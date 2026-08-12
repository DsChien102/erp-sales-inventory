# Theme 7 HTML Prototype — Changelog v2.0.2

Parent: **v2.0.1**  
Scope: **Phase 3 representative Figma DS calibration**

## Changed Product expression

- Calibrated UIF-02, UIF-05, UIF-08, UIF-10, UIF-15 and UIF-17 against exact live Figma DS v2.0.2 component/pattern/template responsibilities.
- Added explicit per-screen Mobile template mapping for all screens in the six calibration UIFs.
- Normalized AppBar, mobile gutter, form-control, List Row, Info Row, quick-filter and Sticky Footer geometry to the live Figma assets.
- Removed generic clickable-card semantics from calibrated navigation/selection surfaces.
- Removed historical HTML-only `VQuantitySelector` from calibrated Product renders; plain quantity entry now uses canonical `VTextField` semantics.
- Normalized representative evidence events to `DS v2 / Timeline Item`.
- Updated Figma-native Inspect/mapping resolution for the calibrated component and template expressions.

## Preserved

- v2.0.1 business behavior and flow topology.
- 106 SRS files.
- Canonical screen registry bytes.
- Non-target UIF Product rendering, protected by exact visual regression.

## QA

- Phase 3 calibration: 14/14 gates · 212 representative states PASS.
- Figma mapping: 18/18 gates · 497 states · 10,495 annotations PASS.
- Holistic semantic/runtime: 6/6 gates · 497 states PASS.
- Protected non-target visual: 50 exact Product renders PASS.
- Visual specimens: 30 at 402×874 PASS.
