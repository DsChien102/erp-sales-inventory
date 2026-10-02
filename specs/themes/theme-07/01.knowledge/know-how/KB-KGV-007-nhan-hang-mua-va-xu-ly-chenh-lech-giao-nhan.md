---
id: KB-KGV-007-nhan-hang-mua-va-xu-ly-chenh-lech-giao-nhan
type: know-how
theme: theme-07
title: nhan-hang-mua-va-xu-ly-chenh-lech-giao-nhan
owner: BA
status: FROZEN
source_baseline: v3.12.0
---
# KB-KGV-007-nhan-hang-mua-va-xu-ly-chenh-lech-giao-nhan — nhan-hang-mua-va-xu-ly-chenh-lech-giao-nhan

## 1. Bối cảnh

### Câu trả lời ngắn

Nhập mua chỉ tăng tồn vật lý khi thủ kho xác nhận lượng thực nhận và operation nhận hàng hoàn tất. Có thể nhận từng phần, ghi nhận thiếu hoặc thừa so với đơn mua; phần thừa của luồng theo chứng từ vượt ngưỡng phải đi qua phê duyệt. **Mọi yêu cầu nhập hàng nhanh đều bắt buộc được phê duyệt**, không phụ thuộc giá trị đang dưới hay trên ngưỡng. Phạm vi hiện tại không có bước kiểm tra chất lượng nhập riêng: xác nhận của thủ kho là căn cứ nhận hàng. Lượng bị từ chối không tạo tồn kho hay movement và phải được chứng từ nguồn lưu để đối soát.

### Vì sao vấn đề này quan trọng?

Đơn mua thể hiện kỳ vọng, còn kho phải phản ánh hàng thực tế đã được tiếp nhận. Nếu nhập theo số đặt mua, kho có thể ghi nhận cả hàng chưa đến hoặc hàng bị từ chối. Ngược lại, bỏ qua số thiếu, số thừa và các lần giao từng phần sẽ làm mất khả năng đối chiếu với nhà cung cấp. Tách rõ kỳ vọng, thực nhận đạt và lượng bị từ chối giúp số dư vật lý trung thực mà vẫn giữ đầy đủ bằng chứng giao nhận ở đúng hệ thống sở hữu chứng từ.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Không được hiểu là |
|---|---|---|
| Mốc nghiệp vụ | Sự kiện được người có trách nhiệm xác nhận và có ý nghĩa rõ ràng. | Một thao tác giao diện chưa hoàn tất. |
| Hoàn tất nguyên tử | Toàn bộ thay đổi liên quan cùng thành công hoặc cùng được hoàn tác. | Cho phép một vài dòng ảnh hưởng tồn trước. |

### Quy tắc vận hành

#### Mốc tăng tồn vật lý

Nhập mua tăng tồn vật lý khi thủ kho xác nhận lượng thực nhận và operation nhận hàng hoàn tất.

Kết quả nhận hàng luôn đưa lượng đạt vào `VALUATION_PENDING`, kể cả khi chứng từ nhận đã mang theo giá dự kiến hoặc bằng chứng giá. Nhận hàng và xác lập giá trị nhập ban đầu là hai nghiệp vụ riêng: nghiệp vụ đầu chịu trách nhiệm cho sự thật vật lý; BJ03 mới có quyền ghi giá trị nhập ban đầu và chuyển trục định giá khỏi `VALUATION_PENDING`. Khả dụng chỉ được đánh giá lại cho lượng đồng thời đủ điều kiện bán.
#### Nhận từng phần và kiểm soát thừa thiếu

Cho phép nhận từng phần; ghi nhận thiếu/thừa so với đơn mua; phần vượt ngưỡng phải được phê duyệt.

#### Nhập hàng nhanh luôn phải được phê duyệt

Nhập hàng nhanh chỉ rút gọn việc chọn chứng từ nguồn; không rút gọn kiểm soát. Khi đủ dữ kiện bắt buộc để gửi, hồ sơ luôn chuyển sang `PENDING_APPROVAL`; hệ thống không hỏi “có cần duyệt không” và không có nhánh đi thẳng `READY`. Chỉ sau một quyết định phê duyệt hợp lệ hồ sơ mới được phép tiếp tục ghi nhận tồn vật lý. Nếu còn thiếu căn cứ nguồn, quyền sở hữu hoặc người duyệt đủ điều kiện, lệnh gửi bị từ chối và không tạo receipt; người dùng chỉ có thể bổ sung dữ liệu còn thiếu trong phiên Quick hiện tại rồi gửi lại. Căn cứ giá của BJ03 là nghiệp vụ định giá riêng sau khi nhận hàng đã hoàn tất. Từ chối không tạo movement; luồng phê duyệt BJ-02 chỉ có Duyệt hoặc Từ chối.

#### Một receipt, một nhà cung cấp và nhiều mục hàng

