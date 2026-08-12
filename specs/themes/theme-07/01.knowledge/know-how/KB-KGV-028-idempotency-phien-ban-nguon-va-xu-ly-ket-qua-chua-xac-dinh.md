---
id: KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh
type: know-how
theme: theme-07
title: idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh — idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh

## 1. Bối cảnh

### Câu trả lời ngắn

Nguồn phải gửi một request ID ổn định; cùng ID luôn ánh xạ đến một operation và cùng kết quả, còn cùng ID với payload khác bị chặn. Mỗi yêu cầu còn mang phiên bản nguồn tăng dần để từ chối dữ liệu đến trễ; thay đổi đi qua hủy hoặc thay thế có liên kết. Timeout không được coi là thất bại: operation chuyển UNKNOWN và được truy vấn hoặc tiếp tục bằng cùng ID. Việc giải quyết dựa trên bằng chứng commit, không sửa tay kết quả. Hợp đồng API/event có phiên bản; thay đổi phá vỡ tương thích dùng phiên bản mới và thời gian cùng tồn tại.

### Vì sao vấn đề này quan trọng?

Mạng có thể làm mất phản hồi dù transaction đã commit, hoặc chuyển các phiên bản chứng từ đến sai thứ tự. Nếu retry tạo operation mới, một lần nhập hay xuất có thể bị ghi hai lần. Nếu hệ thống mặc định timeout là thất bại, người dùng sẽ gửi bản thay thế trong khi lần đầu đã thành công. Idempotency, version ordering và UNKNOWN bảo vệ sự thật nghiệp vụ khỏi sự không chắc chắn của truyền thông; versioning hợp đồng bảo vệ các bên tích hợp khi schema thay đổi.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Không được hiểu là |
|---|---|---|
| Identity của yêu cầu | Định danh ổn định để nhận biết retry và liên kết kết quả. | Một mã mới cho mỗi lần gửi lại. |
| Commit nguyên tử | Tập thay đổi cùng thành công hoặc cùng rollback trong một transaction. | Một chuỗi ghi dữ liệu có thể dừng giữa chừng. |
| Kết quả cuối | Trạng thái không còn được chạy lại bằng cùng định danh nghiệp vụ. | Một lỗi tạm thời luôn có thể bấm thử lại tại chỗ. |

### Quy tắc vận hành

#### Timeout chuyển UNKNOWN và tiếp tục cùng ID

Timeout không được mặc định là thất bại: operation chuyển `UNKNOWN`, được truy vấn/tiếp tục bằng cùng operation ID và không trừ kho lần hai.
#### Request ID ổn định và payload bất biến

Nguồn gửi request ID ổn định; Hệ thống quản lý tồn kho và giá vốn ánh xạ một operation và trả cùng kết quả. Cùng ID nhưng payload khác bị chặn.

Với Inventory Operation, khóa nghiệp vụ này được chuẩn hóa là `operation_request_id`. Mọi lệnh làm thay đổi dữ liệu còn phải có `idempotency_key` riêng cho invocation; hệ thống lưu `CommandReceipt` cho lệnh tạo, sửa, gửi, duyệt, thực thi, cấu hình và các mutation khác. Log/telemetry chỉ lưu các hash cần đối soát, không ghi payload nhạy cảm nguyên văn.
#### Từ chối phiên bản nguồn cũ hơn

Yêu cầu mang phiên bản nguồn tăng dần; từ chối phiên bản cũ hơn. Thay đổi bằng hủy/thay thế có liên kết.
#### Giải quyết UNKNOWN bằng bằng chứng commit

`UNKNOWN` được đối soát bằng bằng chứng commit và cùng operation ID; không có quyền sửa tay kết quả.

Ở giao diện, kết quả này phải được giải thích là **chưa xác định tác động**, không phải thất bại. Hệ thống giữ nguyên định danh, bảo toàn dữ liệu người dùng đã nhập và chỉ hiển thị các bước an toàn đã được hợp đồng cho phép như kiểm tra lại trạng thái, tiếp tục đối soát hoặc liên hệ người có quyền. Không được gợi ý tạo yêu cầu mới khi chưa có bằng chứng lần cũ chưa commit.
#### Phiên bản hóa hợp đồng tích hợp

API/event có phiên bản; thay đổi additive tương thích ngược, breaking change dùng phiên bản mới và thời gian coexistence.

### Ví dụ xuyên suốt

Nguồn gửi request R-100 để xuất 5 đơn vị, phiên bản chứng từ 7. Server commit nhưng phản hồi bị mất nên client timeout. Operation được quan sát là UNKNOWN; client truy vấn lại R-100, không tạo R-101 để thay thế. Bằng chứng outbox và movement cùng transaction cho thấy đã commit, nên trạng thái được xác nhận Hoàn tất và kết quả cũ được trả lại. Nếu nguồn gửi lại R-100 với lượng 6, hệ thống chặn vì payload khác. Nếu phiên bản 6 đến sau phiên bản 7, nó cũng bị từ chối là bản cũ. Một breaking change của payload phải đi qua API phiên bản mới, trong khi bản cũ được duy trì trong thời gian chuyển tiếp đã công bố.

