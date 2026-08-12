---
id: KB-KGV-005-ton-vat-ly-va-ton-kha-dung
type: know-how
theme: theme-07
title: ton-vat-ly-va-ton-kha-dung
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-005-ton-vat-ly-va-ton-kha-dung — ton-vat-ly-va-ton-kha-dung

## 1. Bối cảnh

### Câu trả lời ngắn

**Tồn vật lý** trả lời câu hỏi “hàng có đang hiện diện và thuộc phạm vi quản lý của kho hay không?”. **Lượng đủ điều kiện bán** là phần tồn vật lý hiện được phép dùng để đáp ứng nhu cầu bán. **Lượng đã giữ** là phần đủ điều kiện bán đã được cam kết cho các đơn cụ thể. Vì vậy:

$$
\text{Tồn khả dụng} = \text{Lượng tồn vật lý đủ điều kiện bán} - \text{Lượng đã giữ}
$$

Hàng chờ chốt giá, cách ly, hư hỏng, hết hạn hoặc bị chính sách chặn bán vẫn có thể nằm trong tồn vật lý, nhưng **không được tính vào lượng đủ điều kiện bán**. Tồn khả dụng là một kết quả dẫn xuất tại thời điểm kiểm tra, không phải cách gọi khác của tồn vật lý.

### Vì sao vấn đề này quan trọng?

Một kho có thể “còn 100 sản phẩm” nhưng chỉ bán thêm được 55. Nếu màn hình, báo cáo hoặc nghiệp vụ bán hàng chỉ nhìn tổng tồn vật lý, hệ thống có thể cam kết nhầm hàng chưa chốt giá, hàng hỏng hoặc hàng đã dành cho đơn khác.

Ngược lại, lượng giữ không làm hàng biến mất khỏi kho. Nó chỉ thay đổi **quyền sử dụng phần hàng đó**. Nhầm hai lớp này thường dẫn đến hai lỗi đối nghịch: bán vượt khả năng thực hiện hoặc báo hết hàng trong khi vẫn còn lượng có thể bán.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Câu hỏi mà nó trả lời | Ảnh hưởng đến tồn khả dụng |
|---|---|---|
| Tồn vật lý | Có bao nhiêu hàng đang hiện diện trong kho theo sổ tồn? | Là tập lớn ban đầu, nhưng không phải toàn bộ đều được bán |
| Lượng đủ điều kiện bán | Trong tồn vật lý, bao nhiêu hàng hiện được phép bán? | Là số bị trừ lượng giữ để tính khả dụng |
| Lượng đã giữ | Bao nhiêu hàng đã cam kết cho đơn nhưng chưa xuất vật lý? | Bị trừ khỏi lượng đủ điều kiện bán |
| Tồn khả dụng | Ngay lúc này còn bao nhiêu hàng có thể cam kết cho nhu cầu mới? | Là kết quả cuối cùng dùng cho quyết định giữ hoặc xuất |
| Hàng chờ chốt giá | Hàng đã nhận nhưng chưa đủ điều kiện định giá để đưa vào bán | Có trong vật lý, không thuộc lượng đủ điều kiện bán |
| Hàng cách ly, hỏng hoặc hết hạn | Hàng còn hiện diện nhưng không được bán | Có trong vật lý, không thuộc lượng đủ điều kiện bán |
| Hàng bị chặn bán | Hàng bị loại khỏi bán theo chính sách hiện hành | Không thuộc lượng đủ điều kiện bán trong thời gian bị chặn |

**Trạng thái tồn kho** giải thích vì sao một lượng hàng được hoặc không được bán. **Lượng giữ** lại giải thích phần nào của hàng bán được đã có đơn khác cam kết. Hai chiều này không được trộn thành một con số duy nhất thiếu nguồn gốc.

### Quy tắc vận hành

#### 1. Xác định tồn vật lý

Hệ thống cộng các số dư vật lý của sản phẩm tại kho theo những trạng thái đang hiện diện. Việc chuyển giữa trạng thái bán được và không bán được không tự làm thay đổi tổng vật lý; chỉ operation làm hàng thực sự vào hoặc rời kho mới tăng hoặc giảm lượng vật lý tương ứng.

#### 2. Lọc ra lượng đủ điều kiện bán

Từ tồn vật lý, hệ thống loại các trạng thái không được phép bán như chờ giá, cách ly, hỏng, hết hạn hoặc bị chặn theo chính sách. Phần còn lại là **lượng tồn vật lý đủ điều kiện bán**.

#### 3. Trừ lượng đã giữ

Lượng đã giữ vẫn nằm trong kho nhưng không còn sẵn cho một cam kết mới. Vì vậy, nó được trừ khỏi lượng đủ điều kiện bán để tạo ra tồn khả dụng.

#### 4. Quyết định bằng số dư giao dịch hiện hành

Khi cần giữ hoặc xuất hàng, hệ thống phải đọc số dư giao dịch mới nhất và thực hiện **kiểm tra + giữ/xuất trong cùng một transaction nguyên tử**. Nếu hai giao dịch cùng tranh chấp phần hàng cuối, giao dịch hợp lệ commit trước được quyền sử dụng; giao dịch sau phải nhận kết quả thiếu hàng.

Số dư hoặc báo cáo được cập nhật bất đồng bộ chỉ dùng để tra cứu. Giao diện phải cho biết thời điểm dữ liệu, và không được lấy projection cũ làm thẩm quyền để quyết định giữ hay xuất.

#### 5. Không tạo “tồn đang vận chuyển” trong phạm vi hiện tại

