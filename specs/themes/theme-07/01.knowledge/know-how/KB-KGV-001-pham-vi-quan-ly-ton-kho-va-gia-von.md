---
id: KB-KGV-001
type: know-how
theme: theme-07
title: pham-vi-quan-ly-ton-kho-va-gia-von
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-001 — pham-vi-quan-ly-ton-kho-va-gia-von

## 1. Bối cảnh

### Câu trả lời ngắn

Phạm vi quản lý tồn kho và giá vốn phục vụ bán lẻ, bán sỉ và hoàn tất đơn trực tuyến, với mức chi tiết vị trí đến cấp kho. Phạm vi hiện tại không bao gồm bin/kệ, chuyển kho nội bộ, hàng ký gửi, chuyển đổi giữa các SKU, BOM hoặc sản xuất. Yêu cầu ngoài phạm vi phải bị từ chối bằng lỗi có cấu trúc và không được tạo bất kỳ thay đổi bán phần nào. Mô hình hàng đang vận chuyển chỉ là định hướng cho phiên bản sau, chưa phải một trạng thái có thể phát sinh trong vận hành hiện tại.

### Vì sao vấn đề này quan trọng?

Một hệ thống kho dễ bị biến thành nơi xử lý mọi yêu cầu có liên quan đến hàng hóa. Nếu ranh giới không rõ, người vận hành có thể dùng điều chỉnh tồn để giả lập chuyển kho, tách gộp sản phẩm hoặc nhận hàng ký gửi. Những đường tắt này làm số dư có vẻ đúng trong ngắn hạn nhưng phá hỏng nguồn gốc của hàng, giá trị ghi sổ và khả năng đối soát. Phạm vi rõ giúp đội nghiệp vụ biết yêu cầu nào được thực thi, yêu cầu nào phải chuyển sang một quy trình hoặc phiên bản khác.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Không được hiểu là |
|---|---|---|
| Phạm vi nghiệp vụ | Tập tình huống hệ thống cam kết hỗ trợ và kiểm soát. | Danh sách mọi việc người dùng có thể tưởng tượng. |
| Thẩm quyền dữ liệu | Quyền quyết định và ghi nhận chính thức đối với một loại dữ liệu. | Quyền hiển thị hoặc sao chép dữ liệu từ hệ thống khác. |

### Quy tắc vận hành

#### Các mô hình bán hàng được phục vụ

Phạm vi hiện tại phục vụ bán lẻ, bán sỉ và hoàn tất đơn trực tuyến.
#### Tổ chức trải nghiệm theo công việc

Người dùng đi vào hệ thống theo vai trò và việc cần làm, chẳng hạn xem tồn, nhận hàng, bán hàng hoặc đối soát. Họ không phải hiểu ranh giới miền, tên nhóm màn hình hay mã kỹ thuật trước khi bắt đầu. Bản đồ trải nghiệm chỉ dẫn tới các truy vấn và hành động đã được cấp quyền; nó không tạo thêm năng lực nghiệp vụ, Dữ liệu gốc hoặc trạng thái mới.
#### Mức chi tiết vị trí được quản lý

Phạm vi hiện tại quản lý vị trí đến cấp kho, không quản lý bin/kệ/vị trí chi tiết; phân loại hàng bằng trạng thái tồn kho.
#### Chuyển kho nội bộ chưa được hỗ trợ

Phạm vi hiện tại chưa hỗ trợ chuyển kho nội bộ. API phải từ chối yêu cầu này; không được mô phỏng bằng adjustment.
#### Định hướng cho hàng đang vận chuyển

Khi triển khai ở phiên bản sau, hàng rời kho nguồn khi operation gửi hoàn tất, trở thành tồn đang vận chuyển của đơn vị vận hành, không khả dụng ở hai kho; chênh lệch nhận được giữ để xử lý.
#### Không chuyển đổi giữa các sản phẩm

Phạm vi hiện tại không hỗ trợ chuyển đổi giữa SKU/sản phẩm và không cho mô phỏng bằng hai adjustment độc lập.
#### Hợp đồng từ chối yêu cầu ngoài phạm vi

Nghiệp vụ ngoài Phạm vi hiện tại phải nằm trong Scope Matrix/Behavioral Contract và bị từ chối bằng lỗi có cấu trúc; không tạo mutation bán phần.
#### Danh mục loại trừ rõ ràng

