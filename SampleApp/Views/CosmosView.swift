//
//  CosmosView.swift
//  wordety
//
//  Created by SkyRocket on 2025/12/26.
//

import SwiftUI

struct CosmosView: View {
    @StateObject private var cosmosVM = CosmosViewModel()
    @ObservedObject private var packManager = WordPackManager.shared
    @ObservedObject private var plusAccess = PlusAccessManager.shared
    @ObservedObject private var masteryStore = MasteryStore.shared
    @ObservedObject private var dictionaryModeManager = DictionaryModeManager.shared
    @EnvironmentObject var searchVM: SearchViewModel
    @State private var showExitConfirmation = false

    var body: some View {
        ZStack {
            UtilityBackdrop()
                .ignoresSafeArea()

            if cosmosVM.isFinished {
                CosmosSummaryView(
                    score: cosmosVM.score,
                    total: cosmosVM.testWords.count,
                    selectedMode: dictionaryModeManager.selectedMode
                ) {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                        cosmosVM.resetTest()
                    }
                }
            } else if cosmosVM.testWords.isEmpty {
                CosmosCoverView(
                    cosmosVM: cosmosVM,
                    packManager: packManager,
                    historySlugs: searchVM.searchHistory,
                    selectedMode: dictionaryModeManager.selectedMode
                ) {
                    cosmosVM.startTest(historySlugs: searchVM.searchHistory)
                }
            } else {
                practiceView
            }
        }
        .alert(dictionaryModeManager.selectedMode.localized(chinese: "退出练习？", english: "Abandon Quiz?"), isPresented: $showExitConfirmation) {
            Button(dictionaryModeManager.selectedMode.localized(chinese: "取消", english: "Cancel"), role: .cancel) { }
            Button(dictionaryModeManager.selectedMode.localized(chinese: "退出", english: "Abandon"), role: .destructive) {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                    cosmosVM.resetTest()
                }
            }
        } message: {
            Text(dictionaryModeManager.selectedMode.localized(chinese: "当前练习进度不会保留。", english: "Your current quiz progress will be lost."))
        }
    }

    private var practiceView: some View {
        VStack(spacing: 0) {
            CosmosProgressHeader(
                current: cosmosVM.currentIndex + 1,
                total: cosmosVM.testWords.count,
                score: cosmosVM.starCount,
                selectedMode: dictionaryModeManager.selectedMode,
                onExit: {
                    showExitConfirmation = true
                }
            )
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 12)

            CosmosFlashCard(
                word: cosmosVM.testWords[cosmosVM.currentIndex],
                isFlipped: cosmosVM.isFlipped,
                isCorrect: cosmosVM.isCorrect,
                masteryCount: plusAccess.canTrackMastery ? masteryStore.mastery(for: cosmosVM.testWords[cosmosVM.currentIndex].slug) : nil,
                selectedMode: dictionaryModeManager.selectedMode
            )
            .padding(.horizontal, 18)
            .padding(.bottom, 12)

            Group {
                if cosmosVM.isFlipped {
                    CosmosContinuePanel(
                        isCorrect: cosmosVM.isCorrect,
                        isLast: cosmosVM.currentIndex + 1 >= cosmosVM.testWords.count,
                        selectedMode: dictionaryModeManager.selectedMode
                    ) {
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                            cosmosVM.nextQuestion()
                        }
                    }
                } else {
                    CosmosOptionsPanel(
                        options: cosmosVM.currentOptions,
                        selectedOptionId: cosmosVM.selectedOptionId
                    ) { option in
                        cosmosVM.selectOption(option)
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 20)
        }
    }
}

private struct CosmosProgressHeader: View {
    let current: Int
    let total: Int
    let score: Int
    let selectedMode: DictionaryMode
    let onExit: () -> Void

