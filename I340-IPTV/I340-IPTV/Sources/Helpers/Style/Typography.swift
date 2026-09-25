//
//  Typography.swift
//  I340_IPTV
//
//  Named type scale (Poppins family), the SwiftUI counterpart of the fonts the UIKit
//  screens create with `UIFont(name: "Poppins-...")`.
//

import SwiftUI

public enum Typography {
    public static var headlineLarge: Font { FontFamily.Poppins.bold.font(size: 32) }
    public static var headlineMedium: Font { FontFamily.Poppins.bold.font(size: 24) }
    public static var headlineSmall: Font { FontFamily.Poppins.semiBold.font(size: 22) }

    public static var subtitleLarge: Font { FontFamily.Poppins.semiBold.font(size: 20) }
    public static var subtitleMedium: Font { FontFamily.Poppins.medium.font(size: 20) }
    public static var subtitleSmall: Font { FontFamily.Poppins.semiBold.font(size: 16) }

    public static var bodyLarge: Font { FontFamily.Poppins.medium.font(size: 16) }
    public static var bodyMedium: Font { FontFamily.Poppins.regular.font(size: 16) }
    public static var bodySmall: Font { FontFamily.Poppins.regular.font(size: 14) }

    public static var labelLarge: Font { FontFamily.Poppins.semiBold.font(size: 14) }
    public static var labelMedium: Font { FontFamily.Poppins.medium.font(size: 14) }
    public static var labelSmall: Font { FontFamily.Poppins.regular.font(size: 12) }

    public static var captionLarge: Font { FontFamily.Poppins.semiBold.font(size: 12) }
    public static var captionMedium: Font { FontFamily.Poppins.medium.font(size: 12) }
    public static var captionSmall: Font { FontFamily.Poppins.medium.font(size: 10) }
}
