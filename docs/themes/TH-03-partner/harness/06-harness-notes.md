# TH-03 — Harness notes

## Guards áp dụng

| Guard | Script |
| ----- | ------ |
| Layer imports | `scripts/ci/guard_layer_imports.sh` |
| Infra Dart-only | `scripts/ci/guard_infra_dart_only.sh` |
| Theme docs structure | `scripts/ci/guard_theme_structure.sh` |
| Theme traceability | `scripts/ci/guard_theme_traceability.sh` |
| Presentation file size | `scripts/ci/guard_presentation_size.sh` |
| Inline dialogs in pages | `scripts/ci/guard_presentation_dialogs.sh` |
| Doc links | `scripts/ci/guard_docs_reference.sh` |

Umbrella: `scripts/ci/verify_harness.sh`

## Verify chain (mỗi slice)

```bash
melos bootstrap
melos run analyze
melos run test
melos run codegen          # sau handler mới (BE lane)
./scripts/ci/verify_harness.sh
cd apps/erp && flutter test test/features/partner/   # khi slice có UI
```

## Flywheel log

| Date | Lỗi / ghi chú | Biện pháp |
| ---- | ------------- | --------- |
| 2026-06-30 | Khởi tạo harness/ scaffold TH-03 | README + harness layer + guards |
| 2026-06-30 | God Widget / inline dialog | presentation-layer skill + UI guards + dashboard golden ref |
| - | Dup-check chỉ UI | Ghi nhớ: RPC tenant-scoped khi implement US-02 |
| - | Epic-03 E2E blocked | Chờ sales/inventory/accounting events end-to-end |
| 2026-07-01 | BE/FE lane confusion | 07-api-contracts + FakePartnerModule + traceability Role column |
| 2026-07-02 | Partner hand-wired CQRS | Bật codegen (mirror IAM) |
| **2026-07-07** | **Product spec v2 (Person/Organization) lệch harness + code cũ** | **Reboot: gỡ code partner + migrations cũ; viết lại harness v2 (Partner root, soft delete, contact, transform); reset slice S1..S9 todo; rebuild greenfield từ iam golden** |

## Pitfalls (v2)

- Không dùng lại model `entity_type = individual|household_business|company` — đã thay bằng `partner_type = person|organization`.
- Soft delete = `status = deleted`, không hard delete Phase 1.
- Transaction history = EP-01/US-07 (không còn Epic-03 folder).
- US spec = một file `US-{nn}.md` (không còn `FR-{nn}.md` riêng).
- Dup-check: warn-only Phase 1, không merge.

## Liên kết

- [harness-engineering.md](../../../architecture/harness-engineering.md)
- [PROGRESS.md](../../../harness/PROGRESS.md)