    var progressCount: Int {
        max(total, 1)
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center) {
                Text(selectedMode.localized(chinese: "练习", english: "QUIZ"))
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(AppTheme.selectedEdition == .comic ? AppTheme.ink : AppTheme.mutedInk)
                    .shadow(color: AppTheme.selectedEdition == .comic ? AppTheme.warningYellow : .clear, radius: 0, x: 2, y: 2)
                    .tracking(1.4)

                Spacer()

                Text("\(current) / \(total)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(AppTheme.selectedEdition == .comic ? AppTheme.ink : AppTheme.wordmarkBlue)
                    .padding(.horizontal, AppTheme.selectedEdition == .comic ? 9 : 0)
                    .padding(.vertical, AppTheme.selectedEdition == .comic ? 5 : 0)
                    .background {
                        if AppTheme.selectedEdition == .comic {
                            Color.clear
                                .comicCapsule(fill: AppTheme.warningYellow, shadow: AppTheme.heroBlue, lineWidth: 2)
                        }
                    }

                Button(selectedMode.localized(chinese: "退出", english: "Exit")) {
                    onExit()
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.mutedInk)
                .padding(.leading, 12)
            }

            HStack(spacing: 6) {
                ForEach(0..<progressCount, id: \.self) { index in
                    Capsule()
                        .fill(progressColor(for: index))
                        .frame(height: AppTheme.selectedEdition == .comic ? 8 : 6)
                        .overlay {
                            if AppTheme.selectedEdition == .comic {
                                Capsule()
                                    .stroke(AppTheme.outline.opacity(0.65), lineWidth: 1)
                            }
                        }
                }
            }
        }
    }

    private func progressColor(for index: Int) -> Color {
        if index < score {
            return AppTheme.wordmarkBlue
        }
        if index < current - 1 {
            return AppTheme.wordmarkBlue.opacity(0.22)
        }
        return AppTheme.divider.opacity(0.74)
    }
}

private struct CosmosFlashCard: View {
    let word: Word
    let isFlipped: Bool
    let isCorrect: Bool
    let masteryCount: Int?
    let selectedMode: DictionaryMode

    private let frontHeight: CGFloat = 278
    private let backHeight: CGFloat = 370

    var body: some View {
        ZStack(alignment: .top) {
            frontFace
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(isFlipped ? -180 : 0),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.55
                )

            backFace
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : 180),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.55
                )
        }
        .frame(maxWidth: .infinity)
        .frame(height: isFlipped ? backHeight : frontHeight, alignment: .top)
        .clipped()
        .animation(.spring(response: 0.55, dampingFraction: 0.88), value: isFlipped)
    }

    private var frontFace: some View {
        VStack(alignment: .leading, spacing: 0) {
            CosmosWordHeader(word: word, masteryCount: masteryCount, selectedMode: selectedMode)
                .padding(.horizontal, 22)
                .padding(.top, 22)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(cardBackground(shadowColor: AppTheme.wordmarkBlue.opacity(0.10)))
    }

    private var backFace: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                CosmosWordHeader(word: word, masteryCount: masteryCount, selectedMode: selectedMode)

                VStack(alignment: .leading, spacing: 12) {
                    CosmosSection(title: selectedMode.localized(chinese: "释义", english: "MEANING"), tint: AppTheme.wordmarkPink) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(word.definitions) { definition in
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Text(definition.pos.uppercased())
                                        .font(.system(size: 13, weight: .black, design: .rounded))
                                        .foregroundColor(dopaminePartOfSpeechColor(definition.pos))
                                        .lineLimit(1)

                                    Text(definition.meaning.cleanedDisplayText)
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundColor(AppTheme.ink.opacity(0.90))
                                        .lineSpacing(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }

                    if !word.morphemes.isEmpty {
                        CosmosSection(title: selectedMode.localized(chinese: "构词部件", english: "WORD PARTS"), tint: AppTheme.wordmarkBlue) {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 112), spacing: 8)], alignment: .leading, spacing: 8) {
                                ForEach(word.morphemes) { morpheme in
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("<\(morpheme.piece.cleanedDisplayText)>")
                                            .font(.system(size: 14, weight: .black, design: .rounded))
                                            .foregroundColor(AppTheme.wordmarkBlue)
                                            .lineLimit(1)

                                        Text(morpheme.gloss.cleanedDisplayText)
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                            .foregroundColor(AppTheme.ink)
                                            .lineLimit(2)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(AppTheme.surfaceElevated)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(AppTheme.border, lineWidth: 1)
                                            )
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)
            .padding(.bottom, 22)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            CosmosResultBadge(isCorrect: isCorrect, selectedMode: selectedMode)
                .padding(.trailing, 18)
                .padding(.bottom, 16)
        }
        .background(cardBackground(shadowColor: (isCorrect ? AppTheme.wordmarkBlue : AppTheme.wordmarkPink).opacity(0.14)))
    }

    private func cardBackground(shadowColor: Color) -> some View {
        Group {
            if AppTheme.selectedEdition == .comic {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(shadowColor.opacity(0.90))
                    .offset(x: 7, y: 7)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.surfaceElevated)
                            .overlay(
                                ComicHalftoneDots(color: shadowColor.opacity(0.20), spacing: 12, dotSize: 3)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(AppTheme.outline, lineWidth: 4)
                            )
                    )
            } else {
                RoundedRectangle(cornerRadius: AppTheme.radiusL, style: .continuous)
                    .fill(AppTheme.surfaceElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusL, style: .continuous)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
                    .shadow(color: shadowColor.opacity(0.6), radius: 8, x: 0, y: 2)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            }
        }
    }
}

