# ADR-9: Hàng đổi-vào (exchanged-in) là đối tượng có thể trả/đổi tiếp

- **Trạng thái:** Accepted
- **Ngày:** 2026-08-19
- **Phạm vi:** TH-05 Sales Orders / EP-06 Đổi trả & quyết toán
- **Liên quan:** BR-07, RI-09, RI-10, ReturnableOrderLineView (Theme-5-sales-orders.md); các RPC `precheck_return_exchange`, `get_returnable_order_lines`, `evaluate_return_exchange_valuation`, `confirm_return_exchange`.

## Bối cảnh

Mô hình returnable ban đầu của TH-05 định nghĩa: **returnable quantity tính theo từng `SalesOrderLine` gốc**, và **return line bắt buộc tham chiếu một `SalesOrderLine` gốc** (BR-07, RI-09, RI-10).

Hệ quả: khi khách đổi sản phẩm A → B, dòng gốc A bị trả hết, còn hàng-đổi-vào B **chỉ tồn tại dưới dạng `exchange` line** của phiếu đổi/trả, **không phải** `SalesOrderLine`. Vì thế B **không nằm trong rổ returnable** — khách không thể trả/đổi tiếp B. Hệ thống báo "No returnable quantity remains on this sales order", và đây là hành vi **đúng theo spec cũ**.

Yêu cầu nghiệp vụ mới: khách phải được **trả hoặc đổi tiếp hàng-đổi-vào** như bất kỳ hàng nào đang giữ.

## Quyết định

Mở rộng khái niệm "đơn vị có thể trả" (returnable unit) thành: **một `SalesOrderLine` gốc HOẶC một `exchange` line đã confirmed** của chính đơn đó.

1. **Đệ quy đầy đủ.** Mọi hàng-đổi-vào (B, C, D…) đều là returnable unit hạng nhất. Đổi B→C sinh `exchange` line C, và C lại vào rổ returnable. Không giới hạn số tầng.

2. **Định giá khi trả hàng-đổi-vào.** Khi một `returned` line tham chiếu một `exchange` line, "giá gốc" của nó = **giá lúc hàng đó được đổi-vào đơn** (`unit_value_minor` trên `exchange` line). Nhất quán với quy tắc "returned line dùng original pricing".

3. **Đơn gốc bất biến — KHÔNG mutate.** Không thêm dòng vào `sales_orders`/`sales_order_lines`, không sửa `sales_context_snapshot`. Điều này giữ nguyên nguyên tắc nền tảng của TH-05 (đơn gốc + snapshot là bản ghi audit bất biến; §Nguyên tắc, RI-13). Hàng-đổi-vào đã là bản ghi authoritative (`return_exchange_lines`), nên dùng chính nó làm đích tham chiếu returnable.

4. **Hiển thị qua read model, không ghi ngược.** "Hàng khách đang giữ" (để hiển thị trong Chi tiết đơn) là một read model dẫn xuất = (dòng gốc − đã trả) + (đổi-vào − đổi-vào đã trả). Read model không ghi ngược vào authoritative aggregate (tuân thủ BR-04, dòng 1409).

## Các quy tắc bị sửa

| Quy tắc | Trước | Sau |
|---|---|---|
| BR-07 | Return line phải tham chiếu **SalesOrderLine gốc** | Return line phải tham chiếu **một returnable unit** (SalesOrderLine gốc **hoặc** exchange line đã confirmed), không vượt số còn có thể trả của unit đó |
| RI-09 | Returned line **bắt buộc** tham chiếu SalesOrderLine nguồn | Returned line bắt buộc tham chiếu **đúng một** nguồn: SalesOrderLine gốc **XOR** exchange line đã confirmed, thuộc đúng SalesOrder nguồn |
| RI-10 | Returned quantity ≤ remaining returnable của **original SalesOrderLine** | Returned quantity ≤ remaining returnable của **returnable unit** (gốc hoặc exchange line) |
| ReturnableOrderLineView | Tính số còn có thể trả của từng **SalesOrderLine** | Tính số còn có thể trả của từng **returnable unit** (gốc + exchange line đã confirmed) |

## Hệ quả

**Tích cực**
- Khách trả/đổi tiếp được hàng-đổi-vào, không giới hạn tầng.
- Không phá tính bất biến của đơn gốc/snapshot (khác với phương án "thêm dòng vào đơn").
- Dùng lại `return_exchange_lines` vốn đã authoritative — không cần khái niệm aggregate mới.

**Chi phí / cần lưu ý**
- Schema: `return_exchange_lines` thêm cột nguồn `source_exchange_line_id` (nullable) + ràng buộc "returned trỏ đúng một nguồn" + `unique (tenant_id, id)` làm đích FK.
- Rổ returnable (precheck + get_returnable_order_lines) phải union hai nguồn và trừ phần đã trả trỏ vào mỗi nguồn.
- Định giá (valuation) phải lấy giá theo exchange line khi returned line trỏ vào exchange line.
- Hợp đồng FE/Dart: returnable list nay có unit nguồn-exchange; tham số start phải mang loại nguồn.
- Vết loang cần rà khi triển khai: inventory impact của trả hàng-đổi-vào; quyết toán vòng sau (hoàn ≤ đã thu).
- **HĐĐT:** B không lên phiếu bán/HĐĐT gốc (giữ RI-13). Việc hoá đơn hoá hàng-đổi-vào thuộc **hóa đơn điều chỉnh/thay thế do Theme 8 sở hữu**; Theme 5 chỉ handoff + lưu reference/status projection, không tự tạo/sửa HĐĐT. Read model "hàng đang giữ" chỉ để hiển thị, không phải nguồn sinh chứng từ.

## Phương án đã cân nhắc và loại

- **Trục 1 — Thêm B thành `SalesOrderLine` mới + sửa snapshot.** Loại: vi phạm tính bất biến của đơn gốc và snapshot (§Nguyên tắc, RI-13), tạo thêm điểm đồng bộ giữa hai kho dòng đơn.
- **Trục 2 — Projection "dòng hiện tại" làm nguồn returnable.** Loại: read model không được làm đích tham chiếu authoritative cho return line (BR-04/dòng 1409); một mình projection không đủ để trả được B.
