# Inventory

Tồn kho vật lý và các nghiệp vụ kho (nhận, lấy, trả, kiểm kê, phục hồi) của Theme 07. Thuật ngữ gốc nằm tại glossary của theme; file này chỉ ghi các thuật ngữ đã được làm rõ thêm khi thiết kế.

## Cửa hàng và kho

**Cửa hàng**:
Bối cảnh thương mại của một tenant, nơi ghi nhận giao dịch bán và phục vụ khách.
*Avoid*: Kho, tenant

**Tên cửa hàng**:
Tên gọi của cửa hàng, chốt lúc cặp mặc định được ghi. Lấy từ tên hiển thị của tenant tại thời điểm đó; nếu tenant chưa có tên hiển thị thì tên cửa hàng là «Cửa hàng».
*Avoid*: Tên pháp lý, tên chạy theo hồ sơ tenant

**Kho**:
Nơi một tenant chịu trách nhiệm số lượng và trạng thái hàng vật lý.
*Avoid*: Cửa hàng, vị trí người dùng

**Kho mặc định**:
Kho duy nhất của tenant. Tên hiển thị của kho này là «Kho mặc định».
*Avoid*: Cờ mặc định, kho được chọn, Kho chính

**Cặp mặc định**:
Cửa hàng duy nhất, kho mặc định, và quan hệ gán giữa hai bên của một tenant.
*Avoid*: Hằng số định danh, bộ chọn kho, cờ default

**Gán cửa hàng–kho**:
Quan hệ cho phép một cửa hàng dùng một kho.
*Avoid*: Chuyển kho

## Nhận hàng mua

**Chứng từ nguồn**:
Chứng từ mua do Theme 10 sở hữu (ví dụ đơn mua hàng) cho biết đơn vị được phép nhận hàng gì, của nhà cung cấp nào; Theme 7 chỉ đọc, không sửa.
*Avoid*: Chứng từ nhận, phiếu nhập, PO khi nói về khái niệm chung

**Dòng chứng từ** (source line):
Một dòng sản phẩm trên chứng từ nguồn, có version; là đơn vị mà các lần nhận hàng đối chiếu tới.
*Avoid*: Dòng đơn, order line

**Phiếu nhận hàng** (`GoodsReceipt`):
Hồ sơ của Theme 7 ghi một lần giao hàng thực tế của **một** nhà cung cấp, gồm nhiều mục hàng; một dòng chứng từ có thể được nhận qua nhiều phiếu nhận hàng. Là một hồ sơ riêng, không phải một loại của một "lệnh kho" chung.
*Avoid*: Chứng từ (khi ý là phiếu nhận), phiếu nhập kho, `InventoryOperation` như khái niệm chung chứa mọi loại lệnh kho

**Phiếu nhận hàng nhanh** (Quick Receipt):
Phiếu nhận hàng lập khi chưa có chứng từ nguồn phù hợp; luôn phải được phê duyệt trước khi ghi tồn.
*Avoid*: Nhập không chứng từ, PO tạm

**Phần còn phải nhận** (remaining receivable quantity):
Lượng của một dòng chứng từ chưa được nhận, do nguồn mua cung cấp và là giá trị có thẩm quyền; đã trừ các phiếu nhận hàng trước đó.
*Avoid*: Tự tính bằng số đặt trừ lịch sử nhận của Theme 7

**Lượng nhận vật lý** (accepted physical quantity):
Tổng lượng hàng được nhận quyền sở hữu trên một phiếu nhận hàng, gồm hàng Đạt, Cách ly và Hỏng, quy về đơn vị cơ sở; hàng từ chối tại chỗ không tính.
*Avoid*: Lượng đạt, lượng nhập

## Trạng thái phiếu nhận hàng

Phiếu nhận hàng có **một** vòng đời duy nhất; không có trục trạng thái thứ hai cho "kết quả thực thi".

**Nháp** (`DRAFT`):
Phiếu đang được lập; nội dung còn sửa được và chưa có tác động tồn.
*Avoid*: Bản tạm, chưa lưu

**Chờ duyệt** (`PENDING_APPROVAL`):
Phiếu đã gửi, nội dung bị khóa và đang chờ một người duyệt khác người lập.
*Avoid*: Đang xử lý

**Sẵn sàng ghi nhận** (`READY`):
Phiếu đủ điều kiện để hệ thống tự ghi vào tồn; người dùng không có thao tác nào thêm.
*Avoid*: Đã duyệt (khi ý là trạng thái phiếu)

**Đã hoàn tất** (`COMMITTED`):
Trạng thái cuối khi hàng đã được ghi vào tồn vật lý đúng một lần. UI nói "đã hoàn tất".
*Avoid*: `COMPLETED`, "thành công"

**Bị từ chối** (`REJECTED`):
Trạng thái cuối khi phiếu không được ghi vào tồn, do người duyệt từ chối (bắt buộc có lý do) hoặc do hệ thống từ chối lúc ghi nhận; không có tác động tồn nào.
*Avoid*: Thất bại, lỗi, `APPROVAL_REJECTED` / `EXECUTION_REJECTED` như hai trạng thái riêng

**Chưa xác định** (`UNKNOWN`):
Trạng thái khi chưa biết phiếu đã được ghi vào tồn hay chưa; không phải trạng thái cuối và chỉ được làm rõ bằng cách tra cứu đúng phiếu gốc.
*Avoid*: Đang xử lý, lỗi mạng, `COMMIT_UNKNOWN`, `PROCESSING`

## Số lượng

**Số lượng giao dịch**:
Số lượng theo đơn vị giao dịch trên một mục hàng nhận; luôn là số nguyên không âm.
*Avoid*: Số lượng lẻ, số lượng thập phân