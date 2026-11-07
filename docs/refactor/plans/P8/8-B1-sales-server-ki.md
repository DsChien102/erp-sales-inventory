# 8-B1 — Sales: sửa server theo TH-05 (khách, ngày hẹn, ngày hẹn đổi hàng, tìm không dấu, đơn vị đã bán) + test SQL TH-05 9.3

> Theme 5 (mã cũ P8) · Bước (b) sửa theo TH-05, phần server · Gồm: KI-02 (chỉ test + tài liệu), KI-03, KI-04, KI-05, KI-09, TH-02 KI-08, câu cho mã chặn mới ở `_classifyResult` (8-A2 Rủi ro), test SQL TH-05 9.3.
> Trạng thái: Plan ✅ (viết 2026-11-07, duyệt 2026-11-07) | Làm ✅ 2026-11-07 | Review R1 CHƯA ĐẠT, R2 ĐẠT 2026-11-07 (mục 10)
> Trước: 8-A4 (review ĐẠT). Sau: 8-B2 (sửa app, thêm ca vào `sales_th05.sql`), 8-B3 (Thu tiền), 8-C.
> Tài liệu: [TH-05](../../../02-yeu-cau/TH-05-ban-hang-va-don-hang.md) BR-20, BR-23, BR-24, BR-33, BR-51, 6.4, 7.3, 9.2, 9.3; [TH-02](../../../02-yeu-cau/TH-02-san-pham-va-gia-ban.md) BR-13, KI-08; PLAN.md "Quy tắc migration". Mẫu: [4-B](../P4/4-B-sua-ki-th03.md) (G2 `unaccent`, test SQL), `supabase/tests/pricing_th04.sql` (dựng tenant / owner / JWT), `supabase/tests/partner_th03.sql` (hàm `_expect_err`).
>
> **Cho phiên code:** dùng `superpowers:executing-plans` (tuần tự). Mỗi task xong ghi ngay mục 9 theo mẫu (tệp:dòng, lệch plan, test, impact). **Không commit** (người dùng commit sau `detect_changes()`). **Không chạy SQL, không reset DB, không push** — chạy `sales_th05.sql` là việc của người dùng (mục 7.2). **Không ghi mục 10**.

## 1. Mục tiêu

- Server tự chặn những gì hiện chỉ app chặn: khách ngừng hoạt động (`CUSTOMER_INVALID`), ngày hẹn trước hôm nay (`RECEIVABLE_DUE_DATE_INVALID`).
- Đổi hàng phát sinh nợ thì lưu ngày hẹn vào đơn.
- `search_sales_orders('an binh')` tìm thấy "An Bình".
- Đơn vị đã dùng trong dòng đơn bán, dòng đổi/trả, dòng nháp đang mở thì không xoá được.
- Có `supabase/tests/sales_th05.sql` phủ đủ danh sách "SQL / RPC test" của TH-05 9.3.

**Không làm:** tính lại giá ở precheck (Q1); sửa app ngoài `_classifyResult` (8-B2); `record_sales_payment` không đổi (8-B3 chỉ gọi); bỏ outbox (8-C).

## 2. Quyết định

| # | Câu hỏi | Chốt |
|---|---|---|
| Q1 | KI-02: `finalize_sales_order` bản mới nhất (`20261031017_sales_buyer_invoice_snapshot.sql:215-325`) **đã** tính lại giá qua `pricing.preview_sales_working_state_pricing` và so `lineTotal` → `PRICE_CHANGED` | **Người dùng chốt 2026-11-07:** không sửa SQL; thêm test `PRICE_CHANGED`; sửa TH-05 KI-02 / BR-23 thành đã làm. Precheck vẫn tính tổng theo đơn giá app (chỉ hiển thị; finalize chặn thật) |
| Q2 | Mã cho ngày hẹn quá khứ | **Người dùng chốt 2026-11-07:** mã mới `RECEIVABLE_DUE_DATE_INVALID`, câu "Ngày hẹn thanh toán không được trước hôm nay."; finalize xếp vào `blocked`; `confirm_return_exchange` dùng `RETURN_EXCHANGE_BLOCKED` như chỗ kiểm thiếu ngày hẹn hiện có |
| Q3 | Khách "không còn hoạt động" | **Người dùng chốt 2026-11-07:** `partner.partners.status <> 'active'` **hoặc** không có `partner.partner_roles` `role = 'customer'` và `is_active = true` |
| Q4 | TH-02 KI-08: nháp nào giữ đơn vị | **Người dùng chốt 2026-11-07:** chỉ dòng của nháp `status = 'active'` |
| Q5 | "Hôm nay" | `(now() at time zone 'Asia/Ho_Chi_Minh')::date` — như cách đánh mã đơn (`20261031017:458`) |
| Q6 | Đổi hàng có nợ, đơn đã có ngày hẹn cũ | Ghi đè bằng ngày gửi lên (BR-51 "lưu vào `sales_orders.payment_due_date`"). Không nợ mới thì không đụng |
| Q7 | Hàm catalog là `language sql` trong `20260709023` (chạy trước khi có schema `sales` ở `20260830005`); Postgres kiểm thân hàm SQL lúc tạo | Đổi sang `language plpgsql` **ngay trong `20260709023`** (thân plpgsql không kiểm bảng lúc tạo). Giữ chữ ký, `stable`, `security definer`; tên bảng viết đủ `sales.…`; giữ `revoke` / `grant` (`:124-127`) |
| Q8 | Chạy test SQL | Phiên code **viết** test, không chạy (quy ước DB của người dùng). Người dùng chạy ở 7.2 |

## 3. Hiện trạng (đo 2026-11-07)

