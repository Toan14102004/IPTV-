// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen


#if os(OSX)
  import AppKit.NSFont
#elseif os(iOS) || os(tvOS) || os(watchOS)
  import UIKit.UIFont
#endif
#if canImport(SwiftUI)
  import SwiftUI
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "FontConvertible.Font", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias SystemFont = FontConvertible.SystemFont

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Fonts

// swiftlint:disable identifier_name line_length type_body_length
internal enum FontFamily {
  internal enum Cabin {
    internal static let bold = FontConvertible(name: "Cabin-Bold", family: "Cabin", path: "Cabin-Bold.ttf")
    internal static let medium = FontConvertible(name: "Cabin-Medium", family: "Cabin", path: "Cabin-Medium.ttf")
    internal static let regular = FontConvertible(name: "Cabin-Regular", family: "Cabin", path: "Cabin-Regular.ttf")
    internal static let semiBold = FontConvertible(name: "Cabin-SemiBold", family: "Cabin", path: "Cabin-SemiBold.ttf")
    internal static let all: [FontConvertible] = [bold, medium, regular, semiBold]
  }
  internal enum GoogleSans {
    internal static let bold = FontConvertible(name: "GoogleSans-Bold", family: "Google Sans", path: "GoogleSans-Bold.ttf")
    internal static let medium = FontConvertible(name: "GoogleSans-Medium", family: "Google Sans", path: "GoogleSans-Medium.ttf")
    internal static let regular = FontConvertible(name: "GoogleSans-Regular", family: "Google Sans", path: "GoogleSans-Regular.ttf")
    internal static let all: [FontConvertible] = [bold, medium, regular]
  }
  internal enum GoogleSans17pt {
    internal static let medium = FontConvertible(name: "GoogleSans17pt-Medium", family: "Google Sans 17pt", path: "GoogleSans_17pt-Medium.ttf")
    internal static let regular = FontConvertible(name: "GoogleSans17pt-Regular", family: "Google Sans 17pt", path: "GoogleSans_17pt-Regular.ttf")
    internal static let semiBold = FontConvertible(name: "GoogleSans17pt-SemiBold", family: "Google Sans 17pt", path: "GoogleSans-SemiBold.ttf")
    internal static let all: [FontConvertible] = [medium, regular, semiBold]
  }
  internal enum Inter {
    internal static let black = FontConvertible(name: "Inter-Black", family: "Inter", path: "Inter-Black.otf")
    internal static let bold = FontConvertible(name: "Inter-Bold", family: "Inter", path: "Inter-Bold.otf")
    internal static let extraBold = FontConvertible(name: "Inter-ExtraBold", family: "Inter", path: "Inter-ExtraBold.otf")
    internal static let extraLight = FontConvertible(name: "Inter-ExtraLight", family: "Inter", path: "Inter-ExtraLight.otf")
    internal static let light = FontConvertible(name: "Inter-Light", family: "Inter", path: "Inter-Light.otf")
    internal static let medium = FontConvertible(name: "Inter-Medium", family: "Inter", path: "Inter-Medium.otf")
    internal static let regular = FontConvertible(name: "Inter-Regular", family: "Inter", path: "Inter-Regular.otf")
    internal static let semiBold = FontConvertible(name: "Inter-SemiBold", family: "Inter", path: "Inter-SemiBold.otf")
    internal static let thin = FontConvertible(name: "Inter-Thin", family: "Inter", path: "Inter-Thin.otf")
    internal static let all: [FontConvertible] = [black, bold, extraBold, extraLight, light, medium, regular, semiBold, thin]
  }
  internal enum Poppins {
    internal static let bold = FontConvertible(name: "Poppins-Bold", family: "Poppins", path: "Poppins-Bold.ttf")
    internal static let extraBold = FontConvertible(name: "Poppins-ExtraBold", family: "Poppins", path: "Poppins-ExtraBold.ttf")
    internal static let light = FontConvertible(name: "Poppins-Light", family: "Poppins", path: "Poppins-Light.ttf")
    internal static let medium = FontConvertible(name: "Poppins-Medium", family: "Poppins", path: "Poppins-Medium.ttf")
    internal static let regular = FontConvertible(name: "Poppins-Regular", family: "Poppins", path: "Poppins-Regular.ttf")
    internal static let semiBold = FontConvertible(name: "Poppins-SemiBold", family: "Poppins", path: "Poppins-SemiBold.ttf")
    internal static let all: [FontConvertible] = [bold, extraBold, light, medium, regular, semiBold]
  }
  internal enum Quantico {
    internal static let bold = FontConvertible(name: "Quantico-Bold", family: "Quantico", path: "Quantico-Bold.ttf")
    internal static let all: [FontConvertible] = [bold]
  }
  internal enum Roboto {
    internal static let bold = FontConvertible(name: "Roboto-Bold", family: "Roboto", path: "Roboto-Bold.ttf")
    internal static let medium = FontConvertible(name: "Roboto-Medium", family: "Roboto", path: "Roboto-Medium.ttf")
    internal static let regular = FontConvertible(name: "Roboto-Regular", family: "Roboto", path: "Roboto-Regular.ttf")
    internal static let semiBold = FontConvertible(name: "Roboto-SemiBold", family: "Roboto", path: "Roboto-SemiBold.ttf")
    internal static let all: [FontConvertible] = [bold, medium, regular, semiBold]
  }
  internal enum UTMBebas {
    internal static let regular = FontConvertible(name: "UTM-Bebas", family: "UTM Bebas", path: "UTM-Bebas.ttf")
    internal static let all: [FontConvertible] = [regular]
  }
  internal static let allCustomFonts: [FontConvertible] = [Cabin.all, GoogleSans.all, GoogleSans17pt.all, Inter.all, Poppins.all, Quantico.all, Roboto.all, UTMBebas.all].flatMap { $0 }
  internal static func registerAllCustomFonts() {
    allCustomFonts.forEach { $0.register() }
  }
}
// swiftlint:enable identifier_name line_length type_body_length

