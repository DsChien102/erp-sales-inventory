# T7-G5-4 — Nối Sales với sổ kho

> Theme 7 · plan **G5-4** của [PLAN.md](../../PLAN.md) mục "Theme 7" (bảng Plan, Q7)
> Trạng thái: Plan ✅ (duyệt 2026-11-11) | Làm ✅ 2026-11-11 | Review ✅ R2 đạt (2026-11-11)
> Thiết kế: duyệt trong chat 2026-11-11 (2 câu hỏi + phương án nối + 4 phần: SQL kho, Sales + lookup, Flutter, test). Nguồn nghiệp vụ: [spec giá vốn](T7-G5-gia-von-thiet-ke.md) mục 3.1, 3.2 (dòng đơn lưu giá vốn), 4 (luật `SALE` / `SALE_REVERSAL` / `RETURN_IN`), 9 ca 6. Phụ thuộc: G5-0b (`_post_movements`, `_value_line`), G5-2a (`_product_stock_rows`, `_lot_expiry_end`), G5-3 (có hàng vào kho để bán). Không có màn mới ⇒ không áp "UI Flutter: trích code prototype".

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thanh toán đơn xuất kho FEFO (bỏ lô hết hạn) và lưu giá vốn lên dòng đơn; huỷ đơn / trả hàng nhập lại đúng lô đã xuất theo giá dòng bán gốc (`SALE_REVERSAL` / `RETURN_IN`); hàng đổi xuất kho như bán; thiếu tồn khả dụng ⇒ chặn; ô chọn sản phẩm khi bán hiện tồn khả dụng theo sổ kho. Tiền / công nợ 6 kịch bản Theme 5 không đổi.

**Architecture:** Ba RPC Sales (`finalize_sales_order`, `confirm_sales_order_cancellation`, `confirm_return_exchange`) gọi **thẳng trong cùng giao dịch** hai hàm nội bộ mới của Kho — `inventory._issue_for_sale` và `inventory._reverse_sale` — ở migration riêng của plan `20261115001_inventory_sales_link.sql`; hai hàm này chọn lô rồi gọi `_post_movements` sẵn có. Sales không đọc / ghi bảng kho. Lookup bán hàng của Catalog đọc `inventory._product_stock_rows` (thêm bộ lọc sản phẩm). Sửa **thẳng migration gốc** của Sales / Catalog (người dùng chốt).

**Tech Stack:** PostgreSQL / Supabase (plpgsql), Flutter, `flutter_bloc`.

**Spec:** mục 1–2 của plan này + [spec giá vốn](T7-G5-gia-von-thiet-ke.md) mục 3–4 + PLAN.md Theme 7 → "Quy ước chung cho mọi plan G5".

## Global Constraints

- Quy ước chung: PLAN.md Theme 7 → "Quy ước chung cho mọi plan G5" (cấu trúc code, SQL, test SQL, review plan có SQL).
- **Sửa migration gốc**, không tạo bản ghi đè: chỉ sửa **bản định nghĩa cuối** của mỗi hàm — `finalize_sales_order` ở `20261031017_sales_buyer_invoice_snapshot.sql` (bản ở `20260830008` bị ghi đè, để nguyên); `precheck_sales_order_checkout` ở `20260830008`; `confirm_sales_order_cancellation`, `confirm_return_exchange` ở `20260904001` (bản ở `20260830011` / `014` để nguyên); `search_sellable_products`, `resolve_sellable_barcode`, `list_sellable_product_units` ở `20260830002`; `resolve_sellable_products` ở `20260831001`; `_product_stock_rows` ở `20261111001` (sửa tại chỗ, **không** tạo overload). Cột mới trên bảng Sales thêm ở `20260830005_sales_rebuild_schema.sql`.
- Hàm Sales / Catalog có `search_path` không gồm `inventory` ⇒ luôn gọi đủ tên `inventory.<hàm>`. Migration Sales chạy trước `inventory_core` ⇒ cột Sales **không** có FK sang bảng `inventory.*`.
- Hàm kho mới: `security definer`, `set search_path = inventory, iam, catalog, pg_temp`, `revoke all … from public, anon, authenticated`, **không** `grant` (chỉ hàm khác gọi). Lỗi qua `inventory._raise(code, message)`. Ngày ghi sổ = `inventory._today()`. Số lượng kho theo **ĐVT cơ sở** (`numeric`) = `base_quantity_micros / 1000000.0`.
- Tiền `bigint` (đồng); đơn giá `numeric(18,4)`. Giá vốn dòng = `−Σ amount_vnd` các dòng `SALE` của dòng đó (mỗi lô làm tròn riêng — **không** tính lại `round(SL × c)` cho cả dòng).
- Chạy SQL: `tools/db_check.sh` (đủ 3 bước) phải ✅ trước khi báo xong mỗi task có SQL; chỉ một tệp: `tools/db_check.sh --no-reset <tên>` sau khi đã reset. Reset Dev (`--linked`) **hỏi người dùng**.
- Flutter: `dart analyze` (không `flutter analyze`); test `cd apps/erp && flutter test --no-pub -r compact <đường dẫn>`.
- Trước khi sửa symbol đã có (các hàm SQL ở trên, `CheckoutResultDto`, `SalesCheckoutCubit`, `salesCheckoutException`, `returnExchangeException`, `salesPostSaleErrorMessage`, `SalesCatalogProductLookup`): `impact({target, direction: "upstream"})`, ghi Kết quả; HIGH / CRITICAL ⇒ dừng, báo người dùng. Task cuối: `detect_changes({scope: "compare", base_ref: "main"})`.
- `AGENTS.md`, `CLAUDE.md`: không `git add`. Ghi mục 5 Kết quả sau mỗi task.

## Review Focus

1. **Bán tranh nhau lô cuối** — hai thu ngân cùng thanh toán 5 hộp khi khả dụng 7: khoá advisory theo sản phẩm lấy **trước** khi chọn lô ⇒ đơn sau thấy khả dụng 2, bị `INSUFFICIENT_STOCK` (đơn `blocked`, không đơn nào nửa vời, không `stock_balances` âm). Test: Task 1 `issue_locks_before_choosing_lots` (hợp đồng: `pg_advisory_xact_lock` đứng trước truy vấn chọn lô trong thân hàm); Task 2 `S7`.
2. **Một sản phẩm hai dòng khác ĐVT** — đơn có 1 hộp (10 viên) + 5 viên, khả dụng 12 viên: kiểm gộp 15 > 12 ⇒ chặn cả precheck lẫn finalize; khả dụng 15 ⇒ bán được, hai dòng mỗi dòng có giá vốn riêng. Test: Task 1 `issue_groups_lines_by_product`; Task 2 `S7` (biến thể hai ĐVT).
3. **Trả nhiều lần trên dòng tách lô** — dòng bán 8 lấy lô A (hạn 30/11) 5 + lô B (hạn 31/12) 3; trả 4 ⇒ B +3, A +1; trả tiếp 4 ⇒ A +4; trả thêm 1 ⇒ `CONTEXT_INVALID`, không ghi gì. Test: Task 1 `reverse_latest_expiry_first`, `reverse_exceeds_remaining`; Task 2 `S5`.
4. **Trả lại món đã đổi** — phiếu 1 đổi A lấy B; phiếu 2 trả B (`source_exchange_line_id`) ⇒ tìm `SALE` của dòng exchange (`intent_type 'RETURN_EXCHANGE'`), không tìm ở đơn gốc. Test: Task 2 `S6`.
5. **Gửi lại thanh toán sau lỗi thiếu tồn** — finalize `blocked` vì thiếu tồn; nhập thêm hàng; bấm lại **cùng** khoá ⇒ trả lại kết quả `blocked` cũ (idempotency đã ghi `failed`) — hành vi hiện có của Sales, không đổi; Flutter tạo khoá mới khi người dùng thanh toán lại từ đầu. Test: Task 2 `S8` (cùng khoá thành công không xuất hai lần) + `S7b` (cùng khoá sau `blocked` vẫn `blocked`, không sinh dòng sổ).

---

## 1. Quyết định (người dùng, 2026-11-11)

