# Release validation — v3.3.0

Parent: **v3.2.1**

## Static gates

- PASS — `v330-visual-hierarchy-refactor.css` is loaded after v3.2.1 correction CSS.
- PASS — BJ08 collection-level border/radius is removed; product groups are separated by semantic whitespace.
- PASS — BJ08 product identity remains canonical `DS v2 / List Row`; quantity remains the existing DS field/keypad composition.
- PASS — BJ07 collection-level border/radius is removed; Product parent and subordinate LOT rows have different hierarchy responsibility.
- PASS — BJ07 child LOT rows remain flat and do not regain peer-card border/radius treatment.
- PASS — no business/state/action JavaScript logic changed; only composition metadata and visual CSS overrides were changed.
- PASS — `app.js`, `v310-audit-control-cluster.js`, and `v320-audit-control-ui-correction.js` pass Node syntax validation.

## Visual contract

- Canonical viewport: **402 × 874**.
- Horizontal product content boundary: **370 px**.
- Product groups use a larger inter-group gap than the spacing inside a group.
- Section/group hierarchy must remain understandable without relying on nested rounded surfaces.

## Note

This build intentionally does not introduce a new Theme 7 card or detail pattern. It composes existing DS primitives according to the Figma Layout guidance.

## Runtime smoke

- PASS — **497/497** declared-state renders at 402 × 874.
- PASS — **0** browser page errors.
- PASS — no root horizontal overflow detected across declared states.
- Visual captures included for BJ08 count, BJ08 recount and BJ07 preparation.
