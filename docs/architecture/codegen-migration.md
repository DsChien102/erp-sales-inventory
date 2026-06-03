# Codegen migration guide

How to adopt `vet45_annotations` and `vet45_generator` incrementally. Runtime registration always works without codegen.

## Stage 0 — Manual registration (default)

Register handlers explicitly in module infrastructure:

```dart
bus.register<CreateTaskCommand, TaskId>((cmd) => handler.handle(cmd));
```

No annotations required.

## Stage 1 — Legacy glob + interface codegen (current modules)

Keep file naming conventions (`*_command_handler.dart`) and `ICommandHandler` / `IQueryHandler` interfaces. Enable `vet45_generator|cqrs_registrar` in module `build.yaml`.

Optional legacy markers: `@CqrsBusinessHandler`, `@CqrsQueryHandler`.

## Stage 2 — Explicit handler annotations

Add to handler classes:

```dart
@CommandHandlerFor(CreateTaskCommand)
final class CreateTaskCommandHandler implements ICommandHandler<CreateTaskCommand, TaskId> { ... }
```

Generator prefers `@CommandHandlerFor` / `@QueryHandlerFor` over legacy markers. Conflicts between annotation and interface type args fail the build.

## Stage 3 — Access metadata on messages

Annotate command/query **classes** in application layer:

```dart
@RequiresPermission('task.create')
@RequiresTenant()
final class CreateTaskCommand extends CommandBase<TaskId> { ... }
```

Enable `vet45_generator|access_metadata` builder. Wire optional `IAccessMetadataRegistry` into `DefaultCommandPipeline.buildBusinessPipeline` for auth/tenant decorators.

Set `strict_access_metadata: true` in CI to require annotations on all `ICommand` / `IQuery` types.

## Stage 4 — Module manifest

Add one infrastructure definition class:

```dart
@ModuleManifest(name: 'task', permissions: ['task.create', 'task.view'])
final class TaskModuleDefinition {}
```

Enable `vet45_generator|module_manifest` builder. Use generated manifest for permission inventory and architecture checks — not for runtime DI.

## Compatibility rules

- All builders use `auto_apply: none` — opt in per module
- Generated files use `build_to: source` and are checked into git
- Permission strings remain module-owned; framework never catalogs app permissions
- Backend RPC and RLS remain the real security boundary
- No Flutter or Supabase dependency in annotations or generator

## Running codegen

```bash
melos run codegen
```

Or per module:

```bash
cd modules/{module}/infrastructure && dart run build_runner build --delete-conflicting-outputs
```

## Example fixtures

Non-ERP task examples live in [`packages/vet45_generator/test/fixtures/`](../../packages/vet45_generator/test/fixtures/lib/src/) and [`packages/vet45_generator/example/task_module/README.md`](../../packages/vet45_generator/example/task_module/README.md).