| Q | Nội dung |
|---|---|
| Q-4-1 | **Thiếu tồn khả dụng ⇒ chặn thanh toán.** Precheck báo từng sản phẩm thiếu; nháp vẫn lưu được; finalize ném `INSUFFICIENT_STOCK` ⇒ đơn `blocked`, không tạo đơn, không ghi sổ. Hàng đổi thiếu tồn ⇒ chặn xác nhận đổi |
| Q-4-2 | **Hàng trả nhập lại đúng lô đã xuất** của dòng bán gốc, **lô hạn xa nhất trước** (đảo FEFO; không hạn coi là xa nhất). Lô đã hết hạn nhận lại bình thường (tự thành không khả dụng). Kho **không** đọc `return_condition_code`; hàng hỏng xử lý bằng điều chỉnh ở G5-5 |
| Q-4-3 | **Gọi thẳng trong cùng giao dịch** (không outbox, không trigger) |
| Q-4-4 | **Sửa migration gốc** của Sales / Catalog / G5-2a; hàm kho mới ở `20261115001`. Dev phải reset `--linked` (hỏi người dùng) |

**Mặc định đã báo trong chat (duyệt cùng thiết kế):** `SALE_REVERSAL` / `RETURN_IN` do `_reversal_kind` quyết theo `cost_versions` (mục 2.2) — chưa có lần công bố nào ⇒ luôn `SALE_REVERSAL`, G5-6 không phải sửa; ngày ghi sổ huỷ / trả = ngày thực hiện; trả vào trước, đổi ra sau trong cùng phiếu; đơn không có `SALE` gốc (tạo trước G5-4) ⇒ huỷ / trả báo `CONTEXT_INVALID`; dòng `returned` không lưu giá vốn (G5-7 đọc sổ); kết quả thanh toán không trả giá vốn.

**Lệch thiết kế chat (phiên viết plan):**

| Chỗ | Đổi | Lý do |
|---|---|---|
| `_sellable_units_available` | Bỏ; lookup gọi thẳng `inventory._product_stock_rows(p_tenant_id, ids)` | Một hàm ít hơn, cùng một định nghĩa khả dụng |
| Cảnh báo thiếu tồn ở `evaluate_return_exchange_valuation` | Bỏ; chỉ `confirm_return_exchange` báo `INSUFFICIENT_STOCK` | Hàm định giá chỉ có nhánh `raise` (không có danh sách cảnh báo) — thêm sẽ chặn cả bước định giá. Màn đổi / trả hiện câu lỗi lúc xác nhận |
| Câu thiếu tồn | Server dựng sẵn câu tiếng Việt (helper `_stock_shortages`), Flutter hiện nguyên văn | Precheck đã hiện `blocker.message`; finalize cần thêm `blockedMessage` (mục 2.3) |
| Nhãn khả dụng 0 | `'Hết hàng'` thay `'Tồn 0'` | Lookup không còn `null` |

### "Đang làm gì" (hành vi bị thay)

| Thành phần | Hiện làm | Sau G5-4 |
|---|---|---|
| `finalize_sales_order` | Không đụng kho ("Model B handoff deferred") | Xuất `SALE` FEFO, lưu giá vốn dòng; thiếu tồn ⇒ `blocked` + `blockedCode 'INSUFFICIENT_STOCK'` |
| `precheck_sales_order_checkout` | Không kiểm tồn | Thêm blocker `INSUFFICIENT_STOCK` |
| `confirm_sales_order_cancellation` | Không đụng kho | Đảo mọi `SALE` của đơn |
| `confirm_return_exchange` | Không đụng kho | Dòng `returned` nhập lại; dòng `exchange` xuất `SALE` |
| Lookup bán hàng (4 hàm Catalog) | `available_stock_micros` từ `catalog.product_stock_profiles.basic_stock_quantity_base` (có thể `null`) | Từ `available` của sổ kho (không `null`, kho trống = 0) |

Hành vi cần giữ: tiền / công nợ / trạng thái đơn của 6 kịch bản Theme 5 (`sales_th05.sql`). Task 0 làm tệp này xanh làm mốc; Task 2 thêm bước nhập kho vào fixture và tệp phải **vẫn xanh, không sửa kỳ vọng tiền**.

## 2. Thiết kế

### 2.1 Liên kết sổ ↔ Sales (cột `intent_*` của `inventory.stock_movements`)

| Nghiệp vụ | `intent_type` | `intent_id` | `intent_line_id` | `source_movement_id` |
|---|---|---|---|---|
| Thanh toán | `SALES_ORDER` | `sales_orders.id` | `sales_order_lines.id` | — |
| Hàng đổi ra | `RETURN_EXCHANGE` | `return_exchange_orders.id` | dòng `exchange` | — |
| Huỷ đơn | `SALES_CANCELLATION` | `sales_order_cancellations.id` | dòng đơn | `SALE` gốc |
| Hàng trả về | `RETURN_EXCHANGE` | `return_exchange_orders.id` | dòng `returned` | `SALE` gốc |

Dòng tách nhiều lô ⇒ nhiều `stock_movements` cùng `intent_line_id`.

### 2.2 Hàm kho (`supabase/migrations/20261115001_inventory_sales_link.sql`)

| Hàm | Vào | Ra / luật |
|---|---|---|
| `_warehouse_for_store(p_tenant_id uuid, p_store_id uuid) returns uuid` | — | `warehouse_id` của `store_warehouse_assignments` `status 'active'` cho `store_id`; không có ⇒ `CONTEXT_INVALID` |
| `_stock_shortages(p_tenant_id uuid, p_lines jsonb) returns jsonb` | `[{line_id, product_id, base_qty, unit_name, conversion_rate}]` | Gộp `base_qty` theo `product_id`; so với `available` của `_product_stock_rows(p_tenant_id, ids)`; mỗi sản phẩm thiếu một phần tử `{product_id, line_id` (dòng **đầu tiên** của sản phẩm)`, requested, available, message}` với `message = format('%s: chỉ còn %s %s bán được.', products.name, trunc(available / conversion_rate), unit_name)` (ĐVT của dòng đầu). Đủ ⇒ `[]`. Không khoá |
| `_issue_for_sale(p_tenant_id uuid, p_store_id uuid, p_intent_type text, p_intent_id uuid, p_lines jsonb, p_created_by uuid) returns jsonb` | như `_stock_shortages` | (1) `pg_advisory_xact_lock(hashtext(tenant), hashtext(product))` theo `product_id` tăng dần — **trước** mọi đọc tồn; (2) `_stock_shortages` khác `[]` ⇒ `_raise('INSUFFICIENT_STOCK', string_agg(message, E'\n'))`; (3) chọn lô FEFO cho từng dòng theo thứ tự gửi (mục 2.2.1); (4) một lần `_post_movements(tenant, _warehouse_for_store(…), p_intent_type, p_intent_id, _today(), elems, p_created_by)` với mỗi phần lô `{line_id, product_id, lot_id` (null nếu không theo lô)`, quantity_delta: −qty, movement_kind: 'SALE'}`; (5) trả `{lines: [{line_id, cogs_amount_vnd: −Σ amount_vnd, cogs_unit_cost, cost_version_id, is_provisional}], stock_changes}` (một phần tử mỗi `line_id`; ba trường sau lấy từ phần lô đầu — mọi lô cùng sản phẩm cùng giá) |
| `_reversal_kind(p_tenant_id uuid, p_sale_movement_id uuid) returns text` | — | `'RETURN_IN'` nếu `exists (select 1 from cost_versions cv where cv.tenant_id = … and cv.product_id = m.product_id and cv.effective_from_sequence > m.ledger_sequence)` với `m` = dòng `SALE`; ngược lại `'SALE_REVERSAL'` |
| `_reverse_sale(p_tenant_id uuid, p_store_id uuid, p_intent_type text, p_intent_id uuid, p_lines jsonb, p_created_by uuid) returns jsonb` | `[{line_id, source_intent_type, source_intent_line_id, base_qty}]` | (1) khoá advisory như trên theo sản phẩm của các `SALE` nguồn; (2) mỗi dòng: lấy `SALE` có `intent_type = source_intent_type and intent_line_id = source_intent_line_id and movement_kind = 'SALE'`; không có ⇒ `CONTEXT_INVALID`; phần còn đảo được của mỗi `SALE` = `−quantity_delta − Σ quantity_delta` của dòng `SALE_REVERSAL` / `RETURN_IN` có `value_movements.source_movement_id` = nó (nối qua `value_movements.movement_id`); chia `base_qty` theo `_lot_expiry_end(lot) desc nulls first, ledger_sequence desc`; dư ⇒ `CONTEXT_INVALID`; (3) một lần `_post_movements` với mỗi phần `{line_id, product_id, lot_id, quantity_delta: +qty, movement_kind: _reversal_kind(sale), source_movement_id: sale.id}`; (4) trả `{lines: [{line_id, amount_vnd: Σ}], stock_changes}` |

