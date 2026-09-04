# Implementation Plan: 014-advanced-filter-fuzzy-search

**Branch**: `014-advanced-filter-fuzzy-search` | **Date**: 2026-09-04 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/014-advanced-filter-fuzzy-search/spec.md`

## Summary

Nâng cấp toàn diện cơ chế tìm kiếm và bộ lọc của màn hình giao dịch (`TransactionScreen`):
1. **Fuzzy Search & Chuẩn hóa tiếng Việt**: Tìm kiếm thông minh đa trường (ghi chú, danh mục, tên ví, số tiền), tự động chuẩn hóa tiếng Việt không dấu, nhận diện từ khóa viết tắt số tiền ("50k", "1.5tr") và cho phép dung sai sai chính tả nhẹ.
2. **Bộ Lọc Nâng Cao (Advanced Filters)**: Hỗ trợ lọc đa ví (multi-wallet), lọc đa danh mục (multi-category), lọc loại (thu/chi), lọc thời gian linh hoạt (mốc nhanh, MonthYearPickerModal chuẩn của app, khoảng ngày), và lọc khoảng tiền min-max.
3. **Thanh Quick Filter Chips**: Thanh chip cuộn ngang trực quan dưới AppBar cho phép chuyển nhanh ví, thời gian, loại giao dịch 1 chạm.
4. **Pipeline phối hợp tuần tự**: Tìm kiếm thực thi trực tiếp trên tập dữ liệu đã qua bộ lọc; kết quả vẫn duy trì phân nhóm thẻ ngày (Day Cards) với thứ tự thời gian mới nhất lên đầu.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x  
**Primary Dependencies**: Flutter Riverpod, Intl, Google Fonts  
**Storage**: SQLite (`sqflite`), dữ liệu lọc và search thực thi in-memory trên tập danh sách tải từ SQLite  
**Testing**: Flutter unit tests (`flutter_test`), widget tests  
**Target Platform**: Android, iOS, Desktop (Linux/Windows/macOS)  
**Project Type**: Mobile Application  
**Performance Goals**: Tìm kiếm & lọc dưới 100ms trên tập 1.000+ giao dịch, cuộn mượt mà 60fps  
**Constraints**: Hoạt động offline 100%, không dùng thư viện ngoài cho fuzzy search, giữ nguyên cấu trúc Day Cards  

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **I. Library-First / Modular Design**: Tách riêng `FuzzySearchService` và `TransactionFilterService` thành các service độc lập, dễ kiểm thử.
- [x] **II. Test-First (TDD Enforced)**: Toàn bộ thuật toán chuẩn hóa tiếng Việt, parser số tiền và pipeline lọc đều có unit test đầy đủ trước khi ráp UI.
- [x] **III. Simplicity & YAGNI**: Tối ưu thuật toán tìm kiếm mờ thuần Dart gọn nhẹ, không dùng thư viện FTS cồng kềnh.
- [x] **IV. UI/UX Consistency**: Tái sử dụng `MonthYearPickerModal` đã chuẩn hóa toàn app, giữ nguyên phong cách Day Cards vừa làm.

## Project Structure

### Documentation (this feature)

```text
specs/014-advanced-filter-fuzzy-search/
├── plan.md              # Kế hoạch triển khai kiến trúc
├── research.md          # Nghiên cứu thuật toán chuẩn hóa và pipeline
├── data-model.md        # Mô hình dữ liệu tiêu chí lọc & kết quả search
├── quickstart.md        # Hướng dẫn kiểm thử và kịch bản xác thực
├── contracts/           # Hợp đồng interface các service
│   ├── fuzzy-search-service-contract.md
│   └── filter-service-contract.md
├── checklists/
│   └── requirements.md  # Checklist chất lượng yêu cầu
└── tasks.md             # Sẽ được tạo bởi /speckit-tasks
```

### Source Code Layout

```text
lib/
├── models/
│   └── transaction_filter_criteria.dart    # Model tiêu chí lọc
├── services/
│   ├── fuzzy_search_service.dart           # Thuật toán chuẩn hóa tiếng Việt & fuzzy search
│   └── transaction_filter_service.dart     # Pipeline áp dụng các tiêu chí lọc
├── widgets/
│   ├── quick_filter_chips_bar.dart         # Thanh chip cuộn ngang lọc nhanh
│   └── transaction_filter_bottom_sheet.dart# BottomSheet bộ lọc nâng cao
└── screens/
    └── transaction_screen.dart             # Màn hình giao dịch tích hợp search & filter mới

test/
└── unit/
    ├── fuzzy_search_service_test.dart      # Unit test bộ chuẩn hóa & fuzzy search
    └── transaction_filter_service_test.dart# Unit test pipeline lọc đa tiêu chí
```

## Implementation Phases

### Phase 1: Core Engine & Services (TDD)
1. Xây dựng `TransactionFilterCriteria` model với `copyWith`, `isDefault`, `activeFilterCount`.
2. Xây dựng `FuzzySearchService`:
   - Chuẩn hóa tiếng Việt không dấu (`normalizeVietnamese`).
   - Parse số tiền viết tắt (`tryParseShorthandAmount`: 50k, 1.5tr, 2m...).
   - Thuật toán tìm kiếm đa trường: Ghi chú, Danh mục, Tên ví, Số tiền.
3. Xây dựng `TransactionFilterService`:
   - Lọc đa ví, đa danh mục, loại thu/chi, thời gian (mốc định sẵn, tháng năm, date range), khoảng tiền.
   - Chạy fuzzy search trên data đã lọc.
4. Viết trọn bộ unit test xác thực cho cả 2 service.

### Phase 2: UI Components
1. Tạo widget `QuickFilterChipsBar`:
   - Hiển thị chip cuộn ngang: Ví, Thời gian, Loại, Nút mở modal bộ lọc chi tiết có badge đếm số lượng.
   - Popup chọn nhanh 1 chạm cho từng chip.
2. Tạo widget `TransactionFilterBottomSheet`:
   - Lưới chip chọn ví (đa chọn + "Chọn tất cả").
   - Lưới chip chọn danh mục (đa chọn có icon).
   - Tùy chọn thời gian: Chip mốc nhanh, nút mở `MonthYearPickerModal`, nút DateRange.
   - Khoảng tiền Min-Max.
   - Nút Đặt lại và Áp dụng.

### Phase 3: Screen Integration & Verification
1. Tích hợp thanh `QuickFilterChipsBar` và `TransactionFilterBottomSheet` vào `TransactionScreen`.
2. Kết nối AppBar search TextField với `FuzzySearchService`.
3. Kiểm tra phối hợp giữa Search và Filter, đảm bảo giữ nguyên cấu trúc Day Cards và thứ tự thời gian mới nhất lên đầu.
4. Chạy toàn bộ test suite và build APK kiểm tra thực tế.
