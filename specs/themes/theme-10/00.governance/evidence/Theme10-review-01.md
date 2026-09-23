---
id: T10-REVIEW-01
title: Theme 10 — Mua hàng: ranh giới và bản đồ hành trình đề xuất
status: ĐÃ ĐỐI CHIẾU VỚI BASELINE v0.1.1
date: 2026-09-23
owner: BA
version_parent: Không có — Theme 10 bắt đầu mới
---

# Theme 10 — Mua hàng

## Gói review 01: ranh giới và bản đồ hành trình

**Trạng thái cập nhật ngày 23/09/2026:** Anh đã đồng ý với hướng đề xuất của gói review 01 và bổ sung phạm vi chương trình chiết khấu mua hàng theo kỳ. Sau đó anh làm rõ: Theme Mua hàng kiểm soát tiến độ thực tế và dự đoán mức đạt; Theme Kho cung cấp số liệu từng lần nhập. Nội dung dưới đây được đồng bộ với baseline phạm vi v0.1.1; các điều kiện tính cụ thể trong mục 7 còn mở. Mã BJ đã có trong bản đồ cấp danh mục, chưa viết Trường hợp sử dụng hoặc đặc tả giao diện.

### 1. Kết luận từ nguồn hiện có

1. **Mua hàng là nguồn giao dịch thương mại với nhà cung cấp.** Theme 6 đã khóa việc Mua hàng sở hữu chứng từ mua, hóa đơn nhà cung cấp và nguồn nghĩa vụ phải trả. Mốc được ghi là **“Nhận hóa đơn nhà cung cấp”**; điều kiện chính xác của mốc này còn cần Theme 10 định nghĩa và xác nhận với Theme 6. [S1: `T06-DR-003`, `T06-DR-006`, `T06-DR-035`–`037`]
2. **Kho ghi nhận việc đã xảy ra với hàng hóa.** Theme 7 nhận hàng thực tế, nhận từng phần và ghi chênh lệch; chỉ hàng được tiếp nhận mới tăng tồn vật lý. Kho xác nhận giá trị tồn ban đầu, xử lý chi phí mua đến muộn và bàn giao trả nhà cung cấp theo đúng phạm vi được Mua hàng cho phép. Việc đặt mua hoặc nhận hóa đơn không tự làm tăng tồn. [S2: `BJ-02`, `BJ-03`, `BJ-07`, `BJ-13`; `T7-DR-109`, `T7-DR-138`]
3. **Công nợ giữ số dư phải trả và việc chi tiền.** Sau khi nguồn đạt mốc xác lập, Theme 6 tiếp nhận *đầy đủ nghĩa vụ ban đầu và thông tin tiền đã chi tại nguồn*, kể cả khi đã trả đủ. Thay đổi về sau phải có dấu vết; nếu giá trị mới thấp hơn phần đã thực hiện, Theme 6 giữ trạng thái **Cần xử lý**, không tự hoàn hoặc đảo tiền. [S1: `T06-DR-004`, `007`, `008`, `039`]
4. **Kế toán giữ sổ kế toán và kỳ kế toán.** Theme 10 không tự tạo sổ công nợ hoặc sổ kế toán. [S1: `T06-DR-005`; S2: `BJ-03`, `BJ-13`]
5. **Chương trình chiết khấu theo kỳ thuộc phạm vi Theme 10.** Chương trình có thể đang chạy hoặc có hiệu lực trong tương lai; một mức giảm, chẳng hạn 20%, chỉ được áp dụng thực tế khi đạt ngưỡng theo điều khoản. Theme 7 cung cấp thống kê theo từng lần nhập. Theme 10 dùng sự thật đó và điều khoản để theo dõi tiến độ, dự đoán mức đạt, ước tính/phân bổ lợi ích thương mại. Theme 7 dùng lợi ích dự kiến từ Theme 10 để mô phỏng giá nhập và bình quân dự kiến cho người có quyền cân nhắc giá cơ sở trong kỳ. Phần dự kiến không phải quyền lợi đã phát sinh. Bản chuyển giao cũ của Theme 7 chỉ là tài liệu tham khảo cho mô phỏng giá, không chuyển nguyên trạng thành đặc tả Theme 10. [U2, U3; S2: `T7-DR-098`–`101`, `KB-KGV-043`, `INT-01`, `theme-10-purchase/t10-bj-discount-scenario.md`]

