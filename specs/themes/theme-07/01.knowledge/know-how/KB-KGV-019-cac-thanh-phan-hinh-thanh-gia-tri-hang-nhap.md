---
id: KB-KGV-019
type: know-how
theme: theme-07
title: "Các thành phần hình thành giá trị hàng nhập"
status: ACTIVE
source_baseline: v3.12.0
---
# KB-KGV-019 — Các thành phần hình thành giá trị hàng nhập

## 1. Trả lời ngắn

Giá trị hàng nhập không phải một con số người dùng nhập tùy ý. Hệ thống hình thành giá trị từ các **thành phần có căn cứ**, sau đó xác định thành phần nào đã đủ điều kiện để ghi nhận tại BJ03 và thành phần nào chỉ được ghi điều chỉnh qua BJ13 khi xuất hiện sau đó.

Công thức nghiệp vụ tổng quát:

```text
Giá trị hàng nhập
=
Giá mua
− Các khoản giảm giá trị mua
+ Thuế/phí không được thu hồi
+ Chi phí mua trực tiếp được phân bổ
± Các điều chỉnh hợp lệ khác
```

## 2. Vì sao phải tách theo thành phần

Một lần nhận hàng có thể biết giá mua trước khi có hóa đơn vận chuyển, hoặc hóa đơn NCC có thể đến sau và khác với căn cứ ban đầu. Nếu chỉ lưu một trường “giá nhập”, hệ thống không thể trả lời con số đó đến từ đâu, phần nào thay đổi và vì sao cần tính lại giá vốn.

Vì vậy mỗi thành phần phải giữ ít nhất: loại thành phần, giá trị có dấu, nguồn, phiên bản/thời điểm hiệu lực, phạm vi lượng hàng thực sự áp dụng và cách phân bổ khi nguồn áp dụng cho nhiều dòng/lần nhận.

## 3. Thành phần và cách xử lý

| Thành phần | Tác động vào giá trị hàng nhập | Ví dụ nguồn | Có thể ở BJ03 | Có thể ở BJ13 |
|---|---:|---|---:|---:|
| Giá mua hàng | `+` | Đơn mua/hóa đơn do Theme 10 cung cấp hoặc căn cứ giá trực tiếp của Quick | Có | Có, nếu căn cứ mới làm thay đổi giá đã xác nhận |
| Chiết khấu/giảm giá đã xác lập | `−` | Chứng từ/điều khoản thương mại đã có hiệu lực | Có | Có |
| Thuế, phí không được thu hồi | `+` | Chứng từ + chính sách thuế của tenant/giao dịch | Có | Có |
| Thuế được thu hồi/khấu trừ | Không vào giá trị hàng nhập | Chính sách thuế có thẩm quyền | Không | Không |
| Vận chuyển, bốc xếp, bảo hiểm và chi phí mua trực tiếp đủ điều kiện | `+` sau phân bổ | Chứng từ chi phí | Có nếu đã đủ căn cứ | Có nếu đến sau |
| Quyền lợi thương mại đã xác lập | `−` hoặc theo bản chất nguồn | Theme 10 | Có nếu đã xác lập trước BJ03 | Có nếu xác lập sau BJ03 |
| Quyền lợi/chiết khấu dự kiến | Không ghi thật | Dự báo Theme 10 | Không | Không |

## 4. BJ03 hay BJ13 được quyết định bởi thời điểm căn cứ đủ điều kiện

Không chia máy móc theo loại chi phí.

- Thành phần **đã biết và đủ căn cứ trước khi BJ03 xác nhận** được đưa vào giá trị nhập ban đầu.
- Thành phần **xuất hiện, thay đổi hoặc đủ điều kiện sau khi BJ03 đã hoàn tất** được ghi như điều chỉnh giá trị hàng nhập qua BJ13.
- Nếu BJ03 nhập sai một fact đã biết thì đó là **sửa sai**, không phải điều chỉnh do business fact đến sau.

Ví dụ: phí vận chuyển đã có hóa đơn trước khi xác nhận BJ03 thì có thể đi thẳng vào giá trị ban đầu; cùng khoản phí nhưng hóa đơn đến ba ngày sau thì đi BJ13.

## 5. Thuế đầu vào

Theme 7 không cho người dùng tự chọn “VAT được khấu trừ hay không”. Theme 7 nhận kết quả xử lý thuế từ chính sách có thẩm quyền và chỉ đưa **phần thuế/phí không được thu hồi** vào giá trị hàng nhập.

Phase hiện tại phục vụ hộ kinh doanh nên VAT đầu vào được xem là không thu hồi theo chính sách hiện hành của tenant. Mô hình vẫn giữ tách biệt `recoverable` và `non-recoverable` để sau này hỗ trợ doanh nghiệp áp dụng phương pháp khấu trừ hoặc khấu trừ một phần mà không phải đổi BJ03/BJ13.

## 6. Nhận theo chứng từ và nhập hàng nhanh

### Nhận theo chứng từ
Theme 10 sở hữu nguồn thương mại như đơn mua, hóa đơn NCC, giá, chiết khấu và trạng thái tranh chấp thương mại. Theme 7 dùng các thành phần Theme 10 đã xác lập để tính giá trị cho **lượng hàng thực tế đã nhận**; Theme 7 không sửa dữ liệu nguồn.

### Nhập hàng nhanh
nhập hàng nhanh không phụ thuộc Theme 10. Khi chưa có nguồn thương mại cấu trúc, người có quyền tài chính có thể lập **căn cứ giá trực tiếp** trong Theme 7. Căn cứ này phải nói rõ giá, tiền tệ, cách hiểu đã/chưa gồm thuế khi cần, nguồn, thời điểm và dấu vết người xác lập.

Nếu hóa đơn đến sau và làm thay đổi giá trị đã xác nhận thì phần chênh lệch đi BJ13, không mở lại BJ03 để viết lại lịch sử.

## 7. Phân bổ

Nguồn và cách phân bổ là hai fact khác nhau. Ví dụ hóa đơn vận chuyển 1.000.000 đồng là nguồn; việc phân 600.000 cho Goods receipt A và 400.000 cho Goods receipt B là kết quả phân bổ.

Phase 1 có thể dùng cách phân bổ được policy cho phép như theo số lượng, theo giá trị hàng hoặc số tiền nhập trực tiếp. Tổng kết quả phải khớp tổng nguồn sau quy tắc làm tròn xác định; không được tạo chênh lệch âm thầm.

## 8. Ngoại tệ

Sổ tồn và giá vốn chính thức dùng VND. Giá trị ngoại tệ chỉ được ghi khi có tỷ giá từ nguồn có thẩm quyền. Chênh lệch tỷ giá phát sinh ở thanh toán sau này không quay lại sửa giá trị tồn đã ghi.

## 9. Điều cần ghi nhớ

- BJ03 ghi **giá trị nhập ban đầu**, không công bố giá vốn chính thức.
- BJ13 ghi **điều chỉnh giá trị hàng nhập có dấu**, không chỉ chi phí tăng thêm.
- BJ14 mới tính và công bố `OfficialCostVersion` theo phương pháp cấu hình cấp tenant.
- Dự báo không được biến thành giá trị tồn thật.
- Nguồn sai phải sửa ở owner của nguồn; Theme 7 không chỉnh PO/hóa đơn để làm cho valuation “khớp”.

## 10. Nguồn quyết định và liên quan

- `T7-DR-185…195` — semantic BJ03/BJ13/BJ14 hiện hành.
- `BC-IV-01/04/05/06` — xác lập và điều chỉnh giá trị hàng nhập.
- `BJ-03`, `BJ-13`, `BJ-14`.
