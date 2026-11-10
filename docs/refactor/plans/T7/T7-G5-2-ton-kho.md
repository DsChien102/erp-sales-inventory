# T7-G5-2 — BJ-01 Tồn kho & khả dụng

> Theme 7 · plan **G5-2** của [PLAN.md](../../PLAN.md) mục "Theme 7" (bảng Plan)
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-10) | Làm ⬜ | Review ⬜
> Thiết kế: duyệt trong chat 2026-11-10 (mục 1). Màn: SCR-001, SCR-003 (FROZEN v5.27.0) theo prototype **v5.28.0** (`app/bj01.js`), CAP-01 lấy lại ở [G5-2a](T7-G5-2a-chinh-sach-ton.md). Phụ thuộc: G5-0b, **G5-2a**.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Nhân viên tìm một sản phẩm và thấy ngay khả dụng; chủ cửa hàng lọc hàng hết / tồn thấp / cận hạn / hết hạn, mở chi tiết thấy lô, nguồn số liệu và giá vốn (chỉ chủ cửa hàng); Hub có "Cần chú ý" về tồn.

**Architecture:** Migration `20261112001_inventory_stock_view.sql` thêm 2 RPC đọc (danh sách, chi tiết) dựa trên `inventory._product_stock_rows` của G5-2a; sửa `get_warehouse_hub_summary` (migration gốc G5-0b) điền `problems`. Flutter `features/inventory/{data,logic,presentation}/stock/`: một repository, hai Cubit (danh sách, chi tiết), luật chỉ báo dùng lại `logic/stock/stock_indicator_rules.dart` (G5-2a). Web SCR-001 là danh sách – chi tiết (chi tiết dùng chung widget thân SCR-003).

**Tech Stack:** PostgreSQL / Supabase (plpgsql), Flutter, `flutter_bloc`, `go_router`, `get_it`, `vet45_design_system`.

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
| `packages/vet45_design_system/lib/src/primitives/v_badge.dart`, `…/components/v_stock_row.dart` (mới), `design_system.dart` + test | sửa / tạo | 4 |
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

- [ ] **Step 1: Test hợp đồng (đỏ):** `stock_view_rpcs_granted` (`list_stock_overview(uuid)`, `get_stock_detail(uuid, uuid)` có `security definer` + `grant execute … to authenticated` + `_assert_actor(p_tenant_id, 'inventory.read')`); `detail_masks_cost_for_non_owner` (chuỗi `'financial_masked'` và nhánh `is_owner` trong `get_stock_detail`); `hub_summary_fills_problems` (đọc `20261110001`: hàm có `'near_expiry'`, `'products'`, gọi `_product_stock_rows`, không còn `'problems', null` trong nhánh đã kích hoạt); `no_new_error_codes`.
- [ ] **Step 2: Chạy, thấy đỏ** — `cd apps/erp && flutter test --no-pub -r compact test/features/inventory/data/stock_view_sql_contract_test.dart`.
- [ ] **Step 3: Viết migration + sửa Hub summary** theo 2.1.
- [ ] **Step 4: Viết `supabase/tests/inventory_stock_view.sql`** (khuôn `inventory_core.sql`): `product_without_movement_listed_zero`, `available_excludes_expired_lot` (11 hết hạn + 3 còn hạn ⇒ `available 3`, `expired_quantity 11`), `lots_sorted_by_expiry_end` (`DAY 30/09`, `MONTH 09`, `YEAR`, không HSD ⇒ đúng thứ tự), `staff_cost_masked`, `owner_cost_from_product_costs`, `latest_movement_is_max_sequence`, `hub_problems_counts` (1 hết hàng, 1 tồn thấp + có lô cận hạn ⇒ `products 2`).
- [ ] **Step 5: Chạy test hợp đồng, thấy xanh.**

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

