# US 01 - Dừng sử dụng và sử dụng lại đối tác

## User story

**Là** chủ cửa hàng,  
**Tôi muốn** ngừng hoạt động hoặc kích hoạt lại khách hàng/NCC,  
**Để** kiểm soát đối tác nào còn được dùng trong giao dịch mới mà vẫn giữ được hồ sơ và dữ liệu đã phát sinh trước đó.

## User story context

US này tập trung vào việc thay đổi trạng thái sử dụng của một hồ sơ đối tác đã tồn tại trong hệ thống.

Trong quá trình vận hành, có những khách hàng/NCC không còn giao dịch, tạm ngừng hợp tác hoặc chưa nên được sử dụng trong giao dịch mới. Tuy nhiên, nếu đối tác đã từng phát sinh giao dịch, hệ thống vẫn cần giữ hồ sơ và dữ liệu liên quan để phục vụ tra cứu, đối soát, hóa đơn, công nợ và lịch sử giao dịch.

US này xử lý việc ngừng hoạt động và kích hoạt lại đối tác. US này không xử lý việc xóa hồ sơ đối tác, không thay đổi dữ liệu giao dịch đã phát sinh và không xử lý chi tiết các nghiệp vụ nguồn như bán hàng, nhập hàng, công nợ hoặc hóa đơn.

## Functional requirement map

| FR | Purpose | Main behavior | Key rules / Constraints | Output / Result |
|---|---|---|---|---|
| FR-1 - Bắt đầu thay đổi trạng thái đối tác | Cho phép người dùng bắt đầu thao tác ngừng hoạt động hoặc kích hoạt lại đối tác | Hệ thống hiển thị hành động thay đổi trạng thái từ hồ sơ chi tiết hoặc điểm thao tác phù hợp | Chỉ người dùng đã đăng nhập và có quyền quản lý trạng thái đối tác mới được thao tác; đối tác phải thuộc tenant hiện tại | Người dùng nhìn thấy hành động phù hợp với trạng thái hiện tại của đối tác |
| FR-2 - Kiểm tra điều kiện trước khi thay đổi trạng thái | Đảm bảo thao tác thay đổi trạng thái được thực hiện trên dữ liệu hợp lệ và mới nhất | Hệ thống tải trạng thái mới nhất của đối tác và kiểm tra quyền, tenant, trạng thái hiện tại trước khi cho phép thao tác | Không cho thay đổi trạng thái nếu đối tác không tồn tại, không thuộc tenant hiện tại, đã bị xóa hoặc người dùng không có quyền | Hệ thống xác định được đối tác có đủ điều kiện thay đổi trạng thái hay không |
| FR-3 - Ngừng hoạt động đối tác | Cho phép đưa đối tác đang hoạt động sang trạng thái ngừng hoạt động | Hệ thống chuyển trạng thái đối tác từ Đang hoạt động sang Ngừng hoạt động sau khi người dùng xác nhận | Đối tác ngừng hoạt động không được sử dụng trong giao dịch mới; dữ liệu và lịch sử cũ vẫn được giữ lại để truy vết | Đối tác được ngừng hoạt động và không còn xuất hiện như lựa chọn hợp lệ cho giao dịch mới |
| FR-4 - Kích hoạt lại đối tác | Cho phép sử dụng lại đối tác đã ngừng hoạt động | Hệ thống chuyển trạng thái đối tác từ Ngừng hoạt động sang Đang hoạt động sau khi người dùng xác nhận | Chỉ áp dụng với đối tác đang ở trạng thái Ngừng hoạt động; không áp dụng với đối tác đã bị xóa | Đối tác được kích hoạt lại và có thể được sử dụng trong giao dịch mới theo quyền và điều kiện hợp lệ |
| FR-5 - Ghi nhận kết quả thay đổi trạng thái | Đảm bảo thao tác thay đổi trạng thái có thể truy vết | Hệ thống lưu trạng thái mới, người thực hiện, thời điểm thực hiện và audit log nếu cần | Không được cập nhật một phần nếu thao tác thất bại; thay đổi trạng thái không làm thay đổi dữ liệu giao dịch cũ | Trạng thái đối tác được cập nhật thành công và có dữ liệu phục vụ truy vết |