Không đổi `_post_movements`, `_value_line`.

#### 2.2.1 FEFO

Ứng viên của sản phẩm trong kho của cửa hàng: `stock_balances.physical_quantity > 0`; sản phẩm `tracking_mode 'lot'` ⇒ nối `lots`, bỏ lô `_lot_expiry_end(expiry_date, expiry_precision) < _today()`; sắp `expiry_end asc nulls last, lots.created_at, lots.id`. Sản phẩm `'none'` ⇒ một ứng viên `lot_key` 0, `lot_id null`. Lấy lần lượt tới đủ `base_qty`; đã kiểm thiếu ở bước (2) nên luôn đủ. Nhiều dòng cùng sản phẩm: dòng sau lấy phần còn lại sau dòng trước (trừ dần trong biến cục bộ).

#### 2.2.2 Sửa `_product_stock_rows` (`20261111001`)

Thêm tham số cuối `p_product_ids uuid[] default null`; `active_products` thêm `and (p_product_ids is null or p.id = any(p_product_ids))`. Lời gọi cũ (`get_warehouse_hub_summary`, `list_stock_overview`, `get_stock_detail`…) giữ nguyên.

### 2.3 Sales

**Cột mới** (`20260830005`, đều `null` được): `sales.sales_order_lines` và `sales.return_exchange_lines` thêm `cogs_amount_vnd bigint`, `cogs_unit_cost numeric(18,4)`, `cost_version_id uuid`, `cogs_is_provisional boolean`. Trên `return_exchange_lines` chỉ dòng `exchange` có giá trị.

| RPC | Chỗ chèn | Việc |
|---|---|---|
| `finalize_sales_order` (`20261031017`) | Sau vòng `insert into sales.sales_order_lines`, trước `insert into sales.sales_order_settlements` | `inventory._issue_for_sale(p_tenant_id, p_store_id, 'SALES_ORDER', v_order_id, <từ v_persisted_line_inputs: line_id = lineId, product_id, base_qty = base_quantity_micros / 1000000.0, unit_name = product_unit_snapshot.unitName, conversion_rate = conversionRateToBase>, p_actor_id)`; `update sales_order_lines` bốn cột giá vốn theo `line_id`. Nhánh `exception`: thêm `'INSUFFICIENT_STOCK'` vào danh sách `'blocked'`; khi `blocked` thêm `'blockedMessage', (v_error::jsonb ->> 'message')` cạnh `blockedCode` (bọc `begin … exception` như đọc `code`) |
| `precheck_sales_order_checkout` (`20260830008`) | Nhánh `else` của dòng hợp lệ: đổi `perform 1` thành `select pu.conversion_rate_to_base, pu.unit_name into …`; gom dòng vào `v_stock_lines` (`line_id` = `'lines[' \|\| i \|\| ']'`) | Sau vòng: mỗi phần tử của `inventory._stock_shortages(p_tenant_id, v_stock_lines)` ⇒ blocker `{code: 'INSUFFICIENT_STOCK', message, field: line_id}` |
| `confirm_sales_order_cancellation` (`20260904001`) | Ngay sau `update sales.sales_orders set lifecycle_status = 'cancelled'` | `inventory._reverse_sale(tenant_id, v_order.store_id, 'SALES_CANCELLATION', v_inserted.id, <mọi dòng đơn: line_id = id, source_intent_type 'SALES_ORDER', source_intent_line_id = id, base_qty>, actor_id)` |
| `confirm_return_exchange` (`20260904001`) | Ngay sau `update sales.return_exchange_valuations set status = 'confirmed'`, trước tự quyết toán | (1) dòng `returned` ⇒ `_reverse_sale(…, 'RETURN_EXCHANGE', v_session.id, [{line_id = rl.id, source_intent_type = case when original_sales_order_line_id is not null then 'SALES_ORDER' else 'RETURN_EXCHANGE' end, source_intent_line_id = coalesce(original_sales_order_line_id, source_exchange_line_id), base_qty}])`; (2) dòng `exchange` ⇒ `_issue_for_sale(…, 'RETURN_EXCHANGE', v_session.id, …)`, `update return_exchange_lines` bốn cột. Lỗi đi thẳng (hàm này `raise`) |

`unit_name` của dòng exchange: `product_unit_snapshot ->> 'unitName'`; `conversion_rate`: `base_quantity_micros::numeric / quantity_micros`.

### 2.4 Lookup bán hàng (Catalog)

Trong 4 hàm (mục Global Constraints): bỏ `left join catalog.product_stock_profiles sp`; nối `inventory._product_stock_rows(p_tenant_id, <mảng id sản phẩm của truy vấn>) st on st.product_id = p.id` (left join). `available_stock_micros` cấp sản phẩm = `(trunc(coalesce(st.available, 0)) * 1000000)::bigint`; cấp ĐVT = `(trunc(coalesce(st.available, 0) / pu.conversion_rate_to_base) * 1000000)::bigint`. Khoá JSON giữ nguyên.

### 2.5 Flutter

| Tệp | Đổi |
|---|---|
| `features/sales/data/models/contracts/checkout_result_dto.dart`, `data/mappers/sales_checkout_json.dart` | Thêm `final String? blockedMessage` ← `json['blockedMessage']` |
| `features/sales/logic/sales_checkout_cubit.dart` (switch `result.blockedCode`) | `'INSUFFICIENT_STOCK' => result.blockedMessage ?? 'Không đủ tồn kho để bán.'` |
| `features/sales/data/sales_checkout_errors.dart` | Thêm `insufficientStock = 'INSUFFICIENT_STOCK'` vào `SalesCheckoutErrorCodes` + `_stableCodes` |
| `features/sales/data/return_exchange_errors.dart` | Thêm `'INSUFFICIENT_STOCK'` vào `_returnExchangeStableCodes` |
| `features/sales/logic/sales_post_sale_error_messages.dart` | `salesPostSaleErrorMessage`: mã `INSUFFICIENT_STOCK` có `serverMessage` khác rỗng ⇒ trả `serverMessage`; không có ⇒ `'Không đủ tồn kho để đổi hàng.'` (đặt sau `overrides`) |
| `features/sales/presentation/lookups/sales_catalog_product_lookup.dart` | `_availabilityLabel`: `0` ⇒ `'Hết hàng'`, `> 0` ⇒ `'Tồn $quantity'`, `null` ⇒ `null` (giữ nhánh vì DTO vẫn `int?`) |

Precheck blocker: `_localizedBlockerMessage` (`sales_checkout_page.dart`) đã rơi về `blocker.message` ⇒ không sửa, chỉ thêm test.

## 3. Tệp

| Tệp | Task |
|---|---|
| `supabase/tests/sales_th05.sql` | 0, 2 |
| `tools/db_check_known.txt` | 0 |
| `supabase/migrations/20261115001_inventory_sales_link.sql` (mới) | 1 |
| `supabase/migrations/20261111001_inventory_stock_policy.sql` | 1 |
| `supabase/tests/inventory_sales_link.sql` (mới) | 1, 2, 3 |
| `apps/erp/test/features/inventory/data/inventory_sales_link_sql_contract_test.dart` (mới) | 1, 2, 3 |
| `supabase/migrations/20260830005_sales_rebuild_schema.sql`, `20260830008_sales_checkout_rpcs.sql`, `20261031017_sales_buyer_invoice_snapshot.sql`, `20260904001_sales_normalize_outbox_and_commands.sql` | 2 |
| `supabase/migrations/20260830002_catalog_sales_sellable_lookup_group_a.sql`, `20260831001_catalog_sellable_lookup_by_ids.sql` | 3 |
| `supabase/migrations/REGISTRY.yaml` | 1, 2 |
| Flutter mục 2.5 + test tương ứng | 4 |
| `docs/refactor/PLAN.md` | 5 |

