---
id: UC-15-04
type: use-case
theme: theme-07
title: "Xuất báo cáo"
owner: BA
status: IN_REVIEW
source_baseline: v3.10.1
---
# UC-15-04 — Xuất báo cáo

## 1. Mục tiêu và outcome

Xuất báo cáo để tạo kết quả nghiệp vụ có thể truy vết và kiểm thử độc lập.

**Kết quả thành công:** <ul><li>File được tạo đúng scope/quyền</li><li>Report export có cut-off/as-of</li></ul>

## 2. Ranh giới

### 2.1 Bắt đầu khi

Có kết quả và quyền export

### 2.2 Kết thúc khi

<ul><li>File được tạo đúng scope/quyền</li><li>Report export có cut-off/as-of</li></ul>

### 2.3 Không bao gồm

Phạm vi không thuộc UC được giữ theo BJ cha và các contract nguồn; migration không bổ sung negative scope mới.

## 3. Actor, trigger và điều kiện trước

- **Actor:** Chủ cửa hàng, kế toán hoặc thủ kho
- **Trigger:** Có kết quả và quyền export
- **Điều kiện trước:** Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện.

## 4. Hành vi nghiệp vụ

### Điều kiện đầu vào và định danh

tenant_id, phạm vi đọc, filter/cut-off/as-of, quyền xem và correlation ID.

### Quy tắc và bất biến

<ul><li>Ledger authority: Thẻ kho và lịch sử dựa trên Nhật ký biến động bất biến; không sửa số dư từ báo cáo</li><li>Cut-off/as-of: Báo cáo phải thể hiện cut-off, thời điểm tạo và độ mới của projection</li><li>Hai loại ngày: Cho phép đọc theo ngày ghi nhận hoặc ngày nghiệp vụ nhưng phải gắn nhãn rõ, không trộn ngầm</li><li>Quantity/value: Quyền xem quantity độc lập với quyền xem official cost, total value và valuation adjustment</li><li>LOT/NONE: Breakdown theo lô chỉ áp dụng cho sản phẩm LOT; không tạo lô giả cho NONE</li><li>Giá trị chi tiết: Giá trị có thẩm quyền ở tenant + sản phẩm; phân bổ theo kho/state/lot nếu có phải gắn nhãn dẫn xuất</li></ul>

## 5. Ngoại lệ và thất bại

**Không thành công:** <ul><li>Yêu cầu bị từ chối có mã/lý do rõ ràng.</li><li>Không tạo tác động authoritative ngoài draft hoặc bằng chứng được hợp đồng cho phép.</li><li>Dữ liệu nhập được giữ lại khi việc sửa và thử lại là an toàn.</li></ul>

**Chưa xác định:** <ul><li>Không có finality mutation. Nếu nguồn đọc chưa sẵn sàng hoặc stale, phải trả as_of/stale hoặc lỗi rõ ràng; không suy diễn số liệu.</li></ul>

## 6. Ảnh hưởng nghiệp vụ

Không đổi trạng thái authoritative; chỉ trả read model/snapshot có thời điểm dữ liệu.

**Kiểm toán:** Lưu actor, thời điểm nghiệp vụ/ghi nhận, source/version, correlation ID và bằng chứng quyết định áp dụng.

## 7. Behavioral Contract

- **Hợp đồng dùng chung:** [SBC-COM-02 — Quyền, phạm vi và điều kiện cần](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả dùng chung](../behavioral-contracts/BC-COMMON-EXTENSIONS.md)
- **Hợp đồng hành vi chính:** [BC-IO-01 — Query inventory availability](../behavioral-contracts/BC-IO-01.md)

## 8. Screen liên quan

| Thuộc tính | Nội dung |
|---|---|
| Màn hình liên quan | [SCR-058](../../../03.design/screens/SCR-058.md); [SCR-059](../../../03.design/screens/SCR-059.md) |
| Quy tắc sở hữu | Có thể dùng chung màn hình với UC khác. UI Contract được viết một lần theo bề mặt; file này chỉ sở hữu hành vi và lát nghiệm thu của UC. |
| Các trạng thái của màn hình | READY, LOADING/PROCESSING, VALIDATION_ERROR, PERMISSION_DENIED, CONFLICT/STALE và trạng thái kết quả tương ứng. Chỉ khai state thật sự có ý nghĩa với màn hình. |
| Hành động | Mỗi CTA mutation liên kết đúng một Action ID → UC/BC → API; action không đủ quyền không xuất hiện. |
| Phản hồi | Nêu rõ điều vừa xảy ra, tác động dữ liệu và bước tiếp theo; giữ input ở validation/conflict/UNKNOWN khi an toàn. |
| Khả năng sử dụng | Mobile-first; tên màn hình thấy trước khi chọn; touch target tối thiểu 44 px; không dùng chỉ màu để truyền trạng thái. |

## 9. Acceptance Scenarios

| ID | Given | When | Then |
|---|---|---|---|
| AS-UC-15-04-01 | Điều kiện cần hợp lệ và dữ liệu đầu vào đầy đủ | Tác nhân thực hiện “Xuất báo cáo” | File được tạo đúng scope/quyền; kết quả Report export có cut-off/as-of và có truy vết nguồn. |
| AS-UC-15-04-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-UC-15-04-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-UC-15-04-04 | Không đủ bằng chứng về kết quả cuối | Client timeout hoặc xử lý bị gián đoạn | Không có finality mutation. Nếu nguồn đọc chưa sẵn sàng hoặc stale, phải trả as_of/stale hoặc lỗi rõ ràng; không suy diễn số liệu. |

## 10. Truy vết

- **Nguồn quyết định:** [Nhóm G12 — Ledger, báo cáo và đối soát](../../../01.knowledge/decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i)
- **Bài tri thức liên quan:** [Thẻ kho, báo cáo lịch sử và đối soát nguồn](../../../01.knowledge/know-how/KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon.md); [Nhật ký biến động, số dư dẫn xuất và phục hồi sau sự cố](../../../01.knowledge/know-how/KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md); [Tính chính thức của tồn kho và nguyên tắc chống xuất âm](../../../01.knowledge/know-how/KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am.md); [Quyền chức năng, phạm vi kho và bảo vệ dữ liệu tài chính](../../../01.knowledge/know-how/KB-KGV-030-quyen-chuc-nang-pham-vi-kho-va-bao-ve-du-lieu-tai-chinh.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md)

| Phạm vi | Cách dùng |
|---|---|
| BA | [BJ-15 — Tra cứu báo cáo tồn và thẻ kho](../journeys/BJ-15-tra-cuu-bao-cao-ton-va-the-kho.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy nhóm màn hình cũ làm phạm vi backend. |
| FE | Giao theo work package của BJ; trong package đó, UC này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-UC-15-04-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định UC-15-04, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của UC-15-04. Business Journey chỉ giữ flow đầu-cuối; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.

### Nguồn v3.10.1 — UC-15-04 — Xuất báo cáo

> **Phiên bản:** 4.1.0  
> **Loại:** Trường hợp sử dụng  
> **Hành trình nghiệp vụ:** [BJ-15 — Tra cứu báo cáo tồn và thẻ kho](../journeys/BJ-15-tra-cuu-bao-cao-ton-va-the-kho.md)  
> **Trạng thái:** SPECIFIED_FOR_REVIEW
