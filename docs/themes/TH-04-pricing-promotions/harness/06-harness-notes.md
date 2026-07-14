# TH-04 EP02 — Harness notes

## Guards

| Guard | Script |
| ----- | ------ |
| Theme structure | `scripts/ci/guard_theme_structure.sh` |
| Theme traceability | `scripts/ci/guard_theme_traceability.sh` |
| Documentation links | `scripts/ci/guard_docs_reference.sh` |
| Layer imports | `scripts/ci/guard_layer_imports.sh` |
| Infrastructure Dart-only | `scripts/ci/guard_infra_dart_only.sh` |
| Presentation size/dialogs | `scripts/ci/guard_presentation_size.sh`, `scripts/ci/guard_presentation_dialogs.sh` |

Umbrella: `scripts/ci/verify_harness.sh`.

## Verify chain per implementation slice

```bash
melos bootstrap
melos run analyze
melos run test
melos run codegen
./scripts/ci/verify_harness.sh
cd apps/erp && flutter test test/features/pricing/
```

## Decisions captured on 2026-07-14

- Recreated TH-04 after `dev` fetch removed earlier local work.
- `Theme-3-partner.md` is the formatting/canonical-document standard.
- Six epic folders are retained; only EP02 is active.
- Future owner is `pricing`; `catalog`, `partner`, `sales`, `iam` are supporting contexts.
- RPC-first CQRS replaces legacy REST endpoint notation from the source document.
- Money uses integer minor units in Dart/contracts.
- `expired` is derived; activity is append-only; memory request is idempotent.
- S9 Pricing lanes are actionable, but E2E is blocked by Sales.

## Pitfalls

- Không nhầm TH-02 product/base price với TH-04 customer-specific policy.
- Không đặt final-price calculation vào `CustomerPriceRule` aggregate.
- Không dùng customer/product/unit display label làm identity.
- Không bỏ `product_unit_id` vì Excel V1 thiếu cột unit; phải resolve hoặc row error.
- Không tin precheck/cache tại commit time.
- Không overwrite active manual rule từ Sales memory request mặc định.
- Không lưu tiền bằng `double`.
- Không ghi activity sau transaction như best-effort side effect; activity phải cùng commit.
- Không coi RPC draft là migration đã apply.

## Flywheel log

| Date | Observation | Harness response |
| ---- | ----------- | ---------------- |
| 2026-07-14 | TH-04 cũ mất sau fetch; catalog còn stale Sales link | Recreate canonical TH-04 folder and reconcile catalog/cross-links. |
| 2026-07-14 | Source spec dùng REST references | Normalize to CQRS symbols + `pricing.*` RPC targets. |
| 2026-07-14 | Sales dependency có thể block toàn S9 | Block only E2E lane; use fake/public contract for CONTRACT/BE/FE. |

## Open follow-ups

- Chốt default below-floor policy và memory upsert interval semantics trước S1/S9 BE sign-off.
- Chốt identifier columns/template version cho Excel trước S8 contract freeze.
- Khi code bắt đầu, cập nhật `docs/harness/PROGRESS.md` và module catalog theo ritual chung.

