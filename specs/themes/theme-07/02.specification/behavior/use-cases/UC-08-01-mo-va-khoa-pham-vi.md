---
id: UC-08-01
type: use-case
theme: theme-07
title: "Mở và khóa phạm vi"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-08
---

# UC-08-01 — Mở và khóa phạm vi

## 1. Mục tiêu và kết quả nghiệp vụ

Người có quyền mở một phiên kiểm kê với **phạm vi, thời điểm chốt sổ và khóa phạm vi bất biến**, để mọi lần đếm sau đó đều được so sánh với cùng một sự thật sổ kho.

**Kết quả cần đạt:** `StockCountSession`, `CountScopeSnapshot`, book snapshot và `InventoryLock` được ghi trong cùng một atomic boundary; hoặc yêu cầu bị từ chối mà không để lại session/lock dở dang.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Có nhu cầu kiểm kê tại một kho, với phạm vi và lý do kiểm kê đã xác định.

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

UC kết thúc khi session đã được mở và khóa thành công với `cutoff_ledger_sequence` cố định; hoặc yêu cầu bị từ chối trước khi tạo session; hoặc kết quả mutation chưa xác định và phải phục hồi bằng cùng command identity.

### 2.3 Không bao gồm

Không nhập số đếm, không tự xử lý lượng `VALUATION_PENDING`, không sửa Product/LOT master và không điều chỉnh tồn tại bước mở phiên.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Người có quyền mở kiểm kê trong warehouse scope.
- **Thẩm quyền:** Được chọn phạm vi kiểm kê trong kho được cấp quyền; không được tự mở rộng phạm vi sau khi session đã khóa.
- **Sự kiện khởi phát:** Người dùng bắt đầu một phiên kiểm kê mới.
- **Điều kiện trước:** Không có lock/session xung đột; phạm vi resolve được; scope không chứa physical key có valuation chưa giải quyết hoặc mixed valuation state bị Phase 1 chặn.

## 4. Đối tượng và dữ liệu nghiệp vụ

| Đối tượng / Dữ liệu | Ý nghĩa và yêu cầu | Nguồn |
|---|---|---|
| `CountScopeSnapshot` | Phạm vi kiểm kê đã freeze; thay đổi master/group sau đó không làm đổi membership | `ENT-IC-08`, `T7-DR-172` |
| `cutoff_ledger_sequence` | Mốc sổ kho dùng dựng book snapshot cho phiên | `DOM-IO`, `T7-DR-171` |
| `InventoryLock` | Khóa các mutation có thể làm sai snapshot trong phạm vi | `ENT-IC-03` |
| `PhysicalCountKey` | Warehouse + Product + physical state + LOT/non-LOT; không chứa valuation state | `DOM-IC`, `T7-DR-173` |

## 5. Các luồng của Use Case

### 5.1 Luồng chính (Basic Flow)

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| BF-01 | Người dùng | Chọn kho, phạm vi và lý do kiểm kê. | |
| BF-02 | Hệ thống | Chuẩn hóa phạm vi và resolve exact `CountScopeSnapshot`. | AF-A — Phạm vi theo nhóm sản phẩm<br>EF-A — Phạm vi không hợp lệ |
| BF-03 | Hệ thống | Acquire scope barrier, chờ hoặc serialize các mutation đang chạy trong phạm vi. | EF-B — Xung đột khóa |
| BF-04 | Hệ thống | Chốt `cutoff_ledger_sequence` và dựng book snapshot theo `PhysicalCountKey`. | EF-C — Có valuation chưa giải quyết |
| BF-05 | Hệ thống | Commit session, scope snapshot, count lines, book snapshot, lock và command receipt trong cùng transaction. | EF-D — Kết quả chưa xác định |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Phạm vi theo nhóm sản phẩm

**Phát sinh tại:** BF-02. **Điều kiện:** Người dùng chọn phạm vi dựa trên một nhóm sản phẩm động.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Resolve và freeze exact Product membership của nhóm tại thời điểm mở phiên. | BR-02 — Phạm vi bất biến |
| AF-A-02 | — | [Trở lại BF-03]. | BF-03 — Khóa phạm vi |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Phạm vi rỗng hoặc không hợp lệ

**Phát sinh tại:** BF-02. **Điều kiện:** Phạm vi không resolve được hoặc không có đối tượng hợp lệ để kiểm kê.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Từ chối yêu cầu; không tạo session, snapshot hoặc lock. | |
| EF-A-02 | — | [Kết thúc UC]. | |

#### EF-B — Xung đột khóa

