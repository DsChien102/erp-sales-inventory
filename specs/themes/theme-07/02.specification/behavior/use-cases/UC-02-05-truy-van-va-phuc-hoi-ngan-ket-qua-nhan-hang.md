---
id: UC-02-05
type: use-case
theme: theme-07
title: "Truy vấn và phục hồi ngắn kết quả nhận hàng"
owner: BA
status: FROZEN
frozen_at: v5.27.0
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-02
---
# UC-02-05 — Truy vấn và phục hồi ngắn kết quả nhận hàng

## 1. Mục tiêu và kết quả nghiệp vụ

Xác định **kết quả cuối của đúng operation nhận hàng đã gửi trước đó** khi client mất response hoặc chưa biết operation đã commit hay chưa, mà không thực hiện lại nghiệp vụ nhận hàng.

Kết quả của UC là một trong ba trạng thái có thể kiểm chứng: `COMMITTED`, `REJECTED` hoặc tiếp tục `UNKNOWN/PROCESSING` với cùng operation identity.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Đã có `operation_id`/command identity của lệnh nhận hàng nhưng client không nhận được finality rõ ràng.

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

- trả đúng kết quả phiếu nhận hàng đã commit; hoặc
- trả rejection authoritative với `effect_status=NONE`; hoặc
- vẫn chưa đủ bằng chứng finality và bàn giao BJ17 sau cửa sổ phục hồi ngắn.

### 2.3 Không bao gồm

- Không tạo phiếu nhận hàng hoặc movement mới.
- Không dùng một operation identity mới để “thử lại”.
- Không sửa payload đã bind với idempotency identity.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Thủ kho hoặc adapter nhận hàng đang chờ kết quả.
- **Thẩm quyền:** Chỉ truy vấn/retry đúng operation đã có; không được biến recovery thành một lệnh nhận hàng mới.
- **Sự kiện khởi phát:** timeout, mất kết nối hoặc response không chứng minh finality.
- **Điều kiện trước:** có operation/command identity và tenant scope hợp lệ.

## 4. Đối tượng và dữ liệu nghiệp vụ

| Đối tượng / Dữ liệu | Ý nghĩa và yêu cầu | Nguồn |
|---|---|---|
| `operation_id` / command identity | Nhận diện đúng lệnh đã gửi | `BC-IO-02`, idempotency record |
| Payload fingerprint | Chứng minh retry vẫn là cùng yêu cầu | Idempotency contract |
| Operation result | `COMMITTED`, `REJECTED`, `PROCESSING/UNKNOWN` và effect refs | `DOM-IO` |
| Phiếu nhận hàng/movement refs | Chỉ trả nếu durable commit đã tồn tại | Ledger/operation result |

## 5. Các luồng của Use Case

### 5.1 Luồng chính (Basic Flow)

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| BF-01 | Thủ kho / Adapter | Gửi truy vấn bằng đúng operation identity đã có. | |
| BF-02 | Hệ thống | Tìm idempotency record và operation result, rồi đối chiếu tenant + payload fingerprint. | EF-A — Sai identity/payload |
| BF-03 | Hệ thống | Nếu operation đã commit, trả authoritative kết quả phiếu nhận hàng và toàn bộ effect refs đã commit. | AF-A — Đã commit |
| BF-04 | Hệ thống | Nếu operation đã bị từ chối trước commit, trả rejection code/reason và `effect_status=NONE`. | AF-B — Đã từ chối |
| BF-05 | Hệ thống | Nếu chưa chứng minh commit/no-commit, giữ cùng identity và trả trạng thái chưa xác định cùng hướng verify/retry an toàn. | AF-C — Chưa có finality |
| BF-06 | — | [Kết thúc UC hoặc bàn giao BJ17 theo AF-C]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Operation đã commit
**Phát sinh tại:** BF-03.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Trả đúng kết quả phiếu nhận hàng đã có; không tạo movement/balance/outbox thứ hai. | BC-IO-02 — Receive purchased goods |
| AF-A-02 | — | [Kết thúc UC]. | |

