---
id: UC-16-03
type: use-case
theme: theme-07
title: "Điều tra và xác định nguyên nhân"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-16
---

# UC-16-03 — Điều tra và xác định nguyên nhân

## 1. Mục tiêu và kết quả nghiệp vụ

Điều tra evidence để xác định nguyên nhân sai lệch và route khắc phục đúng owner, không tự sửa ledger chỉ để làm hết chênh lệch.

**Kết quả cần đạt:** Case có kết luận sơ bộ, evidence chain và resolution route rõ: rebuild projection, correction, source fix, recovery hoặc escalation.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Case đã được phân loại

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Có kết luận sơ bộ và hướng xử lý; Investigation evidence và resolution route.

### 2.3 Không bao gồm

Không thay đổi fact nguồn trong quá trình điều tra. UC chỉ so sánh movement, projection, source và evidence để xác định nguyên nhân có thể kiểm chứng.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Nhân viên đối soát hoặc quản lý vận hành.
- **Thẩm quyền:** Chỉ tác nhân hoặc system process có quyền thực thi đúng scope mới được commit; mọi guard về source/version, policy và lifecycle phải được server kiểm lại trước effect.
- **Sự kiện khởi phát:** Case đã được phân loại.
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
| BF-01 | Nhân viên đối soát | Mở case đã phân loại và tập hợp source/version, operation result, movement ledger, projection và evidence liên quan. |  |
| BF-02 | Hệ thống | Đối chiếu các nguồn theo cùng identity/cut-off/as-of để chỉ ra điểm bất nhất. |  |
| BF-03 | Nhân viên đối soát | Xác định nguyên nhân gần nhất và phân loại route khắc phục. | AF-A — Projection sai nhưng ledger đúng<br>AF-B — Cần correction/source fix |
| BF-04 | Nhân viên đối soát | Ghi kết luận sơ bộ, evidence và owner/điều kiện xác minh sau khắc phục vào case. | EF-A — Evidence chưa đủ/ledger integrity nghiêm trọng |
| BF-05 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Projection sai nhưng ledger đúng
**Phát sinh tại:** BF-03. **Điều kiện:** Ledger authoritative khớp source nhưng read model/report sai .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Route `PROC-01` rebuild projection; không tạo movement/correction. | |
| AF-A-02 | — | [Kết thúc UC.] | |

#### AF-B — Cần correction hoặc source fix
**Phát sinh tại:** BF-03. **Điều kiện:** Authoritative transaction/source fact sai hoặc cần bút toán sửa .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-B-01 | Hệ thống | Route BJ11 hoặc owner Theme nguồn với evidence; giữ case mở để verify. | |
| AF-B-02 | — | [Kết thúc UC.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Evidence chưa đủ hoặc nghi ngờ ledger integrity
**Phát sinh tại:** BF-04. **Điều kiện:** Không thể chứng minh ledger đúng hoặc root cause đủ chắc chắn .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Giữ protection phù hợp và escalation; không tự rebuild/correct để che sai lệch. | |
| EF-A-02 | — | [Kết thúc UC với case mở.] | |

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
| Thành công | Case có kết luận sơ bộ, evidence chain và resolution route rõ: rebuild projection, correction, source fix, recovery hoặc escalation. | Hành trình tiếp tục từ kết quả authoritative vừa ghi theo Business Journey sở hữu; không suy bước tiếp theo chỉ từ thứ tự UC. |
| Không đủ điều kiện / Bị từ chối | Nếu precondition, version, quyền hoặc invariant không còn hợp lệ, hệ thống từ chối trước effect; nếu finality chưa rõ thì giữ cùng operation identity để recovery. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |

**Ảnh hưởng nghiệp vụ chính:** Case có kết luận sơ bộ, evidence chain và resolution route rõ: rebuild projection, correction, source fix, recovery hoặc escalation.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-16 — Điều tra và đối soát sai lệch](../../../03.design/flows/UIF-16-BJ-16.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-079` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Điều tra và xác định nguyên nhân”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |
| `SCR-080` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Điều tra và xác định nguyên nhân”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-16-03-01 — Điều tra và xác định nguyên nhân — luồng chính
- **Given:** Case đã được phân loại
- **When:** Mở case đã phân loại và tập hợp source/version, operation result, movement ledger, projection và evidence liên quan.
- **Then:** Case có kết luận sơ bộ, evidence chain và resolution route rõ: rebuild projection, correction, source fix, recovery hoặc escalation.

### AS-UC-16-03-02 — Điều tra và xác định nguyên nhân — Projection sai nhưng ledger đúng
- **Given:** Ledger authoritative khớp source nhưng read model/report sai.
- **When:** Hệ thống phát hiện điều kiện “Projection sai nhưng ledger đúng” tại BF-03.
- **Then:** Route `PROC-01` rebuild projection; không tạo movement/correction. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-16-03-03 — Điều tra và xác định nguyên nhân — Cần correction hoặc source fix
- **Given:** Authoritative transaction/source fact sai hoặc cần bút toán sửa.
- **When:** Hệ thống phát hiện điều kiện “Cần correction hoặc source fix” tại BF-03.
- **Then:** Route BJ11 hoặc owner Theme nguồn với evidence; giữ case mở để verify. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-16-03-04 — Điều tra và xác định nguyên nhân — Evidence chưa đủ hoặc nghi ngờ ledger integrity
- **Given:** Không thể chứng minh ledger đúng hoặc root cause đủ chắc chắn.
- **When:** Hệ thống phát hiện điều kiện “Evidence chưa đủ hoặc nghi ngờ ledger integrity” tại BF-04.
- **Then:** Giữ protection phù hợp và escalation; không tự rebuild/correct để che sai lệch. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

## 10. Truy vết

- **Journey:** `BJ-16` — Điều tra và đối soát sai lệch.
- **Domain:** `DOM-IC`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-05`.

- **Nguồn quyết định:** [Nhóm G12 — Ledger, báo cáo và đối soát](../../../01.knowledge/decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i); [Nhóm G12 — Cảnh báo, phục hồi, hiệu năng và POS offline](../../../01.knowledge/decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i)
- **Bài tri thức liên quan:** [Sửa sai tồn kho không sửa lịch sử](../../../01.knowledge/know-how/KB-KGV-021-sua-sai-ton-kho-khong-sua-lich-su.md); [Idempotency, phiên bản nguồn và xử lý kết quả chưa xác định](../../../01.knowledge/know-how/KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md); [Nhật ký biến động, số dư dẫn xuất và phục hồi sau sự cố](../../../01.knowledge/know-how/KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md); [Thẻ kho, báo cáo lịch sử và đối soát nguồn](../../../01.knowledge/know-how/KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon.md)
