# vet45_design_system

VET45 Company Design System Package containing colors, spacing, radius, typography, shadows, theme, and reusable UI components.

## How to use

Import it in features or application packages:

```dart
import 'package:vet45_design_system/design_system.dart';
```

## Example app

Run preview app:

```bash
cd packages/vet45_design_system/example
flutter run
```

Or from repo root:

```bash
melos run design-system:example
melos run design-system:example:web
```

VS Code: **Run and Debug** → `Design system · example` (hoặc `melos · design-system:example`).

**Agent rule:** khi thêm/đổi public UI trong package này, phải cover example catalog (mọi state API hiện có) — xem [`.cursor/rules/vet45-design-system-example.mdc`](../../.cursor/rules/vet45-design-system-example.mdc).

Main tabs in the preview:
- `Mockup App`: business-oriented page composition
- `Tokens`: colors, typography, spacing, radius, shadows, duration
- `Primitives`: `VBadge`, `VChip`, `VIcon`, `VIconBox` (state gallery)
- `Components`: buttons, fields, dropdowns, toggles, overlays, layout widgets — mỗi component một section + states
- `Forms`: `VEmailField`, `VPasswordField`, `VMoneyField`, `VNumberField`, `VSelect`, `VChoiceList`
- `Business`: `VTodoItem`, `VActivityItem`, `VMetricCard`, `VCreateOrderButton`, `VRevenueCard`
- `UI Audit`: matrix coverage / semantics / tone / state

Component coverage in example includes:
- Primitives: `VBadge`, `VChip`, `VIcon`, `VIconBox`, `VText`
- Components: `VButton`, `VCard` (+ `VCardHeader` / `VCardTitle` / `VCardIcon` / `VCardAction` / `VCardContent` / `VCardFooter`; tone→bg+border, emphasis→shadow), `VCheckbox`, `VRadio`, `VSwitch`, `VFloatingActionButton`, `VTextField`, `VSearchBar`, `VQuickActionButton`, `VTabs`, `VEmptyState`, `VToast`, `VDropdown`, `VSearchableDropdown`, `VQuantitySelector`, `VDatePickerField`, `VHomeHeader`, `VBottomNavigationBar`, `VConfirmDialog` (via `showVConfirmDialog`), `VBottomSheet` (via `showVBottomSheet`), `VAppBar`, `VTable`
- Forms: `VEmailField`, `VPasswordField`, `VMoneyField`, `VNumberField`, `VSelect`, `VChoiceList`
- Business: `VTodoItem`, `VActivityItem`, `VMetricCard`, `VCreateOrderButton`, `VRevenueCard`

## Tài liệu roadmap theo hướng Polaris

Bộ tài liệu triển khai nâng cấp design system theo hướng Polaris có tại:

- `docs/polaris/README.md`
- `docs/polaris/01-baseline-audit.md`
- `docs/polaris/02-target-architecture.md`
- `docs/polaris/03-wave-roadmap.md`
- `docs/polaris/04-backlog-kpi.md`
- `docs/polaris/05-rollout-strategy.md`
- `docs/polaris/06-design-system-spec.md`
- `docs/polaris/07-token-migration-checklist.md`
