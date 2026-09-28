---
id: INT-01
type: integration
theme: theme-07
title: "Hợp đồng tích hợp liên Theme của Kho & Giá vốn"
owner: SA
status: IN_REVIEW
source_baseline: v3.12.0
---
# INT-01 — Hợp đồng tích hợp liên Theme của Kho & Giá vốn

## 1. Mục đích và ranh giới

Tài liệu này khóa **ý nghĩa dữ liệu và ownership khi Theme 7 trao đổi với Theme khác**. Nó không chuyển quyền sở hữu PO, hóa đơn, công nợ, chính sách thuế hoặc giá bán vào Theme 7.

Đối với chuỗi BJ03 → BJ13 → BJ14, ranh giới quan trọng nhất là:

- Theme 10 sở hữu sự thật thương mại của mua hàng khi sự thật đó tồn tại: đơn mua, hóa đơn NCC, giá/chiết khấu và trạng thái tranh chấp thương mại.
- Theme 7 sở hữu lượng hàng thực nhận, giá trị tồn kho ban đầu, điều chỉnh giá trị hàng nhập và giá vốn chính thức.
- **Quick Receipt không phụ thuộc Theme 10.** Theme 7 có thể xác lập căn cứ giá trực tiếp theo policy và authority của mình.
- Căn cứ thương mại có trước khi BJ03 xác nhận có thể tham gia giá trị nhập ban đầu; căn cứ hợp lệ xuất hiện/thay đổi sau đó được route sang BJ13.

## 2. Catalog producer / consumer

| Boundary | Producer | Consumer | Source of truth | Theme 7 được làm gì | Theme 7 không được làm gì |
|---|---|---|---|---|---|
| Căn cứ thương mại mua hàng | Theme 10 | Theme 7 | Theme 10 | Dùng thành phần đã xác lập để tính giá trị lượng thực nhận | Sửa PO/hóa đơn hoặc tự giải quyết commercial dispute thuộc Theme 10 |
| Receipt facts | Theme 7 | Theme 10 / reporting | Theme 7 | Công bố fact receipt đã `COMMITTED`: source/line lineage, lượng thực nhận theo UOM, kho và ngày nhận | Gửi command yêu cầu Theme 10 sửa/cập nhật PO hoặc biến receipt thành PO/hóa đơn |
| Giá trị nhập ban đầu | Theme 7 | Accounting/reporting | Theme 7 | Công bố fact initial value đã commit | Trình bày nó như Official Cost |
| Điều chỉnh giá trị hàng nhập | Theme 7 | Accounting/reporting | Theme 7, với provenance về source owner | Công bố signed adjustment + original/posting period | Viết lại receipt valuation lịch sử |
| Giá vốn chính thức | Theme 7 | Accounting/Pricing/Reporting | Theme 7/BJ14 | Công bố `OfficialCostVersion` có hiệu lực | Tự đổi giá bán hoặc công nợ |
| Tax treatment | Policy owner có thẩm quyền | Theme 7 | Policy owner | Tiêu thụ kết quả recoverable/non-recoverable | Cho user BJ03 tự chọn treatment |

## 3. Theme 10 → Theme 7: thành phần giá trị mua

### 3.1 Nội dung bàn giao

Một handoff đủ dùng phải cho Theme 7 biết tối thiểu:

- source document/line identity và source version;
- Product/UOM hoặc receipt-matching identity đủ để xác định phạm vi áp dụng;
- component type: giá mua, chiết khấu/giảm giá, tax/fee fact, quyền lợi thương mại đã xác lập…;
- signed amount/currency hoặc unit commercial fact theo loại component;
- effective time/status;
- trạng thái nguồn: confirmed, disputed, superseded hoặc tương đương;
- evidence/reference cần thiết để truy vết.

Theme 10 không gửi một con số “giá vốn” cho Theme 7. Theme 7 quyết định tác động của các component hợp lệ lên **lượng hàng thực tế đã nhận**.

### 3.2 Route theo thời điểm

```text
Source component từ Theme 10
        |
        +-- target chưa initial-valued và component đã đủ điều kiện
        |       -> BJ03 / UC-03-01
        |
        +-- target đã initial-valued, component mới xuất hiện/thay đổi
                -> BJ13 / UC-13-01
```

Không route dựa trên “loại chứng từ” một cách máy móc. Cùng một phí vận chuyển có thể thuộc BJ03 nếu đã đủ căn cứ trước confirm, hoặc BJ13 nếu đến sau.

