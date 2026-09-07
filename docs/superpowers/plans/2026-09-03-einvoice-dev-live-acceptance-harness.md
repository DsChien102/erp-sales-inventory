# E-Invoice Dev Live Acceptance Harness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cho phép một người dùng thật trên môi trường dev mở đúng một đơn hàng kiểm thử cố định từ Dashboard ERP và chạy end-to-end các luồng TH-08 với Supabase dev, worker và tài khoản MISA test thật: readiness, preview, phát hành thủ công, xem hóa đơn chính thức, tải PDF/XML và provider observation; gửi email thủ công/tự động được đánh dấu `SKIPPED` vì endpoint MISA test không hỗ trợ.

**Architecture:** Dữ liệu đơn kiểm thử thuộc schema nguồn `sales`, không thuộc `einvoice`. UI dev-only đi qua `IEInvoiceModule` và CQRS như UI sản phẩm, còn các RPC E-invoice dùng source-owned functions để đọc snapshot và kiểm tra data scope. Một canonical invoice builder dùng chung cho preview và publish. Worker vẫn là thành phần duy nhất gọi MISA. Trang acceptance chỉ tổng hợp projection/query thật, điều phối action thật và hiển thị checklist/diagnostics an toàn; không ghi trực tiếp Supabase và không giả trạng thái.

**Tech Stack:** Flutter/Dart 3.11, `flutter_bloc`, `go_router`, `async_query_flutter`, Vet45 CQRS/DDD modules, Supabase PostgreSQL/RPC/RLS, Dart messaging worker, MISA meInvoice test API, `url_launcher`, `http`, `path_provider`, `share_plus`.

**Spec:** [TH-08 slice roadmap](../../themes/TH-08-e-invoice/harness/04-slice-roadmap.md), [TH-08 API contracts](../../themes/TH-08-e-invoice/harness/07-api-contracts.md), [MISA sandbox checklist](../../themes/TH-08-e-invoice/harness/S1-MISA-SANDBOX-CHECKLIST.md), EP-02/US-01..03, EP-03/US-01..03, EP-04/US-01..02.

## Global Constraints

- Chỉ có một fixture: `salesOrderId = e1000000-0000-4000-8000-000000000001`, `orderCode = TEST-HDDT-001`, `sourceVersion = 1`.
- Fixture là dữ liệu tổng hợp nhưng toàn bộ xử lý E-invoice, Supabase RPC, outbox/worker, MISA test API và object storage đều là thật.
- Không tạo bảng SalesOrder trong schema `einvoice`; source fixture và source-scope gate phải do schema `sales` sở hữu.
- Không tạo migration timestamp. Mọi SQL mới/sửa nằm trong `supabase/migrations/_drafts/` cho tới khi người dùng yêu cầu promote.
- Không reset hoặc xóa invoice đã phát hành. Đây là acceptance run một lần; muốn chạy lại phải tạo fixture/version mới trong một thay đổi riêng được duyệt.
- Chỉ phát hành thủ công trong acceptance page. Auto-issuance happy path tiếp tục được chứng minh bằng integration tests vì cùng một order không thể vừa phát hành thủ công vừa phát hành tự động.
- Không gửi email từ acceptance page. MISA test endpoint phải persist `supportsEmailDelivery = false`; cả manual và auto email hiển thị `SKIPPED — MISA test endpoint không hỗ trợ gửi email`.
- Provider observation vẫn là service/worker-only. UI không được gọi RPC trigger; script dev riêng gọi `request_provider_observation_refresh`, còn UI chỉ đọc query công khai đã có.
- Dev surface phải được chặn hai lớp: `Env.isDevelopment` ở Dashboard và route guard ở router. Production build không được hiện card hoặc mở page qua deep link.
- UI không gọi Supabase trực tiếp, không đọc private table, không tự bịa trạng thái. Mọi action/query đi qua `IEInvoiceModule` và `IExecutionContext`.
- Không hiển thị/log credential, access token, viewer token, signed URL hoặc raw provider payload. Diagnostics chỉ gồm ID, trạng thái, error code/message đã sanitize và timestamp.
- Trước khi sửa bất kỳ symbol có sẵn, chạy GitNexus impact upstream và báo nếu risk HIGH/CRITICAL. Trước mỗi commit checkpoint, chạy `detect_changes(scope: compare, base_ref: main)` và xác nhận blast radius đúng task.
- Worktree đang có thay đổi TH-08 chưa commit. Không stage/commit file ngoài danh sách của task hiện tại; dùng `git status --short` và `git diff -- <paths>` trước mỗi commit.

## Acceptance State Model

Trang acceptance suy ra trạng thái từng bước từ dữ liệu server:

| Step | Passed when | Processing when | Failed when | Skipped when |
| --- | --- | --- | --- | --- |
| MISA connection | connection verified và capabilities fresh | verification/capability sync đang chạy | disconnected, expired hoặc last error | never |
| Issuance profile | readiness không có blocker profile/template | query đang load | blocker profile/template | never |
| Automation safety | `autoIssueEnabled = false` và `autoSendEnabled = false` | policy đang load | một trong hai đang bật | never |
| Preview | preview operation trả viewer URL còn hạn | pending/processing | terminal failed/check-required | never |
| Manual issuance | projection là issued/registered | requested/processing | failed/check-required | never |
| Official view | official view operation available | pending/processing | failed/check-required | never |
| PDF | document PDF available và export handoff thành công | requested/processing | failed/check-required | never |
| XML | document XML available và export handoff thành công | requested/processing | failed/check-required | never |
| Provider observation | latest observation là matched/found theo contract | chưa có kết quả sau trigger | mismatch/not-found/interaction failure | never |
| Manual email | never | never | never | luôn skipped trên MISA test endpoint |
| Auto email | never | never | never | luôn skipped trên MISA test endpoint |

