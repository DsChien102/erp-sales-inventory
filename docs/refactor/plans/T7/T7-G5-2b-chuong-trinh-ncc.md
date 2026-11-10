# T7-G5-2b — Chương trình nhà cung cấp

> Theme 7 · plan **G5-2b** của [PLAN.md](../../PLAN.md) mục "Theme 7" (bảng Plan)
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-10) | Làm ⬜ | Review ⬜
> Thiết kế: duyệt trong chat 2026-11-10 (3 phần: dữ liệu + RPC, luật, khung màn). Nguồn nghiệp vụ: [spec giá vốn](T7-G5-gia-von-thiet-ke.md) mục 12.1–12.3, 12.6–12.7. **Không có prototype / Screen Contract** ⇒ màn dựng theo khung ASCII mục 2.4 (đã duyệt) + khuôn K1 / K6 + DS. Phụ thuộc: G5-0b.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Người dùng Kho khai báo ưu đãi của nhà cung cấp (giảm theo bậc, mua X tặng Y, chiết khấu đạt mốc tích luỹ) gắn cặp NCC + sản phẩm, xem danh sách / chi tiết / tiến độ; server có sẵn RPC gợi ý cho dòng phiếu nhận (G5-3 dùng); mỗi tenant có NCC hệ thống "Mua lẻ / khác" không sửa / xoá được.

**Architecture:** Migration mới `20261113001_inventory_supplier_programs.sql` (4 bảng, 8 RPC, helper `_ensure_walk_in_supplier`); sửa thẳng migration gốc Theme 3 (cột `partners.is_system`, chặn trong `_lock_partner`, `get_partner_detail` trả `is_system`) và `ensure_default_store_warehouse_pair` (gọi helper). Flutter: BJ mới `features/inventory/{data,logic,presentation}/supplier_program/` — một repository, ba Cubit (P1, P2, P3), luật thuần; chi tiết NCC Theme 3 nhận khối "Chương trình ưu đãi" qua tham số `supplierSection` do router truyền (Theme 3 không import Kho).

**Tech Stack:** PostgreSQL / Supabase (plpgsql), Flutter, `flutter_bloc`, `go_router`, `get_it`, `vet45_design_system`.

**Spec:** mục 1–2 của plan này + [spec giá vốn](T7-G5-gia-von-thiet-ke.md) mục 12 + PLAN.md Theme 7 → "Quy ước chung cho mọi plan G5".

## Global Constraints

- Quy ước chung: PLAN.md Theme 7 → "Quy ước chung cho mọi plan G5". Mục "UI Flutter: trích code prototype" **không áp được** (không có prototype): thay bằng khung ASCII + bảng ánh xạ mục 2.4; phiên code không thêm phần tử ngoài bảng.
- **Không** chạy bước DB nào. `supabase/tests/inventory_supplier_programs.sql` và ca mới trong `partner_th03.sql` chỉ **viết**.
- Header migration theo khuôn `20261110001_inventory_core.sql`. Theme 3 và `20261104001` **sửa thẳng migration gốc** (PLAN.md "Sửa thẳng trong migration gốc"); ghi `Depends on` khi hàm cũ gọi hàm định nghĩa ở migration sau (plpgsql phân giải lúc chạy). Cập nhật `REGISTRY.yaml`.
- RPC Kho: `security definer`, `set search_path = inventory, iam, catalog, partner, pg_temp`, `grant execute … to authenticated`, quyền `_assert_actor(p_tenant_id, 'inventory.read')` cho **mọi** RPC (Q-2b-4: không chia chủ cửa hàng / nhân viên, không che tiền). RPC ghi: `_begin_idempotency` / `_complete_idempotency` như `save_stock_thresholds`.
- Tiền `bigint` (đồng); % `numeric(5,2)`; số lượng `numeric` (ĐVT cơ sở). Hiển thị số lượng `formatQuantity` (`logic/inventory_format.dart`), tiền `MoneyFormatter.formatMinor(int)`.
- Chữ trên màn: **nguyên văn** mục 2.3 / 2.4 (đã duyệt). Chỉ dùng "NCC" ở chỗ mục 2.4 ghi; tiêu đề đầy đủ "nhà cung cấp".
- `dart analyze` (không `flutter analyze`). Test: `flutter test --no-pub -r compact`.
- Trước khi sửa symbol đã có (`partner._lock_partner`, `partner.get_partner_detail`, `v_partner_detail`, `inventory.ensure_default_store_warehouse_pair`, `PartnerDetailDto`, `PartnerDetailPage`, `K6TaskList`, `K6TaskRow`, `warehouseAreaEntries`, `inventoryErrorMessage`, `app_router.dart`, `injection.dart`): chạy `impact`, ghi Kết quả; HIGH / CRITICAL → dừng, báo người dùng. Task kiểm cuối: `detect_changes()`.
- `AGENTS.md`, `CLAUDE.md`: không `git add`. Ghi mục 5 Kết quả sau mỗi task.

## Review Focus

1. **Hai người cùng tạo chương trình cho một NCC** ⇒ một người thành công, người kia nhận `PROGRAM_OVERLAP` + câu mục 2.3, form giữ nguyên dữ liệu đã nhập. Test: Task 1 ca SQL `overlap_blocked_second_insert`; Task 4 `submit_overlap_keeps_draft`.
2. **Sửa chương trình đã bị người khác sửa** (revision cũ) ⇒ `VERSION_CONFLICT` "Chương trình đã được sửa ở nơi khác. Tải lại để xem bản mới." + nút "Tải lại"; không ghi đè. Test: Task 1 `update_stale_revision_conflict`; Task 6 `version_conflict_reload_390`.
3. **Đổi loại ưu đãi sau khi đã nhập tham số** (bậc rồi chuyển sang mua X tặng Y) ⇒ payload chỉ chứa tham số của loại đang chọn; quay lại loại cũ thấy lại số đã nhập (giữ nháp theo loại). Test: Task 3 `payload_only_kind_fields`, `kind_switch_keeps_drafts`.
4. **Đối tác "Mua lẻ / khác"** ⇒ không có trong danh sách chọn NCC ở P2; mở chi tiết thì không có "Chỉnh sửa" / "Thao tác", có băng đối tác hệ thống, không có khối "Chương trình ưu đãi"; gọi RPC tạo chương trình với nó ⇒ `PROGRAM_SUPPLIER_INVALID`; gọi `update_partner` ⇒ `PARTNER_SYSTEM_LOCKED`. Test: Task 1 `walk_in_supplier_rejected`; Task 2 `system_partner_update_blocked`, `system_partner_detail_no_actions_390`; Task 6 `walk_in_not_in_supplier_options`.
5. **Gợi ý khi SL đúng bằng mốc bậc / vượt bậc cao nhất / dưới bậc thấp nhất** ⇒ `paid = 100` áp 3% (≥); `paid = 500` áp 5%, không có "Nhập thêm"; `paid = 50` không áp bậc, gợi ý "Nhập thêm 50 hộp để được giảm 3%". Test: Task 1 `hints_tier_boundaries`; Task 3 `tier_hint_boundaries`.

---

## 1. Quyết định (người dùng, 2026-11-10)

| Q | Nội dung |
|---|---|
| Q-2b-1 | **Đối tác hệ thống** đánh dấu bằng `partner.partners.is_system`; chặn ở `partner._lock_partner` (mọi RPC ghi Theme 3 đi qua: `update_partner`, `deactivate_partner`, `reactivate_partner`, `soft_delete_partner`, `transform_to_organization`, 3 RPC liên hệ) ⇒ `PARTNER_SYSTEM_LOCKED`. Tạo "Mua lẻ / khác" (tổ chức, vai trò `supplier`) trong `ensure_default_store_warehouse_pair` (app gọi mỗi lần vào tenant ⇒ tenant cũ cũng có). Nới check số điện thoại hồ sơ tổ chức khi đối tác là hệ thống |
| Q-2b-2 | Khối **"Lịch sử nhập hàng"** ở chi tiết NCC **dời sang G5-3** (chưa có bảng phiếu nhận). PLAN.md đã sửa dòng G5-2b / G5-3 |
| Q-2b-3 | **Mỗi NCC tối đa 1 chương trình đang hiệu lực** (`ACTIVE`, hoặc `REACHED` của loại 3), bất kể loại: unique một phần `(tenant_id, supplier_id) where status in ('ACTIVE','REACHED')` ⇒ `PROGRAM_OVERLAP`. Kết thúc / ghi nhận xong thì tạo được chương trình mới. Hệ quả: một dòng phiếu áp tối đa 1 chương trình |
| Q-2b-4 | **Không chia quyền**: ai có `inventory.read` đều xem / tạo / sửa / kết thúc, thấy số tiền. Lệch spec 12.6 (chỉ chủ cửa hàng) ⇒ ghi vào báo cáo đồ án |
| Q-2b-5 | Sửa chương trình **không đổi NCC / loại** (muốn đổi thì tạo mới); kết thúc có hiệu lực ngay, phiếu đã ghi giữ nguyên |
| Q-2b-6 | Lưu P2 xong về P3 + toast (không K4 — chưa ghi sổ) |