**Điểm vênh cần giải quyết:** `T7-DR-054` và `BJ-07` của Theme 7 viết rằng “Theme Kế toán” giảm công nợ khi trả nhà cung cấp. `T06-DR-004`/`035` của Theme 6 giao số dư phải trả cho **Công nợ**, còn Kế toán giữ sổ kế toán. Vì vậy gói này **chưa gán quyền giảm phải trả cho Kế toán hay tự sửa quyết định Theme 7**. Đề xuất khi chốt hợp đồng chung: Mua hàng xác nhận điều chỉnh thương mại; Công nợ cập nhật nghĩa vụ phải trả theo nguồn hợp lệ; Kế toán xử lý phần ghi sổ. Cần xác nhận thời điểm và sửa tài liệu Theme 7/6 bị ảnh hưởng. [S1: `T06-DR-004`, `005`, `035`; S2: `T7-DR-054`, `143`]

### 2. Nguồn và mức thẩm quyền

| Mã | Nguồn được kiểm tra | Vai trò trong gói này | Giới hạn |
|---|---|---|---|
| S1 | `VET45-Cong-no-v2.1.3.zip` | Quyết định đã khóa về ranh giới và nghĩa vụ; tổng quan sáu BJ Theme 6. | `overview.md` ghi `IN_REVIEW`; các yêu cầu bàn giao từ Theme 6 sang Theme 10 vẫn là `PROPOSED_HANDOFF` cho đến khi chủ nguồn xác nhận. |
| S2 | `VET45-Theme7-Harness-v3.10.1-template-aligned.zip`, đối chiếu gói prototype `v3.10.1` | Các quyết định và BJ của Kho/Giá vốn; khả năng đầu vào, đầu ra với Mua hàng. | Không lấy phần outbound tạm làm quyết định Theme 10; có điểm vênh về quyền giảm công nợ. |
| S3 | `VET45-Cong-no-Tai-lieu-hien-hanh-2026-09-22.zip` | Tham khảo lịch sử để kiểm tra thay đổi cấu trúc. | Có bảy BJ theo phân rã cũ; **không** dùng thay danh mục sáu BJ của v2.1.3. |
| U1 | Xác nhận của anh trong cuộc trao đổi này: Theme 10 chưa có bản hiện hành và sẽ bắt đầu từ đầu | Căn cứ để lập baseline mới, không chọn phiên bản cha Theme 10. | Chưa phải phê duyệt danh mục BJ hoặc phạm vi Phase 1 cụ thể. |
| U2 | Xác nhận ngày 23/09/2026: đồng ý với hướng đề xuất; chương trình chiết khấu trong kỳ hiện tại/tương lai chỉ áp dụng thực tế sau khi đạt ngưỡng; cần ước tính sớm giá nhập/giá cơ sở | Nguồn cho phạm vi và mục tiêu chương trình; diễn giải phân vai trước đây được U3 làm rõ. | Chưa xác nhận ngưỡng tính trên dữ liệu nào, hưởng cho toàn bộ hay chỉ phần vượt, bằng chứng chốt quyền lợi và cách phân bổ nhiều sản phẩm. |
| U3 | Xác nhận ngày 23/09/2026: Theme Mua hàng kiểm soát tiến độ thực tế và dự đoán mức đạt chiết khấu; Theme Kho cung cấp số liệu thống kê theo từng lần nhập | Nguồn mới nhất cho quyền sở hữu dự báo đạt ngưỡng và luồng dữ liệu Kho → Mua hàng. | Phương pháp dự báo và điều kiện lượng đủ ngưỡng chưa chốt; Theme 7 tiếp tục mô phỏng giá/giá vốn dự kiến. |

**Căn cứ để tra lại:** Trong S1, xem `01.knowledge/decisions/decision-register.md`, `02.specification/overview/overview.md` và `01.knowledge/know-how/KB-003-xac-lap-va-thay-doi-nghia-vu-cong-no.md`. Trong S2, xem `01.knowledge/decisions/decision-register.md`, `02.specification/behavior/journeys/BJ-02-...`, `BJ-03-...`, `BJ-07-...`, `BJ-13-...` và `04.architecture/integrations/INT-01-cross-theme-outbound.md`. Đường dẫn trên nằm **bên trong các gói nén**, không phải tài liệu đã được đưa vào Theme 10.

| Tệp nguồn | SHA-256 của gói nén |
|---|---|
| S1 | `3f376f9910697082b79a31cde0e291ab9a364c8976ba4ba87cfd5e754be48b72` |
| S2 — bản sắp theo cấu trúc mới | `376296fd20e81fe06b25d5d74fe4e2252a7f78e6a663f4f2542a9cba9b40cdb6` |
| S2 — prototype v3.10.1 | `1e85def14fae12443992bac3bc2affd309ede055d44047ae36b47781ecf47523` |
| S3 | `c277bf21397996dc0a31110397ae2ff135a09959c6904a23085016eceb5a2be4` |

