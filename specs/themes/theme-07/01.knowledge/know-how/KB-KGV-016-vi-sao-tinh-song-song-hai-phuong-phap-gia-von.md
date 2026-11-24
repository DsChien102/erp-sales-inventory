---
id: KB-KGV-016-vi-sao-tinh-song-song-hai-phuong-phap-gia-von
type: know-how
theme: theme-07
title: vi-sao-tinh-song-song-hai-phuong-phap-gia-von
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-016-vi-sao-tinh-song-song-hai-phuong-phap-gia-von — vi-sao-tinh-song-song-hai-phuong-phap-gia-von

## 1. Bối cảnh

### Câu trả lời ngắn

Hệ thống tính đồng thời **bình quân gia quyền liên hoàn** và **bình quân gia quyền cuối kỳ** trên cùng một movement ledger bất biến. Doanh nghiệp chọn một phương pháp làm **nguồn công bố đơn giá tồn kho chính thức cho kỳ**; phương pháp còn lại được giữ làm chỉ số đối chiếu.

Tính song song không có nghĩa là tồn tại hai sổ kế toán hoặc mỗi giao dịch được tự chọn giá có lợi hơn. Tại một thời điểm chỉ có **một phiên bản đơn giá chính thức có hiệu lực**. Chỉ số không được chọn không tự ghi sổ, không tự điều chỉnh tồn và không tự thay thế đơn giá đang áp dụng.

### Vì sao vấn đề này quan trọng?

Giá nhập thường thay đổi trong kỳ. Một phương pháp nhạy với trình tự nhập–xuất giúp doanh nghiệp quan sát biến động liên tục; phương pháp còn lại gom toàn bộ kỳ để tạo một điểm đối soát ít phụ thuộc hơn vào thứ tự thời gian.

Nếu chỉ lưu kết quả đã công bố, kế toán khó biết chênh lệch xuất phát từ biến động giá, thời điểm giao dịch hay dữ liệu bất thường. Tính song song trên cùng ledger tạo ra **hai cách nhìn có thể đối chiếu**, nhưng vẫn duy trì một nguồn ghi sổ chính thức.

## 2. Nội dung nền tảng

### Hai phương pháp khác nhau thế nào?

| Tiêu chí | Bình quân gia quyền liên hoàn | Bình quân gia quyền cuối kỳ |
|---|---|---|
| Thời điểm tính | Cập nhật sau các movement giá trị có liên quan trong kỳ | Tính tại một cut-off cho toàn kỳ hoặc phần kỳ |
| Dữ liệu nhấn mạnh | Số lượng và giá trị còn lại ngay trước movement, cộng movement mới | Tổng lượng và tổng giá trị của hàng sẵn có trong phạm vi kỳ |
| Độ nhạy với trình tự | Nhạy với thứ tự nhập–xuất | Ít phụ thuộc hơn vào thứ tự nhập–xuất trong kỳ |
| Giá trị sử dụng | Chỉ số theo dõi liên tục; có thể là phương pháp nguồn được chọn | Chỉ số đối soát tại cut-off; có thể là phương pháp nguồn được chọn |
| Quyền ghi sổ | Không tự ghi sổ chỉ vì vừa tính ra | Không tự ghi sổ chỉ vì vừa tính ra |

Trong một ví dụ đơn giản, bình quân liên hoàn sau một lần nhập có thể được diễn giải như sau:

$$
\text{Bình quân liên hoàn mới}
=
\frac{\text{Giá trị còn lại trước nhập} + \text{Giá trị nhập mới}}
{\text{Số lượng còn lại trước nhập} + \text{Số lượng nhập mới}}
$$

Bình quân cuối kỳ có thể được diễn giải ở mức khái niệm:

$$
\text{Bình quân cuối kỳ}
=
\frac{\text{Tổng giá trị hàng sẵn có trong kỳ}}
{\text{Tổng số lượng hàng sẵn có trong kỳ}}
$$

