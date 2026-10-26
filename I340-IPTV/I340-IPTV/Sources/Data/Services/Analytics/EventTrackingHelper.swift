//
//  EventTrackingHelper.swift
//  I340_IPTV
//
//  Created by Foxcode on 11/9/24.
//

import Foundation
import AdServices
import Alamofire
import AdjustSdk
import GoogleMobileAds
import StoreKit
import AppTrackingTransparency
import AdsDebugKit
import FBSDKCoreKit
import TikTokBusinessSDK
import FirebaseAnalytics

private struct PredictLogServerEnvironment {
    let endpoint: URL
    let apiKey: String

    init?(jsonString: String) {
        guard !jsonString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let dictionary = json as? [String: Any],
              let endpointString = Self.nonEmptyString(for: "iapEndPoint", in: dictionary),
              let endpoint = URL(string: endpointString),
              let apiKey = Self.nonEmptyString(for: "iapApiKey", in: dictionary) else {
            return nil
        }

        self.endpoint = endpoint
        self.apiKey = apiKey
    }

    private static func nonEmptyString(for key: String, in dictionary: [String: Any]) -> String? {
        guard let value = dictionary[key] as? String else { return nil }
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }
}

private struct PendingPredictPurchase: Codable {
    let bundleId: String
    let transactionId: String
    let productId: String
    let appInstanceId: String?
    let environment: String?
    let adjustAdid: String?
    let idfa: String?
    let idfv: String?

    init(
        bundleId: String,
        transactionId: String,
        productId: String,
        appInstanceId: String?,
        environment: String?,
        adjustAdid: String? = nil,
        idfa: String? = nil,
        idfv: String? = nil
    ) {
        self.bundleId = bundleId
        self.transactionId = transactionId
        self.productId = productId
        self.appInstanceId = appInstanceId
        self.environment = environment
        self.adjustAdid = adjustAdid
        self.idfa = idfa
        self.idfv = idfv
    }

    var payload: [String: Any] {
        var payload: [String: Any] = [
            "bundleId": bundleId,
            "transactionId": transactionId,
            "productId": productId,
            "environment": environment ?? "production",
            "adjustAdid": Self.jsonValue(
                PredictPurchaseDeviceIdentifiers.normalizedAdjustAdid(adjustAdid)
            ),
            "idfa": Self.jsonValue(
                PredictPurchaseDeviceIdentifiers.normalizedUUID(idfa)
            ),
            "idfv": Self.jsonValue(
                PredictPurchaseDeviceIdentifiers.normalizedUUID(idfv)
            )
        ]

        if let appInstanceId = appInstanceId?.trimmingCharacters(in: .whitespacesAndNewlines),
           !appInstanceId.isEmpty {
            payload["appInstanceId"] = appInstanceId
        }
        return payload
    }

    func merging(
        identifiers: PredictPurchaseDeviceIdentifiers,
        isATTAuthorized: Bool
    ) -> PendingPredictPurchase {
        PendingPredictPurchase(
            bundleId: bundleId,
            transactionId: transactionId,
            productId: productId,
            appInstanceId: appInstanceId,
            environment: environment,
            adjustAdid: identifiers.adjustAdid
                ?? PredictPurchaseDeviceIdentifiers.normalizedAdjustAdid(adjustAdid),
            idfa: isATTAuthorized
                ? identifiers.idfa ?? PredictPurchaseDeviceIdentifiers.normalizedUUID(idfa)
                : nil,
            idfv: identifiers.idfv
                ?? PredictPurchaseDeviceIdentifiers.normalizedUUID(idfv)
        )
    }

    private static func jsonValue(_ value: String?) -> Any {
        guard let value = value else { return NSNull() }
        return value
    }
}

private struct PredictPurchaseDeviceIdentifiers {
    let adjustAdid: String?
    let idfa: String?
    let idfv: String?

    init(
        adjustAdid: String?,
        idfa: String?,
        idfv: String?,
        isATTAuthorized: Bool
    ) {
        self.adjustAdid = Self.normalizedAdjustAdid(adjustAdid)
        self.idfa = isATTAuthorized ? Self.normalizedUUID(idfa) : nil
        self.idfv = Self.normalizedUUID(idfv)
    }

    static func normalizedAdjustAdid(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }
        return value
    }

    static func normalizedUUID(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              let uuid = UUID(uuidString: value),
              uuid != UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)) else {
            return nil
        }
        return uuid.uuidString
    }
}

private final class PredictPurchaseIdentifierCollectionState {
    enum IdentifierKind {
        case adjustAdid
        case idfa
        case idfv
    }

    private let stateQueue = DispatchQueue(label: "com.i340.predict-purchase-identifiers")
    private let callbackQueue: DispatchQueue
    private let isATTAuthorized: () -> Bool
    private var completion: ((PredictPurchaseDeviceIdentifiers) -> Void)?
    private var pendingCallbackCount: Int
    private var didComplete = false
    private var adjustAdid: String?
    private var idfa: String?
    private var idfv: String?

    init(
        pendingCallbackCount: Int,
        callbackQueue: DispatchQueue,
        isATTAuthorized: @escaping () -> Bool,
        completion: @escaping (PredictPurchaseDeviceIdentifiers) -> Void
    ) {
        self.pendingCallbackCount = pendingCallbackCount
        self.callbackQueue = callbackQueue
        self.isATTAuthorized = isATTAuthorized
        self.completion = completion
    }