### 3. Ranh giới trách nhiệm đề xuất

| Sự thật hoặc công việc | Chủ sở hữu | Theme 10 làm gì | Trạng thái căn cứ |
|---|---|---|---|
| Định danh nhà cung cấp | Theme 3 — Đối tác | Dùng mã đối tác chung; không tạo một nhà cung cấp khác trong chứng từ mua. | Đã có ranh giới trong S1 và S2. |
| Sản phẩm, đơn vị tính và chính sách theo dõi lô | Theme 2 — Sản phẩm | Chọn dữ liệu hiện hành và giữ bản chụp cần thiết trên chứng từ mua. | Theme 7 đã khóa owner; chi tiết bản chụp cần đặc tả. |
| Đơn mua, phiên bản điều chỉnh/hủy và điều kiện được giao | **Theme 10** | Sở hữu chứng từ nguồn, số lượng và đơn vị đặt mua, giá/điều kiện thương mại; cung cấp số còn được nhận theo từng dòng. | Theme 7 xác nhận **không** sở hữu PO; vòng đời chi tiết Theme 10 còn là đề xuất. |
| Hàng thực nhận, từ chối, lô, trạng thái và tồn vật lý | **Theme 7** | Nhận kết quả, đối chiếu với cam kết của nhà cung cấp và xử lý phần còn mở. | Đã khóa trong S2, `BJ-02`. |
| Hóa đơn và căn cứ giá mua/thuế/chiết khấu | **Theme 10** đối với chứng từ thương mại; trách nhiệm xác nhận thuế cần làm rõ với Kế toán | Lưu hóa đơn và phiên bản; bàn giao thành phần giá có nguồn cho Theme 7, nghĩa vụ hợp lệ cho Theme 6. | S1 khóa nguồn nghĩa vụ; cách xác minh và chi tiết thuế chưa khóa. |
| Giá trị tồn kho ban đầu, chi phí đến muộn, giá vốn | **Theme 7** | Cung cấp chứng từ và quan hệ tới lần nhận; không tự tính hay công bố giá vốn chính thức. | Đã khóa trong S2, `BJ-03`, `BJ-13`. |
| Số dư phải trả, chi tiền, phân bổ, cấn trừ, đối chiếu | **Theme 6** | Hiển thị tham chiếu khi cần; không ghi một sổ phải trả thứ hai. | Đã khóa trong S1. |
| Quyết định thương mại trả nhà cung cấp | **Theme 10** | Xác nhận phạm vi được phép trả và thay đổi có phiên bản; xử lý kết quả thương mại. | Theme 7 đã khóa điều kiện nhận nguồn; quy trình Mua hàng chưa khóa. |
| Hàng chờ trả, kiểm hàng, bàn giao thực tế, giảm tồn và giá trị kho | **Theme 7** | Nhận bằng chứng bàn giao; không coi đề nghị trả là đã xuất kho. | Đã khóa trong S2, `BJ-07`. |
| Ghi sổ và kỳ kế toán | **Theme 9 — Kế toán** | Bàn giao khi có nghiệp vụ cần ghi sổ theo hợp đồng liên Theme. | Đã có ranh giới trong S1; điểm vênh trả NCC cần giải quyết. |
| Chương trình chiết khấu theo kỳ: điều khoản, ngưỡng, thời hạn, phạm vi hàng và số lượng đủ điều kiện **thực tế** | **Theme 10** | Lưu chương trình có phiên bản; nhận từng lần nhập từ Theme 7, đối chiếu điều khoản để theo dõi tiến độ đủ điều kiện, phần còn thiếu và quyền lợi được xác lập sau khi đạt ngưỡng. | Mục tiêu đã được anh xác nhận; cách tính chi tiết còn mở. |
| Dự đoán mức đạt, khoản lợi ích thương mại **dự kiến** và phân bổ theo sản phẩm/lần mua | **Theme 10** | Dùng dữ liệu nhập kho, đơn còn mở và giả định có nguồn để dự báo; bàn giao phiên bản dự báo và lợi ích phân bổ cho Theme 7. | U3 chốt owner; phương pháp và quy tắc phân bổ còn mở. |
| Mô phỏng giá nhập và bình quân gia quyền **dự kiến** | **Theme 7** | Cấp kết quả thương mại dự kiến có phiên bản; đọc kết quả mô phỏng, không coi đó là chứng từ giảm giá. | Cần tiếp nhận hợp đồng hai chiều Theme 7 ↔ Theme 10. |
| Giá vốn tham chiếu để định giá, giá sàn, giá niêm yết và giá bán đang hiệu lực | Miền **Định giá bán** | Cung cấp nguồn chiết khấu dự kiến; người có quyền chọn dùng kết quả để rà soát giá cơ sở. | Ranh giới đã có trong S2, `T7-DR-098`, `100`, `101`; thao tác công bố giá vẫn độc lập. |

