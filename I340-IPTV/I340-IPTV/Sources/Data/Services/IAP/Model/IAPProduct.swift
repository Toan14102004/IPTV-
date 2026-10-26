//
//  IAPProduct.swift
//  I340_IPTV
//

import Foundation
import StoreKit

enum Periods: Equatable {
    case week
    case month
    case year
    case onetime
    case mini

    var value: String {
        switch self {
        case .week: return "weekly"
        case .month: return "monthly"
        case .year: return "yearly"
        case .onetime: return "one-time"
        case .mini: return "mini"
        }
    }

    var name: String {
        switch self {
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        case .onetime: return "onetime"
        case .mini: return "mini"
        }
    }
}

enum StoreKitIntroOfferEligibility {
    typealias GroupEligibilityCheck = @Sendable (String) async -> Bool

    static func availability(
        for products: [Product],
        checkEligibility: @escaping GroupEligibilityCheck = { groupID in
            await Product.SubscriptionInfo.isEligibleForIntroOffer(for: groupID)
        }
    ) async -> [String: Bool] {
        let candidates = products.compactMap { product -> (productID: String, groupID: String)? in
            guard let subscription = product.subscription,
                  let offer = subscription.introductoryOffer,
                  offer.paymentMode == .freeTrial,
                  offer.period.value > 0 else {
                return nil
            }
            return (product.id, subscription.subscriptionGroupID)
        }

        let groupIDs = Set(candidates.map(\.groupID).filter { !$0.isEmpty })
        let eligibleGroups = await withTaskGroup(
            of: (String, Bool).self,
            returning: [String: Bool].self
        ) { group in
            for groupID in groupIDs {
                group.addTask { (groupID, await checkEligibility(groupID)) }
            }

            var result: [String: Bool] = [:]
            for await (groupID, isEligible) in group {
                result[groupID] = isEligible
            }
            return result
        }

        var availability = Dictionary(uniqueKeysWithValues: products.map { ($0.id, false) })
        for candidate in candidates {
            availability[candidate.productID] = eligibleGroups[candidate.groupID] == true
        }
        return availability
    }
}

final class IAPProduct {
    let product: Product
    var isSelected = false
    var name = ""
    var type: ProductType = .autoRenewable
    var key: Periods = .onetime
    var isComsumable = false

    private(set) var isFreeTrial = false
    private(set) var dayFreeTrial = 0

    init(
        product: Product,
        isSelected: Bool = false,
        isEligibleForIntroOffer: Bool = false
    ) {
        self.product = product
        self.isSelected = isSelected

        guard let offer = product.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial,
              offer.period.value > 0,
              isEligibleForIntroOffer else {
            return
        }

        isFreeTrial = true
        dayFreeTrial = Self.approximateDays(for: offer.period)
    }

    var id: String { product.id }
    var price: Decimal { product.price }

    var displayPrice: String {
        product.price.formatted(product.priceFormatStyle)
    }

    static func period(from product: Product) -> Periods? {
        guard let period = product.subscription?.subscriptionPeriod else { return nil }
        switch period.unit {
        case .day:
            switch period.value {
            case 7: return .week
            case 28, 30, 31: return .month
            case 365: return .year
            default: return nil
            }
        case .week:
            switch period.value {
            case 1: return .week
            case 4: return .month
            case 52: return .year
            default: return nil
            }
        case .month:
            switch period.value {
            case 1: return .month
            case 12: return .year
            default: return nil
            }
        case .year:
            return period.value == 1 ? .year : nil
        @unknown default:
            return nil
        }
    }

    private static func approximateDays(for period: Product.SubscriptionPeriod) -> Int {
        switch period.unit {
        case .day: return period.value
        case .week: return period.value * 7
        case .month: return period.value * 30
        case .year: return period.value * 365
        @unknown default: return 0
        }
    }
}

extension Product {
    var priceNumber: NSDecimalNumber {
        NSDecimalNumber(decimal: price)
    }

    var currencyCode: String {
        if #available(iOS 16.0, *) {
            return priceFormatStyle.locale.currency?.identifier ?? "USD"
        }
        return priceFormatStyle.locale.currencyCode ?? "USD"
    }

    var regionCode: String {
        if #available(iOS 16.0, *) {
            return priceFormatStyle.locale.region?.identifier ?? "US"
        }
        return priceFormatStyle.locale.regionCode ?? "US"
    }
}
