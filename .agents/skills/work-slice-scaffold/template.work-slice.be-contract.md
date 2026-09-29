# Work Slice: SL-NNN — tiêu đề ngắn (be-contract)

```yaml
id: SL-NNN
role: be-contract
family: <family-slug>
sources: []
theme: # theme-xx
```

**design_status** trên [`CATALOG.md`](CATALOG.md). Gate code: catalog `READY_TO_IMPLEMENT`. Không invent field/RPC.

---

## 1. Objective

Một câu: contract Application (Command/Query/DTO/port) sẵn sàng cho `be-impl` và `fe`.

---

## 2. Blocked by

- `None` hoặc link slice / GitLab `#N` / URL

---

## 3. Scope (contract)

### In Scope

- Surface Command/Query/DTO/port (+ fake cho test)
- Validation rules ở application boundary (không persistence)

### Out of Scope

- RPC / schema / txn / idempotency persistence — thuộc `.be-impl`
- UI / screens — thuộc `.fe`

### Rules

| ID | Quy tắc (slice) |
| --- | --- |
| [`…`](…) | … |

---

## 4. Contracts

Mỗi type = H4 + blockquote (Command/Query bắt buộc) + Dart fence. Chi tiết field từ SRS đã chốt.

#### ExampleCommand

> Gọi khi …

```dart
class ExampleCommand {
  final String idempotencyKey; // ≠ command.id
}
```

#### ExampleQuery

> Đọc khi …

```dart
class ExampleQuery {
  final String id;
}
```

#### ExampleResultDto

```dart
class ExampleResultDto {
  final String id;
}
```

#### Ports / fakes

- Port interface + in-memory fake đủ cho unit/application test của consumer (`fe` / handler stub)

#### Persistence

`N/A — impl owns` (hoặc ghi rõ “schema draft thuộc SL-…be-impl”).

#### Integration (nếu contract công bố event/command name)

- Facts: `{context}_{entity}_{past}.v1`
- Handoff: `integration_commands` — không `*.requested` trên outbox

---

## 5. Verification

- [ ] **AC-01** Contract compile-shaped: mọi Command/Query có blockquote + fence khớp nguồn
- [ ] **AC-02** Fake/port đủ để `fe` / handler test không cần DB

| Test id | Given / When / Then | Layer |
| --- | --- | --- |
| `scn_…_contract` | … | application fake |

---

## 6. Delivery

### Definition of Done

- [ ] Contracts + fake documented
- [ ] Catalog row `READY_TO_IMPLEMENT` khi depends_on đủ

### Next Action

- [ ] Unblock `.be-impl` và `.fe` cùng family
