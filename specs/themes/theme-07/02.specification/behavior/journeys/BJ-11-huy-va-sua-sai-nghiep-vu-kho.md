---
id: BJ-11
type: business-journey
theme: theme-07
title: "Hủy và sửa sai nghiệp vụ kho"
owner: BA
status: IN_REVIEW
aligned_to: BJ.template.md
source_baseline: v3.12.0
---

# BJ-11 — Hủy và sửa sai nghiệp vụ kho

## 1. Tổng quan nghiệp vụ & Bối cảnh

Cho phép dừng yêu cầu chưa thực thi hoặc sửa sai operation đã hoàn tất mà vẫn bảo toàn **operation gốc, movement ledger, kỳ kế toán và toàn bộ chuỗi truy vết**.

**Bắt đầu khi:** Nguồn yêu cầu hủy operation, hoặc người có quyền phát hiện operation kho đã hoàn tất sai.

**Kết thúc khi:** Operation chưa thực thi được hủy không tác động tồn; correction/reversal được commit; hoặc yêu cầu bị chặn/chờ đối soát mà lịch sử gốc không thay đổi.

**Không bao gồm:** Không sở hữu quyết định thuộc Theme/Domain khác.

## 2. Tác nhân và trách nhiệm

| Tác nhân | Trách nhiệm | Phạm vi thẩm quyền |
|---|---|---|
| Người vận hành kho và người duyệt sửa sai | Phân loại cancel/correction, chuẩn bị phương án, duyệt và ghi correction chain bất biến. | Không sửa transaction đã hoàn tất tại chỗ; phải dùng cancellation/correction/reconciliation đúng loại. |

## 3. Sơ đồ hành trình nghiệp vụ

```mermaid
flowchart TD
    Begin([Bắt đầu: yêu cầu hủy/sửa sai]) --> U1["UC-11-01 — Xác định đường xử lý"]
    U1 --> D{"Operation đã thực thi?"}
    D -->|Chưa| U2["UC-11-02 — Hủy operation chưa thực thi"]
    U2 --> End([Kết thúc])
    D -->|Đã thực thi| U3["UC-11-03 — Chuẩn bị phương án correction"]
    U3 --> U4["UC-11-04 — Phê duyệt correction"]
    U4 -->|Duyệt| U5["UC-11-05 — Ghi correction chain"]
    U4 -->|Từ chối| End
    U5 --> End
```

## 4. Bản đồ Use Case

| UC — Tên | Mục tiêu | Tác nhân | Đầu vào / Bắt đầu khi | Kết quả | Tiếp tục |
|---|---|---|---|---|---|
| [UC-11-01](../use-cases/UC-11-01-xac-dinh-duong-xu-ly.md) — Xác định đường xử lý | Chọn cancel, reconcile, correction hoặc không có tác động để đảo; Treatment route. | Người vận hành kho và người duyệt sửa sai | Có operation và yêu cầu hủy/sửa | Chọn cancel, reconcile, correction hoặc không có tác động để đảo; Treatment route. | UC-11-02 |
| [UC-11-02](../use-cases/UC-11-02-huy-operation-chua-thuc-thi.md) — Hủy operation chưa thực thi | Operation `CANCELLED`, lock/work được giải phóng, không movement/value; Cancellation result. | Người vận hành kho và người duyệt sửa sai | Operation ở trạng thái cho phép hủy | Operation `CANCELLED`, lock/work được giải phóng, không movement/value; Cancellation result. | UC-11-03 |
| [UC-11-03](../use-cases/UC-11-03-chuan-bi-phuong-an-correction.md) — Chuẩn bị phương án correction | Phương án khả thi đủ căn cứ hoặc bị chặn; Correction proposal. | Người vận hành kho và người duyệt sửa sai | Operation đã hoàn tất và có correction intent | Phương án khả thi đủ căn cứ hoặc bị chặn; Correction proposal. | UC-11-04 |
| [UC-11-04](../use-cases/UC-11-04-phe-duyet-correction.md) — Phê duyệt correction | Duyệt hoặc từ chối có lý do; Approval decision. | Người vận hành kho và người duyệt sửa sai | Proposal có snapshot rủi ro | Duyệt hoặc từ chối có lý do; Approval decision. | UC-11-05 |
| [UC-11-05](../use-cases/UC-11-05-ghi-correction-chain.md) — Ghi correction chain | Operation bù/thay thế cùng liên kết được commit hoặc không có gì commit; Immutable correction chain. | Người vận hành kho và người duyệt sửa sai | Proposal được duyệt và vẫn khả thi | Operation bù/thay thế cùng liên kết được commit hoặc không có gì commit; Immutable correction chain. | Kết thúc / theo nhánh trên sơ đồ |

