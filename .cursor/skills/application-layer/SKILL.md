---
name: application-layer
description: Designs, generates, reviews, and refactors the Application layer for ERP Flutter/Dart modules — commands, queries, handlers, DTOs, ports, integration event handlers, and use-case orchestration. Use when working on module application packages, command/query handlers, application services, IIAMModule facade, or when the user mentions application layer, use case, command handler, query handler, or CQRS orchestration.
---

# Application Layer

## Mục đích

Application layer **điều phối use case** — không quyết định invariant nghiệp vụ (domain) và không gọi Supabase/SQL trực tiếp (infrastructure).

```text
Application điều phối use case đang được thực thi.
Domain quyết định hành vi nghiệp vụ hợp lệ.
Infrastructure triển khai kỹ thuật (RPC, views, cache, workers).
Presentation hiển thị cho người dùng.
```

**Đọc trước:** [reference.md](reference.md) · **Ví dụ Sales:** [examples.md](examples.md) · **DDD modeling:** [ddd-domain-modeling](../ddd-domain-modeling/SKILL.md)

---

## Khi nào dùng

- Scaffold hoặc mở rộng `modules/<module>/application/`
- Implement command/query handler cho use case mới
- Thiết kế port (read gateway, lookup service) cho infrastructure implement
- Review PR application — phát hiện business rule hoặc Supabase leak
- Map command từ DDD modeling sang code skeleton

---

## Workflow

### 1. Xác định scope use case

Từ DDD output, xác định:

```text
Mutation hay read?
  → Mutation: Command + CommandHandler
  → Read:     Query + QueryHandler + DTO

Aggregate root nào?
  → 1 command thường map 1 aggregate (checkout có thể orchestrate draft → order)

Cần snapshot/port ngoài module?
  → Application service / port interface (KHÔNG gọi module khác trực tiếp)

Cần idempotency?
  → `command.id` = message/command instance (tracing; mới mỗi lần gửi)
  → `idempotencyKey` ổn định qua retry cho mutation quan trọng (checkout/finalize, payment, cancel, stock, onboarding, complete return)
  → kèm `payloadHash`, `correlationId`, `causationId` khi contract yêu cầu
  → bảo vệ thực sự ở Postgres RPC — không chỉ Dart check
  → doc: docs/architecture/13-idempotency-and-message-processing.md
  → rule: .cursor/rules/vet45-idempotency-and-commands.mdc
```

### 2. Verify package boundaries

```text
Application MAY depend on:
  <module>_domain, <module>_integration_events,
  vet45_shared_domain, uuid, meta

Application MUST NOT depend on:
  <module>_infrastructure
  <module>_presentation
  other_module_domain (trừ shared kernel)
  supabase_flutter, drift, flutter SDK
```

Cross-module data: load qua **port interface** (application định nghĩa, infrastructure implement adapter).

### 3. Chọn cấu trúc thư mục

Theo convention hiện tại (`modules/sales/application/`):

**Quy tắc `lib/src/`:** mọi implementation nằm trong `lib/src/`; chỉ `lib/application.dart` (barrel) nằm ngoài `src/`. Package khác **không** import `src/` trực tiếp.

```text
modules/<module>/application/
  pubspec.yaml                          # vet45_<module>_application
  lib/
    application.dart                    # barrel — chỉ export public API
    src/
      contracts/
        i_command.dart, command_base.dart
        i_query.dart, query_base.dart
        i_iam_module.dart                 # public facade
      configurations/
        commands/
          i_command_handler.dart
          i_command_scheduler.dart        # optional
          internal_command_base.dart
        queries/
          i_query_handler.dart
      <aggregate>/                      # partner, partner_history (read model)
        commands/
          <use_case>/
            <use_case>_command.dart
            <use_case>_command_handler.dart
            <use_case>_command_validator.dart   # optional
        queries/
          <use_case>/
            <use_case>_query.dart
            <use_case>_query_handler.dart
        shared/                         # DTO/input dùng chéo use-case trong aggregate
      services/                           # application services, snapshot loaders
      ports/                              # IReadGateway, ILookupPort (interfaces)
      event_handlers/                     # integration event handlers
      internal_commands/                  # durable async self-commands
      notifications/                      # domain notification handlers (optional)
```

