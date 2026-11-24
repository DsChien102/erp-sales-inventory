---
id: KB-KGV-004-don-vi-tinh-va-cach-quy-doi-so-luong-ton-kho
type: know-how
theme: theme-07
title: don-vi-tinh-va-cach-quy-doi-so-luong-ton-kho
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-004-don-vi-tinh-va-cach-quy-doi-so-luong-ton-kho — don-vi-tinh-va-cach-quy-doi-so-luong-ton-kho

## 1. Bối cảnh

### Câu trả lời ngắn

Người dùng có thể mua, bán hoặc kiểm đếm bằng nhiều đơn vị tính thuận tiện, nhưng số dư phải được quy đổi và lưu theo một đơn vị cơ sở ổn định. Mỗi dòng chứng từ cần giữ lượng giao dịch, lượng cơ sở, hệ số quy đổi và phiên bản hệ số đã dùng. Mở một thùng thành các đơn vị lẻ của cùng sản phẩm không tạo movement vì số dư vốn đã ở đơn vị cơ sở. Sau khi sản phẩm đã có movement, không được đổi đơn vị cơ sở bằng một chỉnh sửa cấu hình thông thường.

### Vì sao vấn đề này quan trọng?

Nếu một kho vừa lưu “thùng” vừa lưu “chai” như hai số dư độc lập, phép cộng, kiểm kê và chống xuất âm sẽ phụ thuộc vào cách người dùng nhập chứng từ. Hệ số quy đổi còn có thể thay đổi theo thời gian, nên chỉ giữ hệ số hiện tại sẽ làm chứng từ cũ cho kết quả khác khi đọc lại. Đơn vị cơ sở tạo một thước đo duy nhất cho tồn kho; snapshot tỷ lệ bảo vệ lịch sử và cho phép giải thích vì sao một giao dịch đã tạo ra lượng cơ sở cụ thể.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Không được hiểu là |
|---|---|---|
| Dữ liệu có thẩm quyền | Dữ liệu được nguồn sở hữu cam kết và dùng để ra quyết định chính thức. | Bản sao tra cứu có thể cập nhật chậm. |
| Dữ liệu dẫn xuất | Kết quả tính từ dữ liệu nguồn theo một công thức xác định. | Một sổ mới có thể sửa độc lập. |

### Quy tắc vận hành

#### Lưu số dư theo đơn vị cơ sở và giữ snapshot quy đổi

Giao dịch được phép dùng nhiều đơn vị tính nhưng tồn luôn quy đổi và lưu theo đơn vị cơ sở. Chứng từ giữ cả lượng giao dịch, lượng cơ sở, tỷ lệ và phiên bản tỷ lệ.
#### Mở bao gói không tạo movement

Mở thùng thành đơn vị lẻ của cùng sản phẩm không tạo movement vì tồn đã lưu theo đơn vị cơ sở.
#### Không đổi đơn vị cơ sở sau khi đã phát sinh biến động

Không đổi đơn vị cơ sở sau movement; phải migration có kiểm soát hoặc tạo sản phẩm mới. Hệ số đơn vị phụ có version hiệu lực và lịch sử giữ snapshot cũ.

Đây là kiểm soát bắt buộc ở tầng nghiệp vụ, không chỉ là cảnh báo giao diện. Khi sản phẩm đã có movement, mọi yêu cầu sửa trực tiếp đơn vị cơ sở phải bị từ chối; người dùng chỉ có thể chọn một hồ sơ sản phẩm mới hoặc một migration có version, phạm vi, đối soát và lịch sử riêng.

### Ví dụ xuyên suốt

Sản phẩm thức ăn có đơn vị cơ sở là gói và một thùng hiện được cấu hình bằng 24 gói. Kho nhận 10 thùng nên chứng từ giữ 10 thùng, hệ số 24 và lượng cơ sở 240 gói. Khi nhân viên mở một thùng để bán lẻ, không có hàng nào đi vào hoặc rời kho: số dư vẫn là 240 gói, chỉ hình thức bao gói vật lý thay đổi. Nếu từ tháng sau nhà cung cấp đóng 20 gói mỗi thùng, giao dịch mới dùng phiên bản hệ số 20; lần nhập cũ vẫn được giải thích bằng snapshot 24. Muốn đổi đơn vị cơ sở phải thực hiện migration có kiểm soát hoặc tạo sản phẩm mới.

Ví dụ này chỉ minh họa cách áp dụng các quy tắc đã nêu. Con số, tên sản phẩm và thời điểm là giả định; chúng không tạo thêm một ngoại lệ, quyền phê duyệt hay mốc ghi nhận mới.

