# 4-C — Dọn sạch module partner + 3 module rỗng + `vet45_resend`

> Theme 3 (mã cũ P4) · Bước (dọn) theo "Quy tắc dọn module (chốt 2026-10-11)" của PLAN.md
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-01, kèm các đề xuất "duyệt plan là chốt") | Làm ✅ 2026-11-01 (chưa commit; bước DB local là việc của người dùng) | Review ✅ R1 2026-11-02 (code đạt; còn người dùng: DB local + reset Dev, xem mục 8)
> Làm **sau** [4-A](4-A-partner-repository.md), [4-B](4-B-sua-ki-th03.md), [4-W](4-W-partner-web.md). Chỉ cần 4-A xong là đủ điều kiện kỹ thuật; xếp cuối theme để chỉ xoá một lần.
> Tài liệu: PLAN.md mục Theme 3 dòng 4-C, "Quy tắc migration"; TH-03 mục 9.1 (bỏ outbox `partner.partner.*`).

## 1. Mục tiêu

- App không còn phụ thuộc `vet45_partner_*`.
- Xoá `modules/partner/{domain,application,infrastructure}`. **Giữ** `modules/partner/integration_events` tới 7-5 (einvoice còn import).
- DB schema `partner` bỏ outbox / inbox / internal commands (chưa ai nghe; worker đã bỏ ở 3-C).
- Kèm theo:
  - xoá 3 module rỗng `accounting`, `costing`, `dashboard` (app không dùng);
  - xoá `packages/vet45_resend` (chỉ worker đã xoá dùng);
  - dọn `apps/erp/example`.

## 2. Hiện trạng (đo 2026-11-01)

| Thứ | Ai còn dùng |
|---|---|
| `vet45_partner_domain/application/infrastructure` | `apps/erp/pubspec.yaml:27–29`. Sau 4-A chỉ còn nhóm `old` của `test/features/partner/data/partner_rpc_parity_test.dart` và `test/features/partner/logic/partner_rules_test.dart` |
| `vet45_partner_integration_events` | `modules/einvoice/application` + `infrastructure` (pubspec, `partner_profile_updated_integration_event_handler.dart`, `einvoice_integration_event_registry.g.dart`, `build.yaml:47`, 4 test), `modules/einvoice/presentation/example/pubspec.yaml:53` ⇒ **giữ** |
| `modules/accounting`, `costing`, `dashboard` (mỗi cái 4 package) | chỉ `pubspec.yaml` workspace + `apps/erp/example/pubspec.yaml` (dependency_overrides) |
| `packages/vet45_resend` | chỉ `pubspec.yaml` workspace (dòng 14) |
| Test hợp đồng SQL partner | `modules/partner/infrastructure/test/partner_list_search_sql_contract_test.dart`, `partner_alternate_name_search_sql_contract_test.dart` (đọc tệp migration, 4-B đã sửa regex). Xoá module thì mất ⇒ chuyển sang app |
| `scripts/ci/guard_application_use_case_layout.sh` | dòng 3 (chú thích "Golden reference" trỏ `modules/partner/...`), dòng 47–48 (`guarded_areas`). Script bỏ qua thư mục không tồn tại (`[[ -d ]] || continue`) ⇒ không vỡ, nhưng phải dọn |
| DB: `supabase/migrations/20260714002_partner_v2_outbox.sql` | chỉ 1 câu `select platform.install_module_messaging('partner');`. Tạo `partner.outbox_messages`, `inbox_messages`, `internal_commands` + 10 hàm `enqueue_outbox_message`, `claim_*`, `complete_*`, `fail_*`, `receive_integration_event`, `enqueue_internal_command` (`20260623000001:169`) |
| DB: lời gọi `partner.enqueue_outbox_message(...)` | **9 chỗ** trong `20260714004_partner_v2_write_rpc.sql` (`grep -c`). Không tệp nào khác đọc `partner.outbox_*` / `inbox_*` / `internal_commands` (grep 2026-11-01) |
| `supabase/migrations/REGISTRY.yaml` | `partner: enqueue_outbox_message: 20260714002_partner_v2_outbox.sql` (dòng ≈ 318); `bootstrap_grandfathered: - 20260714002_partner_v2_outbox.sql` (≈ 485) |
| `20260714001_partner_v2_schema.sql:405–406` | chú thích nhắc `partner.outbox_messages` |

