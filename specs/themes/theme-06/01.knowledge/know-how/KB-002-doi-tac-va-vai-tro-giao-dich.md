---
id: KB-002
type: know-how
theme: theme-06
title: Một đối tác vừa là khách hàng, vừa là nhà cung cấp
owner: BA
status: IN_REVIEW
---

# KB-002 — Một đối tác vừa là khách hàng, vừa là nhà cung cấp

## 1. Bối cảnh

Nam đặt hai tờ giấy cạnh nhau trên bàn chị Lan. Một tờ ghi khoản tiền Bình Minh còn phải trả cho cửa hàng An Phú. Tờ còn lại ghi khoản An Phú đang nợ Bình Minh.

> “Em thấy Bình Minh ở cả phía khách hàng lẫn phía nhà cung cấp. Mình có nhập nhầm không chị?”

Lan nhìn hai giao dịch rồi lắc đầu. Ở lần thứ nhất, Bình Minh mua hàng của An Phú. Ở lần thứ hai, chính Bình Minh lại bán hàng cho An Phú. Hai tờ giấy không mâu thuẫn; chúng đang kể hai việc khác nhau về cùng một đối tác.

Điều Nam cần phân biệt không phải tên nào đúng, tên nào sai, mà là **đang giao dịch với ai** và **bên ấy giữ vai trò gì trong từng giao dịch**.

Tình huống dưới đây là ví dụ giả định riêng, dùng cùng cửa hàng An Phú, đối tác Bình Minh và hai nhân vật Lan, Nam như các bài trong bộ kiến thức. Số tiền không được cộng dồn với ví dụ ở bài khác.

## 2. Nội dung nền tảng

### Hai chiều giao dịch, một đối tác

Trong ví dụ này, An Phú đã hoàn tất bán một lô hàng trị giá 10 triệu đồng cho Bình Minh, chưa thu tiền. Vì đang nhìn từ An Phú, Lan ghi nhận đây là khoản **phải thu**: Bình Minh là bên cần thanh toán cho cửa hàng.

Ở một giao dịch riêng, An Phú mua hàng của Bình Minh. Khi nhận hóa đơn nhà cung cấp trị giá 6 triệu đồng, chưa thanh toán, An Phú có khoản **phải trả** cho Bình Minh.

Lan viết hai câu thay vì chỉ ghi hai con số:

> “Bình Minh còn phải trả An Phú 10 triệu.”
>
> “An Phú còn phải trả Bình Minh 6 triệu.”

Cả hai câu đều nói về Bình Minh. Chỉ có hướng giao dịch và bên có nghĩa vụ trả tiền là khác nhau.

Trong quan hệ bán hàng đầu tiên, Bình Minh mang **vai trò khách hàng**. Trong quan hệ mua hàng thứ hai, Bình Minh mang **vai trò nhà cung cấp**. Tên gọi vai trò giúp hiểu từng giao dịch, nhưng không làm Bình Minh trở thành hai đối tác khác nhau.

### Mã đối tác trả lời câu hỏi khác với vai trò

Để dễ hình dung, giả sử Bình Minh có mã đối tác `P001` trong tổ chức An Phú đang sử dụng VET45. Khi tham gia giao dịch bán, mã ấy vẫn là `P001`. Khi tham gia giao dịch mua, mã ấy cũng không đổi.

**Mã đối tác trả lời “đó là ai”; vai trò trả lời “đó là bên nào trong giao dịch này”.**

Vì thế, khi xem công nợ của `P001`, Lan cần nhìn thấy cả 10 triệu phải thu và 6 triệu phải trả. Việc giữ chung mã không làm mất hai chiều công nợ. Trái lại, nó cho phép đặt hai chiều ấy cạnh nhau mà vẫn biết từng khoản bắt nguồn từ đâu.

Một danh sách có thể chỉ hiển thị khách hàng, danh sách khác chỉ hiển thị nhà cung cấp. Đó là hai cách xem theo vai trò. Chúng không phải lý do để tạo hai mã đối tác độc lập cho cùng Bình Minh.

### Nếu tách mã chỉ vì khác vai trò, chuyện gì sẽ xảy ra?

Nam thử tưởng tượng một cách ghi khác: đưa khoản phải thu vào một mã khách hàng, còn khoản phải trả vào một mã nhà cung cấp không liên hệ với mã trước.

Khi xem mã khách hàng, cậu chỉ thấy An Phú cần thu 10 triệu. Khi xem mã nhà cung cấp, cậu chỉ thấy An Phú cần trả 6 triệu. Hai màn nhìn riêng lẻ có thể đều chứa số tiền đúng, nhưng người đọc phải tự nối chúng bằng trí nhớ mới biết đó là cùng một đối tác.

Vấn đề rõ hơn khi muốn xem xét cấn trừ. Nếu hệ thống chưa biết hai phía thuộc cùng đối tác nào, việc lấy một khoản phải trả để xử lý một khoản phải thu sẽ thiếu căn cứ nhận diện.