Nhóm theo **aggregate** (hoặc **read model** khi không phải aggregate), không nhóm theo `commands/` / `queries/` global hay feature area (profile/contact/status).

**Bắt buộc (module mới + aggregate đã guarded):** tách `commands/` và `queries/` — mỗi use case một subfolder riêng; không gộp command + query trong cùng folder; không đặt `*_command.dart` / `*_query.dart` phẳng ngay dưới `<aggregate>/`.

```text
# ĐÚNG — golden reference modules/partner/application/
partner/                             # Partner aggregate
  shared/
    person_profile_input.dart
  commands/
    create_partner/
      create_partner_command.dart
  queries/
    search_partners/
      search_partners_query.dart
partner_history/                     # PartnerHistoryView read model (không phải aggregate)
  shared/
    partner_transaction_type.dart
  commands/
    record_partner_history/
      record_partner_history_command.dart
  queries/
    get_partner_history/
      get_partner_history_query.dart

# SAI — command + query gộp chung folder
partner/search_partners/search_partners_query.dart

# SAI — feature area grouping
profile/search_partners/...

# SAI — flat aggregate folder
partner/
  create_partner_command.dart
```

DTO dùng chung trong cùng aggregate → `<aggregate>/shared/`. DTO/input dùng chéo aggregate → `src/shared/`. Port vẫn ở `src/ports/`.

**Legacy:** catalog (`custom_fields/`, `pricing/`) chưa migrate — partner + IAM (`identity/`, `platform/`, `authentication/`, `invitation/`, `tenant/`, `notification/`) là golden reference hiện tại.

**DTO colocation (bắt buộc):**

```text
1. Mỗi DTO = 1 file (cấm *_dtos.dart gom nhiều class)
2. DTO chỉ dùng bởi 1 command → `<aggregate>/commands/<use_case>/`
3. DTO chỉ dùng bởi 1 query → `<aggregate>/queries/<use_case>/`
4. DTO dùng bởi ≥2 use-case trong cùng aggregate → `<aggregate>/shared/`
5. DTO/input dùng chéo aggregate → `application/lib/src/shared/`
6. Cấm folder `application/lib/src/dto/` (global DTO bucket)
```

```text
# ĐÚNG — modules/partner/application/
partner/
  queries/
    search_partners/
      search_partners_query.dart
      partner_list_item_dto.dart
partner/shared/
  person_profile_input.dart

# SAI
src/dto/profile/partner_search_dtos.dart
profile/search_partners/...
```

CI: `scripts/ci/guard_application_use_case_layout.sh` + `scripts/ci/guard_application_dto_colocation.sh`.

### 4. Implement command

**Naming:** intent nghiệp vụ, không CRUD — xem [ddd-domain-modeling](../ddd-domain-modeling/SKILL.md).

```dart
final class AddProductToDraftCommand extends CommandBase<void> {
  AddProductToDraftCommand({
    String? id,
    required this.tenantId,
    required this.draftId,
    required this.productId,
    required this.quantity,
  }) : super(id);

  final String tenantId;
  final String draftId;
  final String productId;
  final int quantity;
}
```

**Handler flow (bắt buộc):**

```text
1. Load aggregate (IRepository từ domain)
2. Load snapshots qua port/application service (nếu cần)
3. Gọi method aggregate — KHÔNG duplicate business rule
4. Save aggregate
5. Clear domain events sau khi map sang integration events (outbox do RPC/infrastructure)
6. Trả TResult (void, Id, DTO tóm tắt — không trả aggregate)
```

```dart
final class AddProductToDraftCommandHandler
    implements ICommandHandler<AddProductToDraftCommand, void> {
  AddProductToDraftCommandHandler({
    required this.draftRepository,
    required this.productLookup,
    required this.stockChecker,
  });

  final ISalesOrderDraftRepository draftRepository;
  final IProductLookupPort productLookup;
  final IInventoryAvailabilityPort stockChecker;

  @override
  Future<void> handle(AddProductToDraftCommand command) async {
    final draft = await draftRepository.findById(command.draftId);
    // ... load snapshots, call draft.addProduct(...), save
  }
}
```

