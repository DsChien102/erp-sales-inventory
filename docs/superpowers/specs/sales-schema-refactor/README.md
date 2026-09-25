# Sales schema refactor — quyết định theo từng bảng

> Bắt đầu: 2026-09-22 · Nhánh thảo luận: `fix/theme5`
> Cách làm: review **từng bảng** trong schema `sales`: bảng có cần giữ không, nếu giữ thì từng cột có hợp lý không.
> Mỗi bảng chốt xong → một file quyết định trong thư mục này. Implement dựa trực tiếp vào các file này.
> Tham chiếu cách làm: `docs/superpowers/specs/iam-schema-refactor/` (nhánh `fix/theme1`).

## Nguyên tắc chung (áp dụng mọi bảng)

1. **Dữ liệu Sales hiện tại là dữ liệu dev**, bỏ được.
2. **Ưu tiên thay đổi nhỏ, ít động luồng chính.** Các thay đổi nghiệp vụ nặng (tính năng cửa hàng / mã đơn theo cửa hàng, phân quyền, Model B handoff sang Inventory/Receivable) để giai đoạn sau, không làm trong đợt này trừ khi file bảng ghi rõ.
3. **Giữ contract RPC**: không đổi tên hàm, tham số và các key JSON trả về, trừ khi file bảng ghi rõ. Cột bị gộp/bỏ thì key JSON cũ được **tính ra** từ cột mới để Dart/UI không phải sửa.
4. **Giữ các ADR TH-05 đã chốt**: tiền `bigint` minor, số lượng `bigint` micros; `net_difference = exchange − return`; một bảng `sales.idempotency_records`; outbox dùng `sales.outbox_messages` của platform.
5. **Đọc [01-domain-model.md](../../../themes/TH-05-sales-orders/harness/01-domain-model.md) trước khi chốt mỗi bảng**. Cột/bảng lệch domain model thì ghi rõ bên nào đúng.
6. **Sửa trực tiếp migration gốc, không dùng `_drafts/`**: user sẽ `supabase db reset`. Xem [Quy ước implement](#quy-ước-implement-sửa-trực-tiếp-migration-gốc).
7. **Trước khi đề xuất bỏ cột/bảng, quét cả nhánh `feature/theme8`** (hoá đơn điện tử TH-08 có draft ghi/đọc bảng Sales): `git grep -n "<cột>" feature/theme8 -- 'supabase/migrations' 'modules'`.
8. Trước khi sửa hàm: chạy GitNexus `impact` (CLAUDE.md). Sửa kèm các `*_sql_contract_test.dart` assert trên nội dung SQL bị đổi.

## Phạm vi

Toàn bộ bảng business của Sales nằm trong **một file** `supabase/migrations/20260830005_sales_rebuild_schema.sql`. RPC nằm ở `20260830006`–`20260830015` và `20260904001`.

Ngoài phạm vi review cột: `sales.outbox_messages` / inbox do `platform.install_module_messaging('sales')` tạo (hạ tầng dùng chung).

## Quy ước implement: sửa trực tiếp migration gốc

Reset chạy **toàn bộ** chuỗi migration trên DB rỗng → mọi câu lệnh được thực thi phải hợp lệ với schema mới.

| Loại | Quy tắc |
|---|---|
| Bảng / cột / index / constraint / policy / grant | Sửa tại câu lệnh **tạo ra** nó trong `20260830005`. Bỏ đối tượng → **xoá câu lệnh tạo** (không thêm `drop`) |
| Khối "SCHEMA EVOLUTION" cuối `20260830005` (`alter … add column if not exists`, `drop constraint if exists` + `add constraint`, khối `DO` kiểm `pg_constraint`) | Khi sửa bảng nào thì **gộp** phần alter của bảng đó vào `create table` và xoá khối alter tương ứng (chỉ phục vụ nâng cấp DB cũ; reset từ đầu không cần) |
| Câu lệnh chạy trực tiếp tham chiếu cột/bảng bị bỏ ở **bất kỳ** migration (backfill, khối `DO`, `create index`, `grant`/`revoke`, danh sách bảng bật RLS, hàm `language sql`) | Sửa/xoá tại chỗ: Postgres kiểm tra ngay khi reset dù bảng rỗng |
| Hàm `plpgsql` | Chỉ sửa **định nghĩa cuối cùng** (file owner trong `supabase/migrations/REGISTRY.yaml`). Bản cũ hơn bị ghi đè và câu SQL trong thân không bị kiểm tra lúc tạo → để nguyên. **Ngoại lệ:** phần `declare`/chữ ký **có** bị kiểm tra: bản cũ khai báo biến/tham số/kiểu trả về là bảng hoặc `%type` của cột bị bỏ thì phải đổi kiểu |
| Hàm bị bỏ | Xoá định nghĩa ở file owner + `grant`/`revoke` liên quan (xoá cả bản cũ nếu là `language sql`) |
| Đối tượng mới | Thêm vào migration **trước** chỗ đầu tiên cần nó (bắt buộc với hàm `language sql`, kiểu trả về `%rowtype`/bảng, FK) |
| Đổi chữ ký hàm | Ở file owner thêm `drop function if exists <chữ ký cũ>;` trước `create or replace`, cập nhật `grant`/`revoke` |
| Header migration | Thêm/bỏ bảng hoặc hàm → cập nhật `-- Touches:`; sau khi sửa chạy `dart run tools/vet45_supabase_migrate/bin/seed_registry.dart --write` và `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart --strict` |
| Không còn | File `_drafts/`, khối guard `pg_proc`, `drop column` / `drop table` bổ sung |

**Kiểm chứng mỗi plan:**
1. SQL contract test mới đọc **file migration** (hàm lấy định nghĩa **cuối** trong file).
2. `grep` toàn bộ `supabase/migrations/*.sql` không còn tham chiếu tới đối tượng đã bỏ (ngoài thân hàm plpgsql bản cũ).
3. Chạy lại các SQL contract test cũ bị ảnh hưởng (`cd modules/sales/infrastructure && dart test`); sửa assertion kiểm tra nội dung đã đổi. **Baseline fail sẵn (2026-09-22, trước refactor, 11 test):** không sửa trong refactor.
   - `(setUpAll)` do đọc `_drafts/` không còn: `sales_order/order_detail_current_lines_sql_contract_test.dart`, `sales_order/sales_inquiry_group_f_sql_contract_test.dart`, `sales_order/sales_read_group_e_sql_contract_test.dart`, `sales_order_draft/sales_order_draft_sql_contract_test.dart`, `sales_receipt/sales_receipt_group_e_sql_contract_test.dart`
   - `return_exchange_order/sales_return_exchange_group_i_settlement_sql_contract_test.dart`: *evaluate uses Theme 5 / ADR-2 sign and authoritative line/pricing sources*
   - `sales_order/sales_settlement_rebuild_sql_contract_test.dart`: *mutations recompute settlement and emit canonical fact + settlement_changed*
   - `schema/sales_remove_unused_policy_tables_sql_contract_test.dart`: 4 test (*confirmation keeps source…*, *duplicate bootstrap generations…*, *policy and context responses…*, *promoted baselines no longer create…*)
4. User chạy `supabase db reset` → toàn chuỗi chạy không lỗi → smoke test app (tạo nháp, thanh toán, thu thêm, huỷ đơn, đổi trả, in hoá đơn).

**Thứ tự thực hiện plan:** 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10 → 11 → 12 → 13 → 14 → 15 → 16 (plan sau giả định plan trước đã sửa nội dung file; các plan tìm vị trí sửa theo nội dung, không theo số dòng). Ràng buộc cứng: plan 10 sau plan 8; plan 10, 11, 12 sửa tiếp test của plan 1 (15 begin / 21 → 20 → 18 complete).

## Tiến độ

| # | Bảng | Trạng thái | File |
|---|---|---|---|
| 1 | `sales.idempotency_records` | ✅ Đã chốt · bỏ 6 cột, bỏ `uncertain`, xoá update thừa ở checkout · 📝 Plan: [2026-09-22-sales-refactor-01-idempotency-records](../../plans/2026-09-22-sales-refactor-01-idempotency-records.md) · 🧪 Đã sửa migration gốc, chờ reset | [01-idempotency-records.md](01-idempotency-records.md) |
| 2 | `sales.sales_order_number_counters` | ✅ Đã chốt · giữ khoá theo cửa hàng, bỏ `updated_at`, sửa comment · 📝 Plan: [2026-09-23-sales-refactor-02-sales-order-number-counters](../../plans/2026-09-23-sales-refactor-02-sales-order-number-counters.md) · 🧪 Đã sửa migration gốc, chờ reset | [02-sales-order-number-counters.md](02-sales-order-number-counters.md) |
| 3 | `sales.sales_order_drafts` | ✅ Đã chốt · bỏ 5 cột, tách `preview_snapshot` thành cột · 📝 Plan: [2026-09-23-sales-refactor-03-sales-order-drafts](../../plans/2026-09-23-sales-refactor-03-sales-order-drafts.md) · 🧪 Đã sửa migration gốc, chờ reset | [03-sales-order-drafts.md](03-sales-order-drafts.md) |
| 4 | `sales.sales_order_draft_lines` | ✅ Đã chốt · cột = dữ liệu nhập (+ `manual_discount_basis_points`), `pricing_preview` = hiển thị/giá, bỏ `updated_at` · 📝 Plan: [2026-09-23-sales-refactor-04-sales-order-draft-lines](../../plans/2026-09-23-sales-refactor-04-sales-order-draft-lines.md) · 🧪 Đã sửa migration gốc, chờ reset | [04-sales-order-draft-lines.md](04-sales-order-draft-lines.md) |
| 5 | `sales.sales_orders` | ✅ Đã chốt · bỏ 7 cột (giữ `buyer_tax_snapshot` cho hoá đơn điện tử), gộp alter cũ · dòng hàng trong snapshot → bảng 6 · 📝 Plan: [2026-09-23-sales-refactor-05-sales-orders](../../plans/2026-09-23-sales-refactor-05-sales-orders.md) · 🧪 Đã sửa migration gốc, chờ reset | [05-sales-orders.md](05-sales-orders.md) |
| 6 | `sales.sales_order_lines` | ✅ Đã chốt · bỏ `pricing_snapshot`, `tax_snapshot`; bảng là nguồn dòng hàng duy nhất (bỏ `lines` khỏi snapshot đơn) · 📝 Plan: [2026-09-23-sales-refactor-06-sales-order-lines](../../plans/2026-09-23-sales-refactor-06-sales-order-lines.md) · 🧪 Đã sửa migration gốc, chờ reset | [06-sales-order-lines.md](06-sales-order-lines.md) |
| 7 | `sales.sales_order_return_status_projections` | ✅ Đã chốt · bỏ `id`, 2 cột số lượng, `version`; kiểm tra cân đối theo trạng thái; sự kiện gửi tổng số lượng gốc · 📝 Plan: [2026-09-23-sales-refactor-07-sales-order-return-status-projections](../../plans/2026-09-23-sales-refactor-07-sales-order-return-status-projections.md) · 🧪 Đã sửa migration gốc, chờ reset | [07-sales-order-return-status-projections.md](07-sales-order-return-status-projections.md) |
| 8 | `sales.sales_order_settlements` | ✅ Đã chốt · bỏ `reconciliation_status`, `last_transaction_at`; giữ `settled_at` · 📝 Plan: [2026-09-23-sales-refactor-08-sales-order-settlements](../../plans/2026-09-23-sales-refactor-08-sales-order-settlements.md) · 🧪 Đã sửa migration gốc, chờ reset | [08-sales-order-settlements.md](08-sales-order-settlements.md) |
| 9 | `sales.settlement_obligation_adjustments` | ✅ Đã chốt · giữ nguyên cột; chuyển `create table` lên phần SETTLEMENT; thêm kiểm tra cân đối tổng · 📝 Plan: [2026-09-23-sales-refactor-09-settlement-obligation-adjustments](../../plans/2026-09-23-sales-refactor-09-settlement-obligation-adjustments.md) · 🧪 Đã sửa migration gốc, chờ reset | [09-settlement-obligation-adjustments.md](09-settlement-obligation-adjustments.md) |
| 10 | `sales.sales_payment_transactions` | ✅ Đã chốt · xoá void, bỏ 8 cột · 📝 Plan: [2026-09-23-sales-refactor-10-sales-payment-transactions](../../plans/2026-09-23-sales-refactor-10-sales-payment-transactions.md) · 🧪 Đã sửa migration gốc, chờ reset | [10-sales-payment-transactions.md](10-sales-payment-transactions.md) |
| 11 | `sales.sales_order_cancellations` | ✅ Đã chốt · FC-17 = unique theo đơn, bỏ 11 cột · 📝 Plan: [2026-09-23-sales-refactor-11-sales-order-cancellations](../../plans/2026-09-23-sales-refactor-11-sales-order-cancellations.md) · 🧪 Đã sửa migration gốc, chờ reset | [11-sales-order-cancellations.md](11-sales-order-cancellations.md) |
| 12 | `sales.return_exchange_orders` | ✅ Đã chốt · bỏ 7 cột, reason ghi qua tham số mới · 📝 Plan: [2026-09-23-sales-refactor-12-return-exchange-orders](../../plans/2026-09-23-sales-refactor-12-return-exchange-orders.md) · 🧪 Đã sửa migration gốc, chờ reset | [12-return-exchange-orders.md](12-return-exchange-orders.md) |
| 13 | `sales.return_exchange_lines` | ✅ Đã chốt · base_quantity tính đúng, bỏ 4 cột, dọn CHECK/alter · 📝 Plan: [2026-09-23-sales-refactor-13-return-exchange-lines](../../plans/2026-09-23-sales-refactor-13-return-exchange-lines.md) · 🧪 Đã sửa migration gốc, chờ reset | [13-return-exchange-lines.md](13-return-exchange-lines.md) |
| 14 | `sales.return_exchange_valuations` | ✅ Đã chốt · bỏ 5 cột chỉ-ghi, bỏ superseded · 📝 Plan: [2026-09-23-sales-refactor-14-return-exchange-valuations](../../plans/2026-09-23-sales-refactor-14-return-exchange-valuations.md) · 🧪 Đã sửa migration gốc, chờ reset | [14-return-exchange-valuations.md](14-return-exchange-valuations.md) |
| 15 | `sales.sales_receipts` | ✅ Đã chốt · bỏ 7 cột + FK/CHECK/index supersession · 📝 Plan: [2026-09-23-sales-refactor-15-sales-receipts](../../plans/2026-09-23-sales-refactor-15-sales-receipts.md) · 🧪 Đã sửa migration gốc, chờ reset | [15-sales-receipts.md](15-sales-receipts.md) |
| 16 | `sales.sales_receipt_activities` | ✅ Đã chốt · bỏ 5 cột, actor not null · 📝 Plan: [2026-09-23-sales-refactor-16-sales-receipt-activities](../../plans/2026-09-23-sales-refactor-16-sales-receipt-activities.md) · 🧪 Đã sửa migration gốc, chờ reset | [16-sales-receipt-activities.md](16-sales-receipt-activities.md) |

## Việc phát sinh (ngoài phạm vi cột)

| Việc | Nguồn | Trạng thái |
|---|---|---|
| Đồng bộ draft hoá đơn điện tử khi merge `feature/theme8`: `_drafts/017_sales_buyer_invoice_snapshot.sql` (bản sao đầy đủ `finalize_sales_order` → áp lại mọi thay đổi finalize: plan 1 gọi helper chống lặp mới + xoá update `idempotency_records` thừa; plan 2 bỏ `updated_at` bộ đếm; plan 3 chuyển nháp `converted` không còn `converted_at`; plan 5 insert bỏ `business_time`, `customer_snapshot`, `pricing_summary_snapshot`; plan 6 bỏ `v_normalized_lines` + key `lines` khỏi snapshot và `pricing_snapshot` khỏi insert `sales_order_lines`; plan 8 bỏ `reconciliation_status`, `last_transaction_at` khỏi insert `sales_order_settlements`; plan 10 bỏ `transaction_code`, `confirmed_by_user_id`, `idempotency_key`, `confirmed_at` khỏi insert `sales_payment_transactions` (vòng lặp thanh toán không cần `ordinality`); giữ ghi `buyer_tax_snapshot`) và `_drafts/018_sales_einvoice_source_contract.sql` (`customer_snapshot` → `sales_context_snapshot -> 'customer'`) | [05-sales-orders.md §4](05-sales-orders.md#4-phụ-thuộc) | ⏳ Làm lúc merge theme8 |
| Xoá luồng hoàn tất hai bước: `complete_return_exchange` (SQL `014`) + command/handler/validator/gateway Dart + `completeIfReady` và nút "Hoàn tất phiếu" ở màn kết quả đổi trả ERP + test liên quan | [12-return-exchange-orders.md §2](12-return-exchange-orders.md#2-quyết-định) | ⏸ Làm riêng sau đợt refactor (đụng presentation) |
| Ô nhập "Ghi chú / lý do đổi trả" trên màn đổi trả: gửi `reason` qua command/gateway Dart (SQL đã nhận tham số `reason` từ plan 12) + hiển thị lại ở chi tiết | [12-return-exchange-orders.md §2](12-return-exchange-orders.md#2-quyết-định) | ⏸ Chờ thiết kế màn hình |
| Trùng mã đơn khi tổ chức có ≥ 2 cửa hàng (bộ đếm theo cửa hàng, mã đơn unique theo tổ chức) | [02-sales-order-number-counters.md §3](02-sales-order-number-counters.md#3-ghi-nhận-không-sửa) · quyết định 2026-09-08 | ⏸ Known issue, làm cùng tính năng cửa hàng |
| IAM refactor bảng 6 (xoá `membership_store_scopes` → `iam.can_access_store`) có sửa helper Sales, nằm ở nhánh `fix/theme1`, chưa có trên `fix/theme5` | IAM README bảng 6 | ⚠️ Cần merge/rebase trước khi implement plan Sales đụng tới helper quyền cửa hàng |
