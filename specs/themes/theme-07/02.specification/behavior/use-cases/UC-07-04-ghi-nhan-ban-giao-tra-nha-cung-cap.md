---
id: UC-07-04
type: use-case
theme: theme-07
title: "Ghi nhận bàn giao trả nhà cung cấp"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-07
---

# UC-07-04 — Ghi nhận bàn giao trả nhà cung cấp

## 1. Mục tiêu và kết quả nghiệp vụ

Ghi nhận việc bàn giao hàng thực tế cho nhà cung cấp và giảm tồn/value đúng lượng được authorization hiện hành cho phép.

**Kết quả cần đạt:** Quantity/value movement giảm và pending scope được consume nguyên tử; Theme 7 không tự giảm công nợ NCC.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Có handover assertion và lượng pending hợp lệ

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Tồn vật lý/giá trị giảm hoặc toàn operation bị từ chối; Supplier return issue result.

### 2.3 Không bao gồm

Không tự giảm công nợ nhà cung cấp và không sửa giá trị chấp thuận thương mại. UC chỉ ghi việc bàn giao vật lý, giảm tồn theo rule Theme 7 và phát handoff giá trị cần thiết sang owner liên quan.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Thủ kho; bộ phận mua hàng cung cấp ý định trả.
- **Thẩm quyền:** Chỉ tác nhân hoặc system process có quyền thực thi đúng scope mới được commit; mọi guard về source/version, policy và lifecycle phải được server kiểm lại trước effect.
- **Sự kiện khởi phát:** Có handover assertion và lượng pending hợp lệ.
- **Điều kiện trước:** Current source/version + stable allocations còn hiệu lực; exact pending source slices và physical verification hợp lệ; quyền + warehouse scope đúng; có actor handover assertion. Commercial supplier price không phải điều kiện cần.

## 4. Đối tượng và dữ liệu nghiệp vụ

| Đối tượng / Dữ liệu | Ý nghĩa và yêu cầu | Nguồn |
|---|---|---|
| Phạm vi thực hiện | Tác nhân và phạm vi tenant/cửa hàng/kho mà yêu cầu được phép xử lý. | DOM-IO / BC liên quan |

## 5. Các luồng của Use Case

### 5.1 Luồng chính (Basic Flow)

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| BF-01 | Thủ kho | Xác nhận sản phẩm/lô/lượng thực tế đã bàn giao cho NCC. |  |
| BF-02 | Hệ thống | Recheck authorization source version, `RTV_PENDING`, quantity/LOT và official cost hiện hành. | EF-A — Source/pending stale |
| BF-03 | Hệ thống | Ghi quantity movement giảm và value movement theo official cost áp dụng tại thời điểm hoàn tất. |  |
| BF-04 | Hệ thống | Consume pending scope, cập nhật balance và outbox/handoff cho Theme kế toán/mua trong cùng transaction. | EF-B — Kết quả commit chưa xác định |
| BF-05 | Hệ thống | Trả kết quả bàn giao; chênh lệch giá NCC/giá kho được bàn giao cho owner tài chính, không sửa ở Theme 7. |  |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

Không có luồng thay thế riêng ngoài các nhánh kết quả đã thể hiện trong Luồng chính.

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Source hoặc pending stale
**Phát sinh tại:** BF-02. **Điều kiện:** Authorization/pending scope không còn current hoặc lượng không đủ .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Reject trước movement; yêu cầu refresh/source correction. | |
| EF-A-02 | — | [Kết thúc UC.] | |

