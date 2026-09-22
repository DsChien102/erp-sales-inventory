---
id: KB-009
type: know-how
theme: theme-06
title: Đối chiếu công nợ — khi hai bên không nhìn thấy cùng một con số
owner: BA
status: IN_REVIEW
---

# KB-009 — Đối chiếu công nợ — khi hai bên không nhìn thấy cùng một con số

## 1. Bối cảnh

Cuối tháng, Lan gọi cho Bình Minh để xác nhận công nợ. VET45 cho thấy Bình Minh còn phải trả An Phú 20 triệu đồng.

Phía Bình Minh trả lời:

> “Bên tôi đang ghi nhận chỉ còn 18 triệu.”

Nam ngồi cạnh ngạc nhiên. “Hệ thống mình đã có số rồi, sao còn phải hỏi đối tác nữa chị?”

Lan giải thích: “Tra cứu cho biết **sổ của mình đang nói gì**. Đối chiếu trả lời thêm một câu khác: **hai bên có đang cùng xác nhận một số hay không**.”

## 2. Nội dung nền tảng

### Đối chiếu bắt đầu từ một mốc rõ ràng

Muốn so sánh được, hai bên phải nói về cùng một phạm vi và cùng một thời điểm. Ví dụ:

- Đối tác: Bình Minh.
- Mốc đối chiếu: hết ngày 31/08.
- Theo VET45: còn phải thu 20 triệu.
- Theo Bình Minh: còn phải trả An Phú 18 triệu.

Nếu một bên dùng số đầu tháng và bên kia dùng số cuối tháng, con số khác nhau chưa chắc là sai.

### Có chênh lệch không có nghĩa được tự sửa số

Lan ghi nhận chênh lệch 2 triệu và bắt đầu lần căn cứ. Có thể một bên chưa ghi nhận một khoản thanh toán, một hóa đơn, hoặc đang nhìn khác mốc thời gian.

Nhưng việc phát hiện chênh lệch **không cho phép công nợ tự giảm từ 20 xuống 18 triệu**.

Giai đoạn 1 của đối chiếu có trách nhiệm:

1. Tổng hợp số liệu và căn cứ ở mốc đối chiếu.
2. Tạo bảng/biên bản để trao đổi với đối tác.
3. Ghi nhận phản hồi và bằng chứng.
4. Kết luận trạng thái `Chờ xác nhận`, `Đã khớp` hoặc `Có chênh lệch`.

Nếu có chênh lệch, hệ thống lưu lại để người phụ trách biết cần xử lý. Điều chỉnh công nợ vẫn là một capability khác và chưa thuộc giai đoạn 1.

### Đối chiếu khác tra cứu như thế nào?

Nam mở lại phần tra cứu. Ở đó cậu có thể xem nghĩa vụ, khoản thu/chi, phân bổ và cấn trừ đã được hệ thống ghi nhận.

Nhưng đối chiếu thêm một phía thứ hai: **xác nhận của đối tác**.

Vì vậy:

- Tra cứu: “Theo VET45, số liệu của tôi là bao nhiêu và vì sao?”
- Đối chiếu: “Tại cùng một mốc, đối tác có xác nhận cùng số đó không?”

Hai hành trình liên quan nhưng không thay thế nhau.

### Một lần đối chiếu cần được lưu lại như bằng chứng

Một tháng sau, Lan cần biết vì sao cuối tháng trước hai bên từng chênh 2 triệu. Nếu chỉ ghi đè trạng thái hiện tại, câu chuyện sẽ biến mất.

Vì thế mỗi lần đối chiếu cần giữ được mốc, số liệu hai bên, kết quả, phản hồi và bằng chứng liên quan. Đây là lịch sử xác nhận, không phải một bản sao mới của nghĩa vụ công nợ.

## 3. Ý nghĩa đối với nghiệp vụ công nợ

Đối chiếu công nợ thuộc giai đoạn 1 vì đây là nhu cầu vận hành thường xuyên. VET45 hỗ trợ người dùng lập đối chiếu, ghi nhận phản hồi và lưu kết quả, nhưng không tự động biến chênh lệch thành điều chỉnh công nợ.

Giai đoạn đầu cũng không cần một cổng đối tác hay chữ ký điện tử chuyên biệt. Bảng/biên bản có thể được trao đổi ngoài hệ thống; VET45 chịu trách nhiệm giữ nội dung và bằng chứng mà người dùng ghi nhận lại.

Khi Nam nhìn thấy trạng thái `Có chênh lệch`, cậu hiểu đó không phải lỗi làm hệ thống tự sửa số, mà là một kết quả nghiệp vụ cần được tiếp tục xử lý bằng capability phù hợp.

## 4. Nguồn tham khảo

- [T06-DR-001](../decisions/decision-register.md#t06-dr-001) — Một mã đối tác dùng chung.

- [T06-DR-004](../decisions/decision-register.md#t06-dr-004) — Công nợ sở hữu năng lực đối chiếu trong phạm vi của mình.

- [T06-DR-027](../decisions/decision-register.md#t06-dr-027) — Đối chiếu cơ bản thuộc giai đoạn 1 và các kết quả được hỗ trợ.

- [T06-DR-028](../decisions/decision-register.md#t06-dr-028) — Điều chỉnh công nợ và xử lý đối chiếu nâng cao thuộc giai đoạn sau.

- [T06-DR-032](../decisions/decision-register.md#t06-dr-032) — Yêu cầu lưu bằng chứng và nhật ký 10 năm.

- [Bảng thuật ngữ công nợ](../glossary/glossary.md).

## 5. Liên kết liên quan

- [KB-001 — Công nợ là gì, ai đang nợ ai?](KB-001-cong-no-can-ban.md).

- [KB-003 — Mốc xác lập và lịch sử thay đổi nghĩa vụ công nợ](KB-003-xac-lap-va-thay-doi-nghia-vu-cong-no.md).

- [KB-005 — Chênh lệch công nợ khác cấn trừ công nợ như thế nào?](KB-005-chenh-lech-va-can-tru-cong-no.md).
