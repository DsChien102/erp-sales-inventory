---
id: UC-03-01
type: use-case
theme: theme-07
title: "Xác lập giá trị nhập ban đầu"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v3.12.0
---

# UC-03-01 — Xác lập giá trị nhập ban đầu

## 1. Mục tiêu và kết quả nghiệp vụ

Kế toán xác lập **giá trị ban đầu của lượng hàng đã thực sự nhận** bằng các căn cứ giá hợp lệ đang có tại thời điểm xử lý. Kết quả phải giải thích được giá trị đến từ đâu, áp dụng cho đúng lượng nào và không làm thay đổi lịch sử nhận hàng.

Thành công khi đúng phạm vi hàng chờ giá được ghi value movement, chuyển từ `VALUATION_PENDING` sang `VALUATION_CONFIRMED`, giữ nguyên trạng thái vật lý và được đánh dấu cần cập nhật giá vốn. UC này **không tạo hoặc công bố giá vốn chính thức**.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Có lượng hàng đã hoàn tất nhận vật lý, thuộc quyền sở hữu tenant, chưa từng được xác lập giá trị ban đầu và còn `VALUATION_PENDING`.

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Kết thúc khi một trong các kết quả sau đã rõ:

- phạm vi được xác lập giá trị thành công và value movement đã commit;
- hồ sơ vẫn chờ vì chưa đủ căn cứ hoặc còn mâu thuẫn thuộc owner khác;
- yêu cầu bị từ chối trước mutation;
- mutation có kết quả `UNKNOWN` và được bàn giao sang BJ17 với cùng operation identity.

### 2.3 Không bao gồm

- Sửa PO, hóa đơn NCC, điều kiện thương mại hoặc tranh chấp nguồn thuộc Theme 10.
- Ghi thành phần giá trị chỉ xuất hiện hoặc chỉ trở nên hợp lệ sau khi initial valuation đã hoàn tất; phần này thuộc BJ13.
- Sửa lỗi nhập liệu của người dùng sau khi đã commit; phần này đi theo BJ11/correction.
- Tính hoặc công bố `OfficialCostVersion`; phần này thuộc BJ14.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Kế toán kho hoặc người có quyền tài chính tương đương.
- **Thẩm quyền:** Được xác nhận căn cứ và giá trị trong phạm vi tenant; không được sửa dữ liệu nguồn do Theme khác sở hữu. Với Quick receipt, chỉ người có quyền theo policy mới được lập hoặc chọn căn cứ giá trực tiếp.
- **Sự kiện khởi phát:** Có hàng chờ xác lập giá trị sau BJ02.
- **Điều kiện trước:** Receipt đã hoàn tất; quantity mục tiêu đang `VALUATION_PENDING`; Product/UOM và conversion snapshot hợp lệ; chính sách thuế/tỷ giá cần thiết có nguồn có thẩm quyền.

## 4. Đối tượng và dữ liệu nghiệp vụ

| Đối tượng / Dữ liệu | Ý nghĩa và yêu cầu | Nguồn |
|---|---|---|
| Hàng thực nhận chờ giá | Quantity thực sự đã vào tồn; phạm vi UI theo receipt item, backend giữ exact technical scope | `DOM-IO`, `ENT-IO-01/02` |
| Căn cứ thương mại | Giá mua, chiết khấu, thuế và thành phần thương mại đã được Theme 10 xác lập | Theme 10 / integration contract |
| Căn cứ giá trực tiếp | Căn cứ dùng cho Quick khi không có nguồn Theme 10: đơn giá, tiền tệ, cách hiểu đã/chưa gồm thuế khi cần, nguồn, ngày nguồn, bằng chứng/tham chiếu, người xác lập | `DOM-IV`, `ENT-IV-01` |
| Tax treatment | Phần thuế/phí được hoặc không được thu hồi theo chính sách tenant/giao dịch; người dùng không tự chọn khả năng khấu trừ | Policy có thẩm quyền; `T7-DR-189` |
| Thành phần giá trị | Giá mua − khoản giảm giá trị mua + thuế/phí không thu hồi + chi phí mua trực tiếp đã đủ căn cứ | `BC-IV-05` |
| Phạm vi căn cứ | Quantity mà nguồn thực sự chứng minh; không phải số lượng người dùng tự chia tùy ý | `T7-DR-188` |
| Tỷ giá | Tỷ giá có thẩm quyền để quy đổi sang VND khi nguồn bằng ngoại tệ | Nguồn kế toán/chứng từ |

