# UIF-15 — Component Usage Contract

> **Figma DS migration v2.0.1:** `FIGMA-DS-LOCK.json` / live Figma DS v2.0.2 is the current UI authority. Component names/compositions below are preserved as legacy renderer annotations until Phase 3/4; canonical translation is `../figma-ds/html-figma-ds-mapping.json`. Do not use historical Flutter-DS wording as current authority.

> Status: `PRODUCT_CORRECTED_v1.8.0` · Scope: `BJ-15/UIF-15` · Parent: `v1.7.0` · Figma DS v2.0.2 là UI source of truth; legacy Flutter labels chỉ là migration inputs.

## 1. UX intent

Một entry để chọn **Báo cáo tồn kho** hoặc **Thẻ kho**, giữ scope/date semantics/as-of rõ ràng, cho truy từ số dư → movement → nguồn mà không expose internal pipeline hay tạo mutation.

## 2. Quyết định UX khóa tại v1.8.0

1. Shared `SCR-054..057` tiếp tục canonical; UIF15 dùng flow-specific context mode, không clone.
2. `SCR-054`: `VSegmentedControl` chọn `Tồn kho / Thẻ kho`; `Ngày nghiệp vụ / Ngày ghi nhận` explicit; known scope prefilled.
3. `SCR-055`: report result hoặc stock-card list; không cộng quantity khác UOM thành một total.
4. LOT breakdown dùng contextual `VBottomSheet`; Product NONE không có lô giả.
5. Finance permission độc lập quantity permission; protected official cost/value omitted from DOM.
6. `SCR-056`: business source + before/delta/after; technical IDs chỉ Inspect/audit.
7. `SCR-057`: business evidence timeline; không render operation/event/outbox nodes.
8. `SCR-058`: export keeps exact filter/date/as-of/permission; no approval; as-of read-only; one allowed format does not create a useless selector.
9. `SCR-059`: read-only export result; checksum/hash không phải Product decision.
10. Product viewport `402×874`.

## 3. Component matrix

| Screen | Surface | Context/Composition | Action |
|---|---|---|---|
| `SCR-054` | query form | `REPORT_SCOPE_QUERY` / `Theme7FormSurface` | query navigation |
| `SCR-055` | report/list | `INVENTORY_REPORT_RESULT` or `STOCK_CARD_RESULTS` | contextual drill/export |
| `SCR-056` | detail | `MOVEMENT_DETAIL_BUSINESS` | `Xem nguồn` navigation |
| `SCR-057` | timeline | `BUSINESS_SOURCE_TRACE` | export navigation |
| `SCR-058` | export review | `Theme7ReviewSurface` | `ACT-11-EXPORT` |
| `SCR-059` | result | `Theme7OperationResult` | file handoff/navigation |

## 4. Public DS allowlist

`VPageScaffold`, `VAppBar`, `VPagePadding`, `VSection`, `VSegmentedControl`, `VSelect`, `VCombobox`, `VDatePicker`, `VCard`, `VText`, `VBadge`, `VBanner`, `VButton`, `VSearchBar`, `VBottomSheet`, `VIconBox`, `VSkeleton`, `VEmptyState`, `VLoading`, `VEmptyMedia`, `VEmptyTitle`, `VEmptyDescription`.

## 5. Hard guards

- No mixed-UOM quantity aggregate.
- No fake LOT for NONE tracking.
- No hidden financial data in DOM under restricted permission.
- No technical source pipeline in Product UI.
- No export approval flow unsupported by SRS.
- Stale always shows as-of and never silently becomes current.


## v2.0.2 — Figma DS Phase 3 calibrated expression

This UIF is part of the representative calibration set. The live **Figma Design System v2.0.2** is the UI authority; the older component lists above remain historical migration input only and MUST NOT be used as the current renderer contract.

Current rules:
- Screen shell resolves to the explicit live Mobile template recorded by the runtime mapping.
- `VAppBar` = 56px; mobile content edge = 16px; calibrated page rhythm = 12px where specified by the template.
- Footer actions use `DS v2 / Sticky Footer` (`549:927`) with 92px anatomy and 44px canonical `VButton`.
- Operational navigation/selection rows use `DS v2 / List Row` (`525:519`) rather than a generic clickable `VCard`.
- Read-only facts use `DS v2 / Info Row` (`525:351`) or an explicit token-based `VSection` composition.
- Plain numeric quantity entry uses `VTextField`; `VQuantitySelector` is not a canonical live component and is not used in the calibrated Product renderer.
- State/result surfaces resolve to `Mobile / State` (`551:1746`) where applicable.
- Business behavior, actor handoff, authoritative inputs and UNKNOWN/finality rules are unchanged from the locked Product contracts.

See `../figma-ds/PHASE-3-CALIBRATION-REPORT-v2.0.2.md` for the exact per-screen template mapping and calibration boundary.
