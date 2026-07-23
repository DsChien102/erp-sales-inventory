# Agent onboarding — Vet45 ERP

Tài liệu này là **điểm vào chính** cho AI coding agents. Nếu thông tin không có trong repo, coi như không tồn tại.

## Trạng thái repo (đọc trước khi implement)


| Khu vực                                   | Trạng thái                                                                                                                                                             |
| ----------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `packages/vet45_shared/*`                 | Kernel CQRS + pipeline — **có implementation và tests**                                                                                                                |
| `modules/iam/`                            | **Golden module** — codegen bật, auth + tenant/membership interim; xem [modules/iam/README.md](modules/iam/README.md)                                                  |
| `packages/vet45_generator/test/fixtures/` | Reference CQRS tạm (khi chưa cần đọc IAM)                                                                                                                              |
| `packages/vet45_shared/testing/`          | Test harness (`PipelineTestHarness`, fakes)                                                                                                                            |
| `packages/vet45_async_query/`             | Async server-state toolkit (TanStack Query style) — core + Flutter adapter + example; xem [packages/vet45_async_query/README.md](packages/vet45_async_query/README.md) |
| `modules/partner/`                        | **TH-03 reboot** — greenfield, chờ rebuild; harness v2 synced; xem [docs/themes/TH-03-partner/](docs/themes/TH-03-partner/)                                            |
| `modules/*` (các context khác)            | **Greenfield skeleton** — chưa codegen                                                                                                                                 |
| `apps/erp/features/auth/`                 | Auth **presentation shell** — login/logout qua `IIamModule` / `IamStartup`                                                                                             |
| `apps/messaging_worker/`                  | Worker messaging — có tests                                                                                                                                            |


**Copy CQRS + access pattern từ** `modules/iam/` — không copy từ `modules/sales/` (scaffold).

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


| Mục đích                                            | Path                                                                     |
| --------------------------------------------------- | ------------------------------------------------------------------------ |
| Golden module (codegen + access + wiring)           | `modules/iam/` + [modules/iam/README.md](modules/iam/README.md)          |
| TH-03 harness (partner greenfield)                  | [docs/themes/TH-03-partner/harness/](docs/themes/TH-03-partner/harness/) |
| Command + handler + `@CommandHandlerFor` (fixtures) | `packages/vet45_generator/test/fixtures/lib/src/`                        |
| Pipeline + validator + in-memory bus test           | `packages/vet45_shared/testing/test/shared_testing_test.dart`            |
| Module layout mục tiêu                              | `docs/MODULES_IMPLEMENTATION_TEMPLATE.md`                                |
| Layer rules (always-on)                             | `.cursor/rules/vet45-architecture.mdc`                                   |
| Page mỏng + widgets tách file                       | `apps/erp/lib/features/dashboard/presentation/`                          |




## Skills map


| Task                                                    | Skill / doc                                                                                                 |
| ------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| Domain model phân tích (→ `01-domain-model.md`)         | `.cursor/skills/ddd-domain-modeling/SKILL.md`                                                               |
| Domain code implement (`modules/*/domain/`)             | `.cursor/skills/domain-layer/SKILL.md`                                                                      |
| Application layer (handlers, ports, DTOs)               | `.cursor/skills/application-layer/SKILL.md`                                                                 |
| Infrastructure (RPC, gateways, startup)                 | `.cursor/skills/infrastructure-layer/SKILL.md`                                                              |
| Presentation UI (pages, dialogs, widgets)               | `.cursor/skills/presentation-layer/SKILL.md`                                                                |
| Design system + example catalog coverage                | `.cursor/rules/vet45-design-system-example.mdc` + `packages/vet45_design_system/example/lib/preview/`        |
| Tích hợp async server-state cache (`vet45_async_query`) | `.cursor/rules/vet45-presentation-ui.mdc` + `packages/vet45_async_query/docs/AGENT_INTEGRATION_PLAYBOOK.md` |
| Harness approach                                        | `docs/architecture/harness-engineering.md`                                                                  |


