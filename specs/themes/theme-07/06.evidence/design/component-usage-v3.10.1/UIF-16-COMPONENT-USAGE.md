# UIF-16 — Component Usage Contract

> **Figma DS migration v2.0.1:** `FIGMA-DS-LOCK.json` / live Figma DS v2.0.2 is the current UI authority. Component names/compositions below are preserved as legacy renderer annotations until Phase 3/4; canonical translation is `../figma-ds/html-figma-ds-mapping.json`. Do not use historical Flutter-DS wording as current authority.

> Status: `PRODUCT_CORRECTED_v1.7.0` · Scope: `BJ-16/UIF-16` · Figma DS v2.0.2 is UI authority; legacy Flutter labels are migration inputs only.

## Product rules

1. Evidence is user-readable (`Nguồn nghiệp vụ / Sổ kho / Số liệu hiển thị`), not a log console.
2. UI never offers a generic technical selector for replay/rebuild/source.
3. Projection recovery is available only when ledger correctness is already proven.
4. Correction routes to BJ-11; UNKNOWN routes to BJ-17; source mismatch routes to source owner.
5. Ledger-integrity suspicion stops auto recovery and shows controlled escalation.
6. Close/unlock only after evidence proves resolution; otherwise case remains open/protected.

## Screen matrix

| Screen | Surface | Product role |
|---|---|---|
| `SCR-078` | case worklist | search/filter/triage |
| `SCR-079` | evidence + conclusion | decision + route |
| `SCR-080` | controlled plan | read-only recommended projection recovery + start |
| `SCR-081` | progress | system progress; no mutation choice |
| `SCR-082` | review | compare meaningful facts + close/unlock |
| `SCR-083` | result | resolved or escalated authoritative outcome |

Components: `VPageScaffold`, `VAppBar(centerTitle=false)`, `VSearchBar`, `VChip`, `VCard`, `VBadge`, `VText`, `VBanner`, `VButton`, `VEmptyState`, `VSkeleton`, `VLoading`.
