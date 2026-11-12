# T7-G5-5b — Ghi nhận chiết khấu NCC & so sánh nhà cung cấp

> Theme 7 · plan **G5-5b** của [PLAN.md](../../PLAN.md) mục "Theme 7" (bảng Plan)
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-12) | Làm ✅ 2026-11-12 (chờ chạy Dev reset --linked & commit) | Review ✅ R2 2026-11-12
> Thiết kế: duyệt trong chat 2026-11-12 (2 câu hỏi + 3 phần: dữ liệu + RPC, luật tính, khung màn). Nguồn nghiệp vụ: [spec giá vốn](T7-G5-gia-von-thiet-ke.md) mục 12.4–12.7 (mục 12.5 sửa công thức, xem mục 2.3). **Không có prototype / Screen Contract** ⇒ màn dựng theo khung ASCII mục 2.5 (đã duyệt) + khuôn K1 / K4 + DS. Phụ thuộc: G5-2b (chương trình, P1–P3), G5-3 (`supplier_program_receipts`, `REACHED`, dòng phiếu nhận có giá gốc), G5-0b (`product_costs`, `value_movements`, `_ensure_open_period`).

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Chủ cửa hàng ghi nhận chiết khấu của chương trình loại 3 đã đạt mốc (P4 → K4): phần ứng với hàng còn tồn giảm giá trị tồn bằng dòng sổ `SUPPLIER_REBATE`, phần ứng với hàng đã bán giảm giá vốn của kỳ (lưu ở bảng phân bổ). Mọi người xem được giá vốn dự kiến ở P3 và so sánh nhà cung cấp theo sản phẩm (P5); nhân viên bị che tiền. Hub nhắc chương trình đạt mốc chờ ghi nhận.

**Architecture:** Migration mới `20261117001_inventory_supplier_rebates.sql` gồm 2 bảng, helper `_post_value_adjustment` (dòng sổ chỉ đổi giá trị, G5-6 dùng lại), hàm phân bổ thuần `_rebate_allocation`, 4 RPC mới. Sửa `get_supplier_program` (tại `20261113001`) và `get_warehouse_hub_summary` (tại `20261110001`). **Không** sửa `_value_line` / `_post_movements`. Flutter: BJ mới `features/inventory/{data,logic,presentation}/supplier_rebate/` (P4, K4, P5, khối dự kiến), thêm vào P3 / P2 / chi tiết tồn / dòng phiếu nhận / Hub.

**Tech Stack:** PostgreSQL / Supabase (plpgsql), Flutter, `flutter_bloc`, `go_router`, `get_it`, `vet45_design_system`.

**Spec:** mục 1–2 của plan này + [spec giá vốn](T7-G5-gia-von-thiet-ke.md) mục 12 + PLAN.md Theme 7 → "Quy ước chung cho mọi plan G5".

## Global Constraints

- Quy ước chung: PLAN.md Theme 7 → "Quy ước chung cho mọi plan G5". Mục "UI Flutter: trích code prototype" **không áp được** (không có prototype): thay bằng khung ASCII + bảng ánh xạ mục 2.5; phiên code không thêm phần tử ngoài bảng.
- Header migration theo khuôn `20261110001_inventory_core.sql`; cập nhật `REGISTRY.yaml`. Hàm đã có sửa **thẳng migration gốc** (`get_supplier_program` ở `20261113001`, `get_warehouse_hub_summary` ở `20261110001`). FK `value_movements.supplier_rebate_id → supplier_rebates` đặt trong migration mới (`alter table … add constraint`), vì bảng đích chưa tồn tại lúc chạy `20261110001`.
- Hàm Kho mới: `security definer`, `set search_path = inventory, iam, catalog, partner, pg_temp`. RPC công khai có `grant execute … to authenticated` và gọi `inventory._assert_actor(p_tenant_id, 'inventory.read')` đầu tiên. **Quyền (Q-5b-1):** `preview_supplier_rebate`, `record_supplier_rebate` yêu cầu `(v_actor->>'is_owner')::boolean`, khác ⇒ `_raise('PERMISSION_DENIED', …)`. `get_projected_cost`, `compare_suppliers`, `get_supplier_program`: mọi người đọc; nhân viên nhận khoá tiền = `null` + `financial_masked: true` (khuôn `get_stock_detail`). Hàm `_` có `revoke all … from public, anon, authenticated`, không `grant`.
- **Ngày ghi sổ (Q-5b-2):** `business_date = inventory._today()`. `document_date` chỉ lưu, trong `[started_on, _today()]`.
- Tiền `bigint` (đồng), làm tròn nửa lên (`round()` của numeric); đơn giá / bình quân `numeric(18,4)`; số lượng theo **ĐVT cơ sở**. Hiển thị: `formatQuantity`, `MoneyFormatter.formatMinor(int)`; bình quân `MoneyFormatter.formatMinor(value.round())` + `'/$uom'`.
- Chạy SQL: `tools/db_check.sh` (đủ 3 bước) phải ✅ trước khi báo xong task có SQL; chỉ một tệp: `tools/db_check.sh --no-reset inventory_supplier_rebates`. Reset Dev (`--linked`) **hỏi người dùng**.
- Flutter: `dart analyze` (không `flutter analyze`). Test: `cd apps/erp && flutter test --no-pub -r compact <đường dẫn>`. Số test đỏ không hơn `docs/refactor/TEST-BASELINE.md`.
- Chữ trên màn: **nguyên văn** mục 2.4 / 2.5. Tiêu đề màn dùng "nhà cung cấp" đầy đủ; "NCC" chỉ ở chỗ mục 2.5 ghi.
- Trước khi sửa symbol đã có (`inventory.get_supplier_program`, `inventory.get_warehouse_hub_summary`, `ProgramDetail`, `ProgramDetailPage`, `ProgramDetailCubit`, `ProgramFormPage`, `ProgramFormCubit.startCreate`, `supplierProgramRoutes`, `stockRoutes`, `StockDetailBody`, `ReceiptLineEditor`, `WarehouseHubRepository`, `WarehouseHubSummary`, `WarehouseHubPage`, `inventoryErrorMessage`, `InventoryErrorCode`, `app_router.dart`, `injection.dart`): chạy `impact({target, direction: "upstream"})`, ghi Kết quả; HIGH / CRITICAL ⇒ dừng, báo người dùng. Task cuối: `detect_changes({scope: "compare", base_ref: "main"})`.
- `AGENTS.md`, `CLAUDE.md`: không `git add`. Ghi mục 5 Kết quả sau mỗi task. Làm từng task một, mỗi task một commit.

## Review Focus

1. **Hai lần ghi nhận cùng chương trình** (bấm hai lần; hai chủ cửa hàng cùng lúc) ⇒ đúng một `supplier_rebates`, một bộ dòng sổ; cùng khoá ⇒ trả kết quả lần đầu; khoá khác sau khi đã ghi ⇒ `PROGRAM_NOT_REACHED`, P4 hiện `InventoryStale` "Chương trình đã được ghi nhận chiết khấu" + "Xem chương trình". Test: Task 1 `record_replay_same_key`, `record_twice_other_key`; Task 5 `record_already_recorded_stale_390`.
2. **Bán xen giữa xem trước và ghi** ⇒ ghi theo tồn lúc ghi, không theo số xem trước; K4 có dòng "Tồn đã đổi từ lúc xem trước, số đã tính lại theo tồn hiện tại." Test: Task 1 `record_recomputes_after_sale`; Task 5 `result_shows_changed_note`.
3. **Ô số tiền**: gõ "5.000.000" / "5000000" đều ra 5.000.000; sửa khác đề xuất ⇒ hiện ô lý do; sửa về đúng đề xuất ⇒ ẩn ô lý do và payload không có lý do; `0` / `> base` / chữ ⇒ lỗi dưới ô, không gọi xem trước. Test: Task 3 `parse_amount`, `amount_errors`, `reason_needed_only_when_override`; Task 4 `payload_drops_reason_when_equal`.
4. **Sản phẩm tồn 0 hoặc giá trị sổ nhỏ** ⇒ không ghi dòng sổ cho sản phẩm tồn 0 (toàn bộ vào giá vốn); phần tồn không vượt `ledger_value_vnd`, giá trị sổ không âm. Test: Task 1 `zero_stock_all_cogs`, `cap_by_ledger_value`.
5. **Nhân viên** mở `/…/rebate` bằng URL ⇒ `InventoryLocked` "Chỉ chủ cửa hàng ghi nhận được chiết khấu."; P3 / P5 hiện "—" ở ô tiền; Hub không có dòng đạt mốc; RPC trả `null` + `financial_masked`. Test: Task 1 `staff_denied_and_masked`; Task 2 `staff_masked_projection_compare`; Task 5 `staff_locked_390`; Task 7 `compare_staff_masked_390`.

---

## 1. Quyết định (người dùng, 2026-11-12)

| Q | Nội dung |
|---|---|
| Q-5b-1 | **Chủ cửa hàng ghi, ai cũng xem**: ghi nhận (P4, nút ở P3) chỉ `is_owner`; giá vốn dự kiến và P5 mọi người xem, nhân viên bị che tiền. Khác Q-2b-4 (chương trình không chia quyền) vì ghi nhận ghi vào sổ giá trị |
| Q-5b-2 | **Ngày ghi sổ = hôm nay** (`_today()`); ngày chứng từ chỉ để tra, ≤ hôm nay |
| Q-5b-3 | Dòng sổ chỉ đổi giá trị đi qua helper mới `_post_value_adjustment` (cách A); không đụng `_value_line` |

**Mặc định đã báo trong chat (duyệt cùng thiết kế):** sửa công thức giá vốn dự kiến spec 12.5 cho đúng từng sản phẩm (mục 2.3); phần tồn không vượt giá trị sổ, dư vào giá vốn; ghi nhận xong **không đảo** (sổ chỉ thêm); phiên kiểm kê đang mở **không** chặn ghi nhận (ghi nhận không đổi số lượng).

**Thêm lúc viết plan (duyệt cùng plan):**

| Chỗ | Nội dung | Lý do |
|---|---|---|
| FK `value_movements.supplier_rebate_id` | Đặt ở migration mới bằng `alter table` | Bảng `supplier_rebates` chưa có khi chạy `20261110001` |
| `get_supplier_program` | Thêm `viewer_is_owner` | P3 cần biết có hiện nút "Ghi nhận chiết khấu" không |
| P3 `REACHED` | Băng "Đã đạt mốc, chờ ghi nhận chiết khấu" giữ nguyên chữ, **không** thêm nút trong băng; nút "Ghi nhận chiết khấu" chỉ ở chân | Tránh hai nút cùng việc trên một màn |
| K4 "tồn đã đổi" | So `Σ inventory_part` lúc ghi với số xem trước truyền qua `extra` của route; mở K4 từ URL (không có `extra`) ⇒ không hiện dòng này | K4 nạp lại từ server không có số xem trước |

## 2. Thiết kế

### 2.1 Dữ liệu (`supabase/migrations/20261117001_inventory_supplier_rebates.sql`)

Mọi bảng: `tenant_id uuid not null → iam.tenants`, RLS bật, `revoke all … from public, anon, authenticated`.

| Bảng | Cột | Ràng buộc |
|---|---|---|
| `supplier_rebates` | `id uuid pk`, `program_id uuid not null → supplier_programs`, `document_no text`, `document_date date`, `base_amount_vnd bigint`, `proposed_amount_vnd bigint`, `rebate_amount_vnd bigint`, `override_reason text null`, `business_date date`, `recorded_by uuid`, `recorded_at timestamptz default now()` | `unique (program_id)`; `length(btrim(document_no)) between 1 and 60`; `rebate_amount_vnd between 1 and base_amount_vnd`; `(rebate_amount_vnd = proposed_amount_vnd) or (override_reason is not null and length(btrim(override_reason)) between 1 and 300)` |
| `supplier_rebate_allocations` | `rebate_id uuid → supplier_rebates on delete cascade`, `product_id uuid → catalog.products`, `paid_qty numeric`, `purchase_amount_vnd bigint`, `rebate_part_vnd bigint`, `on_hand_qty numeric`, `inventory_part_vnd bigint`, `cogs_part_vnd bigint`, `avg_cost_before numeric(18,4)`, `avg_cost_after numeric(18,4)`, `value_movement_id uuid null → value_movements` | PK `(rebate_id, product_id)`; `inventory_part_vnd >= 0 and cogs_part_vnd >= 0`; `inventory_part_vnd + cogs_part_vnd = rebate_part_vnd`; `value_movement_id is null` ⇔ `inventory_part_vnd = 0` |

Cả hai bảng có trigger `before update or delete … execute function inventory._forbid_ledger_mutation()` (chỉ thêm). `alter table inventory.value_movements add constraint value_movements_supplier_rebate_fk foreign key (supplier_rebate_id) references inventory.supplier_rebates (id)`.

### 2.2 Hàm + RPC

| Hàm | Vào | Luật / Ra |
|---|---|---|
| `_post_value_adjustment(p_tenant_id uuid, p_product_id uuid, p_kind text, p_amount_vnd bigint, p_business_date date, p_cost_run_id uuid, p_supplier_rebate_id uuid, p_created_by uuid default auth.uid()) returns jsonb` | — | `p_kind in ('SUPPLIER_REBATE','COGS_TRUE_UP','LOSS_TRUE_UP','REVALUE_ROUNDING')`, khác ⇒ `CONTEXT_INVALID`. Đọc `product_costs … for update` (thiếu dòng ⇒ `CONTEXT_INVALID`). `V += amount`; `m = round(V / q, 4)` khi `q > 0`, giữ `m` khi `q = 0`; `V` mới < 0 ⇒ `CONTEXT_INVALID`. `_next_ledger_sequence` → insert `value_movements` (`movement_id null`, `quantity_basis 0`, `unit_cost null`, `cost_run_id`, `supplier_rebate_id`) → `last_ledger_sequence`. Trả `{value_movement_id, ledger_sequence, avg_before, avg_after, value_before, value_after}`. **Không** khoá advisory — người gọi khoá |
| `_rebate_allocation(p_tenant_id uuid, p_program_id uuid, p_amount_vnd bigint) returns table (product_id uuid, paid_qty numeric, purchase_amount_vnd bigint, rebate_part_vnd bigint, on_hand_qty numeric, ledger_value_vnd bigint, avg_cost_before numeric, inventory_part_vnd bigint, cogs_part_vnd bigint)` | — | Luật mục 2.3 "Phân bổ". Thuần đọc; dùng chung cho xem trước và ghi |
| `preview_supplier_rebate(p_tenant_id uuid, p_program_id uuid, p_amount_vnd bigint default null) returns jsonb` | `null` = dùng đề xuất | Chỉ owner. Chương trình không thuộc tenant ⇒ `CONTEXT_INVALID`; `kind <> 'VOLUME_REBATE'` hoặc `status <> 'REACHED'` ⇒ `PROGRAM_NOT_REACHED`; `p_amount_vnd` ngoài `[1, base]` ⇒ `REBATE_AMOUNT_INVALID`. Ra `RebatePreview` (dưới) |
| `record_supplier_rebate(p_tenant_id uuid, p_idempotency_key text, p_program_id uuid, p_payload jsonb) returns jsonb` | `{document_no, document_date, amount_vnd, override_reason?}` | Chỉ owner. Scope `'supplier_rebate.record'`, hash `md5(payload)`. Thứ tự: (1) `select … from supplier_programs where id = … for update`; không `REACHED` ⇒ `PROGRAM_NOT_REACHED`; (2) kiểm payload: `document_no` sau `btrim` 1–60 và `document_date` trong `[started_on, _today()]` (sai ⇒ `CONTEXT_INVALID`), số tiền ⇒ `REBATE_AMOUNT_INVALID`, `amount ≠ proposed` mà lý do rỗng / > 300 ⇒ `REBATE_REASON_REQUIRED`; (3) `_ensure_open_period(tenant, _today())`; (4) `pg_advisory_xact_lock(hashtext(tenant::text), hashtext(product::text))` theo `product_id` tăng dần (cùng khoá `_post_movements`); (5) `_rebate_allocation` **sau** khoá; (6) insert `supplier_rebates`; mỗi sản phẩm `inventory_part > 0` ⇒ `_post_value_adjustment(…, 'SUPPLIER_REBATE', −inventory_part, _today(), null, rebate_id)`; insert allocations (`avg_cost_after` = kết quả helper, hoặc `= avg_cost_before` khi không ghi dòng); (7) chương trình `status 'RECORDED'`, `revision + 1`. Ra `RebatePreview` + `{rebate_id, document_no, document_date, recorded_at}` |
| `get_projected_cost(p_tenant_id uuid, p_program_id uuid, p_product_id uuid, p_extra_qty numeric default null, p_unit_price numeric default null) returns jsonb` | ĐVT cơ sở | Chương trình `VOLUME_REBATE`, `ACTIVE`, có sản phẩm (sai ⇒ `CONTEXT_INVALID`); `p_extra_qty <= 0` hoặc `p_unit_price < 0` ⇒ `CONTEXT_INVALID`. Ra `{product_id, uom, progress_qty, target_qty, missing_qty: greatest(target − progress − coalesce(x,0), 0), reaches_target (null khi x null), rebate_estimate, avg_now, avg_projected, default_unit_price, financial_masked}`; x hoặc u `null` ⇒ `rebate_estimate`, `avg_projected` `null`. Luật mục 2.3 "Dự kiến". Không ghi gì |
| `compare_suppliers(p_tenant_id uuid, p_product_id uuid) returns jsonb` | — | Sản phẩm không thuộc tenant ⇒ `CONTEXT_INVALID`. Ra `{product: {product_id, name ← products.name, code ← products.sku, uom ← catalog._product_base_unit_name}, financial_masked, suppliers: [SupplierCompareRow]}` — luật mục 2.3 "So sánh" |
| `get_supplier_program` (sửa, `20261113001`) | — | Thêm `viewer_is_owner` và `rebate: {rebate_id, document_no, document_date, base_amount_vnd, proposed_amount_vnd, rebate_amount_vnd, override_reason, inventory_part_vnd (Σ), cogs_part_vnd (Σ), recorded_at, recorded_by_name ← iam._member_display_name, allocations: [{product_id, name, uom, paid_qty, on_hand_qty, rebate_part_vnd, inventory_part_vnd, cogs_part_vnd, avg_cost_before, avg_cost_after}]} \| null`. Nhân viên: mọi khoá `*_vnd`, `avg_*` = `null` |
| `get_warehouse_hub_summary` (sửa, `20261110001`) | — | `problems` thêm `programs_reached` = số `supplier_programs` `status 'REACHED'` khi `is_owner`, ngược lại `0` |

