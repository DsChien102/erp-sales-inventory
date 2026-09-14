# TH-05 — Agent ritual

Thứ tự đọc bắt buộc khi triển khai một slice. Platform CQRS/module layout: [docs/architecture/README.md](../../../architecture/README.md).

**Trạng thái hiện tại:** harness docs CONTRACT S02–S34 `done`, S01 `n/a`. Application Dart contracts Phase 1 synced (note-only + session discard). Domain behavior, handler, gateway, RPC, schema và UI vẫn chưa được triển khai.

## Trước khi code

```text
1. AGENTS.md + .cursor/rules/vet45-architecture.mdc
2. docs/harness/PROGRESS.md
3. TH-05/README.md + OVERVIEWS.md
4. harness/04-slice-roadmap.md — lane status, parallel group, E2E blocker
5. harness/07-api-contracts.md — contract status và fake scenarios
6. Epic-{nn}-*/US-{nn}.md — FR/BR/AC/EC/SCN + UI artifacts
7. Theme-5-sales-orders.md — canonical context/ERD/UI contract khi cần
8. harness/01-domain-model.md + 02-module-map.md
9. harness/03-architecture-and-flows.md — commit/consistency/integration
10. harness/05-traceability.md — cập nhật Role row của slice
11. Skill theo lane:
    CONTRACT → application-layer
    BE domain → domain-layer
    BE handler/port → application-layer
    BE gateway/RPC → infrastructure-layer
    FE → presentation-layer + vet45-presentation-ui rule
12. harness/06-harness-notes.md — decisions/pitfalls/open blockers
```

## Contract freeze gate

1. Đọc section `frozen` trong [07-api-contracts.md](07-api-contracts.md) và public Dart contract trước khi mở BE/FE lane.
2. Không tự thay đổi field/nullability/enum trong khi implement; contract change phải quay lại review CONTRACT.
3. BE/FE dùng provider ports và 234 fake scenario definitions; external blocker chỉ chặn E2E.
4. Appendix 6.1 không tồn tại trong canonical source; không tự mở rộng wire shape.

S01 là runtime-only working state: không có persisted command. CONTRACT và BE là `n/a`; FE/E2E vẫn phải tuân execution context và UI contract.

## Trước khi sửa symbol

Theo GitNexus instructions trong [AGENTS.md](../../../../AGENTS.md):

1. `impact(target: "<symbol>", direction: "upstream")`.
2. Báo blast radius; dừng và cảnh báo nếu HIGH/CRITICAL.
3. Refactor/rename dùng GitNexus `rename`, không find/replace.

## SQL và integration

- DDL/RPC/RLS chỉ viết vào `supabase/migrations/_drafts/`.
- Không tạo/sửa timestamped migration nếu user chưa yêu cầu promote.
- RPC draft không đồng nghĩa đã apply.
- Business commit và outbox/impact request phải cùng transaction.
- E2E blocker ngoài module chỉ chặn E2E; CONTRACT/BE/FE dùng public ports và fakes.

## UI ritual

- Đọc `UI artifacts` trong US và screen group canonical trước khi đặt tên widget.
- Tạo widget manifest khi slice bắt đầu; không dùng tên suy diễn từ wireframe trong bootstrap.
- Page ≤ 500 dòng; dialog/widget lớn tách file.
- UI gọi `ISalesModule`/`IModuleMediator`, không gọi Supabase trực tiếp.
- Async server state dùng `vet45_async_query` theo playbook của repo.

## Reference code

| Mục đích | Path |
| --- | --- |
| CQRS + codegen + access wiring | `modules/iam/` |
| Application/domain layout | `modules/iam/` + `docs/MODULES_IMPLEMENTATION_TEMPLATE.md` |
| Pipeline testing | `packages/vet45_shared/testing/` |
| Command/handler annotations | `packages/vet45_generator/test/fixtures/lib/src/` |
| Thin page/widgets | `apps/erp/lib/features/dashboard/presentation/` |

**Không copy implementation từ `modules/sales/` hiện tại** — chỉ application contract/fakes là truth; implementation pattern vẫn mirror IAM.

## Sau khi code

```bash
melos bootstrap
melos run analyze
melos run test
melos run codegen
./scripts/ci/verify_harness.sh
cd apps/erp && flutter test
```

Slice có Supabase/worker:

```bash
melos run env:sync
melos run env:doctor
cd apps/messaging_worker && dart test
```

Trước commit: GitNexus `detect_changes(scope: "compare", base_ref: "main")`.
