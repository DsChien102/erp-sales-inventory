---
id: BJ-13
type: business-journey
theme: theme-07
title: "Điều chỉnh giá trị hàng nhập"
owner: BA
status: IN_REVIEW
aligned_to: BJ.template.md
source_baseline: v4.6.0
ui_flow: UIF-13
---

# BJ-13 — Điều chỉnh giá trị hàng nhập

## 1. Tổng quan nghiệp vụ & Bối cảnh

Ghi nhận các business fact xuất hiện hoặc trở nên hợp lệ sau initial valuation làm tăng hoặc giảm giá trị hàng nhập, với nguồn, phạm vi, phân bổ và kỳ rõ ràng; không sửa giá trị ban đầu hoặc giao dịch lịch sử.

**Bắt đầu khi:** Có thành phần giá trị mới hoặc thay đổi hợp lệ sau khi target đã hoàn tất BJ03.

**Kết thúc khi:** Adjustment được ghi đúng một lần và Product + posting period bị ảnh hưởng được đánh dấu cần cập nhật giá vốn; hoặc yêu cầu bị chặn rõ nguyên nhân.

**Không bao gồm:** Thành phần đã đủ căn cứ trước initial valuation; forecast chưa phát sinh; sửa lỗi nhập liệu; công bố giá vốn.

## 2. Tác nhân và trách nhiệm

| Tác nhân | Trách nhiệm | Phạm vi thẩm quyền |
|---|---|---|
| Kế toán mua hàng hoặc kế toán kho | Ghi signed adjustment khi business fact hợp lệ xuất hiện/thay đổi sau BJ03 và phân bổ về đúng receipt exposure. | Không dùng BJ13 để sửa lỗi nhập liệu; không ghi projected benefit vào ledger. |

## 3. Sơ đồ hành trình nghiệp vụ

```mermaid
flowchart TD
    Begin([Bắt đầu: có fact điều chỉnh sau BJ03]) --> U1["UC-13-01 — Ghi nhận điều chỉnh giá trị hàng nhập"]
    U1 --> End([Kết thúc: adjustment đã ghi hoặc bị chặn rõ lý do])
```

## 4. Bản đồ Use Case

| UC — Tên | Mục tiêu | Tác nhân | Đầu vào / Bắt đầu khi | Kết quả | Tiếp tục |
|---|---|---|---|---|---|
| [UC-13-01](../use-cases/UC-13-01-ghi-nhan-dieu-chinh-gia-tri-hang-nhap.md) — Ghi nhận điều chỉnh giá trị hàng nhập | Ghi một khoản tăng/giảm giá trị phát sinh sau BJ03 và phân bổ về đúng hàng đã nhận | Kế toán mua hàng hoặc kế toán kho có quyền tài chính | Có thành phần giá trị mới hoặc thay đổi hợp lệ sau BJ03: chi phí vận chuyển, bảo hiểm, thuế/phí không thu hồi, chênh lệch giá hóa đơn, giảm giá, chiết khấu, credit note… | Điều chỉnh có nguồn, dấu tăng/giảm, phạm vi phân bổ và kỳ ghi nhận rõ; sản phẩm + kỳ bị ảnh hưởng được đánh dấu cần cập nhật giá vốn | Kết thúc BJ13; chuyển phạm vi cần tính lại sang BJ14 |

## 5. Bàn giao và ranh giới liên quan

| Nơi nhận / Nơi cung cấp | Dữ kiện hoặc trách nhiệm bàn giao | Điều kiện bàn giao / tiếp tục |
|---|---|---|
| Theme 10 / nguồn có thẩm quyền | Thành phần thương mại đã thực sự phát sinh hoặc thay đổi, kèm source/version | Dữ liệu dự kiến chỉ dùng mô phỏng; chưa được ghi vào giá trị tồn thực tế |
| BJ14 | Sản phẩm + kỳ cần tính lại giá vốn | Sau khi điều chỉnh giá trị commit thành công |

## 6. Liên kết thiết kế

- **UI Flow canonical:** [UIF-13 — Điều chỉnh giá trị hàng nhập](../../../03.design/flows/UIF-13-BJ-13.md)
- BJ này chỉ sở hữu **business boundary, mục tiêu, UC/handoff và acceptance ở cấp hành trình**.
- Screen-to-screen routing, entry/terminal, actor handoff, state/recovery và transition nằm tại `UIF-13`; anatomy/action chi tiết nằm tại `03.design/screens/`.
- Không copy Screen Flow vào BJ để tránh trùng với UC/UIF và để redesign UI không làm thay đổi semantic của Journey.

## 7. Nghiệm thu hành trình (Journey Acceptance)

| ID | Điều kiện ở cấp hành trình | Kết quả cần bảo đảm | UC / BC liên quan |
|---|---|---|---|
| JA-01 | Business fact xuất hiện sau BJ03 và có stable source identity | Adjustment giữ source/version, dấu `+/-`, target và phương pháp phân bổ; không sửa ReceiptValuation/value movement gốc | UC-13-01 / BC-IV-04 |
| JA-02 | Quyền lợi mới chỉ dự kiến hoặc lỗi do người dùng nhập sai fact cũ | Không ghi BJ13: forecast chỉ mô phỏng; lỗi nhập liệu đi BJ11/correction | UC-13-01 / BC-IV-04 |
| JA-03 | Kỳ gốc đã khóa | Adjustment được ghi ở kỳ mở theo policy nhưng vẫn giữ liên kết kỳ gốc để đối soát | UC-13-01 / BC-IV-04 |
| JA-04 | Adjustment commit thành công | Product + posting period bị ảnh hưởng được đánh dấu cần BJ14 tính lại; không tự công bố giá vốn | UC-13-01 / BC-IV-04 |
| JA-05 | Dựng phân bổ | `allocation_i = signed amount × metric_i / Σmetric`; metric phải hợp lệ và so sánh được trên toàn scope, tổng metric bằng 0 thì chặn; residual theo stable exposure order, không chia đều fallback | UC-13-01 / BC-IV-06 |

## 8. Truy vết

| Nguồn | Vai trò đối với hành trình |
|---|---|
| [KB-KGV-015 — Đơn giá tồn kho chính thức và tổng giá trị ghi sổ](../../../01.knowledge/know-how/KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md); [KB-KGV-018 — Đối soát giá vốn cuối kỳ và cập nhật đột xuất giữa kỳ](../../../01.knowledge/know-how/KB-KGV-018-doi-soat-gia-von-cuoi-ky-va-cap-nhat-dot-xuat-giua-ky.md); [KB-KGV-019 — Các thành phần hình thành giá trị hàng nhập](../../../01.knowledge/know-how/KB-KGV-019-cac-thanh-phan-hinh-thanh-gia-tri-hang-nhap.md); [KB-KGV-043 — Kịch bản chiết khấu mua hàng theo kỳ](../../../01.knowledge/know-how/KB-KGV-043-kich-ban-chiet-khau-mua-hang-theo-ky.md) | **Bài tri thức cốt lõi** giúp hiểu nền nghiệp vụ của Journey; rule triển khai vẫn theo Decision/BJ/UC/BC canonical |
| [Decision Register](../../../01.knowledge/decisions/decision-register.md) — G07 | Nguồn quyết định nghiệp vụ và trạng thái hiệu lực |
| `DOM-IV`, `DOM-IO` | Domain authority và invariants dùng cho Journey |
| [Use Case Map](../use-cases/00-use-case-map.md) | Danh mục UC canonical của Theme 7 |