`RebatePreview = {program_id, program_name, supplier_name, target_qty, progress_qty, rebate_percent, uom (common_uom), base_amount_vnd, proposed_amount_vnd, amount_vnd, allocations: [{product_id, name ← products.name, uom, paid_qty, purchase_amount_vnd, rebate_part_vnd, on_hand_qty, inventory_part_vnd, cogs_part_vnd, avg_cost_before, avg_cost_after}], inventory_part_total, cogs_part_total}`. Xem trước: `avg_cost_after = round((V − inventory_part) / q, 4)` khi `q > 0`, ngược lại `avg_cost_before`. `allocations` sắp `rebate_part_vnd desc`, rồi `name`.

Mã lỗi mới (`inventory._raise`): `PROGRAM_NOT_REACHED`, `REBATE_AMOUNT_INVALID`, `REBATE_REASON_REQUIRED`.

### 2.3 Luật tính

**Căn cứ** (nối `supplier_program_receipts r` ↔ `goods_receipt_lines l on l.id = r.receipt_line_id`): `base = Σ r.purchase_amount_vnd`; theo sản phẩm `base_p = Σ r.purchase_amount_vnd`, `Q_p = Σ r.paid_qty` (đã là ĐVT cơ sở, G5-3) nhóm theo `l.product_id`. `proposed = round(base × rebate_percent / 100)`.

**Phân bổ** (`_rebate_allocation`, chỉ sản phẩm có `base_p > 0`):
1. `rebate_part_p = floor(R × base_p / base)`; phần dư `R − Σ` cộng vào sản phẩm có `base_p` lớn nhất, bằng nhau ⇒ `product_id` nhỏ nhất.
2. `q = product_costs.quantity_on_hand`, `V = ledger_value_vnd`, `m = moving_avg_cost` (không có dòng ⇒ 0 / 0 / 0).
3. `inv_raw_p = round(rebate_part_p × least(q, Q_p) / Q_p)`.
4. `inventory_part_p = least(inv_raw_p, greatest(V, 0))`; `cogs_part_p = rebate_part_p − inventory_part_p`.

**Dự kiến** (`get_projected_cost`, sản phẩm `p`, `x` SL mua thêm, `u` đơn giá mua): `reaches = progress_qty + x >= target_qty`; `R_p = round((base_p + x·u) × % / 100)`; `inv_p = R_p × least(q + x, Q_p + x) / (Q_p + x)`; `avg_projected = round((V + x·u − (reaches ? inv_p : 0)) / (q + x), 4)`; `rebate_estimate = reaches ? R_p : null`; `avg_now = m`. `default_unit_price = round(l.purchase_amount_vnd / (l.paid_qty × l.conversion_rate))` của dòng phiếu mới nhất (`goods_receipts.business_date desc, created_at desc`) có `supplier_id` = NCC chương trình và `product_id = p`; không có ⇒ `null`. **Lệch spec 12.5** (dùng `R_dk` cả chương trình): ghi vào báo cáo đồ án.

**So sánh** (`compare_suppliers`): mỗi `goods_receipts.supplier_id` có dòng của sản phẩm ⇒ một `SupplierCompareRow = {partner_id, name ← partners.display_name, is_system, last_landed_unit_cost ← landed_unit_cost dòng mới nhất, last_received_on ← business_date dòng đó, avg_landed_unit_cost = round(Σ landed_amount_vnd / Σ ((paid_qty + free_qty) × conversion_rate), 4), receipt_count = count(distinct receipt_id), paid_qty = Σ paid_qty × rate, free_qty = Σ free_qty × rate, program, other_program}`. Chương trình hiệu lực của NCC (`ACTIVE` / `REACHED`, tối đa 1 — Q-2b-3): có sản phẩm ⇒ `program = {program_id, name, kind, status, tiers, buy_qty, free_qty, target_qty, rebate_percent, progress_qty, common_uom}`; không có sản phẩm ⇒ `other_program = {program_id, name}`; `is_system` ⇒ cả hai `null`. Sắp `is_system` (false trước), rồi `avg_landed_unit_cost` tăng dần. Nhân viên: `last_landed_unit_cost`, `avg_landed_unit_cost` = `null`.

**Ví dụ / ca test** (`supabase/tests/inventory_supplier_rebates.sql`):

| Ca | Dữ liệu | Kỳ vọng |
|---|---|---|
| `case14_single_product` | Chương trình 1.000 hộp 5%; phiếu 400 + 600 × 100.000; bán 700 ⇒ tồn 300 | `base 100.000.000`, `proposed 5.000.000`; phần tồn 1.500.000, giá vốn 3.500.000; `ledger_value` 30.000.000 → 28.500.000; `moving_avg_cost` 100.000 → 95.000; một dòng `SUPPLIER_REBATE −1.500.000`, `quantity_basis 0` |
| `case15a_remainder` | 3 sản phẩm cùng ĐVT, mỗi sản phẩm mua 30.000.000 (300 × 100.000), `R` 1.000.000 (lý do có) | `rebate_part` 333.334 cho `product_id` nhỏ nhất, 333.333 / 333.333; `Σ = 1.000.000` |
| `case15b_stock_over_q` | Tồn 800 (200 nhập trước chương trình + 600 trong chương trình), `Q 600` | `inventory_part = rebate_part` |
| `zero_stock_all_cogs` | Bán hết trước khi ghi | không dòng sổ cho sản phẩm đó; `value_movement_id null`; `cogs_part = rebate_part` |
| `cap_by_ledger_value` | NCC B nhập 90 hộp × 1.000; chương trình NCC A mốc 10 hộp 100%, nhập 10 × 100.000 (`REACHED`) ⇒ tồn 100, `V` 1.090.000, bq 10.900; bán 95 ⇒ tồn 5, `V` 54.500; ghi `R` 1.000.000 | `inv_raw` 500.000 > `V` ⇒ `inventory_part 54.500`, `cogs_part 945.500`; `ledger_value` sau `= 0` |
| `record_recomputes_after_sale` | Xem trước với tồn 300 ⇒ bán 100 ⇒ ghi | phần tồn 1.000.000 (theo tồn 200), không phải 1.500.000 |
| `record_replay_same_key` / `record_twice_other_key` | Ghi 2 lần cùng khoá; lần 3 khoá khác | cùng `rebate_id`, số dòng sổ không đổi; lần 3 ⇒ `PROGRAM_NOT_REACHED` |
| `preview_errors` | Chương trình `ACTIVE`; `amount 0`; `amount base + 1` | `PROGRAM_NOT_REACHED`; `REBATE_AMOUNT_INVALID` × 2 |
| `record_validation` | `R ≠ proposed`, lý do `'  '`; `document_date` mai; `document_no ''` | `REBATE_REASON_REQUIRED`; `CONTEXT_INVALID` × 2; chương trình vẫn `REACHED` |
| `period_closed` | Đặt tay `cost_periods` tháng này `CLOSED` | `PERIOD_CLOSED`, không bản ghi nào |
| `staff_denied_and_masked` | Nhân viên gọi preview / record; đọc `get_supplier_program` đã ghi nhận | `PERMISSION_DENIED` × 2; `rebate.rebate_amount_vnd` `null`, `viewer_is_owner false` |
| `projected_reach` | `progress 400` (40.000.000, tồn 400, `V` 40.000.000); `x 600`, `u 100.000` | `reaches_target true`, `rebate_estimate 5.000.000`, `avg_projected 95.000`; `x 500` ⇒ `false`, `missing_qty 100`, `avg_projected 100.000`, `rebate_estimate null`; `default_unit_price 100.000`; số dòng `value_movements` không đổi |
| `staff_masked_projection_compare` | Nhân viên gọi 2 RPC đọc | `avg_*`, `rebate_estimate`, `default_unit_price`, `*_landed_unit_cost` `null`; `financial_masked true`; `reaches_target` vẫn có |
| `compare_rows` | NCC A 2 phiếu (landed 95.000 / 99.400 mỗi hộp, SL 500 / 500) + chương trình chứa SP; NCC B 1 phiếu 1 hộp tặng kèm; "Mua lẻ / khác" 1 phiếu 110.000 | A `avg 97.200`, `receipt_count 2`, `program` có; B `free_qty > 0`; "Mua lẻ / khác" cuối, `program null`; NCC có chương trình không chứa SP ⇒ `other_program` |
| `hub_programs_reached` | 1 chương trình `REACHED` | owner ⇒ `programs_reached 1`; nhân viên ⇒ `0`; sau ghi nhận ⇒ `0` |
| bất biến (sau mọi ca ghi) | — | theo sản phẩm `product_costs.ledger_value_vnd = Σ value_movements.amount_vnd`; `Σ rebate_part_vnd = rebate_amount_vnd`; số dòng `value_movements` cũ không đổi |

Ca 16 (`PERIODIC` + lần tính) thuộc G5-6.

### 2.4 Luật Flutter (`logic/supplier_rebate/rebate_rules.dart`) + mã lỗi

- `parseMoneyInput(String) → int?`: bỏ `.`, khoảng trắng, `đ`; chỉ chữ số ⇒ `int`; rỗng / có ký tự khác ⇒ `null`.
- `rebateAmountError(int? amount, int base) → String?`: `null` ⇒ `'Nhập số tiền ghi nhận'`; `< 1` hoặc `> base` ⇒ `'Số tiền từ 1 đ đến ${MoneyFormatter.formatMinor(base)}'`.
- `needsOverrideReason(int? amount, int proposed) → bool` = `amount != null && amount != proposed`. Lỗi lý do rỗng: `'Nhập lý do khi số tiền khác đề xuất'`; > 300 ký tự: `'Lý do tối đa 300 ký tự'`.
- `documentNoError`: rỗng sau `trim` ⇒ `'Nhập số chứng từ'`; > 60 ⇒ `'Số chứng từ tối đa 60 ký tự'`. `documentDateError(date, startedOn, today)`: ngoài khoảng ⇒ `'Ngày chứng từ không được sau hôm nay hoặc trước ngày bắt đầu chương trình'`.
- `cheapestSupplierId(List<SupplierCompareRow>) → String?`: trong các dòng `!isSystem && avgLandedUnitCost != null`, cần ≥ 2 dòng; trả `partnerId` có bình quân nhỏ nhất (bằng nhau ⇒ dòng đầu); khác ⇒ `null`.
- `stockChangedSincePreview(int? previewInventoryTotal, int recordedInventoryTotal) → bool` = `previewInventoryTotal != null && previewInventoryTotal != recordedInventoryTotal`.

| Mã | Câu (`inventoryErrorMessage`) |
|---|---|
| `PROGRAM_NOT_REACHED` | `'Chương trình chưa đạt mốc hoặc đã ghi nhận chiết khấu.'` |
| `REBATE_AMOUNT_INVALID` | `'Số tiền ghi nhận phải từ 1 đ đến tổng tiền mua.'` |
| `REBATE_REASON_REQUIRED` | `'Nhập lý do khi số tiền khác đề xuất.'` |

### 2.5 Màn (khung đã duyệt 2026-11-12) + ánh xạ Flutter

Route (con của `/warehouse/supplier-programs/:programId` trong `supplierProgramRoutes`): `rebate` (P4), `rebate/result` (K4). P5: con `suppliers` của `/warehouse/stock/:productId` trong `stockRoutes`. Mọi màn ngoài `StatefulShellRoute` (PLAN "Điều hướng"). P2 tạo nhận thêm `?productId=`.

**P3 — khối "Giá vốn dự kiến"** (loại 3 `ACTIVE`, sau khối "Tiến độ"):
```
│ ┌ Giá vốn dự kiến ─────────── Dự kiến, chưa ghi sổ ┐
│ │ Sản phẩm   [Nobivac DHPPi ▾]   (ẩn khi chỉ 1 SP) │
│ │ Mua thêm   [ 600 ] hộp                            │
│ │ Đơn giá    [ 100.000 ] đ/hộp  (gồm VAT)           │
│ │ ✓ Đạt mốc 1.000 hộp sau lần mua này               │
│ │ Chiết khấu ước tính        5.000.000 đ            │
│ │ Bình quân hiện tại           100.000 đ/hộp        │
│ │ Bình quân dự kiến             95.000 đ/hộp        │
│ └───────────────────────────────────────────────────┘
```

