# Simo Build Guide

## Ads Configuration

Simo hỗ trợ build 2 phiên bản:
- **With Ads** - Dành cho publish lên store
- **No Ads** - Dành cho personal use

## Quick Build

### Build WITH ADS (for publishing)

```bash
./build_with_ads.sh
```

Hoặc manual:

```bash
flutter build apk --dart-define=ENABLE_ADS=true --release
```

Output: `build/app/outputs/flutter-apk/simo-with-ads.apk`

### Build NO ADS (for personal use)

```bash
./build_no_ads.sh
```

Hoặc manual:

```bash
flutter build apk --dart-define=ENABLE_ADS=false --release
```

Output: `build/app/outputs/flutter-apk/simo-no-ads.apk`

## Development

### Run with ads (testing)

```bash
flutter run --dart-define=ENABLE_ADS=true
```

### Run without ads

```bash
flutter run --dart-define=ENABLE_ADS=false
```

Hoặc đơn giản:

```bash
flutter run
```

Default là **có ads** khi không specify ENABLE_ADS.

## Where are ads displayed?

**Banner ads (320x50)** xuất hiện sticky ở cuối các màn hình:
- ✅ Dashboard
- ✅ Transactions
- ✅ Categories
- ✅ Recurring
- ✅ Settings
- ✅ Account

**Rewarded Video Ad:**
- Icon ở góc phải Dashboard AppBar (vòng tròn + "AD")
- User có thể xem video ad để tắt tất cả banner ads
- **Testing**: 30 giây (config trong `ads_config.dart`)
- **Production**: Đổi thành 43200 giây (12 tiếng)
- Icon sẽ đổi thành vòng tròn xanh + gạch chéo khi đang ad-free
- Đa ngôn ngữ: Tiếng Việt, English, 中文

## Ad Unit IDs

Currently using **Test IDs** from AdMob:
- Banner Test ID: `ca-app-pub-3940256099942544/6300978111`
- Rewarded Test ID: `ca-app-pub-3940256099942544/5224354917`

Các IDs này được config trong `lib/config/ads_config.dart`.

**Khi publish:** Cần vào AdMob tạo Ad Units thật và replace IDs trong `ads_config.dart`.

## Build for different stores

### Google Play Store

```bash
./build_with_ads.sh
# Upload: build/app/outputs/flutter-apk/simo-with-ads.apk
```

### Samsung Galaxy Store, Xiaomi GetApps, etc.

```bash
./build_with_ads.sh
# Upload: build/app/outputs/flutter-apk/simo-with-ads.apk
```

### Personal Installation

```bash
./build_no_ads.sh
adb install build/app/outputs/flutter-apk/simo-no-ads.apk
```

## Technical Details

Ads được control bởi:
- `lib/config/ads_config.dart` - Ads configuration & Ad Unit IDs
- `lib/widgets/banner_ad_widget.dart` - Banner ad widget với auto-hide khi ads disabled hoặc trong ad-free period
- `lib/services/rewarded_ad_service.dart` - Rewarded ad service
- Build-time constant: `ENABLE_ADS` (true/false)

Khi `ENABLE_ADS=false`:
- Banner ads sẽ **không hiển thị**
- Rewarded ad button sẽ **không hiển thị**
- AdMob SDK vẫn được initialize (safe)
- Không gọi API load ads
- App size và performance không khác biệt

**Rewarded Ad Flow:**
1. User bấm icon ở Dashboard AppBar (vòng tròn "AD")
2. Hiện dialog xác nhận (đa ngôn ngữ)
3. User bấm "Xem quảng cáo" / "Watch Ad" / "观看广告"
4. Xem video ad đến hết (không skip được)
5. Nhận reward: Tắt tất cả banner ads
6. Timestamp lưu trong SharedPreferences
7. Provider (`adFreeProvider`) notify → **TẤT CẢ** banner ads biến mất **NGAY LẬP TỨC**
8. Icon đổi thành vòng tròn xanh + gạch chéo

**Testing:**
- Duration: 30 giây (trong `ads_config.dart`)
- Khi publish production: Đổi `adFreeDurationSeconds` từ 30 → 43200 (12 hours)

## Troubleshooting

### Build failed

```bash
flutter clean
flutter pub get
./build_with_ads.sh
```

### Ads not showing

Check:
1. Using Test ID? → Ads should show immediately
2. Using Real ID? → Wait 24-48h after creating Ad Unit
3. Internet connection?
4. Check logcat: `adb logcat | grep -i "ad"`

### Want to test "no ads" version

```bash
flutter run --dart-define=ENABLE_ADS=false
```

Hoặc build APK:

```bash
./build_no_ads.sh
adb install build/app/outputs/flutter-apk/simo-no-ads.apk
```
