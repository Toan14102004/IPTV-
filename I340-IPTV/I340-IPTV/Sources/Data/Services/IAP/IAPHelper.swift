//
//  IAPHelper.swift
//  I340_IPTV
//

import Foundation
import StoreKit
import RxRelay

final class IAPHelper {
    private let membershipStatusKey = "user_membership_status"
    private let membershipExpiryDateKey = "user_membership_expired_date"
    private let lastSeenServerTimeKey = "user_last_seen_server_time"

    private let noMembership = "no_membership"
    private let expiredMembership = "expire_membership"
    private let premiumMembership = "premium_membership"

    private static let sharedInstance = IAPHelper()

    private var updateListenerTask: Task<Void, Never>?
    private var subscriptionCallbacks: [(Bool) -> Void] = []
    private let transactionStateQueue = DispatchQueue(
        label: "com.streamoiptv.storekit.transaction.state"
    )
    private var suppressUpdatePurchaseTrackingUntil: Date?
    private var suppressUpdatePurchaseTrackingStartedAt: Date?

    let purchaseS = BehaviorRelay<Bool>(value: false)

    var memberShipStatus: Bool {
        get { UserDefaults.standard.bool(forKey: membershipStatusKey) }
        set { UserDefaults.standard.set(newValue, forKey: membershipStatusKey) }
    }

    var memberShipExpiredDay: String? {
        get { UserDefaults.standard.string(forKey: membershipExpiryDateKey) }
        set { UserDefaults.standard.set(newValue, forKey: membershipExpiryDateKey) }
    }

    private init() {}

    deinit {
        updateListenerTask?.cancel()
    }

    class func shared() -> IAPHelper {
        sharedInstance
    }

    /// `sharedSecret` is retained in the call site for compatibility. StoreKit 2
    /// verifies signed transactions directly and does not use a shared secret here.
    func setupIAP(sharedSecret _: String? = nil) {
        guard updateListenerTask == nil else { return }
        updateListenerTask = listenForTransactions()
        Task { await refreshEntitlements() }
    }

    func loadProducts(ids: [String]) async throws -> [Product] {
        try await Product.products(for: ids)
    }

    func handlePurchase(
        product: IAPProduct,
        completion: PurchaseCompletion? = nil
    ) {
        purchase(
            product,
            successMessage: "you_have_purchased".localized,
            failureMessage: "purchase_handle_failed_try_again".localized,
            completion: completion
        )
    }

    func handleSubscription(
        product: IAPProduct,
        completion: PurchaseCompletion? = nil
    ) {
        purchase(
            product,
            successMessage: "you_have_purchased".localized,
            failureMessage: "purchase_failed_you_may_have_made_a_purchase".localized,
            completion: completion
        )
    }

    func purchaseRestore(completion: PurchaseCompletion? = nil) {
        beginRestorePurchaseTrackingSuppression()
        Task { @MainActor in
            do {
                try await AppStore.sync()
                await refreshEntitlements()
                endRestorePurchaseTrackingSuppression()
                let isPurchased = isSubscribed()
                notifyPurchaseState(isPurchased)
                completion?(
                    isPurchased
                        ? "you_have_restored_product_success_fully".localized
                        : "the_restore_was_failed_please_try_again_later".localized,
                    isPurchased ? .purchased : nil,
                    nil
                )
            } catch {
                endRestorePurchaseTrackingSuppression()
                completion?("the_restore_was_failed_please_try_again_later".localized, nil, nil)
            }
        }
    }

    func refreshEntitlements() async {
        var latestSubscriptionExpiry: Date?
        var hasNonConsumable = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.revocationDate == nil else {
                continue
            }

            switch transaction.productType {
            case .autoRenewable:
                if let expiry = transaction.expirationDate, expiry > Date(),
                   latestSubscriptionExpiry == nil || expiry > latestSubscriptionExpiry! {
                    latestSubscriptionExpiry = expiry
                }
            case .nonConsumable:
                hasNonConsumable = true
            default:
                break
            }
        }

        let hasActiveMembership = latestSubscriptionExpiry != nil || hasNonConsumable
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastSeenServerTimeKey)
        memberShipStatus = hasActiveMembership

        if let expiry = latestSubscriptionExpiry {
            memberShipExpiredDay = IAPUtils.getStringFromDate(date: expiry, format: "yyyy-MM-dd HH:mm")
        } else if hasNonConsumable {
            memberShipExpiredDay = "3000-01-01 00:00"
        } else {
            UserDefaults.standard.removeObject(forKey: membershipExpiryDateKey)
        }
    }

    func subscriptionSucceed(purchaseCallBack: @escaping (Bool) -> Void) {
        subscriptionCallbacks.append(purchaseCallBack)
    }

    func isSubscribed() -> Bool {
        memberShipStatus && userMembershipCheck() == premiumMembership
    }

    func userMembershipCheck() -> String {
        guard memberShipStatus,
              let expiryDateString = memberShipExpiredDay else {
            return noMembership
        }

        let expiryDate = IAPUtils.getDatefromString(strdate: expiryDateString, format: "yyyy-MM-dd HH:mm")
        let lastSeenServerTime = UserDefaults.standard.double(forKey: lastSeenServerTimeKey)
        let currentDate = lastSeenServerTime > 0
            ? max(Date(), Date(timeIntervalSince1970: lastSeenServerTime))
            : Date()
        return currentDate > expiryDate ? expiredMembership : premiumMembership
    }
}

// MARK: - Purchase flow

extension IAPHelper {
    typealias PurchaseCompletion = (_ message: String, _ purchaseResult: PurchaseSuccessResult?, _ transaction: Transaction?) -> Void

