# AI-3 — Dự báo nhập hàng: RPC dự báo, công cụ `du_bao_ban_hang`, dữ liệu bán mô phỏng

> Tích hợp AI · plan **AI-3** của [PLAN.md](../../PLAN.md) mục "Tích hợp AI" (bảng Plan)
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-17) | Làm ✅ 2026-11-17 (chờ chạy Dev) | Review 🟡 R2 đạt phần đọc code; chờ kết quả chạy Dev để đóng
> Thiết kế: duyệt trong chat 2026-11-17 (chọn **cách A** sinh dữ liệu: gọi RPC bán thật rồi lùi `completed_at`; công thức 8 tuần trọng số; bộ dữ liệu 12 sản phẩm / 90 ngày). Yêu cầu: [AI-0](AI-0-yeu-cau.md) mục 4, 8a, 9 · Backend nền: [AI-1](AI-1-backend.md) (R4 ✅) · Màn: [AI-2](AI-2-man-hoi-c45.md).

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development hoặc superpowers:executing-plans. Dự án này **người dùng tự code, Claude review ở phiên khác** (xem [README plans](../README.md)); các bước dùng checkbox để người dùng tick.

**Goal:** Hỏi "Hàng nào sắp hết, nên nhập bao nhiêu?" trong Hỏi Mosaic Retail trả bảng dự báo đúng số (còn bán mấy ngày, nên nhập bao nhiêu) từ RPC; có bộ dữ liệu bán mô phỏng 90 ngày để demo và chạy đủ 22 câu thử.

**Architecture:** Một RPC đọc `inventory.get_purchase_forecast` tính tốc độ bán trung bình có trọng số 8 tuần từ đơn bán thật (cùng cách tính `get_sales_stats`) + tồn khả dụng + `product_stock_policies`. Công cụ `du_bao_ban_hang` (module mới trong `ai-assistant/tools`) gọi RPC, dựng bảng; Gemini chỉ viết lời. Script SQL dựng cửa hàng demo + 12 sản phẩm + ~270 đơn bán qua `sales.finalize_sales_order` rồi lùi `completed_at`.

**Tech Stack:** PostgreSQL / Supabase (plpgsql, test kiểu `supabase/tests/*.sql`, chạy bằng `psql` trên Supabase Dev), Deno (Edge Function `ai-assistant`).

## Thiết kế AI-3 (đã duyệt trong chat)

- **Công thức** (giờ VN, mỗi sản phẩm): bucket tuần `b = 0..7`, `b = 0` là 7 ngày gần nhất (`hôm nay − 6 … hôm nay`), `b = 7` là `hôm nay − 55 … hôm nay − 49`; số lượng bucket `q_b` tính y như `sales.get_sales_stats` chỉ số `quantity` (đơn hoàn tất + dòng đổi − dòng trả − đơn huỷ, theo `completed_at` / `cancelled_at`, đúng `store_id` của người hỏi); trọng số `w_b = 8 − b`. `daily_rate = max(0, Σ w_b·q_b / (7·Σ w_b))` (Σ w_b = 36). `days_left = available / daily_rate` (rate = 0 ⇒ `null`; `available ≤ 0` ⇒ `0`). `suggest_qty = ceil(target_level − available)` khi có ngưỡng **và** `available ≤ reorder_threshold`; có ngưỡng nhưng tồn cao hơn ⇒ `0`; chưa đặt ngưỡng ⇒ `null`.
- **Không làm:** sửa `home_tab_page.dart`, nút "Tạo phiếu nhập", công nợ, mùa vụ / khuyến mãi, huấn luyện model.
- **Thất bại dù chạy được:** Gemini nói số không có trong kết quả RPC; tổng số lượng 8 tuần của dự báo lệch `get_sales_stats` cùng kỳ.
- **Việc AI-1 để lại cho plan này:** thêm `du_bao_ban_hang` vào `registry.ts`; thêm lại "dự báo nhập hàng" vào `prompt.ts`; điền `{san_pham_a}` / `{ma_don}`; chạy đủ 22 câu (câu 18–20 hiện chờ).

## Global Constraints

- Migration: header theo khuôn `20261119001_inventory_reports.sql` (Title / Kind / Intent / Context / Touches / Safety / Depends on); cập nhật `supabase/migrations/REGISTRY.yaml` (nhóm `inventory:` → `get_purchase_forecast`). **Không** sửa migration đã có. Tên file: `20261121001_inventory_purchase_forecast.sql`.
- Hàm mới: `security definer`, `stable`, `set search_path = inventory, sales, iam, catalog, pg_temp`, `grant execute … to authenticated`. Lỗi: `inventory._raise('<MÃ>', '<câu>')` (mã dùng: `PERMISSION_DENIED`, `CONTEXT_INVALID`).
- Ngày: `(x at time zone 'Asia/Ho_Chi_Minh')::date`, hôm nay = `inventory._today()`. Số lượng Sales `*_micros / 1000000.0`. Kẹp `p_limit` về 1..20.
- Không trả tiền / giá vốn trong RPC (nhân viên không phải chủ cũng được xem, AI-0 mục 4).
- Chữ người dùng thấy: tên cột bảng nguyên văn bên dưới; câu cố định dùng `MESSAGES` có sẵn (`messages.ts`). Tên công cụ + tham số nguyên văn AI-0 mục 4 (`du_bao_ban_hang`; `san_pham_id`, `chi_hang_can_nhap`).
- Không gửi cho Gemini số điện thoại / email / địa chỉ (AI-0 mục 11) — dùng `redactPersonal` như các công cụ khác.
- **Chạy trên Supabase Dev (remote), không dùng DB local** (người dùng chốt 2026-11-17); **người dùng tự chạy**, plan chỉ ghi lệnh. `tools/db_check.sh` reset DB local nên **không dùng** ở plan này (bỏ luôn bước `plpgsql_check`). Áp migration: `supabase db push --linked` (chỉ thêm file mới, **không** `db reset --linked`). Chạy tệp SQL trên Dev: `psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f <tệp>` (chuỗi kết nối lấy ở Dashboard → Connect). Tệp test **bọc `begin;` … `rollback;`** để fixture (tenant, user, đơn) không ở lại Dev; `raise notice '…: OK'` ở cuối vẫn in ra.
- Deno: `deno test --allow-env --allow-net=127.0.0.1 supabase/functions/ai-assistant/` xanh; `deno check supabase/functions/ai-assistant/index.ts`; `deno fmt --check` / `deno lint` sạch.
- Trước khi sửa symbol có sẵn (`buildSystemPrompt`, `buildTools`): chạy `impact({target, direction: "upstream"})`, báo kết quả; HIGH / CRITICAL ⇒ dừng. Trước commit: `detect_changes({scope: "compare", base_ref: "main"})`.
- Ghi mục "Kết quả" cuối file sau mỗi task. `AGENTS.md`, `CLAUDE.md`: không `git add`.

