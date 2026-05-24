//
//  WordLemmatizer.swift
//  wordety
//
//  Created by SkyRocket on 2026/01/10.
//

import Foundation

/// 词形还原结果
struct LemmaResult: Identifiable {
    let id = UUID()
    let original: String      // 原始输入，如 "worked"
    let lemma: String?        // 还原后的原型，如 "work"
    let matchType: MatchType
    
    enum MatchType: String {
        case exact = "exact"                            // 精确匹配
        case pastTense = "past tense"                   // 过去式 -ed
        case presentParticiple = "present participle"  // 现在分词 -ing
        case pluralOrThirdPerson = "plural/3rd"        // 复数/三单 -s/-es
        case comparative = "comparative"               // 比较级 -er
        case superlative = "superlative"               // 最高级 -est
        case notFound = "not found"                    // 未找到
        
        var icon: String {
            switch self {
            case .exact: return "✅"
            case .notFound: return "⚠️"
            default: return "🔄"
            }
        }

        func localizedDescription(for mode: DictionaryMode) -> String {
            switch self {
            case .exact:
                return mode.localized(chinese: "精确匹配", english: rawValue)
            case .pastTense:
                return mode.localized(chinese: "过去式", english: rawValue)
            case .presentParticiple:
                return mode.localized(chinese: "现在分词", english: rawValue)
            case .pluralOrThirdPerson:
                return mode.localized(chinese: "复数/三单", english: rawValue)
            case .comparative:
                return mode.localized(chinese: "比较级", english: rawValue)
            case .superlative:
                return mode.localized(chinese: "最高级", english: rawValue)
            case .notFound:
                return mode.localized(chinese: "未找到", english: rawValue)
            }
        }
    }
    
    var isMatched: Bool {
        lemma != nil
    }
}

/// 词形还原器
/// 将单词的变形形式（过去式、进行时等）还原为原型
class WordLemmatizer {
    private let repository: WordRepository
    private let minBaseLength = 3  // 原型最小长度，避免 "bed" → "b" 的误判
    
    init(repository: WordRepository = WordRepository()) {
        self.repository = repository
    }
    
    /// 查找单词的原型
    func findLemma(for word: String) -> LemmaResult {
        let word = word.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 跳过空字符串
        guard !word.isEmpty else {
            return LemmaResult(original: word, lemma: nil, matchType: .notFound)
        }
        
        // Step 1: 直接查找
        if repository.wordExists(slug: word) {
            return LemmaResult(original: word, lemma: word, matchType: .exact)
        }
        
        // Step 2: 尝试词形还原
        let candidates = generateCandidates(for: word)
        
        for (candidate, matchType) in candidates {
            if candidate.count >= minBaseLength && repository.wordExists(slug: candidate) {
                return LemmaResult(original: word, lemma: candidate, matchType: matchType)
            }
        }
        
        return LemmaResult(original: word, lemma: nil, matchType: .notFound)
    }
    
    /// 批量查找
    func findLemmas(for words: [String]) -> [LemmaResult] {
        words.map { findLemma(for: $0) }
    }
    
    /// 生成候选原型列表
    private func generateCandidates(for word: String) -> [(String, LemmaResult.MatchType)] {
        var candidates: [(String, LemmaResult.MatchType)] = []
        
        // === -ed 结尾 (过去式/过去分词) ===
        if word.hasSuffix("ied") && word.count > 4 {
            // studied → study
            candidates.append((String(word.dropLast(3)) + "y", .pastTense))
        }
        if word.hasSuffix("ed") && word.count > 3 {
            let base = String(word.dropLast(2))
            // stopped → stop (双写辅音)
            if base.count >= 2 && isDoubleConsonant(base) {
                candidates.append((String(base.dropLast(1)), .pastTense))
            }
            // worked → work
            candidates.append((base, .pastTense))
            // loved → love (去 d)
            candidates.append((String(word.dropLast(1)), .pastTense))
        }
        
        // === -ing 结尾 (现在分词) ===
        if word.hasSuffix("ing") && word.count > 4 {
            let base = String(word.dropLast(3))
            // running → run (双写辅音)
            if base.count >= 2 && isDoubleConsonant(base) {
                candidates.append((String(base.dropLast(1)), .presentParticiple))
            }
            // working → work
            candidates.append((base, .presentParticiple))
            // loving → love
            candidates.append((base + "e", .presentParticiple))
        }
        
        // === -s/-es 结尾 (复数/三单) ===
        if word.hasSuffix("ies") && word.count > 4 {
            // studies → study
            candidates.append((String(word.dropLast(3)) + "y", .pluralOrThirdPerson))
        }
        if word.hasSuffix("es") && word.count > 3 {
            // boxes → box
            candidates.append((String(word.dropLast(2)), .pluralOrThirdPerson))
        }
        if word.hasSuffix("s") && !word.hasSuffix("ss") && word.count > 2 {
            // books → book (排除 boss, class 等以 ss 结尾的)
            candidates.append((String(word.dropLast(1)), .pluralOrThirdPerson))
        }
        
        // === -er 结尾 (比较级) ===
        if word.hasSuffix("ier") && word.count > 4 {
            // happier → happy
            candidates.append((String(word.dropLast(3)) + "y", .comparative))
        }
        if word.hasSuffix("er") && word.count > 3 {
            let base = String(word.dropLast(2))
            // bigger → big
            if base.count >= 2 && isDoubleConsonant(base) {
                candidates.append((String(base.dropLast(1)), .comparative))
            }
            // taller → tall
            candidates.append((base, .comparative))
            // larger → large
            candidates.append((String(word.dropLast(1)), .comparative))
        }
        
        // === -est 结尾 (最高级) ===
        if word.hasSuffix("iest") && word.count > 5 {
            // happiest → happy
            candidates.append((String(word.dropLast(4)) + "y", .superlative))
        }
        if word.hasSuffix("est") && word.count > 4 {
            let base = String(word.dropLast(3))
            // biggest → big
            if base.count >= 2 && isDoubleConsonant(base) {
                candidates.append((String(base.dropLast(1)), .superlative))
            }
            // tallest → tall
            candidates.append((base, .superlative))
            // largest → large
            candidates.append((String(word.dropLast(2)), .superlative))
        }
        
        return candidates
    }
    
    /// 检查是否双写辅音结尾 (如 "stopp", "runn")
    private func isDoubleConsonant(_ str: String) -> Bool {
        guard str.count >= 2 else { return false }
        let chars = Array(str)
        let last = chars[chars.count - 1]
        let secondLast = chars[chars.count - 2]
        let vowels: Set<Character> = ["a", "e", "i", "o", "u"]
        return last == secondLast && !vowels.contains(last)
    }
}
