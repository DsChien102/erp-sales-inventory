# Changelog

## 2.0.2 — Flutter raster + icon parity hardening

- Added `src/flutter-font-bridge.js` so the browser can load the **exact Inter / JetBrains Mono files from the authoritative Flutter checkout** without redistributing font binaries. Silent fallback is now externally detectable through `data-c45-font-parity`.
- Split preview-only Material glyphs from the public `VIcons`/Lucide contract. The Flutter example uses Material `home`, `receipt_long`, `more_horiz` and `store` in specific samples; HTML now mirrors that instead of forcing unrelated Lucide aliases.
- Corrected non-canonical preview icon aliases (`plus`, `eye`, `orders`, `box`).
- Expanded the Floating Action Button sample to the same three source states: primary add, info QR, disabled printer.
- Re-aligned bottom navigation sample labels/items to Flutter (`Home`, `Orders`, `More`) while retaining the Flutter icon-only rendered navigation contract.
- QA now gates the 2.0.2 version, the exact Flutter font bridge, Material-preview separation, semantic `VIcons`, no bundled font binaries, source hashes, component geometry and runtime interactions.

# 2.0.1

## Visual parity hardening

- Fixed Typography H4 preview label to 14 px, matching Flutter `VTypography.headingH4`.
- Added explicit local face bindings for Inter and JetBrains Mono weights 400–800 and disabled synthetic weights.
- Expanded runtime typography verification to every required weight.
- Expanded local SVG fallback coverage from partial to all 108 Flutter `VIcons` aliases.
- Added release gates for complete icon fallback coverage and zero missing-icon placeholders.
- Rebuilt browser regression evidence against Flutter `c45_design_system` 1.4.1.

# 2.0.0

## Flutter-authoritative re-baseline

- Breaking authority change: Flutter `c45_design_system` 1.4.1 is now the canonical source of truth.
- Rebuilt foundation tokens from Flutter `VColors`, `VColorScheme`, `VSpacing`, `VRadius`, `VBorders`, `VShadows`, `VDuration`, `VOpacity`, `VBreakpoints`, `VDensity`, and `VTypography`.
- Rebuilt canonical registry from `lib/design_system.dart` (94 public exports).
- Added source-level constructor/token inventory for 116 classes.
- Rebuilt VIcons contract from Flutter source: 108 semantic aliases/codepoints, Lucide 3.1.15 family/weight contract.
- Rebuilt HTML component layer around Flutter public primitives/components/forms/patterns.
- Restored `VCard` as canonical because Flutter exports it.
- Removed `VQuantitySelector` from canonical assumptions because Flutter 1.4.1 does not export it.
- Preview organization now mirrors Flutter example exactly: Tokens / Primitives / Components / Forms / UI Audit.
- Figma/v1.6 source contracts retained only as legacy reference; they no longer override Flutter.
- Added explicit host font contract; no font binaries are distributed.
- Replaced Figma-centric release gate with Flutter source/hash/API/token/component gate.

- Canonical runtime package generated from Flutter 1.4.1: fresh tokens, component/form/pattern CSS, JS interaction runtime, 94-export registry, 287-test evidence, 108-icon codepoint inventory.
- Preview now mirrors the Flutter example exactly at the organization level: 5 tabs and 63 PreviewSection entries, plus the Flutter-style UI Audit matrix and metrics.
- Public API extraction now covers 94 export statements / 155 public symbols, including generic top-level helpers previously missed by the first parser.
- Added runtime browser equivalents for `VTextNormalizer`, dropdown filtering/search matching, `showVConfirmDialog`, `showVBottomSheet`, and `showVNumericKeypadSheet`.
- Separated `VBottomSheet` / `VNumericKeypadSheet` component anatomy from their modal overlay hosts, matching Flutter widget/helper responsibility.
- Fixed `VSelect` menu rows and `VComboboxItem` touch rows to the Flutter 44 px contract.
- Expanded Chromium computed-style parity checks across primitives, actions, forms, navigation, feedback, overlays and responsive patterns.
- Added interaction regression coverage for Vietnamese search/filter, confirm dialog, bottom sheet, numeric keypad sheet, select, segmented control, tabs, money/number formatting and verification-code focus.
- Added exhaustive `foundation-values.json` generated from Flutter Dart source (50 colors, 22 spacing values/aliases, 12 radius values/aliases, borders, opacity, durations, breakpoints, both density modes, 20 typography styles and 4 shadow levels).
- `VText` now maps all 20 Flutter `VTextVariant` values 1:1, including all JetBrains Mono variants and semantic tone foreground mapping.
- Tokens preview now mirrors Flutter `tokens_tab.dart` typography section, including the complete mono scale and numeric comparison rows.
- Strengthened font parity contract: Inter and JetBrains Mono weights used by Flutter typography are verified in Chromium against the exact project-supplied TTF assets during QA, without bundling those binaries in the HTML artifact.
- Added `extract_foundation_contract.py`, `qa_fonts.py`, and deterministic checksum regeneration for future Flutter-to-HTML updates.

