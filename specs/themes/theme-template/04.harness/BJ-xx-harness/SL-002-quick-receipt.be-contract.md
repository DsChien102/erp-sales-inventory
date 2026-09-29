# Work Slice: SL-002 — Quick receipt contract

```yaml
id: SL-002
role: be-contract
family: quick-receipt
sources: [BJ-02, UC-02-02, BC-IO-16, BC-IC-07, SCR-009, FND-01]
theme: theme-07
sample_status: NON_CANONICAL_EXAMPLE
```

**design_status:** xem [CATALOG.md](CATALOG.md). Sample — **không invent** field/RPC; chỗ chưa chốt ghi Open Questions.

---

## 1. Objective

Công bố Command/Query/DTO/port (+ fake) cho lập/gửi nhận hàng nhanh để `be-impl` và `fe` cùng family bám một contract.

---

## 2. Blocked by

- [SL-001-inventory-operation-boundary.md](SL-001-inventory-operation-boundary.md)

---

## 3. Scope (contract)

### In Scope

- Surface tạo/sửa/gửi hồ sơ nhận hàng nhanh (tên type từ UC khi đã chốt)
- Fake in-memory cho FE/handler test

### Out of Scope

- RPC/schema/txn — [SL-003](SL-003-quick-receipt.be-impl.md)
- UI — [SL-004](SL-004-quick-receipt.fe.md)

### Rules

| ID | Quy tắc (slice) |
| --- | --- |
| [UC-02-02](../../02.specification/behavior/use-cases/UC-02-02.sample.md) | Flow/scenario trong coverage catalog |
| [BC-IC-07](../../02.specification/behavior/behavioral-contracts/BC-IC-07.sample.md) | Gửi → chờ duyệt, chưa đổi tồn |

---

## 4. Contracts

> Schema Dart cụ thể **chưa chốt** trong sample — điền từ SRS khi Theme thật; dưới đây chỉ shape.

#### ExampleCommand

> Gọi khi người lập gửi hồ sơ nhận hàng nhanh hợp lệ. Outcome: trạng thái chờ duyệt, chưa biến động tồn. Đổi tên/field theo UC/API đã chốt — sample không invent schema.

```dart
class ExampleCommand {
  final String idempotencyKey; // ≠ command.id
}
```

#### Persistence

`N/A — impl owns` → [SL-003-quick-receipt.be-impl.md](SL-003-quick-receipt.be-impl.md)

---

## 5. Verification

- [ ] **AC-01** Mọi Command/Query có blockquote + fence khớp nguồn đã chốt
- [ ] **AC-02** Fake đủ cho FE test không cần DB

| Test id | Given / When / Then | Layer |
| --- | --- | --- |
| `scn_sl002_contract` | Consumer compile against fake | application fake |

---

## 6. Delivery

### Open Questions

- Command/Query/DTO schemas đầy đủ (chặn READY_TO_IMPLEMENT đến khi chốt)

### Next Action

- [ ] Chốt schema → catalog `READY_TO_IMPLEMENT` → unblock SL-003 / SL-004
