---
id: UC-11-05
type: use-case
theme: theme-07
title: "Ghi correction chain"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v3.12.0
---

# UC-11-05 — Ghi correction chain

## 1. Mục tiêu và kết quả nghiệp vụ

Ghi correction chain bất biến cho proposal đã được phép, tạo đúng effect đảo/điều chỉnh mà không sửa transaction gốc.

**Kết quả cần đạt:** Correction operation và các movement/value/state effects commit nguyên tử, liên kết rõ original→correction.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Proposal được duyệt và vẫn khả thi

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Operation bù/thay thế cùng liên kết được commit hoặc không có gì commit; Immutable correction chain.

### 2.3 Không bao gồm

Không update/delete movement lịch sử. UC chỉ append reversal/correction mới theo chain đã duyệt và giữ liên kết đầy đủ với operation bị sửa sai.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Người vận hành kho và người duyệt sửa sai.
- **Thẩm quyền:** Chỉ tác nhân hoặc system process có quyền thực thi đúng scope mới được commit; mọi guard về source/version, policy và lifecycle phải được server kiểm lại trước effect.
- **Sự kiện khởi phát:** Proposal được duyệt và vẫn khả thi.
- **Điều kiện trước:** Đối tượng đúng version đã đạt trạng thái sẵn sàng thực thi; quyền, policy, lock và các invariant nguồn còn hợp lệ tại thời điểm commit.

## 4. Đối tượng và dữ liệu nghiệp vụ

| Đối tượng / Dữ liệu | Ý nghĩa và yêu cầu | Nguồn |
|---|---|---|
| Nguồn nghiệp vụ và phiên bản | Định danh nguồn/đối tượng nghiệp vụ và phiên bản hiện hành cần dùng để tránh xử lý trên dữ liệu cũ. | DOM-IO / BC liên quan |
| Dữ liệu nghiệp vụ | Các dữ kiện người dùng/nguồn cung cấp cho mục tiêu của Use Case; phải tuân theo rule ở mục 6. | DOM-IO / BC liên quan |
| Phạm vi thực hiện | Tác nhân và phạm vi tenant/cửa hàng/kho mà yêu cầu được phép xử lý. | DOM-IO / BC liên quan |

## 5. Các luồng của Use Case

### 5.1 Luồng chính (Basic Flow)

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| BF-01 | Hệ thống | Nhận correction proposal đã được phép thực thi. |  |
| BF-02 | Hệ thống | Recheck original effect, correction chain, proposal version và current balance/state trong transaction. | EF-A — Stale/conflict |
| BF-03 | Hệ thống | Ghi correction operation cùng reversal/adjustment effects theo plan; giữ reference tới original. |  |
| BF-04 | Hệ thống | Cập nhật balance/projection trigger/outbox và audit trong cùng atomic boundary. | EF-B — Kết quả commit chưa xác định |
| BF-05 | Hệ thống | Trả correction result và dirty scope cho BJ14 nếu value/cost bị ảnh hưởng. |  |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

Không có luồng thay thế riêng ngoài các nhánh kết quả đã thể hiện trong Luồng chính.

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Stale hoặc conflict
**Phát sinh tại:** BF-02. **Điều kiện:** Original/correction chain/balance đã thay đổi sau khi proposal được duyệt .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Reject trước effect và yêu cầu lập/duyệt successor proposal. | |
| EF-A-02 | — | [Kết thúc UC.] | |