**Không dọn ở đây** (Dọn dẹp P9 lo): danh sách `v_allowed` của `platform.install_module_messaging` (còn `'partner'`, `'accounting'`, …), `platform.messaging_module_registry`, `packages/vet45_shared`, `vet45_adapters`.

## 3. Thay đổi

| Tệp / thư mục | Hành động |
|---|---|
| `apps/erp/pubspec.yaml` | xoá 3 dòng `vet45_partner_domain/application/infrastructure` |
| `apps/erp/test/features/partner/data/partner_rpc_parity_test.dart`, `apps/erp/test/features/partner/logic/partner_rules_test.dart` | xoá **nhóm `old`** và import `vet45_partner_*`. Giữ nhóm `new` và **map mong đợi** (không sửa map) |
| `apps/erp/test/features/partner/data/partner_search_sql_contract_test.dart` | tạo: gộp 2 test hợp đồng SQL từ module. Đổi `package:test/test.dart` → `package:flutter_test/flutter_test.dart`. `_findRepoRoot` giữ (đi ngược lên tới thư mục có `pubspec.yaml` + `supabase/migrations`). Bỏ 2 nhánh đọc `_drafts/partner_list_search_behavior.sql` / `_drafts/partner_exclude_roleless_search.sql` (không còn tệp nào) |
| `modules/partner/domain`, `modules/partner/application`, `modules/partner/infrastructure` | xoá cả thư mục |
| `modules/accounting`, `modules/costing`, `modules/dashboard` | xoá cả thư mục |
| `packages/vet45_resend` | xoá cả thư mục |
| `pubspec.yaml` (gốc, `workspace:`) | xoá 16 dòng: `packages/vet45_resend`, `modules/partner/{domain,application,infrastructure}`, `modules/{costing,dashboard,accounting}/{domain,application,infrastructure,integration_events}`. **Giữ** `modules/partner/integration_events` |
| `apps/erp/example/pubspec.yaml` | xoá mọi mục `vet45_partner_{application,domain,infrastructure}` (giữ `vet45_partner_integration_events` nếu có và còn cần: kiểm bằng `flutter pub get`), `vet45_accounting_*`, `vet45_costing_*`, `vet45_dashboard_*` ở cả `dependencies` và `dependency_overrides` |
| `scripts/ci/guard_application_use_case_layout.sh` | xoá 2 dòng `modules/partner/application/lib/src/partner…` ở `guarded_areas`. Dòng 3 và dòng 114 (chú thích / `echo` "Golden reference") đổi sang một thư mục `commands/<use_case>/` **còn tồn tại** trong `guarded_areas` (chọn bằng `ls`, ghi tên đã chọn vào Kết quả) |
| `supabase/migrations/20260714002_partner_v2_outbox.sql` | xoá tệp |
| `supabase/migrations/20260714004_partner_v2_write_rpc.sql` | xoá 9 khối `perform partner.enqueue_outbox_message(…);` (mỗi khối gồm cả `jsonb_build_object(...)` tới dấu `;`). Không đổi gì khác |
| `supabase/migrations/20260714001_partner_v2_schema.sql` | xoá 2 dòng chú thích 405–406 |
| `supabase/migrations/REGISTRY.yaml` | xoá `enqueue_outbox_message` dưới `partner:` và dòng `- 20260714002_partner_v2_outbox.sql` dưới `bootstrap_grandfathered:` |
| `docs/refactor/TEST-BASELINE.md` | phiên review cập nhật: bỏ các dòng `modules/partner/{domain,application,infrastructure}`, `modules/{accounting,costing,dashboard}` |

## 4. Các bước

Trước khi xoá / sửa: `gitnexus impact` cho `PartnerStartup`, `IPartnerModule`, `FakePartnerModule` (phải không còn caller ngoài chính module và nhóm `old`). Ghi kết quả.

1. **Kiểm điều kiện:**
   - `git grep -n "vet45_partner_\(domain\|application\|infrastructure\)" -- apps ':!apps/erp/pubspec.yaml' ':!apps/erp/example/pubspec.yaml'` chỉ còn 2 tệp test có nhóm `old`;
   - `git grep -n "vet45_accounting\|vet45_costing\|vet45_dashboard\|vet45_resend" -- ':!modules/accounting' ':!modules/costing' ':!modules/dashboard' ':!packages/vet45_resend' ':!*.lock'` chỉ còn `pubspec.yaml` gốc và `apps/erp/example/pubspec.yaml`.
   - Khác thì dừng, ghi lại.
