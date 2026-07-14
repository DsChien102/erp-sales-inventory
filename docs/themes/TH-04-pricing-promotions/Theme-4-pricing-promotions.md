# Theme 4: Chính sách giá và ưu đãi

# 1\. Theme overview

## 1\.1 Mục tiêu theme

Theme 04 giúp doanh nghiệp **thiết lập, kiểm soát và áp dụng giá bán, giá riêng và chương trình khuyến mại** một cách nhất quán trong quá trình bán hàng\.

Mục tiêu không chỉ là “nhập giá” hay “tạo khuyến mại”, mà là giúp người dùng trả lời được:

- Sản phẩm này đang bán theo giá nào?

- Giá này đến từ giá mặc định, giá riêng hay CTKM?

- Chính sách nào đang có hiệu lực?

- Có xung đột giá hoặc khuyến mại không?

- Ai đã thay đổi chính sách giá/khuyến mại, thay đổi khi nào?

- Khi bán hàng, hệ thống phải áp dụng giá nào là đúng?

## 1\.2 Bối cảnh nghiệp vụ

Trong vận hành bán lẻ, đặc biệt với ngành thuốc thú y / vật tư / hàng hóa có nhiều nhóm khách, giá bán thường không đơn giản\.

Một sản phẩm có thể có:

- Giá bán mặc định

- Giá theo bảng giá

- Giá riêng theo khách hàng

- Giá đã từng bán cho khách và cần “nhớ giá”

- Giá bị ảnh hưởng bởi CTKM

- Giá thay đổi theo thời gian

- Giá khác nhau giữa chi nhánh hoặc kênh bán

Nếu không kiểm soát tốt, doanh nghiệp dễ gặp các vấn đề:

- Nhân viên bán sai giá

- Khách quen bị báo giá không nhất quán

- CTKM chồng lên nhau gây sai lợi nhuận

- Chủ hộ không biết chương trình nào đang ảnh hưởng doanh thu

- Không truy vết được ai đã thay đổi giá

- Khi mở rộng nhiều cửa hàng/kênh bán, chính sách giá bị rối

Vì vậy, Theme 04 cần được thiết kế như một lớp **kiểm soát chính sách giá và ưu đãi**, không chỉ là một nhóm màn hình nhập liệu\.

## 1\.3 Phạm vi theme

Theme 04 bao gồm:

- Quản lý giá bán cơ bản

- Quản lý bảng giá nếu cần

- Quản lý giá riêng / nhớ giá

- Quản lý chương trình khuyến mại

- Chọn loại CTKM

- Tạo CTKM theo từng mục đích cụ thể

- Kiểm soát vòng đời CTKM

- Kiểm tra xung đột chính sách giá/khuyến mại

- Xác định giá được áp dụng khi bán hàng

- Giải thích vì sao hệ thống áp dụng một mức giá

- Ghi nhận lịch sử thay đổi chính sách giá/khuyến mại

## 1\.4 Ngoài phạm vi theme

Theme 04 không trực tiếp xử lý:

- Giá vốn

- Lợi nhuận gộp chuyên sâu

- Hạch toán kế toán chi tiết

- Cấu hình thuế VAT chi tiết

- Quản lý tồn kho

- Quản lý công nợ

- Báo cáo tài chính

- Chính sách loyalty/tích điểm/phân hạng khách hàng nếu được tách thành theme riêng

Các phần này có thể liên quan tới giá/khuyến mại, nhưng không nên nhét toàn bộ vào Theme 04 để tránh phình phạm vi\.

## 1\.5 Người dùng chính

|Vai trò|Nhu cầu chính|
|---|---|
|**Chủ hộ / chủ doanh nghiệp**|Kiểm soát chính sách giá, tránh sai giá, xem tác động kinh doanh|
|**Quản lý cửa hàng**|Kiểm tra giá đang áp dụng, xử lý giá riêng/CTKM theo quyền|
|**Nhân viên bán hàng**|Bán đúng giá, hiểu vì sao giá được áp dụng|
|**Kế toán / người kiểm soát**|Kiểm tra lịch sử thay đổi, đối soát doanh thu nếu cần|
|**Quản trị viên hệ thống**|Thiết lập quyền, cấu hình chính sách, kiểm soát vận hành|

## 1\.6 Khái niệm chính

|Khái niệm|Mô tả ngắn|
|---|---|
|**Giá bán mặc định**|Giá cơ bản của sản phẩm khi không có chính sách đặc biệt|
|**Bảng giá**|Tập hợp giá áp dụng cho một nhóm sản phẩm/khách hàng/kênh bán|
|**Giá riêng**|Giá được thiết lập riêng cho một khách hàng hoặc nhóm khách hàng|
|**Nhớ giá**|Hệ thống ghi nhớ giá từng bán cho khách để gợi ý/lặp lại trong lần bán sau|
|**CTKM**|Chương trình khuyến mại có điều kiện, thời gian, phạm vi và cơ chế ưu đãi|
|**Điều kiện kích hoạt**|Điều kiện để một chính sách/CTKM được áp dụng|
|**Phạm vi áp dụng**|Sản phẩm, khách hàng, chi nhánh, kênh bán được áp dụng|
|**Cơ chế ưu đãi**|Cách tính ưu đãi: giảm %, giảm tiền, tặng hàng, giá combo\.\.\.|
|**Hiệu lực**|Khoảng thời gian chính sách được áp dụng|
|**Xung đột chính sách**|Khi nhiều chính sách cùng có khả năng áp dụng nhưng chưa rõ ưu tiên|
|**Giá áp dụng cuối cùng**|Giá hệ thống sử dụng trên đơn hàng sau khi xét các chính sách liên quan|

## 1\.7 Nguyên tắc nghiệp vụ cấp theme

- **Giá áp dụng tại điểm bán phải rõ ràng và giải thích được\.**

- **Mọi chính sách giá/CTKM phải có trạng thái vòng đời\.**

- **Chính sách đang chạy không được sửa tùy tiện nếu ảnh hưởng tới đơn hàng\.**

- **Các thay đổi quan trọng phải có lịch sử\.**

- **Nếu có xung đột, hệ thống phải cảnh báo trước hoặc giải thích rõ cách xử lý\.**

- **Người dùng chỉ được thao tác trong phạm vi quyền được cấp\.**

- **CTKM đã kết thúc hoặc đã hủy không nên được bật lại trực tiếp; nên dùng nhân bản nếu cần chạy lại\.**

## 1\.8 Nguyên tắc UI/UX cấp theme

- Mỗi màn hình nên có **một CTA chính**\.

- Danh sách không chỉ để xem dữ liệu, mà phải giúp người dùng **phát hiện vấn đề cần xử lý**\.

- Trạng thái chính và cảnh báo phải tách biệt\.

- Các action nhạy cảm như bật, tạm dừng, kết thúc, hủy cần có confirmation\.

- Với nghiệp vụ phức tạp, dùng progressive disclosure: tổng quan trước, chi tiết sau\.

- Các màn hình quan trọng cần có đủ state: empty, loading, error, no permission\.

- Design cần được map với FR và Scenario thông qua Design coverage\.

## 1\.9 Mô hình cấu trúc trong SRS

Mỗi Epic trong Theme 04 sẽ được triển khai theo cấu trúc:

- Epic overview

- User story list

- Chi tiết từng User Story

Khi đi vào từng User Story, cấu trúc chuẩn sẽ là:

1. Summary

2. Business context

3. Functional requirements

4. Business rules

5. UI Contract

6. Design coverage

7. Scenarios

8. Edge cases / Open questions

Trong đó:

- **Scenario gắn với User Story**, không gắn trực tiếp với từng FR\.

- **Design coverage nằm trong User Story** để map Design ↔ FR ↔ Scenario\.

- **Design snapshot chi tiết nằm ở Appendix**, không nhét toàn bộ vào thân SRS\.

## 1\.10 Epic map

|Epic ID|Epic|Mục tiêu|
|---|---|---|
|**EP01**|Giá bán cơ bản|Quản lý giá bán mặc định và giá bán hiện hành của sản phẩm|
|**EP02**|Giá riêng / Nhớ giá|Quản lý giá riêng theo khách hàng và gợi ý giá đã từng bán|
|**EP03**|Chương trình khuyến mại|Tạo, quản lý và kiểm soát vòng đời các CTKM|
|**EP04**|Ưu tiên \& xung đột chính sách|Xác định chính sách nào được áp dụng khi nhiều chính sách cùng hợp lệ|
|**EP05**|Giá áp dụng tại bán hàng|Hiển thị, áp dụng và giải thích giá cuối cùng tại POS/Order|
|**EP06**|Lịch sử \& kiểm soát thay đổi|Truy vết thay đổi giá, giá riêng và CTKM|

# 2\. Theme\-level business rules

## 2\.1 Quy tắc hiệu lực

- Một chính sách giá/CTKM chỉ được áp dụng khi đang trong thời gian hiệu lực\.

- Chính sách hết hạn không được áp dụng cho đơn hàng mới\.

- Chính sách đã hủy không được khôi phục trực tiếp\.

- Chính sách nháp không được áp dụng trong bán hàng\.

- Chính sách tạm dừng không được áp dụng cho đơn hàng mới\.

## 2\.2 Quy tắc trạng thái

Các nhóm trạng thái nên áp dụng nhất quán:

- **Nháp**

- **Sẵn sàng**

- **Sắp chạy**

- **Đang chạy**

- **Tạm dừng**

- **Đã kết thúc**

- **Đã hủy**

Tùy từng loại chính sách, có thể không dùng đủ tất cả trạng thái, nhưng ý nghĩa trạng thái phải thống nhất trong toàn theme\.

## 2\.3 Quy tắc ưu tiên

- Giá bán mặc định là giá nền\.

- Giá riêng có thể ưu tiên hơn giá mặc định\.

- CTKM có thể áp dụng sau khi xác định giá nền\.

- Nếu nhiều chính sách cùng hợp lệ, hệ thống phải có rule ưu tiên\.

- Nếu chưa đủ rule để xác định, hệ thống phải cảnh báo xung đột\.

- Khi giá cuối cùng được áp dụng, hệ thống cần giải thích được nguồn gốc giá\.

## 2\.4 Quy tắc chỉnh sửa

- Chính sách ở trạng thái nháp được sửa toàn bộ\.

- Chính sách đang chạy chỉ được sửa các trường an toàn\.

- Các thay đổi ảnh hưởng tới giá bán cần confirmation\.

- Chính sách đã kết thúc không được sửa để chạy lại trực tiếp\.

- Chính sách đã hủy không được sửa để chạy lại trực tiếp\.

- Nếu cần tái sử dụng chính sách cũ, dùng nhân bản\.

## 2\.5 Quy tắc audit/log

Các hành động cần ghi lịch sử:

- Tạo chính sách giá/CTKM

- Sửa chính sách

- Bật chính sách

- Tạm dừng

- Bật lại

- Kết thúc sớm

- Hủy

- Xóa nháp

- Nhân bản

- Thao tác hàng loạt

- Xử lý xung đột

- Thay đổi rule ưu tiên

## 2\.6 Quy tắc phân quyền

- Nhân viên bán hàng chỉ xem giá/CTKM đang áp dụng khi bán hàng\.

- Quản lý cửa hàng có thể xem, tìm kiếm, lọc, kiểm tra chính sách\.

- Quản trị viên có thể tạo, sửa, bật, tạm dừng, kết thúc, hủy chính sách\.

- Chủ hộ/chủ doanh nghiệp có toàn quyền và xem lịch sử thay đổi\.

- Kế toán/người kiểm soát có thể xem lịch sử và dữ liệu phục vụ đối soát\.

# 3\. Epic EP01 — Giá bán cơ bản

## 3\.1 Epic overview

Epic này quản lý **giá bán mặc định và giá bán hiện hành của sản phẩm**\. Đây là lớp giá nền trước khi xét giá riêng hoặc CTKM\.

## 3\.2 User stories

|ID|As user|I want to do|So that|
|---|---|---|---|
|**US\-01**|Quản lý cửa hàng / Quản trị viên|Xem danh sách giá bán của sản phẩm|Tôi có thể kiểm soát giá bán hiện hành của toàn bộ sản phẩm|
|**US\-02**|Quản lý cửa hàng / Quản trị viên|Xem chi tiết giá bán của một sản phẩm|Tôi có thể kiểm tra giá mặc định, đơn vị tính, lịch sử và các thông tin liên quan trước khi bán hoặc điều chỉnh|
|**US\-03**|Quản lý cửa hàng / Quản trị viên|Cập nhật giá bán mặc định của sản phẩm|Tôi có thể điều chỉnh giá bán khi có thay đổi chính sách giá hoặc thị trường|
|**US\-04**|Quản lý cửa hàng / Quản trị viên|Cập nhật giá bán theo đơn vị tính hoặc quy cách|Tôi có thể bán cùng một sản phẩm theo nhiều đơn vị/quy cách với mức giá phù hợp|
|**US\-05**|Quản trị viên|Cập nhật giá bán hàng loạt|Tôi có thể điều chỉnh nhiều giá bán nhanh hơn khi có thay đổi lớn về chính sách giá|
|**US\-06**|Chủ doanh nghiệp / Kế toán / Người kiểm soát|Kiểm tra lịch sử thay đổi giá bán|Tôi có thể truy vết ai đã thay đổi giá, thay đổi gì và thay đổi khi nào|
|**US\-07**|Quản lý cửa hàng / Quản trị viên|Nhận cảnh báo khi giá bán bất thường|Tôi có thể phát hiện sớm giá sai, giá thiếu hoặc giá có rủi ro trước khi ảnh hưởng tới bán hàng|

# 4\. Epic EP02 — Giá riêng / Nhớ giá

## 4\.1 Epic overview

Epic này xử lý **giá riêng theo khách hàng** và khả năng **ghi nhớ giá đã từng bán**, giúp doanh nghiệp duy trì quan hệ giá ổn định với khách quen\.

## 4\.x Domain Foundation

### Purpose

EP02 — Giá riêng / Nhớ giá quản lý các mức giá đặc biệt áp dụng cho khách hàng, bao gồm giá riêng được tạo thủ công, giá nhập từ Excel, giá được ghi nhớ từ lần bán hàng và dữ liệu migration nếu có\.

Epic này không tính giá cuối cùng của đơn hàng\. EP02 cung cấp rule giá đầu vào cho pricing engine và các màn quản trị để người dùng kiểm soát giá đặc biệt theo khách hàng, sản phẩm, đơn vị bán, hiệu lực, trạng thái, nguồn tạo và lịch sử thay đổi\.

### Business context

Trong vận hành bán lẻ và phân phối nhỏ, khách quen thường có mức giá riêng hoặc từng được bán với một mức giá cần được duy trì nhất quán ở các lần bán sau\. Nếu không quản lý tập trung, nhân viên dễ bán sai giá, khách hàng nhận báo giá không nhất quán, giá có thể thấp hơn giá sàn và chủ hộ không truy vết được ai đã tạo hoặc thay đổi giá\.

EP02 cần giúp người dùng trả lời được:

- Khách hàng này đang có giá riêng / nhớ giá nào?

- Giá đó áp dụng cho sản phẩm và đơn vị bán nào?

- Giá đang còn hiệu lực, đã tắt hay cần kiểm tra?

- Giá đến từ tạo thủ công, Excel, đơn hàng hay migration?

- Giá có thấp hơn giá sàn hoặc trùng rule khác không?

- Ai đã tạo, sửa, tắt, bật lại hoặc ghi nhận giá này?

### In scope

- Xem, tìm kiếm, lọc danh sách giá riêng / nhớ giá\.

- Xem chi tiết một rule giá riêng / nhớ giá\.

- Tạo giá riêng thủ công\.

- Nhập giá riêng bằng Excel với các cột: khách hàng, sản phẩm, giá, ngày bắt đầu optional, ngày kết thúc optional\.

- Resolve đơn vị bán khi import Excel không có cột đơn vị bán\.

- Sửa giá riêng / nhớ giá trong phạm vi field được phép\.

- Tắt và bật lại giá riêng / nhớ giá\.

- Ghi nhận nhớ giá từ lần bán hàng\.

- Kiểm tra rule trùng, hiệu lực, giá dưới sàn và dữ liệu không hợp lệ\.

- Ghi nhận lịch sử thay đổi và audit log\.

### Out of scope

- Quản lý giá bán mặc định / giá niêm yết / giá sàn gốc của sản phẩm\.

- Tính giá cuối cùng tại bán hàng sau khi kết hợp CTKM, ưu tiên chính sách và các rule khác\.

- Quản lý chương trình khuyến mại\.

- Xử lý ưu tiên khi nhiều loại chính sách giá cùng hợp lệ ngoài phạm vi duplicate rule của EP02\.

- Quản lý nhóm khách hàng nâng cao nếu chưa bật feature giá theo nhóm khách hàng\.

- Hạch toán kế toán, giá vốn, lợi nhuận gộp, công nợ và báo cáo tài chính\.

### Cross\-domain boundaries

|Related domain/module|Relationship with EP02|
|---|---|
|Theme 1 — Thiết lập cửa hàng|Cung cấp tenant, user, role, permission và audit actor\.|
|Theme 2 — Sản phẩm \& Giá bán|Cung cấp products, product\_units, giá hiện tại, giá sàn và default selling unit nếu có\.|
|Theme 3 — Khách hàng \& Nhà cung cấp|Cung cấp customers và trạng thái hợp lệ của khách hàng\.|
|Theme 5 — Bán hàng \& Đơn hàng|Gửi request lưu nhớ giá từ order/order line và đọc rule giá khi bán hàng\.|
|EP04 — Ưu tiên \& xung đột chính sách|Xử lý ưu tiên giữa giá riêng, giá nền, CTKM và các chính sách khác\.|
|EP05 — Giá áp dụng tại bán hàng|Đọc rule hợp lệ từ EP02 để hiển thị, áp dụng và giải thích giá tại POS/Order\.|
|EP06 — Lịch sử \& kiểm soát thay đổi|Có thể tổng hợp activity/audit từ EP02 cùng các phần khác của Theme 4\.|



### Domain map

|Domain|Purpose|Core responsibility|Related entities|
|---|---|---|---|
|Customer price rule|Quản lý rule giá riêng / nhớ giá theo khách hàng, sản phẩm và đơn vị bán\.|Lưu rule, trạng thái, hiệu lực, nguồn tạo và thông tin giá\.|`customer_price_rules`|
|Rule intake|Tiếp nhận dữ liệu tạo rule từ thủ công, Excel, Sales và migration\.|Parse, map, validate sơ bộ và chuyển thành create/update rule\.|`customer_price_rule_imports`, `customer_price_rule_import_rows`, `price_memory_requests`|
|Validation \& review|Kiểm tra tính hợp lệ trước khi rule được áp dụng hoặc bật lại\.|Kiểm tra customer/product/unit, giá, hiệu lực, duplicate, giá dưới sàn và permission override\.|`customer_price_rules`, `customer_price_rule_import_rows`|
|Lifecycle \& audit|Quản lý vòng đời rule và truy vết thay đổi\.|Ghi nhận tạo, sửa, tắt, bật lại, import, nhớ giá, blocked và các thay đổi quan trọng\.|`customer_price_rule_activities`|



### Domain model overview

EP02 lấy `customer_price_rules` làm entity trung tâm\. Mỗi rule biểu diễn một mức giá đặc biệt có thể áp dụng cho một khách hàng, một sản phẩm và một đơn vị bán cụ thể trong một khoảng hiệu lực\.

Rule có thể đến từ nhiều nguồn:

- `manual`: tạo thủ công\.

- `excel_import`: nhập từ Excel\.

- `sales_order`: ghi nhận nhớ giá từ đơn bán hàng\.

- `migration`: dữ liệu chuyển đổi từ hệ thống cũ hoặc file dữ liệu ban đầu\.

File Excel trong V1 chỉ yêu cầu các cột khách hàng, sản phẩm, giá, ngày bắt đầu optional và ngày kết thúc optional\. Vì file không có đơn vị bán, hệ thống phải resolve `product_unit_id` trước khi tạo hoặc cập nhật rule:

- Nếu sản phẩm chỉ có một đơn vị bán hợp lệ, dùng đơn vị đó\.

- Nếu sản phẩm có default selling unit rõ ràng, dùng default selling unit\.

- Nếu sản phẩm có nhiều đơn vị bán và không resolve được đơn vị mặc định, dòng import bị lỗi `ambiguous_product_unit`\.

- Nếu không tìm được đơn vị bán hợp lệ, dòng import bị lỗi `product_unit_not_found`\.

Core entity vẫn bắt buộc có `product_unit_id`, vì pricing engine cần biết giá áp dụng cho đơn vị bán nào\.

### Domain: Customer price rule

**Purpose**

Customer price rule là domain lõi của EP02, đại diện cho một giá riêng hoặc giá nhớ có thể được xét áp dụng khi bán hàng cho khách hàng cụ thể\.

**Business rules**

- CPR\-BR\-01: Mỗi rule phải thuộc một `tenant_id`\.

- CPR\-BR\-02: Mỗi rule phải gắn với một `customer_id`, một `product_id` và một `product_unit_id`\.

- CPR\-BR\-03: `rule_price` phải lớn hơn 0 và được lưu bằng kiểu Money/Decimal theo convention hệ thống\.

- CPR\-BR\-04: `effective_from` là bắt buộc trong core entity\. Nếu import Excel không có ngày bắt đầu, hệ thống default bằng ngày xác nhận import hoặc business date hiện tại\.

- CPR\-BR\-05: `effective_to` là optional\. Nếu không có ngày kết thúc, rule được hiểu là không giới hạn thời gian kết thúc\.

- CPR\-BR\-06: Nếu có `effective_to`, `effective_from` phải nhỏ hơn hoặc bằng `effective_to`\.

- CPR\-BR\-07: Không được có nhiều rule active trùng `tenant_id + customer_id + product_id + product_unit_id` và giao nhau về hiệu lực\.

- CPR\-BR\-08: Rule có `status = disabled` không được pricing engine áp dụng cho đơn hàng mới\.

- CPR\-BR\-09: Rule có `status = deleted` hoặc có `deleted_at` không được hiển thị trong danh sách mặc định và không được áp dụng\.

- CPR\-BR\-10: Rule đã hết hiệu lực được xác định bằng `effective_to < business_date`; đây là display/derived status, không nhất thiết phải đổi persisted `status`\.

- CPR\-BR\-11: Rule dưới giá sàn phải được đánh dấu warning hoặc blocked theo policy kiểm soát giá\.

- CPR\-BR\-12: Rule chỉ ảnh hưởng đơn hàng mới; đơn hàng cũ giữ snapshot giá đã bán\.

**Invariants**

- CPR\-INV\-01: `tenant_id`, `customer_id`, `product_id`, `product_unit_id`, `rule_price`, `rule_type`, `source_type`, `status`, `effective_from` không được null sau khi rule được tạo thành công\.

- CPR\-INV\-02: Một rule không được đồng thời có `status = active` và `deleted_at` khác null\.

- CPR\-INV\-03: Rule source `excel_import` phải có `source_import_id` và nên có `source_import_row_id`\.

- CPR\-INV\-04: Rule source `sales_order` phải có `source_order_id` và nên có `source_order_line_id`\.

- CPR\-INV\-05: Rule source `manual` phải có `created_by`\.

- CPR\-INV\-06: Bất kỳ thay đổi quan trọng nào của `rule_price`, `effective_from`, `effective_to`, `status`, `source_type` phải tạo activity tương ứng\.

**Lifecycle / state model**

Persisted lifecycle:

- `active`: rule đang hoạt động về mặt lifecycle; có thể được áp dụng nếu còn hiệu lực và không có lỗi blocking; action chính gồm view, edit, disable\.

- `disabled`: rule đã bị tắt; không áp dụng cho đơn hàng mới; action chính gồm view, edit nếu policy cho phép, reenable\.

- `needs_review`: rule cần kiểm tra do migration/import conflict, dữ liệu không hợp lệ hoặc policy yêu cầu review; không áp dụng nếu lỗi blocking; action chính gồm view, edit/fix, disable\.

- `deleted`: rule đã bị xóa mềm; không áp dụng; chỉ xem audit nếu có quyền\.

Derived display status:

- `đang_ap_dung`: `status = active`, business date nằm trong hiệu lực và không có lỗi blocking\.

- `da_tat`: `status = disabled`\.

- `het_hieu_luc`: `effective_to` khác null và `effective_to < business_date`\.

- `can_kiem_tra`: `status = needs_review` hoặc có warning/blocking chưa xử lý\.

- `da_xoa`: `status = deleted` hoặc `deleted_at` khác null\.

**Commands \& permissions**

- `list_customer_price_rules`: xem danh sách giá riêng / nhớ giá\. Permission: `pricing.customer_price_rule.view`\.

- `view_customer_price_rule`: xem chi tiết một rule\. Permission: `pricing.customer_price_rule.view`\.

- `create_customer_price_rule`: tạo rule thủ công\. Permission: `pricing.customer_price_rule.create`\.

- `update_customer_price_rule`: sửa giá, hiệu lực hoặc note của rule\. Permission: `pricing.customer_price_rule.update`\.

- `disable_customer_price_rule`: tắt rule đang hoạt động\. Permission: `pricing.customer_price_rule.disable`\.

- `reenable_customer_price_rule`: bật lại rule đã tắt sau khi pre\-check hợp lệ\. Permission: `pricing.customer_price_rule.reenable`\.

- `override_floor_price_warning`: cho phép lưu/bật lại rule dưới giá sàn nếu policy cho phép\. Permission: `pricing.customer_price_rule.override_floor_price`\.

- `delete_customer_price_rule`: xóa mềm rule nếu scope sau này cho phép\. Permission: `pricing.customer_price_rule.delete`\.

**Events**

- `customer_price_rule_created`: rule được tạo thành công\.

- `customer_price_rule_updated`: rule được cập nhật thành công\.

- `customer_price_rule_disabled`: rule được tắt thành công\.

- `customer_price_rule_reenabled`: rule được bật lại thành công\.

- `customer_price_rule_marked_needs_review`: rule bị đưa vào trạng thái cần kiểm tra\.

- `customer_price_rule_deleted`: rule bị xóa mềm\.

**API references**

- `GET /pricing/customer-price-rules`: danh sách, search, quick filter, advanced filter\.

- `GET /pricing/customer-price-rules/{id}`: xem chi tiết rule\.

- `POST /pricing/customer-price-rules`: tạo rule thủ công\.

- `PATCH /pricing/customer-price-rules/{id}`: sửa rule\.

- `POST /pricing/customer-price-rules/{id}/disable`: tắt rule\.

- `POST /pricing/customer-price-rules/{id}/reenable/precheck`: kiểm tra điều kiện bật lại\.

- `POST /pricing/customer-price-rules/{id}/reenable`: xác nhận bật lại rule\.

**Related entities**

- `tenants`: tenant sở hữu rule\.

- `customers`: khách hàng được áp dụng giá\.

- `products`: sản phẩm được áp dụng giá\.

- `product_units`: đơn vị bán được áp dụng giá\.

- `users`: người tạo/sửa/tắt/bật lại\.

- `customer_price_rule_activities`: lịch sử thay đổi của rule\.

### Domain: Rule intake

**Purpose**

Rule intake quản lý các luồng đưa dữ liệu vào EP02: tạo thủ công, nhập Excel, ghi nhận nhớ giá từ Sales và migration\. Domain này đảm bảo dữ liệu đầu vào được parse, map, validate và ghi nhận nguồn trước khi tạo hoặc cập nhật `customer_price_rules`\.

**Business rules**

- RI\-BR\-01: Tạo thủ công tạo rule source `manual`\.

- RI\-BR\-02: Import Excel tạo hoặc cập nhật rule source `excel_import`\.

- RI\-BR\-03: Ghi nhận nhớ giá từ bán hàng tạo hoặc cập nhật rule source `sales_order`\.

- RI\-BR\-04: Migration tạo rule source `migration` và có thể đánh dấu `needs_review` nếu thiếu dữ liệu tin cậy\.

- RI\-BR\-05: File import Excel V1 chỉ yêu cầu khách hàng, sản phẩm, giá, ngày bắt đầu optional và ngày kết thúc optional\.

- RI\-BR\-06: File import Excel không yêu cầu đơn vị bán, nhưng mỗi dòng hợp lệ phải resolve được `product_unit_id`\.

- RI\-BR\-07: Import phải có batch entity để lưu tổng quan file, trạng thái validate, trạng thái confirm và kết quả import\.

- RI\-BR\-08: Import phải có row entity để lưu từng dòng, dữ liệu raw, dữ liệu resolved, error/warning và kết quả create/update/skip\.

- RI\-BR\-09: Request nhớ giá từ Sales phải idempotent theo order/order line để tránh tạo/cập nhật trùng\.

- RI\-BR\-10: Nếu đã có giá riêng thủ công active cho cùng key, request nhớ giá từ Sales không tự ghi đè trừ khi policy cho phép\.

**Invariants**

- RI\-INV\-01: Mỗi import row phải thuộc đúng một import batch\.

- RI\-INV\-02: `row_number` là duy nhất trong một `import_id`\.

- RI\-INV\-03: Import row không được chuyển sang `imported` nếu còn error blocking\.

- RI\-INV\-04: Một memory request chỉ được xử lý một lần cho cùng `idempotency_key`\.

- RI\-INV\-05: Kết quả import hoặc memory request phải tạo activity nếu có tạo/cập nhật rule\.

**Lifecycle / state model**

Import batch status:

- `uploaded`: file đã upload, chưa validate xong\.

- `validating`: hệ thống đang parse và validate\.

- `ready_to_import`: có kết quả preview và có thể confirm import nếu có dòng hợp lệ\.

- `importing`: hệ thống đang thực hiện create/update rule\.

- `completed`: import hoàn tất toàn bộ dòng hợp lệ\.

- `completed_with_errors`: import hoàn tất một phần, có dòng lỗi/bỏ qua\.

- `failed`: import thất bại ở cấp batch\.

- `canceled`: người dùng hủy import trước khi confirm hoặc trong phạm vi cho phép\.

Import row status:

- `parsed`: dòng đã đọc được dữ liệu raw\.

- `valid`: dòng hợp lệ và có thể import\.

- `warning`: dòng có cảnh báo nhưng có thể import tùy policy\.

- `error`: dòng có lỗi blocking, không được import\.

- `imported`: dòng đã tạo/cập nhật rule thành công\.

- `skipped`: dòng bị bỏ qua theo policy hoặc do duplicate/update mode\.

- `failed`: dòng thất bại khi thực thi import\.

Memory request status:

- `received`: EP02 đã nhận request từ Sales\.

- `processed`: request đã tạo/cập nhật/skip thành công\.

- `blocked`: request bị chặn do rule nghiệp vụ hoặc permission\.

- `failed`: request lỗi kỹ thuật hoặc không xử lý được\.

- `skipped`: request hợp lệ nhưng không cần tạo/cập nhật rule\.

**Commands \& permissions**

- `upload_customer_price_rule_import`: upload file Excel\. Permission: `pricing.customer_price_rule.import`\.

- `validate_customer_price_rule_import`: parse và validate file\. Permission: `pricing.customer_price_rule.import`\.

- `confirm_customer_price_rule_import`: xác nhận import các dòng hợp lệ\. Permission: `pricing.customer_price_rule.import`\.

- `cancel_customer_price_rule_import`: hủy batch import nếu chưa hoàn tất\. Permission: `pricing.customer_price_rule.import`\.

- `download_customer_price_rule_import_template`: tải file mẫu Excel\. Permission: `pricing.customer_price_rule.import`\.

- `download_customer_price_rule_import_errors`: tải file lỗi/cảnh báo\. Permission: `pricing.customer_price_rule.import`\.

- `save_price_memory_request`: ghi nhận nhớ giá từ Sales\. Permission: `pricing.customer_price_rule.save_memory`\.

**Events**

- `customer_price_rule_import_uploaded`: file import được upload\.

- `customer_price_rule_import_validated`: batch import validate xong\.

- `customer_price_rule_import_confirmed`: người dùng xác nhận import\.

- `customer_price_rule_import_completed`: batch import hoàn tất\.

- `customer_price_rule_import_failed`: batch import thất bại\.

- `price_memory_request_received`: EP02 nhận request lưu nhớ giá từ Sales\.

- `price_memory_rule_saved`: request nhớ giá tạo/cập nhật rule thành công\.

- `price_memory_request_blocked`: request nhớ giá bị chặn\.

**API references**

- `GET /pricing/customer-price-rules/imports/template`: tải template Excel\.

- `POST /pricing/customer-price-rules/imports`: upload file import\.

- `GET /pricing/customer-price-rules/imports/{id}`: xem trạng thái batch và summary\.

- `GET /pricing/customer-price-rules/imports/{id}/rows`: xem preview từng dòng\.

- `POST /pricing/customer-price-rules/imports/{id}/confirm`: xác nhận import\.

- `POST /pricing/customer-price-rules/imports/{id}/cancel`: hủy import\.

- `GET /pricing/customer-price-rules/imports/{id}/errors`: tải file lỗi/cảnh báo\.

- `POST /pricing/price-memory-requests`: Sales gửi request lưu nhớ giá\.

**Related entities**

- `customer_price_rule_imports`: batch import Excel\.

- `customer_price_rule_import_rows`: dòng import Excel\.

- `price_memory_requests`: request nhớ giá từ Sales\.

- `customer_price_rules`: rule được tạo/cập nhật\.

- `orders`: đơn bán hàng nguồn của nhớ giá\.

- `order_lines`: dòng đơn hàng nguồn của nhớ giá\.

- `users`: người upload/import/xác nhận lưu nhớ giá\.

### Domain: Validation \& review

**Purpose**

Validation \& review đảm bảo rule chỉ được tạo, sửa, bật lại hoặc áp dụng khi đủ điều kiện nghiệp vụ\. Domain này xử lý các lỗi và cảnh báo như khách hàng không hợp lệ, sản phẩm không hợp lệ, không resolve được đơn vị bán, giá không hợp lệ, hiệu lực sai, trùng rule và giá dưới sàn\.

**Business rules**

- VR\-BR\-01: Customer phải tồn tại trong tenant hiện tại và ở trạng thái được phép giao dịch nếu rule được active\.

- VR\-BR\-02: Product phải tồn tại trong tenant hiện tại và ở trạng thái được phép bán nếu rule được active\.

- VR\-BR\-03: Product unit phải thuộc product và được phép dùng làm đơn vị bán\.

- VR\-BR\-04: Với import Excel, `product_unit_id` phải được resolve trước khi row được coi là valid\.

- VR\-BR\-05: Giá phải parse được thành Money/Decimal hợp lệ và lớn hơn 0\.

- VR\-BR\-06: Hiệu lực phải hợp lệ: `effective_from <= effective_to` nếu có `effective_to`\.

- VR\-BR\-07: Rule active không được giao hiệu lực với rule active khác cùng customer, product và product unit\.

- VR\-BR\-08: Giá dưới giá sàn phải được đánh dấu `below_floor_price`; policy quyết định warning hay blocking\.

- VR\-BR\-09: Khi lưu, import hoặc bật lại rule, hệ thống phải re\-check dữ liệu mới nhất để tránh stale validation\.

- VR\-BR\-10: User không có quyền override không được xác nhận thao tác nếu policy xem dưới giá sàn là blocking\.

**Invariants**

- VR\-INV\-01: Rule không được chuyển sang trạng thái áp dụng nếu còn lỗi blocking\.

- VR\-INV\-02: Import row không được marked `valid` nếu thiếu `customer_id`, `product_id`, `product_unit_id`, `rule_price` hoặc `effective_from`\.

- VR\-INV\-03: Mọi validation warning/error của import row phải được lưu lại đủ để hiển thị preview và tải file lỗi\.

- VR\-INV\-04: Validation tại thời điểm preview không thay thế validation tại thời điểm confirm/save\.

**Validation outcomes**

- `valid`: dữ liệu hợp lệ, không có warning/blocking\.

- `warning`: có cảnh báo nhưng có thể tiếp tục nếu policy cho phép\. Ví dụ: `below_floor_price`, `price_higher_than_current_price`, `missing_optional_effective_to`\.

- `blocked`: có lỗi nghiệp vụ, không được lưu/import/bật lại\. Ví dụ: `customer_not_found`, `product_not_found`, `ambiguous_product_unit`, `duplicate_active_rule`, `invalid_effective_period`, `price_must_be_positive`\.

- `needs_review`: dữ liệu cần người dùng kiểm tra trước khi được tin cậy hoàn toàn\. Ví dụ: `migration_missing_audit`, `manual_review_required`, `source_data_changed`\.

**Commands \& permissions**

- `validate_customer_price_rule`: validate rule khi tạo/sửa\. Permission: theo command gốc\.

- `precheck_customer_price_rule_reenable`: kiểm tra trước khi bật lại\. Permission: `pricing.customer_price_rule.reenable`\.

- `validate_customer_price_rule_import_row`: validate từng dòng import\. Permission: `pricing.customer_price_rule.import`\.

- `resolve_import_customer`: resolve customer từ file Excel\. Permission: `pricing.customer_price_rule.import`\.

- `resolve_import_product`: resolve product từ file Excel\. Permission: `pricing.customer_price_rule.import`\.

- `resolve_import_product_unit`: resolve product unit khi file không có unit\. Permission: `pricing.customer_price_rule.import`\.

**Events**

- `customer_price_rule_validation_failed`: rule create/update/reenable bị chặn\.

- `customer_price_rule_below_floor_detected`: giá rule thấp hơn giá sàn\.

- `customer_price_rule_duplicate_detected`: phát hiện rule trùng/giao hiệu lực\.

- `customer_price_rule_import_row_validated`: một dòng import được validate xong\.

**API references**

- `POST /pricing/customer-price-rules/validate`: validate dữ liệu tạo/sửa rule\.

- `POST /pricing/customer-price-rules/{id}/reenable/precheck`: pre\-check bật lại\.

- `GET /pricing/customer-price-rules/imports/{id}/rows`: xem validation outcome theo từng dòng import\.

**Related entities**

- `customer_price_rules`: rule được validate\.

- `customer_price_rule_import_rows`: lưu kết quả validate từng dòng\.

- `customers`: kiểm tra khách hàng\.

- `products`: kiểm tra sản phẩm\.

- `product_units`: kiểm tra/resolve đơn vị bán\.

### Domain: Lifecycle \& audit

**Purpose**

Lifecycle \& audit ghi nhận vòng đời và lịch sử thay đổi của rule để phục vụ kiểm soát, đối soát và truy vết\. Domain này đảm bảo mọi thao tác quan trọng đều có dấu vết: ai làm, làm lúc nào, nguồn nào, thay đổi gì, lý do là gì và tác động đến rule nào\.

**Business rules**

- LA\-BR\-01: Tạo rule phải ghi activity `created`, `imported` hoặc `memory_saved` tùy nguồn\.

- LA\-BR\-02: Sửa `rule_price`, `effective_from`, `effective_to`, `status`, `review_status` hoặc field quan trọng phải ghi activity `updated`\.

- LA\-BR\-03: Tắt rule phải ghi activity `disabled`, gồm actor, thời gian và lý do nếu có\.

- LA\-BR\-04: Bật lại rule phải ghi activity `reenabled` sau khi pre\-check hợp lệ\.

- LA\-BR\-05: Import phải ghi activity ở cấp rule và giữ trace về `import_id`, `import_row_id`\.

- LA\-BR\-06: Nhớ giá từ Sales phải giữ trace về `order_id`, `order_line_id` và actor nếu có\.

- LA\-BR\-07: Activity không được sửa nội dung cũ sau khi ghi, trừ metadata kỹ thuật nếu có policy riêng\.

- LA\-BR\-08: Activity cần lưu `old_value` và `new_value` dạng JSON/Object cho các thay đổi quan trọng\.

**Invariants**

- LA\-INV\-01: Mỗi activity phải thuộc một tenant\.

- LA\-INV\-02: Activity liên quan trực tiếp rule phải có `customer_price_rule_id`\.

- LA\-INV\-03: Activity từ import phải giữ `import_id` hoặc `import_row_id` nếu có\.

- LA\-INV\-04: Activity từ Sales phải giữ `order_id` hoặc `order_line_id` nếu có\.

- LA\-INV\-05: Activity phải có `activity_type`, `source_type` và `created_at`\.

**Commands \& permissions**

- `list_customer_price_rule_activities`: xem lịch sử thay đổi của rule\. Permission: `pricing.customer_price_rule.view_history`\.

- `create_customer_price_rule_activity`: ghi activity nội bộ sau thao tác\. Permission: system/internal\.

- `export_customer_price_rule_activities`: xuất lịch sử nếu sau này cần\. Permission: `pricing.customer_price_rule.export_history`\.

**Events**

- `customer_price_rule_activity_recorded`: activity được ghi thành công\.

- `customer_price_rule_history_viewed`: user xem lịch sử nếu cần audit event\.

**API references**

- `GET /pricing/customer-price-rules/{id}/activities`: xem lịch sử theo rule\.

- `GET /pricing/customer-price-rule-activities`: xem lịch sử toàn EP02 nếu có quyền\.

**Related entities**

- `customer_price_rule_activities`: entity log chính\.

- `customer_price_rules`: rule được ghi lịch sử\.

- `customer_price_rule_imports`: batch import liên quan\.

- `customer_price_rule_import_rows`: dòng import liên quan\.

- `price_memory_requests`: request nhớ giá liên quan\.

- `orders`: đơn hàng nguồn nếu từ Sales\.

- `order_lines`: dòng đơn hàng nguồn nếu từ Sales\.

- `users`: actor thực hiện thao tác\.

## 4\.x Data \& Entities

### Relationship model

EP02\-owned entities:

- `customer_price_rules` là core entity\.

- `customer_price_rule_imports` là batch import Excel\.

- `customer_price_rule_import_rows` là từng dòng import Excel\.

- `price_memory_requests` là request lưu nhớ giá từ Sales\.

- `customer_price_rule_activities` là log/audit của rule\.

Referenced entities:

- `tenants`, `users`, `customers`, `products`, `product_units`, `orders`, `order_lines`\.

Relationship summary:

|Relationship|Meaning|
|---|---|
|`tenants` 1\-n `customer_price_rules`|Mỗi rule thuộc một tenant\.|
|`customers` 1\-n `customer_price_rules`|Một khách hàng có thể có nhiều rule giá riêng / nhớ giá\.|
|`products` 1\-n `customer_price_rules`|Một sản phẩm có thể có nhiều rule theo khách hàng/đơn vị bán\.|
|`product_units` 1\-n `customer_price_rules`|Một đơn vị bán có thể được nhiều rule tham chiếu\.|
|`customer_price_rule_imports` 1\-n `customer_price_rule_import_rows`|Một batch import có nhiều dòng\.|
|`customer_price_rule_imports` 1\-n `customer_price_rules`|Một batch import có thể tạo/cập nhật nhiều rule\.|
|`customer_price_rule_import_rows` 0/1\-n `customer_price_rules`|Một dòng import có thể tạo/cập nhật một rule\.|
|`orders` 1\-n `price_memory_requests`|Một đơn hàng có thể phát sinh nhiều request nhớ giá\.|
|`order_lines` 1\-n `price_memory_requests`|Một dòng đơn có thể phát sinh một request nhớ giá idempotent\.|
|`price_memory_requests` 0/1\-n `customer_price_rules`|Request có thể tạo/cập nhật một rule\.|
|`customer_price_rules` 1\-n `customer_price_rule_activities`|Một rule có nhiều activity\.|
|`users` 1\-n EP02 entities|User có thể tạo, sửa, import, tắt, bật lại hoặc xác nhận lưu nhớ giá\.|

### Entity relationship diagram

```mermaid
erDiagram
    tenants ||--o{ customer_price_rules : owns
    tenants ||--o{ customer_price_rule_imports : owns
    tenants ||--o{ customer_price_rule_import_rows : owns
    tenants ||--o{ price_memory_requests : owns
    tenants ||--o{ customer_price_rule_activities : owns

    customers ||--o{ customer_price_rules : has
    products ||--o{ customer_price_rules : has
    product_units ||--o{ customer_price_rules : has

    customer_price_rule_imports ||--o{ customer_price_rule_import_rows : contains
    customer_price_rule_imports ||--o{ customer_price_rules : creates_or_updates
    customer_price_rule_import_rows ||--o| customer_price_rules : creates_or_updates

    orders ||--o{ price_memory_requests : triggers
    order_lines ||--o{ price_memory_requests : triggers
    price_memory_requests ||--o| customer_price_rules : creates_or_updates

    customer_price_rules ||--o{ customer_price_rule_activities : records
    customer_price_rule_imports ||--o{ customer_price_rule_activities : traces
    customer_price_rule_import_rows ||--o{ customer_price_rule_activities : traces
    price_memory_requests ||--o{ customer_price_rule_activities : traces
    orders ||--o{ customer_price_rule_activities : traces
    order_lines ||--o{ customer_price_rule_activities : traces

    users ||--o{ customer_price_rules : creates_or_updates
    users ||--o{ customer_price_rule_imports : uploads_or_confirms
    users ||--o{ price_memory_requests : confirms
    users ||--o{ customer_price_rule_activities : acts```

### Entity catalog

|Scope|Entity|Ownership|Purpose|Notes|
|---|---|---|---|---|
|Core|`customer_price_rules`|EP02|Lưu rule giá riêng / nhớ giá theo customer × product × product unit\.|Core entity quan trọng nhất của EP02\.|
|Import|`customer_price_rule_imports`|EP02|Lưu một batch import Excel\.|Cần cho upload, validate, preview, confirm, result và audit\.|
|Import detail|`customer_price_rule_import_rows`|EP02|Lưu từng dòng Excel sau parse/validate\.|Cần cho row\-level error/warning và create/update trace\.|
|Integration|`price_memory_requests`|EP02|Lưu request nhớ giá từ Sales\.|Cần idempotency và trace về order/order line\.|
|Log|`customer_price_rule_activities`|EP02|Lưu lịch sử thay đổi rule\.|Phục vụ US\-10 và audit\.|
|Referenced|`tenants`|Theme 1|Tenant sở hữu dữ liệu\.|EP02 chỉ tham chiếu\.|
|Referenced|`users`|Theme 1|Người thao tác / actor\.|EP02 chỉ tham chiếu\.|
|Referenced|`customers`|Theme 3|Khách hàng áp dụng giá\.|EP02 chỉ tham chiếu\.|
|Referenced|`products`|Theme 2|Sản phẩm áp dụng giá\.|EP02 chỉ tham chiếu\.|
|Referenced|`product_units`|Theme 2|Đơn vị bán áp dụng giá\.|EP02 chỉ tham chiếu và resolve khi import\.|
|Referenced|`orders`|Theme 5|Đơn bán hàng nguồn cho nhớ giá\.|EP02 chỉ tham chiếu\.|
|Referenced|`order_lines`|Theme 5|Dòng đơn hàng nguồn cho nhớ giá\.|EP02 chỉ tham chiếu\.|

### Entity fields

#### `customer_price_rules`

|Field|Type|Required|Key|FK target|Notes|
|---|---|---|---|---|---|
|`id`|UUID|Yes|PK|—|Primary key\.|
|`tenant_id`|UUID|Yes|FK|`tenants.id`|Tenant sở hữu rule\.|
|`customer_id`|UUID|Yes|FK|`customers.id`|Khách hàng áp dụng giá\.|
|`product_id`|UUID|Yes|FK|`products.id`|Sản phẩm áp dụng giá\.|
|`product_unit_id`|UUID|Yes|FK|`product_units.id`|Đơn vị bán áp dụng giá; bắt buộc dù import không có cột đơn vị\.|
|`rule_price`|Money|Yes|—|—|Giá riêng / giá nhớ được lưu\.|
|`currency_code`|text|Yes|—|—|Default `VND`\.|
|`rule_type`|enum|Yes|—|—|Suggested values: `special_price`, `remembered_price`\.|
|`source_type`|enum|Yes|—|—|Suggested values: `manual`, `excel_import`, `sales_order`, `migration`\.|
|`status`|enum|Yes|—|—|Suggested values: `active`, `disabled`, `needs_review`, `deleted`\.|
|`review_status`|enum|Yes|—|—|Suggested values: `clear`, `warning`, `blocked`, `needs_review`\.|
|`effective_from`|date|Yes|—|—|Ngày bắt đầu\. Nếu import bỏ trống thì default ngày xác nhận import/business date\.|
|`effective_to`|date|No|—|—|Null nghĩa là không giới hạn ngày kết thúc\.|
|`listed_price_snapshot`|Money|No|—|—|Giá hiện tại/giá niêm yết tại thời điểm check nếu cần audit\.|
|`floor_price_snapshot`|Money|No|—|—|Giá sàn tại thời điểm check nếu user/policy cho phép lưu snapshot\.|
|`price_check_status`|enum|Yes|—|—|Suggested values: `not_checked`, `normal`, `below_floor_warning`, `below_floor_blocked`, `override_allowed`\.|
|`warning_codes`|JSON/Object|No|—|—|Danh sách warning như `below_floor_price`\.|
|`blocking_codes`|JSON/Object|No|—|—|Danh sách lỗi blocking nếu rule cần review\.|
|`source_import_id`|UUID|No|FK|`customer_price_rule_imports.id`|Batch import nguồn nếu source là Excel\.|
|`source_import_row_id`|UUID|No|FK|`customer_price_rule_import_rows.id`|Dòng import nguồn nếu source là Excel\.|
|`source_order_id`|UUID|No|FK|`orders.id`|Đơn hàng nguồn nếu source là Sales\.|
|`source_order_line_id`|UUID|No|FK|`order_lines.id`|Dòng đơn nguồn nếu source là Sales\.|
|`note`|text|No|—|—|Ghi chú nghiệp vụ nếu cần\.|
|`disabled_at`|datetime|No|—|—|Thời điểm tắt rule\.|
|`disabled_by`|UUID|No|FK|`users.id`|Người tắt rule\.|
|`disabled_reason`|text|No|—|—|Lý do tắt nếu có\.|
|`created_by`|UUID|No|FK|`users.id`|User tạo; có thể null với migration/system\.|
|`updated_by`|UUID|No|FK|`users.id`|User cập nhật gần nhất\.|
|`created_at`|datetime|Yes|—|—|Thời điểm tạo\.|
|`updated_at`|datetime|Yes|—|—|Thời điểm cập nhật gần nhất\.|
|`deleted_at`|datetime|No|—|—|Soft delete timestamp nếu có\.|

#### `customer_price_rule_imports`

|Field|Type|Required|Key|FK target|Notes|
|---|---|---|---|---|---|
|`id`|UUID|Yes|PK|—|Primary key\.|
|`tenant_id`|UUID|Yes|FK|`tenants.id`|Tenant sở hữu batch import\.|
|`template_version`|text|Yes|—|—|Ví dụ `customer_price_rules_v1`\.|
|`original_file_name`|text|Yes|—|—|Tên file người dùng upload\.|
|`file_storage_key`|text|No|—|—|Key lưu file nếu hệ thống lưu file\.|
|`status`<br>|enum|Yes|—|—|Suggested values: `uploaded`, `validating`, `ready_to_import`, `importing`, `completed`, `completed_with_errors`, `failed`, `canceled`\.|
|`import_mode`|enum|Yes|—|—|Suggested values: `create_only`, `update_only`, `upsert`\.|
|`total_rows`|integer|Yes|—|—|Tổng số dòng dữ liệu đọc được\.|
|`valid_rows`|integer|Yes|—|—|Số dòng hợp lệ\.|
|`warning_rows`|integer|Yes|—|—|Số dòng có warning\.|
|`error_rows`|integer|Yes|—|—|Số dòng lỗi blocking\.|
|`imported_rows`|integer|No|—|—|Số dòng đã import thành công\.|
|`skipped_rows`|integer|No|—|—|Số dòng bị bỏ qua\.|
|`failed_rows`|integer|No|—|—|Số dòng fail trong lúc thực thi import\.|
|`summary_json`|JSON/Object|No|—|—|Summary linh hoạt cho preview/result\.|
|`created_by`|UUID|Yes|FK|`users.id`|User upload file\.|
|`confirmed_by`|UUID|No|FK|`users.id`|User xác nhận import\.|
|`confirmed_at`|datetime|No|—|—|Thời điểm xác nhận import\.|
|`created_at`|datetime|Yes|—|—|Thời điểm tạo batch\.|
|`updated_at`|datetime|Yes|—|—|Thời điểm cập nhật batch\.|

#### `customer_price_rule_import_rows`

|Field|Type|Required|Key|FK target|Notes|
|---|---|---|---|---|---|
|`id`|UUID|Yes|PK|—|Primary key\.|
|`tenant_id`|UUID|Yes|FK|`tenants.id`|Tenant sở hữu dòng import\.|
|`import_id`|UUID|Yes|FK|`customer_price_rule_imports.id`|Batch import cha\.|
|`row_number`|integer|Yes|—|—|Số dòng trong file Excel\. Unique trong `import_id`\.|
|`raw_customer_ref`|text|Yes|—|—|Giá trị khách hàng từ Excel; có thể là mã, tên, SĐT hoặc định danh được template hỗ trợ\.|
|`raw_product_ref`|text|Yes|—|—|Giá trị sản phẩm từ Excel; có thể là mã, tên, SKU hoặc barcode được template hỗ trợ\.|
|`raw_price`|text|Yes|—|—|Giá raw từ Excel\.|
|`raw_effective_from`|text|No|—|—|Ngày bắt đầu raw từ Excel\.|
|`raw_effective_to`|text|No|—|—|Ngày kết thúc raw từ Excel\.|
|`customer_id`|UUID|No|FK|`customers.id`|Customer resolved\.|
|`product_id`|UUID|No|FK|`products.id`|Product resolved\.|
|`product_unit_id`|UUID|No|FK|`product_units.id`|Product unit resolved\. Bắt buộc trước khi row valid\.|
|`unit_resolution_strategy`|enum|No|—|—|Suggested values: `single_unit`, `default_selling_unit`, `ambiguous`, `not_found`\.|
|`rule_price`|Money|No|—|—|Giá đã parse\.|
|`effective_from`|date|No|—|—|Ngày bắt đầu đã parse/default\.|
|`effective_to`|date|No|—|—|Ngày kết thúc đã parse; null là không giới hạn\.|
|`row_status`|enum|Yes|—|—|Suggested values: `parsed`, `valid`, `warning`, `error`, `imported`, `skipped`, `failed`\.|
|`action_type`|enum|No|—|—|Suggested values: `create`, `update`, `skip`\.|
|`error_codes`|JSON/Object|No|—|—|Ví dụ `customer_not_found`, `product_not_found`, `ambiguous_product_unit`, `invalid_price`\.|
|`warning_codes`|JSON/Object|No|—|—|Ví dụ `below_floor_price`\.|
|`matched_rule_id`|UUID|No|FK|`customer_price_rules.id`|Rule hiện có nếu dòng match để update hoặc bị duplicate\.|
|`created_rule_id`|UUID|No|FK|`customer_price_rules.id`|Rule được tạo mới từ dòng này\.|
|`updated_rule_id`|UUID|No|FK|`customer_price_rules.id`|Rule được cập nhật từ dòng này\.|
|`old_value`|JSON/Object|No|—|—|Snapshot cũ nếu update\.|
|`new_value`|JSON/Object|No|—|—|Snapshot normalized sau parse/validate\.|
|`created_at`|datetime|Yes|—|—|Thời điểm tạo dòng import\.|
|`updated_at`|datetime|Yes|—|—|Thời điểm cập nhật dòng import\.|

#### `price_memory_requests`

|Field|Type|Required|Key|FK target|Notes|
|---|---|---|---|---|---|
|`id`|UUID|Yes|PK|—|Primary key\.|
|`tenant_id`|UUID|Yes|FK|`tenants.id`|Tenant sở hữu request\.|
|`source_order_id`|UUID|Yes|FK|`orders.id`|Đơn bán hàng nguồn\.|
|`source_order_line_id`|UUID|Yes|FK|`order_lines.id`|Dòng đơn nguồn\.|
|`customer_id`|UUID|Yes|FK|`customers.id`|Khách hàng cụ thể; không dùng khách lẻ mặc định nếu không có định danh\.|
|`product_id`|UUID|Yes|FK|`products.id`|Sản phẩm đã bán\.|
|`product_unit_id`|UUID|Yes|FK|`product_units.id`|Đơn vị bán thực tế trong order line\.|
|`sold_price`|Money|Yes|—|—|Giá đã bán thực tế cần ghi nhớ\.|
|`currency_code`|text|Yes|—|—|Default `VND`\.|
|`sold_at`|datetime|Yes|—|—|Thời điểm bán hoặc hoàn tất đơn theo rule Sales\.|
|`actor_user_id`|UUID|No|FK|`users.id`|Người xác nhận lưu giá nếu có\.|
|`status`|enum|Yes|—|—|Suggested values: `received`, `processed`, `blocked`, `failed`, `skipped`\.|
|`result_type`|enum|No|—|—|Suggested values: `created`, `updated`, `skipped`, `blocked`, `no_permission`, `error`\.|
|`customer_price_rule_id`|UUID|No|FK|`customer_price_rules.id`|Rule được tạo/cập nhật nếu xử lý thành công\.|
|`idempotency_key`|text|Yes|Unique|—|Key chống xử lý trùng request\.|
|`blocked_reason`|text|No|—|—|Lý do bị chặn nếu có\.|
|`error_message`|text|No|—|—|Lỗi kỹ thuật nếu có\.|
|`created_at`|datetime|Yes|—|—|Thời điểm nhận request\.|
|`processed_at`|datetime|No|—|—|Thời điểm xử lý xong\.|

#### `customer_price_rule_activities`

|Field|Type|Required|Key|FK target|Notes|
|---|---|---|---|---|---|
|`id`|UUID|Yes|PK|—|Primary key\.|
|`tenant_id`|UUID|Yes|FK|`tenants.id`|Tenant sở hữu activity\.|
|`customer_price_rule_id`|UUID|Yes|FK|`customer_price_rules.id`|Rule liên quan\.|
|`activity_type`|enum|Yes|—|—|Suggested values: `created`, `updated`, `disabled`, `reenabled`, `imported`, `memory_saved`, `memory_updated`, `blocked`, `deleted`, `marked_needs_review`\.|
|`actor_user_id`|UUID|No|FK|`users.id`|User thực hiện; có thể null nếu system/migration\.|
|`source_type`|enum|Yes|—|—|Suggested values: `manual`, `excel_import`, `sales_order`, `migration`, `system`\.|
|`import_id`|UUID|No|FK|`customer_price_rule_imports.id`|Batch import liên quan nếu có\.|
|`import_row_id`|UUID|No|FK|`customer_price_rule_import_rows.id`|Dòng import liên quan nếu có\.|
|`price_memory_request_id`|UUID|No|FK|`price_memory_requests.id`|Request nhớ giá liên quan nếu có\.|
|`source_order_id`|UUID|No|FK|`orders.id`|Đơn hàng nguồn nếu có\.|
|`source_order_line_id`|UUID|No|FK|`order_lines.id`|Dòng đơn nguồn nếu có\.|
|`old_value`|JSON/Object|No|—|—|Snapshot trước thay đổi\.|
|`new_value`|JSON/Object|No|—|—|Snapshot sau thay đổi\.|
|`reason`|text|No|—|—|Lý do sửa/tắt/bật lại nếu có\.|
|`created_at`|datetime|Yes|—|—|Thời điểm ghi activity\.|

## 4\.2 User stories

|**ID**|**As user**|**I want to do**|**So that**|
|---|---|---|---|
|**US\-01**|Chủ cửa hàng<br>|Xem, tìm kiếm, lọc và kiểm tra danh sách giá riêng / nhớ giá|Tôi có thể kiểm soát các mức giá đặc biệt đang áp dụng cho khách hàng|
|**US\-02**|Chủ cửa hàng|Chọn cách thêm giá riêng|Tôi có thể thêm giá riêng thủ công hoặc nhập bằng Excel tùy theo số lượng dữ liệu|
|**US\-03**|Chủ cửa hàng|Xem chi tiết một giá riêng|Tôi có thể kiểm tra khách hàng, sản phẩm, mức giá, trạng thái và lịch sử liên quan|
|**US\-04**|Chủ cửa hàng|Tạo giá riêng thủ công|Tôi có thể thiết lập giá đặc biệt cho một khách hàng hoặc nhóm khách hàng cụ thể|
|**US\-05**|Chủ cửa hàng|Nhập giá riêng bằng Excel|Tôi có thể tạo hoặc cập nhật nhiều giá riêng nhanh hơn khi có dữ liệu lớn|
|**US\-06**|Chủ cửa hàng|Sửa giá riêng|Tôi có thể điều chỉnh giá riêng khi có thay đổi thỏa thuận với khách hàng|
|**US\-07**|Chủ cửa hàng|Tắt giá riêng|Tôi có thể ngừng áp dụng giá riêng khi giá đó không còn phù hợp|
|**US\-08**|Chủ cửa hàng|Bật lại giá riêng|Tôi có thể áp dụng lại giá riêng đã tắt khi cần tiếp tục chính sách cũ|
|**US\-09**|Nhân viên bán hàng / Chủ cửa hàng|Nhận lưu nhớ giá khi bán hàng|Tôi có thể bán lại cho khách theo mức giá quen thuộc một cách nhất quán|
|**US\-10**|Chủ doanh nghiệp / Kế toán |Kiểm tra lịch sử thay đổi giá riêng|Tôi có thể truy vết các thay đổi liên quan đến giá riêng của khách hàng|

### 4\.2\.1 US\-01 — Xem, tìm kiếm, lọc và kiểm tra danh sách giá riêng / nhớ giá

#### 4\.2\.1\.1 Business context

US\-01 là màn hình entry chính của Epic EP02 — Giá riêng / Nhớ giá\. Màn hình này giúp Quản lý cửa hàng hoặc Quản trị viên kiểm soát các mức giá đặc biệt đang áp dụng cho khách hàng, bao gồm giá riêng được tạo thủ công và giá nhớ được hệ thống ghi nhận hoặc nhập từ dữ liệu bên ngoài\.

Trong vận hành thực tế, người dùng cần nhanh chóng biết khách hàng nào đang có giá riêng, sản phẩm nào có mức giá đặc biệt, giá đó còn đang áp dụng không, có thấp hơn giá sàn không và có rule nào cần kiểm tra trước khi ảnh hưởng tới bán hàng\.

US này chỉ tập trung vào danh sách, tìm kiếm, lọc, kiểm tra nhanh trạng thái/cảnh báo và điều hướng\. Các nghiệp vụ chọn cách thêm, tạo thủ công, nhập Excel, xem chi tiết, sửa, tắt, bật lại, gợi ý nhớ giá khi bán hàng và kiểm tra lịch sử đầy đủ sẽ được xử lý ở các US tiếp theo trong EP02\.

#### 4\.2\.1\.2 Functional requirements

|ID|Functional Requirement|Acceptance Criteria|
|---|---|---|
|**FR\-01**<br>|Hiển thị danh sách giá riêng / nhớ giá|Người dùng có quyền có thể xem danh sách giá riêng / nhớ giá thuộc tenant hiện tại|
|**FR\-02**|Hiển thị thông tin tóm tắt của từng giá riêng|Mỗi item hiển thị khách hàng, sản phẩm, đơn vị bán, giá riêng / giá nhớ, trạng thái và cảnh báo chính nếu có|
|**FR\-03**|Tìm kiếm giá riêng / nhớ giá|Người dùng có thể tìm theo tên khách hàng, mã khách hàng, tên sản phẩm, mã sản phẩm hoặc SKU|
|**FR\-04**|Lọc nhanh theo nhóm nghiệp vụ chính|Người dùng có thể lọc nhanh theo `Tất cả`, `Đang áp dụng`, `Dưới giá sàn`|
|**FR\-05**|Lọc nâng cao danh sách giá riêng / nhớ giá|Người dùng có thể lọc trạng thái, nguồn tạo và thời gian cập nhật nếu hệ thống hỗ trợ|
|**FR\-06**|Hiển thị cảnh báo cần kiểm tra|Giá riêng có rủi ro như dưới giá sàn, dữ liệu không hợp lệ hoặc trùng rule phải được đánh dấu rõ ràng|
|**FR\-07**|Điều hướng từ danh sách|Người dùng có thể mở chi tiết một giá riêng hoặc bấm CTA `+` để chuyển sang US\-02 — Chọn cách thêm giá riêng|

#### 4\.2\.1\.3 Business rules

|ID|Business Rule|
|---|---|
|**BR\-01**|Danh sách chỉ hiển thị dữ liệu thuộc tenant hiện tại và trong phạm vi quyền của người dùng|
|**BR\-02**|Mỗi giá riêng / nhớ giá phải gắn với khách hàng hoặc nhóm khách hàng, sản phẩm và đơn vị bán cụ thể|
|**BR\-03**|Giá riêng được xem là `Đang áp dụng` khi rule active, còn hiệu lực và không có lỗi blocking|
|**BR\-04**|Giá riêng đã tắt hoặc hết hiệu lực không được áp dụng cho đơn hàng mới nhưng vẫn có thể hiển thị để kiểm tra|
|**BR\-05**|Giá riêng thấp hơn giá sàn hiện tại phải hiển thị cảnh báo `Dưới giá sàn`|
|**BR\-06**|Không được có nhiều rule active trùng khách hàng, sản phẩm, đơn vị bán và giao nhau về hiệu lực|
|**BR\-07**|Người dùng không có quyền xem dữ liệu nhạy cảm sẽ bị ẩn giá sàn hoặc bị chặn truy cập theo policy phân quyền|

#### 4\.2\.1\.4 UI Contract

##### 4\.2\.1\.4\.1 Mục tiêu màn hình

Màn hình danh sách giúp người dùng kiểm soát nhanh các giá riêng / nhớ giá đang tồn tại, phát hiện giá cần xử lý và điều hướng sang các flow liên quan\.

##### 4\.2\.1\.4\.2 Entry point

|Entry point|Hành vi|
|---|---|
|**More / Chính sách giá → Giá riêng / Nhớ giá**|Mở danh sách toàn bộ giá riêng / nhớ giá|
|**Chi tiết khách hàng → Giá riêng / Nhớ giá**|Mở danh sách đã lọc theo khách hàng đang xem|
|**Chi tiết sản phẩm → Giá riêng / Nhớ giá**|Mở danh sách đã lọc theo sản phẩm đang xem|
|**Sau khi tạo / nhập / sửa / tắt / bật lại**|Quay lại danh sách và cập nhật trạng thái item liên quan|

##### 4\.2\.1\.4\.3 Cấu trúc màn hình

|Khu vực|Nội dung|
|---|---|
|**Top bar**|Back icon `←` nếu có màn trước đó, title `Giá riêng / Nhớ giá`|
|**Search**|Ô tìm kiếm theo khách hàng hoặc sản phẩm|
|**Quick filters**|`Tất cả`, `Đang áp dụng`, `Dưới giá sàn`|
|**Filter nâng cao**|Icon filter mở màn / sheet lọc nâng cao|
|**Danh sách item**|Danh sách giá riêng / nhớ giá dạng card hoặc list item|
|**CTA thêm mới**|CTA `+` để đi sang US\-02 nếu người dùng có quyền|

##### 4\.2\.1\.4\.4 Thông tin trên mỗi item

|Thành phần|Mô tả|
|---|---|
|**Khách hàng**|Tên khách hàng được áp dụng giá riêng|
|**Sản phẩm**|Tên sản phẩm, mã sản phẩm hoặc SKU|
|**Đơn vị bán**|Đơn vị áp dụng giá, ví dụ lọ, hộp, gói, thùng|
|**Giá riêng / Giá nhớ**|Mức giá đặc biệt đang được lưu|
|**Trạng thái**|`Đang áp dụng`, `Đã tắt`, `Hết hiệu lực`, `Cần kiểm tra`|
|**Cảnh báo**|`Dưới giá sàn`, `Trùng rule`, `Dữ liệu không hợp lệ` nếu có|

##### 4\.2\.1\.4\.5 Search và filter behavior

|Thành phần|Hành vi|
|---|---|
|**Search input**|Placeholder: `Tìm theo khách hàng, sản phẩm...`|
|**Tất cả**|Hiển thị toàn bộ giá riêng / nhớ giá trong phạm vi quyền|
|**Đang áp dụng**|Chỉ hiển thị giá riêng active, còn hiệu lực và không có lỗi blocking|
|**Dưới giá sàn**|Chỉ hiển thị giá riêng thấp hơn giá sàn hiện tại|
|**Filter nâng cao**|Cho phép lọc theo trạng thái, nguồn tạo và thời gian cập nhật nếu hỗ trợ|

##### 4\.2\.1\.4\.6 Interaction và navigation

|Tương tác|Hành vi|
|---|---|
|**Tap item**|Điều hướng sang US\-03 — Xem chi tiết một giá riêng|
|**Tap CTA ****`+`**|Điều hướng sang US\-02 — Chọn cách thêm giá riêng|
|**Tap filter icon**|Mở bộ lọc nâng cao|
|**Clear search/filter**|Xóa điều kiện tìm kiếm/lọc và tải lại danh sách phù hợp|

##### 4\.2\.1\.4\.7 Empty / Error / Permission states

|State|Nội dung|CTA|
|---|---|---|
|**Empty**|`Chưa có giá riêng / nhớ giá nào`|`+` hoặc `Thêm giá riêng` nếu có quyền|
|**No result**|`Không tìm thấy giá riêng phù hợp`|`Xóa tìm kiếm` hoặc `Xóa bộ lọc`|
|**Error**|`Không thể tải danh sách giá riêng / nhớ giá`|`Thử lại`|
|**No permission**|`Bạn không có quyền xem giá riêng / nhớ giá`|Không có CTA chính|

#### 4\.2\.1\.5 Designs

[SG\-01](https://hamsacorp.sg.larksuite.com/wiki/RUsxwytCKiwtd9keBzBlLoQ0gob#share-BelpdzvylowRXux5bMmloHrcgxf)

#### 4\.2\.1\.6 Scenarios

|ID|Scenario|Given|When|Then|
|---|---|---|---|---|
|**SC\-01**<br>|Xem danh sách mặc định|Người dùng có quyền xem giá riêng / nhớ giá|Người dùng mở màn hình `Giá riêng / Nhớ giá`|Hệ thống hiển thị danh sách giá riêng / nhớ giá thuộc tenant hiện tại|
|**SC\-02**|Tìm kiếm giá riêng / nhớ giá|Danh sách có nhiều giá riêng|Người dùng nhập tên khách hàng, tên sản phẩm hoặc mã sản phẩm|Hệ thống hiển thị các item phù hợp với từ khóa|
|**SC\-03**|Lọc giá riêng đang áp dụng|Danh sách có nhiều trạng thái|Người dùng chọn quick filter `Đang áp dụng`|Hệ thống chỉ hiển thị giá riêng active, còn hiệu lực và không có lỗi blocking|
|**SC\-04**|Lọc giá riêng dưới giá sàn|Có giá riêng thấp hơn giá sàn hiện tại|Người dùng chọn quick filter `Dưới giá sàn`|Hệ thống chỉ hiển thị các item có cảnh báo dưới giá sàn|
|**SC\-05**|Mở bộ lọc nâng cao|Người dùng cần lọc sâu hơn quick filter|Người dùng bấm icon filter|Hệ thống mở bộ lọc nâng cao|
|**SC\-06**|Điều hướng từ danh sách|Người dùng đang xem danh sách|Người dùng tap item hoặc bấm CTA `+`|Hệ thống mở chi tiết giá riêng hoặc chuyển sang màn chọn cách thêm|
|**SC\-07**|Hiển thị state đặc biệt|Dữ liệu rỗng, không có kết quả, lỗi tải dữ liệu hoặc thiếu quyền|Người dùng mở hoặc thao tác trên danh sách|Hệ thống hiển thị state tương ứng và CTA xử lý nếu phù hợp|

#### 4\.2\.1\.7 Edge cases

|ID|Edge Case|Hướng xử lý đề xuất|
|---|---|---|
|**EC\-01**|Giá riêng active nhưng đã hết ngày hiệu lực|Không hiển thị trong filter `Đang áp dụng`; hiển thị trạng thái `Hết hiệu lực` ở các filter khác|
|**EC\-02**|Khách hàng, sản phẩm hoặc đơn vị bán không còn hoạt động|Hiển thị cảnh báo dữ liệu không hợp lệ và không áp dụng cho đơn mới nếu là lỗi blocking|
|**EC\-03**|Giá riêng dưới giá sàn nhưng user không có quyền xem giá sàn|Vẫn hiển thị badge cảnh báo nếu policy cho phép, nhưng ẩn giá sàn cụ thể|
|**EC\-04**|Có rule trùng do import hoặc migration|Gắn cảnh báo `Trùng rule` hoặc đưa vào nhóm `Cần kiểm tra`|
|**EC\-05**|Search có dấu / không dấu hoặc khác chữ hoa thường|Nên hỗ trợ tìm kiếm không phân biệt dấu tiếng Việt và không phân biệt hoa thường|
|**EC\-06**|Danh sách rất lớn|Dùng pagination, infinite scroll hoặc server\-side search/filter|
|**EC\-07**|Dữ liệu thay đổi trong lúc người dùng đang xem|Khi refresh hoặc quay lại từ detail, danh sách cập nhật trạng thái mới nhất|

#### 4\.2\.1\.8 Open questions

|ID|Question|Gợi ý|
|---|---|---|
|**OQ\-01**|Quick filter V1 có chỉ gồm `Tất cả`, `Đang áp dụng`, `Dưới giá sàn` không?|Đề xuất giữ 3 nhóm này để tránh quá tải danh sách|
|**OQ\-02**|Item list có cần hiển thị `Giá hiện tại` ngoài `Giá riêng / Giá nhớ` không?|Nếu UI quá tải, đưa `Giá hiện tại` vào màn chi tiết|
|**OQ\-03**|Người dùng bị ẩn giá sàn có được thấy badge `Dưới giá sàn` không?|Đề xuất vẫn thấy badge, nhưng không thấy số giá sàn|
|**OQ\-04**|Sort mặc định nên ưu tiên cảnh báo hay cập nhật gần nhất?|Đề xuất ưu tiên item có cảnh báo, sau đó đến item cập nhật gần nhất|
|**OQ\-05**|Có cần hiển thị nguồn tạo rule trên danh sách không?|Đề xuất để trong filter nâng cao và màn chi tiết; chỉ đưa lên list nếu migration/import là nghiệp vụ thường xuyên|
|**OQ\-06**|Có cần bulk action từ danh sách trong V1 không?|Chưa đưa vào US\-01; nếu cần nên tách thành story riêng|

### 4\.2\.2 US\-02 — Chọn cách thêm giá riêng

#### 4\.2\.2\.1 Business context

US\-02 là bước điều hướng sau khi người dùng bấm CTA thêm mới từ màn hình `Giá riêng / Nhớ giá`\. Mục tiêu của US này là giúp Quản lý cửa hàng hoặc Quản trị viên chọn đúng cách thêm giá riêng theo nhu cầu thực tế: tạo thủ công khi chỉ cần thêm một vài giá riêng, hoặc nhập Excel khi cần tạo/cập nhật nhiều giá riêng cùng lúc\.

US này không trực tiếp tạo rule giá riêng / nhớ giá\. Đây là bước chọn phương thức và chuyển người dùng sang flow phù hợp: US\-04 — Tạo giá riêng thủ công hoặc US\-05 — Nhập giá riêng bằng Excel\.

Nếu người dùng đi vào từ chi tiết khách hàng hoặc chi tiết sản phẩm, hệ thống cần giữ ngữ cảnh để hỗ trợ prefill ở flow tiếp theo, giúp giảm nhập tay và tránh chọn sai khách hàng/sản phẩm\.

#### 4\.2\.2\.2 Functional requirements

|ID|Functional Requirement|Acceptance Criteria|
|---|---|---|
|**FR\-01**|Mở lựa chọn cách thêm giá riêng|Khi người dùng bấm CTA `+` hoặc `Thêm giá riêng`, hệ thống hiển thị lựa chọn cách thêm|
|**FR\-02**|Hiển thị các phương thức thêm|Hệ thống hiển thị tối thiểu 2 lựa chọn: `Tạo thủ công` và `Nhập từ Excel`|
|**FR\-03**|Giải thích ngắn gọn từng phương thức|Mỗi lựa chọn có mô tả rõ khi nào nên dùng phương thức đó|
|**FR\-04**|Điều hướng sang flow tương ứng|Chọn `Tạo thủ công` mở US\-04; chọn `Nhập từ Excel` mở US\-05|
|**FR\-05**|Giữ ngữ cảnh entry point|Nếu mở từ chi tiết khách hàng/sản phẩm, hệ thống truyền context sang flow tiếp theo để prefill nếu hợp lệ|
|**FR\-06**|Kiểm soát quyền theo phương thức|Người dùng chỉ thấy hoặc chỉ chọn được phương thức phù hợp với quyền được cấp|
|**FR\-07**|Hỗ trợ đóng lựa chọn mà không tạo dữ liệu|Người dùng có thể đóng bottom sheet / quay lại mà không phát sinh thay đổi dữ liệu|

#### 4\.2\.2\.3 Business rules

|ID|Business Rule|
|---|---|
|**BR\-01**|US\-02 không tạo mới, cập nhật hoặc xóa rule giá riêng / nhớ giá|
|**BR\-02**|`Tạo thủ công` chỉ khả dụng với người dùng có quyền tạo giá riêng thủ công|
|**BR\-03**|`Nhập từ Excel` chỉ khả dụng với người dùng có quyền import giá riêng|
|**BR\-04**|Tạo thủ công phù hợp với một hoặc ít rule; nhập Excel phù hợp với dữ liệu lớn hoặc cần cập nhật hàng loạt|
|**BR\-05**|Chọn phương thức không được bỏ qua validation của US\-04 hoặc US\-05|
|**BR\-06**|Nếu người dùng không có bất kỳ quyền thêm nào, hệ thống phải hiển thị trạng thái không có quyền thay vì hiển thị lựa chọn khả dụng giả|

#### 4\.2\.2\.4 UI Contract

##### 4\.2\.2\.4\.1 Mục tiêu màn hình

Màn hình / bottom sheet giúp người dùng chọn nhanh cách thêm giá riêng phù hợp với khối lượng dữ liệu và quyền thao tác, đồng thời giữ ngữ cảnh từ màn hình trước nếu có\.

##### 4\.2\.2\.4\.2 Entry point

|Entry point|Hành vi|
|---|---|
|**Danh sách Giá riêng / Nhớ giá → CTA ****`+`**|Mở bottom sheet chọn cách thêm|
|**Empty state → ****`Thêm giá riêng`**|Mở bottom sheet chọn cách thêm|

##### 4\.2\.2\.4\.3 Presentation pattern

|Thành phần|Quy tắc|
|---|---|
|**Pattern chính**<br>|Dùng bottom sheet trên mobile<br>|
|**Overlay**|Nội dung phía sau được dim|
|**Handle**|Bottom sheet có handle ngắn ở phía trên|
|**Title**|`Thêm giá riêng / nhớ giá`|
|**Dismiss**|Có thể đóng bằng icon `×`, kéo xuống hoặc tap overlay nếu không có dữ liệu đang xử lý|

##### 4\.2\.2\.4\.4 Header và context

|Trường hợp|Nội dung hiển thị|
|---|---|
|**Mở từ danh sách**|Hiển thị title chung, không cần context cụ thể|
|**Context không hợp lệ**|Không prefill context và hiển thị cảnh báo nhẹ nếu cần|

##### 4\.2\.2\.4\.5 Method options

|Option|Nội dung|Hành vi|
|---|---|---|
|**Tạo thủ công**|`Tạo 1 giá riêng cho khách hàng × sản phẩm × đơn vị bán`|Tap mở US\-04|
|**Nhập từ Excel**|`Tạo hoặc cập nhật nhiều giá riêng từ file Excel`|Tap mở US\-05|
|**Icon**|`Tạo thủ công` dùng icon edit/pencil; `Nhập từ Excel` dùng icon file Excel|Icon đi cùng label, không dùng icon trang trí không rõ nghĩa|
|**Chevron**|Mỗi option có chevron `›` ở bên phải|Cho biết người dùng sẽ đi sang bước tiếp theo|

##### 4\.2\.2\.4\.6 Permission và availability

|Trạng thái|Hành vi UI|
|---|---|
|**Có đủ quyền**|Cả hai option khả dụng|
|**Chỉ có quyền tạo thủ công**|`Tạo thủ công` khả dụng, `Nhập từ Excel` bị ẩn hoặc disabled kèm lý do|
|**Chỉ có quyền import**|`Nhập từ Excel` khả dụng, `Tạo thủ công` bị ẩn hoặc disabled kèm lý do|
|**Không có quyền thêm**|Hiển thị no\-permission state trong bottom sheet hoặc chặn CTA từ màn trước|
|**Tính năng import chưa bật**|`Nhập từ Excel` disabled với nhãn giải thích ngắn|

##### 4\.2\.2\.4\.7 Navigation và feedback

|Tương tác|Kết quả|
|---|---|
|**Tap ****`Tạo thủ công`**|Điều hướng sang US\-04, truyền context nếu có|
|**Tap ****`Nhập từ Excel`**|Điều hướng sang US\-05, truyền context nếu có thể áp dụng|
|**Đóng bottom sheet**|Quay lại màn trước, không thay đổi dữ liệu|
|**Tap option bị disabled**|Không điều hướng; hiển thị lý do ngắn hoặc tooltip/helper text|

#### 4\.2\.2\.5 Designs

[SG\-03](https://hamsacorp.sg.larksuite.com/wiki/RUsxwytCKiwtd9keBzBlLoQ0gob#share-XMQ8dvSmwo9Hajx594ClUaaAgqb)

#### 4\.2\.2\.6 Scenarios

|ID|Scenario|Given|When|Then|
|---|---|---|---|---|
|**SC\-01**|Chọn tạo thủ công từ danh sách|Người dùng có quyền tạo thủ công|Người dùng bấm `+` và chọn `Tạo thủ công`|Hệ thống mở US\-04 — Tạo giá riêng thủ công|
|**SC\-02**|Chọn nhập Excel từ danh sách|Người dùng có quyền import|Người dùng bấm `+` và chọn `Nhập từ Excel`|Hệ thống mở US\-05 — Nhập giá riêng bằng Excel|
|**SC\-03**|Người dùng chỉ có quyền tạo thủ công|Người dùng không có quyền import|Người dùng mở chọn cách thêm|Hệ thống chỉ cho phép chọn `Tạo thủ công` hoặc disabled `Nhập từ Excel`|
|**SC\-04**|Người dùng không có quyền thêm|Người dùng không có quyền tạo thủ công và không có quyền import|Người dùng bấm CTA thêm|Hệ thống hiển thị no\-permission state hoặc chặn CTA từ màn trước|
|**SC\-05**|Đóng bottom sheet|Bottom sheet đang mở|Người dùng đóng bottom sheet|Hệ thống quay lại màn trước và không tạo dữ liệu|

#### 4\.2\.2\.7 Edge cases

|ID|Edge Case|Hướng xử lý đề xuất|
|---|---|---|
|**EC\-01**|User mất quyền sau khi bottom sheet đã mở|Re\-check quyền khi chọn option; nếu không còn quyền thì chặn và hiển thị thông báo|
|**EC\-02**|Tính năng nhập Excel chưa khả dụng theo gói|Disable option `Nhập từ Excel` và hiển thị lý do ngắn|
|**EC\-03**|Người dùng tap option nhiều lần|Chỉ xử lý một lần, tránh mở nhiều màn hoặc tạo nhiều request|
|**EC\-04**|Mở từ no\-result state với search/filter đang active|Khi đóng bottom sheet, giữ nguyên search/filter hiện tại|

#### 4\.2\.2\.8 Open questions

|ID|Question|Gợi ý|
|---|---|---|
|**OQ\-01**|Trong V1, `Nhập từ Excel` có cho phép cập nhật rule hiện có hay chỉ tạo mới?|Đề xuất cho phép cả tạo mới và cập nhật, nhưng validation chi tiết nằm ở US\-05|
|**OQ\-02**|Người dùng Manager có được import Excel không hay chỉ Admin?|Đề xuất import Excel mặc định cho Quản trị viên; Manager cần quyền riêng|
|**OQ\-03**|Có cần ghi nhớ phương thức thêm gần nhất của người dùng không?|Chưa cần trong V1; giữ bottom sheet đơn giản|
|**OQ\-04**|Nếu mở từ chi tiết khách hàng, nhập Excel có nên giới hạn file chỉ cho khách đó không?|Đề xuất không giới hạn; chỉ dùng context để hỗ trợ UX nếu cần|
|**OQ\-05**|Template Excel nên được tải ngay từ US\-02 hay trong US\-05?|Đề xuất để trong US\-05 để tránh làm nặng bước chọn cách thêm|
|**OQ\-06**|Có cần hiển thị mô tả “nhớ giá” riêng trong option không?|Đề xuất giữ label ngắn; giải thích nguồn tạo và logic nhớ giá ở US\-04/US\-05/US\-09|
|**OQ\-07**|Option không có quyền nên bị ẩn hay disabled?|Đề xuất disabled nếu cần giáo dục quyền; ẩn nếu muốn giảm nhiễu cho user vận hành|

### 4\.2\.3 US\-03 — Xem chi tiết một giá riêng

#### 4\.2\.3\.1 Business context

US\-03 cho phép Quản lý cửa hàng hoặc Quản trị viên xem chi tiết một giá riêng / nhớ giá đã được thiết lập cho khách hàng\.

Trong vận hành, màn chi tiết giúp người dùng kiểm tra vì sao một khách hàng đang được áp dụng mức giá đặc biệt cho một sản phẩm cụ thể, mức giá đó có còn hiệu lực không, có thấp hơn giá sàn không, được tạo từ đâu, ai tạo, ai cập nhật gần nhất và đã từng được áp dụng trong bán hàng như thế nào\.

US này chỉ tập trung vào việc xem chi tiết và kiểm tra thông tin của một rule giá riêng\. Các thao tác sửa, tắt, bật lại hoặc xem lịch sử đầy đủ sẽ được xử lý ở các US sau\. Trên màn chi tiết có thể hiển thị CTA điều hướng sang các flow đó, nhưng không xử lý logic nghiệp vụ của các flow đó trong US\-03\.

#### 4\.2\.3\.2 Functional requirements

|ID|Functional Requirement|Acceptance Criteria|
|---|---|---|
|**FR\-01**|Hiển thị thông tin tổng quan của giá riêng|Người dùng có quyền có thể xem khách hàng, sản phẩm, đơn vị bán và trạng thái của giá riêng|
|**FR\-02**|Hiển thị thông tin giá|Hệ thống hiển thị giá riêng / giá nhớ, giá hiện tại, giá sàn nếu có quyền và chênh lệch liên quan|
|**FR\-03**|Hiển thị hiệu lực áp dụng|Hệ thống hiển thị ngày bắt đầu, ngày kết thúc nếu có và trạng thái hiệu lực hiện tại|
|**FR\-04**|Hiển thị nguồn tạo và thông tin audit cơ bản|Hệ thống hiển thị nguồn tạo, người tạo, thời gian tạo và cập nhật gần nhất nếu có|
|**FR\-05**|Hiển thị cảnh báo cần kiểm tra|Nếu giá riêng dưới giá sàn, hết hiệu lực, đã tắt hoặc dữ liệu không hợp lệ, hệ thống phải thể hiện rõ|
|**FR\-06**|Hiển thị lịch sử gần đây|Hệ thống hiển thị một số hoạt động gần đây liên quan đến rule giá riêng|
|**FR\-07**|Điều hướng sang các flow liên quan|Người dùng có thể đi sang sửa, tắt, bật lại hoặc xem lịch sử đầy đủ nếu có quyền và trạng thái cho phép|

#### 4\.2\.3\.3 Business rules

|ID|Business Rule|
|---|---|
|**BR\-01**|Chỉ hiển thị giá riêng thuộc tenant hiện tại và trong phạm vi quyền của người dùng|
|**BR\-02**|Một giá riêng phải gắn với khách hàng hoặc nhóm khách hàng, sản phẩm và đơn vị bán cụ thể|
|**BR\-03**|Giá riêng đang áp dụng là rule active, còn hiệu lực và không có lỗi blocking|
|**BR\-04**|Giá riêng đã tắt hoặc hết hiệu lực không được áp dụng cho đơn hàng mới nhưng vẫn xem được trong chi tiết|
|**BR\-05**|Nếu giá riêng thấp hơn giá sàn hiện tại, màn chi tiết phải hiển thị cảnh báo `Dưới giá sàn`|
|**BR\-06**|Người dùng không có quyền xem dữ liệu nhạy cảm sẽ bị ẩn giá sàn hoặc một phần thông tin giá theo policy|
|**BR\-07**|CTA sửa / tắt / bật lại chỉ hiển thị hoặc enable khi người dùng có quyền và trạng thái rule cho phép|

#### 4\.2\.3\.4 UI Contract

##### 4\.2\.3\.4\.1 Mục tiêu màn hình

Màn hình chi tiết giúp người dùng kiểm tra đầy đủ một giá riêng / nhớ giá trước khi quyết định có cần sửa, tắt, bật lại hoặc kiểm tra lịch sử sâu hơn hay không\.

##### 4\.2\.3\.4\.2 Entry point

|Entry point|Hành vi|
|---|---|
|**US\-01 — Danh sách giá riêng / nhớ giá**|Người dùng tap vào một item để mở chi tiết giá riêng|
|**Sau khi tạo giá riêng thành công**|Có thể điều hướng sang chi tiết rule vừa tạo|
|**Sau khi sửa / tắt / bật lại**|Có thể quay lại chi tiết và cập nhật trạng thái mới nhất|
|**Từ lịch sử hoặc màn liên quan**|Có thể mở lại chi tiết rule nếu user có quyền|

##### 4\.2\.3\.4\.3 Top bar

|Thành phần|Quy tắc|
|---|---|
|**Back icon**|Dùng `←`|
|**Title**|`Chi tiết giá riêng`|
|**More menu**|Chỉ dùng nếu cần gom action phụ; không tự thêm nếu CTA đã rõ ở cuối màn|
|**Layout**|Title căn giữa, không dùng icon reload|

##### 4\.2\.3\.4\.4 Header summary

|Thành phần|Nội dung|
|---|---|
|**Status badge**|`Đang áp dụng`, `Đã tắt`, `Hết hiệu lực`, `Cần kiểm tra`|
|**Khách hàng**|Tên khách hàng hoặc nhóm khách hàng|
|**Sản phẩm**|Tên sản phẩm và mã/SKU nếu có|
|**Đơn vị bán**|Đơn vị áp dụng giá riêng, ví dụ `Hộp`, `Lọ`, `Gói`|
|**Source badge**|Có thể hiển thị nguồn tạo như `Tạo thủ công`, `Nhập Excel`, `Migration`, `Từ đơn hàng`|

##### 4\.2\.3\.4\.5 Card thông tin giá

|Thành phần|Nội dung|
|---|---|
|**Giá riêng / Giá nhớ**|Mức giá được lưu cho rule|
|**Giá hiện tại**|Giá bán hiện tại của sản phẩm / đơn vị bán nếu có|
|**Giá sàn**|Hiển thị nếu user có quyền xem|
|**Chênh lệch với giá hiện tại**|Hiển thị số tiền và tỷ lệ chênh lệch|
|**Chênh lệch với giá sàn**|Hiển thị nếu có dữ liệu và user có quyền|
|**Cảnh báo dưới giá sàn**|Banner hoặc inline alert nếu giá riêng thấp hơn giá sàn|

##### 4\.2\.3\.4\.6 Card hiệu lực

|Thành phần|Nội dung|
|---|---|
|**Từ ngày**|Ngày bắt đầu áp dụng|
|**Đến ngày**|Ngày kết thúc nếu có|
|**Trạng thái hiệu lực**|Còn hiệu lực, chưa hiệu lực, hết hiệu lực|
|**Cấu hình không giới hạn**|Nếu không có ngày kết thúc, hiển thị rõ `Không giới hạn`|



##### 4\.2\.3\.4\.7 Card nguồn tạo và audit

|Thành phần|Nội dung|
|---|---|
|**Nguồn tạo**|`Tạo thủ công`, `Nhập Excel`, `Migration`, `Từ đơn hàng`|
|**Người tạo**|Tên người tạo nếu có|
|**Ngày tạo**|Thời điểm tạo rule|
|**Cập nhật gần nhất**|Người cập nhật và thời điểm cập nhật gần nhất nếu có|

##### 4\.2\.3\.4\.8 Lịch sử gần đây

|Thành phần|Nội dung|
|---|---|
|**Danh sách hoạt động gần đây**|Hiển thị một số hoạt động mới nhất như tạo, sửa giá, tắt, bật lại, áp dụng trong bán hàng|
|**Thông tin mỗi activity**|Thời gian, người thực hiện, hành động, nội dung thay đổi ngắn|
|**CTA xem thêm**|`Lịch sử áp dụng & thay đổi` điều hướng sang US\-10 nếu có quyền|

##### 4\.2\.3\.4\.9 CTA theo trạng thái và quyền

|Trạng thái rule|CTA đề xuất|
|---|---|
|**Đang áp dụng**|`Sửa` và `Tắt giá riêng` nếu có quyền|
|**Đã tắt**|`Bật lại giá riêng` nếu có quyền|
|**Hết hiệu lực**|Có thể cho `Sửa` hoặc `Bật lại` tùy rule nghiệp vụ|
|**Cần kiểm tra**|CTA chính nên hướng người dùng xử lý lỗi, ví dụ `Sửa giá riêng`|
|**Không có quyền thao tác**|Ẩn hoặc disable CTA thao tác, vẫn cho xem chi tiết theo quyền|



#### 4\.2\.3\.5 Designs

[SG\-02](https://hamsacorp.sg.larksuite.com/wiki/RUsxwytCKiwtd9keBzBlLoQ0gob#share-LalNduwe6oU7luxlb1QlKXxegNf)

#### 4\.2\.3\.6 Scenarios

|ID|Scenario|Given|When|Then|
|---|---|---|---|---|
|**SC\-01**<br>|Xem chi tiết giá riêng đang áp dụng|Người dùng có quyền xem giá riêng|Người dùng mở chi tiết một rule đang áp dụng|Hệ thống hiển thị đầy đủ thông tin khách hàng, sản phẩm, giá, hiệu lực và CTA phù hợp|
|**SC\-02**|Kiểm tra giá riêng dưới giá sàn|Rule có giá riêng thấp hơn giá sàn hiện tại|Người dùng mở chi tiết rule|Hệ thống hiển thị cảnh báo `Dưới giá sàn` và chênh lệch với giá sàn|
|**SC\-03**|Xem giá riêng đã tắt|Rule đã bị tắt trước đó|Người dùng mở chi tiết rule|Hệ thống hiển thị trạng thái `Đã tắt` và không coi rule là đang áp dụng|
|**SC\-04**|Xem giá riêng hết hiệu lực|Rule đã quá ngày kết thúc|Người dùng mở chi tiết rule|Hệ thống hiển thị trạng thái hết hiệu lực và không áp dụng cho đơn mới|
|**SC\-05**|User bị giới hạn quyền xem giá|Người dùng có quyền xem giới hạn|Người dùng mở chi tiết rule|Hệ thống ẩn giá sàn hoặc dữ liệu nhạy cảm theo policy|
|**SC\-06**|Điều hướng sang flow liên quan|Người dùng có quyền và trạng thái cho phép|Người dùng bấm `Sửa`, `Tắt giá riêng`, `Bật lại giá riêng` hoặc `Lịch sử áp dụng & thay đổi`|Hệ thống điều hướng sang US tương ứng|
|**SC\-07**|Không có quyền thao tác|Người dùng chỉ có quyền xem|Người dùng mở chi tiết rule|Hệ thống cho xem thông tin được phép nhưng ẩn hoặc disable CTA thao tác|

#### 4\.2\.3\.7 Edge cases

|ID|Edge Case|Hướng xử lý đề xuất|
|---|---|---|
|**EC\-01**|Sản phẩm hoặc đơn vị bán không còn hoạt động|Hiển thị cảnh báo dữ liệu không còn hợp lệ và không cho áp dụng cho đơn mới|
|**EC\-02**|Khách hàng bị khóa hoặc ngừng giao dịch|Hiển thị cảnh báo khách hàng không còn hợp lệ|
|**EC\-03**|Giá sàn thay đổi sau khi rule được tạo|Chi tiết so sánh với giá sàn hiện tại và hiển thị cảnh báo nếu phát sinh dưới giá sàn|
|**EC\-04**|Giá bán hiện tại thấp hơn giá riêng / nhớ giá|Cần hiển thị chênh lệch để người dùng hiểu rule có thể không còn lợi thế cho khách|
|**EC\-05**|Rule được tạo từ migration thiếu thông tin audit|Hiển thị nguồn `Migration` và dùng fallback như `Không có dữ liệu người tạo` nếu cần|
|**EC\-06**|Không tải được lịch sử gần đây|Vẫn hiển thị thông tin chính, phần lịch sử hiển thị lỗi nhẹ hoặc CTA thử lại|
|**EC\-07**|Rule vừa bị thay đổi bởi người khác|Khi refresh hoặc quay lại màn, cập nhật trạng thái và CTA mới nhất|

#### 4\.2\.3\.8 Open questions

|ID|Question|Gợi ý|
|---|---|---|
|**OQ\-01**|Có hiển thị cả `Giá hiện tại` trên chi tiết không?|Đề xuất có, vì cần so sánh với giá riêng / nhớ giá|
|**OQ\-02**|User không có quyền xem giá sàn có được thấy badge `Dưới giá sàn` không?|Đề xuất vẫn thấy badge, nhưng không thấy số giá sàn|
|**OQ\-03**|Lịch sử gần đây nên hiển thị bao nhiêu dòng?|Đề xuất 3–5 hoạt động gần nhất, xem đầy đủ ở US\-10|
|**OQ\-04**|Rule `Hết hiệu lực` có được bật lại trực tiếp không?|Cần chốt ở US\-08; US\-03 chỉ hiển thị CTA theo rule đã chốt|
|**OQ\-05**|Có cần hiển thị số lần giá riêng đã được áp dụng trong bán hàng không?|Đề xuất hiển thị nếu dữ liệu sẵn có, nhưng không bắt buộc V1|
|**OQ\-06**|Giá riêng cho nhóm khách hàng có cần hiển thị danh sách khách thuộc nhóm không?|Đề xuất chỉ hiển thị nhóm ở US\-03; danh sách chi tiết nếu cần đưa sang màn liên quan|
|**OQ\-07**|Có cần hiển thị thông tin chi nhánh/kênh áp dụng không?|Chỉ hiển thị nếu mô hình giá riêng V1 có phạm vi theo chi nhánh/kênh|

### 4\.2\.4 US\-04 — Tạo giá riêng thủ công

#### 4\.2\.4\.1 Business context

US\-04 cho phép Quản lý cửa hàng hoặc Quản trị viên tạo một giá riêng thủ công cho khách hàng đối với một sản phẩm và đơn vị bán cụ thể\.

Trong vận hành thực tế, giá riêng thường xuất phát từ thỏa thuận bán hàng, chính sách chăm sóc khách quen hoặc quyết định quản lý giá cho một nhóm khách hàng nhất định\. Nếu không có form tạo rõ ràng, người dùng dễ chọn sai khách hàng, sai sản phẩm, sai đơn vị bán hoặc nhập mức giá thấp hơn giá sàn mà không nhận biết rủi ro\.

US này chỉ xử lý việc tạo giá riêng thủ công\. Entry point chọn phương thức thêm đã được xử lý ở US\-02, nên không thiết kế lại bottom sheet chọn cách thêm trong Design coverage của US\-04\.

#### 4\.2\.4\.2 Functional requirements

|ID|Functional Requirement|Acceptance Criteria|
|---|---|---|
|**FR\-01**|Hiển thị form tạo giá riêng thủ công|Người dùng có quyền có thể mở form tạo giá riêng sau khi chọn `Tạo thủ công` từ US\-02|
|**FR\-02**|Chọn đối tượng áp dụng|Người dùng có thể chọn khách hàng áp dụng giá riêng|
|**FR\-03**|Chọn sản phẩm và đơn vị bán|Người dùng có thể chọn sản phẩm và đơn vị bán cụ thể để áp dụng giá riêng|
|**FR\-04**|Nhập giá riêng|Người dùng có thể nhập giá riêng hợp lệ cho tổ hợp khách hàng × sản phẩm × đơn vị bán|
|**FR\-05**|Thiết lập hiệu lực|Người dùng có thể thiết lập ngày bắt đầu và ngày kết thúc nếu cần|
|**FR\-06**|Preview và kiểm tra trước khi lưu|Hệ thống hiển thị giá hiện tại, giá sàn nếu có quyền, chênh lệch và cảnh báo như dưới giá sàn hoặc trùng rule|
|**FR\-07**|Lưu giá riêng thủ công|Khi dữ liệu hợp lệ, hệ thống tạo rule giá riêng nguồn `Tạo thủ công`, ghi audit log và hiển thị feedback thành công|

#### 4\.2\.4\.3 Business rules

|ID|Business Rule|
|---|---|
|**BR\-01**|Chỉ người dùng có quyền tạo giá riêng mới được lưu giá riêng thủ công|
|**BR\-02**|Giá riêng phải thuộc tenant hiện tại và gắn với khách hàng, sản phẩm và đơn vị bán cụ thể|
|**BR\-03**|Giá riêng phải lớn hơn 0 và được lưu bằng kiểu dữ liệu tiền tệ/decimal|
|**BR\-04**|Ngày bắt đầu phải nhỏ hơn hoặc bằng ngày kết thúc nếu người dùng thiết lập ngày kết thúc|
|**BR\-05**|Không được tạo rule active trùng đối tượng áp dụng, sản phẩm, đơn vị bán và giao nhau về hiệu lực|
|**BR\-06**|Giá riêng thấp hơn giá sàn hiện tại phải hiển thị cảnh báo; hệ thống có thể chặn lưu nếu policy không cho phép hoặc user không có quyền override|
|**BR\-07**|Khi lưu thành công, rule có nguồn tạo là `Tạo thủ công` và thao tác phải được ghi vào lịch sử thay đổi|

#### 4\.2\.4\.4 UI Contract

##### 4\.2\.4\.4\.1 Mục tiêu màn hình

Màn hình tạo giá riêng thủ công giúp người dùng thiết lập một rule giá riêng rõ ràng, kiểm tra được mức giá trước khi lưu và giảm rủi ro tạo sai giá cho khách hàng\.

##### 4\.2\.4\.4\.2 Entry point

|Entry point|Hành vi|
|---|---|
|**US\-02 — Chọn cách thêm giá riêng → Tạo thủ công**|Mở form tạo giá riêng thủ công|

##### 4\.2\.4\.4\.3 Top bar

|Thành phần|Quy tắc|
|---|---|
|**Back icon**|Dùng `←`|
|**Title**|`Tạo giá riêng`|
|**Right icon**|Không hiển thị icon reload hoặc icon thừa|
|**Back behavior**|Nếu form có dữ liệu chưa lưu, hiển thị confirmation trước khi thoát|

##### 4\.2\.4\.4\.4 Form structure

|Card / Section|Nội dung|
|---|---|
|**Đối tượng áp dụng**|Chọn `Khách hàng`|
|**Sản phẩm \& đơn vị bán**|Chọn sản phẩm, SKU/mã sản phẩm nếu có và đơn vị bán áp dụng|
|**Giá riêng**|Nhập giá riêng, xem giá hiện tại, giá sàn và chênh lệch|
|**Hiệu lực**|Ngày bắt đầu, ngày kết thúc hoặc `Không giới hạn`|
|**Kiểm tra trước khi lưu**|Hiển thị lỗi blocking và cảnh báo không blocking nếu có|

##### 4\.2\.4\.4\.5 Field behavior

|Field|Hành vi|
|---|---|
|**Loại đối tượng**|Segmented control hoặc radio: `Khách hàng`|
|**Khách hàng**|Picker có search; bắt buộc chọn trước khi lưu|
|**Sản phẩm**|Picker có search theo tên, mã sản phẩm hoặc SKU|
|**Đơn vị bán**|Danh sách phụ thuộc sản phẩm đã chọn; bắt buộc chọn trước khi lưu|
|**Giá riêng**|Numeric input, định dạng tiền Việt Nam, không cho nhập số âm|
|**Ngày hiệu lực**|Date picker; ngày kết thúc là optional nếu cho phép không giới hạn|

##### 4\.2\.4\.4\.6 Validation và warning

|Tình huống|Hành vi UI|
|---|---|
|**Thiếu field bắt buộc**|Hiển thị inline error tại field tương ứng|
|**Giá riêng không hợp lệ**|Hiển thị lỗi dưới input giá riêng|
|**Trùng rule đang áp dụng**|Hiển thị alert blocking và gợi ý mở rule hiện có|
|**Dưới giá sàn**|Hiển thị warning nổi bật; chặn hoặc cho lưu tùy policy|
|**Sản phẩm/đơn vị bán không hợp lệ**|Chặn lưu và yêu cầu chọn lại|

##### 4\.2\.4\.4\.7 Footer CTA và feedback

|Trạng thái|CTA|
|---|---|
|**Form chưa đủ dữ liệu**|`Lưu` disabled, `Hủy` secondary|
|**Form hợp lệ**|`Lưu` primary, `Hủy` secondary|
|**Có lỗi blocking**|`Lưu` disabled hoặc chặn khi tap và focus vào lỗi đầu tiên|
|**Có warning không blocking**|Cho phép `Lưu`, nhưng warning vẫn hiển thị rõ trước khi lưu|
|**Lưu thành công**|Toast `Đã tạo giá riêng`; điều hướng sang chi tiết rule hoặc quay lại danh sách theo flow đã chốt|

#### 4\.2\.4\.5 Designs

[SG\-03](https://hamsacorp.sg.larksuite.com/wiki/RUsxwytCKiwtd9keBzBlLoQ0gob#share-QmbSdOgzso0gRcxUMPslTaBSgae)

#### 4\.2\.4\.6 Scenarios

|ID|Scenario|Given|When|Then|
|---|---|---|---|---|
|**SC\-01**|Tạo giá riêng cho một khách hàng|Người dùng có quyền tạo giá riêng|Người dùng chọn khách hàng, sản phẩm, đơn vị bán, nhập giá hợp lệ và bấm `Lưu`|Hệ thống tạo giá riêng nguồn `Tạo thủ công`|
|**SC\-02**|Preview giá trước khi lưu|Người dùng đã chọn sản phẩm và đơn vị bán|Người dùng nhập giá riêng|Hệ thống hiển thị giá hiện tại, giá sàn nếu có quyền và chênh lệch|
|**SC\-03**|Cảnh báo dưới giá sàn|Giá riêng nhập vào thấp hơn giá sàn hiện tại|Người dùng nhập hoặc rời khỏi field giá riêng|Hệ thống hiển thị cảnh báo dưới giá sàn và xử lý theo policy|
|**SC\-04**|Chặn rule trùng|Đã tồn tại rule active trùng đối tượng, sản phẩm, đơn vị bán và hiệu lực|Người dùng bấm `Lưu`|Hệ thống chặn lưu và thông báo rule đã tồn tại|
|**SC\-05**|Chặn dữ liệu thiếu hoặc không hợp lệ|Form thiếu field bắt buộc hoặc ngày hiệu lực sai|Người dùng bấm `Lưu`|Hệ thống hiển thị lỗi và không tạo rule|
|**SC\-06**|Thoát khi có dữ liệu chưa lưu|Người dùng đã nhập dữ liệu vào form|Người dùng bấm `←` hoặc `Hủy`|Hệ thống hỏi xác nhận trước khi thoát|

#### 4\.2\.4\.7 Edge cases

|ID|Edge Case|Hướng xử lý đề xuất|
|---|---|---|
|**EC\-01**<br>|Khách hàng bị khóa trong lúc tạo|Re\-check khi lưu; chặn lưu nếu đối tượng không còn hợp lệ|
|**EC\-02**|Sản phẩm hoặc đơn vị bán bị ngừng bán trong lúc tạo|Re\-check khi lưu; yêu cầu chọn lại sản phẩm/đơn vị bán|
|**EC\-03**|Giá sàn thay đổi sau khi user đã preview|Khi bấm `Lưu`, hệ thống kiểm tra lại theo giá sàn mới nhất|
|**EC\-04**|User nhập giá có ký tự không hợp lệ|Input chỉ nhận số hợp lệ và tự format tiền tệ|
|**EC\-05**|User tap `Lưu` nhiều lần|Chỉ gửi một request, disable CTA trong lúc xử lý|
|**EC\-06**|Mất mạng khi lưu|Giữ dữ liệu trên form nếu có thể và hiển thị lỗi `Không thể lưu giá riêng`|
|**EC\-07**|Một khách hàng thuộc nhiều nhóm có giá riêng khác nhau|Không xử lý ưu tiên trong US\-04; cần rule ưu tiên ở EP04 hoặc Open question|

#### 4\.2\.4\.8 Open questions

|ID|Question|Gợi ý|
|---|---|---|
|**OQ\-01**|V1 có chính thức hỗ trợ giá riêng theo nhóm khách hàng không?|Nếu chưa chắc, thiết kế field này theo feature flag|
|**OQ\-02**|Giá riêng dưới giá sàn được cảnh báo hay bị chặn?|Đề xuất cảnh báo mặc định, chặn nếu policy không cho override|
|**OQ\-03**|Sau khi lưu thành công nên về danh sách hay sang chi tiết giá riêng?|Đề xuất sang US\-03 để người dùng kiểm tra lại rule vừa tạo|
|**OQ\-04**|Có cho phép ngày kết thúc để trống không?|Đề xuất có, hiển thị là `Không giới hạn`|
|**OQ\-05**|Nếu khách hàng có rule riêng và nhóm khách hàng cũng có rule, rule nào ưu tiên?|Đề xuất để EP04 chốt priority; thường khách hàng cụ thể ưu tiên hơn nhóm|
|**OQ\-06**|Có cần chọn chi nhánh/kênh bán trong giá riêng V1 không?|Đề xuất chưa đưa vào US\-04 nếu mô hình V1 chỉ theo khách hàng × sản phẩm × đơn vị bán|
|**OQ\-07**|Có cần lý do tạo giá riêng không?|Đề xuất chưa bắt buộc; có thể bổ sung ghi chú nếu cần audit sâu|

### 4\.2\.5 US\-05 — Nhập giá riêng bằng Excel

#### 4\.2\.5\.1 Business context

US\-05 cho phép Quản trị viên nhập mới hoặc cập nhật nhiều giá riêng bằng file Excel\. Đây là flow phù hợp khi cửa hàng đã có dữ liệu giá riêng từ file nội bộ, dữ liệu migration hoặc cần cập nhật hàng loạt cho nhiều khách hàng và sản phẩm\.

US này giúp giảm thao tác nhập tay, nhưng cần kiểm soát chặt lỗi dữ liệu như không tìm thấy khách hàng, không tìm thấy sản phẩm, sai đơn vị bán, giá không hợp lệ, trùng rule đang áp dụng hoặc giá thấp hơn giá sàn\.

Entry point chọn phương thức `Nhập từ Excel` đã thuộc US\-02, nên không thiết kế lại bottom sheet chọn cách thêm trong Designs của US\-05\.

#### 4\.2\.5\.2 Functional requirements

|ID|Functional Requirement|Acceptance Criteria|
|---|---|---|
|**FR\-01**|Tải file mẫu nhập giá riêng|Người dùng có thể tải template Excel đúng cấu trúc hệ thống yêu cầu|
|**FR\-02**|Upload file Excel|Người dùng có quyền import có thể chọn và upload file Excel hợp lệ|
|**FR\-03**|Kiểm tra dữ liệu trong file|Hệ thống validate khách hàng, sản phẩm, đơn vị bán, giá riêng, hiệu lực và dữ liệu trùng|
|**FR\-04**|Preview kết quả import|Hệ thống hiển thị tổng số dòng hợp lệ, dòng cảnh báo và dòng lỗi|
|**FR\-05**|Cho phép xử lý dòng lỗi/cảnh báo|Người dùng có thể xem chi tiết lỗi, tải file lỗi hoặc quay lại sửa file|
|**FR\-06**|Xác nhận import|Người dùng có thể xác nhận tạo mới/cập nhật các dòng hợp lệ|
|**FR\-07**|Ghi nhận kết quả import|Hệ thống tạo/cập nhật rule giá riêng, ghi audit log và hiển thị feedback thành công/thất bại|

#### 4\.2\.5\.3 Business rules

|ID|Business Rule|
|---|---|
|**BR\-01**|Chỉ Quản trị viên hoặc user có quyền import giá riêng mới được thực hiện import|
|**BR\-02**|File import phải có các cột bắt buộc: khách hàng, sản phẩm/SKU, đơn vị bán, giá riêng|
|**BR\-03**|Mỗi dòng hợp lệ phải map được đúng một khách hàng, một sản phẩm và một đơn vị bán thuộc tenant hiện tại|
|**BR\-04**|Giá riêng phải lớn hơn 0 và đúng định dạng tiền tệ|
|**BR\-05**|Không được import thành công dòng tạo ra rule active trùng khách hàng, sản phẩm, đơn vị bán và giao nhau hiệu lực|
|**BR\-06**|Giá riêng thấp hơn giá sàn phải được cảnh báo hoặc chặn theo policy kiểm soát giá|
|**BR\-07**|Rule tạo/cập nhật từ file phải có nguồn tạo/cập nhật là `Nhập Excel` và có audit log|

#### 4\.2\.5\.4 UI Contract

##### 4\.2\.5\.4\.1 Mục tiêu màn hình

Flow nhập Excel giúp người dùng đưa dữ liệu giá riêng số lượng lớn vào hệ thống một cách có kiểm soát, tránh import mù và tránh tạo dữ liệu sai ảnh hưởng đến bán hàng\.

##### 4\.2\.5\.4\.2 Entry point

|Entry point|Hành vi|
|---|---|
|**US\-02 → Nhập từ Excel**|Mở flow nhập giá riêng bằng Excel|
|**Deep link nội bộ nếu có**|Mở flow nếu user có quyền import|
|**Không có quyền import**|Chặn truy cập hoặc hiển thị no\-permission state|

##### 4\.2\.5\.4\.3 Top bar

|Thành phần|Quy tắc|
|---|---|
|**Back icon**|Dùng `←`|
|**Title**|`Nhập giá riêng`|
|**Right icon**|Không hiển thị icon reload hoặc icon thừa|
|**Back behavior**|Nếu đã upload file nhưng chưa import, hỏi xác nhận trước khi thoát|

##### 4\.2\.5\.4\.4 Upload và template

|Thành phần|Hành vi|
|---|---|
|**Tải file mẫu**|Cho phép tải template Excel đúng cấu trúc|
|**Chọn file Excel**|Cho phép upload file `.xlsx` hợp lệ|
|**Hướng dẫn ngắn**|Nêu rõ các cột bắt buộc và lưu ý về mã khách hàng/SKU/đơn vị bán|
|**Trạng thái upload**|Hiển thị tên file, dung lượng và trạng thái đang kiểm tra|

##### 4\.2\.5\.4\.5 Preview và validation

|Nhóm kết quả|Hiển thị|
|---|---|
|**Dòng hợp lệ**|Có thể import|
|**Dòng cảnh báo**|Có thể import hoặc bị chặn tùy policy, ví dụ dưới giá sàn|
|**Dòng lỗi**|Không được import, ví dụ không tìm thấy khách hàng/sản phẩm/đơn vị bán|
|**Dòng trùng**|Hiển thị rõ là trùng trong file hay trùng với rule đang áp dụng|

##### 4\.2\.5\.4\.6 Confirmation và import result

|Trạng thái|Hành vi|
|---|---|
|**Có dòng hợp lệ**|CTA `Nhập giá riêng` khả dụng|
|**Không có dòng hợp lệ**|CTA import disabled|
|**Có dòng lỗi**|Cho phép import dòng hợp lệ nếu policy cho phép, hoặc yêu cầu sửa file|
|**Import thành công**|Hiển thị số dòng tạo mới, số dòng cập nhật, số dòng bỏ qua|
|**Import thất bại**|Hiển thị lỗi và CTA `Thử lại` hoặc `Tải file lỗi`|

#### 4\.2\.5\.5 Designs

[SG\-04](https://hamsacorp.sg.larksuite.com/wiki/RUsxwytCKiwtd9keBzBlLoQ0gob#share-L1LIdGlgToGSYBxpFk0laSSkgdg)

#### 4\.2\.5\.6 Scenarios

|ID|Scenario|Given|When|Then|
|---|---|---|---|---|
|**SC\-01**|Tải file mẫu|User có quyền import|User bấm `Tải file mẫu`|Hệ thống tải template Excel|
|**SC\-02**|Upload file hợp lệ|File đúng định dạng và có dữ liệu|User upload file|Hệ thống kiểm tra và hiển thị preview|
|**SC\-03**|File có dòng lỗi|File có khách hàng/sản phẩm/đơn vị bán không map được|Hệ thống kiểm tra file|Hệ thống hiển thị danh sách lỗi|
|**SC\-04**|File có giá dưới sàn|Một số dòng có giá riêng thấp hơn giá sàn|Hệ thống kiểm tra file|Hệ thống hiển thị cảnh báo dưới giá sàn|
|**SC\-05**|Import dòng hợp lệ|File có ít nhất một dòng hợp lệ|User xác nhận import|Hệ thống tạo/cập nhật rule hợp lệ|
|**SC\-06**|Import không có dòng hợp lệ|Toàn bộ file lỗi|User xem preview|CTA import disabled và hệ thống yêu cầu sửa file|
|**SC\-07**|Không có quyền import|User thiếu quyền import|User mở flow|Hệ thống hiển thị no\-permission state|

#### 4\.2\.5\.7 Edge cases

|ID|Edge Case|Hướng xử lý đề xuất|
|---|---|---|
|**EC\-01**|File sai định dạng hoặc không đọc được|Chặn upload và yêu cầu dùng file `.xlsx` đúng template|
|**EC\-02**|Một khách hàng/sản phẩm trong file match nhiều bản ghi|Đưa dòng đó vào lỗi cần xử lý, không tự đoán|
|**EC\-03**|Trong file có nhiều dòng trùng cùng khách hàng, sản phẩm, đơn vị bán|Đánh dấu trùng trong file và yêu cầu sửa|
|**EC\-04**|Giá sàn thay đổi trong lúc preview|Re\-check giá sàn tại thời điểm xác nhận import|
|**EC\-05**|Import đang chạy thì user đóng app|Hệ thống vẫn xử lý theo job nếu đã xác nhận; khi quay lại hiển thị kết quả gần nhất|
|**EC\-06**|File rất lớn|Giới hạn dung lượng/số dòng hoặc xử lý import dạng background job|
|**EC\-07**|Import một phần thành công, một phần thất bại|Hiển thị summary rõ số dòng thành công/thất bại và cho tải file lỗi|

#### 4\.2\.5\.8 Open questions

|ID|Question|Gợi ý|
|---|---|---|
|**OQ\-01**|V1 cho phép import cập nhật rule hiện có hay chỉ tạo mới?|Đề xuất cho phép cả tạo mới và cập nhật nếu match đúng key|
|**OQ\-02**|Dòng dưới giá sàn được import hay bị chặn?|Theo policy kiểm soát giá; mặc định cảnh báo, chặn nếu không có quyền override|
|**OQ\-03**|Có cần hỗ trợ CSV không?|V1 ưu tiên `.xlsx` để giảm lỗi format|
|**OQ\-04**|Import có cần chạy background job không?|Nếu file lớn, nên chạy background job|
|**OQ\-05**|Có cần lưu lịch sử file import không?|Nên lưu để phục vụ audit và đối soát|
|**OQ\-06**|Template có cần hỗ trợ ngày hiệu lực không?|Nên hỗ trợ optional `Từ ngày`, `Đến ngày`|
|**OQ\-07**|Có cần preview từng dòng cập nhật cũ → mới không?|Nên có nếu import dùng để cập nhật rule hiện có|

### 4\.2\.6 US\-06 — Sửa giá riêng

#### 4\.2\.6\.1 Business context

US\-06 cho phép Quản lý cửa hàng hoặc Quản trị viên chỉnh sửa một giá riêng đã tồn tại khi thỏa thuận với khách hàng thay đổi, giá bán hiện tại thay đổi hoặc rule cũ cần được điều chỉnh để tiếp tục áp dụng đúng\.

US này tập trung vào sửa thông tin của một rule giá riêng cụ thể\. Trigger `Sửa` từ màn chi tiết đã thuộc US\-03, nên không thiết kế lại màn chi tiết hoặc CTA trigger trong Designs của US\-06\.

Trong V1, để tránh thay đổi bản chất rule và giảm rủi ro tạo trùng dữ liệu, khách hàng, sản phẩm và đơn vị bán nên được hiển thị dạng read\-only khi sửa; người dùng chủ yếu sửa mức giá và thời gian hiệu lực\.

#### 4\.2\.6\.2 Functional requirements

|ID|Functional Requirement|Acceptance Criteria|
|---|---|---|
|**FR\-01**|Mở form sửa giá riêng|Người dùng có quyền có thể mở form sửa từ một rule hiện có|
|**FR\-02**|Hiển thị thông tin rule hiện tại|Hệ thống prefill khách hàng, sản phẩm, đơn vị bán, giá riêng và hiệu lực|
|**FR\-03**|Cho phép sửa mức giá và hiệu lực|Người dùng có thể cập nhật giá riêng, ngày bắt đầu và ngày kết thúc|
|**FR\-04**|Preview thay đổi trước khi lưu|Hệ thống hiển thị giá hiện tại, giá sàn, chênh lệch và cảnh báo nếu có|
|**FR\-05**|Validate dữ liệu sửa|Hệ thống kiểm tra giá hợp lệ, hiệu lực hợp lệ, trùng rule và dưới giá sàn|
|**FR\-06**|Lưu thay đổi|Khi dữ liệu hợp lệ, hệ thống cập nhật rule và ghi audit log|
|**FR\-07**|Kiểm soát quyền/trạng thái|Hệ thống chặn hoặc disable thao tác nếu user không có quyền hoặc rule không cho phép sửa|

#### 4\.2\.6\.3 Business rules

|ID|Business Rule|
|---|---|
|**BR\-01**|Chỉ user có quyền sửa giá riêng mới được lưu thay đổi|
|**BR\-02**|Khách hàng, sản phẩm và đơn vị bán là thông tin định danh rule, mặc định không chỉnh sửa trong V1|
|**BR\-03**|Giá riêng sau sửa phải lớn hơn 0|
|**BR\-04**|Ngày bắt đầu phải nhỏ hơn hoặc bằng ngày kết thúc nếu có ngày kết thúc|
|**BR\-05**|Sau khi sửa, rule không được trùng rule active khác cùng khách hàng, sản phẩm, đơn vị bán và giao nhau hiệu lực|
|**BR\-06**|Giá riêng dưới giá sàn phải hiển thị cảnh báo hoặc bị chặn theo policy|
|**BR\-07**|Thay đổi giá riêng chỉ ảnh hưởng đơn hàng mới; dữ liệu đơn hàng cũ giữ snapshot giá đã bán|

#### 4\.2\.6\.4 UI Contract

##### 4\.2\.6\.4\.1 Mục tiêu màn hình

Màn hình sửa giá riêng giúp người dùng cập nhật mức giá hoặc hiệu lực của rule hiện có, đồng thời kiểm tra rủi ro trước khi lưu thay đổi\.

##### 4\.2\.6\.4\.2 Entry point

|Entry point|Hành vi|
|---|---|
|**US\-03 → CTA ****`Sửa`**** **|Mở form sửa giá riêng|
|**Sau khi tạo giá riêng thành công nếu cần chỉnh lại**|Có thể mở form sửa từ chi tiết rule|
|**Không có quyền sửa**|Không mở form hoặc hiển thị no\-permission state|

##### 4\.2\.6\.4\.3 Top bar

|Thành phần|Quy tắc|
|---|---|
|**Back icon**|Dùng `←`|
|**Title**|`Sửa giá riêng`|
|**Right icon**|Không hiển thị icon reload hoặc icon thừa|
|**Back behavior**|Nếu có dữ liệu đã thay đổi nhưng chưa lưu, hỏi xác nhận trước khi thoát|

##### 4\.2\.6\.4\.4 Form structure

|Section|Nội dung|
|---|---|
|**Thông tin áp dụng**|Khách hàng, sản phẩm, đơn vị bán dạng read\-only|
|**Mức giá áp dụng**|Giá riêng có thể chỉnh sửa|
|**Kiểm tra nhanh**|Giá hiện tại, giá sàn, chênh lệch, cảnh báo|
|**Thời gian hiệu lực**|Từ ngày, đến ngày hoặc không giới hạn|
|**Audit note**|Có thể hiển thị cập nhật gần nhất để người dùng đối chiếu|

##### 4\.2\.6\.4\.5 Validation và warning

|Tình huống|Hành vi|
|---|---|
|**Giá rỗng/không hợp lệ**|Inline error tại input giá|
|**Ngày hiệu lực sai**|Inline error tại field ngày|
|**Trùng rule**|Alert blocking, CTA lưu disabled|
|**Dưới giá sàn**|Warning nổi bật, chặn hoặc cho lưu tùy policy|
|**Không có thay đổi**|CTA `Lưu` disabled|

##### 4\.2\.6\.4\.6 Save behavior và feedback

|Trạng thái|Hành vi|
|---|---|
|**Dữ liệu hợp lệ**|CTA `Lưu` primary khả dụng|
|**Có lỗi blocking**|CTA `Lưu` disabled hoặc focus vào lỗi đầu tiên|
|**Có warning không blocking**|Cho phép lưu nhưng warning vẫn hiển thị|
|**Lưu thành công**|Toast `Đã cập nhật giá riêng`, quay lại chi tiết rule|
|**Lưu thất bại**|Hiển thị lỗi và giữ dữ liệu đang nhập|

#### 4\.2\.6\.5 Designs

[SG\-03](https://hamsacorp.sg.larksuite.com/wiki/RUsxwytCKiwtd9keBzBlLoQ0gob#share-MBsyddqo1oIvCuxFO4OlWRfMgEg)

#### 4\.2\.6\.6 Scenarios

|ID|Scenario|Given|When|Then|
|---|---|---|---|---|
|**SC\-01**|Mở form sửa|User có quyền sửa|User bấm `Sửa` từ chi tiết rule|Hệ thống mở form prefilled|
|**SC\-02**|Sửa giá hợp lệ|User nhập giá mới hợp lệ|User bấm `Lưu`|Hệ thống cập nhật rule và ghi audit log|
|**SC\-03**|Sửa thời gian hiệu lực|User chỉnh ngày bắt đầu/kết thúc hợp lệ|User bấm `Lưu`|Hệ thống cập nhật hiệu lực rule|
|**SC\-04**|Giá dưới giá sàn|Giá mới thấp hơn giá sàn|User nhập giá mới|Hệ thống hiển thị cảnh báo hoặc chặn theo policy|
|**SC\-05**|Trùng rule sau khi sửa|Thay đổi hiệu lực làm giao nhau với rule khác|User bấm `Lưu`|Hệ thống chặn lưu|
|**SC\-06**|Thoát khi có thay đổi chưa lưu|User đã chỉnh dữ liệu|User bấm `←` hoặc `Hủy`|Hệ thống hỏi xác nhận thoát|
|**SC\-07**|Không có quyền sửa|User chỉ có quyền xem|User cố mở form sửa|Hệ thống chặn hoặc hiển thị no\-permission state|

#### 4\.2\.6\.7 Edge cases

|ID|Edge Case|Hướng xử lý đề xuất|
|---|---|---|
|**EC\-01**|Rule vừa bị người khác sửa|Re\-fetch trước khi lưu; nếu có conflict thì thông báo dữ liệu đã thay đổi|
|**EC\-02**|Rule vừa bị tắt trong lúc user đang sửa|Chặn lưu hoặc yêu cầu tải lại rule|
|**EC\-03**|Giá sàn thay đổi sau khi user preview|Re\-check giá sàn tại thời điểm lưu|
|**EC\-04**|User nhập ký tự không hợp lệ vào giá|Input chỉ nhận số và tự format tiền tệ|
|**EC\-05**|User bấm lưu nhiều lần|Disable CTA trong lúc xử lý|
|**EC\-06**|Mất mạng khi lưu|Giữ dữ liệu form và hiển thị lỗi có thể thử lại|
|**EC\-07**|Rule nguồn migration thiếu dữ liệu audit|Vẫn cho sửa nếu dữ liệu định danh hợp lệ; audit mới phải được ghi đầy đủ|

#### 4\.2\.6\.8 Open questions

|ID|Question|Gợi ý|
|---|---|---|
|**OQ\-01**<br>|V1 có cho sửa khách hàng/sản phẩm/đơn vị bán không?|Đề xuất không; muốn đổi định danh thì tạo rule mới|
|**OQ\-02**|Sửa giá dưới giá sàn có cần quyền override riêng không?|Đề xuất có nếu policy cho phép lưu dưới giá sàn|
|**OQ\-03**|Sửa rule đang áp dụng có cần confirmation không?|Đề xuất có confirmation nhẹ vì ảnh hưởng đơn hàng mới|
|**OQ\-04**|Có cần nhập lý do sửa không?|Đề xuất optional; bắt buộc nếu sửa xuống dưới giá sàn|
|**OQ\-05**|Sau khi lưu nên quay lại chi tiết hay danh sách?|Đề xuất quay lại chi tiết rule|
|**OQ\-06**|Có cho sửa rule đã tắt không?|Đề xuất cho sửa để chuẩn bị bật lại nếu user có quyền|
|**OQ\-07**|Có cần hiển thị diff trước/sau không?|Nên có ở confirmation nếu thay đổi giá hoặc hiệu lực|

### 4\.2\.7 US\-07 — Tắt giá riêng

#### 4\.2\.7\.1 Business context

US\-07 cho phép Quản lý cửa hàng hoặc Quản trị viên ngừng áp dụng một giá riêng khi chính sách không còn phù hợp, thỏa thuận với khách hàng kết thúc hoặc giá riêng có rủi ro cần tạm dừng\.

Tắt giá riêng không phải là xóa dữ liệu\. Rule vẫn được giữ lại để phục vụ truy vết, lịch sử và có thể bật lại ở US\-08 nếu đủ điều kiện\.

Trigger `Tắt giá riêng` từ màn chi tiết thuộc US\-03, nên Designs của US\-07 chỉ cover confirmation, kết quả và các state bị chặn/không có quyền\.

#### 4\.2\.7\.2 Functional requirements

|ID|Functional Requirement|Acceptance Criteria|
|---|---|---|
|**FR\-01**|Mở xác nhận tắt giá riêng|User có quyền có thể mở confirmation khi chọn `Tắt giá riêng`|
|**FR\-02**|Hiển thị tóm tắt rule bị tắt|Modal hiển thị khách hàng, sản phẩm, đơn vị bán, giá riêng và trạng thái hiện tại|
|**FR\-03**|Cho phép nhập lý do tắt|User có thể nhập lý do tắt nếu cần phục vụ audit|
|**FR\-04**|Cho phép hủy thao tác|User có thể chọn giữ giá riêng và không thay đổi dữ liệu|
|**FR\-05**|Xác nhận tắt giá riêng|Hệ thống chuyển rule sang trạng thái `Đã tắt`|
|**FR\-06**|Hiển thị kết quả sau khi tắt|Hệ thống hiển thị toast/success state và cập nhật chi tiết rule|
|**FR\-07**|Chặn thao tác không hợp lệ|Hệ thống chặn nếu user thiếu quyền hoặc rule không thể tắt|

#### 4\.2\.7\.3 Business rules

|ID|Business Rule|
|---|---|
|**BR\-01**|Chỉ user có quyền tắt giá riêng mới được xác nhận thao tác|
|**BR\-02**|Chỉ rule chưa ở trạng thái `Đã tắt` mới có thể thực hiện tắt|
|**BR\-03**|Tắt giá riêng chỉ ảnh hưởng đơn hàng mới, không thay đổi đơn hàng cũ|
|**BR\-04**|Rule bị tắt không được pricing engine áp dụng cho đơn hàng mới|
|**BR\-05**|Thao tác tắt phải ghi audit log gồm người thực hiện, thời gian và lý do nếu có|
|**BR\-06**|Tắt giá riêng không xóa rule và không xóa lịch sử áp dụng/thay đổi|
|**BR\-07**|Trước khi tắt, hệ thống phải re\-check trạng thái mới nhất để tránh thao tác trên dữ liệu cũ|

#### 4\.2\.7\.4 UI Contract

##### 4\.2\.7\.4\.1 Mục tiêu màn hình

Flow tắt giá riêng giúp người dùng xác nhận rõ tác động trước khi ngừng áp dụng rule cho các đơn hàng mới\.

##### 4\.2\.7\.4\.2 Entry point

|Entry point|Hành vi|
|---|---|
|**US\-03 → CTA ****`Tắt giá riêng`**|Mở confirmation tắt giá riêng|
|**Rule đã tắt**|Không hiển thị CTA tắt hoặc hiển thị trạng thái đã tắt|
|**Không có quyền tắt**|Ẩn CTA hoặc hiển thị no\-permission state|

##### 4\.2\.7\.4\.3 Confirmation modal

|Thành phần|Quy tắc|
|---|---|
|**Overlay**|Nền phía sau dim rõ|
|**Icon**|Warning/danger icon|
|**Title**|`Tắt giá riêng?`|
|**Body**|Nêu rõ giá riêng sẽ không còn áp dụng cho đơn hàng mới|
|**Reason input**|`Lý do tắt (không bắt buộc)`|

##### 4\.2\.7\.4\.4 CTA behavior

|CTA|Hành vi|
|---|---|
|**Giữ giá riêng**|Secondary, đóng modal, không thay đổi dữ liệu|
|**Tắt giá riêng**|Destructive primary, xác nhận tắt|
|**Đang xử lý**|Disable CTA để tránh submit nhiều lần|
|**Lỗi xử lý**|Giữ modal hoặc quay về state lỗi phù hợp|

##### 4\.2\.7\.4\.5 Success và state sau thao tác

|Thành phần|Nội dung|
|---|---|
|**Toast**|`Đã tắt giá riêng`|
|**Status badge**|Cập nhật thành `Đã tắt`|
|**Thông tin tắt**|Hiển thị người tắt, thời gian tắt, lý do nếu có|
|**CTA tiếp theo**|Có thể hiển thị `Bật lại giá riêng` nếu có quyền|

##### 4\.2\.7\.4\.6 Blocked và no\-permission state

|State|Hành vi|
|---|---|
|**Rule đã tắt**|Hiển thị thông báo rule đã tắt, không cho tắt lại|
|**Rule không tồn tại / không thuộc tenant**|Chặn thao tác|
|**Không có quyền**|Hiển thị thông báo không có quyền tắt giá riêng|
|**Dữ liệu vừa thay đổi**|Yêu cầu tải lại trạng thái mới nhất|

#### 4\.2\.7\.5 Designs

[SG\-05](https://hamsacorp.sg.larksuite.com/wiki/RUsxwytCKiwtd9keBzBlLoQ0gob#share-TL3SdfPrmooNqoxe1fHlb9Pwg2e)

#### 4\.2\.7\.6 Scenarios

|ID|Scenario|Given|When|Then|
|---|---|---|---|---|
|**SC\-01**|Mở confirmation tắt|Rule đang có thể tắt và user có quyền|User chọn `Tắt giá riêng`|Hệ thống mở confirmation modal|
|**SC\-02**|Giữ giá riêng|Confirmation đang mở|User chọn `Giữ giá riêng`|Modal đóng và dữ liệu không thay đổi|
|**SC\-03**|Tắt giá riêng thành công|User xác nhận tắt|Hệ thống xử lý thành công|Rule chuyển sang `Đã tắt` và hiển thị toast|
|**SC\-04**|Nhập lý do tắt|User nhập lý do trước khi xác nhận|User xác nhận tắt|Lý do được ghi vào audit log|
|**SC\-05**|Rule đã tắt|Rule đã ở trạng thái `Đã tắt`|User cố thực hiện tắt|Hệ thống chặn thao tác|
|**SC\-06**|Không có quyền tắt|User thiếu quyền|User cố tắt rule|Hệ thống hiển thị no\-permission state|
|**SC\-07**|Trạng thái thay đổi trong lúc xác nhận|Rule bị thay đổi bởi user khác|User xác nhận tắt|Hệ thống yêu cầu tải lại dữ liệu|

#### 4\.2\.7\.7 Edge cases

|ID|Edge Case|Hướng xử lý đề xuất|
|---|---|---|
|**EC\-01**|User bấm tắt nhiều lần|Disable CTA trong lúc xử lý|
|**EC\-02**|Mất mạng khi xác nhận|Hiển thị lỗi và cho thử lại|
|**EC\-03**|Rule vừa được bật/tắt bởi người khác|Re\-check trước khi update và báo dữ liệu đã thay đổi|
|**EC\-04**|Lý do tắt quá dài|Giới hạn ký tự và hiển thị counter|
|**EC\-05**|Rule đang có cảnh báo dưới giá sàn|Vẫn cho tắt nếu user có quyền, vì tắt giúp giảm rủi ro|
|**EC\-06**|Rule hết hiệu lực nhưng chưa tắt|Cho tắt nếu policy muốn dọn trạng thái, hoặc chặn nếu không cần|
|**EC\-07**|Không tải được chi tiết sau khi tắt|Hiển thị toast thành công nhưng cho user refresh lại detail/list|

#### 4\.2\.7\.8 Open questions

|ID|Question|Gợi ý|
|---|---|---|
|**OQ\-01**|Lý do tắt có bắt buộc không?|Đề xuất không bắt buộc, trừ khi giá riêng dưới giá sàn hoặc rule có rủi ro|
|**OQ\-02**|Có cho tắt rule hết hiệu lực không?|Có thể cho tắt để thống nhất lifecycle, nhưng không bắt buộc|
|**OQ\-03**|Sau khi tắt nên ở lại chi tiết hay về danh sách?|Đề xuất ở lại chi tiết với trạng thái `Đã tắt`|
|**OQ\-04**|Có cần thông báo cho nhân viên bán hàng không?|Chưa cần V1; pricing engine chỉ không áp dụng rule mới|
|**OQ\-05**|Có cần tắt hàng loạt không?|Không thuộc US\-07; nếu cần tách story riêng|
|**OQ\-06**|Có cần xác nhận bằng mật khẩu/PIN không?|Chưa cần V1, trừ policy kiểm soát giá yêu cầu|
|**OQ\-07**|Có cần lưu snapshot trước khi tắt không?|Audit log đủ cho V1; snapshot đơn hàng cũ không thay đổi|

### 4\.2\.8 US\-08 — Bật lại giá riêng

#### 4\.2\.8\.1 Business context

US\-08 cho phép Quản lý cửa hàng hoặc Quản trị viên áp dụng lại một giá riêng đã tắt khi chính sách cũ cần tiếp tục sử dụng hoặc thỏa thuận với khách hàng được khôi phục\.

Bật lại giá riêng có rủi ro cao hơn thao tác tắt, vì rule sẽ quay lại ảnh hưởng pricing engine cho đơn hàng mới\. Vì vậy, trước khi bật lại, hệ thống cần kiểm tra rule còn hợp lệ không: khách hàng còn hoạt động, sản phẩm/đơn vị bán còn bán được, hiệu lực còn phù hợp, không trùng rule active khác và không vi phạm policy giá sàn\.

Trigger `Bật lại giá riêng` từ màn chi tiết thuộc US\-03, nên Designs của US\-08 chỉ cover kiểm tra, xác nhận, kết quả và state bị chặn/không có quyền\.

#### 4\.2\.8\.2 Functional requirements

|ID|Functional Requirement|Acceptance Criteria|
|---|---|---|
|**FR\-01**|Mở flow bật lại giá riêng|User có quyền có thể bắt đầu bật lại một rule đã tắt|
|**FR\-02**|Hiển thị tóm tắt rule trước khi bật lại|Hệ thống hiển thị khách hàng, sản phẩm, đơn vị bán, giá riêng, hiệu lực và nguồn tạo|
|**FR\-03**|Kiểm tra điều kiện bật lại|Hệ thống validate trạng thái rule, khách hàng, sản phẩm, đơn vị bán, hiệu lực, trùng rule và giá sàn|
|**FR\-04**|Hiển thị cảnh báo/lỗi trước khi xác nhận|Hệ thống phân biệt lỗi blocking và warning không blocking|
|**FR\-05**|Xác nhận bật lại giá riêng|User xác nhận để chuyển rule sang trạng thái có thể áp dụng|
|**FR\-06**|Hiển thị kết quả bật lại|Hệ thống cập nhật trạng thái, hiển thị toast và ghi audit log|
|**FR\-07**|Chặn thao tác không hợp lệ|Hệ thống chặn nếu user thiếu quyền hoặc rule không đủ điều kiện bật lại|

#### 4\.2\.8\.3 Business rules

|ID|Business Rule|
|---|---|
|**BR\-01**|Chỉ user có quyền bật lại giá riêng mới được xác nhận thao tác|
|**BR\-02**|Chỉ rule ở trạng thái `Đã tắt` mới được bật lại trực tiếp|
|**BR\-03**|Khách hàng, sản phẩm và đơn vị bán của rule phải còn hợp lệ trong tenant hiện tại|
|**BR\-04**|Rule bật lại không được trùng rule active khác cùng khách hàng, sản phẩm, đơn vị bán và giao nhau hiệu lực|
|**BR\-05**|Nếu rule đã hết hiệu lực, user phải sửa hiệu lực trước khi bật lại|
|**BR\-06**|Giá riêng dưới giá sàn phải hiển thị cảnh báo hoặc bị chặn theo policy|
|**BR\-07**|Bật lại chỉ ảnh hưởng đơn hàng mới và phải ghi audit log|

#### 4\.2\.8\.4 UI Contract

##### 4\.2\.8\.4\.1 Mục tiêu màn hình

Flow bật lại giá riêng giúp người dùng khôi phục rule đã tắt một cách an toàn, có kiểm tra điều kiện trước khi rule quay lại áp dụng trong bán hàng\.

##### 4\.2\.8\.4\.2 Entry point

|Entry point|Hành vi|
|---|---|
|**US\-03 → CTA ****`Bật lại giá riêng`**|Mở flow bật lại rule đã tắt|
|**Rule không phải ****`Đã tắt`**|Không hiển thị CTA bật lại hoặc chặn thao tác|
|**Không có quyền bật lại**|Ẩn CTA hoặc hiển thị no\-permission state|

##### 4\.2\.8\.4\.3 Pre\-check screen

|Thành phần|Nội dung|
|---|---|
|**Tóm tắt rule**|Khách hàng, sản phẩm, đơn vị bán, giá riêng, hiệu lực|
|**Trạng thái kiểm tra**|Hợp lệ, cảnh báo, lỗi cần xử lý|
|**Cảnh báo dưới giá sàn**|Hiển thị nếu giá riêng thấp hơn giá sàn hiện tại|
|**Lỗi blocking**|Trùng rule active, hết hiệu lực, sản phẩm/khách hàng không hợp lệ|

##### 4\.2\.8\.4\.4 Confirmation modal

|Thành phần|Quy tắc|
|---|---|
|**Overlay**|Nền phía sau dim rõ|
|**Title**|`Bật lại giá riêng?`|
|**Body**|Nêu rõ giá riêng sẽ áp dụng lại cho đơn hàng mới|
|**CTA phụ**|`Hủy` hoặc `Giữ đã tắt`|
|**CTA chính**|`Bật lại giá riêng` primary xanh|

##### 4\.2\.8\.4\.5 Blocked behavior

|Tình huống|Hành vi|
|---|---|
|**Hết hiệu lực**|Chặn bật lại, gợi ý `Sửa hiệu lực`|
|**Trùng rule active**|Chặn bật lại, gợi ý xem rule đang áp dụng|
|**Sản phẩm/đơn vị bán không hợp lệ**|Chặn bật lại, yêu cầu xử lý dữ liệu|
|**Dưới giá sàn**|Warning hoặc blocking theo policy|

##### 4\.2\.8\.4\.6 Success và feedback

|Thành phần|Nội dung|
|---|---|
|**Toast**|`Đã bật lại giá riêng`|
|**Status badge**|Cập nhật thành `Đang áp dụng` nếu rule đủ điều kiện|
|**Audit**|Ghi người bật lại, thời gian bật lại|
|**Next action**|Quay lại chi tiết rule hoặc danh sách tùy flow|

#### 4\.2\.8\.5 Designs

[SG\-05](https://hamsacorp.sg.larksuite.com/wiki/RUsxwytCKiwtd9keBzBlLoQ0gob#share-TL3SdfPrmooNqoxe1fHlb9Pwg2e)

#### 4\.2\.8\.6 Scenarios

|ID|Scenario|Given|When|Then|
|---|---|---|---|---|
|**SC\-01**|Kiểm tra rule hợp lệ|Rule đã tắt và dữ liệu còn hợp lệ|User chọn bật lại|Hệ thống hiển thị pre\-check hợp lệ|
|**SC\-02**|Xác nhận bật lại|Pre\-check không có lỗi blocking|User xác nhận `Bật lại giá riêng`|Rule chuyển sang `Đang áp dụng`|
|**SC\-03**|Bị chặn do hết hiệu lực|Rule đã quá ngày kết thúc|User cố bật lại|Hệ thống chặn và gợi ý sửa hiệu lực|
|**SC\-04**|Bị chặn do trùng rule active|Đã có rule khác đang áp dụng cùng key|User cố bật lại|Hệ thống chặn và gợi ý xem rule đang áp dụng|
|**SC\-05**|Cảnh báo dưới giá sàn|Giá riêng thấp hơn giá sàn hiện tại|User kiểm tra bật lại|Hệ thống hiển thị warning hoặc chặn theo policy|
|**SC\-06**|Không có quyền bật lại|User thiếu quyền|User cố bật lại rule|Hệ thống hiển thị no\-permission state|
|**SC\-07**|Hủy thao tác bật lại|Confirmation đang mở|User chọn hủy|Rule vẫn ở trạng thái `Đã tắt`|

#### 4\.2\.8\.7 Edge cases

|ID|Edge Case|Hướng xử lý đề xuất|
|---|---|---|
|**EC\-01**|Rule vừa được bật lại bởi người khác|Re\-check trạng thái và thông báo dữ liệu đã thay đổi|
|**EC\-02**|Giá sàn thay đổi trong lúc pre\-check|Re\-check giá sàn tại thời điểm xác nhận|
|**EC\-03**|Khách hàng bị khóa sau khi mở pre\-check|Chặn bật lại và yêu cầu tải lại dữ liệu|
|**EC\-04**|Sản phẩm hoặc đơn vị bán bị ngừng bán|Chặn bật lại và gợi ý sửa/chọn lại bằng flow phù hợp|
|**EC\-05**|User bấm xác nhận nhiều lần|Disable CTA trong lúc xử lý|
|**EC\-06**|Mất mạng khi xác nhận|Hiển thị lỗi và giữ nguyên trạng thái `Đã tắt` nếu chưa update thành công|
|**EC\-07**|Rule nguồn migration thiếu audit cũ|Vẫn cho bật lại nếu dữ liệu hợp lệ; audit bật lại phải ghi đầy đủ|

#### 4\.2\.8\.8 Open questions

|ID|Question|Gợi ý|
|---|---|---|
|**OQ\-01**|Rule hết hiệu lực có được bật lại trực tiếp không?|Đề xuất không; yêu cầu sửa hiệu lực trước|
|**OQ\-02**|Dưới giá sàn khi bật lại là warning hay blocking?|Theo policy; mặc định warning nếu user có quyền, blocking nếu không có quyền override|
|**OQ\-03**|Sau khi bật lại nên quay lại chi tiết hay danh sách?|Đề xuất quay lại chi tiết rule với trạng thái mới|
|**OQ\-04**|Có cần nhập lý do bật lại không?|Đề xuất không bắt buộc; audit đã ghi người và thời gian|
|**OQ\-05**|Có cho bật lại rule có sản phẩm ngừng bán không?|Không, cần xử lý sản phẩm trước|
|**OQ\-06**|Có cần confirmation nếu pre\-check hoàn toàn hợp lệ không?|Đề xuất vẫn cần confirmation vì rule quay lại ảnh hưởng bán hàng|
|**OQ\-07**|Có cần thông báo cho nhân viên bán hàng sau khi bật lại không?|Chưa cần V1; pricing engine tự áp dụng cho đơn hàng mới|

### 4\.2\.9 US\-09 — Ghi nhận nhớ giá từ lần bán hàng

#### 4\.2\.9\.1 Business context

Trong luồng bán hàng, khi nhân viên bán cho một khách hàng cụ thể với một mức giá khác giá hiện tại, hệ thống bán hàng có thể gợi ý: `Có lưu lại giá này cho khách không?`\. Nếu người dùng chọn lưu, Sales gửi yêu cầu sang Pricing / EP02 để ghi nhận mức giá đó thành một rule nhớ giá\.

US này không thiết kế lại luồng bán hàng, không xử lý màn tạo đơn, thanh toán, xác nhận đơn hoặc prompt trong Sales\. US này chỉ cover phần EP02 chịu trách nhiệm: tiếp nhận yêu cầu lưu nhớ giá từ đơn hàng, validate điều kiện, tạo hoặc cập nhật rule nhớ giá, gắn nguồn `Từ đơn hàng`, ghi audit log và làm cho rule này xuất hiện trong danh sách, chi tiết và lịch sử giá riêng / nhớ giá\.

#### 4\.2\.9\.2 Functional requirements

|ID|Functional Requirement|Acceptance Criteria|
|---|---|---|
|**FR\-01**|Tiếp nhận yêu cầu lưu nhớ giá từ bán hàng|Khi Sales gửi yêu cầu lưu giá sau giao dịch, EP02 nhận đủ thông tin khách hàng, sản phẩm, đơn vị bán, giá bán thực tế và đơn hàng liên quan|
|**FR\-02**|Validate điều kiện ghi nhận nhớ giá|Hệ thống kiểm tra khách hàng, sản phẩm, đơn vị bán, giá bán, quyền thao tác, trạng thái đơn và rule hiện có|
|**FR\-03**|Tạo mới rule nhớ giá|Nếu chưa có rule phù hợp, hệ thống tạo rule nhớ giá cho khách hàng × sản phẩm × đơn vị bán|
|**FR\-04**|Cập nhật rule nhớ giá hiện có|Nếu đã có rule nhớ giá phù hợp, hệ thống cập nhật giá hoặc thời điểm ghi nhận theo rule nghiệp vụ|
|**FR\-05**|Phân biệt nguồn tạo từ đơn hàng|Rule được tạo/cập nhật từ Sales phải có nguồn `Từ đơn hàng` và liên kết đến đơn hàng gốc|
|**FR\-06**|Hiển thị rule trong quản lý giá|Rule nhớ giá sau khi ghi nhận phải xuất hiện ở danh sách, chi tiết và lịch sử của EP02|
|**FR\-07**|Trả kết quả cho Sales|EP02 trả về kết quả thành công, bị chặn hoặc không có quyền để Sales hiển thị feedback phù hợp|

#### 4\.2\.9\.3 Business rules

|ID|Business Rule|
|---|---|
|**BR\-01**|Chỉ ghi nhận nhớ giá cho đơn hàng có khách hàng cụ thể, không ghi nhận cho khách lẻ mặc định nếu không có định danh khách hàng|
|**BR\-02**|Key của nhớ giá là khách hàng × sản phẩm × đơn vị bán trong tenant hiện tại|
|**BR\-03**|Giá bán được lưu phải lớn hơn 0 và là giá sau khi người bán đã xác nhận trong đơn hàng|
|**BR\-04**|Không ghi nhận nhớ giá nếu đơn hàng bị hủy hoặc chưa đạt trạng thái được phép lưu theo rule của Sales|
|**BR\-05**|Nếu đã có giá riêng thủ công active cho cùng key, hệ thống không tự ghi đè nếu policy chưa cho phép|
|**BR\-06**|Giá nhớ thấp hơn giá sàn phải được cảnh báo hoặc bị chặn theo policy kiểm soát giá|
|**BR\-07**|Mọi lần tạo/cập nhật nhớ giá từ đơn hàng phải ghi audit log gồm đơn hàng nguồn, người thực hiện và thời gian|

#### 4\.2\.9\.4 UI Contract

##### 4\.2\.9\.4\.1 Mục tiêu nghiệp vụ

US\-09 đảm bảo mức giá thực tế đã được người dùng xác nhận trong bán hàng có thể được ghi nhận thành nhớ giá một cách có kiểm soát, giúp các lần bán sau cho cùng khách hàng có mức giá quen thuộc và nhất quán\.

##### 4\.2\.9\.4\.2 Scope boundary với Sales

|Phạm vi|Thuộc module|
|---|---|
|Phát hiện trong đơn hàng có giá khác giá hiện tại|Sales|
|Hiển thị gợi ý `Lưu giá này cho khách?` trong luồng bán hàng|Sales|
|Người dùng chọn lưu / không lưu trong lúc bán hàng|Sales|
|Gửi request lưu nhớ giá sang Pricing|Sales → EP02|
|Validate, tạo/cập nhật rule nhớ giá|EP02|
|Hiển thị rule trong danh sách/chi tiết/lịch sử giá riêng|EP02|
|Áp dụng rule nhớ giá cho lần bán sau|Pricing engine / Sales integration|

##### 4\.2\.9\.4\.3 Input từ Sales sang EP02

|Field|Bắt buộc|Ghi chú|
|---|---|---|
|`tenant_id`|Có|Xác định phạm vi dữ liệu|
|`order_id`|Có|Đơn hàng nguồn|
|`customer_id`|Có|Không dùng khách lẻ mặc định nếu không có định danh|
|`product_id` / `sku_id`|Có|Sản phẩm hoặc SKU được bán|
|`selling_unit_id`|Có|Đơn vị bán thực tế trong đơn|
|`sold_price`|Có|Giá bán đã được xác nhận trong đơn|
|`actor_user_id`|Có|Người thực hiện thao tác lưu|
|`sold_at`|Có|Thời điểm phát sinh giao dịch|

##### 4\.2\.9\.4\.4 Output từ EP02 trả về Sales

|Kết quả|Nội dung|
|---|---|
|**Created**|Đã tạo mới nhớ giá|
|**Updated**|Đã cập nhật nhớ giá hiện có|
|**Skipped**|Không ghi nhận vì user không chọn lưu hoặc request không cần xử lý|
|**Blocked**|Bị chặn do rule trùng, dưới giá sàn, dữ liệu không hợp lệ hoặc policy|
|**No permission**|User không có quyền lưu nhớ giá|
|**Error**|Lỗi hệ thống, Sales có thể hiển thị feedback thử lại|

##### 4\.2\.9\.4\.5 Rule hiển thị trong EP02

|Khu vực|Quy tắc hiển thị|
|---|---|
|**Danh sách giá riêng / nhớ giá**|Rule xuất hiện như item bình thường, nguồn tạo là `Từ đơn hàng`|
|**Chi tiết giá riêng**|Hiển thị đơn hàng nguồn, giá đã lưu, hiệu lực, trạng thái và audit|
|**Lịch sử**|Có activity `Ghi nhận nhớ giá từ đơn hàng` hoặc `Cập nhật nhớ giá từ đơn hàng`|
|**Cảnh báo**|Nếu dưới giá sàn hoặc conflict, hiển thị badge/cảnh báo tương ứng|

##### 4\.2\.9\.4\.6 Permission behavior

|Trường hợp|Hành vi|
|---|---|
|User có quyền lưu nhớ giá|Cho phép tạo/cập nhật rule nếu dữ liệu hợp lệ|
|User chỉ có quyền bán hàng, không có quyền lưu nhớ giá|Sales không nên hiển thị lựa chọn lưu hoặc EP02 trả `No permission`|
|User có quyền override dưới giá sàn|Có thể lưu nếu policy cho phép|
|User không có quyền override dưới giá sàn|EP02 trả `Blocked` nếu giá dưới sàn bị chặn|

##### 4\.2\.9\.4\.7 Feedback và audit

|Thành phần|Nội dung|
|---|---|
|**Feedback cho Sales**|Trả kết quả ngắn để Sales hiển thị toast hoặc inline feedback|
|**Audit log**|Ghi người lưu, thời gian lưu, đơn hàng nguồn, giá cũ, giá mới|
|**Source**|Luôn lưu nguồn `Từ đơn hàng`|
|**Liên kết ngữ cảnh**|Từ chi tiết nhớ giá có thể xem đơn hàng nguồn nếu user có quyền|

#### 4\.2\.9\.5 Designs

***Xem Theme 5***

|Design ID|Màn hình / State|Coverage|
|---|---|---|
|**D\-01**|Ghi nhận nhớ giá thành công từ đơn hàng|FR\-03, FR\-05, FR\-06|
|**D\-02**|Cập nhật nhớ giá hiện có từ đơn hàng|FR\-04, FR\-05|
|**D\-03**|Bị chặn do giá riêng thủ công đang áp dụng|FR\-02, FR\-07, BR\-05|
|**D\-04**|Bị chặn do dưới giá sàn / policy|FR\-02, FR\-07, BR\-06|
|**D\-05**|Không có quyền lưu nhớ giá|FR\-02, FR\-07|
|**D\-06**|Lịch sử activity từ đơn hàng|FR\-06, BR\-07|

#### 4\.2\.9\.6 Scenarios

|ID|Scenario|Given|When|Then|
|---|---|---|---|---|
|**SC\-01**|Tạo mới nhớ giá từ đơn hàng|Đơn hàng có khách hàng cụ thể và chưa có rule cùng key|Sales gửi request lưu nhớ giá|EP02 tạo rule nhớ giá nguồn `Từ đơn hàng`|
|**SC\-02**|Cập nhật nhớ giá hiện có|Đã có rule nhớ giá cùng khách hàng, sản phẩm, đơn vị bán|Sales gửi giá bán mới được xác nhận|EP02 cập nhật rule theo policy|
|**SC\-03**|Không ghi đè giá riêng thủ công|Đã có giá riêng thủ công active cùng key|Sales gửi request lưu nhớ giá|EP02 chặn hoặc yêu cầu xử lý theo policy|
|**SC\-04**|Chặn khách lẻ|Đơn hàng dùng khách lẻ mặc định không có định danh|Sales gửi request lưu nhớ giá|EP02 không tạo rule nhớ giá|
|**SC\-05**|Cảnh báo hoặc chặn dưới giá sàn|Giá bán thực tế thấp hơn giá sàn|Sales gửi request lưu nhớ giá|EP02 cảnh báo hoặc chặn theo quyền/policy|
|**SC\-06**|Không có quyền lưu|User không có quyền lưu nhớ giá|Sales gửi request|EP02 trả `No permission`|
|**SC\-07**|Ghi lịch sử|Rule được tạo hoặc cập nhật từ đơn hàng|EP02 xử lý thành công|Lịch sử rule có activity liên kết đến đơn hàng nguồn|

#### 4\.2\.9\.7 Edge cases

|ID|Edge Case|Hướng xử lý đề xuất|
|---|---|---|
|**EC\-01**|Đơn hàng bị hủy sau khi đã lưu nhớ giá|Không tự xóa rule; ghi thêm activity nếu policy yêu cầu review|
|**EC\-02**|Một đơn có nhiều dòng cùng sản phẩm và đơn vị nhưng giá khác nhau|Chỉ lưu theo dòng được user xác nhận lưu hoặc chặn nếu request không rõ|
|**EC\-03**|Giá bán thực tế bằng giá hiện tại|Có thể không gợi ý lưu ở Sales; nếu gửi sang EP02 thì trả `Skipped`|
|**EC\-04**|Sản phẩm hoặc đơn vị bán bị ngừng kinh doanh|Chặn tạo/cập nhật nhớ giá|
|**EC\-05**|Request lưu bị gửi nhiều lần|EP02 xử lý idempotent theo `order_id + order_line_id + key` nếu có|
|**EC\-06**|Không tìm thấy giá sàn tại thời điểm lưu|Vẫn có thể lưu nếu policy cho phép, nhưng gắn cảnh báo cần kiểm tra|
|**EC\-07**|User bán hàng có quyền bán nhưng không có quyền quản lý giá|Sales không nên hiển thị option lưu; EP02 vẫn phải re\-check quyền khi nhận request|

#### 4\.2\.9\.8 Open questions

|ID|Question|Gợi ý|
|---|---|---|
|**OQ\-01**|Nhớ giá từ đơn hàng có nên tự active ngay không?|Đề xuất active ngay nếu không vi phạm policy|
|**OQ\-02**|Nếu đã có giá riêng thủ công, giá từ đơn hàng có được ghi nhận như history tham khảo không?|Đề xuất không ghi đè rule, nhưng có thể lưu activity tham khảo nếu cần|
|**OQ\-03**|Có cần ngày hết hiệu lực mặc định cho nhớ giá từ đơn hàng không?|Đề xuất `Không giới hạn` trong V1, có thể cấu hình sau|
|**OQ\-04**|Có cần lưu theo từng dòng đơn hàng hay theo sản phẩm tổng hợp trong đơn?|Đề xuất theo từng dòng đơn hàng để giữ đúng đơn vị bán và giá thực tế|
|**OQ\-05**|Có cần confirmation trong EP02 không?|Không; confirmation/prompt thuộc Sales, EP02 chỉ xử lý request đã xác nhận|
|**OQ\-06**|Nhớ giá có khác giá riêng thủ công về độ ưu tiên không?|Đề xuất giá riêng thủ công ưu tiên hơn nhớ giá từ đơn hàng|
|**OQ\-07**|Có cần role riêng `Lưu nhớ giá từ bán hàng` không?|Đề xuất có quyền riêng để không đồng nhất với quyền tạo giá riêng thủ công|

### 4\.2\.10 US\-10 — Kiểm tra lịch sử áp dụng và thay đổi giá riêng / nhớ giá

#### 4\.2\.10\.1 Business context

US\-10 cho phép Chủ doanh nghiệp, Kế toán, Quản lý cửa hàng hoặc Người kiểm soát truy vết lịch sử liên quan đến một giá riêng / nhớ giá\.

Lịch sử này phục vụ kiểm soát nội bộ: ai tạo giá, ai sửa, ai tắt, ai bật lại, giá nào được ghi nhận từ đơn hàng, rule đã được áp dụng trong đơn hàng nào và có thay đổi nào khiến bán dưới giá sàn hoặc ảnh hưởng chính sách giá hay không\.

US này không xử lý việc tạo, sửa, tắt, bật lại hoặc lưu nhớ giá từ bán hàng\. US này chỉ cover việc xem, lọc, kiểm tra và truy vết lịch sử đã phát sinh từ các US trước đó\.

#### 4\.2\.10\.2 Functional requirements

|ID|Functional Requirement|Acceptance Criteria|
|---|---|---|
|**FR\-01**|Hiển thị lịch sử của một rule giá riêng / nhớ giá|Người dùng có quyền có thể xem danh sách activity liên quan đến rule|
|**FR\-02**|Phân loại loại lịch sử|Hệ thống phân biệt tạo mới, sửa, tắt, bật lại, import Excel, ghi nhận từ đơn hàng và áp dụng trong bán hàng|
|**FR\-03**|Hiển thị thông tin từng activity|Mỗi activity hiển thị thời gian, người thực hiện, hành động, nguồn và nội dung thay đổi chính|
|**FR\-04**|Xem chi tiết một activity|Người dùng có thể xem diff trước/sau, lý do, nguồn và liên kết dữ liệu liên quan nếu có|
|**FR\-05**|Kiểm soát quyền xem dữ liệu nhạy cảm|Hệ thống ẩn giá sàn, chênh lệch hoặc dữ liệu nhạy cảm nếu user không có quyền|
|**FR\-06**|Điều hướng sang dữ liệu liên quan|Người dùng có thể mở đơn hàng nguồn, file import hoặc rule liên quan nếu có quyền|

#### 4\.2\.10\.3 Business rules

|ID|Business Rule|
|---|---|
|**BR\-01**|Lịch sử chỉ hiển thị dữ liệu thuộc tenant hiện tại và trong phạm vi quyền của người dùng|
|**BR\-02**|Mọi thay đổi tạo/sửa/tắt/bật lại/import/ghi nhận từ đơn hàng phải có audit log|
|**BR\-03**|Activity phải giữ snapshot giá trị tại thời điểm xảy ra, không bị thay đổi bởi dữ liệu hiện tại|
|**BR\-04**|Dữ liệu đơn hàng cũ phải giữ snapshot giá đã bán, không bị thay đổi khi rule giá riêng thay đổi|
|**BR\-05**|User không có quyền xem giá sàn sẽ không thấy giá sàn và chênh lệch với giá sàn trong lịch sử|
|**BR\-06**|Liên kết sang đơn hàng, file import hoặc user chỉ khả dụng khi người dùng có quyền truy cập đối tượng đó|
|**BR\-07**|Lịch sử là dữ liệu kiểm soát, không cho sửa hoặc xóa từ UI nghiệp vụ thông thường|

#### 4\.2\.10\.4 UI Contract

##### 4\.2\.10\.4\.1 Mục tiêu màn hình

Màn hình lịch sử giúp người dùng kiểm tra toàn bộ dấu vết thay đổi và áp dụng của một rule giá riêng / nhớ giá để phục vụ kiểm soát, đối soát và xử lý tranh chấp nếu có\.

##### 4\.2\.10\.4\.2 Entry point

|Entry point|Hành vi|
|---|---|
|**US\-03 — Chi tiết giá riêng → ****`Lịch sử áp dụng & thay đổi`**|Mở lịch sử của rule đang xem|
|**Sau khi tạo/sửa/tắt/bật lại thành công**|Có thể điều hướng sang lịch sử nếu người dùng cần kiểm tra audit|
|**Từ activity liên quan trong hệ thống**|Mở lịch sử nếu user có quyền|

##### 4\.2\.10\.4\.3 Top bar

|Thành phần|Quy tắc|
|---|---|
|**Back icon**|Dùng `←`|
|**Title**|`Lịch sử giá riêng` hoặc `Lịch sử nhớ giá` tùy context|
|**Right icon**|Không hiển thị reload hoặc icon thừa|
|**Context summary**|Hiển thị rule đang xem: khách hàng, sản phẩm, đơn vị bán, trạng thái|

##### 4\.2\.10\.4\.4 Danh sách lịch sử

|Thành phần|Nội dung|
|---|---|
|**Timeline item**|Thời gian, người thực hiện, hành động, nguồn|
|**Action type**|`Tạo`, `Sửa`, `Tắt`, `Bật lại`, `Nhập Excel`, `Từ đơn hàng`, `Áp dụng trong bán hàng`|
|**Summary**|Mô tả ngắn thay đổi chính, ví dụ `Giá đổi từ 95.000đ → 100.200đ`|
|**Badge nguồn**|`Tạo thủ công`, `Nhập Excel`, `Từ đơn hàng`, `Hệ thống`|
|**Chevron**|Có `›` nếu activity có màn chi tiết|

##### 4\.2\.10\.4\.5 Filter behavior

|Bộ lọc|Lựa chọn|
|---|---|
|**Loại hành động**|Tất cả, Tạo, Sửa, Tắt, Bật lại, Áp dụng trong bán hàng|
|**Nguồn**|Tất cả, Tạo thủ công, Nhập Excel, Từ đơn hàng, Hệ thống|
|**Người thực hiện**|Chọn user nếu có dữ liệu|
|**Thời gian**|Hôm nay, 7 ngày qua, 30 ngày qua, Tùy chỉnh|

##### 4\.2\.10\.4\.6 Chi tiết activity

|Thành phần|Nội dung|
|---|---|
|**Thông tin chung**|Hành động, thời gian, người thực hiện, nguồn|
|**Diff trước/sau**|Giá, hiệu lực, trạng thái hoặc trường thay đổi|
|**Lý do**|Hiển thị nếu activity có lý do|
|**Liên kết liên quan**|Đơn hàng nguồn, file import, rule đang áp dụng hoặc user thực hiện|
|**Dữ liệu bị ẩn**|Hiển thị `Ẩn theo quyền` nếu user không được xem|

##### 4\.2\.10\.4\.7 Empty / Error / Permission states

|State|Nội dung|CTA|
|---|---|---|
|**Empty**|`Chưa có lịch sử thay đổi`|Không cần CTA chính|
|**No result**|`Không tìm thấy lịch sử phù hợp`|`Xóa bộ lọc`|
|**Error**|`Không thể tải lịch sử`|`Thử lại`|
|**No permission**|`Bạn không có quyền xem lịch sử giá riêng`|`Quay lại`|

#### 4\.2\.10\.5 Designs

[SG\-06](https://hamsacorp.sg.larksuite.com/wiki/RUsxwytCKiwtd9keBzBlLoQ0gob#share-TkDrdzqeaosPf8xT9GtlYZCwgHe)

#### 4\.2\.10\.6 Scenarios

|ID|Scenario|Given|When|Then|
|---|---|---|---|---|
|**SC\-01**|Xem timeline lịch sử|Rule có nhiều activity|User mở `Lịch sử áp dụng & thay đổi`|Hệ thống hiển thị timeline theo thời gian mới nhất trước|
|**SC\-02**|Xem chi tiết thay đổi giá|Activity là sửa giá riêng|User tap activity|Hệ thống hiển thị giá trước/sau, người sửa, thời gian và lý do nếu có|
|**SC\-03**|Kiểm tra nhớ giá từ đơn hàng|Rule được tạo từ Sales|User mở activity `Từ đơn hàng`|Hệ thống hiển thị đơn hàng nguồn nếu user có quyền|
|**SC\-04**|Lọc theo nguồn import Excel|Lịch sử có nhiều nguồn|User chọn nguồn `Nhập Excel`|Hệ thống chỉ hiển thị activity từ import|
|**SC\-05**|Ẩn giá sàn theo quyền|User không có quyền xem giá sàn|User mở lịch sử có diff liên quan giá sàn|Hệ thống ẩn giá sàn và chênh lệch với giá sàn|
|**SC\-06**|Không có kết quả sau khi lọc|Bộ lọc không khớp activity nào|User áp dụng bộ lọc|Hệ thống hiển thị no\-result state|
|**SC\-07**|Không có quyền xem lịch sử|User thiếu quyền audit/history|User mở màn lịch sử|Hệ thống hiển thị no\-permission state|

#### 4\.2\.10\.7 Edge cases

|ID|Edge Case|Hướng xử lý đề xuất|
|---|---|---|
|**EC\-01**|Activity cũ thiếu người thực hiện do migration|Hiển thị `Không có dữ liệu người thực hiện` và nguồn `Migration` nếu có|
|**EC\-02**|Đơn hàng nguồn đã bị hủy|Vẫn hiển thị activity và trạng thái đơn hàng hiện tại nếu user có quyền|
|**EC\-03**|User thực hiện đã bị khóa hoặc xóa mềm|Vẫn hiển thị tên snapshot hoặc fallback user ID|
|**EC\-04**|Activity có dữ liệu nhạy cảm nhưng user thiếu quyền|Ẩn trường nhạy cảm, không ẩn toàn bộ activity nếu policy cho phép|
|**EC\-05**|Lịch sử rất dài|Dùng pagination hoặc infinite scroll|
|**EC\-06**|File import liên quan không còn khả dụng|Hiển thị activity, nhưng link file bị disabled kèm lý do|
|**EC\-07**|Dữ liệu hiện tại khác snapshot lịch sử|Luôn hiển thị snapshot tại thời điểm activity và ghi rõ nếu cần|

#### 4\.2\.10\.8 Open questions

|ID|Question|Gợi ý|
|---|---|---|
|**OQ\-01**|Lịch sử có cần hiển thị cả lần rule được áp dụng trong từng đơn hàng không?|Đề xuất có, nhưng có thể phân nhóm `Áp dụng trong bán hàng` để tránh timeline quá dài|
|**OQ\-02**|Có cần export lịch sử không?|Chưa cần V1; nếu cần audit nâng cao có thể tách story riêng|
|**OQ\-03**|Activity từ Sales nên link đến đơn hàng hay dòng đơn hàng?|Đề xuất link đến đơn hàng, và hiển thị dòng sản phẩm liên quan trong detail|
|**OQ\-04**|Có cần lưu IP/device khi thay đổi giá không?|Có thể bổ sung sau nếu cần kiểm soát rủi ro nâng cao|
|**OQ\-05**|Có cần lọc theo `dưới giá sàn` trong lịch sử không?|Đề xuất chưa đưa vào V1, chỉ hiển thị cảnh báo trong activity liên quan|
|**OQ\-06**|Có cần phân biệt lịch sử thay đổi rule và lịch sử áp dụng rule thành 2 tab không?|Đề xuất giữ một timeline trong V1, dùng filter để giảm phức tạp|
|**OQ\-07**|Người dùng kế toán có được xem giá sàn không?|Theo policy quyền; mặc định chỉ user có quyền kiểm soát giá mới xem giá sàn|

## 4\.3 Epic\-level Screen Map \& Design Visuals

Phần này mô tả **danh sách màn hình ở cấp Epic** cho **EP02 — Giá riêng / Nhớ giá**\. Danh sách này không tổ chức theo từng User Story riêng lẻ, mà gom theo **screen group** để tránh lặp màn hình, đồng thời vẫn đảm bảo cover đủ các tình huống nghiệp vụ, trạng thái, lỗi, phân quyền và các luồng thao tác chính\.

Mỗi **screen group** bên dưới gồm một **bảng screen map**\. Sau mỗi bảng, phần **design visuals** sẽ được bổ sung trực tiếp bằng ảnh thiết kế tương ứng\.

### SG\-01 — Danh sách \& kiểm soát nhanh

![image\.png](Images_attachments/image.png)

### SG\-02 — Chi tiết \& action

![image\.png](Images_attachments/image%201.png)

### SG\-03 — Tạo / sửa giá riêng

![image\.png](Images_attachments/image%2020.png)

![image\.png](Images_attachments/image%2021.png)

### SG\-04 — Nhập Excel

![image\.png](Images_attachments/image%2019.png)

![image\.png](Images_attachments/image%2024.png)

### SG\-05 — Tắt / bật lại giá riêng

![image\.png](Images_attachments/image%2022.png)

![image\.png](Images_attachments/image%207.png)

### SG\-06 — Nhớ giá \& lịch sử

![image\.png](Images_attachments/image%2011.png)

# 5\. Epic EP03 — Chương trình khuyến mại

## 5\.1 Epic overview

Epic này giúp người dùng **tạo, quản lý và kiểm soát vòng đời các chương trình khuyến mại**\.

Khác với giá bán cơ bản hoặc giá riêng, CTKM thường có:

- Mục tiêu kinh doanh cụ thể

- Thời gian hiệu lực

- Điều kiện áp dụng

- Phạm vi áp dụng

- Cơ chế ưu đãi riêng

- Rủi ro xung đột với chính sách khác

EP03 sẽ được tổ chức theo hướng:

**Common lifecycle \+ Type\-specific user stories**

Tức là có một số user story dùng chung cho mọi CTKM, và mỗi loại CTKM chính sẽ là một user story riêng vì nó phản ánh **mục đích cụ thể trong đầu người dùng**\.

Xem thêm [Promotion mechanics](https://hamsacorp.sg.larksuite.com/wiki/RUsxwytCKiwtd9keBzBlLoQ0gob#share-DH7md6qLnoDkgkxvRRLlVxxQgEc)\.

## 5\.2 Domain Foundation \& Entity

### 5\.2\.1 Conceptual ERD

Mục này mô tả quan hệ khái niệm giữa các entity chính trong Epic EP03 — Chương trình khuyến mại\. Đây là ERD ở mức conceptual, phục vụ BA/Product/UX/SA cùng hiểu cấu trúc nghiệp vụ, chưa phải DB schema chi tiết\.

```Plain Text
PromotionType
  └── Promotion
        ├── PromotionBenefit
        ├── PromotionRule
        ├── PromotionScope
        │     └── PromotionScopeItem
        ├── PromotionCoupon
        ├── PromotionValidationResult
        │     └── PromotionValidationIssue
        ├── PromotionConflict
        ├── PromotionRevision
        ├── PromotionActionLog
        ├── PromotionBulkOperationItem
        └── PromotionUsage
PromotionTemplate
  └── creates Promotion draft
PromotionBulkOperation
  └── PromotionBulkOperationItem
        └── Promotion
SalesOrder
  └── AppliedPromotion
        └── references Promotion
```

Ghi chú:

- `Promotion` là aggregate root của Epic EP03\.

- `PromotionType` định nghĩa loại CTKM và cơ chế ưu đãi được hỗ trợ\.

- `PromotionTemplate` là mẫu tạo nhanh, không phải CTKM đang chạy\.

- `PromotionBenefit`, `PromotionRule`, `PromotionScope`, `PromotionCoupon` là các thành phần cấu hình của CTKM\.

- `PromotionValidationResult`, `PromotionValidationIssue`, `PromotionConflict` phục vụ kiểm tra tính hợp lệ trước khi bật hoặc bật lại CTKM\.

- `PromotionRevision` và `PromotionActionLog` phục vụ versioning và audit\.

- `AppliedPromotion` là snapshot CTKM đã được áp dụng vào đơn hàng\.

- `PromotionUsage` phục vụ kiểm soát giới hạn sử dụng CTKM/coupon\.

### 5\.2\.2 Entity Mapping

|**Entity**|**Nhóm**|**Ý nghĩa nghiệp vụ**|
|---|---|---|
|`Promotion`|Core<br>|CTKM cụ thể được tạo, kiểm tra, bật, tạm dừng, bật lại, kết thúc, hủy hoặc nhân bản\. Đây là aggregate root của EP03\.|
|`PromotionType`|Setup|Loại CTKM mà hệ thống hỗ trợ, ví dụ giảm giá sản phẩm, giảm giá đơn hàng, mua X tặng Y, combo, voucher\.|
|`PromotionTemplate`|Setup|Mẫu CTKM có sẵn để người dùng tạo nhanh CTKM mới với cấu hình gợi ý\.|
|`PromotionBenefit`|Configuration|Quyền lợi mà khách hàng được hưởng khi CTKM được áp dụng, ví dụ giảm %, giảm số tiền, giá cố định, tặng hàng\.|
|`PromotionRule`|Configuration|Điều kiện giao dịch phải đạt để CTKM được áp dụng, ví dụ đơn từ một giá trị nhất định, mua đủ số lượng, thuộc nhóm khách hàng\.|
|`PromotionScope`|Configuration|Phạm vi áp dụng của CTKM, ví dụ sản phẩm, nhóm sản phẩm, khách hàng, nhóm khách hàng, chi nhánh, kênh bán\.|
|`PromotionScopeItem`|Configuration|Một đối tượng cụ thể nằm trong phạm vi áp dụng, ví dụ một sản phẩm, một nhóm sản phẩm, một khách hàng hoặc một chi nhánh\.|
|`PromotionCoupon`|Configuration|Mã khuyến mại hoặc voucher gắn với CTKM nếu chương trình yêu cầu người bán/khách nhập mã\.|
|`PromotionValidationResult`|Validation|Kết quả kiểm tra CTKM tại một thời điểm và version cụ thể\.|
|`PromotionValidationIssue`|Validation|Một lỗi hoặc cảnh báo cụ thể được phát hiện trong quá trình kiểm tra CTKM\.|
|`PromotionConflict`|Validation|Xung đột giữa CTKM này với CTKM hoặc chính sách giá khác\.|
|`PromotionRevision`|Lifecycle|Snapshot cấu hình CTKM theo từng version quan trọng để phục vụ đối chiếu và audit\.|
|`PromotionActionLog`|Lifecycle|Lịch sử thao tác trên CTKM, ghi nhận ai làm gì, khi nào, từ trạng thái nào sang trạng thái nào, kết quả ra sao\.|
|`PromotionBulkOperation`|Bulk|Một lần thao tác hàng loạt trên nhiều CTKM, ví dụ tạm dừng hàng loạt, kết thúc hàng loạt, xóa nháp hàng loạt\.|
|`PromotionBulkOperationItem`|Bulk|Kết quả xử lý của từng CTKM trong một bulk operation\.|
|`AppliedPromotion`|Runtime|CTKM đã được áp dụng vào một đơn hàng hoặc dòng hàng cụ thể\. Đây là snapshot phục vụ đọc lại đơn hàng cũ\.|
|`PromotionUsage`|Runtime|Bộ đếm lượt sử dụng CTKM/coupon để kiểm soát giới hạn dùng theo chương trình, khách hàng hoặc mã coupon\.|

### 5\.2\.3 Entity Catalogue

#### Entity: `Promotion`

|Field|Description|Enum / Note|
|---|---|---|
|`id`|ID của CTKM|UUID|
|`tenant_id`|Tenant sở hữu CTKM|Required|
|`code`|Mã CTKM|Unique trong tenant|
|`name`|Tên CTKM|Required|
|`description`|Mô tả CTKM|Optional|
|`promotion_type_id`|Loại CTKM|FK → `PromotionType`|
|`lifecycle_status`|Trạng thái vòng đời được lưu trong hệ thống|`draft`, `active`, `paused`, `ended`, `cancelled`, `deleted_draft`, `archived`|
|`source_type`|Nguồn tạo CTKM|`manual`, `template`, `duplicated`, `system_migration`|
|`source_promotion_id`|CTKM nguồn nếu được nhân bản|Optional|
|`template_id`|Template nguồn nếu tạo từ mẫu|Optional|
|`start_at`|Thời gian bắt đầu hiệu lực|Optional nếu `is_always_on = true`|
|`end_at`|Thời gian kết thúc hiệu lực|Optional nếu `is_always_on = true`|
|`timezone`|Múi giờ áp dụng|Default theo tenant|
|`is_always_on`|CTKM không giới hạn thời gian|Boolean|
|`status_reason`|Lý do tạm dừng, kết thúc hoặc hủy nếu có|Optional|
|`owner_id`|Người phụ trách CTKM|Optional|
|`version`|Version hiện tại của CTKM|Dùng chống stale update|
|`last_checked_at`|Thời điểm kiểm tra gần nhất|Optional|
|`activated_at`|Thời điểm bật CTKM|Optional|
|`paused_at`|Thời điểm tạm dừng CTKM|Optional|
|`ended_at`|Thời điểm kết thúc CTKM|Optional|
|`cancelled_at`|Thời điểm hủy CTKM|Optional|
|`deleted_at`|Thời điểm xóa nháp|Optional|

#### Entity: `PromotionType`

|Field|Description|Enum / Note|
|---|---|---|
|`id`|ID loại CTKM|UUID|
|`code`|Mã loại CTKM|Ví dụ: `product_discount`, `order_discount`|
|`name`|Tên loại CTKM|Required|
|`description`|Mô tả loại CTKM|Optional|
|`application_level`|Cấp áp dụng mặc định|`line_item`, `order`, `mixed`|
|`stacking_policy_code`|Rule mặc định khi chồng nhiều CTKM|Phase 1 dùng code hệ thống|
|`is_active`|Loại CTKM có đang khả dụng không|Boolean|
|`display_order`|Thứ tự hiển thị trên UI|Integer|

#### Entity: `PromotionTemplate`

|Field|Description|Enum / Note|
|---|---|---|
|`id`|ID template|UUID|
|`code`|Mã template|Unique|
|`name`|Tên mẫu CTKM|Required|
|`short_description`|Mô tả ngắn để hiển thị trên card mẫu|Optional|
|`description`|Mô tả chi tiết|Optional|
|`promotion_type_id`|Loại CTKM mà template sử dụng|FK → `PromotionType`|
|`template_scope`|Phạm vi template|`system`, `industry`, `tenant`|
|`industry_code`|Ngành áp dụng nếu là industry template|Optional|
|`tenant_id`|Tenant sở hữu nếu là tenant template|Optional / deferred|
|`benefit_preset`|Cấu hình quyền lợi gợi ý|JSON|
|`rule_preset`|Cấu hình điều kiện gợi ý|JSON|
|`scope_preset`|Cấu hình phạm vi gợi ý|JSON|
|`schedule_preset`|Cấu hình thời gian gợi ý|JSON|
|`use_case_tags`|Tag tình huống sử dụng|Optional|
|`setup_difficulty`|Độ khó thiết lập|`easy`, `medium`, `advanced`|
|`estimated_setup_minutes`|Thời gian thiết lập ước tính|Optional|
|`is_active`|Template có đang khả dụng không|Boolean|
|`display_order`|Thứ tự hiển thị|Integer|

#### Entity: `PromotionBenefit`

|Field|Description|Enum / Note|
|---|---|---|
|`id`|ID quyền lợi|UUID|
|`promotion_id`|CTKM sở hữu quyền lợi này|FK → `Promotion`|
|`benefit_type`|Loại quyền lợi|`percentage_discount`, `fixed_amount_discount`, `fixed_price`, `gift_item`, `free_quantity`, `bundle_price`|
|`name`|Tên quyền lợi|Optional|
|`description`|Mô tả quyền lợi|Optional|
|`discount_percent`|Phần trăm giảm|Dùng với `percentage_discount`|
|`discount_amount`|Số tiền giảm|Dùng với `fixed_amount_discount`|
|`fixed_price`|Giá cố định sau ưu đãi|Dùng với `fixed_price` hoặc `bundle_price`|
|`currency`|Đơn vị tiền tệ|VND|
|`max_discount_amount`|Mức giảm tối đa|Optional|
|`gift_product_id`|Sản phẩm tặng|Dùng với `gift_item`|
|`gift_variant_id`|SKU tặng|Optional|
|`gift_quantity`|Số lượng tặng|Optional|
|`gift_uom_id`|Đơn vị tính của quà tặng|Optional|
|`application_level`|Cấp áp dụng quyền lợi|`line_item`, `order`|
|`apply_mode`|Cách áp dụng|`auto`, `coupon_required`, `manual_select`|
|`max_applications_per_order`|Số lần tối đa áp dụng trên một đơn|Optional|
|`total_usage_limit`|Giới hạn tổng lượt dùng theo benefit nếu có|Optional|
|`rounding_mode`|Cách làm tròn|Theo policy hệ thống|
|`is_active`|Quyền lợi có còn hiệu lực trong cấu hình không|Boolean|

#### Entity: `PromotionRule`

|Field|Description|Enum / Note|
|---|---|---|
|`id`|ID điều kiện|UUID|
|`promotion_id`|CTKM sở hữu điều kiện này|FK → `Promotion`|
|`rule_type`|Loại điều kiện|`min_order_amount`, `min_item_quantity`, `min_item_amount`, `customer_group_required`, `first_purchase_only`, `coupon_code_required`, `payment_method_required`|
|`name`|Tên điều kiện|Optional|
|`description`|Mô tả điều kiện|Optional|
|`condition_level`|Cấp kiểm tra điều kiện|`order`, `line_item`, `customer`, `payment`|
|`operator`|Toán tử so sánh|`eq`, `neq`, `gt`, `gte`, `lt`, `lte`, `in`, `not_in`|
|`value_number`|Giá trị số|Optional|
|`value_text`|Giá trị text|Optional|
|`value_json`|Giá trị phức tạp|Optional|
|`currency`|Tiền tệ nếu điều kiện là giá trị tiền|Optional|
|`uom_id`|Đơn vị tính nếu điều kiện là số lượng|Optional|
|`group_key`|Nhóm điều kiện|Optional|
|`group_operator`|Cách kết hợp trong nhóm|`AND`, `OR`|
|`is_required`|Điều kiện có bắt buộc không|Boolean|
|`failure_message`|Message khi điều kiện không đạt|Optional|
|`is_active`|Điều kiện còn active trong cấu hình không|Boolean|

#### Entity: `PromotionScope`

|Field|Description|Enum / Note|
|---|---|---|
|`id`|ID phạm vi áp dụng|UUID|
|`promotion_id`|CTKM sở hữu phạm vi này|FK → `Promotion`|
|`scope_type`|Loại phạm vi|`product`, `product_variant`, `product_category`, `customer`, `customer_group`, `store`, `sales_channel`|
|`include_mode`|Cách áp dụng phạm vi|`include`, `exclude`|
|`match_mode`|Cách match các item trong scope|`any`, `all`|
|`is_all`|Áp dụng cho tất cả đối tượng trong loại scope|Boolean|
|`name`|Tên phạm vi|Optional|
|`description`|Mô tả phạm vi|Optional|
|`display_order`|Thứ tự hiển thị|Integer|
|`is_active`|Phạm vi còn active trong cấu hình không|Boolean|

#### Entity: `PromotionScopeItem`

|Field|Description|Enum / Note|
|---|---|---|
|`id`|ID item trong phạm vi|UUID|
|`promotion_scope_id`|Scope sở hữu item này|FK → `PromotionScope`|
|`target_type`|Loại đối tượng được tham chiếu|`product`, `product_variant`, `product_category`, `customer`, `customer_group`, `store`, `sales_channel`|
|`target_id`|ID đối tượng được tham chiếu|Required nếu target tồn tại trong hệ thống|
|`target_code`|Mã đối tượng snapshot|Optional|
|`target_name`|Tên đối tượng snapshot|Optional|
|`is_active`|Item còn active trong scope không|Boolean|

#### Entity: `PromotionCoupon`

|Field|Description|Enum / Note|
|---|---|---|
|`id`|ID coupon|UUID|
|`tenant_id`|Tenant sở hữu coupon|Required|
|`promotion_id`|CTKM sở hữu coupon|FK → `Promotion`|
|`coupon_code`|Mã coupon người dùng nhập|Required|
|`normalized_code`|Mã đã normalize để kiểm tra trùng|Unique trong tenant|
|`coupon_type`|Loại coupon|`single_code`, `generated_code`|
|`name`|Tên coupon|Optional|
|`description`|Mô tả coupon|Optional|
|`status`|Trạng thái coupon|`draft`, `active`, `inactive`, `expired`|
|`start_at`|Thời điểm bắt đầu hiệu lực riêng của coupon|Optional|
|`end_at`|Thời điểm kết thúc hiệu lực riêng của coupon|Optional|
|`case_sensitive`|Có phân biệt hoa/thường không|Boolean|
|`total_usage_limit`|Tổng lượt dùng tối đa|Optional|
|`per_customer_limit`|Lượt dùng tối đa mỗi khách|Optional|
|`per_order_limit`|Lượt dùng tối đa mỗi đơn|Optional|
|`allow_guest_usage`|Cho khách lẻ chưa định danh dùng mã|Boolean|
|`version`|Version coupon|Dùng chống stale update|

#### Entity: `PromotionValidationResult`

|Field|Description|Enum / Note|
|---|---|---|
|`id`|ID kết quả kiểm tra|UUID|
|`promotion_id`|CTKM được kiểm tra|FK → `Promotion`|
|`validation_context`|Ngữ cảnh kiểm tra|`manual_check`, `activate`, `resume`, `bulk_action`, `apply_to_order`|
|`result_status`|Kết quả tổng thể|`passed`, `warning`, `failed`, `stale`|
|`checked_at`|Thời điểm kiểm tra|Required|
|`checked_by`|Người thực hiện kiểm tra|Optional|
|`promotion_version`|Version CTKM tại thời điểm kiểm tra|Required|
|`promotion_revision_id`|Revision tương ứng nếu có|Optional|
|`is_latest`|Có phải kết quả mới nhất không|Boolean|
|`issue_count`|Tổng số issue|Integer|
|`error_count`|Số lỗi chặn|Integer|
|`warning_count`|Số cảnh báo|Integer|
|`summary_message`|Tóm tắt kết quả kiểm tra|Optional|
|`can_proceed`|Có thể tiếp tục action hay không|Boolean|
|`requires_recheck`|Có cần kiểm tra lại không|Boolean|

#### Entity: `PromotionValidationIssue`

|Field|Description|Enum / Note|
|---|---|---|
|`id`|ID issue|UUID|
|`validation_result_id`|Kết quả kiểm tra chứa issue này|FK → `PromotionValidationResult`|
|`issue_code`|Mã lỗi/cảnh báo|Ví dụ: `missing_scope`, `duplicate_coupon_code`, `promotion_expired`|
|`severity`|Mức độ nghiêm trọng|`info`, `warning`, `error`|
|`issue_group`|Nhóm issue|`configuration`, `schedule`, `scope`, `benefit`, `rule`, `coupon`, `conflict`, `reference`, `usage_limit`, `system`|
|`message`|Nội dung hiển thị cho người dùng|Required|
|`field_path`|Field liên quan nếu có|Optional|
|`related_entity_type`|Entity liên quan|Optional|
|`related_entity_id`|ID entity liên quan|Optional|
|`is_blocking`|Issue có chặn action không|Boolean|
|`metadata`|Thông tin bổ sung|JSON|

#### Entity: `PromotionConflict`

|Field|Description|Enum / Note|
|---|---|---|
|`id`|ID conflict|UUID|
|`promotion_id`|CTKM chính|FK → `Promotion`|
|`conflicting_promotion_id`|CTKM xung đột|FK → `Promotion`|
|`validation_result_id`|Kết quả kiểm tra phát hiện conflict|Optional|
|`conflict_type`|Loại xung đột|`same_scope_time_overlap`, `same_product_overlap`, `same_order_level_overlap`, `exclusive_type_overlap`, `stacking_policy_violation`, `coupon_code_duplicate`|
|`severity`|Mức độ nghiêm trọng|`warning`, `blocking`|
|`is_blocking`|Có chặn bật/bật lại không|Boolean|
|`detected_at`|Thời điểm phát hiện|Required|
|`source_promotion_version`|Version CTKM chính khi phát hiện|Optional|
|`conflicting_promotion_version`|Version CTKM xung đột khi phát hiện|Optional|
|`overlap_start_at`|Thời điểm bắt đầu overlap|Optional|
|`overlap_end_at`|Thời điểm kết thúc overlap|Optional|
|`overlap_scope_type`|Loại phạm vi bị overlap|Optional|
|`overlap_summary`|Tóm tắt xung đột|Optional|
|`resolution_hint`|Gợi ý xử lý|Optional|
|`conflict_status`|Trạng thái conflict|`open`, `resolved`, `stale`, `ignored`|

#### Entity: `PromotionRevision`

|Field|Description|Enum / Note|
|---|---|---|
|`id`|ID revision|UUID|
|`tenant_id`|Tenant sở hữu|Required|
|`promotion_id`|CTKM được snapshot|FK → `Promotion`|
|`revision_number`|Số revision|Thường tương ứng với version|
|`revision_reason`|Lý do tạo revision|`created`, `created_from_template`, `draft_updated`, `activated`, `resumed`, `duplicated`|
|`created_by`|Người tạo revision|Required|
|`created_at`|Thời điểm tạo revision|Required|
|`promotion_code`|Mã CTKM snapshot|Required|
|`promotion_name`|Tên CTKM snapshot|Required|
|`promotion_type_id`|Loại CTKM snapshot|Required|
|`lifecycle_status`|Trạng thái snapshot|Required|
|`schedule_snapshot`|Snapshot thời gian áp dụng|JSON|
|`scope_snapshot`|Snapshot phạm vi|JSON|
|`rule_snapshot`|Snapshot điều kiện|JSON|
|`benefit_snapshot`|Snapshot quyền lợi|JSON|
|`coupon_snapshot`|Snapshot coupon|JSON|
|`full_config_snapshot`|Snapshot đầy đủ nếu cần|JSON|
|`previous_revision_id`|Revision trước đó|Optional|
|`source_revision_id`|Revision nguồn nếu duplicate|Optional|
|`checksum`|Dấu vết kiểm tra thay đổi|Optional|

#### Entity: `PromotionActionLog`

|Field|Description|Enum / Note|
|---|---|---|
|`id`|ID log|UUID|
|`tenant_id`|Tenant sở hữu|Required|
|`promotion_id`|CTKM liên quan|Optional nếu bulk\-level|
|`action_type`|Loại thao tác|`create`, `create_from_template`, `update_draft`, `check`, `activate`, `pause`, `resume`, `end`, `cancel`, `delete_draft`, `archive`, `duplicate`, `bulk_action`|
|`action_result`|Kết quả thao tác|`success`, `failed`, `blocked`, `partial_success`, `no_op`|
|`performed_at`|Thời điểm thao tác|Required|
|`performed_by`|Người thao tác|Required|
|`from_status`|Trạng thái trước thao tác|Optional|
|`to_status`|Trạng thái sau thao tác|Optional|
|`promotion_version_before`|Version trước thao tác|Optional|
|`promotion_version_after`|Version sau thao tác|Optional|
|`is_state_changed`|Có đổi trạng thái không|Boolean|
|`reason_code`|Mã lý do nếu có|Optional|
|`reason_text`|Lý do người dùng nhập|Optional|
|`failure_code`|Mã lỗi nếu thất bại/bị chặn|Optional|
|`failure_message`|Message lỗi|Optional|
|`validation_result_id`|Kết quả validation liên quan|Optional|
|`bulk_operation_id`|Bulk operation liên quan|Optional|
|`source_promotion_id`|CTKM nguồn nếu duplicate|Optional|
|`before_snapshot`|Snapshot trước thao tác|Optional|
|`after_snapshot`|Snapshot sau thao tác|Optional|

#### Entity: `PromotionBulkOperation`

|Field|Description|Enum / Note|
|---|---|---|
|`id`|ID bulk operation|UUID|
|`tenant_id`|Tenant sở hữu|Required|
|`operation_code`|Mã bulk operation|Unique|
|`action_type`|Loại bulk action|`bulk_check`, `bulk_pause`, `bulk_end`, `bulk_cancel`, `bulk_delete_draft`|
|`operation_status`|Trạng thái xử lý|`pending`, `processing`, `completed`, `partial_success`, `failed`, `cancelled`|
|`requested_by`|Người yêu cầu thao tác|Required|
|`requested_at`|Thời điểm yêu cầu|Required|
|`started_at`|Thời điểm bắt đầu xử lý|Optional|
|`completed_at`|Thời điểm hoàn tất|Optional|
|`selected_count`|Số CTKM được chọn|Integer|
|`eligible_count`|Số CTKM đủ điều kiện|Integer|
|`ineligible_count`|Số CTKM không đủ điều kiện|Integer|
|`success_count`|Số CTKM xử lý thành công|Integer|
|`failed_count`|Số CTKM xử lý thất bại|Integer|
|`blocked_count`|Số CTKM bị chặn|Integer|
|`reason_text`|Lý do thao tác nếu có|Optional|
|`summary_message`|Tóm tắt kết quả|Optional|
|`request_snapshot`|Snapshot request|JSON|
|`result_snapshot`|Snapshot kết quả|JSON|

#### Entity: `PromotionBulkOperationItem`

|Field|Description|Enum / Note|
|---|---|---|
|`id`|ID item|UUID|
|`bulk_operation_id`|Bulk operation chứa item|FK → `PromotionBulkOperation`|
|`promotion_id`|CTKM được xử lý|FK → `Promotion`|
|`promotion_code`|Mã CTKM snapshot|Required|
|`promotion_name`|Tên CTKM snapshot|Required|
|`promotion_version_before`|Version trước xử lý|Optional|
|`promotion_version_after`|Version sau xử lý|Optional|
|`from_status`|Trạng thái trước xử lý|Optional|
|`to_status`|Trạng thái sau xử lý|Optional|
|`item_status`|Trạng thái xử lý item|`pending`, `success`, `failed`, `blocked`, `skipped`|
|`failure_code`|Mã lỗi nếu thất bại/bị chặn|Optional|
|`failure_message`|Message lỗi|Optional|
|`validation_result_id`|Kết quả validation nếu có|Optional|
|`action_log_id`|Log thao tác tương ứng|Optional|
|`processed_at`|Thời điểm xử lý|Optional|

#### Entity: `AppliedPromotion`

|Field|Description|Enum / Note|
|---|---|---|
|`id`|ID CTKM đã áp dụng|UUID|
|`tenant_id`|Tenant sở hữu|Required|
|`sales_order_id`|Đơn hàng được áp dụng CTKM|FK → `SalesOrder`|
|`sales_order_line_id`|Dòng hàng được áp dụng CTKM|Optional|
|`promotion_id`|CTKM gốc|FK → `Promotion`|
|`promotion_revision_id`|Revision CTKM tại thời điểm áp dụng|Optional|
|`promotion_benefit_id`|Benefit đã áp dụng|Optional|
|`promotion_coupon_id`|Coupon đã dùng|Optional|
|`applied_at`|Thời điểm áp dụng|Required|
|`promotion_code`|Mã CTKM snapshot|Required|
|`promotion_name`|Tên CTKM snapshot|Required|
|`promotion_type_code`|Loại CTKM snapshot|Required|
|`promotion_version`|Version CTKM khi áp dụng|Required|
|`benefit_type`|Loại quyền lợi đã áp dụng|Required|
|`application_level`|Cấp áp dụng|`line_item`, `order`|
|`discount_amount`|Số tiền giảm thực tế|Optional|
|`discount_percent`|Phần trăm giảm snapshot|Optional|
|`original_amount`|Giá trị gốc trước giảm|Optional|
|`discountable_amount`|Giá trị được phép giảm|Optional|
|`final_amount`|Giá trị sau giảm|Optional|
|`gift_product_id`|Sản phẩm tặng nếu có|Optional|
|`gift_quantity`|Số lượng tặng nếu có|Optional|
|`coupon_code`|Mã coupon đã dùng|Optional|
|`rule_summary`|Tóm tắt điều kiện đạt|Optional|
|`scope_summary`|Tóm tắt phạm vi áp dụng|Optional|
|`benefit_summary`|Tóm tắt quyền lợi|Optional|
|`pricing_snapshot`|Snapshot tính giá|JSON|
|`status`|Trạng thái applied promotion|`applied`, `reversed`, `voided`|
|`reversed_at`|Thời điểm reverse|Optional|
|`reverse_reason`|Lý do reverse|Optional|

#### Entity: `PromotionUsage`

|Field|Description|Enum / Note|
|---|---|---|
|`id`|ID usage counter|UUID|
|`tenant_id`|Tenant sở hữu|Required|
|`promotion_id`|CTKM được đếm usage|FK → `Promotion`|
|`usage_scope`|Phạm vi đếm usage|`promotion_global`, `customer_promotion`, `coupon_code`, `customer_coupon`|
|`customer_id`|Khách hàng liên quan|Optional|
|`coupon_code`|Coupon liên quan|Optional|
|`sales_channel_id`|Kênh bán liên quan|Optional|
|`store_id`|Chi nhánh liên quan|Optional|
|`used_count`|Số lượt đã dùng|Integer|
|`reserved_count`|Số lượt đang giữ chỗ nếu có|Integer|
|`reversed_count`|Số lượt đã reverse|Integer|
|`voided_count`|Số lượt đã void|Integer|
|`usage_limit`|Giới hạn lượt dùng|Optional|
|`limit_source`|Nguồn giới hạn|`promotion`, `benefit`, `coupon`|
|`first_used_at`|Lần dùng đầu tiên|Optional|
|`last_used_at`|Lần dùng gần nhất|Optional|
|`last_sales_order_promotion_id`|AppliedPromotion gần nhất|Optional|
|`metadata`|Thông tin bổ sung|JSON|

### 5\.2\.4 Status Transition \& Business Command

#### 5\.2\.4\.1 Persisted lifecycle status

|Status|Ý nghĩa|
|---|---|
|`draft`|CTKM đang là bản nháp, chưa được đưa vào vận hành\.|
|`active`|CTKM đã được bật; tùy thời gian hiệu lực mà UI có thể hiển thị Sắp chạy hoặc Đang chạy\.|
|`paused`|CTKM đang tạm dừng, không áp dụng cho đơn hàng mới\.|
|`ended`|CTKM đã kết thúc, không được bật lại trực tiếp\.|
|`cancelled`|CTKM đã bị hủy, không được đưa vào vận hành hoặc không tiếp tục vận hành\.|
|`deleted_draft`|Bản nháp đã bị xóa mềm\.|
|`archived`|CTKM cũ được lưu trữ/ẩn khỏi danh sách chính\.|

#### 5\.2\.4\.2 Display status mapping

|Display status|Rule|
|---|---|
|Nháp|`lifecycle_status = draft` và chưa có validation pass mới nhất\.|
|Sẵn sàng|`lifecycle_status = draft` và latest validation result passed\.|
|Sắp chạy|`lifecycle_status = active` và `start_at > now`\.|
|Đang chạy|`lifecycle_status = active` và `start_at <= now <= end_at`, hoặc always\-on\.|
|Tạm dừng|`lifecycle_status = paused`\.|
|Đã kết thúc|`lifecycle_status = ended`, hoặc CTKM active nhưng đã hết hiệu lực theo thời gian\.|
|Đã hủy|`lifecycle_status = cancelled`\.|
|Đã xóa nháp|`lifecycle_status = deleted_draft`\.|
|Đã lưu trữ|`lifecycle_status = archived`\.|

#### 5\.2\.4\.3 Status transition

|Command|From status|To status|Rule chính|
|---|---|---|---|
|`CreatePromotionFromType`|—|`draft`|Tạo CTKM nháp từ loại CTKM\.|
|`CreatePromotionFromTemplate`|—|`draft`|Tạo CTKM nháp từ mẫu CTKM\.|
|`UpdatePromotionDraft`|`draft`|`draft`|Chỉ bản nháp mới được sửa cấu hình đầy đủ\.|
|`CheckPromotion`|`draft`, `active`, `paused`|Không đổi|Kiểm tra tính hợp lệ, không đổi trạng thái\.|
|`ActivatePromotion`|`draft`|`active`|Cần validation pass và user có quyền\.|
|`PausePromotion`|`active`|`paused`|CTKM active mới được tạm dừng\.|
|`ResumePromotion`|`paused`|`active`|Cần validation pass, chưa hết hạn, không có blocking issue\.|
|`EndPromotion`|`active`, `paused`|`ended`|Kết thúc CTKM đang chạy hoặc đang tạm dừng\.|
|`CancelPromotion`|`draft`, `active` chưa phát sinh áp dụng, hoặc active future|`cancelled`|Hủy CTKM nếu đủ điều kiện\.|
|`DeleteDraftPromotion`|`draft`|`deleted_draft`|Xóa mềm bản nháp\.|
|`ArchivePromotion`|`ended`, `cancelled`|`archived`|Lưu trữ CTKM cũ\.|
|`DuplicatePromotion`|`draft`, `active`, `paused`, `ended`, `cancelled`, `archived`|New `draft`|Tạo CTKM mới từ CTKM nguồn, không đổi CTKM nguồn\.|

#### 5\.2\.4\.4 Business command catalogue

##### Query / Read commands

|Command|Ý nghĩa|Main entity|
|---|---|---|
|`ListPromotions`|Xem danh sách CTKM|`Promotion`|
|`SearchPromotions`|Tìm CTKM theo tên hoặc mã|`Promotion`|
|`FilterPromotions`|Lọc CTKM theo trạng thái, loại, thời gian, cảnh báo|`Promotion`|
|`ViewPromotionDetail`|Xem chi tiết một CTKM|`Promotion`|
|`ViewPromotionActionEligibility`|Xem action nào khả dụng theo trạng thái và quyền|`Promotion`|
|`ListPromotionTypes`|Xem danh sách loại CTKM có thể tạo|`PromotionType`|
|`ListPromotionTemplates`|Xem danh sách mẫu CTKM có thể dùng|`PromotionTemplate`|
|`ViewPromotionValidationResult`|Xem kết quả kiểm tra CTKM|`PromotionValidationResult`|
|`ViewBulkOperationResult`|Xem kết quả xử lý hàng loạt|`PromotionBulkOperation`|

##### Setup / Draft commands

|Command|Ý nghĩa|Main entity|
|---|---|---|
|`CreatePromotionFromType`|Tạo CTKM nháp từ loại CTKM|`Promotion`, `PromotionType`|
|`CreatePromotionFromTemplate`|Tạo CTKM nháp từ mẫu CTKM|`Promotion`, `PromotionTemplate`|
|`UpdatePromotionDraft`|Cập nhật cấu hình bản nháp|`Promotion`, `PromotionBenefit`, `PromotionRule`, `PromotionScope`, `PromotionCoupon`|
|`DeleteDraftPromotion`|Xóa mềm bản nháp CTKM|`Promotion`|
|`DuplicatePromotion`|Nhân bản CTKM thành bản nháp mới|`Promotion`, `PromotionRevision`|

##### Validation / Lifecycle commands

|Command|Ý nghĩa|Main entity|
|---|---|---|
|`CheckPromotion`|Kiểm tra cấu hình, thời gian, phạm vi, coupon, conflict, usage rule|`PromotionValidationResult`|
|`ActivatePromotion`|Bật CTKM lần đầu|`Promotion`, `PromotionActionLog`|
|`PausePromotion`|Tạm dừng CTKM|`Promotion`, `PromotionActionLog`|
|`ResumePromotion`|Bật lại CTKM đang tạm dừng|`Promotion`, `PromotionValidationResult`, `PromotionActionLog`|
|`EndPromotion`|Kết thúc CTKM|`Promotion`, `PromotionActionLog`|
|`CancelPromotion`|Hủy CTKM|`Promotion`, `PromotionActionLog`|
|`ArchivePromotion`|Lưu trữ CTKM đã kết thúc hoặc đã hủy|`Promotion`, `PromotionActionLog`|

##### Bulk commands

|Command|Ý nghĩa|Main entity|
|---|---|---|
|`PreviewBulkPromotionAction`|Kiểm tra trước tập CTKM nào hợp lệ/không hợp lệ cho bulk action|`PromotionBulkOperation`|
|`BulkCheckPromotions`|Kiểm tra nhiều CTKM|`PromotionBulkOperation`, `PromotionValidationResult`|
|`BulkPausePromotions`|Tạm dừng nhiều CTKM|`PromotionBulkOperation`, `PromotionBulkOperationItem`|
|`BulkEndPromotions`|Kết thúc nhiều CTKM|`PromotionBulkOperation`, `PromotionBulkOperationItem`|
|`BulkCancelPromotions`|Hủy nhiều CTKM nếu đủ điều kiện|`PromotionBulkOperation`, `PromotionBulkOperationItem`|
|`BulkDeleteDraftPromotions`|Xóa nhiều bản nháp|`PromotionBulkOperation`, `PromotionBulkOperationItem`|
|`ViewBulkOperationResult`|Xem kết quả xử lý hàng loạt|`PromotionBulkOperation`, `PromotionBulkOperationItem`|

##### Runtime / Sales commands

|Command|Ý nghĩa|Main entity|
|---|---|---|
|`PreviewPromotionCalculation`|Tính thử CTKM trên cart/order, không tăng usage|`PromotionCalculation`|
|`ValidateCouponCode`|Kiểm tra mã coupon/voucher khi bán hàng|`PromotionCoupon`|
|`ApplyPromotionToOrder`|Áp dụng CTKM vào đơn hàng/dòng hàng|`AppliedPromotion`|
|`FinalizeOrderWithPromotion`|Chốt đơn và ghi nhận AppliedPromotion, PromotionUsage|`AppliedPromotion`, `PromotionUsage`|
|`ReverseAppliedPromotion`|Reverse CTKM đã áp dụng khi đơn bị hủy/void toàn bộ|`AppliedPromotion`, `PromotionUsage`|
|`UpdatePromotionUsage`|Cập nhật usage counter sau finalize hoặc reverse|`PromotionUsage`|

#### 5\.2\.4\.5 Command rules

|**Rule**|**Description**|
|---|---|
|Permission first|Mọi command nhạy cảm phải kiểm tra quyền trước khi kiểm tra trạng thái\.|
|State check second|Sau permission, hệ thống kiểm tra trạng thái hiện tại của CTKM\.|
|Version check before mutate|Command làm thay đổi dữ liệu phải kiểm tra `expected_version` để tránh stale update\.|
|Validation required for activate/resume|Bật và bật lại CTKM bắt buộc có validation result còn hiệu lực\.|
|Action log for state change|Mọi command làm đổi trạng thái phải ghi `PromotionActionLog`\.|
|Revision for config milestone|Tạo, sửa nháp, bật, bật lại và nhân bản nên tạo `PromotionRevision`\.|
|No direct resume after ended/cancelled|CTKM đã kết thúc hoặc đã hủy không được bật lại trực tiếp; nếu cần dùng lại thì nhân bản\.|
|Preview does not increase usage|Tính thử CTKM không làm tăng `PromotionUsage`\.|
|Finalize must recalculate|Khi chốt đơn, hệ thống phải tính lại CTKM trước khi ghi `AppliedPromotion`\.|
|Full cancel reverses usage|Hủy/void toàn bộ đơn phải reverse `AppliedPromotion` và `PromotionUsage`\.|
|Partial return deferred|Phase 1 chưa tự động reverse usage phức tạp cho partial return/refund\.|

## 5\.3 User stories — Common lifecycle

|**ID**|**As user**|**I want to do**|**So that**|
|---|---|---|---|
|**US\-01**<br>|Quản lý cửa hàng / Quản trị viên|Xem, tìm kiếm, lọc và kiểm tra danh sách CTKM|Tôi có thể kiểm soát toàn bộ CTKM đang nháp, sắp chạy, đang chạy, tạm dừng hoặc đã kết thúc|
|**US\-02**|Quản lý cửa hàng / Quản trị viên|Chọn loại hoặc mẫu CTKM khi tạo mới|Tôi có thể bắt đầu tạo CTKM đúng với mục đích kinh doanh mong muốn|
|**US\-03**|Quản lý cửa hàng / Quản trị viên|Xem chi tiết một CTKM|Tôi có thể kiểm tra cấu hình, trạng thái, cảnh báo và lịch sử của CTKM đó|
|**US\-04**|Quản trị viên / Chủ doanh nghiệp|Kiểm tra và bật CTKM<br>|Tôi có thể đảm bảo CTKM hợp lệ trước khi áp dụng vào bán hàng|
|**US\-05**|Quản trị viên / Chủ doanh nghiệp|Tạm dừng hoặc bật lại CTKM|Tôi có thể kiểm soát CTKM khi cần ngừng tạm thời hoặc cho chạy lại|
|**US\-06**|Quản trị viên / Chủ doanh nghiệp|Kết thúc sớm hoặc hủy CTKM|Tôi có thể dừng CTKM không còn phù hợp và tránh tiếp tục áp dụng sai|
|**US\-07**|Quản lý cửa hàng / Quản trị viên|Nhân bản một CTKM đã có|Tôi có thể tạo nhanh CTKM mới dựa trên chương trình cũ và chỉ sửa các thông tin cần thay đổi|
|**US\-08**|Quản trị viên|Thao tác hàng loạt với nhiều CTKM|Tôi có thể xử lý nhanh nhiều CTKM khi cần tạm dừng, kết thúc hoặc xóa nháp|

### 5\.3\.1 US\-01 — Quản lý danh sách CTKM

#### 5\.3\.1\.1 Business context

Danh sách CTKM không chỉ là nơi hiển thị các chương trình đã tạo\. Đây là màn hình kiểm soát vòng đời CTKM, giúp người dùng biết chương trình nào đang chạy, chương trình nào có lỗi, chương trình nào sắp hết hạn và chương trình nào cần thao tác tiếp\.

Nếu danh sách CTKM không rõ trạng thái hoặc cảnh báo, người dùng có thể bỏ sót CTKM sai, để CTKM hết hạn vẫn được hiểu nhầm là đang chạy, hoặc không phát hiện xung đột trước khi CTKM ảnh hưởng đến bán hàng\.

#### 5\.3\.1\.2 Functional requirements

|**ID**|**Functional Requirement**|**Acceptance Criteria**|
|---|---|---|
|**FR\-01**|Hiển thị danh sách CTKM|Hệ thống hiển thị danh sách CTKM gồm tên, loại CTKM, thời gian hiệu lực, phạm vi áp dụng, trạng thái và cảnh báo nếu có|
|**FR\-02**|Tìm kiếm CTKM|Người dùng có thể tìm CTKM theo tên hoặc mã CTKM|
|**FR\-03**|Lọc CTKM|Người dùng có thể lọc CTKM theo trạng thái, loại CTKM, thời gian hiệu lực và tình trạng cảnh báo|
|**FR\-04**|Hiển thị trạng thái CTKM|Mỗi CTKM phải hiển thị một trạng thái vòng đời rõ ràng|
|**FR\-05**|Hiển thị cảnh báo CTKM|Hệ thống hiển thị cảnh báo nếu CTKM thiếu thiết lập, có xung đột, sắp hết hạn hoặc không còn đối tượng áp dụng hợp lệ|
|**FR\-06**|Thao tác nhanh trên từng CTKM|Người dùng có thể mở menu thao tác của từng CTKM; các action hiển thị theo trạng thái và quyền|
|**FR\-07**|Điều hướng từ danh sách|Người dùng có thể mở chi tiết CTKM hoặc bắt đầu tạo CTKM mới từ màn hình danh sách|

#### 5\.3\.1\.3 Business rules

|**ID**|**Business Rule**|
|---|---|
|**BR\-01**|Mỗi CTKM phải có đúng một trạng thái vòng đời tại một thời điểm|
|**BR\-02**|CTKM có cảnh báo nghiêm trọng cần được ưu tiên hiển thị hoặc làm nổi bật trong danh sách|
|**BR\-03**|Action trên CTKM phụ thuộc vào trạng thái hiện tại của CTKM|
|**BR\-04**|Action nhạy cảm như bật, tạm dừng, kết thúc sớm, hủy hoặc xóa nháp cần có bước xác nhận|
|**BR\-05**|Người dùng chỉ nhìn thấy hoặc thực hiện action trong phạm vi quyền được cấp|
|**BR\-06**|CTKM đã kết thúc hoặc đã hủy không được bật lại trực tiếp|
|**BR\-07**|Các action làm thay đổi trạng thái CTKM phải được ghi nhận vào lịch sử thay đổi|

#### 5\.3\.1\.4 UI Contract

##### 5\.3\.1\.4\.1 Mục tiêu màn hình

Màn hình danh sách CTKM giúp người dùng kiểm soát toàn bộ CTKM theo trạng thái, cảnh báo và hành động cần xử lý\.

##### 5\.3\.1\.4\.2 Cấu trúc màn hình

|**Khu vực**|**Nội dung**|
|---|---|
|**Header**|Tiêu đề màn hình và CTA: ← để trở về màn hình trước đó|
|**Search**|Ô tìm kiếm theo tên hoặc mã CTKM|
|**Quick filters**|Tất cả, Đang chạy, Sắp chạy, Nháp, Có cảnh báo, Đã kết thúc|
|**Filter nâng cao**|Trạng thái, loại CTKM, thời gian hiệu lực, cảnh báo|
|**Danh sách CTKM**|Các CTKM được hiển thị dưới dạng list/card|
|**Item action menu**|Menu thao tác theo từng CTKM|

##### 5\.3\.1\.4\.3 Thông tin trên mỗi CTKM

|**Thành phần**|**Mô tả**|
|---|---|
|**Tên CTKM**|Tên chương trình khuyến mại|
|**Loại CTKM**|Giảm giá sản phẩm, giảm giá đơn hàng, mua X tặng Y, combo\.\.\.|
|**Thời gian hiệu lực**|Ngày bắt đầu và ngày kết thúc|
|**Phạm vi áp dụng**|Sản phẩm, nhóm sản phẩm, khách hàng, chi nhánh hoặc kênh bán|
|**Trạng thái**|Nháp, sẵn sàng, sắp chạy, đang chạy, tạm dừng, đã kết thúc, đã hủy|
|**Cảnh báo**|Thiếu thiết lập, có xung đột, sắp hết hạn, không còn đối tượng hợp lệ|
|**Action**|Xem chi tiết, tiếp tục thiết lập, bật, tạm dừng, kết thúc, hủy, nhân bản|

##### 5\.3\.1\.4\.4 Trạng thái CTKM

|**Trạng thái**|**Ý nghĩa**|
|---|---|
|**Nháp**|CTKM đang được tạo, chưa sẵn sàng áp dụng|
|**Sẵn sàng**|CTKM đã đủ thiết lập và có thể bật|
|**Sắp chạy**|CTKM đã bật nhưng chưa đến thời gian bắt đầu|
|**Đang chạy**|CTKM đang có hiệu lực và có thể được áp dụng khi bán hàng|
|**Tạm dừng**|CTKM tạm thời không được áp dụng cho đơn hàng mới|
|**Đã kết thúc**|CTKM đã hết thời gian hiệu lực hoặc được kết thúc sớm|
|**Đã hủy**|CTKM bị hủy và không được bật lại trực tiếp|

##### 5\.3\.1\.4\.5 Action theo trạng thái

|**Trạng thái**|**Action khả dụng**|
|---|---|
|**Nháp**|Tiếp tục thiết lập, Xóa nháp|
|**Sẵn sàng**|Xem chi tiết, Chỉnh sửa, Bật CTKM|
|**Sắp chạy**|Xem chi tiết, Tạm dừng|
|**Đang chạy**|Xem chi tiết, Tạm dừng, Kết thúc sớm|
|**Tạm dừng**|Xem chi tiết, Bật lại, Kết thúc|
|**Đã kết thúc**|Xem chi tiết, Nhân bản|
|**Đã hủy**|Xem chi tiết, Nhân bản|

##### 5\.3\.1\.4\.6 Empty / Loading / Error states

|**State**|**Nội dung**|
|---|---|
|**Empty**|Chưa có CTKM nào\. CTA: Tạo CTKM|
|**No result**|Không tìm thấy CTKM phù hợp với từ khóa hoặc bộ lọc|
|**Loading**|Hiển thị trạng thái đang tải danh sách|
|**Error**|Không tải được danh sách CTKM\. CTA: Thử lại|
|**No permission**|Người dùng không có quyền xem hoặc thao tác với CTKM|

#### 5\.3\.1\.5 Designs

|**Design ID**|**Màn hình / State**|**Coverage**|
|---|---|---|
|**D\-01**|Danh sách CTKM mặc định|FR\-01, FR\-04|
|**D\-02**|Danh sách CTKM có cảnh báo|FR\-01, FR\-05|
|**D\-03**|Tìm kiếm CTKM|FR\-02|
|**D\-04**|Bộ lọc CTKM|FR\-03|
|**D\-05**|Menu action của một CTKM|FR\-06|
|**D\-06**|Confirmation modal cho action nhạy cảm|BR\-04, FR\-06|
|**D\-07**|Empty / No result / Loading / Error|FR\-07|

![image\.png](Images_attachments/image%205.png)

#### 5\.3\.1\.6 Scenarios

|ID|Scenario|Given|When|Then|
|---|---|---|---|---|
|**SC\-01**|Xem danh sách CTKM|Người dùng có quyền xem CTKM|Người dùng mở màn hình danh sách CTKM|Hệ thống hiển thị danh sách CTKM cùng trạng thái và cảnh báo tương ứng|
|**SC\-02**|Tìm kiếm CTKM|Danh sách có nhiều CTKM|Người dùng nhập tên hoặc mã CTKM|Hệ thống hiển thị các CTKM phù hợp|
|**SC\-03**|Lọc CTKM đang chạy|Danh sách có nhiều trạng thái CTKM|Người dùng chọn filter Đang chạy|Hệ thống chỉ hiển thị các CTKM đang chạy|
|**SC\-04**|Xem cảnh báo CTKM|Có CTKM thiếu thiết lập hoặc có xung đột|Người dùng xem danh sách|Hệ thống hiển thị cảnh báo trên CTKM tương ứng|
|**SC\-05**|Mở chi tiết CTKM|Người dùng thấy một CTKM trong danh sách|Người dùng chọn CTKM đó|Hệ thống điều hướng sang màn hình chi tiết CTKM|
|**SC\-06**|Thực hiện action theo trạng thái|CTKM có trạng thái hợp lệ cho action|Người dùng mở menu action|Hệ thống chỉ hiển thị các action được phép|
|**SC\-07**|Gặp lỗi tải danh sách|Hệ thống không tải được dữ liệu|Người dùng mở màn hình danh sách|Hệ thống hiển thị error state và cho phép thử lại|

#### 5\.3\.1\.7 Edge cases

|ID|Edge Case|Hướng xử lý đề xuất|
|---|---|---|
|**EC\-01**|CTKM đổi trạng thái trong lúc người dùng đang xem danh sách|Hệ thống cần cập nhật lại trạng thái khi người dùng thực hiện action|
|**EC\-02**|Người dùng không còn quyền sau khi đã mở màn hình|Hệ thống chặn action và hiển thị thông báo không đủ quyền|
|**EC\-03**|CTKM đã hết hạn nhưng danh sách chưa refresh|Hệ thống cần kiểm tra lại trạng thái trước khi cho thao tác|
|**EC\-04**|CTKM có nhiều cảnh báo cùng lúc|Hệ thống hiển thị cảnh báo nghiêm trọng nhất và cho phép xem chi tiết|
|**EC\-05**|Danh sách quá nhiều CTKM|Hệ thống cần phân trang hoặc lazy load|

#### 5\.3\.1\.8 Open questions

|ID|Question|Gợi ý|
|---|---|---|
|**OQ\-01**|V1 có cần hiển thị số liệu hiệu quả CTKM trên danh sách không?|Có thể để phase sau|
|**OQ\-02**|Có cho bật CTKM trực tiếp từ danh sách không?|Có, nhưng cần confirmation|
|**OQ\-03**|Có cho bulk activate trong v1 không?|Đề xuất không làm v1|

### 5\.3\.2 US\-02 — Chọn loại hoặc mẫu CTKM

#### 5\.3\.2\.1 Business context

Sau khi người dùng bấm nút `+` từ danh sách CTKM, hệ thống cần đưa người dùng vào một bước trung gian để chọn **loại CTKM** hoặc **mẫu CTKM** phù hợp với mục tiêu kinh doanh\.

US\-02 không xử lý việc cấu hình chi tiết CTKM\. Nhiệm vụ của US\-02 là giúp người dùng chọn đúng điểm bắt đầu trước khi đi vào flow tạo CTKM cụ thể như giảm giá sản phẩm, giảm giá đơn hàng, mua X tặng Y, combo, giảm theo số lượng, theo nhóm khách hàng, theo chi nhánh/kênh bán hoặc voucher\.

Nếu bỏ qua bước này, người dùng có thể phải tự hiểu logic nghiệp vụ quá sớm, dễ chọn sai loại CTKM hoặc tạo CTKM không đúng mục đích\. Vì vậy, màn hình chọn loại/mẫu CTKM cần trình bày rõ ràng theo ngôn ngữ nghiệp vụ, không chỉ theo cấu trúc kỹ thuật\.

#### 5\.3\.2\.2 Functional requirements

|ID|Functional Requirement|Acceptance Criteria|
|---|---|---|
|**FR\-01**|Hiển thị danh sách loại CTKM|Hệ thống hiển thị các loại CTKM khả dụng trong phạm vi v1|
|**FR\-02**|Hiển thị mô tả ngắn cho từng loại CTKM|Mỗi loại CTKM có tên, mô tả ngắn và ví dụ nghiệp vụ để người dùng hiểu khi nào nên dùng|
|**FR\-03**|Cho phép chọn một loại CTKM|Người dùng có thể chọn một loại CTKM để bắt đầu tạo chương trình mới|
|**FR\-04**|Hiển thị danh sách mẫu CTKM nếu có|Hệ thống có thể hiển thị các mẫu CTKM thường dùng để người dùng tạo nhanh|
|**FR\-05**|Cho phép tạo CTKM từ mẫu|Người dùng có thể chọn một mẫu CTKM và bắt đầu tạo CTKM mới dựa trên cấu trúc mẫu đó|
|**FR\-06**|Phân biệt rõ loại CTKM và mẫu CTKM|Giao diện phải giúp người dùng hiểu loại CTKM là cơ chế ưu đãi, còn mẫu CTKM là cấu hình gợi ý có sẵn|
|**FR\-07**|Điều hướng tới flow tạo CTKM tương ứng|Sau khi chọn loại hoặc mẫu, hệ thống điều hướng người dùng sang màn hình tạo CTKM phù hợp|
|**FR\-08**|Xử lý trạng thái không có mẫu CTKM|Nếu chưa có mẫu CTKM, hệ thống vẫn cho phép người dùng chọn loại CTKM để tạo mới|
|**FR\-09**|Kiểm tra quyền tạo CTKM|Nếu người dùng không có quyền tạo CTKM, hệ thống không cho bắt đầu flow tạo mới và hiển thị thông báo phù hợp|

#### 5\.3\.2\.3 Business rules

|ID|Business Rule|
|---|---|
|**BR\-01**|Người dùng chỉ được tạo CTKM nếu có quyền tạo CTKM|
|**BR\-02**|Tại một thời điểm, người dùng chỉ chọn một loại CTKM hoặc một mẫu CTKM để bắt đầu tạo mới|
|**BR\-03**|Chọn loại CTKM chỉ xác định flow tạo mới, chưa tạo bản ghi CTKM chính thức nếu người dùng chưa lưu nháp|
|**BR\-04**|Chọn mẫu CTKM sẽ tạo CTKM mới dựa trên cấu trúc mẫu, không chỉnh sửa trực tiếp mẫu gốc|
|**BR\-05**|Mẫu CTKM không được chứa dữ liệu đã hết hiệu lực hoặc không còn hợp lệ mà không có cảnh báo|
|**BR\-06**|Các loại CTKM chưa hỗ trợ trong v1 không được hiển thị như lựa chọn khả dụng|
|**BR\-07**|Nếu loại CTKM yêu cầu module hoặc quyền chưa được bật, hệ thống phải disable lựa chọn và giải thích lý do|
|**BR\-08**|Việc chọn loại/mẫu CTKM không làm thay đổi danh sách CTKM cho đến khi người dùng lưu nháp hoặc lưu chương trình|

#### 5\.3\.2\.4 UI Contract

##### 5\.3\.2\.4\.1 Mục tiêu màn hình

Màn hình chọn loại hoặc mẫu CTKM giúp người dùng chọn đúng hướng tạo CTKM trước khi đi vào cấu hình chi tiết\.

##### 5\.3\.2\.4\.2 Entry point

|Entry point|Hành vi|
|---|---|
|**Nút ****`+`**** tại danh sách CTKM**|Mở màn hình chọn loại hoặc mẫu CTKM|
|**Empty state CTA ****`+`**|Mở màn hình chọn loại hoặc mẫu CTKM|
|**No result state CTA ****`+`**|Mở màn hình chọn loại hoặc mẫu CTKM|
|**Error state CTA ****`+`**|Chỉ khả dụng nếu lỗi tải danh sách không ảnh hưởng tới quyền tạo mới|

##### 5\.3\.2\.4\.3 Cấu trúc màn hình

|Khu vực|Nội dung|
|---|---|
|**Top bar**|Back icon \(←\), title `Tạo CTKM`|
|**Intro text**|Một câu hướng dẫn ngắn: `Chọn cách bắt đầu chương trình khuyến mại`|
|**Section: Loại CTKM**|Danh sách các loại CTKM khả dụng|
|**Section: Mẫu thường dùng**|Danh sách mẫu CTKM nếu hệ thống có dữ liệu mẫu|
|**Disabled items**|Các loại/mẫu chưa khả dụng hiển thị disabled kèm lý do|
|**No permission state**|Thông báo người dùng không có quyền tạo CTKM|

##### 5\.3\.2\.4\.4 Loại CTKM hiển thị trong v1

|Loại CTKM|Mô tả ngắn|Ví dụ hiển thị|
|---|---|---|
|**Giảm giá sản phẩm**|Giảm giá một hoặc nhiều sản phẩm cụ thể|`Giảm 10% nhóm vaccine`|
|**Giảm giá đơn hàng**|Giảm giá khi đơn hàng đạt điều kiện|`Đơn từ 2.000.000đ giảm 100.000đ`|
|**Mua X tặng Y**|Mua sản phẩm/nhóm sản phẩm này để được tặng sản phẩm/nhóm sản phẩm khác|`Mua 10 tặng 1`|
|**Combo**|Bán một bộ sản phẩm theo giá hoặc ưu đãi riêng|`Combo sát trùng mùa mưa`|
|**Giảm theo số lượng**|Ưu đãi theo bậc số lượng mua|`Mua càng nhiều giá càng tốt`|
|**Theo nhóm khách hàng**|Áp dụng ưu đãi cho một nhóm khách cụ thể|`Ưu đãi khách VIP`|
|**Theo chi nhánh/kênh bán**|Áp dụng CTKM theo điểm bán hoặc kênh bán|`Ưu đãi riêng chi nhánh Hà Nội`|
|**Mã giảm giá / Voucher**|Khách sử dụng mã để nhận ưu đãi|`NHAP10 giảm 10%`|

##### 5\.3\.2\.4\.5 Card loại CTKM

|Thành phần|Mô tả|
|---|---|
|**Icon**|Icon minh họa nhẹ, không trang trí quá mức|
|**Tên loại CTKM**|Tên ngắn, dễ hiểu|
|**Mô tả**|Một câu giải thích loại CTKM dùng để làm gì|
|**Ví dụ**|Một ví dụ nghiệp vụ cụ thể|
|**Chevron**|Cho biết có thể tap để đi tiếp|
|**Disabled reason**|Hiển thị nếu loại CTKM chưa khả dụng hoặc thiếu quyền|

##### 5\.3\.2\.4\.6 Card mẫu CTKM

|Thành phần|Mô tả|
|---|---|
|**Tên mẫu**|Tên mẫu CTKM|
|**Loại CTKM**|Cơ chế ưu đãi mà mẫu đang sử dụng|
|**Mô tả mẫu**|Mục đích sử dụng mẫu|
|**Cấu hình gợi ý**|Một số thông tin cấu hình chính nếu có|
|**Trạng thái hợp lệ**|Cảnh báo nếu mẫu có dữ liệu không còn hợp lệ|
|**CTA**|Tap card để tạo CTKM từ mẫu|

##### 5\.3\.2\.4\.7 Navigation

|Người dùng chọn|Điều hướng|
|---|---|
|**Giảm giá sản phẩm**|Sang flow tạo CTKM giảm giá sản phẩm|
|**Giảm giá đơn hàng**|Sang flow tạo CTKM giảm giá đơn hàng|
|**Mua X tặng Y**|Sang flow tạo CTKM mua X tặng Y|
|**Combo**|Sang flow tạo CTKM combo|
|**Giảm theo số lượng**|Sang flow tạo CTKM giảm theo số lượng|
|**Theo nhóm khách hàng**|Sang flow tạo CTKM có phạm vi khách hàng được preset|
|**Theo chi nhánh/kênh bán**|Sang flow tạo CTKM có phạm vi chi nhánh/kênh được preset|
|**Voucher**|Sang flow tạo CTKM bằng mã giảm giá/voucher|
|**Mẫu CTKM**|Sang flow tạo CTKM tương ứng với loại CTKM của mẫu, kèm dữ liệu mẫu được prefill|
|**Tạo từ đầu**|Điều hướng sang flow tạo chương trình khuyến mãi tương ứng từ đầu, không sử dụng mẫu CTKM|

##### 5\.3\.2\.4\.8 Empty / Loading / Error states

|State|Nội dung|
|---|---|
|**Loading**|Hiển thị skeleton cho danh sách loại CTKM và mẫu CTKM|
|**No templates**|Không hiển thị section mẫu hoặc hiển thị thông điệp ngắn `Chưa có mẫu thường dùng`|
|**Error loading templates**|Vẫn cho chọn loại CTKM nếu danh sách loại đã tải được|
|**No permission**|Hiển thị thông báo `Bạn không có quyền tạo CTKM`|
|**Unsupported type**|Loại CTKM disabled và hiển thị lý do `Chưa hỗ trợ trong phiên bản này`|

#### 5\.3\.2\.5 Designs

|Design ID|Màn hình / State|Coverage|
|---|---|---|
|**D\-0****1**|Chọn loại CTKM mặc định|FR\-01, FR\-02, FR\-03, FR\-06|
|**D\-0****2**|Chọn CTKM từ mẫu thường dùng|FR\-04, FR\-05, FR\-06|
|**D\-****03**|Loại CTKM bị disabled|BR\-06, BR\-07|
|**D\-****04**|Không có mẫu CTKM|FR\-08|
|**D\-****05**|Lỗi tải mẫu CTKM nhưng vẫn chọn được loại CTKM|FR\-01, FR\-08|
|**D\-****06**|Không có quyền tạo CTKM|FR\-09, BR\-01|

![image\.png](Images_attachments/image%2016.png)

#### 5\.3\.2\.6 Scenarios

|ID|Scenario|Given|When|Then|
|---|---|---|---|---|
|**SC\-01**|Mở màn hình chọn loại CTKM từ danh sách|Người dùng có quyền tạo CTKM|Người dùng bấm nút `+` từ danh sách CTKM|Hệ thống mở màn hình `Tạo CTKM` và hiển thị các loại CTKM khả dụng|
|**SC\-02**|Chọn loại CTKM giảm giá sản phẩm|Người dùng đang ở màn hình chọn loại CTKM|Người dùng chọn `Giảm giá sản phẩm`|Hệ thống điều hướng sang flow tạo CTKM giảm giá sản phẩm|
|**SC\-03**|Chọn mẫu CTKM thường dùng|Hệ thống có danh sách mẫu CTKM|Người dùng chọn một mẫu CTKM|Hệ thống điều hướng sang flow tạo CTKM mới với dữ liệu mẫu được prefill|
|**SC\-04**|Không có mẫu CTKM|Hệ thống chưa có mẫu CTKM|Người dùng mở màn hình tạo CTKM|Hệ thống vẫn hiển thị danh sách loại CTKM để người dùng tạo mới|
|**SC\-05**|Loại CTKM chưa hỗ trợ|Có loại CTKM chưa khả dụng trong v1|Người dùng xem danh sách loại CTKM|Hệ thống không cho chọn loại đó và hiển thị lý do|
|**SC\-06**|Người dùng không có quyền tạo CTKM|Người dùng không có quyền tạo CTKM|Người dùng bấm nút `+`|Hệ thống chặn thao tác và hiển thị thông báo không đủ quyền|
|**SC\-07**|Lỗi tải mẫu CTKM|Danh sách loại CTKM tải thành công nhưng mẫu CTKM lỗi|Người dùng mở màn hình tạo CTKM|Hệ thống vẫn cho chọn loại CTKM và hiển thị cảnh báo nhẹ cho phần mẫu|
|**SC\-08**|Quay lại danh sách CTKM|Người dùng đang ở màn hình chọn loại CTKM|Người dùng bấm back|Hệ thống quay lại danh sách CTKM mà không tạo bản ghi mới|

#### 5\.3\.2\.7 Edge cases

|ID|Edge Case|Hướng xử lý đề xuất|
|---|---|---|
|**EC\-01**<br>|Người dùng chọn loại CTKM nhưng mất quyền trước khi vào flow tạo|Hệ thống kiểm tra lại quyền trước khi mở flow tạo và chặn nếu không còn quyền|
|**EC\-02**|Mẫu CTKM tham chiếu sản phẩm không còn tồn tại|Hệ thống cho mở mẫu nhưng cảnh báo dữ liệu cần kiểm tra lại trong flow tạo|
|**EC\-03**|Mẫu CTKM tham chiếu nhóm khách hàng đã bị xóa|Hệ thống không tự áp dụng nhóm khách hàng cũ và yêu cầu người dùng chọn lại|
|**EC\-04**|Người dùng tap nhiều lần vào cùng một loại CTKM|Hệ thống chỉ xử lý một lần và chống double navigation|
|**EC\-05**|Danh sách loại CTKM dài hơn chiều cao màn hình|Hệ thống cho scroll, giữ top bar cố định nếu cần|
|**EC\-06**|Người dùng mở từ empty state khi danh sách CTKM đang lỗi|Hệ thống vẫn cho tạo mới nếu quyền và cấu hình tạo CTKM tải được|
|**EC\-07**|Loại CTKM đang bị disable do plan/permission|Hệ thống hiển thị lý do rõ ràng, không để người dùng hiểu nhầm là lỗi|

#### 5\.3\.2\.8 Open questions

|ID|Question|Gợi ý|
|---|---|---|
|**OQ\-01**|V1 có cần hiển thị section `Mẫu thường dùng` không?|Có thể làm nếu giúp người dùng tạo nhanh, nhưng không nên phụ thuộc vào mẫu|
|**OQ\-02**|Mẫu CTKM là dữ liệu hệ thống cung cấp hay người dùng tự tạo?|V1 có thể bắt đầu với mẫu hệ thống, phase sau cho phép lưu mẫu riêng|
|**OQ\-03**|Có cần search trong danh sách loại/mẫu CTKM không?|Chưa cần trong v1 nếu số lượng loại/mẫu ít|
|**OQ\-04**|Có cần phân nhóm loại CTKM theo mục tiêu kinh doanh không?|Có thể cân nhắc phase sau, ví dụ `Tăng doanh số`, `Xả hàng`, `Chăm sóc khách quen`|
|**OQ\-05**|Có nên hiển thị loại CTKM chưa hỗ trợ dưới dạng disabled không?|Chỉ nên hiển thị nếu có giá trị định hướng; nếu gây nhiễu thì ẩn khỏi v1|

### 5\.3\.3 US\-03 — Xem chi tiết CTKM

#### 5\.3\.3\.1 Business context

Chi tiết CTKM là nơi người dùng kiểm tra đầy đủ một chương trình khuyến mại sau khi đã nhìn thấy chương trình đó trong danh sách\. Mục tiêu chính của màn hình này không phải là tạo mới hay xử lý vòng đời, mà là giúp người dùng hiểu rõ: CTKM này là gì, đang ở trạng thái nào, áp dụng cho ai/cái gì, có cảnh báo gì không và đã từng bị thay đổi như thế nào\.

US\-03 cần tránh overlap với US\-01 và các lifecycle actions\. US\-01 chỉ giúp người dùng scan danh sách và phát hiện CTKM cần xử lý\. US\-03 đi sâu vào một CTKM cụ thể\. Các action như bật, tạm dừng, kết thúc, hủy hoặc nhân bản có thể được mở từ màn hình chi tiết, nhưng logic nghiệp vụ chính của các action đó sẽ được mô tả ở các US tương ứng\.

Phần lịch sử trong US\-03 nên là lịch sử gần đây hoặc lịch sử theo ngữ cảnh của CTKM hiện tại\. Nếu cần xem, lọc, đối soát hoặc xuất lịch sử thay đổi đầy đủ, phạm vi đó thuộc US\-09\.

#### 5\.3\.3\.2 Functional requirements

|ID|Functional Requirement|Acceptance Criteria|
|---|---|---|
|**FR\-01**<br>|Hiển thị thông tin tổng quan CTKM|Hệ thống hiển thị tên CTKM, mã CTKM, loại CTKM, trạng thái hiện tại và thời gian hiệu lực|
|**FR\-02**|Hiển thị cấu hình ưu đãi|Hệ thống hiển thị cơ chế ưu đãi chính của CTKM như giảm %, giảm tiền, tặng hàng, combo, voucher hoặc bậc số lượng tùy theo loại CTKM|
|**FR\-03**|Hiển thị điều kiện áp dụng|Hệ thống hiển thị các điều kiện để CTKM được áp dụng như sản phẩm, giá trị đơn hàng, số lượng mua, nhóm khách hàng, chi nhánh hoặc kênh bán|
|**FR\-04**|Hiển thị phạm vi áp dụng|Hệ thống hiển thị rõ CTKM áp dụng cho sản phẩm/nhóm sản phẩm, khách hàng/nhóm khách hàng, chi nhánh và kênh bán nào|
|**FR\-05**|Hiển thị trạng thái và cảnh báo|Hệ thống hiển thị trạng thái vòng đời và các cảnh báo liên quan như thiếu thiết lập, có xung đột, sắp hết hạn hoặc không còn đối tượng hợp lệ|
|**FR\-06**|Hiển thị lịch sử gần đây của CTKM|Hệ thống hiển thị các thay đổi gần đây của CTKM gồm người thao tác, thời gian, loại hành động và mô tả ngắn|
|**FR\-07**|Hiển thị action phù hợp theo trạng thái và quyền|Hệ thống chỉ hiển thị các action phù hợp với trạng thái CTKM hiện tại và quyền của người dùng|
|**FR\-08**|Cho phép điều hướng tới các màn hình liên quan|Người dùng có thể đi tới flow chỉnh sửa, xử lý cảnh báo, xem lịch sử đầy đủ hoặc quay lại danh sách CTKM khi phù hợp|

#### 5\.3\.3\.3 Business rules

|ID|Business Rule|
|---|---|
|**BR\-01**|Mỗi màn hình chi tiết chỉ hiển thị dữ liệu của một CTKM tại một thời điểm|
|**BR\-02**|Trạng thái CTKM trên màn hình chi tiết phải là trạng thái mới nhất tại thời điểm tải hoặc thực hiện action|
|**BR\-03**|Cảnh báo CTKM phải được tính lại khi mở màn hình chi tiết hoặc trước khi người dùng thực hiện action nhạy cảm|
|**BR\-04**|Người dùng chỉ được xem các thông tin và action trong phạm vi quyền được cấp|
|**BR\-05**|CTKM đã kết thúc hoặc đã hủy được xem lại nhưng không được sửa để chạy lại trực tiếp|
|**BR\-06**|Các thay đổi trong lịch sử CTKM là dữ liệu audit, không được sửa hoặc xóa từ màn hình chi tiết|
|**BR\-07**|Nếu CTKM có dữ liệu tham chiếu không còn hợp lệ, hệ thống phải hiển thị cảnh báo rõ ràng|
|**BR\-08**|Action hiển thị trên màn hình chi tiết không thay thế confirmation và rule xử lý của từng lifecycle action|

#### 5\.3\.3\.4 UI Contract

##### 5\.3\.3\.4\.1 Mục tiêu màn hình

Màn hình chi tiết CTKM giúp người dùng kiểm tra cấu hình, trạng thái, cảnh báo và lịch sử gần đây của một chương trình khuyến mại cụ thể\.

##### 5\.3\.3\.4\.2 Entry point

|Entry point|Hành vi|
|---|---|
|**Tap vùng nội dung card CTKM từ danh sách**|Mở màn hình chi tiết CTKM|
|**Tap ****`Xem chi tiết`**** từ bottom sheet thao tác**|Mở màn hình chi tiết CTKM|
|**Sau khi lưu nháp hoặc lưu CTKM**|Điều hướng về màn hình chi tiết CTKM vừa lưu|
|**Từ cảnh báo/xung đột liên quan CTKM**|Mở màn hình chi tiết CTKM tại khu vực cảnh báo nếu phù hợp|

##### 5\.3\.3\.4\.3 Cấu trúc màn hình

|Khu vực|Nội dung|
|---|---|
|**Top bar**|Back icon \(←\), title `Chi tiết CTKM`|
|**Header summary card**|Tên CTKM, mã CTKM, loại CTKM, trạng thái, thời gian hiệu lực|
|**Warning banner/card**|Hiển thị nếu CTKM có cảnh báo cần xử lý|
|**Section: Cấu hình ưu đãi**|Cơ chế ưu đãi chính theo loại CTKM|
|**Section: Điều kiện áp dụng**|Điều kiện để CTKM được áp dụng|
|**Section: Phạm vi áp dụng**|Sản phẩm, khách hàng, chi nhánh, kênh bán|
|**Section: Lịch sử gần đây**|Một số thay đổi gần nhất của CTKM|
|**Bottom action area**|Một CTA chính hoặc action theo trạng thái nếu người dùng có quyền|

##### 5\.3\.3\.4\.4 Header summary card

|Thành phần|Mô tả|
|---|---|
|**Tên CTKM**|Tên chương trình khuyến mại|
|**Mã CTKM**|Mã định danh CTKM, ví dụ `CTKM-00024`|
|**Loại CTKM**|Giảm giá sản phẩm, giảm giá đơn hàng, mua X tặng Y, combo, voucher\.\.\.|
|**Trạng thái**|Nháp, sẵn sàng, sắp chạy, đang chạy, tạm dừng, đã kết thúc, đã hủy|
|**Thời gian hiệu lực**|Ngày bắt đầu và ngày kết thúc|
|**Cảnh báo tóm tắt**|Số lượng hoặc mức độ cảnh báo nếu có|

##### 5\.3\.3\.4\.5 Cấu hình ưu đãi

|Loại CTKM|Nội dung cần hiển thị|
|---|---|
|**Giảm giá sản phẩm**|Sản phẩm/nhóm sản phẩm áp dụng, kiểu giảm, giá trị giảm|
|**Giảm giá đơn hàng**|Điều kiện đơn hàng, kiểu giảm, giá trị giảm|
|**Mua X tặng Y**|Sản phẩm mua, số lượng mua, sản phẩm tặng, số lượng tặng|
|**Combo**|Danh sách sản phẩm trong combo, giá combo hoặc ưu đãi combo|
|**Giảm theo số lượng**|Các bậc số lượng và mức ưu đãi tương ứng|
|**Theo nhóm khách hàng**|Nhóm khách hàng áp dụng và ưu đãi tương ứng|
|**Theo chi nhánh/kênh bán**|Chi nhánh/kênh bán áp dụng và điều kiện liên quan|
|**Voucher**|Mã voucher, điều kiện dùng mã, giới hạn sử dụng nếu có|

##### 5\.3\.3\.4\.6 Cảnh báo trên màn hình chi tiết

|Cảnh báo|Hiển thị|
|---|---|
|**Thiếu thiết lập**|Warning card ở gần đầu màn hình, kèm danh sách phần còn thiếu|
|**Có xung đột**|Warning/danger card, có CTA điều hướng tới xử lý xung đột nếu người dùng có quyền|
|**Sắp hết hạn**|Warning nhẹ, hiển thị ngày hết hạn|
|**Không còn sản phẩm hợp lệ**|Danger card, yêu cầu kiểm tra phạm vi sản phẩm|
|**Không còn khách hàng hợp lệ**|Danger card, yêu cầu kiểm tra phạm vi khách hàng|
|**Không đủ quyền thao tác**|Không hiển thị action hoặc disable action kèm lý do|

##### 5\.3\.3\.4\.7 Lịch sử gần đây

|Thành phần|Mô tả|
|---|---|
|**Thời gian**|Thời điểm phát sinh thay đổi|
|**Người thao tác**|Người đã thực hiện thay đổi|
|**Loại hành động**|Tạo, sửa, bật, tạm dừng, bật lại, kết thúc, hủy, nhân bản|
|**Mô tả ngắn**|Tóm tắt thay đổi|
|**CTA phụ**|`Xem lịch sử đầy đủ` nếu người dùng có quyền và US\-09 được hỗ trợ|

##### 5\.3\.3\.4\.8 Action theo trạng thái

|**Trạng thái**|**Action khả dụng**|
|---|---|
|**Nháp**|Tiếp tục thiết lập, Xóa nháp|
|**Sẵn sàng**|Chỉnh sửa, Bật CTKM|
|**Sắp chạy**|Tạm dừng|
|**Đang chạy**|Tạm dừng, Kết thúc sớm|
|**Tạm dừng**|Bật lại, Kết thúc|
|**Đã kết thúc**|Nhân bản|
|**Đã hủy**|Nhân bản|

##### 5\.3\.3\.4\.9 Empty / Loading / Error states

|State|Nội dung|
|---|---|
|**Loading**|Skeleton cho header summary và các section chính|
|**Not found**|CTKM không tồn tại hoặc đã bị xóa nháp; CTA quay lại danh sách|
|**Error**|Không tải được chi tiết CTKM; CTA thử lại|
|**No permission**|Người dùng không có quyền xem chi tiết CTKM|
|**Partial error**|Nếu lỗi tải lịch sử nhưng thông tin chính tải được, vẫn hiển thị chi tiết và báo lỗi riêng cho phần lịch sử|

#### 5\.3\.3\.5 Designs

|Design ID|Màn hình / State|Mục tiêu|Coverage|
|---|---|---|---|
|**D\-01**|Chi tiết CTKM mặc định|Trạng thái khi người dùng vừa mở chi tiết CTKM, chưa bật action sheet|FR\-01, FR\-02, FR\-03, FR\-04|
|**D\-02**|Chi tiết CTKM có cảnh báo|Hiển thị CTKM có cảnh báo/xung đột cần người dùng chú ý|FR\-05, BR\-03, BR\-07|
|**D\-03**|Chi tiết CTKM trạng thái nháp|Hiển thị CTKM nháp, thiếu thiết lập, chưa thể chạy|FR\-05, FR\-07|
|**D\-04**|Lịch sử gần đây của CTKM|Hiển thị tối đa 3 lịch sử gần nhất và link `Xem tất cả` nếu có nhiều hơn 3|FR\-06|
|**D\-05**|Tất cả lịch sử CTKM|Màn hình phụ hiển thị danh sách lịch sử đầy đủ của một CTKM|FR\-06, FR\-08|
|**D\-06**|Loading / Error / No permission / Not found|Các trạng thái đặc biệt khi tải hoặc truy cập chi tiết CTKM|FR\-08, BR\-04|
|**D\-07**|Action sheet — Nháp|Người dùng mở action sheet từ CTKM trạng thái nháp|FR\-07|
|**D\-08**|Action sheet — Sẵn sàng|Người dùng mở action sheet từ CTKM trạng thái sẵn sàng|FR\-07|
|**D\-09**|CTA — Sắp chạy|CTKM sắp chạy chỉ có một action chính là `Tạm dừng`|FR\-07|
|**D\-10**|Action sheet — Đang chạy|Người dùng mở action sheet từ CTKM đang chạy|FR\-07|
|**D\-11**|Action sheet — Tạm dừng|Người dùng mở action sheet từ CTKM tạm dừng|FR\-07|
|**D\-12**|CTA — Đã kết thúc|CTKM đã kết thúc chỉ có một action chính là `Nhân bản`|FR\-07|
|**D\-13**|CTA — Đã hủy|CTKM đã hủy chỉ có một action chính là `Nhân bản`|FR\-07|

![image\.png](Images_attachments/image%206.png)

![image\.png](Images_attachments/image%2012.png)

![image\.png](Images_attachments/image%208.png)

#### 5\.3\.3\.6 Scenarios

|ID|Scenario|Given|When|Then|
|---|---|---|---|---|
|**SC\-01**|Mở chi tiết CTKM từ danh sách|Người dùng có quyền xem CTKM|Người dùng tap vào vùng nội dung của một CTKM trong danh sách|Hệ thống mở màn hình chi tiết CTKM tương ứng|
|**SC\-02**|Kiểm tra cấu hình CTKM|CTKM đã có cấu hình ưu đãi và điều kiện áp dụng|Người dùng mở màn hình chi tiết|Hệ thống hiển thị đầy đủ cấu hình ưu đãi, điều kiện và phạm vi áp dụng|
|**SC\-03**|Xem CTKM có cảnh báo|CTKM đang có cảnh báo|Người dùng mở màn hình chi tiết|Hệ thống hiển thị warning card ở gần đầu màn hình cùng nội dung cảnh báo|
|**SC\-04**|Xem lịch sử gần đây|CTKM đã từng có thay đổi|Người dùng kéo tới section lịch sử gần đây|Hệ thống hiển thị các thay đổi gần nhất của CTKM|
|**SC\-05**|Action hiển thị theo trạng thái|CTKM có trạng thái cụ thể và người dùng có quyền phù hợp|Người dùng mở màn hình chi tiết|Hệ thống hiển thị action chính phù hợp với trạng thái hiện tại|
|**SC\-06**|Trạng thái thay đổi trong lúc đang xem|CTKM bị người khác thay đổi trạng thái|Người dùng thực hiện action từ màn hình chi tiết|Hệ thống kiểm tra lại trạng thái mới nhất trước khi tiếp tục|
|**SC\-07**|Không có quyền xem chi tiết|Người dùng không có quyền xem CTKM|Người dùng cố mở chi tiết CTKM|Hệ thống hiển thị no permission state|
|**SC\-08**|CTKM không còn tồn tại|CTKM đã bị xóa nháp hoặc không tìm thấy|Người dùng mở đường dẫn chi tiết CTKM|Hệ thống hiển thị not found state và CTA quay lại danh sách|

#### 5\.3\.3\.7 Edge cases

|ID|Edge Case|Hướng xử lý đề xuất|
|---|---|---|
|**EC\-01**|CTKM bị đổi trạng thái sau khi người dùng mở chi tiết|Kiểm tra lại trạng thái trước khi thực hiện action và cập nhật UI nếu cần|
|**EC\-02**|CTKM tham chiếu sản phẩm đã bị ngừng bán hoặc xóa|Hiển thị cảnh báo ở phần phạm vi áp dụng|
|**EC\-03**|CTKM tham chiếu nhóm khách hàng đã bị xóa|Hiển thị cảnh báo và yêu cầu kiểm tra lại nhóm khách hàng|
|**EC\-04**|Người dùng có quyền xem nhưng không có quyền thao tác|Hiển thị chi tiết ở chế độ read\-only và ẩn/disable action|
|**EC\-05**|Lịch sử thay đổi quá dài|Chỉ hiển thị một số dòng gần đây và dùng CTA `Xem lịch sử đầy đủ`|
|**EC\-06**|Lỗi tải riêng phần lịch sử|Vẫn hiển thị thông tin CTKM chính và báo lỗi riêng cho section lịch sử|
|**EC\-07**|CTKM có nhiều cảnh báo cùng lúc|Hiển thị cảnh báo nghiêm trọng nhất trước, các cảnh báo còn lại nằm trong danh sách chi tiết|

#### 5\.3\.3\.8 Open questions

|ID|Question|Gợi ý|
|---|---|---|
|**OQ\-01**|Màn hình chi tiết có cần hiển thị số liệu hiệu quả CTKM không?|Đề xuất chưa làm trong v1, có thể để dashboard/report phase sau|
|**OQ\-02**|Lịch sử gần đây nên hiển thị bao nhiêu dòng?|Đề xuất 3–5 dòng gần nhất|
|**OQ\-03**|Có cần tab riêng cho `Cấu hình`, `Phạm vi`, `Lịch sử` không?|Mobile v1 nên dùng single scroll \+ card sections trước, tab có thể dùng khi nội dung dài|
|**OQ\-04**|Action chính ở detail nên là một CTA theo trạng thái hay luôn là `Thao tác`?|Đề xuất dùng một CTA chính theo trạng thái; với trạng thái đang chạy có thể dùng `Thao tác` để mở bottom sheet|
|**OQ\-05**|Có cho chỉnh sửa trực tiếp từ màn hình chi tiết không?|Có thể có CTA `Chỉnh sửa` theo quyền và trạng thái, nhưng rule chỉnh sửa cần nằm ở US lifecycle/chỉnh sửa tương ứng|

### 5\.3\.4 US\-04 — Kiểm tra và bật CTKM

#### 5\.3\.4\.1 Business context

US\-04 xử lý thời điểm người dùng muốn đưa một CTKM từ trạng thái có thể chuẩn bị sang trạng thái có thể áp dụng trong vận hành thực tế\. Đây là bước quan trọng vì sau khi bật, CTKM có thể ảnh hưởng trực tiếp tới giá bán, đơn hàng, doanh thu và trải nghiệm tại POS\.

US này không cấu hình nội dung CTKM và cũng không hiển thị chi tiết đầy đủ như US\-03\. Trọng tâm của US\-04 là kiểm tra điều kiện sẵn sàng, cảnh báo rủi ro, yêu cầu xác nhận và cập nhật trạng thái CTKM một cách an toàn\.

Nếu CTKM hợp lệ và thời gian bắt đầu đã tới, sau khi bật hệ thống chuyển CTKM sang trạng thái `Đang chạy`\. Nếu CTKM hợp lệ nhưng thời gian bắt đầu ở tương lai, sau khi bật hệ thống chuyển CTKM sang trạng thái `Sắp chạy`\.

#### 5\.3\.4\.2 Functional requirements

|ID|Functional Requirement|Acceptance Criteria|
|---|---|---|
|**FR\-01**|Mở flow kiểm tra trước khi bật CTKM|Người dùng có thể mở flow từ action `Bật CTKM` ở danh sách hoặc chi tiết CTKM|
|**FR\-02**|Hiển thị thông tin tóm tắt CTKM cần bật|Hệ thống hiển thị tên CTKM, mã CTKM, loại CTKM, trạng thái hiện tại và thời gian hiệu lực|
|**FR\-03**|Kiểm tra thiết lập bắt buộc|Hệ thống kiểm tra các thông tin bắt buộc theo loại CTKM đã được thiết lập đầy đủ chưa|
|**FR\-04**|Kiểm tra thời gian hiệu lực|Hệ thống kiểm tra ngày bắt đầu, ngày kết thúc và xác định trạng thái sau khi bật|
|**FR\-05**|Kiểm tra phạm vi áp dụng|Hệ thống kiểm tra CTKM còn đối tượng áp dụng hợp lệ như sản phẩm, khách hàng, chi nhánh, kênh bán|
|**FR\-06**|Kiểm tra cảnh báo và xung đột|Hệ thống hiển thị lỗi chặn bật hoặc cảnh báo không chặn bật nếu có|
|**FR\-07**|Xác nhận trước khi bật CTKM|Người dùng phải xác nhận trước khi hệ thống cập nhật trạng thái CTKM|
|**FR\-08**|Cập nhật trạng thái và ghi lịch sử|Sau khi bật thành công, hệ thống cập nhật trạng thái CTKM và ghi lịch sử thao tác|

#### 5\.3\.4\.3 Business rules

|ID|Business Rule|
|---|---|
|**BR\-01**|Chỉ người dùng có quyền phù hợp mới được bật CTKM|
|**BR\-02**|Chỉ CTKM ở trạng thái `Sẵn sàng` mới được bật trực tiếp|
|**BR\-03**|CTKM ở trạng thái `Nháp` phải hoàn tất thiết lập trước khi bật|
|**BR\-04**|CTKM có lỗi chặn không được bật cho tới khi lỗi được xử lý|
|**BR\-05**|CTKM có cảnh báo không chặn vẫn có thể bật nếu người dùng xác nhận|
|**BR\-06**|Trước khi bật, hệ thống phải kiểm tra lại dữ liệu mới nhất để tránh trạng thái cũ|
|**BR\-07**|Nếu thời gian bắt đầu ở tương lai, bật CTKM sẽ chuyển trạng thái thành `Sắp chạy`|
|**BR\-08**|Nếu thời gian bắt đầu đã tới và thời gian kết thúc chưa qua, bật CTKM sẽ chuyển trạng thái thành `Đang chạy`|
|**BR\-09**|Mọi thao tác bật CTKM phải được ghi vào lịch sử thay đổi|

#### 5\.3\.4\.4 UI Contract

##### 5\.3\.4\.4\.1 Mục tiêu màn hình

Màn hình giúp người dùng kiểm tra nhanh CTKM đã đủ điều kiện bật hay chưa, hiểu rõ các cảnh báo liên quan và xác nhận trước khi CTKM bắt đầu ảnh hưởng tới vận hành bán hàng\.

##### 5\.3\.4\.4\.2 Entry point

|Entry point|Hành vi|
|---|---|
|**Danh sách CTKM**|Người dùng mở action sheet của CTKM trạng thái `Sẵn sàng`, chọn `Bật CTKM`|
|**Chi tiết CTKM**|Người dùng mở action sheet hoặc CTA của CTKM trạng thái `Sẵn sàng`, chọn `Bật CTKM`|
|**Sau khi hoàn tất thiết lập**|Nếu CTKM đủ điều kiện, hệ thống có thể điều hướng sang màn hình kiểm tra trước khi bật|

##### 5\.3\.4\.4\.3 Cấu trúc màn hình

|Khu vực|Nội dung|
|---|---|
|**Top bar**|Back icon \(←\), title `Kiểm tra CTKM`|
|**Summary card**|Tên CTKM, mã CTKM, loại CTKM, trạng thái hiện tại, thời gian hiệu lực|
|**Result card**|Kết quả kiểm tra tổng quan: `Có thể bật`, `Cần xem lại`, hoặc `Chưa thể bật`|
|**Checklist**|Các nhóm kiểm tra: thiết lập, thời gian, phạm vi áp dụng, xung đột, quyền thao tác|
|**Warning / Error card**|Hiển thị lỗi chặn hoặc cảnh báo không chặn|
|**Bottom CTA**|`Bật CTKM`, `Sửa thiết lập`, hoặc trạng thái disabled tùy kết quả kiểm tra|

##### 5\.3\.4\.4\.4 Checklist kiểm tra

|Nhóm kiểm tra|Nội dung|
|---|---|
|**Thiết lập bắt buộc**|Đủ tên, loại CTKM, cơ chế ưu đãi, điều kiện áp dụng bắt buộc|
|**Thời gian hiệu lực**|Có ngày bắt đầu, ngày kết thúc hợp lệ, chưa quá hạn|
|**Phạm vi áp dụng**|Có ít nhất một đối tượng áp dụng hợp lệ|
|**Xung đột CTKM**|Không có xung đột chặn bật với CTKM khác|
|**Quyền thao tác**|Người dùng có quyền bật CTKM|
|**Dữ liệu tham chiếu**|Sản phẩm, khách hàng, chi nhánh, kênh bán còn hợp lệ|

##### 5\.3\.4\.4\.5 Kết quả kiểm tra

|Kết quả|Hiển thị|CTA|
|---|---|---|
|**Có thể bật**|Success state, checklist đạt|`Bật CTKM`|
|**Cần xem lại**|Warning state, có cảnh báo không chặn|`Bật CTKM`|
|**Chưa thể bật**|Error state, có lỗi chặn|`Sửa thiết lập`|
|**Không có quyền**|No permission state|`Quay lại`|
|**Không tải được kiểm tra**|Error state|`Thử lại`|

##### 5\.3\.4\.4\.6 Confirmation modal

|Thành phần|Nội dung|
|---|---|
|**Title**|`Bật CTKM?`|
|**Description khi chạy ngay**|`CTKM sẽ bắt đầu được áp dụng cho đơn hàng mới sau khi bật.`|
|**Description khi chạy trong tương lai**|`CTKM sẽ chuyển sang Sắp chạy và tự động áp dụng từ thời gian bắt đầu.`|
|**CTA phụ**|`Để sau`|
|**CTA chính**|`Bật CTKM`|

##### 5\.3\.4\.4\.7 Sau khi bật thành công

|Trường hợp|Hành vi|
|---|---|
|**Bắt đầu ngay**|Cập nhật trạng thái thành `Đang chạy`, hiển thị toast thành công|
|**Bắt đầu trong tương lai**|Cập nhật trạng thái thành `Sắp chạy`, hiển thị toast thành công|
|**Nguồn vào từ chi tiết**|Quay lại màn hình chi tiết CTKM với trạng thái mới|
|**Nguồn vào từ danh sách**|Quay lại danh sách CTKM và cập nhật card tương ứng|

#### 5\.3\.4\.5 Designs

|Design ID|Màn hình / State|Coverage|
|---|---|---|
|**D\-01**|Kiểm tra CTKM — có thể bật|FR\-02, FR\-03, FR\-04, FR\-05|
|**D\-02**|Kiểm tra CTKM — có cảnh báo không chặn|FR\-06, BR\-05|
|**D\-03**|Kiểm tra CTKM — có lỗi chặn|FR\-03, FR\-04, FR\-05, BR\-04|
|**D\-04**|Confirmation modal bật CTKM|FR\-07|
|**D\-05**|Bật thành công — chuyển `Đang chạy`|FR\-08, BR\-08|
|**D\-06**|Bật thành công — chuyển `Sắp chạy`|FR\-08, BR\-07|
|**D\-07**|Error / No permission / State changed|FR\-06, FR\-08, BR\-01, BR\-06|

![image\.png](Images_attachments/image%2023.png)

![image\.png](Images_attachments/image%2025.png)

![image\.png](Images_attachments/image%2017.png)

#### 5\.3\.4\.6 Scenarios

|ID|Scenario|Given|When|Then|
|---|---|---|---|---|
|**SC\-01**|Mở màn hình kiểm tra trước khi bật|CTKM đang ở trạng thái `Sẵn sàng`|Người dùng chọn `Bật CTKM`|Hệ thống mở màn hình `Kiểm tra CTKM`|
|**SC\-02**|Bật CTKM chạy ngay|CTKM hợp lệ và thời gian bắt đầu đã tới|Người dùng xác nhận bật|Hệ thống chuyển CTKM sang `Đang chạy`|
|**SC\-03**|Bật CTKM chạy trong tương lai|CTKM hợp lệ và thời gian bắt đầu ở tương lai|Người dùng xác nhận bật|Hệ thống chuyển CTKM sang `Sắp chạy`|
|**SC\-04**|CTKM có cảnh báo không chặn|CTKM có cảnh báo nhưng vẫn đủ điều kiện bật|Người dùng chọn bật|Hệ thống hiển thị confirmation có cảnh báo và cho phép tiếp tục|
|**SC\-05**|CTKM có lỗi chặn|CTKM thiếu thiết lập hoặc có dữ liệu không hợp lệ|Người dùng mở kiểm tra|Hệ thống không cho bật và hiển thị CTA `Sửa thiết lập`|
|**SC\-06**|Trạng thái thay đổi trước khi bật|CTKM bị người khác thay đổi trạng thái|Người dùng xác nhận bật|Hệ thống kiểm tra lại, dừng thao tác và thông báo trạng thái đã thay đổi|
|**SC\-07**|Người dùng không có quyền bật|Người dùng không có quyền thao tác|Người dùng mở hoặc xác nhận bật|Hệ thống hiển thị no permission state|
|**SC\-08**|Bật thất bại do lỗi hệ thống|Dữ liệu hợp lệ nhưng API bật lỗi|Người dùng xác nhận bật|Hệ thống hiển thị lỗi và cho phép thử lại|

#### 5\.3\.4\.7 Edge cases

|ID|Edge Case|Hướng xử lý đề xuất|
|---|---|---|
|**EC\-01**|Ngày kết thúc đã qua|Chặn bật và yêu cầu sửa thời gian hiệu lực|
|**EC\-02**|Ngày bắt đầu nhỏ hơn hiện tại nhưng ngày kết thúc còn hiệu lực|Cho phép bật và chuyển sang `Đang chạy`|
|**EC\-03**|Phạm vi áp dụng rỗng do sản phẩm/khách hàng bị xóa hoặc ngừng hoạt động|Chặn bật và hiển thị lý do|
|**EC\-04**|Có CTKM khác vừa được bật gây xung đột|Kiểm tra lại trước khi confirm, nếu xung đột chặn thì dừng bật|
|**EC\-05**|Người dùng bấm CTA nhiều lần|Disable CTA trong lúc xử lý để tránh gửi nhiều request|
|**EC\-06**|Mất mạng sau khi xác nhận|Hiển thị trạng thái không chắc chắn và cho phép tải lại trạng thái mới nhất|
|**EC\-07**|Quyền người dùng bị thay đổi trong lúc đang ở màn hình kiểm tra|Kiểm tra lại quyền trước khi cập nhật trạng thái|

#### 5\.3\.4\.8 Open questions

|ID|Question|Gợi ý|
|---|---|---|
|**OQ\-01**|Loại xung đột nào là lỗi chặn, loại nào chỉ là cảnh báo?|Cần có bảng rule riêng cho conflict priority|
|**OQ\-02**|Có cho phép bật CTKM khi còn cảnh báo không chặn không?|Đề xuất có, nhưng confirmation phải hiển thị cảnh báo|
|**OQ\-03**|Khi CTKM bắt đầu trong tương lai, CTA nên là `Bật CTKM` hay `Lên lịch chạy`?|Đề xuất vẫn dùng `Bật CTKM`, trạng thái sau bật là `Sắp chạy`|
|**OQ\-04**|Sau khi bật thành công nên quay về danh sách hay chi tiết?|Đề xuất quay về nơi người dùng bắt đầu flow|
|**OQ\-05**|Có cần gửi thông báo cho nhân viên/cửa hàng sau khi bật CTKM không?|Có thể để phase sau nếu chưa cần trong v1|

### 5\.3\.5 US\-05 — Tạm dừng hoặc bật lại CTKM

#### 5\.3\.5\.1 Business context

Trong quá trình vận hành, một CTKM đang chạy hoặc sắp chạy có thể cần được tạm dừng vì nhiều lý do: phát hiện sai cấu hình, hết hàng, sai phạm vi áp dụng, có xung đột chính sách, thay đổi kế hoạch kinh doanh hoặc cần kiểm tra lại trước khi tiếp tục áp dụng\.

Ngược lại, một CTKM đã tạm dừng có thể cần được bật lại khi vấn đề đã được xử lý và chương trình vẫn còn trong thời gian hiệu lực\.

US\-05 chỉ tập trung vào hai hành động vòng đời: **Tạm dừng** và **Bật lại**\. US này không xử lý việc bật CTKM lần đầu, kết thúc sớm, hủy CTKM hoặc nhân bản CTKM\. Các hành động đó thuộc các user story khác trong common lifecycle\.

Mục tiêu nghiệp vụ là giúp người dùng kiểm soát CTKM một cách an toàn, tránh tiếp tục áp dụng sai ưu đãi tại bán hàng, đồng thời vẫn cho phép khôi phục chương trình khi còn hợp lệ\.

#### 5\.3\.5\.2 Functional requirements

|ID|Functional Requirement|Acceptance Criteria|
|---|---|---|
|**FR\-01**|Cho phép tạm dừng CTKM hợp lệ|Người dùng có quyền có thể tạm dừng CTKM ở trạng thái `Sắp chạy` hoặc `Đang chạy`|
|**FR\-02**|Cho phép bật lại CTKM đang tạm dừng|Người dùng có quyền có thể bật lại CTKM ở trạng thái `Tạm dừng` nếu CTKM còn hợp lệ|
|**FR\-03**|Hiển thị confirmation trước khi tạm dừng|Trước khi tạm dừng, hệ thống hiển thị modal/bottom confirmation nêu rõ tác động của hành động|
|**FR\-04**|Hiển thị kiểm tra hợp lệ trước khi bật lại|Trước khi bật lại, hệ thống kiểm tra thời gian hiệu lực, phạm vi áp dụng, cấu hình bắt buộc và xung đột|
|**FR\-05**|Cập nhật trạng thái CTKM sau thao tác|Sau khi tạm dừng hoặc bật lại thành công, trạng thái CTKM được cập nhật trên chi tiết và danh sách CTKM|
|**FR\-06**|Ghi nhận lịch sử thao tác|Mỗi lần tạm dừng hoặc bật lại phải ghi nhận người thao tác, thời gian, hành động và ghi chú nếu có|
|**FR\-07**|Xử lý lỗi khi thao tác không thành công|Nếu thao tác thất bại, hệ thống giữ nguyên trạng thái cũ và hiển thị thông báo lỗi phù hợp|
|**FR\-08**|Kiểm soát quyền thao tác|Nếu người dùng không có quyền, hệ thống không cho thực hiện hành động và hiển thị lý do|

#### 5\.3\.5\.3 Business rules

|ID|Business Rule|
|---|---|
|**BR\-01**|Chỉ CTKM ở trạng thái `Sắp chạy` hoặc `Đang chạy` mới được tạm dừng|
|**BR\-02**|Chỉ CTKM ở trạng thái `Tạm dừng` mới được bật lại|
|**BR\-03**|CTKM đã kết thúc hoặc đã hủy không được bật lại trực tiếp|
|**BR\-04**|Khi CTKM bị tạm dừng, chương trình không được áp dụng cho đơn hàng mới|
|**BR\-05**|Việc tạm dừng không làm thay đổi cấu hình, thời gian hiệu lực hoặc lịch sử áp dụng trước đó của CTKM|
|**BR\-06**|Khi bật lại, CTKM phải còn trong thời gian hiệu lực và không thiếu thiết lập bắt buộc|
|**BR\-07**|Nếu CTKM có xung đột nghiêm trọng, hệ thống phải chặn bật lại hoặc yêu cầu xử lý xung đột trước|
|**BR\-08**|Mọi hành động tạm dừng hoặc bật lại phải được ghi vào lịch sử thay đổi|

#### 5\.3\.5\.4 UI Contract

##### 5\.3\.5\.4\.1 Mục tiêu màn hình

UI của US\-05 giúp người dùng tạm dừng hoặc bật lại CTKM một cách có kiểm soát, có confirmation, có kiểm tra hợp lệ và có phản hồi rõ ràng sau thao tác\.

##### 5\.3\.5\.4\.2 Entry point

|Entry point|Hành vi|
|---|---|
|**Danh sách CTKM → Thao tác**|Mở bottom sheet action của CTKM, cho phép chọn `Tạm dừng` hoặc `Bật lại` nếu hợp lệ|
|**Chi tiết CTKM → Thao tác ︿**|Mở bottom sheet action theo trạng thái CTKM|
|**Chi tiết CTKM có một action duy nhất**|Có thể hiển thị CTA trực tiếp nếu chỉ còn một hành động khả dụng|
|**Sau khi xử lý cảnh báo**|Người dùng có thể quay lại chi tiết CTKM và bật lại nếu CTKM đã hợp lệ|

##### 5\.3\.5\.4\.3 Cấu trúc màn hình tạm dừng

|Khu vực|Nội dung|
|---|---|
|**Top bar**|Back icon \(←\), title `Chi tiết CTKM`|
|**Header summary card**|Tên CTKM, mã CTKM, loại CTKM, trạng thái hiện tại|
|**CTA / Action trigger**|`Thao tác ︿` hoặc CTA trực tiếp `Tạm dừng` tùy số lượng action khả dụng|
|**Bottom sheet action**|Danh sách action khả dụng theo trạng thái|
|**Confirmation modal**|Xác nhận tạm dừng CTKM và nêu rõ CTKM sẽ không còn áp dụng cho đơn hàng mới|
|**Result feedback**|Toast hoặc inline feedback sau khi tạm dừng thành công/thất bại|

##### 5\.3\.5\.4\.4 Cấu trúc màn hình bật lại

|Khu vực|Nội dung|
|---|---|
|**Top bar**|Back icon \(←\), title `Chi tiết CTKM`|
|**Header summary card**|Tên CTKM, mã CTKM, loại CTKM, trạng thái `Tạm dừng`|
|**Status notice**|Thông báo CTKM đang tạm dừng và không áp dụng cho đơn hàng mới|
|**Bottom sheet action**|Hiển thị `Bật lại` và các action khác nếu có|
|**Validation before resume**|Kiểm tra thời gian hiệu lực, cấu hình, phạm vi và xung đột trước khi bật lại|
|**Confirmation modal**|Xác nhận bật lại CTKM nếu cần|
|**Result feedback**|Toast hoặc inline feedback sau khi bật lại thành công/thất bại|

##### 5\.3\.5\.4\.5 Action availability

|Trạng thái CTKM|Action liên quan đến US\-05|
|---|---|
|**Nháp**|Không có|
|**Sẵn sàng**|Không có|
|**Sắp chạy**|Tạm dừng|
|**Đang chạy**|Tạm dừng|
|**Tạm dừng**|Bật lại|
|**Đã kết thúc**|Không có|
|**Đã hủy**|Không có|

##### 5\.3\.5\.4\.6 Confirmation copy

|Action|Title|Nội dung|Primary CTA|Secondary CTA|
|---|---|---|---|---|
|**Tạm dừng**|`Tạm dừng CTKM?`|`CTKM này sẽ không được áp dụng cho đơn hàng mới cho đến khi được bật lại.`|`Tạm dừng`|`Giữ CTKM`|
|**Bật lại**|`Bật lại CTKM?`|`CTKM sẽ được áp dụng trở lại nếu còn hiệu lực và không có lỗi thiết lập.`|`Bật lại`|`Để tạm dừng`|

##### 5\.3\.5\.4\.7 Validation khi bật lại

|Kiểm tra|Hành vi|
|---|---|
|**Còn trong thời gian hiệu lực**|Nếu đã hết hạn, chặn bật lại và gợi ý nhân bản|
|**Đủ cấu hình bắt buộc**|Nếu thiếu thiết lập, chặn bật lại và điều hướng tới phần cần bổ sung|
|**Phạm vi áp dụng còn hợp lệ**|Nếu sản phẩm/khách hàng/chi nhánh không còn hợp lệ, chặn hoặc cảnh báo tùy mức độ|
|**Không có xung đột nghiêm trọng**|Nếu có xung đột, yêu cầu xử lý trước khi bật lại|
|**Người dùng có quyền**|Nếu không có quyền, ẩn hoặc disable action|

##### 5\.3\.5\.4\.8 Success / Error feedback

|Tình huống|Feedback|
|---|---|
|**Tạm dừng thành công**|Toast: `Đã tạm dừng CTKM`|
|**Bật lại thành công**|Toast: `Đã bật lại CTKM`|
|**Không đủ quyền**|Inline/error message: `Bạn không có quyền thực hiện thao tác này`|
|**CTKM đã hết hạn**|Message: `CTKM đã hết hạn, không thể bật lại`|
|**Có xung đột**|Message: `Cần xử lý xung đột trước khi bật lại`|
|**Lỗi hệ thống**|Message: `Không thể cập nhật trạng thái. Vui lòng thử lại`|

#### 5\.3\.5\.5 Designs

|Design ID|Màn hình / State|Coverage|
|---|---|---|
|**D\-01**|Action sheet — CTKM đang chạy|FR\-01, BR\-01|
|**D\-02**|Confirmation modal — Tạm dừng CTKM|FR\-03, BR\-04|
|**D\-03**|Tạm dừng thành công|FR\-05, FR\-06|
|**D\-04**|Action sheet — CTKM tạm dừng|FR\-02, BR\-02|
|**D\-05**|Confirmation modal — Bật lại CTKM|FR\-04, FR\-05|
|**D\-06**|Bật lại bị chặn do hết hạn/thiếu thiết lập/xung đột|FR\-04, FR\-07, BR\-06, BR\-07|
|**D\-07**|Không có quyền tạm dừng/bật lại|FR\-08|

![image\.png](Images_attachments/image%2014.png)

![image\.png](Images_attachments/image%2015.png)

#### 5\.3\.5\.6 Scenarios

|ID|Scenario|Given|When|Then|
|---|---|---|---|---|
|**SC\-01**|Tạm dừng CTKM đang chạy|CTKM đang ở trạng thái `Đang chạy` và người dùng có quyền|Người dùng chọn `Tạm dừng`|Hệ thống hiển thị confirmation trước khi tạm dừng|
|**SC\-02**|Xác nhận tạm dừng CTKM|Confirmation tạm dừng đang hiển thị|Người dùng bấm `Tạm dừng`|Hệ thống đổi trạng thái CTKM sang `Tạm dừng`, ghi lịch sử và hiển thị feedback thành công|
|**SC\-03**|Hủy thao tác tạm dừng|Confirmation tạm dừng đang hiển thị|Người dùng bấm `Giữ CTKM`|Hệ thống đóng confirmation và giữ nguyên trạng thái CTKM|
|**SC\-04**|Bật lại CTKM tạm dừng|CTKM đang ở trạng thái `Tạm dừng`, còn hiệu lực và hợp lệ|Người dùng chọn `Bật lại`|Hệ thống kiểm tra hợp lệ và cho xác nhận bật lại|
|**SC\-05**|Xác nhận bật lại CTKM|Confirmation bật lại đang hiển thị|Người dùng bấm `Bật lại`|Hệ thống đổi trạng thái CTKM sang trạng thái phù hợp, ghi lịch sử và hiển thị feedback thành công|
|**SC\-06**|Bật lại CTKM đã hết hạn|CTKM đang tạm dừng nhưng đã hết thời gian hiệu lực|Người dùng chọn `Bật lại`|Hệ thống chặn bật lại và gợi ý nhân bản nếu cần chạy lại|
|**SC\-07**|Bật lại CTKM có xung đột|CTKM đang tạm dừng và có xung đột nghiêm trọng|Người dùng chọn `Bật lại`|Hệ thống chặn bật lại và yêu cầu xử lý xung đột trước|
|**SC\-08**|Người dùng không đủ quyền|Người dùng không có quyền tạm dừng/bật lại|Người dùng mở action|Hệ thống không hiển thị action hoặc disable action kèm lý do|

#### 5\.3\.5\.7 Edge cases

|ID|Edge Case|Hướng xử lý đề xuất|
|---|---|---|
|**EC\-01**|CTKM đổi trạng thái trong lúc confirmation đang mở|Kiểm tra lại trạng thái trước khi submit action|
|**EC\-02**|Người dùng bấm tạm dừng nhiều lần liên tiếp|Disable CTA sau lần bấm đầu tiên để tránh double submit|
|**EC\-03**|CTKM đang chạy nhưng vừa hết hạn khi người dùng thao tác|Không tạm dừng nữa, cập nhật trạng thái thành `Đã kết thúc` nếu phù hợp|
|**EC\-04**|CTKM tạm dừng nhưng ngày bắt đầu nằm trong tương lai|Khi bật lại, trạng thái nên trở về `Sắp chạy`, không phải `Đang chạy`|
|**EC\-05**|CTKM tạm dừng và đang trong thời gian hiệu lực|Khi bật lại, trạng thái nên trở về `Đang chạy`|
|**EC\-06**|Lỗi mạng sau khi submit action|Hiển thị trạng thái không chắc chắn và yêu cầu reload/kiểm tra lại|
|**EC\-07**|Người dùng có quyền xem nhưng không có quyền thao tác|Hiển thị chi tiết read\-only, không cho tạm dừng/bật lại|

#### 5\.3\.5\.8 Open questions

|ID|Question|Gợi ý|
|---|---|---|
|**OQ\-01**|Khi bật lại CTKM tạm dừng, có cần confirmation không?|Nên có confirmation nếu CTKM ảnh hưởng trực tiếp đến giá bán|
|**OQ\-02**|Có cần nhập lý do tạm dừng không?|V1 có thể chưa bắt buộc; phase sau có thể thêm trường `Lý do` cho audit tốt hơn|
|**OQ\-03**|CTKM sắp chạy khi tạm dừng rồi bật lại thì trở về trạng thái nào?|Nếu thời gian bắt đầu chưa tới, trở về `Sắp chạy`; nếu đã trong thời gian hiệu lực, trở về `Đang chạy`|
|**OQ\-04**|Có cho phép tạm dừng hàng loạt ở US này không?|Không; bulk action nằm ở US\-08|
|**OQ\-05**|Có cần thông báo cho nhân viên bán hàng khi CTKM bị tạm dừng/bật lại không?|Có thể cân nhắc toast/in\-app notification ở phase sau nếu ảnh hưởng POS|

### 5\.3\.6 US\-06 — Kết thúc sớm hoặc hủy CTKM

#### 5\.3\.6\.1 Business context

Trong vận hành thực tế, người quản lý có thể cần dừng hẳn một CTKM trước kế hoạch vì chương trình không còn phù hợp, phát hiện sai cấu hình, hết hàng, thay đổi chính sách bán hàng hoặc có rủi ro áp dụng sai ưu đãi\.

US\-06 tập trung vào hai hành động cuối vòng đời: **Kết thúc sớm** và **Hủy CTKM**\. Hai hành động này đều là hành động nhạy cảm, có ảnh hưởng trực tiếp tới việc CTKM có còn được áp dụng cho đơn hàng mới hay không\.

Cần phân biệt rõ: **Kết thúc sớm** dùng cho CTKM đã hoặc đang có khả năng áp dụng trong bán hàng; **Hủy CTKM** dùng cho CTKM chưa nên được chạy hoặc không còn muốn đưa vào vận hành\. Sau khi kết thúc hoặc hủy, CTKM không được bật lại trực tiếp; nếu muốn chạy lại, người dùng nên dùng flow **Nhân bản CTKM**\.

US này không xử lý `Tạm dừng/Bật lại` vì đã thuộc US\-05, không xử lý `Nhân bản` vì thuộc US riêng, và không xử lý `Xóa nháp` nếu đó là hành động loại bỏ bản nháp chưa hoàn chỉnh\.

#### 5\.3\.6\.2 Functional requirements

|ID|Functional Requirement|Acceptance Criteria|
|---|---|---|
|**FR\-01**|Cho phép kết thúc sớm CTKM hợp lệ|Người dùng có quyền có thể kết thúc sớm CTKM ở trạng thái `Đang chạy`|
|**FR\-02**|Cho phép kết thúc CTKM đang tạm dừng|Người dùng có quyền có thể kết thúc CTKM ở trạng thái `Tạm dừng` nếu CTKM đã từng hoặc đang trong thời gian hiệu lực|
|**FR\-03**|Cho phép hủy CTKM chưa cần chạy|Người dùng có quyền có thể hủy CTKM ở trạng thái `Sẵn sàng` hoặc `Sắp chạy` nếu CTKM chưa phát sinh áp dụng thực tế|
|**FR\-04**|Hiển thị confirmation trước hành động nhạy cảm|Trước khi kết thúc sớm hoặc hủy, hệ thống phải hiển thị confirmation nêu rõ tác động và tính không thể hoàn tác|
|**FR\-05**|Cập nhật trạng thái sau khi xác nhận|Sau khi thao tác thành công, trạng thái CTKM được cập nhật thành `Đã kết thúc` hoặc `Đã hủy`|
|**FR\-06**|Dừng áp dụng CTKM cho đơn hàng mới|Sau khi kết thúc hoặc hủy, CTKM không được áp dụng cho đơn hàng mới|
|**FR\-07**|Ghi nhận lịch sử thao tác|Hệ thống ghi nhận người thao tác, thời gian, hành động, trạng thái trước/sau và ghi chú nếu có|
|**FR\-08**|Xử lý lỗi và quyền thao tác|Nếu không đủ quyền, trạng thái không hợp lệ hoặc thao tác thất bại, hệ thống giữ nguyên trạng thái cũ và hiển thị lý do|

#### 5\.3\.6\.3 Business rules

|ID|Business Rule|
|---|---|
|**BR\-01**|Chỉ CTKM ở trạng thái `Đang chạy` mới được `Kết thúc sớm` trực tiếp|
|**BR\-02**|CTKM ở trạng thái `Tạm dừng` có thể `Kết thúc` nếu chương trình đã từng hoặc đang trong thời gian hiệu lực|
|**BR\-03**|CTKM ở trạng thái `Sẵn sàng` hoặc `Sắp chạy` có thể `Hủy` nếu chưa phát sinh áp dụng thực tế|
|**BR\-04**|CTKM đã `Đã kết thúc` hoặc `Đã hủy` không được kết thúc/hủy thêm lần nữa|
|**BR\-05**|Hành động kết thúc hoặc hủy không làm thay đổi các đơn hàng đã phát sinh trước đó|
|**BR\-06**|Sau khi kết thúc hoặc hủy, CTKM không được chỉnh sửa để bật lại trực tiếp|
|**BR\-07**|Nếu trạng thái CTKM thay đổi trong lúc confirmation đang mở, hệ thống phải kiểm tra lại trước khi submit|
|**BR\-08**|Mọi hành động kết thúc hoặc hủy phải được ghi vào lịch sử thay đổi để phục vụ audit|

#### 5\.3\.6\.4 UI Contract

##### 5\.3\.6\.4\.1 Mục tiêu màn hình

UI của US\-06 giúp người dùng thực hiện hành động kết thúc hoặc hủy CTKM một cách có kiểm soát, có confirmation rõ ràng, tránh thao tác nhầm và đảm bảo người dùng hiểu tác động trước khi xác nhận\.

##### 5\.3\.6\.4\.2 Entry point

|Entry point|Hành vi|
|---|---|
|**Danh sách CTKM → Thao tác**|Mở bottom sheet action của CTKM, hiển thị `Kết thúc sớm`, `Kết thúc` hoặc `Hủy CTKM` nếu hợp lệ|
|**Chi tiết CTKM → Thao tác ︿**|Mở bottom sheet action theo trạng thái CTKM|
|**Confirmation modal**|Hiển thị sau khi người dùng chọn action nhạy cảm|
|**Sau khi thao tác thành công**|Quay lại màn hình chi tiết CTKM với trạng thái mới|

##### 5\.3\.6\.4\.3 Action availability

|Trạng thái CTKM|Action thuộc US\-06|Ghi chú|
|---|---|---|
|**Nháp**|Không xử lý trong US này|Dùng `Xóa nháp` nếu cần|
|**Sẵn sàng**|Hủy CTKM|Chỉ khi chưa phát sinh áp dụng|
|**Sắp chạy**|Hủy CTKM|Chỉ khi chưa tới thời điểm áp dụng|
|**Đang chạy**|Kết thúc sớm|Dừng áp dụng cho đơn hàng mới|
|**Tạm dừng**|Kết thúc|Dừng hẳn CTKM đang tạm dừng|
|**Đã kết thúc**|Không có|Có thể `Nhân bản` ở US khác|
|**Đã hủy**|Không có|Có thể `Nhân bản` ở US khác|

##### 5\.3\.6\.4\.4 Cấu trúc bottom sheet action

|Khu vực|Nội dung|
|---|---|
|**Overlay**|Làm mờ nội dung phía sau để tập trung vào bottom sheet|
|**Sheet handle**|Thanh kéo nhỏ ở đầu bottom sheet|
|**Header**|Tên CTKM, mã CTKM, loại CTKM, trạng thái hiện tại|
|**Action rows**|Danh sách action khả dụng theo trạng thái|
|**Danger action**|`Kết thúc sớm`, `Kết thúc` hoặc `Hủy CTKM` hiển thị bằng semantic danger nếu là hành động cuối vòng đời|
|**Cancel CTA**|`Hủy` hoặc đóng bottom sheet, không làm thay đổi dữ liệu|

##### 5\.3\.6\.4\.5 Confirmation copy

|Action|Title|Nội dung|Primary CTA|Secondary CTA|
|---|---|---|---|---|
|**Kết thúc sớm**|`Kết thúc sớm CTKM?`|`CTKM này sẽ không còn được áp dụng cho đơn hàng mới. Các đơn hàng đã áp dụng trước đó không bị thay đổi.`|`Kết thúc sớm`|`Giữ CTKM`|
|**Kết thúc**|`Kết thúc CTKM?`|`CTKM đang tạm dừng sẽ được kết thúc hẳn và không thể bật lại trực tiếp.`|`Kết thúc`|`Giữ tạm dừng`|
|**Hủy CTKM**|`Hủy CTKM?`|`CTKM này sẽ không được đưa vào áp dụng. Hành động này được ghi vào lịch sử và không thể hoàn tác.`|`Hủy CTKM`|`Giữ CTKM`|

##### 5\.3\.6\.4\.6 Ghi chú / lý do thao tác

|Thành phần|Quy tắc đề xuất|
|---|---|
|**Ghi chú lý do**|V1 có thể để optional|
|**Placeholder**|`Nhập lý do nếu cần`|
|**Hiển thị lịch sử**|Nếu có ghi chú, lịch sử hiển thị kèm lý do|
|**Bắt buộc nhập lý do**|Có thể cân nhắc ở phase sau nếu cần audit chặt hơn|

##### 5\.3\.6\.4\.7 Success / Error feedback

|Tình huống|Feedback|
|---|---|
|**Kết thúc sớm thành công**|Toast: `Đã kết thúc sớm CTKM`|
|**Kết thúc thành công**|Toast: `Đã kết thúc CTKM`|
|**Hủy thành công**|Toast: `Đã hủy CTKM`|
|**Không đủ quyền**|Message: `Bạn không có quyền thực hiện thao tác này`|
|**Trạng thái không còn hợp lệ**|Message: `Trạng thái CTKM đã thay đổi. Vui lòng tải lại`|
|**CTKM đã phát sinh áp dụng**|Message: `Không thể hủy CTKM đã phát sinh áp dụng. Vui lòng kết thúc chương trình`|
|**Lỗi hệ thống**|Message: `Không thể cập nhật trạng thái. Vui lòng thử lại`|

#### 5\.3\.6\.5 Designs

|Design ID|Màn hình / State|Coverage|
|---|---|---|
|**D\-01**|Action sheet — CTKM đang chạy|FR\-01, BR\-01|
|**D\-02**|Confirmation modal — Kết thúc sớm CTKM|FR\-04, BR\-05|
|**D\-03**|Kết thúc sớm thành công|FR\-05, FR\-06, FR\-07|
|**D\-04**|Action sheet — CTKM sẵn sàng/sắp chạy|FR\-03, BR\-03|
|**D\-05**|Confirmation modal — Hủy CTKM|FR\-04, BR\-03|
|**D\-06**|Hủy CTKM thành công|FR\-05, FR\-06, FR\-07|
|**D\-07**|Bị chặn do trạng thái/điều kiện không hợp lệ|FR\-08, BR\-07|
|**D\-08**|Không có quyền kết thúc/hủy CTKM|FR\-08|

![image\.png](Images_attachments/image%2010.png)

![image\.png](Images_attachments/image%203.png)

#### 5\.3\.6\.6 Scenarios

|ID|Scenario|Given|When|Then|
|---|---|---|---|---|
|**SC\-01**|Kết thúc sớm CTKM đang chạy|CTKM đang ở trạng thái `Đang chạy` và người dùng có quyền|Người dùng chọn `Kết thúc sớm`|Hệ thống hiển thị confirmation kết thúc sớm|
|**SC\-02**|Xác nhận kết thúc sớm|Confirmation kết thúc sớm đang hiển thị|Người dùng bấm `Kết thúc sớm`|Hệ thống đổi trạng thái thành `Đã kết thúc`, dừng áp dụng cho đơn hàng mới và ghi lịch sử|
|**SC\-03**|Giữ CTKM khi confirmation đang mở|Confirmation đang hiển thị|Người dùng bấm `Giữ CTKM`|Hệ thống đóng confirmation và giữ nguyên trạng thái|
|**SC\-04**|Hủy CTKM sẵn sàng|CTKM ở trạng thái `Sẵn sàng`, chưa phát sinh áp dụng|Người dùng chọn `Hủy CTKM`|Hệ thống hiển thị confirmation hủy CTKM|
|**SC\-05**|Xác nhận hủy CTKM|Confirmation hủy đang hiển thị|Người dùng bấm `Hủy CTKM`|Hệ thống đổi trạng thái thành `Đã hủy` và ghi lịch sử|
|**SC\-06**|Không cho hủy CTKM đã phát sinh áp dụng|CTKM đã từng được áp dụng cho đơn hàng|Người dùng chọn `Hủy CTKM`|Hệ thống chặn hủy và gợi ý dùng `Kết thúc sớm` nếu phù hợp|
|**SC\-07**|Trạng thái thay đổi trước khi submit|CTKM bị người khác thay đổi trạng thái|Người dùng xác nhận action|Hệ thống kiểm tra lại, chặn submit và yêu cầu tải lại|
|**SC\-08**|Người dùng không đủ quyền|Người dùng không có quyền kết thúc/hủy|Người dùng mở action|Hệ thống ẩn hoặc disable action kèm lý do|

#### 5\.3\.6\.7 Edge cases

|ID|Edge Case|Hướng xử lý đề xuất|
|---|---|---|
|**EC\-01**|Người dùng bấm submit nhiều lần|Disable primary CTA sau lần bấm đầu tiên|
|**EC\-02**|CTKM đang chạy nhưng vừa hết hạn tự nhiên|Cập nhật trạng thái `Đã kết thúc`, không cần thực hiện `Kết thúc sớm`|
|**EC\-03**|CTKM sắp chạy nhưng đã tới thời điểm bắt đầu khi user xác nhận hủy|Kiểm tra lại trạng thái; nếu đã `Đang chạy`, không cho hủy và gợi ý `Kết thúc sớm`|
|**EC\-04**|CTKM đã phát sinh đơn hàng test hoặc đơn hàng bị hủy|Cần rule rõ: chỉ tính là đã phát sinh áp dụng nếu ưu đãi đã được ghi nhận vào đơn hợp lệ|
|**EC\-05**|Lỗi mạng sau khi submit|Hiển thị trạng thái không chắc chắn và yêu cầu tải lại chi tiết CTKM|
|**EC\-06**|Người dùng có quyền xem nhưng không có quyền kết thúc/hủy|Hiển thị read\-only, ẩn hoặc disable action nhạy cảm|
|**EC\-07**|Có ghi chú lý do quá dài|Giới hạn ký tự và báo lỗi inline|

#### 5\.3\.6\.8 Open questions

|ID|Question|Gợi ý|
|---|---|---|
|**OQ\-01**|Có bắt buộc nhập lý do khi kết thúc sớm/hủy không?|V1 nên optional; phase sau có thể bắt buộc nếu cần audit chặt|
|**OQ\-02**|CTKM `Sắp chạy` có nên cho `Hủy CTKM` trực tiếp không?|Nên có, vì chương trình chưa áp dụng thực tế|
|**OQ\-03**|CTKM `Tạm dừng` nên dùng label `Kết thúc` hay `Kết thúc sớm`?|Đề xuất dùng `Kết thúc` vì CTKM đã không còn đang chạy|
|**OQ\-04**|Có cần nhập mã xác nhận cho hành động nhạy cảm không?|Chưa cần ở v1; confirmation rõ ràng là đủ|
|**OQ\-05**|Có cần thông báo tới POS/nhân viên bán hàng khi CTKM bị kết thúc/hủy không?|Có thể cân nhắc in\-app notification ở phase sau|

### 5\.3\.7 US\-07 — Nhân bản CTKM

#### 5\.3\.7\.1 Business context

US\-07 cho phép người dùng tạo nhanh một CTKM mới dựa trên một CTKM đã có\. Mục tiêu là giảm thao tác lặp lại khi cửa hàng thường xuyên chạy lại các chương trình giống nhau theo tháng, mùa vụ, nhóm sản phẩm hoặc nhóm khách hàng\.

Khác với US\-02 , US\-07 dùng một CTKM thật đã từng được tạo trong hệ thống làm nguồn nhân bản\. Vì vậy bản sao cần kế thừa cấu hình nghiệp vụ quan trọng, nhưng không được sao chép các dữ liệu định danh, trạng thái vận hành, lịch sử, hiệu quả bán hàng hoặc lượt sử dụng của CTKM gốc\.

Kết quả an toàn nhất sau khi nhân bản là tạo ra một CTKM mới ở trạng thái `Nháp`, để người dùng kiểm tra lại tên, thời gian hiệu lực, phạm vi áp dụng và các cảnh báo trước khi bật\.

#### 5\.3\.7\.2 Functional requirements

|ID|Functional Requirement|Acceptance Criteria|
|---|---|---|
|**FR\-01**|Cho phép mở flow nhân bản từ một CTKM đã có|Người dùng có thể chọn action `Nhân bản` từ danh sách hoặc màn hình chi tiết CTKM nếu có quyền|
|**FR\-02**|Hiển thị thông tin CTKM nguồn|Hệ thống hiển thị tên, mã, loại CTKM, trạng thái và thời gian hiệu lực của CTKM nguồn|
|**FR\-03**|Hiển thị nội dung sẽ được sao chép|Hệ thống cho người dùng biết các phần được sao chép như loại CTKM, cấu hình ưu đãi, điều kiện và phạm vi áp dụng|
|**FR\-04**|Hiển thị nội dung không được sao chép|Hệ thống hiển thị rõ các phần không sao chép như mã CTKM, trạng thái, lịch sử, số liệu sử dụng và hiệu quả bán hàng|
|**FR\-05**|Cho phép đặt thông tin cơ bản cho bản sao|Người dùng có thể chỉnh tên CTKM mới và thời gian hiệu lực mới trước khi tạo bản nháp|
|**FR\-06**|Kiểm tra dữ liệu tham chiếu của CTKM nguồn|Hệ thống kiểm tra sản phẩm, nhóm khách hàng, chi nhánh, kênh bán hoặc điều kiện áp dụng còn hợp lệ hay không|
|**FR\-07**|Tạo CTKM mới từ CTKM nguồn|Hệ thống tạo một CTKM mới ở trạng thái `Nháp` với mã mới và cấu hình được sao chép hợp lệ|
|**FR\-08**|Ghi lịch sử thao tác nhân bản|Hệ thống ghi nhận CTKM mới được nhân bản từ CTKM nguồn nào, bởi ai và vào thời điểm nào|

#### 5\.3\.7\.3 Business rules

|ID|Business Rule|
|---|---|
|**BR\-01**|Chỉ người dùng có quyền tạo CTKM mới mới được nhân bản CTKM|
|**BR\-02**|CTKM được nhân bản luôn tạo ra một CTKM mới, không chỉnh sửa CTKM nguồn|
|**BR\-03**|CTKM mới sau khi nhân bản luôn ở trạng thái `Nháp`|
|**BR\-04**|Mã CTKM mới phải được sinh mới, không được sao chép từ CTKM nguồn|
|**BR\-05**|Lịch sử thao tác, số liệu sử dụng, số đơn hàng áp dụng và hiệu quả bán hàng không được sao chép|
|**BR\-06**|Các tham chiếu không còn hợp lệ phải được cảnh báo rõ trước khi tạo bản nháp|
|**BR\-07**|Nếu cấu hình sau khi loại bỏ tham chiếu không hợp lệ không còn đủ dữ liệu bắt buộc, CTKM mới vẫn có thể được tạo ở trạng thái `Nháp` nhưng phải hiển thị cảnh báo thiếu thiết lập|
|**BR\-08**|CTKM đã nhân bản không được tự động bật; người dùng phải đi qua flow kiểm tra và bật CTKM ở US\-04|

#### 5\.3\.7\.4 UI Contract

##### 5\.3\.7\.4\.1 Mục tiêu màn hình

Màn hình giúp người dùng hiểu rõ CTKM nào đang được dùng làm nguồn, phần nào sẽ được sao chép, phần nào không sao chép và tạo một bản nháp mới một cách an toàn\.

##### 5\.3\.7\.4\.2 Entry point

|Entry point|Hành vi|
|---|---|
|**Danh sách CTKM**|Người dùng mở action sheet của một CTKM và chọn `Nhân bản`|
|**Chi tiết CTKM**|Người dùng chọn CTA/action `Nhân bản` từ màn hình chi tiết CTKM|
|**CTKM đã kết thúc**|Ưu tiên hiển thị action `Nhân bản` để chạy lại chương trình tương tự|
|**CTKM đã hủy**|Cho phép nhân bản nếu người dùng muốn tạo lại chương trình với cấu hình mới|

##### 5\.3\.7\.4\.3 Cấu trúc màn hình

|Khu vực|Nội dung|
|---|---|
|**Top bar**|Back icon \(←\), title `Nhân bản CTKM`|
|**Source card**|Thông tin CTKM nguồn: tên, mã, loại, trạng thái, thời gian hiệu lực|
|**New draft section**|Tên CTKM mới, thời gian hiệu lực mới|
|**Copied content section**|Danh sách các phần sẽ được sao chép|
|**Not copied section**|Danh sách các phần không được sao chép|
|**Warning section**|Cảnh báo nếu CTKM nguồn có dữ liệu không còn hợp lệ|
|**Bottom CTA**|`Tạo bản nháp`|

##### 5\.3\.7\.4\.4 Thông tin mặc định của bản sao

|Trường|Giá trị mặc định|
|---|---|
|**Tên CTKM mới**|`Bản sao của [Tên CTKM nguồn]`|
|**Mã CTKM**|Sinh mới sau khi tạo bản nháp|
|**Loại CTKM**|Sao chép từ CTKM nguồn|
|**Trạng thái**|`Nháp`|
|**Thời gian hiệu lực**|Để trống hoặc yêu cầu thiết lập lại|
|**Cấu hình ưu đãi**|Sao chép nếu còn hợp lệ|
|**Điều kiện áp dụng**|Sao chép nếu còn hợp lệ|
|**Phạm vi áp dụng**|Sao chép các tham chiếu còn hợp lệ|

##### 5\.3\.7\.4\.5 Nội dung được sao chép

|Nhóm nội dung|Ghi chú|
|---|---|
|**Loại CTKM**|Giữ nguyên loại CTKM nguồn|
|**Cơ chế ưu đãi**|Giữ nguyên kiểu giảm giá, mua tặng, combo hoặc voucher nếu còn được hỗ trợ|
|**Điều kiện áp dụng**|Sao chép điều kiện đơn hàng, số lượng, nhóm khách hàng nếu hợp lệ|
|**Phạm vi sản phẩm**|Sao chép sản phẩm/nhóm sản phẩm còn hoạt động|
|**Phạm vi chi nhánh/kênh bán**|Sao chép các chi nhánh/kênh bán còn hợp lệ và người dùng có quyền|
|**Ghi chú nội bộ**|Có thể sao chép nếu không chứa dữ liệu vận hành phát sinh|

##### 5\.3\.7\.4\.6 Nội dung không sao chép

|Nhóm nội dung|Lý do|
|---|---|
|**Mã CTKM**|Mỗi CTKM cần mã định danh riêng|
|**Trạng thái**|Bản sao luôn bắt đầu từ `Nháp`|
|**Thời gian chạy thực tế**|Tránh vô tình chạy lại lịch cũ|
|**Lịch sử thao tác**|Lịch sử thuộc CTKM nguồn|
|**Đơn hàng đã áp dụng**|Dữ liệu phát sinh không thuộc bản sao|
|**Lượt sử dụng / giới hạn đã dùng**|Phải bắt đầu lại từ 0 cho CTKM mới|
|**Hiệu quả bán hàng**|Thuộc kết quả của CTKM nguồn|

##### 5\.3\.7\.4\.7 Warning / validation

|Tình huống|Cách hiển thị|
|---|---|
|**Sản phẩm không còn hoạt động**|Warning card: `Một số sản phẩm không còn hợp lệ`|
|**Nhóm khách hàng đã bị xóa**|Warning card: `Nhóm khách hàng không còn tồn tại`|
|**Chi nhánh/kênh bán không còn quyền áp dụng**|Warning card: `Một số phạm vi áp dụng đã bị loại bỏ`|
|**Loại CTKM không còn được hỗ trợ**|Error card: `Không thể nhân bản loại CTKM này`|
|**Thiếu thiết lập sau khi sao chép**|Warning card và vẫn cho tạo bản nháp|
|**Không có quyền tạo CTKM**|No permission state|

##### 5\.3\.7\.4\.8 Success behavior

|Sau khi tạo bản nháp|Hành vi|
|---|---|
|**Tạo thành công không cảnh báo**|Hiển thị success state và CTA `Mở bản nháp`|
|**Tạo thành công có cảnh báo**|Hiển thị success state kèm cảnh báo cần kiểm tra lại|
|**Người dùng chọn mở bản nháp**|Điều hướng tới màn hình chi tiết hoặc chỉnh sửa CTKM mới|
|**Người dùng chọn quay lại danh sách**|Quay lại danh sách CTKM và hiển thị CTKM mới ở trạng thái `Nháp`|

#### 5\.3\.7\.5 Designs

|Design ID|Màn hình / State|Coverage|
|---|---|---|
|**D\-01**|Nhân bản CTKM mặc định|FR\-02, FR\-03, FR\-04, FR\-05|
|**D\-02**|Nhân bản CTKM có cảnh báo dữ liệu nguồn|FR\-06, BR\-06, BR\-07|
|**D\-03**|Chỉnh thông tin bản sao trước khi tạo nháp|FR\-05|
|**D\-04**|Tạo bản nháp thành công|FR\-07, FR\-08|
|**D\-05**|Tạo bản nháp thành công nhưng có cảnh báo|FR\-06, FR\-07|
|**D\-06**|Error / No permission / Source changed|FR\-06, FR\-07, BR\-01|

![image\.png](Images_attachments/image%209.png)

![image\.png](Images_attachments/image%2018.png)

#### 5\.3\.7\.6 Scenarios

|ID|Scenario|Given|When|Then|
|---|---|---|---|---|
|**SC\-01**|Nhân bản CTKM đã kết thúc|Người dùng có quyền tạo CTKM|Người dùng chọn `Nhân bản` từ CTKM đã kết thúc|Hệ thống mở màn hình `Nhân bản CTKM` với thông tin CTKM nguồn|
|**SC\-02**|Nhân bản CTKM đã hủy|CTKM đã hủy vẫn còn cấu hình hợp lệ|Người dùng chọn `Nhân bản`|Hệ thống cho phép tạo bản nháp mới từ cấu hình nguồn|
|**SC\-03**|Tạo bản nháp từ CTKM nguồn hợp lệ|CTKM nguồn không có cảnh báo dữ liệu|Người dùng bấm `Tạo bản nháp`|Hệ thống tạo CTKM mới ở trạng thái `Nháp`|
|**SC\-04**|Nhân bản khi có dữ liệu không còn hợp lệ|Một số sản phẩm/nhóm khách hàng trong CTKM nguồn không còn hợp lệ|Người dùng mở màn hình nhân bản|Hệ thống hiển thị cảnh báo và chỉ sao chép phần hợp lệ|
|**SC\-05**|Nhân bản tạo ra bản nháp thiếu thiết lập|Sau khi loại bỏ dữ liệu không hợp lệ, bản sao thiếu thông tin bắt buộc|Người dùng tạo bản nháp|Hệ thống tạo bản nháp và hiển thị cảnh báo cần bổ sung thiết lập|
|**SC\-06**|Không có quyền nhân bản|Người dùng không có quyền tạo CTKM|Người dùng chọn `Nhân bản`|Hệ thống hiển thị no permission state|
|**SC\-07**|CTKM nguồn thay đổi trong lúc nhân bản|CTKM nguồn bị người khác chỉnh sửa hoặc xóa|Người dùng bấm `Tạo bản nháp`|Hệ thống kiểm tra lại nguồn và yêu cầu tải lại nếu có thay đổi quan trọng|
|**SC\-08**|Tạo bản nháp thất bại|Hệ thống lỗi khi tạo CTKM mới|Người dùng bấm `Tạo bản nháp`|Hệ thống hiển thị lỗi và cho phép thử lại|

#### 5\.3\.7\.7 Edge cases

|ID|Edge Case|Hướng xử lý đề xuất|
|---|---|---|
|**EC\-01**|CTKM nguồn đã bị xóa sau khi người dùng mở màn hình nhân bản|Dừng tạo bản nháp và hiển thị `CTKM nguồn không còn tồn tại`|
|**EC\-02**|Loại CTKM nguồn không còn được hỗ trợ ở phiên bản hiện tại|Chặn nhân bản và hướng người dùng chọn loại CTKM khác|
|**EC\-03**|Tên mặc định của bản sao quá dài|Tự rút gọn tên theo giới hạn ký tự và cho phép người dùng sửa|
|**EC\-04**|Người dùng tạo nhiều bản sao liên tiếp từ cùng một CTKM|Cho phép, nhưng mã CTKM phải khác nhau và tên mặc định nên có hậu tố phân biệt|
|**EC\-05**|CTKM nguồn có phạm vi áp dụng lớn|Hiển thị tóm tắt số lượng và cho phép xem chi tiết ở màn hình chỉnh sửa|
|**EC\-06**|Bản sao không còn sản phẩm áp dụng hợp lệ|Tạo bản nháp với cảnh báo `Chưa có sản phẩm áp dụng` hoặc yêu cầu bổ sung trước khi bật|
|**EC\-07**|Mất mạng sau khi bấm tạo bản nháp|Hiển thị trạng thái không chắc chắn và cho phép tải lại danh sách nháp|

#### 5\.3\.7\.8 Open questions

|ID|Question|Gợi ý|
|---|---|---|
|**OQ\-01**|Có cho phép nhân bản từ mọi trạng thái CTKM không, hay chỉ `Đã kết thúc` và `Đã hủy`?|Đề xuất v1 ưu tiên `Đã kết thúc` và `Đã hủy`; các trạng thái khác có thể bổ sung sau|
|**OQ\-02**|Thời gian hiệu lực có nên được sao chép không?|Đề xuất không sao chép, yêu cầu người dùng đặt lại để tránh chạy nhầm lịch cũ|
|**OQ\-03**|Có cần cho người dùng chọn phần nào được sao chép không?|Đề xuất v1 sao chép mặc định cấu hình hợp lệ; chưa cần checkbox nâng cao|
|**OQ\-04**|Tên CTKM có bắt buộc unique không?|Đề xuất mã CTKM bắt buộc unique; tên có thể trùng nhưng nên cảnh báo nhẹ nếu trùng|
|**OQ\-05**|Sau khi tạo bản nháp nên mở màn hình chi tiết hay màn hình chỉnh sửa?|Đề xuất mở màn hình chỉnh sửa/thiết lập để người dùng cập nhật thời gian và kiểm tra cấu hình|
|**OQ\-06**|Có cần lưu quan hệ `nhân bản từ CTKM nào` để audit không?|Đề xuất có, lưu trong lịch sử và metadata của CTKM mới|

### 5\.3\.8 US\-08 — Thao tác hàng loạt với nhiều CTKM

#### 5\.3\.8\.1 Business context

Trong vận hành thực tế, quản trị viên có thể cần xử lý nhiều CTKM cùng lúc, ví dụ tạm dừng nhiều chương trình khi phát hiện sai phạm vi áp dụng, kết thúc hàng loạt các CTKM không còn phù hợp, hoặc xóa nhiều bản nháp không còn dùng nữa\.

US\-08 tập trung vào **bulk action** trên danh sách CTKM\. Mục tiêu là giúp người dùng xử lý nhanh nhiều CTKM, nhưng vẫn phải đảm bảo an toàn vì các thao tác này có thể ảnh hưởng trực tiếp tới bán hàng, giá áp dụng và lịch sử vận hành\.

US này không thay thế logic của các action đơn lẻ ở US\-05 và US\-06\. Bulk action chỉ là cách thực hiện nhiều thao tác cùng loại trên nhiều CTKM\. Rule hợp lệ, confirmation, ghi lịch sử và xử lý lỗi vẫn phải tuân theo logic vòng đời đã định nghĩa ở các US trước\.

#### 5\.3\.8\.2 Functional requirements

|ID|Functional Requirement|Acceptance Criteria|
|---|---|---|
|**FR\-01**|Cho phép vào chế độ chọn nhiều CTKM|Người dùng có quyền có thể bật selection mode từ danh sách CTKM|
|**FR\-02**|Cho phép chọn/bỏ chọn nhiều CTKM|Người dùng có thể chọn từng CTKM, bỏ chọn từng CTKM hoặc thoát khỏi chế độ chọn|
|**FR\-03**|Hiển thị số lượng CTKM đã chọn|Hệ thống hiển thị số lượng CTKM đang được chọn ở top bar hoặc bottom action bar|
|**FR\-04**|Hiển thị bulk actions phù hợp|Hệ thống chỉ hiển thị hoặc enable các bulk action phù hợp với tập CTKM đã chọn|
|**FR\-05**|Cho phép tạm dừng hàng loạt|Người dùng có thể tạm dừng nhiều CTKM hợp lệ trong một lần thao tác|
|**FR\-06**|Cho phép kết thúc hàng loạt|Người dùng có thể kết thúc nhiều CTKM hợp lệ trong một lần thao tác|
|**FR\-07**|Cho phép xóa nháp hàng loạt|Người dùng có thể xóa nhiều CTKM ở trạng thái `Nháp`|
|**FR\-08**|Hiển thị confirmation trước bulk action|Trước khi thực hiện bulk action, hệ thống hiển thị số lượng CTKM sẽ bị ảnh hưởng và cảnh báo tác động|
|**FR\-09**|Hiển thị kết quả xử lý hàng loạt|Sau khi xử lý, hệ thống hiển thị số CTKM thành công, thất bại và lý do thất bại nếu có|
|**FR\-10**|Ghi nhận lịch sử cho từng CTKM|Mỗi CTKM được xử lý thành công phải có lịch sử thao tác riêng|

#### 5\.3\.8\.3 Business rules

|ID|Business Rule|
|---|---|
|**BR\-01**|Chỉ người dùng có quyền quản trị CTKM hoặc quyền bulk action mới được thao tác hàng loạt|
|**BR\-02**|Bulk `Tạm dừng` chỉ áp dụng cho CTKM ở trạng thái `Sắp chạy` hoặc `Đang chạy`|
|**BR\-03**|Bulk `Kết thúc` chỉ áp dụng cho CTKM ở trạng thái `Đang chạy` hoặc `Tạm dừng`|
|**BR\-04**|Bulk `Xóa nháp` chỉ áp dụng cho CTKM ở trạng thái `Nháp`|
|**BR\-05**|Nếu tập chọn có cả CTKM hợp lệ và không hợp lệ, hệ thống phải hiển thị số lượng hợp lệ/không hợp lệ trước khi xác nhận|
|**BR\-06**|Hệ thống không được âm thầm xử lý CTKM không hợp lệ trong bulk action|
|**BR\-07**|Trước khi submit, hệ thống phải kiểm tra lại trạng thái mới nhất của từng CTKM|
|**BR\-08**|Nếu một phần CTKM xử lý thất bại, các CTKM thành công vẫn được giữ kết quả và hệ thống hiển thị partial success|
|**BR\-09**|Bulk action không được thay đổi đơn hàng đã phát sinh trước đó|
|**BR\-10**|Bulk action phải ghi lịch sử cho từng CTKM, không chỉ ghi một log tổng|

#### 5\.3\.8\.4 UI Contract

##### 5\.3\.8\.4\.1 Mục tiêu màn hình

UI của US\-08 giúp quản trị viên chọn nhiều CTKM từ danh sách và thực hiện nhanh các thao tác hàng loạt như `Tạm dừng`, `Kết thúc` hoặc `Xóa nháp`, đồng thời vẫn kiểm soát được số lượng, trạng thái hợp lệ và kết quả xử lý\.

##### 5\.3\.8\.4\.2 Entry point

|Entry point|Hành vi|
|---|---|
|**Danh sách CTKM → Long press card**|Bật selection mode và chọn CTKM đầu tiên|
|**Danh sách CTKM → CTA chọn nhiều**|Bật selection mode nhưng chưa chọn CTKM nào|
|**Action menu của danh sách**|Có thể có item `Chọn nhiều` nếu cần entry point rõ hơn|
|**Sau khi bulk action thành công**|Quay về danh sách CTKM, giữ filter hiện tại và cập nhật trạng thái|

##### 5\.3\.8\.4\.3 Cấu trúc selection mode

|Khu vực|Nội dung|
|---|---|
|**Top bar**|Back/Close icon \(← hoặc `Đóng`\), title `Đã chọn X CTKM`|
|**Search/filter area**|Có thể giữ nguyên nhưng disable thay đổi filter trong lúc đang chọn|
|**Campaign list**|Card CTKM có checkbox hoặc selected state rõ ràng|
|**Selected card state**|Card có border/surface brand và checkbox selected|
|**Bottom action bar**|Hiển thị các bulk action khả dụng theo tập chọn|
|**Disabled action state**|Action không hợp lệ bị disabled kèm lý do hoặc tooltip/bottom sheet giải thích|

##### 5\.3\.8\.4\.4 Bulk action availability

|Tập CTKM đã chọn|Action khả dụng|
|---|---|
|**Chỉ gồm CTKM ****`Nháp`**|`Xóa nháp`|
|**Chỉ gồm CTKM ****`Sắp chạy`**** hoặc ****`Đang chạy`**|`Tạm dừng`|
|**Chỉ gồm CTKM ****`Đang chạy`**** hoặc ****`Tạm dừng`**|`Kết thúc`|
|**Gồm nhiều trạng thái khác nhau nhưng có CTKM hợp lệ**|Hiển thị action khả dụng kèm số lượng hợp lệ|
|**Không có CTKM hợp lệ cho action nào**|Bulk action disabled|

##### 5\.3\.8\.4\.5 Bottom action bar

|Thành phần|Mô tả|
|---|---|
|**Selected count**|`Đã chọn X CTKM`|
|**Primary action**|Action phù hợp nhất với tập chọn nếu chỉ có một nhóm hành động rõ ràng|
|**More actions**|Nếu có nhiều action khả dụng, dùng `Thao tác ︿` để mở bottom sheet|
|**Clear selection**|Cho phép bỏ chọn toàn bộ|
|**Cancel selection**|Thoát selection mode và quay về danh sách mặc định|

##### 5\.3\.8\.4\.6 Confirmation modal

|Action|Title|Nội dung chính|Primary CTA|Secondary CTA|
|---|---|---|---|---|
|**Tạm dừng hàng loạt**|`Tạm dừng X CTKM?`|`Các CTKM hợp lệ sẽ không còn áp dụng cho đơn hàng mới cho đến khi được bật lại.`|`Tạm dừng`|`Giữ CTKM`|
|**Kết thúc hàng loạt**|`Kết thúc X CTKM?`|`Các CTKM hợp lệ sẽ được kết thúc và không thể bật lại trực tiếp.`|`Kết thúc`|`Giữ CTKM`|
|**Xóa nháp hàng loạt**|`Xóa X bản nháp?`|`Các bản nháp đã xóa sẽ không còn hiển thị trong danh sách CTKM.`|`Xóa nháp`|`Giữ bản nháp`|

##### 5\.3\.8\.4\.7 Confirmation detail

|Thành phần|Mô tả|
|---|---|
|**Eligible count**|Số CTKM đủ điều kiện xử lý|
|**Ineligible count**|Số CTKM không đủ điều kiện, nếu có|
|**Reason summary**|Tóm tắt lý do không hợp lệ như sai trạng thái, không đủ quyền, đã phát sinh áp dụng|
|**Optional reason input**|`Nhập lý do nếu cần` cho thao tác tạm dừng/kết thúc|
|**Danger styling**|`Kết thúc` và `Xóa nháp` dùng semantic danger|

##### 5\.3\.8\.4\.8 Result state

|Kết quả|UI|
|---|---|
|**Tất cả thành công**|Toast hoặc success state: `Đã xử lý X CTKM`|
|**Một phần thành công**|Result screen/card: `X thành công, Y thất bại`|
|**Tất cả thất bại**|Error state với lý do và CTA `Thử lại` hoặc `Quay lại danh sách`|
|**Có trạng thái thay đổi khi submit**|Hiển thị các CTKM bị bỏ qua do trạng thái đã thay đổi|

#### 5\.3\.8\.5 Designs

|Design ID|Màn hình / State|Coverage|
|---|---|---|
|**D\-01**|Danh sách CTKM — Selection mode|FR\-01, FR\-02, FR\-03|
|**D\-02**|Danh sách CTKM — Đã chọn nhiều CTKM|FR\-02, FR\-03|
|**D\-03**|Bottom action bar / Bulk action sheet|FR\-04|
|**D\-04**|Confirmation modal — Tạm dừng hàng loạt|FR\-05, FR\-08|
|**D\-05**|Confirmation modal — Kết thúc hàng loạt|FR\-06, FR\-08|
|**D\-06**|Confirmation modal — Xóa nháp hàng loạt|FR\-07, FR\-08|
|**D\-07**|Kết quả xử lý hàng loạt thành công|FR\-09, FR\-10|
|**D\-08**|Partial success / Có CTKM thất bại|FR\-09|
|**D\-09**|Không có quyền thao tác hàng loạt|FR\-04, BR\-01|
|**D\-10**|Không có CTKM hợp lệ cho action đã chọn|BR\-05, BR\-06|

![image\.png](Images_attachments/image%202.png)

![image\.png](Images_attachments/image%204.png)

![image\.png](Images_attachments/image%2013.png)

#### 5\.3\.8\.6 Scenarios

|ID|Scenario|Given|When|Then|
|---|---|---|---|---|
|**SC\-01**|Vào selection mode từ danh sách|Người dùng có quyền bulk action|Người dùng long press một CTKM hoặc chọn `Chọn nhiều`|Hệ thống bật selection mode|
|**SC\-02**|Chọn nhiều CTKM|Selection mode đang bật|Người dùng chọn nhiều card CTKM|Hệ thống cập nhật selected count và selected state|
|**SC\-03**|Tạm dừng nhiều CTKM hợp lệ|Các CTKM đã chọn ở trạng thái `Sắp chạy` hoặc `Đang chạy`|Người dùng chọn bulk `Tạm dừng`|Hệ thống hiển thị confirmation tạm dừng hàng loạt|
|**SC\-04**|Xác nhận tạm dừng hàng loạt|Confirmation đang hiển thị|Người dùng bấm `Tạm dừng`|Hệ thống tạm dừng các CTKM hợp lệ, ghi lịch sử từng CTKM và hiển thị kết quả|
|**SC\-05**|Kết thúc nhiều CTKM|Các CTKM đã chọn ở trạng thái `Đang chạy` hoặc `Tạm dừng`|Người dùng chọn bulk `Kết thúc`|Hệ thống hiển thị confirmation kết thúc hàng loạt|
|**SC\-06**|Xóa nhiều bản nháp|Các CTKM đã chọn ở trạng thái `Nháp`|Người dùng chọn bulk `Xóa nháp`|Hệ thống hiển thị confirmation xóa nháp hàng loạt|
|**SC\-07**|Tập chọn có trạng thái hỗn hợp|Người dùng chọn nhiều CTKM thuộc nhiều trạng thái|Người dùng mở bulk action sheet|Hệ thống hiển thị action khả dụng kèm số lượng CTKM hợp lệ|
|**SC\-08**|Một số CTKM thất bại khi xử lý|Một phần CTKM bị đổi trạng thái hoặc lỗi hệ thống|Người dùng xác nhận bulk action|Hệ thống hiển thị partial success với số thành công/thất bại|
|**SC\-09**|Người dùng không đủ quyền|Người dùng không có quyền bulk action|Người dùng mở selection mode hoặc action sheet|Hệ thống không cho thao tác và hiển thị lý do|

#### 5\.3\.8\.7 Edge cases

|ID|Edge Case|Hướng xử lý đề xuất|
|---|---|---|
|**EC\-01**|Người dùng chọn CTKM qua nhiều filter/trang danh sách|V1 nên chỉ hỗ trợ chọn trong tập dữ liệu đang hiển thị|
|**EC\-02**|CTKM đổi trạng thái sau khi được chọn|Kiểm tra lại trạng thái trước khi submit|
|**EC\-03**|Người dùng chọn cả `Nháp`, `Đang chạy`, `Đã kết thúc`|Action sheet hiển thị số lượng hợp lệ cho từng action và bỏ qua item không hợp lệ|
|**EC\-04**|Người dùng submit bulk action nhiều lần|Disable CTA sau lần submit đầu tiên|
|**EC\-05**|Lỗi mạng giữa quá trình xử lý|Hiển thị trạng thái không chắc chắn và yêu cầu tải lại danh sách|
|**EC\-06**|Một vài CTKM không đủ quyền riêng lẻ|Đánh dấu thất bại cho các CTKM đó, không rollback toàn bộ nếu các CTKM khác thành công|
|**EC\-07**|Xóa nháp hàng loạt nhưng có bản nháp đã được người khác sửa thành `Sẵn sàng`|Bỏ qua item đó và hiển thị lý do thất bại|
|**EC\-08**|Số lượng CTKM chọn quá lớn|Cần giới hạn batch size hoặc xử lý bất đồng bộ|

#### 5\.3\.8\.8 Open questions

|ID|Question|Gợi ý|
|---|---|---|
|**OQ\-01**|Có cho chọn CTKM qua nhiều trang/filter không?|V1 nên chưa hỗ trợ để tránh sai sót|
|**OQ\-02**|Batch size tối đa là bao nhiêu?|Đề xuất giới hạn 50 CTKM/lần ở v1|
|**OQ\-03**|Bulk action nên xử lý partial success hay rollback toàn bộ?|Đề xuất partial success vì mỗi CTKM là một entity độc lập|
|**OQ\-04**|Có bắt buộc nhập lý do khi tạm dừng/kết thúc hàng loạt không?|V1 nên optional; có thể bắt buộc ở phase audit nâng cao|
|**OQ\-05**|Có cần màn hình lịch sử bulk job riêng không?|Chưa cần ở v1; chỉ cần ghi lịch sử từng CTKM|
|**OQ\-06**|`Xóa nháp` là hard delete hay soft delete?|Đề xuất soft delete để có thể audit và khôi phục nếu cần|

## 5\.4 User stories — Type\-specific promotion

|**ID**|**As user**|**I want to do**|**So that**|
|---|---|---|---|
|**US\-10**<br>|Quản lý cửa hàng / Quản trị viên|Tạo CTKM giảm giá sản phẩm|Tôi có thể giảm giá một hoặc nhiều sản phẩm cụ thể trong khoảng thời gian xác định|
|**US\-11**|Quản lý cửa hàng / Quản trị viên|Tạo CTKM giảm giá đơn hàng|Tôi có thể khuyến khích khách mua đạt điều kiện đơn hàng để được giảm giá|
|**US\-12**|Quản lý cửa hàng / Quản trị viên|Tạo CTKM mua X tặng Y|Tôi có thể thiết lập chương trình mua sản phẩm/nhóm sản phẩm này để được tặng sản phẩm/nhóm sản phẩm khác|
|**US\-13**|Quản lý cửa hàng / Quản trị viên|Tạo CTKM combo|Tôi có thể bán một bộ sản phẩm theo giá hoặc ưu đãi riêng|
|**US\-14**|Quản lý cửa hàng / Quản trị viên|Tạo CTKM giảm theo số lượng|Tôi có thể khuyến khích khách mua nhiều hơn bằng các mức ưu đãi theo bậc số lượng|
|**US\-15**|Quản lý cửa hàng / Quản trị viên|Tạo CTKM theo nhóm khách hàng|Tôi có thể áp dụng ưu đãi riêng cho một nhóm khách hàng cụ thể|
|**US\-16**|Quản lý cửa hàng / Quản trị viên|Tạo CTKM theo chi nhánh hoặc kênh bán|Tôi có thể áp dụng CTKM khác nhau theo từng điểm bán hoặc kênh bán|
|**US\-17**|Quản lý cửa hàng / Quản trị viên|Tạo CTKM bằng mã giảm giá hoặc voucher|Tôi có thể cho khách sử dụng mã ưu đãi để được hưởng khuyến mại|

# 6\. Epic EP04 — Ưu tiên \& xung đột chính sách

## 6\.1 Epic overview

Epic này xử lý tình huống **nhiều chính sách giá/khuyến mại cùng có khả năng áp dụng**\. Mục tiêu là xác định chính sách nào được ưu tiên, khi nào cần cảnh báo, và khi nào không cho bật chính sách\.

## 6\.2 User stories mapping

|ID|As user|I want to do|So that|
|---|---|---|---|
|**US\-01**|Chủ doanh nghiệp / Quản trị viên|Xác định thứ tự ưu tiên giữa các chính sách giá|Tôi có thể biết chính sách giá nào được áp dụng khi nhiều chính sách cùng hợp lệ|
|**US\-02**|Chủ doanh nghiệp / Quản trị viên|Xác định thứ tự ưu tiên giữa các CTKM|Tôi có thể kiểm soát CTKM nào được áp dụng trước khi nhiều CTKM cùng thỏa điều kiện|
|**US\-03**|Quản lý cửa hàng / Quản trị viên|Nhận cảnh báo xung đột khi tạo hoặc sửa CTKM|Tôi có thể phát hiện sớm rủi ro trước khi lưu hoặc bật chương trình|
|**US\-04**|Quản trị viên / Chủ doanh nghiệp|Nhận cảnh báo xung đột khi bật CTKM|Tôi có thể tránh đưa một CTKM có rủi ro vào bán hàng|
|**US\-05**|Quản trị viên / Chủ doanh nghiệp|Xử lý xung đột chính sách|Tôi có thể chọn cách ưu tiên, điều chỉnh hoặc dừng chính sách để hệ thống áp dụng giá đúng|
|**US\-06**|Chủ doanh nghiệp / Quản trị viên|Cấu hình rule ưu tiên áp dụng|Tôi có thể thiết lập nguyên tắc chung để hệ thống tự xác định chính sách được áp dụng|
|**US\-07**|Nhân viên bán hàng / Quản lý cửa hàng|Xem giải thích chính sách được chọn khi có nhiều chính sách hợp lệ|Tôi có thể hiểu vì sao hệ thống áp dụng một mức giá hoặc CTKM cụ thể|
|**US\-08**|Chủ doanh nghiệp / Quản trị viên|Kiểm tra tác động của rule ưu tiên trước khi áp dụng|Tôi có thể đánh giá rủi ro trước khi thay đổi cách hệ thống tính giá|

# 7\. Epic EP05 — Giá áp dụng tại bán hàng

## 7\.1 Epic overview

Epic này tập trung vào trải nghiệm tại POS/Order: hệ thống cần **áp dụng đúng giá cuối cùng** và giúp người bán hiểu giá đó đến từ đâu\.

## 7\.2 User stories

|ID|As user|I want to do|So that|
|---|---|---|---|
|**US\-01**|Nhân viên bán hàng|Xem giá áp dụng trên từng dòng hàng|Tôi có thể bán đúng giá mà hệ thống đã xác định|
|**US\-02**|Nhân viên bán hàng / Quản lý cửa hàng|Áp dụng giá riêng khi bán cho khách cụ thể|Tôi có thể đảm bảo khách được hưởng đúng giá đã thỏa thuận|
|**US\-03**|Nhân viên bán hàng|Áp dụng CTKM hợp lệ vào đơn hàng|Tôi có thể bán hàng theo đúng chương trình khuyến mại đang có hiệu lực|
|**US\-04**|Nhân viên bán hàng / Quản lý cửa hàng|Xem giải thích nguồn gốc giá áp dụng|Tôi có thể hiểu giá cuối cùng đến từ giá mặc định, giá riêng hay CTKM|
|**US\-05**|Quản lý cửa hàng / Chủ doanh nghiệp|Nhận cảnh báo khi giá bị thay đổi thủ công|Tôi có thể kiểm soát rủi ro bán sai giá hoặc giảm giá ngoài chính sách|
|**US\-06**|Quản lý cửa hàng / Quản trị viên|Cho phép ghi đè giá theo quyền|Tôi có thể xử lý ngoại lệ bán hàng nhưng vẫn kiểm soát được ai được phép thay đổi giá|
|**US\-07**|Nhân viên bán hàng|Xử lý khi CTKM hết hạn trong lúc đơn đang mở|Tôi có thể biết hệ thống nên giữ, cập nhật hay cảnh báo khi CTKM không còn hiệu lực|
|**US\-08**|Nhân viên bán hàng|Xử lý khi sản phẩm không còn đủ điều kiện CTKM|Tôi có thể tránh áp dụng sai ưu đãi cho sản phẩm không hợp lệ|
|**US\-09**|Nhân viên bán hàng / Quản lý cửa hàng|Xem tổng ưu đãi trên đơn hàng|Tôi có thể biết khách đã được giảm bao nhiêu và kiểm tra lại trước khi thanh toán|

# 8\. Epic EP06 — Lịch sử \& kiểm soát thay đổi

## 8\.1 Epic overview

Epic này giúp doanh nghiệp **truy vết thay đổi liên quan tới giá, giá riêng và CTKM**, phục vụ kiểm soát nội bộ và xử lý sai lệch khi cần\.

## 8\.2 User stories

|ID|As user|I want to do|So that|
|---|---|---|---|
|**US\-01**|Chủ doanh nghiệp / Kế toán / Người kiểm soát|Xem lịch sử thay đổi giá bán sản phẩm|Tôi có thể truy vết các thay đổi ảnh hưởng tới giá bán cơ bản|
|**US\-02**|Chủ doanh nghiệp / Kế toán / Người kiểm soát|Xem lịch sử thay đổi giá riêng|Tôi có thể kiểm tra các thay đổi liên quan tới giá đặc biệt của khách hàng|
|**US\-03**|Chủ doanh nghiệp / Kế toán / Người kiểm soát|Xem lịch sử thay đổi CTKM|Tôi có thể truy vết các thay đổi liên quan tới chương trình khuyến mại|
|**US\-04**|Chủ doanh nghiệp / Kế toán / Người kiểm soát|Xem lịch sử thao tác hàng loạt|Tôi có thể kiểm tra các thay đổi lớn được thực hiện trên nhiều chính sách cùng lúc|
|**US\-05**|Chủ doanh nghiệp / Kế toán / Người kiểm soát|Lọc lịch sử theo người thao tác|Tôi có thể kiểm tra các thay đổi do một người cụ thể thực hiện|
|**US\-06**|Chủ doanh nghiệp / Kế toán / Người kiểm soát|Lọc lịch sử theo thời gian|Tôi có thể đối soát các thay đổi trong một giai đoạn cụ thể|
|**US\-07**|Chủ doanh nghiệp / Kế toán / Người kiểm soát|Lọc lịch sử theo loại thay đổi|Tôi có thể tập trung kiểm tra các hành động quan trọng như bật, tạm dừng, sửa giá hoặc hủy|
|**US\-08**|Chủ doanh nghiệp / Kế toán / Người kiểm soát|Xem chi tiết trước/sau của một thay đổi|Tôi có thể biết chính xác dữ liệu đã thay đổi từ giá trị nào sang giá trị nào|
|**US\-09**|Quản trị viên / Quản lý cửa hàng|Nhân bản chính sách từ phiên bản cũ|Tôi có thể tái sử dụng cấu hình cũ mà không sửa trực tiếp lịch sử đã ghi nhận|
|**US\-10**|Chủ doanh nghiệp / Kế toán / Người kiểm soát|Xuất lịch sử thay đổi phục vụ kiểm tra|Tôi có thể lưu trữ hoặc gửi dữ liệu phục vụ đối soát và kiểm soát nội bộ|

# 9\. Traceability matrix

Phần này sẽ được bổ sung sau khi triển khai chi tiết từng User Story\.

Mục tiêu:

- Map **FR → Scenario → Design**

- Map **Scenario → Design**

- Kiểm tra scenario nào chưa có design

- Kiểm tra design nào chưa gắn với nghiệp vụ

- Kiểm tra FR nào chưa có acceptance coverage

# 10\. Appendix A — Design snapshots

Appendix A sẽ chứa snapshot/link thiết kế tương ứng với từng epic và user story\.

Cấu trúc dự kiến:

## A\.1 Design snapshots — EP01 Giá bán cơ bản

## A\.2 Design snapshots — EP02 Giá riêng / Nhớ giá

## A\.3 Design snapshots — EP03 Chương trình khuyến mại

## A\.4 Design snapshots — EP04 Ưu tiên \& xung đột chính sách

## A\.5 Design snapshots — EP05 Giá áp dụng tại bán hàng

## A\.6 Design snapshots — EP06 Lịch sử \& kiểm soát thay đổi

# 11\. Promotion mechanics

|**Nhóm**|**Ví dụ**|**Có nên đưa vào VET45?**|
|---|---|---|
|1\. Giảm giá trực tiếp|Giảm 5%, giảm 50\.000đ|Có, MVP|
|2\. Giá cố định / special price|Sản phẩm X chỉ còn 99\.000đ|Có|
|3\. Volume / quantity discount|Mua 10 giảm 5%, mua 20 giảm 8%|Có, rất hợp B2B|
|4\. BXGX / BOGO|Mua 1 tặng 1 cùng sản phẩm|Có, phase 2|
|5\. BXGY|Mua X tặng/giảm Y khác sản phẩm|Có, phase 2|
|6\. Gift with purchase|Mua đạt điều kiện được tặng quà|Có, phase 2|
|7\. Order threshold / goal reward|Đơn từ 2 triệu giảm 100k|Có|
|8\. Bundle / combo|Combo A\+B\+C giá ưu đãi|Có, phase 2|
|9\. Coupon / voucher code|Nhập mã KM10 để giảm 10%|Có thể để sau|
|10\. Customer segment promotion|Chỉ áp dụng cho đại lý cấp 1 / khách VIP|Có, quan trọng|
|11\. Cheapest / costliest item discount|Mua 3 món, giảm món rẻ nhất|Chưa cần MVP|
|12\. Loyalty / points / cashback|Tích điểm, hoàn tiền|Để theme sau|

# 12\. Appendix B — Glossary

Tập hợp thuật ngữ dùng trong Theme 04:

- Giá bán mặc định

- Giá bán hiện hành

- Bảng giá

- Giá riêng

- Nhớ giá

- CTKM

- Loại CTKM

- Điều kiện kích hoạt

- Phạm vi áp dụng

- Cơ chế ưu đãi

- Hiệu lực

- Giới hạn sử dụng

- Xung đột chính sách

- Ưu tiên áp dụng

- Giá áp dụng cuối cùng

- Audit log

# 13\. Appendix C — Open questions

Phần này tổng hợp các câu hỏi cần chốt ở cấp theme\.

|OQ ID|Câu hỏi|Trạng thái|
|---|---|---|
|**OQ01**|Giá riêng có luôn ưu tiên hơn CTKM không?|Open|
|**OQ02**|CTKM đang chạy được sửa những trường nào?|Open|
|**OQ03**|Có cho bật hàng loạt CTKM không?|Proposed no for v1|
|**OQ04**|Có cần bảng giá riêng như một concept độc lập không?|Open|
|**OQ05**|Voucher/mã giảm giá nên nằm trong EP03 hay tách epic riêng?|Open|
|**OQ06**|Có cho rollback chính sách giá không, hay chỉ cho nhân bản phiên bản cũ?|Proposed: chỉ nhân bản|



