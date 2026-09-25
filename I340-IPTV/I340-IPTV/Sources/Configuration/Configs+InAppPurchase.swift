//
//  Configs+InAppPurchase.swift
//  I340_IPTV
//

import Foundation

extension Configs {
    enum InAppPurcharse {
        static let enableShowInApp = AppConfiguration.shared.enableShowInApp()
        static let enableShowInAppWhenOpenApp = AppConfiguration.shared.enableShowInAppWhenOpenApp()
        static let iAPSubcriptionSecret = AppConfiguration.shared.iAPSubcriptionSecret()
        static let onetime = AppConfiguration.shared.iAPOneTime()
        static let weekly = AppConfiguration.shared.iAPWeekly()
        static let monthly = AppConfiguration.shared.iAPMonthly()
        static let yearly = AppConfiguration.shared.iAPYearly()
        static let yearlySaleOff = AppConfiguration.shared.iAPYearlySaleOff()
        static let miniPackage = AppConfiguration.shared.iAPMiniPackage()
        static var productIds: [String] {
            return [onetime, monthly, yearly]
        }
        static func stringProduct(idProduct: String) -> String {
            switch idProduct {
            case Configs.InAppPurcharse.monthly:
                return "Month"
            case Configs.InAppPurcharse.yearly, Configs.InAppPurcharse.yearlySaleOff:
                return "Year"
            default:
                return "Week"
            }
        }
        static var productsList: [IAPSKProduct] {
            return [
                IAPSKProduct(name: "yearly".localized, id: yearly, type: .autoRenewable, key: .year),
                IAPSKProduct(name: "monthly".localized, id: monthly, type: .autoRenewable, key: .month),
                IAPSKProduct(name: "weekly".localized, id: weekly, type: .autoRenewable, key: .week),
            ]
        }
        static var infoPremium = AppConfiguration.shared.infoPremium()
        static var message = AppConfiguration.shared.iAPMessage()
    }
}