## 5. Các luồng của Use Case

### 5.1 Luồng chính (Basic Flow)

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| BF-01 | Kế toán | Mở hàng đang chờ xác lập giá trị và chọn receipt item cần xử lý. | |
| BF-02 | Hệ thống | Tập hợp quantity còn chờ giá, căn cứ hiện có, tax treatment, tỷ giá và các thành phần giá trị đã đủ nguồn; đồng thời xác định phạm vi mà từng căn cứ thực sự bao phủ. | AF-A — Nhận theo chứng từ<br>AF-B — Nhập hàng nhanh<br>AF-C — Căn cứ chỉ bao phủ một phần lượng<br>EF-A — Chưa đủ căn cứ<br>EF-B — Mâu thuẫn thương mại thuộc Theme 10 |
| BF-03 | Kế toán | Rà soát căn cứ, bổ sung thông tin thuộc thẩm quyền Theme 7 nếu cần và xác nhận căn cứ sẽ dùng. | AF-D — Nhiều căn cứ trực tiếp của Quick |
| BF-04 | Hệ thống | Tính cấu thành giá trị nhập ban đầu theo đúng phạm vi, UOM, thuế, tỷ giá, phân bổ và làm tròn; trả kết quả để rà soát nhưng chưa mutation. | BR-01 — Công thức giá trị nhập<br>BR-02 — Phạm vi theo căn cứ |
| BF-05 | Kế toán | Rà soát quantity, nguồn và tổng giá trị; xác nhận ghi nhận. | EF-C — Nguồn thay đổi trước xác nhận |
| BF-06 | Hệ thống | Recheck source/scope freshness, ghi `ReceiptValuation` và value movement, chuyển đúng quantity sang `VALUATION_CONFIRMED`, giữ nguyên physical state và đánh dấu Product + posting period cần cập nhật giá vốn. | BC-IV-01 — Xác nhận giá trị nhập ban đầu<br>EF-D — Kết quả mutation chưa xác định |
| BF-07 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Nhận theo chứng từ

**Phát sinh tại:** BF-02. **Điều kiện:** receipt có liên kết nguồn mua do Theme 10 quản lý.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Nạp các thành phần thương mại đã được Theme 10 xác lập và chỉ sử dụng phần có trạng thái/hiệu lực cho phép. | T7-DR-186 — Hai nguồn vào BJ03 |
| AF-A-02 | Kế toán | Rà soát dữ liệu nguồn ở chế độ read-only; không sửa PO/hóa đơn trong Theme 7. | T7-DR-190 — Quyền xử lý xung đột |
| AF-A-03 | — | [Trở lại BF-04]. | BF-04 — Tính cấu thành giá trị |

#### AF-B — Nhập hàng nhanh

**Phát sinh tại:** BF-02. **Điều kiện:** Quick receipt không có căn cứ thương mại đủ dùng từ Theme 10.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-B-01 | Kế toán | Lập căn cứ giá trực tiếp bằng đơn giá mua, tiền tệ, cách hiểu giá đã/chưa gồm thuế khi cần, nguồn, ngày nguồn và bằng chứng/tham chiếu phù hợp. | T7-DR-187 — Căn cứ giá trực tiếp |
| AF-B-02 | Hệ thống | Kiểm tra quyền, tính đầy đủ và tax treatment; không yêu cầu tạo PO/hóa đơn giả. | T7-DR-186 — Quick không phụ thuộc Theme 10<br>T7-DR-189 — Tax treatment |
| AF-B-03 | — | [Trở lại BF-04]. | BF-04 — Tính cấu thành giá trị |

#### AF-C — Căn cứ chỉ bao phủ một phần lượng

**Phát sinh tại:** BF-02. **Điều kiện:** nguồn hợp lệ chỉ chứng minh một phần quantity còn `VALUATION_PENDING`.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-C-01 | Hệ thống | Tạo exact valuation scope theo phần quantity được căn cứ bao phủ; phần còn lại tiếp tục chờ giá. | T7-DR-188 — Phạm vi theo căn cứ |
| AF-C-02 | — | [Trở lại BF-03]. | BF-03 — Rà soát căn cứ |

#### AF-D — Nhiều căn cứ trực tiếp của Quick

