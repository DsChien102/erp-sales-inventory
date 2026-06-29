# Module Architecture Template — `{{ModuleName}}`

> Template này được sử dụng khi tạo một module mới trong hệ thống Flutter/Dart theo hướng **Client Modular Monolith + Supabase/Postgres RPC**.
> Mỗi module cần có ranh giới rõ ràng, sở hữu use case của riêng mình, không gọi trực tiếp implementation nội bộ của module khác, và chỉ giao tiếp liên module thông qua **Integration Event**, **Outbox/Inbox**, hoặc public contract đã được cho phép.

---

## 1. Module Overview

### 1.1 Module Name

```text
{{module_name}}
```

Ví dụ:

```text
sales
inventory
communication
customer
payment
```

### 1.2 Business Responsibility

Module `{{ModuleName}}` chịu trách nhiệm cho:

```text
- {{Responsibility 1}}
- {{Responsibility 2}}
- {{Responsibility 3}}
```

Module này **không chịu trách nhiệm** cho:

```text
- {{Out of scope 1}}
- {{Out of scope 2}}
```

### 1.3 Bounded Context

```text
Bounded Context: {{BoundedContextName}}
```

Ngôn ngữ nghiệp vụ chính trong module:

| Term               | Meaning     |
| ------------------ | ----------- |
| `{{BusinessTerm}}` | {{Meaning}} |
| `{{BusinessTerm}}` | {{Meaning}} |

---

## 2. Architectural Rules

### 2.1 Module Boundary Rules

Module `{{ModuleName}}` phải tuân thủ các rule sau:

```text
1. Module không import trực tiếp implementation nội bộ của module khác.
2. Module chỉ expose public contract cần thiết.
3. Mỗi Layer là một module riêng
4. Domain layer không phụ thuộc Flutter, Supabase, database, HTTP, UI hoặc state management.
5. Application layer điều phối use case, command, query, event handler.
6. Infrastructure layer implement repository, RPC gateway, realtime gateway, local cache và external adapter.
7. Integration events là contract public để module khác consume.
8. Presentation layer là optional, chỉ dùng khi module cần đóng gói widget/screen riêng.
9. Business mutation quan trọng phải đi qua Supabase/Postgres RPC.
10. Outbox/Inbox durable không chạy trong Flutter app; chúng nằm ở Supabase/Postgres hoặc worker/server-side.
11. Flutter event bus chỉ dùng cho app-local event, không dùng thay thế server-side outbox.
12. Mỗi layer package enforce `lib/<layer>.dart` (barrel) + `lib/src/` (private implementation); package ngoài không import `src/` trực tiếp.
```

---

## 3. Package Structure

### 3.1 Recommended Package Layout

**Quy tắc `lib/src/`:** mỗi layer package có barrel `lib/<layer>.dart` và implementation trong `lib/src/`. Package ngoài chỉ import barrel, không import `src/` trực tiếp.

```text
modules/
  {{module_name}}/
    application/
      pubspec.yaml
      lib/
        application.dart
        src/
          contracts/
            {{module_name}}_module.dart
            command.dart
            query.dart
            command_handler.dart
            query_handler.dart
            internal_command.dart
            internal_command_handler.dart
          commands/
            {{use_case_name}}/
              {{use_case_name}}_command.dart
              {{use_case_name}}_command_handler.dart
              {{use_case_name}}_command_validator.dart
          queries/
            {{query_name}}/
              {{query_name}}_query.dart
              {{query_name}}_query_handler.dart
              {{query_name}}_dto.dart
          event_handlers/
            {{integration_event_name}}_handler.dart
          internal_commands/
            {{internal_command_name}}_command.dart
            {{internal_command_name}}_command_handler.dart
          notifications/
            {{domain_notification_name}}.dart
            {{domain_notification_name}}_handler.dart
          services/
            {{application_service_name}}.dart
          ports/

    domain/
      pubspec.yaml
      lib/
        domain.dart
        src/
          {{aggregate_name}}/
            {{aggregate_name}}.dart
            {{aggregate_name}}_id.dart
            {{aggregate_name}}_repository.dart
            {{value_object_name}}.dart
            events/
              {{domain_event_name}}.dart
            rules/
              {{business_rule_name}}.dart

    infrastructure/
      pubspec.yaml
      lib/
        infrastructure.dart
        src/
          {{module_name}}_module.dart
          configuration/
            {{module_name}}_startup.dart
            {{module_name}}_composition_root.dart
            logging/
            data_access/
              data_access_module.dart
            events_bus/
            outbox/
              outbox_module.dart
            processing/
              processing_module.dart
              commands_executor.dart
              {{module_name}}_command_pipeline.dart
              generated/
              outbox/
              inbox/
              internal_commands/
              {{module_name}}_notification_dispatcher.dart
              {{module_name}}_integration_event_dispatcher.dart
            mediation/
              mediation_module.dart
          domain/
            {{aggregate_name}}/
              {{aggregate_name}}_mapper.dart
              supabase_{{aggregate_name}}_repository.dart
              supabase_{{aggregate_name}}_read_gateway.dart
              supabase_{{aggregate_name}}_command_gateway.dart
            shared/
          rpc/
            i_{{module_name}}_rpc_client.dart
            supabase_{{module_name}}_rpc_client.dart
          supabase/
            supabase_query_executor.dart
          adapters/
          errors/
            {{module_name}}_error_mapper.dart
            {{module_name}}_infrastructure_exception.dart

    integration_events/
      pubspec.yaml
      lib/
        integration_events.dart
        src/
          integration_event.dart
          events/
            {{integration_event_name}}.dart

    presentation/
      pubspec.yaml
      lib/
        presentation.dart
        src/
          screens/
            {{screen_name}}_screen.dart
          widgets/
            {{widget_name}}.dart
          controllers/
            {{screen_name}}_controller.dart
          state/
            {{screen_name}}_state.dart
```

