---
id: GLOSSARY
type: glossary
theme: theme-07
title: "Danh mục thuật ngữ quản lý tồn kho, giá vốn và định giá bán"
owner: BA
status: DRAFT
---

# Danh mục thuật ngữ quản lý tồn kho, giá vốn và định giá bán

Ngôn ngữ chung cho tồn kho, giá vốn và định giá bán trong theme này. Tên tiếng Việt là tên dùng trên giao diện và tài liệu nghiệp vụ.

## Ngôn ngữ

### Phạm vi và sở hữu dữ liệu

**Đơn vị vận hành (Tenant)**:
Phạm vi tổ chức độc lập sở hữu dữ liệu, chính sách và sổ tồn kho.

**Cửa hàng (Store)**:
Đơn vị bán hàng và bối cảnh thương mại của một giao dịch.

**Kho (Warehouse)**:
Nơi giữ hàng vật lý của doanh nghiệp.

**Quan hệ cửa hàng–kho (Store–warehouse assignment)**:
Quan hệ cho phép một cửa hàng dùng một kho.

**Kho mặc định (Default warehouse)**:
Kho được dùng cho giao dịch khi người dùng không chọn kho.

**Sản phẩm (Product)**:
Hàng hóa do miền Sản phẩm sở hữu, được tồn kho tham chiếu bằng định danh và phiên bản.

**Dữ liệu chủ (Master data)**:
Dữ liệu nền có thẩm quyền, như sản phẩm, đơn vị tính, cửa hàng và kho.

**Chủ sở hữu dữ liệu (Data owner)**:
Miền có quyền tạo, thay đổi và công bố một loại dữ liệu.

**Dữ liệu có thẩm quyền (Authoritative data)**:
Dữ liệu do chủ sở hữu công bố và dùng làm căn cứ chính thức.

**Dữ liệu tham chiếu (Referenced data)**:
Dữ liệu của miền khác mà kho chỉ giữ định danh, phiên bản hoặc ảnh cần cho giao dịch của mình.

**Dữ liệu dẫn xuất (Derived data)**:
Số hoặc báo cáo được tính lại từ Dữ liệu gốc.

**Cổng quyền sở hữu hàng (Ownership gate)**:
Điều kiện xác nhận hàng đã thuộc doanh nghiệp trước khi ghi nhận vào tồn thuộc sở hữu.

**Hàng ký gửi (Consigned goods)**:
Hàng của bên giao đặt tại điểm bán nhưng chưa thuộc sở hữu bên nhận.

**Hàng demo (Demo stock)**:
Hàng thuộc doanh nghiệp, còn trong tồn vật lý và còn giá trị, nhưng không dùng để bán.

### Số lượng, trạng thái và khả dụng

**Tồn vật lý (Physical stock)**:
Toàn bộ hàng thuộc doanh nghiệp đang có mặt trong kho, kể cả phần chưa bán được.

**Lượng đủ điều kiện bán (Sellable-eligible quantity)**:
Phần tồn vật lý được phép bán theo trạng thái, lô, hạn và chính sách.

**Lượng đã giữ (Reserved quantity)**:
Lượng đã cam kết cho một đơn nhưng chưa rời kho.

**Tồn khả dụng (Available stock)**:
Phần lượng đủ điều kiện bán còn lại sau lượng đã giữ.

**Khóa số dư (Balance key)**:
Tổ hợp định danh một số dư, gồm đơn vị vận hành, sản phẩm, kho, trạng thái và lô khi sản phẩm được theo dõi theo lô.

**Số dư hiện hành (Transactional balance)**:
Số lượng hiện tại tại một khóa số dư.

**Trạng thái tồn kho (Inventory state)**:
Phân loại cho biết một lượng hàng được phép tham gia hoạt động nào.

**Bán được (Sellable)**:
Trạng thái tồn cho phép hàng tham gia kiểm tra khả dụng khi hạn và chính sách không chặn.

**Chờ chốt giá (Valuation pending)**:
Hàng đã nhận và đã thuộc doanh nghiệp nhưng chưa đủ căn cứ giá mua trực tiếp.

