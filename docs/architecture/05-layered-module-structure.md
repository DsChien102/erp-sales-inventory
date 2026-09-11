# Cấu trúc layer trong module

## Bốn layer (presentation thuộc app)

| Layer | Package | Trách nhiệm |
| ----- | ------- | ----------- |
| **Domain** | `vet45_{m}_domain` | Aggregates, VOs, rules, domain events, repository **interfaces** |
| **Application** | `vet45_{m}_application` | Commands, queries, handlers, DTOs, **gateway ports**, `I{X}Module` |
| **Infrastructure** | `vet45_{m}_infrastructure` | Supabase gateways, repos, `MediationModule`, `DataAccessModule`, startup |
| **Integration events** | `vet45_{m}_integration_events` | Event types public cho module khác |

UI: `apps/erp/lib/features/<feature>/presentation/` (Admin tương ứng). Không tạo `vet45_{m}_presentation`. Xem [11-app-owned-presentation.md](11-app-owned-presentation.md).

**Application không import Infrastructure.** Infrastructure import Application + Domain.

## Handler pattern (command)

**Business command** (user-facing use case) — xem [09-application-commands.md](09-application-commands.md):

```text
1. Validator (optional) — shape input
2. IAccessChecker.ensureCan (mutations admin) — khi enforce RBAC
3. Aggregate method — invariant trong Dart
4. ICommandGateway — persist RPC
5. Map domain events → integration events (outbox trong cùng transaction RPC)
```

**Internal command** — side effect deferred, enqueue `{module}.internal_commands`, xử lý bởi worker; handler trả `void`, không qua auth pipeline đầy đủ.

## Handler pattern (query)

```text
Query → IQueryHandler → Read gateway / repository → DTO (không aggregate)
```

## Module status (hiện tại)

Tất cả bounded context trong `modules/` là **greenfield skeleton** — có `I{Name}Module` stub và `{Name}Startup`, chưa có command/handler/gateway. Xem [04-repository-layout.md](04-repository-layout.md).

| Module | Trạng thái | Ghi chú |
| ------ | ---------- | ------- |
| catalog, sales, partner, iam, inventory, costing, dashboard, accounting | Skeleton | Scaffold từ `scripts/scaffold_module.sh` |
| **iam** | Planned golden (phase 2) | Sẽ là reference đầu tiên khi implement |

**Reference tạm thời** (copy pattern từ đây, không từ `modules/sales/`):

- CQRS + codegen: [`packages/vet45_generator/test/fixtures/`](../../packages/vet45_generator/test/fixtures/lib/src/)
- Pipeline tests: [`packages/vet45_shared/testing/test/shared_testing_test.dart`](../../packages/vet45_shared/testing/test/shared_testing_test.dart)
- Agent harness: [harness-engineering.md](harness-engineering.md)

## Cấu trúc application `src/`

```text
src/
  ports/              # ICommandGateway, IReadGateway
  shared/             # inputs/DTOs dùng chéo aggregate (optional)
  {aggregate}/        # Partner, SalesOrder, ...
    shared/           # DTOs dùng chéo use-case trong aggregate
    commands/
      {use_case}/     # command, handler, validator, command DTOs (1 DTO/file)
    queries/
      {use_case}/     # query, handler, query DTOs (1 DTO/file)
  {read_model}/       # e.g. partner_history — khi không phải aggregate
  contracts/          # I{X}Module, CommandBase, QueryBase
```

**DTO colocation:** không dùng folder global `src/dto/`; mỗi DTO một file; DTO single-use nằm cùng folder use-case. CI: `guard_application_dto_colocation.sh`.

## Infrastructure bootstrap

```text
{X}Startup.initialize(supabase)
  → DataAccessModule.load()   # gateways, repos
  → MediationModule.load()    # handlers → CommandBus/QueryBus
```

Ví dụ: [`modules/iam/infrastructure/lib/src/configuration/iam_startup.dart`](../../modules/iam/infrastructure/lib/src/configuration/iam_startup.dart)

## Liên kết

- [application_layer_skill.md](../application_layer_skill.md)
- [infrastructure_layer_skill.md](../infrastructure_layer_skill.md)
- [MODULES_IMPLEMENTATION_TEMPLATE.md](../MODULES_IMPLEMENTATION_TEMPLATE.md)
