---
id: UC-16-04
type: use-case
theme: theme-07
title: "Xác minh và cập nhật kết quả đối soát"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v3.12.0
---

# UC-16-04 — Xác minh và cập nhật kết quả đối soát

## 1. Mục tiêu và kết quả nghiệp vụ

Xác minh evidence sau khắc phục và cập nhật Reconciliation Case thành đóng, tiếp tục mở hoặc mở lại; đồng thời xử lý scope protection đúng điều kiện.

**Kết quả cần đạt:** Case state phản ánh đúng tình trạng đã khắc phục, evidence cuối và lock/protection; không đóng chỉ vì số chênh lệch tạm thời bằng 0.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Có kết luận hoặc evidence từ hành trình được bàn giao

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Case đóng/mở lại/giữ mở và lock được xử lý đúng; Authoritative case result.

### 2.3 Không bao gồm

Không đóng hồ sơ chỉ vì số liệu tạm thời trùng nhau. UC chỉ xác nhận nguyên nhân/kết quả đã có bằng chứng, cập nhật trạng thái hồ sơ và chỉ dẫn correction/rebuild phù hợp.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Nhân viên đối soát hoặc quản lý vận hành.
- **Thẩm quyền:** Chỉ tác nhân hoặc system process có quyền thực thi đúng scope mới được commit; mọi guard về source/version, policy và lifecycle phải được server kiểm lại trước effect.
- **Sự kiện khởi phát:** Có kết luận hoặc evidence từ hành trình được bàn giao.
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
| BF-01 | Nhân viên đối soát | Nhận evidence/kết quả từ procedure, BJ11, BJ17 hoặc Theme nguồn đã được route. |  |
| BF-02 | Hệ thống | Đối chiếu lại authoritative source, ledger/projection và điều kiện closure của case. | AF-A — Chưa đạt điều kiện đóng |
| BF-03 | Nhân viên đối soát | Xác nhận resolution evidence và kết luận đóng/giữ mở/mở lại. |  |
| BF-04 | Hệ thống | Cập nhật case state và giải protection chỉ khi exit condition đã đạt. | EF-A — Kết quả cập nhật chưa xác định |
| BF-05 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Chưa đạt điều kiện đóng
**Phát sinh tại:** BF-02. **Điều kiện:** Chênh lệch còn tồn tại, evidence chưa đủ hoặc correction/rebuild chưa final .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Giữ case/protection cần thiết và route tiếp owner. | |
| AF-A-02 | — | [Kết thúc UC với case mở.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Kết quả cập nhật chưa xác định
**Phát sinh tại:** BF-04. **Điều kiện:** Không rõ case/lock state đã commit .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Verify case version/protection state trước retry. | |
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
| Thành công | Case state phản ánh đúng tình trạng đã khắc phục, evidence cuối và lock/protection; không đóng chỉ vì số chênh lệch tạm thời bằng 0. | Hành trình tiếp tục từ kết quả authoritative vừa ghi theo Business Journey sở hữu; không suy bước tiếp theo chỉ từ thứ tự UC. |
| Không đủ điều kiện / Bị từ chối | Nếu precondition, version, quyền hoặc invariant không còn hợp lệ, hệ thống từ chối trước effect; nếu finality chưa rõ thì giữ cùng operation identity để recovery. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** Case state phản ánh đúng tình trạng đã khắc phục, evidence cuối và lock/protection; không đóng chỉ vì số chênh lệch tạm thời bằng 0.

## 8. Liên hệ giao diện

| Screen | Vai trò trong UC |
|---|---|
| `SCR-082` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Xác minh và cập nhật kết quả đối soát”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |
| `SCR-083` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Xác minh và cập nhật kết quả đối soát”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-16-04-01 — Xác minh và cập nhật kết quả đối soát — luồng chính
- **Given:** Có kết luận hoặc evidence từ hành trình được bàn giao
- **When:** Nhận evidence/kết quả từ procedure, BJ11, BJ17 hoặc Theme nguồn đã được route.
- **Then:** Case state phản ánh đúng tình trạng đã khắc phục, evidence cuối và lock/protection; không đóng chỉ vì số chênh lệch tạm thời bằng 0.

### AS-UC-16-04-02 — Xác minh và cập nhật kết quả đối soát — Chưa đạt điều kiện đóng
- **Given:** Chênh lệch còn tồn tại, evidence chưa đủ hoặc correction/rebuild chưa final.
- **When:** Hệ thống phát hiện điều kiện “Chưa đạt điều kiện đóng” tại BF-02.
- **Then:** Giữ case/protection cần thiết và route tiếp owner. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-16-04-03 — Xác minh và cập nhật kết quả đối soát — Kết quả cập nhật chưa xác định
- **Given:** Không rõ case/lock state đã commit.
- **When:** Hệ thống phát hiện điều kiện “Kết quả cập nhật chưa xác định” tại BF-04.
- **Then:** Verify case version/protection state trước retry. Giữ nguyên identity/evidence hiện có và bàn giao recovery/finality; không tạo effect trùng hoặc thử lại mù.

## 10. Truy vết

- **Journey:** `BJ-16` — Điều tra và đối soát sai lệch.
- **Domain:** `DOM-IC`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-05`.

- **Nguồn quyết định:** [Nhóm G12 — Ledger, báo cáo và đối soát](../../../01.knowledge/decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i); [Nhóm G12 — Cảnh báo, phục hồi, hiệu năng và POS offline](../../../01.knowledge/decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i)
- **Bài tri thức liên quan:** [Sửa sai tồn kho không sửa lịch sử](../../../01.knowledge/know-how/KB-KGV-021-sua-sai-ton-kho-khong-sua-lich-su.md); [Idempotency, phiên bản nguồn và xử lý kết quả chưa xác định](../../../01.knowledge/know-how/KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md); [Nhật ký biến động, số dư dẫn xuất và phục hồi sau sự cố](../../../01.knowledge/know-how/KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md); [Thẻ kho, báo cáo lịch sử và đối soát nguồn](../../../01.knowledge/know-how/KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon.md)