| RPC / hàm | Định nghĩa mới nhất | Chỗ sửa |
|---|---|---|
| `sales.precheck_sales_order_checkout` | `20260830008_sales_checkout_rpcs.sql:11-186` | sau kiểm tiền tệ `:59-65` (khách); nhánh nợ `:142-155` (ngày hẹn) |
| `sales.finalize_sales_order` | `20261031017_sales_buyer_invoice_snapshot.sql:11-674` | sau kiểm snapshot khách `:193-213` (khách); sau `:426-431` (ngày hẹn); danh sách `blocked` `:640-644` |
| `sales.confirm_return_exchange` | `20260904001_sales_normalize_outbox_and_commands.sql:654-…` | kiểm nợ `:1085-1098`; `update sales.sales_orders` `:1294-1298` |
| `sales.search_sales_orders` | `20261031021_sales_list_einvoice_issuance_filter.sql:264-…` | `v_search` `:306`; điều kiện `:442-450` |
| `catalog._product_unit_has_sales_transaction_usage` | `20260709023_catalog_delete_product_conversion_unit.sql:9-23` (stub `select false`) | cả thân |
| App: `SalesCheckoutCubit._classifyResult` | `apps/erp/lib/features/sales/logic/sales_checkout_cubit.dart:265-304` | `switch (result.blockedCode)` `:283-287` |

Bảng dòng (không FK tới `catalog.product_units`): `sales.sales_order_lines`, `sales.sales_order_draft_lines` (FK `sales_order_drafts`), `sales.return_exchange_lines` (`20260830005_sales_rebuild_schema.sql:71`, `:150`, `:337`). Precheck: app hiện **nguyên câu** `message` của blocker (`logic/sales_checkout_orchestrator.dart:70-71`) ⇒ câu blocker mới viết tiếng Việt.

Không có bảng "Đang làm gì": plan không xoá / tách / thay widget, page, cubit hay route (chỉ thêm kiểm tra ở RPC và thêm nhánh `switch`).

## 4. Thiết kế

### G1. KI-03 `CUSTOMER_INVALID`

Điều kiện chung (Q3), viết lặp ở 2 hàm (không thêm hàm chung — 2 chỗ, cùng migration theme 5):

```sql
p_customer_id is not null and not exists (
  select 1
  from partner.partners pp
  join partner.partner_roles pr on pr.partner_id = pp.id and pr.role = 'customer' and pr.is_active
  where pp.tenant_id = p_tenant_id and pp.id = p_customer_id and pp.status = 'active'
)
```

- Precheck: thêm blocker `{code: 'CUSTOMER_INVALID', message: 'Khách hàng không còn hoạt động.', field: 'customerId'}`. Thêm `partner` vào `search_path` **không** cần (tên bảng viết đủ).
- Finalize: ném `{code: 'CUSTOMER_INVALID', message: 'Customer is inactive or not a customer.'}` ngay sau khối `:193-213`; thêm `'CUSTOMER_INVALID'` vào danh sách `blocked` `:640-644`.
- Kiểm cột thật trước khi viết: `partner.partners.tenant_id`, `partner.partner_roles.partner_id` (`20260714001_partner_v2_schema.sql:96-172`). Tên lệch ⇒ dùng tên thật, ghi Kết quả.

### G2. KI-04 `RECEIVABLE_DUE_DATE_INVALID`

`v_today date := (now() at time zone 'Asia/Ho_Chi_Minh')::date;`

- Precheck `:149-155`: thêm nhánh `elsif v_remaining_minor > 0 and p_payment_due_date < v_today` → blocker `{code: 'RECEIVABLE_DUE_DATE_INVALID', message: 'Ngày hẹn thanh toán không được trước hôm nay.', field: 'dueDate'}`.
- Finalize sau `:426-431`: `v_remaining_minor > 0 and p_payment_due_date < v_today` → ném `RECEIVABLE_DUE_DATE_INVALID`; thêm mã vào danh sách `blocked`.
- Confirm đổi/trả, trong `if v_collect_debt > 0` sau kiểm `payment_due_date is null`: `payment_due_date < v_today` → `RETURN_EXCHANGE_BLOCKED`, message `'Payment due date cannot be before today.'`.
- Chỉ kiểm khi **còn nợ** — trả đủ mà vẫn gửi ngày cũ thì không chặn (như kiểm thiếu ngày hiện có).

### G3. KI-05 lưu ngày hẹn khi đổi hàng

`update sales.sales_orders` ở `:1294-1298` thêm:
```sql
payment_due_date = case when v_collect_debt > 0 then confirm_return_exchange.payment_due_date else payment_due_date end,
```
(`#variable_conflict use_column` đang bật ⇒ tham số phải viết `confirm_return_exchange.payment_due_date`.)

### G4. KI-09 tìm đơn không dấu

`v_search := nullif(btrim(catalog.unaccent_immutable(coalesce(search_text, ''))), '');` và cả 3 vế `:444-449` bọc `catalog.unaccent_immutable(…) ilike '%' || v_search || '%'`. Mẫu: `20260715001_partner_list_search_behavior.sql:38`, `:89`. `unaccent_immutable` trả `''` cho `null` nên `coalesce` cũ vẫn đúng.

### G5. TH-02 KI-08

