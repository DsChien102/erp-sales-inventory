---
id: KB-KGV-012-hang-khach-tra-tu-tiep-nhan-den-phan-loai
type: know-how
theme: theme-07
title: hang-khach-tra-tu-tiep-nhan-den-phan-loai
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-012-hang-khach-tra-tu-tiep-nhan-den-phan-loai — hang-khach-tra-tu-tiep-nhan-den-phan-loai

## 1. Bối cảnh

### Câu trả lời ngắn

Hàng khách trả phải liên kết với đơn hàng và dòng hàng để truy đến đúng dòng xuất gốc. Khi nhận thực tế, hàng tăng tồn vật lý ở trạng thái chờ phân loại, chưa tăng khả dụng, đồng thời ghi giá trị một lần ở kỳ mở hiện tại theo căn cứ giá của kỳ xuất gốc. Tổng lượng nhận trả cộng dồn không được vượt lượng đã giao; kiểm tra này phải khóa nguyên tử trên dòng giao gốc. Với sản phẩm theo lô, lô thực nhận phải đối chiếu các lô đã xuất. Phân loại sau đó chỉ đổi trạng thái: hàng đạt mới trở lại khả dụng; hàng hỏng hoặc hết hạn vẫn không bán được.

### Vì sao vấn đề này quan trọng?

Một yêu cầu trả hợp lệ không tự chứng minh hàng đã quay về, đúng sản phẩm hay còn bán được. Không truy giao dịch gốc sẽ mở đường nhận sai lô, trả vượt lượng hoặc tạo tín dụng nhiều lần. Nếu đưa hàng vừa nhận trả thẳng vào khả dụng, sản phẩm hỏng có thể được bán lại trước khi phân loại. Quy trình hai mốc — nhận vật lý rồi phân loại — bảo vệ cả số lượng, chất lượng bán và khả năng đối chiếu với doanh thu hoặc hoàn tiền.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Không được hiểu là |
|---|---|---|
| Mốc nghiệp vụ | Sự kiện được người có trách nhiệm xác nhận và có ý nghĩa rõ ràng. | Một thao tác giao diện chưa hoàn tất. |
| Hoàn tất nguyên tử | Toàn bộ thay đổi liên quan cùng thành công hoặc cùng được hoàn tác. | Cho phép một vài dòng ảnh hưởng tồn trước. |

### Quy tắc vận hành

#### Nhận trả tăng vật lý ở trạng thái chờ phân loại

Hàng khách trả tăng tồn vật lý ở trạng thái chờ phân loại, chưa tăng khả dụng.
#### Phân loại quyết định khả dụng

Sau phân loại, hàng đạt chuyển khả dụng; hàng hỏng/hết hạn giữ ở trạng thái không bán được.
#### Truy đến dòng xuất gốc

Hàng khách trả liên kết đơn hàng/dòng hàng; Hệ thống quản lý tồn kho và giá vốn truy đến đúng dòng xuất gốc.
#### Giới hạn trả cộng dồn và kiểm tra nguyên tử

Tổng lượng đã nhận trả không được vượt lượng giao thực tế sau khi trừ tất cả lần trả trước; kiểm tra và cộng dồn phải khóa/commit nguyên tử trên dòng giao gốc để hai yêu cầu đồng thời không cùng vượt trần.
#### Đối chiếu lô thực nhận

Lô thực nhận phải đối chiếu với các lô đã xuất. Nếu sai lô, hồ sơ phải đi theo đường ngoại lệ có bằng chứng, không tự hợp thức hóa.

#### Combo được nhận trả theo từng thành phần tồn kho

Khi dòng bán là combo, request nhận trả phải khai các thành phần tồn kho thực nhận, số lượng cơ sở, lô nếu có và căn cứ giá trị của từng thành phần. Trần trả, đối chiếu lô và giá trị được kiểm tra trên từng thành phần so với lần xuất gốc; toàn bộ request combo cùng commit hoặc cùng rollback, không được ghi nhận một phần rồi để các thành phần còn lại ở trạng thái không xác định.

### Ví dụ xuyên suốt

Dòng giao gốc đã bàn giao 5 lọ thuộc lô L1. Khách từng trả 1 lọ và nay tạo hai yêu cầu đồng thời, mỗi yêu cầu 3 lọ. Hệ thống khóa dòng giao gốc khi kiểm tra nên chỉ một yêu cầu có thể dùng phần trần còn lại; tổng nhận trả không vượt 4 lọ còn được phép. Lô quét vào phải thuộc các lô đã xuất. Ba lọ thực nhận tăng vật lý ở trạng thái chờ phân loại, khả dụng không đổi. Sau kiểm tra, 2 lọ đạt được chuyển sang bán được, 1 lọ hỏng vẫn nằm trong vật lý nhưng không khả dụng cho đến khi có operation xử lý tiếp.

