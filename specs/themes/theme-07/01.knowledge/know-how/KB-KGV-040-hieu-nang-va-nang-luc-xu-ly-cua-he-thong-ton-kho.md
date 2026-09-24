---
id: KB-KGV-040-hieu-nang-va-nang-luc-xu-ly-cua-he-thong-ton-kho
type: know-how
theme: theme-07
title: hieu-nang-va-nang-luc-xu-ly-cua-he-thong-ton-kho
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-040-hieu-nang-va-nang-luc-xu-ly-cua-he-thong-ton-kho — hieu-nang-va-nang-luc-xu-ly-cua-he-thong-ton-kho

## 1. Bối cảnh

### Câu trả lời ngắn

Dưới tải chuẩn, truy vấn khả dụng phải đạt p95 không quá 300 ms; giữ hoặc xuất đạt p95 không quá 1 giây và p99 không quá 2 giây. Batch lớn được xử lý bất đồng bộ thay vì giữ một request tương tác dài. Mỗi đơn vị vận hành phải hỗ trợ tối thiểu 100 phiên đồng thời, 50 operation thay đổi tồn mỗi giây và 10 triệu dòng movement mỗi năm. Các mục tiêu này không cho phép đánh đổi tính toàn vẹn: tải cao vẫn không được làm trùng, mất movement, bỏ chống xuất âm hoặc tách transaction nguyên tử.

### Vì sao vấn đề này quan trọng?

Số trung bình có thể đẹp trong khi nhóm 5% giao dịch chậm nhất làm checkout không sử dụng được, nên mục tiêu cần được nêu bằng phân vị. Năng lực xử lý cũng không chỉ là số request/giây; hệ thống kho phải duy trì idempotency, khóa cạnh tranh và commit set dưới tải. Nếu tối ưu bằng cách bỏ kiểm tra hoặc ghi bất đồng bộ các phần của transaction, hiệu năng tăng trên biểu đồ nhưng số dư mất tin cậy. Tách batch lớn khỏi luồng tương tác giúp bảo vệ độ trễ mà vẫn có identity và khả năng theo dõi.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Không được hiểu là |
|---|---|---|
| Độ trễ phân vị | Ngưỡng mà một tỷ lệ xác định yêu cầu phải hoàn tất nhanh hơn hoặc bằng. | Giá trị trung bình che các yêu cầu chậm. |
| Năng lực xử lý | Mức tải tối thiểu hệ thống phải chịu mà không mất tính toàn vẹn. | Quyền bỏ qua kiểm tra khi tải cao. |

### Quy tắc vận hành

#### Mục tiêu độ trễ và xử lý batch lớn

Tải chuẩn: availability `p95 ≤ 300 ms`; giữ/xuất `p95 ≤ 1 s`, `p99 ≤ 2 s`; batch lớn xử lý bất đồng bộ.
#### Năng lực tối thiểu không làm mất tính toàn vẹn

Mỗi đơn vị vận hành tối thiểu 100 phiên đồng thời, 50 operation thay đổi tồn/giây và 10 triệu movement line/năm; tải không được gây trùng/mất movement.

### Ví dụ xuyên suốt

Một bài kiểm thử tải mô phỏng 100 phiên đồng thời trên một đơn vị vận hành, với truy vấn khả dụng và 50 operation giữ/xuất mỗi giây. Kết quả đạt khi ít nhất 95% truy vấn khả dụng hoàn tất trong 300 ms, 95% operation mutation trong 1 giây và 99% trong 2 giây, đồng thời số movement tạo ra đúng bằng số operation thành công. Một batch import lớn được nhận bằng job ID và xử lý bất đồng bộ; người dùng theo dõi trạng thái thay vì chờ HTTP nhiều phút. Nếu độ trễ đạt nhưng xuất hiện movement trùng khi retry hoặc mất outbox event sau commit, bài kiểm thử vẫn thất bại vì invariant quan trọng hơn con số tốc độ.

Ví dụ này chỉ minh họa cách áp dụng các quy tắc đã nêu. Con số, tên sản phẩm và thời điểm là giả định; chúng không tạo thêm một ngoại lệ, quyền phê duyệt hay mốc ghi nhận mới.

