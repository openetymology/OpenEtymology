//
//  SettingsView.swift
//  wordety
//
//  Created by SkyRocket on 2026/01/10.
//

import SwiftUI

enum OpenEtymologyAppLinks {
    static let privacyPolicy = "https://www.openetymology.com/privacy"
    static let support = "https://www.openetymology.com/support"
    static let sources = "https://www.openetymology.com/sources"
    static let supportEmail = "openetymology@proton.me"
    static let supportMail = "mailto:openetymology@proton.me"
    static let standardEULA = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    static let manageSubscriptions = "https://apps.apple.com/account/subscriptions"
}

struct SettingsView: View {
    @ObservedObject private var detailTextSizeManager = DetailTextSizeManager.shared
    @ObservedObject private var plusAccess = PlusAccessManager.shared
    @ObservedObject private var dictionaryModeManager = DictionaryModeManager.shared
    @State private var isShowingPaywall = false

    // 获取 App 版本号
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                UtilityBackdrop()
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 30) {
                    // 顶部标题
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dictionaryModeManager.selectedMode.localized(chinese: "设置", english: "SETTINGS"))
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .kerning(4)
                            .foregroundColor(AppTheme.jewelPurple)
                        
                        Text(dictionaryModeManager.selectedMode.localized(chinese: "偏好设置", english: "Preferences"))
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.ink)
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 30)
                    
                    // 设置分组
                    VStack(spacing: 20) {
                        SettingsSection(title: dictionaryModeManager.selectedMode.localized(chinese: "方案", english: "PLAN")) {
                            PlusAccessControl(
                                manager: plusAccess,
                                selectedMode: dictionaryModeManager.selectedMode,
                                showPaywall: {
                                    isShowingPaywall = true
                                },
                                manageSubscription: {
                                    openURL(OpenEtymologyAppLinks.manageSubscriptions)
                                }
                            )
                        }

                        SettingsSection(title: dictionaryModeManager.selectedMode.localized(chinese: "释义字号", english: "DETAIL TEXT")) {
                            DetailTextSizeControl(manager: detailTextSizeManager, selectedMode: dictionaryModeManager.selectedMode)
                        }

                        // 0. 学习合集管理
                        SettingsSection(title: dictionaryModeManager.selectedMode.localized(chinese: "学习合集", english: "STUDY SETS")) {
                            NavigationLink(destination: WordPackListView()) {
                                HStack(spacing: 15) {
                                    Image(systemName: "folder.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(AppTheme.jewelPurple)
                                        .frame(width: 32)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(dictionaryModeManager.selectedMode.localized(chinese: "我的合集", english: "My Collections"))
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundColor(AppTheme.ink)
                                        
                                        Text(dictionaryModeManager.selectedMode.localized(chinese: "我的学习合集", english: "My study sets"))
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                            .foregroundColor(AppTheme.wordmarkBlue)

                                        Text(dictionaryModeManager.selectedMode.localized(
                                            chinese: "\(WordPackManager.shared.packs.count) 个学习合集",
                                            english: "\(WordPackManager.shared.packs.count) study sets"
                                        ))
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundColor(AppTheme.mutedInk)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: plusAccess.canCreateWordPacks ? "chevron.right" : "lock.fill")
                                        .font(.system(size: plusAccess.canCreateWordPacks ? 14 : 15, weight: .bold))
                                        .foregroundColor(plusAccess.canCreateWordPacks ? AppTheme.mutedInk.opacity(0.52) : AppTheme.wordmarkBlue)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .utilityPanel(cornerRadius: AppTheme.radiusM, accent: plusAccess.canCreateWordPacks ? AppTheme.jewelPurple : AppTheme.wordmarkBlue)
                            }
                        }
                        
                        // 1. 关于 App
                        SettingsSection(title: dictionaryModeManager.selectedMode.localized(chinese: "关于", english: "ABOUT")) {
                            VStack(spacing: 0) {
                                SettingsRow(
                                    icon: "info.circle.fill",
                                    title: dictionaryModeManager.selectedMode.localized(chinese: "版本", english: "Version"),
                                    color: AppTheme.jewelPurple
                                ) {
                                    Text("\(appVersion) (\(buildNumber))")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(AppTheme.mutedInk)
                                }
                                
                                Divider().padding(.leading, 52)
                                
                                SettingsLinkRow(
                                    icon: "doc.text.fill",
                                    title: dictionaryModeManager.selectedMode.localized(chinese: "隐私政策", english: "Privacy Policy"),
                                    color: AppTheme.jewelCyan
                                ) {
                                    openURL(OpenEtymologyAppLinks.privacyPolicy)
                                }
                                
                                Divider().padding(.leading, 52)
                                
                                SettingsLinkRow(
                                    icon: "questionmark.circle.fill",
                                    title: dictionaryModeManager.selectedMode.localized(chinese: "支持与反馈", english: "Support & Feedback"),
                                    color: AppTheme.jewelPink
                                ) {
                                    openURL(OpenEtymologyAppLinks.support)
                                }

                                Divider().padding(.leading, 52)

                                SettingsLinkRow(
                                    icon: "envelope.fill",
                                    title: dictionaryModeManager.selectedMode.localized(chinese: "联系邮箱", english: "Contact Email"),
                                    color: AppTheme.jewelOrange
                                ) {
                                    openURL(OpenEtymologyAppLinks.supportMail)
                                }
                            }
                            .utilityPanel(cornerRadius: AppTheme.radiusM)
                        }
                        
                        // 2. 数据来源
                        SettingsSection(title: dictionaryModeManager.selectedMode.localized(chinese: "学习内容来源", english: "LEARNING CONTENT SOURCES")) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(dictionaryModeManager.selectedMode.localized(chinese: "词汇学习内容", english: "Vocabulary Learning Content"))
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.ink)
                                
                                Text(dictionaryModeManager.selectedMode.localized(
                                    chinese: "OpenEtymology 参考公开可用的语言学资料、历史语言资源和词频列表，并为英语词汇学习场景独立整理释义、例句、词源摘要和词形结构。",
                                    english: "OpenEtymology references publicly available linguistic materials, historical language resources, and frequency lists, then independently organizes definitions, examples, etymology summaries, and word-structure notes for English vocabulary learning."
                                ))
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(AppTheme.mutedInk)
                                    .lineSpacing(4)
                                
                                Button {
                                    openURL(OpenEtymologyAppLinks.sources)
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(dictionaryModeManager.selectedMode.localized(
                                            chinese: "查看来源与版权说明",
                                            english: "View Sources & Copyright"
                                        ))
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 11, weight: .black))
                                    }
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.wordmarkBlue)
                                    .padding(.top, 5)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .utilityPanel(cornerRadius: AppTheme.radiusM, accent: AppTheme.jewelOrange)
                        }
                        
                        // 3. 致谢
                        SettingsSection(title: dictionaryModeManager.selectedMode.localized(chinese: "致谢", english: "ACKNOWLEDGEMENTS")) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("OpenEtymology")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.ink)
                                
                                Text(dictionaryModeManager.selectedMode.localized(
                                    chinese: "一款精心打磨的词源学习应用，帮助你理解英语单词的来源、结构和深层含义。",
                                    english: "A beautifully crafted vocabulary learning app designed to help you explore the etymology and deep meanings of English words."
                                ))
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(AppTheme.mutedInk)
                                    .lineSpacing(4)
                                
                                Text(dictionaryModeManager.selectedMode.localized(chinese: "由 SkyRocket 制作", english: "Made by SkyRocket"))
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.jewelPink)
                                    .padding(.top, 5)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .utilityPanel(cornerRadius: AppTheme.radiusM, accent: AppTheme.jewelPink)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                        // 底部版权
                        Text(dictionaryModeManager.selectedMode.localized(
                            chinese: "© 2026 OpenEtymology。保留所有权利。",
                            english: "© 2026 OpenEtymology. All rights reserved."
                        ))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(AppTheme.mutedInk.opacity(0.58))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 20)
                            .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView()
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Components

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .kerning(1)
                .foregroundColor(AppTheme.mutedInk.opacity(0.72))
                .padding(.leading, 5)
            
            content
        }
    }
}

