//
//  CosmosViewModel.swift
//  wordety
//
//  Created by SkyRocket on 2025/12/26.
//

import Foundation
import SwiftUI

class CosmosViewModel: ObservableObject {
    @Published var testWords: [Word] = []
    @Published var currentIndex = 0
    @Published var currentOptions: [Option] = []
    @Published var isFlipped = false
    @Published var selectedOptionId: UUID? = nil
    @Published var isCorrect = false
    @Published var score = 0
    @Published var isFinished = false
    @Published var starCount = 0 // 记录点亮的星星
    
    // 新增：单词来源
    @Published var selectedSource: WordSource = .searchHistory
    
    struct Option: Identifiable {
        let id = UUID()
        let word: Word
        let meaning: String
        var isCorrect: Bool
    }
    
    private let repository = WordRepository()
    private let packManager = WordPackManager.shared
    
    // MARK: - 重置
    
    /// 重置测试，返回选择界面
    func resetTest() {
        testWords = []
        currentIndex = 0
        currentOptions = []
        isFlipped = false
        selectedOptionId = nil
        isCorrect = false
        score = 0
        isFinished = false
        starCount = 0
    }
    
    // MARK: - 来源相关
    
    /// 获取当前选中来源的单词数量
    func getWordCount(for source: WordSource, historySlugs: [String]) -> Int {
        switch source {
        case .searchHistory:
            return historySlugs.count
        case .wordPack(let id):
            return packManager.getPack(id: id)?.wordCount ?? 0
        }
    }
    
    /// 获取当前来源的描述名称
    func getSourceName(for source: WordSource) -> String {
        switch source {
        case .searchHistory:
            return "Search History"
        case .wordPack(let id):
            return packManager.getPack(id: id)?.name ?? "Unknown Pack"
        }
    }
    
    /// 判断来源是否可用（至少 5 个单词）
    func isSourceAvailable(for source: WordSource, historySlugs: [String]) -> Bool {
        switch source {
        case .searchHistory:
            return availablePracticeSlugs(from: historySlugs).count >= 5
        case .wordPack(let id):
            guard let pack = packManager.getPack(id: id), packManager.canUsePack(id: id) else {
                return false
            }
            return availablePracticeSlugs(from: pack.slugs).count >= 5
        }
    }
    
    // MARK: - 测试控制
    
    /// 使用选中的来源开始测试
    func startTest(historySlugs: [String]) {
        guard isSourceAvailable(for: selectedSource, historySlugs: historySlugs) else { return }

        let slugs: [String]
        
        switch selectedSource {
        case .searchHistory:
            slugs = historySlugs
        case .wordPack(let id):
            if let pack = packManager.getPack(id: id) {
                slugs = pack.slugs
                // 更新最后使用时间
                packManager.markPackAsUsed(id: id)
            } else {
                slugs = []
            }
        }
        
        startTestWithSlugs(slugs, source: selectedSource)
    }
    
    /// 使用指定的 slugs 开始测试
    private func startTestWithSlugs(_ slugs: [String], source: WordSource) {
        let selectedSlugs = selectPracticeSlugs(from: slugs, source: source)
        guard !selectedSlugs.isEmpty else { return }

        var rng = SystemRandomNumberGenerator()
        testWords = repository.getWordsBySlugs(selectedSlugs).shuffled(using: &rng)
        guard !testWords.isEmpty else { return }

        currentIndex = 0
        score = 0
        starCount = 0
        isFinished = false
        loadNextQuestion()
    }

    private func selectPracticeSlugs(from slugs: [String], source: WordSource) -> [String] {
        let availableSlugs = availablePracticeSlugs(from: slugs)
        guard !availableSlugs.isEmpty else { return [] }

        switch source {
        case .searchHistory:
            return randomSelection(from: availableSlugs, limit: 10)
        case .wordPack:
            guard PlusAccessManager.shared.canTrackMastery else {
                return randomSelection(from: availableSlugs, limit: 10)
            }

            let masteryStore = MasteryStore.shared
            var rng = SystemRandomNumberGenerator()
            let practicedSlugs = availableSlugs
                .filter { masteryStore.isPracticed($0) }
                .shuffled(using: &rng)
            let newSlugs = availableSlugs
                .filter { !masteryStore.isPracticed($0) }
                .shuffled(using: &rng)

            var selected = Array(practicedSlugs.prefix(6)) + Array(newSlugs.prefix(4))
            let targetCount = min(10, availableSlugs.count)

            if selected.count < targetCount {
                let selectedSet = Set(selected)
                let fallbackSlugs = availableSlugs
                    .filter { !selectedSet.contains($0) }
                    .shuffled(using: &rng)
                selected.append(contentsOf: fallbackSlugs.prefix(targetCount - selected.count))
            }

            return randomSelection(from: selected, limit: targetCount)
        }
    }

    private func availablePracticeSlugs(from slugs: [String]) -> [String] {
        let uniqueSlugs = uniqueNormalizedSlugs(from: slugs)
        guard PlusAccessManager.shared.canTrackMastery else { return uniqueSlugs }
        return uniqueSlugs.filter { !MasteryStore.shared.isFullyMastered($0) }
    }

    private func uniqueNormalizedSlugs(from slugs: [String]) -> [String] {
        var seen = Set<String>()
        return slugs.compactMap { slug in
            let normalizedSlug = slug.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !normalizedSlug.isEmpty, !seen.contains(normalizedSlug) else { return nil }
            seen.insert(normalizedSlug)
            return normalizedSlug
        }
    }

    private func randomSelection(from slugs: [String], limit: Int) -> [String] {
        var rng = SystemRandomNumberGenerator()
        return Array(slugs.shuffled(using: &rng).prefix(limit))
    }
    
    func loadNextQuestion() {
        guard currentIndex < testWords.count else {
            isFinished = true
            // 记录测试完成统计
            StatsManager.shared.recordCosmosTestCompleted(correct: score, total: testWords.count)
            return
        }
        
        let currentWord = testWords[currentIndex]
        let correctMeaning = currentWord.definitions.first?.meaning ?? "无释义"
        
        // 获取干扰项
        let distractors = repository.getRandomWords(limit: 3, excluding: [currentWord.slug])
        
        var options = distractors.map { distractor in
            Option(word: distractor, meaning: distractor.definitions.first?.meaning ?? "无释义", isCorrect: false)
        }
        
        options.append(Option(word: currentWord, meaning: correctMeaning, isCorrect: true))
        currentOptions = options.shuffled()
        
        isFlipped = false
        selectedOptionId = nil
    }
    
    func selectOption(_ option: Option) {
        guard selectedOptionId == nil else { return }
        
        selectedOptionId = option.id
        isCorrect = option.isCorrect

        let currentWord = testWords[currentIndex]
        
        if isCorrect {
            score += 1
            MasteryStore.shared.recordCorrectAnswer(for: currentWord.slug)
            withAnimation(.spring()) {
                starCount += 1
            }
        } else {
            MasteryStore.shared.recordIncorrectAnswer(for: currentWord.slug)
        }
        
        // 触发翻转
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isFlipped = true
        }
        
        // 触感反馈
        let generator = UIImpactFeedbackGenerator(style: isCorrect ? .medium : .heavy)
        generator.impactOccurred()
    }
    
    func nextQuestion() {
        currentIndex += 1
        loadNextQuestion()
    }
    
    var progress: Double {
        guard !testWords.isEmpty else { return 0 }
        return Double(currentIndex + 1) / Double(testWords.count)
    }
}
