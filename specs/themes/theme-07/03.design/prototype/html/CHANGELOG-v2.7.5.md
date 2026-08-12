# Changelog — v2.7.5

- Corrected BJ05 LOT replacement from near-full Form Sheet to canonical content-driven VBottomSheet (`4695:6353`); removed the incorrect top-right close Icon Button.
- Hardened Product typography across all already-built BJ screens to the live Figma sans token stack, including form controls.
- Reorganized SCR-028 around Product/UOM → LOT/allocation → actual handover quantity for clearer scanning and decision making.
- Kept business behavior, commit boundary, partial-handover rules and cross-UOM non-aggregation unchanged.
- Added cross-BJ visual/runtime QA for font fallback, overflow, clipping, sheet semantics and BJ05 handover geometry.