| Phần tử | Flutter | Tham số |
|---|---|---|
| Khung | `VSection(title: 'Giá vốn dự kiến', trailing: VBadge(label: 'Dự kiến, chưa ghi sổ', tone: neutral))` | widget `ProjectedCostSection(programId, products)` trong `presentation/supplier_rebate/` |
| Sản phẩm | `VSelect` (`ProgramDetail.products`), mặc định sản phẩm đầu | ẩn khi `products.length == 1` |
| Mua thêm | `VNumberField(label: 'Mua thêm', suffix: uom)` | |
| Đơn giá | `VNumberField(label: 'Đơn giá', suffix: 'đ/$uom', helper: 'Gồm VAT')` | điền `default_unit_price` khi tải lần đầu / đổi sản phẩm |
| Trạng thái mốc | `reaches_target` ⇒ `VText('Đạt mốc {target} {uom} sau lần mua này', tone success, icon VIcons.success)`; ngược lại `VText('Còn thiếu {missing_qty} {uom} để đạt mốc')` | ẩn khi x trống / 0 |
| Kết quả | `VKeyValueRow('Chiết khấu ước tính', money, mono)` (chỉ khi đạt), `VKeyValueRow('Bình quân hiện tại', …)`, `VKeyValueRow('Bình quân dự kiến', …)` | nhân viên: giá trị `'—'`; gọi RPC sau 400 ms kể từ lần gõ cuối |
| Lỗi | `VText('Không tính được giá vốn dự kiến.')` + `VButton('Thử lại', tertiary)` | không chặn phần còn lại của P3 |

**P3 — `REACHED`:** chân `InventoryFooter`: "Kết thúc chương trình" (secondary, tone danger) · **"Ghi nhận chiết khấu"** (primary, chỉ khi `viewer_is_owner`) ⇒ `push('…/:programId/rebate')`. Không có khối dự kiến.

**P3 — `RECORDED`:** thay khối dự kiến:
```
│ ┌ Chiết khấu đã ghi nhận ─────────────────┐
│ │ Chứng từ        CK-2026-11 · 12/11/2026 │
│ │ Số tiền                   5.000.000 đ   │
│ │ Giảm giá trị tồn          1.500.000 đ   │
│ │ Giảm giá vốn hàng đã bán  3.500.000 đ   │
│ │ Ghi nhận lúc   12/11/2026 14:05         │
│ └─────────────────────────────────────────┘
```
`VSection('Chiết khấu đã ghi nhận')` + `VKeyValueGroup`: "Chứng từ" (`'$documentNo · dd/MM/yyyy'`), "Số tiền", "Giảm giá trị tồn", "Giảm giá vốn hàng đã bán" (mono; nhân viên `'—'`), "Lý do khác đề xuất" (chỉ khi có), "Ghi nhận lúc" (`dd/MM/yyyy HH:mm`).

**P4 — Ghi nhận chiết khấu** (iPhone 390; web cột `VContentWidth` 720, bảng phân bổ dạng bảng):
```
┌ ‹ Mốc 1.000 hộp Q4   Ghi nhận chiết khấu ┐
│ ┌ Căn cứ ─────────────────────────────────┐
│ │ Nhà cung cấp     NCC A                  │
│ │ Đã mua           1.000 / 1.000 hộp      │
│ │ Tổng tiền mua    100.000.000 đ          │
│ │ Mức chiết khấu   5%                     │
│ │ Đề xuất          5.000.000 đ            │
│ └─────────────────────────────────────────┘
│ Số chứng từ *     [ CK-2026-11       ]
│ Ngày chứng từ *   [ 12/11/2026       ]
│ Số tiền ghi nhận * [ 5.000.000 ] đ
│ Lý do khác đề xuất * [            ]   (chỉ hiện khi số ≠ đề xuất)
│ ┌ Phân bổ (xem trước) ────────────────────┐
│ │ Nobivac DHPPi                5.000.000 đ│
│ │  Tồn 300 / mua 1.000 hộp               │
│ │  Giảm giá trị tồn            1.500.000 đ│
│ │  Giảm giá vốn hàng đã bán    3.500.000 đ│
│ │  Bình quân   100.000 → 95.000 đ/hộp    │
│ │ ─────────────────────────────────────── │
│ │ Tổng  tồn 1.500.000 · giá vốn 3.500.000 │
│ └─────────────────────────────────────────┘
│ ⓘ Hàng đang tồn được coi là thuộc các lần nhập của chương trình (tối đa số đã mua). Ghi nhận xong không sửa được.
│ [  Huỷ  ]                 [ Ghi nhận ]
```

| Phần tử | Flutter | Tham số |
|---|---|---|
| Khung | `VPageScaffold(title: 'Ghi nhận chiết khấu')`, nút quay lại về P3 | |
| Căn cứ | `VSection('Căn cứ')` + `VKeyValueGroup`: "Nhà cung cấp", "Đã mua" (`'{progress} / {target} {uom}'`), "Tổng tiền mua", "Mức chiết khấu" (`'{%}%'`, định dạng như `programSummary`), "Đề xuất" | tiền mono |
| Số chứng từ | `VTextField(label: 'Số chứng từ', maxLength: 60)` | |
| Ngày chứng từ | `VDatePicker(label: 'Ngày chứng từ')` mặc định hôm nay, `firstDate: startedOn`, `lastDate: today` | |
| Số tiền | `VTextField(label: 'Số tiền ghi nhận', suffix: 'đ', keyboardType: number)`, mặc định `proposed` định dạng nghìn | đổi hợp lệ ⇒ gọi xem trước sau 400 ms |
| Lý do | `VTextArea(label: 'Lý do khác đề xuất', maxLength: 300)` | chỉ khi `needsOverrideReason` |
| Phân bổ | `VSection('Phân bổ (xem trước)')`; iPhone mỗi sản phẩm một khối: `VText(name)` + tiền `rebate_part`; `'Tồn {on_hand} / mua {paid_qty} {uom}'`; 2 `VKeyValueRow`; `'Bình quân {before} → {after} đ/{uom}'`; dòng tổng `'Tổng  tồn {Σ} · giá vốn {Σ}'`. Web 1280: bảng cột "Sản phẩm" · "Tồn / mua" · "Chiết khấu" · "Giảm giá trị tồn" · "Giảm giá vốn" · "Bình quân" | đang tải lại ⇒ `VSkeleton` thay khối |
| Ghi chú | `VBanner(info, 'Hàng đang tồn được coi là thuộc các lần nhập của chương trình (tối đa số đã mua). Ghi nhận xong không sửa được.')` | |
| Chân | `InventoryFooter`: "Huỷ" (secondary, `pop`) · "Ghi nhận" (primary, `loading` khi đang ghi) | bấm "Ghi nhận" có lỗi ⇒ hiện mọi lỗi dưới ô |
| Xác nhận | `showVAdaptiveSheet`: tiêu đề `'Ghi nhận chiết khấu {R}?'`, nội dung `'Giá trị tồn và bình quân của {n} sản phẩm sẽ giảm. Không hoàn tác được.'`, nút "Ghi nhận" (primary) · "Huỷ" | `n` = số dòng `inventory_part > 0` |
| Không phải owner | `InventoryLocked(title: 'Chỉ chủ cửa hàng ghi nhận được chiết khấu.')` + "Về chương trình" | từ `viewer_is_owner` của `get_supplier_program`, trước khi gọi xem trước |
| Không `REACHED` (lúc mở) | `InventoryLocked(title: 'Chương trình chưa đạt mốc hoặc đã ghi nhận.')` + "Về chương trình" | |
| `PROGRAM_NOT_REACHED` lúc ghi | `InventoryStale(title: 'Chương trình đã được ghi nhận chiết khấu', action: 'Xem chương trình')` | |
| `PERIOD_CLOSED` / lỗi khác lúc ghi | `VBanner(danger, inventoryErrorMessage(code))` trên chân, form giữ nguyên | |
| Đang tải / lỗi tải | `InventoryLoading`, `InventoryEmpty('Không tải được chương trình', 'Thử lại')` | |

**K4 — Kết quả** (`K4ResultPage`, không nút quay lại; nạp `get_supplier_program`, đọc `rebate`):

| Tham số | Giá trị |
|---|---|
| `screenTitle` / `title` | `'Kết quả'` / `'Đã ghi nhận chiết khấu'` |
| `description` | `'{R} từ {NCC} cho chương trình "{tên}".'` |
| `facts` | `'Giảm giá trị tồn'`, `'Giảm giá vốn hàng đã bán'`, `'Chứng từ'` (`'$documentNo · dd/MM/yyyy'`) |
| `stockChanges` | mỗi allocation `avg_cost_after ≠ avg_cost_before`: `K4StockChange` với nhãn `'Bình quân đã đổi: {SP}'`, trước / sau `'{money}/{uom}'` |
| `extra` | `stockChangedSincePreview` ⇒ `VText('Tồn đã đổi từ lúc xem trước, số đã tính lại theo tồn hiện tại.')` |
| `next` | `'Xem chương trình'` (⇒ `go` P3) · `'Về Kho'` (⇒ `/warehouse`) |

**P5 — So sánh nhà cung cấp** (iPhone thẻ, web bảng):
```
┌ ‹ Nobivac DHPPi   So sánh nhà cung cấp ┐
│ NCC A                       Rẻ nhất     │
│ Giá gốc gần nhất   95.000 đ/hộp (05/11) │
│ Bình quân giá gốc  97.200 đ/hộp         │
│ 3 lần nhập · mua 1.000 · tặng 0 hộp     │
│ [Đạt mốc] Mốc 1.000 hộp Q4  ███ 1.000/1.000 ›
│─────────────────────────────────────────│
│ Cty Á Châu                              │
│ … · ưu đãi: Không có  [+ Thêm ưu đãi]   │
│─────────────────────────────────────────│
│ Mua lẻ / khác                           │
│ Giá gốc gần nhất  110.000 đ/hộp (01/11) │
└─────────────────────────────────────────┘
```

| Phần tử | Flutter | Tham số |
|---|---|---|
| Khung | `VPageScaffold(title: 'So sánh nhà cung cấp', subtitle: product.name)` | |
| Thẻ NCC (iPhone) | `VCard`: `VText(name, titleSmall)` + `VBadge('Rẻ nhất', success)` khi `cheapestSupplierId`; `VKeyValueRow('Giá gốc gần nhất', '{money}/{uom} (dd/MM)')`, `VKeyValueRow('Bình quân giá gốc', '{money}/{uom}')`; `VText('{n} lần nhập · mua {paid} · tặng {free} {uom}', bodySmall, textSecondary)` | nhân viên: tiền `'—'`, không nhãn "Rẻ nhất" |
| Ưu đãi | `program` ⇒ `K6TaskRow(title: name, status: nhãn trạng thái G5-2b, below: ProgramRowBelow)` chạm ⇒ P3; `other_program` ⇒ `VText('Đang có chương trình khác: {tên}')` + liên kết P3; không có và `!isSystem` ⇒ `VText('Ưu đãi: Không có')` + `VButton('Thêm ưu đãi', tertiary, icon add)` ⇒ `/warehouse/supplier-programs/new?supplierId={id}&productId={productId}`; `isSystem` ⇒ không có dòng ưu đãi | |
| Web 1280 | bảng cột "Nhà cung cấp" · "Giá gốc gần nhất" · "Bình quân giá gốc" · "Số lần nhập" · "SL mua / tặng" · "Ưu đãi" | |
| Rỗng | `InventoryEmpty(title: 'Chưa nhập sản phẩm này từ nhà cung cấp nào.')` | |
| Đang tải / lỗi | `InventoryLoading`, `InventoryEmpty('Không tải được so sánh', 'Thử lại')` | |

**Lối vào P5:** SCR-003 `StockDetailBody` thêm `VListRow(asCard: true, leading: VIcons.coins, title: 'So sánh nhà cung cấp', subtitle: 'Giá gốc và ưu đãi theo từng nhà cung cấp', type: navigation)` **ngay trên** dòng "Nguồn và thời điểm cập nhật", qua callback mới `VoidCallback? onCompareSuppliers` (null ⇒ ẩn). Màn sửa dòng phiếu nhận (`ReceiptLineEditor`): liên kết chữ `'So sánh nhà cung cấp'` dưới tên sản phẩm, callback `ValueChanged<String>? onCompareSuppliers` (productId) ⇒ `context.push('/warehouse/stock/$productId/suppliers')` (push để giữ nháp).

**P2:** `ProgramFormPage.create({String? supplierId, String? productId})`; `ProgramFormCubit.startCreate({String? supplierId, String? productId})` điền sẵn `productIds = [productId]` khi sản phẩm có trong `form_options.products`.

**Hub "Cần chú ý"** (`programsReached > 0`): `VListRow(asCard: true, leading: VIcons.coins, title: 'Chương trình đạt mốc', subtitle: '$n chương trình nhà cung cấp đạt mốc chờ ghi nhận chiết khấu', trailing: badge n)` ⇒ `/warehouse/supplier-programs?status=REACHED`. `ProgramListPage` nhận thêm `initialStatus` (query `status`, mặc định `ACTIVE`).

### 2.6 Ngoài phạm vi

Đảo / sửa chiết khấu đã ghi; ca 16 và lần tính đọc `SUPPLIER_REBATE` (G5-6); dòng "Chiết khấu NCC giảm giá vốn" ở báo cáo lãi gộp (G5-7); so sánh nhiều sản phẩm cùng lúc.

## 3. Tệp

| Tệp | Task |
|---|---|
| `supabase/migrations/20261117001_inventory_supplier_rebates.sql` (mới), `REGISTRY.yaml` | 1, 2 |
| `supabase/migrations/20261113001_inventory_supplier_programs.sql` (`get_supplier_program`), `20261110001_inventory_core.sql` (`get_warehouse_hub_summary`) | 1 |
| `supabase/tests/inventory_supplier_rebates.sql` (mới) | 1, 2 |
| `apps/erp/test/features/inventory/data/supplier_rebate_sql_contract_test.dart` (mới) | 1, 2 |
| `apps/erp/lib/features/inventory/data/supplier_rebate/{supplier_rebate_models,supplier_rebate_repository}.dart` (mới), `data/supplier_program/supplier_program_models.dart` (`ProgramDetail`), `data/core/inventory_error_codes.dart` | 3 |
| `apps/erp/lib/features/inventory/logic/supplier_rebate/rebate_rules.dart` (mới) | 3 |
| `apps/erp/lib/features/inventory/logic/supplier_rebate/{rebate_record,projected_cost,supplier_compare}_{cubit,state}.dart` (mới) | 4 |
| `apps/erp/lib/features/inventory/presentation/supplier_rebate/{rebate_record_page,rebate_result_page,rebate_allocation_view,rebate_confirm_sheet}.dart` (mới) | 5 |
| `presentation/supplier_rebate/{projected_cost_section,recorded_rebate_section}.dart` (mới), `presentation/supplier_program/program_detail_page.dart` | 6 |
| `presentation/supplier_rebate/supplier_compare_page.dart` (mới), `presentation/stock/{stock_detail_body,stock_detail_page}.dart`, `presentation/goods_receipt/{receipt_line_editor,receipt_line_editor_page}.dart`, `presentation/supplier_program/program_form_page.dart`, `logic/supplier_program/program_form_cubit.dart` | 7 |
| `presentation/supplier_program/{supplier_program_routes,program_list_page}.dart`, `logic/supplier_program/program_list_cubit.dart`, `presentation/stock/stock_routes.dart`, `data/hub/{warehouse_hub_summary,warehouse_hub_repository}.dart`, `presentation/hub/warehouse_hub_page.dart`, `apps/erp/lib/core/di/injection.dart` | 8 |
| `apps/erp/test/features/inventory/{data,logic,presentation}/supplier_rebate/*` (mới) | 3–8 |
| `apps/erp/test/features/inventory/presentation/supplier_rebate/supplier_rebate_golden_test.dart`, `docs/refactor/plans/T7/img/G5-5b/flutter-*.png`, `docs/refactor/PLAN.md`, spec giá vốn mục 12.5 | 9 |

## 4. Task

### Task 0: Mốc + impact

**Files:** plan này (mục 5).

- [x] **Step 1: `impact`** cho các symbol Global Constraints; ghi bảng (symbol · số caller trực tiếp · rủi ro) vào Kết quả. HIGH / CRITICAL ⇒ dừng, báo người dùng.
- [x] **Step 2: Mốc test:** `cd apps/erp && flutter test --no-pub -r compact test/features/inventory` + `tools/db_check.sh`; ghi số xanh / đỏ vào Kết quả.

