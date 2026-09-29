# Work Slice: SL-003 — Quick receipt BE impl

```yaml
id: SL-003
role: be-impl
family: quick-receipt
sources: [UC-02-02, FND-01, AGG-IO-01]
theme: theme-07
sample_status: NON_CANONICAL_EXAMPLE
```

**design_status:** xem [CATALOG.md](CATALOG.md).

---

## 1. Objective

Thực thi RPC/handler/persistence để submit nhận hàng nhanh đúng contract SL-002, chưa đổi tồn vật lý.

---

## 2. Blocked by

- [SL-002-quick-receipt.be-contract.md](SL-002-quick-receipt.be-contract.md)

---

## 3. Persistence & runtime

### Tables / draft

Sample: liệt kê bảng từ Domain đã chốt khi Theme thật; không invent tên ở đây.

> Draft: `supabase/migrations/_drafts/<scope>_quick_receipt.sql` (khi có)

### Transaction

Must commit atomically:

- business mutation hồ sơ
- outbox facts (nếu có lifecycle fact)
- idempotency begin/complete

### Idempotency

- `idempotencyKey` ≠ `command.id`
- UK `(tenant_id, command_scope, idempotency_key)` — xem [FND-01](../../02.specification/technical-contracts/FND-01-Idempotency.sample.md)

### Integration

- Outbox = facts only
- Handoff phê duyệt/tồn = `integration_commands` khi có — không `*.requested` IE

---

## 4. Contracts

Link: [SL-002-quick-receipt.be-contract.md](SL-002-quick-receipt.be-contract.md)

---

## 5. Verification

- [ ] **AC-01** Submit → PENDING_APPROVAL, không đổi tồn
- [ ] **AC-02** Retry cùng key + hash → prior snapshot

| Test id | Given / When / Then | Layer |
| --- | --- | --- |
| `scn_sl003_submit` | … | application / RPC |

---

## 6. Delivery

### Next Action

- [ ] Implement khi catalog READY; song song/ tuần tự với SL-004 sau SL-002
