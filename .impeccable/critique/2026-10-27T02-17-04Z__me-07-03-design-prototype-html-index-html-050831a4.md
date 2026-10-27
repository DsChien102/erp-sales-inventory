---
target: Theme 7 (Kho) prototype index.html — hai khung iPhone + web, G3-7 lần 1
total_score: 29
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 1
target_identity: "file:/Users/macbook/Documents/Đồ án/specs/themes/theme-07/03.design/prototype/html/index.html"
target_fingerprint: "sha256:7bde3ccb68303beeaf4ae2166bee85c1dbed307b1904ea8001b275b1dbb8ce25"
target_path: /Users/macbook/Documents/Đồ án/specs/themes/theme-07/03.design/prototype/html/index.html
timestamp: 2026-10-27T02-17-04Z
slug: me-07-03-design-prototype-html-index-html-050831a4
---
# Critique: Theme 7 (Kho) — prototype HTML v5.26.0 + sửa Phần 1 G3-7, hai khung (lần 1)
⚠️ DEGRADED: single-context (plan G3-7 A7 quy định một ngữ cảnh, không sub-agent, để điểm so được với 2026-10-15 / 2026-10-26: A xem 34 ảnh golden `tools/.golden-g3-7-fix` + `-web-fix`, B chạy `impeccable detect` sau đó)

## Điểm (so với 29/40 ngày 2026-10-26)
| # | Heuristic | iPhone | Web | Vấn đề chính |
|---|---|---|---|---|
| 1 | Hiển thị trạng thái | 3 | 3 | K3/K4 có mã, giờ; "Dữ liệu đến 21:30, 17/09/2026" ở mọi màn tồn. Nhưng Home "Chờ duyệt 7 · 3 nhận hàng…" giữ nguyên sau khi `SC_demo` đã duyệt nhận hàng và kiểm kê |
| 2 | Khớp thực tế | 3 | 3 | Còn "Đếm mù", "Căn cứ", "REC-UNKNOWN-01" (BJ-17 079) |
| 3 | Kiểm soát | 3 | 3 | Dò ngõ cụt 0/498 mỗi khung; Esc + trả focus 5/5 sheet; không hoàn tác duyệt |
| 4 | Nhất quán | 3 | 3 | Một họ K1–K7; nhưng số tiền lúc mono lúc sans trong cùng màn (046, 074), hàng key-value gãy dòng ở Tóm tắt web 074, ngày 056 iPhone tràn sát mép thẻ |
| 5 | Ngăn lỗi | 3 | 3 | Nút khoá có lý do ("Còn 3 mặt hàng chưa đếm"), sheet xác nhận, "Thống nhất giá ở Mua hàng rồi quay lại" |
| 6 | Nhận ra thay vì nhớ | 3 | 3 | HSD lô DH2509 nay một giá trị (30/09/2026) ở BJ-01 / BJ-05; chip có số; 044 chip "Chưa đếm 1" vẫn liệt kê 3 dòng |
| 7 | Linh hoạt | 2 | 3 | iPhone: "Lấy đủ" từng lô, chưa có thao tác hàng loạt; web: Tab / Esc / dòng là nút, nhưng 008 thứ tự Tab ngược thứ tự nhìn |
| 8 | Tối giản | 3 | 2 | Web lặp thông tin: 011 "Tóm tắt" lặp "Thông tin lần nhận"; 015 "Lô DH2507 · 121 hộp" cạnh cột "121 hộp"; 074 "Tóm tắt" lặp hai dòng điều chỉnh; 046 "Cần chú ý" lặp tổng. iPhone 048: tiêu đề "Đổi tình trạng / ST-260906-04" gãy 2 dòng, mỗi thẻ 3–4 dòng |
| 9 | Phục hồi lỗi | 3 | 3 | K3 "Chuyển sang xác minh" + "Về Kho"; mọi lỗi có lối ra đặt tên |
| 10 | Trợ giúp | 3 | 3 | Banner ngữ cảnh, "Cách tính", "Phương pháp" ở 074; chưa có trợ giúp tìm được |
| **Tổng** | | **29/40** | **29/40** | **Tốt (28–35)** — điểm = **29/40**, chưa đạt mục tiêu 32 |

Đối chiếu P1 bản 2026-10-26: HSD lô DH2509 mâu thuẫn **hết** (30/09/2026 "Cận hạn" ở 003 và 026); ngày nhận BJ-02 vs thẻ kho **hết** (16/09 cả hai). P2 chữ 9–10px: đo lúc chạy không còn trong app (luật CSS 9–10px còn nhưng bị đè; detector chỉ báo "Hover component" của vỏ harness).

## Đặc thù sản phẩm
Vẫn có chất riêng: số mono có dấu "+ / −", "Cần chú ý" lên đầu màn duyệt, câu hỏi quyết định ("Duyệt điều chỉnh 1 mặt hàng lệch của phiên KK-260915-02?"), thẻ kho có "Tồn đầu kỳ / Tồn cuối kỳ" và dòng nhận hàng nối về chứng từ. Điểm nhạt không đổi: K4 giống nhau ở mọi BJ; đỉnh demo (thẻ kho) đứng ở bước 84, còn bước cuối quay về Home với số chờ duyệt không đổi — kết thúc demo bằng một con số sai.

