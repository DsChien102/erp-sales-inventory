# TH-08 Slice 3 Kế hoạch triển khai Auto-Issue, Đối soát (Reconciliation), và Phát hành lại (Retry)

> **Dành cho agent:** SUB-SKILL BẮT BUỘC: Sử dụng superpowers:subagent-driven-development (khuyến nghị) hoặc superpowers:executing-plans để triển khai kế hoạch này theo từng task. Các bước sử dụng cú pháp checkbox (`- [ ]`) để theo dõi tiến độ.

**Mục tiêu (Goal):** Hoàn tất Slice 3 của TH-08 gồm auto-issue sau khi đơn hàng đủ điều kiện, xác lập kết quả bất định bằng poll/callback/recovery, và phát hành lại chỉ sau definite failure; mọi luồng xử lý phải đảm bảo tính idempotency, không gọi MISA lần hai khi kết quả lần gọi trước chưa xác định, và cung cấp điểm tích hợp FE cho Theme 05.

**Kiến trúc (Architecture):** Slice 3 chỉ bắt đầu sau repair gate S2b. Repair gate dùng canonical `status = SUBMITTED` làm durable dispatch barrier; `submitted_at` chỉ được ghi ngay trước HTTP call qua RPC riêng, không thêm field vào `IssuanceAttempt`. Sales completion gọi `StartAutoIssuanceCommand` để tạo/load đúng một `AutomaticTriggerProcessRecord` và có thể tạo attempt đầu tiên; Partner profile update chỉ dispatch `ReevaluateAutoIssuanceCommand` để tiếp tục process `PENDING_REEVALUATION` hiện có. `RetryIssuanceCommand` tạo attempt mới chỉ sau terminal `FAILED`; nếu SalesOrder version không đổi thì reuse đúng `BuyerInvoiceCompletion LOCKED`, còn version đã đổi thì tuyệt đối không reuse completion cũ và phải đánh giá readiness/completion của version hiện hành. Mọi attempt mới được tạo trong authoritative Supabase transaction rồi enqueue `PublishInvoiceCommand`. `ReconciliationCase` giữ canonical fields; scheduled internal command dùng deterministic technical identity từ `{caseId, checkOrdinal}` và có thể tái tạo mà không thêm field vào case. `UNRESOLVED` kết thúc auto-poll nhưng không loại bỏ authoritative evidence: callback terminal hợp lệ đến muộn có thể giải quyết attempt và chuyển case sang `RESOLVED`, tuyệt đối không republish. FE chỉ gọi qua `IModuleMediator`, lấy tenant/user từ `IExecutionContext`, và dùng chung nhãn `Phát hành HĐĐT` cho mọi lần phát hành.

**Tech Stack:** Dart >=3.11.1 <4.0.0, Flutter, flutter_bloc, vet45_shared CQRS/inbox/internal commands, vet45_generator, Supabase/Postgres draft SQL, `packages/vet45_misa`, `apps/messaging_worker`, package:test, flutter_test.

**Tài liệu tham chiếu chuẩn (Canonical Inputs):** `docs/themes/TH-08-e-invoice/harness/04-slice-roadmap.md`, `01-domain-model.md`, `02-module-map.md`, `03-architecture-and-flows.md`, `05-traceability.md`, `07-api-contracts.md`, EP-02 US-03/US-04/US-05.

## Ràng buộc toàn cục (Global Constraints)

- Phạm vi của Slice bao gồm S3a (auto issue), S3b (reconciliation/result recovery), và S3c (retry). Không kéo tính năng tải tài liệu hóa đơn (S4), gửi hóa đơn / delivery (S5), hoặc trang sales mới của Theme 05 vào slice này.
- E2E của S3 vẫn bị block cho đến khi S2 có thể tạo ra durable issuance attempt và hóa đơn đã phát hành thành công. BE của S2 vẫn ở trạng thái `in_progress` khi draft 007 chưa được promote; kế hoạch này không được đánh dấu hành vi production DB là đã hoàn thành (shipped).
- Task 2 là repair gate bắt buộc trước mọi task feature S3: vì draft S2b 007 chưa được apply/promote, sửa trực tiếp draft 007 để sửa nghĩa `submitted_at`, bổ sung optimistic `version`, đóng băng đầy đủ schema `issuance_attempts`, và nối executable dead-letter path cho `COMMAND_INTEGRITY`; không tạo draft patch riêng cho một draft chưa phát hành. Không bắt đầu Task 3 trở đi nếu focused tests của repair gate chưa xanh.
- Các thay đổi SQL chỉ nằm trong thư mục `supabase/migrations/_drafts/`. Tuyệt đối không tạo timestamp migration, không tự ý promote draft, không chạy `supabase db reset`, và không giả định draft đã được apply trừ khi người dùng yêu cầu rõ ràng.
- `RecordIssuanceResultCommand` chỉ nhận `IssuanceResultEvidenceDto`, tuyệt đối không dùng kiểu tự do `Map<String, Object?>`. Luồng tiếp nhận callback chỉ lưu trữ allow-listed provider evidence; không lưu token, credential, header, signature secret, hoặc raw response body.
- Bất kỳ timeout, lỗi kết nối không rõ ràng (transport ambiguity), trùng provider reference, phản hồi sai định dạng (malformed response), hoặc worker crash sau khi đã vượt qua dispatch barrier của S2b đều phải đưa vào luồng đối soát (reconcile); tuyệt đối không tự động phát hành lại (republish).
- Mọi attempt mới nhất có `status = FAILED` đều là thất bại xác định và được phép mở lại flow `Phát hành HĐĐT` khi không có operation lock, chưa có ElectronicInvoice, và readiness hiện hành cho phép. Điều này bao gồm `COMMAND_INTEGRITY` hoặc lỗi system chắc chắn xảy ra trước provider call sau khi technical retry cạn. Lỗi xảy ra sau `SUBMITTED` hoặc không thể chứng minh provider chưa được gọi phải đi reconciliation và khóa phát hành mới. Các attempt trước đó cùng evidence của chúng là bất biến.
- Chính sách Polling cho reconciliation được cố định (frozen) cho bản MVP: thực hiện kiểm tra sau `30 seconds`, `2 minutes`, `10 minutes`, `30 minutes`, và `2 hours`; sau lần kiểm tra thứ 5 mà kết quả provider vẫn không xác định (inconclusive), đóng case với trạng thái `UNRESOLVED`, giữ nguyên lock, và yêu cầu can thiệp thủ công (operational review).
- `UNRESOLVED` chỉ là terminal của chu kỳ tự động kiểm tra, không phải evidence tombstone. Callback provider đến muộn chỉ được áp dụng nếu đã xác thực, correlate đúng tenant/attempt/idempotency identity và chứa terminal evidence hợp lệ: success/failure chuyển attempt từ `RECONCILING` sang terminal và case `UNRESOLVED -> RESOLVED`; undetermined, invalid hoặc unmatched callback giữ case `UNRESOLVED`. Nếu attempt đã terminal, callback duplicate/out-of-order trả kết quả hiện có và không được đảo ngược trạng thái.
- Retry phải phân nhánh theo SalesOrder version authoritative trong cùng transaction. Cùng version + completion `LOCKED` thì reuse chính completion/`EffectiveBuyerInvoiceData` đã khóa và không gọi Theme 03; version mới thì từ chối request mang `expectedOrderVersion` cũ, không join/reuse completion theo `sales_order_id` đơn thuần, và chỉ tạo attempt sau khi completion/readiness của version hiện hành đạt điều kiện.
- `invoice_reconciliation_cases` là nguồn authoritative của lịch đối soát. Các scheduled poll command sử dụng cơ chế due-time cục bộ của module: `einvoice.internal_commands.enqueued_at` là thời điểm đến hạn và `einvoice.claim_internal_commands_batch` chỉ claim bản ghi có `enqueued_at <= now()`. Mỗi worker tick phải seed idempotently command còn thiếu từ pending due case, để case có sẵn từ S2b hoặc command bị mất/dead-letter vẫn được tiếp quản; không tạo scheduler dùng chung toàn nền tảng trong S3.
- Luồng đánh giá lại Partner tiêu thụ `partner.partner.profile_updated`, nhưng event này không được tạo `AutomaticTriggerProcessRecord`, business issuance, hoặc provider idempotency identity mới. Nó chỉ tìm và tiếp tục process `PENDING_REEVALUATION` đúng `buyer_partner_id`. Luồng Sales completion dùng `sales.order.completed` và là nguồn duy nhất khởi tạo auto-issue process. Cả hai handler phải replay-safe.
- S3a và S3b không có trang UI riêng cho MVP (SG-04 tiếp tục chỉ chạy ở server-side). Presentation của S3c chỉ mở rộng component dòng/hành động dùng chung cho Theme 05.
- Widget mới trong `apps/erp/features/sales` là ranh giới tích hợp rõ ràng cho Theme 05. Không đánh dấu FE lane là `done` cho đến khi trang chủ thực tế của Theme 05 import component này; nếu trang chủ chưa có, ghi nhận FE là `in_progress` kèm bằng chứng component/widget test đã pass.
- Application layer không import Infrastructure layer. Domain layer không import Supabase, Flutter, GetIt, hay Domain của module khác. UI không gọi trực tiếp PostgREST.
- Không chỉnh sửa thủ công các file sinh tự động `.g.dart`; chạy codegen sau khi thay đổi annotation hoặc cấu hình build.
- Trước khi chỉnh sửa bất kỳ class/function/method nào hiện có, phải chạy GitNexus upstream impact cho symbol đó và báo cáo mức độ rủi ro (blast radius). Dừng lại hỏi ý kiến người dùng nếu rủi ro là HIGH/CRITICAL. Trước khi tạo commit đã được người dùng cho phép, chạy `detect_changes(scope: compare, base_ref: main)`.
- Các lệnh commit bên dưới chỉ là ranh giới review; chỉ thực thi khi đã có sự đồng ý của người dùng. Giữ nguyên các thay đổi không liên quan của người dùng.

---

## Giao diện chuẩn đóng băng của Slice 3 (Frozen Slice 3 Interfaces)

```dart
final class AutoIssuanceStartRequest {
  const AutoIssuanceStartRequest({
    required this.tenantId,
    required this.salesOrderId,
    required this.triggerKey,
    required this.idempotencyKey,
  });
  final String tenantId;
  final String salesOrderId;
  final String triggerKey;
  final String idempotencyKey;
}

final class AutoIssuanceReevaluationRequest {
  const AutoIssuanceReevaluationRequest({
    required this.tenantId,
    required this.processId,
    required this.sourceEventId,
  });
  final String tenantId;
  final String processId;
  final String sourceEventId;
}

final class OpenAutoIssuanceProcessDto {
  const OpenAutoIssuanceProcessDto({
    required this.processId,
    required this.buyerInvoiceCompletionId,
  });
  final String processId;
  final String buyerInvoiceCompletionId;
}

abstract interface class IAutoIssuanceGateway {
  Future<AutoIssuanceResultDto> start(AutoIssuanceStartRequest request);
  Future<AutoIssuanceResultDto> reevaluate(
    AutoIssuanceReevaluationRequest request,
  );
  Future<List<OpenAutoIssuanceProcessDto>> listOpenProcesses({
    required String tenantId,
    required String partnerId,
  });
}

sealed class MeInvoiceIssuanceStatusOutcome {
  const MeInvoiceIssuanceStatusOutcome();
  const factory MeInvoiceIssuanceStatusOutcome.success(
    IssuanceSuccessEvidenceDto evidence,
  ) = MeInvoiceIssuanceStatusSuccess;
  const factory MeInvoiceIssuanceStatusOutcome.definiteFailure(
    IssuanceDefiniteFailureEvidenceDto evidence,
  ) = MeInvoiceIssuanceStatusDefiniteFailure;
  const factory MeInvoiceIssuanceStatusOutcome.pending() =
      MeInvoiceIssuanceStatusPending;
  const factory MeInvoiceIssuanceStatusOutcome.undetermined(String reasonCode) =
      MeInvoiceIssuanceStatusUndetermined;
}

abstract interface class IIssuanceReconciliationGateway {
  Future<ReconciliationPollContextDto> claimDueCase({
    required String tenantId,
    required String caseId,
    required String workerId,
  });
  Future<RecordIssuanceResultDto> recordEvidence({
    required String tenantId,
    required String attemptId,
    required IssuanceResultEvidenceDto evidence,
    required String correlationId,
  });
  Future<ReconciliationCaseDto> recordPending({
    required String tenantId,
    required String caseId,
    required String claimToken,
    required DateTime nextCheckAt,
  });
  Future<ReconciliationCaseDto> markUnresolved({
    required String tenantId,
    required String caseId,
    required String claimToken,
    required String reasonCode,
  });
  Future<RecoverInternalFinalizationResultDto> recoverFinalization({
    required String tenantId,
    required String attemptId,
  });
  Future<IssuanceAttemptStatusDto> getAttemptStatus({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  });
}

final class IssuanceAttemptStatusDto {
  const IssuanceAttemptStatusDto({
    required this.status,
    required this.internalFinalizationStatus,
    required this.hasElectronicInvoice,
    required this.hasActiveOperation,
    required this.failureCode,
  });
  final IssuanceAttemptStatus status;
  final InternalFinalizationStatus internalFinalizationStatus;
  final bool hasElectronicInvoice;
  final bool hasActiveOperation;
  final String? failureCode;
}

final class PollIssuanceStatusCommand extends InternalCommandBase<void>
    implements ISerializableInternalCommand {
  PollIssuanceStatusCommand({
    super.id,
    required this.tenantId,
    required this.caseId,
    required this.attemptId,
    required this.correlationId,
  });
  @override
  final String tenantId;
  final String caseId;
  final String attemptId;
  final String correlationId;

  static const type = 'einvoice.poll_issuance_status';
  @override
  String get commandType => type;
  @override
  Map<String, dynamic> toJson() => stripInternalCommandRowId({
    'tenant_id': tenantId,
    'case_id': caseId,
    'attempt_id': attemptId,
    'correlation_id': correlationId,
  });
}
```

