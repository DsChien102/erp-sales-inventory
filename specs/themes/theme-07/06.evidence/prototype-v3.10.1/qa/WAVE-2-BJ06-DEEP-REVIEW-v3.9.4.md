# Wave 2 — BJ06 Deep Review Closure — v3.9.4

**Journey:** BJ06 — Khách trả hàng  
**Baseline reviewed:** v3.9.3  
**Result:** Deep-Reviewed / Lock candidate  
**Authority:** cumulative Prototype Harness only; frozen-source preserved as history.

## Closure summary

BJ06 was re-reviewed from commercial return authorization through physical receipt, wrong-LOT approval, inventory classification, result finality and UNKNOWN recovery. The key correction is to keep three truths separate:

`Theme 5 commercial return intent ≠ Theme 7 physical receipt ≠ Theme 7 inventory disposition`.

The approved Decision Pack is now represented consistently in business rules, data contracts, screen contracts, Inspect/workbench data and runtime behavior.

## Locked semantics

- Current Theme 5 ReturnExchangeLine authorization is the receipt upper bound; physical partial receipt is valid.
- Declared return condition is read-only context; it never prefills inventory classification.
- Existing/new LOT resolution is explicit and data-integrity conflicts cannot be approved away.
- Wrong-LOT approval is a `LINE_EXCEPTION` subject bound to immutable line/LOT/reason/evidence content.
- Multiple wrong-LOT lines may be awaiting approval in the same receipt operation.
- `EXPIRED` is system-derived for the whole line; user edits only Sellable/Quarantine/Damaged on non-expired lines.
- Result uses source request/SalesOrder and `recorded_at` / `classified_at`; no synthetic receipt identity is created.
- UNKNOWN preserves exact operation identity, disables blind retry and hands finality to BJ17.

## Fresh-eye corrections completed

During implementation QA, two runtime integration issues were corrected before closure:

1. The wrong-LOT evidence section/footer now becomes available immediately after the user chooses **Lô khác**, instead of waiting for an unrelated rerender.
2. Content hashing now has an offline-safe deterministic fallback when Web Crypto is unavailable, while retaining SHA-256 in secure contexts.

## Validation

| Gate | Result |
|---|---|
| BJ06 Deep Review | **40/40 PASS** |
| Prior locked BJ regression — BJ01/BJ02/BJ05 | **8/8 PASS** |
| Frozen-source immutability | **PASS** |
| Current package validation | **26/26 PASS** |
| Full Theme End-user regression | **19/19 PASS** |
| Flow & Logic E2E | **21/21 PASS** |
| All-flow runtime smoke | **89/89 PASS** |
| Runtime UI | **14/14 PASS; 518 states** |
| Representative coherence | **8/8 PASS** |
| Device frame | **7/7 PASS; 89 screens** |
| Focused captures | **6 generated** |
| Browser / console errors | **0** |

No remaining **P0/P1 semantic blocker** was found after the approved fixes and fresh-eye pass. BJ06 is therefore a **Deep-Reviewed / Lock candidate** in Wave 2.
