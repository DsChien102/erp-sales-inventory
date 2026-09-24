---
id: UC-01-01
type: use-case
theme: theme-07
title: "Xác định ngữ cảnh và sản phẩm"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v3.12.0
---

# UC-01-01 — Xác định ngữ cảnh và sản phẩm

## 1. Mục tiêu và kết quả nghiệp vụ

Xác định đúng tenant, cửa hàng/kho và sản phẩm mà người dùng được phép tra cứu trước khi đọc tồn.

**Kết quả cần đạt:** Query context hợp lệ được xác lập, hoặc truy cập bị từ chối trước khi lộ dữ liệu ngoài phạm vi.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Người dùng mở chức năng kiểm tra tồn

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Sản phẩm và warehouse scope được xác định hoặc truy cập bị từ chối; Query context hợp lệ.

### 2.3 Không bao gồm

Không đọc thay cho các UC tra cứu chi tiết và không ghi tồn kho. UC này chỉ xác lập tenant, kho/cửa hàng, sản phẩm, quyền đọc và mốc dữ liệu dùng chung cho các bước tra cứu tiếp theo.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Nhân viên bán hàng, thủ kho hoặc chủ cửa hàng.
- **Thẩm quyền:** Chỉ được đọc đúng tenant/cửa hàng/kho/sản phẩm thuộc phạm vi được cấp; quyền xem số lượng, giá trị và dữ liệu tài chính được kiểm soát độc lập theo policy.
- **Sự kiện khởi phát:** Người dùng mở chức năng kiểm tra tồn.
- **Điều kiện trước:** Ngữ cảnh tenant/cửa hàng/kho và quyền đọc hợp lệ; nguồn/read model cần cho truy vấn có thể xác định được `as_of`/version hoặc trả trạng thái stale rõ ràng.

## 4. Đối tượng và dữ liệu nghiệp vụ

| Đối tượng / Dữ liệu | Ý nghĩa và yêu cầu | Nguồn |
|---|---|---|
| Đối tượng nghiệp vụ | Đối tượng/phạm vi được nêu tại điều kiện bắt đầu và các rule bên dưới | DOM-IO |

## 5. Các luồng của Use Case

