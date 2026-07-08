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

Main tabs in the preview:
- `Mockup App`: business-oriented page composition
- `Tokens`: color, typography, spacing, radius, and shadows
- `Buttons`: button variants, size, loading, full-width
- `Fields`: text fields, dropdown, quantity selector
- `Cards & Badges`: card states and badge statuses
- `New Specs`: tabs, overlays, table, empty state, toggles
- `Missing Components`: direct coverage for `VAppBar`, `VDatePickerField`, `VFloatingActionButton`, and `VIcon`

Component coverage in example includes:
- Primitives: `VBadge`, `VIcon`, `VIconBox`
- Components: `VButton`, `VCard`, `VCheckbox`, `VSwitch`, `VFloatingActionButton`, `VTextField`, `VSearchBar`, `VQuickActionButton`, `VTabs`, `VEmptyState`, `VToast`, `VDropdown`, `VQuantitySelector`, `VDatePickerField`, `VHomeHeader`, `VBottomNavigationBar`, `VModal` (via `showVConfirmDialog`), `VBottomSheet` (via `showVBottomSheet`), `VAppBar`, `VTable`
- Business components: `VTodoItem`, `VActivityItem`, `VMetricCard`, `VCreateOrderButton`, `VRevenueCard`