### 5. Implement query

Query **không** đổi state. Handler gọi **read gateway port** (infrastructure implement).

```dart
final class GetAllSalesOrderDraftQuery extends QueryBase<SalesOrderDraftListDto> {
  GetAllSalesOrderDraftQuery({String? id, required this.tenantId}) : super(id);
  final String tenantId;
}
```

```dart
final class GetAllSalesOrderDraftQueryHandler
    implements IQueryHandler<GetAllSalesOrderDraftQuery, SalesOrderDraftListDto> {
  GetAllSalesOrderDraftQueryHandler({required this.readGateway});
  final ISalesOrderDraftReadGateway readGateway;

  @override
  Future<SalesOrderDraftListDto> handle(GetAllSalesOrderDraftQuery query) {
    return readGateway.getAll(tenantId: query.tenantId);
  }
}
```

DTO = immutable, flat, presentation-safe. Không expose domain entity.

### 6. Định nghĩa ports

| Port (application) | Infrastructure implements |
|--------------------|---------------------------|
| `I<Aggregate>ReadGateway` | `Supabase<Aggregate>ReadGateway` via views |
| `I<Module>CommandGateway` | `Supabase<Module>CommandGateway` via RPC |
| `IProductLookupPort` | adapter gọi Catalog read contract |
| `IInventoryAvailabilityPort` | adapter gọi Inventory read contract |

Ports là `abstract interface class` trong `ports/` hoặc `services/`.

### 7. Integration event handlers

Khi module **consume** event từ module khác:

```text
event_handlers/<event_name>_handler.dart
  → validate payload
  → enqueue internal command với sourceEventId = event.id (dedup)
  → KHÔNG mutate state module khác; KHÔNG coi Inbox thay thế operation idempotency
  → xem docs/architecture/13-idempotency-and-message-processing.md
```

Khi module **publish**: domain event → map integration event trong handler hoặc RPC transaction (ưu tiên server-side outbox).

### 8. Public module facade

```dart
abstract interface class IIAMModule {
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command);
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query);
}
```

Presentation / app shell chỉ gọi `IIAMModule` — không gọi handler trực tiếp.

Handler registration nằm ở **infrastructure composition root**, không trong application.

### 8.1 Serializable internal commands (`json_serializable`)

Chỉ áp dụng cho class `implements ISerializableInternalCommand` từ `package:vet45_adapters/vet45_adapters.dart` (durable async pipeline):

```text
- @JsonSerializable(fieldRename: snake, includeIfNull: false) + part '*.g.dart'
- static const String type = 'module.action'
- fromJson(Map, {required String id}) + normalizeInternalCommandDeserializeJson
- toJson() => generated, strip 'id' khỏi payload (id = cột internal_commands.id)
- Registry wiring: vet45_generator trong infrastructure (melos run codegen)
```

Không dùng `json_serializable` cho business Command/Query/DTO thông thường trong cùng package.

### 9. Validate trước khi hoàn thành

