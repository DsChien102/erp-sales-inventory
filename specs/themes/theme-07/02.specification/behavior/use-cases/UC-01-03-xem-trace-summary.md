---
id: UC-01-03
type: use-case
theme: theme-07
title: "Xem trace summary"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v3.12.0
---

# UC-01-03 — Xem trace summary

## 1. Mục tiêu và kết quả nghiệp vụ

Giải thích một số liệu tồn bằng chuỗi nguồn gần nhất, movement/operation chính và thời điểm dữ liệu mà không biến màn tra cứu thành báo cáo lịch sử đầy đủ.

**Kết quả cần đạt:** Trace summary ngắn, đọc được và truy ngược được về movement/operation/source; không tạo mutation.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Người dùng yêu cầu giải thích số liệu

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Hiển thị breakdown, movement và nguồn; Chuỗi truy nguyên đọc được.

### 2.3 Không bao gồm

Không sửa movement, chứng từ nguồn hoặc số dư để làm khớp kết quả. UC này chỉ truy nguyên số liệu tồn về các nguồn và movement đã ghi.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Nhân viên bán hàng, thủ kho hoặc chủ cửa hàng.
- **Thẩm quyền:** Chỉ được đọc đúng tenant/cửa hàng/kho/sản phẩm thuộc phạm vi được cấp; quyền xem số lượng, giá trị và dữ liệu tài chính được kiểm soát độc lập theo policy.
- **Sự kiện khởi phát:** Người dùng yêu cầu giải thích số liệu.
- **Điều kiện trước:** Ngữ cảnh tenant/cửa hàng/kho và quyền đọc hợp lệ; nguồn/read model cần cho truy vấn có thể xác định được `as_of`/version hoặc trả trạng thái stale rõ ràng.

## 4. Đối tượng và dữ liệu nghiệp vụ

| Đối tượng / Dữ liệu | Ý nghĩa và yêu cầu | Nguồn |
|---|---|---|
| Đối tượng nghiệp vụ | Đối tượng/phạm vi được nêu tại điều kiện bắt đầu và các rule bên dưới | DOM-IO |

## 5. Các luồng của Use Case

### 5.1 Luồng chính (Basic Flow)

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| BF-01 | Người dùng | Yêu cầu xem giải thích cho một số liệu tồn đang hiển thị. |  |
| BF-02 | Hệ thống | Giữ nguyên query context và lấy các movement/operation/source refs liên quan đến số liệu hiện hành. | EF-A — Nguồn không còn truy cập được |
| BF-03 | Hệ thống | Tạo trace summary theo thứ tự thời gian với nguồn gần nhất, tác động quantity/value và `as_of`. |  |
| BF-04 | Hệ thống | Giới hạn thông tin tài chính theo quyền; không thay thế thẻ kho/lịch sử đầy đủ của BJ15. |  |
| BF-05 | Người dùng | Đọc trace summary hoặc chuyển sang BJ15 nếu cần lịch sử/cut-off/export chi tiết. |  |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

Không có luồng thay thế riêng ngoài các nhánh kết quả đã thể hiện trong Luồng chính.

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Nguồn không còn truy cập được
**Phát sinh tại:** BF-02. **Điều kiện:** Một reference lịch sử không resolve được hoặc người dùng không có quyền với nguồn .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Hiển thị phần trace còn xác minh được và nêu rõ reference thiếu/không có quyền; không dựng dữ liệu thay thế. | |
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
| Thành công | Trace summary ngắn, đọc được và truy ngược được về movement/operation/source; không tạo mutation. | Kết thúc tra cứu hoặc chuyển sang UC/BJ khác theo nhu cầu nghiệp vụ; UC này không ghi thay đổi authoritative. |
| Không đủ điều kiện / Bị từ chối | Nếu thiếu quyền, dữ liệu không tồn tại hoặc nguồn stale, hệ thống trả đúng trạng thái đọc/cảnh báo; không tạo mutation. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |

**Ảnh hưởng nghiệp vụ chính:** Trace summary ngắn, đọc được và truy ngược được về movement/operation/source; không tạo mutation.

## 8. Liên hệ giao diện

| Screen | Vai trò trong UC |
|---|---|
| `SCR-005` | Trình bày dữ liệu, thời điểm và trạng thái đọc cần để “Xem trace summary”; không tạo mutation. |
| `SCR-003` | Trình bày dữ liệu, thời điểm và trạng thái đọc cần để “Xem trace summary”; không tạo mutation. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-01-03-01 — Xem trace summary — luồng chính
- **Given:** Người dùng yêu cầu giải thích số liệu
- **When:** Yêu cầu xem giải thích cho một số liệu tồn đang hiển thị.
- **Then:** Trace summary ngắn, đọc được và truy ngược được về movement/operation/source; không tạo mutation.

### AS-UC-01-03-02 — Xem trace summary — Nguồn không còn truy cập được
- **Given:** Một reference lịch sử không resolve được hoặc người dùng không có quyền với nguồn.
- **When:** Hệ thống phát hiện điều kiện “Nguồn không còn truy cập được” tại BF-02.
- **Then:** Hiển thị phần trace còn xác minh được và nêu rõ reference thiếu/không có quyền; không dựng dữ liệu thay thế. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

## 10. Truy vết

- **Journey:** `BJ-01` — Theo dõi tồn, khả dụng và chỉ báo vận hành.
- **Domain:** `DOM-IO`.
- **Behavioral Contract:** `SBC-COM-02`, `BC-COMMON-EXTENSIONS`, `SBC-COM-03`, `BC-IO-01`.

- **Nguồn quyết định:** [Nhóm G01 — Phạm vi, thẩm quyền và mô hình tồn](../../../01.knowledge/decisions/decision-register.md#31-g01-ph%E1%BA%A1m-vi-th%E1%BA%A9m-quy%E1%BB%81n-v%C3%A0-m%C3%B4-h%C3%ACnh-c%E1%BB%ADa-h%C3%A0ngkho); [Nhóm G04 — Khả dụng, giữ hàng và xuất bán](../../../01.knowledge/decisions/decision-register.md#34-g04-kh%E1%BA%A3-d%E1%BB%A5ng-gi%E1%BB%AF-h%C3%A0ng-l%E1%BA%A5y-h%C3%A0ng-v%C3%A0-xu%E1%BA%A5t)
- **Bài tri thức liên quan:** [Phạm vi quản lý tồn kho và giá vốn](../../../01.knowledge/know-how/KB-KGV-001-pham-vi-quan-ly-ton-kho-va-gia-von.md); [Kho, cửa hàng và khóa định danh số dư tồn kho](../../../01.knowledge/know-how/KB-KGV-003-kho-cua-hang-va-khoa-dinh-danh-so-du-ton-kho.md); [Tồn vật lý và tồn khả dụng](../../../01.knowledge/know-how/KB-KGV-005-ton-vat-ly-va-ton-kha-dung.md); [Tính chính thức của tồn kho và nguyên tắc chống xuất âm](../../../01.knowledge/know-how/KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am.md); [Thẻ kho, báo cáo lịch sử và đối soát nguồn](../../../01.knowledge/know-how/KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon.md)
