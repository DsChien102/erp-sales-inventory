---
id: UC-07-01
type: use-case
theme: theme-07
title: "Xác minh phạm vi trả"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-07
---

# UC-07-01 — Xác minh phạm vi trả

## 1. Mục tiêu và kết quả nghiệp vụ

Xác minh supplier-return intent đã được upstream phê duyệt có còn phù hợp với lượng hàng tenant thực có, đúng sản phẩm/lô và đúng giới hạn source trước khi đưa hàng vào chờ trả.

**Kết quả cần đạt:** Phạm vi trả hợp lệ được xác định cùng source/version; trường hợp không hợp lệ bị từ chối trước khi thay đổi `RTV_PENDING` hoặc tồn vật lý.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Có supplier-return intent được duyệt

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Hồ sơ hợp lệ hoặc bị từ chối; Validated return scope.

### 2.3 Không bao gồm

Không thực hiện các mục tiêu thuộc Use Case khác trong cùng Journey; không mở rộng quyền sở hữu sang dữ liệu của Theme/Domain khác.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** System process; Purchase/source là upstream authority.
- **Thẩm quyền:** Chỉ xử lý đúng phạm vi chức năng và dữ liệu được cấp quyền; không thay đổi fact do Domain/Theme khác sở hữu.
- **Sự kiện khởi phát:** Có supplier-return intent được duyệt.
- **Điều kiện trước:** Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện.

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
| BF-01 | Hệ thống | Nhận supplier-return intent đã được upstream phê duyệt cùng source/version và phạm vi sản phẩm/lô/lượng. | |
| BF-02 | Hệ thống | Đối chiếu source authorization với lượng tenant đang thực có, trạng thái vật lý và LOT identity hiện hành. | EF-A — Source stale hoặc lượng không còn đủ |
| BF-03 | Hệ thống | Tính lượng tối đa được phép trả theo đồng thời giới hạn source và lượng tenant thực có. | BR-01 — Giới hạn lượng |
| BF-04 | Hệ thống | Giữ liên kết receipt/source nhập gốc khi nguồn cung cấp và tạo validated return scope cho bước đồng bộ chờ trả. | BR-02 — Nguồn nhập |
| BF-05 | Hệ thống | Trả phạm vi hợp lệ cùng source/version; chưa giảm tồn vật lý và chưa thay đổi công nợ NCC. | BR-04 — Mốc giảm vật lý |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Chỉ một phần phạm vi còn đủ điều kiện
**Phát sinh tại:** BF-03. **Điều kiện:** source cho phép lượng lớn hơn lượng tenant hiện còn đủ điều kiện trả.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Chỉ xác nhận phần lượng đồng thời thỏa source authorization và tồn thực tế; phần vượt bị trả về như discrepancy, không tự mở rộng/đổi source. | BR-01 — Giới hạn lượng |
| AF-A-02 | — | [Trở lại BF-04]. | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Source stale hoặc lượng không còn đủ
**Phát sinh tại:** BF-02. **Điều kiện:** source version đã bị thay thế/hủy, hoặc sản phẩm/lô/lượng tenant hiện có không còn đáp ứng intent.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Từ chối validated scope trên dữ liệu cũ; trả current source/version hoặc discrepancy để upstream xử lý. | |
| EF-A-02 | — | [Kết thúc UC]. | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Giới hạn lượng | Lượng trả không vượt đồng thời lượng còn được source cho phép và lượng tenant thực có theo đúng sản phẩm/lô| Decision / DOM-IO / BC nguồn |
| BR-02 | Nguồn nhập | Giữ liên kết đến receipt/source nhập gốc khi nguồn cung cấp; không tự tạo quan hệ thương mại mới| Decision / DOM-IO / BC nguồn |
| BR-03 | Mốc loại khỏi khả dụng | Khi supplier return đã được chấp thuận và lượng chuyển RTV_PENDING| Decision / DOM-IO / BC nguồn |
| BR-04 | Mốc giảm vật lý | Chỉ khi có bằng chứng bàn giao thực tế; tạo hồ sơ chờ trả không giảm physical| Decision / DOM-IO / BC nguồn |
| BR-05 | Sửa trước bàn giao | Không sửa trực tiếp payload đã khóa; source version mới tạo thay đổi có truy vết và chỉ giải phóng phần chưa bàn giao| Decision / DOM-IO / BC nguồn |
| BR-06 | Giá trị | Giảm theo official cost có hiệu lực; giá nhà cung cấp chấp thuận và chênh lệch chỉ là accounting handoff| Decision / DOM-IO / BC nguồn |