Trong vận hành thực tế, các thành phần giá trị, điều chỉnh và movement đủ điều kiện phải lấy từ ledger theo đúng kỳ và cut-off; không được tính bằng cách gom số từ các báo cáo rời rạc.

### Một ledger, hai phép tính, một đơn giá chính thức

#### 1. Cùng sử dụng một nguồn dữ liệu

Cả hai phương pháp phải đọc cùng movement ledger bất biến. Không được duy trì một bộ movement cho bình quân liên hoàn và một bộ khác cho bình quân cuối kỳ. Nhờ vậy, chênh lệch giữa hai kết quả phản ánh **khác biệt phương pháp**, không phải khác biệt nguồn dữ liệu.

#### 2. Tính song song nhưng không ghi sổ song song

Mỗi phương pháp tạo ra một chỉ số tính toán. Chỉ khi quy trình công bố hoàn tất, kết quả của phương pháp nguồn được chọn mới trở thành phiên bản đơn giá chính thức có hiệu lực. Phương pháp còn lại vẫn được lưu để đối chiếu nhưng không tạo value movement hoặc valuation adjustment chỉ vì nó có kết quả khác.

#### 3. Chọn phương pháp nguồn cho kỳ

Doanh nghiệp cấu hình một phương pháp nguồn cho kỳ. Việc lựa chọn quyết định **kết quả nào được đưa vào quy trình công bố**, không quyết định ledger nào được đọc và không xóa kết quả của phương pháp còn lại.

#### 4. Đối chiếu trước khi công bố

Kế toán có thể xem cả hai kết quả, mức chênh và dữ liệu hình thành chúng. Chênh lệch không mặc nhiên là lỗi; nó có thể xuất hiện tự nhiên khi giá mua biến động và thời điểm nhập–xuất xen kẽ. Tuy nhiên, chênh lệch là tín hiệu hữu ích để rà soát dữ liệu trước khi công bố.

#### 5. Lần chạy tính giá không có thao tác hủy trong phạm vi hiện tại

Một lần chạy đã bắt đầu phải đi đến kết quả cuối có bằng chứng; không có trạng thái hay lệnh `CANCELLED` trong Phase 1. Nếu cần tính lại sau khi dữ liệu hoặc phạm vi thay đổi, hệ thống tạo lần chạy kế tiếp có định danh mới và liên kết `supersedes_run_id` đến lần trước; không hồi sinh hoặc viết lại lần chạy cũ.

### Ví dụ xuyên suốt

Giả sử bỏ qua thuế và các chi phí bổ sung để tập trung vào cơ chế bình quân:

1. Đầu kỳ có 10 đơn vị, đơn giá 100.000 đồng.
2. Bán 5 đơn vị.
3. Nhập thêm 10 đơn vị, đơn giá 140.000 đồng.

#### Chỉ số bình quân liên hoàn sau lần nhập

Trước lần nhập còn 5 đơn vị với giá trị minh họa 500.000 đồng. Lô mới có giá trị 1.400.000 đồng:

$$
\frac{500.000 + 1.400.000}{5 + 10}
= 126.666{,}67\text{ đồng/đơn vị}
$$

#### Chỉ số bình quân cuối kỳ

Toàn bộ hàng sẵn có trong kỳ gồm 10 đơn vị đầu kỳ và 10 đơn vị nhập mới:

$$
\frac{1.000.000 + 1.400.000}{10 + 10}
= 120.000\text{ đồng/đơn vị}
$$

Hai kết quả khác nhau vì bình quân liên hoàn sử dụng giá trị còn lại tại thời điểm nhập, còn bình quân cuối kỳ nhìn toàn bộ hàng sẵn có trong kỳ. Nếu doanh nghiệp chọn bình quân cuối kỳ làm phương pháp nguồn, 120.000 đồng là giá trị được đưa vào quy trình công bố; 126.666,67 đồng vẫn được giữ để đối chiếu và **không tự tạo bút toán**.

