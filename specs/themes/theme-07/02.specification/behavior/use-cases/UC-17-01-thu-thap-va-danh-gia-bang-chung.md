---
id: UC-17-01
type: use-case
theme: theme-07
title: "Thu thập và đánh giá bằng chứng"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-17
---

# UC-17-01 — Thu thập và đánh giá bằng chứng

## 1. Mục tiêu và kết quả nghiệp vụ

Thu thập và đánh giá bằng chứng finality của một operation `UNKNOWN` bằng đúng operation identity, không retry mù.

**Kết quả cần đạt:** Evidence assessment kết luận `COMMITTED`, `NO_COMMIT` hoặc vẫn `UNKNOWN` và chỉ rõ nhánh xử lý tiếp.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Operation ở trạng thái UNKNOWN

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Có kết luận commit, no-commit hoặc chưa đủ bằng chứng; Evidence assessment.

### 2.3 Không bao gồm

Không retry mutation hoặc kết luận thành công/thất bại khi chưa đủ bằng chứng. UC chỉ thu thập phiếu nhận hàng, ledger/outbox/inbox và trạng thái nguồn để đánh giá finality.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Nhân viên đối soát hoặc chủ sở hữu operation.
- **Thẩm quyền:** Chỉ được đọc đúng tenant/cửa hàng/kho/sản phẩm thuộc phạm vi được cấp; quyền xem số lượng, giá trị và dữ liệu tài chính được kiểm soát độc lập theo policy.
- **Sự kiện khởi phát:** Operation ở trạng thái UNKNOWN.
- **Điều kiện trước:** Ngữ cảnh tenant/cửa hàng/kho và quyền đọc hợp lệ; nguồn/read model cần cho truy vấn có thể xác định được `as_of`/version hoặc trả trạng thái stale rõ ràng.

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
| BF-01 | Nhân viên đối soát/Owner operation | Mở operation `UNKNOWN` bằng đúng operation/command identity. |  |
| BF-02 | Hệ thống | Thu thập idempotency record, movement/balance/outbox refs, logs/ack và source correlation có thể xác minh. |  |
| BF-03 | Hệ thống | Đánh giá bằng chứng commit/no-commit mà không suy timeout thành thất bại. | AF-A — Có bằng chứng commit<br>AF-B — Có bằng chứng no-commit |
| BF-04 | Nhân viên đối soát | Rà soát phần bằng chứng còn thiếu và kết luận assessment hiện tại. | EF-A — Bằng chứng mâu thuẫn/nghiêm trọng |
| BF-05 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Có bằng chứng commit
**Phát sinh tại:** BF-03. **Điều kiện:** Durable effects đủ để chứng minh transaction đã hoàn tất .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Route UC-17-02; không ghi movement/balance lại. | |
| AF-A-02 | — | [Kết thúc UC.] | |

