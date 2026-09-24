# Inventory Operations End-user QA — v1.3.4

**Status: PASS for Product review.** This is QA evidence, not Product approval.

## Scope

- BJ-01 regression only; no redesign in this release.
- BJ-02 quantity-model correction in `SCR-084`.
- Full end-user review/design for BJ-04, BJ-05, BJ-06, BJ-07.
- Canonical Product viewport: `402 × 874`.

## Corrections made during QA

### BJ-02
- Removed duplicate total quantity input. Four fields `Đạt / Cách ly / Hỏng / Từ chối` are authoritative; `Tổng thực nhận` is derived.
- Applied the same rule per LOT.

### BJ-04
- Removed manual reservation workflow from active UI.
- Projection shows need / reserved / shortage and makes clear reservation does not reduce physical stock.

### BJ-05
- Search/no-result works at queue entry.
- Default order cannot reach handover until pick is actually completed.
- Removed allocation/version jargon from Product UI.
- FEFO/FIFO is expressed as a user-facing reason, not a technical acronym.
- LOT override requires an eligible LOT and mandatory reason.
- Pick quantity validates live and cannot exceed required quantity.
- No default approval or invented recipient/evidence field at handover.
- UNKNOWN has no blind retry.

### BJ-06
- Search/no-result works at queue entry.
- Pending wrong-LOT case stays in maker context; approver is a separate actor surface.
- Actual LOT input no longer rerenders on every keystroke and therefore does not lose focus.
- Wrong LOT requires evidence; approver sees original/actual LOT and cannot be maker.
- Approval does not commit stock.
- Return quantity cannot exceed cumulative remaining cap.
- Classification uses `Bán được / Cách ly / Hỏng / Hết hạn`; expired quantity is hard-blocked from returning to sellable.
- Classification does not post value a second time.

### BJ-07
- Search/no-result works and selected request keeps its own supplier/source context.
- Purchase/source authorization is not repeated as an Inventory approval.
- Source-version change is shown as one concise informational banner.
- `SCR-038` generic state-change UI is excluded from active BJ-07 while preserved for UIF-09.
- Handover does not invent recipient fields; physical/value decrease only at actual handover.
- UNKNOWN has no blind retry.

## Final automated/browser result

Targeted + cumulative Chromium suite: **150/150 PASS**.

Coverage includes all registered UIF/screen renders, 402×874 geometry, search/no-result, validation, actor handoff, hard guards, handover finality, UNKNOWN recovery and shared-SCR regression. See `RUNTIME-SMOKE-v1.3.4.md` and raw `INVENTORY-OPERATIONS-RUNTIME-QA-v1.3.4.txt`.
