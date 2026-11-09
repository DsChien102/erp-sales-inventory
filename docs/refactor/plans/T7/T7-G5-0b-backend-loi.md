# T7-G5-0b — Backend lõi Kho

> Theme 7 · plan **G5-0b** của [PLAN.md](../../PLAN.md) mục "Theme 7" (bảng Plan)
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-09) | Làm ⬜ | Review ⬜
> Thiết kế duyệt trong chat 2026-11-09, ghi ở mục 2 của plan này (không có tệp spec riêng).

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Có schema + helper SQL + RPC đọc + lớp Flutter dùng chung để mọi BJ ghi tồn đúng bất biến chỉ bằng cách gọi lõi, và sản phẩm có `tracking_mode` / `expiry_required`.

**Architecture:** Một migration mới `20261110001_inventory_core.sql` chứa bảng, trigger, helper `_…` (không cấp cho `authenticated`) và 2 RPC công khai. Hai cột sản phẩm sửa thẳng migration gốc của Catalog (quy tắc "sửa migration gốc tới khi lên Prod"). Flutter có `features/inventory/data/core/` bọc `SupabaseRpc` + `AppException` đang có; Hub (G5-0a) đổi thân repository sang RPC.

**Tech Stack:** PostgreSQL / Supabase (plpgsql, RLS), Flutter, `supabase` Dart, `get_it`, `flutter_bloc`.

**Spec:** mục 1–2 của plan này + PLAN.md mục Theme 7 → "Quy ước chung cho mọi plan G5".

## Global Constraints

- **Không** ghi / chạy bước DB nào (reset, push, `psql`): người dùng tự làm. Test SQL chạy tay (`supabase/tests/inventory_core.sql`) chỉ **viết**, người dùng chạy.
- Đối tượng mới → migration mới `supabase/migrations/20261110001_inventory_core.sql`. Đối tượng đã có (bảng `catalog.products`, RPC Catalog) → **sửa thẳng tệp đang giữ định nghĩa mới nhất** (liệt kê ở Task 1), không tạo migration ghi đè.
- Header migration theo khuôn `20261104001_inventory_default_pair.sql` (`-- Title / Kind / Intent / Context / Touches / Safety / Depends on`). Kind `schema`.
- Mọi bảng: RLS bật + `revoke all … from public, anon, authenticated`. Helper tên bắt đầu `_`: `revoke execute … from public, anon, authenticated`. RPC công khai: `security definer`, `set search_path = inventory, iam, catalog, pg_temp`, `grant execute … to authenticated`.
- Lỗi nghiệp vụ chỉ qua `inventory._raise(code, message)` → `{"code", "message"}`; 16 mã ở mục 2.5, đúng chính tả.
- Flutter: lỗi là `AppException` (lớp `final`, không kế thừa — khác bản thiết kế đầu, xem Q-b6); `AppException.from` đã đọc JSON `{code}` và đổi `PERMISSION_DENIED` → `NO_PERMISSION`.
- Chữ Theme 2 nguyên văn: `Quản lý theo lô`, `Bắt buộc hạn dùng`, `Đã có biến động kho, không đổi được.`
- `dart analyze` (không dùng `flutter analyze`). Test: `flutter test --no-pub -r compact`.
- Trước khi sửa symbol đã có (`create_guided_product`, `update_product_profile`, `get_product_control_center`, `ProductRepository.createGuided` / `updateProfile`, `ProductProfileSummaryDto`, `WarehouseHubRepository.getSummary`): chạy `impact` (GitNexus), ghi blast radius vào Kết quả; HIGH / CRITICAL → dừng, báo người dùng. Trước commit: `detect_changes()`.
- `AGENTS.md`, `CLAUDE.md`: không `git add`. Ghi mục 6 Kết quả sau mỗi task; không ghi mục Review.

## Review Focus

1. **Hai người cùng xuất lô cuối cùng** ⇒ không được âm, không treo. `_post_movements` khoá theo sản phẩm tăng dần rồi mới đọc tồn. Test: Task 4 Step 1 `advisory_lock_before_balance_read` (thứ tự trong thân hàm) + ca SQL `insufficient_stock_rolls_back_all_lines`.
2. **Lệnh 2 dòng, dòng 2 thiếu hàng** ⇒ dòng 1 không được còn trong sổ. Test: Task 4 ca SQL `insufficient_stock_rolls_back_all_lines` (đếm `stock_movements` = 0 sau lỗi).
3. **App mất mạng sau khi gửi rồi gửi lại** ⇒ không ghi hai lần. Test: Task 3 ca SQL `replay_same_hash_returns_saved_result`; Task 6 `mutate_network_error_throws_outcome_unknown` + `outcome_not_found_safe_to_resend`.
4. **Đổi sản phẩm sang "Quản lý theo lô" khi đã có tồn không lô** ⇒ phải chặn. Test: Task 2 ca SQL `tracking_change_after_movement_locked`; Task 8 `toggles_locked_when_has_movements`.
5. **Nhân viên gọi thẳng RPC duyệt / xem "Chờ duyệt"** ⇒ từ chối / rỗng. Test: Task 5 ca SQL `non_owner_decide_denied`, `hub_summary_non_owner_no_pending`.

---

## 1. Quyết định

Q-b1…Q-b5 chốt khi thiết kế, Q-b6…Q-b9 thêm khi viết plan (người dùng duyệt cùng plan 2026-11-09).

