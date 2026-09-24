# Changelog — BJ-01 v0.3.2

Parent: `v0.3.1` (cumulative).

## Changed
- Removed `Tra cứu / Cần chú ý` mode split from SCR-001; one list with search + five filter chips.
- Replaced card-heavy product presentation with compact homogeneous rows.
- Removed repeated UOM and tracking-policy metadata from list rows.
- Rebuilt SCR-003 hierarchy around one primary `Khả dụng` value plus three supporting rows.
- LOW/OUT threshold and replenishment suggestion are conditional; normal/no-threshold states stay quiet.
- LOT and provenance details are contextual Bottom Sheets; deep stock history hands off to BJ-15.
- Product-level and LOT-level indicators use distinct wording.
- Removed technical/English wording from BJ-01 Product UI.

## Self-QA fixes inside the same round
- Restored READY state when clearing FILTER_EMPTY or changing filter.
- Long Product names wrap on detail instead of truncating/colliding with the primary quantity.
- Compact Product-row metadata was reduced to two visual lines.
- Provenance evidence no longer uses a nested rounded card.

## Protected baseline
- BJ-02/UIF-02 business/UI contracts are not changed.
- BJ-02 real Chromium regression: 78/78 PASS.
- Historical `screenshots-v0.2.9` in the canonical package are untouched.