### Task 1: SQL — bảng, helper, xem trước / ghi nhận, P3 + Hub

**Files:** Create `supabase/migrations/20261117001_inventory_supplier_rebates.sql`, `supabase/tests/inventory_supplier_rebates.sql`, `apps/erp/test/features/inventory/data/supplier_rebate_sql_contract_test.dart`; Modify `supabase/migrations/20261113001_inventory_supplier_programs.sql`, `supabase/migrations/20261110001_inventory_core.sql`, `supabase/migrations/REGISTRY.yaml`.

**Interfaces:**
- Consumes: `_assert_actor` (trả `is_owner`), `_raise`, `_begin_idempotency`, `_complete_idempotency`, `_today`, `_ensure_open_period`, `_next_ledger_sequence`, `_forbid_ledger_mutation`, `iam._member_display_name`, `catalog._product_base_unit_name`; bảng `supplier_programs`, `supplier_program_receipts`, `goods_receipt_lines`, `product_costs`, `value_movements`.
- Produces: 2 bảng mục 2.1; `_post_value_adjustment(uuid, uuid, text, bigint, date, uuid, uuid, uuid)` (G5-6 dùng); `_rebate_allocation(uuid, uuid, bigint)`; `preview_supplier_rebate`, `record_supplier_rebate` (JSON `RebatePreview` mục 2.2); `get_supplier_program` có `viewer_is_owner`, `rebate`; `problems.programs_reached`.

- [x] **Step 1: Test hợp đồng (đỏ)** — khuôn `stocktake_sql_contract_test.dart`: `rebate_tables_rls_revoked` (2 bảng `enable row level security` + `revoke all`); `rebate_tables_append_only` (trigger `_forbid_ledger_mutation` trên 2 bảng); `value_adjustment_not_granted` (`_post_value_adjustment`, `_rebate_allocation` có `revoke all`, không `grant`); `rebate_rpcs_owner_only` (thân `preview_supplier_rebate`, `record_supplier_rebate` có `'is_owner'` và `'PERMISSION_DENIED'`); `record_idempotent` (`_begin_idempotency(` + `'supplier_rebate.record'`); `record_locks_program_then_products` (trong thân `record_supplier_rebate`: vị trí `for update` < `pg_advisory_xact_lock` < `_rebate_allocation(`); `record_does_not_call_value_line` (không có `_value_line(` / `_post_movements(`); `hub_counts_programs_reached` (`20261110001` có `'programs_reached'`); `new_error_codes_present` (3 mã mục 2.2); `rebate_fk_added` (`value_movements_supplier_rebate_fk`).
- [x] **Step 2: Chạy, thấy đỏ** — `cd apps/erp && flutter test --no-pub -r compact test/features/inventory/data/supplier_rebate_sql_contract_test.dart`.
- [x] **Step 3: Viết migration** (mục 2.1, 2.2 trừ `get_projected_cost` / `compare_suppliers`, luật 2.3) + sửa `get_supplier_program`, `get_warehouse_hub_summary`; `REGISTRY.yaml`.
- [x] **Step 4: Viết `supabase/tests/inventory_supplier_rebates.sql`** (fixture chép `inventory_goods_receipts.sql`: role `store_owner` + `is_owner`, `products.reference_id`, `store_warehouse_assignments`; thêm nhân viên `is_owner false` có `inventory.read`. Hàng vào bằng `record_goods_receipt` có `program_id` để có `supplier_program_receipts` + `REACHED` thật; bán bằng `_post_movements` `SALE` `intent_type 'TEST'`. Mỗi ca sai ⇒ `raise exception 'FAIL: <ca>'`). Ca mục 2.3 trừ `projected_reach`, `staff_masked_projection_compare`, `compare_rows`; kiểm bất biến sau mọi ca ghi.
- [x] **Step 5: Chạy** — `tools/db_check.sh` ⇒ `✅` (gồm tệp mới + mọi tệp cũ, nhất là `inventory_supplier_programs`, `inventory_goods_receipts`, `inventory_stocktake`); test hợp đồng xanh.
- [ ] **Step 6: Commit** `feat(inventory): chiết khấu NCC — bảng, xem trước / ghi nhận, Hub (G5-5b Task 1)`.

### Task 2: SQL — giá vốn dự kiến, so sánh NCC

**Files:** Modify `supabase/migrations/20261117001_inventory_supplier_rebates.sql`, `supabase/tests/inventory_supplier_rebates.sql`, `apps/erp/test/features/inventory/data/supplier_rebate_sql_contract_test.dart`, `REGISTRY.yaml`.

**Interfaces:**
- Consumes: Task 1; `goods_receipts`, `partner.partners` (`is_system`, `display_name`).
- Produces: `get_projected_cost(uuid, uuid, uuid, numeric, numeric)`, `compare_suppliers(uuid, uuid)` (JSON mục 2.2 / 2.3).

- [x] **Step 1: Test hợp đồng (đỏ):** `read_rpcs_granted` (2 RPC `security definer` + `grant execute … to authenticated` + `_assert_actor(p_tenant_id, 'inventory.read')`); `read_rpcs_mask_money` (cả hai có `'financial_masked'`); `projection_writes_nothing` (thân `get_projected_cost` không có `insert`, `update`, `_post_value_adjustment(`).
- [x] **Step 2: Chạy, thấy đỏ.**
- [x] **Step 3: Viết 2 RPC** theo mục 2.2 / 2.3.
- [x] **Step 4: Thêm ca** `projected_reach`, `staff_masked_projection_compare`, `compare_rows` (mục 2.3).
- [x] **Step 5: Chạy** — `tools/db_check.sh` ⇒ `✅`; test hợp đồng xanh.
- [ ] **Step 6: Commit** `feat(inventory): giá vốn dự kiến, so sánh nhà cung cấp — RPC (G5-5b Task 2)`.

### Task 3: Model + repository + luật thuần + mã lỗi

**Files:** Create `apps/erp/lib/features/inventory/data/supplier_rebate/supplier_rebate_models.dart`, `supplier_rebate_repository.dart`, `apps/erp/lib/features/inventory/logic/supplier_rebate/rebate_rules.dart`; Modify `data/supplier_program/supplier_program_models.dart`, `data/core/inventory_error_codes.dart`; Test `apps/erp/test/features/inventory/data/supplier_rebate/supplier_rebate_repository_test.dart`, `apps/erp/test/features/inventory/logic/supplier_rebate/rebate_rules_test.dart`, sửa `test/features/inventory/data/supplier_program/*` nếu cần.

**Interfaces:**
- Consumes: JSON mục 2.2; `InventoryRpc.query` / `mutate`.
- Produces:
  - `RebateAllocation {productId, name, uom, num paidQty, int? purchaseAmountVnd, int? rebatePartVnd, num onHandQty, int? inventoryPartVnd, int? cogsPartVnd, num? avgCostBefore, num? avgCostAfter}`; `RebatePreview {programId, programName, supplierName, num targetQty, num progressQty, num rebatePercent, String? uom, int baseAmountVnd, int proposedAmountVnd, int amountVnd, List<RebateAllocation> allocations, int inventoryPartTotal, int cogsPartTotal}`; `RebateRecordResult extends RebatePreview` + `rebateId`.
  - `RecordedRebate {rebateId, documentNo, DateTime documentDate, int? baseAmountVnd, int? proposedAmountVnd, int? rebateAmountVnd, String? overrideReason, int? inventoryPartVnd, int? cogsPartVnd, DateTime recordedAt, String recordedByName, List<RebateAllocation> allocations}`; `ProgramDetail` thêm `bool viewerIsOwner` (mặc định `false`) và `RecordedRebate? rebate`.
  - `ProjectedCost {productId, uom, num progressQty, num targetQty, num missingQty, bool? reachesTarget, int? rebateEstimate, num? avgNow, num? avgProjected, int? defaultUnitPrice, bool financialMasked}`.
  - `SupplierCompare {productId, name, code, uom, bool financialMasked, List<SupplierCompareRow> suppliers}`; `SupplierCompareRow {partnerId, name, bool isSystem, num? lastLandedUnitCost, DateTime? lastReceivedOn, num? avgLandedUnitCost, int receiptCount, num paidQty, num freeQty, ProgramRow? program, ({String id, String name})? otherProgram}` (`program` parse bằng `ProgramRow.fromJson` có `supplier_*` lấy từ dòng).
  - `SupplierRebateRepository`: `preview({required String programId, int? amountVnd}) → Future<RebatePreview>`; `record({required String idempotencyKey, required String programId, required String documentNo, required DateTime documentDate, required int amountVnd, String? overrideReason}) → Future<RebateRecordResult>` (`mutate(scope: 'supplier_rebate.record')`, payload không có khoá `override_reason` khi `null`); `projectedCost({required String programId, required String productId, num? extraQty, num? unitPrice}) → Future<ProjectedCost>`; `compareSuppliers(String productId) → Future<SupplierCompare>`.
  - Luật mục 2.4; `InventoryErrorCode` thêm 3 mã + câu.

- [x] **Step 1: Test (đỏ):**
  - `parse_amount`: `'5.000.000'` ⇒ 5000000; `'5000000'` ⇒ 5000000; `'5 000 000 đ'` ⇒ 5000000; `''`, `'5,5'`, `'abc'` ⇒ `null`.
  - `amount_errors`: `rebateAmountError(null, 100000000) == 'Nhập số tiền ghi nhận'`; `(0, …)` và `(100000001, 100000000)` ⇒ `'Số tiền từ 1 đ đến 100.000.000 đ'` (theo `MoneyFormatter.formatMinor`); `(5000000, 100000000) == null`.
  - `reason_needed_only_when_override`: `needsOverrideReason(5000000, 5000000) == false`; `(4000000, 5000000) == true`; `(null, 5000000) == false`.
  - `document_errors`: số chứng từ `'  '` ⇒ `'Nhập số chứng từ'`; ngày mai / trước `startedOn` ⇒ câu mục 2.4; hôm nay ⇒ `null`.
  - `cheapest_supplier`: A 97.200, B 99.000, "Mua lẻ" 90.000 ⇒ A; chỉ A + "Mua lẻ" ⇒ `null`; A `avg null` ⇒ bỏ qua.
  - `stock_changed_since_preview`: `(1500000, 1000000) == true`; `(null, 1000000) == false`; bằng nhau ⇒ `false`.
  - `preview_from_json` (JSON ca 14) ⇒ `allocations.single.inventoryPartVnd == 1500000`, `avgCostAfter == 95000`; JSON nhân viên (khoá tiền `null`) ⇒ các trường `null`, không ném lỗi.
  - `program_detail_rebate_json`: `get_supplier_program` có `viewer_is_owner true` + `rebate` ⇒ `detail.viewerIsOwner`, `detail.rebate!.documentNo`; thiếu hai khoá (JSON G5-2b cũ) ⇒ `false` / `null`.
  - `repository_calls_one_rpc`: fake `InventoryRpc` ghi tên hàm + tham số; mỗi phương thức gọi đúng tên mục 2.2 (`p_program_id`, `p_amount_vnd`, `p_product_id`, `p_extra_qty`, `p_unit_price`, `p_payload`); `record` có scope `'supplier_rebate.record'`; `overrideReason: null` ⇒ payload không có `override_reason`.
  - `error_messages`: 3 mã ⇒ câu mục 2.4.
- [x] **Step 2: Chạy, thấy đỏ.**
- [x] **Step 3: Viết** model / repository / luật / mã lỗi.
- [x] **Step 4: Chạy xanh** — `flutter test --no-pub -r compact test/features/inventory/data test/features/inventory/logic`; `dart analyze` sạch.
- [ ] **Step 5: Commit** `feat(inventory): chiết khấu NCC — model, repository, luật (G5-5b Task 3)`.

### Task 4: Ba Cubit (P4, khối dự kiến, P5)

**Files:** Create `apps/erp/lib/features/inventory/logic/supplier_rebate/{rebate_record,projected_cost,supplier_compare}_{cubit,state}.dart`; Test `apps/erp/test/features/inventory/logic/supplier_rebate/{rebate_record,projected_cost,supplier_compare}_cubit_test.dart`.

**Interfaces:**
- Consumes: Task 3; `SupplierProgramRepository.get`.
- Produces:
  - `RebateRecordCubit({required SupplierRebateRepository rebates, required SupplierProgramRepository programs, required String programId, Duration debounce = const Duration(milliseconds: 400), String Function()? newKey})`; `load()`, `setDocumentNo(String)`, `setDocumentDate(DateTime)`, `setAmountText(String)`, `setReason(String)`, `submit() → Future<void>` (chỉ kiểm + bật `confirming`), `confirm() → Future<void>`, `cancelConfirm()`. `RebateRecordState { RebateRecordStatus status (loading, loadError, notOwner, notReached, ready, submitting, recorded, stale), ProgramDetail? program, RebatePreview? preview, bool previewLoading, String documentNo, DateTime documentDate, String amountText, String reason, bool showErrors, bool confirming, RebateRecordResult? result, String? errorCode, Map<String, String> errors (khoá 'documentNo' | 'documentDate' | 'amount' | 'reason') }`. Khoá idempotency tạo một lần mỗi lần `confirm` thành công trước đó chưa có (giữ khoá khi thử lại sau lỗi mạng).
  - `ProjectedCostCubit({required SupplierRebateRepository rebates, required String programId, required List<ProgramProduct> products, Duration debounce = const Duration(milliseconds: 400)})`; `load()` (gọi `projectedCost` với `extraQty null` để lấy `defaultUnitPrice`), `selectProduct(String)`, `setExtraQty(String)`, `setUnitPrice(String)`. State `{productId, extraText, priceText, ProjectedCost? result, bool loading, bool error}`.
  - `SupplierCompareCubit({required SupplierRebateRepository rebates, required String productId})`; `load()`. State `{loading | loaded(SupplierCompare, String? cheapestId) | error}`.

- [x] **Step 1: Test (đỏ)** (`fake_async` cho debounce):
  - `load_owner_reached_previews`: chương trình `REACHED`, owner ⇒ `ready`, `amountText` = đề xuất định dạng `'5.000.000'`, `preview` được tải.
  - `load_staff_not_owner`: `viewerIsOwner false` ⇒ `notOwner`, **không** gọi `preview`.
  - `load_active_not_reached`: `ACTIVE` ⇒ `notReached`, không gọi `preview`.
  - `amount_change_debounced`: gõ 3 lần trong 300 ms ⇒ đúng một lần `preview(amountVnd: …)` sau 400 ms; số không hợp lệ ⇒ không gọi, `errors['amount']` có khi `showErrors`.
  - `payload_drops_reason_when_equal` (Review Focus 3): nhập lý do, đổi số về đúng đề xuất, `confirm` ⇒ `record(overrideReason: null)`.
  - `submit_shows_all_errors`: số chứng từ rỗng ⇒ `submit` đặt `showErrors`, không `confirming`.
  - `confirm_success_recorded`: ⇒ `recorded`, `result` có `rebateId`.
  - `confirm_not_reached_stale`: repository ném `PROGRAM_NOT_REACHED` ⇒ `stale`.
  - `confirm_period_closed_keeps_form`: `PERIOD_CLOSED` ⇒ `ready`, `errorCode 'PERIOD_CLOSED'`, dữ liệu form giữ.
  - `retry_keeps_idempotency_key`: lỗi mạng rồi `confirm` lại ⇒ cùng khoá.
  - `projected_default_price_and_debounce`: `load` điền `priceText` từ `defaultUnitPrice`; gõ `extra` ⇒ một lần gọi sau 400 ms với `extraQty`; đổi sản phẩm ⇒ tải lại giá mặc định.
  - `compare_cheapest`: dữ liệu `cheapest_supplier` ⇒ `cheapestId == 'A'`.
