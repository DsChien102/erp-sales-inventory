# Work Slice: SL-013 — Pin label E2E (EXAMPLE_ONLY)

```yaml
id: SL-013
role: e2e
family: pin-label
sources: [EXAMPLE-UC-01]
theme: example-only
sample_status: GOLDEN_BAR_B_FIXTURE
```

**design_status:** [CATALOG.md](CATALOG.md).

---

## 1. Objective

Chứng minh ghim nhãn xuyên UI → mediator → RPC → DB (hoặc fake stack) đạt AC EXAMPLE-UC-01.

---

## 2. Blocked by

- [SL-011-pin-label.be-impl.md](SL-011-pin-label.be-impl.md)
- [SL-012-pin-label.fe.md](SL-012-pin-label.fe.md)

---

## 3. Scenarios & evidence

### Design / Contracts

- Design: [SL-011](SL-011-pin-label.be-impl.md), Screen: [SL-012](SL-012-pin-label.fe.md)
- Contracts: [SL-010](SL-010-pin-label.be-contract.md)

### Scenarios

| Scenario | Actor | Across | Given / When / Then | Seed / fixture | Pass / fail |
| --- | --- | --- | --- | --- | --- |
| Happy pin | Staff | UI → mediator → RPC → DB | G: tenant T1 không nhãn / W: nhập `alpha` submit / T: UI success + một hàng `tenant_labels` | seed tenant `T1`; idempotencyKey `ik-1` | pass: một row label=`alpha`; fail: 0/2 rows hoặc UI không success |
| Replay | Staff | same | G: đã pin `alpha` với `ik-1` / W: submit lại cùng key+payload / T: UI success, `replayed`, vẫn một row | reuse `ik-1` | pass: vẫn 1 row; fail: row thứ hai |

### Evidence

- Điền sau khi chạy: `06.evidence/` hoặc link CI (không chặn READY fixture)

### Out of Scope

- Contract/UI mới

---

## 4. Verification

- [ ] **AC-01** Happy pin theo bảng
- [ ] **AC-02** Replay idempotent

| Test id | Given / When / Then | Layer |
| --- | --- | --- |
| `scn_sl013_e2e` | Happy pin G/W/T | e2e / integration |

---

## 5. Delivery

### Definition of Done

- [ ] Scenarios xanh + evidence link
- [ ] Catalog e2e → `VERIFIED`

### Next Action

- [ ] None (fixture)
