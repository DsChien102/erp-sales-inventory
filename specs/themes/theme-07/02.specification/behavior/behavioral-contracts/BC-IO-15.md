---
id: BC-IO-15
type: behavioral-contract
theme: theme-07
title: "Save pick allocation"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-io-15"></a>
# BC-IO-15 — Save pick allocation

## 1. Ý định

Lưu một version của tập dòng phân bổ lô/lượng pick mà chưa giảm physical.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: IO
- Journey chính: `BJ-05`

## 3. Đầu vào nghiệp vụ

Fulfillment/reservation IDs, `allocation_set_id?`, expected allocation version, các line_no/lots/quantities, allocation method, override reason.

## 4. Điều kiện trước

Reservation active; expected version khớp; total lines ≤ unconsumed reservation; lot eligible/available; override permission/reason.

## 5. Quy tắc nghiệp vụ

Lock reservation + active allocation set → compare-and-swap version → supersede toàn version cũ nếu sửa → persist một active set version và audit; không movement/value.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

`allocation_set_id`, new `allocation_version` và các line ổn định sẵn sàng cho handover.

## 9. Kết quả và semantics lỗi

`PICK_ALLOCATION_CONFLICT`, `PICK_EXCEEDS_RESERVATION`, `LOT_NOT_ELIGIBLE`, `OVERRIDE_REASON_REQUIRED`.

## 10. Domain và UC sử dụng

- Entity/Read model: `ENT-IO-05/09`; read `PRJ-IO-01`, `ENT-IO-06`, `ENT-IO-08`.
- Trace: `BJ-05`; `ST-06.01`, `ST-06.03`; `SG-06`; `API-C-24`; synchronous result.
