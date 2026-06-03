# Application Layer Skill

## 1. Purpose

Use this skill when designing, generating, reviewing, or refactoring the **Application layer** of a module in the ERP Flutter/Dart system.

The Application layer orchestrates use cases. It coordinates domain aggregates, loads cross-module snapshots via ports, and exposes commands/queries to presentation — without implementing persistence or business invariants.

```text
Application decides what use case is being executed.
Domain decides what is valid business behavior.
Infrastructure implements how the module talks to the outside world.
Presentation decides how the user sees and interacts with it.
```

---

## 2. Architectural Context

Modular Monolith + Tactical DDD. Each module layer is a separate Dart package:

```text
modules/
  <module_name>/
    domain/
    application/
    integration_events/
    infrastructure/
    presentation/    # optional
```

Reference implementation: `modules/sales/application/`.

---

## 3. Package Structure (Sales Convention)

### 3.1 Package `lib/` convention — enforce private `src/`

Mỗi layer package **phải** tách public API và implementation:

```text
lib/
  <package>.dart          # public barrel — CHỈ export API được phép
  src/                    # private — package ngoài KHÔNG import trực tiếp
    ...
```

Rules:

```text
- Consumer import: package:vet45_<module>_application/application.dart
- Cấm import: package:vet45_<module>_application/src/... từ bên ngoài package
- Mọi file implementation đặt dưới lib/src/
- Barrel chỉ re-export phần public (IIAMModule, commands/queries/DTOs, port interfaces)
- Enforce bằng code review + lint (tránh deep import vào src/)
```

### 3.2 Folder layout

```text
modules/<module_name>/application/
  pubspec.yaml                    # vet45_<module>_application
  lib/
    application.dart              # public barrel
    src/
      contracts/
        i_command.dart
        command_base.dart
        i_query.dart
        query_base.dart
        i_iam_module.dart
      configurations/
        commands/
          i_command_handler.dart
          i_command_scheduler.dart
          internal_command_base.dart
        queries/
          i_query_handler.dart
      <feature_area>/
        <use_case>/
          <use_case>_command.dart
          <use_case>_command_handler.dart
          <use_case>_command_validator.dart    # optional
        <query_use_case>/
          <query>_query.dart
          <query>_query_handler.dart
          <dto>.dart
      services/
      ports/
      event_handlers/
      internal_commands/
      notifications/
```

**Barrel example** (`lib/application.dart`):

```dart
library;

export 'src/contracts/i_iam_module.dart';
export 'src/contracts/i_command.dart';
export 'src/contracts/i_query.dart';
// Export commands, queries, DTOs, ports needed by infrastructure/presentation.
// Do NOT export handler implementations unless required for DI registration.
```

**Feature-area grouping** (not global `commands/` / `queries/`):

```text
sales_order_drafts/    → SalesOrderDraft aggregate cluster
sales_orders/          → SalesOrder aggregate cluster
return_exchanges/      → ReturnExchangeRequest aggregate cluster
```

---

## 4. Dependency Rules

### Application MAY depend on

```text
<module>_domain
<module>_integration_events
vet45_shared_domain
uuid, meta
```

### Application MUST NOT depend on

```text
<module>_infrastructure
<module>_presentation
other_module_infrastructure
other_module_presentation
supabase_flutter, drift, flutter SDK
```

### Cross-module access

```text
Application defines port interface → Infrastructure implements adapter
Never import another module's domain entity for mutation
Use snapshots loaded via port (CustomerSnapshot, ProductSnapshot, etc.)
```

---

## 5. Command Contract

```dart
abstract interface class ICommand<TResult> {
  String get id;
}

abstract class CommandBase<TResult> implements ICommand<TResult> {
  @override
  final String id;

  @protected
  CommandBase([String? id]) : id = id ?? const Uuid().v4();
}
```

### Naming

Intent-based, past-tense or imperative business action:

```text
✓ StartSalesOrderDraftCommand
✓ AddProductToDraftCommand
✓ CheckoutSalesOrderCommand
✓ CompleteReturnExchangeRequestCommand

✗ UpdateCartItemCommand
✗ SaveDraftCommand
✗ UpdateOrderInfoCommand
```

See `ddd-domain-modeling` skill for full command catalog rules.

### Command file template

```dart
final class <UseCase>Command extends CommandBase<<ResultType>> {
  <UseCase>Command({
    String? id,
    required this.tenantId,
    // ... params
  }) : super(id);

  final String tenantId;
  // ... typed params — no Map<String, dynamic> for core fields
}
```

