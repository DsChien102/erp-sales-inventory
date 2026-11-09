---
id: UC-01-02
type: use-case
theme: theme-07
title: "Xem tồn và khả dụng"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-01
---

# UC-01-02 — Xem tồn và khả dụng

## 1. Mục tiêu và kết quả nghiệp vụ

Đọc tồn vật lý, tồn đủ điều kiện bán, lượng đang giữ và khả dụng của sản phẩm trong đúng phạm vi đã xác định.

**Kết quả cần đạt:** Người dùng nhận được snapshot tồn có `as_of`/sequence rõ ràng; không có thay đổi ledger hay số dư authoritative.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Có query context hợp lệ

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Các lượng và thời điểm dữ liệu được hiển thị; Snapshot/read model có as-of.

### 2.3 Không bao gồm

Không giữ hàng, không xuất/nhập kho và không sửa số dư. UC này chỉ đọc tồn vật lý, lượng đã giữ, lượng đủ điều kiện và lượng khả dụng theo cùng một mốc dữ liệu.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Nhân viên bán hàng, thủ kho hoặc chủ cửa hàng.
- **Thẩm quyền:** Chỉ được đọc đúng tenant/cửa hàng/kho/sản phẩm thuộc phạm vi được cấp; quyền xem số lượng, giá trị và dữ liệu tài chính được kiểm soát độc lập theo policy.
- **Sự kiện khởi phát:** Có query context hợp lệ.
- **Điều kiện trước:** Ngữ cảnh tenant/cửa hàng/kho và quyền đọc hợp lệ; nguồn/read model cần cho truy vấn có thể xác định được `as_of`/version hoặc trả trạng thái stale rõ ràng.

## 4. Đối tượng và dữ liệu nghiệp vụ

| Đối tượng / Dữ liệu | Ý nghĩa và yêu cầu | Nguồn |
|---|---|---|
| Đối tượng nghiệp vụ | Đối tượng/phạm vi được nêu tại điều kiện bắt đầu và các rule bên dưới | DOM-IO |

## 5. Các luồng của Use Case

