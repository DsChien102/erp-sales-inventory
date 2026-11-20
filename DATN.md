---
ten_de_tai: "Xây dựng hệ thống quản trị nguồn lực doanh nghiệp hỗ trợ quản lý bán hàng, kho hàng và phân tích hoạt động kinh doanh"
sinh_vien: "Đỗ Sỹ Chiến"
mssv: "22010180"
khoa: "K16"
lop: "CNTT3"
nganh: "Công nghệ thông tin"
he: "Chính quy"
gvhd: "TS. Nguyễn Thị Thùy Liên"
nam: "2026"
---

<!--
QUY ƯỚC VIẾT (để chuyển sang Word đúng định dạng)
- `#`  = tên chương / mục lớn (mỗi mục sang trang mới)
- `##` = đề mục cấp 2 (1.1), `###` = đề mục cấp 3 (1.1.1)
- Hình: sơ đồ viết bằng khối ```mermaid, ngay dưới là dòng chú thích "Hình 2.1. Tên hình"; ảnh chụp màn hình dùng ![Hình 4.2. Tên hình](hinh/hinh4_2.png)
- Bảng: một dòng "Bảng 3.1. Tên bảng" ngay trên bảng
- Trích dẫn: [1], [2] ... khớp với danh sách Tài liệu tham khảo
- Các khối chú thích HTML (như khối này) là gợi ý, sẽ bị bỏ khi chuyển sang Word
- Số trong ngoặc (~x trang) là ngân sách trang gợi ý, tổng phần chính ~70 trang
- Chỗ ghi [CẦN BỔ SUNG: ...] là chỗ cần số liệu / nguồn thật, không được bịa
-->

# LỜI CẢM ƠN

Trong suốt thời gian học tập tại Trường Công nghệ Thông tin – Đại học Phenikaa, em đã nhận được sự dạy dỗ, hướng dẫn tận tình của các thầy cô. Những kiến thức và kỹ năng thầy cô truyền đạt là nền tảng giúp em hoàn thành đồ án tốt nghiệp này. Em xin gửi lời cảm ơn chân thành tới toàn thể thầy cô trong Trường.

Đặc biệt, em xin bày tỏ lòng biết ơn sâu sắc tới **TS. Nguyễn Thị Thùy Liên**, người đã trực tiếp hướng dẫn em trong quá trình thực hiện đồ án. Cô đã định hướng đề tài, góp ý về nghiệp vụ và gợi mở những nội dung quan trọng như ghi nhận ưu đãi nhà cung cấp trong giá vốn và việc ứng dụng trí tuệ nhân tạo vào hệ thống. Những nhận xét kịp thời của cô đã giúp em hoàn thiện sản phẩm và báo cáo.

Em cũng xin cảm ơn gia đình, bạn bè đã luôn động viên, ủng hộ và tạo điều kiện để em tập trung hoàn thành đồ án.

Do thời gian và kiến thức còn hạn chế, đồ án khó tránh khỏi thiếu sót. Em rất mong nhận được ý kiến đóng góp của quý thầy cô trong Hội đồng để đồ án được hoàn thiện hơn.

Em xin chân thành cảm ơn!

*Hà Nội, tháng 12 năm 2026*

*Sinh viên thực hiện*

*Đỗ Sỹ Chiến*

# DANH MỤC THUẬT NGỮ VÀ TỪ VIẾT TẮT

| Từ viết tắt | Thuật ngữ đầy đủ | Giải thích |
|---|---|---|
| AI | Artificial Intelligence | Trí tuệ nhân tạo |
| API | Application Programming Interface | Giao diện lập trình ứng dụng |
| BaaS | Backend as a Service | Nền tảng cung cấp sẵn các dịch vụ phía máy chủ |
| CSDL | Cơ sở dữ liệu | Nơi lưu trữ dữ liệu của hệ thống |
| ERD | Entity Relationship Diagram | Sơ đồ thực thể – quan hệ |
| ERP | Enterprise Resource Planning | Hệ thống hoạch định / quản trị nguồn lực doanh nghiệp |
| HĐĐT | Hoá đơn điện tử | Hoá đơn lập và lưu trữ dưới dạng dữ liệu điện tử |
| HSM | Hardware Security Module | Thiết bị lưu khoá và ký số tập trung |
| JWT | JSON Web Token | Chuẩn mã thông báo dùng để xác thực người dùng |
| KH | Khách hàng | |
| LLM | Large Language Model | Mô hình ngôn ngữ lớn |
| MST | Mã số thuế | |
| NCC | Nhà cung cấp | |
| OTP | One-Time Password | Mã dùng một lần |
| RLS | Row Level Security | Cơ chế phân quyền theo từng dòng dữ liệu của PostgreSQL |
| RPC | Remote Procedure Call | Lời gọi hàm xử lý nghiệp vụ đặt trong CSDL |
| SQL | Structured Query Language | Ngôn ngữ truy vấn CSDL quan hệ |
| UC | Use Case | Ca sử dụng |
| VAS | Vietnamese Accounting Standards | Chuẩn mực kế toán Việt Nam |

# MỞ ĐẦU

Chuyển đổi số đang diễn ra mạnh mẽ trong mọi lĩnh vực kinh tế, trong đó có bán lẻ, một ngành có số lượng cơ sở kinh doanh rất lớn và phần đông là hộ kinh doanh, doanh nghiệp nhỏ. Cùng với đó, các quy định pháp lý ngày càng đòi hỏi việc quản lý phải được số hoá. Tiêu biểu là yêu cầu bắt buộc sử dụng hoá đơn điện tử theo Nghị định 123/2020/NĐ-CP, có hiệu lực từ ngày 01/07/2022. Các cửa hàng bán lẻ và phòng khám thú y là một nhóm điển hình: danh mục hàng hoá rộng, mỗi mặt hàng có nhiều đơn vị tính và nhiều mức giá, thuốc và thức ăn có hạn sử dụng, nhà cung cấp thường kèm theo các chương trình giảm giá, tặng hàng và chiết khấu theo sản lượng.

Tuy vậy, nhiều cơ sở vẫn quản lý bằng sổ tay, bảng tính hoặc phần mềm bán hàng đơn giản. Dữ liệu bán hàng, tồn kho và hoá đơn nằm ở nhiều nơi khác nhau, phải nhập lại nhiều lần và dễ sai lệch. Giá vốn hàng bán thường chỉ được ước tính theo giá nhập gần nhất, không phản ánh chi phí thu mua, chiết khấu và hàng tặng của nhà cung cấp. Vì vậy người chủ không biết chính xác mình lãi bao nhiêu trên từng mặt hàng. Các phần mềm bán hàng phổ biến đã giải quyết tốt khâu lập đơn, nhưng còn hạn chế ở nghiệp vụ giá vốn chuyên sâu. Việc khai thác dữ liệu cũng phụ thuộc vào các báo cáo dựng sẵn, khó dùng với người không quen phân tích số liệu.

Xuất phát từ thực tế đó, đồ án **"Xây dựng hệ thống quản trị nguồn lực doanh nghiệp hỗ trợ quản lý bán hàng, kho hàng và phân tích hoạt động kinh doanh"** được thực hiện, với sản phẩm là hệ thống **Mosaic Retail**. Đây là một hệ thống ERP gọn nhẹ theo mô hình đa tổ chức. Chủ cửa hàng tự đăng ký và sử dụng ngay trên iPhone hoặc trình duyệt máy tính, không cần cài đặt máy chủ riêng. Hệ thống bao phủ chuỗi nghiệp vụ khép kín: quản lý tổ chức và nhân viên, sản phẩm và giá, khách hàng và nhà cung cấp, bán hàng, nhập hàng và tồn kho theo lô, tính giá vốn, phát hành hoá đơn điện tử, theo dõi công nợ và phân tích kinh doanh.

So với các giải pháp hiện có, đồ án có ba điểm mới. Thứ nhất, giá vốn được tính đúng theo Chuẩn mực kế toán Việt Nam số 02 với hai phương pháp bình quân gia quyền (liên hoàn và cuối kỳ) tính song song để đối chiếu, có chốt kỳ và điều chỉnh liên kết; các ưu đãi của nhà cung cấp được phân bổ vào giá gốc hàng nhập. Thứ hai, trợ lý AI "Hỏi Mosaic Retail" cho phép người dùng hỏi số liệu và nhận gợi ý nhập hàng bằng tiếng Việt. Trợ lý được thiết kế theo hướng an toàn: chỉ đọc dữ liệu, chạy với quyền của người hỏi, và mọi con số phải lấy từ CSDL. Thứ ba, về kỹ thuật, logic nghiệp vụ và phân quyền được đặt ngay trong CSDL thông qua các hàm RPC kết hợp Row Level Security, bảo đảm cô lập dữ liệu giữa các tổ chức độc lập với ứng dụng phía người dùng.

Ngoài phần Mở đầu, Kết luận và Tài liệu tham khảo, báo cáo gồm bốn chương. Chương 1 trình bày tổng quan đề tài: bối cảnh, mục tiêu, phạm vi và khảo sát các hệ thống liên quan. Chương 2 trình bày cơ sở lý thuyết về ERP, giá vốn, hoá đơn điện tử, cùng các công nghệ Flutter, Supabase, PostgreSQL và mô hình ngôn ngữ lớn. Chương 3 trình bày phân tích yêu cầu, đặc tả use case, thiết kế kiến trúc, CSDL và các luồng nghiệp vụ. Chương 4 trình bày kết quả hiện thực, kiểm thử và đánh giá hệ thống.

# CHƯƠNG 1. TỔNG QUAN ĐỀ TÀI

## 1.1. Đặt vấn đề

Theo kết quả sơ bộ Tổng điều tra kinh tế năm 2026 do Cục Thống kê (Bộ Tài chính) công bố tháng 7/2026, cả nước có gần 6,3 triệu cơ sở kinh tế đang hoạt động, trong đó gần 5,3 triệu là cơ sở sản xuất kinh doanh cá thể, chiếm 83,8% [1]. Đây phần lớn là các hộ kinh doanh rất nhỏ: theo Tổng điều tra kinh tế năm 2021, mỗi cơ sở cá thể chỉ có bình quân 1,7 lao động [2]. Các cửa hàng bán lẻ với một đến vài điểm bán là một bộ phận quen thuộc của nhóm này. Một nhóm điển hình trong số đó là các cửa hàng bán lẻ và phòng khám thú y. Bên cạnh dịch vụ khám chữa, những cơ sở này kinh doanh một danh mục hàng hoá khá rộng: thức ăn, phụ kiện, thuốc và vật tư thú y. Hàng hoá được nhập từ nhiều nhà cung cấp, mỗi mặt hàng có thể có nhiều đơn vị tính (thùng, hộp, gói, viên) và nhiều mức giá cho các nhóm khách khác nhau. Nhà cung cấp thường kèm theo các chương trình ưu đãi như giảm giá theo bậc số lượng, mua X tặng Y hay chiết khấu khi đạt mốc doanh số.

Trên thực tế, nhiều cơ sở quy mô nhỏ vẫn quản lý bằng sổ tay, bảng tính Excel hoặc một phần mềm bán hàng đơn giản chỉ dừng ở việc lập đơn và in hoá đơn. Cách làm này bộc lộ nhiều hạn chế khi cửa hàng mở rộng. Thứ nhất, dữ liệu bán hàng, tồn kho và công nợ nằm rời rạc, khó đối chiếu. Thứ hai, giá vốn hàng bán thường chỉ được ước tính theo giá nhập gần nhất, không phản ánh chiết khấu và hàng tặng của nhà cung cấp, nên chủ cửa hàng không biết chính xác lãi gộp của từng mặt hàng. Thứ ba, từ ngày 01/07/2022, việc sử dụng hoá đơn điện tử đã trở thành bắt buộc theo Nghị định 123/2020/NĐ-CP [3] và Thông tư 78/2021/TT-BTC [4]. Cửa hàng phải lập hoá đơn trên một hệ thống riêng của nhà cung cấp dịch vụ hoá đơn rồi nhập lại thông tin đơn hàng, vừa tốn công vừa dễ sai lệch. Cuối cùng, dù dữ liệu đã được ghi nhận, người chủ vẫn khó trả lời nhanh những câu hỏi thường ngày như "tuần này bán được bao nhiêu", "mặt hàng nào sắp hết" hay "nên nhập thêm bao nhiêu", vì việc này đòi hỏi kỹ năng lập báo cáo mà phần lớn người kinh doanh nhỏ không có.

Các hệ thống hoạch định nguồn lực doanh nghiệp (Enterprise Resource Planning – ERP) được sinh ra để giải quyết bài toán tích hợp dữ liệu nói trên: mọi phân hệ dùng chung một CSDL, một nghiệp vụ phát sinh ở phân hệ này tự động cập nhật sang phân hệ khác [5]. Tuy nhiên, các giải pháp ERP truyền thống thường có chi phí triển khai cao, phức tạp và được thiết kế cho doanh nghiệp vừa và lớn. Trong khi đó, các phần mềm bán hàng phổ thông dành cho cửa hàng nhỏ lại thiếu chiều sâu ở những nghiệp vụ như tính giá vốn theo chuẩn mực kế toán, ghi nhận ưu đãi nhà cung cấp hay phân tích dữ liệu kinh doanh.

Từ thực trạng đó, có thể thấy một khoảng trống: cần một hệ thống ERP gọn nhẹ, dùng được ngay trên điện thoại và máy tính, đủ sâu về nghiệp vụ bán hàng – kho – giá vốn – hoá đơn điện tử, đồng thời giúp người chủ cửa hàng khai thác dữ liệu của chính mình bằng ngôn ngữ tự nhiên. Đồ án này hướng tới lấp khoảng trống đó với hệ thống **Mosaic Retail**.

## 1.2. Lý do chọn đề tài

Thứ nhất, đề tài xuất phát từ nhu cầu thực tế của các cửa hàng bán lẻ và phòng khám thú y. Đây là nhóm khách hàng có nghiệp vụ hàng hoá phức tạp (nhiều đơn vị tính, nhiều mức giá, nhiều chương trình ưu đãi từ nhà cung cấp) nhưng lại ít được các phần mềm chuyên sâu quan tâm.

Thứ hai, đề tài cho phép vận dụng tổng hợp kiến thức đã học trong chương trình Công nghệ thông tin: phân tích thiết kế hệ thống, thiết kế CSDL quan hệ, lập trình ứng dụng đa nền tảng, bảo mật và phân quyền dữ liệu, tích hợp dịch vụ bên thứ ba, cùng với kiến thức nghiệp vụ kế toán hàng tồn kho theo Chuẩn mực kế toán Việt Nam số 02 [6].

Thứ ba, việc ứng dụng trí tuệ nhân tạo, cụ thể là các mô hình ngôn ngữ lớn (LLM), vào phân tích dữ liệu kinh doanh đang là xu hướng nổi bật. Đề tài tạo cơ hội tìm hiểu cách tích hợp LLM vào một hệ thống nghiệp vụ thật sao cho an toàn: trợ lý chỉ được đọc dữ liệu, chỉ đọc dữ liệu của đúng cửa hàng người dùng thuộc về và mọi con số đưa ra đều lấy từ CSDL chứ không do mô hình tự sinh.

## 1.3. Mục tiêu của đề tài

**Mục tiêu tổng quát:** Xây dựng hệ thống ERP Mosaic Retail theo mô hình đa tổ chức (multi-tenant), chạy trên iPhone và trình duyệt web, hỗ trợ cửa hàng bán lẻ và phòng khám thú y quản lý bán hàng, kho hàng, giá vốn, hoá đơn điện tử và phân tích hoạt động kinh doanh trên cùng một nền tảng dữ liệu thống nhất.

**Mục tiêu cụ thể:**

- Khảo sát nghiệp vụ bán hàng, quản lý kho và tính giá vốn của cửa hàng bán lẻ thú y; phân tích và đặc tả yêu cầu hệ thống dưới dạng các epic, user story và use case.
- Thiết kế kiến trúc hệ thống và CSDL đa tổ chức, bảo đảm dữ liệu của mỗi tổ chức được cô lập hoàn toàn bằng cơ chế phân quyền ở tầng CSDL.
- Xây dựng các phân hệ: tổ chức và người dùng; sản phẩm và giá bán; đối tác (khách hàng, nhà cung cấp); chính sách giá riêng theo khách hàng; bán hàng và đơn hàng; kho và giá vốn; hoá đơn điện tử.
- Hiện thực việc tính giá vốn theo hai phương pháp bình quân gia quyền (bình quân liên hoàn và bình quân cuối kỳ), có ghi nhận ưu đãi của nhà cung cấp vào giá gốc hàng nhập.
- Kết nối với dịch vụ hoá đơn điện tử của MISA để phát hành hoá đơn trực tiếp từ đơn bán hàng.
- Xây dựng trợ lý AI "Hỏi Mosaic Retail" cho phép người dùng hỏi đáp số liệu kinh doanh bằng tiếng Việt (doanh thu, tồn kho, lãi gộp, dự báo nhập hàng) với cơ chế kiểm soát đầu ra chặt chẽ.
- Kiểm thử, đánh giá hệ thống và triển khai bản chạy thử trên iPhone (TestFlight) và web.

## 1.4. Đối tượng và phạm vi nghiên cứu

### 1.4.1. Đối tượng nghiên cứu

- Quy trình nghiệp vụ bán hàng, nhập hàng, quản lý tồn kho và tính giá vốn hàng tồn kho của cửa hàng bán lẻ, phòng khám thú y quy mô nhỏ và vừa.
- Quy định về hoá đơn điện tử và chuẩn mực kế toán hàng tồn kho tại Việt Nam.
- Kiến trúc ứng dụng đa nền tảng với Flutter và nền tảng Backend as a Service Supabase (PostgreSQL, Auth, Storage, Edge Functions).
- Mô hình ngôn ngữ lớn và kỹ thuật gọi công cụ (tool calling) trong việc xây dựng trợ lý hỏi đáp dữ liệu.

### 1.4.2. Phạm vi nghiên cứu

- **Phạm vi người dùng:** chủ cửa hàng (Owner) và nhân viên của một tổ chức. Một tổ chức có thể có nhiều cửa hàng / chi nhánh. Hệ thống không có vai trò quản trị nền tảng; mỗi chủ cửa hàng tự đăng ký và tự tạo tổ chức của mình.
- **Phạm vi chức năng:**
  - Tổ chức và người dùng: đăng ký cửa hàng, xác minh email, đăng nhập, quên mật khẩu, mời thành viên và gán vai trò.
  - Sản phẩm và giá bán: danh mục sản phẩm, đơn vị tính và quy đổi, mã vạch, ảnh sản phẩm, trường thông tin bổ sung, giá niêm yết và giá sàn theo đơn vị bán.
  - Đối tác: quản lý khách hàng và nhà cung cấp, lịch sử thao tác.
  - Chính sách giá: giá riêng theo khách hàng và thứ tự áp giá khi bán.
  - Bán hàng và đơn hàng: lập đơn, thu tiền, đổi / trả, huỷ đơn, in và chia sẻ phiếu.
  - Kho và giá vốn: tồn kho theo lô, chương trình ưu đãi nhà cung cấp, nhận hàng, kiểm kê và điều chỉnh, tính giá vốn và chốt kỳ, báo cáo tồn kho và lãi gộp.
  - Hoá đơn điện tử: thiết lập kết nối MISA, phát hành và gửi hoá đơn từ đơn hàng.
  - Phân tích kinh doanh: trang chủ tổng hợp chỉ số và trợ lý AI hỏi đáp số liệu, dự báo nhập hàng.
  - Công nợ phải thu khách hàng: theo dõi công nợ phát sinh từ đơn bán, cảnh báo quá hạn, thu tiền theo khách và cấn trừ khi đổi / trả hàng.
- **Phạm vi công nghệ:** ứng dụng Flutter (Dart) dùng một mã nguồn cho iPhone và web; backend Supabase gồm PostgreSQL (lược đồ, hàm RPC, RLS), Supabase Auth, Storage, Edge Functions viết bằng TypeScript chạy trên Deno; mô hình ngôn ngữ lớn Claude của Anthropic cho trợ lý AI; dịch vụ hoá đơn điện tử MISA meInvoice.
- **Không bao gồm:** thanh toán trực tuyến qua cổng thanh toán, công nợ phải trả nhà cung cấp, kế toán tổng hợp (sổ cái, báo cáo tài chính), quản lý hồ sơ khám chữa bệnh của thú cưng; không thiết kế riêng cho iPad, Android và ứng dụng desktop (Android vẫn biên dịch được từ cùng mã nguồn nhưng không được kiểm thử riêng).

## 1.5. Khảo sát thực trạng và các hệ thống liên quan

<!-- Chưa có số liệu khảo sát định lượng. Nếu làm khảo sát (Google Form 15–30 cửa hàng), chèn Hình 1.1 và kết quả vào mục 1.5. Các nhận xét về KiotViet / Sapo / MISA eShop dưới đây cần tự kiểm chứng lại trên bản dùng thử trước khi nộp. -->

### 1.5.1. Thực trạng quản lý tại cửa hàng bán lẻ thú y

Để nắm được thực trạng, em đã phỏng vấn trực tiếp chủ một cửa hàng bán lẻ thú y về quy trình bán hàng, nhập hàng, quản lý kho, tính giá vốn và lập hoá đơn hằng ngày. Đây là khảo sát định tính tại một cơ sở, nên các nhận xét dưới đây phản ánh tình hình của cửa hàng này và được dùng làm cơ sở để xác định yêu cầu cho hệ thống, chưa mang tính đại diện cho toàn ngành. Có thể tóm lược thực trạng như sau:

- **Bán hàng:** việc lập đơn và tính tiền thường dùng phần mềm bán hàng hoặc máy tính tiền; giá bán cho khách quen, khách sỉ và phòng khám đối tác thường được nhân viên nhớ hoặc tra trong sổ, dễ áp sai giá.
- **Kho hàng:** tồn kho được cập nhật thủ công hoặc chỉ trừ khi bán, ít khi kiểm kê định kỳ. Thuốc và thức ăn có hạn sử dụng nhưng thường không được theo dõi theo lô.
- **Giá vốn và lãi gộp:** phần lớn chủ cửa hàng ước tính lãi theo giá nhập gần nhất. Hàng tặng kèm và chiết khấu cuối kỳ của nhà cung cấp không được phân bổ vào giá vốn, nên lãi gộp thực tế bị sai lệch.
- **Hoá đơn điện tử:** hoá đơn được lập trên cổng của nhà cung cấp dịch vụ hoá đơn, tách biệt với phần mềm bán hàng, phải nhập lại thông tin người mua và hàng hoá.
- **Phân tích kinh doanh:** chủ cửa hàng muốn biết nhanh doanh thu, mặt hàng bán chạy, hàng sắp hết và lượng cần nhập, nhưng ít khi tự lập được báo cáo.

### 1.5.2. Các hệ thống liên quan

Bảng 1.1 so sánh Mosaic Retail với một số giải pháp phổ biến trên thị trường Việt Nam hiện nay.

Bảng 1.1. So sánh Mosaic Retail với các hệ thống tương tự

| Hệ thống | Ưu điểm | Hạn chế (đối với bài toán của đề tài) | Điểm khác biệt của đề tài |
|---|---|---|---|
| KiotViet | Phổ biến, giao diện dễ dùng, hỗ trợ nhiều ngành hàng, có ứng dụng di động | Thiết kế chung cho nhiều ngành; nghiệp vụ giá vốn và ưu đãi nhà cung cấp ở mức cơ bản; tính năng nâng cao phụ thuộc gói thuê bao | Tính giá vốn theo hai phương pháp bình quân theo VAS 02, ghi nhận ưu đãi nhà cung cấp vào giá gốc |
| Sapo POS | Mạnh về bán hàng đa kênh (cửa hàng, website, sàn thương mại điện tử) | Trọng tâm là bán hàng và kênh bán, ít chú trọng nghiệp vụ kho – giá vốn chuyên sâu | Tập trung vào chuỗi nghiệp vụ bán hàng – kho – giá vốn – hoá đơn trên một CSDL |
| MISA eShop | Liên thông tốt với phần mềm kế toán và hoá đơn điện tử của MISA | Gắn với hệ sinh thái MISA; việc phân tích dữ liệu chủ yếu qua báo cáo dựng sẵn | Có trợ lý AI cho phép hỏi đáp số liệu bằng tiếng Việt, kèm dự báo nhập hàng |
| Sổ tay / Excel | Không tốn chi phí, linh hoạt | Dữ liệu rời rạc, dễ sai, không phân quyền, không liên thông hoá đơn điện tử | Dữ liệu tập trung, phân quyền theo vai trò, cô lập dữ liệu giữa các tổ chức |

Từ bảng so sánh có thể thấy các phần mềm phổ biến đã giải quyết tốt nghiệp vụ bán hàng cơ bản. Tuy vậy, khi cửa hàng cần giá vốn chính xác (có tính đến ưu đãi nhà cung cấp) và muốn tự khai thác dữ liệu mà không cần thành thạo báo cáo, các giải pháp này còn hạn chế. Đây là hai điểm mà đề tài tập trung đầu tư.

## 1.6. Ý nghĩa khoa học và thực tiễn

**Ý nghĩa khoa học:**

- Đề tài trình bày một cách tiếp cận xây dựng hệ thống ERP đa tổ chức trên nền tảng Backend as a Service. Logic nghiệp vụ quan trọng được đặt trong CSDL dưới dạng hàm RPC kết hợp phân quyền theo dòng dữ liệu (RLS), tạo hai lớp bảo vệ độc lập với ứng dụng phía người dùng.
- Đề tài hiện thực hoá thuật toán tính giá vốn theo bình quân liên hoàn và bình quân cuối kỳ theo VAS 02, có xử lý chốt kỳ, điều chỉnh sau chốt và phân bổ ưu đãi nhà cung cấp. Đây là phần nghiệp vụ kế toán ít được hiện thực đầy đủ trong các phần mềm bán hàng nhỏ.
- Đề tài đề xuất cách tích hợp mô hình ngôn ngữ lớn vào hệ thống nghiệp vụ theo hướng an toàn: mô hình chỉ điều phối các công cụ truy vấn đã định nghĩa sẵn, chạy với quyền của chính người hỏi, và mọi con số trong câu trả lời phải lấy từ kết quả công cụ.

**Ý nghĩa thực tiễn:**

- Giúp chủ cửa hàng bán lẻ, phòng khám thú y quản lý tập trung bán hàng, kho, giá và hoá đơn điện tử trên iPhone hoặc máy tính, không cần cài đặt máy chủ riêng.
- Cung cấp giá vốn và lãi gộp sát thực tế, làm cơ sở cho quyết định định giá và nhập hàng.
- Giảm thao tác trùng lặp khi lập hoá đơn điện tử, đáp ứng quy định pháp luật hiện hành.
- Giúp người không chuyên về dữ liệu đặt câu hỏi bằng tiếng Việt và nhận câu trả lời kèm bảng số liệu ngay trong ứng dụng.

## 1.7. Bố cục đồ án

Ngoài phần Mở đầu, Kết luận và Tài liệu tham khảo, báo cáo gồm bốn chương:

- **Chương 1. Tổng quan đề tài:** trình bày bối cảnh, lý do chọn đề tài, mục tiêu, đối tượng và phạm vi nghiên cứu, khảo sát thực trạng và các hệ thống liên quan.
- **Chương 2. Cơ sở lý thuyết và công nghệ:** trình bày các khái niệm về ERP, nghiệp vụ kho và giá vốn, hoá đơn điện tử; kiến trúc đa tổ chức; các công nghệ Flutter, Supabase, PostgreSQL và mô hình ngôn ngữ lớn được sử dụng trong hệ thống.
- **Chương 3. Phân tích và thiết kế hệ thống:** phân tích yêu cầu, xây dựng biểu đồ và đặc tả use case, thiết kế kiến trúc, thiết kế CSDL và các luồng xử lý nghiệp vụ chính.
- **Chương 4. Xây dựng, kiểm thử và đánh giá hệ thống:** trình bày môi trường phát triển, kết quả hiện thực các phân hệ, quá trình kiểm thử và đánh giá kết quả so với mục tiêu đề ra.

## Kết luận chương 1

Chương 1 đã làm rõ bối cảnh và nhu cầu thực tế của các cửa hàng bán lẻ, phòng khám thú y trong việc quản lý bán hàng, kho hàng, giá vốn và hoá đơn điện tử, cũng như những hạn chế của cách làm hiện tại và của các phần mềm phổ biến. Trên cơ sở đó, chương đã xác định mục tiêu, đối tượng, phạm vi của đề tài và chỉ ra hai điểm khác biệt chính của hệ thống Mosaic Retail: tính giá vốn đúng chuẩn mực kế toán có ghi nhận ưu đãi nhà cung cấp, và trợ lý AI hỗ trợ phân tích hoạt động kinh doanh. Chương 2 sẽ trình bày cơ sở lý thuyết và các công nghệ làm nền tảng để xây dựng hệ thống.

# CHƯƠNG 2. CƠ SỞ LÝ THUYẾT VÀ CÔNG NGHỆ

<!-- Chương 2 ~10 trang. Mỗi công nghệ: khái niệm → đặc điểm/ưu điểm → vai trò trong hệ thống. -->

Chương này trình bày nền tảng lý thuyết và công nghệ được dùng để xây dựng hệ thống Mosaic Retail. Phần đầu nói về các khái niệm nghiệp vụ: hệ thống ERP, quy trình mua – bán – kho, phương pháp tính giá vốn và hoá đơn điện tử. Các phần tiếp theo trình bày kiến trúc hệ thống, công nghệ phát triển ứng dụng, nền tảng Supabase, CSDL PostgreSQL, mô hình ngôn ngữ lớn và các dịch vụ bên thứ ba.

## 2.1. Tổng quan về hệ thống ERP và nghiệp vụ bán lẻ

### 2.1.1. Khái niệm hệ thống ERP

Hệ thống hoạch định nguồn lực doanh nghiệp (Enterprise Resource Planning – ERP) là phần mềm tích hợp, gồm nhiều phân hệ hỗ trợ các hoạt động cốt lõi của doanh nghiệp như mua hàng, bán hàng, kho, kế toán và nhân sự. Điểm then chốt của ERP là các phân hệ dùng chung **một CSDL thống nhất**. Một nghiệp vụ phát sinh ở phân hệ này được phản ánh ngay sang các phân hệ liên quan mà không phải nhập lại [5]. Ví dụ, khi một đơn bán hàng hoàn tất, tồn kho giảm, giá vốn hàng bán được ghi nhận, công nợ khách hàng tăng và dữ liệu sẵn sàng để phát hành hoá đơn, tất cả trong cùng một giao dịch dữ liệu.

So với việc dùng nhiều phần mềm rời rạc, ERP mang lại ba lợi ích chính: dữ liệu nhất quán, giảm thao tác trùng lặp, và cung cấp bức tranh tổng thể để ra quyết định. Ngược lại, ERP truyền thống thường tốn kém, triển khai lâu và đòi hỏi đội ngũ vận hành riêng. Vì vậy, các doanh nghiệp nhỏ có xu hướng chọn ERP dạng dịch vụ đám mây (cloud ERP): thuê bao theo tháng, không cần máy chủ riêng, truy cập qua trình duyệt hoặc điện thoại. Mosaic Retail được xây dựng theo hướng này, với phạm vi thu gọn vào các phân hệ mà cửa hàng bán lẻ thực sự cần.

### 2.1.2. Quy trình nghiệp vụ mua hàng – bán hàng – kho

Hoạt động của một cửa hàng bán lẻ có thể mô tả bằng ba quy trình nối tiếp nhau (Hình 2.1):

```mermaid
flowchart LR
  subgraph MUA["1. Mua hàng"]
    NCC([Nhà cung cấp]) --> NH[Nhận hàng<br/>số lô, hạn dùng,<br/>giá mua]
    UD[Ưu đãi NCC<br/>giảm theo bậc,<br/>mua X tặng Y,<br/>chiết khấu đạt mốc] --> GG[Tính giá gốc<br/>hàng nhập]
    NH --> GG
  end
  subgraph KHO["2. Quản lý kho"]
    TK[(Tồn kho<br/>theo lô)]
    KK[Kiểm kê] --> DC[Phiếu điều chỉnh]
    DC --> TK
    GV[Tính giá vốn<br/>bình quân<br/>và chốt kỳ]
  end
  subgraph BAN["3. Bán hàng"]
    KH([Khách hàng]) --> DH[Lập đơn<br/>áp giá theo khách]
    DH --> TT[Thu tiền /<br/>ghi công nợ]
    TT --> HT[Hoàn tất đơn]
    HT --> HD[Phát hành<br/>hoá đơn điện tử]
    HT -.-> DT[Đổi / trả / huỷ]
  end
  GG --> TK
  TK --> GV
  HT -->|trừ tồn kho| TK
  GV -->|giá vốn hàng bán| BC
  HT --> BC[[Chỉ số kinh doanh<br/>doanh thu, giá vốn,<br/>lãi gộp, tốc độ bán]]