- [x] **Step 2: Chạy, thấy đỏ.**
- [x] **Step 3: Viết** ba Cubit.
- [x] **Step 4: Chạy xanh** + `dart analyze` sạch.
- [ ] **Step 5: Commit** `feat(inventory): chiết khấu NCC — cubit P4, dự kiến, so sánh (G5-5b Task 4)`.

### Task 5: P4 Ghi nhận chiết khấu + K4

**Files:** Create `apps/erp/lib/features/inventory/presentation/supplier_rebate/{rebate_record_page,rebate_result_page,rebate_allocation_view,rebate_confirm_sheet}.dart`; Test `apps/erp/test/features/inventory/presentation/supplier_rebate/{rebate_record_page,rebate_result_page}_test.dart`.

**Interfaces:**
- Consumes: Task 4 `RebateRecordCubit`.
- Produces: `RebateRecordPage({required String programId})` (tự tạo cubit từ `getIt`); `RebateResultPage({required String programId, int? previewInventoryTotal})`; khi `recorded` ⇒ `context.go('/warehouse/supplier-programs/$programId/rebate/result', extra: preview.inventoryPartTotal)`.

- [x] **Step 1: Test (đỏ)** (fake repository; 390 trừ khi ghi khác):
  - `ready_390` / `ready_1280`: có chữ `'Căn cứ'`, `'Đề xuất'`, `'5.000.000 đ'`, `'Số chứng từ'`, `'Phân bổ (xem trước)'`, `'Giảm giá trị tồn'`, `'Bình quân'`, câu `VBanner` info mục 2.5; 1280 có tiêu đề cột `'Tồn / mua'`; không có `'Lý do khác đề xuất'`.
  - `override_shows_reason`: đổi số tiền ⇒ có ô `'Lý do khác đề xuất'`.
  - `confirm_sheet_text`: bấm `'Ghi nhận'` với form hợp lệ ⇒ sheet `'Ghi nhận chiết khấu 5.000.000 đ?'` + `'Giá trị tồn và bình quân của 1 sản phẩm sẽ giảm. Không hoàn tác được.'`.
  - `staff_locked_390` (Review Focus 5): `'Chỉ chủ cửa hàng ghi nhận được chiết khấu.'`, không có ô nhập.
  - `record_already_recorded_stale_390` (Review Focus 1): `'Chương trình đã được ghi nhận chiết khấu'` + nút `'Xem chương trình'`.
  - `period_closed_banner`: câu `PERIOD_CLOSED` hiện, ô số chứng từ còn giá trị đã gõ.
  - `result_page`: `'Đã ghi nhận chiết khấu'`, `'5.000.000 đ từ NCC A cho chương trình "Mốc 1.000 hộp Q4".'`, `'Giảm giá trị tồn'`, `'Bình quân đã đổi: Nobivac DHPPi'`, nút `'Xem chương trình'`, `'Về Kho'`; không có nút quay lại.
  - `result_shows_changed_note` (Review Focus 2): `previewInventoryTotal 1500000`, server `1000000` ⇒ có `'Tồn đã đổi từ lúc xem trước, số đã tính lại theo tồn hiện tại.'`; `null` ⇒ không có.
- [x] **Step 2: Chạy, thấy đỏ.**
- [x] **Step 3: Viết** theo bảng ánh xạ P4 / K4 mục 2.5.
- [x] **Step 4: Chạy xanh** + `dart analyze` sạch.
- [ ] **Step 5: Commit** `feat(inventory): chiết khấu NCC — màn ghi nhận, kết quả (G5-5b Task 5)`.

### Task 6: P3 — khối dự kiến, nút ghi nhận, khối đã ghi nhận

**Files:** Create `apps/erp/lib/features/inventory/presentation/supplier_rebate/{projected_cost_section,recorded_rebate_section}.dart`; Modify `presentation/supplier_program/program_detail_page.dart`; Test `apps/erp/test/features/inventory/presentation/supplier_rebate/projected_cost_section_test.dart`, sửa `test/features/inventory/presentation/supplier_program/program_detail_page_test.dart`.

**Interfaces:**
- Consumes: Task 3 (`ProgramDetail.viewerIsOwner`, `rebate`), Task 4 `ProjectedCostCubit`.
- Produces: `ProjectedCostSection({required String programId, required List<ProgramProduct> products})`, `RecordedRebateSection({required RecordedRebate rebate})`.

- [x] **Step 1: `impact`** cho `ProgramDetailPage`; ghi Kết quả.
- [x] **Step 2: Test (đỏ):**
  - `active_volume_shows_projection`: loại 3 `ACTIVE` ⇒ `'Giá vốn dự kiến'`, `'Dự kiến, chưa ghi sổ'`; 1 sản phẩm ⇒ không có `VSelect` sản phẩm; nhập 600 ⇒ `'Đạt mốc 1.000 hộp sau lần mua này'`, `'Chiết khấu ước tính'`, `'95.000 đ/hộp'`; nhập 500 ⇒ `'Còn thiếu 100 hộp để đạt mốc'`, không có `'Chiết khấu ước tính'`.
  - `tier_program_no_projection`: loại 1 ⇒ không có `'Giá vốn dự kiến'`.
  - `reached_owner_has_record_button`: `REACHED`, `viewerIsOwner true` ⇒ chân có `'Ghi nhận chiết khấu'`, chạm ⇒ `/warehouse/supplier-programs/p1/rebate`; băng `'Đã đạt mốc, chờ ghi nhận chiết khấu'` không chứa nút.
  - `reached_staff_no_record_button`: `viewerIsOwner false` ⇒ không có `'Ghi nhận chiết khấu'`.
  - `recorded_shows_section`: `RECORDED` ⇒ `'Chiết khấu đã ghi nhận'`, `'CK-2026-11 · 12/11/2026'`, `'Giảm giá vốn hàng đã bán'`, `'3.500.000 đ'`; không chân; nhân viên ⇒ `'—'`.
  - `projection_error_not_blocking`: repository dự kiến ném lỗi ⇒ `'Không tính được giá vốn dự kiến.'` + `'Thử lại'`, phần "Thông tin" vẫn hiện.
- [x] **Step 3: Chạy, thấy đỏ.**
- [x] **Step 4: Viết** theo mục 2.5 (P3).
- [x] **Step 5: Chạy xanh** — `flutter test --no-pub -r compact test/features/inventory/presentation/supplier_program test/features/inventory/presentation/supplier_rebate`; `dart analyze` sạch.
- [ ] **Step 6: Commit** `feat(inventory): chiết khấu NCC — P3 giá vốn dự kiến, ghi nhận (G5-5b Task 6)`.

### Task 7: P5 So sánh nhà cung cấp + lối vào + P2 `productId`

**Files:** Create `apps/erp/lib/features/inventory/presentation/supplier_rebate/supplier_compare_page.dart`; Modify `presentation/stock/{stock_detail_body,stock_detail_page}.dart`, `presentation/goods_receipt/{receipt_line_editor,receipt_line_editor_page}.dart`, `presentation/supplier_program/program_form_page.dart`, `logic/supplier_program/program_form_cubit.dart`; Test `apps/erp/test/features/inventory/presentation/supplier_rebate/supplier_compare_page_test.dart` + test stock / goods_receipt / program_form tương ứng.

**Interfaces:**
- Consumes: Task 4 `SupplierCompareCubit`.
- Produces: `SupplierComparePage({required String productId})`; `StockDetailBody.onCompareSuppliers: VoidCallback?`; `ReceiptLineEditor.onCompareSuppliers: ValueChanged<String>?`; `ProgramFormPage.create({String? supplierId, String? productId})`; `ProgramFormCubit.startCreate({String? supplierId, String? productId})`.

- [x] **Step 1: `impact`** cho `StockDetailBody`, `ReceiptLineEditor`, `ProgramFormPage`, `ProgramFormCubit.startCreate`; ghi Kết quả.
- [x] **Step 2: Test (đỏ):**
  - `compare_390` / `compare_1280`: dữ liệu `compare_rows` ⇒ thẻ NCC A trước, `'Rẻ nhất'` ở A, `'Giá gốc gần nhất'`, `'97.200 đ/hộp'`, `'2 lần nhập · mua 1.000 · tặng 0 hộp'`; "Mua lẻ / khác" cuối, không có `'Thêm ưu đãi'` ở dòng đó; 1280 có tiêu đề cột `'SL mua / tặng'`.
  - `compare_add_offer`: NCC không có chương trình ⇒ `'Ưu đãi: Không có'` + `'Thêm ưu đãi'` ⇒ `/warehouse/supplier-programs/new?supplierId=B&productId=P`; NCC có `other_program` ⇒ `'Đang có chương trình khác: …'`, không có `'Thêm ưu đãi'`.
  - `compare_staff_masked_390` (Review Focus 5): `financialMasked` ⇒ ô giá `'—'`, không có `'Rẻ nhất'`.
  - `compare_empty`: không NCC ⇒ `'Chưa nhập sản phẩm này từ nhà cung cấp nào.'`.
  - `stock_detail_compare_row`: có callback ⇒ dòng `'So sánh nhà cung cấp'` nằm trên `'Nguồn và thời điểm cập nhật'`, chạm ⇒ gọi callback; `StockDetailPage` ⇒ `push('/warehouse/stock/<id>/suppliers')`.
  - `receipt_line_compare_link`: editor có sản phẩm ⇒ liên kết `'So sánh nhà cung cấp'`, chạm ⇒ `push` `/warehouse/stock/<productId>/suppliers`, quay lại thì nháp dòng còn nguyên.
  - `form_prefills_product`: `startCreate(supplierId: 'B', productId: 'P')` ⇒ `draft.productIds == ['P']`; `productId` không có trong options ⇒ rỗng.
- [x] **Step 3: Chạy, thấy đỏ.**
- [x] **Step 4: Viết** theo mục 2.5 (P5, lối vào, P2).
- [x] **Step 5: Chạy xanh** — `flutter test --no-pub -r compact test/features/inventory`; `dart analyze` sạch.
- [ ] **Step 6: Commit** `feat(inventory): so sánh nhà cung cấp — màn, lối từ tồn kho / phiếu nhận (G5-5b Task 7)`.

### Task 8: Route, DI, Hub, luồng đầu–cuối

**Files:** Modify `presentation/supplier_program/{supplier_program_routes,program_list_page}.dart`, `logic/supplier_program/program_list_cubit.dart`, `presentation/stock/stock_routes.dart`, `data/hub/{warehouse_hub_summary,warehouse_hub_repository}.dart`, `presentation/hub/warehouse_hub_page.dart`, `apps/erp/lib/core/di/injection.dart`; Create `apps/erp/test/features/inventory/presentation/supplier_rebate/supplier_rebate_flow_test.dart`; Test hub tương ứng.

**Interfaces:**
- Consumes: Task 5–7 page.
- Produces: route `warehouse.supplier_programs.rebate` (`:programId/rebate`), `warehouse.supplier_programs.rebate_result` (`:programId/rebate/result`, `extra` `int?`), `warehouse.stock.suppliers` (`/warehouse/stock/:productId/suppliers`); `ProgramListPage({String? initialSupplierId, ProgramStatus? initialStatus})`; `WarehouseHubSummary.programsReached` (`int`, mặc định 0); `getIt<SupplierRebateRepository>`.

- [x] **Step 1: `impact`** cho `supplierProgramRoutes`, `stockRoutes`, `ProgramListPage`, `WarehouseHubRepository`, `WarehouseHubSummary`, `WarehouseHubPage`, `injection.dart`; ghi Kết quả.
- [x] **Step 2: Test (đỏ):**
  - `hub_attention_programs_reached`: `problems.programs_reached 2`, owner ⇒ dòng `'Chương trình đạt mốc'` phụ `'2 chương trình nhà cung cấp đạt mốc chờ ghi nhận chiết khấu'`, chạm ⇒ `/warehouse/supplier-programs?status=REACHED`; `0` ⇒ không có dòng.
  - `list_initial_status_reached`: `?status=REACHED` ⇒ chip `'Đạt mốc'` được chọn.
  - `supplier_rebate_flow_test` (fake repository giữ trạng thái): Hub `'Chương trình đạt mốc'` → P1 chip Đạt mốc → chạm chương trình → P3 `'Ghi nhận chiết khấu'` → P4 nhập số chứng từ → `'Ghi nhận'` → sheet `'Ghi nhận'` → K4 `'Đã ghi nhận chiết khấu'` → `'Xem chương trình'` → P3 có `'Chiết khấu đã ghi nhận'`, không có nút ghi nhận.
  - `compare_flow`: `/warehouse/stock/P` → `'So sánh nhà cung cấp'` → P5 → `'Thêm ưu đãi'` → P2 có sẵn NCC + sản phẩm.
- [x] **Step 3: Chạy, thấy đỏ.**
- [x] **Step 4: Viết** route (mục 2.5; `rebate` trước `rebate/result` không xung đột vì khác độ sâu), DI (`SupplierRebateRepository` cạnh `SupplierProgramRepository`), Hub (`programs_reached` ⇒ `programsReached`; dòng "Cần chú ý" khuôn dòng kiểm kê, chỉ khi `isOwner`).
- [x] **Step 5: Chạy xanh** — `flutter test --no-pub -r compact test/features/inventory`; `dart analyze` sạch.
- [ ] **Step 6: Commit** `feat(inventory): chiết khấu NCC — route, Hub, luồng (G5-5b Task 8)`.

### Task 9: Ảnh Flutter + kiểm cuối + PLAN

**Files:** Create `apps/erp/test/features/inventory/presentation/supplier_rebate/supplier_rebate_golden_test.dart`, `docs/refactor/plans/T7/img/G5-5b/flutter-{P4-READY,P4-RESULT,P3-PROJECTED,P3-RECORDED,P5-READY}-{390,1280}.png`; Modify `docs/refactor/PLAN.md`, `docs/refactor/plans/T7/T7-G5-gia-von-thiet-ke.md` (mục 12.5), plan này (mục 5).

- [x] **Step 1: Golden test** (tag `golden`, khuôn `stocktake_golden_test.dart`) dùng dữ liệu ca 14 + `compare_rows`; `--update-goldens`, chép ảnh sang `img/G5-5b/`.
- [x] **Step 2: Đối chiếu ảnh với khung ASCII mục 2.5** (không có prototype): thứ tự phần tử, chữ, điều kiện hiện / ẩn; lệch ghi vào Kết quả kèm lý do.
- [x] **Step 3:** `tools/db_check.sh` (đủ 3 bước) ⇒ `✅`, dán đoạn cuối vào Kết quả; `cd apps/erp && flutter test --no-pub -r compact test/features/inventory test/features/partner` ⇒ so `TEST-BASELINE.md`; `dart analyze apps/erp/lib apps/erp/test`.
- [x] **Step 4:** `detect_changes({scope: "compare", base_ref: "main"})` ⇒ chỉ symbol mục 3; ghi Kết quả.
- [x] **Step 5:** PLAN.md dòng G5-5b: cột Làm ✅ + ngày; spec giá vốn mục 12.5: thêm ghi chú "công thức tính theo từng sản phẩm — xem plan G5-5b mục 2.3"; mục 12.6: ghi quyền Q-5b-1. Ghi "Dev cần reset `--linked`" — hỏi người dùng, không tự chạy.
- [ ] **Step 6: Commit** `docs(refactor): kết quả G5-5b`.

## 5. Kết quả

### Task 0 (2026-11-12)

**1. GitNexus `impact` (re-index `erp-sales-inventory` tại `82ea44f`, 44.277 nodes / 95.154 edges / 300 flows):**

