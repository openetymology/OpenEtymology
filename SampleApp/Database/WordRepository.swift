//
//  WordRepository.swift
//  wordety
//
//  Created by SkyRocket on 2025/12/22.
//

import Foundation
import SQLite

final class WordRepository {
    private let wordCol = Expression<String>("word")
    private let slugCol = Expression<String>("slug")
    private let pronUkCol = Expression<String?>("pron_uk")
    private let pronUsCol = Expression<String?>("pron_us")
    private let definitionsJsonCol = Expression<String?>("definitions_json")
    private let examplesJsonCol = Expression<String?>("examples_json")
    private let morphemesJsonCol = Expression<String?>("morphemes_json")
    private let etymologyOriginCol = Expression<String?>("etymology_origin")
    private let etymologyAnalysisCol = Expression<String?>("etymology_analysis")

    func getWordBySlug(_ slug: String, mode: DictionaryMode = DictionaryModeManager.shared.selectedMode) -> Word? {
        guard let db = DatabaseManager.shared.getConnection(for: mode) else { return nil }
        let table = Table(mode.tableName)
        let normalized = slug.lowercased()
        let query = table.filter(slugCol == normalized).limit(1)

        if let row = try? db.pluck(query) {
            return parseWord(from: row)
        }

        let fallbackQuery = table.filter(wordCol == normalized).limit(1)
        guard let row = try? db.pluck(fallbackQuery) else { return nil }
        return parseWord(from: row)
    }

    func getWordsBySlugs(_ slugs: [String], mode: DictionaryMode = DictionaryModeManager.shared.selectedMode) -> [Word] {
        guard let db = DatabaseManager.shared.getConnection(for: mode), !slugs.isEmpty else { return [] }
        let table = Table(mode.tableName)
        let normalized = slugs.map { $0.lowercased() }
        let query = table.filter(normalized.contains(slugCol))

        guard let rows = try? db.prepare(query) else { return [] }
        return rows.compactMap(parseWord)
    }

    func getRandomWords(limit: Int, excluding excludedSlugs: [String] = [], mode: DictionaryMode = DictionaryModeManager.shared.selectedMode) -> [Word] {
        guard let db = DatabaseManager.shared.getConnection(for: mode) else { return [] }
        let table = Table(mode.tableName)
        let normalized = excludedSlugs.map { $0.lowercased() }
        let query = table
            .filter(!normalized.contains(slugCol))
            .order(Expression<Double>("random()"))
            .limit(limit)

        guard let rows = try? db.prepare(query) else { return [] }
        return rows.compactMap(parseWord)
    }

    func getDailyFocusWord(
        date: Date = Date(),
        mode: DictionaryMode = DictionaryModeManager.shared.selectedMode,
        offsetDelta: Int = 0
    ) -> Word? {
        guard let db = DatabaseManager.shared.getConnection(for: mode) else { return nil }
        let table = Table(mode.tableName)

        guard let total = try? db.scalar(table.count), total > 0 else { return nil }

        let startOfDay = Calendar.current.startOfDay(for: date)
        let dayIndex = Int(startOfDay.timeIntervalSince1970 / 86_400)
        let baseOffset = abs(dayIndex) % total
        let offset = (baseOffset + offsetDelta) % total
        let query = table
            .order(slugCol.asc)
            .limit(1, offset: offset)

        guard let row = try? db.pluck(query) else { return nil }
        return parseWord(from: row)
    }

    func getRandomFocusWord(
        mode: DictionaryMode = DictionaryModeManager.shared.selectedMode,
        excluding excludedSlugs: [String] = []
    ) -> Word? {
        guard let db = DatabaseManager.shared.getConnection(for: mode) else { return nil }
        let table = Table(mode.tableName)
        let normalized = excludedSlugs.map { $0.lowercased() }
        let pool = table.filter(!normalized.contains(slugCol))
        guard let total = try? db.scalar(pool.count), total > 0 else { return nil }

        let offset = Int.random(in: 0..<total)
        let query = pool
            .order(slugCol.asc)
            .limit(1, offset: offset)

        guard let row = try? db.pluck(query) else { return nil }
        return parseWord(from: row)
    }

    func wordExists(slug: String, mode: DictionaryMode = DictionaryModeManager.shared.selectedMode) -> Bool {
        guard let db = DatabaseManager.shared.getConnection(for: mode) else { return false }
        let table = Table(mode.tableName)
        let query = table.filter(slugCol == slug.lowercased()).limit(1)
        return (try? db.pluck(query)) != nil
    }

    func getSuggestions(_ query: String, limit: Int = 10, mode: DictionaryMode = DictionaryModeManager.shared.selectedMode) -> [String] {
        let searchTerm = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !searchTerm.isEmpty,
              let db = DatabaseManager.shared.getConnection(for: mode) else {
            return []
        }

        let table = Table(mode.tableName)
        let prefixQuery = table
            .select(wordCol)
            .filter(wordCol.like("\(searchTerm)%"))
            .order(wordCol.length.asc, wordCol.asc)
            .limit(limit)

        if let rows = try? db.prepare(prefixQuery) {
            let words = rows.compactMap { try? $0.get(wordCol) }
            if !words.isEmpty {
                return Array(NSOrderedSet(array: words)) as? [String] ?? words
            }
        }

        let slugQuery = table
            .select(wordCol)
            .filter(slugCol.like("\(searchTerm)%"))
            .order(wordCol.length.asc, wordCol.asc)
            .limit(limit)

        guard let rows = try? db.prepare(slugQuery) else { return [] }
        let words = rows.compactMap { try? $0.get(wordCol) }
        return Array(NSOrderedSet(array: words)) as? [String] ?? words
    }

    func bestMatch(for query: String, mode: DictionaryMode = DictionaryModeManager.shared.selectedMode) -> String? {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return nil }

        if let exact = getWordBySlug(normalized, mode: mode) {
            return exact.wordForDisplay
        }

        return getSuggestions(normalized, limit: 1, mode: mode).first
    }

    private func parseWord(from row: Row) -> Word? {
        do {
            let wordValue = try row.get(wordCol)
            let slugValue = try row.get(slugCol)
            let pronUk = try? row.get(pronUkCol)
            let pronUs = try? row.get(pronUsCol)
            let etymologyOrigin = try? row.get(etymologyOriginCol)
            let etymologyAnalysis = try? row.get(etymologyAnalysisCol)

            let definitions = parseJSONArray(jsonString: try? row.get(definitionsJsonCol), type: Definition.self)
            let examples = parseJSONArray(jsonString: try? row.get(examplesJsonCol), type: Example.self)
            let morphemes = parseJSONArray(jsonString: try? row.get(morphemesJsonCol), type: Morpheme.self)

            return Word(
                id: wordValue,
                slug: slugValue,
                pronUk: pronUk,
                pronUs: pronUs,
                definitions: definitions,
                examples: examples,
                morphemes: morphemes,
                etymologyOrigin: etymologyOrigin,
                etymologyAnalysis: etymologyAnalysis
            )
        } catch {
            print("❌ 数据解析失败: \(error)")
            return nil
        }
    }

    private func parseJSONArray<T: Decodable>(jsonString: String?, type: T.Type) -> [T] {
        guard let jsonString, let data = jsonString.data(using: .utf8) else {
            return []
        }
        return (try? JSONDecoder().decode([T].self, from: data)) ?? []
    }
}
