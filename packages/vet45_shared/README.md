# Vet45 shared packages — internal architecture toolkit

`packages/vet45_shared/` is a **small, pure-Dart architecture toolkit** for the Vet45 ERP modular monolith. It is not a business framework and not a place for domain models.

| Package | Role |
| ------- | ---- |
| [`domain`](domain/) | DDD primitives: `Entity`, `ValueObject`, `DomainEvent`, `TypedId`, `IClock` |
| [`application`](application/) | CQRS contracts, execution context, permission/tenant abstractions |
| [`infrastructure`](infrastructure/) | `CommandBus`, `QueryBus`, pipelines, decorators, generic events bus |
| [`testing`](testing/) | In-memory buses, fakes, matchers, `PipelineTestHarness` |

Companion packages:

| Package | Role |
| ------- | ---- |
| [`../vet45_adapters`](../vet45_adapters/) | Supabase RPC, messaging worker registry, outbox/inbox, internal commands |
| [`../vet45_annotations`](../vet45_annotations/) | CQRS and access metadata for codegen |
| [`../vet45_generator`](../vet45_generator/) | `build_runner` handler registration codegen |

## MVP example (non-ERP)

```dart
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

final class CreateTaskCommand extends CommandBase<void> {
  CreateTaskCommand({required this.title, required this.assigneeId});
  final String title;
  final String assigneeId;
}

final bus = CommandBus();
bus.register<CreateTaskCommand, void>((cmd) async {
  // handler body
});

await bus.execute(
  CreateTaskCommand(title: 'Write plan', assigneeId: 'user-1'),
);
```

See [`testing/test/shared_testing_test.dart`](testing/test/shared_testing_test.dart) for a full bus + pipeline example.

## Dependency rules

```
vet45_shared_domain
vet45_shared_application → vet45_annotations (annotations re-export)
vet45_shared_infrastructure → vet45_shared_application, vet45_shared_domain
vet45_shared_testing → vet45_shared_infrastructure, vet45_shared_application
vet45_adapters → vet45_shared_infrastructure (Vet45-specific adapters only)
```

Hard constraints:

- **`vet45_shared_domain`** — pure Dart only. No Flutter, Supabase, HTTP, or GetIt.
- **`vet45_shared_application`** — pure Dart contracts. No Supabase or module infrastructure imports.
- **`vet45_shared_infrastructure`** — no Supabase dependency. Use `vet45_adapters` for Supabase RPC.

## Related documentation

- [Shared toolkit architecture](../../docs/architecture/shared-toolkit.md)
- [Layered module structure](../../docs/architecture/05-layered-module-structure.md)
- [Generator README](../vet45_generator/README.md)
