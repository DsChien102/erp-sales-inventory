# Harness maturity progress

Checklist tiến độ Harness Engineering. Agent đọc file này ở đầu session để biết repo đang ở đâu.

## Phase 1 — Harness foundation

- [x] [AGENTS.md](../../AGENTS.md) — agent onboarding
- [x] Docs reconciled — modules = skeleton, interim references documented
- [x] [harness-engineering.md](../architecture/harness-engineering.md) — harness definition
- [x] CI `verify_workspace` — analyze + harness guards + package tests
- [x] `scripts/ci/verify_harness.sh` + layer import guards
- [x] `melos run test` — workspace package tests
- [x] Skills + MODULE template — PipelineTestHarness section
- [x] Pre-commit — guard scripts after `dart format`
- [x] `docs/ddd_domain_modeling_skill.md` — mirror DDD skill

## Phase 1.5 — TH-03 harness docs

- [x] TH-03 README + harness/ scaffold
- [x] Epic overview fixes (Epic-01 table, Epic-02/03, US-04 rename)
- [x] `guard_theme_structure.sh` + `guard_theme_traceability.sh` (stub)
- [ ] Exemplar traceability (deferred — placeholder trong `05-traceability.md`)

## Phase 1.6 — Presentation harness

- [x] `presentation-layer` skill + `docs/presentation_layer_skill.md`
- [x] `vet45-presentation-ui.mdc` (scoped rule)
- [x] `guard_presentation_size.sh` + `guard_presentation_dialogs.sh`
- [x] TH-03 ritual + module-map presentation layout
- [x] Golden reference documented — `apps/erp/lib/features/dashboard/presentation/`

## Phase 2 — IAM golden module (planned)

- [x] IAM minimal foundation — DB schema `iam` + RPC session/permission + `IamPermissionChecker` / `IamTenantAccessChecker` / `IExecutionContext`
- [x] `IamMediationModule` hand-wired (SignIn/SignOut/GetCurrentSession) + `AccessMetadataRegistry`
- [x] `IamStartup.initialize` / `initializeForTesting` — composition root + `IamRuntime`
- [x] Handler tests — checkers + SignIn + composition
- [x] Wire `IamStartup` từ `apps/erp/lib/core/di/injection.dart`
- [x] Migrate ERP auth khỏi legacy `features/auth/` domain+data (login/logout qua `IIamModule`)
- [ ] IAM vertical slice đầy đủ (SRS Theme 1): aggregates, role management use-cases, codegen
- [ ] codegen `registerGeneratedIamHandlers` + bật `GUARD_CODEGEN_STRICT=1` trong CI
- [ ] Cập nhật AGENTS.md — IAM là reference chính thức

## Flywheel log

Ghi các cải tiến harness sau khi agent fail (ngày + mô tả ngắn):

| Date | Improvement |
| ---- | ----------- |
| 2026-06-29 | Initial harness phase — AGENTS.md, guards, CI, doc reconcile |
| 2026-06-30 | Presentation harness — skill, UI guards, TH-03 ritual, dashboard golden ref |
| 2026-06-30 | IAM minimal — DB RBAC, access checkers, ERP auth migration via IIamModule |