**Phạm vi đã đồng ý ở mức định hướng:** Đặt mua; theo dõi việc giao thực tế và xử lý chênh lệch thương mại; tiếp nhận hóa đơn; trả nhà cung cấp về mặt thương mại; quản lý chương trình chiết khấu mua hàng trong kỳ hiện tại/tương lai. Các quy trình tìm nguồn cung, đấu thầu, hợp đồng khung và tự đặt mua từ cảnh báo tồn vẫn ở danh sách cân nhắc. Chưa mặc định mọi cách tính ưu đãi hoặc quyền ghi nhận tài chính đều thuộc đợt đầu.

### 4. Những lần bàn giao phải định nghĩa

| Bàn giao | Dữ liệu và điều kiện tối thiểu cần chốt | Điều không được suy ra |
|---|---|---|
| Theme 10 → Theme 7, nhận theo chứng từ | Chứng từ/dòng và **phiên bản**, nhà cung cấp, sản phẩm, đơn vị tính, lượng còn được phép nhận, trạng thái cho phép nhận; sửa/hủy phải báo đúng phạm vi. | Đặt mua không có nghĩa hàng đã đến. Nhập nhanh của Theme 7 không được sinh một PO giả. |
| Theme 7 → Theme 10, từng lần nhập | Mã lần nhận/operation, phiên bản/trạng thái xác nhận, liên kết đơn/NCC/sản phẩm/UOM, thời điểm, từng dòng/lô, lượng thực nhập/cách ly/hỏng/từ chối, nguồn sửa/đảo và căn cứ chênh lệch; cần tra lại khi kết quả chưa rõ. | Không biến số lượng trên đơn thành số lượng đã nhận hoặc toàn bộ số đã nhập thành lượng đủ điều kiện chiết khấu; không tự tạo công nợ từ việc tăng tồn. |
| Theme 10 → Theme 7, căn cứ giá nhập | Giá và các thành phần có nguồn, phạm vi dòng nhận, phiên bản/hiệu lực; phân biệt căn cứ có trước lần xác nhận giá với chi phí đến sau. | Giá trên PO, giá hóa đơn và giá vốn chính thức không mặc nhiên bằng nhau. |
| Theme 10 → Theme 6, nghĩa vụ phải trả | Chỉ sau **mốc nhận hóa đơn được định nghĩa rõ**; mã đối tác chung, định danh/phiên bản chứng từ, giá trị nghĩa vụ gốc, chi tiền tại nguồn nếu có, thay đổi/đảo có lịch sử, đủ thông tin chống ghi trùng và đối soát. | File hóa đơn mới tải lên, đơn mua, hàng đã nhận hoặc chỉ phần chưa trả **chưa đủ** để tự kết luận có một nghĩa vụ mới. |
| Theme 10 → Theme 7, đề nghị trả | Yêu cầu đã được Mua hàng cho phép, `source_request_id`/`source_version`, dòng và phân bổ hàng theo sản phẩm–đơn vị–lô; thay đổi trước bàn giao tạo phiên bản mới. | Kho không tự sửa số lượng/lô thương mại và không duyệt thương mại lần hai. |
| Theme 7 → Theme 10 → Theme 6/9, kết quả trả | Bằng chứng bàn giao vật lý từ Theme 7; căn cứ nhà cung cấp chấp nhận giảm giá/trừ nợ do Theme 10 xác lập; Theme 6 cập nhật nghĩa vụ theo hợp đồng được chốt; Theme 9 ghi sổ. | Bàn giao vật lý **không tự xác lập** nhà cung cấp đã giảm số phải trả; giá vốn xuất kho có thể khác giá nhà cung cấp chấp nhận. |
| Theme 10 → Theme 7, dự báo chương trình và lợi ích dự kiến | Mã chương trình/phiên bản, NCC, kỳ, điều khoản, tiến độ đủ điều kiện/thiếu ngưỡng do Theme 10 xác định, kịch bản mức đạt và giả định, khoản lợi ích thương mại phân bổ theo sản phẩm/lần mua có nguồn và thời điểm. | Theme 7 không tính lại tiến độ hoặc mức đạt chiết khấu; không coi kế hoạch tương lai là số lượng thực tế được NCC công nhận. |
| Theme 7 → miền Định giá bán, giá nhập/giá vốn dự kiến | Phiên bản đầu vào từ Theme 10, kịch bản, giá nhập dự kiến theo sản phẩm/đơn vị, bình quân dự kiến theo bối cảnh tồn và phương pháp giá vốn. | Không ghi vào tồn, công nợ, giá vốn chính thức hoặc giá bán đang hiệu lực; giá cơ sở và giá bán chỉ thay đổi qua quyết định/công bố riêng của người có quyền. |
| Theme 10 → Theme 7 và Theme 6, quyền lợi **đã phát sinh** | Bằng chứng đủ điều kiện theo điều khoản, giá trị thương mại thực tế và phiên bản chứng từ; Theme 7 xét thành phần giá trị theo lần nhận/kỳ, Theme 6 chỉ thay đổi phải trả từ nguồn nghĩa vụ hợp lệ. | Không chuyển thẳng một phiên bản dự báo thành bút toán, không tự đồng nhất giảm giá trị kho với giảm công nợ. |