> **Lưu ý kỹ thuật GitNexus:** Khi chạy `node .gitnexus/run.cjs impact <symbol> -r erp-sales-inventory -d upstream`, bộ phân tích Dart lập chỉ mục hầu hết các nút `Class` và `Function` cấp cao với `id = ""` và `filePath = ""`, khiến truy vấn `impact` gom nhầm vào nút rỗng dùng chung trên toàn repo (`1562–1886` caller trực tiếp, `CRITICAL`). Chỉ có các nút có UID riêng (`ProgramFormCubit.startCreate`, constructor `ProgramDetailCubit`, biến `appRouter`) phản ánh đúng bậc 1 (`d=1`), nhưng `startCreate` ở `d=2` vẫn đụng nút rỗng nên ra `CRITICAL`. Bên dưới ghi cả kết quả thô của GitNexus lẫn số tệp tham chiếu thực tế qua `grep` trong `apps/erp/lib/` + `supabase/`.

| Symbol | Caller trực tiếp (`GitNexus d=1`) | Rủi ro GitNexus | Tệp gọi/tham chiếu thực tế (`grep` trong `lib/` + `supabase/`) | Ghi chú |
|---|---|---|---|---|
| `inventory.get_supplier_program` | — (`Target not found`) | `UNKNOWN` | 4 (`supplier_program_repository.dart`, `20261113001`, `REGISTRY.yaml`, `inventory_supplier_programs.sql`) + 2 test | PL/pgSQL không được GitNexus lập chỉ mục |
| `inventory.get_warehouse_hub_summary` | — (`Target not found`) | `UNKNOWN` | 6 (`warehouse_hub_repository.dart`, `20261110001`, `REGISTRY.yaml`, 3 test SQL) + 4 test | PL/pgSQL không được GitNexus lập chỉ mục |
| `ProgramDetail` | 1562 (lỗi UID rỗng) | **`CRITICAL`** ⚠️ | 7 (đều trong `features/inventory/`) + 6 test | Thêm field tùy chọn có mặc định (`viewerIsOwner = false`, `rebate`) |
| `ProgramDetailPage` | 1568 (lỗi UID rỗng) | **`CRITICAL`** ⚠️ | 2 (`supplier_program_routes.dart`, `program_detail_page.dart`) + 1 test | — |
| `ProgramDetailCubit` | 0 (constructor UID) / 1568 (Class UID rỗng) | `LOW` / **`CRITICAL`** ⚠️ | 2 (`program_detail_cubit.dart`, `program_detail_page.dart`) + 1 test | Constructor UID: 0 / `LOW` |
| `ProgramFormPage` | 1562 (lỗi UID rỗng) | **`CRITICAL`** ⚠️ | 2 (`supplier_program_routes.dart`, `program_form_page.dart`) + 1 test | Thêm `productId` tùy chọn ở `.create` |
| `ProgramFormCubit.startCreate` | 3 (`d=1`) | **`CRITICAL`** ⚠️ | 2 (`program_form_cubit.dart`, `program_form_page.dart`) + 1 test | `d=1`: `reload`, `ProgramFormPage.build`, `main` (`""` kéo sang `CRITICAL`) |
| `supplierProgramRoutes` | 1568 (lỗi UID rỗng) | **`CRITICAL`** ⚠️ | 2 (`app_router.dart`, `supplier_program_routes.dart`) + 1 test | Thêm 2 route con dưới `:programId` |
| `stockRoutes` | 1568 (lỗi UID rỗng) | **`CRITICAL`** ⚠️ | 2 (`app_router.dart`, `stock_routes.dart`) + 0 test | Thêm 1 route con `:productId/suppliers` |
| `StockDetailBody` | 1568 (lỗi UID rỗng) | **`CRITICAL`** ⚠️ | 3 (`stock_detail_body.dart`, `stock_detail_page.dart`, `stock_list_page.dart`) + 0 test | Thêm callback tùy chọn `onCompareSuppliers` (`null` ⇒ ẩn) |
| `ReceiptLineEditor` | 1568 (lỗi UID rỗng) | **`CRITICAL`** ⚠️ | 3 (`receipt_line_editor.dart`, `receipt_line_editor_page.dart`, `receipt_lines_page.dart`) + 1 test | Thêm callback tùy chọn `onCompareSuppliers` |
| `WarehouseHubRepository` | 1568 (lỗi UID rỗng) | **`CRITICAL`** ⚠️ | 4 (`injection.dart`, `warehouse_hub_cubit.dart`, `warehouse_hub_repository.dart`, `warehouse_hub_page.dart`) + 8 test | — |
| `WarehouseHubSummary` | 1568 (lỗi UID rỗng) | **`CRITICAL`** ⚠️ | 3 (`warehouse_hub_summary.dart`, `warehouse_hub_repository.dart`, `warehouse_hub_state.dart`) + 2 test | Thêm `programsReached = 0` |
| `WarehouseHubPage` | 1568 (lỗi UID rỗng) | **`CRITICAL`** ⚠️ | 2 (`warehouse_hub_routes.dart`, `warehouse_hub_page.dart`) + 2 test | — |
| `inventoryErrorMessage` | 1562 (lỗi UID rỗng) | **`CRITICAL`** ⚠️ | 10 (đều trong `features/inventory/`) + 2 test | Chỉ thêm 3 nhánh mã lỗi mới |
| `InventoryErrorCode` | 1886 (lỗi UID rỗng) | **`CRITICAL`** ⚠️ | 9 (đều trong `features/inventory/`) + 13 test | Chỉ thêm 3 hằng số mới |
| `app_router.dart` (`appRouter`) | 0 (Variable UID) | `LOW` | 2 (`main.dart`, `partner_area_shell.dart`) + 13 test | — |
| `injection.dart` (`initDependencies`) | 1568 (lỗi UID rỗng) | **`CRITICAL`** ⚠️ | 40 (`getIt` dùng toàn app) + 41 test | Chỉ đăng ký thêm `SupplierRebateRepository` |

> **Dừng báo người dùng (theo Global Constraints & Task 0 Step 1):** `gitnexus impact` trả **`CRITICAL`** cho các symbol trên (do lỗi chỉ mục UID rỗng ở parser Dart của GitNexus làm gộp các `Class`/`Function` về cùng một nút, thực tế qua `grep` phạm vi sửa đều nằm gọn trong `features/inventory/`, `app_router.dart`, `injection.dart` và thêm tham số/thuộc tính tùy chọn tương thích ngược). Chờ người dùng xác nhận đồng ý đi tiếp sang Task 1–9.
>
> **Người dùng đồng ý đi tiếp (ghi lúc đóng plan, 2026-11-12):** chấp nhận mức `CRITICAL` là do lỗi chỉ mục GitNexus; phạm vi thật theo cột `grep`.

**2. Mốc `tools/db_check.sh`:** ✅ **DB check đạt** (exit 0).
- `[1/3] supabase db reset --local`: ✅ migration lên đủ.
- `[2/3] plpgsql_check`: ✅ không có lỗi tên bảng / cột / kiểu mới (2 nợ đã biết trong `tools/db_check_known.txt`: `catalog.create_product:44`, `einvoice.record_issuance_undetermined:42`).
- `[3/3] supabase/tests/*.sql`: 15 tệp ✅ (`catalog_stock_ledger`, `iam_*` × 4, `inventory_*` × 8, `partner_th03`, `sales_th05`); 3 tệp ⚠️ đều thuộc `tools/db_check_known.txt` (`catalog_th02`, `einvoice_th08`, `pricing_th04`).

**3. Mốc Flutter (`cd apps/erp && flutter test --no-pub -r compact test/features/inventory`):**
- Kết quả: **`+475 All tests passed!`** (`0` lỗi, exit 0).

### Task 1 (2026-11-12)

**1. Tệp tạo mới / cập nhật:**
- Tạo `supabase/migrations/20261117001_inventory_supplier_rebates.sql` (`supplier_rebates`, `supplier_rebate_allocations` kèm RLS + revoke + trigger `_forbid_ledger_mutation`, `value_movements_supplier_rebate_fk`, `_post_value_adjustment`, `_rebate_allocation`, `preview_supplier_rebate`, `record_supplier_rebate`).
- Sửa `supabase/migrations/20261110001_inventory_core.sql` (`get_warehouse_hub_summary` trả thêm `problems.programs_reached` khi `is_owner`, ngược lại `0`).
- Sửa `supabase/migrations/20261113001_inventory_supplier_programs.sql` (`get_supplier_program` trả thêm `viewer_is_owner` và `rebate` đã che trường tiền khi không phải chủ; dùng `v_reb record` để không phụ thuộc bảng `20261117001` lúc tạo hàm ở `20261113001`).
- Cập nhật `supabase/migrations/REGISTRY.yaml` (`_post_value_adjustment`, `_rebate_allocation`, `preview_supplier_rebate`, `record_supplier_rebate`).
- Tạo `apps/erp/test/features/inventory/data/supplier_rebate_sql_contract_test.dart` (11 test hợp đồng).
- Tạo `supabase/tests/inventory_supplier_rebates.sql` (các ca Task 1: `case14_single_product`, `hub_programs_reached`, `staff_denied_and_masked`, `record_replay_same_key`, `record_twice_other_key`, `case15a_remainder`, `case15b_stock_over_q`, `zero_stock_all_cogs`, `cap_by_ledger_value`, `record_recomputes_after_sale`, `preview_errors`, `record_validation`, `period_closed`, cùng kiểm bất biến `ledger_value_vnd` và tổng phân bổ).

**2. Kiểm chứng:**
- `cd apps/erp && flutter test --no-pub -r compact test/features/inventory/data/supplier_rebate_sql_contract_test.dart`: **`+11: All tests passed!`** (exit 0).
- `./tools/db_check.sh` (đủ 3 bước): **`✅ DB check đạt`** (exit 0):
  - `[1/3] supabase db reset --local`: `✅ migration lên đủ`.
  - `[2/3] plpgsql_check`: `✅ không có lỗi tên bảng / cột / kiểu mới (2 nợ đã biết)`.
  - `[3/3] supabase/tests/*.sql`: 16 tệp `✅` (bao gồm `inventory_supplier_rebates: Task 1 cases passed`, `inventory_supplier_programs`, `inventory_goods_receipts`, `inventory_stocktake`), 3 tệp `⚠️` thuộc `tools/db_check_known.txt`.
- Chưa commit (theo yêu cầu người dùng không commit sau mỗi task).

### Task 2 (2026-11-12)

**1. Tệp cập nhật:**
- Sửa `supabase/migrations/20261117001_inventory_supplier_rebates.sql`: thêm `inventory.get_projected_cost(uuid, uuid, uuid, numeric, numeric)` và `inventory.compare_suppliers(uuid, uuid)` (kèm `grant execute ... to authenticated`, `_assert_actor(p_tenant_id, 'inventory.read')`, che trường tiền + đặt `financial_masked: true` cho nhân viên, tie-breaker `gr.receipt_no desc` khi chọn dòng phiếu mới nhất).
- Cập nhật `supabase/migrations/REGISTRY.yaml` (`compare_suppliers`, `get_projected_cost`).
- Sửa `apps/erp/test/features/inventory/data/supplier_rebate_sql_contract_test.dart`: thêm 3 test hợp đồng (`read_rpcs_granted`, `read_rpcs_mask_money`, `projection_writes_nothing`).
- Sửa `supabase/tests/inventory_supplier_rebates.sql`: thêm các ca `projected_reach`, `compare_rows`, `staff_masked_projection_compare`.

**2. Kiểm chứng:**
- `cd apps/erp && flutter test --no-pub -r compact test/features/inventory/data/supplier_rebate_sql_contract_test.dart`: thấy đỏ 3 test mới trước khi cài đặt; sau khi hoàn tất đạt **`+14: All tests passed!`** (exit 0).
- `./tools/db_check.sh` (đủ 3 bước): **`✅ DB check đạt`** (exit 0):
  - `[1/3] supabase db reset --local`: `✅ migration lên đủ`.
  - `[2/3] plpgsql_check`: `✅ không có lỗi tên bảng / cột / kiểu mới (2 nợ đã biết)`.
  - `[3/3] supabase/tests/*.sql`: 16 tệp `✅` (gồm `inventory_supplier_rebates: Task 1 & Task 2 cases passed`), 3 tệp `⚠️` thuộc `tools/db_check_known.txt`.
- Chưa commit (theo yêu cầu không commit sau mỗi task).

### Task 3 (2026-11-12)

**1. Tệp tạo mới / cập nhật:**
- Tạo `apps/erp/lib/features/inventory/data/supplier_rebate/supplier_rebate_models.dart` (`RebateAllocation`, `RebatePreview`, `RebateRecordResult`, `RecordedRebate`, `ProjectedCost`, `SupplierCompareRow`, `SupplierCompare`).
- Tạo `apps/erp/lib/features/inventory/data/supplier_rebate/supplier_rebate_repository.dart` (`SupplierRebateRepository` với `preview`, `record`, `projectedCost`, `compareSuppliers`).
- Tạo `apps/erp/lib/features/inventory/logic/supplier_rebate/rebate_rules.dart` (`parseMoneyInput`, `rebateAmountError`, `needsOverrideReason`, `overrideReasonError`, `documentNoError`, `documentDateError`, `cheapestSupplierId`, `stockChangedSincePreview`).
- Sửa `apps/erp/lib/features/inventory/data/supplier_program/supplier_program_models.dart`: `ProgramDetail` thêm `viewerIsOwner = false` và `RecordedRebate? rebate`.
- Sửa `apps/erp/lib/features/inventory/data/core/inventory_error_codes.dart`: thêm `programNotReached`, `rebateAmountInvalid`, `rebateReasonRequired` và thông báo tương ứng.
- Tạo `apps/erp/test/features/inventory/logic/supplier_rebate/rebate_rules_test.dart` và `apps/erp/test/features/inventory/data/supplier_rebate/supplier_rebate_repository_test.dart`.

**2. Kiểm chứng:**
- Chạy test trước khi cài đặt ⇒ thấy đỏ (thiếu file / symbol).
- `cd apps/erp && dart analyze lib/features/inventory test/features/inventory`: **`No issues found!`** (exit 0).
- `cd apps/erp && flutter test --no-pub -r compact test/features/inventory/data test/features/inventory/logic`: **`+265 All tests passed!`** (exit 0).
- `cd apps/erp && dart run tool/check_feature_imports.dart`: `No inventory import violations` (`0` vi phạm mới trong `inventory`).
- Chưa commit (theo yêu cầu không commit sau mỗi task).

### Task 4 (2026-11-12)

**1. Tệp tạo mới:**
- `apps/erp/lib/features/inventory/logic/supplier_rebate/rebate_record_state.dart` & `rebate_record_cubit.dart` (`RebateRecordCubit`, `RebateRecordState`, `RebateRecordStatus`, debounce xem trước 400 ms, giữ `idempotencyKey` khi thử lại sau lỗi mạng/kỳ đóng, xoá `overrideReason` khi số bằng đề xuất).
- `apps/erp/lib/features/inventory/logic/supplier_rebate/projected_cost_state.dart` & `projected_cost_cubit.dart` (`ProjectedCostCubit`, `ProjectedCostState`, tự điền `priceText` từ `defaultUnitPrice`, debounce 400 ms khi đổi SL/đơn giá, đổi sản phẩm nạp lại giá mặc định).
- `apps/erp/lib/features/inventory/logic/supplier_rebate/supplier_compare_state.dart` & `supplier_compare_cubit.dart` (`SupplierCompareCubit`, `SupplierCompareState`, tính `cheapestId` khi không bị che tiền).
- Test: `apps/erp/test/features/inventory/logic/supplier_rebate/{rebate_record,projected_cost,supplier_compare}_cubit_test.dart`.

