# Release validation — Theme 7 Prototype Harness v3.6.4

**Verdict: PASS — CANONICAL VRADIO / HELPER-TEXT DS CORRECTION**

Parent: **v3.6.3**  
Date: **2026-09-15**

## Reported defect

BJ09 `SCR-038 — Chuyển tình trạng hàng` used a legacy custom `choice-card` while declaring it as `VRadio`. Its supporting text was styled as a green pill, visually implying badge/status semantics that do not exist in the Figma Design System.

## Figma DS verification

- `VRadio` node `522:7410`: canonical 20px radio control, 14/22 label, On/Off/Disabled states; disabled uses parent opacity `0.4`.
- `DS v2 / List Row` node `525:519`: disabled is a state, not a different semantic row type; Navigation keeps its trailing chevron in Disabled state.

## Correction

- Active BJ09 choices now use canonical `VRadio` semantics and geometry.
- Explanatory copy is composed as plain secondary text with transparent background.
- No helper text is rendered as a badge/pill unless the source UI explicitly uses `VBadge`.
- A cumulative helper guardrail prevents legacy field/choice helpers from receiving filled backgrounds.
- v3.6.3 chevron/Disabled-state correction remains intact.

## Whole-runtime QA

All **518 declared route-state renders** were scanned for helper/supporting text backgrounds.

| Gate | Result |
|---|---:|
| Radio / Helper DS | **9/9 PASS** |
| Visible helper text with non-transparent background | **0** |
| Reachable legacy `choice-card` mislabeled as `VRadio` | **0** |
| List Navigation State | **15/15 PASS** |
| Mixed Navigation/Status peer collections | **0** |
| List/Card Rhythm | **9/9 PASS** |
| Footer Action | **11/11 PASS** |
| Static consistency | **39/39 PASS** |
| Semantic flow/logic E2E | **21/21 PASS** |
| Full Theme completion | **14/14 PASS** |
| Representative coherence | **8/8 PASS** |
| Runtime UI | **14/14 PASS** |
| All-flow runtime smoke | **89/89 PASS** |
| Canonical device frame | **7/7 PASS** |
| Browser page errors | **0** |

## Evidence

- `specs/themes/theme-07/prototype/html/qa/RADIO-HELPER-DS-QA-v3.6.4.md`
- `specs/themes/theme-07/prototype/html/qa/LIST-NAVIGATION-STATE-QA-v3.6.4.md`
- `specs/themes/theme-07/prototype/html/qa/LIST-SURFACE-RHYTHM-QA-v3.6.4.md`
- `specs/themes/theme-07/prototype/html/qa/FOOTER-ACTION-QA-v3.6.4.md`
- `specs/themes/theme-07/prototype/html/qa/STATIC-CONSISTENCY-QA-v3.6.4.md`
- focused capture: `specs/themes/theme-07/prototype/html/qa/v364-radio-helper-captures/UIF-09-SCR-038-READY.png`

## Scope lock

UI/DS conformance correction only. No business semantics or state-machine behavior changed.
