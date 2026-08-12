# Phase 3 — Representative Figma DS Calibration — v2.0.2

**Parent:** v2.0.1  
**UI authority:** live Figma Design System v2.0.2  
**Business/behavior baseline:** unchanged from cumulative Theme 7 v1.9.0  
**Release intent:** calibrate one representative set before the full 73-screen rollout.

## Scope

The calibrated Product flows are:

- `UIF-02` — Nhận hàng mua
- `UIF-05` — Lấy hàng và bàn giao đơn
- `UIF-08` — Kiểm kê và điều chỉnh chênh lệch
- `UIF-10` — Tiêu hủy hàng
- `UIF-15` — Tra cứu báo cáo tồn và thẻ kho
- `UIF-17` — Phục hồi nghiệp vụ có kết quả chưa xác định

All other UIFs remain protected on the v2.0.1 Product rendering in this release.

## Live Figma references used for calibration

| Responsibility | Canonical Figma asset | Node |
|---|---|---|
| App bar | `VAppBar` | `547:1594` |
| Primary/secondary action | `VButton` | `521:529` |
| Search | `VSearchBar` | `522:7245` |
| Quick filter | `VChip` | `522:7449` |
| List/navigation row | `DS v2 / List Row` | `525:519` |
| Read-only fact row | `DS v2 / Info Row` | `525:351` |
| Summary | `DS v2 / Summary Card` | `525:552` |
| Evidence event | `DS v2 / Timeline Item` | `525:587` |
| Feedback | `VBanner` | `526:4215` |
| Full-content state | `VEmptyState` | `526:4352` |
| Sticky action area | `DS v2 / Sticky Footer` | `549:927` |
| Search/filter composition | `DS v2 / Search & Filter Header` | `547:2306` |
| Root list template | `Mobile / Root List` | `551:549` |
| Nested list template | `Mobile / Nested List` | `551:1277` |
| Detail template | `Mobile / Detail` | `551:1396` |
| Form template | `Mobile / Form` | `551:1452` |
| Search & Select template | `Mobile / Search & Select` | `551:1621` |
| State template | `Mobile / State` | `551:1746` |

## Explicit screen → template calibration

| UIF | Screen | Figma template | Node |
|---|---|---|---|
| UIF-02 | SCR-006 | Mobile / Nested List | `551:1277` |
| UIF-02 | SCR-007 | Mobile / Nested List | `551:1277` |
| UIF-02 | SCR-008 | Mobile / Form | `551:1452` |
| UIF-02 | SCR-009 | Mobile / Form | `551:1452` |
| UIF-02 | SCR-084 | Mobile / Search & Select | `551:1621` |
| UIF-02 | SCR-010 | Mobile / Detail | `551:1396` |
| UIF-02 | SCR-011 | Mobile / Detail | `551:1396` |
| UIF-02 | SCR-012 | Mobile / State | `551:1746` |
| UIF-02 | SCR-013 | Mobile / State | `551:1746` |
| UIF-05 | SCR-025 | Mobile / Root List | `551:549` |
| UIF-05 | SCR-026 | Mobile / Detail | `551:1396` |
| UIF-05 | SCR-027 | Mobile / Form | `551:1452` |
| UIF-05 | SCR-028 | Mobile / Detail | `551:1396` |
| UIF-05 | SCR-029 | Mobile / State | `551:1746` |
| UIF-08 | SCR-042 | Mobile / Root List | `551:549` |
| UIF-08 | SCR-043 | Mobile / Form | `551:1452` |
| UIF-08 | SCR-044 | Mobile / Form | `551:1452` |
| UIF-08 | SCR-045 | Mobile / Form | `551:1452` |
| UIF-08 | SCR-046 | Mobile / Detail | `551:1396` |
| UIF-08 | SCR-047 | Mobile / State | `551:1746` |
| UIF-10 | SCR-036 | Mobile / Root List | `551:549` |
| UIF-10 | SCR-037 | Mobile / Detail | `551:1396` |
| UIF-10 | SCR-040 | Mobile / Form | `551:1452` |
| UIF-10 | SCR-041 | Mobile / State | `551:1746` |
| UIF-15 | SCR-054 | Mobile / Form | `551:1452` |
| UIF-15 | SCR-055 | Mobile / Detail | `551:1396` |
| UIF-15 | SCR-056 | Mobile / Detail | `551:1396` |
| UIF-15 | SCR-057 | Mobile / Detail | `551:1396` |
| UIF-15 | SCR-058 | Mobile / Detail | `551:1396` |
| UIF-15 | SCR-059 | Mobile / State | `551:1746` |
| UIF-17 | SCR-078 | Mobile / Root List | `551:549` |
| UIF-17 | SCR-079 | Mobile / Detail | `551:1396` |
| UIF-17 | SCR-080 | Mobile / Detail | `551:1396` |
| UIF-17 | SCR-082 | Mobile / Detail | `551:1396` |
| UIF-17 | SCR-083 | Mobile / State | `551:1746` |

## Calibration rules locked in HTML

- Product viewport remains `402 × 874`.
- Status Bar anatomy = 24px; `VAppBar` = 56px and H4 title treatment.
- Main mobile gutter = 16px. The calibrated content rhythm follows the 12px live-template spacing where applicable.
- Sticky action surfaces use `DS v2 / Sticky Footer`: 92px anatomy, 16px horizontal inset, 12px top padding, 24px bottom safe-area allocation and 44px canonical buttons.
- Forms use canonical 44px controls and Radius 8; textarea input uses the live Form-template proportions.
- Search uses `VSearchBar`; quick filter chips use 44px interaction targets around 36px visual pills, with Brand semantics for the selected filter.
- Operational navigation/selection records use independent `DS v2 / List Row` surfaces. A generic clickable `VCard` is no longer considered a canonical answer.
- Read-only facts use `DS v2 / Info Row` or an explicit token-based `VSection` composition when the content is a group, not a card object.
- Plain numeric quantity entry uses `VTextField`. The historical HTML-only `VQuantitySelector` is not emitted by the calibrated Product renderer.
- Evidence events use `DS v2 / Timeline Item`.
- Result/empty/error/blocked/permission semantics use the State-template responsibility and `VEmptyState` where applicable.
- Search/filter patterns are applied by task semantics. The renderer does not add an inert advanced-filter button merely to visually copy the `Search & Filter Header` specimen.

## Business protection

No business behavior was changed by this release. In particular:

- approval remains an actor handoff;
- inventory commit/finality rules remain unchanged;
- blind count remains blind before first submission;
- disposal approval does not decrease stock;
- report/inquiry remains read-only;
- `UNKNOWN != FAILED`; no blind retry and no new operation identity.

`106` SRS files and the screen registry are protected against this UI calibration.

## Release boundary

This is a **representative calibration**, not the full Theme 7 migration. Phase 4 must apply these calibrated rules to every remaining canonical screen and then run full-product DS conformance and regression gates.