**Phát sinh tại:** BF-03. **Điều kiện:** có nhiều căn cứ trực tiếp hợp lệ do Theme 7 quản lý và các căn cứ cho kết quả khác nhau.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-D-01 | Kế toán | Chọn căn cứ được policy cho phép sử dụng, xem rõ ngày/phiên bản và ghi lý do bắt buộc. | T7-DR-190 — Quyền xử lý xung đột |
| AF-D-02 | Hệ thống | Giữ đầy đủ dấu vết cả căn cứ được chọn và căn cứ không được chọn. | |
| AF-D-03 | — | [Trở lại BF-04]. | BF-04 — Tính cấu thành giá trị |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Chưa đủ căn cứ

**Phát sinh tại:** BF-02. **Điều kiện:** chưa xác định được giá mua, tax treatment/tỷ giá cần thiết hoặc nguồn bắt buộc khác.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Giữ quantity ở `VALUATION_PENDING`, nêu rõ dữ kiện còn thiếu và không ghi value movement. | |
| EF-A-02 | — | [Kết thúc UC]. | |

#### EF-B — Mâu thuẫn thương mại thuộc Theme 10

**Phát sinh tại:** BF-02. **Điều kiện:** PO, hóa đơn hoặc nguồn thương mại đang tranh chấp/chưa được owner xác lập.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Giữ trạng thái cần đối chiếu và không cho Theme 7 tự chọn nguồn thương mại để bỏ qua conflict. | T7-DR-190 — Quyền xử lý xung đột |
| EF-B-02 | — | [Bàn giao Theme 10 xử lý nguồn thương mại; sau đó quay lại UC này]. | |

#### EF-C — Nguồn thay đổi trước xác nhận

**Phát sinh tại:** BF-05. **Điều kiện:** source/basis/scope version khác với preview vừa rà soát.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-C-01 | Hệ thống | Từ chối commit, tải lại căn cứ hiện hành và yêu cầu rà soát lại; không partial commit. | T7-DR-154 — Freshness |
| EF-C-02 | — | [Trở lại BF-02]. | BF-02 — Tập hợp căn cứ hiện hành |

#### EF-D — Kết quả mutation chưa xác định

**Phát sinh tại:** BF-06. **Điều kiện:** không chứng minh được transaction đã commit hay rollback.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-D-01 | Hệ thống | Trả `UNKNOWN`, giữ nguyên operation/idempotency identity và không cho tạo một xác nhận mới để thử lại. | SBC-COM-03 — Kết quả và phục hồi |
| EF-D-02 | — | [Tiếp tục tại BJ-17]. | BJ-17 — Phục hồi nghiệp vụ có kết quả chưa xác định |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Công thức giá trị nhập | Giá trị nhập = giá mua − các khoản giảm giá trị mua + thuế/phí không thu hồi + chi phí mua trực tiếp đã đủ căn cứ ± thành phần hợp lệ khác. Quyền lợi dự kiến không được ghi thật.| T7-DR-189, T7-DR-193 |
| BR-02 | Phạm vi theo căn cứ | Người dùng không tự chia quantity để định giá. Partial chỉ phát sinh khi nguồn hợp lệ thực sự bao phủ một phần lượng còn chờ.| T7-DR-188 |
| BR-03 | Nguồn và bằng chứng | Nguồn là authority nghiệp vụ; bằng chứng là tài liệu/tham chiếu hỗ trợ. Hai khái niệm phải được lưu riêng khi cần.| T7-DR-187 |
| BR-04 | Không ghi đè nguồn | PO/hóa đơn và commercial facts do Theme 10 sở hữu là read-only tại Theme 7.| T7-DR-190 |
| BR-05 | Sau xác nhận | Business fact mới đến sau đi BJ13; lỗi nhập liệu của người dùng đi correction/BJ11.| T7-DR-191 |

- `BC-IV-05` — Dựng preview giá trị nhập ban đầu.
- `BC-IV-01` — Xác nhận giá trị nhập ban đầu.
- `SBC-COM-02/03/04` — Quyền, finality và phục hồi dùng chung.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Exact quantity được ghi giá trị ban đầu, provenance bất biến, chuyển `VALUATION_CONFIRMED`; physical state không đổi; Product + posting period được đánh dấu cần cập nhật giá vốn | BJ14 xử lý cập nhật giá vốn theo scope hệ thống |
| Chưa đủ căn cứ | Không value movement; quantity tiếp tục `VALUATION_PENDING` | Bổ sung nguồn rồi quay lại UC |
| Mâu thuẫn Theme 10 | Theme 7 không commit valuation | Theme 10 giải quyết nguồn rồi quay lại |
| Thất bại đã xác nhận | Không tạo tác động bán phần | Sửa điều kiện và thử lại theo cùng business intent |
| `UNKNOWN` | Không thể kết luận commit/no-commit; không được xác nhận lại bằng identity mới | BJ17 đối soát/phục hồi |

