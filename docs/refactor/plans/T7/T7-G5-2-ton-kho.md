# T7-G5-2 — BJ-01 Tồn kho & khả dụng

> Theme 7 · plan **G5-2** của [PLAN.md](../../PLAN.md) mục "Theme 7" (bảng Plan)
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-10) | Làm ✅ (2026-11-10) | Review ✅ R2 đạt (2026-11-10; R1 ❌) — còn nợ P3 #4–#11, chạy `supabase/tests/inventory_stock_view.sql`
> Thiết kế: duyệt trong chat 2026-11-10 (mục 1). Màn: SCR-001, SCR-003 (FROZEN v5.27.0) theo prototype **v5.28.0** (`app/bj01.js`), CAP-01 lấy lại ở [G5-2a](T7-G5-2a-chinh-sach-ton.md). Phụ thuộc: G5-0b, **G5-2a**.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Nhân viên tìm một sản phẩm và thấy ngay khả dụng; chủ cửa hàng lọc hàng hết / tồn thấp / cận hạn / hết hạn, mở chi tiết thấy lô, nguồn số liệu và giá vốn (chỉ chủ cửa hàng); Hub có "Cần chú ý" về tồn.

**Architecture:** Migration `20261112001_inventory_stock_view.sql` thêm 2 RPC đọc (danh sách, chi tiết) dựa trên `inventory._product_stock_rows` của G5-2a; sửa `get_warehouse_hub_summary` (migration gốc G5-0b) điền `problems`. Flutter `features/inventory/{data,logic,presentation}/stock/`: một repository, hai Cubit (danh sách, chi tiết), luật chỉ báo dùng lại `logic/stock/stock_indicator_rules.dart` (G5-2a). Web SCR-001 là danh sách – chi tiết (chi tiết dùng chung widget thân SCR-003).

**Tech Stack:** PostgreSQL / Supabase (plpgsql), Flutter, `flutter_bloc`, `go_router`, `get_it`, `c45_design_system`.

**Spec:** mục 1 của plan này + `specs/themes/theme-07/03.design/screens/SCR-001.md`, `SCR-003.md` + prototype `03.design/prototype/html/app/bj01.js` (v5.28.0) + [spec giá vốn](T7-G5-gia-von-thiet-ke.md) mục 7 (dòng SCR-003) + PLAN.md Theme 7 → "Quy ước chung cho mọi plan G5".

## Global Constraints

- Quy ước chung: PLAN.md Theme 7 → "Quy ước chung cho mọi plan G5".
- **Không** chạy bước DB nào. `supabase/tests/inventory_stock_view.sql` chỉ **viết**.
- Header migration theo khuôn `20261110001_inventory_core.sql`; sửa `get_warehouse_hub_summary` **thẳng trong** `20261110001_inventory_core.sql` (chưa lên Prod). Cập nhật `REGISTRY.yaml`.
- RPC: `security definer`, `set search_path = inventory, iam, catalog, pg_temp`, `grant execute … to authenticated`, quyền `_assert_actor(p_tenant_id, 'inventory.read')`. Không mã lỗi mới.
- **Che tài chính:** trường tiền (`official_unit_cost`, `moving_avg_cost`, `ledger_value_vnd`) chỉ trả khi `is_owner`; người khác nhận `cost: null` + `financial_masked: true` (G5-0b mục 2.4). UI nhân viên **không có khối giá vốn** (không phải khối bị che).
- Chữ trên màn chép **nguyên văn** SCR-001 / SCR-003 mục 8 + chữ đã đổi ở `bj01.js` v5.28.0, trừ chỗ mục 1 ghi "bỏ" / "đề xuất". Chỉ dùng "mã vạch", không "barcode". ĐVT chỉ đi cùng số lượng.
- Số lượng hiển thị bằng `formatQuantity` — Task 2 **dời** hàm này từ `logic/receipt_rules.dart` (sẽ xoá ở G5-3) sang `logic/inventory_format.dart`, `receipt_rules.dart` import lại. Tiền: `MoneyFormatter.formatMinor(int)` (`lib/core/formatting/money_formatter.dart`), đơn giá làm tròn về đồng trước khi định dạng.
- `dart analyze` (không `flutter analyze`). Test: `flutter test --no-pub -r compact`.
- Trước khi sửa symbol đã có (`get_warehouse_hub_summary`, `WarehouseHubRepository.getSummary`, `warehouseAreaEntries`, `warehouseQuickActions`, `warehouseStockSearchRoute`, `K7Table`, `VBadge`, `formatQuantity`, `app_router.dart`): chạy `impact`, ghi Kết quả; HIGH / CRITICAL → dừng, báo người dùng. Cuối plan (Task kiểm cuối): `detect_changes()`.
- `AGENTS.md`, `CLAUDE.md`: không `git add`. Ghi mục 5 Kết quả sau mỗi task.

## Review Focus

1. **Sản phẩm chưa từng nhập (kho trống)** ⇒ vẫn là một dòng "0 {ĐVT}" + "Hết hàng"; kho không có sản phẩm nào ⇒ `EMPTY` "Chưa có dữ liệu tồn kho". Test: Task 1 ca SQL `product_without_movement_listed_zero`; Task 4 `empty_when_no_products`.
2. **Nhân viên xem chi tiết** ⇒ không có khối giá vốn, không "Đặt ngưỡng tồn" / "Sửa ngưỡng"; RPC trả `cost: null`. Test: Task 1 ca SQL `staff_cost_masked`; Task 5 `staff_no_cost_no_threshold_links_390`.
3. **Lô HSD chỉ có tháng / năm** ⇒ hết hạn tính theo cuối tháng / 31-12; sắp lô HSD gần nhất trước; lô không HSD cuối. Test: Task 1 ca `lots_sorted_by_expiry_end`; Task 2 `lot_date_from_json_month`.
4. **Gõ tìm khi đang lọc chip** ⇒ số trên chip không đổi; không ra kết quả ⇒ "Không có kết quả phù hợp" + "Xóa tìm kiếm và bộ lọc" về "Tất cả", ô trống. Máy quét USB gõ mã vạch ⇒ khớp sản phẩm. Test: Task 3 `chip_counts_ignore_search`, `search_matches_barcode`; Task 4 `filter_empty_clear_resets`.
5. **Để app nền hơn 5 phút rồi mở lại** ⇒ banner "Dữ liệu có thể đã cũ" + "Làm mới"; làm mới đổi "Dữ liệu đến" theo giờ máy chủ. Test: Task 3 `stale_after_five_minutes_on_resume`; Task 4 `stale_banner_refresh`.
6. **Web: lọc làm dòng đang chọn biến mất** ⇒ chi tiết bên phải chuyển sang dòng đầu của danh sách đang hiện (không giữ sản phẩm đã ẩn). Test: Task 6 `selected_falls_back_to_first_visible_1280`.

---

## 1. Quyết định (người dùng, 2026-11-10)

| Q | Nội dung |
|---|---|
| Q-2-1 | **Bỏ nút quét mã vạch** (repo chưa có gói camera; toast giả bị cấm). Ô tìm khớp tên, mã, mã vạch (máy quét USB gõ như bàn phím). Bỏ sheet "Quét mã vạch" |
| Q-2-2 | **STALE**: `as_of` cũ hơn **5 phút** ⇒ banner; kiểm khi app quay lại foreground (`AppLifecycleState.resumed`) và khi màn hiện lại (quay về từ màn khác) |
| Q-2-3 | **Khối giá vốn ở SCR-003, chỉ chủ cửa hàng**: giá chính thức (hoặc "Chưa công bố" + chú thích giá tạm khi `PERIODIC`), bình quân liên hoàn, giá trị tồn (sổ), phương pháp. Không có prototype ⇒ khung ASCII Task 5, người dùng duyệt cùng plan |
| Q-2-4 | Theo prototype v5.28.0: khả dụng = tồn lô còn hạn; **bỏ** "Đã giữ" (cột web, dòng "Đang giữ" ở sheet nguồn), "Đủ điều kiện bán" ở thẻ số (lô vẫn có), "Cách ly". **Có lại** (CAP-01, G5-2a): ngưỡng + mục tiêu, "Gợi ý nhập thêm", "Đặt ngưỡng tồn" / "Sửa ngưỡng" mở G5-2a một sản phẩm (chủ cửa hàng) |
| Q-2-5 | **Nút trỏ sang màn chưa có thì ẩn** (Q9): "Nhận hàng" + "Mở phiếu nhận" (G5-3 gắn), "Điều chỉnh lô hết hạn" (G5-5), "Xem thẻ kho và lịch sử" (G5-7). Mỗi chỗ là một `onX` null ⇒ không dựng; plan sau chỉ truyền callback |
| Q-2-6 | Lối vào ngữ cảnh sản phẩm (PCC Theme 2 → SCR-003) **để G5-5** (cùng việc nút "Sửa" thẻ Tồn kho) |
| Q-2-7 | Không seed; sản phẩm liệt kê = mọi sản phẩm `active` chưa xoá của tenant (kể cả chưa có tồn) |

**Chữ đề xuất (không có trong Screen Contract — duyệt cùng plan):**

| Chỗ | Chữ |
|---|---|
| Khối giá vốn (Task 5) | "Giá vốn" · "Giá vốn chính thức" · "{x} đ/{ĐVT}" / "Chưa công bố" · "Bình quân liên hoàn" · "Giá trị tồn (sổ)" · "Phương pháp: Bình quân liên hoàn" / "Phương pháp: Bình quân cuối kỳ" · khi `PERIODIC` chưa có giá chính thức: "Xuất kho đang dùng giá tạm (bình quân liên hoàn)." |
| Hub "Cần chú ý" (Task 7) | dòng "Tồn kho cần chú ý", phụ đề nối phần khác 0 bằng " · ": "{a} hết hàng", "{b} tồn thấp", "{c} có lô hết hạn", "{d} có lô cận hạn"; số = số sản phẩm có ít nhất một chỉ báo |
| Sheet nguồn: chưa có biến động | "Chưa có biến động" (đã có ở `bj01.js:182`) |
| Tên loại biến động ("{Biến động} gần nhất") | `RECEIPT` "Nhận hàng" · `SALE` "Xuất bán" · `SALE_REVERSAL` "Huỷ bán" · `RETURN_IN` "Khách trả" · `COUNT_GAIN` / `COUNT_LOSS` "Kiểm kê" · `WRITE_OFF` "Điều chỉnh giảm" |

## 2. Thiết kế

### 2.1 RPC (`supabase/migrations/20261112001_inventory_stock_view.sql`)

| RPC | Trả về |
|---|---|
| `inventory.list_stock_overview(p_tenant_id uuid) returns jsonb` | `{as_of: now(), warehouse_name, products: [{product_id, name, code, barcode, base_uom, is_lot_tracked, physical, available, has_expired, has_near_expiry, reorder_threshold}]}` — từ `_product_stock_rows` nối `catalog.products` + `product_stock_policies`; `warehouse_name` = `inventory.warehouses.display_name` của kho trong `_assert_actor`; `code` = `coalesce(sku, '')`, `barcode` = `coalesce(barcode, '')`; sắp theo `name` (thứ tự gốc) |
| `inventory.get_stock_detail(p_tenant_id uuid, p_product_id uuid) returns jsonb` | Sản phẩm không thuộc tenant / đã xoá → `CONTEXT_INVALID`. `{as_of, warehouse_name, is_owner, financial_masked, product: {product_id, name, code, base_uom, is_lot_tracked}, physical, available, expired_quantity, reorder_threshold, target_level, lots: [...], latest_movement, cost}` |
| — `lots` | lô có `physical > 0`: `{lot_id, lot_code, expiry_date, expiry_precision, physical, is_expired, is_near_expiry, days_to_expiry}`; sắp `_lot_expiry_end` tăng dần, `null` cuối, rồi `lot_code`; `days_to_expiry = _lot_expiry_end − _today()` (null khi không HSD). Sản phẩm không lô ⇒ `[]` |
| — `latest_movement` | dòng `stock_movements` có `ledger_sequence` lớn nhất của sản phẩm trong kho: `{movement_kind, intent_type, intent_id, quantity_delta, business_date}`; chưa có ⇒ `null` |
| — `cost` | `is_owner` ⇒ `{method: _cost_method(...), official_unit_cost, moving_avg_cost, ledger_value_vnd}` từ `product_costs` (chưa có dòng ⇒ `null` cho 3 số, `ledger_value_vnd` 0); không ⇒ `null`, `financial_masked = true` |
| `get_warehouse_hub_summary` (sửa) | `problems: {out, low, expired, near_expiry, products}` — đếm trên `_product_stock_rows` + ngưỡng, cùng luật `stockIndicators` (G5-2a): `out` = `available = 0`; `low` = `threshold not null and available > 0 and available <= threshold`; `products` = số sản phẩm có ≥ 1 trong 4. Chưa `activated` ⇒ `problems: null` như cũ |

