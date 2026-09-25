//
//  Language.swift
//  DogTranslator
//
//  Created by Foxcode on 07/08/2024.
//

import Foundation
import UIKit

struct Language: Identifiable, Equatable {
    var imgFlag: String
    var lbCountry: String
    var isSelected: Bool
    var languageCode: LanguageCode

    var id: String { languageCode.code }
}

enum LanguageCode {
    case system
    case english
    case japanese
    case german
    case french
    case spanish
    case arabic
    case hindi
    case portuguese
    case swahili
    case punjabi
    case bangla
    case chinese
}
extension LanguageCode {
    var code: String {
        switch self {
        case .english:
            return "en"
        case .japanese:
            return "ja"
        case .german:
            return "de"
        case .french:
            return "fr"
        case .spanish:
            return "es"
        case .arabic:
            return "ar"
        case .hindi:
            return "hi"
        case .portuguese:
            return "pt"
        case .swahili:
            return "sw"
        case .punjabi:
            return "pa"
        case .bangla:
            return "bn"
        case .chinese:
            return "zh-Hans"
        case .system:
            return Utils.getCurrenLanguageCode()
        }
    }
    
    var name: String {
        switch self {
        case .english:
            return "English"
        case .japanese:
            return "日本語"
        case .german:
            return "Deutsch"
        case .french:
            return "Français"
        case .spanish:
            return "Español"
        case .arabic:
            return "عربية"
        case .hindi:
            return "हिंदी"
        case .portuguese:
            return "Português"
        case .swahili:
            return "Kiswahili"
        case .punjabi:
            return "ਪੰਜਾਬੀ"
        case .bangla:
            return "বাংলা"
        case .chinese:
            return "中文"
        case .system:
            return "System Language"
        }
    }
}