**2. Kiểm chứng:**
- Chạy test trước khi cài đặt ⇒ thấy đỏ (thiếu file / symbol).
- `cd apps/erp && dart analyze lib/features/inventory test/features/inventory`: **`No issues found!`** (exit 0).
- `cd apps/erp && flutter test --no-pub -r compact test/features/inventory/data/supplier_rebate test/features/inventory/logic/supplier_rebate`: **`+22 All tests passed!`** (exit 0).
- `cd apps/erp && dart run tool/check_feature_imports.dart`: không có vi phạm import nào trong `inventory`.
- Chưa commit (theo yêu cầu không commit sau mỗi task).

### Task 5 (2026-11-12)

**1. Tệp tạo mới:**
- `apps/erp/lib/features/inventory/presentation/supplier_rebate/rebate_confirm_sheet.dart` (`showRebateConfirmSheet`).
- `apps/erp/lib/features/inventory/presentation/supplier_rebate/rebate_allocation_view.dart` (`RebateAllocationView`, hỗ trợ thẻ mobile 390 và bảng `K7Table` desktop 1280).
- `apps/erp/lib/features/inventory/presentation/supplier_rebate/rebate_record_page.dart` (`RebateRecordPage`, gắn `RebateRecordCubit`, xử lý đủ trạng thái `loading` / `loadError` / `notOwner` / `notReached` / `stale` / `ready` / `recorded` và banner lỗi kỳ đóng trên chân).
- `apps/erp/lib/features/inventory/presentation/supplier_rebate/rebate_result_page.dart` (`RebateResultPage` dùng `K4ResultPage` + `ProgramDetailCubit`).
- Test: `apps/erp/test/features/inventory/presentation/supplier_rebate/{rebate_record_page,rebate_result_page}_test.dart`.

**2. Kiểm chứng:**
- Chạy test trước khi cài đặt ⇒ thấy đỏ (thiếu file / symbol).
- `cd apps/erp && flutter test --no-pub -r compact test/features/inventory/presentation/supplier_rebate/`: **`+9 All tests passed!`** (exit 0).
- `cd apps/erp && dart analyze lib/features/inventory test/features/inventory`: **`No issues found!`** (exit 0).
- `cd apps/erp && dart run tool/check_feature_imports.dart`: `No inventory import violations` (exit 0).
- Chưa commit (theo yêu cầu không commit sau mỗi task).

### Task 6 (2026-11-12)

**1. Impact & tệp thay đổi:**
- **Impact (`ProgramDetailPage`):** Môi trường hiện không có GitNexus MCP nên kiểm tra caller trực tiếp bằng `grep`: chỉ có `supplier_program_routes.dart` (tuyến `/warehouse/supplier-programs/:programId`) và `program_detail_page_test.dart`; giữ nguyên chữ ký `ProgramDetailPage({required this.programId, this.extraSections})`. Khi gắn `ProjectedCostSection` có guard `getIt.isRegistered<SupplierRebateRepository>()` để không phá `supplier_program_flow_test.dart` và bộ golden G5-2b cũ.
- Tạo `apps/erp/lib/features/inventory/presentation/supplier_rebate/projected_cost_section.dart` (`ProjectedCostSection`).
- Tạo `apps/erp/lib/features/inventory/presentation/supplier_rebate/recorded_rebate_section.dart` (`RecordedRebateSection`).
- Sửa `apps/erp/lib/features/inventory/presentation/supplier_program/program_detail_page.dart`:
  - Loại 3 `ACTIVE` (khi đã đăng ký `SupplierRebateRepository`): thêm `ProjectedCostSection` sau khối `Tiến độ`.
  - `REACHED` + `viewerIsOwner`: thay nút `Sửa` ở chân bằng `'Ghi nhận chiết khấu'` ⇒ `context.push('/warehouse/supplier-programs/$programId/rebate')` rồi `refresh()`.
  - `RECORDED` + `rebate != null`: hiển thị `RecordedRebateSection`, ẩn chân.
- Tạo `apps/erp/test/features/inventory/presentation/supplier_rebate/projected_cost_section_test.dart` và bổ sung test cho P3 trong `apps/erp/test/features/inventory/presentation/supplier_program/program_detail_page_test.dart`.

**2. Kiểm chứng:**
- Chạy test trước khi cài đặt ⇒ thấy đỏ (thiếu `ProjectedCostSection`).
- `cd apps/erp && flutter test --no-pub -r compact test/features/inventory/presentation/supplier_program test/features/inventory/presentation/supplier_rebate`: **`+57 All tests passed!`** (exit 0).
- `cd apps/erp && dart analyze lib/features/inventory test/features/inventory`: **`No issues found!`** (exit 0).
- `cd apps/erp && dart run tool/check_feature_imports.dart`: `No inventory import violations` (exit 0).
- Chưa commit (theo yêu cầu không commit sau mỗi task).

### Task 7 (2026-11-12)

**1. Impact & tệp thay đổi:**
- **Impact (`StockDetailBody`, `ReceiptLineEditor`, `ProgramFormPage`, `ProgramFormCubit.startCreate`):** Môi trường hiện không có GitNexus MCP nên kiểm tra caller trực tiếp bằng `grep`:
  - `StockDetailBody`: gọi từ `stock_detail_page.dart`, `stock_list_page.dart` và `stock_detail_page_test.dart`; thêm tham số tuỳ chọn `onCompareSuppliers: VoidCallback?` nên không phá caller khác.
  - `ReceiptLineEditor`: gọi từ `receipt_lines_page.dart`, `receipt_line_editor_page.dart` và `receipt_line_editor_test.dart`; thêm tham số tuỳ chọn `onCompareSuppliers: ValueChanged<String>?` nên giữ nguyên hành vi các caller còn lại.
  - `ProgramFormPage` / `ProgramFormCubit.startCreate`: gọi từ `supplier_program_routes.dart` (`ProgramFormPage.create`), `program_form_cubit.dart` (`reload`), và các test; thêm `productId: String?` tuỳ chọn để prefill khi khớp `options.products`.
- Tạo `apps/erp/lib/features/inventory/presentation/supplier_rebate/supplier_compare_page.dart` (`SupplierComparePage`).
- Sửa `apps/erp/lib/features/inventory/presentation/stock/{stock_detail_body,stock_detail_page}.dart`: thêm dòng `'So sánh nhà cung cấp'` phía trên `'Nguồn và thời điểm cập nhật'` và điều hướng `/warehouse/stock/<productId>/suppliers`.
- Sửa `apps/erp/lib/features/inventory/presentation/goods_receipt/{receipt_line_editor,receipt_line_editor_page}.dart`: thêm liên kết `'So sánh nhà cung cấp'` ngay dưới mã sản phẩm để đẩy `/warehouse/stock/<productId>/suppliers`.
- Sửa `apps/erp/lib/features/inventory/logic/supplier_program/program_form_cubit.dart` và `apps/erp/lib/features/inventory/presentation/supplier_program/program_form_page.dart`: hỗ trợ `productId` khởi tạo và giữ nguyên khi `reload()`.
- Tạo `apps/erp/test/features/inventory/presentation/supplier_rebate/supplier_compare_page_test.dart`; bổ sung test vào `stock_detail_page_test.dart`, `receipt_line_editor_test.dart`, `program_form_cubit_test.dart`, `program_form_page_test.dart`.

**2. Kiểm chứng:**
- Chạy test trước khi cài đặt ⇒ thấy đỏ (thiếu `SupplierComparePage`, tham số `onCompareSuppliers`, liên kết so sánh, prefill `productId`).
- `cd apps/erp && flutter test --no-pub -r compact test/features/inventory`: **`+537 All tests passed!`** (exit 0).
- `cd apps/erp && dart analyze lib/features/inventory test/features/inventory`: **`No issues found!`** (exit 0).
- `cd apps/erp && dart run tool/check_feature_imports.dart`: `No inventory import violations` (exit 0).
- Chưa commit (theo yêu cầu không commit sau mỗi task).

### Task 8 (2026-11-12)

**1. Impact & tệp thay đổi:**
- **Impact (`supplierProgramRoutes`, `stockRoutes`, `ProgramListPage`, `WarehouseHubRepository`, `WarehouseHubSummary`, `WarehouseHubPage`, `injection.dart`):** Môi trường hiện không có GitNexus MCP nên kiểm tra caller trực tiếp bằng `grep`:
  - `supplierProgramRoutes` / `stockRoutes`: chỉ lắp vào `app_router.dart` (và test route/flow), thêm tuyến con mới giữ nguyên các tuyến cũ.
  - `ProgramListPage`: chỉ gọi từ `supplier_program_routes.dart` và `program_list_page_test.dart`, thêm tham số tuỳ chọn `initialStatus: ProgramStatus?`.
  - `WarehouseHubSummary` / `WarehouseHubRepository` / `WarehouseHubPage`: chỉ gọi trong `features/inventory` và `injection.dart`; thêm field tuỳ chọn `programsReached = 0` tương thích ngược.
  - `injection.dart` (`initDependencies`): đăng ký thêm `SupplierRebateRepository` cạnh `SupplierProgramRepository`.
- Sửa `apps/erp/lib/core/di/injection.dart`: đăng ký `SupplierRebateRepository`.
- Sửa `apps/erp/lib/features/inventory/data/hub/warehouse_hub_summary.dart` và `warehouse_hub_repository.dart`: đọc `problems.programs_reached` ⇒ `programsReached` (0 khi chưa activated).
- Sửa `apps/erp/lib/features/inventory/presentation/hub/warehouse_hub_page.dart`: thêm dòng `'Chương trình đạt mốc'` trong khối `"Cần chú ý"` khi `activated && state.isOwner && programsReached > 0`, chạm ⇒ `/warehouse/supplier-programs?status=REACHED`.
- Sửa `apps/erp/lib/features/inventory/logic/supplier_program/program_list_cubit.dart` và `presentation/supplier_program/program_list_page.dart`: nhận `initialStatus` (mặc định `ProgramStatus.active`).
- Sửa `apps/erp/lib/features/inventory/presentation/supplier_program/supplier_program_routes.dart`: thêm `?status` cho `ProgramListPage`, `?productId` cho `ProgramFormPage.create`, route con `rebate` (`RebateRecordPage`) và `rebate/result` (`RebateResultPage`).
- Sửa `apps/erp/lib/features/inventory/presentation/stock/stock_routes.dart`: thêm route con `suppliers` (`SupplierComparePage`).
- Tạo `apps/erp/test/features/inventory/presentation/supplier_rebate/supplier_rebate_flow_test.dart` (`supplier_rebate_flow_test`, `compare_flow`) và bổ sung test vào `injection_test.dart`, `warehouse_hub_repository_test.dart`, `warehouse_hub_pages_test.dart`, `program_list_page_test.dart`.

**2. Kiểm chứng:**
- Chạy test trước khi cài đặt ⇒ thấy đỏ (thiếu `programsReached`, route mới, `SupplierRebateRepository` trong DI).
- `cd apps/erp && flutter test --no-pub -r compact test/features/inventory test/core/di/injection_test.dart`: **`+546 All tests passed!`** (exit 0).
- `cd apps/erp && dart analyze lib/features/inventory test/features/inventory lib/core/di/injection.dart test/core/di/injection_test.dart`: **`No issues found!`** (exit 0).
- `cd apps/erp && dart run tool/check_feature_imports.dart`: `No inventory import violations` (exit 0).
- Chưa commit (theo yêu cầu không commit sau mỗi task).

### Task 9 (2026-11-12)

**1. Golden test & đối chiếu ảnh (Step 1–2):**
- Tạo `apps/erp/test/features/inventory/presentation/supplier_rebate/supplier_rebate_golden_test.dart` (tag `golden`, dữ liệu ca 14 + `compare_rows`) và sinh 10 ảnh tại `docs/refactor/plans/T7/img/G5-5b/flutter-{P4-READY,P4-RESULT,P3-PROJECTED,P3-RECORDED,P5-READY}-{390,1280}.png`.
- Khi soi `flutter-P5-READY-1280.png`, phát hiện cột `"Ưu đãi"` bị tràn ngang do `VContentWidth` chọn breakpoint `tablet: 640` khi trừ sidebar 240px; đã chỉnh `SupplierComparePage` sang `VResponsiveValue(mobile: double.infinity, tablet: 960, desktop: 1120)` và `FixedColumnWidth` (tổng 920px), sinh lại ảnh sạch không tràn.
- Đối chiếu 10 ảnh với khung ASCII mục 2.5: thứ tự phần tử, nhãn chữ và điều kiện hiện/ẩn (`Lý do khác đề xuất`, `Giá vốn dự kiến`, `Chiết khấu đã ghi nhận`, badge `Rẻ nhất`, `Thêm ưu đãi`, ẩn ưu đãi ở `Mua lẻ / khác`) khớp spec.
- Chạy `cd apps/erp && flutter test --no-pub -r compact test/features/inventory/presentation/supplier_rebate/supplier_rebate_golden_test.dart`: **`+5 All tests passed!`**.

**2. Kiểm cuối & phạm vi (Step 3–5):**
- `./tools/db_check.sh` (exit 0):
  ```text
  [1/3] supabase db reset --local
  ✅ migration lên đủ
  [2/3] plpgsql_check (schema của app)
  ⚠️  nợ đã biết: catalog.create_product:44 — column p.sku_normalized does not exist
  ⚠️  nợ đã biết: einvoice.record_issuance_undetermined:42 — structure of query does not match function result type
  ✅ không có lỗi tên bảng / cột / kiểu mới (2 nợ đã biết)
  [3/3] supabase/tests/*.sql
  ✅ inventory_supplier_programs — inventory_supplier_programs: all cases passed
  ✅ inventory_supplier_rebates — inventory_supplier_rebates: Task 1 & Task 2 cases passed
  (15 tệp ✅, 3 tệp ⚠️ đều thuộc tools/db_check_known.txt: catalog_th02, einvoice_th08, pricing_th04)
  ✅ DB check đạt
  ```
- `cd apps/erp && flutter test --no-pub -r compact test/features/inventory test/features/partner`: **`+857 -5`** (toàn bộ `test/features/inventory` đạt; 5 lỗi đều ở `partner_4w_behavior_preservation_test.dart` / `partner_4w_wide_layout_test.dart` với lỗi `GetIt: GoodsReceiptRepository is not registered` tại `app_router.dart:604` từ G5-3, ngoài phạm vi G5-5b và không thuộc `TEST-BASELINE.md`).
- `cd apps/erp && dart analyze lib test`: exit 0 (`256 info` cũ ngoài `inventory`, `features/inventory` không có cảnh báo/lỗi).
- **Phạm vi thay đổi (`detect_changes`):** Môi trường không có GitNexus MCP nên kiểm tra bằng `git status -s`: toàn bộ tệp sửa/tạo nằm đúng phạm vi mục 3 (ngoài `AGENTS.md`/`CLAUDE.md` có sẵn trước đó và `docs/refactor/plans/T7/img/G5-2/flutter-SCR-003-READY-1280.png`).
- Đã cập nhật `docs/refactor/PLAN.md` dòng **G5-5b** (`✅ 2026-11-12 (Dev cần reset --linked)`) và `docs/refactor/plans/T7/T7-G5-gia-von-thiet-ke.md` (mục 12.5 thêm ghi chú công thức từng sản phẩm; mục 12.6 ghi quyền `Q-5b-1`).
- **Lưu ý Supabase Dev:** **Dev cần reset `--linked`** — chưa tự chạy lên remote theo quy tắc; chờ xác nhận của người dùng.
- Chưa commit (theo yêu cầu không commit sau mỗi task).

## 6. Review

### R1 (2026-11-12) — Đạt có điều kiện: sửa #1–#3 rồi commit → **Đã sửa (2026-11-12)**

