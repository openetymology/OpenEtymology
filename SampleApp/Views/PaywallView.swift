//
//  PaywallView.swift
//  wordety
//
//  Created by Codex on 2026/05/11.
//

import SwiftUI
import StoreKit

enum PaywallPlan: String, CaseIterable, Identifiable {
    case monthly
    case yearly
    case lifetime

    var id: String { rawValue }

    var productID: String {
        switch self {
        case .monthly: return StoreKitPurchaseManager.monthlyProductID
        case .yearly: return StoreKitPurchaseManager.yearlyProductID
        case .lifetime: return StoreKitPurchaseManager.lifetimeProductID
        }
    }

    static func sortIndex(for productID: String) -> Int {
        Self.allCases.firstIndex { $0.productID == productID } ?? Int.max
    }

    var title: String {
        title(for: .enen)
    }

    func title(for mode: DictionaryMode) -> String {
        switch self {
        case .monthly: return mode.localized(chinese: "月度", english: "Monthly")
        case .yearly: return mode.localized(chinese: "年度", english: "Yearly")
        case .lifetime: return mode.localized(chinese: "终身", english: "Lifetime")
        }
    }

    var price: String {
        switch self {
        case .monthly: return "$2.99"
        case .yearly: return "$19.99"
        case .lifetime: return "$49.99"
        }
    }

    var cadence: String {
        cadence(for: .enen)
    }

    func cadence(for mode: DictionaryMode) -> String {
        switch self {
        case .monthly: return mode.localized(chinese: "/ 月", english: "/ month")
        case .yearly: return mode.localized(chinese: "/ 年", english: "/ year")
        case .lifetime: return mode.localized(chinese: "一次性购买", english: "one-time")
        }
    }

    var note: String {
        note(for: .enen)
    }

    func note(for mode: DictionaryMode) -> String {
        switch self {
        case .monthly: return mode.localized(chinese: "7 天免费试用", english: "7-day free trial")
        case .yearly: return mode.localized(chinese: "14 天免费试用", english: "14-day free trial")
        case .lifetime: return mode.localized(chinese: "支持独立开发", english: "Support Independent Development")
        }
    }

    var badge: String? {
        badge(for: .enen)
    }

