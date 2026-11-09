---
id: UC-11-01
type: use-case
theme: theme-07
title: "Xác định đường xử lý"
owner: BA
status: FROZEN
frozen_at: v5.27.0
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-11
---

# UC-11-01 — Xác định đường xử lý

## 1. Mục tiêu và kết quả nghiệp vụ

Phân loại một yêu cầu sửa sai để chọn đúng đường xử lý: hủy operation chưa thực thi, correction bất biến, hoặc đối soát/recovery.

**Kết quả cần đạt:** Đường xử lý và owner tiếp theo được xác định; chưa sửa transaction/ledger.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Có operation và yêu cầu hủy/sửa

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Chọn cancel, reconcile, correction hoặc không có tác động để đảo; Treatment route.

### 2.3 Không bao gồm

Không sửa trực tiếp operation đã final và không tự chọn correction khi chỉ cần hủy draft. UC chỉ phân loại tình huống để đi đúng đường hủy, reversal/correction hoặc recovery.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Người vận hành kho và người duyệt sửa sai.
- **Thẩm quyền:** Chỉ được đọc đúng tenant/cửa hàng/kho/sản phẩm thuộc phạm vi được cấp; quyền xem số lượng, giá trị và dữ liệu tài chính được kiểm soát độc lập theo policy.
- **Sự kiện khởi phát:** Có operation và yêu cầu hủy/sửa.
- **Điều kiện trước:** Ngữ cảnh tenant/cửa hàng/kho và quyền đọc hợp lệ; nguồn/read model cần cho truy vấn có thể xác định được `as_of`/version hoặc trả trạng thái stale rõ ràng.

## 4. Đối tượng và dữ liệu nghiệp vụ

| Đối tượng / Dữ liệu | Ý nghĩa và yêu cầu | Nguồn |
|---|---|---|
| Nguồn nghiệp vụ và phiên bản | Định danh nguồn/đối tượng nghiệp vụ và phiên bản hiện hành cần dùng để tránh xử lý trên dữ liệu cũ. | DOM-IO / DOM-IC / BC liên quan |
| Dữ liệu nghiệp vụ | Các dữ kiện người dùng/nguồn cung cấp cho mục tiêu của Use Case; phải tuân theo rule ở mục 6. | DOM-IO / DOM-IC / BC liên quan |
| Phạm vi thực hiện | Tác nhân và phạm vi tenant/cửa hàng/kho mà yêu cầu được phép xử lý. | DOM-IO / DOM-IC / BC liên quan |

## 5. Các luồng của Use Case

### 5.1 Luồng chính (Basic Flow)

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| BF-01 | Người vận hành/Người xử lý | Mở giao dịch/sự cố cần sửa và nêu vấn đề cần khắc phục. |  |
| BF-02 | Hệ thống | Đọc operation status/finality, effect refs và các correction/reversal đã tồn tại. |  |
| BF-03 | Hệ thống | Phân loại: chưa thực thi có thể hủy; đã commit cần correction; UNKNOWN đi BJ17; nghi ngờ sai lệch/ledger đi BJ16. | AF-A — UNKNOWN<br>AF-B — Cần đối soát |
| BF-04 | Hệ thống | Trả đường xử lý canonical và dữ liệu cần bàn giao; không sửa lịch sử tại UC này. |  |
| BF-05 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Operation còn UNKNOWN
**Phát sinh tại:** BF-03. **Điều kiện:** Không đủ bằng chứng commit/no-commit .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Bàn giao BJ17 với cùng operation identity; không hủy hay correction vội. | |
| AF-A-02 | — | [Kết thúc UC.] | |

