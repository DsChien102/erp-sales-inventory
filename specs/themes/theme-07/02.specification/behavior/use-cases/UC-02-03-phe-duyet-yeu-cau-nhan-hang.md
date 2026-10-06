---
id: UC-02-03
type: use-case
theme: theme-07
title: "Phê duyệt yêu cầu nhận hàng"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v4.6.7
ui_flow: UIF-02
---

# UC-02-03 — Phê duyệt yêu cầu nhận hàng

## 1. Mục tiêu và kết quả nghiệp vụ

Ra quyết định phê duyệt độc lập cho phiếu nhận hàng nhanh và các phiếu nhận hàng theo chứng từ có accepted physical vượt tolerance/ngưỡng của source theo ApprovalPolicy.

**Kết quả cần đạt:** Yêu cầu được duyệt sang `READY` hoặc bị từ chối có lý do; không tạo movement trong UC phê duyệt.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Hồ sơ phiếu nhận hàng nhanh đã gửi hoặc hồ sơ nhận theo chứng từ có accepted physical vượt tolerance/ngưỡng cần duyệt

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Chấp thuận: operation được phép chuyển sang `READY`, nhưng chưa tạo movement; Từ chối: bắt buộc có lý do, kết thúc yêu cầu mà không thay đổi tồn.

### 2.3 Không bao gồm