`ReconciliationPollContextDto` chỉ chứa `caseId`, `attemptId`, `claimToken`, `idempotencyKey`, `payloadHash`, `providerReference?`, `attemptCount`, và `maxAttempts`. `maxAttempts` luôn là `5` cho slice này.

## Quyết định DDD của Slice 3

1. **Lifecycle:** Sales completion tạo pre-attempt process → blocker giữ `PENDING_REEVALUATION` → Partner/readiness signal tiếp tục process đó → completion `LOCKED` → attempt đầu tiên → publish/result/reconciliation → attempt mới chỉ sau terminal `FAILED`.
2. **Bounded contexts:** Sales sở hữu SalesOrder/version và completion event; Partner sở hữu hồ sơ buyer và chỉ phát source-change signal; E-invoice sở hữu BuyerInvoiceCompletion, automatic process, InvoiceIssuance/Attempt và ReconciliationCase.
3. **Aggregates/entities:** `InvoiceIssuance` là aggregate root chứa lifecycle attempt; `ReconciliationCase` là process entity độc lập; `AutomaticTriggerProcessRecord` là shared technical preparation record, không phải business aggregate mới.
4. **Business rules:** source-change chỉ tiếp tục process mở; completion phải khóa trước attempt; tối đa một ORIGINAL issuance; mọi `FAILED` là definite; post-barrier ambiguity phải reconcile; retry cùng version reuse completion `LOCKED`, retry version mới phải resolve completion mới; callback terminal hợp lệ vẫn được nhận sau `UNRESOLVED`.
5. **Commands:** `StartAutoIssuanceCommand` bắt đầu process từ Sales; `ReevaluateAutoIssuanceCommand` tiếp tục process; `RetryIssuanceCommand` tạo attempt mới sau definite failure; poll/recovery commands không publish lại.
6. **Queries:** `listOpenProcesses(tenantId, partnerId)` trả technical process DTO; status/projection queries trả DTO/actions, không leak aggregate hoặc raw provider payload.
7. **Domain events:** attempt/result/finalization transitions phát domain events nội module theo aggregate commit; không dùng Partner signal như domain event của e-invoice.
8. **Integration events:** consume `sales.order.completed`, `partner.partner.profile_updated`, `einvoice.provider.issuance_result_received`; source events không trực tiếp ghi attempt/invoice.
9. **Domain services:** readiness policy, retry policy và reconciliation schedule là pure policy; orchestration event/worker nằm Application/Infrastructure.
10. **Snapshots/ports:** Application load authoritative Sales/version, Theme 01 seller/configuration và controlled Theme 03 missing buyer fields trước aggregate transition; attempt dùng immutable snapshot. Retry không sửa snapshot cũ: cùng version tạo snapshot mới từ đúng locked completion lineage, version mới dùng completion lineage của version mới.
11. **Anti-pattern warnings:** cấm Partner event tạo process mới; cấm technical field trên canonical entities; cấm provider-only retry gate; cấm post-barrier republish.
12. **Review gate:** Task 1 đóng băng các quyết định trên; Tasks 2/4/5/7/9/10/12 có RED tests tương ứng trước khi lane được đóng ở Task 13.

## Cấu trúc thư mục và Trách nhiệm (File Structure and Responsibilities)

```text
modules/sales/integration_events/                 Hợp đồng sự kiện nguồn sales.order.completed có kiểu rõ ràng
modules/partner/integration_events/               Hỗ trợ payload cho partner.profile_updated
modules/einvoice/integration_events/              Envelope callback an toàn từ provider
modules/einvoice/application/lib/src/issuance/     Các S3 commands, handlers, validators, policies, ports
modules/einvoice/infrastructure/lib/src/domain/    Supabase gateways và RPC mappers
modules/einvoice/infrastructure/lib/src/adapters/  Bộ phân loại/adapter MISA getStatus
modules/einvoice/infrastructure/lib/src/configuration/processing/
                                                   Inbox dispatcher + internal command registry
modules/einvoice/presentation/lib/src/widgets/     Failed-attempt copy/banner/sheets
apps/erp/lib/features/sales/presentation/          Integration component do Theme 05 sở hữu
supabase/migrations/_drafts/007_einvoice_s2b_schema_and_rpc.sql
supabase/migrations/_drafts/008_einvoice_s3a_s3c_start_and_retry.sql
supabase/migrations/_drafts/009_einvoice_s3b_reconciliation.sql
```

---

### Task 1: Đóng băng Hợp đồng Slice 3, Chính sách Lịch trình, và Traceability

**Files:**
- Modify: `docs/themes/TH-08-e-invoice/Theme-8-e-invoice.md`
- Modify: `docs/themes/TH-08-e-invoice/harness/01-domain-model.md`
- Modify: `docs/themes/TH-08-e-invoice/harness/02-module-map.md`
- Modify: `docs/themes/TH-08-e-invoice/harness/03-architecture-and-flows.md`
- Modify: `docs/themes/TH-08-e-invoice/harness/04-slice-roadmap.md`
- Modify: `docs/themes/TH-08-e-invoice/harness/05-traceability.md`
- Modify: `docs/themes/TH-08-e-invoice/harness/07-api-contracts.md`
- Test: `scripts/ci/guard_theme_traceability.sh`
- Test: `scripts/ci/guard_theme_structure.sh`

**Kết quả đạt được:** Một hợp đồng rõ ràng, duy nhất cho các sự kiện nguồn, semantics của `submitted_at`, canonical attempt schema, typed result evidence, nhịp độ poll, callback an toàn, điều kiện retry, và phân định quyền sở hữu lane.

- [ ] **Step 1: Thu thập bằng chứng trước khi thay đổi (Capture pre-change evidence)**

```bash
rg -n "sales.order.completed|partner.profile_updated|RecordIssuanceResultCommand|poll_issuance_status|RetryIssuanceCommand|submitted_at|PROCESSING|version" docs/themes/TH-08-e-invoice/harness docs/themes/TH-08-e-invoice/Theme-8-e-invoice.md
```

Kết quả mong đợi: ghi nhận rõ Theme định nghĩa `submitted_at` là thời điểm gọi provider, mọi persisted entity có `version bigint`, roadmap/API text còn drift `PROCESSING`, và code hiện tại chưa nối RPC `COMMAND_INTEGRITY` vào worker dead-letter composition.

- [ ] **Step 2: Đóng băng event payloads và cơ chế tự động đánh giá lại (automatic re-evaluation)**

Thêm các dòng sau vào module map/API contracts:

```markdown
| `sales.order.completed` | tenantId, salesOrderId, sourceVersion, occurredAt | StartAutoIssuanceCommand |
| `partner.partner.profile_updated` | tenantId, partnerId, occurredAt | Tìm process `PENDING_REEVALUATION` đúng buyer và dispatch `ReevaluateAutoIssuanceCommand`; không tạo process mới |
| `einvoice.provider.issuance_result_received` | tenantId, attemptId, correlationId, typedEvidence | RecordIssuanceResultCommand |
```

Quy định identity ổn định: Sales completion tạo process với `triggerKey = sales.order.completed:<eventId>:<salesOrderId>:<sourceVersion>`; provider `RefID` dùng UUIDv5 namespace `514eaf96-eed8-5f7b-9705-4a840c910684` trên `<tenantId>|<salesOrderId>|<sourceVersion>`. Partner event chỉ dùng `sourceEventId = <eventId>` để dedupe inbox/re-evaluation; nó phải load `processId`, original `triggerKey` và provider idempotency key từ `AutomaticTriggerProcessRecord`, tuyệt đối không suy diễn business identity mới từ Partner event.

- [ ] **Step 3: Đóng băng semantics barrier/timestamp và canonical attempt schema**

Ghi cùng một định nghĩa vào domain model, architecture flow và API contracts:

```text
PREPARING --prepare_issuance_publish--> SUBMITTED
  status SUBMITTED is the durable no-republish barrier; does not set submitted_at
SUBMITTED --mark_issuance_provider_call_started immediately before HTTP--> SUBMITTED
  sets submitted_at once
provider accepted/pending --> WAITING_RESULT
replay at SUBMITTED/WAITING_RESULT --> RECONCILE_ONLY; never publish again
```

Liệt kê đúng và chỉ dùng 31 field canonical của `issuance_attempts`: convention `id`, `tenant_id`, `created_at`, `updated_at`, `version`; và các field business `invoice_issuance_id`, `attempt_no`, `trigger_type`, `status`, `provider_connection_id`, `issuance_profile_id`, `idempotency_key`, `intent_hash`, `snapshot_schema_version`, `attempt_snapshot`, `canonical_model_version`, `canonical_payload_hash`, `provider_interaction_reference`, `provider_request_reference`, `provider_invoice_reference`, `provider_result_code`, `provider_result_message`, `failure_code`, `failure_message`, `internal_finalization_state`, `started_at`, `submitted_at`, `provider_confirmed_at`, `completed_at`, `initiated_by_actor_type`, `initiated_by_actor_id`. Không thêm barrier/failure-origin field vào entity.

`AttemptSnapshot` phải có đủ: `source_order`, `seller`, `buyer`, `buyer_lineage`, `invoice_context`, `lines`, `totals`, `payment_information?`, `automation_policy`, `readiness_result`, và `mapping_schema_version`; không được viết rút gọn thành “canonical payload”.

Đóng băng `AutomaticTriggerProcessRecord` là shared technical record trước attempt, với contract tối thiểu: tenant, process type, SalesOrder, SalesOrder version, original trigger key, process status, retry count, next retry, blocker, BuyerInvoiceCompletion reference khi có, claim lock và timestamps; persisted implementation có `id`/`version` và stable provider idempotency key. Chỉ `sales.order.completed` được insert record. Partner/readiness signal chỉ claim/update record `PENDING_REEVALUATION` hiện có.

- [ ] **Step 4: Đóng băng hợp đồng poll/recovery và durable handoff**

Tài liệu hóa chính xác các khoảng thời gian chờ `[30s, 2m, 10m, 30m, 2h]`, quyền sở hữu claim-token, hành vi đánh dấu `UNRESOLVED` ở lần kiểm tra thứ 5, và việc sử dụng due-time qua `internal_commands.enqueued_at`. Khẳng định pending `ReconciliationCase` là nguồn authoritative; internal command có thể tái tạo bằng sweeper/seed và không thay thế case. Thêm invariant: callback và poll có thể race, nhưng chỉ một terminal transition thắng; bên thua nhận lại kết quả đã ghi trước đó.

Ghi rõ contract amendment còn thiếu và đồng bộ nó vào Theme master cùng harness: bổ sung state transition `ReconciliationCase UNRESOLVED -> RESOLVED` chỉ khi có callback terminal đã xác thực/correlate đúng. `UNRESOLVED` dừng seed/poll tự động và vẫn giữ business lock; success muộn hoàn tất attempt/invoice/finalization mà không publish lại, definite failure muộn kết thúc attempt/case rồi projection mới có thể mở action `issue`, còn evidence chưa xác định/không hợp lệ không đổi state. Callback đến sau `SUCCEEDED`/`FAILED` hoặc case `RESOLVED` là idempotent/no-op và không được đảo kết quả.

- [ ] **Step 5: Chuẩn hóa ranh giới typed command và canonical failed/processing projection**

Thay thế mô tả cũ bằng:

```markdown
| `RecordIssuanceResultCommand` | tenantId, attemptId, `IssuanceResultEvidenceDto evidence`, correlationId | `RecordIssuanceResultDto` | NOT_FOUND, INVALID_STATUS, IDEMPOTENCY_CONFLICT, SYSTEM_ERROR |
```

Khẳng định rõ ràng: các callback được chuẩn hóa trước khi dispatch và raw provider payload không phải là input của command cũng như không được lưu trữ vào evidence.

Đóng băng projection/retry contract: mọi latest attempt `FAILED` và không còn active operation trả `displayState = failed`, safe `failureCode`, và `actions = ['issue']`; command phát hành luôn recheck permission/readiness/no-invoice. `COMMAND_INTEGRITY` hoặc system failure chắc chắn trước provider call cũng tuân theo rule này sau khi technical retry cạn. Trạng thái `SUBMITTED`, `WAITING_RESULT`, `RECONCILING`, pending/`UNRESOLVED` reconciliation trả `processing` và `actions = []`. Không thêm `failureOrigin` hoặc provider-only retry gate.

- [ ] **Step 6: Sửa text drift và bổ sung scenario ID**

Sửa `04-slice-roadmap.md` và fake contract trong `07-api-contracts.md`: `IssueInvoiceCommand` trả canonical `IssuanceAttemptStatus` là `PREPARING` cho attempt mới hoặc trạng thái hiện tại của attempt khi replay; không dùng từ `PROCESSING` như attempt status. `processing` chỉ còn là display projection.

Sử dụng nhất quán các ID này trong traceability và test:

