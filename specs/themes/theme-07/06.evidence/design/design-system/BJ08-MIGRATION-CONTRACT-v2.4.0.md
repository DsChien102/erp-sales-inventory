# BJ08 / UIF-08 Migration Contract — v2.4.1

## Scope
Deep correction of the v2.3.0 BJ08 candidate. This release fixes business-flow drift, actor/action ownership, blind-count behavior, evidence/price-basis handling, result finality, and false Design-System compliance.

## Authority
1. BJ-08 / UC-08-01…05 / decision register / BC-IC-01,02,03,08 / technical contracts: business behavior.
2. Live Figma DS v2.0.3: components, patterns, templates, tokens, typography, spacing, state, interaction and icons.
3. HTML prototype: implementation/verification only.

## Canonical product flow
- Maker/session: `SCR-042 → SCR-043 → SCR-044 → SCR-045`.
- Maker submit ends maker task; no automatic actor impersonation.
- Independent approver enters `SCR-046` from an eligible approval task.
- Approved/cancelled/rejected/unknown authoritative outcomes resolve on `SCR-047`.
- `Yêu cầu xem lại` is a human decision mutation under `ACT-09-APPROVE / BC-IC-03 / API-C-16`, requires reason and returns the same session to recount while retaining the lock according to policy.
- `ACT-09-CANCEL / BC-IC-08 / API-C-27` belongs to maker/session context, not the approval surface.

## Screen correction matrix
| Screen | Product correction | Figma DS expression |
|---|---|---|
| SCR-042 | Cancellation owned by the exact session; pending approval is maker read-only | Search/Filter, List Row, VBadge, VButton Danger, Confirmation Sheet Reason |
| SCR-043 | User decides scope + count reason only; resolved warehouse/cut-off/counter are read-only | Mobile/Form, Info Row, VSelect, VTextField, Search & Select, VBanner, Sticky Footer |
| SCR-044 | True blind DOM; actual quantities only; unexpected item selected from valid existing master | VBanner, Product count-line composition, VNumericKeypadSheet Quantity, Search & Select |
| SCR-045 | Only discrepancies; recount editable; evidence/price-basis is authoritative status, not invented fields | Info Row, VBadge, VBanner, VNumericKeypadSheet, Sticky Footer, Confirmation Sheet |
| SCR-046 | Independent read-only review; approve/request-review decisions; no cancellation | Mobile/Detail, Info Row, VBanner, VButton, Confirmation Sheet Plain/Reason |
| SCR-047 | Result-only; no mutation CTA; CANCELLED and UNKNOWN are explicit | Mobile/Detail + State Pattern + Theme7OperationResult |

## Hard invariants
- Before first count submit, no `book_quantity`, variance, or proxy derived from book quantity is present in visible/hidden/accessibility DOM.
- Unexpected physical items cannot create Product/LOT master and must remain inside the frozen scope predicate/tracking policy.
- Reviewer never edits count.
- Maker cannot self-approve.
- Surplus without valid authoritative price basis cannot proceed to adjustment.
- Evidence/price-basis schema is not invented by Product UI when the source contract does not define it.
- UNKNOWN keeps the same operation/idempotency identity; no blind retry/new adjustment.
- FINANCIAL_RESTRICTED values are omitted server-side unless authorized; CSS masking is invalid.

## DS variable / component gate
- Semantic Surface/Text/Border/Action/Icon tokens first.
- Spacing/dimensions consume Figma variables, including `space-3=12`; the issue is hardcoding, not the numeric value itself.
- Border width: `thin=1px`, `thick=2px` from live VBorders.
- Semantic radii: Input=8, Button=8, Card=12, Sheet=16, IconBox=12.
- Disabled appearance uses root opacity `0.4`.
- Icons use approved VET45 registry only.
- 402×874 mobile; 16px edge; 370px content; 44px minimum interactive target.

## DS internal discrepancy recorded, not hidden
Live component specimens currently show Confirmation Sheet top radius 20 and Numeric Keypad top radius 24, while Foundations `Radius/Sheet` specifies 16. Product runtime in v2.4.1 consumes the **semantic Foundation alias `Radius/Sheet=16`** so screen implementation has one semantic source of truth. This is a DS-master harmonization issue; it is not solved by inventing a Theme7 radius.

## v2.3.0 supersession
`BJ08-MIGRATION-CONTRACT-v2.3.0.md` is historical only. In particular, its temporary `Theme7TimeField / VTimePicker gap` is superseded: the current SCR-043 contract treats already-resolved cut-off as read-only context and does not require an editable time picker.
