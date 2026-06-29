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

## Phase 2 — IAM golden module (planned)

- [ ] IAM vertical slice: command + validator + handler + gateway + RPC migration
- [ ] `IamMediationModule` + codegen `registerGeneratedIamHandlers`
- [x] `IamStartup.initializeForTesting` — contract stub (phase 2 prep)
- [ ] Handler test với `PipelineTestHarness`
- [ ] Wire `IamStartup` từ `apps/erp/lib/core/di/injection.dart`
- [ ] Migrate ERP auth khỏi legacy `features/auth/` pattern
- [ ] Bật `GUARD_CODEGEN_STRICT=1` trong CI
- [ ] Cập nhật AGENTS.md — IAM là reference chính thức

## Flywheel log

Ghi các cải tiến harness sau khi agent fail (ngày + mô tả ngắn):

| Date | Improvement |
| ---- | ----------- |
| 2026-06-29 | Initial harness phase — AGENTS.md, guards, CI, doc reconcile |
