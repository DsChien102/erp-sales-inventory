# KB-T09-008 — Hóa đơn không đồng nghĩa doanh thu

## Trả lời ngắn
Hóa đơn điện tử là chứng từ authoritative của Theme 8, nhưng không nên tự động trở thành source duy nhất để quyết định doanh thu kế toán.

## Rủi ro nếu dùng invoice làm source duy nhất
- đơn hàng đã final nhưng invoice phát hành sau → revenue bị trễ giả;
- retry/phát hành lại có thể gây double count nếu identity không rõ;
- hóa đơn điều chỉnh/thay thế có lifecycle pháp lý riêng, không đồng nghĩa mutation trực tiếp của SalesOrder.

## Đề xuất
Recognition fact đến từ source transaction owner theo accounting policy. Invoice cung cấp evidence/tax facts và là input đối chiếu. Nếu hai nguồn lệch, mở reconciliation thay vì tự chọn một bên.