#### EF-B — Kết quả commit chưa xác định
**Phát sinh tại:** BF-04. **Điều kiện:** Không rõ transaction trả NCC đã commit .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Giữ operation identity, verify/BJ17 trước mọi retry. | |
| EF-B-02 | — | [Kết thúc UC.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Giới hạn lượng | Lượng trả không vượt đồng thời lượng còn được source cho phép và lượng tenant thực có theo đúng sản phẩm/lô| Decision / DOM-IO / BC nguồn |
| BR-02 | Nguồn nhập | Giữ liên kết đến phiếu nhận hàng/source nhập gốc khi nguồn cung cấp; không tự tạo quan hệ thương mại mới| Decision / DOM-IO / BC nguồn |
| BR-03 | Mốc loại khỏi khả dụng | Khi supplier return đã được chấp thuận và lượng chuyển RTV_PENDING| Decision / DOM-IO / BC nguồn |
| BR-04 | Mốc giảm vật lý | Chỉ khi có bằng chứng bàn giao thực tế; tạo hồ sơ chờ trả không giảm physical| Decision / DOM-IO / BC nguồn |
| BR-05 | Sửa trước bàn giao | Không sửa trực tiếp payload đã khóa; source version mới tạo thay đổi có truy vết và chỉ giải phóng phần chưa bàn giao| Decision / DOM-IO / BC nguồn |
| BR-06 | Giá trị | Giảm theo official cost có hiệu lực; giá nhà cung cấp chấp thuận và chênh lệch chỉ là accounting handoff| Decision / DOM-IO / BC nguồn |

- `SBC-COM-01` — Bao yêu cầu và định danh.
- `BC-COMMON-EXTENSIONS` — Shared behavioral contract extensions.
- `SBC-COM-02` — Quyền, phạm vi và điều kiện cần.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `SBC-COM-04` — Finality và tính nguyên tử.
- `BC-IO-09` — Return goods to supplier — actual handover.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Quantity/value movement giảm và pending scope được consume nguyên tử; Theme 7 không tự giảm công nợ NCC. | Hành trình tiếp tục từ kết quả authoritative vừa ghi theo Business Journey sở hữu; không suy bước tiếp theo chỉ từ thứ tự UC. |
| Không đủ điều kiện / Bị từ chối | Nếu precondition, version, quyền hoặc invariant không còn hợp lệ, hệ thống từ chối trước effect; nếu finality chưa rõ thì giữ cùng operation identity để recovery. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** Quantity/value movement giảm và pending scope được consume nguyên tử; Theme 7 không tự giảm công nợ NCC.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-07 — Thực hiện trả hàng cho nhà cung cấp](../../../03.design/flows/UIF-07-BJ-07.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-039` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Ghi nhận bàn giao trả nhà cung cấp”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |
| `SCR-041` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Ghi nhận bàn giao trả nhà cung cấp”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-07-04-01 — Ghi nhận bàn giao trả nhà cung cấp — luồng chính
- **Given:** Có handover assertion và lượng pending hợp lệ
- **When:** Xác nhận sản phẩm/lô/lượng thực tế đã bàn giao cho NCC.
- **Then:** Quantity/value movement giảm và pending scope được consume nguyên tử; Theme 7 không tự giảm công nợ NCC.

### AS-UC-07-04-02 — Ghi nhận bàn giao trả nhà cung cấp — Source hoặc pending stale
- **Given:** Authorization/pending scope không còn current hoặc lượng không đủ.
- **When:** Hệ thống phát hiện điều kiện “Source hoặc pending stale” tại BF-02.
- **Then:** Reject trước movement; yêu cầu refresh/source correction. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-07-04-03 — Ghi nhận bàn giao trả nhà cung cấp — Kết quả commit chưa xác định
- **Given:** Không rõ transaction trả NCC đã commit.
- **When:** Hệ thống phát hiện điều kiện “Kết quả commit chưa xác định” tại BF-04.
- **Then:** Giữ operation identity, verify/BJ17 trước mọi retry. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

## 10. Truy vết

- **Journey:** `BJ-07` — Thực hiện trả hàng cho nhà cung cấp.
- **Domain:** `DOM-IO`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-09`.

- **Nguồn quyết định:** [Nhóm G06 — Trả hàng, hết hạn và loại bỏ](../../../01.knowledge/decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y)
- **Bài tri thức liên quan:** [Trả hàng cho nhà cung cấp](../../../01.knowledge/know-how/KB-KGV-013-tra-hang-cho-nha-cung-cap.md); [Chọn hàng để xuất và thời điểm hoàn tất xuất bán](../../../01.knowledge/know-how/KB-KGV-010-chon-hang-de-xuat-va-thoi-diem-hoan-tat-xuat-ban.md); [Đơn giá tồn kho chính thức và tổng giá trị ghi sổ](../../../01.knowledge/know-how/KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md)
