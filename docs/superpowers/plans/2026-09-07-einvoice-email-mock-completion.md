# E-Invoice Email Mock Completion Implementation Plan

> **Note (2026-09-07):** Email mock + `is_simulated` provenance đã được gỡ (Option B) sau nghiệm thu — xem checklist live; plan này giữ lịch sử thiết kế mock.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hoàn tất và nghiệm thu luồng gửi email hóa đơn bằng phản hồi MISA mô phỏng trên sandbox, đồng thời giữ phân biệt rõ giữa gửi thật, gửi mô phỏng và kết quả chưa xác định.

**Architecture:** Luồng giữ nguyên CQRS và internal command hiện tại: UI tạo delivery, database enqueue command, worker claim command, delivery adapter gọi `POST /invoice/sendemail`, parser đọc `SendEmailStatus`, rồi ghi kết quả vào projection/history. Mock chỉ thay HTTP transport của endpoint send email; auth, phát hành, preview và tải tài liệu vẫn dùng MISA sandbox thật.

**Tech Stack:** Dart, Flutter, Supabase/Postgres RPC, `package:http`, MISA meInvoice client, messaging worker, Flutter widget tests.

**Spec:** `docs/themes/TH-08-e-invoice/harness/EMAIL-MOCK-RUNBOOK.md` và yêu cầu triển khai email mock đã được chốt trong cuộc trò chuyện.

## Global Constraints

- `MISA_MEINVOICE_EMAIL_TRANSPORT=real` là mặc định.
- Mock chỉ được chạy với environment `local`, `development` hoặc `test` và base URL `https://testapi.meinvoice.vn/api/integration`.
- Chỉ `SendEmailStatus=3`, đúng một `TransactionID`, envelope hợp lệ và không có `ErrorCode` mới là thành công.
- Status `0`, `1`, `4`, dữ liệu thiếu/mâu thuẫn và lỗi transport không được tự chuyển thành thành công.
- Không dùng Resend cho luồng này và không gọi MISA production.
- Không sửa delivery trực tiếp thành `SUCCEEDED`; mọi trạng thái phải đi qua worker/provider/result RPC.
- SQL chỉ viết trong `supabase/migrations/_drafts/`; không promote hoặc apply migration trong các task code.
- Không chạy recovery `--apply` cho job dev cho tới khi draft đã được apply và dry-run đã được review.
- Giữ nguyên thay đổi ngoài phạm vi TH-08 đang có trong working tree.

## File Map

- MISA contract/parser: `packages/vet45_misa/lib/src/e_invoice/`, `packages/vet45_misa/test/e_invoice/`.
- Delivery application/infrastructure: `modules/einvoice/application/`, `modules/einvoice/infrastructure/`, `modules/einvoice/presentation/`.
- Worker configuration/bootstrap/tests: `apps/messaging_worker/lib/`, `apps/messaging_worker/test/`, `apps/messaging_worker/vet45.target.json`.
- ERP polling/UI/tests: `apps/erp/lib/features/sales/presentation/`, `apps/erp/test/features/sales/presentation/`.
- Database drafts: `supabase/migrations/_drafts/013_einvoice_delivery_schema_and_start_rpcs.sql`, `014_einvoice_delivery_results_and_projection_rpcs.sql`.
- Dev recovery: `scripts/supabase/recover_einvoice_email_dev_job.sh`, `scripts/supabase/sql/recover_einvoice_email_dev_job.sql`.
- Runbook: `docs/themes/TH-08-e-invoice/harness/EMAIL-MOCK-RUNBOOK.md`.

## Completed Work (already present; verify before changing)

### Task 1: Typed MISA send-email response

**Files:**
- Modified: `packages/vet45_misa/lib/src/e_invoice/i_me_invoice_client.dart`
- Modified: `packages/vet45_misa/lib/src/e_invoice/me_invoice_client.dart`
- Modified: `packages/vet45_misa/lib/src/e_invoice/fake_me_invoice_client.dart`
- Created: `packages/vet45_misa/lib/src/e_invoice/models/responses/send_email_result.dart`
- Test: `packages/vet45_misa/test/e_invoice/send_email_response_test.dart`

**Interfaces:**
- `IMeInvoiceClient.sendEmail(...)` returns `Future<MeInvoiceResult<List<MeInvoiceSendEmailResultItem>>>`.
- `MeInvoiceDeliveryClassifier.classify(result, transactionId: ...)` returns a typed `DeliveryProviderOutcome`.

