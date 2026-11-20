---
id: KB-KGV-021-sua-sai-ton-kho-khong-sua-lich-su
type: know-how
theme: theme-07
title: sua-sai-ton-kho-khong-sua-lich-su
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-021-sua-sai-ton-kho-khong-sua-lich-su — sua-sai-ton-kho-khong-sua-lich-su

## 1. Bối cảnh

### Câu trả lời ngắn

Một Inventory Operation đã hoàn tất là **bằng chứng lịch sử bất biến** và không được mở lại để sửa nội dung. Khi phát hiện sai, hệ thống tạo một **reversal** liên kết với operation gốc để trung hòa ảnh hưởng; nếu cần phản ánh nghiệp vụ đúng, hệ thống tiếp tục tạo operation thay thế. Các operation này giữ ID, ngày và kết quả riêng nhưng cùng nằm trong một **correction chain**.

Reversal không phải quyền “xóa giao dịch”. Nó bị chặn nếu làm tồn âm, nếu còn operation phụ thuộc chưa được trung hòa hoặc nếu operation gốc còn ở trạng thái `UNKNOWN`. Sai sót của kỳ đã khóa được ghi vào kỳ mở hiện tại, giữ cả ngày nghiệp vụ gốc và ngày ghi nhận thực tế; lịch sử và phiên chốt cũ không bị viết lại.

### Vì sao vấn đề này quan trọng?

Nếu cho phép sửa trực tiếp operation đã hoàn tất, người xem lịch sử không thể biết dữ liệu ban đầu là gì, ai sửa, sửa khi nào và số liệu đã từng được dùng trong kỳ chốt nào. Audit trail sẽ biến thành “ảnh chụp hiện tại” thay vì chuỗi bằng chứng.

Ở chiều ngược lại, đảo một operation mà không kiểm tra phụ thuộc có thể tạo tồn âm hoặc phá vỡ giá trị đã đối soát. Quy trình sửa sai vì vậy phải bảo toàn đồng thời ba yêu cầu: **không mất lịch sử, không phá bất biến hiện hành và không viết lại kỳ đã khóa**.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Không được hiểu là |
|---|---|---|
| Operation gốc | Operation đã hoàn tất nhưng sau đó được xác định là sai | Bản nháp có thể mở lại để sửa |
| Reversal | Operation mới, liên kết bản gốc và trung hòa ảnh hưởng được phép trung hòa | Xóa operation gốc khỏi lịch sử |
| Operation thay thế | Operation mới phản ánh dữ liệu đúng sau khi sai sót được trung hòa | Phiên bản chỉnh sửa đè lên ID cũ |
| Correction chain | Quan hệ truy vết giữa operation gốc, reversal và các operation sửa tiếp theo | Một operation lớn hợp nhất toàn bộ lịch sử |
| Operation phụ thuộc | Operation sau đã dựa vào kết quả của operation trước | Chỉ là một liên kết tham khảo có thể bỏ qua |
| Ngày nghiệp vụ gốc | Ngày mà nghiệp vụ thực tế thuộc về | Ngày hệ thống ghi nhận correction |
| Ngày ghi nhận/hoàn tất | Ngày correction thực sự được commit trong kỳ mở | Cách thay thế ngày nghiệp vụ gốc |
| Valuation adjustment | Movement giá trị mới dùng để phản ánh tác động sửa sai lên phần đã đối soát | Việc sửa lại phiên chốt hoặc chứng từ cũ |

### Mô hình correction chain

| Thứ tự | Operation | Vai trò | ID và ngày | Ảnh hưởng lịch sử |
|---:|---|---|---|---|
| 1 | Operation gốc | Ghi nhận nghiệp vụ ban đầu | Giữ nguyên ID và ngày đã có | Không sửa, không xóa |
| 2 | Reversal | Trung hòa ảnh hưởng của operation gốc trong phạm vi được phép | Có ID và ngày hoàn tất riêng; liên kết bản gốc | Bổ sung movement ngược, không thay movement cũ |
| 3 | Operation thay thế | Ghi nhận nghiệp vụ đúng nếu vẫn cần | Có ID và ngày riêng; cùng correction chain | Bổ sung sự thật mới có thể truy vết |

Mỗi operation là một bản ghi độc lập. Correction chain cung cấp bối cảnh để người đọc hiểu toàn bộ câu chuyện, nhưng không làm mất danh tính riêng của từng bước.

### Quy tắc vận hành

#### 1. Không sửa operation đã hoàn tất

Payload, kết quả, movement và audit của operation hoàn tất phải được giữ nguyên. Việc sửa sai luôn bắt đầu bằng yêu cầu reversal mới có liên kết rõ đến operation gốc.

#### 2. Kiểm tra điều kiện trước khi cho phép reversal

