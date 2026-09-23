---
id: DECISION-REGISTER
type: decision-register
theme: theme-06
title: Sổ quyết định — Công nợ
owner: BA
status: FROZEN
---

# Sổ quyết định — Công nợ

## 1. Mục đích và nguyên tắc

Tài liệu này là nguồn quyết định nghiệp vụ chuẩn của phân hệ công nợ. Nội dung chỉ phản ánh trạng thái hiện hành của sản phẩm tại phiên bản 2.1.2.

Quy ước:

- Mỗi quyết định có một mã duy nhất dạng `T06-DR-NNN`; mã, điểm neo và mọi tham chiếu phải thống nhất trong cùng bộ tài liệu.
- Quyết định được nhóm theo chủ đề nghiệp vụ, không theo lịch sử thay đổi.
- `FROZEN` nghĩa là quyết định đã đủ ổn định để làm căn cứ cho miền nghiệp vụ, hành trình, Trường hợp sử dụng, thiết kế và kiến trúc.
- Công nợ không nhận thay quyền sở hữu thực thể hoặc quyền xác nhận đặc tả tích hợp thuộc nghiệp vụ khác.
- Chi tiết kỹ thuật thuộc kiến trúc; sổ quyết định chỉ khóa ý nghĩa và ranh giới nghiệp vụ.

## 2. Nhóm quyết định

### G01 — Đối tác giao dịch, nguồn nghĩa vụ và quyền sở hữu

| ID | Quyết định | Lý do | Yêu cầu chi tiết | Phạm vi ảnh hưởng | Trạng thái |
|---|---|---|---|---|---|
| <a name="t06-dr-001"></a>T06-DR-001 | Đối tác giao dịch có một mã định danh chung; một đối tác có thể vừa là khách hàng, vừa là nhà cung cấp với cùng mã này. | Nhìn đầy đủ quan hệ kinh tế và hỗ trợ cấn trừ hai chiều. | Khách hàng và nhà cung cấp là vai trò, không phải hai định danh công nợ độc lập. | Miền nghiệp vụ, thực thể, hành trình, Trường hợp sử dụng, màn hình | FROZEN |
| <a name="t06-dr-002"></a>T06-DR-002 | Bán hàng là nguồn nghĩa vụ **phải thu**; nghĩa vụ được xác lập khi **Hoàn tất bán hàng**. | Bán hàng sở hữu chứng từ và căn cứ phát sinh phải thu. | Công nợ nhận nghĩa vụ đã xác lập, không sở hữu chứng từ bán hàng nguồn. | Ranh giới phân hệ, miền nghiệp vụ, hành trình, Trường hợp sử dụng | FROZEN |
| <a name="t06-dr-003"></a>T06-DR-003 | Mua hàng là nguồn nghĩa vụ **phải trả**; nghĩa vụ được xác lập khi **Nhận hóa đơn nhà cung cấp**. | Mua hàng sở hữu chứng từ và căn cứ phát sinh phải trả. | Công nợ nhận nghĩa vụ đã xác lập, không sở hữu chứng từ mua hàng nguồn. | Ranh giới phân hệ, miền nghiệp vụ, hành trình, Trường hợp sử dụng | FROZEN |
| <a name="t06-dr-004"></a>T06-DR-004 | Công nợ sở hữu tình hình công nợ theo đối tác, dư nợ còn lại, khoản thu/chi, phân bổ thanh toán, kết quả thực hiện nghĩa vụ, cấn trừ, số dư đầu kỳ, đối chiếu và điều phối phê duyệt thuộc phạm vi công nợ. | Tập trung vòng đời công nợ mà không chiếm quyền sở hữu nguồn. | Chứng từ nguồn chỉ được tham chiếu hoặc lập dữ liệu phục vụ tra cứu khi cần. | Miền nghiệp vụ, thực thể, hành trình, Trường hợp sử dụng, kiến trúc | FROZEN |
| <a name="t06-dr-005"></a>T06-DR-005 | Kế toán sở hữu sổ nhật ký kế toán, việc ghi sổ và kỳ kế toán. | Tách sổ theo dõi công nợ khỏi sổ kế toán. | Công nợ không đảm nhiệm chức năng ghi sổ nhật ký kế toán. | Ranh giới phân hệ, kiến trúc | FROZEN |

### G02 — Xác lập, tiếp nhận và lịch sử nghĩa vụ