- [x] Parse `data` as either a JSON list or an encoded JSON list.
- [x] Preserve transaction/reference IDs, status and error code.
- [x] Reject malformed data and envelope errors.
- [x] Require exact transaction match and status `3` for success.
- [x] Verify statuses `0–4`, mismatched transaction, duplicate result and contradictory envelope cases.

**Verification:** `dart test test/e_invoice/send_email_response_test.dart` in `packages/vet45_misa` passed 21 tests.

### Task 2: Delivery command payload compatibility

**Files:**
- Created: `modules/einvoice/application/lib/src/delivery/shared/delivery_command_payload.dart`
- Modified: `modules/einvoice/application/lib/src/delivery/commands/send_invoice_email/send_invoice_email_command.dart`
- Modified: `modules/einvoice/infrastructure/lib/src/configuration/processing/internal_commands/delivery_command_dead_letter_handler.dart`
- Test: `modules/einvoice/application/test/delivery/send_invoice_email_payload_test.dart`

- [x] Accept `tenant_id/delivery_id/attempt_id` and legacy `tenantId/deliveryId/attemptId`.
- [x] Reject missing, blank, non-string and conflicting aliases.
- [x] Keep shared-kernel serialization unchanged.
- [x] Cover the original `Null → String` failure with a regression test.

### Task 3: Mock HTTP transport and worker configuration

**Files:**
- Created: `modules/einvoice/infrastructure/lib/src/adapters/misa/me_invoice_email_transport.dart`
- Modified: `modules/einvoice/infrastructure/lib/src/adapters/misa/me_invoice_delivery_provider_adapter.dart`
- Modified: `apps/messaging_worker/lib/config/worker_env.dart`
- Modified: `apps/messaging_worker/lib/messaging_worker_bootstrap.dart`
- Modified: `apps/messaging_worker/vet45.target.json`
- Test: `modules/einvoice/infrastructure/test/adapters/misa/me_invoice_email_transport_test.dart`
- Test: `apps/messaging_worker/test/worker_email_transport_test.dart`

- [x] Implement `real|mock` transport mode and `success|sending|requested|failed|timeout` scenarios.
- [x] Intercept only `/invoice/sendemail`; forward other routes.
- [x] Preserve request transaction IDs.
- [x] Reject mock on unsafe environment or production endpoint.
- [x] Add two environment keys to the worker target.
- [x] Keep default transport real.

**Verification:** HTTP mock/adapter tests passed 13 tests; worker configuration tests passed 7 tests; worker analyze reported no issues.

### Task 4: Simulation metadata and UI state

**Files:**
- Modified: `modules/einvoice/application/lib/src/delivery/shared/delivery_provider_context_dto.dart`
- Modified: `modules/einvoice/application/lib/src/shared/order_invoice_projection_dto.dart`
- Modified: `modules/einvoice/application/lib/src/delivery/queries/get_invoice_delivery_history/invoice_delivery_item_dto.dart`
- Modified: `modules/einvoice/infrastructure/lib/src/domain/delivery/delivery_rpc_mapper.dart`
- Modified: `modules/einvoice/infrastructure/lib/src/domain/issuance/issuance_rpc_mapper.dart`
- Modified: `modules/einvoice/presentation/lib/src/widgets/post_issue_einvoice_action_sheet.dart`
- Modified: `modules/einvoice/presentation/lib/src/widgets/invoice_delivery_history_view.dart`
- Created/modified: `apps/erp/lib/features/sales/presentation/widgets/order_einvoice_polling_host.dart`

- [x] Carry persisted `is_simulated` metadata into context, projection, history and UI.
- [x] Label simulated sending/success/failure explicitly.
- [x] Poll delivery every five seconds while pending, including after issuance.
- [x] Pause when inactive and stop on terminal/dispose.
- [x] Update an open action sheet from the same Cubit/projection state.

## Remaining Implementation Tasks

### Task 5: Finish and verify database draft contract

**Files:**
- Modify: `supabase/migrations/_drafts/013_einvoice_delivery_schema_and_start_rpcs.sql`
- Modify: `supabase/migrations/_drafts/014_einvoice_delivery_results_and_projection_rpcs.sql`
- Test: `modules/einvoice/infrastructure/test/domain/delivery/delivery_simulation_metadata_test.dart`
- Test: SQL contract tests under `modules/einvoice/infrastructure/test/`

