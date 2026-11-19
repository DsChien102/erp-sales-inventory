# 09 — Design System Adoption Checklist

Checklist theo dõi migrate presentation UI sang DS + CI guard.

## CI guards

| Script | Mục đích |
|--------|----------|
| [`scripts/ci/guard_design_system_usage.sh`](../../../../scripts/ci/guard_design_system_usage.sh) | Magic spacing, raw Text/overlays/Scaffold/Colors |
| [`scripts/ci/guard_design_system_contracts.sh`](../../../../scripts/ci/guard_design_system_contracts.sh) | Tone/Emphasis/State matrix trong package DS |

### Usage guard tiers

| Tier | Path | CI hành vi |
|------|------|------------|
| **ENFORCED** | `product_control_center*`, `product_catalog*` (tab + widgets) | **ERROR** → fail |
| **MONITORED** | `apps/erp/lib/features/*/presentation/**`, `modules/*/presentation/lib/src/widgets/**` | **WARN** (không fail) |
| Skip | `bloc/`, `*_cubit.dart`, `*_state.dart`, mappers/models/services/data, `harness:allow-design-system-bypass` | Bỏ qua |

Env overrides:

```bash
# Không fail cả enforced (debug local)
GUARD_DESIGN_SYSTEM_LEGACY=1 ./scripts/ci/guard_design_system_usage.sh

# Fail cả monitored (thắt khi lane sạch)
GUARD_DESIGN_SYSTEM_STRICT=1 ./scripts/ci/guard_design_system_usage.sh
```

Wired: `./scripts/ci/verify_harness.sh`

---

## PR checklist (mọi PR chạm UI)

Copy vào PR description hoặc ticket:

### Layout & tokens

- [ ] Không `EdgeInsets.*(số literal)` — dùng `VSpacing` / `VGap` / `VPagePadding`
- [ ] Page shell dùng `VPageScaffold` (không raw `Scaffold` trừ case đặc biệt + comment)
- [ ] Typography qua `VText` + `VTextVariant` (không `Text(` / không `VTypography.*.copyWith` ở feature)

### Components

- [ ] Button → `VButton`; FAB → `VFloatingActionButton`
- [ ] Field → `VTextField` / form fields DS
- [ ] Empty → `VEmptyState`
- [ ] Confirm → `showVConfirmDialog` (1 dialog = 1 file)
- [ ] Sheet → `showVBottomSheet`
- [ ] Color → `context.vColors` / semantic (không `Colors.grey` / `Colors.black` …)

### Contracts (khi sửa DS public widget)

- [ ] Tone / Emphasis / State theo [08-component-contracts.md](08-component-contracts.md)
- [ ] Example catalog + `dart run tool/component_audit.dart [--fail-on-required]`

### Verify

```bash
./scripts/ci/guard_design_system_usage.sh
./scripts/ci/guard_design_system_contracts.sh
```

Chi tiết token: [07-token-migration-checklist.md](07-token-migration-checklist.md)

---

## Adoption backlog (ưu tiên mở rộng ENFORCED)

Đánh dấu khi lane đã migrate xong rồi thêm pattern vào `is_enforced` trong guard script.

### Catalog — apps/erp

- [x] Product Control Center (`product_control_center*`)
- [x] Product Catalog Tab (`product_catalog_*`, `product_list_filter.dart`)
- [ ] Measurement units + bottom bar
- [ ] Price bands + edit unit price band
- [ ] Manual base price / stock adjustment
- [ ] Guided create (page + module widgets)
- [ ] Images / profile maintenance
- [ ] Custom field settings pages + sheets/dialogs
- [ ] Store price rule settings + history

### Catalog — modules/catalog/presentation widgets

- [ ] `product_list_item_tile`, search bar, guided steps
- [ ] Image picker panel / gallery / dialogs

### Partner

- [ ] Partner list / detail / contacts pages (`apps/erp`)
- [ ] Module partner widgets (tiles, sheets, sections)

### More / Auth / Dashboard

- [ ] System + e-invoice settings pages
- [ ] Login / dashboard shell → `VPageScaffold`

### Cách promote một lane lên ENFORCED

1. Migrate file theo [07](07-token-migration-checklist.md) đến khi:
   `./scripts/ci/guard_design_system_usage.sh` không còn WARN cho path đó (hoặc chạy với `STRICT=1` trên subset).
2. Thêm glob path vào block **ENFORCED** trong `guard_design_system_usage.sh`.
3. Tick item trong backlog này.
4. Không thêm `harness:allow-design-system-bypass` trừ tạm thời có ticket theo dõi.

---

## Heuristic scan (manual)

```bash
# Magic spacing debt
rg -c 'EdgeInsets\.(all|symmetric|only)\(\s*[0-9]' \
  apps/erp/lib/features modules/*/presentation/lib --glob '*.dart' \
  | sort -t: -k2 -nr | head -30

# Raw Scaffold pages
rg -l '\bScaffold\s*\(' apps/erp/lib/features --glob '*_page.dart' \
  | while read f; do rg -q 'VPageScaffold' "$f" || echo "$f"; done

# Monitored WARN summary
./scripts/ci/guard_design_system_usage.sh 2>&1 | rg '^WARN:' | wc -l
```
