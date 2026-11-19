# T6-1b — Công nợ theo khách, thu theo khách, cấn trừ khi đổi/trả Implementation Plan

> Phase: Theme 6 · Trạng thái: Plan ✅ (duyệt 2026-11-18) | Làm ✅ (2026-11-19) | Review ✅ R1
> Tài liệu liên quan: PLAN mục Theme 6 (T6-1b), [TH-06](../../../02-yeu-cau/TH-06-cong-no.md) 2.2, 2.4, 3.3–3.5, 6.2–6.3, 7.1, 9.2; [T6-1a](T6-1a-chuyen-bang-tien-receivable.md)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. (Dự án này: **người dùng tự code**, Claude review.)

**Goal:** DB của TH-06 chạy đủ: đọc công nợ theo khách, thu một khoản chia vào nhiều đơn (cũ trước), cấn trừ khi đổi/trả (giảm nợ đơn này → cấn trừ → hoàn); kế hoạch tiền đổi/trả nằm ở bảng riêng.

**Architecture:** Hai migration. (1) Bảng mới + một hàm ghi tiền nội bộ duy nhất `receivable._post_money_transaction` + 4 RPC đọc + `record_customer_collection`. (2) Bảng kế hoạch tiền đổi/trả (chép từ `valuation_details`), viết lại định giá / xác nhận đổi/trả theo thứ tự mới và ghi cấn trừ, **xoá** `sales.settle_return_exchange_difference`, sửa RPC đọc TH-05 cho phương thức `offset`.

**Tech Stack:** PostgreSQL (Supabase local), plpgsql, `psql`.

**Spec:** TH-06 v1.0 + thiết kế duyệt trong chat 2026-11-18 (cách 2 "làm gọn", hai migration, 4 quyết định bên dưới).

## Global Constraints

- **Không sửa Dart.** App vỡ phần đổi/trả và màn giao dịch cho tới T6-2 — người dùng chấp nhận (2026-11-18, chỉ test khi xong cả theme).
- Không sửa migration cũ. Lệnh DB (`supabase db reset`, `psql`, `tools/db_check.sh`) **người dùng tự chạy local**, không chạy trên Dev.
- Mã phương thức thật trong DB / app: `cash`, `manualBankTransfer`, `offset` (spec ghi `manual_bank_transfer` là **sai**, sửa spec ở Task 3).
- Lỗi ném theo khuôn `sales`: `raise exception using message = jsonb_build_object('code', …, 'message', …)::text`.
- Hàm mới ở `receivable`: `security definer`, `set search_path = ''` (ghi tên đầy đủ, kể cả `auth.uid()`, `iam.*`, `sales.*`); RPC: `revoke all … from public, anon; grant execute … to authenticated`; hàm `_…` nội bộ: chỉ revoke, không grant.
- Quyền: `iam.has_permission` trả `true` cho mọi mã ngoài `tenant.*` / `iam.*` → **không cần danh mục quyền**, chỉ gọi đúng mã: đọc `receivable.view`; thu `receivable.collect` **và** `sales.payment.record`; cấn trừ nằm trong `sales.return_exchange.confirm`.
- Phạm vi cửa hàng: mọi đơn đọc / ghi phải qua `iam.can_access_store(tenant, store_id, actor)` (D2, BR-02).
- "Hôm nay" = `(now() at time zone 'Asia/Ho_Chi_Minh')::date` ở server (BR-31).
- "Cũ trước" = `order by so.completed_at, so.order_code` (D1).
- Khoá quyết toán luôn theo `id` tăng dần (`order by s.id for update`) ở mọi RPC ghi.

**Quyết định đã chốt trong chat (2026-11-18):**

1. `confirm_return_exchange.offset_target_order_ids` rỗng / không gửi = **không cấn trừ** (giảm nợ rồi hoàn).
2. `p_expected_outstanding_minor` so với **Σ còn nợ các đơn đã chọn** (BR-05), không phải tổng nợ cả khách (BR-06 sửa theo).
3. Trong `confirm`: ghi giao dịch tiền trước, điều chỉnh nghĩa vụ sau (như hiện nay).
4. Xoá hẳn `sales.settle_return_exchange_difference` (app và test không gọi; chỉ `confirm` gọi).

## Review Focus