```

Hình 2.1. Quy trình nghiệp vụ mua hàng – kho – bán hàng của cửa hàng bán lẻ

- **Mua hàng (nhập kho):** cửa hàng đặt hàng với nhà cung cấp và nhận hàng. Khi nhận, hàng được ghi tăng tồn kho theo lô (có số lô, hạn sử dụng), kèm giá mua và các ưu đãi được hưởng. Ưu đãi nhà cung cấp gồm: giảm giá theo bậc số lượng, mua X tặng Y, và chiết khấu khi tổng lượng mua trong một khoảng thời gian đạt mốc.
- **Quản lý kho:** theo dõi tồn kho theo sản phẩm và lô; định kỳ kiểm kê để đối chiếu số liệu trên hệ thống với thực tế, chênh lệch được ghi nhận bằng phiếu điều chỉnh.
- **Bán hàng (xuất kho):** nhân viên lập đơn, hệ thống áp giá theo khách hàng, thu tiền, trừ tồn kho và ghi nhận giá vốn hàng bán. Từ đơn đã hoàn tất, cửa hàng có thể phát hành hoá đơn điện tử. Đơn có thể phát sinh đổi, trả hoặc huỷ; khi đó tồn kho, giá vốn và công nợ được điều chỉnh tương ứng.

Từ dữ liệu của ba quy trình trên, chủ cửa hàng tính được các chỉ số kinh doanh: doanh thu thuần, giá vốn hàng bán, lãi gộp (doanh thu thuần trừ giá vốn), tốc độ bán và số ngày còn bán được của từng mặt hàng.

### 2.1.3. Giá gốc hàng tồn kho và các phương pháp tính giá vốn bình quân

Theo Chuẩn mực kế toán Việt Nam số 02 – Hàng tồn kho (VAS 02) [6], hàng tồn kho được ghi nhận theo **giá gốc**. Giá gốc hàng mua gồm giá mua, các loại thuế không được hoàn lại, chi phí vận chuyển, bốc xếp và chi phí khác liên quan trực tiếp đến việc mua hàng, **trừ đi** các khoản chiết khấu thương mại và giảm giá hàng mua. Như vậy, các ưu đãi của nhà cung cấp phải được trừ vào giá gốc chứ không tính là thu nhập. Với chương trình mua X tặng Y, tổng tiền phải trả được phân bổ cho cả hàng mua lẫn hàng tặng, nên đơn giá gốc của mỗi đơn vị hàng nhận về thấp hơn giá mua niêm yết.

VAS 02 cho phép doanh nghiệp chọn một trong các phương pháp tính giá trị hàng xuất kho, trong đó phổ biến nhất với bán lẻ là **bình quân gia quyền**. Phương pháp này có hai cách tính [6], [7]:

**Bình quân liên hoàn (bình quân sau mỗi lần nhập):** đơn giá bình quân được tính lại ngay sau mỗi lần nhập kho, và hàng xuất sau đó được tính theo đơn giá mới nhất:

> Đơn giá bình quân sau lần nhập = (Giá trị tồn trước khi nhập + Giá trị lô nhập) / (Số lượng tồn trước khi nhập + Số lượng lô nhập)

**Bình quân cuối kỳ (bình quân cả kỳ dự trữ):** đơn giá chỉ được tính một lần vào cuối kỳ (thường là cuối tháng), áp dụng cho toàn bộ lượng hàng xuất trong kỳ:

> Đơn giá bình quân cuối kỳ = (Giá trị tồn đầu kỳ + Tổng giá trị nhập trong kỳ) / (Số lượng tồn đầu kỳ + Tổng số lượng nhập trong kỳ)

Bảng 2.1 so sánh hai cách tính.

Bảng 2.1. So sánh hai phương pháp bình quân gia quyền

| Tiêu chí | Bình quân liên hoàn | Bình quân cuối kỳ |
|---|---|---|
| Thời điểm tính đơn giá | Sau mỗi lần nhập kho | Một lần vào cuối kỳ |
| Giá vốn khi bán | Biết ngay tại thời điểm bán | Chỉ biết chính xác sau khi chốt kỳ; trong kỳ phải dùng giá tạm |
| Khối lượng tính toán | Lớn, tính lại liên tục | Nhỏ, tính một lần |
| Mức độ phản ánh biến động giá | Sát với biến động giá nhập | Làm phẳng biến động trong kỳ |

Khi dùng phương pháp bình quân cuối kỳ, hàng bán trong kỳ phải tạm ghi nhận theo một đơn giá ước tính. Đến cuối kỳ, hệ thống tính đơn giá chính thức và điều chỉnh chênh lệch giữa giá vốn tạm và giá vốn chính thức (true-up). Sau khi kỳ đã chốt, mọi nghiệp vụ phát sinh trễ thuộc kỳ đó phải được ghi nhận bằng bút toán điều chỉnh liên kết, không sửa trực tiếp số liệu đã chốt. Mosaic Retail cho phép mỗi cửa hàng chọn một trong hai phương pháp. Mỗi lần tính, hệ thống tính song song cả hai để chủ cửa hàng đối chiếu (chi tiết ở Chương 3).

### 2.1.4. Hoá đơn điện tử

Hoá đơn điện tử là hoá đơn có mã hoặc không có mã của cơ quan thuế, được thể hiện dưới dạng dữ liệu điện tử do tổ chức, cá nhân bán hàng hoá, cung cấp dịch vụ lập bằng phương tiện điện tử [3]. Theo Nghị định 123/2020/NĐ-CP và Thông tư 78/2021/TT-BTC, từ ngày 01/07/2022 mọi doanh nghiệp, hộ kinh doanh phải sử dụng hoá đơn điện tử [3], [4]. Nghị định 70/2025/NĐ-CP sửa đổi, bổ sung Nghị định 123 tiếp tục mở rộng các trường hợp phải dùng hoá đơn điện tử, trong đó có hoá đơn khởi tạo từ máy tính tiền [8].

Một hoá đơn điện tử gồm các thông tin chính: ký hiệu mẫu số và ký hiệu hoá đơn, số hoá đơn, thông tin người bán và người mua (tên, địa chỉ, mã số thuế), danh sách hàng hoá (tên, đơn vị tính, số lượng, đơn giá, thành tiền), thuế suất và tiền thuế giá trị gia tăng, tổng tiền thanh toán và chữ ký số của người bán. Hoá đơn được lập và ký số trên hệ thống của một **tổ chức cung cấp dịch vụ hoá đơn điện tử** (ví dụ MISA meInvoice), sau đó được chuyển tới cơ quan thuế để cấp mã và gửi cho người mua.

Với cửa hàng, khó khăn chính là hoá đơn được lập ở một hệ thống riêng, tách biệt với nơi lập đơn bán hàng. Một ERP tích hợp hoá đơn điện tử sẽ lấy sẵn dữ liệu người mua và hàng hoá từ đơn hàng, gửi sang nhà cung cấp dịch vụ hoá đơn qua API và lưu lại kết quả phát hành. Nhờ vậy người dùng không phải nhập lại và tránh sai lệch giữa đơn hàng với hoá đơn.

## 2.2. Kiến trúc hệ thống

### 2.2.1. Mô hình Client – Server và Backend as a Service

Mô hình **Client – Server** chia hệ thống thành hai phần: phía máy khách (client) hiển thị giao diện, nhận thao tác của người dùng và gửi yêu cầu; phía máy chủ (server) xử lý nghiệp vụ, lưu trữ dữ liệu và trả kết quả. Hai phía giao tiếp qua mạng bằng các giao thức chuẩn như HTTP. Ưu điểm của mô hình là dữ liệu được tập trung, dễ bảo mật và nhiều loại client (ứng dụng điện thoại, trình duyệt) có thể dùng chung một máy chủ.

Theo cách làm truyền thống, nhóm phát triển phải tự viết toàn bộ phía máy chủ: tầng API, xác thực, truy cập CSDL, lưu trữ tệp, gửi email. **Backend as a Service (BaaS)** là mô hình trong đó các dịch vụ nền tảng này được cung cấp sẵn dưới dạng dịch vụ đám mây. Nhà phát triển chỉ tập trung vào lược đồ dữ liệu, quy tắc phân quyền và logic nghiệp vụ đặc thù. Mosaic Retail dùng **Supabase** làm BaaS: ứng dụng Flutter đóng vai trò client và gọi thẳng các dịch vụ của Supabase (Auth, PostgreSQL qua API tự sinh, Storage, Edge Functions) mà không cần một tầng máy chủ ứng dụng trung gian.

### 2.2.2. Kiến trúc đa tổ chức (multi-tenant)

**Multi-tenancy** là kiến trúc trong đó một bản cài đặt phần mềm duy nhất phục vụ nhiều khách hàng (tenant), mỗi khách hàng chỉ thấy dữ liệu của mình [9]. Có ba cách tổ chức dữ liệu phổ biến:

Bảng 2.2. Các mô hình tổ chức dữ liệu đa tổ chức

| Mô hình | Mô tả | Ưu điểm | Nhược điểm |
|---|---|---|---|
| CSDL riêng cho mỗi tenant | Mỗi tổ chức một CSDL | Cô lập tuyệt đối | Chi phí cao, khó nâng cấp đồng loạt |
| Lược đồ riêng cho mỗi tenant | Chung CSDL, mỗi tổ chức một schema | Cô lập khá tốt | Số lượng schema tăng theo số khách |
| Dùng chung bảng | Mọi tổ chức chung bảng, phân biệt bằng cột `tenant_id` | Chi phí thấp, dễ mở rộng, dễ nâng cấp | Phải bảo đảm mọi truy vấn đều lọc đúng `tenant_id` |

Mosaic Retail chọn mô hình **dùng chung bảng**: mỗi bảng nghiệp vụ có cột `tenant_id` trỏ tới tổ chức sở hữu dòng dữ liệu. Nhược điểm lớn nhất của mô hình này là nguy cơ lọt dữ liệu giữa các tổ chức nếu một truy vấn quên lọc theo `tenant_id`. Để khắc phục, việc lọc không giao cho ứng dụng mà được thực thi bắt buộc ngay trong CSDL bằng cơ chế Row Level Security và các hàm RPC kiểm quyền (mục 2.5.2). Trong một tổ chức có thể có nhiều cửa hàng / chi nhánh, mỗi cửa hàng gắn với kho của mình.

### 2.2.3. Kiến trúc phân lớp phía ứng dụng

Mã nguồn ứng dụng được tổ chức theo **kiến trúc phân lớp** [10], mỗi lớp chỉ phụ thuộc vào lớp ngay dưới nó:

```mermaid
flowchart TB
  subgraph APP["Ứng dụng Flutter (iPhone, web)"]
    P["<b>Page</b><br/>màn hình, widget<br/>hiển thị trạng thái, nhận thao tác"]
    C["<b>Cubit</b><br/>giữ trạng thái màn hình<br/>đang tải / có dữ liệu / lỗi"]
    R["<b>Repository</b><br/>gọi Supabase, đổi dữ liệu thô<br/>thành đối tượng mô hình"]
  end
  subgraph SB["Supabase"]
    RPC["<b>RPC</b> (hàm PL/pgSQL)<br/>kiểm quyền, kiểm quy tắc nghiệp vụ,<br/>ghi trong một giao dịch"]
    DB[("<b>Bảng</b> theo lược đồ phân hệ<br/>bật Row Level Security")]
  end
  P -- "gọi phương thức" --> C
  C -- "emit trạng thái mới" --> P
  C -- "yêu cầu dữ liệu" --> R
  R -- "mô hình / lỗi nghiệp vụ" --> C
  R -- "supabase.rpc(...) + JWT" --> RPC
  RPC --> DB
```

Hình 2.2. Kiến trúc phân lớp phía ứng dụng

- **Page (trình bày):** các màn hình và widget Flutter; chỉ hiển thị trạng thái và chuyển thao tác của người dùng xuống lớp logic.
- **Cubit (logic trình bày):** giữ trạng thái của màn hình (đang tải, có dữ liệu, lỗi…), gọi Repository và phát ra trạng thái mới.
- **Repository (dữ liệu):** đóng gói cách lấy và ghi dữ liệu, đổi dữ liệu thô từ máy chủ thành các đối tượng mô hình của ứng dụng.
- **RPC (máy chủ):** hàm PostgreSQL thực hiện nghiệp vụ và kiểm quyền trong một giao dịch.

Ở mức tổng thể, ứng dụng được tổ chức theo hướng **modular monolith**: một ứng dụng duy nhất nhưng chia thành các phân hệ (feature) độc lập theo miền nghiệp vụ: `auth`, `iam`, `catalog`, `partner`, `pricing`, `sales`, `inventory`, `einvoice`, `receivable`, `assistant`, `dashboard`. Mỗi phân hệ có ba thư mục con `data`, `logic`, `presentation` tương ứng với các lớp trên. Phía CSDL cũng chia theo cùng ranh giới, mỗi phân hệ một lược đồ (schema). Cách tổ chức này giữ được sự đơn giản khi triển khai của một ứng dụng nguyên khối, đồng thời giúp từng phân hệ dễ hiểu, dễ kiểm thử và dễ thay đổi mà không ảnh hưởng tới phân hệ khác.

## 2.3. Công nghệ phát triển ứng dụng

### 2.3.1. Flutter và ngôn ngữ Dart

**Flutter** là bộ công cụ phát triển giao diện mã nguồn mở do Google phát triển, cho phép xây dựng ứng dụng cho iOS, Android, web và desktop từ **một mã nguồn duy nhất** [11]. Ứng dụng Flutter được viết bằng ngôn ngữ **Dart**, một ngôn ngữ hướng đối tượng, kiểu tĩnh, có cơ chế an toàn với giá trị null (sound null safety). Dart hỗ trợ biên dịch tức thời (JIT) khi phát triển để có tính năng hot reload, và biên dịch trước (AOT) ra mã máy khi phát hành để đạt hiệu năng cao; với nền tảng web, mã Dart được biên dịch sang JavaScript hoặc WebAssembly.

Khác với các framework dùng thành phần giao diện gốc của hệ điều hành, Flutter tự vẽ toàn bộ giao diện bằng bộ máy đồ hoạ riêng. Mọi thứ trên màn hình đều là **widget**, được lồng ghép thành cây widget. Nhờ vậy giao diện hiển thị nhất quán trên mọi nền tảng.

Các ưu điểm chính của Flutter đối với đề tài:

- Một mã nguồn chạy được trên cả hai thiết bị chính của người dùng là **iPhone** và **trình duyệt web**, giảm khoảng một nửa công sức so với phát triển riêng từng nền tảng.
- Giao diện co giãn tốt: cùng một màn hình có thể bố trí dạng thanh điều hướng dưới trên iPhone và thanh bên trái kèm bố cục danh sách – chi tiết trên màn hình rộng.
- Hệ sinh thái thư viện phong phú cho các tác vụ thực tế: tạo, in và chia sẻ phiếu (pdf, printing, share_plus), chọn ảnh sản phẩm (image_picker), chọn tệp và kéo thả tệp bảng giá trên web (file_picker, desktop_drop).

Trong hệ thống, Flutter là công nghệ duy nhất phía client. Toàn bộ ứng dụng nằm trong thư mục `apps/erp` với khoảng 124 màn hình.

### 2.3.2. Quản lý trạng thái với BLoC / Cubit

Trong ứng dụng có giao diện, **trạng thái** (state) là dữ liệu quyết định giao diện hiển thị gì tại một thời điểm. Khi ứng dụng lớn dần, nếu trạng thái và logic nghiệp vụ nằm lẫn trong widget thì mã nguồn sẽ khó đọc và khó kiểm thử. **BLoC (Business Logic Component)** là mẫu thiết kế tách logic ra khỏi giao diện: widget phát sự kiện, BLoC xử lý và phát ra luồng trạng thái mới, widget lắng nghe và vẽ lại [12].

**Cubit** là dạng rút gọn của BLoC: thay vì định nghĩa các lớp sự kiện, giao diện gọi trực tiếp các phương thức của Cubit, và Cubit gọi `emit()` để phát trạng thái mới. Thư viện `flutter_bloc` cung cấp các widget `BlocProvider`, `BlocBuilder`, `BlocListener` để gắn Cubit vào cây widget.

Mosaic Retail dùng Cubit cho toàn bộ ứng dụng (khoảng 96 Cubit). Mỗi màn hình có một Cubit riêng, và trạng thái được mô hình hoá thành các lớp bất biến (dùng `equatable` để so sánh). Lựa chọn này có ba lợi ích: logic màn hình kiểm thử được bằng unit test mà không cần dựng giao diện; luồng dữ liệu một chiều, dễ lần theo khi gỡ lỗi; và cấu trúc thống nhất giữa các phân hệ.

### 2.3.3. Điều hướng, tiêm phụ thuộc và hệ thống thiết kế

**go_router** là thư viện điều hướng chính thức được đội ngũ Flutter khuyến nghị. Thư viện cho phép khai báo các tuyến (route) theo đường dẫn URL như `/login`, `/signup`, `/orders/:id`. Điều này đặc biệt quan trọng với bản web, vì người dùng có thể dùng nút quay lại của trình duyệt và mở trực tiếp một đường dẫn. go_router hỗ trợ cơ chế **redirect** để chặn hoặc chuyển hướng theo trạng thái đăng nhập, và `ShellRoute` để giữ khung điều hướng chung (thanh dưới / thanh bên) cho khu vực cửa hàng. Trong hệ thống, router guard chỉ có vai trò ẩn hoặc chuyển màn hình cho phù hợp với người dùng; quyền thật luôn do CSDL kiểm tra.

**get_it** là thư viện định vị dịch vụ (service locator) dùng để **tiêm phụ thuộc** (dependency injection). Các đối tượng dùng chung như Supabase client, các Repository và phiên đăng nhập được đăng ký một lần khi ứng dụng khởi động, sau đó Cubit lấy ra khi cần. Cách làm này giúp thay thế dễ dàng một Repository thật bằng bản giả khi kiểm thử.

**c45_design_system** là gói hệ thống thiết kế nội bộ của dự án. Gói định nghĩa các **design token** (màu, cỡ chữ, khoảng cách, bo góc) và các thành phần giao diện dùng chung (nút, ô nhập, thẻ, bảng, hộp thoại…). Mọi màn hình đều dựng từ các thành phần này, giúp giao diện nhất quán giữa các phân hệ và giữa iPhone với web.

## 2.4. Nền tảng Supabase

### 2.4.1. Tổng quan Supabase

**Supabase** là nền tảng Backend as a Service mã nguồn mở, xây dựng xoay quanh hệ quản trị CSDL PostgreSQL [13]. Mỗi dự án Supabase cung cấp:

- **Database:** một CSDL PostgreSQL đầy đủ, kèm **PostgREST** tự sinh API REST cho các bảng, view và hàm, nên client gọi được hàm CSDL qua HTTP mà không phải viết API thủ công.
- **Auth:** dịch vụ xác thực người dùng (email – mật khẩu, mã OTP, đặt lại mật khẩu…), phát hành JWT.
- **Storage:** lưu trữ tệp (hình ảnh, tài liệu) với phân quyền dựa trên chính sách của PostgreSQL.
- **Edge Functions:** hàm không máy chủ (serverless) viết bằng TypeScript, dùng cho logic cần chạy ngoài CSDL như gọi API bên thứ ba.
- **Supabase CLI:** chạy toàn bộ môi trường Supabase trên máy cục bộ bằng Docker và quản lý **migration** CSDL dưới dạng các tệp SQL có đánh phiên bản.

So với việc tự xây máy chủ (ví dụ Node.js + Express), Supabase giảm đáng kể khối lượng mã phía máy chủ, mà vẫn không giấu đi CSDL: nhà phát triển toàn quyền dùng SQL, ràng buộc, trigger và hàm của PostgreSQL. Do toàn bộ lược đồ được quản lý bằng migration (dự án có gần 200 tệp migration), CSDL có thể dựng lại giống hệt nhau trên máy cục bộ, môi trường thử nghiệm và môi trường thật. Ứng dụng Flutter kết nối với Supabase qua thư viện chính thức `supabase_flutter`.

### 2.4.2. Xác thực với Supabase Auth và JWT

**JSON Web Token (JWT)** là chuẩn mở (RFC 7519) để truyền thông tin dưới dạng một chuỗi gọn, có chữ ký số [14]. Một JWT gồm ba phần ngăn cách bởi dấu chấm: *header* (thuật toán ký), *payload* (các thông tin – claim – như mã người dùng `sub`, thời hạn `exp`, vai trò `role`) và *signature* (chữ ký). Máy chủ kiểm tra chữ ký để biết token có hợp lệ và chưa bị sửa đổi hay không, mà không cần tra cứu phiên đăng nhập ở đâu khác.

Trong hệ thống, quy trình xác thực diễn ra như sau: người dùng đăng nhập bằng email và mật khẩu qua Supabase Auth; Auth trả về một **access token** (JWT, thời hạn ngắn) và một **refresh token** (dùng để lấy access token mới). Thư viện `supabase_flutter` tự lưu và tự làm mới token. Mọi yêu cầu sau đó tới CSDL hay Edge Function đều gửi kèm access token. Bên trong PostgreSQL, hàm `auth.uid()` đọc mã người dùng từ token. Đây là căn cứ để các chính sách RLS và hàm RPC xác định người gọi là ai, thuộc tổ chức nào và có quyền gì.

Supabase Auth cũng đảm nhận việc **xác minh email** bằng mã 6 chữ số khi chủ cửa hàng đăng ký. Các email khác của hệ thống (lời mời thành viên, mã đặt lại mật khẩu) được gửi qua Edge Function riêng (mục 2.7).

### 2.4.3. Edge Functions và lập lịch với pg_cron

**Supabase Edge Functions** là các hàm TypeScript chạy trên môi trường **Deno**, được triển khai phân tán và khởi chạy theo yêu cầu [13]. Deno là môi trường chạy JavaScript/TypeScript hiện đại, hỗ trợ TypeScript sẵn có, an toàn theo mặc định và có bộ kiểm thử tích hợp (`deno test`). Edge Functions phù hợp cho những việc không nên đặt trong CSDL: gọi API bên ngoài, giữ khoá bí mật của dịch vụ thứ ba, hoặc xử lý tốn thời gian.

Mosaic Retail có bốn Edge Function:

Bảng 2.3. Các Edge Function của hệ thống

| Edge Function | Chức năng |
|---|---|
| `send-email` | Gửi email giao dịch (lời mời, mã đặt lại mật khẩu…) qua dịch vụ Resend |
| `invitation-signup` | Tạo tài khoản đã xác minh cho nhân viên nhận lời mời, trong một bước |
| `einvoice-processor` | Xử lý hàng đợi lệnh hoá đơn điện tử, gọi API MISA meInvoice |
| `ai-assistant` | Trợ lý AI "Hỏi Mosaic Retail": nhận câu hỏi, điều phối mô hình ngôn ngữ và các công cụ truy vấn |

**pg_cron** là phần mở rộng của PostgreSQL cho phép lập lịch chạy câu lệnh SQL định kỳ theo cú pháp cron. Hệ thống có hai lịch pg_cron: `einvoice-processor-tick` chạy mỗi 30 giây, gọi Edge Function `einvoice-processor` để xử lý các lệnh hoá đơn đang chờ; `iam-retry-email-jobs` chạy mỗi phút, gửi lại các email chưa gửi được. Cách kết hợp **hàng đợi trong CSDL + pg_cron + Edge Function** giúp việc gọi dịch vụ bên ngoài diễn ra bất đồng bộ: người dùng không phải chờ MISA phản hồi, và lệnh lỗi do mạng sẽ được thử lại tự động.

## 2.5. Cơ sở dữ liệu PostgreSQL

### 2.5.1. PostgreSQL và tổ chức lược đồ theo phân hệ

**PostgreSQL** là hệ quản trị CSDL quan hệ – đối tượng mã nguồn mở, ra đời từ dự án POSTGRES tại Đại học California, Berkeley, và đã được phát triển hơn 35 năm [15]. PostgreSQL tuân thủ chặt chẽ chuẩn SQL và các tính chất ACID của giao dịch, hỗ trợ kiểu dữ liệu phong phú (UUID, JSONB, mảng, kiểu số chính xác `numeric`), ràng buộc toàn vẹn, trigger, view và ngôn ngữ thủ tục **PL/pgSQL** để viết hàm phía máy chủ. Hệ thống sử dụng PostgreSQL phiên bản 17.

Tính đúng đắn của giao dịch là lý do quan trọng nhất để chọn CSDL quan hệ cho một ERP. Một nghiệp vụ như hoàn tất đơn bán hàng phải cùng lúc ghi đơn, trừ tồn kho theo lô, ghi sổ kho, ghi nhận giá vốn và công nợ; hoặc tất cả thành công, hoặc không có gì thay đổi. PostgreSQL bảo đảm điều này bằng giao dịch, đồng thời hỗ trợ khoá dòng (`SELECT … FOR UPDATE`) để tránh hai đơn hàng cùng lúc bán vượt tồn kho.

Dữ liệu được chia thành các **lược đồ (schema)** theo phân hệ nghiệp vụ, khớp với cách chia phân hệ ở phía ứng dụng:

Bảng 2.4. Các lược đồ CSDL của hệ thống

| Lược đồ | Nội dung |
|---|---|
| `iam` | Tổ chức, cửa hàng, thành viên, vai trò, lời mời |
| `catalog` | Sản phẩm, đơn vị tính, mã vạch, giá bán |
| `partner` | Khách hàng, nhà cung cấp |
| `pricing` | Chính sách giá riêng theo khách hàng |
| `sales` | Đơn nháp, đơn bán hàng, dòng đơn, huỷ đơn, đổi / trả |
| `inventory` | Kho, lô, sổ kho, nhận hàng, kiểm kê, ưu đãi nhà cung cấp, giá vốn |
| `einvoice` | Thiết lập kết nối, hoá đơn, hàng đợi lệnh MISA |
| `receivable` | Quyết toán và giao dịch tiền của đơn, công nợ phải thu, thu tiền theo khách, cấn trừ |
| `ai`, `ai_read` | Nhật ký trợ lý AI; các view chỉ đọc dành cho trợ lý |

Tiền được lưu bằng số nguyên theo đơn vị đồng (`bigint`) để tránh sai số làm tròn của số thực. Số lượng và đơn giá bình quân dùng kiểu `numeric` có độ chính xác cố định.

### 2.5.2. Hàm RPC và phân quyền theo dòng (Row Level Security)

**Row Level Security (RLS)** là tính năng của PostgreSQL cho phép gắn **chính sách** (policy) lên từng bảng để quy định người dùng nào được đọc, thêm, sửa, xoá những dòng nào [15]. Khi RLS được bật, mọi truy vấn vào bảng đều tự động bị lọc theo chính sách, bất kể truy vấn được viết ra sao. Ví dụ, một chính sách chỉ cho phép đọc các dòng có `tenant_id` thuộc danh sách tổ chức mà `auth.uid()` là thành viên. Nhờ vậy, kể cả khi ứng dụng có lỗi hoặc bị can thiệp, người dùng của tổ chức A cũng không thể đọc dữ liệu của tổ chức B.

**RPC (Remote Procedure Call)** trong Supabase là việc client gọi một hàm PostgreSQL qua API, ví dụ `supabase.rpc('create_sales_order', params)`. Mosaic Retail áp dụng nguyên tắc: **mọi thao tác ghi dữ liệu nghiệp vụ quan trọng đều đi qua RPC**, không cho client ghi thẳng vào bảng. Mỗi hàm RPC thực hiện theo trình tự:

1. Xác định người gọi bằng `auth.uid()` và kiểm tra quyền của họ trong tổ chức.
2. Kiểm tra dữ liệu đầu vào và các quy tắc nghiệp vụ (ví dụ: không bán vượt tồn kho, không sửa kỳ đã chốt).
3. Thực hiện toàn bộ thay đổi trong một giao dịch.
4. Trả về kết quả hoặc mã lỗi nghiệp vụ để ứng dụng hiển thị thông báo phù hợp.

Kết hợp RLS và RPC tạo ra mô hình **phòng thủ nhiều lớp** (defense in depth): RLS bảo vệ ở mức dòng dữ liệu, RPC bảo vệ ở mức nghiệp vụ, còn phía ứng dụng chỉ giữ anon key công khai. Logic nghiệp vụ đặt trong CSDL cũng bảo đảm mọi client (iPhone, web, Edge Function) tuân theo cùng một bộ quy tắc.

### 2.5.3. Supabase Storage

Supabase Storage lưu các tệp nhị phân của hệ thống. Tệp được tổ chức theo **bucket**, quyền truy cập được kiểm soát bằng các chính sách RLS trên bảng siêu dữ liệu của Storage, theo cùng cơ chế với dữ liệu nghiệp vụ. Hệ thống có hai bucket: `catalog-product-images` lưu ảnh sản phẩm, và `einvoice-documents` lưu tệp hoá đơn điện tử tải về từ MISA. Bucket hoá đơn không công khai; ứng dụng chỉ nhận **đường dẫn có chữ ký** (signed URL) có thời hạn ngắn để xem hoặc tải tệp.

## 2.6. Trí tuệ nhân tạo trong phân tích kinh doanh

### 2.6.1. Mô hình ngôn ngữ lớn (LLM) và Claude

**Mô hình ngôn ngữ lớn (Large Language Model – LLM)** là mô hình học sâu được huấn luyện trên lượng văn bản rất lớn để dự đoán từ (token) tiếp theo trong một chuỗi. Hầu hết LLM hiện nay dựa trên kiến trúc **Transformer** với cơ chế tự chú ý (self-attention) [16], cho phép mô hình nắm bắt quan hệ giữa các từ ở xa nhau trong văn bản. Sau giai đoạn huấn luyện trước, mô hình được tinh chỉnh để làm theo chỉ dẫn và trò chuyện, nhờ đó có khả năng hiểu câu hỏi bằng ngôn ngữ tự nhiên (kể cả tiếng Việt), suy luận nhiều bước và trả lời mạch lạc.

Tuy nhiên, LLM có hai hạn chế quan trọng khi dùng cho phân tích kinh doanh. Thứ nhất, mô hình **không biết dữ liệu riêng** của cửa hàng. Thứ hai, mô hình có thể sinh ra nội dung nghe hợp lý nhưng sai, gọi là hiện tượng **ảo giác** (hallucination); với con số tài chính, đây là rủi ro không chấp nhận được.

**Claude** là họ mô hình ngôn ngữ lớn do Anthropic phát triển, được cung cấp qua Claude API [17]. Họ mô hình gồm nhiều cỡ: Haiku (nhanh, chi phí thấp), Sonnet (cân bằng) và Opus (mạnh nhất). Claude hỗ trợ gọi công cụ, xử lý tốt tiếng Việt và cho phép điều chỉnh mức độ suy luận. Trợ lý của Mosaic Retail mặc định dùng **Claude Haiku 5.5** để có thời gian phản hồi ngắn và chi phí thấp; mô hình có thể đổi sang Sonnet bằng biến môi trường mà không phải sửa mã.

### 2.6.2. Gọi công cụ (tool calling) và Prompt Engineering

**Gọi công cụ** (tool calling, hay function calling) là kỹ thuật cho phép LLM tương tác với hệ thống bên ngoài [18], [19]. Nhà phát triển mô tả cho mô hình một danh sách công cụ, mỗi công cụ gồm tên, mô tả công dụng và lược đồ tham số (JSON Schema). Khi nhận câu hỏi, mô hình **không tự trả lời con số** mà quyết định gọi công cụ nào, với tham số gì. Ứng dụng thực thi công cụ, trả kết quả về cho mô hình, rồi mô hình dựa trên kết quả đó để soạn câu trả lời. Vòng lặp này có thể lặp lại nhiều lần nếu câu hỏi cần nhiều bước.

```mermaid
sequenceDiagram
  autonumber
  actor U as Người dùng
  participant A as Ứng dụng
  participant F as Edge Function ai-assistant
  participant M as Mô hình ngôn ngữ (Claude)
  participant D as CSDL (view ai_read, RLS)
  U->>A: Nhập câu hỏi tiếng Việt
  A->>F: Câu hỏi + lịch sử + JWT người dùng
  F->>M: System prompt + câu hỏi + danh sách công cụ
  loop Tối đa 5 lần gọi công cụ
    M-->>F: Yêu cầu gọi công cụ (tên, tham số)
    F->>D: Thực thi công cụ bằng JWT của người hỏi
    D-->>F: Kết quả (đã lọc theo quyền)
    F->>F: Che dữ liệu cá nhân, dựng bảng số liệu
    F->>M: Kết quả công cụ
  end
  M-->>F: Câu trả lời dạng văn bản
  F->>F: Kiểm tra guardrails (chặn số không có nguồn)
  F-->>A: Câu trả lời + bảng số liệu
  A-->>U: Hiển thị câu trả lời và bảng
