//
//  WordPackManager.swift
//  wordety
//
//  Created by SkyRocket on 2026/01/10.
//

import Foundation
import SwiftUI

/// 单词包管理器（单例）
class WordPackManager: ObservableObject {
    static let shared = WordPackManager()
    
    @Published var packs: [WordPack] = []
    
    private let userDefaultsKey = "wordety_word_packs"
    private let lemmatizer = WordLemmatizer()
    private lazy var cachedBuiltInPacks: [WordPack] = Self.builtInDefinitions.map { definition in
        WordPack(
            id: definition.id,
            name: definition.name,
            slugs: Self.loadSlugs(from: definition.resourceName),
            colorName: definition.colorName
        )
    }
    
    private init() {
        loadPacks()
    }

    var builtInPacks: [WordPack] {
        cachedBuiltInPacks
    }

    var practicePacks: [WordPack] {
        let customPracticePacks = packs
            .filter { !Self.isBuiltInEquivalentName($0.name) }
            .sorted { lhs, rhs in
                (lhs.lastUsedAt ?? lhs.createdAt) > (rhs.lastUsedAt ?? rhs.createdAt)
            }
        return builtInPacks + customPracticePacks
    }

    func requiresPlus(for pack: WordPack) -> Bool {
        requiresPlus(for: pack.id)
    }

    func requiresPlus(for id: UUID) -> Bool {
        if let definition = Self.builtInDefinitions.first(where: { $0.id == id }) {
            return definition.requiresPlus
        }
        return true
    }

    func canUsePack(id: UUID) -> Bool {
        !requiresPlus(for: id) || PlusAccessManager.shared.canUseAdvancedWordPacks
    }
    
    // MARK: - CRUD 操作
    
    /// 创建新单词包
    @discardableResult
    func createPack(name: String, words: [String], colorName: String = "purple") -> WordPack {
        // 验证并获取有效的 slug 列表
        let validSlugs = validateAndGetSlugs(from: words)
        
        let pack = WordPack(
            name: name,
            slugs: validSlugs,
            colorName: colorName
        )
        
        packs.append(pack)
        savePacks()
        
        return pack
    }
    
    /// 更新单词包
    func updatePack(_ pack: WordPack) {
        if let index = packs.firstIndex(where: { $0.id == pack.id }) {
            packs[index] = pack
            savePacks()
        }
    }
    
    /// 删除单词包
    func deletePack(id: UUID) {
        packs.removeAll { $0.id == id }
        savePacks()
    }
    
    /// 获取单词包
    func getPack(id: UUID) -> WordPack? {
        builtInPacks.first { $0.id == id } ?? packs.first { $0.id == id }
    }
    
    /// 更新单词包的最后使用时间
    func markPackAsUsed(id: UUID) {
        guard !Self.builtInDefinitions.contains(where: { $0.id == id }) else { return }
        if let index = packs.firstIndex(where: { $0.id == id }) {
            packs[index].lastUsedAt = Date()
            savePacks()
        }
    }
    
    // MARK: - 单词验证
    
    /// 验证输入的单词文本，返回验证结果
    func validateWords(from input: String) -> [LemmaResult] {
        let words = parseWordsFromInput(input)
        return lemmatizer.findLemmas(for: words)
    }
    
    /// 从验证结果中获取有效的 slug 列表
    func getValidSlugs(from results: [LemmaResult]) -> [String] {
        results.compactMap { $0.lemma }
    }
    
    /// 验证并获取有效的 slug 列表（内部使用）
    private func validateAndGetSlugs(from words: [String]) -> [String] {
        let results = lemmatizer.findLemmas(for: words)
        // 去重并保持顺序
        var seen = Set<String>()
        return results.compactMap { result -> String? in
            guard let lemma = result.lemma, !seen.contains(lemma) else { return nil }
            seen.insert(lemma)
            return lemma
        }
    }
    