### 3.2 Public Barrel File

Mỗi layer của một module là một Dart package riêng.

File barrel nằm tại:

```text
lib/<layer>.dart
```

Ví dụ: `lib/application.dart`, `lib/domain.dart`, `lib/infrastructure.dart`.

Chỉ export public API cần thiết từ `lib/src/...`:

```dart
library;

export 'src/contracts/i_iam_module.dart';
export 'src/configuration/{{module_name}}_startup.dart';
// ... chỉ những gì consumer được phép dùng (startup, module facade, public errors)
```

Không export:

```text
- repository implementation
- internal command handler
- domain entity nội bộ nếu không cần thiết
- mapper
- RPC implementation
- persistence model
```

---

## 4. Layer Responsibilities

### 4.1 Domain Layer

Domain layer chứa business model và business rule.

Domain layer được phép chứa:

```text
- Aggregate
- Entity
- Value Object
- Domain Event
- Business Rule
- Repository interface
- Domain service nếu thật sự cần
```

Domain layer không được phụ thuộc:

```text
- Flutter widget
- Riverpod/BLoC/GetX
- Supabase client
- HTTP client
- SQLite/Hive
- JSON serialization framework nếu không cần
- Infrastructure service
```

Ví dụ repository interface:

```dart
abstract interface class {{AggregateName}}Repository {
  Future<{{AggregateName}}?> findById({{AggregateName}}Id id);

  Future<void> save({{AggregateName}} aggregate);
}
```

Ví dụ domain event:

```dart
abstract class DomainEvent {
  const DomainEvent({
    required this.id,
    required this.occurredAt,
  });

  final String id;
  final DateTime occurredAt;
}

final class {{DomainEventName}} extends DomainEvent {
  const {{DomainEventName}}({
    required super.id,
    required super.occurredAt,
    required this.{{fieldName}},
  });

  final String {{fieldName}};
}
```

Ví dụ aggregate root:

```dart
abstract class AggregateRoot {
  final List<DomainEvent> _domainEvents = [];

  List<DomainEvent> get domainEvents {
    return List.unmodifiable(_domainEvents);
  }

  void addDomainEvent(DomainEvent event) {
    _domainEvents.add(event);
  }

  void clearDomainEvents() {
    _domainEvents.clear();
  }
}
```

---

### 4.2 Application Layer

Application layer điều phối use case.

Application layer được phép chứa:

```text
- Command
- Command Handler
- Query
- Query Handler
- DTO
- Validator
- Application Service
- Domain Notification
- Integration Event Handler
- Internal Command
- Internal Command Handler
- Port/interface gọi ra ngoài
```

Application layer không được chứa:

```text
- Flutter widget
- Supabase query cụ thể
- SQL/RPC implementation cụ thể
- UI state
```

#### 4.2.1 Command Contract

```dart
abstract class Command<TResult> {
  const Command({
    required this.id,
  });

  final String id;
}

abstract interface class CommandHandler<TCommand extends Command<TResult>, TResult> {
  Future<TResult> handle(TCommand command);
}
```

#### 4.2.2 Query Contract

```dart
abstract class Query<TResult> {
  const Query();
}

abstract interface class QueryHandler<TQuery extends Query<TResult>, TResult> {
  Future<TResult> handle(TQuery query);
}
```

#### 4.2.3 Internal Command Contract

Durable async commands (`ISerializableInternalCommand`) dùng **`json_serializable`** trong application package. `command_type` và row `id` lưu ở cột DB — **không** trong payload JSON.

```dart
abstract interface class ISerializableInternalCommand {
  String get commandType;
  String get tenantId;
  Map<String, dynamic> toJson();
}
```

