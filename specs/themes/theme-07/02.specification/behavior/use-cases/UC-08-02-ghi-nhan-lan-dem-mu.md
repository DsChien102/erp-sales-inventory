---
id: UC-08-02
type: use-case
theme: theme-07
title: "Ghi nhận lần đếm mù"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-08
---

# UC-08-02 — Ghi nhận lần đếm mù

## 1. Mục tiêu và kết quả nghiệp vụ

Người được phân công ghi nhận **lần đếm vật lý đầu tiên** mà không nhìn thấy book quantity hoặc variance trước khi submit, nhằm bảo đảm bằng chứng kiểm kê không bị neo vào số liệu hệ thống.

**Kết quả cần đạt:** một `StockCountSubmission` FIRST bất biến được ghi; sau submit hệ thống mới tính variance để kết thúc phiên nếu khớp hoặc chuyển đúng các dòng chênh lệch sang đếm lại.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Session đang `OPEN/LOCKED`, FIRST round chưa được submit và người dùng là assigned counter hiện hành.

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

UC kết thúc khi FIRST submission đã commit và variance được xác định; zero variance hoàn tất phiên, còn non-zero tạo tập discrepant lines để đếm lại; hoặc submit chưa xác định finality và phải recovery bằng cùng identity.

### 2.3 Không bao gồm

Không cho counter thấy book quantity/variance trước FIRST submit, không nhập giá hàng thừa, không phê duyệt chênh lệch và không sửa evidence sau khi đã submit.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Assigned counter của session.
- **Thẩm quyền:** Chỉ được nhập/submit observation cho đúng assignment version và frozen scope; không có quyền duyệt adjustment của chính snapshot đã đếm.
- **Sự kiện khởi phát:** Counter mở công việc đếm lần đầu của session đã khóa.
- **Điều kiện trước:** Session/lock còn current; assignment còn hiệu lực; FIRST round chưa tồn tại ở trạng thái committed.

## 4. Đối tượng và dữ liệu nghiệp vụ

| Đối tượng / Dữ liệu | Ý nghĩa và yêu cầu | Nguồn |
|---|---|---|
| `PhysicalCountKey` | Dòng vật lý cần đếm trong frozen scope | `DOM-IC`, `T7-DR-173` |
| Observation | Số lượng thực tế theo base UOM/precision snapshot | `ENT-IC-09` |
| `StockCountSubmission` | Bằng chứng append-only của FIRST round | `ENT-IC-09`, `T7-DR-174` |
| Assignment version | Xác định ai được phép submit round hiện hành | `ENT-IC-04` |

## 5. Các luồng của Use Case

### 5.1 Luồng chính (Basic Flow)

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| BF-01 | Counter | Mở FIRST round được phân công; giao diện không hiển thị book quantity hoặc variance. | BR-01 — Blind count |
| BF-02 | Counter | Nhập số lượng thực tế theo từng `PhysicalCountKey`; ghi nhận unexpected physical item chỉ khi thuộc frozen scope. | EF-A — Dòng ngoài phạm vi |
| BF-03 | Hệ thống | Kiểm tra actor, assignment version, scope, tracking, UOM/precision và line identity. | EF-B — Actor không được phân công |
| BF-04 | Counter | Submit FIRST round. | |
| BF-05 | Hệ thống | Commit immutable FIRST submission, sau đó mới tính variance. | AF-A — Không có chênh lệch<br>AF-B — Có chênh lệch<br>EF-C — Kết quả chưa xác định |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Không có chênh lệch

**Phát sinh tại:** BF-05. **Điều kiện:** Final variance của FIRST round bằng 0.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Hoàn tất session và giải phóng lock trong cùng transaction; không tạo ApprovalCase hoặc adjustment. | BR-03 — Zero variance kết thúc trực tiếp |
| AF-A-02 | — | [Kết thúc BJ-08]. | |

#### AF-B — Có chênh lệch

**Phát sinh tại:** BF-05. **Điều kiện:** Có ít nhất một dòng có variance khác 0.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-B-01 | Hệ thống | Chỉ đưa các dòng chênh lệch sang `RECOUNT_REQUIRED`; dòng khớp giữ evidence FIRST hiện tại. | BR-02 — Evidence append-only |
| AF-B-02 | — | [Tiếp tục tại UC-08-03]. | UC-08-03 — Đếm lại và hoàn thiện căn cứ |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Dòng ngoài phạm vi

