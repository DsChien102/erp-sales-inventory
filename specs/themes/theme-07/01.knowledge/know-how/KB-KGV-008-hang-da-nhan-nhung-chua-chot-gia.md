---
id: KB-KGV-008-hang-da-nhan-nhung-chua-chot-gia
type: know-how
theme: theme-07
title: hang-da-nhan-nhung-chua-chot-gia
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# KB-KGV-008-hang-da-nhan-nhung-chua-chot-gia — hang-da-nhan-nhung-chua-chot-gia

## 1. Bối cảnh

### Câu trả lời ngắn

Hàng có thể **đã hiện diện trong kho và đã thuộc sở hữu doanh nghiệp**, nhưng chưa đủ căn cứ để ghi giá trị và đưa vào bán. Khi thủ kho hoàn tất nhận hàng, số lượng được ghi vào tồn vật lý ở trạng thái `VALUATION_PENDING`; tồn khả dụng chưa tăng và value ledger chưa ghi số tiền chính thức.

Quy tắc này áp dụng cho mọi lần nhận mua. Nếu request nhận hàng có kèm bằng chứng giá, bằng chứng được lưu để phục vụ bước định giá tiếp theo nhưng không làm operation nhận hàng tự ghi value movement hoặc bỏ qua `VALUATION_PENDING`.

Khi kế toán xác nhận giá mua trực tiếp từ bằng chứng hợp lệ, hệ thống ghi value movement và chuyển lượng đủ điều kiện từ chờ giá sang bán được **trong cùng một commit**. Sau mốc này, hàng trở thành khả dụng ngay nếu không bị chặn bởi điều kiện khác; không cần thêm một lớp phê duyệt riêng.

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
| Xác nhận giá trực tiếp | Kế toán xác nhận giá mua trực tiếp từ bằng chứng hợp lệ | Cho phép ghi value movement |
| Giải phóng khả dụng | Chuyển lượng đủ điều kiện sang trạng thái bán được | Làm tăng khả dụng theo công thức hiện hành |
| Chi phí mua phân bổ bổ sung | Vận chuyển, bốc dỡ hoặc chi phí liên quan được bổ sung sau | Điều chỉnh giá trị, không làm thay đổi số lượng vật lý |

`VALUATION_PENDING` chỉ phù hợp khi **quyền sở hữu đã chuyển cho doanh nghiệp**. Hàng vẫn thuộc bên thứ ba không được dùng trạng thái chờ giá để đi vòng qua điều kiện sở hữu.

### Quy trình từ nhận hàng đến cho phép bán

| Mốc | Người chịu trách nhiệm | Dữ liệu/bằng chứng chính | Ảnh hưởng số lượng | Ảnh hưởng giá trị | Ảnh hưởng khả dụng |
|---|---|---|---|---|---|
| 1. Xác nhận thực nhận | Thủ kho | Lượng thực nhận và dữ liệu bắt buộc của hàng | Tăng tồn vật lý ở `VALUATION_PENDING` | Chưa ghi số tiền chính thức | Không tăng |
| 2. Chờ định giá | Kế toán theo dõi nghĩa vụ định giá | Đơn mua, biên nhận và xác nhận giá của nhà cung cấp | Không đổi | Chưa ghi chính thức | Vẫn bằng 0 cho lượng này |
| 3. Xác nhận giá trực tiếp | Kế toán có quyền | Giá mua trực tiếp đủ căn cứ; hóa đơn có thể đến sau | Chuyển trạng thái, không tăng thêm vật lý | Ghi value movement theo giá đã chốt | Lượng đủ điều kiện được giải phóng ngay |
| 4. Bổ sung chi phí mua sau | Kế toán hoặc nguồn có thẩm quyền | Thành phần chi phí và căn cứ phân bổ | Không đổi | Ghi valuation adjustment theo quy tắc kỳ | Không tự thay đổi |

#### Commit tại mốc xác nhận giá

Việc ghi giá trị và giải phóng hàng không phải hai thao tác rời nhau. Trong cùng một commit, hệ thống phải:

1. ghi kết quả xác nhận giá trực tiếp;
2. ghi value movement cho lượng đã nhận;
3. chuyển lượng đủ điều kiện ra khỏi `VALUATION_PENDING`;
4. cập nhật số dư và khả dụng liên quan;
5. lưu sự kiện cần phát cho các hệ thống nhận.

Nếu một phần thất bại, toàn bộ commit phải rollback. Cách này ngăn tình trạng hàng đã được bán nhưng chưa có giá trị, hoặc giá trị đã ghi mà lượng hàng vẫn mắc kẹt ở chờ giá.

Operation nhận hàng và operation xác nhận giá có hai định danh, hai kết quả và hai biên transaction độc lập. Operation xác nhận giá vẫn commit nguyên tử các thay đổi giá trị–trạng thái của chính nó; không được gộp ngầm vào lần nhận hàng chỉ vì hai bước xảy ra gần nhau.

#### Căn cứ tối thiểu để xác nhận giá

Kế toán có thể xác nhận giá từ **đơn mua hoặc biên nhận kết hợp với mức giá được nhà cung cấp xác nhận**. Hóa đơn không bắt buộc phải đến trước mốc giải phóng hàng. Tuy nhiên, giá mua trực tiếp phải được chốt; chi phí mua cần phân bổ có thể được bổ sung sau bằng valuation adjustment.

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

#### Ngày 11/08 — kế toán xác nhận giá