    private func purchase(
        _ product: IAPProduct,
        successMessage: String,
        failureMessage: String,
        completion: PurchaseCompletion?
    ) {
        Task { @MainActor in
            do {
                let result = try await product.product.purchase()
                switch result {
                case .success(let verification):
                    let transaction = try checkVerified(verification)
                    await refreshEntitlements()

                    guard isSubscribed() else {
                        await transaction.finish()
                        notifyPurchaseState(false)
                        completion?(failureMessage, nil, nil)
                        return
                    }

                    EventTrackingHelper.shared.logVerifiedPurchase(product: product, transaction: transaction)
                    await transaction.finish()
                    notifyPurchaseState(true)
                    completion?(successMessage, .purchased, transaction)
                case .userCancelled, .pending:
                    completion?(failureMessage, nil, nil)
                @unknown default:
                    completion?(failureMessage, nil, nil)
                }
            } catch {
                completion?(failureMessage, nil, nil)
            }
        }
    }
}

// MARK: - Transaction updates

private extension IAPHelper {
    func listenForTransactions() -> Task<Void, Never> {
        Task.detached(priority: .background) { [weak self] in
            guard let self else { return }

            for await update in Transaction.updates {
                guard !Task.isCancelled else { break }

                do {
                    let transaction = try self.checkVerified(update)
                    let trackingResult = await self.handleUpdatedTransaction(transaction)
                    switch trackingResult {
                    case .tracked, .skipped:
                        await transaction.finish()
                    case .retryLater:
                        break
                    }
                } catch {
                    print("[StoreKit2] Unverified transaction update: \(error)")
                }
            }
        }
    }

    func handleUpdatedTransaction(
        _ transaction: Transaction
    ) async -> TransactionUpdateTrackingResult {
        if transaction.productType == .autoRenewable || transaction.productType == .nonConsumable {
            await refreshEntitlements()
            notifyPurchaseState(isSubscribed())
        }

        if isTransactionUpdatePurchaseTrackingSuppressed(for: transaction) {
            return .skipped
        }

        return await trackUpdatedPurchaseIfNeeded(transaction)
    }

    func trackUpdatedPurchaseIfNeeded(
        _ transaction: Transaction
    ) async -> TransactionUpdateTrackingResult {
        guard shouldTrackUpdatedTransaction(transaction) else {
            return .skipped
        }

        do {
            guard let storeProduct = try await loadProducts(ids: [transaction.productID]).first else {
                print(
                    "[StoreKit2] Retry purchase tracking later; product not found product_id=\(transaction.productID)"
                )
                return .retryLater
            }

            guard let product = resolvedIAPProduct(from: storeProduct) else {
                print(
                    "[StoreKit2] Skip unsupported product_id=\(transaction.productID), type=\(storeProduct.type)"
                )
                return .skipped
            }

            let didTrackPurchase = await MainActor.run {
                EventTrackingHelper.shared.logVerifiedPurchase(
                    product: product,
                    transaction: transaction
                )
            }

            if didTrackPurchase {
                await MainActor.run {
                    EventTrackingHelper.shared.logEventInApp(
                        product,
                        type: self.logEventType(for: product)
                    )
                }
            }

            return didTrackPurchase ? .tracked : .skipped
        } catch {
            print(
                "[StoreKit2] Retry purchase tracking later; failed to load product_id=\(transaction.productID), error=\(error)"
            )
            return .retryLater
        }
    }

    func resolvedIAPProduct(from storeProduct: Product) -> IAPProduct? {
        let product = IAPProduct(product: storeProduct)

        switch storeProduct.type {
        case .autoRenewable:
            product.type = .autoRenewable
            product.key = IAPProduct.period(from: storeProduct) ?? .onetime
        case .nonConsumable, .nonRenewable, .consumable:
            product.type = .nonRenewing
            product.key = .onetime
            product.isComsumable = storeProduct.type == .consumable
        default:
            return nil
        }

        product.name = product.key.name
        return product
    }

    func logEventType(for product: IAPProduct) -> EventTrackingType {
        product.type == .autoRenewable ? .subcription : .inapp
    }

    func shouldTrackUpdatedTransaction(_ transaction: Transaction) -> Bool {
        if #available(iOS 17.0, *) {
            return transaction.reason == .purchase
        }
        return transaction.productType != .autoRenewable || transaction.id == transaction.originalID
    }

    func beginRestorePurchaseTrackingSuppression() {
        transactionStateQueue.sync {
            suppressUpdatePurchaseTrackingStartedAt = Date()
            suppressUpdatePurchaseTrackingUntil = .distantFuture
        }
    }

    func endRestorePurchaseTrackingSuppression() {
        transactionStateQueue.sync {
            suppressUpdatePurchaseTrackingUntil = Date().addingTimeInterval(5)
        }
    }

    func isTransactionUpdatePurchaseTrackingSuppressed(for transaction: Transaction) -> Bool {
        transactionStateQueue.sync {
            guard let suppressUpdatePurchaseTrackingUntil else { return false }
            guard Date() < suppressUpdatePurchaseTrackingUntil else {
                self.suppressUpdatePurchaseTrackingUntil = nil
                self.suppressUpdatePurchaseTrackingStartedAt = nil
                return false
            }
            guard let suppressUpdatePurchaseTrackingStartedAt else { return true }
            return transaction.purchaseDate <= suppressUpdatePurchaseTrackingStartedAt
        }
    }

    func notifyPurchaseState(_ isPurchased: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.purchaseS.accept(isPurchased)
            self.subscriptionCallbacks.forEach { $0(isPurchased) }
        }
    }

    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): return value
        case .unverified: throw StoreError.failedVerification
        }
    }
}

enum PurchaseSuccessResult {
    case purchased
}

private enum StoreError: Error {
    case failedVerification
}

private enum TransactionUpdateTrackingResult {
    case tracked
    case skipped
    case retryLater
}