**Lệch thiết kế chat (phiên viết plan, duyệt cùng plan):**

| Chỗ | Đổi | Lý do |
|---|---|---|
| `list_supplier_programs` | Chỉ `p_tenant_id`, trả **mọi** chương trình; lọc trạng thái / NCC / sản phẩm / tìm tên ở Flutter | Dữ liệu nhỏ; số trên chip đếm được ngay trên client; khối ở chi tiết NCC dùng chung RPC |
| RPC thứ 8 `get_supplier_program_form_options` | Thêm: danh sách NCC chọn được (kèm chương trình đang hiệu lực) + sản phẩm (kèm đơn vị cơ sở) cho P2 và bộ lọc P1 | Kho không import repository Theme 2 / 3; loại "Mua lẻ / khác" và cảnh báo trùng làm ở server |
| `K6TaskList` / `K6TaskRow` | Thêm tham số `below` (widget dưới phụ đề) cho thanh tiến độ loại 3 | K6 chưa có chỗ đặt `VProgress` |

## 2. Thiết kế

### 2.1 Dữ liệu (`supabase/migrations/20261113001_inventory_supplier_programs.sql`)

Mọi bảng: `tenant_id uuid not null`, RLS bật, `revoke all … from public, anon, authenticated`.

| Bảng | Cột | Ràng buộc |
|---|---|---|
| `supplier_programs` | `id uuid pk`, `supplier_id uuid` (→ `partner.partners`), `name text`, `kind text`, `status text default 'ACTIVE'`, `started_on date`, `buy_qty numeric`, `free_qty numeric`, `target_qty numeric`, `rebate_percent numeric(5,2)`, `progress_qty numeric not null default 0`, `reached_at`, `ended_at timestamptz`, `note text`, `revision int not null default 1`, `created_by/at`, `updated_by/at` | `kind in ('TIER_DISCOUNT','BUY_X_GET_Y','VOLUME_REBATE')`; `status in ('ACTIVE','REACHED','RECORDED','ENDED')`; `status in ('REACHED','RECORDED') ⇒ kind = 'VOLUME_REBATE'`; theo `kind`: `BUY_X_GET_Y` ⇒ `buy_qty > 0 and free_qty > 0`, `VOLUME_REBATE` ⇒ `target_qty > 0 and rebate_percent > 0 and rebate_percent <= 100`, cột không thuộc loại `is null`; `length(btrim(name)) between 1 and 120`; unique một phần `supplier_programs_one_effective_per_supplier (tenant_id, supplier_id) where status in ('ACTIVE','REACHED')` |
| `supplier_program_products` | `program_id`, `product_id` | PK `(program_id, product_id)` |
| `supplier_program_tiers` | `program_id`, `min_qty numeric`, `discount_percent numeric(5,2)` | `min_qty > 0`; `discount_percent > 0 and <= 100`; `unique (program_id, min_qty)` |
| `supplier_program_receipts` | `id`, `program_id`, `receipt_line_id uuid`, `paid_qty numeric`, `purchase_amount_vnd bigint`, `created_at` | `unique (program_id, receipt_line_id)`. G5-2b chỉ tạo + đọc; G5-3 ghi |

Helper (không `grant`): `inventory._program_is_locked(p_program_id uuid) returns boolean` = `exists supplier_program_receipts` (G5-3 thêm điều kiện dòng phiếu có `program_id`); `inventory._ensure_walk_in_supplier(p_tenant_id uuid) returns uuid` — có đối tác `is_system` của tenant thì trả id; không thì thêm `partners` (`partner_type 'organization'`, `display_name 'Mua lẻ / khác'`, `is_system true`, `created_by/updated_by = auth.uid()`), `organization_profiles` (`organization_name 'Mua lẻ / khác'`, `organization_type 'other'`, `phone ''`, `allow_blank_phone true`), `partner_roles (supplier)`.

**Theme 3 (sửa migration gốc):**

| Tệp | Sửa |
|---|---|
| `20260714001_partner_v2_schema.sql` | `partners.is_system boolean not null default false`; unique một phần `partners_one_system_per_tenant (tenant_id) where is_system`; thêm cột `organization_profiles.allow_blank_phone boolean not null default false`; `chk_organization_profiles_phone_not_blank` đổi thành `check (allow_blank_phone or length(btrim(phone)) > 0)` (check không đọc được bảng `partners` nên cần cột riêng). Chỉ `_ensure_walk_in_supplier` đặt `true` |
| `20260714004_partner_v2_write_rpc.sql` | `_lock_partner`: sau kiểm `deleted`, `if v_partner.is_system then perform partner._raise_partner_error('PARTNER_SYSTEM_LOCKED', 'system partner is read-only'); end if;` |
| `20260714003_partner_v2_read.sql` | `v_partner_detail` thêm cột `p.is_system` (cuối danh sách cột); `get_partner_detail`: `is_system` ⇒ `v_actions` chỉ còn `viewHistory` (nếu có quyền); JSON thêm `'is_system'` |
| `20261104001_inventory_default_pair.sql` | `ensure_default_store_warehouse_pair`: ngay sau `pg_advisory_xact_lock`, trước nhánh trả sớm: `perform inventory._ensure_walk_in_supplier(p_tenant_id);` |

### 2.2 RPC (cùng migration)

| RPC | Vào | Ra / luật |
|---|---|---|
| `list_supplier_programs(p_tenant_id)` | — | `{programs: [ProgramRow]}` sắp `status` (`ACTIVE`, `REACHED`, `RECORDED`, `ENDED`) rồi `created_at desc`. `ProgramRow = {program_id, name, kind, status, supplier_id, supplier_name, started_on, product_ids[], product_count, common_uom (tên ĐVT cơ sở nếu mọi sản phẩm cùng đơn vị, khác ⇒ null), tiers [{min_qty, discount_percent}] (tăng dần), buy_qty, free_qty, target_qty, rebate_percent, progress_qty}` |
| `get_supplier_program(p_tenant_id, p_program_id)` | — | Không thuộc tenant ⇒ `CONTEXT_INVALID`. `{program: ProgramRow + {note, revision, is_locked, reached_at, ended_at, created_at}, products: [{product_id, name, code, base_uom}], receipts: [{receipt_line_id, paid_qty, purchase_amount_vnd, created_at}], base_amount_vnd: Σ purchase_amount_vnd}` |
| `get_supplier_program_form_options(p_tenant_id)` | — | `{suppliers: [{partner_id, display_name, active_program: {program_id, name} \| null}]` — đối tác `status 'active'`, vai trò `supplier` đang bật, `not is_system`, sắp `display_name`; `products: [{product_id, name, code, base_unit_id, base_uom}]` — `business_status 'active'`, chưa xoá, sắp `name`} |
| `create_supplier_program(p_tenant_id, p_idempotency_key, p_payload)` | `{supplier_id, kind, name, started_on, note, product_ids[], tiers[{min_qty, discount_percent}], buy_qty, free_qty, target_qty, rebate_percent}` | Kiểm theo thứ tự: NCC (`PROGRAM_SUPPLIER_INVALID` khi không có / không `active` / không vai trò `supplier` / `is_system`) → sản phẩm thuộc tenant, active (`CONTEXT_INVALID`); `BUY_X_GET_Y` đúng 1 sản phẩm, loại khác ≥ 1 (`CONTEXT_INVALID`) → `VOLUME_REBATE` cùng đơn vị cơ sở (`PROGRAM_UOM_MISMATCH`) → bậc 1–5, `min_qty` và `%` cùng tăng nghiêm ngặt (`CONTEXT_INVALID`) → `started_on` trong `[_today() − 365, _today() + 365]` → khoá `pg_advisory_xact_lock(hashtextextended(tenant || ':supplier_program:' || supplier, 0))`, có chương trình hiệu lực ⇒ `PROGRAM_OVERLAP` (bắt cả `unique_violation`). Trả `{program_id, revision: 1}` |
| `update_supplier_program(p_tenant_id, p_idempotency_key, p_program_id, p_expected_revision, p_payload)` | payload như trên, **không** `supplier_id` / `kind` (có và khác giá trị hiện tại ⇒ `CONTEXT_INVALID`) | Khoá dòng; `status` không `ACTIVE` / `REACHED` hoặc `_program_is_locked` ⇒ `PROGRAM_LOCKED`; `revision ≠ expected` ⇒ `VERSION_CONFLICT`; cùng kiểm tra như tạo; thay toàn bộ `products` / `tiers`; `revision + 1`. Trả `{program_id, revision}` |
| `end_supplier_program(p_tenant_id, p_idempotency_key, p_program_id, p_expected_revision)` | — | `status in ('ACTIVE','REACHED')` ⇒ `ENDED`, `ended_at = now()`; khác ⇒ `PROGRAM_LOCKED`; `VERSION_CONFLICT` như trên. Trả `{program_id, status: 'ENDED', revision}` |
| `get_receipt_program_hints(p_tenant_id, p_supplier_id, p_lines)` | `p_lines: [{product_id, paid_qty, unit_price}]` | `{lines: [{product_id, hint: Hint \| null}]}` cùng thứ tự vào. Chương trình xét: của `p_supplier_id`, `status 'ACTIVE'`, `started_on <= _today()`, có sản phẩm của dòng. NCC hệ thống / không có ⇒ mọi `hint null`. `Hint = {program_id, program_name, kind, tier, next_tier, suggested_free_qty, rebate}` — luật mục 2.3 "Gợi ý" |

