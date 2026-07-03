# Agent onboarding — Vet45 ERP

Tài liệu này là **điểm vào chính** cho AI coding agents. Nếu thông tin không có trong repo, coi như không tồn tại.

## Trạng thái repo (đọc trước khi implement)

| Khu vực | Trạng thái |
| ------- | ---------- |
| `packages/vet45_shared/*` | Kernel CQRS + pipeline — **có implementation và tests** |
| `modules/iam/` | **Golden module** — codegen bật, auth + tenant/membership interim; xem [modules/iam/README.md](modules/iam/README.md) |
| `packages/vet45_generator/test/fixtures/` | Reference CQRS tạm (khi chưa cần đọc IAM) |
| `packages/vet45_shared/testing/` | Test harness (`PipelineTestHarness`, fakes) |
| `modules/partner/` | **TH-03 in progress** — codegen bật; Epic-01 profile CRUD + Epic-02 status done; xem [modules/partner/README.md](modules/partner/README.md) |
| `modules/*` (các context khác) | **Greenfield skeleton** — chưa codegen |
| `apps/erp/features/auth/` | Auth **presentation shell** — login/logout qua `IIamModule` / `IamStartup` |
| `apps/messaging_worker/` | Worker messaging — có tests |

**Copy CQRS + access pattern từ `modules/iam/`** — không copy từ `modules/sales/` (scaffold).

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
| Golden module (codegen + access + wiring) | `modules/iam/` + [modules/iam/README.md](modules/iam/README.md) |
| Module codegen (second reference) | `modules/partner/` + [modules/partner/README.md](modules/partner/README.md) |
| Command + handler + `@CommandHandlerFor` (fixtures) | `packages/vet45_generator/test/fixtures/lib/src/` |
| Pipeline + validator + in-memory bus test | `packages/vet45_shared/testing/test/shared_testing_test.dart` |
| Module layout mục tiêu | `docs/MODULES_IMPLEMENTATION_TEMPLATE.md` |
| Layer rules (always-on) | `.cursor/rules/vet45-architecture.mdc` |
| Page mỏng + widgets tách file | `apps/erp/lib/features/dashboard/presentation/` |

## Skills map

| Task | Skill / doc |
| ---- | ----------- |
| Domain model phân tích (→ `01-domain-model.md`) | `.cursor/skills/ddd-domain-modeling/SKILL.md` |
| Domain code implement (`modules/*/domain/`) | `.cursor/skills/domain-layer/SKILL.md` |
| Application layer (handlers, ports, DTOs) | `.cursor/skills/application-layer/SKILL.md` |
| Infrastructure (RPC, gateways, startup) | `.cursor/skills/infrastructure-layer/SKILL.md` |
| Presentation UI (pages, dialogs, widgets) | `.cursor/skills/presentation-layer/SKILL.md` |
| Harness approach | `docs/architecture/harness-engineering.md` |

Canonical specs (mirror của skills): `docs/application_layer_skill.md`, `docs/domain_layer_skill.md`, `docs/infrastructure_layer_skill.md`, `docs/ddd_domain_modeling_skill.md`, `docs/presentation_layer_skill.md`.

## Agent workflow (ritual)

```text
1. Đọc AGENTS.md + .cursor/rules/vet45-architecture.mdc
2. Đọc docs/harness/PROGRESS.md — biết harness đã hoàn thành gì
2b. Nếu task gắn theme (vd. TH-03): đọc docs/themes/TH-xx-*/README.md
     → harness/00-agent-ritual.md → 07-api-contracts → slice-roadmap (lane) → US/FR
3. Xác định layer → mở skill tương ứng
     (presentation/UI → presentation-layer skill + UI artifacts trong FR)
     (DDL/RPC/RLS → draft SQL vào `supabase/migrations/_drafts/`, không tạo file timestamp)
     (RPC/worker slice → `melos run env:sync && melos run env:doctor` trước khi test tích hợp;
      local stack: `supabase start` + `melos run env:local`)
4. Implement (minimal diff, match conventions hiện có)
5. Verify:
     melos bootstrap
     melos run analyze
     melos run test
     ./scripts/ci/verify_harness.sh
     cd apps/erp && flutter test   # khi slice có UI
6. Nếu agent fail lặp lại cùng lỗi → cập nhật harness (guard/doc/skill), không chỉ retry prompt
```