Một receipt mua gắn đúng **một Supplier**. Một Supplier có thể có nhiều receipt khác nhau; quy tắc này chỉ cấm trộn hàng của nhiều Supplier vào cùng một receipt. Receipt có thể chứa nhiều sản phẩm. Supplier và Product phải tồn tại trước khi nhận hàng; BJ-02 không tạo master data mới trong lúc nhận.

Ở mức nghiệp vụ/UI, mỗi **mục hàng** gồm một Product và một đơn vị giao dịch. Nhận theo chứng từ dùng UOM của source. Nhập hàng nhanh dùng UOM hợp lệ của Product; nếu cùng Product được giao theo hai UOM, ví dụ hộp và lọ, chúng là hai mục riêng. Trong Quick receipt không tạo hai mục trùng cùng Product + cùng UOM.

Một mục hàng có thể chứa nhiều lô hoặc nhiều tình trạng thực nhận. Khi persist, mục này có thể materialize thành nhiều `InventoryOperationLine` kỹ thuật theo lot/state; các line vẫn phải truy được về cùng receipt-item reference.

#### Xử lý đủ các sản phẩm trên chứng từ

Khi chọn một chứng từ có nhiều sản phẩm, receipt draft phải nạp đủ các source items thuộc phạm vi nhận. Người dùng xử lý từng mục. Nếu một mục chưa được giao trong chuyến này, có thể xác nhận **Chưa nhận lần này**: actual quantity bằng 0 và phần còn lại của source không bị giảm. `Chưa nhận lần này` khác `Chưa ghi nhận`: trạng thái đầu là user đã xử lý mục, trạng thái sau là task còn bỏ dở.

#### Số lượng, tình trạng và lô

Với trường hợp thông thường, người dùng nhập tổng số lượng thực nhận và hệ thống mặc định toàn bộ là hàng đạt. Chỉ khi có ngoại lệ mới cần tách Cách ly, Hỏng hoặc Từ chối nhận; tổng các ngoại lệ không được vượt tổng thực nhận. Từ chối nhận không tăng tồn vật lý.

Tracking policy thuộc Product. Product `NONE` không yêu cầu lô. Product `LOT` bắt buộc mã lô; hạn dùng bắt buộc khi `expiry_required=true`, còn nếu false thì có thể ghi khi biết; ngày sản xuất là optional. Một mục hàng `LOT` có thể gồm nhiều lô.

#### Căn cứ xác nhận hàng đạt

Phạm vi hiện tại không có bước kiểm tra chất lượng nhập hàng riêng; xác nhận của thủ kho là căn cứ nghiệp vụ nhận hàng.
#### Lượng bị từ chối không tạo movement

Khi giao hàng có lượng đạt và không đạt, Hệ thống quản lý tồn kho và giá vốn chỉ ghi nhận lượng đạt; lượng bị từ chối không tạo tồn kho hoặc movement. Chứng từ nguồn chịu trách nhiệm lưu lượng từ chối và chênh lệch giao nhận để đối soát.

### Ví dụ xuyên suốt

Đơn mua có 100 hộp. Lần giao đầu, thủ kho kiểm tra thấy 92 hộp đạt, 3 hộp móp không nhận và 5 hộp chưa giao. Operation nhận hàng chỉ chứa 92 hộp đạt; khi hoàn tất, tồn vật lý tăng 92. Chứng từ mua ghi nhận đã giao 95, nhận đạt 92, từ chối 3 và còn thiếu 5 để đối soát. Nếu lần sau nhà cung cấp giao 10 hộp, tổng thực nhận có thể vượt đơn mua; phần vượt ngưỡng cấu hình phải được phê duyệt trước khi operation có thể hoàn tất. Nếu hàng đến mà chưa có chứng từ nguồn và người dùng chọn nhập hàng nhanh, hồ sơ cũng phải qua phê duyệt dù giá trị dưới ngưỡng. Không một hộp bị từ chối nào được đưa vào trạng thái hỏng của kho vì kho chưa nhận quyền quản lý chúng.

Ví dụ này chỉ minh họa cách áp dụng các quy tắc đã nêu. Con số, tên sản phẩm và thời điểm là giả định; chúng không tạo thêm một ngoại lệ, quyền phê duyệt hay mốc ghi nhận mới.

### Ngoại lệ và những cách làm sai

