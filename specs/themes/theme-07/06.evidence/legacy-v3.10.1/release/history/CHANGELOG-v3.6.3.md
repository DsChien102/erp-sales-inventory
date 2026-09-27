# Changelog — Theme 7 Prototype Harness v3.6.3

Parent: **v3.6.2**  
Date: **2026-09-15**

## Homogeneous navigation-list / disabled-state correction

- Fixes the reported `Hàng chờ xác nhận giá nhập` list inconsistency where actionable peer rows used `DS v2 / List Row · Type=Navigation` with chevrons, while the waiting peer switched to `Type=Status` and lost its chevron.
- Re-applies the already-established Theme 7 invariant: **unavailable is a state, not a different row type**. In one homogeneous destination/task collection, all peer rows keep the same Navigation anatomy; a row that cannot currently open uses `State=Disabled`, keeps the same chevron/geometry, and receives no interaction.
- Whole-runtime audit across **518 declared route-state renders** found the same defect class in exactly two active Product screens:
  - **UIF-03 / SCR-014 — Hàng chờ xác nhận giá nhập**.
  - **UIF-13 / SCR-085 — Chi phí mua bổ sung**.
- Both screens are corrected. Waiting rows now use native disabled Navigation buttons with `aria-disabled=true` and DS parent opacity `0.4`; actionable rows remain enabled Navigation rows.
- The invariant is promoted to `CROSS-UIF-DECISIONS.md` and `UX-PATTERN-REGISTRY.md`, and the UIF-03/UIF-13 component-usage contracts are updated to prevent the defect from recurring.

## QA expansion

- New `LIST-NAVIGATION-STATE-QA-v3.6.3` scans all **518** route-state renders and validates Navigation chevrons, native disabled behavior, DS disabled opacity, enabled-row interactivity, homogeneous peer collections, and actual disabled/actionable click behavior.
- Baseline mixed Navigation/Status peer-collection renders: **10** across the two affected screens/states.
- Post-fix mixed peer collections: **0**.
- Regression remains green: list/card rhythm **9/9**, footer **11/11**, static consistency **37/37**, semantic flow logic **21/21**, full-theme completion **14/14**, representative coherence **8/8**, runtime UI **14/14**, all-flow smoke **89/89**, device frame **7/7**, current package validation **15/15**, browser page errors **0**.

## Scope lock

- UI component-state/anatomy correction only.
- No business rule, field, permission, task ownership, destination, finality or lifecycle change.
- No new Design System component or pattern.
