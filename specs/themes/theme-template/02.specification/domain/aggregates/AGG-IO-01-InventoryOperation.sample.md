---
id: AGG-IO-01
type: aggregate
theme: theme-07
title: InventoryOperation Aggregate
owner: BA/SA
status: DRAFT
sample_of: AGGREGATE.template.md
sample_status: DERIVED_SAMPLE
---
# AGG-IO-01 — InventoryOperation Aggregate

> **Sample dẫn xuất để thử template, chưa phải kiến trúc đã phê duyệt.** Nội dung dựa trên Domain Foundation, Entity và BC hiện hành; tên Domain Operation bên dưới chỉ minh họa cách đặc tả.

## 1. Trách nhiệm

Bảo vệ tính nhất quán của **một Inventory Operation** trong suốt lifecycle mutable/submitted của nó: identity, version, draft payload, các line thuộc operation và payload lock.

## 2. Boundary

### 2.1 Thuộc Aggregate

- `InventoryOperation` — Aggregate Root.
- `InventoryOperationLine` — child entity của operation.
- Receipt-item grouping identity cần để giữ nhiều technical line thuộc cùng Product + transaction UOM *(cách materialize cuối cùng còn là quyết định SA)*.

### 2.2 Không thuộc Aggregate

- `ApprovalPolicy`, `ApprovalCase` — Inventory Control.
- Product/UOM/tracking policy — Product domain.
- Supplier master — Partner domain.
- `CommandReceipt`/idempotency infrastructure — dùng Foundation chung; không coi là child business entity của Aggregate trong sample này.
- Inventory Movement/Balance commit của execution phase — capability phía sau, không do draft aggregate tự phát sinh khi maintain/submit.

## 3. Aggregate Root

`InventoryOperation`, identity `operation_id`; business request identity giữ `operation_request_id` riêng.

## 4. Entity / Value Object bên trong

- `InventoryOperationLine`.
- Candidate `ReceiptItemRef` value/object identity để nhóm technical lines cùng business item.

## 5. Lifecycle và state transition

Relevant path:

`DRAFT → PENDING_APPROVAL → READY → PROCESSING → COMPLETED / EXECUTION_REJECTED / UNKNOWN`

Quick Receipt không được đi `DRAFT → READY`.

## 6. Điều kiện bắt buộc

- Chỉ `DRAFT` được sửa payload.
- Expected version phải khớp khi mutation mutable.
- Submitted payload hash bất biến sau submit.
- Cùng Product + cùng UOM không tạo duplicate business receipt item trong Quick flow.
- LOT data chỉ xuất hiện khi Product policy cho phép/yêu cầu.
- Draft/submit không tự làm thay đổi tồn vật lý.

## 7. Domain Operations / Aggregate Behavior

| Operation | Ý nghĩa | Preconditions | State effect |
|---|---|---|---|
| `createDraft` | Khởi tạo operation draft | Context/source hợp lệ | Tạo `DRAFT` |
| `updateDraftHeader` | Sửa Supplier/evidence/context của draft | `DRAFT`, version match | Tăng version; có thể invalidate dữ liệu phụ thuộc |
| `upsertReceiptItem` | Thêm/sửa business receipt item | `DRAFT`; Product/UOM hợp lệ | Cập nhật child lines/grouping |
| `validateForSubmission` | Kiểm tra các điều kiện nội tại của operation trước submit | `DRAFT` | Không đổi state |
| `lockSubmittedPayload` | Khóa payload đã gửi | Validation pass | Ghi immutable payload hash |
| `markPendingApproval` | Ghi state sau khi approval route đã được tạo hợp lệ | Quick + approval dependency đã thành công | `DRAFT → PENDING_APPROVAL` |

## 8. Concurrency và consistency

- Optimistic version trên mutable Aggregate.
- Domain mutation của Aggregate phải atomic trong transaction của Application Command.
- Idempotency do shared Foundation cung cấp và commit cùng owning mutation.

## 9. Persistence boundary

Persist Aggregate Root + child lines như một consistency set cho draft mutation. Schema vật lý không được suy trực tiếp từ sample này.

## 10. Domain Events

Chưa chốt event riêng cho maintain draft/submit trong sample. BC hiện mô tả synchronous result; không phát minh event mới.

## 11. Dependencies

- Product/UOM/tracking policy lookup.
- Supplier existence/version.
- Warehouse/context.
- Approval capability khi submit.
- Foundation Idempotency.

## 12. Consumers

- `UC-02-01`, `UC-02-02` và các UC khác thao tác InventoryOperation.
- Slice maintain/submit operation draft.

## 13. Verification

- Không sửa operation ngoài `DRAFT`.
- Version conflict bị chặn.
- Quick duplicate Product+UOM bị chặn.
- Lock payload là bất biến.
- Quick không thể chuyển thẳng `READY`.
- Draft/submit không tạo movement vật lý.
