---
id: UC-15-03
type: use-case
theme: theme-07
title: "Xem thẻ kho và lịch sử"
owner: BA
status: FROZEN
frozen_at: v5.27.0
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-15
---

# UC-15-03 — Xem thẻ kho và lịch sử

## 1. Mục tiêu và kết quả nghiệp vụ

Xem thẻ kho/lịch sử movement để giải thích biến động quantity/value theo nguồn và thứ tự thời gian.

**Kết quả cần đạt:** Chuỗi movement truy vết được theo cut-off/date basis, kèm source/effect refs và running balance dẫn xuất khi có.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Người dùng cần giải thích biến động

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Movement và nguồn liên kết được hiển thị; Traceable stock card.

### 2.3 Không bao gồm

Không sửa movement lịch sử hoặc tự đối soát chênh lệch. UC chỉ trình bày chuỗi nhập/xuất/điều chỉnh và số dư dẫn xuất để người dùng truy nguyên.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Chủ cửa hàng, kế toán hoặc thủ kho.
- **Thẩm quyền:** Chỉ được đọc đúng tenant/cửa hàng/kho/sản phẩm thuộc phạm vi được cấp; quyền xem số lượng, giá trị và dữ liệu tài chính được kiểm soát độc lập theo policy.
- **Sự kiện khởi phát:** Người dùng cần giải thích biến động.
- **Điều kiện trước:** Ngữ cảnh tenant/cửa hàng/kho và quyền đọc hợp lệ; nguồn/read model cần cho truy vấn có thể xác định được `as_of`/version hoặc trả trạng thái stale rõ ràng.

## 4. Đối tượng và dữ liệu nghiệp vụ

| Đối tượng / Dữ liệu | Ý nghĩa và yêu cầu | Nguồn |
|---|---|---|
| Đối tượng nghiệp vụ | Đối tượng/phạm vi được nêu tại điều kiện bắt đầu và các rule bên dưới | DOM-IO |

## 5. Các luồng của Use Case

