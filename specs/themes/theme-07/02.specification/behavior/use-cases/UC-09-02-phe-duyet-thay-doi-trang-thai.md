---
id: UC-09-02
type: use-case
theme: theme-07
title: "Phê duyệt thay đổi trạng thái"
owner: BA
status: FROZEN
frozen_at: v5.27.0
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-09
---

# UC-09-02 — Phê duyệt thay đổi trạng thái

## 1. Mục tiêu và kết quả nghiệp vụ

Duyệt hoặc từ chối yêu cầu thay đổi trạng thái cần phê duyệt trên snapshot/evidence hiện hành.

**Kết quả cần đạt:** Request được duyệt sẵn sàng thực thi hoặc bị từ chối có lý do; chưa ghi state movement.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Yêu cầu vượt ngưỡng/rủi ro

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Duyệt hoặc từ chối có lý do; Approval decision.

### 2.3 Không bao gồm

Không tự ghi state movement và không sửa yêu cầu đã khóa. UC chỉ ghi quyết định duyệt/từ chối việc đổi trạng thái cùng lý do/bằng chứng cần thiết.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Người duyệt. **Người duyệt** là `is_owner` hoặc vai trò `store_owner`, khác người lập. **Ngoại lệ:** cửa hàng chỉ có một chủ, nên `is_owner` lập đổi tình trạng thì vẫn gửi duyệt rồi tự duyệt ở màn duyệt (không có đường ghi nhận thẳng); lịch sử ghi người duyệt "Chủ cửa hàng".
- **Thẩm quyền:** Chỉ tác nhân có quyền phê duyệt đúng policy và phạm vi mới được ra quyết định; quyết định không thay thế bước thực thi nghiệp vụ phía sau.
- **Sự kiện khởi phát:** Yêu cầu vượt ngưỡng/rủi ro.
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
| BF-01 | Người duyệt | Mở state-change request đang chờ duyệt. |  |
| BF-02 | Hệ thống | Kiểm tra quyền/cấp duyệt, segregation và request version hiện hành. | EF-A — Không đủ quyền hoặc stale |
| BF-03 | Người duyệt | Rà soát scope, trạng thái nguồn→đích, lý do/evidence và quyết định Duyệt/Từ chối. | AF-A — Từ chối |
| BF-04 | Hệ thống | Commit quyết định duyệt và chuyển request sang trạng thái sẵn sàng thực thi. | EF-B — Kết quả quyết định chưa xác định |
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
**Phát sinh tại:** BF-02. **Điều kiện:** Quyền/cấp duyệt không hợp lệ hoặc request đã đổi version .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Không cho quyết định trên snapshot cũ. | |
| EF-A-02 | — | [Kết thúc UC.] | |