## Review Focus

1. **Sản phẩm không bán gì trong 8 tuần** → `daily_rate = 0`, `days_left = null` (không chia 0, không `Infinity`); bảng hiện "—"; trợ lý không nói "còn bán mãi". → test `f4_no_sales` (Task 1), `forecast_null_days` (Task 3).
2. **Hết hàng (`available = 0`)** → `days_left = 0`, `suggest_qty = target_level`. → `f3b_out_of_stock` (Task 1).
3. **Chưa đặt ngưỡng** → có `days_left` nhưng `suggest_qty = null`; trợ lý nói "chưa đặt ngưỡng", không bịa lượng nhập. → `f3c_no_policy` (Task 1), `forecast_no_policy_flag` (Task 3).
4. **Trả hàng / huỷ đơn nhiều hơn bán trong một tuần** (bucket âm) → tốc độ không âm. → `f5_returns_reduce_rate` (Task 1) kiểm `daily_rate ≥ 0`.
5. **Nhân viên không phải chủ** hỏi dự báo → có kết quả, không `PERMISSION_DENIED`; sản phẩm của cửa hàng khác không lọt vào. → `f8_cashier_ok`, `f9_other_tenant` (Task 1).

---

## Cấu trúc tệp

```
supabase/migrations/20261121001_inventory_purchase_forecast.sql   (Task 1)
supabase/tests/inventory_purchase_forecast.sql                    (Task 1)
supabase/migrations/REGISTRY.yaml                                 (Task 1)
scripts/ai/seed_demo_sales.sql                                    (Task 2)
supabase/functions/ai-assistant/tools/forecast.ts   forecast_test.ts   (Task 3)
supabase/functions/ai-assistant/tools/registry.ts                 (Task 3: sửa)
supabase/functions/ai-assistant/prompt.ts   prompt_test.ts        (Task 3: sửa)
scripts/ai/eval_questions.json                                    (Task 4: sửa)
```

---

### Task 1: RPC `inventory.get_purchase_forecast`

**Files:**
- Create: `supabase/migrations/20261121001_inventory_purchase_forecast.sql`, `supabase/tests/inventory_purchase_forecast.sql`
- Modify: `supabase/migrations/REGISTRY.yaml`

**Interfaces — Produces:**
```sql
inventory.get_purchase_forecast(
  p_tenant_id uuid,
  p_product_id uuid default null,            -- có ⇒ chỉ sản phẩm đó (bỏ qua p_only_need_reorder)
  p_only_need_reorder boolean default true,  -- true ⇒ chỉ hàng có ngưỡng và available <= reorder_threshold
  p_limit int default 20                     -- kẹp 1..20
) returns jsonb
-- { "as_of": timestamptz, "weeks": 8,
--   "need_reorder_count": int,   -- đếm theo mọi sản phẩm đang bán, KHÔNG phụ thuộc p_limit / p_only_need_reorder / p_product_id
--   "rows": [ { "product_id", "name", "code", "uom", "available": numeric,
--               "reorder_threshold": numeric|null, "target_level": numeric|null,
--               "qty_8w": numeric,          -- Σ q_b (cả 8 tuần)
--               "daily_rate": numeric,      -- round(…, 1)
--               "days_left": numeric|null,  -- round(available / daily_rate_chưa_làm_tròn, 1)
--               "suggest_qty": numeric|null } ] }
-- rows sắp xếp: days_left tăng dần (null cuối), rồi name.
```
Quyền: `inventory._assert_actor(p_tenant_id, 'inventory.read')` (như `list_stock_overview`); cửa hàng = `store_id` trong kết quả `_assert_actor`. Tồn + danh sách sản phẩm: `inventory._product_stock_rows(p_tenant_id)` join `catalog.products` (`deleted_at is null`, `business_status = 'active'`) như `list_stock_overview`; `uom` = `catalog._product_base_unit_name`; chính sách: `inventory.product_stock_policies`. Số lượng bán: **chép bốn nhánh `union all`** của `get_sales_stats` (`20261120001_sales_stats.sql`, khối "Tổng cả kỳ") nhưng gom theo `product_id` + bucket tuần. `p_product_id` không thuộc tenant ⇒ `CONTEXT_INVALID`.

**Fixture test** (khuôn `supabase/tests/sales_stats.sql` nhưng **thêm `begin;` đầu tệp và `rollback;` cuối tệp**: chép `ss_tenant` và các helper `expect_err`, `rep_line`, `rep_pay`, `rep_finalize`, `rep_cancel`, `rep_return`; mỗi sản phẩm tồn 100): tenant A, chủ + một thành viên không phải chủ; SP1 và SP2.
- SP1: đơn 14 hộp **hôm nay** + đơn 14 hộp **lùi 52 ngày** (`update sales.sales_orders set completed_at = completed_at - interval '52 days'`, như `s5` của `sales_stats.sql`); chính sách `reorder_threshold = 80`, `target_level = 200` (insert thẳng vào `inventory.product_stock_policies`, `updated_by` = chủ). ⇒ `qty_8w = 28`, `daily_rate = 0.5` (Σ w·q = 8·14 + 1·14 = 126; 126 / 252), tồn 72, `days_left = 144.0`, `suggest_qty = 128`.
- SP2: không bán, không chính sách, tồn 100.

