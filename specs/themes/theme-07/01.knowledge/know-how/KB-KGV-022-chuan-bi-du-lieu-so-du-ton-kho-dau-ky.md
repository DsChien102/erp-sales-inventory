---
id: KB-KGV-022-chuan-bi-du-lieu-so-du-ton-kho-dau-ky
type: know-how
theme: theme-07
title: chuan-bi-du-lieu-so-du-ton-kho-dau-ky
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-022-chuan-bi-du-lieu-so-du-ton-kho-dau-ky — chuan-bi-du-lieu-so-du-ton-kho-dau-ky

## 1. Bối cảnh

### Câu trả lời ngắn

Dữ liệu đầu kỳ phải mô tả số lượng theo sản phẩm + kho + trạng thái, kèm lô và hạn dùng khi chính sách sản phẩm yêu cầu. Mỗi dòng phải khớp master sản phẩm, kho và đơn vị tính đã tồn tại; hệ thống không tự tạo master từ file migration. Số lượng được chi tiết theo kho, nhưng tổng giá trị ghi sổ có thẩm quyền nằm ở cấp đơn vị vận hành + sản phẩm và được dùng để suy ra đơn giá chính thức khởi tạo. Chỉ lượng ở trạng thái bán được và đủ dữ liệu bắt buộc mới tăng khả dụng.

### Vì sao vấn đề này quan trọng?

Số dư đầu kỳ là nền móng của toàn bộ movement về sau. Nếu chỉ nhập tổng theo sản phẩm, hệ thống không biết hàng ở kho nào, ở trạng thái gì hoặc thuộc lô nào. Nếu ép tổng giá trị xuống từng kho như dữ liệu có thẩm quyền, migration sẽ vô tình tạo một mô hình định giá khác với vận hành sau Chuyển đổi chính thức. Kiểm tra master và dữ liệu theo dõi bắt buộc còn ngăn việc tạo sản phẩm, kho hoặc lô giả chỉ vì file nguồn có một mã chưa được chuẩn hóa.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Không được hiểu là |
|---|---|---|
| Chuyển đổi chính thức | Thời điểm chuyển quyền ghi nhận từ hệ thống cũ sang hệ thống mới. | Khoảng thời gian hai bên cùng tự do ghi tồn. |
| Số kiểm soát | Tổng số lượng và giá trị đã duyệt để đối soát batch chuyển đổi. | Một ước lượng chỉ dùng tham khảo. |

### Quy tắc vận hành

#### Mức chi tiết của số lượng đầu kỳ

Số dư đầu kỳ nhập theo sản phẩm + kho + trạng thái; bổ sung lô và hạn nếu sản phẩm yêu cầu.
#### Tổng giá trị có thẩm quyền và đơn giá khởi tạo

Nhập số lượng chi tiết theo kho nhưng tổng giá trị ghi sổ có thẩm quyền theo đơn vị vận hành + sản phẩm; hệ thống suy ra đơn giá chính thức khởi tạo. Giá trị theo kho nếu có trong file nguồn chỉ là số kiểm soát dẫn xuất.
#### Không xác nhận khi thiếu lô hoặc hạn dùng bắt buộc

Sản phẩm `LOT` không được xác nhận dòng đầu kỳ khi thiếu mã lô; nếu `expiry_required=true` thì thiếu hạn dùng cũng bị chặn.
#### Phải khớp master data đã tồn tại

Dòng đầu kỳ phải khớp sản phẩm, kho và đơn vị đã tồn tại; Hệ thống quản lý tồn kho và giá vốn không tự tạo master data.
#### Điều kiện để lượng đầu kỳ tăng khả dụng

Chỉ lượng có trạng thái bán được và đủ dữ liệu bắt buộc tăng khả dụng; trạng thái khác chỉ tăng vật lý.

### Ví dụ xuyên suốt

