# Changelog v1.4.0 — BJ03/UIF03 Deep Product Correction

Parent: **v1.3.9**.

## Corrected

- `SCR-014`: receipt valuation worklist with search, `Tất cả / Có thể xử lý / Thiếu căn cứ`, explicit no-result, and item/part counts instead of mixed-UOM quantity totals.
- `SCR-015`: Product+UOM identified quantity scope; selected quantity is bounded valuation scope and never edits received quantity; missing-evidence scope is read-only while eligible parts of the same receipt may proceed.
- `SCR-016`: authoritative price/tax/FX evidence is read-only. Valid-source conflict has no preselection and requires explicit source selection + reason. Foreign currency shows original source unit price and approved accounting FX provenance separately.
- Direct cost composition is system-derived from source price, line/document discount, known purchase cost, non-deductible tax and approved FX; late landed cost remains owned by BJ13.
- `SCR-017`: one explicit `Xác nhận giá trị` commit surface; money may aggregate in VND while quantity remains per UOM; value effect is separated from availability/sellability effect; source/version stale blocks commit and shows a business-facing before→after source delta.
- Granular stale recovery preserves unaffected source/reason draft state and reopens only the affected source resolution when required.
- `SCR-019`: COMPLETED / REJECTED_EXECUTION / UNKNOWN / PERMISSION finality; no Back-to-consumed-commit; rejected execution returns to provenance review; UNKNOWN has no blind retry.
- User-facing copy removes technical `value movement`/UI jargon from Product surfaces.
- UIF03 visual composition now reuses the shared read-card/meta-row/result anatomy with all v1.4.0 CSS scoped to `body[data-active-uif="UIF-03"]`; interactive controls meet the 44 px target.

## Protected

- No BJ03/UC03/business-decision/behavioral-contract source file is changed; the correction implements rules already present in BJ03, UC03 and BC-IV-01.
- UIF13 is **not** deep-corrected in v1.4.0. Shared screens `SCR-014/015/017/019` and `SCR-018` render byte/text-equivalent to the v1.3.9 parent when active flow is UIF13.
- BJ05 v1.3.7, BJ06 v1.3.8 and BJ07 v1.3.9 remain protected regression baselines.
