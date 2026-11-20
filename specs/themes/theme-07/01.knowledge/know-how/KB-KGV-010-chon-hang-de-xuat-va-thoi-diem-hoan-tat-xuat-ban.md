---
id: KB-KGV-010-chon-hang-de-xuat-va-thoi-diem-hoan-tat-xuat-ban
type: know-how
theme: theme-07
title: chon-hang-de-xuat-va-thoi-diem-hoan-tat-xuat-ban
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-010-chon-hang-de-xuat-va-thoi-diem-hoan-tat-xuat-ban — chon-hang-de-xuat-va-thoi-diem-hoan-tat-xuat-ban

## 1. Bối cảnh

### Câu trả lời ngắn

Hàng có hạn dùng được chọn theo FEFO — hạn dùng sớm nhất trước; hàng không có hạn dùng dùng FIFO — nhập trước xuất trước. Người có quyền có thể đổi lô nhưng phải để lại lịch sử. Với đơn sỉ hoặc online, lấy hàng và đóng gói chỉ chuyển trạng thái của lượng đã giữ; tồn vật lý chỉ giảm khi xác nhận bàn giao cho khách hoặc đơn vị vận chuyển. Hủy đơn sau bàn giao không tự cộng tồn, vì hàng chỉ quay lại khi kho thực nhận qua Return Operation.

### Vì sao vấn đề này quan trọng?

Chọn đúng lô giảm rủi ro hết hạn, còn chọn đúng mốc xuất bảo đảm số kho phản ánh quyền kiểm soát hàng thực tế. Nếu giảm vật lý ngay khi pick, hàng vẫn trong kho nhưng đã biến mất khỏi sổ; nếu chỉ giảm khi giao nhưng không theo dõi trạng thái pick-pack, vận hành lại không biết phần nào đang được chuẩn bị. Việc tự cộng lại sau hủy đơn còn nguy hiểm hơn vì chứng từ có thể hủy trong khi hàng vẫn ở khách hoặc đơn vị vận chuyển.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Không được hiểu là |
|---|---|---|
| Mốc nghiệp vụ | Sự kiện được người có trách nhiệm xác nhận và có ý nghĩa rõ ràng. | Một thao tác giao diện chưa hoàn tất. |
| Hoàn tất nguyên tử | Toàn bộ thay đổi liên quan cùng thành công hoặc cùng được hoàn tác. | Cho phép một vài dòng ảnh hưởng tồn trước. |

### Quy tắc vận hành

#### FEFO, FIFO và quyền đổi lô

Xuất theo FEFO cho hàng có hạn dùng; FIFO cho hàng không có hạn dùng; người có quyền được phép đổi lô và phải để lại lịch sử.
#### Pick-pack chưa giảm vật lý; bàn giao mới giảm

Với đơn sỉ/online, tồn vật lý giảm khi xác nhận bàn giao cho khách hoặc đơn vị vận chuyển; lấy và đóng gói chỉ thay đổi trạng thái của lượng đã giữ.

Mỗi lần lưu kết quả lấy hàng thuộc một **tập phân bổ** có `allocation_set_id` và `allocation_version`; từng dòng có số thứ tự ổn định. Tại một thời điểm chỉ một version của tập phân bổ được hoạt động. Lưu đồng thời trên cùng version hoặc bàn giao bằng version đã bị thay thế phải bị từ chối, nhờ đó cùng một lượng giữ không bị phân bổ hay xuất hai lần.
#### Hủy sau bàn giao không tự nhập lại

Đơn bán bị hủy sau bàn giao không tự cộng lại tồn; chỉ Return Operation dựa trên hàng thực nhận mới tăng tồn.

### Ví dụ xuyên suốt

Đơn online cần 6 hộp. Kho có lô L1 hết hạn ngày 20/9 với 4 hộp và L2 hết hạn ngày 30/9 với 10 hộp. Khi lấy hàng, hệ thống đề xuất 4 hộp L1 và 2 hộp L2 theo FEFO. Sau khi đóng gói, 6 hộp vẫn thuộc tồn vật lý nhưng nằm trong trạng thái đã lấy hoặc đã đóng gói của lượng giữ. Khi nhân viên quét xác nhận bàn giao cho hãng vận chuyển, operation xuất hoàn tất và vật lý giảm 6. Nếu khách hủy sau mốc này, hệ thống không cộng lại. Chỉ khi kiện hàng thực sự quay về và được nhận qua Return Operation thì tồn vật lý mới tăng.

Ví dụ này chỉ minh họa cách áp dụng các quy tắc đã nêu. Con số, tên sản phẩm và thời điểm là giả định; chúng không tạo thêm một ngoại lệ, quyền phê duyệt hay mốc ghi nhận mới.

### Ngoại lệ và những cách làm sai