Sản phẩm P được quản lý theo lô và có 70 đơn vị ở WH-01, 30 ở WH-02. File đầu kỳ phải có các dòng theo kho, trạng thái và mã lô; một dòng thiếu hạn dùng bị từ chối trước khi xác nhận. Tổng giá trị có thẩm quyền của P là 10.000.000 đồng cho 100 đơn vị, nên đơn giá chính thức khởi tạo là 100.000 đồng. Cột giá trị 7 triệu và 3 triệu theo từng kho, nếu có, chỉ là số kiểm soát dẫn xuất. Trong 70 đơn vị ở WH-01, 5 đang cách ly: toàn bộ 70 tăng vật lý nhưng chỉ 65 đủ điều kiện tăng khả dụng. Mã kho hoặc sản phẩm lạ phải được sửa ở master trước, không được tạo tự động từ file.

Ví dụ này chỉ minh họa cách áp dụng các quy tắc đã nêu. Con số, tên sản phẩm và thời điểm là giả định; chúng không tạo thêm một ngoại lệ, quyền phê duyệt hay mốc ghi nhận mới.

### Ngoại lệ và những cách làm sai

- **Chỉ nhập tổng số lượng theo sản phẩm:** Thiếu kho, trạng thái và chiều theo dõi sẽ làm mất khóa số dư cần thiết.
- **Coi giá trị theo kho là có thẩm quyền:** Mô hình giá trị chính thức ở cấp đơn vị vận hành + sản phẩm; số theo kho chỉ phục vụ đối chiếu.
- **Tạo master trong lúc import:** Migration phải khớp dữ liệu đã được quản trị, không mở đường tạo mã ngoài kiểm soát.

- **Sửa trực tiếp số dư hoặc trạng thái để “làm cho đúng”:** cách này phá vỡ sổ biến động và làm mất khả năng giải thích số liệu. Mọi thay đổi chính thức phải đi qua đúng loại nghiệp vụ, có căn cứ và lịch sử.
- **Dùng dữ liệu tra cứu chậm làm căn cứ commit:** báo cáo hoặc projection có thể hữu ích để quan sát, nhưng quyết định thay đổi tồn phải kiểm tra lại dữ liệu giao dịch hiện hành.

## 3. Ý nghĩa đối với Theme

### Cách áp dụng trong thực tế

Dữ liệu phải được kiểm tra với master data, chuẩn hóa đơn vị và đối soát bằng số kiểm soát trước khi xác nhận. Batch chỉ tạo số dư khi toàn bộ điều kiện đạt và được commit nguyên tử; sau Chuyển đổi chính thức, mọi sửa đổi phải đi qua nghiệp vụ sửa sai thông thường thay vì nhập lại lịch sử.

Khi triển khai một trường hợp cụ thể, người xử lý nên ghi rõ nguồn chứng từ, đối tượng hàng, kho, trạng thái, thời điểm nghiệp vụ và kết quả mong đợi. Nếu một dữ kiện thuộc thẩm quyền của hệ thống khác chưa có, hồ sơ phải dừng ở trạng thái an toàn thay vì tự suy đoán. Nếu một bước có thể ảnh hưởng đồng thời đến nhiều số dư hoặc cả số lượng lẫn giá trị, toàn bộ thay đổi phải được commit nguyên tử và để lại dấu vết đối soát.

### Điều cần ghi nhớ

- **Số lượng đầu kỳ chi tiết theo sản phẩm, kho, trạng thái và chiều theo dõi bắt buộc.**
- **Tổng giá trị có thẩm quyền nằm ở cấp đơn vị vận hành + sản phẩm.**
- **Thiếu lô hoặc hạn dùng bắt buộc thì không được xác nhận.**
- **Chỉ lượng bán được và đủ dữ liệu mới tăng khả dụng.**

