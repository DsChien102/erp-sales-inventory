---
id: UC-08-05
type: use-case
theme: theme-07
title: "Hủy phiên kiểm kê"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-08
---

# UC-08-05 — Hủy phiên kiểm kê

## 1. Mục tiêu và kết quả nghiệp vụ

Người có quyền dừng một session kiểm kê chưa final **mà không điều chỉnh tồn**, vẫn giữ đầy đủ evidence đã tạo và giải phóng lock an toàn.

**Kết quả cần đạt:** session chuyển `CANCELLED`, không có adjustment phát sinh, lock được giải phóng; hoặc yêu cầu bị từ chối/UNKNOWN mà không làm mất evidence hay tạo kết quả trùng.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Session đang ở count/recount/blocker context, chưa final và cancellation policy cho phép hủy.

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

UC kết thúc khi trạng thái `CANCELLED` và lock release đã commit cùng nhau; hoặc hủy bị từ chối; hoặc finality chưa xác định và phải đối soát bằng cùng cancellation identity.

### 2.3 Không bao gồm

Không xóa `CountScopeSnapshot`, submission hoặc ApprovalCase lịch sử; không hủy từ browse list như destructive shortcut; không hủy nếu một approval/adjustment command đang `UNKNOWN` hoặc adjustment đã commit.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Người có quyền hủy đúng session context.
- **Thẩm quyền:** Chỉ được hủy session chưa final theo cancellation policy và phải cung cấp lý do hợp lệ.
- **Sự kiện khởi phát:** Người dùng quyết định dừng phiên kiểm kê hiện tại.
- **Điều kiện trước:** Session và lock còn current; không có mutation finality chưa rõ làm hủy trở nên không an toàn.

## 4. Đối tượng và dữ liệu nghiệp vụ

| Đối tượng / Dữ liệu | Ý nghĩa và yêu cầu | Nguồn |
|---|---|---|
| `StockCountSession` | Session cần dừng, chưa ở trạng thái final | `ENT-IC-04` |
| `InventoryLock` | Khóa phải được giải phóng cùng cancellation | `ENT-IC-03` |
| Evidence history | Scope snapshot, submissions, approval cases đã có phải giữ nguyên | `ENT-IC-08/09`, `ENT-IC-02` |
| Cancellation reason | Lý do hủy bắt buộc để audit | `BC-IC-08` |

## 5. Các luồng của Use Case

### 5.1 Luồng chính (Basic Flow)

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| BF-01 | Người dùng | Chọn hủy trong session context và nhập lý do. | BR-01 — Hủy có lý do |
| BF-02 | Hệ thống | Recheck session chưa final, lock current, cancellation policy và không có mutation `UNKNOWN` xung đột. | EF-A — Không được hủy |
| BF-03 | Hệ thống | Commit `CANCELLED`, lock release và outbox atomically; không tạo adjustment. | EF-B — Kết quả chưa xác định |
| BF-04 | Hệ thống | Trả kết quả hủy; evidence lịch sử vẫn truy vết được. | BR-02 — Evidence không bị xóa |
| BF-05 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

Không có luồng thay thế riêng; mọi trường hợp hủy hợp lệ đi qua cùng một commit point.

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Không được hủy

**Phát sinh tại:** BF-02. **Điều kiện:** Thiếu lý do, session đã final, lock không current hoặc có mutation `UNKNOWN` không cho phép chồng lệnh.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Từ chối effect NONE; session và evidence giữ nguyên. | BR-03 — Không hủy chồng finality chưa rõ |
| EF-A-02 | — | [Kết thúc UC]. | |

#### EF-B — Kết quả chưa xác định

