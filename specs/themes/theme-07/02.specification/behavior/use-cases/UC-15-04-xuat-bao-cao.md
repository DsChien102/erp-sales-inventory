---
id: UC-15-04
type: use-case
theme: theme-07
title: "Xuất báo cáo"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-15
---

# UC-15-04 — Xuất báo cáo

## 1. Mục tiêu và kết quả nghiệp vụ

Xuất đúng báo cáo đã xem theo cùng scope/cut-off/as-of và quyền dữ liệu, không tạo snapshot nghiệp vụ mới.

**Kết quả cần đạt:** File export phản ánh đúng report context và metadata thời điểm; thất bại export không ảnh hưởng ledger/báo cáo nguồn.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Có kết quả và quyền export

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

File được tạo đúng scope/quyền; Report export có cut-off/as-of.

### 2.3 Không bao gồm

Không tạo một nguồn dữ liệu mới khác với báo cáo đang xem. UC chỉ xuất đúng dataset, bộ lọc, as-of và quyền của báo cáo đã xác định.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Chủ cửa hàng, kế toán hoặc thủ kho.
- **Thẩm quyền:** Chỉ được đọc đúng tenant/cửa hàng/kho/sản phẩm thuộc phạm vi được cấp; quyền xem số lượng, giá trị và dữ liệu tài chính được kiểm soát độc lập theo policy.
- **Sự kiện khởi phát:** Có kết quả và quyền export.
- **Điều kiện trước:** Ngữ cảnh tenant/cửa hàng/kho và quyền đọc hợp lệ; nguồn/read model cần cho truy vấn có thể xác định được `as_of`/version hoặc trả trạng thái stale rõ ràng.

## 4. Đối tượng và dữ liệu nghiệp vụ

| Đối tượng / Dữ liệu | Ý nghĩa và yêu cầu | Nguồn |
|---|---|---|
| Đối tượng nghiệp vụ | Đối tượng/phạm vi được nêu tại điều kiện bắt đầu và các rule bên dưới | DOM-IO |

## 5. Các luồng của Use Case

### 5.1 Luồng chính (Basic Flow)

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| BF-01 | Người dùng | Yêu cầu xuất báo cáo từ report context hiện hành. |  |
| BF-02 | Hệ thống | Recheck quyền export và đóng băng scope/cut-off/as-of của yêu cầu. | EF-A — Quyền hoặc context hết hiệu lực |
| BF-03 | Hệ thống | Sinh file từ cùng dataset/definition với màn hình và gắn metadata cut-off/as-of/generated-at. | AF-A — Dataset lớn cần xử lý bất đồng bộ |
| BF-04 | Hệ thống | Trả file hoặc trạng thái export; không thay đổi inventory ledger. |  |
| BF-05 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Export xử lý bất đồng bộ
**Phát sinh tại:** BF-03. **Điều kiện:** Khối lượng dữ liệu vượt ngưỡng xử lý đồng bộ .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Tạo export job có cùng context snapshot và trả trạng thái tải về khi hoàn tất; job không thay đổi số liệu nguồn. | |
| AF-A-02 | — | [Kết thúc UC khi file sẵn sàng.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Quyền hoặc context hết hiệu lực
**Phát sinh tại:** BF-02. **Điều kiện:** Quyền thay đổi hoặc report context không còn hợp lệ .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Từ chối export; yêu cầu tạo context mới, không tự mở rộng scope. | |
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
| Thành công | File export phản ánh đúng report context và metadata thời điểm; thất bại export không ảnh hưởng ledger/báo cáo nguồn. | Kết thúc tra cứu hoặc chuyển sang UC/BJ khác theo nhu cầu nghiệp vụ; UC này không ghi thay đổi authoritative. |
| Không đủ điều kiện / Bị từ chối | Nếu thiếu quyền, dữ liệu không tồn tại hoặc nguồn stale, hệ thống trả đúng trạng thái đọc/cảnh báo; không tạo mutation. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |

**Ảnh hưởng nghiệp vụ chính:** File export phản ánh đúng report context và metadata thời điểm; thất bại export không ảnh hưởng ledger/báo cáo nguồn.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-15 — Tra cứu báo cáo tồn và thẻ kho](../../../03.design/flows/UIF-15-BJ-15.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-055` | Sheet "Xuất báo cáo" (phạm vi, mốc dữ liệu, quyền); trình bày dữ liệu, thời điểm và trạng thái đọc cần để “Xuất báo cáo”; không tạo mutation. |
| `SCR-059` | Trình bày dữ liệu, thời điểm và trạng thái đọc cần để “Xuất báo cáo”; không tạo mutation. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-15-04-01 — Xuất báo cáo — luồng chính
- **Given:** Có kết quả và quyền export
- **When:** Yêu cầu xuất báo cáo từ report context hiện hành.
- **Then:** File export phản ánh đúng report context và metadata thời điểm; thất bại export không ảnh hưởng ledger/báo cáo nguồn.

### AS-UC-15-04-02 — Xuất báo cáo — Export xử lý bất đồng bộ
- **Given:** Khối lượng dữ liệu vượt ngưỡng xử lý đồng bộ.
- **When:** Hệ thống phát hiện điều kiện “Export xử lý bất đồng bộ” tại BF-03.
- **Then:** Tạo export job có cùng context snapshot và trả trạng thái tải về khi hoàn tất; job không thay đổi số liệu nguồn. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-15-04-03 — Xuất báo cáo — Quyền hoặc context hết hiệu lực
- **Given:** Quyền thay đổi hoặc report context không còn hợp lệ.
- **When:** Hệ thống phát hiện điều kiện “Quyền hoặc context hết hiệu lực” tại BF-02.
- **Then:** Từ chối export; yêu cầu tạo context mới, không tự mở rộng scope. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

## 10. Truy vết

- **Journey:** `BJ-15` — Tra cứu báo cáo tồn và thẻ kho.
- **Domain:** `DOM-IO`.
- **Behavioral Contract:** `SBC-COM-02`, `BC-COMMON-EXTENSIONS`, `SBC-COM-03`, `BC-IO-01`.

- **Nguồn quyết định:** [Nhóm G12 — Ledger, báo cáo và đối soát](../../../01.knowledge/decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i)
- **Bài tri thức liên quan:** [Thẻ kho, báo cáo lịch sử và đối soát nguồn](../../../01.knowledge/know-how/KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon.md); [Nhật ký biến động, số dư dẫn xuất và phục hồi sau sự cố](../../../01.knowledge/know-how/KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md); [Tính chính thức của tồn kho và nguyên tắc chống xuất âm](../../../01.knowledge/know-how/KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am.md); [Quyền chức năng, phạm vi kho và bảo vệ dữ liệu tài chính](../../../01.knowledge/know-how/KB-KGV-030-quyen-chuc-nang-pham-vi-kho-va-bao-ve-du-lieu-tai-chinh.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md)