Chạy review checklist trong [reference.md](reference.md#review-checklist).

---

## Required Agent Output

Khi thiết kế hoặc generate application layer:

```text
1.  Application responsibility summary
2.  Feature areas & use case list (command/query)
3.  Command → aggregate → handler dependencies map
4.  Query → DTO → read gateway map
5.  Ports/interfaces cần infrastructure implement
6.  Snapshot loaders / application services
7.  Integration event handlers (publish/consume)
8.  Internal commands plan (hoặc N/A)
9.  Folder structure proposal
10. pubspec dependencies
11. Handler skeletons (command + query)
12. DTO skeletons
13. IIAMModule wiring notes (composition root)
14. Review checklist (checked items)
15. Anti-pattern warnings
```

Code preferences:

```text
- abstract interface class cho ports và handler contracts
- constructor injection
- snake_case filenames; PascalCase classes
- CommandBase (UUID v4), QueryBase/InternalCommandBase (UUID v7)
- final class cho command/query/handler concrete
- Future<T> + domain exceptions (trừ khi project dùng Result<T, Failure>)
```

---

## Mapping với các layer khác

| Concern | Layer |
|---------|-------|
| Invariant, aggregate method | Domain |
| Orchestration, snapshot load, DTO | Application |
| RPC, repository impl, read gateway impl | Infrastructure |
| Widget, controller, UI state | Presentation |

**Đọc DDD / 01-domain-model trước khi viết handler** — command list và aggregate boundary đến từ [ddd-domain-modeling](../ddd-domain-modeling/SKILL.md). Implement domain trước: [domain-layer](../domain-layer/SKILL.md).

**Đọc infrastructure khi định nghĩa port** — gateway/RPC naming từ [infrastructure-layer](../infrastructure-layer/SKILL.md).

---

## Test harness

Khi viết handler test, dùng `vet45_shared_testing`:

```dart
import 'package:vet45_shared_testing/shared_testing.dart';

final pipeline = PipelineTestHarness<MyCommand, MyResult>(
  handler: (cmd) async => handler.handle(cmd),
  behaviors: [validationBehavior],
).build();

final bus = InMemoryCommandBus();
bus.register<MyCommand, MyResult>(pipeline);
```

Canonical example: `packages/vet45_shared/testing/test/shared_testing_test.dart`

---

## IAM access plumbing (minimal — align SRS sau)

Host (`apps/erp/lib/core/di/injection.dart`) khởi tạo `IamStartup` và đăng ký:

- `IExecutionContext`, `IPermissionChecker`, `ITenantAccessChecker`
- `ICurrentUser` / `ICurrentTenant` (snapshot từ `IamSession`)

Module khác nhận 3 service này qua `<Module>Startup.initialize(...)` và truyền vào `DefaultCommandPipeline.buildBusinessPipeline`:

```dart
DefaultCommandPipeline.buildBusinessPipeline<MyCommand, void, MyHandler>(
  container: container,
  handler: container.get<MyHandler>(),
  invoke: (command, handler) => handler.handle(command),
  accessMetadata: moduleAccessMetadataRegistry,
  permissionChecker: permissionChecker,      // từ IAM host
  tenantAccessChecker: tenantAccessChecker,  // từ IAM host
);
```

Command tenant-scoped: `implements ITenantScopedCommand` + `@RequiresTenant()`. Command cần quyền: `@RequiresPermission(<Module>Permissions.<action>)` — constant `static const` trong `{module}/domain/`, **không** hardcode string literal trong application/infrastructure.

Reference: `modules/iam/infrastructure/lib/src/configuration/iam_startup.dart`, `modules/iam/infrastructure/lib/src/configuration/mediation/mediation_module.dart`.

---

## Anti-patterns (từ chối)

```text
- Business rule trong command handler (phải ở aggregate/domain rule)
- Supabase/RPC/SQL trong application
- Query handler trả domain aggregate
- Presentation gọi repository hoặc handler trực tiếp
- Import infrastructure vào application
- CRUD command (UpdateOrder, SaveDraft)
- God handler orchestrate nhiều aggregate không cần thiết
- double cho tiền — dùng Money từ shared domain
- Publish integration event trực tiếp bỏ qua outbox cho mutation quan trọng
- Dùng `command.id` làm `idempotencyKey` khi client retry; thiếu `idempotencyKey` trên checkout/payment/cancel/stock
- Cross-module import domain entity thay vì snapshot/port
- Global `application/lib/src/dto/` folder hoặc file `*_dtos.dart` gom nhiều DTO class
```

---

## Tài liệu thêm

- Chi tiết contracts, handler flows, ports: [reference.md](reference.md)
- Ví dụ Sales module: [examples.md](examples.md)
- Canonical source: `docs/application_layer_skill.md`
- Idempotency: `docs/architecture/13-idempotency-and-message-processing.md` · rule `.cursor/rules/vet45-idempotency-and-commands.mdc`
- DDD modeling: [ddd-domain-modeling](../ddd-domain-modeling/SKILL.md)
- Infrastructure ports: [infrastructure-layer](../infrastructure-layer/SKILL.md)
- Module template: `docs/MODULES_IMPLEMENTATION_TEMPLATE.md`
