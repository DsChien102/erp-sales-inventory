# US 05: Quản lý đơn vị đo lường và quy đổi của sản phẩm

**Là** chủ cửa hàng,  
**Tôi muốn** quản lý đơn vị đo lường cơ sở, đơn vị đo lường quy đổi và tỷ lệ quy đổi của sản phẩm,  
**Để** sản phẩm có thể được bán, nhập và theo dõi tồn kho theo đúng đơn vị sử dụng mà không làm sai lệch dữ liệu lịch sử đã phát sinh.

## Functional requirements

| FR | Tên | Spec |
| -- | --- | ---- |
| FR-01 | Thêm đơn vị đo lường quy đổi cho sản phẩm | [FR-01.md](FR-01.md) |
| FR-02 | Ngừng sử dụng đơn vị đo lường | [FR-02.md](FR-02.md) |
| FR-03 | Sử dụng lại đơn vị đo lường đã ngừng | [FR-03.md](FR-03.md) |
| FR-04 | Xóa đơn vị đo lường đủ điều kiện | [FR-04.md](FR-04.md) |
| FR-05 | Đổi đơn vị đo lường cơ sở của sản phẩm | [FR-05.md](FR-05.md) |

Epic: [EPIC-01-product/README.md](../README.md) · Theme: [TH-02 README.md](../../README.md)

### Non-Functional requirement

| ID | Applies to | Requirement |
|---|---|---|
| NFR-01 | All | Thao tác lưu thay đổi cấu hình đơn vị đo lường phải đảm bảo tính nguyên tử; nếu lưu thất bại, hệ thống không được tạo cấu hình ở trạng thái hoàn chỉnh một phần. |
| NFR-02 | All | Việc tính tỷ lệ quy đổi và tồn kho sau quy đổi phải dùng cùng chuẩn độ chính xác/làm tròn của hệ thống. |
