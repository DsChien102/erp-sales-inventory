---
id: UC-08-03
type: use-case
theme: theme-07
title: "Đếm lại và hoàn thiện căn cứ"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-08
---

# UC-08-03 — Đếm lại và hoàn thiện căn cứ

## 1. Mục tiêu và kết quả nghiệp vụ

Người được phân công thực hiện một recount round mới cho các dòng còn chênh lệch, **không sửa evidence cũ**, để xác lập final count hiện hành và chuẩn bị đủ value/risk basis nếu chênh lệch vẫn còn.

**Kết quả cần đạt:** recount submission bất biến được ghi; nếu variance về 0 thì hoàn tất phiên, nếu còn chênh lệch thì có `CountAdjustmentBasis` current để chuyển phê duyệt, hoặc hồ sơ bị giữ chờ vì thiếu căn cứ giá trị.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Latest accepted round còn variance khác 0 hoặc approver đã yêu cầu `REQUEST_RECOUNT`.

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

UC kết thúc khi recount submission đã commit và hệ thống xác định được zero variance, basis ready cho non-zero variance, hoặc blocker `PRICE_BASIS_REQUIRED`; trường hợp finality chưa rõ được phục hồi bằng cùng submission identity.

### 2.3 Không bao gồm

Không overwrite round trước, không cho counter nhập giá trị surplus, không phê duyệt adjustment và không tự giải phóng lock khi vẫn còn chênh lệch chưa được xử lý.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Assigned counter hiện hành của recount round.
- **Thẩm quyền:** Chỉ đếm lại các discrepant lines thuộc round/scope được giao; không được thay value basis hoặc approval decision.
- **Sự kiện khởi phát:** Có recount requirement hiện hành.
- **Điều kiện trước:** Session/lock còn current; assignment và latest accepted submission còn đúng version.

## 4. Đối tượng và dữ liệu nghiệp vụ

| Đối tượng / Dữ liệu | Ý nghĩa và yêu cầu | Nguồn |
|---|---|---|
| `StockCountSubmission` | Evidence append-only của từng recount round | `ENT-IC-09`, `T7-DR-174` |
| Discrepant lines | Chỉ các dòng còn variance khác 0 cần đếm lại | `ENT-IC-05` |
| `CountAdjustmentBasis` | Snapshot chênh lệch + value/risk basis dùng cho approval | `DOM-IC`, `T7-DR-177` |
| Shortage value basis | Official Cost version áp dụng cho thiếu | `DOM-IV`, `T7-DR-177` |
| Surplus value basis | Căn cứ giá trị có thẩm quyền cho hàng thừa | `T7-DR-176` |

## 5. Các luồng của Use Case

### 5.1 Luồng chính (Basic Flow)

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| BF-01 | Counter | Mở recount round với các discrepant lines và round context hiện hành. | |
| BF-02 | Counter | Ghi số lượng thực tế và bằng chứng bổ sung cho các dòng được yêu cầu. | |
| BF-03 | Hệ thống | Kiểm tra assignment/scope/tracking và tạo submission mới với `round_no` kế tiếp, giữ predecessor. | EF-A — Assignment hoặc scope stale<br>EF-C — Kết quả chưa xác định |
| BF-04 | Hệ thống | Tính final variance từ latest accepted round. | AF-A — Variance về 0 |
| BF-05 | Hệ thống | Với non-zero variance, dựng `CountAdjustmentBasis` và kiểm tra value basis cho shortage/surplus. | EF-B — Thiếu surplus value basis |
| BF-06 | — | [Tiếp tục tại UC-08-04]. | UC-08-04 — Duyệt và điều chỉnh |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Recount đưa variance về 0

**Phát sinh tại:** BF-04. **Điều kiện:** Final variance sau recount bằng 0.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Hoàn tất session và giải phóng lock; không tạo ApprovalCase hoặc adjustment. | BR-03 — Zero variance không cần approval |
| AF-A-02 | — | [Kết thúc BJ-08]. | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Assignment hoặc scope stale

**Phát sinh tại:** BF-03. **Điều kiện:** Assignment version, scope hoặc latest round đã đổi so với màn hình người dùng đang thao tác.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Từ chối recount mới; giữ toàn bộ evidence cũ bất biến. | BR-01 — Recount append-only |
| EF-A-02 | — | [Kết thúc UC]. | |

#### EF-B — Thiếu surplus value basis

**Phát sinh tại:** BF-05. **Điều kiện:** Có hàng thừa nhưng chưa có căn cứ giá trị có thẩm quyền.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Trả `PRICE_BASIS_REQUIRED`, giữ lock và không tạo ApprovalCase/adjustment. | BR-02 — Counter không tự định giá surplus |
| EF-B-02 | — | [Kết thúc UC ở trạng thái chờ căn cứ]. | |

