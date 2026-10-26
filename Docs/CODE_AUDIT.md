# Code audit — I361 IPTV Player

Đối chiếu source với bản review của `iptv-ai-navigator` (`CODE_REVIEW.md` + `METADATA_v1.0.md`, 20/10/2026).
Nhánh `develop`. Audit lần đầu 22/10/2026, đã sửa trong cùng ngày.

**Trạng thái build:** Debug `BUILD SUCCEEDED` (exit 0) sau mọi thay đổi. Release **bị chặn có chủ đích** bởi Release Preflight cho tới khi có ID thật.

**Đã chạy thật trên simulator** (iPhone 17, iOS 26.5) — không chỉ compile. Chi tiết ở mục 5.

---

## Tiến độ

| Nhóm | Xong | Còn lại |
|---|---|---|
| P0 — chặn submit | 2 / 6 | 4 (đều **chờ ID từ PM**) |
| P1 — chức năng & policy | 8 / 8 | 0 |
| P2 — dọn dẹp | 3 / 6 | 3 |
| **Code do dev làm được** | **13 / 13** | **0** |

> Toàn bộ việc không cần ID thật đã xong. Phần còn lại chỉ chờ PM cấp thông tin, và
> Release Preflight sẽ không cho archive tới khi điền đủ.

---

## 0. Resume ad — ĐÃ CHỐT (23/10/2026): quay lại Interstitial như bản gốc

**Quyết định cuối cùng:** user confirm dùng **Interstitial**, không dùng App Open, ở vị trí
app-resume (`AdsManager.applicationWillEnterForeground`). Đã revert `AdsManager.swift` về
**y hệt byte-for-byte** bản commit gốc (`git diff` rỗng) — bỏ hẳn `appOpenAdUtils.showAdIfAvailable`
và dòng preload `appOpenAdUtils.loadAd()`, quay lại `showInter2FIfAvailable` → `backgroundInterstitialUtils.showAd`.
`var appOpenAdUtils` / gán `AppOpenAdUtils.shared` vẫn còn (hạ tầng có sẵn từ trước, không dùng tới
nhưng không cần xoá). Build pass.

**3 chỗ `.suppressesAppOpenAd()` tôi từng thêm rồi xoá** (`WatchRoomView`, `PlayVideoView`,
`PlaylistPlayerView`) — **đã xoá theo yêu cầu user**, không còn trong code. Nghĩa là Interstitial ở
vị trí resume **vẫn có thể hiện đè lên màn đang phát video/phòng Watch Together** — đây là lựa chọn
có chủ đích của user (ưu tiên doanh thu hơn tránh gián đoạn), đã nêu rủi ro trước khi xoá.

**Lưu ý quan trọng cho lần sau:** hiện tượng ban đầu khiến user nghi ngờ ("Animax Asia India" bị
quảng cáo che) **đã xác minh KHÔNG phải do App Open ad hay Interstitial** —
`AdsBackgroundWindowManager`'s window full-screen, không khớp ảnh chụp (header + Watch Together card
vẫn thấy rõ xung quanh "ad"). Nhiều khả năng là do chính IPTV panel tự chèn quảng cáo vào luồng
stream. Nếu lỗi tương tự lặp lại, đừng vội đổ cho resume-ad — kiểm tra stream nguồn trước.

**Không liên quan:** `GradientButton.swift` + 3 file `.xib` sửa nút INSTALL native ads — độc lập
hoàn toàn với quyết định này, không bị đụng tới trong lần revert.

---

## 1. Việc ĐÃ LÀM

### 1.1 Gỡ backdoor mã premium — P0 ✅

**Đây là lỗi nặng nhất, giống hệt app của đồng nghiệp.**

Paywall có gesture ẩn: long-press vào tiêu đề → hiện dialog "Enter Premium Code" → nhập `132978`
là được premium tới `3000-01-01`, bỏ qua hoàn toàn StoreKit.

```swift
// PaywallViewModel.swift (ĐÃ XOÁ)
func submitVoucher(_ code: String) {
    if code == "132978" {
        IAPHelper.shared().memberShipStatus = true
        IAPHelper.shared().memberShipExpiredDay = "3000-01-01 00:00"
    }
}
```

