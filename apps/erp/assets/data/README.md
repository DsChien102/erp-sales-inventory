# Vietnamese administrative units

Static dataset for province / ward dropdowns (partner create form).

Location: `assets/data/` at the **c45 repo root** (not under `modules/` or `packages/`).

## Source

- Upstream: [ThangLeQuoc/vietnamese-provinces-database](https://github.com/ThangLeQuoc/vietnamese-provinces-database)
- Upstream file: `json/vn_only_simplified_json_generated_data_vn_units.json`
- License: MIT (see upstream `LICENSE`)

## Files

| File | Purpose |
|------|---------|
| `vn_administrative_units.json` | Data (34 provinces, ~3.321 wards) |
| `vn_administrative_units.schema.json` | JSON Schema for the simplified vn-only shape |

## Refresh data

```bash
./scripts/data/sync_vn_administrative_units.sh
```

## Flutter bundle

Declared in `apps/erp/pubspec.yaml` (and formerly partner presentation — UI now lives under `apps/erp/lib/features/partner/`) via symlink `assets/` → repo root `assets/`.

Load with:

```dart
rootBundle.loadString('assets/data/vn_administrative_units.json');
```

## Dropdown mapping (partner delivery address)

| UI field | JSON field | Stored in DB |
|----------|------------|--------------|
| Tỉnh / Thành phố | `province.FullName` | `delivery_province` |
| Xã / Phường | `ward.FullName` | `delivery_commune` |

Use `Code` / `ProvinceCode` only for cascade filtering in UI; persistence stays text per TH-03 harness.
