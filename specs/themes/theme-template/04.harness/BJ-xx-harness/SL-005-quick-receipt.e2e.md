# Work Slice: SL-005 — Quick receipt E2E

```yaml
id: SL-005
role: e2e
family: quick-receipt
sources: [UC-02-02, SCR-009]
theme: theme-07
sample_status: NON_CANONICAL_EXAMPLE
```

**design_status:** xem [CATALOG.md](CATALOG.md).

---

## 1. Objective

Chứng minh xuyên tầng: UI → mediator → RPC → kết quả PENDING_APPROVAL theo UC-02-02, không đổi tồn.

---

## 2. Blocked by

- [SL-003-quick-receipt.be-impl.md](SL-003-quick-receipt.be-impl.md)
- [SL-004-quick-receipt.fe.md](SL-004-quick-receipt.fe.md)

---

## 3. Scenarios & evidence

### Design / Contracts

- Contracts: [SL-002](SL-002-quick-receipt.be-contract.md)
- Impl: [SL-003](SL-003-quick-receipt.be-impl.md)
- FE: [SL-004](SL-004-quick-receipt.fe.md)

### Scenarios

| Scenario | Actor | Across | Expect |
| --- | --- | --- | --- |
| AS-UC-02-02-01 (sample) | Người lập | UI → RPC | Hồ sơ chờ duyệt, tồn không đổi |

### Evidence

- `06.evidence/` khi chạy Theme thật

---

## 4. Verification

- [ ] **AC-01** Happy path E2E
- [ ] **AC-02** Retry idempotent không double-submit nghiệp vụ

| Test id | Given / When / Then | Layer |
| --- | --- | --- |
| `scn_sl005_e2e` | … | e2e |

---

## 5. Delivery

### Next Action

- [ ] Chạy khi SL-003 + SL-004 đã VERIFIED trên catalog