Mã lỗi mới (`inventory._raise`): `PROGRAM_SUPPLIER_INVALID`, `PROGRAM_UOM_MISMATCH`, `PROGRAM_OVERLAP`, `PROGRAM_LOCKED`; Theme 3: `PARTNER_SYSTEM_LOCKED`. `PROGRAM_NOT_REACHED` để G5-5b.

### 2.3 Luật (`logic/supplier_program/`; server kiểm lại cùng luật)

**Kiểm form P2** — lỗi dưới ô; "Lưu" luôn bấm được, bấm thì hiện mọi lỗi và cuộn tới lỗi đầu:

| Ô | Luật | Câu lỗi |
|---|---|---|
| Nhà cung cấp | bắt buộc | "Chọn nhà cung cấp" |
| Tên | bắt buộc sau `trim`, ≤ 120 ký tự | "Nhập tên chương trình" · "Tên tối đa 120 ký tự" |
| Sản phẩm | ≥ 1; `BUY_X_GET_Y` đúng 1; `VOLUME_REBATE` cùng `base_unit_id` | "Chọn ít nhất một sản phẩm" · "Mua X tặng Y chỉ áp cho một sản phẩm" · "Các sản phẩm phải cùng đơn vị tính cơ sở ({ĐVT của sản phẩm đầu})" |
| Bậc (loại 1) | 1–5 bậc; mỗi bậc có cả hai số; `min_qty > 0`; `%` trong (0, 100]; bậc i > bậc i−1 cả hai số | "Nhập số lượng và mức giảm" · "Mức giảm từ 0,01 đến 100%" · "Số lượng bậc sau phải lớn hơn bậc trước" · "Mức giảm bậc sau phải lớn hơn bậc trước" |
| Loại 2 | `buy_qty`, `free_qty` số nguyên ≥ 1 | "Nhập số lượng mua" · "Nhập số lượng tặng" |
| Loại 3 | `target_qty > 0`; `%` trong (0, 100] | "Nhập mốc số lượng" · "Nhập % chiết khấu" |
| Ngày bắt đầu | mặc định hôm nay; trong ±365 ngày | "Ngày bắt đầu trong vòng một năm so với hôm nay" |

**Tóm tắt một dòng** `programSummary(ProgramRow)` — `{u}` = `' ' + common_uom` khi có, rỗng khi `null`:
- Loại 1: các bậc nối `' · '`: bậc đầu "Từ {min}{u} giảm {%}%", bậc sau "từ {min} giảm {%}%". Ví dụ "Từ 100 hộp giảm 3% · từ 300 giảm 5%".
- Loại 2: "Mua {X} tặng {Y}{u}".
- Loại 3: "Đạt {target}{u} giảm {%}% tổng tiền mua"; tiến độ `VProgress(progress / target)` + "{progress} / {target}{u}"; `REACHED` ⇒ thêm "Đã đạt mốc, chờ ghi nhận chiết khấu".
- Số: `formatQuantity`; %: bỏ số 0 thừa, dấu phẩy thập phân ("2,5%").

**Nhãn:**

| | Chữ | Tông `VBadge` |
|---|---|---|
| `ACTIVE` / `REACHED` / `RECORDED` / `ENDED` | "Đang chạy" / "Đạt mốc" / "Đã ghi nhận" / "Kết thúc" | info / warning / success / neutral |
| Loại ngắn (dòng P1, P3) | "Giảm theo bậc" / "Mua X tặng Y" / "Chiết khấu đạt mốc" | — |
| Loại dài (P2 chọn) | "Giảm giá theo bậc số lượng" / "Mua X tặng Y" / "Chiết khấu đạt mốc số lượng tích luỹ" | — |

**Gợi ý** (server `get_receipt_program_hints`; Flutter `receipt_hint_rules.dart` dựng câu, G5-3 dùng):
- Loại 1: `tier` = bậc có `min_qty` lớn nhất `<= paid_qty` ⇒ `{min_qty, discount_percent, discount_vnd: round(paid_qty × unit_price × % / 100)}` (làm tròn nửa lên, đồng); không có ⇒ `null`. `next_tier` = bậc nhỏ nhất có `min_qty > paid_qty` ⇒ `{min_qty, discount_percent, missing_qty: min_qty − paid_qty}`; không có ⇒ `null`. Câu: "Đang áp bậc từ {min}: giảm {%}%" · "Nhập thêm {missing} {ĐVT} để được giảm {%}%".
- Loại 2: `suggested_free_qty = floor(paid_qty / buy_qty) × free_qty`. Câu: "Tặng {n} {ĐVT} (mua {X} tặng {Y})"; `n = 0` ⇒ "Mua đủ {X} {ĐVT} để được tặng {Y}".
- Loại 3: `rebate = {progress_qty, target_qty, would_reach: progress_qty + paid_qty >= target_qty}`. Câu: "Tính vào chương trình "{tên}": {progress} + {paid} / {target} {ĐVT}"; `would_reach` ⇒ thêm " — đạt mốc khi ghi phiếu".

**Khoá / kết thúc:** `is_locked` ⇒ P2 chỉ đọc + băng "Chương trình đã có phiếu nhận gắn nên không sửa được tham số." + nút "Kết thúc chương trình". Sheet xác nhận: tiêu đề "Kết thúc chương trình "{tên}"?", nội dung "Phiếu nhận sau sẽ không áp ưu đãi này nữa. Không mở lại được.", nút "Kết thúc" (danger) · "Huỷ". Xong ⇒ toast "Đã kết thúc chương trình".

**Lỗi → câu** (thêm vào `inventoryErrorMessage`):

| Mã | Câu |
|---|---|
| `PROGRAM_OVERLAP` | "NCC này đang có chương trình khác đang chạy. Kết thúc chương trình đó trước khi tạo chương trình mới." |
| `PROGRAM_SUPPLIER_INVALID` | "Nhà cung cấp không hợp lệ hoặc đã ngừng hoạt động." |
| `PROGRAM_UOM_MISMATCH` | "Các sản phẩm phải cùng đơn vị tính cơ sở." |
| `PROGRAM_LOCKED` | "Chương trình đã có phiếu nhận gắn hoặc đã kết thúc nên không sửa được." |
| `VERSION_CONFLICT` (override ở P2 / P3) | "Chương trình đã được sửa ở nơi khác. Tải lại để xem bản mới." |
| `PARTNER_SYSTEM_LOCKED` (Theme 3) | "Đối tác hệ thống không sửa hoặc xoá được." |

### 2.4 Màn (khung đã duyệt 2026-11-10) + ánh xạ Flutter

Route (con của `ShellRoute(StoreShell)`, ngoài `StatefulShellRoute` — PLAN "Điều hướng"): `/warehouse/supplier-programs` (P1), `…/new?supplierId=` (P2 tạo; khai báo **trước** `:programId`), `…/:programId` (P3), `…/:programId/edit` (P2 sửa). Lối vào Hub: khu `valuation`, `WarehouseEntry(id: 'supplier_programs', title: 'Chương trình nhà cung cấp', subtitle: 'Ưu đãi giảm giá, hàng tặng, chiết khấu đạt mốc', icon: VIcons.coins, route: '/warehouse/supplier-programs')`.

