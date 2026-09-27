---
id: UC-17-02
type: use-case
theme: theme-07
title: "Xác lập operation đã hoàn tất"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-17
---

# UC-17-02 — Xác lập operation đã hoàn tất

## 1. Mục tiêu và kết quả nghiệp vụ

Xác lập operation `UNKNOWN` thành đã hoàn tất khi durable effects đã chứng minh commit, chỉ cập nhật result/finality chứ không ghi effect lần hai.

**Kết quả cần đạt:** Operation/result trở thành `COMPLETED/COMMITTED` authoritative và source consumer nhận đúng effect refs đã tồn tại.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Có bằng chứng commit đầy đủ

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Operation và nguồn nhận kết quả COMPLETED authoritative; Completed result, không ghi lại movement.

### 2.3 Không bao gồm

Không thực thi lại operation đã chứng minh commit. UC chỉ xác lập kết quả đã hoàn tất từ bằng chứng có thẩm quyền và khôi phục projection/response nếu cần.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Nhân viên đối soát hoặc chủ sở hữu operation.
- **Thẩm quyền:** Chỉ tác nhân hoặc system process có quyền thực thi đúng scope mới được commit; mọi guard về source/version, policy và lifecycle phải được server kiểm lại trước effect.
- **Sự kiện khởi phát:** Có bằng chứng commit đầy đủ.
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
| BF-01 | Hệ thống/Người xử lý | Nhận evidence assessment chứng minh commit của operation. |  |
| BF-02 | Hệ thống | Recheck effect refs thuộc đúng tenant/operation identity và không có conflict. | EF-A — Evidence không còn đủ |
| BF-03 | Hệ thống | Cập nhật operation/result finality thành completed và liên kết các effect đã tồn tại. | EF-B — Kết quả finality update chưa xác định |
| BF-04 | Hệ thống | Thông báo source/consumer; tuyệt đối không tạo lại movement/balance/outbox business effect. |  |
| BF-05 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

Không có luồng thay thế riêng ngoài các nhánh kết quả đã thể hiện trong Luồng chính.

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Evidence không còn đủ
**Phát sinh tại:** BF-02. **Điều kiện:** Effect ref bị phủ định/mâu thuẫn khi recheck .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Không xác lập completed; quay lại UC-17-01/04. | |
| EF-A-02 | — | [Kết thúc UC.] | |

#### EF-B — Kết quả finality update chưa xác định
**Phát sinh tại:** BF-03. **Điều kiện:** Không rõ metadata/result finality đã cập nhật .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Verify operation result bằng cùng identity; business effects vẫn không được ghi lại. | |
| EF-B-02 | — | [Kết thúc UC.] | |

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
| Thành công | Operation/result trở thành `COMPLETED/COMMITTED` authoritative và source consumer nhận đúng effect refs đã tồn tại. | Hành trình tiếp tục từ kết quả authoritative vừa ghi theo Business Journey sở hữu; không suy bước tiếp theo chỉ từ thứ tự UC. |
| Không đủ điều kiện / Bị từ chối | Nếu precondition, version, quyền hoặc invariant không còn hợp lệ, hệ thống từ chối trước effect; nếu finality chưa rõ thì giữ cùng operation identity để recovery. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** Operation/result trở thành `COMPLETED/COMMITTED` authoritative và source consumer nhận đúng effect refs đã tồn tại.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-17 — Phục hồi nghiệp vụ có kết quả chưa xác định](../../../03.design/flows/UIF-17-BJ-17.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-080` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Xác lập operation đã hoàn tất”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |
| `SCR-082` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Xác lập operation đã hoàn tất”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |
| `SCR-083` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Xác lập operation đã hoàn tất”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-17-02-01 — Xác lập operation đã hoàn tất — luồng chính
- **Given:** Có bằng chứng commit đầy đủ
- **When:** Nhận evidence assessment chứng minh commit của operation.
- **Then:** Operation/result trở thành `COMPLETED/COMMITTED` authoritative và source consumer nhận đúng effect refs đã tồn tại.

### AS-UC-17-02-02 — Xác lập operation đã hoàn tất — Evidence không còn đủ
- **Given:** Effect ref bị phủ định/mâu thuẫn khi recheck.
- **When:** Hệ thống phát hiện điều kiện “Evidence không còn đủ” tại BF-02.
- **Then:** Không xác lập completed; quay lại UC-17-01/04. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-17-02-03 — Xác lập operation đã hoàn tất — Kết quả finality update chưa xác định
- **Given:** Không rõ metadata/result finality đã cập nhật.
- **When:** Hệ thống phát hiện điều kiện “Kết quả finality update chưa xác định” tại BF-03.
- **Then:** Verify operation result bằng cùng identity; business effects vẫn không được ghi lại. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

## 10. Truy vết

- **Journey:** `BJ-17` — Phục hồi nghiệp vụ có kết quả chưa xác định.
- **Domain:** `DOM-IC`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-05`.

- **Nguồn quyết định:** [Nhóm G10 — Inventory Operation, idempotency và sự kiện](../../../01.knowledge/decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh); [Nhóm G12 — Cảnh báo, phục hồi, hiệu năng và POS offline](../../../01.knowledge/decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i)
- **Bài tri thức liên quan:** [Vòng đời của một inventory operation](../../../01.knowledge/know-how/KB-KGV-027-vong-doi-cua-mot-inventory-operation.md); [Idempotency, phiên bản nguồn và xử lý kết quả chưa xác định](../../../01.knowledge/know-how/KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md); [Nhật ký biến động, số dư dẫn xuất và phục hồi sau sự cố](../../../01.knowledge/know-how/KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md)
