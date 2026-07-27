# Design System Example

Preview catalog cho `vet45_design_system`.

## Chạy

Từ package:

```bash
cd packages/vet45_design_system/example
flutter run
```

Từ repo root:

```bash
melos run design-system:example
melos run design-system:example:web
```

VS Code: **Run and Debug** → `Design system · example`.

## Tabs

| Tab | Nội dung |
| --- | --- |
| Mockup App | Composition nghiệp vụ |
| Tokens | Colors, typography, spacing, radius, shadows |
| Primitives | `VBadge`, `VChip`, `VIcon`, `VIconBox`, `VText` |
| Components | Buttons, fields, dropdowns, overlays, … |
| Forms | `VEmailField`, `VPasswordField`, `VMoneyField`, `VNumberField`, `VSelect`, `VChoiceList` |
| Business | `VTodoItem`, `VActivityItem`, `VMetricCard`, … |
| UI Audit | Coverage matrix |

## VPasswordField

Mở tab **Forms** → section **VPasswordField**:

- Optional (built-in validation, debounce)
- Required
- External `errorText` override
- Disabled
- Toggle visibility (`initiallyObscured: false`)
