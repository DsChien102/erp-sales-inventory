---
id: UC-07-03
type: use-case
theme: theme-07
title: "Điều chỉnh hoặc hủy trước bàn giao"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v3.12.0
---

# UC-07-03 — Điều chỉnh hoặc hủy trước bàn giao

## 1. Mục tiêu và kết quả nghiệp vụ

Phản ánh amendment/cancel từ Theme nguồn lên lượng đang chờ trả trước khi bàn giao thực tế.

**Kết quả cần đạt:** `RTV_PENDING` được điều chỉnh hoặc giải phóng đúng source version; không phát sinh xuất kho.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Source giảm lượng hoặc hủy khi chưa bàn giao

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Lượng pending được cập nhật, phần bỏ trả quay về trạng thái nguồn hợp lệ; Amended/cancelled pending return.

### 2.3 Không bao gồm

Không sửa lịch sử của lần chuẩn bị cũ sau khi đã bàn giao. UC chỉ cho phép điều chỉnh hoặc hủy phần chờ trả khi hàng vẫn còn thuộc quyền kiểm soát của tenant.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** System process; Purchase/source phát source version mới.
- **Thẩm quyền:** Chỉ tác nhân hoặc system process có quyền thực thi đúng scope mới được commit; mọi guard về source/version, policy và lifecycle phải được server kiểm lại trước effect.
- **Sự kiện khởi phát:** Source giảm lượng hoặc hủy khi chưa bàn giao.
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
| BF-01 | Hệ thống | Nhận source version mới thể hiện giảm lượng, đổi phạm vi hoặc hủy trả NCC. |  |
| BF-02 | Hệ thống | So sánh với pending scope hiện hành và xác định phần chưa bàn giao còn có thể điều chỉnh. | EF-A — Đã bàn giao/finality không cho sửa |
| BF-03 | Hệ thống | Cập nhật hoặc giải phóng `RTV_PENDING` theo source version mới; giữ audit phiên bản cũ. | EF-B — Kết quả điều chỉnh chưa xác định |
| BF-04 | Hệ thống | Trả pending scope mới cho bề mặt chuẩn bị trả. |  |
| BF-05 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

Không có luồng thay thế riêng ngoài các nhánh kết quả đã thể hiện trong Luồng chính.

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Đã bàn giao hoặc finality không cho sửa
**Phát sinh tại:** BF-02. **Điều kiện:** Phần hàng tương ứng đã được bàn giao/ghi xuất .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Không đảo ngược bằng cách sửa pending; yêu cầu correction/return flow phù hợp. | |
| EF-A-02 | — | [Kết thúc UC.] | |

#### EF-B — Kết quả điều chỉnh chưa xác định
**Phát sinh tại:** BF-03. **Điều kiện:** Không rõ pending update đã commit .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Verify cùng source version/identity trước retry. | |
| EF-B-02 | — | [Kết thúc/hand-off recovery.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Giới hạn lượng | Lượng trả không vượt đồng thời lượng còn được source cho phép và lượng tenant thực có theo đúng sản phẩm/lô| Decision / DOM-IO / BC nguồn |
| BR-02 | Nguồn nhập | Giữ liên kết đến receipt/source nhập gốc khi nguồn cung cấp; không tự tạo quan hệ thương mại mới| Decision / DOM-IO / BC nguồn |
| BR-03 | Mốc loại khỏi khả dụng | Khi supplier return đã được chấp thuận và lượng chuyển RTV_PENDING| Decision / DOM-IO / BC nguồn |
| BR-04 | Mốc giảm vật lý | Chỉ khi có bằng chứng bàn giao thực tế; tạo hồ sơ chờ trả không giảm physical| Decision / DOM-IO / BC nguồn |
| BR-05 | Sửa trước bàn giao | Không sửa trực tiếp payload đã khóa; source version mới tạo thay đổi có truy vết và chỉ giải phóng phần chưa bàn giao| Decision / DOM-IO / BC nguồn |
| BR-06 | Giá trị | Giảm theo official cost có hiệu lực; giá nhà cung cấp chấp thuận và chênh lệch chỉ là accounting handoff| Decision / DOM-IO / BC nguồn |

- `SBC-COM-01` — Bao yêu cầu và định danh.
- `BC-COMMON-EXTENSIONS` — Shared behavioral contract extensions.
- `SBC-COM-02` — Quyền, phạm vi và điều kiện cần.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `SBC-COM-04` — Finality và tính nguyên tử.
- `BC-IO-17` — Synchronize supplier-return authorization.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | `RTV_PENDING` được điều chỉnh hoặc giải phóng đúng source version; không phát sinh xuất kho. | Hành trình tiếp tục từ kết quả authoritative vừa ghi theo Business Journey sở hữu; không suy bước tiếp theo chỉ từ thứ tự UC. |
| Không đủ điều kiện / Bị từ chối | Nếu precondition, version, quyền hoặc invariant không còn hợp lệ, hệ thống từ chối trước effect; nếu finality chưa rõ thì giữ cùng operation identity để recovery. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** `RTV_PENDING` được điều chỉnh hoặc giải phóng đúng source version; không phát sinh xuất kho.

## 8. Liên hệ giao diện

| Screen | Vai trò trong UC |
|---|---|
| `SCR-036` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Điều chỉnh hoặc hủy trước bàn giao”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |
| `SCR-037` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Điều chỉnh hoặc hủy trước bàn giao”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-07-03-01 — Điều chỉnh hoặc hủy trước bàn giao — luồng chính
- **Given:** Source giảm lượng hoặc hủy khi chưa bàn giao
- **When:** Nhận source version mới thể hiện giảm lượng, đổi phạm vi hoặc hủy trả NCC.
- **Then:** `RTV_PENDING` được điều chỉnh hoặc giải phóng đúng source version; không phát sinh xuất kho.

### AS-UC-07-03-02 — Điều chỉnh hoặc hủy trước bàn giao — Đã bàn giao hoặc finality không cho sửa
- **Given:** Phần hàng tương ứng đã được bàn giao/ghi xuất.
- **When:** Hệ thống phát hiện điều kiện “Đã bàn giao hoặc finality không cho sửa” tại BF-02.
- **Then:** Không đảo ngược bằng cách sửa pending; yêu cầu correction/return flow phù hợp. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-07-03-03 — Điều chỉnh hoặc hủy trước bàn giao — Kết quả điều chỉnh chưa xác định
- **Given:** Không rõ pending update đã commit.
- **When:** Hệ thống phát hiện điều kiện “Kết quả điều chỉnh chưa xác định” tại BF-03.
- **Then:** Verify cùng source version/identity trước retry. Giữ nguyên identity/evidence hiện có và bàn giao recovery/finality; không tạo effect trùng hoặc thử lại mù.

## 10. Truy vết

- **Journey:** `BJ-07` — Thực hiện trả hàng cho nhà cung cấp.
- **Domain:** `DOM-IO`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-17`.

- **Nguồn quyết định:** [Nhóm G06 — Trả hàng, hết hạn và loại bỏ](../../../01.knowledge/decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y)
- **Bài tri thức liên quan:** [Trả hàng cho nhà cung cấp](../../../01.knowledge/know-how/KB-KGV-013-tra-hang-cho-nha-cung-cap.md); [Chọn hàng để xuất và thời điểm hoàn tất xuất bán](../../../01.knowledge/know-how/KB-KGV-010-chon-hang-de-xuat-va-thoi-diem-hoan-tat-xuat-ban.md); [Đơn giá tồn kho chính thức và tổng giá trị ghi sổ](../../../01.knowledge/know-how/KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md)
