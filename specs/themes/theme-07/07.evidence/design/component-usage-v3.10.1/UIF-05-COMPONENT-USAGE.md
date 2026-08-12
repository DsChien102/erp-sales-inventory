# UIF-05 — Component Usage v1.3.7

> **Figma DS migration v2.0.1:** `FIGMA-DS-LOCK.json` / live Figma DS v2.0.2 is the current UI authority. Component names/compositions below are preserved as legacy renderer annotations until Phase 3/4; canonical translation is `../figma-ds/html-figma-ds-mapping.json`. Do not use historical Flutter-DS wording as current authority.

Live Figma Design System is the UI authority. HTML is a renderer/workbench only; historical Flutter-DS component lists below are migration history, not current UI authority.

| Surface | Canonical DS composition | Theme composition / rule |
|---|---|---|
| SCR-025 Queue | `VPageScaffold`, `VAppBar`, `VPagePadding`, `VSearchBar`, `VChip`, `VCard`, `VText`, `VBadge`, `VIcon`, `VEmptyState` | `InventoryTaskQueue`; default chip `Tất cả`; chips are filters, not tabs |
| SCR-026 Pick overview | `VCard`, `VText`, `VBadge`, `VBanner`, `VButton` | `PickOrderOverview`; order-scoped lines; stale physical correction blocks handover; source-waiting rows are read-only without item navigation affordance |
| SCR-027 Pick item | `VCard`, `VQuantitySelector`, `VButton`, `VBottomSheet`, `VTextFormField`, `VBanner` | `PickLotAllocation`; 1..N LOT allocations; override never preserves invalid old picked evidence |
| Override LOT sheet | `VBottomSheet`, `VText`, `VTextFormField`, `VButton` | Alternative row shows LOT + expiry + available quantity; no preselected alternative; backdrop closes only on actual backdrop click |
| SCR-028 Handover review | `VCard`, `VText`, `VQuantitySelector`, `VButton`, `VBanner` only for abnormal state | `ActualHandoverReview`; only picked allocations render; summary uses product-count scope while actual quantities stay per Product/UOM/LOT; no cross-UOM numeric aggregation |
| SCR-029 Result | `VEmptyState`, `VCard`, `VText`, `VButton`, optional `VBanner` | `OperationResult`; no Back to commit screen; state-specific CTA |

## Interaction constraints

- Queue data must be scoped by Order/Fulfillment.
- Physical correction invalidates affected picked quantity until user repicks.
- `VQuantitySelector` semantics require mobile-appropriate numeric interaction; raw browser spinner is not the intended visual contract.
- Normal rules are helper text; banners are reserved for blocker/warning/recovery states.
- Result state must never collapse `REJECTED_EXECUTION`/`PERMISSION_DENIED` into success.

## v1.4.1 — UX correction
- `SCR-025` WAITING/source-owned card is a true read-only row: one metadata line, concise badge, no chevron/click.
- Overview does not duplicate numeric progress with routine progress badges; LOT helper stays compact.
- Normal handover rules use quiet helper/footnote; exception banners remain semantic.


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


## v2.7.0 — Current renderer contract

| Surface | Current Figma DS expression | Product rule preserved |
|---|---|---|
| SCR-025 Queue | `VSearchBar` (`522:7245`) + `VChip` (`522:7449`) + `DS v2 / List Row` (`525:519`) + `VBadge` | Default `Tất cả`; one Navigation/Default-density collection; source-waiting row uses Disabled state and cannot navigate |
| SCR-026 Pick overview | `DS v2 / Info Row` (`525:351`) + `DS v2 / List Row` (`525:519`) + abnormal `VBanner` | Order scoped; numeric picked/remaining primary; stale correction blocks review; shortage is read-only |
| SCR-027 Pick item | `VTextField` (`522:7186`) + `DS v2 / Link` (`4431:10396`) + `VBanner`; override composes `DS v2 / Form Sheet` (`1353:6355`) from `List Row/Selection`, `VRadio`, `VTextarea`, `VButton` | 1..N allocations; no LOT preselection; reason required; changed/stale LOT invalidates old picked evidence and requires repick |
| SCR-028 Handover review | `Info Row` + `Key-value Row` (`525:358`) + `VTextField` + abnormal `VBanner` + Sticky Footer | Only `picked > 0`; per-allocation actual handover; mixed UOM never numerically aggregated; normal rule remains quiet helper |
| SCR-029 Result | result composition from `VIcon`, `VText`, `Info Row`, read-only `List Row`, `VButton` | Distinct terminal outcomes; no Back to commit; full/partial lifecycle mutates fixture; UNKNOWN has no blind retry |

### Explicit removals from the active BJ05 renderer

- Generic clickable `VCard` is not used as a substitute for `List Row`.
- `VQuantitySelector` is not used; plain quantity entry uses `VTextField`.
- `VTextFormField` is not used for override reason; canonical Figma `VTextarea` is used.
- Success result is not rendered as a synthetic `VEmptyState`.
- Entry/actor-handoff explanation that does not change an in-screen decision is kept in flow/contract/inspect rather than added as helper cards or banners.

