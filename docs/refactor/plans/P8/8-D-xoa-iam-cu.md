# 8-D — Xoá IAM cũ khỏi repo: `modules/iam`, `apps/admin`, `apps/messaging_worker`

> Phase: P8 (làm gọn IAM, kéo việc 9.1 của P9 lên) · Trạng thái: Plan 📝 | Làm ⬜ | Review ⬜
> Làm **sau [8-C](8-C-thay-iam-cu-bang-core.md)** (app `erp` đã hết phụ thuộc `vet45_iam_*`). Trước [8-B](8-B-db-ki08-don-luong-cu.md) (DB).
> Mục tiêu đo được: `grep -rn "vet45_iam\|apps/admin\|messaging_worker" --include=*.yaml --include=*.dart --include=*.sh .` chỉ còn trong `docs/_legacy/` và CHANGELOG; `melos bootstrap` + `flutter test` (`apps/erp`) xanh như trước.

## 1. Vì sao xoá được bây giờ

| Thư mục | Thay bằng | Còn ai dùng |
|---|---|---|
| `modules/iam/{domain,application,infrastructure,integration_events}` (27 MB) | `apps/erp/lib/{core/session, core/iam, features/{auth,iam,platform_admin}}` | Sau 8-C: chỉ `apps/admin`, `apps/messaging_worker` |
| `apps/admin` (87 MB) | 8-A (quản trị tổ chức trong tab Thêm); phần còn lại bỏ theo phương án A | Không |
| `apps/messaging_worker` (13 MB) | 2-B2 (`send-email`), P7 (`einvoice-processor`) | Không chạy từ 2026-10-07 (quyết định bỏ worker) |

Module nghiệp vụ cũ (catalog, partner, pricing, sales, einvoice, inventory) **không** phụ thuộc `vet45_iam_*` (đã đo: chỉ 3 app có trong `pubspec.yaml`).

## 2. Các bước

### Bước 1 — Kiểm trước khi xoá

```bash
grep -rln "vet45_iam" --include=pubspec.yaml apps modules packages tools   # chỉ còn apps/admin, apps/messaging_worker, modules/iam
grep -rn "vet45_iam" apps/erp                                               # rỗng (8-C)
```

### Bước 2 — Xoá thư mục

`git rm -r modules/iam apps/admin apps/messaging_worker`.

### Bước 3 — Workspace và công cụ

1. `pubspec.yaml` (gốc, workspace / melos):
   - mục workspace: bỏ `apps/admin`, `apps/messaging_worker`, `modules/iam/domain`, `modules/iam/application`, `modules/iam/infrastructure`, `modules/iam/integration_events`;
   - script melos: bỏ `worker:once`, `worker:serve`, `worker:docker`, `worker:verify`; bỏ `messaging_worker` khỏi `ignore` của script test.
2. `docker-compose.yml`, `docker-compose.local.yml`: bỏ service worker / admin (đọc file, xoá đúng service; giữ Supabase local).
3. `tools/vet45_env`: lệnh `run worker …` → xoá lệnh và test liên quan (giữ `admin create`, chuyển env, `sync`, `link`, `doctor`).
4. `scripts/`: xoá `scripts/dev/run_messaging_worker.sh`, `scripts/supabase/verify_messaging_migrations.sh`; sửa / xoá các script CI còn liệt kê `apps/admin` hoặc `messaging_worker` (`scripts/ci/guard_*.sh`, `verify_env_manifest.sh`, `scaffold_module.sh`, `collapse_presentation_into_apps.py` — script của kiến trúc cũ thì chuyển vào `docs/_legacy/scripts/` hoặc xoá).
5. `.github/pull_request_template.md`, `vet45.workspace.json`, `README.md`, `AGENTS.md`, `melos_vet45.iml`: bỏ mục admin / worker / module IAM.
6. `deploy/`: kiểm `deploy.env*`, `vet45.target.json` có biến của admin / worker không; bỏ nếu có.

### Bước 4 — Tài liệu

- PLAN P9 việc 9.1: ghi "`modules/iam`, `apps/admin`, `apps/messaging_worker` đã xoá ở 8-D"; còn lại `modules/` khác.
- SCOPE / TH-01 mục 9.1: không cần sửa (đã ghi "1 app").

### Bước 5 — Kiểm tra

```bash
melos bootstrap        # hoặc dart pub get ở gốc workspace
cd apps/erp && dart analyze lib test && flutter test
dart test tools/vet45_env
```

### Bước 6 — Commit

Một commit `chore: remove legacy IAM module, admin app and messaging worker (8-D)`.

## 3. Kiểm tra

- [ ] Lệnh grep mục tiêu ở đầu file chỉ còn `docs/_legacy/`, CHANGELOG.
- [ ] `melos bootstrap` / `pub get` gốc không lỗi.
- [ ] `apps/erp`: analyze sạch, `flutter test` như 8-C.
- [ ] `tools/vet45_env`: test xanh; `vet45 admin create --help` còn chạy.

## 4. Rủi ro / lưu ý

- Xoá lớn (≈130 MB): commit riêng để dễ `git revert` nếu cần. Tag `v-legacy-arch` (P0) vẫn giữ toàn bộ code cũ.
- DB chưa đổi ở bước này: các RPC cũ (onboarding…) vẫn nằm trong DB nhưng **không còn code gọi** → 8-B xoá an toàn.

## 5. Review

<!-- Claude ghi sau khi bạn code xong -->
