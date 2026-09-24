# UI Flow Validation Report — v3.6.0

**Kết quả:** `PASS` · **Evidence:** `SEMANTIC_RUNTIME_VISUAL_VALIDATED`

| Gate | Kết quả |
|---|---|
| Business Journey | `PASS — 17/17` |
| Supporting capability | `PASS — CAP-01 / SCR-062..065` |
| Canonical route occurrences | `PASS — 89` |
| Active unique screens | `PASS — 77` |
| Declared route-state effective render | `PASS — 518/518` |
| Audit & Control effective render | `PASS — 272/272` |
| Semantic transition E2E | `PASS` — `../html/qa/FLOW-LOGIC-E2E-QA-v3.6.0.json` |
| Full Theme completion/dead-end/feedback | `PASS` — `../html/qa/FULL-THEME-COMPLETION-QA-v3.6.0.json` |
| Representative-state reachability/coherence | `PASS` — `../html/qa/REPRESENTATIVE-COHERENCE-QA-v3.6.0.json` |
| Runtime UI / geometry / chip / list surfaces / navigation | `PASS` — `../html/qa/RUNTIME-UI-QA-v3.6.0.json` |

### Flow rules locked in v3.6.0

- BJ08 cancellation exists **inside an opened active session only**, never on the browse list.
- Every stable non-root state has an executable continuation/exit.
- Auxiliary Back returns to its launching occurrence; screen-array order is not a navigation contract.
- Navigation/read-only actions never create business finality.
- UNKNOWN keeps same-operation recovery semantics; no blind retry.
- Same-context mutations use semantic visible feedback where needed; pure navigation does not emit success toast.

Historical v3.5.0 report is preserved as `validation-report-v3.5.0.md`.
