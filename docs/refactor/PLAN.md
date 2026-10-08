# Kế hoạch thực hiện refactor

> Đi kèm [SCOPE.md](SCOPE.md) (phạm vi và các quyết định đã chốt). File này trả lời câu hỏi: **làm gì, theo thứ tự nào, xong thì kiểm tra thế nào.**
> Branch làm việc: `refactor/simple-arch` (tách từ `feature/theme8`). Ngày lập: 2026-10-06.

## Tổng quan

```text
P0 Chuẩn bị ─▶ P1 Nền core/ ─▶ P2 Auth & IAM ─▶ P3 Catalog+Inventory ─▶ P4 Partner ─▶ P5 Pricing ─▶ P6 Sales ─▶ P7 E-invoice ─▶ P8 Platform admin ─▶ P9 Dọn dẹp ─▶ P10 Hoàn thiện báo cáo
                                     │                                                                                       ▲
                                     └───────────────────────────── P8 có thể làm song song từ sau P2 ───────────────────────┘
```

| Phase | Nội dung | Ước lượng | Phụ thuộc |
|---|---|---|---|
| P0 | Chuẩn bị branch, commit việc dở, chụp checklist | 0,5 ngày | — |
| P1 | Dựng `core/` + mẫu feature | 2 ngày | P0 |
| P2 | Auth, đăng ký cửa hàng, IAM | 5 ngày | P1 |
| P3 | Catalog + Inventory | 5 ngày | P2 |
| P4 | Partner | 2 ngày | P2 |
| P5 | Pricing | 2 ngày | P3, P4 |
| P6 | Sales | 6 ngày | P3, P4, P5 |
| P7 | E-invoice | 8 ngày | P6 |
| P8 | Platform admin (gộp app) | 3 ngày | P2 |
| P9 | Dọn dẹp code + DB | 3 ngày | P1–P8 |
| P10 | Tài liệu, sơ đồ cho báo cáo | 2 ngày | P9 |
| | **Tổng** | **~39 ngày làm việc** | |

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

### Danh sách plan

| Việc | File plan | Plan | Làm | Review |
|---|---|---|---|---|
| 1.1 Cấu trúc thư mục `core/` | [plans/P1/1.1-cau-truc-core.md](plans/P1/1.1-cau-truc-core.md) | ✅ | ✅ | ✅ |
| 1-A `AppException`, `SupabaseRpc`, feature mẫu, kiểm import | [plans/P1/1-A-app-exception-feature-mau.md](plans/P1/1-A-app-exception-feature-mau.md) | ✅ | ✅ | ✅ |
| 1-B `SessionController` + router guard | [plans/P1/1-B-session-controller-guard.md](plans/P1/1-B-session-controller-guard.md) | ✅ | ✅ | ✅ |
| 2-A1 IAM: tài khoản, hồ sơ tổ chức, đặt lại mật khẩu | [plans/P2/2-A1-iam-tai-khoan-to-chuc.md](plans/P2/2-A1-iam-tai-khoan-to-chuc.md) | ✅ | ✅ | ✅ |
| 2-A2 IAM: thành viên, lời mời, vai trò, nhật ký | [plans/P2/2-A2-iam-thanh-vien-loi-moi-nhat-ky.md](plans/P2/2-A2-iam-thanh-vien-loi-moi-nhat-ky.md) | ✅ | ✅ | ✅ |


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
| **2-A3** | (a) Phiên & đăng nhập: `SessionController` gọi RPC trực tiếp (`get_tenant_context`, `list_accessible_tenants`, `switch_tenant_context`, `user_preferences`) và tự cập nhật `IamSession`; `LoginCubit`, đăng xuất, nhập mã lời mời `/invitation` (`InvitationAcceptanceCubit`); xử lý 2 góp ý review 1-B (`core` import `features`, reset state khi đổi người dùng) | 2B.5, 1-B góp ý | ⬜ | ⬜ | ⬜ |
| **2-B1** | (b) Đăng ký cửa hàng mới: trigger DB, cấu hình OTP, `/login`, `/signup`, `/verify-email`, `/no-organization`, banner hồ sơ pháp lý; thêm nhánh guard "chưa xác minh", "không có tổ chức", chọn tổ chức hoạt động đầu tiên | 2A.1, 2A.2, 2A.3, 2B.1, 2B.2, 2B.3, 2B.4, 2B.7 | ⬜ | ⬜ | ⬜ |
| **2-B2** | (b) Email qua Edge Function `send-email` + các sửa KI của TH-01 | 2A.4, TH-01 mục 9.2 | ⬜ | ⬜ | ⬜ |

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

Chi tiết từng việc:

Đặc tả: [TH-08](../02-yeu-cau/TH-08-hoa-don-dien-tu.md). Chia PR theo [TH-08 mục 9.2](../02-yeu-cau/TH-08-hoa-don-dien-tu.md#92-chia-pr-của-p7). Quyết định 2026-10-07: **giữ hành vi hiện có** (hàng đợi, đối soát nền, phát hành và gửi tự động, chống trùng) nhưng **bỏ `apps/messaging_worker`**: mọi lệnh gọi MISA chuyển sang Edge Function `einvoice-processor` (TypeScript), kích hoạt bởi app và `pg_cron` mỗi 30 giây (TH-08 KI-20). UI e-invoice hiện tách giữa `modules/einvoice/presentation` và bản sao trong `features/sales` (KI-17).

| # | Việc |
|---|---|
| 7.1 | **DB**: promote 23 file `supabase/migrations/_drafts/001…023` thành migration chính thức; sửa `update_automation_policy` (KI-02), kiểm người mua trong `issue_invoice` / `retry_issuance` / `start_auto_issuance` (KI-04), chép lại trường người mua mỗi lượt (KI-06) |
| 7.2 | **Thiết lập**: chuyển 4 màn vào `apps/erp/lib/features/einvoice/presentation`; `EInvoiceRepository` (kết nối, mẫu, chính sách, sẵn sàng) gọi RPC `einvoice`; KI-01, 15, 16 |
| 7.3 | **Trên đơn**: `OrderEInvoiceSection` + 2 cubit dùng repository; gộp các sheet về một chỗ; hỏi lại trạng thái bằng `Timer` trong cubit (bỏ `vet45_async_query`, giữ hành vi); KI-08, 17 |
| 7.4 | **Edge Function `einvoice-processor`**: viết lại client MISA bằng TypeScript (theo `packages/vet45_misa`, chép 80 test sang Deno) và handler cho 9 loại lệnh `internal_commands` (đồng bộ mẫu, xem trước, phát hành + khóa ký hiệu, đối soát, bản chính thức, tải tài liệu, quan sát, gửi email, đối soát gửi) |
| 7.5 | **Kích hoạt**: `pg_cron` + `pg_net` gọi Edge Function mỗi 30 giây; app gọi `functions.invoke` sau mỗi RPC ghi yêu cầu; trigger khi đơn Hoàn tất và khi hồ sơ khách đổi ghi thẳng `internal_commands` (thay outbox/inbox); `record_issuance_success` tự xếp việc gửi tự động (KI-19, KI-20) |

**Xong khi:** với worker **đã tắt**: kết nối MISA sandbox → phát hành từ đơn → xem/tải PDF → gửi email → gửi lại → phát hành lại sau lỗi; tự phát hành + tự gửi chạy khi bật, kể cả khi app đã đóng; MISA timeout thì `pg_cron` đối soát ra đúng một hóa đơn (TH-08 mục 9.3).

---

## P8. Platform admin: gộp app (3 ngày, làm song song được từ sau P2)

**Trạng thái:** ⬜ Chưa làm

| Plan | Nội dung | Gồm việc | Plan | Làm | Review |
|---|---|---|---|---|---|
| **8** | Gộp platform admin vào `/admin` | 8.1, 8.2, 8.4, 8.5 | ⬜ | ⬜ | ⬜ |

Chi tiết từng việc:

| # | Việc |
|---|---|
| 8.1 | Tạo `features/platform_admin/` + shell `/admin` (bottom nav riêng) |
| 8.2 | Chuyển từ `apps/admin`: tổng quan, danh sách/chi tiết tổ chức (tạm ngưng/khôi phục/đóng/chuyển owner), người dùng nền tảng, audit log |
| 8.4 | Menu "Chuyển không gian" cho user vừa là admin vừa là thành viên |
| 8.5 | Tạo platform admin bằng `vet45 admin create --email …` (đã có trong `tools/vet45_env`, không viết script mới) + admin mẫu trong `seed.sql` cho local; ghi cách dùng vào README |

**Không chuyển** từ `apps/admin`: wizard khởi tạo (`platform_onboarding_page`), "gửi lại lời mời owner", "gửi lại kích hoạt".

**Xong khi:** admin đăng nhập vào `/admin`, thấy tổ chức vừa đăng ký ở P2, tạm ngưng được (owner bị chặn) và khôi phục được.

---

## P9. Dọn dẹp (3 ngày)

**Trạng thái:** ⬜ Chưa làm

| Plan | Nội dung | Gồm việc | Plan | Làm | Review |
|---|---|---|---|---|---|
| **9-1** | Dọn code: xoá module, app admin, worker, package thừa, Melos; gọn `vet45_env` | 9.1, 9.2, 9.3, 9.6 | ⬜ | ⬜ | ⬜ |
| **9-2** | Dọn DB: bỏ outbox/inbox/onboarding, gộp migration baseline | 9.4, 9.5 | ⬜ | ⬜ | ⬜ |

Chi tiết từng việc:

| # | Việc | Kiểm tra |
|---|---|---|
| 9.1 | Xoá `modules/`, `apps/admin`, `apps/messaging_worker` | `grep -r "vet45_.*_application"` không còn kết quả |
| 9.2 | Xoá package `vet45_generator`, `vet45_annotations`, `vet45_adapters`, `vet45_async_query`, `vet45_resend`; gộp phần còn dùng của `vet45_shared` vào `core/` | `flutter pub get` OK |
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
| P2 | 🔄 | | |
| P3 | ⬜ | | |
| P4 | ⬜ | | |
| P5 | ⬜ | | |
| P6 | ⬜ | | |
| P7 | ⬜ | | |
| P8 | ⬜ | | |
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
