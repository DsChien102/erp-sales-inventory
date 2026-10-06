# KB-005 — Chương trình chiết khấu theo kỳ được hiểu thế nào?

## Câu trả lời ngắn

Đây là một **thỏa thuận thương mại có điều kiện** với NCC. Theme Mua hàng quản lý điều khoản, theo dõi tiến độ thực tế, dự báo mức đạt và ước tính lợi ích; Kho chỉ cung cấp sự thật từng lần nhập và mô phỏng giá dự kiến từ đầu vào do Mua hàng cung cấp.

## Ba lớp phải tách

1. **Tiến độ đã xác nhận:** chỉ dữ liệu thực tế đủ điều kiện.
2. **Dự báo đến cuối kỳ:** actual + nguồn dự kiến + giả định.
3. **Quyền lợi thực tế:** chỉ sau khi đạt các mốc business/bằng chứng theo chương trình.

## Hai kiểu áp ngưỡng cần hỗ trợ ở model

Đề xuất v0.2.0 không chọn một công thức toàn hệ thống. Mỗi program version có thể ghi:

- **Toàn kỳ khi đạt:** sau khi đạt ngưỡng, benefit áp cho toàn bộ lượng đủ điều kiện của kỳ.
- **Phần vượt ngưỡng:** benefit chỉ áp cho lượng sau/vượt threshold.

Có thể thêm nhiều bậc. Đây vẫn là proposal cho Q-01, chưa frozen.

## Ví dụ 1.000 đơn vị / 20%

Nếu thực tế đủ điều kiện hiện là 600 và dự kiến còn 500, tiến độ thực tế là 600; kịch bản cuối kỳ là 1.100. Phần 500 **không được đưa vào tiến độ thực tế**. Benefit dự kiến phụ thuộc program rule; không thể chỉ nhìn “20% sau 1.000” rồi tự chọn công thức.

## Khi dự báo đổi

Tạo assessment version mới. Không sửa đè lịch sử, không tự sửa giá bán đã công bố, và không ghi dự báo vào công nợ hoặc giá trị kho.

Nguồn: D-05–D-08, D-17–D-20; Q-01/Q-02/Q-04/Q-08.