Tooling (`modules/{{module_name}}/application/pubspec.yaml`):

```yaml
dependencies:
  json_annotation: ^4.9.0

dev_dependencies:
  build_runner: ^2.15.0
  json_serializable: ^6.9.0
```

Template command:

```dart
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
final class {{InternalCommandName}}Command extends InternalCommandBase<void>
    implements ISerializableInternalCommand {
  {{InternalCommandName}}Command({String? id, required this.tenantId, ...}) : super(id);

  static const String type = '{{module_name}}.{{internal_command_name}}';
  @override String get commandType => type;
  @override final String tenantId;

  factory {{InternalCommandName}}Command.fromJson(Map<String, dynamic> json, {required String id}) =>
      _${{InternalCommandName}}CommandFromJson(
        normalizeInternalCommandDeserializeJson(json, rowId: id),
      );

  @override
  Map<String, dynamic> toJson() {
    final map = _${{InternalCommandName}}CommandToJson(this);
    map.remove('id');
    return map;
  }
}
```

Registry `commandType → fromJson` do `vet45_generator` sinh trong infrastructure (`melos run codegen`).

```dart
abstract interface class InternalCommandHandler<TCommand extends InternalCommand> {
  Future<void> handle(TCommand command);
}
```

#### 4.2.4 Module Contract

Mỗi module expose một contract chính để app shell hoặc composition root gọi vào.

```dart
abstract interface class {{ModuleName}}Module {
  Future<TResult> executeCommand<TResult>(
    Command<TResult> command,
  );

  Future<TResult> executeQuery<TResult>(
    Query<TResult> query,
  );
}
```

Implementation:

```dart
final class {{ModuleName}}ModuleImpl implements {{ModuleName}}Module {
  {{ModuleName}}ModuleImpl({
    required this.commandBus,
    required this.queryBus,
  });

  final CommandBus commandBus;
  final QueryBus queryBus;

  @override
  Future<TResult> executeCommand<TResult>(
    Command<TResult> command,
  ) {
    return commandBus.execute(command);
  }

  @override
  Future<TResult> executeQuery<TResult>(
    Query<TResult> query,
  ) {
    return queryBus.execute(query);
  }
}
```

---

### 4.3 Infrastructure Layer

Infrastructure layer implement chi tiết kỹ thuật.

Infrastructure layer được phép chứa:

```text
- Supabase RPC client
- Repository implementation
- Realtime gateway
- Local cache
- Outbox/Inbox gateway nếu chạy server-side Dart worker
- Mapper DTO <-> domain
- Composition root
- External provider adapter
```

Infrastructure layer không được chứa:

```text
- Business rule thuần domain
- UI widget
- Use case orchestration phức tạp
```

Ví dụ RPC client interface:

```dart
abstract interface class {{ModuleName}}RpcClient {
  Future<Map<String, dynamic>> callRpc(
    String functionName, {
    Map<String, dynamic>? params,
  });
}
```

Supabase implementation:

```dart
final class Supabase{{ModuleName}}RpcClient implements {{ModuleName}}RpcClient {
  Supabase{{ModuleName}}RpcClient({
    required this.supabase,
  });

  final dynamic supabase;

  @override
  Future<Map<String, dynamic>> callRpc(
    String functionName, {
    Map<String, dynamic>? params,
  }) async {
    final result = await supabase.rpc(
      functionName,
      params: params ?? <String, dynamic>{},
    );

    return Map<String, dynamic>.from(result as Map);
  }
}
```

Ví dụ repository implementation:

```dart
final class Supabase{{AggregateName}}Repository
    implements {{AggregateName}}Repository {
  Supabase{{AggregateName}}Repository({
    required this.rpcClient,
  });

  final {{ModuleName}}RpcClient rpcClient;

  @override
  Future<{{AggregateName}}?> findById({{AggregateName}}Id id) async {
    final result = await rpcClient.callRpc(
      '{{module_name}}_get_{{aggregate_name}}',
      params: {
        'p_id': id.value,
      },
    );

    return {{AggregateName}}Mapper.fromJson(result);
  }

  @override
  Future<void> save({{AggregateName}} aggregate) async {
    await rpcClient.callRpc(
      '{{module_name}}_save_{{aggregate_name}}',
      params: {
        'p_payload': {{AggregateName}}Mapper.toJson(aggregate),
      },
    );
  }
}
```

---

### 4.4 Integration Events Layer

Integration events là contract public để module khác consume.

Integration event phải:

```text
- Là event ở thì quá khứ.
- Không chứa domain object nội bộ.
- Không expose implementation detail.
- Chứa dữ liệu tối thiểu để module khác xử lý.
- Có version nếu payload có khả năng thay đổi.
```

Base contract:

