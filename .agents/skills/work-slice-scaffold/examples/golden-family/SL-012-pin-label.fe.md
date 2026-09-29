# Work Slice: SL-012 — Pin label FE (EXAMPLE_ONLY)

```yaml
id: SL-012
role: fe
family: pin-label
sources: [EXAMPLE-SCR-01]
theme: example-only
sample_status: GOLDEN_BAR_B_FIXTURE
```

**design_status:** [CATALOG.md](CATALOG.md). Contracts: [SL-010](SL-010-pin-label.be-contract.md).

---

## 1. Objective

Màn hình ghim nhãn: nhập label → submit → feedback theo contract.

---

## 2. Blocked by

- [SL-010-pin-label.be-contract.md](SL-010-pin-label.be-contract.md)

---

## 3. UI & presentation

### Screens / states / actions

| Screen | State / action | Nguồn |
| --- | --- | --- |
| Pin label | view / submit | EXAMPLE-SCR-01 |

### Route / entry

- `/settings/pin-label` (ERP shell example)

### State × feedback

| State | UI / feedback | Error code (nếu có) |
| --- | --- | --- |
| loading | disable submit + spinner | — |
| empty | hint “Nhập nhãn” | — |
| error | snackbar / inline | `LABEL_INVALID`, `IDEMPOTENCY_CONFLICT` |
| success | show label đã ghim | — |

### Design system

- `Vet45TextField`, `Vet45PrimaryButton`, snackbar pattern từ DS — không invent token

### Mediator & fakes

- `IModuleMediator.send(PinTenantLabelCommand)`
- Dev: `FakeTenantLabelPort` từ SL-010
- Presentation: `apps/erp/...` — không `modules/*/presentation`

### Code Layout

```text
apps/
    erp/
        lib/
            features/
                settings/
                    presentation/
                        pin_label_page.dart
                        widgets/
                            pin_label_form.dart
```

### Out of Scope

- RPC — [SL-011](SL-011-pin-label.be-impl.md)
- E2E — [SL-013](SL-013-pin-label.e2e.md)

---

## 4. Contracts

Link: [SL-010-pin-label.be-contract.md](SL-010-pin-label.be-contract.md)

---

## 5. Verification

- [ ] **AC-01** Submit hợp lệ → success state hiện label
- [ ] **AC-02** `LABEL_INVALID` → error feedback theo bảng

| Test id | Given / When / Then | Layer |
| --- | --- | --- |
| `scn_sl012_fe` | Submit blank → error UI | widget |

---

## 6. Delivery

### Definition of Done

- [ ] UI AC xanh; changelog nếu ship user-facing
- [ ] Catalog → `VERIFIED` sau code-review

### Next Action

- [ ] Unblock SL-013 khi SL-011 cũng xong
