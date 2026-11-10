# T7-G5-0b — Backend lõi Kho

> Theme 7 · plan **G5-0b** của [PLAN.md](../../PLAN.md) mục "Theme 7" (bảng Plan)
> Trạng thái: Plan ✅ **bản sửa theo rút gọn + [spec giá vốn](T7-G5-gia-von-thiet-ke.md), người dùng duyệt 2026-11-09** | Làm ✅ 2026-11-10 | Review ✅ R3 đạt (2026-11-10; R1, R2 ❌) — còn nợ chạy `supabase/tests/inventory_core.sql`
> Thiết kế: mục 2 của plan này. Phạm vi: PLAN.md mục Theme 7 → "Rút gọn 2026-11-09", "Giá vốn"; giá vốn: [spec giá vốn](T7-G5-gia-von-thiet-ke.md) mục 3–4 (G5-0b) — lần tính / công bố (mục 5–7) thuộc G5-6.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Có schema + helper SQL + RPC đọc + lớp Flutter dùng chung để mọi plan G5 ghi tồn **và sổ giá trị (giá vốn theo phương pháp của cửa hàng)** đúng bất biến chỉ bằng cách gọi lõi; sản phẩm có `tracking_mode` / `expiry_required`; Hub đọc RPC thật và không còn phần đã bỏ (Chờ duyệt, lối vào BJ bị bỏ).

**Architecture:** Một migration `20261110001_inventory_core.sql` chứa bảng, trigger, helper `_…` (không cấp cho `authenticated`) và 1 RPC công khai. Hai cột sản phẩm sửa thẳng migration gốc của Catalog (đã làm, Task 1). Flutter có `features/inventory/data/core/` bọc `SupabaseRpc` + `AppException`; Hub (G5-0a) đổi thân repository sang RPC và gỡ "Chờ duyệt".

**Tech Stack:** PostgreSQL / Supabase (plpgsql, RLS), Flutter, `supabase` Dart, `get_it`, `flutter_bloc`.

**Spec:** mục 1–2 của plan này + [spec giá vốn](T7-G5-gia-von-thiet-ke.md) mục 3–4 + PLAN.md mục Theme 7 → "Rút gọn 2026-11-09", "Giá vốn", "Quy ước chung cho mọi plan G5".

## Global Constraints

- **Không** ghi / chạy bước DB nào (reset, push, `psql`): người dùng tự làm. Test SQL chạy tay (`supabase/tests/inventory_core.sql`) chỉ **viết**, người dùng chạy.
- `20261110001_inventory_core.sql` đã commit ở Task 2 nhưng chưa lên Prod ⇒ Task 2b **sửa thẳng tệp này** (không tạo migration ghi đè). Đối tượng Catalog đã có → sửa thẳng tệp đang giữ định nghĩa mới nhất (Task 1, đã xong).
- Header migration theo khuôn `20261104001_inventory_default_pair.sql` (`-- Title / Kind / Intent / Context / Touches / Safety / Depends on`). Kind `schema`. Task 2b sửa dòng `Touches` theo bảng thật.
- Mọi bảng: RLS bật + `revoke all … from public, anon, authenticated`. Helper tên bắt đầu `_`: `revoke execute … from public, anon, authenticated`. RPC công khai: `security definer`, `set search_path = inventory, iam, catalog, pg_temp`, `grant execute … to authenticated`.
- Lỗi nghiệp vụ chỉ qua `inventory._raise(code, message)` → `{"code", "message"}`; 14 mã ở mục 2.5, đúng chính tả.
- Tiền `bigint` (đồng), đơn giá `numeric(18,4)`; `amount_vnd = round(quantity × unit_cost)` (làm tròn nửa lên, `round()` của PostgreSQL với `numeric`), trừ khi người gọi truyền sẵn `amount_vnd` (giá gốc đã phân bổ, G5-3).
- Flutter: lỗi là `AppException` (lớp `final`, không kế thừa, Q-b6); `AppException.from` đã đọc JSON `{code}` và đổi `PERMISSION_DENIED` → `NO_PERMISSION`.
- Chữ Theme 2 nguyên văn: `Quản lý theo lô`, `Bắt buộc hạn dùng`, `Đã có biến động kho, không đổi được.`
- `dart analyze` (không dùng `flutter analyze`). Test: `flutter test --no-pub -r compact`.
- Trước khi sửa symbol đã có (`create_guided_product`, `update_product_profile`, `get_product_control_center`, `ProductRepository.createGuided` / `updateProfile`, `ProductProfileSummaryDto`, `WarehouseHubRepository.getSummary`, `WarehouseHubSummary`, `warehouseAreaEntries`, `warehouseQuickActions`, `WarehouseHubPage`, `buildWarehouseHubRoutes`): chạy `impact` (GitNexus), ghi blast radius vào Kết quả; HIGH / CRITICAL → dừng, báo người dùng. Trước commit: `detect_changes()`.
- Xoá code (Task 7: K2, K3, "Chờ duyệt"): theo PLAN.md "Plan xoá / tách / thay code cũ" — bước 0 chạy test Hub / patterns ghi mốc; sau khi xoá `grep` không còn chỗ gọi.
- `AGENTS.md`, `CLAUDE.md`: không `git add`. Ghi mục 6 Kết quả sau mỗi task; không ghi mục Review.

## Review Focus

1. **Hai người cùng xuất lô cuối cùng** ⇒ không được âm, không treo. `_post_movements` khoá theo sản phẩm tăng dần rồi mới đọc tồn. Test: Task 4 `advisory_lock_before_balance_read` + ca SQL `insufficient_stock_rolls_back_all_lines`.
2. **Lệnh 2 dòng, dòng 2 thiếu hàng** ⇒ dòng 1 không còn trong cả hai sổ, `product_costs` không đổi. Test: Task 4 ca SQL `insufficient_stock_rolls_back_all_lines` (đếm `stock_movements` / `value_movements` = 0, `product_costs` như trước).
3. **App mất mạng sau khi gửi rồi bấm "Thử lại"** ⇒ không ghi hai lần. Test: Task 3 ca SQL `replay_same_hash_returns_saved_result`; Task 6 `mutate_network_error_rethrows_network` + `retry_uses_same_key` (khoá do người gọi giữ).
4. **Sổ giá trị đúng từng đồng theo phương pháp** (spec giá vốn mục 4, ví dụ Nobivac mục 5.1 bước 1–4): `MOVING` xuất theo liên hoàn; `PERIODIC` xuất theo giá chính thức, chưa có thì giá tạm; huỷ / trả đảo đúng giá dòng gốc; kỳ đã chốt bị chặn; `ledger_value_vnd = Σ amount_vnd` sau mọi ca. Test: Task 4 ca `nobivac_moving_steps`, `nobivac_periodic_provisional`, `periodic_uses_official_version`, `sale_reversal_exact`, `return_in_original_cost`, `period_closed_blocked`, `ledger_value_invariant`.
5. **Đổi sản phẩm sang "Quản lý theo lô" khi đã có tồn không lô** ⇒ chặn. Test: Task 2 ca SQL `tracking_change_after_movement_locked`; Task 8 `toggles_locked_when_has_movements`.
6. **Không còn đường vào phần đã bỏ**: Hub không còn "Chờ duyệt", `/warehouse/approvals`, K2, K3, lối vào BJ bị bỏ. Test: Task 7 `hub_has_no_pending_row`, `area_entries_only_kept_bj`; `grep` ở Task 7 Step 4.

---

## 1. Quyết định

Q-b1…Q-b9: bản đầu (2026-11-09). Q-b10…Q-b15: sửa theo rút gọn Theme 7 (người dùng duyệt 2026-11-09). Q-b12 (sửa), Q-b16…Q-b18: theo spec giá vốn (người dùng duyệt 2026-11-09).

| Q | Nội dung |
|---|---|
| Q-b1 | **Giữ bất biến, bỏ hạ tầng doanh nghiệp.** Giữ: sổ chỉ thêm, tồn cập nhật cùng giao dịch, lô, idempotency, chặn tồn âm. ~~Phiếu duyệt, UNKNOWN xác minh, kích hoạt kho~~ (bỏ — Q-b10). Bỏ: ApprovalPolicy, outbox / event, job dựng lại tồn, phong bì kết quả đầy đủ |
| Q-b2 | **`tracking_mode` + `expiry_required` thêm vào `catalog.products`**, có ô gạt ở màn tạo / sửa sản phẩm Theme 2 (✅ Task 1) |
| Q-b3 | **Đường ghi = một hàm lõi `inventory._post_movements`** (không trigger cập nhật tồn, không tính tồn bằng `SUM`) — nay tính luôn giá vốn bình quân (Q-b12) |
| Q-b4 | ~~Bỏ `SELF_APPROVAL_NOT_ALLOWED`~~ — hết nghĩa (không còn duyệt) |
| Q-b5 | Chữ màn sản phẩm: `Quản lý theo lô`, `Bắt buộc hạn dùng`, `Đã có biến động kho, không đổi được.` |
| Q-b6 | **Không có `InventoryRpcException`**: dùng `AppException.code` + hằng `InventoryErrorCode`. Lỗi mạng = `AppException.code == AppErrorCode.network` |
| Q-b7 | ~~Lỗi mạng của `mutate` = UNKNOWN~~ → **Lỗi mạng ném lại nguyên `AppException(network)`**; UI báo lỗi + "Thử lại"; Cubit giữ khoá idempotency của lần gửi đầu nên gửi lại không ghi hai lần (server `replay`) |
| Q-b8 | ~~`title` / `subtitle` trong `approval_cases.snapshot`~~ — hết nghĩa |
| Q-b9 | Sai `tracking_mode` / `expiry_required` dựa vào check constraint + UI chặn; không thêm mã lỗi |
| Q-b10 | **Bỏ khỏi lõi:** `approval_cases`, `_open_approval`, `_decide_approval`, `tenant_inventory_settings`, `_activate`, `INVENTORY_NOT_ACTIVATED`, `get_command_outcome`, `InventoryOutcomeUnknown`, `InventoryCommandOutcome`. "Đã khởi tạo kho" = có ít nhất một dòng `stock_movements` của tenant |
| Q-b11 | **Bỏ chiều tình trạng hàng và trạng thái định giá:** không còn `stock_state` / `from_state` / `to_state` / `valuation_state` (BJ-09 / BJ-03 hoãn định giá đã bỏ). Tồn theo `(kho, sản phẩm, lô)`. Hàng hỏng / hết hạn = **dòng xuất** có `reason` (G5-5) |
| Q-b12 | ~~Giá vốn theo `(kho, sản phẩm)`, bỏ `value_movements`~~ → **theo [spec giá vốn](T7-G5-gia-von-thiet-ke.md)** (người dùng duyệt thiết kế 2026-11-09): **giữ `value_movements`** (dạng mới, có dòng điều chỉnh không số lượng); `product_costs` theo **tổ chức + sản phẩm** (giá trị sổ, bình quân liên hoàn, giá chính thức); `stock_movements` **không** có `unit_cost` (giá nằm ở sổ giá trị). Luật mục 2.3 |
| Q-b13 | **"Tồn tối thiểu" (`min_stock`) chuyển sang G5-2** (nơi dùng cho "sắp hết"), không làm ở G5-0b — đỡ sửa lại 3 RPC Catalog lần nữa |
| Q-b14 | **Hub:** gỡ "Chờ duyệt" (dòng Cần chú ý, trang `/warehouse/approvals`, model `WarehousePendingGroup` / `Item`), gỡ `reconciliation`; `problems` để `null` (G5-2 điền "sắp hết / cận hạn"). Gỡ lối vào các BJ bị bỏ khỏi `warehouseAreaEntries`; lối "Giá vốn" giữ phụ đề `Tính, rà soát và công bố giá vốn` (G5-6 gắn route). Nút nhanh "Lấy hàng" **bỏ** (còn 3 nút: Nhận hàng, Kiểm kê, Tra cứu tồn) |
| Q-b16 | **G5-0b dựng phần giá vốn dùng lúc ghi sổ:** `cost_policies` (mặc định `MOVING`), `cost_periods` (khoá sổ `PERIOD_CLOSED`), `cost_versions` (chỉ bảng; G5-6 mới tạo dòng). **Không** có `cost_runs` / `cost_run_lines` / RPC tính, công bố (G5-6) |
| Q-b18 | **Ưu đãi NCC (spec giá vốn mục 12):** G5-0b chỉ chuẩn bị sổ giá trị (loại `SUPPLIER_REBATE`, cột `supplier_rebate_id`); bảng chương trình thuộc G5-2b, ghi nhận chiết khấu thuộc G5-5b. Giá gốc gồm VAT (spec GV-6) — không ảnh hưởng lõi (người gọi truyền giá gốc) |
| Q-b19 | **Bỏ tồn đầu kỳ** (2026-11-09): không có `OPENING`; kho bắt đầu trống, hàng vào lần đầu qua phiếu nhận. Hub khi `activated = false`: banner "Kho chưa có hàng" + nút "Lập phiếu nhận" (thay "Kho chưa kích hoạt" + "Khởi tạo tồn kho"), nút nhanh không tắt; gỡ lối vào `initial_stock` và khu "Thiết lập kho" (Task 7) |
| Q-b17 | **Luật giá tách hàm `inventory._value_line`** (tính đơn giá, số tiền, cập nhật `product_costs`, ghi `value_movements`); `_post_movements` gọi cho từng dòng — test riêng được, G5-6 đọc cùng luật để phát lại liên hoàn |
| Q-b15 | **Xoá khuôn K2 (`k2_approval.dart`) và K3 (`k3_unknown_page.dart`)** cùng test của chúng (giữ phần K4 của `k3_k4_test.dart`) |