Không tự ghi hàng vào tồn và không sửa payload nhận hàng đã khóa. UC chỉ ghi quyết định duyệt/từ chối yêu cầu nhận cùng lý do/bằng chứng cần thiết.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Người có quyền phê duyệt phù hợp, khác người lập. Với phiếu nhận hàng nhanh, eligibility/cấp được resolve theo policy phiếu nhận hàng nhanh không phụ thuộc price/FX tại BJ02.
- **Thẩm quyền:** Chỉ tác nhân có quyền phê duyệt đúng policy và phạm vi mới được ra quyết định; quyết định không thay thế bước thực thi nghiệp vụ phía sau.
- **Sự kiện khởi phát:** Hồ sơ phiếu nhận hàng nhanh đã gửi hoặc hồ sơ nhận theo chứng từ có accepted physical vượt tolerance/ngưỡng cần duyệt.
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
| BF-01 | Người duyệt | Mở yêu cầu đang `PENDING_APPROVAL` từ task/deep link của mình. |  |
| BF-02 | Hệ thống | Nạp snapshot/version, source, chênh lệch, bằng chứng và kiểm tra quyền/cấp duyệt + segregation. | EF-A — Không đủ quyền hoặc version stale |
| BF-03 | Người duyệt | Rà soát hàng thực nhận và quyết định Duyệt hoặc Từ chối. | AF-A — Từ chối |
| BF-04 | Hệ thống | Nếu Duyệt, commit quyết định đầu tiên hợp lệ và chuyển operation sang `READY`. | EF-B — Kết quả quyết định chưa xác định |
| BF-05 | Hệ thống | Ghi audit người duyệt, thời điểm, version và evidence đã xem; chưa tăng tồn. |  |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Từ chối
**Phát sinh tại:** BF-03. **Điều kiện:** Người duyệt không chấp thuận hồ sơ .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Người duyệt | Nhập lý do từ chối bắt buộc. | |
| AF-A-02 | — | [Hệ thống commit `REJECTED`; kết thúc UC, không tạo movement.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Không đủ quyền hoặc version stale
**Phát sinh tại:** BF-02. **Điều kiện:** Người duyệt không còn quyền/cấp phù hợp, là người lập, hoặc hồ sơ đã đổi version .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Không cho quyết định trên snapshot cũ; trả current status/version. | |
| EF-A-02 | — | [Kết thúc UC.] | |

#### EF-B — Kết quả quyết định chưa xác định
**Phát sinh tại:** BF-04. **Điều kiện:** Client mất response sau khi gửi quyết định .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Giữ cùng decision identity và verify kết quả; quyết định thứ hai không được ghi đè quyết định đã commit. | |
| EF-B-02 | — | [Kết thúc/hand-off recovery.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Route vào bước duyệt | Phiếu nhận hàng nhanh luôn phải có quyết định duyệt theo policy phiếu nhận hàng nhanh và không cần price/FX basis để vào UC này; nhận theo chứng từ chỉ vào UC này khi cumulative accepted physical quantity vượt tolerance/ngưỡng của source theo ApprovalPolicy. | `T7-DR-027`, `T7-DR-022`, `T7-DR-116`, `T7-DR-078`, `T7-DR-080` |
| BR-02 | Người duyệt phải còn quyền | Người duyệt phải còn quyền, phạm vi kho và cấp phù hợp tại thời điểm quyết định, đồng thời khác người lập.| Decision / DOM-IC / BC nguồn |
| BR-03 | Quyết định đầu tiên commit hợp lệ thắng | Quyết định đầu tiên commit hợp lệ thắng; yêu cầu sau không ghi đè.| Decision / DOM-IC / BC nguồn |
| BR-04 | Phê duyệt chỉ cho phép thực thi | Phê duyệt chỉ cho phép thực thi, không giữ hàng và không tạo movement; các guard phải được kiểm tra lại khi ghi tồn.| Decision / DOM-IC / BC nguồn |
| BR-05 | Từ chối phải có lý do và không tạo | Từ chối phải có lý do và không tạo tác động tồn kho.| Decision / DOM-IC / BC nguồn |

- `SBC-COM-01` — Bao yêu cầu và định danh.
- `BC-COMMON-EXTENSIONS` — Shared behavioral contract extensions.
- `SBC-COM-02` — Quyền, phạm vi và điều kiện cần.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `SBC-COM-04` — Finality và tính nguyên tử.
- `BC-IC-06` — Decide approval.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Yêu cầu được duyệt sang `READY` hoặc bị từ chối có lý do; không tạo movement trong UC phê duyệt. | Chỉ kết quả phê duyệt hợp lệ mới cho phép bước thực thi tiếp theo; từ chối kết thúc hoặc trả hồ sơ theo lifecycle nguồn. |
| Không đủ điều kiện / Bị từ chối | Nếu bị từ chối, stale hoặc sai quyền/segregation, quyết định không làm phát sinh effect nghiệp vụ ngoài approval result đã được phép ghi. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** Yêu cầu được duyệt sang `READY` hoặc bị từ chối có lý do; không tạo movement trong UC phê duyệt.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-02 — Nhận hàng mua](../../../03.design/flows/UIF-02-BJ-02.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-010` | Trình bày basis/evidence và hành động ra quyết định của “Phê duyệt yêu cầu nhận hàng”; không tự thực thi effect sau duyệt. |
| `SCR-011` | Trình bày basis/evidence và hành động ra quyết định của “Phê duyệt yêu cầu nhận hàng”; không tự thực thi effect sau duyệt. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-02-03-01 — Phê duyệt yêu cầu nhận hàng — luồng chính
- **Given:** Hồ sơ phiếu nhận hàng nhanh đã gửi hoặc hồ sơ nhận theo chứng từ có accepted physical vượt tolerance/ngưỡng cần duyệt
- **When:** Mở yêu cầu đang `PENDING_APPROVAL` từ task/deep link của mình.
- **Then:** Yêu cầu được duyệt sang `READY` hoặc bị từ chối có lý do; không tạo movement trong UC phê duyệt.

### AS-UC-02-03-02 — Phê duyệt yêu cầu nhận hàng — Từ chối
- **Given:** Người duyệt không chấp thuận hồ sơ.
- **When:** Nhập lý do từ chối bắt buộc.
- **Then:** UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-02-03-03 — Phê duyệt yêu cầu nhận hàng — Không đủ quyền hoặc version stale
- **Given:** Người duyệt không còn quyền/cấp phù hợp, là người lập, hoặc hồ sơ đã đổi version.
- **When:** Hệ thống phát hiện điều kiện “Không đủ quyền hoặc version stale” tại BF-02.
- **Then:** Không cho quyết định trên snapshot cũ; trả current status/version. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-02-03-04 — Phê duyệt yêu cầu nhận hàng — Kết quả quyết định chưa xác định
- **Given:** Client mất response sau khi gửi quyết định.
- **When:** Hệ thống phát hiện điều kiện “Kết quả quyết định chưa xác định” tại BF-04.
- **Then:** Giữ cùng decision identity và verify kết quả; quyết định thứ hai không được ghi đè quyết định đã commit. Giữ nguyên identity/evidence hiện có và bàn giao recovery/finality; không tạo effect trùng hoặc thử lại mù.

## 10. Truy vết

- **Journey:** `BJ-02` — Nhận hàng mua.
- **Domain:** `DOM-IC`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-06`.

- **Nguồn quyết định:** [Nhóm G03 — Nhận hàng mua và giải phóng khả dụng](../../../01.knowledge/decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B); [Nhóm G11 — Quyền và phê duyệt](../../../01.knowledge/decisions/decision-register.md#311-g11-quy%E1%BB%81n-ph%C3%AA-duy%E1%BB%87t-v%C3%A0-b%E1%BA%A3o-v%E1%BB%87-d%E1%BB%AF-li%E1%BB%87u); [Nhóm G03 — Phiếu nhận hàng nhanh bắt buộc duyệt](../../../01.knowledge/decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B)
- **Bài tri thức liên quan:** [Nhận hàng mua và xử lý chênh lệch giao nhận](../../../01.knowledge/know-how/KB-KGV-007-nhan-hang-mua-va-xu-ly-chenh-lech-giao-nhan.md); [Hàng đã nhận nhưng chưa chốt giá](../../../01.knowledge/know-how/KB-KGV-008-hang-da-nhan-nhung-chua-chot-gia.md); [Chính sách NONE, LOT hoặc SERIAL](../../../01.knowledge/know-how/KB-KGV-024-chinh-sach-quan-ly-hang-thong-thuong-theo-lo-hoac-theo-serial.md); [Danh tính và vòng đời của một lô hàng](../../../01.knowledge/know-how/KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md); [Phê duyệt inventory operation theo mức rủi ro](../../../01.knowledge/know-how/KB-KGV-031-phe-duyet-inventory-operation-theo-muc-rui-ro.md)
