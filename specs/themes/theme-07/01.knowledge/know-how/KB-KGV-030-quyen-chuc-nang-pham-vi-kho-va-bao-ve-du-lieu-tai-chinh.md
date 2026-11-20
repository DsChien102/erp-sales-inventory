---
id: KB-KGV-030-quyen-chuc-nang
type: know-how
theme: theme-07
title: quyen-chuc-nang-pham-vi-kho-va-bao-ve-du-lieu-tai-chinh
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-030-quyen-chuc-nang — quyen-chuc-nang-pham-vi-kho-va-bao-ve-du-lieu-tai-chinh

## 1. Bối cảnh

### Câu trả lời ngắn

Quyền thao tác tồn kho là giao của hai điều kiện: quyền chức năng phù hợp và phạm vi kho được cấp. Quyền xem, tạo, xác nhận và phê duyệt có thể được tách riêng, nên được xem một kho không đồng nghĩa với được thay đổi kho đó. Quyền xem số lượng cũng không mặc nhiên cho phép xem giá nhập, đơn giá chính thức, tổng giá trị ghi sổ hay adjustment; các trường tài chính cần quyền riêng. Khi người dùng thiếu quyền tài chính, giao diện che giá nhưng hệ thống vẫn dùng giá nội bộ để tính rủi ro và áp dụng kiểm soát.

### Vì sao vấn đề này quan trọng?

Dữ liệu kho vừa có chiều vật lý vừa có chiều tài chính. Nhân viên cửa hàng có thể cần biết còn bao nhiêu hàng và lô nào sắp hết hạn, nhưng không cần thấy biên lợi nhuận hoặc giá mua. Về lâu dài, quyền phê duyệt một điều chỉnh tại kho A không được mở rộng sang kho B; trong phạm vi một kho hiện tại, chiều phạm vi vẫn được lưu để không làm mất ranh giới này. Tách chức năng, phạm vi kho và dữ liệu tài chính giúp thực hiện nguyên tắc tối thiểu cần biết mà vẫn giữ tính tự động của kiểm soát rủi ro.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Không được hiểu là |
|---|---|---|
| Invariant | Điều kiện luôn phải đúng trước và sau một lần commit. | Một cảnh báo có thể bỏ qua. |
| Audit trail | Chuỗi dấu vết ai làm gì, khi nào, với căn cứ nào và kết quả gì. | Nhật ký có thể sửa để phản ánh kết quả mới. |

### Quy tắc vận hành

#### Quyền chức năng phải giao với phạm vi kho

Người dùng cần đồng thời quyền chức năng và phạm vi kho; quyền xem, tạo, xác nhận, duyệt tách riêng.
#### Dữ liệu tài chính có quyền xem riêng

Quyền xem tồn không mặc nhiên cho xem giá; giá nhập, giá chính thức, giá trị ghi sổ và adjustment cần quyền tài chính riêng.

Nhóm `FINANCIAL_RESTRICTED` tối thiểu gồm: giá mua/giá nhập và thành phần chi phí; đơn giá tồn kho chính thức và giá trị ghi sổ; giá vốn hàng bán cùng adjustment/true-up; giá vốn tham chiếu định giá, giá vốn dự kiến và dữ liệu chiết khấu mua hàng theo kỳ. Khi thiếu quyền, server phải loại hoặc che các trường này nhất quán ở API, export, event/projection và log; không được chỉ ẩn bằng CSS hoặc để dữ liệu xuất hiện trong DOM.

### Ví dụ xuyên suốt

Nhân viên N có quyền xem tồn và tạo phiếu tại WH-01, nhưng không có quyền xác nhận hay xem tài chính. N nhìn thấy sản phẩm P còn 20 đơn vị, trạng thái và lô, nhưng các cột giá nhập, đơn giá chính thức và tổng giá trị được che. N có thể lập một adjustment Nháp cho WH-01 nhưng không thể xác nhận hoặc duyệt. Khi gửi duyệt, hệ thống vẫn dùng đơn giá chính thức nội bộ để tính giá trị rủi ro và chọn cấp duyệt, dù N không thấy con số đó. N không xem hoặc tạo phiếu tại WH-02 vì kho này nằm ngoài phạm vi được cấp.

Ví dụ này chỉ minh họa cách áp dụng các quy tắc đã nêu. Con số, tên sản phẩm và thời điểm là giả định; chúng không tạo thêm một ngoại lệ, quyền phê duyệt hay mốc ghi nhận mới.

### Ngoại lệ và những cách làm sai

