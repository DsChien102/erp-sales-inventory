---
id: UC-05-03
type: use-case
theme: theme-07
title: "Bàn giao hàng"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v3.12.0
---

# UC-05-03 — Bàn giao hàng

## 1. Mục tiêu và kết quả nghiệp vụ

Xác nhận lượng hàng thực tế đã bàn giao cho khách/đơn vị vận chuyển trên pick/allocation hiện hành.

**Kết quả cần đạt:** Handover fact hợp lệ được xác lập để UC-05-05 ghi xuất; partial handover chỉ tồn tại khi source policy cho phép.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Hàng đã pick và allocation hợp lệ

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Xuất toàn phần/một phần hoặc bị từ chối; Handover issue result.

### 2.3 Không bao gồm

Không tự ghi giảm tồn nếu điều kiện bàn giao chưa hoàn tất. UC chỉ xác nhận việc bàn giao vật lý và bằng chứng bàn giao đủ để bước ghi xuất kho nguyên tử tiếp tục.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Nhân viên xử lý đơn hoặc thủ kho.
- **Thẩm quyền:** Chỉ tác nhân hoặc system process có quyền thực thi đúng scope mới được commit; mọi guard về source/version, policy và lifecycle phải được server kiểm lại trước effect.
- **Sự kiện khởi phát:** Hàng đã pick và allocation hợp lệ.
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
| BF-01 | Nhân viên/Thủ kho | Mở fulfillment đã có pick result và chuẩn bị bàn giao. |  |
| BF-02 | Hệ thống | Nạp active allocation/pick version, requested quantity và policy partial handover. | EF-A — Pick/allocation stale |
| BF-03 | Nhân viên/Thủ kho | Xác nhận lượng thực tế bàn giao và người/đơn vị nhận. | AF-A — Bàn giao một phần |
| BF-04 | Hệ thống | Kiểm tra lượng bàn giao không vượt pick/current source và tạo handover assertion/version. | EF-B — Không đủ lượng nhưng source cấm partial |
| BF-05 | Hệ thống | Bàn giao assertion sang UC-05-05; bản thân UC này chưa ghi giảm tồn. |  |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Bàn giao một phần
**Phát sinh tại:** BF-03. **Điều kiện:** Lượng thực tế nhỏ hơn requested và source cho phép partial .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Giữ phần chưa giao ở lifecycle phù hợp; handover chỉ chứa lượng thực giao. | |
| AF-A-02 | — | [Tiếp tục BF-04.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Pick/allocation stale
**Phát sinh tại:** BF-02. **Điều kiện:** Allocation/pick version không còn current .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Chặn bàn giao và yêu cầu phục hồi allocation trước. | |
| EF-A-02 | — | [Kết thúc UC.] | |

#### EF-B — Nguồn không cho phép partial
**Phát sinh tại:** BF-04. **Điều kiện:** Lượng bàn giao nhỏ hơn yêu cầu nhưng policy là all-or-nothing .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Từ chối toàn handover assertion; không ghi xuất bán phần. | |
| EF-B-02 | — | [Kết thúc UC.] | |

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
- `BC-IO-05` — Pick and hand over fulfillment.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Handover fact hợp lệ được xác lập để UC-05-05 ghi xuất; partial handover chỉ tồn tại khi source policy cho phép. | Hành trình tiếp tục từ kết quả authoritative vừa ghi theo Business Journey sở hữu; không suy bước tiếp theo chỉ từ thứ tự UC. |
| Không đủ điều kiện / Bị từ chối | Nếu precondition, version, quyền hoặc invariant không còn hợp lệ, hệ thống từ chối trước effect; nếu finality chưa rõ thì giữ cùng operation identity để recovery. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |

**Ảnh hưởng nghiệp vụ chính:** Handover fact hợp lệ được xác lập để UC-05-05 ghi xuất; partial handover chỉ tồn tại khi source policy cho phép.

## 8. Liên hệ giao diện

| Screen | Vai trò trong UC |
|---|---|
| `SCR-028` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Bàn giao hàng”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |
| `SCR-029` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Bàn giao hàng”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-05-03-01 — Bàn giao hàng — luồng chính
- **Given:** Hàng đã pick và allocation hợp lệ
- **When:** Mở fulfillment đã có pick result và chuẩn bị bàn giao.
- **Then:** Handover fact hợp lệ được xác lập để UC-05-05 ghi xuất; partial handover chỉ tồn tại khi source policy cho phép.

### AS-UC-05-03-02 — Bàn giao hàng — Bàn giao một phần
- **Given:** Lượng thực tế nhỏ hơn requested và source cho phép partial.
- **When:** Hệ thống phát hiện điều kiện “Bàn giao một phần” tại BF-03.
- **Then:** Giữ phần chưa giao ở lifecycle phù hợp; handover chỉ chứa lượng thực giao. Luồng chính tiếp tục tại BF-04: Kiểm tra lượng bàn giao không vượt pick/current source và tạo handover assertion/version.

### AS-UC-05-03-03 — Bàn giao hàng — Pick/allocation stale
- **Given:** Allocation/pick version không còn current.
- **When:** Hệ thống phát hiện điều kiện “Pick/allocation stale” tại BF-02.
- **Then:** Chặn bàn giao và yêu cầu phục hồi allocation trước. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-05-03-04 — Bàn giao hàng — Nguồn không cho phép partial
- **Given:** Lượng bàn giao nhỏ hơn yêu cầu nhưng policy là all-or-nothing.
- **When:** Hệ thống phát hiện điều kiện “Nguồn không cho phép partial” tại BF-04.
- **Then:** Từ chối toàn handover assertion; không ghi xuất bán phần. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

## 10. Truy vết

- **Journey:** `BJ-05` — Lấy hàng và bàn giao đơn.
- **Domain:** `DOM-IO`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-05`.

- **Nguồn quyết định:** [Nhóm G04 — Khả dụng, giữ hàng và xuất bán](../../../01.knowledge/decisions/decision-register.md#34-g04-kh%E1%BA%A3-d%E1%BB%A5ng-gi%E1%BB%AF-h%C3%A0ng-l%E1%BA%A5y-h%C3%A0ng-v%C3%A0-xu%E1%BA%A5t)
- **Bài tri thức liên quan:** [Giữ hàng và xử lý đơn không đủ tồn khả dụng](../../../01.knowledge/know-how/KB-KGV-009-giu-hang-va-xu-ly-don-khong-du-ton-kha-dung.md); [Chọn hàng để xuất và thời điểm hoàn tất xuất bán](../../../01.knowledge/know-how/KB-KGV-010-chon-hang-de-xuat-va-thoi-diem-hoan-tat-xuat-ban.md); [Danh tính và vòng đời của một lô hàng](../../../01.knowledge/know-how/KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md)