#### EF-B — Kết quả quyết định chưa xác định
**Phát sinh tại:** BF-04. **Điều kiện:** Không rõ approval đã commit .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Verify decision identity; không ghi đè quyết định đầu tiên đã commit. | |
| EF-B-02 | — | [Kết thúc/hand-off recovery.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Ma trận chuyển trạng thái | Chỉ cho các chuyển đổi được whitelist; mỗi chuyển đổi xác định quyền, lý do, bằng chứng và mức duyệt| Decision / DOM-IC / BC nguồn |
| BR-02 | Tổng vật lý | Chuyển trạng thái không làm đổi tổng physical quantity của sản phẩm/lô| Decision / DOM-IC / BC nguồn |
| BR-03 | Hết hạn | Xác định trực tiếp từ hạn dùng và ngày nghiệp vụ; loại khỏi khả dụng ngay, không phụ thuộc tác vụ nền đã materialize EXPIRED hay chưa| Decision / DOM-IC / BC nguồn |
| BR-04 | Cận hạn | Chỉ là chỉ báo/policy WARN hoặc BLOCK_SALE; không phải state movement và không tạo hồ sơ cảnh báo có lifecycle| Decision / DOM-IC / BC nguồn |
| BR-05 | Demo | Vẫn thuộc physical và book value nhưng không khả dụng; muốn bán lại phải qua chuyển trạng thái được phép| Decision / DOM-IC / BC nguồn |
| BR-06 | Reservation | Khi eligible giảm, phát tác động để BJ-04 đánh giá lại; BJ này không tự sửa order hoặc PickAllocation| Decision / DOM-IC / BC nguồn |
| BR-K2 | Người duyệt và tự duyệt | Người duyệt là `is_owner` hoặc vai trò `store_owner`, khác người lập. Ngoại lệ: cửa hàng chỉ có một chủ, nên `is_owner` lập đổi tình trạng thì vẫn gửi duyệt rồi tự duyệt ở màn duyệt (không có đường ghi nhận thẳng); lịch sử ghi người duyệt "Chủ cửa hàng". | Decision K2 / T7-P |

- `SBC-COM-01` — Bao yêu cầu và định danh.
- `BC-COMMON-EXTENSIONS` — Shared behavioral contract extensions.
- `SBC-COM-02` — Quyền, phạm vi và điều kiện cần.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `SBC-COM-04` — Finality và tính nguyên tử.
- `BC-IC-06` — Decide approval.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Request được duyệt sẵn sàng thực thi hoặc bị từ chối có lý do; chưa ghi state movement. | Chỉ kết quả phê duyệt hợp lệ mới cho phép bước thực thi tiếp theo; từ chối kết thúc hoặc trả hồ sơ theo lifecycle nguồn. |
| Không đủ điều kiện / Bị từ chối | Nếu bị từ chối, stale hoặc sai quyền/segregation, quyết định không làm phát sinh effect nghiệp vụ ngoài approval result đã được phép ghi. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** Request được duyệt sẵn sàng thực thi hoặc bị từ chối có lý do; chưa ghi state movement.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-09 — Quản lý trạng thái hàng](../../../03.design/flows/UIF-09-BJ-09.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-038` | Trình bày basis/evidence và hành động ra quyết định của “Phê duyệt thay đổi trạng thái”; không tự thực thi effect sau duyệt. |
| `SCR-041` | Trình bày basis/evidence và hành động ra quyết định của “Phê duyệt thay đổi trạng thái”; không tự thực thi effect sau duyệt. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-09-02-01 — Phê duyệt thay đổi trạng thái — luồng chính
- **Given:** Yêu cầu vượt ngưỡng/rủi ro
- **When:** Mở state-change request đang chờ duyệt.
- **Then:** Request được duyệt sẵn sàng thực thi hoặc bị từ chối có lý do; chưa ghi state movement.

### AS-UC-09-02-02 — Phê duyệt thay đổi trạng thái — Từ chối
- **Given:** Người duyệt không chấp thuận.
- **When:** Ghi lý do từ chối bắt buộc.
- **Then:** UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-09-02-03 — Phê duyệt thay đổi trạng thái — Không đủ quyền hoặc stale
- **Given:** Quyền/cấp duyệt không hợp lệ hoặc request đã đổi version.
- **When:** Hệ thống phát hiện điều kiện “Không đủ quyền hoặc stale” tại BF-02.
- **Then:** Không cho quyết định trên snapshot cũ. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-09-02-04 — Phê duyệt thay đổi trạng thái — Kết quả quyết định chưa xác định
- **Given:** Không rõ approval đã commit.
- **When:** Hệ thống phát hiện điều kiện “Kết quả quyết định chưa xác định” tại BF-04.
- **Then:** Verify decision identity; không ghi đè quyết định đầu tiên đã commit. Giữ nguyên identity/evidence hiện có và bàn giao recovery/finality; không tạo effect trùng hoặc thử lại mù.

## 10. Truy vết

- **Journey:** `BJ-09` — Quản lý trạng thái hàng.
- **Domain:** `DOM-IC`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-06`.

- **Nguồn quyết định:** [Nhóm G06 — Trả hàng, hết hạn và loại bỏ](../../../01.knowledge/decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y); [Nhóm G02 — Lô, hạn dùng và chính sách theo dõi sản phẩm](../../../01.knowledge/decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i)
- **Bài tri thức liên quan:** [Hàng cận hạn, hết hạn, hư hỏng và tiêu hủy](../../../01.knowledge/know-how/KB-KGV-014-hang-can-han-het-han-hu-hong-va-tieu-huy.md); [Tồn vật lý và tồn khả dụng](../../../01.knowledge/know-how/KB-KGV-005-ton-vat-ly-va-ton-kha-dung.md); [Danh tính và vòng đời của một lô hàng](../../../01.knowledge/know-how/KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md); [Hàng ký gửi, hàng demo và quyền sở hữu](../../../01.knowledge/know-how/KB-KGV-034-quyen-so-huu-hang-hoa-hang-ky-gui-va-hang-demo.md)
