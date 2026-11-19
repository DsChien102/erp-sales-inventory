# Epic 2.7: Vòng đời sản phẩm và kiểm soát

## Epic overview

Epic này giúp Mosaic Retail quản lý vòng đời sản phẩm sau khi sản phẩm đã được tạo, bao gồm sửa thông tin, quản lý ảnh, ngừng kinh doanh, kinh doanh lại, xóa mềm và truy vết các thay đổi quan trọng.

Trong thực tế vận hành, sản phẩm không đứng yên. Tên sản phẩm có thể cần sửa, barcode có thể thay đổi, ảnh sản phẩm có thể được cập nhật, đơn vị hoặc giá có thể được điều chỉnh, sản phẩm có thể tạm ngừng kinh doanh hoặc không còn bán nữa. Những thay đổi này cần được kiểm soát để không làm sai dữ liệu giao dịch, tồn kho, giá, hóa đơn hoặc báo cáo đã phát sinh trước đó.

Vai trò người dùng chính gồm chủ cửa hàng, người quản lý sản phẩm, kế toán, nhân viên nhập liệu và admin tenant. Chủ cửa hàng cần kiểm soát sản phẩm nào còn được kinh doanh. Người quản lý sản phẩm cần cập nhật dữ liệu hiện hành. Kế toán cần dữ liệu lịch sử không bị phá vỡ. Admin tenant cần kiểm soát quyền và lịch sử thay đổi.

Nguyên tắc cốt lõi của Epic này:

- Chỉnh sửa dữ liệu hiện hành không được làm sai dữ liệu lịch sử.

- Ngừng kinh doanh khác với xóa sản phẩm.

- Sản phẩm ngừng kinh doanh không được dùng trong giao dịch mới.

- Xóa sản phẩm nên là xóa mềm và có kiểm soát.

- Dữ liệu đã phát sinh giao dịch cần được bảo toàn.

- Các thay đổi quan trọng cần có lịch sử truy vết.

- Hành động nguy hiểm phải có xác nhận rõ ràng.

---

## User stories

| US | Tên | Folder | FR | Status |
| -- | --- | ------ | -- | ------ |
| US-01 | Bảo trì hồ sơ sản phẩm sau khi tạo | [US-01/](US-01/) | 4 | in_scope |
| US-02 | Ngừng kinh doanh và kinh doanh lại sản phẩm | [US-02/](US-02/) | 4 | in_scope |
| US-03 | Xóa mềm sản phẩm có kiểm soát | [US-03/](US-03/) | 4 | in_scope |
| US-04 | Truy vết và kiểm soát thay đổi sản phẩm | [US-04/](US-04/) | 4 | in_scope |

Theme index: [README.md](../README.md)
