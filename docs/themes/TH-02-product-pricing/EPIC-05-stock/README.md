# Epic 2.5: Chế độ tồn kho và readiness tồn kho

## Epic overview

Epic này giúp VET45 quản lý cách một sản phẩm được theo dõi tồn kho trong Theme 2, đồng thời phân biệt rõ giữa **thiết lập tồn kho** và **số lượng tồn thực tế**.

Ở gói Foundation, VET45 cần cho phép người dùng nhập và chỉnh tồn kho cơ bản trực tiếp trong Product để có thể vận hành nhanh, không cần triển khai đầy đủ module Kho. Ở gói nâng cao, tồn kho không còn được chỉnh trực tiếp trong Product, mà được đọc từ module Kho dưới dạng stock summary hoặc nguồn dữ liệu tồn kho chuyên trách.

Vai trò người dùng chính gồm chủ cửa hàng, người nhập liệu sản phẩm, nhân viên kho nếu có, kế toán và người quản lý vận hành. Chủ cửa hàng cần biết sản phẩm có đang theo dõi tồn kho hay không. Người nhập liệu cần ghi nhận tồn kho ban đầu. Kế toán và quản lý kho cần dữ liệu tồn kho rõ nguồn, rõ đơn vị, không bị nhập nhầm.

Nguyên tắc cốt lõi của Epic này:

- Tồn kho chỉ có ý nghĩa khi sản phẩm có đơn vị cơ sở.

- Trong Basic stock mode, tồn kho được ghi nhận trực tiếp trong Product.

- Trong Advanced stock mode, Product chỉ hiển thị tồn kho đọc từ module Kho.

- Readiness tồn kho phản ánh việc sản phẩm đã có thiết lập tồn kho hoặc nguồn tồn kho hợp lệ chưa.

- Tồn kho bằng 0 không nhất thiết là thiếu thiết lập tồn kho; đó có thể là trạng thái hết hàng.

- Các thay đổi tồn kho cơ bản phải có lịch sử để truy vết.

    

---

## User stories

| US | Tên | Folder | FR |
| -- | --- | ------ | -- |
| US-01 | Quản lý Stock Profile của sản phẩm | [US-01/](US-01/) | 3 |
| US-02 | Quản lý tồn kho cơ bản trong Foundation | [US-02/](US-02/) | 4 |
| US-03 | Hiển thị tồn kho nâng cao từ module Kho | [US-03/](US-03/) | 4 |
| US-04 | Chuyển đổi từ Basic stock sang Advanced stock | [US-04/](US-04/) | 4 |

Theme index: [README.md](../README.md)