```text
scn_e02_u03_fr01_01  sales completion kích hoạt auto issue
scn_e02_u03_fr09_01  cập nhật partner đánh giá lại open completion
scn_e02_u04_fr08_01  kết quả chưa rõ được poll thành công
scn_e02_u04_fr08_02  poll không xác định lần thứ 5 chuyển sang unresolved
scn_e02_u04_fr08_03  phục hồi local finalization không gọi lại provider
scn_e02_u04_fr01_02  callback terminal hợp lệ đến sau unresolved giải quyết case, không republish
scn_e02_u05_fr04_01  attempt thất bại tạo attempt mới và bảo toàn lịch sử
scn_e02_u05_sc11_01  retry cùng version reuse completion locked, không resolve Theme 03
scn_e02_u05_sc12_01  retry version mới không dùng completion của version cũ
wgt_e02_u05_fr02_01  dòng thất bại sử dụng action issue thông thường
e2e_e02_u03_sc01_01  luồng từ completion đến publish
e2e_e02_u04_sc01_01  luồng từ poll đến electronic invoice
e2e_e02_u05_sc01_01  luồng từ definite failure đến retry
s2b_command_integrity_dead_letter_01  canonical mismatch dead-letter thành system failure không retry
```

Giữ nguyên trạng thái các lane S3 ở task này; trạng thái chỉ được cập nhật ở Task 13 sau khi đã có đầy đủ bằng chứng kiểm thử.

- [ ] **Step 7: Kiểm tra harness và source-text contract**

```bash
bash scripts/ci/guard_theme_traceability.sh
bash scripts/ci/guard_theme_structure.sh
! rg -n "IssueInvoice(Command)?.*PROCESSING|attempt mới.*PROCESSING" docs/themes/TH-08-e-invoice/harness
git diff --check
```

- [ ] **Step 8: Ranh giới Commit (chỉ khi có ủy quyền)**

```bash
git add docs/themes/TH-08-e-invoice/harness
git commit -m "docs(einvoice): freeze slice 3 execution contracts"
```

---

### Task 2: Sửa trực tiếp Draft S2b chưa promote trước khi triển khai Slice 3

**Files:**
- Modify: `supabase/migrations/_drafts/007_einvoice_s2b_schema_and_rpc.sql`
- Delete: `supabase/migrations/_drafts/008_einvoice_s2b_contract_repair.sql` sau khi toàn bộ repair đã được fold vào draft 007
- Modify: `modules/einvoice/application/lib/src/issuance/commands/publish_invoice/publish_invoice_command_handler.dart`
- Create: `modules/einvoice/application/lib/src/issuance/shared/canonical_invoice_integrity_exception.dart`
- Modify: `modules/einvoice/application/lib/src/ports/i_issuance_result_gateway.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/domain/issuance/supabase_issuance_result_gateway.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/domain/issuance/issuance_rpc_mapper.dart`
- Modify: `modules/einvoice/application/lib/src/shared/order_invoice_projection_dto.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/domain/issuance/supabase_order_invoice_projection_read_gateway.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/configuration/processing/internal_commands/i_einvoice_internal_command_client.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/configuration/processing/internal_commands/supabase_einvoice_internal_command_client.dart`
- Create: `modules/einvoice/infrastructure/lib/src/configuration/processing/internal_commands/i_einvoice_internal_command_dead_letter_handler.dart`
- Create: `modules/einvoice/infrastructure/lib/src/configuration/processing/internal_commands/publish_invoice_command_dead_letter_handler.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/configuration/processing/internal_commands/process_internal_commands_command_handler.dart`
- Modify: `modules/einvoice/application/lib/src/issuance/queries/get_issuance_attempt_status/issuance_attempt_status_dto.dart`
- Test: `modules/einvoice/infrastructure/test/domain/issuance/einvoice_s2b_repair_sql_contract_test.dart`
- Test: `modules/einvoice/application/test/issuance/publish_invoice_command_handler_test.dart`
- Test: `modules/einvoice/infrastructure/test/configuration/einvoice_publish_dead_letter_test.dart`
- Test: `modules/einvoice/infrastructure/test/domain/issuance/supabase_issuance_result_gateway_test.dart`
- Create: `modules/einvoice/infrastructure/test/domain/issuance/supabase_order_invoice_projection_read_gateway_test.dart`

**Kết quả đạt được:** S2b có schema đúng Theme, audit timestamp đúng nghĩa, canonical `SUBMITTED` no-republish barrier, bounded retry/dead-letter thực thi được, và projection cung cấp lại action cho mọi definite `FAILED` sau khi lock được giải phóng.

- [ ] **Step 1: Chạy impact analysis trước khi sửa symbol hiện có**

Chạy GitNexus upstream impact cho `PublishInvoiceCommandHandler`, `IIssuanceResultGateway`, `SupabaseIssuanceResultGateway`, `IssuanceRpcMapper`, `ClaimedInternalCommand`, `IEinvoiceInternalCommandClient`, và `ProcessInternalCommandsCommandHandler`. Báo cáo direct callers/execution flows; dừng lại nếu rủi ro HIGH/CRITICAL.

- [ ] **Step 2: Viết RED schema/SQL contract tests cho canonical fields và version**

Test phải parse draft 007 và assert bốn bảng `invoice_issuances`, `issuance_attempts`, `electronic_invoices`, `invoice_reconciliation_cases` đều khai báo trực tiếp `version bigint not null default 0` trong `create table`. Mỗi RPC state mutation trong draft phải dùng row lock và `version = version + 1`.

Với `issuance_attempts`, assert đầy đủ 31 field canonical đã đóng băng ở Task 1 (5 field convention + 26 field business). Thêm negative assertions để draft không tạo `dispatch_barrier_crossed_at`, `failure_origin`, hoặc field implementation-only khác trên entity. Assert `attempt_snapshot` có đủ 11 component, bao gồm `lines` và `totals`; test phải fail nếu thiếu hoặc thêm sai contract.

- [ ] **Step 3: Viết RED tests cho barrier và `submitted_at`**

```dart
test('provider call timestamp is written only immediately before HTTP', () async {
  final log = <String>[];
  final gateway = FakeIssuanceResultGateway(log: log);
  final provider = FakeProviderPort(log: log);
  await PublishInvoiceCommandHandler(gateway, provider).handle(command);
  expect(log, [
    'validateCanonical',
    'prepareBarrier',
    'markProviderCallStarted',
    'provider.publish',
  ]);
});

test('failure to mark provider-call start never calls HTTP', () async {
  final provider = FakeProviderPort();
  await expectLater(
    handlerWithMarkFailure.handle(command),
    throwsA(isA<Exception>()),
  );
  expect(provider.publishCount, 0);
});
```

SQL contract assert `prepare_issuance_publish` chỉ chuyển `PREPARING -> SUBMITTED`, tăng `version` và không ghi `submitted_at`; chính persisted status `SUBMITTED` là barrier. Replay ở `SUBMITTED`/`WAITING_RESULT` trả `RECONCILE_ONLY`. Mở rộng `IIssuanceResultGateway` bằng `markProviderCallStarted(tenantId, attemptId)`. RPC `mark_issuance_provider_call_started` chỉ chấp nhận `SUBMITTED`, set `submitted_at = coalesce(submitted_at, now())`, tăng `version`, và được handler gọi ngay trước HTTP.

- [ ] **Step 4: Fold repair trực tiếp vào draft 007 chưa promote và loại bỏ draft vá 008**

Header `-- Touches:` phải khớp chính xác mọi RPC được `create or replace`:

```text
einvoice.prepare_issuance_publish
einvoice.mark_issuance_provider_call_started
einvoice.record_issuance_success
einvoice.record_issuance_failure
einvoice.record_issuance_command_integrity_failure
einvoice.record_publish_command_dead_letter
einvoice.record_issuance_undetermined
einvoice.get_order_invoice_projection
einvoice.claim_internal_commands_batch
einvoice.retry_or_dead_letter_internal_command
```

Vì draft 007 chưa được apply/promote, sửa trực tiếp các `create table` trong draft này để bổ sung canonical `version bigint not null default 0`; không dùng `alter table` vá một draft chưa phát hành và không thêm field khác vào `IssuanceAttempt` hoặc `ReconciliationCase`. Fold toàn bộ body RPC repair từ draft 008 hiện tại vào đúng RPC owner trong draft 007, cập nhật header `-- Touches:` của 007 cho khớp chính xác, rồi xóa file `008_einvoice_s2b_contract_repair.sql` dư thừa. `record_publish_command_dead_letter` khóa attempt và quyết định bằng canonical status: `PREPARING` chứng minh chưa qua provider barrier nên ghi `FAILED` với safe system `failure_code`; `SUBMITTED`/`WAITING_RESULT` mở hoặc tiếp tục pending reconciliation; cả hai nhánh đều không enqueue publish. `record_issuance_success`, `record_issuance_failure`, và `record_issuance_undetermined` chấp nhận terminal evidence hợp lệ ở `SUBMITTED`/`WAITING_RESULT`. `get_order_invoice_projection` trả safe `failure_code`; mọi latest `FAILED` không còn lock có `actions = ['issue']`, còn reconciliation/unknown có `actions = []`.

- [ ] **Step 5: Nối bounded retry và executable dead-letter composition**

Mở rộng `ClaimedInternalCommand` với `retryCount`; `claim_internal_commands_batch` phải trả field này và tôn trọng `enqueued_at <= now()`. Thay `fail(...)` bằng `retryOrDeadLetter(...)` trả enum `RETRY`/`DEAD_LETTER`. Chính sách cố định: tối đa 3 lần xử lý, backoff `5s`, `30s`; lần thứ 3 ghi `failed_at`, các lần trước clear claim và dời `enqueued_at`.

Mở rộng `IIssuanceResultGateway` bằng hai method có kiểu rõ ràng: `recordCommandIntegrityFailure(tenantId, attemptId, reasonCode)` và `recordPublishCommandDeadLetter(tenantId, attemptId, reasonCode)`. `PublishInvoiceCommandHandler` ném `CanonicalInvoiceIntegrityException` có `attemptId`/safe `reasonCode` khi canonical validation fail trước barrier. `ProcessInternalCommandsCommandHandler` phân loại lỗi, gọi `retryOrDeadLetter`, và chỉ khi disposition là `DEAD_LETTER` mới dispatch đúng handler theo `commandType`. `PublishInvoiceCommandDeadLetterHandler` gọi method integrity cho canonical mismatch; với lỗi khác gọi `recordPublishCommandDeadLetter`, để DB quyết định theo persisted barrier và tuyệt đối không ghi provider definite failure.

- [ ] **Step 6: Viết RED/green tests cho `COMMAND_INTEGRITY` và projection**

Bao quát:

```text
s2b_command_integrity_dead_letter_01:
  canonical mismatch lặp đến lần xử lý thứ 3
  -> internal command DEAD_LETTER
  -> record_issuance_command_integrity_failure đúng 1 lần
  -> attempt FAILED/failure_code COMMAND_INTEGRITY/actions ['issue']
  -> provider publishCount == 0

provider definite failure:
  -> attempt FAILED/safe provider failure_code/actions ['issue']

unexpected terminal worker failure after barrier:
  -> pending ReconciliationCase
  -> không map thành provider definite failure
  -> không enqueue publish command mới
```

- [ ] **Step 7: Xác thực repair gate trước Slice 3**

```bash
dart test modules/einvoice/infrastructure/test/domain/issuance/einvoice_s2b_repair_sql_contract_test.dart
dart test modules/einvoice/application/test/issuance/publish_invoice_command_handler_test.dart
dart test modules/einvoice/infrastructure/test/configuration/einvoice_publish_dead_letter_test.dart
dart test modules/einvoice/infrastructure/test/domain/issuance/supabase_issuance_result_gateway_test.dart
dart test modules/einvoice/infrastructure/test/domain/issuance/supabase_order_invoice_projection_read_gateway_test.dart
dart analyze modules/einvoice/application modules/einvoice/infrastructure
git diff --check
```

- [ ] **Step 8: Ranh giới Commit (chỉ khi có ủy quyền)**

```bash
git add supabase/migrations/_drafts/007_einvoice_s2b_schema_and_rpc.sql modules/einvoice/application modules/einvoice/infrastructure
git commit -m "fix(einvoice): repair issuance processing contracts"
```

---

### Task 3: Thêm Typed Cross-Module Event Envelopes

**Files:**
- Create: `modules/sales/integration_events/lib/src/sales_order_completed_integration_event.dart`
- Modify: `modules/sales/integration_events/lib/integration_events.dart`
- Modify: `modules/sales/integration_events/pubspec.yaml`
- Modify: `modules/partner/integration_events/lib/src/partner_profile_updated_integration_event.dart`
- Create: `modules/einvoice/integration_events/lib/src/provider_issuance_result_received_integration_event.dart`
- Modify: `modules/einvoice/integration_events/lib/integration_events.dart`
- Test: `modules/sales/integration_events/test/sales_order_completed_integration_event_test.dart`
- Test: `modules/partner/integration_events/test/partner_profile_updated_integration_event_test.dart`
- Test: `modules/einvoice/integration_events/test/provider_issuance_result_received_integration_event_test.dart`

**Kết quả đạt được:** Các envelope đầu vào có kiểu rõ ràng và an toàn khi replay; việc dispatch inbox sẽ được gắn kết sau khi các application handlers hoàn thành ở Task 4.

- [ ] **Step 1: Chạy impact analysis trước khi sửa symbol hiện có**

