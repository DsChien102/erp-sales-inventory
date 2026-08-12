# Theme 7 Prototype Harness — Final 17-Round Report

> **HISTORICAL LEDGER + CURRENT CUMULATIVE STATUS.** The round ledger below preserves earlier Harness history. The current cumulative Product candidate is **v2.1.1**, built directly on **v2.1.0**. Product approval remains **PENDING_REVIEW**.

## Current cumulative candidate — v2.1.1

- Scope: **Phase 5 final Figma DS conformance + holistic end-user hardening** across **17 UIF · 73 distinct canonical active screens · 497 registered state renders**.
- Business/behavior, screen registry and topology remain frozen; no BJ redesign is introduced.
- Result/status/validation business screens use `Mobile / Detail` as their base archetype; `Mobile / State` is reserved for actual full-content Empty/Error/No Permission/Blocked/No Result states.
- Success/finality no longer borrows `VEmptyState` owned slots. Exact `DS v2 / Info Row`, `VTextarea`, and `VMoneyField` responsibilities are enforced.
- Release gates: Phase 5 conformance **29/29 · 497**, focused end-user QA **16/16**, visual **67 specimens · 17/17 UIF**, active-flow smoke **85/85** — PASS.
- Mapping resolution covers **10,600 annotations** with no active debt/error status; dynamic State-template use is **83 renders**, all true centered `VEmptyState`.
- Frozen **106 SRS files**, canonical screen registry and `theme.manifest.yaml` are byte-identical to exact parent v2.1.0.
- Prior business suites remain stable. Two legacy assertion suites carry the same inherited failures as parent (Inventory Operations 126/137; Correction/Recovery 67/68) and are not falsely reported as green.
- `QA PASS != Product approval`; current Product approval remains **PENDING_REVIEW**.

## 1. Final result

- **17/17** UIF: `FROZEN`.
- **17/17** local reviews: `PASS`.
- **17/17** cumulative reviews: `PASS`.
- **205** active UI transitions after Harness corrections.
- **79** canonical Screens participate in the 17 Business Journeys.
- **17** of those Screens are shared by more than one UIF and keep one canonical implementation.
- **4** additional CAP-01 supporting Screens (`SCR-062..065`) remain outside the 17-BJ run; they are retained in `contracts/screens/` and are not counted as a Journey round.
- **17** component-usage contracts `.md` + **17** machine contracts `.yaml`.
- **Current authority update:** live Figma Design System v2.0.2 is the UI authority; HTML is a renderer/workbench. The older Flutter-authority wording belongs only to historical releases.

## 2. Round ledger

| Round | UIF | BJ | Screens | Transitions | Status | Cumulative |
|---:|---|---|---:|---:|---|---|
| 01 | UIF-02 | BJ-02 | 8 | 18 | FROZEN | PASS |
| 02 | UIF-01 | BJ-01 | 11 | 20 | FROZEN | PASS |
| 03 | UIF-03 | BJ-03 | 5 | 9 | FROZEN | PASS |
| 04 | UIF-13 | BJ-13 | 5 | 10 | FROZEN | PASS |
| 05 | UIF-04 | BJ-04 | 5 | 10 | FROZEN | PASS |
| 06 | UIF-05 | BJ-05 | 5 | 11 | FROZEN | PASS |
| 07 | UIF-06 | BJ-06 | 6 | 10 | FROZEN | PASS |
| 08 | UIF-07 | BJ-07 | 5 | 11 | FROZEN | PASS |
| 09 | UIF-09 | BJ-09 | 5 | 14 | FROZEN | PASS |
| 10 | UIF-10 | BJ-10 | 4 | 10 | FROZEN | PASS |
| 11 | UIF-08 | BJ-08 | 6 | 13 | FROZEN | PASS |
| 12 | UIF-11 | BJ-11 | 6 | 14 | FROZEN | PASS |
| 13 | UIF-12 | BJ-12 | 6 | 11 | FROZEN | PASS |
| 14 | UIF-14 | BJ-14 | 6 | 10 | FROZEN | PASS |
| 15 | UIF-15 | BJ-15 | 6 | 11 | FROZEN | PASS |
| 16 | UIF-16 | BJ-16 | 6 | 13 | FROZEN | PASS |
| 17 | UIF-17 | BJ-17 | 5 | 10 | FROZEN | PASS |

