# UIF-11 — Component Usage Contract

> **Figma DS migration v2.0.1:** `FIGMA-DS-LOCK.json` / live Figma DS v2.0.2 is the current UI authority. Component names/compositions below are preserved as legacy renderer annotations until Phase 3/4; canonical translation is `../figma-ds/html-figma-ds-mapping.json`. Do not use historical Flutter-DS wording as current authority.

> Status: `PRODUCT_CORRECTED_v1.7.0` · Scope: `BJ-11/UIF-11` · Figma DS v2.0.2 is UI authority; legacy Flutter labels are migration inputs only.

## Product rules

1. `SCR-048` is a control worklist, not a technical operation registry.
2. `SCR-049` shows business identity/impact first; technical hash/version belongs to Inspect/on-demand.
3. `SCR-052` has mutually exclusive `CANCEL_UNEXECUTED` and `CORRECTION_ROUTE` mental tasks.
4. `SCR-050` has one authoritative “Số đúng”; delta is derived. Draft persistence is background/trace-only — **no Save Draft CTA**.
5. Maker submit ends maker task at `SCR-053:PENDING_APPROVAL`; `SCR-051` is a separate actor entry.
6. Approve triggers system execution; no second maker commit. UNKNOWN handoff uses BJ-17 and same operation identity.

## Screen matrix

| Screen | Surface | Visible action(s) |
|---|---|---|
| `SCR-048` | worklist | navigation only |
| `SCR-049` | detail | `Hủy yêu cầu` / `Sửa sai` / `Xác minh kết quả` contextually |
| `SCR-052` | confirmation/route | `ACT-10-CANCEL` only in cancel mode; correction strategy is navigation decision |
| `SCR-050` | correction editor | `ACT-10-SUBMIT`; `ACT-10-SAVE-DRAFT` trace-only |
| `SCR-051` | independent approval | `ACT-10-DECIDE` |
| `SCR-053` | authoritative result | navigation/handoff only; `ACT-10-CORRECT` system-owned |

Components: `VPageScaffold`, `VAppBar(centerTitle=false)`, `VPagePadding`, `VSection`, `VSearchBar`, `VChip`, `VCard`, `VBadge`, `VText`, `VNumberField`, `VTextField`, `VRadio`, `VBanner`, `VButton`, `VBottomSheet`, `VEmptyState`, `VSkeleton`, `VLoading`.
