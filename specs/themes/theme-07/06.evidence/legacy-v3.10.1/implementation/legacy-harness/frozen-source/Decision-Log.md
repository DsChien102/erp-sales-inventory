# Decision Log — Theme 7 Harness Source

> Frozen SRS identity: `T7-PACKAGE-FREEZE-v4.1.0`. Decision authority remains the byte-preserved `T7-BASELINE-FREEZE-v4.0.0` register below. This wrapper binds the unchanged decision baseline to the v4.1.0 SRS execution profile.

# Kho & giá vốn — Quyết định nghiệp vụ

> **Baseline `v4.0.0` đã đóng băng.** Nội dung đã được Business Owner duyệt ngày `2026-08-22`; package kế nhiệm đã chuyển đổi, kiểm tra chéo và đóng băng. Baseline tiền nhiệm `T7-BASELINE-FREEZE-v3.1.0` tiếp tục là hồ sơ bất biến.

## 1. Thông tin kiểm soát

| Thuộc tính | Giá trị |
|---|---|
| Theme | Theme 7 — Kho & giá vốn |
| Phiên bản tài liệu | `v4.0.0` |
| Trạng thái | `FROZEN` |
| Baseline đang có hiệu lực | `T7-BASELINE-FREEZE-v4.0.0` |
| Baseline tiền nhiệm | `T7-BASELINE-FREEZE-v3.1.0` — bất biến |
| Ngày đóng băng | `2026-08-22` |
| Phê duyệt nghiệp vụ | `APPROVED` — Business Owner |
| Phạm vi | 102 quyết định nghiệp vụ thuộc 14 nhóm khách quan |
| Nguyên tắc hợp nhất | Một thẩm quyền hoặc hiệu lực cuối cùng chỉ có một quyết định cha; chi tiết nhỏ nhưng cần kiểm thử được giữ thành yêu cầu nguyên tử |
| Định danh có thẩm quyền sau đóng băng | `freeze_id + decision_id`; không dùng ID trần để phân biệt với baseline cũ |
| Dữ liệu gốc | Quyết định nghiệp vụ của baseline `v4.0.0` |

### 1.1 Quy tắc nhận diện và liên kết

- Quyết định được đánh liên tục từ `T7-DR-001` đến `T7-DR-102` theo thứ tự 14 nhóm nghiệp vụ.
- Không phát hành bảng ánh xạ hoặc alias registry cho 207 ID cũ.
- Yêu cầu nguyên tử dùng locator logic `T7-DR-nnn#REQ-mm`; liên kết Markdown dùng anchor `#t7-dr-nnn-req-mm`.
- `REQ-mm` tăng theo thứ tự nội dung gốc đã được hợp nhất trong từng quyết định; sau khi đóng băng chỉ được thêm locator mới, không đánh lại locator đã phát hành.
- Các quy tắc quản trị, chỉ tiêu phi chức năng và chuẩn nội dung không nhận ID quyết định nghiệp vụ.

## 2. Quy ước trạng thái

| Trạng thái | Ý nghĩa |
|---|---|
| `ACTIVE` | Quyết định hoặc yêu cầu đang có hiệu lực trong Phase 1. |
| `DEFERRED` | Định hướng được giữ cho tương lai nhưng chưa triển khai trong Phase 1. |
| `OUT_OF_SCOPE` | Nghiệp vụ được loại rõ khỏi Phase 1 và phải bị từ chối có cấu trúc. |

**Quy tắc vòng đời:** trạng thái của yêu cầu nguyên tử độc lập với trạng thái quyết định cha. Yêu cầu `DEFERRED` hoặc `OUT_OF_SCOPE` không trở thành `ACTIVE` chỉ vì quyết định cha đang hoạt động.

## 3. Danh mục quyết định nghiệp vụ

### 3.0 Mục lục nhanh