- [ ] **Step 1: Viết test đỏ** `supabase/tests/inventory_purchase_forecast.sql`, các ca:
  - `f1_weighted_rate`: hàng SP1 có `daily_rate = 0.5`, `qty_8w = 28`.
  - `f2_days_left_and_suggest`: SP1 `days_left = 144.0`, `suggest_qty = 128`, `available = 72`.
  - `f3_above_threshold`: nâng tồn SP1 lên 90 (`inventory._post_movements` +18 RECEIPT) ⇒ `suggest_qty = 0` và SP1 không có trong `rows` khi `p_only_need_reorder = true`.
  - `f3b_out_of_stock`: SP3 (thêm vào fixture) có ngưỡng 10 / mục tiêu 50, tồn 0, có bán ⇒ `days_left = 0`, `suggest_qty = 50`.
  - `f3c_no_policy`: SP2 (`p_only_need_reorder = false`) ⇒ `suggest_qty` là `null`, `reorder_threshold` là `null`.
  - `f4_no_sales`: SP2 ⇒ `daily_rate = 0`, `days_left` là `null`, không lỗi chia 0.
  - `f5_returns_reduce_rate`: trả 2 hộp của đơn hôm nay (`rep_return`) ⇒ `qty_8w = 26`, `daily_rate = round(110 / 252.0, 1) = 0.4`, `days_left = round(available / (110 / 252.0), 1)` với `available` đọc từ chính hàng đó; `daily_rate >= 0`.
  - `f6_matches_sales_stats`: `Σ rows[].qty_8w` (với `p_only_need_reorder = false`, đủ mọi sản phẩm) = `(sales.get_sales_stats(t,'quantity','none', today-55, today)->>'total')::numeric`.
  - `f7_count_and_limit`: `need_reorder_count` không đổi khi `p_limit = 1`; `p_limit = 1` ⇒ đúng 1 hàng; `p_limit = 99` ⇒ kẹp 20 (không lỗi); `p_product_id = SP1` trả đúng 1 hàng kể cả khi SP1 không cần nhập.
  - `f8_cashier_ok`: jwt = thành viên không phải chủ ⇒ có kết quả, không lỗi.
  - `f9_other_tenant`: `p_product_id` của tenant B ⇒ `CONTEXT_INVALID`; người ngoài tenant ⇒ `PERMISSION_DENIED`; đơn bán của tenant B không vào `qty_8w` của A.
- [ ] **Step 2: Chạy, thấy đỏ** (người dùng, trên Dev) — `psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/inventory_purchase_forecast.sql` ⇒ lỗi "function inventory.get_purchase_forecast … does not exist".
- [ ] **Step 3: Viết migration** theo Interfaces và công thức ở "Thiết kế AI-3"; cập nhật REGISTRY.
- [ ] **Step 4: Chạy, thấy xanh** (người dùng, trên Dev) — `supabase db push --linked`, rồi chạy lại lệnh psql ở Step 2 ⇒ in `NOTICE: inventory_purchase_forecast: OK`, thoát 0, và không còn tenant / user test nào trên Dev (đã `rollback`). Thêm: chạy lại `psql … -f supabase/tests/sales_stats.sql` để chắc RPC cũ không bị ảnh hưởng (tệp này **không** có `rollback`; nếu không muốn để fixture lại Dev thì bỏ qua bước này).
- [ ] **Step 5: Commit** — `feat(ai): inventory.get_purchase_forecast — dự báo nhập hàng 8 tuần`.

---

### Task 2: Script dữ liệu bán mô phỏng

**Files:** Create `scripts/ai/seed_demo_sales.sql`.

Làm sớm (đầu plan) vì Task 3–4 và demo cần dữ liệu. Chạy **trên Supabase Dev** (không rollback, dữ liệu ở lại để demo); người dùng tự chạy, **chạy một lần**. Script **tự dựng một cửa hàng riêng** ("Cửa hàng Demo AI") để không đụng dữ liệu đang có và có sẵn hai tài khoản cho bộ câu thử.

**Quyết định:**
- Cửa hàng + kho + chính sách giá vốn `MOVING` + hai tài khoản đăng nhập được: chủ `demo.chu@c45.local`, thu ngân `demo.thungan@c45.local` (thành viên **không** phải chủ, `role = 'staff'`), mật khẩu `Demo@12345` (chèn `auth.users` với `encrypted_password = crypt(…, gen_salt('bf'))` **và** `auth.identities`; dựng theo cách `ss_tenant` ở `sales_stats.sql` + thêm mật khẩu). Chạy lại script: bỏ qua nếu cửa hàng đã có (idempotent theo `display_name`).
- 12 sản phẩm (tên chỉ là dữ liệu mẫu, đổi được; giá bán là giá niêm yết, một đơn vị `hộp`):

