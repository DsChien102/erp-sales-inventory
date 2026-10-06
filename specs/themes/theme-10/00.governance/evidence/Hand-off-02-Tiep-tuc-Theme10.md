# Hand-off 02 — Tiếp tục Theme 10 trên luồng mới

**Ngày:** 23/09/2026  
**Theme:** 10 — Mua hàng, dự án VET45 Mobile App.  
**Mốc tạm chốt:** baseline phạm vi v0.1.1, freeze `T10-SCOPE-2026-09-23-01`.  
**Trạng thái:** Đã chốt mục tiêu, quyền sở hữu và danh mục năm Business Journey. Công thức và quy tắc trong các câu hỏi mở chưa được chốt.

## 1. Lệnh tiếp tục cho luồng mới

Tiếp tục Theme 10 từ `VET45-Theme10-Mua-hang-v0.1.1.zip` đính kèm. Đọc baseline và hand-off này, kế thừa các quyết định đã xác nhận. Bắt đầu bằng việc làm rõ điều khoản chương trình chiết khấu, ưu tiên Q-01, rồi Q-02/03/04/08; đồng thời chuẩn bị các phần không phụ thuộc của BJ-01/02. Chốt quy tắc trước khi hoàn thiện phép tính và các nhánh nghiệp vụ phụ thuộc. Khi có thay đổi semantic, tạo phiên bản cumulative mới từ v0.1.1 và ghi vùng tác động.

Hand-off này ghi lại điểm dừng, không tạo một phiên bản baseline mới hoặc ngầm đóng các câu hỏi mở.

## 2. Tài liệu cần mang sang

| Tệp | Vai trò |
|---|---|
| `VET45-Theme10-Mua-hang-v0.1.1.zip` | Nguồn canonical cấp phạm vi của Theme 10. |
| `Theme10-goi-review-01-ranh-gioi-va-ban-do-hanh-trinh.md` | Hồ sơ lập luận/đối chiếu nguồn, đã đồng bộ v0.1.1; đọc khi cần lý do và ví dụ. |
| `Hand-off-01-Theme7-tich-hop-Theme10.md` | Yêu cầu phía Theme 7 cần tiếp nhận; việc nâng cấp Theme 7 chưa được thực hiện trong luồng này. |
| `Hand-off-02-Tiep-tuc-Theme10.md` | Bản tóm tắt để tiếp tục luồng mới. |

**Chuỗi phiên bản:** v0.1.0 là baseline đầu tiên, không có parent → v0.1.1 có parent v0.1.0. Câu “Theme 10 bắt đầu mới, parent không có” trong D-01 nói về lần khởi tạo, không phải parent của v0.1.1.

**SHA-256 v0.1.1:** `2b76f6f78dee1d9e075cdb86f9c53707e0b23fd3f2271df2a8e62cc9b3223570`.

Nguồn tham chiếu đã đọc: Theme 6 `VET45-Cong-no-v2.1.3.zip`; Theme 7 `VET45-Theme7-Harness-v3.10.1-template-aligned.zip` và `VET45-Theme7-Prototype-Harness-v3.10.1.zip`. Checksum và thẩm quyền nằm trong source-register. Nếu cần thay đổi contract liên Theme, đối chiếu thêm baseline hiện hành của Theme đó; các số phiên bản trên chỉ là nguồn đã đọc ở lần phân tích này.

## 3. Những gì đã làm và chưa làm

Baseline gồm tám tài liệu Markdown: README, VERSION, source-register, decision-register, open-question-register, assumption-register, overview và `00-business-journey-map`; kèm manifest SHA-256.

Đã có: phạm vi, ranh giới, mười quyết định D-01–D-10, mười câu hỏi Q-01–Q-10, bốn giả định A-01–A-04 và danh mục năm BJ. Đã kiểm tra liên kết, thành phần ZIP và tính nhất quán owner khi phát hành v0.1.1.

Chưa có: từng BJ chi tiết/Trường hợp sử dụng, mô hình dữ liệu hoàn chỉnh, hợp đồng API/event/error/idempotency/permission/NFR, UI Flow/screen/component contracts, prototype mobile, bộ glossary/wiki đầy đủ, quiz hoặc presentation Theme 10. Đây là baseline phạm vi, chưa phải một Theme package hoàn chỉnh.

## 4. Các quyết định phải kế thừa