```sql
create or replace function catalog._product_unit_has_sales_transaction_usage(
  p_tenant_id uuid, p_product_id uuid, p_product_unit_id uuid
)
returns boolean
language plpgsql
stable
security definer
set search_path = catalog, pg_temp
as $$
begin
  return exists (select 1 from sales.sales_order_lines l
                 where l.tenant_id = p_tenant_id and l.product_id = p_product_id
                   and l.product_unit_id = p_product_unit_id)
      or exists (select 1 from sales.return_exchange_lines l
                 where l.tenant_id = p_tenant_id and l.product_id = p_product_id
                   and l.product_unit_id = p_product_unit_id)
      or exists (select 1 from sales.sales_order_draft_lines l
                 join sales.sales_order_drafts d
                   on d.tenant_id = l.tenant_id and d.id = l.sales_order_draft_id
                 where l.tenant_id = p_tenant_id and l.product_id = p_product_id
                   and l.product_unit_id = p_product_unit_id and d.status = 'active');
end;
$$;
```
Cột lấy theo `20260830005_sales_rebuild_schema.sql:71-92` (`sales_order_draft_id`). Sửa luôn 2 dòng chú thích cũ (`Foundation MVP…`). Câu chặn giữ nguyên (`:42`).

### G6. KI-02 — không sửa SQL (Q1)

### G7. App: câu cho mã chặn mới

`_classifyResult` `:283-287` thêm:
- `'CUSTOMER_INVALID' => 'Khách hàng không còn hoạt động.'`
- `'RECEIVABLE_DUE_DATE_INVALID' => 'Ngày hẹn thanh toán không được trước hôm nay.'`

### G8. `supabase/tests/sales_th05.sql`

Khung như `pricing_th04.sql`: `begin; … do $$ … $$; rollback;`, notice cuối `'sales_th05: OK'`, mọi ca sai `raise exception 'FAIL: …'`. Hàm giúp (tạo trong giao dịch):

| Hàm | Việc |
|---|---|
| `public._th05_expect_err(p_sql text, p_code text)` | chép `_th03_expect_err` (so `sqlerrm like '%"code": "' || p_code || '"%'` **hoặc** `like p_code || '%'` — RPC sales ném JSON) |
| `public._th05_customer(p_tenant, p_actor, p_name, p_phone) returns uuid` | `partner.create_partner(…, 'person', array['customer'], …)` như `_th03_person` |
| `public._th05_finalize(p_tenant, p_actor, p_store, p_customer uuid, p_lines jsonb, p_payments jsonb, p_due date, p_key text, p_source_draft uuid default null, p_source_version int default null) returns jsonb` | dựng `p_commercial_snapshot` từ `p_lines` (`store.storeId`, `seller.actorId`, `customer` (null khi Khách lẻ; có `customerId` + `displayName`), mỗi dòng `{lineId, product{productId, displayName}, unit{productUnitId, unitName}, quantityMicros, lineTotal{amountMinor}}` lấy đúng tiền server tính); `p_correlation_id` = `gen_random_uuid()::text`, `p_command_id` = `gen_random_uuid()`, `p_payload_hash` = `'h'` (server tự băm, `:111-123`) |

Mỗi dòng `p_lines`: `{product_id, product_unit_id, quantity_micros, unit_price: {amount_minor, currency_code: 'VND'}}`. Dữ liệu: owner + tenant + JWT như `pricing_th04.sql:84-112`; 2 sản phẩm qua `catalog.create_guided_product` + `catalog.set_product_unit_price_band` (P1 giá 100.000, P2 giá 150.000); sau đó kiểm `is_ready_to_sell = true` — không ⇒ `update catalog.products set is_ready_to_sell = true` (trong giao dịch rollback) và ghi Kết quả; khách "Đại lý An Bình" và "Khách B".

**Ca** (mã ca dùng làm tên trong Kết quả; ✱ = ca kiểm phần sửa của plan này, còn lại kiểm hành vi đang có):

| Ca | Kịch bản | Kỳ vọng |
|---|---|---|
| C01 | finalize cùng key 2 lần, cùng nội dung | cùng `salesOrderId`; đếm `sales_orders` của tenant = 1 |
| C02 | cùng key, khác số lượng | `IDEMPOTENCY_CONFLICT` |
| C03 | lưu nháp (`sales.save_sales_order_draft`), finalize với `p_expected_source_version` = version − 1 | `status = 'blocked'`, `blockedCode = 'STALE_VERSION'`; không có đơn mới |
| C04 ✱ | finalize với `lineTotal` của snapshot khác tiền server (không nhập tay) | `blocked`, `blockedCode = 'PRICE_CHANGED'` |
| C05 ✱ | đặt `partners.status` của Khách B thành không active (dùng RPC partner nếu có, không thì `update`); precheck; finalize | precheck `blockers` có `code = 'CUSTOMER_INVALID'`, `canFinalize = false`; finalize `blockedCode = 'CUSTOMER_INVALID'` |
| C06 ✱ | khách có partner active nhưng vai trò `customer` `is_active = false` | như C05 |
| C07 ✱ | còn nợ, ngày hẹn = hôm nay VN − 1 | precheck có `RECEIVABLE_DUE_DATE_INVALID`; finalize `blockedCode = 'RECEIVABLE_DUE_DATE_INVALID'` |
| C08 ✱ | còn nợ, ngày hẹn = hôm nay VN | finalize `succeeded`, `sales_orders.payment_due_date` = ngày đó |
| C09 | đơn nợ 100% của An Bình; `record_sales_payment` vượt `outstanding` | `OVERPAYMENT_NOT_ALLOWED` |
| C10 | huỷ đơn C09 (`precheck` + `confirm_sales_order_cancellation`); rồi `record_sales_payment` | huỷ được; `current_payable_amount_minor = 0`; thu → `ORDER_CANCELLED` |
| C11 | đơn đã thu 1 phần; `confirm_sales_order_cancellation` | `CANCELLATION_BLOCKED` có `PAYMENT_ALREADY_COLLECTED` (kiểm mã trong `details` / message thật — ghi Kết quả) |
| C12 | đơn có phiếu đổi/trả đã xác nhận; huỷ | `RETURN_EXCHANGE_CONFLICT` |
| C13 | 2 phiếu trả cùng dòng, tổng vượt số bán (`start_return_exchange` ×2) | phiếu sau `RETURN_QUANTITY_EXCEEDED` |
| C14 ✱ | đổi hàng: trả 1 P1, đổi 1 P2 (đắt hơn), `confirm_return_exchange` trả một phần + `payment_due_date` = hôm nay VN + 7 | `sales_orders.payment_due_date` = ngày đó |
| C15 ✱ | như C14 nhưng ngày = hôm nay VN − 1 | `RETURN_EXCHANGE_BLOCKED` |
| C16 ✱ | `search_sales_orders(…, search_text => 'an binh')` | có đơn của "Đại lý An Bình" |
| C17 ✱ | `catalog.delete_product_conversion_unit` cho đơn vị quy đổi đã nằm trong dòng đơn bán | chặn với câu "Đơn vị đã được dùng trong giao dịch…" (theo cách hàm báo: lỗi hoặc `blocked_reason` — đọc `20260709023:25-…`, ghi Kết quả) |
| C18 ✱ | đơn vị quy đổi chỉ nằm trong dòng của nháp đã huỷ | xoá được |
| C19 ✱ | đơn vị quy đổi nằm trong dòng nháp `active` | chặn |