1. **Thử lại sau khi đã ghi** — gọi `record_customer_collection` lần 2 cùng key sau khi lần 1 đã làm đổi công nợ phải trả kết quả cũ, **không** ra `RECEIVABLE_CHANGED`. Kiểm idempotency trước mọi kiểm số dư. Test: Task 1 ca A13.
2. **Đơn ở cửa hàng không truy cập được** — không có trong danh sách, tổng, công nợ khách, đề xuất cấn trừ; gửi id đơn đó vào thu / cấn trừ bị từ chối. Test: Task 1 ca A05, A12; Task 2 ca B09.
3. **Cursor khi trùng khoá** — hai khách cùng mức khẩn, cùng nợ, cùng tên không bị lặp / mất giữa hai trang. Test: Task 1 ca A04.
4. **Đơn nguồn còn nợ một phần + cấn trừ** — giảm nợ tính trên `outstanding` đơn nguồn trước; tổng hoàn (cả `offset`) không vượt `net_collected` đơn nguồn; bất biến 3.5 (5) giữ. Test: Task 2 ca B03, B04.
5. **Đơn nhận đổi giữa định giá và xác nhận** — đơn nhận vừa được thu (version khác) → `STALE_VERSION`, không ghi gì (kể cả hàng kho). Test: Task 2 ca B07.

---

## File Structure

| File | Hành động | Nội dung |
|---|---|---|
| `supabase/migrations/20261124001_receivable_customer_collections.sql` | tạo | Task 1 |
| `supabase/migrations/20261124002_receivable_return_offsets.sql` | tạo | Task 2 |
| `supabase/tests/receivable_th06.sql` | tạo | ca A (Task 1), ca B (Task 2) |
| `supabase/tests/*.sql` (có đổi/trả) | sửa nếu đỏ | chỉ ca khách được hưởng trên đơn còn nợ (thứ tự mới) |
| `supabase/migrations/REGISTRY.yaml` | sinh lại | Task 3 |
| `docs/02-yeu-cau/TH-06-cong-no.md`, `TH-05-…`, `TH-03-…`, `docs/refactor/PLAN.md` | sửa | Task 3 |

---

### Task 1: Migration 1 — bảng, ghi tiền nội bộ, đọc công nợ, thu theo khách

**Files:**
- Create: `supabase/migrations/20261124001_receivable_customer_collections.sql`
- Create: `supabase/tests/receivable_th06.sql` (phần A)

**Interfaces:**
- Consumes: `receivable.sales_order_settlements` / `sales_payment_transactions` (T6-1a), `sales._recompute_sales_settlement(p_tenant_id uuid, p_settlement_id uuid)`, `sales._emit_sales_settlement_changed(p_tenant_id, p_settlement_id, p_source_kind text, p_source_id text, p_source_command text)`, `sales.generate_sales_receipt(...)` (chữ ký ở `20261123001`), `catalog.unaccent_immutable(text)`.
- Produces (Task 2 dùng):
  - bảng `receivable.customer_collections`, `receivable.receivable_offsets`, `receivable.idempotency_records` (TH-06 3.3, đúng cột).
  - `receivable._begin_idempotency(p_tenant_id uuid, p_command_scope text, p_idempotency_key text, p_payload_hash text) returns jsonb` và `receivable._complete_idempotency(p_tenant_id uuid, p_command_scope text, p_idempotency_key text, p_status text, p_result_snapshot jsonb) returns void` — chép hành vi `sales._begin_sales_idempotency` / `_complete_sales_idempotency` (`20260830006` dòng 53, 133), đổi bảng.
  - `receivable._post_money_transaction(p_tenant_id uuid, p_settlement_id uuid, p_transaction_type text, p_amount_minor bigint, p_payment_method_code text, p_source_context text, p_source_type text, p_source_id uuid, p_actor_id uuid, p_external_reference text default null) returns uuid` — chèn 1 giao dịch (`direction` suy từ loại, `currency_code` lấy từ quyết toán, `status = 'confirmed'`, `occurred_at = now()`), gọi `_recompute_sales_settlement`, trả id giao dịch. **Không** kiểm số dư (người gọi kiểm).

- [ ] **Bước 1: Impact (CLAUDE.md).** GitNexus `impact({target, direction: "upstream"})` cho `_recompute_sales_settlement`, `generate_sales_receipt`. Không có trong chỉ mục SQL → ghi vào mục 7.

- [ ] **Bước 2: Viết test đỏ `receivable_th06.sql` phần A** theo khuôn `sales_th05.sql` (`begin; … rollback;`, hàm giúp `public._th06_*`, `raise exception 'FAIL: …'`, cuối `raise notice 'receivable_th06: OK'`). Dựng dữ liệu bằng hàm giúp chép từ `sales_th05.sql` (`_th05_customer`, `_th05_finalize`, `_th05_line`); chỉnh `completed_at` và `payment_due_date` bằng `update` khi `reset role` để có quá hạn (finalize không cho hẹn quá khứ). Dữ liệu chuẩn = ví dụ TH-06 2.3 + AC-06 US-01.1: Anh Tuấn (DH-001 4tr hẹn H−8, DH-002 10tr đã thu 2tr hẹn H−3, DH-003 6tr hẹn H+12), Trại Hưng Phát 2,5tr hẹn H, Chị Lan 6tr hẹn H+7; thêm một đơn Khách lẻ, một đơn đã huỷ, một đơn đã trả đủ của Chị Lan. Hàm giúp `public._th06_invariants(p_tenant uuid, p_label text)` kiểm 3.5 (0), (1), (2), (5) — gọi sau mỗi ca ghi.

