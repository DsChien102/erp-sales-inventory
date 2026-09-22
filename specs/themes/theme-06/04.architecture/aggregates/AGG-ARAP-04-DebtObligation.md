---
id: AGG-ARAP-04
type: aggregate
theme: theme-06
title: DebtObligation Aggregate
owner: SA
status: IN_REVIEW
---
# AGG-ARAP-04 — DebtObligation Aggregate

> **Hotspot cần review sâu.** Đây là candidate consistency boundary cho outstanding của một nghĩa vụ; cách phối hợp với Payment/Allocation và DebtOffset chưa Architecture Freeze.

## 1. Trách nhiệm

Bảo vệ outstanding và lineage của **một nghĩa vụ công nợ**, ngăn over-settlement và silent overwrite sau finality.

## 2. Boundary
### 2.1 Thuộc Aggregate
- [ENT-ARAP-01 DebtObligation](../../02.specification/domain/entities/ENT-ARAP-01-nghia-vu-cong-no.md) root.
- Có thể có value object cho SourceRef/Amount; không giữ full source document.

### 2.2 Không thuộc Aggregate
- Payment/Allocation.
- DebtOffset request.
- Partner master.
- Source Sales/Purchase document.
- Read models.

## 3. Aggregate Root

`obligation_id`.

## 4. Entity / Value Object bên trong

Chưa có child entity bắt buộc. Settlement history có thể được lưu dưới dạng event/history projection; không tự tạo child nếu không cần consistency.

## 5. Lifecycle và state transition

Semantic: `OPEN/PARTIALLY_SETTLED → SETTLED`; source conflict có thể đưa vào `MANUAL_RESOLUTION_REQUIRED` mà không auto-reverse. Exact state encoding chưa freeze.

## 6. Điều kiện bắt buộc

- Một direction cố định.
- `0 <= outstanding_amount`.
- Settlement delta không vượt outstanding tại commit.
- Source finality/lineage được giữ; correction không silent overwrite.
- Source conflict sau settlement không tự refund/reverse/adjust Phase 1.

## 7. Domain Operations / Aggregate Behavior

| Operation | Ý nghĩa | Preconditions | State effect |
|---|---|---|---|
| `recordFinalObligation` | Ghi nhận obligation từ source final/opening balance | Handoff hợp lệ, không duplicate | Tạo root |
| `applySettlement` | Giảm outstanding theo allocation/offset hợp lệ | Delta <= outstanding; expected version | Giảm outstanding |
| `markManualResolutionRequired` | Chặn auto-apply khi source conflict | Conflict đã xác minh | Gắn trạng thái cần xử lý |

## 8. Concurrency và consistency

Cần optimistic version/locking để hai allocation/offset đồng thời không làm outstanding âm. Cách đảm bảo atomicity xuyên Payment/Offset là điểm kiến trúc trọng yếu chưa chốt.

## 9. Persistence boundary

Một obligation là một consistency unit logic. Không suy ra table/schema hoặc yêu cầu tất cả history nằm trong cùng record.

## 10. Domain Events

Có thể cần event thay đổi outstanding/kết quả settlement cho read model/accounting; tên/schema/delivery chưa freeze.

## 11. Dependencies

Source handoff, Payment Allocation, DebtOffset, Accounting integration, PartnerRef.

## 12. Consumers

BJ-02..BJ-06, read models.

## 13. Verification

Concurrent settlement không over-settle; retry không áp dụng hai lần; source correction không silent overwrite; fully settled vẫn truy vết được nhưng rời open list.
