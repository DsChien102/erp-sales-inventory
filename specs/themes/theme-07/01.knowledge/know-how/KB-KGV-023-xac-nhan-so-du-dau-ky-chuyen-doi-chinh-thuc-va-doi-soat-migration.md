---
id: KB-KGV-023-xac-nhan-so-du-dau-ky-chuyen-doi-chinh-thuc-va-doi-soat-migration
type: know-how
theme: theme-07
title: xac-nhan-so-du-dau-ky-chuyen-doi-chinh-thuc-va-doi-soat-migration
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-023-xac-nhan-so-du-dau-ky-chuyen-doi-chinh-thuc-va-doi-soat-migration — xac-nhan-so-du-dau-ky-chuyen-doi-chinh-thuc-va-doi-soat-migration

## 1. Bối cảnh

### Câu trả lời ngắn

Batch số dư đầu kỳ chỉ tạo tồn chính thức sau khi kiểm tra và người có quyền độc lập xác nhận; toàn batch phải commit nguyên tử. Một thời điểm Chuyển đổi chính thức được chốt và operation thông thường bị khóa cho tới khi batch hoàn tất. Mỗi đơn vị vận hành chỉ có một batch đầu kỳ đã xác nhận; sửa sai về sau đi qua correction, reversal hoặc adjustment. Trước khi mở giao dịch, phải đối soát số lượng theo từng kho và tổng giá trị theo đơn vị vận hành + sản phẩm với số kiểm soát đã duyệt, rồi tạo báo cáo migration bất biến.

### Vì sao vấn đề này quan trọng?

Chuyển đổi chính thức là khoảnh khắc chuyển Dữ liệu gốc. Nếu giao dịch mới phát sinh trước khi số đầu kỳ hoàn tất, không thể biết movement thuộc trước hay sau mốc chuyển đổi. Nếu batch thành công từng phần, một kho có thể mở bán trong khi kho khác chưa có số dư. Việc cho phép batch đầu kỳ thứ hai còn làm lịch sử xuất hiện hai “điểm bắt đầu”. Khóa Chuyển đổi chính thức, commit nguyên tử, maker–checker và báo cáo đối soát biến migration thành một sự kiện có thể kiểm chứng và chỉ xảy ra một lần.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Không được hiểu là |
|---|---|---|
| Chuyển đổi chính thức | Thời điểm chuyển quyền ghi nhận từ hệ thống cũ sang hệ thống mới. | Khoảng thời gian hai bên cùng tự do ghi tồn. |
| Số kiểm soát | Tổng số lượng và giá trị đã duyệt để đối soát batch chuyển đổi. | Một ước lượng chỉ dùng tham khảo. |

### Quy tắc vận hành

#### Toàn batch thành công hoặc toàn batch rollback

Batch đầu kỳ chỉ tạo tồn chính thức sau kiểm tra và xác nhận; toàn batch commit nguyên tử.
#### Khóa operation thường quanh Chuyển đổi chính thức

Chốt một thời điểm Chuyển đổi chính thức; không cho operation thường phát sinh trước khi batch đầu kỳ hoàn tất.
#### Chỉ một batch đầu kỳ được xác nhận

Sau khi batch đầu kỳ xác nhận, không được nhập batch đầu kỳ thứ hai; sửa bằng correction/reversal hoặc adjustment.
#### Người lập không tự xác nhận

Người lập không tự xác nhận batch; người có quyền độc lập kiểm tra và xác nhận.
#### Đối soát và báo cáo bất biến trước khi mở khóa

Trước mở khóa phải đối soát số lượng theo từng kho và tổng giá trị có thẩm quyền theo đơn vị vận hành + sản phẩm với số kiểm soát đã duyệt; giá trị theo kho nếu báo cáo chỉ được gắn nhãn dẫn xuất. Sau đó tạo báo cáo migration bất biến.

Trong thời gian này, đơn vị vận hành ở trạng thái kích hoạt tồn kho `PREPARING`. Chỉ commit xác nhận số dư đầu kỳ và báo cáo đối soát thành công mới được chuyển nguyên tử sang `ACTIVE`. Mọi mutation tồn kho thông thường trước mốc đó phải trả lỗi có cấu trúc `INVENTORY_NOT_ACTIVATED`; không được mở khóa bằng sửa cờ quản trị.

### Ví dụ xuyên suốt

Chuyển đổi chính thức được chốt lúc 22:00 ngày 31/8. Từ mốc đó, nhập, xuất và giữ hàng thông thường bị khóa. Người lập tải batch cho kho mặc định; một dòng lô thiếu hạn bắt buộc làm validation thất bại nên không số dư nào được tạo. Sau khi sửa file, một người có quyền độc lập kiểm tra và xác nhận; transaction ghi toàn bộ số dư hoặc rollback toàn bộ. Báo cáo sau commit đối soát lượng theo kho với số kiểm soát, đồng thời đối soát tổng giá trị từng sản phẩm ở cấp toàn đơn vị vận hành. Chỉ khi các tổng khớp và báo cáo bất biến được tạo, giao dịch thường mới được mở. Một sai sót phát hiện hôm sau phải đi qua correction hoặc adjustment, không tạo batch mở đầu thứ hai.

Ví dụ này chỉ minh họa cách áp dụng các quy tắc đã nêu. Con số, tên sản phẩm và thời điểm là giả định; chúng không tạo thêm một ngoại lệ, quyền phê duyệt hay mốc ghi nhận mới.

### Ngoại lệ và những cách làm sai

- **Cho batch thành công từng kho:** Đầu kỳ phải có một finality chung; thành công bán phần phá vỡ mốc Chuyển đổi chính thức.
- **Mở giao dịch trước khi đối soát:** Movement mới sẽ làm số kiểm soát không còn so sánh được với snapshot migration.
- **Nhập lại batch để sửa lỗi:** Sau finality, sửa sai phải để lại correction chain hoặc adjustment như mọi dữ liệu chính thức khác.

