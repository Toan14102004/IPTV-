//
//  Localized.swift
//  I340_IPTV
//
//  Created by Foxcode on 10/9/24.
//

import UIKit
import ObjectiveC

extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.localizedBundle(), value: "", comment: "")
    }
}

private enum LocalizedAssociatedKeys {
    static var labelKey: UInt8 = 0
    static var labelAutoKey: UInt8 = 0
    static var buttonKey: UInt8 = 0
    static var buttonAutoKey: UInt8 = 0
    static var textViewKey: UInt8 = 0
    static var textViewAutoKey: UInt8 = 0
}

@IBDesignable extension UILabel {
    @IBInspectable var localizeKey: String? {
        set {
            objc_setAssociatedObject(self, &LocalizedAssociatedKeys.labelKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
            text = newValue?.localized
        }
        get {
            return objc_getAssociatedObject(self, &LocalizedAssociatedKeys.labelKey) as? String
        }
    }

    @IBInspectable var autoLocalize: Bool {
        set {
            objc_setAssociatedObject(self, &LocalizedAssociatedKeys.labelAutoKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            guard newValue else { return }
            if let localizeKey {
                text = localizeKey.localized
            } else if let currentText = text {
                text = currentText.localized
            }
        }
        get {
            return (objc_getAssociatedObject(self, &LocalizedAssociatedKeys.labelAutoKey) as? Bool) ?? false
        }
    }
}

@IBDesignable extension UIButton {
    @IBInspectable var localizeKey: String? {
        set {
            objc_setAssociatedObject(self, &LocalizedAssociatedKeys.buttonKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
            let localizedText = newValue?.localized
            setTitle(localizedText, for: .application)
            setTitle(localizedText, for: .normal)
            setTitle(localizedText, for: .focused)
            setTitle(localizedText, for: .highlighted)
            setTitle(localizedText, for: .selected)
            setTitle(localizedText, for: .reserved)
        }
        get {
            return objc_getAssociatedObject(self, &LocalizedAssociatedKeys.buttonKey) as? String
        }
    }

    @IBInspectable var autoLocalize: Bool {
        set {
            objc_setAssociatedObject(self, &LocalizedAssociatedKeys.buttonAutoKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            guard newValue else { return }
            if let localizeKey {
                setLocalizedTitle(localizeKey.localized)
            } else if let currentTitle = title(for: .normal) {
                setLocalizedTitle(currentTitle.localized)
            }
        }
        get {
            return (objc_getAssociatedObject(self, &LocalizedAssociatedKeys.buttonAutoKey) as? Bool) ?? false
        }
    }

    private func setLocalizedTitle(_ localizedText: String?) {
        setTitle(localizedText, for: .application)
        setTitle(localizedText, for: .normal)
        setTitle(localizedText, for: .focused)
        setTitle(localizedText, for: .highlighted)
        setTitle(localizedText, for: .selected)
        setTitle(localizedText, for: .reserved)
    }
}

@IBDesignable extension UITextView {
    @IBInspectable var localizeKey: String? {
        set {
            objc_setAssociatedObject(self, &LocalizedAssociatedKeys.textViewKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
            text = newValue?.localized
        }
        get {
            return objc_getAssociatedObject(self, &LocalizedAssociatedKeys.textViewKey) as? String
        }
    }

    @IBInspectable var autoLocalize: Bool {
        set {
            objc_setAssociatedObject(self, &LocalizedAssociatedKeys.textViewAutoKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            guard newValue else { return }
            if let localizeKey {
                text = localizeKey.localized
            } else if let currentText = text {
                text = currentText.localized
            }
        }
        get {
            return (objc_getAssociatedObject(self, &LocalizedAssociatedKeys.textViewAutoKey) as? Bool) ?? false
        }
    }
}