| ID | Quyết định | Lý do | Yêu cầu chi tiết | Phạm vi ảnh hưởng | Trạng thái |
|---|---|---|---|---|---|
| <a name="t06-dr-006"></a>T06-DR-006 | Công nợ chỉ ghi nhận nghĩa vụ chính thức khi giao dịch nguồn đạt mốc xác lập tương ứng. | Không tạo công nợ từ giao dịch nháp hoặc chưa đủ điều kiện. | Bán hàng theo T06-DR-002; mua hàng theo T06-DR-003. | Miền nghiệp vụ, thực thể, Trường hợp sử dụng, hợp đồng hành vi | FROZEN |
| <a name="t06-dr-007"></a>T06-DR-007 | Khi giao dịch nguồn đạt mốc xác lập, công nợ tiếp nhận đầy đủ giá trị nghĩa vụ ban đầu và thông tin thanh toán tương ứng tại nguồn, kể cả giao dịch đã thanh toán đủ; không chỉ nhận phần còn nợ. | Giữ đủ căn cứ giải thích giá trị gốc, phần đã thanh toán và số còn lại. | Khoản tiền đã ghi nhận tại nguồn phải được tiếp nhận hoặc tham chiếu thống nhất, không tạo khoản tiền trùng. Nghĩa vụ đã trả đủ vẫn tra cứu được nhưng không tính vào công nợ còn mở. | Knowledge, hành trình, Trường hợp sử dụng, tích hợp | FROZEN |
| <a name="t06-dr-008"></a>T06-DR-008 | Sau mốc xác lập, không ghi đè nghĩa vụ đã ghi nhận mà không giữ lịch sử thay đổi. | Bảo toàn khả năng truy vết. | Thay đổi từ nguồn phải thể hiện bằng điều chỉnh, đảo nghĩa vụ hoặc phiên bản mới theo đặc tả của bên cung cấp dữ liệu. | Miền nghiệp vụ, thực thể, hợp đồng hành vi, tích hợp | FROZEN |

### G03 — Khoản thu, chi và phân bổ thanh toán

| ID | Quyết định | Lý do | Yêu cầu chi tiết | Phạm vi ảnh hưởng | Trạng thái |
|---|---|---|---|---|---|
| <a name="t06-dr-009"></a>T06-DR-009 | Giai đoạn 1 hỗ trợ thanh toán một phần. | Công nợ thực tế không bắt buộc thanh toán hết một lần. | Dư nợ chỉ giảm theo phân bổ hoặc kết quả thực hiện nghĩa vụ hợp lệ. | Hành trình, Trường hợp sử dụng, thực thể, màn hình | FROZEN |
| <a name="t06-dr-010"></a>T06-DR-010 | Một nghĩa vụ có thể được thanh toán bởi nhiều khoản thu hoặc chi. | Hỗ trợ nhiều lần thanh toán cho cùng nghĩa vụ. | Quan hệ khoản tiền–nghĩa vụ không bắt buộc một-một. | Miền nghiệp vụ, thực thể, Trường hợp sử dụng | FROZEN |
| <a name="t06-dr-011"></a>T06-DR-011 | Một khoản thu hoặc chi có thể phân bổ cho nhiều nghĩa vụ. | Hỗ trợ một lần thanh toán nhiều khoản nợ. | Mỗi phân bổ xác định rõ số tiền dùng cho từng nghĩa vụ. | Miền nghiệp vụ, thực thể, Trường hợp sử dụng, màn hình | FROZEN |
| <a name="t06-dr-012"></a>T06-DR-012 | Phân bổ thanh toán chỉ được thực hiện trong cùng tổ chức, cùng đối tác và cùng chiều nghĩa vụ: khoản thu → phải thu; khoản chi → phải trả. | Không biến phân bổ thành cấn trừ chéo chiều. | Tổng phân bổ không vượt số tiền chưa phân bổ; phân bổ cho từng nghĩa vụ không vượt dư nợ còn lại. Cấn trừ là nghiệp vụ riêng. | Hành trình, Trường hợp sử dụng, hợp đồng hành vi | FROZEN |
| <a name="t06-dr-013"></a>T06-DR-013 | Giai đoạn 1 hỗ trợ số tiền chưa phân bổ. | Tiền có thể đã được ghi nhận nhưng chưa xác định đầy đủ nghĩa vụ được thanh toán. | Phần chưa phân bổ vẫn thuộc khoản tiền và không tự giảm nghĩa vụ khác. | Miền nghiệp vụ, thực thể, Trường hợp sử dụng, màn hình | FROZEN |
| <a name="t06-dr-014"></a>T06-DR-014 | Khoản thu/chi có hiệu lực khi việc ghi nhận khoản tiền được xác nhận thành công; phân bổ có hiệu lực khi thao tác phân bổ được xác nhận thành công. | Phân biệt tiền đã ghi nhận với tiền đã dùng để thực hiện nghĩa vụ. | Phần đang chờ hoặc chưa có kết quả rõ không được làm giảm dư nợ. Khoản tiền có thể đã có hiệu lực trong khi một phần còn chưa phân bổ. | Trường hợp sử dụng, hợp đồng hành vi, kiến trúc | FROZEN |
| <a name="t06-dr-015"></a>T06-DR-015 | Phân bổ lại sau khi phân bổ đã chốt và đảo khoản thu/chi thuộc giai đoạn sau. | Giữ vòng đời giai đoạn 1 đơn giản và có truy vết. | Giai đoạn 1 không cung cấp hai chức năng này qua hành vi, giao diện hoặc giao diện lập trình. | Phạm vi, Trường hợp sử dụng, thiết kế | FROZEN |

