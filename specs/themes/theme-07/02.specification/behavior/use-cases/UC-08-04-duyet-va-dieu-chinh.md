---
id: UC-08-04
type: use-case
theme: theme-07
title: "Duyệt và điều chỉnh"
owner: BA
status: FROZEN
frozen_at: v5.27.0
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-08
---

# UC-08-04 — Duyệt và điều chỉnh

## 1. Mục tiêu và kết quả nghiệp vụ

Người duyệt độc lập quyết định trên **final variance snapshot và value/risk basis hiện hành**: duyệt để hệ thống ghi adjustment, hoặc yêu cầu đếm lại; người duyệt không sửa số đếm hay tự thay căn cứ giá trị.

**Kết quả cần đạt:** approval decision và adjustment được commit đúng một lần khi APPROVE; hoặc recount requirement được tạo khi `REQUEST_RECOUNT`; hoặc yêu cầu bị từ chối/stale mà không tạo adjustment bán phần.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Final variance khác 0, latest round và `CountAdjustmentBasis` còn current, và `ApprovalCase` ở `PENDING`.

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

UC kết thúc khi APPROVE đã commit adjustment + complete/unlock, hoặc `REQUEST_RECOUNT` đã tạo successor requirement, hoặc approval bị từ chối/stale, hoặc finality chưa xác định và phải phục hồi bằng cùng command identity.

### 2.3 Không bao gồm

Không sửa count evidence, không chỉnh value basis tại màn duyệt, không duyệt trên snapshot stale và không cho người đã góp count evidence tự phê duyệt snapshot đó.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Eligible independent approver đủ required level.
- **Thẩm quyền:** Được chọn `APPROVE` hoặc `REQUEST_RECOUNT`; không được sửa payload count/basis đã khóa.
- **Sự kiện khởi phát:** Một ApprovalCase kiểm kê non-zero đã sẵn sàng.
- **Điều kiện trước:** Approver không nằm trong `excluded_actor_ids`; session/scope/cutoff/lock/latest round/variance/value basis/policy hashes còn current.

## 4. Đối tượng và dữ liệu nghiệp vụ

| Đối tượng / Dữ liệu | Ý nghĩa và yêu cầu | Nguồn |
|---|---|---|
| `ApprovalCase` | Hồ sơ quyết định bind exact count snapshot và basis version | `ENT-IC-02`, `T7-DR-175` |
| Final variance | Chênh lệch trên latest accepted count evidence | `ENT-IC-05/09` |
| `CountAdjustmentBasis` | Value/risk basis current dùng để quyết định và commit | `T7-DR-177` |
| `excluded_actor_ids` | Tất cả người đã góp count evidence của snapshot đang xét | `T7-DR-175` |

## 5. Các luồng của Use Case

### 5.1 Luồng chính (Basic Flow)

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| BF-01 | Approver | Mở approval task và xem final variance, evidence, risk/value basis ở chế độ read-only. | |
| BF-02 | Hệ thống | Kiểm tra approver độc lập, required level và current approval/basis versions. | EF-A — Không đủ quyền hoặc không độc lập |
| BF-03 | Approver | Chọn `APPROVE` hoặc `REQUEST_RECOUNT`; recount bắt buộc có lý do. | AF-A — Yêu cầu đếm lại |
| BF-04 | Hệ thống | Với APPROVE, recheck round/scope/lock/policy/value basis ngay trước commit. | EF-B — Snapshot hoặc basis stale |
| BF-05 | Hệ thống | Commit approval, quantity/value adjustment, session complete, lock release và outbox trong cùng transaction. | EF-C — Kết quả chưa xác định |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Yêu cầu đếm lại

**Phát sinh tại:** BF-03. **Điều kiện:** Approver chưa chấp nhận final count và chọn `REQUEST_RECOUNT` với lý do hợp lệ.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Đóng/supersede current ApprovalCase, giữ lock và tạo recount requirement; không ghi adjustment. | BR-03 — Recount tạo lineage mới |
| AF-A-02 | — | [Tiếp tục tại UC-08-03]. | UC-08-03 — Đếm lại và hoàn thiện căn cứ |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Không đủ quyền hoặc không độc lập

**Phát sinh tại:** BF-02. **Điều kiện:** Actor không đủ required level hoặc đã góp count evidence của snapshot hiện hành.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Từ chối effect NONE; giữ ApprovalCase `PENDING`. | BR-01 — Maker/counter không tự duyệt |
| EF-A-02 | — | [Kết thúc UC]. | |

#### EF-B — Snapshot hoặc basis stale

**Phát sinh tại:** BF-04. **Điều kiện:** Latest round, scope, lock, policy hoặc value basis đã đổi so với ApprovalCase.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Từ chối `COUNT_APPROVAL_SNAPSHOT_STALE` hoặc `COUNT_VALUE_BASIS_STALE`; không dùng risk/basis cũ để commit. | BR-02 — Approval bind exact snapshot |
| EF-B-02 | — | [Kết thúc UC; re-derive/new case trước khi duyệt lại]. | |

#### EF-C — Kết quả chưa xác định