| Q | Nội dung |
|---|---|
| Q-b1 | **Giữ bất biến, bỏ hạ tầng doanh nghiệp.** Giữ: sổ chỉ thêm, tồn cập nhật cùng giao dịch, lô, phiếu duyệt (chủ cửa hàng duyệt; chủ lập vẫn gửi rồi tự duyệt), idempotency + UNKNOWN xác minh bằng cùng mã, kích hoạt kho, chặn tồn âm. Bỏ: ApprovalPolicy có version / định tuyến theo `risk_value_vnd`, outbox / event, job dựng lại tồn, phong bì kết quả đầy đủ (`recovery_guidance`…). Khoá kho (InventoryLock) do G5-12 thêm |
| Q-b2 | **`tracking_mode` + `expiry_required` thêm vào `catalog.products`** (owner Sản phẩm theo overview.md), có ô gạt ở màn tạo / sửa sản phẩm Theme 2 |
| Q-b3 | **Đường ghi = một hàm lõi `inventory._post_movements`** (cách A), không dùng trigger cập nhật tồn, không tính tồn bằng `SUM` |
| Q-b4 | Bỏ mã `SELF_APPROVAL_NOT_ALLOWED`: người duyệt luôn là `is_owner`, người khác bị `PERMISSION_DENIED` |
| Q-b5 | Chữ màn sản phẩm (plan đề xuất, người dùng duyệt): `Quản lý theo lô`, `Bắt buộc hạn dùng`, `Đã có biến động kho, không đổi được.` |
| Q-b6 | **Không có `InventoryRpcException`** (bản thiết kế đầu): `AppException` là `final class`. Dùng `AppException.code` (chuỗi mã server) + hằng `InventoryErrorCode`. Lỗi mạng của `mutate` = `AppException.code == AppErrorCode.network` |
| Q-b7 | Mọi lỗi mạng của `mutate` coi là UNKNOWN (không phân biệt "trước" / "sau khi gửi" được ở tầng HTTP). An toàn vì `get_command_outcome` trả `NOT_FOUND` khi lệnh chưa tới server ⇒ gửi lại đúng khoá |
| Q-b8 | `title` / `subtitle` của dòng "Chờ duyệt" nằm trong `approval_cases.snapshot` (khoá `title`, `subtitle`) do BJ truyền vào `_open_approval` |
| Q-b9 | Sai `tracking_mode` / `expiry_required` (vd `expiry_required` với `none`) dựa vào check constraint ở bảng + UI chặn; không thêm mã lỗi |

## 2. Thiết kế (người dùng duyệt từng phần trong chat 2026-11-09)

### 2.1 Dữ liệu (migration mới `supabase/migrations/20261110001_inventory_core.sql`, schema `inventory`)

Mọi bảng: `tenant_id uuid not null`, RLS bật, `revoke all … from public, anon, authenticated` (chỉ đọc / ghi qua RPC `security definer`), như `20261104001_inventory_default_pair.sql`.

| Bảng | Cột chính | Ràng buộc |
|---|---|---|
| `tenant_inventory_settings` | `tenant_id` (PK), `activation_status` (`PREPARING` / `ACTIVE`), `activated_at`, `activated_by` | Không có dòng = `PREPARING` |
| `lots` | `id`, `product_id`, `lot_code`, `lot_code_normalized` (trim + upper), `expiry_date date`, `expiry_precision` (`DAY` / `MONTH` / `YEAR`), `manufacture_date`, `origin_intent_type`, `origin_intent_id`, `created_at`, `created_by` | `unique (tenant_id, product_id, lot_code_normalized)` |
| `stock_movements` | `id`, `ledger_sequence bigint`, `warehouse_id`, `product_id`, `lot_id`, `intent_type text`, `intent_id uuid`, `intent_line_id uuid`, `movement_kind text`, `from_state`, `to_state`, `valuation_state`, `quantity_delta numeric` (ĐVT cơ sở), `business_date date`, `created_at`, `created_by` | `quantity_delta <> 0`; `unique (tenant_id, ledger_sequence)`; trigger `before update or delete` → `raise exception` (INV-IO-04) |
| `stock_balances` | `id`, `warehouse_id`, `product_id`, `stock_state`, `valuation_state`, `lot_key uuid` (= `lot_id`, hoặc `'00000000-0000-0000-0000-000000000000'` khi không lô), `physical_quantity numeric`, `last_ledger_sequence`, `updated_at` | `unique (tenant_id, warehouse_id, product_id, stock_state, valuation_state, lot_key)`; `physical_quantity >= 0` |
| `value_movements` | `id`, `ledger_sequence`, `warehouse_id`, `product_id`, `lot_id`, `intent_type`, `intent_id`, `intent_line_id`, `movement_kind`, `quantity_basis numeric`, `amount_vnd bigint`, `business_date`, `created_at`, `created_by` | Chỉ thêm (trigger như trên) |
| `approval_cases` | `id`, `subject_type text`, `subject_id uuid`, `snapshot jsonb`, `requester_id`, `submitted_at`, `status` (`PENDING` / `APPROVED` / `REJECTED` / `SUPERSEDED`), `decided_by`, `decided_at`, `decision_reason`, `version int` | `unique (tenant_id, subject_type, subject_id) where status = 'PENDING'` |
| `idempotency_records` | **đã có** (`20261104001`) | Giữ nguyên |

`stock_state`: `SELLABLE`, `QUARANTINE`, `DAMAGED`, `EXPIRED`, `DEMO`, `RETURN_PENDING`, `RTV_PENDING` (check constraint; plan BJ được thêm giá trị bằng cách sửa migration này). `valuation_state`: `PENDING`, `CONFIRMED`. `ledger_sequence`: lấy từ `inventory.ledger_counters (tenant_id PK, last_sequence)` cập nhật trong cùng giao dịch (đơn điệu theo tenant, không dùng `sequence` toàn cục).

`catalog.products` thêm: `tracking_mode text not null default 'none' check (tracking_mode in ('none','lot'))`, `expiry_required boolean not null default false`, `check (not expiry_required or tracking_mode = 'lot')` (INV-LOT-02). Trigger `before update`: đổi một trong hai cột khi đã có dòng `inventory.stock_movements` của sản phẩm → `TRACKING_LOCKED`. RPC tạo / sửa sản phẩm Theme 2 nhận thêm hai tham số (mặc định giữ giá trị cũ).

### 2.2 Helper ghi (nội bộ, `revoke execute … from authenticated`)