### G04 — Chênh lệch và cấn trừ công nợ

| ID | Quyết định | Lý do | Yêu cầu chi tiết | Phạm vi ảnh hưởng | Trạng thái |
|---|---|---|---|---|---|
| <a name="t06-dr-016"></a>T06-DR-016 | Chênh lệch công nợ là kết quả tính từ phải thu và phải trả; không đồng nghĩa đã cấn trừ. | Tránh làm mất nghĩa vụ gốc và hiểu sai trạng thái. | Không tự lấy phải trả để giảm phải thu chỉ vì cùng đối tác. | Miền nghiệp vụ, dữ liệu đọc, hành trình, màn hình | FROZEN |
| <a name="t06-dr-017"></a>T06-DR-017 | Cấn trừ là nghiệp vụ có chủ đích và thuộc giai đoạn 1. | Cấn trừ cần kiểm soát và truy vết. | Chỉ cấn trừ trong cùng tổ chức, cùng mã đối tác, giữa phải thu và phải trả còn đủ dư nợ. Kết quả phải truy vết nghĩa vụ, số tiền, thời điểm, người thực hiện và phê duyệt. | Hành trình, Trường hợp sử dụng, hợp đồng hành vi, thực thể | FROZEN |

### G05 — Chính sách phê duyệt và quyền nghiệp vụ

