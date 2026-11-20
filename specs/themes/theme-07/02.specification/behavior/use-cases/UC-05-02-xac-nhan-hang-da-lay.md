---
id: UC-05-02
type: use-case
theme: theme-07
title: "Xác nhận hàng đã lấy"
owner: BA
status: FROZEN
frozen_at: v5.27.0
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-05
---

# UC-05-02 — Xác nhận hàng đã lấy

## 1. Mục tiêu và kết quả nghiệp vụ

Ghi nhận đúng lượng và lô nhân viên đã lấy theo allocation active, chưa làm giảm tồn vật lý.

**Kết quả cần đạt:** Pick result gắn đúng allocation version được lưu; discrepancy được ghi rõ để xử lý trước bàn giao.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Có allocation active

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Dòng pick được xác nhận hoặc stale được phát hiện; Pick evidence.

### 2.3 Không bao gồm

Không ghi xuất kho và không kết thúc reservation. UC chỉ xác nhận lượng thực tế đã lấy theo allocation hiện hành và giữ dấu vết sai lệch/override nếu có.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Nhân viên xử lý đơn hoặc thủ kho.
- **Thẩm quyền:** Chỉ tác nhân hoặc system process có quyền thực thi đúng scope mới được commit; mọi guard về source/version, policy và lifecycle phải được server kiểm lại trước effect.
- **Sự kiện khởi phát:** Có allocation active.
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
| BF-01 | Nhân viên/Thủ kho | Mở allocation active và lấy hàng theo các dòng/lô được hướng dẫn. |  |
| BF-02 | Nhân viên/Thủ kho | Xác nhận lượng thực tế đã lấy cho từng dòng; nếu đổi lô phải chọn lô eligible và nêu lý do khi policy yêu cầu. | AF-A — Đổi lô khi lấy |
| BF-03 | Hệ thống | Kiểm tra allocation version còn active, quantity không vượt scope và lô vẫn eligible. | EF-A — Allocation stale |
| BF-04 | Hệ thống | Lưu pick result/version và discrepancy; không giảm physical quantity, không consume reservation. | EF-B — Kết quả lưu pick chưa xác định |
| BF-05 | Hệ thống | Đưa fulfillment sang trạng thái sẵn sàng bàn giao nếu policy/quantity cho phép. |  |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Đổi lô khi lấy
**Phát sinh tại:** BF-02. **Điều kiện:** Lô được allocation không còn phù hợp hoặc người có quyền chọn lô khác .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Nhân viên/Thủ kho | Chọn lô thay thế còn eligible và ghi reason/override evidence. | |
| AF-A-02 | — | [Trở lại BF-03.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Allocation stale
**Phát sinh tại:** BF-03. **Điều kiện:** Active allocation đã bị thay version hoặc lô/lượng không còn eligible .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Không chấp nhận pick result trên version cũ; chuyển UC-05-04 để reallocate. | |
| EF-A-02 | — | [Kết thúc UC.] | |

#### EF-B — Kết quả lưu pick chưa xác định
**Phát sinh tại:** BF-04. **Điều kiện:** Không rõ pick result đã commit hay chưa .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Verify bằng cùng identity/version trước khi ghi lại. | |
| EF-B-02 | — | [Kết thúc/hand-off recovery.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Allocation version | Chỉ một version active; handover phải mang đúng active version| Decision / DOM-IO / BC nguồn |
| BR-02 | Pick | Pick không giảm physical quantity| Decision / DOM-IO / BC nguồn |
| BR-03 | Partial handover | Consume đúng lượng đã giao; reservation còn lại giảm tương ứng và vẫn active nếu source cho phép| Decision / DOM-IO / BC nguồn |
| BR-04 | Không cho partial | Chưa đủ lượng thì toàn bộ handover bị từ chối, không commit bán phần| Decision / DOM-IO / BC nguồn |
| BR-05 | Stale recovery | Reallocate trong cùng kho; không tìm kho khác và không âm thầm đổi order| Decision / DOM-IO / BC nguồn |
| BR-06 | Lô thay thế | Phải còn eligible; override FEFO/FIFO cần quyền và lý do| Decision / DOM-IO / BC nguồn |

- `SBC-COM-01` — Bao yêu cầu và định danh.
- `BC-COMMON-EXTENSIONS` — Shared behavioral contract extensions.
- `SBC-COM-02` — Quyền, phạm vi và điều kiện cần.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `SBC-COM-04` — Finality và tính nguyên tử.
- `BC-IO-15` — Save pick allocation.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Pick result gắn đúng allocation version được lưu; discrepancy được ghi rõ để xử lý trước bàn giao. | Hành trình tiếp tục từ kết quả authoritative vừa ghi theo Business Journey sở hữu; không suy bước tiếp theo chỉ từ thứ tự UC. |
| Không đủ điều kiện / Bị từ chối | Nếu precondition, version, quyền hoặc invariant không còn hợp lệ, hệ thống từ chối trước effect; nếu finality chưa rõ thì giữ cùng operation identity để recovery. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** Pick result gắn đúng allocation version được lưu; discrepancy được ghi rõ để xử lý trước bàn giao.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-05 — Lấy hàng và bàn giao đơn](../../../03.design/flows/UIF-05-BJ-05.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-026` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Xác nhận hàng đã lấy”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-05-02-01 — Xác nhận hàng đã lấy — luồng chính
- **Given:** Có allocation active
- **When:** Mở allocation active và lấy hàng theo các dòng/lô được hướng dẫn.
- **Then:** Pick result gắn đúng allocation version được lưu; discrepancy được ghi rõ để xử lý trước bàn giao.

### AS-UC-05-02-02 — Xác nhận hàng đã lấy — Đổi lô khi lấy
- **Given:** Lô được allocation không còn phù hợp hoặc người có quyền chọn lô khác.
- **When:** Chọn lô thay thế còn eligible và ghi reason/override evidence.
- **Then:** Luồng chính tiếp tục tại BF-03: Kiểm tra allocation version còn active, quantity không vượt scope và lô vẫn eligible.

### AS-UC-05-02-03 — Xác nhận hàng đã lấy — Allocation stale
- **Given:** Active allocation đã bị thay version hoặc lô/lượng không còn eligible.
- **When:** Hệ thống phát hiện điều kiện “Allocation stale” tại BF-03.
- **Then:** Không chấp nhận pick result trên version cũ; chuyển UC-05-04 để reallocate. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-05-02-04 — Xác nhận hàng đã lấy — Kết quả lưu pick chưa xác định
- **Given:** Không rõ pick result đã commit hay chưa.
- **When:** Hệ thống phát hiện điều kiện “Kết quả lưu pick chưa xác định” tại BF-04.
- **Then:** Verify bằng cùng identity/version trước khi ghi lại. Giữ nguyên identity/evidence hiện có và bàn giao recovery/finality; không tạo effect trùng hoặc thử lại mù.

## 10. Truy vết

- **Journey:** `BJ-05` — Lấy hàng và bàn giao đơn.
- **Domain:** `DOM-IO`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-15`.

- **Nguồn quyết định:** [Nhóm G04 — Khả dụng, giữ hàng và xuất bán](../../../01.knowledge/decisions/decision-register.md#34-g04-kh%E1%BA%A3-d%E1%BB%A5ng-gi%E1%BB%AF-h%C3%A0ng-l%E1%BA%A5y-h%C3%A0ng-v%C3%A0-xu%E1%BA%A5t)
- **Bài tri thức liên quan:** [Giữ hàng và xử lý đơn không đủ tồn khả dụng](../../../01.knowledge/know-how/KB-KGV-009-giu-hang-va-xu-ly-don-khong-du-ton-kha-dung.md); [Chọn hàng để xuất và thời điểm hoàn tất xuất bán](../../../01.knowledge/know-how/KB-KGV-010-chon-hang-de-xuat-va-thoi-diem-hoan-tat-xuat-ban.md); [Danh tính và vòng đời của một lô hàng](../../../01.knowledge/know-how/KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md)
