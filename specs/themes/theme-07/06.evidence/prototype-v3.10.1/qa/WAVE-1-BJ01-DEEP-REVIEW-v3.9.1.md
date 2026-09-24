# Wave 1 — BJ01 Tồn kho — Deep Review Closure v3.9.1

## Status

**DEEP-REVIEWED / LOCK CANDIDATE**

Review basis: cumulative Prototype Harness **v3.9.0 only**. Approved findings were fixed across business/data/presentation/runtime artifacts and validated again on **v3.9.1**.

## Resolved semantic findings

| Finding | Resolution |
|---|---|
| LOT reservation/availability had no authority | Removed from BJ01 LOT grain; Product + Warehouse remains authoritative; BJ05 owns LOT allocation. |
| One indicator field hid simultaneous stock/expiry conditions | Split stock-level and expiry-attention semantics; selected filter controls list phrase. |
| Product expiry wording could imply whole Product expired | Product copy uses `Có lô ...`; LOT detail uses direct expiry state. |
| Refresh used client click time as freshness | Replaced with server `query_as_of` response semantics and `Dữ liệu đến`. |
| Provenance was generic | Replaced with query-as-of + recent physical movement/source + reservation summary; BJ15 keeps full history. |
| Physical → eligible difference was unexplained | Added eligibility reason breakdown when excluded quantity exists. |
| Missing threshold/target looked NORMAL | Added explicit `NOT_CONFIGURED` semantics. |
| WARN and BLOCK_SALE were conflated | Separated near-expiry action from expiry indicator and stock eligibility. |
| Expiry precision could be over-specified | UI preserves DAY/MONTH/YEAR source precision. |
| Availability metric was styled as status | Returned to Key-value Row / Emphasis. |
| UC/screen trace lagged behind migrated UI | Active UC references and screen registry were synchronized to SCR-001/SCR-003 + overlays. |
| All-list attention text could ellipsize | Fresh-eye refinement moves identity into title and availability/attention into subtitle; focused QA asserts no subtitle overflow. |

## Necessity decisions

- **KEEP + SHOW:** Product identity, warehouse scope, Product physical/eligible/reserved/available, query-as-of, expiry, monitoring attention, eligibility reason when non-zero.
- **DEFINE, DO NOT SHOW:** ledger sequence, reservation bucket version, normalized expiry date, stock/base UOM semantics beyond the unit shown with quantity.
- **REMOVE:** LOT reserved/available before allocation, generic `Nguồn dữ liệu: Tồn kho VET45`, vague `Phạm vi số liệu`, normal-state badge noise.
- **HANDOFF:** full movement/history trace remains BJ15.

## Fresh-eye result

Second-pass end-user review after the fix found **no remaining P0/P1 semantic blocker in BJ01**. The current list/detail/LOT/provenance architecture remains unchanged; the work was semantic hardening rather than a new navigation design.

## Regression boundary

Cross-BJ semantic impact was scanned for BJ04, BJ05, BJ09, BJ12, BJ15 and CAP-01. Their local UX remains frozen until their own deep-review turn unless a shared contract required compatibility.