## Lệnh verify

```bash
melos bootstrap
melos run env:doctor       # khi slice cần Supabase / worker
melos run analyze
melos run test
melos run codegen          # khi module bật build_runner
./scripts/ci/verify_harness.sh
cd apps/erp && flutter test
cd apps/messaging_worker && dart test
```

## Schema & migration (agents)

`supabase/migrations/` là **migration chính thức** — Supabase CLI apply theo version (`YYYYMMDDHHMMSS_*.sql`). Trong collaboration, nhiều agent/branch cùng thêm file timestamp dễ gây **trùng version**, `db reset` fail, hoặc sequence lệch.

### Quy tắc bắt buộc

| Việc | Agent được | Agent không được |
| ---- | ---------- | -------------- |
| Thiết kế DDL/RPC/RLS cho slice | Viết SQL tạm vào [`supabase/migrations/_drafts/`](supabase/migrations/_drafts/) | Tạo/sửa `supabase/migrations/[0-9]*.sql` |
| Map contract BE | Cập nhật harness `07-api-contracts.md` + Dart gateway/RPC client | Giả định draft đã apply trên DB |
| Verify local DB | `melos run test`, harness scripts | `supabase db reset` để “thử” draft SQL (trừ khi user yêu cầu) |
| Promote migration | — | Tự đổi tên draft → timestamp migration |

**Draft naming:** `<scope>_<short_description>.sql` (không có prefix timestamp). Quy ước chi tiết: [`supabase/migrations/_drafts/README.md`](supabase/migrations/_drafts/README.md).

**Chỉ tạo file `YYYYMMDDHHMMSS_*.sql`** khi user **yêu cầu rõ** promote migration hoặc maintain schema chính thức. Khi promote: timestamp phải unique (`supabase migration list --local`), SQL idempotent, có header theo [`supabase/migrations/README.md`](supabase/migrations/README.md).

**Lane BE không có DB:** implement application/infrastructure với RPC name + params khớp draft; test dùng fakes/in-memory — không block slice vì thiếu migration applied.

## Anti-patterns (từ chối)

- Tạo `supabase/migrations/2026....sql` trong slice agent thông thường (dùng `_drafts/` thay thế)
- God aggregate, God Widget (page > 500 dòng), cross-module table access, anemic domain-only-in-SQL
- Inline dialog (`AlertDialog`) trong `*_page.dart` — tách file `widgets/`
- `Widget _buildXxx()` subtree lớn trong `State` — tách class widget riêng
- Direct PostgREST writes từ UI
- `Either`/`Result` **bên trong** command handlers (map ở presentation boundary)
- Import `package:.../src/...` từ package khác
- Application import infrastructure
- Domain import `supabase`, `flutter`, `get_it`
- Hand-maintain `.g.dart` — chạy `melos run codegen`
- Hardcode permission code string — dùng `{Module}Permissions` constant trong `modules/<module>/domain/`
- Chỉnh tay `apps/*/.env*` — sửa `config/secrets/<env>.env` rồi `melos run env:sync`

## Legacy / ngoại lệ hiện tại

`apps/erp/features/auth/` giữ presentation (login page). Business auth nằm trong `modules/iam` qua `IIamModule` — không mở rộng direct Supabase calls từ feature shell.

## Theme harness (TH-03)

Theme đang deliver: [docs/themes/TH-03-partner/](docs/themes/TH-03-partner/)

- Ritual: [harness/00-agent-ritual.md](docs/themes/TH-03-partner/harness/00-agent-ritual.md)
- Contracts: [harness/07-api-contracts.md](docs/themes/TH-03-partner/harness/07-api-contracts.md)
- Slice order + lanes: [harness/04-slice-roadmap.md](docs/themes/TH-03-partner/harness/04-slice-roadmap.md)
- Codegen: [modules/partner/README.md](modules/partner/README.md)

## Liên kết

- [docs/operations/environment-manager.md](docs/operations/environment-manager.md) — Melos env manager (`env:*`, active environment)
- [docs/architecture/](docs/architecture/) — kiến trúc platform (CQRS, module layout)
- [docs/harness/PROGRESS.md](docs/harness/PROGRESS.md) — tiến độ harness
- [docs/themes/](docs/themes/) — catalog theme
- [packages/vet45_shared/README.md](packages/vet45_shared/README.md) — shared toolkit