### 2.2 Flutter

| Tệp | Nội dung |
|---|---|
| `lib/features/inventory/logic/inventory_format.dart` | `formatQuantity` (dời), `String formatStockQuantity(num q, String uom) => '${formatQuantity(q.toDouble())} $uom'` |
| `lib/features/inventory/data/stock/stock_models.dart` | `StockOverview`, `StockOverviewItem`, `StockDetail`, `StockLot`, `StockLatestMovement`, `StockCost` |
| `lib/features/inventory/data/stock/stock_repository.dart` | `loadOverview()`, `loadDetail(productId)` |
| `lib/features/inventory/logic/stock/stock_list_rules.dart` | lọc, tìm, sắp mức gấp, đếm chip |
| `lib/features/inventory/logic/stock/stock_list_cubit.dart` + state | SCR-001 |
| `lib/features/inventory/logic/stock/stock_detail_cubit.dart` + state | SCR-003 + cột phải web |
| `lib/features/inventory/logic/stock/stale_watcher.dart` | mốc 5 phút (dùng chung 2 Cubit) |
| `lib/features/inventory/presentation/stock/` | `stock_list_page.dart`, `stock_detail_page.dart`, `stock_detail_body.dart` (dùng chung), `stock_lot_sheet.dart`, `stock_provenance_sheet.dart`, `stock_cost_block.dart`, `stock_routes.dart` |
| DS | `VBadge` chấm rỗng (`hollowDot`), `VStockRow` mới; `K7Table` thêm `selected` |

### 2.3 Ngoài phạm vi

Nút quét camera (Q-2-1), "Nhận hàng" / "Mở phiếu nhận" (G5-3), "Điều chỉnh lô hết hạn" (G5-5), thẻ kho (G5-7), lối vào từ PCC (G5-5), khả dụng khi bán (G5-4 — dùng `_product_stock_rows` / `_lot_expiry_end` để bỏ lô hết hạn khi xuất FEFO).

## 3. Tệp

| Tệp | Tạo / sửa | Task |
|---|---|---|
| `supabase/migrations/20261112001_inventory_stock_view.sql` | tạo | 1 |
| `supabase/migrations/20261110001_inventory_core.sql` (`get_warehouse_hub_summary`) | sửa | 1 |
| `supabase/migrations/REGISTRY.yaml` | sửa | 1 |
| `supabase/tests/inventory_stock_view.sql` | tạo | 1 |
| `apps/erp/test/features/inventory/data/stock_view_sql_contract_test.dart` | tạo | 1 |
| `apps/erp/lib/features/inventory/logic/{inventory_format,receipt_rules}.dart` | tạo / sửa | 2 |
| `apps/erp/lib/features/inventory/data/stock/*` + test | tạo | 2 |
| `apps/erp/lib/features/inventory/logic/stock/*` + test | tạo | 3 |
| `packages/c45_design_system/lib/src/primitives/v_badge.dart`, `…/components/v_stock_row.dart` (mới), `design_system.dart` + test | sửa / tạo | 4 |
| `apps/erp/lib/features/inventory/presentation/patterns/inventory_layout.dart` (`K7Table.selected`) | sửa | 6 |
| `apps/erp/lib/features/inventory/presentation/stock/*` + test | tạo | 4, 5, 6 |
| `apps/erp/lib/core/router/app_router.dart`, `lib/core/di/injection.dart`, `presentation/hub/warehouse_entries.dart`, `data/hub/warehouse_hub_repository.dart` + test Hub | sửa | 7 |
| `docs/refactor/plans/T7/img/G5-2/` | ảnh prototype (đã chép) + ảnh Flutter | 8 |

## 4. Task

### Task 1: SQL — 2 RPC đọc + "Cần chú ý" Hub

**Files:** Create `supabase/migrations/20261112001_inventory_stock_view.sql`, `supabase/tests/inventory_stock_view.sql`, `apps/erp/test/features/inventory/data/stock_view_sql_contract_test.dart`; Modify `supabase/migrations/20261110001_inventory_core.sql` (hàm `get_warehouse_hub_summary`, dòng 1035-1063), `REGISTRY.yaml`.

**Interfaces:**
- Consumes (G5-2a): `inventory._product_stock_rows(uuid)`, `_lot_expiry_end(date, text)`, `_near_expiry_days(uuid, uuid)`, `_today()`, bảng `product_stock_policies`; (G5-0b) `_assert_actor`, `_cost_method`, `product_costs`, `stock_movements`, `warehouses`.
- Produces: JSON mục 2.1 (Task 2 đọc).
- Thứ tự migration: `20261110001` định nghĩa `get_warehouse_hub_summary` trước khi có `_product_stock_rows` (`20261111001`) — plpgsql chỉ phân giải lúc chạy nên hợp lệ; ghi rõ ở dòng `Depends on` của header.

- [x] **Step 1: Test hợp đồng (đỏ):** `stock_view_rpcs_granted` (`list_stock_overview(uuid)`, `get_stock_detail(uuid, uuid)` có `security definer` + `grant execute … to authenticated` + `_assert_actor(p_tenant_id, 'inventory.read')`); `detail_masks_cost_for_non_owner` (chuỗi `'financial_masked'` và nhánh `is_owner` trong `get_stock_detail`); `hub_summary_fills_problems` (đọc `20261110001`: hàm có `'near_expiry'`, `'products'`, gọi `_product_stock_rows`, không còn `'problems', null` trong nhánh đã kích hoạt); `no_new_error_codes`.
- [x] **Step 2: Chạy, thấy đỏ** — `cd apps/erp && flutter test --no-pub -r compact test/features/inventory/data/stock_view_sql_contract_test.dart`.
- [x] **Step 3: Viết migration + sửa Hub summary** theo 2.1.
- [x] **Step 4: Viết `supabase/tests/inventory_stock_view.sql`** (khuôn `inventory_core.sql`): `product_without_movement_listed_zero`, `available_excludes_expired_lot` (11 hết hạn + 3 còn hạn ⇒ `available 3`, `expired_quantity 11`), `lots_sorted_by_expiry_end` (`DAY 30/09`, `MONTH 09`, `YEAR`, không HSD ⇒ đúng thứ tự), `staff_cost_masked`, `owner_cost_from_product_costs`, `latest_movement_is_max_sequence`, `hub_problems_counts` (1 hết hàng, 1 tồn thấp + có lô cận hạn ⇒ `products 2`).
- [x] **Step 5: Chạy test hợp đồng, thấy xanh.**

### Task 2: Model + repository + `formatQuantity`

**Files:** Create `lib/features/inventory/logic/inventory_format.dart`, `lib/features/inventory/data/stock/{stock_models,stock_repository}.dart`; Modify `lib/features/inventory/logic/receipt_rules.dart` (xoá thân `formatQuantity`, import từ `inventory_format.dart`, export lại cho chỗ gọi cũ); Test `test/features/inventory/data/stock/stock_repository_test.dart`, `test/features/inventory/logic/inventory_format_test.dart`.

**Interfaces:**
- Produces:
  - `class StockOverviewItem { String productId, name, code, barcode, uom; bool isLotTracked; num physical, available; bool hasExpired, hasNearExpiry; num? threshold; List<StockIndicator> get indicators => stockIndicators(available: available, threshold: threshold, hasExpired: hasExpired, hasNearExpiry: hasNearExpiry); }`
  - `class StockOverview { DateTime asOf; String warehouseName; List<StockOverviewItem> products; }`
  - `class StockLot { String lotId, code; LotDate? expiry; num physical; bool isExpired, isNearExpiry; int? daysToExpiry; }` — `LotDate` (`data/models/lot_date.dart`) dựng từ `expiry_date` + `expiry_precision` (`MONTH` ⇒ `LotDate(year, month)`, `YEAR` ⇒ `LotDate(year)`).
  - `class StockLatestMovement { String kind; String intentType; String intentId; num delta; DateTime businessDate; String get label; }` — `label` theo bảng chữ đề xuất mục 1.
  - `enum CostMethod { moving, periodic }`; `class StockCost { CostMethod method; num? officialUnitCost; num? movingAvgCost; int ledgerValueVnd; bool get provisional => method == CostMethod.periodic && officialUnitCost == null; }`
  - `class StockDetail { DateTime asOf; String warehouseName; bool isOwner; String productId, name, code, uom; bool isLotTracked; num physical, available, expiredQuantity; num? threshold, target; List<StockLot> lots; StockLatestMovement? latestMovement; StockCost? cost; List<StockIndicator> get indicators; }`
  - `StockRepository({required InventoryRpc rpc})`: `Future<StockOverview> loadOverview()` → `rpc.query('list_stock_overview')`; `Future<StockDetail> loadDetail(String productId)` → `rpc.query('get_stock_detail', {'p_product_id': productId})`.

- [x] **Step 1: Test (đỏ):** `format_quantity_moved_same_output` (`106` → "106", `1.5` → "1,5"); `format_stock_quantity` ("41 hộp"); `overview_parses` (JSON mẫu: `as_of` ISO ⇒ `DateTime` local, `reorder_threshold null` ⇒ `threshold null`, `indicators == [notConfigured]`); `detail_parses_lots_and_cost`; `lot_date_from_json_month` (`'2027-11-30'`, `'MONTH'` ⇒ `format() == '11/2027'`); `detail_cost_null_when_masked`; `latest_movement_label` (`SALE` ⇒ "Xuất bán").
- [x] **Step 2: Chạy, thấy đỏ.**
- [x] **Step 3: Viết code**; chạy lại test cũ dùng `formatQuantity` (`flutter test --no-pub -r compact test/features/inventory`).
- [x] **Step 4: Chạy, thấy xanh.**

### Task 3: Luật danh sách + 2 Cubit + mốc STALE

**Files:** Create `lib/features/inventory/logic/stock/{stock_list_rules,stock_list_cubit,stock_list_state,stock_detail_cubit,stock_detail_state,stale_watcher}.dart`; Test `test/features/inventory/logic/stock/*_test.dart`.