**P1 — iPhone 390:**
```
┌ ‹ Quay về Kho   Chương trình NCC ┐
│ [🔍 Tìm tên chương trình        ] │
│ [NCC: Tất cả ▾] [Sản phẩm: Tất cả ▾]
│ (Đang chạy 3)(Đạt mốc 1)(Đã ghi nhận 0)(Kết thúc 2)
│ Nobivac bậc SL         [Đang chạy]│
│ Cty Thú Y Á Châu · Giảm theo bậc  │
│ Từ 100 hộp giảm 3% · từ 300 giảm 5%│
│ Mốc 1.000 hộp Q4       [Đạt mốc]  │
│ NCC A · Chiết khấu đạt mốc        │
│ ████████████████ 1.000 / 1.000 hộp│
│        [ + Tạo chương trình ]     │
└───────────────────────────────────┘
```

| Phần tử | Flutter | Tham số |
|---|---|---|
| Khung | `VPageScaffold(title: 'Chương trình NCC')`, nút quay lại "Quay về Kho" | |
| Ô tìm | `K6Search(hint: 'Tìm tên chương trình')` | khớp `name` không dấu, không phân biệt hoa thường (`VTextNormalizer.normalizeForSearch`) |
| Lọc NCC / SP | 2 `VChip` có mũi tên, mở `showVAdaptiveSheet` danh sách có ô tìm (`VSearchBar`) + dòng đầu "Tất cả"; chip ghi "NCC: {tên}" / "Sản phẩm: {tên}" khi đã chọn | nguồn: `form_options` |
| 4 chip trạng thái | `K7FilterChips` 4 `K7Filter(count:)` | mặc định `ACTIVE`; số đếm theo NCC / SP / ô tìm **trừ** trạng thái |
| Dòng | `K6TaskRow(title: name, subtitle: '$supplierName · $kindShort', status: K6Status(label, tone), below: …)` | `below`: loại 1/2 `VText(summary, bodySmall, textSecondary)`; loại 3 `VProgress` cao 6 + `VText('{p} / {t}{u}', mono)` |
| Web 1280 | `K6TaskList.columns`: "Tên" · "Nhà cung cấp" · "Loại" · "Ưu đãi" (tóm tắt / tiến độ) · "Trạng thái" | bộ lọc một hàng; "Tạo chương trình" `VButton(variant: primary)` góc phải đầu trang |
| Chân iPhone | `InventoryFooter` một nút "Tạo chương trình" (icon `add`) | |
| Rỗng | `InventoryEmpty(title: 'Chưa có chương trình nhà cung cấp', description: 'Khai báo ưu đãi của nhà cung cấp để áp khi nhận hàng.', actionLabel: 'Tạo chương trình')` | khi không có chương trình nào |
| Lọc rỗng | `InventoryEmpty(title: 'Không có chương trình phù hợp', description: 'Thử bộ lọc khác.', actionLabel: 'Xóa bộ lọc')` | xoá NCC / SP / ô tìm, giữ chip |
| Lỗi tải | `InventoryEmpty(title: 'Không tải được danh sách', description: 'Kiểm tra kết nối rồi thử lại.', actionLabel: 'Thử lại')` | |
| Đang tải | `InventoryLoading(blocks: [search, row, row, row])` | |

**P2 — iPhone 390 (web: cột giữa `VContentWidth` tối đa 720):**
```
│ Nhà cung cấp *   [Chọn nhà cung cấp ▾]│   (sửa: chỉ đọc)
│ ⚠ NCC này đang có chương trình "…". [Xem chương trình]
│ Loại ưu đãi *  (•) Giảm giá theo bậc số lượng
│                ( ) Mua X tặng Y        │   (sửa: chỉ đọc)
│                ( ) Chiết khấu đạt mốc số lượng tích luỹ
│ Tên chương trình * [               ]  │
│ Sản phẩm *  [+ Chọn sản phẩm]         │
│   Nobivac DHPPi · hộp            [✕]  │
│ ── Tham số ──                          │
│ L1: Từ [100] hộp  giảm [3] %     [✕]  │
│     [+ Thêm bậc]                       │
│ L2: Mua [10] tặng [1] hộp              │
│ L3: Mốc [1000] hộp · chiết khấu [5] %  │
│     Số lượng vượt mốc vẫn tính vào căn cứ chiết khấu.
│ Ngày bắt đầu [10/11/2026]  Ghi chú [  ]│
│ [  Huỷ  ]              [   Lưu   ]    │
```

| Phần tử | Flutter | Tham số |
|---|---|---|
| Khung | `VPageScaffold(title: 'Tạo chương trình' \| 'Sửa chương trình')` | |
| NCC | `VSelect` (danh sách `form_options.suppliers`, có tìm); sửa ⇒ `VKeyValueRow('Nhà cung cấp', name)` | `?supplierId=` điền sẵn |
| Cảnh báo trùng | `VBanner(warning, title: 'NCC này đang có chương trình "{tên}".', description: 'Kết thúc chương trình đó trước khi tạo chương trình mới.', action: 'Xem chương trình')` | NCC có `active_program`, chế độ tạo; "Lưu" tắt |
| Loại | `VChoiceList` 3 lựa chọn nhãn dài; sửa ⇒ `VKeyValueRow('Loại ưu đãi', nhãn dài)` | |
| Tên | `VTextField(label: 'Tên chương trình', maxLength: 120)` | |
| Sản phẩm | danh sách `VListRow(title: name, subtitle: '$code · $baseUom', trailing: nút ✕)` + `VButton(label: 'Chọn sản phẩm', variant: secondary)` mở sheet chọn nhiều (`VCheckbox` + ô tìm); loại 2 sheet chọn một | |
| Bậc | mỗi bậc một hàng: "Từ" `VNumberField` + ĐVT + "giảm" `VNumberField(suffix: '%')` + nút xoá; `VButton(label: 'Thêm bậc', variant: tertiary)` ẩn khi đủ 5 | bậc đầu có sẵn một hàng trống |
| Loại 2 | "Mua" `VNumberField` "tặng" `VNumberField` + ĐVT | |
| Loại 3 | "Mốc" `VNumberField` + ĐVT, "Chiết khấu" `VNumberField(suffix: '%')`, chú thích `VText(bodySmall, textSecondary)` | |
| Ngày, ghi chú | `VDatePicker(label: 'Ngày bắt đầu')`, `VTextArea(label: 'Ghi chú')` | |
| Chân | `InventoryFooter`: "Huỷ" (secondary, `pop`) · "Lưu" (primary, đang lưu ⇒ `loading`) | |
| Khoá | `InventoryLocked` dùng chữ mục 2.3 + `VButton(label: 'Kết thúc chương trình', variant: secondary, tone: danger)` | thay toàn bộ form |

**P3 — iPhone 390 (web: cột 720):**
```
│ Mốc 1.000 hộp Q4            [Đang chạy]│
│ ┌ Thông tin ─────────────────────────┐ │
│ │ Nhà cung cấp     NCC A          ›  │ │
│ │ Loại             Chiết khấu đạt mốc│ │
│ │ Bắt đầu          10/11/2026        │ │
│ │ Ưu đãi           Đạt 1.000 hộp giảm 5%…
│ │ Ghi chú          …                 │ │
│ └────────────────────────────────────┘ │
│ ┌ Sản phẩm áp dụng (2) ──────────────┐ │
│ │ Nobivac DHPPi · hộp             ›  │ │
│ └────────────────────────────────────┘ │
│ ┌ Tiến độ ───────────────────────────┐ │   (loại 3)
│ │ ██████░░░░  400 / 1.000 hộp        │ │
│ │ Căn cứ chiết khấu   40.000.000 đ   │ │
│ │ Phiếu đã tính: Chưa có phiếu nhận. │ │
│ └────────────────────────────────────┘ │
│ [Kết thúc chương trình]     [Sửa]      │
```

