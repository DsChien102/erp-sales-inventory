---
id: BC-IO-02
type: behavioral-contract
theme: theme-07
title: "Receive purchased goods"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-io-02"></a>
# BC-IO-02 — Receive purchased goods

## 1. Ý định

Ghi lượng đạt thực nhận và lô; mọi lượng đạt vào `VALUATION_PENDING`.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: IO
- Journey chính: `BJ-02`

## 3. Đầu vào nghiệp vụ

Goods receipt source/version; source line/version + authoritative `remaining_receivable_qty`; exactly-one Supplier; `receipt_business_date`; receipt-item grouping; Product/UOM + conversion snapshot; accepted/quarantine/damaged/rejected; tracking + lot precision; delivery evidence refs; ownership assertion; versioned price/FX basis.

## 4. Điều kiện trước

Supplier/Product/UOM/version hợp lệ; một goods receipt không trộn Supplier; warehouse unlocked; ownership assertion hợp lệ; document UOM/source line version current; `accepted_physical_base_qty` không vượt source remainder nếu chưa có approval; Quick không duplicate Product+UOM và không submit khi accepted physical=0; `NONE` không lot data; `LOT` có manufacturer lot + original DAY/MONTH/YEAR precision và expiry nếu required; conflict lot attributes chặn.

## 5. Quy tắc nghiệp vụ

Validate toàn operation → kiểm tra route/approval đã hợp lệ (**Quick luôn cần approval; Document cần approval khi cumulative accepted physical quantity vượt tolerance/ngưỡng của source theo ApprovalPolicy**) → create/reuse lot → append goods receipt/state movement vào `VALUATION_PENDING` → update balance → lưu direct-price evidence chỉ làm staging cho BC-IV-01 → store discrepancy result/outbox. Không tự suy thêm trigger approval cho nhận theo chứng từ nếu chưa có Decision định nghĩa.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

`COMPLETED`; physical tăng, available không tăng; không value movement. Xác nhận direct cost luôn là command/transaction riêng.

## 9. Kết quả và semantics lỗi

`OWNERSHIP_ASSERTION_REQUIRED`, `LOT_REQUIRED`, `LOT_ATTRIBUTE_CONFLICT`, `EXPIRY_REQUIRED`, `SOURCE_VERSION_STALE`, `RECEIPT_EXCEEDS_TOLERANCE`, `PRODUCT_DISCONTINUED_FOR_RECEIPT`, `PRODUCT_ARCHIVED`.

## 10. Domain và UC sử dụng

- Entity/Read model: Write `ENT-IO-01/02/03/04/06`; optional approval.
- Trace: `BJ-02`; `ST-02.01`, `ST-02.02`, `ST-02.03`, `ST-02.04`, `ST-02.05`; `SG-02`; `API-C-02`; `EVT-IO-01`.