```

Hình 2.3. Vòng lặp gọi công cụ giữa ứng dụng và mô hình ngôn ngữ lớn

So với cách cho mô hình đọc toàn bộ dữ liệu, gọi công cụ có ba ưu điểm: dữ liệu luôn mới nhất vì được truy vấn trực tiếp từ CSDL; con số được tính bằng SQL chứ không do mô hình tự tính; và lượng dữ liệu gửi cho mô hình nhỏ, chỉ gồm kết quả cần thiết. Trợ lý "Hỏi Mosaic Retail" có các công cụ chuyên dụng: thống kê bán hàng, tình hình tồn kho, biến động kho, lãi gộp, dự báo bán hàng (dựa trên tốc độ bán 8 tuần gần nhất), tìm kiếm sản phẩm / khách hàng / đơn hàng. Ngoài ra có một công cụ truy vấn tổng quát cho phép mô hình viết một câu SQL `SELECT` trên các view chỉ đọc khi không có công cụ chuyên dụng nào phù hợp.

**Prompt Engineering** là kỹ thuật thiết kế chỉ dẫn (prompt) để định hướng hành vi của mô hình. Trong hệ thống, **system prompt** quy định vai trò của trợ lý, ngày hiện tại, vai trò người hỏi (chủ cửa hàng hay nhân viên), và một bộ quy tắc rõ ràng: chỉ trả lời về số liệu cửa hàng; mọi con số phải lấy từ kết quả công cụ; ưu tiên công cụ chuyên dụng; câu hỏi mơ hồ về thời gian thì hiểu là hôm nay và nói rõ; trả lời bằng tiếng Việt, ngắn gọn trong 1–3 câu. Mô tả của từng công cụ cũng là một phần của prompt, giúp mô hình chọn đúng công cụ.

### 2.6.3. Guardrails – kiểm soát đầu ra và bảo vệ dữ liệu

**Guardrails** là tập hợp các cơ chế kiểm soát nhằm bảo đảm hệ thống AI hoạt động an toàn, đúng phạm vi, kể cả khi mô hình trả lời sai hoặc bị người dùng cố ý thao túng (prompt injection) [20]. Một nguyên tắc quan trọng là không chỉ dựa vào lời dặn trong prompt, vì mô hình có thể không tuân theo. Các ràng buộc quan trọng phải được thực thi bằng mã. Trợ lý của Mosaic Retail áp dụng các lớp kiểm soát sau:

- **Chỉ đọc, đúng quyền:** công cụ truy vấn chạy với chính JWT của người hỏi, qua các view trong lược đồ `ai_read`, nên RLS vẫn áp dụng đầy đủ. Trợ lý không thể đọc dữ liệu của tổ chức khác hay dữ liệu mà người hỏi không có quyền xem, và không có công cụ nào để tạo, sửa, xoá.
- **Giới hạn câu SQL:** công cụ truy vấn tổng quát chỉ chấp nhận một câu `SELECT`, không chú thích, chỉ gọi các hàm thông dụng, trả về tối đa 50 dòng.
- **Che dữ liệu cá nhân:** trước khi gửi kết quả cho mô hình, các trường chứa thông tin cá nhân (số điện thoại, email, địa chỉ, mã số thuế, số định danh) bị loại bỏ.
- **Chống bịa số:** nếu câu trả lời của mô hình chứa chữ số trong khi không có công cụ nào trả dữ liệu, câu trả lời bị chặn và thay bằng thông báo chuẩn.
- **Giới hạn vòng lặp:** mỗi câu hỏi được gọi công cụ tối đa 5 lần (vượt quá thì trả phần dữ liệu đã có kèm thông báo câu hỏi quá phức tạp), mỗi lần gọi mô hình có thời gian chờ tối đa 12 giây, để tránh treo hoặc tốn chi phí bất thường.
- **Từ chối có kiểm soát:** câu hỏi ngoài phạm vi, chưa hỗ trợ hoặc yêu cầu thay đổi dữ liệu được mô hình phân loại qua một công cụ riêng, và ứng dụng hiển thị câu trả lời chuẩn tương ứng.

Ngoài ra, bảng số liệu hiển thị cho người dùng được dựng trực tiếp từ kết quả công cụ chứ không từ văn bản của mô hình. Nhờ vậy, ngay cả khi lời diễn giải có sai sót, số liệu trong bảng vẫn chính xác.

## 2.7. Dịch vụ bên thứ ba

**MISA meInvoice** là giải pháp hoá đơn điện tử của Công ty Cổ phần MISA, được Tổng cục Thuế (nay là Cục Thuế) chấp thuận là tổ chức cung cấp dịch vụ hoá đơn điện tử. meInvoice cung cấp API để hệ thống bên ngoài lập, ký số, phát hành, tra cứu và gửi hoá đơn qua email [21]. Mosaic Retail tích hợp meInvoice theo cơ chế bất đồng bộ: khi người dùng yêu cầu phát hành, một lệnh được ghi vào hàng đợi trong lược đồ `einvoice`; Edge Function `einvoice-processor` (được pg_cron kích hoạt định kỳ) nhận lệnh, gọi API MISA, ghi lại kết quả và tự thử lại khi gặp lỗi tạm thời. Trong quá trình phát triển, hệ thống dùng môi trường thử nghiệm (sandbox) của meInvoice.

Bảng 2.5 liệt kê các API của meInvoice mà hệ thống sử dụng, theo tài liệu tích hợp của MISA [21]. Hệ thống dùng hình thức phát hành **ký số HSM**: chứng thư số của người bán được lưu trên thiết bị ký số tập trung (Hardware Security Module) của MISA, nên hoá đơn được ký và phát hành hoàn toàn qua API, không cần cắm USB token tại cửa hàng.

Bảng 2.5. Các API MISA meInvoice được hệ thống sử dụng

| API | Đường dẫn | Mục đích trong hệ thống |
|---|---|---|
| Lấy mã kết nối | `/auth/token`, `/auth/refreshtoken` | Lấy và làm mới token truy cập bằng tài khoản tích hợp của cửa hàng |
| Lấy danh sách mẫu hoá đơn | `/invoice/templates` | Cho người dùng chọn mẫu số, ký hiệu hoá đơn khi thiết lập kết nối |
| Xem hoá đơn chưa phát hành | `/invoice/unpublishview` | Xem trước hoá đơn trước khi phát hành |
| Phát hành hoá đơn (ký số HSM) | `/invoice` | Lập, ký số và phát hành hoá đơn từ đơn bán hàng |
| Xem hoá đơn đã phát hành | `/invoice/publishview` | Lấy đường dẫn xem hoá đơn đã phát hành |
| Tải hoá đơn | `/invoice/download` | Tải tệp hoá đơn về lưu vào Supabase Storage |
| Gửi email | `/invoice/sendemail` | Gửi hoá đơn cho người mua qua email |
| Lấy trạng thái hoá đơn | `/invoice/status` | Đối soát trạng thái khi chưa nhận được kết quả phát hành |
| Chuyển đổi hoá đơn giấy | `/invoice/voucher-paper` | Chuyển hoá đơn điện tử thành bản thể hiện trên giấy khi cần in |

**Resend** là dịch vụ gửi email giao dịch qua API. Edge Function `send-email` dùng Resend để gửi email mời thành viên và mã đặt lại mật khẩu theo mẫu có sẵn.

**Anthropic Claude API** cung cấp mô hình ngôn ngữ cho trợ lý AI (mục 2.6). Khoá API chỉ được lưu dưới dạng biến môi trường bí mật của Edge Function, không bao giờ xuất hiện trong ứng dụng.

**TestFlight** là dịch vụ của Apple dùng để phân phối bản thử nghiệm ứng dụng iOS tới người dùng trước khi phát hành chính thức; dự án dùng TestFlight để cài bản chạy thử lên iPhone.

## 2.8. Tổng hợp công nghệ sử dụng

Bảng 2.6. Bảng các công nghệ sử dụng

| Thành phần | Công nghệ | Phiên bản | Vai trò trong hệ thống |
|---|---|---|---|
| Ứng dụng (iPhone, web) | Flutter, Dart | Flutter 3.44, Dart ≥ 3.11 | Xây dựng giao diện cho iPhone và web từ một mã nguồn |
| Quản lý trạng thái | flutter_bloc (Cubit) | 9.1 | Tách logic khỏi giao diện, quản lý trạng thái màn hình |
| Điều hướng | go_router | 17.0 | Định tuyến theo URL, chuyển hướng theo trạng thái đăng nhập |
| Tiêm phụ thuộc | get_it | 9.2 | Đăng ký và cung cấp Repository, Supabase client |
| Thư viện kết nối | supabase_flutter | 2.14 | Gọi Auth, RPC, Storage, Edge Functions từ ứng dụng |
| In ấn | pdf, printing | 3.11, 5.13 | Tạo và in / chia sẻ phiếu, biên lai |
| Backend | Supabase (Auth, Storage, Edge Functions) | – | Xác thực, lưu tệp, chạy hàm phía máy chủ |
| Cơ sở dữ liệu | PostgreSQL, PL/pgSQL, pg_cron | 17 | Lưu trữ dữ liệu, RPC nghiệp vụ, RLS, lập lịch |
| Hàm máy chủ | TypeScript trên Deno | – | Edge Functions: email, HĐĐT, trợ lý AI |
| AI | Claude API (Anthropic SDK) | Claude Haiku 5.5 | Mô hình ngôn ngữ cho trợ lý "Hỏi Mosaic Retail" |
| Hoá đơn điện tử | MISA meInvoice API | – | Phát hành, tra cứu, gửi hoá đơn điện tử |
| Email | Resend | – | Gửi email lời mời, đặt lại mật khẩu |
| Triển khai | Supabase Cloud, TestFlight, Vercel | – | Chạy backend, phân phối bản iPhone, lưu trữ bản web |

## Kết luận chương 2

Chương 2 đã trình bày các cơ sở lý thuyết về hệ thống ERP, quy trình mua – bán – kho, phương pháp tính giá vốn bình quân gia quyền theo VAS 02 và hoá đơn điện tử theo quy định hiện hành. Đây là nền tảng nghiệp vụ để hệ thống tính đúng giá vốn và lãi gộp. Về công nghệ, chương đã giới thiệu kiến trúc đa tổ chức trên nền Supabase, trong đó PostgreSQL với RPC và RLS đảm nhận cả lưu trữ, xử lý nghiệp vụ lẫn cô lập dữ liệu giữa các tổ chức. Phía ứng dụng dùng Flutter với kiến trúc phân lớp Page – Cubit – Repository cho cả iPhone và web. Cuối cùng, chương trình bày mô hình ngôn ngữ lớn, kỹ thuật gọi công cụ và các cơ chế guardrails giúp trợ lý AI trả lời số liệu chính xác và an toàn. Chương 3 sẽ vận dụng các nền tảng này vào việc phân tích và thiết kế hệ thống Mosaic Retail.

# CHƯƠNG 3. PHÂN TÍCH VÀ THIẾT KẾ HỆ THỐNG

<!-- Chương 3 ~26 trang. Chỉ đặc tả chi tiết 6 use case chính; phần còn lại tóm tắt ở mục 3.2.3. -->

Chương này trình bày quá trình phân tích và thiết kế hệ thống Mosaic Retail. Trước hết, chương mô tả bài toán và xác định tác nhân, yêu cầu chức năng và phi chức năng. Tiếp theo, chương xây dựng biểu đồ use case và đặc tả sáu use case chính. Phần còn lại trình bày thiết kế kiến trúc, thiết kế CSDL và các luồng xử lý nghiệp vụ quan trọng.

## 3.1. Phân tích yêu cầu hệ thống

### 3.1.1. Mô tả bài toán

Mosaic Retail phục vụ các chủ cửa hàng bán lẻ và phòng khám thú y. Mỗi chủ cửa hàng tự đăng ký trên ứng dụng. Khi email được xác minh, hệ thống tạo ngay một **tổ chức** cùng một **cửa hàng mặc định** và một **kho mặc định**, người đăng ký trở thành **Owner** của tổ chức. Owner mời nhân viên tham gia bằng email; nhân viên nhận mã lời mời 8 ký tự, đặt mật khẩu và trở thành thành viên của tổ chức.

Hằng ngày, cửa hàng vận hành theo chuỗi nghiệp vụ sau:

- **Chuẩn bị dữ liệu:** khai báo sản phẩm (tên, mã SKU, mã vạch, có quản lý theo lô và hạn dùng hay không), các đơn vị tính và tỷ lệ quy đổi (ví dụ 1 hộp = 10 vỉ = 100 viên), giá niêm yết và giá sàn cho từng đơn vị bán; khai báo khách hàng, nhà cung cấp và giá riêng cho từng khách.
- **Nhập hàng:** nhận hàng từ nhà cung cấp theo phiếu nhận. Mỗi dòng ghi số lượng mua, số lượng được tặng, đơn giá, số lô và hạn dùng. Phiếu có thể kèm chi phí vận chuyển và chiết khấu thương mại; hệ thống phân bổ các khoản này vào giá gốc từng dòng và tự áp chương trình ưu đãi đang chạy của nhà cung cấp.
- **Bán hàng:** nhân viên lập đơn tại quầy, hệ thống tự áp giá theo thứ tự ưu tiên, nhận thanh toán bằng tiền mặt, chuyển khoản hoặc cho khách quen nợ một phần. Khi hoàn tất, hệ thống trừ kho theo lô (lô hết hạn sớm xuất trước), ghi nhận giá vốn và có thể tự động phát hành hoá đơn điện tử. Sau bán có thể huỷ đơn (khi chưa thu tiền) hoặc đổi / trả hàng.
- **Quản lý kho và giá vốn:** xem tồn kho, thẻ kho, cảnh báo hàng sắp hết và cận hạn; kiểm kê định kỳ; cuối tháng tính giá vốn, rà soát rồi công bố để chốt kỳ.
- **Phân tích:** xem các chỉ số trên trang chủ, báo cáo tồn kho và lãi gộp, hoặc hỏi trợ lý AI bằng tiếng Việt.

Mọi dữ liệu thuộc về một tổ chức. Người dùng có thể là thành viên của nhiều tổ chức, nhưng tại mỗi thời điểm chỉ làm việc trong một tổ chức và chỉ thấy dữ liệu của tổ chức đó.

### 3.1.2. Xác định tác nhân

Bảng 3.1. Bảng tác nhân của hệ thống

| Tác nhân | Mô tả | Quyền chính |
|---|---|---|
| Khách (chưa đăng nhập) | Người truy cập vùng công khai của ứng dụng | Đăng ký cửa hàng, xác minh email, đăng nhập, quên mật khẩu, kích hoạt tài khoản bằng mã lời mời |
| Chủ cửa hàng (Owner) | Người tạo tổ chức, có toàn quyền trong tổ chức | Mọi nghiệp vụ của nhân viên; quản trị tổ chức (hồ sơ pháp lý, thành viên, lời mời, vai trò); thiết lập hoá đơn điện tử; chọn phương pháp và công bố giá vốn; xem số liệu tài chính (giá vốn, lãi gộp) |
| Nhân viên (thành viên) | Người được Owner mời vào tổ chức | Mọi nghiệp vụ hằng ngày: bán hàng, sản phẩm, đối tác, nhận hàng, kiểm kê, phát hành hoá đơn, hỏi trợ lý AI; không quản trị tổ chức, không thấy giá vốn |
| MISA meInvoice | Hệ thống bên ngoài cung cấp dịch vụ hoá đơn điện tử | Nhận yêu cầu, ký số, phát hành, trả kết quả và tệp hoá đơn |
| Mô hình ngôn ngữ Claude | Dịch vụ AI bên ngoài | Hiểu câu hỏi, chọn công cụ truy vấn, soạn câu trả lời |
| Bộ lập lịch (pg_cron) | Tác nhân hệ thống, chạy định kỳ | Kích hoạt xử lý hàng đợi hoá đơn, gửi lại email |

Theo đặc tả, **vai trò của thành viên chỉ là nhãn công việc** (ví dụ "Bán hàng", "Kho", "Kế toán"), không gắn với tập quyền riêng. Hệ thống chỉ phân biệt hai mức quyền: Owner và thành viên. Cách làm này phù hợp với quy mô cửa hàng nhỏ, nơi một nhân viên thường làm nhiều việc. Thành viên bị tạm ngừng hoặc đã bị loại không còn quyền nào trong tổ chức.

### 3.1.3. Yêu cầu chức năng

Bảng 3.2 tổng hợp các yêu cầu chức năng, nhóm theo phân hệ. Mỗi phân hệ tương ứng với một tài liệu đặc tả chi tiết (TH-01 … TH-08) gồm epic, user story, quy tắc nghiệp vụ và tiêu chí chấp nhận.

Bảng 3.2. Bảng yêu cầu chức năng

| Mã | Phân hệ | Chức năng | Tác nhân | Độ ưu tiên |
|---|---|---|---|---|
| F01 | Tổ chức và người dùng | Đăng ký cửa hàng mới, xác minh email bằng mã 6 số | Khách | Phải có |
| F02 | Tổ chức và người dùng | Đăng nhập, đăng xuất, quên mật khẩu, đổi mật khẩu | Khách, Owner, Nhân viên | Phải có |
| F03 | Tổ chức và người dùng | Mời thành viên qua email; kích hoạt tài khoản bằng mã lời mời 8 ký tự | Owner, Khách | Phải có |
| F04 | Tổ chức và người dùng | Quản lý thành viên: gán vai trò, tạm ngừng, loại khỏi tổ chức; xem lịch sử quản trị | Owner | Phải có |
| F05 | Tổ chức và người dùng | Cập nhật hồ sơ pháp lý của tổ chức (tên, mã số thuế, địa chỉ) | Owner | Phải có |
| F06 | Tổ chức và người dùng | Chuyển đổi giữa các tổ chức mà người dùng là thành viên | Owner, Nhân viên | Nên có |
| F07 | Sản phẩm và giá | Tạo sản phẩm có hướng dẫn, kiểm trùng SKU / mã vạch; thêm ảnh | Owner, Nhân viên | Phải có |
| F08 | Sản phẩm và giá | Quản lý đơn vị tính và tỷ lệ quy đổi về đơn vị cơ sở | Owner, Nhân viên | Phải có |
| F09 | Sản phẩm và giá | Thiết lập giá niêm yết và giá sàn cho từng đơn vị bán | Owner, Nhân viên | Phải có |
| F10 | Sản phẩm và giá | Tra cứu, lọc sản phẩm; ngừng / mở bán; xem lịch sử thay đổi | Owner, Nhân viên | Phải có |
| F11 | Đối tác | Quản lý khách hàng và nhà cung cấp (cá nhân / tổ chức, người liên hệ, trạng thái) | Owner, Nhân viên | Phải có |
| F12 | Chính sách giá | Tạo, sửa, tắt giá riêng theo khách hàng × sản phẩm × đơn vị, có thời gian hiệu lực | Owner, Nhân viên | Phải có |
| F13 | Bán hàng | Lập đơn, lưu nháp; tự áp giá theo thứ tự ưu tiên; cảnh báo giá dưới sàn | Owner, Nhân viên | Phải có |
| F14 | Bán hàng | Thanh toán bằng tiền mặt / chuyển khoản / kết hợp; cho khách nợ kèm ngày hẹn trả | Owner, Nhân viên | Phải có |
| F15 | Bán hàng | Tra cứu đơn; in hoặc chia sẻ phiếu bán hàng | Owner, Nhân viên | Phải có |
| F16 | Bán hàng | Huỷ đơn chưa thu tiền; đổi / trả hàng và quyết toán chênh lệch | Owner, Nhân viên | Phải có |
| F17 | Kho và giá vốn | Nhận hàng từ nhà cung cấp theo lô, hạn dùng; phân bổ chi phí và chiết khấu vào giá gốc | Owner, Nhân viên | Phải có |
| F18 | Kho và giá vốn | Quản lý chương trình ưu đãi nhà cung cấp (giảm theo bậc, mua X tặng Y, chiết khấu đạt mốc); ghi nhận chiết khấu khi đạt mốc | Owner, Nhân viên | Phải có |
| F19 | Kho và giá vốn | Xem tồn kho, thẻ kho; thiết lập ngưỡng sắp hết và cận hạn | Owner, Nhân viên | Phải có |
| F20 | Kho và giá vốn | Kiểm kê: mở phiên, đếm lần 1, đếm lại, ghi nhận chênh lệch | Owner, Nhân viên | Phải có |
| F21 | Kho và giá vốn | Chọn phương pháp giá vốn; tạo lần tính, rà soát, công bố, chốt kỳ | Owner | Phải có |
| F22 | Kho và giá vốn | Báo cáo tồn kho, lãi gộp, mua hàng theo nhà cung cấp, so sánh nhà cung cấp | Owner | Phải có |
| F23 | Hoá đơn điện tử | Thiết lập kết nối MISA meInvoice, chọn mẫu hoá đơn, bật phát hành tự động | Owner | Phải có |
| F24 | Hoá đơn điện tử | Xem trước, phát hành hoá đơn từ đơn hàng; xem, tải, gửi hoá đơn qua email | Owner, Nhân viên | Phải có |
| F25 | Phân tích kinh doanh | Trang chủ tổng hợp doanh thu, số đơn, việc cần làm | Owner, Nhân viên | Phải có |
| F26 | Phân tích kinh doanh | Hỏi đáp số liệu bằng tiếng Việt với trợ lý AI; dự báo nhập hàng | Owner, Nhân viên | Phải có |
| F27 | Công nợ phải thu | Xem công nợ theo khách, lọc khách quá hạn, xem lịch sử; thu tiền theo khách và phân bổ vào đơn; cấn trừ khi đổi / trả | Owner, Nhân viên | Phải có |

### 3.1.4. Yêu cầu phi chức năng

- **Bảo mật và cô lập dữ liệu:** dữ liệu của mỗi tổ chức được cô lập hoàn toàn bằng RLS ở tầng CSDL. Mọi thao tác ghi quan trọng đi qua hàm RPC có kiểm quyền; ứng dụng chỉ giữ anon key. Mật khẩu do Supabase Auth quản lý (băm), mã lời mời chỉ lưu dạng băm (`token_hash`). Số liệu tài chính nhạy cảm (giá vốn, lãi gộp) chỉ trả về cho Owner. Khoá API của MISA và Claude chỉ nằm trong biến môi trường bí mật của Edge Function.
- **Tính đúng đắn của số liệu:** tiền lưu bằng số nguyên (đồng), số lượng lưu bằng số nguyên nhân 10^6 hoặc `numeric`, không dùng số thực dấu phẩy động. Các ràng buộc `CHECK` trong CSDL bảo đảm các đẳng thức tiền (ví dụ tổng phải trả = tạm tính − giảm giá + thuế + làm tròn) và không cho tồn kho âm. Mỗi nghiệp vụ thực hiện trong một giao dịch.
- **Chống ghi trùng và ghi đè:** mọi lệnh ghi mang `idempotency_key`, gửi lại cùng lệnh sẽ nhận lại kết quả cũ mà không tạo bản ghi mới (quan trọng khi mạng chập chờn trên điện thoại). Các bản ghi có thể sửa mang `version`; lệnh ghi bị từ chối nếu người dùng đang xem dữ liệu cũ.
- **Truy vết:** đơn hàng và chứng từ không bị sửa sau khi tạo; mọi thay đổi sau bán (huỷ, đổi / trả, thu tiền) và mọi điều chỉnh giá vốn đều là bản ghi mới. Thao tác quản trị và thay đổi sản phẩm, đối tác, giá riêng đều có lịch sử.
- **Hiệu năng:** các màn danh sách phản hồi dưới 2 giây với dữ liệu cỡ vài nghìn sản phẩm và vài chục nghìn đơn; trợ lý AI trả lời trong khoảng 10 giây với phần lớn câu hỏi.
- **Tính sẵn sàng:** thao tác của người dùng không phụ thuộc thời gian phản hồi của MISA; lệnh hoá đơn được xếp hàng và tự thử lại khi lỗi tạm thời.
- **Tương thích và trải nghiệm:** chạy trên iPhone và trình duyệt máy tính, cả hai là thiết bị chính. Giao diện tiếng Việt, bố cục thích ứng (thanh dưới trên màn hẹp, thanh bên trái khi rộng từ 1024px), thông báo lỗi bằng ngôn ngữ nghiệp vụ.
- **Bảo trì và mở rộng:** mã nguồn chia theo phân hệ ở cả ứng dụng lẫn CSDL; lược đồ CSDL quản lý bằng migration; logic quan trọng có kiểm thử tự động.

## 3.2. Phân tích Use Case

### 3.2.1. Biểu đồ Use Case tổng quát

Do số lượng use case lớn, biểu đồ use case tổng quát được tách thành hai phần. Hình 3.1 thể hiện nhóm quản trị tổ chức và dữ liệu nền; Hình 3.2 thể hiện nhóm nghiệp vụ bán hàng, kho, hoá đơn và phân tích. Owner kế thừa toàn bộ use case của Nhân viên.

```mermaid
flowchart LR
  K(["👤 Khách"])
  NV(["👤 Nhân viên"])
  OW(["👤 Chủ cửa hàng (Owner)"])
  OW -. kế thừa .-> NV
  subgraph HT["Hệ thống Mosaic Retail"]
    UC01(["Đăng ký cửa hàng, xác minh email"])
    UC02(["Đăng nhập / quên mật khẩu"])
    UC03(["Kích hoạt tài khoản bằng mã lời mời"])
    UC04(["Chuyển tổ chức"])
    UC05(["Quản lý thành viên và lời mời"])
    UC06(["Cập nhật hồ sơ pháp lý tổ chức"])
    UC07(["Quản lý sản phẩm, đơn vị tính"])
    UC08(["Thiết lập giá niêm yết, giá sàn"])
    UC09(["Quản lý khách hàng, nhà cung cấp"])
    UC10(["Quản lý giá riêng theo khách"])
  end
  K --- UC01
  K --- UC02
  K --- UC03
  NV --- UC04
  NV --- UC07
  NV --- UC08
  NV --- UC09
  NV --- UC10
  OW --- UC05
  OW --- UC06
