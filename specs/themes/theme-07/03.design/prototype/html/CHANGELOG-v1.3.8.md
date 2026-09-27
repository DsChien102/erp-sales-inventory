# CHANGELOG v1.3.8

Parent: `v1.3.7`  
Scope: **BJ06 / UIF06 deep correction**. No redesign of BJ01/BJ02/BJ04/BJ05/BJ07 or other UIFs.

## Business / decision corrections

- Added T7-DR-112: LOT-tracked return line keeps `Product + UOM + source LOT allocation`; same Product/UOM may have multiple source-LOT lines; combo is decomposed into component lines.
- Added T7-DR-113: one wrong-LOT approval case per return line, immutable snapshot binding, exact `approval_case_id`, prior decision invalidated when snapshot data changes.

## UI / interaction corrections

- SCR-030 defaults `Tất cả`; correct chip order; live no-result.
- SCR-031 separates source facts from user physical verification; all-or-nothing commit only after every line is valid and required approvals are current.
- SCR-032 no longer pre-confirms source quantity/LOT; normal LOT uses direct choice; `Lô khác` requires reason + image evidence.
- SCR-034 provides separate approver task list, exact case binding, viewable evidence, real reject typing and final decision state.
- SCR-033 classification starts unconfirmed; per-line draft editor has `Hủy / Xong`; expiry hard guard; no mixed-UOM aggregate.
- SCR-035 has explicit received/completed/rejected/permission/UNKNOWN states, no Back to consumed mutation and safe continuation/queue actions.
- Completed requests leave active maker queue; deferred receipt re-enters directly at classification.

## Contract / registry corrections

- Reconciled BJ06 BJ/UC, UIF-06, SCR-030…035 contracts, Component Usage, Action Registry, Screen Registry, UIF Registry, BJ↔UIF map and workbench metadata.
- Corrected approval screen ownership to UC-06-02 and corrected receipt/classification action ownership.

## QA

- BJ06 end-user/state: 65/65 PASS.
- BJ06 static/contract: 56/56 PASS.
- All-flow runtime: 87 renders PASS.
- BJ05 regression: 48/48 end-user and 40/40 static PASS.
- Visual QA: 12 focused specimens PASS, canonical viewport 402×874.
