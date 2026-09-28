# Mục lục bộ tri thức quản lý tồn kho, giá vốn và định giá liên quan

Bộ tri thức gồm **45 bài**, tổ chức thành 12 cụm. Mỗi bài trả lời một câu hỏi nghiệp vụ độc lập, dùng thuật ngữ tiếng Việt và kết thúc bằng nguồn quyết định làm căn cứ. Nội dung giải thích kiến thức; phạm vi triển khai hiện tại hoặc tương lai được ghi rõ trong từng bài.

## Cách sử dụng

- Người mới nên đọc `KB-KGV-001` → `006`, sau đó chọn cụm nghiệp vụ cần tìm.
- Người làm sản phẩm dùng phần **Quy tắc vận hành** và **Ngoại lệ/cách làm sai**.
- Người làm kỹ thuật dùng Article ID, Decision ID và chủ đề liên quan để truy về SRS.
- Người thiết kế trải nghiệm bắt đầu từ `KB-KGV-001`, `003`, `024`, `027`, `028`, `041` và `042` để giữ luồng theo công việc, nhập liệu tối thiểu, nhãn tiếng Việt và phục hồi an toàn.
- Bài mang loại `FUTURE_CONCEPT` chỉ giải thích hướng mở rộng, không phải cam kết chức năng hiện tại.

## Tra theo Business Journey

Bảng này giúp đi từ công việc nghiệp vụ sang bộ tri thức cần đọc. **Cốt lõi** là nền bắt buộc để hiểu Journey; **hỗ trợ** dùng để đào sâu ngoại lệ, kiểm soát, tính toàn vẹn hoặc hướng mở rộng. Decision Register và SRS vẫn là nguồn có thẩm quyền cho rule triển khai.