Đã xoá: `didLongPressTitle()`, `submitVoucher()`, `VoucherPromptView`, 2 `onLongPressGesture`,
`Alert.voucher`, và 3 chuỗi dịch (`iap_enter_premium_code`, `iap_premium_code_success`,
`iap_premium_code_error`) ở **cả 16 ngôn ngữ**.

Kiểm chứng: grep `voucher|premium_code|132978` → 0 kết quả. `memberShipStatus` giờ chỉ còn
**một** nơi ghi là `IAPHelper.refreshEntitlements()`, tức chỉ StoreKit mới cấp được premium.

> Ghi chú trung thực: audit lần đầu của tôi **báo nhầm là app không dính lỗi này**, vì tôi grep
> theo tên biến của app kia (`isActivateByCode`). Phát hiện ra khi đọc code paywall để làm việc khác.

### 1.2 Release Preflight — P0 ✅

Thêm `I340-IPTV/Scripts/release_preflight.sh` + build phase **"Release Preflight"** (chạy trước
Compile Sources). Debug bỏ qua; Release fail build khi:

1. `AppRelease.xcconfig` còn `__SET_ME__` → **in ra đúng tên từng key còn thiếu**
2. Còn ad unit test của Google (`ca-app-pub-3940256099942544`)
3. Còn IAP product `com.test.*`
4. `ApplicationID = id0000000000` / `EmailDeveloper = your-email@example.com`
5. `IAPSubcriptionSecret` rỗng
6. `PRODUCT_BUNDLE_IDENTIFIER` là bundle test
7. `GoogleService-Info.plist` BUNDLE_ID ≠ bundle ID của target
8. Thiếu `ITSAppUsesNonExemptEncryption`
9. Adjust app token rỗng

Kiểm chứng thực tế:

```
Debug   → DEBUG_EXIT=0        (build bình thường)
Release → RELEASE_EXIT=65     (bị chặn, in rõ lý do)
```

Đồng thời tách `AppRelease.xcconfig` khỏi `AppDebug.xcconfig` (trước đây **giống hệt nhau 100%**):
Debug giữ ID test, Release toàn bộ `__SET_ME__`. Đã verify hai file có **cùng bộ key**, không thiếu key nào.

### 1.3 AVAudioSession — P1 ✅

`PlayerController` trước đây chỉ gọi `setActive(true)`, **không hề set category** → bật công tắc
im lặng là kênh mất tiếng.

```swift
// PlayerController.swift — thêm mới, gọi trong init()
private func configureAudioSession() {
    let session = AVAudioSession.sharedInstance()
    do {
        try session.setCategory(.playback, mode: .moviePlayback)
    } catch {
        print("[Player] Audio session category failed: \(error)")
    }
}
```

### 1.4 Interstitial on resume → App Open — P1 ✅

Vi phạm policy AdMob: slot app-resume chỉ được dùng format App Open.

```swift
// AdsManager.applicationWillEnterForeground() — TRƯỚC
if showInter2FIfAvailable(...) { return }
backgroundInterstitialUtils.showAd(from: rootViewController, isComeback: true, ...)

// SAU
appOpenAdUtils.showAdIfAvailable(viewController: rootViewController)
```

Thêm `appOpenAdUtils.loadAd()` vào `initializeMobileAdsSdk` để preload. Lưu ý: `AppOpenAdUtils`
đã tồn tại sẵn trong base nhưng **chưa từng được gọi show** — app trước giờ không hề hiển thị App Open ad.

### 1.5 Mật khẩu Xtream → Keychain — P1 ✅

Trước: password nằm plaintext trong `playlist.url` (`?password=...`) lưu ở Core Data → vào iCloud/iTunes backup.

Thêm `Data/Services/Persistence/XtreamCredentialStore.swift` — Keychain wrapper dùng
`kSecAttrAccessibleWhenUnlockedThisDeviceOnly` (ThisDeviceOnly = **không vào backup**).

`XtreamProfilePayload` giờ ghi `pwref=<uuid>` thay cho `password`; `decode` đọc Keychain qua ref và
**vẫn fallback đọc `password` cũ** nên profile user đã lưu từ bản trước vẫn chạy bình thường.
`deletePlaylist` xoá luôn Keychain item để không để lại rác.

