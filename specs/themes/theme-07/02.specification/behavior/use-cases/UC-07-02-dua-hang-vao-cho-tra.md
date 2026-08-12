---
id: UC-07-02
type: use-case
theme: theme-07
title: "Đồng bộ hàng vào chờ trả"
owner: BA
status: IN_REVIEW
source_baseline: v3.10.1
---
# UC-07-02 — Đồng bộ hàng vào chờ trả

## 1. Mục tiêu và outcome

Resolve exact inventory source slices và system-sync lượng đã được authorize vào `RTV_PENDING`.

**Kết quả thành công:** <ul><li>Lượng được chuyển sang `RTV_PENDING` và loại khỏi khả dụng</li><li>Pending supplier return</li></ul>

## 2. Ranh giới

### 2.1 Bắt đầu khi

Có scope hợp lệ

### 2.2 Kết thúc khi

<ul><li>Lượng được chuyển sang `RTV_PENDING` và loại khỏi khả dụng</li><li>Pending supplier return</li></ul>

### 2.3 Không bao gồm

Phạm vi không thuộc UC được giữ theo BJ cha và các contract nguồn; migration không bổ sung negative scope mới.

## 3. Actor, trigger và điều kiện trước

- **Actor:** System process; Purchase/source là upstream authority
- **Trigger:** Có scope hợp lệ
- **Điều kiện trước:** Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện.

## 4. Hành vi nghiệp vụ

### Điều kiện đầu vào và định danh

Command envelope dùng chung; source/aggregate ID và version; payload nghiệp vụ; idempotency key; actor, tenant, store và warehouse scope.

### Quy tắc và bất biến

<ul><li>Giới hạn lượng: Lượng trả không vượt đồng thời lượng còn được source cho phép và lượng tenant thực có theo đúng sản phẩm/lô</li><li>Nguồn nhập: Giữ liên kết đến receipt/source nhập gốc khi nguồn cung cấp; không tự tạo quan hệ thương mại mới</li><li>Mốc loại khỏi khả dụng: Khi supplier return đã được chấp thuận và lượng chuyển RTV_PENDING</li><li>Mốc giảm vật lý: Chỉ khi có bằng chứng bàn giao thực tế; tạo hồ sơ chờ trả không giảm physical</li><li>Sửa trước bàn giao: Không sửa trực tiếp payload đã khóa; source version mới tạo thay đổi có truy vết và chỉ giải phóng phần chưa bàn giao</li><li>Giá trị: Giảm theo official cost có hiệu lực; giá nhà cung cấp chấp thuận và chênh lệch chỉ là accounting handoff</li></ul>

## 5. Ngoại lệ và thất bại

**Không thành công:** <ul><li>Yêu cầu bị từ chối có mã/lý do rõ ràng.</li><li>Không tạo tác động authoritative ngoài draft hoặc bằng chứng được hợp đồng cho phép.</li><li>Dữ liệu nhập được giữ lại khi việc sửa và thử lại là an toàn.</li></ul>

**Chưa xác định:** <ul><li>Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp.</li></ul>

## 6. Ảnh hưởng nghiệp vụ

`RTV_PENDING` là system-owned effect của `BC-IO-17`; không render warehouse CTA “Đưa hàng vào chờ trả/Chuyển trạng thái”.

**Kiểm toán:** Lưu actor, thời điểm nghiệp vụ/ghi nhận, source/version, correlation ID và bằng chứng quyết định áp dụng.

## 7. Behavioral Contract

- **Hợp đồng dùng chung:** [SBC-COM-01 — Bao yêu cầu và định danh](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-02 — Quyền, phạm vi và điều kiện cần](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả và phục hồi](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-04 — Finality và tính nguyên tử](../behavioral-contracts/BC-COMMON-EXTENSIONS.md)
- **Hợp đồng hành vi chính:** [BC-IO-17 — Synchronize supplier-return authorization](../behavioral-contracts/BC-IO-17.md)

## 8. Screen liên quan