    func receive(_ value: String?, for kind: IdentifierKind) {
        stateQueue.async { [self] in
            guard !didComplete else { return }

            switch kind {
            case .adjustAdid:
                adjustAdid = value
            case .idfa:
                idfa = value
            case .idfv:
                idfv = value
            }

            pendingCallbackCount -= 1
            if pendingCallbackCount == 0 {
                finish()
            }
        }
    }

    func timeout() {
        stateQueue.async { [self] in
            finish()
        }
    }

    private func finish() {
        guard !didComplete, let completion = completion else { return }
        didComplete = true
        self.completion = nil

        let identifiers = PredictPurchaseDeviceIdentifiers(
            adjustAdid: adjustAdid,
            idfa: idfa,
            idfv: idfv,
            isATTAuthorized: isATTAuthorized()
        )
        callbackQueue.async {
            completion(identifiers)
        }
    }
}

private struct PredictPurchaseIdentifierCollector {
    typealias IdentifierGetter = (@escaping (String?) -> Void) -> Void

    private let timeout: TimeInterval
    private let callbackQueue: DispatchQueue
    private let isATTAuthorized: () -> Bool
    private let adjustAdidGetter: IdentifierGetter
    private let idfaGetter: IdentifierGetter
    private let idfvGetter: IdentifierGetter

    init(
        timeout: TimeInterval = 2,
        callbackQueue: DispatchQueue = .main,
        isATTAuthorized: @escaping () -> Bool = { EventTrackingHelper.isATTAuthorized },
        adjustAdidGetter: @escaping IdentifierGetter = {
            Adjust.adid(completionHandler: $0)
        },
        idfaGetter: @escaping IdentifierGetter = {
            Adjust.idfa(completionHandler: $0)
        },
        idfvGetter: @escaping IdentifierGetter = {
            Adjust.idfv(completionHandler: $0)
        }
    ) {
        self.timeout = max(0, timeout)
        self.callbackQueue = callbackQueue
        self.isATTAuthorized = isATTAuthorized
        self.adjustAdidGetter = adjustAdidGetter
        self.idfaGetter = idfaGetter
        self.idfvGetter = idfvGetter
    }

    func collect(completion: @escaping (PredictPurchaseDeviceIdentifiers) -> Void) {
        let shouldCollectIDFA = isATTAuthorized()
        let state = PredictPurchaseIdentifierCollectionState(
            pendingCallbackCount: shouldCollectIDFA ? 3 : 2,
            callbackQueue: callbackQueue,
            isATTAuthorized: isATTAuthorized,
            completion: completion
        )

        adjustAdidGetter { state.receive($0, for: .adjustAdid) }
        idfvGetter { state.receive($0, for: .idfv) }
        if shouldCollectIDFA {
            idfaGetter { state.receive($0, for: .idfa) }
        }

        callbackQueue.asyncAfter(deadline: .now() + timeout) {
            state.timeout()
        }
    }
}

private final class PredictPurchaseInFlightGate {
    private let lock = NSLock()
    private var transactionIDs = Set<String>()

    func begin(transactionID: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return transactionIDs.insert(transactionID).inserted
    }

    func finish(transactionID: String) {
        lock.lock()
        transactionIDs.remove(transactionID)
        lock.unlock()
    }
}

private enum PredictPurchasePayloadRedactor {
    private static let identifierKeys = ["adjustAdid", "idfa", "idfv"]

    static func debugDescription(_ payload: [String: Any]) -> String {
        var redactedPayload = payload
        identifierKeys.forEach { key in
            guard let value = payload[key] else { return }
            redactedPayload[key] = value is NSNull ? "null" : "present"
        }

        guard JSONSerialization.isValidJSONObject(redactedPayload),
              let data = try? JSONSerialization.data(
                withJSONObject: redactedPayload,
                options: [.sortedKeys]
              ),
              let string = String(data: data, encoding: .utf8) else {
            return "Unable to serialize redacted purchase payload"
        }
        return string
    }
}

private enum PredictPurchaseTelemetryFormatter {
    static func debugLine(title: String, body: String) -> String {
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayBody = prettyPrintedJSON(trimmedBody)
            ?? (trimmedBody.isEmpty ? "<empty>" : trimmedBody)
        return "[PredictServer][\(title.uppercased())]\n\(displayBody)"
    }

    private static func prettyPrintedJSON(_ body: String) -> String? {
        guard let data = body.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              JSONSerialization.isValidJSONObject(object),
              let prettyData = try? JSONSerialization.data(
                withJSONObject: object,
                options: [.prettyPrinted, .sortedKeys]
              ) else {
            return nil
        }
        return String(data: prettyData, encoding: .utf8)
    }
}

private struct PredictPurchaseResponse: Decodable {
    let ok: Bool
}

private enum PredictPurchaseResponseValidator {
    static func isSuccess(statusCode: Int?, data: Data?) -> Bool {
        guard statusCode == 200,
              let data = data,
              let response = try? JSONDecoder().decode(PredictPurchaseResponse.self, from: data) else {
            return false
        }
        return response.ok
    }
}

private final class PredictPurchaseStore {
    private let userDefaults: UserDefaults
    private let maxTransactionIDs: Int
    private let sentIDsKey: String
    private let pendingPurchasesKey: String
    private let lock = NSLock()

