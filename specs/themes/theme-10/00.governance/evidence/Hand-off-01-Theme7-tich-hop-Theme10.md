# Hand-off 01 — Theme 7 nâng cấp tích hợp với Theme 10

**Ngày:** 23/09/2026  
**Nguồn bàn giao:** Theme 10 — Mua hàng v0.1.1; freeze `T10-SCOPE-2026-09-23-01`.  
**Trạng thái:** Bàn giao yêu cầu nghiệp vụ và vùng tác động. Theme 7 chưa được sửa trong lượt này; API/sự kiện/công thức chi tiết chưa phải hợp đồng đã chốt.

## 1. Lệnh tiếp nhận cho luồng Theme 7

Tiếp tục Theme 7 trên bản cumulative hiện hành đã được chấp nhận trong luồng Theme 7. Đọc hand-off này và baseline Theme 10 v0.1.1, lập impact set rồi cập nhật các artifact liên quan để tiếp nhận phân vai mới. Xác định parent thực tế trước khi chọn số phiên bản tiếp theo; không mặc định v3.10.1 là bản mới nhất.

Bộ Theme 7 đã dùng để đối chiếu ở phía Theme 10 là `VET45-Theme7-Harness-v3.10.1-template-aligned.zip` và `VET45-Theme7-Prototype-Harness-v3.10.1.zip`. Đây là nguồn đã đọc tại thời điểm bàn giao. Khi parent mới hơn có thay đổi liên quan, đối chiếu và ghi nhận khác biệt trước khi tích hợp.

## 2. Quyết định cần tiếp nhận

| Chủ thể | Trách nhiệm |
|---|---|
| Theme 7 — Kho | Ghi nhận sự thật từng lần nhập: hàng, số lượng, UOM, lô/trạng thái, thời điểm, điều chỉnh/đảo; cung cấp thống kê có nguồn cho Mua hàng. |
| Theme 10 — Mua hàng | Quản lý chương trình, điều khoản/kỳ/phiên bản; xét lượng đủ điều kiện, theo dõi tiến độ thật và phần còn thiếu; dự đoán mức đạt, tính/phân bổ lợi ích thương mại dự kiến. |
| Theme 7 — Giá vốn | Nhận đầu vào dự kiến từ Theme 10; kết hợp bối cảnh tồn và phương pháp giá vốn để mô phỏng giá nhập và giá vốn bình quân dự kiến. |
| Miền Định giá bán | Quyết định chọn giá vốn tham chiếu, rà soát giá cơ sở và công bố giá bán. |
| Theme 6 / Theme 9 | Theme 6 giữ nghĩa vụ/số dư phải trả và thu chi/phân bổ; Theme 9 giữ sổ và kỳ kế toán. |

Xác nhận mới nhất của Business Owner: **tiến độ thực tế và dự đoán mức đạt chiết khấu do Theme Mua hàng kiểm soát; Theme Kho cung cấp con số thống kê theo từng lần nhập**. Phát biểu này thay thế diễn giải cũ giao dự báo đạt ngưỡng cho Theme 7.

Mục tiêu: chương trình kỳ hiện tại hoặc tương lai có thể được ước tính sớm, để cân nhắc giá cơ sở ngay trong kỳ. Ưu đãi thực tế chỉ có thể áp dụng sau khi đạt điều kiện. Ví dụ 20% và ngưỡng xxx chỉ minh họa, không phải hằng số hệ thống.

## 3. Ba điểm bàn giao phải đặc tả

Các trường dưới đây là yêu cầu về nghĩa dữ liệu; tên trường, schema, transport và cơ chế đồng bộ do BA/SA hai Theme chốt sau.

