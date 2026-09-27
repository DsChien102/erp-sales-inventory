---
id: KB-KGV-036-ton-du-kien-va-de-xuat-bo-sung-hang
type: know-how
theme: theme-07
title: ton-du-kien-va-de-xuat-bo-sung-hang
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-036-ton-du-kien-va-de-xuat-bo-sung-hang — ton-du-kien-va-de-xuat-bo-sung-hang

## 1. Bối cảnh

### Câu trả lời ngắn

Mỗi sản phẩm có hai tham số: **ngưỡng cảnh báo tồn thấp** (`low_stock_threshold`) và **mức tồn mục tiêu** (`target_stock_level`). Khi tồn khả dụng hiện hành nhỏ hơn hoặc bằng ngưỡng, hệ thống hiển thị trạng thái sắp hết hoặc hết hàng và tính:

`suggested_quantity = max(0, target_stock_level − available_quantity)`

Kết quả chỉ là dữ liệu dẫn xuất tại thời điểm xem. Nó không tạo đề xuất có mã, không có vòng đời, không tự tạo đơn mua và chưa xét hàng sắp về, nhu cầu tương lai, tốc độ bán, MOQ, bội số đóng gói hay thời gian giao hàng.

### Vì sao vấn đề này quan trọng?

Chủ cửa hàng cần một danh sách hành động đơn giản hơn là một hệ thống dự báo. Hai tham số và một công thức minh bạch giải quyết phần giá trị cốt lõi: nhìn ra mặt hàng sắp hết và biết khoảng cách đến mức muốn có. Việc chưa tạo workflow mua hàng giúp giảm đáng kể entity, trạng thái, tích hợp và kiểm thử trong giai đoạn đầu.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Ví dụ |
|---|---|---|
| Tồn khả dụng | Lượng đủ điều kiện bán trừ lượng đã giữ | 8 |
| Ngưỡng cảnh báo tồn thấp | Mốc kích hoạt chỉ báo | 10 |
| Mức tồn mục tiêu | Lượng mong muốn đạt sau khi bổ sung | 30 |
| Lượng gợi ý | Khoảng cách từ khả dụng đến mục tiêu | 22 |
| Dự báo bổ sung | Mô hình xét nhu cầu, hàng về, lead time… | Chưa thuộc phạm vi |

### Quy tắc vận hành

1. Cấu hình tối thiểu có `low_stock_threshold` và `target_stock_level`, tính theo đơn vị cơ sở.
2. Khi `available_quantity = 0`, trạng thái là hết hàng; khi `0 < available ≤ threshold`, trạng thái là sắp hết.
3. Lượng gợi ý dùng đúng công thức `max(0, target − available)`.
4. Nếu cấu hình thiếu hoặc không hợp lệ, hệ thống không tự suy đoán; cần hiển thị trạng thái cấu hình.
5. Trải nghiệm hiện tại đặt tham số trong cấu hình sản phẩm và áp dụng cho kho mặc định; mô hình dữ liệu nên cho phép mở rộng theo sản phẩm + kho.
6. Chỉ báo tự thay đổi khi tồn hoặc cấu hình thay đổi; không có nút tiếp nhận/đóng.
7. Người dùng có thể dùng con số để lập mua hàng ở miền mua, nhưng không có liên kết proposal–đơn mua trong phạm vi này.

### Ví dụ minh họa

Sản phẩm P có khả dụng 8, ngưỡng 10 và mục tiêu 30. Hệ thống hiển thị “Sắp hết” và gợi ý 22. Sau khi bán thêm 8, khả dụng về 0, trạng thái thành “Hết hàng” và lượng gợi ý thành 30. Nếu một đơn mua đã được lập nhưng hàng chưa nhận, công thức vẫn dùng 0; hàng sắp về chưa được cộng trong phiên bản đơn giản này.

### Ngoại lệ và cách làm sai

- **Gọi ngưỡng là mức mục tiêu:** một cái kích hoạt cảnh báo, một cái xác định điểm muốn đạt.
- **Cộng PO chưa nhận vào khả dụng:** biến số hiện hành thành dự báo.
- **Làm tròn theo thùng hoặc MOQ:** đưa quy tắc mua hàng chưa được hỗ trợ vào công thức tồn.
- **Tạo bản ghi proposal mỗi lần số dư thay đổi:** sinh lifecycle và chống trùng không cần thiết.
- **Tự động đặt hàng:** vượt thẩm quyền của miền tồn kho.

