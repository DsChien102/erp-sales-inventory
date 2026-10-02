---
id: KB-KGV-031-phe-duyet-inventory-operation-theo-muc-rui-ro
type: know-how
theme: theme-07
title: phe-duyet-inventory-operation-theo-muc-rui-ro
owner: BA
status: FROZEN
source_baseline: v4.6.7
---
# KB-KGV-031-phe-duyet-inventory-operation-theo-muc-rui-ro — phe-duyet-inventory-operation-theo-muc-rui-ro

## 1. Bối cảnh

### Câu trả lời ngắn

Chính sách phê duyệt được quản lý tập trung theo loại operation, lý do và mức rủi ro; đơn vị vận hành cấu hình ngưỡng/cấp và phiên bản chính sách được chụp khi gửi. Giá trị rủi ro của hồ sơ nhiều dòng bằng tổng trị tuyệt đối giá trị từng dòng sau quy đổi VND, không bù trừ dòng tăng và giảm. Mỗi dòng ưu tiên đơn giá chính thức, nếu chưa có thì dùng giá nguồn có phiên bản. Với operation có draft lifecycle **và được định tuyến theo giá trị rủi ro**, thiếu căn cứ giá/tỷ giá có thể giữ operation ở `DRAFT`. **Nhập hàng nhanh là ngoại lệ:** BJ02 bắt buộc duyệt nhưng không dùng price/FX basis làm điều kiện submit; khi Supplier/items/evidence/ownership hợp lệ và có approver phù hợp, receipt được tạo ở `PENDING_APPROVAL` dù căn cứ giá chưa được xác lập. Giá/tỷ giá được xử lý ở chuỗi định giá phía sau. Tại lúc quyết định, người duyệt phải còn quyền, phạm vi kho, cấp phù hợp và khác người lập. Mỗi operation chỉ cần một người đáp ứng cấp cao nhất suy ra, không duyệt tuần tự qua cấp thấp. Phê duyệt không giữ tồn; điều kiện phải được kiểm tra lại khi thực thi.

### Vì sao vấn đề này quan trọng?

Phê duyệt kiểm soát thẩm quyền chấp nhận rủi ro, không bảo đảm tồn kho vẫn còn hay dữ liệu vẫn hợp lệ. Nếu tuyến duyệt được tính lại theo giá thay đổi, cùng một hồ sơ có thể nhảy cấp giữa chừng; nếu người từng được giao vẫn duyệt sau khi mất quyền, kiểm soát truy cập bị vô hiệu. Thiếu căn cứ giá cũng không thể được che bằng nhãn UNKNOWN hay tự đẩy lên cấp cao nhất, vì không ai biết rủi ro thật. Snapshot chính sách và tái kiểm tra tại thời điểm duyệt/thực thi giữ hai lớp kiểm soát độc lập.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Không được hiểu là |
|---|---|---|
| Invariant | Điều kiện luôn phải đúng trước và sau một lần commit. | Một cảnh báo có thể bỏ qua. |
| Audit trail | Chuỗi dấu vết ai làm gì, khi nào, với căn cứ nào và kết quả gì. | Nhật ký có thể sửa để phản ánh kết quả mới. |

### Quy tắc vận hành

#### Chính sách tập trung và snapshot lúc gửi

Hệ thống quản lý tồn kho và giá vốn sở hữu chính sách duyệt theo loại operation, lý do và rủi ro; đơn vị vận hành cấu hình ngưỡng/cấp và chụp phiên bản lúc gửi.
#### Công thức giá trị rủi ro và nhánh thiếu căn cứ giá