| Điều kiện hiện hành | Kết quả |
|---|---|
| Reversal làm một số dư liên quan xuống âm | Chặn reversal |
| Còn operation phụ thuộc chưa được trung hòa | Chặn reversal |
| Operation gốc đang `UNKNOWN` | Chặn reversal và operation thay thế |
| Operation gốc đã có một reversal có hiệu lực | Không tạo reversal có hiệu lực thứ hai |
| Reversal vượt ngưỡng rủi ro | Chờ người đủ thẩm quyền phê duyệt |
| Người tạo đồng thời muốn tự duyệt | Từ chối theo maker–checker (trừ chủ cửa hàng `is_owner`: vẫn gửi duyệt rồi tự duyệt) |

“Trung hòa phụ thuộc” phải diễn ra qua các operation hợp lệ và có liên kết; không được sửa số dư tay để làm cho reversal đi qua.

#### 3. Giải quyết `UNKNOWN` trước khi sửa sai

`UNKNOWN` có nghĩa là chưa đủ bằng chứng để kết luận operation đã commit hay chưa. Trong trạng thái này, tạo reversal có thể đảo một giao dịch chưa từng xảy ra, còn tạo operation thay thế có thể ghi trùng giao dịch đã xảy ra.

Vì vậy, hệ thống phải đối soát hoặc tiếp tục xử lý bằng **cùng operation ID** cho đến khi operation trở thành Hoàn tất hoặc Từ chối thực thi. Chỉ sau khi kết quả gốc đã rõ mới được áp dụng quy trình sửa sai phù hợp.

#### 4. Chỉ có một reversal có hiệu lực cho operation gốc

Một operation gốc không được có hai reversal cùng có hiệu lực. Nếu reversal đầu tiên lại sai, hướng sửa tiếp là đảo reversal đó hoặc tạo bước correction mới có liên kết trong cùng chuỗi; không phát hành thêm một reversal cạnh tranh trực tiếp với bản gốc.

#### 5. Sửa sai trong kỳ đã khóa

Sai sót thuộc kỳ đã khóa không được ghi đè vào kỳ cũ. Correction được ghi trong kỳ mở hiện tại và lưu đồng thời:

- **ngày nghiệp vụ gốc**, để phân tích vận hành đúng thời điểm;
- **ngày ghi nhận/hoàn tất thực tế**, để báo cáo kế toán và audit đúng kỳ mở.

Nếu operation gốc đã tham gia một lần đối soát giá, reversal phải phản ánh cả ảnh hưởng số lượng/giá trị cần thiết và tạo valuation adjustment liên kết. Phiên chốt cũ vẫn bất biến.

#### 6. Phê duyệt theo rủi ro

Reversal được đánh giá theo ngưỡng rủi ro số lượng hoặc giá trị. Người tạo không được tự duyệt (trừ chủ cửa hàng `is_owner`: vẫn gửi duyệt rồi tự duyệt). Phê duyệt chỉ cho phép operation đi tiếp; khi thực thi, hệ thống vẫn phải kiểm tra lại tồn, trạng thái, phụ thuộc và khóa hiện hành.

### Ví dụ xuyên suốt

#### Trường hợp A — sai nhưng chưa có phụ thuộc

Một operation nhận hàng đã hoàn tất với 100 đơn vị, trong khi lượng đúng phải là 90. Chưa có operation nào sử dụng lượng hàng này.

1. Operation gốc `OP-100` được giữ nguyên với lượng 100.
2. Reversal `OP-101` liên kết `OP-100` và trung hòa 100 đơn vị.
3. Operation thay thế `OP-102` ghi nhận đúng 90 đơn vị.
4. Cả ba cùng mang một correction chain ID, nhưng mỗi operation giữ ID, người thực hiện và thời điểm riêng.

Kết quả ròng là 90 đơn vị; lịch sử vẫn cho thấy rõ vì sao hệ thống đi từ 100 về 90.

#### Trường hợp B — reversal sẽ làm tồn âm

Vẫn là operation nhận 100 đơn vị, nhưng 30 đơn vị đã được xuất bằng một operation phụ thuộc. Nếu đảo toàn bộ 100 ngay, số dư sẽ âm 30.

Hệ thống phải chặn reversal. Người xử lý cần trung hòa hoặc giải quyết các operation phụ thuộc bằng đường nghiệp vụ hợp lệ trước; không được ép số dư về 0 rồi tiếp tục đảo.

#### Trường hợp C — sai sót được phát hiện sau khi khóa kỳ

Operation sai thuộc tháng 7 và đã tham gia đối soát giá. Sai sót được phát hiện trong tháng 8 khi tháng 7 đã khóa.

- Reversal và operation thay thế được ghi nhận trong kỳ mở tháng 8.
- Cả hai giữ ngày nghiệp vụ gốc thuộc tháng 7 và ngày hoàn tất thực tế thuộc tháng 8.
- Phần ảnh hưởng giá trị đã chốt được phản ánh bằng valuation adjustment mới có liên kết.
- Báo cáo kỳ tháng 7 không bị viết lại; báo cáo theo ngày nghiệp vụ vẫn có thể phân tích sai sót về đúng tháng 7.