```text
A01 list: summary = {totalOutstandingMinor 26.500.000, customerCount 3, overdueCustomerCount 1,
    overdueAmountMinor 12.000.000, maxOverdueDays 8}; thứ tự Anh Tuấn → Trại Hưng Phát → Chị Lan;
    dòng Anh Tuấn {outstandingMinor 18.000.000, openOrderCount 3, overdueOrderCount 2,
    overdueAmountMinor 12.000.000, maxOverdueDays 8}; Khách lẻ / đơn huỷ / đơn trả đủ không góp.
A02 p_filter 'overdue' → chỉ Anh Tuấn; summary giống hệt A01 (không theo lọc). p_search 'tuan' → Anh Tuấn; summary giống A01.
A03 Đến hạn hôm nay không quá hạn: Trại Hưng Phát maxOverdueDays 0 / overdueOrderCount 0.
A04 Cursor: p_page_size 1 đi 3 trang = đúng thứ tự A01, không lặp; thêm 2 khách giống hệt nhau (cùng nợ, cùng tên,
    không hẹn) → p_page_size 1 vẫn ra đủ 5 khách khác nhau.
A05 Đơn của Anh Tuấn ở cửa hàng thứ hai mà actor không truy cập được: không góp vào list / get / summary.
A06 get_customer_receivable(Anh Tuấn): openOrders theo DH-001, DH-002, DH-003, mỗi dòng có settlementVersion,
    overdueDays (8, 3, 0); Σ outstandingMinor = outstandingMinor đầu = get_customer_receivable_summary.
A07 record: Anh Tuấn, 10.000.000 cash, p_order_ids = cả 3, expected 18.000.000 → allocations
    [DH-001 4tr → 0, DH-002 6tr → 2tr]; 1 customer_collections (before 18tr, after 8tr);
    2 giao dịch collection source_context 'receivable_collection', source_type 'customer_collection',
    source_id = collectionId; DH-001 'paid', DH-002 'partially_paid'; payment_due_date 3 đơn không đổi;
    mỗi đơn có phiếu bán hàng phiên bản mới; outbox sales_payment_recorded.v1 có customerCollectionId.
A08 Chỉ chọn DH-003, sửa số 5.000.000 (expected 6tr) → chỉ DH-003 đổi; chọn DH-002+DH-003 thu đủ → cả hai 'paid'.
A09 Lỗi: amount 0 → AMOUNT_INVALID; p_order_ids '{}' → AMOUNT_INVALID; amount > Σ đơn chọn → OVERPAYMENT_NOT_ALLOWED;
    method 'offset' / 'abc' → PAYMENT_METHOD_INVALID; khách không có / khác tenant → NOT_FOUND;
    khách hết nợ → NO_OUTSTANDING. Mỗi ca: số dòng customer_collections không đổi.
A10 Đơn chọn đã hết nợ / thuộc khách khác → RECEIVABLE_CHANGED; expected lệch 1đ → RECEIVABLE_CHANGED, không ghi gì.
A11 Cùng key + cùng nội dung → cùng collectionId, vẫn 1 lần thu; cùng key khác số → IDEMPOTENCY_CONFLICT.
A12 p_order_ids chứa đơn ở cửa hàng không truy cập được → RECEIVABLE_CHANGED.
A13 Thu xong (công nợ đã đổi) gọi lại đúng key cũ → trả kết quả cũ, không RECEIVABLE_CHANGED.
A14 Khách ngừng hoạt động (partner is_active = false) vẫn list / get / record được (D3).
A15 history Anh Tuấn sau A07: dòng mới nhất kind 'customer_collection' amountMinor 10tr, allocations 2 phần tử;
    có dòng kind 'order_collection' cho 2tr thu lúc bán của DH-002; mới nhất trước; cursor 20.
```

- [ ] **Bước 3: Chạy cho đỏ** (người dùng): `psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/receivable_th06.sql` → lỗi `function receivable.list_customer_receivables … does not exist`.

- [ ] **Bước 4: Viết migration** theo `_migration.template.sql` (`Kind: feature`, `Intent: receivable_customer_collections`, `Context: TH-06 3.3/6.2`, `Depends on: 20261123001_receivable_move_money_tables`). Khối, theo thứ tự:

