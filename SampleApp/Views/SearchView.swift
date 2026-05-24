//
//  SearchView.swift
//  wordety
//
//  Created by SkyRocket on 2025/12/22.
//

import SwiftUI
import UIKit

struct SearchView: View {
    @EnvironmentObject var viewModel: SearchViewModel
    @ObservedObject private var dictionaryModeManager = DictionaryModeManager.shared
    @ObservedObject private var reviewStore = ReviewStore.shared
    @State private var searchText = ""
    @FocusState private var isFocused: Bool

    private var isModernArchivist: Bool {
        AppTheme.selectedEdition == .modernArchivist
    }

    private var usesChineseInterface: Bool {
        dictionaryModeManager.selectedMode == .encn
    }

    var body: some View {
        ZStack {
            UtilityBackdrop()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                searchBar
                content
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: isModernArchivist ? 12 : 8) {
            Button {
                searchText = ""
                viewModel.clearSearch()
                isFocused = false
            } label: {
                Image("OpenEtymologyLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: isModernArchivist ? 72 : 68, height: isModernArchivist ? 72 : 68)
                    .clipShape(RoundedRectangle(cornerRadius: logoCornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: logoCornerRadius, style: .continuous)
                            .stroke(logoBorderColor, lineWidth: logoBorderWidth)
                    )
                    .background(alignment: .center) {
                        if AppTheme.selectedEdition == .comic {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(AppTheme.warningYellow)
                                .offset(x: 4, y: 4)
                        }
                    }
            }
            .buttonStyle(.plain)

            VStack(alignment: .center, spacing: isModernArchivist ? 5 : 3) {
                Button {
                    searchText = ""
                    viewModel.clearSearch()
                    isFocused = false
                } label: {
                    brandTitle
                }
                .buttonStyle(.plain)

                modeSwitch(compact: true, fillWidth: false)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 22)
        .padding(.top, isModernArchivist ? 14 : 8)
        .padding(.bottom, isModernArchivist ? 8 : 8)
    }

    @ViewBuilder
    private var brandTitle: some View {
        if isModernArchivist {
            (
                Text("Open")
                    .foregroundColor(AppTheme.wordmarkPink)
                +
                Text("Etymology")
                    .foregroundColor(AppTheme.wordmarkBlue)
            )
            .font(AppFont.wordmark(30))
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .accessibilityLabel("OpenEtymology")
        } else {
            (
                Text("Open")
                    .foregroundColor(AppTheme.wordmarkPink)
                +
                Text("Etymology")
                    .foregroundColor(AppTheme.wordmarkBlue)
            )
            .font(AppFont.wordmark(23))
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .offset(y: -2)
            .shadow(color: AppTheme.selectedEdition == .comic ? AppTheme.warningYellow : .clear, radius: 0, x: 2, y: 2)
        }
    }

    private var logoCornerRadius: CGFloat {
        if isModernArchivist { return 8 }
        return AppTheme.selectedEdition == .comic ? 10 : AppTheme.radiusM
    }

    private var logoBorderColor: Color {
        if isModernArchivist { return AppTheme.border.opacity(0.24) }
        return AppTheme.selectedEdition == .comic ? AppTheme.outline : AppTheme.border
    }

    private var logoBorderWidth: CGFloat {
        if isModernArchivist { return 0 }
        return AppTheme.selectedEdition == .comic ? 3 : 1
    }

    private func modeSwitch(compact: Bool, fillWidth: Bool) -> some View {
        DictionaryModeSwitch(
            selectedMode: dictionaryModeManager.selectedMode,
            compact: compact,
            embedded: true,
            fillWidth: fillWidth
        ) { mode in
            viewModel.setDictionaryMode(mode, refreshQuery: searchText)
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.mutedInk)
                .font(.system(size: 16, weight: .semibold))

            TextField(
                "",
                text: $searchText,
                prompt: Text(searchPlaceholder).foregroundColor(AppTheme.mutedInk.opacity(0.48))
            )
            .foregroundColor(AppTheme.ink)
            .font(isModernArchivist ? AppFont.editorial(20, weight: .medium) : AppFont.ui(19, weight: .semibold))
            .keyboardType(.asciiCapable)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .tint(AppTheme.wordmarkBlue)
            .focused($isFocused)
            .onChange(of: searchText) { _, newValue in
                viewModel.updateSuggestions(query: newValue)
            }
            .submitLabel(.search)
            .onSubmit {
                viewModel.search(query: searchText)
                isFocused = false
            }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    viewModel.clearSearch()
                    isFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.mutedInk.opacity(0.42))
                }
            }
        }
        .padding(.horizontal, isModernArchivist ? 18 : 18)
        .padding(.vertical, isModernArchivist ? 14 : 11)
        .background(searchBarBackground)
        .contentShape(RoundedRectangle(cornerRadius: AppTheme.radiusL, style: .continuous))
        .simultaneousGesture(
            TapGesture().onEnded {
                focusSearchField()
            }
        )
        .animation(.easeOut(duration: 0.16), value: isFocused)
        .padding(.horizontal, 18)
        .padding(.bottom, isModernArchivist ? 14 : 6)
    }

    private func focusSearchField() {
        guard !isFocused else { return }
        isFocused = true

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 8_000_000)
            isFocused = true
        }
    }

    private var searchPlaceholder: String {
        if usesChineseInterface {
            return "点击搜索单词..."
        }
        return isModernArchivist ? "Search words or forms..." : "Search for word..."
    }

    @ViewBuilder
    private var searchBarBackground: some View {
        if isModernArchivist {
            RoundedRectangle(cornerRadius: AppTheme.radiusL, style: .continuous)
                .fill(AppTheme.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusL, style: .continuous)
                        .stroke(isFocused ? AppTheme.wordmarkBlue.opacity(0.32) : AppTheme.border.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: (isFocused ? AppTheme.wordmarkBlue : AppTheme.outline).opacity(isFocused ? 0.12 : 0.045), radius: isFocused ? 14 : 12, x: 0, y: isFocused ? 5 : 4)
        } else if AppTheme.selectedEdition == .comic {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(AppTheme.heroBlue)
                    .offset(x: 5, y: 5)

                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(AppTheme.surfaceElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .stroke(AppTheme.outline, lineWidth: 3)
                    )
            }
        } else {
            RoundedRectangle(cornerRadius: AppTheme.radiusL, style: .continuous)
                .fill(AppTheme.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusL, style: .continuous)
                        .stroke((isFocused ? AppTheme.wordmarkBlue : AppTheme.border).opacity(isFocused ? 0.32 : 0.82), lineWidth: 1)
                )
                .shadow(color: (isFocused ? AppTheme.wordmarkBlue : Color.black).opacity(0.08), radius: 10, x: 0, y: 3)
        }
    }

    @ViewBuilder
    private var content: some View {
        ZStack {
            if isFocused && !viewModel.suggestions.isEmpty {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(viewModel.suggestions, id: \.self) { suggestion in
                            SuggestionRow(text: suggestion) {
                                searchText = suggestion
                                viewModel.search(query: suggestion)
                                isFocused = false
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                .transition(.opacity)
            } else if viewModel.hasSearched {
                ScrollView(showsIndicators: false) {
                    if viewModel.isLoadingWord {
                        DictionaryLoadingView(selectedMode: dictionaryModeManager.selectedMode)
                            .padding(.horizontal, 20)
                            .padding(.top, 32)
                    } else if let word = viewModel.currentWord {
                        WordDetailView(word: word, selectedMode: dictionaryModeManager.selectedMode)
                            .padding(.bottom, 40)
                    } else {
                        DictionaryLookupUnavailableView(
                            message: viewModel.errorMessage ?? dictionaryModeManager.selectedMode.missingEntryMessage,
                            selectedMode: dictionaryModeManager.selectedMode
                        ) {
                            viewModel.setDictionaryMode(.encn, refreshQuery: searchText)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 32)
                    }
                }
            } else {
                ScrollView(showsIndicators: false) {
                    Group {
                        if isModernArchivist {
                            ModernArchivistLanding()
                        } else {
                            VStack(spacing: 12) {
                                CompactReviewCard(
                                    dueCount: reviewStore.dueCount,
                                    historyCount: viewModel.searchHistory.count,
                                    selectedMode: dictionaryModeManager.selectedMode
                                )

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(usesChineseInterface ? "从一个单词开始。" : "Start with a word.")
                                        .font(AppFont.editorial(22, weight: .bold))
                                        .foregroundColor(AppTheme.ink.opacity(0.86))

                                    Text(usesChineseInterface ? "搜索后即可打开学习卡片，单词会自动加入复习。" : "Search to open a word card, and it will join review automatically.")
                                        .font(AppFont.editorial(14))
                                        .foregroundColor(AppTheme.mutedInk)
                                        .lineSpacing(4)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .padding(.top, 2)
                                .utilityPanel(cornerRadius: AppTheme.radiusL)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, isModernArchivist ? 2 : 4)
                }
            }
        }
    }
}

struct WordDetailView: View {
    let word: Word
    var selectedMode: DictionaryMode = DictionaryModeManager.shared.selectedMode
    @ObservedObject private var detailTextSizeManager = DetailTextSizeManager.shared

    private var structureText: String {
        let pieces = word.morphemes.map(\.piece).filter { !$0.isEmpty }
        return pieces.isEmpty ? word.slug : pieces.joined(separator: " + ")
    }

    private var etymologyText: String {
        let raw = (word.etymologyAnalysis?.cleanedDisplayText).flatMap { $0.isEmpty ? nil : $0 }
            ?? (word.etymologyOrigin?.cleanedDisplayText).flatMap { $0.isEmpty ? nil : $0 }
            ?? (selectedMode == .encn ? "暂无词源说明。" : "No etymology note available.")
        return selectedMode == .enen ? EnglishDisplayTextFormatter.shared.capitalizingLeadingLetter(in: raw) : raw
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            wordHeader

            VStack(spacing: 10) {
                ContentCard(title: "MEANING", color: AppTheme.wordmarkBlue, titleUsesWordmark: true) {
                    VStack(alignment: .leading, spacing: 9) {
                        ForEach(word.definitions) { def in
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Text(def.pos.uppercased())
                                    .font(AppFont.wordmark(detailSize(13)))
                                    .foregroundColor(dopaminePartOfSpeechColor(def.pos))
                                    .lineLimit(1)

                                Text(def.meaning.cleanedDisplayText)
                                    .font(AppFont.editorial(detailSize(16), weight: .medium))
                                    .foregroundColor(AppTheme.ink.opacity(0.88))
                                    .lineSpacing(3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }

                if !word.morphemes.isEmpty {
                    ContentCard(title: "WORD PARTS", color: AppTheme.wordmarkBlue, titleUsesWordmark: true) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(word.morphemes) { morpheme in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("<\(morpheme.piece)>")
                                        .font(AppFont.editorial(detailSize(14), weight: .bold))
                                        .foregroundColor(AppTheme.ink)
                                        .lineLimit(1)

                                    Text(morpheme.gloss.cleanedDisplayText)
                                        .font(AppFont.editorial(detailSize(15)))
                                        .foregroundColor(AppTheme.ink)
                                        .lineSpacing(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }

                ContentCard(title: "STRUCTURE", color: AppTheme.wordmarkBlue, titleUsesWordmark: true) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(structureText)
                            .font(AppFont.editorial(detailSize(17), weight: .bold))
                            .foregroundColor(AppTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)

                        if !word.morphemes.isEmpty {
                            Text(
                                word.morphemes
                                    .map { "\($0.piece.cleanedDisplayText): \($0.gloss.cleanedDisplayText)" }
                                    .joined(separator: "  ·  ")
                            )
                            .font(AppFont.editorial(detailSize(15)))
                            .foregroundColor(AppTheme.ink.opacity(0.82))
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                ContentCard(title: "ETYMOLOGY", color: AppTheme.wordmarkBlue, titleUsesWordmark: true) {
                    EtymologyDetailBlock(word: word, selectedMode: selectedMode)
                }

                if !word.examples.isEmpty {
                    ContentCard(title: "USAGE", color: AppTheme.wordmarkBlue, titleUsesWordmark: true) {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(Array(word.examples.enumerated()), id: \.offset) { index, example in
                                UsageExampleBlock(
                                    index: index + 1,
                                    example: example,
                                    targetWord: word.slug,
                                    mode: selectedMode
                                )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
        }
    }

    private var wordHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            if AppTheme.selectedEdition == .comic {
                ZStack(alignment: .leading) {
                    ComicBurst(points: 16, innerRatio: 0.76)
                        .fill(AppTheme.warningYellow)
                        .overlay(
                            ComicBurst(points: 16, innerRatio: 0.76)
                                .stroke(AppTheme.outline, lineWidth: 3)
                        )
                        .frame(width: 188, height: 74)
                        .offset(x: -14, y: 0)
                        .rotationEffect(.degrees(-3))

                    HighlightedWordText(word: word.wordForDisplay)
                        .font(AppFont.wordmark(44))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .shadow(color: AppTheme.surfaceElevated, radius: 0, x: 2, y: 2)
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HighlightedWordText(word: word.wordForDisplay)
                    .font(AppFont.wordmark(44))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .textSelection(.enabled)
            }

            PronunciationLine(
                pronUk: word.pronUk,
                pronUs: word.pronUs,
                word: word.wordForDisplay
            )
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private func detailSize(_ base: CGFloat) -> CGFloat {
        detailTextSizeManager.adjusted(base)
    }
}

private struct CompactReviewCard: View {
    let dueCount: Int
    let historyCount: Int
    let selectedMode: DictionaryMode

    var body: some View {
        HStack(spacing: 12) {
            metric(title: selectedMode == .encn ? "复习" : "REVIEW", value: "\(dueCount)", color: AppTheme.wordmarkBlue)
            metric(title: selectedMode == .encn ? "历史" : "HISTORY", value: "\(historyCount)", color: AppTheme.wordmarkPink)
        }
        .frame(maxWidth: .infinity)
    }

    private func metric(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(AppFont.sfMono(10, weight: .black))
                .foregroundColor(color)
            Text(value)
                .font(AppFont.editorial(24, weight: .bold))
                .foregroundColor(AppTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .utilityPanel(cornerRadius: AppTheme.radiusM, accent: color)
    }
}

private struct ModernArchivistLanding: View {
    @ObservedObject private var dictionaryModeManager = DictionaryModeManager.shared
    @State private var focusWord: Word?
    @State private var englishFocusWord: Word?
    @State private var recentFocusSlugs: [String] = []

    private let fallbackMeanings = [
        DailyFocusMeaning(partOfSpeech: "ADJ", text: "声音甜美悦耳，听起来柔和流畅。"),
        DailyFocusMeaning(partOfSpeech: "ETY", text: "源自拉丁语 mel（蜂蜜），带有甜美、流动的含义。")
    ]
    private let fallbackEnglishMeanings = [
        DailyFocusMeaning(partOfSpeech: "ADJ", text: "Sweet or musical; pleasant to hear, especially of a voice or sound."),
        DailyFocusMeaning(partOfSpeech: "ETY", text: "From Latin mel, honey, with a sense of sweetness and flow.")
    ]
    private let fallbackStructure = "mel<蜂蜜>+flu<流动>+ous<形容词后缀>"
    private let fallbackEnglishStructure = "mel<honey>+flu<flow>+ous<adjective suffix>"
    nonisolated private static let curatedFocusSlugs = [
        "mellifluous",
        "serendipity",
        "resilient",
        "clarity",
        "curious",
        "benevolent",
        "luminous",
        "tranquil",
        "eloquent",
        "vivid",
        "diligent",
        "vital",
        "candid",
        "lucid",
        "nimble",
        "prudent",
        "radiant",
        "graceful",
        "harmonious",
        "tenacious",
        "versatile",
        "meticulous",
        "flourish",
        "navigate",
        "discover",
        "cultivate",
        "imagine",
        "remember",
        "compose",
        "connect"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if dictionaryModeManager.selectedMode == .encn {
                focusCard
            } else {
                englishFocusCard
            }
        }
        .padding(.bottom, 36)
        .task(id: focusTaskID) {
            await loadRandomFocus()
        }
        .task {
            await autoRefreshFocusWord()
        }
    }

    private var focusTaskID: String {
        dictionaryModeManager.selectedMode.rawValue
    }

    private var focusCard: some View {
        DailyFocusCard(
            wordTitle: focusWordTitle,
            structure: structure(for: focusWord) ?? structureFallback(for: focusWord, mode: dictionaryModeManager.selectedMode),
            meanings: meanings(for: focusWord).nonEmptyValue ?? fallbackMeaningLines(for: dictionaryModeManager.selectedMode),
            watermarkInitial: watermarkInitial,
            colors: focusCardColors,
            shadowColor: AppTheme.wordmarkBlue.opacity(0.15),
            refreshAccessibilityLabel: "刷新首页单词",
            onRefresh: refreshFocusWord
        )
    }

    private var englishFocusCard: some View {
        DailyFocusCard(
            wordTitle: englishFocusWordTitle,
            structure: structure(for: englishFocusWord) ?? structureFallback(for: englishFocusWord, mode: .enen),
            meanings: meanings(for: englishFocusWord).nonEmptyValue ?? fallbackEnglishMeanings,
            watermarkInitial: watermarkInitial(for: englishFocusWordTitle),
            colors: [AppTheme.wordmarkBlue, AppTheme.jewelCyan],
            shadowColor: AppTheme.wordmarkBlue.opacity(0.16),
            refreshAccessibilityLabel: "Refresh daily word",
            onRefresh: refreshFocusWord
        )
    }

    private var focusCardColors: [Color] {
        [AppTheme.wordmarkBlue, AppTheme.jewelCyan]
    }

    private var focusWordTitle: String {
        focusWord?.wordForDisplay.cleanedDisplayText.nonEmptyValue ?? "Mellifluous"
    }

    private var englishFocusWordTitle: String {
        englishFocusWord?.wordForDisplay.cleanedDisplayText.nonEmptyValue ?? "Mellifluous"
    }

    private var watermarkInitial: String {
        watermarkInitial(for: focusWordTitle)
    }

    private func watermarkInitial(for title: String) -> String {
        guard let first = title.first else { return "M" }
        return String(first).uppercased()
    }

    private func meanings(for word: Word?) -> [DailyFocusMeaning] {
        word?.definitions
            .prefix(2)
            .compactMap { definition -> DailyFocusMeaning? in
                let text = definition.meaning.cleanedDisplayText
                guard !text.isEmpty else { return nil }

                return DailyFocusMeaning(
                    partOfSpeech: definition.pos.cleanedDisplayText.uppercased().nonEmptyValue,
                    text: text
                )
            } ?? []
    }

    private func structure(for word: Word?) -> String? {
        let pieces = word?.morphemes
            .sorted { $0.position < $1.position }
            .compactMap { morpheme -> String? in
                let piece = morpheme.piece.cleanedDisplayText
                guard !piece.isEmpty else { return nil }

                let gloss = morpheme.gloss.cleanedDisplayText
                return gloss.isEmpty ? piece : "\(piece)<\(gloss)>"
            } ?? []
        guard !pieces.isEmpty else { return nil }
        return pieces.joined(separator: "+")
    }

    private func structureFallback(for word: Word?, mode: DictionaryMode) -> String {
        if let display = word?.wordForDisplay.cleanedDisplayText.nonEmptyValue {
            return display
        }
        return mode == .enen ? fallbackEnglishStructure : fallbackStructure
    }

    private func fallbackMeaningLines(for mode: DictionaryMode) -> [DailyFocusMeaning] {
        mode == .enen ? fallbackEnglishMeanings : fallbackMeanings
    }

    private func refreshFocusWord() {
        let excludedSlugs = focusExclusionSlugs
        Task {
            await loadRandomFocus(excluding: excludedSlugs)
        }
    }

    private var focusExclusionSlugs: [String] {
        Array(Set(recentFocusSlugs + currentFocusSlugs))
    }

    private var currentFocusSlugs: [String] {
        [focusWord?.slug, englishFocusWord?.slug].compactMap { $0 }
    }

    private func loadRandomFocus(excluding excludedSlugs: [String] = []) async {
        let selectedMode = dictionaryModeManager.selectedMode
        let result = await Task.detached(priority: .utility) {
            let repository = WordRepository()
            switch selectedMode {
            case .encn:
                return (
                    Self.curatedFocusWord(using: repository, mode: .encn, excluding: excludedSlugs),
                    nil as Word?
                )
            case .enen:
                return (
                    nil as Word?,
                    Self.curatedFocusWord(using: repository, mode: .enen, excluding: excludedSlugs)
                )
            }
        }.value

        guard !Task.isCancelled else { return }
        await MainActor.run {
            withAnimation(.smooth(duration: 0.22)) {
                if selectedMode == .encn {
                    focusWord = result.0
                } else {
                    englishFocusWord = result.1
                }
            }
            rememberFocusSlugs(from: result.0, englishWord: result.1)
        }
    }

    private func autoRefreshFocusWord() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(300))
            guard !Task.isCancelled else { return }
            await loadRandomFocus(excluding: focusExclusionSlugs)
        }
    }

    private func rememberFocusSlugs(from word: Word?, englishWord: Word?) {
        let newSlugs = [word?.slug, englishWord?.slug].compactMap { $0?.lowercased() }
        guard !newSlugs.isEmpty else { return }

        var updated = recentFocusSlugs.filter { !newSlugs.contains($0) }
        updated.append(contentsOf: newSlugs)
        recentFocusSlugs = Array(updated.suffix(24))
    }

    nonisolated private static func curatedFocusWord(
        using repository: WordRepository,
        mode: DictionaryMode,
        excluding excludedSlugs: [String]
    ) -> Word? {
        let excluded = Set(excludedSlugs.map { $0.lowercased() })
        let freshCandidates = curatedFocusSlugs.filter { !excluded.contains($0) }.shuffled()
        let candidates = freshCandidates.isEmpty ? curatedFocusSlugs.shuffled() : freshCandidates

        for slug in candidates {
            if let word = repository.getWordBySlug(slug, mode: mode) {
                return word
            }
        }

        return nil
    }
}

private struct DailyFocusMeaning {
    let partOfSpeech: String?
    let text: String
}

private struct DailyFocusCard: View {
    let wordTitle: String
    let structure: String?
    let meanings: [DailyFocusMeaning]
    let watermarkInitial: String
    let colors: [Color]
    let shadowColor: Color
    let refreshAccessibilityLabel: String
    let onRefresh: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Text(watermarkInitial)
                .font(AppFont.editorial(178, weight: .bold))
                .italic()
                .foregroundColor(.white.opacity(0.10))
                .offset(x: -22, y: 38)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(wordTitle)
                        .font(AppFont.editorial(36, weight: .semibold))
                        .italic()
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .padding(.trailing, 46)

                    if let structure {
                        Text(structure)
                            .font(AppFont.sfMono(15, weight: .bold))
                            .tracking(0.15)
                            .foregroundColor(.white.opacity(0.80))
                            .lineLimit(2)
                            .minimumScaleFactor(0.78)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(.white.opacity(0.11))
                            )
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(meanings.enumerated()), id: \.offset) { _, meaning in
                        HStack(alignment: .firstTextBaseline, spacing: 9) {
                            if let partOfSpeech = meaning.partOfSpeech {
                                Text(partOfSpeech)
                                    .font(AppFont.sfMono(10, weight: .black))
                                    .tracking(0.7)
                                    .foregroundColor(dopaminePartOfSpeechColor(partOfSpeech))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(.white.opacity(0.82))
                                    )
                            }

                            Text(meaning.text)
                                .font(AppFont.ui(13, weight: .medium))
                                .foregroundColor(.white.opacity(0.90))
                                .lineSpacing(4)
                                .lineLimit(3)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 22)
            .frame(maxWidth: .infinity, alignment: .leading)

        }
        .frame(maxWidth: .infinity, minHeight: 270, maxHeight: 270, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusL, style: .continuous))
        .shadow(color: shadowColor, radius: 18, x: 0, y: 10)
        .overlay(alignment: .topTrailing) {
            Button {
                onRefresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.88))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(.white.opacity(0.15))
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.26), lineWidth: 1)
                            )
                    )
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
            }
            .buttonStyle(.plain)
            .contentShape(Circle())
            .accessibilityLabel(refreshAccessibilityLabel)
            .padding(.top, 11)
            .padding(.trailing, 11)
            .zIndex(10)
        }
    }
}