Canonical specs (mirror của skills): `docs/application_layer_skill.md`, `docs/domain_layer_skill.md`, `docs/infrastructure_layer_skill.md`, `docs/ddd_domain_modeling_skill.md`, `docs/presentation_layer_skill.md`.

## Agent workflow (ritual)

```text
1. Đọc AGENTS.md + .cursor/rules/vet45-architecture.mdc
2. Đọc docs/harness/PROGRESS.md — biết harness đã hoàn thành gì
2b. Nếu task gắn theme (vd. TH-03): đọc docs/themes/TH-xx-*/README.md
     → harness/00-agent-ritual.md → 07-api-contracts → slice-roadmap (lane) → US/FR
3. Xác định layer → mở skill tương ứng
     (presentation/UI → presentation-layer skill + UI artifacts trong FR)
     (async query integration/migration → vet45-presentation-ui rule + playbook)
     (DDL/RPC/RLS → draft SQL vào `supabase/migrations/_drafts/`, không tạo file timestamp)
     (RPC/worker slice → `melos run env:sync && melos run env:doctor` trước khi test tích hợp;
      local stack: `supabase start` + `melos run env:local`)
4. Implement (minimal diff, match conventions hiện có)
5. Verify:
     melos bootstrap
     melos run env:init -- <profileId>  # first-time: scaffold .vet45/profiles/<profileId>/ from templates
     melos run env:build         # AOT binary for fast vet45 CLI
     vet45                       # interactive TUI (or: vet45 tui)
     vet45 switch <profile> [env]  # after profile/env change (link + sync)
     melos run analyze
     melos run test
     ./scripts/ci/verify_harness.sh
     cd apps/erp && flutter test   # khi slice có UI
6. Nếu agent fail lặp lại cùng lỗi → cập nhật harness (guard/doc/skill), không chỉ retry prompt
```



## Lệnh verify

```bash
melos bootstrap
melos run env:init -- <profileId>  # first-time: scaffold .vet45/profiles/<profileId>/ from templates
melos run env:build        # AOT binary for fast vet45 CLI
# After activate: vet45  # TUI; or vet45 switch <profile> [env]
melos run env:doctor       # khi slice cần Supabase / worker
melos run analyze
melos run test
melos run codegen          # khi module bật build_runner
melos run migrate:verify-policy -- --strict   # sau promote migration
melos run migrate:seed-registry -- --write    # regenerate REGISTRY.yaml
./scripts/ci/verify_harness.sh
cd apps/erp && flutter test
cd apps/messaging_worker && dart test
```



## Schema & migration (agents)

`supabase/migrations/` là **migration chính thức** — Supabase CLI apply theo version (`YYYYMMDDxxx_*.sql`). Trong collaboration, nhiều agent/branch cùng thêm file timestamp dễ gây **trùng version**, `db reset` fail, hoặc sequence lệch.

### Quy tắc bắt buộc


| Việc                           | Agent được                                                                      | Agent không được                                              |
| ------------------------------ | ------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| Thiết kế DDL/RPC/RLS cho slice | Viết SQL tạm vào `[supabase/migrations/_drafts/](supabase/migrations/_drafts/)` | Tạo/sửa `supabase/migrations/[0-9]*.sql`                      |
| Map contract BE                | Cập nhật harness `07-api-contracts.md` + Dart gateway/RPC client                | Giả định draft đã apply trên DB                               |
| Verify local DB                | `melos run test`, harness scripts                                               | `supabase db reset` để “thử” draft SQL (trừ khi user yêu cầu) |
| Promote migration              | —                                                                               | Tự đổi tên draft → timestamp migration                        |

**Draft naming:** `<scope>_<short_description>.sql` hoặc `NNN_<scope>_patch_<intent>_<part>.sql` cho slice lớn — quy ước chi tiết: [`supabase/migrations/_drafts/README.md`](supabase/migrations/_drafts/README.md).