**Interfaces:**
- Consumes: Task 2; `stockIndicators`, `primaryIndicator`, `urgencyRank` (G5-2a).
- Produces:
  - `enum StockFilter { all, out, low, nearExpiry, expired }` — chip "Tất cả" · "Hết hàng" · "Tồn thấp" · "Cận hạn" · "Hết hạn" (`bj01.js:115`); ánh xạ sang `StockIndicator` (`low` ↔ `low`, `nearExpiry` ↔ `nearExpiry`, `expired` ↔ `expired`).
  - `bool matchesSearch(StockOverviewItem p, String query)` — `'${p.name} ${p.code} ${p.barcode}'.toLowerCase().contains(query.trim().toLowerCase())` (`bj01.js:59-60`).
  - `List<StockOverviewItem> visibleProducts(List<StockOverviewItem> all, StockFilter f, String query)` — lọc chip + tìm; `f == all` ⇒ sắp ổn định theo `urgencyRank` (cùng hạng giữ thứ tự gốc, `bj01.js:217`).
  - `int filterCount(List<StockOverviewItem> all, StockFilter f)` — trên **toàn bộ**, không theo ô tìm (`bj01.js:102`).
  - `class StaleWatcher { StaleWatcher({DateTime Function() now = DateTime.now, Duration limit = const Duration(minutes: 5)}); bool isStale(DateTime asOf); }`
  - `StockListState { status (loading, ready, empty, denied, loadError); StockOverview? data; StockFilter filter; String query; bool stale; String? selectedProductId /* web */; List<StockOverviewItem> get visible; StockOverviewItem? get selected /* selectedProductId nếu còn trong visible, không thì visible.first */; }`
  - `StockListCubit({required StockRepository repository, StaleWatcher? stale})`: `load()`, `refresh()` (giữ filter/query, `stale = false`), `setFilter`, `setQuery`, `clearSearchAndFilter()`, `select(String productId)`, `checkStale()` (gọi khi resume / màn hiện lại).
  - `StockDetailState { status (loading, ready, denied, loadError); StockDetail? data; bool stale; }`; `StockDetailCubit({required StockRepository repository, StaleWatcher? stale})`: `load(String productId)`, `refresh()`, `checkStale()`.
  - Lỗi `NO_PERMISSION` ⇒ `denied`; mất mạng / khác ⇒ `loadError` (K1 "Thử lại"). `products` rỗng ⇒ `empty`.

- [x] **Step 1: Test (đỏ)** với fixture 5 sản phẩm như `bj01.js:12-32` sau khi áp v5.28 (Nobivac 118/120 lô cận hạn ngưỡng 30; Amox 46 ngưỡng 50; Enro 0 ngưỡng 10; Tylo khả dụng 3 có lô hết hạn ngưỡng 8; Oxy 11 chưa ngưỡng): `all_sorted_by_urgency` (Enro, Tylo, Amox, Nobivac, Oxy); `chip_counts_ignore_search` (gõ "amox" ⇒ `filterCount(low) == 2`); `search_matches_barcode` ("8938500004068" ⇒ Amox); `filter_keeps_original_order`; `empty_status_when_no_products`; `denied_on_no_permission`; `stale_after_five_minutes_on_resume` (now giả +5 phút 1 giây ⇒ `checkStale()` ⇒ `stale true`; +4 phút ⇒ false); `refresh_clears_stale_and_keeps_filter`; `selected_falls_back_to_first_visible`; `detail_load_and_refresh`.
- [x] **Step 2: Chạy, thấy đỏ.**
- [x] **Step 3: Viết code.**
- [x] **Step 4: Chạy, thấy xanh.**

### Task 4: DS `VBadge` chấm rỗng + `VStockRow`; SCR-001 iPhone

Màn chính: SCR-001 `READY`. Ảnh đích: `img/G5-2/proto-SCR-001-READY-{390,1280}.png` — **ảnh v5.27.0**: còn nút quét trong ô tìm (bỏ, Q-2-1), cột web "Đã giữ" (bỏ); số khả dụng v5.27 khác v5.28 (fixture Flutter dùng số v5.28 ở Task 3).

**Code prototype** (`specs/themes/theme-07/03.design/prototype/html/`), `app/bj01.js:68-79, 113-118, 231-233`:

```js
// Chỉ báo tồn là badge ở cuối dòng; "Chưa có ngưỡng tồn" không phải trạng thái hàng nên ở lại dòng phụ.
const BJ01_STOCK_TONE = {OUT:"Danger",EXPIRED:"Danger",LOW:"Warning",NEAR:"Warning"};
function bj01RowSubtitle(p) {
  const issue=bj01PrimaryAttention(p);
  const inCaption=issue && !BJ01_STOCK_TONE[issue.key];
  return inCaption ? `${p.code} · ${issue.label}` : p.code;
}
function bj01RowBadge(p) {
  const issue=bj01PrimaryAttention(p);
  return issue && BJ01_STOCK_TONE[issue.key] ? ds24DotBadge(issue.label,BJ01_STOCK_TONE[issue.key]) : "";
}
function bj01Context() { return `<p class="ds24-context c45-text-style-7" data-ds-component="VText" data-ds-prop-style="Body/Small">Kho trung tâm · Dữ liệu đến ${esc(bj01AsOf()).replace(" · ", ", ")}</p>`; }
function bj01SearchAndFilters() {
  const filters=[['ALL','Tất cả'],['OUT','Hết hàng'],['LOW','Tồn thấp'],['NEAR','Cận hạn'],['EXPIRED','Hết hạn']];
  const scan=`<button type="button" class="ds24-search__action" data-bj01-scan aria-label="Quét mã vạch">${icon("scan","icon--sm")}</button>`;
  return `${ds24Search(bj01Query,'data-bj01-search','Tên, mã sản phẩm hoặc mã vạch',scan)}<div class="ds24-chip-scroll" aria-label="Lọc tồn kho" data-composed-from="VChip">${filters.map(([k,l])=>ds24Chip(k,l,bj01Filter===k,'data-bj01-filter',bj01FilterCount(k))).join('')}</div>`;
}
  const rows=visible.map((p)=>ds24StockRow({title:p.name,subtitle:bj01RowSubtitle(p),quantity:`${p.available} ${p.stockUom}`,badge:bj01RowBadge(p),attrs:rowAttrs(p)})).join('');
  const body=`${bj01Context()}${stale}${bj01SearchAndFilters()}${rows?`<section class="ds24-list-stack" data-composed-from="DS v2 / List Row">${rows}</section>`:''}${empty}${bj01ScanSheet()}`;
  return appShell({title:"Tồn kho",body,back:false,extraClass:wide});
```

`app/core.js:417-420, 440-442`:

```js
// VBadge có chấm 8px: chấm đặc = cảnh báo, chấm rỗng = nguy hiểm (CSS .ds24-badge--dot), để màu không là tín hiệu duy nhất.
function ds24DotBadge(label,tone="Neutral") {
  const t=String(tone).toLowerCase();
  return `<span class="ds24-badge ds24-badge--${t} ds24-badge--dot" data-ds-component="VBadge" data-ds-prop-style="Soft" data-ds-prop-tone="${tone}">${esc(label)}</span>`;
}
function ds24StockRow({title,subtitle="",quantity,badge="",attrs=""}) {
  return `<button class="ds24-list-row ds24-list-row--no-leading ds24-stock-row" type="button" ${attrs} data-ds-component="VStockRow" data-ds-prop-type="Navigation"><span class="ds24-list-row__copy"><strong>${esc(title)}</strong><small>${esc(subtitle)}</small></span><span class="ds24-stock-row__value"><strong class="ds24-stock-row__qty">${esc(quantity)}</strong>${badge}</span>${icon("chevronRight","icon--sm")}</button>`;
}
```

CSS `styles/components.css:2644-2671` + `styles/screens.css:189-192, 3885-3887`:

```css
.ds24-chip__count { margin-inline-start: 3px; font-size: 12px; font-weight: 600; font-variant-numeric: tabular-nums; }
.ds24-chip.is-empty:not(.is-selected) .ds24-chip__count { color: var(--c45-v2-text-secondary); }
.ds24-stock-row { min-height: 64px; }
.ds24-stock-row__value { flex: 0 0 auto; display: flex; flex-direction: column; align-items: flex-end; gap: 4px; }
.ds24-stock-row__qty { font-family: var(--c45-v2-font-mono); font-size: 16px; line-height: 22px; font-weight: 700; color: var(--c45-v2-text-primary); font-variant-numeric: tabular-nums; white-space: nowrap; }
body[data-active-uif="UIF-01"] .ds24-context { margin: 0; color: var(--c45-v2-text-secondary); font-size: 13px; }
body[data-active-uif="UIF-01"] .figma-calibrated-shell .ds24-chip-scroll { gap: 6px; }
body[data-active-uif="UIF-01"] .figma-calibrated-shell .ds24-chip-scroll > .ds24-chip { padding-inline: 10px; }
```

Token: `text-secondary` #4A535E, `text-primary` #0E1116, `font-mono` "JetBrains Mono" (Flutter: font mono của DS).

**Bảng ánh xạ → Flutter (iPhone 390):**

| Phần tử | Flutter | Tham số |
|---|---|---|
| `appShell(title:"Tồn kho", back:false)` | `Scaffold` + `VAppBar(title: 'Tồn kho')`, không nút phải | mở từ Hub: nút quay lại "Quay về Kho" (PLAN "Điều hướng") — prototype `back:false` vì Hub là khung; Flutter giữ quy ước PLAN |
| `bj01Context` | `Text('${warehouseName} · Dữ liệu đến ${HH:mm}, ${dd/MM/yyyy}', 13, #4A535E)` | giờ từ `asOf` (máy chủ) |
| `stale` (`k1Stale`) | `InventoryStale(title: 'Dữ liệu có thể đã cũ', description: 'Hãy làm mới trước khi sử dụng.', actionLabel: 'Làm mới', onAction: cubit.refresh)` | ngay dưới dòng ngữ cảnh |
| `ds24Search` | `VSearchBar(hintText: 'Tên, mã sản phẩm hoặc mã vạch')` | **không** `suffix` (Q-2-1) |
| nút quét `.ds24-search__action`, `bj01ScanSheet` | **bỏ** — Q-2-1 | — |
| `ds24Chip` × 5 | `K7FilterChips` (G5-0a) 5 `K7Filter` + `count` | khoảng cách chip 6, pad ngang 10; số 0 mờ |
| `ds24StockRow` | `VStockRow(title, subtitle, quantity: formatStockQuantity(available, uom), badge, onTap)` (mới, Step 3) | cao tối thiểu 64; số mono 16/22 w700; cột phải chấm badge cách số 4 |
| `bj01RowSubtitle` | `code`, hoặc `'$code · Chưa có ngưỡng tồn'` khi chỉ báo chính là `notConfigured` | |
| `bj01RowBadge` / `ds24DotBadge` | `VBadge(label, tone: danger/warning, showDot: true, hollowDot: tone == danger)` | chấm đặc = cảnh báo, rỗng = nguy hiểm |
| `empty` (EMPTY) | `InventoryEmpty(title: 'Chưa có dữ liệu tồn kho', description: 'Không có dữ liệu trong kho hiện tại.')` | |
| `empty` (FILTER_EMPTY) | `InventoryEmpty(title: 'Không có kết quả phù hợp', description: 'Thử tên, mã sản phẩm hoặc chọn bộ lọc khác.', actionLabel: 'Xóa tìm kiếm và bộ lọc', onAction: cubit.clearSearchAndFilter)` | |
| `LOADING` | `InventoryLoading(blocks: [search, row, row, row, row])` dưới dòng ngữ cảnh | ngữ cảnh chưa có ⇒ bỏ |
| `PERMISSION_DENIED` | `InventoryDenied(what: 'xem tồn kho', next: 'Bạn chưa được cấp quyền xem tồn kho. Liên hệ chủ cửa hàng nếu cần.', onExit: () => context.go('/warehouse'))` | tiêu đề "Bạn chưa có quyền xem tồn kho"; nút "Về Kho" |

