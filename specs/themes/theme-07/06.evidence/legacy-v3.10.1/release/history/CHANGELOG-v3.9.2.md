# Changelog — VET45 Theme 7 Prototype Harness v3.9.2

**Parent:** v3.9.1  
**Scope:** Wave 2 — BJ02 Nhận hàng mua — Deep-Dive Semantic Traceability hardening.

## Authority / review rule

- v3.9.1 was used as the **single Theme 7 review baseline**.
- No separate legacy Theme 7 source package was used as authority.
- v3.9.2 becomes the next cumulative review baseline after release.
- BJ01 remains locked from Wave 1.

## Approved BJ02 decisions implemented

1. **Quantity semantics:** `Tổng kiểm nhận = Đạt + Cách ly + Hỏng + Từ chối`; `Vào tồn vật lý = Đạt + Cách ly + Hỏng`; rejected quantity never increases stock.
2. **Source authority:** source line/version owns `remaining_receivable_qty`, transaction UOM and conversion snapshot; Theme 7 does not infer remaining source quantity.
3. **Quick ownership:** Quick Receipt requires a structured, versioned ownership assertion from an authorized actor and is bound to delivery evidence.
4. **Delivery evidence:** `Chứng từ giao nhận` supports 1+ immutable business evidence refs; technical MIME/size/count comes from the Shared Attachment Policy rather than BJ02-local DOCX/10 MB assumptions.
5. **Approval risk:** accepted physical base quantity × authoritative price per base UOM; official cost first, otherwise versioned source price + FX.
6. **Receipt date:** server tenant business date is read-only; source document date is separate.
7. **LOT dates:** HSD/NSX preserve DAY/MONTH/YEAR precision; consistent higher precision may enrich with audit; conflict blocks.
8. **Approval evidence:** approver can preview immutable evidence and sees sender/submitted time plus aggregate risk when permitted.
9. **Safe source change:** changing source after entered receipt data requires explicit confirmation/reset; Quick Supplier change invalidates dependent evidence/ownership/price basis.
10. **Zero impact:** Document receipt can close with no stock increase; Quick cannot submit when accepted physical quantity is zero.
11. **Quick capability:** hidden without permission; temporary blocker is a disabled Navigation Row with a clear helper.

## UX / content cleanup

- Warehouse and receipt business date use read-only facts rather than a disabled selector/date picker.
- Supplier identity uses name + code; no phone-number noise in the picker.
- Generic Quick note was removed.
- Product+UOM counts use `mặt hàng` rather than ambiguous `sản phẩm` wording where appropriate.
- Approval uses `Người gửi` + `Gửi lúc` rather than an ambiguous maker timestamp.
- `Từ chối` explicitly states `không vào tồn`.
- Result copy distinguishes accepted physical stock from sellable/valuation status.
- User-facing English leakage found in fresh-eye QA was removed.
- LOT date precision controls use the user-facing labels `Cách ghi hạn dùng / Cách ghi ngày sản xuất`.

## Runtime / data hardening

- `sourceExpected` and fixture-only `priceBasisVnd` assumptions were removed from active BJ02 semantics.
- Base-UOM normalization now drives over-source approval and risk calculation.
- Quick evidence/ownership data is structured and version-bound.
- `SCR-010` no longer shows an invalid cross-UOM numeric aggregate.
- UNKNOWN recovery only displays evidence-backed milestones and preserves explicit BJ17 handoff.
- Legacy v3.6.0 review fixture seeding no longer overwrites explicit BJ02 draft data.
- The first mobile precision composition was corrected from overlapping two-column controls to the canonical vertical VSelect + VTextField anatomy.

## Contract / documentation propagation

Updated within the cumulative package:

- BJ02 business journey and UC-02-01…05.
- Decision Register: T7-DR-024, T7-DR-080 and new T7-DR-116…121.
- Shared behavioral contracts, including the Shared Attachment Evidence Contract.
- Data entities/receipt extension for source remainder, ownership assertion, evidence, base-UOM risk and LOT precision.
- UIF-02 and SCR-006/007/008/009/084/010/011/012/013 presentation contracts.
- Screen registry, screen catalog, component usage contracts and workbench data.
- Runtime fixtures, HTML/CSS/JS behavior and QA gates.

## Cross-BJ impact scan

BJ03, BJ05, BJ06, BJ07, BJ09, BJ10 and BJ15 were checked for semantic compatibility. No local journey redesign was required in v3.9.2. Shared Attachment and LOT precision semantics become common authority for later BJ deep reviews.

## QA

- BJ02 Deep Review: **51/51 PASS**, 6 focused captures, 0 browser errors.
- Current package validation: **21/21 PASS**.
- Full Theme End-user regression: **19/19 PASS**.
- Flow & Logic E2E: **21/21 PASS**.
- All-flow runtime smoke: **89/89 PASS**, 0 browser errors.
- Runtime UI: **14/14 PASS**, **518 declared states**.
- Representative coherence: **8/8 PASS**.
- Device frame: **7/7 PASS**, **89 screens checked**.