// MARK: - Implementation Details

internal struct FontConvertible {
  internal let name: String
  internal let family: String
  internal let path: String

  #if os(OSX)
  internal typealias SystemFont = NSFont
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias SystemFont = UIFont
  #endif

  internal func font(size: CGFloat) -> SystemFont {
    guard let font = SystemFont(font: self, size: size) else {
      fatalError("Unable to initialize font '\(name)' (\(family))")
    }
    return font
  }
  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  internal func font(size: CGFloat) -> SwiftUI.Font {
    return SwiftUI.Font.custom(self, size: size)
  }

  @available(iOS 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *)
  internal func font(fixedSize: CGFloat) -> SwiftUI.Font {
    return SwiftUI.Font.custom(self, fixedSize: fixedSize)
  }

  @available(iOS 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *)
  internal func font(size: CGFloat, relativeTo textStyle: SwiftUI.Font.TextStyle) -> SwiftUI.Font {
    return SwiftUI.Font.custom(self, size: size, relativeTo: textStyle)
  }
  #endif

  internal func textStyle(_ textStyle: Font.TextStyle) -> Font {
    Font.mappedFont(name, textStyle: textStyle)
  }

  internal func register() {
    // swiftlint:disable:next conditional_returns_on_newline
    guard let url = url else { return }
    CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
  }
  fileprivate func registerIfNeeded() {
    #if os(iOS) || os(tvOS) || os(watchOS)
    if !UIFont.fontNames(forFamilyName: family).contains(name) {
      register()
    }
    #elseif os(macOS)
    if let url = url, CTFontManagerGetScopeForURL(url as CFURL) == .none {
      register()
    }
    #endif
  }

  fileprivate var url: URL? {
    // swiftlint:disable:next implicit_return
    return BundleToken.bundle.url(forResource: path, withExtension: nil)
  }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
internal extension SwiftUI.Font {
  static func custom(_ font: FontConvertible, size: CGFloat) -> SwiftUI.Font {
    font.registerIfNeeded()
    return custom(font.name, size: size)
  }
}

@available(iOS 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *)
internal extension SwiftUI.Font {
  static func custom(_ font: FontConvertible, fixedSize: CGFloat) -> SwiftUI.Font {
    font.registerIfNeeded()
    return custom(font.name, fixedSize: fixedSize)
  }

  static func custom(
    _ font: FontConvertible,
    size: CGFloat,
    relativeTo textStyle: SwiftUI.Font.TextStyle
  ) -> SwiftUI.Font {
    font.registerIfNeeded()
    return custom(font.name, size: size, relativeTo: textStyle)
  }
}
#endif

internal extension FontConvertible.SystemFont {
  convenience init?(font: FontConvertible, size: CGFloat) {
    #if os(iOS) || os(tvOS) || os(watchOS)
    if !UIFont.fontNames(forFamilyName: font.family).contains(font.name) {
      font.register()
    }
    #elseif os(OSX)
    if let url = font.url, CTFontManagerGetScopeForURL(url as CFURL) == .none {
      font.register()
    }
    #endif

    self.init(name: font.name, size: size)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}

fileprivate extension Font {
  static func mappedFont(_ name: String, textStyle: TextStyle) -> Font {
    let fontSize = UIFont.preferredFont(forTextStyle: self.mapToUIFontTextStyle(textStyle)).pointSize
    return Font.custom(name, size: fontSize, relativeTo: textStyle)
  }

  // swiftlint:disable:next cyclomatic_complexity
  static func mapToUIFontTextStyle(_ textStyle: SwiftUI.Font.TextStyle) -> UIFont.TextStyle {
    switch textStyle {
    case .largeTitle:
      return .largeTitle
    case .title:
      return .title1
    case .title2:
      return .title2
    case .title3:
      return .title3
    case .headline:
      return .headline
    case .subheadline:
      return .subheadline
    case .callout:
      return .callout
    case .body:
      return .body
    case .caption:
      return .caption1
    case .caption2:
      return .caption2
    case .footnote:
      return .footnote
    @unknown default:
      fatalError("Missing a TextStyle mapping")
    }
  }
}

// swiftlint:enable convenience_type
