# Inventory Operations Design Review — v1.3.4

## Scope
BJ-02 correction + full design pass for BJ-04, BJ-05, BJ-06, BJ-07, based on Phase-A control decisions and Flutter Design System authority. BJ-01 is protected from v0.3.4.

## Canonical active architecture

| BJ | Active UI | Control model |
|---|---|---|
| BJ-04 | `SCR-021` reservation projection | Source/system-driven; no manual reservation workflow |
| BJ-05 | `SCR-025 → 026 ⇄ 027 → 028 → 029` | Normal no approval; LOT override permission+reason |
| BJ-06 | `SCR-030 → 031 ⇄ 032 → 035 → 033 → 035`, with separate `SCR-034` approver handoff | Wrong LOT always maker-checker; normal classification no approval + hard guards |
| BJ-07 | `SCR-036 → 037 → 039 → 041` | Source-authorized; no second commercial approval |

## BJ-02 correction
`SCR-084` no longer asks the user to enter a total quantity in addition to four classifications. The four classification quantities are authoritative; total actual is derived.

## End-user principles applied
- No technical allocation/reservation version as user task.
- System-owned work is not exposed as manual CTA.
- Search is available at the task entry/list where it reduces navigation.
- One irreversible commit is reviewed at the physical handover/receipt boundary.
- Approval is a true actor handoff, not a mode switch in the maker's wizard.
- No invented evidence/recipient fields beyond business source.
- UNKNOWN never implies blind retry.
- Technical statuses/IDs remain in Inspect/contracts, not Product UI.

## Design status
Ready for Product review subject to QA reports in `prototype/html/qa/`. QA pass validates implementation/conformance, not Product approval.
