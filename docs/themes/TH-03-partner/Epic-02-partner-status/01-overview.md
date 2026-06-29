# US 02 - Loại bỏ hồ sơ đối tác tạo nhầm

## User story

**Là** chủ cửa hàng,  
**Tôi muốn** xóa những hồ sơ khách hàng/NCC được tạo nhầm và chưa phát sinh giao dịch,  
**Để** danh sách đối tác gọn gàng, tránh chọn nhầm hồ sơ sai trong quá trình vận hành.

## User story context

US này tập trung vào việc loại bỏ hồ sơ đối tác bị tạo nhầm, không còn giá trị sử dụng và chưa phát sinh dữ liệu nghiệp vụ.

Trong vận hành thực tế, người dùng có thể tạo nhầm khách hàng/NCC hoặc tạo hồ sơ trùng nhưng chưa sử dụng trong bất kỳ giao dịch nào. Những hồ sơ này nếu vẫn tồn tại trong danh sách sẽ làm người dùng dễ chọn nhầm, tạo dữ liệu rác và gây khó khăn khi rà soát danh sách đối tác.

US này xử lý việc bắt đầu xóa hồ sơ, kiểm tra điều kiện xóa, xác nhận xóa và ghi nhận kết quả xóa. US này không cho phép xóa hồ sơ đã phát sinh giao dịch, chứng từ, công nợ, hóa đơn hoặc dữ liệu liên quan; trong trường hợp đó, người dùng chỉ có thể ngừng hoạt động đối tác nếu cần.

## Functional requirement map

| FR | Purpose | Main behavior | Key rules / Constraints | Output / Result |
|---|---|---|---|---|
| FR-1 - Bắt đầu xóa hồ sơ đối tác | Cho phép người dùng bắt đầu thao tác xóa hồ sơ đối tác tạo nhầm | Hệ thống hiển thị hành động xóa từ hồ sơ chi tiết hoặc điểm thao tác phù hợp | Chỉ người dùng đã đăng nhập và có quyền xóa hồ sơ đối tác mới được thao tác; đối tác phải thuộc tenant hiện tại | Người dùng có thể bắt đầu thao tác xóa hồ sơ nếu có quyền |
| FR-2 - Kiểm tra điều kiện trước khi thay đổi trạng thái | Đảm bảo chỉ hồ sơ đủ điều kiện mới được xóa | Hệ thống tải dữ liệu mới nhất và kiểm tra đối tác đã phát sinh giao dịch hay chưa | Chỉ cho xóa hồ sơ chưa phát sinh giao dịch; không cho xóa hồ sơ đã liên quan đến đơn bán, phiếu nhập, công nợ, hóa đơn hoặc chứng từ | Hệ thống xác định hồ sơ có được phép xóa hay không |
| FR-3 - Xác nhận xóa hồ sơ đối tác | Giảm rủi ro người dùng xóa nhầm hồ sơ | Hệ thống hiển thị xác nhận trước khi thực hiện xóa hồ sơ | Nội dung xác nhận cần cho người dùng hiểu đây là thao tác ảnh hưởng đến hồ sơ đối tác; nếu người dùng hủy thì không thay đổi dữ liệu | Người dùng xác nhận rõ ràng trước khi hệ thống xóa hồ sơ |
| FR-4 - Ghi nhận kết quả xóa hồ sơ | Hoàn tất thao tác xóa và đảm bảo dữ liệu sau xóa nhất quán | Hệ thống cập nhật trạng thái/loại bỏ hồ sơ khỏi danh sách làm việc và ghi nhận thông tin thao tác nếu cần | Không được xóa nếu kiểm tra điều kiện thất bại; không được xóa dữ liệu ngoài tenant; không làm ảnh hưởng đến hồ sơ khác | Hồ sơ đối tác tạo nhầm được loại bỏ khỏi danh sách làm việc và kết quả thao tác được ghi nhận |