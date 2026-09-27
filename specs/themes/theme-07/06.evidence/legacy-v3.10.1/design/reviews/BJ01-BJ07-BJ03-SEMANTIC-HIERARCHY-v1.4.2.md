# Product Review — Inventory Operations + BJ03 Semantic Hierarchy v1.4.2

## Trigger

Product review found `BJ07 / SCR-037` visually rendered Product and LOT almost identically. The user had to read content to infer hierarchy and could not immediately tell which row was the verification task.

## Root cause

The renderer reused one generic card grammar for task, Product parent, LOT child, physical allocation, valuation slice and result row. v1.4.1 successfully removed noise, but in some screens it also removed necessary role/action signals.

## Correction rules

1. **Parent/child must be visible without reading helper prose.** Product+UOM parent has its own header role; LOT/allocation/slice is nested and visually subordinate.
2. **Interactive child must expose expected action.** Unverified normal rows use a light action hint instead of repeated warning badges.
3. **Input label owns its meaning.** `Số lượng xác nhận giá` and `Quét hoặc nhập LOT để đối chiếu` do not rely on long footnotes.
4. **Numbers need labels.** Financial value beside Product is labeled `Giá trị sẽ ghi/đã ghi`.
5. **Results are grouped.** Repeated Product+LOT lines are not flattened into generic meta rows.
6. **Vocabulary is stable.** `dòng hàng` = Product+UOM business line; LOT/source LOT/actual LOT are explicitly named; allocation/slice is only described as a `phần hàng` where the user truly acts on a portion.
7. **Normal state stays quiet.** Exception/blocker/stale uses banners; permanent policy guidance becomes footnote/supporting text.

## Per-BJ outcome

- BJ01: no semantic correction required.
- BJ02: Product discovery affordance + explicit LOT label.
- BJ03: scope/calculation/review/result hierarchy corrected.
- BJ04: no semantic correction required.
- BJ05: partial-handover affordance and vocabulary corrected.
- BJ06: source-vs-actual LOT facts, evidence role and result grouping corrected.
- BJ07: preparation/review/result parent-child hierarchy corrected; LOT input meaning corrected.

## Business invariants

This release is presentation/interaction-meaning correction only. Existing authoritative quantity, approval, source-version, physical/value commit, mixed-UOM, stale invalidation and finality rules remain unchanged.

## Final QA evidence

- 73/73 semantic hierarchy checks PASS, including real click/focus/type on BJ07 LOT verification: wrong LOT blocks, matching LOT re-enables confirm, and confirmation does not mutate source LOT.
- 59/59 static/contract checks PASS.
- 17/17 business-invariant regression checks PASS.
- 87 all-flow renders PASS with no horizontal overflow/page exception.
- 12/12 protected-flow checks PASS for UIF01/UIF04/UIF13.
- 43/43 visual checks PASS across 21 screenshots at 402×874.
- 12/12 isolation checks PASS.

This is a Product-review candidate; QA evidence is not Product approval/freeze.
