# Tổng hợp thay đổi nội dung 5 file FR — TH-02

## Mục đích và phạm vi

Tài liệu này ghi nhận bộ thay đổi đã từng được đưa vào working tree ngày 15/07/2026 và sau đó đã được hoàn tác khỏi 5 file FR gốc. Cột **Trước thay đổi** là nội dung FR đang được giữ lại; cột **Sau thay đổi** là nội dung từng được đề xuất/thay đổi để phục vụ đối chiếu. Tài liệu **không xác nhận các thay đổi là đúng**, không thay thế FR gốc và không sửa nội dung của 5 file FR được đối chiếu.

Phạm vi gồm đúng 5 file:

1. [EPIC-02 / Guided Creation / US-01 / FR-02](EPIC-02-guided-creation/US-01/FR-02.md)
2. [EPIC-06 / Pricing / US-02 / FR-01](EPIC-06-pricing/US-02/FR-01.md)
3. [EPIC-06 / Pricing / US-02 / FR-02](EPIC-06-pricing/US-02/FR-02.md)
4. [EPIC-06 / Pricing / US-02 / FR-03](EPIC-06-pricing/US-02/FR-03.md)
5. [EPIC-06 / Pricing / US-02 / FR-04](EPIC-06-pricing/US-02/FR-04.md)

## Tổng quan thay đổi ý

| File | Vị trí thay đổi | Ý được thay đổi hoặc bổ sung |
| --- | --- | --- |
| EPIC-02 / US-01 / FR-02 | BR-03 đến BR-05, EC-03, Scenarios | Thu hẹp phạm vi kiểm tra trùng SKU/barcode còn sản phẩm chưa xóa mềm; cho phép dùng lại mã của sản phẩm đã xóa mềm và chặn restore nếu mã đã có chủ mới. |
| EPIC-06 / US-02 / FR-01 | BR-06 | Chuyển từ nguyên tắc không tự ghi đè khi chưa có hành động/chính sách sang chính sách tự tái tính toàn bộ band `ruleBased` khi Store Price Rule đang hoạt động đổi tỷ lệ. |
| EPIC-06 / US-02 / FR-02 | BR-02, BR-05 | Xác nhận giá gợi ý sẽ trở thành band theo rule và tiếp tục tự tái tính; thay khả năng chỉnh trực tiếp giá gợi ý bằng ba cách tính loại trừ lẫn nhau. |
| EPIC-06 / US-02 / FR-03 | BR-07, BR-08 | Bổ sung cách lưu nguồn của band `ruleBased` và yêu cầu tái tính nguyên tử khi Store Price Rule đổi tỷ lệ. |
| EPIC-06 / US-02 / FR-04 | BR-01, BR-03, BR-05, BR-06 | Thay khái niệm override chung bằng ba cách tính rõ ràng; quy định dữ liệu phải xóa khi chuyển mode và giới hạn đối tượng được Store Price Rule tự cập nhật. |

## 1. EPIC-02 / Guided Creation / US-01 / FR-02

File: [FR-02.md](EPIC-02-guided-creation/US-01/FR-02.md)

### 1.1 Business Rules — BR-03 đến BR-05

| ID | Trước thay đổi | Sau thay đổi | Chú thích thay đổi ý |
| --- | --- | --- | --- |
| BR-03 | Nếu SKU được nhập, SKU không được trùng với sản phẩm khác trong cùng tenant. | Nếu SKU được nhập, SKU không được trùng với sản phẩm **chưa xóa mềm** trong cùng tenant. | Loại sản phẩm đã xóa mềm khỏi phạm vi chiếm giữ SKU. |
| BR-04 | Nếu barcode được nhập, barcode không được trùng với sản phẩm khác trong cùng tenant. | Nếu barcode được nhập, barcode không được trùng với sản phẩm **chưa xóa mềm** trong cùng tenant. | Loại sản phẩm đã xóa mềm khỏi phạm vi chiếm giữ barcode. |
| BR-05 | Sản phẩm đã xóa mềm vẫn cần được cân nhắc khi kiểm tra trùng SKU/barcode. | SKU/barcode của sản phẩm đã xóa mềm được phép dùng lại; restore bị chặn nếu mã đã có chủ mới. | Đổi từ yêu cầu “cân nhắc khi kiểm tra trùng” sang chính sách tái sử dụng mã và xử lý xung đột lúc khôi phục. |

### 1.2 Edge Cases — EC-03

- **Trước:** Trường hợp SKU/barcode trùng với sản phẩm đã xóa mềm chỉ được nêu lại, chưa có expected behavior cụ thể.
- **Sau:** Expected behavior là cho phép dùng lại SKU/barcode cho sản phẩm mới.
- **Chú thích:** Làm rõ quyết định tại BR-05 trên luồng tạo mới.

### 1.3 Scenarios — bổ sung scenario dùng lại mã

- **Trước:** Chưa có scenario mô tả việc dùng lại SKU/barcode của sản phẩm đã xóa mềm.
- **Sau:** Bổ sung scenario tạo sản phẩm mới bằng `SKU-004` và `893000004`, cho phép lưu; khi khôi phục sản phẩm cũ thì chặn vì mã đã có chủ mới.
- **Chú thích:** Bổ sung tiêu chí nghiệm thu cho cả hai đầu của vòng đời: tạo mới và restore.

