# 08 — Component Contracts (Tone / Emphasis / State)

Source of truth for shared visual contracts. Audited via [`docs/audit/contract_matrix.yaml`](../audit/contract_matrix.yaml) + `dart run tool/component_audit.dart`.

## Shared enums

```dart
enum VComponentTone { neutral, primary, success, warning, danger, info }
enum VComponentEmphasis { subtle, medium, strong }
enum VComponentState { enabled, disabled, loading, error }
```

Defined in `lib/src/foundation/v_component_contracts.dart`.

## Role matrix

| Role | Tone | Emphasis | State | semanticLabel | Ví dụ |
|------|------|----------|-------|---------------|--------|
| Action | Required | Required | Preferred | Required | VButton, VFAB, VQuickAction |
| Input | Preferred | Preferred | Required | Required | VTextField, dropdowns, date |
| Toggle | Optional | Optional | Required | Required | VCheckbox, VRadio, VSwitch |
| Status display | Required | Optional | N/A | Preferred | VBadge, VToast |
| Container | Optional | Optional | N/A | Optional | VCard, VSection |
| Overlay shell | Optional | Optional | N/A | Preferred | VConfirmDialog, VBottomSheet |
| Navigation chrome | N/A | N/A | N/A | Optional | VAppBar, VBottomNav |
| Layout pattern | N/A | N/A | N/A | N/A | VGap, VPagePadding, VPageScaffold, VSkeleton |
| Typography primitive | N/A | N/A | N/A | Optional | VText, VIcon |
| Business chrome | Preferred | Preferred | Optional | Preferred | VMetricCard, VTodoItem |

Levels:

- **required** — must reference + expose/use the contract (audit Fail if missing)
- **preferred** — should have; tracked, does not fail CI until Wave E prefers raise
- **optional** — ok present or absent
- **na** — must not require; presence is allowed but documented as unused

## State derivation

Prefer explicit `state: VComponentState` **or** derive and still reference `VComponentState` in file:

| Signals | Derived state |
|---------|---------------|
| `isLoading == true` | `loading` |
| `enabled == false` / `onPressed == null` | `disabled` |
| `errorText != null` | `error` |
| else | `enabled` |

## Domain enum → Tone bridges

Keep domain enums; map to tone internally.

### VBadgeStatus → Tone

| Status group | Tone |
|--------------|------|
| success, completed, paid | success |
| warning, partiallyPaid, outstanding | warning |
| danger, overdue | danger |
| info, pending | info |
| processing | primary |
| draft, cancelled, locked | neutral |

### VToastType → Tone

| Type | Tone |
|------|------|
| success | success |
| warning | warning |
| danger | danger |
| info | info |

### VChipEmphasis (deprecated) → VComponentEmphasis

| Old | New |
|-----|-----|
| subdued | subtle |
| base | medium |
| strong | strong |

## Do / Don't

| Do | Don't |
|----|-------|
| Additive props with safe defaults | Breaking rename of variant enums |
| Map `VBadgeStatus` / `VToastType` → tone | Delete domain status enums |
| Document `// contract: na …` on chrome | Force tone onto VGap / VPageScaffold |
| Cover tone/emphasis/state in example | Only happy-path demo |

## Golden API

- Full input contracts: `VTextField`
- Action tone+emphasis: `VButton` (+ derived `VComponentState`)