| Business Journey | Bài cốt lõi | Bài hỗ trợ |
|---|---|---|
| [`BJ-01` — Theo dõi tồn, khả dụng và chỉ báo vận hành](../../02.specification/behavior/journeys/BJ-01-theo-doi-ton-kha-dung-va-chi-bao-van-hanh.md) | [`KB-KGV-005`](KB-KGV-005-ton-vat-ly-va-ton-kha-dung.md); [`KB-KGV-033`](KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon.md); [`KB-KGV-036`](KB-KGV-036-ton-du-kien-va-de-xuat-bo-sung-hang.md); [`KB-KGV-038`](KB-KGV-038-canh-bao-ton-kho-va-vong-doi-xu-ly.md) | [`KB-KGV-001`](KB-KGV-001-pham-vi-quan-ly-ton-kho-va-gia-von.md); [`KB-KGV-003`](KB-KGV-003-kho-cua-hang-va-khoa-dinh-danh-so-du-ton-kho.md); [`KB-KGV-006`](KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am.md); [`KB-KGV-014`](KB-KGV-014-hang-can-han-het-han-hu-hong-va-tieu-huy.md); [`KB-KGV-037`](KB-KGV-037-ngung-kinh-doanh-san-pham-va-dong-kho.md); [`KB-KGV-040`](KB-KGV-040-hieu-nang-va-nang-luc-xu-ly-cua-he-thong-ton-kho.md) |
| [`BJ-02` — Nhận hàng mua](../../02.specification/behavior/journeys/BJ-02-nhan-hang-mua.md) | [`KB-KGV-007`](KB-KGV-007-nhan-hang-mua-va-xu-ly-chenh-lech-giao-nhan.md); [`KB-KGV-008`](KB-KGV-008-hang-da-nhan-nhung-chua-chot-gia.md); [`KB-KGV-024`](KB-KGV-024-chinh-sach-quan-ly-hang-thong-thuong-theo-lo-hoac-theo-serial.md); [`KB-KGV-025`](KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md); [`KB-KGV-031`](KB-KGV-031-phe-duyet-inventory-operation-theo-muc-rui-ro.md) | [`KB-KGV-001`](KB-KGV-001-pham-vi-quan-ly-ton-kho-va-gia-von.md); [`KB-KGV-002`](KB-KGV-002-ranh-gioi-trach-nhiem-giua-cac-he-thong-nghiep-vu.md); [`KB-KGV-004`](KB-KGV-004-don-vi-tinh-va-cach-quy-doi-so-luong-ton-kho.md); [`KB-KGV-026`](KB-KGV-026-danh-tinh-va-vong-doi-cua-mot-serial.md); [`KB-KGV-027`](KB-KGV-027-vong-doi-cua-mot-inventory-operation.md); [`KB-KGV-028`](KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md); [`KB-KGV-029`](KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md) |
| [`BJ-03` — Xác lập giá trị ban đầu của hàng nhận](../../02.specification/behavior/journeys/BJ-03-xac-lap-gia-tri-ban-dau-cua-hang-nhan.md) | [`KB-KGV-008`](KB-KGV-008-hang-da-nhan-nhung-chua-chot-gia.md); [`KB-KGV-015`](KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md); [`KB-KGV-019`](KB-KGV-019-cac-thanh-phan-hinh-thanh-gia-tri-hang-nhap.md) | [`KB-KGV-002`](KB-KGV-002-ranh-gioi-trach-nhiem-giua-cac-he-thong-nghiep-vu.md); [`KB-KGV-017`](KB-KGV-017-cong-bo-don-gia-ton-kho-va-ghi-nhan-gia-von-xuat-ban.md); [`KB-KGV-043`](KB-KGV-043-kich-ban-chiet-khau-mua-hang-theo-ky.md); [`KB-KGV-044`](KB-KGV-044-tu-gia-von-tham-chieu-den-gia-ban-giao-dich.md) |
| [`BJ-04` — Quản lý vòng đời giữ hàng](../../02.specification/behavior/journeys/BJ-04-quan-ly-vong-oi-giu-hang.md) | [`KB-KGV-005`](KB-KGV-005-ton-vat-ly-va-ton-kha-dung.md); [`KB-KGV-009`](KB-KGV-009-giu-hang-va-xu-ly-don-khong-du-ton-kha-dung.md); [`KB-KGV-027`](KB-KGV-027-vong-doi-cua-mot-inventory-operation.md) | [`KB-KGV-006`](KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am.md); [`KB-KGV-028`](KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md); [`KB-KGV-030`](KB-KGV-030-quyen-chuc-nang-pham-vi-kho-va-bao-ve-du-lieu-tai-chinh.md) |
| [`BJ-05` — Lấy hàng và bàn giao đơn](../../02.specification/behavior/journeys/BJ-05-lay-hang-va-ban-giao-on.md) | [`KB-KGV-009`](KB-KGV-009-giu-hang-va-xu-ly-don-khong-du-ton-kha-dung.md); [`KB-KGV-010`](KB-KGV-010-chon-hang-de-xuat-va-thoi-diem-hoan-tat-xuat-ban.md); [`KB-KGV-025`](KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md); [`KB-KGV-029`](KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md) | [`KB-KGV-006`](KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am.md); [`KB-KGV-017`](KB-KGV-017-cong-bo-don-gia-ton-kho-va-ghi-nhan-gia-von-xuat-ban.md); [`KB-KGV-028`](KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md); [`KB-KGV-039`](KB-KGV-039-ban-hang-pos-offline.md) |
| [`BJ-06` — Tiếp nhận và phân loại hàng khách trả](../../02.specification/behavior/journeys/BJ-06-tiep-nhan-va-phan-loai-hang-khach-tra.md) | [`KB-KGV-012`](KB-KGV-012-hang-khach-tra-tu-tiep-nhan-den-phan-loai.md); [`KB-KGV-020`](KB-KGV-020-dinh-gia-hang-tra-tieu-huy-va-chenh-lech-thua-thieu.md); [`KB-KGV-025`](KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md); [`KB-KGV-035`](KB-KGV-035-combo-ban-hang-va-ton-kho-theo-thanh-phan.md) | [`KB-KGV-002`](KB-KGV-002-ranh-gioi-trach-nhiem-giua-cac-he-thong-nghiep-vu.md); [`KB-KGV-014`](KB-KGV-014-hang-can-han-het-han-hu-hong-va-tieu-huy.md); [`KB-KGV-027`](KB-KGV-027-vong-doi-cua-mot-inventory-operation.md); [`KB-KGV-029`](KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md); [`KB-KGV-034`](KB-KGV-034-quyen-so-huu-hang-hoa-hang-ky-gui-va-hang-demo.md) |
| [`BJ-07` — Thực hiện trả hàng cho nhà cung cấp](../../02.specification/behavior/journeys/BJ-07-thuc-hien-tra-hang-cho-nha-cung-cap.md) | [`KB-KGV-010`](KB-KGV-010-chon-hang-de-xuat-va-thoi-diem-hoan-tat-xuat-ban.md); [`KB-KGV-013`](KB-KGV-013-tra-hang-cho-nha-cung-cap.md); [`KB-KGV-015`](KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md); [`KB-KGV-029`](KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md) | [`KB-KGV-002`](KB-KGV-002-ranh-gioi-trach-nhiem-giua-cac-he-thong-nghiep-vu.md); [`KB-KGV-021`](KB-KGV-021-sua-sai-ton-kho-khong-sua-lich-su.md); [`KB-KGV-027`](KB-KGV-027-vong-doi-cua-mot-inventory-operation.md); [`KB-KGV-028`](KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md) |
| [`BJ-08` — Kiểm kê và điều chỉnh chênh lệch](../../02.specification/behavior/journeys/BJ-08-kiem-ke-va-ieu-chinh-chenh-lech.md) | [`KB-KGV-011`](KB-KGV-011-kiem-ke-hang-ton-kho-tu-khoa-pham-vi-den-dieu-chinh-chenh-lech.md); [`KB-KGV-020`](KB-KGV-020-dinh-gia-hang-tra-tieu-huy-va-chenh-lech-thua-thieu.md); [`KB-KGV-021`](KB-KGV-021-sua-sai-ton-kho-khong-sua-lich-su.md); [`KB-KGV-029`](KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md); [`KB-KGV-032`](KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md) | [`KB-KGV-006`](KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am.md); [`KB-KGV-030`](KB-KGV-030-quyen-chuc-nang-pham-vi-kho-va-bao-ve-du-lieu-tai-chinh.md); [`KB-KGV-031`](KB-KGV-031-phe-duyet-inventory-operation-theo-muc-rui-ro.md); [`KB-KGV-033`](KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon.md) |
| [`BJ-09` — Quản lý trạng thái hàng](../../02.specification/behavior/journeys/BJ-09-quan-ly-trang-thai-hang.md) | [`KB-KGV-005`](KB-KGV-005-ton-vat-ly-va-ton-kha-dung.md); [`KB-KGV-014`](KB-KGV-014-hang-can-han-het-han-hu-hong-va-tieu-huy.md); [`KB-KGV-025`](KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md); [`KB-KGV-034`](KB-KGV-034-quyen-so-huu-hang-hoa-hang-ky-gui-va-hang-demo.md) | [`KB-KGV-006`](KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am.md); [`KB-KGV-026`](KB-KGV-026-danh-tinh-va-vong-doi-cua-mot-serial.md); [`KB-KGV-027`](KB-KGV-027-vong-doi-cua-mot-inventory-operation.md); [`KB-KGV-030`](KB-KGV-030-quyen-chuc-nang-pham-vi-kho-va-bao-ve-du-lieu-tai-chinh.md); [`KB-KGV-037`](KB-KGV-037-ngung-kinh-doanh-san-pham-va-dong-kho.md); [`KB-KGV-038`](KB-KGV-038-canh-bao-ton-kho-va-vong-doi-xu-ly.md) |
| [`BJ-10` — Tiêu hủy hàng](../../02.specification/behavior/journeys/BJ-10-tieu-huy-hang.md) | [`KB-KGV-014`](KB-KGV-014-hang-can-han-het-han-hu-hong-va-tieu-huy.md); [`KB-KGV-020`](KB-KGV-020-dinh-gia-hang-tra-tieu-huy-va-chenh-lech-thua-thieu.md); [`KB-KGV-029`](KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md); [`KB-KGV-031`](KB-KGV-031-phe-duyet-inventory-operation-theo-muc-rui-ro.md) | [`KB-KGV-006`](KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am.md); [`KB-KGV-027`](KB-KGV-027-vong-doi-cua-mot-inventory-operation.md); [`KB-KGV-028`](KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md); [`KB-KGV-030`](KB-KGV-030-quyen-chuc-nang-pham-vi-kho-va-bao-ve-du-lieu-tai-chinh.md) |
| [`BJ-11` — Hủy và sửa sai nghiệp vụ kho](../../02.specification/behavior/journeys/BJ-11-huy-va-sua-sai-nghiep-vu-kho.md) | [`KB-KGV-021`](KB-KGV-021-sua-sai-ton-kho-khong-sua-lich-su.md); [`KB-KGV-027`](KB-KGV-027-vong-doi-cua-mot-inventory-operation.md); [`KB-KGV-028`](KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md); [`KB-KGV-029`](KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md) | [`KB-KGV-006`](KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am.md); [`KB-KGV-030`](KB-KGV-030-quyen-chuc-nang-pham-vi-kho-va-bao-ve-du-lieu-tai-chinh.md); [`KB-KGV-032`](KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md); [`KB-KGV-041`](KB-KGV-041-cach-kiem-soat-thay-doi-doi-voi-quy-tac-nghiep-vu.md) |
| [`BJ-12` — Khởi tạo số dư tồn kho đầu kỳ](../../02.specification/behavior/journeys/BJ-12-khoi-tao-so-du-ton-kho-au-ky.md) | [`KB-KGV-003`](KB-KGV-003-kho-cua-hang-va-khoa-dinh-danh-so-du-ton-kho.md); [`KB-KGV-004`](KB-KGV-004-don-vi-tinh-va-cach-quy-doi-so-luong-ton-kho.md); [`KB-KGV-015`](KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md); [`KB-KGV-022`](KB-KGV-022-chuan-bi-du-lieu-so-du-ton-kho-dau-ky.md); [`KB-KGV-023`](KB-KGV-023-xac-nhan-so-du-dau-ky-chuyen-doi-chinh-thuc-va-doi-soat-migration.md) | [`KB-KGV-001`](KB-KGV-001-pham-vi-quan-ly-ton-kho-va-gia-von.md); [`KB-KGV-002`](KB-KGV-002-ranh-gioi-trach-nhiem-giua-cac-he-thong-nghiep-vu.md); [`KB-KGV-006`](KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am.md); [`KB-KGV-029`](KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md); [`KB-KGV-030`](KB-KGV-030-quyen-chuc-nang-pham-vi-kho-va-bao-ve-du-lieu-tai-chinh.md); [`KB-KGV-032`](KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md); [`KB-KGV-042`](KB-KGV-042-kien-truc-mo-rong-va-ranh-gioi-mvp.md) |
| [`BJ-13` — Điều chỉnh giá trị hàng nhập](../../02.specification/behavior/journeys/BJ-13-dieu-chinh-gia-tri-hang-nhap.md) | [`KB-KGV-015`](KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md); [`KB-KGV-018`](KB-KGV-018-doi-soat-gia-von-cuoi-ky-va-cap-nhat-dot-xuat-giua-ky.md); [`KB-KGV-019`](KB-KGV-019-cac-thanh-phan-hinh-thanh-gia-tri-hang-nhap.md); [`KB-KGV-043`](KB-KGV-043-kich-ban-chiet-khau-mua-hang-theo-ky.md) | [`KB-KGV-002`](KB-KGV-002-ranh-gioi-trach-nhiem-giua-cac-he-thong-nghiep-vu.md); [`KB-KGV-017`](KB-KGV-017-cong-bo-don-gia-ton-kho-va-ghi-nhan-gia-von-xuat-ban.md); [`KB-KGV-020`](KB-KGV-020-dinh-gia-hang-tra-tieu-huy-va-chenh-lech-thua-thieu.md); [`KB-KGV-028`](KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md); [`KB-KGV-029`](KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md); [`KB-KGV-045`](KB-KGV-045-ra-soat-gia-von-tham-chieu-sau-chot-ky.md) |
| [`BJ-14` — Tính và công bố giá vốn](../../02.specification/behavior/journeys/BJ-14-tinh-va-cong-bo-gia-von.md) | [`KB-KGV-015`](KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md); [`KB-KGV-016`](KB-KGV-016-vi-sao-tinh-song-song-hai-phuong-phap-gia-von.md); [`KB-KGV-017`](KB-KGV-017-cong-bo-don-gia-ton-kho-va-ghi-nhan-gia-von-xuat-ban.md); [`KB-KGV-018`](KB-KGV-018-doi-soat-gia-von-cuoi-ky-va-cap-nhat-dot-xuat-giua-ky.md); [`KB-KGV-045`](KB-KGV-045-ra-soat-gia-von-tham-chieu-sau-chot-ky.md) | [`KB-KGV-002`](KB-KGV-002-ranh-gioi-trach-nhiem-giua-cac-he-thong-nghiep-vu.md); [`KB-KGV-019`](KB-KGV-019-cac-thanh-phan-hinh-thanh-gia-tri-hang-nhap.md); [`KB-KGV-028`](KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md); [`KB-KGV-029`](KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md); [`KB-KGV-030`](KB-KGV-030-quyen-chuc-nang-pham-vi-kho-va-bao-ve-du-lieu-tai-chinh.md); [`KB-KGV-041`](KB-KGV-041-cach-kiem-soat-thay-doi-doi-voi-quy-tac-nghiep-vu.md); [`KB-KGV-043`](KB-KGV-043-kich-ban-chiet-khau-mua-hang-theo-ky.md); [`KB-KGV-044`](KB-KGV-044-tu-gia-von-tham-chieu-den-gia-ban-giao-dich.md) |
| [`BJ-15` — Tra cứu báo cáo tồn và thẻ kho](../../02.specification/behavior/journeys/BJ-15-tra-cuu-bao-cao-ton-va-the-kho.md) | [`KB-KGV-006`](KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am.md); [`KB-KGV-030`](KB-KGV-030-quyen-chuc-nang-pham-vi-kho-va-bao-ve-du-lieu-tai-chinh.md); [`KB-KGV-032`](KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md); [`KB-KGV-033`](KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon.md) | [`KB-KGV-001`](KB-KGV-001-pham-vi-quan-ly-ton-kho-va-gia-von.md); [`KB-KGV-005`](KB-KGV-005-ton-vat-ly-va-ton-kha-dung.md); [`KB-KGV-015`](KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md); [`KB-KGV-018`](KB-KGV-018-doi-soat-gia-von-cuoi-ky-va-cap-nhat-dot-xuat-giua-ky.md); [`KB-KGV-038`](KB-KGV-038-canh-bao-ton-kho-va-vong-doi-xu-ly.md); [`KB-KGV-040`](KB-KGV-040-hieu-nang-va-nang-luc-xu-ly-cua-he-thong-ton-kho.md) |
| [`BJ-16` — Điều tra và đối soát sai lệch](../../02.specification/behavior/journeys/BJ-16-ieu-tra-va-oi-soat-sai-lech.md) | [`KB-KGV-021`](KB-KGV-021-sua-sai-ton-kho-khong-sua-lich-su.md); [`KB-KGV-028`](KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md); [`KB-KGV-032`](KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md); [`KB-KGV-033`](KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon.md) | [`KB-KGV-006`](KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am.md); [`KB-KGV-027`](KB-KGV-027-vong-doi-cua-mot-inventory-operation.md); [`KB-KGV-029`](KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md); [`KB-KGV-030`](KB-KGV-030-quyen-chuc-nang-pham-vi-kho-va-bao-ve-du-lieu-tai-chinh.md); [`KB-KGV-031`](KB-KGV-031-phe-duyet-inventory-operation-theo-muc-rui-ro.md); [`KB-KGV-040`](KB-KGV-040-hieu-nang-va-nang-luc-xu-ly-cua-he-thong-ton-kho.md) |
| [`BJ-17` — Phục hồi nghiệp vụ có kết quả chưa xác định](../../02.specification/behavior/journeys/BJ-17-phuc-hoi-nghiep-vu-co-ket-qua-chua-xac-inh.md) | [`KB-KGV-027`](KB-KGV-027-vong-doi-cua-mot-inventory-operation.md); [`KB-KGV-028`](KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md); [`KB-KGV-029`](KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md); [`KB-KGV-032`](KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md) | [`KB-KGV-002`](KB-KGV-002-ranh-gioi-trach-nhiem-giua-cac-he-thong-nghiep-vu.md); [`KB-KGV-030`](KB-KGV-030-quyen-chuc-nang-pham-vi-kho-va-bao-ve-du-lieu-tai-chinh.md); [`KB-KGV-033`](KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon.md); [`KB-KGV-041`](KB-KGV-041-cach-kiem-soat-thay-doi-doi-voi-quy-tac-nghiep-vu.md); [`KB-KGV-042`](KB-KGV-042-kien-truc-mo-rong-va-ranh-gioi-mvp.md) |