**Chờ phân loại hàng trả (Return pending classification)**:
Hàng khách trả đã có mặt trong kho nhưng chưa được xác định là bán lại, hỏng hay hết hạn.

**Cách ly (Quarantined)**:
Hàng tạm thời bị tách khỏi luồng bán vì một lý do nghiệp vụ.

**Hư hỏng (Damaged)**:
Hàng hỏng vẫn còn trong kho và đang chờ xử lý.

**Hết hạn (Expired)**:
Tình trạng không bán được vì hạn dùng đã qua so với ngày nghiệp vụ.

**Cận hạn (Near expiry)**:
Chỉ báo hạn dùng của lô nằm trong ngưỡng ngày do đơn vị vận hành hoặc sản phẩm quy định.

**Chờ trả nhà cung cấp (Return-to-vendor pending)**:
Hàng đã được chấp thuận trả nhà cung cấp nhưng chưa bàn giao.

**Chống xuất âm (No negative stock)**:
Bất biến cấm giao dịch làm lượng đủ điều kiện xuất xuống dưới không.

### Đơn vị tính và lô

**Đơn vị cơ sở (Base unit of measure)**:
Đơn vị dùng để lưu và cộng trừ số dư của một sản phẩm.

**Đơn vị giao dịch (Transaction unit of measure)**:
Đơn vị ghi trên chứng từ hoặc dùng khi thao tác.

**Mục hàng nhận (Receipt item)**:
Nhóm trong một phiếu nhận hàng ứng với một sản phẩm và một đơn vị giao dịch. Một mục có thể gồm nhiều lô hoặc nhiều tình trạng.

**Tỷ lệ quy đổi (Conversion rate)**:
Quan hệ giữa một đơn vị giao dịch và đơn vị cơ sở.

**Ảnh chụp quy đổi (Conversion snapshot)**:
Tỷ lệ quy đổi và phiên bản của tỷ lệ đó được giữ tại thời điểm nghiệp vụ khóa nội dung.

**Chính sách theo dõi (Tracking policy)**:
Quy định một sản phẩm không theo dõi lô hay được theo dõi theo lô.

**Không theo dõi lô (None tracking)**:
Chính sách quản lý sản phẩm chỉ theo số lượng, kho và trạng thái.

**Theo dõi theo lô (Lot tracking)**:
Chính sách bắt buộc mã lô cho mọi nghiệp vụ làm phát sinh hoặc di chuyển tồn của sản phẩm.

**Yêu cầu hạn dùng (Expiry required)**:
Cấu hình của sản phẩm theo dõi theo lô, xác định hạn dùng có bắt buộc hay không.

**Lô sản xuất (Production lot)**:
Nhóm hàng cùng đợt sản xuất hoặc đóng gói, được gắn chung một mã của nhà sản xuất.

**Batch giao hàng (Supplier delivery batch)**:
Một lần giao hoặc một nhóm giao hàng của nhà cung cấp.

**Batch nhận hàng (Receipt batch)**:
Nhóm thao tác nhận hàng nội bộ.

**Hồ sơ lô (Lot profile)**:
Bản ghi danh tính và thuộc tính dùng chung của một lô sản phẩm.

**Mã lô (Lot code)**:
Mã nhà sản xuất hoặc đơn vị đóng gói công bố trên hàng.

**Độ chính xác hạn dùng (Expiry precision)**:
Mức chi tiết gốc của một hạn dùng, theo tháng và năm hoặc theo ngày.

**Xung đột thuộc tính lô (Lot attribute conflict)**:
Tình huống một lần nhập sau khai ngày sản xuất hoặc hạn dùng khác hồ sơ lô đã có.

### Vòng đời nghiệp vụ tồn kho

**Phiếu nhận hàng (Goods receipt)**:
Hồ sơ một lần nhận hàng vào kho của đơn vị vận hành. Hồ sơ giữ nhà cung cấp, các mục hàng, lô khi có, và trạng thái vật lý của lần nhận. Chỉ khi hoàn tất mới ghi biến động tồn.

