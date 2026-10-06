---
id: KB-KGV-035-combo-ban-hang-va-ton-kho-theo-thanh-phan
type: know-how
theme: theme-07
title: combo-ban-hang-va-ton-kho-theo-thanh-phan
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-035-combo-ban-hang-va-ton-kho-theo-thanh-phan — combo-ban-hang-va-ton-kho-theo-thanh-phan

## 1. Bối cảnh

### Câu trả lời ngắn

Combo bán hàng là một cấu hình thương mại, không phải một SKU có số dư riêng. Hệ thống quản lý sản phẩm hoặc bán hàng sở hữu định nghĩa; khi đơn được xác nhận, nguồn gửi phiên bản và snapshot thành phần. Hệ thống kho giữ và xuất nguyên tử đúng các thành phần trong snapshot, chỉ với số nguyên combo có đủ mọi thành phần; không xuất combo thiếu. Khi khách trả, kho ghi đúng thành phần thực nhận và liên kết về các dòng xuất thành phần, không tạo một lượng “tồn combo”.

### Vì sao vấn đề này quan trọng?

Nếu vừa quản lý tồn combo vừa quản lý tồn thành phần, cùng một sản phẩm có thể bị đếm hai lần và khả dụng phụ thuộc việc đã “đóng combo” hay chưa. Cấu hình combo còn có thể đổi sau khi đơn được xác nhận; không giữ snapshot sẽ khiến một đơn cũ cần bộ thành phần mới. Mô hình combo ảo giữ sổ kho ở cấp hàng thật, trong khi snapshot bảo vệ cam kết thương mại tại thời điểm xác nhận.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Không được hiểu là |
|---|---|---|
| Mốc nghiệp vụ | Sự kiện được người có trách nhiệm xác nhận và có ý nghĩa rõ ràng. | Một thao tác giao diện chưa hoàn tất. |
| Hoàn tất nguyên tử | Toàn bộ thay đổi liên quan cùng thành công hoặc cùng được hoàn tác. | Cho phép một vài dòng ảnh hưởng tồn trước. |

### Quy tắc vận hành

#### Combo ảo, tồn kho nằm ở thành phần

Combo không có số dư riêng; Hệ thống quản lý sản phẩm/Bán hàng sở hữu định nghĩa, Hệ thống quản lý tồn kho và giá vốn giữ/xuất nguyên tử các thành phần.
#### Snapshot thành phần tại lúc xác nhận đơn

Khi xác nhận đơn, nguồn gửi phiên bản và snapshot thành phần; thay đổi cấu hình sau đó không ảnh hưởng đơn đã xác nhận.
#### Chỉ giữ và xuất số nguyên combo đầy đủ

Chỉ giữ/xuất số nguyên combo có đủ mọi thành phần; không xuất combo thiếu.
#### Trả theo thành phần thực nhận

Trả combo ghi đúng thành phần thực nhận và liên kết dòng xuất thành phần; không tạo tồn combo.

### Ví dụ xuyên suốt

Combo C gồm 2 đơn vị A và 1 đơn vị B. Kho có 5 A và 2 B nên chỉ đủ 2 combo, dù phép chia riêng cho A được 2,5. Đơn xác nhận 2 combo gửi snapshot phiên bản V3: 4 A + 2 B. Hệ thống giữ hai thành phần trong một operation nguyên tử; nếu B chỉ còn 1 thì không giữ “một phần combo thứ hai”. Sau đó cấu hình C đổi thành 1 A + 1 B, nhưng đơn đã xác nhận vẫn dùng V3. Khách trả lại 2 A và 1 B từ một combo; Return Operation ghi đúng ba đơn vị thực nhận và liên kết các dòng xuất A/B, không tăng số dư C.

Ví dụ này chỉ minh họa cách áp dụng các quy tắc đã nêu. Con số, tên sản phẩm và thời điểm là giả định; chúng không tạo thêm một ngoại lệ, quyền phê duyệt hay mốc ghi nhận mới.

### Ngoại lệ và những cách làm sai

- **Tạo số dư riêng cho combo:** Combo ảo chỉ là cấu hình bán; tồn thật nằm ở từng thành phần.
- **Đọc cấu hình hiện tại khi xuất đơn cũ:** Đơn phải dùng snapshot phiên bản đã chốt lúc xác nhận.
- **Xuất combo thiếu thành phần:** Chỉ số nguyên combo có đủ mọi thành phần mới được giữ hoặc xuất.

