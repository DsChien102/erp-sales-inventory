---
id: SBC-COM-01
type: behavioral-contract
theme: theme-07
title: "Bao yêu cầu và định danh"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="sbc-com-01"></a>
# SBC-COM-01 — Bao yêu cầu và định danh

## 1. Ý định

Mọi command mutation có tối thiểu: `tenant_id`, `store_id`, `warehouse_id`, `actor_id`, `idempotency_key`, `source_type`, `source_document_id`, `source_line_id?`, `source_version`, `business_date`, `expected_entity_version?`, `payload` và `correlation_id`.

## 2. Phạm vi áp dụng

- Loại: Dùng chung theo source v3.10.1
- Owner nguồn: Common
- Journey chính: Cross-cutting

## 3. Đầu vào nghiệp vụ

Các dữ kiện đầu vào được giữ trong định nghĩa nguồn bên dưới.

## 4. Điều kiện trước

Các điều kiện trước được quy định bởi common envelope/permission/finality contracts.

## 5. Quy tắc nghiệp vụ

Mọi command mutation có tối thiểu:

`tenant_id`, `store_id`, `warehouse_id`, `actor_id`, `idempotency_key`, `source_type`, `source_document_id`, `source_line_id?`, `source_version`, `business_date`, `expected_entity_version?`, `payload` và `correlation_id`.

Server tự điền store/warehouse mặc định cho UI Phase 1 nhưng vẫn validate và persist. API không chấp nhận một cặp khác.

<a id="sbc-com-02"></a>

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

Theo outcome được nêu trong định nghĩa nguồn.

## 9. Kết quả và semantics lỗi

Không có error list riêng trong contract nguồn; dùng common result/finality semantics.

## 10. Domain và UC sử dụng

- Theo phạm vi và consumer được nêu trong nguồn v3.10.1.