Ngưỡng duyệt `Σ |base_quantity_i × price_basis_i × fx_to_vnd_i|` chỉ áp cho operation mà ApprovalPolicy định tuyến theo giá trị. Mỗi dòng ưu tiên đơn giá chính thức tại lúc gửi; nếu chưa có thì dùng giá nguồn. Không bù trừ giá trị dòng tăng với dòng giảm. **Quick Receipt không đi qua guard này tại BJ02**: không yêu cầu price/FX, không sinh `APPROVAL_PRICE_BASIS_REQUIRED`, và không tạo `risk_value = UNKNOWN`; yêu cầu được route theo chính sách phê duyệt bắt buộc dành cho Quick Receipt. Nếu không có approver hợp lệ thì trả `APPROVER_CONFIGURATION_MISSING`.

#### Nhập hàng nhanh không có nhánh bỏ qua phê duyệt

Nhập hàng nhanh đủ điều kiện gửi luôn được **tạo mới trực tiếp ở `PENDING_APPROVAL`**; giao diện không hỏi “có cần duyệt không” và không cung cấp nhánh đi thẳng `READY`. Tại BJ02, Quick Receipt dùng policy phê duyệt bắt buộc riêng, **không dùng ngưỡng tiền/price-FX basis để quyết định có được tạo receipt hay không**. Trước submit không có receipt `DRAFT`; chỉ thiếu dữ kiện BJ02 bắt buộc hoặc thiếu approver phù hợp mới làm create-and-submit bị từ chối.
#### Điều kiện của người duyệt tại đúng thời điểm

Tại lúc duyệt, người duyệt phải còn quyền, phạm vi kho và cấp phù hợp, đồng thời không phải người lập.
#### Một quyết định ở cấp cao nhất được suy ra

Tuy chính sách có nhiều cấp ngưỡng rủi ro, mỗi operation chỉ cần một quyết định của người đáp ứng cấp cao nhất được suy ra cho operation đó; không có chuỗi duyệt tuần tự qua các cấp thấp hơn.
#### Từ chối duyệt là kết quả cuối

Từ chối duyệt yêu cầu lý do, là trạng thái cuối và không ảnh hưởng tồn; muốn sửa phải tạo operation mới có liên kết.
#### Không có người đủ điều kiện là lỗi cấu hình

Khi gửi phải có ít nhất một người đủ điều kiện; thiếu thì chặn vì lỗi cấu hình. Mất quyền sau đó không hạ cấp/bỏ qua duyệt.
#### Phê duyệt không giữ tồn và không thay thế kiểm tra thực thi

Phê duyệt chỉ cho phép thực thi, không giữ hay thay đổi tồn; khi xử lý phải kiểm tra lại mọi điều kiện hiện hành.
#### Quyết định hợp lệ commit đầu tiên thắng

Hai quyết định đồng thời: quyết định hợp lệ commit đầu tiên thắng nguyên tử; yêu cầu sau không ghi đè.

### Ví dụ xuyên suốt

Adjustment giảm 50 đơn vị P được gửi khi đơn giá chính thức là 120.000 đồng, nên giá trị rủi ro chụp lại là 6 triệu đồng. Chính sách hiệu lực yêu cầu cấp L2 và hệ thống xác nhận có ít nhất một người L2 đúng phạm vi kho. Một người L1 không cần duyệt trước; người L2 đủ điều kiện và khác người lập có thể quyết định. Nếu giá thay đổi sau đó, tuyến của hồ sơ không đổi. Hai người đồng thời bấm duyệt và từ chối: quyết định hợp lệ commit trước xác lập trạng thái cuối, yêu cầu sau chỉ nhận kết quả. Dù đã duyệt, lúc thực thi hệ thống kiểm tra lại tồn, khóa kiểm kê và trạng thái; điều kiện không đạt thì Từ chối thực thi mà không thay đổi số dư.

Ví dụ này chỉ minh họa cách áp dụng các quy tắc đã nêu. Con số, tên sản phẩm và thời điểm là giả định; chúng không tạo thêm một ngoại lệ, quyền phê duyệt hay mốc ghi nhận mới.

Với nhập hàng nhanh, hồ sơ luôn phải chờ người đủ điều kiện quyết định. Ở BJ02, việc chọn approver/cấp duyệt của Quick phải dựa trên policy dành cho Quick Receipt và **không yêu cầu price/FX basis**; bước phê duyệt không biến mất.

