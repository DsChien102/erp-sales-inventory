# Epic-01- Partner Profile

## Epic overview

Epic này quản lý hồ sơ gốc của đối tác trong hệ thống, bao gồm khách hàng, nhà cung cấp và đối tác vừa là khách hàng vừa là nhà cung cấp. Đây là lớp dữ liệu nền giúp hệ thống biết đối tác là ai, thuộc vai trò nào, có thông tin liên hệ nào, có thông tin thuế hay chưa và có thể được sử dụng trong các nghiệp vụ nào.

Giá trị chính của epic này là tạo ra một nguồn dữ liệu đối tác đủ tin cậy cho các module khác như bán hàng, nhập hàng, công nợ, hóa đơn và lịch sử giao dịch. Khi hồ sơ đối tác được chuẩn hóa từ đầu, hệ thống hạn chế được các lỗi như tạo trùng khách hàng/NCC, chọn sai đối tác khi lập chứng từ, thiếu thông tin xuất hóa đơn hoặc khó đối chiếu công nợ sau này.

Phạm vi của epic tập trung vào tạo mới và cập nhật hồ sơ đối tác, bao gồm loại đối tác, loại hồ sơ, thông tin liên hệ, thông tin thuế, ghi chú, cảnh báo trùng dữ liệu và ghi nhận thông tin tạo/cập nhật. Epic này không xử lý chi tiết giao dịch phát sinh như đơn bán, phiếu nhập, thanh toán, công nợ hoặc phát hành hóa đơn.

## User roles

| Role | Role definition | Role intent in this epic | | ---- | --------------- | ------------------------ | | Chủ cửa hàng | Người chịu trách nhiệm cao nhất về dữ liệu vận hành và chất lượng quản lý của cửa hàng. | Cần hồ sơ đối tác được quản lý thống nhất để hạn chế trùng dữ liệu, sai công nợ, thiếu thông tin hóa đơn hoặc khó kiểm tra lịch sử giao dịch. | | Quản lý cửa hàng | Người theo dõi vận hành hằng ngày và hỗ trợ kiểm soát dữ liệu khách hàng/NCC trong quá trình làm việc. | Cần tạo, kiểm tra và cập nhật hồ sơ đối tác để dữ liệu sử dụng trong bán hàng, nhập hàng và đối soát luôn đúng với thực tế. | | Nhân viên bán hàng | Người trực tiếp lập đơn, chọn khách hàng và xử lý giao dịch bán tại cửa hàng. | Cần nhận diện đúng khách hàng hoặc tạo nhanh hồ sơ tối thiểu để tiếp tục bán hàng mà không làm gián đoạn luồng giao dịch. | | Nhân viên nhập hàng / kho | Người ghi nhận hàng nhập và làm việc với nhà cung cấp trong quá trình nhập hàng. | Cần chọn đúng nhà cung cấp để phiếu nhập, lịch sử nhập hàng và công nợ phải trả gắn đúng đối tác. | | Kế toán | Người kiểm tra dữ liệu phục vụ hóa đơn, công nợ, chứng từ và đối soát giao dịch. | Cần thông tin đối tác đủ tin cậy để kiểm tra chứng từ, xuất hóa đơn, theo dõi công nợ và truy vết khi có sai lệch. |
