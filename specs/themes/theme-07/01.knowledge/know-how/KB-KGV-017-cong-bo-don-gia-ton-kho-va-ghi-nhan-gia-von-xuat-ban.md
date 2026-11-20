---
id: KB-KGV-017-cong-bo-don-gia-ton-kho-va-ghi-nhan-gia-von-xuat-ban
type: know-how
theme: theme-07
title: cong-bo-don-gia-ton-kho-va-ghi-nhan-gia-von-xuat-ban
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-017-cong-bo-don-gia-ton-kho-va-ghi-nhan-gia-von-xuat-ban — cong-bo-don-gia-ton-kho-va-ghi-nhan-gia-von-xuat-ban

## 1. Bối cảnh

### Câu trả lời ngắn

Khi hàng được bàn giao, dòng xuất ghi giá vốn ban đầu theo phiên bản giá vốn chính thức đang hiệu lực. Cuối kỳ, nếu kết quả bình quân được chọn khác với giá đã dùng, hệ thống ghi một **điều chỉnh giá vốn liên kết** đến lượng đã xuất và một điều chỉnh giá trị tồn cuối kỳ. Không chạy lại, không sửa và không thay thế đơn bán hoặc movement xuất gốc.

Giá vốn dự kiến từ kịch bản chiết khấu mua hàng theo kỳ chỉ phục vụ quyết định định giá bán; nó không được dùng làm giá vốn kế toán.

### Vì sao vấn đề này quan trọng?

Đơn bán và movement xuất là bằng chứng về việc gì đã xảy ra tại thời điểm giao hàng. Nếu cuối kỳ sửa giá trị trên bản ghi gốc, báo cáo đã xuất trước đó và audit trail sẽ không còn giải thích được. Mô hình “bản ghi ban đầu + điều chỉnh liên kết” vừa giữ lịch sử bất biến, vừa cho phép kế toán có số cuối kỳ chính xác.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Thẩm quyền |
|---|---|---|
| Giá vốn chính thức | Phiên bản đơn giá tồn kho được công bố và có thời điểm hiệu lực | Miền giá vốn |
| Giá vốn ban đầu của giao dịch | Giá vốn chính thức tại thời điểm bàn giao × lượng xuất | Ghi cùng kết quả xuất |
| Điều chỉnh giá vốn cuối kỳ | Phần chênh lệch sau khi đối soát phương pháp được chọn | Batch chốt kỳ |
| Giá vốn tham chiếu định giá | Con số làm đầu vào cho giá sàn/niêm yết | Miền định giá bán |
| Giá vốn dự kiến | Kết quả giả định từ kịch bản mua hàng | Không phải số kế toán |

### Quy tắc vận hành

1. Mỗi dòng xuất giữ `official_cost_version_id` và đơn giá đã dùng tại thời điểm bàn giao.
2. Công bố giá vốn mới tạo version có thời điểm hiệu lực; không sửa version cũ.
3. Chốt kỳ tạo một batch liên kết gồm điều chỉnh giá vốn lượng đã xuất, điều chỉnh tồn cuối kỳ và phiên bản giá vốn chính thức mới.
4. Mỗi adjustment ghi đúng phần chênh lệch, có liên kết đến nguồn và kỳ; không ghi lại toàn bộ giá trị.
5. Báo cáo lợi nhuận sau đối soát cộng giá vốn ban đầu với adjustment; báo cáo tại giao dịch giữ cách nhìn ban đầu.
6. Công bố giá vốn chính thức không tự đổi giá vốn tham chiếu định giá, giá sàn, giá niêm yết hoặc giá bán đang hiệu lực.
7. Lần chạy tính giá không được hủy sau khi bắt đầu; lần tính lại là một run kế tiếp có liên kết thay thế, còn run cũ giữ nguyên kết quả và dấu vết.

### Ví dụ minh họa

Ngày 10, cửa hàng bàn giao 10 đơn vị khi giá vốn chính thức là 80.000 đồng, nên giá vốn ban đầu là 800.000 đồng. Cuối kỳ, phương pháp được chọn cho ra 82.000 đồng/đơn vị. Hệ thống không sửa dòng bán ngày 10; thay vào đó ghi điều chỉnh giá vốn +20.000 đồng liên kết đến 10 đơn vị đã xuất. Báo cáo tại giao dịch vẫn cho biết quyết định lúc bán dùng 80.000 đồng; báo cáo sau đối soát cho tổng giá vốn 820.000 đồng.

### Ngoại lệ và cách làm sai

- **Sửa đơn giá trên dòng xuất cũ:** phá lịch sử và dấu vết phiên bản.
- **Dùng giá vốn dự kiến làm COGS:** biến giả định thương mại thành số liệu kế toán.
- **Ghi lại toàn bộ giá trị thay vì phần chênh:** dễ đếm trùng khi tổng hợp ledger.
- **Tự đổi giá bán sau khi công bố giá vốn:** xâm phạm thẩm quyền định giá bán.

## 3. Ý nghĩa đối với Theme

### Điều cần ghi nhớ

- **Giá vốn ban đầu được chụp tại bàn giao.**
- **Cuối kỳ ghi adjustment, không viết lại giao dịch.**
- **Giá vốn kế toán và giá vốn tham chiếu định giá là hai khái niệm khác nhau.**
- **Mỗi phiên bản và adjustment đều phải truy được nguồn.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-017` |
| Cụm tri thức | [`KGV-C04`](00-table-of-contents.md#c04-giá-vốn-và-định-giá-tồn-kho) |
| Loại bài | `VALUATION` |
| Quyết định chính | [`T7-DR-052`](../decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3), [`T7-DR-053`](../decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3), [`T7-DR-052#REQ-01`](../decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3), [`T7-DR-056`](../decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3), [`T7-DR-053`](../decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3), [`T7-DR-102`](../decisions/decision-register.md#314-g14-chi%E1%BA%BFt-kh%E1%BA%A5u-mua-h%C3%A0ng-%C4%91%E1%BB%8Bnh-gi%C3%A1-b%C3%A1n-v%C3%A0-l%E1%BB%A3i-nhu%E1%BA%ADn), [`T7-DR-060#REQ-01`](../decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3) |
| Trạng thái | Áp dụng |
| Mức bằng chứng | `STATIC_VALIDATED` |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-015` — Đơn giá tồn kho chính thức và tổng giá trị ghi sổ](KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md)
- [`KB-KGV-016` — Vì sao sử dụng song song hai phương pháp tính giá vốn?](KB-KGV-016-vi-sao-tinh-song-song-hai-phuong-phap-gia-von.md)
- [`KB-KGV-018` — Đối soát giá vốn cuối kỳ và cập nhật đột xuất giữa kỳ](KB-KGV-018-doi-soat-gia-von-cuoi-ky-va-cap-nhat-dot-xuat-giua-ky.md)
- [`KB-KGV-044` — Từ giá vốn tham chiếu định giá đến giá bán giao dịch](KB-KGV-044-tu-gia-von-tham-chieu-den-gia-ban-giao-dich.md)
- [`KB-KGV-045` — Rà soát giá vốn tham chiếu định giá sau chốt kỳ](KB-KGV-045-ra-soat-gia-von-tham-chieu-sau-chot-ky.md)