    init(
        userDefaults: UserDefaults = .standard,
        maxTransactionIDs: Int = 500,
        sentIDsKey: String = "tracked_predict_server_transaction_ids",
        pendingPurchasesKey: String = "pending_predict_server_purchases"
    ) {
        self.userDefaults = userDefaults
        self.maxTransactionIDs = max(1, maxTransactionIDs)
        self.sentIDsKey = sentIDsKey
        self.pendingPurchasesKey = pendingPurchasesKey
    }

    func wasSent(transactionID: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return sentTransactionIDs().contains(transactionID)
    }

    func markSent(transactionID: String) {
        lock.lock()
        defer { lock.unlock() }

        var transactionIDs = sentTransactionIDs()
        guard !transactionIDs.contains(transactionID) else { return }
        transactionIDs.append(transactionID)
        userDefaults.set(Array(transactionIDs.suffix(maxTransactionIDs)), forKey: sentIDsKey)
    }

    func enqueue(_ purchase: PendingPredictPurchase) {
        lock.lock()
        defer { lock.unlock() }

        guard !sentTransactionIDs().contains(purchase.transactionId) else { return }
        var purchases = readPendingPurchases()
        guard !purchases.contains(where: { $0.transactionId == purchase.transactionId }) else { return }
        purchases.append(purchase)
        savePendingPurchases(Array(purchases.suffix(maxTransactionIDs)))
    }

    func upsertPending(_ purchase: PendingPredictPurchase) {
        lock.lock()
        defer { lock.unlock() }

        guard !sentTransactionIDs().contains(purchase.transactionId) else { return }
        var purchases = readPendingPurchases()
        if let index = purchases.firstIndex(where: { $0.transactionId == purchase.transactionId }) {
            purchases[index] = purchase
        } else {
            purchases.append(purchase)
        }
        savePendingPurchases(Array(purchases.suffix(maxTransactionIDs)))
    }

    func removePending(transactionID: String) {
        lock.lock()
        defer { lock.unlock() }
        savePendingPurchases(readPendingPurchases().filter { $0.transactionId != transactionID })
    }

    func pendingPurchases() -> [PendingPredictPurchase] {
        lock.lock()
        defer { lock.unlock() }
        return readPendingPurchases()
    }

    private func sentTransactionIDs() -> [String] {
        userDefaults.stringArray(forKey: sentIDsKey) ?? []
    }

    private func readPendingPurchases() -> [PendingPredictPurchase] {
        guard let data = userDefaults.data(forKey: pendingPurchasesKey),
              let purchases = try? JSONDecoder().decode([PendingPredictPurchase].self, from: data) else {
            return []
        }
        return purchases
    }

    private func savePendingPurchases(_ purchases: [PendingPredictPurchase]) {
        guard !purchases.isEmpty else {
            userDefaults.removeObject(forKey: pendingPurchasesKey)
            return
        }
        guard let data = try? JSONEncoder().encode(purchases) else { return }
        userDefaults.set(data, forKey: pendingPurchasesKey)
    }
}

class EventTrackingHelper: NSObject {
    
    static let shared = EventTrackingHelper.init()
    