### Ngoại lệ và những cách làm sai

- **Lưu thùng và gói như hai tồn kho:** Điều này tạo nguy cơ đếm trùng cùng một lượng hàng.
- **Tạo xuất thùng rồi nhập gói khi mở bao:** Đây không phải biến động vật lý của cùng sản phẩm nên movement giả sẽ làm sai lịch sử.
- **Dùng hệ số hiện hành để tính lại chứng từ cũ:** Lịch sử phải dùng phiên bản tỷ lệ đã được snapshot tại thời điểm giao dịch.

- **Sửa trực tiếp số dư hoặc trạng thái để “làm cho đúng”:** cách này phá vỡ sổ biến động và làm mất khả năng giải thích số liệu. Mọi thay đổi chính thức phải đi qua đúng loại nghiệp vụ, có căn cứ và lịch sử.
- **Dùng dữ liệu tra cứu chậm làm căn cứ commit:** báo cáo hoặc projection có thể hữu ích để quan sát, nhưng quyết định thay đổi tồn phải kiểm tra lại dữ liệu giao dịch hiện hành.

## 3. Ý nghĩa đối với Theme

### Cách áp dụng trong thực tế

Khi áp dụng, cần khóa đúng định nghĩa và khóa định danh trước khi tính toán. Dữ liệu đầu vào phải được chuẩn hóa về cùng đơn vị và cùng thời điểm đọc. Kết quả dẫn xuất chỉ phục vụ đúng mục đích đã nêu; không được dùng một số tổng hợp để thay thế sổ biến động hoặc che đi trạng thái nghiệp vụ bên dưới.

Khi triển khai một trường hợp cụ thể, người xử lý nên ghi rõ nguồn chứng từ, đối tượng hàng, kho, trạng thái, thời điểm nghiệp vụ và kết quả mong đợi. Nếu một dữ kiện thuộc thẩm quyền của hệ thống khác chưa có, hồ sơ phải dừng ở trạng thái an toàn thay vì tự suy đoán. Nếu một bước có thể ảnh hưởng đồng thời đến nhiều số dư hoặc cả số lượng lẫn giá trị, toàn bộ thay đổi phải được commit nguyên tử và để lại dấu vết đối soát.

### Điều cần ghi nhớ

- **Mọi số dư được lưu theo đơn vị cơ sở.**
- **Dòng giao dịch giữ cả lượng nhập, lượng cơ sở, hệ số và phiên bản hệ số.**
- **Mở bao gói cùng sản phẩm không tạo movement.**
- **Đơn vị cơ sở không được đổi tùy ý sau khi đã có movement.**

- **Khi không đủ bằng chứng để đi tiếp, hệ thống phải thất bại an toàn và giữ nguyên dữ liệu có thẩm quyền.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-004` |
| Cụm tri thức | [`KGV-C01`](00-table-of-contents.md#c01-nền-tảng-quản-lý-tồn-kho) |
| Loại bài | `CONCEPT` |
| Quyết định chính | [`T7-DR-011`](../decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i), [`T7-DR-011`](../decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i), [`T7-DR-011#REQ-01`](../decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i), [`T7-DR-097`](../decisions/decision-register.md#313-g13-d%E1%BB%AF-li%E1%BB%87u-ch%E1%BB%A7-combo-b%E1%BB%95-sung-h%C3%A0ng-v%C3%A0-nghi%E1%BB%87p-v%E1%BB%A5-%C4%91%E1%BA%B7c-bi%E1%BB%87t) |
| Trạng thái quyết định | `ACTIVE` |
| Mức bằng chứng của bài | `STATIC_VALIDATED` |
| Giới hạn | Bài giải thích quy đổi đơn vị; không quyết định cách quản lý bao bì riêng, chuyển đổi giữa hai SKU hoặc chính sách làm tròn của chứng từ nguồn |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-003` — Kho, cửa hàng và khóa định danh số dư tồn kho](KB-KGV-003-kho-cua-hang-va-khoa-dinh-danh-so-du-ton-kho.md)
- [`KB-KGV-007` — Nhận hàng mua và xử lý chênh lệch giao nhận](KB-KGV-007-nhan-hang-mua-va-xu-ly-chenh-lech-giao-nhan.md)
- [`KB-KGV-022` — Chuẩn bị dữ liệu số dư tồn kho đầu kỳ](KB-KGV-022-chuan-bi-du-lieu-so-du-ton-kho-dau-ky.md)
- [`KB-KGV-037` — Ngừng kinh doanh sản phẩm và điều kiện quản trị kho](KB-KGV-037-ngung-kinh-doanh-san-pham-va-dong-kho.md)
