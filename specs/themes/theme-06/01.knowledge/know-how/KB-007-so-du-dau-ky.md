---
id: KB-007
type: know-how
theme: theme-06
title: Số dư đầu kỳ khi bắt đầu sử dụng VET45
owner: BA
status: IN_REVIEW
---

# KB-007 — Số dư đầu kỳ khi bắt đầu sử dụng VET45

## 1. Bối cảnh

Ngày đầu An Phú chuyển sang sử dụng VET45, Nam thấy phần công nợ chưa có dữ liệu. Cậu nhìn cuốn sổ Lan mang theo rồi hỏi:

> “Phần mềm mới chưa có giao dịch. Vậy mình bắt đầu từ số không, đúng không chị?”

Lan mở trang ghi công nợ Bình Minh. Có những món hàng đã bán trước ngày dùng hệ thống mới, tiền vẫn chưa thu hết. An Phú cũng còn khoản phải trả từ lần mua hàng trước đó.

Phần mềm bắt đầu hôm nay, nhưng quan hệ mua bán không bắt đầu hôm nay. **Một hệ thống chưa có dữ liệu không có nghĩa doanh nghiệp không còn công nợ.**

Ví dụ dưới đây kể riêng thời điểm chuyển sang sử dụng VET45. Những số tiền và giao dịch cũ là giả định để giải thích số dư đầu kỳ, không nối tiếp số dư ở các bài khác.

## 2. Nội dung nền tảng

### Mang theo phần còn lại, không bắt đầu lại việc mua bán

Trong sổ cũ, Lan có một giao dịch bán cho Bình Minh trị giá 10 triệu đồng. Trước khi An Phú bắt đầu dùng VET45, Bình Minh đã thanh toán 4 triệu và phần tiền này đã được ghi nhận cho đúng khoản nợ. Số còn phải thu tại thời điểm chuyển sang hệ thống mới là 6 triệu.

Ở chiều mua, An Phú từng có khoản phải trả Bình Minh 9 triệu đồng. Cửa hàng đã trả và ghi nhận thanh toán 6 triệu. Phần còn phải trả là 3 triệu.

Lan viết lại cách đi từ giá trị ban đầu đến phần còn lại. Đơn vị trong bảng là **triệu đồng**:

| Khoản đã có trước ngày dùng VET45 | Giá trị ban đầu | Đã thanh toán trước khi chuyển | Còn lại tại thời điểm chuyển |
|---|---:|---:|---:|
| Phải thu Bình Minh | 10 | 4 | 6 |
| Phải trả Bình Minh | 9 | 6 | 3 |

Con số cần hiểu khi khởi tạo công nợ là phần **còn lại** tại thời điểm chuyển: phải thu 6 triệu và phải trả 3 triệu. Đó là công nợ đã tồn tại, không phải giao dịch mua hoặc bán mới phát sinh trong ngày đầu dùng phần mềm.

Trong phạm vi bài này, số dư đầu kỳ là cách đưa phần công nợ tồn tại trước thời điểm bắt đầu sử dụng vào theo dõi. Không được hiểu rằng cứ đến đầu một tháng là tự tạo thêm một nghĩa vụ giống khoản đang còn.

### Vì sao không tạo lại đơn bán và đơn mua cho tiện?

Nam đề nghị nhập một đơn bán mới 6 triệu và một đơn mua mới 3 triệu. Hai số có vẻ khớp với phần còn lại, và cậu đã quen nhìn công nợ phát sinh từ mua bán.

Lan hỏi: “Nhưng hôm nay mình có bán thêm 6 triệu và mua thêm 3 triệu trong câu chuyện này không?”

Câu trả lời là không. Nếu tạo hai giao dịch mới để thay cho số dư đầu kỳ, người đọc sẽ hiểu sai nguồn phát sinh. Sáu triệu phải thu đến từ phần chưa thanh toán của giao dịch cũ, không phải một lần bán mới trị giá 6 triệu.

Lựa chọn đã chốt của VET45 là hỗ trợ số dư đầu kỳ và không giả lập nó thành giao dịch bán hoặc mua mới. Nhờ đó, người xem có thể phân biệt công nợ được mang sang khi bắt đầu sử dụng với công nợ phát sinh từ các giao dịch về sau.

Bảng ở trên chỉ minh họa cách hiểu con số. Nó không phải mẫu nhập dữ liệu và không quyết định rằng hệ thống bắt buộc nhập theo từng chứng từ cũ hay gộp theo đối tác.

### Đừng trừ lại khoản tiền đã nằm trong số dư đầu kỳ

Nam nhìn 4 triệu Bình Minh đã trả trước đây và hỏi có cần ghi thêm một khoản thu 4 triệu trong hệ thống mới để giảm tiếp khoản phải thu 6 triệu không.

Lan chỉ vào phép tính: 6 triệu đã là kết quả sau khi trừ 4 triệu khỏi 10 triệu. Nếu lại coi 4 triệu cũ là một lần thanh toán mới để trừ tiếp, số còn lại sẽ thành 2 triệu, không còn phản ánh khoản thực tế chưa được thanh toán trong ví dụ.

Câu hỏi cần hỏi ở đây là: “Con số đang mang sang đã bao gồm những việc gì trước đó?” Không thể vừa dùng số dư sau thanh toán, vừa xử lý lại chính khoản thanh toán cũ như thể chưa từng được tính.

