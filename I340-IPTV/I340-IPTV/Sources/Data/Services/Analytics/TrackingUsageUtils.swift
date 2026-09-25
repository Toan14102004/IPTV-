//
//  TrackingUsageUtils.swift
//  I340_IPTV
//
//  Created by Kietkoy on 3/2/26.
//

import UIKit
import GoogleMobileAds
import UserMessagingPlatform
import AppTrackingTransparency

class TrackingUsageUtils: NSObject {
    
    static let shared = TrackingUsageUtils()
    
    static var isATTAuthorized: Bool {
        if #available(iOS 14.5, *) {
            return ATTrackingManager.trackingAuthorizationStatus == .authorized
        } else {
            return true          // IDFA was available pre-14.5
        }
    }
    
    var canRequestAds: Bool {
        ConsentInformation.shared.canRequestAds
    }
    
    var isPrivacyOptionsRequired: Bool {
        ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }
    
    private override init() { }
    
    // MARK: - IDFA
    static func requestIDFA(onCompleted: @escaping (Bool) -> Void) {
        shared.requestIDFA(onCompleted: onCompleted)
    }
    
    func requestIDFA(onCompleted: @escaping (Bool) -> Void) {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                onCompleted(status == .authorized)
            }
        } else {
            onCompleted(true)
        }
    }
    
    private func loadForm(_ parentVC: UIViewController,
                          onPresented: @escaping () -> Void,
                          onCompleted: @escaping () -> Void) {
        ConsentForm.load { form, loadError in
            if let loadError {
                print("[GDPR]: Load form error")
                print("[GDPR]: \(loadError.localizedDescription)")
                onCompleted()
                return
            }
            
            guard ConsentInformation.shared.consentStatus == .required else {
                onCompleted()
                return
            }
            
            onPresented()
            form?.present(from: parentVC) { dismissError in
                if let dismissError {
                    print("[GDPR]: present form error")
                    print("[GDPR]: \(dismissError.localizedDescription)")
                }
                onCompleted()
            }
        }
    }
    
    func gatherConsent(from viewController: UIViewController,
                       consentGatheringComplete: @escaping (Error?) -> Void) {
        let parameters = RequestParameters()
        
#if DEBUG
        let debugSettings = DebugSettings()
        debugSettings.testDeviceIdentifiers = MobileAds.shared.requestConfiguration.testDeviceIdentifiers
        debugSettings.geography = DebugGeography.EEA
        parameters.debugSettings = debugSettings
#endif
        
        ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { error in
            guard error == nil else {
                consentGatheringComplete(error)
                return
            }
            
            ConsentForm.loadAndPresentIfRequired(from: viewController) { formError in
                consentGatheringComplete(formError)
            }
        }
    }
    
    func presentPrivacyOptionsForm(from viewController: UIViewController,
                                   completionHandler: @escaping (Error?) -> Void) {
        ConsentForm.presentPrivacyOptionsForm(from: viewController, completionHandler: completionHandler)
    }
}