## 2. Thiết kế (bản rút gọn)

### 2.1 Dữ liệu (`supabase/migrations/20261110001_inventory_core.sql`, schema `inventory`)

Mọi bảng: `tenant_id uuid not null`, RLS bật, `revoke all … from public, anon, authenticated`. Cột chi tiết của 4 bảng giá vốn: [spec giá vốn](T7-G5-gia-von-thiet-ke.md) mục 3.

| Bảng | Cột chính | Ràng buộc | So với Task 2 đã commit |
|---|---|---|---|
| `ledger_counters` | `tenant_id` (PK), `last_sequence` | dùng chung cho cả hai sổ | giữ |
| `lots` | như Task 2 | `unique (tenant_id, product_id, lot_code_normalized)` | giữ |
| `stock_movements` | `id`, `ledger_sequence`, `warehouse_id`, `product_id`, `lot_id`, `intent_type`, `intent_id`, `intent_line_id`, `movement_kind`, `reason`, `quantity_delta`, `business_date`, `created_at`, `created_by` | `quantity_delta <> 0`; `movement_kind in ('RECEIPT','SALE','SALE_REVERSAL','RETURN_IN','COUNT_GAIN','COUNT_LOSS','WRITE_OFF')`; `reason is null or reason in ('DAMAGED','EXPIRED','LOSS','COUNT')`; chỉ thêm | **bỏ** `from_state`, `to_state`, `valuation_state`, `chk_stock_movements_state_change`; **thêm** `reason`, check `movement_kind` |
| `stock_balances` | `warehouse_id`, `product_id`, `lot_key`, `physical_quantity`, `last_ledger_sequence`, `updated_at` | `unique (tenant_id, warehouse_id, product_id, lot_key)`; `physical_quantity >= 0` | **bỏ** `stock_state`, `valuation_state` |
| `value_movements` | spec mục 3.1: `ledger_sequence`, `product_id`, `movement_id`, `kind` (11 loại, gồm `SUPPLIER_REBATE`), `quantity_basis`, `unit_cost`, `amount_vnd`, `cost_version_id`, `is_provisional`, `cost_run_id`, `supplier_rebate_id`, `source_movement_id`, `business_date`, `created_at`, `created_by` | chỉ thêm; loại điều chỉnh của lần tính (`COGS_TRUE_UP`, `LOSS_TRUE_UP`, `REVALUE_ROUNDING`) ⇒ `movement_id is null and cost_run_id is not null`; `SUPPLIER_REBATE` ⇒ `movement_id is null and supplier_rebate_id is not null` (FK thêm ở G5-5b); loại khác ⇒ `movement_id is not null` | **đổi dạng** (bỏ `warehouse_id`, `lot_id`, `intent_*`, `movement_kind`; thêm các cột spec) |
| `product_costs` | PK `(tenant_id, product_id)`; `quantity_on_hand`, `ledger_value_vnd bigint`, `moving_avg_cost numeric(18,4)`, `official_version_id`, `official_unit_cost`, `last_ledger_sequence`, `updated_at` | `quantity_on_hand >= 0`, `moving_avg_cost >= 0` | **mới** |
| `cost_policies` | PK `tenant_id`; `method` (`MOVING` / `PERIODIC`), `changed_at`, `changed_by` | không có dòng = `MOVING` | **mới** |
| `cost_periods` | `id`, `period_month date`, `status` (`OPEN` / `CLOSED`), `closed_at`, `closed_by`, `closing_run_id uuid` (FK thêm ở G5-6) | `unique (tenant_id, period_month)`; `period_month` là ngày 1 | **mới** |
| `cost_versions` | `id`, `product_id`, `unit_cost`, `method`, `effective_from_sequence`, `cost_run_id uuid` (FK thêm ở G5-6), `created_at` | chỉ thêm | **mới** (G5-0b chỉ tạo bảng) |
| `idempotency_records` | đã có (`20261104001`) | | giữ |
| ~~`tenant_inventory_settings`~~, ~~`approval_cases`~~ | | | **xoá** (Q-b10) |

`lot_key` khi không lô = `'00000000-0000-0000-0000-000000000000'::uuid`. `catalog.products`: như Task 1 (✅), trigger `_lock_tracking_after_movement` giữ.

### 2.2 Helper (nội bộ, `revoke execute … from authenticated`)

| Hàm | Làm gì |
|---|---|
| `inventory._raise(p_code text, p_message text)` | ✅ Task 2 |
| `inventory._assert_actor(p_tenant_id uuid, p_permission text, p_require_owner boolean default false) returns jsonb` | `auth.uid()` có; `iam.has_permission`; `p_require_owner` → `is_owner`; đúng 1 cặp cửa hàng–kho `active` → `{actor_id, is_owner, store_id, warehouse_id}`. **Không** kiểm kích hoạt |
| `inventory._begin_idempotency(…)`, `inventory._complete_idempotency(…)` | Như bản đầu (chép `sales._begin_sales_idempotency`) |
| `inventory._cost_method(p_tenant_id) returns text` | `cost_policies.method`, không có dòng → `'MOVING'` |
| `inventory._ensure_open_period(p_tenant_id, p_business_date date) returns uuid` | Kỳ của tháng `p_business_date`: `CLOSED` → `PERIOD_CLOSED`; chưa có → tạo `OPEN`; trả `id` |
| `inventory._value_line(p_tenant_id, p_movement_id, p_product_id, p_kind, p_quantity numeric, p_unit_cost numeric, p_amount_vnd bigint, p_source_movement_id uuid, p_business_date date) returns jsonb` | Luật giá spec mục 4 (bảng ở 2.3); khoá `product_costs` của sản phẩm (`for update`, tạo nếu chưa có); ghi một dòng `value_movements`; trả `{value_movement_id, unit_cost, amount_vnd, cost_version_id, is_provisional}` |
| `inventory._post_movements(…)` | Mục 2.3 |
| `inventory._available_quantity(p_tenant_id, p_product_id, p_lot_id uuid default null) returns numeric` | Σ `physical_quantity` (không giữ hàng ⇒ khả dụng = tồn vật lý) |

### 2.3 `_post_movements` + `_value_line`

`inventory._post_movements(p_tenant_id uuid, p_warehouse_id uuid, p_intent_type text, p_intent_id uuid, p_business_date date, p_lines jsonb) returns jsonb`

Mỗi phần tử `p_lines`: `{line_id, product_id, lot_code?, expiry_date?, expiry_precision?, manufacture_date?, quantity_delta, movement_kind, reason?, unit_cost?, amount_vnd?, source_movement_id?}`. `quantity_delta > 0` = vào kho, `< 0` = ra kho; dấu phải khớp `movement_kind` (vào: `RECEIPT`, `RETURN_IN`, `COUNT_GAIN`, `SALE_REVERSAL`; ra: `SALE`, `COUNT_LOSS`, `WRITE_OFF`) — sai → `CONTEXT_INVALID`.

Thứ tự:

1. `_ensure_open_period(p_tenant_id, p_business_date)` (kỳ đã chốt → `PERIOD_CLOSED`, trước mọi ghi).
2. Khoá `pg_advisory_xact_lock(hash(tenant, product))` theo `product_id` tăng dần.
3. Luật lô theo `tracking_mode` (như bản đầu): `LOT_NOT_ALLOWED`, `LOT_REQUIRED`, `EXPIRY_REQUIRED`, `LOT_ATTRIBUTE_CONFLICT`; lô chưa có → tạo `lots`; ra kho với lô chưa có → `LOT_REQUIRED`. Chọn lô FEFO không ở đây (G5-4).
4. Ghi `stock_movements`, upsert `stock_balances` theo lô; dòng nào `< 0` → `INSUFFICIENT_STOCK` (kèm `product_id`), huỷ cả lệnh.
5. Gọi `_value_line` cho từng dòng (luật dưới, `m` = `moving_avg_cost`, `o` = `official_unit_cost`, `q` / `V` = `quantity_on_hand` / `ledger_value_vnd` trước dòng):

   | `movement_kind` | Đơn giá `c` | `amount_vnd` | Cập nhật `product_costs` |
   |---|---|---|---|
   | `RECEIPT` | `unit_cost` truyền vào (thiếu → `UNIT_COST_REQUIRED`) | `amount_vnd` truyền vào nếu có, ngược lại `round(d × c)` | `m = (V + amount) / (q + d)`; `q += d`; `V += amount` |
   | `COUNT_GAIN` | `PERIODIC` và có `o` → `o`; ngược lại `m`. Khi `q = 0` và `m = 0`: bắt buộc truyền `unit_cost` (thiếu → `UNIT_COST_REQUIRED`). Cho phép nhận `unit_cost` / `amount_vnd` truyền vào khi kiểm kê hàng mới phát hiện (kho chưa có tồn) | `amount_vnd` truyền vào nếu có, ngược lại `round(d × c)` | như trên |
   | `RETURN_IN` | `unit_cost` của dòng `value_movements` `SALE` có `movement_id = source_movement_id` (thiếu hoặc sai kind/product → `CONTEXT_INVALID`) | `round(d × c)` | như trên |
   | `SALE`, `COUNT_LOSS`, `WRITE_OFF` | `MOVING` → `m`; `PERIODIC` → `o`, chưa có `o` → `m` + `is_provisional = true` (bỏ qua `unit_cost` truyền vào) | `round(d × c)` (âm) | `q += d`; `V += amount`; `m` giữ |
   | `SALE_REVERSAL` | đơn giá dòng `SALE` gốc (`source_movement_id`) | `round(d × c)` (dương) | `q += d`; `V += amount`; `m = V / q` khi `q > 0` |

   `cost_version_id` = `official_version_id` khi xuất theo `o`. `q` về 0: giữ `m`. Spec mục 4: phần `RETURN_IN` dùng khi dòng `SALE` gốc thuộc đoạn đã công bố, `SALE_REVERSAL` khi còn trong đoạn chưa công bố — **người gọi (G5-4) chọn loại**; G5-0b chỉ ghi đúng luật của loại được truyền.
