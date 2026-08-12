---
id: KB-KGV-024-chinh-sach-quan-ly-hang-thong-thuong-theo-lo-hoac-theo-serial
type: know-how
theme: theme-07
title: chinh-sach-quan-ly-hang-thong-thuong-theo-lo-hoac-theo-serial
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-024-chinh-sach-quan-ly-hang-thong-thuong-theo-lo-hoac-theo-serial — chinh-sach-quan-ly-hang-thong-thuong-theo-lo-hoac-theo-serial

## 1. Bối cảnh

### Câu trả lời ngắn

Mỗi sản phẩm trong phạm vi khởi đầu có một chế độ theo dõi: `NONE` hoặc `LOT`. `NONE` nghĩa là chỉ quản lý tổng lượng theo kho và trạng thái; các trường lô, ngày sản xuất và hạn dùng bị vô hiệu hóa. `LOT` nghĩa là mọi nghiệp vụ làm phát sinh hoặc lựa chọn hàng phải mang lô. Khi đó mới có cấu hình độc lập `expiry_required` để quyết định hạn dùng có bắt buộc hay không.

Không phải mọi sản phẩm đều cần lô. Thuốc, vaccine hoặc hàng cần truy xuất và kiểm soát hạn thường dùng `LOT`; vật tư thông thường có thể dùng `NONE`. Quản lý theo serial là mức chi tiết khác và chưa thuộc phạm vi khởi đầu.

### Vì sao vấn đề này quan trọng?

Ép tất cả sản phẩm theo lô làm tăng thao tác mà không tạo giá trị cho hàng đơn giản. Ngược lại, không theo lô với hàng cần truy xuất sẽ mất khả năng thu hồi đúng lô, xuất theo FEFO và chặn hàng hết hạn. Tách `tracking_mode` khỏi `expiry_required` còn phản ánh thực tế: có lô để truy xuất nhưng không phải lô nào cũng có hạn dùng.

## 2. Nội dung nền tảng

### Ma trận cấu hình

| `tracking_mode` | `expiry_required` | Lô | Hạn dùng | Trường hợp điển hình |
|---|---|---|---|---|
| `NONE` | Không áp dụng | Tắt | Tắt | Phụ kiện, vật tư không cần truy xuất lô |
| `LOT` | `false` | Bắt buộc | Tùy chọn | Hàng cần truy xuất lô nhưng không công bố hạn |
| `LOT` | `true` | Bắt buộc | Bắt buộc | Thuốc, vaccine, sinh phẩm có hạn dùng |

### Quy tắc vận hành

1. Hệ thống quản lý sản phẩm sở hữu cấu hình; hệ thống tồn kho nhận snapshot có phiên bản và bắt buộc tuân thủ trong mọi operation.
2. Với `NONE`, UI và API không chấp nhận lô, ngày sản xuất hoặc hạn dùng.
3. Với `LOT`, mã lô là dữ liệu bắt buộc khi nhận, xuất, trả, kiểm kê hoặc điều chỉnh có liên quan.
4. `expiry_required` chỉ được phép cấu hình khi mode là `LOT`.
5. Hạn dùng là thuộc tính của hồ sơ lô; lượng hết hạn bị loại khỏi khả dụng theo ngày nghiệp vụ tenant.
6. Chỉ đổi `NONE ↔ LOT` khi tồn bằng 0 và không còn giữ hàng hoặc operation mở. Chuyển đổi dữ liệu khi còn tồn được hoãn.
7. Serial không được xuất hiện như lựa chọn đang dùng trong giao diện hoặc hợp đồng phạm vi hiện tại.

#### Chỉ hỏi dữ liệu khi thực sự cần

Biểu mẫu chỉ mở trường lô khi sản phẩm dùng `LOT`, và chỉ yêu cầu hạn dùng khi `expiry_required=true`. Thông tin đã biết từ sản phẩm, chứng từ nguồn hoặc ngữ cảnh mặc định được tự điền. Khi xuất hàng, hệ thống có thể đề xuất lô theo FEFO hoặc FIFO; người có quyền mới được chọn khác và máy chủ vẫn kiểm tra lại toàn bộ điều kiện trước khi ghi nhận.

