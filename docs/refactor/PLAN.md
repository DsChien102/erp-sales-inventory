# Kế hoạch thực hiện refactor

> Đi kèm [SCOPE.md](SCOPE.md) (phạm vi và các quyết định đã chốt). File này trả lời câu hỏi: **làm gì, theo thứ tự nào, xong thì kiểm tra thế nào.**
> Branch làm việc: `refactor/simple-arch` (tách từ `feature/theme8`). Ngày lập: 2026-10-06.

## Tổng quan

```text
P0 Chuẩn bị ─▶ P1 Nền core/ ─▶ P2 Auth & IAM ─▶ P8 Quản trị tổ chức ─▶ P4 Partner ─▶ P3 Catalog+Inventory ─▶ P5 Pricing ─▶ P7 E-invoice ─▶ P6 Sales ─▶ Đợt kiểm IAM ─▶ P9 Dọn dẹp ─▶ P10 Hoàn thiện báo cáo
```

**Thứ tự thực hiện** (đổi ngày 2026-10-11, cập nhật cùng ngày: E-invoice trước Sales; mã phase giữ nguyên để không phải sửa các tài liệu tham chiếu):

| Bước | Phase | Lý do |
|---|---|---|
| 1 | P8 Quản trị tổ chức | Làm nối tiếp IAM khi còn nhớ ngữ cảnh; khung thiết kế đã duyệt |
| 2 | P4 Partner | Nhỏ, chỉ cần P2; P5 / P6 cần nó |
| 3 | P3 Catalog + Inventory | Lớn; P5 / P6 cần nó |
| 4 | P5 Pricing | Cần P3, P4 |
| 5 | P7 E-invoice | Cần P2. Khu HĐĐT trên đơn (7.3) gắn vào **màn chi tiết đơn cũ** của Sales; hạ tầng Edge Function + `pg_cron` giống 2-B2 nên làm tiếp khi còn nhớ |
| 6 | P6 Sales | Cần P3, P4, P5; khi chuyển màn chi tiết đơn phải **giữ** `OrderEInvoiceSection` của P7 |
| 7 | **Đợt kiểm IAM** (đóng P2 và P8) | Kiểm 5 migration của P2 trong `rollback` → `db push` → `config push` → secrets / Vault → `functions deploy send-email` → kiểm tay TH-01 9.3 + P8 → tick CHECKLIST. Gửi mail tới người ngoài project cần tên miền + Resend |
| 8 | P9 Dọn dẹp | Cần tất cả |
| 9 | P10 Hoàn thiện báo cáo | Cần P9 |

> ⚠️ Hệ quả của việc dời đợt kiểm IAM: P3–P7 sẽ chạy trên Dev **chưa có** 5 migration mới của P2 (trigger đăng ký, email job, sửa nhận lời mời) và Dev vẫn tắt xác minh email. Không ảnh hưởng nghiệp vụ P3–P7; nhưng nếu P3–P7 thêm migration mới thì phải push **sau** `20261009001…005` (đặt timestamp lớn hơn) hoặc làm đợt kiểm IAM trước lần push đầu tiên của P3–P7.

| Phase | Nội dung | Ước lượng | Phụ thuộc |
|---|---|---|---|
| P0 | Chuẩn bị branch, commit việc dở, chụp checklist | 0,5 ngày | — |
| P1 | Dựng `core/` + mẫu feature | 2 ngày | P0 |
| P2 | Auth, đăng ký cửa hàng, IAM | 5 ngày | P1 |
| P3 | Catalog + Inventory (+ dọn module) | 5,5 ngày | P2 |
| P4 | Partner (+ dọn module, 3 module rỗng) | 2,5 ngày | P2 |
| P5 | Pricing (+ dọn module) | 2,5 ngày | P3, P4 |
| P6 | Sales (+ dọn module cuối, package module) | 6,5 ngày | P3, P4, P5 (giữ khu HĐĐT trên đơn từ P7) |
| P7 | E-invoice (+ dọn module, `vet45_misa`) | 8,5 ngày | P2 (7.3 gắn vào màn đơn cũ của Sales) |
| P8 | Quản trị tổ chức (gộp phần tổ chức của `apps/admin` vào tab Thêm) | 2 ngày | P2 |
| P9 | Dọn dẹp còn lại (`vet45_shared`, Melos, DB messaging, baseline) | 2 ngày | P1–P8 |
| P10 | Tài liệu, sơ đồ cho báo cáo | 2 ngày | P9 |
| | **Tổng** | **~40 ngày làm việc** | |

Ước lượng tính cho 1 người. Sales và Catalog lớn nhất, nên chia nhỏ PR.

## Cách làm việc: lên plan → làm → review

| Bước | Ai | Kết quả |
|---|---|---|
| **Plan** | Claude | File `docs/refactor/plans/<phase>/<mã việc>-<tên>.md`: mục tiêu, file sẽ sửa/tạo, từng bước, mã mẫu khi cần, cách kiểm tra, rủi ro. Bạn duyệt rồi mới làm |
| **Làm** | Bạn | Code theo plan trên branch `refactor/simple-arch` (hoặc branch con), commit |
| **Review** | Claude | Đọc diff so với plan và tài liệu TH, chạy analyze/test, ghi kết quả vào cuối file plan (mục "Review"); có góp ý thì bạn sửa rồi review lại |

**Đơn vị theo dõi là plan**, không phải từng việc nhỏ: mỗi phase có bảng **Plan** (mỗi plan khoảng 0,5–1,5 ngày, gom các việc phải làm cùng nhau; cột "Gồm việc" trỏ về bảng chi tiết bên dưới). Ký hiệu trong cột Plan / Làm / Review của bảng đó và dòng "Trạng thái" đầu mỗi phase:

| Cột | ⬜ | 📝 / 🔄 | ✅ | khác |
|---|---|---|---|---|
| Plan | chưa viết | 📝 đã viết, chờ bạn duyệt | đã duyệt | — không cần (việc làm thẳng) |
| Làm | chưa làm | 🔄 đang làm | xong, chờ review | ⏭ bỏ qua (ghi lý do) |
| Review | chưa review | 🔄 có góp ý, đang sửa | đạt | — không cần |