1. Ba bảng (TH-06 3.3; `idempotency_records` cùng cấu trúc `sales.idempotency_records`, `20260830005` dòng 31). FK `customer_collections.customer_partner_id → partner.partners(id)`; `receivable_offsets` FK sang `sales.return_exchange_orders`, `sales.sales_orders` ×2, `receivable.sales_payment_transactions` ×2; CHECK `source ≠ target`, `amount > 0`; unique (`tenant_id`, `return_exchange_order_id`, `target_sales_order_id`). `customer_collections` CHECK `amount_minor > 0`, `before − amount = after`, `payment_method_code in ('cash','manualBankTransfer')`. RLS bật, không policy.
2. `alter table receivable.sales_payment_transactions add constraint …_offset_source_check check (payment_method_code <> 'offset' or (source_context = 'return_exchange' and source_type = 'receivable_offset'))`.
3. Ba index TH-06 3.4.
4. Hàm nội bộ (mục Interfaces).
5. RPC đọc:

| RPC | Chữ ký | Ra |
|---|---|---|
| `receivable.list_customer_receivables` | `(p_tenant_id uuid, p_actor_id uuid, p_filter text default 'all', p_search text default null, p_cursor text default null, p_page_size int default 50) returns jsonb` | `{summary, items, nextCursor}` — khoá như TH-06 6.2, thêm `nextDueDate` (date, null khi không hẹn) |
| `receivable.get_customer_receivable` | `(p_tenant_id uuid, p_actor_id uuid, p_customer_partner_id uuid) returns jsonb` | `{customer {customerId, displayName, phone, isActive}, outstandingMinor, openOrderCount, overdueOrderCount, maxOverdueDays, openOrders [{salesOrderId, orderCode, completedAt, payableMinor, outstandingMinor, dueDate, overdueDays, settlementVersion}]}` |
| `receivable.list_customer_receivable_history` | `(p_tenant_id uuid, p_actor_id uuid, p_customer_partner_id uuid, p_cursor text default null, p_page_size int default 20) returns jsonb` | `{items, nextCursor}`; mỗi item `{kind, occurredAt, amountMinor, paymentMethodCode, externalReference, actorId, salesOrderId, orderCode, allocations, sourceOrderCode, targetOrderCode, returnExchangeReference}` (trường không dùng = null) |
| `receivable.get_customer_receivable_summary` | `(p_tenant_id uuid, p_actor_id uuid, p_customer_partner_id uuid) returns jsonb` | `{outstandingMinor, openOrderCount, maxOverdueDays}` (khách không còn nợ → 0, 0, 0) |

   Khoá sắp xếp mức khẩn (BR-10), dùng cho cả `order by` và cursor (cursor = base64 của bộ khoá dòng cuối):

```text
bucket = 0 nếu maxOverdueDays > 0; 1 nếu nextDueDate = hôm nay; 2 nếu nextDueDate > hôm nay; 3 nếu không hẹn
k1     = −maxOverdueDays (bucket 0) | nextDueDate − hôm nay (bucket 2) | 0
order by bucket, k1, outstandingMinor desc, displayName, customerId
```

   `kind` của lịch sử: `customer_collection` (dòng `customer_collections`); `order_collection` (giao dịch `collection` có `source_context in ('checkout','additional_collection')`, phương thức ≠ `offset`); `offset` (dòng `receivable_offsets`, chỉ có dữ liệu sau Task 2); `refund` (giao dịch `refund`, `source_context = 'return_exchange'`, phương thức ≠ `offset`). Tìm: `catalog.unaccent_immutable(display_name / phone) ilike '%' || unaccent(p_search) || '%'` như `20260715001`.

6. `receivable.record_customer_collection(p_tenant_id uuid, p_actor_id uuid, p_customer_partner_id uuid, p_amount_minor bigint, p_payment_method_code text, p_external_reference text, p_order_ids uuid[], p_expected_outstanding_minor bigint, p_idempotency_key text) returns jsonb` → `{collectionId, allocations [{salesOrderId, orderCode, amountMinor, outstandingAfterMinor}], outstandingAfterMinor}` (`outstandingAfterMinor` = công nợ cả khách sau thu). Thứ tự kiểm (bắt buộc, vì Review Focus 1):

```text
1. auth.uid() = p_actor_id và has_permission 'receivable.collect' và 'sales.payment.record'  → PERMISSION_DENIED
2. khách có trong tenant                                                                    → NOT_FOUND
3. phương thức ∈ (cash, manualBankTransfer)                                                 → PAYMENT_METHOD_INVALID
4. amount > 0 và p_order_ids có ≥ 1 phần tử                                                 → AMOUNT_INVALID
5. payload_hash = md5(jsonb các tham số trừ key); _begin_idempotency scope 'customer_collection'
   replay → trả snapshot; in_progress → IDEMPOTENCY_CONFLICT
6. khoá quyết toán mọi đơn còn nợ của khách (truy cập được), order by s.id for update
7. không còn đơn nào                                                                         → NO_OUTSTANDING
8. p_order_ids ⊄ đơn còn nợ ở bước 6, hoặc Σ outstanding đơn chọn ≠ p_expected               → RECEIVABLE_CHANGED
9. amount > Σ outstanding đơn chọn                                                           → OVERPAYMENT_NOT_ALLOWED
10. chia cũ trước; mỗi phần > 0: _post_money_transaction(collection, phương thức,
    'receivable_collection', 'customer_collection', collectionId); outbox sales_payment_recorded.v1
    (khoá như record_sales_payment + customerCollectionId); _emit_sales_settlement_changed(…,'payment', tx, 'record_customer_collection');
    sales.generate_sales_receipt cho đơn đó, key 'customer_collection:<collectionId>:<orderId>'
11. chèn customer_collections (id sinh ở bước 10 trước khi ghi giao dịch), _complete_idempotency
```

   Nếu `generate_sales_receipt` đòi store trong JWT / tham số mà không lấy được trong ngữ cảnh này, dừng lại báo Claude (đừng bỏ phiếu).