| Nhóm | Nội dung |
|---|---|
| Mua và nhận hàng — D-02 | Theme 10 sở hữu đơn mua/phiên bản và quyết định thương mại; Theme 7 sở hữu nhận thật, tồn/lô/trạng thái và giá trị kho. Đặt mua không tự tăng tồn; nhập nhanh không sinh PO giả. |
| Nguồn nền — D-04 | NCC/đối tác thuộc Theme 3; sản phẩm/UOM/chính sách lô thuộc Theme 2. Theme 10 dùng định danh chuẩn, lưu bản chụp cần thiết. |
| Hóa đơn và công nợ — D-03/09 | Theme 10 sở hữu hóa đơn và nguồn nghĩa vụ. Theme 6 giữ nghĩa vụ/số dư phải trả, chi/phân bổ; Theme 9 giữ sổ/kỳ. Mốc “Nhận hóa đơn NCC” cần định nghĩa điều kiện chính xác. |
| Trả NCC — D-10 | Mua hàng quyết định thương mại; Kho xác nhận bàn giao/giảm tồn theo nguồn hợp lệ. Bàn giao vật lý chưa tự chứng minh NCC đã chấp nhận giảm tiền. |
| Chương trình — D-05/06 | Có chương trình kỳ hiện tại và tương lai. Chỉ sau khi đạt ngưỡng theo điều khoản mới có thể hưởng thực tế. Đạt ngưỡng, xác nhận quyền lợi và đủ căn cứ ghi nhận là các mốc cần phân biệt. |
| Tiến độ và dự báo — D-05/07 | Theme 10 sở hữu tiến độ thực tế, phần thiếu, dự đoán mức đạt và tính/phân bổ lợi ích thương mại dự kiến. Theme 7 cấp thống kê có nguồn theo từng lần nhập; Mua hàng xác định phần đủ điều kiện. |
| Giá dự kiến — D-07/08 | Theme 7 nhận đầu vào dự kiến từ Theme 10 để mô phỏng giá nhập/bình quân; người có quyền dùng kết quả để cân nhắc giá cơ sở sớm. Miền Định giá bán quyết định tham chiếu và công bố giá bán. |

**Sửa sai đã hoàn tất ở v0.1.1:** diễn giải cũ giao việc dự đoán mức đạt chiết khấu cho Theme 7 đã bị thay thế bởi U-03. Không mang diễn giải đó sang luồng mới.

Bản outbound tạm `theme-10-purchase/` trong Theme 7 chỉ là tham khảo lịch sử. BJ-05 hiện bao quát chương trình đang chạy, kỳ tương lai, tiến độ thật và dự báo; không sao chép nguyên trạng phạm vi cũ chỉ mô phỏng trước PO.

## 5. Danh mục năm hành trình đã đồng ý

| ID | Hành trình | Kết quả tại ranh giới Theme 10 |
|---|---|---|
| BJ-01 | Lập và xác nhận đơn mua | Nguồn đặt mua hợp lệ hoặc dừng/hủy có căn cứ, sửa có phiên bản. |
| BJ-02 | Theo dõi giao hàng và xử lý chênh lệch | Phản ánh từng lần nhận, phần còn phải giao và quyết định với sai lệch. |
| BJ-03 | Tiếp nhận và xử lý hóa đơn NCC | Hóa đơn đủ điều kiện/chờ/từ chối; nguồn nghĩa vụ hợp lệ bàn giao Theme 6 đúng một lần. |
| BJ-04 | Xử lý trả hàng cho NCC | Phạm vi trả có thẩm quyền, kết quả vật lý và thương mại được đối chiếu. |
| BJ-05 | Quản lý chương trình chiết khấu theo kỳ | Điều khoản, tiến độ và dự báo có nguồn/phiên bản; quyền lợi thực tế xác lập theo căn cứ; cuối kỳ có kết quả đối chiếu. |

Đây là danh mục, mục tiêu và ranh giới; chưa phải luồng chi tiết đã phê duyệt. Hóa đơn có thể đến trước/sau lần nhận; chương trình có thể bắt đầu trước PO. BJ-04 không phải bước cuối bắt buộc của mọi giao dịch mua.

## 6. Câu hỏi còn mở

