---
id: UC-12-03
type: use-case
theme: theme-07
title: "Commit và kích hoạt tồn kho"
owner: BA
status: FROZEN
frozen_at: v5.27.0
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-12
---

# UC-12-03 — Commit và kích hoạt tồn kho

## 1. Mục tiêu và kết quả nghiệp vụ

Commit batch đầu kỳ đã duyệt thành opening movements/balances và kích hoạt inventory một lần duy nhất.

**Kết quả cần đạt:** Opening ledger/balance được tạo nguyên tử và inventory chuyển sang active; hoặc toàn batch không commit.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Có đúng version/hash đã duyệt

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Toàn bộ batch hoàn tất và inventory được mở; hoặc không có gì commit; Opening evidence và activation result.

### 2.3 Không bao gồm

Không re-import hay sửa dòng đã commit để xử lý sai sót. UC chỉ ghi initial balance/movement từ batch đã duyệt đúng một lần; sai sau đó đi correction.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Quản trị triển khai, kế toán kho và người duyệt.
- **Thẩm quyền:** Chỉ tác nhân hoặc system process có quyền thực thi đúng scope mới được commit; mọi guard về source/version, policy và lifecycle phải được server kiểm lại trước effect.
- **Sự kiện khởi phát:** Có đúng version/hash đã duyệt.
- **Điều kiện trước:** Đối tượng đúng version đã đạt trạng thái sẵn sàng thực thi; quyền, policy, lock và các invariant nguồn còn hợp lệ tại thời điểm commit.

## 4. Đối tượng và dữ liệu nghiệp vụ

| Đối tượng / Dữ liệu | Ý nghĩa và yêu cầu | Nguồn |
|---|---|---|
| Nguồn nghiệp vụ và phiên bản | Định danh nguồn/đối tượng nghiệp vụ và phiên bản hiện hành cần dùng để tránh xử lý trên dữ liệu cũ. | DOM-IC / BC liên quan |
| Dữ liệu nghiệp vụ | Các dữ kiện người dùng/nguồn cung cấp cho mục tiêu của Use Case; phải tuân theo rule ở mục 6. | DOM-IC / BC liên quan |
| Phạm vi thực hiện | Tác nhân và phạm vi tenant/cửa hàng/kho mà yêu cầu được phép xử lý. | DOM-IC / BC liên quan |

## 5. Các luồng của Use Case

### 5.1 Luồng chính (Basic Flow)

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| BF-01 | Hệ thống | Nhận batch version đã duyệt để kích hoạt. |  |
| BF-02 | Hệ thống | Recheck batch hash/version, approval, tenant chưa active và không có operational movement. | EF-A — Stale/đã kích hoạt |
| BF-03 | Hệ thống | Ghi opening quantity/value movements và các LOT/state balances theo batch. |  |
| BF-04 | Hệ thống | Đánh dấu activation/freeze và phát outbox/result trong cùng transaction. | EF-B — Kết quả commit chưa xác định |
| BF-05 | Hệ thống | Trả activation result; từ thời điểm này giao dịch vận hành dùng ledger đã khởi tạo. |  |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

Không có luồng thay thế riêng ngoài các nhánh kết quả đã thể hiện trong Luồng chính.

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Stale hoặc đã kích hoạt
**Phát sinh tại:** BF-02. **Điều kiện:** Batch/approval đổi, tenant đã active hoặc đã có movement vận hành .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Reject toàn commit; không trộn opening batch với operational ledger. | |
| EF-A-02 | — | [Kết thúc UC.] | |

