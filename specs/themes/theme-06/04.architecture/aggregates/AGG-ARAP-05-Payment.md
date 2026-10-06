---
id: AGG-ARAP-05
type: aggregate
theme: theme-06
title: Payment Aggregate
owner: SA
status: IN_REVIEW
---
# AGG-ARAP-05 — Payment Aggregate

> **Hotspot cần review sâu.** Candidate hiện tại đặt Allocation bên trong Payment để bảo vệ tổng phân bổ, nhưng Allocation đồng thời tác động DebtObligation nên boundary cuối cùng chưa freeze.

## 1. Trách nhiệm

Bảo vệ tính nhất quán của một khoản thu/chi và capacity còn có thể phân bổ: tổng allocation hiệu lực không vượt amount.

## 2. Boundary
### 2.1 Thuộc Aggregate
- [ENT-ARAP-02 Payment](../../02.specification/domain/entities/ENT-ARAP-02-khoan-thu-chi.md) root.
- [ENT-ARAP-03 Allocation](../../02.specification/domain/entities/ENT-ARAP-03-phan-bo-thanh-toan.md) — **child candidate**.

### 2.2 Không thuộc Aggregate
- DebtObligation.
- Partner master.
- Source payment record ngoài Domain.

## 3. Aggregate Root

`payment_id`.

## 4. Entity / Value Object bên trong

Allocation có identity, obligation reference, amount, finality/effective time. `unallocated_amount` là derived value.

## 5. Lifecycle và state transition

Payment có hiệu lực sau ghi nhận thành công. Allocation có commit point riêng; Payment có thể effective trong khi vẫn còn unallocated amount. Payment reversal/re-allocation sau final ngoài Phase 1.

## 6. Điều kiện bắt buộc

- Amount > 0.
- Tổng Allocation hiệu lực <= Payment amount.
- Thu chỉ vào Receivable; Chi chỉ vào Payable.
- Cùng Tenant + Partner.
- Allocation chưa có kết quả rõ không được tính vào settled/outstanding.

## 7. Domain Operations / Aggregate Behavior

| Operation | Ý nghĩa | Preconditions | State effect |
|---|---|---|---|
| `recordPayment` | Ghi nhận khoản thu/chi | Input hợp lệ, không duplicate source | Payment effective |
| `allocate` | Dành một phần amount cho obligation | Còn unallocated; direction/partner hợp lệ | Thêm allocation candidate/effective theo result |

## 8. Concurrency và consistency

Payment cần version để hai allocation đồng thời không vượt amount. Đồng thời DebtObligation phải chặn over-settlement. Cần SA quyết định transaction/coordination/outbox/recovery; nếu boundary không phù hợp có thể tách Allocation/Settlement thành Aggregate riêng.

## 9. Persistence boundary

Candidate: Payment + Allocation rows như một consistency set cho capacity của Payment. Không chốt schema vật lý.

## 10. Domain Events

Payment/Allocation result event chưa freeze. Handoff từ source phải có idempotency/dedup theo T06-DR-037.

## 11. Dependencies

DebtObligation, PartnerRef, source payment handoff, permission/idempotency foundation.

## 12. Consumers

BJ-03; payment nguồn từ Sales/Purchase handoff.

## 13. Verification

Concurrent allocation không vượt amount; allocation sai direction/Partner bị chặn; retry không duplicate; unallocated amount luôn tái tính đúng từ source of truth.
