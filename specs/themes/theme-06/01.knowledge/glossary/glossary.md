---
id: GLOSSARY
type: glossary
theme: theme-06
title: Bảng thuật ngữ — Công nợ
owner: BA
status: FROZEN
---

# Bảng thuật ngữ — Công nợ

## 1. Thuật ngữ chuẩn

| Thuật ngữ | Nghĩa trong nghiệp vụ công nợ | Thuật ngữ tránh dùng / đồng nghĩa | Ghi chú |
|---|---|---|---|
| Đối tác giao dịch (`Partner`) | Đối tượng được định danh thống nhất trong quan hệ giao dịch với doanh nghiệp. Một đối tác có thể vừa là khách hàng, vừa là nhà cung cấp. | Tránh tách cùng một đối tượng thành mã khách hàng và mã nhà cung cấp độc lập. | Mã định danh dùng chung: `Partner ID`. |
| Vai trò khách hàng (`Customer role`) | Vai trò của đối tác khi mua hàng của doanh nghiệp. | Tránh hiểu khách hàng là đối tượng định danh tách rời đối tác giao dịch. | Không thay thế mã định danh của đối tác. |
| Vai trò nhà cung cấp (`Supplier role`) | Vai trò của đối tác khi bán hàng cho doanh nghiệp. | Tránh hiểu nhà cung cấp là đối tượng định danh tách rời đối tác giao dịch. | Không thay thế mã định danh của đối tác. |
| Nghĩa vụ công nợ (`Obligation`) | Nghĩa vụ bằng tiền đã được xác lập và được phân hệ công nợ theo dõi, kể cả khi đã thanh toán đủ. | Không đồng nhất với khoản thu, chi; chứng từ nguồn; hoặc chỉ phần còn nợ. | Có chiều phải thu (`RECEIVABLE`) hoặc phải trả (`PAYABLE`). Xem [T06-DR-007](../decisions/decision-register.md#t06-dr-007). |
| Phải thu (`RECEIVABLE`) | Nghĩa vụ đối tác phải thanh toán cho doanh nghiệp. | Không dùng thay cho doanh thu hoặc khoản thu đã ghi nhận. | Nguồn chính trong giai đoạn 1: nghiệp vụ bán hàng. |
| Phải trả (`PAYABLE`) | Nghĩa vụ doanh nghiệp phải thanh toán cho đối tác. | Không dùng thay cho chi phí hoặc khoản chi đã ghi nhận. | Nguồn chính trong giai đoạn 1: nghiệp vụ mua hàng. |
| Giá trị gốc (`Original Amount`) | Giá trị của nghĩa vụ tại phiên bản hoặc mốc xác lập đang được tham chiếu, trước khi trừ phần đã thực hiện. | Không dùng thay cho dư nợ còn lại. | Nghĩa vụ 10 triệu đã trả đủ vẫn có giá trị gốc 10 triệu; số còn phải thu là 0. |
| Dư nợ còn lại (`Outstanding`) | Phần nghĩa vụ chưa được thực hiện hợp lệ, tương ứng với số tiền còn phải thu hoặc phải trả. | Không dùng thay cho giá trị gốc hoặc chênh lệch công nợ. | Bằng 0 khi nghĩa vụ đã được thực hiện đủ; không có nghĩa phải xóa nghĩa vụ hay lịch sử. |
| Khoản công nợ còn mở (`Open Obligation`) | Nghĩa vụ đã xác lập vẫn còn số tiền phải thu hoặc phải trả chưa được thực hiện. | Không dùng thay cho toàn bộ lịch sử nghĩa vụ. | Nghĩa vụ có dư nợ còn lại bằng 0 không thuộc nhóm này. Xem [T06-DR-007](../decisions/decision-register.md#t06-dr-007). |
| Tình hình công nợ (`Debt Position`) | Góc nhìn tổng hợp các nghĩa vụ và dư nợ còn lại của một đối tác. | Còn gọi là vị thế công nợ; không phải một nghĩa vụ đơn lẻ. | Có thể gồm cả phải thu và phải trả. |
| Chênh lệch công nợ (`Net Position`) | Giá trị tính từ chênh lệch giữa số phải thu và số phải trả của cùng đối tác. | Còn gọi là vị thế ròng; không dùng thay cho cấn trừ hoặc số đã cấn trừ. | Phép tính không tự làm giảm nghĩa vụ. |
| Khoản thu, chi (`Payment`) | Khoản tiền thu hoặc chi đã được ghi nhận trong nghiệp vụ thanh toán. | Không đồng nhất với nghĩa vụ công nợ hoặc phân bổ thanh toán. | Có thể còn phần chưa phân bổ. Khoản đã ghi nhận tại nguồn không trở thành một khoản tiền mới chỉ vì công nợ tiếp nhận thông tin. |
| Phân bổ thanh toán (`Allocation`) | Quan hệ xác định một phần số tiền của khoản thu, chi được dùng để thực hiện một nghĩa vụ công nợ cụ thể. | Không dùng thay cho khoản thu, chi. | Là căn cứ làm giảm dư nợ theo hành vi nghiệp vụ hợp lệ. |
| Số tiền chưa phân bổ (`Unallocated Amount`) | Phần tiền của khoản thu, chi chưa được gán cho nghĩa vụ cụ thể. | Không gọi là dư nợ âm hoặc tự động cấn trừ. | Không tự động làm giảm nghĩa vụ khác. |
| Thanh toán một phần (`Partial Payment`) | Trường hợp nghĩa vụ mới được thực hiện một phần tại một thời điểm. | Không mặc định coi việc chưa trả đủ là lỗi. | Là hành vi hợp lệ trong giai đoạn 1. |
| Ghi nhận thực hiện nghĩa vụ (`Settlement`) | Kết quả làm giảm hoặc hoàn thành một phần hay toàn bộ nghĩa vụ công nợ thông qua nghiệp vụ hợp lệ. | Không dùng khoản thu, chi hoặc tất toán toàn bộ để thay thế. | Khoản thu, chi là nguồn tiền; ghi nhận thực hiện nghĩa vụ là kết quả nghiệp vụ. |
| Cấn trừ công nợ (`Offset`) | Nghiệp vụ có chủ đích ghi nhận thực hiện nghĩa vụ giữa khoản phải thu và khoản phải trả của cùng mã đối tác. | Không đồng nhất với chênh lệch công nợ hoặc tự động bù trừ. | Thuộc giai đoạn 1. |
| Mốc xác lập nghĩa vụ (`Finality`) | Mốc nghiệp vụ nguồn xác nhận nghĩa vụ đủ điều kiện được theo dõi chính thức trong phân hệ công nợ. | Không đồng nhất với bản nháp; cũng không mặc định nghĩa vụ còn chưa thanh toán. | Bán hàng: Hoàn tất bán hàng. Mua hàng: Nhận hóa đơn nhà cung cấp. |
| Điều chỉnh từ nguồn (`Correction`) | Thay đổi có lưu dấu vết đối với nghĩa vụ đã xác lập, được thể hiện theo đặc tả của nghiệp vụ nguồn. | Không dùng thay cho ghi đè dữ liệu. | Không xóa lịch sử nghĩa vụ cũ. |
| Đảo nghĩa vụ nguồn (`Source Reversal`) | Bên cung cấp dữ liệu đảo nghĩa vụ nguồn đã phát sinh theo đặc tả có phiên bản và dấu vết nghiệp vụ. | Không đồng nhất với đảo khoản thu, chi hoặc đảo kết quả thực hiện nghĩa vụ. | Thuộc vòng đời nghĩa vụ nguồn, không phải thao tác trên khoản thu, chi. |
| Đảo khoản thu, chi (`Payment Reversal`) | Đảo một khoản thu hoặc chi đã chốt. | Không đồng nhất với đảo nghĩa vụ nguồn. | Thuộc giai đoạn sau. |
| Đảo kết quả thực hiện nghĩa vụ (`Settlement Reversal`) | Đảo kết quả nghiệp vụ của việc ghi nhận thực hiện nghĩa vụ đã chốt. | Không đồng nhất với đảo nghĩa vụ nguồn. | Thuộc giai đoạn sau. |
| Số dư đầu kỳ (`Opening Balance`) | Công nợ tồn tại trước khi chuyển sang sử dụng VET45, được khởi tạo trực tiếp trong phân hệ công nợ. | Không phải giao dịch bán hoặc mua giả lập. | Thuộc giai đoạn 1. |
| Chính sách phê duyệt (`Approval Policy`) | Cấu hình của từng tổ chức quy định loại thao tác nào cần duyệt và cách xác định người duyệt. | Không phải luồng phê duyệt được cố định trong mã chương trình cho toàn hệ thống. | Cấu hình riêng theo tổ chức sử dụng VET45 (`Tenant`). |
| Dải giá trị phê duyệt (`Approval Band`) | Một dải số tiền trong chính sách phê duyệt. | Không giới hạn ở một ngưỡng duy nhất. | Hỗ trợ từ một đến nhiều dải (`1..N`). |
| Vai trò phê duyệt (`Approver Role`) | Vai trò nghiệp vụ được cấu hình để duyệt một dải giá trị hoặc loại thao tác. | Không gắn cố định với một người dùng trong mã chương trình. | Giai đoạn đầu giữ danh sách vai trò đơn giản. |
| Người tạo (`Maker`) | Người dùng khởi tạo thao tác hoặc yêu cầu cần phê duyệt. | Không là người duyệt của chính yêu cầu đó. | Không được tự duyệt yêu cầu của mình. |
| Người duyệt (`Checker`) | Người dùng khác, có vai trò phù hợp với chính sách để phê duyệt hoặc từ chối yêu cầu. | Không là người tạo của cùng yêu cầu. | Người tạo và người duyệt phải khác nhau. |
| Dư nợ tín dụng (`Credit Exposure`) | Trong giai đoạn 1, tổng các khoản phải thu còn mở của đối tác. Chỉ bổ sung cam kết bán chịu khi bán hàng có mốc chuẩn xác nhận cam kết tín dụng trước khi phát sinh phải thu. | Không bao gồm khoản phải thu đã thanh toán đủ; chưa bao gồm cam kết bán chịu ở giai đoạn 1. | Là số liệu tổng hợp phục vụ theo dõi tín dụng, không phải một nghĩa vụ riêng. Xem T06-DR-029. |
| Cam kết bán chịu (`Committed Credit`) | Khái niệm giá trị bán chịu được bán hàng xác nhận là cam kết tín dụng nhưng chưa chuyển thành nghĩa vụ phải thu. Giai đoạn 1 chưa đưa thành phần này vào dư nợ tín dụng vì chưa có mốc chuẩn từ bán hàng. | Không đồng nhất với nghĩa vụ phải thu đã xác lập. | Chỉ được dùng khi bán hàng có checkpoint canonical; khi đó phải tránh tính trùng với nghĩa vụ phát sinh sau này. |
| Đối chiếu công nợ (`Debt Reconciliation`) | Nghiệp vụ so sánh số liệu công nợ của tổ chức với xác nhận từ đối tác tại một mốc hoặc kỳ xác định. | Không đồng nhất với tra cứu nội bộ hoặc tự động điều chỉnh công nợ. | Giai đoạn 1 hỗ trợ lập đối chiếu, ghi nhận phản hồi và kết quả. |
| Chênh lệch đối chiếu (`Reconciliation Difference`) | Khoảng chênh giữa số liệu VET45 và số liệu đối tác phản hồi tại cùng phạm vi đối chiếu. | Không gọi là điều chỉnh công nợ. | Kết quả `Có chênh lệch` không tự thay đổi nghĩa vụ hoặc dư nợ. |
| Biên bản đối chiếu (`Reconciliation Statement`) | Tài liệu tổng hợp số liệu và căn cứ dùng để trao đổi/xác nhận công nợ với đối tác. | Không phải chứng từ điều chỉnh công nợ. | Có thể được xuất/gửi ngoài hệ thống; bằng chứng phản hồi được lưu lại. |
| Ngoại lệ cần xử lý (`Manual Resolution Required`) | Trạng thái khi dữ liệu nguồn thay đổi nhưng không thể áp dụng tự động mà vẫn giữ đúng lịch sử, ví dụ nghĩa vụ bị giảm xuống thấp hơn phần đã thực hiện. | Không đồng nhất với lỗi kỹ thuật hoặc tự động đảo nghiệp vụ. | Giai đoạn 1 giữ nguyên trạng thái công nợ hiện tại và chặn áp dụng thay đổi cho đến khi có cách xử lý hợp lệ. |
| Đề xuất bàn giao dữ liệu (`PROPOSED_HANDOFF`) | Yêu cầu về ý nghĩa và cách trao đổi dữ liệu mà phân hệ công nợ cần, nhưng chưa được bên cung cấp dữ liệu chốt thành đặc tả chuẩn. | Không dùng thay cho đặc tả tích hợp chuẩn. | Chưa được coi là đặc tả chính thức của bên cung cấp dữ liệu. |
| Đặc tả tích hợp chuẩn (`CANONICAL`) | Đặc tả đã được bên sở hữu xác nhận nguồn và phiên bản, dùng làm căn cứ chuẩn cho tích hợp. | Không đồng nhất với một đề xuất. | Quyền xác nhận thuộc bên cung cấp dữ liệu. |

## 2. Quy ước đặt tên

- Tài liệu nghiệp vụ và nội dung giao diện ưu tiên tên tiếng Việt trong bảng trên. Phần đối chiếu tiếng Anh được tập trung tại bảng thuật ngữ, không lặp kèm trong mỗi câu.
- Dùng **Phải thu**, **Phải trả**, **Cấn trừ công nợ**, **Số dư đầu kỳ** trong nghiệp vụ và giao diện. Đặc tả kỹ thuật có thể dùng các mã `RECEIVABLE`, `PAYABLE`, `OFFSET`, `OPENING_BALANCE` khi cần.
- Dùng **Đối tác giao dịch** cho đối tượng được định danh chung; **Khách hàng** và **Nhà cung cấp** là hai vai trò. Không đặt tên thực thể theo mô hình `CustomerAccount` và `SupplierAccount` như hai tài khoản công nợ độc lập cho cùng đối tác.
- Dùng **Khoản thu, chi** cho số tiền đã ghi nhận; dùng **Phân bổ thanh toán** cho việc xác định số tiền đó thanh toán nghĩa vụ nào. Không dùng hai cách gọi này thay thế cho nhau. Khi bối cảnh đã rõ, có thể viết riêng **khoản thu** hoặc **khoản chi**.
- Dùng **Chênh lệch công nợ** cho kết quả tính toán; dùng **Cấn trừ công nợ** cho nghiệp vụ có chủ đích. Không gọi chênh lệch công nợ là “đã cấn trừ”.
- Sau **mốc xác lập nghĩa vụ**, dùng **Điều chỉnh từ nguồn**, **Đảo nghĩa vụ nguồn** hoặc **phiên bản mới** theo đặc tả nguồn. Tránh cách nói “sửa trực tiếp” nếu việc đó làm mất lịch sử thay đổi.
- Trong bộ tài liệu này, `Tenant` được gọi là **tổ chức sử dụng VET45**, viết gọn là **tổ chức** khi bối cảnh đã rõ. `Phase 1` được gọi là **giai đoạn 1**; `Future` là **giai đoạn sau**.
- Trong phần tích hợp, `Selective Preflight` được diễn đạt là **kiểm tra trước có chọn lọc**; `Outbox` là **bộ lưu sự kiện chờ gửi**. Đây là đối chiếu cách gọi; cơ chế kỹ thuật chi tiết vẫn thuộc tài liệu kiến trúc.
- Tên bài kiến thức theo dạng `KB-NNN-chu-de-tieng-viet-khong-dau.md`; tiêu đề và nội dung dùng tiếng Việt có dấu. Tên thư mục và trường kỹ thuật theo bộ mẫu. Mã và liên kết phải đồng bộ trong cùng bộ tài liệu. `FINAL`, `FROZEN`, `PROPOSED_HANDOFF`, `CANONICAL` là các mã kỹ thuật; phần diễn giải và giao diện dùng cách gọi tiếng Việt phù hợp.

- Trong phần diễn giải, gọi theo tên nghiệp vụ như công nợ, bán hàng, mua hàng, kế toán; không dùng số thứ tự phân hệ làm tên gọi. Liên kết nội bộ là liên kết tương đối từ tệp đang đọc, không gắn cứng tên nhánh.
