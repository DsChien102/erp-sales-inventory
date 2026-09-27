---
id: KB-KGV-011-kiem-ke-hang-ton-kho-tu-khoa
type: know-how
theme: theme-07
title: kiem-ke-hang-ton-kho-tu-khoa-pham-vi-den-dieu-chinh-chenh-lech
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-011-kiem-ke-hang-ton-kho-tu-khoa — kiem-ke-hang-ton-kho-tu-khoa-pham-vi-den-dieu-chinh-chenh-lech

## 1. Bối cảnh

### Câu trả lời ngắn

Phiên kiểm kê có thể bao phủ toàn kho hoặc một tập sản phẩm, nhóm hay lô. Khi mở phiên, hệ thống chụp tập khóa số dư thuộc phạm vi tại một cut-off và khóa mọi nhập, xuất, giữ hàng liên quan. Người kiểm đếm không thấy số theo sổ trước khi nộp; chênh lệch phải đếm lại, được duyệt độc lập theo ngưỡng rồi mới tạo Inventory Adjustment. Hủy phiên chỉ giải phóng khóa và giữ lịch sử, không làm đổi tồn.

### Vì sao vấn đề này quan trọng?

Kiểm kê so sánh hàng vật lý với sổ tại cùng một thời điểm. Nếu master thay đổi hoặc giao dịch tiếp tục trong lúc đếm, chênh lệch không còn giải thích được. Việc materialize phạm vi, dùng cut-off nhất quán và khóa đúng tập số dư biến kết quả kiểm kê thành bằng chứng có thể đối soát, thay vì một lần sửa số dư theo cảm tính.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa |
|---|---|
| Phạm vi kiểm kê | Toàn kho hoặc tập sản phẩm/nhóm/lô được chọn |
| Cut-off | Ledger sequence làm mốc so sánh |
| Đếm mù | Người đếm chưa thấy lượng theo sổ trước khi nộp |
| Đếm lại | Lần xác minh phần có chênh lệch |
| Điều chỉnh | Operation ghi đúng phần chênh đã duyệt, không sửa sổ cũ |

### Quy tắc vận hành

1. Khi mở phiên, hệ thống materialize đúng các balance key thuộc phạm vi tại cut-off; thay đổi nhóm hoặc master sau đó không tự đổi phiên.
2. Từ lúc mở đến khi hoàn tất hoặc hủy, mọi nhập, xuất và giữ hàng thuộc phạm vi bị khóa.
3. Người kiểm đếm không nhìn thấy số hệ thống trước lần nộp đầu.
4. Phần chênh lệch phải được đếm lại trước khi trình duyệt.
5. Người kiểm không được duyệt kết quả của chính mình; ngưỡng duyệt có thể dùng lượng và giá trị.
6. Khi duyệt, hệ thống tạo adjustment bằng chênh lệch; chỉ operation hoàn tất mới cập nhật số dư.
7. Hủy phiên cần quyền và lý do, không điều chỉnh tồn và phải giữ toàn bộ lịch sử.

### Ví dụ minh họa

Kho mở kiểm kê nhóm vaccine tại ledger sequence 12.500. Tập balance key được chụp tại mốc đó; sản phẩm thêm vào nhóm sau mốc không thuộc phiên. Người đếm nộp 117 trong khi sổ tại cut-off là 120. Sau khi nộp, hệ thống hiện chênh lệch -3 và yêu cầu đếm lại. Lần hai vẫn 117; người khác đủ quyền duyệt. Adjustment -3 được tạo, và số dư chỉ về 117 khi operation hoàn tất.

Nếu phiên bị hủy, khóa được giải phóng nhưng số dư vẫn là 120; lý do hủy và cả hai lần đếm được giữ lại.

### Ngoại lệ và cách làm sai

- **Dùng truy vấn nhóm động khi đóng phiên:** sản phẩm mới có thể lọt vào hoặc ra khỏi phạm vi.
- **Cho giao dịch đi qua trong lúc đếm:** biến chênh lệch thành một mục tiêu di động.
- **Hiện số sổ trước khi đếm:** tạo thiên kiến xác nhận.
- **Sửa balance trực tiếp về số đếm:** phá Dữ liệu gốc là movement ledger.
- **Cho người đếm tự duyệt:** làm mất kiểm soát maker–checker.

## 3. Ý nghĩa đối với Theme

### Điều cần ghi nhớ

- **Phạm vi và cut-off được đóng băng khi mở phiên.**
- **Khóa áp dụng đúng balance key, không chỉ một nhãn nhóm.**
- **Đếm mù, đếm lại và duyệt độc lập là ba kiểm soát khác nhau.**
- **Chênh lệch chỉ đi vào tồn qua adjustment có lịch sử.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-011` |
| Cụm tri thức | [`KGV-C03`](00-table-of-contents.md#c03-kiểm-kê-trả-hàng-và-loại-bỏ) |
| Loại bài | `PROCESS` |
| Quyết định chính | [`T7-DR-035`](../decisions/decision-register.md#35-g05-ki%E1%BB%83m-k%C3%AA-v%C3%A0-%C4%91i%E1%BB%81u-ch%E1%BB%89nh-t%E1%BB%93n), [`T7-DR-035#REQ-01`](../decisions/decision-register.md#35-g05-ki%E1%BB%83m-k%C3%AA-v%C3%A0-%C4%91i%E1%BB%81u-ch%E1%BB%89nh-t%E1%BB%93n), [`T7-DR-036`](../decisions/decision-register.md#35-g05-ki%E1%BB%83m-k%C3%AA-v%C3%A0-%C4%91i%E1%BB%81u-ch%E1%BB%89nh-t%E1%BB%93n), [`T7-DR-036#REQ-01`](../decisions/decision-register.md#35-g05-ki%E1%BB%83m-k%C3%AA-v%C3%A0-%C4%91i%E1%BB%81u-ch%E1%BB%89nh-t%E1%BB%93n), [`T7-DR-037`](../decisions/decision-register.md#35-g05-ki%E1%BB%83m-k%C3%AA-v%C3%A0-%C4%91i%E1%BB%81u-ch%E1%BB%89nh-t%E1%BB%93n), [`T7-DR-038`](../decisions/decision-register.md#35-g05-ki%E1%BB%83m-k%C3%AA-v%C3%A0-%C4%91i%E1%BB%81u-ch%E1%BB%89nh-t%E1%BB%93n), [`T7-DR-039`](../decisions/decision-register.md#35-g05-ki%E1%BB%83m-k%C3%AA-v%C3%A0-%C4%91i%E1%BB%81u-ch%E1%BB%89nh-t%E1%BB%93n), [`T7-DR-035#REQ-02`](../decisions/decision-register.md#35-g05-ki%E1%BB%83m-k%C3%AA-v%C3%A0-%C4%91i%E1%BB%81u-ch%E1%BB%89nh-t%E1%BB%93n) |
| Trạng thái | Áp dụng trong phạm vi hiện tại; không có bước đồng bộ thiết bị offline |
| Mức bằng chứng | `STATIC_VALIDATED` |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-021` — Sửa sai tồn kho mà không sửa lịch sử](KB-KGV-021-sua-sai-ton-kho-khong-sua-lich-su.md)
- [`KB-KGV-029` — Tính nguyên tử khi ghi tồn kho và phát sự kiện](KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md)
- [`KB-KGV-032` — Movement ledger, số dư dẫn xuất và phục hồi sau sự cố](KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md)
