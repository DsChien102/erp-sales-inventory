---
id: KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang
type: know-how
theme: theme-07
title: danh-tinh-va-vong-doi-cua-mot-lo-hang
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang — danh-tinh-va-vong-doi-cua-mot-lo-hang

## 1. Bối cảnh

### Câu trả lời ngắn

Mã lô chính thức là mã do **nhà sản xuất hoặc đơn vị đóng gói** công bố trên hàng hoặc bao bì. Đơn vị bán hàng chỉ ghi nhận hoặc quét mã này, không tự phát minh lô để gom một lần giao. Trong một tenant, cùng sản phẩm + mã lô là cùng một hồ sơ lô ở mọi lần nhập và mọi kho.

Hồ sơ lô được tạo nguyên tử khi operation đầu tiên làm phát sinh tồn hoàn tất; dữ liệu trong bản nháp chưa tạo hồ sơ chính thức. Lần nhập sau khai khác ngày sản xuất hoặc hạn dùng phải bị chặn cho đến khi sửa dữ liệu nhập hoặc người có quyền sửa hồ sơ lô bằng nghiệp vụ có lý do và lịch sử.

### Vì sao vấn đề này quan trọng?

Một lô sản xuất có thể được mua nhiều lần, qua nhiều nhà cung cấp hoặc phân bổ vào nhiều kho. Nếu mỗi lần nhập tự tạo “lô nội bộ”, truy xuất thu hồi và kiểm soát hạn sẽ bị chia cắt. Nếu cùng mã lô lại mang nhiều ngày sản xuất/hạn dùng, người dùng không còn biết dữ liệu nào là căn cứ.

## 2. Nội dung nền tảng

### Các mã dễ nhầm

| Khái niệm | Ai tạo | Mục đích | Có phải danh tính lô? |
|---|---|---|---|
| Lô sản xuất | Nhà sản xuất/đóng gói | Truy xuất nguồn gốc và hạn dùng | Có |
| Đợt giao của nhà cung cấp | Nhà cung cấp hoặc bên mua | Gom một chuyến giao | Không |
| Batch nhận nội bộ | Hệ thống nhận hàng | Điều phối xử lý nhiều dòng | Không |
| Số chứng từ mua | Hệ thống mua hàng | Đối chiếu thương mại | Không |

### Quy tắc vận hành

1. Khóa lô là tenant + sản phẩm + `lot_code` đã chuẩn hóa.
2. `lot_code` phải lấy từ nhãn hàng/bao bì hoặc bằng chứng nhà sản xuất; không dùng số phiếu nhập thay thế.
3. Hồ sơ chỉ chính thức khi operation tạo tồn đầu tiên commit.
4. Cùng lô dùng chung ngày sản xuất và hạn dùng trên toàn tenant.
5. Ngày sản xuất được ghi khi có; hạn dùng bắt buộc nếu `expiry_required=true`.
6. Hạn dạng tháng/năm phải giữ độ chính xác gốc và quy về ngày cuối tháng để kiểm soát; ngày đầy đủ dùng đúng ngày.
7. Hàng hết hạn sau khi kết thúc ngày hạn theo ngày nghiệp vụ tenant; cận hạn là chỉ báo dẫn xuất theo ngưỡng cấu hình.
8. Sửa thuộc tính lô chính thức cần quyền, lý do, before/after và lịch sử; không sửa âm thầm để một receipt đi qua.
9. Phạm vi hiện tại không sinh lô nội bộ cho đóng gói lại, sản xuất hoặc chuyển đổi SKU.

### Ví dụ minh họa

Ngày 1, cửa hàng nhận vaccine P có mã in trên hộp `LOT-2407`, hạn `08/2027`. Khi operation nhận hoàn tất, hồ sơ `(tenant, P, LOT-2407)` được tạo, giữ độ chính xác hạn là tháng/năm và ngày kiểm soát 31/08/2027.

Ngày 15, một shipment khác của P cũng mang `LOT-2407`; đây là cùng lô dù số phiếu nhập khác. Nếu người dùng gõ hạn 30/09/2027, hệ thống chặn hoàn tất. Người xử lý phải kiểm tra nhãn: nếu receipt gõ sai thì sửa receipt; nếu hồ sơ lô ban đầu sai thì người có quyền thực hiện nghiệp vụ sửa lô có lý do và lịch sử.

### Ngoại lệ và cách làm sai

- **Dùng số phiếu nhập làm mã lô:** chia một lô sản xuất thành nhiều danh tính giả.
- **Tự sinh lô khi hàng không có mã:** tạo nguồn gốc không tồn tại.
- **Tạo hồ sơ lô ngay ở Nháp:** để lại master rác khi chứng từ bị bỏ.
- **Cho cùng lô có nhiều hạn dùng:** phá khả năng truy xuất và FEFO.
- **Mất độ chính xác gốc của tháng/năm:** người đọc không biết ngày cuối tháng là dữ liệu công bố hay quy tắc diễn giải.

## 3. Ý nghĩa đối với Theme

### Điều cần ghi nhớ

- **Lô là lô của nhà sản xuất/đóng gói, không phải đợt giao hoặc phiếu nhập.**
- **Cùng sản phẩm + mã lô là một hồ sơ trong tenant.**
- **Hồ sơ được tạo khi operation đầu tiên commit.**
- **Xung đột thuộc tính phải bị chặn và sửa có kiểm soát.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-025` |
| Cụm tri thức | [`KGV-C06`](00-table-of-contents.md#c06-lô-hạn-dùng-và-serial-tương-lai) |
| Loại bài | `CONCEPT` |
| Quyết định chính | [`T7-DR-015`](../decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i), [`T7-DR-016`](../decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i), [`T7-DR-018`](../decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i), [`T7-DR-072`](../decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh), [`T7-DR-073#REQ-01`](../decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh), [`T7-DR-074`](../decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh), [`T7-DR-074#REQ-01`](../decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh), [`T7-DR-015#REQ-01`](../decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i), [`T7-DR-015`](../decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i) |
| Trạng thái | Áp dụng cho sản phẩm `LOT` |
| Mức bằng chứng | `STATIC_VALIDATED` |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-024` — Chọn quản lý thông thường hay quản lý theo lô](KB-KGV-024-chinh-sach-quan-ly-hang-thong-thuong-theo-lo-hoac-theo-serial.md)
- [`KB-KGV-010` — Chọn hàng để xuất và thời điểm hoàn tất xuất bán](KB-KGV-010-chon-hang-de-xuat-va-thoi-diem-hoan-tat-xuat-ban.md)
- [`KB-KGV-014` — Hàng cận hạn, hết hạn, hư hỏng và tiêu hủy](KB-KGV-014-hang-can-han-het-han-hu-hong-va-tieu-huy.md)
- [`KB-KGV-022` — Chuẩn bị dữ liệu số dư tồn kho đầu kỳ](KB-KGV-022-chuan-bi-du-lieu-so-du-ton-kho-dau-ky.md)