2. **Test app:** sửa 2 tệp parity / rules (bỏ nhóm `old`). Tạo `partner_search_sql_contract_test.dart`, chạy xanh **trước** khi xoá module: cùng số test, cùng kết quả như bản trong module. Riêng test `alternate_name` theo trạng thái 4-B đã ghi.
3. **Xoá thư mục** (mục 3) + sửa `pubspec.yaml` gốc, `apps/erp/pubspec.yaml`, `apps/erp/example/pubspec.yaml`.
   - `flutter pub get` ở gốc workspace, `apps/erp`, `apps/erp/example`, `modules/einvoice/presentation/example`: không lỗi phân giải.
4. **Script CI** (mục 3).
5. **DB:** xoá `20260714002`, sửa `004`, `001`, `REGISTRY.yaml`.
   - `grep -c "enqueue_outbox_message" supabase/migrations/20260714004_partner_v2_write_rpc.sql` → `0`.
   - `grep -rn "partner\.\(outbox_messages\|inbox_messages\|internal_commands\|enqueue_outbox_message\)" supabase/migrations` → rỗng.
   - `supabase db reset` **local**: chạy qua toàn bộ migration + `seed.sql`.
   - Chạy `supabase/tests/partner_th03.sql` và `supabase/tests/iam_*.sql` trên local: xanh.
   - Kiểm schema: `select table_name from information_schema.tables where table_schema = 'partner'` không còn `outbox_messages` / `inbox_messages` / `internal_commands`.
6. **Kiểm mục 5**, ghi Kết quả, `detect_changes()`.

## 5. Kiểm tra

- [ ] `git grep -n "package:vet45_partner_\(domain\|application\|infrastructure\)" -- apps modules packages` rỗng.
- [ ] `ls modules` → `catalog einvoice inventory partner pricing sales`; `ls modules/partner` → `integration_events`.
- [ ] `ls packages` không còn `vet45_resend`.
- [ ] `cd apps/erp && dart analyze lib test`: không lỗi mới. `flutter test`: không fail mới so với sau 4-W. Số test giảm đúng bằng số test nhóm `old` đã xoá (ghi số).
- [ ] `cd modules/einvoice/application && dart test`, `cd modules/einvoice/infrastructure && dart test`: không fail mới so với `TEST-BASELINE.md` (einvoice vẫn dựng được với `vet45_partner_integration_events`).
- [ ] `cd apps/erp/example && dart analyze lib`: không lỗi.
- [ ] `scripts/ci/guard_application_use_case_layout.sh` chạy qua.
- [ ] `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart`: không lỗi mới.
- [ ] Bước 5 mục 4 (DB local) đạt.
- [ ] Dev: sửa / xoá migration đã áp ⇒ Dev chỉ khớp sau `db reset --linked`. Đó là **việc của người dùng**, phiên code không chạy, chỉ ghi "cần reset Dev" vào Kết quả.

## 6. Rủi ro / lưu ý

- `modules/partner/integration_events` còn tới 7-5. Đừng xoá nhầm khi xoá `modules/partner/*`. Lệnh xoá liệt kê đúng 3 thư mục.
- Xoá `install_module_messaging('partner')` thì schema `partner` không còn `internal_commands`. Theme 8 (7-4) **không** dùng bảng của schema `partner`: trigger hồ sơ khách đổi ghi vào `einvoice.internal_commands` (PLAN 7.5). Ghi nhắc ở đây để 7-4 không tìm bảng `partner.internal_commands`.
- Test hợp đồng SQL chuyển sang app phải chạy được từ `apps/erp` (`flutter test`). `_findRepoRoot` đi ngược lên là đủ; kiểm bằng cách chạy riêng tệp đó.

## 7. Kết quả (phiên làm code ghi)

> Xong **mỗi bước** ghi ngay. Mẫu: trạng thái ✅ / 🔄 dở / ⏭ (lý do) · tệp / thư mục đã đổi · lệch plan + lý do · test thêm / sửa / xoá · impact · ghi chú cho review. Bước cuối: lệnh, số pass / fail, fail đối chiếu `TEST-BASELINE.md`, `detect_changes()`, "cần reset Dev".

### Kết quả (2026-11-01)

**Impact (GitNexus, repo `erp-sales-inventory`):** `PartnerStartup` LOW (1 caller: `infrastructure.dart`); `FakePartnerModule` LOW (caller là `testing.dart` + 3 tab của `example/lib/partner/preview`, thư mục này đã xoá ở working tree); `IPartnerModule` HIGH theo chỉ mục nhưng mọi caller nằm trong `modules/partner/{application,infrastructure}`. Grep ngoài module: chỉ 1 dòng chú thích ở `test/features/partner/support/fake_partner_repository.dart:58`. Không còn caller thật ⇒ xoá được.