**Chỉ tạo file `YYYYMMDDxxx_*.sql`** khi user **yêu cầu rõ** promote migration hoặc maintain schema chính thức. Khi promote: `melos run migrate:promote-drafts` (tùy chọn `--bundle-intent` để gom draft cùng intent); header `Kind` / `Intent` / `Touches` theo [`supabase/migrations/README.md`](supabase/migrations/README.md); cập nhật [`REGISTRY.yaml`](supabase/migrations/REGISTRY.yaml).

**Cohesive policy (patch/surgical):**

- `-- Touches:` phải liệt kê **đúng** mọi RPC `create or replace` trong file — CI kiểm tra qua `melos run migrate:verify-policy`
- **Cấm** copy body RPC không đổi từ migration cũ “cho đồng bộ”
- Tra cứu owner RPC: `supabase/migrations/REGISTRY.yaml`
- 29 migration bundled hiện tại nằm trong `bootstrap_grandfathered` — không re-split

**Lane BE không có DB:** implement application/infrastructure với RPC name + params khớp draft; test dùng fakes/in-memory — không block slice vì thiếu migration applied.

## Anti-patterns (từ chối)

- Tạo `supabase/migrations/2026....sql` trong slice agent thông thường (dùng `_drafts/` thay thế)
- Patch migration `create or replace` RPC không nằm trong `-- Touches:` hoặc copy body RPC không đổi từ migration cũ
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
- Chỉnh tay `apps/*/.env*` — sửa `.vet45/profiles/<profileId>/<env>.env` rồi `melos run env:sync`



## Legacy / ngoại lệ hiện tại

`apps/erp/features/auth/` giữ presentation (login page). Business auth nằm trong `modules/iam` qua `IIamModule` — không mở rộng direct Supabase calls từ feature shell.

## Theme harness (TH-03)

Theme đang deliver: [docs/themes/TH-03-partner/](docs/themes/TH-03-partner/)

- Ritual: [harness/00-agent-ritual.md](docs/themes/TH-03-partner/harness/00-agent-ritual.md)
- Contracts: [harness/07-api-contracts.md](docs/themes/TH-03-partner/harness/07-api-contracts.md)
- Slice order + lanes: [harness/04-slice-roadmap.md](docs/themes/TH-03-partner/harness/04-slice-roadmap.md)
- Domain model v2: [harness/01-domain-model.md](docs/themes/TH-03-partner/harness/01-domain-model.md)
- Golden module (rebuild): `modules/iam/` — partner chưa có code



## Liên kết

- [docs/operations/environment-manager.md](docs/operations/environment-manager.md) — Melos env manager (`env:*`, active environment)
- [docs/architecture/](docs/architecture/) — kiến trúc platform (CQRS, module layout)
- [docs/harness/PROGRESS.md](docs/harness/PROGRESS.md) — tiến độ harness
- [docs/themes/](docs/themes/) — catalog theme
- [packages/vet45_shared/README.md](packages/vet45_shared/README.md) — shared toolkit
- [packages/vet45_async_query/docs/AGENT_INTEGRATION_PLAYBOOK.md](packages/vet45_async_query/docs/AGENT_INTEGRATION_PLAYBOOK.md) — async query integration guide

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **vet45** (18317 symbols, 43884 relationships, 291 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> Index stale? Run `node .gitnexus/run.cjs analyze` from the project root — it auto-selects an available runner. No `.gitnexus/run.cjs` yet? `npx gitnexus analyze` (npm 11 crash → `npm i -g gitnexus`; #1939).

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows. For regression review, compare against the default branch: `detect_changes({scope: "compare", base_ref: "main"})`.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `query({search_query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `context({name: "symbolName"})`.
- For security review, `explain({target: "fileOrSymbol"})` lists taint findings (source→sink flows; needs `analyze --pdg`).

## Never Do

- NEVER edit a function, class, or method without first running `impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `rename` which understands the call graph.
- NEVER commit changes without running `detect_changes()` to check affected scope.

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/vet45/context` | Codebase overview, check index freshness |
| `gitnexus://repo/vet45/clusters` | All functional areas |
| `gitnexus://repo/vet45/processes` | All execution flows |
| `gitnexus://repo/vet45/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
|------|---------------------|
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->
