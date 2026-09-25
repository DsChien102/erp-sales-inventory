# Bảng 13 — `sales.return_exchange_lines`

> Trạng thái: ✅ Đã chốt (2026-09-23) — **giữ bảng; tính đúng `base_quantity_micros`; bỏ `pricing_snapshot`, `line_value_minor`, `line_note`, `updated_at`; dọn CHECK trùng + alter cũ**
> Nguyên tắc chung: [README.md](README.md) · Plan: [2026-09-23-sales-refactor-13-return-exchange-lines](../../plans/2026-09-23-sales-refactor-13-return-exchange-lines.md)

## 1. Bối cảnh

Dòng của phiếu đổi trả; `line_role` = `returned` (nguồn: đúng một trong dòng đơn gốc hoặc dòng đổi của phiếu trước — ADR-9) hoặc `exchange`. Ghi: `start_return_exchange` (insert), `update_return_exchange` (xoá hết rồi chèn lại) — `20260830012`. Đọc: định giá (`013`), xác nhận, chi tiết đơn, danh sách có thể trả, trạng thái trả hàng, hàm kiểm tra cân đối. `feature/theme8` không dùng.

Hai lỗi ghi nhận từ bảng 6:

- `base_quantity_micros` ghi bằng đúng `quantity_micros` (không nhân hệ số quy đổi). Dòng đổi vào không có hệ số trong snapshot (app chỉ gửi `productUnitId`, `unitCode`, `unitName`).
- `evaluate_return_exchange_valuation` đọc `pricing_snapshot ->> 'unit_price_minor'` trong khi nơi ghi dùng `unitPriceMinor` — chỉ là nhánh dự phòng không bao giờ chạy (`unit_value_minor` luôn có giá trị).

## 2. Quyết định

| # | Điểm | Quyết định |
|---|---|---|
| ① | Bảng | **Giữ** |
| ② | `base_quantity_micros` | **Tính đúng** = `quantity_micros × conversionRateToBase`, số nguyên (lẻ/vượt phạm vi → `INVALID_QUANTITY`, giống checkout). Hệ số lấy từ `product_unit_snapshot.conversionRateToBase` của dòng: dòng trả từ đơn gốc thừa hưởng snapshot dòng đơn (checkout đã ghi hệ số); dòng trả từ dòng đổi thừa hưởng snapshot dòng đổi; **dòng đổi vào**: server tra `catalog.product_units.conversion_rate_to_base` (cùng điều kiện sản phẩm/đơn vị đang bán như `finalize_sales_order`, không có → `PRODUCT_NOT_SELLABLE`) và ghi thêm `conversionRateToBase` vào snapshot. Không đổi Dart |
| ③ | `pricing_snapshot` | **Bỏ** cột + nhánh dự phòng trong `evaluate_return_exchange_valuation` (`unit_value_minor` là nguồn giá; tiền tệ theo phiếu) |
| ④ | `line_value_minor` (chỉ ghi, định giá tự tính từ `unit_value_minor`) | **Bỏ** (kèm CHECK `return_exchange_lines_value_nonneg`); thay bằng CHECK `return_exchange_lines_unit_value_nonneg (unit_value_minor >= 0)` để giữ mức bảo vệ cũ (số lượng > 0 nên hai điều kiện tương đương) |
| ⑤ | `line_note` (không ai ghi/đọc), `updated_at` (không bao giờ update) | **Bỏ cả 2** |
| ⑦ | (Bổ sung 2026-09-23) Dòng trả lấy `product_id`/`product_unit_id` **từ app**, còn đơn giá/snapshot/số lượng đối chiếu lấy **từ dòng nguồn**; `start`/`update`/`confirm` không kiểm tra khớp → gọi API với đơn vị khác sẽ tính sai tiền và số lượng | **Báo lỗi** trong `start`/`update`: dòng `returned` có `product_id` hoặc `product_unit_id` khác dòng nguồn (dòng đơn gốc hoặc dòng đổi nguồn) → `RETURN_EXCHANGE_BLOCKED` "Hàng trả phải cùng sản phẩm và đơn vị với dòng gốc." ERP hiện gửi đúng đơn vị nguồn → không ảnh hưởng |
| ⑥ | CHECK trùng `returned_source_xor` (yếu hơn `returned_single_source`); khối `DO` + alter của bảng ở cuối `005` đều trùng `create table` | **Giữ** `returned_single_source`, `base_qty_positive` trong `create table`; **xoá** `returned_source_xor` và toàn bộ alter/`DO` của bảng ở khối SCHEMA EVOLUTION |

Helper mới (đặt đầu `20260830012`):

- `sales._product_unit_conversion_rate(p_tenant_id uuid, p_product_id uuid, p_product_unit_id uuid) returns numeric` — tra Catalog như checkout.
- `sales._base_quantity_micros(p_quantity_micros bigint, p_conversion_rate numeric) returns bigint` — nhân + kiểm tra số nguyên/phạm vi.

Cột sau refactor: `id`, `tenant_id`, `return_exchange_order_id`, `source_sales_order_id`, `line_sequence`, `line_role`, `original_sales_order_line_id`, `source_exchange_line_id`, `product_id`, `product_unit_id`, `quantity_micros`, `base_quantity_micros`, `unit_value_minor`, `return_reason_code`, `return_condition_code`, `product_snapshot`, `product_unit_snapshot`, `created_at`.

Contract JSON không đổi (snapshot đơn vị dòng đổi vào dư thêm `conversionRateToBase` — mapper Dart đã cho phép key này).

## 3. Ghi nhận

- Dòng trả dùng hệ số của dòng nguồn — an toàn vì quyết định ⑦ ép dòng trả cùng đơn vị với dòng nguồn. Nếu sau này cho trả khác đơn vị thì phải bỏ ⑦ và tra hệ số theo `product_unit_id` của dòng trả, đồng thời so số lượng theo `base_quantity_micros`.
- `finalize_sales_order` vẫn tự tính hệ số (không đổi sang helper trong đợt này).

## 4. Phụ thuộc

Sau plan 12 (cùng sửa vòng lặp dòng trong `start`/`update`; plan 6 đã bỏ đoạn dự phòng snapshot trong `start`) — tìm theo nội dung.