## 2. EPIC-06 / Pricing / US-02 / FR-01

File: [FR-01.md](EPIC-06-pricing/US-02/FR-01.md)

### Business Rules — BR-06

- **Trước:** Store Price Rule không được tự động ghi đè giá sản phẩm nếu chưa có hành động áp dụng hoặc một chính sách rõ ràng.
- **Sau:** Việc Product Unit Price Band chọn “Theo khung giá cửa hàng” được coi là chính sách rõ ràng; khi tỷ lệ của rule đang hoạt động thay đổi, toàn bộ band đang theo rule được tự tái tính. Custom Config và Manual không bị ghi đè.
- **Chú thích:** Chuyển từ nguyên tắc bảo vệ khỏi tự động ghi đè sang cơ chế subscription theo `ruleBased`; đồng thời xác định rõ hai mode không bị tác động.

## 3. EPIC-06 / Pricing / US-02 / FR-02

File: [FR-02.md](EPIC-06-pricing/US-02/FR-02.md)

### 3.1 Business Rules — BR-02

- **Trước:** Giá gợi ý chưa tự động trở thành giá chính thức nếu người dùng chưa xác nhận.
- **Sau:** Trước xác nhận, giá vẫn chỉ là gợi ý; sau khi xác nhận `ruleBased`, band tiếp tục theo Store Price Rule và tự tái tính khi nguồn thay đổi.
- **Chú thích:** Bổ sung vòng đời sau xác nhận. Việc xác nhận không chỉ lưu snapshot giá mà còn thiết lập quan hệ tiếp tục theo rule.

### 3.2 Business Rules — BR-05

- **Trước:** Người dùng có quyền có thể chỉnh lại giá gợi ý trước khi lưu.
- **Sau:** Muốn dùng tỷ lệ riêng phải chọn Custom Config; muốn nhập giá tuyệt đối phải chọn Manual; ba cách tính loại trừ lẫn nhau.
- **Chú thích:** Thay thao tác chỉnh giá gợi ý chung bằng lựa chọn mode có nguồn dữ liệu rõ ràng.

## 4. EPIC-06 / Pricing / US-02 / FR-03

File: [FR-03.md](EPIC-06-pricing/US-02/FR-03.md)

### Business Rules — bổ sung BR-07 và BR-08

| ID | Trước thay đổi | Sau thay đổi | Chú thích thay đổi ý |
| --- | --- | --- | --- |
| BR-07 | Không có. | Band áp dụng Store Price Rule lưu `source_type = ruleBased`, tham chiếu `store_price_rule_id` và không lưu tỷ lệ riêng. | Bổ sung hợp đồng persistence để phân biệt tỷ lệ cấp cửa hàng với tỷ lệ riêng của sản phẩm. |
| BR-08 | Không có. | Khi rule đang hoạt động đổi tỷ lệ, hệ thống tái tính nguyên tử mọi active band đang tham chiếu rule. | Bổ sung hành vi đồng bộ giá materialized và yêu cầu tính nguyên tử. |

## 5. EPIC-06 / Pricing / US-02 / FR-04

File: [FR-04.md](EPIC-06-pricing/US-02/FR-04.md)

### Business Rules — BR-01, BR-03, BR-05 và BR-06

| ID | Trước thay đổi | Sau thay đổi | Chú thích thay đổi ý |
| --- | --- | --- | --- |
| BR-01 | Store Price Rule chỉ là quy tắc mặc định hoặc gợi ý. | Mỗi Product Unit Price Band chỉ dùng đúng một cách tính: `ruleBased`, `customConfig` hoặc `manual`. | Chuyển trọng tâm từ vai trò gợi ý của rule sang invariant “đúng một mode”. |
| BR-03 | Người dùng có quyền quản lý giá có thể override giá gợi ý. | Người dùng có thể chọn Custom Config để lưu tỷ lệ riêng theo đơn vị hoặc Manual để lưu giá tuyệt đối. | Tách override thành hai loại có nguồn dữ liệu và hành vi tái tính khác nhau. |
| BR-05 | Override giá cần ghi lịch sử thay đổi. | Chuyển cách tính cần ghi lịch sử và xóa các trường nguồn không thuộc cách tính mới. | Mở rộng yêu cầu audit thành yêu cầu chuyển mode nguyên vẹn, không để dữ liệu nguồn trộn lẫn. |
| BR-06 | Áp dụng lại rule sau này không được ghi đè override nếu chưa xác nhận. | Thay đổi Store Price Rule chỉ tự cập nhật band `ruleBased`; không cập nhật `customConfig` hoặc `manual`. | Thay cơ chế xác nhận ghi đè bằng ranh giới cập nhật dựa trên mode hiện hành. |

## Ghi chú cuối

- Tổng số file FR được đối chiếu: **5**.
- Bộ thay đổi được tổng hợp trước khi hoàn tác gồm **19 dòng thêm, 12 dòng xóa**.
- Tài liệu này chỉ mô tả thay đổi nội dung; mọi quyết định giữ lại, hoàn tác hoặc sửa FR cần được review riêng.
- Cả 5 file FR hiện đã được khôi phục về nội dung tại `HEAD` và không còn diff trong working tree.