| # | Sản phẩm | Kiểu bán | ≈ bán/ngày (8 tuần cuối) | Giá | Tồn cuối | Ngưỡng / mục tiêu | Kỳ vọng dự báo |
|---|---|---|---|---|---|---|---|
| 1 | Sữa tươi hộp 1L | đều | 12 | 8.000 | 40 | 60 / 240 | cần nhập (~3 ngày) — **{san_pham_a}** |
| 2 | Mì gói | đều | 30 | 4.000 | 500 | 150 / 600 | đủ hàng |
| 3 | Nước suối 500ml | tăng dần 10→25 | ~22 | 5.000 | 70 | 100 / 400 | cần nhập |
| 4 | Dầu ăn 1L | đều | 5 | 45.000 | 120 | 30 / 100 | đủ hàng |
| 5 | Gạo 5kg | thất thường | 6 | 90.000 | 20 | 25 / 80 | cần nhập |
| 6 | Đường 1kg | bán chậm | 1,5 | 25.000 | 18 | 10 / 40 | đủ hàng |
| 7 | Bánh quy | tăng dần 3→9 | ~8 | 20.000 | **0** | 20 / 80 | **hết hàng**, cần nhập |
| 8 | Nước ngọt lon | thất thường | 15 | 10.000 | 30 | 40 / 160 | cần nhập |
| 9 | Bột giặt 3kg | bán chậm | 1 | 120.000 | 25 | 5 / 20 | đủ hàng |
| 10 | Giấy vệ sinh lốc | đều | 4 | 60.000 | 6 | 8 / 40 | cần nhập |
| 11 | Xà phòng | bán chậm | 0,8 | 15.000 | 50 | 10 / 30 | đủ hàng |
| 12 | Cà phê gói | đều | 8 | 3.500 | 90 | **chưa đặt ngưỡng** | có "còn bán", không có "nên nhập" |

  ⇒ 6 hàng cần nhập (1, 3, 5, 7, 8, 10).
- Dữ liệu: 90 ngày lùi từ hôm nay. Mỗi ngày 2–4 đơn (khách lẻ, trả đủ tiền mặt), mỗi sản phẩm bán số lượng nguyên theo kiểu bán × nhiễu 0,7–1,3; "thất thường" = ~30% ngày bán gấp ~3, còn lại ít; "bán chậm" có nhiều ngày 0. Tồn đầu mỗi sản phẩm = **tồn cuối + tổng đã bán** (nhập một lần bằng `inventory._post_movements` trước khi bán) để sau khi bán xong tồn đúng cột "Tồn cuối". Tạo đơn bằng `sales.finalize_sales_order` (khuôn `rep_finalize` ở `sales_stats.sql`), rồi `update sales.sales_orders set completed_at = completed_at - (n || ' days')::interval` đưa về đúng ngày. Hạt giống cố định (`setseed(0.42)`) để chạy lại ra cùng số.
- Cuối script `select` ra: `tenant_id`, hai email, tên sản phẩm A, **một mã đơn** (số đơn mới nhất của cửa hàng demo; đọc tên cột trong `sales.sales_orders`), và bảng `get_purchase_forecast(t, null, false, 20)` để so với cột "Kỳ vọng" ở trên.
- Báo cáo đồ án phải ghi: dữ liệu bán là **mô phỏng**; để thẻ kho và lãi gộp khớp lịch sử, script **lùi cả sổ kho / sổ giá trị** (`business_date`) bằng cách tạm tắt trigger append-only trong khối seed (chỉ dùng cho dữ liệu demo).

- [ ] **Step 1: Viết script** theo các quyết định trên.
- [ ] **Step 2 (người dùng chạy, trên Dev; sau Task 1 Step 4 để RPC đã có):** `psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f scripts/ai/seed_demo_sales.sql`. Script **lỗi giữa chừng thì dữ liệu dở dang ở lại Dev**: báo lại, sửa script rồi `supabase db reset --linked` (hỏi trước, theo quy ước PLAN) hoặc dọn tay. Kỳ vọng: không lỗi; bảng cuối khớp cột "Kỳ vọng dự báo" (đúng 6 hàng cần nhập; Bánh quy `days_left = 0`; Cà phê `suggest_qty` null).
- [ ] **Step 3 (người dùng):** đăng nhập thử hai tài khoản vào app đang trỏ Dev (hoặc `curl` tới `<SUPABASE_URL>/auth/v1/token?grant_type=password` với anon key Dev); lệch (vd. GoTrue đòi thêm cột) thì báo lại để sửa script.
- [ ] **Step 4: Commit** — `feat(ai): script dữ liệu bán mô phỏng 90 ngày cho demo`.

---

### Task 3: Công cụ `du_bao_ban_hang` + lời dặn

**Files:**
- Create: `supabase/functions/ai-assistant/tools/forecast.ts`, `tools/forecast_test.ts`
- Modify: `tools/registry.ts` (thêm vào `buildTools()` sau `stockMovementTool`; xoá dòng ghi chú "AI-3 thêm…"), `prompt.ts`, `prompt_test.ts`

**Interfaces:**
- Consumes: `Tool`, `ToolContext`, `isRecord`, `asArray`, `UUID_RE` (`tools/tool.ts`); `redactPersonal` (`tools/redact.ts`); `fakeRpc`, `makeCtx` (`tools/test_util.ts`).
- Produces: `export const forecastTool: Tool` (`declaration.name = 'du_bao_ban_hang'`).

Khai báo cho Gemini: tham số `san_pham_id` (uuid, tuỳ chọn, lấy từ `tim_kiem`), `chi_hang_can_nhap` (boolean, mặc định `true`); mô tả nói rõ: dùng cho "nên nhập gì / bao nhiêu", "còn bán được mấy ngày"; **mọi con số lấy nguyên từ kết quả**; hàng chưa đặt ngưỡng thì chỉ có số ngày, không có lượng nên nhập.

`run`: `san_pham_id` có mà không phải uuid ⇒ `bad_args` ("gọi tim_kiem (loai = san_pham) trước"); gọi `ctx.rpc('inventory', 'get_purchase_forecast', { p_tenant_id, p_product_id: san_pham_id ?? null, p_only_need_reorder: chi_hang_can_nhap ?? true, p_limit: 20 })` — nếu có `san_pham_id` thì **bỏ** `chi_hang_can_nhap`. Kết quả:
- `forModel` (qua `redactPersonal`): `{ so_hang_can_nhap: need_reorder_count, dong: [{ ten, ma, ton, dvt, ban_moi_ngay, con_ban_ngay, nen_nhap, nguong?, muc_ton_muc_tieu?, chua_dat_nguong?: true }] }` (`con_ban_ngay`, `nen_nhap` giữ `null` nếu RPC trả `null`).
- `block`: tiêu đề "Dự báo nhập hàng"; cột `san_pham` Sản phẩm (`chu`) | `ton` Tồn (`so`) | `ban_moi_ngay` Bán/ngày (`so`) | `con_ban_ngay` Còn bán (ngày) (`so`) | `nen_nhap` Nên nhập (`so`); `mo = { loai: 'san_pham', id: product_id }`; **không có dòng ⇒ không có `block`** (`forModel.dong = []`).