### Ví dụ minh họa

Ống tiêm dùng một lần không cần truy xuất lô nên cấu hình `NONE`; khi nhận 100 chiếc, người dùng chỉ nhập số lượng. Vaccine A cần truy xuất và có hạn nên cấu hình `LOT` + `expiry_required=true`; nhận 50 lọ phải quét mã lô và ghi hạn dùng. Một bộ dụng cụ có lô sản xuất nhưng không công bố hạn có thể dùng `LOT` + `expiry_required=false`.

Nếu vaccine A còn 20 lọ, quản trị viên không thể chuyển về `NONE`. Trước hết phải xử lý hết tồn và mọi nghĩa vụ mở; việc chạy batch gán hoặc xóa lô trên hàng đang còn không thuộc phạm vi hiện tại.

### Ngoại lệ và cách làm sai

- **Bật hạn dùng cho `NONE`:** tạo dữ liệu không có đơn vị truy xuất để gắn vào.
- **Cho nhập lô tùy ý với `NONE`:** khiến cùng sản phẩm lúc có lúc không có chiều lô.
- **Bật `LOT` khi còn tồn rồi gán một lô giả:** làm sai truy xuất nguồn gốc.
- **Ép mọi sản phẩm dùng `LOT`:** tăng ma sát và sai tinh thần sản phẩm chọn theo nhu cầu.
- **Đưa serial vào cùng màn hình như lựa chọn khả dụng:** tạo kỳ vọng về chức năng chưa có.

## 3. Ý nghĩa đối với Theme

### Điều cần ghi nhớ

- **Theo dõi lô là chính sách theo từng sản phẩm, không phải toàn hệ thống.**
- **`NONE` tự vô hiệu hóa hạn dùng.**
- **`LOT` mới mở lựa chọn có bắt buộc hạn dùng hay không.**
- **Chỉ đổi chế độ khi không còn tồn hoặc nghĩa vụ mở.**
- **Trường lô và hạn dùng chỉ xuất hiện theo cấu hình của sản phẩm; dữ liệu đã biết không được bắt người dùng nhập lại.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-024` |
| Cụm tri thức | [`KGV-C06`](00-table-of-contents.md#c06-lô-hạn-dùng-và-serial-tương-lai) |
| Loại bài | `POLICY` |
| Quyết định chính | [`T7-DR-010`](../decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i), [`T7-DR-013#REQ-01`](../decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i), [`T7-DR-013`](../decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i), [`T7-DR-014`](../decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i), [`T7-DR-016#REQ-01`](../decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i), [`T7-DR-017`](../decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i), [`T7-DR-018`](../decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i), [`T7-DR-013#REQ-02`](../decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i), [`T7-DR-018#REQ-01`](../decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i), [`T7-DR-003#REQ-01`](../decisions/decision-register.md#31-g01-ph%E1%BA%A1m-vi-th%E1%BA%A9m-quy%E1%BB%81n-v%C3%A0-m%C3%B4-h%C3%ACnh-c%E1%BB%ADa-h%C3%A0ngkho) |
| Trạng thái | `NONE` và `LOT` áp dụng; serial và chuyển đổi khi còn tồn được hoãn |
| Mức bằng chứng | `STATIC_VALIDATED` |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-025` — Danh tính và vòng đời của một lô hàng](KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md)
- [`KB-KGV-014` — Hàng cận hạn, hết hạn, hư hỏng và tiêu hủy](KB-KGV-014-hang-can-han-het-han-hu-hong-va-tieu-huy.md)
- [`KB-KGV-026` — Quản lý theo serial khác quản lý theo lô như thế nào?](KB-KGV-026-danh-tinh-va-vong-doi-cua-mot-serial.md)
