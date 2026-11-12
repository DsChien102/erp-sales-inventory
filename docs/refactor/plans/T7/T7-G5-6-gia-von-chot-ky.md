# T7-G5-6 — Giá vốn & chốt kỳ (BJ-14)

> Theme 7 · plan **G5-6** của [PLAN.md](../../PLAN.md) mục "Theme 7" (bảng Plan)
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-12) | Làm ✅ 2026-11-12 | Review ✅ R3 đạt 2026-11-12
> Thiết kế: duyệt trong chat 2026-11-12 (3 câu hỏi + 3 phần: dữ liệu / luật tính / sửa lõi; RPC / quyền / Hub; màn / chữ mới). Nguồn nghiệp vụ: [spec giá vốn](T7-G5-gia-von-thiet-ke.md) mục 2–7, 9, 12.4 (chỗ plan sửa spec ghi ở mục 1). Màn: Screen Contract SCR-072 / 074 / 077 (FROZEN v5.27.0) + prototype `app/bj14.js` (mục 2.7). Phụ thuộc: G5-0b (`value_movements`, `product_costs`, `cost_*`, `_value_line`), G5-4 (`_reversal_kind`), G5-5 (`_has_open_stocktake`), G5-5b (`_post_value_adjustment`, `SUPPLIER_REBATE`).

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Chủ cửa hàng tính lại giá vốn từ sổ cho một đoạn (cập nhật giữa kỳ hoặc chốt tháng), rà soát kết quả cả hai phương pháp kèm kiểm cân bằng, rồi công bố một giao dịch: ghi dòng điều chỉnh liên kết, tạo phiên bản giá chính thức, khoá kỳ khi chốt tháng. Trước lần công bố đầu, cửa hàng chọn phương pháp. 17 ca spec mục 9 đúng từng đồng.

**Architecture:** Migration mới `20261118001_inventory_costing.sql`: 2 bảng (`cost_runs`, `cost_run_lines`), hàm tính thuần `_cost_run_compute`, helper `_cost_run_is_stale`, 7 RPC. Sửa thẳng migration gốc: `_ensure_open_period`, check `kind` (`20261110001`), `_post_value_adjustment` (`20261117001`), `_reversal_kind` (`20261115001`), `get_warehouse_hub_summary` (`20261110001`). **Không** sửa `_value_line` / `_post_movements`. Flutter: BJ mới `features/inventory/{data,logic,presentation}/costing/` (072, 074, 077, sheet đổi phương pháp, sheet chi tiết tính, sheet lịch sử giá vốn), thêm dòng "Lịch sử giá vốn" ở SCR-003, lối vào + "Cần chú ý" ở Hub.

**Tech Stack:** PostgreSQL / Supabase (plpgsql), Flutter, `flutter_bloc`, `go_router`, `get_it`, `vet45_design_system`.

**Spec:** mục 1–2 của plan này + [spec giá vốn](T7-G5-gia-von-thiet-ke.md) + PLAN.md Theme 7 → "Quy ước chung cho mọi plan G5".

## Global Constraints

- Quy ước chung: PLAN.md Theme 7 → "Quy ước chung cho mọi plan G5" (gồm "UI Flutter: trích code prototype" — code đã chép ở mục 2.7; phiên code không thêm phần tử ngoài bảng ánh xạ).
- Header migration theo khuôn `20261110001_inventory_core.sql`; cập nhật `supabase/migrations/REGISTRY.yaml`. Hàm đã có sửa **thẳng migration gốc**. FK trỏ tới `cost_runs` (`cost_versions.cost_run_id`, `cost_periods.closing_run_id`, `value_movements.cost_run_id`) đặt ở migration mới bằng `alter table … add constraint` (bảng đích chưa có lúc chạy `20261110001`).
- Hàm Kho mới: `security definer`, `set search_path = inventory, iam, catalog, pg_temp`. RPC công khai: `grant execute … to authenticated`, gọi `inventory._assert_actor(p_tenant_id, 'inventory.read', true)` đầu tiên (**chỉ chủ cửa hàng** — mọi RPC của plan này; khác ⇒ `PERMISSION_DENIED`). Hàm `_`: `revoke all … from public, anon, authenticated`, không `grant`.
- Tiền `bigint` (đồng), làm tròn `round()` của numeric (nửa lên); đơn giá / bình quân `numeric(18,4)`; số lượng ĐVT cơ sở. Hiển thị: `MoneyFormatter.formatMinor(int)`; đơn giá `MoneyFormatter.formatMinor(v.round())` + `'/$uom'`; số có dấu dùng `signedMoney` (mục 2.6, dấu trừ là `−` U+2212, dính số).
- Khoá: `pg_advisory_xact_lock(hashtext(p_tenant_id::text), hashtext('cost'))` ở đầu `set_cost_policy`, `create_cost_run`, `publish_cost_run`, `discard_cost_run`. Khoá sản phẩm (chỉ ở `publish_cost_run`) đúng khoá của `_post_movements`: `pg_advisory_xact_lock(hashtext(tenant::text), hashtext(product::text))`, `product_id` tăng dần.
- Idempotency (`_begin_idempotency` / `_complete_idempotency`, hash `md5` của tham số trừ khoá): scope `cost_policy.set`, `cost_run.create`, `cost_run.publish`, `cost_run.discard`.
- Chạy SQL: `tools/db_check.sh` (reset + `plpgsql_check` + mọi tệp test) phải ✅ trước khi báo xong task có SQL; một tệp: `tools/db_check.sh --no-reset inventory_costing`. Lệnh DB chỉ chạy **local**; reset Dev (`--linked`) **hỏi người dùng**.
- Flutter: `dart analyze` (không `flutter analyze`). Test: `cd apps/erp && flutter test --no-pub -r compact <đường dẫn>`. Số test đỏ không hơn `docs/refactor/TEST-BASELINE.md`.
- Chữ trên màn: **nguyên văn** Screen Contract mục 8 + chữ mới mục 2.6 / 2.7 (đã duyệt). Phần thuộc cơ chế bỏ (BJ-11, BJ-16, BJ-03 xác lập giá, K3 `UNKNOWN`, nhiều phạm vi chốt) không dựng.
- Trước khi sửa symbol đã có (`inventory._ensure_open_period`, `inventory._post_value_adjustment`, `inventory._reversal_kind`, `inventory.get_warehouse_hub_summary`, `StockCostBlock`, `StockDetailBody`, `WarehouseHubSummary`, `WarehouseHubRepository`, `WarehouseHubPage`, `warehouseAreaEntries`, `inventoryErrorMessage`, `InventoryErrorCode`, `app_router.dart`, `injection.dart`): chạy `impact({target, direction: "upstream"})`, ghi Kết quả; HIGH / CRITICAL ⇒ dừng, báo người dùng. Task cuối: `detect_changes({scope: "compare", base_ref: "main"})`.
- `AGENTS.md`, `CLAUDE.md`: không `git add`. Ghi mục 5 Kết quả sau mỗi task. Làm từng task một, mỗi task một commit.

## Review Focus

1. **Bán trong lúc run chờ rà soát, bán hết sau mốc** (spec ca 11) ⇒ công bố vẫn được dù giá trị sổ hiện tại về âm tạm thời; lần tính sau bù đúng; `moving_avg_cost` không âm. Test: Task 2 `case11_sale_during_review`, `case11b_sold_out_after_cutoff`.
2. **Chốt tháng khi đã sang tháng mới có bán hàng** ⇒ mốc chốt chỉ lấy dòng có `business_date` trong tháng chốt; hàng bán tháng sau thuộc đoạn sau; sau khi chốt, ghi sổ vào tháng đã chốt hoặc cũ hơn ⇒ `PERIOD_CLOSED`. Test: Task 1 `period_close_cutoff_by_month`; Task 2 `case8_closed_period`, `ensure_period_older_than_closed`.
3. **Cập nhật giữa kỳ khi tháng trước chưa chốt / chốt kỳ đoạn trống** ⇒ `MID_PERIOD` bị `PREVIOUS_PERIOD_OPEN`; `PERIOD_CLOSE` đoạn rỗng vẫn `READY_FOR_REVIEW` 0 dòng và công bố được để khoá kỳ. Test: Task 1 `mid_blocked_previous_open`, `period_close_empty_segment`; Task 2 `publish_empty_close`.
4. **Hai lần công bố / dữ liệu cũ** (bấm hai lần, đổi phương pháp sau khi tính, lần công bố khác chen vào) ⇒ cùng khoá trả kết quả cũ; run cũ hiện `STALE` ở 072 / 074 (không cần ghi trạng thái), công bố ⇒ `COST_RUN_STALE`, 074 chuyển trạng thái "Dữ liệu đầu vào đã thay đổi". Test: Task 2 `case9_*`; Task 4 `publish_stale_marks_stale`; Task 6 `publish_stale_shows_input_changed_390`.
5. **Trả hàng của đơn bán sau mốc nhưng trước công bố** ⇒ `SALE_REVERSAL` (không phải `RETURN_IN`), không làm lệch `P` đoạn sau. Test: Task 2 `reversal_kind_after_cutoff_before_publish`.

---

## 1. Quyết định (người dùng, 2026-11-12)

| Q | Nội dung |
|---|---|
| Q-6-1 | **072 = danh sách lần tính** theo prototype (K6, chip "Cần làm" / "Đã công bố", web bảng) + dòng "Đổi" phương pháp ở đầu màn + chân "Cập nhật giữa kỳ" / "Chốt kỳ {kỳ}". Giá theo sản phẩm + lịch sử phiên bản đặt ở SCR-003 (dòng "Lịch sử giá vốn") — khác spec giá vốn mục 7 (072 là danh sách sản phẩm) |
| Q-6-2 | **074 khối ④ theo prototype** (cũ / mới / chênh lệch) + nút "Xem chi tiết tính" mở sheet đủ cột spec (đầu, nhập, chiết khấu NCC, xuất, hao hụt, cuối, hai bình quân, điều chỉnh) + dòng tổng + "Kiểm cân bằng" |
| Q-6-3 | **Demo chốt kỳ tự nhiên**: dữ liệu demo tạo tháng 11 ⇒ từ 01/12 chốt kỳ 11/2026 trên app; trước đó demo "Cập nhật giữa kỳ". `PERIOD_CLOSE` chứng minh bằng test SQL (gọi `_post_movements` với `p_business_date` tháng trước). Không thêm script lùi ngày / đồng hồ giả |

**Duyệt cùng thiết kế (chat 2026-11-12) — chỗ sửa / làm rõ spec:**

| # | Nội dung | Lý do |
|---|---|---|
| D1 | Mốc chốt `PERIOD_CLOSE` = max `ledger_sequence` của dòng có `business_date` trong tháng chốt (spec: max toàn sổ) | Chốt tháng 11 ngày 03/12 không kéo hàng bán tháng 12 vào kỳ 11. Mọi RPC ghi sổ dùng `_today()` ⇒ thứ tự sequence khớp thứ tự tháng |
| D2 | `MID_PERIOD` cũng bị `PREVIOUS_PERIOD_OPEN` khi còn tháng đã hết chưa chốt | Cập nhật giữa kỳ tháng 12 sẽ nuốt đoạn cần chốt của tháng 11 |
| D3 | `_ensure_open_period`: tháng cũ hơn một kỳ `CLOSED` ⇒ `PERIOD_CLOSED` | Không mở lại kỳ đã khoá bằng ngày lùi |
| D4 | `PERIOD_CLOSE` đoạn rỗng ⇒ `READY_FOR_REVIEW` 0 dòng, công bố chỉ khoá kỳ; `NOTHING_TO_COST` chỉ cho `MID_PERIOD` | Đã cập nhật giữa kỳ hết thì vẫn phải chốt được tháng |
| D5 | **Dấu sổ:** `COGS_TRUE_UP.amount = −cogs_true_up`, `LOSS_TRUE_UP.amount = −loss_true_up`, `REVALUE_ROUNDING.amount = +rounding_adjust`. G5-7 đọc điều chỉnh giá vốn = `−amount` | Spec 5.1 viết "+20.000" theo góc giá vốn; sổ giá trị tồn phải giảm 900.000 → 880.000 |
| D6 | Ngày ghi dòng điều chỉnh: `PERIOD_CLOSE` = ngày cuối tháng chốt; `MID_PERIOD` = `_today()` | Lãi gộp G5-7 theo kỳ |
| D7 | `_post_value_adjustment`: với 3 loại điều chỉnh của lần tính cho `V` âm tạm thời; `m = greatest(round(V/q, 4), 0)` khi `q > 0` | Ca 11: tồn đã bán hết sau mốc theo giá tạm ⇒ `V = 0`, ghi −20.000 bị chặn. Lần tính sau tự bù |
| D8 | `_reversal_kind` so `ledger_sequence` của dòng bán với `cut_off_sequence` của run `PUBLISHED` mới nhất (thay vì `cost_versions.effective_from_sequence`) | Bán sau mốc, trước công bố, rồi trả ⇒ phải là `SALE_REVERSAL` |
| D9 | Bỏ `'OPENING'` khỏi check `value_movements.kind` | Spec 3.1 (bỏ tồn đầu kỳ) |
| D10 | Mã lỗi mới chỉ 3: `COST_RUN_STALE`, `COST_RUN_NOT_READY`, `COST_POLICY_LOCKED`. Bỏ `COST_RUN_BLOCKED` (run `BLOCKED` là trạng thái; công bố run `BLOCKED` ⇒ `COST_RUN_NOT_READY`) | — |
| D11 | Hub: lối "Giá vốn" (`ownerOnly: true` đã có) trỏ `/warehouse/costing`; "Cần chú ý" thêm 2 nguồn chỉ chủ cửa hàng | — |
| D12 | 077: bỏ `UNKNOWN` / K3 (mất mạng ⇒ lỗi + "Thử lại" cùng khoá); ẩn "Xem báo cáo tồn" tới G5-7 | Rút gọn 2026-11-09; Q9 |

**Thêm lúc viết plan (duyệt cùng plan):**

| Chỗ | Nội dung | Lý do |
|---|---|---|
| `STALE` suy ra lúc đọc | `get_cost_overview` / `get_cost_run` trả `status = 'STALE'` khi run `READY_FOR_REVIEW` mà `_cost_run_is_stale` đúng; `publish_cost_run` raise `COST_RUN_STALE` (giao dịch rollback nên không ghi được `STALE`); `create_cost_run` ghi `STALE` → `SUPERSEDED` cho run cũ | `raise` huỷ mọi update cùng giao dịch |
| Mốc khi tạo | `create_cost_run` đọc `ledger_counters … for update` trước khi lấy mốc | Chờ giao dịch ghi sổ đang dở commit ⇒ không sót dòng có sequence ≤ mốc |
| Tồn đầu đoạn | = dòng `cost_run_lines` của **run `PUBLISHED` gần nhất có sản phẩm đó** (không chỉ run liền trước); không có ⇒ 0 / 0 | Sản phẩm không biến động trong đoạn trước không có dòng ở run trước |
| Phát lại liên hoàn | Dòng vào (`RECEIPT`, `COUNT_GAIN`, `RETURN_IN`, `SALE_REVERSAL`) dùng `amount_vnd` đã ghi; dòng ra (`SALE`, `COUNT_LOSS`, `WRITE_OFF`) tính lại `−round(qty × m)` | Dòng vào đã có giá; chỉ dòng ra phụ thuộc phương pháp |
| `PERIODIC`, bán hết sau chiết khấu NCC | `closing_qty = 0` ⇒ `closing_value_after = 0`; phần `B` còn lại vào `REVALUE_ROUNDING` (ghi báo cáo đồ án) | Công thức spec `round(0 × S) + B` để lại giá trị âm cho tồn 0 |
| Giá chính thức mới | `PERIODIC`: `closing_value_after / closing_qty` (4 chữ số) khi `closing_qty > 0`, ngược lại `S`; `MOVING`: `S`. `product_costs.official_unit_cost` = đơn giá phiên bản (spec 6.4 ghi `S`) | Spec 5 câu `PERIODIC` có `B` |
| `P` không tính được | `opening_qty + inbound_qty = 0` ⇒ `S null`, không điều chỉnh, không phiên bản | Spec mục 5 "mẫu 0 → null" |
| Ca spec 5, 12–15, 17 | Đã có trong tệp test của plan trước; `inventory_costing.sql` ghi bảng trỏ (mục 2.5), **không** viết lại. Tiêu chí PLAN #8 sửa câu cho khớp | Tránh nhân đôi fixture phiếu nhận / chương trình |
| Mã run | `GV-{YYMM}-{nn}` (`nn` = thứ tự run của tenant trong kỳ, từ 01) | Cột "Lần tính" 072 web |

