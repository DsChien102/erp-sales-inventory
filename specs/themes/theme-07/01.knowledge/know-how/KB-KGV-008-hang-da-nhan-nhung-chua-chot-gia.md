---
id: KB-KGV-008-hang-da-nhan-nhung-chua-chot-gia
type: know-how
theme: theme-07
title: hang-da-nhan-nhung-chua-chot-gia
owner: BA
status: FROZEN
source_baseline: v3.12.0
---
# KB-KGV-008-hang-da-nhan-nhung-chua-chot-gia — hang-da-nhan-nhung-chua-chot-gia

## 1. Bối cảnh

### Câu trả lời ngắn

Hàng có thể **đã hiện diện trong kho và đã thuộc sở hữu doanh nghiệp**, nhưng chưa đủ căn cứ để ghi giá trị và đưa vào bán. Khi thủ kho hoàn tất nhận hàng, số lượng được ghi vào tồn vật lý ở trạng thái `VALUATION_PENDING`; tồn khả dụng chưa tăng và value ledger chưa ghi số tiền chính thức.

Quy tắc này áp dụng cho mọi lần nhận mua. Nếu request nhận hàng có kèm bằng chứng giá, bằng chứng được lưu để phục vụ bước định giá tiếp theo nhưng không làm operation nhận hàng tự ghi value movement hoặc bỏ qua `VALUATION_PENDING`.

Khi kế toán xác lập giá trị nhập ban đầu từ căn cứ hợp lệ, hệ thống ghi value movement và chuyển đúng lượng được xác nhận khỏi `VALUATION_PENDING` **trong cùng một commit**. Sau mốc này, lượng đó chỉ trở thành khả dụng nếu trạng thái vật lý và các điều kiện bán khác đều cho phép; không cần thêm một lớp phê duyệt riêng.

### Vì sao vấn đề này quan trọng?

Trong thực tế, xe hàng có thể đến kho trước hóa đơn hoặc trước khi kế toán chốt được giá với nhà cung cấp. Nếu hệ thống chờ có giá mới ghi nhận hàng, số liệu vật lý sẽ sai: hàng đang nằm trong kho nhưng sổ lại nói chưa nhận. Nếu hệ thống cho bán ngay khi chưa có giá, doanh nghiệp lại phát sinh xuất kho và lợi nhuận trên một lượng hàng chưa được định giá đầy đủ.

Tách hai mốc giúp phản ánh đúng cả hai sự thật:

- **Sự thật vật lý:** hàng đã được nhận và đang hiện diện.
- **Sự thật định giá:** giá mua trực tiếp đã đủ căn cứ để ghi nhận và sử dụng.

## 2. Nội dung nền tảng

### Các khái niệm cần phân biệt

| Khái niệm | Ý nghĩa | Ảnh hưởng chính |
|---|---|---|
| Nhận hàng | Thủ kho xác nhận lượng thực nhận và operation nhận hoàn tất | Tăng tồn vật lý |
| `VALUATION_PENDING` | Hàng đã thuộc sở hữu doanh nghiệp nhưng chưa chốt giá trực tiếp | Có vật lý, khả dụng bằng 0, chưa có số tiền chính thức trong value ledger |
| Nghĩa vụ định giá | Hồ sơ cần kế toán xử lý để chốt giá của lượng đã nhận | Giúp hàng chờ giá không bị quên |
| Xác lập giá trị nhập ban đầu | Kế toán rà soát/xác lập căn cứ giá hợp lệ và xác nhận cấu thành giá trị | Ghi value movement ban đầu và hoàn tất trục định giá cho lượng được bao phủ |
| Giải phóng khả dụng | Chuyển lượng đủ điều kiện sang trạng thái bán được | Làm tăng khả dụng theo công thức hiện hành |
| Chi phí mua phân bổ bổ sung | Vận chuyển, bốc dỡ hoặc chi phí liên quan được bổ sung sau | Điều chỉnh giá trị, không làm thay đổi số lượng vật lý |

`VALUATION_PENDING` chỉ phù hợp khi **quyền sở hữu đã chuyển cho doanh nghiệp**. Hàng vẫn thuộc bên thứ ba không được dùng trạng thái chờ giá để đi vòng qua điều kiện sở hữu.

### Quy trình từ nhận hàng đến cho phép bán