    static var isATTAuthorized: Bool {
        if #available(iOS 14.5, *) {
            return ATTrackingManager.trackingAuthorizationStatus == .authorized
        } else {
            return true          // IDFA was available pre-14.5
        }
    }
    
    private var analyticsData: [String : Any] = [:]
    private let startLock = NSLock()
    private var hasStarted = false
    private let verifiedPurchaseTrackedIDsKey = "tracked_verified_purchase_transaction_ids"
    private let maxTrackedPurchaseIDs = 500
    private let verifiedPurchaseTrackingLock = NSLock()
    private let predictPurchaseStore = PredictPurchaseStore()
    private let predictPurchaseIdentifierCollector = PredictPurchaseIdentifierCollector()
    private let predictServerInFlightGate = PredictPurchaseInFlightGate()
    
    func startWith() {
        retryPendingPredictPurchases()

        startLock.lock()
        guard !hasStarted else {
            startLock.unlock()
            return
        }
        hasStarted = true
        startLock.unlock()

        configAdjust()
        configSearchAds()
        trackFirstOpenIfNeeded()
        tiktokConfig()
    }
    
    func configSearchAds() {
        recordAppleSearchAds()
    }
    
    func configAdjust() {
        if let tps = ADJThirdPartySharing(isEnabled: nil) {
            tps.addGranularOption(
                "facebook",
                key: "advertiser_tracking_enabled",
                value: EventTrackingHelper.isATTAuthorized ? "1" : "0"
            )
            Adjust.trackThirdPartySharing(tps)
        }
        adjustConfig(DefaultConfigToken.adjustToken.rawValue) // init adjust sdk
    }
    
    func logEventInApp(_ product: IAPProduct?, type: EventTrackingType) {
        if (type == .restore) {
            AnalyticsService.shared.log(.restorePurchase)
            logEventAdjustWithKey(.adjustTokenRestorePurchase)
            logServerSearchAds(purchaseName: "restore")
        } else {
            guard let product = product else { return }
            logServerSearchAds(purchaseName: product.key.value)
            trackEventInapp(period: product.key)
        }
    }

    /// Tracks a StoreKit 2 transaction once, whether it arrived from the
    /// purchase screen or from `Transaction.updates`.
    @discardableResult
    func logVerifiedPurchase(product: IAPProduct, transaction: Transaction) -> Bool {
        logServerPredictPurchase(transaction: transaction)

        let transactionID = String(transaction.id)
        guard shouldTrackVerifiedPurchase(transactionID: transactionID) else {
            print("[PurchaseTracking] Skip duplicate transaction_id=\(transactionID)")
            return false
        }

        let storeProduct = product.product
        let actualPrice = storeProduct.priceNumber.doubleValue
        let currency = storeProduct.currencyCode
        let isFreeTrial = storeProduct.subscription?.introductoryOffer?.paymentMode == .freeTrial
        let predictionPercent = max(0, RemoteKonfig.shared.freeTrialPredictPercentValue)
        let predictedValue = actualPrice * predictionPercent / 100
        let trackedRevenue = isFreeTrial ? predictedValue : actualPrice

        AnalyticsService.shared.log(.purchase(
            productID: storeProduct.id,
            transactionID: transactionID,
            value: trackedRevenue,
            currency: currency
        ))
        trackSubscriptions(product: storeProduct, transaction: transaction)
        logEventAdjustPurchase(
            productSelected: product,
            needMoney: trackedRevenue,
            currency: currency
        )
        if isFreeTrial {
            logEventAdjustWithKey(.adjustTokenFreeTrialPredict)
        }
        logPurchaseMetaEvent(
            product: product,
            transaction: transaction,
            amount: trackedRevenue,
            currency: currency
        )
        return true
    }

    func retryPendingPredictPurchases() {
        DispatchQueue.main.async { [weak self] in
            self?.sendPendingPredictPurchases()
        }
    }
    
    func handleAdPaidEvent(
        adRevenueNetwork: String,
        adValue: AdValue,
        adId: Configs.AdvertisementID,
        unit: AdUnitKind
    ) {
        print("Ad Value Precision: \(adValue.precision)")
        print("Ad Value: \(adValue.value)")
        print("Currency Code: \(adValue.currencyCode)")
        let amount = Double(truncating: adValue.value)
        
        // Track adjust revenue
        if let adRevenue = ADJAdRevenue(source: "admob_sdk") {
            adRevenue.setRevenue(amount, currency: adValue.currencyCode)
            adRevenue.setAdImpressionsCount(1)
            adRevenue.setAdRevenueNetwork(adRevenueNetwork)   // "AdMob", "Facebook", ...
            adRevenue.setAdRevenueUnit(adId.id)
            adRevenue.setAdRevenuePlacement(unit.raw)    // "interstitial", "native"...
            
            Adjust.trackAdRevenue(adRevenue)
        }
        
        AnalyticsService.shared.log(.adImpression(
            network: adRevenueNetwork,
            format: unit.raw,
            unit: adId.id,
            value: amount,
            currency: adValue.currencyCode
        ))

        // Sent adjust event ad revenue
        recordAdRevenue(amount: amount, currency: adValue.currencyCode)
        logAdRevenueMetaEvent(adRevenueNetwork: adRevenueNetwork, adValue: adValue)
        logAdRevenueTiktokEvent(adRevenueNetwork: adRevenueNetwork, adValue: adValue)
        
        // Log revenue to AdTelemetry
        AdTelemetry.shared.logRevenue(RevenueEvent(
            unit: unit,
            adId: adId,
            network: adRevenueNetwork,
            valueUSD: amount,
            precision: String(describing: adValue.precision)
        ))
    }
    
    func logEventAdjustWithKey(_ token: DefaultConfigToken) {
        guard !token.rawValue.isEmpty else {
#if DEBUG
            print("[Adjust] Skip \(token): missing event token")
#endif
            return
        }
        let event = ADJEvent(eventToken: token.rawValue)
        Adjust.trackEvent(event)
    }

    private func trackFirstOpenIfNeeded() {
        guard UserDefaultManager.shared().firstLaunchApp else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.logEventAdjustWithKey(.adjustTokenFirstOpen)
            UserDefaultManager.shared().firstLaunchApp = false
        }
    }
}

// MARK: -- private extension
private extension EventTrackingHelper {
    func adjustConfig(_ appToken: String) {
        let environment = (AdTelemetry.isDebugEnabled() || getDebugEnvironment)
        ? ADJEnvironmentSandbox as String
        : ADJEnvironmentProduction as String
        let adjustConfig = ADJConfig(
            appToken: appToken,
            environment: environment)
        
        adjustConfig?.logLevel = ADJLogLevel.verbose
        adjustConfig?.delegate = self
        
        Adjust.initSdk(adjustConfig)
    }
    
    private var getDebugEnvironment: Bool {
#if DEBUG
        return true
#else
        return false
#endif
    }
    