**Bước 1 ✅ (có lệch):** `git grep` bỏ sót tệp chưa theo dõi. Thực tế `vet45_partner_*` còn ở 3 tệp test của app, không phải 2: thêm `apps/erp/test/core/di/injection_test.dart` (import `vet45_partner_application` + dòng `expect(getIt.isRegistered<IPartnerModule>(), isFalse)`). Đã xoá import và dòng đó. `vet45_accounting/costing/dashboard/resend` đúng như plan (chỉ `pubspec.yaml` gốc + `apps/erp/example/pubspec.yaml`).

**Bước 2 ✅:**
- `test/features/partner/logic/partner_rules_test.dart`: xoá nhóm `old` + helper `_person/_org/_create` kiểu cũ: **−12 test** (24 → 12). Map/ca nhóm `new` giữ nguyên.
- `test/features/partner/data/partner_rpc_parity_test.dart`: xoá nhóm `old` + `oldPerson/oldContact/oldOrganization` + 4 import: **−17 test**. Map mong đợi không sửa; chỉ đổi 3 chú thích nhắc nhóm old/new.
- `test/features/partner/data/partner_search_sql_contract_test.dart` (mới): gộp 6 test của `partner_list_search_sql_contract_test` + 1 test của `partner_alternate_name_search_sql_contract_test` = **7 test**, `flutter test` xanh 7/7. Đã bỏ các nhánh đọc `_drafts`, đổi sang `flutter_test`.
- **Lệch plan:** test `alternate_name` ở module đang đỏ sẵn (baseline, 4-B đã ghi) vì `contains('op.short_name')`: migration `20260715001` dùng `v.short_name`, không có `op.short_name`. Khi chuyển tôi đổi đúng assertion đó thành `contains('v.short_name')` (kèm chú thích trong tệp) để không mang test đỏ vào app. Các regex còn lại giữ nguyên. Ngoài ra `pp.nickname` có trong SQL (2 lần).
- Tổng `flutter test` apps/erp: **1760 test, 61 lỗi**. Số test nhóm `old` đã xoá −29, thêm +7 ⇒ ròng −22 (không có số đo trước 4-C để đối chiếu trực tiếp).

**Bước 3 ✅:** xoá `modules/partner/{domain,application,infrastructure}`, `modules/{accounting,costing,dashboard}`, `packages/vet45_resend` (đã kiểm không có tệp chưa commit nào ngoài 2 test SQL đã chuyển). Sửa `pubspec.yaml` gốc (−16 dòng), `apps/erp/pubspec.yaml` (−3), `apps/erp/example/pubspec.yaml` (−18 mục gồm cả `dependencies` `vet45_partner_application/domain`; `vet45_partner_integration_events` giữ trong overrides). `ls modules` = `catalog einvoice inventory partner pricing sales`; `ls modules/partner` = `integration_events`. `flutter pub get` ở gốc, `apps/erp/example`, `modules/einvoice/presentation/example`: không lỗi phân giải.

**Bước 4 ✅:** `scripts/ci/guard_application_use_case_layout.sh`: bỏ 2 dòng `guarded_areas` partner; "Golden reference" (dòng 3 và `echo` dòng ≈ 112) đổi sang `modules/catalog/application/lib/src/product/commands/create_product/` (có trong `guarded_areas`, đã `ls`). Chạy: `OK`.

**Bước 5 🔄 (DB, thiếu phần chạy local):**
- ✅ Xoá `20260714002_partner_v2_outbox.sql` (`git rm`, đang ở trạng thái staged-delete); `20260714004`: xoá đủ 9 khối `perform partner.enqueue_outbox_message(...)` (regex neo cả khối `jsonb_build_object`; `grep -c` = 0); `20260714001`: xoá 2 dòng chú thích; `REGISTRY.yaml`: xoá `enqueue_outbox_message` dưới `partner:` (dòng 319) và `- 20260714002_…` dưới `bootstrap_grandfathered`. Mục `enqueue_outbox_message` dưới `iam:` giữ nguyên.
- ✅ `grep -rnE "partner\.(outbox_messages|inbox_messages|internal_commands|enqueue_outbox_message)" supabase/migrations` → rỗng. Không tệp nào khác nhắc `20260714002`/`partner_v2_outbox` (ngoài chính plan này).
- ⏭ **Chưa chạy** `supabase db reset` local, `supabase/tests/partner_th03.sql`, `supabase/tests/iam_*.sql`, truy vấn `information_schema`: lệnh `supabase db reset --local` bị hệ thống chặn (auto mode, "irreversible local destruction") và theo ghi nhớ reset DB là việc của người dùng. Cần người dùng chạy (xem lệnh ở phần báo cáo cuối). **Cần reset Dev** (`db reset --linked`) vì đã sửa/xoá migration đã áp.

