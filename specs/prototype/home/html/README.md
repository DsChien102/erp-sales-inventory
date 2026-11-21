# Prototype Trang chủ APP-01 (10-8 "Trang chủ (dashboard)")

HTML/CSS/JS thuần (ES module, không build). Vẽ **đúng Flutter hiện tại** của Trang chủ, đặt trong khung chung (`shared/shell.js`), để người dùng rà bằng impeccable (bước 3 của 10-8). Chép y nguyên cả số liệu ghi cứng và chữ mẫu, không thiết kế lại.

## Chạy

```bash
# xem chung với các prototype khác: python3 specs/prototype/serve.py → http://127.0.0.1:8760/ (mục lục)
cd specs/prototype/home/html
python3 tools/serve.py &    # cổng 8768, tắt cache
# trang xem: http://127.0.0.1:8768/   (cột trái chọn ca; iPhone / Web / Cả hai; Từng ca / Cả màn / Sửa trực tiếp)
# một ca trần (URL chụp ảnh): index.html?screen=home&state=owner-banner&device=web
node --test                 # hàm thuần đối chiếu Dart + mọi ca vẽ được
node tools/capture.mjs      # 7 ca × 2 khổ → tools/proto-final/{iphone,web}/home__<state>.png (không vào git)
```

Ở ca trần: bấm × trên banner để ẩn banner. Các nút khác không làm gì (trong Flutter là `onTap: () {}` hoặc mở route ngoài khung).

## Tệp

| Tệp | Vai trò |
|---|---|
| `app/main.js` | Màn Trang chủ (`homePage`), hàm thuần `greetingForHour`, `showLegalBanner`, ca → trạng thái |
| `styles/home.css` | Rule của màn, tiền tố `hm-`, token `--c45-v2-*`; đầu file có bảng màu Flutter → token |
| `app/cases.js`, `app/viewer.js`, `styles/viewer.css`, `styles/stage.css`, `tools/` | Danh sách ca, trang xem, chụp ảnh (chép khuôn Khung chung) |
| `shared/icons.js` | Thêm `bell`, `trendingUp`, `handshake` |

## Nguồn Flutter

| Phần | Flutter (`apps/erp/lib/features/dashboard/presentation/`) |
|---|---|
| Bố cục màn | `home_tab_page.dart` (`_SectionHeader` ở cuối file) |
| Đầu trang xanh, lời chào, tên tổ chức, chuông, ô tìm | `widgets/dashboard_header.dart`, `widgets/home_header.dart`, DS `v_search_bar.dart` (header) |
| Banner hồ sơ pháp lý | `widgets/legal_profile_home_banner.dart`, DS `v_banner.dart`, `v_button.dart` (link) |
| "Hỏi Mosaic Retail" | `VButton` secondary `fullWidth` trong `home_tab_page.dart` |
| Thẻ doanh thu | `widgets/revenue_summary_card.dart` → `widgets/revenue_card.dart` |
| Ba ô số | `widgets/metric_tile.dart` → `widgets/metric_card.dart`, DS `v_card.dart` |
| Việc cần xử lý | `widgets/task_item.dart` → `widgets/todo_item.dart`, DS `v_badge.dart` |

## Hiện trạng Flutter (để rà)

1. **Toàn bộ số liệu là giả.** Thẻ doanh thu ghi cứng `8.420.000 ₫ · Từ 12 đơn · +18% so với hôm qua`; ba ô "Đơn hôm nay / Phải thu / Sắp hết" luôn `-`; hai dòng "Việc cần xử lý" là chữ mẫu `Công việc cần xử lý / Mô tả công việc chi tiết / Chờ xử lý`. Chưa có RPC nào cho Trang chủ.
2. **Bấm vào không làm gì:** thẻ doanh thu, hai dòng việc (`onTap: () {}`), chuông (`onNotificationTap: () {}`); ô tìm `readOnly`, không có `onTap`.
3. **Chấm thông báo luôn hiện** (`hasNotification: true` ghi cứng).
4. **Web dùng nguyên bố cục điện thoại:** đầu trang xanh và mọi thẻ giãn hết bề ngang 1040; ba ô số rộng ~330 mỗi ô; không có `VContentWidth` hay bố cục riêng ≥ 1024.
5. **Widget thừa trong thư mục:** `QuickActionButton` (thao tác nhanh mà PLAN nhắc tới), `ActivityItem` không được dùng ở đâu.
6. Banner: icon canh giữa theo hàng cao 48 (do nút × 48), tiêu đề canh trên → trên web tiêu đề lệch lên so với icon; "Bổ sung" là nút link cao 44 nên khoảng trống dưới tiêu đề lớn.

## Khác biệt có chủ đích với Flutter

- Icon: Material thay bằng nét kiểu Lucide trong `shared/icons.js`, giữ ý nghĩa và cỡ.
- Font: không nạp Inter / JetBrains Mono (như Theme 6 / 7 và Khung chung); số tiền dùng font mono hệ thống.
- Lời chào cố định "sáng" (09:41) trừ ca `evening`; Flutter lấy giờ máy.
- Bấm tên tổ chức mở APP-04 trong Flutter; ở đây không mở (APP-04 rà ở prototype Khung chung).
- Hover / pressed: theo ước lượng (`neutral-150` cho nút secondary, nền mờ cho nút ×).
