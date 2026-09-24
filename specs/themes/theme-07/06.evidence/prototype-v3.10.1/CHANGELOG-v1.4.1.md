# CHANGELOG — v1.4.1

Parent: **v1.4.0**  
Scope: **Inventory Operations holistic Product UX correction**.

## Changed

- UIF01: concise inventory status/context/attention copy.
- UIF02: system-owned warehouse field is true read-only; Product discovery removes tracking-policy noise; derived-total helper duplication removed.
- UIF04: normal successful reservation no longer emits persistent success banner; exception-only feedback hierarchy.
- UIF05: source-owned waiting queue cards are truly read-only; compact LOT/progress/review/result communication.
- UIF06: approval-owned waiting queue cards are truly read-only; reduced normal-state badge noise; technical approval IDs hidden from Product UI.
- UIF07: compact supplier-return queue cards, including Product-reported waiting-card correction; reduced allocation/review/result information noise.

## Not changed

- No SRS/business rule/lifecycle/commit change.
- No new screen or active-flow transition.
- `SCR-038` remains outside active UIF07.
- UIF03/BJ03 valuation design from v1.4.0 is protected by exact text/pixel regression.

## QA

- End-user/state: 137/137 PASS.
- Runtime all-flow smoke: 87 renders PASS.
- Visual: 43/43 checks, 21 specimens at 402×874 PASS.
- UIF03 regression: 15/15 PASS.
- Static/contract conformance: 85/85 PASS.
- Isolation: 13/13 PASS; 36 parent files modified in declared UX scope, 36 files added, 0 removed.

QA PASS is not Product approval.
