---
id: KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so
type: know-how
theme: theme-07
title: don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so — don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so

## 1. Bối cảnh

### Câu trả lời ngắn

Đơn giá tồn kho chính thức là đơn giá quản trị đồng thời là đơn giá ghi sổ dùng cho các lần xuất kho. Tuy vậy, tổng giá trị ghi sổ có thẩm quyền không được suy ra bằng cách lấy số lượng hiện tại nhân đơn giá này; nó là tổng của toàn bộ value movement đã commit. Trong kỳ, nhập theo giá thực tế còn xuất theo đơn giá chính thức đang hiệu lực nên thương số tổng giá trị/số lượng có thể tạm khác đơn giá áp dụng. Cả đơn giá bình quân, đơn giá chính thức và giá trị có thẩm quyền đều được quản lý ở mức đơn vị vận hành + sản phẩm, không theo từng kho hay lô.

### Vì sao vấn đề này quan trọng?

Ba con số thường bị gọi chung là “giá vốn”: giá nhập của một lần mua, đơn giá chính thức dùng cho xuất và bình quân ngầm suy ra từ tổng giá trị chia số lượng. Chúng có thể khác nhau giữa hai lần đối soát mà dữ liệu vẫn đúng. Nếu ép chúng bằng nhau bằng cách sửa số dư, hệ thống sẽ xóa mất chênh lệch cần true-up. Nếu phân bổ giá trị có thẩm quyền xuống từng kho hoặc lô, cùng một sản phẩm có thể có nhiều “giá sổ” cạnh tranh dù mô hình chỉ công nhận một giá ở cấp toàn đơn vị vận hành.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Không được hiểu là |
|---|---|---|
| Biến động số lượng | Ghi nhận hàng đi vào, đi ra hoặc đổi trạng thái. | Tự động đồng nghĩa với biến động giá trị. |
| Biến động giá trị | Khoản tăng, giảm hoặc điều chỉnh giá trị ghi sổ có căn cứ. | Sửa trực tiếp số tổng để làm khớp. |
| Cut-off | Mốc chốt tập giao dịch được đưa vào một lần tính hoặc đối soát. | Ngày có thể đổi tùy lúc xem báo cáo. |

### Quy tắc vận hành

#### Một đơn giá chính thức, một tổng giá trị từ ledger

Không có phương pháp kế toán tách biệt: đơn giá tồn kho chính thức là đơn giá quản trị đồng thời là đơn giá ghi sổ áp dụng cho xuất kho. Tổng giá trị ghi sổ có thẩm quyền vẫn là tổng các value movement; giữa hai lần đối soát, tổng giá trị chia số lượng có thể khác đơn giá chính thức đang áp dụng.
#### Phạm vi đơn giá là đơn vị vận hành + sản phẩm

Đơn giá bình quân và đơn giá chính thức được xác định ở đơn vị vận hành + sản phẩm; một sản phẩm có cùng đơn giá chính thức tại mọi kho.
#### Nhập theo giá thực tế, xuất theo đơn giá đang hiệu lực

Nhập trong kỳ ghi value movement tăng theo giá nhập thực tế; xuất ghi value movement giảm theo đơn giá chính thức hiện hành. Chênh lệch tạm thời giữa tổng giá trị ledger và đơn giá áp dụng được giữ nguyên để đối soát, không bị che bằng sửa số dư.
#### Giá trị chi tiết theo kho hoặc lô chỉ là dẫn xuất

Giá trị ghi sổ có thẩm quyền chỉ tồn tại ở đơn vị vận hành + sản phẩm; giá trị chi tiết theo kho/trạng thái/lô nếu hiển thị phải gắn nhãn quản trị dẫn xuất.

### Ví dụ xuyên suốt

Đầu kỳ, sản phẩm P có 100 đơn vị và tổng giá trị 10.000.000 đồng; đơn giá chính thức là 100.000 đồng. Trong kỳ nhập thêm 20 đơn vị với giá thực tế 120.000 đồng, nên value ledger tăng 2.400.000 đồng. Sau đó xuất 30 đơn vị theo đơn giá chính thức 100.000 đồng, ledger giảm 3.000.000 đồng. Còn 90 đơn vị với tổng giá trị 9.400.000 đồng, tức thương số là khoảng 104.444 đồng; đơn giá chính thức vẫn là 100.000 đồng cho tới lần công bố tiếp theo. Mọi kho dùng cùng phiên bản 100.000 đồng. Một báo cáo chia 9.400.000 cho số lượng từng kho chỉ là phân bổ quản trị và phải được gắn nhãn dẫn xuất.

Ví dụ này chỉ minh họa cách áp dụng các quy tắc đã nêu. Con số, tên sản phẩm và thời điểm là giả định; chúng không tạo thêm một ngoại lệ, quyền phê duyệt hay mốc ghi nhận mới.


#### Khởi tạo đơn giá chính thức từ lần xác nhận giá đầu tiên

