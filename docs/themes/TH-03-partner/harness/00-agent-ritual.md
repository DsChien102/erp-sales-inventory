# TH-03 — Agent ritual

Thứ tự đọc khi implement một FR slice. Platform CQRS/module layout: [docs/architecture/README.md](../../../architecture/README.md) — **không duplicate** ở đây.

## Trước khi code

```text
1. AGENTS.md + .cursor/rules/vet45-architecture.mdc
2. docs/harness/PROGRESS.md
3. TH-03/README.md
4. harness/04-slice-roadmap.md — lane status (Contract/BE/FE/E2E) + parallel group
5. harness/07-api-contracts.md — contract + fake scenarios (đọc TRƯỚC khi chọn lane)
6. Epic-{nn}/US-{nn}/01-overview.md
7. Epic-{nn}/US-{nn}/FR-{nn}.md — BR/EC/UI/SCN (product)
8. harness/01-domain-model.md + harness/02-module-map.md
9. harness/03-architecture-and-flows.md — khi viết RPC/gateway (BE lane)
10. harness/05-traceability.md — cập nhật row theo Role khi slice in_progress
11. Skill theo layer / lane:
    - CONTRACT: application stubs + 07-api-contracts section
    - BE: domain / application / infrastructure skills
    - FE: presentation-layer skill + FakePartnerModule scenarios
10b. FR có UI/Dialog/SCN:
    - đọc UI artifacts trong US/FR
    - tạo widget manifest (tên file) TRƯỚC khi implement
12. harness/06-harness-notes.md — pitfalls đã ghi
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
| FE fake theo contract | `modules/partner/application/lib/testing.dart` (`FakePartnerModule`) |
| Partner vertical slice | `modules/partner/` + `docs/themes/TH-03-partner/harness/07-api-contracts.md` |

**Không copy** từ `modules/sales/` hoặc `modules/iam/` scaffold — chỉ từ fixtures/shared testing cho đến khi IAM golden land.
