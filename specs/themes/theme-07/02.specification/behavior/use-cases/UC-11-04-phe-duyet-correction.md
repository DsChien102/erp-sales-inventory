---
id: UC-11-04
type: use-case
theme: theme-07
title: "Phê duyệt correction"
owner: BA
status: FROZEN
frozen_at: v5.27.0
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-11
---

# UC-11-04 — Phê duyệt correction

## 1. Mục tiêu và kết quả nghiệp vụ

Phê duyệt hoặc từ chối correction proposal dựa trên original effect, phương án và evidence hiện hành.

**Kết quả cần đạt:** Correction proposal được duyệt sẵn sàng ghi chain hoặc bị từ chối có lý do; chưa sửa ledger.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Proposal có snapshot rủi ro

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Duyệt hoặc từ chối có lý do; Approval decision.

### 2.3 Không bao gồm

Không tự thực thi correction và không sửa operation gốc. UC chỉ ghi quyết định duyệt/từ chối phương án correction đã khóa cùng lý do/bằng chứng.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Người duyệt sửa sai. **Người duyệt** là `is_owner` hoặc vai trò `store_owner`, khác người lập. **Ngoại lệ:** cửa hàng chỉ có một chủ, nên `is_owner` lập yêu cầu sửa sai thì vẫn gửi duyệt rồi tự duyệt ở màn duyệt (không có đường ghi nhận thẳng); lịch sử ghi người duyệt "Chủ cửa hàng".
- **Thẩm quyền:** Chỉ tác nhân có quyền phê duyệt đúng policy và phạm vi mới được ra quyết định; quyết định không thay thế bước thực thi nghiệp vụ phía sau.
- **Sự kiện khởi phát:** Proposal có snapshot rủi ro.
- **Điều kiện trước:** Hồ sơ/case đúng version đang ở trạng thái chờ quyết định; tác nhân có quyền phê duyệt theo policy và đọc được snapshot/evidence làm căn cứ.

## 4. Đối tượng và dữ liệu nghiệp vụ

| Đối tượng / Dữ liệu | Ý nghĩa và yêu cầu | Nguồn |
|---|---|---|
| Nguồn nghiệp vụ và phiên bản | Định danh nguồn/đối tượng nghiệp vụ và phiên bản hiện hành cần dùng để tránh xử lý trên dữ liệu cũ. | DOM-IC / BC liên quan |
| Dữ liệu nghiệp vụ | Các dữ kiện người dùng/nguồn cung cấp cho mục tiêu của Use Case; phải tuân theo rule ở mục 6. | DOM-IC / BC liên quan |
| Phạm vi thực hiện | Tác nhân và phạm vi tenant/cửa hàng/kho mà yêu cầu được phép xử lý. | DOM-IC / BC liên quan |

## 5. Các luồng của Use Case

