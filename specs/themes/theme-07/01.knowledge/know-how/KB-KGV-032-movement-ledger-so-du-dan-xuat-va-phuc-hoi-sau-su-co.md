---
id: KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co
type: know-how
theme: theme-07
title: movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co — movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co

## 1. Bối cảnh

### Câu trả lời ngắn

Movement ledger bất biến là Dữ liệu gốc; bảng số dư chỉ là projection được tối ưu để đọc nhanh. Khi hai lớp lệch nhau, phải khóa phạm vi bị ảnh hưởng và dựng lại số dư từ ledger, không sửa tay để ép khớp. Một operation đã Hoàn tất có RPO = 0: ledger, phần transaction của balance và outbox đã commit không được mất, còn projection phải có thể tái tạo. Sau sự cố, chỉ mở lại mutation khi đã đối soát mọi UNKNOWN, xác minh ledger và kiểm tra projection; giao diện phải hiển thị trạng thái phục hồi và thời điểm dữ liệu.

### Vì sao vấn đề này quan trọng?

Bảng số dư có thể bị hỏng do lỗi projection, job cập nhật chậm hoặc sự cố lưu trữ, nhưng điều đó không được biến nó thành một sổ cạnh tranh. Nếu quản trị viên sửa số dư cho giống báo cáo mong muốn, nguyên nhân gốc và các movement bị che đi. Ledger bất biến cho phép replay, còn RPO = 0 cho operation hoàn tất xác định dữ liệu nào tuyệt đối không được mất. Recovery gate ngăn hệ thống mở bán khi kết quả chưa chắc chắn hoặc projection chưa được chứng minh đúng.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Không được hiểu là |
|---|---|---|
| Identity của yêu cầu | Định danh ổn định để nhận biết retry và liên kết kết quả. | Một mã mới cho mỗi lần gửi lại. |
| Commit nguyên tử | Tập thay đổi cùng thành công hoặc cùng rollback trong một transaction. | Một chuỗi ghi dữ liệu có thể dừng giữa chừng. |
| Kết quả cuối | Trạng thái không còn được chạy lại bằng cùng định danh nghiệp vụ. | Một lỗi tạm thời luôn có thể bấm thử lại tại chỗ. |

### Quy tắc vận hành

#### Ledger là Dữ liệu gốc, balance là projection

Movement ledger bất biến là Dữ liệu gốc; số dư là projection. Lệch thì khóa phạm vi và dựng lại, không sửa tay.
#### Operation hoàn tất có RPO bằng không

Operation đã Hoàn tất có `RPO = 0`; ledger, balance transaction và outbox đã commit không được mất; projection phải dựng lại được.
#### Điều kiện mở lại mutation sau sự cố

Sau sự cố, chỉ mở mutation khi đã đối soát `UNKNOWN`, xác minh ledger và kiểm tra projection; giao diện hiển thị trạng thái phục hồi/thời điểm dữ liệu.

### Ví dụ xuyên suốt

Sau sự cố, balance hiển thị P tại WH-01 là 97 nhưng replay movement ledger đến sequence 500 cho kết quả 95. Hệ thống khóa giữ/xuất P trong phạm vi ảnh hưởng, lưu bằng chứng lệch và dựng lại projection từ ledger; không tạo adjustment +2 hoặc sửa cột balance. Đồng thời có một operation UNKNOWN trước lúc mất kết nối. Đội vận hành đối soát dấu vết commit để xác định kết quả, xác minh ledger và outbox của mọi operation Hoàn tất còn đủ, rồi chạy kiểm tra projection mới bằng 95. Chỉ khi ba kiểm tra đều đạt mới mở mutation. Trong quá trình này giao diện thông báo đang phục hồi và mốc dữ liệu cuối đã xác nhận.

Ví dụ này chỉ minh họa cách áp dụng các quy tắc đã nêu. Con số, tên sản phẩm và thời điểm là giả định; chúng không tạo thêm một ngoại lệ, quyền phê duyệt hay mốc ghi nhận mới.

### Ngoại lệ và những cách làm sai