**Phát sinh tại:** BF-03. **Điều kiện:** Có lock/session khác không cho phép mở chồng trên cùng phạm vi.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Từ chối trước khi tạo session; không để orphan lock. | BR-01 — Atomic open |
| EF-B-02 | — | [Kết thúc UC]. | |

#### EF-C — Có valuation chưa giải quyết

**Phát sinh tại:** BF-04. **Điều kiện:** Một physical key trong scope còn `VALUATION_PENDING` hoặc mixed valuation state bị policy chặn.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-C-01 | Hệ thống | Từ chối với `COUNT_SCOPE_HAS_UNRESOLVED_VALUATION`; không mở session. | BJ-03 — Xác lập giá trị ban đầu của hàng nhận |
| EF-C-02 | — | [Kết thúc UC]. | |

#### EF-D — Kết quả chưa xác định

**Phát sinh tại:** BF-05. **Điều kiện:** Client không thể xác định transaction mở phiên đã commit hay rollback.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-D-01 | Hệ thống | Giữ cùng command/session identity; không tạo phiên mới trước khi đối soát finality. | `SBC-COM-03` — Kết quả và hướng phục hồi |
| EF-D-02 | — | [Tiếp tục tại BJ-17]. | BJ-17 — Phục hồi nghiệp vụ có kết quả chưa xác định |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Mở phiên nguyên tử | Scope barrier, cutoff, book snapshot, session và lock phải cùng thành công hoặc cùng không phát sinh. | `T7-DR-171` |
| BR-02 | Phạm vi bất biến | Membership của `CountScopeSnapshot` không thay đổi theo master/group sau khi phiên được mở. | `T7-DR-172` |
| BR-03 | Physical key không chứa valuation state | Người đếm không được nhìn/nhập valuation state như một dimension vật lý. | `T7-DR-173` |
| BR-04 | Khóa mutation sau cut-off | Mutation matching frozen scope không được commit sau cutoff trong thời gian lock còn hiệu lực. | `T7-DR-171` |

- `BC-IC-01` — Mở và khóa phiên kiểm kê.
- `SBC-COM-03` — Kết quả và hướng phục hồi.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Session `OPEN/LOCKED`; scope/cutoff/book/lock đã cố định | `UC-08-02` — Ghi nhận lần đếm mù |
| Bị từ chối | Không tạo session/lock hoặc adjustment | Sửa phạm vi/blocker rồi mở lại |
| Chưa xác định (`UNKNOWN`) | Không tạo command/session identity mới | BJ17 đối soát finality |

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-08 — Kiểm kê và điều chỉnh chênh lệch](../../../03.design/flows/UIF-08-BJ-08.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-042` | Điểm vào danh sách/khởi tạo phiên kiểm kê. |
| `SCR-043` | Chọn kho, phạm vi, lý do và xác nhận mở phiên. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-08-01-01 — Mở phiên với phạm vi hợp lệ
- **Bao phủ:** BF-01 → BF-06; BR-01/02/04.
- **Given:** kho và phạm vi hợp lệ, không có lock xung đột.
- **When:** người dùng mở phiên kiểm kê.
- **Then:** scope snapshot, cutoff, book snapshot và lock được commit cùng session trong một boundary.

### AS-UC-08-01-02 — Nhóm sản phẩm thay đổi sau khi mở
- **Bao phủ:** AF-A; BR-02.
- **Given:** phiên được mở từ nhóm sản phẩm có membership A, B tại thời điểm mở.
- **When:** nhóm sản phẩm sau đó được thêm C.
- **Then:** phiên vẫn chỉ kiểm kê A, B; membership frozen không tự đổi.

### AS-UC-08-01-03 — Scope còn valuation chưa giải quyết
- **Bao phủ:** EF-C; BR-03.
- **Given:** một physical key trong scope còn `VALUATION_PENDING`.
- **When:** hệ thống chuẩn bị book snapshot.
- **Then:** yêu cầu bị từ chối, không tạo session/lock và chỉ rõ BJ03 là nơi xử lý nghĩa vụ định giá.

### AS-UC-08-01-04 — Timeout khi mở phiên
- **Bao phủ:** EF-D.
- **Given:** command mở phiên đã gửi nhưng client mất kết nối trước khi nhận kết quả.
- **When:** người dùng thử tiếp tục.
- **Then:** hệ thống dùng cùng identity để xác minh finality; không mở thêm phiên thứ hai.

## 10. Truy vết

- **Journey:** `BJ-08` — Kiểm kê và điều chỉnh chênh lệch.
- **Domain / Entity:** `DOM-IC`, `ENT-IC-03`, `ENT-IC-04`, `ENT-IC-08`.
- **Behavioral Contract:** `BC-IC-01`.
- **Decision / Nguồn:** `T7-DR-035…039`, `T7-DR-171…173`.
