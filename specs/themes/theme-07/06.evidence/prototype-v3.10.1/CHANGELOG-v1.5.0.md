# Changelog v1.5.0 — Inventory Valuation Group Product Correction

Parent: **v1.4.5**. Product approval: **PENDING**.

## Scope

- BJ03/UIF03: remove architecture explanation UI; linearize happy path; move provenance/conflict/cost detail to contextual Bottom Sheet; retain exact valuation scope, partial identity, preview/commit separation and safe finality.
- BJ13/UIF13: simplify normal-state copy, preserve dedicated late-cost screens and foundation; one linear edit path; no BJ/internal architecture wording in Product UI.
- BJ14/UIF14: deep Product design using immutable cost-run lifecycle; blocker/calculation as run states; system-policy publish method; successor on changed input; atomic publish; no pricing mutation.

## Active topologies

- UIF03: `SCR-014 → SCR-015 → SCR-017 → SCR-019` (`SCR-016` retired active route).
- UIF13: `SCR-085 → SCR-086 → SCR-087 → SCR-088 → SCR-089`.
- UIF14: `SCR-072 → SCR-073 → SCR-074 → SCR-076 → SCR-077` (`SCR-075` retired active route).

## Product UX guardrail

Architecture-only context (entry point, upstream/downstream BJ, actor handoff, orchestration) belongs in contracts/Inspect and is not rendered by default. Product UI only exposes context required for the current decision.
