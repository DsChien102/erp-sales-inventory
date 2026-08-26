# Changelog

All notable changes to the **messaging worker** (`apps/messaging_worker`) are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
(`MAJOR.MINOR.PATCH`, no Flutter build number).

Ship unit: this worker only. Deploy tags: `messaging_worker-vX.Y.Z`.

## [Unreleased]

### Added

### Changed

### Fixed

### Internal

- Deploy script build Docker `linux/amd64` rồi push GitLab registry; Railway `redeploy --from-source` thay `railway up`.
- Tách `publish` (registry) khỏi Railway: `vet45 run railway sync-env` (shared + secret service) và `vet45 run railway rollout`.
- Einvoice S1: `read_provider_credentials` lấy `tax_code` từ `iam.tenant_legal_profiles` khi credential chưa có MST.

## [0.1.1] - 2026-08-20

### Added

- Module binding registry (`MessagingModuleBinding` + `IamMessagingCommandFactory`) — dispatch theo `module_schema` / `queue_type`, không hardcode IAM trong loop.
- Partition pool concurrency (`WORKER_CONCURRENCY`, default 4) theo key `(tenant, module, queue)`.
- Discovery RPC `list_tenants_with_pending_messaging(p_limit, p_modules)` — worker chỉ poll module đã bind.
- Structured JSON logs + tick metrics giàu hơn (`tickId`, `queuesSucceeded`, `byQueue`, `discoveryMs`, …); `WORKER_LOG_LEVEL` điều khiển verbosity.

### Changed

- Bỏ `IMessagingModule` / registry trong `vet45_adapters`; worker gọi trực tiếp `IModuleMediator`.
- Railway IaC: config chuyển sang `.railway/railway.ts` (TypeScript SDK); cập nhật README / `set_secrets.sh`.

### Internal

- IAM integration events: `MembershipDeactivated`, email delivery payload helpers, generated registry wiring.
- Docs: architecture messaging P1 + ops `messaging_worker_scaling.md` (P3 replica shard — docs only).
- Requires promoted messaging discovery migration (`platform_list_pending_messaging_queues` / tương đương).
- Sample range: commits after `d217f0a` through `fix/theme1` (incl. `e939f308` logging).

## [0.1.0] - 2026-08-20

### Internal

- Baseline entry when introducing app-scoped changelog process.