    func recordAppleSearchAds() {
        if #available(iOS 14.3, *) {
            DispatchQueue.global(qos: .background).async {
                var attributionToken = ""
                do {
                    attributionToken = try AAAttribution.attributionToken()
                } catch {
                    print("applySearchAdAttribution: AttributionToken error: \(error)")
                }
                if let url = URL(string: "https://api-adservices.apple.com/api/v1/") {
                    let request = NSMutableURLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
                    request.httpBody = Data(attributionToken.utf8)
                    let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, _, error) in
                        guard let data = data, error == nil else { return }
                        do {
                            guard let data = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                                return
                            }
                            if let campaignId = data["campaignId"] as? Int {
                                var logData = [String: Any]()
                                if campaignId != 1234567890 {
                                    logData["attribution"] = data["attribution"]
                                    logData["orgId"] = data["orgId"]
                                    logData["campaignID"] = campaignId
                                    logData["conversionType"] = data["conversionType"]
                                    logData["clickDate"] = data["clickDate"]
                                    logData["adGroupId"] = data["adGroupId"]
                                    logData["countryOrRegion"] = data["countryOrRegion"]
                                    logData["keywordId"] = data["keywordId"]
                                    logData["creativeSetId"] = data["creativeSetId"]
                                }
                                logData["appID"] = Configs.InfoApp.appIdWithoutIdPrefix
                                logData["attribution"] = UIDevice.current.systemVersion
                                print("applySearchAdAttribution: analyticsData>>>>>>>>>>>")
                                print(logData)
                                self.analyticsData = logData
                            }
                        } catch {
                            print("applySearchAdAttribution: analyticsData: error \(error)")
                        }
                    }
                    task.resume()
                }
            }
        }
    }
    
    func trackSubscriptions(product: Product, transaction: Transaction) {
        if let subscription = ADJAppStoreSubscription(
            price: product.priceNumber,
            currency: product.currencyCode,
            transactionId: String(transaction.id)
        ) {
            subscription.setTransactionDate(transaction.purchaseDate)
            subscription.setSalesRegion(product.regionCode)
            Adjust.trackAppStoreSubscription(subscription)
        }
    }
    
    func logServerSearchAds(purchaseName: String?) {
        if let purchaseName = purchaseName {
            analyticsData["purchase"] = purchaseName
            AF.request(
                "\(Configs.Domain.trackingUrl)api/log",
                method: .post,
                parameters: analyticsData,
                encoding: JSONEncoding.default
            ).responseJSON(queue: .global(qos: .background)) { response in
                switch response.result {
                case .success(let value):
                    print(value, "@@@>")
                case .failure(let error):
                    print(error, "@@@>")
                }
            }
        }
    }
    
    //MARK: -- Adjust
    func logEventAdjustPurchase(productSelected: IAPProduct, needMoney: Double, currency: String) {
        let token = DefaultConfigToken.adjustTokenPurchase.rawValue
        guard !token.isEmpty else { return }
        let event = ADJEvent(eventToken: token)
        event?.setRevenue(needMoney, currency: currency)
        Adjust.trackEvent(event)
    }
    
    func recordAdRevenue(amount: Double, currency: String) {
        let token = DefaultConfigToken.adjustTokenAdRevenue.rawValue
        guard !token.isEmpty else { return }
        let event = ADJEvent(eventToken: token)
        event?.setRevenue(amount, currency: currency)
        Adjust.trackEvent(event)
    }
    
    func trackEventInapp(period: Periods) {
        switch(period) {
        case .week:
            logEventAdjustWithKey(.adjustTokenWeeklyPurchase)
        case .month:
            logEventAdjustWithKey(.adjustTokenMonthlyPurchase)
        case .year:
            logEventAdjustWithKey(.adjustTokenYearlyPurchase)
        case .onetime:
            logEventAdjustWithKey(.adjustTokenOnetimePurchase)
        case .mini:
            logEventAdjustWithKey(.adjustTokenMiniPurchase)
        }
    }

    func shouldTrackVerifiedPurchase(transactionID: String) -> Bool {
        verifiedPurchaseTrackingLock.lock()
        defer { verifiedPurchaseTrackingLock.unlock() }

        var trackedIDs = UserDefaults.standard.stringArray(forKey: verifiedPurchaseTrackedIDsKey) ?? []
        guard !trackedIDs.contains(transactionID) else { return false }

        trackedIDs.append(transactionID)
        if trackedIDs.count > maxTrackedPurchaseIDs {
            trackedIDs.removeFirst(trackedIDs.count - maxTrackedPurchaseIDs)
        }
        UserDefaults.standard.set(trackedIDs, forKey: verifiedPurchaseTrackedIDsKey)
        return true
    }
    
    // MARK: - Log Ad, purchase Revenue Event
    
    func logPurchaseMetaEvent(
        product: IAPProduct,
        transaction: Transaction,
        amount: Double,
        currency: String
    ) {
        let parameters: [AppEvents.ParameterName: Any] = [
            .contentID: product.product.id,
            .contentType: product.key.value,
            .currency: currency,
            .transactionID: String(transaction.id)
        ]

        logPurchase(amount: amount, currency: currency, parameters: parameters)
    }
    
    func logAdRevenueMetaEvent(adRevenueNetwork: String, adValue: AdValue) {
        let amount = Double(truncating: adValue.value)
        let currency = adValue.currencyCode
        
        let parameters: [AppEvents.ParameterName: Any] = [
            .adType: adRevenueNetwork,
        ]
        
        logPurchase(amount: amount,
                  currency: currency,
                  parameters: parameters)
    }
    
    func logPurchase(amount: Double,
                     currency: String,
                     parameters: [AppEvents.ParameterName : Any]? = nil,
                     accessToken: AccessToken? = nil) {
        AppEvents.shared.logPurchase(amount: amount, currency: currency, parameters: parameters)
    }
}

private extension EventTrackingHelper {
    // MARK: - Verified purchase predict server

