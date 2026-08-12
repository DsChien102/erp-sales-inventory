---
id: KB-KGV-019-cac-thanh-phan-hinh-thanh-gia-nhap-thuc-te
type: know-how
theme: theme-07
title: cac-thanh-phan-hinh-thanh-gia-nhap-thuc-te
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-019-cac-thanh-phan-hinh-thanh-gia-nhap-thuc-te — cac-thanh-phan-hinh-thanh-gia-nhap-thuc-te

## 1. Bối cảnh

### Câu trả lời ngắn

Giá nhập thực tế được hình thành từ các thành phần giá trị có nguồn, phương pháp phân bổ và kỳ hiệu lực. Thuế GTGT được khấu trừ bị loại khỏi giá vốn; phần không được khấu trừ được cộng vào. Chi phí mua bổ sung nối về lần nhập gốc: kỳ còn mở thì tính lại, kỳ đã khóa thì ghi adjustment ở kỳ mở kế tiếp nhưng giữ liên kết kỳ gốc. Chiết khấu, hàng khuyến mại và true-up chỉ làm đổi số lượng khi có movement vật lý riêng. Sổ và đơn giá dùng VND; chênh lệch tỷ giá thanh toán về sau không đánh giá lại tồn đã ghi.

### Vì sao vấn đề này quan trọng?

Giá trên hóa đơn chưa chắc là toàn bộ giá nhập: còn thuế, vận chuyển, chiết khấu, hàng tặng và ngoại tệ. Nếu cộng hoặc trừ các khoản này không có nguồn và phương pháp phân bổ, cùng một nghiệp vụ có thể cho nhiều giá vốn khác nhau. Nếu chi phí đến muộn bị ghi vào kỳ cũ đã khóa, tính bất biến của báo cáo bị phá; nếu bỏ liên kết kỳ gốc, không thể giải thích sản phẩm nào được hưởng hay chịu khoản điều chỉnh. Chuẩn hóa thành phần giá trị giúp mọi thay đổi đi qua cùng một ledger.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Không được hiểu là |
|---|---|---|
| Biến động số lượng | Ghi nhận hàng đi vào, đi ra hoặc đổi trạng thái. | Tự động đồng nghĩa với biến động giá trị. |
| Biến động giá trị | Khoản tăng, giảm hoặc điều chỉnh giá trị ghi sổ có căn cứ. | Sửa trực tiếp số tổng để làm khớp. |
| Cut-off | Mốc chốt tập giao dịch được đưa vào một lần tính hoặc đối soát. | Ngày có thể đổi tùy lúc xem báo cáo. |

### Quy tắc vận hành

#### Xử lý thuế GTGT đầu vào

Thuế GTGT đầu vào được khấu trừ bị loại khỏi giá vốn; phần không được khấu trừ được tính vào giá vốn theo cấu hình thuế của giao dịch.
#### Chi phí mua bổ sung đến muộn

Chi phí mua bổ sung được nối vào giá nhập gốc; kỳ chưa khóa thì tính lại, kỳ đã khóa thì ghi adjustment ở kỳ mở kế tiếp và giữ liên kết kỳ gốc.
#### Chiết khấu, khuyến mại và thành phần phân bổ

Chiết khấu mua, hàng khuyến mại, chi phí mua và true-up được chuẩn hóa thành thành phần giá trị có nguồn, phương pháp phân bổ và kỳ hiệu lực; không thay đổi số lượng nếu không có movement vật lý.

Mỗi thành phần còn có khóa tự nhiên ổn định theo nguồn, chứng từ/dòng, loại thành phần và kỳ hiệu lực để retry không ghi trùng. Nếu thành phần đến sau làm thay đổi kết quả đã tính, hệ thống chỉ đánh dấu phạm vi sản phẩm–kỳ liên quan là cần tính lại và tạo một run kế tiếp có liên kết; không sửa ledger hoặc run cũ.
#### Đồng tiền sổ và tỷ giá nguồn

Sổ tồn và đơn giá chính thức dùng VND; tỷ giá nguồn do Hệ thống kế toán/chứng từ cung cấp; chênh lệch tỷ giá thanh toán không làm thay đổi giá trị tồn đã ghi.

### Ví dụ xuyên suốt

Lô hàng có giá mua trước thuế 100 triệu đồng và VAT 10 triệu. Nếu giao dịch được khấu trừ VAT, giá trị đầu vào để tính giá vốn là 100 triệu; nếu không được khấu trừ thì là 110 triệu. Một tuần sau phát sinh 5 triệu phí vận chuyển được phân bổ cho lô. Nếu kỳ còn mở, hệ thống nối chi phí vào lần nhập và tính lại; nếu kỳ đã khóa, 5 triệu được ghi adjustment trong kỳ mở kế tiếp với liên kết về lần nhập cũ. Hóa đơn bằng USD dùng tỷ giá do chứng từ hoặc hệ thống kế toán cung cấp để quy đổi sang VND. Chênh lệch khi thanh toán USD sau đó thuộc kế toán, không đổi giá trị tồn đã ghi.

