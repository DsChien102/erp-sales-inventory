# Agent onboarding — ERP Đồ án (Flutter + Supabase)

Điểm vào cho AI coding agent. Thông tin không có trong repo coi như không tồn tại.

## Repo đang refactor — đọc trước

Branch `refactor/simple-arch` đang chuyển từ modular monolith / DDD / CQRS sang kiến trúc đơn giản. Mốc code cũ: tag `v-legacy-arch`.

| Cần | Đọc |
|---|---|
| Phạm vi, kiến trúc đích, Definition of Done | [docs/refactor/SCOPE.md](docs/refactor/SCOPE.md) |
| Thứ tự phase P0…P10, việc từng phase | [docs/refactor/PLAN.md](docs/refactor/PLAN.md) |
| **Đặc tả nghiệp vụ chuẩn** (source of truth) | [docs/requirements/](docs/requirements/) — TH-01…05, TH-08; TH-07 trỏ sang `specs/themes/theme-07` |
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

## Quy tắc làm việc

- Mỗi việc trong PLAN có file plan ở [docs/refactor/plans/](docs/refactor/plans/README.md); cập nhật cột Plan / Làm / Review trong PLAN.md.
- Trả lời người dùng bằng tiếng Việt.
- Làm theo `docs/requirements`. Mục 🔧 = code cũ sai, phải sửa khi chuyển; 🆕 = chưa có, phải làm. Không chép lỗi cũ.
- Giữ chữ ký RPC hiện có trừ khi tài liệu TH ghi sửa.
- **Phạm vi kiểm thử:** khi làm từng việc/plan, **chỉ chạy test trong phạm vi plan** (file/thư mục test liên quan trực tiếp của feature, `dart analyze lib test`, `dart run tool/check_feature_imports.dart`). **Không chạy test toàn app** (`flutter test`) ở từng plan con để tránh mất thời gian; chỉ chạy toàn app khi nghiệm thu kết thúc Phase để đối chiếu với `TEST-BASELINE.md` hoặc khi người dùng yêu cầu rõ. Tick cột "Mới" trong CHECKLIST khi hoàn thành phase.

## Supabase

| Môi trường | Project | Ghi chú |
|---|---|---|
| Local | `supabase start` | `supabase db reset` dựng lại từ `supabase/migrations/` |
| Dev | `pzlsjedtsntkarkivhve` (Đồ án tốt nghiệp - Dev) | Đang link; app đọc URL và key từ `apps/erp/.env` (tạo tay) |
| Prod | `xodvjcaaxtubnkibmrmn` (Đồ án tốt nghiệp - Prod) | **Không đụng** trước P10 |

- Migration mới: `supabase/migrations/YYYYMMDDxxx_<scope>_<mô_tả>.sql`, không sửa migration đã áp. SQL HĐĐT còn ở `supabase/migrations/_drafts/` đến P7.1.
- `supabase db push` / `supabase config push` ghi lên remote: **hỏi người dùng trước**. `config push` áp ngay, không có bước xem trước.
- Không in hay commit key; file `apps/*/.env*` và `deploy/deploy.env` đã nằm trong `.gitignore`.

## Lệnh hay dùng

```bash
dart analyze apps/erp packages
cd apps/erp && flutter test test/features/<feature>  # test phạm vi plan
cd apps/erp && flutter test                         # nghiệm thu phase (so với docs/refactor/TEST-BASELINE.md)
cd apps/erp && dart run tool/check_feature_imports.dart
supabase db reset             # local
supabase migration list --linked
```
