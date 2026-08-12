---
id: UC-07-04
type: use-case
theme: theme-07
title: "Ghi nhận bàn giao trả nhà cung cấp"
owner: BA
status: IN_REVIEW
source_baseline: v3.10.1
---
# UC-07-04 — Ghi nhận bàn giao trả nhà cung cấp

## 1. Mục tiêu và outcome

Ghi nhận bàn giao trả nhà cung cấp để tạo kết quả nghiệp vụ có thể truy vết và kiểm thử độc lập.

**Kết quả thành công:** <ul><li>Tồn vật lý/giá trị giảm hoặc toàn operation bị từ chối</li><li>Supplier return issue result</li></ul>

## 2. Ranh giới

### 2.1 Bắt đầu khi

Có handover assertion và lượng pending hợp lệ

### 2.2 Kết thúc khi

<ul><li>Tồn vật lý/giá trị giảm hoặc toàn operation bị từ chối</li><li>Supplier return issue result</li></ul>

### 2.3 Không bao gồm

Phạm vi không thuộc UC được giữ theo BJ cha và các contract nguồn; migration không bổ sung negative scope mới.

## 3. Actor, trigger và điều kiện trước

- **Actor:** Thủ kho; bộ phận mua hàng cung cấp ý định trả
- **Trigger:** Có handover assertion và lượng pending hợp lệ
- **Điều kiện trước:** Current source/version + stable allocations còn hiệu lực; exact pending source slices và physical verification hợp lệ; quyền + warehouse scope đúng; có actor handover assertion. Commercial supplier price không phải điều kiện cần.

## 4. Hành vi nghiệp vụ

### Điều kiện đầu vào và định danh

Command envelope + `source_request_id/source_version/source_line_id/source_allocation_id`, exact source slices, Product/UOM/LOT/quantity, idempotency identity, actor + tenant/store/warehouse.

### Quy tắc và bất biến

<ul><li>Giới hạn lượng: Lượng trả không vượt đồng thời lượng còn được source cho phép và lượng tenant thực có theo đúng sản phẩm/lô</li><li>Nguồn nhập: Giữ liên kết đến receipt/source nhập gốc khi nguồn cung cấp; không tự tạo quan hệ thương mại mới</li><li>Mốc loại khỏi khả dụng: Khi supplier return đã được chấp thuận và lượng chuyển RTV_PENDING</li><li>Mốc giảm vật lý: Chỉ khi có bằng chứng bàn giao thực tế; tạo hồ sơ chờ trả không giảm physical</li><li>Sửa trước bàn giao: Không sửa trực tiếp payload đã khóa; source version mới tạo thay đổi có truy vết và chỉ giải phóng phần chưa bàn giao</li><li>Giá trị: Giảm theo official cost có hiệu lực; giá nhà cung cấp chấp thuận và chênh lệch chỉ là accounting handoff</li></ul>

## 5. Ngoại lệ và thất bại

**Không thành công:** <ul><li>Yêu cầu bị từ chối có mã/lý do rõ ràng.</li><li>Không tạo tác động authoritative ngoài draft hoặc bằng chứng được hợp đồng cho phép.</li><li>Dữ liệu nhập được giữ lại khi việc sửa và thử lại là an toàn.</li></ul>

**Chưa xác định:** <ul><li>Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp.</li></ul>

## 6. Ảnh hưởng nghiệp vụ

Chỉ tạo thay đổi được nêu trong BC-IO-09; UI hoặc adapter không được tự thêm transition.

**Kiểm toán:** Lưu actor, thời điểm nghiệp vụ/ghi nhận, source/version, correlation ID và bằng chứng quyết định áp dụng.

## 7. Behavioral Contract

- **Hợp đồng dùng chung:** [SBC-COM-01 — Bao yêu cầu và định danh](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-02 — Quyền, phạm vi và điều kiện cần](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả và phục hồi](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-04 — Finality và tính nguyên tử](../behavioral-contracts/BC-COMMON-EXTENSIONS.md)
- **Hợp đồng hành vi chính:** [BC-IO-09 — Return goods to supplier](../behavioral-contracts/BC-IO-09.md)

## 8. Screen liên quan

