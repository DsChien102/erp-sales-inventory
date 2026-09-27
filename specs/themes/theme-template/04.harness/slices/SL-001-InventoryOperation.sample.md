---
id: SL-001
type: slice
theme: theme-07
title: Khóa ranh giới InventoryOperation Aggregate
owner: SA
contributors: [BA, SE, QA]
status: DRAFT
sample_of: SLICE.template.md
sample_status: NON_CANONICAL_EXAMPLE
---

# SL-001 — Khóa ranh giới InventoryOperation Aggregate

**Nguồn:** [DOM-IO](../../02.specification/domain/domain-foundation/DOM-IO.sample.md),
[ENT-IO-01](../../02.specification/domain/entities/ENT-IO-01.sample.md),
[AGG-IO-01](../../02.specification/domain/aggregates/AGG-IO-01-InventoryOperation.sample.md),
[FND-01](../../02.specification/technical-contracts/FND-01-Idempotency.sample.md).
**Phạm vi bao phủ:** Ranh giới nhất quán và hành vi dùng chung của InventoryOperation.
**Chưa bao phủ:** Triển khai toàn bộ UC/giao diện nhận hàng nhanh — [SL-002](SL-002-QuickReceipt.sample.md).

## 1. Mục tiêu (Objective)

Xác lập ranh giới nhất quán của InventoryOperation để các UC dùng chung lifecycle và hành vi Domain đã được review.

## 2. Phạm vi và quy tắc (Scope & Rules)

**Sở hữu:** Root, Entity/VO bên trong, lifecycle, hành vi draft/submit, concurrency và ranh giới lưu trữ logic của Aggregate.

**Không sở hữu:** Application Command/Query riêng từng UC, endpoint, Screen, dữ liệu Product/Supplier, nội bộ ApprovalPolicy/ApprovalCase và thực thi biến động tồn.

| ID | Cách áp dụng trong Slice |
|---|---|
| [BC-IO-16](../../02.specification/behavior/behavioral-contracts/BC-IO-16.sample.md) | Hành vi sửa bản nháp không phát sinh biến động tồn hoặc phê duyệt |
| [BC-IC-07](../../02.specification/behavior/behavioral-contracts/BC-IC-07.sample.md) | Nhận hàng nhanh phải qua phê duyệt sau khi gửi |
| [FND-01](../../02.specification/technical-contracts/FND-01-Idempotency.sample.md) | Dùng cơ chế chống tác động trùng chung, không biến CommandReceipt thành child Entity |

## 3. Luồng xử lý (Flow)

1. Đối chiếu Domain/Entity/BC và xác định Root, thành viên, bất biến.
2. Mô tả lifecycle và Domain Operations tại AGG-IO-01.
3. Review ranh giới với BA/SA, kiểm chứng hành vi và công bố cho Slice phụ thuộc.

Nếu ranh giới nhóm dòng thực nhận hoặc phối hợp với Approval chưa chốt, giữ DRAFT/IN_REVIEW; không để Slice phụ thuộc tự quyết định thay.

## 4. Thiết kế (Design)

**Trước:** Đã có Domain, Entity và BC; AGG-IO-01 còn là thiết kế minh họa.

**Sau:** AGG-IO-01 xác định rõ Root/child, nhóm dòng thực nhận, draft/submit và giới hạn tác động. Quyết định bền vững được ghi tại chính artifact Aggregate.

Các điểm cần review:

- CommandReceipt thuộc Technical Contract FND-01, không thuộc cụm Entity nghiệp vụ.
- Nhóm mặt hàng thực nhận và dòng kỹ thuật nằm ở đâu trong ranh giới nhất quán.
- Hành vi nội tại Aggregate và điều phối Approval ngoài Aggregate.
- Version và phạm vi lưu trữ logic; schema vật lý chưa được suy ra từ sample.

Slice này không thay đổi giao diện hoặc công bố endpoint.

## 5. Phụ thuộc và hợp đồng (Dependencies & Contracts)

| ID / Link | Cần gì trước khi triển khai | Trạng thái |
|---|---|---|
| [FND-01](../../02.specification/technical-contracts/FND-01-Idempotency.sample.md) | Cơ chế begin/complete và replay | Nguồn minh họa có sẵn |
| [AGG-IO-01](../../02.specification/domain/aggregates/AGG-IO-01-InventoryOperation.sample.md) | Root, thành viên và Domain Operations được duyệt | DRAFT |
| [BC-IC-07](../../02.specification/behavior/behavioral-contracts/BC-IC-07.sample.md) | Ranh giới phối hợp Approval | Cần xác nhận thiết kế chi tiết |

Product/UOM/tracking, Supplier và ngữ cảnh kho là phụ thuộc từ nơi sở hữu. Slice cung cấp AGG-IO-01 được review và các kiểm tra Domain; không công bố HTTP.

## 6. Kiểm chứng (Verification)

- [ ] **AC-01** Root và ranh giới nhất quán rõ; không chứa Command/Query theo UC.
- [ ] **AC-02** Không sửa ngoài DRAFT; version conflict bị chặn; nội dung gửi đã khóa không bị sửa.
- [ ] **AC-03** Nhận hàng nhanh không đi thẳng READY; draft/submit không tạo tồn vật lý.

| Test ID | Tiêu chí | Cách kiểm tra |
|---|---|---|
| scn_sl_001_boundary | AC-01 | Review Domain |
| scn_sl_001_lifecycle | AC-02 | Domain tests |
| scn_sl_001_quick_approval | AC-03 | Domain/contract tests |

## 7. Bàn giao (Delivery)

**Đầu ra:** AGG-IO-01 được review; kiểm tra lifecycle/invariant; dependency được cập nhật trong manifest.
**Evidence/commit/build:** Chưa có; sample chưa chứng minh implementation.

**Câu hỏi còn mở:** Cách nhóm receipt item và ranh giới phối hợp Approval cần BA/SA chốt tại AGG-IO-01.

**Bước tiếp theo:** Review thiết kế trước READY_TO_IMPLEMENT. Đây là Slice năng lực dùng chung vì có phạm vi thay đổi riêng, không phải một loại Slice dành riêng cho SA.
