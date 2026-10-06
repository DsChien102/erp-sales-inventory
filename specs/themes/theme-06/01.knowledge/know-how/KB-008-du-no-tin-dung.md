---
id: KB-008
type: know-how
theme: theme-06
title: Dư nợ tín dụng — nhìn đúng phần đang thực sự mở
owner: BA
status: IN_REVIEW
---

# KB-008 — Dư nợ tín dụng — nhìn đúng phần đang thực sự mở

## 1. Bối cảnh

Nam đang xem công nợ của Bình Minh. Trên màn hình, đối tác còn ba khoản phải thu: 4 triệu, 6 triệu và một giao dịch 10 triệu đã được thanh toán đủ ngay tại lúc bán.

Nam cộng cả ba giá trị gốc rồi nói:

> “Vậy dư nợ tín dụng của Bình Minh là 20 triệu phải không chị?”

Lan lắc đầu. “Em đang cộng lịch sử giao dịch, chứ chưa chắc đang cộng phần tín dụng còn mở.”

Câu chuyện này bắt đầu từ một khác biệt nhỏ nhưng quan trọng: **một giao dịch từng phát sinh nghĩa vụ không có nghĩa toàn bộ giá trị gốc của nó vẫn còn nằm trong dư nợ tín dụng hôm nay.**

## 2. Nội dung nền tảng

### Dư nợ tín dụng giai đoạn 1 nhìn vào khoản phải thu còn mở

Trong giai đoạn 1, cách tính được dùng là:

```text
Dư nợ tín dụng = Tổng các khoản phải thu còn mở
```

Giả sử:

- Khoản A còn phải thu 4 triệu.
- Khoản B còn phải thu 6 triệu.
- Khoản C có giá trị gốc 10 triệu nhưng đã thu và phân bổ đủ 10 triệu, nên số còn phải thu bằng 0.

Dư nợ tín dụng là **10 triệu**, không phải 20 triệu.

Khoản C vẫn tồn tại trong lịch sử để Nam có thể lần lại giao dịch và khoản tiền đã nhận. Nhưng vì không còn phải thu nên nó không làm tăng phần tín dụng đang mở.

### Vì sao chưa cộng “cam kết bán chịu”?

Nam hỏi tiếp:

> “Nếu bán hàng đang có một đơn dự kiến cho Bình Minh mua chịu thêm 8 triệu thì sao?”

Lan trả lời: “Chỉ nhìn thấy một đơn chưa đủ để công nợ tự coi đó là cam kết tín dụng.”

Muốn cộng một khoản chưa trở thành phải thu vào dư nợ tín dụng, bán hàng phải có một **mốc nghiệp vụ chuẩn** nói rõ rằng doanh nghiệp đã cam kết cấp phần tín dụng đó, dù giao dịch chưa đạt mốc `Hoàn tất bán hàng`.

Ở giai đoạn 1 hiện tại, mốc như vậy chưa được xác lập thành hợp đồng chuẩn giữa bán hàng và công nợ. Vì vậy công nợ **không tự suy diễn** từ đơn nháp, đơn đang xử lý hay một trạng thái nội bộ khác để cộng thêm giá trị.

Điều này không phủ nhận khả năng mở rộng sau này. Khi bán hàng có một checkpoint canonical cho cam kết tín dụng, dư nợ tín dụng có thể được mở rộng để tính cả phần cam kết chưa chuyển thành phải thu. Khi đó phải bảo đảm cùng một giá trị không bị tính hai lần lúc cam kết chuyển thành nghĩa vụ.

### Tiền chưa phân bổ cũng không tự làm dư nợ giảm

Giả sử An Phú đã nhận 3 triệu từ Bình Minh nhưng chưa phân bổ cho khoản A hay B.

Khoản tiền đã tồn tại, nhưng hai nghĩa vụ vẫn chưa có căn cứ cho biết khoản nào đã được thực hiện. Vì vậy, chỉ khi phân bổ hợp lệ thì số còn phải thu của nghĩa vụ tương ứng mới giảm và dư nợ tín dụng mới thay đổi theo.

Nam nhận ra một nguyên tắc chung: **dư nợ tín dụng không phải con số được “làm nhỏ đi” bằng mọi khoản tiền nhìn thấy; nó phản ánh phần phải thu còn mở theo trạng thái nghiệp vụ đã được xác nhận.**

## 3. Ý nghĩa đối với nghiệp vụ công nợ

Dư nợ tín dụng ở giai đoạn 1 là một số liệu đọc được từ các khoản phải thu còn mở. Nó không tạo thêm nghĩa vụ, không tự quyết định có được tiếp tục bán chịu hay không và không tự trừ tiền chưa phân bổ.

Nếu bán hàng cần dùng số liệu này để kiểm soát giao dịch, công nợ cung cấp đúng phần đã có căn cứ. Quy tắc hạn mức, quyết định cho bán chịu và checkpoint cam kết tín dụng thuộc phạm vi cần được bán hàng sở hữu hoặc cùng xác nhận trong hợp đồng liên phân hệ.

Khi Nam quay lại bảng công nợ, cậu không còn hỏi “tổng tất cả giao dịch là bao nhiêu”, mà hỏi “bao nhiêu tiền phải thu vẫn thực sự còn mở?”. Đó mới là câu hỏi phù hợp với dư nợ tín dụng hiện tại.

## 4. Nguồn tham khảo

- [T06-DR-002](../decisions/decision-register.md#t06-dr-002) — Mốc phát sinh phải thu từ bán hàng.

- [T06-DR-007](../decisions/decision-register.md#t06-dr-007) — Giao dịch đã trả đủ vẫn giữ lịch sử nhưng không thuộc công nợ còn mở.

- [T06-DR-009](../decisions/decision-register.md#t06-dr-009) — Thanh toán một phần.

- [T06-DR-013](../decisions/decision-register.md#t06-dr-013) — Số tiền chưa phân bổ.

- [T06-DR-029](../decisions/decision-register.md#t06-dr-029) — Cách tính dư nợ tín dụng của giai đoạn 1.

- [Bảng thuật ngữ công nợ](../glossary/glossary.md).

## 5. Liên kết liên quan

- [KB-003 — Mốc xác lập và lịch sử thay đổi nghĩa vụ công nợ](KB-003-xac-lap-va-thay-doi-nghia-vu-cong-no.md).

- [KB-004 — Khách đã trả tiền, vì sao chứng từ vẫn còn nợ?](KB-004-thu-chi-va-phan-bo-thanh-toan.md).

- [KB-006 — Chính sách phê duyệt theo từng tổ chức](KB-006-chinh-sach-phe-duyet.md).