Kế toán có đơn mua, biên nhận và xác nhận của nhà cung cấp với giá trực tiếp **48.000 đồng/chai**. Operation xác nhận giá hoàn tất và ghi:

$$
200 \times 48.000 = 9.600.000\text{ đồng}
$$

Trong cùng commit, 200 chai rời `VALUATION_PENDING` và chuyển sang lượng bán được. Nếu không có điều kiện chặn hoặc lượng giữ khác, tồn khả dụng tăng từ 0 lên 200. Vì đây là sản phẩm mới, 48.000 đồng trở thành đơn giá chính thức khởi tạo.

#### Ngày 14/08 — bổ sung chi phí vận chuyển

Chi phí vận chuyển 600.000 đồng được phân bổ sau. Hệ thống ghi valuation adjustment có nguồn và phương pháp phân bổ; tồn vật lý vẫn là 200 trước các lần xuất phát sinh. Chi phí bổ sung đi vào quá trình đối soát giá trị, không tạo thêm 200 chai và không lặp lại operation nhận hàng.


#### Basis, UOM và ngày ghi nhận của initial valuation

Initial valuation không gom giá theo tên Product+UOM đơn thuần. `DirectCostBasis` bám commercial receipt item/source line và có hash/version của toàn bộ component provenance; technical LOT/state scopes có thể cùng dùng basis đó. Direct cost được hiển thị theo transaction UOM nhưng đồng thời chuẩn hóa về base UOM; Official Cost khởi tạo luôn dùng VND/base UOM. Value movement của lần xác nhận mang `business_date` là ngày nhận nghiệp vụ, còn `recorded_at` là thời điểm server commit. Component đến sau khi quantity đã initial-valued đi qua BJ13/valuation adjustment thay vì sửa lại ReceiptValuation cũ.

### Ngoại lệ và những cách làm sai

- **Chờ chốt giá mới ghi nhận hàng:** làm sai tồn vật lý và khiến kho không chịu trách nhiệm được với hàng đang hiện diện.
- **Cho phép bán hàng ở `VALUATION_PENDING`:** biến hàng chưa có giá trị chính thức thành nguồn cho xuất bán.
- **Ghi giá trị ước tính như giá trị chính thức:** làm mất ranh giới giữa dữ liệu tạm và value ledger có thẩm quyền.
- **Yêu cầu hóa đơn phải đến trước trong mọi trường hợp:** không phù hợp với căn cứ đã chốt; xác nhận giá của nhà cung cấp có thể đủ dù hóa đơn đến sau.
- **Thêm một vòng duyệt sau khi kế toán đã xác nhận giá:** tạo mốc giả không có trong quy trình và làm hàng bị giữ vô lý.
- **Dùng `VALUATION_PENDING` cho hàng chưa thuộc sở hữu:** trộn hàng bên thứ ba với tồn của doanh nghiệp.
- **Bổ sung chi phí mua bằng quantity adjustment:** chi phí bổ sung chỉ thay đổi giá trị nếu không có movement vật lý mới.

## 3. Ý nghĩa đối với Theme

### Điều cần ghi nhớ

- **Nhận hàng làm tăng tồn vật lý; xác nhận giá mới cho phép ghi giá trị và giải phóng bán.**
- **Hàng chờ giá có vật lý nhưng khả dụng bằng 0.**
- **Giá mua trực tiếp phải được xác nhận trước khi hàng được bán; chi phí mua phân bổ có thể đến sau.**
- **Ghi value movement và giải phóng khả dụng phải diễn ra nguyên tử.**
- **Sản phẩm mới dùng giá nhập trực tiếp đầu tiên đã xác nhận để khởi tạo đơn giá chính thức, rồi vẫn đối soát cuối kỳ.**

## 4. Nguồn tham khảo

### Nguồn quyết định và phạm vi

| Thuộc tính | Giá trị |
|---|---|
| Article ID | `KB-KGV-008` |
| Cụm tri thức | [`KGV-C02`](00-table-of-contents.md#c02-nhận-giữ-và-xuất-hàng) |
| Loại bài | `PROCESS` |
| Quyết định chính | [`T7-DR-021`](../decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B), [`T7-DR-021#REQ-01`](../decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B), [`T7-DR-025`](../decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B), [`T7-DR-021#REQ-02`](../decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B), [`T7-DR-021#REQ-03`](../decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B), [`T7-DR-026`](../decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B), [`T7-DR-020#REQ-01`](../decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B) |
| Trạng thái quyết định | `ACTIVE` |
| Mức bằng chứng của bài | `STATIC_VALIDATED` |
| Giới hạn | Bài không mô tả chênh lệch giao nhận, kiểm tra lô–hạn hoặc cách phân bổ từng loại chi phí mua |

## 5. Liên kết liên quan

### Chủ đề liên quan

- [`KB-KGV-007` — Nhận hàng mua và xử lý chênh lệch giao nhận](KB-KGV-007-nhan-hang-mua-va-xu-ly-chenh-lech-giao-nhan.md)
- [`KB-KGV-015` — Đơn giá tồn kho chính thức và tổng giá trị ghi sổ](KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md)
- [`KB-KGV-019` — Các thành phần hình thành giá nhập thực tế](KB-KGV-019-cac-thanh-phan-hinh-thanh-gia-nhap-thuc-te.md)
- [`KB-KGV-024` — Chọn quản lý thông thường hay quản lý theo lô](KB-KGV-024-chinh-sach-quan-ly-hang-thong-thuong-theo-lo-hoac-theo-serial.md)