**Phiếu nhận hàng nhanh (Quick receipt)**:
Phiếu nhận hàng lập khi hàng đã đến nhưng chưa có chứng từ mua phù hợp. Phiếu này không có trạng thái nháp. Lệnh gửi hợp lệ tạo phiếu ở trạng thái chờ duyệt, và luôn cần duyệt trước khi ghi tồn.

**Nghiệp vụ tồn kho (Inventory Operation)**:
Ý định có định danh làm thay đổi số lượng, trạng thái hoặc giá trị tồn kho.

**Dòng nghiệp vụ (Operation line)**:
Phần của một nghiệp vụ tồn kho gắn với một sản phẩm, một kho, một lượng, một trạng thái và lô nếu có.

**Nháp (Draft)**:
Trạng thái nghiệp vụ còn sửa được nội dung và chưa làm thay đổi tồn.

**Chờ duyệt (Pending approval)**:
Trạng thái nghiệp vụ đã khóa nội dung và đang chờ quyết định phê duyệt.

**Sẵn sàng (Ready)**:
Trạng thái nghiệp vụ đã đủ điều kiện để thực thi.

**Đang xử lý (Processing)**:
Trạng thái nghiệp vụ đang được thực hiện và chưa có kết quả cuối.

**Hoàn tất (Completed)**:
Kết quả cuối xác nhận tác động thuộc chủ sở hữu đã được ghi nhận.

**Từ chối duyệt (Approval rejected)**:
Kết quả người duyệt từ chối nghiệp vụ trước khi thực thi.

**Từ chối thực thi (Execution rejected)**:
Kết quả cuối xác nhận nghiệp vụ không được ghi nhận vì điều kiện hiện hành không đạt.

**Chưa xác định kết quả (Unknown result)**:
Tình trạng chưa đủ bằng chứng để biết nghiệp vụ đã được ghi nhận hay chưa.

**Đã hủy (Cancelled)**:
Kết quả nghiệp vụ kết thúc trước khi bước không thể hủy bắt đầu.

**Mã yêu cầu nghiệp vụ (Operation request ID)**:
Định danh ổn định của một ý định tạo nghiệp vụ tồn kho.

**Phiên bản nguồn (Source version)**:
Số phiên bản tăng dần của chứng từ nguồn gắn với nghiệp vụ.

**Đảo nghiệp vụ (Reversal)**:
Nghiệp vụ mới trung hòa tác động của một nghiệp vụ đã hoàn tất.

**Nghiệp vụ sửa sai (Correction operation)**:
Nghiệp vụ mới ghi cách sửa sai có thẩm quyền và liên kết tới nghiệp vụ gốc.

**Chuỗi sửa sai (Correction chain)**:
Quan hệ giữa nghiệp vụ gốc, nghiệp vụ đảo và nghiệp vụ thay thế.

### Sổ, giữ hàng và kiểm kê

**Sổ biến động số lượng (Inventory movement ledger)**:
Sổ chỉ thêm dòng mới, ghi mọi thay đổi số lượng và trạng thái tồn.

**Sổ biến động giá trị (Inventory value ledger)**:
Sổ chỉ thêm dòng mới, ghi mọi thay đổi giá trị tồn kho.

**Dữ liệu gốc**:
Sổ được dùng làm căn cứ khi số dẫn xuất lệch. Với số lượng, đó là sổ biến động số lượng. Với giá trị, đó là sổ biến động giá trị.
_Avoid_: nguồn sự thật, số dư, projection

**Bút ghi biến động (Inventory movement)**:
Một dòng bất biến trên sổ biến động số lượng, gắn với một nghiệp vụ, một dòng nghiệp vụ, một khóa số dư và một lượng thay đổi.

**Bút ghi giá trị (Inventory value movement)**:
Một dòng bất biến trên sổ biến động giá trị, gắn với nguồn, sản phẩm, kỳ và loại biến động.

**Giữ hàng (Reservation)**:
Cam kết một lượng hàng cho một dòng đơn, theo sản phẩm và kho, trước khi hàng rời kho.