```dart
abstract class IntegrationEvent {
  const IntegrationEvent({
    required this.id,
    required this.occurredAt,
  });

  final String id;
  final DateTime occurredAt;

  String get eventType;

  int get version => 1;

  Map<String, dynamic> toJson();
}
```

Ví dụ:

```dart
final class {{IntegrationEventName}} extends IntegrationEvent {
  const {{IntegrationEventName}}({
    required super.id,
    required super.occurredAt,
    required this.tenantId,
    required this.{{entityId}},
  });

  final String tenantId;
  final String {{entityId}};

  @override
  String get eventType => '{{module_name}}.{{entity_name}}.{{event_name}}';

  @override
  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      '{{entity_id}}': {{entityId}},
      'version': version,
    };
  }
}
```

Naming convention:

```text
sales.order.created
sales.order.cancelled
payment.payment_confirmed
inventory.stock_reserved
communication.notification_created
```

---

### 4.5 Presentation Layer Optional

Presentation layer chỉ tồn tại nếu module cần đóng gói UI riêng.

Presentation layer được phép chứa:

```text
- Screen
- Widget
- Controller/Notifier/BLoC
- UI state
- Form model
- Route definition
```

Presentation layer không được chứa:

```text
- Business rule quan trọng
- Supabase RPC trực tiếp
- Cross-module business workflow
```

Controller nên gọi application contract:

```dart
final class {{ScreenName}}Controller {
  {{ScreenName}}Controller({
    required this.module,
  });

  final {{ModuleName}}Module module;

  Future<void> submit() async {
    await module.executeCommand(
      {{UseCaseName}}Command(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        // params
      ),
    );
  }
}
```

---

## 5. Messaging Contracts

### 5.1 Command Bus

```dart
typedef AnyCommandHandler = Future<dynamic> Function(Command<dynamic> command);

final class CommandBus {
  final Map<Type, AnyCommandHandler> _handlers = {};

  void register<TCommand extends Command<TResult>, TResult>(
    Future<TResult> Function(TCommand command) handler,
  ) {
    _handlers[TCommand] = (command) {
      return handler(command as TCommand);
    };
  }

  Future<TResult> execute<TResult>(Command<TResult> command) async {
    final handler = _handlers[command.runtimeType];

    if (handler == null) {
      throw StateError(
        'No command handler registered for ${command.runtimeType}',
      );
    }

    return await handler(command) as TResult;
  }
}
```

### 5.2 Query Bus

```dart
typedef AnyQueryHandler = Future<dynamic> Function(Query<dynamic> query);

final class QueryBus {
  final Map<Type, AnyQueryHandler> _handlers = {};

  void register<TQuery extends Query<TResult>, TResult>(
    Future<TResult> Function(TQuery query) handler,
  ) {
    _handlers[TQuery] = (query) {
      return handler(query as TQuery);
    };
  }

  Future<TResult> execute<TResult>(Query<TResult> query) async {
    final handler = _handlers[query.runtimeType];

    if (handler == null) {
      throw StateError(
        'No query handler registered for ${query.runtimeType}',
      );
    }

    return await handler(query) as TResult;
  }
}
```

### 5.3 App-local Event Bus

App-local event bus chỉ dùng trong Flutter process.

```dart
abstract class AppEvent {
  const AppEvent({
    required this.id,
    required this.occurredAt,
  });

  final String id;
  final DateTime occurredAt;
}

typedef AppEventHandler<T extends AppEvent> = Future<void> Function(T event);

abstract interface class AppEventBus {
  void publish<T extends AppEvent>(T event);

  void subscribe<T extends AppEvent>(
    AppEventHandler<T> handler,
  );
}
```

Không dùng `AppEventBus` để thay thế:

```text
- server-side outbox
- durable integration event
- cross-device synchronization
- background processing
```

---

## 6. Outbox, Inbox, Internal Command

### 6.1 Server-side Outbox

Outbox dùng để lưu integration event cần publish ra ngoài module.

```text
{{module_name}}.outbox_messages
  id
  event_type
  payload
  occurred_at
  processed_at
  failed_at
  error
  retry_count
```

RPC command chịu trách nhiệm ghi business data và outbox event trong cùng transaction.

```sql
insert into {{module_name}}.outbox_messages (
  id,
  event_type,
  payload,
  occurred_at,
  processed_at
)
values (
  gen_random_uuid(),
  '{{module_name}}.{{entity_name}}.{{event_name}}',
  jsonb_build_object(
    'tenant_id', p_tenant_id,
    '{{entity_id}}', v_entity_id
  ),
  now(),
  null
);
```

### 6.2 Server-side Inbox

Inbox dùng để lưu integration event module nhận được từ module khác.

```text
{{module_name}}.inbox_messages
  id
  event_type
  payload
  occurred_at
  processed_at
  failed_at
  error
  retry_count
```

Idempotency rule:

```sql
insert into {{module_name}}.inbox_messages (
  id,
  event_type,
  payload,
  occurred_at,
  processed_at
)
values (
  p_event_id,
  p_event_type,
  p_payload,
  p_occurred_at,
  null
)
on conflict (id) do nothing;
```

### 6.3 Internal Commands

Internal command dùng khi module nhận event và cần thay đổi state của chính nó ở transaction khác.

```text
{{module_name}}.internal_commands
  id
  command_type
  payload
  enqueued_at
  processed_at
  failed_at
  error
  retry_count
```

---

## 7. Composition Root

### 7.1 Purpose

Composition root chịu trách nhiệm tạo object graph cho module.

Composition root được phép biết:

```text
- concrete repository implementation
- RPC client
- command handler
- query handler
- event handler
- controller
- module facade
```

Các layer khác không nên tự tạo dependency concrete.

---

### 7.2 Composition Root Contract

```dart
final class {{ModuleName}}CompositionRoot {
  {{ModuleName}}CompositionRoot({
    required this.supabase,
    required this.appEventBus,
  });

  final dynamic supabase;
  final AppEventBus appEventBus;

  late final {{ModuleName}}RpcClient rpcClient;

  late final {{AggregateName}}Repository {{aggregateName}}Repository;

  late final CommandBus commandBus;
  late final QueryBus queryBus;

  late final {{ModuleName}}Module module;

  bool _initialized = false;

  {{ModuleName}}Module initialize() {
    if (_initialized) {
      return module;
    }

    rpcClient = Supabase{{ModuleName}}RpcClient(
      supabase: supabase,
    );

    {{aggregateName}}Repository = Supabase{{AggregateName}}Repository(
      rpcClient: rpcClient,
    );

    commandBus = CommandBus();
    queryBus = QueryBus();

    _registerCommandHandlers();
    _registerQueryHandlers();
    _registerIntegrationEventHandlers();
    _registerAppLocalEventHandlers();

    module = {{ModuleName}}ModuleImpl(
      commandBus: commandBus,
      queryBus: queryBus,
    );

    _initialized = true;

    return module;
  }

  void _registerCommandHandlers() {
    final handler = {{UseCaseName}}CommandHandler(
      repository: {{aggregateName}}Repository,
      appEventBus: appEventBus,
    );

    commandBus.register<{{UseCaseName}}Command, {{ResultType}}>(
      handler.handle,
    );
  }

  void _registerQueryHandlers() {
    final handler = {{QueryName}}QueryHandler(
      repository: {{aggregateName}}Repository,
    );

    queryBus.register<{{QueryName}}Query, {{QueryResultType}}>(
      handler.handle,
    );
  }

  void _registerIntegrationEventHandlers() {
    // Register handlers for integration events consumed by this module.
    //
    // Example:
    // integrationEventRegistry.register<SalesOrderCreatedIntegrationEvent>(
    //   eventType: 'sales.order.created',
    //   handler: SalesOrderCreatedIntegrationEventHandler(...).handle,
    // );
  }

  void _registerAppLocalEventHandlers() {
    // Register app-local event handlers if needed.
    //
    // Example:
    // appEventBus.subscribe<TenantChangedInAppEvent>((event) async {
    //   await module.executeCommand(...);
    // });
  }
}
```

---

### 7.3 Startup

Startup là entrypoint để app shell initialize module.

```dart
final class {{ModuleName}}Startup {
  static {{ModuleName}}Module initialize({
    required dynamic supabase,
    required AppEventBus appEventBus,
  }) {
    final compositionRoot = {{ModuleName}}CompositionRoot(
      supabase: supabase,
      appEventBus: appEventBus,
    );

    return compositionRoot.initialize();
  }
}
```

App shell sử dụng:

```dart
final {{moduleName}}Module = {{ModuleName}}Startup.initialize(
  supabase: supabase,
  appEventBus: appEventBus,
);
```

---

## 8. Command Example

### 8.1 Command

```dart
final class {{UseCaseName}}Command extends Command<{{ResultType}}> {
  const {{UseCaseName}}Command({
    required super.id,
    required this.tenantId,
    required this.{{fieldName}},
  });

  final String tenantId;
  final String {{fieldName}};
}
```

### 8.2 Command Handler

```dart
final class {{UseCaseName}}CommandHandler {
  {{UseCaseName}}CommandHandler({
    required this.repository,
    required this.appEventBus,
  });

  final {{AggregateName}}Repository repository;
  final AppEventBus appEventBus;

  Future<{{ResultType}}> handle(
    {{UseCaseName}}Command command,
  ) async {
    final result = await repository.{{useCaseMethod}}(
      tenantId: command.tenantId,
      {{fieldName}}: command.{{fieldName}},
    );

    appEventBus.publish(
      {{UseCaseName}}CompletedInAppEvent(
        id: command.id,
        occurredAt: DateTime.now().toUtc(),
        tenantId: command.tenantId,
      ),
    );

    return result;
  }
}
```