### Ngoại lệ và những cách làm sai

- **Thiếu giá thì chặn Nhập hàng nhanh:** Sai. Quick Receipt tại BJ02 không dùng price/FX làm điều kiện gửi; không sinh `APPROVAL_PRICE_BASIS_REQUIRED`. Price/FX thuộc chuỗi định giá phía sau. Với operation risk-based khác, thiếu căn cứ vẫn phải xử lý theo lifecycle/guard của operation đó.
- **Duyệt tuần tự qua mọi cấp:** Mỗi hồ sơ chỉ cần một quyết định của người đáp ứng cấp cao nhất đã suy ra.
- **Coi phê duyệt là giữ hàng:** Phê duyệt chỉ cấp phép thực thi; không thay đổi hoặc bảo đảm số dư.
- **Cho nhập hàng nhanh dưới ngưỡng đi thẳng `READY`:** Sai; nhập hàng nhanh luôn chờ phê duyệt sau khi đủ dữ kiện gửi.

- **Sửa trực tiếp số dư hoặc trạng thái để “làm cho đúng”:** cách này phá vỡ sổ biến động và làm mất khả năng giải thích số liệu. Mọi thay đổi chính thức phải đi qua đúng loại nghiệp vụ, có căn cứ và lịch sử.
- **Dùng dữ liệu tra cứu chậm làm căn cứ commit:** báo cáo hoặc projection có thể hữu ích để quan sát, nhưng quyết định thay đổi tồn phải kiểm tra lại dữ liệu giao dịch hiện hành.

## 3. Ý nghĩa đối với Theme

### Cách áp dụng trong thực tế

Kiểm soát được áp dụng tại thời điểm ra quyết định, không chỉ tại lúc tạo hồ sơ. Hệ thống phải kiểm tra quyền, phạm vi, điều kiện hiện hành và xung đột đồng thời trước khi commit. Nếu không chứng minh được điều kiện an toàn thì dừng, giữ dấu vết và chuyển sang đường đối soát hoặc sửa sai được quy định.

Khi triển khai một trường hợp cụ thể, người xử lý nên ghi rõ nguồn chứng từ, đối tượng hàng, kho, trạng thái, thời điểm nghiệp vụ và kết quả mong đợi. Nếu một dữ kiện thuộc thẩm quyền của hệ thống khác chưa có, hồ sơ phải dừng ở trạng thái an toàn thay vì tự suy đoán. Nếu một bước có thể ảnh hưởng đồng thời đến nhiều số dư hoặc cả số lượng lẫn giá trị, toàn bộ thay đổi phải được commit nguyên tử và để lại dấu vết đối soát.

### Điều cần ghi nhớ

- **Operation risk-based snapshot policy và giá trị rủi ro khi gửi; Quick Receipt chỉ snapshot policy/evidence/ownership cần cho quyết định BJ02.**
- **Thiếu price/FX không chặn Quick Receipt; với operation risk-based khác, thiếu căn cứ xử lý theo lifecycle/guard tương ứng.**
- **Người duyệt phải đủ điều kiện tại lúc quyết định và không phải người lập.**
- **Từ chối duyệt là final; thực thi vẫn phải kiểm tra lại điều kiện hiện hành.**
- **Nhập hàng nhanh luôn cần phê duyệt; tại BJ02, policy Quick Receipt không phụ thuộc price/FX basis.**