Ví dụ này chỉ minh họa cách áp dụng các quy tắc đã nêu. Con số, tên sản phẩm và thời điểm là giả định; chúng không tạo thêm một ngoại lệ, quyền phê duyệt hay mốc ghi nhận mới.

### Ngoại lệ và những cách làm sai

- **Retry bằng request ID mới:** Khi chưa biết kết quả, ID mới có thể tạo một thay đổi thứ hai.
- **Cho phép cùng ID với payload mới:** Identity không còn bảo vệ idempotency nếu nội dung được thay đổi.
- **Quản trị viên sửa UNKNOWN thành thành công:** Kết quả phải được suy ra từ bằng chứng commit và cùng operation ID.

- **Sửa trực tiếp số dư hoặc trạng thái để “làm cho đúng”:** cách này phá vỡ sổ biến động và làm mất khả năng giải thích số liệu. Mọi thay đổi chính thức phải đi qua đúng loại nghiệp vụ, có căn cứ và lịch sử.
- **Dùng dữ liệu tra cứu chậm làm căn cứ commit:** báo cáo hoặc projection có thể hữu ích để quan sát, nhưng quyết định thay đổi tồn phải kiểm tra lại dữ liệu giao dịch hiện hành.

## 3. Ý nghĩa đối với Theme

### Cách áp dụng trong thực tế

Mỗi yêu cầu cần có identity ổn định, phiên bản và ranh giới transaction rõ. Trạng thái chỉ được chuyển bằng transition hợp lệ; retry phải tiếp tục trên cùng dấu vết thay vì tạo kết quả thứ hai. Dữ liệu nghiệp vụ và bản ghi phát sự kiện phải được commit nguyên tử, còn việc giao sự kiện được phục hồi bằng idempotency và đối soát.

Khi triển khai một trường hợp cụ thể, người xử lý nên ghi rõ nguồn chứng từ, đối tượng hàng, kho, trạng thái, thời điểm nghiệp vụ và kết quả mong đợi. Nếu một dữ kiện thuộc thẩm quyền của hệ thống khác chưa có, hồ sơ phải dừng ở trạng thái an toàn thay vì tự suy đoán. Nếu một bước có thể ảnh hưởng đồng thời đến nhiều số dư hoặc cả số lượng lẫn giá trị, toàn bộ thay đổi phải được commit nguyên tử và để lại dấu vết đối soát.

### Điều cần ghi nhớ

- **Request ID ổn định nhận diện retry của cùng một ý định.**
- **Phiên bản nguồn tăng dần bảo vệ khỏi yêu cầu đến sai thứ tự.**
- **UNKNOWN là chưa đủ bằng chứng, không phải thất bại.**
- **Hướng dẫn phục hồi cho UNKNOWN phải giữ cùng định danh và không tạo nguy cơ ghi nhận lần hai.**
- **Breaking change của hợp đồng cần phiên bản mới và kế hoạch coexistence.**

- **Khi không đủ bằng chứng để đi tiếp, hệ thống phải thất bại an toàn và giữ nguyên dữ liệu có thẩm quyền.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-028` |
| Cụm tri thức | [`KGV-C07`](00-table-of-contents.md#c07-inventory-operation-và-tính-toàn-vẹn-giao-dịch) |
| Loại bài | `TECHNICAL_KNOWLEDGE` |
| Quyết định chính | [`T7-DR-071`](../decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh), [`T7-DR-072`](../decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh), [`T7-DR-075`](../decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh), [`T7-DR-071`](../decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh), [`T7-DR-077`](../decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh), [`T7-DR-072`](../decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh), [`T7-DR-072`](../decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh), [`T7-DR-090#REQ-01`](../decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i) |
| Trạng thái quyết định | `ACTIVE` |
| Mức bằng chứng của bài | `STATIC_VALIDATED` |
| Giới hạn | Bài mô tả idempotency, ordering và UNKNOWN; không quy định thời gian retry, công nghệ lưu outbox hoặc SLA của từng tích hợp |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-021` — Sửa sai tồn kho mà không sửa lịch sử](KB-KGV-021-sua-sai-ton-kho-khong-sua-lich-su.md)
- [`KB-KGV-027` — Vòng đời của một Inventory Operation](KB-KGV-027-vong-doi-cua-mot-inventory-operation.md)
- [`KB-KGV-029` — Tính nguyên tử khi ghi tồn kho và phát sự kiện](KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md)
- [`KB-KGV-039` — Bán hàng khi mất kết nối: định hướng và điều kiện mở phạm vi](KB-KGV-039-ban-hang-pos-offline.md)
