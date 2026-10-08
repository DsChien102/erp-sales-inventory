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
    data/          <feature>_repository.dart  → supabase.schema('<schema>').rpc(...)
    presentation/  pages/, cubit/, widgets/
```

- Luồng: `Page → Cubit → Repository → RPC`. Không CommandBus/QueryBus, không mediator, không module package mới.
- Feature không import `data/` của feature khác; dùng chung qua `core/`.
- Nghiệp vụ và kiểm tra quyền nằm trong RPC Postgres (`iam.has_permission`); app chỉ hiển thị.
- Gọi dịch vụ ngoài (MISA meInvoice, email) qua **Supabase Edge Function** (`supabase/functions/*`), kích hoạt bởi app và `pg_cron`. Không có worker chạy riêng (TH-08 KI-20).
- Code cũ trong `modules/`, `packages/vet45_shared`, `apps/admin`, `apps/messaging_worker` còn đến P9; chỉ đọc để chuyển, không thêm code mới vào đó.

## Quy tắc làm việc

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
supabase db reset             # local
supabase migration list --linked
```

## GitNexus

Hướng dẫn GitNexus (impact analysis trước khi sửa symbol, `detect_changes` trước khi commit) ở [CLAUDE.md](CLAUDE.md). Nếu môi trường không có GitNexus, ghi rõ điều đó khi báo cáo.