private extension String {
    var nonEmptyValue: String? {
        isEmpty ? nil : self
    }
}

private extension Array {
    var nonEmptyValue: [Element]? {
        isEmpty ? nil : self
    }
}

private struct ModernRootFeatureCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 7) {
                Text("GREEK ORIGIN")
                    .font(AppFont.sfMono(10, weight: .black))
                    .foregroundColor(AppTheme.wordmarkBlue)
                    .tracking(1.2)

                Text("-logy")
                    .font(AppFont.editorial(34, weight: .semibold))
                    .foregroundColor(AppTheme.ink)

                Text("From logos, meaning word, reason, or study. The suffix quietly anchoring modern science.")
                    .font(AppFont.ui(13, weight: .medium))
                    .foregroundColor(AppTheme.mutedInk.opacity(0.78))
                    .lineSpacing(3)
            }

            HStack(spacing: 7) {
                rootTag("Biology")
                rootTag("Technology")
                rootTag("Etymology")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .utilityPanel(cornerRadius: AppTheme.radiusL, accent: AppTheme.wordmarkBlue)
    }

    private func rootTag(_ text: String) -> some View {
        Text(text)
            .font(AppFont.sfMono(9, weight: .medium))
            .foregroundColor(AppTheme.mutedInk.opacity(0.78))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusS, style: .continuous)
                    .fill(AppTheme.surface)
            )
    }
}