## 8. Liên hệ giao diện

> **Parity note v3.12.0:** các Screen Contract/HTML dưới đây là bề mặt hiện hành từ v3.11.0. Semantic mới của UC này là nguồn cho lượt redesign v3.13.0; không suy ngược nghiệp vụ từ copy/layout cũ.

| Screen | Vai trò trong UC |
|---|---|
| `SCR-014` | Danh sách hàng đang chờ xác lập giá trị và lý do readiness. |
| `SCR-015` | Xem hàng thực nhận và căn cứ giá hiện có. |
| `SCR-016` | Bề mặt hiện hành để xem căn cứ/cách tính; dự kiến được tái thiết kế theo semantic mới. |
| `SCR-017` | Rà soát quantity, nguồn và cấu thành giá trị trước confirm. |
| `SCR-019` | Kết quả xác nhận, phần còn chờ và hướng tiếp theo. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-03-01-01 — Nhận theo chứng từ có căn cứ đầy đủ
- **Bao phủ:** BF-01 → BF-07; AF-A; BR-01 → BR-04.
- **Given:** hàng đã nhận còn `VALUATION_PENDING` và Theme 10 cung cấp commercial facts hợp lệ, không conflict.
- **When:** kế toán xác nhận giá trị nhập ban đầu.
- **Then:** value movement chỉ ghi cho quantity được căn cứ bao phủ, provenance giữ source/version và không tạo `OfficialCostVersion`.

### AS-UC-03-01-02 — Quick receipt không có Theme 10
- **Bao phủ:** BF-01 → BF-07; AF-B; BR-01 → BR-03.
- **Given:** Quick receipt đã hoàn tất và kế toán có quyền lập căn cứ giá trực tiếp.
- **When:** kế toán xác nhận căn cứ trực tiếp đầy đủ.
- **Then:** BJ03 hoàn tất không cần PO/hóa đơn giả và giá trị được tính theo tax policy của tenant.

### AS-UC-03-01-03 — Căn cứ chỉ bao phủ một phần
- **Bao phủ:** AF-C; BR-02.
- **Given:** 100 đơn vị đang chờ giá nhưng nguồn hợp lệ chỉ áp dụng cho 60.
- **When:** kế toán xác nhận căn cứ đó.
- **Then:** chỉ 60 đơn vị được valued; 40 đơn vị còn lại tiếp tục `VALUATION_PENDING` và người dùng không được tự đổi phạm vi thành một số tùy ý.

### AS-UC-03-01-04 — Mâu thuẫn PO và hóa đơn đang chờ Theme 10
- **Bao phủ:** EF-B; BR-04.
- **Given:** commercial sources có giá khác nhau và Theme 10 chưa xác lập nguồn có hiệu lực.
- **When:** kế toán mở hồ sơ BJ03.
- **Then:** Theme 7 không cho chọn tùy ý một giá để commit và hướng xử lý quay về Theme 10.

### AS-UC-03-01-05 — Nguồn thay đổi trước commit
- **Bao phủ:** EF-C.
- **Given:** kế toán đã preview nhưng basis/scope version thay đổi trước confirm.
- **When:** kế toán xác nhận.
- **Then:** toàn command bị từ chối trước mutation và yêu cầu rà soát lại dữ liệu hiện hành.

### AS-UC-03-01-06 — Hóa đơn đến sau Quick receipt đã valued
- **Bao phủ:** BR-05.
- **Given:** Quick receipt đã hoàn tất BJ03 và sau đó Theme 10 xác lập hóa đơn có giá khác.
- **When:** chênh lệch trở thành business fact hợp lệ.
- **Then:** không mở lại/sửa BJ03; chênh lệch được bàn giao sang BJ13.

## 10. Truy vết

- **Journey:** `BJ-03` — Xác lập giá trị ban đầu của hàng nhận.
- **Domain / Entity:** `DOM-IV`, `ENT-IV-01`, `ENT-IV-02`, `DOM-IO`, `ENT-IO-01`, `ENT-IO-02`.
- **Behavioral Contract:** `BC-IV-01`, `BC-IV-05`, `SBC-COM-02/03/04`.
- **Decision:** `T7-DR-185…190`, `T7-DR-191`, `T7-DR-193`; `T7-DR-026` và `T7-DR-155` chỉ còn giá trị lịch sử.