Bài không quy định cách lưu hồ sơ lịch sử. Nó chỉ chỉ ra nguy cơ tính hai lần khi nhầm giá trị ban đầu với phần còn lại tại thời điểm chuyển.

### Có cùng đối tác cũng không chỉ mang sang số chênh lệch

Phải thu 6 triệu và phải trả 3 triệu đều thuộc Bình Minh. Nam tính được chênh lệch 3 triệu nghiêng về phải thu.

Nhưng nếu chỉ giữ câu “Bình Minh còn nợ 3 triệu”, phần phải trả 3 triệu của An Phú sẽ không còn được giải thích. Phép tính không chứng minh hai bên đã cấn trừ.

Trong tình huống đang kể, chưa có nghiệp vụ cấn trừ. Vì vậy, khi hiểu công nợ đầu kỳ, vẫn cần phân biệt hai chiều và nguồn của chúng. Việc xử lý chúng về sau là câu chuyện thanh toán hoặc cấn trừ riêng, không phải kết quả tự động của việc bắt đầu dùng hệ thống.

## 3. Ý nghĩa đối với nghiệp vụ công nợ

Số dư đầu kỳ thuộc giai đoạn 1 và nằm trong phạm vi của nghiệp vụ công nợ. Nó giải quyết một điểm bắt đầu khác với mua bán mới: các nghĩa vụ đã có trước khi chuyển sang VET45 nhưng vẫn còn phần cần theo dõi.

Khi đặc tả, cần giữ rõ nguồn này để người dùng có thể hiểu khoản nào đến từ số dư đầu kỳ, khoản nào đến từ bán hàng và khoản nào đến từ mua hàng. Sổ theo dõi công nợ không vì thế nhận thay việc ghi sổ nhật ký kế toán; các quy tắc bàn giao sang kế toán vẫn thuộc ranh giới đã chốt giữa các nghiệp vụ.

Trong giai đoạn 1, Kế toán lập số dư đầu kỳ theo **từng khoản công nợ còn mở**, có đối tác, chiều phải thu/phải trả, số tiền, ngày/căn cứ và mô tả hoặc tham chiếu khi có. Nhiều khoản có thể được chuẩn bị trong một đợt. Số dư đầu kỳ mặc định cần phê duyệt theo chính sách của tổ chức; người lập không tự duyệt. Sau khi được duyệt và xác lập, khoản số dư không được sửa trực tiếp; điều chỉnh công nợ thuộc giai đoạn sau.

Khi đóng sổ cũ, Nam không còn hỏi có nên bắt đầu từ số không. Cậu hỏi Lan: **“Tại thời điểm bắt đầu dùng VET45, mỗi khoản còn bao nhiêu, và con số đó đã tính những lần thanh toán nào?”**

Đó là điểm xuất phát đúng của số dư đầu kỳ: hệ thống mới tiếp tục theo dõi phần việc còn lại, không viết lại lịch sử thành một lần mua bán mới.

## 4. Nguồn tham khảo

Căn cứ nội bộ là [Sổ quyết định nghiệp vụ công nợ](../decisions/decision-register.md):

- [`T06-DR-004`](../decisions/decision-register.md#t06-dr-004) — Phạm vi theo dõi và quản lý công nợ.

- [`T06-DR-005`](../decisions/decision-register.md#t06-dr-005) — Ranh giới giữa nghiệp vụ công nợ và kế toán.

- [`T06-DR-016`](../decisions/decision-register.md#t06-dr-016) — Chênh lệch công nợ không đồng nghĩa đã cấn trừ.

- [`T06-DR-025`](../decisions/decision-register.md#t06-dr-025) — Số dư đầu kỳ thuộc giai đoạn 1 và có nguồn riêng.

- [`T06-DR-028`](../decisions/decision-register.md#t06-dr-028) — Các nghiệp vụ thuộc giai đoạn sau.

- [`T06-DR-038`](../decisions/decision-register.md#t06-dr-038) — Bàn giao với kế toán.

- Định nghĩa số dư đầu kỳ, giá trị gốc và dư nợ còn lại theo [Bảng thuật ngữ công nợ](../glossary/glossary.md).

Các con số là ví dụ giả định để diễn giải phần công nợ còn lại khi chuyển hệ thống. Bài không quyết định phương thức nhập tay hay nhập tệp; đó là lựa chọn thiết kế/Trường hợp sử dụng, nhưng mức chi tiết từng khoản và yêu cầu phê duyệt đã được khóa.

- [T06-DR-026](../decisions/decision-register.md#t06-dr-026) — Mức chi tiết và nguyên tắc ghi nhận số dư đầu kỳ.

## 5. Liên kết liên quan

- Về công nợ phát sinh từ giao dịch mới, đọc [KB-003 — Mốc xác lập và lịch sử thay đổi nghĩa vụ công nợ](KB-003-xac-lap-va-thay-doi-nghia-vu-cong-no.md).

- Về quan hệ giữa số tiền đã trả và phần còn lại, xem [KB-004 — Khách đã trả tiền, vì sao chứng từ vẫn còn nợ?](KB-004-thu-chi-va-phan-bo-thanh-toan.md).

- Về hai chiều phải thu, phải trả của cùng đối tác, xem [KB-005 — Chênh lệch công nợ khác cấn trừ công nợ như thế nào?](KB-005-chenh-lech-va-can-tru-cong-no.md).
