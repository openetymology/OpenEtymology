//
//  StoreKitPurchaseManager.swift
//  OpenEtymologySample
//
//  Demo-only purchase manager. The public sample app has no real StoreKit
//  products and unlocks study features for local exploration.
//

import Foundation

@MainActor
final class StoreKitPurchaseManager: ObservableObject {
    static let shared = StoreKitPurchaseManager()

    nonisolated static let monthlyProductID = "org.openetymology.sample.plus.monthly"
    nonisolated static let yearlyProductID = "org.openetymology.sample.plus.yearly"
    nonisolated static let lifetimeProductID = "org.openetymology.sample.plus.lifetime"

    @Published private(set) var products: [String] = [
        monthlyProductID,
        yearlyProductID,
        lifetimeProductID
    ]
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isPurchasing = false
    @Published var purchaseErrorMessage: String?

    private init() { }

    var hasPlusEntitlement: Bool { true }
    var activeEntitlement: PlusEntitlement { .debugOverride }

    nonisolated static func entitlement(for productIDs: Set<String>) -> PlusEntitlement {
        .debugOverride
    }

    func start() async {
        PlusAccessManager.shared.updateStoreKitEntitlement(.debugOverride)
    }

    func refreshPurchasedProducts() async {
        PlusAccessManager.shared.updateStoreKitEntitlement(.debugOverride)
    }

    func loadProducts() async { }

    func product(for plan: PaywallPlan) -> String? {
        plan.productID
    }

    func displayPrice(for plan: PaywallPlan) -> String? {
        plan.price
    }

    @discardableResult
    func purchase(_ plan: PaywallPlan) async -> Bool {
        PlusAccessManager.shared.updateStoreKitEntitlement(.debugOverride)
        return true
    }

    @discardableResult
    func restorePurchases() async -> Bool {
        PlusAccessManager.shared.updateStoreKitEntitlement(.debugOverride)
        return true
    }
}
