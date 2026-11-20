---
id: KB-KGV-027-vong-doi-cua-mot-inventory-operation
type: know-how
theme: theme-07
title: vong-doi-cua-mot-inventory-operation
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-027-vong-doi-cua-mot-inventory-operation — vong-doi-cua-mot-inventory-operation

## 1. Bối cảnh

### Câu trả lời ngắn

Inventory Operation dùng một vòng đời thống nhất: Nháp → Chờ duyệt → Sẵn sàng → Đang xử lý → Hoàn tất, với các nhánh Từ chối duyệt, Từ chối thực thi, UNKNOWN và Đã hủy. Operation không cần duyệt đi từ Nháp sang Sẵn sàng. Payload chỉ được sửa ở Nháp; từ khi gửi duyệt hoặc Sẵn sàng, muốn đổi phải hủy và tạo bản thay thế có liên kết. Chỉ Nháp, Chờ duyệt và Sẵn sàng được hủy trực tiếp; Đang xử lý/UNKNOWN phải đối soát, còn Hoàn tất phải reversal. Từ chối thực thi là kết quả cuối và thử lại cần ID mới.

### Vì sao vấn đề này quan trọng?

Trạng thái operation vừa mô tả quyền sửa, vừa mô tả mức chắc chắn của kết quả. Nếu trộn reason code với trạng thái, hệ thống có thể tạo vô số nhánh không có finality. Nếu cho sửa payload sau duyệt, quyết định phê duyệt không còn áp dụng cho dữ liệu được thực thi. Nếu chạy lại một operation đã Từ chối thực thi bằng cùng ID, audit trail không thể phân biệt lần cũ và lần thử mới. Vòng đời thống nhất tạo một state machine có thể kiểm tra và giúp mỗi thao tác có đường phục hồi đúng.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Không được hiểu là |
|---|---|---|
| Identity của yêu cầu | Định danh ổn định để nhận biết retry và liên kết kết quả. | Một mã mới cho mỗi lần gửi lại. |
| Commit nguyên tử | Tập thay đổi cùng thành công hoặc cùng rollback trong một transaction. | Một chuỗi ghi dữ liệu có thể dừng giữa chừng. |
| Kết quả cuối | Trạng thái không còn được chạy lại bằng cùng định danh nghiệp vụ. | Một lỗi tạm thời luôn có thể bấm thử lại tại chỗ. |

### Quy tắc vận hành

#### State machine thống nhất và reason code tách biệt

Trạng thái operation thống nhất: Nháp → Chờ duyệt → Sẵn sàng → Đang xử lý → Hoàn tất; nhánh Từ chối duyệt, Từ chối thực thi, `UNKNOWN`, Đã hủy. Lỗi nghiệp vụ được biểu diễn bằng reason code của trạng thái kết quả, không mở rộng state machine thành một trạng thái riêng cho từng lỗi.
#### Payload khóa sau Nháp

Chỉ sửa khi Nháp; từ gửi duyệt hoặc Sẵn sàng, payload bị khóa. Thay đổi bằng hủy và operation thay thế có liên kết.
#### Quyền hủy phụ thuộc trạng thái

Được hủy ở Nháp, Chờ duyệt, Sẵn sàng; Đang xử lý/`UNKNOWN` phải đối soát; Hoàn tất phải reversal.
#### Từ chối thực thi là kết quả cuối

Từ chối thực thi là kết quả cuối, không ảnh hưởng tồn; retry nghiệp vụ dùng request/operation ID mới và liên kết bản bị từ chối.

#### Trình bày kết quả theo ngôn ngữ người dùng

Nhãn chính dùng tiếng Việt theo công việc, còn mã trạng thái và mã lỗi kỹ thuật chỉ là thông tin phụ để hỗ trợ và đối soát. Mỗi kết quả phải cho biết: điều gì vừa xảy ra, tác động đã `không ghi nhận`, `đã ghi nhận` hay `chưa xác định`, và người dùng được phép làm gì tiếp theo. Hướng dẫn này được suy ra từ trạng thái, quyền và hợp đồng hiện có; nó không mở transition mới hoặc cho phép vượt qua finality.

### Ví dụ xuyên suốt

Một adjustment được tạo ở Nháp và còn sửa được dòng hàng. Khi gửi duyệt, payload bị khóa và operation sang Chờ duyệt; nếu được duyệt, nó sang Sẵn sàng rồi Đang xử lý. Nếu kiểm tra lại cho thấy tồn không đủ, operation sang Từ chối thực thi và không ảnh hưởng số dư. Người dùng muốn sửa lượng phải tạo yêu cầu mới với operation ID mới, liên kết bản bị từ chối. Nếu operation đang Sẵn sàng, có thể hủy; nếu đã Đang xử lý hoặc UNKNOWN thì không được hủy mù mà phải đối soát. Nếu đã Hoàn tất, hủy chứng từ nguồn không đổi lịch sử và chỉ reversal hợp lệ mới trung hòa tác động.

