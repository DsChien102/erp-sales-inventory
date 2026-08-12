---
id: KB-KGV-020-dinh-gia-hang-tra-tieu-huy-va-chenh-lech-thua-thieu
type: know-how
theme: theme-07
title: dinh-gia-hang-tra-tieu-huy-va-chenh-lech-thua-thieu
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-020-dinh-gia-hang-tra-tieu-huy-va-chenh-lech-thua-thieu — dinh-gia-hang-tra-tieu-huy-va-chenh-lech-thua-thieu

## 1. Bối cảnh

### Câu trả lời ngắn

Nghiệp vụ đặc biệt không dùng một căn cứ giá duy nhất. Trả nhà cung cấp giảm kho theo đơn giá chính thức đang hiệu lực, trong khi giảm công nợ theo giá nhà cung cấp chấp thuận và phần chênh lệch được chuyển cho hệ thống kế toán. Tiêu hủy, điều chỉnh giảm và thiếu kiểm kê dùng số lượng giảm nhân đơn giá chính thức tại lúc hoàn tất. Thừa hoặc hàng biếu tặng chỉ tăng khi có nguồn, lý do và căn cứ giá từ bên có thẩm quyền; thiếu giá thì hồ sơ ở Nháp. Hàng khách trả dùng giá đã đối soát của kỳ xuất gốc hoặc snapshot xuất nếu kỳ chưa đối soát.

### Vì sao vấn đề này quan trọng?

Một mặt hàng trả nhà cung cấp có thể được nhà cung cấp chấp thuận theo giá mua cũ trong khi kho đang dùng đơn giá bình quân mới. Hàng khách trả lại cần khôi phục giá trị theo lần bán gốc, không theo giá hiện tại. Nếu tất cả đều lấy “giá gần nhất”, tồn kho, công nợ và lợi nhuận sẽ bị trộn. Bảng căn cứ theo loại nghiệp vụ giúp tách đúng giá trị kho khỏi nghĩa vụ với đối tác và giữ chênh lệch cho hệ thống kế toán xử lý.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Không được hiểu là |
|---|---|---|
| Biến động số lượng | Ghi nhận hàng đi vào, đi ra hoặc đổi trạng thái. | Tự động đồng nghĩa với biến động giá trị. |
| Biến động giá trị | Khoản tăng, giảm hoặc điều chỉnh giá trị ghi sổ có căn cứ. | Sửa trực tiếp số tổng để làm khớp. |
| Cut-off | Mốc chốt tập giao dịch được đưa vào một lần tính hoặc đối soát. | Ngày có thể đổi tùy lúc xem báo cáo. |

### Quy tắc vận hành

#### Trả nhà cung cấp có hai căn cứ giá trị

Hệ thống quản lý tồn kho và giá vốn giảm tồn và giá trị kho theo đơn giá chính thức có hiệu lực, đồng thời gửi giá nhà cung cấp chấp thuận và phần chênh lệch cho Hệ thống kế toán. Hệ thống kế toán mới có thẩm quyền giảm công nợ và hạch toán chênh lệch.
#### Tiêu hủy và giảm kho theo giá chính thức hiện hành

Tiêu hủy hoặc điều chỉnh giảm dùng số lượng bị loại bỏ nhân đơn giá chính thức có hiệu lực tại thời điểm hoàn tất; không suy ra giá riêng theo kho/lô vì giá trị có thẩm quyền chỉ ở đơn vị vận hành + sản phẩm.
#### Thừa thiếu và hàng biếu tặng cần căn cứ có thẩm quyền

Thiếu tồn dùng căn cứ giảm giá trị tại quy tắc liên quan. Thừa và hàng biếu/tặng chỉ tăng qua operation có nguồn, lý do và căn cứ giá được Hệ thống kế toán/nguồn có thẩm quyền cung cấp; thiếu căn cứ giá thì áp dụng quy tắc liên quan và giữ operation ở Nháp. Không tự hợp thức hóa bằng sửa số dư.
#### Hàng khách trả dùng căn cứ của kỳ xuất gốc

Hàng khách trả dùng đơn giá đã đối soát của sản phẩm + kỳ xuất gốc; nếu kỳ gốc còn mở và chưa có giá đối soát thì dùng snapshot tại lần xuất. Giá trị trả được ghi thành value movement mới ở kỳ mở hiện tại, giữ liên kết kỳ gốc và không sửa hồi tố dòng xuất.

### Ví dụ xuyên suốt

Kho trả 10 đơn vị P. Đơn giá chính thức hiện hành là 105.000 đồng nên sổ kho giảm 1.050.000 đồng. Nhà cung cấp chấp thuận giảm công nợ theo 100.000 đồng mỗi đơn vị; hệ thống kế toán nhận cả 1.000.000 đồng và chênh lệch 50.000 đồng để hạch toán. Nếu tiêu hủy 4 đơn vị cùng thời điểm, kho giảm thêm 420.000 đồng. Nếu kiểm kê thừa 3 đơn vị nhưng chưa có căn cứ giá được nguồn có thẩm quyền cung cấp, operation không được tự lấy 105.000 đồng mà phải ở Nháp. Một đơn vị khách trả từ kỳ trước dùng giá đã đối soát của kỳ xuất gốc và tạo movement giá trị mới trong kỳ mở hiện tại.

