---
target: Theme 7 (Kho) prototype index.html — hai khung iPhone + web, G3-7 lần 2 (sau B vòng 1)
total_score: 30
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 0
target_identity: "file:/Users/macbook/Documents/Đồ án/specs/themes/theme-07/03.design/prototype/html/index.html"
target_fingerprint: "sha256:7bde3ccb68303beeaf4ae2166bee85c1dbed307b1904ea8001b275b1dbb8ce25"
target_path: /Users/macbook/Documents/Đồ án/specs/themes/theme-07/03.design/prototype/html/index.html
timestamp: 2026-10-27T02-35-15Z
slug: me-07-03-design-prototype-html-index-html-050831a4
---
# Critique: Theme 7 (Kho) — prototype HTML sau B vòng 1 G3-7, hai khung (lần 2)
⚠️ DEGRADED: single-context (plan G3-7 A7: một ngữ cảnh, không sub-agent, để so được với 2026-10-26 và lần 1 2026-10-27T02-17-04Z; A xem cùng bộ ảnh ở `tools/.golden-g3-7-b` + `-web-b`, B chạy `impeccable detect` sau đó)

## Điểm (lần 1: 29 / 29)
| # | Heuristic | iPhone | Web | Thay đổi so với lần 1 |
|---|---|---|---|---|
| 1 | Hiển thị trạng thái | **4** | **4** | Home "Chờ duyệt" đọc từ BJ: cuối `SC_demo` "6 · 2 nhận hàng…" (trước 7 · 3). Mọi màn tồn có "Dữ liệu đến …", K3 có "Lần kiểm tra gần nhất", lấy hàng / kiểm kê có thanh tiến độ, chip có số khớp danh sách (044) |
| 2 | Khớp thực tế | 3 | 3 | BJ-17 079 gọi hồ sơ theo nghiệp vụ ("Tiêu hủy TH-260906-02 · …") thay "REC-UNKNOWN-01"; còn "Đếm mù", "Căn cứ" (chữ spec) |
| 3 | Kiểm soát | 3 | 3 | Không đổi: dò ngõ cụt 0/498, Esc + trả focus; không hoàn tác duyệt |
| 4 | Nhất quán | 3 | 3 | Hàng nhãn–giá trị BJ-14 / BJ-15 theo bề rộng nội dung (hết "Toàn bộ sản / phẩm", hết ngày tràn 056); K4 mọi BJ cùng khoảng mô tả–thẻ 12px. Còn: tiền mono / sans lẫn trong cùng màn (046, 074, 015) |
| 5 | Ngăn lỗi | 3 | 3 | Không đổi |
| 6 | Nhận ra thay vì nhớ | 3 | 3 | 041 `REJECTED` có Lô + Số lượng; 044 rời ô thì dòng đã đếm rời "Chưa đếm". Còn: 037 badge "Cách ly" lặp "2 hộp Cách ly"; 079 iPhone phụ đề cắt "… · 5 …" |
| 7 | Linh hoạt | 2 | 3 | Không đổi — iPhone vẫn chưa có thao tác hàng loạt (U4) |
| 8 | Tối giản | 3 | **3** | Web: 015 bỏ "· 121 hộp" lặp cột, tên sản phẩm một dòng; 074 Tóm tắt hết gãy. Còn: 011 "Tóm tắt" lặp thẻ "Thông tin lần nhận", 074 "Tóm tắt" lặp hai dòng điều chỉnh; iPhone 048 tiêu đề gãy 2 dòng |
| 9 | Phục hồi lỗi | 3 | 3 | Không đổi |
| 10 | Trợ giúp | 3 | 3 | Không đổi |
| **Tổng** | | **30/40** | **31/40** | **Tốt (28–35)** — điểm = **30/40**, chưa đạt 32 |

## Đặc thù sản phẩm
Không đổi so với lần 1; điểm "end" của demo nay đúng (Home giảm số chờ duyệt sau khi duyệt). Đỉnh demo vẫn là thẻ kho; K4 vẫn một khuôn cho mọi BJ.

Detector (`impeccable detect` thư mục `html/`): cùng 122 phát hiện như lần 1 (vỏ harness, Inter là font DS, token advisory) — không có phát hiện mới trong app. Audit lúc chạy: tương phản 9 / 6 (nút `disabled`), vùng chạm 10 / 42 (chip, nút đóng toast, `cap-link-button` — nay có `::after` 84×40 trên web — và liên kết nội dòng bảng web).

## Điểm tốt
- Số "Chờ duyệt" sống: duyệt nhận hàng ở `SC_demo` → Home và danh sách "Chờ duyệt" bớt đúng phiếu đó.
- Thẻ tóm tắt BJ-14 web đọc một dòng mỗi hàng; ngày ghi nhận 056 iPhone nằm trong lề.
- BJ-08: gõ số thì dòng giữ chỗ, rời ô thì dòng đã đếm rời "Chưa đếm" — không nhảy khi đang nhập.

## Vấn đề ưu tiên
- **[P2] iPhone chưa có thao tác hàng loạt** (H7 = 2): 026 "Lấy đủ" từng lô, 044 không có "đếm như số trước", 015 tick từng dòng. Đề xuất U4 — đổi luồng, cần duyệt.
- **[P2] Web lặp thông tin giữa thẻ chính và "Tóm tắt"**: 011 (chứng từ, NCC, kho, ngày hai lần), 074 (hai dòng điều chỉnh hai lần). Bỏ một bên là đổi bố cục đã duyệt (brief BJ-02 / BJ-14).
- **[P2] iPhone 048 tiêu đề "{loại} {mã}" gãy 2 dòng** vì badge dài ở bên phải; sửa = đưa badge xuống dưới tiêu đề (đổi khuôn dòng K6) hoặc rút chữ badge (chữ spec).
- **[P3] Tiền mono / sans lẫn**: thẻ số liệu và "Tóm tắt" dùng Inter, bảng dùng mono (046, 074, 015).
- **[P3] 079 iPhone phụ đề bị cắt** "Tiêu hủy TH-260906-02 · Găng tay khám Nitrile · 5 …".

## Persona
**Casey (một tay, iPhone):** vẫn phải chạm "Lấy đủ" từng lô; 048 thẻ cao vì tiêu đề gãy. **Sam (bàn phím):** 008 Tab theo thứ tự hàng (Nhà cung cấp → Chọn tệp → ô xác nhận) — ổn. **Chủ cửa hàng (demo):** duyệt xong thấy số chờ duyệt giảm — tin được.

## Câu hỏi để cân nhắc
Làm U4 (thao tác hàng loạt iPhone) để H7 iPhone lên 3? Cho phép gộp "Tóm tắt" với thẻ thông tin ở 011 / 074 web, và đưa badge xuống dưới tiêu đề ở danh sách K6 iPhone? Có thêm dòng "Tồn kho đã đổi" ở K4 nhận hàng / kiểm kê (U5)?
