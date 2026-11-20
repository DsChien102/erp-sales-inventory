# Epic 2.2: Tạo sản phẩm theo hành trình có hướng dẫn

## Epic overview

Epic này giúp người dùng tạo sản phẩm mới theo một flow có hướng dẫn, thay vì phải xử lý tất cả field trong một form lớn. Mục tiêu là cho phép tạo hồ sơ sản phẩm tối thiểu trước, sau đó dẫn người dùng hoàn thiện các dữ liệu vận hành như ảnh, đơn vị cơ sở, tồn kho, Giá cơ sở định giá, khung giá bán và thông tin bổ sung.

Vai trò người dùng chính gồm chủ cửa hàng và nhân viên được phân quyền tạo sản phẩm. Người dùng không cần hiểu đầy đủ toàn bộ mô hình dữ liệu ngay từ đầu; hệ thống phải dẫn dắt họ theo đúng thứ tự nghiệp vụ.

Flow tạo sản phẩm cần ưu tiên mobile-first và không làm người dùng bị quá tải. Hệ thống nên cho phép tạo nhanh sản phẩm tối thiểu, nhưng sau đó phải cho biết sản phẩm còn thiếu gì để sẵn sàng nhập hàng, bán hàng hoặc quản trị.

---

## User stories

| US | Tên | Folder | FR | Status |
| -- | --- | ------ | -- | ------ |
| US-01 | Ghi nhận sản phẩm mới theo flow tạo tối thiểu | [US-01/](US-01/) | 4 | in_scope |
| US-02 | Thiết lập dữ liệu vận hành ban đầu khi tạo sản phẩm | [US-02/](US-02/) | 4 | in_scope |
| US-03 | Hoàn tất tạo sản phẩm và dẫn người dùng sang bước tiếp theo | [US-03/](US-03/) | 4 | in_scope |

Theme index: [README.md](../README.md)