Ví dụ này chỉ minh họa cách áp dụng các quy tắc đã nêu. Con số, tên sản phẩm và thời điểm là giả định; chúng không tạo thêm một ngoại lệ, quyền phê duyệt hay mốc ghi nhận mới.

### Ngoại lệ và những cách làm sai

- **Dùng giá nhà cung cấp để giảm kho:** Kho giảm theo đơn giá chính thức; giá nhà cung cấp phục vụ giảm công nợ và xác định chênh lệch.
- **Tự gán giá hiện hành cho hàng thừa:** Tăng đặc biệt cần căn cứ giá từ nguồn có thẩm quyền; thiếu thì phải giữ Nháp.
- **Sửa dòng xuất khi khách trả:** Hàng trả tạo value movement mới ở kỳ mở và giữ liên kết kỳ gốc, không hồi tố chứng từ xuất.

- **Sửa trực tiếp số dư hoặc trạng thái để “làm cho đúng”:** cách này phá vỡ sổ biến động và làm mất khả năng giải thích số liệu. Mọi thay đổi chính thức phải đi qua đúng loại nghiệp vụ, có căn cứ và lịch sử.
- **Dùng dữ liệu tra cứu chậm làm căn cứ commit:** báo cáo hoặc projection có thể hữu ích để quan sát, nhưng quyết định thay đổi tồn phải kiểm tra lại dữ liệu giao dịch hiện hành.

## 3. Ý nghĩa đối với Theme

### Cách áp dụng trong thực tế

Luôn tách biến động số lượng khỏi biến động giá trị, đồng thời xác định phiên bản đơn giá và cut-off áp dụng. Mọi chênh lệch phải được ghi thành delta có liên kết; không sửa chứng từ gốc, không ghi đè lịch sử và không tự tạo một căn cứ giá khi nguồn có thẩm quyền chưa cung cấp.

Khi triển khai một trường hợp cụ thể, người xử lý nên ghi rõ nguồn chứng từ, đối tượng hàng, kho, trạng thái, thời điểm nghiệp vụ và kết quả mong đợi. Nếu một dữ kiện thuộc thẩm quyền của hệ thống khác chưa có, hồ sơ phải dừng ở trạng thái an toàn thay vì tự suy đoán. Nếu một bước có thể ảnh hưởng đồng thời đến nhiều số dư hoặc cả số lượng lẫn giá trị, toàn bộ thay đổi phải được commit nguyên tử và để lại dấu vết đối soát.

### Điều cần ghi nhớ

- **Giá trị kho và giá trị công nợ của hàng trả nhà cung cấp có thể khác nhau.**
- **Tiêu hủy, điều chỉnh giảm và thiếu dùng giá chính thức lúc hoàn tất.**
- **Thừa hoặc biếu tặng không được tăng giá trị khi thiếu căn cứ có thẩm quyền.**
- **Hàng khách trả dùng giá của kỳ xuất gốc nhưng ghi movement mới ở kỳ hiện tại.**

- **Khi không đủ bằng chứng để đi tiếp, hệ thống phải thất bại an toàn và giữ nguyên dữ liệu có thẩm quyền.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-020` |
| Cụm tri thức | [`KGV-C04`](00-table-of-contents.md#c04-giá-vốn-và-định-giá-tồn-kho) |
| Loại bài | `VALUATION` |
| Quyết định chính | [`T7-DR-054`](../decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3), [`T7-DR-047#REQ-01`](../decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y), [`T7-DR-063`](../decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3), [`T7-DR-041#REQ-02`](../decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y), [`T7-DR-048`](../decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y), [`T7-DR-041#REQ-03`](../decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y), [`T7-DR-048#REQ-01`](../decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y) |
| Trạng thái quyết định | `ACTIVE` |
| Mức bằng chứng của bài | `STATIC_VALIDATED` |
| Giới hạn | Bài xác định căn cứ giá trị đầu vào cho các nghiệp vụ đặc biệt; không mô tả bút toán công nợ hoặc quy trình phê duyệt chi tiết |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-012` — Hàng khách trả từ tiếp nhận đến phân loại](KB-KGV-012-hang-khach-tra-tu-tiep-nhan-den-phan-loai.md)
- [`KB-KGV-013` — Trả hàng cho nhà cung cấp](KB-KGV-013-tra-hang-cho-nha-cung-cap.md)
- [`KB-KGV-014` — Hàng cận hạn, hết hạn, hư hỏng và tiêu hủy](KB-KGV-014-hang-can-han-het-han-hu-hong-va-tieu-huy.md)
- [`KB-KGV-015` — Đơn giá tồn kho chính thức và tổng giá trị ghi sổ](KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md)
