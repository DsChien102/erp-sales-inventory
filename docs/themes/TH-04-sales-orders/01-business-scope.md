# TH-04 — Business scope

## Purpose

Lập và xử lý đơn bán hàng: nháp, xác nhận, thanh toán, tra cứu — đồng thời publish sự kiện tích hợp cho đối tác, kho và công nợ.

## Epic map (dự kiến)

| Epic | Mô tả |
| ---- | ----- |
| E4.1 Order capture | Tạo/sửa đơn, chọn KH & SP |
| E4.2 Checkout & payment | Thanh toán, hoàn tất đơn |
| E4.3 Order inquiry | Tra cứu, in phiếu |

## Cross-theme dependencies

- Master data: TH-02 (catalog), TH-03 (partner)
- Stock: TH-06 (inventory)
- Events: `sales.order.checked_out` → TH-03 transaction history (E2E blocked until publish)

**SRS:** chưa có. Module `sales` hiện là greenfield skeleton.