| Chiều | Dữ liệu cần có | Quy tắc |
|---|---|---|
| Kho → Mua hàng: từng lần nhập và thay đổi | Định danh lần nhập/operation và dòng; phiên bản, trạng thái xác nhận; NCC; liên kết nguồn mua nếu có; sản phẩm/UOM; thời điểm; lượng và phân loại; quan hệ sửa/đảo; căn cứ tra cứu. | Thống kê truy được về từng lần nhập. Phân biệt nhập thật với kết quả chưa rõ. Gửi lại không cộng thêm tiến độ; sửa/đảo tham chiếu nguồn cũ. Lượng nhập chưa tự đồng nghĩa lượng đủ ngưỡng. |
| Mua hàng → Kho: kết quả dự báo | Chương trình/phiên bản/kỳ; phiên bản dự báo và thời điểm; tiến độ đủ điều kiện, phần còn thiếu; kịch bản/giả định có nguồn; lợi ích thương mại dự kiến phân bổ theo sản phẩm/lần mua; phạm vi/hiệu lực. | Theme 10 tính mức đạt và điều kiện chương trình. Theme 7 kiểm tra, tiêu thụ kết quả; không duy trì bộ tính ngưỡng độc lập. Thiếu quy tắc phân bổ thì chưa đủ căn cứ cho một giá dự kiến duy nhất. |
| Kho → Định giá bán: giá mô phỏng | Giá nhập và bình quân dự kiến; phiên bản dự báo Theme 10; bối cảnh tồn, phương pháp và thời điểm mô phỏng; điều kiện áp dụng. | Kết quả dự kiến có nhãn và truy vết. Đổi dự báo dẫn tới kết quả mô phỏng mới, rà soát tham chiếu đã dùng; không âm thầm viết lại giá bán đã công bố. |

Chốt thêm cách xử lý nguồn đến chậm, sai thứ tự, nguồn bị sửa và kết quả chưa rõ. Khi chưa có dữ liệu đủ tin cậy, thể hiện thiếu/cũ/chờ xác minh theo contract được duyệt; không tự thay bằng 0 hoặc coi dự báo cũ còn hiệu lực. Đây là yêu cầu cần thiết kế, chưa chốt tên trạng thái hay giao thức.

## 4. Vùng tác động cần rà tại Theme 7

| Artifact/điểm neo đã đọc | Nội dung cần kiểm tra và cập nhật |
|---|---|
| Decision Register: `T7-DR-098–102`, đặc biệt `098#REQ-01`, `099`, `100/101` | Phân vai dự báo chiết khấu; đầu vào mô phỏng giá; kết quả dự kiến không ghi sổ; chuỗi giá vốn tham chiếu. Hợp nhất vào nhóm nghiệp vụ hiện hành. |
| BJ-02 và hợp đồng kết quả nhận | Thống kê theo từng lần nhập, kết quả xác nhận, sửa/đảo, truy vết tới nguồn mua. |
| BJ-03 / BJ-13 | Tách mô phỏng dự kiến với thành phần giá thực tế có căn cứ; xác định nhánh xử lý khi quyền lợi thực tế đến trước hoặc sau xác nhận giá. |
| BJ-14 và các artifact tham chiếu `T7-DR-098–102` | Rà phạm vi tác động thực tế trên parent; điều chỉnh phần mô phỏng/tham chiếu nếu có liên quan. |
| BJ-07; `T7-DR-054`, `042/109/143` | Đối chiếu ranh giới trả NCC; sửa cách gán owner giảm phải trả sau khi hòa giải với Theme 6/10. |
| `04.architecture/integrations/INT-01-cross-theme-outbound.md` | Đặc tả hai chiều Kho ↔ Mua hàng và đầu ra giá dự kiến, có phiên bản/đối soát. |
| `07.evidence/outbound-v3.10.1/theme-10-purchase/` | Phần tạm không còn là nguồn canonical cho Theme 10. Ghi tiếp nhận/thay thế và trỏ tới BJ-05 Theme 10; bảo toàn bằng chứng lịch sử. |
| `KB-KGV-043/044/045`, glossary, quiz, presentation | Đồng bộ giải thích, owner và ví dụ theo quyết định mới nếu có tham chiếu. |
| UI Flow, screen/component contracts, mobile HTML, Inspect và QA | Cập nhật khi nghiệp vụ tác động màn hình; tuân thủ DS của parent hiện hành. Thông tin giải thích handoff/kiến trúc đặt ở tài liệu hoặc Inspect; trong UI chỉ giữ thông tin giúp người dùng quyết định. |