| Hàm | Làm gì |
|---|---|
| `inventory._assert_actor(p_tenant_id uuid, p_permission text, p_require_owner boolean default false, p_allow_preparing boolean default false) returns jsonb` | `auth.uid()` có; `iam.has_permission`; `p_require_owner` → `is_owner` (lấy từ `iam.memberships`); cặp cửa hàng–kho mặc định đang hoạt động (đọc `store_warehouse_assignments`, trả `{store_id, warehouse_id, actor_id, is_owner}`); kho `ACTIVE` trừ khi `p_allow_preparing` |
| `inventory._begin_idempotency(p_tenant_id, p_command_scope, p_idempotency_key, p_payload_hash) returns jsonb` | Chép khuôn `sales._begin_sales_idempotency`: khoá tư vấn → `{decision: 'new' \| 'replay' \| 'in_progress', result?}`; cùng khoá khác hash → `IDEMPOTENCY_CONFLICT` |
| `inventory._complete_idempotency(p_tenant_id, p_command_scope, p_idempotency_key, p_status, p_result jsonb)` | `succeeded` / `failed` + `result_snapshot` |
| `inventory._post_movements(p_tenant_id, p_warehouse_id, p_intent_type, p_intent_id, p_business_date date, p_lines jsonb) returns jsonb` | Xem 4.1 |
| `inventory._open_approval(p_tenant_id, p_subject_type, p_subject_id, p_snapshot jsonb) returns uuid` | Tạo case `PENDING`; trùng → `APPROVAL_ALREADY_OPEN` |
| `inventory._decide_approval(p_tenant_id, p_case_id, p_decision text, p_reason text, p_expected_version int) returns jsonb` | Chỉ `is_owner` (khác → `PERMISSION_DENIED`); case không `PENDING` → `APPROVAL_ALREADY_DECIDED`; `REJECTED` cần lý do khác rỗng → `REASON_REQUIRED`; sai `version` → `VERSION_CONFLICT`. Chỉ đổi trạng thái case; BJ quyết bước sau |
| `inventory._activate(p_tenant_id)` | `PREPARING` → `ACTIVE` (G5-1 gọi khi tồn đầu kỳ ghi xong) |
| `inventory._available_quantity(p_tenant_id, p_product_id, p_lot_id uuid default null) returns numeric` | Σ `physical_quantity` với `SELLABLE` + `CONFIRMED`. G5-7 trừ phần đang giữ |
| `inventory._raise(p_code text, p_message text)` | `raise exception using message = jsonb_build_object('code', …, 'message', …)::text` (khuôn Sales) |

### 2.3 `_post_movements`

Mỗi phần tử `p_lines`: `{line_id, product_id, lot_code?, expiry_date?, expiry_precision?, manufacture_date?, from_state?, to_state?, valuation_state, quantity_delta, amount_vnd?, movement_kind}`. `from_state` null = hàng vào kho, `to_state` null = hàng ra kho, cả hai = đổi tình trạng (hai dòng tồn, số lượng bằng nhau trái dấu).

Thứ tự:

1. Khoá `pg_advisory_xact_lock(hash(tenant, product))` theo `product_id` tăng dần (chống khoá chéo).
2. Luật lô theo `catalog.products.tracking_mode`: `none` + có `lot_code` → `LOT_NOT_ALLOWED`; `lot` + thiếu → `LOT_REQUIRED`; `expiry_required` + thiếu hạn → `EXPIRY_REQUIRED`; lô đã có mà hạn / ngày SX khác → `LOT_ATTRIBUTE_CONFLICT`; chưa có → tạo `lots` (`origin_intent_*` = phiếu này).
3. Ghi `stock_movements` (một dòng cho mỗi tình trạng bị chạm; đổi tình trạng = 2 dòng) và `value_movements` nếu có `amount_vnd`.
4. Cập nhật `stock_balances` (upsert); dòng nào `< 0` → `INSUFFICIENT_STOCK` (kèm `product_id`), huỷ cả lệnh (INV-IO-03 / 05).
5. Trả `{movement_ids: [...], stock_changes: [{product_id, product_name, base_uom, before, after}]}` — `before` / `after` = Σ `physical_quantity` mọi tình trạng của sản phẩm trong kho, trước / sau lệnh.

Mẫu RPC của BJ (Task 9 ghi vào phần "Quy ước chung" của PLAN.md): `_assert_actor` → `_begin_idempotency` (replay → trả kết quả cũ) → luật BJ + ghi phiếu → `_post_movements` khi phiếu hoàn tất → `_complete_idempotency('succeeded', result)` → trả result. Lỗi nghiệp vụ dùng `_raise`, giao dịch tự huỷ (idempotency record `in_progress` cũng huỷ theo).

### 2.4 RPC công khai (`grant execute … to authenticated`)

| RPC | Trả về |
|---|---|
| `inventory.get_warehouse_hub_summary(p_tenant_id uuid) returns jsonb` | `{activated: bool, pending: [{source_id, label, items: [{subject_type, subject_id, title, subtitle, submitted_at}]}], problems: null, reconciliation: null}`. `pending` chỉ có khi người gọi `is_owner`; nhóm theo `subject_type`, nhãn bằng `case subject_type when … then …` (G5-0b chưa có nhánh nào; mỗi plan BJ thêm nhánh + `title` / `subtitle` của mình). `problems` / `reconciliation` do G5-9 / G5-14 điền |
| `inventory.get_command_outcome(p_tenant_id uuid, p_command_scope text, p_idempotency_key text) returns jsonb` | `{status: 'COMMITTED', result}` \| `{status: 'NOT_FOUND'}` (an toàn gửi lại đúng khoá) \| `{status: 'IN_PROGRESS'}` \| `{status: 'FAILED'}`; chỉ người cùng tenant có `inventory.read` |

Che tiền: quy ước cho mọi RPC đọc của BJ — trường tiền `null` + `financial_masked: true` khi người gọi không `is_owner`.

Quyền: `iam.has_permission` cho non-owner trả `true` với mọi mã ngoài `tenant.*` / `iam.*`; mã quyền Kho đặt theo `inventory.<bj>.<hành động>` để sau này siết được, còn "chỉ chủ cửa hàng" kiểm bằng `p_require_owner`.

### 2.5 Mã lỗi lõi (16)

`PERMISSION_DENIED`, `CONTEXT_INVALID`, `DATA_SCOPE_DENIED`, `INVENTORY_NOT_ACTIVATED`, `IDEMPOTENCY_CONFLICT`, `COMMAND_IN_PROGRESS`, `VERSION_CONFLICT`, `INSUFFICIENT_STOCK`, `LOT_REQUIRED`, `LOT_NOT_ALLOWED`, `EXPIRY_REQUIRED`, `LOT_ATTRIBUTE_CONFLICT`, `TRACKING_LOCKED`, `APPROVAL_ALREADY_OPEN`, `APPROVAL_ALREADY_DECIDED`, `REASON_REQUIRED`. Câu hiển thị theo Screen Contract của màn dùng (plan BJ); lõi chỉ có câu mặc định ở Flutter.

### 2.6 Flutter (`apps/erp/lib/features/inventory/data/core/`)

