# Agent onboarding — Vet45 ERP

Tài liệu này là **điểm vào chính** cho AI coding agents. Nếu thông tin không có trong repo, coi như không tồn tại.

## Trạng thái repo (đọc trước khi implement)

| Khu vực | Trạng thái |
| ------- | ---------- |
| `packages/vet45_shared/*` | Kernel CQRS + pipeline — **có implementation và tests** |
| `packages/vet45_generator/test/fixtures/` | **Reference CQRS + codegen tạm thời** |
| `packages/vet45_shared/testing/` | **Reference test harness** (`PipelineTestHarness`, in-memory buses) |
| `modules/*` (8 bounded contexts) | **Greenfield skeleton** — `I{Name}Module` stub, chưa có command/handler/gateway |
| `apps/erp/features/auth/` | Auth shell **legacy** — gọi Supabase Auth trực tiếp, **chưa** qua `IModuleMediator` |
| `apps/messaging_worker/` | Worker messaging — có tests |

**Không copy pattern từ `modules/sales/` hoặc `modules/iam/`** — chúng chỉ là scaffold. Golden module **IAM** được lên kế hoạch ở phase 2 (xem [docs/harness/PROGRESS.md](docs/harness/PROGRESS.md)).

## Luồng kiến trúc bắt buộc

```text
UI → IExecutionContext (tenant/user) → IModuleMediator
  → ScopedCommandExecutor → CommandBus/QueryBus
  → DefaultCommandPipeline (validate → log → handler)
  → port/gateway → Supabase RPC
```

Layer map (không vi phạm):

```text
apps/erp/features     → module application (via IModuleMediator)
module presentation   → module application → module domain → packages/vet45_shared/domain
module infrastructure → module application + packages/vet45_shared/infrastructure
packages/vet45_shared/*     → never import modules/
```

## Reference tạm thời (copy từ đây)

| Mục đích | Path |
| -------- | ---- |
| Command + handler + `@CommandHandlerFor` | `packages/vet45_generator/test/fixtures/lib/src/` |
| Pipeline + validator + in-memory bus test | `packages/vet45_shared/testing/test/shared_testing_test.dart` |
| Module layout mục tiêu | `docs/MODULES_IMPLEMENTATION_TEMPLATE.md` |
| Layer rules (always-on) | `.cursor/rules/vet45-architecture.mdc` |

## Skills map

| Task | Skill / doc |
| ---- | ----------- |
| Domain modeling, aggregates, commands | `.cursor/skills/ddd-domain-modeling/SKILL.md` |
| Application layer (handlers, ports, DTOs) | `.cursor/skills/application-layer/SKILL.md` |
| Infrastructure (RPC, gateways, startup) | `.cursor/skills/infrastructure-layer/SKILL.md` |
| Harness approach | `docs/architecture/harness-agent.md` |

Canonical specs (mirror của skills): `docs/application_layer_skill.md`, `docs/infrastructure_layer_skill.md`, `docs/ddd_domain_modeling_skill.md`.

## Agent workflow (ritual)

```text
1. Đọc AGENTS.md + .cursor/rules/vet45-architecture.mdc
2. Đọc docs/harness/PROGRESS.md — biết harness đã hoàn thành gì
3. Xác định layer → mở skill tương ứng
4. Implement (minimal diff, match conventions hiện có)
5. Verify:
     melos bootstrap
     melos run analyze
     melos run test
     ./scripts/ci/verify_harness.sh
6. Nếu agent fail lặp lại cùng lỗi → cập nhật harness (guard/doc/skill), không chỉ retry prompt
```

## Lệnh verify

```bash
melos bootstrap
melos run analyze
melos run test
melos run codegen          # khi module bật build_runner
./scripts/ci/verify_harness.sh
cd apps/erp && flutter test
cd apps/messaging_worker && dart test
```

## Anti-patterns (từ chối)

- God aggregate, cross-module table access, anemic domain-only-in-SQL
- Direct PostgREST writes từ UI
- `Either`/`Result` **bên trong** command handlers (map ở presentation boundary)
- Import `package:.../src/...` từ package khác
- Application import infrastructure
- Domain import `supabase`, `flutter`, `get_it`
- Hand-maintain `.g.dart` — chạy `melos run codegen`

## Legacy / ngoại lệ hiện tại

`apps/erp/lib/features/auth/` là mini bounded context trong shell app. **Target architecture** là module `iam` qua `IModuleMediator` — không mở rộng pattern auth shell khi implement tính năng mới.

## Liên kết

- [docs/architecture/](docs/architecture/) — kiến trúc platform
- [docs/harness/PROGRESS.md](docs/harness/PROGRESS.md) — tiến độ harness
- [packages/vet45_shared/README.md](packages/vet45_shared/README.md) — shared toolkit
