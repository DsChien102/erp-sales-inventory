# TH-01 — Agent ritual

Thứ tự đọc khi implement một slice. Platform CQRS/module layout: [docs/architecture/README.md](../../../architecture/README.md).

**Golden module:** mở rộng [`modules/iam/`](../../../../modules/iam/README.md) (codegen + pipeline đã bật). Không scaffold module mới cho Theme 1 owner.

Hai application surface: **Tenant App** = [`apps/erp`](../../../../apps/erp); **Platform Admin App** = [`apps/admin`](../../../../apps/admin) (scaffold — Melos wiring sau).

## Trước khi code

```text
1. AGENTS.md + .cursor/rules/vet45-architecture.mdc
2. docs/harness/PROGRESS.md
3. TH-01/README.md + OVERVIEWS.md
4. Theme-1-organization-users.md (theme context khi cần)
5. harness/04-slice-roadmap.md — lane status + parallel group
6. harness/07-api-contracts.md — contract + fake scenarios (TRƯỚC khi chọn lane)
7. Epic-{nn}-*/US-{nn}.md — FR table + BR/EC/SCN (product, một file/US)
8. harness/01-domain-model.md + harness/02-module-map.md
9. harness/03-architecture-and-flows.md — khi viết RPC/gateway / Resend / App Link (BE lane)
   - SQL schema: draft vào supabase/migrations/_drafts/ (AGENTS.md)
10. harness/05-traceability.md — cập nhật row theo Role khi slice in_progress
11. Skill theo layer / lane:
    - CONTRACT: application stubs + 07-api-contracts section
    - BE: domain / application / infrastructure skills
    - FE: presentation-layer skill + FakeIamModule scenarios
11b. US có UI/Dialog/SCN:
    - đọc `Design Reference` trong US file
    - đọc Screen Group tương ứng trong Theme-1-organization-users.md §5
    - tạo widget manifest TRƯỚC khi implement
12. harness/06-harness-notes.md — pitfalls đã ghi (Owner≠role, Resend, App Link)
```

## Sau khi code

```bash
melos bootstrap
melos run analyze
melos run test
melos run codegen          # BE lane: sau handler/validator mới
./scripts/ci/verify_harness.sh
cd apps/erp && flutter test test/features/   # khi slice có Tenant App UI
# apps/admin: khi slice Admin có UI và app đã vào Melos
```

## Reference code

| Mục đích | Path |
| -------- | ---- |
| Codegen + CQRS wiring (golden) | `modules/iam/` + [modules/iam/README.md](../../../../modules/iam/README.md) |
| Command + handler annotations (fixtures) | `packages/vet45_generator/test/fixtures/lib/src/` |
| Pipeline test | `packages/vet45_shared/testing/test/shared_testing_test.dart` |
| Module layout | `docs/MODULES_IMPLEMENTATION_TEMPLATE.md` |
| Page mỏng + widgets tách file | `apps/erp/lib/features/dashboard/presentation/` |
| API contracts | [harness/07-api-contracts.md](07-api-contracts.md) |
| Product appendices | [APPENDICES.md](../APPENDICES.md) |

**Copy CQRS + codegen pattern từ `modules/iam/`** — không copy từ `modules/sales/` (scaffold).

Slice order: [04-slice-roadmap.md](04-slice-roadmap.md).
