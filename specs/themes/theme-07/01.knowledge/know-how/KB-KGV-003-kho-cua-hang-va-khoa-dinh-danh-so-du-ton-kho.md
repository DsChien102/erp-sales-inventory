---
id: KB-KGV-003-kho-cua-hang-va-khoa-dinh-danh-so-du-ton-kho
type: know-how
theme: theme-07
title: kho-cua-hang-va-khoa-dinh-danh-so-du-ton-kho
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-003-kho-cua-hang-va-khoa-dinh-danh-so-du-ton-kho — kho-cua-hang-va-khoa-dinh-danh-so-du-ton-kho

## 1. Bối cảnh

### Câu trả lời ngắn

Cửa hàng là bối cảnh bán và phục vụ khách; kho là nơi quản lý hàng vật lý. Hai khái niệm không đồng nhất. Phạm vi khởi đầu chỉ có **một cửa hàng hoạt động và một kho hoạt động**, mọi giao dịch trực tuyến được quy về cặp mặc định này. Tuy vậy, dữ liệu và hợp đồng vẫn mang `store_id`, `warehouse_id`, đồng thời giữ mô hình cấp quyền cửa hàng–kho để có thể mở rộng quan hệ nhiều–nhiều về sau.

Một số dư tồn kho được nhận diện tối thiểu bằng tenant + sản phẩm + kho + trạng thái; nếu sản phẩm quản lý theo lô thì bổ sung lô. Hạn dùng là thuộc tính của lô, không phải một chiều số dư riêng.

### Vì sao vấn đề này quan trọng?

Nếu dùng cửa hàng thay cho kho, đội kỹ thuật sẽ khó mở rộng khi một cửa hàng dùng nhiều kho hoặc nhiều cửa hàng dùng chung một kho. Ngược lại, nếu đưa toàn bộ bài toán nhiều kho vào phiên bản đầu, hệ thống phải giải quyết chọn kho, chia đơn, chuyển kho, tồn đang vận chuyển và phân quyền phức tạp trước khi khách hàng cần đến.

Cách cân bằng là tách **khả năng mở rộng của mô hình** khỏi **khả năng nghiệp vụ đang được mở**: identity và quan hệ dữ liệu sẵn sàng cho tương lai, còn hành vi hiện tại chỉ cho một cặp mặc định.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Ví dụ |
|---|---|---|
| Cửa hàng | Bối cảnh thương mại phục vụ khách và ghi nhận giao dịch bán | Cửa hàng Mậu Hiên |
| Kho | Nơi chịu trách nhiệm số lượng và trạng thái hàng vật lý | Kho chính |
| Kho mặc định | Kho duy nhất được dùng cho mọi nghiệp vụ trong phạm vi khởi đầu | `WH-01` |
| Quan hệ cửa hàng–kho | Quyền một cửa hàng được sử dụng một kho | `STORE-01` được gán `WH-01` |
| Khóa số dư | Tập chiều làm một lượng tồn trở thành duy nhất | tenant + sản phẩm + kho + trạng thái + lô nếu có |

### Quy tắc vận hành

1. Chỉ một cửa hàng và một kho được ở trạng thái hoạt động.
2. Mọi giao dịch đều ghi rõ `store_id` và `warehouse_id`; không được suy ra bằng hằng số ẩn trong mã nguồn.
3. Giao diện không cần bộ chọn cửa hàng hoặc kho khi chỉ có một lựa chọn; hệ thống tự điền cặp mặc định và vẫn ghi vào dữ liệu.
4. Nhiều người dùng có thể bán đồng thời từ quầy, văn phòng hoặc khi đang di chuyển. Vị trí của người dùng không tạo thêm cửa hàng.
5. Không có chọn kho tối ưu, chia đơn giữa kho, chuyển kho, đóng/đổi kho hay tồn đang vận chuyển trong phạm vi hiện tại.
6. Yêu cầu dùng cửa hàng hoặc kho khác phải bị từ chối bằng lỗi có cấu trúc; không được mô phỏng bằng điều chỉnh tồn.
7. Chỉ cộng hai số dư khi toàn bộ chiều bắt buộc của khóa số dư giống nhau.

Cặp mặc định phải được hệ thống tự điền từ cấu hình và kiểm tra lại trên máy chủ. Người dùng không phải chọn một giá trị duy nhất, nhưng dữ liệu lưu vẫn mang đủ định danh. Đây là cách giảm thao tác trong hiện tại mà không biến giới hạn một cửa hàng, một kho thành hằng số kiến trúc.