---

## 2. Thiết kế

### 2.1 Dữ liệu (`supabase/migrations/20261118001_inventory_costing.sql`)

Mọi bảng: `tenant_id uuid not null → iam.tenants on delete cascade`, RLS bật, `revoke all … from public, anon, authenticated`.

| Bảng | Cột | Ràng buộc |
|---|---|---|
| `cost_runs` | `id uuid pk`, `code text`, `kind text`, `period_id uuid → cost_periods`, `period_month date`, `from_sequence bigint`, `cut_off_sequence bigint`, `cut_off_at timestamptz`, `method text`, `status text`, `blockers jsonb not null default '[]'`, `supersedes_run_id uuid null → cost_runs`, `based_on_run_id uuid null → cost_runs`, `created_by uuid`, `created_at timestamptz default now()`, `published_by uuid null`, `published_at timestamptz null` | `kind in ('PERIOD_CLOSE','MID_PERIOD')`; `method in ('MOVING','PERIODIC')`; `status in ('READY_FOR_REVIEW','BLOCKED','STALE','PUBLISHED','SUPERSEDED')`; `unique (tenant_id, code)`; unique một phần `(tenant_id) where status = 'READY_FOR_REVIEW'`; `cut_off_sequence >= from_sequence` |
| `cost_run_lines` | `run_id uuid → cost_runs on delete cascade`, `product_id uuid → catalog.products`, `old_official_unit_cost numeric(18,4) null`, `opening_qty numeric`, `opening_value bigint`, `inbound_qty numeric`, `inbound_value bigint`, `rebate_value bigint` (B, ≤ 0), `sale_qty numeric`, `sale_value_recorded bigint`, `loss_qty numeric`, `loss_value_recorded bigint`, `closing_qty numeric`, `closing_value_before bigint`, `moving_avg_end numeric(18,4)`, `periodic_avg numeric(18,4) null`, `selected_unit_cost numeric(18,4) null`, `cogs_true_up bigint`, `loss_true_up bigint`, `rounding_adjust bigint`, `closing_value_after bigint`, `new_unit_cost numeric(18,4) null` | PK `(run_id, product_id)`; trigger `before update or delete … _forbid_ledger_mutation()` (chỉ thêm) |

`cut_off_at`: `MID_PERIOD` = `now()`; `PERIOD_CLOSE` = `(period_month + interval '1 month') - interval '1 minute'` (giờ VN, hiện "31/08/2026 · 23:59"). `alter table` FK: `cost_versions.cost_run_id`, `cost_periods.closing_run_id`, `value_movements.cost_run_id` → `cost_runs (id)`. Chỉ mục: `value_movements (tenant_id, product_id, ledger_sequence)`, `stock_movements (tenant_id, business_date, ledger_sequence)`.

### 2.2 Hàm + RPC

| Hàm | Luật / Ra |
|---|---|
| `_cost_run_compute(p_tenant_id uuid, p_from bigint, p_cut bigint, p_method text) returns setof inventory.cost_run_lines` | Thuần đọc, `run_id` = `null` (người gọi gán). Luật mục 2.3. Chỉ sản phẩm có dòng `value_movements` trong `(p_from, p_cut]` với `kind not in ('COGS_TRUE_UP','LOSS_TRUE_UP','REVALUE_ROUNDING')` |
| `_cost_run_is_stale(p_tenant_id uuid, p_run inventory.cost_runs) returns boolean` | `p_run.status = 'READY_FOR_REVIEW'` và (`based_on_run_id` khác id run `PUBLISHED` mới nhất — so `is distinct from` — **hoặc** `method` khác `_cost_method(tenant)`) |
| `_cost_run_view(p_tenant_id uuid, p_run_id uuid) returns jsonb` | Dựng `CostRunView` (dưới) — dùng chung cho `get_cost_run`, kết quả `create_cost_run`, `publish_cost_run` |
| `get_cost_overview(p_tenant_id uuid) returns jsonb` | `{method, method_locked (có run PUBLISHED), open_period ('YYYY-MM-01' của kỳ OPEN chứa _today(), null nếu chưa có), period_to_close ('YYYY-MM-01' kỳ OPEN sớm nhất có period_month + 1 tháng <= _today(), hoặc null), has_pending_run (có run READY không stale), runs: [CostRunRow]}`. `CostRunRow = {run_id, code, kind, period_month, status (đã suy STALE), product_count (count lines), blocker_count (jsonb_array_length(blockers)), value_adjust_vnd (Σ −cogs −loss + rounding; null khi status không READY / PUBLISHED / STALE), published_at, created_at}`; bỏ `SUPERSEDED`; sắp `created_at desc` |
| `set_cost_policy(p_tenant_id uuid, p_method text, p_idempotency_key text) returns jsonb` | `p_method` ngoài 2 giá trị ⇒ `CONTEXT_INVALID`; có run `PUBLISHED` ⇒ `COST_POLICY_LOCKED`; upsert `cost_policies (method, changed_at = now(), changed_by)`. Ra `{method, method_locked: false}` |
| `create_cost_run(p_tenant_id uuid, p_kind text, p_idempotency_key text) returns jsonb` | Mục 2.4 "Tạo". Ra `CostRunView` |
| `get_cost_run(p_tenant_id uuid, p_run_id uuid) returns jsonb` | Run không thuộc tenant ⇒ `CONTEXT_INVALID`. Ra `CostRunView` |
| `publish_cost_run(p_tenant_id uuid, p_run_id uuid, p_idempotency_key text) returns jsonb` | Mục 2.4 "Công bố". Ra `CostRunView` (status `PUBLISHED`) |
| `discard_cost_run(p_tenant_id uuid, p_run_id uuid, p_idempotency_key text) returns jsonb` | Status (đã suy) `READY_FOR_REVIEW` / `BLOCKED` / `STALE` ⇒ `SUPERSEDED`; khác ⇒ `COST_RUN_NOT_READY`. Ra `{run_id, status: 'SUPERSEDED'}` |
| `list_cost_versions(p_tenant_id uuid, p_product_id uuid) returns jsonb` | Sản phẩm không thuộc tenant ⇒ `CONTEXT_INVALID`. `{product_id, name ← products.name, uom ← catalog._product_base_unit_name, versions: [{version_id ← cost_versions.id, unit_cost, method, run_code ← cost_runs.code, published_at ← cost_runs.published_at}]}` sắp `effective_from_sequence desc` |
| `get_warehouse_hub_summary` (sửa, `20261110001`) | Thêm `cost_period_to_close` (như overview) và `cost_runs_pending` (số run READY không stale) khi `is_owner`; nhân viên `null` / `0` |

`CostRunView = {run_id, code, kind, period_month, status (đã suy), method, from_sequence, cut_off_sequence, cut_off_at, created_at, published_at, blockers: [{code, period_month?, product_count?}], product_count, changed_count (dòng có new_unit_cost is distinct from old_official_unit_cost và new_unit_cost not null), totals: {closing_value ← Σ closing_value_after, cogs_value ← Σ (sale_value_recorded + cogs_true_up), cogs_adjust ← Σ (cogs_true_up + loss_true_up), value_adjust ← Σ (−cogs_true_up − loss_true_up + rounding_adjust), balance_ok}, alt: {method (phương pháp kia), closing_value, cogs_value}, lines: [CostRunLineView]}`. `CostRunLineView` = mọi cột `cost_run_lines` + `name ← catalog.products.name`, `code ← catalog.products.sku`, `uom ← catalog._product_base_unit_name(tenant, product)`, `line_adjust = −cogs_true_up − loss_true_up + rounding_adjust`, `balance_diff` (vế trái − vế phải bất biến mục 2.3). `lines` sắp `abs(line_adjust) desc, name`. `alt`: tính lại `S'`, `cogs'`, `closing'` theo mục 2.3 với phương pháp kia từ cột đã lưu (`moving_avg_end`, `periodic_avg`), không lưu.

Mã lỗi mới (`inventory._raise`): `COST_RUN_STALE`, `COST_RUN_NOT_READY`, `COST_POLICY_LOCKED`.

### 2.3 Luật tính (`_cost_run_compute`)

Cho mỗi sản phẩm `p` trong đoạn:

1. **Đầu đoạn:** dòng `cost_run_lines` của run `PUBLISHED` có `cut_off_sequence` lớn nhất chứa `p` ⇒ `opening_qty = closing_qty`, `opening_value = closing_value_after`, `m0 = moving_avg_end`; không có ⇒ `0, 0, 0`. `old_official_unit_cost = product_costs.official_unit_cost`.
2. **Duyệt** `value_movements` của `p` trong `(from, cut]`, bỏ 3 loại điều chỉnh, theo `ledger_sequence` tăng (`qb = quantity_basis`, luôn dương; `a = amount_vnd`):

   | `kind` | Cộng dồn | Phát lại liên hoàn (`q`, `V`, `m`; bắt đầu `opening_qty`, `opening_value`, `m = q>0 ? round(V/q,4) : m0`) |
   |---|---|---|
   | `RECEIPT`, `COUNT_GAIN`, `RETURN_IN` | `inbound_qty += qb`, `inbound_value += a` | `q += qb`, `V += a`, `m = round(V/q, 4)` |
   | `SUPPLIER_REBATE` | `rebate_value += a` | `V += a`, `m = q>0 ? round(V/q,4) : m` |
   | `SALE` | `sale_qty += qb`, `sale_value_recorded += −a` | `q −= qb`, `V −= round(qb × m)` |
   | `SALE_REVERSAL` | `sale_qty −= qb`, `sale_value_recorded −= a` | `q += qb`, `V += a`, `m = q>0 ? round(V/q,4) : m` |
   | `COUNT_LOSS`, `WRITE_OFF` | `loss_qty += qb`, `loss_value_recorded += −a` | `q −= qb`, `V −= round(qb × m)` |

   `moving_avg_end = m` cuối.
3. `closing_qty = opening_qty + inbound_qty − sale_qty − loss_qty`; `closing_value_before = opening_value + inbound_value + rebate_value − sale_value_recorded − loss_value_recorded`.
4. `periodic_avg = (opening_qty + inbound_qty) > 0 ? round((opening_value + inbound_value) / (opening_qty + inbound_qty), 4) : null` (không gồm `B`).
5. `S = MOVING ? moving_avg_end : periodic_avg`.
6. `S null` ⇒ `cogs_true_up = loss_true_up = rounding_adjust = 0`, `closing_value_after = closing_value_before`, `new_unit_cost = null`. Ngược lại:
   - `MOVING`: `cogs_true_up = loss_true_up = 0`; `closing_value_after = round(closing_qty × S)`.
   - `PERIODIC`: `cogs_true_up = round(sale_qty × S) − sale_value_recorded`; `loss_true_up = round(loss_qty × S) − loss_value_recorded`; `closing_value_after = closing_qty > 0 ? round(closing_qty × S) + rebate_value : 0`.
   - `rounding_adjust = closing_value_after − (closing_value_before − cogs_true_up − loss_true_up)`.
   - `new_unit_cost = PERIODIC and closing_qty > 0 ? round(closing_value_after / closing_qty, 4) : S`.

**Bất biến** (`balance_diff = 0` cho mọi dòng): `opening_value + inbound_value + rebate_value = (sale_value_recorded + cogs_true_up) + (loss_value_recorded + loss_true_up) + closing_value_after − rounding_adjust`. `balance_ok` = mọi `balance_diff = 0`.

**Ví dụ 5.1 (khoá test):** `PERIODIC` ⇒ `P 11.000`, `cogs_true_up +20.000`, `closing_value_after 880.000`, `rounding 0`, dòng sổ `COGS_TRUE_UP −20.000`, phiên bản 11.000; `MOVING` ⇒ `S 11.250`, mọi điều chỉnh 0, `closing_value_after 900.000`.

### 2.4 Tạo và công bố

**Tạo** (`create_cost_run`): `_begin_idempotency` → khoá `cost` → `select last_sequence … from ledger_counters … for update` (thiếu dòng ⇒ 0) → run `READY_FOR_REVIEW` cũ mà stale ⇒ `STALE`; mọi run `BLOCKED` / `STALE` của tenant ⇒ `SUPERSEDED` (nhớ id run mới nhất bị thay cùng `kind` làm `supersedes_run_id`) → xác định:
- `from` = `cut_off_sequence` của run `PUBLISHED` mới nhất (0); `based_on_run_id` = id run đó.
- `MID_PERIOD`: kỳ = `_ensure_open_period(tenant, _today())`; `cut` = `last_sequence`.
- `PERIOD_CLOSE`: kỳ = `OPEN` có `period_month` nhỏ nhất (không có ⇒ `CONTEXT_INVALID`); `cut = greatest(from, max ledger_sequence của stock_movements ∪ value_movements có business_date trong [period_month, period_month + 1 tháng))`.
- `blockers` (thứ tự này; `period_month` dạng `YYYY-MM-01`):
  | Mã | Khi |
  |---|---|
  | `PREVIOUS_PERIOD_OPEN` | Có kỳ `OPEN` khác kỳ của run, `period_month < period_month của run` và đã hết (`+1 tháng <= _today()`) — kèm `period_month` của kỳ đó |
  | `PERIOD_NOT_ENDED` | `PERIOD_CLOSE` mà `period_month + 1 tháng > _today()` — kèm `period_month` |
  | `STOCKTAKE_OPEN` | `_has_open_stocktake(tenant)` |
  | `RUN_PENDING_REVIEW` | Còn run `READY_FOR_REVIEW` không stale |
  | `NOTHING_TO_COST` | `MID_PERIOD` và `_cost_run_compute` rỗng |
  | `LEDGER_MISMATCH` | Có dòng compute mà `closing_qty ≠ Σ stock_movements.quantity_delta` của sản phẩm với `ledger_sequence <= cut` — kèm `product_count` |
- Có blocker ⇒ lưu run `BLOCKED`, **không** lưu dòng. Không ⇒ lưu run `READY_FOR_REVIEW` + dòng compute. `code` = `'GV-' || to_char(period_month,'YYMM') || '-' || lpad((count run cùng tenant + period_month) + 1, 2, '0')`.

**Công bố** (`publish_cost_run`): `_begin_idempotency` (replay ⇒ trả snapshot) → khoá `cost` → `select … for update` run (không thuộc tenant ⇒ `CONTEXT_INVALID`) → `status ≠ READY_FOR_REVIEW` ⇒ `COST_RUN_NOT_READY` → `_cost_run_is_stale` ⇒ `COST_RUN_STALE` → khoá sản phẩm của dòng theo `product_id` tăng → `v_date = PERIOD_CLOSE ? (period_month + 1 tháng − 1 ngày) : _today()` → mỗi dòng: gọi `_post_value_adjustment(tenant, product, kind, amount, v_date, run_id, null)` cho `COGS_TRUE_UP (−cogs_true_up)`, `LOSS_TRUE_UP (−loss_true_up)`, `REVALUE_ROUNDING (+rounding_adjust)` khi khác 0 → `v_eff = ledger_counters.last_sequence + 1` → mỗi dòng `new_unit_cost not null`: insert `cost_versions (unit_cost = new_unit_cost, method = run.method, effective_from_sequence = v_eff, cost_run_id)`; update `product_costs set official_version_id, official_unit_cost = new_unit_cost` và (`PERIODIC`, `q > 0`) `moving_avg_cost = greatest(round(ledger_value_vnd / quantity_on_hand, 4), 0)` → `PERIOD_CLOSE`: kỳ `CLOSED` (`closed_at`, `closed_by`, `closing_run_id`), insert kỳ tháng sau `OPEN` (`on conflict do nothing`) → run `PUBLISHED` (`published_by`, `published_at = now()`) → `_complete_idempotency`.

### 2.5 Sửa lõi + test SQL

**Sửa lõi:**