`CHECK_REQUIRED` và timeout không được chuyển thành một request cạnh tranh. Retry phải giữ nguyên operation/generation theo contract S2/S4.

---

## Task 1: Freeze the dev acceptance contract with failing tests

**Files:**

- Create: `docs/themes/TH-08-e-invoice/harness/DEV-LIVE-ACCEPTANCE-CHECKLIST.md`
- Create: `modules/einvoice/infrastructure/test/dev_acceptance/einvoice_dev_acceptance_source_sql_contract_test.dart`
- Create: `modules/einvoice/infrastructure/test/dev_acceptance/einvoice_dev_acceptance_canonical_sql_contract_test.dart`
- Create: `modules/einvoice/infrastructure/test/dev_acceptance/einvoice_dev_acceptance_access_sql_contract_test.dart`
- Modify: `docs/themes/TH-08-e-invoice/harness/04-slice-roadmap.md`
- Reference: `docs/themes/TH-08-e-invoice/harness/07-api-contracts.md`

- [ ] Run `git status --short` and record the pre-existing dirty paths. Do not normalize or stage them.
- [ ] Write `DEV-LIVE-ACCEPTANCE-CHECKLIST.md` with the exact fixed IDs, one-shot constraint, prerequisite policy (`autoIssue=false`, `autoSend=false`), worker prerequisite, action order, expected terminal states and explicit email skip reason from this plan.
- [ ] In the source SQL contract test, assert that the source draft defines `sales.einvoice_acceptance_orders`, enables RLS, has no `authenticated` table grant, defines `sales.get_einvoice_source_snapshot`, and seeds only through a separate script.
- [ ] In the canonical SQL contract test, assert that both `request_invoice_preview` and `issue_invoice` invoke one `einvoice.build_canonical_invoice` helper and do not enqueue `'{}'` or construct independent partial JSON.
- [ ] Assert the helper produces every MISA-required canonical field: `invSeries`, `invDate`, `currencyCode`, `exchangeRate`, `paymentMethodName`, buyer identity/address, `totalSaleAmount`, `totalAmountWithoutVat`, `totalVatAmount`, `totalAmount`, `originalInvoiceDetail`, and `taxRateInfo`.
- [ ] In the access SQL contract test, assert authenticated read RPCs enforce `auth.uid()`, actor equality, IAM permission and `sales.can_access_sales_order`; assert the final `get_order_invoice_projection(uuid, uuid, uuid)` grant includes `authenticated`.
- [ ] Add a roadmap note under the acceptance/verification section linking the new checklist. Do not mark the Theme-5-dependent production order UI as delivered by this harness.
- [ ] Run the new tests and confirm they fail for the intended reasons: missing source draft, partial canonical payload, Sales scope stub and projection grant only to service role.

Run:

```bash
dart test modules/einvoice/infrastructure/test/dev_acceptance
```

Expected: FAIL with assertions naming the missing acceptance source and canonical/access repairs, not compilation errors.

- [ ] Run GitNexus `detect_changes(scope: compare, base_ref: main)`; review only docs/tests are affected.
- [ ] Commit only this task's paths if commits are desired in the current workflow.

```bash
git add docs/themes/TH-08-e-invoice/harness/DEV-LIVE-ACCEPTANCE-CHECKLIST.md docs/themes/TH-08-e-invoice/harness/04-slice-roadmap.md modules/einvoice/infrastructure/test/dev_acceptance
git commit -m "test(einvoice): freeze dev live acceptance contract"
```

---

## Task 2: Add the Sales-owned one-order fixture and safe dev scripts

**Files:**

- Create: `supabase/migrations/_drafts/005_sales_einvoice_dev_acceptance_source.sql`
- Create: `scripts/supabase/seed_einvoice_dev_acceptance_order.sql`
- Create: `scripts/supabase/seed_einvoice_dev_acceptance_order.sh`
- Create: `scripts/supabase/trigger_einvoice_dev_acceptance_observation.sql`
- Create: `scripts/supabase/trigger_einvoice_dev_acceptance_observation.sh`
- Modify: `modules/einvoice/infrastructure/test/dev_acceptance/einvoice_dev_acceptance_source_sql_contract_test.dart`
- Modify: `modules/einvoice/infrastructure/test/dev_acceptance/einvoice_dev_acceptance_access_sql_contract_test.dart`

**Source contract:**

```sql
sales.get_einvoice_source_snapshot(
  p_tenant_id uuid,
  p_sales_order_id uuid
) returns table (
  available boolean,
  source_version text,
  order_completed boolean,
  buyer_partner_id uuid,
  commercial_snapshot jsonb,
  buyer_snapshot jsonb,
  blockers jsonb
)

sales.can_access_sales_order(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_sales_order_id uuid
) returns boolean
```