- **Khi không đủ bằng chứng để đi tiếp, hệ thống phải thất bại an toàn và giữ nguyên dữ liệu có thẩm quyền.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-022` |
| Cụm tri thức | [`KGV-C05`](00-table-of-contents.md#c05-sửa-sai-và-số-dư-đầu-kỳ) |
| Loại bài | `MIGRATION` |
| Quyết định chính | [`T7-DR-067`](../decisions/decision-register.md#39-g09-s%E1%BB%91-d%C6%B0-%C4%91%E1%BA%A7u-k%E1%BB%B3-v%C3%A0-chuy%E1%BB%83n-%C4%91%E1%BB%95i-ch%C3%ADnh-th%E1%BB%A9c), [`T7-DR-067#REQ-01`](../decisions/decision-register.md#39-g09-s%E1%BB%91-d%C6%B0-%C4%91%E1%BA%A7u-k%E1%BB%B3-v%C3%A0-chuy%E1%BB%83n-%C4%91%E1%BB%95i-ch%C3%ADnh-th%E1%BB%A9c), [`T7-DR-067#REQ-02`](../decisions/decision-register.md#39-g09-s%E1%BB%91-d%C6%B0-%C4%91%E1%BA%A7u-k%E1%BB%B3-v%C3%A0-chuy%E1%BB%83n-%C4%91%E1%BB%95i-ch%C3%ADnh-th%E1%BB%A9c), [`T7-DR-067#REQ-03`](../decisions/decision-register.md#39-g09-s%E1%BB%91-d%C6%B0-%C4%91%E1%BA%A7u-k%E1%BB%B3-v%C3%A0-chuy%E1%BB%83n-%C4%91%E1%BB%95i-ch%C3%ADnh-th%E1%BB%A9c), [`T7-DR-067#REQ-04`](../decisions/decision-register.md#39-g09-s%E1%BB%91-d%C6%B0-%C4%91%E1%BA%A7u-k%E1%BB%B3-v%C3%A0-chuy%E1%BB%83n-%C4%91%E1%BB%95i-ch%C3%ADnh-th%E1%BB%A9c), [`T7-DR-068#REQ-03`](../decisions/decision-register.md#39-g09-s%E1%BB%91-d%C6%B0-%C4%91%E1%BA%A7u-k%E1%BB%B3-v%C3%A0-chuy%E1%BB%83n-%C4%91%E1%BB%95i-ch%C3%ADnh-th%E1%BB%A9c), [`T7-DR-069#REQ-02`](../decisions/decision-register.md#39-g09-s%E1%BB%91-d%C6%B0-%C4%91%E1%BA%A7u-k%E1%BB%B3-v%C3%A0-chuy%E1%BB%83n-%C4%91%E1%BB%95i-ch%C3%ADnh-th%E1%BB%A9c) |
| Trạng thái quyết định | `ACTIVE` |
| Mức bằng chứng của bài | `STATIC_VALIDATED` |
| Giới hạn | Bài chuẩn bị nội dung dữ liệu; không mô tả finality của batch, quyền xác nhận hoặc trình tự mở khóa sau Chuyển đổi chính thức |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-003` — Kho, cửa hàng và khóa định danh số dư tồn kho](KB-KGV-003-kho-cua-hang-va-khoa-dinh-danh-so-du-ton-kho.md)
- [`KB-KGV-004` — Đơn vị tính và cách quy đổi số lượng tồn kho](KB-KGV-004-don-vi-tinh-va-cach-quy-doi-so-luong-ton-kho.md)
- [`KB-KGV-023` — Xác nhận số dư đầu kỳ, Chuyển đổi chính thức và đối soát migration](KB-KGV-023-xac-nhan-so-du-dau-ky-chuyen-doi-chinh-thuc-va-doi-soat-migration.md)
- [`KB-KGV-024` — Chọn quản lý thông thường hay quản lý theo lô](KB-KGV-024-chinh-sach-quan-ly-hang-thong-thuong-theo-lo-hoac-theo-serial.md)