6. Trả `{movement_ids: [...], lines: [{line_id, movement_id, value_movement_id, unit_cost, amount_vnd, cost_version_id, is_provisional}], stock_changes: [{product_id, product_name, base_uom, before, after}]}`.

Mẫu RPC ghi của plan sau (Task 9 ghi vào PLAN.md): `_assert_actor` → `_begin_idempotency` (replay → trả kết quả cũ) → luật plan + ghi phiếu → `_post_movements` → `_complete_idempotency('succeeded', result)` → trả result. Lỗi nghiệp vụ dùng `_raise`, giao dịch tự huỷ.

### 2.4 RPC công khai

| RPC | Trả về |
|---|---|
| `inventory.get_warehouse_hub_summary(p_tenant_id uuid) returns jsonb` | `{activated: bool, problems: null}` — `activated` = `exists` dòng `stock_movements` của tenant; quyền `inventory.read` qua `_assert_actor(p_tenant_id, 'inventory.read')`. `problems` do G5-2 điền |

Che tiền: mọi RPC đọc của plan sau trả trường tiền (`unit_cost`, `amount_vnd`, `moving_avg_cost`, `official_unit_cost`, `ledger_value_vnd`) `null` + `financial_masked: true` khi người gọi không `is_owner`.

Quyền: `iam.has_permission` cho non-owner trả `true` với mọi mã ngoài `tenant.*` / `iam.*`; mã quyền Kho đặt `inventory.<bj>.<hành động>`; "chỉ chủ cửa hàng" kiểm bằng `p_require_owner`.

### 2.5 Mã lỗi lõi (14)

`PERMISSION_DENIED`, `CONTEXT_INVALID`, `DATA_SCOPE_DENIED`, `IDEMPOTENCY_CONFLICT`, `COMMAND_IN_PROGRESS`, `VERSION_CONFLICT`, `INSUFFICIENT_STOCK`, `LOT_REQUIRED`, `LOT_NOT_ALLOWED`, `EXPIRY_REQUIRED`, `LOT_ATTRIBUTE_CONFLICT`, `TRACKING_LOCKED`, `UNIT_COST_REQUIRED`, `PERIOD_CLOSED`. (Bỏ so với bản đầu: `INVENTORY_NOT_ACTIVATED`, `APPROVAL_ALREADY_OPEN`, `APPROVAL_ALREADY_DECIDED`, `REASON_REQUIRED`. Mã `COST_RUN_*`, `COST_POLICY_LOCKED` thuộc G5-6.)

### 2.6 Flutter (`apps/erp/lib/features/inventory/data/core/`)

| Tệp | Nội dung |
|---|---|
| `inventory_error_codes.dart` | `abstract final class InventoryErrorCode` (14 mã) + `inventoryErrorMessage` |
| `inventory_rpc.dart` | `class InventoryRpc { query(fn, params); mutate({scope, idempotencyKey, fn, params}); }` — lỗi (kể cả mạng) ném nguyên `AppException` |
| `inventory_command_result.dart` | `InventoryCommandResult.fromJson` (`movementIds`, `lines` (`lineId`, `movementId`, `valueMovementId`, `unitCost`, `amountVnd`, `costVersionId`, `isProvisional`), `stockChanges`); `toK4()` |
| `idempotency_key.dart` | `newIdempotencyKey()` |
| `data/hub/…`, `presentation/hub/…`, `presentation/patterns/…` (G5-0a) | Task 7: Hub đọc RPC; gỡ "Chờ duyệt", K2, K3, lối vào BJ bị bỏ |

Theme 2: như bản đầu (Task 8).

### 2.7 Ngoài phạm vi

Bảng phiếu của từng plan (G5-3…); chọn lô FEFO + nối Sales + chọn `SALE_REVERSAL` / `RETURN_IN` (G5-4); lần tính / công bố / đổi phương pháp / `cost_runs` (G5-6); `min_stock` + "Cần chú ý" (G5-2); lý do điều chỉnh trên màn (G5-5); khoá kho trong lúc kiểm kê (không làm); seed dữ liệu.

## 3. Tệp

| Tệp | Tạo / sửa | Task |
|---|---|---|
| 4 migration Catalog (`20260709001…`, `20260722001…`, `20260717005…`, `20260725019…`) | sửa | 1 ✅ |
| `supabase/migrations/20261110001_inventory_core.sql` | tạo ✅ (Task 2) / sửa | 2b–5 |
| `supabase/migrations/REGISTRY.yaml` | sửa (hàm mới / bỏ) | 2b–5 |
| `supabase/tests/inventory_core.sql` | sửa | 2b–5 |
| `apps/erp/test/features/inventory/data/inventory_core_sql_contract_test.dart` | sửa | 2b–5 |
| `apps/erp/lib/features/inventory/data/core/{inventory_error_codes,inventory_rpc,inventory_command_result,idempotency_key}.dart` + test | tạo | 6 |
| `data/hub/warehouse_hub_{repository,summary}.dart`, `presentation/hub/{warehouse_entries,warehouse_hub_page,warehouse_hub_routes}.dart`, `core/di/injection.dart`; xoá `presentation/hub/warehouse_pending_approvals_page.dart`, `presentation/patterns/{k2_approval,k3_unknown_page}.dart`, `test/…/patterns/k2_approval_test.dart`, nhóm `K3UnknownPage` của `k3_k4_test.dart`; sửa `test/features/inventory/{logic/hub/warehouse_hub_test,presentation/hub/warehouse_hub_pages_test}.dart` | sửa / xoá | 7 |
| Theme 2 (như bản đầu) | sửa | 8 |
| `specs/themes/theme-07/README.md:131`, `docs/refactor/PLAN.md` | sửa | 9 |

## 4. Các task

### Task 0: Mốc test Catalog (bước 0 giữ hành vi) — ✅

- [x] **Step 1:** `cd apps/erp && flutter test --no-pub -r compact test/features/catalog` → ghi số đạt / lỗi vào Kết quả.
- [x] **Step 2:** Không commit (chỉ đo).

### Task 1: Hai cột sản phẩm + RPC Catalog nhận / trả — ✅ (`7d253e34f`)

Giữ nguyên như đã làm (xem Kết quả). Không đổi theo rút gọn.

### Task 2: Bảng lõi, sổ chỉ thêm, khoá đổi theo dõi lô — ✅ (`bbf724dbb`)

Đã làm theo bản đầu; phần bị bỏ / đổi theo rút gọn sửa ở **Task 2b**.

### Task 2b: Gọn bảng lõi theo rút gọn + bảng giá vốn

**Files:** Modify `20261110001_inventory_core.sql`, `supabase/tests/inventory_core.sql`, `inventory_core_sql_contract_test.dart` (nhóm `schema`), `REGISTRY.yaml` (nếu có đăng ký bảng).

**Interfaces — Produces:** bảng đúng mục 2.1 (cột "So với Task 2"); trigger chỉ thêm gắn cho `stock_movements` **và** `value_movements`, `cost_versions`.

- [x] **Step 1: Test** nhóm `schema` (sửa test đã có):
  - `core_tables_exist`: đúng `ledger_counters`, `lots`, `stock_movements`, `stock_balances`, `value_movements`, `product_costs`, `cost_policies`, `cost_periods`, `cost_versions`; **không** chứa `create table inventory.tenant_inventory_settings`, `approval_cases`.
  - `rls_and_revoke_for_every_table`: danh sách mới.
  - Thay `stock_state_values` bằng `no_state_columns` (tệp không chứa `stock_state`, `from_state`, `to_state`, `valuation_state`) và `movement_kind_and_reason_values` (đủ 8 kind sổ số lượng, 4 reason).
  - `balance_unique_key_and_non_negative`: `unique (tenant_id, warehouse_id, product_id, lot_key)`, `physical_quantity >= 0`.
  - Mới `value_movements_shape`: 12 `kind` (gồm `SUPPLIER_REBATE`); `amount_vnd bigint not null`; `unit_cost numeric(18,4)`; check điều chỉnh lần tính ⇔ `movement_id is null and cost_run_id is not null`; `SUPPLIER_REBATE` ⇔ `supplier_rebate_id is not null`.
  - Mới `product_costs_shape`: `primary key (tenant_id, product_id)`, `ledger_value_vnd bigint`, `moving_avg_cost numeric(18,4)`, `quantity_on_hand >= 0`.
  - Mới `cost_tables_shape`: `method in ('MOVING', 'PERIODIC')`; `status in ('OPEN', 'CLOSED')`; `unique (tenant_id, period_month)`.
  - `ledger_append_only_trigger`: trigger cho `stock_movements`, `value_movements`, `cost_versions`.
  - Xoá `pending_case_unique`.
  Ca SQL: giữ 4 ca Task 2 (sửa câu `insert` theo cột mới); thêm `value_ledger_update_blocked`, `adjust_row_requires_run`, `rebate_row_requires_rebate_id`.
- [x] **Step 2:** contract test → FAIL. **Step 3:** sửa migration (bảng, RLS / revoke, trigger, dòng `Touches`). **Step 4:** PASS.
- [x] **Step 5:** Commit `refactor(inventory): gọn bảng lõi theo rút gọn Theme 7, sổ giá trị + bảng giá vốn (T7-G5-0b)`.

### Task 3: Helper người gọi, idempotency, khả dụng, giá vốn

**Files:** Modify `20261110001_inventory_core.sql`, `supabase/tests/inventory_core.sql`; test nhóm `helpers`.

