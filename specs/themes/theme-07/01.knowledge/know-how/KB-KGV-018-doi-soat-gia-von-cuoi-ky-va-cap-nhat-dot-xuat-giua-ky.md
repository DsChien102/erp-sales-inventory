---
id: KB-KGV-018-doi-soat-gia-von-cuoi-ky-va-cap-nhat-dot-xuat-giua-ky
type: know-how
theme: theme-07
title: doi-soat-gia-von-cuoi-ky-va-cap-nhat-dot-xuat-giua-ky
owner: BA
status: FROZEN
source_baseline: v3.12.0
---
# KB-KGV-018-doi-soat-gia-von-cuoi-ky-va-cap-nhat-dot-xuat-giua-ky — doi-soat-gia-von-cuoi-ky-va-cap-nhat-dot-xuat-giua-ky

## 1. Bối cảnh

### Câu trả lời ngắn

Chốt giá vốn chỉ được thực hiện trên tập movement ổn định đến một cut-off. Operation `UNKNOWN`, hàng nhập chưa xác lập giá trị nhập ban đầu, kiểm kê/điều chỉnh/correction chain chưa hoàn tất hoặc hồ sơ đối soát có khả năng làm sai kỳ đều là blocker. Khi đủ điều kiện, hệ thống tính bản nháp; kế toán kiểm tra và công bố một batch liên kết. Cập nhật đột xuất giữa kỳ cũng phải đối soát đến cut-off riêng, ghi adjustment và chỉ áp dụng giá mới cho giao dịch sau mốc hiệu lực.

### Vì sao vấn đề này quan trọng?

Bình quân cuối kỳ phụ thuộc cả lượng và giá trị trong kỳ. Một operation chưa rõ kết quả hoặc một goods receipt chưa có giá có thể thay đổi tử số hoặc mẫu số sau khi công bố. Blocker và cut-off giúp kỳ đóng có thể chứng minh. Batch liên kết giúp ba ảnh hưởng — lượng đã xuất, tồn còn lại và phiên bản giá mới — không bị tách rời.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa |
|---|---|
| Cut-off | Ledger sequence xác định tập dữ liệu được tính |
| Blocker | Điều kiện chưa giải quyết có thể làm thay đổi kết quả |
| Bản nháp tính giá | Kết quả hệ thống tính để kế toán kiểm tra |
| Batch công bố | Nhóm nguyên tử/liên kết các adjustment và phiên bản giá |
| Cập nhật đột xuất | Công bố giữa kỳ với cut-off và hiệu lực riêng |

### Quy tắc vận hành

1. Không chốt khi còn `UNKNOWN`, goods receipt chờ giá trực tiếp, kiểm kê/điều chỉnh/correction chưa hoàn tất hoặc đối soát trọng yếu chưa đóng.
2. Hệ thống tính song song hai phương pháp; tenant chỉ định phương pháp nguồn cho phiên bản chính thức.
3. Kế toán xem dữ liệu đầu vào, chênh lệch và phạm vi trước khi công bố; không cần thêm một lớp duyệt thứ hai.
4. Batch chốt kỳ ghi đúng phần chênh của giá vốn hàng đã xuất và tồn cuối kỳ, đồng thời tạo phiên bản giá vốn mới.
5. Mỗi thành phần có chung `cost_calculation_run_id`, kỳ, cut-off và nguồn.
6. Cập nhật giữa kỳ không hồi tố giao dịch trước cut-off; mọi ảnh hưởng trước mốc được thể hiện bằng adjustment.
7. Sau công bố, miền định giá bán nhận sự kiện để rà soát, không tự động thay đổi giá bán.
8. Mỗi thành phần chi phí đến muộn có khóa tự nhiên ổn định theo nguồn, chứng từ/dòng, loại thành phần và kỳ hiệu lực; retry không tạo giá trị lần hai.
9. Khi dữ liệu đến muộn làm thay đổi phạm vi đã tính, hệ thống đánh dấu đúng sản phẩm/kỳ là `DIRTY` và tạo run kế tiếp liên kết run bị thay thế; không sửa run đã công bố và không tính lại ngoài phạm vi bị ảnh hưởng.

### Ví dụ minh họa