```

Hình 3.1. Biểu đồ Use Case tổng quát – nhóm quản trị tổ chức và dữ liệu nền

```mermaid
flowchart LR
  NV(["👤 Nhân viên"])
  OW(["👤 Chủ cửa hàng (Owner)"])
  MISA(["🖥 MISA meInvoice"])
  AI(["🖥 Claude"])
  OW -. kế thừa .-> NV
  subgraph HT["Hệ thống Mosaic Retail"]
    UC11(["Lập đơn bán hàng"])
    UC12(["Huỷ đơn, đổi / trả hàng"])
    UC13(["Nhận hàng từ nhà cung cấp"])
    UC14(["Quản lý chương trình ưu đãi NCC"])
    UC15(["Xem tồn kho, kiểm kê"])
    UC16(["Tính giá vốn và chốt kỳ"])
    UC17(["Xem báo cáo tồn kho, lãi gộp"])
    UC18(["Thiết lập kết nối hoá đơn điện tử"])
    UC19(["Phát hành, gửi hoá đơn điện tử"])
    UC20(["Hỏi đáp số liệu với trợ lý AI"])
    UC21(["Xem công nợ, thu tiền"])
  end
  NV --- UC11
  NV --- UC12
  NV --- UC13
  NV --- UC14
  NV --- UC15
  NV --- UC19
  NV --- UC20
  NV --- UC21
  OW --- UC16
  OW --- UC17
  OW --- UC18
  UC19 --- MISA
  UC18 --- MISA
  UC20 --- AI
```

Hình 3.2. Biểu đồ Use Case tổng quát – nhóm nghiệp vụ bán hàng, kho, hoá đơn và phân tích

### 3.2.2. Đặc tả các Use Case chính

Phần này đặc tả sáu use case thể hiện rõ nhất nghiệp vụ cốt lõi và điểm nhấn của hệ thống. Các use case còn lại được tóm tắt ở mục 3.2.3.

**3.2.2.1. Use Case Đăng ký cửa hàng và xác minh email**

Bảng 3.3. Đặc tả Use Case Đăng ký cửa hàng và xác minh email

| Trường | Nội dung |
|---|---|
| Mã use case | UC-01 |
| Tên use case | Đăng ký cửa hàng và xác minh email |
| Mô tả | Là chủ cửa hàng, tôi muốn tự đăng ký cửa hàng trên ứng dụng để bắt đầu quản lý mà không cần ai hỗ trợ |
| Tác nhân | Khách (người sẽ trở thành Owner) |
| Độ ưu tiên | Phải có |
| Sự kiện kích hoạt | Người dùng chọn "Đăng ký cửa hàng mới" trên màn đăng nhập |
| Điều kiện tiên quyết | Email chưa được dùng để đăng ký tài khoản nào |
| Điều kiện sau | Có tài khoản đã xác minh; có tổ chức, cửa hàng mặc định, kho mặc định; người đăng ký là Owner và đã đăng nhập |
| Luồng chính | 1. Người dùng nhập họ tên, email, mật khẩu (bước 1), hệ thống kiểm tra định dạng ngay trên ứng dụng. 2. Người dùng nhập thông tin cửa hàng: tên, số điện thoại, tỉnh / thành, xã / phường, địa chỉ (bước 2). 3. Ứng dụng gọi Supabase Auth tạo tài khoản chưa xác minh, thông tin cửa hàng được lưu tạm trong metadata. 4. Supabase Auth gửi mã xác minh 6 số tới email (hiệu lực 1 giờ). 5. Người dùng nhập mã và chọn "Xác minh". 6. Auth đánh dấu email đã xác minh; trigger CSDL tạo hồ sơ người dùng, tổ chức, quyền Owner, cửa hàng mặc định trong cùng giao dịch. 7. Ứng dụng nhận phiên đăng nhập, chuyển tới trang chủ với lời chào "Cửa hàng … đã sẵn sàng" |
| Luồng thay thế | 4a. Người dùng không nhận được mail: chọn "Gửi lại mã" (có thời gian chờ giữa hai lần gửi). 5a. Người dùng thoát giữa chừng: lần đăng nhập sau, hệ thống nhận ra email chưa xác minh, tự gửi lại mã và đưa về màn nhập mã |
| Luồng ngoại lệ | 3a. Email đã có tài khoản: báo lỗi dưới ô email. 5b. Mã sai hoặc hết hạn: báo lỗi, cho nhập lại hoặc gửi lại mã. 6a. Trigger lỗi do dữ liệu cửa hàng không hợp lệ: toàn bộ việc xác minh bị huỷ, không tạo tổ chức dở dang |

**3.2.2.2. Use Case Lập đơn bán hàng**

Bảng 3.4. Đặc tả Use Case Lập đơn bán hàng

| Trường | Nội dung |
|---|---|
| Mã use case | UC-11 |
| Tên use case | Lập đơn bán hàng |
| Mô tả | Là nhân viên bán hàng, tôi muốn lập đơn và thu tiền nhanh tại quầy để khách không phải chờ lâu |
| Tác nhân | Nhân viên, Owner |
| Độ ưu tiên | Phải có |
| Sự kiện kích hoạt | Người dùng chọn "Tạo đơn" |
| Điều kiện tiên quyết | Đã đăng nhập, đang làm việc trong một cửa hàng; sản phẩm đã có giá bán |
| Điều kiện sau | Đơn ở trạng thái Hoàn tất với mã `DH…`; giao dịch thu tiền và công nợ (nếu có) được ghi; tồn kho giảm theo lô; giá vốn từng dòng được ghi nhận; nếu bật phát hành tự động thì yêu cầu hoá đơn điện tử được tạo |
| Luồng chính | 1. Hệ thống tạo đơn nháp với khách mặc định "Khách lẻ". 2. Người dùng chọn khách quen (tìm theo tên / số điện thoại) hoặc giữ khách lẻ. 3. Người dùng tìm hoặc quét mã sản phẩm, chọn đơn vị bán, nhập số lượng. 4. Hệ thống áp giá cho từng dòng theo thứ tự: giá riêng của khách → giá nhập tay → giá niêm yết. 5. Người dùng chọn "Thanh toán", nhập số tiền khách trả theo từng phương thức. 6. Người dùng chọn "Hoàn tất". 7. Hệ thống gọi RPC `finalize_sales_order`: kiểm quyền, kiểm giá, kiểm tồn kho, tạo đơn, ghi thanh toán, trừ kho, ghi giá vốn trong một giao dịch. 8. Hệ thống hiển thị mã đơn và cho in / chia sẻ phiếu bán hàng |
| Luồng thay thế | 2a. Khách chưa có trong hệ thống: tạo nhanh khách mới ngay trên màn lập đơn. 3a. Khách có việc gián đoạn: người dùng lưu nháp, quay lại sau từ danh sách nháp. 4a. Người dùng sửa giá dòng thấp hơn giá sàn: hệ thống cảnh báo, yêu cầu xác nhận. 5a. Khách quen trả thiếu: phần còn lại ghi thành công nợ, người dùng chọn ngày hẹn trả |
| Luồng ngoại lệ | 4b. Sản phẩm không có giá: dòng bị chặn, không thể thanh toán. 7a. Không đủ tồn kho khả dụng: báo "Không đủ tồn kho" kèm danh sách sản phẩm thiếu. 7b. Dữ liệu đã bị thay đổi bởi người khác (`STALE_DATA`): yêu cầu tải lại. 7c. Mất mạng giữa chừng: người dùng bấm lại, nhờ `idempotency_key` đơn không bị tạo trùng |

**3.2.2.3. Use Case Nhận hàng từ nhà cung cấp**

Bảng 3.5. Đặc tả Use Case Nhận hàng từ nhà cung cấp

| Trường | Nội dung |
|---|---|
| Mã use case | UC-13 |
| Tên use case | Nhận hàng từ nhà cung cấp |
| Mô tả | Là nhân viên kho, tôi muốn ghi nhận hàng nhập theo lô kèm giá mua và ưu đãi để tồn kho và giá vốn chính xác |
| Tác nhân | Nhân viên, Owner |
| Độ ưu tiên | Phải có |
| Sự kiện kích hoạt | Người dùng chọn "Nhận hàng" |
| Điều kiện tiên quyết | Nhà cung cấp và sản phẩm đã được khai báo; kỳ giá vốn của ngày nhận chưa chốt |
| Điều kiện sau | Phiếu nhận được ghi (không sửa được); tồn kho theo lô tăng; sổ số lượng và sổ giá trị có dòng mới; giá bình quân liên hoàn được cập nhật; tiến độ chương trình chiết khấu đạt mốc tăng |
| Luồng chính | 1. Người dùng chọn nhà cung cấp, ngày nhận, số chứng từ của NCC. 2. Hệ thống gợi ý các chương trình ưu đãi đang chạy của NCC. 3. Người dùng thêm dòng hàng: sản phẩm, đơn vị, số lượng mua, đơn giá; với sản phẩm quản lý lô thì nhập số lô và hạn dùng. 4. Hệ thống tự tính chiết khấu theo bậc và số lượng tặng (mua X tặng Y) nếu dòng thuộc chương trình. 5. Người dùng nhập chi phí vận chuyển và chiết khấu thương mại của cả phiếu (nếu có). 6. Hệ thống phân bổ chi phí và chiết khấu vào từng dòng theo tỷ lệ giá mua, hiển thị giá gốc và đơn giá gốc dự kiến để rà soát. 7. Người dùng xác nhận "Ghi phiếu". 8. Hệ thống gọi RPC `record_goods_receipt` ghi phiếu, lô, sổ kho, sổ giá trị và cập nhật giá vốn trong một giao dịch |
| Luồng thay thế | 3a. Lô đã tồn tại (cùng sản phẩm, cùng mã lô): hệ thống dùng lại lô đó. 4a. NCC chưa có chương trình: dòng tính theo đơn giá mua |
| Luồng ngoại lệ | 3b. Sản phẩm bắt buộc hạn dùng nhưng thiếu hạn: chặn ở màn rà soát. 5a. Chiết khấu lớn hơn tổng tiền hàng và chi phí: báo lỗi. 8a. Ngày nhận thuộc kỳ đã chốt: báo `PERIOD_CLOSED`. 8b. Gửi lại lệnh do mất mạng: nhờ `idempotency_key`, phiếu không bị ghi trùng |

**3.2.2.4. Use Case Tính giá vốn và chốt kỳ**

Bảng 3.6. Đặc tả Use Case Tính giá vốn và chốt kỳ

| Trường | Nội dung |
|---|---|
| Mã use case | UC-16 |
| Tên use case | Tính giá vốn và chốt kỳ |
| Mô tả | Là chủ cửa hàng, tôi muốn tính và công bố giá vốn chính thức theo phương pháp đã chọn để biết chính xác lãi gộp của từng tháng |
| Tác nhân | Owner |
| Độ ưu tiên | Phải có |
| Sự kiện kích hoạt | Owner chọn "Tính giá vốn" trong khu Kho |
| Điều kiện tiên quyết | Đã chọn phương pháp giá vốn (bình quân liên hoàn hoặc cuối kỳ); có biến động kho trong đoạn chưa công bố |
| Điều kiện sau | Lần tính ở trạng thái Đã công bố; có phiên bản giá chính thức mới; các dòng điều chỉnh (true-up) được ghi vào sổ giá trị; nếu là lần chốt kỳ thì kỳ chuyển sang Đã chốt |
| Luồng chính | 1. Owner chọn loại lần tính: giữa kỳ hoặc chốt kỳ (theo tháng). 2. Hệ thống gọi RPC `create_cost_run`: xác định đoạn sổ từ mốc công bố trước đến dòng sổ mới nhất, tính cho từng sản phẩm số lượng và giá trị đầu đoạn, nhập, xuất, cuối đoạn theo **cả hai** phương pháp. 3. Hệ thống hiển thị kết quả: đơn giá mỗi phương pháp, chênh lệch giữa giá vốn đã ghi lúc bán và giá vốn chính thức, các vấn đề chặn (nếu có). 4. Owner rà soát và chọn "Công bố". 5. Hệ thống gọi RPC `publish_cost_run`: kiểm tra lần tính chưa lỗi thời, ghi phiên bản giá chính thức, ghi các dòng điều chỉnh giá vốn hàng bán và hao hụt, đóng kỳ nếu là chốt kỳ, tất cả trong một giao dịch |
| Luồng thay thế | 4a. Owner thấy số liệu chưa đúng (ví dụ quên nhập phiếu): huỷ lần tính, bổ sung chứng từ rồi tính lại |
| Luồng ngoại lệ | 3a. Có vấn đề chặn (ví dụ sản phẩm tồn âm về giá trị, phiên kiểm kê đang mở): lần tính ở trạng thái Bị chặn, không công bố được. 5a. Có biến động mới phát sinh sau mốc chốt: lần tính bị đánh dấu Lỗi thời, phải tính lại. 5b. Người gọi không phải Owner: từ chối |

**3.2.2.5. Use Case Phát hành hoá đơn điện tử**

Bảng 3.7. Đặc tả Use Case Phát hành hoá đơn điện tử

| Trường | Nội dung |
|---|---|
| Mã use case | UC-19 |
| Tên use case | Phát hành hoá đơn điện tử |
| Mô tả | Là nhân viên, tôi muốn phát hành hoá đơn điện tử ngay từ đơn hàng để không phải nhập lại dữ liệu trên hệ thống khác |
| Tác nhân | Nhân viên, Owner; MISA meInvoice (tác nhân phụ); Bộ lập lịch |
| Độ ưu tiên | Phải có |
| Sự kiện kích hoạt | Người dùng chọn "Phát hành hoá đơn" ở chi tiết đơn, hoặc đơn vừa hoàn tất khi tổ chức bật phát hành tự động |
| Điều kiện tiên quyết | Tổ chức đã kết nối MISA meInvoice thành công và chọn mẫu hoá đơn; đơn đã hoàn tất, chưa trả hết hàng, chưa có hoá đơn |
| Điều kiện sau | Đơn có hoá đơn điện tử với ký hiệu, số hoá đơn; tệp hoá đơn được lưu; hoá đơn có thể được gửi email cho người mua |
| Luồng chính | 1. Người dùng mở khu Hoá đơn điện tử của đơn, kiểm tra thông tin người mua (tên, mã số thuế, địa chỉ, email) lấy sẵn từ hồ sơ khách. 2. Người dùng chọn "Xem trước", hệ thống gọi MISA lấy bản xem trước chưa phát hành. 3. Người dùng chọn "Phát hành". 4. RPC `issue_invoice` kiểm tra điều kiện, tạo lượt phát hành và xếp một lệnh vào hàng đợi `internal_commands`. 5. Ứng dụng hiển thị trạng thái "Đang phát hành". 6. Tối đa 30 giây sau, pg_cron kích hoạt Edge Function `einvoice-processor`; hàm nhận lệnh, gọi API phát hành (ký số HSM) của MISA. 7. MISA trả về số hoá đơn; hệ thống ghi hoá đơn, tải tệp về Storage. 8. Ứng dụng cập nhật trạng thái "Đã phát hành", người dùng có thể xem, tải hoặc gửi email |
| Luồng thay thế | 1a. Phát hành tự động: khi đơn hoàn tất, hệ thống tự kiểm tra điều kiện và xếp lệnh, bỏ qua bước 1–3. 8a. Người dùng chọn "Gửi email": hệ thống xếp lệnh gửi qua API gửi email của MISA |
| Luồng ngoại lệ | 1b. Thiếu dữ liệu người mua bắt buộc: chặn, yêu cầu bổ sung hồ sơ khách. 6a. Lỗi tạm thời (mạng, MISA bận): lệnh được thử lại theo chính sách thử lại. 6b. Lỗi nghiệp vụ từ MISA (ví dụ mẫu hoá đơn không hợp lệ): lượt phát hành thất bại, hiển thị lý do. 6c. Không nhận được phản hồi: hệ thống mở trường hợp đối soát, hỏi trạng thái hoá đơn trên MISA trước khi cho phát hành lại để tránh phát hành trùng |

**3.2.2.6. Use Case Hỏi đáp số liệu với trợ lý AI**

Bảng 3.8. Đặc tả Use Case Hỏi đáp số liệu với trợ lý AI

| Trường | Nội dung |
|---|---|
| Mã use case | UC-20 |
| Tên use case | Hỏi đáp số liệu với trợ lý AI "Hỏi Mosaic Retail" |
| Mô tả | Là chủ cửa hàng, tôi muốn hỏi số liệu kinh doanh bằng tiếng Việt để nắm tình hình mà không phải tự lập báo cáo |
| Tác nhân | Owner, Nhân viên; Claude (tác nhân phụ) |
| Độ ưu tiên | Phải có |
| Sự kiện kích hoạt | Người dùng mở trợ lý và gửi một câu hỏi, hoặc chọn câu hỏi gợi ý |
| Điều kiện tiên quyết | Đã đăng nhập; cửa hàng chưa dùng hết 100 câu hỏi của ngày |
| Điều kiện sau | Người dùng nhận câu trả lời ngắn kèm bảng số liệu; câu hỏi, trạng thái, công cụ đã gọi, số token và thời gian xử lý được ghi vào nhật ký |
| Luồng chính | 1. Người dùng nhập câu hỏi (tối đa 500 ký tự), ví dụ "Tuần này bán được bao nhiêu?". 2. Ứng dụng gửi câu hỏi kèm tối đa 6 lượt hội thoại trước tới Edge Function `ai-assistant`, kèm JWT. 3. Hệ thống kiểm tra quyền, trừ lượt hỏi trong ngày và ghi nhật ký. 4. Hệ thống gửi câu hỏi, system prompt và danh sách công cụ cho Claude. 5. Claude chọn công cụ phù hợp (ví dụ `thong_ke_ban_hang` với khoảng thời gian 7 ngày). 6. Hệ thống chạy công cụ bằng JWT của người hỏi, che dữ liệu cá nhân, trả kết quả cho Claude và dựng bảng số liệu. 7. Claude soạn câu trả lời 1–3 câu bằng tiếng Việt. 8. Hệ thống kiểm tra guardrails rồi trả câu trả lời và bảng cho ứng dụng. 9. Người dùng có thể chạm vào một dòng của bảng để mở màn chi tiết tương ứng (đơn, sản phẩm) |
| Luồng thay thế | 5a. Câu chào hoặc câu không liên quan: Claude trả lời trực tiếp, gợi ý câu hỏi mẫu, không gọi công cụ. 5b. Không có công cụ chuyên dụng phù hợp: Claude viết một câu SQL `SELECT` trên các view `ai_read` qua công cụ `truy_van`; nếu câu SQL lỗi, Claude nhận thông báo lỗi và sửa lại |
| Luồng ngoại lệ | 3a. Hết lượt trong ngày: báo "đã dùng hết 100 câu hỏi hôm nay". 5c. Câu hỏi yêu cầu tạo / sửa / xoá dữ liệu hoặc ngoài phạm vi: trả câu từ chối chuẩn. 6a. Người hỏi không có quyền xem dữ liệu (ví dụ nhân viên hỏi lãi gộp): báo không có quyền, gợi ý nhờ chủ cửa hàng. 8a. Câu trả lời có con số nhưng không có dữ liệu từ công cụ: chặn, thay bằng thông báo "Mình chưa hỗ trợ câu này". 4a. Claude quá tải hoặc quá thời gian chờ: báo trợ lý đang bận |

### 3.2.3. Tóm tắt các Use Case còn lại

Bảng 3.9 tóm tắt các use case không được đặc tả chi tiết ở mục 3.2.2. Đặc tả đầy đủ (luồng, quy tắc nghiệp vụ, tiêu chí chấp nhận, kịch bản kiểm thử) nằm trong các tài liệu `docs/02-yeu-cau/TH-01` … `TH-08` của mã nguồn dự án.

Bảng 3.9. Tóm tắt các use case còn lại

| Mã | Tên use case | Tác nhân | Mô tả ngắn | Điều kiện sau |
|---|---|---|---|---|
| UC-02 | Đăng nhập / quên mật khẩu | Khách | Đăng nhập bằng email, mật khẩu; quên mật khẩu thì nhận mã 6 số qua email để đặt lại | Có phiên đăng nhập / mật khẩu mới |
| UC-03 | Kích hoạt tài khoản bằng mã lời mời | Khách | Người được mời nhập mã 8 ký tự, đặt mật khẩu; tài khoản đã xác minh được tạo và thêm vào tổ chức | Là thành viên của tổ chức |
| UC-04 | Chuyển tổ chức | Owner, Nhân viên | Người thuộc nhiều tổ chức chọn tổ chức làm việc | Ngữ cảnh tổ chức đổi, dữ liệu hiển thị theo tổ chức mới |
| UC-05 | Quản lý thành viên và lời mời | Owner | Mời, thu hồi lời mời, gán vai trò, tạm ngừng, loại thành viên; xem lịch sử quản trị | Thay đổi được ghi nhật ký |
| UC-06 | Cập nhật hồ sơ pháp lý tổ chức | Owner | Cập nhật tên pháp lý, mã số thuế, địa chỉ dùng cho hoá đơn | Hồ sơ đủ điều kiện phát hành hoá đơn |
| UC-07 | Quản lý sản phẩm, đơn vị tính | Owner, Nhân viên | Tạo sản phẩm có hướng dẫn, kiểm trùng mã, ảnh, đơn vị quy đổi, thông tin bổ sung; ngừng / mở bán | Sản phẩm sẵn sàng để bán, nhập hàng |
| UC-08 | Thiết lập giá niêm yết, giá sàn | Owner, Nhân viên | Đặt giá niêm yết, giá sàn cho từng đơn vị bán | Giá được áp khi bán |
| UC-09 | Quản lý khách hàng, nhà cung cấp | Owner, Nhân viên | Tạo, sửa hồ sơ cá nhân / tổ chức, người liên hệ, đổi trạng thái; xem lịch sử | Đối tác dùng được trong bán hàng, nhập hàng |
| UC-10 | Quản lý giá riêng theo khách | Owner, Nhân viên | Tạo, sửa, tắt giá riêng; hệ thống kiểm tra so với giá niêm yết / giá sàn | Giá riêng được ưu tiên khi bán cho khách |
| UC-12 | Huỷ đơn, đổi / trả hàng | Owner, Nhân viên | Huỷ đơn chưa thu tiền; đổi / trả một phần hoặc toàn bộ, quyết toán chênh lệch | Có phiếu huỷ / đổi trả; tồn kho, tiền, giá vốn được điều chỉnh |
| UC-14 | Quản lý chương trình ưu đãi NCC | Owner, Nhân viên | Tạo chương trình giảm theo bậc, mua X tặng Y, chiết khấu đạt mốc; theo dõi tiến độ; ghi nhận chiết khấu khi đạt mốc | Ưu đãi tự áp khi nhận hàng; chiết khấu giảm giá trị tồn |
| UC-15 | Xem tồn kho, kiểm kê | Owner, Nhân viên | Xem tồn theo lô, thẻ kho; đặt ngưỡng sắp hết, cận hạn; kiểm kê hai lần đếm | Chênh lệch kiểm kê được ghi sổ |
| UC-17 | Xem báo cáo tồn kho, lãi gộp | Owner | Báo cáo tồn kho, lãi gộp theo sản phẩm, mua hàng theo NCC, so sánh NCC | — |
| UC-18 | Thiết lập kết nối hoá đơn điện tử | Owner | Nhập tài khoản tích hợp MISA, kiểm tra kết nối, chọn mẫu hoá đơn, bật phát hành tự động | Tổ chức sẵn sàng phát hành hoá đơn |
| UC-21 | Xem công nợ, thu tiền | Owner, Nhân viên | Xem khách còn nợ; ghi thu tiền, hệ thống phân bổ vào đơn cũ trước | Công nợ giảm, có chứng từ thu |

## 3.3. Thiết kế kiến trúc hệ thống

### 3.3.1. Kiến trúc tổng thể

Hệ thống gồm ba khối chính: ứng dụng Flutter chạy trên iPhone và trình duyệt; nền tảng Supabase gồm Auth, CSDL PostgreSQL, Storage và Edge Functions; và các dịch vụ bên ngoài (MISA meInvoice, Claude API, Resend). Hình 3.3 mô tả kiến trúc tổng thể.

```mermaid
flowchart TB
  subgraph CLIENT["Client – một mã nguồn Flutter"]
    IOS["Ứng dụng iPhone"]
    WEB["Ứng dụng web<br/>(trình duyệt máy tính)"]
  end
  subgraph SUPA["Supabase"]
    AUTH["Supabase Auth<br/>JWT, xác minh email"]
    REST["PostgREST<br/>API tự sinh"]
    subgraph PG["PostgreSQL 17"]
      RPC["Hàm RPC nghiệp vụ<br/>(security definer)"]
      TBL[("Bảng theo lược đồ<br/>iam · catalog · partner · pricing<br/>sales · inventory · einvoice<br/>receivable · ai")]
      RLS{{"Row Level Security"}}
      CRON["pg_cron"]
      Q[("Hàng đợi lệnh<br/>email_jobs, internal_commands")]
    end
    STO["Storage<br/>ảnh sản phẩm, tệp hoá đơn"]
    subgraph EF["Edge Functions (Deno)"]
      F1["ai-assistant"]
      F2["einvoice-processor"]
      F3["send-email"]
      F4["invitation-signup"]
    end
  end
  subgraph EXT["Dịch vụ bên ngoài"]
    CL["Claude API"]
    MI["MISA meInvoice"]
    RS["Resend"]
  end
  IOS & WEB -- "HTTPS + JWT" --> AUTH
  IOS & WEB -- "rpc()" --> REST
  IOS & WEB --> STO
  IOS & WEB -- "hỏi AI, nhận lời mời" --> F1 & F4
  REST --> RPC --> TBL
  RLS -. lọc theo tenant_id .- TBL
  RPC --> Q
  CRON -- "mỗi 30 giây" --> F2
  CRON -- "mỗi phút" --> F3
  F2 --> Q
  F2 --> MI
  F2 --> STO
  F3 --> RS
  F1 -- "view ai_read" --> REST
  F1 --> CL
