---
id: KB-KGV-042-kien-truc-mo-rong-va-ranh-gioi-mvp
type: know-how
theme: theme-07
title: kien-truc-mo-rong-va-ranh-gioi-mvp
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-042-kien-truc-mo-rong-va-ranh-gioi-mvp — kien-truc-mo-rong-va-ranh-gioi-mvp

## 1. Bối cảnh

### Câu trả lời ngắn

Thiết kế sẵn nghĩa là giữ đúng thực thể, identity, ranh giới thẩm quyền và điểm mở rộng để thay đổi sau này không đòi hỏi viết lại lõi. Nó **không** có nghĩa là tạo sẵn màn hình, API, trạng thái hoặc nhánh nghiệp vụ chưa có đủ yêu cầu. Trong phiên bản đầu, hệ thống chỉ mở hành vi tạo giá trị ngay; yêu cầu tương lai bị từ chối rõ ràng, còn schema và hợp đồng không hard-code những giả định sẽ sớm bị phá vỡ.

### Vì sao vấn đề này quan trọng?

Hai cực đều nguy hiểm. Hard-code “chỉ một kho mãi mãi” giúp nhanh trước mắt nhưng khiến mở rộng tốn migration lớn. Ngược lại, xây đầy đủ định tuyến nhiều kho, offline và serial trước khi khách cần sẽ tăng thời gian, lỗi và chi phí kiểm thử. Một kiến trúc tiến hóa tốt đặt “đường nối” đúng chỗ nhưng không xây căn phòng chưa dùng.

## 2. Nội dung nền tảng

### Ba lớp cần tách

| Lớp | Làm ngay | Không làm trước |
|---|---|---|
| Mô hình | Giữ `store_id`, `warehouse_id`, version, source identity | Không tạo entity offline/serial/proposal nếu chưa có hành vi |
| Hợp đồng | Lỗi có cấu trúc cho capability ngoài phạm vi | Không nhận payload rồi bỏ qua một phần |
| Trải nghiệm | Ẩn lựa chọn chỉ có một giá trị, tự điền mặc định | Không hiện chức năng tương lai dưới dạng disabled/ẩn |

### Quy tắc vận hành

1. Mỗi giới hạn MVP phải được ghi thành capability boundary, không biến thành giả định vô hình.
2. Trường định danh cần cho mở rộng được lưu ngay nếu chi phí thấp và ý nghĩa ổn định.
3. Entity chỉ được tạo khi có lifecycle, Dữ liệu gốc và hành vi thật trong phạm vi.
4. API ngoài phạm vi trả lỗi có mã; không mutate một phần hoặc mô phỏng bằng operation khác.
5. UI chỉ hiển thị hành vi đã hoàn chỉnh; không dùng nhánh ẩn như một cách “chuẩn bị”.
6. Khi mở capability mới, phải cập nhật Quyết định nghiệp vụ, SRS, migration, compatibility và test trước khi bật.

7. Điều hướng hiện tại phải bắt đầu từ vai trò và công việc đang được hỗ trợ; không bắt người dùng chọn ngữ cảnh chỉ có một giá trị hoặc hiểu cấu trúc miền kỹ thuật.
8. Việc tự điền, ẩn trường có điều kiện và hướng dẫn bước tiếp theo chỉ là lớp trình bày. Máy chủ vẫn kiểm tra quyền, ngữ cảnh, bất biến và finality theo hợp đồng chuẩn.

### Ví dụ minh họa

Hệ thống hiện chỉ có một kho. Mỗi movement vẫn ghi `warehouse_id`, còn giao diện tự dùng kho mặc định. Đây là kiến trúc mở rộng hợp lý. Nhưng thêm nút “Chuyển kho” chỉ để tạo một adjustment âm và một adjustment dương là xây trước sai cách: không có hàng đang vận chuyển, chênh lệch nhận hay nguyên tử xuyên hai kho.

Tương tự, lưu request ID và outbox ngay từ đầu giúp độ tin cậy chung; nhưng tạo device sequence và offline conflict entity khi chưa bán offline chỉ làm tăng mô hình không cần thiết.