Detector (`impeccable detect` thư mục `html/`, 122 phát hiện — cùng hình với 2026-10-26): `overused-font` 39 (Inter là font DS), `design-system-*` 75 (34 ở `harness/workbench.css`), `tiny-text` 4 + `undersized-ui-text` 1 + `low-contrast` 1 ở `index.html` — đều thuộc vỏ harness ("Hover component", inspector 11px), `marquee` 1 (`.skeleton::after`, bỏ qua). Không phát hiện nào trong app mà A bỏ sót. Audit lúc chạy (Phần 1): tương phản còn 9 / 6 lỗi đều là nút `disabled` (miễn theo WCAG 1.4.3); vùng chạm còn lại có `::after` hoặc là liên kết nội dòng bảng web.

## Điểm tốt
- Màn duyệt (011 / 046) đặt câu hỏi + ngoại lệ + hai nút ở đầu / chân; web đưa bảng chứng từ – thực nhận – chênh lệch ra giữa.
- Một sổ kho thật: thẻ kho Oxytetracycline (SC_demo bước 84) có "Nhận hàng REC-260916-04 +24 · Chứng từ PN-260816-04" và "Điều chỉnh kiểm kê −2", cuối kỳ 34.
- Bàn phím web: hộp thoại đi vòng Tab / Shift+Tab, Esc đóng, focus về nút đã mở (5/5 sheet).

## Vấn đề ưu tiên
- **[P1] Home Kho "Chờ duyệt" là số mẫu cố định.** Cuối `SC_demo` (bước 86–87) Home vẫn "7 · 3 nhận hàng · 1 kiểm kê…" dù demo vừa duyệt nhận hàng và kiểm kê. Hội đồng thấy ngay ở bước cuối — đúng chỗ "end" của peak-end. Sửa: `pendingSummary` (`app/hub.js`) đọc trạng thái các BJ như "Cần chú ý". Lệnh: `harden`.
- **[P2] Web lặp thông tin cạnh nhau.** 011 "Tóm tắt" (chứng từ, NCC, kho, ngày) lặp nguyên thẻ "Thông tin lần nhận"; 015 dòng phụ "Lô DH2507 · 121 hộp" cạnh cột "Số lượng 121 hộp"; 074 "Tóm tắt" lặp hai dòng "Điều chỉnh…" đã ở thẻ chính, và gãy "Toàn bộ sản / phẩm", "31/08/2026 · / 23:59", "Bình quân cuối / kỳ". Lệnh: `distill`, `layout`.
- **[P2] iPhone: tiêu đề thẻ gãy và giá trị tràn.** 048 tiêu đề "{loại} {mã}" gãy 2 dòng vì badge dài chiếm chỗ ("Chờ duyệt sửa sai", "Đã giao khách"); 056 "07/09/2026 · 09:00" vượt lề phải của thẻ (390 vs 378). Lệnh: `layout`, `typeset`.
- **[P2] Bốn mục "kiểm lại" của G3-6 vẫn còn:** 037 (BJ-09 / BJ-10) tiêu đề "Việc tiếp theo" chỉ có một ghi chú, badge "Cách ly" lặp "2 hộp Cách ly"; 041 `REJECTED` thiếu "Lô" / "Số lượng" (biểu tượng đã đổi sang cảnh báo); 044 chip "Chưa đếm 1" vẫn hiện dòng đã đếm; 008 web Tab: Nhà cung cấp → Kho → Chọn tệp (cột phải) → ô xác nhận (cột trái). Lệnh: `clarify`, `adapt`.
- **[P3] K4: đoạn mô tả dính sát thẻ key-value** (083 / 041 / 012 khoảng 0–8px), thẻ kho web "Tồn đầu kỳ" cùng nền với hàng tiêu đề bảng. Lệnh: `polish`.

## Persona
**Casey (một tay, iPhone):** 048 mỗi thẻ 3–4 dòng vì tiêu đề gãy, phải cuộn nhiều; 026 "Lấy đủ" từng lô, không có "Lấy đủ tất cả". **Sam (bàn phím):** 008 web Tab nhảy sang cột phải rồi quay lại ô xác nhận bên trái. **Chủ cửa hàng (demo trước hội đồng):** duyệt xong quay về Home thấy "Chờ duyệt 7" không đổi → hỏi "vậy duyệt có ăn không?".

## Quan sát nhỏ
Home iPhone vừa có mũi tên quay lại vừa có thanh tab (chế độ BJ của harness); 003 web banner "Hết hàng" có khoảng trống dưới; 026 web nút "Lấy đủ" xếp dưới badge trong cùng ô; 011 `RECORDED` iPhone "10 hộp" màu mờ như bị khoá; 011 `RECORDED` web "1 dòng" lơ lửng giữa hàng tiêu đề.

## Câu hỏi để cân nhắc
Có cần thao tác hàng loạt trên iPhone (U4) để H7 iPhone lên 3? Có cho K4 nhận hàng / kiểm kê một dòng "Tồn kho đã đổi" (U5) làm đỉnh demo không?
