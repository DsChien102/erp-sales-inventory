## Epic 3.1: Quản lý danh sách và hồ sơ đối tác

### Epic overview

Epic này tập trung vào việc quản lý hồ sơ đối tác trong VET45, bao gồm khách hàng, nhà cung cấp hoặc một đối tác có cả hai vai trò.

Trong phạm vi Epic này, hệ thống quản lý một hồ sơ Business Partner duy nhất trong tenant. Vai trò Khách hàng và Nhà cung cấp chỉ thể hiện cách đối tác được sử dụng trong nghiệp vụ, không tạo ra nhiều hồ sơ riêng cho cùng một đối tác.

Epic này bao gồm các nghiệp vụ chính như tra cứu danh sách đối tác, ghi nhận hồ sơ mới, xem chi tiết hồ sơ, cập nhật thông tin, thay đổi vai trò đối tác và thay đổi loại hồ sơ giữa Cá nhân và Tổ chức.

Hồ sơ đối tác được phân thành hai loại chính:

- Cá nhân
- Tổ chức

Hồ sơ Tổ chức bao gồm Công ty và Hộ kinh doanh. Trong MVP, Công ty và Hộ kinh doanh không được tách thành hai loại hồ sơ riêng, mà cùng sử dụng cấu trúc hồ sơ Tổ chức.

Epic này cũng chuẩn hóa bộ thông tin của đối tác gồm thông tin nhận diện, thông tin liên hệ, thông tin người liên hệ, địa chỉ, thông tin xuất hóa đơn, mã số thuế, trạng thái và ghi chú nội bộ.

### Business value

Epic này giúp cửa hàng chuẩn hóa dữ liệu khách hàng và nhà cung cấp ngay từ gốc, tránh việc cùng một đối tác bị tạo nhiều hồ sơ khác nhau trong hệ thống.

Khi dữ liệu đối tác được quản lý thống nhất, các module khác như Bán hàng, Nhập hàng, Công nợ, Hóa đơn điện tử, Kho và Báo cáo có thể cùng tham chiếu một nguồn dữ liệu nhất quán. Điều này giúp giảm sai sót khi lập giao dịch, dễ tra cứu lịch sử, dễ đối soát công nợ và hỗ trợ dữ liệu hóa đơn khi cần.

### User roles

| Role | Permission / Involvement |
|---|---|
| Chủ cửa hàng | Có toàn quyền xem, tạo, cập nhật, đổi vai trò, đổi loại hồ sơ và kiểm tra thông tin đối tác. |
| Kế toán | Xem và cập nhật thông tin đối tác phục vụ công nợ, hóa đơn, chứng từ và đối soát. |
| Nhân viên bán hàng | Xem, tìm kiếm, ghi nhận hoặc cập nhật thông tin khách hàng phục vụ bán hàng. |
| Thủ kho | Xem thông tin nhà cung cấp liên quan đến nghiệp vụ nhập hàng nếu được phân quyền. |

### User stories

| User story | User story name | Mục tiêu |
|---|---|---|
| US-3.1.1 | Tìm kiếm và rà soát danh sách đối tác | Giúp người dùng tìm nhanh đúng khách hàng/NCC cần kiểm tra hoặc sử dụng. |
| US-3.1.2 | Ghi nhận đối tác mới | Giúp người dùng tạo hồ sơ đối tác mới theo vai trò và loại hồ sơ phù hợp. |
| US-3.1.3 | Bổ sung và chỉnh sửa hồ sơ đối tác | Giúp người dùng cập nhật thông tin, vai trò và loại hồ sơ của đối tác khi dữ liệu thay đổi. |
| US-3.1.4 | Kiểm tra hồ sơ đối tác | Giúp người dùng xem chi tiết thông tin hồ sơ đối tác theo loại hồ sơ hiện tại. |