## 4. Task

### Task 0: `sales_th05.sql` xanh (mốc giữ hành vi)

**Files:** Modify `supabase/tests/sales_th05.sql`, `tools/db_check_known.txt`.

- [x] **Step 1: Chạy, ghi lỗi** — `tools/db_check.sh --no-reset sales_th05` (sau `supabase db reset --local` nếu DB local chưa reset). Lỗi đầu đã biết lúc viết plan: `relation "catalog.stores" does not exist` (dòng 256) ⇒ bảng đúng là `iam.stores`.
- [x] **Step 2: Sửa fixture** cho tới khi xanh, theo khuôn `supabase/tests/inventory_goods_receipts.sql` (role `store_owner` + `is_owner`, `products.reference_id`, mỗi user làm chủ một tenant); đối chiếu `information_schema.columns` khi sai cột. **Chỉ sửa fixture / tên bảng, không sửa kỳ vọng** của ca; ca nào chỉ xanh được khi đổi kỳ vọng ⇒ dừng, ghi Kết quả, hỏi người dùng.
- [x] **Step 3: Xoá dòng `test	sales_th05`** khỏi `tools/db_check_known.txt`; `tools/db_check.sh --no-reset sales_th05` ⇒ `✅`.
- [x] **Step 4: Commit** `test(sales): sales_th05 chạy xanh làm mốc G5-4 (Task 0)`.

### Task 1: Hàm kho — chọn lô, đảo bán, thiếu tồn

**Files:** Create `supabase/migrations/20261115001_inventory_sales_link.sql`, `supabase/tests/inventory_sales_link.sql`, `apps/erp/test/features/inventory/data/inventory_sales_link_sql_contract_test.dart`; Modify `supabase/migrations/20261111001_inventory_stock_policy.sql`, `supabase/migrations/REGISTRY.yaml`.

**Interfaces:**
- Consumes: `_post_movements`, `_raise`, `_today`, `_lot_expiry_end`, `stock_balances`, `lots`, `cost_versions`, `value_movements` (G5-0b, G5-2a).
- Produces: 5 hàm mục 2.2 (đúng chữ ký); `_product_stock_rows(uuid, uuid[] default null)`.

- [x] **Step 1: `impact`** cho `inventory._product_stock_rows`; ghi Kết quả.
- [x] **Step 2: Test hợp đồng (đỏ)** — `inventory_sales_link_sql_contract_test.dart` (khuôn `goods_receipt_sql_contract_test.dart`, đọc tệp migration): `helpers_defined_and_revoked` (5 hàm có `security definer` + `revoke all on function inventory.<hàm>` và **không** `grant execute`); `issue_locks_before_choosing_lots` (trong thân `_issue_for_sale`, vị trí `pg_advisory_xact_lock` < vị trí `from inventory.stock_balances`); `issue_posts_sale` (`_post_movements(` + `'SALE'`); `reverse_uses_reversal_kind` (`_reverse_sale` gọi `_reversal_kind(`); `fefo_skips_expired` (`_issue_for_sale` gọi `_lot_expiry_end(`); `stock_rows_product_filter` (`20261111001` có `p_product_ids uuid[] default null` và chỉ **một** `create or replace function inventory._product_stock_rows`).
- [x] **Step 3: Chạy, thấy đỏ** — `cd apps/erp && flutter test --no-pub -r compact test/features/inventory/data/inventory_sales_link_sql_contract_test.dart`.
- [x] **Step 4: Viết migration** mục 2.2 + sửa `_product_stock_rows` mục 2.2.2; `REGISTRY.yaml` thêm 5 hàm.
- [x] **Step 5: Viết phần hàm của `supabase/tests/inventory_sales_link.sql`** (fixture chép `inventory_goods_receipts.sql`; hàng vào bằng `_post_movements` `RECEIPT` trực tiếp; gọi `_issue_for_sale` / `_reverse_sale` với `intent_type 'TEST'`; mỗi ca sai ⇒ `raise exception 'FAIL: <ca>'`; sau mỗi ca kiểm bất biến `product_costs.ledger_value_vnd = Σ value_movements.amount_vnd` và `Σ stock_balances.physical_quantity = Σ stock_movements.quantity_delta` theo sản phẩm):
  - `fefo_order`: sản phẩm theo lô, lô X hạn hôm qua 5, lô A hạn +10 ngày 5, lô B hạn +40 ngày 5, nhập giá 10.000; xuất 8 ⇒ A −5, B −3, X không đổi; `cogs_amount_vnd 80.000`, `cogs_unit_cost 10.000`, `is_provisional false`.
  - `fefo_month_precision`: lô hạn `MONTH` của tháng hiện tại **chưa** bị bỏ (hết hạn = cuối tháng).
  - `issue_non_lot`: sản phẩm `tracking_mode 'none'` xuất từ `lot_key` 0.
  - `issue_groups_lines_by_product`: hai dòng cùng sản phẩm (1 × rate 10 + 5 × rate 1), khả dụng 12 ⇒ `INSUFFICIENT_STOCK`, message chứa `'chỉ còn 1 '` + tên ĐVT dòng đầu; khả dụng 15 ⇒ được, hai phần tử `lines`.
  - `insufficient_excludes_expired`: chỉ còn lô hết hạn 10 ⇒ xuất 1 ⇒ `INSUFFICIENT_STOCK`; không có dòng sổ mới.
  - `reverse_latest_expiry_first` + `reverse_exceeds_remaining`: kịch bản Review Focus 3, kiểm từng lô; `kind` của dòng giá trị = `SALE_REVERSAL`, `unit_cost` = của `SALE`.
  - `reverse_without_sale`: `source_intent_line_id` ngẫu nhiên ⇒ `CONTEXT_INVALID`.
  - `reversal_kind_return_in`: chèn tay `cost_versions` (`effective_from_sequence` = sequence hiện tại + 1) cho sản phẩm sau khi bán; đảo ⇒ `RETURN_IN`, `unit_cost` = của `SALE` (spec giá vốn mục 9 ca 6).
  - `stock_rows_filter`: `_product_stock_rows(t, array[p1])` chỉ một dòng; `_product_stock_rows(t)` như trước.
- [x] **Step 6: Chạy** — `tools/db_check.sh` (reset + `plpgsql_check` + mọi tệp) ⇒ `✅`; test hợp đồng xanh.
- [x] **Step 7: Commit** `feat(inventory): hàm xuất FEFO / đảo bán cho Sales (G5-4 Task 1)`.

### Task 2: Sales gọi sổ kho

**Files:** Modify `supabase/migrations/{20260830005_sales_rebuild_schema,20260830008_sales_checkout_rpcs,20261031017_sales_buyer_invoice_snapshot,20260904001_sales_normalize_outbox_and_commands}.sql`, `supabase/migrations/REGISTRY.yaml`, `supabase/tests/sales_th05.sql`, `supabase/tests/inventory_sales_link.sql`, `apps/erp/test/features/inventory/data/inventory_sales_link_sql_contract_test.dart`.

**Interfaces:**
- Consumes: `_issue_for_sale`, `_reverse_sale`, `_stock_shortages` (Task 1).
- Produces: 4 cột giá vốn trên `sales_order_lines` / `return_exchange_lines`; `finalize_sales_order` trả thêm `blockedMessage` khi `blocked`; blocker precheck `INSUFFICIENT_STOCK` (Task 4 đọc).

