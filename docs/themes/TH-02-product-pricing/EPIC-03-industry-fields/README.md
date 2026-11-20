# Epic 2.3: Thông tin bổ sung của sản phẩm

## Epic overview

Epic này cho phép tenant cấu hình, ghi nhận, hiển thị, tìm kiếm và lọc **thông tin bổ sung của sản phẩm** thông qua mô hình **Nhóm thông tin** và **Trường thông tin**.

Trong Theme 2, các thông tin bổ sung không được hard-code vào Product. Hệ thống cần cho phép tenant tự cấu hình nhóm, trường, thuộc tính và thứ tự hiển thị để phù hợp với cách vận hành thực tế.

Ngành kinh doanh chỉ đóng vai trò là **template khởi tạo ban đầu** nếu có. Sau khi khởi tạo, tenant có thể điều chỉnh nhóm, trường, thứ tự hiển thị và thuộc tính của từng trường.

**Mục tiêu**

|**Mục tiêu**|**Diễn giải**|
|---|---|
|**Linh hoạt dữ liệu sản phẩm**|Cho phép tenant bổ sung thông tin sản phẩm mà không thay đổi Product lõi.|
|**Tổ chức thông tin rõ ràng**|Gom các trường liên quan vào nhóm để dễ nhập, xem và quản lý.|
|**Kiểm soát readiness**|Field bắt buộc có thể tham gia readiness của sản phẩm.|
|**Hỗ trợ tìm kiếm và lọc**|Một số field có thể được cấu hình để tìm kiếm hoặc lọc sản phẩm.|
|**Kiểm soát hiển thị**|Một số field có thể hiển thị trên danh sách sản phẩm.|
|**Bảo toàn dữ liệu cũ**|Thay đổi cấu hình nhóm hoặc field không được làm mất dữ liệu đã nhập.|

**Phạm vi**

|**Trong phạm vi**|**Ngoài phạm vi**|
|---|---|
|Khởi tạo nhóm và trường từ template nếu có.|Field công thức.|
|Tạo, sửa, tạm tắt nhóm thông tin.|Field phụ thuộc điều kiện.|
|Tạo, sửa, tạm tắt trường thông tin.|Permission riêng cho từng field.|
|Cấu hình thuộc tính field.|Workflow phê duyệt thay đổi field.|
|Sắp xếp thứ tự nhóm và field.|Import/export cấu hình field.|
|Nhập giá trị field theo sản phẩm.|Versioning phức tạp của field.|
|Tìm kiếm, lọc và hiển thị field được cấu hình.|Báo cáo phân tích chuyên sâu theo field.|

**Khái niệm chính**

|**Khái niệm**|**Diễn giải**|
|---|---|
|**Nhóm thông tin**<br>|Nhóm các trường thông tin bổ sung có liên quan với nhau.|
|**Trường thông tin**|Một field cấu hình được, dùng để bổ sung dữ liệu cho sản phẩm.|
|**Giá trị trường thông tin**|Dữ liệu cụ thể của một field trên một sản phẩm.|
|**Template khởi tạo**|Bộ nhóm và field gợi ý theo ngành hoặc mô hình kinh doanh.|
|**Thứ tự hiển thị**|Thứ tự nhóm và field do admin tenant cấu hình.|
|**Thuộc tính field**|Các cờ như required, searchable, filterable, display on list.|

---

## User stories

| US | Tên | Folder | FR | Status |
| -- | --- | ------ | -- | ------ |
| US-01 | Cấu hình nhóm và trường thông tin sản phẩm | [US-01/](US-01/) | 6 | in_scope |
| US-02 | Ghi nhận thông tin bổ sung theo từng sản phẩm | [US-02/](US-02/) | 4 | in_scope |
| US-03 | Tìm kiếm, lọc và hiển thị thông tin bổ sung | [US-03/](US-03/) | 4 | in_scope |

Theme index: [README.md](../README.md)
