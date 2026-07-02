# TH-02 — Agent ritual

Thứ tự đọc khi implement một FR slice. Platform CQRS/module layout: [docs/architecture/README.md](../../../architecture/README.md) — **không duplicate** ở đây.

## Trước khi code

```text
1. AGENTS.md + .cursor/rules/vet45-architecture.mdc
2. docs/harness/PROGRESS.md
3. TH-02/README.md
4. harness/04-slice-roadmap.md — lane status (Contract/BE/FE/E2E) + parallel group
5. harness/07-api-contracts.md — contract + fake scenarios (đọc TRƯỚC khi chọn lane)
6. EPIC-{nn}-*/US-{nn}/README.md
7. EPIC-{nn}-*/US-{nn}/FR-{nn}.md — BR/EC/UI/SCN (product)
8. harness/01-domain-model.md + harness/02-module-map.md
9. harness/03-architecture-and-flows.md — khi viết RPC/gateway (BE lane)
10. harness/05-traceability.md — cập nhật row theo Role khi slice in_progress
11. Skill theo layer / lane:
    - CONTRACT: application stubs + 07-api-contracts section
    - BE: domain / application / infrastructure skills
    - FE: presentation-layer skill + FakeCatalogModule scenarios
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
melos run codegen          # BE lane: sau handler/validator mới
./scripts/ci/verify_harness.sh
cd apps/erp && flutter test test/features/catalog/   # khi slice có UI
```

## Reference code

| Mục đích | Path |
| -------- | ---- |
| Codegen + CQRS wiring (golden) | `modules/iam/` + [modules/iam/README.md](../../../../modules/iam/README.md) |
| Partner codegen + vertical slice | `modules/partner/` + [modules/partner/README.md](../../../../modules/partner/README.md) |
| Command + handler annotations (fixtures) | `packages/vet45_generator/test/fixtures/lib/src/` |
| Domain VO + rule (full) | `modules/accounting/domain/lib/src/money.dart` |
| Pipeline test | `packages/vet45_shared/testing/test/shared_testing_test.dart` |
| Module layout | `docs/MODULES_IMPLEMENTATION_TEMPLATE.md` |
| Page mỏng + widgets tách file | `apps/erp/lib/features/dashboard/presentation/` |
| FE fake theo contract | `modules/catalog/application/lib/testing.dart` (`FakeCatalogModule`) |
| API contracts | [harness/07-api-contracts.md](07-api-contracts.md) |

**Copy CQRS + codegen pattern từ `modules/iam/` hoặc `modules/partner/`** — không copy từ `modules/sales/` (scaffold).
