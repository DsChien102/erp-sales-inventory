# TH-03 — Business scope

### Purpose

Theme Khách hàng & NCC giúp người dùng quản lý hồ sơ đối tác trong hệ thống, bao gồm khách hàng, nhà cung cấp và đối tác vừa là khách hàng vừa là nhà cung cấp.

Theme này chuẩn hóa dữ liệu đối tác như thông tin định danh, thông tin liên hệ, thông tin thuế, vai trò, trạng thái và lịch sử liên quan, để phục vụ các nghiệp vụ bán hàng, nhập hàng, hóa đơn, công nợ, tra cứu lịch sử giao dịch và quản lý vận hành.

### Business context

Trong thực tế vận hành của hộ kinh doanh và doanh nghiệp thương mại nhỏ, cùng một cá nhân hoặc tổ chức có thể vừa mua hàng từ cửa hàng, vừa cung cấp hàng hóa cho cửa hàng. Nếu quản lý khách hàng và nhà cung cấp tách rời hoàn toàn, dữ liệu dễ bị trùng lặp, khó đối soát lịch sử giao dịch và khó kiểm soát công nợ theo từng vai trò.

Theme Khách hàng & NCC đóng vai trò là nguồn dữ liệu đối tác thống nhất cho VET45. Từ một hồ sơ đối tác, hệ thống có thể xác định đối tác đang tham gia với vai trò khách hàng, nhà cung cấp hoặc cả hai, đồng thời vẫn giữ được dữ liệu lịch sử, chứng từ và trạng thái xử lý theo từng nghiệp vụ phát sinh.

Theme này giúp VET45 tạo nền tảng dữ liệu sạch cho các module khác như Bán hàng & Đơn hàng, Nhập hàng, Công nợ, Hóa đơn điện tử, Ghi sổ và Báo cáo. Đây là một phần quan trọng trong định hướng xây dựng luồng dữ liệu xuyên suốt từ vận hành thực tế đến tuân thủ và quản trị.

### Scope

Theme này bao gồm các nghiệp vụ chính sau:

- Tạo mới hồ sơ đối tác từ màn quản lý Khách hàng & NCC.
- Tạo nhanh hồ sơ đối tác từ các luồng nghiệp vụ khác như bán hàng hoặc nhập hàng, nếu module gọi có nhu cầu.
- Cập nhật thông tin hồ sơ đối tác.
- Quản lý loại đối tác gồm Khách hàng, Nhà cung cấp, hoặc Khách hàng & Nhà cung cấp.
- Quản lý loại hồ sơ gồm Cá nhân hoặc Tổ chức.
- Quản lý thông tin cơ bản của đối tác như tên đối tác, số điện thoại, email, địa chỉ, mã số thuế và ghi chú.
- Cảnh báo dữ liệu có khả năng bị trùng như số điện thoại, email hoặc mã số thuế.
- Cảnh báo khi đối tác tổ chức thiếu mã số thuế nhưng không chặn lưu nếu nghiệp vụ cho phép.
- Tra cứu danh sách đối tác.
- Tìm kiếm đối tác theo tên, số điện thoại, email, mã số thuế hoặc thông tin định danh phù hợp.
- Lọc danh sách đối tác theo loại đối tác, loại hồ sơ và trạng thái.
- Xem chi tiết hồ sơ đối tác.
- Quản lý trạng thái đối tác gồm Đang hoạt động, Ngừng hoạt động và Đã xóa mềm.
- Ngừng hoạt động đối tác để không cho phép dùng trong giao dịch mới.
- Kích hoạt lại đối tác đã ngừng hoạt động.
- Xóa mềm đối tác theo điều kiện hợp lệ.
- Xem lịch sử giao dịch liên quan đến đối tác theo vai trò Khách hàng hoặc Nhà cung cấp.
- Kiểm soát quyền truy cập và thao tác với dữ liệu đối tác theo tenant hiện tại.
- Ghi nhận thông tin người tạo, thời điểm tạo, người cập nhật gần nhất và thời điểm cập nhật gần nhất.
- Ghi nhận audit log cho các thay đổi quan trọng của hồ sơ đối tác.

### Out of scope

Các nội dung sau không nằm trong phạm vi xử lý chính của Theme Khách hàng & NCC:

- Tạo đơn bán hàng, chỉnh sửa đơn bán hàng hoặc xử lý thanh toán đơn hàng.
- Tạo phiếu nhập hàng, xử lý nhập kho hoặc thanh toán cho nhà cung cấp.
- Chọn và áp dụng đối tác vào một đơn bán, phiếu nhập hoặc chứng từ cụ thể; phần này thuộc phạm vi của module nghiệp vụ đang gọi.
- Tính toán, ghi nhận và xử lý công nợ chi tiết phát sinh từ bán hàng, nhập hàng, trả hàng, hoàn tiền hoặc cấn trừ.
- Phát hành, ký số, gửi email hoặc xử lý lỗi hóa đơn điện tử.
- Quản lý danh mục sản phẩm, giá bán, tồn kho hoặc giá vốn.
- Quản lý phân quyền chi tiết hoặc cho phép chủ cửa hàng tự cấu hình ma trận quyền nâng cao.
- Báo cáo phân tích khách hàng, phân nhóm khách hàng, chấm điểm khách hàng hoặc CRM nâng cao.
- Quản lý chương trình chăm sóc khách hàng, loyalty, khuyến mãi hoặc chiến dịch marketing.
- Import hàng loạt khách hàng/NCC nếu chưa được định nghĩa trong theme hoặc US riêng.
- Tích hợp với hệ thống CRM, kế toán, nhà cung cấp hoặc cổng đối tác bên ngoài.

## Epic map

| Epic | Mô tả | Folder |
| ---- | ----- | ------ |
| Epic 01 - Quản lý danh sách và hồ sơ đối tác | Quản lý hồ sơ gốc của đối tác, bao gồm tra cứu danh sách, ghi nhận đối tác mới, bổ sung/chỉnh sửa thông tin và kiểm tra hồ sơ chi tiết. | [Epic-01-partner-profile/](Epic-01-partner-profile/) |
| Epic 02 - Quản lý trạng thái đối tác | Kiểm soát việc ngừng hoạt động, kích hoạt lại và loại bỏ hồ sơ đối tác tạo nhầm theo điều kiện dữ liệu đã phát sinh. | [Epic-02-partner-status/](Epic-02-partner-status/) |
| Epic 03 - Theo dõi lịch sử giao dịch của đối tác | Cho phép xem lịch sử làm việc/giao dịch đã phát sinh với đối tác, hỗ trợ lọc, tìm kiếm và mở chi tiết giao dịch nguồn khi cần. | [Epic-03-partner-transaction-history/](Epic-03-partner-transaction-history/) |

Harness engineering: [harness/](harness/) · Index: [README.md](README.md)