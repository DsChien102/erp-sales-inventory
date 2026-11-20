---
id: BC-IO-08
type: behavioral-contract
theme: theme-07
title: "Classify returned goods"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-io-08"></a>
# BC-IO-08 — Classify returned goods

## 1. Ý định

Chuyển lượng `RETURN_PENDING` sang stock state sau kiểm tra vật lý.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: IO
- Journey chính: `BJ-06`

## 3. Đầu vào nghiệp vụ

Return pending lines; user classification quantities cho `SELLABLE/QUARANTINE/DAMAGED`; resolved LOT attributes/version; tenant business date. `ReturnCondition` từ Theme 5 chỉ là declared context.

## 4. Điều kiện trước

Với LOT chưa hết hạn: `sellable + quarantine + damaged = pending quantity`. Với LOT đã hết hạn: `EXPIRED = SYSTEM_DERIVED`; system derive toàn pending quantity = `EXPIRED`, ba lượng user classification phải bằng 0. LOT/source version current; permission hợp lệ. Routine classification Phase 1 **không yêu cầu reason/evidence/approval**; không có approval/evidence threshold mặc định.

## 5. Quy tắc nghiệp vụ

Server derive expiry từ `Lot.expiry_date` + tenant business date → append state movements and update balances atomically; sellable only when eligible. Classification không ghi value movement lần hai.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

Pending về 0 cho phạm vi; available tăng chỉ phần sellable; server trả `classified_at`.

## 8. Tính nguyên tử và kết quả cuối

Pending về 0 cho phạm vi; available tăng chỉ phần sellable; server trả `classified_at`.

## 9. Kết quả và semantics lỗi

`CLASSIFICATION_TOTAL_MISMATCH`, `LOT_DATA_CONFLICT`, `EXPIRED_CLASSIFICATION_SYSTEM_OWNED`, `RETURN_ALREADY_CLASSIFIED`.

## 10. Domain và UC sử dụng

- Entity/Read model: `ENT-IO-01/02/03/04/06`.
- Trace: `BJ-06`; `ST-08.04`; `SG-07`; `API-C-08`; `EVT-IO-07`.