Với mọi bàn giao có thể ghi dữ liệu, BA cần khóa ý nghĩa, điều kiện, nguồn và phiên bản. SA mới xác định thông điệp/API, chống lặp, thứ tự, cách tra cứu khi kết quả chưa rõ và đối soát. Một lần gửi lại không được tạo thêm lần nhận, nghĩa vụ hay yêu cầu trả.

### 5. Bản đồ hành trình Theme 10 đề xuất

**Năm BJ dưới đây đã được đồng ý ở mức mục tiêu và ranh giới; chưa phân rã Trường hợp sử dụng.** Không có yêu cầu rằng hóa đơn phải đến sau hàng hoặc mọi giao dịch đều phải có đơn mua.

| Mã tạm | Hành trình | Bắt đầu bằng công việc thực tế | Kết thúc tại kết quả Theme 10 sở hữu | Điểm nối chính |
|---|---|---|---|---|
| BJ-01 | **Lập và xác nhận đơn mua** | Có nhu cầu mua một số hàng xác định. | Đơn mua có hiệu lực để giao; hoặc yêu cầu dừng/hủy có lý do. Điều chỉnh sau đó tạo phiên bản có dấu vết. | Theme 3/2 cung cấp dữ liệu nền; Theme 7 được xem chứng từ đủ điều kiện nhận. Chính sách duyệt đơn còn mở. |
| BJ-02 | **Theo dõi giao hàng và xử lý chênh lệch** | Nhà cung cấp báo giao, hoặc Theme 7 có kết quả nhận từng lần. | Từng dòng đơn phản ánh đã nhận, đã từ chối, còn cần giao và quyết định với phần chênh lệch; đơn được đóng khi có căn cứ. | Theme 7 chịu trách nhiệm nhận và tồn; Theme 10 xử lý cam kết/ngoại lệ thương mại. |
| BJ-03 | **Tiếp nhận và xử lý hóa đơn nhà cung cấp** | Nhà cung cấp gửi hóa đơn/chứng từ tính tiền. | Hóa đơn được xác nhận đủ điều kiện hoặc giữ chờ/từ chối có lý do; nếu đủ mốc xác lập, nghĩa vụ được bàn giao cho Theme 6 đúng một lần. | Có thể đối chiếu đơn mua và kết quả nhận; Theme 7 dùng thành phần giá, Theme 6 dùng nghĩa vụ; không bắt buộc hóa đơn đến sau hàng. |
| BJ-04 | **Xử lý trả hàng cho nhà cung cấp** | Có yêu cầu trả hàng đã nhận và cần quyết định thương mại. | Phạm vi trả được cho phép, được theo dõi tới kết quả vật lý và kết quả thương mại; hồ sơ đóng hoặc chờ ngoại lệ có căn cứ. | Theme 7 giữ hàng chờ trả/bàn giao; Theme 6 cập nhật phải trả khi có căn cứ hợp lệ, Theme 9 ghi sổ. |
| BJ-05 | **Quản lý chương trình chiết khấu mua hàng theo kỳ** | Có điều khoản ưu đãi của nhà cung cấp cho kỳ đang diễn ra hoặc kỳ tương lai. | Chương trình/điều khoản có phiên bản; tiến độ thực tế và dự báo mức đạt được cập nhật; quyền lợi chỉ xác lập khi đạt điều kiện; cuối kỳ có kết quả đủ căn cứ hoặc lý do chưa được hưởng. | Theme 7 cấp thống kê từng lần nhập; Theme 10 sở hữu tiến độ, dự báo mức đạt và phân bổ lợi ích thương mại dự kiến; Theme 7 mô phỏng giá nhập/giá vốn dự kiến; miền Định giá bán xem xét giá cơ sở. Khi ưu đãi thật phát sinh, Theme 7/6 nhận thành phần có chứng từ theo từng ranh giới. |

