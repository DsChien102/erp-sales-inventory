---
id: KB-KGV-026-danh-tinh-va-vong-doi-cua-mot-serial
type: know-how
theme: theme-07
title: danh-tinh-va-vong-doi-cua-mot-serial
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-026-danh-tinh-va-vong-doi-cua-mot-serial — danh-tinh-va-vong-doi-cua-mot-serial

## 1. Bối cảnh

### Câu trả lời ngắn

Lô gom nhiều đơn vị có chung nguồn sản xuất; serial nhận diện **từng đơn vị riêng lẻ**. Một lô vaccine có thể gồm 1.000 lọ, còn một máy siêu âm có một serial riêng và số lượng luôn bằng 1. Serial phù hợp với tài sản giá trị cao, bảo hành hoặc truy vết từng thiết bị; lô phù hợp với thuốc, vaccine và hàng cần kiểm soát hạn dùng.

Phạm vi khởi đầu chỉ triển khai `NONE` và `LOT`. Serial là hướng mở rộng, không có lựa chọn cấu hình, trường nhập, entity hoặc API đang hoạt động.

### Vì sao vấn đề này quan trọng?

Nếu dùng lô thay serial, hệ thống không biết chính xác thiết bị nào được bán, trả hay bảo hành. Nếu dùng serial cho hàng tiêu hao số lượng lớn, thao tác quét sẽ quá nặng. Tách hai cơ chế giúp chọn đúng độ chi tiết và không mang chi phí triển khai serial vào một sản phẩm MVP chủ yếu cần lô–hạn dùng.

## 2. Nội dung nền tảng

### So sánh

| Tiêu chí | Lô | Serial |
|---|---|---|
| Độ chi tiết | Một nhóm nhiều đơn vị | Một đơn vị |
| Khóa điển hình | tenant + sản phẩm + mã lô | tenant + sản phẩm + mã serial |
| Số lượng trên danh tính | Có thể lớn hơn 1 | Luôn bằng 1 |
| Hạn dùng | Thường là thuộc tính của lô | Có thể có nhưng không phải mục đích chính |
| Dùng khi bán | Chọn lô theo FEFO/FIFO | Quét đúng đơn vị |
| Trường hợp | Vaccine, thuốc, thức ăn theo batch | Máy móc, thiết bị, tài sản bảo hành |

### Điều kiện cần có trước khi mở serial

1. Quy tắc duy nhất và lịch sử vòng đời của serial.
2. Kiểm soát số lượng nguyên và số serial phân biệt bằng lượng cơ sở.
3. Quy trình quét khi nhập, lấy hàng, bàn giao, trả và bảo hành.
4. Xử lý tái nhập một serial đã rời kho với nguồn hợp lệ.
5. Migration và tương thích với tồn hiện hữu.
6. Hợp đồng lỗi cho serial trùng, sai sản phẩm hoặc đã xuất.
7. Màn hình và thiết bị quét đủ nhanh cho vận hành thực tế.

### Ví dụ minh họa

Một thùng 100 lọ vaccine có mã lô `L2408`; hệ thống theo dõi tổng lượng còn lại của lô và hạn dùng. Ngược lại, ba máy xét nghiệm cùng model có serial `S001`, `S002`, `S003`; khi bán phải biết chính xác máy nào đã bàn giao để bảo hành đúng thiết bị.

Trong phạm vi hiện tại, vaccine được hỗ trợ bằng `LOT`; ví dụ máy xét nghiệm chỉ giúp hiểu thiết kế tương lai. Không được nhập `S001` vào một trường lô để giả lập serial.

### Ngoại lệ và cách làm sai

- **Dùng một lô có lượng 1 để giả lập serial:** không tạo được các invariant vòng đời serial.
- **Dùng serial cho mọi hàng:** tăng chi phí thao tác mà không có lợi ích tương ứng.
- **Đưa trường serial vào UI nhưng chưa có ledger hỗ trợ:** tạo dữ liệu không thể kiểm soát.
- **Hiểu “serial được hoãn” là có thể nhập tự do:** ngoài phạm vi phải bị từ chối có cấu trúc.

## 3. Ý nghĩa đối với Theme

### Điều cần ghi nhớ

- **Lô theo dõi một nhóm; serial theo dõi từng đơn vị.**
- **Lô và serial giải quyết hai bài toán khác nhau.**
- **Phạm vi khởi đầu chưa triển khai serial.**
- **Không giả lập serial bằng lô hoặc ghi chú tự do.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-026` |
| Cụm tri thức | [`KGV-C06`](00-table-of-contents.md#c06-lô-hạn-dùng-và-serial-tương-lai) |
| Loại bài | `FUTURE_CONCEPT` |
| Quyết định chính | [`T7-DR-019`](../decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i), [`T7-DR-019#REQ-01`](../decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i), [`T7-DR-019#REQ-02`](../decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i), [`T7-DR-019#REQ-03`](../decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i), [`T7-DR-008#REQ-01`](../decisions/decision-register.md#31-g01-ph%E1%BA%A1m-vi-th%E1%BA%A9m-quy%E1%BB%81n-v%C3%A0-m%C3%B4-h%C3%ACnh-c%E1%BB%ADa-h%C3%A0ngkho) |
| Trạng thái | `DEFERRED` — không triển khai trong phạm vi hiện tại |
| Mức bằng chứng | `STATIC_VALIDATED` |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-024` — Chọn quản lý thông thường hay quản lý theo lô](KB-KGV-024-chinh-sach-quan-ly-hang-thong-thuong-theo-lo-hoac-theo-serial.md)
- [`KB-KGV-025` — Danh tính và vòng đời của một lô hàng](KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md)
- [`KB-KGV-041` — Cách kiểm soát thay đổi đối với quy tắc nghiệp vụ](KB-KGV-041-cach-kiem-soat-thay-doi-doi-voi-quy-tac-nghiep-vu.md)
