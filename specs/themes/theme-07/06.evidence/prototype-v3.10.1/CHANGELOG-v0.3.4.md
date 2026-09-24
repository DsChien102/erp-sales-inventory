# CHANGELOG v0.3.4

Parent: `v0.3.3`. Cumulative incremental update.

## BJ-01 / UIF-01
- Search now truly matches product name, product code and barcode.
- STALE refresh updates visible as-of.
- LOW/OUT copy explains threshold/target/suggested quantity.
- Provenance entry and sheet reduce duplication and technical wording.

## BJ-02 / UIF-02
- Quick SCR-009 replaces `Thêm sản phẩm` CTA with inline `VSearchBar`.
- Product/UOM selection happens on SCR-009 and adds a PENDING item without navigation.
- Duplicate Product+UOM is blocked on the overview with open-existing recovery.
- SCR-084 always shows Accepted/Quarantine/Damaged/Rejected; Accepted is derived read-only.
- Approval, auto-execution, result and UNKNOWN recovery remain unchanged.

## Isolation
- Only UIF01/UIF02 contracts/renderer/data/QA plus version metadata are allowed to change.
- Non-target UIFs must remain byte-identical to v0.3.3.

## QA corrections made during v0.3.4
- BJ01: Bottom-sheet handle changed from danger red to a neutral DS border tone; the red handle falsely signaled a destructive state.
- BJ02: Search-result `hidden` state now wins over grid display so filtering truly hides non-matching products.
- BJ02: While a multi-UOM Product is waiting for UOM selection, the unrelated "Chưa có sản phẩm" empty state is suppressed to reduce noise.
- BJ01/BJ02: browser QA was rerun after these corrections.
