# 02 — Audit Flutter Design System

> Source: uploaded package `vet45_design_system` version `1.0.0` · Generated `2026-08-24T09:17:52.534357+00:00` · Static source audit only.

## Verdict

- ZIP này được dùng làm **single technical source of truth** theo chỉ định của Product.
- Không tạo HTML Design System thứ hai. HTML ở bước sau chỉ là renderer/prototype và module-presentation composition dựa trên public Flutter DS.
- Public architecture phù hợp: Tokens → Theme/Foundation → Primitives → Components/Forms → Patterns; business chrome ở module presentation.
- Môi trường audit không có Flutter/Dart executable, nên chưa chạy `flutter analyze` hoặc widget tests. Kết luận runtime vẫn chưa được chứng minh.

## Package facts

| Metric | Value |
|---|---|
| Package | `vet45_design_system` |
| Version | `1.0.0` |
| Public export files | 81 |
| Public classes/enums (static extraction) | 107 |
| Dart source files | 86 |
| Test files | 29 |
| Public symbols referenced in tests | 57 |
| Flutter executable | `NOT_AVAILABLE` |
| Dart executable | `NOT_AVAILABLE` |

## Public layer distribution

| Layer | Export files |
|---|---:|
| `audit` | 1 |
| `components` | 30 |
| `forms` | 16 |
| `foundation` | 7 |
| `foundations` | 1 |
| `patterns` | 8 |
| `primitives` | 6 |
| `theme` | 3 |
| `tokens` | 9 |

## Strong points

1. Semantic color access is explicit (`context.vColors`); feature UI should not use raw palette.
2. Layout primitives exist: `VPageScaffold`, `VPagePadding`, `VSection`, `VGap`, responsive/content-width/grid patterns.
3. Core components cover action, input, navigation, overlay, feedback/status and forms.
4. Component audit documents tone/emphasis/state/semantics expectations.
5. README explicitly places dashboard/business widgets in module presentation, which prevents core DS pollution.

## Source gaps found

| Gap | Evidence | Impact on Theme 7 |
|---|---|---|
| `DSG-001` version governance | `pubspec.yaml` = `1.0.0`; project rule elsewhere calls DS v2 | Naming/governance only; user declaration makes this ZIP current technical source. |
| `DSG-002` missing assets | VAssets declares 6 asset paths; missing: `assets/illustrations/logo.png`, `assets/illustrations/empty_state.png`, `assets/illustrations/error_state.png`, `assets/icons/ic_calendar.svg`, `assets/icons/ic_chart.svg`, `assets/icons/ic_warning.svg` | Do not use these constants in Theme 7 until fixed. |
| `DSG-003` typography anomaly | `headingH4`/Mono fontSize 14 with height `22/16` | Do not patch in HTML; DS owner must correct source. |
| `DSG-004` spacing naming | `VSpacing.space0 = 1` | Renderer must use actual source value, not infer from token name. |
| `DSG-005` module-presentation boundary | Core DS intentionally has no Theme 7 business chrome | Compose Theme 7 module-presentation components from public DS; do not create an HTML DS. |

## Component audit notes

- Components/forms with `Semantics = No` in supplied audit: `VAppBar`, `VAvatar`, `VBottomNavigationBar`, `VCard`, `VEmailField`, `VMoneyField`, `VNumberField`, `VPasswordField`, `VContentWidth`, `VGap`, `VPagePadding`, `VPageScaffold`, `VResponsive`, `VResponsiveGrid`, `VResponsiveVisibility`, `VSection`, `VIcon`, `VIconBox`, `VText`.
- Core interactive components such as `VButton`, `VTextField`, `VCheckbox`, `VRadio`, `VSearchBar`, `VSelect`, `VChoiceList`, overlays and status components have stronger contracts.
- Test coverage is partial by symbol reference; it is not evidence of full state/golden coverage.

## Rule for later HTML

1. Do not copy DS into a permanent CSS token library by hand.
2. Do not fix DS source anomalies inside HTML.
3. Theme 7 module components may exist, but must compose public Flutter DS semantics/tokens and stay outside core DS.
4. Any cross-module reusable pattern discovered during HTML calibration should be proposed back to Flutter DS/module presentation before scale-out.
