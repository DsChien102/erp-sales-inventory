---
target: Theme 7 (Kho) prototype index.html — hai khung iPhone + web, G3-6
total_score: 29
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 1
target_identity: "file:/Users/macbook/Documents/Đồ án/specs/themes/theme-07/03.design/prototype/html/index.html"
target_fingerprint: "sha256:4a9de1881112f6f02ddb768719cb20392a6e2bec1d28cf823937944664b9e4e9"
target_path: /Users/macbook/Documents/Đồ án/specs/themes/theme-07/03.design/prototype/html/index.html
timestamp: 2026-10-26T07-12-45Z
slug: me-07-03-design-prototype-html-index-html-050831a4
---
# Critique: Theme 7 (Kho) — prototype HTML v5.25.0, hai khung
⚠️ DEGRADED: single-context (không dùng sub-agent: A xem 28 ảnh golden iPhone + web đã chụp, B chạy `impeccable detect` sau đó)

## Điểm (so với 24/40 ngày 2026-10-15)
| # | Heuristic | iPhone | Web | Vấn đề chính |
|---|---|---|---|---|
| 1 | Hiển thị trạng thái | 3 | 3 | K3/K4 có mã, giờ, "Dữ liệu đến 21:30 17/09"; nhưng BJ-02 ghi "nhận 16/09" còn thẻ kho ghi 17/09 |
| 2 | Khớp thực tế | 3 | 3 | Tiếng Việt nghiệp vụ rõ; còn "Đếm mù", "Căn cứ", "REC-UNKNOWN-0x" ở danh sách |
| 3 | Kiểm soát | 3 | 3 | Có lối ra mọi màn (dò ngõ cụt 0/498), Esc + trả focus; không hoàn tác duyệt |
| 4 | Nhất quán | 3 | 3 | Một họ K1–K7; còn nút chân gãy hai dòng, key-value BJ-14 lệch |
| 5 | Ngăn lỗi | 3 | 3 | Nút khoá có lý do, sheet xác nhận, phát hiện dữ liệu đổi giữa chừng |
| 6 | Nhận ra thay vì nhớ | 3 | 3 | Chip có số, nguồn dòng; hạn dùng cùng một lô khác nhau giữa BJ |
| 7 | Linh hoạt | 2 | 3 | iPhone: điền nhanh "Lấy đủ / Cả n chai" nhưng chưa có thao tác hàng loạt; web: Tab / Esc / dòng là nút |
| 8 | Tối giản | 3 | 2 | Web: bảng rộng cột thưa ("Đếm được" cách xa sản phẩm), key-value BJ-14 lệch, số 9–10px |
| 9 | Phục hồi lỗi | 3 | 3 | Mọi trạng thái lỗi có đường ra đặt tên; "Thống nhất giá ở Mua hàng rồi quay lại" |
| 10 | Trợ giúp | 3 | 3 | Banner ngữ cảnh, "Cách tính"; chưa có trợ giúp tìm kiếm được |
| **Tổng** | | **29/40** | **29/40** | **Tốt (28–35)** — điểm Giai đoạn 3 = điểm thấp hơn = **29/40** (gốc 24) |

Đối chiếu P0 / P1 / P2 của bản gốc: màu tiền / tồn (P0) **hết**; màn duyệt chôn quyết định (P1) **hết** (câu hỏi + "Cần chú ý" lên đầu); hai Home / Kho dưới "Thêm" (P1) **hết** (Home Kho một nơi, thanh 5 tab / thanh bên); ngõ cụt (P2) **hết** (công cụ dò 0 lỗi); chữ chuyên môn (P2) **còn nhẹ**.

## Đặc thù sản phẩm
Có chất riêng: số mono có dấu "+ / −", "Cần chú ý" theo nghĩa, một họ khuôn K1–K7 dùng cho 17 BJ, nhãn nghiệp vụ thú y (Nobivac, Tylosin). Không còn là "danh sách trắng trên nền xám" đa năng. Điểm còn nhạt: màn kết quả K4 giống nhau (biểu tượng + thẻ key-value), chưa có "khoảnh khắc đáng nhớ" cho demo (đỉnh là thẻ kho cuối `SC_demo`).
Detector (`impeccable detect`, 122 phát hiện): phần lớn là nhiễu — `overused-font` (Inter là font của design system) và 34 mục ở `harness/workbench.css` / `index.html` (vỏ công cụ, không phải app). Thật trong app: **9 chỗ chữ 9–10px** (nhãn thanh tab 9px, vài badge / chú thích 10px), 1 `.skeleton::after` lặp vô hạn (marquee) — chỉ là skeleton, bỏ qua; màu / bán kính lệch ramp là advisory.