### 5.1 Luồng chính (Basic Flow)

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| BF-01 | Người dùng | Yêu cầu xem tồn của sản phẩm trong query context đã hợp lệ. |  |
| BF-02 | Hệ thống | Đọc snapshot/read model theo tenant + sản phẩm + kho và kiểm tra độ mới của projection. | AF-A — Projection stale |
| BF-03 | Hệ thống | Tính/hiển thị các lượng theo contract: vật lý, đủ điều kiện, đang giữ và khả dụng; chỉ hiển thị LOT khi sản phẩm theo LOT. | BR-01 — Công thức khả dụng<br>BR-04 — LOT/NONE |
| BF-04 | Hệ thống | Gắn `query_as_of`/sequence và giới hạn trường giá trị theo quyền tài chính. | EF-A — Không có quyền xem giá trị |
| BF-05 | Người dùng | Đọc snapshot và tiếp tục sang chi tiết/trace khi cần giải thích số liệu. |  |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Projection stale
**Phát sinh tại:** BF-02. **Điều kiện:** Read model chưa đạt độ mới yêu cầu hoặc nguồn báo stale .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Trả snapshot cùng nhãn stale và `as_of`; không suy diễn thành current balance. | |
| AF-A-02 | — | [Kết thúc UC hoặc người dùng làm mới sau.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Không có quyền xem giá trị
**Phát sinh tại:** BF-04. **Điều kiện:** Người dùng được xem quantity nhưng không có quyền tài chính .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Ẩn/không trả unit cost và total value; vẫn trả quantity trong phạm vi được phép. | |
| EF-A-02 | — | [Kết thúc UC.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Công thức khả dụng | Khả dụng = lượng vật lý đủ điều kiện bán − lượng đang giữ hợp lệ| Decision / DOM-IO / BC nguồn |
| BR-02 | Dữ liệu chính thức | Mutation phải dựa trên transactional balance; read model trễ chỉ phục vụ xem| Decision / DOM-IO / BC nguồn |
| BR-03 | Quyền tài chính | Quantity có thể được xem mà không đồng nghĩa được xem unit cost hoặc total value| Decision / DOM-IO / BC nguồn |
| BR-04 | LOT/NONE | Chỉ hiển thị lô khi sản phẩm theo LOT; sản phẩm NONE không phát sinh lô giả| Decision / DOM-IO / BC nguồn |
| BR-05 | Thời điểm | Mọi kết quả phải có as-of hoặc sequence để người dùng biết độ mới| Decision / DOM-IO / BC nguồn |

- `SBC-COM-02` — Quyền, phạm vi và điều kiện cần.
- `BC-COMMON-EXTENSIONS` — Shared behavioral contract extensions.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `BC-IO-01` — Query inventory availability.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Người dùng nhận được snapshot tồn có `as_of`/sequence rõ ràng; không có thay đổi ledger hay số dư authoritative. | Kết thúc tra cứu hoặc chuyển sang UC/BJ khác theo nhu cầu nghiệp vụ; UC này không ghi thay đổi authoritative. |
| Không đủ điều kiện / Bị từ chối | Nếu thiếu quyền, dữ liệu không tồn tại hoặc nguồn stale, hệ thống trả đúng trạng thái đọc/cảnh báo; không tạo mutation. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |

**Ảnh hưởng nghiệp vụ chính:** Người dùng nhận được snapshot tồn có `as_of`/sequence rõ ràng; không có thay đổi ledger hay số dư authoritative.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-01 — Theo dõi tồn, khả dụng và chỉ báo vận hành](../../../03.design/flows/UIF-01-BJ-01.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-003` | Trình bày dữ liệu, thời điểm và trạng thái đọc cần để “Xem tồn và khả dụng”; không tạo mutation. Sheet lô (thay SCR-004 cũ): Trình bày dữ liệu, thời điểm và trạng thái đọc cần để “Xem tồn và khả dụng”; không tạo mutation. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-01-02-01 — Xem tồn và khả dụng — luồng chính
- **Given:** Có query context hợp lệ
- **When:** Yêu cầu xem tồn của sản phẩm trong query context đã hợp lệ.
- **Then:** Người dùng nhận được snapshot tồn có `as_of`/sequence rõ ràng; không có thay đổi ledger hay số dư authoritative.

### AS-UC-01-02-02 — Xem tồn và khả dụng — Projection stale
- **Given:** Read model chưa đạt độ mới yêu cầu hoặc nguồn báo stale.
- **When:** Hệ thống phát hiện điều kiện “Projection stale” tại BF-02.
- **Then:** Trả snapshot cùng nhãn stale và `as_of`; không suy diễn thành current balance. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-01-02-03 — Xem tồn và khả dụng — Không có quyền xem giá trị
- **Given:** Người dùng được xem quantity nhưng không có quyền tài chính.
- **When:** Hệ thống phát hiện điều kiện “Không có quyền xem giá trị” tại BF-04.
- **Then:** Ẩn/không trả unit cost và total value; vẫn trả quantity trong phạm vi được phép. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

## 10. Truy vết

- **Journey:** `BJ-01` — Theo dõi tồn, khả dụng và chỉ báo vận hành.
- **Domain:** `DOM-IO`.
- **Behavioral Contract:** `SBC-COM-02`, `BC-COMMON-EXTENSIONS`, `SBC-COM-03`, `BC-IO-01`.

- **Nguồn quyết định:** [Nhóm G01 — Phạm vi, thẩm quyền và mô hình tồn](../../../01.knowledge/decisions/decision-register.md#31-g01-ph%E1%BA%A1m-vi-th%E1%BA%A9m-quy%E1%BB%81n-v%C3%A0-m%C3%B4-h%C3%ACnh-c%E1%BB%ADa-h%C3%A0ngkho); [Nhóm G04 — Khả dụng, giữ hàng và xuất bán](../../../01.knowledge/decisions/decision-register.md#34-g04-kh%E1%BA%A3-d%E1%BB%A5ng-gi%E1%BB%AF-h%C3%A0ng-l%E1%BA%A5y-h%C3%A0ng-v%C3%A0-xu%E1%BA%A5t)
- **Bài tri thức liên quan:** [Phạm vi quản lý tồn kho và giá vốn](../../../01.knowledge/know-how/KB-KGV-001-pham-vi-quan-ly-ton-kho-va-gia-von.md); [Kho, cửa hàng và khóa định danh số dư tồn kho](../../../01.knowledge/know-how/KB-KGV-003-kho-cua-hang-va-khoa-dinh-danh-so-du-ton-kho.md); [Tồn vật lý và tồn khả dụng](../../../01.knowledge/know-how/KB-KGV-005-ton-vat-ly-va-ton-kha-dung.md); [Tính chính thức của tồn kho và nguyên tắc chống xuất âm](../../../01.knowledge/know-how/KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am.md); [Thẻ kho, báo cáo lịch sử và đối soát nguồn](../../../01.knowledge/know-how/KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon.md)