Rule:

```text
Command handler trong Flutter có thể publish app-local event sau khi RPC thành công.
Command handler trong Flutter không ghi durable outbox trực tiếp.
Durable outbox phải được ghi trong Supabase/Postgres RPC.
```

---

## 9. Query Example

### 9.1 Query

```dart
final class {{QueryName}}Query extends Query<{{QueryResultType}}> {
  const {{QueryName}}Query({
    required this.tenantId,
  });

  final String tenantId;
}
```

### 9.2 DTO

```dart
final class {{QueryName}}Dto {
  const {{QueryName}}Dto({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory {{QueryName}}Dto.fromJson(Map<String, dynamic> json) {
    return {{QueryName}}Dto(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}
```

### 9.3 Query Handler

```dart
final class {{QueryName}}QueryHandler {
  {{QueryName}}QueryHandler({
    required this.repository,
  });

  final {{AggregateName}}Repository repository;

  Future<{{QueryResultType}}> handle(
    {{QueryName}}Query query,
  ) async {
    return repository.{{queryMethod}}(
      tenantId: query.tenantId,
    );
  }
}
```

---

## 10. Integration Event Handler Example

### 10.1 Consumed Event

```dart
final class {{ConsumedIntegrationEventName}} extends IntegrationEvent {
  const {{ConsumedIntegrationEventName}}({
    required super.id,
    required super.occurredAt,
    required this.tenantId,
    required this.sourceEntityId,
  });

  final String tenantId;
  final String sourceEntityId;

  @override
  String get eventType => '{{source_module}}.{{entity}}.{{event}}';

  @override
  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'source_entity_id': sourceEntityId,
      'version': version,
    };
  }
}
```

### 10.2 Handler

```dart
final class {{ConsumedIntegrationEventName}}Handler {
  {{ConsumedIntegrationEventName}}Handler({
    required this.internalCommandScheduler,
  });

  final InternalCommandScheduler internalCommandScheduler;

  Future<void> handle({{ConsumedIntegrationEventName}} event) async {
    await internalCommandScheduler.enqueue(
      {{InternalCommandName}}(
        id: event.id,
        enqueuedAt: DateTime.now().toUtc(),
        tenantId: event.tenantId,
        sourceEntityId: event.sourceEntityId,
      ),
    );
  }
}
```

Rule:

```text
Integration Event Handler không nên chứa business mutation phức tạp.
Nếu cần thay đổi state module nhận, hãy enqueue Internal Command.
```

---

## 11. Internal Command Example

### 11.1 Internal Command

```dart
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
final class {{InternalCommandName}}Command extends InternalCommandBase<void>
    implements ISerializableInternalCommand {
  {{InternalCommandName}}Command({
    String? id,
    required this.tenantId,
    required this.sourceEntityId,
  }) : super(id);

  static const String type = '{{module_name}}.{{internal_command_name}}';

  @override
  String get commandType => type;

  @override
  final String tenantId;
  final String sourceEntityId;

  factory {{InternalCommandName}}Command.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) =>
      _${{InternalCommandName}}CommandFromJson(
        normalizeInternalCommandDeserializeJson(json, rowId: id),
      );

  @override
  Map<String, dynamic> toJson() {
    final map = _${{InternalCommandName}}CommandToJson(this);
    map.remove('id');
    return map;
  }
}
```

### 11.2 Internal Command Handler

```dart
final class {{InternalCommandName}}Handler {
  {{InternalCommandName}}Handler({
    required this.repository,
  });

  final {{AggregateName}}Repository repository;

  Future<void> handle({{InternalCommandName}} command) async {
    await repository.{{stateChangeMethod}}(
      tenantId: command.tenantId,
      sourceEntityId: command.sourceEntityId,
    );
  }
}
```

---

## 12. Supabase/Postgres Requirements

Khi tạo module mới, cần chuẩn bị các database object sau nếu module có durable processing.

### 12.1 Schema

```sql
create schema if not exists {{module_name}};
```

### 12.2 Outbox Table

```sql
create table if not exists {{module_name}}.outbox_messages (
  id uuid primary key,
  tenant_id uuid not null,
  event_type text not null,
  payload jsonb not null,
  occurred_at timestamptz not null default now(),
  processed_at timestamptz null,
  failed_at timestamptz null,
  error text null,
  retry_count int not null default 0,
  claimed_at timestamptz null,
  claim_token uuid null
);

create index if not exists outbox_messages_pending_tenant_idx
  on {{module_name}}.outbox_messages (tenant_id, occurred_at)
  where processed_at is null and failed_at is null;
```

