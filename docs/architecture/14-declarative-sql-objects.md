# Declarative SQL Objects — Single source of truth cho RPC / view / trigger / policy

> **Trạng thái:** Accepted.
>
> Liên quan: [supabase/migrations/README.md](../../supabase/migrations/README.md) · [supabase/migrations/_drafts/README.md](../../supabase/migrations/_drafts/README.md) · [REGISTRY.yaml](../../supabase/migrations/REGISTRY.yaml) · [08-data-and-security.md](08-data-and-security.md)

## 1. Vấn đề

- Mỗi lần sửa RPC (dù nhỏ) phải tạo một patch migration mới copy lại toàn bộ body → trùng lặp tới ~99% giữa các file.
- Muốn biết định nghĩa hiện tại của một function phải tra `REGISTRY.yaml` → mở migration cuối cùng định nghĩa nó.
- Agent/branch song song tạo file timestamp → rủi ro trùng version.

## 2. Quyết định

| # | Quyết định |
| --- | --- |
| Phạm vi | **Function, view, trigger, RLS policy** (object stateless) có file nguồn duy nhất, sửa tại chỗ. **Table / DDL / backfill** vẫn migration tuần tự qua `_drafts`. |
| Artefact deploy | Vẫn là **migration timestamp**, do tool sinh từ diff so với lock, chỉ chứa object đã đổi. Supabase CLI / `db push` / `db reset` giữ nguyên. |
| Lịch sử cũ | Không rewrite 166 migration hiện có. Module mới dùng luồng mới ngay; module cũ **adopt-on-touch** hoặc `adopt --module`. |
| Phát hiện thay đổi | Lock checksum `supabase/schema.lock.yaml` (commit vào repo, một file toàn repo). |
| Drop / đổi signature | Tool tự sinh `drop` (lock lưu signature cũ). Dependency phức tạp → tool fail, hướng dẫn viết vùng pre. |
| Thứ tự | Cố định: pre → functions → views → triggers → policies → post; trong nhóm sort theo tên. Không parse dependency. |
| Policy / trigger | File nguồn viết `create policy` / `create trigger` thuần; tool tự bọc `drop ... if exists`. |
| Ai sinh migration | Người chạy `migrate:generate` lúc promote. Agent chỉ sửa file nguồn + draft pre/post, **không** tạo file timestamp. |
| Test không có DB local | `schema:apply-dev` apply thẳng lên Supabase dev (account khác), chấp nhận lệch lịch sử migration trên DB dev. |
| Tooling | Dart, gọi qua melos / CLI `vet45`, đồng bộ `migrate:promote-drafts` / `migrate:verify-policy`. |

## 3. Layout

```text
modules/<m>/infrastructure/supabase/sql/
  functions/<name>.sql     # mọi overload của <name> chung một file
  views/<name>.sql
  triggers/<name>.sql
  policies/<name>.sql
supabase/sql/<schema>/{functions,views,triggers,policies}/<name>.sql   # public, messaging, storage, shared helpers
supabase/schema.lock.yaml
supabase/migrations/_drafts/<intent>.pre.sql
supabase/migrations/_drafts/<intent>.post.sql
```

Quy tắc discover:

- Tool quét đúng 2 root trên.
- Tên object parse từ chính câu SQL (`create or replace function <schema>.<name>(...)`), không dùng header.
- Object trong `modules/<m>/...` phải có schema = `<m>`; lệch → fail.
- Hai file cùng định nghĩa một object → fail.

### Lock

```yaml
catalog.search_products:
  source_path: modules/catalog/infrastructure/supabase/sql/functions/search_products.sql
  hash: sha256:...
  signatures:
    - "catalog.search_products(p_tenant_id uuid, p_query text)"
  last_migration: 20260801001_catalog_search_tweak.sql
```

`REGISTRY.yaml` chỉ còn giữ object **chưa adopt**; khi adopt, entry chuyển sang lock.

## 4. Lệnh

### `melos run migrate:generate -- <intent>`

1. So hash file nguồn ↔ lock → tập object thay đổi / mới / bị xoá.
2. Sinh `supabase/migrations/YYYYMMDDxxx_<intent>.sql`:

```sql
-- Kind: generated
-- Intent: <intent>
-- Touches: catalog.search_products, catalog._build_product_search_text

-- region: pre            (từ _drafts/<intent>.pre.sql — sửa tay được)
-- region: functions      (tool sinh — cấm sửa tay)
-- region: views
-- region: triggers
-- region: policies
-- region: post           (từ _drafts/<intent>.post.sql — sửa tay được)
```

3. Tự thêm `drop function <signature cũ>` khi xoá file / xoá overload / đổi signature; tự bọc `drop policy if exists` / `drop trigger if exists`.
4. Cập nhật lock (`hash`, `signatures`, `last_migration`), archive draft pre/post.

### `melos run schema:adopt -- <schema.object>` / `-- --module <m>`

- Cắt block định nghĩa từ migration mà `REGISTRY.yaml` chỉ tới (fallback / đối chiếu: `pg_get_functiondef` trên dev DB).
- Ghi file nguồn + entry lock với `last_migration` = file gốc → **không** sinh migration mới khi chưa sửa.

### `melos run schema:apply-dev`

- Target: profile `vet45` đang active (`.vet45/profiles/<id>/<env>.env`); chỉ chạy khi env nằm trong allowlist (vd. `dev`, `sandbox`), luôn từ chối `staging` / `prod`.
- In project ref + danh sách object, yêu cầu confirm.
- Apply file nguồn có hash khác bảng `vet45_dev.schema_apply_log` trên chính DB đó (dev DB có thể đi trước lock nhiều slice).
- Không apply vùng pre/post; DDL table chạy thủ công từ `_drafts` như hiện tại.

## 5. CI guards

| Guard | Nơi chạy | Mức |
| --- | --- | --- |
| File nguồn đổi mà lock chưa sync | `verify_harness.sh` | Cảnh báo ở nhánh slice; fail ở nhánh promote/release |
| Migration không phải `Kind: generated` mà `create or replace` object đã adopt | `migrate:verify-policy` | Fail |
| Vùng functions/views/triggers/policies của file `Kind: generated` không khớp byte-for-byte nguồn tại hash trong lock | `migrate:verify-policy` | Fail |
| Drift: định nghĩa function/view/trigger trong DB sau `db reset` ≠ file nguồn (policy: chỉ kiểm existence vì catalog expression lossy) | Job CircleCI `verify_schema_drift` (`./scripts/ci/verify_schema_drift.sh`) | Fail |

## 6. Workflow

```text
1. Object chưa adopt?  → schema:adopt
2. Sửa file nguồn trong modules/<m>/infrastructure/supabase/sql/...
3. Cần DDL/backfill?   → _drafts/<intent>.pre.sql / .post.sql
4. Thử                 → schema:apply-dev
5. Promote (người)     → migrate:generate -- <intent>  → review → merge
```

## 7. Rollout

1. Core tool: discover, parse object, lock, `migrate:generate` (chưa drop) + test fixture SQL. ✅
2. Drop / đổi signature, policy & trigger wrapper, ghép pre/post. ✅
3. `schema:adopt` (parse block từ REGISTRY → migration). ✅
4. `schema:apply-dev` (bảng log, allowlist env, confirm). ✅
5. CI guards (`verify-policy`, `verify_harness.sh`, job drift). ✅
6. Pilot: `partner` (greenfield dirs) dùng luồng mới từ đầu; adopt-on-touch vài function `catalog`. ✅
7. Docs/rules/skills cập nhật. ✅

Không ảnh hưởng ship unit → không cần changelog app.