- [ ] **Bước 5: Chạy cho xanh** (người dùng): `supabase db reset` rồi `tools/db_check.sh` → `receivable_th06: OK` (phần A), mọi test cũ OK, `plpgsql_check` không lỗi mới.

- [ ] **Bước 6: Commit**

```bash
git add supabase/migrations/20261124001_receivable_customer_collections.sql supabase/tests/receivable_th06.sql
git commit -m "feat(receivable): T6-1b công nợ theo khách và thu theo khách"
```

---

### Task 2: Migration 2 — kế hoạch tiền đổi/trả, cấn trừ, đọc TH-05

**Files:**
- Create: `supabase/migrations/20261124002_receivable_return_offsets.sql`
- Modify: `supabase/tests/receivable_th06.sql` (phần B, thêm sau phần A)
- Modify nếu đỏ: test cũ có đổi/trả khách được hưởng trên đơn còn nợ

**Interfaces:**
- Consumes: mọi thứ Task 1 Produces; bản mới nhất của `evaluate_return_exchange_valuation`, `confirm_return_exchange`, `get_sales_order_payment_transactions`, `get_sales_order_payment_summary`, `generate_sales_receipt`, `get_sales_order_timeline` (ở `20261123001`) và `get_return_exchange_detail` (ở `20260830012` dòng 1500).
- Produces: `sales.confirm_return_exchange(...cũ..., offset_target_order_ids uuid[] default '{}'::uuid[])`; bảng `receivable.return_exchange_settlement_plans`; JSON `settlementPlan` thêm `offsetAmountMinor`, `offsetCandidates`.

- [ ] **Bước 1: Impact** cho `evaluate_return_exchange_valuation`, `confirm_return_exchange`, `settle_return_exchange_difference`, `get_return_exchange_detail`, 4 RPC đọc TH-05. Ghi kết quả vào mục 7.

- [ ] **Bước 2: Viết test đỏ phần B.** Dựng phiếu đổi/trả như `sales_th05.sql` C14 (`start_return_exchange` → `evaluate_return_exchange_valuation` → `confirm_return_exchange`). Gọi `_th06_invariants` + kiểm thêm 3.5 (3), (4), (6) sau mỗi ca.

```text
B01 (2.3 bước 2) DH-001 đã trả đủ, DH-002 nợ 2tr, DH-003 nợ 6tr; trả hàng DH-001 500.000:
    evaluate → settlementPlan {receivableReverseAmountMinor 0, offsetAmountMinor 500.000, refundAmountMinor 0,
    offsetCandidates [DH-002 offset 500.000, DH-003 offset 0] (cũ trước, có settlementVersion, dueDate, overdueDays)};
    dòng return_exchange_settlement_plans khớp; valuation_details không còn khoá settlement_plan.
B02 confirm với offset_target_order_ids = {DH-002, DH-003}: DH-001 có refund 500.000 'offset'
    source_type 'receivable_offset'; DH-002 có collection 500.000 'offset', còn nợ 1.500.000; DH-003 không đổi;
    1 receivable_offsets; outbox receivable_offset_recorded.v1 ở cả DH-001 và DH-002; DH-002 có phiếu mới;
    history Anh Tuấn có kind 'offset' sourceOrderCode DH-001 targetOrderCode DH-002.
B03 (2.3 bước 3 / SC-03) trả hàng 1.000.000 của DH-003 còn nợ 6tr → receivableReverse 1tr, offset 0, refund 0;
    sau confirm DH-003 còn nợ 5tr, không có giao dịch refund nào.
B04 (US-03.2 AC-02) nguồn đã trả đủ 4tr, trả 3tr, khách nợ DH-002 2tr → offset 2tr + refund 1tr cash;
    nguồn có 1 refund offset 2tr + 1 refund cash 1tr; net_collected nguồn = 1tr (≥ 0, ≤ current_payable).
B05 (US-03.1 AC-03) đơn 1tr đã thu 400k, trả 600k → reverse 600k, offset 0, refund 0; sau confirm còn nợ 0.
B06 confirm với offset_target_order_ids rỗng (và lần khác: không truyền) → refund cash toàn bộ còn_lại, không receivable_offsets.
B07 giữa evaluate và confirm, thu 1đ vào DH-002 (record_customer_collection) → confirm ra STALE_VERSION;
    phiếu vẫn 'draft', không giao dịch mới, không bút toán kho mới.
B08 offset_target_order_ids chứa đơn khách khác / đơn đã huỷ / chính đơn nguồn → OFFSET_TARGET_INVALID.
B09 đơn nhận ở cửa hàng không truy cập được: không có trong offsetCandidates; gửi id đó → OFFSET_TARGET_INVALID.
B10 Khách lẻ: offsetCandidates [] ; gửi id bất kỳ → OFFSET_TARGET_INVALID; confirm rỗng → hoàn như TH-05.
B11 confirm 2 lần cùng key → 1 phiếu, 1 receivable_offsets, không trùng giao dịch.
B12 get_return_exchange_detail sau B02: settlementPlan có processedRefundMinor = refund, remainder* = 0,
    offsetAmountMinor, offsetCandidates; phiếu draft: processed* = 0.
B13 get_sales_order_payment_transactions DH-002: item offset có counterpartSalesOrderId = DH-001, counterpartOrderCode;
    get_sales_order_payment_summary DH-002: collectedCash / collectedBank không gồm 500.000, collectedOffset = 500.000;
    generate_sales_receipt DH-002: khối đã trả theo phương thức có dòng offset 500.000;
    get_sales_order_timeline DH-002 có sự kiện receivable_offset_recorded.v1.
B14 to_regprocedure('sales.settle_return_exchange_difference(...)') is null.
```

