---
id: KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am
type: know-how
theme: theme-07
title: tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am — tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am

## 1. Bối cảnh

### Câu trả lời ngắn

Số lượng chỉ trở thành chính thức khi Inventory Operation hoàn tất. Mọi giao dịch trong phạm vi hiện tại đều trực tuyến, luôn chặn xuất âm và phải kiểm tra cùng giữ hoặc xuất trong một giao dịch nguyên tử. Khi hai giao dịch tranh chấp phần hàng cuối, giao dịch hợp lệ commit trước thành công; giao dịch sau bị từ chối trên trạng thái mới nhất.

### Vì sao vấn đề này quan trọng?

Giữa lúc người dùng bấm xác nhận và lúc server commit có thể xảy ra retry, timeout hoặc một giao dịch khác chen vào. Nếu kiểm tra tồn và trừ tồn là hai bước độc lập, hai người đều có thể thấy cùng một đơn vị cuối và cùng bán nó. Một mốc hoàn tất rõ ràng cùng ranh giới nguyên tử giúp mọi người quan sát một kết quả thống nhất và phục hồi an toàn khi kết nối không chắc chắn.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Không được hiểu là |
|---|---|---|
| Hoàn tất | Operation đã commit toàn bộ movement, số dư và kết quả liên quan | Người dùng vừa bấm nút |
| Giao dịch nguyên tử | Hoặc tất cả thay đổi cùng thành công, hoặc không thay đổi nào tồn tại | Chuỗi bước có thể hoàn tất một phần |
| `UNKNOWN` | Chưa đủ bằng chứng xác định commit đã xảy ra hay chưa | Thất bại chắc chắn |
| Chặn xuất âm | Lượng xuất không được vượt lượng đủ điều kiện hiện hành | Cho phép rồi sửa sau |

### Quy tắc vận hành

1. Nháp, Chờ duyệt, Sẵn sàng và Đang xử lý không làm thay đổi số lượng chính thức.
2. Kiểm tra khả dụng và giữ/xuất phải nằm trong cùng ranh giới giao dịch hoặc dùng cơ chế đồng thời có hiệu lực tương đương.
3. Giao dịch hợp lệ commit đầu tiên thắng; yêu cầu sau phải đọc lại và bị từ chối nếu không còn đủ hàng.
4. Timeout sau khi gửi không được tạo yêu cầu mới. Nguồn truy vấn hoặc tiếp tục bằng cùng operation ID.
5. Nếu kết quả chưa đủ bằng chứng, operation ở `UNKNOWN`; không được giả định thất bại rồi trừ lại.
6. Bán hàng khi mất kết nối là định hướng tương lai, không phải ngoại lệ cho phép âm tồn trong phạm vi hiện tại.

### Ví dụ minh họa

Kho còn 1 đơn vị bán được. Checkout A và B gần như đồng thời yêu cầu xuất 1. Nếu cả hai chỉ đọc số dư trước rồi trừ sau, cả hai có thể thành công sai. Cách đúng là mỗi checkout kiểm tra và xuất nguyên tử. A commit trước, số dư về 0; B kiểm tra trạng thái đã commit và nhận lỗi thiếu hàng.

Nếu A bị timeout đúng sau khi server đã commit, client gửi lại cùng request ID. Hệ thống trả lại kết quả của operation cũ, không tạo movement thứ hai.

### Ngoại lệ và cách làm sai

- **Đánh dấu Hoàn tất trước khi commit:** trạng thái hiển thị có thể khác ledger.
- **Kiểm tra và trừ ở hai transaction:** tạo khoảng trống cho oversell.
- **Retry bằng request ID mới:** có thể xuất hai lần cho một yêu cầu.
- **Coi `UNKNOWN` là thất bại:** có thể tạo lần trừ thứ hai sau một commit đã thành công.
- **Dùng định hướng offline để nới quy tắc online:** chức năng chưa triển khai không tạo ngoại lệ hiện hành.

## 3. Ý nghĩa đối với Theme

### Điều cần ghi nhớ

- **Chỉ operation Hoàn tất mới thay đổi tồn chính thức.**
- **Kiểm tra và giữ/xuất phải nguyên tử.**
- **Commit hợp lệ đầu tiên thắng.**
- **Timeout được giải quyết bằng cùng identity, không bằng mutation mới.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-006` |
| Cụm tri thức | [`KGV-C01`](00-table-of-contents.md#c01-nền-tảng-quản-lý-tồn-kho) |
| Loại bài | `CONTROL` |
| Quyết định chính | [`T7-DR-028`](../decisions/decision-register.md#34-g04-kh%E1%BA%A3-d%E1%BB%A5ng-gi%E1%BB%AF-h%C3%A0ng-l%E1%BA%A5y-h%C3%A0ng-v%C3%A0-xu%E1%BA%A5t), [`T7-DR-070`](../decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh), [`T7-DR-033`](../decisions/decision-register.md#34-g04-kh%E1%BA%A3-d%E1%BB%A5ng-gi%E1%BB%AF-h%C3%A0ng-l%E1%BA%A5y-h%C3%A0ng-v%C3%A0-xu%E1%BA%A5t), [`T7-DR-071`](../decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh) |
| Trạng thái | Áp dụng cho mọi giao dịch trực tuyến trong phạm vi hiện tại |
| Mức bằng chứng | `STATIC_VALIDATED` |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-005` — Tồn vật lý, lượng đủ điều kiện bán, lượng giữ và tồn khả dụng](KB-KGV-005-ton-vat-ly-va-ton-kha-dung.md)
- [`KB-KGV-027` — Vòng đời của một Inventory Operation](KB-KGV-027-vong-doi-cua-mot-inventory-operation.md)
- [`KB-KGV-028` — Idempotency, phiên bản nguồn và kết quả chưa xác định](KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md)
- [`KB-KGV-039` — Bán hàng khi mất kết nối: định hướng và điều kiện mở phạm vi](KB-KGV-039-ban-hang-pos-offline.md)
