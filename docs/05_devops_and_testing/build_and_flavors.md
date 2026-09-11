# Hướng Dẫn Build, Flavors & Phát Hành (Build & Release Guide)

Tài liệu này hướng dẫn cách cấu hình môi trường, phân biệt bản Development vs Production, và các kịch bản đóng gói ứng dụng Simo cho Android.

---

## 1. Phân Biệt Bản Dev và Bản Production

Để bảo vệ an toàn dữ liệu thực tế của người dùng và lập trình viên khi thử nghiệm tính năng mới, ứng dụng được cấu hình phân tách Application ID và Tên ứng dụng trong `android/app/build.gradle.kts`:

| Thuộc tính | Debug / Development | Release / Production |
| :--- | :--- | :--- |
| **Package Name** | `com.simolab.simo.dev` | `com.simolab.simo` |
| **Tên Ứng Dụng** | **Simo Dev** | **Simo** |
| **Database Path** | Độc lập (`simo.db` trong sandbox `.dev`) | Độc lập (`simo.db` của bản chính) |
| **Lệnh Chạy** | `flutter run -d <DEVICE_ID>` | `flutter build apk --release` |

> [!CAUTION]
> **Quy Tắc Bảo Toàn Dữ Liệu**:
> Khi debug hoặc chạy thử nghiệm trực tiếp trên điện thoại cá nhân, **luôn luôn sử dụng bản Debug (`Simo Dev`)**. Việc cài đè bản Release có thể làm mất hoặc ghi đè dữ liệu tài chính thực tế đang sử dụng hàng ngày!

---

## 2. Kịch Bản Đóng Gói Ứng Dụng (Build Scripts)

Simo cung cấp sẵn hai script đóng gói tự động hóa ở thư mục gốc:

### 2.1. Bản Cá Nhân Không Quảng Cáo (`build_no_ads.sh`)
Dành cho lập trình viên hoặc sử dụng nội bộ (tắt hoàn toàn Google Mobile Ads SDK):
```bash
./build_no_ads.sh
```
Lệnh thực thi cốt lõi:
```bash
flutter build apk --dart-define=ENABLE_ADS=false --release
```
- Đầu ra: `build/app/outputs/flutter-apk/simo-no-ads.apk`

### 2.2. Bản Phát Hành Có Quảng Cáo (`build_release.sh` / `build_with_ads.sh`)
Dành cho việc xuất bản lên Google Play hoặc phân phối công khai:
```bash
./build_release.sh
```
Lệnh thực thi cốt lõi:
```bash
flutter build apk --dart-define=ENABLE_ADS=true --release
```
- Đầu ra: `build/app/outputs/flutter-apk/simo-v{VERSION}.apk`
- Hỗ trợ xem rewarded video để nhận 12 tiếng trải nghiệm không quảng cáo.

---

## 3. Chạy Kiểm Thử Trực Tiếp Trên Thiết Bị (Live Device Run)

1. Kiểm tra danh sách thiết bị Android đang kết nối qua cáp hoặc Wi-Fi ADB:
   ```bash
   flutter devices
   ```
2. Chạy ứng dụng bản Dev lên thiết bị:
   ```bash
   flutter run -d <DEVICE_ID>
   ```
3. Các phím tắt hữu ích trong Terminal:
   - Nhấn `r`: Hot Reload (cập nhật UI tức thì).
   - Nhấn `R`: Hot Restart (khởi động lại toàn bộ state Riverpod).
   - Nhấn `q`: Thoát ứng dụng.
