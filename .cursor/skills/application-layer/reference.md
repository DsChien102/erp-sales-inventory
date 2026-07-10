# Application Layer — Reference

Canonical source: [`docs/application_layer_skill.md`](../../../docs/application_layer_skill.md)

Read the source document for complete handler skeletons, port definitions, and composition-root wiring notes.

## Section Index

| § | Topic |
|---|-------|
| 1 | Purpose |
| 2 | Architectural context |
| 3 | Package structure (sales convention) |
| 4 | Dependency rules |
| 5 | Command contract |
| 6 | Command handler flow |
| 7 | Query contract |
| 8 | Query handler flow |
| 9 | DTO rules |
| 10 | Application services & ports |
| 11 | Internal commands |
| 12 | Integration event handlers |
| 13 | Domain notifications |
| 14 | IIAMModule facade |
| 15 | Composition root wiring (in infrastructure) |
| 16 | Idempotency |
| 17 | Agent output requirements |
| 18 | Review checklist |
| 19 | Anti-patterns |

---

## Quick Reference

### Module layout

```text
modules/<module_name>/
  domain/
  application/          ← this skill
  integration_events/
  infrastructure/
  presentation/         ← optional
```

### Application may contain

```text
Commands, command handlers, queries, query handlers, DTOs,
validators, application services, port interfaces,
integration event handlers, internal command definitions,
domain notification handlers, IIAMModule contract
```

### Application must not contain

```text
Widgets, Bloc/Riverpod, Supabase client, RPC impl,
SQL, repository impl, read gateway impl, mappers,
business invariants, aggregate behavior
```

### Folder convention (sales)

**Quy tắc `lib/src/`:** implementation trong `lib/src/`; barrel `lib/application.dart` export public API. Không import `src/` từ package ngoài.

```text
lib/
  application.dart      # public barrel
  src/
    contracts/            # ICommand, CommandBase, IQuery, QueryBase, IIAMModule
    configurations/       # ICommandHandler, IQueryHandler, InternalCommandBase
    <aggregate>/          # partner, partner_history
      commands/
        <use_case>/       # command + handler (+ validator)
      queries/
        <use_case>/       # query + handler
      shared/
    services/             # snapshot loaders, orchestrators
    ports/                # read gateway & cross-module port interfaces
    event_handlers/
    internal_commands/
```

### Base contracts (actual code)

```dart
// contracts/i_command.dart
abstract interface class ICommand<TResult> {
  String get id;
}

// contracts/command_base.dart
abstract class CommandBase<TResult> implements ICommand<TResult> {
  @override
  final String id;
  @protected
  CommandBase([String? id]) : id = id ?? const Uuid().v4();
}

// contracts/i_query.dart
abstract interface class IQuery<TResult> {}

// contracts/query_base.dart
abstract class QueryBase<TResult> implements IQuery<TResult> {
  final String id;
  @protected
  QueryBase([String? id]) : id = id ?? const Uuid().v7();
}

// configurations/commands/i_command_handler.dart
abstract interface class ICommandHandler<TCommand extends ICommand<TResult>, TResult> {
  Future<TResult> handle(TCommand command);
}

// configurations/queries/i_query_handler.dart
abstract interface class IQueryHandler<TQuery extends IQuery<TResult>, TResult> {
  Future<TResult> handle(TQuery query);
}

// contracts/i_iam_module.dart
abstract interface class IIAMModule {
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command);
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query);
}
```

### Command handler flow (detailed)

```text
handle(command):
  1. Resolve tenant context (from command params)
  2. Load aggregate via domain IRepository
     → throw NotFoundException if missing
  3. Load external data via ports (snapshots, policies)
  4. Call aggregate method(s) — domain enforces rules
  5. Persist via repository.save()
  6. Map domain events → integration events (if handler owns publish)
     → prefer outbox written in same RPC transaction (infrastructure)
  7. Return TResult
```

### Query handler flow

```text
handle(query):
  1. Resolve tenant context
  2. Call IReadGateway (port) — never repository for list/detail UI reads
  3. Map to DTO (gateway may return DTO directly)
  4. Return DTO — no domain entity, no side effects
```

### Port naming

```text
I<SalesOrder>DraftReadGateway       — list/detail reads
I<SalesOrder>ReadGateway
IProductLookupPort                   — cross-module snapshot
IInventoryAvailabilityPort
I<Module>CommandGateway              — RPC-backed mutations (optional pattern)
```

Infrastructure implements `Supabase*` versions. Application never imports them.

### Orchestration patterns

| Pattern | When | Example |
|---------|------|---------|
| Single aggregate | 1 root, 1 transaction | `AddProductToDraftCommand` |
| Sequential commands | Reuse validation use case | `ValidateDraftForCheckout` before checkout |
| Multi-aggregate | Explicit business commit point | `CheckoutSalesOrder` → draft + order |
| Saga/async | Cross-module, eventual | Outbox + inbox → internal command |

### Internal command

```dart
// configurations/commands/internal_command_base.dart
abstract class InternalCommandBase<TResult> implements ICommand<TResult> {
  @override
  final String id;
  @protected
  InternalCommandBase([String? id]) : id = id ?? Uuid().v7();
}
```

Used when inbox handler must defer mutation to a separate durable command.

### DTO rules

```text
- final class, immutable fields
- Primitive types, String ids, nested DTOs
- Money as formatted string or minor units + currency — match presentation contract
- No domain types (SalesOrderDraft, Money VO) unless shared kernel DTO
- Colocated with query: <query_folder>/<name>_dto.dart
```

### pubspec (minimum)

```yaml
name: vet45_<module>_application
resolution: workspace
dependencies:
  meta: ^1.17.0
  uuid: ^4.5.3
  vet45_<module>_domain:
    path: ../domain
  vet45_<module>_integration_events:
    path: ../integration_events
```

---

## Review checklist

```text
[ ] Mỗi command đặt tên theo intent nghiệp vụ
[ ] lib/src/ convention: implementation dưới src/, barrel export public API
[ ] Không import lib/src/ từ package ngoài
[ ] Handler không chứa business invariant (chỉ orchestration)
[ ] Không import infrastructure/presentation/supabase
[ ] Query trả DTO qua read gateway port
[ ] Cross-module data qua port/snapshot, không entity import
[ ] command.id có trên mutation (idempotency / tracing)
[ ] Complete/checkout/payment có idempotencyKey nếu DDD yêu cầu
[ ] Integration publish qua outbox cho mutation quan trọng
[ ] Handler registration ở infrastructure composition root
[ ] Public API qua IIAMModule / application.dart barrel
[ ] Folder theo feature area, không flat commands/
[ ] Money không dùng double
```

---

## Anti-patterns

```text
- Rule if/else trong handler thay vì aggregate.checkRule()
- Handler gọi supabase.rpc() trực tiếp
- GetAllQuery load full aggregate từ repository
- Handler import SupabaseSalesOrderDraftReadGateway
- UI inject handler thay vì IIAMModule
- Return SalesOrderDraft từ command handler
- Một handler 300+ dòng — tách application service
```

---

## Cross-skill alignment

| Skill | Application uses |
|-------|------------------|
| ddd-domain-modeling | Command/query names, aggregate map, snapshot list, rules location |
| infrastructure-layer | Port → gateway/RPC impl, composition root registration |
| MODULES_IMPLEMENTATION_TEMPLATE | Command bus, outbox/inbox, full module scaffold |