Lựa chọn của VET45 là giữ một mã đối tác chung ngay từ nền tảng. Nghiệp vụ công nợ sử dụng mã ấy để liên kết các nghĩa vụ; không tự đoán quan hệ giữa hai hồ sơ dựa vào tên hiển thị.

### Tên giống nhau chưa đủ để kết luận là cùng một bên

Đến đây, Nam đề nghị tìm tất cả hồ sơ có tên Bình Minh rồi coi chúng là một.

Lan dừng cậu lại. Ví dụ đang giả định hai giao dịch thực sự thuộc cùng đối tác `P001`. Nó không chứng minh rằng mọi hồ sơ trùng tên đều là cùng đối tác. Một chuỗi ký tự giống nhau không thay thế được căn cứ định danh.

Tương tự, không thể chỉ vì số điện thoại trùng mà tự cho phép cấn trừ giữa hai hồ sơ. Việc nhận diện, quản lý hồ sơ đối tác là trách nhiệm của nghiệp vụ quản lý đối tác; quy tắc tìm trùng hoặc hợp nhất hồ sơ không được tự bổ sung trong bài công nợ này.

Bài học của Nam không phải “hãy gộp mọi tên giống nhau”, mà là “hãy dùng đúng mã của đối tác đã được nhận diện”.

## 3. Ý nghĩa đối với nghiệp vụ công nợ

Khi đọc một yêu cầu về công nợ, người phân tích cần tách ba điều: đối tác là ai, nghĩa vụ thuộc chiều nào, và giao dịch nào làm phát sinh nghĩa vụ. Nghiệp vụ bán hàng cung cấp khoản phải thu; nghiệp vụ mua hàng cung cấp khoản phải trả; phân hệ công nợ theo dõi các nghĩa vụ ấy dưới mã đối tác tương ứng.

Giữ chung mã không đồng nghĩa chỉ giữ một con số cuối cùng. Trong tình huống trên, trước khi có nghiệp vụ xử lý hợp lệ, vẫn phải hiểu riêng 10 triệu phải thu và 6 triệu phải trả. Phép trừ cho ra 4 triệu chỉ giúp đọc chênh lệch; nó không tự làm hai nghĩa vụ thay đổi và không chứng minh đã cấn trừ.

Cũng không được mang một khoản thuộc tổ chức khác vào ví dụ chỉ vì mã hoặc tên đối tác trông giống nhau. Quyết định cấn trừ của VET45 giới hạn trong cùng tổ chức sử dụng hệ thống và cùng mã đối tác.

Cuối buổi, Nam giữ lại cả hai tờ giấy, nhưng không còn nghĩ có hai Bình Minh. Cậu ghi trên cùng: **“Một đối tác, hai vai trò, hai chiều công nợ.”** Khi gặp một tên xuất hiện ở cả phía khách hàng và nhà cung cấp, câu hỏi đầu tiên của cậu sẽ là mã đối tác có đang được dùng thống nhất hay không.

## 4. Nguồn tham khảo

Căn cứ nội bộ là [Sổ quyết định nghiệp vụ công nợ](../decisions/decision-register.md):

- [`T06-DR-001`](../decisions/decision-register.md#t06-dr-001) — Mã đối tác dùng chung và hai vai trò khách hàng, nhà cung cấp.

- [`T06-DR-002`](../decisions/decision-register.md#t06-dr-002) — Nguồn và mốc xác lập khoản phải thu từ bán hàng.

- [`T06-DR-003`](../decisions/decision-register.md#t06-dr-003) — Nguồn và mốc xác lập khoản phải trả từ mua hàng.

- [`T06-DR-004`](../decisions/decision-register.md#t06-dr-004) — Phạm vi theo dõi và quản lý công nợ.

- [`T06-DR-016`](../decisions/decision-register.md#t06-dr-016) — Chênh lệch công nợ không đồng nghĩa đã cấn trừ.

- [`T06-DR-017`](../decisions/decision-register.md#t06-dr-017) — Cấn trừ công nợ có chủ đích và lưu dấu vết nghiệp vụ.

- Các cách gọi đối tác giao dịch, vai trò khách hàng, vai trò nhà cung cấp, phải thu và phải trả theo [Bảng thuật ngữ công nợ](../glossary/glossary.md).

Tên, mã và số tiền trong câu chuyện là minh họa cho quyết định của VET45, không phải quy tắc xác minh danh tính, hợp nhất hồ sơ hoặc xác định tư cách pháp lý.

## 5. Liên kết liên quan

- Nếu chưa quen cách xác định bên phải trả tiền, đọc [KB-001 — Công nợ là gì, ai đang nợ ai?](KB-001-cong-no-can-ban.md) trước.

- Đọc tiếp [KB-003 — Mốc xác lập và lịch sử thay đổi nghĩa vụ công nợ](KB-003-xac-lap-va-thay-doi-nghia-vu-cong-no.md) để hiểu khi nào giao dịch trở thành khoản được theo dõi.

- Câu chuyện về hai chiều nghĩa vụ được đi sâu trong [KB-005 — Chênh lệch công nợ khác cấn trừ công nợ như thế nào?](KB-005-chenh-lech-va-can-tru-cong-no.md).
