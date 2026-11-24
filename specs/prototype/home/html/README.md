# Prototype Trang chủ APP-01 (10-8 "Trang chủ (dashboard)")

HTML/CSS/JS thuần (ES module, không build), đặt trong khung chung (`shared/shell.js`). Ban đầu chép đúng Flutter hiện tại; sau khi rà bằng impeccable (bước 3 của 10-8), người dùng **chốt thiết kế lại** Trang chủ theo đề xuất "Bảng giá chợ" (2026-11-23). Prototype này giờ vẽ **đề xuất đó**, không còn bản Flutter. Bảng hiện trạng Flutter bên dưới giữ để đối chiếu.

## Chạy

```bash
# xem chung với các prototype khác: python3 specs/prototype/serve.py → http://127.0.0.1:8760/ (mục lục)
cd specs/prototype/home/html
python3 tools/serve.py &    # cổng 8768, tắt cache
# trang xem: http://127.0.0.1:8768/   (cột trái chọn ca; iPhone / Web / Cả hai; Từng ca / Cả màn / Sửa trực tiếp)
# một ca trần (URL chụp ảnh): index.html?screen=home&state=owner&device=web
node --test                 # lời chào theo giờ + mọi ca vẽ được + nội dung đã chốt
node tools/capture.mjs      # 5 ca × 2 khổ → tools/proto-final/{iphone,web}/home__<state>.png (không vào git)
```

Ở ca trần các nút chưa làm gì (prototype); bấm tên tổ chức trong Flutter sẽ mở APP-04.

## Tệp

| Tệp | Vai trò |
|---|---|
| `app/main.js` | Ca → trạng thái, `greetingForHour`, vẽ trong khung |
| `app/board.js` | Màn Trang chủ "Bảng giá chợ" (`boardPage`) + dữ liệu mẫu `SAMPLE` |
| `styles/board.css` | Rule của màn, tiền tố `bz-`, chỉ token `--c45-v2-*` |
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

## Đề xuất đã chốt "Bảng giá chợ" (2026-11-23) — đã có trong Flutter (10-8b, 2026-11-24)

Đã chuyển về Flutter theo [plan 10-8b](../../../../docs/refactor/plans/P10/10-8b-trang-chu-flutter.md): RPC `sales.get_home_summary`, `HomeTabPage` + `widgets/home_board.dart`, khung chat `AssistantChatPanel`; ảnh so sánh `docs/refactor/plans/P10/img/10-8b/`.

Giữ màu, font Mosaic; đổi cách trình bày. Cả web (≥ 1024, trong thanh biểu tượng) và iPhone (trong thanh dưới).

- **Đầu trang:** lời chào + ngày, tên tổ chức lớn (bấm để đổi tổ chức). **Bỏ ô tìm, chuông** (hiện trạng 2, 3 không còn).
- **Hỏi Mosaic Retail (đề xuất 2026-11-23):** không còn nút ở đầu trang. Nút nổi vuông bo 56 màu chữ đậm ở góc dưới phải mở **khung chat nổi** ngay trên Trang chủ: web là cửa sổ lớn rộng ≤ 1120, cách đỉnh 64, dải đầu xanh, lời chào + gợi ý (lưới 2 cột) + ô hỏi trong cột 720 (nút thành ✕), iPhone là màn toàn phần, ẩn thanh dưới. Trong khung: lời chào + 4 câu gợi ý + ô hỏi + câu nhắc, chữ import nguyên văn từ `assistant/html/app/ask.js`; ⤢ mở màn `/ask` đầy đủ; Esc / ✕ đóng. Ca `ask-open`. Lệch Flutter hiện tại (`context.push('/ask')` từ nút ở `home_tab_page.dart`).
- **Doanh thu:** số rất lớn màu brand, ▲ % so với hôm qua; cột doanh thu 7 ngày đúng tỉ lệ, hôm nay màu brand — biểu đồ **duy nhất** trên màn.
- **Ba hộp số** (web một hàng, iPhone xếp dọc): **Đơn hôm nay** (số đơn ▲ so với hôm qua | **Chưa xuất hoá đơn** chỉ con số, dòng Tiền mặt / Chuyển khoản / Ghi nợ); **Tiền đã thu hôm nay** (thu lúc bán + khách trả nợ TH-06, tách tiền mặt / chuyển khoản); **Công nợ phải thu** (tổng + số khoản quá hạn). Thứ tự trên iPhone: Đơn hôm nay → Công nợ phải thu → Tiền đã thu hôm nay (người dùng chốt 2026-11-23); web giữ Đơn → Tiền đã thu → Công nợ.
- Số lật lên một lần khi mở (tắt khi giảm chuyển động).
- **Không có:** nút thao tác (Tạo đơn, Nhập hàng…), việc cần xử lý, ô số "Sắp hết", **banner hồ sơ pháp lý**.
- **Lệch tài liệu:** bỏ banner trái TH-01 BR-14 / FR-01 (banner nhắc ở trang chủ) — **đã sửa TH-01** (2026-11-24): banner chỉ còn ở Hồ sơ tổ chức.
- **Cần cho Flutter (đã làm ở 10-8b):** RPC doanh thu hôm nay + 7 ngày, đơn hôm nay theo cách trả, số đơn chưa xuất HĐĐT (TH-08), tiền đã thu hôm nay (TH-06), tổng phải thu + quá hạn (TH-06). Số liệu trong prototype là dữ liệu mẫu.

## Khác biệt có chủ đích với Flutter

- Icon: Material thay bằng nét kiểu Lucide trong `shared/icons.js`, giữ ý nghĩa và cỡ.
- Font: không nạp Inter / JetBrains Mono (như Theme 6 / 7 và Khung chung); dùng font hệ thống.
- Lời chào cố định "sáng" trừ ca `evening`; Flutter lấy giờ máy.
- Bấm tên tổ chức mở APP-04 trong Flutter; ở đây không mở (APP-04 rà ở prototype Khung chung).
