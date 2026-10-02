# VET45 HTML Design System 2.0.2

**Canonical visual authority:** `vet45_design_system` Flutter package **1.4.1** supplied by the project.

This release is a breaking re-baseline of HTML DS 1.6.0. v1.6 used Figma as visual authority and Flutter as a cross-reference. v2.0.0 reverses that rule deliberately: **Flutter is the source of truth for tokens, public API, component anatomy/defaults/states, form behavior, patterns, icon semantics, density and preview organization.**

## Why 2.0.0

Theme 7 exposed a structural problem: a prototype can use the same words as a Design System while still rendering different anatomy. v2.0.0 removes that ambiguity. A component is canonical only when it exists in `lib/design_system.dart` of Flutter 1.4.1 and the HTML implementation maps to that API.

## Preview organization

Open `index.html`. It mirrors the Flutter example application structure:

1. Tokens
2. Primitives
3. Components
4. Forms
5. UI Audit

The preview mirrors the Flutter example with **5 tabs / 63 PreviewSection entries**. The source contract records **94 export statements / 155 public symbols**, including **78 visual mappings**; the UI Audit tab mirrors the Flutter audit snapshot and component matrix.

## Canonical source hierarchy

1. `lib/design_system.dart` — public barrel / canonical API inventory.
2. `lib/src/tokens` + `lib/src/theme` — color, type, spacing, radius, border, shadow, density, duration, opacity.
3. `lib/src/primitives`, `components`, `forms`, `patterns` — anatomy, variants, states and behavior.
4. `lib/src/foundations/icons/v_icons.dart` + `lucide_icons_flutter 3.1.15` — icon semantics/codepoints/weight families.
5. `example/lib/main.dart` + `example/lib/preview` — preview organization and representative examples.
6. Figma / HTML DS 1.6 contracts — **legacy reference only** in v2.


## Source organization

HTML v2 mirrors the same mental model as Flutter `lib/src` while keeping one implementation authority per concern:

```text
src/
├── tokens/        → Flutter lib/src/tokens
├── theme/         → Flutter lib/src/theme
├── foundation/    → Flutter lib/src/foundation
├── patterns/      → Flutter lib/src/patterns
├── primitives/    → Flutter lib/src/primitives
├── components/    → Flutter lib/src/components
├── forms/         → Flutter lib/src/forms
└── audit/         → Flutter lib/src/audit
```

The group `index.css` / `index.js` files are taxonomy entry points only. They delegate to the aggregate canonical implementation (`tokens.css`, `components.css`, `forms.css`, `patterns.css`, `vet45-ds.js`) so the HTML package does not create duplicate sources of truth.

`contracts/flutter-source-tree.json` fingerprints **99 Flutter `lib/src` files** and records the corresponding HTML group. When the supplied Flutter source is available, `qa.sh` verifies every mapped source hash before any browser parity test runs.

## Import

```html
<link rel="stylesheet" href="/specs/vet45-html-design-system/src/templates.css">
<script type="module" src="/specs/vet45-html-design-system/src/vet45-ds.js"></script>
```

`templates.css` imports the complete canonical chain:

`templates.css → patterns.css → forms.css → components.css → base.css → tokens.css → fonts.css`

## Font contract

Flutter 1.4.1 embeds Inter and JetBrains Mono and obtains Lucide glyphs from `lucide_icons_flutter 3.1.15`.

This HTML package intentionally **does not distribute font binaries**. The host repository must expose the same families. `src/fonts.css` binds the required local family names; `contracts/font-contract.json` records required weights and sources. When those font assets are present, typography uses the same family/weight/size/line-height values as Flutter. v2.0.2 binds every required local weight explicitly and disables synthetic weights so a missing face cannot be silently faked.

Required:

- Inter: 400, 500, 600, 700, 800
- JetBrains Mono: 400, 500, 600, 700, 800
- Lucide: host-supplied families from `lucide_icons_flutter 3.1.15` (Lucide 1.24.0): `Lucide`, `Lucide100`, `Lucide200`, `Lucide300`, `Lucide400`, `Lucide500`, `Lucide600`. These mirror `VIconWeight`; 108 semantic aliases/codepoints are stored in contracts. SVG fallback covers all 108 VIcons aliases locally when the Lucide font is unavailable; no semantic icon may degrade to an empty placeholder.

## Key source-exact values

