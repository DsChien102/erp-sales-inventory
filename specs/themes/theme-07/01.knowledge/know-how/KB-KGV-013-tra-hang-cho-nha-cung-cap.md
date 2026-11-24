---
id: KB-KGV-013-tra-hang-cho-nha-cung-cap
type: know-how
theme: theme-07
title: tra-hang-cho-nha-cung-cap
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-013-tra-hang-cho-nha-cung-cap — tra-hang-cho-nha-cung-cap

## 1. Bối cảnh

### Câu trả lời ngắn

Khi hàng đã được chấp thuận trả nhà cung cấp nhưng chưa bàn giao, hàng vẫn thuộc tồn vật lý nhưng chuyển sang trạng thái chờ trả và bị loại khỏi khả dụng. Tồn vật lý chỉ giảm khi kho xác nhận đã bàn giao cho nhà cung cấp hoặc đơn vị vận chuyển. Hai mốc này tách việc ra quyết định trả khỏi sự kiện hàng thực sự rời quyền kiểm soát của kho.

### Vì sao vấn đề này quan trọng?

Quyết định trả có thể được lập trước ngày nhà cung cấp đến nhận hàng. Nếu giảm vật lý ngay khi phê duyệt, sổ nói hàng đã rời kho trong khi kiện hàng vẫn nằm tại chỗ; nếu vẫn để khả dụng, nhân viên bán có thể dùng nhầm hàng đã dành để trả. Trạng thái chờ trả giải quyết cả hai: bảo toàn sự thật vật lý và ngăn lượng đó được cam kết cho nhu cầu khác cho tới khi bàn giao hoặc hủy quyết định theo một nghiệp vụ hợp lệ.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Không được hiểu là |
|---|---|---|
| Mốc nghiệp vụ | Sự kiện được người có trách nhiệm xác nhận và có ý nghĩa rõ ràng. | Một thao tác giao diện chưa hoàn tất. |
| Hoàn tất nguyên tử | Toàn bộ thay đổi liên quan cùng thành công hoặc cùng được hoàn tác. | Cho phép một vài dòng ảnh hưởng tồn trước. |

### Quy tắc vận hành

#### Bàn giao là mốc giảm tồn vật lý

Trả nhà cung cấp giảm tồn vật lý khi kho xác nhận bàn giao cho nhà cung cấp hoặc đơn vị vận chuyển.
#### Chờ trả vẫn là vật lý nhưng không khả dụng

Hàng được chấp thuận trả nhà cung cấp nhưng chưa bàn giao chuyển sang trạng thái chờ trả và bị loại khỏi khả dụng.

### Ví dụ xuyên suốt

Kho chấp thuận trả 12 hộp lỗi cho nhà cung cấp vào thứ Hai, nhưng hãng vận chuyển chỉ đến vào thứ Tư. Từ thứ Hai, 12 hộp được chuyển sang trạng thái chờ trả nên không xuất hiện trong tồn khả dụng; tổng tồn vật lý chưa giảm. Thứ Tư, nhân viên đối chiếu kiện hàng và xác nhận bàn giao. Operation trả hoàn tất làm tồn vật lý giảm 12. Nếu xe không đến, không có operation bàn giao nào được hoàn tất và sổ vẫn phản ánh hàng còn tại kho. Việc giảm công nợ hoặc xử lý chênh lệch giá nằm ở hệ thống kế toán, không phải hệ quả tự động của thay đổi trạng thái chờ trả.

Ví dụ này chỉ minh họa cách áp dụng các quy tắc đã nêu. Con số, tên sản phẩm và thời điểm là giả định; chúng không tạo thêm một ngoại lệ, quyền phê duyệt hay mốc ghi nhận mới.

### Ngoại lệ và những cách làm sai

- **Giảm vật lý khi phê duyệt trả:** Phê duyệt chỉ thay đổi quyền sử dụng; hàng chưa rời kho.
- **Để hàng chờ trả vẫn bán được:** Lượng đã dành trả nhà cung cấp phải bị loại khỏi khả dụng.
- **Dùng trạng thái chứng từ làm bằng chứng bàn giao:** Kho cần xác nhận sự kiện bàn giao thực tế cho nhà cung cấp hoặc đơn vị vận chuyển.

