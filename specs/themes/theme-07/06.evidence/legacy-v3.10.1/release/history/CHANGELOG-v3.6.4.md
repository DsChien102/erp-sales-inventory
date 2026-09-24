# Changelog — Theme 7 Prototype Harness v3.6.4

Parent: **v3.6.3**  
Date: **2026-09-15**

## Canonical VRadio / helper-text correction

- Fixes the reported BJ09 `Chuyển tình trạng hàng` choice component where supporting copy such as `Tạm thời không bán`, `Không còn đủ điều kiện bán`, and `Chuyển sang mục đích dùng thử` was rendered with a green pill background.
- Removes the legacy custom `choice-card` expression from the active BJ09 state-choice flow and maps the control back to canonical Figma `VRadio` (`522:7410`).
- Supporting text is now plain secondary text with a transparent background; it is no longer visually treated as a badge/status.
- Adds a cumulative guardrail for reachable helper/supporting text (`choice-card` helper, field helper, helper text, `__helper`) so it cannot inherit an accidental filled background.
- Preserves the v3.6.3 homogeneous Navigation/Disabled-row correction: non-clickable peers keep the same Navigation anatomy and chevron and use canonical `State=Disabled` with opacity `0.4`.
- No business rule, permission, transition, finality, field requirement, or destination changes.

## QA

- Radio/helper DS audit: **9/9 PASS**, all **518 declared route-state renders** scanned, **0** helper/supporting elements with non-transparent background, **0** reachable legacy `choice-card` instances mislabeled as `VRadio`.
- List Navigation State regression: **15/15 PASS**, mixed Navigation/Status peer collections **0**.
- List/Card Rhythm: **9/9 PASS**.
- Footer Action: **11/11 PASS**.
- Static consistency: **39/39 PASS**.
- Semantic flow/logic E2E: **21/21 PASS**.
- Full Theme completion: **14/14 PASS**.
- Representative coherence: **8/8 PASS**.
- Runtime UI: **14/14 PASS**.
- All-flow runtime smoke: **89/89 PASS**.
- Device frame: **7/7 PASS**, browser errors **0**.