| Hàm (tệp) | Sửa |
|---|---|
| `_ensure_open_period` (`20261110001`) | Trước khi tạo kỳ mới: tồn tại `cost_periods CLOSED` với `period_month > v_month` ⇒ `PERIOD_CLOSED` |
| check `value_movements.kind` (`20261110001`) | Bỏ `'OPENING'` |
| `_post_value_adjustment` (`20261117001`) | Kiểm `V_after < 0` chỉ khi `p_kind = 'SUPPLIER_REBATE'`; `avg_after = greatest(round(V/q, 4), 0)` khi `q > 0` |
| `_reversal_kind` (`20261115001`) | `RETURN_IN` khi tồn tại `cost_runs PUBLISHED` của tenant có `cut_off_sequence >= ledger_sequence` của dòng bán; ngược lại `SALE_REVERSAL`. Sửa fixture ca `reversal_kind_return_in` ở `supabase/tests/inventory_sales_link.sql` (chèn run `PUBLISHED` thay vì chỉ `cost_versions`) |

**`supabase/tests/inventory_costing.sql`** (fixture chép khuôn `inventory_supplier_rebates.sql`: role `store_owner` + `is_owner`, `products.reference_id`, `store_warehouse_assignments`; dòng sổ tháng trước tạo bằng `inventory._post_movements(…, p_business_date => …)` chạy như `postgres`; RPC gọi với `request.jwt.claims` của owner / staff). Mỗi ca sai ⇒ `raise exception 'FAIL: <ca>'`.

| Ca | Task | Dữ liệu | Kỳ vọng |
|---|---|---|---|
| `case1_moving` | 1 | Ví dụ 5.1, `MOVING`, `MID_PERIOD` | dòng: `inbound 150 / 1.650.000`, `sale 70 / 750.000`, `closing_qty 80`, `moving_avg_end 11.250`, `periodic_avg 11.000`, `cogs_true_up 0`, `closing_value_after 900.000`; `alt.cogs_value 770.000` |
| `case2_periodic` | 2 | Ví dụ 5.1, `PERIODIC` (chưa có giá chính thức ⇒ bán `is_provisional`) ⇒ tạo + công bố ⇒ bán 10 | `cogs_true_up 20.000`, `closing_value_after 880.000`, `rounding 0`; một dòng sổ `COGS_TRUE_UP −20.000`; `cost_versions.unit_cost 11.000`; `ledger_value 880.000`; bán sau ⇒ `unit_cost 11.000`, `is_provisional false`, `cost_version_id` = phiên bản mới |
| `case3_periodic_prior_official` | 2 | Tiếp `case2`: nhập 20 × 12.000, bán 30 (theo 11.000) ⇒ lần tính 2 | `opening 80 / 880.000`; `P = (880.000 + 240.000) / 100 = 11.200`; `sale_value_recorded` gồm 10 + 30 bán theo 11.000 = 440.000, `cogs_true_up = 448.000 − 440.000 = 8.000` |
| `case4_rounding` | 1, 2 | `PERIODIC`, chưa có giá chính thức: nhập 1 × 10.001, 1 × 10.000 (`m` 10.000,5); bán 1 (giá tạm, ghi `round(10.000,5) = 10.001`) | dòng run: `P 10.000,5`, `cogs_true_up 0`, `closing_value_before 10.000`, `closing_value_after 10.001`, `rounding_adjust +1`, `balance_diff 0`; Task 2: sau công bố một dòng `REVALUE_ROUNDING +1`, `ledger_value 10.001 = round(1 × S)` |
| `case6_reversal_return` | 2 | Bán 10 ⇒ huỷ 4 cùng đoạn; công bố; trả 3 của dòng bán cũ | `SALE_REVERSAL +4 × đơn giá bán`, `sale_qty 6`; sau công bố `RETURN_IN` theo đơn giá dòng `SALE` gốc, đoạn sau `inbound_qty 3` |
| `case7_loss_periodic` | 2 | `PERIODIC`, chưa có giá chính thức: nhập 10 × 10.000; `COUNT_LOSS 2` (ghi 20.000); nhập 10 × 12.000 (`m` 11.111,1111); `WRITE_OFF 1` (ghi 11.111); bán 5 (ghi 55.556) | `P 11.000`; `loss_qty 3`, `loss_value_recorded 31.111`, `loss_true_up +1.889`; `sale_value_recorded 55.556`, `cogs_true_up −556`; `closing_value_after 132.000`, `rounding 0`; sau công bố dòng `LOSS_TRUE_UP −1.889`, `COGS_TRUE_UP +556` |
| `case8_closed_period` | 2 | Chốt kỳ tháng trước ⇒ `_post_movements` với ngày tháng đó | `PERIOD_CLOSED` |
| `ensure_period_older_than_closed` | 2 | Kỳ T−1 `CLOSED`; ghi ngày T−2 (chưa có kỳ) | `PERIOD_CLOSED`, không tạo kỳ T−2 |
| `case9_replay_same_key` / `case9_stale_after_policy_change` / `case9_policy_locked` | 2 | Công bố 2 lần cùng khoá; run A READY (`MOVING`) ⇒ `set_cost_policy('PERIODIC')` ⇒ đọc A, công bố A ⇒ tạo run B (A thành `SUPERSEDED`), công bố B; `set_cost_policy` sau công bố | cùng kết quả, số dòng sổ không đổi; `get_cost_run(A).status = 'STALE'`, `publish(A) ⇒ COST_RUN_STALE`; `COST_POLICY_LOCKED`. (Spec "lần công bố khác chen vào" không xảy ra được: unique một phần chỉ cho một run READY; `_cost_run_is_stale` vẫn so `based_on_run_id`) |
| `case10_close_then_mid` | 2 | Xem ghi chú dưới bảng | Run sau `from_sequence` = `cut` run trước; dòng điều chỉnh của run trước không vào đoạn sau; `opening` = `closing_value_after` run trước |
| `case11_sale_during_review` | 2 | Run READY; bán 10 sau mốc; công bố | công bố được; dòng bán có `ledger_sequence > cut`; lần tính kế tiếp có dòng bán đó |
| `case11b_sold_out_after_cutoff` | 2 | `PERIODIC` ví dụ 5.1; run READY; bán hết 80 theo giá tạm 11.250 ⇒ `V 0`; công bố | công bố được; dòng `COGS_TRUE_UP −20.000`; `ledger_value −20.000`; `moving_avg_cost` giữ 11.250 (`q = 0`); lần tính sau: `opening 80 / 880.000`, `sale_value_recorded 900.000`, `cogs_true_up −20.000`, `new_unit_cost 11.000` ⇒ công bố dòng `COGS_TRUE_UP +20.000`, `ledger_value 0` |
| `case16_rebate_periodic` | 2 | `PERIODIC`: nhập 1.000 × 100.000 qua chương trình loại 3 (chép fixture `case14_single_product`), bán 700, ghi nhận `R 5.000.000` (phần tồn 1.500.000) ⇒ lần tính | `rebate_value −1.500.000`; `P 100.000` (không gồm B); `closing_value_after = 300 × 100.000 − 1.500.000 = 28.500.000`; `new_unit_cost 95.000`; `balance_diff 0` |
| `period_close_cutoff_by_month` | 1 | Dòng tháng T−1 (seq 1–4), rồi tháng T (seq 5–6); `PERIOD_CLOSE` | `cut_off_sequence` = seq lớn nhất tháng T−1; dòng tháng T không vào run |
| `period_close_empty_segment` / `publish_empty_close` | 1 / 2 | Kỳ T−1 OPEN, mọi dòng đã thuộc run công bố trước | `READY_FOR_REVIEW`, `product_count 0`; công bố ⇒ kỳ `CLOSED`, kỳ T `OPEN` |
| `mid_blocked_previous_open` | 1 | Kỳ T−1 OPEN; `MID_PERIOD` | `BLOCKED`, `blockers[0].code = 'PREVIOUS_PERIOD_OPEN'` |
| `blockers_misc` | 1 | Phiên kiểm kê `COUNTING`; run READY sẵn; không biến động mới | `STOCKTAKE_OPEN`, `RUN_PENDING_REVIEW`, `NOTHING_TO_COST` |
| `ledger_mismatch` | 1 | Chèn tay một `stock_movements` không có dòng giá trị (tắt trigger trong test) | `LEDGER_MISMATCH`, `product_count 1` |
| `discard_and_supersede` | 2 | Run BLOCKED ⇒ tạo lại ⇒ run cũ `SUPERSEDED`, run mới `supersedes_run_id`; bỏ run READY | `discard ⇒ SUPERSEDED`; bỏ run PUBLISHED ⇒ `COST_RUN_NOT_READY` |
| `reversal_kind_after_cutoff_before_publish` | 2 | Run READY (mốc X); bán (seq > X); công bố; huỷ đơn | `_reversal_kind = 'SALE_REVERSAL'` |
| `staff_denied` | 2 | Nhân viên gọi 7 RPC | `PERMISSION_DENIED` × 7 |
| `hub_cost_attention` | 2 | Kỳ T−1 OPEN + run READY | owner: `cost_period_to_close`, `cost_runs_pending 1`; nhân viên `null` / `0` |
| bất biến (sau mọi ca) | — | — | theo sản phẩm `ledger_value_vnd = Σ amount_vnd`; mọi dòng run `balance_diff 0`; số dòng sổ cũ không đổi |

*Ghi chú `case10_close_then_mid`* (`PERIODIC`): dòng tháng T−1 (ví dụ 5.1) tạo bằng `_post_movements(p_business_date => ngày 15 tháng T−1)` ⇒ `PERIOD_CLOSE` + công bố (run 1, dòng `COGS_TRUE_UP` ngày cuối tháng T−1, kỳ T−1 `CLOSED`, kỳ T `OPEN`); dòng tháng T (`_today()`): bán 20 (theo 11.000) ⇒ `MID_PERIOD` + công bố (run 2); bán 5 ⇒ `MID_PERIOD` (run 3). Kỳ vọng: run 2 `opening 80 / 880.000`, `sale_qty 20`; run 3 `from_sequence` = `cut` run 2, `sale_qty 5` (không gồm dòng điều chỉnh run 1–2).

**Ca spec mục 9 đã có ở tệp khác** (đầu `inventory_costing.sql` ghi bảng này dạng comment):

| Ca spec | Tệp | Ca |
|---|---|---|
| 5 | `inventory_goods_receipts.sql` | `spec_example_4_1`, `allocation_rounding` |
| 12 | `inventory_goods_receipts.sql`, `inventory_supplier_programs.sql` | `tier_case12`, `hints_case12` |
| 13 | `inventory_goods_receipts.sql` | `buy_x_get_y_case13` |
| 14, 15 | `inventory_supplier_rebates.sql` | `case14_single_product`, `case15a_remainder`, `case15b_stock_over_q` |
| 17 | `inventory_supplier_rebates.sql` | `projected_reach`, `record_replay_same_key` |

### 2.6 Luật Flutter (`logic/costing/costing_rules.dart`) + mã lỗi

- `String periodLabel(DateTime month)` ⇒ `'MM/yyyy'`.
- `String runTitle(CostRunKind kind, DateTime month)` ⇒ `'Chốt kỳ 08/2026'` / `'Cập nhật giá vốn 11/2026'`.
- `String runSubtitle(CostRunView run)` ⇒ `'{n} sản phẩm · Thời điểm chốt dd/MM/yyyy · HH:mm'`; `n = 0` ⇒ bỏ phần `'{n} sản phẩm · '` (như `bj14Subtitle`).
- `String signedMoney(int v)` ⇒ `0` ⇒ `'0 đ'`; dương `'+50.400 đ'`; âm `'−25.000 đ'` (U+2212).
- `K6Status runStatus(CostRunRow r)` (nhãn / tone / phụ đề — chép `bj14StatusMeta` bỏ nhánh `CALCULATING`, `AD_HOC`, `NOT_CALCULATED`):

  | `status` | Nhãn | Tone | Phụ đề |
  |---|---|---|---|
  | `READY_FOR_REVIEW` | Sẵn sàng công bố | success | `'{n} sản phẩm · đã tính, chờ công bố'` |
  | `PUBLISHED` | Đã công bố | success | `'Công bố dd/MM/yyyy'` |
  | `STALE` | Cần tính lại | warning | `'{n} sản phẩm · dữ liệu đã đổi'` |
  | `BLOCKED` | Cần xử lý | warning | `'{k} việc cần xử lý'` |

- `BlockerView blockerView(CostBlocker b)` ⇒ `{title, detail?, actionLabel?, action}` (`action` enum `closePeriod`, `midPeriod`, `stocktakes`, `openPendingRun`, `none`):

  | Mã | `title` | `detail` | `actionLabel` |
  |---|---|---|---|
  | `PREVIOUS_PERIOD_OPEN` | `'Kỳ MM/yyyy chưa chốt'` | — | `'Chốt kỳ MM/yyyy'` |
  | `PERIOD_NOT_ENDED` | `'Tháng MM/yyyy chưa kết thúc'` | — | `'Cập nhật giữa kỳ'` |
  | `STOCKTAKE_OPEN` | `'Có phiên kiểm kê chưa ghi nhận'` | — | `'Mở kiểm kê'` |
  | `RUN_PENDING_REVIEW` | `'Đã có lần tính chờ công bố'` | — | `'Mở lần tính'` |
  | `LEDGER_MISMATCH` | `'Sổ số lượng và sổ giá trị không khớp ({n} sản phẩm)'` | `'Liên hệ hỗ trợ; không tự sửa.'` | — |
  | `NOTHING_TO_COST` | `'Không có biến động mới từ lần công bố trước'` | — | — |

- `List<CostRunLineView> topChanged(List<CostRunLineView> lines, int n)` = `lines.where((l) => l.lineAdjust != 0).take(n)` (server đã sắp).
- `(String label, String sentence) methodCopy(CostMethod m)`: `periodic` ⇒ `('Bình quân cuối kỳ', 'giá vốn mỗi sản phẩm là giá trung bình của tồn đầu kỳ và hàng nhập cả kỳ.')`; `moving` ⇒ `('Bình quân liên hoàn', 'giá vốn tính lại sau mỗi lần nhập.')`.

| Mã | Câu (`inventoryErrorMessage`) |
|---|---|
| `COST_RUN_STALE` | `'Dữ liệu đầu vào đã thay đổi. Hãy tạo lần tính kế tiếp.'` |
| `COST_RUN_NOT_READY` | `'Lần tính không còn ở trạng thái chờ công bố.'` |
| `COST_POLICY_LOCKED` | `'Đã công bố giá vốn nên không đổi được phương pháp.'` |

### 2.7 Màn + code prototype + ánh xạ Flutter

Route (`presentation/costing/costing_routes.dart`, `costingRoutes()`; mọi màn ngoài `StatefulShellRoute`): `/warehouse/costing` (072), `/warehouse/costing/new?kind=MID_PERIOD|PERIOD_CLOSE` (074 chưa tính), `/warehouse/costing/runs/:runId` (074), `/warehouse/costing/runs/:runId/result` (077). Nhân viên mở bằng URL ⇒ K1 `InventoryDenied(what: 'xem giá vốn', next: 'Chỉ chủ cửa hàng xem và công bố giá vốn.', exitLabel: 'Về Kho')` (chữ "Bạn chưa có quyền xem giá vốn").

Ảnh đích (`img/G5-6/`): `proto-072-READY-{390,1280}.png`, `proto-074-READY_FOR_REVIEW-{390,1280}.png`, `proto-074-BLOCKED-{390,1280}.png`, `proto-077-COMPLETED-{390,1280}.png`. Prototype không có dòng "Đổi", chân "Cập nhật giữa kỳ", nút "Xem chi tiết tính", "Bỏ lần tính" ⇒ ghi lệch có chủ đích ở Kết quả.