| Phần tử | Flutter | Tham số |
|---|---|---|
| Đầu | `VText(name, titleMedium)` + `VBadge(label, tone)` | |
| Thông tin | `VSection('Thông tin')` + `VKeyValueGroup`: "Nhà cung cấp" (chạm ⇒ `/partner/:id`), "Loại" (ngắn), "Bắt đầu" (`dd/MM/yyyy`), "Ưu đãi" (`programSummary`), "Ghi chú" (ẩn khi rỗng); `ENDED` thêm "Kết thúc" (ngày `ended_at`) | |
| Sản phẩm | `VSection('Sản phẩm áp dụng ({n})')` + `VListRow` chạm ⇒ `/warehouse/stock/:productId` | |
| Bậc (loại 1) | `VSection('Bậc giảm giá')` + `VKeyValueGroup` mỗi bậc "Từ {min} {ĐVT}" → "{%}%" | thay khối Tiến độ |
| Tiến độ (loại 3) | `VSection('Tiến độ')`: `VProgress` + "{p} / {t} {ĐVT}"; `VKeyValueRow('Căn cứ chiết khấu', money, mono: true)`; phiếu: rỗng ⇒ "Phiếu đã tính: Chưa có phiếu nhận.", có ⇒ mỗi phiếu `VKeyValueRow('{dd/MM/yyyy}', '{paid} {ĐVT} · {tiền}')` | `REACHED` ⇒ `VBanner(warning, 'Đã đạt mốc, chờ ghi nhận chiết khấu')` trên thanh |
| Chân | `InventoryFooter`: "Kết thúc chương trình" (secondary, tone danger) · "Sửa" (primary); khoá ⇒ chỉ nút đầu; `ENDED` / `RECORDED` ⇒ không có chân | |
| Lỗi / đang tải | `InventoryEmpty('Không tải được chương trình', 'Thử lại')`, `InventoryLoading`; `CONTEXT_INVALID` ⇒ `InventoryEmpty(title: 'Không tìm thấy chương trình', actionLabel: 'Về danh sách')` | |

**Khối ở chi tiết NCC (Theme 3)** — `SupplierProgramsSection(partnerId)` trong `presentation/supplier_program/`, đặt sau `PartnerDetailNoteCard`; chỉ hiện khi `roles` có `supplier` và `!isSystem`:
```
│ ┌ Chương trình ưu đãi ─────── Xem tất cả ›┐
│ │ Mốc 1.000 hộp Q4   [Đang chạy]          │
│ │ ███░░ 400 / 1.000 hộp                    │
│ │ (không có: "Chưa có chương trình đang chạy." + "+ Tạo chương trình")
│ └──────────────────────────────────────────┘
```

| Phần tử | Flutter | Tham số |
|---|---|---|
| Thẻ | cùng khung `PartnerDetail*Card` (`VCard`), tiêu đề "Chương trình ưu đãi", liên kết "Xem tất cả" ⇒ `/warehouse/supplier-programs?supplierId=` (P1 lọc sẵn NCC, chip "Tất cả" trạng thái giữ mặc định `ACTIVE`) | |
| Có chương trình hiệu lực | `K6TaskRow` như P1 (không phụ đề NCC: phụ đề = loại ngắn) chạm ⇒ P3 | |
| Không có | `VText('Chưa có chương trình đang chạy.')` + `VButton(label: 'Tạo chương trình', variant: tertiary)` ⇒ `…/new?supplierId=` | |
| Đang tải / lỗi | `VSkeleton` một dòng / `VText('Không tải được chương trình ưu đãi.')` + "Thử lại" | không chặn phần còn lại của màn |

**Đối tác hệ thống ở chi tiết:** ẩn thanh nút "Chỉnh sửa" / "Thao tác"; `VBanner(info, 'Đối tác hệ thống, dùng cho phiếu nhận mua lẻ. Không sửa hoặc xoá được.')` thay vị trí băng cảnh báo thiếu MST.

### 2.5 Ngoài phạm vi

"Lịch sử nhập hàng" (G5-3, Q-2b-2); áp ưu đãi trên phiếu, ghi `supplier_program_receipts`, `REACHED` (G5-3); P4, P5, giá vốn dự kiến, nút "Ghi nhận chiết khấu", "Cần chú ý" đạt mốc (G5-5b).

## 3. Tệp

| Tệp | Tạo / sửa | Task |
|---|---|---|
| `supabase/migrations/20261113001_inventory_supplier_programs.sql`, `REGISTRY.yaml` | tạo / sửa | 1 |
| `supabase/tests/inventory_supplier_programs.sql` | tạo | 1 |
| `apps/erp/test/features/inventory/data/supplier_program_sql_contract_test.dart` | tạo | 1 |
| `supabase/migrations/20260714001_partner_v2_schema.sql`, `…003_partner_v2_read.sql`, `…004_partner_v2_write_rpc.sql`, `20261104001_inventory_default_pair.sql` | sửa | 2 |
| `supabase/tests/partner_th03.sql`, `supabase/tests/inventory_default_pair.sql` | sửa | 2 |
| `apps/erp/test/features/partner/data/partner_system_sql_contract_test.dart` | tạo | 2 |
| `apps/erp/lib/features/partner/data/models/{partner_detail,partner_error_codes}.dart`, `logic/partner_error_messages.dart`, `presentation/pages/partner_detail_page.dart` + test | sửa | 2 |
| `apps/erp/lib/features/inventory/data/supplier_program/{supplier_program_models,supplier_program_repository}.dart`, `data/core/inventory_error_codes.dart` + test | tạo / sửa | 3 |
| `apps/erp/lib/features/inventory/logic/supplier_program/{supplier_program_rules,receipt_hint_rules,program_form_draft}.dart` + test | tạo | 3 |
| `apps/erp/lib/features/inventory/logic/supplier_program/{program_list,program_form,program_detail}_{cubit,state}.dart` + test | tạo | 4 |
| `apps/erp/lib/features/inventory/presentation/patterns/k6_task_list.dart` | sửa (`below`) | 5 |
| `apps/erp/lib/features/inventory/presentation/supplier_program/*` + test | tạo | 5, 6, 7, 8 |
| `apps/erp/lib/core/router/app_router.dart`, `lib/core/di/injection.dart`, `presentation/hub/warehouse_entries.dart` | sửa | 8 |
| `docs/refactor/PLAN.md` (dòng G5-2b / G5-3) | sửa (đã làm lúc viết plan) | — |
| `docs/refactor/plans/T7/img/G5-2b/` | ảnh Flutter | 9 |

## 4. Task

### Task 1: SQL Kho — bảng, helper, 8 RPC

**Files:** Create `supabase/migrations/20261113001_inventory_supplier_programs.sql`, `supabase/tests/inventory_supplier_programs.sql`, `apps/erp/test/features/inventory/data/supplier_program_sql_contract_test.dart`; Modify `REGISTRY.yaml`.

**Interfaces:**
- Consumes (G5-0b / G5-2a): `_assert_actor`, `_raise`, `_begin_idempotency`, `_complete_idempotency`, `_today()`; `catalog.products`, `catalog._product_base_unit_name`; `partner.partners`, `partner.partner_roles`, `partner.organization_profiles` (cột mới của Task 2 — Task 2 làm ngay sau, test SQL chạy khi cả hai xong).
- Produces: JSON mục 2.2 (Task 3 đọc); `_ensure_walk_in_supplier(uuid) returns uuid` (Task 2 gọi); `_program_is_locked(uuid)` (G5-3 mở rộng).

- [ ] **Step 1: Test hợp đồng (đỏ):** `program_tables_rls_revoked` (4 bảng có `enable row level security` + `revoke all`); `program_rpcs_granted` (8 RPC: `security definer`, `grant execute … to authenticated`, `_assert_actor(p_tenant_id, 'inventory.read')`, không có `'inventory.read', true`); `write_rpcs_idempotent` (3 RPC ghi gọi `_begin_idempotency`); `one_effective_per_supplier_index` (chuỗi `where status in ('ACTIVE','REACHED')`); `new_error_codes_present` (4 mã mục 2.2); `overlap_catches_unique_violation`.
- [ ] **Step 2: Chạy, thấy đỏ** — `cd apps/erp && flutter test --no-pub -r compact test/features/inventory/data/supplier_program_sql_contract_test.dart`.
- [ ] **Step 3: Viết migration** theo 2.1 / 2.2.
- [ ] **Step 4: Viết `supabase/tests/inventory_supplier_programs.sql`** (khuôn `inventory_stock_policy.sql`), mỗi ca `raise exception 'FAIL: <ca>'`:
  - `create_tier_program_ok` (2 bậc 100/3, 300/5; `list` trả `common_uom 'hộp'`, `tiers` tăng dần);
  - `hints_case12` — **ca 12 spec giá vốn**: `paid 300, price 100000` ⇒ `tier.discount_percent 5`, `discount_vnd 1500000` (giá gốc 28.500.000), `next_tier null`; `paid 280` ⇒ `tier 3%`, `discount_vnd 840000`, `next_tier.missing_qty 20`;
  - `hints_tier_boundaries` (`paid 100` ⇒ 3%; `500` ⇒ 5%, `next_tier null`; `50` ⇒ `tier null`, `missing_qty 50`);
  - `hints_buy_x_get_y` — ca 13: mua 10 tặng 1, `paid 10` ⇒ `suggested_free_qty 1`; `paid 25` ⇒ 2; `paid 9` ⇒ 0;
  - `hints_volume_rebate` (mốc 1000, `progress 0`, `paid 1000` ⇒ `would_reach true`; `paid 999` ⇒ false);
  - `hints_other_supplier_null` (chương trình NCC A, gọi với NCC B ⇒ `hint null`); `hints_not_started_null` (`started_on` mai ⇒ `null`);
  - `overlap_blocked_second_insert` (NCC đã có `ACTIVE` loại 1, tạo loại 3 ⇒ `PROGRAM_OVERLAP`; sau `end` ⇒ tạo được);
  - `uom_mismatch_volume` (hộp + chai ⇒ `PROGRAM_UOM_MISMATCH`; loại 1 cùng hai sản phẩm ⇒ được);
  - `walk_in_supplier_rejected` (`_ensure_walk_in_supplier` id ⇒ `PROGRAM_SUPPLIER_INVALID`; đối tác chỉ vai trò `customer` ⇒ cùng mã);
  - `buy_x_get_y_single_product` (2 sản phẩm ⇒ `CONTEXT_INVALID`); `tiers_must_increase` (300/5 rồi 100/3 ⇒ `CONTEXT_INVALID`; 100/5, 300/3 ⇒ `CONTEXT_INVALID`);
  - `update_stale_revision_conflict`; `update_locked_after_receipt` (chèn tay `supplier_program_receipts` ⇒ `PROGRAM_LOCKED`; `end` vẫn được); `update_cannot_change_kind`;
  - `end_twice_locked` (lần hai ⇒ `PROGRAM_LOCKED`); `create_idempotent_replay` (cùng khoá ⇒ cùng `program_id`, một dòng);
  - `form_options_excludes_system_and_inactive`; `form_options_active_program`.
