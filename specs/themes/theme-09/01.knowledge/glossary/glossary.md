# Theme 09 — Glossary

## 1. Quy ước ngôn ngữ

- Tài liệu nghiệp vụ/UI ưu tiên tiếng Việt; mã kỹ thuật giữ trong backtick khi cần.
- Không dùng “ledger” chung chung trong UI; chọn **Sổ kế toán**, **Sổ chi tiết**, **Bút toán** theo ngữ cảnh.
- Không dùng “transaction” để chỉ cả giao dịch nguồn lẫn database transaction.
- “Ghi sổ” là kết quả kế toán; “đồng bộ” chỉ là cơ chế truyền dữ liệu, không phải business result.

## 2. Thuật ngữ lõi

| Thuật ngữ chính thức | English/code | Định nghĩa VET45 | Không dùng lẫn với |
|---|---|---|---|
| Kế toán | Accounting | Miền ghi nhận, phân loại, kiểm soát và trình bày dữ liệu kế toán | Công nợ, Kho, HĐĐT |
| Sự thật kế toán | Accounting Fact | Sự thật từ source domain đã đủ ý nghĩa để Theme 09 xem xét ghi sổ | Bút toán |
| Ca ghi sổ | Accounting Case | Một lần xử lý một source version/purpose tới kết quả cuối | Technical delivery attempt |
| Ghi sổ | Posting | Chuyển fact thành accounting entry authoritative theo policy | Gửi event |
| Bút toán / Bản ghi kế toán | Accounting Entry | Kết quả kế toán đã post trong Theme 09 | Source transaction |
| Dòng bút toán | Accounting Entry Line | Thành phần chi tiết của entry theo scheme | Dòng đơn hàng |
| Chính sách ghi sổ | Posting Policy | Quy tắc chuyển fact thành entry | Chính sách giá |
| Chế độ kế toán | Accounting Scheme/Regime | Bộ yêu cầu kế toán áp dụng cho đối tượng/thời kỳ | Tax profile |
| Hồ sơ kế toán | Accounting Profile | Cấu hình kế toán hiệu lực của tenant | Legal profile |
| Kỳ kế toán | Accounting Period | Khoảng thời gian dùng để ghi/khóa dữ liệu kế toán | Kỳ thuế |
| Khóa kỳ | Period Lock | Chặn posting vào kỳ sau khi hoàn tất kiểm soát | Lock kỹ thuật |
| Mở lại kỳ | Period Reopen | Cho phép ghi lại vào kỳ đã khóa theo quyền và audit | Sửa entry |
| Ngày nghiệp vụ gốc | Source Effective Date | Ngày/thời điểm business source có hiệu lực | recorded_at |
| Ngày kế toán | Accounting Date | Ngày entry thuộc về kỳ kế toán | created_at |
| Thời điểm ghi nhận | Recorded At | Thời điểm hệ thống persist result | accounting date |
| Sổ kế toán | Accounting Book | Cách trình bày/projection theo chế độ kế toán | Accounting Entry store |
| Lần sinh sổ | Statutory Book Run | Một lần tạo snapshot sổ theo range/watermark | Live book view |
| Điều chỉnh kế toán | Accounting Adjustment | Entry mới sửa ảnh hưởng kế toán đã post | Edit entry cũ |
| Bút toán đảo | Reversal Entry | Entry mới triệt tiêu/đảo ảnh hưởng entry trước | Delete |
| Chứng từ điều chỉnh thủ công | Manual Accounting Document | Ý định điều chỉnh do user lập trước khi post | Accounting Entry |
| Đối chiếu | Reconciliation | Xác lập và xử lý sai lệch/unknown giữa nguồn và kế toán | Retry kỹ thuật |
| Ca đối chiếu | Reconciliation Case | Process record điều phối một mismatch | Business source owner |
| Số dư đầu kỳ kế toán | Accounting Opening Position | Dữ liệu khởi tạo accounting representation | Opening AR/AP/stock owner khác |
| Nguồn dữ liệu | Source Domain | Theme sở hữu sự thật nghiệp vụ | Theme 09 |
| Tham chiếu nguồn | Source Reference | Định danh object/version upstream | Copy aggregate |
| Bản chụp | Snapshot | Dữ liệu bất biến tại một mốc | Current master data |
| Phiên bản chính sách | Policy Version | Version rule hiệu lực đã dùng | App version |
| Dimension kế toán | Accounting Dimension | Chiều phân tích như cửa hàng/đối tác/sản phẩm | Aggregate owner |
| Mã tài khoản | Account Code | Mã tài khoản kế toán khi scheme yêu cầu | Book category |
| Nợ / Có | Debit / Credit | Hai phía của bút toán kép khi scheme áp dụng | Thu/Chi tiền |
| Danh mục sổ | Book Catalog | Tập loại sổ khả dụng theo scheme | Một sổ cụ thể |
| Hồ sơ thuế | Tax Profile | Classification và rule reference dùng cho nghĩa vụ thuế | Accounting Profile |
| Kỳ thuế | Tax Period | Khoảng thời gian của nghĩa vụ kê khai/tính thuế | Kỳ kế toán |
| Lần tính thuế | Tax Calculation Run | Kết quả tính có source watermark + policy version | Tax Return |
| Hồ sơ khai thuế | Tax Return | Business object quản lý nội dung khai theo loại/kỳ | Hóa đơn điện tử |
| Bản chụp hồ sơ khai | Tax Return Snapshot | Nội dung form/schema tại một version | Current tax profile |
| Nghĩa vụ thuế | Tax Obligation | Nghĩa vụ cần tính/khai/nộp theo rule | Công nợ thương mại |
| Dữ liệu tính thuế | Taxable Base/Input | Dữ liệu dùng cho phép tính thuế | Accounting amount mặc định |
| Trạng thái nghiệp vụ | Business Result | `POSTED/REJECTED/...` | Delivery status |
| Trạng thái truyền nhận | Delivery Status | queued/sent/ack/failed/unknown | Posting result |
| Kết quả chưa xác định | UNKNOWN | Không đủ bằng chứng để kết luận success/failure | FAILED |
| Cần đối chiếu | RECONCILIATION_NEEDED | Business state cần xác lập trước xử lý tiếp | Retry now |
| Kỳ đã khóa | PERIOD_LOCKED | Posting bị chặn bởi period state | System error |
| Từ chối ghi sổ | REJECTED | Source/policy invalid về nghiệp vụ | Transport error |
| Đã ghi sổ | POSTED | Theme 09 đã commit accounting result | Event acknowledged |