**Interfaces:**
- `einvoice.prepare_delivery_provider_call(..., p_is_simulated boolean default false)` persists the simulation bit before provider dispatch.
- `einvoice.record_delivery_result(...)` preserves that bit and emits projection/history fields.
- Projection exposes `delivery_is_simulated` and `delivery_pending`.

- [x] Run the SQL contract tests and inspect every changed `create or replace function` against the `-- Touches:` header.
- [x] Confirm both manual and automatic delivery paths set simulation metadata before enqueue/dispatch.
- [x] Confirm `load_delivery_attempt_context` returns `is_simulated` from the persisted attempt, not worker configuration.
- [x] Confirm result and dead-letter paths preserve `is_simulated` and do not overwrite it during retries.
- [x] Run `melos run migrate:verify-policy -- --strict`.
- [x] Do not promote or apply drafts in this task.

### Task 6: Complete infrastructure wiring and compile verification

**Files:**
- Modify if needed: `modules/einvoice/infrastructure/lib/src/configuration/einvoice_startup.dart`
- Modify if needed: `modules/einvoice/infrastructure/lib/src/configuration/data_access/data_access_module.dart`
- Modify if needed: `modules/einvoice/infrastructure/lib/src/adapters/misa/me_invoice_delivery_provider_adapter.dart`
- Test: `modules/einvoice/infrastructure/test/einvoice_email_http_mock_integration_test.dart`

- [x] Verify the mock delivery client is isolated from preview/download client caches.
- [x] Verify `DeliveryProviderContextDto.isSimulated` matches persisted `is_simulated` before provider call.
- [x] Verify a warmed preview/download client cannot disable or bypass the delivery mock.
- [x] Run infrastructure tests including adapter, classifier, startup, RPC mapper, SQL contract and HTTP integration tests.
- [x] Run `dart analyze` for `modules/einvoice/infrastructure` and resolve compile errors from constructor/signature changes.

### Task 7: Finish worker logging and end-to-end integration coverage

**Files:**
- Modify if needed: `apps/messaging_worker/bin/worker.dart`
- Modify if needed: `modules/einvoice/infrastructure/lib/src/adapters/misa/me_invoice_delivery_provider_adapter.dart`
- Test: `modules/einvoice/infrastructure/test/einvoice_email_http_mock_integration_test.dart`
- Test: `apps/messaging_worker/test/`

- [x] Log only command/delivery/attempt identifiers, transport mode, scenario and safe status/error code.
- [x] Do not log recipient email, bearer token or raw MISA body.
- [x] Test `success`: exactly one provider call, result `SUCCEEDED`, persisted simulation metadata.
- [x] Test `failed`: result `FAILED` with safe code and no false success.
- [x] Test `sending` and `requested`: result remains undetermined/pending and is not retried automatically after dispatch.
- [x] Test `timeout`: transport failure follows existing unknown/reconciliation path and does not create a second provider call.
- [x] Test worker discovery/claim/complete behavior with the actual internal command factory.

### Task 8: Finish ERP and presentation verification

**Files:**
- Test: `apps/erp/test/features/sales/presentation/bloc/order_einvoice_cubit_test.dart`
- Test: `apps/erp/test/features/sales/presentation/order_einvoice_polling_host_test.dart`
- Test: `modules/einvoice/presentation/test/widgets/post_issue_einvoice_action_sheet_test.dart`
- Test: `modules/einvoice/presentation/test/widgets/invoice_delivery_history_view_test.dart`

- [x] Verify an open bottom sheet changes from `Đang gửi mô phỏng` to `Đã gửi mô phỏng` without reopening.
- [x] Verify polling continues for an issued invoice whose delivery is pending.
- [x] Verify polling pauses on inactive route and stops on terminal state/dispose.
- [x] Verify persisted simulation metadata remains visible after refresh/reload.
- [x] Run focused Flutter tests and `flutter analyze` for the affected ERP/presentation packages.

### Task 9: Validate and document dev operation

**Files:**
- Modify: `docs/themes/TH-08-e-invoice/harness/EMAIL-MOCK-RUNBOOK.md`
- Modify if needed: `docs/themes/TH-08-e-invoice/harness/DEV-LIVE-ACCEPTANCE-CHECKLIST.md`
- Verify: `.vet45/profiles/dschien-local/development.env`

