# BJ-01 — Phase B Review v0.3.2

## Review trigger
Product review của v0.3.1 phát hiện screen/list mode thừa, card inflation, UOM duplication, technical/English copy và LOT detail over-navigation — các lỗi tương tự bài học BJ-02.

## Corrected architecture
`SCR-001 Tồn kho → SCR-003 Chi tiết tồn kho`

Contextual overlays trong `SCR-003`:
- LOT Detail Bottom Sheet (`SCR-004` migration ID).
- Provenance Bottom Sheet (`SCR-005` migration ID).

## Information hierarchy lock
- List: identity + available quantity; indicator chỉ khi bổ sung quyết định.
- Detail: one hero available quantity + three supporting rows.
- LOT: contextual detail only; no duplicate Product card.
- Threshold/target/suggested: conditional, not default information.
- Business indicator ≠ presentation state.
- Product UI Vietnamese business copy only.

## Release rule
v0.3.2 chỉ hợp lệ khi BJ-02 regression pass và non-BJ01 files ngoài allowlist không đổi so với v0.3.1.

## Self-QA result
- Static BJ-01 contract QA: **24/24 PASS**.
- Real Chromium BJ-01 runtime/interaction/geometry QA: **61/61 PASS**.
- Visual specimen review: `SCR-001` all/LOW, `SCR-003` normal/LOW, LOT sheet, provenance sheet.
- Self-QA corrections made before freeze: FILTER_EMPTY recovery, long Product-name wrapping, compact two-line Product-row metadata, provenance evidence changed from nested card to row separators.
- BJ-02 protected regression suite on v0.3.2: **78/78 PASS**.

`v0.3.2` is ready for Product review; QA PASS is not the same as Product UX approval.