**Giao đủ (Ship complete)**:
Chính sách chỉ xác nhận đơn khi đủ toàn bộ lượng yêu cầu.

**Giao từng phần (Partial fulfillment)**:
Chính sách cho phép giữ lượng đang có và để phần thiếu ở trạng thái chờ hàng.

**Chờ hàng (Backorder)**:
Phần nhu cầu đã được chấp nhận nhưng chưa có lượng khả dụng.

**FEFO (First Expired, First Out)**:
Quy tắc ưu tiên lô còn hợp lệ có hạn dùng sớm nhất.

**FIFO (First In, First Out)**:
Quy tắc ưu tiên lượng nhập trước.

**Lấy hàng (Picking)**:
Việc chọn và thu gom lượng cùng lô cho một đơn.

**Đóng gói (Packing)**:
Việc chuẩn bị hàng đã lấy để bàn giao.

**Bàn giao (Handover)**:
Mốc hàng rời quyền kiểm soát vật lý của kho sang khách hoặc đơn vị vận chuyển.

**Checkout POS (POS checkout)**:
Giao dịch tại quầy, trong đó kiểm tra khả dụng và xuất hàng thuộc cùng một lần bán.

**Phiên kiểm kê (Stock count session)**:
Hồ sơ của một lần kiểm kê, gồm phạm vi, mốc cắt, khóa, lần đếm và kết quả.

**Đếm kín (Blind count)**:
Cách đếm trong đó người đếm chưa thấy số lượng trên sổ trước lần nộp đầu.

**Khóa kiểm kê (Count lock)**:
Khóa đặt trên đúng các khóa số dư thuộc một phiên kiểm kê trong thời gian đếm.

**Chênh lệch kiểm kê (Count discrepancy)**:
Hiệu giữa lượng kiểm đếm được duyệt và lượng trên sổ tại mốc cắt của phiên.

### Giá trị và giá vốn

**Giá trị nhập ban đầu (Initial receipt value)**:
Giá trị được xác lập lần đầu cho lượng hàng thực tế đã nhận, từ các căn cứ hợp lệ có tại thời điểm xác nhận.

**Căn cứ giá trực tiếp (Direct price basis)**:
Căn cứ giá do miền tồn kho lập cho hàng nhập khi không lấy từ nguồn thương mại khác, gồm nguồn, thời điểm và người xác lập.

**Điều chỉnh giá trị hàng nhập (Receipt value adjustment)**:
Thành phần có dấu làm thay đổi giá trị hàng nhập sau khi giá trị nhập ban đầu đã được xác nhận.

**Cấu phần giá trị (Cost component)**:
Khoản làm hình thành hoặc điều chỉnh giá trị hàng nhập, như giá mua, khoản giảm giá trị mua, thuế hoặc phí không thu hồi, và chi phí mua được phân bổ.

**Bình quân gia quyền liên hoàn (Moving weighted average)**:
Cách tính bình quân được cập nhật theo từng biến động đủ điều kiện.

**Bình quân gia quyền cuối kỳ (Periodic weighted average)**:
Cách tính bình quân tại mốc cắt kỳ trên toàn bộ hàng sẵn có của kỳ.

**Phương pháp nguồn (Source costing method)**:
Phương pháp tính giá được đơn vị vận hành chọn trước để dùng khi công bố giá vốn chính thức.

**Giá vốn chính thức (Official inventory cost)**:
Đơn giá tồn kho đã được công bố và đang có hiệu lực.

**Phiên bản giá vốn (Official cost version)**:
Một lần công bố giá vốn chính thức, gồm nguồn tính, thời điểm hiệu lực và người công bố.

**Giá vốn ban đầu của giao dịch (Transaction-time COGS)**:
Giá vốn ghi tại lúc bàn giao theo giá vốn chính thức đang hiệu lực.

**Điều chỉnh giá vốn cuối kỳ (Period-end COGS true-up)**:
Phần chênh lệch bổ sung cho lượng đã xuất khi kết quả cuối kỳ khác giá vốn ban đầu của giao dịch.