### 5.1 Luồng chính (Basic Flow)

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| BF-01 | Người dùng | Mở chức năng tồn kho và chọn/đi tới sản phẩm cần xem. |  |
| BF-02 | Hệ thống | Xác định tenant, cửa hàng/kho, sản phẩm và quyền đọc từ ngữ cảnh đăng nhập và lựa chọn hiện hành. | EF-A — Không có quyền hoặc sai phạm vi |
| BF-03 | Hệ thống | Kiểm tra capability tồn kho, tracking mode và nguồn read model phù hợp với sản phẩm. | AF-A — Policy/chỉ báo chưa cấu hình |
| BF-04 | Hệ thống | Tạo query context kèm `query_as_of`/sequence để các UC đọc tiếp theo dùng cùng phạm vi. |  |
| BF-05 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Policy/chỉ báo chưa cấu hình
**Phát sinh tại:** BF-03. **Điều kiện:** Thiếu threshold/target hoặc policy chỉ báo không làm mất quyền xem tồn cơ bản .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Đánh dấu `NOT_CONFIGURED` cho phần chỉ báo tương ứng; không tự sinh cấu hình mặc định. | |
| AF-A-02 | — | [Kết thúc UC với query context vẫn hợp lệ nếu tồn cơ bản đọc được.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Không có quyền hoặc sai phạm vi
**Phát sinh tại:** BF-02. **Điều kiện:** Người dùng không có quyền với tenant/cửa hàng/kho/sản phẩm được yêu cầu .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Từ chối truy cập trước khi trả quantity/value/source detail; không tạo mutation. | |
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
| Thành công | Query context hợp lệ được xác lập, hoặc truy cập bị từ chối trước khi lộ dữ liệu ngoài phạm vi. | Kết thúc tra cứu hoặc chuyển sang UC/BJ khác theo nhu cầu nghiệp vụ; UC này không ghi thay đổi authoritative. |
| Không đủ điều kiện / Bị từ chối | Nếu thiếu quyền, dữ liệu không tồn tại hoặc nguồn stale, hệ thống trả đúng trạng thái đọc/cảnh báo; không tạo mutation. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |

**Ảnh hưởng nghiệp vụ chính:** Query context hợp lệ được xác lập, hoặc truy cập bị từ chối trước khi lộ dữ liệu ngoài phạm vi.

## 8. Liên hệ giao diện

| Screen | Vai trò trong UC |
|---|---|
| `SCR-001` | Trình bày dữ liệu, thời điểm và trạng thái đọc cần để “Xác định ngữ cảnh và sản phẩm”; không tạo mutation. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-01-01-01 — Xác định ngữ cảnh và sản phẩm — luồng chính
- **Given:** Người dùng mở chức năng kiểm tra tồn
- **When:** Mở chức năng tồn kho và chọn/đi tới sản phẩm cần xem.
- **Then:** Query context hợp lệ được xác lập, hoặc truy cập bị từ chối trước khi lộ dữ liệu ngoài phạm vi.

### AS-UC-01-01-02 — Xác định ngữ cảnh và sản phẩm — Policy/chỉ báo chưa cấu hình
- **Given:** Thiếu threshold/target hoặc policy chỉ báo không làm mất quyền xem tồn cơ bản.
- **When:** Hệ thống phát hiện điều kiện “Policy/chỉ báo chưa cấu hình” tại BF-03.
- **Then:** Đánh dấu `NOT_CONFIGURED` cho phần chỉ báo tương ứng; không tự sinh cấu hình mặc định. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-01-01-03 — Xác định ngữ cảnh và sản phẩm — Không có quyền hoặc sai phạm vi
- **Given:** Người dùng không có quyền với tenant/cửa hàng/kho/sản phẩm được yêu cầu.
- **When:** Hệ thống phát hiện điều kiện “Không có quyền hoặc sai phạm vi” tại BF-02.
- **Then:** Từ chối truy cập trước khi trả quantity/value/source detail; không tạo mutation. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

## 10. Truy vết

- **Journey:** `BJ-01` — Theo dõi tồn, khả dụng và chỉ báo vận hành.
- **Domain:** `DOM-IO`.
- **Behavioral Contract:** `SBC-COM-02`, `BC-COMMON-EXTENSIONS`, `SBC-COM-03`, `BC-IO-01`.

- **Nguồn quyết định:** [Nhóm G01 — Phạm vi, thẩm quyền và mô hình tồn](../../../01.knowledge/decisions/decision-register.md#31-g01-ph%E1%BA%A1m-vi-th%E1%BA%A9m-quy%E1%BB%81n-v%C3%A0-m%C3%B4-h%C3%ACnh-c%E1%BB%ADa-h%C3%A0ngkho); [Nhóm G04 — Khả dụng, giữ hàng và xuất bán](../../../01.knowledge/decisions/decision-register.md#34-g04-kh%E1%BA%A3-d%E1%BB%A5ng-gi%E1%BB%AF-h%C3%A0ng-l%E1%BA%A5y-h%C3%A0ng-v%C3%A0-xu%E1%BA%A5t)
- **Bài tri thức liên quan:** [Phạm vi quản lý tồn kho và giá vốn](../../../01.knowledge/know-how/KB-KGV-001-pham-vi-quan-ly-ton-kho-va-gia-von.md); [Kho, cửa hàng và khóa định danh số dư tồn kho](../../../01.knowledge/know-how/KB-KGV-003-kho-cua-hang-va-khoa-dinh-danh-so-du-ton-kho.md); [Tồn vật lý và tồn khả dụng](../../../01.knowledge/know-how/KB-KGV-005-ton-vat-ly-va-ton-kha-dung.md); [Tính chính thức của tồn kho và nguyên tắc chống xuất âm](../../../01.knowledge/know-how/KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am.md); [Thẻ kho, báo cáo lịch sử và đối soát nguồn](../../../01.knowledge/know-how/KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon.md)
