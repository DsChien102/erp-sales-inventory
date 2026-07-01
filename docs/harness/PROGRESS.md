# Harness maturity progress

Checklist tiến độ Harness Engineering. Agent đọc file này ở đầu session để biết repo đang ở đâu.

## Phase 1 — Harness foundation

- [x] [AGENTS.md](../../AGENTS.md) — agent onboarding
- [x] Docs reconciled — modules = skeleton, interim references documented
- [x] [harness-engineering.md](../architecture/harness-engineering.md) — harness definition
- [x] CI `verify_workspace` — analyze + harness guards + package tests (worker test on deploy only)
- [x] `scripts/ci/verify_harness.sh` + layer import guards
- [x] `melos run test` — workspace package tests
- [x] Skills + MODULE template — PipelineTestHarness section
- [x] Pre-commit — guard scripts after `dart format`
- [x] `docs/ddd_domain_modeling_skill.md` — mirror DDD skill

## Phase 1.5 — TH-03 harness docs

- [x] TH-03 README + harness/ scaffold
- [x] Epic overview fixes (Epic-01 table, Epic-02/03, US-04 rename)
- [x] `guard_theme_structure.sh` + `guard_theme_traceability.sh` (stub)
- [x] Exemplar traceability (updated cho Epic-01 từ US-01 đến US-04)

## Phase 1.6 — Presentation harness

- [x] `presentation-layer` skill + `docs/presentation_layer_skill.md`
- [x] `vet45-presentation-ui.mdc` (scoped rule)
- [x] `guard_presentation_size.sh` + `guard_presentation_dialogs.sh`
- [x] TH-03 ritual + module-map presentation layout
- [x] Golden reference documented — `apps/erp/lib/features/dashboard/presentation/`

## Phase 1.7 — BE/FE harness lanes

- [x] `harness/07-api-contracts.md` + lane columns trong template + `guard_theme_structure.sh`
- [x] TH-03 backfill Epic-01 traceability (Role BE/FE/E2E)
- [x] `FakePartnerModule` + `package:vet45_partner_application/testing.dart`
- [x] Epic-02/US-01 contract-first pilot (deactivate/reactivate)
- [x] `guard_theme_traceability.sh` — Role column khi exemplar-complete
- [ ] Roll-up lane % trong `docs/themes/README.md` (optional)

## Phase 2 — IAM golden module

- [x] IAM minimal foundation — DB schema `iam` + RPC session/permission + access checkers
- [x] Codegen enabled — `registerGeneratedIamHandlers`, `IamCommandPipeline`, `iam_access_metadata.g.dart`
- [x] Tenant/membership interim — `SwitchActiveTenant`, `ListTenantMembers`, `AssignMemberRole` + RPC migration
- [x] `GUARD_CODEGEN_STRICT=1` trong `verify_harness.sh`
- [x] AGENTS.md + `modules/iam/README.md` — IAM là reference chính thức
- [x] Permission code constants — `IamPermissions` / `InterimPermissionCodes` trong domain; chuẩn hóa trong skills + codegen docs
- [ ] Permission manifest ownership — gỡ `partner.*`, `settings.einvoice.*` khỏi `IamModuleDefinition`; chuyển sang `@ModuleManifest` của từng module khi bật codegen (xem [interim-domain.md](../../modules/iam/docs/interim-domain.md#cross-module-permission-placeholders-temporary))
- [ ] IAM vertical slice đầy đủ (SRS Theme 1): aggregates, onboarding, role catalog UI

## Flywheel log

Ghi các cải tiến harness sau khi agent fail (ngày + mô tả ngắn):

| Date | Improvement |
| ---- | ----------- |
| 2026-06-29 | Initial harness phase — AGENTS.md, guards, CI, doc reconcile |
| 2026-06-30 | Presentation harness — skill, UI guards, TH-03 ritual, dashboard golden ref |
| 2026-06-30 | IAM Phase 2 golden — codegen, tenant/membership interim, CI strict codegen guard |
| 2026-06-30 | Permission constants — `IamPermissions` domain class; skills/docs anti-pattern hardcode strings |
| 2026-06-30 | IAM minimal — DB RBAC, access checkers, ERP auth migration via IIamModule |
| 2026-06-30 | Implemented Presentation Layer for TH-03 Epic-01 US-03 (Bổ sung và chỉnh sửa) |
| 2026-07-01 | BE/FE harness lanes — 07-api-contracts, FakePartnerModule, Epic-02/US-01 contract-first |
