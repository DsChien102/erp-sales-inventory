---
id: KB-KGV-044-tu-gia-von-tham-chieu-den-gia-ban-giao-dich
type: know-how
theme: theme-07
title: tu-gia-von-tham-chieu-den-gia-ban-giao-dich
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-044-tu-gia-von-tham-chieu-den-gia-ban-giao-dich — tu-gia-von-tham-chieu-den-gia-ban-giao-dich

## 1. Bối cảnh

### Câu trả lời ngắn

Chuỗi định giá bán có bốn lớp chính:

1. **Giá vốn tham chiếu định giá**: đầu vào do người có quyền công bố, lấy từ giá vốn chính thức hoặc một kịch bản chiết khấu mua hàng theo kỳ.
2. **Giá sàn** và **giá niêm yết**: kết quả áp chính sách lợi nhuận tối thiểu/tối đa lên giá vốn tham chiếu.
3. **Giá bán giao dịch**: giá niêm yết sau khi áp khuyến mại và bối cảnh cụ thể như sản phẩm, lượng, khách hàng và thời gian.

Giá sàn có thể cảnh báo hoặc chặn giảm sâu theo chính sách định giá. Giá vốn tham chiếu không phải giá vốn kế toán và việc cập nhật nó không tự đổi giá bán đang hiệu lực.

### Vì sao vấn đề này quan trọng?

Một con số duy nhất không thể vừa đại diện sự thật kế toán, vừa phản ánh kỳ vọng mua hàng, vừa là giá khách phải trả. Gộp các lớp làm thay đổi giả định thương mại trở thành thay đổi sổ kế toán hoặc khiến công bố giá vốn vô tình đổi giá bán. Tách lớp giúp mỗi quyết định có đúng chủ sở hữu và lịch sử.

## 2. Nội dung nền tảng

### Chuỗi giá và thẩm quyền

| Lớp giá | Nguồn/chủ sở hữu | Mục đích |
|---|---|---|
| Giá vốn chính thức | Miền giá vốn | Ghi value ledger và COGS |
| Giá vốn dự kiến | Kịch bản mua hàng | Phân tích giả định |
| Giá vốn tham chiếu định giá | Miền định giá, người có quyền công bố | Đầu vào chính sách lợi nhuận |
| Giá sàn | Chính sách định giá | Cảnh báo/chặn biên lợi nhuận thấp |
| Giá niêm yết | Chính sách định giá | Giá trước khuyến mại |
| Giá bán giao dịch | Động cơ khuyến mại + bối cảnh giao dịch | Giá cuối cùng áp cho giao dịch |

### Quy tắc vận hành

1. Mỗi phiên bản giá vốn tham chiếu lưu `source_type`, `source_version_id`, người công bố và thời điểm hiệu lực.
2. `source_type` chỉ là `OFFICIAL_COST` hoặc `PROJECTED_PURCHASE_DISCOUNT` trong phạm vi hiện tại.
3. Chính sách lợi nhuận tạo giá sàn và giá niêm yết; quy tắc làm tròn và biên thuộc miền định giá.
4. Promotion không sửa giá niêm yết; nó tính giá bán giao dịch trong một context.
5. Khi giá bán dưới sàn, hệ thống cảnh báo hoặc chặn theo chính sách đã cấu hình; không âm thầm nâng giá.
6. Mọi thay đổi giá bán cần một lần công bố giá riêng, có hiệu lực và lịch sử.
7. Giá vốn tham chiếu không ghi value movement và không được dùng thay giá vốn chính thức khi xuất hàng.

### Ví dụ minh họa

Giá vốn tham chiếu của P là 95.000 đồng. Chính sách lợi nhuận tạo giá sàn 110.000 và giá niêm yết 130.000. Khách thành viên mua 10 hộp trong tuần khuyến mại nên giá bán giao dịch là 115.000. Vì vẫn trên sàn, giao dịch được phép. Nếu promotion tính ra 105.000, hệ thống cảnh báo hoặc chặn tùy chính sách; không sửa giá niêm yết 130.000.