- **Cấp quyền xem kho rồi cho phép mọi thao tác:** Xem, tạo, xác nhận và duyệt là các quyền chức năng độc lập.
- **Hiển thị giá cho mọi người xem số lượng:** Dữ liệu tài chính cần quyền riêng và phải được che ở mọi màn hình/export khi thiếu quyền.
- **Bỏ tính rủi ro khi người lập không được xem giá:** Che hiển thị không làm mất dữ liệu nội bộ; hệ thống vẫn phải áp dụng ngưỡng đúng.

- **Sửa trực tiếp số dư hoặc trạng thái để “làm cho đúng”:** cách này phá vỡ sổ biến động và làm mất khả năng giải thích số liệu. Mọi thay đổi chính thức phải đi qua đúng loại nghiệp vụ, có căn cứ và lịch sử.
- **Dùng dữ liệu tra cứu chậm làm căn cứ commit:** báo cáo hoặc projection có thể hữu ích để quan sát, nhưng quyết định thay đổi tồn phải kiểm tra lại dữ liệu giao dịch hiện hành.

## 3. Ý nghĩa đối với Theme

### Cách áp dụng trong thực tế

Kiểm soát được áp dụng tại thời điểm ra quyết định, không chỉ tại lúc tạo hồ sơ. Hệ thống phải kiểm tra quyền, phạm vi, điều kiện hiện hành và xung đột đồng thời trước khi commit. Nếu không chứng minh được điều kiện an toàn thì dừng, giữ dấu vết và chuyển sang đường đối soát hoặc sửa sai được quy định.

Khi triển khai một trường hợp cụ thể, người xử lý nên ghi rõ nguồn chứng từ, đối tượng hàng, kho, trạng thái, thời điểm nghiệp vụ và kết quả mong đợi. Nếu một dữ kiện thuộc thẩm quyền của hệ thống khác chưa có, hồ sơ phải dừng ở trạng thái an toàn thay vì tự suy đoán. Nếu một bước có thể ảnh hưởng đồng thời đến nhiều số dư hoặc cả số lượng lẫn giá trị, toàn bộ thay đổi phải được commit nguyên tử và để lại dấu vết đối soát.

### Điều cần ghi nhớ

- **Muốn thao tác phải đồng thời có quyền chức năng và phạm vi kho.**
- **Xem, tạo, xác nhận và phê duyệt có thể được cấp tách biệt.**
- **Quyền xem tồn không bao gồm quyền xem giá trị tài chính.**
- **Việc che giá không làm thay đổi phép tính rủi ro tự động.**

- **Khi không đủ bằng chứng để đi tiếp, hệ thống phải thất bại an toàn và giữ nguyên dữ liệu có thẩm quyền.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-030` |
| Cụm tri thức | [`KGV-C08`](00-table-of-contents.md#c08-quyền-phê-duyệt-sổ-và-báo-cáo) |
| Loại bài | `CONTROL` |
| Quyết định chính | [`T7-DR-079`](../decisions/decision-register.md#311-g11-quy%E1%BB%81n-ph%C3%AA-duy%E1%BB%87t-v%C3%A0-b%E1%BA%A3o-v%E1%BB%87-d%E1%BB%AF-li%E1%BB%87u), [`T7-DR-083`](../decisions/decision-register.md#311-g11-quy%E1%BB%81n-ph%C3%AA-duy%E1%BB%87t-v%C3%A0-b%E1%BA%A3o-v%E1%BB%87-d%E1%BB%AF-li%E1%BB%87u), [`T7-DR-083`](../decisions/decision-register.md#311-g11-quy%E1%BB%81n-ph%C3%AA-duy%E1%BB%87t-v%C3%A0-b%E1%BA%A3o-v%E1%BB%87-d%E1%BB%AF-li%E1%BB%87u) |
| Trạng thái quyết định | `ACTIVE` |
| Mức bằng chứng của bài | `STATIC_VALIDATED` |
| Giới hạn | Bài giải thích mô hình quyền; không định nghĩa vai trò tổ chức cụ thể, cách cấp quyền trên giao diện hoặc ma trận quyền của hệ thống kế toán |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-031` — Phê duyệt Inventory Operation theo mức rủi ro](KB-KGV-031-phe-duyet-inventory-operation-theo-muc-rui-ro.md)
- [`KB-KGV-033` — Thẻ kho, báo cáo lịch sử và đối soát nguồn](KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon.md)
- [`KB-KGV-038` — Chỉ báo dẫn xuất và hồ sơ cần xử lý](KB-KGV-038-canh-bao-ton-kho-va-vong-doi-xu-ly.md)
