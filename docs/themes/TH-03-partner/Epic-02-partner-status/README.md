## Epic 3.2: Quản lý trạng thái và vòng đời đối tác

### Epic overview

Epic này tập trung vào việc quản lý trạng thái sử dụng và vòng đời của hồ sơ đối tác sau khi đã được tạo trong hệ thống.

Trong VET45, một đối tác có thể đang hoạt động, tạm ngừng giao dịch hoặc không còn được phép sử dụng trong giao dịch mới. Tuy nhiên, nếu đối tác đã từng phát sinh dữ liệu nghiệp vụ, hệ thống cần giữ hồ sơ để đảm bảo lịch sử giao dịch, chứng từ, công nợ và audit log vẫn có thể truy vết được.

Epic này bao gồm các nghiệp vụ như ngừng hoạt động đối tác, kích hoạt lại đối tác và xóa đối tác khi đủ điều kiện.

Trạng thái sử dụng của đối tác chỉ gồm:

- Đang hoạt động
- Ngừng hoạt động

Không sử dụng trạng thái Đã xóa trong nghiệp vụ. Xóa là thao tác loại bỏ hồ sơ khỏi database và chỉ được phép khi đối tác chưa phát sinh dữ liệu nghiệp vụ.

### Business value

Epic này giúp cửa hàng kiểm soát đối tác nào còn được sử dụng trong giao dịch mới, đồng thời vẫn giữ được dữ liệu lịch sử đối với các đối tác đã từng phát sinh nghiệp vụ.

Việc phân biệt rõ Ngừng hoạt động và Xóa giúp hệ thống tránh mất dữ liệu quan trọng, tránh sai lệch lịch sử giao dịch, đồng thời giúp người dùng dọn dẹp các hồ sơ tạo nhầm hoặc chưa từng sử dụng.

### User roles

| Role | Permission / Involvement |
|---|---|
| Chủ cửa hàng | Có quyền ngừng hoạt động, kích hoạt lại hoặc xóa đối tác nếu đủ điều kiện. |
| Kế toán | Cần xem trạng thái đối tác và lịch sử liên quan để đảm bảo không ảnh hưởng công nợ, hóa đơn hoặc chứng từ. |
| Nhân viên bán hàng | Chỉ sử dụng được đối tác Đang hoạt động trong giao dịch mới; vẫn có thể xem hồ sơ Ngừng hoạt động nếu được phân quyền. |
| Thủ kho | Chỉ sử dụng được nhà cung cấp Đang hoạt động trong nghiệp vụ nhập hàng nếu được phân quyền. |

### User stories

| User story | User story name | Mục tiêu |
|---|---|---|
| US-3.2.1 | Ngừng hoạt động và kích hoạt lại đối tác | Giúp người dùng kiểm soát đối tác có còn được sử dụng trong giao dịch mới hay không. |
| US-3.2.2 | Xóa đối tác đủ điều kiện | Giúp người dùng xóa hồ sơ tạo nhầm hoặc chưa từng phát sinh nghiệp vụ. |