## v2.7.1 — Live primitive correction

- `DS v2 / List Row` (`525:519`): v2.7.1 locked exact geometry by variant (`Default 370×76`, `Compact 370×52`). The earlier waiting-row Type choice is superseded by the v2.7.3 same-collection rule below.
- `DS v2 / Info Row` (`525:351`): each row stays transparent `338×44`; multiple facts are composed inside the established `370px` information surface with `16px` inset and `12px` radius. The grouping is a composition, not a new Theme component.
- `DS v2 / Key-value Row` (`525:358`): BJ05 handover summary uses the shared helper. Default is `338×44`; Emphasis keeps the `12px` horizontal inset, `8px` radius and brand surface/typography.
- `VToast` (`526:4305`): shared renderer is canonical `370×56`, dark surface, `8px` radius, semantic circular leading icon and plain close icon. Toast type is semantic (`success / warning / danger / info`), not inferred from a legacy icon argument.
- These changes are visual/DS corrections only; allocation, pick, LOT invalidation, handover commit boundary and finality rules are unchanged from v2.7.0.

## v2.7.3 — Cross-BJ UI hardening

- `SCR-025` is one Navigation collection: all Order rows use `DS v2 / List Row 525:519`, `Type=Navigation`, `Density=Default`, `370×76`. Waiting Orders use `State=Disabled`; they keep the same chevron/anatomy and are non-interactive via the DS disabled state.
- `SCR-026` uses the same rule for Product+UOM task rows; waiting/completed rows become Disabled Navigation peers instead of changing component Type.
- `SCR-027` Product+UOM context uses `List Row / Status / Compact` (`370×52`) with `Còn N UOM`; no sparse fixed-height Summary Card.
- `Summary Card 525:552` is reserved for a real compact narrative/decision summary. Component choice is semantic; blank space must never be filled with unnecessary information merely to satisfy a specimen height.
- Cross-theme Product UI is a mandatory composition reference after canonical DS/Patterns review. Use it to keep VET45 grouping/rhythm consistent, without copying legacy deviations from DS.

### v2.7.4 Figma DS hard gate

`Chọn lô thay thế` must use live `DS v2 / Form Sheet` (`1353:6355`) without custom geometry: 402×764, handle area 24, header 44, intro 40, canonical field region, and Sticky Footer 92. Field/action primitives are `DS v2 / List Row`, `VRadio`, `VTextarea` (`522:7212`), `DS v2 / Icon Button` (`4431:10317`), and `VButton` (`521:529`). Disabled Primary uses `Opacity/Disabled=0.4`; no separate disabled color is allowed.

## v2.7.5 — Current overlay and handover composition

- LOT replacement: `VBottomSheet` (`4695:6353`) + `DS v2 / List Row` Selection + `VRadio` + `VTextarea` + one Primary `VButton`. Normal VBottomSheet has no top-right close CTA; `DS v2 / Form Sheet` is no longer used for this interaction.
- `SCR-028`: grouped Product/UOM information surface containing allocation blocks; each allocation uses canonical VTextField/Info Row. The surface is content-driven and must not clip or overflow at 402px.
- Typography for every Product screen uses the Figma sans token stack; form controls inherit the same stack.


## v2.8.2 — SCR-027 multi-LOT density

`SCR-027` uses `List Row (Navigation, Default)` as the scalable LOT overview. Quantity editing is contextual in canonical `VBottomSheet`; do not render one full `VTextField` block per LOT in the page. This preserves standard 76px row anatomy and keeps large allocation sets scannable.

## v2.9.2 — Handover Product-group hardening
- `SCR-028` Product+UOM identity now uses canonical `List Row / Status / Compact` inside the existing grouped surface. Allocation LOT quantity uses `Key-value Row`; editable actual handover remains `VTextField`.
- The former ad-hoc product header (`text + optional badge`) is retired.

## v2.9.3 — DS-native grouped collection correction

- Supersedes the v2.9.2 per-Product outer handover surface in `SCR-028`.
- The whole homogeneous handover collection owns **one** Layout `Grouped surface` reference (`4518:1545`); repeated Product+UOM groups are layout subgroups, not independent cards.
- Product+UOM remains the canonical `DS v2 / List Row` (`525:519`), `Type=Status`, `Density=Compact`, exact `370×52`. Its trailing `VBadge` is semantic (`Đã lấy`), never a raw quantity.
- Allocation evidence uses `DS v2 / Key-value Row` (`525:358`); `VTextField` appears only when actual handover is editable. Read-only state does not duplicate the same quantity in a second Info Row.
- This release follows the Figma Layout rule “use the lightest surface treatment” and the explicit anti-pattern “Card soup”. Business behavior and commit boundaries are unchanged.