- **Sửa trực tiếp số dư hoặc trạng thái để “làm cho đúng”:** cách này phá vỡ sổ biến động và làm mất khả năng giải thích số liệu. Mọi thay đổi chính thức phải đi qua đúng loại nghiệp vụ, có căn cứ và lịch sử.
- **Dùng dữ liệu tra cứu chậm làm căn cứ commit:** báo cáo hoặc projection có thể hữu ích để quan sát, nhưng quyết định thay đổi tồn phải kiểm tra lại dữ liệu giao dịch hiện hành.

## 3. Ý nghĩa đối với Theme

### Cách áp dụng trong thực tế

Mỗi quy trình phải làm rõ bốn mốc: điều kiện vào, hành động xác nhận, thời điểm thay đổi chính thức và nhánh thất bại an toàn. Các bước chuẩn bị có thể thay đổi trạng thái công việc, nhưng chỉ mốc hoàn tất được quy định mới làm thay đổi số lượng hoặc giá trị có thẩm quyền.

Khi triển khai một trường hợp cụ thể, người xử lý nên ghi rõ nguồn chứng từ, đối tượng hàng, kho, trạng thái, thời điểm nghiệp vụ và kết quả mong đợi. Nếu một dữ kiện thuộc thẩm quyền của hệ thống khác chưa có, hồ sơ phải dừng ở trạng thái an toàn thay vì tự suy đoán. Nếu một bước có thể ảnh hưởng đồng thời đến nhiều số dư hoặc cả số lượng lẫn giá trị, toàn bộ thay đổi phải được commit nguyên tử và để lại dấu vết đối soát.

### Điều cần ghi nhớ

- **Chấp thuận trả làm hàng không khả dụng nhưng chưa giảm vật lý.**
- **Trạng thái chờ trả bảo vệ hàng khỏi được cam kết lại.**
- **Xác nhận bàn giao là mốc giảm tồn vật lý.**
- **Giá trị công nợ và chênh lệch thuộc quy tắc định giá/kế toán riêng.**

- **Khi không đủ bằng chứng để đi tiếp, hệ thống phải thất bại an toàn và giữ nguyên dữ liệu có thẩm quyền.**

### Deep-review BJ07 v3.9.5

- Purchase/source authorize commercial return; Theme 7 system-syncs exact allocations into `RTV_PENDING`. Kho không có thao tác duyệt/chuyển trạng thái thương mại lần hai.
- Exact pending quantity preserves stable source allocation identity and original stock-state source slices so amendment/cancel can release đúng nơi đã lấy.
- Physical mismatch is a structured observation, not a local source edit. Purchase/source must issue a new version before handover can continue.
- Actual handover is the only physical/value decrement point and creates source-agnostic immutable HandoverEvidence. Supplier commercial price never blocks the physical fact; inventory value uses official cost.

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-013` |
| Cụm tri thức | [`KGV-C03`](00-table-of-contents.md#c03-kiểm-kê-trả-hàng-và-loại-bỏ) |
| Loại bài | `PROCESS` |
| Quyết định chính | [`T7-DR-042`](../decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y), [`T7-DR-042#REQ-01`](../decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y) |
| Trạng thái quyết định | `ACTIVE` |
| Mức bằng chứng của bài | `STATIC_VALIDATED` |
| Giới hạn | Bài giải thích số lượng và trạng thái của hàng trả nhà cung cấp; không bao phủ định giá giảm kho, giảm công nợ hoặc quy trình tranh chấp với nhà cung cấp |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-020` — Định giá hàng trả, tiêu hủy và chênh lệch thừa thiếu](KB-KGV-020-dinh-gia-hang-tra-tieu-huy-va-chenh-lech-thua-thieu.md)
- [`KB-KGV-031` — Phê duyệt Inventory Operation theo mức rủi ro](KB-KGV-031-phe-duyet-inventory-operation-theo-muc-rui-ro.md)
- [`KB-KGV-034` — Quyền sở hữu hàng hóa, hàng ký gửi và hàng demo](KB-KGV-034-quyen-so-huu-hang-hoa-hang-ky-gui-va-hang-demo.md)