### Ngoại lệ và cách làm sai

- **YAGNI cực đoan:** bỏ mọi định danh ổn định vì hiện chưa dùng nhiều giá trị.
- **Future-proofing cực đoan:** thiết kế mọi trạng thái của một tính năng chưa hiểu rõ.
- **Feature flag cho hành vi chưa hoàn chỉnh:** biến code chưa kiểm chứng thành rủi ro vận hành.
- **Dùng nullable field cho mọi khả năng tưởng tượng:** làm mô hình mơ hồ hơn thay vì mở rộng hơn.

## 3. Ý nghĩa đối với Theme

### Điều cần ghi nhớ

- **Chuẩn bị ranh giới, không xây trước quy trình.**
- **Giới hạn MVP phải tường minh và có lỗi có cấu trúc.**
- **Identity ổn định có thể có từ đầu; lifecycle tương lai thì chưa.**
- **Mỗi capability mới cần một lần mở phạm vi có kiểm soát.**
- **Đơn giản hóa trải nghiệm hiện tại không được hard-code giới hạn hiện tại vào mô hình dữ liệu.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-042` |
| Cụm tri thức | [`KGV-C11`](00-table-of-contents.md#c11-kiến-trúc-mvp-có-khả-năng-tiến-hóa) |
| Loại bài | `ARCHITECTURE` |
| Quyết định chính | [`T7-DR-008`](../decisions/decision-register.md#31-g01-ph%E1%BA%A1m-vi-th%E1%BA%A9m-quy%E1%BB%81n-v%C3%A0-m%C3%B4-h%C3%ACnh-c%E1%BB%ADa-h%C3%A0ngkho), [`T7-DR-008#REQ-01`](../decisions/decision-register.md#31-g01-ph%E1%BA%A1m-vi-th%E1%BA%A9m-quy%E1%BB%81n-v%C3%A0-m%C3%B4-h%C3%ACnh-c%E1%BB%ADa-h%C3%A0ngkho), [`T7-DR-004`](../decisions/decision-register.md#31-g01-ph%E1%BA%A1m-vi-th%E1%BA%A9m-quy%E1%BB%81n-v%C3%A0-m%C3%B4-h%C3%ACnh-c%E1%BB%ADa-h%C3%A0ngkho), [`T7-DR-004`](../decisions/decision-register.md#31-g01-ph%E1%BA%A1m-vi-th%E1%BA%A9m-quy%E1%BB%81n-v%C3%A0-m%C3%B4-h%C3%ACnh-c%E1%BB%ADa-h%C3%A0ngkho), [`T7-DR-008#REQ-02`](../decisions/decision-register.md#31-g01-ph%E1%BA%A1m-vi-th%E1%BA%A9m-quy%E1%BB%81n-v%C3%A0-m%C3%B4-h%C3%ACnh-c%E1%BB%ADa-h%C3%A0ngkho), [`TERMINOLOGY_STANDARD`](../glossary/glossary.md), [`T7-DR-003#REQ-01`](../decisions/decision-register.md#31-g01-ph%E1%BA%A1m-vi-th%E1%BA%A9m-quy%E1%BB%81n-v%C3%A0-m%C3%B4-h%C3%ACnh-c%E1%BB%ADa-h%C3%A0ngkho) |
| Trạng thái | Áp dụng như nguyên tắc kiến trúc MVP |
| Mức bằng chứng | `STATIC_VALIDATED` |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-003` — Cửa hàng, kho và khóa định danh số dư tồn kho](KB-KGV-003-kho-cua-hang-va-khoa-dinh-danh-so-du-ton-kho.md)
- [`KB-KGV-039` — Bán hàng khi mất kết nối: định hướng và điều kiện mở phạm vi](KB-KGV-039-ban-hang-pos-offline.md)
- [`KB-KGV-041` — Cách kiểm soát thay đổi đối với quy tắc nghiệp vụ](KB-KGV-041-cach-kiem-soat-thay-doi-doi-voi-quy-tac-nghiep-vu.md)
