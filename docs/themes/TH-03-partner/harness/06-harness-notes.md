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
| — | Dup-check chỉ UI | Ghi nhớ: RPC tenant-scoped khi implement US-02 FR-5 |
| — | Permission label tiếng Việt vs code | Bảng mapping trong 02-module-map.md |
| — | Epic-03 blocked | Chờ sales/inventory/accounting events |
| 2026-07-01 | BE/FE lane confusion | 07-api-contracts + FakePartnerModule + traceability Role column |
| 2026-07-02 | Partner hand-wired CQRS | Bật codegen (mirror IAM); cập nhật ritual + [modules/partner/README.md](../../../../modules/partner/README.md) |

## Liên kết

- [harness-engineering.md](../../../architecture/harness-engineering.md)
- [PROGRESS.md](../../../harness/PROGRESS.md)