**Phát sinh tại:** BF-02. **Điều kiện:** Observation trỏ tới key không thuộc frozen scope.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Từ chối dòng với `COUNT_LINE_OUT_OF_SCOPE`; không tự mở rộng session scope. | |
| EF-A-02 | — | [Trở lại BF-02]. | BF-02 — Tiếp tục đếm các dòng hợp lệ |

#### EF-B — Actor không được phân công

**Phát sinh tại:** BF-03. **Điều kiện:** Người submit không khớp assignment hiện hành.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Từ chối với `COUNT_ACTOR_NOT_ASSIGNED`; không ghi submission. | |
| EF-B-02 | — | [Kết thúc UC]. | |

#### EF-C — Kết quả chưa xác định

**Phát sinh tại:** BF-05. **Điều kiện:** Không thể xác định FIRST submission đã commit hay chưa.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-C-01 | Hệ thống | Giữ cùng submission identity; không cho tạo FIRST round thứ hai trước khi đối soát. | `SBC-COM-03` — Kết quả và hướng phục hồi |
| EF-C-02 | — | [Tiếp tục tại BJ-17]. | BJ-17 — Phục hồi nghiệp vụ có kết quả chưa xác định |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Blind count thực sự | Trước FIRST submit, counter không được nhận book quantity, variance hoặc proxy có thể suy ra các số đó. | `T7-DR-036`, `T7-DR-174` |
| BR-02 | Evidence append-only | FIRST submission đã commit không bị overwrite; recount sau này tạo submission mới có lineage. | `T7-DR-174` |
| BR-03 | Zero variance kết thúc trực tiếp | Nếu variance bằng 0, session hoàn tất và mở khóa mà không cần approval/adjustment. | `T7-DR-177` |
| BR-04 | Counter không định giá surplus | Người đếm không nhập giá trị hàng thừa; value basis thuộc nguồn có thẩm quyền khác. | `T7-DR-176` |

- `BC-IC-02` — Ghi nhận count/recount evidence.
- `SBC-COM-03` — Kết quả và hướng phục hồi.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Không có chênh lệch | FIRST submission bất biến; session completed; lock released; không adjustment | Kết thúc BJ08 |
| Có chênh lệch | FIRST submission bất biến; chỉ discrepant lines cần recount | `UC-08-03` |
| Bị từ chối | Không ghi submission | Counter/owner xử lý assignment hoặc scope |
| Chưa xác định (`UNKNOWN`) | Không append submission trùng | BJ17 đối soát cùng identity |

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-08 — Kiểm kê và điều chỉnh chênh lệch](../../../03.design/flows/UIF-08-BJ-08.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-044` | Giao diện blind count cho FIRST round; không lộ book/variance trước submit. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-08-02-01 — FIRST round không lộ số sổ
- **Bao phủ:** BF-01 → BF-05; BR-01.
- **Given:** session đã khóa và counter được phân công.
- **When:** counter mở FIRST round.
- **Then:** UI không chứa book quantity, variance hoặc proxy có thể suy ra chúng trước submit.

### AS-UC-08-02-02 — Dòng ngoài frozen scope
- **Bao phủ:** EF-A.
- **Given:** counter nhập một key không thuộc `CountScopeSnapshot`.
- **When:** hệ thống validate observation.
- **Then:** dòng bị từ chối; scope không tự mở rộng và các dòng hợp lệ khác vẫn có thể tiếp tục.

### AS-UC-08-02-03 — Zero variance
- **Bao phủ:** AF-A; BR-03.
- **Given:** FIRST submission đã commit và mọi dòng khớp book snapshot.
- **When:** hệ thống tính variance.
- **Then:** session hoàn tất, lock được giải phóng và không tạo ApprovalCase/adjustment.

### AS-UC-08-02-04 — Timeout khi submit
- **Bao phủ:** EF-C; BR-02.
- **Given:** FIRST submit đã gửi nhưng client mất kết nối.
- **When:** counter mở lại công việc.
- **Then:** hệ thống dùng cùng submission identity để làm rõ kết quả; không tạo FIRST round thứ hai.

## 10. Truy vết

- **Journey:** `BJ-08` — Kiểm kê và điều chỉnh chênh lệch.
- **Domain / Entity:** `DOM-IC`, `ENT-IC-04`, `ENT-IC-05`, `ENT-IC-09`.
- **Behavioral Contract:** `BC-IC-02`.
- **Decision / Nguồn:** `T7-DR-035…039`, `T7-DR-174`, `T7-DR-176/177`.