| ID | Quyết định | Lý do | Yêu cầu chi tiết | Phạm vi ảnh hưởng | Trạng thái |
|---|---|---|---|---|---|
| <a name="t06-dr-018"></a>T06-DR-018 | Chính sách phê duyệt là cấu hình riêng của từng tổ chức sử dụng VET45. | Mỗi tổ chức có mức kiểm soát tài chính khác nhau. | Không dùng một bộ ngưỡng cố định cho toàn hệ thống. | Miền nghiệp vụ, cấu hình, Trường hợp sử dụng, màn hình | FROZEN |
| <a name="t06-dr-019"></a>T06-DR-019 | Có thể bật/tắt yêu cầu phê duyệt theo từng loại thao tác. | Cho phép thay đổi chính sách mà không đổi luồng nghiệp vụ cốt lõi. | Tắt phê duyệt không đồng nghĩa bỏ kiểm tra quyền thực hiện. | Miền nghiệp vụ, Trường hợp sử dụng, cấu hình | FROZEN |
| <a name="t06-dr-020"></a>T06-DR-020 | Chính sách phê duyệt hỗ trợ từ một đến nhiều dải giá trị; số dải, ngưỡng tiền và vai trò duyệt đều cấu hình được. | Không hard-code một số lượng dải hay một ngưỡng tiền. | Các dải đang áp dụng cho một thao tác phải không chồng lấn và đủ để xác định dải cho giá trị cần duyệt. Khi yêu cầu được gửi duyệt, lưu ảnh chụp chính sách/dải/vai trò áp dụng; thay đổi cấu hình sau đó không đổi yêu cầu đang chờ. | Cấu hình, miền nghiệp vụ, Trường hợp sử dụng | FROZEN |
| <a name="t06-dr-021"></a>T06-DR-021 | Giai đoạn đầu giữ vai trò nghiệp vụ đơn giản: Bán hàng, Kế toán, Thủ kho, Chủ hộ/Chủ doanh nghiệp. | Tránh mô hình quyền quá phức tạp ở giai đoạn đầu. | Công nợ chỉ sử dụng vai trò phù hợp với nghiệp vụ tương ứng. | Phân quyền, cấu hình, Trường hợp sử dụng | FROZEN |
| <a name="t06-dr-022"></a>T06-DR-022 | Khi thao tác cần phê duyệt, người tạo và người duyệt phải là hai người khác nhau. | Bảo đảm nguyên tắc người lập–người kiểm soát. | Người tạo không tự duyệt yêu cầu của mình; người duyệt phải có vai trò phù hợp với chính sách. Nếu không có người duyệt hợp lệ, yêu cầu không được tự bỏ qua phê duyệt và không được thực thi. | Phân quyền, Trường hợp sử dụng, hợp đồng hành vi | FROZEN |
| <a name="t06-dr-023"></a>T06-DR-023 | Trong giai đoạn 1, cấn trừ và khởi tạo số dư đầu kỳ mặc định cần phê duyệt; ghi nhận thu/chi, phân bổ và đối chiếu công nợ không mặc định cần phê duyệt. | Tập trung kiểm soát vào thao tác tạo/triệt tiêu nghĩa vụ hoặc đưa số dư tồn vào hệ thống. | Tổ chức có thể bật/tắt theo T06-DR-019. Dải phê duyệt căn cứ vào giá trị của nghiệp vụ được yêu cầu, không cộng hai phía; cấn trừ 6 triệu được xét theo 6 triệu. | BJ-06, BJ-02, BJ-01, Trường hợp sử dụng, cấu hình | FROZEN |
| <a name="t06-dr-024"></a>T06-DR-024 | Quyền nghiệp vụ giai đoạn 1: Kế toán được xem, ghi nhận thu/chi, phân bổ, lập cấn trừ, lập số dư đầu kỳ và lập/ghi nhận đối chiếu; Chủ hộ/Chủ doanh nghiệp được xem, duyệt và cấu hình chính sách, đồng thời có thể thực hiện nghiệp vụ nếu được phân quyền; Bán hàng chỉ xem ngữ cảnh cần thiết và ghi nhận tiền trong luồng bán hàng nếu nghiệp vụ bán cho phép; Thủ kho không có quyền công nợ mặc định. | Giữ trách nhiệm đơn giản nhưng không suy quyền từ chức danh ngoài phạm vi cần thiết. | Quyền thao tác cụ thể vẫn phải kiểm tra theo tổ chức; quyền phê duyệt độc lập với quyền thực hiện. | Toàn bộ hành trình, thiết kế, phân quyền | FROZEN |

### G06 — Số dư đầu kỳ

| ID | Quyết định | Lý do | Yêu cầu chi tiết | Phạm vi ảnh hưởng | Trạng thái |
|---|---|---|---|---|---|
| <a name="t06-dr-025"></a>T06-DR-025 | Số dư đầu kỳ thuộc giai đoạn 1 và không được giả lập thành giao dịch bán hoặc mua mới. | Đưa công nợ tồn tại trước khi dùng VET45 vào hệ thống mà không làm sai lịch sử. | Số dư đầu kỳ có nguồn riêng trong công nợ. | Phạm vi, hành trình, Trường hợp sử dụng, miền nghiệp vụ | FROZEN |
| <a name="t06-dr-026"></a>T06-DR-026 | Số dư đầu kỳ được ghi theo từng khoản công nợ còn mở, không chỉ một số tổng theo đối tác. | Bảo toàn khả năng phân bổ, tra cứu và đối chiếu về sau. | Mỗi khoản có đối tác, chiều phải thu/phải trả, số tiền, ngày/căn cứ và mô tả hoặc tham chiếu khi có. Có thể nhập nhiều khoản trong một đợt. Sau khi được phê duyệt và xác lập, không sửa trực tiếp; sai sót đi theo cơ chế xử lý ngoại lệ. | BJ-02, Trường hợp sử dụng, thực thể, thiết kế | FROZEN |

### G07 — Phạm vi giai đoạn 1 và các giới hạn sản phẩm

