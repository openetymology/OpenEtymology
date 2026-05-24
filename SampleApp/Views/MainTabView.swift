//
//  MainTabView.swift
//  wordety
//
//  Created by SkyRocket on 2025/12/25.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel = SearchViewModel()
    @ObservedObject private var uiEditionManager = UIEditionManager.shared
    @ObservedObject private var dictionaryModeManager = DictionaryModeManager.shared
    @State private var selection: Tab = .home
    
    enum Tab {
        case home
        case history
        case cosmos
        case stats
        case settings
    }
    
    var body: some View {
        TabView(selection: $selection) {
            SearchView()
                .environmentObject(viewModel)
                .tabItem {
                    Label(tabTitle(.home), systemImage: "house.fill")
                }
                .tag(Tab.home)
            
            LazyTabContent {
                HistoryView()
                    .environmentObject(viewModel)
            }
                .tabItem {
                    Label(tabTitle(.history), systemImage: "clock.fill")
                }
                .tag(Tab.history)

            LazyTabContent {
                CosmosView()
                    .environmentObject(viewModel)
            }
                .tabItem {
                    Label(tabTitle(.cosmos), systemImage: "checkmark.circle.fill")
                }
                .tag(Tab.cosmos)
            
            LazyTabContent {
                StatsView()
            }
                .tabItem {
                    Label(tabTitle(.stats), systemImage: "chart.bar.fill")
                }
                .tag(Tab.stats)
            
            LazyTabContent {
                SettingsView()
            }
                .tabItem {
                    Label(tabTitle(.settings), systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .id(uiEditionManager.selectedEdition)
        .onChange(of: uiEditionManager.selectedEdition) { _, _ in
            setupTabBarAppearance()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openQuizTab)) { _ in
            withAnimation(.easeOut(duration: 0.18)) {
                selection = .cosmos
            }
        }
    }

    private var usesChineseInterface: Bool {
        dictionaryModeManager.selectedMode == .encn
    }

    private func tabTitle(_ tab: Tab) -> String {
        switch tab {
        case .home:
            return usesChineseInterface ? "首页" : "Home"
        case .history:
            return usesChineseInterface ? "历史" : "History"
        case .cosmos:
            return usesChineseInterface ? "练习" : "Quiz"
        case .stats:
            return usesChineseInterface ? "统计" : "Stats"
        case .settings:
            return usesChineseInterface ? "设置" : "Settings"
        }
    }
}

extension Notification.Name {
    static let openQuizTab = Notification.Name("OpenEtymologyOpenQuizTab")
}

private struct LazyTabContent<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
    }
}
