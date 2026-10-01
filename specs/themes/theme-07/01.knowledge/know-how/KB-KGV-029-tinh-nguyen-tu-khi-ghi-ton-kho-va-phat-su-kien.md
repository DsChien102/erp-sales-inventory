---
id: KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien
type: know-how
theme: theme-07
title: tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien — tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien

## 1. Bối cảnh

### Câu trả lời ngắn

Một operation nhiều dòng là all-or-nothing: nếu muốn xử lý một phần, nguồn phải tách thành operation riêng. Khi hoàn tất, trạng thái operation, movement ledger, số dư, trạng thái tồn, hồ sơ lô, giá trị liên quan và outbox event phải commit trong cùng transaction; một phần lỗi thì rollback toàn bộ. Việc giao event ra ngoài không nằm trong tính chính thức của tồn kho: sau commit, outbox gửi lại cùng event ID đến khi được xác nhận và bên nhận chống trùng. Lỗi giao event không được tự đảo số dư đã commit.

### Vì sao vấn đề này quan trọng?

Một operation có thể cập nhật nhiều biểu diễn của cùng sự thật. Nếu ledger đã ghi nhưng số dư chưa đổi, hoặc lô đã phát sinh nhưng operation vẫn Đang xử lý, hệ thống tạo ra trạng thái không thể giải thích. Ngược lại, nếu transaction kho phụ thuộc vào phản hồi của hệ thống nhận event, sự cố mạng sẽ khiến commit nghiệp vụ không ổn định. Transactional outbox tách hai trách nhiệm: commit sự thật nội bộ nguyên tử, rồi giao thông báo ít nhất một lần với identity để bên nhận chống trùng.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Không được hiểu là |
|---|---|---|
| Identity của yêu cầu | Định danh ổn định để nhận biết retry và liên kết kết quả. | Một mã mới cho mỗi lần gửi lại. |
| Commit nguyên tử | Tập thay đổi cùng thành công hoặc cùng rollback trong một transaction. | Một chuỗi ghi dữ liệu có thể dừng giữa chừng. |
| Kết quả cuối | Trạng thái không còn được chạy lại bằng cùng định danh nghiệp vụ. | Một lỗi tạm thời luôn có thể bấm thử lại tại chỗ. |

### Quy tắc vận hành

#### Operation nhiều dòng là all-or-nothing

Operation nhiều dòng là all-or-nothing; muốn xử lý một phần phải tách operation riêng.
#### Commit set gồm mọi dữ liệu và outbox event

Khi hoàn tất, trạng thái operation, movement ledger, số dư, trạng thái tồn, lô, giá trị và outbox event phải commit trong cùng transaction; lỗi thì rollback toàn bộ.
#### Giao event được retry, không đảo tồn đã commit

Commit thành công không phụ thuộc việc giao event; outbox gửi lại cùng event ID đến khi nhận xác nhận, bên nhận chống trùng; không tự đảo tồn vì lỗi giao event.

### Ví dụ xuyên suốt

Operation nhập có ba dòng. Dòng thứ ba khai mã lô đã có nhưng hạn dùng xung đột nên validation thất bại; cả ba dòng rollback, không dòng nào tăng tồn. Muốn nhận hai dòng hợp lệ, nguồn phải tạo operation riêng có phạm vi rõ. Trong một operation khác, transaction commit movement, balance, hồ sơ lô và một outbox event E-500 cùng lúc rồi chuyển Hoàn tất. Hệ thống kế toán tạm thời không nhận được E-500. Operation vẫn Hoàn tất và số dư không bị đảo; outbox tiếp tục gửi cùng E-500. Nếu bên nhận đã xử lý nhưng mất phản hồi, lần giao lại được nhận diện trùng bằng event ID và không tạo hạch toán thứ hai.

Ví dụ này chỉ minh họa cách áp dụng các quy tắc đã nêu. Con số, tên sản phẩm và thời điểm là giả định; chúng không tạo thêm một ngoại lệ, quyền phê duyệt hay mốc ghi nhận mới.

