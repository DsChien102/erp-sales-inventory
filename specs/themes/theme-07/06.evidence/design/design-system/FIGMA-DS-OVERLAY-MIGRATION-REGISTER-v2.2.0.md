# Figma DS Overlay Migration Register — v2.2.0 candidate

Legacy generic sheet contexts inventoried: **12**.

> Rule: `VBottomSheet` is not a canonical migration target by itself. Resolve each use to a live Figma overlay pattern/component.

| UIF | Legacy context | Intent | Canonical target | Status |
|---|---|---|---|---|
| UIF-03 | `val03EvidenceSheet` | Evidence/calculation; conflict mode adds source selection + required reason | Form Sheet when conflict; read-only mode has no exact Info Sheet equivalent | **SOURCE_DECISION_REQUIRED** |
| UIF-01 | `bj01LotSheet` | Read-only LOT detail | No canonical read-only Info/Detail Sheet master | **SOURCE_DECISION_REQUIRED** |
| UIF-01 | `bj01ProvenanceSheet` | Read-only provenance/as-of detail | No canonical read-only Info/Detail Sheet master | **SOURCE_DECISION_REQUIRED** |
| UIF-07 | `io07VerificationSheet` | Verification form/action task | DS v2 / Form Sheet · 1353:6355 | **RESOLVABLE_EXACT** |
| UIF-05 | `io05OverrideLotSheet` | Choose alternate LOT + required reason | DS v2 / Form Sheet · 1353:6355 (selection controls + reason) | **RESOLVABLE_EXACT** |
| UIF-06 | `io06RejectSheet` | Reject approval with mandatory reason | DS v2 / Confirmation Sheet · 550:1058 · Danger/Reason | **RESOLVABLE_EXACT** |
| UIF-06 | `io06ClassificationSheet` | Classify quantities across four business states | DS v2 / Form Sheet · 1353:6355 | **RESOLVABLE_EXACT** |
| UIF-08 | `ic08CancelSheet` | Cancel count session with reason | DS v2 / Confirmation Sheet · 550:1058 · Danger/Reason | **RESOLVABLE_EXACT** |
| UIF-11 | `cr11RejectSheet` | Reject correction with mandatory reason | DS v2 / Confirmation Sheet · 550:1058 · Danger/Reason | **RESOLVABLE_EXACT** |
| UIF-12 | `cf12RejectSheet` | Reject opening balance with mandatory reason | DS v2 / Confirmation Sheet · 550:1058 · Danger/Reason | **RESOLVABLE_EXACT** |
| UIF-15 | `cf15ProductSheet` | Read-only product inventory detail + handoff action | No canonical read-only Info/Detail Sheet master | **SOURCE_DECISION_REQUIRED** |
| UIF-02 | `openRejectSheet` | Reject receiving approval with mandatory reason | DS v2 / Confirmation Sheet · 550:1058 · Danger/Reason | **RESOLVABLE_EXACT** |

## Blocking DS decision

Figma DS v2.0.2 currently has Action Sheet, Confirmation Sheet, Select Sheet, Filter Sheet, Form Sheet and VModal, but no canonical read-only **Info/Detail Sheet**. The read-only sheet interactions in UIF-01, UIF-03 and UIF-15 therefore cannot be declared 1:1 DS-exact without a Product/DS decision. Do not preserve a naked legacy `VBottomSheet` shell by approximation.