## 3. Ý nghĩa đối với Theme

### Điều cần ghi nhớ

- **Ngưỡng cảnh báo và mức mục tiêu là hai tham số khác nhau.**
- **Căn cứ duy nhất hiện tại là tồn khả dụng.**
- **Lượng gợi ý là dữ liệu dẫn xuất, không phải một chứng từ.**
- **Dự báo và tự động mua hàng được để lại cho giai đoạn sau.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-036` |
| Cụm tri thức | [`KGV-C09`](00-table-of-contents.md#c09-hàng-đặc-thù-combo-bổ-sung-và-vòng-đời-master) |
| Loại bài | `PLANNING` |
| Quyết định chính | [`T7-DR-095`](../decisions/decision-register.md#313-g13-d%E1%BB%AF-li%E1%BB%87u-ch%E1%BB%A7-combo-b%E1%BB%95-sung-h%C3%A0ng-v%C3%A0-nghi%E1%BB%87p-v%E1%BB%A5-%C4%91%E1%BA%B7c-bi%E1%BB%87t), [`T7-DR-095`](../decisions/decision-register.md#313-g13-d%E1%BB%AF-li%E1%BB%87u-ch%E1%BB%A7-combo-b%E1%BB%95-sung-h%C3%A0ng-v%C3%A0-nghi%E1%BB%87p-v%E1%BB%A5-%C4%91%E1%BA%B7c-bi%E1%BB%87t), [`T7-DR-096#REQ-01`](../decisions/decision-register.md#313-g13-d%E1%BB%AF-li%E1%BB%87u-ch%E1%BB%A7-combo-b%E1%BB%95-sung-h%C3%A0ng-v%C3%A0-nghi%E1%BB%87p-v%E1%BB%A5-%C4%91%E1%BA%B7c-bi%E1%BB%87t), [`T7-DR-096`](../decisions/decision-register.md#313-g13-d%E1%BB%AF-li%E1%BB%87u-ch%E1%BB%A7-combo-b%E1%BB%95-sung-h%C3%A0ng-v%C3%A0-nghi%E1%BB%87p-v%E1%BB%A5-%C4%91%E1%BA%B7c-bi%E1%BB%87t), [`T7-DR-096#REQ-02`](../decisions/decision-register.md#313-g13-d%E1%BB%AF-li%E1%BB%87u-ch%E1%BB%A7-combo-b%E1%BB%95-sung-h%C3%A0ng-v%C3%A0-nghi%E1%BB%87p-v%E1%BB%A5-%C4%91%E1%BA%B7c-bi%E1%BB%87t), [`T7-DR-095#REQ-03`](../decisions/decision-register.md#313-g13-d%E1%BB%AF-li%E1%BB%87u-ch%E1%BB%A7-combo-b%E1%BB%95-sung-h%C3%A0ng-v%C3%A0-nghi%E1%BB%87p-v%E1%BB%A5-%C4%91%E1%BA%B7c-bi%E1%BB%87t), [`T7-DR-096`](../decisions/decision-register.md#313-g13-d%E1%BB%AF-li%E1%BB%87u-ch%E1%BB%A7-combo-b%E1%BB%95-sung-h%C3%A0ng-v%C3%A0-nghi%E1%BB%87p-v%E1%BB%A5-%C4%91%E1%BA%B7c-bi%E1%BB%87t), [`T7-DR-018#REQ-01`](../decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i) |
| Trạng thái | Gợi ý đơn giản áp dụng; dự báo và lifecycle đề xuất ngoài phạm vi |
| Mức bằng chứng | `STATIC_VALIDATED` |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-005` — Tồn vật lý, lượng đủ điều kiện bán, lượng giữ và tồn khả dụng](KB-KGV-005-ton-vat-ly-va-ton-kha-dung.md)
- [`KB-KGV-009` — Giữ hàng và xử lý đơn không đủ tồn khả dụng](KB-KGV-009-giu-hang-va-xu-ly-don-khong-du-ton-kha-dung.md)
- [`KB-KGV-038` — Chỉ báo dẫn xuất và hồ sơ cần xử lý](KB-KGV-038-canh-bao-ton-kho-va-vong-doi-xu-ly.md)