## C01 — Nền tảng quản lý tồn kho

| ID | Bài viết |
|---|---|
| `KB-KGV-001` | [Phạm vi quản lý tồn kho và giá vốn](KB-KGV-001-pham-vi-quan-ly-ton-kho-va-gia-von.md) |
| `KB-KGV-002` | [Ranh giới trách nhiệm giữa các hệ thống nghiệp vụ](KB-KGV-002-ranh-gioi-trach-nhiem-giua-cac-he-thong-nghiep-vu.md) |
| `KB-KGV-003` | [Cửa hàng, kho và khóa định danh số dư tồn kho](KB-KGV-003-kho-cua-hang-va-khoa-dinh-danh-so-du-ton-kho.md) |
| `KB-KGV-004` | [Đơn vị tính và cách quy đổi số lượng tồn kho](KB-KGV-004-don-vi-tinh-va-cach-quy-doi-so-luong-ton-kho.md) |
| `KB-KGV-005` | [Tồn vật lý, lượng đủ điều kiện bán, lượng giữ và tồn khả dụng](KB-KGV-005-ton-vat-ly-va-ton-kha-dung.md) |
| `KB-KGV-006` | [Tính chính thức của tồn kho và nguyên tắc chống xuất âm](KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am.md) |

## C02 — Nhận, giữ và xuất hàng

