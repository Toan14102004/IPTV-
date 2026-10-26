//
//  PaywallViewModel.swift
//  I340_IPTV
//

import Combine
import Foundation
import StoreKit
import SwiftUI

extension PaywallView {
    final class ViewModel: BaseViewModel {
        @Published var coordinator = Coordinator()
        @Published private(set) var products: [IAPProduct] = []
        @Published private(set) var selectedID: String?
        @Published private(set) var isLoadingProducts = true
        @Published private(set) var isProcessing = false
        @Published var toast: String?

        private let onFinish: (_ isPurchased: Bool) -> Void

        init(onFinish: @escaping (_ isPurchased: Bool) -> Void) {
            self.onFinish = onFinish
        }

        // MARK: - Derived state

        var selectedProduct: IAPProduct? {
            products.first { $0.id == selectedID }
        }

        var isBusy: Bool { isLoadingProducts || isProcessing }

        var policyText: String {
            let policy = "inapp_policy_short".localized
            guard let product = selectedProduct, product.isFreeTrial, product.dayFreeTrial != 0 else { return policy }
            let trial = String(
                format: "inapp_message_trial_policy".localized,
                product.dayFreeTrial,
                product.displayPrice,
                product.name.lowercased()
            )
            return trial + policy
        }

        /// Reassurance line under the plans: "no payment now" is only true for a free trial.
        var reassuranceText: String {
            guard let product = selectedProduct, product.isFreeTrial, product.dayFreeTrial != 0 else {
                return "inapp_cancel_anytime".localized
            }
            return "inapp_no_payment_now".localized
        }

        func title(for product: IAPProduct) -> String {
            if product.isFreeTrial {
                return String(
                    format: "free_trial".localized,
                    "\(product.dayFreeTrial)",
                    product.dayFreeTrial <= 1 ? "day_text".localized : "days_text".localized
                )
            }
            switch product.key {
            case .week: return "inapp_plan_weekly".localized
            case .month: return "inapp_plan_monthly".localized
            case .year: return "inapp_plan_yearly".localized
            case .onetime: return "lifetime".localized
            case .mini: return "mini".localized
            }
        }

        func detail(for product: IAPProduct) -> String {
            product.type == .nonRenewing ? "one_time_payment".localized : "inapp_auto_renewable".localized
        }

        func period(for product: IAPProduct) -> String {
            switch product.key {
            case .week: return "per_week".localized
            case .month: return "per_month".localized
            case .year: return "per_year".localized
            case .onetime: return "onetime_text".localized
            case .mini: return "per_day".localized
            }
        }

        // MARK: - Actions

        func onAppear() {
            guard products.isEmpty, isLoadingProducts else { return }
            loadProducts()
        }

        func select(_ product: IAPProduct) {
            selectedID = product.id
        }

        func didTapLimitedVersion() {
            onFinish(false)
        }

        func didTapContinue() {
            guard let product = selectedProduct, !isProcessing else { return }
            isProcessing = true

            AnalyticsService.shared.log(.custom("paywall_cta", ["item_id": product.product.id]))

            let completion: IAPHelper.PurchaseCompletion = { [weak self] message, result, _ in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.isProcessing = false
                    switch result {
                    case .purchased?:
                        EventTrackingHelper.shared.logEventInApp(product, type: .inapp)
                        self.coordinator.alert = .message(title: "", text: message, finishes: true)
                    default:
                        self.coordinator.alert = .message(title: "", text: message, finishes: nil)
                    }
                }
            }

            if product.type != .nonRenewing {
                IAPHelper.shared().handleSubscription(product: product, completion: completion)
            } else {
                IAPHelper.shared().handlePurchase(product: product, completion: completion)
            }
        }

        func didTapRestore() {
            guard !isProcessing else { return }
            isProcessing = true
            IAPHelper.shared().purchaseRestore { [weak self] message, result, _ in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.isProcessing = false
                    switch result {
                    case .purchased?:
                        EventTrackingHelper.shared.logEventInApp(nil, type: .restore)
                        self.coordinator.alert = .message(title: "", text: message, finishes: true)
                    default:
                        self.coordinator.alert = .message(title: "", text: message, finishes: nil)
                    }
                }
            }
        }

        func didTapTerms() {
            AppNavigator.present(.web(url: Configs.InfoApp.termOfUseUrl))
        }

        func didTapPrivacy() {
            AppNavigator.present(.web(url: Configs.InfoApp.policyUrl))
        }

        func closeAlert(finishes: Bool?) {
            coordinator.alert = nil
            if let finishes {
                onFinish(finishes)
            }
        }

        func dismissAlert() {
            coordinator.alert = nil
        }

        // MARK: - Products

        private func loadProducts() {
            let skProducts = Array(Configs.InAppPurcharse.productsList)

            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    let storeProducts = try await IAPHelper.shared().loadProducts(ids: skProducts.map(\.id))
                    let introOffers = await StoreKitIntroOfferEligibility.availability(for: storeProducts)
                    let productsByID = Dictionary(uniqueKeysWithValues: storeProducts.map { ($0.id, $0) })

                    var loaded = skProducts.compactMap { sku -> IAPProduct? in
                        guard let storeProduct = productsByID[sku.id] else { return nil }
                        let product = IAPProduct(
                            product: storeProduct,
                            isEligibleForIntroOffer: introOffers[sku.id] == true
                        )
                        product.type = sku.type
                        product.name = sku.name ?? ""
                        product.key = sku.key
                        product.isComsumable = sku.isComsumable
                        return product
                    }

                    let filters: [(Periods, Bool)] = [
                        (.mini, RemoteKonfig.shared.abTestingMiniPackage),
                        (.year, RemoteKonfig.shared.isShowYearProduct)
                    ]
                    loaded.removeAll { product in
                        filters.contains { $0.0 == product.key && !$0.1 }
                    }
                    loaded.sort { lhs, rhs in
                        let lhsOrder = Self.displayOrder(for: lhs.key)
                        let rhsOrder = Self.displayOrder(for: rhs.key)
                        if lhsOrder != rhsOrder { return lhsOrder < rhsOrder }
                        return lhs.price > rhs.price
                    }

                    isLoadingProducts = false
                    guard !loaded.isEmpty else {
                        coordinator.alert = .message(
                            title: "error".localized,
                            text: "no_products_found".localized,
                            finishes: false
                        )
                        return
                    }
                    products = loaded
                    selectedID = loaded.first?.id
                } catch {
                    isLoadingProducts = false
                    coordinator.alert = .message(
                        title: "error".localized,
                        text: "cannot_load_inapp".localized,
                        finishes: false
                    )
                }
            }
        }

        private static func displayOrder(for key: Periods) -> Int {
            switch key {
            case .year: 0
            case .month: 1
            case .week: 2
            case .mini: 3
            case .onetime: 4
            }
        }
    }
}
