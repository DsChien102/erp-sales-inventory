# v2.7.0 — BJ05 Figma DS structural migration and correction

- Cumulative from v2.6.0.
- Structurally migrated `BJ-05 / UIF-05` across `SCR-025..029` to the live Figma DS canonical surface.
- Preserved the active business flow: queue → pick overview ⇄ product/LOT pick → actual handover review → result.
- Preserved the stock boundary: pick does not reduce physical stock; confirmed actual handover does.
- Rebuilt the queue with `VSearchBar` + `VChip` + `DS v2 / List Row`; `Tất cả` remains default and waiting/source-owned work is truly read-only.
- Replaced legacy quantity-selector usage with numeric `VTextField` controls and contextual `DS v2 / Link` LOT actions.
- Implemented LOT override with the existing `DS v2 / Form Sheet` (`1353:6355`), `List Row / Selection`, `VRadio`, required `VTextarea` reason and one primary action.
- Kept alternative LOT unselected initially; changing a picked LOT resets affected picked evidence and requires exact return/repick correction.
- Simplified `SCR-028` to actual handover per allocation; no cross-UOM total is created.
- Reworked `SCR-029` as a finality-aware result surface: actual quantities by LOT, remaining quantities per Product/UOM for partial completion, no zero-remaining noise on completed, no Back to pre-commit, and no blind retry for UNKNOWN.
- Normal operation remains visually quiet; `VBanner` is reserved for shortage, stale physical correction, source change and real blockers.
- Added scoped `v270-bj05-ds-fidelity.css`; no new reusable Theme 7 component was created.
- Preserved prior migrated UIF-01/UIF-02/UIF-04/UIF-08 behavior and registry hashes.