### Ví dụ minh họa

Tenant có `STORE-01` và `WH-01`. Nhân viên tại quầy và chủ cửa hàng trên đường cùng tạo hai đơn trực tuyến. Cả hai đơn đều thuộc `STORE-01`; khi giữ hoặc xuất hàng, cả hai đều dùng `WH-01`. Hệ thống vẫn kiểm tra cạnh tranh nguyên tử nên không bán trùng phần hàng cuối.

Sản phẩm vaccine P tại `WH-01` có 30 lọ bán được thuộc lô L1 và 5 lọ cách ly cũng thuộc L1. Đây là hai số dư khác nhau vì trạng thái khác nhau. Nếu sau này có `WH-02`, lượng tại kho đó sẽ là số dư khác, nhưng chức năng kích hoạt và định tuyến sang `WH-02` phải thuộc một phiên bản được mở phạm vi riêng.

### Ngoại lệ và cách làm sai

- **Bỏ `warehouse_id` vì hiện chỉ có một kho:** tạo nợ kiến trúc và làm khó migration về sau.
- **Hiện bộ chọn nhiều kho nhưng chưa có quy tắc định tuyến:** tạo cam kết giao diện mà nghiệp vụ chưa bảo đảm.
- **Coi người bán từ xa là một cửa hàng khác:** nhầm kênh hoặc vị trí truy cập với đơn vị vận hành.
- **Dùng adjustment để giả lập chuyển kho:** tạo hai thay đổi rời, không có hàng đang vận chuyển và không bảo đảm nguyên tử.
- **Gộp trạng thái bán được và cách ly:** làm sai khả dụng dù tổng vật lý có thể vẫn đúng.

## 3. Ý nghĩa đối với Theme

### Điều cần ghi nhớ

- **Một cửa hàng, một kho là giới hạn hành vi; không phải giới hạn kiến trúc.**
- **Cửa hàng và kho là hai thực thể khác nhau.**
- **Mọi giao dịch vẫn mang định danh cửa hàng và kho.**
- **Không mở các luồng nhiều kho trước khi có đầy đủ hợp đồng nghiệp vụ.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-003` |
| Cụm tri thức | [`KGV-C01`](00-table-of-contents.md#c01-nền-tảng-quản-lý-tồn-kho) |
| Loại bài | `CONCEPT` |
| Quyết định chính | [`T7-DR-004`](../decisions/decision-register.md#31-g01-ph%E1%BA%A1m-vi-th%E1%BA%A9m-quy%E1%BB%81n-v%C3%A0-m%C3%B4-h%C3%ACnh-c%E1%BB%ADa-h%C3%A0ngkho), [`T7-DR-010`](../decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i), [`T7-DR-004`](../decisions/decision-register.md#31-g01-ph%E1%BA%A1m-vi-th%E1%BA%A9m-quy%E1%BB%81n-v%C3%A0-m%C3%B4-h%C3%ACnh-c%E1%BB%ADa-h%C3%A0ngkho), [`T7-DR-004`](../decisions/decision-register.md#31-g01-ph%E1%BA%A1m-vi-th%E1%BA%A9m-quy%E1%BB%81n-v%C3%A0-m%C3%B4-h%C3%ACnh-c%E1%BB%ADa-h%C3%A0ngkho), [`T7-DR-003#REQ-01`](../decisions/decision-register.md#31-g01-ph%E1%BA%A1m-vi-th%E1%BA%A9m-quy%E1%BB%81n-v%C3%A0-m%C3%B4-h%C3%ACnh-c%E1%BB%ADa-h%C3%A0ngkho) |
| Trạng thái | Phạm vi khởi đầu hoạt động; quan hệ nhiều–nhiều là khả năng mở rộng |
| Mức bằng chứng | `STATIC_VALIDATED` |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-005` — Tồn vật lý, lượng đủ điều kiện bán, lượng giữ và tồn khả dụng](KB-KGV-005-ton-vat-ly-va-ton-kha-dung.md)
- [`KB-KGV-006` — Tính chính thức của tồn kho và nguyên tắc chống xuất âm](KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am.md)
- [`KB-KGV-030` — Quyền chức năng, phạm vi kho và bảo vệ dữ liệu tài chính](KB-KGV-030-quyen-chuc-nang-pham-vi-kho-va-bao-ve-du-lieu-tai-chinh.md)
- [`KB-KGV-042` — Xây kiến trúc mở rộng mà không triển khai trước chức năng tương lai](KB-KGV-042-kien-truc-mo-rong-va-ranh-gioi-mvp.md)
