---
id: KB-KGV-002-ranh-gioi-trach-nhiem-giua-cac-he-thong-nghiep-vu
type: know-how
theme: theme-07
title: ranh-gioi-trach-nhiem-giua-cac-he-thong-nghiep-vu
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-002-ranh-gioi-trach-nhiem-giua-cac-he-thong-nghiep-vu — ranh-gioi-trach-nhiem-giua-cac-he-thong-nghiep-vu

## 1. Bối cảnh

### Câu trả lời ngắn

Hệ thống quản lý tồn kho và giá vốn sở hữu số lượng, khả dụng, trạng thái, hồ sơ lô–hạn dùng, luân chuyển và giá trị tồn kho. Hệ thống mua, bán, định giá và quản lý sản phẩm vẫn sở hữu chứng từ và master data tương ứng. Chứng từ nguồn chỉ gửi yêu cầu cùng những xác nhận mà nó có thẩm quyền; hệ thống kho tự kiểm tra hợp đồng, số dư và điều kiện bất biến trước khi tạo hoặc thực thi Inventory Operation. Không hệ thống nguồn nào được sửa thẳng số dư tồn kho. Quản lý theo serial là năng lực tương lai.

### Vì sao vấn đề này quan trọng?

Cùng một giao dịch bán hàng có dữ liệu thuộc nhiều chủ sở hữu: đơn bán thuộc hệ thống bán, chính sách theo lô thuộc master sản phẩm, còn số lượng đã xuất và giá vốn thuộc sổ kho. Nếu không phân tách thẩm quyền, một hệ thống có thể vô tình tuyên bố cả sự kiện bàn giao lẫn kết quả trừ kho, khiến retry, hủy đơn hoặc sửa master tạo ra hai Dữ liệu gốc. Ranh giới trách nhiệm biến tích hợp thành hợp đồng có thể kiểm tra thay vì trao quyền sửa dữ liệu lẫn nhau.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Không được hiểu là |
|---|---|---|
| Phạm vi nghiệp vụ | Tập tình huống hệ thống cam kết hỗ trợ và kiểm soát. | Danh sách mọi việc người dùng có thể tưởng tượng. |
| Thẩm quyền dữ liệu | Quyền quyết định và ghi nhận chính thức đối với một loại dữ liệu. | Quyền hiển thị hoặc sao chép dữ liệu từ hệ thống khác. |

### Quy tắc vận hành

#### Phân chia quyền sở hữu dữ liệu

Hệ thống quản lý tồn kho và giá vốn sở hữu số lượng, khả dụng, lô–hạn dùng, luân chuyển và giá trị/giá vốn tồn kho; không sở hữu chứng từ mua, bán, giá bán hoặc master sản phẩm.
#### Chứng từ nguồn yêu cầu, sổ kho quyết định kết quả

Chứng từ nguồn gửi yêu cầu cùng các assertion thuộc thẩm quyền của nguồn như phiên bản chứng từ, bàn giao hoặc chuyển quyền sở hữu; Hệ thống quản lý tồn kho và giá vốn kiểm tra hợp đồng và invariant của mình rồi tạo/thực thi Inventory Operation. Không hệ thống nguồn nào được sửa trực tiếp số dư.

### Ví dụ xuyên suốt

Hệ thống bán hàng xác nhận đơn SO-100 đã được bàn giao lúc 10:00 và gửi request ID ổn định, phiên bản dòng hàng cùng số lượng bàn giao. Nó không gửi một số dư mới kiểu “tồn còn 42”. Hệ thống kho kiểm tra dòng hàng, kho, lượng khả dụng, trạng thái lô và idempotency rồi hoàn tất operation xuất. Nếu cùng yêu cầu được retry, kết quả cũ được trả lại. Nếu payload đổi nhưng request ID giữ nguyên, yêu cầu bị chặn. Nhờ đó, đơn bán vẫn là nguồn của sự kiện bàn giao, còn movement và số dư sau xuất vẫn chỉ có một nguồn có thẩm quyền.

Ví dụ này chỉ minh họa cách áp dụng các quy tắc đã nêu. Con số, tên sản phẩm và thời điểm là giả định; chúng không tạo thêm một ngoại lệ, quyền phê duyệt hay mốc ghi nhận mới.

### Ngoại lệ và những cách làm sai

- **Cho hệ thống nguồn gửi số dư cuối:** Nguồn chỉ được gửi sự kiện và assertion thuộc thẩm quyền; số dư phải được suy ra từ sổ biến động của kho.
- **Sao chép master rồi cho phép sửa độc lập:** Bản sao phục vụ tra cứu không được trở thành một master cạnh tranh với hệ thống quản lý sản phẩm.
- **Hiểu quyền tích hợp là quyền ghi trực tiếp:** API nghiệp vụ phải đi qua kiểm tra invariant và Inventory Operation, không mở đường cập nhật bảng số dư.