- [ ] **Step 5: Chạy test hợp đồng, thấy xanh.**

### Task 2: Theme 3 — đối tác hệ thống "Mua lẻ / khác"

**Files:** Modify 4 migration ở bảng mục 3 (theo 2.1 "Theme 3"), `supabase/tests/partner_th03.sql`, `supabase/tests/inventory_default_pair.sql`, `apps/erp/lib/features/partner/data/models/partner_detail.dart`, `partner_error_codes.dart`, `logic/partner_error_messages.dart`, `presentation/pages/partner_detail_page.dart`; Create `apps/erp/test/features/partner/data/partner_system_sql_contract_test.dart`; Test `apps/erp/test/features/partner/presentation/partner_detail_system_test.dart`.

**Interfaces:**
- Consumes: Task 1 `inventory._ensure_walk_in_supplier(uuid)`.
- Produces: `PartnerDetailDto.isSystem` (`bool`, đọc `row['is_system'] as bool? ?? false`); `PartnerErrorCodes.systemLocked = 'PARTNER_SYSTEM_LOCKED'`; `PartnerDetailPage({…, Widget Function(BuildContext context, PartnerDetailDto dto)? supplierSection})` — dựng sau `PartnerDetailNoteCard` khi `roles.contains(supplier) && !isSystem` (Task 8 truyền).

- [ ] **Step 1: Test hợp đồng (đỏ):** `partners_has_is_system` (cột + unique một phần); `lock_partner_blocks_system` (`_lock_partner` có `'PARTNER_SYSTEM_LOCKED'`); `detail_returns_is_system` (`get_partner_detail` có `'is_system'`); `default_pair_ensures_walk_in` (`ensure_default_store_warehouse_pair` gọi `_ensure_walk_in_supplier` **trước** `return` đầu tiên); `org_phone_check_allows_system` (`allow_blank_phone or`).
- [ ] **Step 2: Widget test (đỏ)** `partner_detail_system_test.dart` (390 × 844, fake repository): `system_partner_detail_no_actions_390` (`isSystem: true` ⇒ không có "Chỉnh sửa", "Thao tác"; có chữ "Đối tác hệ thống, dùng cho phiếu nhận mua lẻ. Không sửa hoặc xoá được."; `supplierSection` không được gọi); `supplier_section_shown_for_supplier` (`roles [supplier]`, `isSystem false` ⇒ widget từ `supplierSection` có trong cây); `supplier_section_hidden_for_customer`.
- [ ] **Step 3: Chạy, thấy đỏ.**
- [ ] **Step 4: Sửa SQL** theo 2.1; thêm ca `partner_th03.sql`: `system_partner_update_blocked` (`update_partner`, `soft_delete_partner`, `deactivate_partner` ⇒ `PARTNER_SYSTEM_LOCKED`), `system_partner_detail_actions` (`available_actions` chỉ `viewHistory`); `inventory_default_pair.sql`: `walk_in_created_once` (gọi `ensure` 2 lần ⇒ đúng 1 đối tác `is_system`, có vai trò `supplier`, tên "Mua lẻ / khác").
- [ ] **Step 5: Sửa Flutter** (DTO, mã lỗi + câu mục 2.3, trang chi tiết theo 2.4 "Đối tác hệ thống").
- [ ] **Step 6: Chạy test Task 2 + toàn bộ `test/features/partner`, thấy xanh** (không thêm lỗi so với `TEST-BASELINE.md`).

### Task 3: Model + repository + luật thuần

**Files:** Create `lib/features/inventory/data/supplier_program/{supplier_program_models,supplier_program_repository}.dart`, `lib/features/inventory/logic/supplier_program/{supplier_program_rules,receipt_hint_rules,program_form_draft}.dart`; Modify `lib/features/inventory/data/core/inventory_error_codes.dart`; Test `test/features/inventory/data/supplier_program/supplier_program_repository_test.dart`, `test/features/inventory/logic/supplier_program/{supplier_program_rules,receipt_hint_rules,program_form_draft}_test.dart`.

**Interfaces:**
- Produces:
  - `enum ProgramKind { tierDiscount, buyXGetY, volumeRebate }` (`fromJson` theo chuỗi mục 2.1); `enum ProgramStatus { active, reached, recorded, ended }`.
  - `class ProgramTier { num minQty; num discountPercent; }`
  - `class ProgramRow { String id, name, supplierId, supplierName; ProgramKind kind; ProgramStatus status; DateTime startedOn; List<String> productIds; int productCount; String? commonUom; List<ProgramTier> tiers; num? buyQty, freeQty, targetQty, rebatePercent; num progressQty; }`
  - `class ProgramProduct { String productId, name, code, baseUom; }`; `class ProgramReceipt { String receiptLineId; num paidQty; int purchaseAmountVnd; DateTime createdAt; }`
  - `class ProgramDetail { ProgramRow row; String? note; int revision; bool isLocked; DateTime? reachedAt, endedAt; List<ProgramProduct> products; List<ProgramReceipt> receipts; int baseAmountVnd; }`
  - `class SupplierOption { String partnerId, displayName; ({String id, String name})? activeProgram; }`; `class ProductOption { String productId, name, code, baseUnitId, baseUom; }`; `class ProgramFormOptions { List<SupplierOption> suppliers; List<ProductOption> products; }`
  - `class ProgramHint { String programId, programName; ProgramKind kind; ({num minQty, num percent, int discountVnd})? tier; ({num minQty, num percent, num missingQty})? nextTier; num? suggestedFreeQty; ({num progress, num target, bool wouldReach})? rebate; }`
  - `SupplierProgramRepository({required InventoryRpc rpc})`: `Future<List<ProgramRow>> list()`; `Future<ProgramDetail> get(String id)`; `Future<ProgramFormOptions> formOptions()`; `Future<({String id, int revision})> create({required String idempotencyKey, required ProgramPayload payload})` (scope `'supplier_program.create'`); `update({required String idempotencyKey, required String id, required int expectedRevision, required ProgramPayload payload})` (scope `'supplier_program.update'`); `Future<int> end({required String idempotencyKey, required String id, required int expectedRevision})` (scope `'supplier_program.end'`); `Future<List<ProgramHint?>> receiptHints({required String supplierId, required List<({String productId, num paidQty, int unitPrice})> lines})`. Mỗi phương thức đúng một RPC mục 2.2.
  - `class ProgramPayload { String? supplierId; ProgramKind? kind; String name; DateTime startedOn; String? note; List<String> productIds; List<ProgramTier> tiers; num? buyQty, freeQty, targetQty, rebatePercent; Map<String, dynamic> toJson(); }` — `toJson` chỉ ghi khoá của `kind` (bỏ `supplier_id` / `kind` khi `null`).
  - `program_form_draft.dart`: `class ProgramFormDraft` (bất biến, `copyWith`) giữ `supplierId, kind, name, startedOn, note, productIds` + **nháp riêng mỗi loại** `tiers: List<({String minQty, String percent})>`, `buyQty, freeQty, targetQty, rebatePercent` (chuỗi ô nhập); `ProgramPayload toPayload({required bool forUpdate})`.
  - `supplier_program_rules.dart`: `Map<String, String> validateProgramForm(ProgramFormDraft d, List<ProductOption> products)` (khoá: `supplier`, `name`, `products`, `tier.$i`, `tiers`, `buyQty`, `freeQty`, `targetQty`, `rebatePercent`, `startedOn`; câu mục 2.3); `String programSummary(ProgramRow r)`; `String programStatusLabel(ProgramStatus)`, `VComponentTone programStatusTone(ProgramStatus)`, `String programKindShort(ProgramKind)`, `String programKindLong(ProgramKind)`; `String formatPercent(num)` ("2,5", "5").
  - `receipt_hint_rules.dart`: `List<String> hintLines(ProgramHint h, String uom)` — câu mục 2.3 "Gợi ý".
  - `inventory_error_codes.dart`: thêm 4 hằng `programOverlap`, `programSupplierInvalid`, `programUomMismatch`, `programLocked` + câu mục 2.3.