Chạy GitNexus upstream impact cho `PartnerProfileUpdatedIntegrationEvent` và 3 file barrel của các package integration-event. Báo cáo các direct callers/processes và dừng lại nếu rủi ro là HIGH/CRITICAL.

- [ ] **Step 2: Viết các RED serialization tests**

```dart
test('sales completion round-trips its authoritative identity', () {
  final event = SalesOrderCompletedIntegrationEvent(
    id: 'event-1',
    occurredOn: DateTime.utc(2026, 8, 28),
    tenantId: 'tenant-1',
    salesOrderId: 'order-1',
    sourceVersion: 'sales:v17',
  );
  final decoded = SalesOrderCompletedIntegrationEvent.fromPayload(
    event.toPayload(),
  );
  expect(decoded.id, event.id);
  expect(decoded.salesOrderId, event.salesOrderId);
  expect(decoded.sourceVersion, event.sourceVersion);
});

test('callback payload excludes raw provider data', () {
  final payload = ProviderIssuanceResultReceivedIntegrationEvent.success(
    id: 'event-2', occurredOn: DateTime.utc(2026, 8, 28),
    tenantId: 'tenant-1', attemptId: 'attempt-1', correlationId: 'corr-1',
    idempotencyKey: '6e60dfa0-c244-40fd-b73e-65112cb73a96',
    payloadHash: 'sha256:invoice-1', providerReference: 'misa-1',
    invoiceNumber: '00000123', invoiceSeries: '1C26TVE',
    issuedAt: DateTime.utc(2026, 8, 28),
  ).toPayload();
  expect(payload, isNot(contains('raw_response')));
  expect(payload, isNot(contains('access_token')));
});
```

- [ ] **Step 3: Triển khai các typed events**

Mỗi event định nghĩa một hằng số tên type, `toPayload`, và `fromPayload`; sử dụng định dạng thời gian UTC ISO-8601 và từ chối các trường định danh bị trống/thiếu. Nâng cấp event partner hiện có mà không làm thay đổi chuỗi type string của nó.

- [ ] **Step 4: Chạy focused serialization tests và codegen**

```bash
dart test modules/sales/integration_events/test
dart test modules/partner/integration_events/test
dart test modules/einvoice/integration_events/test
melos run codegen
git diff --check
```

- [ ] **Step 5: Ranh giới Commit (chỉ khi có ủy quyền)**

```bash
git add modules/sales/integration_events modules/partner/integration_events modules/einvoice/integration_events
git commit -m "feat(einvoice): define typed slice 3 integration events"
```

---

### Task 4: Triển khai S3a Auto-Issuance Application Flow

**Files:**
- Create: `modules/einvoice/application/lib/src/issuance/commands/start_auto_issuance/auto_issuance_start_request.dart`
- Modify: `modules/einvoice/application/lib/src/issuance/commands/start_auto_issuance/start_auto_issuance_command.dart`
- Create: `modules/einvoice/application/lib/src/issuance/commands/start_auto_issuance/start_auto_issuance_command_validator.dart`
- Create: `modules/einvoice/application/lib/src/issuance/commands/start_auto_issuance/start_auto_issuance_command_handler.dart`
- Create: `modules/einvoice/application/lib/src/issuance/commands/reevaluate_auto_issuance/reevaluate_auto_issuance_command.dart`
- Create: `modules/einvoice/application/lib/src/issuance/commands/reevaluate_auto_issuance/reevaluate_auto_issuance_command_validator.dart`
- Create: `modules/einvoice/application/lib/src/issuance/commands/reevaluate_auto_issuance/reevaluate_auto_issuance_command_handler.dart`
- Create: `modules/einvoice/application/lib/src/issuance/dtos/open_auto_issuance_process_dto.dart`
- Create: `modules/einvoice/application/lib/src/issuance/shared/auto_issuance_idempotency_key.dart`
- Create: `modules/einvoice/application/lib/src/ports/i_auto_issuance_gateway.dart`
- Create: `modules/einvoice/application/lib/src/ports/i_einvoice_command_dispatcher.dart`
- Create: `modules/einvoice/application/lib/src/issuance/integration_events/sales_order_completed_integration_event_handler.dart`
- Create: `modules/einvoice/application/lib/src/issuance/integration_events/partner_profile_updated_integration_event_handler.dart`
- Modify: `modules/einvoice/application/pubspec.yaml`
- Modify: `modules/einvoice/application/lib/application.dart`
- Create: `modules/einvoice/infrastructure/lib/src/configuration/processing/einvoice_integration_event_dispatcher.dart`
- Create: `modules/einvoice/infrastructure/lib/src/configuration/processing/einvoice_command_dispatcher.dart`
- Modify: `modules/einvoice/infrastructure/build.yaml`
- Modify: `modules/einvoice/infrastructure/lib/src/configuration/processing/inbox/process_inbox_command_handler.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/configuration/processing/processing_module.dart`
- Test: `modules/einvoice/application/test/issuance/start_auto_issuance_command_handler_test.dart`
- Test: `modules/einvoice/application/test/issuance/reevaluate_auto_issuance_command_handler_test.dart`
- Test: `modules/einvoice/application/test/issuance/auto_issuance_idempotency_key_test.dart`
- Test: `modules/einvoice/application/test/issuance/auto_issuance_integration_event_handlers_test.dart`
- Test: `modules/einvoice/infrastructure/test/configuration/einvoice_inbox_dispatch_test.dart`

**Kết quả đạt được:** Sales completion bắt đầu đúng một auto-issue preparation process; Partner update chỉ tiếp tục process mở hiện có qua command re-evaluate; cả hai đi qua CQRS pipeline và không tạo process/attempt cạnh tranh.

- [ ] **Step 1: Chạy impact analysis trước khi sửa symbol hiện có**

Chạy GitNexus upstream impact cho `StartAutoIssuanceCommand`, `ProcessInboxCommandHandler`, `EinvoiceProcessingModule`, `EinvoiceModuleDefinition`, và application barrel file. Báo cáo callers/processes và dừng lại nếu rủi ro là HIGH/CRITICAL.

- [ ] **Step 2: Viết các RED validator và handler tests**

```dart
test('scn_e02_u03_fr01_01 forwards stable trigger identity', () async {
  final gateway = FakeAutoIssuanceGateway.started();
  final result = await StartAutoIssuanceCommandHandler(gateway).handle(
    StartAutoIssuanceCommand(
      tenantId: 'tenant-1', salesOrderId: 'order-1',
      triggerKey: 'sales.order.completed:event-1:order-1:sales-v17',
      idempotencyKey: 'a6547397-1158-5873-a825-9ee320d9fcc5',
    ),
  );
  expect(result.started, isTrue);
  expect(gateway.lastRequest!.salesOrderId, 'order-1');
});

test('policy-off is a successful skip, not an exception', () async {
  final result = await StartAutoIssuanceCommandHandler(
    FakeAutoIssuanceGateway.skipped('POLICY_OFF'),
  ).handle(validCommand);
  expect((result.started, result.reason), (false, 'POLICY_OFF'));
});
```

Validator từ chối các trường tenant/order/trigger/key bị trống và provider key không đúng định dạng UUID. Kiểm tra việc sinh UUIDv5 phải đảm bảo tính ổn định cho cùng một bộ dữ liệu đầu vào và thay đổi khi source version thay đổi. Kiểm thử các scenario: `auto_issue_started`, `auto_issue_skipped_policy_off`, `auto_issue_skipped_not_ready`, và duplicate trigger replay.

Viết thêm RED tests cho `ReevaluateAutoIssuanceCommandHandler`: request chỉ chứa `tenantId`, existing `processId`, `sourceEventId`; replay cùng Partner event trả process/result hiện có; không có API nào cho re-evaluation truyền `triggerKey`, provider idempotency key hoặc tạo process mới.

```dart
test('partner update continues an existing process without start dispatch', () async {
  final gateway = FakeAutoIssuanceGateway.withOpenProcess('process-1');
  final commands = FakeEinvoiceCommandDispatcher();
  await PartnerProfileUpdatedIntegrationEventHandler(gateway, commands)
      .handle(partnerUpdatedEvent);
  expect(commands.startAutoIssuanceCalls, isEmpty);
  expect(commands.reevaluateCalls.single.processId, 'process-1');
  expect(commands.reevaluateCalls.single.sourceEventId, partnerUpdatedEvent.id);
});

@RequiresTenant()
final class ReevaluateAutoIssuanceCommand
    extends CommandBase<AutoIssuanceResultDto>
    implements ICommand<AutoIssuanceResultDto>, ITenantScopedCommand {
  ReevaluateAutoIssuanceCommand({
    String? id,
    required this.tenantId,
    required this.processId,
    required this.sourceEventId,
  }) : super(id);

  @override
  final String tenantId;
  final String processId;
  final String sourceEventId;
}

@CommandHandlerFor(ReevaluateAutoIssuanceCommand)
final class ReevaluateAutoIssuanceCommandHandler implements
    ICommandHandler<ReevaluateAutoIssuanceCommand, AutoIssuanceResultDto> {
  ReevaluateAutoIssuanceCommandHandler(this._gateway);
  final IAutoIssuanceGateway _gateway;

  @override
  Future<AutoIssuanceResultDto> handle(
    ReevaluateAutoIssuanceCommand command,
  ) => _gateway.reevaluate(AutoIssuanceReevaluationRequest(
    tenantId: command.tenantId,
    processId: command.processId,
    sourceEventId: command.sourceEventId,
  ));
}
```

- [ ] **Step 3: Triển khai thin handler và gateway contract**

Đổi field `StartAutoIssuanceCommand.triggerId` thành canonical `triggerKey` trên command, validator và request; đây là original Sales completion identity được lưu vào process record, không phải Partner event identity.

```dart
@CommandHandlerFor(StartAutoIssuanceCommand)
final class StartAutoIssuanceCommandHandler
    implements ICommandHandler<StartAutoIssuanceCommand, AutoIssuanceResultDto> {
  StartAutoIssuanceCommandHandler(this._gateway);
  final IAutoIssuanceGateway _gateway;

  @override
  Future<AutoIssuanceResultDto> handle(StartAutoIssuanceCommand command) =>
      _gateway.start(AutoIssuanceStartRequest(
        tenantId: command.tenantId,
        salesOrderId: command.salesOrderId,
        triggerKey: command.triggerKey,
        idempotencyKey: command.idempotencyKey,
      ));
}
```

- [ ] **Step 4: Triển khai event handlers**

Sales completion dispatch duy nhất một `StartAutoIssuanceCommand`. Partner update gọi `listOpenProcesses(tenantId, partnerId)`, chỉ nhận process `PENDING_REEVALUATION` đã tồn tại, rồi dispatch `ReevaluateAutoIssuanceCommand`; không truy vấn trực tiếp bảng Partner/Sales và không tạo business identity mới. Port dispatcher nằm ở Application; Infrastructure adapter ủy quyền cho scoped `CommandBus` để validator/access decorator vẫn chạy.

```dart
for (final process in openProcesses) {
  await _commands.execute(ReevaluateAutoIssuanceCommand(
    tenantId: event.tenantId,
    processId: process.processId,
    sourceEventId: event.id,
  ));
}
```

`ReevaluateAutoIssuanceCommandHandler` gọi `IAutoIssuanceGateway.reevaluate`. Gateway/RPC load original SalesOrder version, trigger key, completion reference và provider idempotency key từ process row. Khi readiness đạt, cùng transaction khóa completion, chuyển process sang `ATTEMPT_STARTED`, tạo attempt đầu tiên và enqueue publish; nếu vẫn blocked, cập nhật blocker/next retry trên chính process đó.

- [ ] **Step 5: Thay thế inbox stub bằng generated dispatch**

Làm theo pattern `IamIntegrationEventDispatcher` và registry của module IAM. Cấu hình `cqrs_integration_event_registry` với các package sự kiện `vet45_sales_integration_events`, `vet45_partner_integration_events`, và `vet45_einvoice_integration_events`. Chuẩn hóa các giá trị mặc định của envelope, deserialize bằng `EinvoiceIntegrationEventRegistry.fromJson`, xác thực event ID khớp với message ID, publish, sau đó hoàn tất. Các event lạ hoặc sai định dạng phải được fail-safe; việc nhận trùng lặp event phải hoàn tất mà không tạo thêm business attempt thứ hai.

- [ ] **Step 6: Xác thực Application và Inbox processing**

```bash
dart test modules/einvoice/application/test/issuance/start_auto_issuance_command_handler_test.dart
dart test modules/einvoice/application/test/issuance/reevaluate_auto_issuance_command_handler_test.dart
dart test modules/einvoice/application/test/issuance/auto_issuance_idempotency_key_test.dart
dart test modules/einvoice/application/test/issuance/auto_issuance_integration_event_handlers_test.dart
melos run codegen
dart test modules/einvoice/infrastructure/test/configuration/einvoice_inbox_dispatch_test.dart
dart analyze modules/einvoice/application modules/einvoice/infrastructure
```

- [ ] **Step 7: Ranh giới Commit (chỉ khi có ủy quyền)**

```bash
git add modules/einvoice/application modules/einvoice/infrastructure
git commit -m "feat(einvoice): dispatch automatic issuance triggers"
```

---

### Task 5: Triển khai các Transaction Khởi tạo Authoritative cho S3a và S3c