**Phát sinh tại:** BF-03. **Điều kiện:** Không thể xác định cancellation transaction đã commit hay rollback.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Giữ cùng cancellation identity; xác minh session/lock finality trước mọi retry. | `SBC-COM-03` — Kết quả và hướng phục hồi |
| EF-B-02 | — | [Tiếp tục tại BJ-17]. | BJ-17 — Phục hồi nghiệp vụ có kết quả chưa xác định |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Hủy có lý do | Cancellation reason là bắt buộc và được lưu cùng actor/time. | `BC-IC-08` |
| BR-02 | Evidence không bị xóa | Scope snapshot, submissions, ApprovalCase và audit đã có vẫn bất biến sau hủy. | `BC-IC-08` |
| BR-03 | Không hủy chồng finality chưa rõ | Session có approval/adjustment command `UNKNOWN` không được nhận thêm cancellation có thể tạo kết quả mâu thuẫn. | `SBC-COM-03` |
| BR-04 | Hủy không tạo adjustment | Cancellation thành công chỉ đóng session và giải phóng lock; không ghi InventoryOperation adjustment. | `BC-IC-08` |

- `BC-IC-08` — Hủy phiên kiểm kê.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `SBC-COM-04` — Atomicity và chống ghi bán phần.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Session `CANCELLED`; no adjustment; lock released; evidence retained | Kết thúc BJ08 |
| Bị từ chối | Session/lock/evidence giữ nguyên | Tiếp tục session hoặc xử lý blocker |
| Chưa xác định (`UNKNOWN`) | Không gửi cancellation identity mới | BJ17 đối soát cùng identity |

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-08 — Kiểm kê và điều chỉnh chênh lệch](../../../03.design/flows/UIF-08-BJ-08.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-044` | Cho phép hủy trong FIRST-count context khi policy cho phép. |
| `SCR-045` | Cho phép hủy trong recount/blocker context khi policy cho phép. |
| `SCR-047` | Hiển thị result sau khi cancellation đã final. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-08-05-01 — Hủy session đang mở
- **Bao phủ:** BF-01 → BF-05; BR-01/02/04.
- **Given:** session chưa final, lock current và người dùng có quyền hủy.
- **When:** người dùng nhập lý do và xác nhận hủy.
- **Then:** session chuyển `CANCELLED`, lock được giải phóng, không có adjustment và evidence cũ vẫn truy vết được.

### AS-UC-08-05-02 — Thiếu lý do hủy
- **Bao phủ:** EF-A; BR-01.
- **Given:** session có thể hủy nhưng người dùng chưa nhập lý do.
- **When:** người dùng xác nhận hủy.
- **Then:** hệ thống từ chối effect NONE; session/lock giữ nguyên.

### AS-UC-08-05-03 — Có mutation UNKNOWN
- **Bao phủ:** EF-A; BR-03.
- **Given:** approval/adjustment command của session đang có finality `UNKNOWN`.
- **When:** người dùng yêu cầu hủy session.
- **Then:** cancellation bị chặn cho tới khi finality được làm rõ; không tạo kết quả chồng lệnh.

### AS-UC-08-05-04 — Timeout khi hủy
- **Bao phủ:** EF-B.
- **Given:** cancellation command đã gửi nhưng response bị mất.
- **When:** người dùng mở lại session.
- **Then:** hệ thống xác minh bằng cùng cancellation identity; không gửi thêm lệnh hủy mới.

## 10. Truy vết

- **Journey:** `BJ-08` — Kiểm kê và điều chỉnh chênh lệch.
- **Domain / Entity:** `DOM-IC`, `ENT-IC-02`, `ENT-IC-03`, `ENT-IC-04`, `ENT-IC-08/09`.
- **Behavioral Contract:** `BC-IC-08`.
- **Decision / Nguồn:** `T7-DR-035…039`, `T7-DR-171…177`.
- **Bài tri thức liên quan:** [KB-KGV-011 — Kiểm kê hàng tồn kho từ khóa phạm vi đến điều chỉnh chênh lệch](../../../01.knowledge/know-how/KB-KGV-011-kiem-ke-hang-ton-kho-tu-khoa-pham-vi-den-dieu-chinh-chenh-lech.md); [KB-KGV-027 — Vòng đời của một Inventory Operation](../../../01.knowledge/know-how/KB-KGV-027-vong-doi-cua-mot-inventory-operation.md)