- [ ] **Bước 3: Chạy cho đỏ** (người dùng) → `FAIL: B01 …` (thiếu `offsetAmountMinor`).

- [ ] **Bước 4: Viết migration** (`Kind: feature`, `Intent: receivable_return_offsets`, `Depends on: 20261124001_…`). Khối, theo thứ tự:

1. Bảng `receivable.return_exchange_settlement_plans` đúng TH-06 3.3 (CHECK cân số theo dấu `net`; unique `return_exchange_order_id`; FK `sales.return_exchange_orders`, `sales.sales_orders`). RLS bật, không policy.
2. Chép từ `sales.return_exchange_valuations.valuation_details -> 'settlement_plan'` (offset = 0, candidates `[]`, status = status định giá) → khối `do` kiểm số dòng = số định giá có `settlement_plan`, sai thì `raise exception 'T6-1b: chép kế hoạch lệch …'` → `update … set valuation_details = valuation_details - 'settlement_plan'`.
3. `create or replace` `evaluate_return_exchange_valuation` (từ bản `20261123001`): bỏ ghi `settlement_plan` vào `valuation_details`; upsert dòng kế hoạch; nhánh `net < 0` thay bằng:

```text
duoc_huong = |net|
giam_no    = min(duoc_huong, settlement.outstanding)          → receivable_reverse_amount_minor
con_lai    = duoc_huong − giam_no
ứng viên   = đơn completed khác đơn nguồn, cùng customer_partner_id (null → không có), outstanding > 0,
             can_access_store; cũ trước; offsetAmountMinor = chia cũ trước từ con_lai
offset     = Σ offsetAmountMinor;  refund = con_lai − offset
```

   JSON `settlementPlan`: giữ mọi khoá cũ (processed* = 0, pending* = 0, remainder* = collect / refund), thêm `offsetAmountMinor`, `offsetCandidates [{salesOrderId, orderCode, completedAt, outstandingMinor, offsetAmountMinor, dueDate, overdueDays, settlementVersion}]`. Giữ chặn "walk-in cannot use receivable reversal" như cũ (chỉ nổ khi `giam_no > 0`; Khách lẻ trả đủ 100% nên bình thường `giam_no = 0` và đi thẳng sang hoàn).
