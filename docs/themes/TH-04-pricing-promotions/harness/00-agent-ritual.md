# TH-04 EP02 — Agent ritual

Thứ tự đọc khi implement một slice. `pricing` là future bounded context greenfield; copy CQRS/access/codegen từ `modules/iam/`, không copy scaffold `modules/sales/`.

## Trước khi code

```text
1. AGENTS.md + .cursor/rules/c45-architecture.mdc
2. docs/harness/PROGRESS.md
3. TH-04/README.md + 01-business-scope.md
4. Theme-4-pricing-promotions.md — canonical product/UI/data spec
5. harness/04-slice-roadmap.md — chọn đúng slice/lane
6. harness/07-api-contracts.md — chốt contract/fake trước BE hoặc FE
7. Epic-02-customer-price-rules/US-{nn}.md — FR/BR/EC/SCN
8. harness/01-domain-model.md + 02-module-map.md
9. harness/03-architecture-and-flows.md — khi làm handler/gateway/RPC
10. harness/05-traceability.md — cập nhật đúng Role row
11. Skill theo layer trong AGENTS.md
12. UI lane: đọc Screen Group tương ứng và lập widget manifest trước khi code
```

## Scope locks

- Chỉ EP02 active. Không tiện tay implement EP01/EP03–EP06.
- Pricing không tính giá cuối đơn, không stacking promotion và không sửa order snapshot.
- Không import entity Catalog/Partner/Sales; dùng snapshot/port/public contract.
- Command handler không trả `Either`/`Result`; map lỗi ở presentation boundary.
- Không direct PostgREST write; mutation đi qua mediator → pipeline → handler → gateway → RPC.
- SQL chỉ được draft trong `supabase/migrations/_drafts/`; không tạo timestamp migration.
- **EP02 mutation:** đọc Theme-4 EP02 domain + [07-api-contracts.md](07-api-contracts.md) mục overwrite (`OVERWRITE_REQUIRED` / `acknowledgeOverwrite`) trước khi code. Docs có thể **ahead of code** (`DOC_AHEAD_OF_CODE` trong `07`/`06`); PR docs-only không sửa Dart/SQL.

## Trước khi sửa symbol

Theo AGENTS.md, chạy GitNexus upstream impact cho function/class/method sẽ sửa. Nếu HIGH/CRITICAL, báo blast radius trước khi tiếp tục. Docs-only update không có Dart symbol nên ghi rõ `n/a`.

## Sau khi code

```bash
melos bootstrap
melos run analyze
melos run test
melos run codegen
./scripts/ci/verify_harness.sh
cd apps/erp && flutter test test/features/pricing/
```

Chỉ chạy codegen/ERP feature tests khi artifact của slice tồn tại. RPC/worker slice cần env ritual trong AGENTS.md.

## Reference code

| Mục đích | Path |
| -------- | ---- |
| Golden CQRS/access/wiring | `modules/iam/` |
| CQRS fixtures | `packages/c45_generator/test/fixtures/lib/src/` |
| Pipeline harness | `packages/c45_shared/testing/` |
| Module target layout | `docs/MODULES_IMPLEMENTATION_TEMPLATE.md` |
| Harness engineering | `docs/architecture/harness-engineering.md` |
| EP02 contracts | [07-api-contracts.md](07-api-contracts.md) |

## Khi gặp lỗi lặp lại

Sau ba lần cùng failure mode, dừng retry; ghi nguyên nhân và guard/fake/doc cần bổ sung vào [06-harness-notes.md](06-harness-notes.md), rồi sửa harness trước khi tiếp tục.

