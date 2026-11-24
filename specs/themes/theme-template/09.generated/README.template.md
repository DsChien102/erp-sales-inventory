# generated/

Thư mục này **không có template nội dung để biên tập bằng tay**.

Mọi file trong `generated/` phải:

- được sinh tự động từ nguồn chuẩn;
- deterministic: cùng đầu vào sinh cùng đầu ra;
- read-only đối với người dùng;
- có link/ID quay về nguồn;
- có thể xóa và sinh lại mà không mất thông tin gốc.

Các nhóm điển hình:

- `registries/` — danh mục artifact/slice/interface;
- `matrices/` — ma trận truy vết/coverage/dependency;
- `indexes/` — index phục vụ tìm kiếm/điều hướng.
