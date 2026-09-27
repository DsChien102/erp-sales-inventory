# BJ01 — Existing-component-first correction v2.4.3

## Problem found in v2.4.2

`Theme7AvailabilitySummary` was still treated as a Product component even though the live Figma DS already has a component that owns the primary summary-outcome responsibility. This violated the project's reuse priority and added unnecessary Theme-specific UI anatomy.

## Correction

- Delete `Theme7AvailabilitySummary` identity from Product HTML.
- Use `DS v2 / Key-value Row` (`525:358`) with `State=Emphasis` for `Khả dụng`.
- Use `DS v2 / Info Row` (`525:351`) for the three supporting quantities.
- Apply the same composition in the Product detail and LOT `VBottomSheet`.
- Keep only a layout wrapper; it is not a reusable component and must not appear as a Theme7 component in Inspect.

## Reuse rule locked for Theme 7

1. Prefer a semantically correct **V_component**.
2. If none exists, use another semantically correct **existing canonical DS component**.
3. Reuse an existing Pattern/Template/composition before inventing UI anatomy.
4. Use Product composition only as ordinary layout when needed; do not promote it to a component without reuse evidence.
5. Create a new reusable component only after the existing DS has been checked and a genuine cross-screen responsibility gap is demonstrated.

This rule applies to subsequent Theme 7 BJs and to future Theme design work using this Figma DS.