### 1.6 Gỡ AppsFlyer + PurchaseConnector — P1 ✅

Lý do: app kia bị yêu cầu gỡ, và theo chuẩn tracking của team **Adjust là MMP + SKAN writer duy nhất** —
AppsFlyer chạy song song sẽ tranh ghi SKAN conversion value làm sai số liệu cả hai bên.

Đã gỡ: 2 pod, `appFlyersConfigs()`, `import AppsFlyerLib`, file `DeepLinksHandler.swift` (chỉ phục vụ
AppsFlyer), extension `PurchaseConnector` trong `SystemEventsHandler`, `Configs.AppsFlyer`,
`AppConfiguration.appsFlyerDevKey()`, key `AppsFlyer` trong Info.plist và cả 2 xcconfig.

`pod install` → *Removing AppsFlyerFramework / Removing PurchaseConnector*, còn 25 dependency.

### 1.7 Export compliance + ATS — P1 ✅

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key><true/>
    <key>NSAllowsArbitraryLoadsForMedia</key><true/>
</dict>
```

**Lưu ý thành thật về ATS:** `NSAllowsArbitraryLoads` vẫn phải để `true`, không thu hẹp hết được —
app IPTV cho user dán URL http cho **cả playlist (URLSession) lẫn stream (AVFoundation)**. Đã thêm
`NSAllowsArbitraryLoadsForMedia` để ghi rõ ý định. Cần **giải trình trong App Review Notes**:
app là player cho nguồn do user tự nhập, nhiều nhà cung cấp IPTV chỉ phát http.

### 1.8 Event Firebase cho funnel — P1 ✅

Đính chính: audit lần đầu tôi viết "gần như chưa log event nào" là **sai** — tôi grep literal
`Analytics.logEvent` nên chỉ thấy 1 chỗ (bên trong `AnalyticsService`). Thực tế đã có
`screen_view` (15 màn), `purchase`, `restore_purchase`, `ad_impression`, `import_playlist`.

Cái thật sự thiếu là khúc giữa funnel. Đã bổ sung:

| Event | Tham số | Nơi gửi |
|---|---|---|
| `playback_start` | `source` | `PlaylistPlayerView.ViewModel` |
| `paywall_cta` | `item_id` | `PaywallView.ViewModel` |
| `room_create` | — | `RoomService.createRoom` |
| `room_join` | — | `RoomService.joinRoom` |

Đã cập nhật `Docs/Analytics.md` theo đúng quy ước sẵn có của project.

### 1.9 Quyền lợi premium viết cho IPTV — P0 ✅ (phần copy)

`InfoPremium0..2` trong Release: "Remove All Ads / Unlimited Features / Premium Support" (template chung chung,
dễ dính Apple 2.3.1) → đổi thành:

```
InfoPremium0 = Remove all ads
InfoPremium1 = Unlimited playlists and streams
InfoPremium2 = Unlimited watch time, no 10-minute limit
```

Ghi chú: paywall SwiftUI thực tế đọc chuỗi localize `inapp_feature_playlists` / `inapp_feature_playback`
("Enjoy Unlimited Playlists & Streams", "Unlock Advanced Playback Features") — vốn đã đúng tinh thần IPTV.
`InfoPremium*` là đường cũ của base. **Cần PM chốt lại wording cuối** cho khớp quyền lợi thật khi có IAP.

### 1.10 Dọn code chết nguy hiểm — P2 ✅

- `Configs.Network.AES_SECRET` + `AES_IV` — placeholder, 0 nơi dùng → xoá.
- `UserDefaultManager`: `email`, `password`, `userId`, `enableCheat` — **0 call site**, là tàn dư
  template lưu credential vào UserDefaults, tên `enableCheat` lại dễ bị hiểu nhầm khi review → xoá cả 4.

---

## 2. Việc CÒN LẠI

### 2.1 Chờ PM cấp thông tin — P0 ⬜

Release Preflight đã in sẵn danh sách key. **Gửi nguyên danh sách này cho PM:**

| # | Cần gì | Key trong `AppRelease.xcconfig` |
|---|---|---|
| ⬜ B1 | Bundle ID thật + app record ASC | `PRODUCT_BUNDLE_IDENTIFIER` (trong project) |
| ⬜ B2 | Firebase app mới khớp bundle ID | thay `GoogleService-Info.plist` |
| ⬜ B3 | AdMob app ID + 24 ad unit thật | `ADSAppID`, `ADSInterstitial*`, `ADSNative*`, `ADSAppOpenAdsID`, `ADSBannerID`, `ADSRewardedVideoAds*` |
| ⬜ B4 | 6 IAP product ID + App-Specific Shared Secret | `OneTime`, `IAPWeekly`, `IAPYearly`, `IAPMonthly`, `IAPYearlySaleOff`, `IAPMiniPackage`, `IAPSubcriptionSecret` |
| ⬜ B5 | Apple App ID, email hỗ trợ, App Group, Privacy/Terms/Refund URL | `ApplicationID`, `EmailDeveloper`, `AppGroupID`, `PrivacyPolicyUrl`, `TermOfUseUrl`, `RefundUrl` |
| ⬜ B6 | Meta + TikTok app ID/token của **app này** | `FacebookAppID`, `FacebookClientToken`, `FBAPPID`, `TikTokAppID`, `TikTokAccessToken` |
| ⬜ B7 | Xác nhận Adjust app token `ha6eamv6p69s` đúng app này | `DefaultConfigToken.swift` |

### Event token Adjust — chờ marketing, không phải blocker

**Quyết định (22/10/2026):** chỉ thêm token cho event nào marketing yêu cầu, không tạo trước.

Trạng thái hiện tại — **wiring đã xong hết, không cần code thêm**, chỉ điền token là chạy:

| Đang gửi được ngay (không cần event token) | Đích |
|---|---|
| Ad revenue qua `ADJAdRevenue` → `Adjust.trackAdRevenue()` | Adjust |
| `ad_impression` | Firebase |
| Ad revenue qua `logPurchase` | Meta |
| `TikTokAdRevenueEvent` | TikTok |

`paidEventHandler` đã gắn active cho **đủ 7 format**: banner, interstitial, native đơn, native list,
app open, rewarded (×2). (`RewardedAdManager.swift` có chỗ comment nhưng đó là file legacy đã comment
toàn bộ — bản đang dùng là `RewardedAdHandler.swift`.)

14 token rỗng → `logEventAdjustWithKey` có `guard !token.rawValue.isEmpty else { return }` nên
**bỏ qua an toàn, không crash, không gửi rác**:

- Impression đếm lượt: banner, inter, native, open ad
- Click: banner, inter, native, open ad
- Vòng đời: `first_open`, `ad_revenue` (event phụ), `free_trial_predict`
- Mua hàng: **`onetime`**, `mini`, `restore`

⚠️ Lưu ý khi làm IAP: weekly / monthly / yearly **có** token, nhưng **`onetime` và `mini` thì không**.
Nếu gói onetime là sản phẩm chính thì doanh thu đó sẽ không về Adjust dưới dạng event mua.
Liên quan trực tiếp tới việc cần re-check IAP onetime trước release.

Release Preflight **chỉ chặn `adjustToken` (app token)**, không chặn 14 event token — nên việc
để trống không làm vướng build Release.

### 2.2 Dọn dẹp còn lại — P2 ⬜

| # | Việc | Ghi chú |
|---|---|---|
| ⬜ | ~146 `print()` trong Ads/Analytics | Nên thay bằng `Logger.d` để Release im lặng |
| ⬜ | Header comment còn `I340_IPTV`, `Created by Foxcode` | Không ảnh hưởng binary |
| ⬜ | `SearchAdsTrackingDomain = appletracking.fuentechsoft.com` | Domain vendor khác — xác nhận với PM còn dùng không |

### 2.3 Metadata & QA trước nộp — ⬜

| # | Việc |
|---|---|
| ⬜ | Playlist test hợp pháp cho reviewer (Apple BipBop + Mux), host trên domain mình |
| ⬜ | Review Notes: nêu rõ app là player, **không kèm kênh nào**; giải trình ATS http |
| ⬜ | Chạy full luồng trên iPad + screenshot iPhone 6.9" & iPad 13" |
| ⬜ | App Privacy: khai AdMob, Adjust, Firebase, Meta, TikTok |
| ⬜ | Age rating 18+ (user tự nạp stream) |
| ⬜ | Commit working tree (đang ~314 file), tách commit theo nhóm |

---

## 3. Các lỗi app kia bị — app này KHÔNG bị

Đã verify lại lần hai sau khi phát hiện sót mục voucher.

| Lỗi trong `CODE_REVIEW.md` | Bằng chứng |
|---|---|
| `isPurchased` gán cứng `true` | Không có chỗ nào hardcode |
| `validateReceipt` thiếu `return`, `catch {}` nuốt lỗi | `IAPHelper.swift:188` có `guard ... else { ...; return }`; catch có gọi completion |
| Subscription hết hạn vẫn premium | `setupIAP()` → `refreshEntitlements()` + `Transaction.updates` listener |
| Cấp lifetime cho giao dịch đã refund | `refreshEntitlements()` check `transaction.revocationDate == nil` |
| Paywall không có đường vào | ~15 entry point |
| Không có nút Restore | `PaywallView.swift:202` |
| Tên kênh có dấu phẩy bị cắt | `M3UPlaylistParser` dùng `firstCommaOutsideQuotes()` |
| ID kênh trùng | `IPTVChannel` dùng `UUID().uuidString` |
| Xin quyền Location/Motion/Contacts thừa | Info.plist chỉ có `NSUserTrackingUsageDescription` |
| Hỏi Local Network mỗi lần foreground | Không có |
| Code chết template (Workout/Achievement/Multipeer…) | Không có |
| Ảnh onboarding có poster phim/cầu thủ thật | Ảnh AI-generated generic, không logo giải/poster thật |

Đợt restructure module cũng sạch: không còn thư mục cũ sót, không file `.orig/.bak`,
không merge-conflict marker, `.gitignore` cover đủ `Pods/`, `DerivedData/`, `xcuserdata/`, `.DS_Store`, `.figma-tmp/`.

---

## 5. Kết quả chạy thật trên simulator (22/10/2026)

Chạy app trên iPhone 17 / iOS 26.5, dựng **Xtream server giả** (`player_api.php` + redirect
stream sang Apple BipBop) để test end-to-end. Server giả **từ chối sai mật khẩu** (trả `auth: 0`),
nên nếu đọc Keychain hỏng thì profile sẽ không load được — đó là phép thử.

### 5.1 Ba thay đổi của tôi — ĐỀU PASS

| Thay đổi | Cách kiểm chứng | Kết quả |
|---|---|---|
| **Keychain Xtream** | Tạo profile → đọc Core Data trên đĩa → cold restart → mở lại profile | ✅ PASS |
| **AVAudioSession** | Phát stream thật, soi log lỗi `setCategory` | ✅ PASS |
| **App Open thay interstitial lúc resume** | Background → foreground, soi log + ảnh | ✅ PASS |

**Keychain — bằng chứng cụ thể.** Core Data lưu đúng như thiết kế, **không có `password=`**:

```
KeyTest|i340-xtream://profile?server=http://127.0.0.1:8099&username=demo_user
        &pwref=9DB0883A-09CD-42EF-B468-A3A1BC7CEDD9&avatar=avatar_duck_3
