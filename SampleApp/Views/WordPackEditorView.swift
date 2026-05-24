//
//  WordPackEditorView.swift
//  wordety
//
//  Created by SkyRocket on 2026/01/10.
//

import SwiftUI

struct WordPackEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var manager = WordPackManager.shared
    @ObservedObject private var dictionaryModeManager = DictionaryModeManager.shared
    
    // 编辑模式：如果有 existingPack 则为编辑，否则为新建
    let existingPack: WordPack?
    
    @State private var packName: String = ""
    @State private var selectedColor: String = "purple"
    @State private var wordsInput: String = ""
    
    // 验证相关
    @State private var validationResults: [LemmaResult] = []
    @State private var showValidation = false
    @State private var isValidating = false
    
    var isEditing: Bool { existingPack != nil }
    
    init(existingPack: WordPack? = nil) {
        self.existingPack = existingPack
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                UtilityBackdrop()
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 25) {
                        // 包名输入
                        VStack(alignment: .leading, spacing: 10) {
                            Text(dictionaryModeManager.selectedMode.localized(chinese: "合集名称", english: "SET NAME"))
                                .font(AppFont.section)
                                .kerning(1)
                                .foregroundColor(AppTheme.mutedInk.opacity(0.72))
                            
                            TextField(dictionaryModeManager.selectedMode.localized(chinese: "例如：GRE 核心词、CET 练习", english: "e.g. GRE Core, Exam Practice"), text: $packName)
                                .font(AppFont.body)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .utilityPanel(cornerRadius: AppTheme.radiusM)
                        }
                        
                        // 颜色选择
                        VStack(alignment: .leading, spacing: 10) {
                            Text(dictionaryModeManager.selectedMode.localized(chinese: "颜色", english: "COLOR"))
                                .font(AppFont.section)
                                .kerning(1)
                                .foregroundColor(AppTheme.mutedInk.opacity(0.72))
                            
                            HStack(spacing: 12) {
                                ForEach(WordPack.availableColors, id: \.name) { item in
                                    Button(action: { selectedColor = item.name }) {
                                        ZStack {
                                            Circle()
                                                .fill(item.color)
                                                .frame(width: 44, height: 44)
                                            
                                            if selectedColor == item.name {
                                                Image(systemName: "checkmark")
                                                    .font(AppFont.body)
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .utilityPanel(cornerRadius: AppTheme.radiusM)
                        }
                        
                        // 单词输入
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(dictionaryModeManager.selectedMode.localized(chinese: "单词", english: "WORDS"))
                                    .font(AppFont.section)
                                    .kerning(1)
                                    .foregroundColor(AppTheme.mutedInk.opacity(0.72))
                                
                                Text(dictionaryModeManager.selectedMode.localized(chinese: "（每行一个）", english: "(one per line)"))
                                    .font(AppFont.secondarySmall)
                                    .foregroundColor(AppTheme.mutedInk.opacity(0.56))
                            }
                            
                            TextEditor(text: $wordsInput)
                                .font(AppFont.bodyMono)
                                .frame(minHeight: 200)
                                .padding(16)
                                .scrollContentBackground(.hidden)
                                .background(AppTheme.surfaceElevated)
                                .utilityPanel(cornerRadius: AppTheme.radiusM)
                                .onChange(of: wordsInput) { _, _ in
                                    // 输入变化时重置验证状态
                                    showValidation = false
                                }
                            
                            // 提示
                            HStack(spacing: 6) {
                                Image(systemName: "lightbulb.fill")
                                    .font(AppFont.secondary)
                                    .foregroundColor(AppTheme.jewelYellow)
                                
                                Text(dictionaryModeManager.selectedMode.localized(
                                    chinese: "可以从任何地方粘贴单词。变形形式（worked、running）会自动匹配原形。",
                                    english: "Paste words from anywhere! Inflected forms (worked, running) will be matched automatically."
                                ))
                                    .font(AppFont.secondarySmall)
                                    .foregroundColor(AppTheme.mutedInk)
                            }
                            .padding(.horizontal, 5)
                        }
                        
                        // 验证结果区域
                        if showValidation {
                            ValidationResultView(
                                results: validationResults,
                                stats: manager.calculateStats(from: validationResults),
                                selectedMode: dictionaryModeManager.selectedMode
                            )
                        }
                        
                        // 保存按钮
                        Button(action: validateAndShowResults) {
                            HStack {
                                if isValidating {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(primaryButtonTitle)
                                        .font(AppFont.body)
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                Capsule()
                                    .fill(canSave ? AppTheme.jewelPurple : AppTheme.mutedInk.opacity(0.32))
                            )
                            .shadow(color: canSave ? Color.black.opacity(0.08) : .clear, radius: 8, x: 0, y: 2)
                        }
                        .disabled(!canValidate)
                        
                        Spacer().frame(height: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle(dictionaryModeManager.selectedMode.localized(
                chinese: isEditing ? "编辑合集" : "新建合集",
                english: isEditing ? "Edit Set" : "New Set"
            ))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(dictionaryModeManager.selectedMode.localized(chinese: "取消", english: "Cancel")) {
                        dismiss()
                    }
                    .font(AppFont.body)
                }
            }
            .onAppear {
                // 如果是编辑模式，加载现有数据
                if let pack = existingPack {
                    packName = pack.name
                    selectedColor = pack.colorName
                    wordsInput = pack.slugs.joined(separator: "\n")
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canValidate: Bool {
        !packName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !wordsInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var canSave: Bool {
        showValidation && !manager.getValidSlugs(from: validationResults).isEmpty
    }

    private var primaryButtonTitle: String {
        if showValidation {
            let count = manager.getValidSlugs(from: validationResults).count
            return dictionaryModeManager.selectedMode.localized(
                chinese: "保存 \(count) 个单词",
                english: "SAVE \(count) WORDS"
            )
        }
        return dictionaryModeManager.selectedMode.localized(chinese: "验证并预览", english: "VALIDATE & PREVIEW")
    }
    
    // MARK: - Actions
    
    private func validateAndShowResults() {
        if showValidation {
            // 已验证，执行保存
            saveWordPack()
        } else {
            // 执行验证
            isValidating = true
            
            // 使用异步避免 UI 卡顿
            DispatchQueue.global(qos: .userInitiated).async {
                let results = manager.validateWords(from: wordsInput)
                
                DispatchQueue.main.async {
                    validationResults = results
                    showValidation = true
                    isValidating = false
                }
            }
        }
    }
    
    private func saveWordPack() {
        let validSlugs = manager.getValidSlugs(from: validationResults)
        
        // 去重
        var seen = Set<String>()
        let uniqueSlugs = validSlugs.filter { slug in
            guard !seen.contains(slug) else { return false }
            seen.insert(slug)
            return true
        }
        
        if let existing = existingPack {
            // 更新现有
            var updated = existing
            updated.name = packName.trimmingCharacters(in: .whitespaces)
            updated.slugs = uniqueSlugs
            updated.colorName = selectedColor
            manager.updatePack(updated)
        } else {
            // 创建新的
            manager.createPack(
                name: packName.trimmingCharacters(in: .whitespaces),
                words: uniqueSlugs,
                colorName: selectedColor
            )
        }
        
        dismiss()
    }
}

// MARK: - Validation Result View

struct ValidationResultView: View {
    let results: [LemmaResult]
    let stats: WordPackManager.ValidationStats
    let selectedMode: DictionaryMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 统计摘要
            HStack(spacing: 20) {
                StatBadge(count: stats.exactMatches, label: selectedMode.localized(chinese: "精确", english: "Exact"), color: AppTheme.jewelCyan)
                StatBadge(count: stats.lemmaMatches, label: selectedMode.localized(chinese: "原形", english: "Lemma"), color: AppTheme.jewelPurple)
                StatBadge(count: stats.notFound, label: selectedMode.localized(chinese: "未找到", english: "Not Found"), color: AppTheme.jewelPink)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .utilityPanel(cornerRadius: AppTheme.radiusM)
            
            // 详细列表
            VStack(alignment: .leading, spacing: 8) {
                Text(selectedMode.localized(chinese: "预览", english: "PREVIEW"))
                    .font(AppFont.section)
                    .kerning(1)
                    .foregroundColor(AppTheme.mutedInk.opacity(0.72))
                
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(results) { result in
                            HStack(spacing: 12) {
                                Text(result.matchType.icon)
                                    .font(AppFont.bodyMono)
                                
                                Text(result.original)
                                    .font(AppFont.bodyMono)
                                    .foregroundColor(result.isMatched ? AppTheme.ink : AppTheme.mutedInk)
                                
                                if result.matchType != .exact && result.matchType != .notFound,
                                   let lemma = result.lemma {
                                    Text("→")
                                        .font(AppFont.secondarySmall)
                                        .foregroundColor(AppTheme.mutedInk)
                                    
                                    Text(lemma)
                                        .font(AppFont.bodyMono)
                                        .fontWeight(.semibold)
                                        .foregroundColor(AppTheme.jewelPurple)
                                }
                                
                                Spacer()
                                
                                if result.matchType != .exact && result.matchType != .notFound {
                                    Text(result.matchType.localizedDescription(for: selectedMode))
                                        .font(AppFont.label)
                                        .foregroundColor(AppTheme.mutedInk.opacity(0.62))
                                }
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            
                            if result.id != results.last?.id {
                                Divider().padding(.leading, 44)
                            }
                        }
                    }
                }
                .frame(maxHeight: 250)
                .background(AppTheme.surfaceElevated)
                .utilityPanel(cornerRadius: AppTheme.radiusM)
            }
        }
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(AppFont.valueCard)
                .foregroundColor(color)
            
            Text(label)
                .font(AppFont.label)
                .foregroundColor(AppTheme.mutedInk.opacity(0.72))
        }
        .frame(maxWidth: .infinity)
    }
}
