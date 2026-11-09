---
id: UC-05-01
type: use-case
theme: theme-07
title: "Lập allocation"
owner: BA
status: FROZEN
frozen_at: v5.27.0
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-05
---

# UC-05-01 — Lập allocation

## 1. Mục tiêu và kết quả nghiệp vụ

Tạo một allocation version ổn định cho lượng cần lấy từ reservation/source dựa trên hàng đủ điều kiện hiện hành.

**Kết quả cần đạt:** Một `PickAllocation` version active được tạo; chưa giảm tồn vật lý.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Đơn/reservation sẵn sàng

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Một allocation version active được tạo; Stable allocation set.

### 2.3 Không bao gồm

Không giảm tồn và không consume reservation. UC chỉ xác định lô/lượng sẽ lấy theo FEFO/FIFO hoặc override có quyền, lưu thành một allocation version có thể truy vết.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Hệ thống Inventory theo source/reservation; nhân viên/thủ kho là consumer của kết quả allocation.
- **Thẩm quyền:** Chỉ tác nhân hoặc system process có quyền thực thi đúng scope mới được commit; mọi guard về source/version, policy và lifecycle phải được server kiểm lại trước effect.
- **Sự kiện khởi phát:** Đơn/reservation sẵn sàng.
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
| BF-01 | Hệ thống | Nhận fulfillment/reservation/source scope đã sẵn sàng lấy hàng. |  |
| BF-02 | Hệ thống | Đọc current hold và hàng đủ điều kiện trong đúng kho; khóa dữ liệu cần thiết để tránh allocation vượt khả dụng. | EF-A — Không đủ lượng theo policy |
| BF-03 | Hệ thống | Chọn lô theo FEFO với hàng có HSD, FIFO với hàng không có HSD; tạo các allocation line theo quantity cần lấy. | AF-A — Override lô có thẩm quyền |
| BF-04 | Hệ thống | Ghi `allocation_set_id` + version mới và đặt duy nhất version này `ACTIVE`; không thay physical quantity. | EF-B — Kết quả tạo allocation chưa xác định |
| BF-05 | Hệ thống | Trả allocation cho bề mặt lấy hàng. |  |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Override lô có thẩm quyền
**Phát sinh tại:** BF-03. **Điều kiện:** Policy cho phép người có quyền chọn lô khác FEFO/FIFO .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Nhân viên/Thủ kho | Chọn lô thay thế còn eligible và ghi lý do override. | |
| AF-A-02 | — | [Hệ thống tạo allocation theo lựa chọn và lưu dấu vết override.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Không đủ lượng theo policy
**Phát sinh tại:** BF-02. **Điều kiện:** Eligible stock không đủ cho lượng phải lấy và source không cho partial .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Không tạo allocation bán phần; trả shortage/blocked rõ ràng. | |
| EF-A-02 | — | [Kết thúc UC.] | |

#### EF-B — Kết quả tạo allocation chưa xác định
**Phát sinh tại:** BF-04. **Điều kiện:** Không rõ allocation version đã commit hay chưa .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Giữ cùng identity và verify active version trước khi tạo lại. | |
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
| Thành công | Một `PickAllocation` version active được tạo; chưa giảm tồn vật lý. | Hành trình tiếp tục từ kết quả authoritative vừa ghi theo Business Journey sở hữu; không suy bước tiếp theo chỉ từ thứ tự UC. |
| Không đủ điều kiện / Bị từ chối | Nếu precondition, version, quyền hoặc invariant không còn hợp lệ, hệ thống từ chối trước effect; nếu finality chưa rõ thì giữ cùng operation identity để recovery. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** Một `PickAllocation` version active được tạo; chưa giảm tồn vật lý.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-05 — Lấy hàng và bàn giao đơn](../../../03.design/flows/UIF-05-BJ-05.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-025` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Lập allocation”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |
| `SCR-026` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Lập allocation”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-05-01-01 — Lập allocation — luồng chính
- **Given:** Đơn/reservation sẵn sàng
- **When:** Nhận fulfillment/reservation/source scope đã sẵn sàng lấy hàng.
- **Then:** Một `PickAllocation` version active được tạo; chưa giảm tồn vật lý.

### AS-UC-05-01-02 — Lập allocation — Override lô có thẩm quyền
- **Given:** Policy cho phép người có quyền chọn lô khác FEFO/FIFO.
- **When:** Chọn lô thay thế còn eligible và ghi lý do override.
- **Then:** Hệ thống tạo allocation theo lựa chọn và lưu dấu vết override.

### AS-UC-05-01-03 — Lập allocation — Không đủ lượng theo policy
- **Given:** Eligible stock không đủ cho lượng phải lấy và source không cho partial.
- **When:** Hệ thống phát hiện điều kiện “Không đủ lượng theo policy” tại BF-02.
- **Then:** Không tạo allocation bán phần; trả shortage/blocked rõ ràng. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-05-01-04 — Lập allocation — Kết quả tạo allocation chưa xác định
- **Given:** Không rõ allocation version đã commit hay chưa.
- **When:** Hệ thống phát hiện điều kiện “Kết quả tạo allocation chưa xác định” tại BF-04.
- **Then:** Giữ cùng identity và verify active version trước khi tạo lại. Giữ nguyên identity/evidence hiện có và bàn giao recovery/finality; không tạo effect trùng hoặc thử lại mù.

## 10. Truy vết

- **Journey:** `BJ-05` — Lấy hàng và bàn giao đơn.
- **Domain:** `DOM-IO`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-15`.

- **Nguồn quyết định:** [Nhóm G04 — Khả dụng, giữ hàng và xuất bán](../../../01.knowledge/decisions/decision-register.md#34-g04-kh%E1%BA%A3-d%E1%BB%A5ng-gi%E1%BB%AF-h%C3%A0ng-l%E1%BA%A5y-h%C3%A0ng-v%C3%A0-xu%E1%BA%A5t)
- **Bài tri thức liên quan:** [Giữ hàng và xử lý đơn không đủ tồn khả dụng](../../../01.knowledge/know-how/KB-KGV-009-giu-hang-va-xu-ly-don-khong-du-ton-kha-dung.md); [Chọn hàng để xuất và thời điểm hoàn tất xuất bán](../../../01.knowledge/know-how/KB-KGV-010-chon-hang-de-xuat-va-thoi-diem-hoan-tat-xuat-ban.md); [Danh tính và vòng đời của một lô hàng](../../../01.knowledge/know-how/KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md)