| Tệp | Nội dung |
|---|---|
| `inventory_error_codes.dart` | `enum InventoryErrorCode` (16 mã mục 6 + `unknown`); hằng mã + `inventoryErrorMessage` — **không** có lớp exception riêng (Q-b6); chữ ký đúng ở Task 6 |
| `inventory_rpc.dart` | `class InventoryRpc { Future<Map<String, dynamic>> query(String fn, Map<String, dynamic> params); Future<Map<String, dynamic>> mutate({required String scope, required String idempotencyKey, required String fn, required Map<String, dynamic> params}); Future<InventoryCommandOutcome> getCommandOutcome(String scope, String key); }` — `mutate`: lỗi có `code` → `InventoryRpcException`; `SocketException` / `TimeoutException` / `ClientException` **sau khi đã gửi** → `InventoryOutcomeUnknown(scope, key, sentAt)` |
| `inventory_command_result.dart` | `InventoryCommandResult.fromJson` (`movementIds`, `stockChanges`); `List<K4StockChange> toK4()` (định dạng `formatQuantity` + ĐVT) |
| `inventory_command_outcome.dart` | `sealed InventoryCommandOutcome`: `Committed(result)`, `NotFound`, `InProgress`, `Failed` |
| `idempotency_key.dart` | `String newIdempotencyKey()` (uuid v4) |
| `data/hub/warehouse_hub_repository.dart` (G5-0a) | thân `getSummary()` đổi sang `inventory.get_warehouse_hub_summary`; ánh xạ `subject_type` → route ở `warehouse_entries.dart` (`warehousePendingRoute(subjectType, subjectId)`, G5-0b chưa có loại nào) |

Theme 2: model / repository / form sản phẩm thêm `trackingMode`, `expiryRequired`; màn tạo sản phẩm (guided create) và màn sửa hồ sơ sản phẩm có 2 ô gạt (Q-b5); khoá khi server báo `TRACKING_LOCKED` hoặc khi `has_inventory_movements = true` (RPC đọc chi tiết sản phẩm trả thêm cờ này). Plan thực thi liệt kê đúng tệp sau khi đọc code Theme 2.

### 2.7 Ngoài phạm vi

Bảng phiếu BJ (G5-1…); giữ hàng / `ReservationBucket` (G5-7); khoá kho (G5-12); chính sách tồn / cận hạn (G5-3); ApprovalPolicy, outbox, dựng lại tồn từ sổ; seed dữ liệu.

## 3. Tệp

| Tệp | Tạo / sửa | Task |
|---|---|---|
| `supabase/migrations/20260709001_catalog_guided_create.sql` (bảng `catalog.products`, dòng 38–62) | sửa | 1 |
| `supabase/migrations/20260722001_catalog_pending_automatic_price_bands.sql` (`create_guided_product`, bản mới nhất) | sửa | 1 |
| `supabase/migrations/20260717005_catalog_product_code_reuse_after_soft_delete_rpcs.sql` (`update_product_profile`, bản mới nhất) | sửa | 1 |
| `supabase/migrations/20260725019_catalog_search_pcc_price_after_vat.sql` (`get_product_control_center`, dòng ~343–352) | sửa | 1 |
| `supabase/migrations/20261110001_inventory_core.sql` | tạo | 2–5 |
| `supabase/migrations/REGISTRY.yaml` | sửa (owner migration mới) | 2 |
| `supabase/tests/inventory_core.sql` | tạo | 2–5 |
| `apps/erp/test/features/inventory/data/inventory_core_sql_contract_test.dart` | tạo | 1–5 |
| `apps/erp/lib/features/inventory/data/core/{inventory_error_codes,inventory_rpc,inventory_command_result,inventory_command_outcome,idempotency_key}.dart` | tạo | 6 |
| `apps/erp/test/features/inventory/data/core/*_test.dart` | tạo | 6 |
| `apps/erp/lib/features/inventory/data/hub/warehouse_hub_repository.dart`, `presentation/hub/warehouse_entries.dart`, `core/di/injection.dart` | sửa | 7 |
| Theme 2: `data/models/product_inputs.dart`, `data/models/product_control_center.dart`, `data/product_repository.dart`, `logic/product_guided_create_{state,cubit}.dart`, `logic/product_profile_maintenance_cubit.dart`, `presentation/widgets/product_guided_step_identification.dart`, `presentation/pages/product_profile_maintenance_page.dart`, `presentation/models/product_list_item_model.dart`, `presentation/mappers/catalog_ui_mapper.dart`, fake repository của test catalog | sửa | 8 |
| `specs/themes/theme-07/02.specification/domain/{domain-foundation/DOM-IO.md, entities/ENT-IO-03…, ENT-IO-06…, ENT-IC-01…, ENT-IC-02…, ENT-IV-02…, read-models/PRJ-IO-01…}`, `specs/themes/theme-07/README.md:131`, `docs/refactor/PLAN.md` | sửa | 9 |

## 4. Các task

### Task 0: Mốc test Catalog (bước 0 giữ hành vi)

Task 1 và 8 sửa RPC / form sản phẩm đang chạy (chỉ **thêm** tham số có mặc định). Hành vi cũ được giữ bằng test Catalog đã có.

- [ ] **Step 1:** `cd apps/erp && flutter test --no-pub -r compact test/features/catalog` → ghi số đạt / lỗi vào Kết quả (đối chiếu `TEST-BASELINE.md`: 2 lỗi ⚠️ `product_guided_create_e2e_test` duplicate SKU, `product_change_history_e2e_test` là lỗi có sẵn).
- [ ] **Step 2:** Không commit (chỉ đo).

### Task 1: Hai cột sản phẩm + RPC Catalog nhận / trả

**Files:** Modify 4 migration Catalog ở mục 3; Create `inventory_core_sql_contract_test.dart` (nhóm `catalog`).

**Interfaces — Produces:**
- `catalog.products`: `tracking_mode text not null default 'none'`, `expiry_required boolean not null default false`, `constraint chk_products_tracking_mode check (tracking_mode in ('none', 'lot'))`, `constraint chk_products_expiry_requires_lot check (not expiry_required or tracking_mode = 'lot')`.
- `catalog.create_guided_product(…, p_tracking_mode text default 'none', p_expiry_required boolean default false)` — thêm **cuối** danh sách tham số, ghi vào `insert`.
- `catalog.update_product_profile(…, p_tracking_mode text default null, p_expiry_required boolean default null)` — `null` = giữ giá trị cũ (`coalesce`).
- `get_product_control_center` → object hồ sơ (cạnh `'trade_name'`) thêm `'tracking_mode'`, `'expiry_required'`, `'has_inventory_movements', exists (select 1 from inventory.stock_movements m where m.tenant_id = p_tenant_id and m.product_id = p.id)`.
- Cập nhật `revoke` / `grant` theo chữ ký mới của 2 RPC (cùng tệp).

