# DDD Domain Modeling Skill

Canonical mirror of [`.cursor/skills/ddd-domain-modeling/SKILL.md`](../.cursor/skills/ddd-domain-modeling/SKILL.md). Cursor agents load the skill file; humans and external tools use this doc.

## Purpose

Phân tích nghiệp vụ và thiết kế domain model theo Tactical DDD cho ERP Modular Monolith (Flutter/Dart + Supabase).

```text
Domain quyết định hành vi nghiệp vụ hợp lệ.
Application điều phối use case.
Infrastructure triển khai kỹ thuật.
Presentation hiển thị cho người dùng.
```

**Chi tiết:** `.cursor/skills/ddd-domain-modeling/reference.md` · **Ví dụ:** `.cursor/skills/ddd-domain-modeling/examples.md`

**Lưu ý:** `modules/*` hiện là skeleton. Ví dụ Sales trong skill examples là **target state**. Domain code thật duy nhất: `modules/accounting/domain/lib/src/money.dart`.

## Khi nào dùng

- Phân tích Epic / User Story / Business Rule
- Thiết kế bounded context, aggregate, value object
- Đặt tên command/query theo intent nghiệp vụ
- Review tránh God Aggregate
- Chuẩn bị `modules/<module>/domain/`

## Quy trình (7 bước)

1. **Lifecycle nghiệp vụ** — draft → commit → fulfill; ai owns data; điểm commit
2. **Bounded context** — tách theo capability, không theo UI
3. **Aggregate** — một consistency boundary; tách draft vs committed entity
4. **Entity vs VO** — snapshot pattern cho cross-module; `Money` integer minor units
5. **Business rules** — `implements IBusinessRule`, một file / rule
6. **Commands** — intent naming (`CheckoutSalesOrderCommand`, không `UpdateOrder`)
7. **Queries** — read-only, trả DTO, không leak aggregate

## Domain folder convention

```text
modules/<module>/domain/lib/
  domain.dart
  src/<aggregate>/
    <aggregate>.dart
    rules/<rule_name>_rule.dart
    events/<event_name>_domain_event.dart
```

Base types: `vet45_shared_domain` — `Entity`, `ValueObject`, `IBusinessRule`, `AggregateRoot`.

## Required agent output

```text
1.  Tóm tắt nghiệp vụ & lifecycle
2.  Bounded context map
3.  Danh sách aggregate
4.  Business rules table
5.  Commands table
6.  Queries table
7.  Domain events
8.  Integration events
9.  Domain services (nếu có)
10. Snapshot/ports cần application load
11. Anti-pattern warnings
12. Review checklist
```

## Anti-patterns

- God Aggregate, CRUD commands, cross-module entity references
- Business rules in repository/infrastructure/UI
- `double` for money, domain imports Flutter/Supabase

## Liên kết

- [application_layer_skill.md](application_layer_skill.md)
- [MODULES_IMPLEMENTATION_TEMPLATE.md](MODULES_IMPLEMENTATION_TEMPLATE.md)
- [harness-engineering.md](architecture/harness-engineering.md)
- [harness/PROGRESS.md](harness/PROGRESS.md)