**Phát sinh tại:** BF-05. **Điều kiện:** Không thể xác định approval + adjustment transaction đã commit hay rollback.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-C-01 | Hệ thống | Giữ cùng approval command identity; không phát adjustment thứ hai trước khi xác minh finality. | `SBC-COM-03` — Kết quả và hướng phục hồi |
| EF-C-02 | — | [Tiếp tục tại BJ-17]. | BJ-17 — Phục hồi nghiệp vụ có kết quả chưa xác định |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Người đếm không tự duyệt | Mọi actor góp count evidence trong snapshot hiện hành phải bị loại khỏi approver eligible — **trừ** chủ cửa hàng (`is_owner`, mỗi cửa hàng chỉ có một): chủ đếm thì vẫn gửi duyệt rồi tự duyệt. | `T7-DR-175` |
| BR-02 | Approval bind exact snapshot | ApprovalCase bind session/scope/cutoff/latest round/variance/value basis/policy; bất kỳ phần nào đổi đều làm case stale. | `T7-DR-175/177` |
| BR-03 | Recount tạo lineage mới | `REQUEST_RECOUNT` không sửa evidence/approval cũ; tạo successor recount/case lineage. | `T7-DR-174/175` |
| BR-04 | Risk không net thừa thiếu | Risk được tính bằng tổng trị tuyệt đối line amount của final variance basis. | `T7-DR-177` |

- `BC-IC-03` — Duyệt chênh lệch kiểm kê và commit adjustment.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `SBC-COM-04` — Atomicity và chống ghi bán phần.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| `APPROVE` | Approval + adjustment + complete + unlock commit nguyên tử | Kết thúc BJ08; downstream valuation nhận fact nếu có |
| `REQUEST_RECOUNT` | Không adjustment; lock được giữ; có recount requirement mới | `UC-08-03` |
| Bị từ chối / stale | Không adjustment; hồ sơ hiện hành giữ nguyên hoặc được re-derive | Chọn approver hợp lệ hoặc tạo case mới |
| Chưa xác định (`UNKNOWN`) | Không được phát adjustment lần hai | BJ17 đối soát cùng identity |

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-08 — Kiểm kê và điều chỉnh chênh lệch](../../../03.design/flows/UIF-08-BJ-08.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-046` | Hiển thị approval task read-only: variance, evidence, risk/value basis và hành động duyệt/đếm lại. |
| `SCR-047` | Hiển thị kết quả authoritative sau quyết định/commit. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-08-04-01 — Counter không tự duyệt
- **Bao phủ:** EF-A; BR-01.
- **Given:** actor đã góp FIRST hoặc recount evidence của snapshot đang xét.
- **When:** actor mở approval task và cố duyệt.
- **Then:** hệ thống từ chối effect NONE; ApprovalCase vẫn chờ người đủ điều kiện khác.

### AS-UC-08-04-02 — Yêu cầu đếm lại
- **Bao phủ:** AF-A; BR-03.
- **Given:** approver thấy bằng chứng chưa đủ tin cậy.
- **When:** approver chọn `REQUEST_RECOUNT` và nhập lý do.
- **Then:** không có adjustment; lock được giữ và một recount requirement kế nhiệm được tạo.

### AS-UC-08-04-03 — Value basis đổi trước khi duyệt
- **Bao phủ:** EF-B; BR-02.
- **Given:** ApprovalCase đang chờ nhưng applicable cost/surplus basis đã đổi.
- **When:** approver bấm duyệt.
- **Then:** case bị coi stale; không commit adjustment bằng basis cũ.

### AS-UC-08-04-04 — Duyệt thành công
- **Bao phủ:** BF-01 → BF-06; BR-02/04.
- **Given:** approver độc lập, snapshot và basis còn current.
- **When:** approver chọn `APPROVE`.
- **Then:** approval, adjustments, completion và unlock commit nguyên tử; không có partial result.

### AS-UC-08-04-05 — Timeout khi commit
- **Bao phủ:** EF-C.
- **Given:** command duyệt đã gửi nhưng response bị mất.
- **When:** người dùng mở lại.
- **Then:** hệ thống không phát adjustment mới; finality được làm rõ bằng cùng command identity.

## 10. Truy vết

- **Journey:** `BJ-08` — Kiểm kê và điều chỉnh chênh lệch.
- **Domain / Entity:** `DOM-IC`, `ENT-IC-02`, `ENT-IC-04`, `ENT-IC-05`, `ENT-IC-09`.
- **Behavioral Contract:** `BC-IC-03`.
- **Decision / Nguồn:** `T7-DR-035…039`, `T7-DR-174…177`.
- **Bài tri thức liên quan:** [KB-KGV-011 — Kiểm kê hàng tồn kho từ khóa phạm vi đến điều chỉnh chênh lệch](../../../01.knowledge/know-how/KB-KGV-011-kiem-ke-hang-ton-kho-tu-khoa-pham-vi-den-dieu-chinh-chenh-lech.md); [KB-KGV-020 — Định giá hàng trả, tiêu hủy và chênh lệch thừa thiếu](../../../01.knowledge/know-how/KB-KGV-020-dinh-gia-hang-tra-tieu-huy-va-chenh-lech-thua-thieu.md); [KB-KGV-029 — Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md); [KB-KGV-031 — Phê duyệt Inventory Operation theo mức rủi ro](../../../01.knowledge/know-how/KB-KGV-031-phe-duyet-inventory-operation-theo-muc-rui-ro.md)
