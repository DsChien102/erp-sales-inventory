# TH-03 — Agent ritual

Thứ tự đọc khi implement một FR slice. Platform CQRS/module layout: [docs/architecture/README.md](../../../architecture/README.md) — **không duplicate** ở đây.

## Trước khi code

```text
1. AGENTS.md + .cursor/rules/vet45-architecture.mdc
2. docs/harness/PROGRESS.md
3. TH-03/README.md
4. harness/04-slice-roadmap.md — prerequisite + status slice
5. Epic-{nn}/US-{nn}/01-overview.md
6. Epic-{nn}/US-{nn}/FR-{nn}.md — BR/EC/UI/SCN (product)
7. harness/01-domain-model.md + harness/02-module-map.md
8. harness/03-architecture-and-flows.md — khi viết RPC/gateway
9. harness/05-traceability.md — khi slice chuyển in_progress
10. Skill theo layer:
    - domain modeling (01-domain-model.md) → .cursor/skills/ddd-domain-modeling/SKILL.md
    - domain implementation (modules/*/domain) → .cursor/skills/domain-layer/SKILL.md
    - application → .cursor/skills/application-layer/SKILL.md
    - infrastructure → .cursor/skills/infrastructure-layer/SKILL.md
10b. FR có UI/Dialog/SCN:
    - presentation → .cursor/skills/presentation-layer/SKILL.md
    - đọc UI artifacts trong US/FR
    - tạo widget manifest (tên file) TRƯỚC khi implement
11. harness/06-harness-notes.md — pitfalls đã ghi
```

## Sau khi code

```bash
melos bootstrap
melos run analyze
melos run test
./scripts/ci/verify_harness.sh
cd apps/erp && flutter test test/features/partner/   # khi slice có UI
```

## Reference code (interim)

| Mục đích | Path |
| -------- | ---- |
| Command + handler + codegen | `packages/vet45_generator/test/fixtures/lib/src/` |
| Domain VO + rule (full) | `modules/accounting/domain/lib/src/money.dart` |
| Domain interim (thin) | `modules/iam/domain/` |
| Pipeline test | `packages/vet45_shared/testing/test/shared_testing_test.dart` |
| Module layout | `docs/MODULES_IMPLEMENTATION_TEMPLATE.md` |
| Page mỏng + widgets tách file | `apps/erp/lib/features/dashboard/presentation/` |

**Không copy** từ `modules/sales/` hoặc `modules/iam/` scaffold — chỉ từ fixtures/shared testing cho đến khi IAM golden land.
