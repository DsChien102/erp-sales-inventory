# Wave 2 — BJ02 Nhận hàng mua — Deep Review Closure v3.9.2

## Status

**DEEP-REVIEWED / LOCK CANDIDATE**

Review basis: cumulative Prototype Harness **v3.9.1 only**. The approved BJ02 findings were propagated through business, decision, behavioral/data/presentation contracts, fixtures and runtime, then re-reviewed on **v3.9.2**.

## Resolved semantic findings

| Finding | Resolution |
|---|---|
| Over-source control used `Đạt` instead of actual quantity entering physical stock | Locked `Tổng kiểm nhận = Đạt + Cách ly + Hỏng + Từ chối`; `Vào tồn vật lý = Đạt + Cách ly + Hỏng`; over-source/approval uses accepted physical quantity normalized to base UOM. |
| `sourceExpected` did not say whether it was ordered, delivered or remaining quantity | Source now owns `source_line_id/version + remaining_receivable_qty + transaction UOM/conversion snapshot`; Theme 7 does not invent the remainder. |
| Quick Receipt could reach inventory without a structured ownership basis | Added versioned `ownership_assertion` bound to authorized actor, time and delivery evidence; missing assertion keeps the receipt Draft. |
| Delivery file requirement was under-defined while the UI invented DOC/DOCX/10 MB rules | Renamed to **Chứng từ giao nhận**; business evidence types are defined, 1+ immutable evidence refs are allowed, and technical MIME/size/count belongs to the Shared Attachment Policy. |
| Approval risk could be wrong across UOM and had fixture-only price basis | Risk uses accepted physical **base quantity × authoritative price per base UOM**; official cost first, otherwise versioned source price + FX snapshot. |
| Receipt date came from the browser and could imply a future/incorrect business date | `receipt_business_date` is the server tenant business date and is read-only; source document date is a separate fact. |
| LOT date entry forced day-level precision | HSD/NSX preserve DAY/MONTH/YEAR; higher precision can enrich a consistent value with audit; contradiction blocks instead of overwriting. |
| Approver could see a filename without enough decision evidence | Approval surface exposes immutable evidence preview, `Người gửi`, `Gửi lúc`, and aggregate risk total when permitted; unit-cost details remain separately controlled. |
| Changing source could silently invalidate entered quantities/LOT/evidence | `Đổi chứng từ` requires explicit destructive confirmation; Supplier change in Quick invalidates/revalidates dependent ownership/evidence/price basis. |
| Zero-impact results could claim stock was added | Document flow may complete with `Không có hàng vào tồn vật lý`; Quick cannot submit when accepted physical quantity is zero. |
| Quick was always visible even when the actor had no capability | No capability → option hidden. Temporary configuration blocker → disabled Navigation Row with an explicit helper. |
| Recovery UI could narrate a committed movement without authoritative evidence | UNKNOWN keeps the same operation identity; recovery only surfaces facts proven by authoritative evidence and keeps the BJ17 handoff. |

## Necessity decisions

- **KEEP + SHOW:** Supplier, warehouse, receipt business date, source document identity, remaining receivable quantity, four classification quantities, delivery evidence, LOT/HSD when required, approval reason, sender/submitted time, aggregate approval risk when authorized.
- **SAFE DERIVED + SHOW when useful:** `Tổng kiểm nhận`, `Vào tồn vật lý`, over/under source difference, total risk.
- **DEFINE, DO NOT SHOW normally:** source line version, conversion snapshot/version, evidence hash/version, ownership assertion version, price basis source/version/FX snapshot, ledger sequence.
- **REMOVE:** generic Quick note, hard-coded DOC/DOCX/10 MB copy, browser-clock date authority, ambiguous `sourceExpected`, silent source reset, cross-UOM aggregate quantity.
- **HANDOFF:** unknown finality may route to BJ17; valuation of accepted physical stock remains BJ03 responsibility.

## Fresh-eye findings caught after the approved change set

The second-pass visual/runtime review found four additional implementation issues before release. They were corrected in the same v3.9.2 change set:

1. Legacy v3.6.0 representative seeding could overwrite an explicitly prepared BJ02 receipt on `SCR-010`. The seeder now recognizes meaningful draft data and only seeds direct Inspector entry when appropriate.
2. The first DAY/MONTH/YEAR implementation forced two fixed-width DS fields into a two-column mobile grid and visually overlapped. It now uses a canonical vertical VSelect + VTextField composition inside the 338px editor content width.
3. User-visible English leakage (`source-version`, `Preview`, `movement authoritative`) was removed.
4. The v3.9.2 `SCR-013` renderer initially masked the earlier explicit BJ17 unknown-result handoff. The recovery CTA now retains `bj02-handoff-unknown` and the full-flow E2E guard passes.

The LOT copy was also simplified from the technical phrase `Độ chính xác HSD/NSX` to user language `Cách ghi hạn dùng / Cách ghi ngày sản xuất`, while the underlying precision contract remains DAY/MONTH/YEAR.

## Cross-BJ impact scan

The approved changes were scanned against downstream/adjacent Theme 7 journeys without redesigning them ahead of their turn:

- **BJ03 — Xác nhận giá trị:** remains the valuation owner. BJ02 now hands over clearer accepted-physical/base-UOM and versioned price-basis context; no BJ03 UI redesign was required in this release.
- **BJ05 — Lấy hàng:** base-UOM normalization remains compatible; BJ05 still owns authoritative LOT allocation. No local flow change required.
- **BJ06 — Khách trả:** its business-specific wrong-LOT photo evidence remains valid. Technical attachment limits should consume the shared attachment policy when BJ06 is deep-reviewed.
- **BJ07 — Trả NCC:** immutable handover evidence/source-version behavior remains compatible; no current UI change required.
- **BJ09 — Tình trạng hàng:** accepted classification states remain compatible with the physical-vs-sellable separation.
- **BJ10 — Tiêu hủy:** maker-checker/risk logic remains compatible with the shared principle that risk quantity must be normalized to the authoritative unit basis. Local details remain for BJ10's own review.
- **BJ15 — Báo cáo/thẻ kho:** continues to own deep source/movement trace; BJ02 only owns the receiving evidence/result necessary for the operation.
- **Shared contracts:** the Attachment Evidence Contract and LOT precision semantics are now common authorities; later BJ reviews must reuse them rather than create local technical file/precision rules.

## Fresh-eye result

After the fixes above, the full BJ02 journey was re-walked from `SCR-006` through document/Quick branches, item editing, review, approval, result and UNKNOWN recovery. **No remaining P0/P1 semantic blocker was found in BJ02.**

BJ02 is therefore a **Deep-Reviewed / Lock candidate**. Any later change to receipt quantity semantics, source remainder, ownership evidence, base-UOM approval risk, receipt business date or LOT precision must be treated as a shared/cross-BJ contract change rather than a local screen tweak.

## Regression boundary

BJ01 remains locked. BJ03/BJ05/BJ06/BJ07/BJ09/BJ10/BJ15 were impact-scanned only; their local UX stays frozen until their own deep-review turn unless a shared contract change requires compatibility.
