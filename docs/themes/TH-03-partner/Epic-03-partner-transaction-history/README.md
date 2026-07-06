## Epic 3.3: Theo dõi lịch sử giao dịch của đối tác

### Epic overview

Epic này tập trung vào việc hiển thị lịch sử giao dịch đã phát sinh liên quan đến một đối tác.

Trong VET45, hồ sơ đối tác là điểm truy xuất để người dùng kiểm tra lại các nghiệp vụ đã từng phát sinh với khách hàng hoặc nhà cung cấp. Một đối tác có thể có lịch sử mua hàng khi đóng vai trò Khách hàng, lịch sử nhập hàng khi đóng vai trò Nhà cung cấp, hoặc có cả hai nhóm lịch sử nếu đối tác có nhiều vai trò.

Epic này không tạo mới, chỉnh sửa hoặc lưu giao dịch gốc. Dữ liệu lịch sử giao dịch được hiển thị từ read model/projection do các module nghiệp vụ khác đẩy sang, ví dụ Bán hàng, Nhập hàng, Công nợ, Hóa đơn hoặc Kho.

Hệ thống cần phân biệt lịch sử theo vai trò giao dịch để tránh nhầm lẫn giữa dữ liệu khách hàng và dữ liệu nhà cung cấp.

### Business value

Epic này giúp người dùng có một điểm kiểm tra tập trung khi cần xem lại quan hệ giao dịch với một đối tác.

Chủ cửa hàng có thể nắm tổng quan đối tác đã từng phát sinh gì. Nhân viên bán hàng có thể hỗ trợ khách khi cần tra cứu đơn cũ. Kế toán có thể đối chiếu công nợ, hóa đơn hoặc thanh toán. Thủ kho có thể kiểm tra lịch sử nhập hàng từ nhà cung cấp.

Việc sử dụng read model/projection giúp Theme 3 không bị phụ thuộc trực tiếp vào query realtime từ nhiều module khác, đồng thời vẫn cung cấp trải nghiệm tra cứu tập trung cho người dùng.

### User roles

| Role | Permission / Involvement |
|---|---|
| Chủ cửa hàng | Xem lịch sử giao dịch tổng hợp theo đối tác để nắm quan hệ giao dịch và kiểm soát vận hành. |
| Kế toán | Xem lịch sử liên quan đến công nợ, hóa đơn, thanh toán hoặc chứng từ để đối soát. |
| Nhân viên bán hàng | Xem lịch sử mua hàng, đơn hàng hoặc đổi/trả của khách hàng nếu được phân quyền. |
| Thủ kho | Xem lịch sử nhập hàng hoặc giao dịch với nhà cung cấp nếu được phân quyền. |

### User stories

| User story | User story name | Mục tiêu |
|---|---|---|
| US-3.3.1 | Xem lịch sử giao dịch của đối tác | Giúp người dùng kiểm tra các giao dịch đã phát sinh với đối tác theo vai trò Khách hàng hoặc Nhà cung cấp. |