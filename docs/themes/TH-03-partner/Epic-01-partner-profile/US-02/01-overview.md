# US 02 - Ghi nhận đối tác mới

## User story

**Là** chủ cửa hàng,  
**Tôi muốn** ghi nhận khách hàng/NCC mới vào hệ thống,  
**Để** cửa hàng có hồ sơ đối tác rõ ràng, dùng được cho bán hàng, nhập hàng, hóa đơn và các nghiệp vụ quản lý liên quan.

## User story context

US này tập trung vào việc ghi nhận một hồ sơ đối tác mới từ module Khách hàng & NCC sau khi người dùng đã rà soát danh sách và xác định đối tác chưa có trong hệ thống.

Đối tác mới có thể là khách hàng, nhà cung cấp hoặc vừa là khách hàng vừa là nhà cung cấp. Khi ghi nhận đối tác, hệ thống cần đảm bảo người dùng xác định đúng vai trò, loại hồ sơ, thông tin nhận diện, thông tin liên hệ và thông tin phục vụ hóa đơn nếu có.

US này xử lý việc mở form ghi nhận đối tác mới, nhập thông tin, nhận biết dữ liệu có khả năng trùng và hoàn tất lưu hồ sơ đối tác mới. US này không xử lý luồng tạo nhanh khách hàng/NCC từ bán hàng, nhập hàng hoặc các nghiệp vụ khác.

## Functional requirement map

| FR | Purpose | Main behavior | Key rules / Constraints | Output / Result |
|---|---|---|---|---|
| FR-1 - Bắt đầu ghi nhận đối tác mới | Cho phép người dùng bắt đầu tạo hồ sơ đối tác mới từ module Khách hàng & NCC | Hệ thống hiển thị form ghi nhận đối tác mới khi người dùng có quyền phù hợp | Chỉ người dùng đã đăng nhập và có quyền ghi nhận đối tác mới được mở form; hệ thống chưa tạo hồ sơ cho đến khi lưu hợp lệ | Người dùng có thể bắt đầu nhập thông tin đối tác mới |
| FR-2 - Xác định vai trò và loại hồ sơ đối tác | Xác định đối tác là khách hàng, nhà cung cấp hoặc cả hai, và là cá nhân hay tổ chức | Người dùng chọn loại đối tác và loại hồ sơ trên form | Loại đối tác và loại hồ sơ là dữ liệu quan trọng để hệ thống hiểu cách sử dụng và hiển thị hồ sơ | Hệ thống xác định được vai trò và bản chất hồ sơ của đối tác mới |
| FR-3 - Nhập thông tin nhận diện đối tác | Ghi nhận thông tin tối thiểu để nhận diện và sử dụng đối tác trong vận hành | Người dùng nhập tên đối tác, số điện thoại và các thông tin nhận diện bắt buộc theo form | Không cho lưu nếu thiếu thông tin bắt buộc hoặc dữ liệu không hợp lệ | Hồ sơ có đủ thông tin nền để được kiểm tra trước khi lưu |
| FR-4 - Bổ sung thông tin hồ sơ | Cho phép người dùng nhập thêm thông tin liên hệ, thuế, hóa đơn và ghi chú nếu có | Người dùng có thể bổ sung email, địa chỉ, tên trên hóa đơn, mã số thuế, địa chỉ hóa đơn, email nhận hóa đơn và ghi chú | Các thông tin bổ sung không bắt buộc nếu không có rule điều kiện; nếu nhập thì phải đúng định dạng được hỗ trợ | Hồ sơ đối tác có thêm dữ liệu phục vụ liên hệ, hóa đơn và quản lý |
| FR-5 - Nhận biết dữ liệu có khả năng trùng | Giảm rủi ro tạo nhiều hồ sơ cho cùng một đối tác | Hệ thống kiểm tra và cảnh báo nếu số điện thoại, email hoặc mã số thuế có khả năng trùng với đối tác khác trong tenant | Cảnh báo trùng dữ liệu không tự động chặn lưu nếu người dùng xác nhận tiếp tục; kiểm tra trùng chỉ áp dụng trong tenant hiện tại | Người dùng được cảnh báo trước khi hoàn tất ghi nhận đối tác mới |
| FR-6 - Hoàn tất ghi nhận đối tác mới | Lưu hồ sơ đối tác mới thành dữ liệu chính thức trong hệ thống | Hệ thống lưu hồ sơ khi dữ liệu hợp lệ, ghi nhận trạng thái mặc định, người tạo và thời điểm tạo | Không tạo hồ sơ không hoàn chỉnh nếu lưu thất bại; thao tác lưu cần tránh xử lý trùng khi người dùng bấm nhiều lần | Hồ sơ đối tác mới được tạo thành công và có thể sử dụng theo trạng thái hợp lệ |