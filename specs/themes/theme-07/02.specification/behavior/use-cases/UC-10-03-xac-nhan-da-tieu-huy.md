---
id: UC-10-03
type: use-case
theme: theme-07
title: "Xác nhận đã tiêu hủy"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v3.12.0
---

# UC-10-03 — Xác nhận đã tiêu hủy

## 1. Mục tiêu và kết quả nghiệp vụ

Xác nhận việc tiêu hủy/xử lý thực tế đã xảy ra và lưu bằng chứng hoàn tất trước khi ghi giảm tồn.

**Kết quả cần đạt:** Completion evidence hợp lệ được khóa cho disposal request; chưa tự giảm tồn nếu bước ghi giảm chưa commit.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Yêu cầu đã duyệt và việc xử lý thực tế diễn ra

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Có completion assertion cho lượng thực xử lý; Disposal completion evidence.

### 2.3 Không bao gồm

Không ghi giảm tồn nếu chưa có bằng chứng hàng đã thực sự được xử lý. UC chỉ xác nhận sự kiện tiêu hủy vật lý và bằng chứng đủ để bước ghi giảm thực thi.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Thủ kho, người duyệt và người xác nhận xử lý.
- **Thẩm quyền:** Chỉ tác nhân hoặc system process có quyền thực thi đúng scope mới được commit; mọi guard về source/version, policy và lifecycle phải được server kiểm lại trước effect.
- **Sự kiện khởi phát:** Yêu cầu đã duyệt và việc xử lý thực tế diễn ra.
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
| BF-01 | Người xác nhận xử lý | Mở disposal request đã được phép xử lý và thực hiện/kiểm chứng việc tiêu hủy thực tế. |  |
| BF-02 | Người xác nhận xử lý | Ghi thời điểm, phương thức, người thực hiện và evidence hoàn tất. |  |
| BF-03 | Hệ thống | Kiểm tra request version, trạng thái và yêu cầu bằng chứng. | EF-A — Request stale/evidence thiếu |
| BF-04 | Hệ thống | Ghi completion assertion/version và chuyển sang UC-10-04 để ghi giảm. | EF-B — Kết quả xác nhận chưa xác định |
| BF-05 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

Không có luồng thay thế riêng ngoài các nhánh kết quả đã thể hiện trong Luồng chính.

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Request stale hoặc evidence thiếu
**Phát sinh tại:** BF-03. **Điều kiện:** Request không còn current hoặc evidence bắt buộc chưa đủ .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Không xác lập completion; giữ dữ liệu có thể sửa. | |
| EF-A-02 | — | [Kết thúc/Trở lại BF-02.] | |

#### EF-B — Kết quả xác nhận chưa xác định
**Phát sinh tại:** BF-04. **Điều kiện:** Không rõ completion assertion đã commit .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Verify cùng identity/version trước khi gửi lại. | |
| EF-B-02 | — | [Kết thúc/hand-off recovery.] | |

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
| Thành công | Completion evidence hợp lệ được khóa cho disposal request; chưa tự giảm tồn nếu bước ghi giảm chưa commit. | Hành trình tiếp tục từ kết quả authoritative vừa ghi theo Business Journey sở hữu; không suy bước tiếp theo chỉ từ thứ tự UC. |
| Không đủ điều kiện / Bị từ chối | Nếu precondition, version, quyền hoặc invariant không còn hợp lệ, hệ thống từ chối trước effect; nếu finality chưa rõ thì giữ cùng operation identity để recovery. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** Completion evidence hợp lệ được khóa cho disposal request; chưa tự giảm tồn nếu bước ghi giảm chưa commit.

## 8. Liên hệ giao diện

| Screen | Vai trò trong UC |
|---|---|
| `SCR-040` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Xác nhận đã tiêu hủy”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-10-03-01 — Xác nhận đã tiêu hủy — luồng chính
- **Given:** Yêu cầu đã duyệt và việc xử lý thực tế diễn ra
- **When:** Mở disposal request đã được phép xử lý và thực hiện/kiểm chứng việc tiêu hủy thực tế.
- **Then:** Completion evidence hợp lệ được khóa cho disposal request; chưa tự giảm tồn nếu bước ghi giảm chưa commit.

### AS-UC-10-03-02 — Xác nhận đã tiêu hủy — Request stale hoặc evidence thiếu
- **Given:** Request không còn current hoặc evidence bắt buộc chưa đủ.
- **When:** Hệ thống phát hiện điều kiện “Request stale hoặc evidence thiếu” tại BF-03.
- **Then:** Không xác lập completion; giữ dữ liệu có thể sửa. Luồng chính tiếp tục tại BF-02: Ghi thời điểm, phương thức, người thực hiện và evidence hoàn tất.

### AS-UC-10-03-03 — Xác nhận đã tiêu hủy — Kết quả xác nhận chưa xác định
- **Given:** Không rõ completion assertion đã commit.
- **When:** Hệ thống phát hiện điều kiện “Kết quả xác nhận chưa xác định” tại BF-04.
- **Then:** Verify cùng identity/version trước khi gửi lại. Giữ nguyên identity/evidence hiện có và bàn giao recovery/finality; không tạo effect trùng hoặc thử lại mù.

## 10. Truy vết

- **Journey:** `BJ-10` — Tiêu hủy hàng.
- **Domain:** `DOM-IO`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-11`.

- **Nguồn quyết định:** [Nhóm G06 — Trả hàng, hết hạn và loại bỏ](../../../01.knowledge/decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y); [Nhóm G11 — Quyền và phê duyệt](../../../01.knowledge/decisions/decision-register.md#311-g11-quy%E1%BB%81n-ph%C3%AA-duy%E1%BB%87t-v%C3%A0-b%E1%BA%A3o-v%E1%BB%87-d%E1%BB%AF-li%E1%BB%87u)
- **Bài tri thức liên quan:** [Hàng cận hạn, hết hạn, hư hỏng và tiêu hủy](../../../01.knowledge/know-how/KB-KGV-014-hang-can-han-het-han-hu-hong-va-tieu-huy.md); [Định giá hàng trả, tiêu hủy và chênh lệch thừa thiếu](../../../01.knowledge/know-how/KB-KGV-020-dinh-gia-hang-tra-tieu-huy-va-chenh-lech-thua-thieu.md); [Phê duyệt inventory operation theo mức rủi ro](../../../01.knowledge/know-how/KB-KGV-031-phe-duyet-inventory-operation-theo-muc-rui-ro.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md)