## Điểm tốt
- Màn duyệt đặt **câu hỏi + ngoại lệ + hai nút** ở đầu / chân, bảng "chứng từ · thực nhận · chênh lệch" ở bên (web) — quyết định không bị chôn.
- Một sổ kho: thẻ kho Oxytetracycline cuối demo ghi "Nhận hàng +24 / Điều chỉnh kiểm kê −2" và cuối kỳ = tồn BJ-01.
- Kiểm soát bàn phím trên web: dòng bảng là nút, Esc đóng sheet và trả focus; K4 có thanh tab ở iPhone.

## Vấn đề ưu tiên
- **[P1] Dữ liệu mẫu tự mâu thuẫn giữa các BJ, làm hỏng niềm tin khi demo.** Lô Nobivac DH2509: BJ-01 / BJ-12 ghi HSD 15/09/2026 và gắn "Cận hạn · còn 19 ngày" — nhưng mốc dữ liệu giờ là 17/09 nên lô đã quá hạn 2 ngày; BJ-05 / BJ-06 ghi HSD 09/2027. BJ-02 nói "nhận 16/09/2026" còn thẻ kho ghi ngày nghiệp vụ 17/09. Sửa: một HSD cho mỗi lô (DH2509 → 30/09/2026, còn 13 ngày) ở BJ-01 / 05 / 06 / 12; ngày nghiệp vụ của dòng nhận hàng = ngày nhận của phiếu. Lệnh: `harden`, `clarify`.
- **[P2] Nút chính ở chân iPhone gãy hai dòng** ("Chuyển sang xác minh", "Về công việc điều chỉnh", "Về hồ sơ cần kiểm tra") khi chân chia đôi; tên nguồn BJ-13 gãy ở dấu gạch nối ("VC-" / "8842"). Sửa: chân dọc khi chữ dài hoặc cho phép nút rộng hơn; gạch nối không ngắt cho mã. Lệnh: `layout`, `typeset`.
- **[P2] Web: bảng rộng nhưng thưa, key-value lệch.** "Đếm mù" (044): cột "Đếm được" nằm ~700px cách sản phẩm; BJ-14 074: dòng "Điều chỉnh giá vốn xuất / giá trị tồn" không sát lề phải, đường kẻ cắt qua chữ; BJ-03 web lặp "Lô DH2507 · 121 hộp" ngay cạnh cột "121 hộp". Lệnh: `layout`, `distill`.
- **[P2] Chữ 9–10px** ở nhãn thanh tab iPhone, badge và chú thích (9 chỗ trong CSS) dưới sàn đọc được. Sửa: ≥ 11px. Lệnh: `typeset`.
- **[P2] Các góp ý nhỏ còn lại của plan:** 068 "Sửa số kiểm soát" phải mở 067 và focus ô tổng; 015 web cột "Tình trạng" 240px làm cột "Sản phẩm" gãy; 008 web thứ tự Tab; K2 iPhone nhãn "{tên}:" còn dấu hai chấm; 041 `REJECTED` icon đồng hồ + thiếu Lô / Số lượng; 037 "Đúng hàng" xám → "Chọn phần hàng"; 079 web nội dung ở cột hẹp; "Kết luận" luôn màu cảnh báo; 044 iPhone "Bán / được" gãy.

## Persona
**Casey (một tay, iPhone):** nút chân chia đôi làm chữ chính gãy hai dòng, nhãn tab 9px khó đọc; chip lọc cuộn ngang bị cắt ("Tiêu…"). **Sam (bàn phím / đọc màn hình):** Tab đi vòng được trong sheet, dòng bảng là nút; còn chữ 9–10px, số tiền xanh / đỏ có dấu +/− nên không chỉ màu. **Chủ cửa hàng (demo trước hội đồng):** thấy HSD một lô khác nhau giữa hai màn → mất tin; thấy "Chờ duyệt 7" vẫn 7 sau khi duyệt (danh sách chờ mẫu cố định).

## Quan sát nhỏ
Home iPhone có mũi tên quay lại và cũng có thanh tab; "Thiết lập kho" bị cắt dưới màn web (cuộn); "Hàng thực nhận" ở màn duyệt web nhỏ hơn câu hỏi quyết định (đúng thứ bậc); BJ-15 "Tổng giá trị cuối kỳ" chỉ chủ cửa hàng thấy (đúng).

## Câu hỏi để cân nhắc
Có nên cho màn kết quả K4 một "đỉnh" riêng khi hoàn tất thao tác kho lớn (nhận hàng, kiểm kê) — ví dụ một dòng "Tồn kho đã đổi: Nobivac 120 → 241" — thay vì cùng một thẻ key-value? Danh sách "Chờ duyệt" nên đọc từ các BJ như "Cần xử lý" chứ không còn là ba phiếu mẫu?
