# BJ01 / UIF-01 Migration Contract — v2.4.1

## Scope
Cumulative correction of BJ01 on the existing Theme 7 prototype. Business behavior is unchanged unless explicitly stated by existing BJ01 source; this contract standardizes screen architecture and Figma DS expression.

## Authority
1. BJ/UC/decision/data/behavioral/UI contracts: business behavior.
2. Live Figma DS v2.0.3 (`505:5889`, `505:5890`, `505:5891`): UI expression.
3. HTML: implementation/verification only.

## Screen mapping
| Screen | Template / pattern | Canonical DS | Theme7 Product composition |
|---|---|---|---|
| SCR-001 | Mobile list + search/filter | Search & Filter Header `547:2306`, VSearchBar, VChip, List Row `525:519`, VBadge, VEmptyState, VBanner | Theme7InventoryProductRow |
| SCR-003 | Mobile Detail | VText, Info Row, List Row, VBadge, VBanner, VButton | Theme7InventoryProductIdentity, Theme7AvailabilitySummary, Theme7InventoryLotRow, Theme7ContextSheet |

## Corrections carried into v2.4.1
- One inventory list only; no `Tra cứu/Cần chú ý` tabs.
- No card-per-product and no redundant outer list card.
- Availability is the single primary stock metric; physical/sellable/reserved are supporting facts.
- UOM appears with quantity only; tracking metadata does not clutter normal rows.
- LOT and provenance are contextual overlays; deeper trace hands off to BJ15.
- Search really covers name/code/barcode as promised by the placeholder.
- Normal state remains visually quiet.

## DS compliance
- Canonical component names are used only when the rendered anatomy actually follows that component.
- Product-specific compositions use `data-theme-component`, not false Core DS labels.
- Semantic variables first; no raw product color.
- Approved VET45 icon registry only.
- 402×874 / 16px edge / 370px content.