#### EF-C — Kết quả chưa xác định

**Phát sinh tại:** BF-03. **Điều kiện:** Không thể xác định recount submission đã commit hay chưa.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-C-01 | Hệ thống | Đối soát bằng cùng submission identity; không append duplicate recount. | `SBC-COM-03` — Kết quả và hướng phục hồi |
| EF-C-02 | — | [Tiếp tục tại BJ-17]. | BJ-17 — Phục hồi nghiệp vụ có kết quả chưa xác định |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Recount append-only | Mỗi recount tạo submission mới với predecessor/round/actor/time; không overwrite evidence trước. | `T7-DR-174` |
| BR-02 | Giá trị surplus có owner riêng | Counter không nhập giá cho hàng thừa; surplus adjustment cần value basis có thẩm quyền. | `T7-DR-176` |
| BR-03 | Zero variance không cần approval | Nếu recount đưa variance về 0, session hoàn tất và không tạo adjustment. | `T7-DR-177` |
| BR-04 | Basis phải current | Shortage/surplus value basis và variance snapshot phải current trước khi tạo approval case. | `T7-DR-177` |

- `BC-IC-02` — Ghi nhận count/recount evidence.
- `SBC-COM-03` — Kết quả và hướng phục hồi.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Variance về 0 | Session completed; lock released; không adjustment | Kết thúc BJ08 |
| Non-zero, basis đầy đủ | Final count và `CountAdjustmentBasis` current | `UC-08-04` |
| Thiếu value basis | Session giữ lock; chưa approval/adjustment | Bổ sung căn cứ rồi tiếp tục |
| Chưa xác định (`UNKNOWN`) | Không ghi recount trùng | BJ17 đối soát cùng identity |

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-08 — Kiểm kê và điều chỉnh chênh lệch](../../../03.design/flows/UIF-08-BJ-08.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-045` | Hiển thị discrepant lines, round context, số đếm lại và trạng thái value basis. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-08-03-01 — Recount giữ evidence cũ
- **Bao phủ:** BF-01 → BF-04; BR-01.
- **Given:** FIRST round có chênh lệch và recount được phân công.
- **When:** counter submit round 2.
- **Then:** round 1 vẫn bất biến; round 2 có predecessor và trở thành latest accepted evidence nếu hợp lệ.

### AS-UC-08-03-02 — Recount đưa variance về 0
- **Bao phủ:** AF-A; BR-03.
- **Given:** recount quantity khớp book snapshot.
- **When:** hệ thống tính final variance.
- **Then:** session hoàn tất, lock được giải phóng và không tạo approval/adjustment.

### AS-UC-08-03-03 — Hàng thừa chưa có value basis
- **Bao phủ:** EF-B; BR-02/04.
- **Given:** final count cho thấy surplus và chưa có căn cứ giá trị có thẩm quyền.
- **When:** hệ thống chuẩn bị `CountAdjustmentBasis`.
- **Then:** trả `PRICE_BASIS_REQUIRED`, giữ lock và không gửi approval.

### AS-UC-08-03-04 — Recount stale
- **Bao phủ:** EF-A.
- **Given:** assignment hoặc latest round đã đổi sau khi counter mở màn hình.
- **When:** counter submit recount cũ.
- **Then:** request bị từ chối; evidence trước đó không bị sửa.

## 10. Truy vết

- **Journey:** `BJ-08` — Kiểm kê và điều chỉnh chênh lệch.
- **Domain / Entity:** `DOM-IC`, `ENT-IC-04`, `ENT-IC-05`, `ENT-IC-09`.
- **Behavioral Contract:** `BC-IC-02`.
- **Decision / Nguồn:** `T7-DR-035…039`, `T7-DR-174`, `T7-DR-176/177`.
- **Bài tri thức liên quan:** [KB-KGV-011 — Kiểm kê hàng tồn kho từ khóa phạm vi đến điều chỉnh chênh lệch](../../../01.knowledge/know-how/KB-KGV-011-kiem-ke-hang-ton-kho-tu-khoa-pham-vi-den-dieu-chinh-chenh-lech.md); [KB-KGV-021 — Sửa sai tồn kho mà không sửa lịch sử](../../../01.knowledge/know-how/KB-KGV-021-sua-sai-ton-kho-khong-sua-lich-su.md); [KB-KGV-032 — Movement ledger, số dư dẫn xuất và phục hồi sau sự cố](../../../01.knowledge/know-how/KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md)