private struct ModernRootTile: View {
    let root: String
    let meaning: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(root)
                .font(AppFont.editorial(20, weight: .semibold))
                .foregroundColor(AppTheme.ink)

            Text(meaning.uppercased())
                .font(AppFont.sfMono(9, weight: .black))
                .tracking(0.7)
                .foregroundColor(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.radiusM, style: .continuous)
                .fill(tint.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusM, style: .continuous)
                        .stroke(tint.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

private struct UsageExampleBlock: View {
    let index: Int
    let example: Example
    let targetWord: String
    let mode: DictionaryMode
    @ObservedObject private var detailTextSizeManager = DetailTextSizeManager.shared

    private let formatter = EnglishDisplayTextFormatter.shared
    private var sentenceSize: CGFloat { detailTextSizeManager.adjusted(17) }
    private var translationSize: CGFloat { detailTextSizeManager.adjusted(15) }

    var body: some View {
        VStack(alignment: .leading, spacing: mode == .encn ? 4 : 0) {
            HStack(alignment: .top, spacing: 0) {
                let prefix = "\(index). "
                Text(prefix)
                    .font(AppFont.editorial(sentenceSize, weight: .medium))
                    .foregroundColor(AppTheme.ink)

                ExampleSentenceHighlighter.shared.highlightedText(
                    sentence: formatter.capitalizingLeadingLetter(in: example.en.cleanedDisplayText),
                    targetWord: targetWord,
                    highlightColor: AppTheme.wordmarkBlue
                )
                .font(AppFont.editorial(sentenceSize, weight: .medium))
                .foregroundColor(AppTheme.ink)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            }

            if mode == .encn, !example.zh.cleanedDisplayText.isEmpty {
                Text(example.zh.cleanedDisplayText)
                    .font(AppFont.songti(translationSize))
                    .foregroundColor(AppTheme.ink)
                    .lineSpacing(4)
                    .padding(.leading, translatedIndentWidth(for: index))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func translatedIndentWidth(for index: Int) -> CGFloat {
        let digits = "\(index). " as NSString
        let width = digits.size(withAttributes: [.font: UIFont.systemFont(ofSize: sentenceSize, weight: .medium)]).width
        return width
    }
}

private struct EtymologyDetailBlock: View {
    let word: Word
    let selectedMode: DictionaryMode
    @ObservedObject private var detailTextSizeManager = DetailTextSizeManager.shared

    private var content: EtymologyDisplayContent {
        EtymologyDisplayContent.make(
            word: word,
            selectedMode: selectedMode
        )
    }

    private var bodySize: CGFloat {
        detailTextSizeManager.adjusted(15)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let structure = content.structure {
                Text(structure)
                    .font(AppFont.editorial(detailTextSizeManager.adjusted(16), weight: .bold))
                    .foregroundColor(AppTheme.ink)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !content.parts.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    ForEach(Array(content.parts.enumerated()), id: \.offset) { _, part in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Circle()
                                .fill(AppTheme.wordmarkBlue.opacity(0.62))
                                .frame(width: 5, height: 5)

                            Text(part)
                                .font(AppFont.editorial(bodySize, weight: .medium))
                                .foregroundColor(AppTheme.ink.opacity(0.86))
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            if let origin = content.origin {
                VStack(alignment: .leading, spacing: 6) {
                    Text(selectedMode == .encn ? "词源溯源" : "ORIGIN")
                        .font(selectedMode == .encn ? AppFont.yahei(12, weight: .bold) : AppFont.sfMono(11, weight: .black))
                        .foregroundColor(AppTheme.wordmarkBlue)
                        .tracking(0.8)

                    Text(origin)
                        .font(AppFont.editorial(bodySize))
                        .foregroundColor(AppTheme.ink.opacity(0.84))
                        .lineSpacing(4)
                        .padding(.leading, 13)
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(AppTheme.wordmarkBlue)
                                .frame(width: 4)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, content.parts.isEmpty ? 0 : 2)
            }
        }
    }
}

private struct EtymologyDisplayContent {
    let structure: String?
    let parts: [String]
    let origin: String?

    static func make(word: Word, selectedMode: DictionaryMode) -> EtymologyDisplayContent {
        var structure: String?
        var parts: [String] = []
        var originLines: [String] = []
        var isReadingOrigin = false

        let rawAnalysis = word.etymologyAnalysis ?? ""
        for rawLine in rawAnalysis.components(separatedBy: .newlines) {
            let cleaned = clean(rawLine)
            guard !cleaned.isEmpty else { continue }

            if isOriginMarker(cleaned) {
                isReadingOrigin = true
                if let inlineOrigin = originText(afterMarkerIn: cleaned), !inlineOrigin.isEmpty {
                    originLines.append(inlineOrigin)
                }
                continue
            }

            if isReadingOrigin {
                originLines.append(cleaned)
                continue
            }

            if isStructureLine(cleaned) {
                structure = cleaned
            } else if isPartLine(rawLine, cleaned: cleaned) {
                parts.append(contentsOf: splitPartLine(cleaned))
            }
        }

        if parts.isEmpty {
            parts = word.morphemes.map { morpheme in
                let piece = morpheme.piece.cleanedDisplayText
                let gloss = morpheme.gloss.cleanedDisplayText
                return gloss.isEmpty ? piece : "\(piece): \(gloss)"
            }
        }

        let origin = originLines.isEmpty
            ? fallbackOrigin(word: word, selectedMode: selectedMode)
            : originLines.joined(separator: "\n")

        return EtymologyDisplayContent(
            structure: structure,
            parts: parts.filter { !$0.isEmpty },
            origin: origin.flatMap { $0.isEmpty ? nil : $0 }
        )
    }

    private static func clean(_ line: String) -> String {
        var result = line
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        while result.hasPrefix("•") || result.hasPrefix("-") {
            result.removeFirst()
            result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }
        return result
    }

    private static func isOriginMarker(_ line: String) -> Bool {
        let lowercased = line.lowercased()
        return line.contains("词源溯源") || lowercased.hasPrefix("origin")
    }

    private static func originText(afterMarkerIn line: String) -> String? {
        let separators: [Character] = ["：", ":"]
        guard let index = line.firstIndex(where: { separators.contains($0) }) else {
            return nil
        }
        return String(line[line.index(after: index)...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isStructureLine(_ line: String) -> Bool {
        let lowercased = line.lowercased()
        return lowercased.hasPrefix("structure:")
            || lowercased.contains("simplex")
            || line.contains("不可拆分")
            || line.contains(" = ")
    }

    private static func isPartLine(_ rawLine: String, cleaned: String) -> Bool {
        let trimmedRaw = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedRaw.hasPrefix("•")
            || trimmedRaw.hasPrefix("-")
            || cleaned.contains(" + ")
            || cleaned.contains("; ")
    }

    private static func splitPartLine(_ line: String) -> [String] {
        if line.contains(" + ") {
            return line.components(separatedBy: " + ")
                .map(clean)
                .filter { !$0.isEmpty }
        }

        if line.contains("; ") {
            return line.components(separatedBy: "; ")
                .map(clean)
                .filter { !$0.isEmpty }
        }

        return [line]
    }

    private static func fallbackOrigin(word: Word, selectedMode: DictionaryMode) -> String? {
        let raw = (word.etymologyOrigin?.preservingLineDisplayText).flatMap { $0.isEmpty ? nil : $0 }
            ?? (word.etymologyAnalysis?.preservingLineDisplayText).flatMap { $0.isEmpty ? nil : $0 }
        guard let raw else { return selectedMode == .encn ? "暂无词源说明。" : "No etymology note available." }
        return selectedMode == .enen ? EnglishDisplayTextFormatter.shared.capitalizingLeadingLetter(in: raw) : raw
    }
}

private struct HighlightedWordText: View {
    let word: String

    var body: some View {
        Text(word)
            .foregroundColor(AppTheme.wordmarkBlue)
    }
}

func dopaminePartOfSpeechColor(_ rawPartOfSpeech: String) -> Color {
    let normalized = rawPartOfSpeech
        .lowercased()
        .replacingOccurrences(of: ".", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)

    if normalized.hasPrefix("n") {
        return AppTheme.wordmarkBlue
    }
    if normalized.hasPrefix("adj") || normalized == "a" {
        return Color(red: 0.98, green: 0.10, blue: 0.58)
    }
    if normalized.hasPrefix("adv") {
        return AppTheme.jewelPurple
    }
    if normalized.hasPrefix("vi") {
        return Color(red: 0.24, green: 0.82, blue: 0.20)
    }
    if normalized.hasPrefix("vt") {
        return Color(red: 1.00, green: 0.78, blue: 0.08)
    }
    if normalized.hasPrefix("v") {
        return Color(red: 0.24, green: 0.82, blue: 0.20)
    }
    if normalized.hasPrefix("prep") || normalized.hasPrefix("conj") {
        return AppTheme.jewelPurple
    }
    return Color(red: 0.98, green: 0.10, blue: 0.58)
}

struct DictionaryModeSwitch: View {
    let selectedMode: DictionaryMode
    var compact: Bool = false
    var embedded: Bool = false
    var fillWidth: Bool = true
    let action: (DictionaryMode) -> Void
    @Namespace private var selectionNamespace

    private var horizontalPadding: CGFloat { compact ? 6 : 8 }
    private var verticalPadding: CGFloat { compact ? 4 : 6 }

    var body: some View {
        if AppTheme.selectedEdition == .modernArchivist {
            modernBody
        } else {
            legacyBody
        }
    }

    private var modernBody: some View {
        HStack(spacing: 5) {
            ForEach(DictionaryMode.allCases) { mode in
                Button {
                    guard mode != selectedMode else { return }
                    withAnimation(.interactiveSpring(response: 0.28, dampingFraction: 0.86, blendDuration: 0.08)) {
                        action(mode)
                    }
                } label: {
                    Text(modernSwitchLabel(for: mode))
                        .font(AppFont.wordmark(compact ? 16 : 18))
                        .tracking(0.45)
                        .foregroundColor(mode == selectedMode ? modernSelectionTint(for: mode) : AppTheme.ink.opacity(0.40))
                        .padding(.horizontal, compact ? 15 : 18)
                        .padding(.vertical, compact ? 7 : 9)
                        .frame(minWidth: compact ? 56 : 66)
                        .frame(maxWidth: fillWidth ? .infinity : nil)
                        .background {
                            if mode == selectedMode {
                                ZStack {
                                    Capsule()
                                        .fill(modernSelectionTint(for: mode).opacity(0.22))
                                        .offset(y: 2)

                                    Capsule()
                                        .fill(AppTheme.surfaceElevated)
                                        .overlay(
                                            Capsule()
                                                .stroke(.white.opacity(0.95), lineWidth: 1)
                                                .offset(y: -0.5)
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(modernSelectionTint(for: mode).opacity(0.34), lineWidth: 1)
                                        )
                                        .overlay(alignment: .top) {
                                            Capsule()
                                                .fill(.white.opacity(0.96))
                                                .frame(height: 2)
                                                .padding(.horizontal, 12)
                                                .padding(.top, 3)
                                        }
                                        .overlay(alignment: .bottom) {
                                            Capsule()
                                                .fill(modernSelectionTint(for: mode).opacity(0.20))
                                                .frame(height: 2)
                                                .padding(.horizontal, 12)
                                                .padding(.bottom, 2)
                                        }
                                }
                                .matchedGeometryEffect(id: "dictionaryModeSelection", in: selectionNamespace)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mode == .encn ? "中文版本" : "English version")
            }
        }
        .padding(5)
        .background(
            ZStack {
                HStack(spacing: 0) {
                    Capsule()
                        .fill(AppTheme.wordmarkPink.opacity(0.13))
                    Capsule()
                        .fill(AppTheme.wordmarkBlue.opacity(0.13))
                }
                .clipShape(Capsule())
                .offset(y: 2)

                Capsule()
                    .fill(AppTheme.surfaceElevated.opacity(0.92))
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.95), lineWidth: 1)
                            .offset(y: -0.5)
                    )
                    .overlay(
                        Capsule()
                            .stroke(AppTheme.wordmarkBlue.opacity(0.16), lineWidth: 1)
                    )
                    .overlay(alignment: .bottom) {
                        Capsule()
                            .fill(AppTheme.wordmarkBlue.opacity(0.08))
                            .frame(height: 2)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 2)
                    }
            }
        )
        .animation(.interactiveSpring(response: 0.28, dampingFraction: 0.86, blendDuration: 0.08), value: selectedMode)
        .frame(maxWidth: fillWidth ? .infinity : nil)
    }

    private func modernSwitchLabel(for mode: DictionaryMode) -> String {
        switch mode {
        case .encn: return "CN"
        case .enen: return "EN"
        }
    }

    private var legacyBody: some View {
        HStack(spacing: compact ? 2 : 4) {
            ForEach(DictionaryMode.allCases) { mode in
                Button {
                    action(mode)
                } label: {
                    HStack(spacing: compact ? 4 : 6) {
                        Circle()
                            .fill(mode == .encn ? AppTheme.wordmarkPink : AppTheme.wordmarkBlue)
                            .frame(width: compact ? 5 : 6, height: compact ? 5 : 6)

                        Text(mode.title)
                            .font(AppFont.sfMono(compact ? 10 : 12, weight: .black))
                            .foregroundColor(foregroundColor(for: mode))
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, verticalPadding)
                    .frame(maxWidth: fillWidth ? .infinity : nil)
                    .background(
                        Capsule()
                            .fill(selectedFill(for: mode))
                            .overlay(
                                Capsule()
                                    .stroke(selectedStroke(for: mode), lineWidth: AppTheme.selectedEdition == .comic ? 1.5 : 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(compact ? 4 : 5)
        .utilityPill(accent: AppTheme.selectedEdition == .comic ? AppTheme.warningYellow : nil)
        .frame(maxWidth: fillWidth ? .infinity : nil)
    }

    private func foregroundColor(for mode: DictionaryMode) -> Color {
        guard mode == selectedMode else { return AppTheme.mutedInk }
        if AppTheme.selectedEdition == .comic {
            return AppTheme.surfaceElevated
        }
        return mode == .encn ? AppTheme.wordmarkPink : AppTheme.wordmarkBlue
    }

    private func modernSelectionTint(for mode: DictionaryMode) -> Color {
        mode == .encn ? AppTheme.wordmarkPink : AppTheme.wordmarkBlue
    }

    private func selectedFill(for mode: DictionaryMode) -> Color {
        guard mode == selectedMode else { return .clear }
        if AppTheme.selectedEdition == .comic {
            return mode == .encn ? AppTheme.wordmarkPink : AppTheme.wordmarkBlue
        }
        return mode == .encn ? AppTheme.wordmarkPink.opacity(0.12) : AppTheme.wordmarkBlue.opacity(0.12)
    }

    private func selectedStroke(for mode: DictionaryMode) -> Color {
        guard mode == selectedMode else { return .clear }
        if AppTheme.selectedEdition == .comic {
            return AppTheme.outline
        }
        return mode == .encn ? AppTheme.wordmarkPink.opacity(0.22) : AppTheme.wordmarkBlue.opacity(0.22)
    }
}

struct DictionaryLoadingView: View {
    let selectedMode: DictionaryMode

    var body: some View {
        VStack(spacing: 12) {
            if AppTheme.selectedEdition == .comic {
                Text("WHOOSH")
                    .font(AppFont.wordmark(26))
                    .foregroundColor(AppTheme.comicRed)
                    .shadow(color: AppTheme.warningYellow, radius: 0, x: 3, y: 3)

                ProgressView(value: 0.72)
                    .tint(AppTheme.heroBlue)
                    .frame(maxWidth: 220)
                    .comicCapsule(fill: AppTheme.surfaceElevated, shadow: AppTheme.warningYellow, lineWidth: 2)
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
            }
            Text(selectedMode == .encn ? "正在载入学习卡片..." : "Loading word card...")
                .font(AppFont.editorial(18, weight: .bold))
                .foregroundColor(AppTheme.ink)
            Text(selectedMode == .encn ? "EN-CN Study" : selectedMode.title)
                .font(AppFont.sfMono(11, weight: .black))
                .foregroundColor(AppTheme.wordmarkBlue)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 18)
        .background {
            if AppTheme.selectedEdition == .comic {
                Color.clear
                    .comicPanel(fill: AppTheme.surfaceElevated, shadow: AppTheme.heroBlue, cornerRadius: 12)
            } else {
                Color.clear
                    .utilityPanel(cornerRadius: AppTheme.radiusL, accent: AppTheme.wordmarkBlue)
            }
        }
    }
}

struct DictionaryLookupUnavailableView: View {
    let message: String
    let selectedMode: DictionaryMode
    let switchBack: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppTheme.wordmarkBlue.opacity(0.7))
            Text(message)
                .font(AppFont.editorial(18, weight: .bold))
                .foregroundColor(AppTheme.ink)
                .multilineTextAlignment(.center)
            if selectedMode == .enen {
                Button("BACK TO EN-CN") {
                    switchBack()
                }
                .font(AppFont.sfMono(11, weight: .black))
                .foregroundColor(AppTheme.wordmarkBlue)
                .padding(.horizontal, AppTheme.selectedEdition == .comic ? 12 : 0)
                .padding(.vertical, AppTheme.selectedEdition == .comic ? 8 : 0)
                .background {
                    if AppTheme.selectedEdition == .comic {
                        Color.clear
                            .comicCapsule(fill: AppTheme.surfaceElevated, shadow: AppTheme.warningYellow, lineWidth: 2)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 18)
        .background {
            if AppTheme.selectedEdition == .comic {
                Color.clear
                    .comicPanel(fill: AppTheme.surfaceElevated, shadow: AppTheme.comicRed, cornerRadius: 12)
            } else {
                Color.clear
                    .utilityPanel(cornerRadius: AppTheme.radiusL, accent: AppTheme.wordmarkPink)
            }
        }
    }
}

struct ContentCard<Content: View>: View {
    let title: String
    let color: Color
    var titleUsesYaHei: Bool = false
    var titleUsesWordmark: Bool = false
    let content: Content

    init(
        title: String,
        color: Color,
        titleUsesYaHei: Bool = false,
        titleUsesWordmark: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.color = color
        self.titleUsesYaHei = titleUsesYaHei
        self.titleUsesWordmark = titleUsesWordmark
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if AppTheme.selectedEdition == .comic {
                Text(title.uppercased())
                    .font(titleFont)
                    .kerning(1)
                    .foregroundColor(AppTheme.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        ZStack {
                            Capsule()
                                .fill(color)
                                .offset(x: 3, y: 3)
                            Capsule()
                                .fill(AppTheme.warningYellow)
                                .overlay(
                                    Capsule()
                                        .stroke(AppTheme.outline, lineWidth: 2)
                                )
                        }
                    )
                    .padding(.horizontal, 4)
            } else {
                Text(title.uppercased())
                    .font(titleFont)
                    .kerning(1)
                    .foregroundColor(color)
                    .padding(.horizontal, 4)
            }

            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 15)
                .padding(.vertical, 14)
                .textSelection(.enabled)
                .utilityPanel(cornerRadius: AppTheme.radiusM, accent: color)
        }
    }

    private var titleFont: Font {
        if titleUsesWordmark {
            return AppFont.wordmark(13)
        }
        return titleUsesYaHei ? AppFont.yahei(11, weight: .bold) : AppFont.sfMono(10, weight: .black)
    }
}

struct SuggestionRow: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .foregroundColor(AppTheme.ink)
                    .font(AppFont.ui(18, weight: .semibold))
                Spacer()
                if AppTheme.selectedEdition == .comic {
                    Text("↗")
                        .font(AppFont.sfMono(14, weight: .medium))
                        .foregroundColor(AppTheme.mutedInk.opacity(0.45))
                } else {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.mutedInk.opacity(0.68))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background {
                if AppTheme.selectedEdition == .comic {
                    Color.clear
                        .comicPanel(fill: AppTheme.surfaceElevated, shadow: AppTheme.warningYellow, cornerRadius: 9, lineWidth: 3)
                } else {
                    Color.clear
                        .utilityPanel(cornerRadius: AppTheme.radiusM)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct PronunciationChip: View {
    let label: String
    let ipa: String
    let isUS: Bool
    let word: String
    private var accent: Color {
        isUS ? AppTheme.wordmarkBlue : AppTheme.wordmarkPink
    }

    var body: some View {
        Button {
            SpeechManager.shared.speak(text: word, isUS: isUS)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 11, weight: .bold))

                Text(label)
                    .font(AppFont.ipa(15))
                    .lineLimit(1)

                Text("/\(ipa)/")
                    .font(AppFont.ipa(15))
                    .lineLimit(1)
            }
            .foregroundColor(AppTheme.ink.opacity(0.78))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(accent.opacity(0.18))
                    .overlay(
                        Capsule()
                            .stroke(accent.opacity(0.26), lineWidth: 1)
                    )
            )
            .fixedSize(horizontal: true, vertical: false)
        }
        .buttonStyle(.plain)
    }
}

private struct PronunciationLine: View {
    let pronUk: String?
    let pronUs: String?
    let word: String

    private var uk: String? {
        pronUk?.cleanedDisplayText.nonEmptyValue
    }

    private var us: String? {
        pronUs?.cleanedDisplayText.nonEmptyValue
    }

    var body: some View {
        if let uk, let us {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    ukChip(uk)
                    usChip(us)
                }

                VStack(alignment: .leading, spacing: 6) {
                    ukChip(uk)
                    usChip(us)
                }
            }
        } else if let uk {
            ukChip(uk)
        } else if let us {
            usChip(us)
        }
    }

    private func ukChip(_ ipa: String) -> some View {
        PronunciationChip(label: "UK", ipa: ipa, isUS: false, word: word)
    }

    private func usChip(_ ipa: String) -> some View {
        PronunciationChip(label: "US", ipa: ipa, isUS: true, word: word)
    }
}

final class EnglishDisplayTextFormatter {
    static let shared = EnglishDisplayTextFormatter()
    private var cache: [String: String] = [:]

    func capitalizingLeadingLetter(in text: String) -> String {
        if let cached = cache[text] { return cached }
        var characters = Array(text)
        if let index = characters.firstIndex(where: { $0.isLetter }) {
            characters[index] = Character(String(characters[index]).uppercased())
        }
        let result = String(characters)
        cache[text] = result
        return result
    }
}

final class ExampleSentenceHighlighter {
    static let shared = ExampleSentenceHighlighter()

    private let tokenRegex = try? NSRegularExpression(pattern: "[A-Za-z']+")
    private var cache: [String: AttributedString] = [:]

    func highlightedText(sentence: String, targetWord: String, highlightColor: Color) -> Text {
        let key = "\(sentence)|\(targetWord)|\(highlightColor.description)"
        if let cached = cache[key] {
            return Text(cached)
        }

        let nsSentence = sentence as NSString
        var attributed = AttributedString(sentence)

        tokenRegex?.enumerateMatches(in: sentence, range: NSRange(location: 0, length: nsSentence.length)) { match, _, _ in
            guard let match else { return }
            let token = nsSentence.substring(with: match.range)
            guard Self.matchesInflectedForm(token: token, target: targetWord) else { return }
            if let range = Range(match.range, in: attributed) {
                attributed[range].foregroundColor = UIColor(highlightColor)
            }
        }

        cache[key] = attributed
        return Text(attributed)
    }

    private static func matchesInflectedForm(token: String, target: String) -> Bool {
        let normalizedToken = token.lowercased()
        let normalizedTarget = target.lowercased()

        if normalizedToken == normalizedTarget { return true }

        let candidates = candidateLemmas(for: normalizedToken)
        return candidates.contains(normalizedTarget)
    }

    private static func candidateLemmas(for word: String) -> Set<String> {
        var results: Set<String> = [word]

        if word.hasSuffix("ied"), word.count > 4 {
            results.insert(String(word.dropLast(3)) + "y")
        }

        if word.hasSuffix("ed"), word.count > 3 {
            let base = String(word.dropLast(2))
            results.insert(base)
            results.insert(String(word.dropLast(1)))
            if isDoubleConsonant(base) {
                results.insert(String(base.dropLast(1)))
            }
        }

        if word.hasSuffix("ing"), word.count > 4 {
            let base = String(word.dropLast(3))
            results.insert(base)
            results.insert(base + "e")
            if isDoubleConsonant(base) {
                results.insert(String(base.dropLast(1)))
            }
        }

        if word.hasSuffix("ies"), word.count > 4 {
            results.insert(String(word.dropLast(3)) + "y")
        }

        if word.hasSuffix("es"), word.count > 3 {
            results.insert(String(word.dropLast(2)))
        }

        if word.hasSuffix("s"), !word.hasSuffix("ss"), word.count > 2 {
            results.insert(String(word.dropLast(1)))
        }

        return results
    }

    private static func isDoubleConsonant(_ str: String) -> Bool {
        guard str.count >= 2 else { return false }
        let chars = Array(str)
        let last = chars[chars.count - 1]
        let secondLast = chars[chars.count - 2]
        let vowels: Set<Character> = ["a", "e", "i", "o", "u"]
        return last == secondLast && !vowels.contains(last)
    }
}

struct AppFont {
    static func wordmark(_ size: CGFloat) -> Font {
        switch UIEditionManager.shared.selectedEdition {
        case .modernArchivist:
            return .system(size: size, weight: .black, design: .rounded)
        case .comic:
            return .custom("MarkerFelt-Wide", size: size)
        default:
            return .custom("Microsoft YaHei Bold", size: size)
        }
    }

    static func yahei(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold, .semibold, .black, .heavy:
            return .custom("Microsoft YaHei Bold", size: size)
        default:
            return .custom("Microsoft YaHei", size: size)
        }
    }

    static func editorial(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if UIEditionManager.shared.selectedEdition == .modernArchivist {
            switch weight {
            case .bold, .semibold, .black, .heavy:
                return .system(size: size, weight: .semibold, design: .serif)
            case .medium:
                return .system(size: size, weight: .medium, design: .serif)
            default:
                return .system(size: size, weight: .regular, design: .serif)
            }
        } else if UIEditionManager.shared.selectedEdition == .comic {
            switch weight {
            case .bold, .semibold, .black, .heavy:
                return .custom("MarkerFelt-Wide", size: size)
            default:
                return .custom("ChalkboardSE-Regular", size: size)
            }
        } else {
            switch weight {
            case .bold, .semibold, .black, .heavy:
                return .custom("AvenirNext-DemiBold", size: size)
            default:
                return .custom("AvenirNext-Regular", size: size)
            }
        }
    }

    static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold, .semibold:
            return .custom("AvenirNext-DemiBold", size: size)
        case .medium:
            return .custom("AvenirNext-Medium", size: size)
        case .black, .heavy:
            return .custom("AvenirNext-Bold", size: size)
        default:
            return .custom("AvenirNext-Regular", size: size)
        }
    }

    static func sfMono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .black, .bold, .heavy, .semibold:
            return .custom("SFMono-Bold", size: size)
        case .medium:
            return .custom("SFMono-Medium", size: size)
        default:
            return .custom("SFMono-Regular", size: size)
        }
    }

    static func ipa(_ size: CGFloat) -> Font {
        .custom("Times New Roman", size: size)
    }

    static func songti(_ size: CGFloat = 16) -> Font {
        .custom("Songti SC", size: size)
    }

    static let titleLarge = editorial(30, weight: .bold)
    static let titleWord = yahei(46, weight: .bold)
    static let titlePage = editorial(38, weight: .bold)
    static let titleHero = editorial(72, weight: .bold)
    static let valueCard = editorial(24, weight: .bold)

    static let section = sfMono(11, weight: .black)
    static let body = ui(17)
    static let bodySmall = ui(15)
    static let bodyMono = sfMono(15, weight: .medium)
    static let secondary = ui(13, weight: .medium)
    static let secondarySmall = ui(12, weight: .medium)
    static let label = sfMono(10, weight: .black)
}

enum UIEdition: String, CaseIterable, Identifiable {
    case modernArchivist
    case dopamine
    case comic
    case foil
    case kawaiiMinimal
    case utilitySystem

    var id: String { rawValue }

    var title: String {
        switch self {
        case .modernArchivist: return "Warm Study Cards"
        case .dopamine: return "Dopamine Soft"
        case .comic: return "Comic Panel"
        case .foil: return "Foil Collectible"
        case .kawaiiMinimal: return "Kawaii Minimal"
        case .utilitySystem: return "Utility System"
        }
    }

    var subtitle: String {
        switch self {
        case .modernArchivist: return "Soft learning cards with quiet structure"
        case .dopamine: return "Bright, comfortable and expressive"
        case .comic: return "High contrast panels and action accents"
        case .foil: return "Dark premium card with metallic cues"
        case .kawaiiMinimal: return "Soft stationery colors, tidy layout"
        case .utilitySystem: return "Neutral tokens, grids and fine borders"
        }
    }

    var icon: String {
        switch self {
        case .modernArchivist: return "rectangle.stack.fill"
        case .dopamine: return "sparkles"
        case .comic: return "bolt.fill"
        case .foil: return "seal.fill"
        case .kawaiiMinimal: return "heart.circle.fill"
        case .utilitySystem: return "square.grid.3x3.fill"
        }
    }

    var swatches: [Color] {
        [palette.wordmarkPink, palette.wordmarkBlue, palette.surfaceElevated]
    }

    var accentColor: Color {
        palette.wordmarkBlue
    }

    fileprivate var palette: UIEditionPalette {
        switch self {
        case .modernArchivist:
            return UIEditionPalette(
                background: Color(red: 0.984, green: 0.976, blue: 0.957),
                surface: Color(red: 0.941, green: 0.933, blue: 0.914),
                surfaceElevated: Color(red: 1.0, green: 1.0, blue: 1.0),
                ink: Color(red: 0.106, green: 0.110, blue: 0.098),
                mutedInk: Color(red: 0.302, green: 0.259, blue: 0.294),
                divider: Color(red: 0.840, green: 0.730, blue: 0.790),
                border: Color(red: 0.565, green: 0.445, blue: 0.535),
                primary: Color(red: 0.090, green: 0.650, blue: 1.000),
                accent: Color(red: 0.900, green: 0.095, blue: 0.480),
                primarySoft: Color(red: 0.850, green: 0.945, blue: 1.000),
                accentSoft: Color(red: 0.980, green: 0.835, blue: 0.915),
                jewelPurple: Color(red: 0.760, green: 0.105, blue: 0.445),
                jewelCyan: Color(red: 0.130, green: 0.660, blue: 0.900),
                jewelYellow: Color(red: 0.900, green: 0.690, blue: 0.190),
                radiusS: 4,
                radiusM: 10,
                radiusL: 14
            )
        case .dopamine:
            return UIEditionPalette(
                background: Color(red: 0.969, green: 0.957, blue: 0.937),
                surface: Color(red: 0.985, green: 0.978, blue: 0.963),
                surfaceElevated: Color(red: 0.993, green: 0.989, blue: 0.981),
                ink: Color(red: 0.20, green: 0.19, blue: 0.17),
                mutedInk: Color(red: 0.45, green: 0.42, blue: 0.39),
                divider: Color(red: 0.82, green: 0.78, blue: 0.73),
                border: Color.black.opacity(0.07),
                primary: Color(red: 93.0 / 255.0, green: 165.0 / 255.0, blue: 218.0 / 255.0),
                accent: Color(red: 0.98, green: 0.16, blue: 0.63),
                primarySoft: Color(red: 0.90, green: 0.96, blue: 0.99),
                accentSoft: Color(red: 1.0, green: 0.90, blue: 0.95),
                jewelPurple: Color(red: 0.63, green: 0.34, blue: 0.96),
                jewelCyan: Color(red: 0.09, green: 0.77, blue: 0.96),
                jewelYellow: Color(red: 0.96, green: 0.74, blue: 0.15),
                radiusS: 10,
                radiusM: 18,
                radiusL: 24
            )
        case .comic:
            return UIEditionPalette(
                background: Color(red: 1.0, green: 0.996, blue: 0.941),
                surface: Color(red: 1.0, green: 0.985, blue: 0.890),
                surfaceElevated: Color(red: 1.0, green: 0.995, blue: 0.955),
                ink: Color(red: 0.08, green: 0.08, blue: 0.08),
                mutedInk: Color(red: 0.30, green: 0.30, blue: 0.30),
                divider: Color.black.opacity(0.22),
                border: Color.black.opacity(0.92),
                primary: Color(red: 0.12, green: 0.56, blue: 1.0),
                accent: Color(red: 0.886, green: 0.212, blue: 0.212),
                primarySoft: Color(red: 0.88, green: 0.94, blue: 1.0),
                accentSoft: Color(red: 1.0, green: 0.91, blue: 0.56),
                jewelPurple: Color(red: 0.12, green: 0.56, blue: 1.0),
                jewelCyan: Color(red: 0.04, green: 0.56, blue: 0.38),
                jewelYellow: Color(red: 1.0, green: 0.84, blue: 0.0),
                radiusS: 4,
                radiusM: 6,
                radiusL: 8
            )
        case .foil:
            return UIEditionPalette(
                background: Color(red: 0.035, green: 0.039, blue: 0.055),
                surface: Color(red: 0.070, green: 0.078, blue: 0.102),
                surfaceElevated: Color(red: 0.105, green: 0.112, blue: 0.145),
                ink: Color(red: 0.925, green: 0.910, blue: 0.862),
                mutedInk: Color(red: 0.650, green: 0.680, blue: 0.735),
                divider: Color(red: 0.260, green: 0.280, blue: 0.340),
                border: Color(red: 0.820, green: 0.720, blue: 0.450).opacity(0.72),
                primary: Color(red: 0.38, green: 0.80, blue: 0.95),
                accent: Color(red: 0.95, green: 0.74, blue: 0.36),
                primarySoft: Color(red: 0.115, green: 0.200, blue: 0.260),
                accentSoft: Color(red: 0.230, green: 0.185, blue: 0.105),
                jewelPurple: Color(red: 0.70, green: 0.54, blue: 0.95),
                jewelCyan: Color(red: 0.38, green: 0.80, blue: 0.95),
                jewelYellow: Color(red: 0.95, green: 0.74, blue: 0.36),
                radiusS: 8,
                radiusM: 14,
                radiusL: 20
            )
        case .kawaiiMinimal:
            return UIEditionPalette(
                background: Color(red: 0.998, green: 0.972, blue: 0.925),
                surface: Color(red: 1.0, green: 0.988, blue: 0.956),
                surfaceElevated: Color(red: 1.0, green: 0.996, blue: 0.982),
                ink: Color(red: 0.235, green: 0.197, blue: 0.215),
                mutedInk: Color(red: 0.52, green: 0.46, blue: 0.48),
                divider: Color(red: 0.91, green: 0.84, blue: 0.82),
                border: Color(red: 0.93, green: 0.82, blue: 0.86),
                primary: Color(red: 0.43, green: 0.68, blue: 0.96),
                accent: Color(red: 1.0, green: 0.39, blue: 0.62),
                primarySoft: Color(red: 0.88, green: 0.94, blue: 1.0),
                accentSoft: Color(red: 1.0, green: 0.83, blue: 0.88),
                jewelPurple: Color(red: 0.70, green: 0.60, blue: 0.98),
                jewelCyan: Color(red: 0.37, green: 0.78, blue: 0.70),
                jewelYellow: Color(red: 1.0, green: 0.78, blue: 0.32),
                radiusS: 12,
                radiusM: 22,
                radiusL: 28
            )
        case .utilitySystem:
            return UIEditionPalette(
                background: Color(red: 0.965, green: 0.973, blue: 0.984),
                surface: Color(red: 0.982, green: 0.986, blue: 0.992),
                surfaceElevated: Color(red: 0.999, green: 1.0, blue: 0.998),
                ink: Color(red: 0.105, green: 0.133, blue: 0.165),
                mutedInk: Color(red: 0.395, green: 0.447, blue: 0.520),
                divider: Color(red: 0.842, green: 0.870, blue: 0.902),
                border: Color(red: 0.812, green: 0.842, blue: 0.880),
                primary: Color(red: 0.145, green: 0.318, blue: 0.690),
                accent: Color(red: 0.690, green: 0.363, blue: 0.078),
                primarySoft: Color(red: 0.890, green: 0.925, blue: 0.992),
                accentSoft: Color(red: 0.988, green: 0.945, blue: 0.862),
                jewelPurple: Color(red: 0.145, green: 0.318, blue: 0.690),
                jewelCyan: Color(red: 0.145, green: 0.318, blue: 0.690),
                jewelYellow: Color(red: 0.690, green: 0.363, blue: 0.078),
                radiusS: 8,
                radiusM: 12,
                radiusL: 16
            )
        }
    }
}

private struct UIEditionPalette {
    let background: Color
    let surface: Color
    let surfaceElevated: Color
    let ink: Color
    let mutedInk: Color
    let divider: Color
    let border: Color
    let primary: Color
    let accent: Color
    let primarySoft: Color
    let accentSoft: Color
    let jewelPurple: Color
    let jewelCyan: Color
    let jewelYellow: Color
    let radiusS: CGFloat
    let radiusM: CGFloat
    let radiusL: CGFloat

    var jewelPink: Color { accent }
    var jewelOrange: Color { accent }
    var logoRed: Color { accent }
    var logoBlue: Color { primary }
    var wordmarkPink: Color { accent }
    var wordmarkBlue: Color { primary }
}

final class UIEditionManager: ObservableObject {
    static let shared = UIEditionManager()

    @Published var selectedEdition: UIEdition {
        didSet {
            UserDefaults.standard.set(selectedEdition.rawValue, forKey: Self.storageKey)
        }
    }

    private static let storageKey = "wordety.selectedUIEdition"

    private init() {
        selectedEdition = .modernArchivist
        UserDefaults.standard.set(UIEdition.modernArchivist.rawValue, forKey: Self.storageKey)
    }
}

final class DetailTextSizeManager: ObservableObject {
    static let shared = DetailTextSizeManager()

    static let minimumOffset: Double = -2
    static let maximumOffset: Double = 4
    static let step: Double = 0.5

    @Published var offset: Double {
        didSet {
            let clamped = Self.clamped(offset)
            if clamped != offset {
                offset = clamped
                return
            }
            UserDefaults.standard.set(offset, forKey: Self.storageKey)
        }
    }

    var displayLabel: String {
        if abs(offset) < 0.001 {
            return "Default"
        }
        return "\(offset > 0 ? "+" : "")\(Self.formatted(offset)) pt"
    }

    private static let storageKey = "wordety.detailTextSizeOffset"

    private init() {
        let saved = UserDefaults.standard.object(forKey: Self.storageKey) as? Double ?? 0
        offset = Self.clamped(saved)
    }

    func adjusted(_ base: CGFloat) -> CGFloat {
        max(11, base + CGFloat(offset))
    }

    func reset() {
        offset = 0
    }

    private static func clamped(_ value: Double) -> Double {
        min(max(value, minimumOffset), maximumOffset)
    }

    private static func formatted(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if rounded.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(rounded))"
        }
        return String(format: "%.1f", rounded)
    }
}