`prompt.ts`: quy tắc 1 thêm lại "dự báo nhập hàng" (đứng sau "lãi gộp"); giữ nguyên dòng "Chưa có công cụ phù hợp thì KHÔNG trả lời nội dung, gọi bao_khong_ho_tro". Công nợ **vẫn chưa thêm** (hoãn sau Theme 6). Không sửa AI-0 mục 7.

- [ ] **Step 1: Chạy `impact`** trên `buildTools` và `buildSystemPrompt`, ghi vào Kết quả.
- [ ] **Step 2: Test đỏ** `forecast_test.ts` (RPC giả):
  - `forecast_calls_rpc_with_defaults`: không tham số ⇒ đúng 1 lời gọi `inventory.get_purchase_forecast` với `p_only_need_reorder: true`, `p_product_id: null`, `p_limit: 20`.
  - `forecast_single_product`: `san_pham_id` uuid ⇒ `p_product_id` đúng, không gửi `p_only_need_reorder`; `san_pham_id: 'Sữa'` ⇒ `bad_args`, **không** gọi RPC.
  - `forecast_maps_rows_and_block`: 2 hàng mẫu ⇒ `forModel.so_hang_can_nhap`, đủ khoá `dong`, block đúng 5 cột + `mo` san_pham.
  - `forecast_null_days`: `days_left: null` ⇒ `con_ban_ngay: null` trong `forModel` và ô `null` trong block (Review Focus 1).
  - `forecast_no_policy_flag`: `reorder_threshold: null` ⇒ `chua_dat_nguong: true`, `nen_nhap: null` (Review Focus 3).
  - `forecast_empty_no_block`: `rows: []` ⇒ `kind: 'data'`, không `block`.
  - `forecast_permission_denied_rethrown`: RPC ném `PERMISSION_DENIED` ⇒ `RpcError` ném ra.
  - Trong `prompt_test.ts`: sửa ca đang khẳng định "dự báo nhập hàng" **không** còn trong lời dặn (thêm ở R2 của AI-1) thành khẳng định **có**; "công nợ khách" vẫn **không** có; dòng `bao_khong_ho_tro` vẫn còn.
  - Sửa `tools/registry` test (nếu có) / `orchestrator_test` đếm công cụ: danh sách có `du_bao_ban_hang`.
- [ ] **Step 3: Chạy, thấy đỏ** — `deno test --allow-env --allow-net=127.0.0.1 supabase/functions/ai-assistant/tools/forecast_test.ts supabase/functions/ai-assistant/prompt_test.ts`.
- [ ] **Step 4: Viết** `forecast.ts`, sửa `registry.ts`, `prompt.ts`.
- [ ] **Step 5: Chạy, thấy xanh** — toàn bộ `deno test` của thư mục + `deno check` / `fmt --check` / `lint`.
- [ ] **Step 6: Commit** — `feat(ai): công cụ du_bao_ban_hang + lời dặn dự báo`.

---

### Task 4: Bộ câu thử đủ 22 câu + cập nhật PLAN

**Files:** Modify `scripts/ai/eval_questions.json`; `docs/refactor/PLAN.md` (dòng AI-3, dòng AI-2 nếu cần).

- [ ] **Step 1:** Trong `eval_questions.json`, câu 18–20: bỏ chữ "(cần AI-3)" ở `doi_chieu`; đặt giá trị `{san_pham_a}` = `Sữa tươi hộp 1L` (ghi trong "Kết quả" cùng `{ma_don}` lấy từ bảng cuối Task 2). Câu 18 / 20 đối chiếu: "khớp bảng cuối `seed_demo_sales.sql` / RPC `get_purchase_forecast`"; câu 19: "Sữa tươi hộp 1L: `days_left` ≈ 3,3 ngày".
- [ ] **Step 2 (người dùng chạy, trên Dev + Gemini thật):** `supabase functions deploy ai-assistant` (đưa công cụ mới lên; `GEMINI_API_KEY` đã nằm trong secrets Dev từ AI-1/AI-2), rồi `deno run … scripts/ai/run_eval.ts` với `SUPABASE_URL` / `SUPABASE_ANON_KEY` của **Dev** và env `AI_EVAL_TENANT_ID`, `AI_EVAL_OWNER_EMAIL` / `_PASSWORD`, `AI_EVAL_CASHIER_EMAIL` / `_PASSWORD`, `AI_EVAL_SAN_PHAM_A`, `AI_EVAL_MA_DON` (giá trị từ Task 2). Kỳ vọng: `Tự động đạt` ≥ 19/22 ở bộ 22 câu (AI-0 mục 1); đối chiếu tay số ở câu 1–14, 18–22 với bảng cuối script. Dán bảng kết quả vào mục "Kết quả".
- [ ] **Step 3:** Câu nào không đạt do công cụ / lời dặn (vd. Gemini không chọn `du_bao_ban_hang` cho "Tuần tới nên nhập những gì?") ⇒ sửa **mô tả công cụ** ở `forecast.ts` hoặc `prompt.ts`, chạy lại câu đó; ghi lần sửa.
- [ ] **Step 4:** `detect_changes({scope: "compare", base_ref: "main"})` chỉ chạm tệp của plan này; ghi vào Kết quả.
- [ ] **Step 5:** PLAN.md: dòng **AI-3** cột Plan ✅ link file này; cập nhật "Làm / Review" theo thực tế.
- [ ] **Step 6: Commit** — `feat(ai): bộ câu thử đủ 22 câu cho dự báo nhập hàng`.