- [ ] Before editing the existing Sales scope symbol in later drafts, run GitNexus impact upstream for `sales.can_access_sales_order`; report the S4/S5 RPC callers as expected blast radius.
- [ ] Create `sales.einvoice_acceptance_orders` with composite tenant ownership, fixed order ID support, `source_version bigint not null default 1`, `order_code`, completed status check, buyer partner ID, buyer/commercial JSON snapshots, actor audit fields and timestamps.
- [ ] Enable RLS and revoke table access from `public`, `anon`, and `authenticated`. This table is not a generic app write surface.
- [ ] Implement `sales.get_einvoice_source_snapshot` as `security definer` with a fixed search path. Return `available=false` plus a stable blocker when no matching fixture exists; never silently substitute another tenant's row.
- [ ] Implement `sales.can_access_sales_order` so it returns true only when `auth.uid()` is present, equals `p_actor_id`, an `iam.memberships` row exists for `(tenant_id = p_tenant_id, user_id = p_actor_id, status = 'active')`, and the exact fixture row belongs to that tenant.
- [ ] Revoke function execution from broad roles. Grant snapshot loading to `service_role`; grant the scope function only to the owner/service path needed by security-definer E-invoice RPCs.
- [ ] Write the seed SQL as an idempotent upsert for exactly `e1000000-0000-4000-8000-000000000001`. Require psql variables for tenant ID and actor ID; use safe individual-buyer test data and one line at 1,000,000 VND + 10% VAT = 1,100,000 VND.
- [ ] Write the shell wrapper with `set -euo pipefail`; require `DATABASE_URL`, `DEV_TENANT_ID`, `DEV_ACTOR_ID`, and an explicit `CONFIRM_DEV_EINVOICE_ACCEPTANCE=YES`. Reject missing/non-UUID values and non-dev confirmation. Never echo the connection URL or credentials.
- [ ] Write the observation script to call the existing service-role RPC for the fixed order/invoice context after issuance. Require explicit dev confirmation and accept an optional trigger UUID; generate only that idempotency key when omitted.
- [ ] Add shell contract tests or assertions to the source test covering the confirmation guard, required variables, fixed ID and absence of destructive `delete`, `truncate`, or reset statements.
- [ ] Run the focused tests.

```bash
dart test modules/einvoice/infrastructure/test/dev_acceptance/einvoice_dev_acceptance_source_sql_contract_test.dart
dart test modules/einvoice/infrastructure/test/dev_acceptance/einvoice_dev_acceptance_access_sql_contract_test.dart
bash -n scripts/supabase/seed_einvoice_dev_acceptance_order.sh
bash -n scripts/supabase/trigger_einvoice_dev_acceptance_observation.sh
```

Expected: PASS. Do not execute either script against a database in this task.

- [ ] Run GitNexus change detection and commit only Task 2 paths.

```bash
git add supabase/migrations/_drafts/005_sales_einvoice_dev_acceptance_source.sql scripts/supabase/seed_einvoice_dev_acceptance_order.sql scripts/supabase/seed_einvoice_dev_acceptance_order.sh scripts/supabase/trigger_einvoice_dev_acceptance_observation.sql scripts/supabase/trigger_einvoice_dev_acceptance_observation.sh modules/einvoice/infrastructure/test/dev_acceptance
git commit -m "feat(einvoice): add dev acceptance sales source"
```

---

## Task 3: Repair source loading, canonical construction and authenticated reads

**Files:**

- Modify: `supabase/migrations/_drafts/006_einvoice_buyer_completion_and_preview_rpcs.sql`
- Modify: `supabase/migrations/_drafts/007_einvoice_issuance_schema_and_publish_rpcs.sql`
- Modify: `supabase/migrations/_drafts/010_einvoice_official_view_rpcs.sql`
- Modify: `supabase/migrations/_drafts/014_einvoice_delivery_results_and_projection_rpcs.sql`
- Create: `scripts/supabase/build_theme8_bundle.sh`
- Create: `scripts/supabase/apply_einvoice_dev_acceptance_bundle.sh`
- Create: `theme8.sql` (generated by `scripts/supabase/build_theme8_bundle.sh`)
- Modify: `modules/einvoice/infrastructure/test/dev_acceptance/einvoice_dev_acceptance_canonical_sql_contract_test.dart`
- Modify: `modules/einvoice/infrastructure/test/dev_acceptance/einvoice_dev_acceptance_access_sql_contract_test.dart`
- Modify if return signatures change: `modules/einvoice/infrastructure/lib/src/domain/issuance/supabase_order_invoice_projection_read_gateway.dart`
- Modify if return signatures change: `modules/einvoice/infrastructure/lib/src/data_access/einvoice_rpc_mapper.dart`

**Canonical builder contract:**

```sql
einvoice.build_canonical_invoice(
  p_tenant_id uuid,
  p_sales_order_id uuid,
  p_source_version text,
  p_buyer_snapshot jsonb,
  p_commercial_snapshot jsonb
) returns jsonb
```

- [ ] Run GitNexus impact upstream for `load_issuance_source_snapshot`, `request_invoice_preview`, `issue_invoice`, `sales.can_access_sales_order`, and `get_order_invoice_projection`. Stop and report before editing if any unexpected HIGH/CRITICAL process appears.
- [ ] Replace the fail-closed `load_issuance_source_snapshot` body with delegation to `sales.get_einvoice_source_snapshot`; preserve the existing row contract expected by application/infrastructure code.
- [ ] Make readiness consume the source result rather than hardcoded `order_completed=true` and `commercial_data_mappable=true`. Map source blockers to existing stable blocker codes.
- [ ] Add `einvoice.build_canonical_invoice` once, with a fixed search path and no provider HTTP concerns. Resolve `invSeries` by matching the configured profile template ID to the verified connection capability template and taking its MISA symbol.
- [ ] Build a provider-neutral lowerCamel JSON payload with Vietnam-local `invDate`, VND currency/exchange rate, buyer fields, one or more commercial lines, totals, `originalInvoiceDetail`, and `taxRateInfo`. Validate line/tax totals and raise a stable business error before enqueueing when malformed.
- [ ] Change preview request creation to persist/enqueue the helper output instead of `'{}'`.
- [ ] Change manual issue creation to persist/enqueue the same helper output instead of its independent partial JSON. Keep the existing source-version/idempotency protections.
- [ ] Remove the `sales.can_access_sales_order` stub from S4. Make S4/S5 rely on the source-owned function created in Task 2.
- [ ] Repair the latest `get_order_invoice_projection` definition so it checks `auth.uid()`, actor equality, `einvoice.view` and Sales data scope before returning a row. Grant execute to both `authenticated` and `service_role`; keep table access revoked.
- [ ] Audit every acceptance-facing read RPC—readiness, preview, projection, attempt status, detail, documents, latest observation—and assert each enforces its documented permission plus Sales scope.
- [ ] If an existing function's `RETURNS TABLE` shape must change, add an explicit `drop function if exists schema.name(exact_arg_types)` immediately before recreation. Preserve the bundle compatibility guard for PostgreSQL error `42P13`.
- [ ] Add `build_theme8_bundle.sh` with an explicit ordered manifest of the active TH-08 drafts (`001` through `016`, including the Sales acceptance source). The script must write a temporary file, validate every manifest entry exists, prepend `\set ON_ERROR_STOP on`, then atomically replace root `theme8.sql`; it must not glob unrelated module drafts.
- [ ] Add `apply_einvoice_dev_acceptance_bundle.sh` with `set -euo pipefail`; require `CONFIRM_DEV_EINVOICE_ACCEPTANCE=YES` and non-empty `DATABASE_URL`, invoke `psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f theme8.sql`, and never print the URL. Add a shell-contract assertion covering these guards and run `bash -n` on both scripts.
- [ ] Generate `theme8.sql` and assert it contains every listed draft byte-for-byte in manifest order. Re-run the existing `einvoice_theme8_bundle_function_compatibility_test.dart` so changed OUT-row signatures are protected against PostgreSQL `42P13`.
- [ ] Update SQL contract tests for valid canonical parity, access checks, role grants and exact drop/recreate signatures.
- [ ] Run the full E-invoice infrastructure contract suite.