**Đổi so với bản chuyển giao cũ:** Bản outbound Theme 7 chỉ lập kịch bản trước đơn mua và không theo dõi mức đạt thực tế. BJ-05 mới bao quát chương trình có hiệu lực, tiến độ đang chạy và chương trình tương lai; dự báo đạt ngưỡng do Theme 10 kiểm soát. Các bước giả định và giá dự kiến của bản cũ chỉ được kế thừa trong phần mô phỏng giá Theme 7 sau khi đối chiếu với BJ-05. [U2, U3; S2: `INT-01`, `t10-bj-discount-scenario.md`]

**Quan hệ giữa các BJ:** BJ-01 cung cấp nguồn đặt mua cho BJ-02 khi có đơn. BJ-02 nhận sự thật giao hàng từ Theme 7, có thể xảy ra nhiều lần. BJ-03 được kích hoạt theo **hóa đơn đến**, nên có thể đi trước, xen giữa hoặc sau các lần nhận. BJ-04 được kích hoạt khi có nhu cầu trả, không phải bước cuối bắt buộc. BJ-05 chạy theo kỳ chương trình, đọc các nguồn được phép từ BJ-01/02/03/04 và thống kê nhập kho từ Theme 7, nhưng không biến chúng thành một chuỗi bắt buộc. Theme 10 cập nhật tiến độ/dự báo khi nguồn hợp lệ đổi; Theme 7 tái mô phỏng giá khi đầu vào dự kiến từ Theme 10 đổi.

### 6. Chương trình chiết khấu: cách hiểu và ví dụ

**Điều đã chốt:** Có chương trình của kỳ hiện tại và tương lai. Chưa đạt ngưỡng thì chưa áp dụng ưu đãi như một quyền lợi **thực tế**. Theme 7 cấp sự thật từng lần nhập; Theme 10 đối chiếu điều khoản, cho thấy tiến độ, dự báo đạt ngưỡng và lợi ích thương mại dự kiến đã phân bổ; Theme 7 mô phỏng giá nhập/giá vốn dự kiến để người có quyền xem xét điều chỉnh giá cơ sở phục vụ định giá bán. [U2, U3]

| Con số cần phân biệt | Cách hiểu trong ví dụ 1.000 đơn vị / giảm 20% |
|---|---|
| Tiến độ đã đạt | Giả sử điều khoản lấy hàng nhập hợp lệ: Theme 7 báo từng lần nhập; Theme 10 xác định 600 đơn vị *đủ điều kiện thực tế* → 60% ngưỡng; còn thiếu 400. Chưa có quyền lợi 20% thực tế. |
| Kịch bản có kế hoạch | Theme 10 tính 600 đã đạt + 500 dự kiến đủ điều kiện trong quý → 1.100 theo kịch bản, vượt ngưỡng 100. Đây là **ước tính**, không phải xác nhận của nhà cung cấp. |
| Lợi ích thương mại dự kiến | Theme 10 tính/phân bổ khoản lợi ích **theo đúng điều khoản** cho sản phẩm/lần mua hưởng lợi; lưu chương trình, phiên bản, dữ liệu thực tế, giả định và phương pháp. |
| Giá nhập dự kiến | Theme 7 dùng đầu vào phân bổ của Theme 10 và dữ liệu tồn để mô phỏng giá nhập, bình quân dự kiến theo phương pháp giá vốn. |
| Giá nhập/giá vốn chính thức | Vẫn căn cứ giao dịch và quyền lợi đã phát sinh có chứng từ. Bình quân gia quyền/giá vốn chính thức không bị thay bằng kịch bản. |
| Giá cơ sở cho định giá bán | Người có quyền có thể chọn giá dự kiến làm nguồn tham chiếu và công bố giá bán qua bước riêng ngay trong kỳ. Khi kế hoạch đổi hoặc chương trình không đạt, hệ thống yêu cầu rà soát lại. |

Theme 10 cần bàn giao **lợi ích thương mại dự kiến phân bổ theo sản phẩm/lần mua**; Theme 7 cần trả riêng **giá nhập dự kiến** và **giá vốn bình quân dự kiến** khi đặt hàng dự kiến vào bối cảnh lượng và giá trị tồn hiện có. Đây là một lượt tính mô phỏng theo phương pháp giá vốn và thứ tự biến động phù hợp, có thời điểm và giả định rõ; không phải một lần công bố giá vốn. Ví dụ giản lược, nếu đang có 100 đơn vị giá trị 100.000 đồng/đơn vị, dự kiến nhận thêm 100 đơn vị với giá sau phân bổ ưu đãi 80.000 đồng/đơn vị và chưa có xuất hàng/chi phí khác, bình quân **dự kiến** là 90.000 đồng/đơn vị. Người định giá có thể cân nhắc 90.000 đồng làm giá cơ sở ngay; số bình quân **chính thức** vẫn chạy theo sự kiện và chứng từ thực tế. Khi có xuất hàng xen giữa hoặc dùng phương pháp bình quân khác, Theme 7 phải tính đúng theo phương pháp đó, không áp công thức giản lược này cho mọi trường hợp.

