---
id: KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon
type: know-how
theme: theme-07
title: the-kho-bao-cao-lich-su-va-doi-soat-nguon
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon — the-kho-bao-cao-lich-su-va-doi-soat-nguon

## 1. Bối cảnh

### Câu trả lời ngắn

Báo cáo lịch sử hỗ trợ hai cách nhìn có nhãn rõ: theo ngày ghi nhận để bảo toàn kỳ khóa và theo ngày nghiệp vụ gốc để phân tích vận hành. Thẻ kho phải trình bày tồn đầu, movement tăng/giảm, tồn cuối và truy đến operation, chứng từ, ngày, người, kho, trạng thái và lô khi áp dụng. Mỗi báo cáo/export dùng một cut-off hoặc ledger sequence nhất quán cho toàn bộ dòng, kèm thời điểm, bộ lọc, múi giờ và cách nhìn. Đối soát nguồn dùng identity chứng từ và request; sai lệch tạo hồ sơ đối soát chứ không sửa tồn. Lịch sử operation, movement và audit được giữ tối thiểu 10 năm và archive vẫn phải truy vấn, xuất, rebuild được.

### Vì sao vấn đề này quan trọng?

Một nghiệp vụ sửa sai có thể mang ngày nghiệp vụ cũ nhưng được ghi nhận trong kỳ hiện tại. Nếu báo cáo không nói đang dùng ngày nào, cùng câu hỏi “tồn tại 31/8” sẽ cho hai kết quả mà người đọc tưởng là mâu thuẫn. Nếu từng dòng được đọc ở một thời điểm khác, tổng đầu–tăng–giảm–cuối cũng có thể không cân. Hai cách nhìn, snapshot nhất quán và khả năng drill-down giúp báo cáo vừa bảo vệ kỳ khóa vừa phục vụ phân tích vận hành, mà không biến reconciliation thành đường sửa sổ.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Không được hiểu là |
|---|---|---|
| Cut-off báo cáo | Một ledger sequence hoặc mốc dữ liệu nhất quán cho toàn bộ dòng. | Thời điểm riêng thay đổi theo từng dòng. |
| Cách nhìn thời gian | Quy ước dùng ngày ghi nhận hoặc ngày nghiệp vụ gốc. | Hai ngày được trộn trong cùng một cột không nhãn. |

### Quy tắc vận hành

#### Hai cách nhìn thời gian cho dữ liệu lịch sử

Báo cáo quá khứ có hai cách nhìn: theo ngày ghi nhận để bảo toàn kỳ khóa và theo ngày nghiệp vụ gốc để phân tích vận hành.
#### Đối soát nguồn tạo hồ sơ, không tự sửa tồn

Đối chiếu loại nguồn + chứng từ/dòng + phiên bản + request ID với operation/kết quả; sai lệch tạo hồ sơ/cảnh báo, không tự sửa tồn.
#### Nội dung và khả năng truy vết của thẻ kho

Thẻ kho thể hiện tồn đầu, movement tăng/giảm, tồn cuối và truy đến operation, chứng từ, ngày, người, kho, trạng thái và lô khi áp dụng.
#### Một cut-off nhất quán cho toàn báo cáo

Mỗi báo cáo/export dùng một cut-off/ledger sequence nhất quán cho toàn bộ dòng và ghi rõ thời điểm, bộ lọc, múi giờ và cách nhìn.
#### Lưu giữ và archive tối thiểu mười năm

Operation, movement và audit không xóa riêng lẻ; mặc định giữ tối thiểu 10 năm, archive vẫn truy vấn/xuất/dựng projection được.

### Ví dụ xuyên suốt

Một adjustment sửa sai được ghi ngày 5/9 nhưng giữ ngày nghiệp vụ gốc 30/8. Báo cáo theo ngày ghi nhận tại 31/8 không bao gồm adjustment, bảo toàn số đã khóa; báo cáo theo ngày nghiệp vụ gốc có thể đặt nó vào 30/8 để phân tích nguyên nhân vận hành. Cả hai báo cáo chụp cùng ledger sequence 8.000, múi giờ Asia/Bangkok và bộ lọc WH-01. Người dùng drill-down từ tồn cuối đến movement, operation, chứng từ và người thực hiện. Nếu chứng từ nguồn nói phiên bản khác với operation đã ghi, hệ thống mở hồ sơ đối soát và cảnh báo; không sửa movement. Dữ liệu archive sau nhiều năm vẫn phải xuất và dùng để rebuild projection.

Ví dụ này chỉ minh họa cách áp dụng các quy tắc đã nêu. Con số, tên sản phẩm và thời điểm là giả định; chúng không tạo thêm một ngoại lệ, quyền phê duyệt hay mốc ghi nhận mới.

