---
id: KB-KGV-041-cach-kiem-soat-thay-doi-doi-voi-quy-tac-nghiep-vu
type: know-how
theme: theme-07
title: cach-kiem-soat-thay-doi-doi-voi-quy-tac-nghiep-vu
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-041-cach-kiem-soat-thay-doi-doi-voi-quy-tac-nghiep-vu — cach-kiem-soat-thay-doi-doi-voi-quy-tac-nghiep-vu

## 1. Bối cảnh

### Câu trả lời ngắn

Một bộ quy tắc nghiệp vụ chỉ được đóng băng thành bản chuẩn có hiệu lực sau khi ba lớp bằng chứng đồng thuận: danh mục quyết định đã hợp nhất, nhật ký các quyết định bị thay thế và báo cáo kiểm tra nhất quán. Mọi xung đột có thể thay đổi phạm vi, thẩm quyền, phép tổng hợp, invariant hoặc finality tài chính phải được đóng trước. Khi đạt điều kiện, snapshot được phát hành với định danh phiên bản và checksum manifest riêng. Thay đổi về sau không sửa âm thầm bản đã đóng băng mà đi qua một phiên bản mới có truy vết thay thế và kiểm tra lại tác động.

### Vì sao vấn đề này quan trọng?

Một câu trả lời mới có thể nghe hợp lý nhưng vô tình mâu thuẫn với mốc ghi nhận, quyền sở hữu dữ liệu hoặc cách tính giá đã chốt. Nếu chỉ sửa tài liệu hiện tại, đội triển khai không biết bản nào từng có hiệu lực và dữ liệu lịch sử được tạo theo quy tắc nào. Freeze không có nghĩa là quy tắc không bao giờ đổi; nó tạo một điểm tham chiếu ổn định, có checksum để phát hiện trôi nội dung. Nhật ký thay thế và audit nhất quán giúp thay đổi có chủ đích thay vì cộng dồn ngoại lệ không kiểm soát.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Không được hiểu là |
|---|---|---|
| Phiên bản hiệu lực | Bản quy tắc được áp dụng từ một mốc xác định và giữ lại lịch sử. | Sửa nội dung cũ rồi coi như luôn đúng. |
| Thay thế có truy vết | Quy tắc mới chỉ rõ quy tắc cũ bị thay thế và lý do. | Xóa quyết định cũ khỏi lịch sử. |

### Quy tắc vận hành

#### Freeze chỉ sau khi khép mọi xung đột trọng yếu

Chỉ freeze sau khi danh mục quyết định đã hợp nhất, nhật ký quyết định bị thay thế và báo cáo kiểm tra nhất quán không còn xung đột thay đổi scope, authority, aggregate, invariant hoặc financial finality. Mọi blocker phải được đóng, kết quả kiểm tra phải đạt điều kiện freeze, và snapshot chuẩn phải được phát hành với định danh phiên bản cùng checksum manifest riêng.

#### Trải nghiệm cũng phải có hợp đồng kiểm soát

Thay đổi cách vào việc, mức dữ liệu phải nhập, từ ngữ hiển thị hoặc hướng dẫn phục hồi phải được truy vết như các quy tắc khác. Từ điển nhãn tiếng Việt dùng chung giúp wiki, SRS, prototype và kiểm thử không diễn đạt cùng một trạng thái theo nhiều nghĩa. Hướng dẫn phục hồi chỉ được suy ra từ kết quả, quyền và hành động sẵn có; nếu thêm một mutation hay transition mới thì đó là thay đổi nghiệp vụ, không còn là tinh chỉnh giao diện.

### Ví dụ xuyên suốt

Một đề xuất mới cho phép sửa trực tiếp trạng thái hàng hết hạn để xử lý nhanh. Dù thuận tiện, nó xung đột với invariant rằng thay đổi trạng thái phải qua operation có lịch sử. Đề xuất không được chèn ngay vào bản chuẩn. Nhóm phân tích ghi finding, xác định quyết định bị tác động, đánh giá authority và finality, rồi chốt giữ nguyên đường operation. Finding được đóng và báo cáo consistency trở lại PASS. Snapshot phiên bản 1.0.0 được phát hành với checksum. Nếu phiên bản sau thật sự thay đổi quy tắc, nó phải chỉ rõ quyết định cũ bị thay thế, ngày hiệu lực, ảnh hưởng dữ liệu hiện hữu và phát hành snapshot 1.1.0 hoặc phiên bản phù hợp; bản 1.0.0 vẫn bất biến.

Ví dụ này chỉ minh họa cách áp dụng các quy tắc đã nêu. Con số, tên sản phẩm và thời điểm là giả định; chúng không tạo thêm một ngoại lệ, quyền phê duyệt hay mốc ghi nhận mới.

