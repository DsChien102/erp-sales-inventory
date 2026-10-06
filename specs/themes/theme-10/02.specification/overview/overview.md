# Overview — Theme 10 Mua hàng

**Document status:** `IN_REVIEW / NOT_FROZEN`  
**Domain:** `DOM-PUR — Mua hàng`

## 1. Mục đích

Theme Mua hàng giúp người dùng trả lời xuyên suốt năm câu hỏi:

1. **Đã cam kết mua gì, từ NCC nào, theo điều kiện nào?**
2. **NCC đã giao đến đâu, còn thiếu/thừa/từ chối gì cần xử lý?**
3. **Hóa đơn nào đủ điều kiện để trở thành nguồn nghĩa vụ phải trả?**
4. **Hàng trả NCC đang ở đâu giữa kết quả vật lý và kết quả thương mại?**
5. **Chương trình chiết khấu trong kỳ đang đạt đến đâu, có khả năng đạt mức nào và lợi ích dự kiến ảnh hưởng thế nào đến quyết định giá?**

## 2. Product principle

Theme 10 không cố sở hữu toàn bộ quy trình procure-to-pay. Nó sở hữu **lớp thương mại mua hàng** và phối hợp với các miền chuyên trách.

| Miền | Nguồn sự thật |
|---|---|
| Đối tác | Định danh NCC |
| Sản phẩm | Product, UOM, tracking policy, conversion |
| Mua hàng | Đơn mua, hóa đơn NCC, quyết định thương mại trả NCC, chương trình chiết khấu, tiến độ/dự báo |
| Kho | Receipt, LOT/state, tồn, bàn giao vật lý, giá trị kho/giá vốn |
| Công nợ | Nghĩa vụ/số dư phải trả, chi/phân bổ/cấn trừ/đối chiếu |
| Kế toán | Sổ và kỳ kế toán |
| Định giá bán | Giá cơ sở tham chiếu và giá bán công bố |

## 3. Năm Business Journey

| ID | Hành trình | Kết quả tại ranh giới Mua hàng |
|---|---|---|
| BJ-01 | Lập và xác nhận đơn mua | Đơn mua có hiệu lực hoặc dừng/hủy có căn cứ; sửa có phiên bản |
| BJ-02 | Theo dõi giao hàng và xử lý chênh lệch | Mỗi dòng phản ánh đã nhận/còn phải giao và quyết định với sai lệch |
| BJ-03 | Tiếp nhận và xử lý hóa đơn NCC | Hóa đơn đủ điều kiện/chờ/từ chối; nguồn nghĩa vụ hợp lệ được phát đúng một lần |
| BJ-04 | Xử lý trả hàng cho NCC | Phạm vi trả có thẩm quyền; kết quả vật lý và thương mại được đối chiếu |
| BJ-05 | Quản lý chương trình chiết khấu theo kỳ | Điều khoản + tiến độ + dự báo có phiên bản; quyền lợi thực tế tách khỏi lợi ích dự kiến |

Các BJ không tạo thành một chuỗi bắt buộc. Hóa đơn có thể đến trước/sau hàng; BJ-04 chỉ xảy ra khi cần trả; BJ-05 chạy xuyên kỳ.

## 4. Bức tranh sử dụng cuối

Một người làm mua hàng về mặt nghiệp vụ cần có thể:

- tạo và xác nhận một Đơn mua cho một NCC;
- thấy mỗi dòng đã nhận bao nhiêu, còn bao nhiêu và chênh lệch nào cần quyết định mà không phải đọc chi tiết stock ledger;
- tiếp nhận hóa đơn, biết đang chờ gì và chỉ phát nguồn công nợ khi đủ điều kiện;
- mở một hồ sơ trả NCC, theo dõi tách biệt “Kho đã giao hàng” và “NCC đã xử lý tiền/chứng từ”;
- mở một chương trình chiết khấu để thấy **tiến độ thực tế**, **phần còn thiếu**, **kịch bản cuối kỳ**, **lợi ích dự kiến** và phiên bản giả định;
- khi dự báo thay đổi, biết cần rà soát giá tham chiếu nào thay vì âm thầm sửa giá chính thức.

Đây là mục tiêu sản phẩm; UI cụ thể sẽ được thiết kế sau.

## 5. Actor business — candidate

> Q-10 chưa khóa permission. Các vai trò dưới đây mô tả trách nhiệm, chưa phải role matrix triển khai.

- **Người lập mua:** chuẩn bị Đơn mua/chứng từ.
- **Người xác nhận mua:** chấp thuận cam kết thương mại theo policy.
- **Người theo dõi mua:** xử lý thiếu/thừa/trễ và kết quả giao hàng.
- **Người xử lý hóa đơn mua:** tiếp nhận/đối chiếu/xác nhận hoặc từ chối.
- **Người xử lý trả NCC:** quyết định phạm vi trả và theo dõi kết quả thương mại.
- **Người quản lý chương trình mua:** quản lý điều khoản, tiến độ, dự báo và đối chiếu cuối kỳ.

Một người có thể đảm nhận nhiều vai trò tùy tổ chức.

## 6. Invariant cấp Theme

1. Một sự thật có đúng một owner.
2. Dữ liệu từ miền khác luôn mang source identity/version đủ để reconcile.
3. Đơn mua, receipt, invoice, payable và accounting entry không được coi là cùng một object.
4. Actual và expected luôn tách nhãn, tách nguồn và tách lifecycle.
5. Sửa chứng từ đã xác nhận phải có lịch sử; không sửa đè làm mất nguồn downstream đã dùng.
6. Không trộn UOM khi cộng số lượng nếu chưa chuẩn hóa bằng quy đổi canonical.
7. Gửi lại cùng một source operation không được cộng thêm tiến độ hoặc tạo thêm nghĩa vụ.
8. Kết quả chưa rõ không được default thành thành công hoặc số 0.

## 7. Thành công của baseline

Baseline đạt mục tiêu khi BA/Product/SA có thể dùng cùng một ngôn ngữ để trả lời:

- object nào Theme 10 sở hữu;
- object nào chỉ tham chiếu;
- aggregate nào chịu invariant nào;
- dữ liệu nào là thực tế, dữ liệu tổng hợp hay dự báo;
- câu hỏi nào còn mở trước khi viết UC/API/UI.

Numeric SLO/volume/latency chưa thuộc phạm vi baseline này.