```bash
dart test modules/einvoice/infrastructure/test/dev_acceptance
dart test modules/einvoice/infrastructure/test/configuration/einvoice_theme8_bundle_function_compatibility_test.dart
dart test modules/einvoice/infrastructure/test
bash -n scripts/supabase/build_theme8_bundle.sh
bash -n scripts/supabase/apply_einvoice_dev_acceptance_bundle.sh
```

Expected: PASS; no test expects placeholder source defaults or empty canonical payload.

- [ ] Run `git diff --check` on the touched drafts, GitNexus change detection, then commit only Task 3 paths.

```bash
git add supabase/migrations/_drafts/006_einvoice_buyer_completion_and_preview_rpcs.sql supabase/migrations/_drafts/007_einvoice_issuance_schema_and_publish_rpcs.sql supabase/migrations/_drafts/010_einvoice_official_view_rpcs.sql supabase/migrations/_drafts/014_einvoice_delivery_results_and_projection_rpcs.sql scripts/supabase/build_theme8_bundle.sh scripts/supabase/apply_einvoice_dev_acceptance_bundle.sh theme8.sql modules/einvoice/infrastructure/test/dev_acceptance modules/einvoice/infrastructure/lib/src/domain/issuance/supabase_order_invoice_projection_read_gateway.dart modules/einvoice/infrastructure/lib/src/data_access/einvoice_rpc_mapper.dart
git commit -m "fix(einvoice): wire live sales source and canonical invoice"
```

---

## Task 4: Make MISA preview and capabilities truthful for the test endpoint

**Files:**

- Modify: `modules/einvoice/application/lib/src/ports/i_me_invoice_provider_port.dart`
- Modify: `modules/einvoice/application/lib/src/configuration/commands/sync_provider_capabilities/sync_provider_capabilities_command_handler.dart`
- Modify: `modules/einvoice/application/lib/src/configuration/commands/sync_provider_capabilities/sync_provider_capabilities_result.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/adapters/misa/me_invoice_canonical_mapper.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/adapters/misa/me_invoice_provider_adapter.dart`
- Create: `modules/einvoice/infrastructure/lib/src/adapters/misa/me_invoice_endpoint_capabilities.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/configuration/data_access/data_access_module.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/configuration/einvoice_startup.dart`
- Modify: `apps/messaging_worker/lib/config/worker_env.dart`
- Modify: `apps/messaging_worker/lib/messaging_worker_bootstrap.dart`
- Modify: `apps/messaging_worker/vet45.target.json`
- Modify: `.vet45/profiles/dschien-local/development.env.example`
- Modify: `apps/messaging_worker/test/worker_env_test.dart`
- Modify: `apps/messaging_worker/test/messaging_worker_loop_test.dart`
- Modify: `modules/einvoice/infrastructure/test/me_invoice_provider_adapter_preview_test.dart`
- Modify: `modules/einvoice/infrastructure/test/sync_provider_capabilities_handler_test.dart`
- Modify: `modules/einvoice/infrastructure/test/einvoice_slice3_integration_test.dart`
- Create: `modules/einvoice/infrastructure/test/adapters/misa/me_invoice_canonical_mapper_preview_test.dart`
- Create: `modules/einvoice/infrastructure/test/adapters/misa/me_invoice_endpoint_capabilities_test.dart`
- Modify: relevant application tests under `modules/einvoice/application/test/configuration/`

**Application contract change:**

```dart
final class MeInvoiceAuthOutcome {
  final bool supportsEmailDelivery;
  final Set<InvoiceDocumentType> supportedDocumentTypes;
  final List<ProviderTemplateDescriptor> templates;
}
```