**Files:**
- Create: `supabase/migrations/_drafts/008_einvoice_s3a_s3c_start_and_retry.sql`
- Create: `modules/einvoice/infrastructure/lib/src/domain/issuance/supabase_auto_issuance_gateway.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/domain/issuance/issuance_rpc_mapper.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/configuration/data_access/data_access_module.dart`
- Test: `modules/einvoice/infrastructure/test/domain/issuance/supabase_auto_issuance_gateway_test.dart`
- Test: `modules/einvoice/infrastructure/test/domain/issuance/einvoice_s3a_s3c_sql_contract_test.dart`

**Kết quả đạt được:** Một SQL start primitive dùng chung cho cả luồng thủ công, tự động và retry mà không cần sao chép toàn bộ thân RPC của S2b.

- [ ] **Step 1: Chạy impact analysis trước khi sửa mapper/DI**

Chạy upstream impact cho `IssuanceRpcMapper` và `EinvoiceDataAccessModule`; báo cáo rủi ro và các callers.

- [ ] **Step 2: Viết các RED SQL contract tests**

```dart
test('draft declares every replaced RPC in Touches', () {
  final sql = File(draftPath).readAsStringSync();
  expect(sql, contains('-- Touches: einvoice.automatic_trigger_process_records, einvoice._start_issuance_attempt, einvoice.issue_invoice, einvoice.start_auto_issuance, einvoice.list_open_auto_issuance_processes, einvoice.reevaluate_auto_issuance, einvoice.retry_issuance'));
  expect(sql, contains('einvoice._start_issuance_attempt'));
  expect(sql, contains("'einvoice.publish_invoice'"));
  expect(sql, isNot(contains('create table sales.')));
  expect(sql, isNot(contains('create table partner.')));
});

test('automatic process persists the canonical preparation contract', () {
  final sql = File(draftPath).readAsStringSync();
  for (final field in <String>[
    'sales_order_id', 'sales_order_version', 'trigger_key', 'process_status',
    'retry_count', 'next_retry_at', 'blocker_code',
    'buyer_invoice_completion_id', 'claimed_at', 'claim_token',
    'created_at', 'updated_at', 'version',
  ]) {
    expect(sql, contains(field), reason: 'missing $field');
  }
  expect(sql, contains("'PENDING_REEVALUATION'"));
  expect(sql, contains('einvoice.reevaluate_auto_issuance'));
  final reevaluateBody = sql.substring(
    sql.indexOf('create or replace function einvoice.reevaluate_auto_issuance'),
  );
  expect(reevaluateBody,
      isNot(contains('insert into einvoice.automatic_trigger_process_records')));
});
```

Bổ sung test kiểm tra tenant context, auto policy, readiness, already-issued/active-attempt locks, replay cùng key và source version. Test riêng phải chứng minh `reevaluate_auto_issuance` yêu cầu existing process `PENDING_REEVALUATION`, không insert process row, giữ nguyên original trigger/provider identity, và chỉ có thể tạo attempt đầu tiên trong transaction chuyển chính process đó sang `ATTEMPT_STARTED`.

Thêm SQL contract/integration tests cho hai nhánh retry canonical: (1) `scn_e02_u05_sc11_01` — authoritative version không đổi và completion tương ứng đã `LOCKED`: RPC reuse đúng completion ID/resolved values/lineage, không gọi controlled Theme 03 resolve và vẫn tạo `AttemptSnapshot` mới; (2) `scn_e02_u05_sc12_01` — authoritative version đã đổi: stale `expectedOrderVersion` bị từ chối, completion version cũ không được reuse, mọi lookup completion bắt buộc match cả `sales_order_id` lẫn `sales_order_version`, và chưa tạo attempt nếu completion/readiness của version mới chưa đạt.

- [ ] **Step 3: Tạo file draft với hàm primitive dùng chung nội bộ**

Header của file draft phải có định dạng:

```sql
-- Kind: cohesive
-- Intent: einvoice_s3_start_and_retry
-- Touches: einvoice.automatic_trigger_process_records, einvoice._start_issuance_attempt, einvoice.issue_invoice, einvoice.start_auto_issuance, einvoice.list_open_auto_issuance_processes, einvoice.reevaluate_auto_issuance, einvoice.retry_issuance
```

Tạo `einvoice.automatic_trigger_process_records` với đầy đủ canonical minimum: `id`, `tenant_id`, `process_type`, `sales_order_id`, `sales_order_version`, `trigger_key`, `process_status`, `retry_count`, `next_retry_at`, `blocker_code`, `buyer_invoice_completion_id`, `claimed_at`, `claim_token`, `created_at`, `updated_at`, `version`; thêm `provider_idempotency_key` để bảo toàn RefID của process. Freeze status thành `PENDING_REEVALUATION`, `ATTEMPT_STARTED`, `SKIPPED`; unique business process `(tenant_id, sales_order_id, sales_order_version, process_type)` và unique original `trigger_key` trong tenant. Lock dùng `claimed_at`/`claim_token` có timeout và `for update skip locked`.

`start_auto_issuance` là đường duy nhất insert process từ Sales completion. Khi blocked có thể re-evaluate, nó giữ `PENDING_REEVALUATION`, lưu completion reference/blocker/retry schedule; khi đủ điều kiện, cùng transaction khóa completion, tạo attempt và chuyển `ATTEMPT_STARTED`. `list_open_auto_issuance_processes` join dữ liệu thuộc e-invoice để trả process đúng `buyer_partner_id`, không đọc bảng Partner. `reevaluate_auto_issuance` chỉ update/continue process đã có và từ chối process terminal hoặc completion không còn OPEN. Tạo helper `_start_issuance_attempt` dùng đúng 31 field canonical và `AttemptSnapshot` đủ 11 component.

`retry_issuance` chấp nhận mọi latest `FAILED` definite khi không có lock/invoice và re-read SalesOrder/version authoritative trong transaction. Nếu version hiện hành bằng version của attempt trước và `BuyerInvoiceCompletion` tương ứng đã `LOCKED`, RPC reuse đúng immutable `EffectiveBuyerInvoiceData` cùng completion lineage, không resolve Theme 03, rồi tạo `AttemptSnapshot` mới mà không sửa snapshot/attempt cũ. Nếu version hiện hành khác, RPC từ chối stale `expectedOrderVersion`, không reuse completion của version cũ, thực hiện source-precedence/completion evaluation cho version mới và chỉ tạo attempt khi completion/readiness version mới đạt. Không có provider-only failure gate. Task này vẫn bị E2E block đến khi S2 source authoritative.

- [ ] **Step 4: Triển khai và kiểm thử Supabase gateway**

Chỉ map các trường đã biết:

```dart
return AutoIssuanceResultDto(
  started: row['started'] as bool,
  reason: row['reason'] as String?,
);
```

Kiểm thử bao quát các trường hợp: khởi chạy thành công, từng lý do bỏ qua, replay trùng lặp, và từ chối kết quả sai định dạng.

- [ ] **Step 5: Xác thực file draft và Infrastructure**

```bash
dart test modules/einvoice/infrastructure/test/domain/issuance/einvoice_s3a_s3c_sql_contract_test.dart
dart test modules/einvoice/infrastructure/test/domain/issuance/supabase_auto_issuance_gateway_test.dart
dart analyze modules/einvoice/infrastructure
git diff --check
```

- [ ] **Step 6: Ranh giới Commit (chỉ khi có ủy quyền)**

```bash
git add supabase/migrations/_drafts/008_einvoice_s3a_s3c_start_and_retry.sql modules/einvoice/infrastructure
git commit -m "feat(einvoice): add automatic and retry start transactions"
```

---

### Task 6: Thay thế Loose Result Command bằng Typed Evidence

**Files:**
- Modify: `modules/einvoice/application/lib/src/issuance/commands/record_issuance_result/record_issuance_result_command.dart`
- Create: `modules/einvoice/application/lib/src/issuance/commands/record_issuance_result/record_issuance_result_command_validator.dart`
- Create: `modules/einvoice/application/lib/src/issuance/commands/record_issuance_result/record_issuance_result_command_handler.dart`
- Create: `modules/einvoice/application/lib/src/issuance/integration_events/provider_issuance_result_received_integration_event_handler.dart`
- Modify: `modules/einvoice/application/lib/src/ports/i_issuance_result_gateway.dart`
- Test: `modules/einvoice/application/test/issuance/record_issuance_result_command_handler_test.dart`
- Test: `modules/einvoice/application/test/issuance/provider_issuance_result_received_integration_event_handler_test.dart`
- Modify: `modules/einvoice/application/test/issuance/publish_invoice_command_handler_test.dart`

**Kết quả đạt được:** Một ranh giới tiếp nhận typed evidence duy nhất được dùng chung bởi publish trực tiếp, polling, và callback.

- [ ] **Step 1: Chạy impact analysis**

Chạy upstream impact cho `RecordIssuanceResultCommand`, `IIssuanceResultGateway`, và `PublishInvoiceCommandHandler`. Báo cáo cảnh báo nếu rủi ro là HIGH/CRITICAL.

- [ ] **Step 2: Viết các RED typed-routing tests**

```dart
test('success evidence routes only to recordSuccess', () async {
  final gateway = FakeIssuanceResultGateway();
  await RecordIssuanceResultCommandHandler(gateway).handle(
    RecordIssuanceResultCommand(
      tenantId: 'tenant-1', attemptId: 'attempt-1', correlationId: 'corr-1',
      evidence: IssuanceResultEvidenceDto.success(
        idempotencyKey: key, payloadHash: hash,
        providerReference: 'misa-1', invoiceNumber: '00000123',
        invoiceSeries: '1C26TVE', issuedAt: DateTime.utc(2026, 8, 28),
      ),
    ),
  );
  expect(gateway.successCalls, 1);
  expect(gateway.failureCalls + gateway.undeterminedCalls, 0);
});
```

Thêm các test tương tự cho definite-failure và undetermined. Validator kiểm tra các trường định danh/hash không được trống và các trường riêng theo từng subtype.

- [ ] **Step 3: Triển khai sealed dispatch**

Thay thế trường `providerResult` bằng `evidence` và dùng matching đầy đủ theo subtype (exhaustive subtype matching). Không trả về kiểu `Either`/`Result` bên trong command handler.

- [ ] **Step 4: Định tuyến các callback event an toàn qua cùng một command**

Triển khai `ProviderIssuanceResultReceivedIntegrationEventHandler` sử dụng `IEinvoiceCommandDispatcher`. Chuyển đổi các trường an toàn đã phân loại của event thành chính xác một `IssuanceResultEvidenceDto`, sau đó thực thi `RecordIssuanceResultCommand`. Kiểm thử các biến thể success/failure/undetermined và từ chối tổ hợp discriminator/field không hợp lệ khi deserialize event.

Bổ sung `scn_e02_u04_fr01_02`: callback terminal hợp lệ đến sau khi case đã `UNRESOLVED` vẫn đi qua cùng typed command. Success phải kết thúc attempt/đăng ký invoice/resolve case mà không enqueue publish; definite failure phải kết thúc attempt/resolve case để projection có thể mở lại action sau các gate; undetermined giữ nguyên `UNRESOLVED`. Callback unmatched, sai tenant/correlation/idempotency identity bị từ chối; callback duplicate hoặc out-of-order sau terminal state trả kết quả hiện có và không đảo trạng thái.

- [ ] **Step 5: Giữ ổn định hành vi luồng trực tiếp của S2b**

Cập nhật test của `PublishInvoiceCommandHandler` để đảm bảo việc gọi trực tiếp gateway hiện tại không bị ảnh hưởng; `RecordIssuanceResultCommand` trở thành điểm vào cho polling/callback, không phải là một bước dispatch thừa từ publish.

- [ ] **Step 6: Xác thực**

```bash
dart test modules/einvoice/application/test/issuance/record_issuance_result_command_handler_test.dart
dart test modules/einvoice/application/test/issuance/provider_issuance_result_received_integration_event_handler_test.dart
dart test modules/einvoice/application/test/issuance/publish_invoice_command_handler_test.dart
melos run codegen
dart analyze modules/einvoice/application
```

- [ ] **Step 7: Ranh giới Commit (chỉ khi có ủy quyền)**

```bash
git add modules/einvoice/application
git commit -m "refactor(einvoice): type issuance result landing"
```

---

### Task 7: Mã hóa Lịch trình Đối soát và Điều kiện Retry vào Domain Policies

**Files:**
- Create: `modules/einvoice/domain/lib/src/reconciliation/reconciliation_schedule.dart`
- Create: `modules/einvoice/domain/lib/src/issuance/services/issuance_retry_policy.dart`
- Modify: `modules/einvoice/domain/lib/domain.dart`
- Test: `modules/einvoice/domain/test/reconciliation/reconciliation_schedule_test.dart`
- Test: `modules/einvoice/domain/test/issuance/issuance_retry_policy_test.dart`

**Kết quả đạt được:** Các pure business policy có thể thực thi độc lập cho nhịp độ 5 lần kiểm tra và điều kiện chỉ retry khi definite-failure; Application và SQL chịu trách nhiệm điều phối và lưu trữ.

- [ ] **Step 1: Chạy impact analysis trước khi sửa barrel file**

Chạy GitNexus upstream impact cho `IssuanceAttemptStatus`, `InternalFinalizationStatus`, và domain barrel file. Báo cáo rủi ro và dừng lại nếu HIGH/CRITICAL.

- [ ] **Step 2: Viết các RED reconciliation schedule tests**