**CSS dùng chung** (`styles/screens.css:4220-4254`, token `styles/tokens.css`):
```css
.bj14-note { margin: 0; font: 400 13px/20px Inter, system-ui, sans-serif; color: var(--vet45-v2-text-secondary); }          /* #4A535E */
.bj14-method, .bj14-products, .bj14-writes, .bj14-scope, .bj14-section { display: flex; flex-direction: column; gap: var(--vet45-v2-space-2); } /* 8px */
.bj14-method__line { margin: 0; font: 400 14px/22px Inter, system-ui, sans-serif; color: var(--vet45-v2-text-primary); }  /* #0E1116 */
.bj14-method__line strong { font-weight: 600; }
.bj14-method__compare, .bj14-more { width: 100%; min-height: 44px; }
.bj14-diff { font: 600 13px/20px var(--vet45-v2-font-mono); font-variant-numeric: tabular-nums; white-space: nowrap; color: var(--vet45-v2-text-primary); }
.bj14-blockers { display: flex; flex-direction: column; background: var(--vet45-v2-surface-default); border: 1px solid var(--vet45-v2-border-default); border-radius: var(--vet45-v2-radius-card); overflow: hidden; } /* #FFF, #E5E8EB, 12px */
.bj14-blocker { display: grid; grid-template-columns: 20px minmax(0, 1fr); column-gap: var(--vet45-v2-space-2); row-gap: var(--vet45-v2-space-2); align-items: start; padding: var(--vet45-v2-space-3) var(--vet45-v2-space-4); border-bottom: 1px solid var(--vet45-v2-border-default); } /* 12px 16px */
.bj14-blocker:last-child { border-bottom: 0; }
.bj14-blocker__icon { grid-column: 1; grid-row: 1; margin-top: 2px; color: var(--vet45-v2-icon-warning); }                /* #935A0A */
.bj14-blocker__copy { grid-column: 2; grid-row: 1; display: flex; flex-direction: column; gap: 2px; min-width: 0; }
.bj14-blocker__copy strong { font: 600 14px/20px Inter, system-ui, sans-serif; color: var(--vet45-v2-text-primary); overflow-wrap: anywhere; }
.bj14-blocker__copy small { font: 400 13px/20px Inter, system-ui, sans-serif; color: var(--vet45-v2-text-secondary); overflow-wrap: anywhere; }
.bj14-blocker__action { grid-column: 2; grid-row: 2; justify-self: start; min-height: 44px; }
.bj14-sheet-facts { display: flex; flex-direction: column; margin-bottom: var(--vet45-v2-space-3); }
.device-preview.is-web .bj14-blocker { grid-template-columns: 20px minmax(0, 1fr) auto; align-items: center; }
.device-preview.is-web .bj14-blocker__action { grid-column: 3; grid-row: 1; }
.device-preview.is-web .k7-wide :is(.bj14-method, .bj14-writes, .bj14-products, .bj14-scope, .bj14-section, .ac310-metrics, .v-banner, .k1-stale-action) { width: 100%; max-width: none; box-sizing: border-box; }
.device-preview.is-web .bj14-method__compare, .device-preview.is-web .bj14-more { width: auto; align-self: flex-start; }
.device-preview.is-web .bj14-more { display: none; }
body[data-active-uif="UIF-14"] .ds24-key-value-row { display: flex; align-items: center; justify-content: space-between; gap: var(--vet45-v2-space-3); min-height: 44px; padding: var(--vet45-v2-space-2) 0; box-sizing: border-box; }
body[data-active-uif="UIF-14"] :is(.ac310-key-value-stack, .bj14-sheet-facts) > .ds24-key-value-row + .ds24-key-value-row { border-top: 1px solid var(--vet45-v2-border-default); }
body[data-active-uif="UIF-14"] .ds24-key-value-row > span { flex: 1 1 0; min-width: 0; font: 400 13px/20px Inter, system-ui, sans-serif; color: var(--vet45-v2-text-secondary); }
body[data-active-uif="UIF-14"] .ds24-key-value-row > strong { flex: 0 1 auto; min-width: 0; text-align: right; font: 600 14px/20px var(--vet45-v2-font-mono); font-variant-numeric: tabular-nums; white-space: nowrap; color: var(--vet45-v2-text-primary); }
```
Thẻ số liệu (`styles/screens.css:2940-2964`): `.ac310-metrics { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:8px }`; `.ac310-metric { min-height:76px; justify-content:center; gap:4px; padding:12px; border:1px solid #E5E8EB; border-radius:12px; background:#FFF }`; nhãn `400 12px/16px #4A535E`; giá trị `600 18px/24px` (Screen Contract mục 7: số tiền **mono**).

#### SCR-072 Giá vốn

```js
// app/bj14.js:226-238 (bj14StatusMeta) — Flutter: runStatus() mục 2.6, bỏ nhánh CALCULATING / AD_HOC / NOT_CALCULATED
// app/bj14.js:243-273
function bj14ListRows() { return bj14Runs.filter((r) => !bj14Superseded(r)); }
function bj14RowView(run) {
  const m = bj14StatusMeta(run);
  return { id: run.id, title: bj14Title(run), subtitle: m.sub, status: { label: m.label, tone: m.tone }, period: run.period, scope: run.scopeLabel, adj: bj14HasResult(run) ? t7FmtMoney(bj14Totals(run).net, true) : "—", statusHtml: ds24Badge(m.label, m.tone) };
}
function render072BJ14(state) {
  const title = "Giá vốn", subtitle = `Chính sách: ${BJ14_POLICY.label}`;
  if (state === "PERMISSION_DENIED" || !bj14CanView()) return bj14Denied(title);
  if (state === "LOADING") return bj14Shell({ title, subtitle, body: k1Loading({ blocks: ["row", "row", "row"] }), back: false });
  const all = state === "EMPTY" ? [] : bj14ListRows();
  const todo = all.filter((r) => r.status !== "PUBLISHED"), done = all.filter((r) => r.status === "PUBLISHED");
  const rows = (bj14Filter === "DONE" ? done : todo).map(bj14RowView);
  const columns = [{ key: "title", label: "Lần tính" }, { key: "period", label: "Kỳ", mono: true }, { key: "scope", label: "Phạm vi" }, { key: "adj", label: "Chênh lệch sẽ ghi", align: "end", mono: true }, { key: "statusHtml", label: "Tình trạng", html: true }];
  const body = k6TaskList({
    search: null, caption: "Công việc giá vốn",
    filters: { items: [["TODO", "Cần làm", todo.length], ["DONE", "Đã công bố", done.length]], selected: bj14Filter, attrName: "data-bj14-filter" },
    columns, rows, total: all.length, rowOpen: true,
    empty: { title: "Không có công việc giá vốn", description: "Chưa có phạm vi cần cập nhật hoặc chốt kỳ." },
    filterEmpty: { title: bj14Filter === "DONE" ? "Chưa có kỳ nào được công bố" : "Không còn việc cần làm", description: "Chọn mục khác để xem thêm.", actionLabel: "Xem tất cả", actionAttr: 'data-bj14-action="clear-filter"' },
  });
  const close = state === "EMPTY" ? null : bj14PeriodToClose();
  return bj14Shell({ title, subtitle, body, back: false, centered: state === "EMPTY", actions: close ? primaryFooter(`Chốt kỳ ${close}`, 'data-bj14-action="close-period"') : "" });
}
```

| Phần tử | Flutter | Tham số / ghi chú |
|---|---|---|
| Khung | `Scaffold` + `VAppBar(title: 'Giá vốn', subtitle: 'Chính sách: {label}')` trong `InventoryPage` của khuôn (như `StocktakeListPage`) | quay lại "Quay về Kho" |
| **Mới** — dòng "Đổi" | `VButton('Đổi', variant: text)` ở `VAppBar.actions` | chỉ khi `!methodLocked`; mở `CostMethodSheet` |
| Danh sách | `K6TaskList<CostRunRow>(search: null, filters: K7FilterChips([K7Filter('TODO','Cần làm',n), K7Filter('DONE','Đã công bố',n)]), columns: [Lần tính ← runTitle, Kỳ ← periodLabel mono, Phạm vi ← 'Toàn bộ sản phẩm', Chênh lệch sẽ ghi ← signedMoney(valueAdjustVnd) / '—' mono end, Tình trạng ← VBadge], title: runTitle, subtitle: runStatus().sub, status: runStatus, onOpen)` | `onOpen`: `PUBLISHED` ⇒ `/runs/:id/result`; khác ⇒ `/runs/:id` |
| Rỗng | `InventoryEmpty('Không có công việc giá vốn', 'Chưa có phạm vi cần cập nhật hoặc chốt kỳ.')` | |
| Chip rỗng | `InventoryEmpty(title theo chip, 'Chọn mục khác để xem thêm.', action 'Xem tất cả')` | |
| Chân | `InventoryFooter`: **mới** `'Cập nhật giữa kỳ'` (secondary; ẩn khi `hasPendingRun`) ⇒ `/new?kind=MID_PERIOD`; `'Chốt kỳ {periodLabel(periodToClose)}'` (primary; chỉ khi `periodToClose != null`) ⇒ `/new?kind=PERIOD_CLOSE` | không có cả hai ⇒ không chân |
| Đang tải | `InventoryLoading(blocks: 3 dòng)` | |

**Sheet "Chọn phương pháp giá vốn"** (mới, `CostMethodSheet`, `showVAdaptiveSheet`): `VChoiceList` hai dòng — tiêu đề `methodCopy().label`, phụ `methodCopy().sentence` viết hoa chữ đầu; `Text('Chỉ đổi được trước lần công bố giá vốn đầu tiên.')` kiểu `.bj14-note`; chân `'Quay lại'` (secondary) · `'Lưu'` (primary, tắt khi chưa đổi). Lưu ⇒ `setPolicy` ⇒ đóng sheet, tải lại 072; lỗi `COST_POLICY_LOCKED` ⇒ `VToast` câu mục 2.6, tải lại.

#### SCR-074 Chốt kỳ / Cập nhật giá vốn

```js
// app/bj14.js:274-354, 355-360
function bj14BlockerRow(b) {
  return `<div class="bj14-blocker"><span class="bj14-blocker__icon">${icon("alert", "icon--sm")}</span><span class="bj14-blocker__copy"><strong>${esc(b.title)}</strong><small>${esc(b.detail)}</small></span><button class="button button--secondary bj14-blocker__action">${esc(b.label)}</button></div>`;
}
function bj14MethodBlock(run, withCompare) {
  const [label, sentence] = bj14Method();
  const compare = withCompare ? `<button class="button button--secondary bj14-method__compare">${esc(`Xem đối chiếu theo ${bj14Method(true)[0]}`)}</button>` : "";
  return `<section class="bj14-method">${ds24SectionTitle("Phương pháp")}<p class="bj14-method__line"><strong>${esc(label)}</strong> — ${esc(sentence)}</p><p class="bj14-note">Theo chính sách của cửa hàng; không đổi theo lần tính.</p>${compare}</section>`;
}
function bj14ProductMobileRow(r) {
  const c = bj14CostOf(r);
  const sub = r.changed ? `${t7FmtMoney(r.oldCost)} → ${bj14Unit(c, r.uom)}` : `Giữ ${bj14Unit(r.oldCost, r.uom)}`;
  const trailing = r.changed ? `<strong class="bj14-diff">${esc(t7FmtMoney(r.diff, true))}</strong>` : ds24Badge("Không đổi", "Neutral");
  return ds24ListRow({ title: r.name, subtitle: sub, trailing, leading: null, type: "Status", density: "Compact", interactive: false });
}
function bj14ProductsBlock(run) {
  const rows = bj14ProductRows(run).map((r) => ({ ...r, product: `<strong>${esc(r.name)}</strong><small>${esc(r.code)}</small>`, oldText: bj14Unit(r.oldCost, r.uom), newText: r.changed ? bj14Unit(bj14CostOf(r), r.uom) : "—", diffHtml: r.changed ? esc(t7FmtMoney(r.diff, true)) : ds24Badge("Không đổi", "Neutral") }));
  const columns = [{ key: "product", label: "Sản phẩm", html: true }, { key: "oldText", label: "Giá vốn cũ", align: "end", mono: true }, { key: "newText", label: "Giá vốn mới", align: "end", mono: true }, { key: "diffHtml", label: "Chênh lệch", align: "end", mono: true, html: true }];
  const table = k7Table({ columns, rows, mobileRow: (r) => (rows.indexOf(r) >= 3 ? "" : bj14ProductMobileRow(r)), caption: "Theo sản phẩm" });
  const more = `<button class="button button--secondary bj14-more">${esc(`Xem ${rows.length} sản phẩm`)}</button>`;
  return `<section class="bj14-products">${ds24SectionTitle("Theo sản phẩm")}${table}${more}</section>`;
}
function bj14ResultMain(run, t) {
  const metrics = ac310SummaryMetrics([["Giá trị tồn cuối", t7FmtMoney(t.end)], ["Giá vốn xuất", t7FmtMoney(t.cogs)]]);
  const writes = `<section class="bj14-writes">${ds24SectionTitle("Thay đổi sẽ ghi khi công bố")}<p class="bj14-note">Chỉ phần chênh lệch dưới đây được ghi; chứng từ lịch sử không bị sửa.</p>${ac310KeyValueSurface("", [["Điều chỉnh giá vốn xuất", t7FmtMoney(t.cogsAdj, true), true], ["Điều chỉnh giá trị tồn", t7FmtMoney(t.endAdj, true), true]])}</section>`;
  return `${metrics}${writes}${bj14ProductsBlock(run)}${bj14MethodBlock(run, true)}`;
}
function bj14Summary(run, t) {
  return ac310KeyValueSurface("Tóm tắt", [["Kỳ", run.period], ["Phạm vi", run.scopeLabel], ["Thời điểm chốt", run.cutoff], ["Phương pháp", BJ14_POLICY.label], /* bỏ 2 dòng điều chỉnh — Screen Contract mục 3 */]);
}
function bj14SetupBody(run) { /* chốt kỳ / cập nhật chưa tính */
  const body = `${ds24InfoGroup("", ds24InfoRow("Kỳ", run.period) + ds24InfoRow("Phạm vi", run.scopeLabel))}${bj14MethodBlock(run, false)}`;
  return { body, actions: primaryFooter("Tính giá vốn", 'data-bj14-action="calculate"') };
}
function bj14BlockedBody(run) {
  const blockers = bj14Blockers(run), k = blockers.length;
  const banner = k ? vBanner("warning", "Chưa công bố được", `Xử lý ${k} việc dưới đây rồi tính lại.`) : vBanner("info", "Đã xử lý hết việc chặn", "Tính lại để có kết quả mới.");
  const list = k ? ds24GroupedCollection(blockers.map(bj14BlockerRow).join(""), "bj14-blockers") : "";
  return { body: `${banner}${list}${bj14MethodBlock(run, false)}`, actions: k4ReasonFooter({ label: "Tính lại", disabled: k > 0, reason: `Còn ${k} việc cần xử lý` }) };
}
function bj14PublishSheet(run, t) {
  const facts = `<div class="bj14-sheet-facts">${ds24InfoRow("Kỳ ghi nhận", run.period)}${ds24InfoRow("Phạm vi", run.scopeLabel)}${ds24InfoRow("Phương pháp", BJ14_POLICY.label)}${ds24KeyValueRow("Điều chỉnh giá vốn xuất", t7FmtMoney(t.cogsAdj, true), true)}${ds24KeyValueRow("Điều chỉnh giá trị tồn", t7FmtMoney(t.endAdj, true), true)}</div>`;
  return k2RejectSheet({ title: "Công bố giá vốn?", description: "Kết quả đã rà soát sẽ có hiệu lực. Hệ thống chỉ ghi phần chênh lệch, không sửa chứng từ lịch sử.", withReason: false, closeLabel: "Quay lại", confirmLabel: "Công bố giá vốn" }) /* + facts trước nút */;
}
function bj14CompareSheet(run) {
  const t = bj14Totals(run, true), [label] = bj14Method(true);
  return bj14InfoSheet(`Đối chiếu theo ${label}`, `<p class="bj14-note">Chỉ để đối chiếu; không dùng để công bố.</p>${ac310KeyValueSurface("", [["Giá trị tồn cuối", t7FmtMoney(t.end)], ["Giá vốn xuất", t7FmtMoney(t.cogs)]])}`);
}
function bj14ProductsSheet(run) { return bj14InfoSheet("Theo sản phẩm", ds24GroupedCollection(bj14ProductRows(run).map(bj14ProductMobileRow).join(""), "bj14-products-sheet")); }
function render074BJ14(state) {
  const run = bj14Current(), title = bj14Title(run), subtitle = bj14Subtitle(run);
  if (run.status === "CALCULATING") return bj14Shell({ title, subtitle, body: `${k1Loading({ blocks: ["heading", "card", "card"] })}<p class="bj14-note">Có thể rời màn hình. Kết quả được lưu trong cùng lần tính.</p>` });
  if (run.status === "INPUT_CHANGED") return bj14Shell({ title, subtitle, body: `${k1Stale({ title: "Dữ liệu đầu vào đã thay đổi", description: "Kết quả cũ được giữ để truy vết nhưng không còn đủ điều kiện công bố.", actionLabel: "Tạo lần tính kế tiếp" })}${bj14MethodBlock(run, false)}` });
  if (run.status === "BLOCKED" || run.status === "NOT_CALCULATED") { const v = run.status === "BLOCKED" ? bj14BlockedBody(run) : bj14SetupBody(run); return bj14Shell({ title, subtitle, body: v.body, actions: v.actions }); }
  const t = bj14Totals(run);
  const body = `${k7Split({ main: bj14ResultMain(run, t), aside: bj14Summary(run, t), wideMain: true, asideWebOnly: true })}${bj14SheetHtml(run, t)}`;
  return bj14Shell({ title, subtitle, body, actions: run.status === "READY_FOR_REVIEW" ? primaryFooter("Công bố giá vốn", 'data-bj14-action="open-publish"') : "" });
}
```