---

## 6. Command Handler Flow

```dart
abstract interface class ICommandHandler<TCommand extends ICommand<TResult>, TResult> {
  Future<TResult> handle(TCommand command);
}
```

### Standard flow

```text
1. Load aggregate (domain IRepository)
2. Load snapshots / policies via application ports
3. Invoke aggregate method(s) — domain enforces IBusinessRule
4. Save aggregate(s)
5. Domain events collected on aggregate — map to integration events
   (outbox write preferably in same Postgres RPC transaction)
6. Return TResult (void, Id, summary DTO — never full aggregate)
```

### Handler template

```dart
final class <UseCase>CommandHandler
    implements ICommandHandler<<UseCase>Command, <ResultType>> {
  <UseCase>CommandHandler({
    required this.<aggregate>Repository,
    // ports, application services
  });

  final I<Aggregate>Repository <aggregate>Repository;

  @override
  Future<<ResultType>> handle(<UseCase>Command command) async {
    final aggregate = await <aggregate>Repository.findById(command.<id>);
    if (aggregate == null) throw <Aggregate>NotFoundException(command.<id>);

    // load snapshots via ports if needed
    aggregate.<method>(/* domain params */);
    await <aggregate>Repository.save(aggregate);

    return /* result */;
  }
}
```

### Orchestration vs domain logic

| Belongs in handler | Belongs in domain |
|--------------------|-------------------|
| Load order + draft in sequence | `checkoutFromDraft()` invariant |
| Call port for stock snapshot | `DraftLineQuantityCannotExceedAvailableStockRule` |
| Call validator before handler | `DraftMustHaveAtLeastOneValidLineForCheckoutRule` |
| Map domain event → integration event | Event emission timing on aggregate |

---

## 7. Query Contract

```dart
abstract interface class IQuery<TResult> {}

abstract class QueryBase<TResult> implements IQuery<TResult> {
  final String id;

  @protected
  QueryBase([String? id]) : id = id ?? const Uuid().v7();
}
```

Queries are read-only. No state mutation, no domain event, no outbox.

---

## 8. Query Handler Flow

```dart
abstract interface class IQueryHandler<TQuery extends IQuery<TResult>, TResult> {
  Future<TResult> handle(TQuery query);
}
```

```text
1. Resolve tenant/filter params from query
2. Call IReadGateway port (infrastructure implements via Supabase views)
3. Return DTO
```

**Do not** load aggregates from `IRepository` for UI list/detail — use read models.

---

## 9. DTO Rules

```text
- final class, immutable
- Flat structure for presentation
- Colocated in query folder: <query_name>_dto.dart
- No aggregate/entity types from domain
- Money: minor units (int) + currency code, or formatted string per UI contract
- Include tenantId in query params, not always in DTO response
```

---

## 10. Application Services & Ports

### When to add application service

```text
- Snapshot loading reused by multiple handlers
- Multi-step orchestration clutters handler (> ~40 lines of coordination)
- Cross-module read aggregation (not a single gateway query)
```

### Port interfaces (application defines, infrastructure implements)

```dart
// ports/i_product_lookup_port.dart
abstract interface class IProductLookupPort {
  Future<ProductSnapshot> getSnapshot({
    required String tenantId,
    required String productId,
  });
}

// ports/i_sales_order_draft_read_gateway.dart
abstract interface class ISalesOrderDraftReadGateway {
  Future<SalesOrderDraftListDto> listByTenant({required String tenantId});
}
```

### Mapping to infrastructure skill

| Application port | Infrastructure implementation |
|------------------|-------------------------------|
| `I<Aggregate>ReadGateway` | `Supabase<Aggregate>ReadGateway` via `sales.v_*` views |
| `I<Aggregate>Repository` (domain) | `Supabase<Aggregate>Repository` via RPC |
| `I<Module>CommandGateway` | `Supabase<Module>CommandGateway` via RPC |
| `IProductLookupPort` | Adapter to Catalog read API / view |

---

## 11. Internal Commands

```dart
abstract class InternalCommandBase<TResult> implements ICommand<TResult> {
  @override
  final String id;

  @protected
  InternalCommandBase([String? id]) : id = id ?? Uuid().v7();
}
```

Use when:

```text
- Inbox handler receives integration event
- Mutation must run in separate durable transaction
- Retry/idempotency handled by Postgres internal_commands table
```

Handler returns `Future<void>`. Registration in infrastructure composition root.

---

## 12. Integration Event Handlers