#### AF-B — Có bằng chứng no-commit
**Phát sinh tại:** BF-03. **Điều kiện:** Đủ bằng chứng operation chưa tạo authoritative effect và contract cho phép tiếp tục .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-B-01 | Hệ thống | Route UC-17-03 với cùng identity/payload. | |
| AF-B-02 | — | [Kết thúc UC.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Bằng chứng mâu thuẫn hoặc nghi ngờ ledger integrity
**Phát sinh tại:** BF-04. **Điều kiện:** Evidence giữa ledger/result/source không thống nhất .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Giữ `UNKNOWN`, bảo vệ scope và route UC-17-04/BJ16; không tự chọn một nguồn để kết luận. | |
| EF-A-02 | — | [Kết thúc UC.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | UNKNOWN không phải FAILED | Timeout hoặc mất kết nối không chứng minh rằng transaction đã rollback| Decision / DOM-IC / BC nguồn |
| BR-02 | Cùng định danh | Chỉ tra cứu/tiếp tục bằng đúng định danh operation và yêu cầu; nội dung khác phải bị từ chối| Decision / DOM-IC / BC nguồn |
| BR-03 | Có bằng chứng commit | Chỉ xác lập kết quả từ tác động đã có; không ghi movement/balance/outbox lần hai| Decision / DOM-IC / BC nguồn |
| BR-04 | Có bằng chứng no-commit | Có thể tiếp tục cùng ID sau khi xác minh không tồn tại tác động bán phần| Decision / DOM-IC / BC nguồn |
| BR-05 | Chưa đủ bằng chứng | Giữ UNKNOWN và trạng thái nguồn tương ứng; không đoán kết quả để “mở đường” cho người dùng| Decision / DOM-IC / BC nguồn |
| BR-06 | Boundary liên miền | Sales/Purchase giữ trạng thái chờ theo contract của mình; Theme 7 không tự hoàn tất đơn, refund payment hoặc tạo lại phiếu nhận hàng| Decision / DOM-IC / BC nguồn |

- `SBC-COM-01` — Bao yêu cầu và định danh.
- `BC-COMMON-EXTENSIONS` — Shared behavioral contract extensions.
- `SBC-COM-02` — Quyền, phạm vi và điều kiện cần.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `SBC-COM-04` — Finality và tính nguyên tử.
- `BC-IC-05` — Reconcile and rebuild projection.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Evidence assessment kết luận `COMMITTED`, `NO_COMMIT` hoặc vẫn `UNKNOWN` và chỉ rõ nhánh xử lý tiếp. | Kết thúc tra cứu hoặc chuyển sang UC/BJ khác theo nhu cầu nghiệp vụ; UC này không ghi thay đổi authoritative. |
| Không đủ điều kiện / Bị từ chối | Nếu thiếu quyền, dữ liệu không tồn tại hoặc nguồn stale, hệ thống trả đúng trạng thái đọc/cảnh báo; không tạo mutation. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |

**Ảnh hưởng nghiệp vụ chính:** Evidence assessment kết luận `COMMITTED`, `NO_COMMIT` hoặc vẫn `UNKNOWN` và chỉ rõ nhánh xử lý tiếp.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-17 — Phục hồi nghiệp vụ có kết quả chưa xác định](../../../03.design/flows/UIF-17-BJ-17.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-078` | Trình bày dữ liệu, thời điểm và trạng thái đọc cần để “Thu thập và đánh giá bằng chứng”; không tạo mutation. |
| `SCR-079` | Trình bày dữ liệu, thời điểm và trạng thái đọc cần để “Thu thập và đánh giá bằng chứng”; không tạo mutation. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-17-01-01 — Thu thập và đánh giá bằng chứng — luồng chính
- **Given:** Operation ở trạng thái UNKNOWN
- **When:** Mở operation `UNKNOWN` bằng đúng operation/command identity.
- **Then:** Evidence assessment kết luận `COMMITTED`, `NO_COMMIT` hoặc vẫn `UNKNOWN` và chỉ rõ nhánh xử lý tiếp.

### AS-UC-17-01-02 — Thu thập và đánh giá bằng chứng — Có bằng chứng commit
- **Given:** Durable effects đủ để chứng minh transaction đã hoàn tất.
- **When:** Hệ thống phát hiện điều kiện “Có bằng chứng commit” tại BF-03.
- **Then:** Route UC-17-02; không ghi movement/balance lại. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-17-01-03 — Thu thập và đánh giá bằng chứng — Có bằng chứng no-commit
- **Given:** Đủ bằng chứng operation chưa tạo authoritative effect và contract cho phép tiếp tục.
- **When:** Hệ thống phát hiện điều kiện “Có bằng chứng no-commit” tại BF-03.
- **Then:** Route UC-17-03 với cùng identity/payload. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-17-01-04 — Thu thập và đánh giá bằng chứng — Bằng chứng mâu thuẫn hoặc nghi ngờ ledger integrity
- **Given:** Evidence giữa ledger/result/source không thống nhất.
- **When:** Hệ thống phát hiện điều kiện “Bằng chứng mâu thuẫn hoặc nghi ngờ ledger integrity” tại BF-04.
- **Then:** Giữ `UNKNOWN`, bảo vệ scope và route UC-17-04/BJ16; không tự chọn một nguồn để kết luận. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

## 10. Truy vết

- **Journey:** `BJ-17` — Phục hồi nghiệp vụ có kết quả chưa xác định.
- **Domain:** `DOM-IC`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-05`.

- **Nguồn quyết định:** [Nhóm G10 — Inventory Operation, idempotency và sự kiện](../../../01.knowledge/decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh); [Nhóm G12 — Cảnh báo, phục hồi, hiệu năng và POS offline](../../../01.knowledge/decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i)
- **Bài tri thức liên quan:** [Vòng đời của một inventory operation](../../../01.knowledge/know-how/KB-KGV-027-vong-doi-cua-mot-inventory-operation.md); [Idempotency, phiên bản nguồn và xử lý kết quả chưa xác định](../../../01.knowledge/know-how/KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md); [Nhật ký biến động, số dư dẫn xuất và phục hồi sau sự cố](../../../01.knowledge/know-how/KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md)