struct AppTheme {
    private static var palette: UIEditionPalette { UIEditionManager.shared.selectedEdition.palette }
    static var selectedEdition: UIEdition { UIEditionManager.shared.selectedEdition }

    static var background: Color { palette.background }
    static var surface: Color { palette.surface }
    static var surfaceElevated: Color { palette.surfaceElevated }
    static var ink: Color { palette.ink }
    static var mutedInk: Color { palette.mutedInk }
    static var divider: Color { palette.divider }
    static var border: Color { palette.border }
    static var primary: Color { palette.primary }
    static var accent: Color { palette.accent }
    static var primarySoft: Color { palette.primarySoft }
    static var accentSoft: Color { palette.accentSoft }
    static var wordmarkPink: Color { palette.wordmarkPink }
    static var wordmarkBlue: Color { palette.wordmarkBlue }
    static var logoRed: Color { palette.logoRed }
    static var logoBlue: Color { palette.logoBlue }
    static var jewelPurple: Color { palette.jewelPurple }
    static var jewelCyan: Color { palette.jewelCyan }
    static var jewelPink: Color { palette.jewelPink }
    static var jewelYellow: Color { palette.jewelYellow }
    static var jewelOrange: Color { palette.jewelOrange }
    static var radiusS: CGFloat { palette.radiusS }
    static var radiusM: CGFloat { palette.radiusM }
    static var radiusL: CGFloat { palette.radiusL }
    static var outline: Color { selectedEdition == .comic ? Color.black : palette.border }
    static var comicRed: Color { selectedEdition == .comic ? palette.accent : palette.accent }
    static var heroBlue: Color { palette.primary }
    static var warningYellow: Color { selectedEdition == .comic ? palette.jewelYellow : palette.jewelYellow }
    static var comicGreen: Color { selectedEdition == .comic ? palette.jewelCyan : palette.jewelCyan }
    static var comicPurple: Color { selectedEdition == .comic ? palette.jewelPurple : palette.jewelPurple }
    static var darkPanel: Color { selectedEdition == .comic ? Color(red: 0.173, green: 0.173, blue: 0.173) : palette.ink.opacity(0.9) }
}