```dart
test('poll cadence is exact and one-based', () {
  expect(ReconciliationSchedule.delayBeforeCheck(1), const Duration(seconds: 30));
  expect(ReconciliationSchedule.delayBeforeCheck(2), const Duration(minutes: 2));
  expect(ReconciliationSchedule.delayBeforeCheck(3), const Duration(minutes: 10));
  expect(ReconciliationSchedule.delayBeforeCheck(4), const Duration(minutes: 30));
  expect(ReconciliationSchedule.delayBeforeCheck(5), const Duration(hours: 2));
});

test('fifth completed check is terminal unresolved', () {
  expect(ReconciliationSchedule.shouldMarkUnresolved(4), isFalse);
  expect(ReconciliationSchedule.shouldMarkUnresolved(5), isTrue);
});
```

Đồng thời assert các số thứ tự lần kiểm tra `0` và `6` ném ra `RangeError` để tránh lỗi off-by-one khi lên lịch.

- [ ] **Step 3: Viết các RED retry policy tests**

```dart
test('every definite failed attempt can reopen issuance when unlocked', () {
  expect(IssuanceRetryPolicy.isAllowed(
    latestStatus: IssuanceAttemptStatus.failed,
    internalFinalizationStatus: InternalFinalizationStatus.pending,
    hasElectronicInvoice: false,
    hasActiveOperation: false,
  ), isTrue);
  expect(IssuanceRetryPolicy.isAllowed(
    latestStatus: IssuanceAttemptStatus.reconciling,
    internalFinalizationStatus: InternalFinalizationStatus.pending,
    hasElectronicInvoice: false,
    hasActiveOperation: true,
  ), isFalse);
  expect(IssuanceRetryPolicy.isAllowed(
    latestStatus: IssuanceAttemptStatus.failed,
    internalFinalizationStatus: InternalFinalizationStatus.unresolved,
    hasElectronicInvoice: false,
    hasActiveOperation: true,
  ), isFalse);
});
```

Bổ sung trường hợp `FAILED + failureCode COMMAND_INTEGRITY` và `FAILED + safe system failureCode` đều trả true khi không lock/invoice; đã thành công, đã có hóa đơn, active reconciliation, finalization unresolved, và mọi trạng thái nonterminal đều trả false. Domain policy không phụ thuộc failure provenance; Application/RPC vẫn recheck readiness authoritative trước khi tạo attempt.

- [ ] **Step 4: Triển khai các immutable pure policies và export chúng**

`ReconciliationSchedule` là tiện ích `abstract final` với `maxChecks = 5`. `IssuanceRetryPolicy` hoàn toàn không phụ thuộc vào repository hay provider. Sử dụng các policy này ở Task 8 và 10; đồng thời đối chiếu chúng trong SQL ở Task 9.

- [ ] **Step 5: Xác thực Domain package**

```bash
dart test modules/einvoice/domain/test/reconciliation/reconciliation_schedule_test.dart
dart test modules/einvoice/domain/test/issuance/issuance_retry_policy_test.dart
dart analyze modules/einvoice/domain
```

- [ ] **Step 6: Ranh giới Commit (chỉ khi có ủy quyền)**

```bash
git add modules/einvoice/domain
git commit -m "feat(einvoice): encode reconciliation and retry policies"
```

---

### Task 8: Triển khai Phân loại Trạng thái Provider và Lệnh Poll của S3b

**Files:**
- Modify: `modules/einvoice/application/lib/src/ports/i_me_invoice_provider_port.dart`
- Create: `modules/einvoice/application/lib/src/ports/me_invoice_issuance_status_outcome.dart`
- Create: `modules/einvoice/application/lib/src/issuance/commands/poll_issuance_status/poll_issuance_status_command.dart`
- Create: `modules/einvoice/application/lib/src/issuance/commands/poll_issuance_status/poll_issuance_status_command_handler.dart`
- Create: `modules/einvoice/application/lib/src/ports/i_issuance_reconciliation_gateway.dart`
- Create: `modules/einvoice/application/lib/src/issuance/shared/reconciliation_poll_context_dto.dart`
- Create: `modules/einvoice/infrastructure/lib/src/adapters/misa/me_invoice_issuance_status_classifier.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/adapters/misa/me_invoice_provider_adapter.dart`
- Modify: `packages/vet45_misa/lib/src/e_invoice/fake_me_invoice_client.dart`
- Modify: `packages/vet45_misa/test/e_invoice/fake_me_invoice_client_test.dart`
- Test: `modules/einvoice/infrastructure/test/me_invoice_issuance_status_classifier_test.dart`
- Test: `modules/einvoice/application/test/issuance/poll_issuance_status_command_handler_test.dart`

**Kết quả đạt được:** Một durable internal command thực hiện kiểm tra trạng thái và tuyệt đối không bao giờ publish lại.

- [ ] **Step 1: Chạy impact analysis**

Chạy upstream impact cho `IMeInvoiceProviderPort`, `MeInvoiceProviderAdapter`, và `FakeMeInvoiceClient`; đưa các callers của S1/S2a/S2b vào báo cáo blast-radius.

- [ ] **Step 2: Viết các RED classifier tests dựa trên các cấu trúc dữ liệu của `FakeMeInvoiceClient`**

```dart
test('provider issued status becomes typed success', () {
  final outcome = classifier.classify(statusResponseIssued);
  expect(outcome, isA<MeInvoiceIssuanceStatusSuccess>());
});

test('processing remains pending and malformed response is undetermined', () {
  expect(classifier.classify(statusResponseProcessing),
      isA<MeInvoiceIssuanceStatusPending>());
  expect(classifier.classify(<String, Object?>{}),
      isA<MeInvoiceIssuanceStatusUndetermined>());
});
```

Không bao giờ suy diễn definite failure từ các lỗi kết nối/parse; chỉ các mã từ chối kết thúc (terminal rejection codes) đã được định nghĩa rõ ràng mới map thành definite failure. Mở rộng `FakeMeInvoiceClient` với hàng đợi FIFO tùy chọn cho các kết quả `getStatus` được kịch bản hóa trước, đồng thời giữ nguyên các hành vi mặc định/kịch bản có sẵn; điều này cho phép integration test kiểm thử được các luồng pending → success và 5 lần pending liên tiếp mà không cần gọi network thật.

- [ ] **Step 3: Viết các RED poll orchestration tests**

Kiểm thử các trường hợp: mất claim = bỏ qua an toàn; success = ghi nhận typed evidence; definite failure = ghi nhận typed evidence; pending ở các lần 1–4 = lên lịch lần kiểm tra tiếp theo với độ trễ chính xác; pending/undetermined ở lần thứ 5 = đánh dấu unresolved; thiếu thông tin xác thực (credentials) = xử lý an toàn theo nhánh undetermined mà không làm crash tick của worker.

```dart
verifyNever(() => provider.publish(
  tenantId: any(named: 'tenantId'),
  canonicalInvoice: any(named: 'canonicalInvoice'),
  idempotencyKey: any(named: 'idempotencyKey'),
));
```

- [ ] **Step 4: Triển khai poll handler**

Luồng xử lý: claim case → lấy trạng thái từ provider bằng idempotency key/provider reference đã lưu → dispatch `RecordIssuanceResultCommand` khi có terminal evidence → trường hợp khác dùng `ReconciliationSchedule` để tính toán thời gian kiểm tra tiếp theo hoặc đánh dấu unresolved. Handler của lệnh poll không nhận dữ liệu canonical invoice payload và không có bất kỳ đường dẫn nào để gọi hàm `publish`.

- [ ] **Step 5: Xác thực**

```bash
dart test modules/einvoice/infrastructure/test/me_invoice_issuance_status_classifier_test.dart
dart test modules/einvoice/application/test/issuance/poll_issuance_status_command_handler_test.dart
dart test packages/vet45_misa/test/e_invoice/fake_me_invoice_client_test.dart
dart analyze modules/einvoice/application modules/einvoice/infrastructure packages/vet45_misa
```

- [ ] **Step 6: Ranh giới Commit (chỉ khi có ủy quyền)**

```bash
git add modules/einvoice/application modules/einvoice/infrastructure packages/vet45_misa
git commit -m "feat(einvoice): poll uncertain issuance outcomes"
```

---

### Task 9: Triển khai S3b Reconciliation RPCs, Due-Time Claiming, và Recovery

**Files:**
- Create: `supabase/migrations/_drafts/009_einvoice_s3b_reconciliation.sql`
- Create: `modules/einvoice/infrastructure/lib/src/domain/issuance/supabase_issuance_reconciliation_gateway.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/domain/issuance/issuance_rpc_mapper.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/configuration/data_access/data_access_module.dart`
- Create: `modules/einvoice/application/lib/src/issuance/commands/open_reconciliation_case/open_reconciliation_case_command_validator.dart`
- Create: `modules/einvoice/application/lib/src/issuance/commands/open_reconciliation_case/open_reconciliation_case_command_handler.dart`
- Create: `modules/einvoice/application/lib/src/issuance/commands/resolve_reconciliation_case/resolve_reconciliation_case_command_validator.dart`
- Create: `modules/einvoice/application/lib/src/issuance/commands/resolve_reconciliation_case/resolve_reconciliation_case_command_handler.dart`
- Create: `modules/einvoice/application/lib/src/issuance/commands/recover_internal_finalization/recover_internal_finalization_command_validator.dart`
- Create: `modules/einvoice/application/lib/src/issuance/commands/recover_internal_finalization/recover_internal_finalization_command_handler.dart`
- Modify: `modules/einvoice/application/lib/src/issuance/queries/get_issuance_attempt_status/issuance_attempt_status_dto.dart`
- Create: `modules/einvoice/application/lib/src/issuance/queries/get_issuance_attempt_status/get_issuance_attempt_status_query_handler.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/configuration/processing/internal_commands/i_einvoice_internal_command_client.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/configuration/processing/internal_commands/supabase_einvoice_internal_command_client.dart`
- Test: `modules/einvoice/infrastructure/test/domain/issuance/einvoice_s3b_sql_contract_test.dart`
- Test: `modules/einvoice/infrastructure/test/domain/issuance/supabase_issuance_reconciliation_gateway_test.dart`
- Test: `modules/einvoice/application/test/issuance/reconciliation_command_handlers_test.dart`

**Kết quả đạt được:** Các RPC xử lý claim/giải quyết case mang tính transaction và cơ chế phục hồi hoàn tất nội bộ rõ ràng, không gọi lại provider.

- [ ] **Step 1: Chạy impact analysis**

Chạy upstream impact cho `IssuanceRpcMapper`, `EinvoiceDataAccessModule`, và từng class command/query liên quan đến reconciliation trước khi chỉnh sửa.

- [ ] **Step 2: Mở rộng durable handoff của S2b trong file draft S3b**

Trong draft 009, thay thế `record_issuance_undetermined` để cùng transaction mở/cập nhật pending case và enqueue poll đầu tiên với `enqueued_at = next_check_at`. Pending case vẫn là nguồn authoritative; insert command là delivery side effect có thể phục hồi. Không sửa draft 007/008 và liệt kê mọi RPC bị replace vào header `-- Touches:` của draft 009.

Không thêm field vào `invoice_reconciliation_cases`. Tạo private SQL helper `einvoice._reconciliation_poll_command_id(p_case_id uuid, p_check_ordinal integer)` trả deterministic UUID bằng cách SHA-256 chuỗi `<caseId>|<checkOrdinal>`, format 32 hex đầu thành UUID. Direct enqueue, seed và backfill đều dùng kết quả này làm `command_id`/`source_event_id`. `seed_due_issuance_reconciliation_commands(tenant, limit)` scan case canonical `PENDING` có `next_check_at <= now()` và insert command còn thiếu cho ordinal `attempt_count + 1`; nếu đúng command đã dead-letter nhưng case vẫn pending, re-arm chính technical queue row sau cooldown. Cuối draft backfill idempotently mọi pending case cũ từ chính `case.id`, `attempt_count`, `next_check_at`; không cập nhật schema case.

- [ ] **Step 3: Viết các RED SQL contract tests**

Assert draft 009 có danh sách `-- Touches:` chính xác gồm:

```text
einvoice.open_reconciliation_case
einvoice.record_issuance_undetermined
einvoice.claim_issuance_reconciliation_case
einvoice.record_reconciliation_pending
einvoice.resolve_reconciliation_case
einvoice.recover_internal_finalization
einvoice.get_issuance_attempt_status
einvoice.claim_internal_commands_batch
einvoice._reconciliation_poll_command_id
einvoice.seed_due_issuance_reconciliation_commands
```

Đồng thời kiểm tra SQL của claim có `enqueued_at <= now()`, `for update skip locked`, và claim-token; seed/backfill dùng deterministic `{caseId, checkOrdinal}`, xử lý case tồn tại trước S3, chỉ enqueue `einvoice.poll_issuance_status`, và draft không chứa `scheduled_command_id`. Lệnh recovery không chứa hành vi chèn publish command hay provider payload. Test `resolve_reconciliation_case` phải có nhánh `UNRESOLVED -> RESOLVED` cho terminal evidence hợp lệ, không cho undetermined/invalid evidence đổi state, không enqueue publish, và giữ idempotent/no-op khi target attempt đã terminal.

- [ ] **Step 4: Triển khai hành vi Transactional**