- [ ] **Step 1: Test** nhóm `catalog` trong `inventory_core_sql_contract_test.dart` (đọc tệp như `catalog_sql_contract_test.dart`, dùng lại `_findRepoRoot` / `_functionDefinition` chép vào tệp mới):
  - `products_has_tracking_columns`: `20260709001…` chứa `tracking_mode text not null default 'none'`, `expiry_required boolean not null default false`, `chk_products_tracking_mode`, `chk_products_expiry_requires_lot`.
  - `guided_create_accepts_tracking`: thân `create_guided_product` chứa `p_tracking_mode text default 'none'`, `p_expiry_required boolean default false`.
  - `profile_update_keeps_tracking_when_null`: thân `update_product_profile` chứa `p_tracking_mode text default null` và `coalesce(p_tracking_mode`.
  - `pcc_returns_tracking_and_movements_flag`: thân `get_product_control_center` chứa `'tracking_mode'`, `'expiry_required'`, `'has_inventory_movements'`.
- [ ] **Step 2:** `flutter test --no-pub test/features/inventory/data/inventory_core_sql_contract_test.dart` → FAIL.
- [ ] **Step 3:** `impact` 3 RPC; sửa 4 tệp.
- [ ] **Step 4:** test trên → PASS; `flutter test --no-pub test/features/catalog/data/catalog_sql_contract_test.dart` → PASS.
- [ ] **Step 5:** Commit `feat(catalog): tracking_mode + expiry_required cho sản phẩm (T7-G5-0b)`.

### Task 2: Bảng lõi, sổ chỉ thêm, khoá đổi theo dõi lô

**Files:** Create `20261110001_inventory_core.sql` (phần bảng), `supabase/tests/inventory_core.sql` (khung + ca của task); Modify `REGISTRY.yaml`; test nhóm `schema`.

**Interfaces — Produces** (đúng mục 2.1): bảng `inventory.tenant_inventory_settings`, `inventory.ledger_counters (tenant_id uuid primary key, last_sequence bigint not null default 0)`, `inventory.lots`, `inventory.stock_movements`, `inventory.stock_balances`, `inventory.value_movements`, `inventory.approval_cases`; hằng `stock_state` 7 giá trị, `valuation_state` 2 giá trị (check constraint tên `chk_*_stock_state`, `chk_*_valuation_state`); hàm trigger `inventory._forbid_ledger_mutation()` gắn `before update or delete` cho `stock_movements` và `value_movements` → `_raise('CONTEXT_INVALID', 'Ledger is append-only.')`; hàm trigger `catalog._lock_tracking_after_movement()` gắn `before update of tracking_mode, expiry_required on catalog.products` → nếu đổi giá trị và `exists` dòng `inventory.stock_movements` của sản phẩm → `inventory._raise('TRACKING_LOCKED', …)`. **Task này dựng luôn `inventory._raise(p_code text, p_message text) returns void`** (mục 2.2) ở đầu migration, trước các trigger dùng nó.

- [ ] **Step 1: Test** nhóm `schema`: `core_tables_exist` (7 bảng + `ledger_counters`); `rls_and_revoke_for_every_table` (mỗi bảng có `enable row level security` và `revoke all on inventory.<bảng>`); `stock_state_values` (đủ `'SELLABLE', 'QUARANTINE', 'DAMAGED', 'EXPIRED', 'DEMO', 'RETURN_PENDING', 'RTV_PENDING'`); `balance_unique_key` (`unique (tenant_id, warehouse_id, product_id, stock_state, valuation_state, lot_key)`), `physical_quantity >= 0`; `ledger_append_only_trigger` (2 trigger `before update or delete`); `tracking_lock_trigger` (`before update of tracking_mode, expiry_required on catalog.products`); `pending_case_unique` (`where status = 'PENDING'`).
  Ca SQL (`inventory_core.sql`, mỗi ca `raise exception 'FAIL: <tên>'` khi sai, cuối `raise notice 'inventory_core: OK'`): `ledger_update_blocked`, `ledger_delete_blocked`, `tracking_change_after_movement_locked` (chèn 1 dòng sổ trực tiếp bằng quyền chủ DB rồi `update catalog.products set tracking_mode = 'lot'` → bắt `TRACKING_LOCKED`), `tracking_change_without_movement_ok`.
- [ ] **Step 2:** contract test → FAIL. **Step 3:** viết phần bảng / trigger. **Step 4:** PASS.
- [ ] **Step 5:** Commit `feat(inventory): bảng lõi Kho, sổ chỉ thêm (T7-G5-0b)`.

### Task 3: Helper kiểm người gọi, idempotency, kích hoạt, khả dụng

**Files:** Modify `20261110001_inventory_core.sql`, `supabase/tests/inventory_core.sql`; test nhóm `helpers`.

**Interfaces — Produces** (chữ ký mục 2.2):
- `inventory._assert_actor(p_tenant_id uuid, p_permission text, p_require_owner boolean default false, p_allow_preparing boolean default false) returns jsonb` → `{actor_id, is_owner, store_id, warehouse_id}`. Thứ tự kiểm: `auth.uid()` null → `PERMISSION_DENIED`; `iam.has_permission` false → `PERMISSION_DENIED`; `p_require_owner` và không `is_owner` (`iam.memberships`) → `PERMISSION_DENIED`; không có đúng 1 `store_warehouse_assignments` `active` → `CONTEXT_INVALID`; `activation_status` ≠ `ACTIVE` (không dòng = `PREPARING`) và không `p_allow_preparing` → `INVENTORY_NOT_ACTIVATED`.
- `inventory._begin_idempotency(p_tenant_id uuid, p_command_scope text, p_idempotency_key text, p_payload_hash text) returns jsonb` → `{decision: 'new'|'replay'|'in_progress', result?}`; khác hash → `IDEMPOTENCY_CONFLICT`; chép thân `sales._begin_sales_idempotency` (`20260830006`), đổi bảng sang `inventory.idempotency_records`, mã lỗi qua `_raise`.
- `inventory._complete_idempotency(p_tenant_id uuid, p_command_scope text, p_idempotency_key text, p_status text, p_result jsonb) returns void` (`p_status in ('succeeded','failed')`).
- `inventory._activate(p_tenant_id uuid) returns void` (upsert `ACTIVE`, `activated_at = now()`, `activated_by = auth.uid()`).
- `inventory._available_quantity(p_tenant_id uuid, p_product_id uuid, p_lot_id uuid default null) returns numeric`.

