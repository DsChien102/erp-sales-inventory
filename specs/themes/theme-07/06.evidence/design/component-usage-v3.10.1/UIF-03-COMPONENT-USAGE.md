# UIF-03 — Component Usage v1.5.0

> **Figma DS migration v2.0.1:** `FIGMA-DS-LOCK.json` / live Figma DS v2.0.2 is the current UI authority. Component names/compositions below are preserved as legacy renderer annotations until Phase 3/4; canonical translation is `../figma-ds/html-figma-ds-mapping.json`. Do not use historical Flutter-DS wording as current authority.

Active screens: SCR-014, SCR-015, SCR-017, SCR-019.

- App shell: `VPageScaffold + VAppBar(center=false) + VPagePadding + sticky action area` where action exists.
- Lists/tasks: `VSearchBar`, `DS v2 / List Row`, `VBadge`, `VEmptyState`. Peer task/destination rows use one homogeneous `Navigation` collection; waiting/unavailable peers use `State=Disabled`, keep the same chevron/anatomy, and are non-interactive.
- Forms: `VSelect`/`VTextFormField` only for facts the user owns. System/policy facts remain read-only.
- Review: business facts first; transaction-UOM direct cost + normalized base-UOM consequence; one commit action, no confirmation modal or normal-state “Sẵn sàng” badge.
- Result: `VEmptyState` grammar; no Back to consumed commit; UNKNOWN no retry.
- Contextual detail: `VBottomSheet` for complete DirectCostBasis/provenance/conflict only when supporting the current decision; no navigation route for explanatory detail.
- Financial permission: protected values omitted from DOM when not authorized.
- Product viewport: 402×874, touch targets >=44 px, no horizontal overflow.