Ví dụ trên chỉ minh họa khác biệt phương pháp. Mốc hiệu lực của đơn giá chính thức, true-up lượng đã xuất và adjustment của tồn cuối kỳ được xử lý trong quy trình công bố và đối soát riêng.

### Cách đọc chênh lệch giữa hai phương pháp

| Quan sát | Cách hiểu phù hợp |
|---|---|
| Hai kết quả bằng nhau hoặc gần nhau | Trình tự nhập–xuất và biến động giá không tạo khác biệt đáng kể trong kỳ |
| Bình quân liên hoàn cao hơn | Giá trị của lượng còn lại và các lần nhập gần đây có thể cao hơn mặt bằng toàn kỳ |
| Bình quân cuối kỳ cao hơn | Hàng giá cao trong toàn kỳ có thể chưa phản ánh tương đương vào lượng còn lại tại các mốc liên hoàn |
| Chênh lệch đột biến, khó giải thích | Cần rà soát movement, cut-off, giá nhập và adjustment; không tự kết luận phương pháp nào sai |

Bảng này là hướng dẫn đọc số liệu, không phải quy tắc tự động thay đổi phương pháp nguồn.

### Ngoại lệ và những cách làm sai

- **Coi hai kết quả là hai giá ghi sổ cùng hiệu lực:** làm mất khái niệm đơn giá chính thức duy nhất.
- **Cho người dùng chọn phương pháp theo từng lần xuất:** biến phương pháp định giá thành công cụ chọn kết quả có lợi.
- **Dùng hai bộ dữ liệu đầu vào khác nhau:** khiến chênh lệch không còn khả năng đối chiếu.
- **Để chỉ số đối chiếu tự ghi adjustment:** phương pháp không được chọn chỉ cung cấp thông tin, không có quyền tự ghi sổ.
- **Tính lại từ báo cáo tổng hợp thay vì movement ledger:** có thể bỏ sót correction, cut-off hoặc adjustment có liên kết.
- **Hiểu chênh lệch là lỗi bắt buộc phải đưa về 0:** hai phương pháp có thể khác nhau một cách hợp lệ.

## 3. Ý nghĩa đối với Theme

### Điều cần ghi nhớ

- **Hai phương pháp cùng đọc một movement ledger bất biến.**
- **Doanh nghiệp chọn một phương pháp nguồn cho kỳ; phương pháp còn lại dùng để đối chiếu.**
- **Tính ra một chỉ số không đồng nghĩa với đã công bố hoặc đã ghi sổ.**
- **Tại một thời điểm chỉ có một phiên bản đơn giá chính thức có hiệu lực.**
- **Chênh lệch giữa hai phương pháp là thông tin cần giải thích, không phải một bút toán tự động.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-016` |
| Cụm tri thức | [`KGV-C04`](00-table-of-contents.md#c04-giá-vốn-và-định-giá-tồn-kho) |
| Loại bài | `VALUATION` |
| Quyết định chính | [`T7-DR-049`](../decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3), [`T7-DR-049#REQ-01`](../decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3), [`T7-DR-060#REQ-01`](../decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3) |
| Trạng thái quyết định | `ACTIVE` |
| Mức bằng chứng của bài | `STATIC_VALIDATED` |
| Giới hạn | Công thức được trình bày để giải thích khái niệm; bài không mô tả đầy đủ thuật toán true-up, publication hoặc mọi loại movement giá trị |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-015` — Đơn giá tồn kho chính thức và tổng giá trị ghi sổ](KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md)
- [`KB-KGV-017` — Công bố giá vốn chính thức và ghi nhận giá vốn hàng bán](KB-KGV-017-cong-bo-don-gia-ton-kho-va-ghi-nhan-gia-von-xuat-ban.md)
- [`KB-KGV-018` — Đối soát giá vốn cuối kỳ và cập nhật đột xuất giữa kỳ](KB-KGV-018-doi-soat-gia-von-cuoi-ky-va-cap-nhat-dot-xuat-giua-ky.md)