private struct CosmosWordHeader: View {
    let word: Word
    let masteryCount: Int?
    let selectedMode: DictionaryMode
    private let fixedHeight: CGFloat = 148

    private var exampleText: String? {
        guard let first = word.examples.first?.en.cleanedDisplayText, !first.isEmpty else {
            return nil
        }
        return first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(word.wordForDisplay)
                .font(AppFont.wordmark(30))
                .foregroundColor(AppTheme.wordmarkBlue)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .allowsTightening(true)

            if let masteryCount {
                HStack(spacing: 8) {
                    Text(selectedMode.localized(chinese: "熟练度", english: "MASTERY"))
                        .font(AppFont.sfMono(9, weight: .black))
                        .foregroundColor(AppTheme.wordmarkPink)

                    MasteryDots(count: masteryCount, size: 7.2)
                }
            }

            if let exampleText {
                Text(exampleText)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.ink.opacity(0.86))
                    .lineSpacing(5)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, minHeight: fixedHeight, maxHeight: fixedHeight, alignment: .topLeading)
    }
}

private struct CosmosSection<Content: View>: View {
    let title: String
    let tint: Color
    @ViewBuilder let content: Content

    init(title: String, tint: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundColor(tint)
                .tracking(0.8)
            content
        }
    }
}

private struct CosmosResultBadge: View {
    let isCorrect: Bool
    let selectedMode: DictionaryMode

    var body: some View {
        Text(isCorrect
             ? selectedMode.localized(chinese: "答对", english: "APPROVED")
             : selectedMode.localized(chinese: "复习", english: "REVIEW"))
            .font(.system(size: 10, weight: .black, design: .rounded))
            .foregroundColor(isCorrect ? AppTheme.wordmarkBlue : AppTheme.wordmarkPink)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                if AppTheme.selectedEdition == .comic {
                    Color.clear
                        .comicCapsule(
                            fill: AppTheme.surfaceElevated,
                            shadow: isCorrect ? AppTheme.wordmarkBlue : AppTheme.wordmarkPink,
                            lineWidth: 2
                        )
                } else {
                    Capsule()
                        .fill(isCorrect ? AppTheme.wordmarkBlue.opacity(0.12) : AppTheme.wordmarkPink.opacity(0.12))
                        .overlay(
                            Capsule()
                                .stroke(isCorrect ? AppTheme.wordmarkBlue.opacity(0.28) : AppTheme.wordmarkPink.opacity(0.28), lineWidth: 1)
                        )
                }
            }
    }
}

private struct CosmosOptionsPanel: View {
    let options: [CosmosViewModel.Option]
    let selectedOptionId: UUID?
    let onSelect: (CosmosViewModel.Option) -> Void

    private let optionPalette: [Color] = [
        AppTheme.wordmarkBlue,
        AppTheme.wordmarkPink,
        AppTheme.wordmarkBlue,
        AppTheme.wordmarkPink
    ]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                let tint = optionPalette[index % optionPalette.count]
                CosmosOptionRow(
                    label: optionLabel(for: index),
                    tint: tint,
                    meaning: option.meaning.cleanedDisplayText,
                    isSelected: selectedOptionId == option.id
                ) {
                    onSelect(option)
                }
            }
        }
    }

    private func optionLabel(for index: Int) -> String {
        let labels = ["A.", "B.", "C.", "D.", "E.", "F."]
        return labels.indices.contains(index) ? labels[index] : "A."
    }
}

private struct CosmosOptionRow: View {
    let label: String
    let tint: Color
    let meaning: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(label)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(tint)
                    .frame(width: 34, height: 34)
                    .background(
                        Circle()
                            .fill(tint.opacity(isSelected ? 0.22 : 0.14))
                    )

                Text(meaning)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? AppTheme.surfaceElevated : AppTheme.ink.opacity(0.86))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)
                    .lineSpacing(2)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isSelected ? AppTheme.surfaceElevated.opacity(0.75) : AppTheme.mutedInk.opacity(0.7))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background {
                if AppTheme.selectedEdition == .comic {
                    Color.clear
                        .comicPanel(
                            fill: isSelected ? tint : AppTheme.surfaceElevated,
                            shadow: isSelected ? AppTheme.warningYellow : tint.opacity(0.92),
                            cornerRadius: 18,
                            lineWidth: 3,
                            offset: CGSize(width: 4, height: 4)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(isSelected ? tint : AppTheme.surfaceElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(isSelected ? tint.opacity(0.72) : AppTheme.border, lineWidth: 1)
                        )
                }
            }
            .shadow(color: AppTheme.selectedEdition == .comic ? .clear : Color.black.opacity(isSelected ? 0.07 : 0.04), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 0.992 : 1.0)
        .animation(.easeOut(duration: 0.16), value: isSelected)
    }
}