**Điều chỉnh giá trị tồn cuối kỳ (Ending inventory adjustment)**:
Phần chênh lệch đưa giá trị lượng còn lại về kết quả tính giá cuối kỳ.

**Đợt điều chỉnh định giá (Valuation adjustment batch)**:
Một lần điều chỉnh gồm điều chỉnh giá vốn cuối kỳ, điều chỉnh giá trị tồn cuối kỳ và công bố phiên bản giá vốn.

**Giá trị ghi sổ (Book value)**:
Tổng giá trị có thẩm quyền của một sản phẩm trên sổ biến động giá trị.

**Ngày nghiệp vụ (Business date)**:
Ngày của sự kiện kinh doanh gốc.

**Ngày ghi nhận (Posting date)**:
Ngày một tác động được ghi vào sổ.

**Ngày hiệu lực (Effective time)**:
Thời điểm một phiên bản hoặc một chính sách bắt đầu được áp dụng.

### Chiết khấu mua và định giá bán

**Khoản ưu đãi mua hàng từ nhà cung cấp (Supplier incentive)**:
Quyền lợi mà doanh nghiệp mua nhận từ nhà cung cấp.
_Avoid_: rebate

**Chiết khấu mua hàng theo kỳ (Period purchase rebate)**:
Ưu đãi được xác định theo doanh số hoặc sản lượng tích lũy trong một kỳ.

**Kịch bản chiết khấu mua hàng (Purchase-discount scenario)**:
Bản tính dự kiến theo sản phẩm, lập trước khi có đơn mua hoặc trước khi hàng về.

**Giá vốn dự kiến (Projected cost)**:
Ước lượng giá vốn sau khi áp các điều kiện ưu đãi giả định.

**Giá vốn tham chiếu định giá (Pricing cost basis)**:
Mốc giá vốn do miền định giá bán công bố để tính giá sàn và giá niêm yết.

**Nguồn giá vốn tham chiếu (Pricing basis source)**:
Loại nguồn và phiên bản đã hình thành một giá vốn tham chiếu định giá.

**Giá sàn (Floor price)**:
Mức giá bán tối thiểu theo chính sách lợi nhuận hoặc rủi ro.

**Giá niêm yết (List price)**:
Giá bán được công bố trước khuyến mại và trước điều chỉnh theo bối cảnh giao dịch.

**Giá bán giao dịch (Transaction sales price)**:
Giá cuối cùng áp cho một dòng bán trong một bối cảnh cụ thể.

**Chính sách lợi nhuận (Profit policy)**:
Quy tắc chuyển giá vốn tham chiếu định giá thành giá sàn và giá niêm yết.

**Tỷ suất lợi nhuận trên doanh thu (Margin)**:
Phần lợi nhuận so với giá bán.

**Tỷ lệ cộng trên giá vốn (Markup)**:
Phần lợi nhuận so với giá vốn.

**Dự thảo giá (Pricing draft)**:
Gói thay đổi giá chưa có hiệu lực, gồm giá vốn tham chiếu, giá sàn, giá niêm yết và căn cứ tính.

**Công bố giá (Price publication)**:
Quyết định của người có thẩm quyền đưa một phiên bản giá bán vào hiệu lực.

**Cập nhật hàng loạt theo giá vốn mới (Bulk pricing-basis update)**:
Việc chọn cập nhật nhiều sản phẩm đang dùng giá vốn chính thức cũ sang giá vốn chính thức mới.

**Rà soát giá dựa trên kịch bản (Scenario-based pricing review)**:
Việc người có thẩm quyền quyết định giữ giá vốn tham chiếu từ kịch bản, thay bằng giá vốn chính thức, hoặc tính lại kịch bản.

**Lợi nhuận tại giao dịch (Transaction-time margin)**:
Lợi nhuận tính từ giá bán giao dịch và giá vốn ban đầu của giao dịch.

**Lợi nhuận sau đối soát (Reconciled margin)**:
Lợi nhuận tính từ giá vốn ban đầu của giao dịch và phần điều chỉnh cuối kỳ.

