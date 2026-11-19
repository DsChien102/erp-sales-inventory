# Flutter → HTML parity contract

HTML DS 2.0.2 is a source-level mirror of `c45_design_system` 1.4.1.

## Parity dimensions

| Dimension | Flutter authority | HTML implementation |
|---|---|---|
| Palette / semantic colors | `VColors`, `VColorScheme` | `src/tokens.css` |
| Typography | `VTypography` | `tokens.css` + `fonts.css` |
| Density | `VDensity` | density variables / `[data-v-density]` |
| Spacing / radius / border | token files | CSS variables |
| Shadows / motion / disabled | `VShadows`, `VDuration`, `VOpacity` | CSS variables/animations |
| Icons | `VIcons`, `VIcon`, Lucide 3.1.15 | `flutter-icons.json` + `c45-ds.js` |
| Primitive/component anatomy | Dart widget source | `components.css` / documented HTML anatomy |
| Form composition | `VField`, forms | `forms.css` |
| Responsive/patterns | pattern Dart source | `patterns.css` |
| Page shell | `VPageScaffold` | `.v-page-scaffold` / `.v-template` |
| Preview structure | Flutter example | `index.html` |

## Raster parity note

Flutter and Chromium are different raster/layout engines. The contract fixes semantic values and geometry to the same Dart source. Exact font/icon rasterization additionally requires the host to provide the same Inter, JetBrains Mono and Lucide font assets/families used by Flutter. The package intentionally does not redistribute font binaries.