- [ ] **Step 1: Test (đỏ):** `format_quantity_moved_same_output` (`106` → "106", `1.5` → "1,5"); `format_stock_quantity` ("41 hộp"); `overview_parses` (JSON mẫu: `as_of` ISO ⇒ `DateTime` local, `reorder_threshold null` ⇒ `threshold null`, `indicators == [notConfigured]`); `detail_parses_lots_and_cost`; `lot_date_from_json_month` (`'2027-11-30'`, `'MONTH'` ⇒ `format() == '11/2027'`); `detail_cost_null_when_masked`; `latest_movement_label` (`SALE` ⇒ "Xuất bán").
- [ ] **Step 2: Chạy, thấy đỏ.**
- [ ] **Step 3: Viết code**; chạy lại test cũ dùng `formatQuantity` (`flutter test --no-pub -r compact test/features/inventory`).
- [ ] **Step 4: Chạy, thấy xanh.**

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

- [ ] **Step 1: Test (đỏ)** với fixture 5 sản phẩm như `bj01.js:12-32` sau khi áp v5.28 (Nobivac 118/120 lô cận hạn ngưỡng 30; Amox 46 ngưỡng 50; Enro 0 ngưỡng 10; Tylo khả dụng 3 có lô hết hạn ngưỡng 8; Oxy 11 chưa ngưỡng): `all_sorted_by_urgency` (Enro, Tylo, Amox, Nobivac, Oxy); `chip_counts_ignore_search` (gõ "amox" ⇒ `filterCount(low) == 2`); `search_matches_barcode` ("8938500004068" ⇒ Amox); `filter_keeps_original_order`; `empty_status_when_no_products`; `denied_on_no_permission`; `stale_after_five_minutes_on_resume` (now giả +5 phút 1 giây ⇒ `checkStale()` ⇒ `stale true`; +4 phút ⇒ false); `refresh_clears_stale_and_keeps_filter`; `selected_falls_back_to_first_visible`; `detail_load_and_refresh`.
- [ ] **Step 2: Chạy, thấy đỏ.**
- [ ] **Step 3: Viết code.**
- [ ] **Step 4: Chạy, thấy xanh.**

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
function bj01Context() { return `<p class="ds24-context vet45-text-style-7" data-ds-component="VText" data-ds-prop-style="Body/Small">Kho trung tâm · Dữ liệu đến ${esc(bj01AsOf()).replace(" · ", ", ")}</p>`; }
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
.ds24-chip.is-empty:not(.is-selected) .ds24-chip__count { color: var(--vet45-v2-text-secondary); }
.ds24-stock-row { min-height: 64px; }
.ds24-stock-row__value { flex: 0 0 auto; display: flex; flex-direction: column; align-items: flex-end; gap: 4px; }
.ds24-stock-row__qty { font-family: var(--vet45-v2-font-mono); font-size: 16px; line-height: 22px; font-weight: 700; color: var(--vet45-v2-text-primary); font-variant-numeric: tabular-nums; white-space: nowrap; }
body[data-active-uif="UIF-01"] .ds24-context { margin: 0; color: var(--vet45-v2-text-secondary); font-size: 13px; }
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