Chữ ký `start_return_exchange`, `evaluate_return_exchange_valuation`, `confirm_return_exchange`, `precheck_sales_order_cancellation`, `confirm_sales_order_cancellation`, `record_sales_payment`, `search_sales_orders`, `save_sales_order_draft`, `cancel_sales_order_draft`: đọc ở migration mới nhất (`grep -l "function sales.<tên>(" supabase/migrations/*.sql | tail -1`), gọi bằng tên tham số (`=>`). Ca C17–C19 cần đơn vị quy đổi (không phải đơn vị cơ sở): tạo bằng RPC catalog thêm đơn vị (như `catalog_th02.sql`).

## 5. Các bước

**Ràng buộc chung** (mọi task):
- Chỉ sửa tệp liệt kê ở từng task. Sửa migration **tại chỗ** (PLAN "Quy tắc migration"), không tạo migration mới. Không đụng `modules/`.
- Trước khi sửa symbol có sẵn: `node .gitnexus/run.cjs impact <symbol> --direction upstream --repo erp-sales-inventory`, ghi bảng vào Kết quả; HIGH / CRITICAL ⇒ dừng, báo người dùng.
- Câu tiếng Việt chép nguyên văn từ mục 4.
- SQL: viết, **không chạy** (Q8). Kiểm cú pháp bằng đọc lại; người dùng chạy ở 7.2.

### Task 1: Khung `sales_th05.sql` + ca hành vi đang có

**Files:** Create: `supabase/tests/sales_th05.sql`

- [ ] **1.1** Đầu tệp (chú thích cách chạy như `partner_th03.sql:1-4`), 3 hàm giúp G8, dựng dữ liệu.
- [ ] **1.2** Ca C01, C02, C03, C09, C10, C11, C12, C13 (hành vi đang có — phải xanh trên code hiện tại).
- [ ] **1.3** Ghi Kết quả: số dòng, danh sách ca, chỗ phải đoán (tên cột, cách báo lỗi) để review soi.

### Task 2: G1 KI-03

**Files:** Modify: `supabase/migrations/20260830008_sales_checkout_rpcs.sql:59-65`, `supabase/migrations/20261031017_sales_buyer_invoice_snapshot.sql:213`, `:640-644`; `supabase/tests/sales_th05.sql` (C05, C06)

- [ ] **2.1** Thêm ca C05, C06.
- [ ] **2.2** Sửa precheck + finalize theo G1.

### Task 3: G2 KI-04 + G3 KI-05

**Files:** Modify: `20260830008…:142-155`; `20261031017…:426-431`, `:640-644`; `20260904001_sales_normalize_outbox_and_commands.sql:1085-1098`, `:1294-1298`; `sales_th05.sql` (C07, C08, C14, C15)

- [ ] **3.1** Thêm ca C07, C08, C14, C15.
- [ ] **3.2** Sửa 3 hàm theo G2, G3.

### Task 4: G4 KI-09 + G5 TH-02 KI-08 + C04

**Files:** Modify: `20261031021_sales_list_einvoice_issuance_filter.sql:306`, `:442-450`; `20260709023_catalog_delete_product_conversion_unit.sql:9-23`; `sales_th05.sql` (C04, C16–C19)

- [ ] **4.1** Thêm ca C04, C16, C17, C18, C19.
- [ ] **4.2** Sửa theo G4, G5.

### Task 5: G7 câu ở `_classifyResult`

**Files:** Modify: `apps/erp/lib/features/sales/logic/sales_checkout_cubit.dart:283-287`; Test: `apps/erp/test/features/sales/presentation_module/bloc/sales_checkout_cubit_test.dart`

- [ ] **5.1** Test (cạnh ca `PRICE_CHANGED` đang có của tệp): `blocked_customer_invalid_message` — finalize trả `CheckoutResultDto(status: blocked, blockedCode: 'CUSTOMER_INVALID')` ⇒ `state.attemptErrorMessage == 'Khách hàng không còn hoạt động.'`; `blocked_due_date_invalid_message` — `'RECEIVABLE_DUE_DATE_INVALID'` ⇒ `'Ngày hẹn thanh toán không được trước hôm nay.'`.
- [ ] **5.2** `cd apps/erp && flutter test test/features/sales/presentation_module/bloc/sales_checkout_cubit_test.dart` → FAIL 2 ca mới.
- [ ] **5.3** Thêm 2 nhánh. Chạy lại → PASS.

### Task 6: Tài liệu + kiểm toàn bộ + Kết quả