Đường dẫn/ID trên thuộc nguồn v3.10.1 đã đối chiếu. Nếu parent đã di chuyển artifact, tìm theo ID/nội dung và ghi mapping; không tạo file trùng chỉ để giữ đường dẫn cũ.

## 5. Các điểm còn mở phải giữ nguyên trạng thái

- **Q-01:** hưởng hồi tố toàn bộ lượng đủ điều kiện của kỳ hay chỉ phần sau/vượt ngưỡng; nhiều bậc thế nào.
- **Q-02:** lượng nào đủ điều kiện và ở mốc nào; trả/hủy/sửa ảnh hưởng ra sao. Kho cấp số thực nhập, Mua hàng áp điều khoản.
- **Q-03/04:** bằng chứng xác lập quyền lợi thật; phạm vi sản phẩm/UOM; tiền, %, hàng tặng và cách phân bổ.
- **Q-07/08:** “giá cơ sở” tạm hiểu là giá vốn tham chiếu định giá; phương pháp dự báo, nguồn kế hoạch và cách rà soát khi dự báo đổi chưa chốt.
- **Q-06 — mâu thuẫn liên Theme:** `T7-DR-054` đang gọi Kế toán giảm công nợ. Theme 6 giao số dư phải trả cho Công nợ. Hướng phân vai: Mua hàng xác nhận căn cứ thương mại, Kho xác nhận bàn giao, Công nợ cập nhật phải trả, Kế toán ghi sổ. Mốc đủ điều kiện giảm tiền còn mở.

Có thể cập nhật owner và ranh giới đã xác nhận ngay. Các lựa chọn trên cần quyết định trước khi hoàn thiện công thức/luồng ghi nhận tương ứng.

## 6. Tiêu chí nghiệm thu bản Theme 7 nâng cấp

1. Mọi artifact liên quan thống nhất Theme 10 sở hữu tiến độ và dự báo đạt ngưỡng.
2. Một đơn nhận nhiều lần: từng lần có nguồn; gửi lại không cộng trùng; UOM khác nhau không được cộng thẳng.
3. Nhập nhanh không có PO vẫn giữ nguồn thực tế; không tạo PO giả để đáp ứng tích hợp.
4. Trả/sửa/đảo được truy vết để Theme 10 tính lại phần đủ điều kiện; kết quả chưa rõ có đường tra cứu/đối soát.
5. Ví dụ 600 thực tế đủ điều kiện + 500 dự kiến cho ngưỡng 1.000: Theme 10 dự báo 1.100; phần 500 chưa thành tiến độ thực tế. Theme 7 mô phỏng từ kết quả thương mại của Theme 10.
6. Dự báo không ghi movement, phải trả, `OfficialCostVersion`, value ledger hoặc giá vốn giao dịch. Quyền lợi thực tế đi qua căn cứ riêng.
7. Khi dự báo đổi/không đạt, có phiên bản mới và cách rà soát giá tham chiếu theo quy trình được chốt.
8. Diff cumulative giải thích được mọi file thay đổi; các artifact ngoài impact set được bảo toàn; checksum và liên kết hợp lệ.

**Đầu ra gửi lại Theme 10:** version/parent Theme 7, artifact/ID hợp đồng được tiếp nhận, quyết định đã thống nhất, câu hỏi còn mở, mapping thay thế outbound và bằng chứng QA. Không coi hand-off này là xác nhận Theme 7 đã hoàn thành nâng cấp.

## 7. Nguồn đính kèm

- Baseline chuẩn phía Mua hàng: `VET45-Theme10-Mua-hang-v0.1.1.zip`.
- Trong ZIP, đọc `README.md`, `VERSION.md`, `01.knowledge/governance/source-register.md`, `01.knowledge/decisions/decision-register.md` (D-02/05–10), `02.specification/overview/overview.md` và bản đồ BJ.
- SHA-256 baseline: `2b76f6f78dee1d9e075cdb86f9c53707e0b23fd3f2271df2a8e62cc9b3223570`.
