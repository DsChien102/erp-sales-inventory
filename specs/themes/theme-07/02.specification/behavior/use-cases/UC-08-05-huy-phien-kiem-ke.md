---
id: UC-08-05
type: use-case
theme: theme-07
title: "Hủy phiên kiểm kê"
owner: BA
status: IN_REVIEW
source_baseline: v3.10.1
---
# UC-08-05 — Hủy phiên kiểm kê

## 1. Mục tiêu và outcome



**Kết quả thành công:** 

## 2. Ranh giới

### 2.1 Bắt đầu khi



### 2.2 Kết thúc khi



### 2.3 Không bao gồm

Phạm vi không thuộc UC được giữ theo BJ cha và các contract nguồn; migration không bổ sung negative scope mới.

## 3. Actor, trigger và điều kiện trước

- **Actor:** 
- **Trigger:** 
- **Điều kiện trước:** 

## 4. Hành vi nghiệp vụ

## 5. Ngoại lệ và thất bại

**Không thành công:** 

## 6. Ảnh hưởng nghiệp vụ



## 7. Behavioral Contract


## 8. Screen liên quan



## 9. Acceptance Scenarios



## 10. Truy vết




### Nguồn v3.10.1 — UC-08-05 — Hủy phiên kiểm kê

> **Hành trình:** [BJ-08](../journeys/BJ-08-kiem-ke-va-ieu-chinh-chenh-lech.md)  
> **Actor:** Người có quyền hủy đúng session context  
> **BC/API:** `BC-IC-08 / API-C-27`

### 1. Tổng quan

| Mục | Hợp đồng |
|---|---|
| Trigger | Session chưa final, đang ở count/recount/blocker context và cancellation policy cho phép |
| Mục tiêu | Dừng phiên mà không điều chỉnh tồn, giữ toàn bộ evidence và giải phóng lock |
| Thành công | `CANCELLED`; no adjustment; immutable submissions/cases retained; lock released |
| Guard | Lý do bắt buộc; không cancel khi approval/adjustment command đang UNKNOWN hoặc commit đã hoàn tất |
| UNKNOWN | Same cancellation identity; verify current session/lock finality trước retry |

### 2. Behavioral contract

- Cancellation là mutation của **một session cụ thể**, không phải destructive action trên browse list.
- Không xóa CountScopeSnapshot, StockCountSubmission, ApprovalCase hoặc audit đã có.
- Nếu cancel commit thành công: session CANCELLED + lock release + receipt/outbox atomic.
- Không tạo InventoryOperation adjustment.

### 3. Acceptance

<a id="as-uc-08-05-01"></a>
- UI chỉ expose cancel trong session context `SCR-044/SCR-045` khi policy cho phép.
<a id="as-uc-08-05-02"></a>
- Lý do thiếu → validation, effect NONE.
<a id="as-uc-08-05-03"></a>
- Success result hiển thị no-adjustment + lock released.
<a id="as-uc-08-05-04"></a>
- UNKNOWN handoff/verify cùng identity.
### 4. UI trace

- [SCR-044](../../../03.design/screens/SCR-044.md), [SCR-045](../../../03.design/screens/SCR-045.md): contextual `ACT-09-CANCEL`.
- [SCR-042](../../../03.design/screens/SCR-042.md): không render cancellation mutation.
- [SCR-047](../../../03.design/screens/SCR-047.md): result.

### 5. Technical trace

| BC | Handler | API | Transaction | Event |
|---|---|---|---|---|
| `BC-IC-08` | `CancelStockCount` | `API-C-27 POST /v1/stock-counts/{id}/cancellation` | Session cancel + lock release + CommandReceipt | `EVT-IC-05` |

### 6. Source
[BJ-08](../journeys/BJ-08-kiem-ke-va-ieu-chinh-chenh-lech.md); `T7-DR-035…039`, `T7-DR-171…177`