struct ComicBookBackground: View {
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            ComicHalftoneDots(color: AppTheme.heroBlue.opacity(0.10), spacing: 15, dotSize: 3.2)
                .ignoresSafeArea()
            ComicHalftoneDots(color: AppTheme.comicRed.opacity(0.055), spacing: 22, dotSize: 4.5)
                .rotationEffect(.degrees(-10))
                .ignoresSafeArea()
        }
    }
}

struct ComicHalftoneDots: View {
    let color: Color
    var spacing: CGFloat = 14
    var dotSize: CGFloat = 3

    var body: some View {
        Canvas { context, size in
            var x: CGFloat = 0
            while x < size.width + spacing {
                var y: CGFloat = 0
                while y < size.height + spacing {
                    let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                    context.fill(Path(ellipseIn: rect), with: .color(color))
                    y += spacing
                }
                x += spacing
            }
        }
        .allowsHitTesting(false)
    }
}

struct ComicSpeedLines: View {
    var color: Color = AppTheme.outline.opacity(0.12)
    var lineCount: Int = 22

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width * 0.72, y: size.height * 0.18)
            let radius = hypot(size.width, size.height)

            for index in 0..<lineCount {
                let angle = Double(index) / Double(max(lineCount, 1)) * .pi * 2
                let inner = CGPoint(
                    x: center.x + cos(angle) * radius * 0.16,
                    y: center.y + sin(angle) * radius * 0.16
                )
                let outer = CGPoint(
                    x: center.x + cos(angle) * radius,
                    y: center.y + sin(angle) * radius
                )

                var path = Path()
                path.move(to: inner)
                path.addLine(to: outer)
                context.stroke(path, with: .color(color), lineWidth: index.isMultiple(of: 3) ? 3 : 1.5)
            }
        }
        .allowsHitTesting(false)
    }
}

