---
id: UC-08-01
type: use-case
theme: theme-07
title: "Mở và khóa phạm vi"
owner: BA
status: IN_REVIEW
source_baseline: v3.10.1
---
# UC-08-01 — Mở và khóa phạm vi

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




### Nguồn v3.10.1 — UC-08-01 — Mở và khóa phạm vi

> **Hành trình:** [BJ-08](../journeys/BJ-08-kiem-ke-va-ieu-chinh-chenh-lech.md)  
> **Actor:** Người có quyền mở kiểm kê trong warehouse scope  
> **BC/API:** `BC-IC-01 / API-C-14`

### 1. Tổng quan

| Mục | Hợp đồng |
|---|---|
| Trigger | Có yêu cầu kiểm kê với warehouse, phạm vi và lý do hợp lệ |
| Mục tiêu | Tạo frozen scope + exact book cut-off và khóa phạm vi trước khi đếm |
| Tiền điều kiện | Không có conflicting lock/session; actor có quyền; scope không chứa unresolved/mixed valuation state |
| Thành công | `OPEN/LOCKED` session, CountScopeSnapshot, InventoryLock và book lines cùng một atomic commit |
| Từ chối | Scope rỗng/không hợp lệ, lock conflict, unresolved valuation, permission denied; effect = NONE |
| UNKNOWN | Giữ cùng command/session identity; query/reconcile trước retry; không tạo session/lock mới |

### 2. Behavioral contract

1. Chuẩn hóa scope và resolve frozen membership theo `T7-DR-172`.
2. Acquire scope barrier trước cut-off; serialize/chờ mutation đang chạy trong scope.
3. Chốt `cutoff_ledger_sequence`; materialize `PhysicalCountKey` book snapshot đúng sequence đó.
4. Persist CountScopeSnapshot + session + count lines + lock nguyên tử.
5. `GROUP` freeze exact Product membership; Product/Group vẫn chặn prospective LOT của Product đã frozen.
6. Count line dùng base UOM; không expose valuation state cho người đếm.
7. Nếu physical key có `VALUATION_PENDING` hoặc mixed valuation-state quantity: `COUNT_SCOPE_HAS_UNRESOLVED_VALUATION`.
8. Open fail không để orphan lock hoặc half-session.

### 3. Acceptance

<a id="as-uc-08-01-01"></a>
- **Given** scope hợp lệ và ledger ổn định sau barrier **When** actor mở phiên **Then** cutoff/book/lock phải cùng atomic boundary.
<a id="as-uc-08-01-02"></a>
- Mutation thuộc frozen scope không thể commit ở sequence sau cutoff trong thời gian lock active.
<a id="as-uc-08-01-03"></a>
- Group membership đổi sau open không thay CountScopeSnapshot.
<a id="as-uc-08-01-04"></a>
- Unknown open command được reconcile bằng cùng idempotency identity.
### 4. UI trace

- [SCR-042](../../../03.design/screens/SCR-042.md): browse/start navigation, không sở hữu cancel mutation.
- [SCR-043](../../../03.design/screens/SCR-043.md): scope/reason + read-only warehouse/cut-off/assigned counter; `ACT-09-OPEN`.

### 5. Technical trace

| BC | Handler | API | Transaction | Test |
|---|---|---|---|---|
| `BC-IC-01` | `OpenStockCount` | `API-C-14 POST /v1/stock-counts` | scope barrier + cutoff + snapshot + session/lines/lock | `TST-BC-IC-01` |

### 6. Source
[BJ-08](../journeys/BJ-08-kiem-ke-va-ieu-chinh-chenh-lech.md); `T7-DR-035…039`, `T7-DR-171…177`