`IN_TRANSIT` là khái niệm dành trước cho nghiệp vụ chuyển kho nội bộ trong tương lai. Khi nghiệp vụ đó chưa được hỗ trợ, operation hiện tại không được tự tạo số dư đang vận chuyển hoặc dùng trạng thái này để mô phỏng một lần chuyển kho.

### Ví dụ xuyên suốt

Một kho đang có 100 đơn vị sản phẩm A:

| Thành phần vật lý | Số lượng | Được bán? |
|---|---:|---|
| Trạng thái bán được | 80 | Có |
| Chờ chốt giá | 10 | Không |
| Cách ly | 5 | Không |
| Hư hỏng | 3 | Không |
| Hết hạn | 2 | Không |
| **Tổng tồn vật lý** | **100** |  |

Trong 80 đơn vị đủ điều kiện bán, 25 đơn vị đã được giữ cho các đơn sỉ và online:

$$
\text{Tồn khả dụng} = 80 - 25 = 55
$$

Các biến động sau cho thấy bốn lớp số lượng thay đổi khác nhau:

| Sự kiện | Tồn vật lý | Đủ điều kiện bán | Đã giữ | Khả dụng |
|---|---:|---:|---:|---:|
| Trạng thái ban đầu | 100 | 80 | 25 | 55 |
| Giải phóng 5 đơn vị do đơn giảm lượng | 100 | 80 | 20 | 60 |
| Bàn giao 20 đơn vị đã giữ cho khách | 80 | 60 | 0 | 60 |
| Chốt giá và giải phóng 10 đơn vị chờ giá | 80 | 70 | 0 | 70 |

Điểm đáng chú ý là khi 20 đơn vị đã giữ được bàn giao, tồn vật lý và lượng giữ cùng giảm 20 nên tồn khả dụng không đổi. Đây là hành vi đúng: phần hàng đó vốn đã không còn sẵn cho nhu cầu mới từ lúc được giữ.

### Ngoại lệ và những cách làm sai

- **Dùng tồn vật lý làm tồn khả dụng:** cách này cho phép bán cả hàng chờ giá, hỏng hoặc đã giữ cho đơn khác.
- **Trừ lượng giữ hai lần:** nếu lượng giữ đã được loại khỏi khả dụng, không được tiếp tục trừ nó khỏi tồn vật lý để tạo một “tồn thực” giả.
- **Cho phép màn hình cache quyết định giữ hàng:** số hiển thị có thể chậm hơn ledger; quyết định thay đổi tồn phải dùng số dư giao dịch hiện hành.
- **Sửa số dư trực tiếp để chuyển trạng thái:** việc phân loại lại hàng phải đi qua operation có lý do và lịch sử.
- **Coi lượng đã giữ là bảo đảm vĩnh viễn:** nếu hàng đã giữ không còn đủ điều kiện bán, hệ thống vẫn phải phân bổ lại hoặc đưa phần thiếu vào chờ hàng theo quy tắc liên quan.

## 3. Ý nghĩa đối với Theme

### Điều cần ghi nhớ

- **Tồn vật lý cho biết hàng đang hiện diện; tồn khả dụng cho biết hàng còn có thể cam kết.**
- **Lượng đủ điều kiện bán là một tập con của tồn vật lý.**
- **Lượng giữ không giảm vật lý nhưng làm giảm khả dụng.**
- **Hàng chờ giá, cách ly, hỏng, hết hạn hoặc bị chặn bán không thuộc lượng đủ điều kiện bán.**
- **Quyết định giữ và xuất phải dựa trên số dư giao dịch hiện hành, không dựa trên projection bất đồng bộ.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-005` |
| Cụm tri thức | [`KGV-C01`](00-table-of-contents.md#c01-nền-tảng-quản-lý-tồn-kho) |
| Loại bài | `CONCEPT` |
| Quyết định chính | [`T7-DR-012`](../decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i), [`T7-DR-029`](../decisions/decision-register.md#34-g04-kh%E1%BA%A3-d%E1%BB%A5ng-gi%E1%BB%AF-h%C3%A0ng-l%E1%BA%A5y-h%C3%A0ng-v%C3%A0-xu%E1%BA%A5t), [`T7-DR-084#REQ-01`](../decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i) |
| Trạng thái quyết định | `ACTIVE` |
| Mức bằng chứng của bài | `STATIC_VALIDATED` |
| Giới hạn | Bài giải thích mô hình số lượng; không quyết định quy tắc giữ hàng, chọn lô hoặc xử lý từng loại hàng không bán được |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-003` — Kho, cửa hàng và khóa định danh số dư tồn kho](KB-KGV-003-kho-cua-hang-va-khoa-dinh-danh-so-du-ton-kho.md)
- [`KB-KGV-009` — Giữ hàng và xử lý đơn không đủ tồn khả dụng](KB-KGV-009-giu-hang-va-xu-ly-don-khong-du-ton-kha-dung.md)
- [`KB-KGV-014` — Hàng cận hạn, hết hạn, hư hỏng và tiêu hủy](KB-KGV-014-hang-can-han-het-han-hu-hong-va-tieu-huy.md)
- [`KB-KGV-036` — Nhận biết tồn thấp và gợi ý lượng bổ sung](KB-KGV-036-ton-du-kien-va-de-xuat-bo-sung-hang.md)
- [`KB-KGV-039` — Bán hàng khi mất kết nối: định hướng và điều kiện mở phạm vi](KB-KGV-039-ban-hang-pos-offline.md)