struct ComicBurst: Shape {
    var points: Int = 18
    var innerRatio: CGFloat = 0.72

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * innerRatio

        var path = Path()
        for index in 0..<(points * 2) {
            let radius = index.isMultiple(of: 2) ? outer : inner
            let angle = CGFloat(index) / CGFloat(points * 2) * .pi * 2 - .pi / 2
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            index == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

private struct ComicPanelModifier: ViewModifier {
    var fill: Color = AppTheme.surfaceElevated
    var shadow: Color = AppTheme.warningYellow
    var cornerRadius: CGFloat = 10
    var lineWidth: CGFloat = 3
    var offset: CGSize = CGSize(width: 5, height: 5)

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(shadow)
                        .offset(offset)

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(fill)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .stroke(AppTheme.outline, lineWidth: lineWidth)
                        )
                }
            )
    }
}

private struct ComicCapsuleModifier: ViewModifier {
    var fill: Color = AppTheme.surfaceElevated
    var shadow: Color = AppTheme.warningYellow
    var lineWidth: CGFloat = 2

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    Capsule()
                        .fill(shadow)
                        .offset(x: 4, y: 4)

                    Capsule()
                        .fill(fill)
                        .overlay(
                            Capsule()
                                .stroke(AppTheme.outline, lineWidth: lineWidth)
                        )
                }
            )
    }
}

