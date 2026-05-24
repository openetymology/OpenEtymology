//
//  StatsView.swift
//  wordety
//
//  Created by Assistant on 2026/1/10.
//

import SwiftUI

struct StatsView: View {
    @ObservedObject private var statsManager = StatsManager.shared
    @ObservedObject private var dictionaryModeManager = DictionaryModeManager.shared
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                VStack(spacing: 5) {
                    Text(dictionaryModeManager.selectedMode.localized(chinese: "统计", english: "STATISTICS"))
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .kerning(3)
                        .foregroundColor(AppTheme.mutedInk)
                    
                    Text(dictionaryModeManager.selectedMode.localized(chinese: "你的学习轨迹", english: "Your Learning Journey"))
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.ink)
                }
                .padding(.top, 14)
                
                StreakHeroCard(
                    currentStreak: statsManager.currentStreak,
                    longestStreak: statsManager.longestStreak,
                    selectedMode: dictionaryModeManager.selectedMode
                )
                .padding(.horizontal, 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(
                        title: dictionaryModeManager.selectedMode.localized(chinese: "今日", english: "TODAY"),
                        color: AppTheme.jewelCyan
                    )
                    
                    HStack(spacing: 10) {
                        StatCard(
                            icon: "magnifyingglass",
                            title: dictionaryModeManager.selectedMode.localized(chinese: "查询", english: "Queries"),
                            value: "\(statsManager.todayQueries)",
                            color: AppTheme.jewelCyan
                        )
                        
                        StatCard(
                            icon: "sparkles",
                            title: dictionaryModeManager.selectedMode.localized(chinese: "练习", english: "Quizzes"),
                            value: "\(statsManager.todayCosmosTests)",
                            color: AppTheme.jewelPink
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(
                        title: dictionaryModeManager.selectedMode.localized(chinese: "累计", english: "ALL TIME"),
                        color: AppTheme.jewelPurple
                    )
                    
                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            StatCard(
                                icon: "text.magnifyingglass",
                                title: dictionaryModeManager.selectedMode.localized(chinese: "总查询", english: "Total Queries"),
                                value: "\(statsManager.totalQueries)",
                                color: AppTheme.jewelPurple
                            )
                            
                            StatCard(
                                icon: "textformat.abc",
                                title: dictionaryModeManager.selectedMode.localized(chinese: "不同单词", english: "Unique Words"),
                                value: "\(statsManager.uniqueWordsCount)",
                                color: AppTheme.jewelYellow
                            )
                        }
                        
                        HStack(spacing: 10) {
                            StatCard(
                                icon: "checkmark.circle.fill",
                                title: dictionaryModeManager.selectedMode.localized(chinese: "完成练习", english: "Quizzes Done"),
                                value: "\(statsManager.cosmosTestsCompleted)",
                                color: AppTheme.jewelCyan
                            )
                            
                            StatCard(
                                icon: "percent",
                                title: dictionaryModeManager.selectedMode.localized(chinese: "正确率", english: "Accuracy"),
                                value: statsManager.cosmosTestsCompleted > 0 ? String(format: "%.0f%%", statsManager.cosmosAccuracy) : "—",
                                color: AppTheme.jewelPink
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(
                        title: dictionaryModeManager.selectedMode.localized(chinese: "旅程", english: "JOURNEY"),
                        color: AppTheme.jewelYellow
                    )
                    
                    JourneyCard(
                        firstUseDate: statsManager.formattedFirstUseDate,
                        totalActiveDays: statsManager.totalActiveDays,
                        daysSinceStart: statsManager.daysSinceStart,
                        selectedMode: dictionaryModeManager.selectedMode
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 28)
            }
        }
        .background(
            UtilityBackdrop()
                .ignoresSafeArea()
        )
    }
}

// MARK: - Components

struct SectionHeader: View {
    let title: String
    let color: Color
    
    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .black, design: .rounded))
            .kerning(2)
            .foregroundColor(color)
            .padding(.leading, 4)
    }
}

struct StreakHeroCard: View {
    let currentStreak: Int
    let longestStreak: Int
    let selectedMode: DictionaryMode
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentSoft)
                    .frame(width: 54, height: 54)
                
                Image(systemName: "flame")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundColor(AppTheme.jewelOrange)
            }
            
            VStack(spacing: 2) {
                Text("\(currentStreak)")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundColor(AppTheme.jewelOrange)
                
                Text(selectedMode.localized(chinese: "连续学习天数", english: "Day Streak"))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.mutedInk)
            }
            
            if longestStreak > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.jewelYellow)
                    
                    Text(selectedMode.localized(chinese: "最佳：\(longestStreak) 天", english: "Best: \(longestStreak) days"))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.mutedInk)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .utilityPill(accent: AppTheme.jewelYellow)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .utilityPanel(cornerRadius: AppTheme.radiusL, accent: AppTheme.jewelOrange)
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 23, weight: .black, design: .rounded))
                .foregroundColor(AppTheme.ink)
            
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.mutedInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .utilityPanel(cornerRadius: AppTheme.radiusM, accent: color)
    }
}

struct JourneyCard: View {
    let firstUseDate: String
    let totalActiveDays: Int
    let daysSinceStart: Int
    let selectedMode: DictionaryMode
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedMode.localized(chinese: "开始于", english: "Started"))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.mutedInk)
                    
                    Text(firstUseDate)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.ink)
                }
                
                Spacer()
                
                if daysSinceStart > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(selectedMode.localized(chinese: "活跃率", english: "Active Rate"))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(AppTheme.mutedInk)
                        
                        Text(String(format: "%.0f%%", min(Double(totalActiveDays) / Double(max(daysSinceStart, 1)) * 100, 100)))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.jewelCyan)
                    }
                }
            }
            
            Divider()
                .background(AppTheme.divider)
            
            HStack(spacing: 0) {
                JourneyStatItem(
                    value: "\(totalActiveDays)",
                    label: selectedMode.localized(chinese: "活跃天数", english: "Active Days"),
                    color: AppTheme.jewelPurple
                )
                
                Divider()
                    .frame(height: 30)
                    .background(AppTheme.divider)
                
                JourneyStatItem(
                    value: "\(daysSinceStart)",
                    label: selectedMode.localized(chinese: "累计天数", english: "Days Since Start"),
                    color: AppTheme.jewelCyan
                )
            }
        }
        .padding(12)
        .utilityPanel(cornerRadius: AppTheme.radiusM, accent: AppTheme.jewelYellow)
    }
}

struct JourneyStatItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.mutedInk)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    StatsView()
}