- [ ] **Step 1: Test (đỏ):**
  - repository: `list_parses_rows` (JSON mẫu loại 1 + loại 3; `common_uom null` ⇒ `commonUom null`); `get_parses_detail_receipts_empty`; `form_options_parses_active_program`; `create_sends_scope_and_payload`; `hints_preserve_order_and_null`.
  - rules: `summary_tier` ("Từ 100 hộp giảm 3% · từ 300 giảm 5%"); `summary_tier_mixed_uom` ("Từ 100 giảm 3% · từ 300 giảm 5%"); `summary_buy_x` ("Mua 10 tặng 1 hộp"); `summary_volume` ("Đạt 1.000 hộp giảm 5% tổng tiền mua"); `format_percent` (`2.5` ⇒ "2,5", `5.00` ⇒ "5"); `validate_requires_supplier_name_products`; `validate_buy_x_single_product`; `validate_volume_uom_mismatch` (câu có "(hộp)"); `validate_tiers_increasing` (cả hai câu); `validate_tier_max_five`; `validate_started_on_range`.
  - draft: `payload_only_kind_fields` (nháp có bậc + `buyQty`, chọn `buyXGetY` ⇒ `toJson` không có `tiers`, có `buy_qty`); `kind_switch_keeps_drafts`; `payload_update_omits_supplier_kind`.
  - hints: `tier_hint_boundaries` (dựng `ProgramHint` như ca SQL `hints_tier_boundaries` ⇒ "Đang áp bậc từ 100: giảm 3%", "Nhập thêm 50 hộp để được giảm 3%"); `buy_x_zero_free` ("Mua đủ 10 hộp để được tặng 1"); `volume_would_reach_suffix`.
- [ ] **Step 2: Chạy, thấy đỏ.**
- [ ] **Step 3: Viết code.**
- [ ] **Step 4: Chạy, thấy xanh.**

### Task 4: Ba Cubit (P1, P2, P3)

**Files:** Create `lib/features/inventory/logic/supplier_program/{program_list_cubit,program_list_state,program_form_cubit,program_form_state,program_detail_cubit,program_detail_state}.dart`; Test `test/features/inventory/logic/supplier_program/*_cubit_test.dart`.

**Interfaces:**
- Consumes: Task 3.
- Produces:
  - `ProgramListState { status (loading, ready, empty, loadError); List<ProgramRow> all; ProgramFormOptions? options; ProgramStatus statusFilter (mặc định active); String? supplierId, productId; String query; List<ProgramRow> get visible; int count(ProgramStatus s) /* theo NCC, SP, query; không theo statusFilter */; bool get filterEmpty; }`; `ProgramListCubit({required SupplierProgramRepository repository, String? initialSupplierId})`: `load()` (gọi `list` + `formOptions` song song), `refresh()`, `setStatus`, `setSupplier(String?)`, `setProduct(String?)`, `setQuery`, `clearFilters()` (NCC, SP, query; giữ `statusFilter`).
  - `ProgramFormState { status (loading, editing, saving, locked, loadError); ProgramFormDraft draft; ProgramFormOptions? options; Map<String, String> errors; bool showErrors; String? submitError; bool versionConflict; String? savedProgramId; bool get isEdit; SupplierOption? get overlapping /* chế độ tạo, NCC đã chọn có activeProgram */; }`; `ProgramFormCubit({required SupplierProgramRepository repository, String Function() newKey = newIdempotencyKey})` (`data/core/idempotency_key.dart`): `startCreate({String? supplierId})`, `startEdit(String programId)` (đọc `get`; `isLocked` hoặc `ENDED` / `RECORDED` ⇒ `locked`), `update(ProgramFormDraft Function(ProgramFormDraft) change)` (tính lại `errors`), `submit()` (có lỗi ⇒ `showErrors true`, không gọi RPC; khoá idempotency giữ nguyên giữa các lần bấm lại cùng nháp; `PROGRAM_OVERLAP` / lỗi khác ⇒ `submitError`, giữ nháp; `VERSION_CONFLICT` ⇒ `versionConflict true`), `reload()`.
  - `ProgramDetailState { status (loading, ready, notFound, loadError); ProgramDetail? data; bool ending; String? actionError; bool versionConflict; bool get canEdit /* ACTIVE|REACHED và !isLocked */; bool get canEnd /* ACTIVE|REACHED */; }`; `ProgramDetailCubit({required SupplierProgramRepository repository})`: `load(String id)`, `refresh()`, `end()` (thành công ⇒ tải lại, `Future<bool>`).

- [ ] **Step 1: Test (đỏ):** `list_default_active_filter`; `list_counts_ignore_status_filter`; `list_query_matches_unaccented` ("nobivac bac" khớp "Nobivac bậc SL"); `list_initial_supplier_filter`; `list_clear_keeps_status`; `list_empty_vs_filter_empty`; `form_prefill_supplier`; `form_overlap_from_options` (`overlapping != null`); `form_submit_invalid_no_rpc`; `submit_overlap_keeps_draft` (fake ném `PROGRAM_OVERLAP` ⇒ `submitError` = câu mục 2.3, `draft` không đổi); `form_submit_retry_same_key`; `form_edit_locked`; `form_version_conflict_flag`; `detail_can_edit_end_matrix` (4 trạng thái × `isLocked`); `detail_end_reloads`; `detail_not_found_on_context_invalid`.
- [ ] **Step 2: Chạy, thấy đỏ.**
- [ ] **Step 3: Viết code.**
- [ ] **Step 4: Chạy, thấy xanh.**

### Task 5: P1 Chương trình NCC (iPhone + web) + `K6` thêm `below`

**Files:** Modify `lib/features/inventory/presentation/patterns/k6_task_list.dart`; Create `lib/features/inventory/presentation/supplier_program/{program_list_page,program_filter_sheet,program_row_below}.dart`; Test `test/features/inventory/presentation/patterns/k6_task_list_test.dart` (thêm ca), `test/features/inventory/presentation/supplier_program/program_list_page_test.dart`.

**Interfaces:**
- Consumes: Task 4 `ProgramListCubit`; bảng P1 mục 2.4.
- Produces: `K6TaskRow({…, Widget? below})`, `K6TaskList({…, Widget? Function(T)? below})` (iPhone: dưới phụ đề, cách 4; web: không dùng — cột "Ưu đãi" thay); `ProgramRowBelow(ProgramRow row)` (Task 8 dùng lại ở khối chi tiết NCC); `ProgramListPage({String? initialSupplierId})`.

- [ ] **Step 1: Test (đỏ):** K6 `below_rendered_under_subtitle` (ca cũ của K6 vẫn xanh). P1 (fixture: 1 loại 1 `ACTIVE`, 1 loại 3 `REACHED` progress 1000/1000, 1 loại 2 `ENDED`): `list_ready_390` (tiêu đề "Chương trình NCC", chip "Đang chạy 1", "Đạt mốc 1", "Kết thúc 1"; dòng loại 1 có "Từ 100 hộp giảm 3% · từ 300 giảm 5%"; nút "Tạo chương trình"); `chip_reached_shows_progress_390` ("1.000 / 1.000 hộp", có `VProgress`); `supplier_filter_sheet_390`; `filter_empty_clear_390`; `empty_390`; `load_error_retry_390`; `list_ready_1280` (bảng có 5 tiêu đề cột mục 2.4, nút "Tạo chương trình" ở đầu trang, không có `InventoryFooter`); `row_tap_opens_detail` (đẩy `/warehouse/supplier-programs/<id>`); `create_tap_opens_form`.
- [ ] **Step 2: Chạy, thấy đỏ.**
- [ ] **Step 3: Dựng** theo bảng P1; quay về từ P2 / P3 (`await context.push`) ⇒ `refresh()`.
- [ ] **Step 4: Chạy, thấy xanh.**

