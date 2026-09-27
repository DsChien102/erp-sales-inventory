# Theme 7 — Holistic Product Review v1.9.0

## Decision

**Engineering / UX candidate: PASS. Product approval: PENDING_REVIEW.**

V1.9.0 is a cumulative hardening release built directly on v1.8.0. It does not add or rebuild a Business Journey.

## What the audit found

### 1. Product language leaked implementation mechanics

A semantic probe across the current workbench identified technical wording concentrated in BJ10/BJ11/BJ16/BJ17. Examples included concepts equivalent to operation identity, authoritative result, correction/mutation/finality/movement and internal recovery identifiers.

Correction principle: the Product UI states what the user needs to understand or decide; implementation terms remain in contracts/Inspect. The final all-state semantic gate reports zero Product UI semantic/runtime issues.

### 2. Auto-save was still modeled as a visible user action in source contracts

Although the HTML experience had already moved to auto-persistence, source registries for `SCR-008`, `SCR-009`, `SCR-084`, `SCR-038`, `SCR-040` still implied a visible Save Draft action.

V1.9.0 back-propagates the intended contract:

- Save draft = `TRACE_ONLY_SYSTEM`.
- `user_task=false`.
- Not present in visible action ownership.
- Flow registry records system ownership where relevant.
- Renderer metadata matches the contracts.

### 3. Current topology documentation had drifted behind the cumulative Harness

The legacy map belonged to an older package schema. V1.9.0 regenerates the current map from current registries and archives the exact legacy map instead of pretending the old validator/schema is current.

Current topology: **17 UIF · 73 canonical active screens · 497 active flow/state render combinations**.

## Non-regression evidence

- Topology parent v1.8 → child v1.9: 6/6 gates PASS.
- 106 SRS files + `theme.manifest.yaml`: byte-identical.
- All-flow runtime smoke: 85 renders PASS.
- Valuation: 54/54 + 27/27 + 14/14 PASS.
- Audit & Control: 48/48 + 53 renders PASS.
- Correction & Recovery: 68/68 + 95 renders PASS with v1.9 business-facing copy assertions.
- Control Foundation & Inquiry: 65/65 + 78 renders PASS.

## Validator boundary

The frozen historical package validator is not release-compatible with the cumulative Harness. With the current screen-map present, it next requires the legacy `prototype/prototype.manifest.json` and exits before validating current v1.9 artifacts. V1.9.0 therefore treats this validator as historical evidence only; current readiness is established by the v1.9 release-aware static/runtime/visual/topology/source gates.