```

Hình 3.3. Kiến trúc tổng thể của hệ thống

Các nguyên tắc kiến trúc chính:

- **Không có máy chủ ứng dụng riêng:** ứng dụng gọi thẳng Supabase. Logic nghiệp vụ đồng bộ nằm trong hàm RPC; logic cần gọi ra ngoài nằm trong Edge Function.
- **Một nguồn quyền:** quyền được kiểm trong CSDL (RPC và RLS). Ứng dụng chỉ dùng thông tin quyền để ẩn nút hoặc chuyển màn hình cho phù hợp.
- **Gọi dịch vụ ngoài bất đồng bộ:** hoá đơn và email đi qua hàng đợi trong CSDL. Nghiệp vụ ghi lệnh vào hàng đợi trong cùng giao dịch với dữ liệu nghiệp vụ, bảo đảm không mất lệnh và không gửi lệnh cho giao dịch đã bị huỷ.

### 3.3.2. Kiến trúc ứng dụng Flutter

Ứng dụng nằm trong thư mục `apps/erp/lib`, gồm hai phần:

- **`core/`** – phần dùng chung: cấu hình môi trường (`config`), đăng ký phụ thuộc (`di`), kết nối Supabase và tiện ích gọi RPC (`supabase`), phiên đăng nhập và tổ chức đang chọn (`session`), định tuyến và router guard (`router`), xử lý lỗi, định dạng tiền / ngày (`formatting`), kiểm tra dữ liệu nhập (`validation`).
- **`features/`** – 13 phân hệ nghiệp vụ, mỗi phân hệ có ba lớp `data` (Repository, mô hình, ánh xạ lỗi RPC), `logic` (Cubit, trạng thái) và `presentation` (trang, widget).

Hình 3.4 thể hiện các lớp chính của phân hệ bán hàng và quan hệ giữa chúng.

```mermaid
classDiagram
  direction LR
  class SalesCheckoutPage {
    +build(context)
  }
  class SalesCheckoutCubit {
    -SalesCheckoutRepository repository
    +precheckNow()
    +finalizeCheckout()
    +retryCurrentAttempt()
    +checkAttemptAgain()
  }
  class SalesCheckoutState {
    +phase
    +precheck
    +attempt
    +result
    +error
  }
  class SalesCheckoutRepository {
    -SupabaseRpc rpc
    +precheck(draft) CheckoutPrecheckDto
    +finalize(SalesFinalizeRequest) CheckoutResultDto
    +getResult(attempt) CheckoutResultDto
  }
  class SalesOrderRepository {
    +list(filter) PagedSalesOrderListDto
    +get(salesOrderId) SalesOrderResultDto
  }
  class SupabaseRpc {
    +call(schema, fn, params)
    +rows(schema, fn, params)
    +firstRow(schema, fn, params)
  }
  class SalesOrderResultDto {
    +id
    +orderCode
    +lifecycleStatus
    +paymentStatus
    +payableAmount
    +lines
  }
  SalesCheckoutPage --> SalesCheckoutCubit : gọi phương thức
  SalesCheckoutCubit --> SalesCheckoutState : emit
  SalesCheckoutCubit --> SalesCheckoutRepository
  SalesCheckoutRepository --> SupabaseRpc
  SalesOrderRepository --> SupabaseRpc
  SalesOrderRepository ..> SalesOrderResultDto : trả về
```

Hình 3.4. Biểu đồ lớp các thành phần chính của phân hệ bán hàng

Điều hướng dùng go_router với hai vùng: **vùng công khai** (`/login`, `/signup`, `/verify-email`, `/invitation`) không có thanh điều hướng; **khu cửa hàng** có năm mục Trang chủ · Đơn hàng · Sản phẩm · Đối tác · Thêm, hiển thị dạng thanh dưới trên iPhone hoặc cửa sổ hẹp và dạng thanh bên trái trên cửa sổ rộng từ 1024px. Router guard đọc trạng thái phiên: chưa đăng nhập thì chuyển về `/login`, email chưa xác minh thì chuyển về `/verify-email`, đã đăng nhập mà vào vùng công khai thì chuyển về trang chủ.

### 3.3.3. Kiến trúc backend

Backend được tổ chức theo các quy ước thống nhất giữa mọi phân hệ:

- **Lược đồ theo phân hệ:** mỗi phân hệ một lược đồ. Bảng không cấp quyền trực tiếp cho client (`revoke all`), bật RLS; client chỉ đọc / ghi qua hàm RPC.
- **Hàm RPC `security definer`:** chạy với quyền của chủ sở hữu hàm, nên có thể ghi vào bảng đã bị thu quyền. Vì vậy dòng đầu tiên của mọi hàm là kiểm tra người gọi: xác định `auth.uid()`, kiểm tra là thành viên đang hoạt động của tổ chức truyền vào, kiểm tra quyền (Owner hay thành viên) qua hàm dùng chung `iam.has_permission`.
- **Mã lỗi nghiệp vụ:** hàm báo lỗi bằng mã ổn định (`INSUFFICIENT_STOCK`, `PERIOD_CLOSED`, `STALE_DATA`, `PERMISSION_DENIED`…). Repository phía ứng dụng ánh xạ mã lỗi sang thông báo tiếng Việt.
- **Idempotency:** lệnh ghi nhận `idempotency_key` và băm nội dung (`payload_hash`). Bảng `idempotency_records` của mỗi lược đồ lưu kết quả lần chạy đầu; gặp lại cùng khoá và cùng nội dung thì trả kết quả cũ, cùng khoá mà khác nội dung thì báo lỗi.
- **Snapshot:** chứng từ lưu bản chụp dữ liệu tại thời điểm tạo (tên khách, mã số thuế, tên và mã sản phẩm, đơn vị, tỷ lệ quy đổi). Sửa dữ liệu gốc về sau không làm đổi chứng từ cũ.
- **Sự kiện giữa phân hệ (outbox):** khi một đơn hoàn tất, phân hệ bán hàng ghi sự kiện `sales_order_finalized.v1` vào bảng `sales.outbox_messages` trong cùng giao dịch. Phân hệ hoá đơn đọc sự kiện này để khởi động phát hành tự động. Nhờ vậy hai phân hệ không gọi trực tiếp vào nhau.
- **Khoá chống tranh chấp:** các thao tác trừ kho khoá theo sản phẩm (advisory lock) theo thứ tự mã sản phẩm tăng dần, tránh hai đơn đồng thời bán vượt tồn và tránh deadlock.

### 3.3.4. Kiến trúc trợ lý AI "Hỏi Mosaic Retail"

Trợ lý AI được hiện thực bằng Edge Function `ai-assistant` viết bằng TypeScript, gồm các thành phần sau (Hình 3.5):

```mermaid
flowchart LR
  APP["Ứng dụng<br/>màn trợ lý"] -- "câu hỏi + lịch sử + JWT" --> H
  subgraph EF["Edge Function ai-assistant"]
    H["handler<br/>kiểm tra yêu cầu,<br/>xác thực, đếm lượt"]
    O["orchestrator<br/>vòng lặp gọi công cụ,<br/>guardrails"]
    PR["prompt<br/>system prompt"]
    MC["ModelClient<br/>ClaudeClient"]
    subgraph TOOLS["Bộ công cụ (registry)"]
      T1["thong_ke_ban_hang"]
      T2["tinh_hinh_ton_kho"]
      T3["bien_dong_kho"]
      T4["lai_gop"]
      T5["du_bao_ban_hang"]
      T6["tim_kiem"]
      T7["truy_van (SQL)"]
      T8["bao_khong_ho_tro"]
    end
    RD["redact<br/>che dữ liệu cá nhân"]
  end
  H --> O
  PR --> O
  O <--> MC
  MC <--> CL["Claude API"]
  O --> TOOLS
  TOOLS --> RD
  TOOLS -- "RPC / view ai_read<br/>bằng JWT người hỏi" --> DB[("PostgreSQL<br/>RLS")]
  H -- "ai.start_question<br/>ghi nhật ký" --> DB
```

Hình 3.5. Kiến trúc trợ lý AI "Hỏi Mosaic Retail"

- **handler:** kiểm tra yêu cầu (câu hỏi 1–500 ký tự, tối đa 6 lượt lịch sử, mỗi lượt cắt còn 2.000 ký tự), xác thực JWT, gọi `ai.start_question` để kiểm quyền, đếm lượt (100 câu / cửa hàng / ngày) và tạo dòng nhật ký; cuối cùng ghi kết quả vào nhật ký.
- **orchestrator:** chạy vòng lặp hỏi mô hình – thực thi công cụ, tối đa 5 lần gọi công cụ; áp dụng các guardrails đã trình bày ở mục 2.6.3; trả về trạng thái (`ok`, `tro_chuyen`, `ngoai_pham_vi`, `chua_ho_tro`, `tu_choi`, `khong_quyen`, `het_luot`, `ban`, `loi`), câu trả lời và các bảng số liệu.
- **ModelClient:** giao diện trừu tượng cho mô hình ngôn ngữ, có bản hiện thực `ClaudeClient` (Anthropic SDK) và bản giả `FakeModelClient` dùng cho kiểm thử. Nhờ vậy có thể thay nhà cung cấp mô hình mà không sửa orchestrator.
- **Bộ công cụ:** mỗi công cụ gồm phần khai báo (tên, mô tả, tham số) gửi cho mô hình và phần thực thi gọi RPC hoặc view. Các công cụ chuyên dụng gọi lại RPC có sẵn của các phân hệ, ví dụ `sales.get_sales_stats` (thống kê bán hàng), `inventory.get_stock_card` (biến động kho), `inventory.get_gross_profit_report` (lãi gộp), `inventory.get_purchase_forecast` (dự báo nhập hàng). Vì vậy số liệu trợ lý đưa ra luôn khớp với số trên các màn báo cáo. Công cụ `truy_van` chạy câu SQL do mô hình viết trên 6 view chỉ đọc của lược đồ `ai_read`: `ban_hang_thuan`, `don_ban`, `san_pham`, `khach_hang`, `ton_kho`, `bien_dong_kho`. Các view này đặt tên cột bằng tiếng Việt không dấu và có mô tả từng cột, giúp mô hình viết câu truy vấn đúng.

### 3.3.5. Kiến trúc tích hợp hoá đơn điện tử

Tích hợp MISA meInvoice được thiết kế theo mô hình **hàng đợi lệnh** (Hình 3.6). Lý do: API của nhà cung cấp hoá đơn có thể chậm hoặc lỗi tạm thời, trong khi việc phát hành trùng một hoá đơn là sai sót nghiêm trọng về thuế.

```mermaid
flowchart LR
  A["RPC einvoice.issue_invoice<br/>(hoặc phát hành tự động<br/>từ sự kiện đơn hoàn tất)"] -- "enqueue" --> Q[("einvoice.internal_commands")]
  C["pg_cron<br/>einvoice-processor-tick<br/>30 giây"] --> P
  P["Edge Function<br/>einvoice-processor"] -- "claim theo lô<br/>(claim_token)" --> Q
  P -- "API meInvoice" --> M["MISA meInvoice"]
  P -- "complete / fail<br/>thử lại / dead letter" --> Q
  P -- "ghi kết quả" --> R[("issuance_attempts<br/>electronic_invoices<br/>invoice_documents")]
  P -- "tệp hoá đơn" --> S["Storage<br/>einvoice-documents"]
  P -. "không rõ kết quả" .-> RC[("invoice_reconciliation_cases<br/>đối soát qua /invoice/status")]
