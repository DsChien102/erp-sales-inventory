# 04 — Backlog & KPI

## KPI đo lường

| KPI | Baseline | Target (sau Wave 4) |
|-----|----------|---------------------|
| Golden page dùng `VPageScaffold` | 0 | 1 (Product Control Center) |
| Magic `EdgeInsets` literal trên golden | >10 | 0 |
| Raw `Text(` trên golden presentation | >15 | 0 (dùng `VText`) |
| Components có Tone trong audit | ~6/30 | Matrix Pass theo role |
| Required contracts Pass (Action/Input/Toggle/Status) | thấp | 100% sau Wave C |
| Example coverage cho layout primitives | 0 | 4/4 |

## Backlog ưu tiên

### P0 — Đã plan (Wave 1–4)

- [x] Polaris docs
- [x] Layout primitives
- [x] CI guard (usage)
- [x] Golden migration (control center)

### P2 — Contract hardening (Wave 5)

- [x] `08-component-contracts.md` + `contract_matrix.yaml`
- [x] P0 primitives (Badge/Chip/IconBox)
- [x] P1 controls + forms
- [x] P2 overlays + business
- [x] CI `--fail-on-required` (`guard_design_system_contracts.sh`)
- Chạy `dart run tool/component_audit.dart` sau mỗi component change

### P3 — Tooling

- custom_lint rules (optional)
- IDE snippet cho 5 recipes

## Cách đo

```bash
# Guard usage (catalog golden)
./scripts/ci/guard_design_system_usage.sh

# Guard contracts (required Tone/Emphasis/State/label)
./scripts/ci/guard_design_system_contracts.sh

# Component audit (report only)
cd packages/vet45_design_system && dart run tool/component_audit.dart
```