| Phần tử | Flutter | Tham số / ghi chú |
|---|---|---|
| Khung | `VAppBar(title: runTitle, subtitle: runSubtitle)`; web `K7Split(main, aside, wideMain: true, asideWebOnly: true)` | draft (`/new`): tiêu đề theo `kind` + `periodLabel` (MID = `openPeriod` hoặc tháng hiện tại; CLOSE = `periodToClose`), không phụ đề |
| Chưa tính | `VKeyValueGroup([VKeyValueRow('Kỳ', periodLabel), VKeyValueRow('Phạm vi', 'Toàn bộ sản phẩm')])` + khối Phương pháp (không nút đối chiếu) + `InventoryFooter('Tính giá vốn')` | bấm ⇒ trạng thái đang tính ⇒ `createRun` ⇒ `context.replace('/warehouse/costing/runs/:id')` |
| Đang tính | `InventoryLoading(blocks: heading, card, card)` + `Text('Có thể rời màn hình. Kết quả được lưu trong cùng lần tính.')` (`.bj14-note`) | trong lúc chờ RPC |
| Banner chặn | `VBanner(tone: warning, title: 'Chưa công bố được', message: 'Xử lý {k} việc dưới đây rồi tính lại.')` | |
| Danh sách chặn | `Container` viền `#E5E8EB` 1px, bo 12, nền surface; mỗi việc `CostBlockerRow`: lưới icon 20px `VIcons.warning` màu `iconWarning` (#935A0A) + cột (tiêu đề 600 14/20, `detail` 400 13/20 secondary) + `VButton(actionLabel, secondary, minHeight 44)` — iPhone nút dòng 2 dưới chữ, web cột 3 cùng hàng; padding 12/16, gạch dưới trừ dòng cuối | `action` ⇒ `closePeriod`: `/new?kind=PERIOD_CLOSE`; `midPeriod`: `/new?kind=MID_PERIOD`; `stocktakes`: `/warehouse/stocktakes`; `openPendingRun`: run READY từ overview (`/runs/:id`) |
| Chân chặn | `InventoryFooter('Tính lại')` **luôn bật** (lệch prototype `k4ReasonFooter` tắt — mục 1 Phần 3) + **mới** `VButton('Bỏ lần tính', text, tone danger)` | Tính lại ⇒ `createRun(kind)` ⇒ replace sang run mới |
| ② | `CostMetricCards([('Giá trị tồn cuối', closing_value), ('Giá vốn xuất', cogs_value)])` — widget mới ở `presentation/costing/` theo CSS `.ac310-metric` (giá trị mono 600 18/24) | |
| ③ | `VSection('Thay đổi sẽ ghi khi công bố')` + note + `VKeyValueGroup([('Điều chỉnh giá vốn xuất', signedMoney(cogs_adjust)), ('Điều chỉnh giá trị tồn', signedMoney(value_adjust))], mono)` | |
| ④ web | `K7Table` cột Sản phẩm (tên 600 + mã 13 secondary) · Giá vốn cũ (`'{x}/{uom}'` hoặc **'Giá tạm'**) · Giá vốn mới (`'{x}/{uom}'`, không đổi ⇒ `'—'`) · Chênh lệch (`signedMoney(line_adjust)`, `= 0` ⇒ `VBadge('Không đổi', neutral)`) | mono, căn phải |
| ④ iPhone | 3 dòng `VListRow(title: name, subtitle: '{cũ} → {mới}/{uom}' hoặc 'Giữ {cũ}/{uom}', trailing: Text mono 600 13/20 hoặc badge)` từ `topChanged(lines, 3)` + `VButton('Xem {n} sản phẩm', secondary, full width 44)` ⇒ sheet "Theo sản phẩm" (mọi dòng) | không đổi nào ⇒ 3 dòng đầu |
| **Mới** — "Xem chi tiết tính" | `VButton('Xem chi tiết tính', secondary)` dưới ④ (iPhone full width, web tự co) ⇒ `CostRunDetailSheet` | |
| ⑤ | `VSection('Phương pháp')` + `Text.rich(label 600 + ' — ' + sentence)` 14/22 + note `'Theo chính sách của cửa hàng; không đổi theo lần tính.'` + `VButton('Xem đối chiếu theo {label phương pháp kia}', secondary)` | sheet `'Đối chiếu theo {label}'`: note `'Chỉ để đối chiếu; không dùng để công bố.'` + `VKeyValueGroup('Giá trị tồn cuối' ← alt.closing_value, 'Giá vốn xuất' ← alt.cogs_value)` + `'Đóng'` |
| Tóm tắt (web) | `VKeyValueGroup(title: 'Tóm tắt', [Kỳ, Phạm vi 'Toàn bộ sản phẩm', Thời điểm chốt 'dd/MM/yyyy · HH:mm', Phương pháp])` | |
| Chân READY | `InventoryFooter`: **mới** `'Bỏ lần tính'` (text, danger) · `'Công bố giá vốn'` (primary) | Bỏ ⇒ `discard` ⇒ `go('/warehouse/costing')` |
| Sheet công bố | `showVAdaptiveSheet`: tiêu đề `'Công bố giá vốn?'`, mô tả (nguyên văn), `VKeyValueGroup` Kỳ ghi nhận · Phạm vi · Phương pháp · 2 dòng điều chỉnh (mono), chân `'Quay lại'` · `'Công bố giá vốn'` | xác nhận ⇒ `publish` ⇒ `go('/runs/:id/result')`; `COST_RUN_STALE` ⇒ đóng sheet, trạng thái STALE; lỗi khác ⇒ `VToast` + giữ màn (bấm lại dùng cùng khoá) |
| STALE | `InventoryStale(title: 'Dữ liệu đầu vào đã thay đổi', description: 'Kết quả cũ được giữ để truy vết nhưng không còn đủ điều kiện công bố.', actionLabel: 'Tạo lần tính kế tiếp')` + khối ⑤ | hành động ⇒ `createRun(run.kind)` ⇒ replace |

**Sheet "Chi tiết tính"** (mới, `CostRunDetailSheet`, chỉ đọc, `showVAdaptiveSheet` cao tối đa):
```
Chi tiết tính                                         [Đóng]
Sản phẩm      Tồn đầu  Nhập  Chiết khấu NCC  Xuất bán  Hao hụt  Tồn cuối  BQ liên hoàn  BQ cuối kỳ  Điều chỉnh
Nobivac DHPPi 0        150   0               70        0        80        11.250        11.000      −20.000 đ
              0 đ   1.650.000 đ  0 đ   750.000 đ  0 đ   880.000 đ
Tổng          …
Kiểm cân bằng: Khớp ✓            (lệch ⇒ badge warning "Kiểm cân bằng: Lệch {số} đ")
Tồn đầu + Nhập − Chiết khấu NCC = Giá vốn xuất + Hao hụt + Tồn cuối
```
Web: `K7Table` (mỗi ô SL trên, tiền dưới, mono; "Chiết khấu NCC" chỉ tiền; "Điều chỉnh" = `signedMoney(line_adjust)`; cột hai bình quân là đơn giá). Dòng "Tổng" cộng tiền. iPhone: mỗi sản phẩm một `VKeyValueGroup(title: name)` 9 dòng `'{SL} {uom} · {tiền}'`. Chân: `VBadge` "Kiểm cân bằng: Khớp" (success) / "Kiểm cân bằng: Lệch {signedMoney(Σ balance_diff)}" (warning) + câu công thức (`.bj14-note`) + `'Đóng'`. Tiêu đề cột "BQ" viết đầy đủ "Bình quân liên hoàn" / "Bình quân cuối kỳ".

#### SCR-077 Kết quả công bố

```js
// app/bj14.js:364-379 (bỏ nhánh UNKNOWN — D12)
function render077BJ14(state) {
  const title = "Kết quả công bố giá vốn";
  if (state === "PERMISSION_DENIED" || !bj14CanView()) return bj14Denied(title);
  if (state === "PROCESSING") return bj14Shell({ title, body: k1Loading({ blocks: ["heading", "card", "row"] }), centered: true, back: false });
  const run = bj14Current(), toList = { label: "Về giá vốn", attr: 'data-bj14-action="to-list"' };
  if (state === "REJECTED_EXECUTION") return k4Result({ screenTitle: title, kind: "warning", title: "Chưa công bố giá vốn", description: "Không có điều chỉnh hoặc phiên bản giá vốn mới.", facts: [["Kỳ ghi nhận", run.period]], next: [{ ...toList, primary: true }] });
  const t = bj14Totals(run);
  const facts = [["Kỳ ghi nhận", run.period], ["Phương pháp", BJ14_POLICY.label], ["Sản phẩm có giá vốn mới", String(t.changed)], ["Điều chỉnh giá vốn xuất", t7FmtMoney(t.cogsAdj, true)], ["Điều chỉnh giá trị tồn", t7FmtMoney(t.endAdj, true)], ["Công bố lúc", run.publishedAt || BJ14_AT]];
  return k4Result({ screenTitle: title, title: `Đã công bố giá vốn ${run.period}`, description: "Phần chênh lệch đã được ghi và giá vốn chính thức mới đã có hiệu lực.", facts, next: [toList, { label: "Xem báo cáo tồn", primary: true }] });
}
```

| Phần tử | Flutter | Ghi chú |
|---|---|---|
| Thành công | `K4ResultPage(screenTitle: 'Kết quả công bố giá vốn', title: 'Đã công bố giá vốn {periodLabel}', description: …, facts: [Kỳ ghi nhận, Phương pháp (label), Sản phẩm có giá vốn mới ← changed_count, Điều chỉnh giá vốn xuất ← signedMoney(cogs_adjust) mono, Điều chỉnh giá trị tồn ← signedMoney(value_adjust) mono, Công bố lúc 'dd/MM/yyyy · HH:mm'], next: [InventoryFooterAction('Về giá vốn', primary)])` | "Xem báo cáo tồn" ẩn tới G5-7; nạp bằng `getRun` (vào từ sheet hoặc dòng 072) |
| Từ chối | `K4ResultPage(kind: warning, title: 'Chưa công bố giá vốn', description: 'Không có điều chỉnh hoặc phiên bản giá vốn mới.', facts: [Kỳ ghi nhận], next: ['Về giá vốn'])` | run tải về không phải `PUBLISHED` |
| Đang tải | `InventoryLoading(blocks: heading, card, row)` | |

#### SCR-003 — "Lịch sử giá vốn" (mới)

`StockCostBlock` thêm tham số `VoidCallback? onShowVersions`; khi không null (chỉ chủ cửa hàng — `StockDetailBody` truyền khi `!financialMasked`), dưới `VKeyValueRow('Giá trị tồn (sổ)')` thêm `VButton('Lịch sử giá vốn', variant: text)`. Mở `CostVersionsSheet(productId)`: tiêu đề `'Lịch sử giá vốn'`; mỗi phiên bản `VListRow(title: '{đơn giá}/{uom}', subtitle: '{methodCopy().label} · Công bố dd/MM/yyyy · {run_code}')`; rỗng ⇒ `Text('Chưa có giá vốn chính thức')`; lỗi ⇒ câu `inventoryErrorMessage` + `'Thử lại'`; chân `'Đóng'`.

#### Hub

`warehouse_entries.dart`: lối `cogs` `route: '/warehouse/costing'`. `WarehouseHubSummary` thêm `costPeriodToClose (DateTime?)`, `costRunsPending (int)`. "Cần chú ý" (owner, sau "Chương trình đạt mốc"): `VListRow(asCard, leading: VIcons.coins, title: 'Kỳ {MM/yyyy} chưa chốt giá vốn', subtitle: 'Tháng đã kết thúc, cần chốt giá vốn', onTap: /warehouse/costing)` và `VListRow(title: 'Lần tính giá vốn chờ công bố', subtitle: '{n} lần tính đã tính, chờ công bố', trailing: badge n, onTap: /warehouse/costing)`.

### 2.8 Ngoài phạm vi

Nhiều phạm vi chốt; "Sản phẩm cần tính lại" + nguyên nhân (không theo dõi); việc chặn BJ-03 / BJ-11 / BJ-16; K3 / BJ-17; "Xem báo cáo tồn" (G5-7); báo cáo lãi gộp (G5-7, đọc `COGS_TRUE_UP` / `LOSS_TRUE_UP` với `−amount`); tính lần tính chạy nền (RPC đồng bộ).

## 3. Tệp

| Tệp | Task |
|---|---|
| `supabase/migrations/20261118001_inventory_costing.sql` (mới), `REGISTRY.yaml` | 1, 2 |
| `supabase/migrations/20261110001_inventory_core.sql` (`_ensure_open_period`, check `kind`, `get_warehouse_hub_summary`) | 1, 2 |
| `supabase/migrations/20261117001_inventory_supplier_rebates.sql` (`_post_value_adjustment`) | 2 |
| `supabase/migrations/20261115001_inventory_sales_link.sql` (`_reversal_kind`), `supabase/tests/inventory_sales_link.sql` | 2 |
| `supabase/tests/inventory_costing.sql` (mới) | 1, 2 |
| `apps/erp/test/features/inventory/data/costing_sql_contract_test.dart` (mới) | 1, 2 |
| `apps/erp/lib/features/inventory/data/costing/{costing_models,costing_repository}.dart` (mới), `data/core/inventory_error_codes.dart` | 3 |
| `apps/erp/lib/features/inventory/logic/costing/costing_rules.dart`, `cost_overview_cubit/state.dart`, `cost_run_cubit/state.dart`, `cost_versions_cubit/state.dart` (mới) | 3, 4 |
| `apps/erp/lib/features/inventory/presentation/costing/` (mới): `cost_overview_page.dart`, `cost_method_sheet.dart`, `cost_run_page.dart`, `cost_run_blocks.dart` (metric cards, blocker row, khối ③④⑤, tóm tắt), `cost_run_sheets.dart` (công bố, đối chiếu, theo sản phẩm), `cost_run_detail_sheet.dart`, `cost_result_page.dart`, `cost_versions_sheet.dart`, `costing_routes.dart` | 5, 6, 7, 8 |
| `presentation/stock/stock_cost_block.dart`, `stock_detail_body.dart` | 7 |
| `data/hub/warehouse_hub_{summary,repository}.dart`, `presentation/hub/{warehouse_hub_page,warehouse_entries}.dart`, `core/router/app_router.dart`, `core/di/injection.dart` | 8 |
| Test Flutter `apps/erp/test/features/inventory/{data,logic,presentation}/costing/` | 3–9 |
| `docs/refactor/PLAN.md` | 9 |

## 4. Task

### Task 0: Mốc + impact

- [x] Ghi mốc: `git rev-parse HEAD`, `cd apps/erp && flutter test --no-pub -r compact test/features/inventory` (số đỏ), `tools/db_check.sh` (✅ / nợ đã biết).
- [x] `impact` upstream cho mọi symbol ở Global Constraints; ghi bảng vào Kết quả; HIGH / CRITICAL ⇒ dừng, hỏi người dùng.

### Task 1: SQL — bảng, sửa kỳ, tính, tạo / đọc run

**Files:** migration mới (mục 2.1; `_cost_run_compute`, `_cost_run_is_stale`, `_cost_run_view`, `create_cost_run`, `get_cost_run`); `20261110001` (`_ensure_open_period`, check `kind`); `inventory_costing.sql`; `costing_sql_contract_test.dart`.

**Interfaces — Produces:** chữ ký mục 2.2; `CostRunView` mục 2.2.

- [x] Viết ca test Task 1 ở mục 2.5 (`case1_moving`, `case4_rounding` phần dòng run, `period_close_cutoff_by_month`, `period_close_empty_segment`, `mid_blocked_previous_open`, `blockers_misc`, `ledger_mismatch`) + bất biến; viết test hợp đồng: có 5 hàm, `security definer`, `revoke` hàm `_`, `grant` 2 RPC, `_assert_actor(p_tenant_id, 'inventory.read', true)` đứng trước truy vấn đầu, `for update` trên `ledger_counters` trước khi tính, có 6 mã blocker, unique một phần `READY_FOR_REVIEW`.
- [x] Chạy `tools/db_check.sh --no-reset inventory_costing` ⇒ đỏ (hàm chưa có).
- [x] Viết migration + sửa `20261110001` theo mục 2.1–2.4 (phần tạo) và 2.5 (2 dòng đầu bảng sửa lõi).
- [x] `tools/db_check.sh` ⇒ ✅ (mọi tệp, kể cả plan trước); `flutter test --no-pub -r compact test/features/inventory/data/costing_sql_contract_test.dart` ⇒ xanh.
- [ ] Commit `feat(inventory): lần tính giá vốn — bảng, tính đoạn, điều kiện chặn (G5-6 Task 1)`.

### Task 2: SQL — công bố, bỏ, chính sách, tổng quan, lịch sử, sửa lõi, Hub

**Files:** migration mới (`publish_cost_run`, `discard_cost_run`, `set_cost_policy`, `get_cost_overview`, `list_cost_versions`); `20261117001` (`_post_value_adjustment`); `20261115001` (`_reversal_kind`) + `inventory_sales_link.sql`; `20261110001` (`get_warehouse_hub_summary`); `inventory_costing.sql`; test hợp đồng.

**Interfaces — Consumes:** Task 1. **Produces:** chữ ký mục 2.2; khoá Hub `cost_period_to_close`, `cost_runs_pending`.

- [x] Viết các ca Task 2 ở mục 2.5 + bất biến; test hợp đồng thêm: 5 hàm, khoá `cost` trước `for update` run, khoá sản phẩm theo `product_id` tăng trong `publish_cost_run`, 3 mã lỗi mới, `_reversal_kind` đọc `cost_runs`.
- [x] Chạy ⇒ đỏ.
- [x] Viết mục 2.4 "Công bố" + 2.2 + bảng sửa lõi mục 2.5 (2 dòng cuối); sửa fixture `reversal_kind_return_in`.
- [x] `tools/db_check.sh` ⇒ ✅; test hợp đồng ⇒ xanh.
- [ ] Commit `feat(inventory): công bố giá vốn, chốt kỳ, chính sách, Hub (G5-6 Task 2)`.

### Task 3: Model + repository + luật thuần + mã lỗi

**Files:** `data/costing/costing_models.dart`, `costing_repository.dart`; `logic/costing/costing_rules.dart`; `inventory_error_codes.dart`; test `data/costing/costing_models_test.dart`, `logic/costing/costing_rules_test.dart`.

**Interfaces — Produces:**
- `enum CostRunKind { midPeriod, periodClose }` (`'MID_PERIOD'`, `'PERIOD_CLOSE'`); `enum CostRunStatus { readyForReview, blocked, stale, published, superseded }`; dùng lại `CostMethod` của `data/stock/stock_models.dart`.
- `CostOverview {CostMethod method; bool methodLocked; DateTime? openPeriod; DateTime? periodToClose; bool hasPendingRun; List<CostRunRow> runs}`; `CostRunRow {runId, code, kind, periodMonth, status, productCount, blockerCount, int? valueAdjustVnd, DateTime? publishedAt, createdAt}`; `CostBlocker {String code; DateTime? periodMonth; int? productCount}`; `CostRunView {…mục 2.2; CostTotals totals; CostAlt alt; List<CostRunLineView> lines}`; `CostRunLineView {productId, name, code, uom, num? oldOfficialUnitCost, num? newUnitCost, openingQty, int openingValue, inboundQty, int inboundValue, int rebateValue, saleQty, int saleValueRecorded, lossQty, int lossValueRecorded, closingQty, num movingAvgEnd, num? periodicAvg, int cogsTrueUp, int lossTrueUp, int roundingAdjust, int closingValueAfter, int lineAdjust, int balanceDiff}`; `CostVersionList {productId, name, uom, List<CostVersion> versions}`; `CostVersion {versionId, num unitCost, CostMethod method, String runCode, DateTime publishedAt}`. Mỗi lớp `fromJson`, `Equatable`.
- `CostingRepository({required InventoryRpc rpc})`: `Future<CostOverview> overview()`, `Future<({CostMethod method, bool methodLocked})> setPolicy({required String idempotencyKey, required CostMethod method})`, `Future<CostRunView> createRun({required String idempotencyKey, required CostRunKind kind})`, `Future<CostRunView> getRun(String runId)`, `Future<CostRunView> publish({required String idempotencyKey, required String runId})`, `Future<void> discard({required String idempotencyKey, required String runId})`, `Future<CostVersionList> versions(String productId)`. Scope `mutate` theo Global Constraints.
- Luật mục 2.6; `InventoryErrorCode.costRunStale/costRunNotReady/costPolicyLocked` + câu.

- [x] Test: `fromJson` của `CostRunView` với JSON ví dụ 5.1 `PERIODIC` (`totals.cogs_adjust 20000`, `value_adjust −20000`, `lines[0].lineAdjust −20000`, `oldOfficialUnitCost null`); `signedMoney(50400) == '+50.400 đ'`, `signedMoney(-25000) == '−25.000 đ'`, `signedMoney(0) == '0 đ'`; `runTitle(periodClose, 2026-08-01) == 'Chốt kỳ 08/2026'`; `runSubtitle` có / không số sản phẩm; `runStatus` đủ 4 hàng bảng; `blockerView` đủ 6 hàng; `topChanged` bỏ dòng 0; `inventoryErrorMessage` 3 mã.
- [x] Chạy ⇒ đỏ; viết code; chạy ⇒ xanh; `dart analyze` sạch.
- [ ] Commit `feat(inventory): model, repository, luật giá vốn (G5-6 Task 3)`.

### Task 4: Cubit

**Files:** `logic/costing/cost_overview_cubit.dart` + state, `cost_run_cubit.dart` + state, `cost_versions_cubit.dart` + state; test cùng tên.

**Interfaces — Produces:**
- `CostOverviewCubit(repo)`: `load()`, `selectFilter(CostRunFilter todo|done)`, `changeMethod(CostMethod)`; state `CostOverviewState {status: loading|ready|denied|error, CostOverview? data, CostRunFilter filter, String? message, bool savingMethod}`. `PERMISSION_DENIED` ⇒ `denied`.
- `CostRunCubit(repo)`: `startDraft(CostRunKind, DateTime period)`, `load(runId)`, `calculate()` (draft / blocked / stale ⇒ `createRun(kind)`; một khoá mỗi lần bấm), `publish()` (khoá giữ nguyên khi thử lại sau lỗi mạng, đổi khi thành công), `discard()`; state `CostRunState {phase: draft|calculating|loaded|publishing|published|discarded|denied|error, CostRunKind kind, DateTime? period, CostRunView? run, String? message}`. `COST_RUN_STALE` khi công bố ⇒ `run.status = stale` (copyWith), `phase loaded`.
- `CostVersionsCubit(repo)`: `load(productId)`; state `{loading|ready|error, CostVersionList?}`.

- [x] Test (`bloc_test`, fake repo): `overview_denied`, `change_method_locked_shows_message_and_reloads`, `calculate_from_draft_emits_calculating_then_loaded`, `calculate_blocked_keeps_blockers`, `publish_success_emits_published`, `publish_stale_marks_stale` (Review Focus 4), `publish_network_error_retries_same_key`, `discard_emits_discarded`.
- [x] Chạy ⇒ đỏ; viết; xanh; `dart analyze`.
- [ ] Commit `feat(inventory): cubit giá vốn (G5-6 Task 4)`.

### Task 5: SCR-072 Giá vốn + sheet đổi phương pháp

**Files:** `presentation/costing/cost_overview_page.dart`, `cost_method_sheet.dart`; test `presentation/costing/cost_overview_page_test.dart`.

- [x] Widget test (fake repo, 390 + 1280): `overview_ready_390` (2 chip có số, dòng "Cập nhật giá vốn 11/2026" phụ "12 sản phẩm · đã tính, chờ công bố", badge "Sẵn sàng công bố"), `overview_ready_1280` (bảng 5 cột, "Chênh lệch sẽ ghi" `'+20.000 đ'`/`'—'`), `overview_close_footer` ("Chốt kỳ 10/2026" chỉ khi `periodToClose`; "Cập nhật giữa kỳ" ẩn khi `hasPendingRun`), `overview_change_hidden_when_locked`, `method_sheet_saves`, `overview_empty`, `overview_denied_390`, `open_published_goes_result`.
- [x] Chạy ⇒ đỏ; dựng theo bảng ánh xạ 072; xanh.
- [ ] Commit `feat(inventory): màn Giá vốn 072 (G5-6 Task 5)`.

### Task 6: SCR-074 + các sheet

**Files:** `cost_run_page.dart`, `cost_run_blocks.dart`, `cost_run_sheets.dart`, `cost_run_detail_sheet.dart`; test `cost_run_page_test.dart`, `cost_run_detail_sheet_test.dart`.

- [x] Widget test: `draft_mid_shows_period_scope_method`, `calculating_shows_note`, `ready_390` (2 thẻ, ③ hai dòng mono, 3 dòng ④ + "Xem 5 sản phẩm", ⑤ có nút đối chiếu, chân "Bỏ lần tính" · "Công bố giá vốn"), `ready_1280` (K7Split có "Tóm tắt" 4 dòng, bảng ④ có "Giá tạm" và badge "Không đổi", không có "Xem 5 sản phẩm"), `blocked_390` (banner "Xử lý 2 việc dưới đây rồi tính lại.", nút "Chốt kỳ 10/2026" mở `/new?kind=PERIOD_CLOSE`, `LEDGER_MISMATCH` không nút), `publish_sheet_facts_and_confirm`, `publish_stale_shows_input_changed_390` (Review Focus 4), `compare_sheet_alt_totals`, `detail_sheet_balance_ok` / `detail_sheet_balance_off` (badge "Kiểm cân bằng: Lệch −3 đ"), `denied_390`.
- [x] Chạy ⇒ đỏ; dựng theo bảng ánh xạ 074; xanh.
- [ ] Commit `feat(inventory): màn chốt kỳ / cập nhật giá vốn 074 (G5-6 Task 6)`.

### Task 7: SCR-077 + "Lịch sử giá vốn" ở SCR-003

**Files:** `cost_result_page.dart`, `cost_versions_sheet.dart`; sửa `stock_cost_block.dart`, `stock_detail_body.dart`; test `cost_result_page_test.dart`, `cost_versions_sheet_test.dart`, test SCR-003 hiện có.

- [x] Widget test: `result_completed_390/1280` (6 dòng đúng thứ tự, chỉ nút "Về giá vốn"), `result_rejected_when_not_published`, `versions_sheet_rows` ("11.000 đ/hộp", "Bình quân cuối kỳ · Công bố 03/11/2026 · GV-2611-01"), `versions_sheet_empty`, `stock_cost_block_versions_link_owner_only` (nhân viên không thấy "Lịch sử giá vốn").
- [x] Chạy ⇒ đỏ; dựng; xanh; test SCR-003 cũ vẫn xanh.
- [ ] Commit `feat(inventory): kết quả công bố 077, lịch sử giá vốn (G5-6 Task 7)`.

### Task 8: Route, DI, Hub, luồng đầu–cuối

**Files:** `costing_routes.dart`; `app_router.dart` (thêm `...costingRoutes()` cạnh `stocktakeRoutes()`); `injection.dart` (`CostingRepository`); Hub (mục 2.7 "Hub"); test `presentation/costing/costing_flow_test.dart`, test Hub hiện có.

- [x] Test: `hub_cogs_entry_routes_costing`, `hub_attention_cost_rows_owner_only`; luồng `costing_flow_mid_period` trên fake repo: 072 rỗng ⇒ "Cập nhật giữa kỳ" ⇒ "Tính giá vốn" ⇒ 074 READY ⇒ sheet ⇒ "Công bố giá vốn" ⇒ 077 ⇒ "Về giá vốn" ⇒ 072 dòng "Đã công bố" ở chip "Đã công bố".
- [x] Chạy ⇒ đỏ; viết; xanh; `dart analyze`.
- [ ] Commit `feat(inventory): route, Hub, luồng giá vốn (G5-6 Task 8)`.

### Task 9: Ảnh Flutter + kiểm cuối + PLAN

- [x] Golden `matchesGoldenFile` 390 / 1280 cho 072 READY, 074 READY_FOR_REVIEW, 074 BLOCKED, 077 COMPLETED ⇒ `docs/refactor/plans/T7/img/G5-6/flutter-<SCR>-<trạng thái>-{390,1280}.png`; so với ảnh `proto-…`, ghi lệch vào Kết quả (kể cả lệch có chủ đích: "Đổi", "Cập nhật giữa kỳ", "Xem chi tiết tính", "Bỏ lần tính", "Tính lại" luôn bật, ẩn "Xem báo cáo tồn").
- [x] `tools/db_check.sh` ⇒ ✅; `flutter test --no-pub -r compact test/features/inventory` ⇒ không đỏ hơn mốc Task 0; `dart analyze` sạch; `detect_changes({scope: "compare", base_ref: "main"})` ghi Kết quả.
- [x] PLAN.md: dòng G5-6 (Làm ✅ + ngày); tiêu chí #8 sửa "17 kịch bản … `inventory_costing.sql`" thành "17 kịch bản spec mục 9 (`inventory_costing.sql` + ca trỏ ở plan G5-6 mục 2.5)"; ghi chú mốc chốt theo tháng (D1) + dấu sổ (D5) vào mục "Giá vốn" cho G5-7.
- [ ] Reset Dev `--linked`: **hỏi người dùng**.
- [ ] Commit `docs(refactor): kết quả G5-6, ảnh Flutter`.

## 5. Kết quả

### Task 0: Mốc + impact (2026-11-12)

- **Git HEAD:** `cef783d1d03fa27e95e38bbe7a60dc7fb8bc1fc1`
- **Flutter test (`test/features/inventory`):** `549` passed, `0` failed (`All tests passed!`).
- **DB check (`tools/db_check.sh`):** ✅ DB check đạt.
  - `plpgsql_check`: 2 nợ đã biết (`catalog.create_product:44`, `einvoice.record_issuance_undetermined:42`), 0 lỗi mới.
  - `supabase/tests/*.sql`: mọi suite inventory đạt; 3 nợ đã biết (`catalog_th02`, `einvoice_th08`, `pricing_th04`).
- **GitNexus `impact` upstream** (chạy qua `node .gitnexus/run.cjs impact <symbol> -r erp-sales-inventory -d upstream`):

| Symbol | Kết quả | Direct | Impacted | Risk | Ghi chú |
|---|---|---|---|---|---|
| `inventory._ensure_open_period` | Not found | 0 | 0 | `UNKNOWN` | SQL chưa được index trong callgraph |
| `inventory._post_value_adjustment` | Not found | 0 | 0 | `UNKNOWN` | SQL chưa được index trong callgraph |
| `inventory._reversal_kind` | Not found | 0 | 0 | `UNKNOWN` | SQL chưa được index trong callgraph |
| `inventory.get_warehouse_hub_summary` | Not found | 0 | 0 | `UNKNOWN` | SQL chưa được index trong callgraph |
| `StockCostBlock` | Exact (partial) | 1568 | 1865 | `CRITICAL` | Fan-out qua `build` / widget tree (20 modules) |
| `StockDetailBody` | Exact (partial) | 1568 | 1865 | `CRITICAL` | Fan-out qua `build` / widget tree (20 modules) |
| `WarehouseHubSummary` | Exact (partial) | 1562 | 1853 | `CRITICAL` | Fan-out qua `build` / widget tree (20 modules) |
| `WarehouseHubRepository` | Exact (partial) | 1568 | 1865 | `CRITICAL` | Fan-out qua `build` / widget tree (20 modules) |
| `WarehouseHubPage` | Exact (partial) | 1568 | 1865 | `CRITICAL` | Fan-out qua `build` / widget tree (20 modules) |
| `warehouseAreaEntries` | Ambiguous (2) | 1568 | 1865 | `CRITICAL` | `maxRisk: CRITICAL` |
| `inventoryErrorMessage` | Exact (partial) | 1562 | 1853 | `CRITICAL` | Fan-out qua `build` / widget tree (20 modules) |
| `InventoryErrorCode` | Exact (partial) | 1568 | 1865 | `CRITICAL` | Fan-out qua `build` / widget tree (20 modules) |
| `app_router.dart` | Exact (partial) | 1562 | 1853 | `CRITICAL` | Fan-out qua `build` / widget tree (20 modules) |
| `injection.dart` | Exact (partial) | 1568 | 1865 | `CRITICAL` | Fan-out qua `build` / widget tree (20 modules) |

> ⚠️ Cảnh báo: 10 symbol Flutter đều trả mức `CRITICAL` (1853–1865 impacted symbols qua `build` / widget graph). Dừng sau Task 0 để báo người dùng và xin xác nhận trước khi tiếp tục Task 1.

### Task 1: SQL — bảng, sửa kỳ, tính, tạo / đọc run (2026-11-12)

- **Tệp tạo mới:**
  - `supabase/migrations/20261118001_inventory_costing.sql`: bảng `cost_runs`, `cost_run_lines` (RLS, revoke all, partial unique `READY_FOR_REVIEW`, trigger append-only cho `cost_run_lines`, 3 FK từ `cost_versions`/`cost_periods`/`value_movements`, 2 index); 5 hàm `_cost_run_compute`, `_cost_run_is_stale`, `_cost_run_view`, `create_cost_run`, `get_cost_run`.
  - `supabase/tests/inventory_costing.sql`: các ca Task 1 (`case1_moving`, `case4_rounding`, `period_close_cutoff_by_month`, `period_close_empty_segment`, `mid_blocked_previous_open`, `blockers_misc`, `ledger_mismatch`) + bất biến `balance_diff = 0`.
  - `apps/erp/test/features/inventory/data/costing_sql_contract_test.dart`: test hợp đồng Task 1.
- **Tệp sửa:**
  - `supabase/migrations/20261110001_inventory_core.sql`: `_ensure_open_period` chặn kỳ cũ hơn kỳ đã `CLOSED` (`PERIOD_CLOSED`); bỏ `'OPENING'` khỏi check `value_movements.kind`.
  - `supabase/migrations/REGISTRY.yaml`: đăng ký 5 hàm mới.
- **Kiểm tra:**
  - `tools/db_check.sh`: ✅ DB check đạt (`inventory_costing: Task 1 cases passed`, mọi suite inventory đạt, `plpgsql_check` 0 lỗi mới).
  - `cd apps/erp && flutter test --no-pub -r compact test/features/inventory/data/costing_sql_contract_test.dart`: `3` passed, `0` failed.
- **Commit:** chưa commit theo yêu cầu người dùng.

### Task 2: SQL — công bố, bỏ, chính sách, tổng quan, lịch sử, sửa lõi, Hub (2026-11-12)

- **Tệp cập nhật:**
  - `supabase/migrations/20261118001_inventory_costing.sql`: thêm 5 RPC (`get_cost_overview`, `set_cost_policy`, `publish_cost_run`, `discard_cost_run`, `list_cost_versions`) cùng khoá `cost`, khoá sản phẩm tăng dần, idempotency, 3 mã lỗi mới (`COST_RUN_STALE`, `COST_RUN_NOT_READY`, `COST_POLICY_LOCKED`).
  - `supabase/migrations/20261117001_inventory_supplier_rebates.sql`: `_post_value_adjustment` chỉ chặn `V_after < 0` với `SUPPLIER_REBATE`; `avg_after = greatest(round(V/q, 4), 0)`.
  - `supabase/migrations/20261115001_inventory_sales_link.sql` + `supabase/tests/inventory_sales_link.sql`: `_reversal_kind` kiểm tra `cost_runs PUBLISHED` (`cut_off_sequence >= v_seq`), cập nhật fixture `reversal_kind_return_in`.
  - `supabase/migrations/20261110001_inventory_core.sql`: `get_warehouse_hub_summary` thêm `cost_period_to_close`, `cost_runs_pending` cho owner (`null`/`0` với staff).
  - `supabase/migrations/REGISTRY.yaml`: đăng ký 5 RPC mới.
  - `supabase/tests/inventory_costing.sql`: thêm toàn bộ ca Task 2 (`case2_periodic`, `case3_periodic_prior_official`, `case4_rounding`, `case6_reversal_return`, `case7_loss_periodic`, `case8_closed_period`, `ensure_period_older_than_closed`, `case9_*`, `case10_close_then_mid`, `case11_sale_during_review`, `case11b_sold_out_after_cutoff`, `case16_rebate_periodic`, `publish_empty_close`, `discard_and_supersede`, `reversal_kind_after_cutoff_before_publish`, `staff_denied`, `hub_cost_attention`, bất biến `ledger_value_vnd`).
  - `apps/erp/test/features/inventory/data/costing_sql_contract_test.dart`: thêm test hợp đồng Task 2.
- **Kiểm tra:**
  - `tools/db_check.sh`: ✅ DB check đạt (`inventory_costing: Task 1 & Task 2 cases passed`, `inventory_sales_link` đạt, mọi suite inventory đạt, `plpgsql_check` 0 lỗi mới).
  - `cd apps/erp && flutter test --no-pub -r compact test/features/inventory/data/costing_sql_contract_test.dart`: `5` passed, `0` failed.
- **Commit:** chưa commit theo yêu cầu người dùng.

### Task 3: Model + repository + luật thuần + mã lỗi (2026-11-12)

- **Tệp tạo mới / cập nhật:**
  - `apps/erp/lib/features/inventory/data/costing/costing_models.dart`: `CostRunKind`, `CostRunStatus`, `CostOverview`, `CostRunRow`, `CostBlocker`, `CostTotals`, `CostAlt`, `CostRunLineView`, `CostRunView`, `CostVersion`, `CostVersionList`.
  - `apps/erp/lib/features/inventory/data/costing/costing_repository.dart`: `CostingRepository` với 7 RPC (`overview`, `setPolicy`, `createRun`, `getRun`, `publish`, `discard`, `versions`).
  - `apps/erp/lib/features/inventory/logic/costing/costing_rules.dart`: `periodLabel`, `runTitle`, `runSubtitle`, `signedMoney`, `moneyWithSpace`, `runStatus`, `blockerView`, `topChanged`, `methodCopy`.
  - `apps/erp/lib/features/inventory/data/core/inventory_error_codes.dart`: thêm `costRunStale`, `costRunNotReady`, `costPolicyLocked` và câu thông báo.
  - `apps/erp/test/features/inventory/data/costing/costing_models_test.dart`, `apps/erp/test/features/inventory/logic/costing/costing_rules_test.dart`.
- **Kiểm tra:**
  - `flutter test --no-pub -r compact test/features/inventory/data/costing/costing_models_test.dart test/features/inventory/logic/costing/costing_rules_test.dart`: `8` passed, `0` failed.
  - `dart analyze` trên các tệp Task 3: `No issues found!`; `dart run tool/check_feature_imports.dart`: 0 vi phạm trong `inventory`.
- **Commit:** chưa commit theo yêu cầu người dùng.

### Task 4: Cubit (2026-11-12)

- **Tệp tạo mới:**
  - `apps/erp/lib/features/inventory/logic/costing/cost_overview_state.dart`, `cost_overview_cubit.dart`
  - `apps/erp/lib/features/inventory/logic/costing/cost_run_state.dart`, `cost_run_cubit.dart`
  - `apps/erp/lib/features/inventory/logic/costing/cost_versions_state.dart`, `cost_versions_cubit.dart`
  - `apps/erp/test/features/inventory/logic/costing/cost_overview_cubit_test.dart`, `cost_run_cubit_test.dart`, `cost_versions_cubit_test.dart` (dùng `flutter_test` + fake repo thay cho `bloc_test` do `pubspec.yaml` không khai báo `bloc_test`).
- **Kiểm tra:**
  - `flutter test --no-pub -r compact test/features/inventory/logic/costing/cost_overview_cubit_test.dart test/features/inventory/logic/costing/cost_run_cubit_test.dart test/features/inventory/logic/costing/cost_versions_cubit_test.dart`: `9` passed, `0` failed.
  - `dart analyze lib/features/inventory/logic/costing test/features/inventory/logic/costing`: `No issues found!`.
- **Commit:** chưa commit theo yêu cầu người dùng.

### Task 5: SCR-072 Giá vốn + sheet đổi phương pháp (2026-11-12)

- **Tệp tạo mới:**
  - `apps/erp/lib/features/inventory/presentation/costing/cost_overview_page.dart`
  - `apps/erp/lib/features/inventory/presentation/costing/cost_method_sheet.dart`
  - `apps/erp/test/features/inventory/presentation/costing/cost_overview_page_test.dart`
- **Kiểm tra:**
  - `flutter test --no-pub -r compact test/features/inventory/presentation/costing/cost_overview_page_test.dart`: `8` passed, `0` failed (`overview_ready_390`, `overview_ready_1280`, `overview_close_footer`, `overview_change_hidden_when_locked`, `method_sheet_saves`, `overview_empty`, `overview_denied_390`, `open_published_goes_result`).
  - `dart analyze lib/features/inventory/presentation/costing test/features/inventory/presentation/costing`: `No issues found!`.
  - `dart run tool/check_feature_imports.dart`: 0 vi phạm trong `inventory`.
- **Commit:** chưa commit theo yêu cầu người dùng.

### Task 6: SCR-074 + các sheet (2026-11-12)

- **Tệp tạo mới:**
  - `apps/erp/lib/features/inventory/presentation/costing/cost_run_page.dart`
  - `apps/erp/lib/features/inventory/presentation/costing/cost_run_blocks.dart`
  - `apps/erp/lib/features/inventory/presentation/costing/cost_run_sheets.dart`
  - `apps/erp/lib/features/inventory/presentation/costing/cost_run_detail_sheet.dart`
  - `apps/erp/test/features/inventory/presentation/costing/cost_run_page_test.dart`
  - `apps/erp/test/features/inventory/presentation/costing/cost_run_detail_sheet_test.dart`
- **Kiểm tra:**
  - `flutter test --no-pub -r compact test/features/inventory/presentation/costing/cost_run_page_test.dart test/features/inventory/presentation/costing/cost_run_detail_sheet_test.dart`: `11` passed, `0` failed (`draft_mid_shows_period_scope_method`, `calculating_shows_note`, `ready_390`, `ready_1280`, `blocked_390`, `publish_sheet_facts_and_confirm`, `publish_stale_shows_input_changed_390`, `compare_sheet_alt_totals`, `denied_390`, `detail_sheet_balance_ok`, `detail_sheet_balance_off`).
  - `dart analyze lib/features/inventory/presentation/costing test/features/inventory/presentation/costing`: `No issues found!`.
  - `dart run tool/check_feature_imports.dart`: 0 vi phạm trong `inventory`.
- **Commit:** chưa commit theo yêu cầu người dùng.

### Task 7: SCR-077 + "Lịch sử giá vốn" ở SCR-003 (2026-11-12)

- **Tệp tạo mới / sửa:**
  - `apps/erp/lib/features/inventory/presentation/costing/cost_result_page.dart`
  - `apps/erp/lib/features/inventory/presentation/costing/cost_versions_sheet.dart`
  - `apps/erp/lib/features/inventory/presentation/stock/stock_cost_block.dart` (thêm `onShowVersions` + nút `Lịch sử giá vốn`)
  - `apps/erp/lib/features/inventory/presentation/stock/stock_detail_body.dart` (truyền `onShowVersions` khi `detail.isOwner`)
  - `apps/erp/test/features/inventory/presentation/costing/cost_result_page_test.dart`
  - `apps/erp/test/features/inventory/presentation/costing/cost_versions_sheet_test.dart`
  - `apps/erp/test/features/inventory/presentation/stock/stock_detail_page_test.dart` (thêm `stock_cost_block_versions_link_owner_only`)
- **Kiểm tra:**
  - `flutter test --no-pub -r compact test/features/inventory/presentation/costing/cost_result_page_test.dart test/features/inventory/presentation/costing/cost_versions_sheet_test.dart test/features/inventory/presentation/stock/stock_detail_page_test.dart`: `18` passed, `0` failed (gồm 12 test SCR-003 cũ + 1 test mới + 5 test SCR-077 / CostVersionsSheet).
  - `dart analyze lib/features/inventory/presentation/costing lib/features/inventory/presentation/stock test/features/inventory/presentation/costing test/features/inventory/presentation/stock`: `No issues found!`.
  - `dart run tool/check_feature_imports.dart`: 0 vi phạm trong `inventory`.
- **Commit:** chưa commit theo yêu cầu người dùng.

### Task 8: Route, DI, Hub, luồng đầu–cuối (2026-11-12)

- **Tệp tạo mới / sửa:**
  - `apps/erp/lib/features/inventory/presentation/costing/costing_routes.dart`
  - `apps/erp/lib/core/router/app_router.dart` (thêm `...costingRoutes()` cạnh `...stocktakeRoutes()`)
  - `apps/erp/lib/core/di/injection.dart` (đăng ký `CostingRepository`)
  - `apps/erp/lib/features/inventory/presentation/hub/warehouse_entries.dart` (gắn `route: '/warehouse/costing'` cho `cogs`)
  - `apps/erp/lib/features/inventory/data/hub/warehouse_hub_summary.dart` & `warehouse_hub_repository.dart` (thêm/parse `costPeriodToClose`, `costRunsPending`)
  - `apps/erp/lib/features/inventory/presentation/hub/warehouse_hub_page.dart` (2 dòng "Cần chú ý" giá vốn chỉ cho chủ cửa hàng)
  - `apps/erp/test/features/inventory/presentation/costing/costing_flow_test.dart`
  - `apps/erp/test/features/inventory/presentation/hub/warehouse_hub_pages_test.dart` (thêm `hub_cogs_entry_routes_costing`, `hub_attention_cost_rows_owner_only`)
- **Kiểm tra:**
  - `flutter test --no-pub -r compact test/features/inventory/presentation/costing/costing_flow_test.dart test/features/inventory/presentation/hub/warehouse_hub_pages_test.dart`: `22` passed, `0` failed.
  - `dart analyze lib/core/router/app_router.dart lib/core/di/injection.dart lib/features/inventory/data/hub lib/features/inventory/presentation/costing lib/features/inventory/presentation/hub test/features/inventory/presentation/costing test/features/inventory/presentation/hub`: `No issues found!`.
  - `dart run tool/check_feature_imports.dart`: 0 vi phạm trong `inventory`.
- **Commit:** chưa commit theo yêu cầu người dùng.

### Task 9: Ảnh Flutter + kiểm cuối + PLAN (2026-11-12)

- **Golden test (`apps/erp/test/features/inventory/presentation/costing/costing_golden_test.dart`):**
  - Sinh và kiểm khớp 8 ảnh `flutter-{072-READY,074-READY_FOR_REVIEW,074-BLOCKED,077-COMPLETED}-{390,1280}.png` tại `docs/refactor/plans/T7/img/G5-6/` (`4` test groups passed).
  - **Đối chiếu với `proto-…` (lệch có chủ đích đã chốt trong plan):**
    - SCR-072: thêm nút `"Đổi"` ở `VAppBar.actions` (ẩn khi `methodLocked`) và nút `"Cập nhật giữa kỳ"` ở `InventoryFooter` (ẩn khi `hasPendingRun`).
    - SCR-074 `READY_FOR_REVIEW`: thêm nút `"Xem chi tiết tính"` dưới khối ④ và nút `"Bỏ lần tính"` ở chân trang.
    - SCR-074 `BLOCKED`: nút `"Tính lại"` luôn bật (thay vì khoá bởi `k4ReasonFooter`) + thêm `"Bỏ lần tính"`.
    - SCR-077 `COMPLETED`: ẩn nút `"Xem báo cáo tồn"` (dời sang G5-7), giữ duy nhất nút `"Về giá vốn"`.
- **Kiểm tra cuối:**
  - `./tools/db_check.sh`: ✅ DB check đạt (`supabase db reset --local` OK, `plpgsql_check` 0 lỗi mới, `inventory_costing` & toàn bộ `supabase/tests/*.sql` xanh).
  - `cd apps/erp && flutter test --no-pub -r compact test/features/inventory`: **603 passed, 0 failed** (mốc Task 0 là 549 passed; tăng +54 test mới của G5-6, 0 regression).
  - `cd apps/erp && dart analyze lib/features/inventory test/features/inventory`: **No issues found!**.
  - `gitnexus detect_changes --scope compare --base-ref main`: 3749 files, 24436 symbols, 271 affected processes (critical — do phạm vi nhánh `refactor/simple-arch` so với `main`); `detect_changes --scope all` (working tree): 19 files, 11 symbols, 0 affected processes (`low`).
- **Cập nhật `PLAN.md`:** đánh dấu G5-6 `Làm ✅ 2026-11-12`, cập nhật tiêu chí #8, thêm ghi chú mốc chốt theo tháng (D1) + dấu sổ (D5) cho G5-7.
- **Commit:** chưa commit theo yêu cầu người dùng.

### Sửa sau R1 (2026-11-12)

- **#1 (Deadlock lock giá trị tồn trong `publish_cost_run`):** tách 2 vòng lặp trong [20261118001_inventory_costing.sql](file:///Users/macbook/Documents/graduation_project/supabase/migrations/20261118001_inventory_costing.sql) — lấy `pg_advisory_xact_lock(hashtext(p_tenant_id::text), hashtext(v_line.product_id::text))` theo thứ tự `crl.product_id asc` cho toàn bộ dòng trước khi gọi `_post_value_adjustment`; bổ sung assertion thứ tự lock trong [costing_sql_contract_test.dart](file:///Users/macbook/Documents/graduation_project/apps/erp/test/features/inventory/data/costing_sql_contract_test.dart).
- **#2 (URL sau `Tính lại` / `Tạo lần tính kế tiếp`):** sửa listener trong [cost_run_page.dart](file:///Users/macbook/Documents/graduation_project/apps/erp/lib/features/inventory/presentation/costing/cost_run_page.dart) sang `state.run!.runId != initialRunId`; thêm widget test `recalculate_from_blocked_replaces_url` trong [cost_run_page_test.dart](file:///Users/macbook/Documents/graduation_project/apps/erp/test/features/inventory/presentation/costing/cost_run_page_test.dart).
- **#3 (Truyền `period=YYYY-MM` từ màn Tổng quan sang Tạo mới):** bổ sung callback `onCreateRunWithPeriod` và query param `&period=YYYY-MM` trong [cost_overview_page.dart](file:///Users/macbook/Documents/graduation_project/apps/erp/lib/features/inventory/presentation/costing/cost_overview_page.dart) và [costing_routes.dart](file:///Users/macbook/Documents/graduation_project/apps/erp/lib/features/inventory/presentation/costing/costing_routes.dart); thêm test `period_close_passes_period_query_param` trong [cost_overview_page_test.dart](file:///Users/macbook/Documents/graduation_project/apps/erp/test/features/inventory/presentation/costing/cost_overview_page_test.dart).
- **#4 (`RUN_PENDING_REVIEW` trả về `pending_run_id`):** bổ sung `pending_run_id` vào blocker JSON trong `create_cost_run`, parse `CostBlocker.pendingRunId` ở [costing_models.dart](file:///Users/macbook/Documents/graduation_project/apps/erp/lib/features/inventory/data/costing/costing_models.dart), điều hướng `/warehouse/costing/runs/$pendingId` ở [cost_run_page.dart](file:///Users/macbook/Documents/graduation_project/apps/erp/lib/features/inventory/presentation/costing/cost_run_page.dart); thêm test `open_pending_run_navigates_to_run_id` và contract check.
- **#5 (Trạng thái `superseded`):** thêm nhánh `run.status == CostRunStatus.superseded` hiển thị `InventoryStale` (`Lần tính đã được thay`) trong [cost_run_page.dart](file:///Users/macbook/Documents/graduation_project/apps/erp/lib/features/inventory/presentation/costing/cost_run_page.dart); thêm test `superseded_shows_replaced_state`.
- **Kiểm chứng lại sau R1:** `./tools/db_check.sh` ✅ (`DB check đạt`, `inventory_costing: Task 1 & Task 2 cases passed`); `dart analyze lib/features/inventory test/features/inventory` ✅ (`No issues found!`); `flutter test --no-pub -r compact test/features/inventory` ✅ (`607` tests passed).

### Sửa sau R2 (2026-11-12)

- **#1 (Gán theo vị trí `v_line` khi lock sản phẩm trong `publish_cost_run`):** khai báo biến `v_lock_product_id uuid;` và lặp `for v_lock_product_id in select crl.product_id ... loop perform pg_advisory_xact_lock(hashtext(p_tenant_id::text), hashtext(v_lock_product_id::text)); end loop;` trong [20261118001_inventory_costing.sql](file:///Users/macbook/Documents/graduation_project/supabase/migrations/20261118001_inventory_costing.sql) để không gán `product_id` vào cột đầu tiên `run_id` của `v_line`.
- **Test hợp đồng:** cập nhật [costing_sql_contract_test.dart](file:///Users/macbook/Documents/graduation_project/apps/erp/test/features/inventory/data/costing_sql_contract_test.dart) kiểm tra `v_lock_product_id uuid`, `hashtext(v_lock_product_id::text)` đứng trước `_post_value_adjustment`, không có `pg_advisory_xact_lock` sau `_post_value_adjustment`, và cấm `for v_line in select crl.product_id`.
- **Kiểm chứng lại sau R2:** `./tools/db_check.sh` ✅ (`DB check đạt`, `inventory_costing: Task 1 & Task 2 cases passed`); `flutter test --no-pub -r compact test/features/inventory/data/costing_sql_contract_test.dart` ✅ (`5` tests passed).

## 6. Review

### R1 (2026-11-12) — Đạt có điều kiện: sửa #1, #2 rồi commit; #3–#5 sửa cùng lúc nếu nhanh

**Đã xem:** mục Kết quả Task 0–9; ảnh `flutter-…` so `proto-…` (Ahem, như các plan trước — chỉ so bố cục: thứ tự khối ①–⑤, K7Split + "Tóm tắt" 4 dòng trên web, chân hai nút; lệch có chủ đích khớp mục 1); toàn bộ `20261118001_inventory_costing.sql`; diff `20261110001` / `20261115001` / `20261117001` / `inventory_sales_link.sql`; `inventory_costing.sql` (đủ ca mục 2.5, số kỳ vọng ca 1, 2, 3, 4, 7, 11b, 16 đúng từng đồng theo plan); `CostRunCubit`, `CostRunPage`, `costing_routes.dart`, DI, router. Ảnh G5-2 `flutter-SCR-003-*` và `flutter-SCR-001-READY-1280` (panel chi tiết bên phải) đổi do thêm nút "Lịch sử giá vốn" ở khối giá vốn — đúng, đã so với bản ở `HEAD`.

**`tools/db_check.sh`** (người dùng chạy 2026-11-12): ✅ DB check đạt — reset đủ migration; `plpgsql_check` 0 lỗi mới (2 nợ đã biết: `catalog.create_product:44`, `einvoice.record_issuance_undetermined:42`); `inventory_costing` "Task 1 & Task 2 cases passed", mọi suite `inventory_*`, `sales_th05`, `partner_th03` xanh; nợ đã biết `catalog_th02`, `einvoice_th08`, `pricing_th04`. Ca deadlock #1 không lộ ở test tuần tự — cần sửa theo lập luận khoá, không theo kết quả test.

| # | Mức | Chỗ | Vấn đề | Sửa |
|---|---|---|---|---|
| 1 | **Cao** | `publish_cost_run` (`20261118001:1016-1047`) | Khoá sản phẩm **xen kẽ** với ghi sổ: khoá P1 → `_post_value_adjustment` (giữ khoá dòng `ledger_counters` tới hết giao dịch) → khoá P2… Một đơn bán đang giữ khoá P2 (`_post_movements` khoá hết sản phẩm trước) rồi chờ `ledger_counters` ⇒ **deadlock** (Postgres huỷ một bên: thanh toán hoặc công bố báo lỗi 40P01). Plan mục 2.4: "khoá sản phẩm của dòng theo `product_id` tăng → mỗi dòng: ghi …" — khoá hết rồi mới ghi | Tách vòng: (a) một vòng `pg_advisory_xact_lock` cho mọi `product_id` của run (tăng dần), (b) vòng ghi điều chỉnh. Test hợp đồng: trong thân `publish_cost_run`, vị trí vòng khoá đứng trước lần gọi `_post_value_adjustment` đầu tiên, và không có `pg_advisory_xact_lock` nào nằm sau nó |
| 2 | Trung bình | `CostRunPage` listener (`cost_run_page.dart:249-257`) | "Tính lại" (BLOCKED) / "Tạo lần tính kế tiếp" (STALE) ở `/runs/:id` tạo run mới nhưng URL **giữ id run cũ** (chỉ chuyển khi `initialRunId == null`). Tải lại trang / quay lại rồi vào lại ⇒ mở run cũ đã `SUPERSEDED` (màn hiện khối kết quả rỗng, không chân) | Chuyển (`replace`) khi `state.run.runId != initialRunId`. Test `recalculate_from_blocked_replaces_url` (fake repo trả run id mới ⇒ `onNavigate('/warehouse/costing/runs/<id mới>')`) |
| 3 | Thấp | `CostRunPage._defaultPeriod` + `costing_routes.dart` | Bản nháp "Chốt kỳ" lấy **tháng trước theo đồng hồ máy**, không phải `periodToClose` (plan mục 2.7). Còn ≥ 2 kỳ chưa chốt ⇒ 072 ghi "Chốt kỳ 09/2026" nhưng 074 ghi "Chốt kỳ 10/2026"; server chốt 09 | 072 truyền `&period=YYYY-MM` (từ `periodToClose` / `openPeriod`) vào `/new`; route đọc vào `initialPeriod` |
| 4 | Thấp | `_handleBlockerAction` `openPendingRun` | Về 072 thay vì mở run READY (plan mục 2.7) | Nhận id run READY: `get_cost_run` chưa có ⇒ thêm `pending_run_id` vào blocker `RUN_PENDING_REVIEW` (server) và mở `/runs/:id`; hoặc ghi "Lệch plan" ở Kết quả nếu giữ |
| 5 | Thấp | `CostRunPage` khi `status == superseded` | Mở run `SUPERSEDED` bằng URL rơi vào nhánh kết quả (khối rỗng). `costing_rules.runStatus` gộp `superseded` vào "Cần xử lý" | Nhánh riêng: `InventoryStale(title: 'Lần tính đã được thay', description: 'Lần tính này đã bị bỏ hoặc thay bằng lần tính kế tiếp.', actionLabel: 'Về giá vốn')` — chữ mới, cần người dùng duyệt; hoặc chuyển thẳng về 072 |

**Không phải lỗi (đã kiểm):** dấu sổ D5 (`−cogs_true_up`, `−loss_true_up`, `+rounding_adjust`); mốc `PERIOD_CLOSE` theo tháng và `greatest(from, …)`; `ledger_counters … for update` trước khi lấy mốc; `STALE` suy ra lúc đọc, `create_cost_run` ghi `STALE` → `SUPERSEDED`; `_post_value_adjustment` chỉ chặn âm với `SUPPLIER_REBATE`; `_reversal_kind` so `cut_off_sequence`; `_ensure_open_period` chặn tháng cũ hơn kỳ `CLOSED`; quyền chủ cửa hàng ở cả 7 RPC (`staff_denied` × 7); khoá công bố giữ nguyên khi lỗi mạng, đổi khi thành công / `STALE`.

**Phiên sửa:** ghi "Sửa sau R1" ở mục 5; chạy lại `tools/db_check.sh` + `flutter test --no-pub -r compact test/features/inventory`.

### R2 (2026-11-12) — Chưa đạt: #1 sửa chưa có hiệu lực; #2–#5 đạt

**Đã xem:** "Sửa sau R1" (mục 5); thân `publish_cost_run` mới; `create_cost_run` (`pending_run_id`); listener + nhánh `superseded` + `openPendingRun` ở `cost_run_page.dart`; `period` ở `cost_overview_page.dart` / `costing_routes.dart`; test hợp đồng `task2_locks_error_codes_and_reversal_kind`. `db_check` / `flutter test` theo số phiên sửa ghi (✅, 607 passed) — phiên review không chạy DB.

| # R1 | Kết quả | Ghi chú |
|---|---|---|
| 1 | **Chưa đạt** | Vòng khoá mới `for v_line in select crl.product_id from … loop … hashtext(v_line.product_id::text)`, mà `v_line` khai báo `inventory.cost_run_lines` (cột đầu là `run_id`). PL/pgSQL gán cột **theo vị trí** vào biến dòng: `product_id` rơi vào `v_line.run_id`, `v_line.product_id` = `NULL` ⇒ `hashtext(NULL)` = `NULL` ⇒ `pg_advisory_xact_lock` (STRICT) trả `NULL`, **không khoá gì**. Không lỗi lúc chạy nên `db_check` xanh; test hợp đồng chỉ so vị trí chuỗi nên cũng xanh. Hệ quả: công bố không còn khoá sản phẩm nào; deadlock vẫn có thể xảy ra qua khoá dòng `product_costs` (`_post_value_adjustment … for update`) ↔ `ledger_counters` với đơn bán đang chạy |
| 2 | Đạt | Chuyển URL khi `runId != initialRunId`; route dùng `context.go` (thay vị trí, quay lại về 072) |
| 3 | Đạt | `&period=YYYY-MM` từ `periodToClose` |
| 4 | Đạt | `pending_run_id` trong blocker `RUN_PENDING_REVIEW` |
| 5 | Đạt | Chữ "Lần tính đã được thay" / "Lần tính này đã bị bỏ hoặc thay bằng lần tính kế tiếp." / "Về giá vốn" (đề xuất R1, người dùng cho làm) |

**Sửa #1:** khai báo `v_lock_product_id uuid;` và
```sql
for v_lock_product_id in
  select crl.product_id from inventory.cost_run_lines crl
  where crl.run_id = v_run.id order by crl.product_id asc
loop
  perform pg_advisory_xact_lock(hashtext(p_tenant_id::text), hashtext(v_lock_product_id::text));
end loop;
```
Test hợp đồng: thân `publish_cost_run` có `v_lock_product_id uuid`, có `hashtext(v_lock_product_id::text)` đứng trước `_post_value_adjustment` đầu tiên, và **không** có `for v_line in\n    select crl.product_id` (chặn lặp lại lỗi gán theo vị trí).

**Kiểm nhanh (tuỳ chọn, người dùng chạy local)** — xác nhận gán theo vị trí:
```sql
do $$ declare r inventory.cost_run_lines; begin
  for r in select gen_random_uuid() loop
    raise notice 'run_id=% product_id=%', r.run_id, r.product_id;
  end loop;
end $$;
```
Kỳ vọng: `run_id=<uuid> product_id=<NULL>`.

**Phiên sửa:** ghi "Sửa sau R2"; chạy lại `tools/db_check.sh` + test hợp đồng `costing_sql_contract_test.dart`.

### R3 (2026-11-12) — Đạt

**Đã xem:** "Sửa sau R2"; `publish_cost_run`: vòng khoá dùng `v_lock_product_id uuid` (`for v_lock_product_id in select crl.product_id … order by crl.product_id asc` → `pg_advisory_xact_lock(hashtext(tenant), hashtext(v_lock_product_id::text))`), xong mới tới vòng `for v_line in select *` ghi điều chỉnh; không còn `pg_advisory_xact_lock` sau `_post_value_adjustment` đầu tiên. Rà cả migration: không còn vòng / `select into` nào gán một cột vào biến kiểu dòng. Test hợp đồng có `v_lock_product_id uuid`, thứ tự khoá → ghi, và regex chặn `for v_line in select crl.product_id`. `db_check` ✅ / test hợp đồng 5 passed theo số phiên sửa ghi (phiên review không chạy DB).

| # R1 | Kết quả |
|---|---|
| 1 | Đạt |
| 2–5 | Đạt (R2) |

**Còn lại trước khi đóng plan:** commit (không `git add` `AGENTS.md`, `CLAUDE.md`); reset Dev `--linked` — người dùng quyết.