- [ ] **Step 1: Test** nhóm `helpers`: `helpers_not_granted` (mỗi hàm `_` có `revoke execute on function inventory.<tên>` và **không** có `grant execute on function inventory.<tên>`); `assert_actor_checks_in_order` (vị trí chuỗi `has_permission` < `is_owner` < `store_warehouse_assignments` < `INVENTORY_NOT_ACTIVATED` trong thân); `idempotency_conflict_code`; `available_counts_sellable_confirmed` (thân `_available_quantity` chứa `'SELLABLE'` và `'CONFIRMED'`).
  Ca SQL: `not_activated_blocks`, `preparing_allowed_when_flag`, `non_owner_require_owner_denied`, `replay_same_hash_returns_saved_result`, `same_key_other_hash_conflict`, `activate_sets_active`.
- [ ] **Step 2–4:** FAIL → viết → PASS. **Step 5:** Commit `feat(inventory): helper người gọi + idempotency (T7-G5-0b)`.

### Task 4: `_post_movements`

**Files:** Modify `20261110001_inventory_core.sql`, `supabase/tests/inventory_core.sql`; test nhóm `post_movements`.

**Interfaces — Produces:** `inventory._post_movements(p_tenant_id uuid, p_warehouse_id uuid, p_intent_type text, p_intent_id uuid, p_business_date date, p_lines jsonb) returns jsonb` — dòng vào / kết quả theo **mục 2.3** (5 bước, đúng thứ tự). Thêm quy ước:
- `ledger_sequence`: `update inventory.ledger_counters set last_sequence = last_sequence + 1 … returning` (insert dòng counter nếu chưa có), một số cho mỗi dòng sổ.
- Đổi tình trạng (`from_state` và `to_state` cùng có): 2 dòng sổ (`-q` ở `from_state`, `+q` ở `to_state`), cùng `lot`, cùng `valuation_state`.
- `amount_vnd` có → 1 dòng `value_movements` / dòng vào (dấu theo `quantity_delta`).
- `stock_changes[].product_name` = `catalog.products.name`; `base_uom` = tên đơn vị `is_base_unit` (`catalog._product_base_unit_name(p_tenant_id, p_product_id)` đã có).
- `lot_key` khi không lô = `'00000000-0000-0000-0000-000000000000'::uuid`.

- [ ] **Step 1: Test** nhóm `post_movements`: `advisory_lock_before_balance_read` (vị trí `pg_advisory_xact_lock` < vị trí `from inventory.stock_balances` đầu tiên trong thân); `lot_rules_codes` (thân chứa `LOT_NOT_ALLOWED`, `LOT_REQUIRED`, `EXPIRY_REQUIRED`, `LOT_ATTRIBUTE_CONFLICT`); `insufficient_stock_code`; `returns_stock_changes` (`'stock_changes'`, `'before'`, `'after'`).
  Ca SQL: `receive_increases_balance_and_reports_change` (vào 10 → `before 0`, `after 10`); `issue_more_than_stock_insufficient`; `insufficient_stock_rolls_back_all_lines` (2 dòng, dòng 2 thiếu → bắt lỗi trong `begin … exception`, rồi đếm `stock_movements` của `intent_id` = 0); `state_change_two_rows_total_unchanged` (SELLABLE → QUARANTINE 2: `after == before`); `lot_none_with_code_rejected`; `lot_required_rejected`; `expiry_required_rejected`; `lot_same_code_other_expiry_conflict`; `lot_created_once` (2 lần nhận cùng mã → 1 dòng `lots`); `value_movement_written_when_amount`.
- [ ] **Step 2–4:** FAIL → viết → PASS. **Step 5:** Commit `feat(inventory): _post_movements ghi sổ + tồn (T7-G5-0b)`.

### Task 5: Duyệt K2 + RPC công khai

**Files:** Modify `20261110001_inventory_core.sql`, `supabase/tests/inventory_core.sql`; test nhóm `approval_public`.

**Interfaces — Produces:**
- `inventory._open_approval(p_tenant_id uuid, p_subject_type text, p_subject_id uuid, p_snapshot jsonb) returns uuid` (snapshot phải có `title`, `subtitle` — Q-b8; trùng `PENDING` → `APPROVAL_ALREADY_OPEN`).
- `inventory._decide_approval(p_tenant_id uuid, p_case_id uuid, p_decision text, p_reason text, p_expected_version int) returns jsonb` → `{case_id, status, version, decided_at}`; luật mục 2.2; `p_decision in ('APPROVED','REJECTED')`.
- `inventory.get_warehouse_hub_summary(p_tenant_id uuid) returns jsonb` (mục 2.4): quyền `inventory.read` qua `_assert_actor(p_tenant_id, 'inventory.read', false, true)`; `pending` = `[]` khi không `is_owner`; nhãn nhóm: `case subject_type … else subject_type end` — G5-0b **không có nhánh nào** (ghi chú `-- Mỗi plan BJ thêm: when '<subject_type>' then '<nhãn>'`).
- `inventory.get_command_outcome(p_tenant_id uuid, p_command_scope text, p_idempotency_key text) returns jsonb` → `status`: `succeeded` → `COMMITTED` (+ `result` = `result_snapshot`), `in_progress` → `IN_PROGRESS`, `failed` → `FAILED`, không có → `NOT_FOUND`.

- [ ] **Step 1: Test** nhóm `approval_public`: `public_rpcs_granted_definer` (2 RPC có `security definer`, `set search_path`, `grant execute … to authenticated`); `decide_owner_only_and_reason` (thân có `REASON_REQUIRED`, `APPROVAL_ALREADY_DECIDED`, `VERSION_CONFLICT`); `hub_summary_shape` (`'activated'`, `'pending'`, `'problems'`, `'reconciliation'`); `outcome_statuses` (`'COMMITTED'`, `'NOT_FOUND'`, `'IN_PROGRESS'`, `'FAILED'`); `all_core_error_codes_present` (16 mã mục 2.5 đều xuất hiện trong tệp migration).
  Ca SQL: `open_twice_already_open`; `non_owner_decide_denied`; `reject_without_reason`; `decide_twice_already_decided`; `stale_version_conflict`; `hub_summary_non_owner_no_pending`; `hub_summary_activated_flag`; `outcome_not_found_then_committed`.