| ID | Nội dung cần chốt | Chủ trì quyết định / phụ thuộc |
|---|---|---|
| Q-01 | Ưu đãi hồi tố cả kỳ hay chỉ phần sau/vượt ngưỡng; nhiều bậc hay không? | Business Owner/BA Theme 10; chặn công thức BJ-05. |
| Q-02 | Giao dịch/mốc nào tính ngưỡng; trả/hủy/sửa ảnh hưởng ra sao? | Theme 10 cùng owner nguồn; Kho cung cấp số thực nhập. |
| Q-03 | Bằng chứng nào xác lập quyền lợi thật sau khi đạt? | Theme 10, phối hợp Theme 7/6/9. |
| Q-04 | Phạm vi sản phẩm/nhóm/NCC, UOM, tiền/%/hàng tặng và quy tắc phân bổ? | Theme 10; ảnh hưởng đầu vào mô phỏng Theme 7. |
| Q-05 | “Nhận hóa đơn NCC” đủ điều kiện xác lập nghĩa vụ khi nào? | Theme 10 và Theme 6. |
| Q-06 | Căn cứ và người xác nhận giảm phải trả khi trả NCC? | Theme 10/6/7/9; hòa giải `T7-DR-054`. |
| Q-07 | “Giá cơ sở” là lớp giá nào? | Business Owner và miền Định giá bán/Theme 7. |
| Q-08 | Phương pháp dự báo, kỳ, nguồn kế hoạch, cảnh báo/rà soát khi không đạt? | Theme 10; Theme 7 tiêu thụ đầu ra. |
| Q-09 | Không có PO, hóa đơn trước hàng, hóa đơn dịch vụ và trả trước trong phạm vi nào? | Theme 10 phối hợp Theme 6/7. |
| Q-10 | Ai được lập/xác nhận/sửa/hủy từng chứng từ và chương trình? | Business Owner/BA Theme 10. |

Các câu hỏi chưa có thời hạn chốt được Business Owner xác nhận. Mốc cần giải quyết là trước khi đặc tả/triển khai phần phụ thuộc tương ứng.

**Giả định còn hiệu lực:** A-01 tạm hiểu giá cơ sở là giá vốn tham chiếu định giá; A-02 20%/xxx chỉ là ví dụ; A-03 chương trình tương lai không mặc nhiên tính mua kỳ hiện tại; A-04 chưa có phương pháp thì chưa sinh xác suất đạt bằng phần trăm. A-01 cần được kiểm tra ở Q-07; A-03 phụ thuộc Q-02/04; A-04 phụ thuộc Q-08.

## 7. Trình tự tiếp tục đề xuất

1. Đọc nguồn theo thứ tự README → VERSION → source/decision registers → overview/BJ map → open questions/assumptions. Nếu thiếu ZIP, lấy đúng v0.1.1 trước khi sửa artifact.
2. Chuẩn bị lựa chọn và ví dụ để chốt Q-01 trước, rồi Q-02/03/04/08. Ghi câu trả lời vào quyết định canonical theo nhóm nghiệp vụ và cập nhật mọi tham chiếu liên quan.
3. Làm rõ Q-05/06/09/10 cho mua, hóa đơn và trả NCC; nhận phản hồi hợp đồng từ luồng Theme 7. Các phần độc lập có thể tiến hành song song về công việc, không buộc toàn Theme chờ BJ-05.
4. Viết từng BJ/Trường hợp sử dụng với start/end, owner, basic/alternate/exception flow, failure/recovery, handoff và acceptance. Dùng “Trường hợp sử dụng” trong tiếng Việt; BF-01, BF-02…; AF-A-01/EF-A-01…; reference từ bước rẽ tới nhánh và điểm quay lại/kết thúc.
5. BA khóa nghĩa nghiệp vụ; SA đặc tả data/API/event/error/idempotency/permission/NFR và traceability. Sau đó viết UI Flow → Screen/Component contracts → prototype mobile có Inspect theo DS có thẩm quyền được xác nhận ở bước thiết kế.
6. Hoàn thiện know-how, quiz/presentation và kiểm định parity khi phạm vi tương ứng đã sẵn sàng. Mỗi bản phát hành có parent, impact set và bằng chứng kiểm tra.

**Gợi ý câu hỏi đầu tiên:** “Một chương trình đạt ngưỡng sẽ giảm cho toàn bộ lượng đủ điều kiện trong kỳ, chỉ phần sau/vượt ngưỡng, hay hỗ trợ cả hai kiểu theo điều khoản từng chương trình?” Đây là câu hỏi còn mở, chưa có đáp án mặc định.

## 8. Quy tắc tiếp nối

- Mọi phiên bản mới kế thừa toàn bộ baseline trước đó; bảo toàn artifact ngoài vùng tác động.
- Quyết định hợp nhất theo nhóm nghiệp vụ; lịch sử thay đổi ghi qua version/supersession, không tách các sổ quyết định rời theo từng version.
- Dữ liệu dự kiến phải có nhãn, phiên bản và giả định; không dùng làm quyền lợi thực tế hoặc giá vốn ghi sổ.
- Công thức hưởng chiết khấu, phương pháp dự báo và API còn mở phải được thể hiện rõ, không biến fixture/prototype thành quyết định.
- Khi cập nhật liên Theme, ghi nhận nơi đã tiếp nhận, nơi còn chờ và câu hỏi chưa thống nhất. Hand-off 01 là yêu cầu cho Theme 7, chưa là bằng chứng tích hợp đã hoàn tất.
