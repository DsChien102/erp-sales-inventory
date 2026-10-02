# Foundations — Flutter 1.4.1 canonical

HTML DS 2.0.0 mirrors the supplied `vet45_design_system` Flutter package 1.4.1. Flutter source is authoritative for every value below.

## Typography

Host families must be the same families used by Flutter: **Inter** and **JetBrains Mono**. Binary font files are deliberately not redistributed by this package.

| Token | Flutter value |
|---|---|
| D1 | 40/44, 800, letter-spacing -1 |
| H1 | 28/34, 700, -0.5 |
| H2 | 22/28, 700, -0.3 |
| H3 | 18/24, 600, -0.2 |
| H4 | 14/19.25, 600 |
| Body Default | 14/22, 500 |
| Body Small | 13/20, 500 |
| Label Default | 14/20, 600 |
| Label Small | 11/14, 600 |
| Caption | 12/16, 600 |
| Action Default | 14/20, 600 |
| Mono Numeric | 14/20, 500 |

## Spacing

`1, 4, 8, 12, 16, 20, 24, 32, 40, 48, 72`. Mobile page edge is 16. Minimum touch target is 44.

## Radius

`4, 6, 8, 12, 16, 20, pill 999`. Input/button 8, card 12, sheet 16, icon box 12.

## Density

Comfortable controls: 36 / 44 / 52. Compact controls: 32 / 40 / 48.

## Opacity and motion

Disabled is whole-subtree opacity **0.4**. Durations: 150 / 200 / 300 / 350 / 1000 ms.

## Color

Primitive and semantic palettes are generated from Flutter `VColors` and `VColorScheme`. Use semantic CSS variables from `src/tokens.css`; Themes must not hard-code replacement component colors.
