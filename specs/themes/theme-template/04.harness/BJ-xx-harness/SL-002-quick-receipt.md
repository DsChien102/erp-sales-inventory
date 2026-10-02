# Work Slice: SL-002 — Lập nhận hàng nhanh

```yaml
id: SL-002
journey:
  - BJ-02
usecase:
  - UC-02-02
sources:
  - BC-IO-16
  - BC-IC-07
  - SCR-009
  - FND-01
  - AGG-IO-01
theme: theme-07
sample_status: NON_CANONICAL_EXAMPLE
```

**design_status** trên [CATALOG.md](CATALOG.md). Sample minh họa một outcome có UI. Field chưa có trong SRS thì nằm ở Open Questions. Không copy thành contract theme thật.

---

## Objective

Người lập gửi hồ sơ nhận hàng nhanh và hồ sơ chờ duyệt, chưa đổi tồn vật lý.

---

## Blocked by

- [SL-001-inventory-operation-boundary.md](SL-001-inventory-operation-boundary.md)

---

## Scope & Rules

### In Scope

- Surface tạo, sửa, gửi hồ sơ nhận hàng nhanh, kèm fake cho test
- RPC, handler, persistence của lần gửi
- Quick mode trên SCR-009
- Scenario xuyên UI → mediator → RPC: chờ duyệt, tồn không đổi

### Out of Scope

- Phê duyệt và ghi tồn vật lý — outcome sau
- Tên bảng chưa có trong domain của sample thì không bịa ở đây

### Boundary

| Concern | Owner |
| --- | --- |
| Hồ sơ nhận và lifecycle draft/submit | Inventory aggregate đã chốt ở SL-001 |
| Màn hình quick mode | SCR-009, presentation `apps/erp` |

### Rules

| ID | Quy tắc (slice) |
| --- | --- |
| [UC-02-02](../../02.specification/behavior/use-cases/UC-02-02.sample.md) | Flow lập và gửi nhận hàng nhanh |
| [BC-IC-07](../../02.specification/behavior/behavioral-contracts/BC-IC-07.sample.md) | Gửi xong thì chờ duyệt, chưa đổi tồn |

### Open Questions

- Tên Command, Query, DTO và field Dart chưa có trong sample. Chưa `READY` khi mục Contracts còn là shape minh họa.
- Tên bảng và danh sách file code chưa có trong sample.

---

## Flow

### Main Flow

1. Người lập mở quick mode trên SCR-009.
2. Người lập tìm sản phẩm, đơn vị tính, và nhập dòng.
3. Người lập gửi hồ sơ.
4. Hệ thống lưu hồ sơ ở trạng thái chờ duyệt.
5. Tồn vật lý giữ nguyên.

### Failure Flow

1. Gửi lại cùng idempotency key và cùng hash → trả snapshot trước → không tạo hồ sơ thứ hai.

---

## Design

### Domain

**Before:** hồ sơ nhận nhanh chưa gửi, hoặc chưa có.
**After:** hồ sơ ở trạng thái chờ duyệt. Tồn vật lý không đổi.

### Persistence

Tên bảng lấy từ domain khi theme thật chốt. Draft lúc đó: `supabase/migrations/_drafts/<scope>_quick_receipt.sql`.

### Transaction / Idempotency

- `idempotencyKey` ≠ `command.id`
- UK `(tenant_id, command_scope, idempotency_key)` theo [FND-01](../../02.specification/technical-contracts/FND-01-Idempotency.sample.md)
- Cùng transaction: mutation hồ sơ, fact outbox nếu lifecycle đã xảy ra, begin/complete idempotency
- Handoff phê duyệt hoặc tồn, khi có, đi `integration_commands`

### Code Layout

Danh sách file nằm ở Open Questions. Khi theme thật chốt, một cây cho `modules/` và `apps/erp`.

---

## Contracts

### ExampleCommand

> Gọi khi người lập gửi hồ sơ nhận hàng nhanh hợp lệ. Outcome: trạng thái chờ duyệt, chưa biến động tồn. Đổi tên và field theo UC đã chốt.

```dart
class ExampleCommand {
  final String idempotencyKey; // ≠ command.id
}
```

---

## Presentation

### Screens

| Screen | State / action | Nguồn |
| --- | --- | --- |
| SCR-009 | Quick mode: tìm sản phẩm, đơn vị tính, dòng, gửi | [SCR-009](../../03.design/screens/SCR-009.sample.md) |

### Route

- Entry quick mode của SCR-009. Path cụ thể nằm ở Open Questions cho đến khi screen sample chốt.

### State × feedback

| State | UI / feedback | Error code |
| --- | --- | --- |
| loading | chờ gửi | — |
| empty | chưa có dòng hàng | — |
| error | báo lỗi gửi, kèm mã khi SRS đã có | — |
| success | hồ sơ đã gửi, chờ duyệt | — |

### Design system

- Widget màn hình nhận hàng từ design system của theme

### Mediator

- `IModuleMediator` và fake khớp Contracts
- Presentation trong `apps/erp`

---

## Verification

### Acceptance Criteria

- [ ] **AC-01** Given hồ sơ hợp lệ, When người lập gửi, Then trạng thái chờ duyệt và tồn không đổi
- [ ] **AC-02** Given cùng idempotency key và cùng hash, When gửi lại, Then snapshot trước, không hồ sơ thứ hai
- [ ] **AC-03** Given quick mode, When đang tải, trống, lỗi, hoặc thành công, Then feedback đúng bảng State × feedback

### Tests

| Test id | Given / When / Then | Layer |
| --- | --- | --- |
| `scn_submit_pending` | Gửi hồ sơ hợp lệ → chờ duyệt, tồn không đổi | application / RPC |
| `scn_quick_widget` | Quick mode hiện loading, empty, error, success | widget |

### Scenarios

| Scenario | Actor | Across | Given / When / Then | Seed / fixture | Pass / fail |
| --- | --- | --- | --- | --- | --- |
| AS-UC-02-02-01 | Người lập | UI → mediator → RPC | G: quick mode mở / W: gửi hồ sơ hợp lệ / T: chờ duyệt, tồn không đổi | fixture theme thật lúc chạy | pass: một hồ sơ chờ duyệt; fail: tồn đổi hoặc hai hồ sơ |
