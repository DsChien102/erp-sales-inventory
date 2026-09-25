---
id: UC-07-02
type: use-case
theme: theme-07
title: "Đồng bộ hàng vào chờ trả"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-07
---

# UC-07-02 — Đồng bộ hàng vào chờ trả

## 1. Mục tiêu và kết quả nghiệp vụ

Đồng bộ lượng hàng được Theme mua/nguồn trả NCC phê duyệt vào trạng thái chờ trả mà chưa làm giảm tồn vật lý.

**Kết quả cần đạt:** Lượng hợp lệ được đánh dấu `RTV_PENDING` theo source version; không tạo xuất kho.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Có scope hợp lệ

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Lượng được chuyển sang `RTV_PENDING` và loại khỏi khả dụng; Pending supplier return.

### 2.3 Không bao gồm

Không ghi giảm tồn và chưa ghi nhận bàn giao cho nhà cung cấp. UC chỉ đưa đúng lượng đủ điều kiện vào trạng thái chờ trả, giữ liên kết với nguồn và reservation/lock cần thiết.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** System process; Purchase/source là upstream authority.
- **Thẩm quyền:** Chỉ tác nhân hoặc system process có quyền thực thi đúng scope mới được commit; mọi guard về source/version, policy và lifecycle phải được server kiểm lại trước effect.
- **Sự kiện khởi phát:** Có scope hợp lệ.
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
| BF-01 | Hệ thống | Nhận authorization/source version trả NCC từ upstream authority. |  |
| BF-02 | Hệ thống | Recheck Product/UOM/LOT, lượng còn trong tồn và source authorization current. | EF-A — Source stale/không đủ lượng |
| BF-03 | Hệ thống | Đánh dấu đúng lượng/lô vào `RTV_PENDING` hoặc trạng thái chờ trả tương ứng. |  |
| BF-04 | Hệ thống | Ghi source/version trace và trả pending scope cho bề mặt chuẩn bị bàn giao; physical quantity không đổi. | EF-B — Kết quả đồng bộ chưa xác định |
| BF-05 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

Không có luồng thay thế riêng ngoài các nhánh kết quả đã thể hiện trong Luồng chính.

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Source stale hoặc không đủ lượng
**Phát sinh tại:** BF-02. **Điều kiện:** Authorization cũ hoặc lượng/lô không còn đủ để chờ trả .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Không tự tăng/đổi authorization; trả conflict về Theme nguồn để xử lý. | |
| EF-A-02 | — | [Kết thúc UC.] | |

#### EF-B — Kết quả đồng bộ chưa xác định
**Phát sinh tại:** BF-04. **Điều kiện:** Không rõ pending state đã commit .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Verify theo source/version + identity trước khi ghi lại. | |
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
| Thành công | Lượng hợp lệ được đánh dấu `RTV_PENDING` theo source version; không tạo xuất kho. | Hành trình tiếp tục từ kết quả authoritative vừa ghi theo Business Journey sở hữu; không suy bước tiếp theo chỉ từ thứ tự UC. |
| Không đủ điều kiện / Bị từ chối | Nếu precondition, version, quyền hoặc invariant không còn hợp lệ, hệ thống từ chối trước effect; nếu finality chưa rõ thì giữ cùng operation identity để recovery. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** Lượng hợp lệ được đánh dấu `RTV_PENDING` theo source version; không tạo xuất kho.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-07 — Thực hiện trả hàng cho nhà cung cấp](../../../03.design/flows/UIF-07-BJ-07.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-036` | Điểm vào/list context cho supplier-return intent. |
| `SCR-037` | Rà soát source/version/quantity trước khi system đồng bộ RTV_PENDING. |
| `SCR-041` | Kết quả/trạng thái authoritative sau system sync; không dùng SCR-038. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-07-02-01 — Đồng bộ hàng vào chờ trả — luồng chính
- **Given:** Có scope hợp lệ
- **When:** Nhận authorization/source version trả NCC từ upstream authority.
- **Then:** Lượng hợp lệ được đánh dấu `RTV_PENDING` theo source version; không tạo xuất kho.

### AS-UC-07-02-02 — Đồng bộ hàng vào chờ trả — Source stale hoặc không đủ lượng
- **Given:** Authorization cũ hoặc lượng/lô không còn đủ để chờ trả.
- **When:** Hệ thống phát hiện điều kiện “Source stale hoặc không đủ lượng” tại BF-02.
- **Then:** Không tự tăng/đổi authorization; trả conflict về Theme nguồn để xử lý. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-07-02-03 — Đồng bộ hàng vào chờ trả — Kết quả đồng bộ chưa xác định
- **Given:** Không rõ pending state đã commit.
- **When:** Hệ thống phát hiện điều kiện “Kết quả đồng bộ chưa xác định” tại BF-04.
- **Then:** Verify theo source/version + identity trước khi ghi lại. Giữ nguyên identity/evidence hiện có và bàn giao recovery/finality; không tạo effect trùng hoặc thử lại mù.

## 10. Truy vết

- **Journey:** `BJ-07` — Thực hiện trả hàng cho nhà cung cấp.
- **Domain:** `DOM-IO`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-17`.

- **Nguồn quyết định:** [Nhóm G06 — Trả hàng, hết hạn và loại bỏ](../../../01.knowledge/decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y)
- **Bài tri thức liên quan:** [Trả hàng cho nhà cung cấp](../../../01.knowledge/know-how/KB-KGV-013-tra-hang-cho-nha-cung-cap.md); [Chọn hàng để xuất và thời điểm hoàn tất xuất bán](../../../01.knowledge/know-how/KB-KGV-010-chon-hang-de-xuat-va-thoi-diem-hoan-tat-xuat-ban.md); [Đơn giá tồn kho chính thức và tổng giá trị ghi sổ](../../../01.knowledge/know-how/KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md)
