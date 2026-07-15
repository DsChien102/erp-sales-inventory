# 02 — Target Architecture

## Layer stack

```text
Tokens (VColors, VSpacing, VTypography, VRadius, VShadows, VDuration)
  ↓
Theme (VTheme, VColorScheme, VDensity)
  ↓
Foundation (v_context_extensions, v_component_contracts)
  ↓
Primitives (VText, VBadge, VChip, VIcon, VIconBox)
  ↓
Components (VButton, VCard, VTextField, overlays, ...)
  ↓
Forms (VEmailField, VMoneyField, VSelect, ...)
  ↓
Patterns (VGap, VPagePadding, VSection, VPageScaffold)  ← NEW
  ↓
Business (VMetricCard, VTodoItem, ...) — generic ERP chrome only
  ↓
Module presentation (partner_transform_stepper, product_control_center_section_card)
  ↓
Feature pages (apps/erp/features/*/presentation/pages/)
```

## Nguyên tắc phân tầng

| Layer | Được | Không được |
|-------|------|------------|
| Tokens | Raw values, semantic aliases | Widget logic |
| Components | Reusable UI với API ổn định | Domain-specific copy |
| Patterns | Compose components cho layout ERP | Business rules |
| Module presentation | Domain-specific widgets | Magic spacing / raw Material |
| Feature pages | Compose + Bloc/Cubit + navigate | Direct Supabase, God Widget |

## Semantic vs raw tokens

Feature UI **không** reference trực tiếp `VColors.primary500` trừ khi trong DS internals. Dùng:

- `context.vColors.textPrimary` / `textSecondary` / `textMuted`
- `context.vColors.surface` / `surfaceAlt` / `dangerBg`
- `context.vColors.borderDefault` / `borderStrong`

Spacing **chỉ** qua `VSpacing.*` hoặc layout primitives (`VGap`, `VPagePadding`).

## Component API contract (mục tiêu dài hạn)

Mọi public interactive component nên support (khi applicable):

- `VComponentTone` — neutral, primary, success, warning, danger, info
- `VComponentEmphasis` — subtle, medium, strong
- `VComponentState` — enabled, disabled, loading, error
- `semanticsLabel` cho accessibility

Phase hiện tại: chuẩn hóa layout patterns trước; contract đồng đều là wave sau.

## Import rule

```dart
import 'package:vet45_design_system/design_system.dart';
```

Feature và module presentation **chỉ** import public API — không `package:vet45_design_system/src/...`.
