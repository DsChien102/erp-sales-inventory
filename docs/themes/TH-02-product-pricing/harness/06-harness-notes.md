# TH-02 — Harness notes

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
cd apps/erp && flutter test test/features/catalog/   # khi slice có UI
```

## Flywheel log

| Date | Lỗi / ghi chú | Biện pháp |
| ---- | ------------- | --------- |
| 2026-07-02 | Khởi tạo harness/ scaffold TH-02 | README + harness layer + flip in_progress |
| — | Dup-check SKU/barcode chỉ UI | Ghi nhớ: RPC tenant-scoped unique index khi implement US-01 |
| — | Giá vốn từ TH-06 | Catalog chỉ read gateway; không consume event ở slice đầu |
| — | Tồn cơ bản vs TH-06 | AdjustBasicStock ≠ phiếu điều chỉnh kho — doc boundary trong 02-module-map |
| — | Đổi base unit không auto-reprice | US-05/FR-05 BR-07 — không tính lại giá trong command |
| — | Epic folder naming | TH-02 dùng `EPIC-01-product/` (khác TH-03 `Epic-01-*`) — guard chỉ check `US-*` |

## Liên kết

- [harness-engineering.md](../../../architecture/harness-engineering.md)
- [PROGRESS.md](../../../harness/PROGRESS.md)
