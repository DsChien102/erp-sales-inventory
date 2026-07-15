# 06 — Design System Spec

Source of truth cho tokens, typography roles, và 5 recipes vàng.

## Token map

### Spacing (`VSpacing`)

| Token | Value | Dùng cho |
|-------|-------|----------|
| `space1` / `xs` | 4 | Tight inline gap |
| `space2` / `sm` | 8 | Default stack gap giữa sections nhỏ |
| `space3` | 12 | Field internal padding |
| `space4` / `md` | 16 | Card padding, screen mobile |
| `space5` | 20 | Dialog padding |
| `space6` / `lg` | 24 | Section gap |
| `space8` / `xl` | 32 | Large section |
| `screenMobile` | 16 | `VPagePadding` mobile |
| `screenTablet` | 24 | `VPagePadding` tablet |
| `minTouchTarget` | 44 | Hit area tối thiểu |

**Cấm:** `EdgeInsets.all(16)`, `SizedBox(height: 8)` với literal — dùng `VGap` hoặc `VSpacing.*`.

### Colors (semantic via `context.vColors`)

| Role | Property | Khi dùng |
|------|----------|----------|
| Primary text | `textPrimary` | Tiêu đề, body chính |
| Secondary text | `textSecondary` | Subtitle, meta |
| Muted | `textMuted` | Placeholder, disabled hint |
| Surface | `surface` | Card, sheet background |
| Surface alt | `surfaceAlt` | Icon box, zebra |
| Border | `borderDefault` / `borderStrong` | Card border, input |
| Status | `danger`, `warning`, `success`, `info` + `*Bg` | Banner, badge, error |

**Cấm:** `Colors.grey`, `VColors.primary500` trực tiếp trong feature UI.

### Radius (`VRadius`)

- `card` — VCard
- `input` — text fields
- `sheet` — bottom sheet, dialog
- `pill` — chips, drag handle

---

## Typography role → `VTextVariant`

| UI role | `VTextVariant` |
|---------|----------------|
| Page title (trong body, không app bar) | `headingH1` |
| Section title | `headingH3` |
| Card title | `headingH4` |
| Body | `bodyDefault` |
| Subtitle / secondary | `bodySmall` + `color: context.vColors.textSecondary` |
| Caption / meta | `caption` |
| Form label | `labelSmall` |
| Mono cùng role (SKU, code) | `displayD1Mono` / `headingH3Mono` / `headingH4Mono` / `bodyDefaultMono` / `bodySmallMono` |
| Số tiền tabular | `monoNumeric` |

Sans = Inter (`VTypography.*` không suffix). Mono = JetBrains Mono (`*Mono` / `monoNumeric`).

**Cấm:** `Text(...)` + `VTypography.x.copyWith(...)` trong feature presentation.

---

## Do / Don't

| Do | Don't |
|----|-------|
| `import 'package:vet45_design_system/design_system.dart'` | Import `src/` |
| `VText`, `VButton`, `VCard` | `Text`, `ElevatedButton`, raw `Container` card |
| `VGap.sm`, `VPagePadding` | `SizedBox(height: 8)`, `Padding(all: 16)` |
| `showVConfirmDialog`, `showVBottomSheet` | `AlertDialog`, `showModalBottomSheet` |
| `context.vColors.*` | `Colors.*`, hardcoded hex |
| Tách dialog = 1 file | Inline dialog trong page |
| Dùng pattern có sẵn trước khi invent | Feature-local card với padding riêng |

---

## 5 Recipes vàng

### Recipe 1 — Page detail (AppBar + scroll body + optional bottom bar)

```dart
VPageScaffold(
  title: 'Chi tiết sản phẩm',
  subtitle: product.sku,
  onBack: () => context.pop(),
  body: VPagePadding(
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileCard(...),
          VGap.sm(),
          SectionA(...),
          VGap.sm(),
          SectionB(...),
        ],
      ),
    ),
  ),
  bottomBar: ProductFormBottomBar(...), // optional
)
```

### Recipe 2 — Section card (title / subtitle / action)

```dart
VSection(
  title: 'Đơn vị đo',
  subtitle: 'Quản lý đơn vị quy đổi',
  trailing: onEdit != null
      ? VButton(label: 'Sửa', variant: VButtonVariant.ghost, onPressed: onEdit)
      : null,
  child: VCard(
    child: Row(
      children: [
        VIconBox(iconData: Icons.straighten),
        VGap.horizontalSm(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VText(title, variant: VTextVariant.headingH4),
              VGap.xs(),
              VText(subtitle, variant: VTextVariant.bodySmall,
                color: context.vColors.textSecondary),
            ],
          ),
        ),
      ],
    ),
  ),
)
```

### Recipe 3 — Form field stack

```dart
VPagePadding(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      VTextField(label: 'Tên', controller: nameController),
      VGap.md(),
      VMoneyField(label: 'Giá', controller: priceController),
      VGap.md(),
      VSelect<String>(label: 'Loại', options: options, value: selected),
    ],
  ),
)
```

### Recipe 4 — Confirm overlay

Dialog:

```dart
final confirmed = await showVConfirmDialog(
  context: context,
  title: 'Xác nhận xóa',
  message: 'Hành động không thể hoàn tác.',
  actionLabel: 'Xóa',
  isDestructive: true,
);
```

Bottom sheet:

```dart
await showVBottomSheet(
  context: context,
  title: 'Tùy chọn',
  child: MySheetContent(),
);
```

### Recipe 5 — Empty / error / loading state

```dart
// Loading
if (state.isLoading) {
  return const Center(child: CircularProgressIndicator());
}

// Error
if (state.hasError) {
  return VEmptyState(
    iconData: Icons.error_outline,
    title: 'Không thể tải dữ liệu',
    description: state.errorMessage,
    actionLabel: 'Thử lại',
    onActionPressed: onRetry,
  );
}

// Empty
if (items.isEmpty) {
  return VEmptyState(
    iconData: Icons.inventory_2_outlined,
    title: 'Chưa có sản phẩm',
    description: 'Thêm sản phẩm đầu tiên.',
    actionLabel: 'Tạo mới',
    onActionPressed: onCreate,
  );
}
```

Error inline (trong body):

```dart
Center(
  child: VText(
    message,
    variant: VTextVariant.bodyDefault,
    color: context.vColors.textSecondary,
    textAlign: TextAlign.center,
  ),
)
```
