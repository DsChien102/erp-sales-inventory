# Work Slice: SL-004 — Quick receipt FE

```yaml
id: SL-004
role: fe
family: quick-receipt
sources: [UC-02-02, SCR-009]
theme: theme-07
sample_status: NON_CANONICAL_EXAMPLE
```

**design_status:** xem [CATALOG.md](CATALOG.md).

---

## 1. Objective

Giao diện quick mode (SCR-009) cho phép lập/gửi nhận hàng nhanh qua mediator + fake khớp SL-002.

---

## 2. Blocked by

- [SL-002-quick-receipt.be-contract.md](SL-002-quick-receipt.be-contract.md)

---

## 3. UI & presentation

### Screens / states / actions

| Screen | State / action | Nguồn |
| --- | --- | --- |
| SCR-009 | Quick mode: tìm SP, ĐVT, dòng, gửi | [SCR-009](../../03.design/screens/SCR-009.sample.md) |

### Mediator & fakes

- `IModuleMediator` + fake từ SL-002
- Presentation: `apps/erp/lib/features/…` — không module presentation

### Out of Scope

- RPC — [SL-003](SL-003-quick-receipt.be-impl.md)
- E2E — [SL-005](SL-005-quick-receipt.e2e.md)

---

## 4. Contracts

Link: [SL-002-quick-receipt.be-contract.md](SL-002-quick-receipt.be-contract.md)

---

## 5. Verification

- [ ] **AC-01** Happy path UI theo SCR-009 / UC-02-02
- [ ] **AC-02** Feedback lỗi / empty / loading

| Test id | Given / When / Then | Layer |
| --- | --- | --- |
| `scn_sl004_fe` | … | widget |

---

## 6. Delivery

### Next Action

- [ ] Unblock SL-005 khi SL-003 cũng VERIFIED/READY path xong