Ví dụ này chỉ minh họa cách áp dụng các quy tắc đã nêu. Con số, tên sản phẩm và thời điểm là giả định; chúng không tạo thêm một ngoại lệ, quyền phê duyệt hay mốc ghi nhận mới.

### Ngoại lệ và những cách làm sai

- **Kiểm trần riêng từng yêu cầu trả:** Hai yêu cầu hợp lệ riêng lẻ vẫn có thể làm tổng trả vượt lượng giao; phải cộng dồn trên dòng gốc.
- **Nhận trả thẳng vào khả dụng:** Hàng cần ở trạng thái chờ phân loại trước khi được xác nhận đủ điều kiện bán.
- **Chỉ đối chiếu mã sản phẩm:** Sản phẩm theo lô cần kiểm tra đúng lô đã xuất, không chỉ cùng SKU.

- **Sửa trực tiếp số dư hoặc trạng thái để “làm cho đúng”:** cách này phá vỡ sổ biến động và làm mất khả năng giải thích số liệu. Mọi thay đổi chính thức phải đi qua đúng loại nghiệp vụ, có căn cứ và lịch sử.
- **Dùng dữ liệu tra cứu chậm làm căn cứ commit:** báo cáo hoặc projection có thể hữu ích để quan sát, nhưng quyết định thay đổi tồn phải kiểm tra lại dữ liệu giao dịch hiện hành.

## 3. Ý nghĩa đối với Theme

### Cách áp dụng trong thực tế

Mỗi quy trình phải làm rõ bốn mốc: điều kiện vào, hành động xác nhận, thời điểm thay đổi chính thức và nhánh thất bại an toàn. Các bước chuẩn bị có thể thay đổi trạng thái công việc, nhưng chỉ mốc hoàn tất được quy định mới làm thay đổi số lượng hoặc giá trị có thẩm quyền.

Khi triển khai một trường hợp cụ thể, người xử lý nên ghi rõ nguồn chứng từ, đối tượng hàng, kho, trạng thái, thời điểm nghiệp vụ và kết quả mong đợi. Nếu một dữ kiện thuộc thẩm quyền của hệ thống khác chưa có, hồ sơ phải dừng ở trạng thái an toàn thay vì tự suy đoán. Nếu một bước có thể ảnh hưởng đồng thời đến nhiều số dư hoặc cả số lượng lẫn giá trị, toàn bộ thay đổi phải được commit nguyên tử và để lại dấu vết đối soát.

### Điều cần ghi nhớ

- **Hàng trả liên kết đơn/dòng và truy đến movement xuất gốc.**
- **Nhận trả tăng vật lý nhưng chưa tăng khả dụng.**
- **Trần trả là lượng giao thực tế trừ toàn bộ lượng đã nhận trả trước.**
- **Phân loại và định danh lô quyết định đường xử lý tiếp theo khi sản phẩm theo lô.**

- **Khi không đủ bằng chứng để đi tiếp, hệ thống phải thất bại an toàn và giữ nguyên dữ liệu có thẩm quyền.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-012` |
| Cụm tri thức | [`KGV-C03`](00-table-of-contents.md#c03-kiểm-kê-trả-hàng-và-loại-bỏ) |
| Loại bài | `PROCESS` |
| Quyết định chính | [`T7-DR-041`](../decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y), [`T7-DR-041#REQ-01`](../decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y), [`T7-DR-043`](../decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y), [`T7-DR-044`](../decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y), [`T7-DR-045`](../decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y), [`T7-DR-048`](../decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y), [`T7-DR-041#REQ-03`](../decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y), [`T7-DR-048#REQ-01`](../decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y) |
| Trạng thái quyết định | `ACTIVE` |
| Mức bằng chứng của bài | `STATIC_VALIDATED` |
| Giới hạn | Bài bao phủ nhận, mốc ghi giá trị và phân loại hàng khách trả; không quyết định nghiệp vụ hoàn tiền hoặc bảo hành |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-014` — Hàng cận hạn, hết hạn, hư hỏng và tiêu hủy](KB-KGV-014-hang-can-han-het-han-hu-hong-va-tieu-huy.md)
- [`KB-KGV-020` — Định giá hàng trả, tiêu hủy và chênh lệch thừa thiếu](KB-KGV-020-dinh-gia-hang-tra-tieu-huy-va-chenh-lech-thua-thieu.md)
- [`KB-KGV-025` — Danh tính và vòng đời của một lô hàng](KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md)