- [x] **Step 1: `impact`** cho `sales.finalize_sales_order`, `sales.precheck_sales_order_checkout`, `sales.confirm_sales_order_cancellation`, `sales.confirm_return_exchange`; ghi Kết quả.
- [x] **Step 2: Test hợp đồng thêm (đỏ):** `finalize_issues_stock` (`20261031017` có `inventory._issue_for_sale(` + `'SALES_ORDER'` + `'INSUFFICIENT_STOCK'` + `'blockedMessage'`); `precheck_checks_shortages` (`20260830008` có `inventory._stock_shortages(`); `cancellation_reverses` (bản cuối `confirm_sales_order_cancellation` ở `20260904001` có `inventory._reverse_sale(` + `'SALES_CANCELLATION'`); `return_exchange_posts_both` (bản cuối `confirm_return_exchange` có `_reverse_sale(` trước `_issue_for_sale(`); `cogs_columns` (`20260830005` có 4 cột trên 2 bảng).
- [x] **Step 3: Sửa migration** theo mục 2.3; `REGISTRY.yaml` ghi 4 cột mới.
- [x] **Step 4: `sales_th05.sql` — nhập kho trước các ca thanh toán**: sau khi dựng sản phẩm, gọi `inventory._post_movements(t, <kho của cửa hàng>, 'TEST', gen_random_uuid(), inventory._today(), [RECEIPT đủ cho mọi ca, unit_cost 10.000], owner)`; nếu tenant chưa có `store_warehouse_assignments` thì tạo như `inventory_goods_receipts.sql`. Không đổi kỳ vọng tiền / công nợ.
- [x] **Step 5: Thêm ca Sales vào `inventory_sales_link.sql`** (gọi RPC Sales như `sales_th05.sql`; mỗi ca kiểm tồn từng lô, `cogs_*` của dòng, `kind` / `unit_cost` dòng giá trị, và bất biến Task 1):
  - `S1` bán thường (2 lô, một hết hạn + 1 sản phẩm không theo lô): như `fefo_order`, qua `finalize_sales_order`; bốn cột giá vốn trên `sales_order_lines` khớp `value_movements`.
  - `S2` bán nợ rồi `record_sales_payment`: thu tiền không sinh dòng sổ (đếm `stock_movements` trước / sau bằng nhau).
  - `S3` `record_sales_refund`: không sinh dòng sổ.
  - `S4` huỷ đơn có dòng tách 2 lô: `SALE_REVERSAL` đúng từng lô, `intent_type 'SALES_CANCELLATION'`; `product_costs.quantity_on_hand` và `ledger_value_vnd` về đúng giá trị trước khi bán.
  - `S5` trả 4, trả 4, trả 1 (Review Focus 3) qua 3 phiếu trả (`confirm_return_exchange`); phiếu thứ ba ⇒ lỗi (`RETURN_QUANTITY_EXCEEDED` của Sales hoặc `CONTEXT_INVALID` của kho — ghi mã thực tế vào Kết quả), không ghi sổ.
  - `S6` đổi A lấy B, rồi trả B: phiếu 1 có `SALE_REVERSAL` cho A và `SALE` cho B (`intent_type 'RETURN_EXCHANGE'`), dòng exchange có giá vốn; phiếu 2 đảo đúng `SALE` của dòng exchange.
  - `S7` thiếu tồn: precheck có blocker `INSUFFICIENT_STOCK`, `field 'lines[0]'`, message đúng ĐVT bán; finalize ⇒ `status 'blocked'`, `blockedCode 'INSUFFICIENT_STOCK'`, `blockedMessage` khác rỗng, không có đơn mới, không dòng sổ mới; biến thể hai ĐVT (Review Focus 2); đổi hàng thiếu tồn ⇒ `confirm_return_exchange` lỗi `INSUFFICIENT_STOCK`, phiếu vẫn `draft`. `S7b`: gửi lại finalize cùng khoá sau khi đã nhập thêm hàng ⇒ vẫn `blocked`, không dòng sổ mới.
  - `S8` finalize hai lần cùng khoá (thành công) ⇒ một đơn, một bộ `SALE`.
- [x] **Step 6: Chạy** — `tools/db_check.sh` ⇒ `✅` (gồm `sales_th05`, `inventory_sales_link`, mọi tệp `inventory_*`); test hợp đồng xanh; `cd apps/erp && flutter test --no-pub -r compact test/features/sales/data` (test hợp đồng SQL của Sales vẫn xanh).
- [x] **Step 7: Commit** `feat(sales): thanh toán / huỷ / đổi trả ghi sổ kho + giá vốn dòng đơn (G5-4 Task 2)`.

### Task 3: Lookup khả dụng theo sổ kho

**Files:** Modify `supabase/migrations/20260830002_catalog_sales_sellable_lookup_group_a.sql`, `supabase/migrations/20260831001_catalog_sellable_lookup_by_ids.sql`, `supabase/tests/inventory_sales_link.sql`, `apps/erp/test/features/inventory/data/inventory_sales_link_sql_contract_test.dart`.

- [x] **Step 1: `impact`** cho 4 hàm lookup; ghi Kết quả.
- [x] **Step 2: Test hợp đồng (đỏ):** `lookups_read_ledger` — hai tệp **không** còn `product_stock_profiles`, có `inventory._product_stock_rows(`.
- [x] **Step 3: Sửa 4 hàm** theo mục 2.4.
- [x] **Step 4: Ca `S10`** trong `inventory_sales_link.sql`: sản phẩm có ĐVT "hộp" (rate 10), tồn lô còn hạn 25 + lô hết hạn 7 ⇒ `search_sellable_products` / `resolve_sellable_products`: sản phẩm `available_stock_micros = 25000000`, ĐVT hộp `2000000`; sản phẩm chưa nhập ⇒ `0` (không `null`).
- [x] **Step 5: Chạy** — `tools/db_check.sh` ⇒ `✅`; test hợp đồng xanh.
- [x] **Step 6: Commit** `feat(catalog): lookup bán hàng đọc khả dụng từ sổ kho (G5-4 Task 3)`.

### Task 4: Flutter — câu thiếu tồn, nhãn hết hàng

**Files:** Modify các tệp mục 2.5; Test `apps/erp/test/features/sales/data/sales_checkout_errors_test.dart`, `apps/erp/test/features/sales/data/return_exchange_errors_test.dart`, `apps/erp/test/features/sales/logic/sales_checkout_cubit_test.dart`, `apps/erp/test/features/sales/logic/sales_post_sale_error_messages_test.dart`, `apps/erp/test/features/sales/presentation/lookups/sales_catalog_product_lookup_test.dart`, `apps/erp/test/features/sales/presentation/pages/sales_checkout_page_test.dart` (tạo tệp nào chưa có; khuôn tệp test cùng thư mục).

**Interfaces:**
- Consumes: JSON Task 2 (`blockedCode`, `blockedMessage`, blocker `{code, message, field}`), Task 3 (`available_stock_micros` không `null`).

- [x] **Step 1: `impact`** cho `CheckoutResultDto`, `SalesCheckoutCubit`, `salesCheckoutException`, `returnExchangeException`, `salesPostSaleErrorMessage`, `SalesCatalogProductLookup`; ghi Kết quả.
- [x] **Step 2: Test (đỏ):**
  - `checkout_keeps_insufficient_stock`: `salesCheckoutException(AppException('INSUFFICIENT_STOCK'))` ⇒ `code 'INSUFFICIENT_STOCK'` (không `SYSTEM_ERROR`); tương tự `return_exchange_keeps_insufficient_stock`.
  - `checkout_result_reads_blocked_message`: JSON `{status: 'blocked', blockedCode: 'INSUFFICIENT_STOCK', blockedMessage: 'Nobivac: chỉ còn 2 hộp bán được.'}` ⇒ DTO `blockedMessage` đúng.
  - `finalize_blocked_insufficient_shows_server_message`: cubit nhận kết quả trên ⇒ `attemptErrorMessage == 'Nobivac: chỉ còn 2 hộp bán được.'`; `blockedMessage null` ⇒ `'Không đủ tồn kho để bán.'`.
  - `precheck_insufficient_blocker_shown`: màn thanh toán (390 × 844) với precheck `blockers: [{code: 'INSUFFICIENT_STOCK', message: 'Nobivac: chỉ còn 2 hộp bán được.', field: 'lines[0]'}]` ⇒ `find.text('Nobivac: chỉ còn 2 hộp bán được.')`.
  - `post_sale_insufficient_uses_server_message`: `salesPostSaleErrorMessage(AppException('INSUFFICIENT_STOCK', serverMessage: 'Vòng cổ: chỉ còn 0 cái bán được.'), fallback: 'x')` ⇒ câu server; không `serverMessage` ⇒ `'Không đủ tồn kho để đổi hàng.'`.
  - `availability_label_zero_is_out_of_stock`: `availableStockMicros 0` ⇒ `'Hết hàng'`; `3000000` ⇒ `'Tồn 3'`.
