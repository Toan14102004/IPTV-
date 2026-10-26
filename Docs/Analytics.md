# Analytics events

Gửi qua `AnalyticsService` (Firebase Analytics). Attribution (Adjust, Meta, TikTok) do `EventTrackingHelper` xử lý riêng.
Adjust là MMP + SKAN writer duy nhất; AppsFlyer đã gỡ khỏi app.

| Event | Khi nào | Tham số | Nơi gửi |
|---|---|---|---|
| `screen_view` | Màn hình hiện ra | `screen_name`, `screen_class` | `.trackScreen("…")` trong các View |
| `purchase` | Mua / gia hạn thành công (đã verify, không trùng) | `transaction_id`, `value`, `currency`, `item_id` | `EventTrackingHelper.logVerifiedPurchase` |
| `restore_purchase` | Restore thành công | — | `EventTrackingHelper.logEventInApp` |
| `ad_impression` | Quảng cáo có doanh thu (`paidEventHandler`) | `ad_platform`, `ad_source`, `ad_format`, `ad_unit_name`, `value`, `currency` | `EventTrackingHelper.handleAdPaidEvent` |
| `import_playlist` | Import playlist thành công | `source` (playlistURL/file/stream), `channels` | `PlaylistView.ViewModel` |
| `playback_start` | Kênh bắt đầu phát | `source` (playlistURL/file/stream/xtream) | `PlaylistPlayerView.ViewModel` |
| `paywall_cta` | Bấm nút mua trên paywall | `item_id` | `PaywallView.ViewModel` |
| `room_create` | Tạo phòng xem chung thành công | — | `RoomService.createRoom` |
| `room_join` | Vào phòng xem chung thành công | — | `RoomService.joinRoom` |

Màn đang được theo dõi: Playlist, Xtream, PlaylistChannel, PlaylistFavorite, PlaylistPlayer, XtreamFavorite,
XtreamDetail, Paywall, Settings.

## Thêm event mới
```swift
AnalyticsService.shared.log(.custom("share_app", ["method": "link"]))
```
Thêm dòng vào bảng trên để cả team biết event tồn tại.

## Kiểm tra
Xcode → Scheme → Arguments Passed On Launch: `-FIRDebugEnabled`, rồi xem Firebase Console → DebugView.