struct SettingsRow<Accessory: View>: View {
    let icon: String
    let title: String
    let color: Color
    let accessory: Accessory
    
    init(icon: String, title: String, color: Color, @ViewBuilder accessory: () -> Accessory) {
        self.icon = icon
        self.title = title
        self.color = color
        self.accessory = accessory()
    }
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 32)
            
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.ink)
            
            Spacer()
            
            accessory
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppTheme.surfaceElevated)
    }
}

struct SettingsLinkRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                    .frame(width: 32)
                
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.ink)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.mutedInk.opacity(0.52))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(AppTheme.surfaceElevated)
        }
    }
}

private struct DetailTextSizeControl: View {
    @ObservedObject var manager: DetailTextSizeManager
    let selectedMode: DictionaryMode

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Image(systemName: "textformat.size")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppTheme.wordmarkBlue)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedMode.localized(chinese: "学习内容正文", english: "Learning Content Text"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.ink)

                    Text(selectedMode.localized(
                        chinese: "释义、构词结构、词源和用法",
                        english: "Meaning, word structure, etymology and usage"
                    ))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.mutedInk)
                        .lineLimit(2)
                }

                Spacer()

                Text(manager.displayLabel)
                    .font(AppFont.sfMono(11, weight: .black))
                    .foregroundColor(AppTheme.wordmarkBlue)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .utilityPill(accent: AppTheme.wordmarkBlue)
            }

            Slider(
                value: $manager.offset,
                in: DetailTextSizeManager.minimumOffset...DetailTextSizeManager.maximumOffset,
                step: DetailTextSizeManager.step
            )
            .tint(AppTheme.wordmarkBlue)

            HStack(alignment: .lastTextBaseline) {
                Text("A")
                    .font(AppFont.editorial(manager.adjusted(14), weight: .medium))
                    .foregroundColor(AppTheme.mutedInk)

                Spacer()

                Text(selectedMode.localized(chinese: "主单词字号固定", english: "Main word stays fixed"))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.mutedInk.opacity(0.68))

                Spacer()

                Text("A")
                    .font(AppFont.editorial(manager.adjusted(20), weight: .semibold))
                    .foregroundColor(AppTheme.ink)
            }

            Button {
                withAnimation(.easeOut(duration: 0.16)) {
                    manager.reset()
                }
            } label: {
                Text(selectedMode.localized(chinese: "恢复默认", english: "Reset to Default"))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(manager.offset == 0 ? AppTheme.mutedInk.opacity(0.45) : AppTheme.wordmarkPink)
            }
            .buttonStyle(.plain)
            .disabled(manager.offset == 0)
        }
        .padding(18)
        .utilityPanel(cornerRadius: AppTheme.radiusM, accent: AppTheme.wordmarkBlue)
    }
}