### Ngoại lệ và cách làm sai

- **Gọi giá vốn tham chiếu là giá vốn chính thức:** nhầm mục đích và thẩm quyền.
- **Cập nhật tham chiếu rồi đổi giá bán ngay:** bỏ qua bước xem xét/công bố.
- **Lưu giá tham chiếu không có nguồn:** không giải thích được quyết định giá.
- **Ghi đè giá niêm yết khi áp promotion:** mất khả năng tái hiện chính sách.
- **Dùng giá sàn như giá luôn phải bán:** giá sàn là rào kiểm soát, không phải niêm yết.

## 3. Ý nghĩa đối với Theme

### Điều cần ghi nhớ

- **Giá vốn kế toán và đầu vào định giá bán phải tách.**
- **Giá sàn, giá niêm yết và giá giao dịch là ba lớp khác nhau.**
- **Mọi giá tham chiếu phải có provenance.**
- **Giá bán chỉ đổi qua một lần công bố riêng.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-044` |
| Cụm tri thức | [`KGV-C12`](00-table-of-contents.md#c12-chiết-khấu-mua-hàng-và-định-giá-bán) |
| Loại bài | `PRICING` |
| Quyết định chính | [`T7-DR-098`](../decisions/decision-register.md#314-g14-chi%E1%BA%BFt-kh%E1%BA%A5u-mua-h%C3%A0ng-%C4%91%E1%BB%8Bnh-gi%C3%A1-b%C3%A1n-v%C3%A0-l%E1%BB%A3i-nhu%E1%BA%ADn), [`T7-DR-100`](../decisions/decision-register.md#314-g14-chi%E1%BA%BFt-kh%E1%BA%A5u-mua-h%C3%A0ng-%C4%91%E1%BB%8Bnh-gi%C3%A1-b%C3%A1n-v%C3%A0-l%E1%BB%A3i-nhu%E1%BA%ADn), [`T7-DR-100#REQ-01`](../decisions/decision-register.md#314-g14-chi%E1%BA%BFt-kh%E1%BA%A5u-mua-h%C3%A0ng-%C4%91%E1%BB%8Bnh-gi%C3%A1-b%C3%A1n-v%C3%A0-l%E1%BB%A3i-nhu%E1%BA%ADn), [`T7-DR-100#REQ-02`](../decisions/decision-register.md#314-g14-chi%E1%BA%BFt-kh%E1%BA%A5u-mua-h%C3%A0ng-%C4%91%E1%BB%8Bnh-gi%C3%A1-b%C3%A1n-v%C3%A0-l%E1%BB%A3i-nhu%E1%BA%ADn), [`T7-DR-100#REQ-03`](../decisions/decision-register.md#314-g14-chi%E1%BA%BFt-kh%E1%BA%A5u-mua-h%C3%A0ng-%C4%91%E1%BB%8Bnh-gi%C3%A1-b%C3%A1n-v%C3%A0-l%E1%BB%A3i-nhu%E1%BA%ADn) |
| Trạng thái | Áp dụng như hợp đồng liên miền |
| Mức bằng chứng | `STATIC_VALIDATED` |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-017` — Công bố giá vốn chính thức và ghi nhận giá vốn hàng bán](KB-KGV-017-cong-bo-don-gia-ton-kho-va-ghi-nhan-gia-von-xuat-ban.md)
- [`KB-KGV-043` — Kịch bản chiết khấu mua hàng theo kỳ](KB-KGV-043-kich-ban-chiet-khau-mua-hang-theo-ky.md)
- [`KB-KGV-045` — Rà soát giá vốn tham chiếu định giá sau chốt kỳ](KB-KGV-045-ra-soat-gia-von-tham-chieu-sau-chot-ky.md)
