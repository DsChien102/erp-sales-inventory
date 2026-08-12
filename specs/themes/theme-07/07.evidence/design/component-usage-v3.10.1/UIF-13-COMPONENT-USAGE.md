# UIF-13 — Component Usage v3.9.8

> **Figma DS migration v2.0.1:** `FIGMA-DS-LOCK.json` / live Figma DS v2.0.2 is the current UI authority. Component names/compositions below are preserved as legacy renderer annotations until Phase 3/4; canonical translation is `../figma-ds/html-figma-ds-mapping.json`. Do not use historical Flutter-DS wording as current authority.

Active screens: SCR-085, SCR-086, SCR-087, SCR-088, SCR-089.

- App shell: `VPageScaffold + VAppBar(center=false) + VPagePadding + sticky action area` where action exists.
- Lists/tasks: `VSearchBar`, `DS v2 / List Row`, `VBadge`, `VEmptyState`. Peer task/destination rows use one homogeneous `Navigation` collection; waiting/unavailable peers use `State=Disabled`, keep the same chevron/anatomy, and are non-interactive.
- Forms: `VSelect`/`VTextFormField` only for facts the user owns. System/policy facts remain read-only.
- Review: business facts first; one commit action, no confirmation modal.
- Result: `VEmptyState` grammar; no Back to consumed commit; UNKNOWN no retry.
- Contextual detail: `VBottomSheet` only when supporting the current decision; no navigation route for explanatory detail.
- Financial permission: protected values omitted from DOM when not authorized.
- Product viewport: 402×874, touch targets >=44 px, no horizontal overflow.

- BJ13 deep review v3.9.8 keeps the same DS composition; changes are semantic/data hierarchy, not a new visual language.