- **Khi không đủ bằng chứng để đi tiếp, hệ thống phải thất bại an toàn và giữ nguyên dữ liệu có thẩm quyền.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-031` |
| Cụm tri thức | [`KGV-C08`](00-table-of-contents.md#c08-quyền-phê-duyệt-sổ-và-báo-cáo) |
| Loại bài | `CONTROL` |
| Quyết định chính | [`T7-DR-078`](../decisions/decision-register.md#311-g11-quy%E1%BB%81n-ph%C3%AA-duy%E1%BB%87t-v%C3%A0-b%E1%BA%A3o-v%E1%BB%87-d%E1%BB%AF-li%E1%BB%87u), [`T7-DR-080`](../decisions/decision-register.md#311-g11-quy%E1%BB%81n-ph%C3%AA-duy%E1%BB%87t-v%C3%A0-b%E1%BA%A3o-v%E1%BB%87-d%E1%BB%AF-li%E1%BB%87u), [`T7-DR-081`](../decisions/decision-register.md#311-g11-quy%E1%BB%81n-ph%C3%AA-duy%E1%BB%87t-v%C3%A0-b%E1%BA%A3o-v%E1%BB%87-d%E1%BB%AF-li%E1%BB%87u), [`T7-DR-081#REQ-01`](../decisions/decision-register.md#311-g11-quy%E1%BB%81n-ph%C3%AA-duy%E1%BB%87t-v%C3%A0-b%E1%BA%A3o-v%E1%BB%87-d%E1%BB%AF-li%E1%BB%87u), [`T7-DR-082`](../decisions/decision-register.md#311-g11-quy%E1%BB%81n-ph%C3%AA-duy%E1%BB%87t-v%C3%A0-b%E1%BA%A3o-v%E1%BB%87-d%E1%BB%AF-li%E1%BB%87u), [`T7-DR-081#REQ-02`](../decisions/decision-register.md#311-g11-quy%E1%BB%81n-ph%C3%AA-duy%E1%BB%87t-v%C3%A0-b%E1%BA%A3o-v%E1%BB%87-d%E1%BB%AF-li%E1%BB%87u), [`T7-DR-082#REQ-01`](../decisions/decision-register.md#311-g11-quy%E1%BB%81n-ph%C3%AA-duy%E1%BB%87t-v%C3%A0-b%E1%BA%A3o-v%E1%BB%87-d%E1%BB%AF-li%E1%BB%87u), [`T7-DR-082#REQ-02`](../decisions/decision-register.md#311-g11-quy%E1%BB%81n-ph%C3%AA-duy%E1%BB%87t-v%C3%A0-b%E1%BA%A3o-v%E1%BB%87-d%E1%BB%AF-li%E1%BB%87u), [`T7-DR-080`](../decisions/decision-register.md#311-g11-quy%E1%BB%81n-ph%C3%AA-duy%E1%BB%87t-v%C3%A0-b%E1%BA%A3o-v%E1%BB%87-d%E1%BB%AF-li%E1%BB%87u), [`T7-DR-083`](../decisions/decision-register.md#311-g11-quy%E1%BB%81n-ph%C3%AA-duy%E1%BB%87t-v%C3%A0-b%E1%BA%A3o-v%E1%BB%87-d%E1%BB%AF-li%E1%BB%87u), [`T7-DR-027`](../decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B) |
| Trạng thái quyết định | `ACTIVE` |
| Mức bằng chứng của bài | `STATIC_VALIDATED` |
| Giới hạn | Bài mô tả logic phê duyệt; không đặt con số ngưỡng, danh sách vai trò hay SLA phê duyệt cụ thể cho từng đơn vị vận hành |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-011` — Kiểm kê hàng tồn kho từ khóa phạm vi đến điều chỉnh chênh lệch](KB-KGV-011-kiem-ke-hang-ton-kho-tu-khoa-pham-vi-den-dieu-chinh-chenh-lech.md)
- [`KB-KGV-021` — Sửa sai tồn kho mà không sửa lịch sử](KB-KGV-021-sua-sai-ton-kho-khong-sua-lich-su.md)
- [`KB-KGV-027` — Vòng đời của một Inventory Operation](KB-KGV-027-vong-doi-cua-mot-inventory-operation.md)
- [`KB-KGV-030` — Quyền chức năng, phạm vi kho và bảo vệ dữ liệu tài chính](KB-KGV-030-quyen-chuc-nang-pham-vi-kho-va-bao-ve-du-lieu-tai-chinh.md)