### Ngoại lệ và những cách làm sai

- **Cho các dòng hợp lệ commit trước:** Điều này phá finality của operation; xử lý một phần cần tách identity nghiệp vụ.
- **Phát event trước rồi mới commit:** Bên nhận có thể thấy một sự kiện cho transaction cuối cùng đã rollback.
- **Đảo tồn khi event giao thất bại:** Sự thật nội bộ đã commit; lỗi truyền thông được phục hồi bằng outbox, retry và đối soát.

- **Sửa trực tiếp số dư hoặc trạng thái để “làm cho đúng”:** cách này phá vỡ sổ biến động và làm mất khả năng giải thích số liệu. Mọi thay đổi chính thức phải đi qua đúng loại nghiệp vụ, có căn cứ và lịch sử.
- **Dùng dữ liệu tra cứu chậm làm căn cứ commit:** báo cáo hoặc projection có thể hữu ích để quan sát, nhưng quyết định thay đổi tồn phải kiểm tra lại dữ liệu giao dịch hiện hành.

## 3. Ý nghĩa đối với Theme

### Cách áp dụng trong thực tế

Mỗi yêu cầu cần có identity ổn định, phiên bản và ranh giới transaction rõ. Trạng thái chỉ được chuyển bằng transition hợp lệ; retry phải tiếp tục trên cùng dấu vết thay vì tạo kết quả thứ hai. Dữ liệu nghiệp vụ và bản ghi phát sự kiện phải được commit nguyên tử, còn việc giao sự kiện được phục hồi bằng idempotency và đối soát.

Khi triển khai một trường hợp cụ thể, người xử lý nên ghi rõ nguồn chứng từ, đối tượng hàng, kho, trạng thái, thời điểm nghiệp vụ và kết quả mong đợi. Nếu một dữ kiện thuộc thẩm quyền của hệ thống khác chưa có, hồ sơ phải dừng ở trạng thái an toàn thay vì tự suy đoán. Nếu một bước có thể ảnh hưởng đồng thời đến nhiều số dư hoặc cả số lượng lẫn giá trị, toàn bộ thay đổi phải được commit nguyên tử và để lại dấu vết đối soát.

### Điều cần ghi nhớ

- **Operation nhiều dòng không có thành công bán phần.**
- **Movement, balance, trạng thái, identity hàng, giá trị và outbox cùng transaction.**
- **Commit kho không phụ thuộc việc bên ngoài đã nhận event.**
- **Event được gửi lại cùng ID và bên nhận phải chống xử lý trùng.**

- **Khi không đủ bằng chứng để đi tiếp, hệ thống phải thất bại an toàn và giữ nguyên dữ liệu có thẩm quyền.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-029` |
| Cụm tri thức | [`KGV-C07`](00-table-of-contents.md#c07-inventory-operation-và-tính-toàn-vẹn-giao-dịch) |
| Loại bài | `TECHNICAL_KNOWLEDGE` |
| Quyết định chính | [`T7-DR-073#REQ-01`](../decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh), [`T7-DR-073`](../decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh), [`T7-DR-076`](../decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh), [`T7-DR-072`](../decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh) |
| Trạng thái quyết định | `ACTIVE` |
| Mức bằng chứng của bài | `STATIC_VALIDATED` |
| Giới hạn | Bài mô tả ranh giới transaction và phát sự kiện; không quyết định công nghệ message broker, số lần retry hoặc chính sách dead-letter cụ thể |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-006` — Tính chính thức của tồn kho và nguyên tắc chống xuất âm](KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am.md)
- [`KB-KGV-027` — Vòng đời của một Inventory Operation](KB-KGV-027-vong-doi-cua-mot-inventory-operation.md)
- [`KB-KGV-028` — Idempotency, phiên bản nguồn và xử lý kết quả chưa xác định](KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md)
- [`KB-KGV-032` — Movement ledger, số dư dẫn xuất và phục hồi sau sự cố](KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md)
