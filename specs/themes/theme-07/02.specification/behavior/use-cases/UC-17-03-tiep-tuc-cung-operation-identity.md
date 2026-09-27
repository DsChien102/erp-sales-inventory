---
id: UC-17-03
type: use-case
theme: theme-07
title: "Tiếp tục cùng operation identity"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-17
---

# UC-17-03 — Tiếp tục cùng operation identity

## 1. Mục tiêu và kết quả nghiệp vụ

Tiếp tục một operation đã chứng minh chưa commit bằng đúng operation identity và payload fingerprint, để đạt finality mà không tạo giao dịch trùng.

**Kết quả cần đạt:** Cùng operation identity trả kết quả mới `COMMITTED/REJECTED` hoặc vẫn `UNKNOWN`; không tạo identity/business request thứ hai.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Có bằng chứng operation chưa commit

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Cùng operation ID trả kết quả mới hoặc vẫn UNKNOWN; Idempotent continuation dùng chung.

### 2.3 Không bao gồm

Không tạo business effect mới để “bù” cho kết quả chưa rõ; chỉ xác minh, đối soát và phục hồi trên cùng operation/command identity.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Nhân viên đối soát hoặc chủ sở hữu operation.
- **Thẩm quyền:** Chỉ tác nhân/system có quyền recovery trên đúng operation identity được xác minh trạng thái; không được tạo identity mới để né finality hoặc idempotency.
- **Sự kiện khởi phát:** Có bằng chứng operation chưa commit.
- **Điều kiện trước:** Có operation/command identity cần xác minh và đủ audit/source evidence để đối soát; tác nhân/system có quyền recovery đúng phạm vi.

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
| BF-01 | Hệ thống/Adapter | Chuẩn bị retry/continue với đúng operation identity và payload fingerprint cũ. |  |
| BF-02 | Hệ thống | Kiểm tra evidence no-commit, retry policy và payload không đổi. | EF-A — Payload/identity conflict |
| BF-03 | Hệ thống | Tiếp tục hoặc gửi lại command trong idempotency boundary của operation hiện hữu. |  |
| BF-04 | Hệ thống | Đọc finality mới: commit, reject hoặc vẫn unknown. | AF-A — Vẫn UNKNOWN |
| BF-05 | Hệ thống | Trả result và effect refs nếu có; không tạo request identity mới. |  |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Vẫn UNKNOWN
**Phát sinh tại:** BF-04. **Điều kiện:** Sau retry/continue vẫn chưa đủ bằng chứng finality..

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Giữ cùng identity và route UC-17-04 khi vượt recovery window/ngưỡng escalation. | |
| AF-A-02 | — | [Kết thúc UC.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Payload hoặc identity conflict
**Phát sinh tại:** BF-02. **Điều kiện:** Retry dùng payload khác hoặc identity không khớp operation gốc..

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Từ chối; không coi là retry và không tạo effect mới. | |
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
| Thành công | Cùng operation identity trả kết quả mới `COMMITTED/REJECTED` hoặc vẫn `UNKNOWN`; không tạo identity/business request thứ hai. | Tiếp tục recovery/escalation bằng cùng identity và evidence cho đến khi xác lập được finality hoặc owner xử lý tiếp. |
| Không đủ điều kiện / Bị từ chối | Nếu chưa đủ bằng chứng finality, giữ trạng thái chưa xác định và cùng operation identity; không blind retry, correction hoặc tạo request mới. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |

**Ảnh hưởng nghiệp vụ chính:** Cùng operation identity trả kết quả mới `COMMITTED/REJECTED` hoặc vẫn `UNKNOWN`; không tạo identity/business request thứ hai.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-17 — Phục hồi nghiệp vụ có kết quả chưa xác định](../../../03.design/flows/UIF-17-BJ-17.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-080` | Trình bày evidence/finality và hành động phục hồi an toàn cho “Tiếp tục cùng operation identity”; giữ cùng operation identity. |
| `SCR-082` | Trình bày evidence/finality và hành động phục hồi an toàn cho “Tiếp tục cùng operation identity”; giữ cùng operation identity. |
| `SCR-083` | Trình bày evidence/finality và hành động phục hồi an toàn cho “Tiếp tục cùng operation identity”; giữ cùng operation identity. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-17-03-01 — Tiếp tục cùng operation identity — luồng chính
- **Given:** Có bằng chứng operation chưa commit
- **When:** Chuẩn bị retry/continue với đúng operation identity và payload fingerprint cũ.
- **Then:** Cùng operation identity trả kết quả mới `COMMITTED/REJECTED` hoặc vẫn `UNKNOWN`; không tạo identity/business request thứ hai.

### AS-UC-17-03-02 — Tiếp tục cùng operation identity — Vẫn UNKNOWN
- **Given:** Sau retry/continue vẫn chưa đủ bằng chứng finality.
- **When:** Hệ thống phát hiện điều kiện “Vẫn UNKNOWN” tại BF-04.
- **Then:** Giữ cùng identity và route UC-17-04 khi vượt recovery window/ngưỡng escalation. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-17-03-03 — Tiếp tục cùng operation identity — Payload hoặc identity conflict
- **Given:** Retry dùng payload khác hoặc identity không khớp operation gốc.
- **When:** Hệ thống phát hiện điều kiện “Payload hoặc identity conflict” tại BF-02.
- **Then:** Từ chối; không coi là retry và không tạo effect mới. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

## 10. Truy vết

- **Journey:** `BJ-17` — Phục hồi nghiệp vụ có kết quả chưa xác định.
- **Domain:** `DOM-IC`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-05`.

- **Nguồn quyết định:** [Nhóm G10 — Inventory Operation, idempotency và sự kiện](../../../01.knowledge/decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh); [Nhóm G12 — Cảnh báo, phục hồi, hiệu năng và POS offline](../../../01.knowledge/decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i)
- **Bài tri thức liên quan:** [Vòng đời của một inventory operation](../../../01.knowledge/know-how/KB-KGV-027-vong-doi-cua-mot-inventory-operation.md); [Idempotency, phiên bản nguồn và xử lý kết quả chưa xác định](../../../01.knowledge/know-how/KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md); [Nhật ký biến động, số dư dẫn xuất và phục hồi sau sự cố](../../../01.knowledge/know-how/KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md)