---

## Kiểm tra (tổng)
- [ ] Test SQL trên Dev in `inventory_purchase_forecast: OK` (sau `supabase db push --linked`)
- [ ] `deno test` / `deno check` / `deno fmt --check` / `deno lint` sạch cho `ai-assistant`
- [ ] Chạy script mô phỏng trên Dev, bảng cuối khớp cột "Kỳ vọng"
- [ ] Hỏi "Hàng nào sắp hết, nên nhập bao nhiêu?" trong `/ask` (web + iPhone) ra bảng 5 cột, số khớp RPC
- [ ] Không có thay đổi ở `home_tab_page.dart`

## Rủi ro / lưu ý
- **Dev là DB dùng chung:** script mô phỏng ghi dữ liệu thật vào Dev (tài khoản `demo.*@c45.local`, ~270 đơn, nhập kho); không có script dọn. Không có bước kiểm `plpgsql_check` (chỉ có ở `db_check` local) nên lỗi tên bảng / cột chỉ lộ khi chạy test.
- Chèn `auth.users` + mật khẩu có thể cần thêm `auth.identities` / cột khác tuỳ phiên bản GoTrue — Task 2 Step 3 kiểm; lệch thì sửa script.
- Làm tròn `daily_rate` 1 chữ số: hàng bán rất chậm (< 0,05/ngày) hiện "0" nhưng vẫn có `days_left`; dữ liệu demo không có hàng như vậy.
- Số trong lời Gemini không được đối chiếu lại với kết quả công cụ khi **đã có** dữ liệu (đã ghi ở R1 của AI-1); câu thử 18–20 kiểm tay phần này.
- Lối vào Home (ô "Sắp hết", dòng "Việc cần xử lý") và nút "Tạo phiếu nhập" **chưa làm**; RPC đã có `need_reorder_count` để gắn sau.
- Tên model Gemini / hạn mức đổi nhanh: kiểm lại trước khi chạy Task 4 Step 2 (lệnh liệt kê model ở AI-1 R3).

## Kết quả
- Task 1: viết `20261121001_inventory_purchase_forecast.sql`, `supabase/tests/inventory_purchase_forecast.sql`, REGISTRY. **Chưa chạy trên Dev** (người dùng chạy `supabase db push --linked` rồi psql test).
- Task 2: viết `scripts/ai/seed_demo_sales.sql`. **Chưa chạy** (chạy sau Task 1 Step 4).
- Task 3: `tools/forecast.ts` + `forecast_test.ts`, sửa `registry.ts`, `prompt.ts`, `prompt_test.ts`. `deno test` 97 passed / 0 failed; `deno check`, `deno fmt --check`, `deno lint` sạch. Không chạy `impact` (không có công cụ GitNexus trong phiên); thay đổi chỉ thêm 1 phần tử vào `buildTools` và 1 cụm từ vào `buildSystemPrompt`.
- Task 4: Step 1 xong (`doi_chieu` câu 18–20); `{san_pham_a}` = `Sữa tươi hộp 1L`, `{ma_don}` lấy từ bảng cuối script Task 2. Step 2–3 (deploy + chạy Gemini thật) chờ người dùng. PLAN.md dòng AI-3 đã có Plan ✅ từ trước.
- Sau R1: script lùi cả `stock_movements` / `value_movements` (lãi gộp theo kỳ khớp), thêm hồ sơ `platform_user_profiles`, `extensions.crypt`; mô tả công cụ dự báo bỏ cụm "hàng nào sắp hết". Chi tiết ở mục Review R1–R2.
- Chưa commit (chưa được yêu cầu).

- **Phát hiện khi chạy seed (2026-11-17):** `inventory._issue_for_sale` khoá cấp phát FEFO theo `lot_key`; hàng không quản lý lô cùng `lot_key = 00000000-…` nên đơn nhiều dòng bị chặn nhầm `INSUFFICIENT_STOCK` (số đã xuất cho sản phẩm trước bị trừ vào tồn sản phẩm sau). Người dùng chọn sửa lỗi gốc: migration patch `20261121002_inventory_issue_for_sale_alloc_key.sql` (khoá = `product_id:lot_key`, chỉ đổi 5 dòng), test `supabase/tests/inventory_issue_multi_line.sql` (`m1_multi_line_ok`, `m2_real_shortage_still_blocked`, `m3_stock_after`), REGISTRY. **Chưa chạy trên Dev.** Chưa chạy `impact` (không có GitNexus): `_issue_for_sale` gọi từ `sales.finalize_sales_order` và luồng đổi hàng — thay đổi chỉ sửa khoá cấp phát, hành vi một dòng / hàng có lô giữ nguyên.

- **Kết quả chạy Dev (người dùng, 2026-11-17):** `db push` áp `20261121002` (`20261121001` đã có từ trước); `inventory_issue_multi_line.sql` và `inventory_purchase_forecast.sql` chạy **không lỗi** (đạt); seed chạy xong, bảng dự báo khớp kỳ vọng: 6 hàng cần nhập (Bánh quy hết hàng nên nhập 80; Giấy vệ sinh 1,5 ngày / 34; Nước ngọt 1,9 / 130; Nước suối 3,2 / 330; Sữa tươi 3,3 / 200; Gạo 4,2 / 60), Cà phê `nen_nhap` NULL, 5 hàng còn lại 0. Lần chạy lại seed bỏ qua (cửa hàng đã có). **Còn chờ:** truy vấn đối chiếu giá vốn theo tháng, `functions deploy`, `run_eval.ts`.

