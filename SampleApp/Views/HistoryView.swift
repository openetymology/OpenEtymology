//
//  HistoryView.swift
//  wordety
//
//  Created by SkyRocket on 2025/12/25.
//

import SwiftUI
import UIKit

struct HistoryView: View {
    @EnvironmentObject var viewModel: SearchViewModel
    @ObservedObject private var dictionaryModeManager = DictionaryModeManager.shared
    @ObservedObject private var reviewStore = ReviewStore.shared
    @ObservedObject private var plusAccess = PlusAccessManager.shared
    @ObservedObject private var masteryStore = MasteryStore.shared
    @State private var exportedPDFItem: PDFExportItem?
    @State private var exportErrorMessage: String?
    @State private var isExporting = false
    @State private var showClearConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                UtilityBackdrop()
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 10) {
                    header

                    if viewModel.searchHistory.isEmpty {
                        emptyState
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 6) {
                                ForEach(Array(viewModel.searchHistory.enumerated()), id: \.element) { index, item in
                                    NavigationLink {
                                        HistoryWordDetailScreen(query: item, mode: dictionaryModeManager.selectedMode)
                                    } label: {
                                        HistoryRow(
                                            index: index + 1,
                                            word: item,
                                            status: reviewStore.status(for: item),
                                            masteryCount: plusAccess.canTrackMastery ? masteryStore.mastery(for: item) : nil,
                                            selectedMode: dictionaryModeManager.selectedMode
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(dictionaryModeManager.selectedMode.localized(chinese: "加入复习", english: "Add To Review")) {
                                            ReviewStore.shared.addWord(slug: item.lowercased(), word: item, source: .history)
                                        }
                                    }

                                    if index < viewModel.searchHistory.count - 1 {
                                        EmptyView()
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 28)
                        }
                    }
                }
                .padding(.top, 10)
            }
            .navigationBarHidden(true)
            .sheet(item: $exportedPDFItem) { item in
                ActivityView(activityItems: [item.url])
            }
            .alert(
                dictionaryModeManager.selectedMode.localized(chinese: "导出失败", english: "Export Failed"),
                isPresented: Binding(
                    get: { exportErrorMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            exportErrorMessage = nil
                        }
                    }
                )
            ) {
                Button(dictionaryModeManager.selectedMode.localized(chinese: "好", english: "OK"), role: .cancel) { }
            } message: {
                Text(exportErrorMessage ?? "")
            }
            .alert(dictionaryModeManager.selectedMode.localized(chinese: "清空历史记录？", english: "Clear History?"), isPresented: $showClearConfirmation) {
                Button(dictionaryModeManager.selectedMode.localized(chinese: "取消", english: "Cancel"), role: .cancel) { }
                Button(dictionaryModeManager.selectedMode.localized(chinese: "清空", english: "Clear"), role: .destructive) {
                    viewModel.clearHistory()
                }
            } message: {
                Text(dictionaryModeManager.selectedMode.localized(
                    chinese: "这会删除本机保存的全部搜索历史，操作后无法撤销。",
                    english: "This removes all search history stored on this device. This action cannot be undone."
                ))
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text(dictionaryModeManager.selectedMode.localized(chinese: "历史", english: "History"))
                .font(AppFont.editorial(30, weight: .bold))
                .foregroundColor(AppTheme.ink)

            Spacer()

            if !viewModel.searchHistory.isEmpty {
                HStack(spacing: 8) {
                    if plusAccess.canExportHistoryPDF {
                        HistoryHeaderButton(
                            title: isExporting
                            ? dictionaryModeManager.selectedMode.localized(chinese: "生成中", english: "Saving")
                            : dictionaryModeManager.selectedMode.localized(chinese: "笔记", english: "Notes"),
                            systemImage: isExporting ? "hourglass" : "doc.richtext",
                            tint: AppTheme.wordmarkBlue,
                            isDisabled: isExporting
                        ) {
                            exportHistoryPDF()
                        }
                    } else {
                        HistoryLimitBadge(selectedMode: dictionaryModeManager.selectedMode)
                    }

                    HistoryHeaderButton(
                        title: dictionaryModeManager.selectedMode.localized(chinese: "清空", english: "Clear"),
                        systemImage: "trash",
                        tint: AppTheme.wordmarkPink
                    ) {
                        showClearConfirmation = true
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func exportHistoryPDF() {
        guard !isExporting else { return }

        isExporting = true
        defer { isExporting = false }

        do {
            let url = try HistoryPDFExporter().exportHistory(
                slugs: viewModel.searchHistory,
                mode: dictionaryModeManager.selectedMode
            )
            exportedPDFItem = PDFExportItem(url: url)
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 42, weight: .light))
                .foregroundColor(AppTheme.wordmarkBlue.opacity(0.35))
            Text(dictionaryModeManager.selectedMode.localized(chinese: "还没有历史记录", english: "No history yet"))
                .font(AppFont.editorial(20, weight: .bold))
                .foregroundColor(AppTheme.ink.opacity(0.82))
            Text(dictionaryModeManager.selectedMode.localized(chinese: "你搜索过的单词会显示在这里。", english: "Words you search will appear here."))
                .font(AppFont.editorial(14))
                .foregroundColor(AppTheme.mutedInk)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 26)
        .utilityPanel(cornerRadius: AppTheme.radiusL)
        .padding(.horizontal, 20)
    }
}

private struct HistoryHeaderButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .bold))

                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundColor(isDisabled ? AppTheme.mutedInk.opacity(0.48) : tint)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(tint.opacity(isDisabled ? 0.05 : 0.11))
                    .overlay(
                        Capsule()
                            .stroke(tint.opacity(isDisabled ? 0.08 : 0.24), lineWidth: 1)
                    )
                    .shadow(color: tint.opacity(isDisabled ? 0 : 0.08), radius: 8, x: 0, y: 3)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

