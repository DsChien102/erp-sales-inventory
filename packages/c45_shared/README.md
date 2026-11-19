# Mosaic Retail shared packages — internal architecture toolkit

`packages/c45_shared/` is a **small, pure-Dart architecture toolkit** for the Mosaic Retail ERP modular monolith. It is not a business framework and not a place for domain models.

| Package | Role |
| ------- | ---- |
| [`domain`](domain/) | DDD primitives: `Entity`, `ValueObject`, `DomainEvent`, `TypedId`, `IClock` |
| [`application`](application/) | CQRS contracts, execution context, permission/tenant abstractions |
| [`infrastructure`](infrastructure/) | `CommandBus`, `QueryBus`, pipelines, decorators, generic events bus |
| [`testing`](testing/) | In-memory buses, fakes, matchers, `PipelineTestHarness` |

Companion packages:

| Package | Role |
| ------- | ---- |
| [`../c45_adapters`](../c45_adapters/) | Supabase RPC, messaging worker registry, outbox/inbox, internal commands |
| [`../c45_annotations`](../c45_annotations/) | CQRS and access metadata for codegen |
| [`../c45_generator`](../c45_generator/) | `build_runner` handler registration codegen |

## MVP example (non-ERP)

```dart
import 'package:c45_shared_application/application.dart';
import 'package:c45_shared_infrastructure/infrastructure.dart';

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
c45_shared_domain
c45_shared_application → c45_annotations (annotations re-export)
c45_shared_infrastructure → c45_shared_application, c45_shared_domain
c45_shared_testing → c45_shared_infrastructure, c45_shared_application
c45_adapters → c45_shared_infrastructure (Mosaic Retail-specific adapters only)
```

Hard constraints:

- **`c45_shared_domain`** — pure Dart only. No Flutter, Supabase, HTTP, or GetIt.
- **`c45_shared_application`** — pure Dart contracts. No Supabase or module infrastructure imports.
- **`c45_shared_infrastructure`** — no Supabase dependency. Use `c45_adapters` for Supabase RPC.

## Related documentation

- [Shared toolkit architecture](../../docs/architecture/shared-toolkit.md)
- [Layered module structure](../../docs/architecture/05-layered-module-structure.md)
- [Generator README](../c45_generator/README.md)
