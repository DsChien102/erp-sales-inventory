# Agent onboarding — ERP Đồ án (Flutter + Supabase)

Điểm vào cho AI coding agent. Thông tin không có trong repo coi như không tồn tại.

## Repo đang refactor — đọc trước

Branch `refactor/simple-arch` đang chuyển từ modular monolith / DDD / CQRS sang kiến trúc đơn giản. Mốc code cũ: tag `v-legacy-arch`.

| Cần | Đọc |
|---|---|
| Phạm vi, kiến trúc đích, Definition of Done | [docs/refactor/SCOPE.md](docs/refactor/SCOPE.md) |
| Thứ tự phase P0…P10, việc từng phase | [docs/refactor/PLAN.md](docs/refactor/PLAN.md) |
| **Đặc tả nghiệp vụ chuẩn** (source of truth) | [docs/02-yeu-cau/](docs/02-yeu-cau/) — TH-01…05, TH-08; TH-07 trỏ sang `specs/themes/theme-07` |
| Nghiệm thu màn hình | [docs/refactor/CHECKLIST.md](docs/refactor/CHECKLIST.md) |
| Test đang lỗi sẵn trước refactor | [docs/refactor/TEST-BASELINE.md](docs/refactor/TEST-BASELINE.md) |
| Tài liệu kiến trúc cũ (chỉ để đọc code cũ) | [docs/_legacy/](docs/_legacy/README.md) — **không** áp dụng cho code mới |

## Kiến trúc đích

```text
apps/erp/lib/
  core/        supabase, router (guard), session (SessionController), errors (AppException), formatting
  features/<feature>/
    data/          models/ + <feature>_repository.dart  → SupabaseRpc → supabase.schema('<schema>').rpc(...)
    logic/         cubit + state; rule nghiệp vụ phía client (hàm thuần)
    presentation/  pages/, widgets/
```

- Luồng: `Page → Cubit → Repository → RPC`. Không CommandBus/QueryBus, không mediator, không module package mới.
- Phụ thuộc: `presentation → logic → data`. Feature khác chỉ dùng **repository** (`data/`) của nhau, không import `logic/`/`presentation/` của nhau (SCOPE 3.1). Kiểm bằng `dart run tool/check_feature_imports.dart` (từ 1-A).
- Page được import kiểu repository (`data/`) **chỉ để tạo cubit** (`BlocProvider(create: (_) => XCubit(repository: …))`); mọi lời gọi dữ liệu đi qua cubit.
- Lỗi: repository ném `AppException` (`core/errors`), UI hiển thị `e.userMessage()`.
- Nghiệp vụ và kiểm tra quyền nằm trong RPC Postgres (`iam.has_permission`); app chỉ hiển thị.
- Gọi dịch vụ ngoài (MISA meInvoice, email) qua **Supabase Edge Function** (`supabase/functions/*`), kích hoạt bởi app và `pg_cron`. Không có worker chạy riêng (TH-08 KI-20).
- Code cũ trong `modules/` và `packages/vet45_shared` còn đến P9 (IAM cũ, app admin và worker đã xoá ở 8-D); chỉ đọc để chuyển, không thêm code mới vào đó.

## Quy tắc làm việc

- **Phân vai:** agent **lên plan và review**, người dùng **tự code**. Mỗi việc trong PLAN có file plan ở [docs/refactor/plans/](docs/refactor/plans/README.md); cập nhật cột Plan / Làm / Review trong PLAN.md. Không tự sửa code ứng dụng trừ khi người dùng yêu cầu rõ.
- Trả lời người dùng bằng tiếng Việt; xác nhận phạm vi trước khi sửa code.
- Làm theo `docs/02-yeu-cau`. Mục 🔧 = code cũ sai, phải sửa khi chuyển; 🆕 = chưa có, phải làm. Không chép lỗi cũ.
- Giữ chữ ký RPC hiện có trừ khi tài liệu TH ghi sửa.
- Mỗi phase: test không được lỗi thêm ngoài `TEST-BASELINE.md`; tick cột "Mới" trong CHECKLIST.

## Supabase

| Môi trường | Project | Ghi chú |
|---|---|---|
| Local | `supabase start` | `supabase db reset` dựng lại từ `supabase/migrations/` |
| Dev | `pzlsjedtsntkarkivhve` (Đồ án tốt nghiệp - Dev) | Đang link; app dùng qua `.vet45/profiles/default/development.env` → `melos run env:sync` |
| Prod | `xodvjcaaxtubnkibmrmn` (Đồ án tốt nghiệp - Prod) | **Không đụng** trước P10 |

- Migration mới: `supabase/migrations/YYYYMMDDxxx_<scope>_<mô_tả>.sql`, không sửa migration đã áp. SQL HĐĐT còn ở `supabase/migrations/_drafts/` đến P7.1.
- `supabase db push` / `supabase config push` ghi lên remote: **hỏi người dùng trước**. `config push` áp ngay, không có bước xem trước.
- Không in hay commit key; file `.vet45/profiles/**` và `apps/*/.env*` đã nằm trong `.gitignore`.

## Lệnh hay dùng

```bash
melos run env:sync            # sinh apps/erp/.env từ profile đang chọn
melos run analyze
cd apps/erp && flutter test   # so với docs/refactor/TEST-BASELINE.md
cd apps/erp && dart run tool/check_feature_imports.dart
supabase db reset             # local
supabase migration list --linked
```

## GitNexus

Hướng dẫn GitNexus (impact analysis trước khi sửa symbol, `detect_changes` trước khi commit) ở [CLAUDE.md](CLAUDE.md). Nếu môi trường không có GitNexus, ghi rõ điều đó khi báo cáo.

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **erp-sales-inventory** (53377 symbols, 121113 relationships, 300 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

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
| `gitnexus://repo/erp-sales-inventory/context` | Codebase overview, check index freshness |
| `gitnexus://repo/erp-sales-inventory/clusters` | All functional areas |
| `gitnexus://repo/erp-sales-inventory/processes` | All execution flows |
| `gitnexus://repo/erp-sales-inventory/process/{name}` | Step-by-step execution trace |

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