    func logServerPredictPurchase(transaction: Transaction) {
        let transactionID = String(transaction.id)
        guard !predictPurchaseStore.wasSent(transactionID: transactionID) else {
            logPredictServerDebug(
                "Transaction was already sent successfully",
                event: "purchase_deduplicated",
                status: .success,
                values: ["transactionId": transactionID]
            )
            return
        }

        let pendingPurchase = PendingPredictPurchase(
            bundleId: Bundle.main.bundleIdentifier ?? "",
            transactionId: transactionID,
            productId: transaction.productID,
            appInstanceId: Analytics.appInstanceID(),
            environment: shouldSendSandboxIAPEnvironment ? "sandbox" : "production"
        )
        predictPurchaseStore.enqueue(pendingPurchase)
        logPredictServerDebug(
            "Verified purchase saved to persistent retry queue",
            event: "purchase_enqueued",
            status: .submitted,
            values: predictServerDebugValues(for: pendingPurchase).merging([
                "pendingCount": "\(predictPurchaseStore.pendingPurchases().count)"
            ]) { _, newValue in newValue }
        )
        sendPendingPredictPurchases()
    }

    func sendPendingPredictPurchases() {
        let pendingPurchases = predictPurchaseStore.pendingPurchases()
        guard !pendingPurchases.isEmpty else { return }
        guard let environment = predictLogServerEnvironment() else {
            logPredictServerDebug(
                "Missing or invalid i340_notification_env; requests remain pending",
                event: "purchase_config",
                status: .failed,
                values: ["pendingCount": "\(pendingPurchases.count)"]
            )
            return
        }

        pendingPurchases.forEach { purchase in
            sendPendingPredictPurchase(purchase, environment: environment)
        }
    }

    func sendPendingPredictPurchase(
        _ purchase: PendingPredictPurchase,
        environment: PredictLogServerEnvironment
    ) {
        let transactionID = purchase.transactionId
        if predictPurchaseStore.wasSent(transactionID: transactionID) {
            predictPurchaseStore.removePending(transactionID: transactionID)
            return
        }

        guard predictServerInFlightGate.begin(transactionID: transactionID) else {
            logPredictServerDebug(
                "Request is already in flight",
                event: "purchase_deduplicated",
                status: .submitted,
                values: ["transactionId": transactionID]
            )
            return
        }

        predictPurchaseIdentifierCollector.collect { [weak self] identifiers in
            guard let self = self else { return }

            if self.predictPurchaseStore.wasSent(transactionID: transactionID) {
                self.predictPurchaseStore.removePending(transactionID: transactionID)
                self.predictServerInFlightGate.finish(transactionID: transactionID)
                return
            }

            let enrichedPurchase = purchase.merging(
                identifiers: identifiers,
                isATTAuthorized: EventTrackingHelper.isATTAuthorized
            )
            self.predictPurchaseStore.upsertPending(enrichedPurchase)
            self.postPendingPredictPurchase(enrichedPurchase, environment: environment)
        }
    }

    func postPendingPredictPurchase(
        _ purchase: PendingPredictPurchase,
        environment: PredictLogServerEnvironment
    ) {
        let transactionID = purchase.transactionId
        let payload = purchase.payload
        let headers: HTTPHeaders = [
            "x-api-key": environment.apiKey,
            "Content-Type": "application/json"
        ]

        logPredictServerDebug(
            "POST purchase tracking request",
            event: "purchase_request",
            status: .submitted,
            values: predictServerDebugValues(for: purchase).merging([
                "endpoint": environment.endpoint.absoluteString,
                "apiKey": maskedApiKey(environment.apiKey),
                "payload": payloadDebugDescription(payload)
            ]) { _, newValue in newValue }
        )

        AF.request(
            environment.endpoint,
            method: .post,
            parameters: payload,
            encoding: JSONEncoding.default,
            headers: headers
        )
        .responseData { [weak self] response in
            guard let self = self else { return }
            defer {
                self.predictServerInFlightGate.finish(transactionID: transactionID)
            }

            let statusCode = response.response?.statusCode ?? 0
            let responseText = response.data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            if PredictPurchaseResponseValidator.isSuccess(
                statusCode: response.response?.statusCode,
                data: response.data
            ) {
                self.predictPurchaseStore.markSent(transactionID: transactionID)
                self.predictPurchaseStore.removePending(transactionID: transactionID)
                self.logPredictServerDebug(
                    "Server accepted purchase; transaction marked as sent",
                    event: "purchase_response",
                    status: .success,
                    values: [
                        "transactionId": transactionID,
                        "statusCode": "\(statusCode)",
                        "body": responseText,
                        "pendingCount": "\(self.predictPurchaseStore.pendingPurchases().count)"
                    ]
                )
            } else if response.error == nil {
                self.logPredictServerDebug(
                    "Server returned an invalid acknowledgement; request remains pending",
                    event: "purchase_response",
                    status: .failed,
                    values: [
                        "transactionId": transactionID,
                        "statusCode": "\(statusCode)",
                        "body": responseText
                    ]
                )
            } else {
                self.logPredictServerDebug(
                    "Purchase request failed; request remains pending",
                    event: "purchase_response",
                    status: .failed,
                    values: [
                        "transactionId": transactionID,
                        "statusCode": "\(statusCode)",
                        "body": responseText,
                        "error": response.error?.localizedDescription ?? "invalid_response"
                    ]
                )
            }
        }
    }

    func predictLogServerEnvironment() -> PredictLogServerEnvironment? {
        PredictLogServerEnvironment(jsonString: RemoteKonfig.shared.notificationEnvironment)
    }

    var shouldSendSandboxIAPEnvironment: Bool {
#if DEBUG
        return true
#else
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
#endif
    }