#### EF-B — Kết quả commit chưa xác định
**Phát sinh tại:** BF-04. **Điều kiện:** Không rõ activation transaction đã commit .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Giữ activation identity và verify/BJ17; không chạy batch thứ hai. | |
| EF-B-02 | — | [Kết thúc UC.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Activation gate | Khi chưa hoàn tất batch đầu tiên, chỉ nghiệp vụ chuẩn bị/duyệt/commit đầu kỳ được phép; mutation thường bị chặn| Decision / DOM-IC / BC nguồn |
| BR-02 | Một batch chính thức | Chỉ một opening batch được hoàn tất; sai sau activation phải dùng correction/adjustment| Decision / DOM-IC / BC nguồn |
| BR-03 | Dữ liệu bất thường | Quantity âm hoặc quantity bằng 0 nhưng có value bị từ chối; quantity dương phải có căn cứ giá trị đủ để hình thành giá vốn khởi tạo| Decision / DOM-IC / BC nguồn |
| BR-04 | Trùng khóa | Không tự gộp im lặng các dòng trùng product + warehouse + state + lot; phải báo lỗi để sửa nguồn| Decision / DOM-IC / BC nguồn |
| BR-05 | LOT/expiry | Sản phẩm NONE không có lô; sản phẩm LOT bắt buộc mã lô và chỉ bắt buộc hạn dùng khi product policy yêu cầu| Decision / DOM-IC / BC nguồn |
| BR-06 | Trạng thái | Có thể nhập non-sellable khi state được khai rõ; chỉ lượng sellable và đủ dữ liệu mới tăng khả dụng| Decision / DOM-IC / BC nguồn |

- `SBC-COM-01` — Bao yêu cầu và định danh.
- `BC-COMMON-EXTENSIONS` — Shared behavioral contract extensions.
- `SBC-COM-02` — Quyền, phạm vi và điều kiện cần.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `SBC-COM-04` — Finality và tính nguyên tử.
- `BC-IC-04` — Commit opening balance.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Opening ledger/balance được tạo nguyên tử và inventory chuyển sang active; hoặc toàn batch không commit. | Hành trình tiếp tục từ kết quả authoritative vừa ghi theo Business Journey sở hữu; không suy bước tiếp theo chỉ từ thứ tự UC. |
| Không đủ điều kiện / Bị từ chối | Nếu precondition, version, quyền hoặc invariant không còn hợp lệ, hệ thống từ chối trước effect; nếu finality chưa rõ thì giữ cùng operation identity để recovery. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** Opening ledger/balance được tạo nguyên tử và inventory chuyển sang active; hoặc toàn batch không commit.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-12 — Khởi tạo số dư tồn kho đầu kỳ](../../../03.design/flows/UIF-12-BJ-12.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-070` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Commit và kích hoạt tồn kho”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |
| `SCR-071` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Commit và kích hoạt tồn kho”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-12-03-01 — Commit và kích hoạt tồn kho — luồng chính
- **Given:** Có đúng version/hash đã duyệt
- **When:** Nhận batch version đã duyệt để kích hoạt.
- **Then:** Opening ledger/balance được tạo nguyên tử và inventory chuyển sang active; hoặc toàn batch không commit.

### AS-UC-12-03-02 — Commit và kích hoạt tồn kho — Stale hoặc đã kích hoạt
- **Given:** Batch/approval đổi, tenant đã active hoặc đã có movement vận hành.
- **When:** Hệ thống phát hiện điều kiện “Stale hoặc đã kích hoạt” tại BF-02.
- **Then:** Reject toàn commit; không trộn opening batch với operational ledger. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-12-03-03 — Commit và kích hoạt tồn kho — Kết quả commit chưa xác định
- **Given:** Không rõ activation transaction đã commit.
- **When:** Hệ thống phát hiện điều kiện “Kết quả commit chưa xác định” tại BF-04.
- **Then:** Giữ activation identity và verify/BJ17; không chạy batch thứ hai. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

## 10. Truy vết

- **Journey:** `BJ-12` — Khởi tạo số dư tồn kho đầu kỳ.
- **Domain:** `DOM-IC`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-04`.

- **Nguồn quyết định:** [Nhóm G09 — Số dư đầu kỳ và Chuyển đổi chính thức](../../../01.knowledge/decisions/decision-register.md#39-g09-s%E1%BB%91-d%C6%B0-%C4%91%E1%BA%A7u-k%E1%BB%B3-v%C3%A0-chuy%E1%BB%83n-%C4%91%E1%BB%95i-ch%C3%ADnh-th%E1%BB%A9c)
- **Bài tri thức liên quan:** [Chuẩn bị dữ liệu số dư tồn kho đầu kỳ](../../../01.knowledge/know-how/KB-KGV-022-chuan-bi-du-lieu-so-du-ton-kho-dau-ky.md); [Xác nhận số dư đầu kỳ, Chuyển đổi chính thức và đối soát migration](../../../01.knowledge/know-how/KB-KGV-023-xac-nhan-so-du-dau-ky-chuyen-doi-chinh-thuc-va-doi-soat-migration.md); [Kho, cửa hàng và khóa định danh số dư tồn kho](../../../01.knowledge/know-how/KB-KGV-003-kho-cua-hang-va-khoa-dinh-danh-so-du-ton-kho.md); [Đơn vị tính và cách quy đổi số lượng tồn kho](../../../01.knowledge/know-how/KB-KGV-004-don-vi-tinh-va-cach-quy-doi-so-luong-ton-kho.md); [Đơn giá tồn kho chính thức và tổng giá trị ghi sổ](../../../01.knowledge/know-how/KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md)