- [ ] Run GitNexus impact upstream for `MeInvoiceAuthOutcome`, `SyncProviderCapabilitiesCommandHandler`, `MeInvoiceCanonicalMapper`, and `MeInvoiceProviderAdapter.previewUnpublished`.
- [ ] Add failing mapper tests proving a lowerCamel canonical payload becomes the PascalCase `MeInvoiceInvoiceData` required by preview, including details and tax summaries. Add failure tests for missing `invSeries`, invalid totals and empty lines.
- [ ] Add failing endpoint capability tests: `https://testapi.meinvoice.vn/api/integration` yields email unsupported even if configuration attempts to enable it; a non-test HTTPS host yields email supported only when `MISA_MEINVOICE_EMAIL_DELIVERY_ENABLED=true`; missing/false configuration fails closed for email; PDF/XML remain supported.
- [ ] Add `supportedDocumentTypes` to `MeInvoiceAuthOutcome` success/failure construction and thread it through capability synchronization into `ProviderCapabilitiesSnapshot`. Update every constructor call in `sync_provider_capabilities_handler_test.dart` and `einvoice_slice3_integration_test.dart`; failures expose an empty set.
- [ ] Add `MISA_MEINVOICE_EMAIL_DELIVERY_ENABLED` to `WorkerEnv`, target metadata and development env example with default `false`. Parse only case-insensitive `true`/`false`; reject malformed values. Thread it through `MessagingWorkerBootstrap → EinvoiceStartup → DataAccessModule → MeInvoiceProviderAdapter`.
- [ ] Implement `MeInvoiceEndpointCapabilities.resolve({required Uri baseUrl, required bool emailDeliveryEnabled})` as a pure resolver. Force email false for host `testapi.meinvoice.vn`, require explicit true for any other HTTPS host, reject non-HTTPS hosts, and advertise PDF/XML. Do not infer email support from successful login or template listing.
- [ ] Update authentication/capability listing to return the endpoint-derived email/document capabilities instead of unconditional `supportsEmailDelivery: true`.
- [ ] Add `MeInvoiceCanonicalMapper.toPreviewInvoice(Map<String, Object?> canonical)` and make `previewUnpublished` use it. Keep `toPublishRequest` as the publish mapping and share validation helpers so preview and publish reject the same malformed canonical fields.
- [ ] Ensure no credential, canonical raw payload, access token or preview URL is logged in error paths.
- [ ] Run focused and full module tests.

```bash
dart test modules/einvoice/infrastructure/test/adapters/misa/me_invoice_canonical_mapper_preview_test.dart
dart test modules/einvoice/infrastructure/test/adapters/misa/me_invoice_endpoint_capabilities_test.dart
dart test modules/einvoice/infrastructure/test/me_invoice_provider_adapter_preview_test.dart
dart test modules/einvoice/application/test
dart test modules/einvoice/infrastructure/test
cd apps/messaging_worker && dart test test/worker_env_test.dart test/messaging_worker_loop_test.dart
```

Expected: PASS; synchronized MISA test connection advertises `{pdf, xml}` and `supportsEmailDelivery=false`.

- [ ] Run GitNexus change detection and commit only Task 4 paths.

```bash
git add modules/einvoice/application/lib/src/ports/i_me_invoice_provider_port.dart modules/einvoice/application/lib/src/configuration/commands/sync_provider_capabilities modules/einvoice/infrastructure/lib/src/adapters/misa modules/einvoice/infrastructure/lib/src/configuration/data_access/data_access_module.dart modules/einvoice/infrastructure/lib/src/configuration/einvoice_startup.dart modules/einvoice/application/test/configuration modules/einvoice/infrastructure/test/adapters/misa modules/einvoice/infrastructure/test/me_invoice_provider_adapter_preview_test.dart modules/einvoice/infrastructure/test/sync_provider_capabilities_handler_test.dart modules/einvoice/infrastructure/test/einvoice_slice3_integration_test.dart apps/messaging_worker/lib/config/worker_env.dart apps/messaging_worker/lib/messaging_worker_bootstrap.dart apps/messaging_worker/vet45.target.json .vet45/profiles/dschien-local/development.env.example apps/messaging_worker/test/worker_env_test.dart apps/messaging_worker/test/messaging_worker_loop_test.dart
git commit -m "fix(einvoice): map MISA preview and sandbox capabilities"
```

---

## Task 5: Complete the reusable live order E-invoice orchestration

**Files:**

- Modify: `apps/erp/lib/features/sales/presentation/bloc/order_einvoice_cubit.dart`
- Modify: `apps/erp/lib/features/sales/presentation/bloc/order_einvoice_state.dart`
- Modify: `apps/erp/lib/features/sales/presentation/widgets/order_einvoice_section.dart`
- Modify: `apps/erp/lib/features/sales/presentation/support/order_einvoice_idempotency_key_factory.dart`
- Create: `apps/erp/lib/features/einvoice/presentation/services/einvoice_viewer_launcher.dart`
- Create: `apps/erp/lib/features/einvoice/presentation/services/invoice_document_exporter.dart`
- Modify: `apps/erp/pubspec.yaml`
- Modify: `apps/erp/test/features/sales/presentation/order_einvoice_section_test.dart`
- Create: `apps/erp/test/features/sales/presentation/order_einvoice_cubit_test.dart`
- Create: `apps/erp/test/features/einvoice/presentation/services/invoice_document_exporter_test.dart`

**Public UI inputs:**

```dart
OrderEInvoiceSection(
  salesOrderId: acceptanceOrderId,
  orderVersion: 1,
  confirmationSummary: const IssueInvoiceConfirmationSummary(...),
  allowEmailDelivery: false,
  emailDisabledReason: misaSandboxEmailSkipReason,
  onAcceptanceEvent: cubit.recordUiEvent,
)
```

