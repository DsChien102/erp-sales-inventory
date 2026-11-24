# 07 — Token Migration Checklist

Dùng checklist này cho mọi PR chạm presentation UI.

## Trước khi code

- [ ] Đọc [06-design-system-spec.md](06-design-system-spec.md) — chọn recipe phù hợp
- [ ] Kiểm tra example catalog: component/pattern đã có chưa?
- [ ] Widget manifest: dialog/section tách file riêng

## Spacing & layout

- [ ] Không `EdgeInsets.all/symmetric/only` với literal number
- [ ] Dùng `VGap` cho vertical/horizontal gap
- [ ] Dùng `VPagePadding` cho screen inset
- [ ] Page detail dùng `VPageScaffold` khi có app bar + body
- [ ] Section có title dùng `VSection` hoặc compose `VCard` + `VText`

## Typography

- [ ] Mọi copy hiển thị qua `VText` + `VTextVariant`
- [ ] Không `Text(` trực tiếp (trừ generated/test)
- [ ] Không `VTypography.*.copyWith` trong feature — dùng `VText` `color` param

## Color

- [ ] Chỉ `context.vColors.*` hoặc semantic qua component
- [ ] Không `Colors.*` / `Color(0x…)` hex literal (CI guard: `scripts/ci/guard_design_system_usage.sh`)

## Components & overlays

- [ ] Button → `VButton`
- [ ] Input → `VTextField` / form fields (`VMoneyField`, ...)
- [ ] Card → `VCard`
- [ ] Confirm → `showVConfirmDialog` (file dialog riêng)
- [ ] Sheet → `showVBottomSheet` / `VBottomSheet`
- [ ] Empty → `VEmptyState`

## Design system changes (nếu thêm widget public)

- [ ] Export trong `design_system.dart`
- [ ] PreviewSection trong example (mọi state API)
- [ ] `_exampleCoverage` trong `ui_audit_tab.dart`
- [ ] `dart run tool/component_audit.dart`

## Verify

```bash
./scripts/ci/guard_design_system_usage.sh
./scripts/ci/guard_design_system_contracts.sh
./scripts/ci/verify_harness.sh
cd apps/erp && flutter test test/features/<feature>/
```

**CI tiers (usage):** ENFORCED = `product_control_center*` + `product_catalog*`; MONITORED = toàn bộ feature presentation + module widgets (WARN). Chi tiết + backlog: [09-adoption-checklist.md](09-adoption-checklist.md).

## Mapping nhanh (legacy → token)

| Legacy | Thay bằng |
|--------|-----------|
| `EdgeInsets.all(16)` | `VPagePadding` hoặc `VCard` default padding |
| `SizedBox(height: 8)` | `VGap.sm()` |
| `Column(spacing: 8)` | children + `VGap.sm()` giữa items |
| `Text('...', style: VTypography.bodyDefault)` | `VText('...', variant: VTextVariant.bodyDefault)` |
| `AlertDialog(...)` | `showVConfirmDialog` + widget file |
| `showModalBottomSheet(...)` | `showVBottomSheet` |