private struct PlusAccessControl: View {
    @ObservedObject var manager: PlusAccessManager
    let selectedMode: DictionaryMode
    let showPaywall: () -> Void
    let manageSubscription: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Image(systemName: manager.isPlusUnlocked ? "crown.fill" : "sparkles")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(manager.isPlusUnlocked ? AppTheme.wordmarkPink : AppTheme.wordmarkBlue)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text(planName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.ink)

                    Text(manager.isPlusUnlocked
                         ? selectedMode.localized(chinese: "无限历史、七星熟练度和自定义学习合集", english: "Unlimited history, seven-star mastery and custom study sets")
                         : selectedMode.localized(chinese: "永久无广告、离线运行，保留最近 50 条历史记录", english: "Always ad-free, offline, with the latest 50 history items"))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.mutedInk)
                        .lineLimit(2)
                }

                Spacer()

                if manager.isPlusUnlocked {
                    Text(selectedMode.localized(chinese: "已启用", english: "ACTIVE"))
                        .font(AppFont.sfMono(10, weight: .black))
                        .foregroundColor(AppTheme.wordmarkPink)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .utilityPill(accent: AppTheme.wordmarkPink)
                } else {
                    Button(selectedMode.localized(chinese: "升级", english: "Upgrade")) {
                        showPaywall()
                    }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        Capsule()
                            .fill(AppTheme.wordmarkBlue)
                    )
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                PlusFeatureRow(
                    icon: "nosign",
                    title: selectedMode.localized(chinese: "永久无广告", english: "Always ad-free")
                )
                PlusFeatureRow(
                    icon: "wifi.slash",
                    title: selectedMode.localized(chinese: "永久支持离线运行", english: "Offline forever")
                )
                PlusFeatureRow(
                    icon: "clock.arrow.circlepath",
                    title: selectedMode.localized(chinese: "最近 50 条历史记录", english: "Latest 50 history records")
                )
                PlusFeatureRow(
                    icon: "infinity",
                    title: selectedMode.localized(chinese: "无限历史记录", english: "Unlimited history records"),
                    locked: !manager.canUseUnlimitedHistory
                )
                PlusFeatureRow(
                    icon: "folder.badge.plus",
                    title: selectedMode.localized(chinese: "自定义学习合集", english: "Custom study sets"),
                    locked: !manager.canCreateWordPacks
                )
                PlusFeatureRow(
                    icon: "square.stack.3d.up.fill",
                    title: selectedMode.localized(chinese: "更多高阶练习合集", english: "More advanced study sets"),
                    locked: !manager.canUseAdvancedWordPacks
                )
                PlusFeatureRow(
                    icon: "doc.richtext.fill",
                    title: selectedMode.localized(
                        chinese: "个人学习笔记导出",
                        english: "Personal study notes export"
                    ),
                    locked: !manager.canExportHistoryPDF
                )
                PlusFeatureRow(
                    icon: "star.circle.fill",
                    title: selectedMode.localized(
                        chinese: "专属七星熟练度记忆系统\n（基于艾宾浩斯曲线优化）",
                        english: "Exclusive seven-star mastery memory system\n(optimized from Ebbinghaus)"
                    ),
                    locked: !manager.canTrackMastery
                )
            }

            if manager.isPlusUnlocked {
                Button {
                    if manager.activeEntitlement.isSubscription {
                        manageSubscription()
                    } else {
                        showPaywall()
                    }
                } label: {
                    Text(activeActionTitle)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.wordmarkBlue)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    showPaywall()
                } label: {
                    Text(selectedMode.localized(chinese: "了解 OpenEtymology Plus", english: "Explore OpenEtymology Plus"))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.wordmarkBlue)
                }
                .buttonStyle(.plain)
            }

