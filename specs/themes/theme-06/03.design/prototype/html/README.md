# Prototype Theme 6 — Công nợ phải thu (T6-2a)

HTML/CSS/JS thuần (ES module, không build) cho CN-01, CN-02, CN-03, SG-13 bản cấn trừ và màn gom `patches`.
Spec: `docs/02-yeu-cau/TH-06-cong-no.md` mục 2.2, 2.3, 4.2–4.5, 5.2–5.6, 6.3. Plan: `docs/refactor/plans/T6/T6-2a-prototype.md`.

## Chạy

```bash
cd specs/themes/theme-06/03.design/prototype/html
python3 tools/serve.py &    # cổng 8766, tắt cache: sửa JS/CSS xong chỉ cần ⌘R
# xem: http://127.0.0.1:8766/   (trang xem: cột trái chọn ca, khung iPhone / Web / Cả hai, chế độ "Cả màn" = lưới mọi trạng thái)
#   phím: ↑/↓ (hoặc k/j) ca trước / sau · 1 iPhone · 2 Web · 3 Cả hai · g đổi Từng ca / Cả màn
#   link chia sẻ được: http://127.0.0.1:8766/#sg13/one-unchecked/both/single
# một màn trần (đúng URL chụp ảnh): index.html?screen=cn01&state=all&device=iphone   (device=iphone|web)
node --test                 # test hàm thuần + dữ liệu (Node 24: không truyền thư mục)
bash tools/check-classes.sh # class dùng trong app/*.js nhưng thiếu rule CSS (bỏ qua dòng "method": class ghép động)
node tools/capture.mjs      # chụp 38 ca × 2 khổ → tools/proto-final/{iphone,web}/  (node tools/capture.mjs cn01: chỉ ca bắt đầu bằng cn01)
```

Khổ chụp: iPhone 390×844, web 1280×800, scale 1 (Chrome headless). Ảnh trong `tools/proto-final/` không vào git.
Tham số thử tay: `&amount=10.000.000` (CN-03). Tương tác thật: lọc / tìm (300 ms, bỏ dấu) / chạm dòng khách ở CN-01; gõ tiền, `Trả hết`, đổi phương thức ở CN-03; chọn / bỏ đơn cấn trừ ở SG-13.

## Danh sách ca (`<screen>__<state>.png`)

| screen | state | Dữ liệu (thời điểm của ví dụ 2.3) |
|---|---|---|
| `cn01` | `loading`, `all`, `many`, `no-overdue`, `overdue` (hero đang lọc), `search-empty`, `empty`, `error`, `loading-more`, `long` | 3 khách trước bước 1; `many` = 8 khách (`richCustomers`, đủ quá hạn / hôm nay / hẹn / không hẹn); `no-overdue` = hero xanh; `long` thêm công ty tên dài (không SĐT, ≥ 1 tỷ) và Cô Hoa (ngừng hoạt động). Bố cục "Quá hạn dẫn đầu" (phương án B, chốt 2026-11-18): hero tiền quá hạn (cũng là lối lọc, không còn chip) → tổng thu nhỏ → tìm → danh sách xếp theo mức khẩn |
| `cn02` | `full`, `after-offset`, `block-error`, `paid-off`, `inactive`, `no-history` | Tuấn `before` / `afterOffset` / `paidOff`; `inactive` = Cô Hoa; `no-history` = Chị Lan |
| `cn03` | `empty`, `valid`, `over`, `transfer`, `confirm`, `submitting`, `submit-error`, `changed`, `leave-confirm`, `all`, `one`, `multi`, `one-over`, `one-confirm`, `success` | Tuấn `before`; `success` = CN-02 Tuấn `afterCollect` + toast |
| `sg13` | `all-selected`, `one-unchecked`, `none-selected`, `confirm`, `stale` (bước 2); `mixed`, `source-has-debt`, `no-other-debt` (dữ liệu riêng) | bước 2 của 2.3: DH-001 trả 500.000, nợ khác DH-002 (còn 2.000.000) và DH-003 (6.000.000) |
| `patches` | `sg09`, `sg09b`, `sg09c`, `sg14`, `pt07`, `more-menu` | khung minh hoạ Trước / Sau (viền xanh + nhãn MỚI) — **không** phải bản vẽ pixel của màn TH-05 / TH-03 hiện có |

