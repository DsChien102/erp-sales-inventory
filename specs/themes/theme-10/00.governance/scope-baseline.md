# Scope Baseline — Theme 10 Mua hàng

## 1. Mục tiêu miền

Theme Mua hàng quản lý **cam kết và chứng từ thương mại với nhà cung cấp**, theo dõi việc thực hiện cam kết bằng dữ liệu thực tế từ Kho, xác lập nguồn nghĩa vụ hợp lệ cho Công nợ, điều phối phần thương mại của trả hàng và quản lý chương trình chiết khấu mua hàng theo kỳ.

## 2. Capability trong baseline

| Capability | Trạng thái |
|---|---|
| Lập, xác nhận, sửa có phiên bản, dừng/hủy đơn mua | IN SCOPE |
| Theo dõi giao hàng theo từng lần nhận và xử lý chênh lệch thương mại | IN SCOPE |
| Tiếp nhận, kiểm tra nghiệp vụ và xác lập hóa đơn NCC đủ điều kiện | IN SCOPE |
| Bàn giao nguồn nghĩa vụ phải trả sang Công nợ | IN SCOPE |
| Xử lý trả hàng NCC về mặt thương mại | IN SCOPE |
| Quản lý chương trình chiết khấu kỳ hiện tại/tương lai | IN SCOPE |
| Theo dõi tiến độ thực tế và dự báo mức đạt | IN SCOPE |
| Tính/phân bổ lợi ích thương mại dự kiến có nguồn | IN SCOPE |
| Mô phỏng giá nhập/giá vốn bình quân dự kiến | OUT — Kho/Giá vốn tiêu thụ đầu vào Theme 10 |
| Số dư phải trả, chi tiền, phân bổ/cấn trừ | OUT — Công nợ |
| Ghi sổ/kỳ kế toán | OUT — Kế toán |
| Tồn vật lý, LOT, trạng thái hàng, giá trị kho chính thức | OUT — Kho |
| Định giá bán/công bố giá bán | OUT — Định giá bán |
| Tìm nguồn cung, RFQ/đấu thầu, hợp đồng khung | FUTURE CANDIDATE |
| Tự động tái đặt hàng từ cảnh báo tồn | FUTURE CANDIDATE |

## 3. Điểm bắt đầu/kết thúc

Theme có nhiều hành trình độc lập, không ép thành một chuỗi duy nhất:

- Đơn mua bắt đầu từ nhu cầu mua đã xác định phạm vi hàng và kết thúc khi đơn có hiệu lực hoặc bị dừng/hủy có căn cứ.
- Theo dõi giao bắt đầu khi có giao hàng/kết quả nhận và kết thúc khi cam kết trên từng dòng được xử lý rõ.
- Hóa đơn bắt đầu khi NCC gửi chứng từ tính tiền và kết thúc khi đủ điều kiện/chờ/từ chối; nếu đủ mốc thì phát nguồn nghĩa vụ đúng một lần.
- Trả NCC bắt đầu khi có nhu cầu trả hàng đã nhận và kết thúc khi kết quả vật lý + thương mại được đối chiếu.
- Chương trình chiết khấu chạy xuyên kỳ, độc lập với việc một giao dịch cụ thể có Đơn mua hay không.

## 4. Negative scope bắt buộc

- Không tạo tồn chỉ vì có đơn mua hoặc hóa đơn.
- Không tạo Đơn mua giả cho luồng nhập nhanh.
- Không tạo sổ phải trả thứ hai trong Mua hàng.
- Không coi dự báo là quyền lợi thực tế.
- Không tự công bố giá bán từ giá dự kiến.
- Không tự giảm phải trả chỉ vì hàng đã rời kho.