**Files:** Modify: `docs/02-yeu-cau/TH-05-ban-hang-va-don-hang.md` (BR-20, BR-23, BR-24, BR-51 bỏ 🔧; 6.4 thêm dòng `RECEIVABLE_DUE_DATE_INVALID` + bỏ 🔧 ở `CUSTOMER_INVALID`; 7.3 KI-02 "Đã có ở `finalize` (20261031017), 8-B1 thêm test", KI-03/04/05/09 "Đã sửa 8-B1"; 9.3 bỏ 🔧 các ca đã có); `docs/02-yeu-cau/TH-02-san-pham-va-gia-ban.md` (BR-13, KI-08, dòng `:1085`); `docs/refactor/PLAN.md` (dòng 8-B1: Làm ✅ + ngày)

- [ ] **6.1** Sửa tài liệu như trên.
- [ ] **6.2** `cd apps/erp && dart analyze lib/features/sales test/features/sales` → 0 lỗi, 0 cảnh báo mới.
- [ ] **6.3** `flutter test test/features/sales` → PASS (so số với mốc sau 8-A4, ghi số).
- [ ] **6.4** `node .gitnexus/run.cjs analyze` rồi `node .gitnexus/run.cjs detect-changes --repo erp-sales-inventory --scope all`: chỉ tệp trong plan; ghi số tệp / symbol / luồng / rủi ro. Hoàn nguyên `AGENTS.md` / `CLAUDE.md` nếu `analyze` sửa.

## 6. Review Focus (chưa task nào test tự động trên app, phiên review soi)

1. **Ngày hẹn = hôm nay, bán lúc 00:00–07:00 giờ VN:** lúc đó ngày UTC còn là hôm qua. Server phải so theo giờ VN (Q5); review đọc lại biểu thức, không được dùng `current_date` (theo múi giờ phiên DB) — dùng nhầm thì ca C08 vẫn xanh vào ban ngày.
2. **Replay idempotency sau khi thêm kiểm:** đơn đã tạo trước khi khách bị ngừng — gọi lại cùng key phải trả kết quả cũ (`replay` ở `:131-133` đứng **trước** kiểm khách). Kiểm thứ tự trong diff.
3. **Precheck của Khách lẻ:** `p_customer_id is null` không được sinh `CUSTOMER_INVALID`.
4. **`#variable_conflict use_column`** ở `confirm_return_exchange`: `payment_due_date` không tiền tố là **cột**, gán nhầm ⇒ giữ nguyên ngày cũ; C14 bắt được.
5. **Tìm theo mã đơn có chữ thường** (`dh2026…`): `unaccent` không đổi hoa / thường, `ilike` vẫn lo — giữ `ilike`, không đổi sang `like`.

## 7. Kiểm tra

### 7.1 Tự động
Task 5, Task 6.

### 7.2 Việc của người dùng
- DB local: reset rồi `psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/sales_th05.sql` → `sales_th05: OK`. Ca nào FAIL ⇒ báo phiên sửa.
- Dev: reset (đã sửa migration đã áp).
- Kiểm tay (iPhone simulator + Chrome): (1) bán nợ cho khách vừa ngừng hoạt động ở màn khác → "Khách hàng không còn hoạt động."; (2) tìm đơn "an binh" ở SG-08 ra "An Bình"; (3) catalog: xoá đơn vị quy đổi đã bán → câu "Đơn vị đã được dùng trong giao dịch…"; (4) đổi hàng còn nợ, chọn ngày hẹn → chi tiết đơn hiện hẹn thanh toán mới.

## 8. Rủi ro / lưu ý

- **Migration đã áp:** sửa tại chỗ ⇒ Dev / local không tự nhận tới khi reset (việc người dùng).
- **`plpgsql` cho hàm catalog:** lỗi tên bảng chỉ lộ khi chạy, không lộ khi `db reset` ⇒ C17–C19 là nơi duy nhất bắt.
- **Câu blocker tiếng Việt trong SQL:** app hiện nguyên văn ở precheck; sai chính tả là lộ ra người dùng.
- **8-B2** thêm ca vào `sales_th05.sql` (tìm nháp, lọc người tạo, "Tạo bởi"); **8-B3** thêm ca thu tiền.

## 9. Kết quả (phiên làm code ghi)

<!-- Ghi ngay sau mỗi task: tệp:dòng, lệch plan, số test / ca, bảng impact. -->

**Thứ tự làm lệch plan:** làm migration (Task 2–4) và app (Task 5) trước, viết trọn `sales_th05.sql` một lượt sau (Task 1 + ca ✱ gộp). Không ảnh hưởng kết quả; không chạy SQL (Q8).

**Impact (gitnexus, upstream):** `precheck_sales_order_checkout`, `finalize_sales_order`, `confirm_return_exchange`, `search_sales_orders` — chỉ khớp thư mục `modules/sales/application`, 0 caller, LOW. `_product_unit_has_sales_transaction_usage` — không có trong index (SQL). `SalesCheckoutCubit._classifyResult` — LOW (6 symbol, 2 trực tiếp, 0 luồng).

