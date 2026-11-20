---
id: KB-KGV-014-hang-can-han-het-han-hu-hong-va-tieu-huy
type: know-how
theme: theme-07
title: hang-can-han-het-han-hu-hong-va-tieu-huy
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-014-hang-can-han-het-han-hu-hong-va-tieu-huy — hang-can-han-het-han-hu-hong-va-tieu-huy

## 1. Bối cảnh

### Câu trả lời ngắn

Cận hạn là một chỉ báo dẫn xuất: đơn vị vận hành đặt ngưỡng mặc định và có thể ghi đè theo sản phẩm để chỉ cảnh báo hoặc chặn bán. Lượng bị chặn bị loại khỏi khả dụng nhưng vẫn thuộc tồn vật lý. Khi đến hạn, hệ thống tạo operation chuyển trạng thái chống trùng theo đơn vị vận hành + lô + ngày nghiệp vụ; chỉ khi operation hoàn tất hàng mới ở trạng thái hết hạn. Hàng hỏng hoặc hết hạn chỉ giảm vật lý sau một operation tiêu hủy/xử lý có lý do, phê duyệt theo ngưỡng và xác nhận đã xử lý.

### Vì sao vấn đề này quan trọng?

Hàng cận hạn, hết hạn và hàng đã tiêu hủy là ba sự thật khác nhau. Một lô cận hạn có thể vẫn bán được hoặc bị chặn tùy chính sách; lô hết hạn còn hiện diện tại kho nhưng không được bán; chỉ hàng đã xử lý vật lý mới được giảm khỏi tồn. Nếu gộp ba mốc, báo cáo sẽ không biết hàng đang ở đâu, người dùng có thể bán hàng không đủ điều kiện hoặc loại khỏi sổ trước khi thực sự tiêu hủy.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Không được hiểu là |
|---|---|---|
| Mốc nghiệp vụ | Sự kiện được người có trách nhiệm xác nhận và có ý nghĩa rõ ràng. | Một thao tác giao diện chưa hoàn tất. |
| Hoàn tất nguyên tử | Toàn bộ thay đổi liên quan cùng thành công hoặc cùng được hoàn tác. | Cho phép một vài dòng ảnh hưởng tồn trước. |

### Quy tắc vận hành

#### Đến hạn phải chuyển trạng thái bằng operation chống trùng

Đến hạn, Hệ thống quản lý tồn kho và giá vốn tạo operation chuyển trạng thái do hệ thống, chống trùng theo đơn vị vận hành + lô + ngày nghiệp vụ; khi operation hoàn tất, lô chuyển hết hạn và bị loại khỏi khả dụng. Không có đường sửa trạng thái trực tiếp.
#### Chỉ xác nhận xử lý mới giảm vật lý

Hàng hỏng/hết hạn chỉ giảm vật lý qua operation tiêu hủy/xử lý có lý do, duyệt theo ngưỡng và xác nhận đã xử lý.
#### Cận hạn là chỉ báo có thể cảnh báo hoặc chặn bán

Cận hạn là chỉ báo dẫn xuất; đơn vị vận hành có ngưỡng mặc định, cho phép ghi đè theo sản phẩm để cảnh báo hoặc chặn bán; lượng bị chặn không khả dụng.

Chính sách gồm ngưỡng số ngày và hành động `WARN` hoặc `BLOCK_SALE`. Cấu hình theo sản phẩm được ưu tiên; nếu không có thì dùng cấu hình mặc định của đơn vị vận hành. Việc thay đổi chính sách là một lệnh cấu hình có quyền và idempotency riêng, không sửa trực tiếp số dư và không tạo một thực thể cảnh báo có thẩm quyền; chỉ báo được tính lại từ chính sách đang hiệu lực và dữ liệu lô.

### Ví dụ xuyên suốt

Lô L1 có 50 hộp, hạn dùng 30/9. Chính sách sản phẩm chặn bán trước hạn 7 ngày. Ngày 23/9, chỉ báo cận hạn kích hoạt và 50 hộp bị loại khỏi khả dụng nhưng vẫn nằm trong vật lý. Sau khi kết thúc ngày 30/9 theo ngày nghiệp vụ, operation hết hạn được tạo với khóa chống trùng; retry cùng ngày không tạo lần chuyển thứ hai. Khi operation hoàn tất, lô ở trạng thái hết hạn. Ngày 5/10, kho được duyệt tiêu hủy 40 hộp và xác nhận đã xử lý; vật lý giảm 40, còn 10 hộp hết hạn vẫn phải được quản lý cho đến lần xử lý sau.

