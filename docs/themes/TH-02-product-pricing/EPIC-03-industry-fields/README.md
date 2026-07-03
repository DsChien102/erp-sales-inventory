# Epic 2.3: Thông tin sản phẩm đặc thù theo ngành

## Epic overview

Epic này giúp VET45 ghi nhận và quản lý các thông tin sản phẩm thay đổi theo ngành kinh doanh mà không hard-code vào Product. Với ngành thú y, hệ thống có thể cần các thông tin như thành phần, chỉ định, chống chỉ định, cách dùng, liều dùng, thời gian ngưng sử dụng hoặc nhóm thuốc. Nhưng các thông tin này không nên trở thành field cố định trong Product, vì VET45 cần mở rộng sang các ngành bán lẻ khác trong tương lai.

Vai trò người dùng chính gồm chủ cửa hàng, admin hệ thống tenant, người nhập liệu sản phẩm và nhân sự vận hành có quyền chỉnh thông tin sản phẩm. Chủ cửa hàng hoặc admin cần cấu hình thông tin nào là cần thiết cho ngành của mình. Người nhập liệu cần điền thông tin theo cấu hình đó. Nhân viên bán hàng, kho, kế toán hoặc quản lý cần xem các thông tin này khi vận hành.

Epic này chuyển cách thiết kế từ “Product có nhiều field cố định” sang mô hình **Custom Field Group → Custom Field → Product Custom Field Value**.

---

## User stories

| US | Tên | Folder | FR |
| -- | --- | ------ | -- |
| US-01 | Khởi tạo cấu hình thông tin đặc thù theo ngành | [US-01/](US-01/) | 4 |
| US-02 | Ghi nhận thông tin đặc thù ngành theo từng sản phẩm | [US-02/](US-02/) | 4 |
| US-03 | Tìm kiếm, lọc và sử dụng thông tin đặc thù ngành | [US-03/](US-03/) | 4 |

Theme index: [README.md](../README.md)
