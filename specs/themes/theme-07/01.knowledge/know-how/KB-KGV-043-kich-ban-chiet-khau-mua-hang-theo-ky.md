---
id: KB-KGV-043-kich-ban-chiet-khau-mua-hang-theo-ky
type: know-how
theme: theme-07
title: kich-ban-chiet-khau-mua-hang-theo-ky
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-043-kich-ban-chiet-khau-mua-hang-theo-ky — kich-ban-chiet-khau-mua-hang-theo-ky

## 1. Bối cảnh

### Câu trả lời ngắn

Người có quyền có thể lập một **kịch bản chiết khấu mua hàng theo kỳ** trước khi có đơn mua hoặc hàng về. Kịch bản mô tả giả định theo sản phẩm — như tỷ lệ giảm, số tiền ưu đãi hoặc hàng tặng quy đổi — rồi tính giá vốn dự kiến. Kết quả có thể làm đầu vào cho dự thảo định giá bán, nhưng không thay đổi tồn kho, công nợ, sổ giá trị, giá vốn chính thức hoặc báo cáo kế toán.

Chỉ khoản ưu đãi đã phát sinh, có chứng từ hợp lệ và được phân bổ theo chính sách kế toán mới có thể đi vào định giá tồn kho thực tế.

### Vì sao vấn đề này quan trọng?

Chủ cửa hàng thường phải ra quyết định giá trước khi đạt KPI nhà cung cấp. Không có công cụ kịch bản, họ phải tính ngoài hệ thống hoặc nhầm giá dự kiến với giá vốn thật. Tách kịch bản khỏi ledger cho phép ra quyết định thương mại sớm mà vẫn giữ số kế toán dựa trên sự kiện đã phát sinh.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Có ghi sổ? |
|---|---|---|
| Kịch bản | Tập giả định về mua hàng và ưu đãi | Không |
| Giá vốn dự kiến | Kết quả tính trên giả định | Không |
| Khoản ưu đãi đã phát sinh | Quyền lợi có bằng chứng theo chính sách nhà cung cấp | Có thể, sau xác nhận/phân bổ |
| Giá vốn chính thức | Đơn giá được công bố từ dữ liệu kế toán hợp lệ | Có |
| Giá vốn tham chiếu định giá | Đầu vào được công bố cho định giá bán | Không tự tạo bút toán |

### Quy tắc vận hành

1. Kịch bản có ID, phiên bản, người tạo, kỳ, sản phẩm, giả định và trạng thái riêng; không cần PO để khởi tạo.
2. Tính riêng theo sản phẩm; phương pháp quy đổi tỷ lệ, số tiền hoặc hàng tặng phải hiển thị minh bạch.
3. Kết quả không ghi Inventory Operation, quantity/value movement, công nợ hoặc official cost version.
4. Người có quyền có thể dùng kết quả để tạo một phiên bản giá vốn tham chiếu định giá nguồn `PROJECTED_PURCHASE_DISCOUNT`.
5. Việc công bố giá vốn tham chiếu không đồng nghĩa công bố giá bán; nó tạo dự thảo/gói thay đổi cho miền định giá.
6. Khi giả định đổi, phải tạo phiên bản mới hoặc tính lại; không âm thầm sửa con số đã dùng làm nguồn.
7. Khi ưu đãi thực tế phát sinh, xử lý bằng chứng từ và quy tắc định giá tồn kho riêng; không “chuyển trạng thái” kịch bản thành bút toán.

### Ví dụ minh họa

Nhà cung cấp dự kiến giảm 5% nếu cửa hàng mua 1.000 hộp trong quý. Giá mua niêm yết là 100.000 đồng/hộp; kịch bản cho giá vốn dự kiến 95.000 đồng trước các chi phí khác. Chủ cửa hàng có thể dùng 95.000 đồng làm nguồn tham chiếu để cân nhắc giá sàn và giá niêm yết mới. Nếu cuối quý chỉ đạt mức giảm 3%, kế toán ghi nhận ưu đãi thực tế theo chứng từ; kịch bản 5% vẫn là lịch sử giả định và không được dùng để sửa sổ.

### Ngoại lệ và cách làm sai

- **Gọi giá dự kiến là giá vốn chính thức:** xóa ranh giới giữa dự báo và kế toán.
- **Ghi giảm giá trị tồn ngay khi tạo kịch bản:** hạch toán một quyền lợi chưa phát sinh.
- **Sửa kịch bản đã được công bố làm nguồn:** mất provenance của quyết định giá.
- **Tự thay đổi giá bán khi kịch bản đổi:** bỏ qua phê duyệt/công bố định giá.

## 3. Ý nghĩa đối với Theme

### Điều cần ghi nhớ

- **Kịch bản là công cụ ra quyết định, không phải chứng từ kế toán.**
- **Giá vốn dự kiến có thể làm nguồn định giá bán nhưng không phải COGS.**
- **Giả định và kết quả phải có phiên bản, nguồn và người chịu trách nhiệm.**
- **Ưu đãi thực tế đi qua quy trình chứng từ riêng.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-043` |
| Cụm tri thức | [`KGV-C12`](00-table-of-contents.md#c12-chiết-khấu-mua-hàng-và-định-giá-bán) |
| Loại bài | `PLANNING` |
| Quyết định chính | [`T7-DR-099`](../decisions/decision-register.md#314-g14-chi%E1%BA%BFt-kh%E1%BA%A5u-mua-h%C3%A0ng-%C4%91%E1%BB%8Bnh-gi%C3%A1-b%C3%A1n-v%C3%A0-l%E1%BB%A3i-nhu%E1%BA%ADn), [`T7-DR-098#REQ-01`](../decisions/decision-register.md#314-g14-chi%E1%BA%BFt-kh%E1%BA%A5u-mua-h%C3%A0ng-%C4%91%E1%BB%8Bnh-gi%C3%A1-b%C3%A1n-v%C3%A0-l%E1%BB%A3i-nhu%E1%BA%ADn), [`T7-DR-100`](../decisions/decision-register.md#314-g14-chi%E1%BA%BFt-kh%E1%BA%A5u-mua-h%C3%A0ng-%C4%91%E1%BB%8Bnh-gi%C3%A1-b%C3%A1n-v%C3%A0-l%E1%BB%A3i-nhu%E1%BA%ADn) |
| Trạng thái | Áp dụng như năng lực liên miền; không có quyền tài chính |
| Mức bằng chứng | `STATIC_VALIDATED` |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-019` — Các thành phần hình thành giá nhập thực tế](KB-KGV-019-cac-thanh-phan-hinh-thanh-gia-nhap-thuc-te.md)
- [`KB-KGV-044` — Từ giá vốn tham chiếu định giá đến giá bán giao dịch](KB-KGV-044-tu-gia-von-tham-chieu-den-gia-ban-giao-dich.md)
- [`KB-KGV-045` — Rà soát giá vốn tham chiếu định giá sau chốt kỳ](KB-KGV-045-ra-soat-gia-von-tham-chieu-sau-chot-ky.md)