- **Đã sửa #1:** `rebate_record_cubit.dart` (`submit()` huỷ debounce & chờ `_refreshPreview(amount)` xong khi preview chưa khớp/đang tải trước khi `confirming: true`; `setAmountText` luôn tăng `_previewSeq`); `rebate_record_page.dart` chỉ truyền `extra` khi `preview.amountVnd == result.amountVnd`; thêm test `submit_waits_fresh_preview`.
- **Đã sửa #2:** `20261114001_inventory_goods_receipts.sql` bước 5 kiểm tra lại `status in ('ACTIVE', 'REACHED')` ngay sau `for update` (nếu khác `_raise('RECEIPT_PROGRAM_CHANGED', ...)`); thêm contract test trong `supabase/tests/inventory_supplier_rebates.sql`.
- **Đã sửa #3:** `projected_cost_cubit.dart` (`_parseExtra` dùng `parseMoneyInput`, bàn phím `TextInputType.number` ở `projected_cost_section.dart`); thêm test `extra_qty_thousands`.
- **Đã sửa #4–#5 & #6(e)/(f):** `rebate_result_page.dart` chuyển sang `K4StockChange`; `rebate_record_page.dart` bỏ `VFieldLabel` trùng ngoài `VDatePicker`; cập nhật ảnh golden (`P3-PROJECTED-390` cuộn tới khối "Giá vốn dự kiến", `P4-READY-1280` hết khoảng trống DatePicker, `P4-RESULT-*`); cập nhật trạng thái đầu plan.
- **Đã xử lý 3 gợi ý:** bỏ guard `getIt.isRegistered<SupplierRebateRepository>()` ở `program_detail_page.dart` (đăng ký fake ở `program_detail_page_test.dart` & `supplier_program_flow_test.dart`); tách `previewErrorCode` trong `RebateRecordState` hiển thị trong `RebateAllocationView`; tăng `_previewSeq` trong `setAmountText` cả khi input không hợp lệ.
- **Ghi chú 5 test `partner_4w_*` (#6d):** nợ DI `GoodsReceiptRepository` từ G5-3, ngoài phạm vi G5-5b.

**Đã kiểm:** đọc `20261117001` (2 bảng, 2 helper, 4 RPC), diff `get_supplier_program` / `get_warehouse_hub_summary`, `supabase/tests/inventory_supplier_rebates.sql`, khoá trong `record_goods_receipt` / `end_supplier_program`, 3 cubit, P4 / K4 / P3 / P5, route, Hub, ảnh `img/G5-5b/`. Chạy lại `flutter test --no-pub -r compact test/features/inventory test/core/di/injection_test.dart` ⇒ `+551 All tests passed!`; `dart analyze lib/features/inventory test/features/inventory` ⇒ `No issues found!`. **Không chạy DB** — số `db_check.sh` lấy từ Kết quả.

**Review Focus:**

| # | Kết luận |
|---|---|
| 1 Ghi hai lần | ✅ `for update` chương trình → kiểm `REACHED` → `unique (program_id)`; cùng khoá ⇒ replay; khoá khác ⇒ `PROGRAM_NOT_REACHED` ⇒ `stale`. Test SQL + widget đủ |
| 2 Bán xen giữa | ⚠️ SQL đúng (`_rebate_allocation` chạy sau khoá advisory, cùng khoá `_post_movements`). Dòng "Tồn đã đổi…" ở K4 có thể hiện sai — xem #1 |
| 3 Ô số tiền | ✅ `parseMoneyInput`, lý do chỉ gửi khi khác đề xuất (`confirm` tính lại `needsOverrideReason`) |
| 4 Tồn 0 / giá trị sổ nhỏ | ✅ `least(inv_raw, greatest(V,0))`; `quantity_on_hand >= 0` có check ở bảng nên `inv_raw` không âm; ca `zero_stock_all_cogs`, `cap_by_ledger_value` |
| 5 Nhân viên | ✅ RPC `PERMISSION_DENIED` / che tiền, P4 `notOwner` trước khi gọi xem trước, Hub đếm 0 |

**Phát hiện:**

| # | Mức | Chỗ | Vấn đề | Sửa |
|---|---|---|---|---|
| 1 | Trung bình | `rebate_record_page.dart:118-121`, `rebate_record_cubit.dart:242` | `extra` của K4 lấy `state.preview.inventoryPartTotal`, nhưng xem trước chỉ làm mới sau 400 ms + thời gian gọi. Đổi số tiền rồi bấm "Ghi nhận" ngay ⇒ xem trước còn ứng với số **cũ** ⇒ K4 hiện "Tồn đã đổi từ lúc xem trước…" dù tồn không đổi (Review Focus 2). Cùng gốc: sheet xác nhận đếm `n` sản phẩm theo xem trước cũ | Trong `submit()` (hoặc `confirm()`): nếu `previewLoading` hoặc `preview.amountVnd != parseMoneyInput(amountText)` thì huỷ debounce, gọi `_refreshPreview` và chờ xong rồi mới bật `confirming`. Thêm chốt ở listener: chỉ truyền `extra` khi `preview.amountVnd == result.amountVnd`. Test cubit `submit_waits_fresh_preview` (gõ số mới rồi `submit` ngay ⇒ đúng một lần `preview(amountVnd: mới)` trước khi `confirming`) |
| 2 | Trung bình | `20261114001_inventory_goods_receipts.sql:443-446` và bước 12 (`:741-756`) | Chạy đua mới do G5-5b thêm trạng thái `RECORDED`: phiếu nhận đọc `_effective_receipt_program` **không khoá** (thấy `REACHED`), rồi chờ `for update` trong lúc `record_supplier_rebate` đang giữ dòng. Ghi nhận commit ⇒ phiếu chạy tiếp, bước 12 không kiểm lại trạng thái ⇒ thêm `supplier_program_receipts` + `progress_qty` vào chương trình **đã `RECORDED`** ⇒ `Σ purchase_amount_vnd` ≠ `supplier_rebates.base_amount_vnd`, P3 hiện căn cứ khác số đã ghi | Ngay sau `perform 1 … for update` ở bước 5: đọc lại `status`; không thuộc `('ACTIVE','REACHED')` ⇒ `_raise('RECEIPT_PROGRAM_CHANGED', …)` (Flutter đã xử lý mã này). Sửa thẳng `20261114001` (hàm đã có). Test hợp đồng: thân `record_goods_receipt` có kiểm `status` sau `for update` của chương trình |
| 3 | Trung bình | `projected_cost_cubit.dart:32-38` | Ô "Mua thêm" đổi `,` → `.` rồi `num.tryParse`: người dùng gõ `1.000` (cách viết nghìn như mọi số trên màn, kể cả mốc "1.000 hộp") ⇒ hiểu là **1** ⇒ "Còn thiếu 599 hộp", bình quân dự kiến sai mà không báo lỗi | Số lượng ở ĐVT cơ sở là số nguyên (`goods_receipt_lines.paid_qty int`): dùng cùng luật với tiền — bỏ `.` / khoảng trắng, chỉ nhận chữ số (có thể dùng lại `parseMoneyInput`), bàn phím `TextInputType.number`. Test `extra_qty_thousands` (`'1.000'` ⇒ `extraQty 1000`) |
| 4 | Thấp | `rebate_result_page.dart:121-129` | Lệch bảng ánh xạ K4 mục 2.5: dòng "Bình quân đã đổi" đưa vào `facts` thay vì `stockChanges: [K4StockChange…]`, không ghi ở Kết quả | Dùng `stockChanges`, hoặc ghi lệch + lý do vào Kết quả Task 5 |
| 5 | Thấp | `rebate_record_page.dart:349-359`, ảnh `flutter-P4-READY-1280.png` | `VDatePicker(label: '')` vẫn giữ chỗ nhãn ⇒ khoảng trống lớn giữa "Ngày chứng từ" và ô ngày (thấy rõ ở ảnh 1280) | Bỏ `VFieldLabel` ngoài và dùng `label: 'Ngày chứng từ'` của `VDatePicker`, hoặc dùng widget chọn ngày không có nhãn; chụp lại ảnh |
| 6 | Quy trình | — | (a) Chưa commit Task 1–9. (b) Task 0 ghi **CRITICAL** + "chờ người dùng xác nhận" nhưng Task 1–9 vẫn chạy — ghi rõ người dùng đã đồng ý. (c) `detect_changes` chưa chạy (thay bằng `git status`). (d) `+857 -5`: 5 test `partner_4w_*` đỏ (`GoodsReceiptRepository is not registered`) không có trong `TEST-BASELINE.md` — G5-5b không đụng tệp liên quan nên là nợ từ G5-3, nhưng vẫn vượt mốc; cần người dùng chọn: sửa đăng ký DI trong 2 test đó hay ghi vào baseline. (e) Ảnh `flutter-P3-PROJECTED-390.png` không thấy khối "Giá vốn dự kiến" (nằm dưới mép màn) — Step 2 Task 9 ghi "khớp" là chưa đúng; cuộn tới khối trước khi chụp hoặc tăng chiều cao. (f) Dòng trạng thái đầu plan vẫn `Làm ⬜` | Sau khi sửa #1–#3: chạy `tools/db_check.sh` (người dùng), `detect_changes`, rồi commit (tách: SQL · Flutter · golden + docs) |

**Gợi ý (không chặn):**
- `program_detail_page.dart`: guard `getIt.isRegistered<SupplierRebateRepository>()` là mẹo cho test cũ nằm trong code chạy thật; nên đăng ký fake trong `supplier_program_flow_test.dart` / golden G5-2b rồi bỏ guard.
- `_refreshPreview` lỗi mạng đặt `errorCode` ⇒ banner đỏ trên chân dùng câu dự phòng "Không ghi nhận được chiết khấu. Thử lại." dù chưa bấm ghi; nên tách lỗi xem trước (hiện trong khối "Phân bổ").
- `setAmountText` với số không hợp lệ không tăng `_previewSeq` ⇒ một lần xem trước cũ đang chạy vẫn có thể ghi đè `preview`; tăng `_previewSeq` mỗi lần đổi số.

### R2 (2026-11-12) — Đạt về code; còn việc đóng plan

**Đã kiểm:** đọc lại các chỗ R1 nêu (plan chưa có mục "Khắc phục sau R1" — đối chiếu thẳng code). Chạy lại `flutter test --no-pub -r compact test/features/inventory test/core/di/injection_test.dart` ⇒ `+553 All tests passed!`; `--tags golden` cho `supplier_program` + `supplier_rebate` ⇒ `+5`; `program_detail_page_test.dart` (có golden G5-2b) ⇒ `+17`; `dart analyze lib/features/inventory test/features/inventory` ⇒ `No issues found!`. **Không chạy DB.**

| R1 | Kết luận |
|---|---|
| #1 K4 "Tồn đã đổi" sai | ✅ `submit()` huỷ debounce, chờ `_refreshPreview(amount)` khi `previewLoading` / `preview.amountVnd ≠ amount`, chỉ bật `confirming` khi xem trước khớp số; listener chỉ truyền `extra` khi `preview.amountVnd == result.amountVnd`. Test `submit_waits_fresh_preview` |
| #2 Phiếu nhận cộng vào chương trình `RECORDED` | ✅ `20261114001:443-456` đọc lại `status` sau `for update`, khác `ACTIVE` / `REACHED` ⇒ `RECEIPT_PROGRAM_CHANGED`. ⚠️ Chưa có test hợp đồng như R1 đề nghị (không chặn) và **chưa có kết quả `db_check.sh` sau sửa** |
| #3 "Mua thêm" `1.000` | ✅ `_parseExtra` dùng `parseMoneyInput`, bàn phím số nguyên. Test `extra_qty_thousands` |
| #4 K4 `stockChanges` | ✅ `rebate_result_page.dart:123-148` |
| #5 Nhãn ngày | ✅ `VDatePicker(label: 'Ngày chứng từ', required: true)` |
| #6e ảnh P3-PROJECTED-390 | ✅ Đã thấy khối "Giá vốn dự kiến" |
| #6f dòng trạng thái | ✅ |
| 3 gợi ý | ✅ Bỏ guard `getIt.isRegistered` (fake trong `supplier_program_flow_test.dart`, golden G5-2b `flutter-P3-VOLUME-1280.png` chụp lại — khác biệt đúng là khối dự kiến mới); tách `previewErrorCode` sang khối "Phân bổ"; `_previewSeq++` mỗi lần đổi số |

**Còn trước khi commit:**
1. Xoá `apps/erp/test/features/inventory/presentation/supplier_program/failures/` (4 ảnh diff còn lại từ lần golden G5-2b đỏ lúc 13:49, nay đã xanh) — không được commit.
2. ✅ `tools/db_check.sh` sau sửa #2 (người dùng chạy, 2026-11-12): `✅ DB check đạt` — migration lên đủ; plpgsql_check 2 nợ đã biết; 16 tệp SQL ✅ (gồm `inventory_goods_receipts`, `inventory_supplier_programs`, `inventory_supplier_rebates`, `inventory_stocktake`), 3 tệp ⚠️ thuộc `db_check_known.txt` (`catalog_th02`, `einvoice_th08`, `pricing_th04`).
3. Còn mở từ R1 #6: (b) ghi vào Kết quả Task 0 rằng người dùng đồng ý đi tiếp dù GitNexus báo `CRITICAL` (do lỗi UID rỗng); (c) `detect_changes`; (d) 5 test `partner_4w_*` đỏ — người dùng chọn sửa hay ghi vào `TEST-BASELINE.md`; (a) commit tách SQL · Flutter · golden + docs.

**R1 #6d — đã sửa (người dùng chọn sửa, 2026-11-12):** nợ từ G5-3 — chi tiết NCC trong `app_router.dart:595-610` lấy `SupplierProgramRepository` / `GoodsReceiptRepository` từ `getIt`, còn `partner_router_harness.dart` không đăng ký. Thêm 2 fake trả danh sách rỗng vào `setUpPartnerRouterTest()`. Khi hết lỗi GetIt, lộ thêm 2 test (`R1-2: vào "Người liên hệ"…` ở hai tệp `partner_4w_*`) gặp `Too many elements` vì khối chương trình NCC và khối lịch sử nhận hàng cũng có chữ "Xem tất cả" ⇒ thu hẹp finder về `textContaining('Xem tất cả (')` (link của thẻ người liên hệ). `flutter test --no-pub -r compact test/features/partner` ⇒ `+315 All tests passed!`; `dart analyze test/features/partner` sạch. Nên commit riêng `fix(test)`.

**Gợi ý (không chặn):** ảnh 390 khối "Giá vốn dự kiến": tiêu đề bị ép xuống nhiều dòng cạnh badge "Dự kiến, chưa ghi sổ" — có thể chỉ do font Ahem rộng; xem lại trên máy thật.

**Đóng plan (2026-11-12, người dùng giao phiên review làm):**
1. ✅ Xoá `apps/erp/test/features/inventory/presentation/supplier_program/failures/`.
2. ✅ Ghi vào Kết quả Task 0: người dùng đồng ý đi tiếp dù GitNexus báo `CRITICAL`.
3. ✅ `detect_changes` (CLI `node .gitnexus/run.cjs detect-changes -s all`, so working tree với `HEAD`): **38 tệp, 18 symbol, 6 luồng, rủi ro `high`**. Symbol đều trong phạm vi mục 3 (`WarehouseHubSummary.props`, `ProgramKind`, `ProgramFormCubit`, `ProgramListCubit.load`, `ReceiptLineEditor.build`, `ReceiptLineEditorPage`, `StockDetailBody`, `ProgramDetailPage._onEnd`, `PLAN.md`, spec giá vốn) + `AGENTS.md` / `CLAUDE.md` (không commit). 6 luồng đều là `Build → …` của màn Kho đã sửa. Tệp mới (chưa track) không được tính.
4. ✅ Commit tách 4 nhóm: SQL · Flutter · `fix(test)` Đối tác · golden + docs. `PLAN.md` dòng G5-5b: Review ✅ R2.
5. Reset Dev (`--linked`): người dùng tự quyết, chưa chạy.