- [ ] Run GitNexus impact upstream for `OrderEInvoiceCubit`, `OrderEInvoiceState`, `OrderEInvoiceSection`, and `OrderEInvoiceIdempotencyKeyFactory`; warn before edits if dashboard/order flows outside the expected sales presentation process are affected.
- [ ] Write failing cubit tests for preview request → polling → available URL, manual issue → polling → issued projection, official view → polling → available URL, PDF/XML request → polling → document available, terminal failure, `CHECK_REQUIRED`, and duplicate-tap suppression.
- [ ] Write failing widget tests proving every `PreIssueAction` and `PostIssueAction` is handled, the confirmation summary is injected rather than hardcoded, and send is visibly disabled with the MISA test reason.
- [ ] Extend state with independent operation state for preview, issuance, official view, PDF and XML. Store safe IDs/status/error metadata only; do not put viewer token or signed URL in diagnostics state.
- [ ] Add cubit methods `requestPreview`, `issueOrRetry`, `requestOfficialView`, and `requestDocument(InvoiceDocumentType)`. Generate stable per-operation idempotency keys and prevent a second command while that operation is non-terminal.
- [ ] Poll via the existing async query infrastructure every 3 seconds while an operation is non-terminal, stop on terminal state, and cancel timers/subscriptions in `close`. Do not use local fake transitions beyond immediate optimistic “requested/processing”.
- [ ] Handle `CHECK_REQUIRED` as the same operation awaiting reconciliation/retry. Never create a competing generation because polling timed out.
- [ ] Add `EInvoiceViewerLauncher` backed by `url_launcher`; validate `https` URLs and open externally. Inject a fake in tests.
- [ ] Add `InvoiceDocumentExporter`: fetch the short-lived signed URL with `http`, write to `path_provider` temp storage, invoke the OS export/share sheet through `share_plus`, then delete the temporary file best-effort. Reject non-HTTPS URLs, cap/validate response handling, and never log the URL.
- [ ] Add direct ERP dependencies `url_launcher`, `http`, `path_provider`, and `share_plus`; run `flutter pub get` from `apps/erp` and include only generated lockfile changes owned by this package/workspace.
- [ ] Wire action sheets to the cubit and external services. For documents, wait until the query reports `AVAILABLE`, resolve/export through the existing DTO contract, and surface a retryable UI error if handoff fails.
- [ ] Keep the reusable section production-compatible: `allowEmailDelivery` defaults from provider capability in normal callers; only the dev acceptance caller forces false. Do not alter module presentation widgets to perform direct application calls.
- [ ] Run focused Flutter tests and analyzer.

```bash
cd apps/erp && flutter pub get
cd apps/erp && flutter test test/features/sales/presentation/order_einvoice_cubit_test.dart test/features/sales/presentation/order_einvoice_section_test.dart test/features/einvoice/presentation/services/invoice_document_exporter_test.dart
cd apps/erp && flutter analyze
```

Expected: PASS; no hardcoded `#DH-000129` or ignored sheet result remains in `OrderEInvoiceSection`.

- [ ] Run GitNexus change detection and commit only Task 5 paths plus the dependency lockfile actually changed by `flutter pub get`.

```bash
git add apps/erp/lib/features/sales/presentation apps/erp/lib/features/einvoice/presentation/services apps/erp/test/features/sales/presentation apps/erp/test/features/einvoice/presentation/services apps/erp/pubspec.yaml pubspec.lock
git commit -m "feat(erp): complete live invoice order actions"
```

---

## Task 6: Build the dev-only acceptance page, checklist and diagnostics

**Files:**

- Create: `apps/erp/lib/features/einvoice/presentation/models/einvoice_acceptance_fixture.dart`
- Create: `apps/erp/lib/features/einvoice/presentation/bloc/einvoice_acceptance_cubit.dart`
- Create: `apps/erp/lib/features/einvoice/presentation/bloc/einvoice_acceptance_state.dart`
- Create: `apps/erp/lib/features/einvoice/presentation/pages/einvoice_acceptance_order_page.dart`
- Create: `apps/erp/lib/features/einvoice/presentation/widgets/einvoice_acceptance_banner.dart`
- Create: `apps/erp/lib/features/einvoice/presentation/widgets/einvoice_acceptance_order_summary.dart`
- Create: `apps/erp/lib/features/einvoice/presentation/widgets/einvoice_acceptance_checklist.dart`
- Create: `apps/erp/lib/features/einvoice/presentation/widgets/einvoice_acceptance_diagnostics.dart`
- Create: `apps/erp/lib/features/einvoice/presentation/widgets/einvoice_acceptance_email_skip_card.dart`
- Create: `apps/erp/test/features/einvoice/presentation/einvoice_acceptance_cubit_test.dart`
- Create: `apps/erp/test/features/einvoice/presentation/einvoice_acceptance_order_page_test.dart`

**Fixture model:**

```dart
abstract final class EInvoiceAcceptanceFixture {
  static const salesOrderId = 'e1000000-0000-4000-8000-000000000001';
  static const sourceVersion = 1;
  static const orderCode = 'TEST-HDDT-001';
  static const totalAmount = 1100000;
  static const emailSkipReason =
      'MISA test endpoint không hỗ trợ gửi email';
}
```