### Task 6: P2 Tạo / sửa chương trình

**Files:** Create `lib/features/inventory/presentation/supplier_program/{program_form_page,program_product_picker_sheet,program_tier_rows,program_end_sheet}.dart`; Test `test/features/inventory/presentation/supplier_program/program_form_page_test.dart`.

**Interfaces:**
- Consumes: Task 4 `ProgramFormCubit`; bảng P2 mục 2.4.
- Produces: `ProgramFormPage.create({String? supplierId})`, `ProgramFormPage.edit({required String programId})`; `Future<bool> showProgramEndSheet(BuildContext, {required String programName})` (P3 dùng); lưu xong `context.go('/warehouse/supplier-programs/$id')` (thay vị trí, P1 không còn P2 trong ngăn xếp) + toast "Đã lưu chương trình".

- [ ] **Step 1: Test (đỏ):** `create_default_tier_kind_390` (một hàng bậc trống, chữ 3 lựa chọn loại nhãn dài); `walk_in_not_in_supplier_options` (fixture `form_options` không có "Mua lẻ / khác" ⇒ sheet chọn NCC không có dòng đó — kiểm repository fake trả đúng danh sách server, không lọc lại ở client); `overlap_banner_disables_save_390`; `kind_switch_shows_kind_fields_390` (chọn "Mua X tặng Y" ⇒ có "Mua", "tặng", không còn "Thêm bậc"; quay lại ⇒ bậc đã nhập còn); `add_tier_hidden_at_five`; `save_shows_errors_and_scrolls` (bấm "Lưu" form trống ⇒ "Chọn nhà cung cấp", "Nhập tên chương trình", "Chọn ít nhất một sản phẩm"); `volume_uom_hint_text` ("Số lượng vượt mốc vẫn tính vào căn cứ chiết khấu."); `edit_supplier_kind_readonly_390`; `locked_shows_end_only_390`; `version_conflict_reload_390` ("Chương trình đã được sửa ở nơi khác. Tải lại để xem bản mới." + "Tải lại"); `submit_overlap_message_390`; `form_1280_centered_max_720`.
- [ ] **Step 2: Chạy, thấy đỏ.**
- [ ] **Step 3: Dựng** theo bảng P2.
- [ ] **Step 4: Chạy, thấy xanh.**

### Task 7: P3 Chi tiết chương trình

**Files:** Create `lib/features/inventory/presentation/supplier_program/program_detail_page.dart`; Test `test/features/inventory/presentation/supplier_program/program_detail_page_test.dart`.

**Interfaces:**
- Consumes: Task 4 `ProgramDetailCubit`; Task 6 `showProgramEndSheet`; bảng P3 mục 2.4.
- Produces: `ProgramDetailPage({required String programId})`. Chỗ G5-5b gắn thêm: tham số `List<Widget> Function(ProgramDetail)? extraSections` (để `null` ở G5-2b; không dựng gì).

- [ ] **Step 1: Test (đỏ):** `volume_active_390` (khối "Tiến độ" "400 / 1.000 hộp", "Căn cứ chiết khấu" "40.000.000 đ", "Phiếu đã tính: Chưa có phiếu nhận."; chân "Kết thúc chương trình" + "Sửa"); `tier_shows_tier_table_390` (không có "Tiến độ", có "Bậc giảm giá" 2 dòng); `reached_banner_390` ("Đã đạt mốc, chờ ghi nhận chiết khấu"); `ended_no_footer_390` (có dòng "Kết thúc"); `locked_end_only_390`; `end_confirm_flow` (sheet đúng chữ mục 2.3 ⇒ "Kết thúc" ⇒ toast "Đã kết thúc chương trình", badge "Kết thúc"); `end_cancel_no_call`; `supplier_row_opens_partner`; `product_row_opens_stock`; `not_found_390`; `detail_1280_max_720`.
- [ ] **Step 2: Chạy, thấy đỏ.**
- [ ] **Step 3: Dựng** theo bảng P3.
- [ ] **Step 4: Chạy, thấy xanh.**

### Task 8: Khối ở chi tiết NCC + route + DI + Hub + luồng đầu–cuối

**Files:** Create `lib/features/inventory/presentation/supplier_program/{supplier_programs_section,supplier_program_routes}.dart`; Modify `lib/core/router/app_router.dart` (thêm `...supplierProgramRoutes()` cạnh `stockRoutes()`; route `partner.detail` truyền `supplierSection: (ctx, dto) => SupplierProgramsSection(partnerId: dto.partnerId)`), `lib/core/di/injection.dart` (`SupplierProgramRepository` lazy singleton), `presentation/hub/warehouse_entries.dart` (mục khu `valuation` mục 2.4, đặt **trước** "Giá vốn"); Test `test/features/inventory/presentation/supplier_program/supplier_programs_section_test.dart`, `…/supplier_program_flow_test.dart`, test Hub hiện có.

**Interfaces:**
- Consumes: Task 2 `supplierSection`; Task 3 repository (`list()` lọc `supplierId` + `ACTIVE|REACHED` ở client); Task 5 `ProgramRowBelow`; Task 5–7 page.
- Produces: `SupplierProgramsSection({required String partnerId})` (tự tạo Cubit nhỏ hoặc `FutureBuilder` qua `getIt<SupplierProgramRepository>()` — một lần tải, nút "Thử lại"); `List<RouteBase> supplierProgramRoutes()`.

- [ ] **Step 1: Test (đỏ):** section `section_shows_effective_program`; `section_empty_create_link` (chạm "Tạo chương trình" ⇒ `/warehouse/supplier-programs/new?supplierId=<id>`); `section_view_all_link`; `section_error_does_not_block`. Hub: `valuation_area_has_supplier_programs` (đúng thứ tự, route). Luồng `supplier_program_flow_test.dart` (fake repository có trạng thái, 390): Hub khu Giá trị → P1 rỗng → "Tạo chương trình" → chọn NCC, loại "Chiết khấu đạt mốc số lượng tích luỹ", 1 sản phẩm, mốc 1000, 5% → "Lưu" → P3 có "0 / 1.000 hộp" → quay về P1 thấy dòng "Đang chạy 1" → mở P3 → "Kết thúc chương trình" → xác nhận → P1 chip "Kết thúc 1".
- [ ] **Step 2: Chạy, thấy đỏ.**
- [ ] **Step 3: Viết code.** (PLAN.md đã sửa dòng G5-2b / G5-3 lúc viết plan, 2026-11-10.)
- [ ] **Step 4: Chạy test Task 8 + `test/features/inventory` + `test/features/partner` + router test, thấy xanh.**

### Task 9: Ảnh Flutter + kiểm cuối

**Files:** Create `docs/refactor/plans/T7/img/G5-2b/flutter-{P1-READY,P2-CREATE,P3-VOLUME,NCC-SECTION}-{390,1280}.png` (`matchesGoldenFile` trong test Task 5–8, cùng tên).

- [ ] **Step 1:** Thêm golden cho 4 trạng thái chính × 2 bề rộng (NCC-SECTION: chỉ 390 nếu bố cục web giống), chạy `flutter test --update-goldens` cho đúng các test đó, chép ảnh vào `img/G5-2b/`. Không có ảnh prototype ⇒ review so ảnh với khung ASCII mục 2.4.
- [ ] **Step 2:** `cd apps/erp && dart analyze lib/features/inventory lib/features/partner test/features/inventory test/features/partner` = 0 lỗi; `flutter test --no-pub -r compact` không thêm lỗi so với `TEST-BASELINE.md`.
- [ ] **Step 3:** `detect_changes({scope: "compare", base_ref: "main"})` — chỉ đổi symbol trong bảng mục 3 + `_lock_partner`, `get_partner_detail`, `ensure_default_store_warehouse_pair`; ghi Kết quả.
- [ ] **Step 4:** Ghi mục 5 Kết quả; nhắc người dùng chạy `supabase db reset --linked` (hỏi trước) rồi `supabase/tests/inventory_supplier_programs.sql`, `partner_th03.sql`, `inventory_default_pair.sql`.

## 5. Kết quả

_(phiên code ghi: impact từng symbol, lệch plan + lý do, test đã chạy, nợ còn lại)_

## 6. Review

_(phiên review ghi)_