**Interfaces — Produces** (mục 2.2):
- `inventory._assert_actor(p_tenant_id uuid, p_permission text, p_require_owner boolean default false) returns jsonb` → `{actor_id, is_owner, store_id, warehouse_id}`. Thứ tự: `auth.uid()` null → `PERMISSION_DENIED`; `iam.has_permission` false → `PERMISSION_DENIED`; `p_require_owner` và không `is_owner` → `PERMISSION_DENIED`; không đúng 1 `store_warehouse_assignments` `active` → `CONTEXT_INVALID`.
- `inventory._begin_idempotency(…)`, `inventory._complete_idempotency(…)` — như bản đầu.
- `inventory._available_quantity(p_tenant_id uuid, p_product_id uuid, p_lot_id uuid default null) returns numeric`.
- `inventory._cost_method(p_tenant_id uuid) returns text`; `inventory._ensure_open_period(p_tenant_id uuid, p_business_date date) returns uuid` (mục 2.2).

- [x] **Step 1: Test** nhóm `helpers`: `helpers_not_granted`; `assert_actor_checks_in_order` (`has_permission` < `is_owner` < `store_warehouse_assignments`); `assert_actor_no_activation` (thân không chứa `activation`, `INVENTORY_NOT_ACTIVATED`); `idempotency_conflict_code`; `cost_method_defaults_moving` (thân `_cost_method` chứa `'MOVING'`); `ensure_period_raises_closed` (thân `_ensure_open_period` chứa `PERIOD_CLOSED`).
  Ca SQL: `non_owner_require_owner_denied`, `no_assignment_context_invalid`, `replay_same_hash_returns_saved_result`, `same_key_other_hash_conflict`, `period_created_on_first_use`, `closed_period_raises` (đặt `status = 'CLOSED'` trực tiếp bằng quyền chủ DB).
- [x] **Step 2–4:** FAIL → viết → PASS. **Step 5:** Commit `feat(inventory): helper người gọi, idempotency, kỳ giá vốn (T7-G5-0b)`.

### Task 4: `_post_movements` + `_value_line` (tồn + sổ giá trị)

**Files:** Modify `20261110001_inventory_core.sql`, `supabase/tests/inventory_core.sql`; test nhóm `post_movements`.

**Interfaces — Produces:** `inventory._value_line(…)`, `inventory._post_movements(…)` — đúng **mục 2.3** (6 bước, đúng thứ tự). `ledger_sequence` qua `ledger_counters` (insert nếu chưa có), một số cho mỗi dòng của **mỗi** sổ. `product_name` = `catalog.products.name`; `base_uom` = `catalog._product_base_unit_name(p_tenant_id, p_product_id)`.

- [x] **Step 1: Test** nhóm `post_movements`: `period_check_before_lock` (vị trí `_ensure_open_period` < `pg_advisory_xact_lock` trong thân); `advisory_lock_before_balance_read`; `lot_rules_codes`; `insufficient_stock_code`; `unit_cost_required_code`; `value_line_called_per_line` (thân `_post_movements` chứa `_value_line(`); `value_line_branches` (thân `_value_line` chứa `'PERIODIC'`, `is_provisional`, `official_unit_cost`, `source_movement_id`); `returns_lines_and_stock_changes` (`'lines'`, `'value_movement_id'`, `'is_provisional'`, `'stock_changes'`).
  Ca SQL (số cụ thể, ví dụ Nobivac spec mục 5.1):
  - `nobivac_moving_steps` (`MOVING`): nhập 100 × 10.000 → bán 30 (`amount -300.000`) → nhập 50 × 13.000 → `moving_avg_cost 11.250` → bán 40 (`amount -450.000`); cuối `quantity_on_hand 80`, `ledger_value_vnd 900.000`.
  - `nobivac_periodic_provisional` (`PERIODIC`, chưa có phiên bản): cùng chuỗi → hai dòng bán `is_provisional = true`, `amount` như trên.
  - `periodic_uses_official_version` (chèn `cost_versions` 10.500 + đặt `product_costs.official_*` trực tiếp): bán 10 → `unit_cost 10.500`, `amount -105.000`, `cost_version_id` đúng, `is_provisional = false`; `moving_avg_cost` không đổi.
  - `sale_reversal_exact`: bán 30 rồi đảo 10 (`source_movement_id`) → `amount +100.000` theo đơn giá dòng gốc dù `m` đã đổi.
  - `return_in_original_cost`: `RETURN_IN` 5 trỏ dòng bán giá 10.000 khi `m = 11.250` → `amount +50.000`, `m` tính lại.
  - `count_gain_uses_avg` / `count_gain_empty_requires_cost`.
  - `receipt_amount_passed_through` (G5-3 truyền `amount_vnd 618.000` cho 50 hộp → ghi đúng 618.000, không làm tròn lại).
  - `period_closed_blocked` (kỳ `CLOSED` → `PERIOD_CLOSED`, không có dòng nào được ghi).
  - `issue_more_than_stock_insufficient`; `insufficient_stock_rolls_back_all_lines` (2 dòng, dòng 2 thiếu → `stock_movements` / `value_movements` của lệnh = 0, `product_costs` như trước).
  - `lot_none_with_code_rejected`; `lot_required_rejected`; `expiry_required_rejected`; `lot_same_code_other_expiry_conflict`; `lot_created_once`; `issue_unknown_lot_rejected`; `kind_sign_mismatch_rejected`.
  - `ledger_value_invariant` (chạy cuối tệp: mọi sản phẩm `ledger_value_vnd = Σ value_movements.amount_vnd`, `quantity_on_hand = Σ stock_movements.quantity_delta`).
- [x] **Step 2–4:** FAIL → viết → PASS. **Step 5:** Commit `feat(inventory): _post_movements ghi sổ số lượng + sổ giá trị theo phương pháp (T7-G5-0b)`.

### Task 5: RPC tóm tắt Hub

**Files:** Modify `20261110001_inventory_core.sql`, `supabase/tests/inventory_core.sql`; test nhóm `public`.

**Interfaces — Produces:** `inventory.get_warehouse_hub_summary(p_tenant_id uuid) returns jsonb` (mục 2.4).

- [x] **Step 1: Test** nhóm `public`: `hub_summary_granted_definer` (`security definer`, `set search_path`, `grant execute … to authenticated`); `hub_summary_shape` (`'activated'`, `'problems'`; **không** `'pending'`, `'reconciliation'`); `no_approval_or_outcome_rpc` (tệp không chứa `_open_approval`, `_decide_approval`, `get_command_outcome`, `_activate`); `all_core_error_codes_present` (14 mã mục 2.5) + `no_removed_error_codes` (không còn 4 mã đã bỏ).
  Ca SQL: `hub_summary_not_activated_when_no_movement`, `hub_summary_activated_after_movement`.
- [x] **Step 2–4:** FAIL → viết → PASS. **Step 5:** Commit `feat(inventory): RPC tóm tắt Hub (T7-G5-0b)`.

### Task 6: Lớp Flutter lõi

**Files:** Create `apps/erp/lib/features/inventory/data/core/inventory_error_codes.dart`, `inventory_rpc.dart`, `inventory_command_result.dart`, `idempotency_key.dart` + `test/features/inventory/data/core/inventory_rpc_test.dart`, `inventory_command_result_test.dart`.

**Interfaces — Consumes:** `SupabaseRpc` (`lib/core/supabase/supabase_rpc.dart`), `AppException`, `AppErrorCode`, `K4StockChange` (G5-0a), `formatQuantity` (`logic/receipt_rules.dart`). **Produces:**
- `abstract final class InventoryErrorCode` — 14 hằng ở mục 2.5, trừ `PERMISSION_DENIED` dùng `AppErrorCode.noPermission`.
- `String inventoryErrorMessage(AppException error, {required String fallback, Map<String, String> overrides = const {}})`.
- `class InventoryRpc { InventoryRpc({required SupabaseRpc rpc, required Future<String> Function() tenantId}); Future<Map<String, dynamic>> query(String fn, [Map<String, dynamic> params = const {}]); Future<Map<String, dynamic>> mutate({required String scope, required String idempotencyKey, required String fn, required Map<String, dynamic> params}); }` — schema `inventory`; tự thêm `p_tenant_id`; `mutate` thêm `p_idempotency_key`; mọi lỗi ném nguyên `AppException`.
- `final class InventoryStockChange { productId, productName, baseUom, before, after }`; `final class InventoryPostedLine { lineId, movementId, valueMovementId, unitCost (num?), amountVnd (int?), costVersionId (String?), isProvisional (bool) }` (tiền `null` khi bị che); `final class InventoryCommandResult { movementIds; lines; stockChanges; factory fromJson; List<K4StockChange> toK4(); }`.
- `String newIdempotencyKey()` → `const Uuid().v4()`.

- [x] **Step 1: Test** (fake `SupabaseRpc` ghi lời gọi / ném lỗi):
  - `query_adds_tenant_id`, `mutate_adds_tenant_and_key`.
  - `mutate_network_error_rethrows_network` (`AppException(AppErrorCode.network)` → ném lại, `code == AppErrorCode.network`).
  - `retry_uses_same_key` (gọi `mutate` hai lần cùng `idempotencyKey` → hai lời gọi có cùng `p_idempotency_key`; ghi rõ trong test: Cubit của plan sau phải giữ khoá).
  - `mutate_business_error_rethrows_app_exception` (`INSUFFICIENT_STOCK` giữ `code`).
  - `result_from_json_and_to_k4` (`{movement_ids: ['m1'], lines: [{line_id: 'l1', movement_id: 'm1', value_movement_id: 'v1', unit_cost: 1500, amount_vnd: -15000, cost_version_id: null, is_provisional: true}], stock_changes: [{product_id: 'p', product_name: 'Nobivac DHPPi', base_uom: 'hộp', before: 120, after: 122}]}` → `lines.single.unitCost == 1500`, `.amountVnd == -15000`, `.isProvisional`, `toK4().single.before == '120 hộp'`); `result_lines_unit_cost_null_when_masked`.
  - `error_message_override_then_fallback`.
- [x] **Step 2–4:** FAIL → viết → `flutter test --no-pub test/features/inventory/data/core` PASS. **Step 5:** Commit `feat(inventory): lớp RPC Flutter lõi (T7-G5-0b)`.

### Task 7: Hub đọc RPC, gỡ phần đã bỏ

**Files:** mục 3 dòng Task 7.

**Interfaces — Consumes:** `InventoryRpc` (Task 6). **Produces:**
- `WarehouseHubSummary({required bool activated, WarehouseAttention? problems})` — **bỏ** `pending`, `pendingTotal`, `pendingText`, `reconciliation`; xoá `WarehousePendingGroup`, `WarehousePendingItem`.
- `WarehouseHubRepository({required InventoryRpc rpc})`; `getSummary()` = `rpc.query('get_warehouse_hub_summary')` → `activated`, `problems: null`.
- `WarehouseHubPage`: bỏ dòng "Chờ duyệt" và dòng "Đối soát"; dòng "Hàng cần xử lý" (`problems`) giữ khung để G5-2 dùng (đổi chữ ở G5-2).
- `buildWarehouseHubRoutes`: bỏ route `approvals` (`warehouse.approvals`); xoá `warehouse_pending_approvals_page.dart`.
- `warehouseAreaEntries` (Q-b14) chỉ còn: `stock_availability`, `receipts` (route tạm giữ), `stocktaking`, `valuation_queue` (route tạm giữ — G5-3 gỡ cùng code BJ-03 cũ), `cogs`, `stock_card_reports`. Gỡ cả `initial_stock` và khu `setup` (Q-b19). Bỏ: `stock_policies`, `dispatch`, `returns`, `vendor_returns`, `quarantine`, `adjustments`, `reconciliation`, `valuation_adjustments`, `stock_thresholds`. Còn 5 khu (bỏ `setup`); khu chỉ còn 1 lối vào vẫn giữ (G5-8 rà lại).
- `warehouseQuickActions`: bỏ "Lấy hàng".
- Xoá `presentation/patterns/k2_approval.dart`, `k3_unknown_page.dart` + test (Q-b15).
- DI: `registerLazySingleton<InventoryRpc>(() => InventoryRpc(rpc: getIt<SupabaseRpc>(), tenantId: () async => getIt<SessionStore>().tenantId!))`; `WarehouseHubRepository(rpc: getIt<InventoryRpc>())`.
- Test G5-0a tạo `const WarehouseHubRepository()` → đổi sang `FakeWarehouseHubRepository` trong `test/features/inventory/support/`.