- [ ] Write cubit tests with `FakeEInvoiceModule` responses for disconnected connection, unsafe automation, readiness blockers, pre-issue, preview available, issuance processing/issued/failed, official view, PDF/XML and observation outcomes.
- [ ] Write page tests proving the red/amber preflight blocks destructive actions, the fixed order summary is rendered, real `OrderEInvoiceSection` is embedded, email rows are skipped, refresh re-queries module data, and diagnostics redact URLs/tokens.
- [ ] Implement immutable acceptance state with typed `AcceptanceStepState` (`notStarted`, `processing`, `passed`, `failed`, `skipped`) and safe diagnostic fields. Derive step state from query DTOs; do not persist a parallel workflow state.
- [ ] In `load`, dispatch through `IEInvoiceModule`: `GetProviderConnectionScreenQuery`, `GetAutomationPolicyQuery`, `GetIssuanceReadinessQuery`, and `GetOrderInvoiceProjectionQuery`. Once issued, also query detail, documents, latest observation and delivery history as available.
- [ ] Require the active `IExecutionContext` tenant/user for every query. Treat missing context as a blocking page error; never substitute seed IDs for tenant/actor.
- [ ] Preflight must require verified MISA connection, selected template/profile, `autoIssue=false`, `autoSend=false`, readiness success and document capabilities PDF/XML. Show a direct navigation action to connection/profile/automation settings for each resolvable blocker.
- [ ] Compose a page under 500 lines using the five extracted widgets and Vet45 design-system tokens. Place an unmistakable `DEV / MISA TEST / ONE-SHOT` banner above the order summary.
- [ ] Embed the real `OrderEInvoiceSection` with fixed fixture inputs and injected services. Disable issue until preflight passes; after issuance, keep non-destructive view/download actions available.
- [ ] Render observation as “awaiting service trigger” until the dev script has run. Include the exact safe shell command shape from the checklist, but never include `DATABASE_URL` or service key in UI.
- [ ] Render both email entries as skipped and provide no send/resend callback. If the synchronized capability unexpectedly says email is supported on a test host, display a blocking configuration mismatch instead of enabling send.
- [ ] Show diagnostics: tenant ID, actor ID, sales order ID, source version, attempt ID, electronic invoice ID, operation IDs, provider invoice reference, state/error code and timestamps. Redact all viewer/signed URLs, tokens and canonical/provider payloads.
- [ ] Poll only while at least one acceptance operation is non-terminal; use 3-second interval and stop when terminal or page disposed.
- [ ] Run focused tests and analyzer.

```bash
cd apps/erp && flutter test test/features/einvoice/presentation/einvoice_acceptance_cubit_test.dart test/features/einvoice/presentation/einvoice_acceptance_order_page_test.dart
cd apps/erp && flutter analyze
```

Expected: PASS; the page can be driven entirely with fake module responses in tests while production code uses the real registered `IEInvoiceModule`.

- [ ] Run GitNexus change detection and commit only Task 6 paths.

```bash
git add apps/erp/lib/features/einvoice/presentation/models/einvoice_acceptance_fixture.dart apps/erp/lib/features/einvoice/presentation/bloc/einvoice_acceptance_cubit.dart apps/erp/lib/features/einvoice/presentation/bloc/einvoice_acceptance_state.dart apps/erp/lib/features/einvoice/presentation/pages/einvoice_acceptance_order_page.dart apps/erp/lib/features/einvoice/presentation/widgets/einvoice_acceptance_banner.dart apps/erp/lib/features/einvoice/presentation/widgets/einvoice_acceptance_order_summary.dart apps/erp/lib/features/einvoice/presentation/widgets/einvoice_acceptance_checklist.dart apps/erp/lib/features/einvoice/presentation/widgets/einvoice_acceptance_diagnostics.dart apps/erp/lib/features/einvoice/presentation/widgets/einvoice_acceptance_email_skip_card.dart apps/erp/test/features/einvoice/presentation
git commit -m "feat(erp): add dev MISA acceptance page"
```

---

## Task 7: Expose the page from Dashboard with a two-layer dev gate

**Files:**

- Modify: `apps/erp/lib/features/dashboard/presentation/widgets/task_item.dart`
- Modify: `apps/erp/lib/features/dashboard/presentation/dashboard_page.dart`
- Modify: `apps/erp/lib/core/router/app_router.dart`
- Create or modify: `apps/erp/test/features/dashboard/presentation/dashboard_page_test.dart`
- Create or modify: `apps/erp/test/core/router/app_router_test.dart`

- [ ] Run GitNexus impact upstream for `TaskItem`, `DashboardPage`, and the router factory before editing.
- [ ] Add failing dashboard tests: development environment shows one “Kiểm thử hóa đơn MISA” task with `TEST-HDDT-001`; non-development environment does not show it; tapping it navigates to the acceptance route.
- [ ] Add failing router tests: the named route resolves in development; the same deep link redirects to Dashboard or a not-found/denied page outside development.
- [ ] Add optional `VoidCallback? onTap` to `TaskItem` and pass it to the underlying design-system item. Existing task cards retain their current no-op/default behavior.
- [ ] Add a single dev task under “Việc cần xử lý” with title, order code, `DEV · MISA TEST` badge and test-tube/invoice icon from the existing icon set. Gate creation with `Env.isDevelopment`.
- [ ] Add route path `/dev/einvoice-acceptance`, name `dev.einvoice.acceptance`, and a route-level `Env.isDevelopment` guard. Construct dependencies from existing DI registrations; do not instantiate Supabase clients in the route.
- [ ] Ensure back navigation returns to Dashboard and the bottom navigation shell remains consistent with app routing conventions.
- [ ] Run dashboard/router tests and full ERP tests.

```bash
cd apps/erp && flutter test test/features/dashboard/presentation/dashboard_page_test.dart test/core/router/app_router_test.dart
cd apps/erp && flutter test
cd apps/erp && flutter analyze
```

Expected: PASS; production-mode tests cannot discover or deep-link to the acceptance page.

- [ ] Run GitNexus change detection and commit only Task 7 paths.

```bash
git add apps/erp/lib/features/dashboard/presentation/widgets/task_item.dart apps/erp/lib/features/dashboard/presentation/dashboard_page.dart apps/erp/lib/core/router/app_router.dart apps/erp/test/features/dashboard/presentation/dashboard_page_test.dart apps/erp/test/core/router/app_router_test.dart
git commit -m "feat(erp): expose dev invoice acceptance entry"
```

---

## Task 8: Verify the real dev flow and publish the runbook evidence

**Files:**

- Modify: `docs/themes/TH-08-e-invoice/harness/DEV-LIVE-ACCEPTANCE-CHECKLIST.md`
- Modify: `docs/themes/TH-08-e-invoice/harness/04-slice-roadmap.md`
- Modify if required by repository workflow: `supabase/migrations/REGISTRY.yaml`
- Do not create: `supabase/migrations/[0-9]*.sql` unless the user separately requests promotion.

