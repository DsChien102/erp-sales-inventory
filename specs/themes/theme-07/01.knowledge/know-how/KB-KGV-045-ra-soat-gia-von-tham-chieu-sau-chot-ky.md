---
id: KB-KGV-045-ra-soat-gia-von-tham-chieu-sau-chot-ky
type: know-how
theme: theme-07
title: ra-soat-gia-von-tham-chieu-sau-chot-ky
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-045-ra-soat-gia-von-tham-chieu-sau-chot-ky — ra-soat-gia-von-tham-chieu-sau-chot-ky

## 1. Bối cảnh

### Câu trả lời ngắn

Hệ thống phân luồng theo **nguồn của phiên bản giá vốn tham chiếu đang hiệu lực**, không theo mức chênh lệch:

- Nếu nguồn là giá vốn chính thức kỳ trước (`OFFICIAL_COST`), sản phẩm được đưa vào lựa chọn cập nhật hàng loạt sang giá vốn chính thức mới.
- Nếu nguồn là kịch bản chiết khấu mua hàng (`PROJECTED_PURCHASE_DISCOUNT`), sản phẩm bị loại khỏi cập nhật hàng loạt. Người có quyền chọn giữ nguyên, dùng giá vốn chính thức mới hoặc tính lại kịch bản.

Kết quả cập nhật chỉ tạo phiên bản tham chiếu/dự thảo định giá. Giá sàn, giá niêm yết và giá bán đang hiệu lực không đổi cho đến khi được công bố riêng.

### Vì sao vấn đề này quan trọng?

Một tham chiếu dựa trên official cost thường có ý định “đi theo số kế toán”, nên có thể rà soát theo nhóm. Một tham chiếu dựa trên kịch bản phản ánh quyết định thương mại có chủ ý; ghi đè tự động sẽ xóa giả định và trách nhiệm của người quyết định. Dùng loại nguồn làm quy tắc đơn giản, giải thích được và không cần cấu hình ngưỡng chênh lệch.

## 2. Nội dung nền tảng

### Ma trận quyết định

| Nguồn hiện tại | Mặc định đưa vào batch? | Lựa chọn |
|---|---:|---|
| `OFFICIAL_COST` kỳ trước | Có | Chọn/bỏ chọn cập nhật sang official cost mới |
| `PROJECTED_PURCHASE_DISCOUNT` | Không | Giữ nguyên / dùng official cost mới / tính lại kịch bản |

### Quy tắc vận hành

1. Sự kiện công bố official cost mới mở một đợt rà soát định giá, không ghi đè trực tiếp.
2. Phân nhóm chỉ theo `source_type`; không dùng ngưỡng chênh lệch tối thiểu/tối đa.
3. Batch chỉ bao gồm các sản phẩm nguồn `OFFICIAL_COST` được người có quyền chọn.
4. Sản phẩm nguồn kịch bản luôn cần quyết định riêng và ghi lựa chọn, người thực hiện, thời điểm.
5. Chọn “tính lại” tạo phiên bản kịch bản/kết quả mới trước khi công bố tham chiếu.
6. Mọi thay đổi tham chiếu tạo version, giữ source version cũ và không ghi ledger.
7. Dự thảo giá sàn/niêm yết được tính lại nếu người dùng yêu cầu; giá đang hiệu lực chỉ đổi sau price publication.
8. Báo cáo phải phân biệt lợi nhuận tại giao dịch, lợi nhuận sau đối soát và lợi nhuận dự kiến.

### Ví dụ minh họa

Sản phẩm A có giá vốn tham chiếu 80.000 từ official cost tháng 7. Sản phẩm B có tham chiếu 75.000 từ kịch bản chiết khấu quý 3. Cuối tháng 8, official cost mới lần lượt là 82.000 và 79.000.

A xuất hiện trong danh sách cập nhật hàng loạt; người có quyền có thể chọn tạo tham chiếu 82.000. B không bị ghi đè: người đó có thể giữ 75.000, dùng 79.000 hoặc tính lại kịch bản. Dù chọn phương án nào, giá niêm yết hiện tại chỉ thay đổi sau khi dự thảo giá được xem xét và công bố.

### Ngoại lệ và cách làm sai

- **Ghi đè mọi tham chiếu sau chốt kỳ:** xóa quyết định thương mại dựa trên kịch bản.
- **Dùng phần trăm chênh lệch để suy đoán nguồn:** một chênh lệch nhỏ vẫn có thể mang ý nghĩa nguồn khác nhau.
- **Tự công bố giá bán cùng batch:** trộn thẩm quyền giá vốn và định giá.
- **Không giữ source version:** không thể giải thích vì sao một mức giá được chọn.
- **Gọi lợi nhuận dự kiến là lợi nhuận kế toán:** trộn số giả định và số đã đối soát.

## 3. Ý nghĩa đối với Theme

### Điều cần ghi nhớ

- **Nguồn tham chiếu quyết định đường rà soát.**
- **Nguồn official cost có thể cập nhật theo nhóm; nguồn kịch bản phải quyết định riêng.**
- **Không dùng ngưỡng chênh lệch cho việc phân luồng này.**
- **Cập nhật tham chiếu không đồng nghĩa cập nhật giá bán.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-045` |
| Cụm tri thức | [`KGV-C12`](00-table-of-contents.md#c12-chiết-khấu-mua-hàng-và-định-giá-bán) |
| Loại bài | `PRICING_CONTROL` |
| Quyết định chính | [`T7-DR-101`](../decisions/decision-register.md#314-g14-chi%E1%BA%BFt-kh%E1%BA%A5u-mua-h%C3%A0ng-%C4%91%E1%BB%8Bnh-gi%C3%A1-b%C3%A1n-v%C3%A0-l%E1%BB%A3i-nhu%E1%BA%ADn), [`T7-DR-101`](../decisions/decision-register.md#314-g14-chi%E1%BA%BFt-kh%E1%BA%A5u-mua-h%C3%A0ng-%C4%91%E1%BB%8Bnh-gi%C3%A1-b%C3%A1n-v%C3%A0-l%E1%BB%A3i-nhu%E1%BA%ADn), [`T7-DR-100#REQ-03`](../decisions/decision-register.md#314-g14-chi%E1%BA%BFt-kh%E1%BA%A5u-mua-h%C3%A0ng-%C4%91%E1%BB%8Bnh-gi%C3%A1-b%C3%A1n-v%C3%A0-l%E1%BB%A3i-nhu%E1%BA%ADn), [`T7-DR-102`](../decisions/decision-register.md#314-g14-chi%E1%BA%BFt-kh%E1%BA%A5u-mua-h%C3%A0ng-%C4%91%E1%BB%8Bnh-gi%C3%A1-b%C3%A1n-v%C3%A0-l%E1%BB%A3i-nhu%E1%BA%ADn) |
| Trạng thái | Áp dụng như hợp đồng liên miền |
| Mức bằng chứng | `STATIC_VALIDATED` |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-017` — Công bố giá vốn chính thức và ghi nhận giá vốn hàng bán](KB-KGV-017-cong-bo-don-gia-ton-kho-va-ghi-nhan-gia-von-xuat-ban.md)
- [`KB-KGV-043` — Kịch bản chiết khấu mua hàng theo kỳ](KB-KGV-043-kich-ban-chiet-khau-mua-hang-theo-ky.md)
- [`KB-KGV-044` — Từ giá vốn tham chiếu định giá đến giá bán giao dịch](KB-KGV-044-tu-gia-von-tham-chieu-den-gia-ban-giao-dich.md)