| ID | Bài viết |
|---|---|
| `KB-KGV-007` | [Nhận hàng mua và xử lý chênh lệch giao nhận](KB-KGV-007-nhan-hang-mua-va-xu-ly-chenh-lech-giao-nhan.md) |
| `KB-KGV-008` | [Hàng đã nhận nhưng chưa chốt giá và điều kiện đưa vào bán](KB-KGV-008-hang-da-nhan-nhung-chua-chot-gia.md) |
| `KB-KGV-009` | [Giữ hàng và xử lý đơn không đủ tồn khả dụng](KB-KGV-009-giu-hang-va-xu-ly-don-khong-du-ton-kha-dung.md) |
| `KB-KGV-010` | [Chọn hàng để xuất và thời điểm hoàn tất xuất bán](KB-KGV-010-chon-hang-de-xuat-va-thoi-diem-hoan-tat-xuat-ban.md) |

## C03 — Kiểm kê, trả hàng và loại bỏ

| ID | Bài viết |
|---|---|
| `KB-KGV-011` | [Kiểm kê hàng tồn kho từ khóa phạm vi đến điều chỉnh chênh lệch](KB-KGV-011-kiem-ke-hang-ton-kho-tu-khoa-pham-vi-den-dieu-chinh-chenh-lech.md) |
| `KB-KGV-012` | [Hàng khách trả từ tiếp nhận đến phân loại](KB-KGV-012-hang-khach-tra-tu-tiep-nhan-den-phan-loai.md) |
| `KB-KGV-013` | [Trả hàng cho nhà cung cấp](KB-KGV-013-tra-hang-cho-nha-cung-cap.md) |
| `KB-KGV-014` | [Hàng cận hạn, hết hạn, hư hỏng và tiêu hủy](KB-KGV-014-hang-can-han-het-han-hu-hong-va-tieu-huy.md) |

