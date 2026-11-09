---
id: UC-12-01
type: use-case
theme: theme-07
title: "Nạp và kiểm tra batch đầu kỳ"
owner: BA
status: FROZEN
frozen_at: v5.27.0
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-12
---

# UC-12-01 — Nạp và kiểm tra batch đầu kỳ

## 1. Mục tiêu và kết quả nghiệp vụ

Nạp batch số dư đầu kỳ và kiểm tra dữ liệu master, quantity/value/UOM/LOT trước khi cho phép duyệt.

**Kết quả cần đạt:** Batch draft có lỗi được chỉ rõ hoặc đạt validation để chuyển rà soát; chưa kích hoạt tồn.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Có file nguồn, cut-off và control totals

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Batch hợp lệ hoặc có danh sách lỗi đầy đủ; Prepared batch có version/hash, chưa ghi ledger.

### 2.3 Không bao gồm

Không tạo tồn đầu kỳ ngay khi upload và không tự sửa dữ liệu nguồn. UC chỉ chuẩn hóa, kiểm tra và tạo batch nháp với lỗi/duplicate được chỉ rõ.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Quản trị triển khai, kế toán kho và người duyệt.
- **Thẩm quyền:** Được lập/cập nhật hồ sơ nháp trong phạm vi được cấp; chưa có quyền tạo tác động cuối nếu Journey còn bước phê duyệt hoặc thực thi riêng.
- **Sự kiện khởi phát:** Có file nguồn, cut-off và control totals.
- **Điều kiện trước:** Nguồn/version cần dùng còn hiện hành; tác nhân có quyền lập hồ sơ trong đúng tenant/cửa hàng/kho; các master/policy bắt buộc cho việc chuẩn bị đã resolve được.

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
| BF-01 | Quản trị triển khai/Kế toán kho | Tạo hoặc tải batch số dư đầu kỳ cho tenant chưa kích hoạt inventory. |  |
| BF-02 | Hệ thống | Parse từng dòng và resolve Product/UOM/LOT/warehouse/master references. | EF-A — Dòng không resolve/không hợp lệ |
| BF-03 | Hệ thống | Kiểm tra duplicate key, precision, quantity/value và các invariant opening balance. | AF-A — Có lỗi dữ liệu |
| BF-04 | Hệ thống | Lưu batch draft + validation result/version; không ghi operational ledger. | EF-B — Kết quả nạp chưa xác định |
| BF-05 | Người lập | Sửa lỗi hoặc chuyển batch đạt validation sang UC-12-02. |  |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Có lỗi dữ liệu
**Phát sinh tại:** BF-03. **Điều kiện:** Một hoặc nhiều dòng vi phạm schema/invariant .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Gắn lỗi theo dòng/field và giữ các dòng hợp lệ trong draft; không tự sửa số liệu. | |
| AF-A-02 | — | [Trở lại BF-01 sau khi người dùng sửa.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Master/reference không hợp lệ
**Phát sinh tại:** BF-02. **Điều kiện:** Product/UOM/LOT/warehouse không tồn tại hoặc không thuộc tenant .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Không tạo master mới trong import; trả lỗi để xử lý ở owner master data. | |
| EF-A-02 | — | [Kết thúc/sửa batch.] | |

#### EF-B — Kết quả nạp chưa xác định
**Phát sinh tại:** BF-04. **Điều kiện:** Không rõ draft/version đã lưu .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Verify batch identity/version trước khi nạp lại. | |
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
- `BC-IC-09` — Prepare opening balance batch.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Batch draft có lỗi được chỉ rõ hoặc đạt validation để chuyển rà soát; chưa kích hoạt tồn. | Hồ sơ chỉ được bàn giao sang bước duyệt/thực thi khi các điều kiện của UC đã đạt; chưa ghi ledger trước commit point. |
| Không đủ điều kiện / Bị từ chối | Nếu dữ liệu, nguồn hoặc version chưa đủ điều kiện, hồ sơ không được đưa qua commit point; dữ liệu hợp lệ đã nhập được giữ theo contract để sửa/refresh khi an toàn. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** Batch draft có lỗi được chỉ rõ hoặc đạt validation để chuyển rà soát; chưa kích hoạt tồn.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-12 — Khởi tạo số dư tồn kho đầu kỳ](../../../03.design/flows/UIF-12-BJ-12.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-066` | Thu thập và rà soát dữ liệu cần để “Nạp và kiểm tra batch đầu kỳ”; việc ghi effect chỉ xảy ra tại commit point do UC/BC quy định. |
| `SCR-067` | Thu thập và rà soát dữ liệu cần để “Nạp và kiểm tra batch đầu kỳ”; việc ghi effect chỉ xảy ra tại commit point do UC/BC quy định. |
| `SCR-068` | Thu thập và rà soát dữ liệu cần để “Nạp và kiểm tra batch đầu kỳ”; việc ghi effect chỉ xảy ra tại commit point do UC/BC quy định. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-12-01-01 — Nạp và kiểm tra batch đầu kỳ — luồng chính
- **Given:** Có file nguồn, cut-off và control totals
- **When:** Tạo hoặc tải batch số dư đầu kỳ cho tenant chưa kích hoạt inventory.
- **Then:** Batch draft có lỗi được chỉ rõ hoặc đạt validation để chuyển rà soát; chưa kích hoạt tồn.

### AS-UC-12-01-02 — Nạp và kiểm tra batch đầu kỳ — Có lỗi dữ liệu
- **Given:** Một hoặc nhiều dòng vi phạm schema/invariant.
- **When:** Hệ thống phát hiện điều kiện “Có lỗi dữ liệu” tại BF-03.
- **Then:** Gắn lỗi theo dòng/field và giữ các dòng hợp lệ trong draft; không tự sửa số liệu. Luồng chính tiếp tục tại BF-01: Tạo hoặc tải batch số dư đầu kỳ cho tenant chưa kích hoạt inventory.

### AS-UC-12-01-03 — Nạp và kiểm tra batch đầu kỳ — Master/reference không hợp lệ
- **Given:** Product/UOM/LOT/warehouse không tồn tại hoặc không thuộc tenant.
- **When:** Hệ thống phát hiện điều kiện “Master/reference không hợp lệ” tại BF-02.
- **Then:** Không tạo master mới trong import; trả lỗi để xử lý ở owner master data. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-12-01-04 — Nạp và kiểm tra batch đầu kỳ — Kết quả nạp chưa xác định
- **Given:** Không rõ draft/version đã lưu.
- **When:** Hệ thống phát hiện điều kiện “Kết quả nạp chưa xác định” tại BF-04.
- **Then:** Verify batch identity/version trước khi nạp lại. Giữ nguyên identity/evidence hiện có và bàn giao recovery/finality; không tạo effect trùng hoặc thử lại mù.

## 10. Truy vết

- **Journey:** `BJ-12` — Khởi tạo số dư tồn kho đầu kỳ.
- **Domain:** `DOM-IC`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-09`.

- **Nguồn quyết định:** [Nhóm G09 — Số dư đầu kỳ và Chuyển đổi chính thức](../../../01.knowledge/decisions/decision-register.md#39-g09-s%E1%BB%91-d%C6%B0-%C4%91%E1%BA%A7u-k%E1%BB%B3-v%C3%A0-chuy%E1%BB%83n-%C4%91%E1%BB%95i-ch%C3%ADnh-th%E1%BB%A9c)
- **Bài tri thức liên quan:** [Chuẩn bị dữ liệu số dư tồn kho đầu kỳ](../../../01.knowledge/know-how/KB-KGV-022-chuan-bi-du-lieu-so-du-ton-kho-dau-ky.md); [Xác nhận số dư đầu kỳ, Chuyển đổi chính thức và đối soát migration](../../../01.knowledge/know-how/KB-KGV-023-xac-nhan-so-du-dau-ky-chuyen-doi-chinh-thuc-va-doi-soat-migration.md); [Kho, cửa hàng và khóa định danh số dư tồn kho](../../../01.knowledge/know-how/KB-KGV-003-kho-cua-hang-va-khoa-dinh-danh-so-du-ton-kho.md); [Đơn vị tính và cách quy đổi số lượng tồn kho](../../../01.knowledge/know-how/KB-KGV-004-don-vi-tinh-va-cach-quy-doi-so-luong-ton-kho.md); [Đơn giá tồn kho chính thức và tổng giá trị ghi sổ](../../../01.knowledge/know-how/KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md)