| Thuộc tính | Nội dung |
|---|---|
| Màn hình liên quan | [SCR-039](../../../03.design/screens/SCR-039.md); [SCR-041](../../../03.design/screens/SCR-041.md) |
| Quy tắc sở hữu | Không sở hữu màn hình riêng. UI của UC gọi hiển thị trạng thái tiến trình/kết quả và giữ cùng operation identity. |
| Các trạng thái của màn hình | READY, LOADING/PROCESSING, VALIDATION_ERROR, PERMISSION_DENIED, CONFLICT/STALE và trạng thái kết quả tương ứng. Chỉ khai state thật sự có ý nghĩa với màn hình. |
| Hành động | Mỗi CTA mutation liên kết đúng một Action ID → UC/BC → API; action không đủ quyền không xuất hiện. |
| Phản hồi | Nêu rõ điều vừa xảy ra, tác động dữ liệu và bước tiếp theo; giữ input ở validation/conflict/UNKNOWN khi an toàn. |
| Khả năng sử dụng | Mobile-first; tên màn hình thấy trước khi chọn; touch target tối thiểu 44 px; không dùng chỉ màu để truyền trạng thái. |

## 9. Acceptance Scenarios

| ID | Given | When | Then |
|---|---|---|---|
| AS-UC-07-04-01 | Điều kiện cần hợp lệ và dữ liệu đầu vào đầy đủ | Tác nhân thực hiện “Ghi nhận bàn giao trả nhà cung cấp” | Tồn vật lý/giá trị giảm hoặc toàn operation bị từ chối; kết quả Supplier return issue result và có truy vết nguồn. |
| AS-UC-07-04-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-UC-07-04-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-UC-07-04-04 | Không đủ bằng chứng về kết quả cuối | Client timeout hoặc xử lý bị gián đoạn | Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp. |

## 10. Truy vết

- **Nguồn quyết định:** [Nhóm G06 — Trả hàng, hết hạn và loại bỏ](../../../01.knowledge/decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y)
- **Bài tri thức liên quan:** [Trả hàng cho nhà cung cấp](../../../01.knowledge/know-how/KB-KGV-013-tra-hang-cho-nha-cung-cap.md); [Chọn hàng để xuất và thời điểm hoàn tất xuất bán](../../../01.knowledge/know-how/KB-KGV-010-chon-hang-de-xuat-va-thoi-diem-hoan-tat-xuat-ban.md); [Đơn giá tồn kho chính thức và tổng giá trị ghi sổ](../../../01.knowledge/know-how/KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md)

| Phạm vi | Cách dùng |
|---|---|
| BA | [BJ-07 — Thực hiện trả hàng cho nhà cung cấp](../journeys/BJ-07-thuc-hien-tra-hang-cho-nha-cung-cap.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy nhóm màn hình cũ làm phạm vi backend. |
| FE | Giao theo work package của BJ; trong package đó, UC này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-UC-07-04-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định UC-07-04, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của UC-07-04. Business Journey chỉ giữ flow đầu-cuối; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.



## Amendment v1.3.9 — Actual handover exactness & finality
- `SCR-039` chỉ mở khi toàn bộ current source allocations đã physical verify và không mismatch.
- Handover commit exact current Product+UOM+LOT scope; warehouse không arbitrary partial handover, không LOT substitution. Nếu physical reality khác source, source owner phải amendment/new version trước khi commit.
- Final review rechecks source/version/permission/warehouse/Product/UOM/LOT/quantity. Source stale không commit; quay lại preparation với granular invalidation.
- `SCR-039` là explicit final review nên không lặp confirmation modal thứ hai.
- Result snapshot giữ operation identity + source version + actor + line-level Product/UOM/LOT/qty; COMPLETED/REJECTED/UNKNOWN/PERMISSION không cho Back vào consumed commit. UNKNOWN không blind retry; prolonged recovery → BJ17.


## Amendment v1.4.0 — Exact pending handover & evidence
- `SCR-039` chỉ mở khi current allocation/source-slice scope đã verify, không có open physical observation và source/version vẫn current.
- `HandoverEvidence` dùng shared source-agnostic schema: source document/version, warehouse, actor/confirmed_at, exact line allocation/source-slice evidence và canonical hash.
- Official inventory cost quyết định value reduction. Supplier accepted price/debit note/payable difference thuộc Purchase/Accounting; thiếu commercial price không được block physical handover.
- `UNKNOWN` giữ same operation/idempotency identity; không blind retry; prolonged recovery → BJ17.

### Nguồn v3.10.1 — UC-07-04 — Ghi nhận bàn giao trả nhà cung cấp

> **Phiên bản:** 4.1.0  
> **Loại:** Trường hợp sử dụng dùng chung  
> **Hành trình nghiệp vụ:** [BJ-07 — Thực hiện trả hàng cho nhà cung cấp](../journeys/BJ-07-thuc-hien-tra-hang-cho-nha-cung-cap.md)  
> **Trạng thái:** SPECIFIED_FOR_REVIEW


> **Control/UI amendment v1.3.4:** Không duyệt lại commercial return. Actual handover mới giảm physical/value; UNKNOWN giữ cùng operation identity và không blind retry. Không invent handover evidence fields ngoài source contract.