Một việc chỉ tính **xong** khi Review ✅. Ghi commit/PR vào bảng [Theo dõi tiến độ](#theo-dõi-tiến-độ).

Khi đã có file plan, cột **Plan** ghi trạng thái kèm link, ví dụ `📝 [plan](plans/P1/1.1-cau-truc-core.md)`.

### Quy tắc dọn module (chốt 2026-10-11)

Mỗi phase nghiệp vụ kết thúc bằng một plan **dọn sạch module** của nó (4-C, 3-C, 5-C, 7-5, 6-C — giống 8-C / 8-D của IAM), không để dồn tới P9:

1. App `erp` không còn import `vet45_<module>_*` — kể cả chỗ feature **khác** đang gọi chéo (đo 2026-10-11: `sales/presentation` gọi catalog 2, partner 1, pricing 2, einvoice 20; `pricing/presentation` gọi catalog 2, partner 1; `dashboard/presentation` gọi inventory 2).
2. Xoá thư mục module + mục workspace / DI / router / test liên quan.
3. DB của schema đó: bỏ outbox / inbox / RPC / bảng chỉ module cũ dùng — **sửa migration gốc** (quy tắc migration bên dưới).
4. Ràng buộc thứ tự: `modules/einvoice` phụ thuộc `partner/integration_events` và `sales/integration_events` → 4-C giữ `partner/integration_events` tới 7-5; 7-5 (einvoice) chạy trước 6-C (sales) theo thứ tự hiện tại nên không vướng. Package `vet45_adapters` / `vet45_annotations` / `vet45_generator` chỉ xoá được ở 6-C (module cuối).

### Quy tắc migration (chốt 2026-10-11)

**Sửa thẳng trong migration gốc, không tạo migration mới chỉ để ghi đè cái cũ.** Áp dụng cho mọi plan từ nay, cho tới khi Prod chạy thật (P10).

| Trường hợp | Làm thế nào |
|---|---|
| Sửa một hàm / trigger / view đã có | Sửa trong file migration chứa **định nghĩa mới nhất** của đối tượng đó (`grep -l "function iam.<tên>(" supabase/migrations/*.sql \| tail -1`) |
| Bỏ một đối tượng của luồng cũ | Xoá câu `create …` (và `grant`, trigger đi kèm) khỏi migration gốc; không viết `drop` ở migration mới |
| Bảng / cột / ràng buộc | Sửa câu `create table` / `alter table` gốc (vd thêm FK ngay chỗ tạo cột; xoá câu `drop constraint` đã gỡ nó) |
| Đối tượng **mới hoàn toàn** | Vẫn tạo migration mới (timestamp lớn nhất) |
| Migration chỉ còn là bản ghi đè rỗng sau khi gộp | Xoá file + dòng trong `REGISTRY.yaml` |

**Hệ quả bắt buộc:** Supabase chỉ chạy mỗi file một lần → sửa file **đã áp** thì Dev không tự nhận. Mỗi đợt có sửa migration đã áp: `supabase db reset --linked` trên Dev (xoá sạch DB Dev rồi chạy lại toàn bộ migration + `seed.sql`), sau đó `vet45 admin create` lại admin. Dev hiện gần như trống (0 tài khoản, chỉ dữ liệu seed — đo 2026-10-11) nên reset an toàn; **hỏi trước mỗi lần reset**. Prod chưa đụng tới — P10 dựng mới từ bộ migration cuối. **Sau khi Prod chạy thật, quay lại quy tắc cũ** (chỉ thêm migration mới).

### Danh sách plan

| Việc | File plan | Plan | Làm | Review |
|---|---|---|---|---|
| 1.1 Cấu trúc thư mục `core/` | [plans/P1/1.1-cau-truc-core.md](plans/P1/1.1-cau-truc-core.md) | ✅ | ✅ | ✅ |
| 1-A `AppException`, `SupabaseRpc`, feature mẫu, kiểm import | [plans/P1/1-A-app-exception-feature-mau.md](plans/P1/1-A-app-exception-feature-mau.md) | ✅ | ✅ | ✅ |
| 1-B `SessionController` + router guard | [plans/P1/1-B-session-controller-guard.md](plans/P1/1-B-session-controller-guard.md) | ✅ | ✅ | ✅ |
| 2-A1 IAM: tài khoản, hồ sơ tổ chức, đặt lại mật khẩu | [plans/P2/2-A1-iam-tai-khoan-to-chuc.md](plans/P2/2-A1-iam-tai-khoan-to-chuc.md) | ✅ | ✅ | ✅ |
| 2-A2 IAM: thành viên, lời mời, vai trò, nhật ký | [plans/P2/2-A2-iam-thanh-vien-loi-moi-nhat-ky.md](plans/P2/2-A2-iam-thanh-vien-loi-moi-nhat-ky.md) | ✅ | ✅ | ✅ |
| 2-A3 Phiên, đăng nhập, nhận lời mời | [plans/P2/2-A3-phien-dang-nhap-loi-moi.md](plans/P2/2-A3-phien-dang-nhap-loi-moi.md) | ✅ | ✅ | ✅ |
| 2-B1 Đăng ký cửa hàng, xác minh email, định tuyến | [plans/P2/2-B1-dang-ky-cua-hang.md](plans/P2/2-B1-dang-ky-cua-hang.md) | ✅ | ✅ | 🔄 |
| 2-B2 Email qua Edge Function | [plans/P2/2-B2-email-edge-function.md](plans/P2/2-B2-email-edge-function.md) | ✅ | ✅ | 🔄 |
| 2-B3 Sửa KI của IAM, bỏ readiness | [plans/P2/2-B3-iam-sua-ki.md](plans/P2/2-B3-iam-sua-ki.md) | ✅ | ✅ | 🔄 |
| 2-B4 Hoàn thiện IAM sau rà soát | [plans/P2/2-B4-iam-hoan-thien.md](plans/P2/2-B4-iam-hoan-thien.md) | ✅ | ✅ | ✅ |
| 8-A Quản trị tổ chức (app) | [plans/P8/8-A-quan-tri-to-chuc.md](plans/P8/8-A-quan-tri-to-chuc.md) | ✅ | ✅ | ✅ |
| 8-C App bỏ phụ thuộc IAM cũ | [plans/P8/8-C-thay-iam-cu-bang-core.md](plans/P8/8-C-thay-iam-cu-bang-core.md) | ✅ | ✅ | ✅ |
| 8-D Xoá modules/iam, apps/admin, worker | [plans/P8/8-D-xoa-iam-cu.md](plans/P8/8-D-xoa-iam-cu.md) | ✅ | ✅ | ✅ |
| 8-B DB: KI-08, dọn luồng cũ, KI-03 | [plans/P8/8-B-db-ki08-don-luong-cu.md](plans/P8/8-B-db-ki08-don-luong-cu.md) | 📝 | 🔄 | ⬜ |


---

## Cách chuyển MỘT feature (công thức dùng cho P2–P8)

Hiện tại:

```text
Page ─▶ Cubit ─▶ IXxxModule.executeCommandAsync(XCommand) ─▶ Handler ─▶ Aggregate/Rule ─▶ Gateway ─▶ SchemaRpcClient ─▶ supabase.schema('x').rpc('fn')
```

Sau refactor:

```text
Page ─▶ Cubit ─▶ XxxRepository.method() ─▶ supabase.schema('x').rpc('fn')
```

**8 bước cho mỗi feature:**

1. **Liệt kê**: grep `executeCommandAsync|executeQueryAsync` trong `apps/erp/lib/features/<x>` để ra danh sách Command/Query mà UI đang dùng.
2. **Truy vết**: với mỗi Command/Query, đi theo Handler → Gateway để ghi lại **tên RPC, tham số, cách map kết quả**.
3. **Model**: tạo `features/<x>/data/models/`. Chuyển DTO đang dùng (từ `modules/<x>/application`) sang và giữ nguyên tên field để UI không phải sửa.
4. **Repository**: tạo `features/<x>/data/<x>_repository.dart`, mỗi Command/Query thành 1 method gọi **đúng RPC cũ**. Lỗi RPC (`raise exception 'CODE'`) được map sang `AppException(code)` dùng chung.
5. **Rule nghiệp vụ**: rule kiểm tra ở Aggregate/Handler (ví dụ MST, giá ≥ 0, số lượng > 0) chuyển thành hàm thuần trong `features/<x>/logic/<x>_rules.dart`. Test domain cũ được giữ lại bằng cách trỏ sang hàm mới.
6. **Đổi Cubit**: thay `IXxxModule` bằng `XxxRepository` trong constructor. Thay `executeXAsync(Command(...))` bằng `repo.method(...)`. Cubit chuyển từ `presentation/bloc/` sang `logic/`.
7. **DI và Router**: đăng ký repository trong `core/di`; route truyền repository thay cho module.
8. **Kiểm tra**: `dart analyze` sạch, test cubit/repository chạy qua, tự bấm hết màn hình của feature trong checklist P0. Sau đó mở PR.

**Quy tắc khi làm:**
- **Tách hai bước, hai PR** (chốt 2026-10-08):
  - **(a) Chuyển kiến trúc**: không đổi hành vi, không sửa UI ngoài import/dependency, không sửa RPC.
  - **(b) Sửa theo tài liệu TH**: các mục 🔧 / 🆕 của theme đó (UI, RPC bằng migration mới, Edge Function). Mỗi mục có plan riêng.
  - Làm (a) trước (b). Có lỗi thì biết ngay do chuyển kiến trúc hay do sửa nghiệp vụ.
- Module cũ **vẫn chạy song song** tới P9: feature nào chưa chuyển thì vẫn dùng module.
- Theo `CLAUDE.md`: chạy GitNexus `impact` trước khi sửa symbol, và `detect_changes` trước khi commit.
- Mỗi feature (hoặc nhóm màn hình lớn) là **1 PR vào `refactor/simple-arch`**.

---

## P0. Chuẩn bị (0,5 ngày)

**Trạng thái:** ✅ Xong (2026-10-08)

| Plan | Nội dung | Gồm việc | Plan | Làm | Review |
|---|---|---|---|---|---|
| **0** | Chuẩn bị | 0.1–0.6 | — | ✅ | — |

Chi tiết từng việc:

| # | Việc | Kết quả |
|---|---|---|
| 0.1 | `git checkout refactor/simple-arch` (mang theo 51 thay đổi đang dở) | Đứng trên branch refactor |
| 0.2 | Commit việc dở thành các nhóm: ① bỏ Railway/CircleCI/GitLab, ② đổi bundle id iOS/Android, ③ docs vận hành, ④ `docs/refactor/` (SCOPE + PLAN) | Thư mục làm việc sạch |
| 0.3 | Tag mốc `v-legacy-arch` tại commit đầu branch và push | Luôn quay lại được bản cũ |
| 0.4 | Chạy app bản cũ trên Supabase local và lập **checklist màn hình** `docs/refactor/CHECKLIST.md`: mỗi màn 1 dòng (route, thao tác chính, ☐ đã kiểm tra sau refactor) | Danh sách nghiệm thu 119 dòng. Cột "Cũ" ⏭ bỏ qua theo quyết định 2026-10-08 |
| 0.5 | Chạy toàn bộ test hiện có và ghi lại số pass/fail làm mốc | Biết test nào vốn đã fail |
| 0.6 | Chuyển tài liệu / rule / skill của kiến trúc cũ vào `docs/_legacy/`; viết lại `AGENTS.md` và rule Cursor theo kiến trúc mới | AI agent không viết code theo kiểu cũ |

**Xong khi:** branch sạch, có tag, có checklist và mốc test.

---

## P1. Nền `core/` (2 ngày)

**Trạng thái:** ✅ Xong code, merge `7c455c6a7` (2026-10-08) — còn kiểm tay trên Dev theo plan 1-B mục 5

| Plan | Nội dung | Gồm việc | Plan | Làm | Review |
|---|---|---|---|---|---|
| **1.1** | Cấu trúc thư mục `core/` | 1.1 | ✅ [plan](plans/P1/1.1-cau-truc-core.md) | ✅ | ✅ |
| **1-A** | `AppException` + bộ dịch lỗi, feature mẫu `partner_change_history`, lint ranh giới feature | 1.2, 1.5, 1.6 | ✅ [plan](plans/P1/1-A-app-exception-feature-mau.md) | ✅ | ✅ |
| **1-B** | `SessionController` + router guard (3 nhánh hiện có; 3 nhánh mới làm ở 2-B1 / P8) | 1.3, 1.4 | ✅ [plan](plans/P1/1-B-session-controller-guard.md) | ✅ | ✅ |

Chi tiết từng việc:

| # | Việc | Chi tiết |
|---|---|---|
| 1.1 | Cấu trúc thư mục | Dời `lib/configurations/` → `lib/core/config/` trên `refactor/p1-core` |
| 1.2 | `AppException` + bộ map lỗi | Một lớp lỗi chung, map từ `PostgrestException.message` (mã `PERMISSION_DENIED`, `VALIDATION_ERROR`…) sang thông báo tiếng Việt. Gộp từ `exception_mapper.dart` và các `IamBlockedCodes` |
| 1.3 | `SessionController` | Giữ: user hiện tại, có phải platform admin không, danh sách membership, tenant/store đang chọn. Thay cho `ICurrentUser` + `TenantContextCubit` + session port của module |
| 1.4 | Router guard | Viết lại `redirect` theo **bảng định tuyến ở SCOPE 3.5**: chưa đăng nhập, chưa xác minh, platform admin, không có tổ chức, tenant bị chặn, tenant active |
| 1.5 | Feature mẫu | Làm **trước 1 feature nhỏ**: `partner_change_history` (1 query, 1 cubit) theo đủ 8 bước, để làm mẫu cho cả nhóm |
| 1.6 | Lint | Script `tool/check_feature_imports.dart` kiểm 3 luật phụ thuộc của SCOPE 3.1 cho tầng `data/`, `logic/` (feature khác chỉ dùng repository của nhau) |

**Xong khi:** app chạy như cũ; feature mẫu chạy qua repository; guard là hàm thuần có test (3 nhánh hiện có, 3 nhánh mới của TH-01 2.3 thêm ở 2-B1 / P8); có test cho `SessionController` và guard.

---

## P2. Auth, đăng ký cửa hàng, IAM (5 ngày)

**Trạng thái:** 🔄 Đang làm

| Plan | Nội dung | Gồm việc | Plan | Làm | Review |
|---|---|---|---|---|---|
| **2-A1** | (a) IAM: tài khoản của tôi, hồ sơ tổ chức, hồ sơ pháp lý, quên mật khẩu | 2B.6 (một phần) | ✅ [plan](plans/P2/2-A1-iam-tai-khoan-to-chuc.md) | ✅ | ✅ |
| **2-A2** | (a) IAM: thành viên, vai trò, lời mời (quản trị), nhật ký quản trị, hub "Người dùng & vai trò" | 2B.6 (phần còn lại) | ✅ [plan](plans/P2/2-A2-iam-thanh-vien-loi-moi-nhat-ky.md) | ✅ | ✅ |
| **2-A3** | (a) Phiên & đăng nhập: `SessionController` gọi RPC trực tiếp (`get_tenant_context`, `list_accessible_tenants`, `switch_tenant_context`, `user_preferences`) và tự cập nhật `IamSession`; `LoginCubit`, đăng xuất, nhập mã lời mời `/invitation` (`InvitationAcceptanceCubit`); xử lý 2 góp ý review 1-B (`core` import `features`, reset state khi đổi người dùng) | 2B.5, 1-B góp ý | ✅ [plan](plans/P2/2-A3-phien-dang-nhap-loi-moi.md) | ✅ | ✅ |
| **2-B1** | (b) Đăng ký cửa hàng mới: trigger DB, cấu hình OTP, `/login`, `/signup`, `/verify-email`, `/no-organization`, banner hồ sơ pháp lý; thêm nhánh guard "chưa xác minh", "không có tổ chức", chọn tổ chức hoạt động đầu tiên | 2A.1, 2A.2, 2A.3, 2B.1, 2B.2, 2B.3, 2B.4, 2B.7 | ✅ [plan](plans/P2/2-B1-dang-ky-cua-hang.md) | ✅ | 🔄 |
| **2-B2** | (b) Email qua Edge Function `send-email`: `iam.email_jobs`, `enqueue_outbox_message` chuyển email sang job, `pg_net` + `pg_cron`, Resend | 2A.4 | ✅ [plan](plans/P2/2-B2-email-edge-function.md) | ✅ | 🔄 |
| **2-B3** | (b) Sửa KI của TH-01: KI-02 (`accept_invitation` kích hoạt lại thành viên đã loại), KI-06, KI-10…KI-14, phần app của KI-05 (bỏ readiness cửa hàng). KI-03 và KI-05 DB/platform dời P8 | TH-01 mục 9.2 | ✅ [plan](plans/P2/2-B3-iam-sua-ki.md) | ✅ | 🔄 |
| **2-B4** | (b) Hoàn thiện sau rà soát TH-01: mất quyền khi đang dùng → tải lại phiên; đổi mật khẩu xong đăng xuất; câu lời mời tổ chức tạm ngừng; đăng ký lại cùng email (A3); đếm ngược gửi lại (A4) | Rà soát 2026-10-10 | ✅ [plan](plans/P2/2-B4-iam-hoan-thien.md) | ✅ | ✅ |

Chi tiết từng việc:

### 2A. Database (làm trước)

| # | Migration mới | Nội dung |
|---|---|---|
| 2A.1 | `iam_create_tenant_for_owner.sql` | Hàm nội bộ `iam._create_tenant_for_owner(user_id, payload jsonb)`: tạo tenant `active`, Owner, cửa hàng mặc định, `last_selected_tenant_id`, audit. Có kiểm tra **mỗi user tối đa 1 tổ chức sở hữu** |
| 2A.2 | `iam_on_auth_user_confirmed.sql` | Trigger trên `auth.users` khi `email_confirmed_at` chuyển từ null sang có giá trị (và khi insert đã xác minh sẵn): tạo profile `active`, có `signup_tenant` thì gọi 2A.1, rồi xoá `signup_tenant` khỏi metadata |
| 2A.3 | Cấu hình Auth | `supabase/config.toml`: bật xác minh email (`enable_confirmations = true`), dùng **OTP 6 số** (template email đổi `{{ .ConfirmationURL }}` thành `{{ .Token }}`), `max_frequency = "1m0s"`, `site_url` / `additional_redirect_urls` theo deep link của app. Đẩy lên **Dev và Prod** bằng `supabase config push` (lệnh này áp ngay, không hỏi lại). Hiện Dev đang tắt xác nhận email, 1 giây/lần gửi để khớp app cũ (2026-10-07) |
| 2A.4 | Email qua Edge Function | Tạo `supabase/functions/send-email` (Resend), bảng `iam.email_jobs` và Database Webhook. Sửa RPC lời mời / reset mật khẩu: ghi `email_jobs` thay cho `enqueue_outbox_message` |

### 2B. Màn hình

| # | Màn | Ghi chú |
|---|---|---|
| 2B.1 | `/login` | Giữ màn cũ (đã có "Bạn đã nhận được lời mời? → Kích hoạt tài khoản"), thêm nút **Đăng ký cửa hàng mới**. Gộp `sign_in_platform_admin` và `sign_in_tenant_user` thành 1 |
| 2B.2 | `/signup` (mới) | Wizard 3 bước: Tài khoản → Cửa hàng → Xác minh email |
| 2B.3 | `/verify-email` (mới) | Nhập mã, gửi lại mã. Dùng cả cho trường hợp đăng nhập mà email chưa xác minh |
| 2B.4 | `/no-organization` (mới) | "Bạn chưa thuộc tổ chức nào" + Nhập mã lời mời + Đăng xuất |
| 2B.5 | `/invitation` | Giữ luồng lời mời nhân viên, chuyển sang repository |
| 2B.6 | IAM trong app (khoảng 20 màn) | Tài khoản của tôi, hồ sơ tổ chức, hồ sơ pháp lý, thành viên, vai trò, lời mời, audit log, quên mật khẩu: chuyển theo công thức 8 bước. **Bỏ** `tenant_readiness_page` và route `/more/readiness` |
| 2B.7 | Banner | Banner "Bổ sung hồ sơ pháp lý" ở trang chủ khi chưa có MST |

**Repository:** `AuthRepository` (signIn, signUp, verifyOtp, resend, signOut, resetPassword), `OrganizationRepository`, `MemberRepository`, `InvitationRepository`, `AuditLogRepository`.

Đặc tả chi tiết (chuỗi UI, quy tắc, sửa lỗi KI-02…KI-14, kịch bản kiểm thử): [TH-01 v4.0](../02-yeu-cau/TH-01-to-chuc-va-nguoi-dung.md) mục 4, 9.2, 9.3.

**Xong khi:**
- Từ `db reset`: đăng ký → nhập mã → vào trang chủ có cửa hàng mặc định.
- Bỏ dở ở bước nhập mã, đăng nhập lại sẽ tới `/verify-email`; xác minh xong vẫn có cửa hàng.
- Owner mời nhân viên, nhân viên nhận mã, tham gia và thấy đúng quyền.
- Không có nút nào tạo tổ chức sau khi đăng nhập.
- Các màn IAM trong checklist đều đã tick.

---

## P3. Catalog + Inventory (5 ngày)

**Trạng thái:** ⬜ Chưa làm

| Plan | Nội dung | Gồm việc | Plan | Làm | Review |
|---|---|---|---|---|---|
| **3-A1** | (a) Sản phẩm cốt lõi | 3.1 | ⬜ | ⬜ | ⬜ |
| **3-A2** | (a) Đơn vị tính + trường tùy chỉnh | 3.2, 3.3 | ⬜ | ⬜ | ⬜ |
| **3-A3** | (a) Giá trong catalog | 3.4 | ⬜ | ⬜ | ⬜ |
| **3-A4** | (a) Inventory | 3.5 | ⬜ | ⬜ | ⬜ |
| **3-B** | (b) Các sửa KI của TH-02 | TH-02 mục 9.2 | ⬜ | ⬜ | ⬜ |
| **3-C** | (dọn) **Dọn sạch module catalog + inventory**: app hết `vet45_catalog_*`, `vet45_inventory_*` (kể cả 2 chỗ ở `sales/presentation`, 2 ở `pricing/presentation`, 2 ở `dashboard/presentation`); xoá `modules/catalog`, `modules/inventory`; DB schema `catalog`, `inventory`: bỏ outbox / inbox / RPC cũ không còn dùng (sửa migration gốc) | Dọn module (2026-10-11) | ⬜ | ⬜ | ⬜ |

Chi tiết từng việc:

ERP hiện có **18 file** gọi module catalog, **15 cubit**, **23 màn**. Chia thành 4 PR:

| PR | Nhóm | Màn chính |
|---|---|---|
| 3.1 | Sản phẩm cốt lõi | Danh sách/tab sản phẩm, control center, tạo nhanh/guided, sửa hồ sơ, ảnh, vô hiệu/khôi phục/xoá, lịch sử thay đổi, readiness sản phẩm |
| 3.2 | Đơn vị tính | ĐVT tenant, ĐVT sản phẩm, quy đổi |
| 3.3 | Trường tuỳ chỉnh | Nhóm, field, giá trị, sắp xếp |
| 3.4 | Giá trong catalog | Giá gốc thủ công, khung giá theo đơn vị, quy tắc giá cửa hàng + lịch sử |
| 3.5 | **Inventory** | Chuyển điều chỉnh tồn và lịch sử tồn từ catalog sang `features/inventory/`. Giữ **cổng cửa hàng/kho mặc định** (theme7) qua `InventoryRepository` |

Repository: `ProductRepository`, `MeasurementUnitRepository`, `CustomFieldRepository`, `ProductPriceRepository`, `InventoryRepository`.
Riêng tìm sản phẩm bán được / quét barcode (`search_sellable_products`, `resolve_sellable_barcode`): đặt trong `ProductRepository` để P6 Sales dùng lại.

Các sửa lỗi kèm theo từng PR: xem [TH-02 mục 9.2](../02-yeu-cau/TH-02-san-pham-va-gia-ban.md#92-theo-pr-của-p3) (KI-01…KI-18). Riêng kiểm đơn vị đã bán khi xoá (TH-02 KI-08) làm ở P6 PR 6.1.

**Xong khi:** các màn catalog và inventory trong checklist đều đã tick; 5 kịch bản đầu–cuối và test RPC ở TH-02 mục 9.3 chạy qua.

---

## P4. Partner (2 ngày)

**Trạng thái:** ⬜ Chưa làm

| Plan | Nội dung | Gồm việc | Plan | Làm | Review |
|---|---|---|---|---|---|
| **4-A** | (a) Chuyển partner + rule MST dùng chung | 4.1, 4.2 | ⬜ | ⬜ | ⬜ |
| **4-B** | (b) Trigger lịch sử giao dịch đối tác + các sửa KI của TH-03 | 4.3, TH-03 mục 9.2 | ⬜ | ⬜ | ⬜ |
| **4-C** | (dọn) **Dọn sạch module partner**: app hết `vet45_partner_*` (kể cả 1 chỗ ở `sales/presentation`, 1 ở `pricing/presentation`, router, DI); xoá `modules/partner/{domain,application,infrastructure}` — **giữ `modules/partner/integration_events` tới 7-5** (einvoice phụ thuộc); DB schema `partner`: bỏ outbox / inbox / RPC cũ không còn dùng (sửa migration gốc). Kèm: xoá 3 module rỗng `accounting`, `costing`, `dashboard` (erp không dùng), `packages/vet45_resend` (chỉ worker dùng), kiểm `apps/erp/example` | Dọn module (2026-10-11) | ⬜ | ⬜ | ⬜ |

Chi tiết từng việc:

11 file gọi module, 8 cubit, 8 màn: danh sách, tạo, chi tiết, sửa, chuyển cá nhân → tổ chức, liên hệ, lịch sử.

| # | Việc |
|---|---|
| 4.1 | `PartnerRepository` (search, detail, create, update, transform, contacts, deactivate/reactivate/soft-delete, check duplicate) |
| 4.2 | Rule MST (10/12/10-3) dùng chung với IAM: chuyển vào `core/validation/tax_code.dart` |
| 4.3 | **Trigger DB ghi lịch sử giao dịch đối tác**: trigger trên `sales.sales_orders` gọi `partner.upsert_partner_history` (TH-03 KI-02). `partner_action_logs` đã được ghi trong RPC, giữ nguyên |

Chia PR và các sửa lỗi đi kèm (KI-02…KI-13): xem [TH-03 mục 9.2](../02-yeu-cau/TH-03-doi-tac-giao-dich.md#92-chia-pr-của-p4).

**Xong khi:** 8 màn đã tick; tạo đơn bán cho khách thì khách đó không còn xoá được (`HAS_TRANSACTIONS`); 5 kịch bản đầu–cuối ở TH-03 mục 9.3 chạy qua.

---

## P5. Pricing (2 ngày)

**Trạng thái:** ⬜ Chưa làm

| Plan | Nội dung | Gồm việc | Plan | Làm | Review |
|---|---|---|---|---|---|
| **5-A** | (a) Chuyển pricing (giá riêng, nhập Excel, màn chọn) | 5.1, 5.2, 5.3 | ⬜ | ⬜ | ⬜ |
| **5-B** | (b) Các sửa KI của TH-04 | TH-04 mục 9.2 | ⬜ | ⬜ | ⬜ |
| **5-C** | (dọn) **Dọn sạch module pricing**: app hết `vet45_pricing_*` (kể cả 2 chỗ ở `sales/presentation`); xoá `modules/pricing`; DB schema `pricing`: bỏ RPC cũ không còn dùng (sửa migration gốc) | Dọn module (2026-10-11) | ⬜ | ⬜ | ⬜ |

Chi tiết từng việc:

9 file gọi module, 5 cubit, 9 màn: danh sách, form, chi tiết, lịch sử, import, các màn chọn (sản phẩm/khách/đơn vị).

| # | Việc |
|---|---|
| 5.1 | `CustomerPriceRuleRepository` (CRUD, tắt/bật, lịch sử, resolve áp dụng) |
| 5.2 | `PriceImportRepository` (template, start/confirm/cancel import) |
| 5.3 | Màn chọn sản phẩm/khách dùng lại `ProductRepository` (P3) và `PartnerRepository` (P4) |

Chia PR và các sửa lỗi đi kèm (KI-02…KI-15): xem [TH-04 mục 9.2](../02-yeu-cau/TH-04-chinh-sach-gia.md#92-chia-pr-của-p5).

**Xong khi:** 9 màn đã tick; import Excel mẫu chạy được từ đầu tới cuối; 5 kịch bản đầu–cuối ở TH-04 mục 9.3 chạy qua.

---

## P6. Sales (6 ngày, phần lớn nhất)

**Trạng thái:** ⬜ Chưa làm

| Plan | Nội dung | Gồm việc | Plan | Làm | Review |
|---|---|---|---|---|---|
| **6-A1** | (a) Soạn đơn + nháp | 6.1 | ⬜ | ⬜ | ⬜ |
| **6-A2** | (a) Checkout + thanh toán | 6.2 | ⬜ | ⬜ | ⬜ |
| **6-A3** | (a) Tra cứu đơn + phiếu/biên lai | 6.3, 6.4 | ⬜ | ⬜ | ⬜ |
| **6-A4** | (a) Huỷ đơn + đổi/trả | 6.5 | ⬜ | ⬜ | ⬜ |
| **6-B** | (b) Các sửa KI của TH-05 | TH-05 mục 9.2 | ⬜ | ⬜ | ⬜ |
| **6-C** | (dọn) **Dọn sạch module sales — module cuối**: app hết `vet45_sales_*`; xoá `modules/sales` → thư mục `modules/` **trống, xoá hẳn**; xoá `packages/vet45_adapters`, `vet45_annotations`, `vet45_generator` (chỉ module dùng); bỏ `CoreExecutionContext` / `CorePermissionChecker` / `CoreTenantAccessChecker` trong `core/session` (chỉ phục vụ module cũ); DB schema `sales`: bỏ outbox / inbox | Dọn module (2026-10-11) | ⬜ | ⬜ | ⬜ |

Chi tiết từng việc:

20 file gọi module, 13 cubit, khoảng 20 màn. Chia thành 5 PR:

| PR | Nhóm | RPC/Query chính |
|---|---|---|
| 6.1 | Soạn đơn + nháp | save/update/cancel draft, list drafts, restore; preview pricing (gọi pricing). Sửa `catalog._product_unit_has_sales_transaction_usage` đọc dòng đơn / nháp / đổi trả (TH-02 KI-08) |
| 6.2 | Checkout + thanh toán | precheck checkout, **finalize_sales_order** (transaction ở DB), record payment/refund, settlement, payment summary |
| 6.3 | Tra cứu đơn | list/search/detail/timeline, post-sale actions |
| 6.4 | Phiếu/biên lai | generate/get receipt, original receipt, printed/shared, slip preview |
| 6.5 | Huỷ đơn + đổi/trả | cancellation (lý do, precheck, confirm); return/exchange (start, preview pricing, update, confirm, complete, cancel) |

**Integration event:** bỏ outbox. Phát hành HĐĐT tự động dùng trigger trên `sales.sales_orders` khi đơn Hoàn tất, ghi việc vào `einvoice.internal_commands` (làm ở P7.5; TH-08 KI-19, KI-20). Không gọi "nhớ giá từ đơn" (ngoài phạm vi, TH-04 KI-02). Trừ/cộng tồn khi bán, huỷ, đổi trả **không** làm ở P6: thuộc Theme 7 (P11, `BC-IO-04`, `BC-IO-07`, `BC-IO-13`).

**Xong khi:** đủ 6 kịch bản: bán thường, bán nợ rồi thu sau, hoàn tiền, huỷ đơn, đổi hàng, trả hàng. Công nợ (còn phải thu của đơn) đúng sau mỗi kịch bản. Tồn kho kiểm ở P11 (Theme 7). Các màn sales trong checklist đều đã tick.

---

## P7. E-invoice (8 ngày)

**Trạng thái:** ⬜ Chưa làm

| Plan | Nội dung | Gồm việc | Plan | Làm | Review |
|---|---|---|---|---|---|
| **7-1** | DB: promote drafts HĐĐT + sửa KI-02, 04, 06 | 7.1 | ⬜ | ⬜ | ⬜ |
| **7-2** | Dời toàn bộ UI HĐĐT (thiết lập + trên đơn), gộp bản trùng, `EInvoiceRepository` | 7.2, 7.3 | ⬜ | ⬜ | ⬜ |
| **7-3** | Edge Function `einvoice-processor` + client MISA TypeScript | 7.4 | ⬜ | ⬜ | ⬜ |
| **7-4** | Kích hoạt: `pg_cron`, `functions.invoke`, trigger thay outbox/inbox | 7.5 | ⬜ | ⬜ | ⬜ |
| **7-5** | (dọn) **Dọn sạch module einvoice**: app hết `vet45_einvoice_*` (20 file ở `sales/presentation` đã chuyển ở 7-2); xoá `modules/einvoice` (gồm `presentation` + `example`), `packages/vet45_misa` (thay bằng client TypeScript 7-3), `packages/vet45_async_query`, `modules/partner/integration_events` (hết người dùng); DB schema `einvoice`: bỏ outbox / inbox, **giữ `internal_commands`** | Dọn module (2026-10-11) | ⬜ | ⬜ | ⬜ |

Chi tiết từng việc:

Đặc tả: [TH-08](../02-yeu-cau/TH-08-hoa-don-dien-tu.md). Chia PR theo [TH-08 mục 9.2](../02-yeu-cau/TH-08-hoa-don-dien-tu.md#92-chia-pr-của-p7). Quyết định 2026-10-07: **giữ hành vi hiện có** (hàng đợi, đối soát nền, phát hành và gửi tự động, chống trùng) nhưng **bỏ `apps/messaging_worker`**: mọi lệnh gọi MISA chuyển sang Edge Function `einvoice-processor` (TypeScript), kích hoạt bởi app và `pg_cron` mỗi 30 giây (TH-08 KI-20). UI e-invoice hiện tách giữa `modules/einvoice/presentation` và bản sao trong `features/sales` (KI-17).

| # | Việc |
|---|---|
| 7.1 | **DB**: promote 23 file `supabase/migrations/_drafts/001…023` thành migration chính thức; sửa `update_automation_policy` (KI-02), kiểm người mua trong `issue_invoice` / `retry_issuance` / `start_auto_issuance` (KI-04), chép lại trường người mua mỗi lượt (KI-06) |
| 7.2 | **Thiết lập**: chuyển 4 màn vào `apps/erp/lib/features/einvoice/presentation`; `EInvoiceRepository` (kết nối, mẫu, chính sách, sẵn sàng) gọi RPC `einvoice`; KI-01, 15, 16 |
| 7.3 | **Trên đơn** (làm trước P6: gắn vào màn chi tiết đơn **cũ**, P6 giữ nguyên widget khi chuyển màn): `OrderEInvoiceSection` + 2 cubit dùng repository; gộp các sheet về một chỗ; hỏi lại trạng thái bằng `Timer` trong cubit (bỏ `vet45_async_query`, giữ hành vi); KI-08, 17 |
| 7.4 | **Edge Function `einvoice-processor`**: viết lại client MISA bằng TypeScript (theo `packages/vet45_misa`, chép 80 test sang Deno) và handler cho 9 loại lệnh `internal_commands` (đồng bộ mẫu, xem trước, phát hành + khóa ký hiệu, đối soát, bản chính thức, tải tài liệu, quan sát, gửi email, đối soát gửi) |
| 7.5 | **Kích hoạt**: `pg_cron` + `pg_net` gọi Edge Function mỗi 30 giây; app gọi `functions.invoke` sau mỗi RPC ghi yêu cầu; trigger khi đơn Hoàn tất và khi hồ sơ khách đổi ghi thẳng `internal_commands` (thay outbox/inbox); `record_issuance_success` tự xếp việc gửi tự động (KI-19, KI-20) |

**Xong khi:** với worker **đã tắt**: kết nối MISA sandbox → phát hành từ đơn → xem/tải PDF → gửi email → gửi lại → phát hành lại sau lỗi; tự phát hành + tự gửi chạy khi bật, kể cả khi app đã đóng; MISA timeout thì `pg_cron` đối soát ra đúng một hóa đơn (TH-08 mục 9.3).

---

## P8. Quản trị tổ chức cho Platform Admin (2 ngày, làm song song được từ sau P2)

> Phương án A (chốt 2026-10-09): không có khu `/admin`; nhóm "Quản trị nền tảng" cuối tab **Thêm**. Màn và khung: [ADMIN-SCREENS.md](ADMIN-SCREENS.md); đặc tả: TH-01 EP-09 (US-09.2…09.4), ID-31…ID-33.

**Trạng thái:** ⬜ Chưa làm

| Plan | Nội dung | Gồm việc | Plan | Làm | Review |
|---|---|---|---|---|---|
| **8-A** | (app) Quản trị tổ chức trong tab Thêm: `isPlatformAdmin`, guard G7, repository + cubit, màn C1–C6, lối vào ở tab Thêm và `/no-organization`, admin mẫu | 8.1, 8.2, 8.3, 8.5 | ✅ [plan](plans/P8/8-A-quan-tri-to-chuc.md) | ✅ | ✅ |
| **8-C** | (app) App không còn phụ thuộc `vet45_iam_*`: hằng số / DTO sang core, `SessionStore` + 4 lớp contract thay `IamSession` / `IamStartup`, Sales bỏ `IIamModule`, viết lại 27 test | Làm gọn IAM (2026-10-11) | ✅ [plan](plans/P8/8-C-thay-iam-cu-bang-core.md) | ✅ | ✅ |
| **8-D** | Xoá `modules/iam`, `apps/admin`, `apps/messaging_worker` + workspace / CI / script | Làm gọn IAM; kéo 9.1 lên | ✅ [plan](plans/P8/8-D-xoa-iam-cu.md) | ✅ | ✅ |
| **8-B** | (DB, sau 8-D, cùng đợt kiểm IAM) KI-08 chặn chuyển Owner cho người đã là Owner nơi khác; dọn onboarding / `provisioning` / `pending_activation`; FK `memberships.user_id` (KI-03) | 8.4, 8.6 | 📝 [chi tiết](plans/P8/8-B-db-ki08-don-luong-cu.md) | 🔄 code xong, chờ kiểm trên DB sạch | ⬜ |

Chi tiết từng việc:

| # | Việc |
|---|---|
| 8.1 | `features/platform_admin/` (data / logic / presentation); `SessionController.isPlatformAdmin`; guard: `/more/platform/**` chỉ cho Platform Admin |
| 8.2 | Chuyển từ `apps/admin`: danh sách tổ chức (ID-31), chi tiết (ID-32), sheet Thao tác + xác nhận tạm ngừng / khôi phục / đóng, thay đổi chủ sở hữu (ID-33) + xác nhận |
| 8.3 | Điểm vào: nhóm "Quản trị nền tảng" cuối tab Thêm; nút "Quản trị nền tảng" trên `/no-organization` (admin chưa có cửa hàng) |
| 8.4 | KI-08: `transfer_platform_tenant_ownership` chặn người nhận đã là Owner tổ chức khác (BR-32) |
| 8.5 | Tạo platform admin bằng `vet45 admin create --email …` (đã có trong `tools/vet45_env`, không viết script mới) + admin mẫu trong `seed.sql` cho local; ghi cách dùng vào README |
| 8.6 | KI-03 FK `memberships.user_id`; xoá onboarding cũ, owner activation, readiness RPC, trạng thái `provisioning` / `pending_activation` (dời từ 2-B3) |

**Không chuyển** từ `apps/admin`: wizard khởi tạo (`platform_onboarding_page`), "gửi lại email thiết lập / lời mời owner", "gửi lại kích hoạt", tổng quan, người dùng nền tảng, nhật ký nền tảng, khung 5 tab, "Chuyển không gian".

**Xong khi:** Platform Admin đăng nhập, mở Thêm ▸ Quản trị nền tảng ▸ Tổ chức, thấy tổ chức vừa đăng ký ở P2, tạm ngừng được (Owner thấy ID-09), khôi phục được, chuyển Owner được; người thường không thấy mục này và gõ route thì bị chặn.

---

## P9. Dọn dẹp (3 ngày)

**Trạng thái:** ⬜ Chưa làm

| Plan | Nội dung | Gồm việc | Plan | Làm | Review |
|---|---|---|---|---|---|
| **9-1** | Dọn code: gộp phần còn dùng của `vet45_shared` vào `core/` rồi xoá; bỏ Melos; gọn `vet45_env` (module / app / package cũ đã xoá ở 8-D, 4-C, 3-C, 5-C, 7-5, 6-C) | 9.1, 9.2, 9.3, 9.6 | ⬜ | ⬜ | ⬜ |
| **9-2** | Dọn DB: bỏ outbox/inbox/onboarding, gộp migration baseline | 9.4, 9.5 | ⬜ | ⬜ | ⬜ |

Chi tiết từng việc:

| # | Việc | Kiểm tra |
|---|---|---|
| 9.1 | Kiểm **không còn** `modules/`, `apps/admin`, `apps/messaging_worker` (xoá dần: 8-D IAM / admin / worker; 4-C partner + 3 module rỗng; 3-C catalog, inventory; 5-C pricing; 7-5 einvoice; 6-C sales) | `grep -r "vet45_.*_application"` không còn kết quả |
| 9.2 | Gộp phần còn dùng của `vet45_shared` (`ApplicationException`, `TenantAccessRevokedSignal`…) vào `core/` rồi xoá `packages/vet45_shared` (các package khác đã xoá ở 4-C, 7-5, 6-C) | `flutter pub get` OK |
| 9.3 | Bỏ Melos, `pubspec.yaml` gốc chỉ còn workspace nhỏ (`apps/erp`, `packages/vet45_design_system`, `tools/vet45_env`). Lệnh `melos run env:*` đổi thành `.vet45/bin/vet45 …` (dựng bằng `dart compile exe`) hoặc `dart run tools/vet45_env/bin/run.dart …`. Xoá `packages/vet45_misa` (đã viết lại bằng TypeScript trong Edge Function ở P7.4) | `flutter analyze` sạch |
| 9.4 | DB: bỏ outbox/inbox của mọi schema (kể cả `sales`, `einvoice`) và RPC/view messaging của `platform`; **giữ `einvoice.internal_commands`** (hàng đợi của Edge Function). Bỏ idempotency/onboarding, RPC readiness/activate/onboarding, trạng thái `provisioning`/`pending_activation`; thêm lại FK `memberships.user_id` | `supabase db reset` OK |
| 9.5 | **Gộp migration**: dump schema thành ~5 file baseline (`00_schemas`, `01_tables`, `02_functions`, `03_rls`, `04_triggers`) + `seed.sql`; chuyển migration cũ vào `supabase/_archive/` | `db reset` từ baseline + chạy lại checklist |
| 9.6 | Xoá `tools/vet45_supabase_migrate` và guard CI không còn dùng. **Giữ `tools/vet45_env`** (đổi môi trường local/Dev/Prod, `sync` env, `link`, `doctor`, `admin create`), gọn lại: bỏ target `admin`, `worker` và action `run worker …`, bỏ key `MESSAGING_CLIENT_POLL_ENABLED`, `WORKER_*`; thêm key secrets cho Edge Function (`MISA_*`, `RESEND_*`) nếu cần | `vet45 doctor` sạch; `vet45 switch` + `sync` sinh đúng `apps/erp/.env` |

**Xong khi:** đạt toàn bộ **Definition of Done ở SCOPE mục 6**.

---

## P10. Hoàn thiện cho báo cáo đồ án (2 ngày)

**Trạng thái:** ⬜ Chưa làm

| Plan | Nội dung | Gồm việc | Plan | Làm | Review |
|---|---|---|---|---|---|
| **10-1** | Tài liệu kiến trúc, sơ đồ báo cáo, README | 10.1, 10.2, 10.3 | ⬜ | ⬜ | ⬜ |
| **10-2** | Kịch bản demo bảo vệ | 10.4 | ⬜ | ⬜ | ⬜ |
| **10-3** | Đổi tên `vet45` (tùy chọn), merge và tag `v2.0.0` — làm thẳng | 10.5, 10.6 | — | ⬜ | — |

Chi tiết từng việc:

| # | Việc |
|---|---|
| 10.1 | Viết lại `docs/architecture/` thành 2 file: `ARCHITECTURE.md` (sơ đồ 3 tầng, luồng request, quy tắc phụ thuộc) và `DATABASE.md` (ERD theo schema, RLS, các RPC transaction) |
| 10.2 | Sơ đồ cho báo cáo: kiến trúc tổng thể, use case theo vai trò (Owner / Nhân viên / Platform Admin), sequence đăng ký cửa hàng, sequence checkout → HĐĐT |
| 10.3 | Cập nhật README: cách chạy local (Supabase + seed + app) |
| 10.4 | Kịch bản demo bảo vệ: đăng ký cửa hàng → thêm sản phẩm → thêm khách → bán hàng → phát hành HĐĐT → đổi trả → admin tạm ngưng tổ chức |
| 10.5 | (Tùy chọn) Đổi tên công cụ `vet45` / thư mục `.vet45` / `tools/vet45_env` cho khớp tên dự án mới |
| 10.6 | Merge `refactor/simple-arch` → `dev` → `main`, tag `v2.0.0` |

---

## Theo dõi tiến độ

| Phase | Trạng thái | PR | Ghi chú |
|---|---|---|---|
| P0 | ✅ | — (commit trực tiếp trên branch) | Tag `v-legacy-arch`; CHECKLIST lập xong, cột "Cũ" bỏ qua; TEST-BASELINE 5688 đạt / 160 lỗi; Supabase Dev đủ 162 migration; tài liệu cũ vào `docs/_legacy/` |
| P1 | ✅ | Merge `7c455c6a7` (branch `refactor/p1-core`) | 1.1 `16bcfe263`; 1-A `d8f4e9ca8`, `8550b3561`; 1-B `3a48c19b5`, `373002481`. Còn kiểm tay + tick CHECKLIST |
| P2 | 🔄 | — | Code xong 2-A1…2-B4 (2026-10-11). 2-B1, 2-B2, 2-B3 review 🔄 chờ **đợt kiểm IAM** (bước 7 trong thứ tự thực hiện) |
| P3 | ⬜ | | |
| P4 | ⬜ | | |
| P5 | ⬜ | | |
| P6 | ⬜ | | |
| P7 | ⬜ | | |
| P8 | 🔄 | — | 8-A ✅ review (2026-10-11), chờ kiểm tay; 8-B khung, làm cùng đợt kiểm IAM |
| P9 | ⬜ | | |
| P10 | ⬜ | | |

## Rủi ro theo phase

| Phase | Rủi ro | Cách xử lý |
|---|---|---|
| P2 | Trigger trên `auth.users` lỗi làm hỏng việc xác minh email | Test kỹ ở local; trigger bắt lỗi rõ ràng; validate dữ liệu cửa hàng trên client trước khi `signUp` |
| P2 | Email OTP local khó test | Dùng Inbucket/Mailpit có sẵn trong `supabase start` để đọc mã |
| P6 | Mất rule nghiệp vụ khi bỏ Aggregate | Bước 5 của công thức: port rule thành hàm thuần và giữ test cũ |
| P7 | UI einvoice nằm ở module nên phải chuyển nhiều file | Chuyển nguyên thư mục trước, đổi dependency sau, 2 PR riêng |
| P9 | Gộp migration làm lệch schema | So `pg_dump --schema-only` trước và sau; chạy lại toàn bộ checklist |