**Một khác biệt quyết định kết quả tính:** Nếu giá trước ưu đãi là 100.000 đồng/đơn vị, ngưỡng 1.000 và dự báo mua 1.100 đơn vị, *giả sử* chiết khấu 20% được hưởng **cho toàn bộ lượng đủ điều kiện trong kỳ**, giá dự kiến trước chi phí khác có thể là 80.000 đồng/đơn vị. Nếu chỉ 100 đơn vị **vượt ngưỡng** được giảm, số tiền giảm dự kiến là 2.000.000 đồng; khi trải trên cả 1.100 đơn vị cùng giá, giá bình quân kịch bản xấp xỉ 98.182 đồng/đơn vị. Đây là **hai quy tắc minh họa loại trừ nhau**, không phải điều khoản đã chốt. Theme 10 không được mặc định cách nào từ câu “giảm 20% sau khi đạt ngưỡng”; Theme 7 chỉ mô phỏng giá theo kết quả phân bổ đã bàn giao.

Theme 10 cần thể hiện ít nhất hai góc nhìn có nhãn: **theo tiến độ đã xác nhận** và **theo kịch bản đến cuối kỳ**. Không tự sinh một “xác suất đạt” bằng số phần trăm khi chưa có phương pháp dự báo được xác nhận. Khi hàng đặt chuyển sang đã nhận, khi trả hàng/hủy đơn hoặc khi điều khoản đổi, ước tính mới phải dùng phiên bản mới và không cộng hai lần cùng một lượng.

**Tác động lên Theme 7:** Cung cấp thống kê có nguồn theo từng lần nhập cho Theme 10; nhận phiên bản dự báo và lợi ích thương mại đã phân bổ từ Theme 10 để mô phỏng giá. Giữ `T7-DR-098#REQ-01` về việc dự báo không ghi sổ; mở rộng hợp đồng của `T7-DR-099` và bản outbound theo phân vai mới; dùng chuỗi giá tham chiếu của `T7-DR-100/101` để xử lý điều chỉnh giá cơ sở sớm. Không chèn các số dự kiến vào `ReceiptValuation`, `OfficialCostVersion` hay kết quả bình quân gia quyền chính thức. Khi ưu đãi **thực tế** phát sinh, xét nhánh giá ban đầu `BJ-03` hoặc chi phí/điều chỉnh đến sau `BJ-13` theo thời điểm và bằng chứng. [S2, U3]

### 7. Quyết định chi tiết cần khóa trước khi viết BJ-05 và hợp đồng Theme 7