#### AF-B — Cần đối soát
**Phát sinh tại:** BF-03. **Điều kiện:** Có dấu hiệu projection/ledger/source mismatch chưa đủ để chọn correction .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-B-01 | Hệ thống | Bàn giao BJ16 với evidence hiện có. | |
| AF-B-02 | — | [Kết thúc UC.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

Không có ngoại lệ riêng ngoài lỗi quyền/phạm vi/nguồn được Behavioral Contract dùng chung xử lý.

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Hủy trước thực thi | Chỉ DRAFT, PENDING_APPROVAL hoặc READY được hủy; cancellation không tạo movement/value| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-02 | UNKNOWN | Không đảo hoặc thay thế khi chưa xác lập finality; phải đối soát bằng cùng operation ID| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-03 | Operation hoàn tất | Không sửa payload/result; tạo operation mới trong correction chain| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-04 | Dependency | Chặn reversal nếu làm âm tồn hoặc dependency chưa được trung hòa; không giả lập trung hòa bằng sửa số dư| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-05 | Delta hay full reversal | Dùng delta khi chỉ phần sai có thể sửa độc lập và giữ đúng nguồn; dùng reversal + replacement khi toàn operation mất hiệu lực hoặc payload đúng phải được xác lập lại nguyên khối| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-06 | Hàng thực quay về | Sale Issue đã bàn giao chỉ tăng tồn qua BJ-06; cancellation/correction không thay thế việc nhận hàng thực tế| Decision / DOM-IO / DOM-IC / BC nguồn |

- `SBC-COM-01` — Bao yêu cầu và định danh.
- `BC-COMMON-EXTENSIONS` — Shared behavioral contract extensions.
- `SBC-COM-02` — Quyền, phạm vi và điều kiện cần.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `SBC-COM-04` — Finality và tính nguyên tử.
- `BC-IO-16` — Maintain operation draft.
- `BC-IC-07` — Submit inventory operation.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Đường xử lý và owner tiếp theo được xác định; chưa sửa transaction/ledger. | Kết thúc tra cứu hoặc chuyển sang UC/BJ khác theo nhu cầu nghiệp vụ; UC này không ghi thay đổi authoritative. |
| Không đủ điều kiện / Bị từ chối | Nếu thiếu quyền, dữ liệu không tồn tại hoặc nguồn stale, hệ thống trả đúng trạng thái đọc/cảnh báo; không tạo mutation. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |

**Ảnh hưởng nghiệp vụ chính:** Đường xử lý và owner tiếp theo được xác định; chưa sửa transaction/ledger.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-11 — Hủy và sửa sai nghiệp vụ kho](../../../03.design/flows/UIF-11-BJ-11.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-048` | Trình bày dữ liệu, thời điểm và trạng thái đọc cần để “Xác định đường xử lý”; không tạo mutation. |
| `SCR-049` | Trình bày dữ liệu, thời điểm và trạng thái đọc cần để “Xác định đường xử lý”; không tạo mutation. |
| `SCR-050` | Trình bày dữ liệu, thời điểm và trạng thái đọc cần để “Xác định đường xử lý”; không tạo mutation. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-11-01-01 — Xác định đường xử lý — luồng chính
- **Given:** Có operation và yêu cầu hủy/sửa
- **When:** Mở giao dịch/sự cố cần sửa và nêu vấn đề cần khắc phục.
- **Then:** Đường xử lý và owner tiếp theo được xác định; chưa sửa transaction/ledger.

### AS-UC-11-01-02 — Xác định đường xử lý — Operation còn UNKNOWN
- **Given:** Không đủ bằng chứng commit/no-commit.
- **When:** Hệ thống phát hiện điều kiện “Operation còn UNKNOWN” tại BF-03.
- **Then:** Bàn giao BJ17 với cùng operation identity; không hủy hay correction vội. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-11-01-03 — Xác định đường xử lý — Cần đối soát
- **Given:** Có dấu hiệu projection/ledger/source mismatch chưa đủ để chọn correction.
- **When:** Hệ thống phát hiện điều kiện “Cần đối soát” tại BF-03.
- **Then:** Bàn giao BJ16 với evidence hiện có. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

## 10. Truy vết

- **Journey:** `BJ-11` — Hủy và sửa sai nghiệp vụ kho.
- **Domain:** `DOM-IO`, `DOM-IC`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-16`, `BC-IC-07`.

- **Nguồn quyết định:** [Nhóm G08 — Sửa sai, reversal và kỳ khóa](../../../01.knowledge/decisions/decision-register.md#38-g08-s%E1%BB%ADa-sai-v%C3%A0-ho%C3%A0n-nguy%C3%AAn); [Nhóm G10 — Inventory Operation, idempotency và sự kiện](../../../01.knowledge/decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh)
- **Bài tri thức liên quan:** [Sửa sai tồn kho mà không sửa lịch sử](../../../01.knowledge/know-how/KB-KGV-021-sua-sai-ton-kho-khong-sua-lich-su.md); [Vòng đời của một Inventory Operation](../../../01.knowledge/know-how/KB-KGV-027-vong-doi-cua-mot-inventory-operation.md); [Idempotency, phiên bản nguồn và xử lý kết quả chưa xác định](../../../01.knowledge/know-how/KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md)
