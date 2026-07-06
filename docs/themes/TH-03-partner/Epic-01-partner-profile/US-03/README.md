# US 03 - Bổ sung và chỉnh sửa thông tin đối tác

## User story

**Là** chủ cửa hàng,  
**Tôi muốn** bổ sung hoặc chỉnh sửa thông tin của khách hàng/NCC đã có trong hệ thống,  
**Để** hồ sơ đối tác luôn phản ánh đúng thông tin hiện tại mà không làm sai lệch các giao dịch đã phát sinh trước đó.

## User story context

US này tập trung vào việc bổ sung hoặc chỉnh sửa hồ sơ đối tác đã tồn tại trong hệ thống.

Trong quá trình vận hành, thông tin của khách hàng/NCC có thể thay đổi hoặc cần được bổ sung, ví dụ số điện thoại, email, địa chỉ, thông tin hóa đơn, mã số thuế hoặc ghi chú. Khi chỉnh sửa, hệ thống cần đảm bảo dữ liệu mới hợp lệ, không tạo trùng không kiểm soát, không làm sai lệch các giao dịch đã phát sinh và vẫn ghi nhận được lịch sử cập nhật.

US này xử lý việc mở form chỉnh sửa, rà soát thông tin hiện tại, bổ sung/chỉnh sửa thông tin hồ sơ, điều chỉnh vai trò đối tác, thay đổi loại hồ sơ khi cần, cảnh báo dữ liệu có khả năng trùng và hoàn tất lưu thay đổi. US này không xử lý thay đổi trạng thái ngừng hoạt động, kích hoạt lại, xóa hồ sơ hoặc xem lịch sử giao dịch chi tiết.

## Functional requirement map

| FR | Purpose | Main behavior | Key rules / Constraints | Output / Result |
|---|---|---|---|---|
| FR-1 - Bắt đầu bổ sung hoặc chỉnh sửa hồ sơ đối tác | Cho phép người dùng bắt đầu chỉnh sửa hồ sơ đối tác đã có | Hệ thống cho phép mở form bổ sung/chỉnh sửa từ hồ sơ chi tiết hoặc điểm điều hướng phù hợp | Chỉ người dùng đã đăng nhập và có quyền chỉnh sửa đối tác mới được thao tác; đối tác phải thuộc tenant hiện tại | Người dùng có thể bắt đầu chỉnh sửa hồ sơ hợp lệ |
| FR-2 - Rà soát thông tin hiện tại trước khi chỉnh sửa | Đảm bảo người dùng nhìn thấy dữ liệu hiện tại trước khi thay đổi | Hệ thống tải và hiển thị thông tin hiện tại của đối tác trên form chỉnh sửa | Dữ liệu hiển thị phải là dữ liệu mới nhất tại thời điểm mở form; nếu không tải được dữ liệu thì không cho tiếp tục chỉnh sửa | Người dùng có cơ sở để kiểm tra và chỉnh sửa đúng thông tin |
| FR-3 - Bổ sung hoặc chỉnh sửa thông tin hồ sơ | Cho phép cập nhật thông tin định danh, liên hệ, thuế, hóa đơn và ghi chú | Người dùng chỉnh sửa các trường được phép như tên, số điện thoại, email, địa chỉ, mã số thuế, thông tin hóa đơn và ghi chú | Tên đối tác và số điện thoại không được để trống sau khi chỉnh sửa; dữ liệu nhập phải đúng định dạng; không làm thay đổi snapshot giao dịch cũ | Hồ sơ đối tác được cập nhật thông tin mới cho các nghiệp vụ phát sinh sau này |
| FR-4 - Điều chỉnh vai trò đối tác | Cho phép cập nhật vai trò khi quan hệ với đối tác thay đổi | Người dùng có thể bổ sung hoặc điều chỉnh vai trò Khách hàng, Nhà cung cấp hoặc Khách hàng & Nhà cung cấp | Không được xóa vai trò đã phát sinh giao dịch; đối tác phải luôn còn ít nhất một vai trò hợp lệ | Vai trò đối tác được cập nhật đúng mà không làm mất liên kết dữ liệu đã phát sinh |
| FR-5 - Nhận biết dữ liệu có khả năng trùng khi chỉnh sửa | Giảm nguy cơ cập nhật thông tin trùng với hồ sơ khác | Hệ thống kiểm tra số điện thoại, email hoặc mã số thuế có khả năng trùng trong tenant hiện tại | Cảnh báo trùng dữ liệu không tự động chặn lưu nếu người dùng xác nhận tiếp tục; không kiểm tra trùng ngoài tenant | Người dùng được cảnh báo trước khi lưu thay đổi có khả năng gây trùng dữ liệu |
| FR-6 - Hoàn tất bổ sung hoặc chỉnh sửa hồ sơ đối tác | Ghi nhận thay đổi vào hồ sơ đối tác | Hệ thống lưu dữ liệu hợp lệ, cập nhật người chỉnh sửa gần nhất, thời điểm chỉnh sửa và audit log nếu cần | Không cập nhật một phần nếu lưu thất bại; không làm thay đổi dữ liệu giao dịch, hóa đơn, phiếu nhập hoặc chứng từ đã phát sinh trước đó | Hồ sơ đối tác được cập nhật thành công và có dữ liệu phục vụ truy vết |
| FR-7 - Thay đổi loại hồ sơ đối tác khi chỉnh sửa | Cho phép sửa loại hồ sơ khi hồ sơ ban đầu được ghi nhận chưa đúng | Người dùng có thể chuyển giữa Cá nhân và Tổ chức với cảnh báo và ánh xạ dữ liệu phù hợp | Hồ sơ sau chuyển đổi phải đủ dữ liệu bắt buộc; không làm thay đổi snapshot giao dịch đã phát sinh | Loại hồ sơ được cập nhật đúng mà không làm mất dữ liệu cần giữ lại |