## C04 — Giá vốn và định giá tồn kho

| ID | Bài viết |
|---|---|
| `KB-KGV-015` | [Đơn giá tồn kho chính thức và tổng giá trị ghi sổ](KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md) |
| `KB-KGV-016` | [Vì sao sử dụng song song hai phương pháp tính giá vốn?](KB-KGV-016-vi-sao-tinh-song-song-hai-phuong-phap-gia-von.md) |
| `KB-KGV-017` | [Công bố giá vốn chính thức và ghi nhận giá vốn hàng bán](KB-KGV-017-cong-bo-don-gia-ton-kho-va-ghi-nhan-gia-von-xuat-ban.md) |
| `KB-KGV-018` | [Đối soát giá vốn cuối kỳ và cập nhật đột xuất giữa kỳ](KB-KGV-018-doi-soat-gia-von-cuoi-ky-va-cap-nhat-dot-xuat-giua-ky.md) |
| `KB-KGV-019` | [Các thành phần hình thành giá trị hàng nhập](KB-KGV-019-cac-thanh-phan-hinh-thanh-gia-tri-hang-nhap.md) |
| `KB-KGV-020` | [Định giá hàng trả, tiêu hủy và chênh lệch thừa thiếu](KB-KGV-020-dinh-gia-hang-tra-tieu-huy-va-chenh-lech-thua-thieu.md) |

