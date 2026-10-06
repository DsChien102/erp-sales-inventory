# KB-001 — Mua hàng khác Kho, Công nợ và Kế toán ở đâu?

## Câu trả lời ngắn

Mua hàng sở hữu **cam kết và chứng từ thương mại với NCC**. Kho sở hữu **hàng thực tế và giá trị kho**. Công nợ sở hữu **nghĩa vụ/số dư phải trả và chi tiền**. Kế toán sở hữu **sổ và kỳ kế toán**.

## Vì sao quan trọng

Một giao dịch mua thường đi xuyên bốn miền. Nếu gộp chúng thành một “trạng thái mua hàng”, hệ thống dễ phát sinh ba lỗi: đặt mua làm tăng tồn sớm, nhận hàng làm phát sinh công nợ sai thời điểm, hoặc trả hàng khỏi kho làm giảm phải trả trước khi NCC chấp nhận.

## Quy tắc vận hành

1. Đơn mua chỉ mô tả **cam kết**.
2. Kho báo **sự thật nhận** theo từng lần.
3. Hóa đơn đủ điều kiện mới trở thành **nguồn nghĩa vụ**.
4. Công nợ nhận nguồn và duy trì balance.
5. Kế toán ghi sổ theo contract của miền Kế toán.
6. Mọi handoff có ID + version + source; gửi lại không tạo giao dịch trùng.

## Ví dụ

Đơn mua 100 hộp. Kho lần 1 nhận đạt 60, từ chối 5; lần 2 nhận 35. Mua hàng theo dõi rằng cam kết đã được xử lý đủ 100, nhưng không tự tạo các movement 60/35. Nếu hóa đơn 100 hộp đến giữa hai lần nhận, hóa đơn có thể ở trạng thái chờ đối chiếu; việc tải file không tự tăng phải trả.

## Điều cần ghi nhớ

**Commercial intent ≠ physical fact ≠ payable balance ≠ accounting entry.**

Nguồn quyết định: D-02, D-03, D-09, D-10.