`record_reconciliation_pending` tăng số lần kiểm tra và `version`, rồi enqueue command tiếp theo với thời gian chờ chính xác. `resolve_reconciliation_case` khóa cả case và target attempt, ghi terminal evidence/đóng case và tăng version. Nó chấp nhận `PENDING -> RESOLVED` và contract amendment `UNRESOLVED -> RESOLVED` chỉ cho authenticated/correlated terminal evidence; success/failure áp dụng vào attempt từ `RECONCILING` theo state machine, còn undetermined giữ `UNRESOLVED`. Case/attempt đã terminal trả canonical result hiện có, không đảo trạng thái và không tạo side effect lần hai. `recover_internal_finalization` dùng success evidence đã lưu, tạo bản ghi nội bộ còn thiếu, hoàn tất finalization, tăng version và kích hoạt outbox mà không gọi MISA. Mọi internal transition dùng `for update` và optimistic version increment theo repair gate.

- [ ] **Step 5: Triển khai các handlers/gateway/query gọn nhẹ**

Các Handler kiểm tra dữ liệu trước khi ủy quyền. `IssuanceAttemptStatusDto` chứa `internalFinalizationStatus`, `hasElectronicInvoice`, `hasActiveOperation`, và safe `failureCode`; không có `failureOrigin`/`retryEligible`. `GetIssuanceAttemptStatusQueryHandler` không để lộ raw provider payload. Infrastructure client expose `seedDueReconciliationCommands`, được worker gọi trước `claimBatch` ở Task 11.

- [ ] **Step 6: Xác thực**

```bash
dart test modules/einvoice/infrastructure/test/domain/issuance/einvoice_s3b_sql_contract_test.dart
dart test modules/einvoice/infrastructure/test/domain/issuance/supabase_issuance_reconciliation_gateway_test.dart
dart test modules/einvoice/application/test/issuance/reconciliation_command_handlers_test.dart
dart analyze modules/einvoice/application modules/einvoice/infrastructure
git diff --check
```

- [ ] **Step 7: Ranh giới Commit (chỉ khi có ủy quyền)**

```bash
git add supabase/migrations/_drafts/009_einvoice_s3b_reconciliation.sql modules/einvoice/application modules/einvoice/infrastructure
git commit -m "feat(einvoice): reconcile uncertain issuance results"
```

---

### Task 10: Triển khai S3c Definite-Failure Retry

**Files:**
- Create: `modules/einvoice/application/lib/src/issuance/commands/retry_issuance/retry_issuance_start_request.dart`
- Create: `modules/einvoice/application/lib/src/issuance/commands/retry_issuance/retry_issuance_command_validator.dart`
- Create: `modules/einvoice/application/lib/src/issuance/commands/retry_issuance/retry_issuance_command_handler.dart`
- Modify: `modules/einvoice/application/lib/src/ports/i_issuance_command_gateway.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/domain/issuance/supabase_issuance_command_gateway.dart`
- Test: `modules/einvoice/application/test/issuance/retry_issuance_command_handler_test.dart`
- Test: `modules/einvoice/infrastructure/test/domain/issuance/supabase_issuance_command_gateway_retry_test.dart`

**Kết quả đạt được:** Cơ chế phát hành lại khi người dùng xác nhận thông qua cùng publish path bền vững, bảo toàn nguyên vẹn lịch sử các attempt trước.

- [ ] **Step 1: Chạy impact analysis**

Chạy upstream impact cho `RetryIssuanceCommand`, `IIssuanceCommandGateway`, và `SupabaseIssuanceCommandGateway`.

- [ ] **Step 2: Viết các RED tests**

```dart
test('scn_e02_u05_fr04_01 sends retry source version and actor', () async {
  final gateway = FakeIssuanceCommandGateway.retryPreparing();
  final result = await RetryIssuanceCommandHandler(gateway).handle(
    RetryIssuanceCommand(
      tenantId: 'tenant-1', actorId: 'actor-1', salesOrderId: 'order-1',
      expectedOrderVersion: 18,
      idempotencyKey: '692c44cb-03a4-456b-a8a8-c5973f4e93db',
    ),
  );
  expect(result.status, IssuanceAttemptStatus.preparing);
  expect(gateway.lastRetry!.expectedOrderVersion, 18);
});
```

Bổ sung trường hợp `FAILED + COMMAND_INTEGRITY` và `FAILED + system failure trước provider` đều được đi tiếp tới readiness check. Các trường hợp bị từ chối: attempt gần nhất là `RECONCILING`, `WAITING_RESULT`, `SUCCEEDED`; active reconciliation/operation lock; finalization chưa xử lý; đã có invoice; projection chưa sẵn sàng; và source-version không khớp.

Thêm hai RED scenario tests độc lập:

```text
scn_e02_u05_sc11_01: current SalesOrder version == failed attempt version + matching completion LOCKED
  -> reuse exact locked EffectiveBuyerInvoiceData/completion lineage
  -> do not resolve Theme 03
  -> create a new attempt/snapshot; keep old attempt/snapshot immutable

scn_e02_u05_sc12_01: current SalesOrder version != failed attempt version
  -> stale expectedOrderVersion is rejected
  -> old-version completion is never selected
  -> evaluate completion/readiness for current version
  -> create no attempt until current-version completion is LOCKED/ready
```

- [ ] **Step 3: Triển khai luồng Application và Infrastructure**

Handler kiểm tra `IssuanceRetryPolicy` bằng canonical status, active-operation/finalization lock và invoice existence, sau đó chuyển yêu cầu tới gateway. RPC lặp lại toàn bộ gate trong transaction: latest attempt phải `FAILED`, không có active reconciliation/finalization lock, chưa có invoice, rồi load SalesOrder/version authoritative và so với `expectedOrderVersion`.

Với cùng version, RPC bắt buộc chọn `BuyerInvoiceCompletion` bằng cặp `(sales_order_id, sales_order_version)`, reuse chính record `LOCKED` và `EffectiveBuyerInvoiceData` đã khóa, tuyệt đối không gọi Theme 03. Với version mới, request stale bị từ chối; lần gọi lại trên version hiện hành không được dùng completion cũ, phải chạy source-precedence/completion rule của version mới và chỉ tạo attempt khi readiness/completion hiện hành đạt. RPC không lọc theo `failure_code`; mọi `FAILED` là definite failure theo Theme. Giữ `expectedOrderVersion` dưới dạng số nguyên theo hợp đồng S3c và không tái sử dụng ngầm `sourceVersion` dạng chuỗi của S2b.

- [ ] **Step 4: Kiểm tra tính bảo toàn lịch sử tại ranh giới SQL**

Các SQL contract test kiểm tra không có hành vi ghi đè hay xóa các dòng attempt trước đó, một attempt ID mới được tạo, và các trường thông tin thất bại trước đó được giữ nguyên vẹn. Kiểm tra thêm mọi completion lookup đều version-bound, cùng-version path không chứa Theme 03 resolve/refresh, và changed-version path không thể copy `buyer_invoice_completion_id` hoặc resolved values từ attempt cũ.

- [ ] **Step 5: Xác thực**

```bash
dart test modules/einvoice/application/test/issuance/retry_issuance_command_handler_test.dart
dart test modules/einvoice/infrastructure/test/domain/issuance/supabase_issuance_command_gateway_retry_test.dart
dart test modules/einvoice/infrastructure/test/domain/issuance/einvoice_s3a_s3c_sql_contract_test.dart
```

- [ ] **Step 6: Ranh giới Commit (chỉ khi có ủy quyền)**

```bash
git add modules/einvoice/application modules/einvoice/infrastructure
git commit -m "feat(einvoice): retry definite issuance failures"
```

---

### Task 11: Đăng ký S3 Commands, Provider Ports, và Cấu hình Worker

**Files:**
- Modify: `modules/einvoice/infrastructure/lib/src/configuration/processing/processing_module.dart`
- Modify: `modules/einvoice/infrastructure/lib/src/configuration/processing/einvoice_module_definition.dart`
- Generated: `modules/einvoice/infrastructure/lib/src/configuration/processing/generated/einvoice_cqrs_registrar.g.dart`
- Generated: `modules/einvoice/infrastructure/lib/src/configuration/processing/generated/einvoice_internal_command_registry.g.dart`
- Generated: `modules/einvoice/infrastructure/lib/src/configuration/processing/generated/einvoice_module_manifest.g.dart`
- Generated: `modules/einvoice/infrastructure/lib/src/configuration/processing/generated/einvoice_access_metadata.g.dart`
- Test: `modules/einvoice/infrastructure/test/configuration/einvoice_s3_registration_test.dart`
- Test: `apps/messaging_worker/test/einvoice_worker_slice3_test.dart`

**Kết quả đạt được:** Toàn bộ handler có thể gọi được qua Mediator/Internal-command worker và xử lý soft-fail khi tenant thiếu credentials.

- [ ] **Step 1: Chạy impact analysis**

Chạy upstream impact cho `EinvoiceProcessingModule` và `EinvoiceModuleDefinition`; kiểm tra các tiến trình startup và worker bị ảnh hưởng.

- [ ] **Step 2: Viết các RED registration tests**

Kiểm tra Mediator resolve được `StartAutoIssuanceCommand`, `ReevaluateAutoIssuanceCommand`, S3b/S3c handlers; internal registry serialize/deserialize được `PollIssuanceStatusCommand`; dead-letter registry resolve được handler của `PublishInvoiceCommand`; và inbox dispatcher nhận diện đủ 3 event type. Registration test phải chứng minh Partner handler chỉ dispatch re-evaluate command.

- [ ] **Step 3: Đăng ký Dependency Injection và sinh mã nguồn**

Đăng ký `IAutoIssuanceGateway`, `IIssuanceReconciliationGateway`, `IMeInvoiceProviderPort` mở rộng, `PublishInvoiceCommandDeadLetterHandler`, và các integration event handlers. Chạy:

```bash
melos run codegen
```

Review kỹ diff của code được sinh ra; tuyệt đối không sửa tay các file `.g.dart`.

- [ ] **Step 4: Kiểm thử hành vi của Worker**

```dart
test('missing tenant MISA credentials fails one command without crashing tick', () async {
  await expectLater(worker.tick(), completes);
  expect(fakeInternalCommands.retryOrDeadLetterCalls.single.code,
      'PROVIDER_CREDENTIALS_UNAVAILABLE');
});
```

Mỗi e-invoice worker tick gọi `seedDueReconciliationCommands(tenantId)` trước `claimBatch`. Thêm test với pending case có sẵn nhưng không có queue row: tick đầu seed đúng một poll command, replay tick không tạo duplicate, và không có publish command. Việc lọc due-time/backfill đã được chứng minh qua SQL contract test ở Task 9; fake worker không tự tạo clock parameter không tồn tại trong interface production.

- [ ] **Step 5: Xác thực**

```bash
dart test modules/einvoice/infrastructure/test/configuration/einvoice_s3_registration_test.dart
cd apps/messaging_worker && dart test test/einvoice_worker_slice3_test.dart
cd ../..
dart analyze modules/einvoice/infrastructure apps/messaging_worker
```

- [ ] **Step 6: Ranh giới Commit (chỉ khi có ủy quyền)**

```bash
git add modules/einvoice/infrastructure apps/messaging_worker
git commit -m "feat(einvoice): wire slice 3 worker processing"
```

---

### Task 12: Xây dựng Theme 05 Retry Integration Component

**Files:**
- Modify: `modules/einvoice/presentation/lib/src/widgets/pre_issue_einvoice_action_sheet.dart`
- Modify: `modules/einvoice/presentation/lib/src/support/order_einvoice_copy.dart`
- Create: `modules/einvoice/presentation/lib/src/widgets/issuance_failure_banner.dart`
- Modify: `modules/einvoice/presentation/lib/presentation.dart`
- Create: `apps/erp/lib/features/sales/presentation/bloc/order_einvoice_cubit.dart`
- Create: `apps/erp/lib/features/sales/presentation/bloc/order_einvoice_state.dart`
- Create: `apps/erp/lib/features/sales/presentation/support/order_einvoice_idempotency_key_factory.dart`
- Create: `apps/erp/lib/features/sales/presentation/widgets/order_einvoice_section.dart`
- Modify: `apps/erp/pubspec.yaml`
- Test: `modules/einvoice/presentation/test/widgets/pre_issue_einvoice_action_sheet_test.dart`
- Test: `modules/einvoice/presentation/test/widgets/issuance_failure_banner_test.dart`
- Test: `apps/erp/test/features/sales/presentation/order_einvoice_section_test.dart`
- Modify: `modules/einvoice/presentation/example/lib/preview/sg02_tab.dart`
- Modify: `modules/einvoice/presentation/example/lib/preview/sg03_tab.dart`

**Kết quả đạt được:** Một UI section tái sử dụng cho trạng thái thất bại tuân thủ đúng luồng UI → Execution Context → Mediator và dùng action phát hành chuẩn.

- [ ] **Step 1: Chạy impact analysis**

Chạy upstream impact cho `PreIssueEInvoiceActionSheet`, `OrderEInvoiceRow`, và `OrderEInvoiceCopy` trước khi sửa.

- [ ] **Step 2: Viết các RED widget tests**

```dart
testWidgets('wgt_e02_u05_fr02_01 failed row keeps normal issue label', (tester) async {
  await tester.pumpWidget(buildSection(
    scenario: FakeEInvoiceScenario.retryAfterFailOk,
    projectionStatus: IssuanceDisplayState.failed,
    projectionActions: const [OrderInvoiceAction.issue],
  ));
  await tester.tap(find.byType(OrderEInvoiceRow));
  await tester.pumpAndSettle();
  expect(find.text('Phát hành HĐĐT'), findsOneWidget);
  expect(find.text('Thử lại'), findsNothing);
});
```