Phạm vi hiện tại loại trừ: bin/location chi tiết, chuyển kho nội bộ, custody/ký gửi, chuyển đổi SKU, BOM/sản xuất và các đường sửa trực tiếp số dư/trạng thái.

### Ví dụ xuyên suốt

Một đơn vị vận hành có một kho trung tâm được dùng cho cửa hàng, đơn sỉ và đơn online. Ba luồng bán này đều có thể kiểm tra, giữ hoặc xuất từ cùng số dư kho theo đúng quy tắc. Khi người dùng gửi yêu cầu chuyển 20 đơn vị từ kho trung tâm sang kho dự phòng, API phải trả lỗi ngoài phạm vi và không được tạo một adjustment giảm ở kho nguồn rồi tăng ở kho đích. Tương tự, yêu cầu biến một thùng quà thành ba SKU thành phần không được mô phỏng bằng các adjustment độc lập. Kết quả đúng là không số dư nào thay đổi và yêu cầu có mã lỗi đủ rõ để hệ thống nguồn xử lý.

Ví dụ này chỉ minh họa cách áp dụng các quy tắc đã nêu. Con số, tên sản phẩm và thời điểm là giả định; chúng không tạo thêm một ngoại lệ, quyền phê duyệt hay mốc ghi nhận mới.

### Ngoại lệ và những cách làm sai

- **Dùng adjustment để giả lập nghiệp vụ chưa hỗ trợ:** Adjustment không mang semantics bàn giao, vận chuyển, nhận đích hoặc chuyển đổi sản phẩm nên không thể thay thế chuyển kho hay tách gộp SKU.
- **Tạo trạng thái đang vận chuyển từ sớm:** Mã dành trước không phải là quyền tạo số dư; sử dụng nó sẽ làm phát sinh dữ liệu mà quy trình hiện tại không thể kết thúc đúng.
- **Đưa hàng ký gửi vào tồn sở hữu:** Hàng có quyền sở hữu khác cần mô hình custody riêng; phạm vi hiện tại loại trừ nghiệp vụ này.

- **Sửa trực tiếp số dư hoặc trạng thái để “làm cho đúng”:** cách này phá vỡ sổ biến động và làm mất khả năng giải thích số liệu. Mọi thay đổi chính thức phải đi qua đúng loại nghiệp vụ, có căn cứ và lịch sử.
- **Dùng dữ liệu tra cứu chậm làm căn cứ commit:** báo cáo hoặc projection có thể hữu ích để quan sát, nhưng quyết định thay đổi tồn phải kiểm tra lại dữ liệu giao dịch hiện hành.

## 3. Ý nghĩa đối với Theme

### Cách áp dụng trong thực tế

Bắt đầu bằng việc xác định đối tượng và ranh giới trách nhiệm. Sau đó kiểm tra yêu cầu có nằm trong phạm vi được hỗ trợ hay không. Chỉ khi cả phạm vi lẫn thẩm quyền đều rõ thì mới đi tiếp đến bước tạo nghiệp vụ; yêu cầu ngoài phạm vi phải thất bại có cấu trúc và không tạo thay đổi bán phần.

Khi triển khai một trường hợp cụ thể, người xử lý nên ghi rõ nguồn chứng từ, đối tượng hàng, kho, trạng thái, thời điểm nghiệp vụ và kết quả mong đợi. Nếu một dữ kiện thuộc thẩm quyền của hệ thống khác chưa có, hồ sơ phải dừng ở trạng thái an toàn thay vì tự suy đoán. Nếu một bước có thể ảnh hưởng đồng thời đến nhiều số dư hoặc cả số lượng lẫn giá trị, toàn bộ thay đổi phải được commit nguyên tử và để lại dấu vết đối soát.

### Điều cần ghi nhớ

- **Ba mô hình bán được phục vụ là bán lẻ, bán sỉ và hoàn tất đơn trực tuyến.**
- **Vị trí được quản lý đến cấp kho, không đến bin hoặc kệ.**
- **Chuyển kho nội bộ, ký gửi, chuyển đổi SKU và sản xuất nằm ngoài phạm vi hiện tại.**
- **Ngoài phạm vi nghĩa là từ chối có cấu trúc và không mutation bán phần.**
- **Giao diện bắt đầu từ công việc của người dùng, nhưng vẫn thực thi đúng hợp đồng nghiệp vụ và quyền hiện có.**