struct UtilityBackdrop: View {
    var body: some View {
        switch UIEditionManager.shared.selectedEdition {
        case .modernArchivist:
            ZStack {
                AppTheme.background
                LinearGradient(
                    colors: [
                        AppTheme.surfaceElevated.opacity(0.86),
                        AppTheme.background,
                        AppTheme.primarySoft.opacity(0.12)
                    ],
                    startPoint: .top,
                    endPoint: .bottomTrailing
                )
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(AppTheme.background.opacity(0.82))
                        .frame(height: 88)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(AppTheme.border.opacity(0.08))
                                .frame(height: 1)
                        }
                    Spacer()
                }
            }
        case .dopamine:
            ZStack {
                AppTheme.background
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(AppTheme.primarySoft.opacity(0.72))
                        .frame(height: 118)
                    Spacer()
                    Rectangle()
                        .fill(AppTheme.accentSoft.opacity(0.52))
                        .frame(height: 58)
                }
            }
        case .comic:
            ZStack {
                ComicBookBackground()
                ComicSpeedLines(color: AppTheme.outline.opacity(0.055), lineCount: 24)
                    .ignoresSafeArea()
            }
        case .foil:
            ZStack {
                AppTheme.background
                LinearGradient(
                    colors: [
                        AppTheme.primarySoft.opacity(0.58),
                        AppTheme.accentSoft.opacity(0.32),
                        AppTheme.background
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(AppTheme.surface.opacity(0.62))
                        .frame(height: 110)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(AppTheme.border.opacity(0.62))
                                .frame(height: 1)
                        }
                    Spacer()
                }
            }
        case .kawaiiMinimal:
            ZStack {
                AppTheme.background
                UtilityGrid()
                    .stroke(AppTheme.divider.opacity(0.14), lineWidth: 0.7)
                    .padding(.top, 112)
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(AppTheme.accentSoft.opacity(0.58))
                        .frame(height: 124)
                    Spacer()
                    Rectangle()
                        .fill(AppTheme.primarySoft.opacity(0.42))
                        .frame(height: 70)
                }
            }
        case .utilitySystem:
            ZStack {
                AppTheme.background

                UtilityGrid()
                    .stroke(AppTheme.divider.opacity(0.38), lineWidth: 0.6)
                    .padding(.top, 88)

                VStack(spacing: 0) {
                    Rectangle()
                        .fill(AppTheme.primarySoft.opacity(0.68))
                        .frame(height: 96)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(AppTheme.border.opacity(0.72))
                                .frame(height: 1)
                        }
                    Spacer()
                }
            }
        }
    }

}

