# Work Slice: SL-010 — Pin label contract (EXAMPLE_ONLY)

```yaml
id: SL-010
role: be-contract
family: pin-label
sources: [EXAMPLE-UC-01]
theme: example-only
sample_status: GOLDEN_BAR_B_FIXTURE
```

**design_status:** [CATALOG.md](CATALOG.md). Pseudo-schema — **không** copy vào theme Vet45.

---

## 1. Objective

Công bố Command/DTO/port (+ fake) để ghim nhãn tenant-scoped, đủ cho `be-impl` và `fe`.

---

## 2. Blocked by

- None

---

## 3. Scope (contract)

### In Scope

- `PinTenantLabelCommand` + `PinTenantLabelResultDto` + in-memory fake

### Out of Scope

- RPC/schema — [SL-011](SL-011-pin-label.be-impl.md)
- UI — [SL-012](SL-012-pin-label.fe.md)

### Rules

| ID | Quy tắc (slice) |
| --- | --- |
| EXAMPLE-UC-01 | Một tenant một nhãn active; retry cùng key không tạo bản thứ hai |

### Code Layout

```text
modules/
    example_labels/
        application/
            lib/
                src/
                    tenant_label/
                        commands/
                            pin_tenant_label/
                                pin_tenant_label_command.dart
                        shared/
                            pin_tenant_label_result_dto.dart
                        testing/
                            fake_tenant_label_port.dart
```

---

## 4. Contracts

#### PinTenantLabelCommand

> Gọi khi user ghim nhãn cho tenant hiện tại. Outcome: nhãn active được lưu; retry cùng idempotencyKey trả kết quả trước.

```dart
class PinTenantLabelCommand {
  final String idempotencyKey; // ≠ command.id
  final String tenantId;
  final String label;
}
```

#### PinTenantLabelResultDto

```dart
class PinTenantLabelResultDto {
  final String tenantId;
  final String label;
  final bool replayed;
}
```

#### Ports / fakes

- `ITenantLabelPort.pin({tenantId, label, idempotencyKey})` → `PinTenantLabelResultDto`
- `FakeTenantLabelPort` in-memory: cùng key + cùng payload → `replayed: true`; khác payload → throw conflict

#### Persistence

`N/A — impl owns` → [SL-011-pin-label.be-impl.md](SL-011-pin-label.be-impl.md)

#### Integration

- Không outbox / integration command trong fixture này

---

## 5. Verification

- [ ] **AC-01** Fence đủ field; blockquote trước Command
- [ ] **AC-02** Fake đủ cho FE test không cần DB

| Test id | Given / When / Then | Layer |
| --- | --- | --- |
| `scn_sl010_contract` | Consumer compile against fake | application fake |

---

## 6. Delivery

### Definition of Done

- [ ] Contracts + fake + Code Layout documented
- [ ] Catalog `READY_TO_IMPLEMENT` (fixture)

### Next Action

- [ ] Unblock SL-011 / SL-012