**Lệnh người dùng chạy để test (trên Dev, theo thứ tự):**
```bash
# 1. áp migration mới
supabase db push --linked
# 1b. test bản vá đơn nhiều dòng — kỳ vọng không lỗi
supabase db query --linked -f supabase/tests/inventory_issue_multi_line.sql
# 2. test RPC (bọc rollback, không để lại dữ liệu) — kỳ vọng: KHÔNG có lỗi (lỗi sẽ in "FAIL: …"); NOTICE có thể không hiện qua Management API
supabase db query --linked -f supabase/tests/inventory_purchase_forecast.sql
# 3. dữ liệu mô phỏng (CHẠY MỘT LẦN, lúc không ai dùng Dev; nếu "Cửa hàng Demo AI" đã có từ bản cũ thì phải dọn / reset trước)
supabase db query --linked -f scripts/ai/seed_demo_sales.sql
# 4. đưa công cụ mới lên Edge Function
supabase functions deploy ai-assistant
# 5. bộ câu thử (env: SUPABASE_URL, SUPABASE_ANON_KEY của Dev, AI_EVAL_TENANT_ID + email/mật khẩu demo, AI_EVAL_SAN_PHAM_A="Sữa tươi hộp 1L", AI_EVAL_MA_DON từ bảng cuối bước 3)
deno run --allow-env --allow-net scripts/ai/run_eval.ts
```
Sau đó dán kết quả bước 2, bảng cuối bước 3 và bảng bước 5 để review đóng R3.

## Review

### R1 (2026-11-17) — có góp ý, chờ sửa

**Đã kiểm (phiên review, không đụng DB):** `deno test` **97 passed / 0 failed**; `deno check`, `deno fmt --check`, `deno lint` sạch. Đọc kỹ migration, test SQL, `forecast.ts` + test, script mô phỏng, `prompt.ts`, `registry.ts`, `eval_questions.json`.
**Đối chiếu bằng đọc code:** bucket tuần `8 - ((hôm nay - ngày) / 7)` (chia nguyên) cho trọng số 8…1, Σw = 36 ✓; bốn nhánh doanh số chép đúng `get_sales_stats` ✓; `days_left` tính từ rate chưa làm tròn ✓; `need_reorder_count` không phụ thuộc limit / lọc ✓; kẹp `p_limit` 1..20 ✓; sản phẩm tenant khác ⇒ `CONTEXT_INVALID` ✓; số kỳ vọng trong test SQL (0,5 / 144 / 128; 110/252; 26 + 5) khớp công thức ✓; script là một khối `do` ⇒ lỗi giữa chừng thì rollback cả khối (tốt hơn điều plan lo).
**Chưa kiểm được, cần người dùng dán kết quả:** `supabase db push --linked`; `psql … -f supabase/tests/inventory_purchase_forecast.sql` (kỳ vọng `NOTICE: inventory_purchase_forecast: OK`); chạy `seed_demo_sales.sql` (bảng cuối khớp cột "Kỳ vọng"); đăng nhập hai tài khoản demo; `run_eval.ts`.

| # | Mức | Chỗ | Vấn đề | Cách sửa |
|---|---|---|---|---|
| 1 | **Cao (demo)** | `scripts/ai/seed_demo_sales.sql` (khối lùi `completed_at`) | Chỉ lùi `sales_orders.completed_at`. Báo cáo lãi gộp theo sản phẩm lấy **doanh thu theo `completed_at`** nhưng **giá vốn từ `inventory.value_movements.business_date`** (`20261119001_inventory_reports.sql` ~dòng 166–177) — mà các dòng này mang ngày chạy script. Hệ quả: "lãi gộp tháng này" (câu 13, 14, bước demo lãi gộp) = doanh thu của tháng này trừ giá vốn của **cả 90 ngày** ⇒ lỗ nặng; "tháng 10" ⇒ giá vốn 0 ⇒ lãi 100%. Câu thử vẫn "đạt" (trợ lý và báo cáo cùng sai) nên eval không bắt được. Plan chỉ ghi lệch thẻ kho và nói dự báo không ảnh hưởng — **bỏ sót lãi gộp**. | Lùi cả `business_date` của các dòng bán của đơn đó (`inventory.value_movements`, và `inventory.stock_movements` cho thẻ kho) cùng số ngày. Đọc trước xem có trigger chặn UPDATE không (bảng sổ có thể bất biến); nếu chặn thì: bỏ câu 13, 14 và bước demo lãi gộp khỏi bộ demo trên dữ liệu mô phỏng và ghi rõ trong báo cáo. Chạy lại cần dọn Dev (`db reset --linked`, hỏi trước) vì script bỏ qua khi cửa hàng đã có. |
| 2 | Thấp–TB | `tools/forecast.ts` (mô tả công cụ) | Mô tả có cụm "hàng nào sắp hết" — trùng với `tinh_hinh_ton_kho`. Câu 8 "Hàng nào sắp hết?" mong đợi `tinh_hinh_ton_kho`; Gemini có thể chọn `du_bao_ban_hang` ⇒ lệch công cụ trong bộ câu thử. | Bỏ cụm đó khỏi mô tả dự báo; ghi "chỉ dùng khi hỏi *nên nhập / nhập bao nhiêu / còn bán mấy ngày*". Nếu muốn câu 8 vẫn đi `tinh_hinh_ton_kho`, thêm "danh sách tồn thuần thì dùng tinh_hinh_ton_kho". Chạy lại câu 8 và 18. |
| 3 | Thấp | script + app | Hai tài khoản demo chưa có hồ sơ `iam.platform_user_profiles`: nhãn người bán ra "Nhân viên" (câu 6, mọi đơn đều do chủ bán); đăng nhập vào app có thể cần hồ sơ / lựa chọn cửa hàng. | Kiểm ở Task 2 Step 3 (đăng nhập thật). Nếu thiếu thì thêm hồ sơ vào script. |
| 4 | Thấp | script (`crypt`, `gen_salt`) | Trên Supabase, pgcrypto nằm ở schema `extensions`; nếu `search_path` của kết nối không có thì lỗi "function gen_salt does not exist" (cả khối rollback, an toàn). | Nếu gặp: đổi sang `extensions.crypt(…, extensions.gen_salt('bf'))`. |
| 5 | Ghi nhận | định nghĩa "sắp hết" | `tinh_hinh_ton_kho.sap_het` loại hàng đã hết (`available > 0`), còn `need_reorder_count` của dự báo **gồm** hàng hết (`available ≤ ngưỡng`). Dữ liệu demo: 5 so với 6 (Bánh quy). Chưa ảnh hưởng gì vì Home chưa nối. | Khi nối ô "Sắp hết" ở Home, chọn một định nghĩa và dùng chung. |
| 6 | Ghi nhận | test SQL | Chưa có ca cho nhánh **đơn huỷ** và **hàng đổi** của dự báo (cùng nợ với `get_sales_stats`, chép nguyên nên rủi ro thấp). `impact` chưa chạy (phiên làm không có GitNexus) — thay đổi chỉ thêm 1 phần tử `buildTools` + 1 cụm ở `buildSystemPrompt`. | Ghi nợ; không chặn. |