## C05 — Sửa sai và số dư đầu kỳ

| ID | Bài viết |
|---|---|
| `KB-KGV-021` | [Sửa sai tồn kho mà không sửa lịch sử](KB-KGV-021-sua-sai-ton-kho-khong-sua-lich-su.md) |
| `KB-KGV-022` | [Chuẩn bị dữ liệu số dư tồn kho đầu kỳ](KB-KGV-022-chuan-bi-du-lieu-so-du-ton-kho-dau-ky.md) |
| `KB-KGV-023` | [Xác nhận số dư đầu kỳ, Chuyển đổi chính thức và đối soát migration](KB-KGV-023-xac-nhan-so-du-dau-ky-chuyen-doi-chinh-thuc-va-doi-soat-migration.md) |

## C06 — Lô, hạn dùng và serial tương lai

| ID | Bài viết | Phạm vi |
|---|---|---|
| `KB-KGV-024` | [Chọn quản lý thông thường hay quản lý theo lô](KB-KGV-024-chinh-sach-quan-ly-hang-thong-thuong-theo-lo-hoac-theo-serial.md) | Hiện tại |
| `KB-KGV-025` | [Danh tính và vòng đời của một lô hàng](KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md) | Hiện tại |
| `KB-KGV-026` | [Quản lý theo serial khác quản lý theo lô như thế nào?](KB-KGV-026-danh-tinh-va-vong-doi-cua-mot-serial.md) | Tương lai |