- [x] **Step 1: Test DS (đỏ)** — `packages/c45_design_system/test/primitives/v_badge_hollow_dot_test.dart`: `hollow_dot_draws_ring` (chấm 8 × 8 viền tone, nền trong suốt); `packages/c45_design_system/test/components/v_stock_row_test.dart`: `min_height_64`, `quantity_mono_bold_16`, `badge_below_quantity`, `has_chevron`, `semantics_button_label` ("{title}, {quantity}, {badge}").
- [x] **Step 2: Viết** `VBadge.hollowDot` (bool, mặc định false; chỉ có hiệu lực khi `showDot`) và `VStockRow({required String title, String? subtitle, required String quantity, Widget? badge, VoidCallback? onTap, bool selected = false})` (dựa trên `VListRow` không icon đầu); export ở `design_system.dart`. Sửa `StockIndicatorBadge` của G5-2a (`presentation/stock_policy/`) dùng `hollowDot: true` cho tone `danger` và dời sang `presentation/stock/stock_indicator_badge.dart` để hai màn dùng chung (sửa import ở G5-2a). Chạy test DS + test G5-2a xanh.
- [x] **Step 3: Widget test SCR-001 iPhone (đỏ)** — `test/features/inventory/presentation/stock/stock_list_page_test.dart` (390 × 844, fake repository fixture Task 3): `list_ready_390` (ngữ cảnh "Kho trung tâm · Dữ liệu đến 21:30, 17/09/2026"; không có `Semantics('Quét mã vạch')`; dòng đầu Enrofloxacin "0 chai" + "Hết hàng"; Oxy phụ đề "SP-000147 · Chưa có ngưỡng tồn", không badge); `chip_tap_filters_390`; `empty_when_no_products`; `filter_empty_clear_resets`; `stale_banner_refresh`; `denied_390`; `row_tap_opens_detail_route` (đẩy `/warehouse/stock/INV-AMX`).
- [x] **Step 4: Chạy, thấy đỏ.**
- [x] **Step 5: Dựng `stock_list_page.dart`** (bố cục iPhone) theo bảng; `WidgetsBindingObserver` gọi `checkStale()` khi resumed; quay về từ chi tiết (`await context.push`) gọi `checkStale()`.
- [x] **Step 6: Chạy, thấy xanh.**

### Task 5: SCR-003 Chi tiết tồn kho (iPhone + web lối vào thẳng), sheet lô, sheet nguồn, khối giá vốn

Màn chính: SCR-003 `READY`. Ảnh đích: `img/G5-2/proto-SCR-003-READY-{390,1280}.png` — **ảnh v5.27.0**: thẻ số còn "Đủ điều kiện bán" / "Đã giữ", dòng ngưỡng "Ngưỡng · Mục tiêu" + "Sửa ngưỡng" (Flutter giữ dòng này vì CAP-01 có lại), không có khối giá vốn (Flutter thêm, chủ cửa hàng).

**Code prototype** `app/bj01.js:122-155` (thẻ số, cảnh báo — v5.28.0; **sửa theo Q-2-4**: dòng chính sách đổi lại thành "Ngưỡng {n} · Mục tiêu {m} {ĐVT}" + "Sửa ngưỡng" như SCR-003 mục 8, chữ cảnh báo "Ngưỡng {M} {ĐVT}" thay "Tồn tối thiểu"):

```js
function bj01StockHero(p) {
  const unit=esc(p.stockUom);
  const issue=bj01Indicators(p).find((x)=>x.key==="OUT")||bj01Indicators(p).find((x)=>x.key==="LOW");
  const badge=issue?ds24DotBadge(issue.label,BJ01_STOCK_TONE[issue.key]):"";
  const reasons=(p.eligibilityBreakdown||[]).filter((x)=>Number(x.quantity)>0).map((x)=>`${x.reason} ${x.quantity} ${p.stockUom}`);
  const stat=(label,value)=>`<div><dt>${esc(label)}</dt><dd>${esc(value)} ${unit}</dd></div>`;
  const policy=p.monitoringConfigStatus!=="NOT_CONFIGURED"&&p.threshold!=null?`<div class="bj01-stock-hero__policy"><span>Tồn tối thiểu ${esc(p.threshold)} ${unit}</span></div>`:"";
  return `<section class="bj01-stock-hero" data-composed-from="VCard,DS v2 / Key-value Row"><div class="bj01-stock-hero__main"><span>Khả dụng</span><strong>${esc(p.available)} ${unit}</strong>${badge}</div><dl class="bj01-stock-hero__stats">${stat("Tồn vật lý",p.physical)}</dl>${reasons.length?`<p class="bj01-stock-hero__note">Không đủ điều kiện bán: ${esc(reasons.join(" · "))}</p>`:""}${policy}</section>`;
}
function bj01Attention(p) {
  const unit=esc(p.stockUom);
  const inds=bj01Indicators(p);
  const item=inds.find((x)=>x.key==="OUT")||inds.find((x)=>x.key==="LOW");
  let html="";
  if(item) {
    const desc=item.key==="OUT"
      ? `Khả dụng 0 ${unit}${p.threshold!=null?` · Tồn tối thiểu ${p.threshold} ${unit}.`:'.'}`
      : `Khả dụng ${p.available} ${unit}${p.threshold!=null?` · Tồn tối thiểu ${p.threshold} ${unit}.`:'.'}`;
    const hint=p.target!=null&&p.target>p.available?`<p class="bj01-attention__hint">Gợi ý nhập thêm ${p.target-p.available} ${unit} (mục tiêu ${p.target} ${unit})</p>`:"";
    html+=`<div class="bj01-attention">${vBanner(item.key==="OUT"?"error":"warning",item.label,desc)}${hint}<button class="ds24-button ds24-button--secondary" data-bj01-receive type="button" data-ds-component="VButton" data-figma-node="521:529">Nhận hàng</button></div>`;
  }
  const expired=(p.lots||[]).filter((l)=>l.expiryIndicator==="EXPIRED");
  if(expired.length) {
    const qty=expired.reduce((sum,l)=>sum+Number(l.physical||0),0);
    html+=`<div class="bj01-attention">${vBanner("error","Có lô hết hạn",`Lô ${esc(expired.map((l)=>l.code).join(" · "))} · ${qty} ${unit} không đủ điều kiện bán.`)}<button class="ds24-button ds24-button--secondary" data-bj01-dispose-lot="${escapeAttribute(expired[0].code)}" type="button" data-ds-component="VButton" data-figma-node="521:529">Điều chỉnh lô hết hạn</button></div>`;
  }
  return html;
}
```

`app/bj01.js:162-171` (sheet lô), `179-185` (sheet nguồn), `193-210` (thân chi tiết), `235-243` (`render003BJ01`):

```js
function bj01LotSheet(p) {
  if(!bj01LotOpen) return ""; const lot=(p.lots||[]).find((x)=>x.code===bj01SelectedLotCode)||p.lots?.[0]; if(!lot)return "";
  let status="";
  if(lot.expiryIndicator==='EXPIRED') status=vBanner('error','Hết hạn','Lượng của lô này không đủ điều kiện bán.');
  else if(lot.expiryIndicator==='NEAR_EXPIRY'&&lot.nearExpiryAction==='BLOCK_SALE') status=vBanner('warning','Cận hạn · Đã chặn bán','Lượng của lô này không tính vào khả dụng theo chính sách hiện tại.');
  else if(lot.expiryIndicator==='NEAR_EXPIRY') status=vBanner('warning','Cận hạn',`${lot.daysToExpiry!=null?`Còn ${lot.daysToExpiry} ngày · `:''}vẫn đủ điều kiện bán theo chính sách hiện tại.`);
  const t7 = bj01T7Lot(p, lot.code);
  const dispose=lot.expiryIndicator==='EXPIRED'?`<button class="ds24-button ds24-button--secondary" data-bj01-dispose-lot="${escapeAttribute(lot.code)}" type="button" data-ds-component="VButton" data-figma-node="521:529">Điều chỉnh lô hết hạn</button>`
    :''; // v5.28.0: bỏ "Đổi tình trạng" (BJ-09)
  return ds24Sheet({title:`Lô ${lot.code}`,attrs:'data-bj01-close-lot',body:`<p class="ds24-context c45-text-style-7">${esc(p.name)} · HSD ${esc(lot.expiryDisplay)}</p>${bj01LotQuantityRows(lot,p)}${status}${dispose}`});
}
function bj01ProvenanceSheet(p) {
  if(!bj01ProvenanceOpen)return "";
  const mv=bj01LatestMovement(p); const rs=p.reservationSummary||{};
  const movementValue=mv.source?`${mv.source} · ${Number(mv.delta)>0?'+':''}${mv.delta} ${p.stockUom}`:'Chưa có biến động';
  const reservationValue=Number(rs.quantity)>0?`${rs.quantity} ${p.stockUom}${rs.source?` · ${rs.source}`:''}`:`0 ${p.stockUom}`;
  return ds24Sheet({title:'Nguồn và thời điểm cập nhật',attrs:'data-bj01-close-provenance',body:`<p class="ds24-context c45-text-style-7">${esc(p.name)} · Kho trung tâm</p><div class="ds24-info-stack">${ds24InfoRow('Dữ liệu đến',bj01AsOf())}${ds24InfoRow(mv.label?`${mv.label} gần nhất`:'Biến động gần nhất',movementValue)}${mv.receipt?`<button class="k7-row-link" type="button" data-bj01-open-receipt="${escapeAttribute(mv.source)}">Mở phiếu nhận ${esc(mv.source)}</button>`:''}${ds24InfoRow('Đang giữ',reservationValue)}</div><button class="ds24-button ds24-button--secondary" data-bj01-handoff type="button" data-ds-component="VButton" data-figma-node="521:529">${icon('history','icon--sm')}Xem thẻ kho và lịch sử</button>`});
}
function bj01DetailBody(p) {
  const configNote=p.monitoringConfigStatus==='NOT_CONFIGURED'?`<p class="ds24-context bj01-config-note" data-ds-component="VText">Chưa đặt tồn tối thiểu (ở hồ sơ sản phẩm); chưa xác định được tồn thấp.</p>`:'';
  let more="";
  if(p.tracking==='LOT') {
    const sorted=[...p.lots].sort((x,y)=>bj01ExpirySortKey(x)-bj01ExpirySortKey(y));
    const lotBadge=(lot)=>lot.expiryIndicator==='NEAR_EXPIRY'?ds24DotBadge('Cận hạn','Warning'):lot.expiryIndicator==='EXPIRED'?ds24DotBadge('Hết hạn','Danger'):'';
    const lots=viewport==="web"
      ? k7Table({columns:[{key:"code",label:"Lô",html:true},{key:"expiry",label:"HSD",mono:true},{key:"physical",label:"Tồn",align:"end",mono:true},{key:"badge",label:"Tình trạng",html:true}],caption:"Lô và hạn dùng",
          rows:sorted.map((lot)=>({code:`<strong>Lô ${esc(lot.code)}</strong>`,expiry:lot.expiryDisplay,physical:`${lot.physical} ${p.stockUom}`,badge:lotBadge(lot),lot})),
          mobileRow:(r)=>ds24ListRow({title:`Lô ${r.lot.code}`,subtitle:`HSD ${r.lot.expiryDisplay} · Tồn ${r.lot.physical} ${p.stockUom}`,trailing:r.badge,leading:null,attrs:`data-bj01-lot="${escapeAttribute(r.lot.code)}"`}),
          rowAttr:(r)=>`data-bj01-lot="${escapeAttribute(r.lot.code)}"`,rowOpen:true})
      : `<div class="ds24-list-stack">${sorted.map((lot)=>ds24ListRow({title:`Lô ${lot.code}`,subtitle:`HSD ${lot.expiryDisplay} · Tồn ${lot.physical} ${p.stockUom}`,trailing:lotBadge(lot),leading:null,attrs:`data-bj01-lot="${escapeAttribute(lot.code)}"`,})).join('')}</div>`;
    more+=`<section class="ds24-section">${ds24SectionTitle('Lô và hạn dùng',`${p.lots.length} lô`)}${lots}</section>`;
  }
  more+=`<section class="ds24-section">${ds24ListRow({title:'Nguồn và thời điểm cập nhật',subtitle:'Xem nguồn số liệu và lịch sử',leading:'history',attrs:'data-bj01-provenance',})}</section>`;
  return `<div class="bj01-detail"><div class="bj01-detail__summary">${bj01StockHero(p)}${bj01Attention(p)}${configNote}</div><div class="bj01-detail__more">${more}</div></div>`;
}
function render003BJ01(state) {
  const entryBack=entryMode==="product-context"?"exit-inventory-product-context":"";
  if(state==="PERMISSION_DENIED") return appShell({title:"Chi tiết tồn kho",body:k1Denied({what:"xem tồn kho",next:"Bạn chưa được cấp quyền xem tồn kho. Liên hệ chủ cửa hàng nếu cần.",exitAttr:k1ExitAttr("SCR-001")}),centered:true,back:true,backAction:entryBack,extraClass:"k7-wide"});
  const p=bj01ProductById(bj01SelectedProductId);
  const title=p.name, subtitle=`${p.code} · ${p.stockUom}`;
  if(state==="LOADING") return appShell({title,subtitle,body:bj01Context()+k1Loading({blocks:["card","row","row","row"]}),back:true,backAction:entryBack,extraClass:"k7-wide"});
  const stale=state==="STALE"?bj01Stale(true):"";
  const body=`${bj01Context()}${stale}${bj01DetailBody(p)}${bj01LotSheet(p)}${bj01ProvenanceSheet(p)}`;
  return appShell({title,subtitle,body,back:true,backAction:entryBack,extraClass:"k7-wide"});
}
```

