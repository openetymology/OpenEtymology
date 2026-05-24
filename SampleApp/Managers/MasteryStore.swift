//
//  MasteryStore.swift
//  wordety
//
//  Created by Codex on 2026/05/11.
//

import Foundation

final class MasteryStore: ObservableObject {
    static let shared = MasteryStore()

    static let maximumMastery = 7

    @Published private(set) var masteryCounts: [String: Int] = [:]

    private let storageKey = "openetymology.wordMasteryCounts"

    private init() {
        load()
    }

    func mastery(for slug: String) -> Int {
        masteryCounts[normalized(slug), default: 0]
    }

    func isPracticed(_ slug: String) -> Bool {
        mastery(for: slug) > 0
    }

    func isFullyMastered(_ slug: String) -> Bool {
        mastery(for: slug) >= Self.maximumMastery
    }

    func recordCorrectAnswer(for slug: String) {
        guard PlusAccessManager.shared.canTrackMastery else { return }

        let key = normalized(slug)
        let nextValue = min(Self.maximumMastery, masteryCounts[key, default: 0] + 1)
        masteryCounts[key] = nextValue
        save()
    }

    func recordIncorrectAnswer(for slug: String) {
        guard PlusAccessManager.shared.canTrackMastery else { return }

        let key = normalized(slug)
        let nextValue = max(0, masteryCounts[key, default: 0] - 1)
        masteryCounts[key] = nextValue
        save()
    }

    func resetMastery(for slug: String) {
        masteryCounts.removeValue(forKey: normalized(slug))
        save()
    }

    private func normalized(_ slug: String) -> String {
        slug.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func load() {
        guard let saved = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: Int] else {
            return
        }
        masteryCounts = saved.mapValues { min(max($0, 0), Self.maximumMastery) }
    }

    private func save() {
        UserDefaults.standard.set(masteryCounts, forKey: storageKey)
    }
}
