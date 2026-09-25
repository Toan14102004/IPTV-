//
//  PresentationCenter.swift
//  I340_IPTV
//
//  Created by Kietkoy on 4/2/26.
//

import UIKit
import RxRelay
import ObjectiveC.runtime

final class PresentationCenter: NSObject, UIAdaptivePresentationControllerDelegate {
    static let shared = PresentationCenter()
    
    /// Emits the Window that triggered the stack change.
    /// BaseVC can check if this window is a DebugWindow to ignore.
    let stackDidChange = PublishRelay<UIWindow?>()

    func emit(from window: UIWindow?) {
        DispatchQueue.main.async { [weak self] in
            self?.stackDidChange.accept(window)
        }
    }

    // iOS 13+ Sheet Swipe Dismiss
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        // Emit the window of the presenting VC (the one underneath remaining)
        emit(from: presentationController.presentingViewController.view.window)
    }
}

extension UIViewController {
    
    static func installPresentationMonitoring() {
        _ = self._swizzleOnce
    }

    private static let _swizzleOnce: Void = {
        let swizzle = { (cls: AnyClass, original: Selector, swizzled: Selector) in
            guard let m1 = class_getInstanceMethod(cls, original),
                  let m2 = class_getInstanceMethod(cls, swizzled) else { return }
            method_exchangeImplementations(m1, m2)
        }
        
        swizzle(UIViewController.self, #selector(present(_:animated:completion:)), #selector(mon_present(_:animated:completion:)))
        swizzle(UIViewController.self, #selector(dismiss(animated:completion:)), #selector(mon_dismiss(animated:completion:)))
        
        print("[PresentationMonitor] Installed successfully")
    }()

    @objc private func mon_present(_ vc: UIViewController, animated: Bool, completion: (() -> Void)?) {
        // Fix: Don't hijack if delegate exists (e.g. SKStoreProductViewController)
        if vc.presentationController?.delegate == nil {
            vc.presentationController?.delegate = PresentationCenter.shared
        }
        
        // Capture window BEFORE present (source window)
        let sourceWindow = self.view.window
        
        mon_present(vc, animated: animated) {
            completion?()
            PresentationCenter.shared.emit(from: sourceWindow)
        }
        PresentationCenter.shared.emit(from: sourceWindow)
    }

    @objc private func mon_dismiss(animated: Bool, completion: (() -> Void)?) {
        // Capture window (source window)
        let sourceWindow = self.view.window
        
        mon_dismiss(animated: animated) {
            completion?()
            PresentationCenter.shared.emit(from: sourceWindow)
        }
        PresentationCenter.shared.emit(from: sourceWindow)
    }
}