Khi Product chưa có Official Cost, direct valuation đầu tiên có thể bootstrap bằng normalized direct cost theo **base UOM**. Việc tạo version là compare-and-create nguyên tử ở tenant+product: confirmation thắng đầu tiên tạo version; confirmation đồng thời đến sau vẫn ghi valuation/value movement nhưng không overwrite Official Cost. `effective_from` của version khởi tạo là server commit time của lần thắng.

### Ngoại lệ và những cách làm sai

- **Lấy số lượng nhân đơn giá để ghi đè tổng giá trị:** Cách này làm mất các value movement thực tế và che chênh lệch cần đối soát.
- **Tạo đơn giá chính thức riêng theo kho hoặc lô:** Phạm vi giá có thẩm quyền là toàn đơn vị vận hành theo sản phẩm.
- **Coi chênh lệch trong kỳ là lỗi dữ liệu:** Nhập và xuất dùng hai căn cứ tạm thời khác nhau; chênh lệch được giữ để true-up đúng kỳ.

- **Sửa trực tiếp số dư hoặc trạng thái để “làm cho đúng”:** cách này phá vỡ sổ biến động và làm mất khả năng giải thích số liệu. Mọi thay đổi chính thức phải đi qua đúng loại nghiệp vụ, có căn cứ và lịch sử.
- **Dùng dữ liệu tra cứu chậm làm căn cứ commit:** báo cáo hoặc projection có thể hữu ích để quan sát, nhưng quyết định thay đổi tồn phải kiểm tra lại dữ liệu giao dịch hiện hành.

## 3. Ý nghĩa đối với Theme

### Cách áp dụng trong thực tế

Luôn tách biến động số lượng khỏi biến động giá trị, đồng thời xác định phiên bản đơn giá và cut-off áp dụng. Mọi chênh lệch phải được ghi thành delta có liên kết; không sửa chứng từ gốc, không ghi đè lịch sử và không tự tạo một căn cứ giá khi nguồn có thẩm quyền chưa cung cấp.

Khi triển khai một trường hợp cụ thể, người xử lý nên ghi rõ nguồn chứng từ, đối tượng hàng, kho, trạng thái, thời điểm nghiệp vụ và kết quả mong đợi. Nếu một dữ kiện thuộc thẩm quyền của hệ thống khác chưa có, hồ sơ phải dừng ở trạng thái an toàn thay vì tự suy đoán. Nếu một bước có thể ảnh hưởng đồng thời đến nhiều số dư hoặc cả số lượng lẫn giá trị, toàn bộ thay đổi phải được commit nguyên tử và để lại dấu vết đối soát.

### Điều cần ghi nhớ

- **Đơn giá chính thức là giá quản trị đồng thời là giá ghi sổ áp dụng cho xuất.**
- **Tổng giá trị có thẩm quyền là tổng value movement, không phải phép nhân tắt.**
- **Một sản phẩm dùng cùng đơn giá chính thức ở mọi kho.**
- **Giá trị theo kho, trạng thái hoặc lô chỉ là số dẫn xuất nếu được hiển thị.**

- **Khi không đủ bằng chứng để đi tiếp, hệ thống phải thất bại an toàn và giữ nguyên dữ liệu có thẩm quyền.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-015` |
| Cụm tri thức | [`KGV-C04`](00-table-of-contents.md#c04-giá-vốn-và-định-giá-tồn-kho) |
| Loại bài | `VALUATION` |
| Quyết định chính | [`T7-DR-050`](../decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3), [`T7-DR-050`](../decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3), [`T7-DR-055`](../decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3), [`T7-DR-050#REQ-01`](../decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3) |
| Trạng thái quyết định | `ACTIVE` |
| Mức bằng chứng của bài | `STATIC_VALIDATED` |
| Giới hạn | Bài phân biệt đơn giá và tổng giá trị; không giải thích cách tính hai phương pháp bình quân, batch công bố hoặc định giá từng nghiệp vụ đặc biệt |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-003` — Kho, cửa hàng và khóa định danh số dư tồn kho](KB-KGV-003-kho-cua-hang-va-khoa-dinh-danh-so-du-ton-kho.md)
- [`KB-KGV-008` — Hàng đã nhận nhưng chưa chốt giá và điều kiện đưa vào bán](KB-KGV-008-hang-da-nhan-nhung-chua-chot-gia.md)
- [`KB-KGV-016` — Vì sao sử dụng song song hai phương pháp tính giá vốn?](KB-KGV-016-vi-sao-tinh-song-song-hai-phuong-phap-gia-von.md)
- [`KB-KGV-017` — Công bố giá vốn chính thức và ghi nhận giá vốn hàng bán](KB-KGV-017-cong-bo-don-gia-ton-kho-va-ghi-nhan-gia-von-xuat-ban.md)
- [`KB-KGV-018` — Đối soát giá vốn cuối kỳ và cập nhật đột xuất giữa kỳ](KB-KGV-018-doi-soat-gia-von-cuoi-ky-va-cap-nhat-dot-xuat-giua-ky.md)
- [`KB-KGV-020` — Định giá hàng trả, tiêu hủy và chênh lệch thừa thiếu](KB-KGV-020-dinh-gia-hang-tra-tieu-huy-va-chenh-lech-thua-thieu.md)