| ID | Quyết định | Lý do | Yêu cầu chi tiết | Phạm vi ảnh hưởng | Trạng thái |
|---|---|---|---|---|---|
| <a name="t06-dr-027"></a>T06-DR-027 | Đối chiếu và xác nhận công nợ với đối tác thuộc giai đoạn 1. | Đây là nhu cầu vận hành phổ biến của nhóm khách hàng mục tiêu. | Hỗ trợ chọn đối tác và mốc/kỳ đối chiếu, tổng hợp và xem căn cứ, lập bảng/biên bản, ghi nhận phản hồi, bằng chứng và kết quả `Chờ xác nhận` / `Đã khớp` / `Có chênh lệch`. Kết quả đối chiếu không tự sửa công nợ. | BJ-05, Trường hợp sử dụng, thiết kế, bằng chứng | FROZEN |
| <a name="t06-dr-028"></a>T06-DR-028 | Xóa nợ, điều chỉnh công nợ thủ công, đảo kết quả thực hiện nghĩa vụ, đảo khoản thu/chi, phân bổ lại sau chốt và các cơ chế xử lý tranh chấp/đối chiếu nâng cao thuộc giai đoạn sau. | Giữ phạm vi giai đoạn 1 có kiểm soát. | Không expose các chức năng này qua hành vi, giao diện hoặc giao diện lập trình ở giai đoạn 1. | Phạm vi, hành trình, Trường hợp sử dụng, thiết kế | FROZEN |
| <a name="t06-dr-029"></a>T06-DR-029 | Trong giai đoạn 1, dư nợ tín dụng bằng tổng các khoản phải thu còn mở. Giá trị cam kết bán chịu chưa được cộng vào cho đến khi bán hàng có một mốc chuẩn xác nhận cam kết tín dụng nhưng chưa phát sinh phải thu. | Không để công nợ tự suy diễn trạng thái bán hàng chưa có hợp đồng chuẩn. | Khi bán hàng có checkpoint canonical trong tương lai, thành phần cam kết có thể được bổ sung mà phải tránh tính trùng khi chuyển thành nghĩa vụ. | Tra cứu, liên kết bán hàng, miền nghiệp vụ | FROZEN |
| <a name="t06-dr-030"></a>T06-DR-030 | Giai đoạn 1 dùng một loại tiền tệ; chưa hỗ trợ nhiều loại tiền tệ. | Giảm độ phức tạp khi phân bổ, cấn trừ và đối chiếu. | Không có nghiệp vụ quy đổi ngoại tệ trong giai đoạn 1. | Miền nghiệp vụ, thực thể, Trường hợp sử dụng | FROZEN |
| <a name="t06-dr-031"></a>T06-DR-031 | Kết nối ngân hàng theo thời gian thực nằm ngoài giai đoạn 1. | Công nợ cốt lõi không phụ thuộc kết nối ngân hàng để vận hành. | Không lấy kết nối ngân hàng làm điều kiện trước của hành trình cốt lõi. | Phạm vi, tích hợp | FROZEN |
| <a name="t06-dr-032"></a>T06-DR-032 | Bằng chứng và nhật ký nghiệp vụ công nợ được lưu 10 năm. | Đáp ứng yêu cầu truy vết dài hạn của nghiệp vụ tài chính. | Cơ chế lưu trữ dài hạn do kiến trúc quyết định. | Yêu cầu phi chức năng, kiến trúc, bằng chứng | FROZEN |
| <a name="t06-dr-033"></a>T06-DR-033 | Lãi và phạt chậm trả nằm ngoài giai đoạn 1. | Chưa triển khai cơ chế tính và phát sinh lãi/phạt. | Không tự động phát sinh lãi hoặc tiền phạt. | Phạm vi, miền nghiệp vụ, Trường hợp sử dụng | FROZEN |
| <a name="t06-dr-034"></a>T06-DR-034 | Ứng dụng dành cho tổ chức có mục cấp một **Công nợ**. | Hỗ trợ công việc tổng hợp công nợ như một chức năng độc lập. | Có thể có liên kết từ đối tác hoặc giao dịch nguồn nhưng không thay thế lối vào chính. | Hành trình, thiết kế, điều hướng | FROZEN |

### G08 — Quyền xác nhận tích hợp, phục hồi và kế toán