- [ ] **Step 2–4:** FAIL → viết → PASS. **Step 5:** Commit `feat(inventory): duyệt K2 + RPC Hub / xác minh (T7-G5-0b)`.

### Task 6: Lớp Flutter lõi

**Files:** Create `apps/erp/lib/features/inventory/data/core/inventory_error_codes.dart`, `inventory_rpc.dart`, `inventory_command_result.dart`, `inventory_command_outcome.dart`, `idempotency_key.dart` + `test/features/inventory/data/core/inventory_rpc_test.dart`, `inventory_command_result_test.dart`.

**Interfaces — Consumes:** `SupabaseRpc` (`lib/core/supabase/supabase_rpc.dart`), `AppException`, `AppErrorCode`, `K4StockChange` (G5-0a), `formatQuantity` (`logic/receipt_rules.dart`). **Produces:**
- `abstract final class InventoryErrorCode` — 16 hằng chuỗi ở mục 2.5, trừ `PERMISSION_DENIED` dùng `AppErrorCode.noPermission`.
- `String inventoryErrorMessage(AppException error, {required String fallback, Map<String, String> overrides = const {}})` — `overrides[code] ?? (mã thuộc AppErrorCode chung ? error.userMessage() : fallback)`.
- `final class InventoryOutcomeUnknown implements Exception { final String scope; final String idempotencyKey; final DateTime sentAt; }`.
- `sealed class InventoryCommandOutcome` → `InventoryCommandCommitted(Map<String, dynamic> result)`, `InventoryCommandNotFound()`, `InventoryCommandInProgress()`, `InventoryCommandFailed()`.
- `class InventoryRpc { InventoryRpc({required SupabaseRpc rpc, required Future<String> Function() tenantId, DateTime Function()? now}); Future<Map<String, dynamic>> query(String fn, [Map<String, dynamic> params = const {}]); Future<Map<String, dynamic>> mutate({required String scope, required String idempotencyKey, required String fn, required Map<String, dynamic> params}); Future<InventoryCommandOutcome> getCommandOutcome(String scope, String idempotencyKey); }` — schema `inventory`; tự thêm `p_tenant_id`; `mutate` thêm `p_idempotency_key`; `AppException` có `code == AppErrorCode.network` trong `mutate` → ném `InventoryOutcomeUnknown(scope, key, now())` (Q-b7); lỗi khác ném nguyên `AppException`.
- `final class InventoryStockChange { productId, productName, baseUom, before (num), after (num) }`; `final class InventoryCommandResult { List<String> movementIds; List<InventoryStockChange> stockChanges; factory fromJson(Map<String, dynamic>); List<K4StockChange> toK4(); }` — `toK4` = `K4StockChange(product: productName, before: '${formatQuantity(before)} $baseUom', after: …)`.
- `String newIdempotencyKey()` → `const Uuid().v4()`.

- [ ] **Step 1: Test** (fake `SupabaseRpc` bằng lớp con ghi lại lời gọi / ném lỗi):
  - `query_adds_tenant_id`, `mutate_adds_tenant_and_key`.
  - `mutate_network_error_throws_outcome_unknown` (fake ném `AppException(AppErrorCode.network)` → `InventoryOutcomeUnknown` có đúng `scope`, `idempotencyKey`).
  - `mutate_business_error_rethrows_app_exception` (`AppException('INSUFFICIENT_STOCK')` giữ nguyên `code`).
  - `outcome_maps_four_statuses` + `outcome_not_found_safe_to_resend` (`{status: 'NOT_FOUND'}` → `InventoryCommandNotFound`).
  - `result_from_json_and_to_k4` (`{movement_ids: ['m1'], stock_changes: [{product_id: 'p', product_name: 'Nobivac DHPPi', base_uom: 'hộp', before: 120, after: 122}]}` → `toK4().single.before == '120 hộp'`, `.after == '122 hộp'`).
  - `error_message_override_then_fallback`.
- [ ] **Step 2–4:** FAIL → viết → `flutter test --no-pub test/features/inventory/data/core` PASS. **Step 5:** Commit `feat(inventory): lớp RPC Flutter lõi (T7-G5-0b)`.

### Task 7: Hub đọc RPC

**Files:** Modify `data/hub/warehouse_hub_repository.dart`, `presentation/hub/warehouse_entries.dart`, `core/di/injection.dart`; Test `test/features/inventory/data/hub/warehouse_hub_repository_test.dart`.

**Interfaces — Consumes:** `InventoryRpc` (Task 6), `WarehouseHubSummary` / `WarehousePendingGroup` / `WarehousePendingItem` (G5-0a). **Produces:**
- `WarehouseHubRepository({required InventoryRpc rpc})` (bỏ `const`); `getSummary()` = `rpc.query('get_warehouse_hub_summary')` → model; `items[]` có `subject_type` mà `warehousePendingRoute` trả `null` thì **bỏ** dòng (lối vào chưa có màn, Q9).
- `warehouse_entries.dart`: `String? warehousePendingRoute(String subjectType, String subjectId)` — G5-0b trả `null` cho mọi loại; `VIcons warehousePendingIcon(String subjectType)` mặc định `VIcons.inbox`.
- DI: `registerLazySingleton<InventoryRpc>(() => InventoryRpc(rpc: getIt<SupabaseRpc>(), tenantId: () async => getIt<SessionStore>().tenantId!))`; `WarehouseHubRepository(rpc: getIt<InventoryRpc>())`.
- Test G5-0a đang tạo `const WarehouseHubRepository()` → đổi sang fake (`class FakeWarehouseHubRepository extends WarehouseHubRepository` trả summary đặt sẵn) trong `test/features/inventory/support/`.

- [ ] **Step 1: Test:** `parses_activated_and_pending` (JSON 1 nhóm 2 việc, `warehousePendingRoute` thử bằng tham số — đưa resolver vào constructor: `WarehouseHubRepository({required InventoryRpc rpc, String? Function(String, String) pendingRoute = warehousePendingRoute})`); `drops_items_without_route`; `null_problems_stay_null`.
- [ ] **Step 2–4:** FAIL → viết → PASS; `flutter test --no-pub test/features/inventory` không thêm lỗi. **Step 5:** Commit `feat(inventory): Hub đọc RPC tóm tắt (T7-G5-0b)`.

