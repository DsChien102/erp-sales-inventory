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
| 2026-07-04 | Product docs tách từ `theme_snapshot` → OVERVIEWS / APPENDICES / EPIC (98 FR); status `pending` / `out_of_scope`; harness lệch Epic ID + roadmap | Realign harness `00`–`07` + README terminology; catalog vẫn skeleton |
| 2026-07-03 | **Spec v3 migration** — 7 epics, readiness, guided create, thông tin bổ sung, base price, stock/base price modes | Regenerated EPIC-* tree; reset traceability + slice roadmap; 07-api-contracts partial |
| 2026-07-02 | Khởi tạo harness/ scaffold TH-02 | README + harness layer + flip in_progress |
| — | Dup-check SKU/barcode chỉ UI | RPC tenant-scoped unique index khi implement EPIC-02/US-01 |
| — | Giá vốn từ costing | Catalog read gateway; Growth tier only |
| — | Basic vs Advanced stock | Basic = chỉnh trong Product; Advanced = read inventory |
| — | Không hard-code ngành vào Product | Nhóm & trường thông tin bổ sung (EPIC-03); folder `EPIC-03-industry-fields/` giữ tên |
| — | Epic folder naming | `EPIC-{nn}-{slug}/` — guard check `US-*` |
| — | EPIC-04/US-03 đổi base unit | `out_of_scope` — không implement |
| — | EPIC-01/US-02/FR-04 checklist PCC | `pending` — PCC dùng readinessSummary sớm |

## Liên kết

- [harness-engineering.md](../../../architecture/harness-engineering.md)
- [PROGRESS.md](../../../harness/PROGRESS.md)
- [OVERVIEWS.md](../OVERVIEWS.md) · [APPENDICES.md](../APPENDICES.md)