private struct CosmosContinuePanel: View {
    let isCorrect: Bool
    let isLast: Bool
    let selectedMode: DictionaryMode
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(isLast
                 ? selectedMode.localized(chinese: "完成本轮", english: "Finish Session")
                 : selectedMode.localized(chinese: "继续", english: "Continue"))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.selectedEdition == .comic ? AppTheme.ink : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background {
                    if AppTheme.selectedEdition == .comic {
                        Color.clear
                            .comicPanel(
                                fill: isCorrect ? AppTheme.wordmarkBlue : AppTheme.wordmarkPink,
                                shadow: AppTheme.warningYellow,
                                cornerRadius: 16,
                                lineWidth: 3,
                                offset: CGSize(width: 4, height: 4)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: AppTheme.radiusM, style: .continuous)
                            .fill(isCorrect ? AppTheme.wordmarkBlue : AppTheme.wordmarkPink)
                    }
                }
                .shadow(color: AppTheme.selectedEdition == .comic ? .clear : Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

private struct CosmosCoverView: View {
    @ObservedObject var cosmosVM: CosmosViewModel
    @ObservedObject var packManager: WordPackManager
    @ObservedObject private var plusAccess = PlusAccessManager.shared
    let historySlugs: [String]
    let selectedMode: DictionaryMode
    let startAction: () -> Void
    @State private var isShowingPaywall = false

    private var historyCount: Int {
        historySlugs.count
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(selectedMode.localized(chinese: "练习", english: "Quiz"))
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.ink)
                        .shadow(color: AppTheme.selectedEdition == .comic ? AppTheme.warningYellow : .clear, radius: 0, x: 2, y: 2)

                    Text(selectedMode.localized(
                        chinese: "练习最近搜索过的单词，也可以从你的学习合集开始。",
                        english: "Quiz the words you recently searched, or start from one of your study sets."
                    ))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.mutedInk)
                        .lineSpacing(3)
                }
                .padding(.top, 10)

                VStack(spacing: 8) {
                    CosmosSourceRow(
                        icon: "clock.arrow.circlepath",
                        title: selectedMode.localized(chinese: "搜索历史", english: "Search History"),
                        subtitle: selectedMode.localized(chinese: "可用 \(historyCount) 个单词", english: "\(historyCount) words available"),
                        accent: AppTheme.wordmarkBlue,
                        isSelected: cosmosVM.selectedSource == .searchHistory,
                        isAvailable: historyCount >= 5
                    ) {
                        cosmosVM.selectedSource = .searchHistory
                    }

                    ForEach(packManager.practicePacks) { pack in
                        let isLocked = packManager.requiresPlus(for: pack) && !plusAccess.canUseAdvancedWordPacks
                        CosmosSourceRow(
                            icon: "rectangle.stack.fill",
                            title: pack.name,
                            subtitle: packSubtitle(for: pack, isLocked: isLocked),
                            accent: pack.color,
                            isSelected: cosmosVM.selectedSource == .wordPack(pack.id),
                            isAvailable: pack.wordCount >= 5 && !isLocked,
                            isLocked: isLocked,
                            usesRoundedPackIcon: true
                        ) {
                            if isLocked {
                                isShowingPaywall = true
                            } else {
                                cosmosVM.selectedSource = .wordPack(pack.id)
                            }
                        }
                    }
                }

