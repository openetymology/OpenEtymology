//
//  WordPackListView.swift
//  wordety
//
//  Created by SkyRocket on 2026/01/10.
//

import SwiftUI

struct WordPackListView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var manager = WordPackManager.shared
    @ObservedObject private var plusAccess = PlusAccessManager.shared
    @ObservedObject private var dictionaryModeManager = DictionaryModeManager.shared
    @State private var showingEditor = false
    @State private var showingPaywall = false
    @State private var editingPack: WordPack? = nil
    
    var body: some View {
        ZStack {
            UtilityBackdrop()
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // 返回按钮
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text(dictionaryModeManager.selectedMode.localized(chinese: "设置", english: "Settings"))
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(AppTheme.jewelPurple)
                    }
                    .padding(.horizontal, 25)
                    .padding(.top, 15)
                    
                    // 顶部标题
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dictionaryModeManager.selectedMode.localized(chinese: "学习合集", english: "STUDY SETS"))
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .kerning(2)
                                .foregroundColor(AppTheme.jewelPurple)
                            
                            Text(dictionaryModeManager.selectedMode.localized(chinese: "我的合集", english: "My Collections"))
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundColor(AppTheme.ink)
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 5) {
                            // 添加按钮
                            Button(action: {
                                if plusAccess.canCreateWordPacks {
                                    editingPack = nil
                                    showingEditor = true
                                } else {
                                    showingPaywall = true
                                }
                            }) {
                                Image(systemName: plusAccess.canCreateWordPacks ? "plus" : "lock.fill")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(plusAccess.canCreateWordPacks ? AppTheme.jewelPurple : AppTheme.wordmarkBlue)
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusS, style: .continuous))
                                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                            }

                            Text(plusAccess.canCreateWordPacks
                                 ? dictionaryModeManager.selectedMode.localized(chinese: "增加合集", english: "Add Set")
                                 : dictionaryModeManager.selectedMode.localized(chinese: "Plus 增加", english: "Plus Add"))
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(plusAccess.canCreateWordPacks ? AppTheme.jewelPurple : AppTheme.wordmarkBlue)
                                .lineLimit(1)
                        }
                    }
                    .padding(.horizontal, 25)
                    .padding(.top, 10)
                    
                    if manager.packs.isEmpty {
                        // 空状态
                        VStack(spacing: 20) {
                            Spacer().frame(height: 60)
                            
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 60))
                                .foregroundColor(AppTheme.jewelPurple.opacity(0.3))
                            
                            Text(dictionaryModeManager.selectedMode.localized(chinese: "还没有学习合集", english: "No Study Sets Yet"))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.ink)
                            
                            Text(dictionaryModeManager.selectedMode.localized(
                                chinese: plusAccess.canCreateWordPacks ? "点击 + 创建第一个\n练习合集" : "升级 Plus 后可创建\n自定义练习合集",
                                english: plusAccess.canCreateWordPacks ? "Tap + to create your first\nstudy set for Quiz practice" : "Upgrade to Plus to create\ncustom quiz sets"
                            ))
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(AppTheme.mutedInk)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 28)
                        .utilityPanel(cornerRadius: AppTheme.radiusL)
                        .padding(.horizontal, 20)
                        .padding(.top, 40)
                    } else {
                        // 单词包列表
                        VStack(spacing: 12) {
                            ForEach(manager.packs.sorted { ($0.lastUsedAt ?? .distantPast) > ($1.lastUsedAt ?? .distantPast) }) { pack in
                                WordPackCard(
                                    pack: pack,
                                    selectedMode: dictionaryModeManager.selectedMode,
                                    isLocked: !plusAccess.canCreateWordPacks
                                ) {
                                    if plusAccess.canCreateWordPacks {
                                        editingPack = pack
                                        showingEditor = true
                                    } else {
                                        showingPaywall = true
                                    }
                                } onDelete: {
                                    withAnimation(.spring()) {
                                        manager.deletePack(id: pack.id)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer().frame(height: 100)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingEditor) {
            WordPackEditorView(existingPack: editingPack)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }
}

// MARK: - Word Pack Card

struct WordPackCard: View {
    let pack: WordPack
    let selectedMode: DictionaryMode
    var isLocked = false
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteConfirm = false
    
    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 16) {
                // 颜色标识
                Circle()
                    .fill(pack.color)
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(pack.name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.ink)
                    
                    HStack(spacing: 8) {
                        Text(selectedMode.localized(chinese: "\(pack.wordCount) 个单词", english: "\(pack.wordCount) words"))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(AppTheme.mutedInk)
                        
                        if let lastUsed = pack.lastUsedAt {
                            Text("·")
                                .foregroundColor(AppTheme.mutedInk.opacity(0.58))
                            Text(lastUsed.relativeDescription(for: selectedMode))
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(AppTheme.mutedInk.opacity(0.78))
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: isLocked ? "lock.fill" : "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isLocked ? pack.color.opacity(0.82) : AppTheme.mutedInk.opacity(0.52))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .utilityPanel(cornerRadius: AppTheme.radiusM, accent: pack.color)
        }
        .contextMenu {
            if isLocked {
                Button(action: onEdit) {
                    Label(selectedMode.localized(chinese: "升级以编辑", english: "Upgrade To Edit"), systemImage: "lock.fill")
                }
            } else {
                Button(action: onEdit) {
                    Label(selectedMode.localized(chinese: "编辑", english: "Edit"), systemImage: "pencil")
                }

                Button(role: .destructive, action: { showDeleteConfirm = true }) {
                    Label(selectedMode.localized(chinese: "删除", english: "Delete"), systemImage: "trash")
                }
            }
        }
        .confirmationDialog(
            selectedMode.localized(chinese: "删除“\(pack.name)”？", english: "Delete \"\(pack.name)\"?"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(selectedMode.localized(chinese: "删除", english: "Delete"), role: .destructive, action: onDelete)
            Button(selectedMode.localized(chinese: "取消", english: "Cancel"), role: .cancel) {}
        } message: {
            Text(selectedMode.localized(chinese: "此操作无法撤销。", english: "This action cannot be undone."))
        }
    }
}

// MARK: - Date Extension

extension Date {
    var relativeDescription: String {
        relativeDescription(for: .enen)
    }

    func relativeDescription(for mode: DictionaryMode) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(self) {
            return mode.localized(chinese: "今天使用", english: "Used today")
        } else if calendar.isDateInYesterday(self) {
            return mode.localized(chinese: "昨天使用", english: "Used yesterday")
        } else {
            let days = calendar.dateComponents([.day], from: self, to: now).day ?? 0
            if days < 7 {
                return mode.localized(chinese: "\(days) 天前使用", english: "Used \(days) days ago")
            } else if days < 30 {
                let weeks = days / 7
                return mode.localized(chinese: "\(weeks) 周前使用", english: "Used \(weeks) week\(weeks > 1 ? "s" : "") ago")
            } else {
                let months = days / 30
                return mode.localized(chinese: "\(months) 个月前使用", english: "Used \(months) month\(months > 1 ? "s" : "") ago")
            }
        }
    }
}
