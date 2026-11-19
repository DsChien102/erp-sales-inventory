# c45_annotations

Dependency-light metadata annotations for Mosaic Retail CQRS codegen. No analyzer, Flutter, or framework runtime dependencies.

## Annotation targets

| Annotation | Target | Purpose |
|------------|--------|---------|
| `CommandHandlerFor` | Handler class | Declares handled command type |
| `QueryHandlerFor` | Handler class | Declares handled query type |
| `RequiresPermission` | Command/query class | Permission metadata |
| `PublicAccess` | Command/query class | Anonymous access |
| `RequiresTenant` | Command/query class | Tenant context required |
| `Idempotent` | Command class | Idempotency key field |
| `ModuleManifest` | Module definition class | Module inventory for codegen |

Legacy handler markers (`CqrsBusinessHandler`, `CqrsQueryHandler`) remain supported but are deprecated.

## Example

```dart
@RequiresPermission('task.create')
@RequiresTenant()
@Idempotent(keyField: 'requestId')
final class CreateTaskCommand implements ICommand<TaskId> {
  CreateTaskCommand({required this.requestId, required this.title});
  final String requestId;
  final String title;
}

@CommandHandlerFor(CreateTaskCommand)
final class CreateTaskCommandHandler
    implements ICommandHandler<CreateTaskCommand, TaskId> {
  @override
  Future<TaskId> handle(CreateTaskCommand command) async { ... }
}
```

Runtime buses work without annotations. Codegen is optional.