Hoặc dùng DRY installer: `select platform.install_module_messaging('{{module_name}}');` — xem [operations/messaging_schema.md](operations/messaging_schema.md).

### 12.3 Inbox Table

```sql
create table if not exists {{module_name}}.inbox_messages (
  id uuid primary key,
  tenant_id uuid not null,
  event_type text not null,
  payload jsonb not null,
  occurred_at timestamptz not null,
  processed_at timestamptz null,
  failed_at timestamptz null,
  error text null,
  retry_count int not null default 0,
  claimed_at timestamptz null,
  claim_token uuid null
);

create index if not exists inbox_messages_pending_tenant_idx
  on {{module_name}}.inbox_messages (tenant_id, occurred_at)
  where processed_at is null and failed_at is null;
```

Idempotency: `id` = `IntegrationEvent.id`; insert qua `receive_integration_event` với `ON CONFLICT (id) DO NOTHING`.

### 12.4 Internal Commands Table

```sql
create table if not exists {{module_name}}.internal_commands (
  id uuid primary key,
  tenant_id uuid not null,
  command_type text not null,
  payload jsonb not null,
  source_event_id uuid null,
  enqueued_at timestamptz not null default now(),
  processed_at timestamptz null,
  failed_at timestamptz null,
  error text null,
  retry_count int not null default 0,
  claimed_at timestamptz null,
  claim_token uuid null
);

create unique index if not exists internal_commands_source_dedup_idx
  on {{module_name}}.internal_commands (tenant_id, source_event_id, command_type)
  where source_event_id is not null;
```

Dedup khi enqueue từ integration event: `(tenant_id, source_event_id, command_type)`.

### 12.5 Messaging RPC (worker + helpers)

Mỗi module có bộ RPC (tạo bởi `platform.install_module_messaging`):

```text
enqueue_outbox_message
claim_outbox_batch / complete_outbox_message / fail_outbox_message
receive_integration_event
claim_inbox_batch / complete_inbox_message / fail_inbox_message
enqueue_internal_command
claim_internal_commands_batch / complete_internal_command / fail_internal_command
```

Chi tiết signature và verify: [operations/messaging_schema.md](operations/messaging_schema.md).

### 12.6 Command RPC

Mutation RPC phải ghi business data và outbox event trong cùng transaction.

```sql
create or replace function {{module_name}}.{{command_rpc_name}}(
  p_tenant_id text,
  p_payload jsonb
)
returns uuid
language plpgsql
as $$
declare
  v_entity_id uuid := gen_random_uuid();
begin
  -- 1. Validate business rule.
  -- 2. Insert/update business tables.
  -- 3. Insert outbox event.

  insert into {{module_name}}.outbox_messages (
    id,
    tenant_id,
    event_type,
    payload,
    occurred_at
  )
  values (
    gen_random_uuid(),
    p_tenant_id::uuid,
    '{{module_name}}.{{entity_name}}.{{event_name}}',
    jsonb_build_object(
      'tenant_id', p_tenant_id,
      '{{entity_id}}', v_entity_id
    ),
    now()
  );

  return v_entity_id;
end;
$$;
```

---

## 13. Module Creation Checklist

Khi tạo module mới, cần kiểm tra:

```text
[ ] Đã xác định responsibility rõ ràng.
[ ] Đã xác định out-of-scope.
[ ] Đã tạo package riêng.
[ ] Đã có Application layer.
[ ] Đã có Domain layer.
[ ] Đã có Infrastructure layer.
[ ] Đã có Integration Events layer.
[ ] Đã thêm Presentation layer nếu module có UI.
[ ] Đã tạo module contract.
[ ] Đã tạo command/query base hoặc reuse từ shared package.
[ ] Đã tạo repository interface trong domain/application.
[ ] Đã tạo repository implementation trong infrastructure.
[ ] Đã tạo Supabase RPC client.
[ ] Đã tạo composition root.
[ ] Đã register command handlers.
[ ] Đã register query handlers.
[ ] Đã register integration event handlers nếu module consume event.
[ ] Đã define integration events nếu module publish event.
[ ] Đã tạo outbox table nếu module publish durable event.
[ ] Đã tạo inbox table nếu module consume durable event.
[ ] Đã tạo internal_commands table nếu module xử lý async internal command.
[ ] Đã đảm bảo Flutter event bus chỉ dùng cho app-local event.
[ ] Đã đảm bảo business mutation quan trọng nằm trong Supabase/Postgres RPC.
```

---

## 14. Naming Convention

### 14.1 Package

```text
{{module_name}}
```

Ví dụ:

```text
sales
inventory
communication
customer
payment
```

### 14.2 Dart Classes