Ví dụ này chỉ minh họa cách áp dụng các quy tắc đã nêu. Con số, tên sản phẩm và thời điểm là giả định; chúng không tạo thêm một ngoại lệ, quyền phê duyệt hay mốc ghi nhận mới.

### Ngoại lệ và những cách làm sai

- **Cận hạn đồng nghĩa với hết hạn:** Cận hạn là chỉ báo chính sách; ngày hết hạn mới tạo mốc trạng thái hết hạn.
- **Tự sửa trạng thái lô:** Chuyển hết hạn phải qua operation do hệ thống, có idempotency và lịch sử.
- **Giảm vật lý khi phê duyệt tiêu hủy:** Chỉ xác nhận đã xử lý thực tế mới cho phép giảm số lượng.

- **Sửa trực tiếp số dư hoặc trạng thái để “làm cho đúng”:** cách này phá vỡ sổ biến động và làm mất khả năng giải thích số liệu. Mọi thay đổi chính thức phải đi qua đúng loại nghiệp vụ, có căn cứ và lịch sử.
- **Dùng dữ liệu tra cứu chậm làm căn cứ commit:** báo cáo hoặc projection có thể hữu ích để quan sát, nhưng quyết định thay đổi tồn phải kiểm tra lại dữ liệu giao dịch hiện hành.

## 3. Ý nghĩa đối với Theme

### Cách áp dụng trong thực tế

Mỗi quy trình phải làm rõ bốn mốc: điều kiện vào, hành động xác nhận, thời điểm thay đổi chính thức và nhánh thất bại an toàn. Các bước chuẩn bị có thể thay đổi trạng thái công việc, nhưng chỉ mốc hoàn tất được quy định mới làm thay đổi số lượng hoặc giá trị có thẩm quyền.

Khi triển khai một trường hợp cụ thể, người xử lý nên ghi rõ nguồn chứng từ, đối tượng hàng, kho, trạng thái, thời điểm nghiệp vụ và kết quả mong đợi. Nếu một dữ kiện thuộc thẩm quyền của hệ thống khác chưa có, hồ sơ phải dừng ở trạng thái an toàn thay vì tự suy đoán. Nếu một bước có thể ảnh hưởng đồng thời đến nhiều số dư hoặc cả số lượng lẫn giá trị, toàn bộ thay đổi phải được commit nguyên tử và để lại dấu vết đối soát.

### Điều cần ghi nhớ

- **Cận hạn có thể chỉ cảnh báo hoặc chặn bán theo chính sách.**
- **Bị chặn hoặc hết hạn không đồng nghĩa với đã rời kho.**
- **Chuyển hết hạn phải chống trùng và chỉ có hiệu lực khi operation hoàn tất.**
- **Tiêu hủy cần lý do, phê duyệt theo ngưỡng và xác nhận đã xử lý.**

- **Khi không đủ bằng chứng để đi tiếp, hệ thống phải thất bại an toàn và giữ nguyên dữ liệu có thẩm quyền.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-014` |
| Cụm tri thức | [`KGV-C03`](00-table-of-contents.md#c03-kiểm-kê-trả-hàng-và-loại-bỏ) |
| Loại bài | `PROCESS` |
| Quyết định chính | [`T7-DR-046`](../decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y), [`T7-DR-047`](../decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y), [`T7-DR-018`](../decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i), [`T7-DR-018#REQ-01`](../decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i) |
| Trạng thái quyết định | `ACTIVE` |
| Mức bằng chứng của bài | `STATIC_VALIDATED` |
| Giới hạn | Bài mô tả trạng thái và số lượng; không quyết định mức ngưỡng cận hạn cụ thể hoặc căn cứ giá trị của nghiệp vụ tiêu hủy |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-005` — Tồn vật lý, lượng đủ điều kiện bán, lượng giữ và tồn khả dụng](KB-KGV-005-ton-vat-ly-va-ton-kha-dung.md)
- [`KB-KGV-020` — Định giá hàng trả, tiêu hủy và chênh lệch thừa thiếu](KB-KGV-020-dinh-gia-hang-tra-tieu-huy-va-chenh-lech-thua-thieu.md)
- [`KB-KGV-025` — Danh tính và vòng đời của một lô hàng](KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md)
