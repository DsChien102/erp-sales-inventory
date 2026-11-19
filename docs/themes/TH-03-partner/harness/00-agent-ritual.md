# TH-03 — Agent ritual

Thứ tự đọc khi implement một slice. Platform CQRS/module layout: [docs/architecture/README.md](../../../architecture/README.md).

**Reboot 2026-07-07:** Module `partner` đang greenfield — copy pattern từ `modules/iam/` (golden), không từ code partner cũ (đã gỡ).

## Trước khi code

```text
1. AGENTS.md + .cursor/rules/c45-architecture.mdc
2. docs/harness/PROGRESS.md
3. TH-03/README.md
4. Theme-3-partner.md (theme context khi cần)
5. harness/04-slice-roadmap.md — lane status + parallel group
6. harness/07-api-contracts.md — contract + fake scenarios (TRƯỚC khi chọn lane)
7. Epic-{nn}-*/US-{nn}.md — FR table + BR/EC/SCN (product, một file/US)
8. harness/01-domain-model.md + harness/02-module-map.md
9. harness/03-architecture-and-flows.md — khi viết RPC/gateway (BE lane)
   - SQL schema: draft vào supabase/migrations/_drafts/ (AGENTS.md)
10. harness/05-traceability.md — cập nhật row theo Role khi slice in_progress
11. Skill theo layer / lane:
    - CONTRACT: application stubs + 07-api-contracts section
    - BE: domain / application / infrastructure skills
    - FE: presentation-layer skill + FakePartnerModule scenarios
11b. US có UI/Dialog/SCN:
    - đọc `Design Reference` trong US file
    - đọc Appendix A / Screen Group tương ứng trong `Theme-3-partner.md`
    - tạo widget manifest TRƯỚC khi implement
12. harness/06-harness-notes.md — pitfalls đã ghi
```

## Sau khi code

```bash
melos bootstrap
melos run analyze
melos run test
melos run codegen          # BE lane: sau handler/validator mới
./scripts/ci/verify_harness.sh
cd apps/erp && flutter test test/features/partner/   # khi slice có UI
```

## Reference code

| Mục đích | Path |
| -------- | ---- |
| Codegen + CQRS wiring (golden) | `modules/iam/` + [modules/iam/README.md](../../../../modules/iam/README.md) |
| Command + handler annotations (fixtures) | `packages/c45_generator/test/fixtures/lib/src/` |
| Pipeline test | `packages/c45_shared/testing/test/shared_testing_test.dart` |
| Module layout | `docs/MODULES_IMPLEMENTATION_TEMPLATE.md` |
| Page mỏng + widgets tách file | `apps/erp/lib/features/dashboard/presentation/` |
| API contracts | [harness/07-api-contracts.md](07-api-contracts.md) |

**Copy CQRS + codegen pattern từ `modules/iam/`** — không copy từ `modules/sales/` (scaffold).

Partner module sẽ tái tạo tại `modules/partner/` theo slice S1..S9 trong [04-slice-roadmap.md](04-slice-roadmap.md).