## 3. Structural / UX corrections discovered

1. **UIF-01:** inserted shared `SCR-055` between query `SCR-054` and movement detail `SCR-056`; a query form no longer pretends to own a list of movements.
2. **UIF-02:** approval is an actor handoff; only Approve/Reject remain; reject reason is mandatory; receiving executes automatically and `SCR-012` owns processing/result.
3. **UIF-03:** removed “đưa vào bán” semantics from valuation. Valuation confirms value; sellability remains owned by current inventory state/policy.
4. **UIF-13:** moved late-cost final confirmation to `SCR-017`; removed review → form → submit backtracking.
5. **UIF-05:** `ACT-06-SAVE-PICK` is persistence behind the user’s Continue/save intent, not a separate mental step.
6. **UIF-06:** changed continuation wording to “Tiếp tục phân loại”; physical receipt and later quality classification remain separate tasks.
7. **UIF-09:** maker submit, approver decision and state movement are distinct contracts; the movement is system-owned after approval.
8. **UIF-10:** `SCR-040` has mutually exclusive PREPARE / APPROVAL / COMPLETION modes; approval never decrements physical inventory.
9. **UIF-08:** blind count does not render book quantity in the DOM before first submission; approval is a separate actor task.
10. **UIF-11:** after approval, correction chain executes automatically; the user is not sent back to commit again.
11. **UIF-12:** opening-balance approval is separated from authoritative commit; commit executes automatically on result processing.
12. **UIF-15:** report/stock-card query reuses the canonical UIF-01 query/list/detail/timeline family and keeps as-of/cut-off visible.
13. **UIF-16/17:** recovery is evidence-first, no direct ledger edit, no blind retry, and continuation preserves the original operation identity.

## 4. Cumulative UX invariants

- **Don’t make me think:** prefill known context, do not ask users to decide what the system already knows, remove redundant taps/inputs, and preserve safe context on back/recovery.
- One Screen = one mental task. Technical polling/outbox/retry/version mechanics do not become user-facing steps.
- Shared Screen = one canonical implementation + context mode; no copied versions per BJ.
- Maker/approver tasks do not share an artificial session; handoff and resume preserve object/version.
- Review screens prioritize differences, risk, blockers and routing before repeated source details.
- Result screens own processing/finality; a toast never replaces an authoritative result.
- `UNKNOWN` is neither success nor failure. Use evidence/reconciliation and the same operation identity.
- Permission masking occurs before DOM render.
- App shell uses `VPageScaffold → VAppBar`, `centerTitle=false`, no trailing action unless explicitly owned.
- Icons/components/patterns/templates resolve through the live Figma DS registry; historical Flutter naming is trace/provenance only.

## 5. Validation

- Harness structural / contract / HTML validation: **155/155 PASS**.
- JavaScript syntax: PASS (`node --check`).
- Relative Markdown link integrity: PASS.
- Active legacy path references: none.
- Headless Chromium visual execution is blocked in the current container by Chromium/DBus/zygote runtime; therefore pixel regression against the Vercel Flutter render remains a **separate visual gate**, not falsely marked PASS here.

## 6. Canonical artifacts

- `HARNESS-STATUS.yaml` — 17-round state.
- `reviews/LOCAL-REVIEW-UIF-xx.md` — local review for each round.
- `reviews/CUMULATIVE-REVIEW-UIF-xx.md` — cumulative regression for each round.
- `contracts/component-usage/` — UIF-specific MD/YAML usage contracts.
- `contracts/screens/` — canonical Screen Design Contracts.
- `contracts/UX-PATTERN-REGISTRY.md` — promoted UX patterns.
- `contracts/CROSS-UIF-DECISIONS.md` — cumulative design decisions.
- `html/` — one common workbench with flow selector, state switcher and Inspect mode.