- **Sửa balance cho bằng ledger:** Balance phải được rebuild; sửa tay tạo một nguồn biến động không có trong ledger.
- **Mất projection đồng nghĩa mất dữ liệu nghiệp vụ:** Projection được thiết kế để dựng lại; movement và commit set của operation hoàn tất mới là dữ liệu RPO 0.
- **Mở giao dịch ngay khi dịch vụ chạy lại:** Khả dụng kỹ thuật chưa đủ; phải hoàn tất đối soát UNKNOWN, ledger và projection.

- **Sửa trực tiếp số dư hoặc trạng thái để “làm cho đúng”:** cách này phá vỡ sổ biến động và làm mất khả năng giải thích số liệu. Mọi thay đổi chính thức phải đi qua đúng loại nghiệp vụ, có căn cứ và lịch sử.
- **Dùng dữ liệu tra cứu chậm làm căn cứ commit:** báo cáo hoặc projection có thể hữu ích để quan sát, nhưng quyết định thay đổi tồn phải kiểm tra lại dữ liệu giao dịch hiện hành.

## 3. Ý nghĩa đối với Theme

### Cách áp dụng trong thực tế

Mỗi yêu cầu cần có identity ổn định, phiên bản và ranh giới transaction rõ. Trạng thái chỉ được chuyển bằng transition hợp lệ; retry phải tiếp tục trên cùng dấu vết thay vì tạo kết quả thứ hai. Dữ liệu nghiệp vụ và bản ghi phát sự kiện phải được commit nguyên tử, còn việc giao sự kiện được phục hồi bằng idempotency và đối soát.

Khi triển khai một trường hợp cụ thể, người xử lý nên ghi rõ nguồn chứng từ, đối tượng hàng, kho, trạng thái, thời điểm nghiệp vụ và kết quả mong đợi. Nếu một dữ kiện thuộc thẩm quyền của hệ thống khác chưa có, hồ sơ phải dừng ở trạng thái an toàn thay vì tự suy đoán. Nếu một bước có thể ảnh hưởng đồng thời đến nhiều số dư hoặc cả số lượng lẫn giá trị, toàn bộ thay đổi phải được commit nguyên tử và để lại dấu vết đối soát.

### Điều cần ghi nhớ

- **Movement ledger bất biến là Dữ liệu gốc duy nhất của số dư.**
- **Projection lệch phải bị khóa và dựng lại, không sửa tay.**
- **Operation Hoàn tất không được mất ledger, balance transaction hay outbox đã commit.**
- **Recovery chỉ kết thúc sau đối soát UNKNOWN, xác minh ledger và kiểm tra projection.**

- **Khi không đủ bằng chứng để đi tiếp, hệ thống phải thất bại an toàn và giữ nguyên dữ liệu có thẩm quyền.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-032` |
| Cụm tri thức | [`KGV-C08`](00-table-of-contents.md#c08-quyền-phê-duyệt-sổ-và-báo-cáo) |
| Loại bài | `TECHNICAL_KNOWLEDGE` |
| Quyết định chính | [`T7-DR-084`](../decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i), [`T7-DR-084#REQ-02`](../decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i), [`T7-DR-090`](../decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i) |
| Trạng thái quyết định | `ACTIVE` |
| Mức bằng chứng của bài | `STATIC_VALIDATED` |
| Giới hạn | Bài xác định nguyên tắc durability và recovery; không quy định kiến trúc lưu trữ, quy trình backup vật lý hoặc chỉ tiêu RTO cụ thể |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-005` — Tồn vật lý, lượng đủ điều kiện bán, lượng giữ và tồn khả dụng](KB-KGV-005-ton-vat-ly-va-ton-kha-dung.md)
- [`KB-KGV-029` — Tính nguyên tử khi ghi tồn kho và phát sự kiện](KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md)
- [`KB-KGV-033` — Thẻ kho, báo cáo lịch sử và đối soát nguồn](KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon.md)
- [`KB-KGV-040` — Hiệu năng và năng lực xử lý của hệ thống tồn kho](KB-KGV-040-hieu-nang-va-nang-luc-xu-ly-cua-he-thong-ton-kho.md)