## 5. Bàn giao và ranh giới liên quan

| Nơi nhận / Nơi cung cấp | Dữ kiện hoặc trách nhiệm bàn giao | Điều kiện bàn giao / tiếp tục |
|---|---|---|
| Journey nguồn | Operation gốc và bằng chứng sai/hủy | Giữ immutable lineage |
| BJ14/BJ16/BJ17 | Dirty scope hoặc reconciliation/recovery | Theo loại correction/result |

## 6. Luồng giao diện cấp hành trình

| Chặng / UC | Chuyển màn hình | Hành động nghiệp vụ |
|---|---|---|
| UC-11-01 — Xác định đường xử lý | `SCR-048`, `SCR-049`, `SCR-050` | Phân loại một yêu cầu sửa sai để chọn đúng đường xử lý: hủy operation chưa thực thi, correction bất biến, hoặc đối soát/recovery. |
| UC-11-02 — Hủy operation chưa thực thi | `SCR-052`, `SCR-053` | Hủy operation chưa thực thi khi đã chứng minh chưa có authoritative effect, không dùng cancellation để đảo transaction đã commit. |
| UC-11-03 — Chuẩn bị phương án correction | `SCR-049`, `SCR-052` | Lập phương án correction cho transaction đã commit bằng các effect đảo/điều chỉnh có liên kết, không sửa dữ liệu lịch sử tại chỗ. |
| UC-11-04 — Phê duyệt correction | `SCR-051`, `SCR-053` | Phê duyệt hoặc từ chối correction proposal dựa trên original effect, phương án và evidence hiện hành. |
| UC-11-05 — Ghi correction chain | `SCR-049`, `SCR-053` | Ghi correction chain bất biến cho proposal đã được phép, tạo đúng effect đảo/điều chỉnh mà không sửa transaction gốc. |

## 7. Nghiệm thu hành trình (Journey Acceptance)

| ID | Điều kiện ở cấp hành trình | Kết quả cần bảo đảm | UC / BC liên quan |
|---|---|---|---|
| JA-01 | Journey bắt đầu từ đúng trigger và actor có quyền | Kết quả chỉ được ghi trong phạm vi authority của Theme 7; source ngoài Theme không bị sửa ngầm | UC-11-01 / BC liên quan |
| JA-02 | Một nhánh bị từ chối, blocked hoặc chưa xác định | Không được báo thành công hoặc tạo tác động bán phần; hướng xử lý/owner tiếp theo phải rõ | UC-11-01…UC-11-05 |
| JA-03 | Journey hoàn tất thành công | Kết quả cuối có provenance, thời điểm/phạm vi và đủ dữ kiện cho consumer tiếp theo | UC-11-05 / Domain ledger |

## 8. Truy vết

| Nguồn | Vai trò đối với hành trình |
|---|---|
| [Decision Register](../../../01.knowledge/decisions/decision-register.md) — Decision Register theo UC/BC | Nguồn quyết định nghiệp vụ và trạng thái hiệu lực |
| `DOM-IC`, `DOM-IO` | Domain authority và invariants dùng cho Journey |
| [Use Case Map](../use-cases/00-use-case-map.md) | Danh mục UC canonical của Theme 7 |