| Mốc | Người chịu trách nhiệm | Dữ liệu/bằng chứng chính | Ảnh hưởng số lượng | Ảnh hưởng giá trị | Ảnh hưởng khả dụng |
|---|---|---|---|---|---|
| 1. Xác nhận thực nhận | Thủ kho | Lượng thực nhận và dữ liệu bắt buộc của hàng | Tăng tồn vật lý ở `VALUATION_PENDING` | Chưa ghi số tiền chính thức | Không tăng |
| 2. Chờ định giá | Kế toán theo dõi nghĩa vụ định giá | Nguồn thương mại đã xác lập hoặc căn cứ giá trực tiếp hợp lệ | Không đổi | Chưa ghi chính thức | Vẫn bằng 0 cho lượng này |
| 3. Xác nhận giá trực tiếp | Kế toán có quyền | Giá mua trực tiếp đủ căn cứ; hóa đơn có thể đến sau | Chuyển trạng thái, không tăng thêm vật lý | Ghi value movement theo giá đã chốt | Lượng đủ điều kiện được giải phóng ngay |
| 4. Bổ sung chi phí mua sau | Kế toán hoặc nguồn có thẩm quyền | Thành phần chi phí và căn cứ phân bổ | Không đổi | Ghi valuation adjustment theo quy tắc kỳ | Không tự thay đổi |

#### Commit tại mốc xác lập giá trị nhập ban đầu

Việc ghi giá trị và giải phóng hàng không phải hai thao tác rời nhau. Trong cùng một commit, hệ thống phải:

1. ghi ReceiptValuation và cấu thành giá trị đã xác nhận;
2. ghi value movement cho lượng đã nhận;
3. chuyển lượng đủ điều kiện ra khỏi `VALUATION_PENDING`;
4. cập nhật số dư và khả dụng liên quan;
5. lưu sự kiện cần phát cho các hệ thống nhận.

Nếu một phần thất bại, toàn bộ commit phải rollback. Cách này ngăn tình trạng hàng đã được bán nhưng chưa có giá trị, hoặc giá trị đã ghi mà lượng hàng vẫn mắc kẹt ở chờ giá.

Operation nhận hàng và command xác lập giá trị nhập ban đầu có hai định danh, hai kết quả và hai biên transaction độc lập. Command BJ03 commit nguyên tử các thay đổi giá trị–trạng thái định giá của chính nó; không được gộp ngầm vào lần nhận hàng chỉ vì hai bước xảy ra gần nhau.

#### Căn cứ tối thiểu để xác lập giá trị nhập ban đầu

Nhận theo chứng từ có thể sử dụng giá và các thành phần thương mại do Theme 10 đã xác lập. Nhập hàng nhanh phải hoàn tất được mà không phụ thuộc Theme 10: kế toán có quyền phù hợp có thể lập căn cứ giá trực tiếp có nguồn và dấu vết. Hóa đơn không bắt buộc phải đến trước BJ03. Thành phần đã đủ căn cứ trước lúc xác nhận có thể nằm trong giá trị ban đầu; thành phần phát sinh hoặc được xác lập sau đó đi BJ13.

#### Sản phẩm chưa có đơn giá chính thức

Nếu đây là lần nhập đầu tiên và sản phẩm chưa có đơn giá tồn kho chính thức, giá nhập trực tiếp được xác nhận sẽ tạo **phiên bản đơn giá chính thức khởi tạo**. Việc khởi tạo này không loại bỏ yêu cầu đối soát cuối kỳ.

### Ví dụ xuyên suốt

Kho nhận 200 chai sản phẩm B vào ngày 10/08. Quyền sở hữu đã chuyển, nhưng kế toán chưa nhận được xác nhận cuối cùng về giá trực tiếp.

#### Ngày 10/08 — thủ kho nhận hàng

| Chỉ tiêu | Trước nhận | Sau nhận |
|---|---:|---:|
| Tồn vật lý | 0 | 200 |
| `VALUATION_PENDING` | 0 | 200 |
| Lượng đủ điều kiện bán | 0 | 0 |
| Tồn khả dụng | 0 | 0 |
| Giá trị chính thức đã ghi | 0 | 0 |

Hệ thống đồng thời tạo nghĩa vụ định giá cho 200 chai. Người bán không thể dùng lượng này để nhận thêm cam kết bán.

#### Ngày 11/08 — kế toán xác lập giá trị nhập ban đầu

Kế toán có căn cứ mua hợp lệ với giá **48.000 đồng/chai**. BJ03 rà soát phạm vi căn cứ, xác nhận giá trị nhập ban đầu và ghi:

$$
200 \times 48.000 = 9.600.000\text{ đồng}
$$

Trong cùng commit, 200 chai rời `VALUATION_PENDING`. Nếu trạng thái vật lý và các điều kiện bán khác đều cho phép, lượng đủ điều kiện bán/khả dụng được đánh giá lại. Giá trị 9.600.000 đồng là **giá trị nhập ban đầu** của lượng đã nhận; nó chưa phải giá vốn chính thức. Sản phẩm và kỳ liên quan được đánh dấu cần cập nhật để BJ14 tính và công bố giá vốn theo chính sách tenant.

#### Ngày 14/08 — bổ sung chi phí vận chuyển

