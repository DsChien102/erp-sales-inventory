# Open Question Register — Theme 10 Mua hàng

> Tất cả câu hỏi dưới đây còn `OPEN` hoặc `PROPOSED_RESOLUTION`; chưa câu nào được tự đóng trong v0.2.0.

| ID | Câu hỏi | Trạng thái v0.2.0 | Đề xuất để review | Chặn artifact |
|---|---|---|---|---|
| Q-01 | Ưu đãi hồi tố cả kỳ hay chỉ phần sau/vượt ngưỡng; nhiều bậc hay không? | PROPOSED_RESOLUTION | Hỗ trợ cả `toàn kỳ sau khi đạt` và `chỉ phần vượt`, cấu hình theo từng chương trình; hỗ trợ nhiều bậc theo điều khoản | Công thức BJ-05, AGG-PUR-04/05 |
| Q-02 | Giao dịch/mốc nào tính ngưỡng; trả/hủy/sửa ảnh hưởng ra sao? | PROPOSED_RESOLUTION | Mỗi chương trình khai báo `căn cứ tính ngưỡng`; khuyến nghị mặc định là lượng nhận đạt đã xác nhận, có bù trừ sửa/đảo; không hard-code toàn hệ thống | Progress model, handoff Kho → Mua hàng |
| Q-03 | Bằng chứng nào xác lập quyền lợi thật sau khi đạt? | OPEN | Tách 3 mốc: đạt ngưỡng → NCC xác nhận/quyền lợi được chấp nhận → đủ chứng từ để ghi nhận giá trị/công nợ | BJ-05, invoice/cost handoff |
| Q-04 | Phạm vi sản phẩm/nhóm/NCC, UOM, tiền/%/hàng tặng và phân bổ? | PROPOSED_RESOLUTION | Program Version có scope rõ; Phase đầu ưu tiên giảm %/số tiền; hàng tặng để `FUTURE_CANDIDATE` nếu chưa cần | Glossary, Discount Program |
| Q-05 | “Nhận hóa đơn NCC” đủ điều kiện xác lập nghĩa vụ khi nào? | PROPOSED_RESOLUTION | Không phải lúc upload file; dùng mốc `Hóa đơn đủ điều kiện` sau kiểm tra nghiệp vụ tối thiểu. Tiêu chí thuế/pháp lý chi tiết còn phụ thuộc miền liên quan | BJ-03, Supplier Invoice |
| Q-06 | Căn cứ và người xác nhận giảm phải trả khi trả NCC? | OPEN | Bàn giao vật lý chỉ là một bằng chứng; cần xác nhận thương mại/chứng từ điều chỉnh trước khi Công nợ thay đổi nghĩa vụ | BJ-04, cross-theme reconciliation |
| Q-07 | “Giá cơ sở” là lớp giá nào? | OPEN | Tạm giữ nghĩa `giá vốn tham chiếu phục vụ định giá`; miền Định giá bán phải xác nhận | Pricing handoff |
| Q-08 | Phương pháp dự báo, kỳ, nguồn kế hoạch, cảnh báo khi không đạt? | PROPOSED_RESOLUTION | Forecast theo kịch bản có version: actual eligible + open commitment + optional plan; không sinh xác suất % nếu chưa có model xác suất | AGG-PUR-05 |
| Q-09 | Không có Đơn mua, hóa đơn trước hàng, hóa đơn dịch vụ và trả trước trong phạm vi nào? | PROPOSED_RESOLUTION | Không có Đơn mua và hóa đơn trước hàng được hỗ trợ; không tạo Đơn mua bù bắt buộc. Hóa đơn dịch vụ/trả trước tách scope review riêng | BJ-03, invoice model |
| Q-10 | Ai được lập/xác nhận/sửa/hủy từng chứng từ và chương trình? | OPEN | Định nghĩa role/policy sau khi actor model được khóa; baseline này chỉ nêu action cần phân quyền | Permission contract |

## Thứ tự chốt đề xuất

`Q-01 → Q-02 → Q-04 → Q-08 → Q-03 → Q-05 → Q-06 → Q-09 → Q-10 → Q-07`.