- [ ] Run environment checks before touching shared dev data.

```bash
melos run env:sync
melos run env:doctor
```

Expected: active profile points to dev Supabase, worker config points to MISA test host, and no production target appears.

- [ ] Rebuild the deterministic bundle and run its compatibility test before applying it.

```bash
bash scripts/supabase/build_theme8_bundle.sh
dart test modules/einvoice/infrastructure/test/configuration/einvoice_theme8_bundle_function_compatibility_test.dart
```

- [ ] Apply the generated bundle directly to the explicitly supplied dev database. Do not run `supabase db push`, because drafts are intentionally outside official migration history.

```bash
CONFIRM_DEV_EINVOICE_ACCEPTANCE=YES DATABASE_URL=<dev-database-url> bash scripts/supabase/apply_einvoice_dev_acceptance_bundle.sh
```

A changed OUT/`RETURNS TABLE` signature must have an exact `DROP FUNCTION IF EXISTS` in the generated bundle before recreation so PostgreSQL does not raise `42P13`.
- [ ] Run the one-order seed with explicit dev variables and confirmation.

```bash
CONFIRM_DEV_EINVOICE_ACCEPTANCE=YES DEV_TENANT_ID=<active-tenant-uuid> DEV_ACTOR_ID=<signed-in-user-uuid> DATABASE_URL=<dev-database-url> bash scripts/supabase/seed_einvoice_dev_acceptance_order.sh
```

Expected: exactly one `TEST-HDDT-001` source row is inserted/updated for the active tenant; no E-invoice record exists until the app requests one.

- [ ] Start the real messaging worker with the dev profile and confirm it claims E-invoice commands without logging credentials.
- [ ] Launch ERP in development, open Dashboard → “Kiểm thử hóa đơn MISA”, and verify preflight is green except the intentional email skips.
- [ ] Request preview; capture safe evidence of request/operation IDs and confirm the MISA preview viewer opens.
- [ ] Issue manually exactly once; wait for terminal issued/registered projection and record provider invoice reference plus timestamps. Do not tap issue again while pending.
- [ ] Open official invoice view and verify it comes from the MISA operation result.
- [ ] Request/export PDF and XML separately; verify the OS handoff receives readable files and the app does not retain signed URLs in logs/state.
- [ ] Trigger provider observation from the service-side dev script, then refresh/poll the page until the latest real observation is shown.

```bash
CONFIRM_DEV_EINVOICE_ACCEPTANCE=YES DEV_TENANT_ID=<active-tenant-uuid> DEV_ACTOR_ID=<signed-in-user-uuid> DATABASE_URL=<dev-database-url> bash scripts/supabase/trigger_einvoice_dev_acceptance_observation.sh
```

- [ ] Confirm manual email and auto email remain skipped, no delivery command/outbox record was created by the acceptance page, and automation policy stayed disabled.
- [ ] Record only sanitized evidence in the checklist: date, tester, safe IDs, terminal states and pass/fail. Do not paste provider payloads, tokens, URLs, credentials or downloaded invoice contents.
- [ ] Run repository verification.

```bash
melos bootstrap
melos run codegen
melos run analyze
melos run test
bash scripts/ci/verify_harness.sh
cd apps/erp && flutter test
cd apps/messaging_worker && dart test
git diff --check
```

Expected: all commands exit 0. If a live MISA call fails, preserve its safe interaction ID/error code in the checklist and do not mark the corresponding acceptance row passed.

- [ ] Run `rg -n "TODO|TBD|implement later|SOURCE_SNAPSHOT_UNAVAILABLE|'canonical_invoice': '\{\}'"` over the touched implementation paths. The only acceptable TODO is an explicitly unrelated pre-existing item documented in the final handoff.
- [ ] Run GitNexus `detect_changes(scope: compare, base_ref: main)` and confirm affected flows are limited to TH-08 source loading, preview/publish, S4 reads and ERP dev acceptance UI.
- [ ] Update the roadmap with truthful status: automated verification passed, live acceptance rows individually passed/failed/skipped, production Theme 5 order entry still not replaced by this harness.
- [ ] Commit only docs/evidence changes after removing all secrets from the diff.

```bash
git add docs/themes/TH-08-e-invoice/harness/DEV-LIVE-ACCEPTANCE-CHECKLIST.md docs/themes/TH-08-e-invoice/harness/04-slice-roadmap.md
git diff --cached --check
git commit -m "docs(einvoice): record dev MISA acceptance evidence"
```

## Final Review Gate

- [ ] Verify every acceptance page command/query crosses `IExecutionContext → IEInvoiceModule → CQRS`; search for and reject direct `Supabase.instance` or `.rpc(` usage under the new presentation paths.
- [ ] Verify source ownership: `sales` owns fixture/snapshot/scope; `einvoice` owns invoice lifecycle only.
- [ ] Verify canonical parity: preview and publish consume the same canonical builder and mapper validation.
- [ ] Verify capability truth: test host email false, PDF/XML true, and UI does not offer send.
- [ ] Verify ambiguity safety: timeout/`CHECK_REQUIRED` never creates a competing operation.
- [ ] Verify production isolation in both widget and router tests.
- [ ] Verify no secret or short-lived URL appears in logs, diagnostics, docs or git diff.
- [ ] Verify no official timestamp migration was created without an explicit promotion request.
- [ ] Verify all changed public DTOs/ports have matching fakes, mappers and tests.
- [ ] Verify `theme8.sql`/bundle generation, if used operationally, includes exact `DROP FUNCTION IF EXISTS` statements for changed OUT-row signatures before `CREATE OR REPLACE`.