Ví dụ này chỉ minh họa cách áp dụng các quy tắc đã nêu. Con số, tên sản phẩm và thời điểm là giả định; chúng không tạo thêm một ngoại lệ, quyền phê duyệt hay mốc ghi nhận mới.

### Ngoại lệ và những cách làm sai

- **Biến mỗi lỗi thành một trạng thái mới:** Mã thiếu hàng, sai lô hoặc xung đột phiên bản là reason code, không mở rộng state machine.
- **Sửa payload sau khi đã duyệt:** Bản duyệt gắn với payload bị khóa; thay đổi cần hủy và tạo bản liên kết.
- **Chạy lại Từ chối thực thi bằng cùng ID:** Đây là kết quả cuối; lần thử mới cần identity mới để audit rõ ràng.

- **Sửa trực tiếp số dư hoặc trạng thái để “làm cho đúng”:** cách này phá vỡ sổ biến động và làm mất khả năng giải thích số liệu. Mọi thay đổi chính thức phải đi qua đúng loại nghiệp vụ, có căn cứ và lịch sử.
- **Dùng dữ liệu tra cứu chậm làm căn cứ commit:** báo cáo hoặc projection có thể hữu ích để quan sát, nhưng quyết định thay đổi tồn phải kiểm tra lại dữ liệu giao dịch hiện hành.

## 3. Ý nghĩa đối với Theme

### Cách áp dụng trong thực tế

Mỗi yêu cầu cần có identity ổn định, phiên bản và ranh giới transaction rõ. Trạng thái chỉ được chuyển bằng transition hợp lệ; retry phải tiếp tục trên cùng dấu vết thay vì tạo kết quả thứ hai. Dữ liệu nghiệp vụ và bản ghi phát sự kiện phải được commit nguyên tử, còn việc giao sự kiện được phục hồi bằng idempotency và đối soát.

`operation_request_id` nhận diện ý định nghiệp vụ của Inventory Operation. `idempotency_key` nhận diện một lần gọi lệnh có thể được gửi lại và được áp dụng cho **mọi mutation**, không chỉ lệnh tạo operation. Hai khóa không được dùng thay nhau; mỗi invocation mutation có một idempotency record lưu actor, command, payload hash và kết quả để trả lại đúng response hoặc chặn cùng khóa với payload khác.

Khi triển khai một trường hợp cụ thể, người xử lý nên ghi rõ nguồn chứng từ, đối tượng hàng, kho, trạng thái, thời điểm nghiệp vụ và kết quả mong đợi. Nếu một dữ kiện thuộc thẩm quyền của hệ thống khác chưa có, hồ sơ phải dừng ở trạng thái an toàn thay vì tự suy đoán. Nếu một bước có thể ảnh hưởng đồng thời đến nhiều số dư hoặc cả số lượng lẫn giá trị, toàn bộ thay đổi phải được commit nguyên tử và để lại dấu vết đối soát.

### Điều cần ghi nhớ

- **Operation dùng một danh sách trạng thái thống nhất.**
- **Chỉ Nháp được sửa payload.**
- **Hủy trực tiếp chỉ hợp lệ trước Đang xử lý.**
- **Từ chối thực thi là final; Hoàn tất chỉ sửa bằng reversal.**
- **Thông báo kết quả phải nói rõ tác động và bước tiếp theo; mã kỹ thuật không thay thế lời giải thích cho người dùng.**

- **Khi không đủ bằng chứng để đi tiếp, hệ thống phải thất bại an toàn và giữ nguyên dữ liệu có thẩm quyền.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-027` |
| Cụm tri thức | [`KGV-C07`](00-table-of-contents.md#c07-inventory-operation-và-tính-toàn-vẹn-giao-dịch) |
| Loại bài | `TECHNICAL_KNOWLEDGE` |
| Quyết định chính | [`T7-DR-074`](../decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh), [`T7-DR-074#REQ-01`](../decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh), [`T7-DR-074#REQ-02`](../decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh), [`T7-DR-074#REQ-03`](../decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh), [`T7-DR-072`](../decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh), [`T7-DR-072`](../decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh), [`T7-DR-090#REQ-01`](../decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i) |
| Trạng thái quyết định | `ACTIVE` |
| Mức bằng chứng của bài | `STATIC_VALIDATED` |
| Giới hạn | Bài mô tả state machine và quyền sửa/hủy; không trình bày tuyến phê duyệt, thuật toán UNKNOWN hoặc commit set chi tiết |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-006` — Tính chính thức của tồn kho và nguyên tắc chống xuất âm](KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am.md)
- [`KB-KGV-021` — Sửa sai tồn kho mà không sửa lịch sử](KB-KGV-021-sua-sai-ton-kho-khong-sua-lich-su.md)
- [`KB-KGV-028` — Idempotency, phiên bản nguồn và xử lý kết quả chưa xác định](KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md)
- [`KB-KGV-029` — Tính nguyên tử khi ghi tồn kho và phát sự kiện](KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md)
- [`KB-KGV-031` — Phê duyệt Inventory Operation theo mức rủi ro](KB-KGV-031-phe-duyet-inventory-operation-theo-muc-rui-ro.md)