- [`G01` — Phạm vi, thẩm quyền và mô hình cửa hàng–kho](#g01) · 8 quyết định
- [`G02` — Định danh số dư, đơn vị tính và chính sách theo dõi](#g02) · 11 quyết định
- [`G03` — Nhận hàng và xác nhận giá trị](#g03) · 8 quyết định
- [`G04` — Khả dụng, giữ hàng, lấy hàng và xuất](#g04) · 7 quyết định
- [`G05` — Kiểm kê và điều chỉnh tồn](#g05) · 5 quyết định
- [`G06` — Trả hàng, trạng thái, hết hạn và tiêu hủy](#g06) · 9 quyết định
- [`G07` — Giá trị tồn, giá vốn và chốt kỳ](#g07) · 15 quyết định
- [`G08` — Sửa sai và hoàn nguyên](#g08) · 3 quyết định
- [`G09` — Số dư đầu kỳ và Chuyển đổi chính thức](#g09) · 3 quyết định
- [`G10` — Inventory Operation, tích hợp, chống trùng và kết quả chưa xác định](#g10) · 8 quyết định
- [`G11` — Quyền, phê duyệt và bảo vệ dữ liệu](#g11) · 6 quyết định
- [`G12` — Sổ nghiệp vụ, báo cáo, đối soát, cảnh báo và phục hồi](#g12) · 8 quyết định
- [`G13` — Dữ liệu chủ, combo, bổ sung hàng và nghiệp vụ đặc biệt](#g13) · 6 quyết định
- [`G14` — Chiết khấu mua hàng, định giá bán và lợi nhuận](#g14) · 5 quyết định

<a id="g01"></a>
## 3.1 G01 — Phạm vi, thẩm quyền và mô hình cửa hàng–kho

<a id="t7-dr-001"></a>
### T7-DR-001 — Phạm vi kênh bán Phase 1

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G01`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Phase 1 phục vụ bán lẻ, bán sỉ và hoàn tất đơn trực tuyến.

<a id="t7-dr-002"></a>
### T7-DR-002 — Ranh giới thẩm quyền Theme 7

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G01`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Miền kho và giá vốn sở hữu số lượng, khả dụng, trạng thái, hồ sơ lô, sổ biến động số lượng, sổ giá trị và giá vốn tồn kho; không sở hữu chứng từ mua, bán, giá bán hoặc master sản phẩm. Serial chưa thuộc phạm vi Phase 1.

<a id="t7-dr-003"></a>
### T7-DR-003 — Hợp đồng nguồn và quyền tạo Inventory Operation

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G01`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Chứng từ nguồn gửi yêu cầu cùng các assertion thuộc thẩm quyền của nguồn như phiên bản chứng từ, bàn giao hoặc chuyển quyền sở hữu; Theme 7 kiểm tra hợp đồng và invariant của mình rồi tạo/thực thi Inventory Operation. Không hệ thống nguồn nào được sửa trực tiếp số dư.

**Yêu cầu nguyên tử**

- <a id="t7-dr-003-req-01"></a>`T7-DR-003#REQ-01` · `ACTIVE` — Mọi điều kiện bảo vệ về quyền, phạm vi và nghiệp vụ vẫn do máy chủ kiểm tra; giao diện không thay thế hoặc mở rộng thẩm quyền của máy chủ.

<a id="t7-dr-004"></a>
### T7-DR-004 — Topology cửa hàng–kho Phase 1 và khả năng mở rộng

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G01`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Phase 1 chỉ có một cửa hàng hoạt động và một kho hoạt động. Nhiều người dùng có thể đồng thời giao dịch trực tuyến từ các địa điểm khác nhau nhưng không tạo thêm cửa hàng; mọi giao dịch được quy về cửa hàng và kho mặc định của tenant.
- Dữ liệu, định danh, hợp đồng và quan hệ cấp quyền vẫn mang `store_id` và `warehouse_id`, đồng thời cho phép mở rộng quan hệ cửa hàng–kho nhiều–nhiều mà không phải đổi nền tảng kiến trúc.

**Yêu cầu nguyên tử**

- <a id="t7-dr-004-req-01"></a>`T7-DR-004#REQ-01` · `ACTIVE` — Phase 1 không cho đóng hoặc đổi kho đang hoạt động.
- <a id="t7-dr-004-req-02"></a>`T7-DR-004#REQ-02` · `DEFERRED` — Vòng đời đóng hoặc đổi kho an toàn được để cho giai đoạn tương lai.

<a id="t7-dr-005"></a>
### T7-DR-005 — Chuyển kho nội bộ ngoài Phase 1

- **Trạng thái:** `OUT_OF_SCOPE`
- **Nhóm nghiệp vụ:** `G01`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Phase 1 chưa hỗ trợ chuyển kho nội bộ. API phải từ chối yêu cầu này; không được mô phỏng bằng adjustment.

<a id="t7-dr-006"></a>
### T7-DR-006 — Định hướng chuyển kho nội bộ

- **Trạng thái:** `DEFERRED`
- **Nhóm nghiệp vụ:** `G01`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Khi triển khai ở phiên bản sau, hàng rời kho nguồn khi operation gửi hoàn tất, trở thành tồn đang vận chuyển của tenant, không khả dụng ở hai kho; chênh lệch nhận được giữ để xử lý.

<a id="t7-dr-007"></a>
### T7-DR-007 — Phạm vi và cổng quyền sở hữu hàng hóa

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G01`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Hàng chưa chuyển quyền sở hữu cho tenant không được nhập Theme 7. Nguồn mua/nhận chịu trách nhiệm assertion về chuyển quyền sở hữu và bằng chứng/phiên bản của assertion; Theme 7 bắt buộc có assertion hợp lệ nhưng không tự phán quyết pháp lý. `VALUATION_PENDING` chỉ dùng cho hàng đã thuộc tenant nhưng chưa chốt giá.

**Yêu cầu nguyên tử**

- <a id="t7-dr-007-req-01"></a>`T7-DR-007#REQ-01` · `OUT_OF_SCOPE` — Phase 1 không quản lý hàng ký gửi, hàng giữ hộ hoặc hàng thuộc sở hữu bên thứ ba; không có `CUSTODY_ONLY`.

<a id="t7-dr-008"></a>
### T7-DR-008 — Guard và structured rejection cho capability ngoài phạm vi

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G01`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Nghiệp vụ ngoài Phase 1 phải nằm trong Scope Matrix/Behavioral Contract và bị từ chối bằng lỗi có cấu trúc; không tạo mutation bán phần.

**Yêu cầu nguyên tử**

- <a id="t7-dr-008-req-01"></a>`T7-DR-008#REQ-01` · `OUT_OF_SCOPE` — Phase 1 không mở bin/location chi tiết, chuyển kho nội bộ, đóng hoặc đổi kho, custody/ký gửi, chuyển đổi SKU, BOM/sản xuất, serial, POS offline, chuyển đổi `NONE ↔ LOT` khi còn tồn, dự báo bổ sung hàng hoặc đường sửa trực tiếp số dư/trạng thái. Việc bị loại khỏi Phase 1 không thay đổi định hướng dài hạn đã được quy định riêng cho từng capability.
- <a id="t7-dr-008-req-02"></a>`T7-DR-008#REQ-02` · `ACTIVE` — Chức năng tương lai không xuất hiện dưới dạng màn hình vô hiệu hóa, nhánh ẩn hoặc operation giả. Phase 1 chỉ giữ ranh giới mở rộng trong identity, dữ liệu và hợp đồng; yêu cầu ngoài phạm vi bị từ chối có cấu trúc.

<a id="g02"></a>
## 3.2 G02 — Định danh số dư, đơn vị tính và chính sách theo dõi

<a id="t7-dr-009"></a>
### T7-DR-009 — Cấp vị trí quản lý tồn

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G02`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Phase 1 quản lý vị trí đến cấp kho, không quản lý bin/kệ/vị trí chi tiết. Phân loại tình trạng vật lý/nghiệp vụ của hàng được thực hiện ở cấp kho; trạng thái định giá là một trục độc lập theo mô hình tại [`T7-DR-012`](#t7-dr-012).

<a id="t7-dr-010"></a>
### T7-DR-010 — Khóa định danh số dư tồn

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G02`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Một phân vùng lượng tồn được nhận diện bởi tenant + sản phẩm + kho + `physical_state` + `valuation_state`; bổ sung lô khi sản phẩm quản lý theo lô. Nếu hai trục được lưu ở các authority hoặc subledger khác nhau, hợp đồng vẫn phải bảo toàn phép phân hoạch này một cách nguyên tử và không được gộp lượng `VALUATION_PENDING` với lượng đã xác nhận định giá. Hạn dùng là thuộc tính của lô, không phải chiều định danh riêng; serial chưa thuộc Phase 1.

<a id="t7-dr-011"></a>
### T7-DR-011 — Quy đổi đơn vị và tồn theo đơn vị cơ sở

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G02`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Giao dịch được phép dùng nhiều đơn vị tính nhưng tồn luôn quy đổi và lưu theo đơn vị cơ sở. Chứng từ giữ lượng giao dịch, lượng cơ sở, tỷ lệ quy đổi và phiên bản tỷ lệ; mở bao gói thành đơn vị lẻ của cùng sản phẩm không tạo movement mới.

**Yêu cầu nguyên tử**

- <a id="t7-dr-011-req-01"></a>`T7-DR-011#REQ-01` · `ACTIVE` — Không đổi đơn vị cơ sở sau movement; phải migration có kiểm soát hoặc tạo sản phẩm mới. Hệ số đơn vị phụ có version hiệu lực và lịch sử giữ snapshot cũ.

<a id="t7-dr-012"></a>
### T7-DR-012 — Mô hình số lượng và trạng thái tồn

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G02`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Mô hình tồn kho có hai trục độc lập: (1) trạng thái vật lý/nghiệp vụ như đủ điều kiện bán, cách ly, hỏng, hết hạn hoặc chờ xử lý; và (2) trạng thái định giá như `VALUATION_PENDING` hoặc `VALUATION_CONFIRMED`. Trạng thái định giá không được ghi đè hoặc thay thế trạng thái vật lý.
- Tồn vật lý, lượng đủ điều kiện bán, lượng giữ và lượng khả dụng là các đại lượng khác nhau. Một lượng chỉ khả dụng khi đồng thời có trạng thái vật lý đủ điều kiện bán, đã được xác nhận định giá và không còn điều kiện chặn khác. Phase 1 không có trạng thái `IN_TRANSIT` vì chưa hỗ trợ chuyển kho.

<a id="t7-dr-013"></a>
### T7-DR-013 — Chính sách theo dõi sản phẩm

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G02`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Miền Sản phẩm sở hữu chính sách theo dõi `NONE` hoặc `LOT`; miền kho bắt buộc tuân thủ ở mọi operation. Nếu là `LOT`, cấu hình phụ xác định hạn dùng có bắt buộc hay không. Serial được giữ cho phiên bản tương lai.

**Yêu cầu nguyên tử**

- <a id="t7-dr-013-req-01"></a>`T7-DR-013#REQ-01` · `ACTIVE` — Nếu sản phẩm có chính sách `LOT`, thủ kho nhập hoặc quét mã lô do nhà sản xuất/đơn vị đóng gói công bố. Ngày sản xuất được ghi khi có; hạn dùng chỉ bắt buộc khi cấu hình `expiry_required = true`. Sản phẩm `NONE` không nhập lô hoặc hạn dùng.
- <a id="t7-dr-013-req-02"></a>`T7-DR-013#REQ-02` · `ACTIVE` — `expiry_required` chỉ có ý nghĩa khi tracking mode là `LOT`. Nếu mode là `NONE`, giao diện và hợp đồng tự vô hiệu hóa lô, ngày sản xuất và hạn dùng.

<a id="t7-dr-014"></a>
### T7-DR-014 — Chuyển đổi chính sách theo dõi

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G02`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Phase 1 chỉ cho thay đổi `NONE ↔ LOT` khi số lượng vật lý của sản phẩm bằng 0 và không còn reservation/operation mở. Nếu còn tồn, hệ thống chặn; batch chuyển đổi tồn hiện hữu được hoãn sang phiên bản sau.

<a id="t7-dr-015"></a>
### T7-DR-015 — Danh tính, nguồn và thuộc tính lô

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G02`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Một lô được định danh bởi tenant + sản phẩm + mã lô và dùng chung thuộc tính sản xuất/hạn trên mọi kho.

**Yêu cầu nguyên tử**

- <a id="t7-dr-015-req-01"></a>`T7-DR-015#REQ-01` · `ACTIVE` — Mã lô chính thức là mã do nhà sản xuất hoặc đơn vị đóng gói công bố trên hàng/bao bì. Đơn vị bán hàng ghi nhận hoặc quét mã đó; batch giao hàng của nhà cung cấp và batch nhận nội bộ không thay thế danh tính lô sản xuất.
- <a id="t7-dr-015-req-02"></a>`T7-DR-015#REQ-02` · `ACTIVE` — Nếu sản phẩm bắt buộc quản lý theo lô mà không có mã lô hợp lệ, thao tác nhận hàng phải bị chặn.
- <a id="t7-dr-015-req-03"></a>`T7-DR-015#REQ-03` · `OUT_OF_SCOPE` — Phase 1 không tự sinh lô nội bộ cho đóng gói lại, sản xuất hoặc chuyển đổi SKU.

<a id="t7-dr-016"></a>
### T7-DR-016 — Vòng đời hồ sơ lô

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G02`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Hồ sơ lô chính thức được tạo nguyên tử khi operation đầu tiên phát sinh tồn hoàn tất; dữ liệu nháp không tạo hồ sơ.

**Yêu cầu nguyên tử**

- <a id="t7-dr-016-req-01"></a>`T7-DR-016#REQ-01` · `ACTIVE` — Lần nhập sau khai khác thuộc tính lô bị chặn; phải sửa dữ liệu nhập hoặc sửa hồ sơ lô bằng operation có quyền, lý do và lịch sử.

<a id="t7-dr-017"></a>
### T7-DR-017 — Ngữ nghĩa và độ chính xác hạn dùng

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G02`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Giữ độ chính xác ngày gốc; tháng/năm quy về cuối tháng, ngày đầy đủ dùng đúng ngày; hết hạn sau khi kết thúc ngày nghiệp vụ.

<a id="t7-dr-018"></a>
### T7-DR-018 — Cấu hình cận hạn và hành động

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G02`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Cận hạn là chỉ báo dẫn xuất; tenant có ngưỡng mặc định, cho phép ghi đè theo sản phẩm để cảnh báo hoặc chặn bán; lượng bị chặn không khả dụng.

**Yêu cầu nguyên tử**

- <a id="t7-dr-018-req-01"></a>`T7-DR-018#REQ-01` · `ACTIVE` — Chính sách tồn theo sản phẩm bao gồm ngưỡng tồn/mức mục tiêu và cấu hình cận hạn. Cận hạn dùng mặc định tenant, có thể ghi đè theo sản phẩm bằng số ngày và hành động `WARN` hoặc `BLOCK_SALE`; không tạo hồ sơ cảnh báo có vòng đời.

<a id="t7-dr-019"></a>
### T7-DR-019 — Định hướng quản lý serial

- **Trạng thái:** `DEFERRED`
- **Nhóm nghiệp vụ:** `G02`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Định danh serial theo tenant + sản phẩm + mã serial là định hướng dài hạn, chưa triển khai trong Phase 1.

**Yêu cầu nguyên tử**

- <a id="t7-dr-019-req-01"></a>`T7-DR-019#REQ-01` · `DEFERRED` — Quy tắc mỗi serial đại diện một đơn vị và số lượng cơ sở phải khớp số serial được giữ cho phiên bản tương lai.
- <a id="t7-dr-019-req-02"></a>`T7-DR-019#REQ-02` · `DEFERRED` — Gắn serial khi lấy/đóng gói hoặc checkout được giữ cho phiên bản tương lai; Phase 1 không có UI, API hoặc dữ liệu serial.
- <a id="t7-dr-019-req-03"></a>`T7-DR-019#REQ-03` · `DEFERRED` — Tái nhập và nối tiếp lịch sử serial được giữ cho phiên bản tương lai.

<a id="g03"></a>
## 3.3 G03 — Nhận hàng và xác nhận giá trị

<a id="t7-dr-020"></a>
### T7-DR-020 — Hoàn tất nhận hàng vật lý

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G03`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Nhập mua tăng tồn vật lý khi thủ kho xác nhận lượng thực nhận và operation nhận hàng hoàn tất.

**Yêu cầu nguyên tử**

- <a id="t7-dr-020-req-01"></a>`T7-DR-020#REQ-01` · `ACTIVE` — Operation nhận hàng mua luôn kết thúc lượng đạt với trạng thái định giá `VALUATION_PENDING`, kể cả khi bằng chứng giá đi kèm. Trạng thái định giá này độc lập với trạng thái vật lý/nghiệp vụ của lượng hàng, vì vậy hàng cách ly hoặc hỏng vẫn có thể đồng thời chờ định giá. Xác nhận giá trực tiếp là command độc lập, có idempotency/transaction riêng; chỉ command đó ghi value movement và chuyển trạng thái định giá.

<a id="t7-dr-021"></a>
### T7-DR-021 — Xác nhận giá trị và giải phóng khả dụng

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G03`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** [`T7-DR-020`](#t7-dr-020)

**Nội dung quyết định**

- Hàng đã thuộc sở hữu tenant nhưng chưa chốt giá trực tiếp được ghi quantity movement vào tồn vật lý, mang trạng thái định giá `VALUATION_PENDING`, có khả dụng bằng 0 và tạo nghĩa vụ định giá; chưa ghi số tiền chính thức vào value ledger. Nghĩa vụ chờ định giá không làm mất hoặc thay đổi trạng thái vật lý/nghiệp vụ của lượng hàng.

**Yêu cầu nguyên tử**

- <a id="t7-dr-021-req-01"></a>`T7-DR-021#REQ-01` · `ACTIVE` — “Nhận hàng” và “cho phép bán” là hai mốc riêng: operation nhận làm tăng tồn vật lý; operation xác nhận giá ghi value movement và chuyển trạng thái định giá sang `VALUATION_CONFIRMED` trong cùng commit. Chỉ lượng đồng thời có trạng thái vật lý đủ điều kiện bán và không còn điều kiện chặn khác mới trở thành khả dụng; lượng cách ly, hỏng hoặc hết hạn vẫn giữ trạng thái vật lý tương ứng.
- <a id="t7-dr-021-req-02"></a>`T7-DR-021#REQ-02` · `ACTIVE` — Giá mua trực tiếp phải được xác nhận và ghi value movement trước khi hàng khả dụng; chi phí mua hàng phân bổ có thể bổ sung sau theo cơ chế valuation adjustment.
- <a id="t7-dr-021-req-03"></a>`T7-DR-021#REQ-03` · `ACTIVE` — Sau khi kế toán xác nhận giá trực tiếp, trạng thái định giá được xác nhận ngay, không cần một lớp phê duyệt riêng. Chỉ phần đồng thời đủ điều kiện bán mới trở thành khả dụng; phần không bán được tiếp tục giữ trạng thái vật lý hiện hành cho đến khi có operation đổi trạng thái hợp lệ.

<a id="t7-dr-022"></a>
### T7-DR-022 — Nhận từng phần và nhận vượt chứng từ

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G03`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Cho phép nhận từng phần; ghi nhận thiếu/thừa so với đơn mua; phần vượt ngưỡng phải được phê duyệt.

<a id="t7-dr-023"></a>
### T7-DR-023 — Phạm vi kiểm tra chất lượng khi nhận hàng

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G03`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Phase 1 không có bước kiểm tra chất lượng nhập hàng riêng; xác nhận của thủ kho là căn cứ nghiệp vụ nhận hàng.

<a id="t7-dr-024"></a>
### T7-DR-024 — Lượng đạt và lượng từ chối khi nhận hàng

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G03`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Khi giao hàng có lượng đạt và không đạt, Theme 7 chỉ ghi nhận lượng đạt; lượng bị từ chối không tạo tồn kho hoặc movement. Chứng từ nguồn chịu trách nhiệm lưu lượng từ chối và chênh lệch giao nhận để đối soát.

<a id="t7-dr-025"></a>
### T7-DR-025 — Bằng chứng xác nhận giá nhập trực tiếp

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G03`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Kế toán được xác nhận giá từ đơn mua/biên nhận và giá được nhà cung cấp xác nhận; hóa đơn có thể đến sau.

<a id="t7-dr-026"></a>
### T7-DR-026 — Khởi tạo giá vốn chính thức

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G03`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Với sản phẩm chưa có đơn giá chính thức, lần xác nhận giá nhập đầu tiên khởi tạo phiên bản đơn giá chính thức; cuối kỳ vẫn phải đối soát.

<a id="t7-dr-027"></a>
### T7-DR-027 — Phê duyệt bắt buộc cho nhập hàng nhanh

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G03`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** [`T7-DR-007`](#t7-dr-007), [`T7-DR-020`](#t7-dr-020), [`T7-DR-074`](#t7-dr-074), [`T7-DR-078`](#t7-dr-078), [`T7-DR-079`](#t7-dr-079), [`T7-DR-080`](#t7-dr-080), [`T7-DR-081`](#t7-dr-081), [`T7-DR-082`](#t7-dr-082)

**Nội dung quyết định**

- Mọi yêu cầu **nhập hàng nhanh** đủ dữ kiện gửi phải tự động đi theo `DRAFT` (Nháp) → `PENDING_APPROVAL` (Chờ duyệt) → `READY` (Sẵn sàng) của lifecycle Inventory Operation dùng chung; hệ thống không hỏi người dùng “có cần duyệt không” và không có nhánh đi thẳng `READY`. Với nhập hàng nhanh, ApprovalPolicy chỉ xác định điều kiện, tuyến và cấp duyệt; không được trả kết quả bỏ qua duyệt. Chỉ quyết định phê duyệt hợp lệ mới cho phép chuyển sang `READY` để tiếp tục ghi nhận hàng vào tồn vật lý. Việc bắt buộc duyệt không thay thế kiểm tra nguồn/quyền sở hữu, căn cứ giá–tỷ giá, quyền, phạm vi kho, maker–checker hoặc kiểm tra lại khi thực thi. Thiếu dữ kiện bắt buộc thì hồ sơ vẫn ở `DRAFT`. Sau khi đã gửi và payload bị khóa, nếu cần bổ sung thì hồ sơ hiện tại phải được hủy hoặc kết thúc theo lifecycle chung và tạo operation thay thế có liên kết; không sửa payload đã khóa và không tạo movement từ hồ sơ chưa được duyệt.

<a id="g04"></a>
## 3.4 G04 — Khả dụng, giữ hàng, lấy hàng và xuất

<a id="t7-dr-028"></a>
### T7-DR-028 — Giao dịch trực tuyến và chống xuất âm

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G04`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Mọi giao dịch Phase 1 là trực tuyến và luôn chặn xuất âm; Phase 1 không có ngoại lệ âm tồn.

<a id="t7-dr-029"></a>
### T7-DR-029 — Khả dụng, giữ hàng và Dữ liệu gốc về lượng giữ

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G04`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Khả dụng để cam kết bằng tồn vật lý đủ điều kiện bán trừ lượng đã giữ; hàng chờ giá, cách ly, hỏng, hết hạn hoặc bị chặn bán không thuộc lượng đủ điều kiện.

**Yêu cầu nguyên tử**

- <a id="t7-dr-029-req-01"></a>`T7-DR-029#REQ-01` · `ACTIVE` — Đơn sỉ/online giữ hàng khi đơn được xác nhận; POS kiểm tra và xuất ngay trong cùng checkout.
- <a id="t7-dr-029-req-02"></a>`T7-DR-029#REQ-02` · `ACTIVE` — Khi giữ chỉ gắn đến sản phẩm + kho; lô được chọn khi lấy/đóng gói hoặc xuất theo FEFO/FIFO.
- <a id="t7-dr-029-req-03"></a>`T7-DR-029#REQ-03` · `ACTIVE` — Lượng giữ có authority ở tenant + sản phẩm + kho, không ở lô/trạng thái. `TransactionalBalance` không sở hữu `reserved_quantity`; một `ReservationBucket` giao dịch được khóa/cập nhật cùng Reservation là nguồn tổng lượng giữ.

<a id="t7-dr-030"></a>
### T7-DR-030 — Lựa chọn hàng, phiên bản phân bổ và bàn giao

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G04`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Lấy hàng áp dụng FEFO cho hàng có hạn dùng và FIFO cho hàng không có hạn dùng; người đủ quyền được đổi lô nhưng phải để lại lý do và lịch sử. Kết quả lấy hàng được lưu thành `PickAllocation` có chung `allocation_set_id`, `allocation_version`, lô/lượng và dấu vết override; thao tác này chưa làm giảm tồn vật lý.
- Chỉ một phiên bản allocation được `ACTIVE` cho cùng fulfillment, reservation và sản phẩm. Sửa kết quả lấy hàng tạo phiên bản kế nhiệm; bàn giao phải khóa, kiểm tra lại và consume đúng phiên bản hiện hành đúng một lần trước khi ghi xuất.

**Yêu cầu nguyên tử**

- <a id="t7-dr-030-req-01"></a>`T7-DR-030#REQ-01` · `ACTIVE` — Với đơn sỉ/online, tồn vật lý giảm khi xác nhận bàn giao cho khách hoặc đơn vị vận chuyển; lấy và đóng gói chỉ thay đổi trạng thái của lượng đã giữ.

<a id="t7-dr-031"></a>
### T7-DR-031 — Thiếu hàng và tái phân bổ

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G04`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Khi xác nhận đơn không đủ khả dụng, đơn yêu cầu giao đủ bị chặn; đơn cho phép giao từng phần giữ lượng đang có và đưa phần thiếu vào chờ hàng.
- Nếu lượng đã giữ không còn đủ điều kiện bán, Theme 7 tự tìm lượng thay thế đủ điều kiện trong cùng kho; nếu vẫn thiếu thì giữ phần thiếu ở trạng thái chờ hàng và phát chỉ báo.

<a id="t7-dr-032"></a>
### T7-DR-032 — Giải phóng lượng giữ

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G04`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Lượng giữ được giải phóng khi xuất, đơn hủy/giảm lượng hoặc hết thời hạn giữ do chứng từ nguồn chỉ định.

<a id="t7-dr-033"></a>
### T7-DR-033 — Tính nguyên tử khi giữ và xuất hàng

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G04`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Kiểm tra và giữ/xuất phải nguyên tử; với giao dịch trực tuyến, transaction hợp lệ commit trước thắng, transaction sau bị từ chối.

<a id="t7-dr-034"></a>
### T7-DR-034 — Ranh giới POS offline

- **Trạng thái:** `DEFERRED`
- **Nhóm nghiệp vụ:** `G04`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Bán POS offline, quy tắc ưu tiên với reservation, định danh thiết bị, sequence, snapshot, dữ liệu theo dõi và các kết quả `OFFLINE_SALE_VARIANCE`/`OFFLINE_CONFLICT` đều được để cho giai đoạn tương lai; Phase 1 không có entity, API hoặc luồng đồng bộ offline.

<a id="g05"></a>
## 3.5 G05 — Kiểm kê và điều chỉnh tồn

<a id="t7-dr-035"></a>
### T7-DR-035 — Phạm vi và khóa kiểm kê

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G05`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Hỗ trợ kiểm kê toàn kho và kiểm kê từng phần theo sản phẩm, nhóm hoặc lô. Khi mở phiên, Theme 7 materialize tập balance key thuộc phạm vi cùng cut-off/ledger sequence; thay đổi master hoặc membership nhóm sau đó không tự đổi phạm vi phiên.

**Yêu cầu nguyên tử**

- <a id="t7-dr-035-req-01"></a>`T7-DR-035#REQ-01` · `ACTIVE` — Khi mở phiên kiểm kê, hệ thống lưu cả biểu thức phạm vi bất biến và tập balance key tại cut-off; mọi mutation trên key hiện có **hoặc key mới có thể phát sinh** nhưng thỏa biểu thức phạm vi đều bị chặn cho đến khi phiên hoàn tất hoặc bị hủy. Phase 1 không có bước chờ thiết bị POS offline đồng bộ hoặc xác nhận khóa.
- <a id="t7-dr-035-req-02"></a>`T7-DR-035#REQ-02` · `ACTIVE` — Khóa kiểm kê áp dụng theo biểu thức phạm vi đã chốt cho cả khóa số dư đã tồn tại và khóa số dư có thể phát sinh trong phạm vi đó.

<a id="t7-dr-036"></a>
### T7-DR-036 — Kiểm đếm mù và kiểm đếm lại

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G05`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Người kiểm đếm không thấy số hệ thống trước khi nộp; chỉ sau khi nộp mới hiển thị chênh lệch.

**Yêu cầu nguyên tử**

- <a id="t7-dr-036-req-01"></a>`T7-DR-036#REQ-01` · `ACTIVE` — Lần đếm đầu có chênh lệch phải kiểm lại phần chênh lệch trước khi trình xử lý.

<a id="t7-dr-037"></a>
### T7-DR-037 — Phê duyệt chênh lệch kiểm kê

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G05`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Chênh lệch duyệt theo ngưỡng số lượng/giá trị; người kiểm không được duyệt kết quả của mình.

<a id="t7-dr-038"></a>
### T7-DR-038 — Điều chỉnh tồn sau kiểm kê

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G05`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Khi kết quả được duyệt, tạo Inventory Adjustment bằng chênh lệch; khi hoàn tất, số dư bằng lượng kiểm kê được duyệt.

<a id="t7-dr-039"></a>
### T7-DR-039 — Hủy phiên kiểm kê

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G05`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Người có quyền được hủy phiên kèm lý do; không điều chỉnh tồn, giải phóng khóa và giữ toàn bộ lịch sử.

<a id="g06"></a>
## 3.6 G06 — Trả hàng, trạng thái, hết hạn và tiêu hủy

<a id="t7-dr-040"></a>
### T7-DR-040 — Ranh giới hủy bán và nhận hàng khách trả

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G06`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Đơn bán bị hủy sau bàn giao không tự cộng lại tồn; chỉ Return Operation dựa trên hàng thực nhận mới tăng tồn.

<a id="t7-dr-041"></a>
### T7-DR-041 — Ghi nhận, định giá và phân loại hàng khách trả

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G06`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Hàng khách trả tăng tồn vật lý ở trạng thái chờ phân loại, chưa tăng khả dụng.

**Yêu cầu nguyên tử**

- <a id="t7-dr-041-req-01"></a>`T7-DR-041#REQ-01` · `ACTIVE` — Sau phân loại, hàng đạt chuyển khả dụng; hàng hỏng/hết hạn giữ ở trạng thái không bán được.
- <a id="t7-dr-041-req-02"></a>`T7-DR-041#REQ-02` · `ACTIVE` — Khi operation **nhận hàng khách trả** hoàn tất và tăng vật lý ở `RETURN_PENDING`, hệ thống đồng thời ghi value movement mới ở kỳ mở hiện tại theo đơn giá đã đối soát của sản phẩm + kỳ xuất gốc; nếu kỳ gốc còn mở và chưa có giá đối soát thì dùng snapshot tại lần xuất. Phân loại sau đó chỉ đổi trạng thái; mọi dòng giữ liên kết kỳ gốc và không sửa hồi tố dòng xuất.
- <a id="t7-dr-041-req-03"></a>`T7-DR-041#REQ-03` · `ACTIVE` — Mốc ghi giá trị hàng khách trả là lúc nhận hàng thực tế vào `RETURN_PENDING`, cùng giao dịch với quantity movement, balance và outbox; không chờ phân loại và không ghi lần hai khi phân loại.

<a id="t7-dr-042"></a>
### T7-DR-042 — Vòng đời trả hàng nhà cung cấp

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G06`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Trả nhà cung cấp giảm tồn vật lý khi kho xác nhận bàn giao cho nhà cung cấp hoặc đơn vị vận chuyển.

**Yêu cầu nguyên tử**

- <a id="t7-dr-042-req-01"></a>`T7-DR-042#REQ-01` · `ACTIVE` — Hàng được chấp thuận trả nhà cung cấp nhưng chưa bàn giao chuyển sang trạng thái chờ trả và bị loại khỏi khả dụng.

<a id="t7-dr-043"></a>
### T7-DR-043 — Truy vết hàng khách trả về dòng xuất gốc

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G06`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Hàng khách trả liên kết đơn hàng/dòng hàng; Theme 7 truy đến đúng dòng xuất gốc.

<a id="t7-dr-044"></a>
### T7-DR-044 — Giới hạn lượng khách trả

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G06`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Tổng lượng đã nhận trả không được vượt lượng giao thực tế sau khi trừ tất cả lần trả trước; kiểm tra và cộng dồn phải khóa/commit nguyên tử trên dòng giao gốc để hai yêu cầu đồng thời không cùng vượt trần.

<a id="t7-dr-045"></a>
### T7-DR-045 — Đối chiếu lô khi khách trả

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G06`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Với sản phẩm theo lô, lô thực nhận khi khách trả phải được đối chiếu với các lô đã xuất; sai lô phải được xử lý bằng ngoại lệ có bằng chứng, không tự hợp thức hóa. Serial chưa thuộc Phase 1.

<a id="t7-dr-046"></a>
### T7-DR-046 — Hiệu lực hết hạn đối với khả dụng

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G06`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Hết hạn được xác định trực tiếp từ hạn dùng và ngày nghiệp vụ tenant; lượng hết hạn bị loại khỏi khả dụng ngay, không phụ thuộc việc một tác vụ nền đã chạy hay chưa. Nếu hệ thống materialize trạng thái `EXPIRED`, việc chuyển trạng thái phải qua operation chống trùng và không được sửa trực tiếp.

<a id="t7-dr-047"></a>
### T7-DR-047 — Số lượng và giá trị khi tiêu hủy

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G06`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Hàng hỏng/hết hạn chỉ giảm vật lý qua operation tiêu hủy/xử lý có lý do, duyệt theo ngưỡng và xác nhận đã xử lý.

**Yêu cầu nguyên tử**

- <a id="t7-dr-047-req-01"></a>`T7-DR-047#REQ-01` · `ACTIVE` — Tiêu hủy hoặc điều chỉnh giảm dùng số lượng bị loại bỏ nhân đơn giá chính thức có hiệu lực tại thời điểm hoàn tất; không suy ra giá riêng theo kho/lô vì giá trị có thẩm quyền chỉ ở tenant + sản phẩm.

<a id="t7-dr-048"></a>
### T7-DR-048 — Trả hàng đối với combo ảo

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G06`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Trả combo ghi đúng thành phần thực nhận và liên kết dòng xuất thành phần; không tạo tồn combo.

**Yêu cầu nguyên tử**

- <a id="t7-dr-048-req-01"></a>`T7-DR-048#REQ-01` · `ACTIVE` — Trả combo kiểm trần, lô và giá trị theo từng dòng thành phần đã xuất; chỉ thành phần thực nhận tăng tồn, không tạo tồn combo. Tất cả dòng của một yêu cầu nhận trả vẫn commit hoặc rollback cùng nhau.

<a id="g07"></a>
## 3.7 G07 — Giá trị tồn, giá vốn và chốt kỳ

<a id="t7-dr-049"></a>
### T7-DR-049 — Phương pháp giá vốn và hai phép tính song song

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G07`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Hệ thống tính song song bình quân gia quyền liên hoàn và bình quân gia quyền cuối kỳ; tenant chọn một phương pháp nguồn để công bố đơn giá chính thức cho kỳ.

**Yêu cầu nguyên tử**

- <a id="t7-dr-049-req-01"></a>`T7-DR-049#REQ-01` · `ACTIVE` — Hai chỉ số bình quân chạy trên cùng movement ledger bất biến; phương pháp không được chọn vẫn được giữ để đối chiếu và không tự ghi sổ.

<a id="t7-dr-050"></a>
### T7-DR-050 — Thẩm quyền và cấp độ của giá vốn chính thức

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G07`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Đơn giá tồn kho chính thức vừa là đơn giá quản trị vừa là đơn giá ghi sổ áp dụng cho xuất kho, được xác định tại cấp tenant + sản phẩm và giống nhau ở mọi kho.
- Tổng giá trị ghi sổ có thẩm quyền là tổng các value movement. Giữa hai lần đối soát, tổng giá trị chia số lượng có thể khác đơn giá chính thức đang áp dụng mà không tạo ra một phương pháp kế toán thứ hai.

**Yêu cầu nguyên tử**

- <a id="t7-dr-050-req-01"></a>`T7-DR-050#REQ-01` · `ACTIVE` — Giá trị ghi sổ có thẩm quyền chỉ tồn tại ở tenant + sản phẩm; giá trị chi tiết theo kho/trạng thái/lô nếu hiển thị phải gắn nhãn quản trị dẫn xuất.

<a id="t7-dr-051"></a>
### T7-DR-051 — Xử lý thuế GTGT trong giá vốn

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G07`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Thuế GTGT đầu vào được khấu trừ bị loại khỏi giá vốn; phần không được khấu trừ được tính vào giá vốn theo cấu hình thuế của giao dịch.

<a id="t7-dr-052"></a>
### T7-DR-052 — Công bố giá vốn và điều chỉnh giá trị

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G07`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Công bố đơn giá mới tạo version có thời điểm hiệu lực và value-only adjustment bằng đúng phần chênh lệch của tồn hiện hữu trong cùng batch đối soát; không ghi lại toàn bộ giá trị và không sửa chứng từ lịch sử.

**Yêu cầu nguyên tử**

- <a id="t7-dr-052-req-01"></a>`T7-DR-052#REQ-01` · `ACTIVE` — Việc công bố giá mới không sửa chứng từ gốc; mọi ảnh hưởng giá trị được ghi bằng valuation adjustment có liên kết.

<a id="t7-dr-053"></a>
### T7-DR-053 — Giá vốn bán hàng và đối soát cuối kỳ

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G07`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Khi bàn giao bán hàng, hệ thống ghi giá vốn ban đầu theo phiên bản giá vốn chính thức đang có hiệu lực. Cuối kỳ có thể ghi điều chỉnh giá vốn liên kết với lượng đã xuất nhưng không chạy lại, sửa hoặc thay thế đơn bán, dòng xuất hay giá vốn ban đầu; giá vốn dự kiến từ kịch bản không được dùng làm giá vốn kế toán.

<a id="t7-dr-054"></a>
### T7-DR-054 — Giá trị trả nhà cung cấp và bàn giao sang Kế toán

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G07`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** [`T7-DR-042`](#t7-dr-042)

**Nội dung quyết định**

- Theme 7 giảm tồn và giá trị kho theo đơn giá chính thức có hiệu lực, đồng thời gửi giá nhà cung cấp chấp thuận và phần chênh lệch cho Theme Kế toán. Theme Kế toán mới có thẩm quyền giảm công nợ và hạch toán chênh lệch.

<a id="t7-dr-055"></a>
### T7-DR-055 — Biến động giá trị trong kỳ

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G07`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Nhập trong kỳ ghi value movement tăng theo giá nhập thực tế; xuất ghi value movement giảm theo đơn giá chính thức hiện hành. Chênh lệch tạm thời giữa tổng giá trị ledger và đơn giá áp dụng được giữ nguyên để đối soát, không bị che bằng sửa số dư.

<a id="t7-dr-056"></a>
### T7-DR-056 — Batch chốt giá vốn cuối kỳ

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G07`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Chốt cuối kỳ tạo một batch liên kết gồm: điều chỉnh chênh lệch giá vốn của lượng đã xuất, điều chỉnh giá trị tồn cuối kỳ và phiên bản giá vốn chính thức mới. Mỗi thành phần chỉ ghi đúng phần chênh lệch, có liên kết đến nguồn và không sửa đơn bán, operation hoặc movement gốc.

<a id="t7-dr-057"></a>
### T7-DR-057 — Cập nhật giá vốn ngoài kỳ

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G07`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Cập nhật giá đột xuất giữa kỳ đối soát đến cut-off, ghi operation điều chỉnh; giá mới áp dụng cho giao dịch sau cut-off.

<a id="t7-dr-058"></a>
### T7-DR-058 — Chi phí mua bổ sung, chống trùng và tính lại

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G07`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Ghi chi phí mua bổ sung là command độc lập với công bố giá vốn và tạo adjustment có nguồn, phiên bản, phương pháp phân bổ. Chống trùng theo tenant + ID/phiên bản cấu phần nguồn + dòng phân bổ.
- Khi ghi thành công, phạm vi sản phẩm + kỳ được đánh dấu cần tính lại. Kỳ còn mở tạo lần tính kế nhiệm; kỳ đã khóa ghi adjustment ở kỳ mở kế tiếp và giữ liên kết với kỳ gốc.

<a id="t7-dr-059"></a>
### T7-DR-059 — Điều kiện chặn chốt giá vốn

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G07`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Chặn chốt giá cho phạm vi sản phẩm + kỳ khi còn operation `UNKNOWN`, hàng nhập chưa xác nhận giá trực tiếp, kiểm kê/điều chỉnh/correction chain chưa hoàn tất hoặc hồ sơ đối soát có thể làm sai số lượng hay giá trị của kỳ. Không có blocker POS offline trong Phase 1.

<a id="t7-dr-060"></a>
### T7-DR-060 — Vòng đời tính, rà soát và công bố giá vốn

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G07`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Hệ thống tính bản nháp; kế toán có quyền xem, kiểm tra và công bố, không cần phê duyệt lớp hai.

**Yêu cầu nguyên tử**

- <a id="t7-dr-060-req-01"></a>`T7-DR-060#REQ-01` · `ACTIVE` — Phase 1 không cho hủy một lần tính giá vốn đã tạo. Run giữ bằng chứng và kết thúc ở `BLOCKED`, `READY_FOR_REVIEW` hoặc `PUBLISHED`; tính lại tạo run mới có liên kết kế nhiệm, không sửa hoặc tái dùng run cũ.

<a id="t7-dr-061"></a>
### T7-DR-061 — Mô hình thành phần giá trị đầu vào

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G07`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Chiết khấu mua, hàng khuyến mại, chi phí mua và true-up được chuẩn hóa thành thành phần giá trị có nguồn, phương pháp phân bổ và kỳ hiệu lực; không thay đổi số lượng nếu không có movement vật lý.

<a id="t7-dr-062"></a>
### T7-DR-062 — Đồng tiền sổ tồn và xử lý tỷ giá

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G07`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Sổ tồn và đơn giá chính thức dùng VND; tỷ giá nguồn do Theme Kế toán/chứng từ cung cấp; chênh lệch tỷ giá thanh toán không làm thay đổi giá trị tồn đã ghi.

<a id="t7-dr-063"></a>
### T7-DR-063 — Định giá chênh lệch thừa thiếu và hàng biếu tặng

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G07`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Thiếu tồn dùng căn cứ giảm giá trị tại [`T7-DR-047`](#t7-dr-047). Thừa và hàng biếu/tặng chỉ tăng qua operation có nguồn, lý do và căn cứ giá được Theme Kế toán/nguồn có thẩm quyền cung cấp; thiếu căn cứ giá thì áp dụng [`T7-DR-080`](#t7-dr-080) và giữ operation ở Nháp. Không tự hợp thức hóa bằng sửa số dư.

<a id="g08"></a>
## 3.8 G08 — Sửa sai và hoàn nguyên

<a id="t7-dr-064"></a>
### T7-DR-064 — Tính bất biến và chuỗi sửa sai

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G08`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Operation hoàn tất không được sửa; phải tạo reversal liên kết bản gốc, sau đó tạo operation đúng nếu cần.

**Yêu cầu nguyên tử**

- <a id="t7-dr-064-req-01"></a>`T7-DR-064#REQ-01` · `ACTIVE` — Operation gốc, reversal và operation thay thế giữ ID/ngày riêng nhưng cùng thuộc một correction chain có thể truy vết.

<a id="t7-dr-065"></a>
### T7-DR-065 — Điều kiện và tính duy nhất của hoàn nguyên

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G08`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** [`T7-DR-064`](#t7-dr-064), [`T7-DR-071`](#t7-dr-071)

**Nội dung quyết định**

- Chặn reversal nếu làm tồn âm hoặc còn operation phụ thuộc chưa được trung hòa.

**Yêu cầu nguyên tử**

- <a id="t7-dr-065-req-01"></a>`T7-DR-065#REQ-01` · `ACTIVE` — Mỗi operation gốc chỉ có một reversal có hiệu lực; sửa tiếp bằng đảo reversal hoặc chuỗi correction có liên kết.
- <a id="t7-dr-065-req-02"></a>`T7-DR-065#REQ-02` · `ACTIVE` — Operation `UNKNOWN` không được đảo hoặc thay thế; phải được đối soát về Hoàn tất hoặc Từ chối thực thi trước.

<a id="t7-dr-066"></a>
### T7-DR-066 — Sửa sai tài chính qua kỳ khóa

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G08`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** [`T7-DR-065`](#t7-dr-065)

**Nội dung quyết định**

- Sai sót thuộc kỳ khóa được sửa trong kỳ mở hiện tại, giữ ngày nghiệp vụ gốc và liên kết operation sai.

**Yêu cầu nguyên tử**

- <a id="t7-dr-066-req-01"></a>`T7-DR-066#REQ-01` · `ACTIVE` — Correction lưu cả ngày nghiệp vụ gốc và ngày ghi nhận/hoàn tất thực tế.
- <a id="t7-dr-066-req-02"></a>`T7-DR-066#REQ-02` · `ACTIVE` — Nếu operation gốc đã nằm trong đối soát giá, reversal phải tạo cả ảnh hưởng số lượng/giá trị và valuation adjustment liên kết; không sửa phiên chốt cũ.

<a id="g09"></a>
## 3.9 G09 — Số dư đầu kỳ và Chuyển đổi chính thức

<a id="t7-dr-067"></a>
### T7-DR-067 — Hợp đồng dữ liệu số dư đầu kỳ

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G09`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Số dư đầu kỳ nhập theo sản phẩm + kho + trạng thái; bổ sung mã lô và hạn dùng khi chính sách `LOT` yêu cầu. Phase 1 không nhập serial.

**Yêu cầu nguyên tử**

- <a id="t7-dr-067-req-01"></a>`T7-DR-067#REQ-01` · `ACTIVE` — Nhập số lượng chi tiết theo kho nhưng tổng giá trị ghi sổ có thẩm quyền theo tenant + sản phẩm; hệ thống suy ra đơn giá chính thức khởi tạo. Giá trị theo kho nếu có trong file nguồn chỉ là số kiểm soát dẫn xuất.
- <a id="t7-dr-067-req-02"></a>`T7-DR-067#REQ-02` · `ACTIVE` — Sản phẩm `LOT` không được xác nhận dòng đầu kỳ khi thiếu mã lô; nếu `expiry_required = true` thì đồng thời không được thiếu hạn dùng.
- <a id="t7-dr-067-req-03"></a>`T7-DR-067#REQ-03` · `ACTIVE` — Dòng đầu kỳ phải khớp sản phẩm, kho và đơn vị đã tồn tại; Theme 7 không tự tạo master data.
- <a id="t7-dr-067-req-04"></a>`T7-DR-067#REQ-04` · `ACTIVE` — Chỉ lượng có trạng thái bán được và đủ dữ liệu bắt buộc tăng khả dụng; trạng thái khác chỉ tăng vật lý.

<a id="t7-dr-068"></a>
### T7-DR-068 — Chuẩn bị, phê duyệt và commit số dư đầu kỳ

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G09`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** [`T7-DR-067`](#t7-dr-067)

**Nội dung quyết định**

- Batch đầu kỳ chỉ tạo tồn chính thức sau kiểm tra và xác nhận; toàn batch commit nguyên tử.

**Yêu cầu nguyên tử**

- <a id="t7-dr-068-req-01"></a>`T7-DR-068#REQ-01` · `ACTIVE` — Sau khi batch đầu kỳ xác nhận, không được nhập batch đầu kỳ thứ hai; sửa bằng correction/reversal hoặc adjustment.
- <a id="t7-dr-068-req-02"></a>`T7-DR-068#REQ-02` · `ACTIVE` — Người lập không tự xác nhận batch; người có quyền độc lập kiểm tra và xác nhận.
- <a id="t7-dr-068-req-03"></a>`T7-DR-068#REQ-03` · `ACTIVE` — Nạp file, chuẩn hóa, kiểm tra dòng/tổng kiểm soát và gửi duyệt tạo một batch chuẩn bị có version; chỉ batch đã duyệt mới được commit. Chuẩn bị/duyệt không ghi ledger hoặc mở khóa Chuyển đổi chính thức.

<a id="t7-dr-069"></a>
### T7-DR-069 — Chuyển đổi chính thức, đối soát và kích hoạt tồn kho

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G09`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** [`T7-DR-068`](#t7-dr-068)

**Nội dung quyết định**

- Chốt một thời điểm Chuyển đổi chính thức; không cho operation thường phát sinh trước khi batch đầu kỳ hoàn tất.

**Yêu cầu nguyên tử**

- <a id="t7-dr-069-req-01"></a>`T7-DR-069#REQ-01` · `ACTIVE` — Trước mở khóa phải đối soát số lượng theo từng kho và tổng giá trị có thẩm quyền theo tenant + sản phẩm với số kiểm soát đã duyệt; giá trị theo kho nếu báo cáo chỉ được gắn nhãn dẫn xuất. Sau đó tạo báo cáo migration bất biến.
- <a id="t7-dr-069-req-02"></a>`T7-DR-069#REQ-02` · `ACTIVE` — Trước khi opening batch đầu tiên `COMPLETED` và đối soát đạt, tồn kho ở trạng thái `PREPARING`; chỉ command opening/duyệt/đối soát được phép, mutation thường bị chặn. Commit opening cùng báo cáo kiểm soát chuyển gate sang `ACTIVE` nguyên tử.

<a id="g10"></a>
## 3.10 G10 — Inventory Operation, tích hợp, chống trùng và kết quả chưa xác định

<a id="t7-dr-070"></a>
### T7-DR-070 — Mốc chính thức thay đổi số lượng

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G10`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Số lượng chính thức chỉ thay đổi khi Inventory Operation hoàn tất; POS trực tuyến có thể hoàn tất xuất kho trong cùng transaction checkout.

<a id="t7-dr-071"></a>
### T7-DR-071 — Kết quả UNKNOWN và phân giải an toàn

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G10`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Timeout không được mặc định là thất bại: operation chuyển `UNKNOWN` và chỉ được phân giải bằng bằng chứng kết quả cuối có thẩm quyền, gắn với cùng operation ID và command identity. Bằng chứng `COMMITTED` đưa operation về Hoàn tất với đúng effects đã commit; bằng chứng xác định `NOT_COMMITTED` hoặc `EXECUTION_REJECTED` đưa operation về Từ chối thực thi với owner effect `NONE`. Từ chối duyệt không phải bằng chứng phân giải một operation đang `UNKNOWN`. Khi bằng chứng chưa đủ, operation phải tiếp tục ở `UNKNOWN`.
- Hệ thống chỉ truy vấn hoặc tiếp tục bằng cùng định danh; không cho sửa tay kết quả, không retry bằng định danh mới khi còn `UNKNOWN` và không được ghi số lượng hoặc giá trị lần hai.

<a id="t7-dr-072"></a>
### T7-DR-072 — Danh tính operation/command và chống trùng

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G10`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- `operation_request_id` định danh yêu cầu nguồn tạo operation; `operation_id` định danh hồ sơ; mỗi mutation có `Idempotency-Key` và `CommandReceipt`. Cùng định danh và cùng payload trả cùng kết quả; cùng định danh nhưng payload khác bị chặn.
- Cập nhật bản nháp dùng optimistic version; payload hash chỉ được khóa khi gửi. Kết quả `UNKNOWN` phải được truy vấn hoặc tiếp tục bằng đúng operation ID và command key, không dùng một trường `request_id` nhập nhằng hoặc tạo định danh mới.

<a id="t7-dr-073"></a>
### T7-DR-073 — Tính nguyên tử và commit finality

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G10`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Khi hoàn tất, trạng thái operation, movement ledger, số dư, trạng thái tồn, hồ sơ lô, giá trị liên quan và outbox event phải commit trong cùng transaction; lỗi thì rollback toàn bộ.

**Yêu cầu nguyên tử**

- <a id="t7-dr-073-req-01"></a>`T7-DR-073#REQ-01` · `ACTIVE` — Operation nhiều dòng là all-or-nothing; muốn xử lý một phần phải tách operation riêng.

<a id="t7-dr-074"></a>
### T7-DR-074 — Vòng đời Inventory Operation

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G10`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Trạng thái operation thống nhất: Nháp → Chờ duyệt → Sẵn sàng → Đang xử lý → Hoàn tất; các nhánh gồm Từ chối duyệt, Từ chối thực thi, `UNKNOWN` và Đã hủy. Reason code giải thích kết quả nhưng không tạo thêm trạng thái operation.

**Yêu cầu nguyên tử**

- <a id="t7-dr-074-req-01"></a>`T7-DR-074#REQ-01` · `ACTIVE` — Chỉ sửa khi Nháp; từ gửi duyệt hoặc Sẵn sàng, payload bị khóa. Thay đổi bằng hủy và operation thay thế có liên kết.
- <a id="t7-dr-074-req-02"></a>`T7-DR-074#REQ-02` · `ACTIVE` — Được hủy ở Nháp, Chờ duyệt, Sẵn sàng; Đang xử lý/`UNKNOWN` phải đối soát; Hoàn tất phải reversal.
- <a id="t7-dr-074-req-03"></a>`T7-DR-074#REQ-03` · `ACTIVE` — Từ chối thực thi là kết quả cuối, không ảnh hưởng tồn; retry nghiệp vụ dùng request/operation ID mới và liên kết bản bị từ chối.

<a id="t7-dr-075"></a>
### T7-DR-075 — Thứ tự và phiên bản yêu cầu nguồn

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G10`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Yêu cầu mang phiên bản nguồn tăng dần; từ chối phiên bản cũ hơn. Thay đổi bằng hủy/thay thế có liên kết.

<a id="t7-dr-076"></a>
### T7-DR-076 — Giao sự kiện đáng tin cậy

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G10`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Commit thành công không phụ thuộc việc giao event; outbox gửi lại cùng event ID đến khi nhận xác nhận, bên nhận chống trùng; không tự đảo tồn vì lỗi giao event.

<a id="t7-dr-077"></a>
### T7-DR-077 — Quản lý phiên bản hợp đồng liên miền

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G10`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- API/event có phiên bản; thay đổi additive tương thích ngược, breaking change dùng phiên bản mới và thời gian coexistence.

<a id="g11"></a>
## 3.11 G11 — Quyền, phê duyệt và bảo vệ dữ liệu

<a id="t7-dr-078"></a>
### T7-DR-078 — Chính sách duyệt theo operation và rủi ro

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G11`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Theme 7 sở hữu chính sách duyệt theo loại operation, lý do và mức rủi ro; tenant cấu hình ngưỡng/cấp và hệ thống chụp phiên bản chính sách tại thời điểm gửi. Hoàn nguyên là một loại operation thuộc chính sách này và phải tuân thủ maker–checker.

<a id="t7-dr-079"></a>
### T7-DR-079 — Mô hình phân quyền kho

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G11`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Người dùng cần đồng thời quyền chức năng và phạm vi kho; quyền xem, tạo, xác nhận, duyệt tách riêng.

<a id="t7-dr-080"></a>
### T7-DR-080 — Căn cứ và cách tính rủi ro phê duyệt

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G11`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Giá trị rủi ro của operation nhiều dòng bằng tổng trị tuyệt đối từng dòng sau khi chuẩn hóa sang VND; không bù trừ dòng tăng với dòng giảm. Mỗi dòng ưu tiên đơn giá chính thức tại lúc gửi, nếu chưa có thì dùng giá nguồn có phiên bản và snapshot tỷ giá nguồn.
- Snapshot phải giữ căn cứ giá/tỷ giá từng dòng, tổng rủi ro và cấp duyệt suy ra. Thiếu căn cứ ở bất kỳ dòng nào thì operation ở Nháp và bị chặn gửi duyệt; không dùng `UNKNOWN` hoặc tự đẩy lên cấp cao nhất.

<a id="t7-dr-081"></a>
### T7-DR-081 — Eligibility và maker-checker của người duyệt

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G11`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Tại lúc duyệt, người duyệt phải còn quyền, phạm vi kho và cấp phù hợp, đồng thời không phải người lập.

**Yêu cầu nguyên tử**

- <a id="t7-dr-081-req-01"></a>`T7-DR-081#REQ-01` · `ACTIVE` — Tuy chính sách có nhiều cấp ngưỡng rủi ro, mỗi operation chỉ cần một quyết định của người đáp ứng cấp cao nhất được suy ra cho operation đó; không có chuỗi duyệt tuần tự qua các cấp thấp hơn.
- <a id="t7-dr-081-req-02"></a>`T7-DR-081#REQ-02` · `ACTIVE` — Khi gửi phải có ít nhất một người đủ điều kiện; thiếu thì chặn vì lỗi cấu hình. Mất quyền sau đó không hạ cấp/bỏ qua duyệt.

<a id="t7-dr-082"></a>
### T7-DR-082 — Finality của quyết định phê duyệt

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G11`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Từ chối duyệt yêu cầu lý do, là trạng thái cuối và không ảnh hưởng tồn; muốn sửa phải tạo operation mới có liên kết.

**Yêu cầu nguyên tử**

- <a id="t7-dr-082-req-01"></a>`T7-DR-082#REQ-01` · `ACTIVE` — Phê duyệt chỉ cho phép thực thi, không giữ hay thay đổi tồn; khi xử lý phải kiểm tra lại mọi điều kiện hiện hành.
- <a id="t7-dr-082-req-02"></a>`T7-DR-082#REQ-02` · `ACTIVE` — Hai quyết định đồng thời: quyết định hợp lệ commit đầu tiên thắng nguyên tử; yêu cầu sau không ghi đè.

<a id="t7-dr-083"></a>
### T7-DR-083 — Phân loại và bảo vệ dữ liệu tài chính

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G11`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Quyền xem tồn không mặc nhiên cho xem giá. Giá mua/nhà cung cấp, căn cứ rủi ro, giá vốn ban đầu/chính thức/tham chiếu, value movement/adjustment và margin là `FINANCIAL_RESTRICTED`.
- UI, API và export phải che dữ liệu ở phía máy chủ khi thiếu quyền; log không ghi giá trị rõ và event chỉ được giao theo hợp đồng consumer đã được cấp phép.

<a id="g12"></a>
## 3.12 G12 — Sổ nghiệp vụ, báo cáo, đối soát, cảnh báo và phục hồi

<a id="t7-dr-084"></a>
### T7-DR-084 — Ledger là Dữ liệu gốc và projection có thể dựng lại

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G12`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Movement ledger bất biến là Dữ liệu gốc; số dư là projection. Lệch thì khóa phạm vi và dựng lại, không sửa tay.

**Yêu cầu nguyên tử**

- <a id="t7-dr-084-req-01"></a>`T7-DR-084#REQ-01` · `ACTIVE` — Kiểm tra khả dụng/giữ/xuất dùng số dư giao dịch cập nhật nguyên tử; projection bất đồng bộ chỉ dùng tra cứu và phải hiển thị thời điểm dữ liệu.
- <a id="t7-dr-084-req-02"></a>`T7-DR-084#REQ-02` · `ACTIVE` — Sổ nghiệp vụ, số dư giao dịch và outbox đã commit không được mất; dữ liệu dẫn xuất phải có thể dựng lại từ sổ nghiệp vụ.

<a id="t7-dr-085"></a>
### T7-DR-085 — Nhất quán thời gian của báo cáo

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G12`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Báo cáo quá khứ có hai cách nhìn: theo ngày ghi nhận để bảo toàn kỳ khóa và theo ngày nghiệp vụ gốc để phân tích vận hành.

**Yêu cầu nguyên tử**

- <a id="t7-dr-085-req-01"></a>`T7-DR-085#REQ-01` · `ACTIVE` — Mỗi báo cáo/export dùng một cut-off/ledger sequence nhất quán cho toàn bộ dòng và ghi rõ thời điểm, bộ lọc, múi giờ và cách nhìn.

<a id="t7-dr-086"></a>
### T7-DR-086 — Đối soát chứng từ nguồn với operation

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G12`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Đối chiếu loại nguồn + chứng từ/dòng + phiên bản + request ID với operation/kết quả; sai lệch tạo hồ sơ/cảnh báo, không tự sửa tồn.

<a id="t7-dr-087"></a>
### T7-DR-087 — Thẻ kho và dấu vết movement

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G12`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Thẻ kho thể hiện tồn đầu, movement tăng/giảm, tồn cuối và truy đến operation, chứng từ, ngày, người, kho, trạng thái và lô khi áp dụng.

<a id="t7-dr-088"></a>
### T7-DR-088 — Chỉ báo dẫn xuất và hồ sơ xử lý

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G12`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Phase 1 hiển thị chỉ báo dẫn xuất và hàng công việc cho `UNKNOWN`, chờ giá, cận/hết hạn, chênh lệch kiểm kê/đối soát và tồn thấp. Chỉ báo dẫn xuất không có thao tác đóng tay và tự biến mất khi điều kiện nguồn không còn.
- Sai lệch cần xử lý dùng Hồ sơ đối soát có vòng đời riêng và chỉ được đóng bằng bằng chứng xử lý hợp lệ; tồn thấp không tự tạo hồ sơ có vòng đời.

**Yêu cầu nguyên tử**

- <a id="t7-dr-088-req-01"></a>`T7-DR-088#REQ-01` · `ACTIVE` — Phase 1 không có một vòng đời cảnh báo dùng chung; hồ sơ rủi ro sử dụng vòng đời của Inventory Operation hoặc Hồ sơ đối soát tương ứng.
- <a id="t7-dr-088-req-02"></a>`T7-DR-088#REQ-02` · `DEFERRED` — Vòng đời cảnh báo dùng chung với người phụ trách, mức độ và cam kết xử lý được để cho giai đoạn tương lai.

<a id="t7-dr-089"></a>
### T7-DR-089 — Phạm vi routing và kênh thông báo Phase 1

- **Trạng thái:** `DEFERRED`
- **Nhóm nghiệp vụ:** `G12`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Email, push và các kênh thông báo ngoài ứng dụng được để cho giai đoạn tương lai.

**Yêu cầu nguyên tử**

- <a id="t7-dr-089-req-01"></a>`T7-DR-089#REQ-01` · `DEFERRED` — Phân phối thông báo theo người phụ trách và phạm vi kho được để cho giai đoạn tương lai.

<a id="t7-dr-090"></a>
### T7-DR-090 — Phục hồi an toàn sau sự cố

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G12`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** [`T7-DR-071`](#t7-dr-071)

**Nội dung quyết định**

- Sau sự cố, chỉ mở mutation khi đã đối soát `UNKNOWN`, xác minh ledger và kiểm tra projection; giao diện hiển thị trạng thái phục hồi/thời điểm dữ liệu.

**Yêu cầu nguyên tử**

- <a id="t7-dr-090-req-01"></a>`T7-DR-090#REQ-01` · `ACTIVE` — Mỗi kết quả thành công, lỗi, conflict, lock hoặc `UNKNOWN` phải cho biết điều gì xảy ra, owner effect là `NONE`, `COMMITTED` hay `UNKNOWN`, và các hành động an toàn tiếp theo. Recovery Guidance là metadata trình bày dẫn xuất từ result/error catalog; chỉ trỏ tới query/command đã có, không tạo business state/finality mới và không cho retry `UNKNOWN` bằng identity mới.

<a id="t7-dr-091"></a>
### T7-DR-091 — Lưu giữ dữ liệu tồn kho và audit

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G12`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Operation, movement và audit không xóa riêng lẻ; mặc định giữ tối thiểu 10 năm, archive vẫn truy vấn/xuất/dựng projection được.

<a id="g13"></a>
## 3.13 G13 — Dữ liệu chủ, combo, bổ sung hàng và nghiệp vụ đặc biệt

<a id="t7-dr-092"></a>
### T7-DR-092 — Hàng demo thuộc sở hữu tenant

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G13`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Hàng thuộc tenant chuyển sang `DEMO` bằng operation; vẫn thuộc vật lý và giá trị ghi sổ nhưng không khả dụng; được chuyển lại hoặc xử lý tiếp bằng operation.

<a id="t7-dr-093"></a>
### T7-DR-093 — Chuyển đổi giữa SKU ngoài Phase 1

- **Trạng thái:** `OUT_OF_SCOPE`
- **Nhóm nghiệp vụ:** `G13`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Phase 1 không hỗ trợ chuyển đổi giữa SKU/sản phẩm và không cho mô phỏng bằng hai adjustment độc lập.

<a id="t7-dr-094"></a>
### T7-DR-094 — Mô hình tồn của combo ảo

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G13`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Combo không có số dư riêng; Theme Sản phẩm/Bán hàng sở hữu định nghĩa, Theme 7 giữ/xuất nguyên tử các thành phần.

**Yêu cầu nguyên tử**

- <a id="t7-dr-094-req-01"></a>`T7-DR-094#REQ-01` · `ACTIVE` — Khi xác nhận đơn, nguồn gửi phiên bản và snapshot thành phần; thay đổi cấu hình sau đó không ảnh hưởng đơn đã xác nhận.
- <a id="t7-dr-094-req-02"></a>`T7-DR-094#REQ-02` · `ACTIVE` — Chỉ giữ/xuất số nguyên combo có đủ mọi thành phần; không xuất combo thiếu.

<a id="t7-dr-095"></a>
### T7-DR-095 — Phạm vi bổ sung hàng Phase 1

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G13`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Phase 1 chỉ hiển thị trạng thái sắp hết/hết hàng và số lượng gợi ý bổ sung; không sở hữu quy trình đề xuất mua hoặc lập đơn mua.

**Yêu cầu nguyên tử**

- <a id="t7-dr-095-req-01"></a>`T7-DR-095#REQ-01` · `ACTIVE` — Phase 1 chỉ dùng lượng khả dụng hiện hành làm căn cứ cho chỉ báo và lượng gợi ý bổ sung.
- <a id="t7-dr-095-req-02"></a>`T7-DR-095#REQ-02` · `DEFERRED` — Tồn dự kiến theo hàng sắp về, nhu cầu tương lai, tốc độ bán và khoảng dự báo được để cho giai đoạn tương lai.
- <a id="t7-dr-095-req-03"></a>`T7-DR-095#REQ-03` · `OUT_OF_SCOPE` — Phase 1 không có vòng đời đề xuất bổ sung, không liên kết proposal–đơn mua và không có thao tác tiếp nhận/đóng đề xuất.

<a id="t7-dr-096"></a>
### T7-DR-096 — Chính sách tồn và gợi ý bổ sung

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G13`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Cấu hình tồn gồm `low_stock_threshold` và `target_stock_level` tại cấp sản phẩm + kho. Phase 1 đặt trải nghiệm trong cấu hình sản phẩm và tự áp dụng kho mặc định; `target_stock_level ≥ low_stock_threshold ≥ 0`.
- Thay đổi cấu hình là mutation riêng; việc xem chỉ báo và lượng gợi ý vẫn là query dẫn xuất.

**Yêu cầu nguyên tử**

- <a id="t7-dr-096-req-01"></a>`T7-DR-096#REQ-01` · `ACTIVE` — Khi tồn khả dụng nhỏ hơn hoặc bằng ngưỡng cảnh báo, hệ thống hiển thị lượng gợi ý; kết quả là dữ liệu dẫn xuất, không tạo proposal có identity hoặc lifecycle.
- <a id="t7-dr-096-req-02"></a>`T7-DR-096#REQ-02` · `ACTIVE` — Lượng gợi ý bằng `max(0, target_stock_level − available_quantity)` theo đơn vị cơ sở. Phase 1 chưa xét MOQ, bội số đóng gói, lead time hoặc quy cách mua.

<a id="t7-dr-097"></a>
### T7-DR-097 — Vòng đời sản phẩm và guard mutation

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G13`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- `DISCONTINUED` chặn yêu cầu mua và nhận mua mới trừ khi nguồn cung cấp xác nhận tiếp tục có phiên bản; vẫn cho bán hết, nhận khách trả, trả nhà cung cấp, sửa sai, điều chỉnh và tiêu hủy.
- Chỉ chuyển sang `ARCHIVED` khi không còn tồn, lượng giữ hoặc operation mở; `ARCHIVED` không nhận thay đổi nghiệp vụ.

<a id="g14"></a>
## 3.14 G14 — Chiết khấu mua hàng, định giá bán và lợi nhuận

<a id="t7-dr-098"></a>
### T7-DR-098 — Ranh giới giá vốn và định giá bán

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G14`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Giá vốn chính thức mới chỉ là một nguồn có thể dùng cho **giá vốn tham chiếu định giá**. Quyền lựa chọn nguồn tham chiếu, tính giá sàn/giá niêm yết và công bố giá bán thuộc miền định giá bán; công bố giá vốn không tự thay đổi giá bán.

**Yêu cầu nguyên tử**

- <a id="t7-dr-098-req-01"></a>`T7-DR-098#REQ-01` · `ACTIVE` — Kịch bản chiết khấu và giá vốn dự kiến không làm thay đổi tồn kho, sổ giá trị, công nợ, giá vốn chính thức hoặc báo cáo kế toán. Chỉ dữ liệu ưu đãi đã phát sinh và có chứng từ hợp lệ mới được đưa vào cấu phần định giá tồn kho.

<a id="t7-dr-099"></a>
### T7-DR-099 — Kịch bản và quyền lợi dự kiến

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G14`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Cho phép người có quyền lập kịch bản chiết khấu mua hàng theo kỳ trước khi có đơn mua hoặc hàng về. Kịch bản được tính riêng theo sản phẩm và có thể mô tả ưu đãi theo tỷ lệ, số tiền hoặc hàng tặng quy đổi.

<a id="t7-dr-100"></a>
### T7-DR-100 — Dự thảo, nguồn gốc và công bố giá bán

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G14`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Kết quả kịch bản có thể tạo dự thảo định giá bán. Người có thẩm quyền định giá được công bố giá bán mới ngay nếu chấp nhận rủi ro dự kiến; thao tác này không được mô tả là “áp dụng giá vốn mới”.

**Yêu cầu nguyên tử**

- <a id="t7-dr-100-req-01"></a>`T7-DR-100#REQ-01` · `ACTIVE` — Chuỗi định giá bán được hiểu là: **giá vốn tham chiếu định giá** → áp chính sách lợi nhuận → **giá sàn** và **giá niêm yết** → áp khuyến mại và bối cảnh giao dịch → **giá bán giao dịch**. Giá sàn có thể cảnh báo hoặc chặn giảm sâu theo chính sách của miền định giá bán.
- <a id="t7-dr-100-req-02"></a>`T7-DR-100#REQ-02` · `ACTIVE` — Mỗi phiên bản giá vốn tham chiếu định giá phải lưu nguồn: `OFFICIAL_COST` cùng phiên bản giá vốn chính thức, hoặc `PROJECTED_PURCHASE_DISCOUNT` cùng phiên bản kịch bản. Không được ghi một con số tham chiếu mà mất nguồn, người công bố và thời điểm hiệu lực.
- <a id="t7-dr-100-req-03"></a>`T7-DR-100#REQ-03` · `ACTIVE` — Cập nhật giá vốn tham chiếu chỉ tạo dự thảo giá sàn/giá niêm yết hoặc gói thay đổi. Giá bán đang hiệu lực chỉ thay đổi sau một lần công bố giá riêng của người có thẩm quyền.

<a id="t7-dr-101"></a>
### T7-DR-101 — Rà soát nguồn giá vốn tham chiếu

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G14`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Khi giá vốn chính thức mới được công bố, miền định giá phân loại sản phẩm theo loại nguồn của giá vốn tham chiếu hiện hành. Nguồn từ giá vốn chính thức kỳ trước được đưa vào lựa chọn cập nhật hàng loạt; nguồn từ kịch bản chiết khấu phải được người có thẩm quyền quyết định giữ nguyên, dùng giá vốn mới hoặc tính lại kịch bản.
- Phân luồng không dựa trên ngưỡng chênh lệch tối thiểu/tối đa và không tự ghi đè giá vốn tham chiếu đang có hiệu lực.

<a id="t7-dr-102"></a>
### T7-DR-102 — Ba cách nhìn lợi nhuận

- **Trạng thái:** `ACTIVE`
- **Nhóm nghiệp vụ:** `G14`
- **Phụ thuộc về hiệu lực cuối cùng (`depends_on`):** —

**Nội dung quyết định**

- Báo cáo quản trị phải phân biệt: lợi nhuận tại giao dịch dùng giá vốn ban đầu; lợi nhuận sau đối soát dùng giá vốn ban đầu cộng adjustment cuối kỳ; lợi nhuận dự kiến dùng giá vốn tham chiếu định giá. Không được trình bày ba cách nhìn như cùng một số liệu kế toán.

## 4. Phụ thuộc về hiệu lực cuối cùng

Các chuỗi dưới đây là hợp đồng tổng hợp bắt buộc. Mỗi quan hệ phải được chiếu sang trace và kịch bản nghiệm thu tổng hợp khi migrate SRS/Harness; không được chỉ giữ dưới dạng diễn giải.

| Chuỗi nghiệp vụ | Các quyết định tham gia | Nghĩa vụ về tính nguyên tử hoặc thứ tự |
|---|---|---|
| Nhận hàng mua | [`T7-DR-020`](#t7-dr-020) ↔ [`T7-DR-021`](#t7-dr-021) | Nhận vật lý tăng số lượng, giữ đúng trạng thái vật lý/nghiệp vụ và đồng thời đặt trạng thái định giá ở `VALUATION_PENDING`; xác nhận giá trị mới ghi giá trị và chuyển trạng thái định giá. Chỉ phần đồng thời đủ điều kiện bán mới được giải phóng khả dụng. Hai mốc không được ghi lặp hoặc nhập nhằng. |
| Hàng khách trả | [`T7-DR-041`](#t7-dr-041) | Số lượng và giá trị phải commit cùng giao dịch tại trạng thái chờ phân loại theo căn cứ của kỳ xuất gốc; phân loại sau đó chỉ đổi trạng thái và không ghi giá trị lần hai. |
| Trả hàng nhà cung cấp | [`T7-DR-042`](#t7-dr-042) ↔ [`T7-DR-054`](#t7-dr-054) | Trạng thái chờ trả loại hàng khỏi khả dụng; chỉ khi xác nhận bàn giao mới giảm số lượng, ghi giảm giá trị theo giá vốn chính thức và chuyển phần chênh lệch thương mại sang Kế toán. |
| Số dư đầu kỳ | [`T7-DR-067`](#t7-dr-067) ↔ [`T7-DR-068`](#t7-dr-068) ↔ [`T7-DR-069`](#t7-dr-069) | Chỉ batch đủ dữ liệu, đã duyệt và đạt số kiểm soát mới được commit nguyên tử; trạng thái chuẩn bị chỉ chuyển sang hoạt động và mở thao tác thường sau khi đối soát thành công. |
| Sửa sai và hoàn nguyên | [`T7-DR-064`](#t7-dr-064) ↔ [`T7-DR-065`](#t7-dr-065) ↔ [`T7-DR-066`](#t7-dr-066) ↔ [`T7-DR-071`](#t7-dr-071) | Không hoàn nguyên khi kết quả còn chưa xác định hoặc quan hệ phụ thuộc chưa được trung hòa; kỳ đã khóa chỉ được sửa ở kỳ mở và phải giữ chuỗi truy vết số lượng, giá trị và điều chỉnh định giá. |
| Phục hồi kết quả chưa xác định | [`T7-DR-071`](#t7-dr-071) ↔ [`T7-DR-090`](#t7-dr-090) | Chỉ phân giải bằng bằng chứng kết quả cuối có thẩm quyền, cùng định danh thao tác: `COMMITTED` để hoàn tất hoặc `NOT_COMMITTED`/`EXECUTION_REJECTED` với owner effect `NONE` để từ chối thực thi. Từ chối duyệt không phải bằng chứng phân giải `UNKNOWN`. Chỉ mở lại thay đổi sau khi đối soát sổ nghiệp vụ và dữ liệu dẫn xuất; không thử lại bằng định danh mới khi kết quả còn `UNKNOWN`. |

## 5. Ranh giới với quy tắc quản trị

Các nội dung sau không phải quyết định nghiệp vụ và không nhận `T7-DR-*`. Chúng phải được tạo tại đúng nơi tiếp nhận trong baseline đã đóng băng.

| Rule key | Nội dung | Người chịu trách nhiệm | Người phối hợp | Nơi tiếp nhận dự kiến | Trạng thái |
|---|---|---|---|---|---|
| `PERFORMANCE_SLO` | Mục tiêu độ trễ | Solution Architect | Platform Lead | `srs/07-technical-contracts.md#nfr-hieu-nang` | `ACTIVE` |
| `CAPACITY_TARGET` | Mục tiêu năng lực xử lý | Solution Architect | Platform Lead | `srs/07-technical-contracts.md#nfr-nang-luc-xu-ly` | `ACTIVE` |
| `BASELINE_FREEZE_GATE` | Cổng đóng băng baseline | Release Owner | BA Lead | `srs/09-traceability-quality.md#baseline-freeze-gates` | `ACTIVE` |
| `TERMINOLOGY_STANDARD` | Quy ước sử dụng thuật ngữ | BA Lead | Nhóm thẩm định miền | `know-how/glossary/glossary.md#quy-uoc-su-dung-thuat-ngu` | `ACTIVE` |
| `CONTRACT_CLOSURE_GATE` | Cổng khép kín hợp đồng | Solution Architect | BA Lead; QA/Harness Owner | `srs/09-traceability-quality.md#contract-closure-gate` | `ACTIVE` |
| `EXPERIENCE_MAP_AUTHORITY` | Thẩm quyền của bản đồ trải nghiệm | BA Lead | Product Designer | `srs/08-ui-ux.md#experience-map-va-authority-giao-dien` | `ACTIVE` |
| `UI_CONTENT_STANDARD` | Quy ước nội dung giao diện | Product Designer | BA Lead | `srs/08-ui-ux.md#quy-uoc-noi-dung-giao-dien` | `ACTIVE` |
| `DURABILITY_RPO` | Chỉ tiêu định lượng về độ bền, RPO và khả năng dựng lại | Solution Architect | Platform Lead | `srs/07-technical-contracts.md#durability-rpo-va-rebuildability` | `ACTIVE` |
| `PROGRESSIVE_DISCLOSURE` | Chỉ hỏi dữ liệu cần thiết; điền sẵn ngữ cảnh; ẩn ID kỹ thuật; hiển thị LOT/hạn dùng theo chính sách; đề xuất FEFO/FIFO có kiểm soát quyền; và đặt ranh giới xác nhận theo mức rủi ro | Product Designer | BA Lead | `srs/08-ui-ux.md#prefill-progressive-disclosure-va-confirmation` | `ACTIVE` |

## 6. Kiểm soát hợp nhất

- Mỗi thẩm quyền hoặc hiệu lực cuối cùng có đúng một quyết định cha.
- Nội dung đã hoàn tất không được sửa lịch sử; thay đổi sau đóng băng phải tạo phiên bản và freeze mới.
- Quyết định `OUT_OF_SCOPE` phải có từ chối có cấu trúc; không dựng thao tác hoặc giao diện ghi dữ liệu một phần.
- Nội dung quản trị tại Mục 5 phải được tạo và kiểm tra liên kết trước khi baseline mới được phát hành.
- Baseline `v3.1.0` và hồ sơ thay thế cũ tiếp tục nằm nguyên vẹn trong package tiền nhiệm; baseline này không sao chép bảng ánh xạ 207 ID cũ.

## 7. Kết quả kiểm tra tĩnh của baseline

| Kiểm tra | Kết quả |
|---|---|
| Số quyết định nghiệp vụ | `PASS` — 102 |
| ID duy nhất và liên tục | `PASS` — `T7-DR-001…T7-DR-102` |
| Phân bổ trạng thái quyết định | `PASS` — 96 `ACTIVE`, 4 `DEFERRED`, 2 `OUT_OF_SCOPE` |
| Số yêu cầu nguyên tử | `PASS` — 78 |
| Phân bổ trạng thái yêu cầu | `PASS` — 67 `ACTIVE`, 7 `DEFERRED`, 4 `OUT_OF_SCOPE` |
| Locator yêu cầu duy nhất | `PASS` — không trùng |
| Nhóm nghiệp vụ | `PASS` — 14 nhóm, không tổ chức theo phiên bản |
| Cột tham chiếu nguồn | `PASS` — đã loại bỏ |
| Nội dung chuyển sang quản trị | `PASS` — 7 đích chính và 2 đích thứ cấp được khai báo; còn `ACTIVE` |
| Phụ thuộc hiệu lực cuối cùng | `PASS` — 6 chuỗi được khai báo |
| Trạng thái phát hành | `FROZEN` — thay thế baseline `v3.1.0` cho mọi triển khai mới |