    func badge(for mode: DictionaryMode) -> String? {
        self == .yearly ? mode.localized(chinese: "最划算", english: "Best Value") : nil
    }
}

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    @ObservedObject private var dictionaryModeManager = DictionaryModeManager.shared
    @ObservedObject private var plusAccess = PlusAccessManager.shared
    @ObservedObject private var storeKit = StoreKitPurchaseManager.shared

    @State private var selectedPlan: PaywallPlan = .yearly
    @State private var didAppear = false

    private var palette: PaywallPalette {
        PaywallPalette(colorScheme: colorScheme)
    }

    var body: some View {
        ZStack {
            background

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    topBar
                    heroSection
                    benefitsSection
                    if plusAccess.isPlusUnlocked {
                        activeEntitlementSection
                        activeActionsSection
                    } else {
                        pricingSection
                        ctaSection
                    }
                    footerSection
                }
                .padding(.horizontal, 22)
                .padding(.top, 14)
                .padding(.bottom, 26)
                .opacity(didAppear ? 1 : 0)
                .scaleEffect(didAppear ? 1 : 0.985)
                .animation(.easeOut(duration: 0.32), value: didAppear)
            }
        }
        .preferredColorScheme(colorScheme)
        .onAppear {
            didAppear = true
        }
        .task {
            await storeKit.start()
            await storeKit.refreshPurchasedProducts()
            if !plusAccess.isPlusUnlocked {
                await storeKit.loadProducts()
            }
        }
    }

    private var background: some View {
        ZStack {
            palette.background.ignoresSafeArea()

            LinearGradient(
                colors: [
                    palette.blue.opacity(colorScheme == .dark ? 0.26 : 0.16),
                    palette.ivory.opacity(0.0),
                    palette.pink.opacity(colorScheme == .dark ? 0.18 : 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(palette.blue.opacity(colorScheme == .dark ? 0.13 : 0.10))
                .frame(width: 220, height: 220)
                .blur(radius: 28)
                .offset(x: 142, y: -230)

            Circle()
                .fill(palette.pink.opacity(colorScheme == .dark ? 0.12 : 0.08))
                .frame(width: 260, height: 260)
                .blur(radius: 34)
                .offset(x: -150, y: 330)
        }
    }

    private var topBar: some View {
        HStack {
            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(palette.secondaryText)
                    .frame(width: 34, height: 34)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(dictionaryModeManager.selectedMode.localized(chinese: "关闭", english: "Close"))
        }
    }

    private var heroSection: some View {
        VStack(spacing: 16) {
            Image("OpenEtymologyLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 82, height: 82)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: palette.shadow.opacity(0.16), radius: 22, x: 0, y: 10)

            VStack(spacing: 10) {
                Text(dictionaryModeManager.selectedMode.localized(chinese: "单词终于说得通了。", english: "Words finally make sense."))
                    .font(.system(size: 36, weight: .bold, design: .serif))
                    .foregroundColor(palette.primaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .minimumScaleFactor(0.82)

                Text(dictionaryModeManager.selectedMode.localized(
                    chinese: "为好奇心设计的现代词汇学习工具。",
                    english: "A modern vocabulary study tool designed for curious minds."
                ))
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(palette.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 12)
            }
        }
        .padding(.top, 2)
    }

    private var benefitsSection: some View {
        VStack(spacing: 10) {
            PaywallBenefitRow(icon: "nosign", title: dictionaryModeManager.selectedMode.localized(chinese: "永久无广告", english: "Always ad-free"), palette: palette)
            PaywallBenefitRow(icon: "bookmark.fill", title: dictionaryModeManager.selectedMode.localized(chinese: "无限保存历史搜索记录", english: "Unlimited search history"), palette: palette)
            PaywallBenefitRow(
                icon: "star.circle.fill",
                title: dictionaryModeManager.selectedMode.localized(
                    chinese: "专属七星熟练度记忆系统\n（基于艾宾浩斯曲线优化）",
                    english: "Seven-star mastery memory system"
                ),
                palette: palette
            )
            PaywallBenefitRow(icon: "square.stack.3d.up.fill", title: dictionaryModeManager.selectedMode.localized(chinese: "更多高阶练习合集", english: "More advanced study sets"), palette: palette)
            PaywallBenefitRow(icon: "folder.badge.plus", title: dictionaryModeManager.selectedMode.localized(chinese: "自定义学习合集", english: "Custom study sets"), palette: palette)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(palette.card.opacity(colorScheme == .dark ? 0.72 : 0.82))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(palette.hairline, lineWidth: 1)
                )
        )
    }

    private var pricingSection: some View {
        VStack(spacing: 12) {
            ForEach(PaywallPlan.allCases) { plan in
                PaywallPricingCard(
                    plan: plan,
                    isSelected: selectedPlan == plan,
                    isProminent: plan == .yearly,
                    displayPrice: storeKit.displayPrice(for: plan),
                    isAvailable: storeKit.product(for: plan) != nil,
                    isLoading: storeKit.isLoadingProducts,
                    palette: palette,
                    selectedMode: dictionaryModeManager.selectedMode
                ) {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                        selectedPlan = plan
                    }
                }
            }
        }
    }

    private var activeEntitlementSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(palette.blue)

            Text(dictionaryModeManager.selectedMode.localized(chinese: "OpenEtymology Plus 已启用", english: "OpenEtymology Plus is active"))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(palette.primaryText)
                .multilineTextAlignment(.center)

            Text(activeEntitlementMessage)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(palette.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(palette.card.opacity(colorScheme == .dark ? 0.76 : 0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(palette.blue.opacity(0.34), lineWidth: 1.2)
                )
        )
    }

    private var activeActionsSection: some View {
        VStack(spacing: 10) {
            if plusAccess.activeEntitlement.isSubscription {
                Button {
                    openExternalLink(OpenEtymologyAppLinks.manageSubscriptions)
                } label: {
                    Text(dictionaryModeManager.selectedMode.localized(chinese: "管理订阅", english: "Manage Subscription"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(
                                colors: [palette.blue, palette.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
            }

            Button {
                dismiss()
            } label: {
                Text(dictionaryModeManager.selectedMode.localized(chinese: "完成", english: "Done"))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(palette.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(palette.blue.opacity(colorScheme == .dark ? 0.16 : 0.10))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var ctaSection: some View {
        VStack(spacing: 10) {
            Button {
                guard canPurchaseSelectedPlan else { return }
                Task {
                    let didUnlock = await storeKit.purchase(selectedPlan)
                    if didUnlock {
                        dismiss()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if storeKit.isPurchasing {
                        ProgressView()
                            .tint(.white)
                    }

                    Text(ctaTitle)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(
                    LinearGradient(
                        colors: canPurchaseSelectedPlan
                        ? [palette.blue, palette.purple]
                        : [palette.secondaryText.opacity(0.46), palette.secondaryText.opacity(0.32)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .shadow(color: palette.blue.opacity(0.26), radius: 18, x: 0, y: 8)
            }
            .buttonStyle(.plain)
            .disabled(!canPurchaseSelectedPlan)

            if storeKit.isLoadingProducts {
                Text(dictionaryModeManager.selectedMode.localized(chinese: "正在载入购买选项…", english: "Loading purchase options..."))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(palette.secondaryText)
            } else if let message = storeKit.purchaseErrorMessage {
                Text(localizedPurchaseMessage(message))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(palette.pink)
                    .multilineTextAlignment(.center)

                if storeKit.products.isEmpty {
                    Button {
                        Task {
                            await storeKit.loadProducts()
                        }
                    } label: {
                        Text(dictionaryModeManager.selectedMode.localized(chinese: "重试", english: "Try Again"))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(palette.blue)
                    }
                    .buttonStyle(.plain)
                }
            } else if !selectedProductIsAvailable {
                Text(dictionaryModeManager.selectedMode.localized(chinese: "购买选项暂时不可用，请稍后重试。", english: "Purchase options are unavailable. Please try again."))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(palette.secondaryText)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 8) {
                Label(dictionaryModeManager.selectedMode.localized(chinese: "可随时取消", english: "Cancel anytime"), systemImage: "checkmark.circle.fill")
                Text("•")
                Text(dictionaryModeManager.selectedMode.localized(chinese: "没有长期绑定", english: "No commitment"))
            }
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundColor(palette.secondaryText)
        }
    }

    private var selectedProductIsAvailable: Bool {
        storeKit.product(for: selectedPlan) != nil
    }

    private var canPurchaseSelectedPlan: Bool {
        !plusAccess.isPlusUnlocked
        && !storeKit.isPurchasing
        && !storeKit.isLoadingProducts
        && selectedProductIsAvailable
    }

    private var ctaTitle: String {
        if storeKit.isPurchasing {
            return dictionaryModeManager.selectedMode.localized(chinese: "处理中…", english: "Processing...")
        }
        if storeKit.isLoadingProducts || (storeKit.products.isEmpty && storeKit.purchaseErrorMessage == nil) {
            return dictionaryModeManager.selectedMode.localized(chinese: "正在载入购买选项", english: "Loading Purchase Options")
        }
        if !selectedProductIsAvailable {
            return dictionaryModeManager.selectedMode.localized(chinese: "购买选项不可用", english: "Purchase Unavailable")
        }

        return selectedPlan == .lifetime
        ? dictionaryModeManager.selectedMode.localized(chinese: "解锁终身版", english: "Unlock Lifetime")
        : dictionaryModeManager.selectedMode.localized(chinese: "开始免费试用", english: "Start Free Trial")
    }

    private var activeEntitlementMessage: String {
        switch plusAccess.activeEntitlement {
        case .monthlySubscription:
            return dictionaryModeManager.selectedMode.localized(chinese: "你的月度订阅正在生效。你可以在 App Store 中管理或取消订阅。", english: "Your monthly subscription is active. You can manage or cancel it in the App Store.")
        case .yearlySubscription:
            return dictionaryModeManager.selectedMode.localized(chinese: "你的年度订阅正在生效。你可以在 App Store 中管理或取消订阅。", english: "Your yearly subscription is active. You can manage or cancel it in the App Store.")
        case .lifetime:
            return dictionaryModeManager.selectedMode.localized(chinese: "你已永久解锁所有 Plus 权益。", english: "Your lifetime Plus access is unlocked.")
        case .debugOverride:
            return dictionaryModeManager.selectedMode.localized(chinese: "调试模式已启用 Plus 权益。", english: "Plus access is enabled for debugging.")
        case .none:
            return dictionaryModeManager.selectedMode.localized(chinese: "你的 Plus 权益已准备就绪。", english: "Your Plus access is ready.")
        }
    }

    private var footerSection: some View {
        HStack(spacing: 18) {
            Button(dictionaryModeManager.selectedMode.localized(chinese: "隐私政策", english: "Privacy Policy")) {
                openExternalLink(OpenEtymologyAppLinks.privacyPolicy)
            }
            Button(dictionaryModeManager.selectedMode.localized(chinese: "使用条款", english: "Terms of Use")) {
                openExternalLink(OpenEtymologyAppLinks.standardEULA)
            }
            Button(dictionaryModeManager.selectedMode.localized(chinese: "恢复购买", english: "Restore Purchases")) {
                Task {
                    let didRestore = await storeKit.restorePurchases()
                    if didRestore {
                        dismiss()
                    }
                }
            }
        }
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .foregroundColor(palette.secondaryText)
        .padding(.top, 2)
    }

    private func localizedPurchaseMessage(_ message: String) -> String {
        guard dictionaryModeManager.selectedMode == .encn else { return message }

        if message.contains("not available") || message.contains("Unable to load") {
            return "购买选项暂时不可用，请稍后再试。"
        }
        if message.contains("No active") {
            return "没有找到有效的 OpenEtymology Plus 购买记录。"
        }
        if message.contains("pending") {
            return "购买正在等待批准。"
        }
        return message
    }

    private func openExternalLink(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        openURL(url)
    }
}

private struct PaywallBenefitRow: View {
    let icon: String
    let title: String
    let palette: PaywallPalette

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(palette.blue)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(palette.blue.opacity(0.10))
                )

            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(palette.primaryText)
                .lineLimit(3)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
    }
}

private struct PaywallPricingCard: View {
    let plan: PaywallPlan
    let isSelected: Bool
    let isProminent: Bool
    let displayPrice: String?
    let isAvailable: Bool
    let isLoading: Bool
    let palette: PaywallPalette
    let selectedMode: DictionaryMode
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 8) {
                        Text(plan.title(for: selectedMode))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(palette.primaryText)

                        if let badge = plan.badge(for: selectedMode) {
                            Text(badge)
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(palette.pink)
                                )
                        }
                    }

                    Text(plan.note(for: selectedMode))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(palette.secondaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(priceLabel)
                        .font(.system(size: displayPrice == nil && !isLoading ? 13 : (isProminent ? 22 : 20), weight: .bold, design: .rounded))
                        .foregroundColor(isAvailable || isLoading ? palette.primaryText : palette.secondaryText)

                    Text(plan.cadence(for: selectedMode))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(palette.secondaryText)
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isSelected ? palette.blue : palette.secondaryText.opacity(0.42))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, isProminent ? 17 : 15)
            .background(cardBackground)
            .scaleEffect(isSelected ? 1.015 : 1.0)
            .shadow(color: isProminent ? palette.blue.opacity(0.16) : palette.shadow.opacity(0.06), radius: isProminent ? 16 : 9, x: 0, y: 7)
        }
        .buttonStyle(.plain)
    }

    private var priceLabel: String {
        if let displayPrice {
            return displayPrice
        }
        if isLoading {
            return selectedMode.localized(chinese: "载入中", english: "Loading")
        }
        return selectedMode.localized(chinese: "不可用", english: "Unavailable")
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(
                isProminent
                ? LinearGradient(
                    colors: [
                        palette.card,
                        palette.blue.opacity(0.08),
                        palette.purple.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                : LinearGradient(
                    colors: [palette.card, palette.card],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? palette.blue.opacity(0.68) : palette.hairline, lineWidth: isSelected ? 1.6 : 1)
            )
    }
}

private struct PaywallPalette {
    let colorScheme: ColorScheme

    var background: Color {
        colorScheme == .dark
        ? Color(red: 0.045, green: 0.055, blue: 0.075)
        : Color(red: 0.990, green: 0.978, blue: 0.948)
    }

    var card: Color {
        colorScheme == .dark
        ? Color(red: 0.090, green: 0.105, blue: 0.135)
        : Color.white.opacity(0.86)
    }

    var primaryText: Color {
        colorScheme == .dark
        ? Color(red: 0.965, green: 0.956, blue: 0.930)
        : Color(red: 0.080, green: 0.105, blue: 0.155)
    }

    var secondaryText: Color {
        colorScheme == .dark
        ? Color(red: 0.690, green: 0.720, blue: 0.780)
        : Color(red: 0.395, green: 0.435, blue: 0.500)
    }

    var hairline: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }

    var shadow: Color {
        colorScheme == .dark ? Color.black : Color(red: 0.12, green: 0.16, blue: 0.25)
    }

    var ivory: Color {
        Color(red: 0.990, green: 0.978, blue: 0.948)
    }

    var blue: Color {
        Color(red: 0.090, green: 0.650, blue: 1.000)
    }

    var pink: Color {
        Color(red: 0.900, green: 0.095, blue: 0.480)
    }

    var purple: Color {
        Color(red: 0.480, green: 0.330, blue: 0.920)
    }
}