- `SBC-COM-01` — Bao yêu cầu và định danh.
- `BC-COMMON-EXTENSIONS` — Shared behavioral contract extensions.
- `SBC-COM-02` — Quyền, phạm vi và điều kiện cần.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `SBC-COM-04` — Finality và tính nguyên tử.
- `BC-IO-17` — Synchronize supplier-return authorization.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Phạm vi trả hợp lệ được xác định theo đúng source/version, sản phẩm/lô và lượng tenant còn thực có; chưa giảm tồn vật lý và chưa thay đổi công nợ. | Chuyển phạm vi đã xác minh sang bước đồng bộ hàng chờ trả của `BJ-07`. |
| Không hợp lệ / Bị từ chối | Source đã stale, bị hủy hoặc lượng hàng thực tế không còn đáp ứng phạm vi được phép trả; không tạo `RTV_PENDING`, quantity movement hoặc value movement. | Trả discrepancy và source/version hiện hành để upstream xử lý hoặc phát hành phạm vi trả mới. |
| Nguồn đọc lỗi/stale | Không suy diễn kết quả từ dữ liệu cũ hoặc thiếu; không phát sinh mutation. | Tải lại nguồn hiện hành |

**Ảnh hưởng nghiệp vụ chính:** Chỉ system/source sync theo `BC-IO-17`; UI không có mutation CTA cho source intake/`RTV_PENDING`.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-07 — Thực hiện trả hàng cho nhà cung cấp](../../../03.design/flows/UIF-07-BJ-07.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-036` | Trình bày dữ liệu, thời điểm và trạng thái đọc cần để “Xác minh phạm vi trả”; không tạo mutation. |
| `SCR-037` | Trình bày dữ liệu, thời điểm và trạng thái đọc cần để “Xác minh phạm vi trả”; không tạo mutation. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-07-01-01 — Phạm vi trả hợp lệ
- **Given:** Có supplier-return intent đã duyệt, source version hiện hành và tenant còn đúng sản phẩm/lô/lượng được phép trả.
- **When:** Người xử lý mở yêu cầu trả và hệ thống đối chiếu authorization với lượng hàng hiện còn đủ điều kiện.
- **Then:** Hệ thống trả validated return scope có source/version rõ ràng; chưa giảm tồn vật lý và chưa thay đổi công nợ.

### AS-UC-07-01-02 — Chỉ một phần lượng còn đủ điều kiện
- **Given:** Source cho phép trả 10 nhưng tenant hiện chỉ còn 7 đơn vị đủ điều kiện.
- **When:** Hệ thống đối chiếu lượng được phép trả với lượng thực tế còn đủ điều kiện.
- **Then:** Chỉ 7 đơn vị nằm trong validated scope; 3 đơn vị còn lại được nêu là discrepancy và không tự phát sinh authorization mới.

### AS-UC-07-01-03 — Source đã stale
- **Given:** Supplier-return intent đã có version mới hoặc bị hủy trước khi xác minh.
- **When:** Hệ thống recheck source version tại thời điểm xác minh.
- **Then:** Yêu cầu trên version cũ bị từ chối; không tạo `RTV_PENDING`, quantity movement hoặc value movement.

## 10. Truy vết

- **Journey:** `BJ-07` — Thực hiện trả hàng cho nhà cung cấp.
- **Domain:** `DOM-IO`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-17`.

- **Nguồn quyết định:** [Nhóm G06 — Trả hàng, hết hạn và loại bỏ](../../../01.knowledge/decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y)
- **Bài tri thức liên quan:** [Trả hàng cho nhà cung cấp](../../../01.knowledge/know-how/KB-KGV-013-tra-hang-cho-nha-cung-cap.md); [Chọn hàng để xuất và thời điểm hoàn tất xuất bán](../../../01.knowledge/know-how/KB-KGV-010-chon-hang-de-xuat-va-thoi-diem-hoan-tat-xuat-ban.md); [Đơn giá tồn kho chính thức và tổng giá trị ghi sổ](../../../01.knowledge/know-how/KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md)
