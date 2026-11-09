---
id: BJ-06
type: business-journey
theme: theme-07
title: "Tiếp nhận và phân loại hàng khách trả"
owner: BA
status: IN_REVIEW
aligned_to: BJ.template.md
source_baseline: v4.0.0
ui_flow: UIF-06
---

# BJ-06 — Tiếp nhận và phân loại hàng khách trả

## 1. Tổng quan nghiệp vụ & Bối cảnh

Ghi đúng **hàng thực tế quay về từ khách**, liên kết được với lần giao gốc, không nhận vượt trần và không đưa hàng trở lại bán trước khi phân loại. Việc nhận vật lý và việc phân loại là hai mốc khác nhau trong cùng hành trình.

**Bắt đầu khi:** Có return intent hợp lệ và hàng thực tế được khách giao lại.

**Kết thúc khi:** Hàng thực nhận đã được ghi vào `RETURN_PENDING` và được phân loại; hoặc vẫn chờ phân loại/ngoại lệ với tác động đã được nói rõ; hoặc không nhận hàng.

**Không bao gồm:** Khách có được đổi/trả về mặt thương mại, số tiền hoàn, phương thức hoàn tiền hoặc cách xử lý combo ở cấp đơn bán.

## 2. Tác nhân và trách nhiệm

| Tác nhân | Trách nhiệm | Phạm vi thẩm quyền |
|---|---|---|
| Thủ kho; bộ phận trả hàng cung cấp ý định thương mại | Xác minh hàng thực nhận, truy vết giao dịch gốc và phân loại hàng khách trả. | Theme 7 chỉ sở hữu phiếu nhận hàng/physical state; quyết định hoàn tiền/thương mại thuộc Theme nguồn. |
| Người duyệt: `is_owner` hoặc vai trò `store_owner`, khác người lập (trừ ngoại lệ `is_owner` tự duyệt) | Duyệt ngoại lệ lô/truy vết hàng khách trả. | **Người duyệt** là `is_owner` hoặc vai trò `store_owner`, khác người lập. **Ngoại lệ:** cửa hàng chỉ có một chủ, nên `is_owner` lập ngoại lệ hàng trả thì vẫn gửi duyệt rồi tự duyệt ở màn duyệt (không có đường ghi nhận thẳng); lịch sử ghi người duyệt "Chủ cửa hàng". |

## 3. Sơ đồ hành trình nghiệp vụ

```mermaid
flowchart TD
    Begin([Bắt đầu: return intent + hàng thực tế]) --> U1["UC-06-01 — Xác minh hàng được phép nhận trả"]
    U1 --> T{"Truy vết đủ?"}
    T -->|Không| U2["UC-06-02 — Xử lý ngoại lệ truy vết"]
    U2 --> T
    T -->|Có| U3["UC-06-03 — Ghi nhận hàng khách trả"]
    U3 --> U4["UC-06-04 — Phân loại hàng thực nhận"]
    U4 --> End([Kết thúc])
```

## 4. Bản đồ Use Case

| UC — Tên | Mục tiêu | Tác nhân | Đầu vào / Bắt đầu khi | Kết quả | Tiếp tục |
|---|---|---|---|---|---|
| [UC-06-01](../use-cases/UC-06-01-xac-minh-hang-duoc-phep-nhan-tra.md) — Xác minh hàng được phép nhận trả | Hàng đủ điều kiện nhận, cần ngoại lệ hoặc bị từ chối; Return validation result. | Thủ kho; bộ phận trả hàng cung cấp ý định thương mại | Có return intent và hàng vật lý | Hàng đủ điều kiện nhận, cần ngoại lệ hoặc bị từ chối; Return validation result. | UC-06-02 |
| [UC-06-02](../use-cases/UC-06-02-xu-ly-ngoai-le-truy-vet.md) — Xử lý ngoại lệ truy vết | Ngoại lệ được chấp thuận hoặc từ chối có bằng chứng; Trace exception decision. | Thủ kho; bộ phận trả hàng cung cấp ý định thương mại | Lô thực nhận không khớp lô đã xuất | Ngoại lệ được chấp thuận hoặc từ chối có bằng chứng; Trace exception decision. | UC-06-03 |
| [UC-06-03](../use-cases/UC-06-03-ghi-nhan-hang-khach-tra.md) — Ghi nhận hàng khách trả | Toàn yêu cầu được commit vào `RETURN_PENDING` hoặc không có gì commit; Phiếu nhận hàng của hàng trả có quantity/value provenance. | Thủ kho; bộ phận trả hàng cung cấp ý định thương mại | Các dòng thực nhận đã hợp lệ | Toàn yêu cầu được commit vào `RETURN_PENDING` hoặc không có gì commit; Phiếu nhận hàng của hàng trả có quantity/value provenance. | UC-06-04 |
| [UC-06-04](../use-cases/UC-06-04-phan-loai-hang-thuc-nhan.md) — Phân loại hàng thực nhận | Toàn lượng được phân loại hoặc giữ pending với việc cần xử lý; Classification result. | Thủ kho; bộ phận trả hàng cung cấp ý định thương mại | Có lượng `RETURN_PENDING` | Toàn lượng được phân loại hoặc giữ pending với việc cần xử lý; Classification result. | Kết thúc / theo nhánh trên sơ đồ |