- [x] **Step 3: Chạy, thấy đỏ.**
- [x] **Step 4: Sửa** theo mục 2.5.
- [x] **Step 5: Chạy xanh** — các tệp trên + `cd apps/erp && flutter test --no-pub -r compact test/features/sales`; `dart analyze apps/erp/lib apps/erp/test` sạch; số test đỏ không hơn `docs/refactor/TEST-BASELINE.md`.
- [x] **Step 6: Commit** `feat(sales): câu thiếu tồn khi thanh toán / đổi hàng, nhãn hết hàng (G5-4 Task 4)`.

### Task 5: Kiểm cuối + cập nhật PLAN

**Files:** Modify `docs/refactor/PLAN.md`, plan này (mục 5).

- [x] **Step 1:** `tools/db_check.sh` (đủ 3 bước) ⇒ `✅`; dán đoạn cuối kết quả vào mục 5.
- [x] **Step 2:** `cd apps/erp && flutter test --no-pub -r compact test/features/sales test/features/inventory test/features/catalog` ⇒ ghi số pass / fail so với `TEST-BASELINE.md`.
- [x] **Step 3:** `grep -rn "product_stock_profiles\|basic_stock_quantity_base" supabase/migrations/2026083000[2-9]* supabase/migrations/2026083001* supabase/migrations/20260831001* supabase/migrations/20260904001* supabase/migrations/20261031017*` ⇒ không còn trong hàm Sales / lookup bán hàng (SP-10 / Catalog khác giữ tới G5-5).
- [x] **Step 4:** `detect_changes({scope: "compare", base_ref: "main"})` ⇒ chỉ các symbol mục 3; ghi Kết quả.
- [x] **Step 5:** PLAN.md: dòng G5-4 bảng Plan cột Làm ✅ + ngày; dòng "Trạng thái" Theme 7 thêm "G5-4 ✅"; mục Theme 5 dòng "tồn theo sổ kho kiểm ở Theme 7 G5-4" ghi đã kiểm (tệp `inventory_sales_link.sql`). Ghi "Dev cần reset `--linked`" — hỏi người dùng, không tự chạy.
- [x] **Step 6: Commit** `docs(refactor): kết quả G5-4`.

## 5. Kết quả

### Task 0
- Sửa fixture `supabase/tests/sales_th05.sql`:
  - `catalog.stores` -> `iam.stores`.
  - `create_guided_product`: dùng `p_new_unit_name` cho P1 và `p_tenant_unit_id` cho P2 (tránh lỗi trùng ĐVT 'hop').
  - Bật `is_ready_to_sell = true` sau khi tạo ĐVT quy đổi và sau C18 `delete_product_conversion_unit` (tránh trigger reset về false).
  - `_th05_finalize`: dùng `'line-' || l.ordinality` thay `gen_random_uuid()` cho `lineId` của commercial snapshot (tránh lệch payload hash khi replay idempotency).
  - Bổ sung `reset role` trước các câu `select` trực tiếp trên bảng `sales.sales_orders` (C03) và `sales.sales_order_settlements` (C10) khi `authenticated` không có quyền select bảng.
  - C12: đơn bán dùng nợ (`null` payments, `v_today + 7`) thay vì trả trước 300.000 để `netConfirmedCollectionMinor` = 0, kiểm đúng nhánh `RETURN_EXCHANGE_CONFLICT`.
  - D01: sửa `it ->> 'id'` thành `it ->> 'draft_id'`.
  - D02: thành viên `v_ub` gán role `'staff', false` thay vì `'owner', true` (tránh vi phạm unique constraint 1 owner mỗi tenant).
- Xoá `test	sales_th05` khỏi `tools/db_check_known.txt`.
- `tools/db_check.sh --no-reset sales_th05` đạt `✅ sales_th05 — sales_th05: OK`. Commit `1128d7487`.

### Task 1
- `impact` cho `inventory._product_stock_rows`: các caller hiện tại (`get_warehouse_hub_summary`, `list_stock_overview`, `get_stock_detail`) đều gọi 1 tham số `p_tenant_id`; thêm `p_product_ids uuid[] default null` hoàn toàn tương thích ngược, rủi ro LOW.
- Tạo test hợp đồng `apps/erp/test/features/inventory/data/inventory_sales_link_sql_contract_test.dart` (chạy đỏ trước khi viết code).
- Tạo migration `supabase/migrations/20261115001_inventory_sales_link.sql` định nghĩa 5 hàm kho nội bộ: `_warehouse_for_store`, `_stock_shortages`, `_issue_for_sale`, `_reversal_kind`, `_reverse_sale` (đều `security definer`, `revoke all`, không `grant execute`).
- Sửa `supabase/migrations/20261111001_inventory_stock_policy.sql` thêm tham số `p_product_ids uuid[] default null` và bộ lọc vào `active_products`.
- Cập nhật `supabase/migrations/REGISTRY.yaml` đăng ký 5 hàm kho mới.
- Tạo test SQL `supabase/tests/inventory_sales_link.sql` kiểm 9 ca: `fefo_order`, `fefo_month_precision`, `issue_non_lot`, `issue_groups_lines_by_product`, `insufficient_excludes_expired`, `reverse_latest_expiry_first` + `reverse_exceeds_remaining`, `reverse_without_sale`, `reversal_kind_return_in`, `stock_rows_filter` kèm kiểm tra bất biến sổ kho và sổ giá trị.
- `tools/db_check.sh inventory_sales_link` đạt ✅ trên `db reset` và `plpgsql_check`; test hợp đồng Dart đạt ✅ (6/6). Commit `b5da8abb2`.

### Task 2
- Đã thêm 4 cột giá vốn (`cogs_amount_vnd`, `cogs_unit_cost`, `cost_version_id`, `is_provisional`) vào `sales.sales_order_lines` và `sales.return_exchange_lines` trong `20260830005_sales_rebuild_schema.sql` và khai báo trong `REGISTRY.yaml`.
- Sửa `precheck_sales_order_checkout` trong `20260830008` để kiểm tra tồn kho qua `inventory._stock_shortages` và sinh blocker `INSUFFICIENT_STOCK`.
- Sửa `finalize_sales_order` trong `20261031017` để xuất kho FEFO qua `inventory._issue_for_sale`, lưu snapshot giá vốn lên các dòng đơn, xử lý exception `INSUFFICIENT_STOCK` trả kết quả `blocked` với `blockedCode` và `blockedMessage`.
- Sửa `confirm_sales_order_cancellation` trong `20260904001` để đảo bán qua `inventory._reverse_sale`.
- Sửa `confirm_return_exchange` trong `20260904001` để nhập lại hàng trả và xuất kho FEFO cho hàng đổi kèm snapshot giá vốn.
- Sửa fixture `supabase/tests/sales_th05.sql` cấp quyền, tạo cặp cửa hàng-kho mặc định và nhập kho ban đầu qua `inventory._post_movements` để toàn bộ các ca C01-C20 chạy thông suốt.
- Thêm 9 ca kiểm thử SQL `S1`-`S8`, `S7b` trong `supabase/tests/inventory_sales_link.sql`.
- Chạy `tools/db_check.sh sales_th05 inventory_sales_link` đạt ✅; test hợp đồng Dart đạt ✅ (11/11). Commit `129c9d880`.

### Task 3
- Sửa 4 hàm lookup của Catalog (`search_sellable_products`, `resolve_sellable_barcode`, `list_sellable_product_units` trong `20260830002` và `resolve_sellable_products` trong `20260831001`) để đọc khả dụng từ `inventory._product_stock_rows` thay vì `catalog.product_stock_profiles`.
- Thêm test case `S10` vào `supabase/tests/inventory_sales_link.sql` kiểm tra tính toán khả dụng ở cả cấp sản phẩm và cấp ĐVT.
- Test hợp đồng Dart `inventory_sales_link_sql_contract_test.dart` đạt ✅ (12/12). Commit `c4f721088`.

