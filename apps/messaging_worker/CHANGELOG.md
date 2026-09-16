# Changelog

All notable changes to the **messaging worker** (`apps/messaging_worker`) are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
(`MAJOR.MINOR.PATCH`, no Flutter build number).

Ship unit: this worker only. Deploy tags: `messaging_worker-vX.Y.Z`.

## [Unreleased]

### Added

- Bind Sales module (`moduleSchema: 'sales'`) với `SalesMessagingCommandFactory` — worker xử lý `sales.outbox` qua shared `IEventsBus` cùng IAM và E-invoice.

### Changed

- Einvoice S1: Đồng bộ và lưu danh sách mẫu hóa đơn từ MISA meInvoice vào `capabilities_snapshot` và RPC `list_provider_templates` hiển thị động các mẫu thay vì mock tĩnh.

### Fixed

- Binding einvoice dùng `moduleSchema: 'einvoice'` + `EinvoiceMessagingCommandFactory` — tránh ghi đè IAM và mismatch `ProcessOutboxCommand` type.

### Internal

- TH-08 H1: fail-closed MISA view URL allowlist + bỏ diagnostic `print` download; delivery domain `hasActiveLock` chỉ `PROCESSING`.
- TH-08 H1: MISA publish retry policy bền vững — retryable rejection enqueue lại `publish_invoice` qua RPC (không dead-letter), poll `InvoiceDuplicated` reconcile bằng RefID; draft `020_einvoice_misa_publish_retry_policy.sql`.
- TH-08 H1: publish invoice worker acquire series lease trước MISA dispatch; busy lease reschedule internal command không tăng retry_count (draft `019_einvoice_misa_publish_series_lease.sql`).
- TH-08 Slice 5: delivery `UNKNOWN` không còn business lock; worker không auto-retry; manual resend tạo delivery mới (draft 013/014).
- TH-08 Slice 5: delivery provider map MISA Product envelope `data=""` thành `SUCCEEDED` (acknowledgement); `supportsEmailDelivery` chỉ true trên `api.meinvoice.vn`.
- TH-08 Slice 3: E-invoice inbox consume `sales_order_finalized.v1` (thay `sales.order.completed`) để auto-issue.
- TH-08 Slice 3 repair: draft `008` GRANT EXECUTE `start_auto_issuance` / `list_open_auto_issuance_processes` / `reevaluate_auto_issuance` cho `authenticated, service_role` (worker inbox không còn 42501).
- Deploy script build Docker `linux/amd64` rồi push GitLab registry; Railway `redeploy --from-source` thay `railway up`.
- Tách `publish` (registry) khỏi Railway: `vet45 run railway sync-env` (shared + secret service) và `vet45 run railway rollout`.
- TH-08: gỡ email mock / `is_simulated` provenance (Option B); worker chỉ còn `MISA_MEINVOICE_EMAIL_DELIVERY_ENABLED`.
- TH-08 email mock: `MISA_MEINVOICE_EMAIL_TRANSPORT`/`EMAIL_MOCK_SCENARIO`, validate sandbox-only, startup log `emailTransport`/`emailMockScenario` không secret; delivery mock client tách khỏi preview cache.
- Einvoice S5 Task 9: compose MISA delivery send adapter + send/reconcile dead-letter handlers; register generated inbox subscriptions for registered→StartAutoDelivery.
- Einvoice S5 Task 8: MISA `sendEmail` delivery adapter + closed allowlist classifier → typed `DeliveryProviderOutcome` (no `getStatus`, no raw provider payload leakage).
- Einvoice S5 Task 7: capability-aware delivery reconciliation command/handler, draft 015 load/record RPCs, unsupported MISA observation adapter registration for worker path.
- Einvoice S5 Task 6: delivery result state machine draft (prepare/record/dead-letter), UNKNOWN reconciliation enqueue, Supabase delivery command/read gateways for worker path.
- Einvoice S5 Task 5: draft delivery schema + start/read/load RPCs (worker `start_auto_delivery` / `load_delivery_attempt_context`; enqueue `einvoice.send_invoice_email`).
- Einvoice S5 Task 4: Partner source-owned `partner.get_einvoice_recipient_snapshot` draft contract (service_role only).
- Einvoice S5 Task 3: durable `einvoice.send_invoice_email` internal command + delivery application use cases (worker gateway wiring later).
- Einvoice S4: Worker slice 4 tests — `fetch_official_view` internal command tick, không observation seeder.
- Einvoice S3b: Reconciliation RPCs draft 009 with deterministic poll command enqueue, due-time claiming batch, status recovery without provider, and internal command seed helper.
- Einvoice S3b: Typed provider issuance status classifier (`MeInvoiceIssuanceStatusClassifier`), `getStatus` polling on `IMeInvoiceProviderPort` / `MeInvoiceProviderAdapter`, and durable `PollIssuanceStatusCommandHandler` without republish.
- Einvoice S2b: Supabase issuance result/command gateways + fail-closed `IssuanceRpcMapper` (typed evidence, dispatch barrier actions, projection read).
- Einvoice S2b: Typed issuance result gateway contract (`IIssuanceResultGateway`, `IssuanceResultEvidenceDto`, `PublishPreparationAction`) cho worker publish path.
- Einvoice S2a: Worker preview command/handler mapping và dispatch `einvoice.preview_invoice` qua `EinvoiceMessagingCommandFactory`.
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