### 5.1 Luồng chính (Basic Flow)

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| BF-01 | Người dùng | Mở thẻ kho/lịch sử cho sản phẩm/phạm vi đã chọn. |  |
| BF-02 | Hệ thống | Đọc movement ledger bất biến theo date basis/cut-off và quyền dữ liệu. |  |
| BF-03 | Hệ thống | Sắp xếp theo sequence authoritative và liên kết từng movement tới operation/source/correction chain. | AF-A — Có correction/reversal |
| BF-04 | Hệ thống | Tính running balance/read model dẫn xuất nếu cần và gắn as-of; không sửa movement lịch sử. |  |
| BF-05 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Có correction hoặc reversal
**Phát sinh tại:** BF-03. **Điều kiện:** Movement có chain sửa sai liên quan .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Hiển thị liên kết original→correction/reversal và effect ròng; không ẩn transaction gốc. | |
| AF-A-02 | — | [Tiếp tục BF-04.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Source reference không resolve
**Phát sinh tại:** BF-03. **Điều kiện:** Một nguồn lịch sử không còn truy cập/không đủ quyền .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Giữ movement authoritative và hiển thị reference bị hạn chế/thiếu; không dựng source giả. | |
| EF-A-02 | — | [Kết thúc UC.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Ledger authority | Thẻ kho và lịch sử dựa trên Nhật ký biến động bất biến; không sửa số dư từ báo cáo| Decision / DOM-IO / BC nguồn |
| BR-02 | Cut-off/as-of | Báo cáo phải thể hiện cut-off, thời điểm tạo và độ mới của projection| Decision / DOM-IO / BC nguồn |
| BR-03 | Hai loại ngày | Cho phép đọc theo ngày ghi nhận hoặc ngày nghiệp vụ nhưng phải gắn nhãn rõ, không trộn ngầm| Decision / DOM-IO / BC nguồn |
| BR-04 | Quantity/value | Quyền xem quantity độc lập với quyền xem official cost, total value và valuation adjustment| Decision / DOM-IO / BC nguồn |
| BR-05 | LOT/NONE | Breakdown theo lô chỉ áp dụng cho sản phẩm LOT; không tạo lô giả cho NONE| Decision / DOM-IO / BC nguồn |
| BR-06 | Giá trị chi tiết | Giá trị có thẩm quyền ở tenant + sản phẩm; phân bổ theo kho/state/lot nếu có phải gắn nhãn dẫn xuất| Decision / DOM-IO / BC nguồn |

- `SBC-COM-02` — Quyền, phạm vi và điều kiện cần.
- `BC-COMMON-EXTENSIONS` — Shared behavioral contract extensions.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `BC-IO-01` — Query inventory availability.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Chuỗi movement truy vết được theo cut-off/date basis, kèm source/effect refs và running balance dẫn xuất khi có. | Kết thúc tra cứu hoặc chuyển sang UC/BJ khác theo nhu cầu nghiệp vụ; UC này không ghi thay đổi authoritative. |
| Không đủ điều kiện / Bị từ chối | Nếu thiếu quyền, dữ liệu không tồn tại hoặc nguồn stale, hệ thống trả đúng trạng thái đọc/cảnh báo; không tạo mutation. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |

**Ảnh hưởng nghiệp vụ chính:** Chuỗi movement truy vết được theo cut-off/date basis, kèm source/effect refs và running balance dẫn xuất khi có.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-15 — Tra cứu báo cáo tồn và thẻ kho](../../../03.design/flows/UIF-15-BJ-15.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-055` | Trình bày dữ liệu, thời điểm và trạng thái đọc cần để “Xem thẻ kho và lịch sử”; không tạo mutation. |
| `SCR-056` | Trình bày dữ liệu, thời điểm và trạng thái đọc cần để “Xem thẻ kho và lịch sử”; không tạo mutation. |
| `SCR-056` | Khối "Nguồn" (dòng thời gian nguồn nghiệp vụ) của chi tiết biến động; trình bày dữ liệu, thời điểm và trạng thái đọc cần để “Xem thẻ kho và lịch sử”; không tạo mutation. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-15-03-01 — Xem thẻ kho và lịch sử — luồng chính
- **Given:** Người dùng cần giải thích biến động
- **When:** Mở thẻ kho/lịch sử cho sản phẩm/phạm vi đã chọn.
- **Then:** Chuỗi movement truy vết được theo cut-off/date basis, kèm source/effect refs và running balance dẫn xuất khi có.

### AS-UC-15-03-02 — Xem thẻ kho và lịch sử — Có correction hoặc reversal
- **Given:** Movement có chain sửa sai liên quan.
- **When:** Hệ thống phát hiện điều kiện “Có correction hoặc reversal” tại BF-03.
- **Then:** Hiển thị liên kết original→correction/reversal và effect ròng; không ẩn transaction gốc. Luồng chính tiếp tục tại BF-04: Tính running balance/read model dẫn xuất nếu cần và gắn as-of; không sửa movement lịch sử.

### AS-UC-15-03-03 — Xem thẻ kho và lịch sử — Source reference không resolve
- **Given:** Một nguồn lịch sử không còn truy cập/không đủ quyền.
- **When:** Hệ thống phát hiện điều kiện “Source reference không resolve” tại BF-03.
- **Then:** Giữ movement authoritative và hiển thị reference bị hạn chế/thiếu; không dựng source giả. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

## 10. Truy vết

- **Journey:** `BJ-15` — Tra cứu báo cáo tồn và thẻ kho.
- **Domain:** `DOM-IO`.
- **Behavioral Contract:** `SBC-COM-02`, `BC-COMMON-EXTENSIONS`, `SBC-COM-03`, `BC-IO-01`.

- **Nguồn quyết định:** [Nhóm G12 — Ledger, báo cáo và đối soát](../../../01.knowledge/decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i)
- **Bài tri thức liên quan:** [Thẻ kho, báo cáo lịch sử và đối soát nguồn](../../../01.knowledge/know-how/KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon.md); [Nhật ký biến động, số dư dẫn xuất và phục hồi sau sự cố](../../../01.knowledge/know-how/KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md); [Tính chính thức của tồn kho và nguyên tắc chống xuất âm](../../../01.knowledge/know-how/KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am.md); [Quyền chức năng, phạm vi kho và bảo vệ dữ liệu tài chính](../../../01.knowledge/know-how/KB-KGV-030-quyen-chuc-nang-pham-vi-kho-va-bao-ve-du-lieu-tai-chinh.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md)
