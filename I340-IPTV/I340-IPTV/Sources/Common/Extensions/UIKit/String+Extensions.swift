//
//  String+Extensions.swift
//  I340_IPTV
//
//  Created by HaoLK on 03/12/2020.
//

import Foundation
import MobileCoreServices
import UIKit
import SwiftUI

extension String {
    /// - Returns: String with extra domain formatting stripped out
    func whitelistedHostname() -> String? {
        // Convert to lower case
        let input = self.lowercased
        // Trim hostname
        var hostname = input().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        // Prepend scheme if needed
        if !hostname.hasPrefix("http://") && !hostname.hasPrefix("https://") {
            hostname = "http://" + hostname
        }
        // Try to get host from URL
        hostname = URL(string: hostname)?.host ?? ""
        if hostname.count == 0 {
            hostname = self as String
            return nil
        }
        // Remove not allowed characters
        let invalidCharSet = CharacterSet(charactersIn: "\\|()[{^$*?<>")
        hostname = hostname.components(separatedBy: invalidCharSet).joined()
        
        // Remove www prefix
        hostname = hostname.replacingOccurrences(of: "www.", with: "")
        
        return hostname
    }
    
    static func className(_ aClass: AnyClass) -> String {
        return NSStringFromClass(aClass).components(separatedBy: ".").last!
    }
    
    func fileExtension() -> String {
        var fileExtension = ""
        if let name = self.components(separatedBy: "/").last {
            if let fExtension = name.components(separatedBy: ".").last, name.components(separatedBy: ".").count > 1 {
                fileExtension = "." + fExtension
            }
        }
        return fileExtension
    }
    
    func fileExtensionNotDot() -> String {
        var fileExtension = ""
        if let name = self.components(separatedBy: "/").last {
            if let fExtension = name.components(separatedBy: ".").last, name.components(separatedBy: ".").count > 1 {
                fileExtension = fExtension
            }
        }
        return fileExtension
    }
    
    func getParentPath() -> String {
        let arrSuffix = self.components(separatedBy: "/")
        var rs = ""
        for i in 0..<arrSuffix.count - 1 {
            if arrSuffix[i] != "" {
                rs += "/" + arrSuffix[i]
            }
        }
        return rs
    }
    
//    var localized: String {
//        return NSLocalizedString(self, tableName: nil, bundle: Bundle.localizedBundle(), value: "", comment: "")
//    }
    func substring(from : Int) -> String {
        let fromIndex = self.index(self.startIndex, offsetBy: from)
        return String(self[fromIndex...])
    }
    
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
}

extension String {
    
    var toUIImage: UIImage? {
        return UIImage(named: self)
    }
    
    var toUIImageTemplate: UIImage? {
        return UIImage(named: self)?.withRenderingMode(.alwaysTemplate)
    }
    
    var toUIColor: UIColor {
        if let color = UIColor(named: self) {
            return color
        } else {
            var hexWithoutSymbol: String = self
            if hexWithoutSymbol.hasPrefix("#") {
                hexWithoutSymbol = substring(from: 1)
            }
            
            let scanner = Scanner(string: hexWithoutSymbol)
            var hexInt : UInt64 = 0
            scanner.scanHexInt64(&hexInt)
            
            return UIColor(red: CGFloat((hexInt & 0xFF0000) >> 16) / 255.0,
                           green: CGFloat((hexInt & 0x00FF00) >> 8) / 255.0,
                           blue: CGFloat(hexInt & 0x0000FF) / 255.0,
                           alpha: 1)
        }
    }
    
    func toUIImage(renderingMode: UIImage.RenderingMode = .alwaysOriginal) -> UIImage? {
        return UIImage(named: self)?.withRenderingMode(renderingMode)
    }
    
    func toUIAlphaColor(alpha: CGFloat = 1.0) -> UIColor {
           // Nếu có đặt tên màu trong asset, ưu tiên lấy
           if let color = UIColor(named: self) {
               return color.withAlphaComponent(alpha)
           } else {
               var hexWithoutSymbol = self.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
               
               if hexWithoutSymbol.hasPrefix("#") {
                   hexWithoutSymbol.remove(at: hexWithoutSymbol.startIndex)
               }
               
               let scanner = Scanner(string: hexWithoutSymbol)
               var hexInt: UInt64 = 0
               scanner.scanHexInt64(&hexInt)
               
               // Lấy RGB từ hex 6 chữ số (RRGGBB)
               let r = CGFloat((hexInt & 0xFF0000) >> 16) / 255.0
               let g = CGFloat((hexInt & 0x00FF00) >> 8) / 255.0
               let b = CGFloat(hexInt & 0x0000FF) / 255.0
               
               return UIColor(red: r, green: g, blue: b, alpha: alpha)
           }
       }
    
    @available(iOS 13.0, *)
    var toColor: Color {
        let hex = self.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        return Color.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    var toUInt32: UInt32 {
        if let char = UnicodeScalar(self) {
            return char.value
        } else {
            return 0
        }
    }
    
    var toInt: Int? {
        return Int(self)
    }
    
    var toFloat: Float? {
        return Float(self)
    }
    
    var toDouble: Double? {
        return Double(self)
    }
    
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return nil }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return nil
        }
    }
    
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}