Ví dụ này chỉ minh họa cách áp dụng các quy tắc đã nêu. Con số, tên sản phẩm và thời điểm là giả định; chúng không tạo thêm một ngoại lệ, quyền phê duyệt hay mốc ghi nhận mới.


#### DirectCostBasis và làm tròn deterministic

Một giá nhập trực tiếp có thể được chứng minh bởi nhiều component/source cùng lúc. Hệ thống dựng complete `DirectCostBasis` gồm giá mua, discount, known purchase cost, tax treatment, FX và allocation provenance. Hai nguồn chỉ được coi là cùng căn cứ khi toàn basis tương đương về fact làm thay đổi giá trị; không chỉ vì cùng unit price. Allocation/rounding phải deterministic theo policy/version và stable scope order. Khi xác nhận từng phần, amount lần này được tính theo cumulative target trừ amount đã confirm trước để tổng cuối cùng không phụ thuộc cách chia partial.

### Ngoại lệ và những cách làm sai

- **Luôn cộng toàn bộ VAT vào giá vốn:** Phần được khấu trừ phải bị loại; xử lý phụ thuộc cấu hình thuế của giao dịch.
- **Ghi chi phí muộn ngược vào kỳ khóa:** Kỳ khóa giữ nguyên; adjustment được ghi ở kỳ mở kế tiếp và liên kết kỳ gốc.
- **Đổi số lượng vì một khoản chiết khấu:** Thành phần giá trị không tạo movement vật lý nếu thực tế hàng không tăng hoặc giảm.

- **Sửa trực tiếp số dư hoặc trạng thái để “làm cho đúng”:** cách này phá vỡ sổ biến động và làm mất khả năng giải thích số liệu. Mọi thay đổi chính thức phải đi qua đúng loại nghiệp vụ, có căn cứ và lịch sử.
- **Dùng dữ liệu tra cứu chậm làm căn cứ commit:** báo cáo hoặc projection có thể hữu ích để quan sát, nhưng quyết định thay đổi tồn phải kiểm tra lại dữ liệu giao dịch hiện hành.

## 3. Ý nghĩa đối với Theme

### Cách áp dụng trong thực tế

Luôn tách biến động số lượng khỏi biến động giá trị, đồng thời xác định phiên bản đơn giá và cut-off áp dụng. Mọi chênh lệch phải được ghi thành delta có liên kết; không sửa chứng từ gốc, không ghi đè lịch sử và không tự tạo một căn cứ giá khi nguồn có thẩm quyền chưa cung cấp.

Khi triển khai một trường hợp cụ thể, người xử lý nên ghi rõ nguồn chứng từ, đối tượng hàng, kho, trạng thái, thời điểm nghiệp vụ và kết quả mong đợi. Nếu một dữ kiện thuộc thẩm quyền của hệ thống khác chưa có, hồ sơ phải dừng ở trạng thái an toàn thay vì tự suy đoán. Nếu một bước có thể ảnh hưởng đồng thời đến nhiều số dư hoặc cả số lượng lẫn giá trị, toàn bộ thay đổi phải được commit nguyên tử và để lại dấu vết đối soát.

### Điều cần ghi nhớ

- **Mỗi thành phần giá nhập cần nguồn, phương pháp phân bổ và kỳ hiệu lực.**
- **VAT được khấu trừ không vào giá vốn; phần không khấu trừ thì có.**
- **Chi phí đến muộn giữ liên kết lần nhập và tôn trọng kỳ khóa.**
- **Sổ tồn dùng VND; chênh lệch tỷ giá thanh toán không đánh giá lại tồn.**

- **Khi không đủ bằng chứng để đi tiếp, hệ thống phải thất bại an toàn và giữ nguyên dữ liệu có thẩm quyền.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-019` |
| Cụm tri thức | [`KGV-C04`](00-table-of-contents.md#c04-giá-vốn-và-định-giá-tồn-kho) |
| Loại bài | `VALUATION` |
| Quyết định chính | [`T7-DR-051`](../decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3), [`T7-DR-058`](../decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3), [`T7-DR-061`](../decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3), [`T7-DR-062`](../decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3), [`T7-DR-058`](../decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3), [`T7-DR-058`](../decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3) |
| Trạng thái quyết định | `ACTIVE` |
| Mức bằng chứng của bài | `STATIC_VALIDATED` |
| Giới hạn | Bài giải thích thành phần giá nhập; không thay thế chính sách thuế, công thức phân bổ chi tiết hoặc hạch toán chênh lệch tỷ giá của hệ thống kế toán |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-008` — Hàng đã nhận nhưng chưa chốt giá và điều kiện đưa vào bán](KB-KGV-008-hang-da-nhan-nhung-chua-chot-gia.md)
- [`KB-KGV-015` — Đơn giá tồn kho chính thức và tổng giá trị ghi sổ](KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md)
- [`KB-KGV-018` — Đối soát giá vốn cuối kỳ và cập nhật đột xuất giữa kỳ](KB-KGV-018-doi-soat-gia-von-cuoi-ky-va-cap-nhat-dot-xuat-giua-ky.md)