| Thuộc tính | Nội dung |
|---|---|
| Màn hình liên quan | Không có screen mutation riêng. Kết quả system sync xuất hiện trong [SCR-036](../../../03.design/screens/SCR-036.md) và [SCR-037](../../../03.design/screens/SCR-037.md). `SCR-038` chỉ thuộc UIF-09. |
| Quy tắc sở hữu | Có thể dùng chung màn hình với UC khác. UI Contract được viết một lần theo bề mặt; file này chỉ sở hữu hành vi và lát nghiệm thu của UC. |
| Các trạng thái của màn hình | READY, LOADING/PROCESSING, VALIDATION_ERROR, PERMISSION_DENIED, CONFLICT/STALE và trạng thái kết quả tương ứng. Chỉ khai state thật sự có ý nghĩa với màn hình. |
| Hành động | Mỗi CTA mutation liên kết đúng một Action ID → UC/BC → API; action không đủ quyền không xuất hiện. |
| Phản hồi | Nêu rõ điều vừa xảy ra, tác động dữ liệu và bước tiếp theo; giữ input ở validation/conflict/UNKNOWN khi an toàn. |
| Khả năng sử dụng | Mobile-first; tên màn hình thấy trước khi chọn; touch target tối thiểu 44 px; không dùng chỉ màu để truyền trạng thái. |

## 9. Acceptance Scenarios

| ID | Given | When | Then |
|---|---|---|---|
| AS-UC-07-02-01 | Source allocation hợp lệ và source slices resolve được | Hệ thống nhận/đồng bộ source authorization | Exact quantity được chuyển sang `RTV_PENDING`, loại khỏi availability và giữ original-state source-slice lineage; không cần warehouse mutation CTA. |
| AS-UC-07-02-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-UC-07-02-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-UC-07-02-04 | Không đủ bằng chứng về kết quả cuối | Client timeout hoặc xử lý bị gián đoạn | Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp. |

## 10. Truy vết

- **Nguồn quyết định:** [Nhóm G06 — Trả hàng, hết hạn và loại bỏ](../../../01.knowledge/decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y)
- **Bài tri thức liên quan:** [Trả hàng cho nhà cung cấp](../../../01.knowledge/know-how/KB-KGV-013-tra-hang-cho-nha-cung-cap.md); [Chọn hàng để xuất và thời điểm hoàn tất xuất bán](../../../01.knowledge/know-how/KB-KGV-010-chon-hang-de-xuat-va-thoi-diem-hoan-tat-xuat-ban.md); [Đơn giá tồn kho chính thức và tổng giá trị ghi sổ](../../../01.knowledge/know-how/KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md)

| Phạm vi | Cách dùng |
|---|---|
| BA | [BJ-07 — Thực hiện trả hàng cho nhà cung cấp](../journeys/BJ-07-thuc-hien-tra-hang-cho-nha-cung-cap.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy nhóm màn hình cũ làm phạm vi backend. |
| FE | Giao theo work package của BJ; trong package đó, UC này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-UC-07-02-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định UC-07-02, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của UC-07-02. Business Journey chỉ giữ flow đầu-cuối; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.



## Amendment v1.3.9 — Source-owned pending placement
- Việc đặt lượng source-authorized vào `RTV_PENDING` là system/source-owned effect; UI không yêu cầu thủ kho thực hiện một bước “chuyển trạng thái” riêng.
- `RTV_PENDING` loại khỏi availability nhưng chưa giảm physical/value.
- SCR-038 không thuộc active UIF07.


## Amendment v1.4.0 — Exact source slices
- Mỗi source allocation resolve thành `1..N` source slices khóa `source_balance_id + origin_stock_state + LOT + quantity + balance_version`.
- Nếu đúng một composition hợp lệ, hệ thống tự resolve. Nếu nhiều composition hợp lệ, chỉ khi Thủ kho mở SCR-037 mới progressive-disclose “Xác định nguồn tồn” để xác nhận exact composition.
- Việc xác định source state không thay đổi commercial quantity/LOT và không phải approval.

### Nguồn v3.10.1 — UC-07-02 — Đồng bộ hàng vào chờ trả

> **Phiên bản:** 4.1.0  
> **Loại:** Trường hợp sử dụng  
> **Hành trình nghiệp vụ:** [BJ-07 — Thực hiện trả hàng cho nhà cung cấp](../journeys/BJ-07-thuc-hien-tra-hang-cho-nha-cung-cap.md)  
> **Trạng thái:** SPECIFIED_FOR_REVIEW


> **Control/UI amendment v1.3.4:** `RTV_PENDING` preparation là execution của source-authorized intent; không có approval thương mại lần hai. Chuyển pending loại khỏi available nhưng chưa giảm physical/value.
