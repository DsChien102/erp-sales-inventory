# Bức tranh Theme 10 — Mua hàng sau baseline v0.2.0

## 1. Theme 10 sẽ trở thành gì?

Không phải một module “nhập hàng” và cũng không phải một module “công nợ”. Theme 10 là **nơi quản lý quan hệ thương mại mua vào với nhà cung cấp**: mình đã cam kết mua gì, nhà cung cấp đã thực hiện cam kết đến đâu, hóa đơn nào được chấp nhận, hàng trả đã được xử lý thương mại chưa, và các chương trình chiết khấu đang ảnh hưởng thế nào đến chi phí mua dự kiến.

## 2. Năm vùng nghiệp vụ người dùng sẽ cảm nhận được

### A. Đơn mua

Người dùng tạo Đơn mua, xác nhận, sửa bằng phiên bản mới và theo dõi phần còn phải giao. Đơn mua chỉ là cam kết; không làm tăng tồn.

### B. Theo dõi giao hàng

Kho ghi nhận từng lần nhận. Mua hàng tổng hợp kết quả để trả lời: đã nhận bao nhiêu, từ chối bao nhiêu, còn phải giao bao nhiêu, có chênh lệch nào cần quyết định.

### C. Hóa đơn NCC

Hóa đơn được tiếp nhận và kiểm tra nghiệp vụ. Chỉ khi đạt mốc **Hóa đơn đủ điều kiện** mới tạo nguồn nghĩa vụ sang Công nợ. Hóa đơn có thể đến trước hàng hoặc không có Đơn mua; hệ thống không ép tạo chứng từ giả để hợp thức hóa.

### D. Trả NCC

Hồ sơ trả theo dõi hai sự thật riêng: **Kho đã bàn giao hàng chưa** và **NCC đã chấp nhận xử lý tiền/chứng từ chưa**. Một việc hoàn tất không tự suy ra việc còn lại.

### E. Chương trình chiết khấu mua hàng

Mua hàng quản lý điều khoản, ngưỡng, kỳ và phạm vi áp dụng; nhận dữ liệu thực tế từ Kho để tính tiến độ; dùng Đơn mua/kế hoạch có nguồn để lập kịch bản cuối kỳ; tính lợi ích thương mại dự kiến. Kho/Giá vốn dùng kết quả này để mô phỏng giá nhập và giá vốn bình quân dự kiến. Dữ liệu dự kiến không được ghi thành giá vốn hay công nợ thực tế.

## 3. Năm semantic aggregate đề xuất

1. **Đơn mua** — cam kết và lịch sử phiên bản.
2. **Hóa đơn NCC** — tiếp nhận, kiểm tra và nguồn nghĩa vụ.
3. **Hồ sơ trả NCC** — quyết định trả và đối chiếu vật lý/thương mại.
4. **Chương trình chiết khấu** — điều khoản có phiên bản và hiệu lực.
5. **Đánh giá tiến độ & dự báo** — snapshot thực tế, kịch bản và phân bổ lợi ích dự kiến.

Tình hình giao hàng **không** là aggregate riêng; đó là dữ liệu tổng hợp từ sự thật của Kho. Cách này ngăn Theme 10 biến thành một hệ thống tồn kho thứ hai.

## 4. Các đề xuất quan trọng chưa frozen

- Đơn mua đã xác nhận không sửa đè; thay đổi tạo phiên bản mới.
- Hóa đơn có thể đến trước hàng hoặc không có Đơn mua.
- Mốc phát nguồn công nợ là **Hóa đơn đủ điều kiện**, không phải lúc tải tệp.
- Chương trình chiết khấu hỗ trợ điều khoản “hưởng cho toàn kỳ khi đạt” hoặc “chỉ phần vượt ngưỡng”, chọn theo từng chương trình thay vì hard-code toàn hệ thống.
- Căn cứ tính ngưỡng cũng thuộc điều khoản chương trình; khuyến nghị cho hàng hóa là lượng nhận đạt đã xác nhận sau chuẩn hóa đơn vị và xử lý sửa/đảo.
- Tiến độ thực tế và dự báo được lưu theo phiên bản; không sinh “xác suất đạt” nếu chưa có mô hình được duyệt.

## 5. Những điểm cần Business Owner khóa tiếp

Ưu tiên cao nhất vẫn là Q-01/Q-02/Q-04/Q-08 của chương trình chiết khấu, sau đó Q-03 về bằng chứng quyền lợi thực tế. Song song, cần khóa Q-05/Q-06 cho mốc hóa đơn và trả NCC, rồi Q-10 cho quyền thao tác.

Khi các điểm này được xác nhận, bước hợp lý tiếp theo là viết từng Business Journey/Trường hợp sử dụng; chưa cần nhảy thẳng sang UI hay API.