- **Khi không đủ bằng chứng để đi tiếp, hệ thống phải thất bại an toàn và giữ nguyên dữ liệu có thẩm quyền.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-001` |
| Cụm tri thức | [`KGV-C01`](00-table-of-contents.md#c01-nền-tảng-quản-lý-tồn-kho) |
| Loại bài | `FOUNDATION` |
| Quyết định chính | [`T7-DR-001`](../decisions/decision-register.md#31-g01-ph%E1%BA%A1m-vi-th%E1%BA%A9m-quy%E1%BB%81n-v%C3%A0-m%C3%B4-h%C3%ACnh-c%E1%BB%ADa-h%C3%A0ngkho), [`T7-DR-009`](../decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i), [`T7-DR-005`](../decisions/decision-register.md#31-g01-ph%E1%BA%A1m-vi-th%E1%BA%A9m-quy%E1%BB%81n-v%C3%A0-m%C3%B4-h%C3%ACnh-c%E1%BB%ADa-h%C3%A0ngkho), [`T7-DR-006`](../decisions/decision-register.md#31-g01-ph%E1%BA%A1m-vi-th%E1%BA%A9m-quy%E1%BB%81n-v%C3%A0-m%C3%B4-h%C3%ACnh-c%E1%BB%ADa-h%C3%A0ngkho), [`T7-DR-093`](../decisions/decision-register.md#313-g13-d%E1%BB%AF-li%E1%BB%87u-ch%E1%BB%A7-combo-b%E1%BB%95-sung-h%C3%A0ng-v%C3%A0-nghi%E1%BB%87p-v%E1%BB%A5-%C4%91%E1%BA%B7c-bi%E1%BB%87t), [`T7-DR-008`](../decisions/decision-register.md#31-g01-ph%E1%BA%A1m-vi-th%E1%BA%A9m-quy%E1%BB%81n-v%C3%A0-m%C3%B4-h%C3%ACnh-c%E1%BB%ADa-h%C3%A0ngkho), [`T7-DR-008#REQ-01`](../decisions/decision-register.md#31-g01-ph%E1%BA%A1m-vi-th%E1%BA%A9m-quy%E1%BB%81n-v%C3%A0-m%C3%B4-h%C3%ACnh-c%E1%BB%ADa-h%C3%A0ngkho), [`EXPERIENCE_MAP_AUTHORITY`](../../06.evidence/legacy-v3.10.1/implementation/legacy-harness/frozen-source/srs/08-ui-ux.md#experience-map-va-authority-giao-dien), [`UI_CONTENT_STANDARD`](../../06.evidence/legacy-v3.10.1/implementation/legacy-harness/frozen-source/srs/08-ui-ux.md#quy-uoc-noi-dung-giao-dien) |
| Trạng thái quyết định | `ACTIVE`, `OUT_OF_SCOPE`, `DEFERRED` |
| Mức bằng chứng của bài | `STATIC_VALIDATED` |
| Giới hạn | Bài xác định ranh giới phạm vi; không thiết kế quy trình tương lai cho chuyển kho, ký gửi, sản xuất hoặc chuyển đổi SKU |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-002` — Ranh giới trách nhiệm giữa các hệ thống nghiệp vụ](KB-KGV-002-ranh-gioi-trach-nhiem-giua-cac-he-thong-nghiep-vu.md)
- [`KB-KGV-034` — Quyền sở hữu hàng hóa, hàng ký gửi và hàng demo](KB-KGV-034-quyen-so-huu-hang-hoa-hang-ky-gui-va-hang-demo.md)
- [`KB-KGV-035` — Combo bán hàng và tồn kho theo thành phần](KB-KGV-035-combo-ban-hang-va-ton-kho-theo-thanh-phan.md)
- [`KB-KGV-041` — Cách kiểm soát thay đổi đối với quy tắc nghiệp vụ](KB-KGV-041-cach-kiem-soat-thay-doi-doi-voi-quy-tac-nghiep-vu.md)
