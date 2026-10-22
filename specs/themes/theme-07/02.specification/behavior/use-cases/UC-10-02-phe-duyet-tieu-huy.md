---
id: UC-10-02
type: use-case
theme: theme-07
title: "Phê duyệt tiêu hủy"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-10
---

# UC-10-02 — Phê duyệt tiêu hủy

## 1. Mục tiêu và kết quả nghiệp vụ

Duyệt hoặc từ chối disposal request cần phê duyệt trên đúng snapshot và evidence hiện hành.

**Kết quả cần đạt:** Request được duyệt sẵn sàng xử lý hoặc bị từ chối có lý do; tồn kho chưa giảm.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Yêu cầu có snapshot rủi ro và approver hợp lệ

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Duyệt hoặc từ chối có lý do; Approval decision.

### 2.3 Không bao gồm

Không tự ghi giảm tồn và không sửa nội dung yêu cầu tiêu hủy đã khóa. UC chỉ ghi quyết định duyệt/từ chối cùng lý do/bằng chứng cần thiết.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Thủ kho, người duyệt và người xác nhận xử lý.
- **Thẩm quyền:** Chỉ tác nhân có quyền phê duyệt đúng policy và phạm vi mới được ra quyết định; quyết định không thay thế bước thực thi nghiệp vụ phía sau.
- **Sự kiện khởi phát:** Yêu cầu có snapshot rủi ro và approver hợp lệ.
- **Điều kiện trước:** Hồ sơ/case đúng version đang ở trạng thái chờ quyết định; tác nhân có quyền phê duyệt theo policy và đọc được snapshot/evidence làm căn cứ.

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
| BF-01 | Người duyệt | Mở disposal request đang chờ duyệt. |  |
| BF-02 | Hệ thống | Kiểm tra quyền/cấp duyệt, segregation và request version. | EF-A — Không đủ quyền/stale |
| BF-03 | Người duyệt | Rà soát quantity/state, lý do, phương thức và bằng chứng; quyết định Duyệt/Từ chối. | AF-A — Từ chối |
| BF-04 | Hệ thống | Commit approval và chuyển request sang chờ xác nhận đã xử lý thực tế. | EF-B — Kết quả quyết định chưa xác định |
| BF-05 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Từ chối
**Phát sinh tại:** BF-03. **Điều kiện:** Người duyệt không chấp thuận .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Người duyệt | Ghi lý do từ chối bắt buộc. | |
| AF-A-02 | — | [Hệ thống commit rejection; kết thúc UC.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Không đủ quyền hoặc stale
**Phát sinh tại:** BF-02. **Điều kiện:** Người duyệt không hợp lệ hoặc request đã đổi version .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Không cho quyết định trên dữ liệu cũ. | |
| EF-A-02 | — | [Kết thúc UC.] | |

#### EF-B — Kết quả quyết định chưa xác định
**Phát sinh tại:** BF-04. **Điều kiện:** Không rõ approval/rejection đã commit .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Verify cùng decision identity. | |
| EF-B-02 | — | [Kết thúc/hand-off recovery.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Trạng thái nguồn | Chỉ hàng không bán được và thuộc tenant mới được tiêu hủy; hàng sellable phải qua BJ-09 trước| Decision / DOM-IC / BC nguồn |
| BR-02 | Mốc giảm tồn | Phê duyệt chưa làm giảm physical; chỉ completion assertion hợp lệ mới cho phép ghi giảm| Decision / DOM-IC / BC nguồn |
| BR-03 | Maker–checker | Người lập không tự duyệt (trừ chủ cửa hàng `is_owner`: vẫn gửi duyệt rồi tự duyệt); cấp duyệt suy ra từ trị tuyệt đối lượng × căn cứ giá| Decision / DOM-IC / BC nguồn |
| BR-04 | Thiếu căn cứ giá | Không gửi duyệt khi thiếu cả official cost và giá nguồn; giữ nháp để bổ sung, không gán rủi ro không xác định| Decision / DOM-IC / BC nguồn |
| BR-05 | Giá trị | Giảm theo official cost có hiệu lực tại thời điểm hoàn tất; không suy ra giá riêng theo kho/lô| Decision / DOM-IC / BC nguồn |
| BR-06 | Số lượng thực xử lý | Nếu khác lượng được duyệt, chỉ cho phép trong phạm vi policy; vượt phạm vi phải quay lại lập/duyệt yêu cầu mới| Decision / DOM-IC / BC nguồn |

- `SBC-COM-01` — Bao yêu cầu và định danh.
- `BC-COMMON-EXTENSIONS` — Shared behavioral contract extensions.
- `SBC-COM-02` — Quyền, phạm vi và điều kiện cần.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `SBC-COM-04` — Finality và tính nguyên tử.
- `BC-IC-06` — Decide approval.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Request được duyệt sẵn sàng xử lý hoặc bị từ chối có lý do; tồn kho chưa giảm. | Chỉ kết quả phê duyệt hợp lệ mới cho phép bước thực thi tiếp theo; từ chối kết thúc hoặc trả hồ sơ theo lifecycle nguồn. |
| Không đủ điều kiện / Bị từ chối | Nếu bị từ chối, stale hoặc sai quyền/segregation, quyết định không làm phát sinh effect nghiệp vụ ngoài approval result đã được phép ghi. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** Request được duyệt sẵn sàng xử lý hoặc bị từ chối có lý do; tồn kho chưa giảm.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-10 — Tiêu hủy hàng](../../../03.design/flows/UIF-10-BJ-10.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-040` | Trình bày basis/evidence và hành động ra quyết định của “Phê duyệt tiêu hủy”; không tự thực thi effect sau duyệt. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-10-02-01 — Phê duyệt tiêu hủy — luồng chính
- **Given:** Yêu cầu có snapshot rủi ro và approver hợp lệ
- **When:** Mở disposal request đang chờ duyệt.
- **Then:** Request được duyệt sẵn sàng xử lý hoặc bị từ chối có lý do; tồn kho chưa giảm.

### AS-UC-10-02-02 — Phê duyệt tiêu hủy — Từ chối
- **Given:** Người duyệt không chấp thuận.
- **When:** Ghi lý do từ chối bắt buộc.
- **Then:** UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-10-02-03 — Phê duyệt tiêu hủy — Không đủ quyền hoặc stale
- **Given:** Người duyệt không hợp lệ hoặc request đã đổi version.
- **When:** Hệ thống phát hiện điều kiện “Không đủ quyền hoặc stale” tại BF-02.
- **Then:** Không cho quyết định trên dữ liệu cũ. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-10-02-04 — Phê duyệt tiêu hủy — Kết quả quyết định chưa xác định
- **Given:** Không rõ approval/rejection đã commit.
- **When:** Hệ thống phát hiện điều kiện “Kết quả quyết định chưa xác định” tại BF-04.
- **Then:** Verify cùng decision identity. Giữ nguyên identity/evidence hiện có và bàn giao recovery/finality; không tạo effect trùng hoặc thử lại mù.

## 10. Truy vết

- **Journey:** `BJ-10` — Tiêu hủy hàng.
- **Domain:** `DOM-IC`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-06`.

- **Nguồn quyết định:** [Nhóm G06 — Trả hàng, hết hạn và loại bỏ](../../../01.knowledge/decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y); [Nhóm G11 — Quyền và phê duyệt](../../../01.knowledge/decisions/decision-register.md#311-g11-quy%E1%BB%81n-ph%C3%AA-duy%E1%BB%87t-v%C3%A0-b%E1%BA%A3o-v%E1%BB%87-d%E1%BB%AF-li%E1%BB%87u)
- **Bài tri thức liên quan:** [Hàng cận hạn, hết hạn, hư hỏng và tiêu hủy](../../../01.knowledge/know-how/KB-KGV-014-hang-can-han-het-han-hu-hong-va-tieu-huy.md); [Định giá hàng trả, tiêu hủy và chênh lệch thừa thiếu](../../../01.knowledge/know-how/KB-KGV-020-dinh-gia-hang-tra-tieu-huy-va-chenh-lech-thua-thieu.md); [Phê duyệt inventory operation theo mức rủi ro](../../../01.knowledge/know-how/KB-KGV-031-phe-duyet-inventory-operation-theo-muc-rui-ro.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md)