```

`grep -rl "S3cretPass"` trên **toàn bộ app container** → 0 file. Sau khi kill app và mở lại,
profile vẫn auth thành công và load được kênh ("Apple BipBop" / category "Test") — tức là đã
đọc `pwref` → lấy mật khẩu từ Keychain → gửi lên server đúng.

**AVAudioSession.** Stream Apple BipBop phát thật (timecode chạy trên màn hình), log không có
dòng `[Player] Audio session category failed`.
⚠️ *Giới hạn:* simulator **không có công tắc im lặng vật lý**, nên hành vi "bật silent switch vẫn
có tiếng" phải xác nhận lại trên máy thật.

**App Open lúc resume.** Log: `AppOpenAdsHandler: Will show ad.` → `Ad will present.`,
ảnh chụp đúng format App Open (có thanh "Continue to app"), không còn là interstitial.

### 5.2 Phát hiện MỚI khi chạy app

| # | Phát hiện | Mức |
|---|---|---|
| ⬜ 1 | **Interstitial vẫn hiện ở Splash.** Tôi mới sửa phần resume. Bản review app kia bắt **cả hai** vị trí: *"Interstitial hiện khi app quay lại foreground và ở Splash/GetStarted — vị trí này chỉ được dùng format App Open"*. Splash vẫn dùng `openInterstitialFirstUtils` / `openInterstitialAd2FUtils`. | P1 |
| ⬜ 2 | **Mỗi lần mở app đều bắt xem lại Language + 3 trang Onboarding** (kèm ads) trước khi vào playlist đã lưu. Không phải bug — `AppDelegate.swift:43` cố ý reset `isSelectedLanguage = false` mỗi launch. Đây là pattern farm ad impression; hại UX với user cũ và là thứ reviewer hay soi. | P1 |
| ⬜ 3 | **Copy onboarding hứa nội dung app không có:** *"Access thousands of live TV channels from around the world, all in one place"*. App **không kèm kênh nào**. `METADATA_v1.0.md` ghi rõ không được hứa điều này (2.3.1 + rủi ro content-rights của app IPTV). | P0 |
| ⬜ 4 | **Ảnh GetStarted / banner Xtream đầy hình thể thao, sân vận động, phòng tin tức** — dù là AI-generated, nó ngụ ý app có nội dung thể thao/TV trực tiếp. Cùng nhóm rủi ro với #3. | P1 |
| ⬜ 5 | **Nút "Add Profile" (xanh) nằm ngay trên nút "INSTALL" (xanh) của native ad** — dễ bấm nhầm, đúng loại bố cục AdMob hay cảnh báo. | P2 |
| ⬜ 6 | **Hộp thoại đánh giá bật ngay sau khi thêm profile đầu tiên** — quá sớm. | P2 |
| ✅ 7 | **Điểm tốt:** Disclaimer trước khi mở Xtream ("app is a media player only, does not provide/host/sell any media content") — viết rất đúng ý App Review, nên giữ và nhắc trong Review Notes. | — |
| ✅ 8 | **Điểm tốt:** thứ tự UMP → ATT đúng (consent trước, ATT sau). Đây là lỗi app kia bị bắt (analytics init trước UMP/ATT). | — |

### 5.3 Những gì KHÔNG kiểm chứng được lần này

- Hành vi công tắc im lặng (cần máy thật).
- **Feature Watch Together / Room (~1.800 dòng)** — có thấy UI "Create Room" dưới player nhưng
  chưa test luồng tạo/vào phòng, sync, host/viewer. Đây vẫn là phần rủi ro nhất chưa được review.
- Luồng IAP thật (cần sandbox + product ID thật).
- iPad.

---

## 4. Đề xuất cho kế hoạch 5 app IPTV

Theo brief "IPTV App Factory": core tech dùng chung, product/monetization experience khác nhau.

**Dùng chung được ngay cho cả 5 app:**

1. `Scripts/release_preflight.sh` + build phase — copy nguyên, chỉ sửa đường dẫn `SRCROOT`.
   Đây là thứ đã cứu app kia; có nó thì không app nào lọt được nhóm lỗi P0.
2. Mẫu `AppRelease.xcconfig` toàn `__SET_ME__` — ép mỗi app phải điền ID riêng, không copy nhầm từ app khác.
3. `XtreamCredentialStore` (Keychain), `AVAudioSession` config, App Open ad ở slot resume.
4. Chuẩn tracking: Adjust là MMP + SKAN writer duy nhất, Meta/TikTok signal-only, ATT qua UMP.
   Có sẵn skill `ios-tracking-integration` + script `sdk_gate_t1.py` để chạy gate trước merge.

**Phải khác nhau giữa 5 app:** UI layout, branding, feature set, user flow, ads flow, monetization flow
→ tách riêng `Modules/` và `Resources/Assets/` mỗi app một bộ.

**Khuyến nghị quy trình:** trước mỗi lần bàn giao, chạy `grep -rn "132978\|voucher\|enableCheat"` và thử
build Release. Lỗi voucher lần này cho thấy backdoor có thể nằm im trong base rất lâu mà không ai để ý.