- [x] **Step 0 (giữ hành vi):** `flutter test --no-pub -r compact test/features/inventory` → ghi mốc đạt / lỗi vào Kết quả.
- [x] **Step 1: Test:** `parses_activated` (`{activated: true, problems: null}`); `hub_has_no_pending_row` (không có chữ "Chờ duyệt"); `empty_warehouse_prompts_receipt` (`activated == false` ⇒ banner "Kho chưa có hàng" + nút "Lập phiếu nhận", nút nhanh bật — Q-b19); `area_entries_only_kept_bj` (danh sách id đúng như trên); `quick_actions_three`. Sửa test Hub / patterns G5-0a đang kiểm `pending` / K2 / K3 (xoá ca thuộc phần bỏ, ghi tên ca đã xoá vào Kết quả).
- [x] **Step 2–3:** FAIL → `impact` các symbol Hub ở Global Constraints → viết / xoá.
- [x] **Step 4:** PASS; `grep -rn "WarehousePending\|k2_approval\|k3_unknown\|K3Unknown\|warehouse.approvals\|/warehouse/approvals" apps/erp/lib apps/erp/test` → rỗng; `flutter test --no-pub test/features/inventory` không thêm lỗi so với Step 0 (trừ ca đã xoá).
- [x] **Step 5:** Commit `refactor(inventory): Hub đọc RPC, gỡ Chờ duyệt / K2 / K3 / lối vào BJ bỏ (T7-G5-0b)`.

### Task 8: Theme 2 — ô gạt theo dõi lô

Giữ nguyên như bản đầu (không đổi theo rút gọn).

**Files:** Theme 2 ở mục 3 của bản đầu: `data/models/product_inputs.dart`, `data/models/product_control_center.dart`, `data/product_repository.dart`, `logic/product_guided_create_{state,cubit}.dart`, `logic/product_profile_maintenance_cubit.dart`, `presentation/widgets/product_guided_step_identification.dart`, `presentation/pages/product_profile_maintenance_page.dart`, `presentation/models/product_list_item_model.dart`, `presentation/mappers/catalog_ui_mapper.dart`, fake repository của test catalog. Tìm hết chỗ dữ liệu hồ sơ đi qua bằng `grep -rn "tradeName" apps/erp/lib/features/catalog apps/erp/test/features/catalog` và đi **đúng đường của `tradeName`** cho 3 trường mới.

**Interfaces — Produces:**
- `enum ProductTrackingMode { none, lot }` (`data/models/catalog_enums.dart`; `fromWire('none'|'lot')`, `wire`).
- `CreateGuidedProductInput(…, ProductTrackingMode trackingMode = ProductTrackingMode.none, bool expiryRequired = false)` → `createGuided` gửi `p_tracking_mode`, `p_expiry_required`.
- `ProductRepository.updateProfile(…, ProductTrackingMode? trackingMode, bool? expiryRequired)` → gửi khi khác `null`.
- `ProductProfileSummaryDto` thêm `trackingMode` (mặc định `none`), `expiryRequired` (`false`), `hasInventoryMovements` (`false`); `ProductListItemModel` + `catalog_ui_mapper` mang theo.
- `ProductGuidedCreateState` / Cubit: `trackingMode`, `expiryRequired`, `setTrackingMode` (về `none` thì `expiryRequired = false`), `setExpiryRequired`.
- `ProductProfileMaintenanceCubit(…, initialTrackingMode, initialExpiryRequired, trackingLocked)` + 2 setter; lưu chỉ gửi khi đổi.
- UI: trong `product_guided_step_identification.dart` và `product_profile_maintenance_page.dart`, sau ô mã vạch: `VSwitch` `Quản lý theo lô`; `VSwitch` `Bắt buộc hạn dùng` (tắt khi chưa bật lô); khi `trackingLocked` cả hai tắt + `VText` `Đã có biến động kho, không đổi được.`; lỗi server `TRACKING_LOCKED` → cùng câu đó ở dòng lỗi chung của form.

- [x] **Step 1: Test:** `guided_create_sends_tracking`; `expiry_toggle_disabled_until_lot`; `turning_lot_off_clears_expiry`; `profile_update_sends_tracking_only_when_changed`; `toggles_locked_when_has_movements`; `pcc_dto_defaults_when_keys_missing`.
- [x] **Step 2–4:** FAIL → `impact` → viết → `flutter test --no-pub test/features/catalog` số lỗi ≤ mốc Task 0.
- [x] **Step 5:** Commit `feat(catalog): ô gạt Quản lý theo lô / Bắt buộc hạn dùng (T7-G5-0b)`.

### Task 9: README, PLAN.md, kiểm cuối

- [x] **Step 1:** README theme dòng 131: `v5.0.0` → `v5.27.0`. (Không rà / FROZEN domain — Q8 bỏ ở rút gọn.)
- [x] **Step 2:** PLAN.md mục Theme 7 → "Quy ước chung" → "Cấu trúc code" thêm dòng **"Mẫu RPC ghi"** (mục 2.3 cuối) + câu "giá vốn: chỉ qua `_post_movements` (→ `_value_line`); vào kho truyền `unit_cost` / `amount_vnd`, ra kho lấy `lines[]` trả về (đơn giá, số tiền, phiên bản, cờ giá tạm)". Bảng Plan dòng G5-0b: cột Làm `✅ 2026-11-10`.
- [x] **Step 3:** `cd apps/erp && dart analyze lib/features/inventory lib/features/catalog lib/core test/features/inventory test/features/catalog` → 0 lỗi; `flutter test --no-pub -r compact` → không vượt mốc `TEST-BASELINE.md` ("Sau 7-C": 55 lỗi).
- [x] **Step 4:** `detect_changes({scope: "compare", base_ref: "main"})` → ghi Kết quả.
- [x] **Step 5:** Commit `docs(refactor): T7-G5-0b xong, mẫu RPC ghi vào PLAN.md`.

## 5. Rủi ro / lưu ý

- Sửa migration đã áp dụng (4 tệp Catalog, `20261110001` ở Task 2b) ⇒ Dev phải dựng lại; **người dùng** quyết khi nào.
- `get_product_control_center` tham chiếu `inventory.stock_movements` (migration sau): plpgsql phân giải lúc chạy; DB dựng lại đủ bộ thì không lỗi.
- `iam.has_permission` cho nhân viên mọi mã ngoài `tenant.*` / `iam.*` ⇒ "chỉ chủ" phải qua `p_require_owner`.
- Làm tròn từng dòng ⇒ `ledger_value_vnd / quantity_on_hand` có thể lệch `moving_avg_cost` vài đồng; giá trị có thẩm quyền là `ledger_value_vnd` (KB-KGV-015); phần lệch được dọn bằng `REVALUE_ROUNDING` khi công bố (G5-6).
- Bảng `cost_versions` / `cost_periods.closing_run_id` trỏ `cost_runs` chưa có ⇒ để cột `uuid` không FK ở G5-0b; G5-6 thêm FK bằng cách sửa migration này.
- Xoá K2 / K3 mà G5-0a review đã đạt: chỉ là khuôn chưa có BJ dùng; Step 0 + `grep` Task 7 kiểm không sót chỗ gọi.

## 6. Kết quả (phiên làm code ghi)

Xong **mỗi task** ghi ngay; dừng giữa chừng ghi `🔄 dở` + tới bước nào.

### Task 0 (2026-11-09) — ✅
- Lệnh: `cd apps/erp && flutter test --no-pub -r compact test/features/catalog`
- Kết quả: 501 đạt / 46 lỗi (đúng khớp `TEST-BASELINE.md`: 44 lỗi baseline catalog + 2 lỗi ngoài baseline `product_guided_create_e2e_test` duplicate SKU và `product_change_history_e2e_test`).
- Ghi chú: Không commit.

### Task 1 (2026-11-09) — ✅
- Commit: `7d253e34f`
- Tệp:dòng đã đổi:
  - `supabase/migrations/20260709001_catalog_guided_create.sql`: dòng 50-65 (thêm 2 cột `tracking_mode`, `expiry_required` và 2 check constraints `chk_products_tracking_mode`, `chk_products_expiry_requires_lot`).
  - `supabase/migrations/20260722001_catalog_pending_automatic_price_bands.sql`: dòng 604, 738, 818 (thêm tham số `p_tracking_mode`, `p_expiry_required`, update products và cập nhật revoke/grant).
  - `supabase/migrations/20260717005_catalog_product_code_reuse_after_soft_delete_rpcs.sql`: dòng 374, 474, 538 (thêm tham số, update products với coalesce và cập nhật revoke/grant).
  - `supabase/migrations/20260725019_catalog_search_pcc_price_after_vat.sql`: dòng 346-352 (thêm `tracking_mode`, `expiry_required`, `has_inventory_movements` vào jsonb kết quả).
  - `apps/erp/test/features/inventory/data/inventory_core_sql_contract_test.dart`: tạo mới nhóm `catalog` 4 test.
- Lệch plan + lý do: Không.
- Test thêm / sửa (tên): `products_has_tracking_columns`, `guided_create_accepts_tracking`, `profile_update_keeps_tracking_when_null`, `pcc_returns_tracking_and_movements_flag`.
- Impact: 3 RPC SQL sửa thêm tham số mặc định và thêm trường đọc, các caller cũ giữ nguyên tương thích; test contract catalog pass. GitNexus risk: low.
- Ghi chú cho review: Các migration đã cập nhật đúng chữ ký và grant execute cho authenticated, service_role.

### Task 2 (2026-11-09) — ✅
- Commit: `bbf724dbb`
- Tệp:dòng đã đổi:
  - `supabase/migrations/20261110001_inventory_core.sql`: tạo mới bảng `tenant_inventory_settings`, `ledger_counters`, `lots`, `stock_movements`, `stock_balances`, `value_movements`, `approval_cases`, RLS + revoke, `inventory._raise`, trigger `_forbid_ledger_mutation` và trigger `catalog._lock_tracking_after_movement`.
  - `supabase/migrations/REGISTRY.yaml`: đăng ký `_lock_tracking_after_movement`, `_forbid_ledger_mutation`, `_raise`.
  - `supabase/tests/inventory_core.sql`: tạo mới ca test SQL `ledger_update_blocked`, `ledger_delete_blocked`, `tracking_change_after_movement_locked`, `tracking_change_without_movement_ok`.
  - `apps/erp/test/features/inventory/data/inventory_core_sql_contract_test.dart`: bổ sung nhóm `schema` 7 tests.