    /// 解析用户输入的文本为单词数组
    func parseWordsFromInput(_ input: String) -> [String] {
        input
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }  // 忽略空行和注释行
    }
    
    // MARK: - 持久化
    
    /// 保存到 UserDefaults
    private func savePacks() {
        if let encoded = try? JSONEncoder().encode(packs) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    /// 从 UserDefaults 加载
    private func loadPacks() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([WordPack].self, from: data) {
            packs = decoded
        }
    }
    
    // MARK: - 统计信息
    
    /// 验证结果统计
    struct ValidationStats {
        let exactMatches: Int
        let lemmaMatches: Int
        let notFound: Int
        let total: Int
        
        var matchedCount: Int { exactMatches + lemmaMatches }
    }
    
    /// 计算验证统计
    func calculateStats(from results: [LemmaResult]) -> ValidationStats {
        var exact = 0
        var lemma = 0
        var notFound = 0
        
        for result in results {
            switch result.matchType {
            case .exact:
                exact += 1
            case .notFound:
                notFound += 1
            default:
                lemma += 1
            }
        }
        
        return ValidationStats(
            exactMatches: exact,
            lemmaMatches: lemma,
            notFound: notFound,
            total: results.count
        )
    }
}

private extension WordPackManager {
    struct BuiltInDefinition {
        let id: UUID
        let name: String
        let resourceName: String
        let colorName: String
        let requiresPlus: Bool
    }

    static let builtInDefinitions: [BuiltInDefinition] = [
        BuiltInDefinition(
            id: UUID(uuidString: "77E80E22-1F93-46D4-86F9-5E8B82F5C4A1")!,
            name: "CET4",
            resourceName: "CET4_edited",
            colorName: "cyan",
            requiresPlus: false
        ),
        BuiltInDefinition(
            id: UUID(uuidString: "7AF5136D-7C01-4F9E-8D82-9C6D7C9B2B62")!,
            name: "CET6",
            resourceName: "CET6_edited",
            colorName: "green",
            requiresPlus: false
        ),
        BuiltInDefinition(
            id: UUID(uuidString: "00EA57A5-0BD1-44C0-AF7E-8DE94E0E72B4")!,
            name: "TEM8",
            resourceName: "TEM8",
            colorName: "pink",
            requiresPlus: true
        ),
        BuiltInDefinition(
            id: UUID(uuidString: "77B49B46-C36C-4FB3-B1B3-E1E61677AD70")!,
            name: "TOEFL",
            resourceName: "TOEFL",
            colorName: "brightPurple",
            requiresPlus: true
        ),
        BuiltInDefinition(
            id: UUID(uuidString: "C1E6E398-C9CB-4E5A-912F-46161D28EF12")!,
            name: "GRE8000",
            resourceName: "GRE_8000_Words",
            colorName: "yellow",
            requiresPlus: true
        )
    ]

    static func loadSlugs(from resourceName: String) -> [String] {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "txt"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }

        var seen = Set<String>()
        return content
            .components(separatedBy: .newlines)
            .compactMap { rawLine -> String? in
                let line = rawLine
                    .replacingOccurrences(of: "\u{feff}", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard !line.isEmpty, line.count > 1 else { return nil }
                guard let firstWordRange = line.range(
                    of: #"^[A-Za-z][A-Za-z'-]*"#,
                    options: .regularExpression
                ) else {
                    return nil
                }

                let slug = String(line[firstWordRange])
                    .trimmingCharacters(in: CharacterSet(charactersIn: "'-"))
                    .lowercased()

                guard slug.count > 1, !seen.contains(slug) else { return nil }
                seen.insert(slug)
                return slug
            }
    }

    static func isBuiltInEquivalentName(_ name: String) -> Bool {
        let normalized = normalizedPackName(name)
        let legacyBuiltInNames: Set<String> = ["tofel", "gre", "gre8000words"]
        return builtInDefinitions.contains { definition in
            normalized == normalizedPackName(definition.name)
        } || legacyBuiltInNames.contains(normalized)
    }

    static func normalizedPackName(_ name: String) -> String {
        name
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
    }
}