| Task | Tệp | Việc |
|---|---|---|
| 2 (G1) | `20260830008_sales_checkout_rpcs.sql` (khối khách trước kiểm dòng; `v_today` ở declare), `20261031017_sales_buyer_invoice_snapshot.sql` (khối khách ngay trước tính giá; `blocked` thêm `CUSTOMER_INVALID`) | `CUSTOMER_INVALID` precheck + finalize. Khách lẻ (`p_customer_id is null`) không sinh blocker |
| 3 (G2, G3) | `20260830008…` nhánh `elsif … < v_today`; `20261031017…` sau kiểm thiếu ngày + `blocked` thêm `RECEIVABLE_DUE_DATE_INVALID`; `20260904001…` kiểm trong `v_collect_debt > 0` + `update sales.sales_orders` ghi `payment_due_date = case … confirm_return_exchange.payment_due_date` | Ngày hẹn quá khứ chặn; đổi hàng lưu ngày hẹn. "Hôm nay" luôn `(now() at time zone 'Asia/Ho_Chi_Minh')::date`; không dùng `current_date` |
| 4 (G4, G5) | `20261031021…` `v_search` + 3 vế bọc `catalog.unaccent_immutable`, giữ `ilike`; `20260709023…` hàm đổi `plpgsql`, đọc 3 bảng sales | Tìm không dấu; KI-08 |
| 5 (G7) | `sales_checkout_cubit.dart` +2 nhánh; test +2 ca | RED 2 ca → GREEN 29/29 |
| 6 | TH-05 (BR-20/23/24/33/51, 6.4 + dòng `RECEIVABLE_DUE_DATE_INVALID`, 7.3, 9.3), TH-02 (BR-13, KI-08, dòng US-04.4), PLAN.md | Bỏ 🔧 |

**Lệch plan / đoán:**
- Cột partner thật là `partner.partners.partner_id` (không phải `id`) — SQL dùng `pp.partner_id`; `partner_roles` có `partner_id`, `tenant_id`, `role`, `is_active` đúng plan.
- TH-02 KI-08 ghi tên bảng `return_exchange_order_lines`, thật là `sales.return_exchange_lines` — đã sửa tài liệu.
- Precheck không thêm `partner` vào `search_path` (tên bảng viết đủ).
- Câu blocker tiếng Việt chép nguyên văn mục 4.

**`sales_th05.sql`:** ~600 dòng, ca C01–C19 (C14/C15 dùng chung đơn với C12). Chưa chạy. **Chỗ phải đoán, review soi / người dùng soi khi chạy:**
1. Khoá trả của `start_return_exchange` (`returnExchangeId`, `version` ở top-level kết quả) và `draftId`/`id` của `save_sales_order_draft` (dùng `coalesce`).
2. C02: giả định `IDEMPOTENCY_CONFLICT` được ném (không trả JSON `failed`).
3. C13: giả định phiếu 1 chưa xác nhận đã giữ số lượng; nếu không, ca không ném lỗi → sửa test (xác nhận phiếu 1 trước).
4. C11: chỉ bắt buộc `CANCELLATION_BLOCKED`; `PAYMENT_ALREADY_COLLECTED` chỉ `raise notice` nếu không có trong message.
5. C17/C19: chấp nhận lỗi chứa "Đơn vị đã được dùng trong giao dịch" hoặc `product_conversion_unit_delete_blocked`.
6. C05/C06 dùng `reset role` + `update` trực tiếp để ngừng khách / tắt vai trò; `is_ready_to_sell` tự bật nếu thiếu (có notice).
7. `search_sales_orders` kết quả đọc `items`; `current_payable_amount_minor` ở `sales.sales_order_settlements`.
8. Giá P1 đặt list 100.000 (floor 50.000) để `PRICE_CHANGED`/tổng khớp giá server.

**Kiểm:** `flutter test …/sales_checkout_cubit_test.dart` 29/29; `flutter test test/features/sales` 1195 pass (không có mốc 8-A4 trong tay để so — ghi số này làm mốc); `dart analyze lib/features/sales test/features/sales` 9 info `deprecated_member_use`, giống hệt trước khi sửa, 0 lỗi / cảnh báo. `detect-changes`: 12 tệp / 33 symbol / 0 luồng / LOW (đã hoàn nguyên `AGENTS.md`/`CLAUDE.md`). Không commit.

### Sửa theo R1 (phiên code, 2026-11-07) — chỉ `supabase/tests/sales_th05.sql` + mục 9; không chạy SQL

Đã đối chiếu từng lỗi R1 với migration trước khi sửa: cả 6 đúng.

| Việc | Đã làm |
|---|---|
| R1-1 | Hàm giúp `_th05_draft_line` (đủ `product_sku`, `product_name`, `unit_code`, `unit_name`, `applied_unit_price_minor`, `line_total_minor`; giá cố định 100.000, không đọc catalog); C03/C18/C19 đọc `draft_id`, `version` (bỏ `coalesce`) |
| R1-2 | Hàm giúp `_th05_cancel` đọc version đơn + settlement mới nhất, truyền `expected_order_version` / `expected_settlement_version`; C10, C11, C12 dùng. C11 thiếu `PAYMENT_ALREADY_COLLECTED` ⇒ `raise exception` |
| R1-3 | C12 kỳ vọng `CANCELLATION_BLOCKED` **và** `RETURN_EXCHANGE_CONFLICT` trong message |
| R1-4 | `start_return_exchange` của C14/C15 truyền `reference_decision.exchange_prices_by_product_unit_id` (P2 = 150.000); C15 kiểm thêm câu `Payment due date cannot be before today` |
| R1-5 | C13: phiếu 1 → `evaluate` → `confirm` (không truyền `payment_settled_now_minor`, phần hoàn do kế hoạch tất toán quyết định) rồi mới `start` phiếu 2 → `RETURN_QUANTITY_EXCEEDED` |
| R1-6a | C17 và C19 chỉ chấp nhận `Đơn vị đã được dùng trong giao dịch` |
| R1-6b | Impact `_classifyResult` (index hiện tại, upstream): **CRITICAL** — 7 symbol, 2 trực tiếp, 20 module, 86 luồng. Dòng "LOW" ở bảng impact phía trên là số cũ, giữ nguyên. Nhận định: luồng liệt kê phần lớn không liên quan; thay đổi chỉ thêm 2 nhánh `switch` ở nhánh `blocked`, không đổi hành vi caller; 1195 test sales pass |