4. `drop function sales.confirm_return_exchange(text, uuid, uuid, uuid, text, text, text, text, integer, jsonb, bigint, text, date);` rồi tạo lại với thêm `offset_target_order_ids uuid[] default '{}'::uuid[]`, chép lại `revoke` / `grant` của bản gốc (`20260830014`). Thay đổi trong thân:
   - Đọc kế hoạch từ bảng (`for update`), không từ jsonb; giữ kiểm `source_order_version` / `source_settlement_version` / `source_session_version` / giá.
   - Trước khi đụng kho (đặt ngay sau kiểm version): kiểm đơn nhận — mảng trùng phần tử hoặc đơn ∉ (cùng khách, completed, ≠ nguồn, truy cập được) → `OFFSET_TARGET_INVALID`; khoá quyết toán đơn nhận `order by id for update`; đơn ∉ `offset_candidates` của kế hoạch, hoặc `version` ≠ `settlementVersion` ứng viên, hoặc `outstanding = 0` → `STALE_VERSION`.
   - Thay hai lời gọi `settle_return_exchange_difference`: thu (`net > 0`) = `_post_money_transaction(collection, payment_method, 'return_exchange', 'return_exchange_order', phiếu)`; với `net < 0`: chia `con_lai` cũ trước vào các đơn nhận đã chọn; mỗi phần X > 0: sinh `offset_id`, refund `offset` ở nguồn + collection `offset` ở đơn nhận (cả hai `source_type 'receivable_offset'`, `source_id offset_id`), chèn `receivable_offsets`, outbox `receivable_offset_recorded.v1` hai lần (`salesOrderId` = nguồn rồi = nhận; payload `offsetId, returnExchangeId, sourceSalesOrderId, targetSalesOrderId, amountMinor, correlationId`), `_emit_sales_settlement_changed` + `generate_sales_receipt` cho đơn nhận; sau đó hoàn cash/CK `con_lai − Σ X` nếu > 0.
   - Cập nhật kế hoạch `status = 'confirmed'`. Phần kho, trạng thái trả hàng, ngày hẹn, `_apply_settlement_obligation_adjustment` (sau tiền), outbox cũ giữ nguyên.
5. `drop function sales.settle_return_exchange_difference(text, uuid, uuid, text, uuid, uuid, bigint, text, text, text, text, text, text, text, bigint);`
6. `create or replace sales.get_return_exchange_detail` (từ `20260830012`): khối kế hoạch đọc từ bảng; `processed* = collect / refund` khi phiếu `completed`, ngược lại 0; `remainder* = amount − processed`; `pending* = 0`; thêm `offsetAmountMinor`, `offsetCandidates`.
7. RPC đọc TH-05 (từ `20261123001`): `get_sales_order_payment_transactions` thêm `counterpartSalesOrderId`, `counterpartOrderCode` (qua `receivable_offsets`, null nếu không phải offset), `customerCollectionId`; `get_sales_order_payment_summary` thêm `collectedOffset` (Σ collection `offset`) và `refundedOffset` (Σ refund `offset`); `generate_sales_receipt` thêm dòng phương thức `offset` vào khối đã trả theo phương thức; `get_sales_order_timeline` nếu lọc theo danh sách `event_type` thì thêm `receivable_offset_recorded.v1`.

- [ ] **Bước 5: Chạy cho xanh** (người dùng): `supabase db reset` + `tools/db_check.sh` → `receivable_th06: OK`; mọi test cũ OK. Test cũ nào đỏ **chỉ** vì ca khách được hưởng trên đơn còn nợ (thứ tự mới: giảm nợ trước hoàn) thì sửa kỳ vọng ca đó, ghi tên ca vào mục 7; đỏ vì lý do khác → dừng báo Claude.

- [ ] **Bước 6: Commit**

```bash
git add supabase/migrations/20261124002_receivable_return_offsets.sql supabase/tests/
git commit -m "feat(receivable): T6-1b cấn trừ khi đổi/trả, kế hoạch tiền tách khỏi định giá"
```

---

### Task 3: Registry, tài liệu, kiểm phạm vi

**Files:** `supabase/migrations/REGISTRY.yaml`, `docs/02-yeu-cau/TH-06-cong-no.md`, `docs/02-yeu-cau/TH-05-*.md`, `docs/02-yeu-cau/TH-03-*.md`, `docs/refactor/PLAN.md`

- [ ] **Bước 1:** `melos run migrate:seed-registry -- --write`; diff chỉ thêm / đổi chủ các ký hiệu của hai migration (và bỏ `settle_return_exchange_difference`).
- [ ] **Bước 2: Sửa TH-06:** 2.1 / BR-04 / 3.3 / 6.3 `manual_bank_transfer` → `manualBankTransfer`; 7.1 bỏ "thêm vào danh mục quyền" (ghi lý do `has_permission`); BR-06 so Σ đơn đã chọn (như BR-05); 6.2 tên tham số `offset_target_order_ids` (rỗng = không cấn trừ), dòng `settle_return_exchange_difference` → "đã xoá (T6-1b)"; 3.3 `offset_candidates` thêm `overdueDays`; 6.2 ghi khoá JSON thật của 4 RPC đọc (bảng Task 1 Bước 4).
- [ ] **Bước 3: Sửa TH-05 / TH-03 phần dữ liệu** theo TH-06 7.3 (dòng 2.2 / BR-49 / US-06.6 AC-02 / KI-08 / 1.5–8 của TH-05; 1.5 / 8 của TH-03), mỗi chỗ link về TH-06. Phần màn (SG-…, PT-07) để T6-2.
- [ ] **Bước 4:** GitNexus `detect_changes()` → chỉ các ký hiệu của hai migration.
- [ ] **Bước 5:** PLAN dòng T6-1b: Plan ✅, Làm ✅; commit `docs(refactor): T6-1b registry + sửa TH-06/TH-05/TH-03`.