                if packManager.packs.isEmpty {
                    Text(selectedMode.localized(
                        chinese: "如果想自定义练习来源，可以在设置里创建学习合集。",
                        english: "Create study sets in Settings if you want a custom practice source."
                    ))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.mutedInk)
                }

                Button(action: startAction) {
                    Text(selectedMode.localized(chinese: "开始练习", english: "Start Quiz"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.selectedEdition == .comic ? AppTheme.ink : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background {
                            if AppTheme.selectedEdition == .comic {
                                Color.clear
                                    .comicPanel(
                                        fill: canStart ? AppTheme.wordmarkBlue : AppTheme.surface,
                                        shadow: canStart ? AppTheme.warningYellow : AppTheme.mutedInk.opacity(0.35),
                                        cornerRadius: 16,
                                        lineWidth: 3,
                                        offset: CGSize(width: 4, height: 4)
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: AppTheme.radiusM, style: .continuous)
                                    .fill(canStart ? AppTheme.wordmarkBlue : AppTheme.mutedInk.opacity(0.45))
                            }
                        }
                }
                .buttonStyle(.plain)
                .disabled(!canStart)

                if !canStart {
                    Text(unavailableHint)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.wordmarkPink)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView()
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }

    private var canStart: Bool {
        cosmosVM.isSourceAvailable(
            for: cosmosVM.selectedSource,
            historySlugs: historySlugs
        )
    }

    private var unavailableHint: String {
        selectedMode.localized(
            chinese: "当前来源至少需要 5 个单词才能开始。",
            english: "You need at least 5 words in the selected source to begin."
        )
    }

    private func packSubtitle(for pack: WordPack, isLocked: Bool) -> String {
        if isLocked {
            return selectedMode.localized(
                chinese: "Plus 可用 · \(pack.wordCount) 个单词",
                english: "Plus · \(pack.wordCount) words"
            )
        }

        return selectedMode.localized(
            chinese: "\(pack.wordCount) 个单词",
            english: "\(pack.wordCount) words in this pack"
        )
    }
}

private struct CosmosSourceRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let accent: Color
    let isSelected: Bool
    let isAvailable: Bool
    var isLocked = false
    var usesRoundedPackIcon = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if usesRoundedPackIcon {
                    RoundedPackIcon(accent: accent)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(accent)
                        .frame(width: 20)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(isAvailable || isLocked ? AppTheme.ink : AppTheme.mutedInk)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.mutedInk)
                        .lineLimit(1)
                }

                Spacer()

                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(accent.opacity(0.82))
                        .frame(width: 16, height: 16)
                } else {
                    Circle()
                        .fill(isSelected ? accent : Color.clear)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? accent : Color.black.opacity(0.15), lineWidth: 1.5)
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background {
                if AppTheme.selectedEdition == .comic {
                    Color.clear
                        .comicPanel(
                            fill: AppTheme.surfaceElevated,
                            shadow: isSelected ? accent : AppTheme.warningYellow,
                            cornerRadius: 14,
                            lineWidth: 3,
                            offset: CGSize(width: 4, height: 4)
                        )
                } else {
                    RoundedRectangle(cornerRadius: AppTheme.radiusM, style: .continuous)
                        .fill(AppTheme.surfaceElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusM, style: .continuous)
                                .stroke(isSelected ? accent.opacity(0.38) : AppTheme.border, lineWidth: 1)
                        )
                }
            }
            .shadow(color: AppTheme.selectedEdition == .comic ? .clear : Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable && !isLocked)
        .opacity(isAvailable || isLocked ? 1.0 : 0.58)
    }
}

private struct RoundedPackIcon: View {
    let accent: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(accent.opacity(0.25))
                .frame(width: 15, height: 13)
                .offset(x: 4, y: -4)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(accent.opacity(0.45))
                .frame(width: 15, height: 13)
                .offset(x: 1, y: -1)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(accent)
                .frame(width: 15, height: 13)
                .offset(x: -3, y: 3)
        }
    }
}

private struct CosmosSummaryView: View {
    let score: Int
    let total: Int
    let selectedMode: DictionaryMode
    let action: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 30)

            Text(selectedMode.localized(chinese: "本轮完成", english: "Session Complete"))
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundColor(AppTheme.ink)
                .shadow(color: AppTheme.selectedEdition == .comic ? AppTheme.warningYellow : .clear, radius: 0, x: 2, y: 2)

            Text("\(score) / \(total)")
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundColor(AppTheme.wordmarkBlue)

            Text(selectedMode.localized(
                chinese: "这组练习可以再来一轮。",
                english: "Your quiz set is ready for another round."
            ))
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.mutedInk)
                .multilineTextAlignment(.center)

            Button(action: action) {
                Text(selectedMode.localized(chinese: "返回来源", english: "Back To Sources"))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.selectedEdition == .comic ? AppTheme.ink : .white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 15)
                    .background {
                        if AppTheme.selectedEdition == .comic {
                            Color.clear
                                .comicPanel(
                                    fill: AppTheme.wordmarkBlue,
                                    shadow: AppTheme.warningYellow,
                                    cornerRadius: 16,
                                    lineWidth: 3,
                                    offset: CGSize(width: 4, height: 4)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: AppTheme.radiusM, style: .continuous)
                                .fill(AppTheme.wordmarkBlue)
                        }
                    }
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 20)
    }
}