- [x] Set mock only in the profile file, never directly in generated `.env` files.

```env
MISA_MEINVOICE_BASE_URL=https://testapi.meinvoice.vn/api/integration
MISA_MEINVOICE_EMAIL_DELIVERY_ENABLED=true
MISA_MEINVOICE_EMAIL_TRANSPORT=mock
MISA_MEINVOICE_EMAIL_MOCK_SCENARIO=success
```

- [x] Run `melos run env:sync` and `melos run env:doctor`.
  - `env:sync` OK; `env:doctor` FAIL baseline (thiếu `APP_STORE_CONNECT_*` deploy keys) — worker/erp secrets OK; mock keys synced.
- [x] Confirm the worker startup log reports development environment and mock mode without secrets.
  - Code path: `worker.dart` logs `emailTransport` / `emailMockScenario`. **Cần restart** `worker:serve` để nạp env mock mới.
- [x] Document that status `3` is MISA's send status, not proof of inbox delivery.
- [x] Document that `sending/requested` remain unresolved because no supported MISA email-observation API is used.

### Task 10: Dry-run and optionally execute the guarded recovery

**Files:**
- Verify: `scripts/supabase/recover_einvoice_email_dev_job.sh`
- Verify: `scripts/supabase/sql/recover_einvoice_email_dev_job.sql`

- [ ] Run read-only dry-run with explicitly confirmed development `PGHOST` and `EINVOICE_RECOVERY_DEV_HOST`.
  - **Blocked (2026-09-07):** shell không có `PGHOST`/`EINVOICE_RECOVERY_DEV_HOST`/`APP_ENV`; script + SQL guards đã review tĩnh (IDs cứng, read-only default, `--apply` cần worker stopped + mock). Không đoán host.
- [ ] Confirm the exact command, attempt and delivery IDs match the known failed job.
- [ ] Confirm no `submitted_at`, provider interaction or changed retry evidence exists.
- [x] Only after the draft SQL is applied and all workers are stopped, decide separately whether to run `--apply`.
- [x] Never run `--apply` as part of automated tests and never set delivery status directly.

### Task 11: Final verification and change review

**Files:**
- Verify all changed files in the working tree.

- [x] Run focused tests for MISA, application, infrastructure, presentation, ERP and worker.
- [x] Run `melos run analyze`.
  - `CI=true melos run analyze --no-select` → SUCCESS (`--no-fatal-warnings`); baseline deprecation infos ngoài phạm vi.
- [x] Run `melos run migrate:verify-policy -- --strict`.
- [x] Run `git diff --check`.
- [x] Run GitNexus `detect_changes()` and confirm affected scope is limited to the intended TH-08 email/mock/UI paths.
  - Risk **medium**; working tree còn nhiều thay đổi TH-08/dev-acceptance ngoài session này (giữ nguyên theo constraint). Không có timestamped migration mới.
- [x] Review the diff to ensure no timestamped migration, secret, raw email, token or production endpoint was added.
- [x] Report separately which checks passed, which are baseline failures, and whether dev SQL was applied.

## Acceptance Criteria

- [ ] A development worker configured with `mock/success` processes a real queued command through the actual worker and records `SUCCEEDED` with `is_simulated=true`.
- [ ] The UI changes from `Đang gửi mô phỏng` to `Đã gửi mô phỏng` while the action sheet remains open.
- [ ] Reloading the projection/history keeps the simulation label from persisted metadata.
- [ ] `failed`, `sending`, `requested` and `timeout` never appear as successful.
- [ ] Production/staging startup rejects mock configuration.
- [ ] The old `Null → String` payload failure no longer occurs.
- [ ] No real MISA email is sent and no production endpoint is called.
- [ ] The old failed job is not mutated unless the guarded recovery dry-run is reviewed and a separate operational action is authorized.

## Self-Review Notes

- The plan covers the already completed parser, payload, mock, metadata and UI work so a new implementer can verify rather than duplicate it.
- Remaining work is split by independently testable database, infrastructure, worker, UI, operation and final-verification boundaries.
- All later interfaces reference existing names: `MeInvoiceEmailTransport`, `MeInvoiceEmailMockHttpClient`, `DeliveryProviderContextDto.isSimulated`, `delivery_is_simulated`, `delivery_pending`, and the guarded recovery script.
- No task promotes/applies a migration or runs the recovery mutation automatically.
