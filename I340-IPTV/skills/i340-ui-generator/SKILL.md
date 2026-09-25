---
name: i340-ui-generator
description: Generate or update I340-IPTV UIKit screens, XIB layouts, cells, custom views, assets, and localized strings from Figma links, screenshots, or UI descriptions. Use when implementing app UI in this repository, especially ViewControllers under I340-IPTV/ViewControllers.
metadata:
  short-description: Generate I340 IPTV UIKit/XIB UI
---

# I340 UI Generator

Use this skill when the user asks to generate, rebuild, or polish UI in the I340-IPTV app from a Figma node, screenshot, reference project, or written design.

## First Read

1. Read `AGENTS.md` at the repository root.
2. Read the target feature files:
   - `<Feature>VC.swift`
   - `<Feature>VC.xib`
   - related cells, custom views, view model, assets, and localized keys.
   - For tab content under Main, read `MainVC`, `MainTabBarView`, then the tab screen folder such as `PlaylistVC` or `XstreamVC`.
3. Search neighboring implementations before inventing patterns:
   - `rg --files I340-IPTV/ViewControllers/<Feature>`
   - `rg -n "setupView|setupAction|registerCell|localized|RemoteKonfig|AdsManager" I340-IPTV/ViewControllers`

## Input Handling

- For a Figma URL, fetch design context/screenshot if Figma tools are available. Extract dimensions, hierarchy, spacing, colors, typography, assets, and variant states.
- For a screenshot, visually inspect layout before editing. Match the visible screen first, then make it responsive.
- For a reference project path, read the sample screen and port the flow/style using this app's existing base classes and resources.

## Implementation Rules

- Prefer UIKit + XIB. Keep Swift and XIB paired by name.
- For Swift or config file headers, use `Created by Nguyen Dao Hung ...`; if a file still has the Xcode template author `___VARIABLE_organizationName___`, replace only that author with `Nguyen Dao Hung` and preserve the existing date.
- New view controller classes must inherit from `BaseVC`. Do not create new screen VCs that inherit directly from `UIViewController` or native-ad base classes.
- If a new `BaseVC` screen needs native ads, keep the VC on `BaseVC` and override `loadNativeBannerAds()` / `loadNativeListAds()` as needed using the existing ad views and `AdsManager` helpers.
- Keep screen controllers lean:
  - `viewDidLoad()`
  - `setupView()`
  - `setupAction()`
  - small feature-specific setup methods.
- Prefer `private let viewModel = FeatureVM()` unless the screen has an existing injection flow.
- Avoid implicitly unwrapped view model properties.
- Use private IBOutlets where possible.
- Use `BaseVC`, `BaseVM`, `BaseCollectionViewCell`, and `BaseTableViewCell` patterns.
- Use existing helpers:
  - `tableView.registerCellNib(Cell.self)`
  - `collectionView.registerCell(ofType: Cell.self)`
  - `Cell.identifier`
- Repeated UI items should be data-driven with an enum or model plus collection/table view. Do not add many fixed buttons when the list may grow.
- Keep reusable component UI in a custom view/cell when it improves clarity, following `MainTabBarView` and `MainOptionCell`.

## Main Tab Pattern

- Treat `MainVC` as a shell/container only.
- Keep `MainVC.swift` and `MainVC.xib` focused on:
  - `contentContainerView`
  - embedding/removing child view controllers
  - `MainTabBarView`
  - forwarding add actions through `MainTabContent.handleAddTapped()`
- Keep tab content as separate feature folders:
  - `I340-IPTV/ViewControllers/PlaylistVC/PlaylistVC.swift`
  - `I340-IPTV/ViewControllers/PlaylistVC/PlaylistVC.xib`
  - `I340-IPTV/ViewControllers/PlaylistVC/Cell/`
  - `I340-IPTV/ViewControllers/XstreamVC/XstreamVC.swift`
  - `I340-IPTV/ViewControllers/XstreamVC/XstreamVC.xib`
- Do not put playlist or Xtream-specific UI back into `MainVC`.
- Child tab screens embedded in `MainVC` should also inherit from `BaseVC`.
- Keep `MainTabBarView` in `I340-IPTV/ViewControllers/MainVC/` because it belongs to the shell.

## XIB Rules

- Keep constraints explicit and stable across iPhone sizes.
- Use safe area or fixed bottom constraints deliberately for bottom controls.
- Avoid ambiguous constraints, nested card-like containers, and text that can overflow.
- For dynamic labels/buttons, set line count, truncation/scaling, or fixed height as needed.
- Use collection/table views for horizontally scrollable options, repeated cards, language lists, products, and tab-like chips.
- Validate edited XIB files with:

```sh
xmllint --noout path/to/File.xib
```

## Visual Style

- Match the app's dark IPTV style: black/dark backgrounds, red primary accents, Poppins/GoogleSans/Inter fonts, restrained controls.
- Use `UIColor(hex:)` or existing color assets.
- Match Figma spacing and hierarchy, but favor robust Auto Layout over fragile absolute placement.
- Use asset catalog images from `I340-IPTV/Assets.xcassets`.
- For icon buttons, prefer image-only buttons with correct rendering mode:
  - `.alwaysTemplate` when tinted in code.
  - `.alwaysOriginal` when the asset carries final color.

## Localization

- Every user-facing string must use `"key".localized` or XIB `localizeKey`.
- Add new keys to every `I340-IPTV/Resources/*.lproj/Localizable.strings`.
- Use short, stable keys grouped by screen, for example `main_playlist_url`, `get_start_title`, `splash_welcome`.
- In code, provide fallback only when guarding incomplete localization during development.

## Flow And Ads

- Preserve the current launch flow:
  `SplashVC -> GetStartVC -> LanguageVC/OnBoardVC -> MainVC`.
- Do not add `isCompletedOnboarding`.
- Respect `IAPHelper.shared().isSubscribed()` before showing ad UI or loading ads.
- Use existing `AdsManager`, `RemoteKonfig`, and `Configs.AdvertisementID` patterns.

## Asset Checklist

When adding assets:

1. Place icons under `I340-IPTV/Assets.xcassets/Icons/<name>.imageset`.
2. Add `Contents.json` with correct filename references.
3. Use consistent names such as `ic_<screen>_<purpose>` or `img_<screen>_<purpose>`.
4. Verify the Swift/XIB uses the exact asset name.

## Validation Checklist

Before finishing:

1. `rg` for removed outlets, obsolete asset names, and old hardcoded strings.
2. `xmllint --noout` on edited XIBs.
3. Build:

```sh
xcodebuild -workspace I340-IPTV.xcworkspace -scheme I340-IPTV -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
```

4. If the UI changed significantly, run the screen in Simulator when practical and inspect for clipping/overlap.

## Final Response

Summarize only the meaningful changes:

- screens/components touched
- new assets/localized keys
- validation run and result
- any remaining UI risk if Simulator inspection was not possible
