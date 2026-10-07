# Kiến trúc nền Vet45

Tài liệu tầng **platform** — áp dụng cho mọi theme (TH-01..TH-11). Để biết module nào thuộc theme nào, xem [themes/README.md](../themes/README.md).

## Đọc theo thứ tự (onboard ~30 phút)

1. [01-vision-and-principles.md](01-vision-and-principles.md) — mục tiêu, bounded context, nguyên tắc
2. [02-architecture-style.md](02-architecture-style.md) — modular monolith, DDD, RPC-first
3. [04-repository-layout.md](04-repository-layout.md) — cây thư mục `apps/`, `modules/`, `packages/`
4. [05-layered-module-structure.md](05-layered-module-structure.md) — domain / application / infrastructure
5. [09-application-commands.md](09-application-commands.md) — business command vs internal command
6. [13-idempotency-and-message-processing.md](13-idempotency-and-message-processing.md) — idempotency, message identity, Outbox/Inbox
7. Theme đang làm việc trong [themes/](../themes/)

## Mục lục đầy đủ

| File | Nội dung |
| ---- | -------- |
| [01-vision-and-principles.md](01-vision-and-principles.md) | Vision, anti-patterns, 12 architectural rules |
| [02-architecture-style.md](02-architecture-style.md) | Modular monolith, CQRS, RPC-first, request flow |
| [03-technology-stack.md](03-technology-stack.md) | Flutter, Supabase, Melos, worker, codegen |
| [04-repository-layout.md](04-repository-layout.md) | Monorepo layout, package naming |
| [05-layered-module-structure.md](05-layered-module-structure.md) | Layer responsibilities, handler pattern |
| [09-application-commands.md](09-application-commands.md) | Business command vs internal command, pipeline, durable queue |
| [13-idempotency-and-message-processing.md](13-idempotency-and-message-processing.md) | Idempotency, messageId vs idempotencyKey, Outbox/Inbox, RPC helpers |
| [14-declarative-sql-objects.md](14-declarative-sql-objects.md) | (Proposed) File nguồn duy nhất cho RPC/view/trigger/policy, migration sinh từ lock |
| [06-cross-cutting-concerns.md](06-cross-cutting-concerns.md) | IAM, tenant, DI, module settings |
| [07-integration-and-messaging.md](07-integration-and-messaging.md) | Integration events, outbox, worker |
| [12-railway-image-source.md](12-railway-image-source.md) | ADR (lỗi thời — hạ tầng đã gỡ): Railway pull image từ GitLab registry |
| [08-data-and-security.md](08-data-and-security.md) | Postgres schema, RLS, multi-tenant |
| [app-link-in-depth.md](app-link-in-depth.md) | Cơ chế App Links (Android) / Universal Links (iOS): verify + handoff |
| [harness-engineering.md](harness-engineering.md) | Harness Engineering — context, constraints, verification, flywheel |
| [10-hybrid-presentation-ownership.md](10-hybrid-presentation-ownership.md) | **Superseded** — hybrid pages@ERP / widgets@module |
| [11-app-owned-presentation.md](11-app-owned-presentation.md) | Presentation thuộc `apps/erp` / `apps/admin`; không package `modules/*/presentation` |

## Diagrams

- [diagrams/system-context.mmd](diagrams/system-context.mmd)
- [diagrams/module-dependencies.mmd](diagrams/module-dependencies.mmd)
- [diagrams/request-lifecycle.mmd](diagrams/request-lifecycle.mmd)

## Ai đọc file nào?

| Vai trò | Ưu tiên |
| ------- | ------- |
| Developer feature | 04, 05, theme `02-module-map.md` |
| Tech lead | 01, 02, 06, 07, 08, 13 |
| Infra / DB | 07, 08, 13, [infrastructure_layer_skill.md](../infrastructure_layer_skill.md) |
| Application | 05, 09, 13, [application_layer_skill.md](../application_layer_skill.md) |
| AI agent / harness | [AGENTS.md](../../AGENTS.md), [harness-engineering.md](harness-engineering.md), [harness/PROGRESS.md](../harness/PROGRESS.md) |