- **Nhập theo số lượng trên đơn mua:** Đơn mua là kỳ vọng; số dư chỉ tăng theo lượng đạt được thủ kho xác nhận thực nhận.
- **Đưa hàng từ chối vào tồn hỏng:** Lượng chưa được tiếp nhận không thuộc tồn vật lý và không được tạo movement.
- **Tự bỏ qua phần thừa:** Phần vượt ngưỡng phải dừng để phê duyệt, không được hợp thức hóa bằng sửa dòng đơn mua sau đó.
- **Cho nhập hàng nhanh đi thẳng thực thi vì giá trị nhỏ:** Nhập hàng nhanh luôn phải chờ một quyết định phê duyệt hợp lệ.
- **Tạo nhanh Product/Supplier để đi tiếp:** Master data phải được chuẩn bị ở domain sở hữu trước khi receipt tiếp tục.
- **Bỏ sót sản phẩm trên chứng từ:** Chọn source phải nạp đủ các mục cần nhận; mục chưa giao phải được xác nhận `Chưa nhận lần này`, không được biến mất khỏi task.
- **Gộp hai UOM thành một số lượng:** Mỗi mục hàng dùng một transaction UOM; cùng Product nhưng UOM khác phải giữ thành các mục riêng.

- **Sửa trực tiếp số dư hoặc trạng thái để “làm cho đúng”:** cách này phá vỡ sổ biến động và làm mất khả năng giải thích số liệu. Mọi thay đổi chính thức phải đi qua đúng loại nghiệp vụ, có căn cứ và lịch sử.
- **Dùng dữ liệu tra cứu chậm làm căn cứ commit:** báo cáo hoặc projection có thể hữu ích để quan sát, nhưng quyết định thay đổi tồn phải kiểm tra lại dữ liệu giao dịch hiện hành.

## 3. Ý nghĩa đối với Theme

### Cách áp dụng trong thực tế

Mỗi quy trình phải làm rõ bốn mốc: điều kiện vào, hành động xác nhận, thời điểm thay đổi chính thức và nhánh thất bại an toàn. Các bước chuẩn bị có thể thay đổi trạng thái công việc, nhưng chỉ mốc hoàn tất được quy định mới làm thay đổi số lượng hoặc giá trị có thẩm quyền.

Khi triển khai một trường hợp cụ thể, người xử lý nên ghi rõ nguồn chứng từ, đối tượng hàng, kho, trạng thái, thời điểm nghiệp vụ và kết quả mong đợi. Nếu một dữ kiện thuộc thẩm quyền của hệ thống khác chưa có, hồ sơ phải dừng ở trạng thái an toàn thay vì tự suy đoán. Nếu một bước có thể ảnh hưởng đồng thời đến nhiều số dư hoặc cả số lượng lẫn giá trị, toàn bộ thay đổi phải được commit nguyên tử và để lại dấu vết đối soát.

### Điều cần ghi nhớ

- **Thủ kho xác nhận thực nhận là mốc nghiệp vụ đầu vào.**
- **Operation hoàn tất mới làm tăng tồn vật lý.**
- **Nhận từng phần và chênh lệch thiếu/thừa phải được ghi nhận.**
- **Nhập hàng nhanh luôn vào Chờ phê duyệt trước khi có thể ghi tồn vật lý.**
- **Lượng bị từ chối thuộc hồ sơ giao nhận của nguồn, không thuộc sổ kho.**
- **Một receipt chỉ thuộc một Supplier nhưng có thể có nhiều sản phẩm/mục hàng.**
- **Supplier/Product chưa có thì chuẩn bị master trước; BJ-02 không tạo mới.**
- **Mỗi mục dùng một UOM; cùng Product khác UOM là các mục riêng.**

- **Khi không đủ bằng chứng để đi tiếp, hệ thống phải thất bại an toàn và giữ nguyên dữ liệu có thẩm quyền.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-007` |
| Cụm tri thức | [`KGV-C02`](00-table-of-contents.md#c02-nhận-giữ-và-xuất-hàng) |
| Loại bài | `PROCESS` |
| Quyết định chính | [`T7-DR-020`](../decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B), [`T7-DR-022`](../decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B), [`T7-DR-023`](../decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B), [`T7-DR-024`](../decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B), [`T7-DR-020#REQ-01`](../decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B), [`T7-DR-027`](../decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BB%8B), [`T7-DR-103`](../decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B), [`T7-DR-104`](../decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B), [`T7-DR-105`](../decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B) |
| Trạng thái quyết định | `ACTIVE` |
| Mức bằng chứng của bài | `STATIC_VALIDATED` |
| Giới hạn | Bài nói về số lượng và giao nhận; việc xác lập giá trị nhập ban đầu, điều kiện khả dụng và dữ liệu lô được giải thích ở các bài liên quan |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-004` — Đơn vị tính và cách quy đổi số lượng tồn kho](KB-KGV-004-don-vi-tinh-va-cach-quy-doi-so-luong-ton-kho.md)
- [`KB-KGV-008` — Hàng đã nhận nhưng chưa chốt giá và điều kiện đưa vào bán](KB-KGV-008-hang-da-nhan-nhung-chua-chot-gia.md)
- [`KB-KGV-024` — Chọn quản lý thông thường hay quản lý theo lô](KB-KGV-024-chinh-sach-quan-ly-hang-thong-thuong-theo-lo-hoac-theo-serial.md)
