# UIF-09 — Component Usage Contract

> **Figma DS migration v2.0.1:** `FIGMA-DS-LOCK.json` / live Figma DS v2.0.2 is the current UI authority. Component names/compositions below are preserved as legacy renderer annotations until Phase 3/4; canonical translation is `../figma-ds/html-figma-ds-mapping.json`. Do not use historical Flutter-DS wording as current authority.

> Status: `PRODUCT_CORRECTED_v1.6.0` · Scope: `BJ-09/UIF-09` · Figma DS v2.0.2 is UI authority; legacy Flutter labels are migration inputs only.

## Product rules

- Product language is “Tình trạng hàng”; show normal `Bán được` beside exception states.
- Expiry is derived, not a user action. Generic destinations are whitelisted business states only.
- `SCR-038` maker/approver modes are mutually exclusive; no visible Save Draft. `ACT-08-STATE` is system-owned/trace-only after approval.
- Stock-count lock produces true read-only. State movement preserves total physical quantity and value.
- UNKNOWN keeps same operation identity.

## Screen matrix

| Screen | Surface | Visible action(s) |
|---|---|---|
| `SCR-036` | list | none |
| `SCR-037` | detail | contextual “Thay đổi tình trạng”; history |
| `SCR-038` | form/review by mode | `ACT-COMMON-SUBMIT` or `ACT-COMMON-DECIDE` |
| `SCR-041` | result | none; `ACT-08-STATE` trace-only |
| `SCR-056` | history | none |

Components: `VPageScaffold`, `VAppBar(centerTitle=false)`, `VPagePadding`, `VSearchBar`, `VChip`, `VCard`, `VBadge`, `VText`, `VRadio`, `VTextField`, `VBanner`, `VButton`, `VEmptyState`, `VSkeleton`, `VLoading`.


## v3.10.1 BJ09 contract correction
- Policy source: immutable `StateTransitionPolicyVersion`; UI chỉ render destination/requirement do policy server-authoritative cung cấp, không hard-code policy như business authority.
- Submit khóa immutable `StateChangeBasis`; exact source valuation slices, policy hash/version và reservation-impact là contract/Inspect/audit facts, không phải user choices.
- Approver xem và quyết định trên đúng `StateChangeBasis`; approval không tự ghi tồn, system executor recheck trước commit.
- Current state: read-only `VInfoRow`/text composition, server authoritative.
- Destination: `VRadio/VChoiceList` from server policy; canonical `DEMO` label **Dùng thử**.
- Partial quantity: `VNumberField`; source valuation slices are contract-only, never user choices.
- Approval: separate actor task; `ACT-COMMON-DECIDE` only. `ACT-08-STATE` is system trace-only.
- Reject reason uses field + validation; basis stale uses persistent `VBanner`, not toast.