#### EF-B — Kết quả commit chưa xác định
**Phát sinh tại:** BF-04. **Điều kiện:** Không rõ correction transaction đã commit .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Giữ operation identity, verify/BJ17 trước retry. | |
| EF-B-02 | — | [Kết thúc UC.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Hủy trước thực thi | Chỉ DRAFT, PENDING_APPROVAL hoặc READY được hủy; cancellation không tạo movement/value| Decision / DOM-IO / BC nguồn |
| BR-02 | UNKNOWN | Không đảo hoặc thay thế khi chưa xác lập finality; phải đối soát bằng cùng operation ID| Decision / DOM-IO / BC nguồn |
| BR-03 | Operation hoàn tất | Không sửa payload/result; tạo operation mới trong correction chain| Decision / DOM-IO / BC nguồn |
| BR-04 | Dependency | Chặn reversal nếu làm âm tồn hoặc dependency chưa được trung hòa; không giả lập trung hòa bằng sửa số dư| Decision / DOM-IO / BC nguồn |
| BR-05 | Delta hay full reversal | Dùng delta khi chỉ phần sai có thể sửa độc lập và giữ đúng nguồn; dùng reversal + replacement khi toàn operation mất hiệu lực hoặc payload đúng phải được xác lập lại nguyên khối| Decision / DOM-IO / BC nguồn |
| BR-06 | Hàng thực quay về | Sale Issue đã bàn giao chỉ tăng tồn qua BJ-06; cancellation/correction không thay thế việc nhận hàng thực tế| Decision / DOM-IO / BC nguồn |

- `SBC-COM-01` — Bao yêu cầu và định danh.
- `BC-COMMON-EXTENSIONS` — Shared behavioral contract extensions.
- `SBC-COM-02` — Quyền, phạm vi và điều kiện cần.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `SBC-COM-04` — Finality và tính nguyên tử.
- `BC-IO-13` — Reverse or correct completed operation.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Correction operation và các movement/value/state effects commit nguyên tử, liên kết rõ original→correction. | Hành trình tiếp tục từ kết quả authoritative vừa ghi theo Business Journey sở hữu; không suy bước tiếp theo chỉ từ thứ tự UC. |
| Không đủ điều kiện / Bị từ chối | Nếu precondition, version, quyền hoặc invariant không còn hợp lệ, hệ thống từ chối trước effect; nếu finality chưa rõ thì giữ cùng operation identity để recovery. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** Correction operation và các movement/value/state effects commit nguyên tử, liên kết rõ original→correction.

## 8. Liên hệ giao diện

| Screen | Vai trò trong UC |
|---|---|
| `SCR-049` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Ghi correction chain”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |
| `SCR-053` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Ghi correction chain”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-11-05-01 — Ghi correction chain — luồng chính
- **Given:** Proposal được duyệt và vẫn khả thi
- **When:** Nhận correction proposal đã được phép thực thi.
- **Then:** Correction operation và các movement/value/state effects commit nguyên tử, liên kết rõ original→correction.

### AS-UC-11-05-02 — Ghi correction chain — Stale hoặc conflict
- **Given:** Original/correction chain/balance đã thay đổi sau khi proposal được duyệt.
- **When:** Hệ thống phát hiện điều kiện “Stale hoặc conflict” tại BF-02.
- **Then:** Reject trước effect và yêu cầu lập/duyệt successor proposal. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-11-05-03 — Ghi correction chain — Kết quả commit chưa xác định
- **Given:** Không rõ correction transaction đã commit.
- **When:** Hệ thống phát hiện điều kiện “Kết quả commit chưa xác định” tại BF-04.
- **Then:** Giữ operation identity, verify/BJ17 trước retry. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

## 10. Truy vết

- **Journey:** `BJ-11` — Hủy và sửa sai nghiệp vụ kho.
- **Domain:** `DOM-IO`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-13`.

- **Nguồn quyết định:** [Nhóm G08 — Sửa sai, reversal và kỳ khóa](../../../01.knowledge/decisions/decision-register.md#38-g08-s%E1%BB%ADa-sai-v%C3%A0-ho%C3%A0n-nguy%C3%AAn); [Nhóm G10 — Inventory Operation, idempotency và sự kiện](../../../01.knowledge/decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh)
- **Bài tri thức liên quan:** [Sửa sai tồn kho mà không sửa lịch sử](../../../01.knowledge/know-how/KB-KGV-021-sua-sai-ton-kho-khong-sua-lich-su.md); [Vòng đời của một Inventory Operation](../../../01.knowledge/know-how/KB-KGV-027-vong-doi-cua-mot-inventory-operation.md); [Idempotency, phiên bản nguồn và xử lý kết quả chưa xác định](../../../01.knowledge/know-how/KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md)