## 5. Bàn giao và ranh giới liên quan

| Nơi nhận / Nơi cung cấp | Dữ kiện hoặc trách nhiệm bàn giao | Điều kiện bàn giao / tiếp tục |
|---|---|---|
| Theme 5 / return source | Return intent và source sale lineage | Nguồn cho phép tiếp nhận |
| BJ09 | Hàng sau nhận cần phân loại trạng thái | Phiếu nhận hàng vật lý đã ghi |

## 6. Liên kết thiết kế

- **UI Flow canonical:** [UIF-06 — Tiếp nhận và phân loại hàng khách trả](../../../03.design/flows/UIF-06-BJ-06.md)
- BJ này chỉ sở hữu **business boundary, mục tiêu, UC/handoff và acceptance ở cấp hành trình**.
- Screen-to-screen routing, entry/terminal, actor handoff, state/recovery và transition nằm tại `UIF-06`; anatomy/action chi tiết nằm tại `03.design/screens/`.
- Không copy Screen Flow vào BJ để tránh trùng với UC/UIF và để redesign UI không làm thay đổi semantic của Journey.

## 7. Nghiệm thu hành trình (Journey Acceptance)

| ID | Điều kiện ở cấp hành trình | Kết quả cần bảo đảm | UC / BC liên quan |
|---|---|---|---|
| JA-01 | Journey bắt đầu từ đúng trigger và actor có quyền | Kết quả chỉ được ghi trong phạm vi authority của Theme 7; source ngoài Theme không bị sửa ngầm | UC-06-01 / BC liên quan |
| JA-02 | Một nhánh bị từ chối, blocked hoặc chưa xác định | Không được báo thành công hoặc tạo tác động bán phần; hướng xử lý/owner tiếp theo phải rõ | UC-06-01…UC-06-04 |
| JA-03 | Journey hoàn tất thành công | Kết quả cuối có provenance, thời điểm/phạm vi và đủ dữ kiện cho consumer tiếp theo | UC-06-04 / Domain ledger |

## 8. Truy vết

| Nguồn | Vai trò đối với hành trình |
|---|---|
| [KB-KGV-012 — Hàng khách trả từ tiếp nhận đến phân loại](../../../01.knowledge/know-how/KB-KGV-012-hang-khach-tra-tu-tiep-nhan-den-phan-loai.md); [KB-KGV-020 — Định giá hàng trả, tiêu hủy và chênh lệch thừa thiếu](../../../01.knowledge/know-how/KB-KGV-020-dinh-gia-hang-tra-tieu-huy-va-chenh-lech-thua-thieu.md); [KB-KGV-025 — Danh tính và vòng đời của một lô hàng](../../../01.knowledge/know-how/KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md); [KB-KGV-035 — Combo bán hàng và tồn kho theo thành phần](../../../01.knowledge/know-how/KB-KGV-035-combo-ban-hang-va-ton-kho-theo-thanh-phan.md) | **Bài tri thức cốt lõi** giúp hiểu nền nghiệp vụ của Journey; rule triển khai vẫn theo Decision/BJ/UC/BC canonical |
| [Decision Register](../../../01.knowledge/decisions/decision-register.md) — Decision Register theo UC/BC | Nguồn quyết định nghiệp vụ và trạng thái hiệu lực |
| `DOM-IO` | Domain authority và invariants dùng cho Journey |
| [Use Case Map](../use-cases/00-use-case-map.md) | Danh mục UC canonical của Theme 7 |