private struct HistoryLimitBadge: View {
    let selectedMode: DictionaryMode

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "lock.fill")
                .font(.system(size: 10, weight: .bold))

            Text(selectedMode.localized(
                chinese: "最近 \(PlusAccessManager.basicHistoryLimit) 条",
                english: "Latest \(PlusAccessManager.basicHistoryLimit)"
            ))
                .font(AppFont.sfMono(10, weight: .black))
                .lineLimit(1)
        }
        .foregroundColor(AppTheme.mutedInk.opacity(0.72))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(AppTheme.surfaceElevated.opacity(0.88))
                .overlay(
                    Capsule()
                        .stroke(AppTheme.border.opacity(0.14), lineWidth: 1)
                )
        )
    }
}

private struct HistoryRow: View {
    let index: Int
    let word: String
    let status: LearningStatus
    let masteryCount: Int?
    let selectedMode: DictionaryMode

    private var accent: Color {
        switch status {
        case .new: return AppTheme.wordmarkBlue
        case .reviewed: return AppTheme.jewelOrange
        case .mastered: return AppTheme.wordmarkPink
        }
    }

    private var indexAccent: Color {
        let palette: [Color] = [
            AppTheme.wordmarkBlue,
            AppTheme.wordmarkPink,
            AppTheme.jewelPurple,
            AppTheme.jewelCyan,
            AppTheme.jewelYellow
        ]
        return palette[(index - 1) % palette.count]
    }

    private var statusLabel: String? {
        switch status {
        case .new: return nil
        case .reviewed: return selectedMode.localized(chinese: "已复习", english: "REVIEWED")
        case .mastered: return selectedMode.localized(chinese: "已掌握", english: "MASTERED")
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(String(format: "%02d", index))
                .font(AppFont.wordmark(17))
                .foregroundColor(indexAccent)
                .frame(width: 30, alignment: .leading)

            Text(word)
                .font(AppFont.wordmark(17))
                .foregroundColor(AppTheme.ink)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let masteryCount {
                MasteryDots(count: masteryCount, size: 7.4)
                    .fixedSize()
                    .frame(width: 74, alignment: .trailing)
            }

            Spacer(minLength: 4)

            if let statusLabel {
                Text(statusLabel)
                    .font(AppFont.sfMono(9, weight: .black))
                    .foregroundColor(accent.opacity(0.9))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(accent.opacity(0.08))
                    )
            }

            Image(systemName: "arrow.up.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(accent)
        }
        .frame(minHeight: 44)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .utilityPanel(cornerRadius: AppTheme.radiusM, accent: accent)
        .contentShape(Rectangle())
    }
}

struct MasteryDots: View {
    @ObservedObject private var dictionaryModeManager = DictionaryModeManager.shared
    let count: Int
    var maximum: Int = MasteryStore.maximumMastery
    var size: CGFloat = 7
    var filledColor: Color = AppTheme.wordmarkBlue

    var body: some View {
        HStack(spacing: size * 0.45) {
            ForEach(0..<maximum, id: \.self) { index in
                Circle()
                    .fill(index < count ? filledColor : AppTheme.divider.opacity(0.48))
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .stroke(index < count ? filledColor.opacity(0.72) : AppTheme.border.opacity(0.35), lineWidth: 0.6)
                    )
            }
        }
        .accessibilityLabel(dictionaryModeManager.selectedMode.localized(
            chinese: "熟练度 \(count) / \(maximum)",
            english: "Mastery \(count) of \(maximum)"
        ))
    }
}

private struct PDFExportItem: Identifiable {
    let id = UUID()
    let url: URL
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}

private struct HistoryWordDetailScreen: View {
    let query: String
    let mode: DictionaryMode

    @State private var word: Word?
    @State private var isLoading = true

    private let repository = WordRepository()

    var body: some View {
        ZStack {
            UtilityBackdrop()
                .ignoresSafeArea()

            if isLoading {
                DictionaryLoadingView(selectedMode: mode)
                    .padding(.horizontal, 20)
            } else if let word {
                ScrollView(showsIndicators: false) {
                    WordDetailView(word: word, selectedMode: mode)
                        .padding(.bottom, 40)
                }
            } else {
                DictionaryLookupUnavailableView(
                    message: mode.missingEntryMessage,
                    selectedMode: mode
                ) { }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task(id: query + mode.rawValue) {
            isLoading = true
            word = repository.getWordBySlug(query.lowercased(), mode: mode)
            isLoading = false
        }
    }
}
