# UIF-14 — Component Usage v1.5.0

> **Figma DS migration v2.0.1:** `FIGMA-DS-LOCK.json` / live Figma DS v2.0.2 is the current UI authority. Component names/compositions below are preserved as legacy renderer annotations until Phase 3/4; canonical translation is `../figma-ds/html-figma-ds-mapping.json`. Do not use historical Flutter-DS wording as current authority.

Active screens: SCR-072, SCR-073, SCR-074, SCR-076, SCR-077.

- App shell: `VPageScaffold + VAppBar(center=false) + VPagePadding + sticky action area` where action exists.
- Lists/tasks: `VSearchBar`, `VCard`, `VBadge`, `VEmptyState`; waiting rows are read-only.
- Forms: `VSelect`/`VTextFormField` only for facts the user owns. System/policy facts remain read-only.
- Review: business facts first; one commit action, no confirmation modal.
- Result: `VEmptyState` grammar; no Back to consumed commit; UNKNOWN no retry.
- Contextual detail: `VBottomSheet` only when supporting the current decision; no navigation route for explanatory detail.
- Financial permission: protected values omitted from DOM when not authorized.
- Product viewport: 402×874, touch targets >=44 px, no horizontal overflow.
