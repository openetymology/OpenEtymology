//
//  wordetyApp.swift
//  wordety
//
//  Created by SkyRocket on 2025/12/22.
//

import SwiftUI
import UIKit

@main
struct wordetyApp: App {
    init() {
        setupTabBarAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            AppLaunchGateView()
        }
    }
}

// MARK: - Startup

private struct AppLaunchGateView: View {
    @StateObject private var launchModel = AppLaunchModel()
    @StateObject private var storeKit = StoreKitPurchaseManager.shared

    var body: some View {
        ZStack {
            if launchModel.isReady {
                MainTabView()
                    .transition(.opacity.animation(.easeOut(duration: 0.2)))
            } else {
                AppLaunchProgressView(
                    progress: launchModel.progress,
                    phaseText: launchModel.phaseText
                )
                .transition(.opacity.animation(.easeOut(duration: 0.18)))
            }
        }
        .task {
            await launchModel.start()
        }
        .task {
            await storeKit.start()
        }
    }
}

@MainActor
private final class AppLaunchModel: ObservableObject {
    @Published var progress: Double = 0.08
    @Published var phaseText = "Opening study content"
    @Published var isReady = false

    private var hasStarted = false

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true

        let selectedMode = DictionaryModeManager.shared.selectedMode
        let warmupTask = Task.detached(priority: .utility) {
            AppLaunchWarmup.prewarmDictionary(mode: selectedMode)
        }

        await advance(to: 0.34, phase: "Preparing local index", duration: 0.22)
        await waitForWarmup(warmupTask, timeoutNanoseconds: 700_000_000)
        await advance(to: 0.76, phase: "Preparing word structure", duration: 0.28)
        await advance(to: 1.0, phase: "Ready", duration: 0.18)

        withAnimation(.easeOut(duration: 0.2)) {
            isReady = true
        }
    }

    private func advance(to target: Double, phase: String, duration: TimeInterval) async {
        phaseText = phase
        withAnimation(.easeOut(duration: duration)) {
            progress = target
        }

        let nanoseconds = UInt64(duration * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
    }

    private func waitForWarmup(_ task: Task<Void, Never>, timeoutNanoseconds: UInt64) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await task.value
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: timeoutNanoseconds)
            }
            _ = await group.next()
            group.cancelAll()
        }
    }
}

private enum AppLaunchWarmup {
    static func prewarmDictionary(mode: DictionaryMode) {
        _ = DatabaseManager.shared.getConnection(for: mode)
    }
}

private struct AppLaunchProgressView: View {
    let progress: Double
    let phaseText: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            UtilityBackdrop()
                .ignoresSafeArea()

            VStack(spacing: 22) {
                Image("OpenEtymologyLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 76, height: 76)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusM, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusM, style: .continuous)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )

                VStack(spacing: 7) {
                    (
                        Text("Open")
                            .foregroundColor(AppTheme.wordmarkPink)
                        +
                        Text("Etymology")
                            .foregroundColor(AppTheme.wordmarkBlue)
                    )
                    .font(AppFont.wordmark(26))
                    .lineLimit(1)

                    Text(phaseText)
                        .font(AppFont.ui(14, weight: .medium))
                        .foregroundColor(AppTheme.mutedInk)
                }

                VStack(spacing: 9) {
                    GeometryReader { proxy in
                        let width = proxy.size.width
                        let clampedProgress = max(0, min(progress, 1))

                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(AppTheme.surfaceElevated)
                                .overlay(
                                    Capsule()
                                        .stroke(AppTheme.border, lineWidth: 1)
                                )

                            Capsule()
                                .fill(AppTheme.wordmarkBlue)
                                .frame(width: max(16, width * clampedProgress))

                            if !reduceMotion {
                                Capsule()
                                    .fill(AppTheme.surfaceElevated.opacity(0.72))
                                    .frame(width: 28, height: 4)
                                    .offset(x: min(max(0, width * clampedProgress - 31), width - 28))
                            }
                        }
                    }
                    .frame(height: 7)

                    HStack(spacing: 8) {
                        loadingMark("parts", isActive: progress < 0.5)
                        loadingMark("meaning", isActive: progress >= 0.5 && progress < 0.9)
                        loadingMark("usage", isActive: progress >= 0.9)
                    }
                }
                .frame(maxWidth: 260)
            }
            .padding(.horizontal, 32)
            .offset(y: -14)
        }
    }

    private func loadingMark(_ text: String, isActive: Bool) -> some View {
        Text(text)
            .font(AppFont.sfMono(10, weight: .black))
            .foregroundColor(isActive ? AppTheme.ink.opacity(0.78) : AppTheme.mutedInk.opacity(0.48))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isActive ? AppTheme.surfaceElevated : AppTheme.surface)
                    .overlay(
                        Capsule()
                            .stroke(isActive ? AppTheme.wordmarkBlue.opacity(0.28) : AppTheme.border.opacity(0.72), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Global UI Appearance
func setupTabBarAppearance() {
    let appearance = UITabBarAppearance()
    appearance.configureWithDefaultBackground()
    appearance.backgroundColor = UIColor(AppTheme.surfaceElevated)
    appearance.shadowColor = UIColor(Color.black.opacity(0.06))

    let selectedColor = UIColor(AppTheme.wordmarkBlue)
    let normalColor = UIColor(AppTheme.mutedInk)

    appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
    appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
    appearance.stackedLayoutAppearance.normal.iconColor = normalColor
    appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]

    appearance.inlineLayoutAppearance = appearance.stackedLayoutAppearance
    appearance.compactInlineLayoutAppearance = appearance.stackedLayoutAppearance
    
    UITabBar.appearance().standardAppearance = appearance
    if #available(iOS 15.0, *) {
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    UITabBar.appearance().unselectedItemTintColor = normalColor
    UITabBar.appearance().tintColor = selectedColor
}
