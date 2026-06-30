# Epic-02 — Quản lý trạng thái đối tác

## Epic overview

Epic này kiểm soát việc ngừng hoạt động, kích hoạt lại và loại bỏ hồ sơ đối tác tạo nhầm theo điều kiện dữ liệu đã phát sinh.

Trong vận hành, đối tác có thể tạm ngừng hợp tác hoặc bị tạo nhầm. Epic này đảm bảo thay đổi trạng thái không làm mất dữ liệu giao dịch đã phát sinh, và chỉ cho xóa hồ sơ khi chưa có giao dịch liên quan.

Epic này **không** xử lý chỉnh sửa hồ sơ (Epic-01), **không** xử lý lịch sử giao dịch (Epic-03).

## User stories

| US | Tên | Folder |
| -- | --- | ------ |
| US-01 | Dừng sử dụng và sử dụng lại đối tác | [US-01/](US-01/) |
| US-02 | Loại bỏ hồ sơ đối tác tạo nhầm | [US-02/](US-02/) |

## Out of scope

- Cập nhật thông tin hồ sơ (Epic-01/US-03)
- Xem lịch sử giao dịch (Epic-03)
- Xử lý đơn bán, phiếu nhập, công nợ, hóa đơn
