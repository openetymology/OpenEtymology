//
//  SearchViewModel.swift
//  wordety
//
//  Created by SkyRocket on 2025/12/22.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var suggestions: [String] = []
    @Published var currentWord: Word? = nil
    @Published var errorMessage: String? = nil
    @Published var hasSearched = false
    @Published var isLoadingWord = false
    @Published var searchHistory: [String] = []

    private let repository = WordRepository()
    private let historyKey = "SearchHistory"
    private var suggestionTask: Task<Void, Never>?
    private var searchTask: Task<Void, Never>?
    private var plusAccessCancellable: AnyCancellable?

    init() {
        loadHistory()
        plusAccessCancellable = PlusAccessManager.shared.$isPlusUnlocked
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.applyHistoryLimitIfNeeded()
                }
            }
    }

    func updateSuggestions(query: String, mode: DictionaryMode? = nil) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            suggestionTask?.cancel()
            suggestions = []
            return
        }

        let selectedMode = mode ?? DictionaryModeManager.shared.selectedMode
        suggestionTask?.cancel()
        suggestionTask = Task.detached(priority: .userInitiated) { [repository, trimmed, selectedMode] in
            try? await Task.sleep(nanoseconds: 120_000_000)
            guard !Task.isCancelled else { return }
            let results = repository.getSuggestions(trimmed, mode: selectedMode)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.suggestions = results
            }
        }
    }

    func search(query: String, mode: DictionaryMode? = nil) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let selectedMode = mode ?? DictionaryModeManager.shared.selectedMode

        hasSearched = true
        isLoadingWord = true
        suggestions = []
        errorMessage = nil

        searchTask?.cancel()
        searchTask = Task.detached(priority: .userInitiated) { [repository, trimmed, selectedMode] in
            let matched = repository.bestMatch(for: trimmed, mode: selectedMode) ?? trimmed
            guard !Task.isCancelled else { return }

            let word = repository.getWordBySlug(matched.lowercased(), mode: selectedMode)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.addToHistory(matched)
                StatsManager.shared.recordQuery(word: matched)
                self.isLoadingWord = false
                if let word {
                    self.currentWord = word
                    self.errorMessage = nil
                    ReviewStore.shared.addWord(slug: word.slug, word: word.id, source: .search)
                } else {
                    self.currentWord = nil
                    self.errorMessage = selectedMode.missingEntryMessage
                }
            }
        }
    }

    func openHistoryWord(_ query: String) {
        search(query: query)
    }

    func setDictionaryMode(_ mode: DictionaryMode, refreshQuery: String?) {
        guard DictionaryModeManager.shared.selectedMode != mode else {
            if let refreshQuery, !refreshQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                updateSuggestions(query: refreshQuery, mode: mode)
            }
            return
        }

        DictionaryModeManager.shared.updateMode(mode)
        suggestions = []

        if let refreshQuery, !refreshQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            search(query: refreshQuery, mode: mode)
        } else if hasSearched, let currentWord {
            search(query: currentWord.slug, mode: mode)
        } else {
            currentWord = nil
            errorMessage = nil
            hasSearched = false
            isLoadingWord = false
        }
    }

    func clearSearch() {
        suggestionTask?.cancel()
        searchTask?.cancel()
        suggestions = []
        currentWord = nil
        errorMessage = nil
        hasSearched = false
        isLoadingWord = false
    }

    func clearHistory() {
        searchHistory = []
        UserDefaults.standard.removeObject(forKey: historyKey)
    }

    private func loadHistory() {
        searchHistory = limitedHistory(UserDefaults.standard.stringArray(forKey: historyKey) ?? [])
        UserDefaults.standard.set(searchHistory, forKey: historyKey)
    }

    private func addToHistory(_ word: String) {
        let trimmedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedWord.isEmpty else { return }

        var currentHistory = searchHistory
        if let index = currentHistory.firstIndex(of: trimmedWord) {
            currentHistory.remove(at: index)
        }

        currentHistory.insert(trimmedWord, at: 0)
        searchHistory = limitedHistory(currentHistory)
        UserDefaults.standard.set(searchHistory, forKey: historyKey)
    }

    private func applyHistoryLimitIfNeeded() {
        let limited = limitedHistory(searchHistory)
        guard limited != searchHistory else { return }
        searchHistory = limited
        UserDefaults.standard.set(searchHistory, forKey: historyKey)
    }

    private func limitedHistory(_ history: [String]) -> [String] {
        guard let limit = PlusAccessManager.shared.historyLimit else {
            return history
        }
        return Array(history.prefix(limit))
    }
}