### Ngoại lệ và những cách làm sai

- **Trộn ngày ghi nhận và ngày nghiệp vụ trong một cách nhìn:** Người đọc không thể biết số liệu bảo toàn kỳ hay mô phỏng vận hành.
- **Đọc mỗi trang báo cáo ở một cut-off mới:** Các dòng không còn cùng snapshot và tổng có thể không cân.
- **Tự sửa tồn khi chứng từ nguồn lệch:** Sai lệch phải tạo hồ sơ đối soát; mọi sửa đổi vẫn đi qua operation hợp lệ.

- **Sửa trực tiếp số dư hoặc trạng thái để “làm cho đúng”:** cách này phá vỡ sổ biến động và làm mất khả năng giải thích số liệu. Mọi thay đổi chính thức phải đi qua đúng loại nghiệp vụ, có căn cứ và lịch sử.
- **Dùng dữ liệu tra cứu chậm làm căn cứ commit:** báo cáo hoặc projection có thể hữu ích để quan sát, nhưng quyết định thay đổi tồn phải kiểm tra lại dữ liệu giao dịch hiện hành.

## 3. Ý nghĩa đối với Theme

### Cách áp dụng trong thực tế

Trước khi dựng báo cáo phải chốt cut-off, cách nhìn thời gian, múi giờ và bộ lọc cho toàn bộ tập dữ liệu. Mọi số tổng hợp phải truy được về movement và operation nguồn. Sai lệch được ghi thành hồ sơ đối soát; báo cáo không được tự sửa ledger hoặc trộn dữ liệu ở nhiều thời điểm.

Khi triển khai một trường hợp cụ thể, người xử lý nên ghi rõ nguồn chứng từ, đối tượng hàng, kho, trạng thái, thời điểm nghiệp vụ và kết quả mong đợi. Nếu một dữ kiện thuộc thẩm quyền của hệ thống khác chưa có, hồ sơ phải dừng ở trạng thái an toàn thay vì tự suy đoán. Nếu một bước có thể ảnh hưởng đồng thời đến nhiều số dư hoặc cả số lượng lẫn giá trị, toàn bộ thay đổi phải được commit nguyên tử và để lại dấu vết đối soát.

### Điều cần ghi nhớ

- **Báo cáo lịch sử phải ghi rõ cách nhìn thời gian.**
- **Thẻ kho cân tồn đầu + tăng - giảm = tồn cuối và truy được nguồn.**
- **Một export dùng cùng cut-off, bộ lọc, múi giờ và nhãn cách nhìn.**
- **Archive không làm mất khả năng truy vấn, xuất hoặc dựng lại projection.**

- **Khi không đủ bằng chứng để đi tiếp, hệ thống phải thất bại an toàn và giữ nguyên dữ liệu có thẩm quyền.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-033` |
| Cụm tri thức | [`KGV-C08`](00-table-of-contents.md#c08-quyền-phê-duyệt-sổ-và-báo-cáo) |
| Loại bài | `REPORTING` |
| Quyết định chính | [`T7-DR-085`](../decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i), [`T7-DR-086`](../decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i), [`T7-DR-087`](../decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i), [`T7-DR-085#REQ-01`](../decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i), [`T7-DR-091`](../decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i) |
| Trạng thái quyết định | `ACTIVE` |
| Mức bằng chứng của bài | `STATIC_VALIDATED` |
| Giới hạn | Bài mô tả semantics và truy vết báo cáo; không thiết kế mẫu biểu, phân quyền từng báo cáo hoặc định dạng lưu trữ archive |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-023` — Xác nhận số dư đầu kỳ, Chuyển đổi chính thức và đối soát migration](KB-KGV-023-xac-nhan-so-du-dau-ky-chuyen-doi-chinh-thuc-va-doi-soat-migration.md)
- [`KB-KGV-030` — Quyền chức năng, phạm vi kho và bảo vệ dữ liệu tài chính](KB-KGV-030-quyen-chuc-nang-pham-vi-kho-va-bao-ve-du-lieu-tai-chinh.md)
- [`KB-KGV-032` — Movement ledger, số dư dẫn xuất và phục hồi sau sự cố](KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md)
- [`KB-KGV-038` — Chỉ báo dẫn xuất và hồ sơ cần xử lý](KB-KGV-038-canh-bao-ton-kho-va-vong-doi-xu-ly.md)
- [`KB-KGV-040` — Hiệu năng và năng lực xử lý của hệ thống tồn kho](KB-KGV-040-hieu-nang-va-nang-luc-xu-ly-cua-he-thong-ton-kho.md)
