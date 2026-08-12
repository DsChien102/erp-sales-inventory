---
id: UC-08-03
type: use-case
theme: theme-07
title: "Đếm lại và hoàn thiện căn cứ"
owner: BA
status: IN_REVIEW
source_baseline: v3.10.1
---
# UC-08-03 — Đếm lại và hoàn thiện căn cứ

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




### Nguồn v3.10.1 — UC-08-03 — Đếm lại và hoàn thiện căn cứ

> **Hành trình:** [BJ-08](../journeys/BJ-08-kiem-ke-va-ieu-chinh-chenh-lech.md)  
> **Actor:** Assigned counter của session  
> **BC/API:** `BC-IC-02 / API-C-15`

### 1. Tổng quan

| Mục | Hợp đồng |
|---|---|
| Trigger | Latest accepted round có variance khác 0 hoặc ApprovalCase trả `REQUEST_RECOUNT` |
| Mục tiêu | Tạo một recount round mới, không sửa evidence cũ, và xác lập final count hiện hành |
| Thành công | Immutable RECOUNT submission; zero variance complete hoặc non-zero route basis/approval |
| Blocked | Surplus thiếu authoritative value basis → `PRICE_BASIS_REQUIRED`, lock giữ nguyên |
| UNKNOWN | Query/reconcile same submission identity; không append duplicate recount |

### 2. Behavioral contract

- Recount chỉ cho discrepant lines của latest accepted snapshot.
- Mỗi submit tăng `round_no`, giữ predecessor submission, actor/time/observations/payload hash bất biến.
- `REQUEST_RECOUNT` của approver tạo yêu cầu round mới; không overwrite round đã duyệt/xem xét.
- Final non-zero variance phải dựng CountAdjustmentBasis trước ApprovalCase.
- Shortage basis bind applicable Official Cost version; surplus bind authoritative surplus-value basis. Counter chỉ xem status cần thiết và không nhập giá.
- Final variance = 0 → complete + unlock; không ApprovalCase.

### 3. Acceptance

<a id="as-uc-08-03-01"></a>
- Round 2/3/... đều truy vết được, round trước không đổi.
<a id="as-uc-08-03-02"></a>
- Recount actor phải là assigned counter hiện hành theo assignment version/snapshot.
<a id="as-uc-08-03-03"></a>
- Surplus thiếu basis không thể gửi duyệt hoặc adjustment.
<a id="as-uc-08-03-04"></a>
- Zero variance sau recount bỏ qua approval và trả result no-adjustment.
### 4. UI trace

- [SCR-045](../../../03.design/screens/SCR-045.md): discrepant lines, round context, basis status; `ACT-09-SUBMIT`, contextual `ACT-09-CANCEL`.

### 5. Technical trace

| BC | Handler | API | Entity | Test |
|---|---|---|---|---|
| `BC-IC-02` | `SubmitStockCount` | `API-C-15 POST /v1/stock-counts/{id}/submissions` | `ENT-IC-04/05/09` | `TST-BC-IC-02` |

### 6. Source
[BJ-08](../journeys/BJ-08-kiem-ke-va-ieu-chinh-chenh-lech.md); `T7-DR-035…039`, `T7-DR-171…177`