### 5.1 Luồng chính (Basic Flow)

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| BF-01 | Người duyệt | Mở correction proposal đang chờ duyệt. |  |
| BF-02 | Hệ thống | Kiểm tra quyền/cấp duyệt, segregation, original/correction version và proposal current. | EF-A — Không đủ quyền/stale |
| BF-03 | Người duyệt | Rà soát lý do, evidence và effect dự kiến; quyết định Duyệt/Từ chối. | AF-A — Từ chối |
| BF-04 | Hệ thống | Commit approval và khóa proposal version để UC-11-05 thực thi. | EF-B — Kết quả quyết định chưa xác định |
| BF-05 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Từ chối
**Phát sinh tại:** BF-03. **Điều kiện:** Người duyệt không chấp thuận phương án .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Người duyệt | Ghi lý do từ chối. | |
| AF-A-02 | — | [Hệ thống commit rejection; kết thúc UC.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Không đủ quyền hoặc stale
**Phát sinh tại:** BF-02. **Điều kiện:** Quyền/segregation không hợp lệ hoặc original/proposal đã đổi .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Không cho quyết định trên snapshot cũ. | |
| EF-A-02 | — | [Kết thúc UC.] | |

#### EF-B — Kết quả quyết định chưa xác định
**Phát sinh tại:** BF-04. **Điều kiện:** Không rõ decision đã commit .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Verify same decision identity; không ghi đè quyết định đầu tiên. | |
| EF-B-02 | — | [Kết thúc/hand-off recovery.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Hủy trước thực thi | Chỉ DRAFT, PENDING_APPROVAL hoặc READY được hủy; cancellation không tạo movement/value| Decision / DOM-IC / BC nguồn |
| BR-02 | UNKNOWN | Không đảo hoặc thay thế khi chưa xác lập finality; phải đối soát bằng cùng operation ID| Decision / DOM-IC / BC nguồn |
| BR-03 | Operation hoàn tất | Không sửa payload/result; tạo operation mới trong correction chain| Decision / DOM-IC / BC nguồn |
| BR-04 | Dependency | Chặn reversal nếu làm âm tồn hoặc dependency chưa được trung hòa; không giả lập trung hòa bằng sửa số dư| Decision / DOM-IC / BC nguồn |
| BR-05 | Delta hay full reversal | Dùng delta khi chỉ phần sai có thể sửa độc lập và giữ đúng nguồn; dùng reversal + replacement khi toàn operation mất hiệu lực hoặc payload đúng phải được xác lập lại nguyên khối| Decision / DOM-IC / BC nguồn |
| BR-06 | Hàng thực quay về | Sale Issue đã bàn giao chỉ tăng tồn qua BJ-06; cancellation/correction không thay thế việc nhận hàng thực tế| Decision / DOM-IC / BC nguồn |
| BR-K2 | Người duyệt và tự duyệt | Người duyệt là `is_owner` hoặc vai trò `store_owner`, khác người lập. Ngoại lệ: cửa hàng chỉ có một chủ, nên `is_owner` lập yêu cầu sửa sai thì vẫn gửi duyệt rồi tự duyệt ở màn duyệt (không có đường ghi nhận thẳng); lịch sử ghi người duyệt "Chủ cửa hàng". | Decision K2 / T7-P |

- `SBC-COM-01` — Bao yêu cầu và định danh.
- `BC-COMMON-EXTENSIONS` — Shared behavioral contract extensions.
- `SBC-COM-02` — Quyền, phạm vi và điều kiện cần.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `SBC-COM-04` — Finality và tính nguyên tử.
- `BC-IC-06` — Decide approval.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Correction proposal được duyệt sẵn sàng ghi chain hoặc bị từ chối có lý do; chưa sửa ledger. | Chỉ kết quả phê duyệt hợp lệ mới cho phép bước thực thi tiếp theo; từ chối kết thúc hoặc trả hồ sơ theo lifecycle nguồn. |
| Không đủ điều kiện / Bị từ chối | Nếu bị từ chối, stale hoặc sai quyền/segregation, quyết định không làm phát sinh effect nghiệp vụ ngoài approval result đã được phép ghi. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** Correction proposal được duyệt sẵn sàng ghi chain hoặc bị từ chối có lý do; chưa sửa ledger.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-11 — Hủy và sửa sai nghiệp vụ kho](../../../03.design/flows/UIF-11-BJ-11.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-051` | Trình bày basis/evidence và hành động ra quyết định của “Phê duyệt correction”; không tự thực thi effect sau duyệt. |
| `SCR-053` | Trình bày basis/evidence và hành động ra quyết định của “Phê duyệt correction”; không tự thực thi effect sau duyệt. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-11-04-01 — Phê duyệt correction — luồng chính
- **Given:** Proposal có snapshot rủi ro
- **When:** Mở correction proposal đang chờ duyệt.
- **Then:** Correction proposal được duyệt sẵn sàng ghi chain hoặc bị từ chối có lý do; chưa sửa ledger.

### AS-UC-11-04-02 — Phê duyệt correction — Từ chối
- **Given:** Người duyệt không chấp thuận phương án.
- **When:** Ghi lý do từ chối.
- **Then:** UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-11-04-03 — Phê duyệt correction — Không đủ quyền hoặc stale
- **Given:** Quyền/segregation không hợp lệ hoặc original/proposal đã đổi.
- **When:** Hệ thống phát hiện điều kiện “Không đủ quyền hoặc stale” tại BF-02.
- **Then:** Không cho quyết định trên snapshot cũ. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-11-04-04 — Phê duyệt correction — Kết quả quyết định chưa xác định
- **Given:** Không rõ decision đã commit.
- **When:** Hệ thống phát hiện điều kiện “Kết quả quyết định chưa xác định” tại BF-04.
- **Then:** Verify same decision identity; không ghi đè quyết định đầu tiên. Giữ nguyên identity/evidence hiện có và bàn giao recovery/finality; không tạo effect trùng hoặc thử lại mù.

## 10. Truy vết

- **Journey:** `BJ-11` — Hủy và sửa sai nghiệp vụ kho.
- **Domain:** `DOM-IC`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-06`.

- **Nguồn quyết định:** [Nhóm G08 — Sửa sai, reversal và kỳ khóa](../../../01.knowledge/decisions/decision-register.md#38-g08-s%E1%BB%ADa-sai-v%C3%A0-ho%C3%A0n-nguy%C3%AAn); [Nhóm G10 — Inventory Operation, idempotency và sự kiện](../../../01.knowledge/decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh)
- **Bài tri thức liên quan:** [Sửa sai tồn kho mà không sửa lịch sử](../../../01.knowledge/know-how/KB-KGV-021-sua-sai-ton-kho-khong-sua-lich-su.md); [Vòng đời của một Inventory Operation](../../../01.knowledge/know-how/KB-KGV-027-vong-doi-cua-mot-inventory-operation.md); [Idempotency, phiên bản nguồn và xử lý kết quả chưa xác định](../../../01.knowledge/know-how/KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md)
