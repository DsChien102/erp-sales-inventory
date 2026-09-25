---
id: EVD-VALUATION-DESIGN-PARITY-v3.13.0
type: design-evidence
theme: theme-07
title: "Parity Design/HTML cụm giá trị và giá vốn — v3.13.0"
owner: DESIGN/BA/QA
status: PASS
version: v3.13.0
parent: v3.12.0
---
# EVD — Parity Design/HTML cụm BJ03 → BJ13 → BJ14 — v3.13.0

## 1. Mục tiêu

Đưa `BJ03 → BJ13 → BJ14` về parity với semantic v3.12.0 ở ba lớp: Screen Contract, bàn review/Inspect và HTML prototype; không tạo thêm quyết định nghiệp vụ.

## 2. Authority đã dùng

1. Nghiệp vụ: Decision/BJ/UC/BC/Domain v3.12.0.
2. UI: Figma file `QVJolM5tAdFKkhP7RIwe3y`, page `505:5890 — DS v2 - 02 Components`.
3. Component đã đọc trực tiếp: `VAppBar 547:1594`, `List Row 525:519`, `Summary Card 525:552`, `VBanner 526:4215`, `VBottomSheet 4695:6353` và các component liên quan trong DS registry.
4. Variable collections đã kiểm: `Color Primitive`, `Color Semantic`, `Dimension`, `Opacity`.

Giá trị trọng yếu xác nhận từ Figma: mobile `402×874`, edge `16`, touch minimum `44`, `Opacity/Disabled = 0.4`, `Opacity/Overlay = 0.48`, spacing `4/8/12/16/20/24/32`, radius `8/12/16/20`.

## 3. Topology sau redesign

| Journey | Màn active | Đã hợp nhất / retire |
|---|---|---|
| BJ03 | `SCR-014 → SCR-015 → SCR-017 → SCR-019` | `SCR-016`, legacy `SCR-018` |
| BJ13 | `SCR-085 → SCR-086 → SCR-088 → SCR-089` | `SCR-087` |
| BJ14 | `SCR-072 → SCR-074 → SCR-077` | `SCR-073`, `SCR-075`, `SCR-076` |

## 4. Quyết định thiết kế đã kiểm chứng

### BJ03

- Danh sách nói theo **công việc cần xử lý**, không theo trạng thái kỹ thuật của hệ thống định giá.
- Nhận theo chứng từ dùng căn cứ thương mại chỉ đọc; chênh lệch thương mại không có control cho phép Theme 7 tự chọn nguồn để bỏ qua vấn đề.
- Nhập nhanh có `Thêm căn cứ giá` trong `VBottomSheet`, không phụ thuộc Theme 10/hóa đơn để hoàn thành BJ03.
- Rà soát dùng `Đơn giá ghi nhận ban đầu` và `Giá trị nhập ban đầu`; chưa tạo giá vốn chính thức.

### BJ13

- Nguồn + phạm vi áp dụng + cách phân bổ + kết quả dự kiến nằm trong cùng một công việc tại `SCR-086`.
- Điều chỉnh thể hiện rõ tăng/giảm; product copy không còn bó hẹp thành “chi phí mua đến muộn”.
- Kết quả đánh dấu phạm vi cần cập nhật giá vốn và không sửa lịch sử BJ03.

### BJ14

- Entry là danh sách công việc: cập nhật giá vốn, chốt kỳ hoặc công việc bị chặn.
- Phương pháp tính giá vốn là thông tin chỉ đọc từ chính sách tenant; phương pháp còn lại chỉ dùng đối chiếu.
- Thiết lập cần thiết, tính, vấn đề chặn và rà soát nằm trong cùng `SCR-074`; xác nhận công bố dùng `VBottomSheet`.
- Màn kết quả không lộ lô xử lý, event hay version kỹ thuật không cần thiết cho người dùng.

## 5. Gate Design System / UX

- Không tạo component core mới.
- Danh sách dùng `List Row`; fact dùng `Info Row/Key-value Row`; `Summary Card` chỉ dùng cho một summary thật sự; `VBanner` chỉ dùng cho feedback có ý nghĩa.
- Disabled dùng opacity `0.4`, không tạo màu disabled riêng.
- Bottom Sheet dùng handle `48×4`, top radius `20`, horizontal padding `16`, bottom safe area `44`.
- Product viewport giữ `402×874`, edge `16`, touch target tối thiểu `44`.
- Định danh kỹ thuật nằm trong Inspect/audit, không nằm trong Product UI.

## 6. Bằng chứng runtime/visual

- `ALL-FLOWS-RUNTIME-SMOKE-v3.13.0.json`: PASS — **86** route renders, **0** browser error.
- `VALUATION-FLOW-E2E-v3.13.0.json`: PASS — **24/24**.
- `VALUATION-VISUAL-INTEGRITY-v3.13.0.json`: PASS — **16/16**.
- `VALUATION-ADVERSARIAL-QA-v3.13.0.json`: PASS — **7/7**.
- Contact sheet: `03.design/prototype/html/qa/v313-valuation-captures/VALUATION-CONTACT-SHEET-v3.13.0.png`.

## 7. Kết luận

**PASS.** Cụm BJ03/BJ13/BJ14 đạt parity giữa semantic v3.12.0, Screen Contract, Figma Design System và HTML prototype trong phạm vi v3.13.0.