| Ưu tiên | Câu hỏi cần khóa | Các hướng cần phân biệt | Đề xuất để thảo luận |
|---|---|---|---|
| 1 | “Nhận hóa đơn nhà cung cấp” trong Theme 6 xảy ra khi nào? | Chỉ nhận tệp; ghi nhận số/ngày/nhà cung cấp hợp lệ; hoặc sau đối chiếu và duyệt hóa đơn. | Tách **tiếp nhận tệp** khỏi **xác nhận hóa đơn đủ điều kiện phát sinh nghĩa vụ**. Chốt tên mốc và cách xử lý hóa đơn bị bác/trùng với Theme 6, không tự diễn giải lại quyết định đã khóa. |
| 2 | Giao dịch không có đơn mua và hóa đơn đến trước hàng xử lý thế nào? | Cho nhận nhanh độc lập; cho hóa đơn chờ liên kết; bắt buộc lập đơn bù. | Giữ khả năng nhập nhanh đã có ở Theme 7; không tạo đơn mua giả. Chốt loại giao dịch và cách liên kết về sau trước khi định nghĩa trạng thái. |
| 3 | Hàng thiếu/thừa/bị từ chối ảnh hưởng gì tới đơn và hóa đơn? | Tiếp tục chờ giao; cho phép thay đổi đơn có phiên bản; hoặc đóng phần không giao và yêu cầu điều chỉnh thương mại. | Tách sự thật vật lý của Theme 7 khỏi quyết định chấp nhận/chỉnh cam kết của Theme 10. |
| 4 | Mốc nào làm giảm phải trả khi trả nhà cung cấp? | Khi bàn giao vật lý; khi bên bán chấp nhận giảm; khi có chứng từ điều chỉnh đủ điều kiện. | **Không giảm tự động chỉ vì kho đã bàn giao**; chốt căn cứ thương mại và cách xử lý hoàn tiền/đã chi trước đó cùng Theme 6. Hòa giải câu chữ `T7-DR-054`. |
| 5 | Đơn mua, hóa đơn và trả nhà cung cấp cần ai duyệt? | Mỗi việc có thẩm quyền riêng; mức/ngoại lệ cần duyệt theo chính sách. | Định nghĩa theo quyết định thương mại của Theme 10; không lặp việc duyệt nhập nhanh và kiểm kho của Theme 7. |
| 6 | Ngưỡng áp dụng cho **toàn bộ lượng đủ điều kiện trong kỳ** hay chỉ lượng vượt ngưỡng? | Hồi tố sau khi đạt; áp dụng từ lượng vượt ngưỡng; hoặc theo từng điều khoản chương trình. | Lưu quy tắc trong từng chương trình; chưa tính một mức giá dự kiến duy nhất khi thiếu quy tắc này. |
| 7 | Hóa đơn dịch vụ/chi phí mua ngoài hàng và khoản trả trước thuộc phạm vi nào? | Cùng luồng hóa đơn mua hàng; luồng riêng; hoặc để sau. | Chưa đưa vào BJ-03/đợt đầu bằng một giả định ngầm. |
| 8 | Đơn vị nào được tính vào ngưỡng và khi nào đủ điều kiện? | Đặt mua, giao, nhận đạt, hóa đơn, hoặc nhà cung cấp xác nhận; trả/hủy có thể trừ tiến độ. | Theme 7 cấp từng lần nhập có nguồn; Theme 10 khóa và áp chính sách từng chương trình, không tự nâng mọi lần nhập hoặc đơn mua thành đã đạt. |
| 9 | Ưu đãi tính theo từng sản phẩm, nhóm sản phẩm hay cả nhà cung cấp? | Ngưỡng chung/riêng, nhiều bậc, hàng tặng/giảm tiền, hiệu lực và phương pháp phân bổ khác nhau. | Có điều khoản và phiên bản tường minh; số dự kiến theo từng sản phẩm không được cộng hoặc phân bổ tùy ý. |
| 10 | Bằng chứng nào biến khoản dự kiến thành quyền lợi thực tế? | Đủ số lượng theo dữ liệu nội bộ, đối tác xác nhận, chứng từ giảm giá/hóa đơn điều chỉnh, hoặc các bước kết hợp. | Cần tách **đã đạt ngưỡng**, **đã được xác nhận quyền lợi** và **đủ căn cứ ghi giá trị/công nợ**. |
| 11 | Khi kịch bản đã dùng để định giá mà dự báo giảm, ai quyết định cập nhật giá cơ sở và giá bán? | Cảnh báo/rà soát; tự cập nhật tham chiếu; hoặc công bố lại giá bán. | Ưu tiên cảnh báo và quyết định của người có quyền; giữ lịch sử giá đã công bố, không viết lại giao dịch cũ. |

### 8. Bước tiếp theo

1. Khóa quy tắc xác định số lượng đủ ngưỡng, phạm vi hưởng ưu đãi, cách dự báo và bằng chứng xác nhận thực tế; chốt điều kiện mốc hóa đơn và điểm vênh Theme 6–7 khi trả hàng.
2. Dùng baseline Theme 10 v0.1.1 (kế thừa v0.1.0) làm nguồn cấp phạm vi và danh mục năm BJ; tài liệu review này là hồ sơ lập luận, không là hợp đồng tính toán cuối cùng.
3. Viết từng BJ/Trường hợp sử dụng từ bản đồ danh mục: mục tiêu, bắt đầu/kết thúc, nhánh dừng và handoff. Với BJ-05, rà riêng hợp đồng từng lần nhập Theme 7 → tiến độ/dự báo và lợi ích Theme 10 → mô phỏng giá Theme 7 → giá tham chiếu Định giá. Sau đó đặc tả dữ liệu, hợp đồng kỹ thuật và UI Flow.

**Kiểm tra của lượt này:** đối chiếu danh mục 6 BJ của Theme 6 v2.1.3 với bản 7 BJ lịch sử; kiểm tra Theme 7 `BJ-02/03/07/13/14`, `T7-DR-098`–`102`, các bài tri thức `KB-KGV-043/044/045` và trạng thái outbound Theme 10. Nguồn Theme 6/7 cần một lượt cập nhật liên Theme sau khi các điều khoản còn mở được xác nhận.
