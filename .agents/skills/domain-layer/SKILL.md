---
name: domain-layer
description: Implements, reviews, and refactors the Domain layer in ERP modules — aggregates, value objects, business rules, domain events, and enums from harness domain models. Use when coding modules/*/domain/, implementing 01-domain-model.md, writing IBusinessRule, aggregate behavior, or when the user mentions domain layer, business invariant, or domain code (not DDD analysis).
---

# Domain Layer

## Mục đích

Domain layer **quyết định invariant nghiệp vụ** — không điều phối use case (application), không gọi Supabase/SQL (infrastructure), không hiển thị UI (presentation).

```text
Domain quyết định hành vi nghiệp vụ hợp lệ.
Application điều phối use case đang được thực thi.
Infrastructure triển khai kỹ thuật (RPC, views, cache, workers).
Presentation hiển thị cho người dùng.
```

**Đọc trước:** [reference.md](reference.md) · **Ví dụ:** [examples.md](examples.md) · **Phân tích model:** [ddd-domain-modeling](../ddd-domain-modeling/SKILL.md) · Canonical: `docs/domain_layer_skill.md`

---

## Khi nào dùng

- Implement slice sau khi có `harness/01-domain-model.md` (hoặc output từ ddd-domain-modeling)
- Scaffold hoặc mở rộng `modules/<module>/domain/`
- Review PR domain — God aggregate, rule leak, wrong layer
- Viết/test `IBusinessRule`, VO, aggregate method, domain event

**Không** dùng khi chỉ phân tích FR/Epic → [ddd-domain-modeling](../ddd-domain-modeling/SKILL.md) (sinh `01-domain-model.md`).

**Sau domain** → command/handler: [application-layer](../application-layer/SKILL.md).

---

## Workflow (6 bước)

### 1. Đọc input

```text
harness/01-domain-model.md   — aggregate, VO, rules, events, commands table (intent)
harness/02-module-map.md     — package paths
FR/BR trong US               — edge cases chưa có trong harness doc
```

Map bảng aggregate → folder `lib/src/<aggregate>/`.

### 2. Scaffold package

```text
modules/<module>/domain/
  pubspec.yaml                 # vet45_<module>_domain
  lib/
    domain.dart                # barrel — export public API only
    src/
      <aggregate_name>/
        rules/
        events/
```

`pubspec.yaml`: chỉ `vet45_shared_domain`, `meta`, `uuid` (và dev `test`, `vet45_lints`).

### 3. Implement theo thứ tự

```text
1. Enums / status value objects (closed set)
2. Value objects (validation trong constructor)
3. Business rules (một class / file trong rules/)
4. Aggregate root + entity con (mutation methods gọi checkRule)
5. Domain events (một class / file trong events/)
```

**Một class public = một file.** Không gom `*_rules.dart` hoặc `*_events.dart`.

### 4. Test

```text
- Rule: isBroken() true/false
- VO: reject invalid input at construction
- Aggregate: method happy path + invariant violation throws
- Không mock Supabase; không test persistence ở đây
```

Chạy: `cd modules/<module>/domain && dart test`

### 5. Export barrel

Chỉ export types mà **application** cần (aggregate, VO, permission constants, rule helpers public nếu có).

### 6. Verify

```bash
melos bootstrap
melos run analyze    # hoặc cd modules/<module>/domain && dart analyze
melos run test       # package domain
```

---

## Package boundaries

```text
Domain MAY depend on:
  vet45_shared_domain, meta, uuid

Domain MUST NOT depend on:
  <module>_application, <module>_infrastructure, <module>_presentation
  other_module_domain (trừ shared kernel)
  supabase, flutter, get_it
```

Cross-module data: **snapshot** qua application — không import entity module khác.

---

## Base types (`vet45_shared_domain`)

| Type | Dùng cho |
|------|----------|
| `Entity<Id>` | Aggregate root, entity con |
| `ValueObject` | VO immutable (`props`) |
| `IBusinessRule` | `isBroken()` + `message` |
| `DomainEventBase` | Domain event in-module |
| `IAggregateRoot` | Marker trên aggregate root |

Chi tiết template: [reference.md](reference.md).

---

## Thin vs full domain

| Mode | Khi nào | Ví dụ |
|------|---------|-------|
| **Full** | Slice có aggregate trong `01-domain-model.md` | [`modules/accounting/domain`](../../../modules/accounting/domain/lib/src/money.dart) |
| **Interim** | SRS chưa đủ; chỉ catalog/rule tĩnh | [`modules/iam/domain`](../../../modules/iam/domain) |

Interim **không** thay full aggregate — ghi note trong module docs; migrate khi SRS land.

---

## Handoff sang application

```text
Invariant / state transition  → aggregate method + IBusinessRule (domain)
Input shape / required fields → ICommandValidator (application) — không duplicate invariant
Handler                       → load aggregate qua port, gọi domain method, persist qua gateway
Permission code constants     → có thể đặt domain (static const) — application annotate @RequiresPermission
```

---

## Mapping với các layer khác

| Concern | Layer |
|---------|-------|
| Invariant, aggregate method | **Domain** (skill này) |
| Command/query, handler, DTO | Application |
| RPC, repository, mapper | Infrastructure |
| Widget, page | Presentation |
| Phân tích FR → model doc | ddd-domain-modeling |

---

## Agent output khi implement domain slice

```text
1.  Files created/updated (path list)
2.  Aggregate folder map
3.  Rules implemented (class → aggregate method)
4.  Events emitted (event → trigger method)
5.  Tests added
6.  Deferred items (interim vs full)
7.  Review checklist (checked)
```

---

## Anti-patterns (từ chối)

```text
- God aggregate
- CRUD method trên aggregate (updateProfile thay vì intent method)
- Cross-module entity reference
- Business rule trong handler, RPC, hoặc UI
- double cho tiền — Money integer minor units
- Domain import Flutter/Supabase/get_it
- Import package:.../src/... từ package khác
- Nhiều rule/event trong một file
- Domain event publish trực tiếp sang module khác (dùng integration event ở application/infra)
```

---

## Tài liệu thêm

- Templates & checklist: [reference.md](reference.md)
- Money, IAM interim, Partner snippet: [examples.md](examples.md)
- Design input: [ddd-domain-modeling](../ddd-domain-modeling/SKILL.md)
- Application handoff: [application-layer](../application-layer/SKILL.md)
- TH-03 model: `docs/themes/TH-03-partner/harness/01-domain-model.md`
