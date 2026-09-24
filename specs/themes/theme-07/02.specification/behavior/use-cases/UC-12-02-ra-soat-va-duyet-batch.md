---
id: UC-12-02
type: use-case
theme: theme-07
title: "Rà soát và duyệt batch"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v3.12.0
---

# UC-12-02 — Rà soát và duyệt batch

## 1. Mục tiêu và kết quả nghiệp vụ

Rà soát và phê duyệt batch số dư đầu kỳ đã validation, bảo đảm maker/approver và tổng kiểm soát trước activation.

**Kết quả cần đạt:** Batch được duyệt sẵn sàng commit hoặc bị từ chối có lý do; operational inventory vẫn chưa active.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Có prepared batch hợp lệ

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Batch được duyệt hoặc từ chối; Approval decision độc lập với người lập.

### 2.3 Không bao gồm

Không commit tồn đầu kỳ và không sửa dòng nguồn đã khóa. UC chỉ ghi quyết định duyệt/từ chối batch sau khi rà soát phạm vi, lỗi và tổng hợp.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Quản trị triển khai, kế toán kho và người duyệt.
- **Thẩm quyền:** Chỉ tác nhân có quyền phê duyệt đúng policy và phạm vi mới được ra quyết định; quyết định không thay thế bước thực thi nghiệp vụ phía sau.
- **Sự kiện khởi phát:** Có prepared batch hợp lệ.
- **Điều kiện trước:** Hồ sơ/case đúng version đang ở trạng thái chờ quyết định; tác nhân có quyền phê duyệt theo policy và đọc được snapshot/evidence làm căn cứ.

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
| BF-01 | Người duyệt | Mở batch đã validation và xem tổng quantity/value, lỗi cảnh báo và sample/chi tiết. |  |
| BF-02 | Hệ thống | Kiểm tra quyền, segregation và batch version; bảo đảm không có giao dịch vận hành chen vào. | EF-A — Không đủ quyền/stale |
| BF-03 | Người duyệt | Quyết định Duyệt hoặc Từ chối batch. | AF-A — Từ chối |
| BF-04 | Hệ thống | Commit approval và khóa batch version cho UC-12-03. | EF-B — Kết quả quyết định chưa xác định |
| BF-05 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Từ chối
**Phát sinh tại:** BF-03. **Điều kiện:** Batch cần sửa hoặc evidence chưa đủ .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Người duyệt | Ghi lý do từ chối. | |
| AF-A-02 | — | [Hệ thống trả batch về draft/rejected theo lifecycle; chưa ghi ledger.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Không đủ quyền hoặc stale
**Phát sinh tại:** BF-02. **Điều kiện:** Người duyệt không hợp lệ hoặc batch đã đổi version .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Không cho duyệt trên dữ liệu cũ. | |
| EF-A-02 | — | [Kết thúc UC.] | |

#### EF-B — Kết quả quyết định chưa xác định
**Phát sinh tại:** BF-04. **Điều kiện:** Không rõ approval đã commit .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Verify same decision identity. | |
| EF-B-02 | — | [Kết thúc/hand-off recovery.] | |

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
- `BC-IC-06` — Decide approval.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Batch được duyệt sẵn sàng commit hoặc bị từ chối có lý do; operational inventory vẫn chưa active. | Chỉ kết quả phê duyệt hợp lệ mới cho phép bước thực thi tiếp theo; từ chối kết thúc hoặc trả hồ sơ theo lifecycle nguồn. |
| Không đủ điều kiện / Bị từ chối | Nếu bị từ chối, stale hoặc sai quyền/segregation, quyết định không làm phát sinh effect nghiệp vụ ngoài approval result đã được phép ghi. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** Batch được duyệt sẵn sàng commit hoặc bị từ chối có lý do; operational inventory vẫn chưa active.

## 8. Liên hệ giao diện

| Screen | Vai trò trong UC |
|---|---|
| `SCR-069` | Trình bày basis/evidence và hành động ra quyết định của “Rà soát và duyệt batch”; không tự thực thi effect sau duyệt. |
| `SCR-070` | Trình bày basis/evidence và hành động ra quyết định của “Rà soát và duyệt batch”; không tự thực thi effect sau duyệt. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-12-02-01 — Rà soát và duyệt batch — luồng chính
- **Given:** Có prepared batch hợp lệ
- **When:** Mở batch đã validation và xem tổng quantity/value, lỗi cảnh báo và sample/chi tiết.
- **Then:** Batch được duyệt sẵn sàng commit hoặc bị từ chối có lý do; operational inventory vẫn chưa active.

### AS-UC-12-02-02 — Rà soát và duyệt batch — Từ chối
- **Given:** Batch cần sửa hoặc evidence chưa đủ.
- **When:** Ghi lý do từ chối.
- **Then:** Hệ thống trả batch về draft/rejected theo lifecycle; chưa ghi ledger.

### AS-UC-12-02-03 — Rà soát và duyệt batch — Không đủ quyền hoặc stale
- **Given:** Người duyệt không hợp lệ hoặc batch đã đổi version.
- **When:** Hệ thống phát hiện điều kiện “Không đủ quyền hoặc stale” tại BF-02.
- **Then:** Không cho duyệt trên dữ liệu cũ. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-12-02-04 — Rà soát và duyệt batch — Kết quả quyết định chưa xác định
- **Given:** Không rõ approval đã commit.
- **When:** Hệ thống phát hiện điều kiện “Kết quả quyết định chưa xác định” tại BF-04.
- **Then:** Verify same decision identity. Giữ nguyên identity/evidence hiện có và bàn giao recovery/finality; không tạo effect trùng hoặc thử lại mù.

## 10. Truy vết

- **Journey:** `BJ-12` — Khởi tạo số dư tồn kho đầu kỳ.
- **Domain:** `DOM-IC`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-06`.

- **Nguồn quyết định:** [Nhóm G09 — Số dư đầu kỳ và Chuyển đổi chính thức](../../../01.knowledge/decisions/decision-register.md#39-g09-s%E1%BB%91-d%C6%B0-%C4%91%E1%BA%A7u-k%E1%BB%B3-v%C3%A0-chuy%E1%BB%83n-%C4%91%E1%BB%95i-ch%C3%ADnh-th%E1%BB%A9c)
- **Bài tri thức liên quan:** [Chuẩn bị dữ liệu số dư tồn kho đầu kỳ](../../../01.knowledge/know-how/KB-KGV-022-chuan-bi-du-lieu-so-du-ton-kho-dau-ky.md); [Xác nhận số dư đầu kỳ, Chuyển đổi chính thức và đối soát migration](../../../01.knowledge/know-how/KB-KGV-023-xac-nhan-so-du-dau-ky-chuyen-doi-chinh-thuc-va-doi-soat-migration.md); [Kho, cửa hàng và khóa định danh số dư tồn kho](../../../01.knowledge/know-how/KB-KGV-003-kho-cua-hang-va-khoa-dinh-danh-so-du-ton-kho.md); [Đơn vị tính và cách quy đổi số lượng tồn kho](../../../01.knowledge/know-how/KB-KGV-004-don-vi-tinh-va-cach-quy-doi-so-luong-ton-kho.md); [Đơn giá tồn kho chính thức và tổng giá trị ghi sổ](../../../01.knowledge/know-how/KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md)
