# US 01 - Theo dõi lịch sử làm việc với đối tác

## User story

**Là** chủ cửa hàng,  
**Tôi muốn** xem lịch sử giao dịch đã phát sinh của một khách hàng,  
**Để** tra cứu các đơn hàng, hóa đơn, thanh toán hoặc công nợ liên quan khi cần đối soát, chăm sóc khách hàng hoặc xử lý thắc mắc.

## User story context

US này tập trung vào việc xem lịch sử làm việc/giao dịch đã phát sinh của một đối tác từ hồ sơ chi tiết đối tác.

Trong quá trình vận hành, người dùng thường cần kiểm tra lại một khách hàng/NCC đã từng phát sinh giao dịch gì, vào thời điểm nào, thuộc loại giao dịch nào và có liên quan đến đơn hàng, hóa đơn, thanh toán hoặc công nợ nào. Nếu không có điểm tra cứu tập trung theo đối tác, người dùng phải đi qua nhiều module khác nhau, mất thời gian và dễ bỏ sót thông tin.

US này xử lý việc mở lịch sử làm việc, hiển thị danh sách lịch sử, lọc/tìm kiếm lịch sử, mở chi tiết giao dịch nguồn và xử lý hiển thị lịch sử khi trạng thái đối tác thay đổi. US này chỉ phục vụ tra cứu và điều hướng, không cho chỉnh sửa, hủy hoặc xử lý nghiệp vụ giao dịch trực tiếp trong Theme Khách hàng & NCC.

## Functional requirement map

| FR | Purpose | Main behavior | Key rules / Constraints | Output / Result |
|---|---|---|---|---|
| FR-1 - Mở lịch sử làm việc của đối tác | Cho phép người dùng truy cập khu vực lịch sử từ hồ sơ đối tác | Hệ thống mở lịch sử làm việc từ hồ sơ chi tiết đối tác và tải dữ liệu mới nhất | Chỉ người dùng đã đăng nhập và có quyền xem lịch sử mới được mở; chỉ hiển thị lịch sử của đối tác trong tenant hiện tại | Người dùng mở được khu vực lịch sử làm việc của đúng đối tác |
| FR-2 - Hiển thị danh sách lịch sử làm việc | Giúp người dùng xem các giao dịch đã phát sinh với đối tác | Hệ thống hiển thị danh sách lịch sử theo các giao dịch liên quan đến đối tác | Lịch sử chỉ đọc; chỉ hiển thị dữ liệu tổng hợp/tóm tắt từ module nguồn; không cho sửa hoặc xử lý giao dịch tại Theme 3 | Người dùng xem được các giao dịch đã phát sinh với đối tác |
| FR-3 - Lọc và tìm kiếm trong lịch sử làm việc | Giúp người dùng nhanh chóng tìm đúng giao dịch cần kiểm tra | Hệ thống cho phép lọc/tìm kiếm lịch sử theo khoảng thời gian, loại giao dịch, trạng thái hoặc mã giao dịch nếu có | Bộ lọc và tìm kiếm chỉ áp dụng trên dữ liệu lịch sử của đúng đối tác và tenant hiện tại | Danh sách lịch sử được thu hẹp theo điều kiện người dùng chọn |
| FR-4 - Mở chi tiết giao dịch từ lịch sử | Cho phép người dùng truy vết từ lịch sử đối tác sang giao dịch nguồn | Hệ thống điều hướng từ một dòng lịch sử sang màn chi tiết giao dịch ở module nguồn | Chỉ mở được nếu người dùng có quyền xem giao dịch nguồn; dữ liệu chi tiết do module nguồn xử lý | Người dùng có thể kiểm tra sâu giao dịch liên quan mà không chỉnh sửa trực tiếp từ lịch sử đối tác |
| FR-5 - Xử lý lịch sử khi trạng thái đối tác thay đổi | Đảm bảo lịch sử vẫn truy vết được dù đối tác không còn hoạt động | Hệ thống vẫn hiển thị lịch sử của đối tác ngừng hoạt động nếu người dùng có quyền | Trạng thái đối tác không được làm mất lịch sử giao dịch đã phát sinh; nếu đối tác không tồn tại hoặc không thuộc tenant thì không hiển thị lịch sử | Người dùng vẫn tra cứu được lịch sử hợp lệ và hiểu trạng thái hiện tại của đối tác |