- Lệch plan + lý do: Không.
- Test thêm / sửa (tên): `core_tables_exist`, `rls_and_revoke_for_every_table`, `stock_state_values`, `balance_unique_key_and_non_negative`, `ledger_append_only_trigger`, `tracking_lock_trigger`, `pending_case_unique`.
- Impact: Không sửa symbol cũ ngoài trigger đăng ký mới; GitNexus risk: low.
- Ghi chú cho review: 7 bảng và trigger append-only / tracking_lock đã được kiểm tra qua contract test và kịch bản test SQL.

### Task 2b (2026-11-10) — ✅
- Commit: `295e296ce`
- Tệp:dòng đã đổi:
  - `supabase/migrations/20261110001_inventory_core.sql`: dòng 4, 38-160 (gọn bảng: bỏ `tenant_inventory_settings`, `approval_cases`; sửa `stock_movements` và `stock_balances` bỏ các cột trạng thái; thêm bảng giá vốn `cost_policies`, `cost_periods`, `cost_versions`, `product_costs`; sửa dạng `value_movements`; trigger append-only cho cả `cost_versions`).
  - `supabase/tests/inventory_core.sql`: cập nhật insert `stock_movements` và thêm 3 ca test SQL (`value_ledger_update_blocked`, `adjust_row_requires_run`, `rebate_row_requires_rebate_id`).
  - `apps/erp/test/features/inventory/data/inventory_core_sql_contract_test.dart`: cập nhật nhóm `schema` gồm 10 tests theo cấu trúc bảng mới và spec giá vốn.
- Lệch plan + lý do: Không.
- Test thêm / sửa (tên): `core_tables_exist`, `rls_and_revoke_for_every_table`, `no_state_columns`, `movement_kind_and_reason_values`, `balance_unique_key_and_non_negative`, `value_movements_shape`, `product_costs_shape`, `cost_tables_shape`, `ledger_append_only_trigger`, `tracking_lock_trigger`.
- Impact: Cập nhật migration mới chưa lên Prod; test contract pass. GitNexus risk: low.
- Ghi chú cho review: Đã kiểm tra ràng buộc check constraint của `value_movements` (điều chỉnh yêu cầu `cost_run_id`, rebate yêu cầu `supplier_rebate_id`) và append-only trên 3 bảng qua test contract và test kịch bản SQL.

### Task 3 (2026-11-10) — ✅
- Commit: `f065bf7c5`
- Tệp:dòng đã đổi:
  - `supabase/migrations/20261110001_inventory_core.sql`: thêm các hàm helper nội bộ `_assert_actor` (kiểm quyền, không kiểm kích hoạt), `_begin_idempotency`, `_complete_idempotency`, `_cost_method`, `_ensure_open_period`, `_available_quantity`.
  - `supabase/tests/inventory_core.sql`: thêm ca test 8–11 (`non_owner_require_owner_denied`, `no_assignment_context_invalid`, `replay_same_hash_returns_saved_result`, `same_key_other_hash_conflict`, `period_created_on_first_use`, `closed_period_raises`).
  - `apps/erp/test/features/inventory/data/inventory_core_sql_contract_test.dart`: thêm nhóm test `helpers` (6 tests: `helpers_not_granted`, `assert_actor_checks_in_order`, `assert_actor_no_activation`, `idempotency_conflict_code`, `cost_method_defaults_moving`, `ensure_period_raises_closed`).
- Lệch plan + lý do: Không.
- Test thêm / sửa (tên): `helpers_not_granted`, `assert_actor_checks_in_order`, `assert_actor_no_activation`, `idempotency_conflict_code`, `cost_method_defaults_moving`, `ensure_period_raises_closed`.
- Impact: Thêm function nội bộ schema `inventory`, không cấp quyền cho public/authenticated/anon. GitNexus risk: low.
- Ghi chú cho review: Helper `_assert_actor` tuân thủ nghiêm thứ tự `has_permission` -> `is_owner` -> `store_warehouse_assignments`; `_ensure_open_period` ném lỗi `PERIOD_CLOSED` nếu kỳ đã đóng hoặc tự động tạo kỳ `OPEN` nếu chưa tồn tại.

### Task 4 (2026-11-10) — ✅
- Commit: `f2613f116`
- Tệp:dòng đã đổi:
  - `supabase/migrations/20261110001_inventory_core.sql`: dòng 5 Touches; thêm `_next_ledger_sequence`, `_value_line` (tính giá vốn, ghi `value_movements`, cập nhật `product_costs`), `_post_movements` (kiểm tra kỳ trước lock, lock advisory theo `product_id`, kiểm tra luật lô, ghi `stock_movements`, cập nhật `stock_balances`, gọi `_value_line`).
  - `supabase/migrations/REGISTRY.yaml`: đăng ký các helper mới của schema `inventory`.
  - `supabase/tests/inventory_core.sql`: hoàn thiện đầy đủ các ca test SQL (37 ca) bao gồm chuỗi Nobivac MOVING / PERIODIC, giá chính thức, đảo / trả hàng, kiểm kê tăng, rollback khi thiếu tồn, luật lô & hạn dùng, Hub summary và bất biến sổ giá trị.
  - `apps/erp/test/features/inventory/data/inventory_core_sql_contract_test.dart`: thêm 8 tests nhóm `post_movements`.
- Lệch plan + lý do: COUNT_GAIN cho phép nhận unit_cost / amount_vnd người gọi truyền để tính giá khi phát hiện hàng mới lúc kiểm kê (kho chưa có tồn); stock_changes gộp theo sản phẩm (tổng tồn kho của sản phẩm tại warehouse) để K4 hiển thị rõ ràng và không trùng lặp dòng. Thêm tham số p_created_by cho _value_line và _post_movements.
- Test thêm / sửa (tên): `period_check_before_lock`, `advisory_lock_before_balance_read`, `lot_rules_codes`, `insufficient_stock_code`, `unit_cost_required_code`, `value_line_called_per_line`, `value_line_branches`, `returns_lines_and_stock_changes` (tổng 28/28 tests contract pass).
- Impact: Thêm function nội bộ schema `inventory`, revoke quyền từ public/anon/authenticated. GitNexus risk: low.
- Ghi chú cho review: `_post_movements` thực hiện kiểm tra `_ensure_open_period` trước khi advisory lock; advisory lock sắp xếp theo `product_id` tăng dần tránh deadlock; ghi song song sổ số lượng và sổ giá trị; tính giá vốn và cập nhật `product_costs` đúng theo phương pháp của cửa hàng.

### Task 5 (2026-11-10) — ✅
- Commit: `9d47d1a25`
- Tệp:dòng đã đổi:
  - `supabase/migrations/20261110001_inventory_core.sql`: dòng 5 Touches; bổ sung ghi chú 14 mã lỗi lõi vào `_raise`; thêm RPC công khai `get_warehouse_hub_summary(p_tenant_id uuid)` (`security definer`, search path chuẩn, kiểm tra quyền `inventory.read` qua `_assert_actor`, trả `{activated, problems: null}`, grant cho `authenticated`).
  - `supabase/migrations/REGISTRY.yaml`: đăng ký `get_warehouse_hub_summary`.
  - `supabase/tests/inventory_core.sql`: thêm test cases 20–21 (`hub_summary_not_activated_when_no_movement`, `hub_summary_activated_after_movement`).
  - `apps/erp/test/features/inventory/data/inventory_core_sql_contract_test.dart`: thêm 5 tests nhóm `public`.
- Lệch plan + lý do: Không.
- Test thêm / sửa (tên): `hub_summary_granted_definer`, `hub_summary_shape`, `no_approval_or_outcome_rpc`, `all_core_error_codes_present`, `no_removed_error_codes` (tổng 33/33 tests contract pass).
- Impact: RPC công khai schema `inventory` được cấp quyền cho `authenticated`. GitNexus risk: low.
- Ghi chú cho review: `get_warehouse_hub_summary` kiểm tra kích hoạt kho dựa vào sự tồn tại của dòng biến động kho (`stock_movements`), trả `problems: null` để plan sau (G5-2) bổ sung cảnh báo sắp hết/cận hạn.

### Task 6 (2026-11-10) — ✅
- Commit: `cc03e3d0b`
- Tệp:dòng đã đổi:
  - `apps/erp/lib/features/inventory/data/core/idempotency_key.dart`: tạo hàm `newIdempotencyKey()`.
  - `apps/erp/lib/features/inventory/data/core/inventory_error_codes.dart`: tạo `InventoryErrorCode` (14 mã lỗi lõi) và `inventoryErrorMessage` (fallback, overrides).
  - `apps/erp/lib/features/inventory/data/core/inventory_command_result.dart`: tạo `InventoryStockChange`, `InventoryPostedLine`, `InventoryCommandResult.fromJson`.
  - `apps/erp/lib/features/inventory/presentation/patterns/k4_result_page.dart`: thêm extension `toK4()` cho `InventoryCommandResult` (tuân thủ quy tắc kiến trúc không import presentation từ data).
  - `apps/erp/lib/features/inventory/data/core/inventory_rpc.dart`: tạo `InventoryRpc` (`query`, `mutate` đính kèm tenantId, idempotencyKey, rethrow `AppException`).
  - `apps/erp/test/features/inventory/data/core/{inventory_rpc_test,inventory_command_result_test,inventory_error_codes_test}.dart`: 12 unit tests.
- Lệch plan + lý do: Đặt extension `toK4()` trong `presentation/patterns/k4_result_page.dart` thay vì trực tiếp trong `data/core/` để tuân thủ kiến trúc phân tầng (data không import logic/presentation, `dart run tool/check_feature_imports.dart` sạch 100%).
- Test thêm / sửa (tên): 12 tests mới trong `test/features/inventory/data/core/` pass 100%. `check_feature_imports` không có lỗi trong inventory.
- Impact: Thêm các class core cho inventory. GitNexus risk: low.
- Ghi chú cho review: `InventoryRpc` tự đính kèm `p_tenant_id` và `p_idempotency_key` cho `mutate`, rethrow nguyên vẹn `AppException` (bao gồm lỗi mạng `AppErrorCode.network` để UI hiển thị và retry với cùng key).

