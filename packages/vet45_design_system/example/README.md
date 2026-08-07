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
| Tokens | Colors, typography, spacing, radius, shadows |
| Primitives | `VBadge`, `VChip`, `VIcon`, `VIconBox`, `VText` |
| Components | Buttons, fields, `VCard`, Responsive kit (`VResponsive` / grid / content width), dropdowns, overlays, … |
| Forms | `VEmailField`, `VPasswordField`, `VMoneyField`, `VNumberField`, `VSelect`, `VChoiceList` |
| UI Audit | Coverage matrix |

## VPasswordField

Mở tab **Forms** → section **VPasswordField**:

- Optional (built-in validation, debounce)
- Required
- External `errorText` override
- Disabled
- Toggle visibility (`initiallyObscured: false`)

## VCard

Mở tab **Components** → section **VCard**:

- Default / tappable
- Tone gallery (neutral → info): border + background
- Emphasis gallery (subtle / medium / strong): shadow
- Composed: `VCardHeader` + `VCardContent` + `VCardFooter` (`padding: EdgeInsets.zero`)

## Responsive

Mở tab **Components** → section **Responsive** (resize cửa sổ để xem đổi breakpoint):

| Breakpoint | Width |
| --- | --- |
| mobile | under 600 |
| tablet | 600+ |
| desktop | 1024+ |

- `VResponsive` / `VResponsiveValue`
- `VResponsiveVisibility` (only mobile / from tablet / only desktop)
- `VContentWidth` (max-width center)
- `VResponsiveGrid` (1 / 2 / 3 columns)