### Ngoại lệ và những cách làm sai

- **Chỉ báo cáo độ trễ trung bình:** Trung bình che tail latency; mục tiêu đã quy định p95 và p99.
- **Bỏ khóa hoặc idempotency để đạt throughput:** Năng lực chỉ được công nhận khi không tạo trùng, mất hoặc sai movement.
- **Xử lý batch lớn trong request đồng bộ:** Batch cần job bất đồng bộ có identity, trạng thái và kết quả đối soát.

- **Sửa trực tiếp số dư hoặc trạng thái để “làm cho đúng”:** cách này phá vỡ sổ biến động và làm mất khả năng giải thích số liệu. Mọi thay đổi chính thức phải đi qua đúng loại nghiệp vụ, có căn cứ và lịch sử.
- **Dùng dữ liệu tra cứu chậm làm căn cứ commit:** báo cáo hoặc projection có thể hữu ích để quan sát, nhưng quyết định thay đổi tồn phải kiểm tra lại dữ liệu giao dịch hiện hành.

## 3. Ý nghĩa đối với Theme

### Cách áp dụng trong thực tế

Mục tiêu hiệu năng phải được kiểm chứng dưới tải chuẩn và tải cạnh tranh, đồng thời giữ nguyên invariant nghiệp vụ. Tối ưu hóa không được tách transaction hoặc bỏ kiểm tra idempotency. Batch lớn chuyển sang xử lý bất đồng bộ có identity, trạng thái và khả năng đối soát thay vì giữ giao dịch tương tác quá lâu.

Khi triển khai một trường hợp cụ thể, người xử lý nên ghi rõ nguồn chứng từ, đối tượng hàng, kho, trạng thái, thời điểm nghiệp vụ và kết quả mong đợi. Nếu một dữ kiện thuộc thẩm quyền của hệ thống khác chưa có, hồ sơ phải dừng ở trạng thái an toàn thay vì tự suy đoán. Nếu một bước có thể ảnh hưởng đồng thời đến nhiều số dư hoặc cả số lượng lẫn giá trị, toàn bộ thay đổi phải được commit nguyên tử và để lại dấu vết đối soát.

### Điều cần ghi nhớ

- **Availability p95 ≤ 300 ms; giữ/xuất p95 ≤ 1 s và p99 ≤ 2 s.**
- **Quy mô tối thiểu là 100 phiên đồng thời và 50 mutation/giây cho mỗi đơn vị vận hành.**
- **Hệ thống phải chịu 10 triệu dòng movement mỗi năm cho mỗi đơn vị vận hành.**
- **Không chỉ tiêu hiệu năng nào cho phép hy sinh tính nguyên tử hoặc toàn vẹn ledger.**

- **Khi không đủ bằng chứng để đi tiếp, hệ thống phải thất bại an toàn và giữ nguyên dữ liệu có thẩm quyền.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-040` |
| Cụm tri thức | [`KGV-C10`](00-table-of-contents.md#c10-vận-hành-phục-hồi-và-thay-đổi) |
| Loại bài | `NON_FUNCTIONAL` |
| Quy tắc quản trị | [`PERFORMANCE_SLO`](../../02.specification/technical-contracts/FND-TECH-01.md#nfr-hieu-nang), [`CAPACITY_TARGET`](../../02.specification/technical-contracts/FND-TECH-01.md#nfr-nang-luc-xu-ly) |
| Trạng thái quyết định | `ACTIVE` |
| Mức bằng chứng của bài | `STATIC_VALIDATED` |
| Giới hạn | Bài nêu mục tiêu phi chức năng tối thiểu; không quy định topology triển khai, kích thước hạ tầng, bộ dữ liệu benchmark hoặc kế hoạch capacity theo từng khách hàng |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-029` — Tính nguyên tử khi ghi tồn kho và phát sự kiện](KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md)
- [`KB-KGV-032` — Movement ledger, số dư dẫn xuất và phục hồi sau sự cố](KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md)
- [`KB-KGV-033` — Thẻ kho, báo cáo lịch sử và đối soát nguồn](KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon.md)