    func maskedApiKey(_ apiKey: String) -> String {
        guard apiKey.count > 8 else { return "***" }
        return "\(apiKey.prefix(4))...\(apiKey.suffix(4))"
    }

    func logPredictServerDebug(
        _ message: String,
        event: String,
        status: AdDebugExternalStatus,
        values: [String: String] = [:]
    ) {
        AdTelemetry.shared.logExternal(
            provider: "iap_server",
            event: event,
            status: status,
            message: message,
            values: values
        )

        let debugLine: String?
        if event == "purchase_request", let payload = values["payload"] {
            debugLine = PredictPurchaseTelemetryFormatter.debugLine(title: "request", body: payload)
        } else if event == "purchase_response", let body = values["body"] {
            debugLine = PredictPurchaseTelemetryFormatter.debugLine(title: "response", body: body)
        } else {
            debugLine = nil
        }

        if let debugLine {
            AdTelemetry.shared.logDebugLine(debugLine)
#if DEBUG
            print(debugLine)
#endif
        }
    }

    func predictServerDebugValues(for purchase: PendingPredictPurchase) -> [String: String] {
        var values = [
            "bundleId": purchase.bundleId,
            "transactionId": purchase.transactionId,
            "productId": purchase.productId,
            "environment": purchase.environment ?? "production",
            "appInstanceId": purchase.appInstanceId ?? ""
        ]

        let adjustAdid = PredictPurchaseDeviceIdentifiers.normalizedAdjustAdid(purchase.adjustAdid)
        let idfa = PredictPurchaseDeviceIdentifiers.normalizedUUID(purchase.idfa)
        let idfv = PredictPurchaseDeviceIdentifiers.normalizedUUID(purchase.idfv)

#if DEBUG
        values["adjustAdid"] = adjustAdid ?? "null"
        values["idfa"] = idfa ?? "null"
        values["idfv"] = idfv ?? "null"
#else
        values["adjustAdid"] = adjustAdid == nil ? "null" : "present"
        values["idfa"] = idfa == nil ? "null" : "present"
        values["idfv"] = idfv == nil ? "null" : "present"
#endif
        return values
    }

    func payloadDebugDescription(_ payload: [String: Any]) -> String {
#if DEBUG
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(
                withJSONObject: payload,
                options: [.sortedKeys]
              ),
              let string = String(data: data, encoding: .utf8) else {
            return "Unable to serialize purchase payload"
        }
        return string
#else
        return PredictPurchasePayloadRedactor.debugDescription(payload)
#endif
    }
}

extension EventTrackingHelper: AdjustDelegate {
    func adjustEventTrackingSucceeded(_ eventSuccessResponseData: ADJEventSuccess?) {
        print("[Adjust] adjustEventTrackingSucceeded \(eventSuccessResponseData?.eventToken ?? "")")
        AdTelemetry.shared.logExternal(
            provider: "adjust",
            event: eventSuccessResponseData?.eventToken ?? "event",
            status: .success,
            message: eventSuccessResponseData?.message,
            values: [
                "adid": eventSuccessResponseData?.adid ?? "",
                "timestamp": eventSuccessResponseData?.timestamp ?? "",
                "callbackId": eventSuccessResponseData?.callbackId ?? ""
            ]
        )
    }
    
    func adjustEventTrackingFailed(_ eventFailureResponseData: ADJEventFailure?) {
        print("[Adjust] adjustEventTrackingFailed \(eventFailureResponseData?.description ?? "")")
        AdTelemetry.shared.logExternal(
            provider: "adjust",
            event: eventFailureResponseData?.eventToken ?? "event",
            status: .failed,
            message: eventFailureResponseData?.message,
            values: [
                "adid": eventFailureResponseData?.adid ?? "",
                "timestamp": eventFailureResponseData?.timestamp ?? "",
                "callbackId": eventFailureResponseData?.callbackId ?? "",
                "willRetry": "\(eventFailureResponseData?.willRetry ?? false)"
            ]
        )
    }

    func adjustSessionTrackingSucceeded(_ sessionSuccessResponseData: ADJSessionSuccess?) {
        print("[Adjust] adjustSessionTrackingSucceeded \(sessionSuccessResponseData?.message ?? "")")
        AdTelemetry.shared.logExternal(
            provider: "adjust",
            event: "session",
            status: .success,
            message: sessionSuccessResponseData?.message,
            values: [
                "adid": sessionSuccessResponseData?.adid ?? "",
                "timestamp": sessionSuccessResponseData?.timestamp ?? ""
            ]
        )
    }

    func adjustSessionTrackingFailed(_ sessionFailureResponseData: ADJSessionFailure?) {
        print("[Adjust] adjustSessionTrackingFailed \(sessionFailureResponseData?.message ?? "")")
        AdTelemetry.shared.logExternal(
            provider: "adjust",
            event: "session",
            status: .failed,
            message: sessionFailureResponseData?.message,
            values: [
                "adid": sessionFailureResponseData?.adid ?? "",
                "timestamp": sessionFailureResponseData?.timestamp ?? "",
                "willRetry": "\(sessionFailureResponseData?.willRetry ?? false)"
            ]
        )
    }
}


// MARK: - Tiktok