- **Giảm vật lý tại lúc pick:** Pick chỉ thay đổi trạng thái lượng giữ; hàng chưa rời quyền kiểm soát của kho.
- **Dùng FIFO cho hàng có hạn dùng:** Ngày nhập không thay thế hạn dùng; hàng có hạn phải ưu tiên FEFO.
- **Hủy đơn đồng nghĩa với nhập lại:** Sau bàn giao, trạng thái chứng từ không chứng minh hàng đã quay về kho.

- **Sửa trực tiếp số dư hoặc trạng thái để “làm cho đúng”:** cách này phá vỡ sổ biến động và làm mất khả năng giải thích số liệu. Mọi thay đổi chính thức phải đi qua đúng loại nghiệp vụ, có căn cứ và lịch sử.
- **Dùng dữ liệu tra cứu chậm làm căn cứ commit:** báo cáo hoặc projection có thể hữu ích để quan sát, nhưng quyết định thay đổi tồn phải kiểm tra lại dữ liệu giao dịch hiện hành.

## 3. Ý nghĩa đối với Theme

### Cách áp dụng trong thực tế

Mỗi quy trình phải làm rõ bốn mốc: điều kiện vào, hành động xác nhận, thời điểm thay đổi chính thức và nhánh thất bại an toàn. Các bước chuẩn bị có thể thay đổi trạng thái công việc, nhưng chỉ mốc hoàn tất được quy định mới làm thay đổi số lượng hoặc giá trị có thẩm quyền.

Khi triển khai một trường hợp cụ thể, người xử lý nên ghi rõ nguồn chứng từ, đối tượng hàng, kho, trạng thái, thời điểm nghiệp vụ và kết quả mong đợi. Nếu một dữ kiện thuộc thẩm quyền của hệ thống khác chưa có, hồ sơ phải dừng ở trạng thái an toàn thay vì tự suy đoán. Nếu một bước có thể ảnh hưởng đồng thời đến nhiều số dư hoặc cả số lượng lẫn giá trị, toàn bộ thay đổi phải được commit nguyên tử và để lại dấu vết đối soát.

### Điều cần ghi nhớ

- **FEFO áp dụng cho hàng có hạn dùng; FIFO cho hàng không có hạn.**
- **Đổi lô cần đúng quyền và có lịch sử.**
- **Pick và pack không giảm tồn vật lý.**
- **Bàn giao là mốc giảm vật lý; nhận trả thực tế là mốc tăng lại.**

- **Khi không đủ bằng chứng để đi tiếp, hệ thống phải thất bại an toàn và giữ nguyên dữ liệu có thẩm quyền.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-010` |
| Cụm tri thức | [`KGV-C02`](00-table-of-contents.md#c02-nhận-giữ-và-xuất-hàng) |
| Loại bài | `PROCESS` |
| Quyết định chính | [`T7-DR-030`](../decisions/decision-register.md#34-g04-kh%E1%BA%A3-d%E1%BB%A5ng-gi%E1%BB%AF-h%C3%A0ng-l%E1%BA%A5y-h%C3%A0ng-v%C3%A0-xu%E1%BA%A5t), [`T7-DR-030#REQ-01`](../decisions/decision-register.md#34-g04-kh%E1%BA%A3-d%E1%BB%A5ng-gi%E1%BB%AF-h%C3%A0ng-l%E1%BA%A5y-h%C3%A0ng-v%C3%A0-xu%E1%BA%A5t), [`T7-DR-040`](../decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y), [`T7-DR-030`](../decisions/decision-register.md#34-g04-kh%E1%BA%A3-d%E1%BB%A5ng-gi%E1%BB%AF-h%C3%A0ng-l%E1%BA%A5y-h%C3%A0ng-v%C3%A0-xu%E1%BA%A5t), [`T7-DR-030`](../decisions/decision-register.md#34-g04-kh%E1%BA%A3-d%E1%BB%A5ng-gi%E1%BB%AF-h%C3%A0ng-l%E1%BA%A5y-h%C3%A0ng-v%C3%A0-xu%E1%BA%A5t) |
| Trạng thái quyết định | `ACTIVE` |
| Mức bằng chứng của bài | `STATIC_VALIDATED` |
| Giới hạn | Bài giải thích lựa chọn lô và tính chính thức của xuất bán; không bao phủ định giá dòng xuất hoặc lỗi `UNKNOWN` khi bàn giao |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-009` — Giữ hàng và xử lý đơn không đủ tồn khả dụng](KB-KGV-009-giu-hang-va-xu-ly-don-khong-du-ton-kha-dung.md)
- [`KB-KGV-017` — Công bố giá vốn chính thức và ghi nhận giá vốn hàng bán](KB-KGV-017-cong-bo-don-gia-ton-kho-va-ghi-nhan-gia-von-xuat-ban.md)
- [`KB-KGV-024` — Chọn quản lý thông thường hay quản lý theo lô](KB-KGV-024-chinh-sach-quan-ly-hang-thong-thuong-theo-lo-hoac-theo-serial.md)