---

## 5. Kiểm tra

- [ ] `supabase db reset` chạy hết migration
- [ ] `tools/db_check.sh`: mọi test OK (gồm `receivable_th06` A01–A15, B01–B14), `plpgsql_check` không lỗi mới
- [ ] Không còn `settlement_plan` trong `valuation_details` và không còn hàm `settle_return_exchange_difference`
- [ ] Không sửa Dart (`git diff --stat -- apps/` rỗng)

## 6. Rủi ro / lưu ý

- App vỡ phần đổi/trả (khoá lạ `offsetAmountMinor`) và màn giao dịch đơn (khoá lạ `counterpart…`) cho tới T6-2 — đã chấp nhận.
- `drop function confirm_return_exchange` làm mất `grant` → phải chép lại `grant execute … to authenticated` với chữ ký mới.
- `generate_sales_receipt` gọi lồng trong RPC khác: kiểm quyền / store của nó phải qua được với `auth.uid()` của người gọi (Task 1 Bước 4 có điểm dừng).
- Deploy Dev (khi người dùng tự làm): API *Exposed schemas* đã cần `receivable` từ T6-1a.

## 7. Review

### R1
- Ngày, phạm vi được review: 2026-11-19, working tree chưa commit (`20261124001_receivable_customer_collections.sql`, `20261124002_receivable_return_offsets.sql`, `supabase/tests/receivable_th06.sql`, REGISTRY, TH-03 / TH-05 / TH-06)
- Kết quả: ✅ đạt
- Kiểm:
  - `record_customer_collection`: thứ tự kiểm đúng plan (idempotency trước mọi kiểm số dư — A13), khoá quyết toán theo `id`, chia cũ trước trong các đơn đã chọn, phiếu bán hàng mới + `sales_payment_recorded.v1` có `customerCollectionId` cho từng đơn.
  - RPC đọc: tổng không theo lọc / tìm, khoá mức khẩn + cursor có tie-break `customerId`, phạm vi cửa hàng qua `_open_orders`.
  - Định giá: giảm nợ → cấn trừ → hoàn; liệt kê mọi đơn còn nợ (kể cả "Trừ 0"); `còn_lại` kẹp ở `net_collected` (BR-27).
  - `confirm_return_exchange`: kiểm đơn nhận (`OFFSET_TARGET_INVALID` / `STALE_VERSION`) **trước** khi đụng kho (B07); mỗi cấn trừ đủ 2 giao dịch + 1 `receivable_offsets` + sự kiện ở cả hai đơn + phiếu mới cho đơn nhận; tiền trước, điều chỉnh nghĩa vụ sau; `revoke` / `grant` chữ ký mới.
  - Kế hoạch cũ chép sang bảng có khối kiểm đếm rồi mới bỏ khỏi `valuation_details`; `settle_return_exchange_difference` đã xoá, không còn hàm nào đọc `settlement_plan`.
  - `generate_sales_receipt` / `get_sales_order_timeline` không cần sửa: phiếu gom theo phương thức (dòng `offset` tự có), timeline không lọc loại sự kiện.
  - `tools/db_check.sh` (người dùng chạy): migration lên đủ; `plpgsql_check` không lỗi mới (2 nợ đã biết); mọi test xanh gồm `receivable_th06: OK`, `receivable_t6_1a: OK`, `sales_th05: OK` (3 ⚠️ nợ đã biết: `catalog_th02`, `einvoice_th08`, `pricing_th04`). Không test cũ nào phải sửa kỳ vọng.
  - GitNexus `detect_changes --repo erp-sales-inventory`: rủi ro thấp, 0 luồng (không lập chỉ mục SQL).
- Góp ý (không chặn; T6-2 lưu ý 1–2):
  1. `get_return_exchange_detail`: `processedRefundMinor` / `processedCollectMinor` lấy từ kế hoạch, lệch tiền thật khi bỏ chọn cấn trừ hoặc ghi nợ một phần — T6-2 hiện tiền thật từ danh sách giao dịch.
  2. `payload_hash` của `confirm` do app tính: T6-2 phải đưa `offset_target_order_ids` vào hash.
  3. Phiếu nháp đã định giá trước migration giữ cách chia cũ (hoàn trước) tới khi định giá lại — chỉ dữ liệu local.
  4. Thu theo khách và xác nhận cấn trừ cùng lúc trên cùng đơn có thể deadlock (Postgres huỷ một lệnh, không sai số).
  5. Gửi đơn nhận khi `net ≥ 0` ra `STALE_VERSION` thay vì `OFFSET_TARGET_INVALID`.
  6. Lịch sử: dòng `customer_collection` chưa lọc theo cửa hàng truy cập được (app một cửa hàng).
