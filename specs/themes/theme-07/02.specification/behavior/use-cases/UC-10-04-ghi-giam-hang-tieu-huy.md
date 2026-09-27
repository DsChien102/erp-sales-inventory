---
id: UC-10-04
type: use-case
theme: theme-07
title: "Ghi giảm hàng tiêu hủy"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-10
---

# UC-10-04 — Ghi giảm hàng tiêu hủy

## 1. Mục tiêu và kết quả nghiệp vụ

Ghi giảm quantity và value cho đúng lượng đã được xác nhận tiêu hủy, sau khi completion evidence hợp lệ.

**Kết quả cần đạt:** Quantity/value movement giảm và balance cập nhật nguyên tử; disposal request kết thúc đúng một lần.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Approval và completion assertion còn hợp lệ

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Physical/value giảm nguyên tử hoặc result không rõ được chuyển đối soát; Disposal inventory result.

### 2.3 Không bao gồm

Không sửa yêu cầu/phê duyệt/biên bản tiêu hủy để hợp thức hóa kết quả. UC chỉ ghi giảm lượng và giá trị theo đúng phạm vi đã xác nhận, một lần và có truy vết.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Thủ kho, người duyệt và người xác nhận xử lý.
- **Thẩm quyền:** Chỉ tác nhân hoặc system process có quyền thực thi đúng scope mới được commit; mọi guard về source/version, policy và lifecycle phải được server kiểm lại trước effect.
- **Sự kiện khởi phát:** Approval và completion assertion còn hợp lệ.
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
| BF-01 | Hệ thống | Nhận disposal completion assertion hiện hành. |  |
| BF-02 | Hệ thống | Recheck request/version, quantity/state và official cost tại thời điểm hoàn tất. | EF-A — Stale/không đủ lượng |
| BF-03 | Hệ thống | Ghi quantity movement giảm và value movement theo official cost cho lượng tiêu hủy. |  |
| BF-04 | Hệ thống | Cập nhật balance, disposal lifecycle và outbox/result trong cùng transaction. | EF-B — Kết quả commit chưa xác định |
| BF-05 | Hệ thống | Trả authoritative disposal result. |  |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

Không có luồng thay thế riêng ngoài các nhánh kết quả đã thể hiện trong Luồng chính.

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Stale hoặc không đủ lượng
**Phát sinh tại:** BF-02. **Điều kiện:** Quantity/state/request đã thay đổi trước commit .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Reject trước effect; không ghi giảm bán phần. | |
| EF-A-02 | — | [Kết thúc UC.] | |

#### EF-B — Kết quả commit chưa xác định
**Phát sinh tại:** BF-04. **Điều kiện:** Không rõ transaction ghi giảm đã commit .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Giữ operation identity và verify/BJ17 trước retry. | |
| EF-B-02 | — | [Kết thúc UC.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Trạng thái nguồn | Chỉ hàng không bán được và thuộc tenant mới được tiêu hủy; hàng sellable phải qua BJ-09 trước| Decision / DOM-IO / BC nguồn |
| BR-02 | Mốc giảm tồn | Phê duyệt chưa làm giảm physical; chỉ completion assertion hợp lệ mới cho phép ghi giảm| Decision / DOM-IO / BC nguồn |
| BR-03 | Maker–checker | Người lập không tự duyệt; cấp duyệt suy ra từ trị tuyệt đối lượng × căn cứ giá| Decision / DOM-IO / BC nguồn |
| BR-04 | Thiếu căn cứ giá | Không gửi duyệt khi thiếu cả official cost và giá nguồn; giữ nháp để bổ sung, không gán rủi ro không xác định| Decision / DOM-IO / BC nguồn |
| BR-05 | Giá trị | Giảm theo official cost có hiệu lực tại thời điểm hoàn tất; không suy ra giá riêng theo kho/lô| Decision / DOM-IO / BC nguồn |
| BR-06 | Số lượng thực xử lý | Nếu khác lượng được duyệt, chỉ cho phép trong phạm vi policy; vượt phạm vi phải quay lại lập/duyệt yêu cầu mới| Decision / DOM-IO / BC nguồn |

- `SBC-COM-01` — Bao yêu cầu và định danh.
- `BC-COMMON-EXTENSIONS` — Shared behavioral contract extensions.
- `SBC-COM-02` — Quyền, phạm vi và điều kiện cần.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `SBC-COM-04` — Finality và tính nguyên tử.
- `BC-IO-11` — Dispose inventory.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Quantity/value movement giảm và balance cập nhật nguyên tử; disposal request kết thúc đúng một lần. | Hành trình tiếp tục từ kết quả authoritative vừa ghi theo Business Journey sở hữu; không suy bước tiếp theo chỉ từ thứ tự UC. |
| Không đủ điều kiện / Bị từ chối | Nếu precondition, version, quyền hoặc invariant không còn hợp lệ, hệ thống từ chối trước effect; nếu finality chưa rõ thì giữ cùng operation identity để recovery. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** Quantity/value movement giảm và balance cập nhật nguyên tử; disposal request kết thúc đúng một lần.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-10 — Tiêu hủy hàng](../../../03.design/flows/UIF-10-BJ-10.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-041` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Ghi giảm hàng tiêu hủy”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-10-04-01 — Ghi giảm hàng tiêu hủy — luồng chính
- **Given:** Approval và completion assertion còn hợp lệ
- **When:** Nhận disposal completion assertion hiện hành.
- **Then:** Quantity/value movement giảm và balance cập nhật nguyên tử; disposal request kết thúc đúng một lần.

### AS-UC-10-04-02 — Ghi giảm hàng tiêu hủy — Stale hoặc không đủ lượng
- **Given:** Quantity/state/request đã thay đổi trước commit.
- **When:** Hệ thống phát hiện điều kiện “Stale hoặc không đủ lượng” tại BF-02.
- **Then:** Reject trước effect; không ghi giảm bán phần. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-10-04-03 — Ghi giảm hàng tiêu hủy — Kết quả commit chưa xác định
- **Given:** Không rõ transaction ghi giảm đã commit.
- **When:** Hệ thống phát hiện điều kiện “Kết quả commit chưa xác định” tại BF-04.
- **Then:** Giữ operation identity và verify/BJ17 trước retry. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

## 10. Truy vết

- **Journey:** `BJ-10` — Tiêu hủy hàng.
- **Domain:** `DOM-IO`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-11`.

- **Nguồn quyết định:** [Nhóm G06 — Trả hàng, hết hạn và loại bỏ](../../../01.knowledge/decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y); [Nhóm G11 — Quyền và phê duyệt](../../../01.knowledge/decisions/decision-register.md#311-g11-quy%E1%BB%81n-ph%C3%AA-duy%E1%BB%87t-v%C3%A0-b%E1%BA%A3o-v%E1%BB%87-d%E1%BB%AF-li%E1%BB%87u)
- **Bài tri thức liên quan:** [Hàng cận hạn, hết hạn, hư hỏng và tiêu hủy](../../../01.knowledge/know-how/KB-KGV-014-hang-can-han-het-han-hu-hong-va-tieu-huy.md); [Định giá hàng trả, tiêu hủy và chênh lệch thừa thiếu](../../../01.knowledge/know-how/KB-KGV-020-dinh-gia-hang-tra-tieu-huy-va-chenh-lech-thua-thieu.md); [Phê duyệt inventory operation theo mức rủi ro](../../../01.knowledge/know-how/KB-KGV-031-phe-duyet-inventory-operation-theo-muc-rui-ro.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md)