## 3. Cặp dễ nhầm

### Giao dịch nguồn vs Sự thật kế toán
Một SalesOrder có thể chứa rất nhiều dữ liệu; `AccountingFactSnapshot` chỉ giữ phần đã final và có ý nghĩa kế toán cho một purpose.

### Sự thật kế toán vs Bút toán
Fact trả lời **điều gì đã xảy ra**. Entry trả lời **được ghi sổ như thế nào theo policy nào**.

### Kỳ kế toán vs Kỳ thuế
Có thể trùng ngày nhưng khác purpose, state và rule. Không dùng một entity cho cả hai.

### Thu/Chi vs Nợ/Có
Thu/Chi là dòng tiền nghiệp vụ. Nợ/Có là cấu trúc hạch toán; không đồng nghĩa.

### Hóa đơn vs Doanh thu
Hóa đơn là chứng từ pháp lý/thuế do Theme 8 sở hữu. Doanh thu kế toán phải theo recognition policy từ source facts; không double count chỉ vì invoice xuất hiện.

### Sổ công nợ vs Sổ kế toán
Sổ công nợ/subledger authoritative thuộc Theme 6. Theme 09 có accounting representation liên quan nhưng không sở hữu số dư thương mại.

### Giá vốn dự kiến vs Giá vốn chính thức
Giá dự kiến phục vụ mô phỏng/quản trị không được tự post. Chỉ output authoritative đủ điều kiện từ Theme 7 mới vào official accounting.