- Mobile page edge: **16 px**
- Minimum touch target: **44 px**
- Comfortable controls: **36 / 44 / 52 px**
- Compact controls: **32 / 40 / 48 px**
- Input/button radius: **8 px**
- Card radius: **12 px**
- Sheet radius: **16 px**
- Default disabled treatment: **whole subtree opacity 0.4**
- Breakpoints: **600 / 1024 px**
- VAppBar: standard 56 px, 64 px with subtitle, surface background, 1 px bottom divider
- VBottomNavigationBar: icon-only in Flutter 1.4.1; icon size 29 px; top border

## Important API corrections versus HTML DS 1.6

- `VCard` is canonical because it exists in Flutter 1.4.1.
- `VQuantitySelector` is **not** canonical because it is not exported by Flutter 1.4.1. Quantity entry is represented by `VNumberField` and/or `VNumericKeypadSheet` depending on product flow.
- Figma-only master names from v1.6 are not canonical in v2.0.0 unless they also exist in the Flutter public barrel.
- `VIcons` contains 108 semantic aliases/codepoints from Flutter source.


## Public runtime behavior parity

HTML v2 exposes browser equivalents for Flutter top-level behavior APIs that Theme 7 should reuse instead of reimplementing:

- `VTextNormalizer`
- `filterDropdownEntries`
- `matchesComboboxSearch` / `matchesNormalizedComboboxSearch`
- `showVConfirmDialog`
- `showVBottomSheet`
- `showVNumericKeypadSheet`
- money / number input formatting helpers

Overlay widgets are separated from overlay hosts exactly as in Flutter: `VBottomSheet` and `VNumericKeypadSheet` are embeddable components; the `showV*` helpers own modal positioning and dismissal.

## Theme rule

Theme HTML may compose canonical Flutter components and patterns. It must not:

- create a theme-local visual replacement for a canonical component;
- attach a Flutter component name to different DOM anatomy;
- keep a v1.6/Figma-only component as if it were canonical v2;
- override shared visual tokens/components to fix one Theme.

If the Flutter DS lacks a needed component, record a DS gap and update the shared Flutter/HTML contract first.

## Contracts

- `contracts/flutter-source.json` — package/version/source hashes
- `contracts/flutter-public-api.json` — 94 Flutter export statements and extracted public API inventory
- `contracts/public-symbol-coverage.json` — 155 public symbols classified as visual/runtime/nonvisual; 78 visual mappings
- `contracts/preview-structure.json` — exact Flutter preview order: 5 tabs / 63 sections
- `contracts/runtime-api.json` — browser equivalents for public Flutter behavior helpers
- `contracts/flutter-component-signatures.json` — constructor/source inventory
- `contracts/flutter-icons.json` — 108 icon aliases/codepoints
- `contracts/canonical-registry.json` — Flutter→HTML selector registry
- `contracts/component-map.json` — canonical visual mapping
- `contracts/variant-contracts.json` — public variants/defaults
- `contracts/font-contract.json` — host font requirement
- `contracts/parity-matrix.json` — authority rules

## QA

Run:

```bash
./qa.sh
```

The gate verifies all frozen Flutter source hashes, 94 export statements / 155 public symbols, canonical selector coverage, 287 Flutter tests as evidence inventory, 108 icon aliases/codepoints, critical tokens, exact 5-tab/63-section preview organization, absence of bundled font binaries, JS syntax, and Chromium computed-style + interaction parity for high-risk components, forms, responsive patterns and public runtime helpers (`filterDropdownEntries`, search matching, confirm dialog, bottom sheet and numeric keypad sheet).
## Exact Flutter font parity

HTML DS **does not bundle or redistribute font binaries**. For pixel-faithful typography, point the preview/runtime at the `assets/fonts` directory of the authoritative `vet45_design_system` checkout before initialization:

```html
<script>
window.__VET45_FLUTTER_ASSETS__ = {
  fontRoot: '../vet45_design_system/assets/fonts'
};
</script>
```

Alternatively append `?flutterFontRoot=/path/to/vet45_design_system/assets/fonts` when serving the preview. `src/flutter-font-bridge.js` registers Inter weights 400/500/600/700/800 and JetBrains Mono 400/500/600/700/800 from those exact source files. Runtime parity is explicit: `document.documentElement.dataset.vet45FontParity` is `exact` only after every authoritative face loaded successfully; otherwise it is `fallback`.

Preview-only Material icons are intentionally separate from `VIcons`. Public VET45 icons continue to follow the frozen Flutter `VIcons` semantic/codepoint contract; Material glyphs are used only where the Flutter example itself uses `Icons.*`.

