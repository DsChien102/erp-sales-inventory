---
id: AGG-ARAP-07
type: aggregate
theme: theme-06
title: DebtReconciliation Aggregate
owner: SA
status: IN_REVIEW
---
# AGG-ARAP-07 — DebtReconciliation Aggregate

## 1. Trách nhiệm

Bảo vệ hồ sơ của một lần đối chiếu: mốc/kỳ, snapshot/căn cứ nội bộ, phản hồi phía đối tác, evidence và kết quả khớp/chênh lệch; không thay đổi nghĩa vụ.

## 2. Boundary
### 2.1 Thuộc Aggregate
- [ENT-ARAP-10 DebtReconciliation](../../02.specification/domain/entities/ENT-ARAP-10-doi-chieu-cong-no.md) root.
- Counterparty response/evidence metadata có thể là child/value object nếu cần lịch sử chi tiết.

### 2.2 Không thuộc Aggregate
- DebtObligation.
- Partner master.
- DebtAdjustment (không có Phase 1).

## 3. Aggregate Root

`reconciliation_id`.

## 4. Entity / Value Object bên trong

Candidate: `InternalPositionSnapshot`, `CounterpartyResponse`, `EvidenceRef[]`. Exact decomposition chờ UC-05.

## 5. Lifecycle và state transition

`WAITING_CONFIRMATION → MATCHED | DIFFERENCE_FOUND` là semantic cốt lõi. Draft/edit/correct response chưa freeze.

## 6. Điều kiện bắt buộc

- Một reconciliation thuộc một Partner/Tenant và một mốc/kỳ.
- Kết quả phải giải thích được từ snapshot/căn cứ đã dùng.
- `DIFFERENCE_FOUND` không tự thay DebtObligation.
- Evidence/history phải được giữ theo policy audit.

## 7. Domain Operations / Aggregate Behavior

| Operation | Ý nghĩa | Preconditions | State effect |
|---|---|---|---|
| `createReconciliation` | Chốt scope/mốc và internal position | Partner/scope hợp lệ | Waiting confirmation |
| `recordCounterpartyResponse` | Ghi nhận số liệu/phản hồi | Reconciliation còn nhận phản hồi | Lưu response/evidence |
| `determineResult` | Xác định matched/difference | Đủ dữ liệu so sánh | Final result semantic |

## 8. Concurrency và consistency

Cần version/audit khi ghi phản hồi. Snapshot đã dùng cho một bản gửi/biên bản phải giữ được để lịch sử không thay đổi theo read model live; cách materialize snapshot do SA quyết định.

## 9. Persistence boundary

Reconciliation record + snapshot/response/evidence metadata thuộc một consistency boundary logic; file vật lý có thể nằm ở storage khác qua reference.

## 10. Domain Events

Không cần phát minh event ở bước này. Nếu accounting/notification consume kết quả, contract phải được chốt riêng.

## 11. Dependencies

PartnerRef, read models/obligation data để tạo snapshot, Evidence storage/reference.

## 12. Consumers

BJ-05.

## 13. Verification

Kết quả lịch sử không trôi theo dữ liệu live; difference không auto-adjust; evidence liên kết được; duplicate response/retry không làm sai final result.
