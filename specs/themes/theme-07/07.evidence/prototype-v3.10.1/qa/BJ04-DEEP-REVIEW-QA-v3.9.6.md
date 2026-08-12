# BJ04 Deep Review QA — v3.9.6

**Result: PASS · 52/52**

Scope: approved D04-01..D04-06 / T7-DR-144..149, current reservation semantics, BJ04/BJ05 ownership boundary and contextual read-only UI.

- PASS — Approved BJ04 decisions T7-DR-144..149 are registered
- PASS — Reservation capability is explicit NONE/ALL_OR_NOTHING/PARTIAL_ALLOWED
- PASS — BJ04 capability is limited to Advanced Stock and Basic Stock does not create Theme7 reservation
- PASS — Transaction UOM identity and conversion snapshot are preserved
- PASS — Reservation requested quantity is stored in transaction and base semantics
- PASS — reserved_base_quantity is defined as current hold
- PASS — consumed_base_quantity preserves cumulative committed handover history
- PASS — Remaining-required and shortage formulas are explicit
- PASS — ReservationBucket counts current held amount only
- PASS — ALL_OR_NOTHING insufficient capacity leaves bucket unchanged
- PASS — Deterministic reservation priority is priority then source_confirmed_at then stable source_line_id
- PASS — No automatic top-up after capacity returns
- PASS — Source expiry is source-owned with no implicit TTL
- PASS — ReservationGroup entity exists for combo atomicity
- PASS — Combo child reservations carry group identity
- PASS — Combo partial reservation is rounded to complete combo quantity
- PASS — BC-IO-06 is Adjust reservation capacity, not pick-allocation ownership
- PASS — BC-IO-06 does not own active PickAllocation mutation
- PASS — UC05 stale-allocation recovery is owned by BC-IO-15
- PASS — Technical API-C-06 uses reservation adjustments endpoint
- PASS — Technical reservation event carries current held/consumed/shortage facts
- PASS — SCR-021 contract rejects global FULL/PARTIAL/RELEASED/STALE lifecycle states
- PASS — SCR-021 is contextual-only and read-only
- PASS — SCR-021 does not expose the static physical-vs-availability helper
- PASS — UIF-04 flow keeps current facts and per-line lifecycle semantics
- PASS — Canonical registry has exactly three active BJ04 states
- PASS — Workbench defaults BJ04 screen to READY
- PASS — Workbench includes UC-04-03 lifecycle release context
- PASS — Harness BC-IO-06 excludes UC-05-04
- PASS — Harness API-C-06 excludes UC-05-04 and uses adjustments endpoint
- PASS — Runtime prototype identifies v3.9.6
- PASS — BJ04 current projection shows order and warehouse context
- PASS — Consumed line reduces remaining requirement without rewriting consumed history
- PASS — Short line shows current held and shortage facts
- PASS — Combo line projects complete combo quantity instead of component internals
- PASS — Fully consumed line shows handover history and zero current hold
- PASS — Current UI does not show historical global RELEASED copy
- PASS — Current UI omits static domain helper
- PASS — Current UI has no reservation mutation CTA
- PASS — Reservation rows are non-interactive status rows
- PASS — Runtime fixtures preserve UOM snapshots and conversion versions
- PASS — Runtime fixtures separate current reserved from consumed quantity
- PASS — Runtime fixtures carry deterministic priority inputs
- PASS — Runtime combo fixture carries ReservationGroup and component definition
- PASS — Legacy global RELEASED state safely renders current facts rather than legacy released screen
- PASS — All-terminal reservation projection shows concise no-current-hold information
- PASS — All-terminal projection does not resurrect historical requested quantities as active needs
- PASS — BJ04 LOADING state uses canonical loading surface
- PASS — BJ04 permission state is non-mutating blocked surface
- PASS — Warehouse function catalog marks BJ04 as contextual-only
- PASS — Focused BJ04 browser has no page errors
- PASS — Focused BJ04 browser has no console errors

## Visual captures
- `01-SCR021-READY-CURRENT-PROJECTION.png` — BJ04 READY — current reservation facts by source line, including combo and consumed history
- `02-SCR021-NO-CURRENT-HOLD.png` — BJ04 all terminal — concise information instead of global RELEASED history dump
- `03-SCR021-PERMISSION-DENIED.png` — BJ04 permission boundary
- `04-FUNCTION-CATALOG-BJ04-CONTEXTUAL.png` — Warehouse catalog — reservation lifecycle is contextual, not a manual module
