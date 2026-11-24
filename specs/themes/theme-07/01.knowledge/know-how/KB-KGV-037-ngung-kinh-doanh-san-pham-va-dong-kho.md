---
id: KB-KGV-037-ngung-kinh-doanh-san
type: know-how
theme: theme-07
title: ngung-kinh-doanh-san-pham-va-dong-kho
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-037-ngung-kinh-doanh-san — ngung-kinh-doanh-san-pham-va-dong-kho

## 1. Bối cảnh

### Câu trả lời ngắn

Trạng thái `DISCONTINUED` chặn yêu cầu mua mới và nhập mua mới không được nguồn cho phép tiếp tục, nhưng không xóa sản phẩm hoặc khóa các nghiệp vụ cần để xử lý nghĩa vụ còn lại. Vẫn phải cho bán hết lượng hợp lệ, nhận khách trả, trả nhà cung cấp, correction/reversal, điều chỉnh và tiêu hủy. Chỉ archive khi tồn, lượng giữ và operation mở đều bằng 0.

Đóng hoặc đổi kho hoạt động chưa thuộc phạm vi khởi đầu. Kho mặc định phải tồn tại và hoạt động; không có thao tác đóng kho trong giao diện hoặc API hiện tại.

### Vì sao vấn đề này quan trọng?

“Không còn kinh doanh” không có nghĩa là hàng và nghĩa vụ biến mất. Nếu khóa mọi operation, cửa hàng không thể bán nốt, nhận hàng khách trả hoặc tiêu hủy đúng quy trình. Nếu xóa master, sổ cũ mất khả năng giải thích. Với kho, một thao tác đóng vội có thể để lại tồn, reservation hoặc operation không có nơi xử lý; vì vậy chức năng này chỉ nên mở khi có đầy đủ điều kiện an toàn.

## 2. Nội dung nền tảng

### Quy tắc vận hành

1. `DISCONTINUED` ngăn cam kết mua mới theo chính sách nguồn.
2. Goods receipt từ chứng từ đã có chỉ được nhận nếu nguồn khẳng định phiên bản/chính sách vẫn cho phép.
3. Các nghiệp vụ xử lý tồn và nghĩa vụ đã phát sinh vẫn hoạt động.
4. Archive chỉ khi vật lý = 0, giữ = 0 và không còn operation mở.
5. Dữ liệu lịch sử, movement và liên kết chứng từ vẫn được giữ sau archive.
6. Trong phạm vi hiện tại, không có đóng kho, đổi kho mặc định hoặc tạo topology hoạt động thứ hai.
7. Yêu cầu đóng/đổi kho phải bị từ chối có cấu trúc, không được thực hiện bằng sửa cờ trực tiếp.
8. `ARCHIVED` chặn mọi mutation mới; chỉ còn quyền đọc lịch sử có kiểm soát.
9. Goods receipt cho sản phẩm `DISCONTINUED` chỉ được tiếp tục khi request mang tham chiếu chứng từ nguồn và phiên bản/chính sách đã được chụp trước mốc ngừng; nếu không phải trả lỗi có cấu trúc.
10. Đơn vị cơ sở của sản phẩm đã có movement là bất biến; thay đổi phải qua sản phẩm mới hoặc migration có kiểm soát.

### Ví dụ minh họa

Sản phẩm P ngừng kinh doanh nhưng còn 12 đơn vị và 2 đơn đang giữ tổng 4 đơn vị. Hệ thống chặn tạo yêu cầu mua mới nhưng vẫn cho giao 4 đơn vị đã giữ, bán nốt 8 đơn vị, nhận trả nếu khách hoàn hàng và tiêu hủy hàng hỏng. Chỉ sau khi tồn và nghĩa vụ về 0 mới được archive.

Kho `WH-01` là kho hoạt động duy nhất. Người quản trị không thấy nút “Đóng kho”; API tương ứng trả lỗi ngoài phạm vi. Khi chức năng nhiều kho được mở sau này, điều kiện đóng kho phải được thiết kế thành một hợp đồng riêng.

### Ngoại lệ và cách làm sai

- **Ngừng kinh doanh rồi chặn khách trả:** bỏ nghĩa vụ đã phát sinh.
- **Xóa sản phẩm:** làm movement lịch sử mất ngữ cảnh.
- **Archive khi còn reservation:** tạo cam kết không thể hoàn tất.
- **Thêm nút đóng kho nhưng chỉ kiểm tra tồn tổng:** bỏ sót trạng thái, lô, khóa hoặc operation mở.

## 3. Ý nghĩa đối với Theme

### Điều cần ghi nhớ

- **Ngừng kinh doanh chặn tương lai, không xóa quá khứ.**
- **Các đường xử lý tồn còn lại phải tiếp tục.**
- **Archive chỉ sau khi sạch tồn và nghĩa vụ.**
- **Đóng/đổi kho là chức năng tương lai, không phải cờ cấu hình hiện tại.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-037` |
| Cụm tri thức | [`KGV-C09`](00-table-of-contents.md#c09-hàng-đặc-thù-combo-bổ-sung-và-vòng-đời-master) |
| Loại bài | `LIFECYCLE` |
| Quyết định chính | [`T7-DR-097`](../decisions/decision-register.md#313-g13-d%E1%BB%AF-li%E1%BB%87u-ch%E1%BB%A7-combo-b%E1%BB%95-sung-h%C3%A0ng-v%C3%A0-nghi%E1%BB%87p-v%E1%BB%A5-%C4%91%E1%BA%B7c-bi%E1%BB%87t), [`T7-DR-004`](../decisions/decision-register.md#31-g01-ph%E1%BA%A1m-vi-th%E1%BA%A9m-quy%E1%BB%81n-v%C3%A0-m%C3%B4-h%C3%ACnh-c%E1%BB%ADa-h%C3%A0ngkho), [`T7-DR-097`](../decisions/decision-register.md#313-g13-d%E1%BB%AF-li%E1%BB%87u-ch%E1%BB%A7-combo-b%E1%BB%95-sung-h%C3%A0ng-v%C3%A0-nghi%E1%BB%87p-v%E1%BB%A5-%C4%91%E1%BA%B7c-bi%E1%BB%87t) |
| Trạng thái | Ngừng sản phẩm áp dụng; đóng/đổi kho được hoãn |
| Mức bằng chứng | `STATIC_VALIDATED` |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-003` — Cửa hàng, kho và khóa định danh số dư tồn kho](KB-KGV-003-kho-cua-hang-va-khoa-dinh-danh-so-du-ton-kho.md)
- [`KB-KGV-021` — Sửa sai tồn kho mà không sửa lịch sử](KB-KGV-021-sua-sai-ton-kho-khong-sua-lich-su.md)
- [`KB-KGV-041` — Cách kiểm soát thay đổi đối với quy tắc nghiệp vụ](KB-KGV-041-cach-kiem-soat-thay-doi-doi-voi-quy-tac-nghiep-vu.md)
