# Assumption Register — Theme 10 Mua hàng

| ID | Giả định | Căn cứ | Rủi ro | Mất hiệu lực khi |
|---|---|---|---|---|
| A-01 | “Giá cơ sở” tạm hiểu là giá vốn tham chiếu phục vụ định giá | v0.1.1 | Có thể lệch thuật ngữ miền Định giá bán | Q-07 được chốt khác |
| A-02 | Ví dụ 20% / ngưỡng xxx chỉ là ví dụ | v0.1.1 | Nếu coi là hằng số sẽ sai model | Không áp dụng — đây là guardrail |
| A-03 | Chương trình tương lai không mặc nhiên tính giao dịch kỳ hiện tại | v0.1.1 | Có thể cộng sai dữ liệu vào ngưỡng | Q-02/Q-04 khóa quy tắc hồi tố/hiệu lực |
| A-04 | Chưa có phương pháp thì không sinh “xác suất đạt” bằng % | v0.1.1 | Pseudo-precision, gây hiểu nhầm | Q-08 chốt model xác suất |
| A-05 | Một chứng từ thương mại cấp root thuộc đúng một NCC | Proposal v0.2.0 | Trường hợp marketplace/agent có thể khác | Business Owner xác nhận mô hình đa bên |
| A-06 | Tiền và thuế được lưu theo currency của chứng từ; baseline chưa khóa multi-currency policy | Proposal v0.2.0 | Không đủ để triển khai FX | Technical/Business scope khóa currency |
| A-07 | Aggregate/entity trong v0.2.0 là semantic model của BA, chưa phải transaction boundary vật lý cuối cùng | Quy tắc BA/SA | Dev có thể hiểu nhầm thành schema/API | SA phát hành architecture contracts |
