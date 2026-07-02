# TH-02 — Business scope

### Purpose

Theme Sản phẩm và Giá bán giúp người dùng quản lý toàn bộ dữ liệu nền liên quan đến hàng hóa và sản phẩm trong hệ thống, bao gồm hồ sơ sản phẩm, thông tin nhận diện, đơn vị đo lường, quy đổi đơn vị, tồn kho cơ bản, giá bán, trạng thái kinh doanh và các thông tin mô tả chuyên ngành nếu có.

Theme này là nền tảng để các nghiệp vụ vận hành như bán hàng, nhập hàng, kho, giá vốn, hóa đơn, ghi sổ và báo cáo có thể sử dụng cùng một nguồn dữ liệu sản phẩm thống nhất.

Mục tiêu không chỉ là lưu danh sách sản phẩm, mà là chuẩn hóa cách hệ thống hiểu một sản phẩm là gì, sản phẩm được ghi nhận theo đơn vị nào, được bán theo đơn vị nào, được định giá ra sao, có còn được kinh doanh hay không, và dữ liệu nào cần được giữ ổn định để phục vụ giao dịch, truy vết và quản trị sau này.

### Business context

Theme Sản phẩm & Giá bán là một mắt xích nền trong toàn bộ chuỗi vận hành của VET45. Theme này không đứng độc lập, mà đóng vai trò xác định dữ liệu đầu vào và đầu ra cho nhiều nghiệp vụ phía sau như bán hàng, nhập hàng, tồn kho, giá vốn, hóa đơn, ghi sổ và báo cáo.

Trong thực tế vận hành của hộ kinh doanh và doanh nghiệp nhỏ, dữ liệu sản phẩm dễ bị sai lệch do đặt tên không thống nhất, trùng sản phẩm, thiếu mã nhận diện, dùng nhiều đơn vị đo lường hoặc cập nhật giá bán thủ công. Nếu mắt xích dữ liệu này không được kiểm soát tốt, các nghiệp vụ phía sau có thể sai dây chuyền như bán nhầm sản phẩm, nhập sai đơn vị, sai tồn kho, sai giá bán hoặc khó đối chiếu báo cáo.

Theme này đóng vai trò lớp chuẩn hóa dữ liệu sản phẩm trước khi phát sinh giao dịch — giúp các module phía sau dùng cùng một nguồn dữ liệu đáng tin cậy.

### Scope

Theme này bao gồm các nghiệp vụ chính sau:

- Quản lý hồ sơ sản phẩm: ghi nhận mới, tra cứu, xem chi tiết và cập nhật thông tin sản phẩm.
- Quản lý thông tin nhận diện và mô tả: tên, mã sản phẩm, SKU, barcode, ảnh, mô tả, ghi chú và thông tin chuyên ngành nếu có.
- Quản lý tồn kho cơ bản của sản phẩm: ghi nhận tồn ban đầu và cập nhật tồn trực tiếp từ hồ sơ sản phẩm.
- Quản lý trạng thái kinh doanh: ngừng kinh doanh, kinh doanh lại và kiểm soát việc sử dụng sản phẩm trong nghiệp vụ mới.
- Xóa sản phẩm theo điều kiện hợp lệ, đảm bảo không ảnh hưởng dữ liệu đã phát sinh.
- Quản lý đơn vị đo lường: đơn vị cơ sở, đơn vị quy đổi và tỷ lệ quy đổi; đổi đơn vị cơ sở khi đáp ứng điều kiện nghiệp vụ.
- Quản lý cấu hình giá bán: giá bán chung của cửa hàng và giá bán riêng theo sản phẩm.
- Tính và quản lý giá niêm yết, giá sàn theo sản phẩm và theo từng đơn vị đo lường.
- Quản lý trạng thái giá bán: giá tự tính, giá chỉnh riêng và đặt lại giá tự tính khi cần.
- Kiểm soát tính hợp lệ trong phạm vi tenant: trùng SKU/barcode, dữ liệu bắt buộc, audit các thay đổi cần truy vết.

### Out of scope

Các nội dung sau không thuộc phạm vi xử lý chính của Theme 2, nhưng có thể sử dụng dữ liệu sản phẩm hoặc liên kết với theme này:

- Nghiệp vụ bán hàng: tạo đơn, thêm SP vào đơn, quét barcode tại POS, checkout và thanh toán — **TH-04**.
- Nghiệp vụ nhập hàng, phiếu nhập, NCC và cập nhật tồn từ giao dịch nhập — **TH-06** / partner.
- Quản lý kho chi tiết: xuất/nhập kho, điều chỉnh tồn, kiểm kê, tồn khả dụng, đa kho/chi nhánh — **TH-06**.
- Tính giá vốn hàng bán, giá trị tồn kho — **TH-06** / costing.
- Chính sách giá nâng cao: bảng giá theo nhóm KH, chi nhánh, kênh, khuyến mãi, loyalty.
- Phê duyệt bán dưới giá sàn, kiểm soát chiết khấu nâng cao trong luồng bán — **TH-04**.
- Import/export hoặc đồng bộ hàng loạt (chưa định nghĩa trong SRS hiện tại).
- Hóa đơn điện tử, công nợ, ghi sổ, dashboard — theme tương ứng.

## Epic map

| Epic | Mô tả | Folder |
| ---- | ----- | ------ |
| Epic 01 — Quản lý vòng đời sản phẩm | Hồ sơ SP, ảnh, tồn cơ bản, trạng thái KD, UOM | [EPIC-01-product/](EPIC-01-product/) |
| Epic 02 — Giá niêm yết và giá sàn | Cấu hình giá cửa hàng/SP, giá theo UOM | [EPIC-02-pricing/](EPIC-02-pricing/) |

**SRS:** product scope ở trên; Epic/US/FR tree — xem [README.md](README.md). Module `catalog` hiện là greenfield skeleton.

Index: [README.md](README.md) · Module map: [02-module-map.md](02-module-map.md)