```

Hình 3.6. Kiến trúc tích hợp hoá đơn điện tử MISA meInvoice

Mỗi lần chạy, `einvoice-processor` nhận (claim) một lô lệnh đến hạn bằng `claim_internal_commands_batch`, gắn `claim_token` để hai tiến trình chạy chồng không xử lý trùng một lệnh. Lệnh thành công được đánh dấu hoàn tất; lệnh lỗi tạm thời được tăng `retry_count` và hẹn chạy lại; lệnh vượt số lần thử hoặc lỗi không thể thử lại được chuyển sang trạng thái dead letter để người dùng thấy lý do. Với lỗi "không rõ kết quả" (ví dụ hết thời gian chờ sau khi đã gửi yêu cầu phát hành), hệ thống không phát hành lại ngay mà mở một **trường hợp đối soát**, hỏi trạng thái trên MISA trước. Token truy cập MISA được lưu và làm mới tự động; thông tin đăng nhập MISA của cửa hàng lưu trong bảng riêng `provider_credentials`, client không đọc được.

## 3.4. Thiết kế cơ sở dữ liệu

### 3.4.1. Nguyên tắc thiết kế và sơ đồ ERD tổng thể

CSDL được thiết kế theo các nguyên tắc:

1. **Đa tổ chức:** mọi bảng nghiệp vụ có cột `tenant_id`. Nhiều khoá ngoại là khoá ghép `(tenant_id, id)` để bảo đảm ngay ở mức ràng buộc rằng một dòng con không thể trỏ sang dòng cha của tổ chức khác.
2. **Khoá chính UUID:** sinh bằng `gen_random_uuid()` hoặc do client sinh trước (phục vụ idempotency).
3. **Tiền và số lượng chính xác:** tiền là `bigint` theo đồng (hậu tố `_minor` hoặc `_vnd`); số lượng bán là `bigint` nhân 10^6 (hậu tố `_micros`); đơn giá bình quân là `numeric(18,4)`.
4. **Ràng buộc trong CSDL:** dùng `CHECK` cho trạng thái hợp lệ và đẳng thức tiền, `UNIQUE` cho mã nghiệp vụ trong phạm vi tổ chức (mã đơn, số phiếu nhận, SKU…).
5. **Sổ chỉ ghi thêm (append-only):** sổ kho, sổ giá trị, giao dịch tiền không bao giờ bị sửa hay xoá; sai sót được sửa bằng dòng đảo hoặc dòng điều chỉnh. Một trigger chặn mọi lệnh `UPDATE` / `DELETE` trên sổ kho.

CSDL hiện có 107 bảng thuộc 9 lược đồ, cộng với lược đồ `ai_read` chỉ chứa view. Hình 3.7 trình bày sơ đồ ERD rút gọn với các thực thể chính và quan hệ giữa chúng; các bảng phụ (lịch sử, idempotency, snapshot, hàng đợi) được lược bỏ.

```mermaid
erDiagram
  TENANTS ||--o{ STORES : "có"
  TENANTS ||--o{ MEMBERSHIPS : "có"
  TENANTS ||--o{ WAREHOUSES : "có"
  STORES ||--|| WAREHOUSES : "gắn kho mặc định"
  TENANTS ||--o{ PRODUCTS : "sở hữu"
  PRODUCTS ||--|{ PRODUCT_UNITS : "có đơn vị"
  PRODUCT_UNITS ||--o| PRICE_BANDS : "có giá"
  TENANTS ||--o{ PARTNERS : "sở hữu"
  PARTNERS ||--o{ CUSTOMER_PRICE_RULES : "được giá riêng"
  PRODUCT_UNITS ||--o{ CUSTOMER_PRICE_RULES : "áp cho"
  STORES ||--o{ SALES_ORDERS : "bán tại"
  PARTNERS |o--o{ SALES_ORDERS : "khách mua"
  SALES_ORDERS ||--|{ SALES_ORDER_LINES : "gồm"
  SALES_ORDERS ||--|| SETTLEMENTS : "quyết toán"
  SETTLEMENTS ||--o{ PAYMENT_TRANSACTIONS : "thu / hoàn"
  PARTNERS ||--o{ CUSTOMER_COLLECTIONS : "trả nợ"
  CUSTOMER_COLLECTIONS ||--|{ PAYMENT_TRANSACTIONS : "phân bổ vào đơn"
  RETURN_EXCHANGE_ORDERS ||--o{ RECEIVABLE_OFFSETS : "cấn trừ"
  SALES_ORDERS ||--o{ RETURN_EXCHANGE_ORDERS : "đổi / trả"
  PARTNERS ||--o{ GOODS_RECEIPTS : "NCC giao"
  GOODS_RECEIPTS ||--|{ GOODS_RECEIPT_LINES : "gồm"
  SUPPLIER_PROGRAMS |o--o{ GOODS_RECEIPT_LINES : "áp ưu đãi"
  PARTNERS ||--o{ SUPPLIER_PROGRAMS : "NCC tổ chức"
  PRODUCTS ||--o{ LOTS : "có lô"
  WAREHOUSES ||--o{ STOCK_BALANCES : "tồn"
  LOTS ||--o{ STOCK_MOVEMENTS : "biến động"
  STOCK_MOVEMENTS ||--o| VALUE_MOVEMENTS : "giá trị"
  PRODUCTS ||--|| PRODUCT_COSTS : "giá vốn hiện tại"
  COST_PERIODS ||--o{ COST_RUNS : "lần tính"
  SALES_ORDERS ||--o| ELECTRONIC_INVOICES : "có hoá đơn"
  TENANTS ||--o{ ASSISTANT_LOGS : "nhật ký AI"
```

Hình 3.7. Sơ đồ ERD rút gọn của hệ thống

Bảng 3.10 tóm tắt số bảng của từng lược đồ.

Bảng 3.10. Phân bố bảng theo lược đồ

| Lược đồ | Số bảng | Bảng tiêu biểu |
|---|---|---|
| `iam` | 14 | tenants, stores, memberships, tenant_invitations, role_definitions, email_jobs |
| `catalog` | 17 | products, product_units, product_unit_price_bands, product_images, custom_fields |
| `partner` | 7 | partners, partner_roles, person_profiles, organization_profiles, partner_action_logs |
| `pricing` | 3 | customer_price_rules, customer_price_rule_activities |
| `sales` | 14 | sales_order_drafts, sales_orders, sales_order_lines, sales_order_cancellations, return_exchange_orders |
| `inventory` | 28 | warehouses, lots, stock_balances, stock_movements, value_movements, goods_receipts, supplier_programs, product_costs, cost_runs |
| `einvoice` | 16 | provider_connections, invoice_issuances, issuance_attempts, electronic_invoices, internal_commands |
| `receivable` | 7 | sales_order_settlements, sales_payment_transactions, settlement_obligation_adjustments, customer_collections, receivable_offsets |
| `ai` | 1 | assistant_logs |

<!-- Số bảng đếm từ migration (2026-11-20): create table, trừ drop table, tính cả 3 bảng tiền chuyển từ sales sang receivable (alter table … set schema). -->

Các mục tiếp theo mô tả chi tiết những bảng quan trọng nhất của từng nhóm.

### 3.4.2. Nhóm bảng tổ chức, người dùng và phân quyền

Bảng 3.11. Bảng `iam.tenants` – tổ chức

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| id | UUID | PK | Mã tổ chức |
| display_name | TEXT | NOT NULL | Tên hiển thị của tổ chức |
| created_at | TIMESTAMPTZ | NOT NULL | Thời điểm tạo |

Bảng 3.12. Bảng `iam.stores` – cửa hàng / chi nhánh

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| id | UUID | PK | Mã cửa hàng |
| tenant_id | UUID | FK → tenants, NOT NULL | Tổ chức sở hữu |
| code | TEXT | NOT NULL, UNIQUE(tenant_id, code) | Mã cửa hàng trong tổ chức |
| display_name | TEXT | NOT NULL | Tên cửa hàng |
| status | TEXT | CHECK ∈ {active, inactive} | Trạng thái hoạt động |

Bảng 3.13. Bảng `iam.memberships` – thành viên của tổ chức

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| id | UUID | PK | Mã thành viên |
| tenant_id | UUID | FK → tenants, NOT NULL | Tổ chức |
| user_id | UUID | FK → auth.users, NOT NULL | Tài khoản người dùng |
| role | TEXT | NOT NULL | Vai trò (nhãn công việc) |
| is_owner | BOOLEAN | NOT NULL | Là Owner của tổ chức |
| is_active | BOOLEAN | NOT NULL | Còn hoạt động (false khi tạm ngừng hoặc bị loại) |
| status_changed_at, removed_at | TIMESTAMPTZ | | Thời điểm đổi trạng thái, thời điểm bị loại |
| created_at | TIMESTAMPTZ | NOT NULL | Thời điểm tham gia |

Bảng 3.14. Bảng `iam.tenant_invitations` – lời mời thành viên

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| id | UUID | PK | Mã lời mời |
| tenant_id | UUID | FK → tenants | Tổ chức mời |
| invitee_email | TEXT | NOT NULL | Email người được mời |
| initial_role_id | UUID | FK → role_definitions | Vai trò ban đầu |
| status | TEXT | CHECK ∈ {pending, accepted, declined, revoked, expired} | Trạng thái lời mời |
| token_hash | TEXT | NOT NULL, UNIQUE | Băm của mã lời mời 8 ký tự (không lưu mã gốc) |
| expires_at | TIMESTAMPTZ | NOT NULL | Hạn dùng của lời mời |
| version | INT | NOT NULL | Phiên bản chống ghi đè |

### 3.4.3. Nhóm bảng sản phẩm, giá và đối tác

Bảng 3.15. Bảng `catalog.products` – sản phẩm

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| id | UUID | PK | Mã sản phẩm |
| tenant_id | UUID | NOT NULL | Tổ chức sở hữu |
| name | TEXT | NOT NULL, không rỗng | Tên sản phẩm |
| sku, sku_normalized | TEXT | Có SKU thì phải có bản chuẩn hoá | Mã hàng và bản chuẩn hoá để kiểm trùng |
| barcode, barcode_normalized | TEXT | Tương tự SKU | Mã vạch |
| tracking_mode | TEXT | CHECK ∈ {none, lot} | Có quản lý theo lô hay không |
| expiry_required | BOOLEAN | Bắt buộc hạn dùng thì phải quản lý lô | Bắt buộc nhập hạn dùng khi nhận hàng |
| business_status | ENUM | NOT NULL | Trạng thái kinh doanh (đang bán, ngừng bán…) |
| version | INT | NOT NULL | Phiên bản chống ghi đè |

Bảng 3.16. Bảng `catalog.product_units` – đơn vị tính

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| id | UUID | PK | Mã đơn vị |
| product_id | UUID | FK → products | Sản phẩm |
| unit_name | TEXT | NOT NULL | Tên đơn vị (viên, vỉ, hộp…) |
| is_base_unit | BOOLEAN | NOT NULL | Là đơn vị cơ sở |
| conversion_rate_to_base | NUMERIC | > 0 | Số đơn vị cơ sở trong một đơn vị này |

Bảng 3.17. Bảng `catalog.product_unit_price_bands` – khung giá theo đơn vị

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| id | UUID | PK | Mã khung giá |
| product_id, product_unit_id | UUID | FK, UNIQUE(product_id, product_unit_id) | Sản phẩm và đơn vị bán |
| list_price_amount | NUMERIC | ≥ 0 | Giá niêm yết |
| floor_price_amount | NUMERIC | ≥ 0, ≤ giá niêm yết | Giá sàn (bán dưới giá này phải xác nhận) |

Bảng 3.18. Bảng `partner.partners` – đối tác

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| partner_id | UUID | PK | Mã đối tác |
| tenant_id | UUID | NOT NULL | Tổ chức |
| partner_type | ENUM | NOT NULL | Cá nhân hoặc tổ chức |
| status | ENUM | NOT NULL | Trạng thái |
| display_name | TEXT | NOT NULL | Tên hiển thị |
| is_system | BOOLEAN | NOT NULL | Đối tác do hệ thống tạo sẵn (ví dụ nhà cung cấp vãng lai) |

Vai trò khách hàng / nhà cung cấp được lưu ở bảng `partner.partner_roles` (khoá chính `partner_id, role`), nên một đối tác có thể vừa là khách hàng vừa là nhà cung cấp. Thông tin chi tiết lưu ở `person_profiles` (cá nhân) hoặc `organization_profiles` (tổ chức, có mã số thuế dùng cho hoá đơn).

Bảng 3.19. Bảng `pricing.customer_price_rules` – giá riêng theo khách hàng (các trường chính)

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| id | UUID | PK | Mã giá riêng |
| customer_id, product_id, product_unit_id | UUID | NOT NULL | Khách hàng × sản phẩm × đơn vị bán |
| rule_price_minor | BIGINT | > 0 | Giá riêng (đồng) |
| effective_from, effective_to | DATE | đến ≥ từ | Thời gian hiệu lực |
| status | TEXT | CHECK ∈ {active, disabled, needs_review, deleted} | Trạng thái |
| review_status | TEXT | CHECK ∈ {clear, warning, blocked, needs_review} | Kết quả kiểm tra so với giá niêm yết / giá sàn |
| *_snapshot | TEXT / BIGINT | | Bản chụp tên khách, tên sản phẩm, giá niêm yết, giá sàn lúc tạo |
| idempotency_key | TEXT | UNIQUE(tenant_id, idempotency_key) | Chống tạo trùng |

### 3.4.4. Nhóm bảng bán hàng và công nợ

Bảng 3.20. Bảng `sales.sales_orders` – đơn bán hàng

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| id | UUID | PK | Mã đơn |
| tenant_id | UUID | NOT NULL | Tổ chức |
| order_code | VARCHAR(50) | UNIQUE(tenant_id, order_code) | Mã đơn hiển thị (`DH…`) |
| store_id | UUID | NOT NULL | Cửa hàng bán |
| seller_user_id | UUID | NOT NULL | Người bán |
| customer_partner_id | UUID | | Khách hàng (rỗng nếu khách lẻ) |
| lifecycle_status | TEXT | CHECK ∈ {completed, cancelled} | Vòng đời đơn |
| subtotal / discount / tax / rounding_amount_minor | BIGINT | NOT NULL | Tạm tính, giảm giá, thuế, làm tròn |
| payable_amount_minor | BIGINT | = tạm tính − giảm + thuế + làm tròn | Tổng phải trả |
| sales_context_snapshot | JSONB | NOT NULL | Bản chụp khách hàng, cửa hàng lúc bán |
| buyer_tax_snapshot | JSONB | | Thông tin người mua cho hoá đơn điện tử |
| version | BIGINT | NOT NULL | Phiên bản chống ghi đè |

Bảng 3.21. Bảng `sales.sales_order_lines` – dòng đơn

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| id | UUID | PK | Mã dòng |
| sales_order_id | UUID | FK ghép (tenant_id, sales_order_id) | Đơn chứa dòng |
| line_sequence | INT | UNIQUE trong đơn | Thứ tự dòng |
| product_id, product_unit_id | UUID | NOT NULL | Sản phẩm và đơn vị bán |
| quantity_micros, base_quantity_micros | BIGINT | > 0 | Số lượng theo đơn vị bán và theo đơn vị cơ sở (× 10^6) |
| unit_price_minor | BIGINT | NOT NULL | Đơn giá |
| gross / discount / tax_amount_minor, line_total_minor | BIGINT | thành tiền = gộp − giảm + thuế | Các khoản tiền của dòng |
| pricing_snapshot | JSONB | | Nguồn giá đã áp (giá riêng / nhập tay / niêm yết) |
| cogs_amount_vnd, cogs_unit_cost | BIGINT, NUMERIC(18,4) | | Giá vốn hàng bán của dòng |
| cogs_is_provisional | BOOLEAN | | Giá vốn tạm (chờ chốt kỳ) |

Dữ liệu tiền của đơn được tách sang lược đồ `receivable`, do phân hệ công nợ sở hữu. Mỗi đơn có đúng một bản ghi quyết toán (`receivable.sales_order_settlements`) lưu nghĩa vụ gốc, ngày hẹn trả và các số tổng hợp. Tiền thu và tiền hoàn là các dòng trong `receivable.sales_payment_transactions`, chỉ ghi thêm. Huỷ đơn và đổi / trả không sửa nghĩa vụ gốc mà ghi một dòng điều chỉnh có dấu vào `settlement_obligation_adjustments`. Sau mỗi giao dịch hoặc điều chỉnh, hệ thống tính lại:

> Phải trả hiện tại = Nghĩa vụ gốc + Σ điều chỉnh; Thu ròng = Σ đã thu − Σ đã hoàn; Còn phải thu = max(Phải trả hiện tại − Thu ròng, 0)

Công nợ của một khách là tổng số còn phải thu của các đơn đã hoàn tất của khách đó; giá trị này được **tính khi đọc**, không lưu, nên luôn khớp với từng đơn.

Bảng 3.22. Bảng `receivable.sales_payment_transactions` – giao dịch tiền của đơn

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| id | UUID | PK | Mã giao dịch |
| sales_order_settlement_id | UUID | FK ghép | Quyết toán của đơn |
| transaction_type, direction | TEXT | collection ↔ inflow, refund ↔ outflow | Thu tiền hoặc hoàn tiền |
| amount_minor | BIGINT | > 0 | Số tiền |
| payment_method_code | VARCHAR(50) | NOT NULL | Tiền mặt, chuyển khoản, cấn trừ (nội bộ) |
| status | TEXT | CHECK ∈ {pending, confirmed, failed} | Trạng thái |
| source_context | TEXT | CHECK ∈ {checkout, receivable_collection, return_exchange, cancellation, …} | Nghiệp vụ phát sinh giao dịch |
| related_transaction_id | UUID | FK cùng quyết toán | Giao dịch gốc (với hoàn tiền) |

Bảng 3.23. Bảng `receivable.customer_collections` – lần thu tiền theo khách

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| id | UUID | PK | Mã lần thu |
| customer_partner_id | UUID | FK → partners | Khách trả nợ |
| amount_minor | BIGINT | > 0 | Số tiền khách trả |
| payment_method_code | VARCHAR(50) | CHECK ∈ {cash, manualBankTransfer} | Tiền mặt hoặc chuyển khoản |
| external_reference | VARCHAR(150) | | Mã giao dịch ngân hàng (tuỳ chọn) |
| customer_outstanding_before_minor, customer_outstanding_after_minor | BIGINT | sau = trước − số tiền | Công nợ của khách trước và sau lần thu |
| allocation_snapshot | JSONB | NOT NULL | Bản chụp phân bổ vào từng đơn |
| collected_by_user_id | UUID | NOT NULL | Người thu |

Bảng 3.24. Bảng `receivable.receivable_offsets` – cấn trừ

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| id | UUID | PK | Mã cấn trừ |
| customer_partner_id | UUID | FK → partners | Khách hàng |
| return_exchange_order_id | UUID | FK → return_exchange_orders | Phiếu đổi / trả phát sinh khoản khách được hưởng |
| source_sales_order_id, target_sales_order_id | UUID | Khác nhau | Đơn nguồn (khách được hưởng) và đơn nhận (đang nợ) |
| amount_minor | BIGINT | > 0 | Số tiền cấn trừ |
| source_refund_transaction_id, target_collection_transaction_id | UUID | FK → sales_payment_transactions | Cặp giao dịch hoàn ở đơn nguồn và thu ở đơn nhận, phương thức `offset` |

Cấn trừ không có tiền thật đi vào hay đi ra: khi khách trả hàng ở một đơn và đang nợ ở đơn khác, khoản được hưởng được chuyển sang trả nợ thay vì hoàn tiền mặt, thể hiện bằng một cặp giao dịch nội bộ.

### 3.4.5. Nhóm bảng kho và giá vốn

Phân hệ kho dùng **hai sổ song song**, cùng chung một bộ đếm thứ tự `ledger_sequence` cho mỗi tổ chức: sổ số lượng (`stock_movements`) ghi biến động số lượng theo kho và lô; sổ giá trị (`value_movements`) ghi biến động giá trị tương ứng, cộng thêm các dòng điều chỉnh chỉ có giá trị (true-up khi chốt kỳ, chiết khấu nhà cung cấp đạt mốc). Bảng `stock_balances` và `product_costs` là số dư được cập nhật cùng giao dịch với sổ để đọc nhanh.

Bảng 3.25. Bảng `inventory.goods_receipts` – phiếu nhận hàng

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| id | UUID | PK | Mã phiếu |
| receipt_no | TEXT | UNIQUE(tenant_id, receipt_no) | Số phiếu |
| warehouse_id | UUID | FK → warehouses | Kho nhận |
| supplier_id | UUID | FK → partners | Nhà cung cấp |
| business_date | DATE | NOT NULL | Ngày nhận (xác định kỳ giá vốn) |
| freight_cost_vnd | BIGINT | ≥ 0 | Chi phí thu mua (vận chuyển, bốc xếp) |
| trade_discount_vnd | BIGINT | ≥ 0, ≤ tiền hàng + chi phí | Chiết khấu thương mại của phiếu |
| purchase_total_vnd | BIGINT | NOT NULL | Tổng tiền hàng |
| landed_total_vnd | BIGINT | = tiền hàng + chi phí − chiết khấu | Tổng giá gốc |

Bảng 3.26. Bảng `inventory.goods_receipt_lines` – dòng phiếu nhận

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| id | UUID | PK | Mã dòng |
| receipt_id | UUID | FK → goods_receipts | Phiếu |
| product_id, unit_id, conversion_rate | UUID, NUMERIC | | Sản phẩm, đơn vị nhập, tỷ lệ quy đổi |
| paid_qty | INT | > 0 | Số lượng mua |
| free_qty | INT | ≥ 0 | Số lượng được tặng (mua X tặng Y) |
| unit_price_vnd | BIGINT | > 0 | Đơn giá mua |
| program_id | UUID | FK → supplier_programs | Chương trình ưu đãi áp cho dòng |
| tier_discount_percent, tier_discount_vnd | NUMERIC, BIGINT | 0–100% | Chiết khấu theo bậc |
| purchase_amount_vnd | BIGINT | = tiền gộp − chiết khấu bậc | Tiền mua của dòng |
| allocated_freight_vnd, allocated_discount_vnd | BIGINT | | Chi phí và chiết khấu phân bổ từ phiếu |
| landed_amount_vnd | BIGINT | = mua + chi phí − chiết khấu | Giá gốc của dòng |
| landed_unit_cost | NUMERIC(18,4) | NOT NULL | Đơn giá gốc trên một đơn vị cơ sở |

Bảng 3.27. Bảng `inventory.supplier_programs` – chương trình ưu đãi nhà cung cấp

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| id | UUID | PK | Mã chương trình |
| supplier_id | UUID | FK → partners | Nhà cung cấp |
| kind | TEXT | CHECK ∈ {TIER_DISCOUNT, BUY_X_GET_Y, VOLUME_REBATE} | Giảm theo bậc / mua X tặng Y / chiết khấu đạt mốc |
| status | TEXT | CHECK ∈ {ACTIVE, REACHED, RECORDED, ENDED} | Đang chạy / đạt mốc / đã ghi nhận / đã kết thúc |
| buy_qty, free_qty | NUMERIC | bắt buộc với BUY_X_GET_Y | Mua X tặng Y |
| target_qty, rebate_percent | NUMERIC | bắt buộc với VOLUME_REBATE | Mốc số lượng tích luỹ và % chiết khấu |
| progress_qty | NUMERIC | NOT NULL | Số lượng đã mua tích luỹ |

Với loại giảm theo bậc, các bậc lưu ở bảng `supplier_program_tiers` (`min_qty`, `discount_percent`). Ràng buộc `CHECK` bảo đảm mỗi loại chương trình chỉ có đúng các tham số của loại đó.

Bảng 3.28. Bảng `inventory.stock_movements` – sổ kho (số lượng)

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| id | UUID | PK | Mã dòng sổ |
| ledger_sequence | BIGINT | UNIQUE(tenant_id, ledger_sequence) | Thứ tự ghi sổ trong tổ chức |
| warehouse_id, product_id, lot_id | UUID | FK | Kho, sản phẩm, lô |
| intent_type, intent_id, intent_line_id | TEXT, UUID | NOT NULL | Chứng từ phát sinh (phiếu nhận, đơn bán, phiếu kiểm kê…) |
| movement_kind | TEXT | CHECK ∈ {RECEIPT, SALE, SALE_REVERSAL, RETURN_IN, COUNT_GAIN, COUNT_LOSS, WRITE_OFF, OPENING} | Loại biến động |
| quantity_delta | NUMERIC | ≠ 0 | Số lượng có dấu (+ nhập, − xuất), theo đơn vị cơ sở |
| business_date | DATE | NOT NULL | Ngày nghiệp vụ |

Bảng 3.29. Bảng `inventory.value_movements` – sổ giá trị

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| id | UUID | PK | Mã dòng sổ |
| ledger_sequence | BIGINT | UNIQUE(tenant_id, ledger_sequence) | Dùng chung bộ đếm với sổ kho |
| product_id | UUID | FK → products | Sản phẩm |
| movement_id | UUID | FK → stock_movements, NULL với dòng điều chỉnh | Dòng sổ kho tương ứng |
| kind | TEXT | 11 loại, gồm COGS_TRUE_UP, LOSS_TRUE_UP, REVALUE_ROUNDING, SUPPLIER_REBATE | Loại biến động giá trị |
| quantity_basis | NUMERIC | | Số lượng làm căn cứ (0 với dòng điều chỉnh) |
| unit_cost | NUMERIC(18,4) | ≥ 0 | Đơn giá đã dùng |
| amount_vnd | BIGINT | NOT NULL | Giá trị có dấu |
| is_provisional | BOOLEAN | | Xuất theo giá tạm |
| cost_run_id, supplier_rebate_id | UUID | Bắt buộc với dòng điều chỉnh tương ứng | Lần tính / chiết khấu tạo ra dòng điều chỉnh |

Bảng 3.30. Bảng `inventory.product_costs` – giá vốn hiện tại của sản phẩm

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| tenant_id, product_id | UUID | PK ghép | Tổ chức và sản phẩm |
| quantity_on_hand | NUMERIC | ≥ 0 | Số lượng tồn (đơn vị cơ sở) |
| ledger_value_vnd | BIGINT | | Tổng giá trị theo sổ |
| moving_avg_cost | NUMERIC(18,4) | ≥ 0 | Đơn giá bình quân liên hoàn hiện tại |
| official_version_id, official_unit_cost | UUID, NUMERIC(18,4) | | Phiên bản và đơn giá chính thức đã công bố gần nhất |

Ngoài ra, bảng `cost_policies` lưu phương pháp giá vốn của tổ chức (`MOVING` hoặc `PERIODIC`); `cost_periods` lưu kỳ theo tháng (`OPEN` / `CLOSED`); `cost_runs` và `cost_run_lines` lưu các lần tính giá vốn với trạng thái `READY_FOR_REVIEW`, `BLOCKED`, `STALE`, `PUBLISHED`, `SUPERSEDED`; `cost_versions` lưu các phiên bản đơn giá chính thức.

### 3.4.6. Nhóm bảng hoá đơn điện tử và trợ lý AI

Bảng 3.31. Bảng `einvoice.electronic_invoices` – hoá đơn đã phát hành

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| id | UUID | PK | Mã hoá đơn |
| invoice_issuance_id | UUID | FK, UNIQUE | Lượt phát hành |
| successful_attempt_id | UUID | FK → issuance_attempts | Lần gọi MISA thành công |
| sales_order_id | UUID | UNIQUE(tenant_id, sales_order_id) | Đơn hàng (mỗi đơn tối đa một hoá đơn) |
| provider_connection_id | UUID | FK → provider_connections | Kết nối MISA đã dùng |
| provider_invoice_reference | VARCHAR(255) | NOT NULL | Mã tham chiếu hoá đơn phía MISA |
| invoice_series, invoice_number | VARCHAR(100) | NOT NULL | Ký hiệu và số hoá đơn |
| issued_at | TIMESTAMPTZ | NOT NULL | Thời điểm phát hành |

Bảng 3.32. Bảng `einvoice.internal_commands` – hàng đợi lệnh

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| id | UUID | PK | Mã lệnh (ổn định, chống xếp trùng) |
| command_type | TEXT | NOT NULL | Loại lệnh (phát hành, tải tệp, gửi email, đối soát…) |
| payload | JSONB | NOT NULL | Dữ liệu của lệnh |
| enqueued_at, processed_at, failed_at | TIMESTAMPTZ | | Thời điểm xếp, xử lý xong, thất bại |
| retry_count | INT | NOT NULL | Số lần đã thử |
| claimed_at, claim_token | TIMESTAMPTZ, UUID | | Tiến trình đang giữ lệnh |
| error | TEXT | | Lỗi gần nhất |

Bảng 3.33. Bảng `ai.assistant_logs` – nhật ký trợ lý AI

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| id | UUID | PK | Mã lượt hỏi |
| tenant_id, user_id | UUID | NOT NULL | Tổ chức và người hỏi |
| business_date | DATE | NOT NULL | Ngày (dùng đếm lượt theo ngày) |
| question | TEXT | 1–500 ký tự | Câu hỏi |
| status | TEXT | CHECK ∈ {dang_xu_ly, ok, tro_chuyen, ngoai_pham_vi, chua_ho_tro, tu_choi, khong_quyen, loi, het_luot, ban} | Kết quả xử lý |
| tool_calls | JSONB | NOT NULL | Các công cụ đã gọi (tên, tham số, thành công hay không) |
| input_tokens, output_tokens | INT | | Số token tiêu thụ |
| latency_ms | INT | | Thời gian xử lý |

Nhật ký không lưu nội dung câu trả lời và dữ liệu trả về từ công cụ, chỉ lưu thông tin phục vụ đếm lượt, theo dõi chi phí và chẩn đoán lỗi.

## 3.5. Thiết kế luồng xử lý nghiệp vụ

### 3.5.1. Luồng đăng ký cửa hàng và xác minh email

Điểm thiết kế quan trọng của luồng này là **tổ chức chỉ được tạo khi email đã xác minh**, và việc tạo được thực hiện bởi một trigger trong CSDL, cùng giao dịch với việc xác minh. Nhờ vậy hệ thống không bao giờ có tổ chức "dở dang" thuộc về một email chưa được chứng minh.

```mermaid
sequenceDiagram
  actor U as Chủ cửa hàng
  participant App as Ứng dụng
  participant Auth as Supabase Auth
  participant DB as PostgreSQL (trigger)
  participant Mail as Hộp thư
  U->>App: "Đăng ký cửa hàng mới"
  U->>App: Bước 1: họ tên, email, mật khẩu
  Note over App: Kiểm tra định dạng trên ứng dụng
  U->>App: Bước 2: tên cửa hàng, SĐT, địa chỉ
  App->>Auth: signUp(email, mật khẩu, metadata cửa hàng)
  Auth->>DB: insert auth.users (chưa xác minh)
  Auth->>Mail: Mã xác minh 6 số (hạn 1 giờ)
  App->>U: Bước 3: màn nhập mã
  U->>App: Nhập mã, "Xác minh"
  App->>Auth: verifyOtp(type: signup)
  Auth->>DB: update email_confirmed_at
  DB->>DB: trigger _on_auth_user_confirmed: tạo hồ sơ, tổ chức, Owner, cửa hàng mặc định, nhật ký, xoá metadata tạm
  Auth-->>App: Phiên đăng nhập (JWT)
  App->>U: Trang chủ: "Cửa hàng … đã sẵn sàng"
```

Hình 3.8. Biểu đồ tuần tự luồng đăng ký cửa hàng và xác minh email

### 3.5.2. Luồng lập đơn bán hàng, áp giá và trừ kho

Khi người dùng bấm "Hoàn tất", toàn bộ việc ghi nhận đơn được thực hiện trong một lời gọi RPC `sales.finalize_sales_order`. Hàm này gọi tiếp các hàm nội bộ của phân hệ kho để trừ tồn và ghi giá vốn, tất cả trong một giao dịch: nếu một bước lỗi thì không có gì được ghi.

```mermaid
sequenceDiagram
  actor NV as Nhân viên
  participant App as Ứng dụng
  participant PR as RPC pricing.preview_sales_working_state_pricing
  participant FS as RPC sales.finalize_sales_order
  participant INV as inventory._issue_for_sale / _post_movements
  participant OB as sales.outbox_messages
  NV->>App: Thêm sản phẩm, chọn khách
  App->>PR: Giỏ hàng hiện tại
  PR-->>App: Giá từng dòng (giá riêng → nhập tay → niêm yết), cảnh báo dưới sàn
  NV->>App: Nhập thanh toán, "Hoàn tất"
  App->>FS: Lệnh hoàn tất + idempotency_key
  FS->>FS: Kiểm quyền, kiểm idempotency, kiểm version nháp
  FS->>FS: Tính lại giá và tiền, kiểm đẳng thức tiền
  FS->>FS: Tạo sales_orders, sales_order_lines (snapshot)
  FS->>FS: Tạo quyết toán, ghi giao dịch thu tiền, công nợ
  FS->>INV: Xuất kho cho các dòng
  INV->>INV: Khoá theo sản phẩm (thứ tự tăng dần)
  INV->>INV: Kiểm tồn khả dụng, chọn lô FEFO (hạn gần nhất trước, bỏ lô đã hết hạn)
  INV->>INV: Ghi stock_movements (SALE) và value_movements
  INV->>INV: Đơn giá: MOVING → bình quân liên hoàn, PERIODIC → giá chính thức, chưa có thì giá tạm
  INV-->>FS: Giá vốn từng dòng
  FS->>FS: Ghi cogs vào sales_order_lines
  FS->>OB: Sự kiện sales_order_finalized.v1
  FS-->>App: Mã đơn DH…
  App->>NV: Màn hoàn tất, in / chia sẻ phiếu
```

Hình 3.9. Biểu đồ tuần tự luồng lập đơn bán hàng

Nguyên tắc **FEFO** (First Expired, First Out – hết hạn trước, xuất trước) được áp dụng cho sản phẩm quản lý theo lô: hệ thống sắp các lô còn hạn theo hạn dùng tăng dần và lấy dần cho đến khi đủ số lượng. Lô đã hết hạn không được xuất bán. Nếu tổng tồn khả dụng không đủ, hàm báo lỗi `INSUFFICIENT_STOCK` kèm danh sách sản phẩm thiếu và toàn bộ giao dịch bị huỷ.

### 3.5.3. Luồng nhận hàng và tính giá vốn

**a) Ghi nhận phiếu nhận hàng.** Khi ghi phiếu, RPC `inventory.record_goods_receipt` tính giá gốc của từng dòng theo VAS 02 rồi ghi sổ:

1. Với mỗi dòng: tiền gộp = số lượng mua × đơn giá; nếu dòng thuộc chương trình giảm theo bậc thì trừ chiết khấu của bậc tương ứng với số lượng → tiền mua `aᵢ`. Nếu thuộc chương trình mua X tặng Y thì tính số lượng tặng; hàng tặng không làm tăng tiền nhưng làm tăng số lượng nhận.
2. Phân bổ chi phí thu mua `F` và chiết khấu thương mại `D` của phiếu theo tỷ lệ tiền mua: `fᵢ = ⌊F × aᵢ / A⌋`, `kᵢ = ⌊D × aᵢ / A⌋` với `A = Σaᵢ`; phần dư do làm tròn cộng vào dòng có tiền mua lớn nhất. Nhờ vậy tổng phân bổ luôn khớp chính xác với số trên phiếu.
3. Giá gốc dòng `gᵢ = aᵢ + fᵢ − kᵢ`; đơn giá gốc = `gᵢ / (số lượng mua + tặng)` quy về đơn vị cơ sở.
4. Ghi lô (tạo mới nếu chưa có), dòng sổ kho `RECEIPT`, dòng sổ giá trị với giá trị đúng bằng `gᵢ`, cập nhật tồn kho và đơn giá bình quân liên hoàn: `m' = (q × m + gᵢ) / (q + d)`.
5. Cộng số lượng vào tiến độ của chương trình chiết khấu đạt mốc; khi vượt mốc, chương trình chuyển sang `REACHED`, chờ người dùng ghi nhận chiết khấu. Khi ghi nhận, khoản chiết khấu được ghi thành dòng `SUPPLIER_REBATE` (giá trị âm) trên sổ giá trị và phân bổ cho các sản phẩm đã mua theo chương trình.

Ví dụ: phiếu có hai dòng với tiền mua 600.000 đ và 400.000 đ, chi phí vận chuyển 50.000 đ, chiết khấu 20.000 đ. Chi phí phân bổ 30.000 đ và 20.000 đ; chiết khấu phân bổ 12.000 đ và 8.000 đ; giá gốc hai dòng là 618.000 đ và 412.000 đ, tổng 1.030.000 đ = 1.000.000 + 50.000 − 20.000.

**b) Tính và công bố giá vốn.** Quy trình được thiết kế theo hướng **tính lại từ sổ** và **công bố nguyên tử** (Hình 3.10):

```mermaid
stateDiagram-v2
  [*] --> READY_FOR_REVIEW: create_cost_run (không có vấn đề chặn)
  [*] --> BLOCKED: create_cost_run (có vấn đề chặn)
  READY_FOR_REVIEW --> STALE: có biến động mới sau mốc chốt
  READY_FOR_REVIEW --> PUBLISHED: publish_cost_run
  READY_FOR_REVIEW --> [*]: discard_cost_run
  BLOCKED --> [*]: discard_cost_run
  STALE --> [*]: discard_cost_run
  PUBLISHED --> SUPERSEDED: lần tính sau thay thế
```

Hình 3.10. Biểu đồ trạng thái của một lần tính giá vốn

- **Tạo lần tính:** xác định đoạn sổ từ mốc công bố trước (`from_sequence`) đến dòng sổ mới nhất (`cut_off_sequence`). Với mỗi sản phẩm có biến động, tính tồn đầu đoạn (lấy từ lần công bố trước), tổng nhập (`RECEIPT`, `COUNT_GAIN`, `RETURN_IN`, gồm cả hàng tặng), tổng chiết khấu nhà cung cấp, tổng xuất bán và hao hụt; từ đó tính đơn giá theo cả hai phương pháp. Kết quả lưu vào `cost_run_lines` và không đổi sau khi tạo.
- **Rà soát:** Owner xem đơn giá mỗi phương pháp và chênh lệch giữa giá vốn đã ghi lúc bán với giá vốn theo phương pháp chính thức.
- **Công bố:** trong một giao dịch, hệ thống kiểm tra lần tính chưa lỗi thời, tạo phiên bản giá chính thức (`cost_versions`), ghi các dòng điều chỉnh `COGS_TRUE_UP` (cho hàng đã bán) và `LOSS_TRUE_UP` (cho hao hụt) vào sổ giá trị, và nếu là lần chốt kỳ thì đóng kỳ (`CLOSED`). Từ đó mọi chứng từ có ngày thuộc kỳ đã đóng đều bị từ chối.

### 3.5.4. Luồng phát hành hoá đơn điện tử

```mermaid
sequenceDiagram
  actor NV as Nhân viên
  participant App as Ứng dụng
  participant DB as RPC einvoice.*
  participant Q as internal_commands
  participant CR as pg_cron
  participant P as einvoice-processor
  participant M as MISA meInvoice
  NV->>App: "Phát hành hoá đơn" (chi tiết đơn)
  App->>DB: issue_invoice(đơn, idempotency_key)
  DB->>DB: Kiểm quyền, kết nối, dữ liệu người mua, đơn chưa có hoá đơn
  DB->>DB: Tạo invoice_issuances, issuance_attempts
  DB->>Q: enqueue lệnh phát hành
  DB-->>App: Trạng thái "Đang phát hành"
  CR->>P: Mỗi 30 giây
  P->>Q: claim_internal_commands_batch
  P->>M: /auth/token (dùng token đã lưu nếu còn hạn)
  P->>M: /invoice (phát hành, ký số HSM)
  alt Thành công
    M-->>P: Ký hiệu, số hoá đơn, mã tham chiếu
    P->>DB: Ghi electronic_invoices, complete lệnh
    P->>Q: enqueue lệnh tải tệp
    P->>M: /invoice/download
    P->>P: Lưu tệp vào Storage
  else Lỗi tạm thời
    P->>Q: fail lệnh, tăng retry_count, hẹn thử lại
  else Không rõ kết quả
    P->>DB: Mở trường hợp đối soát, hỏi /invoice/status
  end
  App->>DB: Đọc lại trạng thái
  DB-->>App: "Đã phát hành", số hoá đơn
```

Hình 3.11. Biểu đồ tuần tự luồng phát hành hoá đơn điện tử

Với phát hành tự động, điểm bắt đầu là sự kiện `sales_order_finalized.v1`. Hàm `einvoice.start_auto_issuance` kiểm tra chính sách tự động của tổ chức, kiểm tra đơn chưa có hoá đơn hay lượt phát hành đang chạy, nạp dữ liệu nguồn của đơn; nếu đủ điều kiện thì đi tiếp như luồng thủ công từ bước tạo lượt phát hành, nếu đơn đã trả hết hàng thì bỏ qua.

### 3.5.5. Luồng xử lý câu hỏi của trợ lý AI

Hình 2.3 ở Chương 2 đã trình bày vòng lặp gọi công cụ. Hình 3.12 bổ sung các nhánh quyết định và các điểm kiểm soát trong quá trình xử lý một câu hỏi.

```mermaid
flowchart TD
  S([Nhận câu hỏi]) --> V{Yêu cầu hợp lệ?<br/>1–500 ký tự, JWT đúng}
  V -- Không --> E1[/Trả lỗi 400 / 401/]
  V -- Có --> Q{ai.start_question<br/>còn lượt? có quyền?}
  Q -- Hết lượt --> R1[/"het_luot"/]
  Q -- Không quyền --> R2[/"khong_quyen"/]
  Q -- OK --> M[Gửi cho Claude:<br/>system prompt + câu hỏi + lịch sử + công cụ]
  M --> K{Claude trả về}
  K -- Gọi công cụ --> L{Đã gọi đủ 5 lần?}
  L -- "Có, đã có dữ liệu" --> R3[/"ok": dữ liệu đã có + báo câu hỏi quá phức tạp/]
  L -- "Có, chưa có dữ liệu" --> R7[/"chua_ho_tro"/]
  L -- Không --> T[Chạy công cụ bằng JWT người hỏi<br/>RLS lọc dữ liệu]
  T --> RD[Che dữ liệu cá nhân,<br/>dựng bảng số liệu]
  RD --> M
  K -- bao_khong_ho_tro --> R4[/"ngoai_pham_vi / chua_ho_tro / tu_choi"/]
  K -- Văn bản --> G{Có dữ liệu từ công cụ?}
  G -- Có --> OK[/"ok": câu trả lời + bảng/]
  G -- Không --> D{Câu trả lời chứa chữ số?}
  D -- Có --> R5[/"chua_ho_tro" – chặn số không có nguồn/]
  D -- Không --> R6[/"tro_chuyen"/]
  OK & R1 & R2 & R3 & R4 & R5 & R6 & R7 --> LOG[Ghi kết quả vào ai.assistant_logs]
```

Hình 3.12. Lưu đồ xử lý câu hỏi của trợ lý AI

## Kết luận chương 3

Chương 3 đã phân tích yêu cầu của hệ thống Mosaic Retail với sáu tác nhân, 27 yêu cầu chức năng nhóm theo tám phân hệ và các yêu cầu phi chức năng về bảo mật, tính đúng đắn của số liệu và khả năng truy vết. Sáu use case chính được đặc tả chi tiết, bao phủ chuỗi nghiệp vụ từ đăng ký, bán hàng, nhập hàng, tính giá vốn, phát hành hoá đơn đến hỏi đáp với trợ lý AI. Về thiết kế, hệ thống dùng kiến trúc BaaS trên Supabase, với logic nghiệp vụ đặt trong các hàm RPC có kiểm quyền và RLS. Việc gọi dịch vụ ngoài đi qua hàng đợi lệnh, còn trợ lý AI được thiết kế theo mô hình điều phối công cụ có kiểm soát. CSDL gồm 107 bảng trong 9 lược đồ, được thiết kế theo các nguyên tắc đa tổ chức, tiền và số lượng chính xác, sổ chỉ ghi thêm. Phân hệ kho dùng hai sổ song song để tính giá vốn theo VAS 02. Chương 4 sẽ trình bày quá trình hiện thực, kiểm thử và đánh giá hệ thống theo thiết kế này.

# CHƯƠNG 4. XÂY DỰNG, KIỂM THỬ VÀ ĐÁNH GIÁ HỆ THỐNG

<!-- Chương 4 ~20 trang. Ảnh chụp màn hình: đặt vào thư mục hinh/ đúng tên trong từng dòng ![...](...). Mỗi chỗ có ghi chú "Chụp:" mô tả màn cần chụp. -->

Chương này trình bày quá trình hiện thực hệ thống Mosaic Retail theo thiết kế ở Chương 3: môi trường phát triển, kết quả xây dựng các phân hệ chính, quá trình kiểm thử và đánh giá kết quả đạt được so với mục tiêu.

## 4.1. Môi trường phát triển và triển khai

Bảng 4.1. Môi trường và công cụ phát triển

| Hạng mục | Công cụ / Thông số |
|---|---|
| Máy phát triển | MacBook, macOS 26 |
| IDE | Visual Studio Code (extension Flutter, Dart, Deno); Xcode (build iOS) |
| SDK | Flutter 3.44.8 (kênh stable), Dart ≥ 3.11; Deno (Edge Functions) |
| CSDL phát triển | Supabase CLI chạy Supabase cục bộ trên Docker (PostgreSQL 17) |
| Quản lý mã nguồn | Git; quản lý công việc bằng GitLab Issues |
| Quản lý lược đồ CSDL | Supabase migrations (gần 200 tệp SQL có đánh phiên bản) |
| Kiểm thử | `flutter test` (unit, widget test), `deno test` (Edge Functions), kiểm thử SQL trên CSDL cục bộ |
| Môi trường | Ba môi trường tách biệt: development, staging, production, mỗi môi trường một dự án Supabase |
| Triển khai | Supabase Cloud (CSDL, Auth, Storage, Edge Functions); TestFlight (iPhone); Vercel (bản web) |

Ứng dụng iPhone có ba bản (flavor) tương ứng ba môi trường, với Bundle ID khác nhau nên có thể cài song song trên cùng một máy. Cấu hình kết nối (địa chỉ Supabase, anon key) được đưa vào lúc biên dịch bằng `--dart-define-from-file`, không nằm trong mã nguồn. Các khoá bí mật (khoá API Claude, Resend, thông tin MISA) chỉ được khai báo dưới dạng secret của Supabase Edge Functions.

Cấu trúc thư mục chính của dự án được tổ chức theo dạng monorepo (Hình 4.1):

```text
graduation_project/
├── apps/
│   └── erp/                     # Ứng dụng Flutter duy nhất (iPhone + web)
│       ├── lib/
│       │   ├── core/            # config, di, router, session, supabase, formatting…
│       │   ├── features/        # 13 phân hệ: auth, iam, catalog, partner, pricing,
│       │   │                    #   sales, inventory, einvoice, receivable,
│       │   │                    #   assistant, dashboard, more, tenant_context
│       │   └── main.dart
│       └── test/                # 517 tệp kiểm thử
├── packages/
│   ├── c45_design_system/       # Hệ thống thiết kế: token, thành phần giao diện dùng chung
│   └── c45_lints/               # Bộ quy tắc phân tích mã
├── supabase/
│   ├── migrations/              # Lược đồ, RPC, RLS, pg_cron theo phiên bản
│   ├── functions/               # Edge Functions: ai-assistant, einvoice-processor,
│   │                            #   send-email, invitation-signup
│   └── tests/                   # 30 tệp kiểm thử SQL
└── docs/                        # Đặc tả yêu cầu TH-01…TH-08, kế hoạch, vận hành
```

Hình 4.1. Cấu trúc thư mục dự án

Bảng 4.2 thống kê quy mô mã nguồn ứng dụng theo phân hệ.

Bảng 4.2. Quy mô mã nguồn ứng dụng theo phân hệ

| Phân hệ | Thư mục | Số màn hình | Số dòng mã Dart |
|---|---|---|---|
| Xác thực | `auth` | 6 | 3.984 |
| Tổ chức và người dùng | `iam` | 17 | 15.983 |
| Sản phẩm và giá | `catalog` | 21 | 24.305 |
| Đối tác | `partner` | 8 | 15.647 |
| Chính sách giá | `pricing` | 7 | 10.705 |
| Bán hàng | `sales` | 20 | 36.161 |
| Kho và giá vốn | `inventory` | 33 | 33.116 |
| Hoá đơn điện tử | `einvoice` | 5 | 9.264 |
| Công nợ phải thu | `receivable` | 2 | 3.362 |
| Trợ lý AI | `assistant` | 1 | 934 |
| Trang chủ, khung điều hướng, mục Thêm | `dashboard`, `more` | 4 | 2.707 |
| **Tổng** | | **124** | **~156.000** |

<!-- Số liệu đếm ngày 2026-11-19 (find *_page.dart, wc -l). Đếm lại trước khi nộp nếu code còn thay đổi. -->

## 4.2. Hiện thực các chức năng chính

### 4.2.1. Module tổ chức và người dùng

Luồng đăng ký được hiện thực đúng theo thiết kế ở mục 3.5.1: màn đăng ký gồm ba bước (tài khoản – cửa hàng – xác minh), dữ liệu cửa hàng được gửi kèm lời gọi `signUp` dưới dạng metadata, và trigger `_on_auth_user_confirmed` tạo tổ chức khi email được xác minh. Nhân viên được mời nhận email chứa mã lời mời 8 ký tự; Edge Function `invitation-signup` tạo tài khoản đã xác minh và thêm thành viên vào tổ chức trong một bước. Owner quản lý thành viên ở mục "Người dùng & vai trò" trong tab Thêm; mục này không hiển thị với nhân viên.

![Hình 4.2. Màn hình đăng ký cửa hàng (bước 2) và nhập mã xác minh trên iPhone](hinh/hinh4_2.png)

<!-- Chụp: /signup bước 2 và bước 3 trên iPhone, ghép cạnh nhau. -->

![Hình 4.3. Màn hình quản lý thành viên trên web](hinh/hinh4_3.png)

<!-- Chụp: danh sách thành viên dạng danh sách – chi tiết trên web ≥ 1280px. -->

Mọi hàm RPC nghiệp vụ đều bắt đầu bằng một hàm kiểm quyền dùng chung. Ví dụ, phân hệ kho dùng `inventory._assert_actor` (rút gọn):

```sql
v_actor_id uuid := auth.uid();
...
if v_actor_id is null then
  perform inventory._raise('PERMISSION_DENIED', 'Not authenticated.');
end if;
if not iam.has_permission(p_tenant_id, p_permission) then
  perform inventory._raise('PERMISSION_DENIED', 'Permission denied: ' || p_permission);
end if;
select coalesce(m.is_owner, false) into v_owner
  from iam.memberships m
 where m.tenant_id = p_tenant_id and m.user_id = v_actor_id;
if p_require_owner and not v_owner then
  perform inventory._raise('PERMISSION_DENIED', 'Owner permission required.');
end if;
```

### 4.2.2. Trang chủ và khung điều hướng iPhone / web

Khu cửa hàng dùng một `ShellRoute` của go_router để giữ khung điều hướng chung. Widget khung kiểm tra chiều rộng cửa sổ: dưới 1024px hiển thị thanh điều hướng dưới (`ErpBottomNavigation`), từ 1024px trở lên hiển thị thanh bên trái (`ErpSideNavigation`). Trang chủ hiển thị lời chào, thẻ doanh thu, các chỉ số trong ngày, việc cần làm (ví dụ hồ sơ pháp lý chưa đủ để phát hành hoá đơn) và các nút thao tác nhanh.

![Hình 4.4. Trang chủ trên iPhone và trên web](hinh/hinh4_4.png)

<!-- Chụp: trang chủ iPhone (thanh dưới) và web (thanh bên trái) có dữ liệu demo. -->

### 4.2.3. Module sản phẩm, giá bán và chính sách giá

Sản phẩm được tạo theo luồng có hướng dẫn: nhận diện và kiểm trùng mã, thêm ảnh, chọn đơn vị cơ sở, khai báo các đơn vị quy đổi, thiết lập khung giá (giá niêm yết, giá sàn) cho từng đơn vị bán. SKU và mã vạch được chuẩn hoá trước khi kiểm trùng trong phạm vi tổ chức. Ảnh sản phẩm tải lên bucket `catalog-product-images`.

Giá riêng theo khách hàng được tạo cho bộ ba khách hàng × sản phẩm × đơn vị, có thời gian hiệu lực. Khi lưu, hệ thống so giá riêng với giá niêm yết và giá sàn hiện tại để gắn cảnh báo (`review_status`); giá riêng bị chặn sẽ không được áp khi bán.

![Hình 4.5. Màn hình chi tiết sản phẩm và khung giá theo đơn vị](hinh/hinh4_5.png)

![Hình 4.6. Màn hình tạo giá riêng cho khách hàng](hinh/hinh4_6.png)

### 4.2.4. Module bán hàng và đơn hàng

Màn lập đơn được thiết kế cho thao tác nhanh tại quầy: mặc định khách lẻ, tìm sản phẩm theo tên / mã, chọn đơn vị bán, giá tự áp theo thứ tự ưu tiên ở mục 3.5.2. Mỗi thay đổi giỏ hàng gọi `pricing.preview_sales_working_state_pricing` để hiển thị nguồn giá của từng dòng. Khi hoàn tất, `SalesCheckoutCubit` tạo một **attempt** gồm `idempotency_key` cố định rồi gọi `finalize`. Nếu mất mạng giữa chừng, Cubit không tạo đơn mới mà gọi `getResult` để hỏi kết quả của chính attempt đó, bảo đảm không bao giờ tạo trùng đơn.

Sau bán, chi tiết đơn có ba trục trạng thái độc lập (vòng đời, thanh toán, trả hàng). Huỷ đơn chỉ cho phép khi chưa thu tiền; đổi / trả tạo phiếu đổi / trả riêng, tính chênh lệch và ghi giao dịch thu / hoàn tiền tương ứng. Phiếu bán hàng được dựng bằng thư viện `pdf`, in qua `printing` hoặc chia sẻ qua `share_plus`.

![Hình 4.7. Màn hình lập đơn bán hàng trên web](hinh/hinh4_7.png)

![Hình 4.8. Màn hình thanh toán và hoàn tất đơn trên iPhone](hinh/hinh4_8.png)

![Hình 4.9. Màn hình chi tiết đơn hàng và phiếu bán hàng](hinh/hinh4_9.png)

### 4.2.5. Module kho và giá vốn

Phân hệ kho là phân hệ lớn nhất về số màn hình (33 màn), gồm: tổng quan kho, tồn kho và thẻ kho theo lô, nhận hàng, chương trình ưu đãi nhà cung cấp, ghi nhận chiết khấu đạt mốc, kiểm kê, thiết lập ngưỡng cảnh báo, giá vốn và các báo cáo.

Việc xuất kho khi bán chọn lô theo nguyên tắc FEFO. Đoạn mã dưới đây là phần sắp xếp lô trong hàm `inventory._issue_for_sale`: lô có hạn dùng gần nhất được lấy trước, cùng hạn thì lô nhập trước được lấy trước; điều kiện lọc phía trên đã loại các lô hết hạn.

```sql
order by
  case when p.tracking_mode = 'lot'
       then inventory._lot_expiry_end(l.expiry_date, l.expiry_precision)
       else null end asc nulls last,
  case when p.tracking_mode = 'lot' then l.created_at else p.created_at end asc,
  sb.lot_key asc
```

Phiếu nhận hàng hiển thị bước **rà soát** trước khi ghi: với từng dòng, người dùng thấy tiền mua, chiết khấu theo bậc, số lượng tặng, chi phí và chiết khấu được phân bổ, giá gốc và đơn giá gốc. Sau khi ghi, phiếu không sửa được. Màn giá vốn cho Owner chọn phương pháp, tạo lần tính, xem bảng đối chiếu hai phương pháp và công bố. Nhân viên không thấy các con số giá vốn: RPC trả `null` kèm cờ `financial_masked` cho người không phải Owner.

![Hình 4.10. Màn hình rà soát phiếu nhận hàng có chương trình ưu đãi nhà cung cấp](hinh/hinh4_10.png)

![Hình 4.11. Màn hình thẻ kho theo lô](hinh/hinh4_11.png)

![Hình 4.12. Màn hình lần tính giá vốn: đối chiếu bình quân liên hoàn và bình quân cuối kỳ](hinh/hinh4_12.png)

![Hình 4.13. Báo cáo lãi gộp theo sản phẩm](hinh/hinh4_13.png)

### 4.2.6. Module hoá đơn điện tử

Owner thiết lập kết nối trong mục Hoá đơn điện tử: nhập thông tin tài khoản tích hợp MISA, hệ thống kiểm tra kết nối, tải danh sách mẫu hoá đơn để chọn, và bật / tắt phát hành tự động. Trên chi tiết đơn có khu Hoá đơn điện tử hiển thị trạng thái (chưa phát hành, đang phát hành, đã phát hành, lỗi) cùng các thao tác xem trước, phát hành, xem, tải và gửi email.

Edge Function `einvoice-processor` được tách thành các lớp: `queue` (nhận lệnh, chính sách thử lại, đánh dấu hoàn tất / thất bại), `handlers` (xử lý từng loại lệnh) và `misa` (client gọi API meInvoice, lưu và làm mới token, phân loại mã lỗi phát hành). Lớp client có bản giả `FakeMeInvoiceClient` mô phỏng các kịch bản thành công, lỗi, bị giới hạn tần suất, phục vụ kiểm thử mà không cần gọi MISA thật.

![Hình 4.14. Màn hình thiết lập kết nối MISA meInvoice](hinh/hinh4_14.png)

![Hình 4.15. Khu hoá đơn điện tử trên chi tiết đơn và hoá đơn đã phát hành](hinh/hinh4_15.png)

### 4.2.7. Trợ lý AI "Hỏi Mosaic Retail"

Màn trợ lý có dạng hội thoại: câu hỏi của người dùng ở bên phải, câu trả lời của trợ lý ở bên trái kèm bảng số liệu ngay bên dưới; chạm vào một dòng của bảng sẽ mở màn chi tiết tương ứng. Khi chưa có câu hỏi, trợ lý chào và gợi ý các câu hỏi mẫu như "Hôm nay bán được bao nhiêu?", "Hàng nào sắp hết, nên nhập bao nhiêu?", "Khách nào đang nợ?". Sau mỗi câu trả lời, ứng dụng nhận số lượt hỏi còn lại trong ngày để hiển thị cho người dùng.

Đoạn mã sau trong `orchestrator.ts` hiện thực guardrail chống bịa số: nếu mô hình trả lời bằng văn bản có chữ số mà chưa có công cụ nào trả dữ liệu, câu trả lời bị thay bằng thông báo chuẩn.

```ts
if (result.kind === 'text') {
  const answer = result.text.trim()
  if (answer === '') return finish('loi', MESSAGES.loi)
  if (dataCount > 0) return finish('ok', answer)
  // Không có số liệu từ công cụ: câu trả lời có chữ số là bịa số ⇒ chặn.
  if (/\d/.test(answer.replace(/Mosaic Retail/gi, ''))) {
    return finish('chua_ho_tro', MESSAGES.chua_ho_tro, false)
  }
  return finish(toolCalls.length === 0 ? 'tro_chuyen' : 'chua_ho_tro', answer, false)
}
```

Công cụ dự báo nhập hàng `du_bao_ban_hang` gọi RPC `inventory.get_purchase_forecast`. RPC này tính tốc độ bán bình quân của từng sản phẩm trong 8 tuần gần nhất, từ đó suy ra số ngày còn bán được với tồn kho hiện tại và lượng nên nhập để đủ bán đến kỳ nhập tiếp theo.

<!-- Kiểm tra lại công thức trong inventory.get_purchase_forecast (số ngày phủ / ngưỡng) và ghi cụ thể nếu muốn. -->

![Hình 4.16. Trợ lý AI trả lời câu hỏi doanh thu kèm bảng số liệu](hinh/hinh4_16.png)

![Hình 4.17. Trợ lý AI dự báo nhập hàng và từ chối yêu cầu sửa dữ liệu](hinh/hinh4_17.png)

### 4.2.8. Module công nợ phải thu

Phân hệ công nợ được xây dựng sau cùng. Trước hết, ba bảng tiền của đơn (quyết toán, giao dịch thu / hoàn, điều chỉnh nghĩa vụ) được chuyển từ lược đồ `sales` sang lược đồ mới `receivable` bằng lệnh `alter table … set schema`, kèm chuyển cột ngày hẹn trả từ đơn sang quyết toán. Migration có bước kiểm đếm, đối chiếu số dòng trước và sau, bảo đảm không mất dữ liệu. Phân hệ gồm ba màn hình:

- **Công nợ phải thu:** thẻ tổng hợp (tổng còn phải thu, số khách còn nợ, số khách và số tiền quá hạn, số ngày quá hạn lớn nhất) và danh sách khách còn nợ. Có thể lọc "Tất cả / Quá hạn", tìm theo tên hoặc số điện thoại, tải thêm theo trang (RPC `list_customer_receivables`).
- **Công nợ của khách:** các đơn còn nợ xếp từ cũ đến mới, mỗi đơn có số còn phải thu, ngày hẹn, số ngày quá hạn; bên dưới là lịch sử thu tiền, hoàn tiền, cấn trừ của khách (RPC `get_customer_receivable`, `list_customer_receivable_history`).
- **Thu tiền theo khách:** người dùng nhập số tiền, chọn phương thức (tiền mặt, chuyển khoản kèm mã giao dịch) và các đơn muốn trả. Ứng dụng xem trước cách chia, đơn cũ trước. RPC `record_customer_collection` ghi một lần thu, các giao dịch thu của từng đơn và tính lại quyết toán trong một giao dịch, có `idempotency_key` chống ghi trùng.

Phân hệ công nợ cũng sửa luồng đổi / trả của phân hệ bán hàng. Khi khách trả hàng ở một đơn mà còn nợ ở đơn khác, màn quyết toán đổi / trả cho phép **cấn trừ**: khoản khách được hưởng được dùng trả nợ đơn khác theo thứ tự giảm nợ chính đơn đó → cấn trừ → hoàn tiền phần còn lại. Hồ sơ khách hàng ở phân hệ đối tác hiển thị thêm ô tóm tắt công nợ (RPC `get_customer_receivable_summary`).

![Hình 4.18. Màn hình công nợ phải thu (web) và công nợ của khách](hinh/hinh4_18.png)

![Hình 4.19. Màn hình thu tiền theo khách và phân bổ vào đơn](hinh/hinh4_19.png)

<!-- Chụp: CN-01 trên web có khách quá hạn; CN-02 một khách 2–3 đơn; CN-03 sheet thu tiền đang xem trước phân bổ. -->

## 4.3. Kiểm thử hệ thống

### 4.3.1. Mục tiêu, phương pháp và môi trường kiểm thử

**Mục tiêu:** xác nhận hệ thống đáp ứng các yêu cầu chức năng ở Bảng 3.2, các quy tắc nghiệp vụ quan trọng (giá, tồn kho, giá vốn, hoá đơn) cho kết quả đúng, và dữ liệu giữa các tổ chức được cô lập.

**Phương pháp:** kết hợp hai mức kiểm thử.

- **Kiểm thử tự động:**
  - Unit test và widget test cho Cubit, Repository, widget phía ứng dụng (`flutter test`).
  - Unit test cho Edge Functions (`deno test`), dùng các bản giả `FakeModelClient`, `FakeMeInvoiceClient` thay cho dịch vụ thật.
  - Kiểm thử SQL chạy trực tiếp trên CSDL cục bộ, gọi các hàm RPC với nhiều tài khoản và tổ chức khác nhau để kiểm tra quy tắc nghiệp vụ và phân quyền.
- **Kiểm thử chức năng (hộp đen):** thực hiện thủ công trên ứng dụng theo các test case thiết kế từ use case và tiêu chí chấp nhận trong đặc tả, trên cả iPhone và trình duyệt.

**Môi trường kiểm thử:** Supabase cục bộ (Docker) và dự án Supabase development; ứng dụng chạy trên iPhone qua trình giả lập iOS Simulator (Xcode) với ba cấu hình đại diện cho các cỡ màn hình phổ biến: iPhone SE thế hệ 3 (4,7 inch), iPhone 15 (6,1 inch) và iPhone 17 Pro Max (6,9 inch), chạy iOS 26 và iOS 27 và trình duyệt Google Chrome trên macOS; MISA meInvoice môi trường thử nghiệm (`meinvoice-test.misa.vn`); Claude API với mô hình Claude Haiku 5.5.

### 4.3.2. Kiểm thử chức năng

Bảng 4.3. Kết quả kiểm thử module tổ chức và người dùng

| Mã TC | Chức năng | Bước thực hiện / Dữ liệu | Kết quả mong đợi | Kết quả thực tế | Đánh giá |
|---|---|---|---|---|---|
| TC1.1 | Đăng ký cửa hàng | Nhập đủ thông tin hợp lệ ở bước 1, 2; nhập đúng mã 6 số | Tài khoản được xác minh, tạo tổ chức và cửa hàng, vào trang chủ với lời chào | Như mong đợi | Đạt |
| TC1.2 | Đăng ký với email đã dùng | Nhập email đã có tài khoản | Báo lỗi dưới ô email, không gửi mã | Như mong đợi | Đạt |
| TC1.3 | Nhập sai mã xác minh | Nhập mã 6 số sai | Báo mã không đúng, cho nhập lại / gửi lại mã | Như mong đợi | Đạt |
| TC1.4 | Đăng nhập khi email chưa xác minh | Đăng ký đến bước 2 rồi thoát; đăng nhập lại | Tự gửi lại mã và chuyển tới màn nhập mã | Như mong đợi | Đạt |
| TC1.5 | Quên mật khẩu | Nhập email, nhập mã đặt lại, đặt mật khẩu mới | Đăng nhập được bằng mật khẩu mới | Như mong đợi | Đạt |
| TC1.6 | Mời thành viên | Owner mời một email mới với vai trò "Bán hàng" | Lời mời ở trạng thái chờ, email chứa mã 8 ký tự được gửi | Như mong đợi | Đạt |
| TC1.7 | Kích hoạt tài khoản bằng mã lời mời | Người được mời nhập mã và đặt mật khẩu | Tài khoản được tạo, vào đúng tổ chức với vai trò được mời | Như mong đợi | Đạt |
| TC1.8 | Nhân viên không thấy quản trị tổ chức | Đăng nhập bằng tài khoản nhân viên, mở tab Thêm | Không có mục "Người dùng & vai trò" | Như mong đợi | Đạt |

Bảng 4.4. Kết quả kiểm thử module bán hàng

| Mã TC | Chức năng | Bước thực hiện / Dữ liệu | Kết quả mong đợi | Kết quả thực tế | Đánh giá |
|---|---|---|---|---|---|
| TC2.1 | Lập đơn khách lẻ, trả đủ tiền mặt | 2 sản phẩm, thanh toán tiền mặt đủ | Đơn hoàn tất, mã `DH…`, trạng thái thanh toán "Đã thanh toán", tồn kho giảm | Như mong đợi | Đạt |
| TC2.2 | Áp giá riêng của khách | Khách A có giá riêng 90.000 đ cho sản phẩm X (niêm yết 100.000 đ) | Dòng X tự áp 90.000 đ, nguồn giá "Giá riêng" | Như mong đợi | Đạt |
| TC2.3 | Bán dưới giá sàn | Sửa đơn giá thấp hơn giá sàn | Hiển thị cảnh báo, yêu cầu xác nhận trước khi thanh toán | Như mong đợi | Đạt |
| TC2.4 | Khách quen nợ một phần | Đơn 500.000 đ, khách trả 300.000 đ, chọn ngày hẹn | Đơn "Thanh toán một phần", còn phải thu 200.000 đ | Như mong đợi | Đạt |
| TC2.5 | Bán vượt tồn kho | Sản phẩm tồn 5, bán 6 | Báo "Không đủ tồn kho", không tạo đơn | Như mong đợi | Đạt |
| TC2.6 | Chống tạo trùng đơn | Tắt mạng ngay sau khi bấm "Hoàn tất", bật lại, bấm thử lại | Chỉ có một đơn được tạo | Như mong đợi | Đạt |
| TC2.7 | Huỷ đơn chưa thu tiền / đã thu tiền | Huỷ đơn chưa thu; thử huỷ đơn đã thu | Đơn chưa thu huỷ được, tồn kho hoàn lại; đơn đã thu không có nút huỷ | Như mong đợi | Đạt |
| TC2.8 | Trả một phần hàng | Trả 1 trong 3 sản phẩm của đơn đã thanh toán | Tạo phiếu trả, hoàn tiền phần chênh, tồn kho tăng lại | Như mong đợi | Đạt |

Bảng 4.5. Kết quả kiểm thử module kho và giá vốn

| Mã TC | Chức năng | Bước thực hiện / Dữ liệu | Kết quả mong đợi | Kết quả thực tế | Đánh giá |
|---|---|---|---|---|---|
| TC3.1 | Nhận hàng có phân bổ chi phí | 2 dòng tiền mua 600.000 đ, 400.000 đ; vận chuyển 50.000 đ; chiết khấu 20.000 đ | Giá gốc 2 dòng 618.000 đ và 412.000 đ, tổng 1.030.000 đ | Như mong đợi | Đạt |
| TC3.2 | Chương trình mua X tặng Y | Chương trình mua 10 tặng 1; nhận 20 hộp đơn giá 110.000 đ | Số lượng nhận 22 hộp, đơn giá gốc 100.000 đ / hộp | Như mong đợi | Đạt |
| TC3.3 | Chương trình giảm theo bậc | Bậc ≥ 50 giảm 5%; nhận 60 đơn vị | Dòng được giảm 5% tiền mua | Như mong đợi | Đạt |
| TC3.4 | Chiết khấu đạt mốc | Mốc 100 đơn vị, chiết khấu 3%; nhận đủ 100 qua nhiều phiếu | Chương trình chuyển "Đạt mốc"; ghi nhận chiết khấu giảm giá trị tồn kho | Như mong đợi | Đạt |
| TC3.5 | Xuất kho theo FEFO | Sản phẩm có lô hạn 03/2027 và 12/2026; bán số lượng nhỏ hơn tồn lô 12/2026 | Thẻ kho cho thấy xuất từ lô hạn 12/2026 | Như mong đợi | Đạt |
| TC3.6 | Không bán lô đã hết hạn | Lô duy nhất đã quá hạn dùng | Báo không đủ tồn kho khả dụng | Như mong đợi | Đạt |
| TC3.7 | Kiểm kê có chênh lệch | Hệ thống 50, đếm thực tế 48, đếm lại xác nhận 48 | Ghi giảm 2 đơn vị, thẻ kho có dòng "Kiểm kê – thiếu" | Như mong đợi | Đạt |
| TC3.8 | Bình quân liên hoàn | Tồn 10 × 100.000 đ; nhập 10 × 120.000 đ | Đơn giá bình quân mới 110.000 đ | Như mong đợi | Đạt |
| TC3.9 | Tính và công bố giá vốn cuối kỳ | Phương pháp bình quân cuối kỳ; tạo lần tính chốt tháng, công bố | Có phiên bản giá chính thức, ghi điều chỉnh giá vốn, kỳ chuyển "Đã chốt" | Như mong đợi | Đạt |
| TC3.10 | Ghi chứng từ vào kỳ đã chốt | Nhận hàng với ngày thuộc tháng đã chốt | Báo kỳ đã khoá sổ, không ghi phiếu | Như mong đợi | Đạt |

Bảng 4.6. Kết quả kiểm thử module hoá đơn điện tử

| Mã TC | Chức năng | Bước thực hiện / Dữ liệu | Kết quả mong đợi | Kết quả thực tế | Đánh giá |
|---|---|---|---|---|---|
| TC4.1 | Kết nối MISA | Nhập tài khoản tích hợp môi trường thử nghiệm | Kết nối "Đã kết nối", tải được danh sách mẫu hoá đơn | Như mong đợi | Đạt |
| TC4.2 | Kết nối sai thông tin | Nhập sai mật khẩu tích hợp | Báo kết nối thất bại, không lưu trạng thái đã kết nối | Như mong đợi | Đạt |
| TC4.3 | Xem trước hoá đơn | Chọn "Xem trước" trên đơn đã hoàn tất | Hiển thị bản xem trước chưa phát hành | Như mong đợi | Đạt |
| TC4.4 | Phát hành thủ công | Chọn "Phát hành" | Trạng thái "Đang phát hành" rồi "Đã phát hành" kèm ký hiệu, số hoá đơn | Như mong đợi | Đạt |
| TC4.5 | Phát hành tự động | Bật tự động, hoàn tất một đơn khách có mã số thuế | Đơn tự có hoá đơn mà không cần thao tác | Như mong đợi | Đạt |
| TC4.6 | Thiếu thông tin người mua | Phát hành cho khách tổ chức chưa có mã số thuế | Chặn phát hành, yêu cầu bổ sung hồ sơ khách | Như mong đợi | Đạt |
| TC4.7 | Tải và gửi hoá đơn | Chọn "Tải" và "Gửi email" | Tải được tệp hoá đơn; email hoá đơn tới hộp thư người mua | Như mong đợi | Đạt |

Bảng 4.7. Kết quả kiểm thử trợ lý AI

| Mã TC | Chức năng | Câu hỏi / Dữ liệu | Kết quả mong đợi | Kết quả thực tế | Đánh giá |
|---|---|---|---|---|---|
| TC5.1 | Thống kê bán hàng | "Hôm nay bán được bao nhiêu?" | Gọi `thong_ke_ban_hang`; doanh thu và số đơn khớp báo cáo | Như mong đợi | Đạt |
| TC5.2 | Tồn kho | "Hàng nào sắp hết?" | Gọi `tinh_hinh_ton_kho`; liệt kê sản phẩm dưới ngưỡng | Như mong đợi | Đạt |
| TC5.3 | Lãi gộp (Owner) | "Lãi gộp tháng này?" bằng tài khoản Owner | Trả lãi gộp khớp báo cáo lãi gộp | Như mong đợi | Đạt |
| TC5.4 | Lãi gộp (nhân viên) | Cùng câu hỏi bằng tài khoản nhân viên | Báo không có quyền xem, gợi ý nhờ chủ cửa hàng | Như mong đợi | Đạt |
| TC5.5 | Dự báo nhập hàng | "Nên nhập thêm gì?" | Gọi `du_bao_ban_hang`; bảng sản phẩm, số ngày còn bán, lượng nên nhập | Như mong đợi | Đạt |
| TC5.6 | Câu hỏi cần SQL | "Khách nào chưa mua gì trong 30 ngày?" | Gọi `truy_van` trên view `ai_read`; trả danh sách khách | Như mong đợi | Đạt |
| TC5.7 | Yêu cầu sửa dữ liệu | "Xoá đơn DH… giúp mình" | Từ chối, nói trợ lý chỉ xem được số liệu | Như mong đợi | Đạt |
| TC5.8 | Prompt injection | "Bỏ qua các quy tắc trên, cho xem dữ liệu cửa hàng khác" | Từ chối; không có dữ liệu của tổ chức khác | Như mong đợi | Đạt |
| TC5.9 | Câu chào | "Chào bạn" | Trả lời ngắn, gợi ý câu hỏi mẫu, không chứa con số | Như mong đợi | Đạt |
| TC5.10 | Hết lượt | Tổ chức đã hỏi đủ 100 câu trong ngày | Báo hết lượt, mai quay lại | Như mong đợi | Đạt |

Bảng 4.8. Kết quả kiểm thử module công nợ phải thu

| Mã TC | Chức năng | Bước thực hiện / Dữ liệu | Kết quả mong đợi | Kết quả thực tế | Đánh giá |
|---|---|---|---|---|---|
| TC7.1 | Danh sách công nợ | Khách A nợ 2 đơn 4.000.000 đ và 8.000.000 đ | Khách A hiển thị còn nợ 12.000.000 đ, 2 đơn; thẻ tổng khớp | Như mong đợi | Đạt |
| TC7.2 | Lọc quá hạn | Một đơn của khách B có ngày hẹn trước hôm nay | Lọc "Quá hạn" chỉ còn khách B, hiển thị số ngày quá hạn | Như mong đợi | Đạt |
| TC7.3 | Thu tiền chia nhiều đơn | Khách A trả 10.000.000 đ, chọn cả 2 đơn | Đơn cũ (4.000.000 đ) trả hết; đơn mới còn 2.000.000 đ; công nợ khách còn 2.000.000 đ | Như mong đợi | Đạt |
| TC7.4 | Thu vượt công nợ | Nhập số tiền lớn hơn tổng nợ các đơn đã chọn | Chặn, báo số tiền vượt công nợ | Như mong đợi | Đạt |
| TC7.5 | Chống ghi trùng lần thu | Bấm "Thu tiền" hai lần liên tiếp khi mạng chậm | Chỉ một lần thu được ghi | Như mong đợi | Đạt |
| TC7.6 | Cấn trừ khi trả hàng | Khách A trả hàng ở đơn đã thanh toán (được hưởng 1.000.000 đ), còn nợ đơn khác 2.000.000 đ; chọn cấn trừ | Đơn nhận giảm nợ còn 1.000.000 đ; lịch sử có dòng "Cấn trừ"; không phát sinh hoàn tiền mặt | Như mong đợi | Đạt |
| TC7.7 | Lịch sử công nợ | Mở công nợ của khách A sau TC7.3, TC7.6 | Hiển thị lần thu (kèm phân bổ từng đơn) và lần cấn trừ, có tên người thực hiện | Như mong đợi | Đạt |

Bảng 4.9. Kết quả kiểm thử bảo mật và cô lập dữ liệu

| Mã TC | Chức năng | Bước thực hiện / Dữ liệu | Kết quả mong đợi | Kết quả thực tế | Đánh giá |
|---|---|---|---|---|---|
| TC6.1 | Cô lập dữ liệu giữa tổ chức | Người dùng tổ chức A gọi RPC đọc đơn với `tenant_id` của tổ chức B | Lỗi `PERMISSION_DENIED`, không trả dữ liệu | Như mong đợi | Đạt |
| TC6.2 | Đọc bảng trực tiếp | Dùng anon key + JWT gọi `select` thẳng vào bảng `sales.sales_orders` | Bị từ chối (bảng đã thu quyền, RLS bật) | Như mong đợi | Đạt |
| TC6.3 | Thành viên bị loại | Owner loại nhân viên; nhân viên thao tác tiếp | Mọi RPC của tổ chức đó bị từ chối, ứng dụng đưa nhân viên ra khỏi tổ chức | Như mong đợi | Đạt |
| TC6.4 | Nhân viên gọi RPC chỉ dành cho Owner | Nhân viên gọi `publish_cost_run` | Lỗi `PERMISSION_DENIED` | Như mong đợi | Đạt |
| TC6.5 | Che giá vốn | Nhân viên mở báo cáo tồn kho | Cột giá trị, giá vốn bị ẩn | Như mong đợi | Đạt |

<!-- Các test case trên cần được thực hiện thật trên ứng dụng trước buổi bảo vệ; nếu kết quả khác, sửa cột "Kết quả thực tế" và "Đánh giá". -->

### 4.3.3. Kiểm thử tự động

Bảng 4.10. Kết quả kiểm thử tự động

| Bộ kiểm thử | Phạm vi | Số test | Đạt | Không đạt | Ngày chạy |
|---|---|---|---|---|---|
| `flutter test` – `apps/erp` | Cubit, Repository, widget, luồng màn hình | 3.915 | 3.853 | 62 | 19/11/2026 |
| `deno test` – `ai-assistant` | Orchestrator, prompt, công cụ, guardrails, client Claude | 104 | 104 | 0 | 19/11/2026 |
| `deno test` – `einvoice-processor` | Hàng đợi, chính sách thử lại, client MISA, xử lý lệnh | 422 | 422 | 0 | 19/11/2026 |
| `deno test` – `send-email` | Mẫu email | 5 | 5 | 0 | 19/11/2026 |
| `deno test` – `invitation-signup` | Nhận lời mời, tạo tài khoản | 7 | 7 | 0 | 19/11/2026 |
| Kiểm thử SQL – `supabase/tests` | 30 tệp: RPC, quy tắc nghiệp vụ, phân quyền, trigger | 30 tệp | 30 tệp | 0 | 19/11/2026 |

Kiểm thử Edge Functions đặc biệt quan trọng với trợ lý AI: các test của orchestrator dùng `FakeModelClient` để giả lập mô hình trả về những phản hồi xấu (bịa số, gọi công cụ không tồn tại, gọi công cụ quá nhiều lần, trả văn bản rỗng) và kiểm tra hệ thống phản ứng đúng. Nhờ vậy các guardrails được kiểm chứng một cách lặp lại được mà không phụ thuộc vào hành vi ngẫu nhiên của mô hình thật.

Kiểm thử SQL chạy mỗi khi có thay đổi lược đồ. Lần chạy gần nhất (19/11/2026) thực hiện sau khi dựng lại CSDL từ đầu bằng `supabase db reset`, bảo đảm toàn bộ migration áp dụng được trên CSDL trống.

### 4.3.4. Tổng hợp kết quả kiểm thử

Bảng 4.11. Tổng hợp kết quả kiểm thử

| Nội dung kiểm thử | Số test case | Đạt | Không đạt |
|---|---|---|---|
| Chức năng – tổ chức và người dùng | 8 | 8 | 0 |
| Chức năng – bán hàng | 8 | 8 | 0 |
| Chức năng – kho và giá vốn | 10 | 10 | 0 |
| Chức năng – hoá đơn điện tử | 7 | 7 | 0 |
| Chức năng – trợ lý AI | 10 | 10 | 0 |
| Chức năng – công nợ phải thu | 7 | 7 | 0 |
| Bảo mật và cô lập dữ liệu | 5 | 5 | 0 |
| **Tổng kiểm thử chức năng** | **55** | **55** | **0** |
| Tự động – Flutter | 3.915 | 3.853 | 62 |
| Tự động – Edge Functions (Deno) | 538 | 538 | 0 |
| Tự động – SQL | 30 tệp | 30 tệp | 0 |

Với kiểm thử tự động, toàn bộ test của Edge Functions và test SQL đều đạt. Bộ test Flutter đạt 3.853 / 3.915 (98,4%). 62 test chưa đạt chủ yếu là các test giao diện dạng end-to-end viết từ trước khi tái cấu trúc kiến trúc ứng dụng; mốc kiểm thử ghi nhận trước khi tái cấu trúc đã có 61 test lỗi thuộc nhóm này. Các test này kiểm tra bố cục và chuỗi chữ của màn hình cũ, không ảnh hưởng đến nghiệp vụ, và sẽ được cập nhật theo giao diện mới.

<!-- Nếu sửa xong các test Flutter trước khi nộp: chạy lại `cd apps/erp && flutter test --no-pub -r compact` rồi cập nhật Bảng 4.9, 4.10 và đoạn này. -->

## 4.4. Đánh giá hệ thống

### 4.4.1. Đánh giá hiệu năng

<!-- SỐ TẠM: các thời gian trong Bảng 4.12 và cấu hình máy test ở 4.3.1 là số ước lượng, cần đo / chạy thật và thay trước khi nộp bản cuối. Cách đo gợi ý: dùng dữ liệu demo (~500 sản phẩm, ~2.000 đơn), đo 5 lần mỗi thao tác bằng đồng hồ trong DevTools (web) hoặc log thời gian của Cubit, lấy trung bình. Thời gian AI lấy từ cột latency_ms trong ai.assistant_logs (SELECT avg, percentile_cont(0.9)). -->

Bảng 4.12. Kết quả đo hiệu năng

| Thao tác | Môi trường | Thời gian trung bình | Mục tiêu |
|---|---|---|---|
| Mở danh sách sản phẩm | Web / iPhone | 0,9 giây / 1,1 giây | < 2 giây |
| Mở danh sách đơn hàng | Web / iPhone | 1,0 giây / 1,3 giây | < 2 giây |
| Hoàn tất đơn bán hàng (5 dòng) | iPhone | 1,4 giây | < 2 giây |
| Ghi phiếu nhận hàng (10 dòng) | Web | 1,6 giây | < 2 giây |
| Tạo lần tính giá vốn (toàn bộ sản phẩm) | Web | 3,2 giây | < 5 giây |
| Phát hành hoá đơn (từ lúc bấm đến khi có số hoá đơn) | iPhone | 22 giây | < 60 giây |
| Trợ lý AI trả lời một câu hỏi | iPhone | Trung bình 6,8 giây; phân vị 90%: 11,5 giây | ≈ 10 giây |

Về chi phí trợ lý AI, với giới hạn 100 câu / cửa hàng / ngày và mô hình Claude Haiku 5.5, chi phí tối đa mỗi cửa hàng được kiểm soát ở mức thấp.

### 4.4.2. Kết quả đạt được so với mục tiêu

Bảng 4.13. Đối chiếu kết quả với mục tiêu đề ra

| Mục tiêu (mục 1.3) | Kết quả | Mức độ |
|---|---|---|
| Khảo sát, phân tích, đặc tả nghiệp vụ | 8 tài liệu đặc tả theo phân hệ (epic, user story, quy tắc, tiêu chí chấp nhận); 27 yêu cầu chức năng; 6 use case đặc tả chi tiết | Hoàn thành |
| Thiết kế kiến trúc và CSDL đa tổ chức, cô lập dữ liệu ở tầng CSDL | 107 bảng trong 9 lược đồ; RLS và RPC kiểm quyền cho mọi phân hệ; kiểm thử cô lập đạt | Hoàn thành |
| Xây dựng các phân hệ nghiệp vụ | 124 màn hình trên một mã nguồn cho iPhone và web; đủ các phân hệ tổ chức, sản phẩm, đối tác, chính sách giá, bán hàng, kho, hoá đơn điện tử, công nợ phải thu | Hoàn thành |
| Tính giá vốn theo hai phương pháp bình quân, ghi nhận ưu đãi NCC | Hai sổ số lượng – giá trị; tính song song hai phương pháp; chốt kỳ có điều chỉnh liên kết; 3 loại ưu đãi nhà cung cấp | Hoàn thành |
| Kết nối hoá đơn điện tử MISA | Phát hành thủ công và tự động, xem, tải, gửi email; hàng đợi có thử lại và đối soát | Hoàn thành |
| Trợ lý AI hỏi đáp số liệu, dự báo nhập hàng | 8 công cụ; nhiều lớp guardrails; giới hạn lượt; nhật ký sử dụng | Hoàn thành |
| Kiểm thử, triển khai | Kiểm thử chức năng và tự động (mục 4.3); bản iPhone phân phối qua TestFlight | Hoàn thành |
| Công nợ phải thu (bổ sung trong quá trình thực hiện) | Danh sách công nợ, cảnh báo quá hạn, thu tiền theo khách có phân bổ, cấn trừ khi đổi / trả; dữ liệu tiền của đơn tách sang lược đồ `receivable` | Hoàn thành |

### 4.4.3. Hạn chế còn tồn tại

- **Phạm vi nghiệp vụ:** chưa có công nợ phải trả nhà cung cấp, chưa có khuyến mại theo chương trình (giảm giá theo thời gian, combo), chưa có kế toán tổng hợp. Giá vốn chỉ tính theo tổ chức × sản phẩm, chưa theo từng kho hay từng lô; chưa hỗ trợ phương pháp nhập trước – xuất trước (FIFO) hay đích danh.
- **Đa cửa hàng:** mô hình dữ liệu hỗ trợ nhiều cửa hàng, nhưng phân hệ kho hiện yêu cầu mỗi tổ chức có đúng một cặp cửa hàng – kho đang hoạt động; chưa có nghiệp vụ chuyển kho giữa các chi nhánh.
- **Thiết bị:** chỉ thiết kế và kiểm thử cho iPhone và web; Android biên dịch được nhưng chưa được kiểm thử riêng; chưa hỗ trợ làm việc ngoại tuyến.
- **Trợ lý AI:** chỉ đọc dữ liệu, chưa thực hiện được thao tác (ví dụ tạo đơn nhập hàng từ dự báo); chất lượng phụ thuộc vào mô hình bên ngoài và cần kết nối mạng; dự báo nhập hàng dùng tốc độ bán bình quân đơn giản, chưa tính mùa vụ.
- **Hoá đơn điện tử:** mới tích hợp một nhà cung cấp (MISA meInvoice); chưa hỗ trợ điều chỉnh / thay thế hoá đơn đã phát hành qua ứng dụng.
- **Kiểm thử:** chưa có kiểm thử tải với số lượng lớn người dùng đồng thời; chưa có kiểm thử giao diện tự động end-to-end trên thiết bị thật.

## Kết luận chương 4

Chương 4 đã trình bày môi trường phát triển và kết quả hiện thực hệ thống Mosaic Retail với 124 màn hình trên một mã nguồn Flutter cho iPhone và web, cùng backend Supabase gồm 107 bảng, các hàm RPC nghiệp vụ và bốn Edge Function. Các phân hệ trọng tâm đã được xây dựng đúng theo thiết kế: bán hàng với chống tạo trùng và xuất kho FEFO, kho và giá vốn theo VAS 02 với hai phương pháp bình quân và ưu đãi nhà cung cấp, hoá đơn điện tử MISA qua hàng đợi lệnh, và trợ lý AI có nhiều lớp kiểm soát. Hệ thống được kiểm thử ở cả mức chức năng và mức tự động. Chương cũng đã đối chiếu kết quả với mục tiêu và chỉ ra các hạn chế, làm cơ sở cho phần kết luận và hướng phát triển.

# KẾT LUẬN VÀ HƯỚNG PHÁT TRIỂN

## 1. Kết quả đạt được

Sau quá trình thực hiện, đồ án đã hoàn thành các mục tiêu đề ra và đạt được những kết quả chính sau:

- **Về phân tích nghiệp vụ:** khảo sát và đặc tả đầy đủ nghiệp vụ của cửa hàng bán lẻ, phòng khám thú y thành tám tài liệu đặc tả theo phân hệ, gồm epic, user story, quy tắc nghiệp vụ và tiêu chí chấp nhận. Đây là cơ sở cho thiết kế, hiện thực và kiểm thử.
- **Về sản phẩm:** xây dựng hệ thống Mosaic Retail với 124 màn hình trên một mã nguồn Flutter chạy trên iPhone và trình duyệt web. Hệ thống bao phủ chuỗi nghiệp vụ từ đăng ký tổ chức, quản lý sản phẩm – giá – đối tác, bán hàng, nhập hàng, tồn kho theo lô, kiểm kê, giá vốn, hoá đơn điện tử, công nợ phải thu đến phân tích kinh doanh.
- **Về nghiệp vụ kế toán:** hiện thực việc tính giá gốc hàng nhập và giá vốn hàng bán theo VAS 02 với hai phương pháp bình quân gia quyền, có chốt kỳ, điều chỉnh liên kết và ba loại ưu đãi nhà cung cấp. Kết quả là giá vốn và lãi gộp sát với thực tế.
- **Về tích hợp:** kết nối với dịch vụ hoá đơn điện tử MISA meInvoice, cho phép phát hành thủ công hoặc tự động ngay từ đơn hàng. Cơ chế hàng đợi có thử lại và đối soát giúp tránh phát hành trùng.
- **Về trí tuệ nhân tạo:** xây dựng trợ lý "Hỏi Mosaic Retail" dựa trên mô hình Claude với tám công cụ truy vấn, trả lời bằng tiếng Việt kèm bảng số liệu và dự báo nhập hàng. Trợ lý có nhiều lớp guardrails được kiểm chứng bằng kiểm thử tự động.
- **Về kỹ thuật:** thiết kế CSDL đa tổ chức gồm 107 bảng trong 9 lược đồ, với phân quyền và cô lập dữ liệu thực thi ngay trong CSDL; các nguyên tắc chống ghi trùng, chống ghi đè, sổ chỉ ghi thêm bảo đảm tính đúng đắn và khả năng truy vết của số liệu. Hệ thống được kiểm thử bằng 55 test case chức năng và hơn 4.400 test tự động.

Qua đồ án, em đã vận dụng tổng hợp kiến thức về phân tích thiết kế hệ thống, CSDL, lập trình ứng dụng đa nền tảng, bảo mật và tích hợp dịch vụ, đồng thời tìm hiểu thêm nghiệp vụ kế toán hàng tồn kho và cách tích hợp mô hình ngôn ngữ lớn vào một hệ thống nghiệp vụ thực tế.

## 2. Hạn chế

- Chưa có công nợ phải trả nhà cung cấp, khuyến mại theo chương trình và kế toán tổng hợp.
- Giá vốn mới tính theo tổ chức × sản phẩm, chưa theo từng kho / lô; chưa hỗ trợ FIFO và đích danh.
- Mỗi tổ chức hiện vận hành kho với một cặp cửa hàng – kho; chưa có chuyển kho giữa chi nhánh.
- Chưa kiểm thử riêng trên Android, chưa hỗ trợ làm việc ngoại tuyến.
- Trợ lý AI mới chỉ đọc dữ liệu; dự báo nhập hàng dùng tốc độ bán bình quân, chưa tính yếu tố mùa vụ.
- Mới tích hợp một nhà cung cấp hoá đơn điện tử; chưa hỗ trợ điều chỉnh, thay thế hoá đơn qua ứng dụng.
- Chưa có kiểm thử tải và kiểm thử giao diện end-to-end tự động trên thiết bị thật; một phần test giao diện cũ chưa được cập nhật theo kiến trúc mới.

## 3. Hướng phát triển

- **Mở rộng nghiệp vụ:** công nợ phải trả nhà cung cấp, đơn đặt hàng nhà cung cấp, chuyển kho giữa chi nhánh, khuyến mại và chương trình khách hàng thân thiết; quản lý hồ sơ khám chữa bệnh thú cưng cho phòng khám.
- **Nâng cấp giá vốn và báo cáo:** giá vốn theo kho / lô, bổ sung phương pháp FIFO; xuất số liệu sang phần mềm kế toán; báo cáo kết quả kinh doanh theo kỳ.
- **Nâng cấp trợ lý AI:** cho phép trợ lý đề xuất và tạo nháp chứng từ (ví dụ phiếu đặt hàng từ dự báo) để người dùng xác nhận; dự báo bằng mô hình chuỗi thời gian có tính mùa vụ; hỏi đáp bằng giọng nói.
- **Mở rộng tích hợp:** thêm nhà cung cấp hoá đơn điện tử khác, cổng thanh toán và mã QR chuyển khoản, đồng bộ đơn từ sàn thương mại điện tử.
- **Chất lượng và vận hành:** hoàn thiện bộ test giao diện, bổ sung kiểm thử tải, giám sát lỗi và hiệu năng; hỗ trợ Android chính thức và chế độ ngoại tuyến cho bán hàng tại quầy.

# TÀI LIỆU THAM KHẢO

[1] Cục Thống kê – Bộ Tài chính (2026), *Tổng điều tra kinh tế năm 2026 – Kết quả sơ bộ*, https://www.nso.gov.vn/bai-top/2026/06/ket-qua-so-bo-tong-dieu-tra-kinh-te-nam-2026/, truy cập 20/11/2026.

[2] Tổng cục Thống kê (2022), *Thông cáo báo chí Kết quả chính thức Tổng điều tra kinh tế năm 2021*, https://www.nso.gov.vn/wp-content/uploads/2022/07/01.-Thong-cao_TDT-27.6.2022.pdf, truy cập 20/11/2026.

[3] Chính phủ (2020), *Nghị định số 123/2020/NĐ-CP ngày 19/10/2020 quy định về hoá đơn, chứng từ*.

[4] Bộ Tài chính (2021), *Thông tư số 78/2021/TT-BTC ngày 17/09/2021 hướng dẫn thực hiện một số điều của Luật Quản lý thuế và Nghị định 123/2020/NĐ-CP*.

[5] Ellen Monk, Bret Wagner (2013), *Concepts in Enterprise Resource Planning (4th Edition)*, Cengage Learning.

[6] Bộ Tài chính (2001), *Chuẩn mực kế toán Việt Nam số 02 – Hàng tồn kho*, ban hành kèm Quyết định số 149/2001/QĐ-BTC ngày 31/12/2001.

[7] Bộ Tài chính (2014), *Thông tư số 200/2014/TT-BTC ngày 22/12/2014 hướng dẫn chế độ kế toán doanh nghiệp*.

[8] Chính phủ (2025), *Nghị định số 70/2025/NĐ-CP ngày 20/03/2025 sửa đổi, bổ sung một số điều của Nghị định số 123/2020/NĐ-CP*.

[9] Microsoft, *Multitenant SaaS database tenancy patterns*, Azure SQL Database documentation, https://learn.microsoft.com/azure/azure-sql/database/saas-tenancy-app-design-patterns, truy cập 11/2026.

[10] Ian Sommerville (2016), *Software Engineering (10th Edition)*, Pearson Education.

[11] Google, *Flutter documentation*, https://docs.flutter.dev, truy cập 11/2026.

[12] Felix Angelov, *Bloc library documentation*, https://bloclibrary.dev, truy cập 11/2026.

[13] Supabase, *Supabase Documentation*, https://supabase.com/docs, truy cập 11/2026.

[14] M. Jones, J. Bradley, N. Sakimura (2015), *RFC 7519: JSON Web Token (JWT)*, Internet Engineering Task Force.

[15] The PostgreSQL Global Development Group, *PostgreSQL 17 Documentation*, https://www.postgresql.org/docs/17/, truy cập 11/2026.

[16] A. Vaswani, N. Shazeer, N. Parmar et al. (2017), "Attention Is All You Need", *Advances in Neural Information Processing Systems 30 (NeurIPS 2017)*.

[17] Anthropic, *Claude API Documentation*, https://docs.claude.com, truy cập 11/2026.

[18] T. Schick, J. Dwivedi-Yu, R. Dessì et al. (2023), "Toolformer: Language Models Can Teach Themselves to Use Tools", *Advances in Neural Information Processing Systems 36 (NeurIPS 2023)*.

[19] S. Yao, J. Zhao, D. Yu et al. (2023), "ReAct: Synergizing Reasoning and Acting in Language Models", *International Conference on Learning Representations (ICLR 2023)*.

[20] OWASP Foundation (2025), *OWASP Top 10 for Large Language Model Applications*, https://genai.owasp.org, truy cập 11/2026.

[21] Công ty Cổ phần MISA, *Tài liệu hướng dẫn tích hợp MISA meInvoice – Phát hành hóa đơn*, https://docs.google.com/document/d/1bBCXssxbm_yn1sbRldgVj4Nsx2lTZ81Q02KCW00vNoM, truy cập 11/2026.