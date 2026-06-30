# IAM — golden module reference

First bounded context with **codegen enabled**. Other modules should mirror this layout when implementing CQRS + access control.

## Folder map

```text
modules/iam/
  application/          # commands, queries, handlers, DTOs, ports
  domain/               # thin rules (RoleCode, IamPermissions, InterimPermissionCodes)
  infrastructure/
    lib/src/configuration/
      data_access/      # gateways, session, checkers (singletons)
      mediation/        # registerGeneratedIamHandlers + queries
      processing/       # codegen triggers + IamCommandPipeline
        generated/      # *.g.dart — commit after melos run codegen
      session/          # IamSession, coordinator
    lib/src/domain/     # Supabase adapters
  docs/interim-domain.md
```

## Codegen ritual

```bash
melos bootstrap
cd modules/iam/infrastructure && dart run build_runner build --delete-conflicting-outputs
# or: melos run codegen
```

Builders in `infrastructure/build.yaml`:

- `cqrs_registrar` → `registerGeneratedIamHandlers` / `registerGeneratedIamQueries`
- `cqrs_infrastructure` → `IamCommandPipeline` bus extensions
- `access_metadata` → `iamAccessMetadataRegistry` (commands need `implements ICommand` / `IQuery`)
- `module_manifest` → scans `IamModuleDefinition` in infrastructure; handlers from `handler_scan_package` (application)

**Important:** command/query classes must explicitly `implements ICommand<T>` / `IQuery<T>` for access metadata generation.

## Handler annotations

```dart
import 'package:vet45_iam_domain/domain.dart'; // hoặc <module>_domain

@CommandHandlerFor(MyCommand)
@RequiresPermission(IamPermissions.membersRead) // domain constant — không hardcode string
@RequiresTenant()
final class MyCommand extends CommandBase<void>
    implements ICommand<void>, ITenantScopedCommand { ... }
```

`@ModuleManifest` permissions: cùng constant từ domain (`IamPermissions`, `InterimPermissionCodes`).

Validators: `implements ICommandValidator<MyCommand>` — auto-registered by codegen.

## Host wiring (ERP)

`IamStartup.initialize` returns `IamRuntime` with:

- `executionContext`, `permissionChecker`, `tenantAccessChecker` — register in app DI for other modules
- `IIamModule` — sign-in/out, session queries

`IamCommandPipeline.buildBusinessPipeline` injects generated `IAccessMetadataRegistry` + checkers from GetIt.

## Copy checklist for new modules

1. Add `configuration/processing/` + `build.yaml` builders (`module_name`, `scan_package`)
2. `{Module}CommandPipeline.buildBusinessPipeline` forwarding checkers + metadata registry
3. Annotate handlers; messages implement `ICommand` / `IQuery` explicitly
4. `data_access` — gateways only; no handler singletons
5. `mediation` — call `registerGenerated{Module}Handlers`
6. `melos run codegen` after each new handler
7. CI: `GUARD_CODEGEN_STRICT=1` keeps `.g.dart` fresh

## Interim scope (Phase 2)

Auth + tenant switch + member list/role assign. See [docs/interim-domain.md](docs/interim-domain.md).

Deferred: full SRS aggregates, UI member management, `install_module_messaging('iam')`.
