# Epic 2.6: Nền tảng định giá và khung giá bán

## Epic overview

Epic này giúp VET45 thiết lập nền tảng giá bán cho sản phẩm, bao gồm Giá cơ sở định giá, quy tắc giá cấp cửa hàng, Giá niêm yết, Giá sàn và khung giá theo từng đơn vị bán.

Mục tiêu của Epic không phải là tính giá bán cuối cùng trên giao dịch. Theme 2 chỉ quản lý **khung giá chuẩn** của sản phẩm. Giá bán cuối cùng có thể bị ảnh hưởng bởi khuyến mãi, chiết khấu, coupon, combo hoặc chính sách bán hàng, và thuộc phạm vi của Promotions / Sales.

Vai trò người dùng chính gồm chủ cửa hàng, kế toán, người quản lý sản phẩm và nhân sự được phân quyền quản lý giá. Chủ cửa hàng cần kiểm soát biên lợi nhuận. Kế toán cần biết nguồn Giá cơ sở định giá. Người quản lý sản phẩm cần thiết lập Giá niêm yết và Giá sàn để bán hàng không phá giá hoặc bán sai khung kiểm soát.

Nguyên tắc cốt lõi của Epic này:

- Giá cơ sở định giá là input nền để thiết lập khung giá bán.

- Foundation cho phép nhập Giá cơ sở định giá thủ công trong Product.

- Gói nâng cao có thể lấy Giá cơ sở định giá từ module Giá vốn.

- Giá niêm yết là giá trước khuyến mãi.

- Giá sàn là ngưỡng kiểm soát để bảo vệ lợi nhuận.

- Giá niêm yết và Giá sàn có thể khác nhau theo từng đơn vị bán.

- Giá bán cuối cùng sau khuyến mãi không thuộc Theme 2.

    

Luồng giá trong Theme 2:

Giá cơ sở định giá

→ Quy tắc định giá

→ Giá niêm yết

→ Giá sàn

→ Khung giá bán

→ Promotions / Sales

→ Giá bán cuối cùng trên giao dịch

---

## User stories

| US | Tên | Folder | FR |
| -- | --- | ------ | -- |
| US-01 | Quản lý Giá cơ sở định giá của sản phẩm | [US-01/](US-01/) | 4 |
| US-02 | Thiết lập quy tắc định giá cấp cửa hàng | [US-02/](US-02/) | 4 |
| US-03 | Quản lý Product Unit Price Band | [US-03/](US-03/) | 4 |
| US-04 | Cung cấp khung giá cho Sales và Promotions | [US-04/](US-04/) | 4 |

Theme index: [README.md](../README.md)
