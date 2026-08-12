---
id: UC-08-02
type: use-case
theme: theme-07
title: "Ghi nhận lần đếm mù"
owner: BA
status: IN_REVIEW
source_baseline: v3.10.1
---
# UC-08-02 — Ghi nhận lần đếm mù

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




### Nguồn v3.10.1 — UC-08-02 — Ghi nhận lần đếm mù

> **Hành trình:** [BJ-08](../journeys/BJ-08-kiem-ke-va-ieu-chinh-chenh-lech.md)  
> **Actor:** Assigned counter của session  
> **BC/API:** `BC-IC-02 / API-C-15`

### 1. Tổng quan

| Mục | Hợp đồng |
|---|---|
| Trigger | Session đang `OPEN/LOCKED`, FIRST round chưa submit |
| Mục tiêu | Ghi bằng chứng đếm vật lý đầu tiên mà không để book quantity ảnh hưởng người đếm |
| Thành công | Immutable FIRST StockCountSubmission; variance được compute sau submit |
| Zero variance | Complete session + no adjustment + release lock atomically; không tạo ApprovalCase |
| Non-zero | Chỉ các discrepant lines chuyển `RECOUNT_REQUIRED` |
| UNKNOWN | Giữ same submission command identity; không tạo round thứ hai khi chưa chứng minh round đầu không commit |

### 2. Behavioral contract

- Trước submit, book/variance/proxy từ book không được trả cho surface đếm mù.
- Quantity nhập theo Product base UOM và đúng precision/step snapshot.
- Key identity là Product + physical stock state + LOT/non-LOT trong warehouse session.
- Unexpected physical item phải nằm trong CountScopeSnapshot; Product tồn tại; stock_state xác định; tracking hợp lệ.
- Với LOT tracking có thể resolve LOT hiện có hoặc capture LOT mới theo shared LOT contract; BJ08 không tạo Product.
- Counter không nhập surplus price/value basis.
- Submit tạo immutable `StockCountSubmission(round_type=FIRST, round_no=1)` + line observations hash; StockCountLine chỉ cập nhật projection/ref.

### 3. Acceptance

<a id="as-uc-08-02-01"></a>
- Blind-count DOM/accessibility không chứa book/variance trước submit.
<a id="as-uc-08-02-02"></a>
- Actor khác assigned counter bị `COUNT_ACTOR_NOT_ASSIGNED`.
<a id="as-uc-08-02-03"></a>
- Unexpected key ngoài frozen scope bị `COUNT_LINE_OUT_OF_SCOPE`.
<a id="as-uc-08-02-04"></a>
- FIRST round không thể overwrite/re-submit bằng identity mới để thay evidence.
- Zero variance không đi qua SCR-046.
### 4. UI trace

- [SCR-044](../../../03.design/screens/SCR-044.md): blind count; `ACT-09-SUBMIT`; contextual `ACT-09-CANCEL` khi được phép.

### 5. Technical trace

| BC | Handler | API | Entity | Test |
|---|---|---|---|---|
| `BC-IC-02` | `SubmitStockCount` | `API-C-15 POST /v1/stock-counts/{id}/submissions` | `ENT-IC-05`, `ENT-IC-09` | `TST-BC-IC-02` |

### 6. Source
[BJ-08](../journeys/BJ-08-kiem-ke-va-ieu-chinh-chenh-lech.md); `T7-DR-035…039`, `T7-DR-171…177`
