# 04 — Backlog & KPI

## KPI đo lường

| KPI | Baseline | Target (sau Wave 4) |
|-----|----------|---------------------|
| Golden page dùng `VPageScaffold` | 0 | 1 (Product Control Center) |
| Magic `EdgeInsets` literal trên golden | >10 | 0 |
| Raw `Text(` trên golden presentation | >15 | 0 (dùng `VText`) |
| Components có Tone trong audit | ~6/30 | Giữ; tăng dần wave 5+ |
| Example coverage cho layout primitives | 0 | 4/4 |

## Backlog ưu tiên

### P0 — Đã plan (Wave 1–4)

- [x] Polaris docs
- [ ] Layout primitives
- [ ] CI guard
- [ ] Golden migration (control center)

### P1 — Sau golden

- Migrate catalog settings pages theo lane
- Migrate partner presentation widgets
- Promote `ProductControlCenterSectionCard` pattern → generic `VSection` usage doc

### P2 — Contract hardening

- `VBadge`, `VCard`, `VEmptyState` → Tone/State
- Chạy `dart run tool/component_audit.dart` sau mỗi component change
- Screenshot/golden tests cho example tabs

### P3 — Tooling

- custom_lint rules (optional)
- IDE snippet cho 5 recipes

## Cách đo

```bash
# Guard (sau Wave 3)
./scripts/ci/guard_design_system_usage.sh

# Component audit
cd packages/vet45_design_system && dart run tool/component_audit.dart

# Adoption spot-check
rg "EdgeInsets\.(all|symmetric|only)\([0-9]" apps/erp/lib/features/catalog/presentation --glob '*.dart' -c
rg "VPageScaffold|VGap|VPagePadding" apps/erp/lib/features/catalog/presentation --glob '*.dart' -c
```