## C07 — Inventory Operation và tính toàn vẹn giao dịch

| ID | Bài viết |
|---|---|
| `KB-KGV-027` | [Vòng đời của một Inventory Operation](KB-KGV-027-vong-doi-cua-mot-inventory-operation.md) |
| `KB-KGV-028` | [Idempotency, phiên bản nguồn và xử lý kết quả chưa xác định](KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md) |
| `KB-KGV-029` | [Tính nguyên tử khi ghi tồn kho và phát sự kiện](KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md) |

## C08 — Quyền, phê duyệt, sổ và báo cáo

| ID | Bài viết |
|---|---|
| `KB-KGV-030` | [Quyền chức năng, phạm vi kho và bảo vệ dữ liệu tài chính](KB-KGV-030-quyen-chuc-nang-pham-vi-kho-va-bao-ve-du-lieu-tai-chinh.md) |
| `KB-KGV-031` | [Phê duyệt Inventory Operation theo mức rủi ro](KB-KGV-031-phe-duyet-inventory-operation-theo-muc-rui-ro.md) |
| `KB-KGV-032` | [Movement ledger, số dư dẫn xuất và phục hồi sau sự cố](KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md) |
| `KB-KGV-033` | [Thẻ kho, báo cáo lịch sử và đối soát nguồn](KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon.md) |