private struct UtilityGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step: CGFloat = 32

        var x = rect.minX
        while x <= rect.maxX {
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
            x += step
        }

        var y = rect.minY
        while y <= rect.maxY {
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
            y += step
        }

        return path
    }
}

private struct UtilityPanelModifier: ViewModifier {
    let cornerRadius: CGFloat
    let accent: Color?

    @ViewBuilder
    func body(content: Content) -> some View {
        switch UIEditionManager.shared.selectedEdition {
        case .modernArchivist:
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(AppTheme.surfaceElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .stroke((accent ?? AppTheme.border).opacity(accent == nil ? 0.12 : 0.20), lineWidth: 1)
                        )
                )
                .overlay(alignment: .top) {
                    if let accent {
                        Rectangle()
                            .fill(accent.opacity(0.22))
                            .frame(height: 1)
                            .padding(.horizontal, 14)
                    }
                }
                .shadow(color: AppTheme.outline.opacity(0.045), radius: 12, x: 0, y: 4)
        case .dopamine:
            content
                .background(
                    RoundedRectangle(cornerRadius: max(cornerRadius, AppTheme.radiusM), style: .continuous)
                        .fill(AppTheme.surfaceElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: max(cornerRadius, AppTheme.radiusM), style: .continuous)
                                .stroke((accent ?? AppTheme.border).opacity(0.16), lineWidth: 1)
                        )
                )
                .overlay(alignment: .leading) {
                    if let accent {
                        Rectangle()
                            .fill(accent.opacity(0.82))
                            .frame(width: 4)
                    }
                }
                .shadow(color: (accent ?? Color.black).opacity(0.10), radius: 14, x: 0, y: 7)
        case .comic:
            content
                .comicPanel(
                    fill: AppTheme.surfaceElevated,
                    shadow: accent ?? AppTheme.warningYellow,
                    cornerRadius: max(cornerRadius, 9),
                    lineWidth: 3,
                    offset: CGSize(width: 4, height: 4)
                )
        case .foil:
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppTheme.surfaceElevated,
                                    (accent ?? AppTheme.primary).opacity(0.18),
                                    AppTheme.surface
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            AppTheme.accent.opacity(0.78),
                                            AppTheme.primary.opacity(0.58),
                                            AppTheme.border.opacity(0.72)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .overlay(alignment: .leading) {
                    if let accent {
                        Rectangle()
                            .fill(accent.opacity(0.88))
                            .frame(width: 3)
                    }
                }
                .shadow(color: (accent ?? AppTheme.accent).opacity(0.20), radius: 12, x: 0, y: 4)
        case .kawaiiMinimal:
            content
                .background(
                    RoundedRectangle(cornerRadius: max(cornerRadius, AppTheme.radiusM), style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.surfaceElevated, (accent ?? AppTheme.primary).opacity(0.07)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: max(cornerRadius, AppTheme.radiusM), style: .continuous)
                                .stroke((accent ?? AppTheme.border).opacity(0.20), lineWidth: 1)
                        )
                )
                .shadow(color: (accent ?? Color.black).opacity(0.11), radius: 12, x: 0, y: 5)
        case .utilitySystem:
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(AppTheme.surfaceElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .stroke(AppTheme.border.opacity(0.82), lineWidth: 1)
                        )
                )
                .overlay(alignment: .leading) {
                    if let accent {
                        Rectangle()
                            .fill(accent)
                            .frame(width: 3)
                    }
                }
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
    }
}

private struct UtilityPillModifier: ViewModifier {
    let accent: Color?

    @ViewBuilder
    func body(content: Content) -> some View {
        switch UIEditionManager.shared.selectedEdition {
        case .modernArchivist:
            content
                .background(
                    Capsule()
                        .fill(accent?.opacity(0.10) ?? AppTheme.surface)
                        .overlay(
                            Capsule()
                                .stroke((accent ?? AppTheme.border).opacity(0.16), lineWidth: 1)
                        )
                )
        case .comic:
            content
                .comicCapsule(fill: AppTheme.surfaceElevated, shadow: accent ?? AppTheme.warningYellow, lineWidth: 2)
        case .foil:
            content
                .background(
                    Capsule()
                        .fill(accent?.opacity(0.16) ?? AppTheme.surfaceElevated)
                        .overlay(
                            Capsule()
                                .stroke((accent ?? AppTheme.border).opacity(0.62), lineWidth: 1)
                        )
                )
        case .kawaiiMinimal:
            content
                .background(
                    Capsule()
                        .fill(accent?.opacity(0.12) ?? AppTheme.surfaceElevated)
                        .overlay(
                            Capsule()
                                .stroke((accent ?? AppTheme.border).opacity(0.24), lineWidth: 1)
                        )
                )
                .shadow(color: (accent ?? Color.black).opacity(0.08), radius: 7, x: 0, y: 3)
        case .dopamine:
            content
                .background(
                    Capsule()
                        .fill(accent?.opacity(0.10) ?? AppTheme.surfaceElevated)
                        .overlay(
                            Capsule()
                                .stroke((accent ?? AppTheme.border).opacity(0.18), lineWidth: 1)
                        )
                )
        case .utilitySystem:
            content
                .background(
                    Capsule()
                        .fill(accent?.opacity(0.08) ?? AppTheme.surfaceElevated)
                        .overlay(
                            Capsule()
                                .stroke((accent ?? AppTheme.border).opacity(accent == nil ? 0.9 : 0.24), lineWidth: 1)
                        )
                )
        }
    }
}

extension View {
    func comicPanel(
        fill: Color = AppTheme.surfaceElevated,
        shadow: Color = AppTheme.warningYellow,
        cornerRadius: CGFloat = 10,
        lineWidth: CGFloat = 3,
        offset: CGSize = CGSize(width: 5, height: 5)
    ) -> some View {
        modifier(
            ComicPanelModifier(
                fill: fill,
                shadow: shadow,
                cornerRadius: cornerRadius,
                lineWidth: lineWidth,
                offset: offset
            )
        )
    }

    func comicCapsule(
        fill: Color = AppTheme.surfaceElevated,
        shadow: Color = AppTheme.warningYellow,
        lineWidth: CGFloat = 2
    ) -> some View {
        modifier(ComicCapsuleModifier(fill: fill, shadow: shadow, lineWidth: lineWidth))
    }

    func utilityPanel(cornerRadius: CGFloat = AppTheme.radiusM, accent: Color? = nil) -> some View {
        modifier(UtilityPanelModifier(cornerRadius: cornerRadius, accent: accent))
    }

    func utilityPill(accent: Color? = nil) -> some View {
        modifier(UtilityPillModifier(accent: accent))
    }
}
