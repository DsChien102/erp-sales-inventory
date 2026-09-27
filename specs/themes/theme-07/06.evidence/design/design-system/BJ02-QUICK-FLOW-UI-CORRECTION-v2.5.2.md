# BJ02 Quick Flow + UI Correction — v2.5.2

Parent: **v2.5.1**. Scope: **UIF-02 only**; BJ01/BJ08 unchanged.

## Root causes corrected
- `render009()` referenced an undefined `total`, so navigation state changed to SCR-009 but rendering aborted and stale SCR-008 remained visible.
- v2.5.1 QA seeded screens directly and did not execute the real Quick click path.
- Quick Product/UOM interaction had regressed to add-and-stay / dropdown behavior, conflicting with current UC-02-02 and SCR-009 contract.
- Nested LOT editor inherited 370px field widths inside 16px padding, causing clipping/overflow.

## Locked interaction
`SCR-006 → SCR-008 → SCR-009 → Product`
- one valid inbound UOM → `SCR-084` immediately;
- multiple valid inbound UOMs → all choices visible as `DS v2 / List Row` Selection → chosen UOM → `SCR-084` immediately;
- duplicate Product+UOM → open existing item;
- `Xong` → `SCR-009`; when every item is handled → `SCR-010`.

## DS/UX constraints
- Existing-component-first / V-first governance remains mandatory.
- No new Theme7 shared component.
- 402×874 canvas, 370px page content; padded LOT editor inner content = 338px.
- Long evidence/LOT values may wrap or intentionally ellipsize within their semantic control but may not create page-level horizontal overflow.
- `VFileDropZone` retains short canonical title/description; selected filename is supporting Product text below it.

## QA change
Real user interaction is now a release gate. Directly setting `activeScreenId` is not accepted as proof that a transition works.
