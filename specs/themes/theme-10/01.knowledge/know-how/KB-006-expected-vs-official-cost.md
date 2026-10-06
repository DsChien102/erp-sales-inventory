# KB-006 — Giá dự kiến khác giá nhập/giá vốn chính thức thế nào?

## Câu trả lời ngắn

**Giá dự kiến** là một phép mô phỏng để ra quyết định sớm. **Giá chính thức** đi theo giao dịch và bằng chứng thực tế.

## Chuỗi dữ liệu đề xuất

`Theme Mua hàng: benefit dự kiến đã phân bổ → Kho/Giá vốn: mô phỏng giá nhập + bình quân dự kiến → Định giá bán: cân nhắc giá cơ sở → người có quyền công bố giá bán`

Không bước nào trong chuỗi trên tự thay thế giá trị kho hoặc giá vốn đã ghi nhận.

## Ví dụ

Đang có 100 đơn vị với giá trị bình quân 100.000đ. Dự kiến nhận thêm 100 đơn vị với giá sau phân bổ benefit là 80.000đ và giả định không có biến động khác, bình quân kịch bản là 90.000đ. Đây chỉ là mô phỏng. Nếu thực tế có xuất hàng xen giữa, chi phí đến muộn hoặc benefit không đạt, kết quả chính thức sẽ khác.

## Guardrail

- Mọi expected result có `scenario/version/as_of`.
- Không gọi expected cost là “giá vốn mới”.
- Khi dự báo bị hạ, hệ thống cần tạo nhu cầu rà soát tham chiếu; không viết lại giao dịch cũ.
- Miền Định giá bán mới có quyền quyết định reference nào được dùng và thời điểm công bố.

Nguồn: D-07, D-08, D-20; A-01; Q-07/Q-08.