- [ ] **Step 1: Test DS (đỏ)** — `packages/vet45_design_system/test/primitives/v_badge_hollow_dot_test.dart`: `hollow_dot_draws_ring` (chấm 8 × 8 viền tone, nền trong suốt); `packages/vet45_design_system/test/components/v_stock_row_test.dart`: `min_height_64`, `quantity_mono_bold_16`, `badge_below_quantity`, `has_chevron`, `semantics_button_label` ("{title}, {quantity}, {badge}").
- [ ] **Step 2: Viết** `VBadge.hollowDot` (bool, mặc định false; chỉ có hiệu lực khi `showDot`) và `VStockRow({required String title, String? subtitle, required String quantity, Widget? badge, VoidCallback? onTap, bool selected = false})` (dựa trên `VListRow` không icon đầu); export ở `design_system.dart`. Sửa `StockIndicatorBadge` của G5-2a (`presentation/stock_policy/`) dùng `hollowDot: true` cho tone `danger` và dời sang `presentation/stock/stock_indicator_badge.dart` để hai màn dùng chung (sửa import ở G5-2a). Chạy test DS + test G5-2a xanh.
- [ ] **Step 3: Widget test SCR-001 iPhone (đỏ)** — `test/features/inventory/presentation/stock/stock_list_page_test.dart` (390 × 844, fake repository fixture Task 3): `list_ready_390` (ngữ cảnh "Kho trung tâm · Dữ liệu đến 21:30, 17/09/2026"; không có `Semantics('Quét mã vạch')`; dòng đầu Enrofloxacin "0 chai" + "Hết hàng"; Oxy phụ đề "SP-000147 · Chưa có ngưỡng tồn", không badge); `chip_tap_filters_390`; `empty_when_no_products`; `filter_empty_clear_resets`; `stale_banner_refresh`; `denied_390`; `row_tap_opens_detail_route` (đẩy `/warehouse/stock/INV-AMX`).
- [ ] **Step 4: Chạy, thấy đỏ.**
- [ ] **Step 5: Dựng `stock_list_page.dart`** (bố cục iPhone) theo bảng; `WidgetsBindingObserver` gọi `checkStale()` khi resumed; quay về từ chi tiết (`await context.push`) gọi `checkStale()`.
- [ ] **Step 6: Chạy, thấy xanh.**

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
  return ds24Sheet({title:`Lô ${lot.code}`,attrs:'data-bj01-close-lot',body:`<p class="ds24-context vet45-text-style-7">${esc(p.name)} · HSD ${esc(lot.expiryDisplay)}</p>${bj01LotQuantityRows(lot,p)}${status}${dispose}`});
}
function bj01ProvenanceSheet(p) {
  if(!bj01ProvenanceOpen)return "";
  const mv=bj01LatestMovement(p); const rs=p.reservationSummary||{};
  const movementValue=mv.source?`${mv.source} · ${Number(mv.delta)>0?'+':''}${mv.delta} ${p.stockUom}`:'Chưa có biến động';
  const reservationValue=Number(rs.quantity)>0?`${rs.quantity} ${p.stockUom}${rs.source?` · ${rs.source}`:''}`:`0 ${p.stockUom}`;
  return ds24Sheet({title:'Nguồn và thời điểm cập nhật',attrs:'data-bj01-close-provenance',body:`<p class="ds24-context vet45-text-style-7">${esc(p.name)} · Kho trung tâm</p><div class="ds24-info-stack">${ds24InfoRow('Dữ liệu đến',bj01AsOf())}${ds24InfoRow(mv.label?`${mv.label} gần nhất`:'Biến động gần nhất',movementValue)}${mv.receipt?`<button class="k7-row-link" type="button" data-bj01-open-receipt="${escapeAttribute(mv.source)}">Mở phiếu nhận ${esc(mv.source)}</button>`:''}${ds24InfoRow('Đang giữ',reservationValue)}</div><button class="ds24-button ds24-button--secondary" data-bj01-handoff type="button" data-ds-component="VButton" data-figma-node="521:529">${icon('history','icon--sm')}Xem thẻ kho và lịch sử</button>`});
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
.bj01-stock-hero { width: 100%; padding: var(--vet45-v2-space-4); display: flex; flex-direction: column; gap: var(--vet45-v2-space-3); border: var(--vet45-v2-border-width-thin) solid var(--vet45-v2-border-default); border-radius: var(--vet45-v2-radius-4); background: var(--vet45-v2-surface-default); box-sizing: border-box; }
.bj01-stock-hero__main { display: grid; grid-template-columns: minmax(0, 1fr) auto; align-items: center; gap: var(--vet45-v2-space-1) var(--vet45-v2-space-3); }
.bj01-stock-hero__main > span { grid-column: 1 / -1; font: 400 13px/20px Inter, sans-serif; color: var(--vet45-v2-text-secondary); }
.bj01-stock-hero__main > strong { font-family: var(--vet45-v2-font-mono); font-size: 22px; line-height: 28px; font-weight: 700; color: var(--vet45-v2-text-primary); font-variant-numeric: tabular-nums; grid-column: 1; grid-row: 2; }
.bj01-stock-hero__main > .ds24-badge { grid-column: 2; grid-row: 2; width: auto; justify-self: end; }
.bj01-stock-hero__stats { margin: 0; display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: var(--vet45-v2-space-3); }
.bj01-stock-hero__stats dt { font: 400 12px/16px Inter, sans-serif; color: var(--vet45-v2-text-secondary); }
.bj01-stock-hero__stats dd { margin: var(--vet45-v2-space-1) 0 0; font-family: var(--vet45-v2-font-mono); font-size: 14px; line-height: 20px; font-weight: 600; color: var(--vet45-v2-text-primary); }
.bj01-stock-hero__note { margin: 0; padding-top: var(--vet45-v2-space-3); border-top: var(--vet45-v2-border-width-thin) solid var(--vet45-v2-border-default); font: 400 13px/20px Inter, sans-serif; color: var(--vet45-v2-text-secondary); }
.bj01-stock-hero__policy { display: flex; align-items: center; justify-content: space-between; gap: var(--vet45-v2-space-3); padding-top: var(--vet45-v2-space-3); border-top: var(--vet45-v2-border-width-thin) solid var(--vet45-v2-border-default); font: 400 13px/20px Inter, sans-serif; color: var(--vet45-v2-text-secondary); }
.bj01-stock-hero__note + .bj01-stock-hero__policy { padding-top: 0; border-top: 0; }
.bj01-attention { display: flex; flex-direction: column; gap: var(--vet45-v2-space-2); }
.bj01-attention__hint { margin: 0; font: 600 14px/20px Inter, sans-serif; color: var(--vet45-v2-text-primary); }
.bj01-config-note{margin:8px 0 0}
.bj01-detail, .bj01-detail__summary, .bj01-detail__more { display: contents; }
.device-preview.is-web .bj01-detail { display: grid; grid-template-columns: minmax(0, 5fr) minmax(0, 7fr); gap: var(--vet45-v2-space-6); align-items: start; }
.device-preview.is-web .bj01-detail__summary, .device-preview.is-web .bj01-detail__more { display: flex; flex-direction: column; gap: var(--vet45-v2-space-3); min-width: 0; }
.device-preview.is-web .k7-split__aside > .bj01-detail { display: flex; flex-direction: column; align-items: stretch; gap: var(--vet45-v2-space-4); }
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

- [ ] **Step 1: Widget test (đỏ)** `test/features/inventory/presentation/stock/stock_detail_page_test.dart` (fake repository; Tylosin có lô `TY2408` hết hạn 11, `TY2511` 3; Nobivac lô cận hạn còn 13 ngày):
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
- [ ] **Step 2: Chạy, thấy đỏ.**
- [ ] **Step 3: Dựng** `stock_detail_body.dart` (nhận `StockDetail` + callback `onEditThreshold`, `onReceive`, `onAdjustExpired`, `onOpenStockCard`, `onOpenReceipt` — 4 cái sau truyền `null` ở plan này), `stock_cost_block.dart`, `stock_lot_sheet.dart`, `stock_provenance_sheet.dart`, `stock_detail_page.dart`.
- [ ] **Step 4: Chạy, thấy xanh.**

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
.device-preview.is-web .k7-split__aside > .bj01-detail { display: flex; flex-direction: column; align-items: stretch; gap: var(--vet45-v2-space-4); }
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

- [ ] **Step 1: `impact` cho `K7Table`**; test `K7Table` (đỏ): `selected_row_highlighted` (nền #EBF4EC, `Semantics.selected`).
- [ ] **Step 2: Widget test (đỏ)** thêm vào `stock_list_page_test.dart` (1280 × 800): `list_detail_ready_1280` (4 tiêu đề cột, không "Đã giữ"; cột phải hiện thẻ số của dòng đầu "Enrofloxacin 10%"); `row_tap_changes_aside_not_route_1280`; `selected_falls_back_to_first_visible_1280` (chọn Amox, lọc "Hết hạn" ⇒ cột phải là Tylosin).
- [ ] **Step 3: Chạy, thấy đỏ.**
- [ ] **Step 4: Dựng** nhánh web của `stock_list_page.dart`, thêm `K7Table.selected`.
- [ ] **Step 5: Chạy, thấy xanh** — `flutter test --no-pub -r compact test/features/inventory`.

### Task 7: Route, DI, lối vào Hub, "Cần chú ý"

**Files:** Create `lib/features/inventory/presentation/stock/stock_routes.dart`; Modify `lib/core/router/app_router.dart`, `lib/core/di/injection.dart`, `lib/features/inventory/presentation/hub/warehouse_entries.dart`, `lib/features/inventory/data/hub/warehouse_hub_repository.dart`, `warehouse_hub_page.dart` (đích chạm dòng "Cần chú ý"); Test `test/features/inventory/presentation/stock/stock_routes_test.dart`, sửa test Hub.

**Interfaces:**
- Produces: `List<RouteBase> stockRoutes()` — `GoRoute('/warehouse/stock')` (`StockListPage`), `GoRoute('/warehouse/stock/:productId')` (`StockDetailPage`, `extra` = tên sản phẩm cho app bar lúc tải); đặt cạnh `stockPolicyRoutes()` (G5-2a). DI `StockRepository`.
- `warehouseAreaEntries(inventory)`: `stock_availability.route = '/warehouse/stock'`; nút nhanh "Tra cứu tồn" `route: '/warehouse/stock'`; `warehouseStockSearchRoute = '/warehouse/stock'`.
- `WarehouseHubRepository.getSummary`: đọc `problems` (mục 2.1) ⇒ `WarehouseAttention(count: products, text: …)` theo chữ đề xuất mục 1; `products == 0` ⇒ `null`.
- Hub: dòng "Cần chú ý" đổi tiêu đề thành "Tồn kho cần chú ý", chạm ⇒ `context.push('/warehouse/stock')` (thay đích `stocktaking` cũ của G5-0a).

- [ ] **Step 1: `impact`** cho `WarehouseHubRepository.getSummary`, `warehouseAreaEntries`, `warehouseQuickActions`, `warehouseStockSearchRoute`.
- [ ] **Step 2: Test (đỏ):** `hub_summary_text_joins_nonzero` (`{out: 2, low: 1, expired: 1, near_expiry: 0, products: 3}` ⇒ `count 3`, `text '2 hết hàng · 1 tồn thấp · 1 có lô hết hạn'`); `hub_problems_zero_is_null`; `hub_attention_row_opens_stock`; `quick_action_tra_cuu_ton_opens_stock`; `route_detail_opens_product`.
- [ ] **Step 3: Chạy, thấy đỏ.**
- [ ] **Step 4: Viết.**
- [ ] **Step 5: Chạy, thấy xanh.**

### Task 8: Luồng đầu–cuối, đối chiếu ảnh, kiểm cuối

- [ ] **Step 1: Test luồng** `test/features/inventory/presentation/stock/stock_flow_test.dart` (fake repository, chủ cửa hàng, 390): Hub "Tồn kho cần chú ý" → danh sách → chip "Tồn thấp" → Tylosin → "Sửa ngưỡng" → (fake G5-2a trả `true`) → chi tiết tải lại → quay lại danh sách giữ chip "Tồn thấp".
- [ ] **Step 2: Ảnh Flutter** (`matchesGoldenFile`): `img/G5-2/flutter-SCR-001-READY-{390,1280}.png`, `flutter-SCR-003-READY-{390,1280}.png` (fixture Task 3; SCR-003 là Nobivac như ảnh prototype, chủ cửa hàng). So với `proto-*`; lệch ghi Kết quả (chênh đã biết: mục đầu Task 4, Task 5).
- [ ] **Step 3: Kiểm** — `cd apps/erp && dart analyze lib/features/inventory test/features/inventory` = 0 lỗi; `cd packages/vet45_design_system && dart analyze && flutter test --no-pub -r compact`; `flutter test --no-pub -r compact` (app) không thêm lỗi so với `TEST-BASELINE.md`; `detect_changes()`.
- [ ] **Step 4: Ghi Kết quả** + PLAN.md bảng Plan (cột Làm).

## 5. Kết quả

_(phiên code ghi)_

## 6. Review

_(phiên review ghi)_
