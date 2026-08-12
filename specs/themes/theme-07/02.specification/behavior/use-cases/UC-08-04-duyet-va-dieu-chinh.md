---
id: UC-08-04
type: use-case
theme: theme-07
title: "Duyệt và điều chỉnh"
owner: BA
status: IN_REVIEW
source_baseline: v3.10.1
---
# UC-08-04 — Duyệt và điều chỉnh

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




### Nguồn v3.10.1 — UC-08-04 — Duyệt và điều chỉnh

> **Hành trình:** [BJ-08](../journeys/BJ-08-kiem-ke-va-ieu-chinh-chenh-lech.md)  
> **Actor:** Eligible independent approver  
> **BC/API:** `BC-IC-03 / API-C-16`

### 1. Tổng quan

| Mục | Hợp đồng |
|---|---|
| Trigger | Final variance khác 0, latest round và CountAdjustmentBasis hiện hành, ApprovalCase `PENDING` |
| Mục tiêu | Approve exact variance snapshot hoặc yêu cầu recount; approver không sửa số đếm |
| APPROVE | Recheck toàn basis → atomic adjustment quantity/value + complete session + release lock |
| REQUEST_RECOUNT | Đóng/supersede current case, giữ lock, tạo recount requirement; không adjustment |
| Từ chối stale | Basis/cost/policy/round/lock thay đổi → no adjustment; rederive/new case |
| UNKNOWN | Giữ same approval command identity; verify/handoff BJ17, không blind retry |

### 2. Behavioral contract

ApprovalCase subject là `STOCK_COUNT_SESSION`, bind:
- session + CountScopeSnapshot hash + cutoff + lock identity/version;
- latest final-count submission hash + variance lines;
- CountAdjustmentBasis/risk lines;
- applicable Official Cost versions và surplus basis versions;
- approval policy/required level;
- `excluded_actor_ids` gồm mọi actor góp count evidence của snapshot đang xét.

Risk = `Σ abs(line_amount_vnd)`, không net thừa/thiếu. Một approver đủ required level quyết định; không chain tuần tự.

APPROVE phải recheck toàn snapshot. Shortage final adjustment dùng Official Cost có hiệu lực tại commit theo valuation rule hiện hành; nếu khác snapshot đã duyệt thì approval stale, không commit bằng risk cũ.

### 3. Acceptance

<a id="as-uc-08-04-01"></a>
- Counter/re-counter contributor không tự duyệt.
<a id="as-uc-08-04-02"></a>
- `REQUEST_RECOUNT` có reason, giữ old case immutable và tạo successor lineage.
<a id="as-uc-08-04-03"></a>
- Official Cost/surplus basis đổi giữa submit và decision → `COUNT_APPROVAL_SNAPSHOT_STALE`, effect NONE.
<a id="as-uc-08-04-04"></a>
- APPROVE atomic: InventoryOperation adjustment + quantity/value movements + session complete + lock release + outbox cùng transaction.
- UNKNOWN không tạo adjustment thứ hai.
### 4. UI trace

- [SCR-046](../../../03.design/screens/SCR-046.md): read-only independent approval; `ACT-09-APPROVE` với decision `APPROVE | REQUEST_RECOUNT`.
- [SCR-047](../../../03.design/screens/SCR-047.md): authoritative result only.

### 5. Technical trace

| BC | Handler | API | Transaction | Event |
|---|---|---|---|---|
| `BC-IC-03` | `ApproveCountAndAdjust` | `API-C-16 POST /v1/stock-counts/{id}/approval-decisions` | Approval + optional adjustment + complete/unlock | `EVT-IC-01` khi completed |

### 6. Source
[BJ-08](../journeys/BJ-08-kiem-ke-va-ieu-chinh-chenh-lech.md); `T7-DR-035…039`, `T7-DR-171…177`
