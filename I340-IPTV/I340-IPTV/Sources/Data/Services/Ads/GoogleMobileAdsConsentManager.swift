//
//  GoogleMobileAdsConsentManager.swift
//  I340_IPTV
//
//  Created by Foxcode on 23/8/24.
//

import Foundation
import GoogleMobileAds
import UserMessagingPlatform

/// The Google Mobile Ads SDK provides the User Messaging Platform (Google's
/// IAB Certified consent management platform) as one solution to capture
/// consent for users in GDPR impacted countries. This is an example and
/// you can choose another consent management platform to capture consent.

class GoogleMobileAdsConsentManager: NSObject {
    static let shared = GoogleMobileAdsConsentManager()
    
    var canRequestAds: Bool {
        return ConsentInformation.shared.canRequestAds
    }
    
    var isPrivacyOptionsRequired: Bool {
        return ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }
    
    /// Helper method to call the UMP SDK methods to request consent information and load/present a
    /// consent form if necessary.
    func gatherConsent(
        from consentFormPresentationviewController: UIViewController,
        consentGatheringComplete: @escaping (Error?) -> Void
    ) {
        let parameters = RequestParameters()
        
        //For testing purposes, you can force a DebugGeography of EEA or not EEA.
#if DEBUG
        let debugSettings = DebugSettings()
        debugSettings.testDeviceIdentifiers = MobileAds.shared.requestConfiguration.testDeviceIdentifiers
        debugSettings.geography = DebugGeography.EEA
        parameters.debugSettings = debugSettings
#endif
        
        // Requesting an update to consent information should be called on every app launch.
        ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) {
            requestConsentError in
            guard requestConsentError == nil else {
                return consentGatheringComplete(requestConsentError)
            }
            
            ConsentForm.loadAndPresentIfRequired(from: consentFormPresentationviewController) {
                loadAndPresentError in
                
                // Consent has been gathered.
                consentGatheringComplete(loadAndPresentError)
            }
        }
    }
    
    /// Helper method to call the UMP SDK method to present the privacy options form.
    func presentPrivacyOptionsForm(
        from viewController: UIViewController, completionHandler: @escaping (Error?) -> Void
    ) {
        ConsentForm.presentPrivacyOptionsForm(
            from: viewController, completionHandler: completionHandler)
    }
}
