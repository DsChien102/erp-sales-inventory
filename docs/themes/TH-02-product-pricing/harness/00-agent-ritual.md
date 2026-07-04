# TH-02 — Agent ritual

Thứ tự đọc khi implement một FR slice. Platform CQRS/module layout: [docs/architecture/README.md](../../../architecture/README.md) — **không duplicate** ở đây.

## Trước khi code

```text
1. AGENTS.md + .cursor/rules/vet45-architecture.mdc
2. docs/harness/PROGRESS.md
3. TH-02/README.md
4. [OVERVIEWS.md](../OVERVIEWS.md) — yêu cầu xuyên suốt, readiness, validation (khi cần)
5. harness/04-slice-roadmap.md — lane status (Contract/BE/FE/E2E) + parallel group
6. harness/07-api-contracts.md — contract + fake scenarios (đọc TRƯỚC khi chọn lane)
7. EPIC-{nn}-*/US-{nn}/README.md — kiểm tra Status (in_scope | pending | out_of_scope)
8. EPIC-{nn}-*/US-{nn}/FR-{nn}.md — BR/EC/UI/SCN; bỏ qua FR pending/out_of_scope
9. harness/01-domain-model.md + harness/02-module-map.md
10. [APPENDICES.md](../APPENDICES.md) — flows, ERD, permissions (khi cần)
11. harness/03-architecture-and-flows.md — khi viết RPC/gateway (BE lane)
    - SQL schema: draft vào `supabase/migrations/_drafts/` (AGENTS.md — Schema & migration)
12. harness/05-traceability.md — cập nhật row theo Role khi slice in_progress
13. Skill theo layer / lane:
    - CONTRACT: application stubs + 07-api-contracts section
    - BE: domain / application / infrastructure skills
    - FE: presentation-layer skill + FakeCatalogModule scenarios
14. FR có UI/Dialog/SCN:
    - đọc UI artifacts trong US/FR
    - tạo widget manifest (tên file) TRƯỚC khi implement
15. harness/06-harness-notes.md — pitfalls đã ghi
```

**Status rule:** US/FR có `pending` hoặc `out_of_scope` → **không** mở lane BE/FE/E2E. CONTRACT chỉ ghi chú trong roadmap/contracts nếu cần, không implement handler/UI.

Phân biệt readiness:

- EPIC-02/US-03 — readiness **summary/blocker** sau create: implement.
- EPIC-01/US-02/FR-04 — checklist đầy đủ trên Product Control Center: **pending** (PCC làm FR-01..03, FR-05..06).

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