- **Sửa trực tiếp số dư hoặc trạng thái để “làm cho đúng”:** cách này phá vỡ sổ biến động và làm mất khả năng giải thích số liệu. Mọi thay đổi chính thức phải đi qua đúng loại nghiệp vụ, có căn cứ và lịch sử.
- **Dùng dữ liệu tra cứu chậm làm căn cứ commit:** báo cáo hoặc projection có thể hữu ích để quan sát, nhưng quyết định thay đổi tồn phải kiểm tra lại dữ liệu giao dịch hiện hành.

## 3. Ý nghĩa đối với Theme

### Cách áp dụng trong thực tế

Dữ liệu phải được kiểm tra với master data, chuẩn hóa đơn vị và đối soát bằng số kiểm soát trước khi xác nhận. Batch chỉ tạo số dư khi toàn bộ điều kiện đạt và được commit nguyên tử; sau Chuyển đổi chính thức, mọi sửa đổi phải đi qua nghiệp vụ sửa sai thông thường thay vì nhập lại lịch sử.

Khi triển khai một trường hợp cụ thể, người xử lý nên ghi rõ nguồn chứng từ, đối tượng hàng, kho, trạng thái, thời điểm nghiệp vụ và kết quả mong đợi. Nếu một dữ kiện thuộc thẩm quyền của hệ thống khác chưa có, hồ sơ phải dừng ở trạng thái an toàn thay vì tự suy đoán. Nếu một bước có thể ảnh hưởng đồng thời đến nhiều số dư hoặc cả số lượng lẫn giá trị, toàn bộ thay đổi phải được commit nguyên tử và để lại dấu vết đối soát.

### Điều cần ghi nhớ

- **Batch đầu kỳ commit nguyên tử sau kiểm tra và xác nhận độc lập.**
- **Operation thường bị khóa từ Chuyển đổi chính thức đến khi migration hoàn tất.**
- **Chỉ có một batch đầu kỳ đã xác nhận.**
- **Đối soát lượng, tổng giá trị và báo cáo bất biến là điều kiện mở khóa.**

- **Khi không đủ bằng chứng để đi tiếp, hệ thống phải thất bại an toàn và giữ nguyên dữ liệu có thẩm quyền.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-023` |
| Cụm tri thức | [`KGV-C05`](00-table-of-contents.md#c05-sửa-sai-và-số-dư-đầu-kỳ) |
| Loại bài | `MIGRATION` |
| Quyết định chính | [`T7-DR-068`](../decisions/decision-register.md#39-g09-s%E1%BB%91-d%C6%B0-%C4%91%E1%BA%A7u-k%E1%BB%B3-v%C3%A0-chuy%E1%BB%83n-%C4%91%E1%BB%95i-ch%C3%ADnh-th%E1%BB%A9c), [`T7-DR-069`](../decisions/decision-register.md#39-g09-s%E1%BB%91-d%C6%B0-%C4%91%E1%BA%A7u-k%E1%BB%B3-v%C3%A0-chuy%E1%BB%83n-%C4%91%E1%BB%95i-ch%C3%ADnh-th%E1%BB%A9c), [`T7-DR-068#REQ-01`](../decisions/decision-register.md#39-g09-s%E1%BB%91-d%C6%B0-%C4%91%E1%BA%A7u-k%E1%BB%B3-v%C3%A0-chuy%E1%BB%83n-%C4%91%E1%BB%95i-ch%C3%ADnh-th%E1%BB%A9c), [`T7-DR-068#REQ-02`](../decisions/decision-register.md#39-g09-s%E1%BB%91-d%C6%B0-%C4%91%E1%BA%A7u-k%E1%BB%B3-v%C3%A0-chuy%E1%BB%83n-%C4%91%E1%BB%95i-ch%C3%ADnh-th%E1%BB%A9c), [`T7-DR-069#REQ-01`](../decisions/decision-register.md#39-g09-s%E1%BB%91-d%C6%B0-%C4%91%E1%BA%A7u-k%E1%BB%B3-v%C3%A0-chuy%E1%BB%83n-%C4%91%E1%BB%95i-ch%C3%ADnh-th%E1%BB%A9c), [`T7-DR-069#REQ-02`](../decisions/decision-register.md#39-g09-s%E1%BB%91-d%C6%B0-%C4%91%E1%BA%A7u-k%E1%BB%B3-v%C3%A0-chuy%E1%BB%83n-%C4%91%E1%BB%95i-ch%C3%ADnh-th%E1%BB%A9c) |
| Trạng thái quyết định | `ACTIVE` |
| Mức bằng chứng của bài | `STATIC_VALIDATED` |
| Giới hạn | Bài mô tả finality và kiểm soát migration; không quyết định công cụ import, định dạng file hoặc kế hoạch rollback hạ tầng |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-021` — Sửa sai tồn kho mà không sửa lịch sử](KB-KGV-021-sua-sai-ton-kho-khong-sua-lich-su.md)
- [`KB-KGV-022` — Chuẩn bị dữ liệu số dư tồn kho đầu kỳ](KB-KGV-022-chuan-bi-du-lieu-so-du-ton-kho-dau-ky.md)
- [`KB-KGV-029` — Tính nguyên tử khi ghi tồn kho và phát sự kiện](KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md)
- [`KB-KGV-031` — Phê duyệt Inventory Operation theo mức rủi ro](KB-KGV-031-phe-duyet-inventory-operation-theo-muc-rui-ro.md)
- [`KB-KGV-033` — Thẻ kho, báo cáo lịch sử và đối soát nguồn](KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon.md)