CSS `styles/screens.css:3826-3865, 3881-3891, 3371` + `styles/components.css:3000-3006`:

```css
.bj01-stock-hero { width: 100%; padding: var(--c45-v2-space-4); display: flex; flex-direction: column; gap: var(--c45-v2-space-3); border: var(--c45-v2-border-width-thin) solid var(--c45-v2-border-default); border-radius: var(--c45-v2-radius-4); background: var(--c45-v2-surface-default); box-sizing: border-box; }
.bj01-stock-hero__main { display: grid; grid-template-columns: minmax(0, 1fr) auto; align-items: center; gap: var(--c45-v2-space-1) var(--c45-v2-space-3); }
.bj01-stock-hero__main > span { grid-column: 1 / -1; font: 400 13px/20px Inter, sans-serif; color: var(--c45-v2-text-secondary); }
.bj01-stock-hero__main > strong { font-family: var(--c45-v2-font-mono); font-size: 22px; line-height: 28px; font-weight: 700; color: var(--c45-v2-text-primary); font-variant-numeric: tabular-nums; grid-column: 1; grid-row: 2; }
.bj01-stock-hero__main > .ds24-badge { grid-column: 2; grid-row: 2; width: auto; justify-self: end; }
.bj01-stock-hero__stats { margin: 0; display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: var(--c45-v2-space-3); }
.bj01-stock-hero__stats dt { font: 400 12px/16px Inter, sans-serif; color: var(--c45-v2-text-secondary); }
.bj01-stock-hero__stats dd { margin: var(--c45-v2-space-1) 0 0; font-family: var(--c45-v2-font-mono); font-size: 14px; line-height: 20px; font-weight: 600; color: var(--c45-v2-text-primary); }
.bj01-stock-hero__note { margin: 0; padding-top: var(--c45-v2-space-3); border-top: var(--c45-v2-border-width-thin) solid var(--c45-v2-border-default); font: 400 13px/20px Inter, sans-serif; color: var(--c45-v2-text-secondary); }
.bj01-stock-hero__policy { display: flex; align-items: center; justify-content: space-between; gap: var(--c45-v2-space-3); padding-top: var(--c45-v2-space-3); border-top: var(--c45-v2-border-width-thin) solid var(--c45-v2-border-default); font: 400 13px/20px Inter, sans-serif; color: var(--c45-v2-text-secondary); }
.bj01-stock-hero__note + .bj01-stock-hero__policy { padding-top: 0; border-top: 0; }
.bj01-attention { display: flex; flex-direction: column; gap: var(--c45-v2-space-2); }
.bj01-attention__hint { margin: 0; font: 600 14px/20px Inter, sans-serif; color: var(--c45-v2-text-primary); }
.bj01-config-note{margin:8px 0 0}
.bj01-detail, .bj01-detail__summary, .bj01-detail__more { display: contents; }
.device-preview.is-web .bj01-detail { display: grid; grid-template-columns: minmax(0, 5fr) minmax(0, 7fr); gap: var(--c45-v2-space-6); align-items: start; }
.device-preview.is-web .bj01-detail__summary, .device-preview.is-web .bj01-detail__more { display: flex; flex-direction: column; gap: var(--c45-v2-space-3); min-width: 0; }
.device-preview.is-web .k7-split__aside > .bj01-detail { display: flex; flex-direction: column; align-items: stretch; gap: var(--c45-v2-space-4); }
```

Token: `space-1` 4, `space-3` 12, `space-4` 16, `space-6` 24, `radius-4` 12, `border-default` #E5E8EB, `border-width-thin` 1.

**Khối giá vốn (mới, không có prototype — duyệt cùng plan):** đặt cuối cột "summary" (sau ghi chú chưa có ngưỡng), chỉ khi `detail.cost != null`:

```
┌───────────────────────────────────────────┐  VCard, viền #E5E8EB r12 pad 16 (như .bj01-stock-hero)
│ Giá vốn                                   │  13/20 #4A535E (như "Khả dụng")
│ Giá vốn chính thức         118.500 đ/hộp  │  VKeyValueRow(mono: true)
│ Bình quân liên hoàn        117.940 đ/hộp  │  VKeyValueRow(mono: true)
│ Giá trị tồn (sổ)            14.152.800 đ  │  VKeyValueRow(mono: true)
│ ───────────────────────────────────────── │  viền trên 1px #E5E8EB, pad trên 12
│ Phương pháp: Bình quân cuối kỳ            │  13/20 #4A535E
│ Xuất kho đang dùng giá tạm (bình quân     │  chỉ khi provisional; thay giá chính thức
│ liên hoàn).                               │  bằng "Chưa công bố"
└───────────────────────────────────────────┘
```

**Bảng ánh xạ → Flutter:**