Kỳ tháng 8 có một goods receipt đang `VALUATION_PENDING`; hệ thống chặn công bố vì giá trị nhập ban đầu chưa được xác lập. Sau khi BJ03 xác lập giá trị nhập ban đầu và đối soát lại, run tháng 8 tính kết quả, kế toán kiểm tra rồi công bố batch. Batch gồm COGS true-up cho hàng đã bán, valuation adjustment cho hàng còn lại và giá vốn chính thức phiên bản mới có hiệu lực từ đầu kỳ tiếp theo.

Nếu ngày 15 cần cập nhật khẩn cấp, hệ thống lập run đến cut-off ngày 15. Giá mới chỉ dùng cho lần bàn giao sau cut-off; phần trước cut-off được giữ nguyên và điều chỉnh bằng bản ghi liên kết.

### Ngoại lệ và cách làm sai

- **Chốt khi còn blocker:** số kỳ đóng có thể thay đổi sau công bố.
- **Cập nhật trực tiếp một con số giá:** mất quan hệ với ledger và phạm vi tính.
- **Sửa movement cũ để “khớp” giá mới:** phá tính bất biến.
- **Coi việc giao event định giá thất bại là lý do đảo batch:** kết quả kế toán đã commit vẫn giữ nguyên; event phải được gửi lại.

## 3. Ý nghĩa đối với Theme

### Điều cần ghi nhớ

- **Cut-off và blocker xác định tính đầy đủ của kỳ.**
- **Công bố là một batch liên kết, không phải sửa một trường giá.**
- **Cập nhật giữa kỳ có ranh giới hiệu lực rõ ràng.**
- **Định giá bán rà soát sau công bố; không bị ghi đè tự động.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-018` |
| Cụm tri thức | [`KGV-C04`](00-table-of-contents.md#c04-giá-vốn-và-định-giá-tồn-kho) |
| Loại bài | `VALUATION` |
| Quyết định chính | [`T7-DR-056`](../decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3), [`T7-DR-057`](../decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3), [`T7-DR-058`](../decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3), [`T7-DR-059`](../decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3), [`T7-DR-060`](../decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3), [`T7-DR-101`](../decisions/decision-register.md#314-g14-chi%E1%BA%BFt-kh%E1%BA%A5u-mua-h%C3%A0ng-%C4%91%E1%BB%8Bnh-gi%C3%A1-b%C3%A1n-v%C3%A0-l%E1%BB%A3i-nhu%E1%BA%ADn), [`T7-DR-101`](../decisions/decision-register.md#314-g14-chi%E1%BA%BFt-kh%E1%BA%A5u-mua-h%C3%A0ng-%C4%91%E1%BB%8Bnh-gi%C3%A1-b%C3%A1n-v%C3%A0-l%E1%BB%A3i-nhu%E1%BA%ADn), [`T7-DR-100#REQ-03`](../decisions/decision-register.md#314-g14-chi%E1%BA%BFt-kh%E1%BA%A5u-mua-h%C3%A0ng-%C4%91%E1%BB%8Bnh-gi%C3%A1-b%C3%A1n-v%C3%A0-l%E1%BB%A3i-nhu%E1%BA%ADn), [`T7-DR-058`](../decisions/decision-register.md#37-g07-gi%C3%A1-tr%E1%BB%8B-t%E1%BB%93n-gi%C3%A1-v%E1%BB%91n-v%C3%A0-ch%E1%BB%91t-k%E1%BB%B3) |
| Trạng thái | Áp dụng |
| Mức bằng chứng | `STATIC_VALIDATED` |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-016` — Vì sao sử dụng song song hai phương pháp tính giá vốn?](KB-KGV-016-vi-sao-tinh-song-song-hai-phuong-phap-gia-von.md)
- [`KB-KGV-017` — Công bố giá vốn chính thức và ghi nhận giá vốn hàng bán](KB-KGV-017-cong-bo-don-gia-ton-kho-va-ghi-nhan-gia-von-xuat-ban.md)
- [`KB-KGV-029` — Tính nguyên tử khi ghi tồn kho và phát sự kiện](KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md)
- [`KB-KGV-045` — Rà soát giá vốn tham chiếu định giá sau chốt kỳ](KB-KGV-045-ra-soat-gia-von-tham-chieu-sau-chot-ky.md)