**Bước 6:**
- `dart analyze lib test` (apps/erp): 249 issue, **0 error, 0 warning** (toàn `info`: deprecated/unnecessary_import có sẵn). `apps/erp/example`: `dart analyze lib` 2 `info` (`sales/main.dart`, deprecated), 0 lỗi.
- `flutter test` apps/erp: 1760 test, **61 lỗi, trùng khít từng tên** với danh sách `TEST-BASELINE.md` (cập nhật 2026-10-28, 61 lỗi): không lỗi mới; không test partner / `core/di` nào đỏ.
- `modules/einvoice/application` `dart test`: 217 đạt / 1 lỗi = baseline. `modules/einvoice/infrastructure`: **378 đạt / 60 lỗi**, baseline ghi 741 / 2. **Không do 4-C**: 60 lỗi đều là test `*_sql_contract_test` đọc `supabase/migrations/_drafts/*.sql` (`PathNotFoundException` / "draft SQL must exist"); 26 tệp `_drafts/0xx_einvoice_*.sql` đang ở trạng thái ` D` (xoá chưa commit) trong working tree từ trước phiên này, tôi không đụng `_drafts`. Cần người dùng/phiên review quyết định (khôi phục hoặc chuyển 7-x); số 741 → 378 cũng phản ánh các tệp test bị mất vì `setUpAll` lỗi.
- `verify_migration_policy.dart`: 0 error, 1 warning có sẵn (`20261101001_partner_sales_order_history_trigger.sql` chưa có owner trong REGISTRY).
- `detect_changes()` (toàn working tree, gồm cả 4-A/4-W chưa commit): 105 tệp, 87 symbol, 0 process bị ảnh hưởng, risk **low**.
- Chưa làm: cập nhật `docs/refactor/TEST-BASELINE.md` (việc của phiên review theo mục 3); chưa commit.

**Ghi chú cho review:** (1) `op.short_name`→`v.short_name` ở test chuyển sang app; (2) `injection_test.dart` là tệp thứ 3 ngoài plan; (3) mục 5 "Bước 5 mục 4 (DB local)" còn mở; (4) 7-4 không tìm `partner.internal_commands` (xem mục 6).

## 8. Review

### R1 — 2026-11-02 — ✅ ĐẠT (code; 0 P1, 0 P2, 3 P3)

**Kết luận: ĐẠT** phần code / tệp. Xoá đúng phạm vi, giữ `modules/partner/integration_events`, không còn tham chiếu, test không lỗi mới. Còn bước DB local (mục 4 bước 5) chưa chạy: việc của người dùng, không chặn kết luận code.

