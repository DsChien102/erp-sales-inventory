# Changelog — v3.8.2

## Warehouse Home action hierarchy correction

- Removed the standalone full-width **Primary** `Tạo thao tác` CTA that sat after the `Tra cứu` section.
- Repositioned `Tạo thao tác` into the **Việc của bạn** work context, alongside the inline task disclosure control.
- Downgraded `Tạo thao tác` to canonical **Secondary VButton** emphasis because continuing assigned work is the primary behavior of the task-driven Warehouse Home; starting a new warehouse task is an explicit secondary path.
- Kept `Tra cứu` below the work context and kept `Tất cả chức năng kho` as the low-emphasis long-tail discoverability route after Tra cứu.
- Preserved the existing four-option `Tạo thao tác` bottom sheet and its dismiss-by-backdrop/Escape behavior; no redundant `Đóng` CTA was reintroduced.
- No BJ business rule, state machine, transaction finality, task routing, catalog coverage, or existing screen renderer changed.

## QA

- Warehouse Home Action Hierarchy: **21/21 PASS**
- All-flow runtime smoke: **89/89 PASS**
- Runtime UI: **14/14 PASS** across the existing **518 declared states**
- Device frame: **7/7 PASS**, **89 screens checked**, canonical **402×874** product viewport preserved
- Flow/logic E2E: **21/21 PASS**
- Browser errors in the focused layout QA: **0**
