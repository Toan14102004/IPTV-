// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif
#if canImport(SwiftUI)
  import SwiftUI
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "ColorAsset.Color", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetColorTypeAlias = ColorAsset.Color
@available(*, deprecated, renamed: "ImageAsset.Image", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetImageTypeAlias = ImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
internal enum Asset {
  internal enum Assets {
    internal static let accentColor = ColorAsset(name: "AccentColor")
  }
  internal enum Color {
    internal static let accentBlue = ColorAsset(name: "accentBlue")
    internal static let borderMuted = ColorAsset(name: "borderMuted")
    internal static let brandMaroon = ColorAsset(name: "brandMaroon")
    internal static let brandMaroonDark = ColorAsset(name: "brandMaroonDark")
    internal static let brandRed = ColorAsset(name: "brandRed")
    internal static let brandRedButton = ColorAsset(name: "brandRedButton")
    internal static let brandRedDark = ColorAsset(name: "brandRedDark")
    internal static let brandRedDeep = ColorAsset(name: "brandRedDeep")
    internal static let buttonNeutral = ColorAsset(name: "buttonNeutral")
    internal static let cardBackground = ColorAsset(name: "cardBackground")
    internal static let cardBorder = ColorAsset(name: "cardBorder")
    internal static let colorPrimaryLegacy = ColorAsset(name: "colorPrimaryLegacy")
    internal static let colorAccent = ColorAsset(name: "color_accent")
    internal static let colorBg = ColorAsset(name: "color_bg")
    internal static let colorBgNative = ColorAsset(name: "color_bg_native")
    internal static let colorBgNativeAds = ColorAsset(name: "color_bg_native_ads")
    internal static let colorBgNativeItem = ColorAsset(name: "color_bg_native_item")
    internal static let colorDawnText = ColorAsset(name: "color_dawn_text")
    internal static let colorPrimary = ColorAsset(name: "color_primary")
    internal static let colorSecondary = ColorAsset(name: "color_secondary")
    internal static let colorShadow = ColorAsset(name: "color_shadow")
    internal static let colorShadowInapp = ColorAsset(name: "color_shadow_inapp")
    internal static let colorTextAd = ColorAsset(name: "color_text_ad")
    internal static let colorTextPrimary = ColorAsset(name: "color_text_primary")
    internal static let colorTextSecondary = ColorAsset(name: "color_text_secondary")
    internal static let colorWhite = ColorAsset(name: "color_white")
    internal static let colorWhite20 = ColorAsset(name: "color_white_20")
    internal static let dialogBackground = ColorAsset(name: "dialogBackground")
    internal static let dividerBlue = ColorAsset(name: "dividerBlue")
    internal static let dividerGray = ColorAsset(name: "dividerGray")
    internal static let fieldBackground = ColorAsset(name: "fieldBackground")
    internal static let fieldBackgroundDark = ColorAsset(name: "fieldBackgroundDark")
    internal static let handleGray = ColorAsset(name: "handleGray")
    internal static let loadingDialogBackground = ColorAsset(name: "loadingDialogBackground")
    internal static let pinkAccent = ColorAsset(name: "pinkAccent")
    internal static let screenBackground = ColorAsset(name: "screenBackground")
    internal static let separator = ColorAsset(name: "separator")
    internal static let sheetBackground = ColorAsset(name: "sheetBackground")
    internal static let sheetSurface = ColorAsset(name: "sheetSurface")
    internal static let surfaceDark = ColorAsset(name: "surfaceDark")
    internal static let surfaceDarkest = ColorAsset(name: "surfaceDarkest")
    internal static let textCaption = ColorAsset(name: "textCaption")
    internal static let textGray = ColorAsset(name: "textGray")
    internal static let textOnSurface = ColorAsset(name: "textOnSurface")
    internal static let textPrimary = ColorAsset(name: "textPrimary")
    internal static let textSubtitle = ColorAsset(name: "textSubtitle")
    internal static let textTertiary = ColorAsset(name: "textTertiary")
  }
  internal enum Icon {
    internal static let icAppIcon = ImageAsset(name: "ic_app_icon")
    internal static let icArrowLeft = ImageAsset(name: "ic_arrow_left")
    internal static let icArrowRight = ImageAsset(name: "ic_arrow_right")
    internal static let icAudioBluetooth = ImageAsset(name: "ic_audio_bluetooth")
    internal static let icAudioCheck = ImageAsset(name: "ic_audio_check")
    internal static let icAudioSpeaker = ImageAsset(name: "ic_audio_speaker")
    internal static let icAudioTv = ImageAsset(name: "ic_audio_tv")
    internal static let icChannelDefault = ImageAsset(name: "ic_channel_default")
    internal static let icChannelPlayerDefault = ImageAsset(name: "ic_channel_player_default")
    internal static let icChannelPlayerHeartFilled = ImageAsset(name: "ic_channel_player_heart_filled")
    internal static let icChannelPlayerHeartOutline = ImageAsset(name: "ic_channel_player_heart_outline")
    internal static let icChannelPlayerVoice = ImageAsset(name: "ic_channel_player_voice")
    internal static let icChecked = ImageAsset(name: "ic_checked")
    internal static let icClose = ImageAsset(name: "ic_close")
    internal static let icCopy = ImageAsset(name: "ic_copy")
    internal static let icCrown = ImageAsset(name: "ic_crown")
    internal static let icDialogClose = ImageAsset(name: "ic_dialog_close")
    internal static let icDiamond = ImageAsset(name: "ic_diamond")
    internal static let icFieldClear = ImageAsset(name: "ic_field_clear")
    internal static let icFinger = ImageAsset(name: "ic_finger")
    internal static let icHeaderFavorite = ImageAsset(name: "ic_header_favorite")
    internal static let icHeaderHelp = ImageAsset(name: "ic_header_help")
    internal static let icHelpCircle = ImageAsset(name: "ic_help_circle")
    internal static let icHelpMain = ImageAsset(name: "ic_help_main")
    internal static let icImportFieldEyeClosed = ImageAsset(name: "ic_import_field_eye_closed")
    internal static let icImportFieldLink = ImageAsset(name: "ic_import_field_link")
    internal static let icImportFieldLock = ImageAsset(name: "ic_import_field_lock")
    internal static let icImportFieldName = ImageAsset(name: "ic_import_field_name")
    internal static let icImportFieldUser = ImageAsset(name: "ic_import_field_user")
    internal static let icImportFieldValid = ImageAsset(name: "ic_import_field_valid")
    internal static let icImportFolderAdd = ImageAsset(name: "ic_import_folder_add")
    internal static let icMainChipFavorite = ImageAsset(name: "ic_main_chip_favorite")
    internal static let icMainChipFile = ImageAsset(name: "ic_main_chip_file")
    internal static let icMainChipLink = ImageAsset(name: "ic_main_chip_link")
    internal static let icMainChipStream = ImageAsset(name: "ic_main_chip_stream")
    internal static let icMainTabAdd = ImageAsset(name: "ic_main_tab_add")
    internal static let icMainTabHub = ImageAsset(name: "ic_main_tab_hub")
    internal static let icMainTabPlaylist = ImageAsset(name: "ic_main_tab_playlist")
    internal static let icMainTabSetting = ImageAsset(name: "ic_main_tab_setting")
    internal static let icMainTabXtream = ImageAsset(name: "ic_main_tab_xtream")
    internal static let icMoreVertical = ImageAsset(name: "ic_more_vertical")
    internal static let icPlayerCast = ImageAsset(name: "ic_player_cast")
    internal static let icPlayerClose = ImageAsset(name: "ic_player_close")
    internal static let icPlayerForward15 = ImageAsset(name: "ic_player_forward_15")
    internal static let icPlayerFullscreen = ImageAsset(name: "ic_player_fullscreen")
    internal static let icPlayerMore = ImageAsset(name: "ic_player_more")
    internal static let icPlayerPlay = ImageAsset(name: "ic_player_play")
    internal static let icPlayerRewind15 = ImageAsset(name: "ic_player_rewind_15")
    internal static let icPlayerSmallToggle = ImageAsset(name: "ic_player_small_toggle")
    internal static let icPlayerVolume = ImageAsset(name: "ic_player_volume")
    internal static let icPlaylistChannels = ImageAsset(name: "ic_playlist_channels")
    internal static let icPlaylistDelete = ImageAsset(name: "ic_playlist_delete")
    internal static let icPlaylistFavorite = ImageAsset(name: "ic_playlist_favorite")
    internal static let icPlaylistFavoriteFilled = ImageAsset(name: "ic_playlist_favorite_filled")
    internal static let icPlaylistMenuImportDevice = ImageAsset(name: "ic_playlist_menu_import_device")
    internal static let icPlaylistMenuImportUrl = ImageAsset(name: "ic_playlist_menu_import_url")
    internal static let icPlaylistMenuSingleStream = ImageAsset(name: "ic_playlist_menu_single_stream")
    internal static let icPlaylistMenuXtreamApi = ImageAsset(name: "ic_playlist_menu_xtream_api")
    internal static let icPlaylistSearch = ImageAsset(name: "ic_playlist_search")
    internal static let icPlaylistSectionPlaylist = ImageAsset(name: "ic_playlist_section_playlist")
    internal static let icPlaylistSectionVideos = ImageAsset(name: "ic_playlist_section_videos")
    internal static let icPlaylistSeeAll = ImageAsset(name: "ic_playlist_see_all")
    internal static let icPlus = ImageAsset(name: "ic_plus")
    internal static let icPremiumMain = ImageAsset(name: "ic_premium_main")
    internal static let icReload = ImageAsset(name: "ic_reload")
    internal static let icRoomClear = ImageAsset(name: "ic_room_clear")
    internal static let icRoomHistory = ImageAsset(name: "ic_room_history")
    internal static let icRoomInvite = ImageAsset(name: "ic_room_invite")
    internal static let icRoomLeave = ImageAsset(name: "ic_room_leave")
    internal static let icRoomShare = ImageAsset(name: "ic_room_share")
    internal static let icSetting = ImageAsset(name: "ic_setting")
    internal static let icSettingsChevron = ImageAsset(name: "ic_settings_chevron")
    internal static let icSettingsContact = ImageAsset(name: "ic_settings_contact")
    internal static let icSettingsLanguage = ImageAsset(name: "ic_settings_language")
    internal static let icSettingsPrivacy = ImageAsset(name: "ic_settings_privacy")
    internal static let icSettingsRate = ImageAsset(name: "ic_settings_rate")
    internal static let icSettingsShare = ImageAsset(name: "ic_settings_share")
    internal static let icSettingsTerms = ImageAsset(name: "ic_settings_terms")
    internal static let icShieldDone = ImageAsset(name: "ic_shield_done")
    internal static let icToastSuccess = ImageAsset(name: "ic_toast_success")
    internal static let iconNoConnection = ImageAsset(name: "icon_no_connection")
    internal static let imgPlaylistEmpty = ImageAsset(name: "img_playlist_empty")
    internal enum Language {
      internal static let flagArabic = ImageAsset(name: "flag_arabic")
      internal static let flagBangla = ImageAsset(name: "flag_bangla")
      internal static let flagChinese = ImageAsset(name: "flag_chinese")
      internal static let flagEnglish = ImageAsset(name: "flag_english")
      internal static let flagFrench = ImageAsset(name: "flag_french")
      internal static let flagGerman = ImageAsset(name: "flag_german")
      internal static let flagHindi = ImageAsset(name: "flag_hindi")
      internal static let flagJapanese = ImageAsset(name: "flag_japanese")
      internal static let flagPortuguese = ImageAsset(name: "flag_portuguese")
      internal static let flagPunjabi = ImageAsset(name: "flag_punjabi")
      internal static let flagSpanish = ImageAsset(name: "flag_spanish")
      internal static let flagSwahili = ImageAsset(name: "flag_swahili")
    }
    internal enum Onboard {
      internal static let imgOnboardFirst = ImageAsset(name: "img_onboard_first")
      internal static let imgOnboardSecond = ImageAsset(name: "img_onboard_second")
      internal static let imgOnboardThird = ImageAsset(name: "img_onboard_third")
    }
  }
  internal enum Image {
    internal static let avatarDuck1 = ImageAsset(name: "avatar_duck_1")
    internal static let avatarDuck2 = ImageAsset(name: "avatar_duck_2")
    internal static let avatarDuck3 = ImageAsset(name: "avatar_duck_3")
    internal static let avatarDuck4 = ImageAsset(name: "avatar_duck_4")
    internal static let avatarDuck5 = ImageAsset(name: "avatar_duck_5")
    internal static let avatarDuck6 = ImageAsset(name: "avatar_duck_6")
    internal static let avatarDuck7 = ImageAsset(name: "avatar_duck_7")
    internal static let avatarDuck8 = ImageAsset(name: "avatar_duck_8")
    internal static let avatarXtream1 = ImageAsset(name: "avatar_xtream_1")
    internal static let avatarXtream2 = ImageAsset(name: "avatar_xtream_2")
    internal static let avatarXtream3 = ImageAsset(name: "avatar_xtream_3")
    internal static let avatarXtream4 = ImageAsset(name: "avatar_xtream_4")
    internal static let imgAvatarAmber = ImageAsset(name: "img_avatar_amber")
    internal static let imgAvatarBlue = ImageAsset(name: "img_avatar_blue")
    internal static let imgAvatarCheck = ImageAsset(name: "img_avatar_check")
    internal static let imgAvatarCyan = ImageAsset(name: "img_avatar_cyan")
    internal static let imgAvatarGreen = ImageAsset(name: "img_avatar_green")
    internal static let imgAvatarMagenta = ImageAsset(name: "img_avatar_magenta")
    internal static let imgAvatarOrange = ImageAsset(name: "img_avatar_orange")
    internal static let imgAvatarPink = ImageAsset(name: "img_avatar_pink")
    internal static let imgChannelUnavailable = ImageAsset(name: "img_channel_unavailable")
    internal static let imgDeleteChannel = ImageAsset(name: "img_delete_channel")
    internal static let imgGetStartedBg = ImageAsset(name: "img_get_started_bg")
    internal static let imgGetStartedPhone = ImageAsset(name: "img_get_started_phone")
    internal static let imgGuideStep1 = ImageAsset(name: "img_guide_step_1")
    internal static let imgGuideStep2 = ImageAsset(name: "img_guide_step_2")
    internal static let imgHostCrown = ImageAsset(name: "img_host_crown")
    internal static let imgImportFile = ImageAsset(name: "img_import_file")
    internal static let imgImportM3u = ImageAsset(name: "img_import_m3u")
    internal static let imgImportStream = ImageAsset(name: "img_import_stream")
    internal static let imgImportValidMark = ImageAsset(name: "img_import_valid_mark")
    internal static let imgImportXtream = ImageAsset(name: "img_import_xtream")
    internal static let imgInappHero = ImageAsset(name: "img_inapp_hero")
    internal static let imgInvalidSource = ImageAsset(name: "img_invalid_source")
    internal static let imgLeaveRoom = ImageAsset(name: "img_leave_room")
    internal static let imgPlaylistEmptyTitle = ImageAsset(name: "img_playlist_empty_title")
    internal static let imgPlaylistItem = ImageAsset(name: "img_playlist_item")
    internal static let imgRoomEmptyPeople = ImageAsset(name: "img_room_empty_people")
    internal static let imgRoomJoinOff = ImageAsset(name: "img_room_join_off")
    internal static let imgRoomJoinOn = ImageAsset(name: "img_room_join_on")
    internal static let imgRoomOops = ImageAsset(name: "img_room_oops")
    internal static let imgSettingsPremiumBanner = ImageAsset(name: "img_settings_premium_banner")
    internal static let imgWatchTogetherAvatars = ImageAsset(name: "img_watch_together_avatars")
    internal static let imgXtreamBanner = ImageAsset(name: "img_xtream_banner")
    internal static let imgXtreamBanner2 = ImageAsset(name: "img_xtream_banner_2")
    internal static let imgXtreamBanner3 = ImageAsset(name: "img_xtream_banner_3")
    internal static let imgXtreamCameraBadge = ImageAsset(name: "img_xtream_camera_badge")
    internal static let imgXtreamEmptyTitle = ImageAsset(name: "img_xtream_empty_title")
    internal static let imgXtreamItem = ImageAsset(name: "img_xtream_item")
    internal enum Movies {
      internal static let icAgreementSelect = ImageAsset(name: "ic_agreement_select")
      internal static let icAgreementUnselect = ImageAsset(name: "ic_agreement_unselect")
      internal static let icBackXtream = ImageAsset(name: "ic_back_xtream")
      internal static let icFailedAddXtream = ImageAsset(name: "ic_failed_add_xtream")
      internal static let icFullScreenXtream = ImageAsset(name: "ic_full_screen_xtream")
      internal static let icLockXtream = ImageAsset(name: "ic_lock_xtream")
      internal static let icPasswordXtream = ImageAsset(name: "ic_password_xtream")
      internal static let icPasswordXtreamOpen = ImageAsset(name: "ic_password_xtream_open")
    }
  }
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

internal final class ColorAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Color = NSColor
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Color = UIColor
  #endif

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  internal private(set) lazy var uiColor: Color = {
    guard let color = Color(asset: self) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }()

  #if os(iOS) || os(tvOS)
  @available(iOS 11.0, tvOS 11.0, *)
  internal func color(compatibleWith traitCollection: UITraitCollection) -> Color {
    let bundle = BundleToken.bundle
    guard let color = Color(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }
  #endif

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  internal private(set) lazy var color: SwiftUI.Color = {
    SwiftUI.Color(asset: self)
  }()
  #endif

  fileprivate init(name: String) {
    self.name = name
  }
}

internal extension ColorAsset.Color {
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  convenience init?(asset: ColorAsset) {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSColor.Name(asset.name), bundle: bundle)
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
internal extension SwiftUI.Color {
  init(asset: ColorAsset) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle)
  }
}
#endif

internal struct ImageAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Image = UIImage
  #endif

  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, macOS 10.7, *)
  internal var uiImage: Image {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let name = NSImage.Name(self.name)
    let image = (bundle == .main) ? NSImage(named: name) : bundle.image(forResource: name)
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }

  #if os(iOS) || os(tvOS)
  @available(iOS 8.0, tvOS 9.0, *)
  internal func image(compatibleWith traitCollection: UITraitCollection) -> Image {
    let bundle = BundleToken.bundle
    guard let result = Image(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }
  #endif

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  internal var image: SwiftUI.Image {
    SwiftUI.Image(asset: self)
  }
  #endif
}

internal extension ImageAsset.Image {
  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, *)
  @available(macOS, deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  convenience init?(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = BundleToken.bundle
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
internal extension SwiftUI.Image {
  init(asset: ImageAsset) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle)
  }

  init(asset: ImageAsset, label: Text) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle, label: label)
  }

  init(decorative asset: ImageAsset) {
    let bundle = BundleToken.bundle
    self.init(decorative: asset.name, bundle: bundle)
  }
}
#endif

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
// swiftlint:enable convenience_type
