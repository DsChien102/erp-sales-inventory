# Glossary — Theme 10 Mua hàng

## 1. Chứng từ và giao dịch mua

| Thuật ngữ Việt chính thức | English / code | Định nghĩa VET45 | Không dùng / dễ nhầm |
|---|---|---|---|
| Nhà cung cấp (NCC) | Supplier | Đối tác bán hàng hóa/dịch vụ cho tổ chức; định danh gốc thuộc miền Đối tác | Không tạo “NCC nội bộ Theme 10” |
| Đơn mua | Purchase Order | Cam kết thương mại của tổ chức với một NCC về hàng, lượng, UOM, giá và điều kiện giao | “Phiếu nhập”, “đơn nhập kho” |
| Phiên bản đơn mua | Purchase Order Version | Ảnh bất biến của điều khoản đơn tại một lần xác nhận/thay đổi | Sửa đè lịch sử |
| Dòng đơn mua | Purchase Order Line | Một mặt hàng/UOM và điều kiện thương mại tương ứng trong phiên bản đơn | LOT thực nhận |
| Lượng còn được phép nhận | Receivable Quantity / Open Quantity | Phần còn lại theo cam kết mua mà Kho được phép dùng làm giới hạn nguồn nhận theo chứng từ | Không đồng nghĩa “còn tồn” |
| Tình hình giao hàng | Fulfillment | Góc nhìn Mua hàng về đã nhận, từ chối, còn phải giao và chênh lệch theo nguồn Kho | Không phải stock ledger |
| Chênh lệch giao hàng | Delivery Variance | Khác biệt giữa cam kết thương mại và kết quả nhận thực tế cần quyết định | Không tự đồng nghĩa lỗi kho |

## 2. Nhận hàng và nguồn Kho

| Thuật ngữ | English / code | Định nghĩa | Ranh giới |
|---|---|---|---|
| Lần nhận hàng | Receipt Operation | Một lần Kho ghi nhận nhận thực tế, có ID/version/trạng thái | Kho sở hữu |
| Lượng nhận đạt | Accepted Receipt Quantity | Lượng được Kho phân loại là đạt theo receipt | Chưa tự là lượng tính chiết khấu |
| Lượng từ chối | Rejected Quantity | Lượng không được tiếp nhận theo kết quả nhận | Không tăng tồn vật lý |
| Sửa/đảo lần nhận | Receipt Correction/Reversal | Thay đổi có truy vết làm điều chỉnh sự thật lần nhận | Mua hàng phải tính lại projection/assessment khi liên quan |

## 3. Hóa đơn và nghĩa vụ

| Thuật ngữ | English / code | Định nghĩa | Dễ nhầm |
|---|---|---|---|
| Hóa đơn nhà cung cấp | Supplier Invoice | Chứng từ NCC dùng để yêu cầu thanh toán/ghi nhận giá trị thương mại | Không đồng nghĩa file upload |
| Tiếp nhận hóa đơn | Invoice Intake | Ghi nhận tệp/thông tin ban đầu để bắt đầu xử lý | Chưa phát sinh nghĩa vụ mặc định |
| Hóa đơn đủ điều kiện | Qualified Supplier Invoice | Hóa đơn đã vượt các kiểm tra nghiệp vụ cần thiết để trở thành nguồn nghĩa vụ theo contract | Tiêu chí cuối còn Q-05 |
| Nguồn nghĩa vụ phải trả | Payable Source | Chứng từ/phiên bản từ Mua hàng được phép bàn giao sang Công nợ | Không phải số dư phải trả |
| Nghĩa vụ phải trả | Payable Obligation | Khoản Công nợ quản lý sau khi nhận nguồn hợp lệ | Mua hàng không sở hữu balance |
| Giá trị thương mại | Commercial Amount | Giá trị trên chứng từ/điều chỉnh với NCC | Không mặc nhiên bằng giá trị kho |

## 4. Trả nhà cung cấp

| Thuật ngữ | English / code | Định nghĩa | Dễ nhầm |
|---|---|---|---|
| Yêu cầu trả nhà cung cấp | Supplier Return Case | Hồ sơ thương mại xác định hàng nào được đề nghị/cho phép trả và lý do | Không phải movement xuất kho |
| Bàn giao vật lý | Physical Handover | Kho xác nhận hàng đã rời quyền kiểm soát vật lý theo quy trình trả | Chưa chứng minh NCC giảm tiền |
| Kết quả thương mại | Commercial Outcome | Kết quả NCC chấp nhận/từ chối/điều chỉnh giá trị cho hàng trả | Có thể đến sau bàn giao vật lý |
| Điều chỉnh nghĩa vụ | Payable Adjustment | Thay đổi hợp lệ lên nghĩa vụ phải trả tại Công nợ dựa trên nguồn thương mại đủ điều kiện | Không thực hiện trực tiếp trong Theme 10 |

