# US 04 - Kiểm tra hồ sơ đối tác

## User story

**Là** chủ cửa hàng,  
**Tôi muốn** kiểm tra hồ sơ chi tiết của một khách hàng/NCC,  
**Để** nắm được đầy đủ thông tin nhận diện, vai trò, liên hệ, thuế và trạng thái sử dụng trước khi tiếp tục làm việc với đối tác đó.

## User story context

US này tập trung vào việc xem và kiểm tra hồ sơ chi tiết của một đối tác đã tồn tại trong hệ thống.

Sau khi tìm thấy đối tác trên danh sách, người dùng cần mở hồ sơ để kiểm tra thông tin đầy đủ trước khi quyết định thao tác tiếp theo như bổ sung/chỉnh sửa, ngừng hoạt động, kích hoạt lại, xóa nếu đủ điều kiện hoặc xem lịch sử liên quan. Hồ sơ chi tiết cần giúp người dùng hiểu đối tác là ai, thuộc vai trò nào, có thông tin liên hệ/thuế gì, đang ở trạng thái nào và có thông tin hệ thống nào phục vụ truy vết.

US này chỉ xử lý việc mở và kiểm tra hồ sơ đối tác. US này không xử lý chỉnh sửa dữ liệu, thay đổi trạng thái, xóa hồ sơ, chọn đối tác vào giao dịch mới hoặc xử lý lịch sử giao dịch chi tiết.

## Functional requirement map

| FR | Purpose | Main behavior | Key rules / Constraints | Output / Result |
|---|---|---|---|---|
| FR-1 - Mở hồ sơ đối tác | Cho phép người dùng truy cập hồ sơ chi tiết của đối tác | Hệ thống mở hồ sơ từ danh sách đối tác hoặc điểm điều hướng phù hợp trong module Khách hàng & NCC | Chỉ người dùng đã đăng nhập và có quyền xem chi tiết đối tác mới được mở hồ sơ; đối tác phải thuộc tenant hiện tại | Người dùng mở được hồ sơ đối tác hợp lệ |
| FR-2 - Kiểm tra thông tin nhận diện và vai trò đối tác | Giúp người dùng xác định đúng đối tác và vai trò của đối tác | Hệ thống hiển thị tên đối tác, loại đối tác, loại hồ sơ và các thông tin nhận diện chính | Với đối tác có nhiều vai trò, hệ thống phải thể hiện rõ Khách hàng & Nhà cung cấp | Người dùng nhận diện đúng đối tác và hiểu đối tác đang đóng vai trò nào |
| FR-3 - Kiểm tra thông tin liên hệ | Giúp người dùng kiểm tra thông tin liên hệ, thuế, hóa đơn và ghi chú của đối tác | Hệ thống hiển thị số điện thoại, email, địa chỉ, mã số thuế, thông tin hóa đơn và ghi chú nếu có | Trường không có dữ liệu cần hiển thị phù hợp, không làm vỡ bố cục; việc bổ sung/chỉnh sửa thuộc US khác | Người dùng xem được đầy đủ thông tin hồ sơ hiện có |
| FR-4 - Kiểm tra trạng thái sử dụng và thông tin hệ thống | Giúp người dùng biết đối tác còn được sử dụng hay không và dữ liệu có thể truy vết thế nào | Hệ thống hiển thị trạng thái hiện tại, người tạo, thời điểm tạo, người cập nhật gần nhất và thời điểm cập nhật gần nhất nếu có | Việc xem trạng thái không được làm thay đổi dữ liệu; thay đổi trạng thái thuộc US quản lý trạng thái | Người dùng hiểu trạng thái sử dụng và thông tin truy vết của hồ sơ |
| FR-5 - Tiếp tục thao tác từ hồ sơ đối tác | Giúp người dùng đi tiếp sang thao tác phù hợp sau khi kiểm tra hồ sơ | Hệ thống hiển thị các hành động phù hợp như quay lại danh sách, bổ sung/chỉnh sửa, ngừng hoạt động, kích hoạt lại, xóa nếu đủ điều kiện hoặc xem lịch sử liên quan | Hành động phải phù hợp với quyền người dùng, trạng thái hiện tại và lịch sử phát sinh của đối tác; thao tác chi tiết xử lý ở US tương ứng | Người dùng có thể tiếp tục xử lý đúng luồng mà không nhầm phạm vi nghiệp vụ |