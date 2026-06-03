# Task module example (non-ERP)

Reference fixtures for annotation and codegen testing. Not a workspace package.

## Layout

```text
test/fixtures/lib/src/
  create_task_command.dart          # @RequiresPermission, @RequiresTenant, @Idempotent
  create_task_command_handler.dart  # @CommandHandlerFor
  get_task_by_id_query_handler.dart # @QueryHandlerFor
  configuration/test_module_definition.dart  # @ModuleManifest
```

## Commands

- `CreateTaskCommand` — protected, tenant-scoped, idempotent
- `LoginCommand` — `@PublicAccess`
- `GetTaskByIdQuery` — query handler example

Run generator tests:

```bash
cd packages/vet45_generator && dart test
```

See [codegen migration guide](../../../docs/architecture/codegen-migration.md).
