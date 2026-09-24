---
id: UC-16-01
type: use-case
theme: theme-07
title: "Mở và phân loại hồ sơ đối soát"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v3.12.0
---

# UC-16-01 — Mở và phân loại hồ sơ đối soát

## 1. Mục tiêu và kết quả nghiệp vụ

Mở hoặc liên kết hồ sơ đối soát khi có tín hiệu sai lệch, phân loại loại sai lệch và phạm vi mà không tạo case trùng.

**Kết quả cần đạt:** Một Reconciliation Case current có loại, mức độ, owner, evidence ban đầu và scope rõ.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Có tín hiệu sai lệch

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Case được tạo/liên kết và có loại, mức độ, người xử lý, phạm vi; Reconciliation Case không trùng.

### 2.3 Không bao gồm

Không sửa ledger/read model ngay khi phát hiện sai lệch. UC chỉ mở hồ sơ, khóa phạm vi điều tra cần thiết và phân loại triệu chứng để tiếp tục xử lý.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Nhân viên đối soát hoặc quản lý vận hành.
- **Thẩm quyền:** Chỉ tác nhân hoặc system process có quyền thực thi đúng scope mới được commit; mọi guard về source/version, policy và lifecycle phải được server kiểm lại trước effect.
- **Sự kiện khởi phát:** Có tín hiệu sai lệch.
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
| BF-01 | Nhân viên đối soát/Hệ thống | Tiếp nhận tín hiệu sai lệch từ report, reconcile check, người dùng hoặc recovery. |  |
| BF-02 | Hệ thống | Tìm case active cùng loại + phạm vi để chống tạo hồ sơ song song. | AF-A — Đã có case active |
| BF-03 | Nhân viên đối soát | Phân loại sơ bộ: source mismatch, UNKNOWN, projection mismatch, correction cần thiết hoặc nghi ngờ ledger integrity. |  |
| BF-04 | Hệ thống | Tạo case mới với owner/severity/scope/evidence ban đầu nếu chưa có case phù hợp. | EF-A — Kết quả tạo case chưa xác định |
| BF-05 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Đã có case active
**Phát sinh tại:** BF-02. **Điều kiện:** Đã tồn tại case active cùng loại/phạm vi .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Liên kết evidence/tín hiệu mới vào case hiện hành thay vì tạo duplicate. | |
| AF-A-02 | — | [Kết thúc UC với case hiện hành.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Kết quả tạo case chưa xác định
**Phát sinh tại:** BF-04. **Điều kiện:** Không rõ case đã commit .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Verify case key/identity trước khi tạo lại. | |
| EF-A-02 | — | [Kết thúc/hand-off recovery.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Chống hồ sơ trùng | Cùng loại sai lệch và cùng phạm vi đang có case hoạt động thì liên kết evidence mới, không tạo case song song vô nghĩa| Decision / DOM-IC / BC nguồn |
| BR-02 | Phân loại nguyên nhân | Phải phân biệt source mismatch, UNKNOWN, projection mismatch, correction cần thiết và nghi ngờ ledger integrity| Decision / DOM-IC / BC nguồn |
| BR-03 | Rebuild | Chỉ route sang PROC-01 khi đã chứng minh ledger đúng và dữ liệu dẫn xuất sai; không phải case nào cũng rebuild| Decision / DOM-IC / BC nguồn |
| BR-04 | Bảo vệ phạm vi | Chỉ khóa phạm vi cần thiết; lock có owner, lý do và điều kiện mở rõ ràng| Decision / DOM-IC / BC nguồn |
| BR-05 | Đóng hồ sơ | Chỉ đóng khi evidence chứng minh kết quả và các tác động cần thiết đã hoàn tất; case có thể reopen nếu evidence mới phủ định kết luận cũ| Decision / DOM-IC / BC nguồn |
| BR-06 | Ledger integrity | Khi nghi ngờ ledger, dừng rebuild/correction tự động và escalated; không dựng ledger từ báo cáo hoặc chứng từ nguồn để che lỗi| Decision / DOM-IC / BC nguồn |

- `SBC-COM-01` — Bao yêu cầu và định danh.
- `BC-COMMON-EXTENSIONS` — Shared behavioral contract extensions.
- `SBC-COM-02` — Quyền, phạm vi và điều kiện cần.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `SBC-COM-04` — Finality và tính nguyên tử.
- `BC-IC-05` — Reconcile and rebuild projection.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Một Reconciliation Case current có loại, mức độ, owner, evidence ban đầu và scope rõ. | Hành trình tiếp tục từ kết quả authoritative vừa ghi theo Business Journey sở hữu; không suy bước tiếp theo chỉ từ thứ tự UC. |
| Không đủ điều kiện / Bị từ chối | Nếu precondition, version, quyền hoặc invariant không còn hợp lệ, hệ thống từ chối trước effect; nếu finality chưa rõ thì giữ cùng operation identity để recovery. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** Một Reconciliation Case current có loại, mức độ, owner, evidence ban đầu và scope rõ.

## 8. Liên hệ giao diện

| Screen | Vai trò trong UC |
|---|---|
| `SCR-078` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Mở và phân loại hồ sơ đối soát”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-16-01-01 — Mở và phân loại hồ sơ đối soát — luồng chính
- **Given:** Có tín hiệu sai lệch
- **When:** Tiếp nhận tín hiệu sai lệch từ report, reconcile check, người dùng hoặc recovery.
- **Then:** Một Reconciliation Case current có loại, mức độ, owner, evidence ban đầu và scope rõ.

### AS-UC-16-01-02 — Mở và phân loại hồ sơ đối soát — Đã có case active
- **Given:** Đã tồn tại case active cùng loại/phạm vi.
- **When:** Hệ thống phát hiện điều kiện “Đã có case active” tại BF-02.
- **Then:** Liên kết evidence/tín hiệu mới vào case hiện hành thay vì tạo duplicate. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-16-01-03 — Mở và phân loại hồ sơ đối soát — Kết quả tạo case chưa xác định
- **Given:** Không rõ case đã commit.
- **When:** Hệ thống phát hiện điều kiện “Kết quả tạo case chưa xác định” tại BF-04.
- **Then:** Verify case key/identity trước khi tạo lại. Giữ nguyên identity/evidence hiện có và bàn giao recovery/finality; không tạo effect trùng hoặc thử lại mù.

## 10. Truy vết

- **Journey:** `BJ-16` — Điều tra và đối soát sai lệch.
- **Domain:** `DOM-IC`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-05`.

- **Nguồn quyết định:** [Nhóm G12 — Ledger, báo cáo và đối soát](../../../01.knowledge/decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i); [Nhóm G12 — Cảnh báo, phục hồi, hiệu năng và POS offline](../../../01.knowledge/decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i)
- **Bài tri thức liên quan:** [Sửa sai tồn kho không sửa lịch sử](../../../01.knowledge/know-how/KB-KGV-021-sua-sai-ton-kho-khong-sua-lich-su.md); [Idempotency, phiên bản nguồn và xử lý kết quả chưa xác định](../../../01.knowledge/know-how/KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md); [Nhật ký biến động, số dư dẫn xuất và phục hồi sau sự cố](../../../01.knowledge/know-how/KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md); [Thẻ kho, báo cáo lịch sử và đối soát nguồn](../../../01.knowledge/know-how/KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon.md)