Còn đoán (chưa xác nhận bằng chạy): C13 `confirm_return_exchange` không truyền số tiền hoàn nên tin `remainder_refund` từ kế hoạch (`:1189`); `expected_version` của phiếu lấy từ kết quả `start` (C14 đã dùng cách này); `sales.sales_order_settlements` có cột `version` (R1 đã xác nhận qua `v_settlement.version`).

## 10. Review

<!-- Chỉ phiên review ghi. -->

### R1 — 2026-11-07 — **CHƯA ĐẠT**

Phần sửa server (G1–G5) và app (G7) **đúng thiết kế**. Chưa đạt vì `sales_th05.sql` sẽ dừng ngay ở C03 khi người dùng chạy (một khối `do`, lỗi đầu tiên là dừng cả tệp), và có 3 ca khác cũng hỏng vì gọi RPC sai. Mục tiêu 5 ("có test phủ 9.3") chưa đạt.

| Hạng mục | Kết quả |
|---|---|
| G1 `CUSTOMER_INVALID` (precheck + finalize, `blocked`) | ✅ Khách lẻ bỏ qua; dùng `pp.partner_id` đúng cột thật |
| G2 `RECEIVABLE_DUE_DATE_INVALID` (precheck, finalize, confirm đổi/trả) | ✅ chỉ kiểm khi còn nợ |
| G3 lưu ngày hẹn đổi hàng | ✅ `confirm_return_exchange.payment_due_date`, nhánh `else` giữ cột |
| G4 tìm không dấu | ✅ `unaccent_immutable` + `ilike` ở cả 3 vế và `v_search` |
| G5 KI-08 | ✅ `plpgsql`, đọc 3 bảng, nháp chỉ `active`; giữ `revoke`/`grant` |
| G7 app | ✅ 2 nhánh, câu đúng mục 4 |
| Tài liệu TH-05 / TH-02 / PLAN | ✅ |
| `sales_th05.sql` | ❌ R1-1 … R1-5 |
| Bảng impact trong Kết quả | ⚠️ R1-6 |

**Review Focus (mục 6):**
1. Giờ VN: cả 3 hàm dùng `(now() at time zone 'Asia/Ho_Chi_Minh')::date`, không có `current_date` — ✅.
2. Replay idempotency: `_begin_sales_idempotency` → `replay` trả kết quả cũ trước khối `begin` chứa kiểm khách (`20261031017:131-133` < khối khách) — ✅.
3. Khách lẻ: điều kiện mở đầu `p_customer_id is not null` ở cả 2 hàm — ✅.
4. `#variable_conflict use_column`: `set payment_due_date = case … confirm_return_exchange.payment_due_date else payment_due_date end` — vế `else` là cột, đúng ý; câu `if payment_due_date < …` là biểu thức plpgsql (không có cột trong phạm vi) ⇒ là tham số, như kiểm `is null` có sẵn — ✅.
5. Giữ `ilike` — ✅.

**Số liệu kiểm lại:** `sales_checkout_cubit_test.dart` 29/29 ✅; `flutter test test/features/sales` 1195 pass ✅ (khớp); `dart analyze lib/features/sales test/features/sales` 9 info `deprecated_member_use`, 0 lỗi / cảnh báo ✅. Đoán trong Kết quả: #1 (`returnExchangeId`/`version` ở top-level — đúng, `_get_return_exchange_context -> 'draft'`), #2 (`IDEMPOTENCY_CONFLICT` được ném trước khối `begin` — đúng), #7 (`items` — đúng); #1 phần nháp, #3, #5 sai — xem dưới.

### R1 — việc cần sửa

Chỉ sửa `supabase/tests/sales_th05.sql` (trừ R1-6). Không chạy SQL — người dùng chạy lại ở 7.2.