```text
integration_events/<event_name>_integration_event_handler.dart
```

Implement `IIntegrationEventNotificationHandler<T extends IntegrationEvent>` from `vet45_shared_infrastructure` (Meetings `INotificationHandler<IntegrationEvent>` equivalent). Infrastructure `<Module>IntegrationEventDispatcher` routes inbox messages to these handlers — do **not** implement `IIntegrationEventHandler` here (that role is `IntegrationEventGenericHandler` on the bus).

Responsibilities:

```text
- Deserialize integration event payload
- Idempotency check (event.id)
- Enqueue internal command OR invoke command handler
- Never mutate another module's state
- Never contain business invariants — delegate to domain via command
```

Publish path (module emits):

```text
Aggregate raises domain event
  → Handler or RPC maps to IntegrationEvent
  → Outbox row in same transaction (infrastructure/Postgres)
  → Worker publishes to consuming modules
```

---

## 13. Domain Notifications

Optional pattern for in-module reactive side effects (not cross-module):

```text
notifications/<notification>_handler.dart
```

Prefer domain events + explicit command when side effect is business-critical.

---

## 14. IIAMModule Facade

```dart
abstract interface class IIAMModule {
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command);
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query);
}
```

Rules:

```text
- Presentation calls IIAMModule only
- Implementation lives in infrastructure (dispatches to registered handlers)
- Application defines contract; does not wire GetIt/bus itself
```

---

## 15. Composition Root Wiring (Infrastructure)

Handler registration happens in `infrastructure/lib/src/configuration/` — not application.

```text
<Module>Startup._configureCompositionRoot:
  DataAccessModule     → domain/<aggregate>/ repos, gateways (from application ports)
  ProcessingModule     → messaging dispatchers
  MediationModule      → CommandBus / QueryBus + codegen registerGenerated*Handlers
  EventsBusStartup     → subscribe integration event generic handlers
```

Application package exports:

```text
- Commands, queries, DTOs, handler classes (for DI registration)
- Port interfaces
- *IntegrationEventHandler implementations
- I<Module>Module interface
```

Application package does NOT export handler instances, buses, or Supabase clients.

---

## 16. Idempotency

```text
command.id         — UUID v4 on CommandBase; tracing + client retry safety
idempotencyKey     — required on CompleteReturnExchange, Checkout, payment record
event.id           — inbox deduplication (on conflict do nothing)
```

Pass `command.id` to RPC as `p_command_id` / `p_idempotency_key` where infrastructure skill requires it.

---

## 17. Agent Output Requirements

When designing or generating application layer, produce:

```text
1.  Application responsibility summary
2.  Feature areas & use case inventory
3.  Commands table (command → aggregate → ports)
4.  Queries table (query → DTO → read gateway)
5.  Port interfaces list
6.  Application services list
7.  Integration event handlers (consume/publish)
8.  Internal commands plan
9.  Folder structure
10. pubspec.yaml dependencies
11. Command/query/handler skeletons
12. DTO skeletons
13. IIAMModule wiring notes
14. Review checklist
15. Anti-pattern warnings
```

---

## 18. Review Checklist

```text
[ ] Commands named by business intent
[ ] lib/src/ convention: implementation under src/, barrel exports public API only
[ ] No deep imports of lib/src/ from outside the package
[ ] One command maps clearly to aggregate boundary
[ ] Handlers orchestrate only — no business invariants
[ ] No Supabase/RPC/SQL in application
[ ] Queries use read gateway, return DTO
[ ] Cross-module via ports/snapshots
[ ] No infrastructure/presentation imports
[ ] command.id on mutations
[ ] Idempotency on critical completes
[ ] Integration events via outbox for important mutations
[ ] Feature-area folder structure
[ ] IIAMModule as presentation entry
[ ] Money uses integer minor units
```

---

## 19. Anti-Patterns

```text
- if (quantity > stock) in handler — use domain rule
- supabase.from('orders') in handler
- repository.findById in list query handler
- import '../infrastructure/...'
- return SalesOrderDraft from handler
- Update/Save/Delete CRUD commands
- God handler with 5+ aggregate loads
- double for currency
- Direct integration event bus publish skipping outbox
- Import Customer entity from customers_domain
```

---

## 20. Related Skills

```text
ddd-domain-modeling     — aggregate, command names, business rules, snapshots
infrastructure-layer    — repository/gateway RPC impl, composition root, outbox
MODULES_IMPLEMENTATION_TEMPLATE — full module scaffold, command bus, messaging
```