Bổ sung test cho: `failed + failureCode COMMAND_INTEGRITY` hiển thị safe message và action phát hành; provider/system definite failure cũng dùng cùng action; `processing/reconciling` không có action; bước xác nhận trước phát hành; chuyển ngay sang local `Đang xử lý`; và các fake scenario `retry_after_fail_ok`, `retry_while_reconciling`, `retry_projection_failed_state`, `retry_not_ready`.

- [ ] **Step 3: Triển khai các thành phần Presentation**

`IssuanceFailureBanner` hiển thị safe allow-listed `lastFailureMessage?`/`failureCode?`, không có `failureOrigin`/`retryEligible` và không hiển thị raw provider details. UI render đúng `actions` từ `OrderInvoiceProjectionDto`; với `failed` canonical projection cung cấp `issue`, còn `processing` cung cấp danh sách rỗng. Giữ nguyên confirmation sheet và nhãn phát hành hiện có.

- [ ] **Step 4: Triển khai ranh giới tích hợp ứng dụng (App integration boundary)**

`OrderEInvoiceCubit` nhận `IExecutionContext`, `IModuleMediator`, và `OrderEInvoiceIdempotencyKeyFactory`. Thêm dependency `uuid: ^4.5.3` trực tiếp vào app ERP và trả về plain UUID v4 để có thể truyền sang MISA dưới dạng `RefID`; inject deterministic factory trong unit test. Khi người dùng thao tác:

```dart
final tenantId = await _executionContext.requireTenantId();
final actorId = await _executionContext.requireUserId();
await _mediator.executeCommandAsync(RetryIssuanceCommand(
  tenantId: tenantId,
  actorId: actorId,
  salesOrderId: state.salesOrderId,
  expectedOrderVersion: state.orderVersion,
  idempotencyKey: _idempotencyKeys.next(),
));
emit(state.toProcessing());
```

Component cung cấp hàm `refresh()` để bên quản lý polling projection của S2 FE gọi; không tự ý tạo thêm `Timer.periodic` thứ hai.

- [ ] **Step 5: Bổ sung các trạng thái Example Catalog và Xác thực**

```bash
flutter test modules/einvoice/presentation/test/widgets/pre_issue_einvoice_action_sheet_test.dart
flutter test modules/einvoice/presentation/test/widgets/issuance_failure_banner_test.dart
cd apps/erp && flutter test test/features/sales/presentation/order_einvoice_section_test.dart
cd ../..
flutter analyze modules/einvoice/presentation apps/erp
```

- [ ] **Step 6: Ghi nhận Theme 05 Host Gate**

Nếu trang đơn hàng thực tế của Theme 05 đã tồn tại ở thời điểm thực thi, import `OrderEInvoiceSection` vào trang đó và thêm widget test cho host-page. Nếu chưa có, giữ FE lane ở trạng thái `in_progress` và ghi nhận chính xác artifact còn thiếu trong `04-slice-roadmap.md`; không tự tạo trang giả định hoặc tự ý đánh dấu lane là done.

- [ ] **Step 7: Ranh giới Commit (chỉ khi có ủy quyền)**

```bash
git add modules/einvoice/presentation apps/erp/lib/features/sales apps/erp/test/features/sales
git commit -m "feat(einvoice): expose failed issuance retry flow"
```

---

### Task 13: Chứng minh End-to-End Slice 3 và Đóng các Lane Hợp lệ

**Files:**
- Create: `modules/einvoice/infrastructure/test/einvoice_slice3_integration_test.dart`
- Modify: `docs/themes/TH-08-e-invoice/harness/05-traceability.md`
- Modify: `docs/themes/TH-08-e-invoice/harness/04-slice-roadmap.md`
- Modify: `docs/themes/TH-08-e-invoice/README.md`
- Test: Các lệnh kiểm thử repository bên dưới

**Kết quả đạt được:** Bằng chứng kiểm thử qua Mediator/Worker với `FakeMeInvoiceClient`, cùng với trạng thái lane và các deployment blockers trung thực.

- [ ] **Step 1: Viết end-to-end tests qua các Public Boundaries**

Bao quát toàn bộ các luồng mà không cần kết nối tới MISA thật:

```text
e2e_e02_u03_sc01_01: sales.order.completed -> inbox -> StartAutoIssuance -> attempt -> publish command
scn_e02_u03_fr09_01: partner update -> existing PENDING_REEVALUATION process -> first attempt; process row count unchanged
e2e_e02_u04_sc01_01: publish unknown -> due poll -> getStatus success -> ElectronicInvoice được ghi nhận
pending_handoff_existing_case_01: pending case có sẵn/không có queue row -> worker seed -> poll, không publish
scn_e02_u04_fr08_02: 5 lần kiểm tra không xác định -> UNRESOLVED, không republish
scn_e02_u04_fr08_03: provider success đã lưu -> recovery -> local finalization hoàn tất, không gọi MISA
scn_e02_u04_fr01_02: callback terminal hợp lệ sau UNRESOLVED -> attempt/case terminal đúng kết quả, không republish
e2e_e02_u05_sc01_01: definite failure -> RetryIssuance -> attempt mới; attempt cũ & evidence không đổi
scn_e02_u05_sc11_01: retry cùng SalesOrder version -> reuse completion LOCKED, không resolve Theme 03
scn_e02_u05_sc12_01: retry sau SalesOrder version mới -> không reuse completion cũ; chờ completion/readiness mới
s2b_command_integrity_dead_letter_01: canonical mismatch -> bounded dead-letter -> failed/no action/no provider call
```

Với Partner re-evaluation, assert process row count không đổi, original trigger/provider key không đổi và chỉ attempt đầu tiên được tạo sau khi completion khóa. Với mọi test unknown/recovery/late-callback, assert `FakeMeInvoiceClient.publishCount == 1`; callback sau `UNRESOLVED` không tạo poll/publish mới, terminal callback hợp lệ đóng case, còn invalid/undetermined callback giữ lock. Với retry cùng version, assert completion ID/lineage giữ nguyên nhưng attempt/snapshot ID mới; với version mới, assert completion cũ không xuất hiện trong snapshot mới và không có attempt trước khi version mới ready. Existing-case handoff và command-integrity processing assert không có provider call ngoài đường dẫn cho phép. Mọi terminal `FAILED`, gồm `COMMAND_INTEGRITY`, phải có action `issue`; unknown/reconciliation phải không có action.

- [ ] **Step 2: Chuẩn bị môi trường tích hợp**

```bash
melos run env:sync
melos run env:doctor
```

Kết quả mong đợi: Profile đang active có cấu hình đồng bộ. Việc thiếu stack Supabase local chỉ chặn các test tích hợp phụ thuộc DB; các test fake/unit/SQL contract vẫn phải chạy bình thường.

- [ ] **Step 3: Chạy Focused và Repository Verification**

```bash
melos bootstrap
melos run codegen
melos run analyze
melos run test
bash scripts/ci/verify_harness.sh
cd apps/erp && flutter test
cd ../messaging_worker && dart test
cd ../..
git diff --check
```

- [ ] **Step 4: Rà soát phạm vi mã nguồn được sinh ra và SQL**

Xác nhận không có timestamp migration, không truy cập trực tiếp bảng Sales/Partner, không dùng raw callback/provider payload, không chỉnh sửa thủ công code sinh tự động, và `-- Touches:` chính xác. Assert draft 007 đã fold repair và xanh trước draft 008/009; file repair `008_einvoice_s2b_contract_repair.sql` không còn tồn tại; mọi persisted e-invoice entity mới có `version`; `submitted_at` không được set trong `prepare_issuance_publish`; không có `dispatch_barrier_crossed_at`, `failure_origin`, hoặc `scheduled_command_id` trên canonical entities.

- [ ] **Step 5: Chạy GitNexus Change Detection trước commit được ủy quyền**

```text
detect_changes(scope: compare, base_ref: main)
```

Rà soát các symbol/flow bị ảnh hưởng chỉ nằm trong phạm vi S3a/S3b/S3c. Điều tra các tác động ngoài dự kiến tới S4/S5, IAM, platform scheduler, hoặc trực tiếp tới các bảng nguồn trước khi tiếp tục.

- [ ] **Step 6: Cập nhật Traceability và Roadmap dựa trên bằng chứng thực tế**

Chỉ đánh dấu các dòng BE/Worker là `done` khi các focused test và repository test đã pass. Giữ BE ở trạng thái `in_progress` kèm ghi chú rõ ràng rằng SQL đang ở dạng draft chưa promote nếu việc deploy lên production là một phần định nghĩa của lane. Chỉ đánh dấu FE là `done` khi host thực tế của Theme 05 đã import integration component. Chỉ đánh dấu E2E là `done` khi điều kiện tiên quyết của S2 và các bài test mediator/worker đều pass; nếu không, ghi nhận rõ `blocked by S2` đúng như định nghĩa trong roadmap.

- [ ] **Step 7: Ranh giới Commit cuối cùng (chỉ khi có ủy quyền)**

```bash
git add modules/einvoice/infrastructure/test/einvoice_slice3_integration_test.dart docs/themes/TH-08-e-invoice
git commit -m "test(einvoice): verify and trace slice 3 issuance"
```

---

## Danh sách tự kiểm tra (Self-Review Checklist)

- [ ] Mỗi dòng hợp đồng của S3 đều map tới ít nhất một handler, gateway/RPC, và scenario ID cụ thể.
- [ ] Auto issue chỉ được kích hoạt bởi các typed source event và an toàn khi nhận duplicate event qua inbox.
- [ ] Sales completion là nguồn duy nhất tạo `AutomaticTriggerProcessRecord`; Partner update chỉ tiếp tục process `PENDING_REEVALUATION` hiện có và không đổi original business/provider identity.
- [ ] `AutomaticTriggerProcessRecord` có đủ SalesOrder/version, trigger key, status, retry count, next retry, blocker, completion reference, lock, timestamps và version.
- [ ] Các luồng Poll/callback/result dùng chung typed evidence và đảm bảo tính idempotency khi chuyển sang terminal state.
- [ ] `submitted_at` chỉ ghi ngay trước provider HTTP call; canonical status `SUBMITTED` là no-republish barrier, không thêm barrier field.
- [ ] `issuance_attempts` có đủ 31 field canonical, `AttemptSnapshot` đủ 11 component, và các persisted S2 entities có `version bigint` được increment khi mutation.
- [ ] `COMMAND_INTEGRITY` có bounded technical retry; khi terminal trước provider call, attempt `FAILED`, không gọi provider và projection có action `issue` sau readiness recheck.
- [ ] Mọi `FAILED` definite có cùng canonical action rule; mọi post-barrier ambiguity đi reconciliation và không có action.
- [ ] `IssuanceAttempt`/`ReconciliationCase` không có field ngoài canonical; poll identity nằm trong technical internal-command composition.
- [ ] Không có bất kỳ kết quả mơ hồ nào có thể dẫn đến việc gọi publish sang provider lần thứ hai.
- [ ] Pending `ReconciliationCase` có sẵn trước S3 được backfill/seed vào poll command idempotently; queue row không thay thế authoritative case.
- [ ] Lần kiểm tra thứ 5 không xác định sẽ chuyển trạng thái thành `UNRESOLVED` và giữ nguyên business lock.
- [ ] `UNRESOLVED` dừng auto-poll nhưng callback terminal đã xác thực/correlate đúng vẫn có thể chuyển case sang `RESOLVED`; callback invalid/undetermined giữ lock và mọi nhánh đều không republish.
- [ ] Quá trình Finalization recovery sử dụng provider success evidence đã lưu và không gọi provider thêm lần nào.
- [ ] Lệnh Retry chỉ chấp nhận definite failure và tạo attempt mới mà không làm thay đổi lịch sử cũ.
- [ ] Retry cùng SalesOrder version reuse đúng `BuyerInvoiceCompletion LOCKED`/lineage và không resolve Theme 03; retry version mới không reuse completion cũ và chỉ tạo attempt sau readiness/completion của version mới.
- [ ] FE lấy tenant/user thông qua `IExecutionContext` và thực thi qua `IModuleMediator`.
- [ ] Nhãn nút UI giữ nguyên là `Phát hành HĐĐT`; không tạo thêm action `Thử lại` riêng biệt.
- [ ] SG-04 tiếp tục chỉ chạy ở server-side và không thêm trang đối soát giao diện nào ngoài phạm vi.
- [ ] Chỉ dùng Draft SQL, header/Touches đúng chính sách migration, không tạo timestamp migration.
- [ ] Trạng thái các Lane phản ánh trung thực về tiến độ S2, việc promote draft, và tính sẵn sàng của trang chủ Theme 05.

## Các hạng mục hoãn lại sau Slice 3 (Deferred Beyond Slice 3)

- Việc promote/apply các draft 007–009 và quy trình triển khai lên môi trường production.
- Trừu tượng hóa Scheduled Command dùng chung toàn nền tảng; S3 sử dụng cơ chế due-time cục bộ qua `enqueued_at` của e-invoice.
- Cơ chế broadcast realtime để invalidate cache; cơ chế polling projection của S2 FE tiếp tục là phương thức quan sát chuẩn.
- Giao diện vận hành đối soát chuyên dụng, công cụ giải quyết thủ công cho operator, và hạ tầng callback/edge deployment ngoài hợp đồng inbox an toàn.
- Các luồng công việc tải/in tài liệu hóa đơn đã phát hành (EP-03) và gửi hóa đơn / delivery (EP-04).
