# US 01 - Tìm kiếm và rà soát danh sách đối tác

## User story

**Là** chủ cửa hàng,  
**Tôi muốn** tìm kiếm và rà soát danh sách khách hàng/NCC trong hệ thống,  
**Để** nhanh chóng xác định đối tác đã tồn tại hay chưa, kiểm tra thông tin cơ bản và tiếp tục thao tác phù hợp như ghi nhận mới, kiểm tra hồ sơ hoặc chỉnh sửa thông tin.

## User story context

US này tập trung vào bước người dùng rà soát danh sách đối tác trước khi quyết định thao tác tiếp theo. Đối tác trong phạm vi US này bao gồm khách hàng, nhà cung cấp và đối tác vừa là khách hàng vừa là nhà cung cấp.

Trong vận hành thực tế, người dùng thường cần kiểm tra nhanh xem một khách hàng/NCC đã có trong hệ thống hay chưa trước khi tạo mới, mở hồ sơ chi tiết hoặc chỉnh sửa thông tin. Nếu danh sách không hỗ trợ tìm kiếm, lọc và nhận diện rõ đối tác, hệ thống dễ phát sinh trùng hồ sơ, chọn sai đối tác hoặc mất thời gian kiểm tra thủ công.

US này xử lý việc mở danh sách đối tác, hiển thị thông tin tóm tắt, tìm kiếm, lọc, xử lý trạng thái không có dữ liệu và điều hướng sang thao tác tiếp theo. US này không xử lý việc ghi nhận mới, chỉnh sửa hồ sơ, thay đổi trạng thái hoặc xem lịch sử giao dịch chi tiết của đối tác.

## Functional requirement map

| FR | Purpose | Main behavior | Key rules / Constraints | Output / Result |
|---|---|---|---|---|
| FR-1 - Mở danh sách đối tác | Cho phép người dùng bắt đầu rà soát danh sách khách hàng/NCC | Hệ thống tải và hiển thị danh sách đối tác trong tenant hiện tại | Chỉ người dùng đã đăng nhập và có quyền xem đối tác mới được vào danh sách; danh sách chỉ hiển thị dữ liệu trong tenant hiện tại; mặc định ưu tiên hiển thị đối tác đang hoạt động | Người dùng nhìn thấy danh sách đối tác hợp lệ để rà soát |
| FR-2 - Tìm kiếm đối tác | Giúp người dùng nhanh chóng xác định đối tác đã tồn tại hay chưa | Hệ thống cho phép tìm kiếm đối tác theo các thông tin nhận diện như tên, số điện thoại, email hoặc mã số thuế | Tìm kiếm chỉ áp dụng trong phạm vi tenant hiện tại; kết quả phải phản ánh đúng dữ liệu phù hợp với từ khóa | Danh sách được thu hẹp theo từ khóa tìm kiếm |
| FR-3 - Lọc danh sách đối tác | Giúp người dùng thu hẹp danh sách theo nhu cầu kiểm tra | Hệ thống cho phép lọc danh sách theo loại đối tác, loại hồ sơ và trạng thái sử dụng | Bộ lọc có thể kết hợp với từ khóa tìm kiếm; đối tác ngưng hoạt động chỉ hiển thị khi người dùng chọn bộ lọc trạng thái phù hợp | Danh sách hiển thị đúng các đối tác phù hợp với điều kiện lọc |
| FR-4 - Xử lý khi không có dữ liệu phù hợp | Giúp người dùng hiểu vì sao danh sách không có kết quả | Hệ thống hiển thị trạng thái rỗng khi tenant chưa có đối tác, không tìm thấy theo từ khóa hoặc không có dữ liệu theo bộ lọc | Cần phân biệt rõ chưa có dữ liệu, không khớp từ khóa và không khớp bộ lọc; không hiển thị dữ liệu sai tenant | Người dùng hiểu lý do không có dữ liệu và biết có thể ghi nhận đối tác mới nếu có quyền |
| FR-5 - Điều hướng thao tác tiếp theo | Cho phép người dùng tiếp tục thao tác phù hợp sau khi rà soát danh sách | Hệ thống cho phép mở hồ sơ đối tác đã có hoặc bắt đầu ghi nhận đối tác mới nếu người dùng có quyền | Chỉ hiển thị hành động phù hợp với quyền người dùng và trạng thái dữ liệu; thao tác chi tiết được xử lý ở US tương ứng | Người dùng có thể đi tiếp sang kiểm tra hồ sơ, chỉnh sửa hoặc ghi nhận đối tác mới mà không bị đứt mạch thao tác |