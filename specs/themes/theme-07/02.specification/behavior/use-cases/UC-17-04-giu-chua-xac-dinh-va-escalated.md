---
id: UC-17-04
type: use-case
theme: theme-07
title: "Giữ chưa xác định và escalated"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v3.12.0
---

# UC-17-04 — Giữ chưa xác định và escalated

## 1. Mục tiêu và kết quả nghiệp vụ

Giữ operation ở trạng thái chưa xác định có kiểm soát khi chưa đủ bằng chứng, bảo vệ phạm vi rủi ro và escalation đúng owner.

**Kết quả cần đạt:** `UNKNOWN` được giữ đúng nghĩa, scope protection/escalation có owner và điều kiện giải quyết; không có blind retry/correction.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Evidence chưa đủ hoặc có nghi ngờ nghiêm trọng

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

UNKNOWN được giữ, phạm vi được bảo vệ và escalation có owner; Controlled unresolved result.

### 2.3 Không bao gồm

Không tự biến UNKNOWN thành FAILED hoặc tạo operation identity mới. UC giữ hồ sơ ở trạng thái chưa xác định, bảo vệ phạm vi rủi ro và escalation theo policy cho tới khi có bằng chứng mới.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Nhân viên đối soát hoặc chủ sở hữu operation.
- **Thẩm quyền:** Chỉ tác nhân hoặc system process có quyền thực thi đúng scope mới được commit; mọi guard về source/version, policy và lifecycle phải được server kiểm lại trước effect.
- **Sự kiện khởi phát:** Evidence chưa đủ hoặc có nghi ngờ nghiêm trọng.
- **Điều kiện trước:** Đối tượng đúng version đã đạt trạng thái sẵn sàng thực thi; quyền, policy, lock và các invariant nguồn còn hợp lệ tại thời điểm commit.

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
| BF-01 | Nhân viên đối soát | Nhận operation vẫn UNKNOWN sau assessment/recovery hoặc có evidence nghiêm trọng. |  |
| BF-02 | Hệ thống | Xác định scope có thể chịu double-effect/rủi ro nếu tiếp tục xử lý. |  |
| BF-03 | Nhân viên đối soát/Quản lý | Áp dụng protection/escalation phù hợp và chỉ định owner/next evidence cần thu thập. | AF-A — Không cần khóa giao dịch |
| BF-04 | Hệ thống | Lưu unresolved state, evidence snapshot, protection và escalation SLA/owner. | EF-A — Kết quả cập nhật chưa xác định |
| BF-05 | Hệ thống | Chỉ cho phép mở lại assessment/continue khi có evidence mới; không tự chuyển `UNKNOWN` thành FAILED. |  |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Không cần khóa giao dịch
**Phát sinh tại:** BF-03. **Điều kiện:** Operation không thể tạo double effect cho giao dịch mới hoặc đã được cô lập ở phạm vi khác .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Nhân viên đối soát | Ghi căn cứ không khóa nhưng vẫn giữ owner/evidence plan. | |
| AF-A-02 | — | [Tiếp tục BF-04.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Kết quả cập nhật chưa xác định
**Phát sinh tại:** BF-04. **Điều kiện:** Không rõ protection/escalation metadata đã commit .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Verify case/operation state trước khi lặp update. | |
| EF-A-02 | — | [Kết thúc UC.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | UNKNOWN không phải FAILED | Timeout hoặc mất kết nối không chứng minh rằng transaction đã rollback| Decision / DOM-IC / BC nguồn |
| BR-02 | Cùng định danh | Chỉ tra cứu/tiếp tục bằng đúng định danh operation và yêu cầu; nội dung khác phải bị từ chối| Decision / DOM-IC / BC nguồn |
| BR-03 | Có bằng chứng commit | Chỉ xác lập kết quả từ tác động đã có; không ghi movement/balance/outbox lần hai| Decision / DOM-IC / BC nguồn |
| BR-04 | Có bằng chứng no-commit | Có thể tiếp tục cùng ID sau khi xác minh không tồn tại tác động bán phần| Decision / DOM-IC / BC nguồn |
| BR-05 | Chưa đủ bằng chứng | Giữ UNKNOWN và trạng thái nguồn tương ứng; không đoán kết quả để “mở đường” cho người dùng| Decision / DOM-IC / BC nguồn |
| BR-06 | Boundary liên miền | Sales/Purchase giữ trạng thái chờ theo contract của mình; Theme 7 không tự hoàn tất đơn, refund payment hoặc tạo lại receipt| Decision / DOM-IC / BC nguồn |

- `SBC-COM-01` — Bao yêu cầu và định danh.
- `BC-COMMON-EXTENSIONS` — Shared behavioral contract extensions.
- `SBC-COM-02` — Quyền, phạm vi và điều kiện cần.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `SBC-COM-04` — Finality và tính nguyên tử.
- `BC-IC-05` — Reconcile and rebuild projection.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | `UNKNOWN` được giữ đúng nghĩa, scope protection/escalation có owner và điều kiện giải quyết; không có blind retry/correction. | Hành trình tiếp tục từ kết quả authoritative vừa ghi theo Business Journey sở hữu; không suy bước tiếp theo chỉ từ thứ tự UC. |
| Không đủ điều kiện / Bị từ chối | Nếu precondition, version, quyền hoặc invariant không còn hợp lệ, hệ thống từ chối trước effect; nếu finality chưa rõ thì giữ cùng operation identity để recovery. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** `UNKNOWN` được giữ đúng nghĩa, scope protection/escalation có owner và điều kiện giải quyết; không có blind retry/correction.

## 8. Liên hệ giao diện

| Screen | Vai trò trong UC |
|---|---|
| `SCR-079` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Giữ chưa xác định và escalated”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |
| `SCR-083` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Giữ chưa xác định và escalated”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-17-04-01 — Giữ chưa xác định và escalated — luồng chính
- **Given:** Evidence chưa đủ hoặc có nghi ngờ nghiêm trọng
- **When:** Nhận operation vẫn UNKNOWN sau assessment/recovery hoặc có evidence nghiêm trọng.
- **Then:** `UNKNOWN` được giữ đúng nghĩa, scope protection/escalation có owner và điều kiện giải quyết; không có blind retry/correction.

### AS-UC-17-04-02 — Giữ chưa xác định và escalated — Không cần khóa giao dịch
- **Given:** Operation không thể tạo double effect cho giao dịch mới hoặc đã được cô lập ở phạm vi khác.
- **When:** Ghi căn cứ không khóa nhưng vẫn giữ owner/evidence plan.
- **Then:** Luồng chính tiếp tục tại BF-04: Lưu unresolved state, evidence snapshot, protection và escalation SLA/owner.

### AS-UC-17-04-03 — Giữ chưa xác định và escalated — Kết quả cập nhật chưa xác định
- **Given:** Không rõ protection/escalation metadata đã commit.
- **When:** Hệ thống phát hiện điều kiện “Kết quả cập nhật chưa xác định” tại BF-04.
- **Then:** Verify case/operation state trước khi lặp update. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

## 10. Truy vết

- **Journey:** `BJ-17` — Phục hồi nghiệp vụ có kết quả chưa xác định.
- **Domain:** `DOM-IC`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-05`.

- **Nguồn quyết định:** [Nhóm G10 — Inventory Operation, idempotency và sự kiện](../../../01.knowledge/decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh); [Nhóm G12 — Cảnh báo, phục hồi, hiệu năng và POS offline](../../../01.knowledge/decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i)
- **Bài tri thức liên quan:** [Vòng đời của một inventory operation](../../../01.knowledge/know-how/KB-KGV-027-vong-doi-cua-mot-inventory-operation.md); [Idempotency, phiên bản nguồn và xử lý kết quả chưa xác định](../../../01.knowledge/know-how/KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md); [Nhật ký biến động, số dư dẫn xuất và phục hồi sau sự cố](../../../01.knowledge/know-how/KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md)