extension EventTrackingHelper {
    func tiktokConfig() {
        let config = TikTokConfig(
            accessToken: Configs.Tracking.tikTokAccessToken,
            appId: Configs.InfoApp.appIdWithoutIdPrefix,
            tiktokAppId: Configs.Tracking.tikTokAppId
        )
        
        #if DEBUG
        config?.enableDebugMode()
        config?.setLogLevel(TikTokLogLevelDebug)
        #endif
        
        TikTokBusiness.initializeSdk(config) { success, error in
            if success {
                print("[TikTok] SDK Initialized Successfully")
                #if DEBUG
                print("[TikTok] Test Event Code: \(TikTokBusiness.getTestEventCode())")
                #endif
            } else {
                print("[TikTok] SDK Initialization Failed: \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }
    
    func logAdRevenueTiktokEvent(adRevenueNetwork: String, adValue: AdValue) {
        let revenueValue = adValue.value
        let currencyCode = adValue.currencyCode
        let precision = adValue.precision
        
        var adRevenue: [String: Any] = [:]
        adRevenue["device_ad_mediation_platform"] = "admob_sdk"
        adRevenue["value"] = revenueValue
        adRevenue["currency_code"] = currencyCode
        adRevenue["precision"] = precision.rawValue // GADAdValuePrecision is enum, then take rawValue (Int)
        adRevenue["ad_source_name"] = adRevenueNetwork
        
        let adRevenueEvent = TikTokAdRevenueEvent(adRevenue: adRevenue, eventId:  UUID().uuidString)
        TikTokBusiness.trackTTEvent(adRevenueEvent)
        
//        // Test custom event to track ad value
//        let customEvent = TikTokBaseEvent(eventName: TTEventName.impressionLevelAdRevenue.rawValue, eventId: UUID().uuidString)

//        customEvent.addProperty(withKey: "currency", value: adValue.currencyCode.ttCurrency)
//        customEvent.addProperty(withKey: "value", value: revenueValue)
//        customEvent.addProperty(withKey: "precision", value: precision)
//        TikTokBusiness.trackTTEvent(customEvent)
    }
}


// MARK: - TikTok Currency Mapping

private extension String {
    /// Chuyển mã tiền tệ ISO (ví dụ "USD", "VND") sang TTCurrency của TikTok SDK
    /// Nếu không map được thì fallback về TTCurrencyUSD
    var ttCurrency: TTCurrency {
        switch self.uppercased() {
        case "AED": return TTCurrency.AED
        case "ARS": return TTCurrency.ARS
        case "AUD": return TTCurrency.AUD
        case "BDT": return TTCurrency.BDT
        case "BGN": return TTCurrency.BGN
        case "BHD": return TTCurrency.BHD
        case "BIF": return TTCurrency.BIF
        case "BOB": return TTCurrency.BOB
        case "BRL": return TTCurrency.BRL
        case "CAD": return TTCurrency.CAD
        case "CHF": return TTCurrency.CHF
        case "CLP": return TTCurrency.CLP
        case "CNY": return TTCurrency.CNY
        case "COP": return TTCurrency.COP
        case "CRC": return TTCurrency.CRC
        case "CZK": return TTCurrency.CZK
        case "DKK": return TTCurrency.DKK
        case "DZD": return TTCurrency.DZD
        case "EGP": return TTCurrency.EGP
        case "EUR": return TTCurrency.EUR
        case "GBP": return TTCurrency.GBP
        case "GTQ": return TTCurrency.GTQ
        case "HKD": return TTCurrency.HKD
        case "HNL": return TTCurrency.HNL
        case "HUF": return TTCurrency.HUF
        case "IDR": return TTCurrency.IDR
        case "ILS": return TTCurrency.ILS
        case "INR": return TTCurrency.INR
        case "IQD": return TTCurrency.IQD
        case "ISK": return TTCurrency.ISK
        case "JOD": return TTCurrency.JOD
        case "JPY": return TTCurrency.JPY
        case "KES": return TTCurrency.KES
        case "KHR": return TTCurrency.KHR
        case "KRW": return TTCurrency.KRW
        case "KWD": return TTCurrency.KWD
        case "KZT": return TTCurrency.KZT
        case "LBP": return TTCurrency.LBP
        case "MAD": return TTCurrency.MAD
        case "MOP": return TTCurrency.MOP
        case "MXN": return TTCurrency.MXN
        case "MYR": return TTCurrency.MYR
        case "NGN": return TTCurrency.NGN
        case "NIO": return TTCurrency.NIO
        case "NOK": return TTCurrency.NOK
        case "NZD": return TTCurrency.NZD
        case "OMR": return TTCurrency.OMR
        case "PEN": return TTCurrency.PEN
        case "PHP": return TTCurrency.PHP
        case "PKR": return TTCurrency.PKR
        case "PLN": return TTCurrency.PLN
        case "PYG": return TTCurrency.PYG
        case "QAR": return TTCurrency.QAR
        case "RON": return TTCurrency.RON
        case "RUB": return TTCurrency.RUB
        case "SAR": return TTCurrency.SAR
        case "SEK": return TTCurrency.SEK
        case "SGD": return TTCurrency.SGD
        case "THB": return TTCurrency.THB
        case "TRY": return TTCurrency.TRY
        case "TWD": return TTCurrency.TWD
        case "TZS": return TTCurrency.TZS
        case "UAH": return TTCurrency.UAH
        case "USD": return TTCurrency.USD
        case "VES": return TTCurrency.VES
        case "VND": return TTCurrency.VND
        case "ZAR": return TTCurrency.ZAR
        default:
            return TTCurrency.USD
        }
    }
}