#### AF-B — Operation đã bị từ chối
**Phát sinh tại:** BF-04.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-B-01 | Hệ thống | Trả `REJECTED` với mã/lý do authoritative và effect NONE. | SBC-COM-03 — Finality |
| AF-B-02 | — | [Kết thúc UC]. | |

#### AF-C — Chưa có finality
**Phát sinh tại:** BF-05.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-C-01 | Hệ thống | Cho phép query/retry bằng **cùng identity và cùng fingerprint** theo contract. | |
| AF-C-02 | Hệ thống | Nếu hết cửa sổ phục hồi ngắn mà vẫn chưa đủ bằng chứng, giữ `UNKNOWN` và tạo handoff BJ17 với evidence refs. | BJ-17 — Phục hồi nghiệp vụ chưa xác định |
| AF-C-03 | — | [Kết thúc UC]. | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Identity hoặc payload không khớp
**Phát sinh tại:** BF-02. **Điều kiện:** operation không thuộc tenant hoặc retry dùng payload khác với identity đã bind.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Từ chối truy vấn/retry; không tạo operation mới và không suy diễn finality. | Idempotency conflict |
| EF-A-02 | — | [Kết thúc UC]. | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Quy tắc | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Same identity | Recovery phải dùng cùng operation/idempotency identity.| G10 / `SBC-COM-03` |
| BR-02 | Không duplicate effect | Query/retry không tạo lại phiếu nhận hàng, movement, balance hoặc outbox đã commit.| `BC-IO-02` |
| BR-03 | UNKNOWN không phải FAILED | Không đủ bằng chứng commit/no-commit thì giữ `UNKNOWN`.| `SBC-COM-03/04` |
| BR-04 | Payload fingerprint bất biến | Cùng identity nhưng payload khác là conflict, không phải retry.| Idempotency contract |

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| `COMMITTED` | Trả result/phiếu nhận hàng đã commit; không có effect mới | Kết thúc BJ02 |
| `REJECTED` | Effect NONE, lý do rõ | Sửa dữ liệu và tạo yêu cầu mới nếu business cho phép |
| `UNKNOWN` | Không tạo operation mới | BJ17 với cùng identity/evidence |

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-02 — Nhận hàng mua](../../../03.design/flows/UIF-02-BJ-02.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-012` | Hiển thị trạng thái đang xác minh/kết quả operation. |
| `SCR-013` | Authoritative result sau khi xác định finality. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-02-05-01 — Response commit bị mất
- **Given:** operation đã commit nhưng response trước bị mất.
- **When:** client query bằng đúng operation identity.
- **Then:** trả đúng kết quả phiếu nhận hàng đã commit và không tạo effect thứ hai.

### AS-UC-02-05-02 — Operation bị từ chối
- **Given:** operation bị reject trước commit.
- **When:** client query result.
- **Then:** trả `REJECTED`, reason và `effect_status=NONE`.

### AS-UC-02-05-03 — Retry khi còn UNKNOWN
- **Given:** operation chưa chứng minh finality.
- **When:** adapter retry cùng identity/fingerprint.
- **Then:** deduplicate/tiếp tục đúng operation, không sinh identity mới.

### AS-UC-02-05-04 — Hết cửa sổ phục hồi ngắn
- **Given:** vẫn chưa đủ bằng chứng finality.
- **When:** recovery window kết thúc.
- **Then:** giữ `UNKNOWN` và handoff BJ17 với cùng identity/evidence.

## 10. Truy vết

- **Journey:** `BJ-02` — Nhận hàng mua.
- **Domain:** `DOM-IO`.
- **BC:** `BC-IO-02`, `SBC-COM-03/04`.
- **Decision:** Nhóm G03, G10.
- **Bài tri thức liên quan:** [KB-KGV-027 — Vòng đời của một Inventory Operation](../../../01.knowledge/know-how/KB-KGV-027-vong-doi-cua-mot-inventory-operation.md); [KB-KGV-028 — Idempotency, phiên bản nguồn và xử lý kết quả chưa xác định](../../../01.knowledge/know-how/KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md); [KB-KGV-032 — Movement ledger, số dư dẫn xuất và phục hồi sau sự cố](../../../01.knowledge/know-how/KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md)
