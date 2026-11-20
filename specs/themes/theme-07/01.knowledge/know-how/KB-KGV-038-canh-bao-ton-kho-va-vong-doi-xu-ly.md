---
id: KB-KGV-038-canh-bao-ton-kho-va-vong-doi-xu-ly
type: know-how
theme: theme-07
title: canh-bao-ton-kho-va-vong-doi-xu-ly
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-038-canh-bao-ton-kho-va-vong-doi-xu-ly — canh-bao-ton-kho-va-vong-doi-xu-ly

## 1. Bối cảnh

### Câu trả lời ngắn

Phạm vi khởi đầu không có một nền tảng cảnh báo chung với người phụ trách, SLA và trạng thái Mở → Đã xử lý. Các điều kiện như tồn thấp, cận hạn hoặc hết hạn là **chỉ báo dẫn xuất**: điều kiện nguồn thay đổi thì chỉ báo tự thay đổi. Các vấn đề cần bằng chứng và quyết định, như `UNKNOWN`, lệch ledger–projection hoặc sai lệch đối soát nguồn, dùng lifecycle của Inventory Operation hoặc Reconciliation Case.

Không có nút “đóng cảnh báo” để che điều kiện nguồn; email, push và định tuyến thông báo ngoài ứng dụng được để lại cho giai đoạn sau.

### Vì sao vấn đề này quan trọng?

Nếu biến mọi điều kiện thành một bản ghi cảnh báo, hệ thống phải xử lý identity, chống trùng, người nhận, SLA và đóng/mở lại trước khi tạo giá trị. Ngược lại, nếu một sai lệch cần điều tra chỉ được hiển thị như badge, sẽ không có người chịu trách nhiệm hoặc bằng chứng xử lý. Phân loại theo bản chất giúp MVP gọn mà vẫn kiểm soát rủi ro thật.

## 2. Nội dung nền tảng

### Ma trận xử lý

| Điều kiện | Biểu diễn | Cách biến mất/đóng |
|---|---|---|
| Tồn thấp/hết hàng | Chỉ báo dẫn xuất | Tồn hoặc cấu hình thay đổi |
| Cận hạn/hết hạn | Chỉ báo dẫn xuất từ lô và ngày nghiệp vụ | Thời gian/dữ liệu hoặc tồn thay đổi |
| Hàng chờ giá | Hàng công việc theo trạng thái tồn | Xác nhận giá hoàn tất |
| Operation `UNKNOWN` | Lifecycle của operation | Đối soát/tiếp tục cùng operation ID |
| Chênh lệch kiểm kê | Lifecycle phiên kiểm kê | Đếm lại, duyệt, adjustment hoặc hủy |
| Lệch ledger–projection | Reconciliation Case | Có bằng chứng rebuild/đối soát |
| Sai lệch chứng từ nguồn | Reconciliation Case | Xử lý bằng operation hợp lệ |

### Quy tắc vận hành

1. Chỉ báo dẫn xuất không có identity, owner, SLA hoặc thao tác đóng riêng.
2. Người dùng chỉ nhìn thấy chỉ báo và dữ liệu theo quyền; giá trị tài chính vẫn bị che nếu thiếu quyền.
3. Hồ sơ rủi ro dùng lifecycle của đối tượng nghiệp vụ gốc, không tạo một lifecycle cảnh báo song song.
4. Đóng Reconciliation Case cần bằng chứng; không được sửa balance hoặc operation trực tiếp.
5. Điều kiện còn tồn tại phải tiếp tục xuất hiện sau refresh; thao tác UI không thể chỉ ẩn nó.
6. Giao event tích hợp thất bại được retry bằng cùng event ID và không đảo operation đã commit.

### Ví dụ minh họa

Sản phẩm P có khả dụng 8 dưới ngưỡng 10 nên hiện badge “Sắp hết”. Khi goods receipt hoàn tất và khả dụng lên 35, badge tự biến mất; không có hồ sơ để đóng. Ngược lại, nếu projection hiển thị 35 nhưng movement ledger dựng ra 34, hệ thống khóa phạm vi bị ảnh hưởng và mở Reconciliation Case. Case chỉ đóng sau khi có bằng chứng rebuild projection và kết quả đối chiếu bằng nhau.

### Ngoại lệ và cách làm sai

- **Tạo ticket cho mỗi lần tồn thấp:** sinh nhiễu và trùng khi số dư dao động.
- **Cho người dùng bấm “Đã xử lý” để ẩn badge:** che điều kiện vẫn còn thật.
- **Dùng một alert lifecycle thay operation lifecycle:** tạo hai nguồn trạng thái cạnh tranh.
- **Gửi dữ liệu giá qua thông báo cho người chỉ có quyền xem lượng:** vi phạm phân tách tài chính.

## 3. Ý nghĩa đối với Theme

### Điều cần ghi nhớ

- **Điều kiện tự tính dùng chỉ báo; vấn đề cần bằng chứng dùng hồ sơ nghiệp vụ.**
- **Không có vòng đời cảnh báo chung trong phạm vi khởi đầu.**
- **Không thao tác đóng thủ công chỉ báo dẫn xuất.**
- **Sửa nguyên nhân bằng đúng operation hoặc đối soát.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-038` |
| Cụm tri thức | [`KGV-C10`](00-table-of-contents.md#c10-vận-hành-phục-hồi-và-thay-đổi) |
| Loại bài | `OPERATIONS` |
| Quyết định chính | [`T7-DR-088`](../decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i), [`T7-DR-088`](../decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i), [`T7-DR-088`](../decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i), [`T7-DR-089#REQ-01`](../decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i), [`T7-DR-089`](../decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i), [`T7-DR-018#REQ-01`](../decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i) |
| Trạng thái | Chỉ báo và worklist áp dụng; alert lifecycle/kênh ngoài được hoãn |
| Mức bằng chứng | `STATIC_VALIDATED` |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-028` — Idempotency, phiên bản nguồn và xử lý kết quả chưa xác định](KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md)
- [`KB-KGV-033` — Thẻ kho, báo cáo lịch sử và đối soát nguồn](KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon.md)
- [`KB-KGV-036` — Nhận biết tồn thấp và gợi ý lượng bổ sung](KB-KGV-036-ton-du-kien-va-de-xuat-bo-sung-hang.md)
