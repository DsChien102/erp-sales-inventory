# KB-002 — Đơn mua và theo dõi giao hàng vận hành thế nào?

## Câu trả lời ngắn

Đơn mua là nguồn cho biết NCC **được yêu cầu giao gì**. Kho cho biết **đã nhận gì**. Theme Mua hàng ghép hai sự thật đó để quản lý phần còn phải giao và quyết định chênh lệch.

## Các khái niệm cần phân biệt

- **Lượng đặt mua:** nằm trên phiên bản đơn.
- **Lượng thực nhận:** đến từ Kho.
- **Lượng còn được phép nhận:** giới hạn theo phiên bản đơn hiện hành và các kết quả đã xác nhận.
- **Lượng còn phải giao:** góc nhìn thương mại sau khi xử lý thiếu/thừa/từ chối.

Hai con số cuối có thể khác nhau khi người dùng quyết định đóng phần thiếu, chấp nhận thay đổi hoặc điều chỉnh đơn.

## Versioning

Đề xuất v0.2.0: đơn đã xác nhận không sửa đè. Nếu đổi số lượng/giá/điều kiện giao, tạo phiên bản mới. Kho phải biết phiên bản nào là nguồn khi nhận, còn Theme 10 phải theo dõi receipt nào đã dùng phiên bản nào.

## Trường hợp không có đơn

Kho vẫn có thể có nhập nhanh theo policy riêng. Theme 10 **không tạo Đơn mua giả** để hợp thức hóa. Các giao dịch không có Đơn mua nếu cần tham gia hóa đơn/chiết khấu phải dùng source relation riêng và rule của chương trình.

## Ngoại lệ cần thiết kế ở BJ/UC

- Nhận thừa so với version đang hiệu lực.
- Đơn bị giảm/hủy khi Kho đã nhận một phần.
- Receipt correction/reversal đến sau khi đơn đã đóng.
- Một sản phẩm có nhiều UOM và cần quy đổi khi so ngưỡng.

Nguồn: D-02, D-04, D-12, D-13; Q-02/Q-10.
