# Domain Layer Skill

Canonical mirror of [`.cursor/skills/domain-layer/SKILL.md`](../.cursor/skills/domain-layer/SKILL.md). Cursor agents load the skill file; humans and external tools use this doc.

## Purpose

Implement và review code trong `modules/<module>/domain/` — aggregates, value objects, `IBusinessRule`, domain events, enums — từ harness `01-domain-model.md`.

```text
Domain quyết định hành vi nghiệp vụ hợp lệ.
Application điều phối use case.
Infrastructure triển khai kỹ thuật.
Presentation hiển thị cho người dùng.
```

**Phân tích model (FR → doc):** [ddd-domain-modeling skill](ddd_domain_modeling_skill.md)  
**Chi tiết:** `.cursor/skills/domain-layer/reference.md` · **Ví dụ:** `.cursor/skills/domain-layer/examples.md`

## Khi nào dùng

- Có `harness/01-domain-model.md` — implement domain code
- Scaffold `modules/*/domain/`
- Review PR domain layer

**Không** dùng cho phân tích Epic/US — dùng ddd-domain-modeling.

## Workflow (tóm tắt)

1. Đọc `01-domain-model.md` + `02-module-map.md`
2. Scaffold `lib/domain.dart` + `lib/src/<aggregate>/`
3. Implement: enums/VO → rules → aggregate → events (một class / file)
4. Test rule + aggregate behavior
5. Export barrel
6. `dart analyze` + `dart test` package domain

## Package boundaries

```text
MAY:     vet45_shared_domain, meta, uuid
MUST NOT: application, infrastructure, presentation, supabase, flutter, get_it
```

## Reference code

| Mode | Path |
|------|------|
| Full VO + rule | `modules/accounting/domain/lib/src/money.dart` |
| Interim thin | `modules/iam/domain/` |
| TH-03 target | `docs/themes/TH-03-partner/harness/01-domain-model.md` → `modules/partner/domain/` (khi implement) |

## Handoff

Sau domain → [application_layer_skill.md](application_layer_skill.md) (commands/handlers từ bảng Commands trong harness).

## Anti-patterns

God aggregate, CRUD on aggregate, rule in handler/RPC, `double` money, cross-module entity refs, nhiều rule/event một file.

## Liên kết

- [application_layer_skill.md](application_layer_skill.md)
- [ddd_domain_modeling_skill.md](ddd_domain_modeling_skill.md)
- [MODULES_IMPLEMENTATION_TEMPLATE.md](MODULES_IMPLEMENTATION_TEMPLATE.md)
- [harness/PROGRESS.md](harness/PROGRESS.md)
