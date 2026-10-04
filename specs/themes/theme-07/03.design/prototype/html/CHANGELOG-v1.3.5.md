# CHANGELOG v1.3.5

## Decisions
- Locked `T7-DR-110` — physical handover verification for BJ05/BJ07: server recheck + actor confirmation of actual physical handover; LOT verification required when applicable; scan supported but not mandatory in Phase 1.
- Locked `T7-DR-111` — evidence policy: normal handover uses immutable system evidence + actor confirmation; BJ06 wrong-LOT requires system snapshot + reason code + at least one image of the actual LOT label; `Khác` requires description.

## BJ02
- `SCR-008`: warehouse remains a disabled `VSelect` at `Kho mặc định`; goods receipt date cannot be before the current tenant day; delivery evidence is required file upload via `VFileDropZone` instead of text.
- `SCR-009`: multi-UOM Product exposes all valid UOM choices directly; no dropdown; single-UOM Product uses its UOM immediately; once Product+UOM is resolved the flow opens `SCR-084` directly.
- `SCR-084`: LOT collection append action renamed to `Thêm lô khác`; `Xong` remains the only item-completion action.
- Preserved the v1.3.4 quantity model: `Đạt / Cách ly / Hỏng / Từ chối` are authoritative inputs and total received is derived.

## Similar-root-cause corrections
- BJ06 wrong-LOT no longer accepts text-only evidence: maker selects a structured reason and uploads a LOT-label image; approver sees the mismatch, reason, evidence reference and maker.
- BJ05/BJ07 handover contracts explicitly separate system validation/evidence from the user’s physical-handover assertion; no invented mandatory recipient/photo/signature/carrier fields in Phase 1.
- Added cross-UIF guardrails: `LOCKED_CONTROL_FIDELITY`, `VISIBLE_MANDATORY_CHOICE`, `EVIDENCE_INPUT_MATCHES_ARTIFACT`, `DECISIVE_SELECTION_ADVANCES`, `APPEND_IS_NOT_COMPLETE`, `TEMPORAL_GUARD_IN_CONTROL`.

## QA corrections found during implementation
- Fixed a CSS serialization defect that prevented the new upload/UOM/reason-choice styling from applying in the browser.
- Fixed BJ06 uploaded evidence filename not refreshing visibly after file selection.
- Removed leaked technical/English copy (`reason`, `commit`, `actor`, `source/LOT`) from affected end-user surfaces.
- File-drop visuals use an existing Flutter-DS-mapped `fileText` icon rather than inventing an unsupported upload icon mapping.