- **Sửa trực tiếp số dư hoặc trạng thái để “làm cho đúng”:** cách này phá vỡ sổ biến động và làm mất khả năng giải thích số liệu. Mọi thay đổi chính thức phải đi qua đúng loại nghiệp vụ, có căn cứ và lịch sử.
- **Dùng dữ liệu tra cứu chậm làm căn cứ commit:** báo cáo hoặc projection có thể hữu ích để quan sát, nhưng quyết định thay đổi tồn phải kiểm tra lại dữ liệu giao dịch hiện hành.

## 3. Ý nghĩa đối với Theme

### Cách áp dụng trong thực tế

Mỗi quy trình phải làm rõ bốn mốc: điều kiện vào, hành động xác nhận, thời điểm thay đổi chính thức và nhánh thất bại an toàn. Các bước chuẩn bị có thể thay đổi trạng thái công việc, nhưng chỉ mốc hoàn tất được quy định mới làm thay đổi số lượng hoặc giá trị có thẩm quyền.

Khi triển khai một trường hợp cụ thể, người xử lý nên ghi rõ nguồn chứng từ, đối tượng hàng, kho, trạng thái, thời điểm nghiệp vụ và kết quả mong đợi. Nếu một dữ kiện thuộc thẩm quyền của hệ thống khác chưa có, hồ sơ phải dừng ở trạng thái an toàn thay vì tự suy đoán. Nếu một bước có thể ảnh hưởng đồng thời đến nhiều số dư hoặc cả số lượng lẫn giá trị, toàn bộ thay đổi phải được commit nguyên tử và để lại dấu vết đối soát.

### Điều cần ghi nhớ

- **Combo không có tồn kho độc lập.**
- **Nguồn gửi snapshot thành phần và phiên bản tại xác nhận đơn.**
- **Giữ/xuất mọi thành phần phải nguyên tử theo số nguyên combo đủ.**
- **Hàng trả được ghi theo thành phần thực nhận và dòng xuất gốc.**

- **Khi không đủ bằng chứng để đi tiếp, hệ thống phải thất bại an toàn và giữ nguyên dữ liệu có thẩm quyền.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-035` |
| Cụm tri thức | [`KGV-C09`](00-table-of-contents.md#c09-hàng-đặc-thù-combo-bổ-sung-và-vòng-đời-master) |
| Loại bài | `PROCESS` |
| Quyết định chính | [`T7-DR-094`](../decisions/decision-register.md#313-g13-d%E1%BB%AF-li%E1%BB%87u-ch%E1%BB%A7-combo-b%E1%BB%95-sung-h%C3%A0ng-v%C3%A0-nghi%E1%BB%87p-v%E1%BB%A5-%C4%91%E1%BA%B7c-bi%E1%BB%87t), [`T7-DR-094#REQ-01`](../decisions/decision-register.md#313-g13-d%E1%BB%AF-li%E1%BB%87u-ch%E1%BB%A7-combo-b%E1%BB%95-sung-h%C3%A0ng-v%C3%A0-nghi%E1%BB%87p-v%E1%BB%A5-%C4%91%E1%BA%B7c-bi%E1%BB%87t), [`T7-DR-094#REQ-02`](../decisions/decision-register.md#313-g13-d%E1%BB%AF-li%E1%BB%87u-ch%E1%BB%A7-combo-b%E1%BB%95-sung-h%C3%A0ng-v%C3%A0-nghi%E1%BB%87p-v%E1%BB%A5-%C4%91%E1%BA%B7c-bi%E1%BB%87t), [`T7-DR-048`](../decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y), [`T7-DR-048#REQ-01`](../decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y) |
| Trạng thái quyết định | `ACTIVE` |
| Mức bằng chứng của bài | `STATIC_VALIDATED` |
| Giới hạn | Bài mô tả combo ảo; không quyết định giá bán combo, phân bổ doanh thu hoặc nghiệp vụ sản xuất/đóng gói thành một SKU mới |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-001` — Phạm vi quản lý tồn kho và giá vốn](KB-KGV-001-pham-vi-quan-ly-ton-kho-va-gia-von.md)
- [`KB-KGV-009` — Giữ hàng và xử lý đơn không đủ tồn khả dụng](KB-KGV-009-giu-hang-va-xu-ly-don-khong-du-ton-kha-dung.md)
- [`KB-KGV-010` — Chọn hàng để xuất và thời điểm hoàn tất xuất bán](KB-KGV-010-chon-hang-de-xuat-va-thoi-diem-hoan-tat-xuat-ban.md)
