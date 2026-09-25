# iOS Source Base (SwiftUI)

Nền tảng iOS để clone → đổi branding/UI → phát triển app mới. Hiện tại demo bằng app IPTV
(Playlist M3U, Xtream), phần IPTV nằm gọn trong các module riêng nên có thể xoá đi.

| | |
|---|---|
| UI | SwiftUI, kiến trúc **MVVM-C** (View + ViewModel + Coordinator) |
| Điều hướng | FlowStacks (`FlowStack`, `AppNavigator`) |
| Dữ liệu | Core Data, `async/await` |
| DI | `@Injected` |
| Tối thiểu | iOS 15 |
| Tài nguyên | SwiftGen (`Asset`, `FontFamily`) |

## 1. Cài đặt và chạy

```bash
git clone <repo> && cd I340-IPTV
pod install                 # dùng I340-IPTV.xcworkspace, không mở .xcodeproj
open I340-IPTV.xcworkspace  # scheme: I340-IPTV
```

Cần: Xcode 16+, CocoaPods, SwiftGen (`brew install swiftgen`).

Sinh lại `Asset`/`FontFamily` sau khi thêm ảnh, màu hoặc font (chạy ở thư mục gốc repo hoặc trong `I340-IPTV/`):

```bash
swiftgen
```

> Nếu Xcode báo lỗi module lạ ("module file not found"): đóng Xcode, xoá
> `~/Library/Developer/Xcode/DerivedData/I340-IPTV-*`, mở lại và Build.

## 2. Đổi thành app mới (checklist)

1. **Bundle id / tên app / version:** Target → General (hoặc `PRODUCT_BUNDLE_IDENTIFIER`, `PRODUCT_NAME`, `MARKETING_VERSION`).
2. **Firebase:** thay `I340-IPTV/Resources/GoogleService-Info.plist` bằng file của app mới.
3. **Cấu hình theo môi trường:** sửa `I340-IPTV/Environments/AppDebug.xcconfig` (Debug) và `AppRelease.xcconfig` (Release). Mọi ID nằm ở đây (xem mục 3), không sửa Info.plist.
4. **Ads:** thay AdMob App ID và các Ad Unit ID trong xcconfig (mục 3). Debug mặc định dùng ID test của Google.
5. **IAP:** tạo product trong App Store Connect, điền `OneTime/IAPWeekly/IAPMonthly/IAPYearly...` và `IAPSubcriptionSecret`.
6. **Tracking:** Adjust token (`DefaultConfigToken`), AppsFlyer dev key, Facebook/TikTok app id và token trong xcconfig.
7. **Branding:** `Resources/Assets/*.xcassets` (icon app, màu `Color`, ảnh), `Resources/Fonts`, chuỗi trong `Resources/*.lproj`; chạy `swiftgen`.
8. **Xoá phần demo IPTV** nếu không cần: các module `Playlist*`, `Xtream*`, `AddPlaylist`, `Data/Services/Playlist`, `Data/Services/Persistence`, `Data/Model` (IPTV*), `Data/Services/Player` và các mục tương ứng ở `Main`.

> ⚠️ Các xcconfig đang chứa **khoá thử nghiệm** (Facebook client token, TikTok token, dev key). Thay
> bằng khoá của app thật và không commit khoá production lên repo công khai.

## 3. Cấu hình (`Environments/*.xcconfig`)

Giá trị được nạp vào Info.plist (`AppConfigs`) và đọc qua `Configs.*` / `AppConfiguration`.

| Nhóm | Khoá chính |
|---|---|
| App | `ApplicationID`, `EmailDeveloper`, `AppGroupID`, `PrivacyPolicyUrl`, `TermOfUseUrl` |
| Meta / TikTok / AppsFlyer | `FacebookAppID`, `FacebookClientToken`, `TikTokAppID`, `TikTokAccessToken`, `AppsFlyerDevKey` |
| Ads | `ADSAppID`, `ADSInterstitialAdsID`, `ADSNative*`, `ADSAppOpenAdsID`, `ADSBannerID`, `ADSRewarded*` (mỗi loại có bản `2F`/`MF` cho mediation tầng giá cao/trung bình) |
| IAP | `OneTime`, `IAPWeekly`, `IAPMonthly`, `IAPYearly`, `IAPYearlySaleOff`, `IAPMiniPackage`, `IAPSubcriptionSecret` |
| Thông báo | `EnableLocalNotification`, `TimeTriggerNotification` |

- **Công tắc build:** `Configuration/AppFlags.swift` (`adsEnabled` bật/tắt toàn bộ quảng cáo).
- **Remote Config (Firebase):** khai báo ở `Configuration/RemoteConfig/RemoteKonfig.swift`, mỗi giá trị một dòng
  `@RemoteKonfigProperty(key: "…", default: …)`; đọc bằng `RemoteKonfig.shared.<tên>`.

## 4. Cấu trúc thư mục

```
I340-IPTV/
  Environments/      xcconfig Debug / Release
  Resources/
    Assets/          Assets, Color, Icon, Image (.xcassets)
    Fonts/  *.lproj  Info.plist  GoogleService-Info.plist
  Sources/
    Application/     AppDelegate, PushNotificationsHandler, DeepLinksHandler, SystemEventsHandler, AppEnvironment, AppDependencies
    Configuration/   AppConfiguration, AppFlags, Configs*, RemoteConfig/
    Common/          Alert/Popup, FlowStacks, Logger, Types (AppError), Extensions, Protocols, PropertyWrappers
    Data/            Enum, Model, Services/
                       Ads, Analytics, Cache, IAP, Loading, LocalStorage, Network, Paywall, Persistence, Player, Playlist
    Helpers/         Style (Layout, Typography), Shape
    Injected/        AppState, DependencyInjector, @Injected
    Modules/         mỗi màn = View + ViewModel + Coordinator
    Utilities/       CancelBag, Loadable, Store, Helpers, ...
    Views/           thành phần UI dùng chung (Ads, Button, Dialog, Form, Loading, State, Toolbar, ...)
    Generated/       SwiftGen (không sửa tay)
```