#if DEBUG
            Button {
                withAnimation(.easeOut(duration: 0.18)) {
                    manager.setDebugOverride(!manager.debugOverrideUnlocked)
                }
            } label: {
                Text(manager.debugOverrideUnlocked
                     ? selectedMode.localized(chinese: "调试：关闭 Plus 模拟", english: "Debug: Disable Plus Override")
                     : selectedMode.localized(chinese: "调试：模拟 Plus", english: "Debug: Simulate Plus"))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.mutedInk.opacity(0.72))
            }
            .buttonStyle(.plain)
#endif
        }
        .padding(18)
        .utilityPanel(
            cornerRadius: AppTheme.radiusM,
            accent: manager.isPlusUnlocked ? AppTheme.wordmarkPink : AppTheme.wordmarkBlue
        )
    }

    private var planName: String {
        switch manager.activeEntitlement {
        case .monthlySubscription:
            return selectedMode.localized(chinese: "OpenEtymology Plus 月度版", english: "OpenEtymology Plus Monthly")
        case .yearlySubscription:
            return selectedMode.localized(chinese: "OpenEtymology Plus 年度版", english: "OpenEtymology Plus Yearly")
        case .lifetime:
            return selectedMode.localized(chinese: "OpenEtymology Plus 终身版", english: "OpenEtymology Plus Lifetime")
        case .debugOverride:
            return "OpenEtymology Plus"
        case .none:
            return selectedMode.localized(chinese: "OpenEtymology 基础版", english: "OpenEtymology Basic")
        }
    }

    private var activeActionTitle: String {
        manager.activeEntitlement.isSubscription
        ? selectedMode.localized(chinese: "管理订阅", english: "Manage Subscription")
        : selectedMode.localized(chinese: "查看 Plus 状态", english: "View Plus Status")
    }
}

private struct PlusFeatureRow: View {
    let icon: String
    let title: String
    var locked: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: locked ? "lock.fill" : icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(iconColor)
                .frame(width: 20)

            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(locked ? AppTheme.mutedInk : AppTheme.ink.opacity(0.88))
                .lineLimit(3)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(backgroundColor)
        )
    }

    private var iconColor: Color {
        locked ? AppTheme.mutedInk.opacity(0.58) : Self.availableBlue
    }

    private var backgroundColor: Color {
        locked ? AppTheme.mutedInk.opacity(0.07) : Self.availableBlueFill
    }

    private static let availableBlue = Color(red: 0.08, green: 0.56, blue: 0.94)
    private static let availableBlueFill = Color(red: 0.88, green: 0.95, blue: 1.0)
}

private struct UIEditionSelector: View {
    let selectedEdition: UIEdition
    let select: (UIEdition) -> Void

    var body: some View {
        VStack(spacing: 10) {
            ForEach(UIEdition.allCases) { edition in
                UIEditionOptionRow(
                    edition: edition,
                    isSelected: edition == selectedEdition
                ) {
                    select(edition)
                }
            }
        }
    }
}

private struct UIEditionOptionRow: View {
    let edition: UIEdition
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: edition.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? edition.accentColor : AppTheme.mutedInk)
                    .frame(width: 26)

                VStack(alignment: .leading, spacing: 4) {
                    Text(edition.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.ink)

                    Text(edition.subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.mutedInk)
                        .lineLimit(2)
                }

                Spacer(minLength: 10)

                HStack(spacing: 4) {
                    ForEach(Array(edition.swatches.enumerated()), id: \.offset) { _, color in
                        Circle()
                            .fill(color)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(AppTheme.border.opacity(0.72), lineWidth: 1)
                            )
                    }
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(isSelected ? edition.accentColor : AppTheme.mutedInk.opacity(0.46))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .utilityPanel(
                cornerRadius: AppTheme.radiusM,
                accent: isSelected ? edition.accentColor : nil
            )
        }
        .buttonStyle(.plain)
    }
}

// 为 SettingsSection 内的卡片添加圆角容器
extension SettingsSection where Content == AnyView {
    init(title: String, cardContent: () -> some View) {
        self.title = title
        self.content = AnyView(
            cardContent()
                .background(AppTheme.surfaceElevated)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
        )
    }
}