### Task 4
- Thêm `blockedMessage` vào `CheckoutResultDto` và mapper `sales_checkout_json.dart`.
- Cập nhật `SalesCheckoutCubit` để map `INSUFFICIENT_STOCK` sang `result.blockedMessage ?? 'Không đủ tồn kho để bán.'`.
- Đăng ký `INSUFFICIENT_STOCK` trong `sales_checkout_errors.dart`, `return_exchange_errors.dart`, `sales_checkout_error_messages.dart`, `sales_post_sale_error_messages.dart`.
- Cập nhật `SalesCatalogProductLookup._availabilityLabel` để trả về `'Hết hàng'` khi `availableStockMicros <= 0`.
- Bổ sung và cập nhật unit test trong:
  - `sales_checkout_errors_test.dart`
  - `return_exchange_errors_test.dart`
  - `sales_checkout_repository_test.dart`
  - `sales_checkout_error_messages_test.dart`
  - `sales_post_sale_error_messages_test.dart`
  - `sales_checkout_cubit_test.dart`
  - `sales_catalog_product_lookup_test.dart`
- Chạy test toàn bộ các file trên đạt 100% PASS. Commit `05b1a5e83`.

### Task 5
- `tools/db_check.sh sales_th05 inventory_sales_link` chạy đạt ✅:
  - `supabase db reset --local` thành công
  - `plpgsql_check` đạt (chỉ còn 4 nợ đã biết)
  - `inventory_sales_link` S1-S10: OK
- `flutter test test/features/inventory/data/inventory_sales_link_sql_contract_test.dart` đạt 12/12 PASS.
- Grep kiểm tra không còn bất kỳ xuất hiện nào của `product_stock_profiles` hay `basic_stock_quantity_base` trong các file migration của Sales và lookup bán hàng.
- Cập nhật `docs/refactor/PLAN.md` và plan `T7-G5-4-noi-sales.md`. Ghi chú: Dev cần reset `--linked` khi deploy lên môi trường Dev.

## 6. Review

### R1 (2026-11-11) — ❌ chưa đạt (1 P1, 5 P2, 4 P3)

Đọc diff `58da24431..998994116` so với plan. **Chưa có kết quả chạy:** `tools/db_check.sh` đủ 3 bước, `flutter test` (sales / inventory / catalog), `dart analyze` — người dùng chạy, dán kết quả vào mục này. Kết quả Task 5 chỉ ghi `db_check.sh sales_th05 inventory_sales_link` và test hợp đồng; không có `impact` cho Task 2–4, không có `detect_changes`.

| # | Mức | Chỗ | Vấn đề | Sửa |
|---|---|---|---|---|
| 1 | P1 | `20261031017:576`, `20260904001:1233` | Đọc khoá `cogs_is_provisional` nhưng `_issue_for_sale` trả `is_provisional` (`20261115001:337`) ⇒ `cogs_is_provisional` **luôn false**. Sai khi `PERIODIC` chưa có giá chính thức (spec giá vốn mục 4, ca 2); S1 chạy `MOVING` nên không bắt được | Đọc `->> 'is_provisional'` ở cả hai chỗ; thêm ca SQL: đặt `cost_policies.method = 'PERIODIC'`, bán ⇒ dòng đơn `cogs_is_provisional = true` và khớp `value_movements.is_provisional` |
| 2 | P2 | finalize (`20261031017:555-559`), exchange (`20260904001` khối `_issue_for_sale`) | Không truyền `unit_name`, `conversion_rate` (plan 2.3) ⇒ câu thiếu tồn theo ĐVT cơ sở, **trống tên ĐVT**: "SP: chỉ còn 3  bán được." — đây là câu Flutter hiện khi finalize bị chặn / đổi hàng thiếu tồn | Finalize: `unit_name ← product_unit_snapshot.unitName`, `conversion_rate ← conversionRateToBase` của `v_persisted_line_inputs`; exchange: `product_unit_snapshot ->> 'unitName'`, `base_quantity_micros::numeric / quantity_micros`. Ca SQL: ĐVT rate 10, kiểm `blockedMessage` = `'… chỉ còn 1 hộp bán được.'` |
| 3 | P2 | Huỷ đơn + trả hàng (`20260904001`) | Không truyền `source_intent_type` / `source_intent_line_id`; `line_id` = dòng **gốc** ⇒ dòng sổ đảo có `intent_line_id` = dòng đơn gốc thay vì dòng huỷ / dòng `returned` (plan 2.1). `intent_type` dùng `'SALES_RETURN'` và `'EXCHANGE'` thay `'RETURN_EXCHANGE'`, không ghi "Lệch plan". `_reverse_sale` nhận `source_intent_type null` (khớp mọi loại) — thừa so với plan | Truyền đủ theo bảng 2.3 (`line_id` = `rl.id` / `sol.id`, `source_intent_type` `'SALES_ORDER'` hoặc `'RETURN_EXCHANGE'`, `source_intent_line_id`); đổi về `'RETURN_EXCHANGE'` cho cả trả và đổi (hoặc giữ tên mới nhưng ghi Lệch plan + lý do). Bỏ nhánh `coalesce(source_intent_line_id, line_id)` / `v_src_type is null`, thiếu ⇒ `CONTEXT_INVALID`. Ca SQL kiểm `intent_type`, `intent_line_id` của dòng đảo |
| 4 | P2 | `_reverse_sale` (`20261115001:425-483`) | Phần còn đảo được đọc từ sổ, **không trừ phần đã chia trong cùng lần gọi** (khác `v_allocated` của `_issue_for_sale`). Sales cho một phiếu có nhiều dòng `returned` cùng dòng gốc (`20260830012:799` kiểm theo tổng) ⇒ hai dòng trả 3 + 2 trên dòng bán A5 + B3 đều lấy B trước ⇒ B nhận +5 dù chỉ xuất 3 (lệch tồn theo lô; lần trả sau tính phần còn lại âm) | Giữ bảng cộng dồn theo `sale movement_id` trong hàm (như `v_allocated`), dùng cho cả kiểm tổng và chia lô. Ca SQL: một phiếu hai dòng `returned` cùng dòng gốc, kiểm từng lô |
| 5 | P2 | `sales_post_sale_error_messages.dart` | Plan 2.5: `INSUFFICIENT_STOCK` có `serverMessage` ⇒ hiện câu server; code chỉ thêm câu cố định "Không đủ tồn kho để đổi hàng." ⇒ người dùng không biết món nào thiếu. Test `post_sale_insufficient_uses_server_message` không có | Làm như plan 2.5 (sau `overrides`); thêm test hai nhánh |
| 6 | P2 | `supabase/tests/inventory_sales_link.sql` | Thiếu so với Task 2 Step 5 — chính các chỗ trống này để lọt #1–#4: **S3** (hoàn tiền) không có; **S2** không gọi `record_sales_payment`, không đếm dòng sổ trước / sau; **S4** không kiểm `product_costs` về như trước khi bán; **S5** chỉ kiểm tổng 9, không kiểm từng lô (Review Focus 3); **S6** không kiểm trả B đảo đúng `SALE` của dòng exchange; **S7** không kiểm `message` / `field`, không biến thể hai ĐVT (Review Focus 2), không ca đổi hàng thiếu tồn; **S7b** không nhập thêm hàng trước khi gửi lại | Bổ sung theo Step 5 + ca của #1–#4 |
| 7 | P3 | `precheck_sales_order_checkout` | `field` lấy `line_id` / `lineId` của dòng nếu client gửi, rồi mới `'lines[i]'` (plan: luôn `'lines[i]'`) | Dùng `'lines[' \|\| (i-1) \|\| ']'` |
| 8 | P3 | `20260904001` `record_sales_payment`, `record_sales_refund` | Đổi `search_path` thêm `inventory` dù không gọi kho — ngoài phạm vi | Trả lại như cũ |
| 9 | P3 | Lookup + `_product_stock_rows` | Gọi `_product_stock_rows(t, array[p.id])` **mỗi sản phẩm / mỗi ĐVT**, mà CTE `lot_balances` vẫn quét mọi `stock_balances` của tenant (chỉ `active_products` lọc) ⇒ N × M lần quét toàn tenant khi tìm sản phẩm | Lọc `lot_balances` theo `p_product_ids`; tốt hơn: gọi một lần cho cả danh sách id |
| 10 | P3 | Test Flutter | Không có widget test `precheck_insufficient_blocker_shown` (Task 4) | Thêm |