## 5. Chương trình chiết khấu mua hàng

| Thuật ngữ | English / code | Định nghĩa | Dễ nhầm |
|---|---|---|---|
| Chương trình chiết khấu mua hàng | Purchase Discount Program | Thỏa thuận theo kỳ với NCC về điều kiện đạt và quyền lợi thương mại | Không gọi chung là “giảm giá đơn hàng” |
| Phiên bản chương trình | Discount Program Version | Bộ điều khoản có hiệu lực tại một giai đoạn cụ thể | Không sửa đè |
| Kỳ chương trình | Program Period | Khoảng thời gian dùng để xét điều kiện và tổng kết | Không mặc định bằng tháng/quý |
| Ngưỡng | Threshold | Mức phải đạt theo basis của chương trình để mở bậc quyền lợi | Có thể có nhiều bậc |
| Căn cứ tính ngưỡng | Qualification Basis | Loại giao dịch/sự kiện được dùng để cộng tiến độ | Không mặc định mọi lần nhập đều tính |
| Phạm vi đủ điều kiện | Eligibility Scope | NCC/sản phẩm/nhóm/UOM/giao dịch được xét | Không phải toàn bộ danh mục NCC |
| Lượng đủ điều kiện thực tế | Actual Eligible Quantity | Phần dữ liệu thực tế đã được Theme 10 xác định là đáp ứng điều khoản | Khác “lượng nhận đạt” |
| Tiến độ đã xác nhận | Confirmed Progress | Mức đạt hiện tại tính từ dữ liệu thực tế đủ điều kiện | Không chứa kế hoạch tương lai |
| Phần còn thiếu | Remaining To Threshold | Khoảng cách từ tiến độ thực tế tới ngưỡng mục tiêu theo program version | Không phải open PO quantity |
| Dự báo mức đạt | Forecasted Attainment | Kết quả kịch bản đến cuối kỳ dựa trên actual + dữ liệu dự kiến/giả định | Không phải cam kết của NCC |
| Lợi ích thương mại dự kiến | Expected Commercial Benefit | Khoản giảm giá/lợi ích ước tính theo kịch bản và điều khoản, đã phân bổ có nguồn | Không phải quyền lợi thực tế |
| Quyền lợi đã phát sinh | Earned Benefit | Quyền lợi đã vượt mốc business cần thiết theo điều khoản và bằng chứng | Chưa mặc định đủ để ghi sổ nếu thiếu chứng từ |
| Quyền lợi đủ căn cứ ghi nhận | Recognizable Benefit | Quyền lợi có đủ căn cứ để chuyển thành thành phần giá/nghĩa vụ theo contract | Khác forecast |

## 6. Giá và định giá

| Thuật ngữ | English / code | Định nghĩa | Ranh giới |
|---|---|---|---|
| Giá mua trên đơn | Ordered Purchase Price | Giá thương mại tại phiên bản Đơn mua | Không mặc nhiên là invoice price/cost |
| Giá trên hóa đơn | Invoiced Purchase Price | Giá trị đơn vị/thành phần giá theo hóa đơn NCC | Có thể khác PO |
| Giá nhập dự kiến | Expected Receipt Cost | Kết quả mô phỏng của Kho/Giá vốn từ benefit dự kiến và bối cảnh tồn | Không ghi sổ |
| Giá vốn bình quân dự kiến | Expected Average Cost | Bình quân giả lập theo phương pháp giá vốn và scenario | Không phải Official Cost |
| Giá vốn chính thức | Official Cost | Giá trị do miền Kho/Giá vốn xác lập từ sự kiện/chứng từ thực tế | Mua hàng không sở hữu |
| Giá cơ sở | Pricing Base | Thuật ngữ tạm cho giá tham chiếu dùng bởi miền Định giá bán | Q-07 chưa chốt nghĩa cuối |

## 7. Quy ước dùng từ

- UI/BA: ưu tiên **Đơn mua**, **Hóa đơn NCC**, **Trả NCC**, **Chương trình chiết khấu**, **Tiến độ**, **Dự báo**.
- Technical IDs: được dùng `PurchaseOrder`, `SupplierInvoice`, `SupplierReturnCase`, `PurchaseDiscountProgram`, `DiscountAssessment`.
- Không dùng “dự báo đã đạt”, “chiết khấu chắc chắn”, “giá vốn mới” cho dữ liệu dự kiến.
- Khi một số chưa phải thực tế, label phải có từ **dự kiến**, **kịch bản** hoặc **tạm tính** phù hợp.
