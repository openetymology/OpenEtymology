//
//  PlusAccessManager.swift
//  wordety
//
//  Created by Codex on 2026/05/11.
//

import Foundation

enum PlusEntitlement: Equatable {
    case none
    case monthlySubscription
    case yearlySubscription
    case lifetime
    case debugOverride

    var isUnlocked: Bool {
        self != .none
    }

    var isSubscription: Bool {
        switch self {
        case .monthlySubscription, .yearlySubscription:
            return true
        case .none, .lifetime, .debugOverride:
            return false
        }
    }
}

final class PlusAccessManager: ObservableObject {
    static let shared = PlusAccessManager()

    static let basicHistoryLimit = 50
    static let historyPDFExportLimit = 200

    @Published private(set) var isPlusUnlocked: Bool
    @Published private(set) var activeEntitlement: PlusEntitlement

#if DEBUG
    @Published private(set) var debugOverrideUnlocked: Bool
#endif

    private static let debugOverrideKey = "openetymology.samplePlusDebugOverrideUnlocked"
    private var storeKitEntitlement: PlusEntitlement = .none

    private init() {
#if DEBUG
        let debugOverride = UserDefaults.standard.bool(forKey: Self.debugOverrideKey)
        debugOverrideUnlocked = debugOverride
        activeEntitlement = debugOverride ? .debugOverride : .none
        isPlusUnlocked = debugOverride
#else
        activeEntitlement = .none
        isPlusUnlocked = false
#endif
    }

    func updateStoreKitEntitlement(_ entitlement: PlusEntitlement) {
        storeKitEntitlement = entitlement
        updateEffectiveAccess()
    }

#if DEBUG
    func setDebugOverride(_ isUnlocked: Bool) {
        debugOverrideUnlocked = isUnlocked
        UserDefaults.standard.set(isUnlocked, forKey: Self.debugOverrideKey)
        updateEffectiveAccess()
    }
#endif

    var historyLimit: Int? {
        isPlusUnlocked ? nil : Self.basicHistoryLimit
    }

    var canUseUnlimitedHistory: Bool {
        isPlusUnlocked
    }

    var canExportHistoryPDF: Bool {
        isPlusUnlocked
    }

    var canUseAdvancedWordPacks: Bool {
        isPlusUnlocked
    }

    var canCreateWordPacks: Bool {
        isPlusUnlocked
    }

    var canTrackMastery: Bool {
        isPlusUnlocked
    }

    var planName: String {
        isPlusUnlocked ? "OpenEtymology Plus" : "OpenEtymology Basic"
    }

    private func updateEffectiveAccess() {
#if DEBUG
        let effectiveEntitlement: PlusEntitlement = storeKitEntitlement.isUnlocked
        ? storeKitEntitlement
        : (debugOverrideUnlocked ? .debugOverride : .none)
#else
        let effectiveEntitlement = storeKitEntitlement
#endif

        if activeEntitlement != effectiveEntitlement {
            activeEntitlement = effectiveEntitlement
        }

        let effectiveAccess = effectiveEntitlement.isUnlocked
        if isPlusUnlocked != effectiveAccess {
            isPlusUnlocked = effectiveAccess
        }
    }
}
