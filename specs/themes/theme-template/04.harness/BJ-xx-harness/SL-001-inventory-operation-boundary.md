# Work Slice: SL-001 — Khóa ranh giới InventoryOperation

```yaml
id: SL-001
role: full
family:
sources: [DOM-IO, ENT-IO-01, AGG-IO-01, BC-IO-16, FND-01]
theme: theme-07
sample_status: NON_CANONICAL_EXAMPLE
```

**design_status:** xem [CATALOG.md](CATALOG.md). Sample minh họa `full` (không UI).

---

## 1. Objective

Xác lập ranh giới nhất quán của InventoryOperation để các UC dùng chung lifecycle Domain đã review.

---

## 2. Blocked by

None

---

## 3. Scope & Rules

### In Scope

- Root, Entity/VO bên trong, lifecycle draft/submit, concurrency và ranh giới lưu trữ logic Aggregate

### Out of Scope

- Application Command/Query từng UC, Screen, Product/Supplier master, ApprovalCase, biến động tồn

### Rules

| ID | Quy tắc (slice) |
| --- | --- |
| [BC-IO-16](../../02.specification/behavior/behavioral-contracts/BC-IO-16.sample.md) | Sửa nháp không phát sinh tồn/phê duyệt |
| [FND-01](../../02.specification/technical-contracts/FND-01-Idempotency.sample.md) | Cơ chế chống trùng dùng chung — không biến CommandReceipt thành child Entity |

---

## 4. Flow

### Main Flow

1. Đối chiếu Domain/Entity/BC → Root, thành viên, bất biến
2. Mô tả lifecycle tại AGG-IO-01
3. Review ranh giới BA/SA → công bố cho slice phụ thuộc

### Failure Flow

N/A — design/doc slice (không mutation runtime)

---

## 5. Design

**Before:** Domain/Entity/BC có; AGG-IO-01 còn minh họa.  
**After:** AGG-IO-01 chốt Root/child, draft/submit, giới hạn tác động.

Persistence / Txn / Idempotency: `N/A — domain boundary doc`; runtime thuộc family UC sau.

---

## 6. Contracts

N/A — không publish Command/Query ở slice này. Consumer đọc AGG-IO-01 + BC.

---

## 7. Verification

- [ ] **AC-01** AGG-IO-01 nêu rõ Root, members, lifecycle, invariants
- [ ] **AC-02** Slice phụ thuộc (quick-receipt) không tự quyết ranh giới thay

| Test id | Given / When / Then | Layer |
| --- | --- | --- |
| `scn_sl001_boundary` | Reviewer đọc AGG → ranh giới khớp BC | doc review |

---

## 8. Delivery

### Definition of Done

- [ ] AGG-IO-01 reviewed; catalog sẵn sàng nâng status khi depends_on thật đủ

### Next Action

- [ ] Human review → catalog `IN_REVIEW` / `READY_TO_IMPLEMENT`