```text
{{ModuleName}}Module
{{ModuleName}}Startup
{{ModuleName}}CompositionRoot
{{UseCaseName}}Command
{{UseCaseName}}CommandHandler
{{QueryName}}Query
{{QueryName}}QueryHandler
{{AggregateName}}Repository
Supabase{{AggregateName}}Repository
{{DomainEventName}}DomainEvent
{{IntegrationEventName}}IntegrationEvent
{{InternalCommandName}}Command
```

### 14.3 RPC

```text
{{module_name}}_{{action}}_{{entity}}
```

Ví dụ:

```text
sales_create_order
inventory_reserve_stock
communication_create_notification
payment_confirm_payment
```

### 14.4 Integration Event Type

```text
{{module}}.{{entity}}.{{past_tense_event}}
```

Ví dụ:

```text
sales.order.created
sales.order.cancelled
payment.payment_confirmed
inventory.stock_reserved
communication.notification_created
```

---

## 15. Dependency Direction

Dependency direction phải đi từ ngoài vào trong:

```text
presentation
  -> application
      -> domain

infrastructure
  -> application
  -> domain

integration_events
  -> shared contracts only
```

Domain không phụ thuộc:

```text
- application
- infrastructure
- presentation
- Flutter
- Supabase
```

Application không phụ thuộc:

```text
- presentation
- concrete infrastructure implementation
```

Infrastructure có thể phụ thuộc:

```text
- application contracts
- domain contracts
- external libraries
```

Presentation có thể phụ thuộc:

```text
- application contracts
- module facade
```

---

## 16. Communication Between Modules

### 16.1 Allowed

```text
1. App shell gọi module facade.
2. Module publish Integration Event qua Outbox.
3. Module nhận Integration Event qua Inbox.
4. Module nhận xử lý event bằng Integration Event Handler.
5. Module nhận enqueue Internal Command nếu cần thay đổi state.
6. Flutter presentation publish app-local event cho UI/local state.
```

### 16.2 Not Allowed

```text
1. Module A import repository implementation của Module B.
2. Module A gọi trực tiếp use case nội bộ của Module B.
3. Module A query trực tiếp table/schema private của Module B.
4. Flutter app ghi durable outbox thay cho server-side RPC.
5. Flutter app xử lý durable inbox thay cho worker/server-side processor.
6. Domain layer gọi Supabase hoặc Flutter API.
```

---

## 17. Recommended Flow

### 17.1 Command Flow

```text
Flutter UI
  -> Controller/Notifier
      -> {{ModuleName}}Module.executeCommand()
          -> CommandBus
              -> CommandHandler
                  -> Repository interface
                      -> Supabase RPC implementation
                          -> business data
                          -> outbox event
```

### 17.2 Query Flow

```text
Flutter UI
  -> Controller/Notifier
      -> {{ModuleName}}Module.executeQuery()
          -> QueryBus
              -> QueryHandler
                  -> Repository/Gateway
                      -> Supabase read RPC/table/view
```

### 17.3 Integration Event Flow

```text
Source RPC
  -> write business data
  -> write outbox event

Outbox Worker
  -> read outbox
  -> dispatch integration event
  -> write target inbox

Target Inbox Processor
  -> read inbox
  -> call integration event handler
  -> enqueue internal command if needed

Internal Command Processor
  -> execute command
  -> change target module state
```

### 17.4 Flutter App-local Event Flow

```text
CommandHandler or RealtimeGateway
  -> publish AppEvent
      -> UI/local modules react
```

App-local event examples:

```text
OrderCreatedInApp
TenantChangedInApp
NotificationReceivedInApp
CartClearedInApp
```

---

## 18. Minimal Module Skeleton

Nếu module còn nhỏ, có thể bắt đầu với cấu trúc tối thiểu:

```text
packages/
  {{module_name}}/
    lib/
      {{module_name}}.dart
      src/
        application/
          contracts/
          commands/
          queries/

        domain/
          {{aggregate_name}}/

        infrastructure/
          configuration/
          domain/
            {{aggregate_name}}/
          rpc/
          supabase/
          adapters/
          errors/

        integration_events/

        presentation/
```

Chỉ thêm các phần sau khi thật sự cần:

```text
- configuration/events_bus/ + configuration/processing/ (messaging)
- domain/shared/ (mappers dùng chung giữa aggregates)
- adapters/ (cross-module lookup ports)
- realtime/ (optional, cùng cấp rpc/ — không trong domain/)
```

Chi tiết cấu trúc infrastructure: [infrastructure_layer_skill.md](./infrastructure_layer_skill.md). Reference: `modules/sales/infrastructure`.

---

## 19. Final Rule

Khi tạo module mới, hãy giữ nguyên nguyên tắc:

```text
Module owns its language.
Module owns its use cases.
Module owns its data boundary.
Module exposes only contracts.
Module communicates asynchronously through integration events.
Flutter event bus is local only.
Supabase/Postgres outbox is durable.
```