### 3.3 Conflict

Nếu Theme 10 đánh dấu PO/invoice/commercial source đang tranh chấp hoặc chưa xác lập, Theme 7 giữ trạng thái chờ. Theme 7 không được cho kế toán chọn một nguồn bất kỳ để bỏ qua conflict thương mại.

## 4. Quick Receipt không phụ thuộc Theme 10

Quick Receipt có thể hoàn tất BJ03 bằng `THEME7_DIRECT` basis theo `UC-03-01`, miễn căn cứ đáp ứng policy về authority, nguồn, thời điểm, tiền tệ, cách hiểu thuế và evidence/reason.

Nếu sau đó Theme 10 tiếp nhận một hóa đơn hoặc commercial source và liên kết được với Quick Receipt:

- nếu giá trị ban đầu chưa xác nhận, source có thể tham gia BJ03;
- nếu BJ03 đã hoàn tất và source làm thay đổi giá trị, Theme 7 tạo signed adjustment qua BJ13;
- không mở lại BJ03 để viết lại lịch sử.

## 5. Theme 7 → downstream

| Fact outbound | Trigger | Nội dung chính | Finality |
|---|---|---|---|
| Receipt recorded | BJ02 `COMMITTED` | Receipt + source document/line lineage + quantity classification/UOM + warehouse + receipt business date | Chỉ durable commit mới phát; `REJECTED`/`UNKNOWN` không được công bố như fact đã nhận |
| Initial value confirmed | BJ03 commit | Receipt valuation, covered quantity, value movements, provenance, dirty cost scope | Không kèm Official Cost mới |
| Receipt value adjustment recorded | BJ13 commit | Signed component/allocation/value movements/original & posting periods/dirty scope | Không tự công bố Official Cost |
| Official cost published | BJ14 publication | Product, OfficialCostVersion, effective time, source run/method snapshot | Chỉ publication thành công mới authoritative |

`Receipt recorded` là **integration fact ở thì quá khứ**, không phải command. Theme 10 tiêu thụ fact này để tự cập nhật trạng thái/số lượng còn nhận của PO theo ownership của mình; Theme 7 không gửi lệnh “cập nhật PO” và không sở hữu `remaining_receivable_qty` sau khi Theme 10 xử lý fact.

Wire/API/event chi tiết nằm ở `FND-TECH-01`; integration semantic không được copy event schema thành nguồn thứ hai.

## 6. Consistency, ordering và chống lặp

- Mỗi inbound component có stable source/component identity và source version.
- Consumer phải idempotent; retry không tạo thêm ReceiptValuation hoặc ValueAdjustmentSource cho cùng business fact.
- Source revision thay đổi không được tạo business identity mới nếu vẫn là cùng economic component.
- Event delivery có thể at-least-once; consumer dùng inbox/dedup theo Technical Contract.
- Theme 7 không suy total-order giữa Theme khác; mọi mutation phải recheck source/scope version ngay trước commit.

## 7. Failure và recovery

| Tình huống | Cách xử lý |
|---|---|
| Source Theme 10 stale/superseded trước BJ03/BJ13 commit | Reject trước mutation và refresh source |
| Commercial dispute chưa resolve | Giữ chờ, owner là Theme 10 |
| Theme 10 unavailable nhưng Quick có direct basis hợp lệ | BJ03 vẫn tiếp tục độc lập |
| Event đã phát nhưng consumer chưa nhận | Retry cùng event identity; không rollback Theme 7 commit |
| Không rõ mutation Theme 7 đã commit hay chưa | Dùng finality/UNKNOWN recovery contract; không gửi command mới mù quáng |

## 8. Temporary outbound reference artifacts

Các gói lịch sử chuyển giao Theme 5/10/2/Reporting vẫn được giữ dưới `06.evidence/outbound-v3.10.1/` để truy vết. Chúng là **evidence**, không phải canonical Theme 7 capability và không được dùng để đếm BJ/UC hiện hành.

## 9. Verification

- Theme 10 source không bị copy thành owned entity của Theme 7.
- Quick Receipt có đường hoàn tất BJ03 khi Theme 10 không có source.
- Source trước/sau initial valuation route đúng BJ03/BJ13.
- `ReceiptValuationConfirmed` không chứa/khởi tạo Official Cost mới.
- `OfficialCostVersion` chỉ xuất hiện sau BJ14 publication.
- Duplicate/stale/source-conflict tests được bao phủ bởi `FND-TECH-01` và BC tương ứng.