## C09 — Hàng đặc thù, combo, bổ sung và vòng đời master

| ID | Bài viết |
|---|---|
| `KB-KGV-034` | [Quyền sở hữu hàng hóa, hàng ký gửi và hàng demo](KB-KGV-034-quyen-so-huu-hang-hoa-hang-ky-gui-va-hang-demo.md) |
| `KB-KGV-035` | [Combo bán hàng và tồn kho theo thành phần](KB-KGV-035-combo-ban-hang-va-ton-kho-theo-thanh-phan.md) |
| `KB-KGV-036` | [Nhận biết tồn thấp và gợi ý lượng bổ sung](KB-KGV-036-ton-du-kien-va-de-xuat-bo-sung-hang.md) |
| `KB-KGV-037` | [Ngừng kinh doanh sản phẩm và điều kiện quản trị kho](KB-KGV-037-ngung-kinh-doanh-san-pham-va-dong-kho.md) |

## C10 — Vận hành, phục hồi và thay đổi

| ID | Bài viết | Phạm vi |
|---|---|---|
| `KB-KGV-038` | [Chỉ báo dẫn xuất và hồ sơ cần xử lý](KB-KGV-038-canh-bao-ton-kho-va-vong-doi-xu-ly.md) | Hiện tại |
| `KB-KGV-039` | [Bán hàng khi mất kết nối: định hướng và điều kiện mở phạm vi](KB-KGV-039-ban-hang-pos-offline.md) | Tương lai |
| `KB-KGV-040` | [Hiệu năng và năng lực xử lý của hệ thống tồn kho](KB-KGV-040-hieu-nang-va-nang-luc-xu-ly-cua-he-thong-ton-kho.md) | Hiện tại |
| `KB-KGV-041` | [Cách kiểm soát thay đổi đối với quy tắc nghiệp vụ](KB-KGV-041-cach-kiem-soat-thay-doi-doi-voi-quy-tac-nghiep-vu.md) | Hiện tại |

## C11 — Kiến trúc MVP có khả năng tiến hóa

| ID | Bài viết |
|---|---|
| `KB-KGV-042` | [Xây kiến trúc mở rộng mà không triển khai trước chức năng tương lai](KB-KGV-042-kien-truc-mo-rong-va-ranh-gioi-mvp.md) |

## C12 — Chiết khấu mua hàng và định giá bán

| ID | Bài viết |
|---|---|
| `KB-KGV-043` | [Kịch bản chiết khấu mua hàng theo kỳ](KB-KGV-043-kich-ban-chiet-khau-mua-hang-theo-ky.md) |
| `KB-KGV-044` | [Từ giá vốn tham chiếu định giá đến giá bán giao dịch](KB-KGV-044-tu-gia-von-tham-chieu-den-gia-ban-giao-dich.md) |
| `KB-KGV-045` | [Rà soát giá vốn tham chiếu định giá sau chốt kỳ](KB-KGV-045-ra-soat-gia-von-tham-chieu-sau-chot-ky.md) |

## Quy ước kiểm soát

- Article ID là ổn định; thay đổi tiêu đề không làm đổi ID.
- Quyết định mới hơn thay thế nội dung cũ theo Hồ sơ chuyển đổi quyết định.
- Bài wiki không phải nguồn thay đổi tồn hoặc giá trị; Quyết định nghiệp vụ và SRS là tài liệu làm căn cứ triển khai.
- Thuật ngữ được chuẩn hóa tại `../glossary/glossary.md`.
