# 08 — Component Contracts (Tone / Emphasis / Enabled)

Source of truth for shared visual contracts. Audited via [`docs/audit/contract_matrix.yaml`](../audit/contract_matrix.yaml) + `dart run tool/component_audit.dart`.

## Shared enums

```dart
enum VComponentTone { neutral, primary, success, warning, danger, info }
enum VComponentEmphasis { subtle, medium, strong }
```

Defined in `lib/src/foundation/v_component_contracts.dart`.

**Enabled** is not an enum: use `bool? enabled` with soft inherit via
`VComponentScope.resolveEnabled` (local → scope → fallback `true`).
Error UX stays per-component (`errorText`, domain state). Submit loading stays
on `VButton.isLoading` (page loading → `VSkeleton`).

## Role matrix

| Role | Tone | Emphasis | Enabled | semanticLabel | Ví dụ |
|------|------|----------|---------|---------------|--------|
| Action | Required | Required | Preferred | Required | VButton, VFAB, VQuickAction |
| Input | Preferred | Preferred | Required | Required | VTextField, dropdowns, date |
| Toggle | Optional | Optional | Required | Required | VCheckbox, VRadio, VSwitch |
| Status display | Required | Optional | N/A | Preferred | VBadge, VToast |
| Container | Optional | Optional | N/A | Optional | VCard, VSection |
| Overlay shell | Optional | Optional | N/A | Preferred | VConfirmDialog, VBottomSheet |
| Navigation chrome | N/A | N/A | N/A | Optional | VAppBar, VBottomNav |
| Layout pattern | N/A | N/A | N/A | N/A | VField*, VGap, VPagePadding, VPageScaffold, VSkeleton |
| Typography primitive | Optional | N/A | N/A | Optional | VText, VIcon |
| Business chrome | Preferred | Preferred | Optional | Preferred | Module presentation (e.g. TodoItem) |

Levels:

- **required** — must reference + expose/use the contract (audit Fail if missing)
- **preferred** — should have; tracked, does not fail CI until Wave E prefers raise
- **optional** — ok present or absent
- **na** — must not require; presence is allowed but documented as unused

## Enabled derivation

```dart
final isEnabled = VComponentScope.resolveEnabled(context, local: enabled) &&
    /* derived: onPressed != null, !isLoading, … */;
```

| Signals | Effect |
|---------|--------|
| `enabled: false` (local or ambient scope) | disabled |
| `onPressed` / `onChanged` / `onTap` null | disabled |
| `VButton.isLoading == true` | non-interactive + spinner |
| `errorText != null` | error chrome (not a shared state enum) |
| else | enabled |

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
| Cover tone/emphasis/enabled in example | Only happy-path demo |

## Golden API

- Full input contracts: `VTextField`
- Action tone+emphasis: `VButton` (+ `enabled` / `isLoading`)