Web: `cn01`/`cn02` hai cột (trái CN-01 rộng 380, phải CN-02 hoặc "Chọn một khách để xem công nợ"); `cn03` là hộp thoại trên hai cột; `sg13` một cột 560 px giữa khung.

## Nguồn token / component

- `shared/` (symlink tới `specs/prototype/shared/`): `tokens.css`, `components.css`, `icons.js` dùng chung với các theme khác. Xem `specs/prototype/README.md`. Cần chạy bằng `python3 tools/serve.py` (đi qua symlink).
- `styles/receivable.css`, `cn01.css`, `cn03.css`: rule riêng của Theme 6, chỉ dùng `--vet45-v2-*`. **Ngoại lệ:** Theme 7 không có token cỡ chữ nên khai báo `--rc-fs-*` ở đầu `receivable.css`.
- `app/icon.js`: re-export `shared/icons.js` (`icon()` / `k7CheckMark()`).
- `styles/receivable.css`: rule mới, chỉ dùng `--vet45-v2-*`. **Ngoại lệ:** Theme 7 không có token cỡ chữ nên khai báo `--rc-fs-*` ở đầu file.
- `app/ui.js` (không có trong plan ban đầu): hàm dùng chung (khung màn, sheet / dialog, badge, toast).

## Font

Theme 7 chỉ khai báo `font-family` (Inter) mà không nạp font, nên ảnh dùng font hệ thống. Giữ như Theme 7; khi so với Flutter đừng bắt lệch font.

## SG-13 nền (từ Flutter hiện có)

Đọc `apps/erp/lib/features/sales/presentation/{pages/sales_return_exchange_settlement_page.dart, widgets/sales_return_exchange_settlement_body.dart, widgets/sales_return_confirm_settlement_sheet.dart}`:

- Appbar "Quyết toán đổi/trả" → dòng phụ `<mã đơn> · <khách>` → một thẻ (số tiền nổi bật; hoàn thì có "Giảm nợ đơn này" + "Phương thức hoàn" Tiền mặt / Chuyển khoản) → khối thu gọn "Tóm tắt đổi/trả" (Chênh lệch, Giá trị hàng trả / đổi) → nút dưới "Xác nhận đổi/trả"; sheet "Xác nhận đổi/trả?" có đoạn tóm tắt, nút "Xác nhận đổi/trả" / "Quay lại".
- Màn hiện có **không có bố cục riêng cho web** (một cột như iPhone). Prototype web để một cột 560 px.
- Prototype giữ thứ tự đó và chèn các dòng mới của TH-06: nhãn "Khách được hưởng", "Giảm nợ đơn này" (+ chữ giải thích), khối "CẤN TRỪ VÀO ĐƠN KHÁC", "Hoàn cho khách" + "Phương thức hoàn" chỉ khi hoàn > 0; tóm tắt được vẽ mở sẵn như khung 5.5. Sai khác nhỏ có chủ đích: nhãn phương thức hoàn "CK" theo 5.5 (Flutter hiện ghi "Chuyển khoản").

## Chữ tạm (spec không quy định, cần bạn chốt khi duyệt ảnh)

- Hộp "Bỏ khoản thu đang nhập?" (`cn03__leave-confirm`): nút **"Ở lại"** / **"Bỏ"**.
- Hộp `RECEIVABLE_CHANGED` (CN-03 và SG-13): câu thông báo đặt làm tiêu đề hộp, một nút "Tải lại".
- Dòng phụ SG-13 `DH-001 · Anh Tuấn` (mã đơn nguồn · khách) theo Flutter hiện có.
- Dòng lịch sử CN-02: số tiền không kèm ₫ ("Thu 2.000.000 · Tiền mặt"), số trong khối "Sẽ trừ vào" cũng bỏ ₫ theo khung 5.4; tổng và còn nợ có ₫.
- Dòng quá hạn ở bộ lọc: `⚠ Quá hạn 8 ngày · 12.000.000 ₫`.
- `patches`: tiêu đề màn khung minh hoạ ("Chi tiết đơn · DH-002", "Lịch sử đơn", "Hồ sơ đối tác · Anh Tuấn", "Đã ghi nhận đổi/trả", nút "Xong", "Vai trò"…) chỉ để dựng khung.
- Chạm dòng khách khác Tuấn ở CN-01: prototype chỉ có dữ liệu CN-02 của Tuấn, Chị Lan, Cô Hoa; các khách khác mở CN-02 của Tuấn.