| Hạng mục | Kết quả |
|---|---|
| Xoá thư mục + workspace | Đạt. `ls modules` = `catalog einvoice inventory partner pricing sales`; `ls modules/partner` = `integration_events`; `packages` không còn `vet45_resend`. `pubspec.yaml` gốc −16 dòng đúng danh sách, `apps/erp/pubspec.yaml` −3 |
| Không còn tham chiếu | Đạt. `grep -rn` (kể cả tệp chưa theo dõi) `vet45_partner_(domain\|application\|infrastructure)` và `vet45_(accounting\|costing\|dashboard\|resend)` trong `apps modules packages scripts tools pubspec.yaml`: rỗng. Lệch plan `injection_test.dart` (tệp thứ 3) hợp lý |
| Test app | Đạt. `partner_search_sql_contract_test.dart` 7 test = 6 (list, gồm 1 test 4-B thêm) + 1 (alternate_name); `test/features/partner/{data,logic}` + `test/core/di`: 143/143 xanh. Toàn `apps/erp`: **1705 đạt / 61 lỗi**, 61 tên khớp `TEST-BASELINE.md` (đo ở review 4-W R2, cùng working tree) |
| Đổi `op.short_name` → `v.short_name` | Chấp nhận. `op.short_name` chỉ có trong định nghĩa view `partner.v_partner_list` (`20260714009:36`); bản `search_partners` mới nhất (`20260715001`, tệp test đọc) chỉ đọc `v.short_name` (`:91`, `:180`). Xem P3-1 |
| Migration | Đạt. `20260714004`: đúng 9 khối `perform partner.enqueue_outbox_message(...)` bị xoá, không đổi gì khác của 4-C (đoạn `add_organization_contact` khác trong diff là G3 của 4-B). `20260714001`: −2 dòng chú thích. `REGISTRY.yaml`: bỏ `partner.enqueue_outbox_message` + `bootstrap_grandfathered` `20260714002` (các khối `einvoice:` / sắp xếp lại `iam:` trong cùng diff là của lượt promote HĐĐT 2026-10-31, không thuộc 4-C). `grep` `partner.(outbox_messages\|inbox_messages\|internal_commands\|enqueue_outbox_message)`, `install_module_messaging('partner')`, `20260714002` trong `supabase apps tools scripts`: rỗng |
| Script CI / policy / example | Đạt. `guard_application_use_case_layout.sh`: `OK`, golden reference trỏ `modules/catalog/.../commands/create_product/`. `verify_migration_policy.dart`: 0 error, 1 warning (P3-2). `apps/erp/example`: `dart analyze lib` 2 info, 0 lỗi |
| einvoice | Đạt theo nghĩa của mục 5 (einvoice vẫn dựng với `vet45_partner_integration_events`). `application` 217 / 1 = baseline. `infrastructure` 378 / 60: phiên review chạy `dart test -r failures-only`, **cả 60 lỗi** nằm ở 36 tệp test đọc `supabase/migrations/_drafts/0xx_einvoice_*.sql` (đã promote thành `20261031001…023` ngày 2026-10-31, không do 4-C); không lỗi biên dịch / phân giải package. Đã ghi vào `TEST-BASELINE.md` |
| `TEST-BASELINE.md` (việc phiên review, mục 3) | Đã làm: bỏ hàng `packages/vet45_resend`, `modules/partner/{domain,application,infrastructure}` và mục lỗi `modules/partner/infrastructure`; thêm ghi chú "Sau 4-C" (số `apps/erp`, einvoice). `accounting/costing/dashboard` không có hàng (không có test) |
| Bắt buộc sửa / Tuỳ chọn sửa / Cần người dùng chốt | Không có |
| Chỉ ghi nhận | P3-1 … P3-3 |
| **Còn lại (người dùng)** | (1) `supabase db reset` local; chạy `supabase/tests/partner_th03.sql`, `supabase/tests/iam_*.sql`; kiểm `information_schema.tables` schema `partner` không còn `outbox_messages` / `inbox_messages` / `internal_commands`. (2) Reset Dev (`db reset --linked`) vì đã sửa / xoá migration đã áp. (3) `node .gitnexus/run.cjs analyze` + `detect_changes()` rồi commit |

#### P3 (không chặn)

1. **[Không sửa — chỉ ghi nhận]** Sau khi đổi, `expect(sql, contains('v.short_name'))` (`partner_search_sql_contract_test.dart`, test cuối) thừa: regex ngay dưới đã đòi `v.short_name` 2 lần. Việc nối `op.short_name` → `short_name` của view không còn test nào kiểm (chỉ là tệp view `20260714009`). Không ảnh hưởng hành vi.
2. **[Không sửa — chỉ ghi nhận]** Warning `verify_migration_policy` báo `catalog._trg_sales_order_partner_history` thiếu trong REGISTRY, nhưng hàm thật là `partner._trg_sales_order_partner_history` (`20261101001:12`) và REGISTRY đã có dưới `partner:`. Công cụ đoán sai schema; có từ 4-B, không do 4-C.
3. **[Không sửa — chỉ ghi nhận]** Mục 7 ghi `flutter test` 1760 test; nay 1766 (1705 + 61) vì R1 của 4-W thêm 6 test sau lúc đo. Khớp.

**Đã chạy (phiên review):** các `grep` ở bảng trên; `flutter test test/features/partner/data test/features/partner/logic test/core/di` 143/143; `dart analyze` (example); `guard_application_use_case_layout.sh`; `verify_migration_policy.dart`; `dart test` `modules/einvoice/{application,infrastructure}` (+ `-r failures-only` để phân loại); đối chiếu diff `004` / `001` / `REGISTRY.yaml` với plan 4-B. Không chạy DB.