### Ngoại lệ và những cách làm sai

- **Mở lại operation hoàn tất để sửa payload:** phá tính bất biến và làm mất bằng chứng gốc.
- **Xóa operation sai khỏi ledger:** khiến số dư mới không thể giải thích từ lịch sử movement.
- **Đảo operation đang `UNKNOWN`:** có thể tạo double effect hoặc đảo một giao dịch chưa từng commit.
- **Tạo hai reversal cùng có hiệu lực:** làm trung hòa quá mức và tạo hai nhánh lịch sử cạnh tranh.
- **Đảo mà không kiểm tra phụ thuộc:** có thể làm âm tồn hoặc phá liên kết với xuất bán, trả hàng hay định giá.
- **Ghi correction lùi vào kỳ đã khóa:** làm thay đổi số liệu đã công bố và phá audit trail.
- **Chỉ đảo số lượng khi operation đã được đối soát giá:** khiến quantity ledger và value ledger mất nhất quán.
- **Cho người tạo tự duyệt reversal rủi ro:** phá maker–checker.

## 3. Ý nghĩa đối với Theme

### Điều cần ghi nhớ

- **Không sửa hoặc xóa operation đã hoàn tất; sửa bằng operation mới có liên kết.**
- **Reversal trung hòa ảnh hưởng nhưng không xóa lịch sử.**
- **Tồn âm, phụ thuộc chưa xử lý và trạng thái `UNKNOWN` đều là điều kiện chặn.**
- **Mỗi operation gốc chỉ có một reversal có hiệu lực.**
- **Correction trong kỳ khóa được ghi ở kỳ mở và giữ hai ngày.**
- **Ảnh hưởng đã đi qua đối soát giá phải có valuation adjustment liên kết.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-021` |
| Cụm tri thức | [`KGV-C05`](00-table-of-contents.md#c05-sửa-sai-và-số-dư-đầu-kỳ) |
| Loại bài | `CONTROL` |
| Quyết định chính | [`T7-DR-064`](../decisions/decision-register.md#38-g08-s%E1%BB%ADa-sai-v%C3%A0-ho%C3%A0n-nguy%C3%AAn), [`T7-DR-065`](../decisions/decision-register.md#38-g08-s%E1%BB%ADa-sai-v%C3%A0-ho%C3%A0n-nguy%C3%AAn), [`T7-DR-066`](../decisions/decision-register.md#38-g08-s%E1%BB%ADa-sai-v%C3%A0-ho%C3%A0n-nguy%C3%AAn), [`T7-DR-066#REQ-01`](../decisions/decision-register.md#38-g08-s%E1%BB%ADa-sai-v%C3%A0-ho%C3%A0n-nguy%C3%AAn), [`T7-DR-066#REQ-02`](../decisions/decision-register.md#38-g08-s%E1%BB%ADa-sai-v%C3%A0-ho%C3%A0n-nguy%C3%AAn), [`T7-DR-078`](../decisions/decision-register.md#311-g11-quy%E1%BB%81n-ph%C3%AA-duy%E1%BB%87t-v%C3%A0-b%E1%BA%A3o-v%E1%BB%87-d%E1%BB%AF-li%E1%BB%87u), [`T7-DR-065#REQ-01`](../decisions/decision-register.md#38-g08-s%E1%BB%ADa-sai-v%C3%A0-ho%C3%A0n-nguy%C3%AAn), [`T7-DR-065#REQ-02`](../decisions/decision-register.md#38-g08-s%E1%BB%ADa-sai-v%C3%A0-ho%C3%A0n-nguy%C3%AAn), [`T7-DR-064#REQ-01`](../decisions/decision-register.md#38-g08-s%E1%BB%ADa-sai-v%C3%A0-ho%C3%A0n-nguy%C3%AAn) |
| Trạng thái quyết định | `ACTIVE` |
| Mức bằng chứng của bài | `STATIC_VALIDATED` |
| Giới hạn | Bài giải thích nguyên tắc correction; không quyết định cách trung hòa từng loại operation phụ thuộc hoặc cấu hình cụ thể của ngưỡng phê duyệt |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-018` — Đối soát giá vốn cuối kỳ và cập nhật đột xuất giữa kỳ](KB-KGV-018-doi-soat-gia-von-cuoi-ky-va-cap-nhat-dot-xuat-giua-ky.md)
- [`KB-KGV-027` — Vòng đời của một Inventory Operation](KB-KGV-027-vong-doi-cua-mot-inventory-operation.md)
- [`KB-KGV-028` — Idempotency, phiên bản nguồn và xử lý kết quả chưa xác định](KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md)
- [`KB-KGV-031` — Phê duyệt Inventory Operation theo mức rủi ro](KB-KGV-031-phe-duyet-inventory-operation-theo-muc-rui-ro.md)
