//
//  StatsManager.swift
//  wordety
//
//  Created by Assistant on 2026/1/10.
//

import Foundation
import Combine

class StatsManager: ObservableObject {
    static let shared = StatsManager()
    
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Keys
    private enum Keys {
        static let totalQueries = "stats_totalQueries"
        static let uniqueWords = "stats_uniqueWords"
        static let todayQueries = "stats_todayQueries"
        static let todayDate = "stats_todayDate"
        static let currentStreak = "stats_currentStreak"
        static let longestStreak = "stats_longestStreak"
        static let lastActiveDate = "stats_lastActiveDate"
        static let firstUseDate = "stats_firstUseDate"
        static let totalActiveDays = "stats_totalActiveDays"
        static let activeDates = "stats_activeDates"
        static let cosmosTestsCompleted = "stats_cosmosTestsCompleted"
        static let cosmosTotalCorrect = "stats_cosmosTotalCorrect"
        static let cosmosTotalQuestions = "stats_cosmosTotalQuestions"
        static let todayCosmosTests = "stats_todayCosmosTests"
    }
    
    // MARK: - Published Properties
    @Published var totalQueries: Int = 0
    @Published var uniqueWordsCount: Int = 0
    @Published var todayQueries: Int = 0
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var firstUseDate: Date?
    @Published var totalActiveDays: Int = 0
    @Published var cosmosTestsCompleted: Int = 0
    @Published var cosmosAccuracy: Double = 0.0
    @Published var todayCosmosTests: Int = 0
    
    private var uniqueWords: Set<String> = []
    private var activeDates: Set<String> = []
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    // MARK: - Init
    private init() {
        loadStats()
        checkAndUpdateStreak()
    }
    
    // MARK: - Public Methods
    
    /// 记录一次单词查询
    func recordQuery(word: String) {
        checkDayChange()
        
        totalQueries += 1
        todayQueries += 1
        
        let lowercased = word.lowercased()
        if !uniqueWords.contains(lowercased) {
            uniqueWords.insert(lowercased)
            uniqueWordsCount = uniqueWords.count
        }
        
        markTodayActive()
        saveStats()
    }
    
    /// 记录 Cosmos 测试完成
    func recordCosmosTestCompleted(correct: Int, total: Int) {
        checkDayChange()
        
        cosmosTestsCompleted += 1
        todayCosmosTests += 1
        
        let previousTotal = userDefaults.integer(forKey: Keys.cosmosTotalQuestions)
        let previousCorrect = userDefaults.integer(forKey: Keys.cosmosTotalCorrect)
        
        let newTotalQuestions = previousTotal + total
        let newTotalCorrect = previousCorrect + correct
        
        userDefaults.set(newTotalQuestions, forKey: Keys.cosmosTotalQuestions)
        userDefaults.set(newTotalCorrect, forKey: Keys.cosmosTotalCorrect)
        
        if newTotalQuestions > 0 {
            cosmosAccuracy = Double(newTotalCorrect) / Double(newTotalQuestions) * 100
        }
        
        markTodayActive()
        saveStats()
    }
    
    /// 标记今天为活跃日
    func markTodayActive() {
        let today = dateFormatter.string(from: Date())
        
        if !activeDates.contains(today) {
            activeDates.insert(today)
            totalActiveDays = activeDates.count
            updateStreak()
        }
        
        // 设置首次使用日期
        if firstUseDate == nil {
            firstUseDate = Date()
            userDefaults.set(firstUseDate, forKey: Keys.firstUseDate)
        }
        
        userDefaults.set(today, forKey: Keys.lastActiveDate)
    }
    
    // MARK: - Private Methods
    
    private func loadStats() {
        totalQueries = userDefaults.integer(forKey: Keys.totalQueries)
        todayQueries = userDefaults.integer(forKey: Keys.todayQueries)
        currentStreak = userDefaults.integer(forKey: Keys.currentStreak)
        longestStreak = userDefaults.integer(forKey: Keys.longestStreak)
        firstUseDate = userDefaults.object(forKey: Keys.firstUseDate) as? Date
        totalActiveDays = userDefaults.integer(forKey: Keys.totalActiveDays)
        cosmosTestsCompleted = userDefaults.integer(forKey: Keys.cosmosTestsCompleted)
        todayCosmosTests = userDefaults.integer(forKey: Keys.todayCosmosTests)
        
        // 加载独立单词集合
        if let savedWords = userDefaults.array(forKey: Keys.uniqueWords) as? [String] {
            uniqueWords = Set(savedWords)
            uniqueWordsCount = uniqueWords.count
        }
        
        // 加载活跃日期集合
        if let savedDates = userDefaults.array(forKey: Keys.activeDates) as? [String] {
            activeDates = Set(savedDates)
        }
        
        // 计算正确率
        let totalQuestions = userDefaults.integer(forKey: Keys.cosmosTotalQuestions)
        let totalCorrect = userDefaults.integer(forKey: Keys.cosmosTotalCorrect)
        if totalQuestions > 0 {
            cosmosAccuracy = Double(totalCorrect) / Double(totalQuestions) * 100
        }
    }
    
    private func saveStats() {
        userDefaults.set(totalQueries, forKey: Keys.totalQueries)
        userDefaults.set(todayQueries, forKey: Keys.todayQueries)
        userDefaults.set(currentStreak, forKey: Keys.currentStreak)
        userDefaults.set(longestStreak, forKey: Keys.longestStreak)
        userDefaults.set(totalActiveDays, forKey: Keys.totalActiveDays)
        userDefaults.set(cosmosTestsCompleted, forKey: Keys.cosmosTestsCompleted)
        userDefaults.set(todayCosmosTests, forKey: Keys.todayCosmosTests)
        userDefaults.set(Array(uniqueWords), forKey: Keys.uniqueWords)
        userDefaults.set(Array(activeDates), forKey: Keys.activeDates)
    }
    
    private func checkDayChange() {
        let today = dateFormatter.string(from: Date())
        let savedDate = userDefaults.string(forKey: Keys.todayDate)
        
        if savedDate != today {
            // 新的一天，重置今日统计
            todayQueries = 0
            todayCosmosTests = 0
            userDefaults.set(today, forKey: Keys.todayDate)
        }
    }
    
    private func checkAndUpdateStreak() {
        let today = dateFormatter.string(from: Date())
        guard let lastActive = userDefaults.string(forKey: Keys.lastActiveDate) else {
            return
        }
        
        guard let lastDate = dateFormatter.date(from: lastActive),
              let todayDate = dateFormatter.date(from: today) else {
            return
        }
        
        let daysDiff = Calendar.current.dateComponents([.day], from: lastDate, to: todayDate).day ?? 0
        
        if daysDiff > 1 {
            // 超过一天没活跃，streak 归零
            currentStreak = 0
            saveStats()
        }
    }
    
    private func updateStreak() {
        let today = dateFormatter.string(from: Date())
        let yesterday = dateFormatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        
        if let lastActive = userDefaults.string(forKey: Keys.lastActiveDate) {
            if lastActive == yesterday {
                // 连续学习
                currentStreak += 1
            } else if lastActive != today {
                // 中断了，重新开始
                currentStreak = 1
            }
            // 如果 lastActive == today，不需要更新
        } else {
            // 首次使用
            currentStreak = 1
        }
        
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
        
        saveStats()
    }
    
    // MARK: - Computed Properties
    
    var daysSinceStart: Int {
        guard let start = firstUseDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
    }
    
    var formattedFirstUseDate: String {
        guard let date = firstUseDate else { return "—" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

