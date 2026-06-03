# Technology stack

## Tổng quan

| Layer | Công nghệ | Vị trí trong repo |
| ----- | --------- | ----------------- |
| Client UI | Flutter 3.x, Dart SDK ≥3.11 | `apps/erp` |
| State / routing | flutter_bloc, go_router | `apps/erp` |
| DI | get_it | module `*Startup`, `apps/erp/lib/core/di/` |
| Backend | Supabase (Auth, Postgres, Storage, Realtime) | `supabase/migrations/` |
| Async messaging | Dart worker trên Railway | `apps/messaging_worker` |
| Monorepo | Melos workspace | root `pubspec.yaml` |
| Codegen | `vet45_generator`, build_runner | `packages/vet45_generator` |
| Design system | `packages/vet45_design_system` | shared UI tokens/components |
| Shared kernel | `packages/vet45_shared/{domain,application,infrastructure}` | Entity, CommandBus, Outbox ports |

## Supabase / Postgres

- Schema theo module: `iam`, `catalog`, `sales`, `partner`, …
- **RPC** cho command path (`iam.register_user_account_from_auth`, `sales.*`, …)
- **RLS** + `require_permission()` trên RPC admin
- **Views** cho effective permissions, read models đơn giản

## Flutter app (`apps/erp`)

- **Shell app**: router, DI, feature adapters
- Feature folder map theo theme: `lib/features/catalog/`, `sales/`, `iam/`, …
- Module presentation package optional; nhiều screen nằm trực tiếp trong ERP

## Worker (`apps/messaging_worker`)

- Poll outbox/inbox, flush integration handlers
- Không expose public API cho client tick (security)
- Deploy: Railway - (xem README.md của messaging_worker)

## Tooling

```bash
melos bootstrap    # link workspace packages
melos run codegen  # build_runner where configured
dart test          # per package
```

## Liên kết

- [04-repository-layout.md](04-repository-layout.md)
- [07-integration-and-messaging.md](07-integration-and-messaging.md)