- **Sửa trực tiếp số dư hoặc trạng thái để “làm cho đúng”:** cách này phá vỡ sổ biến động và làm mất khả năng giải thích số liệu. Mọi thay đổi chính thức phải đi qua đúng loại nghiệp vụ, có căn cứ và lịch sử.
- **Dùng dữ liệu tra cứu chậm làm căn cứ commit:** báo cáo hoặc projection có thể hữu ích để quan sát, nhưng quyết định thay đổi tồn phải kiểm tra lại dữ liệu giao dịch hiện hành.

## 3. Ý nghĩa đối với Theme

### Cách áp dụng trong thực tế

Bắt đầu bằng việc xác định đối tượng và ranh giới trách nhiệm. Sau đó kiểm tra yêu cầu có nằm trong phạm vi được hỗ trợ hay không. Chỉ khi cả phạm vi lẫn thẩm quyền đều rõ thì mới đi tiếp đến bước tạo nghiệp vụ; yêu cầu ngoài phạm vi phải thất bại có cấu trúc và không tạo thay đổi bán phần.

Khi triển khai một trường hợp cụ thể, người xử lý nên ghi rõ nguồn chứng từ, đối tượng hàng, kho, trạng thái, thời điểm nghiệp vụ và kết quả mong đợi. Nếu một dữ kiện thuộc thẩm quyền của hệ thống khác chưa có, hồ sơ phải dừng ở trạng thái an toàn thay vì tự suy đoán. Nếu một bước có thể ảnh hưởng đồng thời đến nhiều số dư hoặc cả số lượng lẫn giá trị, toàn bộ thay đổi phải được commit nguyên tử và để lại dấu vết đối soát.

### Điều cần ghi nhớ

- **Chứng từ mua, bán và master sản phẩm có chủ sở hữu riêng.**
- **Số lượng, trạng thái và giá trị tồn kho có một sổ sở hữu duy nhất.**
- **Nguồn gửi yêu cầu và assertion; hệ thống kho kiểm tra rồi quyết định kết quả.**
- **Không tích hợp nào được sửa trực tiếp số dư.**

- **Khi không đủ bằng chứng để đi tiếp, hệ thống phải thất bại an toàn và giữ nguyên dữ liệu có thẩm quyền.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-002` |
| Cụm tri thức | [`KGV-C01`](00-table-of-contents.md#c01-nền-tảng-quản-lý-tồn-kho) |
| Loại bài | `FOUNDATION` |
| Quyết định chính | [`T7-DR-002`](../decisions/decision-register.md#31-g01-ph%E1%BA%A1m-vi-th%E1%BA%A9m-quy%E1%BB%81n-v%C3%A0-m%C3%B4-h%C3%ACnh-c%E1%BB%ADa-h%C3%A0ngkho), [`T7-DR-003`](../decisions/decision-register.md#31-g01-ph%E1%BA%A1m-vi-th%E1%BA%A9m-quy%E1%BB%81n-v%C3%A0-m%C3%B4-h%C3%ACnh-c%E1%BB%ADa-h%C3%A0ngkho) |
| Trạng thái quyết định | `ACTIVE` |
| Mức bằng chứng của bài | `STATIC_VALIDATED` |
| Giới hạn | Bài giải thích thẩm quyền dữ liệu; không mô tả chi tiết payload, schema sự kiện hoặc tuyến phê duyệt của từng loại operation |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-001` — Phạm vi quản lý tồn kho và giá vốn](KB-KGV-001-pham-vi-quan-ly-ton-kho-va-gia-von.md)
- [`KB-KGV-024` — Chọn quản lý thông thường hay quản lý theo lô](KB-KGV-024-chinh-sach-quan-ly-hang-thong-thuong-theo-lo-hoac-theo-serial.md)
- [`KB-KGV-027` — Vòng đời của một Inventory Operation](KB-KGV-027-vong-doi-cua-mot-inventory-operation.md)
- [`KB-KGV-031` — Phê duyệt Inventory Operation theo mức rủi ro](KB-KGV-031-phe-duyet-inventory-operation-theo-muc-rui-ro.md)
- [`KB-KGV-034` — Quyền sở hữu hàng hóa, hàng ký gửi và hàng demo](KB-KGV-034-quyen-so-huu-hang-hoa-hang-ky-gui-va-hang-demo.md)
