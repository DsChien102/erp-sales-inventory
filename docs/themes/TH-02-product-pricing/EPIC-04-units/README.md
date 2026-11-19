# Epic 2.4: Readiness về đơn vị đo lường

## Epic overview

Epic này giúp Mosaic Retail thiết lập và kiểm soát đơn vị đo lường của sản phẩm, bao gồm đơn vị cơ sở, đơn vị quy đổi, vai trò của từng đơn vị trong bán hàng/nhập hàng/hiển thị, và tác động của đơn vị đến readiness của sản phẩm.

Đơn vị đo lường là dữ liệu nền rất quan trọng vì tồn kho, Giá cơ sở định giá, Giá niêm yết, Giá sàn, nhập hàng và bán hàng đều cần hiểu “số lượng này đang tính theo đơn vị nào”. Nếu đơn vị cơ sở sai hoặc thiếu, các dữ liệu phía sau như tồn kho và giá đều có nguy cơ bị hiểu sai.

Vai trò người dùng chính gồm chủ cửa hàng, người nhập liệu sản phẩm, kế toán và quản lý kho nếu có. Chủ cửa hàng hoặc người nhập liệu cần thiết lập đơn vị đúng ngay từ đầu. Kế toán và quản lý kho cần đơn vị ổn định để đối chiếu tồn kho, giá vốn, nhập hàng và bán hàng.

Nguyên tắc cốt lõi của Epic này:

- Mỗi sản phẩm có một đơn vị cơ sở tại một thời điểm.

- Tồn kho cơ bản được diễn giải theo đơn vị cơ sở.

- Đơn vị quy đổi giúp sản phẩm được bán, nhập hoặc hiển thị theo nhiều cách khác nhau.

- Giá niêm yết và Giá sàn có thể được quản lý theo từng đơn vị bán.

- Đổi đơn vị cơ sở là thao tác nhạy cảm và cần kiểm soát chặt.

---

## User stories

| US | Tên | Folder | FR | Status |
| -- | --- | ------ | -- | ------ |
| US-01 | Thiết lập đơn vị cơ sở cho sản phẩm | [US-01/](US-01/) | 3 | in_scope |
| US-02 | Quản lý đơn vị quy đổi của sản phẩm | [US-02/](US-02/) | 4 | in_scope |
| US-03 | Đổi đơn vị cơ sở có kiểm soát | [US-03/](US-03/) | 4 | out_of_scope |
| US-04 | Cung cấp đơn vị đo lường cho các module khác | [US-04/](US-04/) | 4 | pending |

Theme index: [README.md](../README.md)
