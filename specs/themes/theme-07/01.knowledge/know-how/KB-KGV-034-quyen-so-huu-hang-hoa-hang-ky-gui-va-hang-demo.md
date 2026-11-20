---
id: KB-KGV-034-quyen-so-huu-hang-hoa-hang-ky-gui-va-hang-demo
type: know-how
theme: theme-07
title: quyen-so-huu-hang-hoa-hang-ky-gui-va-hang-demo
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-034-quyen-so-huu-hang-hoa-hang-ky-gui-va-hang-demo — quyen-so-huu-hang-hoa-hang-ky-gui-va-hang-demo

## 1. Bối cảnh

### Câu trả lời ngắn

Hàng chưa chuyển quyền sở hữu cho doanh nghiệp không được nhập như tồn sở hữu. Hệ thống nguồn của nghiệp vụ mua/nhận phải cung cấp assertion có phiên bản về việc chuyển quyền sở hữu và bằng chứng tương ứng; hệ thống kho bắt buộc assertion hợp lệ nhưng không tự phán quyết pháp lý. Phạm vi hiện tại không quản lý hàng ký gửi, giữ hộ hoặc hàng bên thứ ba và không có trạng thái custody-only. Trạng thái chờ định giá chỉ dành cho hàng đã thuộc sở hữu nhưng chưa chốt giá. Hàng demo thuộc sở hữu doanh nghiệp vẫn nằm trong tồn vật lý và giá trị ghi sổ, song bị loại khỏi khả dụng bằng một operation chuyển trạng thái.

### Vì sao vấn đề này quan trọng?

Sự hiện diện vật lý không đồng nghĩa với quyền sở hữu. Hàng ký gửi có thể nằm trong kho và được bán theo hợp đồng đại lý, nhưng nếu đưa thẳng vào tồn sở hữu, hệ thống sẽ ghi nhận sai tài sản và giá vốn. Ngược lại, hàng demo thực sự thuộc doanh nghiệp không được biến mất khỏi sổ chỉ vì không bán. Cổng quyền sở hữu tách hai câu hỏi: hàng có ở đây không và hàng có thuộc tài sản của doanh nghiệp không; khi mô hình custody chưa được hỗ trợ, cách an toàn là từ chối thay vì mượn một trạng thái khác.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Không được hiểu là |
|---|---|---|
| Chủ sở hữu chính sách | Hệ thống có thẩm quyền thiết lập và công bố cấu hình nghiệp vụ. | Hệ thống thực thi tự chọn quy tắc thuận tiện. |
| Chuyển đổi chính sách | Batch đưa toàn bộ dữ liệu hiện hữu sang điều kiện của chính sách mới trước khi kích hoạt. | Bật cờ cấu hình rồi sửa dữ liệu dần về sau. |

### Quy tắc vận hành

#### Không quản lý hàng ký gửi hoặc giữ hộ trong phạm vi hiện tại

Phạm vi hiện tại không quản lý hàng ký gửi, hàng giữ hộ hoặc hàng thuộc sở hữu bên thứ ba; không có `CUSTODY_ONLY`.
#### Assertion chuyển quyền sở hữu là điều kiện nhập tồn

Hàng chưa chuyển quyền sở hữu cho đơn vị vận hành không được nhập Hệ thống quản lý tồn kho và giá vốn. Nguồn mua/nhận chịu trách nhiệm assertion về chuyển quyền sở hữu và bằng chứng/phiên bản của assertion; Hệ thống quản lý tồn kho và giá vốn bắt buộc có assertion hợp lệ nhưng không tự phán quyết pháp lý. `VALUATION_PENDING` chỉ dùng cho hàng đã thuộc đơn vị vận hành nhưng chưa chốt giá.
#### Hàng demo vẫn là tồn sở hữu nhưng không khả dụng

Hàng thuộc đơn vị vận hành chuyển sang `DEMO` bằng operation; vẫn thuộc vật lý và giá trị ghi sổ nhưng không khả dụng; được chuyển lại hoặc xử lý tiếp bằng operation.

### Ví dụ xuyên suốt

Nhà cung cấp gửi 50 sản phẩm ký gửi đến cửa hàng nhưng quyền sở hữu chưa chuyển. Dù hàng hiện diện vật lý, hệ thống kho sở hữu không được tạo nhập mua hoặc dùng trạng thái chờ giá; nghiệp vụ phải được quản lý ở một mô hình custody khác ngoài phạm vi. Với một lô 10 sản phẩm mà hợp đồng xác nhận quyền sở hữu đã chuyển nhưng giá trực tiếp chưa chốt, nguồn gửi assertion hợp lệ và hàng có thể vào trạng thái chờ định giá. Sau đó doanh nghiệp chọn 2 sản phẩm thuộc sở hữu làm mẫu trưng bày: một operation chuyển 2 đơn vị sang DEMO, vẫn giữ vật lý và giá trị nhưng loại khỏi khả dụng. Khi thôi trưng bày, operation khác mới chuyển chúng về trạng thái bán được nếu đủ điều kiện.

Ví dụ này chỉ minh họa cách áp dụng các quy tắc đã nêu. Con số, tên sản phẩm và thời điểm là giả định; chúng không tạo thêm một ngoại lệ, quyền phê duyệt hay mốc ghi nhận mới.