- [ ] **R1-1 Nháp (C03, C18, C19) — tệp dừng ở C03.** `sales._write_draft_lines` (`20260830007_sales_draft_rpcs.sql:86-98`) bắt buộc mỗi dòng có `product_sku`, `product_name`, `unit_code`, `unit_name`, `applied_unit_price_minor`, `line_total_minor`; test chỉ gửi `product_id`, `product_unit_id`, `quantity_micros` ⇒ `CONTEXT_INVALID`. Kết quả trả khoá **`draft_id`** (`_draft_payload` `:45`), không phải `draftId`/`id` ⇒ `v_draft_id` luôn null. Sửa: thêm đủ 6 trường (giá = giá server của đơn vị đó; `unit_code` lấy từ `catalog.product_units`); đọc `(v_draft ->> 'draft_id')::uuid`, `(v_draft ->> 'version')::int` (bỏ `coalesce`).
- [ ] **R1-2 Huỷ đơn (C10, C11, C12) luôn `FIELD_NOT_ALLOWED`.** `confirm_sales_order_cancellation` bắt buộc `expected_order_version` và `expected_settlement_version` khác null, > 0 (`20260904001:394-406`), sau đó so với version thật (`:446`). Test không truyền ⇒ C10 ném lỗi, cả tệp dừng. Truyền `expected_order_version` (từ `sales.sales_orders.version`) và `expected_settlement_version` (từ `sales.sales_order_settlements.version`, bản mới nhất) ở cả 3 ca. C11: `PAYMENT_ALREADY_COLLECTED` nằm chắc chắn ở `details.reason` (`:479`) ⇒ đổi `raise notice` thành `raise exception 'FAIL: …'`.
- [ ] **R1-3 C12 sai mã kỳ vọng.** Server ném `code = 'CANCELLATION_BLOCKED'`, `details.reason = 'RETURN_EXCHANGE_CONFLICT'` (`:507`); `_th05_expect_err(…, 'RETURN_EXCHANGE_CONFLICT')` không bao giờ khớp. Kỳ vọng `CANCELLATION_BLOCKED` **và** `sqlerrm like '%RETURN_EXCHANGE_CONFLICT%'` (khối `begin … exception` như C11).
- [ ] **R1-4 Đổi hàng (C14, C15) hỏng ở `start_return_exchange`.** Dòng `exchangeLine` lấy giá app từ `reference_decision -> 'exchange_prices_by_product_unit_id' -> <product_unit_id> ->> 'amountMinor'` rồi `_assert_exchange_price` so với giá server (`20260830012:933-938`); không gửi ⇒ `null ≠ 150000` ⇒ `PRICE_CHANGED`. Truyền `reference_decision => jsonb_build_object('exchange_prices_by_product_unit_id', jsonb_build_object(v_u2::text, jsonb_build_object('amountMinor', 150000)))`. Thêm cho C15: ngoài mã `RETURN_EXCHANGE_BLOCKED` (dùng chung cho ~15 chỗ chặn) kiểm `sqlerrm like '%Payment due date cannot be before today%'`, để ca không xanh nhờ một chỗ chặn khác.
- [ ] **R1-5 C13 không ném lỗi.** Kiểm số lượng ở `start_return_exchange` chỉ cộng phiếu `confirmed`/`processing`/`completed` (`20260830012:816`) — phiếu `draft` không giữ số lượng (đúng như Kết quả đoán #3). Sửa test: phiếu 1 trả 2 → `evaluate_return_exchange_valuation` → `confirm_return_exchange` (hoàn tiền; đọc thân hàm để truyền đúng tham số phần hoàn), rồi mới `start` phiếu 2 → `RETURN_QUANTITY_EXCEEDED`.
- [ ] **R1-6 C17 xanh giả + bảng impact.** (a) `v_u1_conv` có khung giá (cần để bán) nên dù hàm KI-08 hỏng, xoá vẫn bị chặn với câu "Đơn vị đã có khung giá bán…", và mọi câu chặn đều mở đầu `product_conversion_unit_delete_blocked` ⇒ ca vẫn xanh. C17 và C19: chỉ chấp nhận `'%Đơn vị đã được dùng trong giao dịch%'`, bỏ vế `product_conversion_unit_delete_blocked`. (b) Mục 9 ghi `_classifyResult` LOW (0 luồng); chạy lại `impact _classifyResult --direction upstream` (index hiện tại) ra **CRITICAL**: 7 symbol, 2 trực tiếp, 86 luồng — luồng liệt kê phần lớn không liên quan (`pricing_form_page.build`, `Bj09ResetDraft`…), thay đổi chỉ thêm 2 nhánh `switch` nên không đổi hành vi caller. Ghi lại đúng số này vào mục 9 kèm nhận định, không xoá dòng cũ.

**Ghi nhận (không bắt sửa, chờ người dùng):** G5 tính mọi dòng `return_exchange_lines`, kể cả phiếu đổi/trả `draft` / `cancelled` — đơn vị chỉ nằm trong phiếu đã huỷ cũng không xoá được, khác cách xử lý nháp đơn bán (Q4). Đơn vị đó luôn đã nằm trong dòng đơn bán gốc (dòng trả), riêng dòng **đổi** của phiếu huỷ thì không ⇒ chỉ lệch ở ca hiếm. **Người dùng chốt 2026-11-07: giữ nguyên (A)** — chặn thừa an toàn, đã có "Tắt đơn vị".

### R2 — 2026-11-07 — **ĐẠT**

Phiên code chỉ sửa `supabase/tests/sales_th05.sql` và mục 9. Migration và app giữ nguyên so với R1 (diff 7 tệp, +116 / −10, không đổi).

| Việc R1 | Kết quả |
|---|---|
| R1-1 | ✅ `_th05_draft_line` đủ 6 trường `_write_draft_lines` bắt buộc; C03/C18/C19 đọc `draft_id`, `version` |
| R1-2 | ✅ `_th05_cancel` đọc version đơn + settlement mới nhất, truyền cả 2; C11 thiếu `PAYMENT_ALREADY_COLLECTED` ⇒ FAIL |
| R1-3 | ✅ C12 kỳ vọng `CANCELLATION_BLOCKED` + `RETURN_EXCHANGE_CONFLICT` |
| R1-4 | ✅ `reference_decision.exchange_prices_by_product_unit_id` (P2 = 150.000); C15 kiểm câu ngày hẹn |
| R1-5 | ✅ C13 xác nhận phiếu 1 rồi mới mở phiếu 2. Đã soi: `evaluate_return_exchange_valuation` không tăng version phiếu (chỉ ghi `source_session_version`, `20260830013:287`) ⇒ `expected_version` lấy từ `start` đúng; phần hoàn do `confirm` tự gọi `settle_return_exchange_difference` (`20260904001:1189-1210`, method mặc định `cash`) |
| R1-6a | ✅ C17/C19 chỉ chấp nhận câu "Đơn vị đã được dùng trong giao dịch" |
| R1-6b | ✅ Mục 9 ghi CRITICAL 7 / 2 / 86 kèm nhận định; chạy lại khớp số |

C18 xoá được vì `add_product_conversion_unit` không tự tạo khung giá (`20260710004`, chỉ insert `product_units` + lịch sử) — chỉ `v_u1_conv` có khung giá.

**Còn lại là việc của người dùng (7.2):** chạy `sales_th05.sql` trên DB local sau reset. Kết luận ĐẠT dựa trên đọc đối chiếu; chưa có lần chạy SQL nào. Ca FAIL ⇒ mở R3.