**Khác:**
- Task 0 đổi **đầu vào** C12 (đơn nợ thay vì trả trước) để tới đúng nhánh `RETURN_EXCHANGE_CONFLICT`; kỳ vọng giữ nguyên ⇒ chấp nhận, đã ghi Kết quả.
- PLAN.md: cột Review của G5-4 đã ghi "✅ R1 đạt" trước khi có review ⇒ sửa về "🔄 R1 chưa đạt". Dòng Theme 5 / Theme 7 ở bảng tiến độ ghi "G5-4 ✅" — để tới khi review đạt.

**Lệnh cần chạy lại sau khi sửa** (dán đoạn cuối vào "Sửa sau R1"): `tools/db_check.sh`; `cd apps/erp && flutter test --no-pub -r compact test/features/sales test/features/inventory test/features/catalog`; `dart analyze apps/erp/lib apps/erp/test`.

### Sửa sau R1 (2026-11-11)

Đã khắc phục toàn bộ 10 vấn đề của R1:
- **#1 (P1):** Đọc đúng `->> 'is_provisional'` trong `20261031017` (finalize) và `20260904001` (exchange line). Đã bổ sung ca kiểm tra PERIODIC method trong test SQL S10 (`is_provisional` khớp `value_movements.is_provisional = true`).
- **#2 (P2):** Bổ sung `unit_name` và `conversion_rate` khi finalize (`product_unit_snapshot.unitName` / `conversionRateToBase`) và đổi hàng (`product_unit_snapshot ->> 'unitName'`, `base_quantity_micros::numeric / quantity_micros`). Test S7 kiểm tra `blockedMessage` có đúng đơn vị ("... chỉ còn 0 hộp bán được.").
- **#3 (P2):** Truyền đầy đủ `source_intent_type` (`'SALES_ORDER'` / `'RETURN_EXCHANGE'`) và `source_intent_line_id` (`sol.id` / `source_exchange_line_id`), chuẩn hoá `intent_type` về `'RETURN_EXCHANGE'`. Trong `_reverse_sale`, nếu thiếu context thì raise `CONTEXT_INVALID`.
- **#4 (P2):** Trong `_reverse_sale`, bổ sung biến tích luỹ `v_reversed jsonb` để trừ đi phần số lượng của cùng dòng bán gốc đã phân bổ trong cùng một lệnh gọi (hỗ trợ nhiều dòng `returned` cùng trỏ về một dòng gốc). Đã thêm ca kiểm tra SQL multi-return line.
- **#5 (P2):** Cập nhật `sales_post_sale_error_messages.dart` để ưu tiên `serverMessage` khi mã lỗi là `INSUFFICIENT_STOCK`. Đã bổ sung unit test kiểm tra cả hai nhánh (có `serverMessage` và fallback).
- **#6 (P2):** Bổ sung đầy đủ các ca test SQL vào `supabase/tests/inventory_sales_link.sql` (S1–S11): S2 (kiểm tra không tạo stock movements khi thanh toán), S3 (hoàn tiền không tạo stock movements), S4 (hủy đơn đảo FEFO và phục hồi nguyên vẹn `product_costs`), S5 (kiểm tra chi tiết từng lô khi trả hàng tách lô đảo FEFO), S6 (đổi hàng tạo SALE và trả lại hàng đổi đảo đúng SALE của dòng đổi), S7 (blocker message/field, 2 ĐVT, đổi hàng thiếu tồn), S7b (replay idempotency key khi thiếu tồn).
- **#7 (P3):** Đảm bảo `field` của blocker trong `precheck_sales_order_checkout` luôn là `'lines[' || (v_line_index - 1)::text || ']'`.
- **#8 (P3):** Khôi phục `search_path` của `record_sales_payment` và `record_sales_refund` về `sales, iam, public, pg_temp` (loại bỏ `inventory`).
- **#9 (P3):** Thêm bộ lọc `and (p_product_ids is null or sb.product_id = any(p_product_ids))` vào CTE `lot_balances` trong `_product_stock_rows` để tránh quét toàn bộ tenant.
- **#10 (P3):** Thêm widget test `precheck_insufficient_blocker_shown` trong `sales_checkout_page_test.dart`.

**Kết quả kiểm tra xác minh:**
- `bash tools/db_check.sh sales_th05 inventory_sales_link`:
  - Reset & migration: ✅
  - plpgsql_check: ✅ (4 nợ đã biết)
  - SQL test: `inventory_sales_link Task 2 & Task 3 (S1-S11): OK` ✅
- Contract test: `test/features/inventory/data/inventory_sales_link_sql_contract_test.dart` (12/12 PASS) ✅
- Scoped Flutter tests: `sales_checkout_errors_test.dart`, `return_exchange_errors_test.dart`, `sales_checkout_error_messages_test.dart`, `sales_post_sale_error_messages_test.dart`, `sales_checkout_cubit_test.dart`, `sales_catalog_product_lookup_test.dart`, `sales_checkout_page_test.dart` (All tests passed!) ✅
- Dart analyze: `dart analyze lib test` 0 error (exit code 0) ✅

### R2 (2026-11-11) — 🟡 code đạt; chờ kết quả chạy đủ

Đọc diff sửa sau R1 (chưa commit) so với bảng R1.

| R1 | Kết quả |
|---|---|
| #1 P1 | ✅ Đọc `is_provisional` ở finalize + exchange; S11 (`PERIODIC`) kiểm dòng đơn và `value_movements` |
| #2 P2 | ✅ Truyền `unit_name` / `conversion_rate` ở finalize + exchange; S7 kiểm câu "… hộp bán được." ở precheck và `blockedMessage` |
| #3 P2 | ✅ Huỷ / trả truyền `source_intent_type` + `source_intent_line_id`, `line_id` = dòng huỷ / `returned`; trả và đổi dùng `RETURN_EXCHANGE`; `_reverse_sale` bỏ nhánh khớp mọi loại, thiếu ⇒ `CONTEXT_INVALID` |
| #4 P2 | ✅ `v_reversed` cộng dồn theo `SALE` trong một lần gọi; ca "Multi-Return" |
| #5 P2 | ✅ `serverMessage` cho `INSUFFICIENT_STOCK`, test hai nhánh |
| #6 P2 | ✅ S2 / S3 đếm dòng sổ, S4 `product_costs`, S5 từng lô, S6 trả món đổi, S7 câu + `field` + hai ĐVT + đổi thiếu tồn, S7b nhập thêm rồi gửi lại |
| #7–#10 P3 | ✅ |

**Còn lại:**

| # | Mức | Vấn đề | Sửa |
|---|---|---|---|
| 1 | P3 | Không ca nào kiểm `intent_type` / `intent_line_id` của **dòng đảo** (huỷ ⇒ `SALES_CANCELLATION` + `sol.id`; trả ⇒ `RETURN_EXCHANGE` + `rl.id`) — đúng theo đọc code, nhưng sửa sau có thể lặng lẽ sai lại | Thêm 2 câu kiểm vào S4 và S5 |
| 2 | — | Kết quả chạy mới gồm `db_check.sh sales_th05 inventory_sales_link` và một số tệp test Flutter — **chưa chạy đủ bộ** (các tệp `supabase/tests/*` khác, `flutter test` cả 3 thư mục). `impact` / `detect_changes` không có (phiên làm không có GitNexus) | Lệnh người dùng chạy bên dưới; dán đoạn cuối vào đây |

**Lệnh người dùng chạy:**
```
tools/db_check.sh
cd apps/erp && flutter test --no-pub -r compact test/features/sales test/features/inventory test/features/catalog
dart analyze apps/erp/lib apps/erp/test
```
Cả ba ✅ (số test đỏ không hơn `docs/refactor/TEST-BASELINE.md`) ⇒ G5-4 đạt; commit phần sửa sau R1.