Chi phí vận chuyển 600.000 đồng được phân bổ sau. Hệ thống ghi valuation adjustment có nguồn và phương pháp phân bổ; tồn vật lý vẫn là 200 trước các lần xuất phát sinh. Chi phí bổ sung đi vào quá trình đối soát giá trị, không tạo thêm 200 chai và không lặp lại operation nhận hàng.


#### Basis, UOM và ngày ghi nhận của initial valuation

Giá trị nhập ban đầu không gom giá theo tên Product+UOM đơn thuần. Căn cứ bám dòng hàng thực nhận và phạm vi mà nguồn hợp lệ thực sự bao phủ; nhiều technical LOT/state scope có thể dùng chung một căn cứ khi nghiệp vụ không phân biệt giá. Giá trị được trình bày theo transaction UOM và đồng thời chuẩn hóa về base UOM để phục vụ ledger và BJ14. Value movement của lần xác nhận mang `business_date` là ngày nhận nghiệp vụ, còn `recorded_at` là thời điểm server commit. Thành phần hợp lệ xuất hiện sau khi quantity đã được xác lập giá trị ban đầu đi qua BJ13 dưới dạng điều chỉnh giá trị, thay vì sửa lại ReceiptValuation cũ.

### Ngoại lệ và những cách làm sai

- **Chờ chốt giá mới ghi nhận hàng:** làm sai tồn vật lý và khiến kho không chịu trách nhiệm được với hàng đang hiện diện.
- **Cho phép bán hàng ở `VALUATION_PENDING`:** biến hàng chưa có giá trị chính thức thành nguồn cho xuất bán.
- **Ghi giá trị ước tính như giá trị chính thức:** làm mất ranh giới giữa dữ liệu tạm và value ledger có thẩm quyền.
- **Yêu cầu hóa đơn phải đến trước trong mọi trường hợp:** không phù hợp với căn cứ đã chốt; xác nhận giá của nhà cung cấp có thể đủ dù hóa đơn đến sau.
- **Thêm một vòng duyệt sau khi kế toán đã xác lập giá trị nhập ban đầu:** tạo mốc giả không có trong quy trình và làm hàng bị giữ vô lý.
- **Dùng `VALUATION_PENDING` cho hàng chưa thuộc sở hữu:** trộn hàng bên thứ ba với tồn của doanh nghiệp.
- **Bổ sung chi phí mua bằng quantity adjustment:** chi phí bổ sung chỉ thay đổi giá trị nếu không có movement vật lý mới.

## 3. Ý nghĩa đối với Theme

### Điều cần ghi nhớ

- **Nhận hàng làm tăng tồn vật lý; BJ03 xác lập giá trị nhập ban đầu và hoàn tất trục định giá. Khả dụng chỉ tăng khi lượng hàng đồng thời đủ điều kiện bán.**
- **Hàng chờ giá có vật lý nhưng khả dụng bằng 0.**
- **Giá mua trực tiếp phải được xác nhận trước khi hàng được bán; chi phí mua phân bổ có thể đến sau.**
- **Ghi value movement và giải phóng khả dụng phải diễn ra nguyên tử.**
- **BJ03 không khởi tạo đơn giá chính thức; mọi phiên bản giá vốn chính thức, kể cả phiên bản đầu tiên của sản phẩm, đều do BJ14 công bố.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-008` |
| Cụm tri thức | [`KGV-C02`](00-table-of-contents.md#c02-nhận-giữ-và-xuất-hàng) |
| Loại bài | `PROCESS` |
| Quyết định chính | [`T7-DR-021`](../decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B), [`T7-DR-021#REQ-01`](../decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B), [`T7-DR-025`](../decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B), [`T7-DR-021#REQ-02`](../decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B), [`T7-DR-021#REQ-03`](../decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B), [`T7-DR-020#REQ-01`](../decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B) |
| Trạng thái quyết định | `ACTIVE` |
| Mức bằng chứng của bài | `STATIC_VALIDATED` |
| Giới hạn | Bài không mô tả chênh lệch giao nhận, kiểm tra lô–hạn hoặc cách phân bổ từng loại chi phí mua |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-007` — Nhận hàng mua và xử lý chênh lệch giao nhận](KB-KGV-007-nhan-hang-mua-va-xu-ly-chenh-lech-giao-nhan.md)
- [`KB-KGV-015` — Đơn giá tồn kho chính thức và tổng giá trị ghi sổ](KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md)
- [`KB-KGV-019` — Các thành phần hình thành giá trị hàng nhập](KB-KGV-019-cac-thanh-phan-hinh-thanh-gia-tri-hang-nhap.md)
- [`KB-KGV-024` — Chọn quản lý thông thường hay quản lý theo lô](KB-KGV-024-chinh-sach-quan-ly-hang-thong-thuong-theo-lo-hoac-theo-serial.md)