### Ngoại lệ và những cách làm sai

- **Freeze khi vẫn còn blocker:** Một xung đột về thẩm quyền hoặc finality có thể làm nhiều bài và hợp đồng triển khai cùng sai.
- **Sửa snapshot cũ để phản ánh quyết định mới:** Cách này xóa lịch sử hiệu lực; thay đổi phải tạo phiên bản và liên kết thay thế.
- **Chỉ kiểm tra trùng câu chữ:** Consistency cần kiểm cả scope, authority, aggregate, invariant và finality tài chính.

- **Sửa trực tiếp số dư hoặc trạng thái để “làm cho đúng”:** cách này phá vỡ sổ biến động và làm mất khả năng giải thích số liệu. Mọi thay đổi chính thức phải đi qua đúng loại nghiệp vụ, có căn cứ và lịch sử.
- **Dùng dữ liệu tra cứu chậm làm căn cứ commit:** báo cáo hoặc projection có thể hữu ích để quan sát, nhưng quyết định thay đổi tồn phải kiểm tra lại dữ liệu giao dịch hiện hành.

## 3. Ý nghĩa đối với Theme

### Cách áp dụng trong thực tế

Trước hết, hợp nhất các câu trả lời thành quyết định không trùng nghĩa và gắn trạng thái rõ ràng. Tiếp theo, ghi nhận quyết định nào thay thế quyết định nào để chỉ còn một kết luận có hiệu lực cho mỗi vấn đề. Sau đó chạy kiểm tra chéo tối thiểu trên năm trục: scope, authority, aggregate, invariant và financial finality. Mọi blocker phải có quyết định đóng hoặc được ghi là chưa đủ điều kiện phát hành. Chỉ khi audit đạt, tạo snapshot chỉ đọc, gán version và tính checksum cho manifest. Một yêu cầu thay đổi mới bắt đầu chu kỳ mới; không chỉnh file snapshot cũ.

Khi triển khai một trường hợp cụ thể, người xử lý nên ghi rõ nguồn chứng từ, đối tượng hàng, kho, trạng thái, thời điểm nghiệp vụ và kết quả mong đợi. Nếu một dữ kiện thuộc thẩm quyền của hệ thống khác chưa có, hồ sơ phải dừng ở trạng thái an toàn thay vì tự suy đoán. Nếu một bước có thể ảnh hưởng đồng thời đến nhiều số dư hoặc cả số lượng lẫn giá trị, toàn bộ thay đổi phải được commit nguyên tử và để lại dấu vết đối soát.

### Điều cần ghi nhớ

- **Freeze là điểm tham chiếu có phiên bản, không phải tuyên bố quy tắc không bao giờ đổi.**
- **Danh mục quyết định, nhật ký thay thế và consistency audit phải đồng thuận.**
- **Mọi blocker ảnh hưởng ranh giới hoặc finality phải được đóng trước phát hành.**
- **Snapshot đã phát hành là bất biến; thay đổi về sau tạo phiên bản mới có checksum và truy vết.**
- **Thay đổi trải nghiệm không được âm thầm tạo năng lực, trạng thái hoặc quyền mới.**

- **Khi không đủ bằng chứng để đi tiếp, hệ thống phải thất bại an toàn và giữ nguyên dữ liệu có thẩm quyền.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-041` |
| Cụm tri thức | [`KGV-C10`](00-table-of-contents.md#c10-vận-hành-phục-hồi-và-thay-đổi) |
| Loại bài | `GOVERNANCE` |
| Quyết định chính | [`T7-DR-003#REQ-01`](../decisions/decision-register.md#31-g01-ph%E1%BA%A1m-vi-th%E1%BA%A9m-quy%E1%BB%81n-v%C3%A0-m%C3%B4-h%C3%ACnh-c%E1%BB%ADa-h%C3%A0ngkho), [`T7-DR-090#REQ-01`](../decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i) |
| Trạng thái quyết định | `ACTIVE` |
| Mức bằng chứng của bài | `STATIC_VALIDATED` |
| Giới hạn | Bài giải thích quản trị thay đổi quy tắc; không quyết định quy ước semantic versioning cụ thể, công cụ ký số hoặc cơ cấu hội đồng phê chuẩn |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-001` — Phạm vi quản lý tồn kho và giá vốn](KB-KGV-001-pham-vi-quan-ly-ton-kho-va-gia-von.md)
- [`KB-KGV-002` — Ranh giới trách nhiệm giữa các hệ thống nghiệp vụ](KB-KGV-002-ranh-gioi-trach-nhiem-giua-cac-he-thong-nghiep-vu.md)
- [`KB-KGV-033` — Thẻ kho, báo cáo lịch sử và đối soát nguồn](KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon.md)