### Ngoại lệ và những cách làm sai

- **Dùng chờ định giá cho hàng chưa sở hữu:** Chờ định giá chỉ giải quyết thiếu giá của tài sản đã thuộc doanh nghiệp, không thay thế assertion quyền sở hữu.
- **Nhập hàng ký gửi rồi ghi nợ phải trả:** Mô hình kho hiện tại không có custody; không được biến nghiệp vụ ngoài phạm vi thành tồn sở hữu.
- **Xuất giảm hàng demo khỏi vật lý:** DEMO là trạng thái sử dụng của tài sản vẫn hiện diện, không phải hàng đã rời kho.

- **Sửa trực tiếp số dư hoặc trạng thái để “làm cho đúng”:** cách này phá vỡ sổ biến động và làm mất khả năng giải thích số liệu. Mọi thay đổi chính thức phải đi qua đúng loại nghiệp vụ, có căn cứ và lịch sử.
- **Dùng dữ liệu tra cứu chậm làm căn cứ commit:** báo cáo hoặc projection có thể hữu ích để quan sát, nhưng quyết định thay đổi tồn phải kiểm tra lại dữ liệu giao dịch hiện hành.

## 3. Ý nghĩa đối với Theme

### Cách áp dụng trong thực tế

Chính sách phải có một chủ sở hữu rõ ràng, phiên bản hiệu lực và điều kiện chuyển đổi. Hệ thống thực thi chỉ tiếp nhận chính sách đã có hiệu lực và bắt buộc tuân thủ trong mọi nghiệp vụ. Nếu thay đổi chính sách làm dữ liệu hiện hữu không còn hợp lệ, phạm vi phải được khóa và chuyển đổi có đối soát trước khi kích hoạt bản mới.

Khi triển khai một trường hợp cụ thể, người xử lý nên ghi rõ nguồn chứng từ, đối tượng hàng, kho, trạng thái, thời điểm nghiệp vụ và kết quả mong đợi. Nếu một dữ kiện thuộc thẩm quyền của hệ thống khác chưa có, hồ sơ phải dừng ở trạng thái an toàn thay vì tự suy đoán. Nếu một bước có thể ảnh hưởng đồng thời đến nhiều số dư hoặc cả số lượng lẫn giá trị, toàn bộ thay đổi phải được commit nguyên tử và để lại dấu vết đối soát.

### Điều cần ghi nhớ

- **Hiện diện vật lý và quyền sở hữu là hai sự thật khác nhau.**
- **Nguồn nghiệp vụ phải assertion chuyển quyền; hệ thống kho không tự phán quyết pháp lý.**
- **Ký gửi, giữ hộ và custody-only nằm ngoài phạm vi hiện tại.**
- **Hàng demo vẫn có số lượng và giá trị nhưng không khả dụng.**

- **Khi không đủ bằng chứng để đi tiếp, hệ thống phải thất bại an toàn và giữ nguyên dữ liệu có thẩm quyền.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-034` |
| Cụm tri thức | [`KGV-C09`](00-table-of-contents.md#c09-hàng-đặc-thù-combo-bổ-sung-và-vòng-đời-master) |
| Loại bài | `POLICY` |
| Quyết định chính | [`T7-DR-007#REQ-01`](../decisions/decision-register.md#31-g01-ph%E1%BA%A1m-vi-th%E1%BA%A9m-quy%E1%BB%81n-v%C3%A0-m%C3%B4-h%C3%ACnh-c%E1%BB%ADa-h%C3%A0ngkho), [`T7-DR-007`](../decisions/decision-register.md#31-g01-ph%E1%BA%A1m-vi-th%E1%BA%A9m-quy%E1%BB%81n-v%C3%A0-m%C3%B4-h%C3%ACnh-c%E1%BB%ADa-h%C3%A0ngkho), [`T7-DR-092`](../decisions/decision-register.md#313-g13-d%E1%BB%AF-li%E1%BB%87u-ch%E1%BB%A7-combo-b%E1%BB%95-sung-h%C3%A0ng-v%C3%A0-nghi%E1%BB%87p-v%E1%BB%A5-%C4%91%E1%BA%B7c-bi%E1%BB%87t) |
| Trạng thái quyết định | `OUT_OF_SCOPE`, `ACTIVE` |
| Mức bằng chứng của bài | `STATIC_VALIDATED` |
| Giới hạn | Bài giải thích cổng quyền sở hữu và hàng demo; không đưa ra tư vấn pháp lý/kế toán cho hợp đồng ký gửi hoặc thiết kế module custody tương lai |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-001` — Phạm vi quản lý tồn kho và giá vốn](KB-KGV-001-pham-vi-quan-ly-ton-kho-va-gia-von.md)
- [`KB-KGV-002` — Ranh giới trách nhiệm giữa các hệ thống nghiệp vụ](KB-KGV-002-ranh-gioi-trach-nhiem-giua-cac-he-thong-nghiep-vu.md)
- [`KB-KGV-013` — Trả hàng cho nhà cung cấp](KB-KGV-013-tra-hang-cho-nha-cung-cap.md)