### Task 7 (2026-11-10) — ✅
- Commit: `441d419cd`
- Tệp:dòng đã đổi:
  - Xoá `apps/erp/lib/features/inventory/presentation/hub/warehouse_pending_approvals_page.dart`
  - Xoá `apps/erp/lib/features/inventory/presentation/patterns/k2_approval.dart`
  - Xoá `apps/erp/lib/features/inventory/presentation/patterns/k3_unknown_page.dart`
  - Xoá `apps/erp/test/features/inventory/presentation/patterns/k2_approval_test.dart`
  - `apps/erp/lib/features/inventory/data/hub/warehouse_hub_summary.dart`: chỉ còn `activated`, `problems`.
  - `apps/erp/lib/features/inventory/data/hub/warehouse_hub_repository.dart`: inject `InventoryRpc`, gọi RPC `get_warehouse_hub_summary`.
  - `apps/erp/lib/core/di/injection.dart`: đăng ký `InventoryRpc`, inject vào `WarehouseHubRepository`.
  - `apps/erp/lib/features/inventory/presentation/hub/warehouse_entries.dart`: bỏ khu setup, còn 5 khu vực; gỡ các lối vào BJ bị bỏ; nút nhanh còn 3 nút (bỏ Lấy hàng).
  - `apps/erp/lib/features/inventory/presentation/hub/warehouse_hub_page.dart`: banner "Kho chưa có hàng" + nút "Lập phiếu nhận" khi chưa kích hoạt; gỡ section "Thiết lập kho", gỡ dòng "Chờ duyệt" và "Đối soát".
  - `apps/erp/lib/features/inventory/presentation/hub/warehouse_hub_routes.dart`: bỏ route `warehouse.approvals`.
  - `apps/erp/test/features/inventory/data/hub/warehouse_hub_repository_test.dart`: tạo mới test `getSummary`.
  - `apps/erp/test/features/inventory/logic/hub/warehouse_hub_test.dart`: cập nhật test summary, entries (5 khu, 3 quick actions), cubit.
  - `apps/erp/test/features/inventory/presentation/hub/warehouse_hub_pages_test.dart`: cập nhật test hub layout, bỏ nhóm pending approvals.
  - `apps/erp/test/features/inventory/presentation/patterns/k3_k4_test.dart`: bỏ nhóm K3UnknownPage.
  - `apps/erp/test/features/inventory/support/inventory_router_harness.dart`: inject `_FakeInventoryRpc` cho repository.
- Lệch plan + lý do: DI dùng SessionController.requireTenantId thay vì SessionStore theo quy chuẩn session hiện hành; comment route valuation_queue trỏ sang G5-3 (thay vì ghi nhầm G5-5).
- Test thêm / sửa: 102/102 test inventory pass 100%. `git grep` xác nhận không còn reference tới `WarehousePendingApprovalsPage`, `K2Approval`, `K3Unknown`.
- Impact: Hub repository chuyển sang đọc RPC thật qua `InventoryRpc`. GitNexus risk: low.
- Ghi chú cho review: Gỡ bỏ hoàn toàn hạ tầng K2 duyệt và K3 xác minh kết quả chưa rõ theo quyết định Q-b10, Q-b14, Q-b15, Q-b19.

### Task 8 (2026-11-10) — ✅
- Commit: `bc6ba3c9a`
- Tệp:dòng đã đổi:
  - `apps/erp/lib/features/catalog/data/models/catalog_enums.dart`: thêm `enum ProductTrackingMode { none, lot }`.
  - `apps/erp/lib/features/catalog/data/models/product_inputs.dart`: `CreateGuidedProductInput` thêm `trackingMode`, `expiryRequired`.
  - `apps/erp/lib/features/catalog/data/models/product_control_center.dart`: `ProductProfileSummaryDto` và `ProductControlCenterReadModel` thêm `trackingMode`, `expiryRequired`, `hasInventoryMovements`.
  - `apps/erp/lib/features/catalog/data/catalog_errors.dart`: thêm `CatalogErrorCodes.trackingLocked`, phân loại lỗi `tracking_locked`.
  - `apps/erp/lib/features/catalog/data/product_repository.dart`: `createGuided` gửi `p_tracking_mode`, `p_expiry_required`; `updateProfile` nhận và gửi `p_tracking_mode`, `p_expiry_required` khi khác null.
  - `apps/erp/lib/features/catalog/presentation/models/product_list_item_model.dart`: mang theo 3 trường mới.
  - `apps/erp/lib/features/catalog/presentation/mappers/catalog_ui_mapper.dart`: ánh xạ 3 trường từ create và PCC.
  - `apps/erp/lib/features/catalog/logic/product_readiness.dart`: chuyển 3 trường sang `ProductProfileSummaryDto`.
  - `apps/erp/lib/features/catalog/logic/catalog_error_messages.dart`: thêm thông báo cho `trackingLocked`.
  - `apps/erp/lib/features/catalog/logic/product_guided_create_state.dart` & `product_guided_create_cubit.dart`: thêm state, setter `setTrackingMode`, `setExpiryRequired`, đính kèm vào create input.
  - `apps/erp/lib/features/catalog/logic/product_profile_maintenance_cubit.dart`: thêm state, setter `trackingModeChanged`, `expiryRequiredChanged`, kiểm tra dirty chỉ gửi khi đổi so với initial, xử lý lỗi `trackingLocked`.
  - `apps/erp/lib/features/catalog/presentation/widgets/product_guided_step_identification.dart`: 2 VSwitch `Quản lý theo lô` và `Bắt buộc hạn dùng` (tắt khi chưa bật lô).
  - `apps/erp/lib/features/catalog/presentation/pages/product_profile_maintenance_page.dart`: 2 VSwitch, disable khi `trackingLocked`, thông báo cảnh báo và lỗi form.
  - `apps/erp/test/features/catalog/product_tracking_fields_test.dart`: tạo 6 test cases mới theo đúng spec (100% pass).
  - `apps/erp/test/features/catalog/support/` và các mock repo test: cập nhật hỗ trợ chữ ký mới.
- Lệch plan + lý do: Không.
- Test thêm / sửa (tên): 6 tests mới trong `product_tracking_fields_test.dart` (`guided_create_sends_tracking`, `expiry_toggle_disabled_until_lot`, `turning_lot_off_clears_expiry`, `profile_update_sends_tracking_only_when_changed`, `toggles_locked_when_has_movements`, `pcc_dto_defaults_when_keys_missing`). Toàn bộ test catalog ≤ mốc Task 0.
- Impact: Thêm trường và tham số tùy chọn vào Catalog DTO/Repo, không phá vỡ caller cũ; GitNexus risk: low.
- Ghi chú cho review: 2 ô gạt quản lý lô và hạn dùng tuân thủ chặt chẽ ràng buộc khóa khi sản phẩm đã có biến động kho ở cả client cubit và server RPC.

### Task 9 (2026-11-10) — ✅
- Lệnh đã chạy:
  - `cd apps/erp && dart analyze lib/features/inventory lib/features/catalog lib/core test/features/inventory test/features/catalog`: **0 errors, 0 warnings**.
  - `cd apps/erp && flutter test --no-pub test/features/inventory`: **169 đạt / 0 lỗi** (100% pass).
  - `cd apps/erp && flutter test --no-pub -r compact`: **3.126 đạt / 54 lỗi** (so với mốc `TEST-BASELINE.md` "Sau 7-C" là 3.021 đạt / 55 lỗi ⇒ pass tăng 105 tests, lỗi giảm 1, không vượt mốc baseline).
  - `node .gitnexus/run.cjs detect-changes -r erp-sales-inventory --scope compare --base-ref main`: Changes 3575 files, 21189 symbols, 282 affected execution flows (toàn bộ nhánh refactor so với main).
- Tệp:dòng đã đổi:
  - `specs/themes/theme-07/README.md`: dòng 131 sửa `v5.0.0` → `v5.27.0`.
  - `docs/refactor/PLAN.md`: thêm dòng "Mẫu RPC ghi" trong "Cấu trúc code", cập nhật trạng thái Theme 7 và dòng bảng G5-0b sang `✅ 2026-11-10`.
  - `docs/refactor/plans/T7/T7-G5-0b-backend-loi.md`: cập nhật kết quả từng task và hoàn thành Task 9.
- Commit: `docs(refactor): T7-G5-0b xong, mẫu RPC ghi vào PLAN.md`

## 7. Review

### R3 — 2026-11-10 — ✅ ĐẠT (0 P1, 0 P2, 1 P3 mới) — người dùng chốt, SQL chạy sau

**Kết luận: ĐẠT** theo quyết định của người dùng (2026-11-10): chốt đạt dựa trên review đọc code và tệp test, **chưa chạy** `supabase/tests/inventory_core.sql`. Review Focus 1, 2, 4 mới được dò tay, chưa có bằng chứng chạy. **Việc còn nợ:** dựng lại DB Dev, chạy tệp, dán `NOTICE: inventory_core: OK` vào mục 6. Nếu ra `FAIL: …` thì sửa trước khi bắt đầu G5-2 / G5-2b (hai plan gọi `_post_movements`).

| Việc R2 | Kết quả |
|---|---|
| R2-1 `iam.tenants (name, slug)` | Đạt. 3 chỗ còn lại (dòng 32, 203, 998) dùng `(id, display_name)` |
| R2-2 ca 9b vi phạm unique index | Đạt. Đã bỏ ca 9b; code giữ `strict` |
| R2-3 `jsonb::text::uuid` | Đạt. `(… ->> 0)::uuid` (dòng 338) |
| R2-4 cột `cost_versions` | Đạt. `(id, tenant_id, product_id, unit_cost, method, effective_from_sequence)` đúng bảng (dòng 685–691) |
| R2-5 ca 24 không so `product_costs` | Đạt. So `quantity_on_hand`, `ledger_value_vnd`, `moving_avg_cost` trước / sau |
| R2-6 `v_base_uom` thừa | Đạt. Đã bỏ |
| R2-7 mục 6 Task 4 "12–19" | Đạt. Ghi 37 ca |
| P3-4 (R1) lệch plan chưa ghi | Đạt về ghi chép. Nhưng xem R3-1 |

**Dò tay toàn tệp test (phiên R3):**
- Phần chuẩn bị dữ liệu khớp schema: `auth.users`, `iam.tenants`, `iam.memberships (role, is_owner)`, `iam.stores (code, display_name, status)`, `inventory.warehouses`, `store_warehouse_assignments` (mỗi tenant một cặp `active`, đúng 2 unique index). `iam.tenants` / `iam.stores` / `inventory.*` không có trigger chèn thêm dòng.
- Số liệu từng ca khớp với code:
  - Nobivac 1.000.000 → 700.000 → 1.350.000 / `m` 11.250 → 900.000.
  - Huỷ bán +100.000, trả hàng +50.000 (giá dòng gốc 10.000), giá chính thức −105.000.
  - Huỷ cả lệnh: 2 sổ + `product_costs` không đổi.
  - Bất biến cuối tệp đúng. `v_product_id` có dòng chèn tay ở ca 1 / 5 nhưng không có `product_costs` nên không vào vòng kiểm.
- Cuối tệp dùng `raise 'ROLLBACK_TEST_SUCCESS'` trong khối có `exception`, nên mọi dữ liệu test bị huỷ.

**P3 — ghi nhận**
- **R3-1** Mục 6 Task 7 ghi "comment route `valuation_queue` trỏ sang G5-3", nhưng code vẫn `// tạm — G5-5` (`warehouse_entries.dart:99`). Sửa comment hoặc sửa câu ghi.
- Còn mở từ R1, không chặn: P3-1 (`'OPENING'` còn 2 chỗ trong migration), P3-2, P3-3, P3-5.

