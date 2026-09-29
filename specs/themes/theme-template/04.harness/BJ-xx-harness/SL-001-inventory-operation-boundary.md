# Work Slice: SL-001 — Khóa ranh giới InventoryOperation

```yaml
id: SL-001
journey: []
usecase: []
sources:
  - DOM-IO
  - ENT-IO-01
  - AGG-IO-01
  - BC-IO-16
  - FND-01
theme: theme-07
sample_status: NON_CANONICAL_EXAMPLE
```

**design_status** trên [CATALOG.md](CATALOG.md). Sample minh họa slice không UI. Không phải yêu cầu chính thức.

---

## Objective

Chốt ranh giới InventoryOperation để các use case sau dùng chung lifecycle domain đã review.

---

## Blocked by

- `None`

---

## Scope & Rules

### In Scope

- Root, entity và value object bên trong, lifecycle draft/submit, concurrency, ranh giới lưu trữ của aggregate

### Out of Scope

- Contracts — slice này không publish Command hay Query
- Presentation — không có màn hình
- Application command từng use case, Product/Supplier master, ApprovalCase, biến động tồn

### Boundary

| Concern | Owner |
| --- | --- |
| Root, lifecycle, bất biến | AGG-IO-01 |
| Chống trùng dùng chung | FND-01 |

### Rules

| ID | Quy tắc (slice) |
| --- | --- |
| [BC-IO-16](../../02.specification/behavior/behavioral-contracts/BC-IO-16.sample.md) | Sửa nháp không phát sinh tồn hay phê duyệt |
| [FND-01](../../02.specification/technical-contracts/FND-01-Idempotency.sample.md) | Cơ chế chống trùng dùng chung. CommandReceipt không thành child entity |

---

## Flow

### Main Flow

1. Đối chiếu domain, entity và behavioral contract để chốt root, thành viên, bất biến.
2. Mô tả lifecycle tại AGG-IO-01.
3. Review ranh giới để slice phụ thuộc dùng chung.

---

## Design

### Domain

**Before:** domain, entity và behavioral contract đã có. AGG-IO-01 còn là minh họa.
**After:** AGG-IO-01 chốt root, child, draft/submit, và giới hạn tác động.

---

## Verification

### Acceptance Criteria

- [ ] **AC-01** Given AGG-IO-01, When reviewer đọc, Then root, members, lifecycle và invariants được nêu rõ
- [ ] **AC-02** Given slice quick receipt phụ thuộc SL-001, When slice đó thiết kế, Then nó không tự đặt ranh giới aggregate

### Tests

| Test id | Given / When / Then | Layer |
| --- | --- | --- |
| `scn_boundary_review` | Reviewer đọc AGG-IO-01 | doc review |
