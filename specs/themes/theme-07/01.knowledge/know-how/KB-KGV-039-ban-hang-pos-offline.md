---
id: KB-KGV-039-ban-hang-pos-offline
type: know-how
theme: theme-07
title: ban-hang-pos-offline
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-039-ban-hang-pos-offline — ban-hang-pos-offline

## 1. Bối cảnh

### Câu trả lời ngắn

Bán khi mất kết nối là định hướng dài hạn nhưng chưa thuộc phạm vi khởi đầu. Hiện tại mọi người dùng — ở quầy hay đang di chuyển — đều phải có kết nối tới hệ thống trung tâm khi tạo và hoàn tất giao dịch. Nhiều người dùng bán trực tuyến không tạo thêm cửa hàng và không đồng nghĩa với offline.

Để mở offline an toàn, cần một gói năng lực đầy đủ gồm identity giao dịch trên thiết bị, snapshot có phiên bản, khóa khi kiểm kê, đồng bộ idempotent, giải quyết xung đột, dữ liệu lô đã quét và quy tắc sai lệch vật lý–ledger. Vì chưa có gói đó, UI, API và entity offline không xuất hiện trong phạm vi hiện tại.

### Vì sao vấn đề này quan trọng?

Khi mất kết nối, thiết bị quyết định dựa trên dữ liệu cũ trong khi server có thể tiếp tục bán hoặc giữ cùng hàng. Đây không chỉ là “lưu đơn rồi gửi sau”; nó thay đổi quy tắc chống xuất âm, kiểm kê, truy xuất lô, retry và trách nhiệm xử lý xung đột. Mở một phần sẽ tạo cảm giác hoạt động nhưng không bảo vệ được sổ tồn.

## 2. Nội dung nền tảng

### Điều kiện cần trước khi triển khai

| Năng lực | Câu hỏi phải trả lời |
|---|---|
| Identity thiết bị | Một lần bán offline được nhận diện và retry thế nào? |
| Snapshot | Dữ liệu nào được tải xuống, có phiên bản và hết hiệu lực khi nào? |
| Lô | Thiết bị ghi lô thực tế đã giao ra sao? |
| Xung đột | Xử lý thế nào nếu server đã dùng phần hàng đó? |
| Kiểm kê | Thiết bị nhận và xác nhận khóa phạm vi thế nào? |
| Đối soát | Ai xử lý sai lệch vật lý–ledger, bằng operation nào? |
| Quan sát | Làm sao biết thiết bị nào chưa đồng bộ? |

### Quy tắc trong phạm vi hiện tại

1. Checkout và hoàn tất đơn cần kết nối server.
2. Không lưu một transaction offline để đồng bộ sau.
3. Không có `OFFLINE_SALE_VARIANCE`, `OFFLINE_CONFLICT`, device sequence hoặc offline snapshot.
4. Không cho âm tồn với lý do “hàng đã bán lúc mất mạng”.
5. Idempotency, version nguồn, transaction nguyên tử và outbox vẫn được xây như nền tảng dùng chung, nhưng không được gọi là tính năng offline.
6. Khi mất kết nối, giao diện giữ dữ liệu nhập cục bộ nếu phù hợp trải nghiệm nhưng không được xác nhận đã bán hoặc đã xuất kho.

### Ví dụ minh họa

Nhân viên tại quầy và chủ cửa hàng trên đường đều có mạng, đăng nhập bằng tài khoản riêng và bán từ cùng cửa hàng/kho mặc định. Đây là bán hàng trực tuyến nhiều người dùng, không phải nhiều cửa hàng và không phải offline.

Nếu nhân viên mất mạng đúng lúc checkout, giao diện phải báo chưa xác nhận. Khi kết nối lại, ứng dụng truy vấn hoặc gửi lại cùng request ID; chỉ kết quả server mới xác định hàng đã xuất hay chưa. Ứng dụng không được tự coi đơn đã bán rồi đồng bộ như một giao dịch offline.

### Ngoại lệ và cách làm sai

- **Gọi người bán từ xa là kênh offline:** vị trí địa lý không quyết định trạng thái kết nối.
- **Lưu đơn cục bộ và coi là đã hoàn tất:** tạo cam kết vật lý không có ledger trung tâm.
- **Chỉ thêm hàng đợi sync:** bỏ qua snapshot, xung đột, kiểm kê và truy xuất lô.
- **Hiện nút offline bị vô hiệu hóa:** tạo cam kết sản phẩm chưa sẵn sàng.

## 3. Ý nghĩa đối với Theme

### Điều cần ghi nhớ

- **Nhiều người dùng trực tuyến vẫn là một cửa hàng.**
- **Offline là một gói năng lực nhất quán, không phải một cờ.**
- **Phạm vi khởi đầu không có UI, API hay entity offline.**
- **Nền tảng idempotency và nguyên tử được giữ để mở rộng về sau.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-039` |
| Cụm tri thức | [`KGV-C10`](00-table-of-contents.md#c10-vận-hành-phục-hồi-và-thay-đổi) |
| Loại bài | `FUTURE_CONCEPT` |
| Quyết định chính | [`T7-DR-034`](../decisions/decision-register.md#34-g04-kh%E1%BA%A3-d%E1%BB%A5ng-gi%E1%BB%AF-h%C3%A0ng-l%E1%BA%A5y-h%C3%A0ng-v%C3%A0-xu%E1%BA%A5t), [`T7-DR-034`](../decisions/decision-register.md#34-g04-kh%E1%BA%A3-d%E1%BB%A5ng-gi%E1%BB%AF-h%C3%A0ng-l%E1%BA%A5y-h%C3%A0ng-v%C3%A0-xu%E1%BA%A5t), [`T7-DR-034`](../decisions/decision-register.md#34-g04-kh%E1%BA%A3-d%E1%BB%A5ng-gi%E1%BB%AF-h%C3%A0ng-l%E1%BA%A5y-h%C3%A0ng-v%C3%A0-xu%E1%BA%A5t), [`T7-DR-034`](../decisions/decision-register.md#34-g04-kh%E1%BA%A3-d%E1%BB%A5ng-gi%E1%BB%AF-h%C3%A0ng-l%E1%BA%A5y-h%C3%A0ng-v%C3%A0-xu%E1%BA%A5t), [`T7-DR-034`](../decisions/decision-register.md#34-g04-kh%E1%BA%A3-d%E1%BB%A5ng-gi%E1%BB%AF-h%C3%A0ng-l%E1%BA%A5y-h%C3%A0ng-v%C3%A0-xu%E1%BA%A5t) |
| Trạng thái | `DEFERRED` — không triển khai trong phạm vi hiện tại |
| Mức bằng chứng | `STATIC_VALIDATED` |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-003` — Cửa hàng, kho và khóa định danh số dư tồn kho](KB-KGV-003-kho-cua-hang-va-khoa-dinh-danh-so-du-ton-kho.md)
- [`KB-KGV-006` — Tính chính thức của tồn kho và nguyên tắc chống xuất âm](KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am.md)
- [`KB-KGV-028` — Idempotency, phiên bản nguồn và xử lý kết quả chưa xác định](KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md)
- [`KB-KGV-042` — Xây kiến trúc mở rộng mà không triển khai trước chức năng tương lai](KB-KGV-042-kien-truc-mo-rong-va-ranh-gioi-mvp.md)