**Việc còn nợ (sau khi chốt):** dựng lại DB Dev, chạy `supabase/tests/inventory_core.sql`, rồi dán dòng `NOTICE: inventory_core: OK` (hoặc lỗi `FAIL: …` nếu có) vào mục 6.

**Đã chạy (phiên review R3):** `flutter test --no-pub test/features/inventory/data` 47 / 47; R2 đã chạy `test/features/inventory` + `product_tracking_fields_test` 175 / 175, R3 không có thay đổi Dart. Không chạy SQL.

### R2 — 2026-11-10 — ❌ CHƯA ĐẠT (4 P1 mới, 0 P2, 3 P3)

**Kết luận: CHƯA ĐẠT.** Phần code đã sửa đúng mọi P1 / P2 của R1 (commit `ad3401262`, `d1c0e81d6`). Còn chặn ở **tệp test SQL**: đọc đối chiếu với schema thì tệp vẫn dừng ngay ở dòng 32, và còn 3 chỗ khác sẽ đỏ. Review Focus 1, 2, 4 chỉ đạt khi tệp chạy xanh trên Dev.

| Việc R1 | Kết quả |
|---|---|
| P1-1 `_assert_actor` đọc `iam.roles` | Đạt. Đọc `iam.memberships.is_owner`, `coalesce` khi không có dòng |
| P1-2 `base_uom` | Đạt. Dùng `catalog._product_base_unit_name` |
| P1-3 tệp SQL đỏ | Đạt 3 chỗ R1 nêu: số sổ qua `_next_ledger_sequence`, có `iam.stores`, user + membership. **Nhưng sinh lỗi mới**, xem R2-1…R2-4 |
| P1-4 thiếu ca SQL | Đạt về số lượng: đủ ca Task 3 / 4 + 3 ca cho P2 (37 ca) |
| P2-1 nút nhanh kho trống | Đạt. `requiresActivation` mặc định `false`; test kiểm 3 nút bật khi `activated = false` |
| P2-2 dòng gốc `RETURN_IN` / `SALE_REVERSAL` | Đạt. Lọc `kind = 'SALE'` + `product_id`; ca 18b cho cả hai hướng sai |
| P2-3 `COUNT_GAIN` nhận giá truyền vào | Đạt. Ghi vào bảng mục 2.3 + "Lệch plan" Task 4 |
| P2-4 "đúng 1 cặp" | Đạt (code dùng `strict`). Ghi chú của review: R1 nêu quá tay. DB đã có `store_warehouse_assignments_one_active_per_tenant` (`20261104001:47`) nên không thể có 2 cặp `active`; nhánh `too_many_rows` chỉ là phòng thủ. Xem R2-2 |
| P2-5 `stock_changes` | Đạt. Gộp theo sản phẩm, `after` = Σ tồn kho của sản phẩm, `before = after − Σ delta`; ca 34b |
| P3-4 lệch plan chưa ghi | Một phần: đã ghi `p_created_by`. Chưa ghi DI `SessionController` và comment route "G5-5" |
| P3-1, P3-2, P3-3, P3-5 | Còn mở, chỉ ghi nhận |

**P1 — chặn (tất cả trong `supabase/tests/inventory_core.sql`)**

- **R2-1** `insert into iam.tenants (id, name, slug)` ở dòng 32, 203, 228, 1021. `iam.tenants` không có `name` / `slug` (`20260630000001`: `id`, `display_name`, `created_at`; các migration sau chỉ thêm `display_name`, `contact_*`…). Tệp dừng ngay ở dòng 32. Sửa: `insert into iam.tenants (id, display_name) values (…)`, như `tests/iam_legacy_cleanup.sql:125`.
- **R2-2** Ca 9b chèn 2 cặp `active` cùng tenant, vi phạm unique index `store_warehouse_assignments_one_active_per_tenant`. Câu `insert` nằm ngoài khối bắt lỗi nên cả tệp đỏ. Sửa: bỏ ca 9b (DB đã đảm bảo), giữ `strict` trong code.
- **R2-3** Dòng 361: `(v_res -> 'movement_ids' -> 0)::text::uuid`. `jsonb::text` giữ dấu nháy (`"…"`) nên ép sang `uuid` lỗi. Sửa: `(v_res -> 'movement_ids' ->> 0)::uuid`.
- **R2-4** Ca 26 (dòng 708–714) chèn `cost_versions (period_month, official_unit_cost, created_by)`. Bảng không có các cột đó, và thiếu 3 cột `not null`: `unit_cost`, `method`, `effective_from_sequence`. Sửa: `insert into inventory.cost_versions (id, tenant_id, product_id, unit_cost, method, effective_from_sequence) values (v_ver_id, v_tenant_id, v_nobi_id, 10500, 'PERIODIC', inventory._next_ledger_sequence(v_tenant_id))`, hoặc dùng `last_ledger_sequence` của `product_costs`.

Sau khi sửa: **người dùng chạy** `supabase/tests/inventory_core.sql` trên Dev (đã dựng lại DB), dán dòng `NOTICE: inventory_core: OK` vào mục 6.

**P3 — ghi nhận**

- **R2-5** Ca 24 lấy `v_cost_before` nhưng không so. Review Focus 2 yêu cầu "`product_costs` như trước". Thêm so `quantity_on_hand`, `ledger_value_vnd`, `moving_avg_cost`.
- **R2-6** `_post_movements` tính `v_base_uom` cho từng dòng nhưng không dùng (`stock_changes` tự tính lại ở bước 7). Bỏ biến và câu gọi thừa.
- **R2-7** Mục 6 Task 4 vẫn ghi "test cases 12–19", chưa cập nhật danh sách 37 ca.
- Phiên sửa R1 đã ghi đè mất mục 7 R1 và dòng trạng thái đầu plan. Phiên review R2 đã ghi lại cả hai.

**Đã chạy (phiên review R2):**
- `flutter test --no-pub -r compact test/features/inventory test/features/catalog/product_tracking_fields_test.dart`: **175 / 175**.
- `dart analyze lib/features/inventory test/features/inventory`: sạch.
- Không chạy SQL. R2-1…R2-4 xác định bằng đối chiếu với schema: `iam.tenants` (`20260630000001`, `20260811006`, `20260811015`), unique index (`20261104001:47`), `inventory.cost_versions` (`20261110001:111–120`). Các ca còn lại đã dò tay từng bước: số liệu Nobivac (1.000.000 → 700.000 → 1.350.000 / 11.250 → 900.000), huỷ bán 100.000, trả hàng 50.000, giá chính thức −105.000, và bất biến cuối tệp đều khớp với code.

### R1 — 2026-11-10 — ❌ CHƯA ĐẠT (4 P1, 5 P2, 5 P3)

**Kết luận: CHƯA ĐẠT.** Vì sao:

- (1) Hai helper lõi đọc **bảng / cột không tồn tại**. plpgsql chỉ báo lỗi khi chạy, nên `get_warehouse_hub_summary` và `_post_movements` lần nào gọi cũng lỗi: Hub trên DB thật không tải được, chưa ghi được tồn.
- (2) Contract test chỉ dò chữ trong tệp, nên vẫn xanh. Tệp `supabase/tests/inventory_core.sql` **chưa được chạy**, và chạy sẽ đỏ ở 3 chỗ.
- (3) Thiếu hầu hết ca SQL mà Review Focus 1, 2, 4 dựa vào. Mục 6 Task 3 / 4 lại ghi "Lệch plan: Không".

| Hạng mục | Kết quả |
|---|---|
| Review Focus 1 — hai người xuất lô cuối | **Chưa chứng minh.** Code đúng thứ tự: khoá advisory theo `product_id` tăng dần rồi mới `select … for update` tồn. Thiếu ca SQL `insufficient_stock_rolls_back_all_lines`. Chặn bởi P1-2 |
| Review Focus 2 — dòng 2 thiếu hàng huỷ cả lệnh | **Chưa chứng minh.** Logic dựa vào giao dịch tự huỷ khi `_raise`. Thiếu ca SQL đếm hai sổ = 0, `product_costs` như trước |
| Review Focus 3 — "Thử lại" không ghi hai lần | Đạt. `_begin_idempotency` chép đúng mẫu `sales._begin_sales_idempotency`; có ca SQL `replay_same_hash_returns_saved_result`, test Flutter `mutate_network_error_rethrows_network`, `retry_uses_same_key` |
| Review Focus 4 — sổ giá trị đúng từng đồng | **Chưa chứng minh.** Luật xuất `MOVING` / `PERIODIC` / giá tạm khớp mục 2.3. Thiếu toàn bộ ca Nobivac, `sale_reversal_exact`, `return_in_original_cost`, `period_closed_blocked`, `ledger_value_invariant` |
| Review Focus 5 — khoá đổi theo dõi lô | Đạt. Trigger `catalog._lock_tracking_after_movement` + ca SQL; UI khoá cả 2 ô gạt + câu Theme 2 nguyên văn |
| Review Focus 6 — không còn đường vào phần bỏ | Đạt. `grep` K2 / K3 / `WarehousePending` / `/warehouse/approvals` rỗng; khu `setup`, `initial_stock`, "Lấy hàng" đã gỡ. Xem P2-1 |

**P1:**
- P1-1 `_assert_actor` `join iam.roles … m.role_id`: không có bảng / cột này; dùng `iam.memberships.is_owner`.
- P1-2 `_post_movements` đọc `catalog.products.base_uom` không có; dùng `catalog._product_base_unit_name`.
- P1-3 tệp SQL đỏ: ca 1 chèn tay `ledger_sequence = 1` trùng với `_next_ledger_sequence`; ca 20–21 vi phạm FK `iam.stores`; user test không có membership.
- P1-4 thiếu ca SQL Task 3 (`non_owner_require_owner_denied`, `no_assignment_context_invalid`) và Task 4 (Nobivac, đảo / trả, kiểm kê tăng, kỳ đóng, huỷ cả lệnh, luật lô, dấu, bất biến).

**P2:**
- P2-1 kho trống thì 2 nút nhanh bị tắt, trái Q-b19.
- P2-2 `RETURN_IN` / `SALE_REVERSAL` không lọc `kind = 'SALE'` + `product_id` khi lấy đơn giá gốc.
- P2-3 `COUNT_GAIN` nhận `unit_cost` / `amount_vnd` truyền vào, lệch mục 2.3 mà chưa ghi.
- P2-4 `_assert_actor` không `strict` khi lấy cặp cửa hàng–kho.
- P2-5 `stock_changes` theo dòng / lô, không theo sản phẩm.

**P3:**
- P3-1 còn `'OPENING'` trong `movement_kind` / `kind`, trái Q-b19.
- P3-2 `expiry_precision` mặc định `'DAY'` khi không có hạn; dùng `lot_id` có sẵn không kiểm `LOT_ATTRIBUTE_CONFLICT`.
- P3-3 sổ chỉ thêm nhưng FK `on delete cascade` / `set null`.
- P3-4 lệch plan chưa ghi: `p_created_by`, DI `SessionController`, comment route `valuation_queue` "G5-5".
- P3-5 tên test Flutter khác plan.

**Đã chạy (phiên review R1):** `flutter test` inventory + `product_tracking_fields_test` 175 / 175; `dart analyze` 0 error, 0 warning, 76 info. Không chạy SQL.