### Task 8: Theme 2 — ô gạt theo dõi lô

**Files:** mục 3 dòng "Theme 2". Tìm hết chỗ dữ liệu hồ sơ đi qua bằng `grep -rn "tradeName" apps/erp/lib/features/catalog apps/erp/test/features/catalog` và đi **đúng đường của `tradeName`** cho 3 trường mới.

**Interfaces — Produces:**
- `enum ProductTrackingMode { none, lot }` (`data/models/catalog_enums.dart`; `fromWire('none'|'lot')`, `wire`).
- `CreateGuidedProductInput(…, ProductTrackingMode trackingMode = ProductTrackingMode.none, bool expiryRequired = false)` → `createGuided` gửi `p_tracking_mode`, `p_expiry_required`.
- `ProductRepository.updateProfile(…, ProductTrackingMode? trackingMode, bool? expiryRequired)` → gửi khi khác `null`.
- `ProductProfileSummaryDto` thêm `trackingMode` (mặc định `none` khi thiếu khoá), `expiryRequired` (`false`), `hasInventoryMovements` (`false`); `ProductListItemModel` + `catalog_ui_mapper` mang theo.
- `ProductGuidedCreateState` / Cubit: `trackingMode`, `expiryRequired`, `setTrackingMode(ProductTrackingMode)` (về `none` thì `expiryRequired = false`), `setExpiryRequired(bool)`.
- `ProductProfileMaintenanceCubit(…, initialTrackingMode, initialExpiryRequired, trackingLocked)` + 2 setter như trên; lưu chỉ gửi khi đổi.
- UI: trong `product_guided_step_identification.dart` và `product_profile_maintenance_page.dart`, sau ô mã vạch: `VSwitch` `Quản lý theo lô`; `VSwitch` `Bắt buộc hạn dùng` (tắt khi chưa bật lô); khi `trackingLocked` (= `hasInventoryMovements`) cả hai tắt + dòng `VText` `Đã có biến động kho, không đổi được.`; lỗi server `TRACKING_LOCKED` → hiện cùng câu đó ở dòng lỗi chung của form.

- [ ] **Step 1: Test** (thêm vào test page / cubit Catalog đã có, fake repository ghi tham số):
  - `guided_create_sends_tracking` (bật lô + hạn dùng → input `trackingMode == lot`, `expiryRequired == true`).
  - `expiry_toggle_disabled_until_lot`; `turning_lot_off_clears_expiry`.
  - `profile_update_sends_tracking_only_when_changed`.
  - `toggles_locked_when_has_movements` (cả hai `VSwitch` `onChanged == null`, có `'Đã có biến động kho, không đổi được.'`).
  - `pcc_dto_defaults_when_keys_missing`.
- [ ] **Step 2–4:** FAIL → `impact` các symbol ở Global Constraints → viết → `flutter test --no-pub test/features/catalog` số lỗi ≤ mốc Task 0.
- [ ] **Step 5:** Commit `feat(catalog): ô gạt Quản lý theo lô / Bắt buộc hạn dùng (T7-G5-0b)`.

### Task 9: Domain, README, PLAN.md, kiểm cuối

- [ ] **Step 1 (Q8):** mỗi tệp domain ở mục 3 thêm mục cuối `## Hiện thực Phase 1 (T7-G5-0b)`: tên bảng / hàm (mục 2.1–2.4), phần bỏ theo Q-b1; ENT-IC-01: `Phase 1 không hiện thực (Q-b1): người duyệt = is_owner`. Tệp đang `status: DRAFT` → `FROZEN` + `frozen_at: v5.27.0`. README theme dòng 131: `v5.0.0` → `v5.27.0`.
- [ ] **Step 2:** PLAN.md mục Theme 7 → "Quy ước chung" → "Cấu trúc code" thêm dòng **"Mẫu RPC ghi của BJ"**: `_assert_actor` → `_begin_idempotency` (replay → trả kết quả cũ) → luật BJ + ghi phiếu → `_post_movements` khi hoàn tất → `_complete_idempotency('succeeded', result)`; chờ duyệt dùng `_open_approval` / `_decide_approval` + thêm nhánh nhãn vào `get_warehouse_hub_summary` + `warehousePendingRoute`. Bảng Plan dòng G5-0b: cột Làm `✅ {ngày}`.
- [ ] **Step 3:** `cd apps/erp && dart analyze lib/features/inventory lib/features/catalog lib/core test/features/inventory test/features/catalog` → 0 lỗi; `flutter test --no-pub -r compact` → không vượt mốc `TEST-BASELINE.md` ("Sau 7-C": 55 lỗi).
- [ ] **Step 4:** `detect_changes({scope: "compare", base_ref: "main"})` → ghi Kết quả.
- [ ] **Step 5:** Commit `docs(spec): T7-G5-0b hiện thực Phase 1 vào domain + PLAN.md`.

## 5. Rủi ro / lưu ý

- Sửa migration đã áp dụng (4 tệp Catalog) ⇒ Dev phải dựng lại; **người dùng** quyết khi nào (không ghi bước).
- `get_product_control_center` (2025-07) tham chiếu `inventory.stock_movements` (migration 2026-11): plpgsql chỉ phân giải lúc chạy nên tạo hàm được; nhưng gọi PCC trước khi áp migration lõi sẽ lỗi — trên DB dựng lại đủ bộ thì không xảy ra.
- `iam.has_permission` cho nhân viên mọi mã ngoài `tenant.*` / `iam.*` ⇒ `inventory.read` luôn đúng với thành viên; "chỉ chủ" phải qua `p_require_owner`.

## 6. Kết quả (phiên làm code ghi)

Xong **mỗi task** ghi ngay; dừng giữa chừng ghi `🔄 dở` + tới bước nào.

```
### Task N (YYYY-MM-DD) — ✅ / 🔄 / ⏭
- Commit:
- Tệp:dòng đã đổi:
- Lệch plan + lý do:
- Test thêm / sửa (tên):
- Impact (symbol → mức, số caller):
- Ghi chú cho review:
```

Task 9 thêm: lệnh đã chạy, đạt / lỗi, tên test hỏng đối chiếu `TEST-BASELINE.md`, kết quả `detect_changes`.

## 7. Review

(Phiên review ghi.)