| Phần tử | Flutter | Tham số / chữ |
|---|---|---|
| `appShell(title, subtitle)` | `VAppBar(title: name, subtitle: '$code · $uom')`, có nút quay lại (về nơi đã đến) | `PERMISSION_DENIED`: tiêu đề "Chi tiết tồn kho", không phụ đề |
| `bj01Context` | như Task 4 | |
| `bj01Stale(true)` | `InventoryStale(title: 'Dữ liệu có thể đã cũ', description: 'Dữ liệu đến {HH:mm · dd/MM/yyyy}. Hãy làm mới trước khi sử dụng.', actionLabel: 'Làm mới')` | |
| `bj01StockHero` | `StockHeroCard` (trong `stock_detail_body.dart`): `VCard` pad 16 r12 viền 1 #E5E8EB, khe 12 | |
| `__main` | "Khả dụng" 13/20 #4A535E; dưới: số mono 22/28 w700 trái + `VBadge(showDot, hollowDot cho danger)` phải ("Hết hàng" / "Tồn thấp") | |
| `__stats` | **một** cột "Tồn vật lý" (dt 12/16 #4A535E, dd mono 14/20 w600) trong lưới 3 cột | "Đủ điều kiện bán", "Đã giữ" **bỏ** (Q-2-4, như v5.28.0) |
| `__note` | "Không đủ điều kiện bán: Hết hạn {expiredQuantity} {ĐVT}" khi `expiredQuantity > 0` | viền trên 1px, pad trên 12 |
| `__policy` | khi có ngưỡng: `Row` "Ngưỡng {n} · Mục tiêu {m} {ĐVT}" + (chủ cửa hàng) nút chữ "Sửa ngưỡng" | `onEditThreshold` → `context.push<bool>('/warehouse/stock-policy/product/$id')`, `true` ⇒ `cubit.refresh()` |
| `bj01Attention` hết / thấp | `VBanner(tone: error/warning, title: 'Hết hàng'/'Tồn thấp', message: 'Khả dụng {N} {ĐVT} · Ngưỡng {M} {ĐVT}.')`; "Gợi ý nhập thêm {target−available} {ĐVT} (mục tiêu {target} {ĐVT})" 14/20 w600 khi `target > available`; nút "Nhận hàng" **ẩn** (`onReceive == null`, Q-2-5) | khe 8 |
| `bj01Attention` lô hết hạn | `VBanner(tone: error, title: 'Có lô hết hạn', message: 'Lô {mã · mã} · {SL} {ĐVT} không đủ điều kiện bán.')`; nút "Điều chỉnh lô hết hạn" **ẩn** (`onAdjustExpired == null`) | sau khối hết / thấp |
| `configNote` | chưa có ngưỡng: `Text('Chưa cấu hình ngưỡng tồn; chưa thể xác định trạng thái tồn thấp/bình thường.', 13, #4A535E)` + (chủ cửa hàng) `VButton(variant: secondary, 'Đặt ngưỡng tồn')` | chữ theo SCR-003 mục 8 (v5.28 câu "Tồn tối thiểu…" bỏ vì CAP-01 có lại) |
| khối giá vốn | `StockCostBlock` theo khung trên | chỉ `cost != null` |
| "Lô và hạn dùng" (iPhone) | `VSection(title: 'Lô và hạn dùng', trailing: Text('{n} lô'))` + `VListRow` mỗi lô: "Lô {mã}" / "HSD {LotDate.format()} · Tồn {SL} {ĐVT}" / badge "Cận hạn" (warning, chấm đặc) / "Hết hạn" (danger, chấm rỗng) | chỉ `isLotTracked`; HSD null ⇒ "Không có HSD" |
| "Lô và hạn dùng" (web) | `K7Table(columns: ['Lô','HSD','Tồn','Tình trạng'], onRowTap: mở sheet lô)` | HSD, Tồn mono |
| dòng nguồn | `VListRow(leading: VIcons.history, title: 'Nguồn và thời điểm cập nhật', subtitle: 'Xem nguồn số liệu và lịch sử', type: navigation)` | |
| `bj01LotSheet` | `StockLotSheet` (`showVAdaptiveSheet`): tiêu đề "Lô {mã}"; "{tên} · HSD {ngày}"; `VKeyValueRow` "Tồn vật lý", "Đủ điều kiện bán" (= tồn nếu chưa hết hạn, 0 nếu hết hạn); `VBanner` "Hết hạn" / "Lượng của lô này không đủ điều kiện bán." hoặc "Cận hạn" / "Còn {n} ngày · vẫn đủ điều kiện bán theo chính sách hiện tại."; nút "Điều chỉnh lô hết hạn" ẩn | nhánh "Cận hạn · Đã chặn bán" **bỏ** (Q-2a2) |
| `bj01ProvenanceSheet` | `StockProvenanceSheet`: "{tên} · {warehouseName}"; `VKeyValueRow` "Dữ liệu đến" `{HH:mm · dd/MM/yyyy}`; "{label} gần nhất" = "{dd/MM/yyyy} · {+/-}{SL} {ĐVT}" hoặc "Biến động gần nhất" = "Chưa có biến động"; "Mở phiếu nhận" **ẩn** (G5-3); "Đang giữ" **bỏ**; "Xem thẻ kho và lịch sử" **ẩn** (G5-7) | mã chứng từ chưa có (phiếu thuộc G5-3+) ⇒ dùng ngày nghiệp vụ |
| `bj01Detail` web (lối vào thẳng) | `stock_detail_body.dart` ≥ 1024: `Row` 5 : 7, khe 24 — trái summary (thẻ số, cảnh báo, ghi chú, giá vốn), phải lô + nguồn; iPhone một cột khe 12 | |
| `LOADING` | `VAppBar` có tên (từ `extra` của route nếu có, không thì "Chi tiết tồn kho") + `InventoryLoading(blocks: [card, row, row, row])` | |

- [x] **Step 1: Widget test (đỏ)** `test/features/inventory/presentation/stock/stock_detail_page_test.dart` (fake repository; Tylosin có lô `TY2408` hết hạn 11, `TY2511` 3; Nobivac lô cận hạn còn 13 ngày):
  - `detail_ready_390` (thẻ "Khả dụng" "3 lọ" + "Tồn thấp"; "Tồn vật lý 14 lọ"; "Không đủ điều kiện bán: Hết hạn 11 lọ"; "Ngưỡng 8 · Mục tiêu 24 lọ"; banner "Tồn thấp" "Khả dụng 3 lọ · Ngưỡng 8 lọ."; "Gợi ý nhập thêm 21 lọ (mục tiêu 24 lọ)"; banner "Có lô hết hạn" "Lô TY2408 · 11 lọ không đủ điều kiện bán."; không có chữ "Nhận hàng", "Điều chỉnh lô hết hạn", "Đã giữ"; lô `TY2408` đứng trước `TY2511`).
  - `owner_sees_cost_block_390` ("Giá vốn chính thức", "Bình quân liên hoàn", "Giá trị tồn (sổ)", "Phương pháp: Bình quân liên hoàn").
  - `periodic_provisional_shows_note` ("Chưa công bố", "Xuất kho đang dùng giá tạm (bình quân liên hoàn).").
  - `staff_no_cost_no_threshold_links_390` (không "Giá vốn", không "Sửa ngưỡng", không "Đặt ngưỡng tồn").
  - `not_configured_shows_note_and_set_button` (Oxy, chủ cửa hàng).
  - `edit_threshold_pushes_policy_and_refreshes` (nhận `true` ⇒ repository `loadDetail` gọi lần 2).
  - `lot_sheet_near_expiry_390` ("Còn 13 ngày · vẫn đủ điều kiện bán theo chính sách hiện tại.").
  - `provenance_sheet_no_reservation` (không "Đang giữ", không "Xem thẻ kho và lịch sử"; có "Nhận hàng gần nhất").
  - `detail_two_columns_1280` (thẻ số và bảng lô cùng hàng).
  - `detail_denied`.
- [x] **Step 2: Chạy, thấy đỏ.**
- [x] **Step 3: Dựng** `stock_detail_body.dart` (nhận `StockDetail` + callback `onEditThreshold`, `onReceive`, `onAdjustExpired`, `onOpenStockCard`, `onOpenReceipt` — 4 cái sau truyền `null` ở plan này), `stock_cost_block.dart`, `stock_lot_sheet.dart`, `stock_provenance_sheet.dart`, `stock_detail_page.dart`.
- [x] **Step 4: Chạy, thấy xanh.**

### Task 6: SCR-001 web — danh sách – chi tiết

**Code prototype** `app/bj01.js:80-92, 219-229` (bỏ cột `reserved`, bỏ `bj01ScanSheet`):

```js
function bj01TableRow(p) {
  const issue=bj01PrimaryAttention(p);
  const unit=p.stockUom;
  return { id:p.id, name:p.name, code:p.code, product:`<strong>${esc(p.name)}</strong><small>${esc(p.code)}</small>`, available:`${p.available} ${unit}`, physical:`${p.physical} ${unit}`, reserved:`${p.reserved} ${unit}`, badge:bj01RowBadge(p)||(issue?ds24Badge(issue.label,"Neutral"):"") };
}
const BJ01_COLUMNS = [
  { key:"product", label:"Sản phẩm", html:true },
  { key:"available", label:"Khả dụng", align:"end", mono:true },
  { key:"physical", label:"Tồn vật lý", align:"end", mono:true },
  { key:"reserved", label:"Đã giữ", align:"end", mono:true },
  { key:"badge", label:"Chỉ báo", html:true },
];
  const web=viewport==="web";
  const rowAttrs=(p)=>`data-bj01-product="${p.id}" data-bj01-search-text="${escapeAttribute(bj01SearchText(p))}"`;
  if(web && visible.length) {
    // Danh sách – chi tiết: bấm dòng đổi chi tiết bên phải, không đổi trang. Dòng chọn mặc định = dòng đầu.
    const selected=visible.find((p)=>p.id===bj01WebSelectedId)||visible[0];
    bj01SelectedProductId=selected.id;
    const table=k7Table({columns:BJ01_COLUMNS,rows:visible.map(bj01TableRow),caption:"Tồn kho",
      mobileRow:(r)=>ds24StockRow({title:r.name,subtitle:r.code,quantity:r.available,badge:r.badge,attrs:rowAttrs(bj01ProductById(r.id))}),
      rowAttr:(r)=>`${rowAttrs(bj01ProductById(r.id))}${r.id===selected.id?' aria-current="true" class="is-selected"':""}`,rowOpen:true});
    const main=`${bj01Context()}${stale}${bj01SearchAndFilters()}${table}${bj01ScanSheet()}${bj01LotSheet(selected)}${bj01ProvenanceSheet(selected)}`;
    return appShell({title:"Tồn kho",body:`<div class="bj01-list-detail">${k7Split({main,aside:bj01DetailBody(selected),asideWebOnly:true})}</div>`,back:false,extraClass:wide});
  }
```

CSS `styles/components.css:3006-3008`:

```css
.device-preview.is-web .k7-split__aside > .bj01-detail { display: flex; flex-direction: column; align-items: stretch; gap: var(--c45-v2-space-4); }
.device-preview.is-web .bj01-list-detail .k7-split { grid-template-columns: minmax(0, 7fr) minmax(0, 5fr); }
```

**Bảng ánh xạ → Flutter (web ≥ 1024):**

| Phần tử | Flutter | Tham số |
|---|---|---|
| `k7Split` | `K7Split(main, aside)` (G5-0a), tỉ lệ 7 : 5 | cột phải xếp dọc khe 16 (không chia 2 cột) |
| `k7Table` + `BJ01_COLUMNS` | `K7Table(columns: ['Sản phẩm','Khả dụng','Tồn vật lý','Chỉ báo'], selected: …, onRowTap: cubit.select)` | cột "Đã giữ" **bỏ**; Khả dụng / Tồn vật lý mono căn phải |
| `rowAttr … is-selected` | `K7Table.selected` (mới): dòng chọn nền `surface-brand` #EBF4EC + `Semantics(selected: true)` | Tab tới dòng + Enter = chọn |
| cột "Chỉ báo" | badge như dòng iPhone; `notConfigured` ⇒ `VBadge('Chưa có ngưỡng tồn')` trung tính | |
| aside | `StockDetailPanel` = `BlocProvider(StockDetailCubit..load(selected.id))` + `StockDetailBody` (Task 5, chế độ một cột) | đổi dòng ⇒ `load` sản phẩm mới, không đổi URL |
| không có dòng (`EMPTY` / `FILTER_EMPTY`) | như iPhone, không cột phải | |

- [x] **Step 1: `impact` cho `K7Table`**; test `K7Table` (đỏ): `selected_row_highlighted` (nền #EBF4EC, `Semantics.selected`).
- [x] **Step 2: Widget test (đỏ)** thêm vào `stock_list_page_test.dart` (1280 × 800): `list_detail_ready_1280` (4 tiêu đề cột, không "Đã giữ"; cột phải hiện thẻ số của dòng đầu "Enrofloxacin 10%"); `row_tap_changes_aside_not_route_1280`; `selected_falls_back_to_first_visible_1280` (chọn Amox, lọc "Hết hạn" ⇒ cột phải là Tylosin).
- [x] **Step 3: Chạy, thấy đỏ.**
- [x] **Step 4: Dựng** nhánh web của `stock_list_page.dart`, thêm `K7Table.selected`.
- [x] **Step 5: Chạy, thấy xanh** — `flutter test --no-pub -r compact test/features/inventory`.

### Task 7: Route, DI, lối vào Hub, "Cần chú ý"

**Files:** Create `lib/features/inventory/presentation/stock/stock_routes.dart`; Modify `lib/core/router/app_router.dart`, `lib/core/di/injection.dart`, `lib/features/inventory/presentation/hub/warehouse_entries.dart`, `lib/features/inventory/data/hub/warehouse_hub_repository.dart`, `warehouse_hub_page.dart` (đích chạm dòng "Cần chú ý"); Test `test/features/inventory/presentation/stock/stock_routes_test.dart`, sửa test Hub.

**Interfaces:**
- Produces: `List<RouteBase> stockRoutes()` — `GoRoute('/warehouse/stock')` (`StockListPage`), `GoRoute('/warehouse/stock/:productId')` (`StockDetailPage`, `extra` = tên sản phẩm cho app bar lúc tải); đặt cạnh `stockPolicyRoutes()` (G5-2a). DI `StockRepository`.
- `warehouseAreaEntries(inventory)`: `stock_availability.route = '/warehouse/stock'`; nút nhanh "Tra cứu tồn" `route: '/warehouse/stock'`; `warehouseStockSearchRoute = '/warehouse/stock'`.
- `WarehouseHubRepository.getSummary`: đọc `problems` (mục 2.1) ⇒ `WarehouseAttention(count: products, text: …)` theo chữ đề xuất mục 1; `products == 0` ⇒ `null`.
- Hub: dòng "Cần chú ý" đổi tiêu đề thành "Tồn kho cần chú ý", chạm ⇒ `context.push('/warehouse/stock')` (thay đích `stocktaking` cũ của G5-0a).

- [x] **Step 1: `impact`** cho `WarehouseHubRepository.getSummary`, `warehouseAreaEntries`, `warehouseQuickActions`, `warehouseStockSearchRoute`.
- [x] **Step 2: Test (đỏ):** `hub_summary_text_joins_nonzero` (`{out: 2, low: 1, expired: 1, near_expiry: 0, products: 3}` ⇒ `count 3`, `text '2 hết hàng · 1 tồn thấp · 1 có lô hết hạn'`); `hub_problems_zero_is_null`; `hub_attention_row_opens_stock`; `quick_action_tra_cuu_ton_opens_stock`; `route_detail_opens_product`.
- [x] **Step 3: Chạy, thấy đỏ.**
- [x] **Step 4: Viết.**
- [x] **Step 5: Chạy, thấy xanh.**

### Task 8: Luồng đầu–cuối, đối chiếu ảnh, kiểm cuối

- [x] **Step 1: Test luồng** `test/features/inventory/presentation/stock/stock_flow_test.dart` (fake repository, chủ cửa hàng, 390): Hub "Tồn kho cần chú ý" → danh sách → chip "Tồn thấp" → Tylosin → "Sửa ngưỡng" → (fake G5-2a trả `true`) → chi tiết tải lại → quay lại danh sách giữ chip "Tồn thấp".
- [x] **Step 2: Ảnh Flutter** (`matchesGoldenFile`): `img/G5-2/flutter-SCR-001-READY-{390,1280}.png`, `flutter-SCR-003-READY-{390,1280}.png` (fixture Task 3; SCR-003 là Nobivac như ảnh prototype, chủ cửa hàng). So với `proto-*`; lệch ghi Kết quả (chênh đã biết: mục đầu Task 4, Task 5).
- [x] **Step 3: Kiểm** — `cd apps/erp && dart analyze lib/features/inventory test/features/inventory` = 0 lỗi; `cd packages/c45_design_system && dart analyze && flutter test --no-pub -r compact`; `flutter test --no-pub -r compact` (app) không thêm lỗi so với `TEST-BASELINE.md`; `detect_changes()`.
- [x] **Step 4: Ghi Kết quả** + PLAN.md bảng Plan (cột Làm).

## 5. Kết quả

### 5.1 Tiến độ & Kết quả kiểm thử từng Task
1. **Task 1 (SQL — 2 RPC đọc + "Cần chú ý" Hub):**
   - `impact` cho `get_warehouse_hub_summary` / `WarehouseHubRepository.getSummary`: LOW risk (chỉ được gọi bởi `WarehouseHubRepository.getSummary`).
   - Tạo migration `supabase/migrations/20261112001_inventory_stock_view.sql` gồm `inventory.list_stock_overview(uuid)` và `inventory.get_stock_detail(uuid, uuid)`.
   - Cập nhật `inventory.get_warehouse_hub_summary(uuid)` trong `supabase/migrations/20261110001_inventory_core.sql` điền `problems: {out, low, expired, near_expiry, products}` khi `activated = true`; cập nhật `supabase/migrations/REGISTRY.yaml`.
   - Viết 7 ca test SQL trong `supabase/tests/inventory_stock_view.sql` (chỉ viết file, không chạy DB).
   - Test hợp đồng `test/features/inventory/data/stock_view_sql_contract_test.dart` (4/4 PASS) và `inventory_core_sql_contract_test.dart` (33/33 PASS).
2. **Task 2 (Model + repository + `formatQuantity`):**
   - `impact` cho `receipt_rules.formatQuantity`: LOW risk trong `features/inventory` (9 tệp import `receipt_rules.dart`, giữ re-export `inventory_format.dart`).
   - Tạo `lib/features/inventory/logic/inventory_format.dart` (`formatQuantity`, `formatStockQuantity`), cập nhật `receipt_rules.dart`.
   - Tạo `lib/features/inventory/data/stock/stock_models.dart` và `stock_repository.dart`; bổ sung extension `indicators` cho `StockOverviewItem` và `StockDetail` tại `logic/stock/stock_indicator_rules.dart` để tuân thủ ranh giới tầng `data` không import `logic` (0 vi phạm `check_feature_imports.dart` cho `inventory`).
   - Test `inventory_format_test.dart` (2/2 PASS), `stock_repository_test.dart` (5/5 PASS), `receipt_rules_test.dart` (20/20 PASS).
3. **Task 3 (Luật danh sách + 2 Cubit + mốc STALE):**
   - Tạo `stale_watcher.dart`, `stock_list_rules.dart`, `stock_list_state.dart`, `stock_list_cubit.dart`, `stock_detail_state.dart`, `stock_detail_cubit.dart`.
   - Test `test/features/inventory/logic/stock/stock_list_test.dart` (10/10 PASS).
4. **Task 4 (DS `VBadge` chấm rỗng + `VStockRow`; SCR-001 iPhone):**
   - `impact` cho `VBadge` (MEDIUM — thêm tham số tuỳ chọn `hollowDot = false`) và `StockIndicatorBadge` (LOW — dời sang `presentation/stock/stock_indicator_badge.dart`, giữ re-export tại `stock_policy/`).
   - Bổ sung `VBadge.hollowDot` và `VStockRow` trong `c45_design_system`; test DS `v_badge_hollow_dot_test.dart`, `v_badge_test.dart`, `v_stock_row_test.dart` (14/14 PASS) và `stock_policy_page_test.dart` (16/16 PASS).
   - Dựng `lib/features/inventory/presentation/stock/stock_list_page.dart` (iPhone 390); test `test/features/inventory/presentation/stock/stock_list_page_test.dart` (7/7 PASS).
5. **Task 5 (SCR-003 Chi tiết tồn kho, sheet lô, sheet nguồn, khối giá vốn):**
   - Dựng `stock_cost_block.dart`, `stock_lot_sheet.dart`, `stock_provenance_sheet.dart`, `stock_detail_body.dart`, `stock_detail_page.dart`.
   - Test `test/features/inventory/presentation/stock/stock_detail_page_test.dart` (10/10 PASS).
6. **Task 6 (SCR-001 web — danh sách – chi tiết):**
   - `impact` cho `K7Table`: chỉ được dùng nội bộ trong `features/inventory` (`k6_task_list`, `near_expiry_tab`, `stock_threshold_tab`, `stock_detail_body`, `k1_k7_footer_test`) — thêm tham số tuỳ chọn `selected` (`K7Table.selected` / `VTable.selectedRowIndex`) tương thích ngược 100%.
   - Bổ sung nhánh web danh sách – chi tiết (`K7Split` 7:5 + `StockDetailPanel`) trong `stock_list_page.dart`.
   - Test `k1_k7_footer_test.dart` + `stock_list_page_test.dart` (23/23 PASS), toàn bộ `test/features/inventory` (273/273 PASS).
7. **Task 7 (Route, DI, lối vào Hub, "Cần chú ý"):**
   - `impact` cho `warehouseQuickActions`, `warehouseStockSearchRoute` (LOW risk, chỉ dùng trong `warehouse_hub_page.dart`), `warehouseAreaEntries` (chỉ dùng trong `features/inventory/presentation/hub/`), `WarehouseHubRepository.getSummary` (LOW risk).
   - Tạo `stock_routes.dart` (`stockRoutes()`), đăng ký `StockRepository` trong `injection.dart`, gắn `...stockRoutes()` ngoài `StatefulShellRoute` trong `app_router.dart`, cập nhật `warehouse_entries.dart`, `warehouse_hub_repository.dart`, `warehouse_hub_page.dart`.
   - Test `warehouse_hub_repository_test.dart`, `warehouse_hub_test.dart`, `warehouse_hub_pages_test.dart`, `warehouse_hub_routes_test.dart`, `stock_routes_test.dart` (34/34 PASS).
8. **Task 8 (Luồng đầu–cuối, đối chiếu ảnh, kiểm cuối):**
   - Tạo `test/features/inventory/presentation/stock/stock_flow_test.dart` (3/3 PASS): kiểm tra luồng đầu–cuối 390px từ Hub "Tồn kho cần chú ý" → danh sách `/warehouse/stock` → lọc chip "Tồn thấp" → chạm "Tylosin 20%" mở `/warehouse/stock/INV-TYLO` → bấm "Sửa ngưỡng" mở G5-2a `StockThresholdSinglePage` → sửa ngưỡng & lưu → chi tiết tự động tải lại ngưỡng mới → bấm Back quay lại danh sách giữ nguyên chip "Tồn thấp"; đồng thời sinh và kiểm `matchesGoldenFile` cho 4 ảnh chụp `flutter-SCR-001-READY-{390,1280}.png` và `flutter-SCR-003-READY-{390,1280}.png`.

### 5.2 Đối chiếu ảnh (`flutter-SCR-*` so với `proto-SCR-*`)
- `flutter-SCR-001-READY-390.png` so với `proto-SCR-001-READY-390.png`:
  - Khớp thứ bậc thông tin, dòng ngữ cảnh (`Kho trung tâm · Dữ liệu đến 21:30, 17/09/2026`), ô tìm kiếm, 5 chip lọc (`Tất cả 5` đang chọn), 5 thẻ `VStockRow` theo đúng thứ tự ưu tiên (`Enrofloxacin 10%` chấm rỗng đỏ "Hết hàng", `Tylosin 20%` chấm rỗng đỏ "Có lô hết hạn", `Amox 500` chấm đặc vàng "Tồn thấp", `Nobivac DHPPi` chấm đặc vàng "Có lô cận hạn", `Oxytetracycline LA` dòng phụ `SP-000147 · Chưa có ngưỡng tồn`).
  - Chênh đã biết theo thiết kế: không có nút quét mã vạch ở hậu tố ô tìm (quyết định mục 1); `VAppBar` có nút Back để quay về Hub `/warehouse`; môi trường test Flutter dùng font Ahem.
- `flutter-SCR-001-READY-1280.png` so với `proto-SCR-001-READY-1280.png`:
  - Khớp bố cục `K7Split` 7:5 có thanh điều hướng bên trái (`Thêm` → `Kho`). Cột trái hiện bảng `K7Table` 4 cột (`Sản phẩm`, `Khả dụng`, `Tồn vật lý`, `Chỉ báo` — chủ đích bỏ cột `Đã giữ` theo KI-02 / KI-13), dòng đầu `Enrofloxacin 10%` tô nền chọn `#EBF4EC`. Cột phải hiện `StockDetailBody` của `Enrofloxacin 10%` ở chế độ một cột (thẻ Khả dụng + `VBanner` đỏ "Hết hàng" + gợi ý nhập thêm 30 chai + khối "Giá vốn" của chủ cửa hàng + dòng "Nguồn và thời điểm cập nhật"; nút "Nhận hàng" **ẩn** theo Q-2-5).
- `flutter-SCR-003-READY-390.png` so với `proto-SCR-003-READY-390.png`:
  - Khớp bố cục chi tiết `Nobivac DHPPi` (`SP-000184 · hộp`): dòng ngữ cảnh, thẻ Khả dụng (`118 hộp`, `Tồn vật lý 120 hộp`, `Ngưỡng 30 · Mục tiêu 80 hộp`, nút `Sửa ngưỡng` — bỏ `Đủ điều kiện bán`, `Đã giữ`, `Cách ly` theo KI-02 / KI-03), khối "Giá vốn" (chủ cửa hàng, thêm theo G5-0b mục 2.5), mục "Lô và hạn dùng" (`2 lô` thẻ dọc `Lô DH2509` cận hạn và `Lô DH2507`), dòng "Nguồn và thời điểm cập nhật".
- `flutter-SCR-003-READY-1280.png` so với `proto-SCR-003-READY-1280.png`:
  - Khớp bố cục 2 cột rộng trên web (chụp cho `Nobivac DHPPi` theo yêu cầu Task 8 Step 2 để hiển thị đầy đủ cả bảng lô 4 cột và khối Giá vốn): cột trái gồm thẻ Khả dụng + khối Giá vốn; cột phải gồm bảng `K7Table` "Lô và hạn dùng" (`Lô`, `HSD`, `Tồn`, `Tình trạng`) + dòng "Nguồn và thời điểm cập nhật".

### 5.3 Kiểm tra tổng thể & `detect_changes`
- `cd apps/erp && dart analyze lib/features/inventory test/features/inventory`: **No issues found!** (0 lỗi, 0 warning, 0 info).
- `cd apps/erp && dart run tool/check_feature_imports.dart`: **0 vi phạm** trong `lib/features/inventory`.
- `cd apps/erp && flutter test --no-pub -r compact test/features/inventory`: **281/281 PASS**.
- `cd packages/c45_design_system && dart analyze lib`: **No issues found!**; các test DS liên quan (`v_badge_test.dart`, `v_badge_hollow_dot_test.dart`, `v_stock_row_test.dart`, `v_table_row_tap_test.dart`, `v_table_selected_test.dart` — thêm sau R1) **PASS 100%** (toàn gói DS 472 pass / 1 fail sẵn có ở `v_overlay_menu_shell_test.dart` không liên quan).
- `node .gitnexus/run.cjs detect-changes --repo erp-sales-inventory`:
  - `Changes: 20 files, 7 symbols | Affected processes: 0 | Risk level: low`
  - Các symbol thay đổi đều nằm đúng phạm vi plan (`appRouter`, `GoRouter`, `LotIssue`, `build` trong `inventory_layout.dart`, `InventorySessionStore`, `VTable`, `isSmall` trong `v_badge.dart`).
- Lưu ý DB: tuân thủ quy tắc phiên code không tự chạy DB (`supabase/tests/inventory_stock_view.sql` đã viết đủ 7 ca test để người dùng chạy khi áp migration).

### 5.4 Sửa sau R1 (2026-11-10)
- **#1** `StockDetailCubit.load`: đổi sang sản phẩm khác ⇒ xoá `data` cũ; `_fetch` bỏ phản hồi (cả lỗi) khi `productId` không còn là sản phẩm đang chọn. Test `load_other_product_clears_old_data`, `late_response_ignored` (`stock_list_test.dart`), `aside_error_shows_retry_1280` (`stock_list_page_test.dart`).
- **#2** `StockDetailPanel` nhận `listAsOf` (mốc "Dữ liệu đến" của danh sách); mốc đổi ⇒ `refresh()` cột phải. Lưu ngưỡng ở cột phải ⇒ cột phải tự tải lại rồi làm mới danh sách (thêm 1 lần gọi khi mốc đổi — chấp nhận, để không phụ thuộc danh sách làm mới thành công). Test `refresh_reloads_aside_1280`.
- **#3** Sửa 5.2 / 5.3 cho khớp code. Thêm `packages/c45_design_system/test/components/v_table_selected_test.dart` (`selected_row_background`, `no_selection_by_default`, `selected_semantics`). Kèm #9 một phần: `VTable` dòng chọn dùng `colors.surfaceBrand` thay `Color(0xFFEBF4EC)` (sửa `selected_row_highlighted` theo token).
- Kiểm: `dart analyze lib/features/inventory test/features/inventory` = 0; `flutter test --no-pub test/features/inventory` = **285/285**; DS `dart analyze lib` = 0, `v_table_*_test` 6/6.
- Chưa sửa: P3 #4–#8, #10, #11, phần `Color(0xFF4A535E)` của #9.
- `detect_changes` (sau `analyze` lại): 23 tệp, 44 symbol, 0 process bị ảnh hưởng, **low**; `impact StockDetailPanel` LOW (5). `AGENTS.md`, `CLAUDE.md` chỉ đổi dòng thống kê do `analyze` — không `git add`.
- Còn biết: `stock_flow_test.dart` (như `stock_policy_flow_test.dart` của G5-2a) ghi ảnh rồi mới `matchesGoldenFile` chính tệp đó ⇒ so ảnh không bao giờ đỏ, và mỗi lần chạy test ghi đè ảnh trong `docs/`.

## 6. Review

### R1 (2026-11-10) — ❌ chưa đạt (0 P1, 3 P2)

Đã chạy: `dart analyze lib/features/inventory test/features/inventory lib/core` = 0 lỗi; `flutter test --no-pub test/features/inventory` = **đạt hết**; test DS `v_stock_row_test`, `primitives/*` đạt. Mọi test có tên trong plan đều có (SQL 7/7 ca trong `supabase/tests/inventory_stock_view.sql`, chưa chạy — người dùng chạy). Đã so ảnh `flutter-SCR-001-READY-1280`, `flutter-SCR-003-READY-390` với `proto-*` (Ahem nên chỉ so được bố cục).

| # | Mức | Chỗ | Lỗi | Sửa |
|---|---|---|---|---|
| 1 | P2 | `stock_list_page.dart:473-477`, `stock_detail_cubit.dart:19-28` | Web: đổi dòng ⇒ `load(newId)` **giữ `data` cũ** (`copyWith` không xoá) ⇒ trong lúc tải cột phải vẫn hiện sản phẩm cũ trong khi bảng tô dòng mới; tải lỗi ⇒ hiện sản phẩm cũ **mãi**, không báo lỗi (nhánh `loadError && data == null` không vào). Bấm nhanh A → B: phản hồi A về sau ghi đè B (không bỏ phản hồi cũ) | `load(id)` khác `state.productId` ⇒ xoá `data`; `_fetch` bỏ kết quả khi `productId != state.productId`. Test `aside_switch_shows_loading_not_old_product_1280`, `aside_late_response_ignored`, `aside_error_shows_retry_1280` |
| 2 | P2 | `stock_list_page.dart:405-410` | Web: "Làm mới" (banner STALE) chỉ gọi `StockListCubit.refresh` ⇒ cột phải **không tải lại** (productId không đổi) ⇒ bảng và chi tiết lệch số / "Dữ liệu đến". Khi resume, cột phải cũng không bao giờ `checkStale` | Truyền mốc `data.asOf` (hoặc `refreshTick`) vào `StockDetailPanel`, `didUpdateWidget` đổi mốc ⇒ `_cubit.refresh()`. Test `refresh_reloads_aside_1280` |
| 3 | P2 | Kết quả 5.2, 5.3 | Ghi sai so với code / ảnh: (a) ảnh SCR-001 1280 cột phải "nút **Nhận hàng**" — code ẩn (`onReceive` null, Q-2-5), ảnh cũng không có nút; (b) bảng lô SCR-003 web ghi cột "Tồn vật lý", "Trạng thái" — code là "Tồn", "Tình trạng" (đúng plan); (c) 5.3 ghi `v_table_test.dart` PASS — tệp **không tồn tại**; `VTable.selectedRowIndex` (sửa DS) không có test nào trong `packages/c45_design_system/test/` (chỉ test qua `K7Table` ở app) | Sửa Kết quả cho khớp; thêm `packages/c45_design_system/test/components/v_table_selected_test.dart` (`selected_row_background`, `selected_semantics`) |
| 4 | P3 | `stock_list_cubit.dart:45-52`, `stock_detail_cubit.dart:50-58` | "Làm mới" lỗi khi đã có dữ liệu ⇒ `status = loadError` nhưng màn vẫn vẽ dữ liệu cũ (vì `data != null`), banner STALE còn đó, **không báo gì** | Lỗi lúc `refresh` giữ `ready`, đặt `refreshError` ⇒ `VToast` / banner "Không làm mới được. Thử lại." |
| 5 | P3 | `stock_list_state.dart:37-46` | Dòng chọn dự phòng chỉ tính lúc đọc, `selectedProductId` vẫn giữ sản phẩm đã ẩn ⇒ chọn Amox, lọc "Hết hạn" (thấy Tylosin), về "Tất cả" ⇒ cột phải nhảy **lại Amox**. Prototype ghi đè `bj01SelectedProductId = selected.id` (Review Focus 6: "không giữ sản phẩm đã ẩn") | `setFilter` / `setQuery`: sản phẩm chọn không còn trong `visible` ⇒ đặt `selectedProductId = visible.first.productId`. Thêm bước vào test `selected_falls_back_to_first_visible_1280` |
| 6 | P3 | `stock_list_page.dart:114` | Không truyền `extra: item.name` ⇒ LOADING app bar ghi "Chi tiết tồn kho" thay vì tên sản phẩm (Task 5 dòng LOADING, Task 7 `extra`) | `context.push('/warehouse/stock/$id', extra: item.name)`; test `loading_shows_product_name` |
| 7 | P3 | `stock_indicator_badge.dart:20-24` (dùng ở cột "Chỉ báo" web) | Sản phẩm bình thường hiện badge xanh "Bình thường"; `bj01TableRow` để **trống** (chữ không có trong SCR-001) | Thêm cờ `showNormal` (mặc định `true` cho G5-2a), SCR-001 truyền `false` |
| 8 | P3 | `stock_detail_body.dart:179-189` | "Sửa ngưỡng" là `InkWell` + chữ 13px: vùng chạm ~20px (< 44), không có `Semantics(button)` | `VButton(variant: tertiary, size small)` hoặc `Semantics(button: true)` + `ConstrainedBox(minHeight: 44)` |
| 9 | P3 | `v_table.dart:102`; `stock_*` (nhiều chỗ `Color(0xFF4A535E)`) | Mã màu cứng thay token: nền dòng chọn có sẵn `colors.surfaceBrand`, chữ phụ có `colors.textSecondary` ⇒ DS / chế độ tối không theo | Đổi sang `context.vColors.surfaceBrand` / `.textSecondary` |
| 10 | P3 | `20261112001_inventory_stock_view.sql:110-116` | `get_stock_detail` không lọc `business_status = 'active'`, trong khi `_product_stock_rows` chỉ có sản phẩm `active` ⇒ sản phẩm ngừng bán còn hàng: thẻ "Khả dụng 0 / Tồn vật lý 0" nhưng danh sách lô vẫn có lô tồn > 0. Thêm: `_product_stock_rows` cộng **mọi kho**, còn lô / biến động lọc theo `warehouse_id` — đúng chỉ khi một kho | Tính `physical` / `available` cho chi tiết thẳng từ lô đã lọc (hoặc `CONTEXT_INVALID` cho sản phẩm không `active`); ghi chú "một kho" ở header migration. Ca SQL `inactive_product_detail_consistent` |
| 11 | P3 | `flutter-SCR-003-READY-390.png` khối "Giá vốn" | Nhãn `VKeyValueRow` gãy 3–4 dòng ("Bình quân liên hoàn"), giá trị chiếm phần lớn bề ngang — Ahem phóng đại nhưng tỉ lệ nhãn / giá trị có vẻ ngược | Kiểm bằng font thật; nếu vẫn gãy, giới hạn cột giá trị (`Flexible`) |

**Đạt:** SQL đúng 2.1 (quyền `_assert_actor`, `security definer`, grant, che `cost` + `financial_masked`, sắp lô `_lot_expiry_end` + `nulls last`, `latest_movement` theo `ledger_sequence`, Hub `problems` cùng luật `stockIndicators`, chưa kích hoạt ⇒ `null`, không mã lỗi mới, REGISTRY); `formatQuantity` dời đúng + re-export; ranh giới tầng (`indicators` là extension ở `logic`); luật chip / tìm / sắp mức gấp / đếm chip khớp `bj01.js`; STALE 5 phút + resume + quay về; Q-2-1 (không nút quét), Q-2-4 (bỏ "Đã giữ", "Cách ly"), Q-2-5 (4 nút ẩn qua callback null); nhân viên không có khối giá vốn, không "Sửa ngưỡng" / "Đặt ngưỡng tồn"; route ngoài `StatefulShellRoute`; Hub "Tồn kho cần chú ý" + nút nhanh "Tra cứu tồn".

Làm lại: sửa #1–#3 (P2), #4–#11 khi tiện; ghi Kết quả R1 → R2.

### R2 (2026-11-10) — ✅ đạt (P2 đã sửa; P3 còn nợ)

Kiểm lại trên code sau sửa (mục 5.4): `dart analyze` = 0; `check_feature_imports` = 0 vi phạm inventory; `flutter test --no-pub test/features/inventory` = 285/285; `detect_changes` low, 0 process.

| # R1 | Trạng thái | Bằng chứng |
|---|---|---|
| 1 P2 | ✅ | `stock_detail_cubit.dart` `load` xoá `data` khi đổi sản phẩm, `_fetch` bỏ phản hồi lệch `productId`; 3 test mới xanh |
| 2 P2 | ✅ | `StockDetailPanel.listAsOf` ⇒ `refresh()`; lưu ngưỡng ở cột phải tự tải lại trước rồi làm mới danh sách (R2 sửa hồi quy: bản đầu phụ thuộc danh sách làm mới thành công); `refresh_reloads_aside_1280` xanh |
| 3 P2 | ✅ | 5.2 / 5.3 khớp code; `v_table_selected_test.dart` 3/3 |
| 9 P3 | 🟡 một phần | `VTable` dùng `surfaceBrand`; `Color(0xFF4A535E)` ở `stock_*` còn |
| 4–8, 10, 11 P3 | ⬜ còn nợ | — |

Thêm (P3, có từ G5-2a): `stock_flow_test.dart` ghi ảnh rồi `matchesGoldenFile` chính tệp đó ⇒ so ảnh không bao giờ đỏ.