**Người dùng chạy giúp (Dev) rồi dán kết quả:**
```bash
supabase db push --linked
supabase db query --linked -f supabase/tests/inventory_purchase_forecast.sql
```
Chưa chạy seed trước khi sửa mục 1 (nếu chưa chạy), để khỏi phải reset Dev.

### Sửa theo R1 (2026-11-17)
- Mục 1 **đã xác nhận** (báo cáo lãi gộp theo sản phẩm lấy giá vốn từ `value_movements.business_date`; sổ có trigger append-only): `seed_demo_sales.sql` nay tạm tắt trigger user của `stock_movements` / `value_movements`, lùi `business_date` dòng xuất kho theo `completed_at` đơn, lùi dòng nhập đầu về hôm nay − 90, và lùi `value_movements` theo `movement_id`; dừng với lỗi nếu không khớp được dòng xuất kho nào. Script giữ khoá bảng sổ đến hết khối ⇒ chạy lúc không ai dùng Dev. **Chưa chạy** — báo lại kết quả.
- Mục 2: mô tả `du_bao_ban_hang` bỏ cụm "hàng nào sắp hết", thêm hướng dẫn dùng `tinh_hinh_ton_kho` cho tồn thuần. Cần chạy lại câu 8 và 18 khi chạy eval.
- Mục 3: thêm hồ sơ `iam.platform_user_profiles` (upsert) cho hai tài khoản demo.
- Mục 4: đổi sang `extensions.crypt` / `extensions.gen_salt`.
- Mục 5, 6: ghi nhận, chưa làm.


### R2 (2026-11-17) — đạt phần đọc code; còn chờ kết quả chạy Dev

**Đã kiểm (phiên review, không đụng DB):** `deno test` **97 passed / 0 failed**; `deno fmt --check`, `deno lint` sạch.

| R1 | Kết quả đọc lại code |
|---|---|
| 1 Giá vốn không lùi ngày | ✅ Script tắt `trigger user` trên `stock_movements` + `value_movements` (hai bảng chỉ có trigger append-only `trg_*_forbid_mutation`, không trigger nào khác), lùi `business_date` dòng `SALE` theo `completed_at` của đơn (`intent_id = sales_orders.id`, đúng: `_issue_for_sale` nhận `v_order_id` làm `p_intent_id`), `RECEIPT` về `hôm nay − 90`, rồi `value_movements.business_date` theo `movement_id`. Làm trong cùng khối `do` ⇒ lỗi thì rollback cả trigger. Có chặn `v_n2 = 0`. Thêm dòng chú thích đầu script. |
| 2 Mô tả công cụ | ✅ Bỏ "hàng nào sắp hết"; ghi "CHỈ dùng khi hỏi nên nhập / còn bán mấy ngày", danh sách tồn thuần ⇒ `tinh_hinh_ton_kho`. |
| 3 Hồ sơ tài khoản demo | ✅ Thêm `iam.platform_user_profiles` (cột `given_name`, `family_middle_name` có thật). Tên hiện "Demo Chủ" / "Demo Thu ngân" (họ đệm trước tên) — chỉ thẩm mỹ. |
| 4 `crypt` / `gen_salt` | ✅ Đổi sang `extensions.crypt(…, extensions.gen_salt('bf'))`. |

**Còn lại (nhỏ):**
- Dòng "Rủi ro / lưu ý" ở mục Task 2 của plan (dòng "thẻ kho / chuyển động kho mang ngày chạy script (không lùi)") đã **lỗi thời** vì script nay lùi cả sổ. Sửa câu cho khớp (hoặc bỏ), và ghi vào báo cáo đồ án: dữ liệu mô phỏng được dựng bằng cách tắt trigger sổ append-only trong lúc seed.
- Script giữ khoá `ALTER TABLE` hai bảng sổ đến hết khối (đã ghi chú đầu script): chạy lúc không ai dùng Dev.
- Nếu cửa hàng "Cửa hàng Demo AI" **đã được tạo trên Dev trước bản sửa**, script sẽ bỏ qua (idempotent) và giá vốn vẫn lệch ngày ⇒ cần dọn / `db reset --linked` (hỏi trước) rồi chạy lại.
- Vẫn chưa có kết quả chạy: `supabase db push --linked`, `psql … inventory_purchase_forecast.sql` (kỳ vọng `NOTICE: inventory_purchase_forecast: OK`), seed (bảng cuối khớp "Kỳ vọng"; kiểm thêm `get_gross_profit_report` tháng này ra lãi dương hợp lý), đăng nhập hai tài khoản, `run_eval.ts` (câu 8 ⇒ `tinh_hinh_ton_kho`, câu 18 ⇒ `du_bao_ban_hang`).
