# Release validation — Theme 7 Prototype Harness v3.6.3

**Verdict: PASS — HOMOGENEOUS NAVIGATION LIST / DISABLED-STATE CORRECTION**

Parent: **v3.6.2**  
Date: **2026-09-15**

## Defect and rule

The reported list mixed two component semantics inside one peer task collection: actionable rows were `DS v2 / List Row · Type=Navigation` with chevrons, while `PN-260816-02 · Chờ căn cứ` was rendered as a read-only `Status` row without a chevron.

That violates the locked Theme 7 rule already used in other journeys: when a peer destination is temporarily unavailable, **do not change its row type**. Keep the same Navigation anatomy/chevron and express unavailability through the canonical `Disabled` state.

## Whole-runtime audit

The effective v3.6.2 runtime was scanned across all **518 declared route-state renders**. The same mixed `Navigation/Status` peer-list defect appeared only in:

1. **UIF-03 / SCR-014 — Hàng chờ xác nhận giá nhập**.
2. **UIF-13 / SCR-085 — Chi phí mua bổ sung**.

Across their declared states this produced **10 mixed peer-collection renders**. No other homogeneous DS List Row navigation collection had the same defect.

## Correction

For both affected lists:

- all peer task rows use `DS v2 / List Row · Type=Navigation`;
- actionable rows use `State=Default` and remain clickable;
- waiting rows use `State=Disabled`;
- waiting rows keep the same chevron and geometry as their peers;
- disabled rows are native disabled buttons with `aria-disabled=true`;
- disabled visual state uses DS parent opacity **0.4**, not a custom disabled color;
- clicking a disabled row cannot navigate; clicking an actionable peer still navigates to the correct next screen.

The rule is also promoted to the cross-UIF design contracts so later BJ work cannot reintroduce the same inconsistency.

## QA gates

| Gate | Result |
|---|---:|
| List Navigation State — all declared states | **15/15 PASS** |
| Mixed Navigation/Status peer collections after fix | **0** |
| List/Card Rhythm regression | **9/9 PASS** |
| Footer Action regression | **11/11 PASS** |
| Static consistency | **37/37 PASS** |
| Semantic flow/logic E2E | **21/21 PASS** |
| Full Theme completion | **14/14 PASS** |
| Representative coherence | **8/8 PASS** |
| Runtime UI | **14/14 PASS** |
| All-flow runtime smoke | **89/89 PASS** |
| Canonical device frame | **7/7 PASS** |
| Current package validation | **15/15 PASS** |
| Browser page errors | **0** |

## QA evidence

- `specs/themes/theme-07/prototype/html/qa/LIST-NAVIGATION-STATE-QA-v3.6.3.md`
- `specs/themes/theme-07/prototype/html/qa/LIST-SURFACE-RHYTHM-QA-v3.6.3.md`
- `specs/themes/theme-07/prototype/html/qa/FOOTER-ACTION-QA-v3.6.3.md`
- `specs/themes/theme-07/prototype/html/qa/RUNTIME-UI-QA-v3.6.3.md`
- `specs/themes/theme-07/prototype/html/qa/CURRENT-PACKAGE-VALIDATION-v3.6.3.md`
- focused browser captures: `specs/themes/theme-07/prototype/html/qa/v363-list-navigation-captures/`

## Evidence boundary

This validates the browser prototype and represented UI/flow/state behavior. It does not prove production backend persistence, transaction, concurrency, outbox, network or crash/restart atomicity.
