# Static / Flutter-DS contract conformance — v1.3.5

**Result: 57/57 PASS**

Focused static conformance for the v1.3.5 interaction/evidence corrections. This supplements, rather than rewrites, historical validators tied to the v0.2.9 pilot.

## Checks

- [x] DR110 exists as active decision row
- [x] DR111 exists as active decision row
- [x] DR110 makes scan optional Phase 1
- [x] DR111 normal handover does not invent photo/signature
- [x] DR111 wrong LOT requires reason code and LOT image
- [x] SCR008 warehouse uses disabled VSelect
- [x] SCR008 date forbids prior day
- [x] SCR008 evidence uses VFileDropZone
- [x] UC02 acceptance locks warehouse/date
- [x] UC02 acceptance locks file evidence
- [x] SCR009 direct visible UOM choice
- [x] SCR009 explicitly forbids UOM dropdown
- [x] SCR009 advances directly to SCR084
- [x] UC02 acceptance locks visible multi-UOM
- [x] UC02 acceptance locks single-UOM direct advance
- [x] SCR084 append label is Thêm lô khác
- [x] SCR084 Xong is only completion CTA
- [x] Flow contract has no progressive classification toggle
- [x] Flow contract keeps four authoritative quantity inputs
- [x] Component usage documents upload evidence
- [x] UX guardrail LOCKED_CONTROL_FIDELITY exists
- [x] UX guardrail VISIBLE_MANDATORY_CHOICE exists
- [x] UX guardrail EVIDENCE_INPUT_MATCHES_ARTIFACT exists
- [x] UX guardrail DECISIVE_SELECTION_ADVANCES exists
- [x] UX guardrail APPEND_IS_NOT_COMPLETE exists
- [x] UX guardrail TEMPORAL_GUARD_IN_CONTROL exists
- [x] Cross-UIF lock promotes file upload for artifact evidence
- [x] Cross-UIF lock promotes append wording
- [x] SCR032 wrong LOT uses direct reason choices
- [x] SCR032 wrong LOT forbids text-only evidence
- [x] UC06 screens include maker + approver surfaces
- [x] UC06 acceptance blocks missing reason/image
- [x] UC06 Other requires detail
- [x] UC06 approver acceptance includes evidence
- [x] SCR028 system evidence + physical confirmation
- [x] SCR039 system evidence + physical confirmation
- [x] SCR028 does not invent mandatory recipient/photo/signature
- [x] SCR039 does not invent mandatory recipient/photo/signature
- [x] UIF05 component usage records physical confirmation
- [x] UIF05 component usage keeps scan optional
- [x] UIF06 component usage requires VFileDropZone image evidence
- [x] UIF06 component usage forbids text-only evidence
- [x] UIF07 component usage records physical confirmation
- [x] UIF07 component usage keeps scan optional
- [x] SCR008 renderer uses disabled select
- [x] SCR008 renderer uses date min localDateIso
- [x] SCR008 renderer uses file input
- [x] SCR009 renderer has direct UOM buttons
- [x] SCR009 renderer does not implement overview UOM select
- [x] Fallback line UOM also uses direct visible choice
- [x] SCR084 renderer uses Thêm lô khác
- [x] BJ06 renderer has image upload
- [x] File zones use existing mapped fileText icon
- [x] No unsupported upload semantic icon is invoked
- [x] No horizontal fixed width introduced in new choice CSS
- [x] Registry records required file upload ownership
- [x] Registry records wrong-LOT file upload ownership