## 5. Các tầng nền tảng

### Firebase
Core, Analytics, Crashlytics, Messaging, Remote Config: khởi tạo trong `SystemEventsHandler.setupFirebase()`.
Crashlytics nhận log của `Logger` (mức warning/error) làm breadcrumb.

### Ads & Mediation
AdMob + Facebook, Pangle, Mintegral, AppLovin. `AdsManager` (interstitial, app-open, rewarded, native), `NativeAdBannerView`
(SwiftUI) để nhúng native ad. Ad Unit ID lấy từ xcconfig qua `Configs.AdvertisementID`.
Debug dùng ID test của Google; bật `AdsDebugKit` bằng cử chỉ ở Splash.

### In-App Purchase
`Data/Services/IAP/IAPHelper` (StoreKit 2): tải product, mua, restore, theo dõi `Transaction.updates`, trạng thái
`isSubscribed()`. Màn `Modules/Paywall`. Mở bằng `AppNavigator.presentPaywall()`.
Mua thành công tự bắn event tracking (Adjust, Meta, TikTok, Firebase `purchase`).

### Cache & Local storage
- `UserDefaultManager` (cài đặt nhẹ) và Core Data (`Data/Services/Persistence`).
- **`CacheService`** (`@Injected var cache`): ảnh (Kingfisher, giới hạn dung lượng cấu hình ở `setupCache()`),
  URL cache, cache dữ liệu có TTL, file tạm.
  ```swift
  try cache.store(items, forKey: "featured", ttl: 3600)
  let items = cache.value([Item].self, forKey: "featured")
  await cache.totalSize(); await cache.clearAll()
  ```
  Settings → **Clear cache** gọi `clearAll()` (không đụng dữ liệu người dùng).
- Ảnh từ URL: dùng `RemoteImageView` (Kingfisher).

### Network
`NetworkService` (URLSession, async/await, retry lỗi tạm thời, log request):
```swift
enum FeedEndpoint: Endpoint {
    case list(page: Int)
    var path: String { "/feed" }
    var query: [String: String] { if case let .list(page) = self { ["page": "\(page)"] } else { [:] } }
}

@Injected var network: NetworkService
let items: [Item] = try await network.request(FeedEndpoint.list(page: 1))
```
Base URL: `Configs.Network.Base_URL`. Lỗi: `NetworkError`.
Theo dõi mạng: `NetworkOverlayManager` (hiện màn "No connection" khi mất mạng).

### Error handling
`AppError(error)` gom mọi lỗi (`NetworkError`, lỗi domain…) thành `message` cho người dùng + `isRetryable`.
```swift
catch { toast = AppError(error).message }
```

### Logging
```swift
Logger.d("debug", value)   // chỉ in ở Debug
Logger.w("warning")        // + breadcrumb Crashlytics
Logger.e("error", error)   // + breadcrumb Crashlytics
```
`Logger.isEnabled` mặc định bật ở Debug, tắt ở Release.

### Analytics & Tracking
- Firebase: `AnalyticsService.shared.log(.screenView("X"))`, `.purchase`, `.adImpression`, `.custom("name", [...])`.
  Màn hình: thêm `.trackScreen("Tên")` vào View.
- Adjust / AppsFlyer / Meta / TikTok: `EventTrackingHelper` (purchase, ad revenue, impression).
- Danh sách event: [`Docs/Analytics.md`](Docs/Analytics.md).

## 6. UI base

- **Màn mới:** tạo `Modules/<Tên>/<Tên>View.swift`, `…ViewModel.swift`, `…ViewCoordinator.swift`
  (mẫu: `Modules/Settings`). Thêm case vào `RootView.Coordinator.Navigation` (push) hoặc `FullScreen` (present),
  khai báo view trong `RootView.destination(for:)` / `fullScreen(for:)`, rồi mở bằng `AppNavigator.push(...)` / `AppNavigator.present(...)`.
- **Trạng thái:** `LoadingStateView`, `EmptyStateView`, `ErrorStateView`, `LoadableStateView` (bọc `Loadable<T>`) ở `Views/State`.
- **Loading toàn màn:** `LoadingService` (`show()` / `hide()`).
- **Thành phần chung:** `BaseView`, dialog (`ConfirmDialogView`, `RenameSheetView`, `CustomAlertView`), `toast(message:)`,
  `SearchBar`, `GradientButtonStyle`, `AnchoredActionMenu`, popup (`.popup(item:)`).
- **Style:** `Layout.Spacing.*`, `Layout.CornerRadius.*`, `Typography`, `FontFamily.*`, `Asset.*`.

## 7. Kiểm tra trước khi bàn giao

- [ ] Build Debug và Release; chạy Simulator và **thiết bị thật**.
- [ ] Firebase DebugView nhận `screen_view`, `ad_impression`, `purchase` (chạy scheme với `-FIRDebugEnabled`).
- [ ] Quảng cáo test hiển thị (banner/native/interstitial/app-open).
- [ ] IAP: mua, restore bằng Sandbox account.
- [ ] Settings → Clear cache hoạt động.
- [ ] Thay hết khoá thử nghiệm bằng khoá thật trước khi phát hành.