| ID | Quyết định | Lý do | Yêu cầu chi tiết | Phạm vi ảnh hưởng | Trạng thái |
|---|---|---|---|---|---|
| <a name="t06-dr-035"></a>T06-DR-035 | Bên cung cấp dữ liệu giữ quyền sở hữu thực thể và quyền xác nhận đặc tả tích hợp chuẩn do mình cung cấp. | Không để công nợ nhận thay ownership của bán hàng, mua hàng hoặc kế toán. | Với dữ liệu ngoài ownership, công nợ chỉ tham chiếu hoặc lập dữ liệu phục vụ tra cứu. | Ranh giới miền nghiệp vụ, tích hợp | FROZEN |
| <a name="t06-dr-036"></a>T06-DR-036 | Công nợ được xác định yêu cầu tiếp nhận và ý nghĩa dữ liệu bàn giao; đặc tả chưa được bên cung cấp xác nhận mang trạng thái `PROPOSED_HANDOFF`. | Cho phép phân tích nhu cầu mà không chiếm quyền xác nhận contract của bên khác. | Chỉ chuyển thành `CANONICAL` khi owner xác nhận nguồn và phiên bản. | Tích hợp, truy vết | FROZEN |
| <a name="t06-dr-037"></a>T06-DR-037 | Dữ liệu bàn giao phải làm rõ định danh, phiên bản, mốc xác lập, điều chỉnh/đảo, chống lặp, thứ tự khi cần, phục hồi và đối chiếu. | Bảo đảm dữ liệu không ghi trùng và có thể phục hồi. | Kiến trúc cụ thể hóa cơ chế chuyển giao; business contract giữ ý nghĩa. | Tích hợp, kiến trúc | FROZEN |
| <a name="t06-dr-038"></a>T06-DR-038 | Giữa công nợ và kế toán, chỉ kiểm tra trước đối với nghiệp vụ cần bảo đảm điều kiện ghi nhận kế toán; sau khi nghiệp vụ công nợ được ghi nhận thành công, phát sự kiện bất đồng bộ qua bộ lưu sự kiện chờ gửi. | Cân bằng kiểm soát kế toán và khả năng hoạt động độc lập. | Không bắt mọi thao tác công nợ chờ phản hồi đồng bộ từ kế toán. | Tích hợp, kiến trúc, Trường hợp sử dụng | FROZEN |
| <a name="t06-dr-039"></a>T06-DR-039 | Khi thay đổi từ nguồn làm phát sinh trạng thái không thể áp dụng hợp lệ vì nghĩa vụ đã được thanh toán/cấn trừ vượt giá trị mới, giai đoạn 1 không tự hoàn tiền, tự đảo phân bổ hoặc tự điều chỉnh công nợ. | Các chức năng đảo/điều chỉnh chưa thuộc giai đoạn 1; tự xử lý có thể làm sai lịch sử. | Giữ nguyên trạng thái công nợ đang có, ghi nhận thay đổi nguồn ở trạng thái **Cần xử lý**, lưu đầy đủ căn cứ và chặn áp dụng tự động cho đến khi được giải quyết bằng capability phù hợp. | Tích hợp nguồn, hành trình tra cứu, bằng chứng, kiến trúc | FROZEN |

### G09 — Cấu trúc Domain Công nợ

| ID | Quyết định | Lý do | Yêu cầu chi tiết | Phạm vi ảnh hưởng | Trạng thái |
|---|---|---|---|---|---|
| <a name="t06-dr-040"></a>T06-DR-040 | Trong phạm vi bộ tài liệu này, **Công nợ được mô hình hóa là một Domain nghiệp vụ duy nhất**. Các nhóm như nghĩa vụ và số dư, thu/chi và phân bổ, số dư đầu kỳ, cấn trừ, đối chiếu, phê duyệt và tra cứu là **capability bên trong Domain**, không phải các Domain con độc lập. | Giữ ranh giới nghiệp vụ bền vững, tránh chia Domain theo màn hình hoặc từng chức năng nhỏ. | Bán hàng, Mua hàng, Quản lý đối tác và Kế toán là các Domain bên ngoài có ranh giới/handoff với Công nợ. Aggregate được xác định theo consistency boundary và invariant, không suy ra một-một từ capability hoặc Business Journey. | Domain Foundation, Entity, Aggregate, Architecture, Trường hợp sử dụng | FROZEN |