enum ReviewRating: String, CaseIterable, Identifiable {
    case again
    case good
    case easy

    var id: String { rawValue }
}

enum ReviewSource: String, Codable {
    case search
    case history
    case cosmos
}

enum LearningStatus: String {
    case new
    case reviewed
    case mastered
}

struct ReviewEntry: Codable, Identifiable {
    let id: String
    let slug: String
    let word: String
    let source: ReviewSource
    let addedAt: Date
    var reviewCount: Int
    var lastReviewedAt: Date?
    var isMastered: Bool

    init(slug: String, word: String, source: ReviewSource) {
        self.id = slug
        self.slug = slug
        self.word = word
        self.source = source
        self.addedAt = Date()
        self.reviewCount = 0
        self.lastReviewedAt = nil
        self.isMastered = false
    }
}

final class ReviewStore: ObservableObject {
    static let shared = ReviewStore()

    @Published private(set) var entries: [ReviewEntry] = []

    private let storageKey = "wordety_review_entries"

    private init() {
        load()
    }

    var dueCount: Int {
        entries.count
    }

    var dueSlugs: [String] {
        entries.map(\.slug)
    }

    func addWord(slug: String, word: String, source: ReviewSource) {
        let normalized = slug.lowercased()
        if let index = entries.firstIndex(where: { $0.slug == normalized }) {
            var entry = entries[index]
            if entry.word != word {
                entry = ReviewEntry(slug: normalized, word: word, source: source)
            }
            entries[index] = entry
        } else {
            entries.insert(ReviewEntry(slug: normalized, word: word, source: source), at: 0)
        }
        save()
    }

    func submitReview(for slug: String, rating: ReviewRating) {
        guard let index = entries.firstIndex(where: { $0.slug == slug.lowercased() }) else { return }
        var entry = entries[index]

        switch rating {
        case .again:
            entry.reviewCount = max(0, entry.reviewCount)
            entry.isMastered = false
        case .good:
            entry.reviewCount += 1
            entry.isMastered = entry.reviewCount >= 2
        case .easy:
            entry.reviewCount += 2
            entry.isMastered = true
        }

        entry.lastReviewedAt = Date()
        entries[index] = entry
        save()
    }

    func status(for slug: String) -> LearningStatus {
        guard let entry = entries.first(where: { $0.slug == slug.lowercased() }) else {
            return .new
        }
        if entry.isMastered { return .mastered }
        if entry.reviewCount > 0 { return .reviewed }
        return .new
    }

    func trackedCount(in slugs: [String]) -> Int {
        let set = Set(slugs.map { $0.lowercased() })
        return entries.filter { set.contains($0.slug) }.count
    }

    func masteredCount(in slugs: [String]) -> Int {
        let set = Set(slugs.map { $0.lowercased() })
        return entries.filter { set.contains($0.slug) && $0.isMastered }.count
    }

    func reviewedTodayCount(in slugs: [String]) -> Int {
        let set = Set(slugs.map { $0.lowercased() })
        return entries.filter {
            set.contains($0.slug) &&
            ($0.lastReviewedAt.map { Calendar.current.isDateInToday($0) } ?? false)
        }.count
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([ReviewEntry].self, from: data) else {
            return
        }
        entries = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
