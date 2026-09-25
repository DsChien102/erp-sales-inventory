---
id: UC-05-04
type: use-case
theme: theme-07
title: "Phục hồi allocation stale"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-05
---

# UC-05-04 — Phục hồi allocation stale

## 1. Mục tiêu và kết quả nghiệp vụ

Phục hồi allocation khi lô/lượng/version đã stale trước khi bàn giao, không đổi nguồn đặt hàng.

**Kết quả cần đạt:** Allocation successor current được tạo trong cùng kho hoặc fulfillment bị chặn với shortage rõ ràng.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Allocation/order/lot không còn hợp lệ

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Allocation mới hoặc shortage; Recovery result.

### 2.3 Không bao gồm

Không tạo business effect mới để “bù” cho kết quả chưa rõ; chỉ xác minh, đối soát và phục hồi trên cùng operation/command identity.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Nhân viên xử lý đơn hoặc thủ kho.
- **Thẩm quyền:** Chỉ tác nhân/system có quyền recovery trên đúng operation identity được xác minh trạng thái; không được tạo identity mới để né finality hoặc idempotency.
- **Sự kiện khởi phát:** Allocation/order/lot không còn hợp lệ.
- **Điều kiện trước:** Có operation/command identity cần xác minh và đủ audit/source evidence để đối soát; tác nhân/system có quyền recovery đúng phạm vi.

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
| BF-01 | Hệ thống / Thủ kho | Phát hiện allocation/pick stale trước bàn giao. |  |
| BF-02 | Hệ thống | Đọc lại reservation/source và eligible stock trong cùng kho; không tìm kho khác. |  |
| BF-03 | Hệ thống | Tính lại allocation theo FEFO/FIFO và current hold; giữ trace tới allocation version bị thay thế. | AF-A — Không đủ lượng hiện hành |
| BF-04 | Hệ thống | Ghi successor allocation version `ACTIVE` và đánh dấu version cũ `SUPERSEDED`. | EF-A — Kết quả reallocation chưa xác định |
| BF-05 | Thủ kho | Tiếp tục lấy/bàn giao theo version mới. |  |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Không đủ lượng hiện hành
**Phát sinh tại:** BF-03. **Điều kiện:** Current eligible stock không đủ cho lượng còn phải giao..

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Trả shortage và trạng thái chờ/blocked theo source policy; không âm thầm đổi đơn hoặc kho. | |
| AF-A-02 | — | [Kết thúc UC.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Kết quả reallocation chưa xác định
**Phát sinh tại:** BF-04. **Điều kiện:** Không rõ successor version đã commit hay chưa..

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Verify active allocation set trước khi retry; không tạo nhiều active version. | |
| EF-A-02 | — | [Kết thúc/hand-off recovery.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Allocation version | Chỉ một version active; handover phải mang đúng active version| Decision / DOM-IO / BC nguồn |
| BR-02 | Pick | Pick không giảm physical quantity| Decision / DOM-IO / BC nguồn |
| BR-03 | Partial handover | Consume đúng lượng đã giao; reservation còn lại giảm tương ứng và vẫn active nếu source cho phép| Decision / DOM-IO / BC nguồn |
| BR-04 | Không cho partial | Chưa đủ lượng thì toàn bộ handover bị từ chối, không commit bán phần| Decision / DOM-IO / BC nguồn |
| BR-05 | Stale recovery | Revalidate/supersede allocation trong cùng kho khi LOT/source stale hoặc nhận `allocation_review_required`; không tìm kho khác và không âm thầm đổi order| Decision / DOM-IO / BC nguồn |
| BR-06 | Lô thay thế | Phải còn eligible; override FEFO/FIFO cần quyền và lý do| Decision / DOM-IO / BC nguồn |

- `SBC-COM-01` — Bao yêu cầu và định danh.
- `BC-COMMON-EXTENSIONS` — Shared behavioral contract extensions.
- `SBC-COM-02` — Quyền, phạm vi và điều kiện cần.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `SBC-COM-04` — Finality và tính nguyên tử.
- `BC-IO-15` — Save pick allocation.
- `BC-IO-06` — Adjust reservation capacity.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Allocation successor current được tạo trong cùng kho hoặc fulfillment bị chặn với shortage rõ ràng. | Tiếp tục recovery/escalation bằng cùng identity và evidence cho đến khi xác lập được finality hoặc owner xử lý tiếp. |
| Không đủ điều kiện / Bị từ chối | Nếu chưa đủ bằng chứng finality, giữ trạng thái chưa xác định và cùng operation identity; không blind retry, correction hoặc tạo request mới. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** Allocation successor current được tạo trong cùng kho hoặc fulfillment bị chặn với shortage rõ ràng.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-05 — Lấy hàng và bàn giao đơn](../../../03.design/flows/UIF-05-BJ-05.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-026` | Trình bày evidence/finality và hành động phục hồi an toàn cho “Phục hồi allocation stale”; giữ cùng operation identity. |
| `SCR-027` | Trình bày evidence/finality và hành động phục hồi an toàn cho “Phục hồi allocation stale”; giữ cùng operation identity. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-05-04-01 — Phục hồi allocation stale — luồng chính
- **Given:** Allocation/order/lot không còn hợp lệ
- **When:** Phát hiện allocation/pick stale trước bàn giao.
- **Then:** Allocation successor current được tạo trong cùng kho hoặc fulfillment bị chặn với shortage rõ ràng.

### AS-UC-05-04-02 — Phục hồi allocation stale — Không đủ lượng hiện hành
- **Given:** Current eligible stock không đủ cho lượng còn phải giao.
- **When:** Hệ thống phát hiện điều kiện “Không đủ lượng hiện hành” tại BF-03.
- **Then:** Trả shortage và trạng thái chờ/blocked theo source policy; không âm thầm đổi đơn hoặc kho. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-05-04-03 — Phục hồi allocation stale — Kết quả reallocation chưa xác định
- **Given:** Không rõ successor version đã commit hay chưa.
- **When:** Hệ thống phát hiện điều kiện “Kết quả reallocation chưa xác định” tại BF-04.
- **Then:** Verify active allocation set trước khi retry; không tạo nhiều active version. Giữ nguyên identity/evidence hiện có và bàn giao recovery/finality; không tạo effect trùng hoặc thử lại mù.

## 10. Truy vết

- **Journey:** `BJ-05` — Lấy hàng và bàn giao đơn.
- **Domain:** `DOM-IO`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-15`, `BC-IO-06`.

- **Nguồn quyết định:** [Nhóm G04 — Khả dụng, giữ hàng và xuất bán](../../../01.knowledge/decisions/decision-register.md#34-g04-kh%E1%BA%A3-d%E1%BB%A5ng-gi%E1%BB%AF-h%C3%A0ng-l%E1%BA%A5y-h%C3%A0ng-v%C3%A0-xu%E1%BA%A5t)
- **Bài tri thức liên quan:** [Giữ hàng và xử lý đơn không đủ tồn khả dụng](../../../01.knowledge/know-how/KB-KGV-009-giu-hang-va-xu-ly-don-khong-du-ton-kha-dung.md); [Chọn hàng để xuất và thời điểm hoàn tất xuất bán](../../../01.knowledge/know-how/KB-KGV-010-chon-hang-de-xuat-va-thoi-diem-hoan-tat-xuat-ban.md); [Danh tính và vòng đời của một lô hàng](../../../01.knowledge/know-how/KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md)