**Lợi nhuận dự kiến (Projected margin)**:
Lợi nhuận tính từ giá bán đang xét và giá vốn tham chiếu định giá.

### Phê duyệt, đối soát và quyền

**Người lập–người duyệt (Maker–checker)**:
Quy tắc người tạo một nghiệp vụ không được tự phê duyệt nghiệp vụ đó.

**Chính sách phê duyệt (Approval policy)**:
Quy tắc xác định nghiệp vụ nào cần duyệt và cấp quyền cần có.

**Giá trị rủi ro (Approval risk value)**:
Giá trị dùng để định tuyến phê duyệt, lấy từ lượng và căn cứ giá tại lúc gửi duyệt.

**Phạm vi kho (Warehouse scope)**:
Tập kho một người dùng được phép xem hoặc thao tác.

**Quyền tài chính (Financial permission)**:
Quyền được xem dữ liệu về giá mua, giá vốn, giá trị ghi sổ và kịch bản ưu đãi.

**Đối soát (Reconciliation)**:
Việc thu thập và kiểm tra bằng chứng để xác định nguyên nhân, kết quả cuối và cách xử lý của một sai lệch hoặc một kết quả chưa xác định.

**Hồ sơ đối soát (Reconciliation case)**:
Hồ sơ theo dõi một sai lệch giữa nguồn, sổ hoặc số dẫn xuất cho đến khi có bằng chứng xử lý.

**Thẻ kho (Stock card)**:
Báo cáo biến động theo thời gian, gồm tồn đầu, nhập, xuất, tồn cuối và nguồn gốc từng dòng.

**Báo cáo tại thời điểm (Point-in-time report)**:
Báo cáo số dư đến một mốc cắt trong quá khứ.

**Chuyển đổi chính thức**:
Thời điểm chuyển quyền ghi nhận từ hệ thống cũ sang hệ thống mới.
_Avoid_: mốc chuyển đổi

**Batch số dư đầu kỳ (Opening balance batch)**:
Một lần nhập số lượng và tổng giá trị ghi sổ ban đầu khi bắt đầu dùng hệ thống.

**Số kiểm soát (Control total)**:
Tổng đã được duyệt để đối chiếu một lần chuyển dữ liệu hoặc một batch.

### Ngoài Phase 1

**Chuyển kho nội bộ (Internal warehouse transfer)**:
Việc đưa hàng từ kho nguồn, qua hàng đang vận chuyển, đến kho đích.

**Hàng đang vận chuyển (In-transit stock)**:
Hàng đã rời kho nguồn nhưng chưa được nhận tại kho đích.

**Định tuyến kho (Warehouse sourcing)**:
Việc chọn kho đáp ứng một đơn khi có nhiều kho.

**Bán hàng khi mất kết nối (Offline POS)**:
Giao dịch bán được hoàn tất tại quầy khi không có kết nối, rồi được đưa vào sổ sau.

**Serial (Serial number)**:
Mã riêng cho từng đơn vị hàng.

**Quản lý theo serial (Serial tracking)**:
Việc theo dõi từng đơn vị hàng bằng serial.

**Chuyển đổi tracking khi còn tồn (Tracking conversion batch)**:
Một lần gán lô hoặc serial cho tồn hiện có trước khi đổi chính sách theo dõi.

**Dự báo tồn kho (Inventory forecasting)**:
Ước lượng cung và cầu từ lịch sử bán, hàng sắp về và khoảng thời gian xét.

**Đề xuất bổ sung có vòng đời (Replenishment proposal lifecycle)**:
Hồ sơ đề xuất mua có định danh, trạng thái và liên kết tới đơn mua.

**Đóng kho (Warehouse closure)**:
Việc ngừng một kho sau khi đã xử lý hết tồn và các nghĩa vụ còn mở.

### Ngôn ngữ tài liệu

**Quyết định nghiệp vụ (Decision Register)**:
Tập kết luận nghiệp vụ đang có hiệu lực của theme.

**Sổ theo dõi quyết định (decision ledger)**:
Sổ ghi quyết định nào thay quyết định nào, và vì sao.
_Avoid_: nhật ký thay thế
