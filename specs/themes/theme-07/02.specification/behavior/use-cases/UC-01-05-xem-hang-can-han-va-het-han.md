---
id: UC-01-05
type: use-case
theme: theme-07
title: "Xem hàng cận hạn và hết hạn"
owner: BA
status: IN_REVIEW
source_baseline: v3.10.1
---
# UC-01-05 — Xem hàng cận hạn và hết hạn

## 1. Mục tiêu và outcome

Xem hàng cận hạn và hết hạn để tạo kết quả nghiệp vụ có thể truy vết và kiểm thử độc lập.

**Kết quả thành công:** <ul><li>Các lô cần chú ý được phân nhóm</li><li>Derived expiry indicator</li></ul>

## 2. Ranh giới

### 2.1 Bắt đầu khi

Có lot expiry và policy cận hạn

### 2.2 Kết thúc khi

<ul><li>Các lô cần chú ý được phân nhóm</li><li>Derived expiry indicator</li></ul>

### 2.3 Không bao gồm

Phạm vi không thuộc UC được giữ theo BJ cha và các contract nguồn; migration không bổ sung negative scope mới.

## 3. Actor, trigger và điều kiện trước

- **Actor:** Chủ cửa hàng, người mua hàng hoặc thủ kho
- **Trigger:** Có lot expiry và policy cận hạn
- **Điều kiện trước:** Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện.

## 4. Hành vi nghiệp vụ

### Điều kiện đầu vào và định danh

tenant_id, phạm vi đọc, filter/cut-off/as-of, quyền xem và correlation ID.

### Quy tắc và bất biến

<ul><li>Căn cứ tồn: Chỉ dùng available quantity hiện hành; không cộng hàng sắp về hoặc trừ nhu cầu dự kiến</li><li>Hết/tồn thấp: OUT khi available bằng 0; LOW khi 0 < available ≤ threshold</li><li>Lượng gợi ý: max(0, target_stock_level − available_quantity) theo đơn vị cơ sở</li><li>Thiếu cấu hình: Gắn NOT_CONFIGURED; không tự suy ra threshold/target</li><li>Cận/hết hạn: Product override ưu tiên tenant default; hết hạn bị loại khỏi khả dụng theo ngày nghiệp vụ dù chỉ báo chưa được mở</li><li>LOT/NONE: Chỉ sản phẩm/lượng có expiry mới xuất hiện trong danh sách cận/hết hạn</li></ul>

## 5. Ngoại lệ và thất bại

**Không thành công:** <ul><li>Yêu cầu bị từ chối có mã/lý do rõ ràng.</li><li>Không tạo tác động authoritative ngoài draft hoặc bằng chứng được hợp đồng cho phép.</li><li>Dữ liệu nhập được giữ lại khi việc sửa và thử lại là an toàn.</li></ul>

**Chưa xác định:** <ul><li>Không có finality mutation. Nếu nguồn đọc chưa sẵn sàng hoặc stale, phải trả as_of/stale hoặc lỗi rõ ràng; không suy diễn số liệu.</li></ul>

## 6. Ảnh hưởng nghiệp vụ

Không đổi trạng thái authoritative; chỉ trả read model/snapshot có thời điểm dữ liệu.

**Kiểm toán:** Lưu actor, thời điểm nghiệp vụ/ghi nhận, source/version, correlation ID và bằng chứng quyết định áp dụng.

## 7. Behavioral Contract

- **Hợp đồng dùng chung:** [SBC-COM-02 — Quyền, phạm vi và điều kiện cần](../behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả dùng chung](../behavioral-contracts/BC-COMMON-EXTENSIONS.md)
- **Hợp đồng hành vi chính:** [BC-IO-14 — Query low stock suggestions](../behavioral-contracts/BC-IO-14.md)

## 8. Screen liên quan

| Thuộc tính | Nội dung |
|---|---|
| Màn hình liên quan | [SCR-001](../../../03.design/screens/SCR-001.md); [SCR-003](../../../03.design/screens/SCR-003.md); LOT Detail overlay [SCR-004](../../../03.design/screens/SCR-004.md) |
| Quy tắc sở hữu | Có thể dùng chung màn hình với UC khác. UI Contract được viết một lần theo bề mặt; file này chỉ sở hữu hành vi và lát nghiệm thu của UC. |
| Các trạng thái của màn hình | READY, LOADING/PROCESSING, VALIDATION_ERROR, PERMISSION_DENIED, CONFLICT/STALE và trạng thái kết quả tương ứng. Chỉ khai state thật sự có ý nghĩa với màn hình. |
| Hành động | Mỗi CTA mutation liên kết đúng một Action ID → UC/BC → API; action không đủ quyền không xuất hiện. |
| Phản hồi | Nêu rõ điều vừa xảy ra, tác động dữ liệu và bước tiếp theo; giữ input ở validation/conflict/UNKNOWN khi an toàn. |
| Khả năng sử dụng | Mobile-first; tên màn hình thấy trước khi chọn; touch target tối thiểu 44 px; không dùng chỉ màu để truyền trạng thái. |

## 4.1 Làm rõ semantic — Deep-Dive Review v3.9.1

- Quantity hiển thị theo **stock/base UOM**.
- Freshness dùng `query_as_of` do server trả; UI diễn đạt `Dữ liệu đến`, không dùng thời điểm click refresh làm dữ liệu.
- Expiry attention phân biệt `WARN` và `BLOCK_SALE`; HSD giữ precision nguồn DAY/MONTH/YEAR. Product row dùng wording `Có lô ...`; LOT row dùng `Cận hạn/Hết hạn`.

## 9. Acceptance Scenarios

| ID | Given | When | Then |
|---|---|---|---|
| AS-UC-01-05-01 | Điều kiện cần hợp lệ và dữ liệu đầu vào đầy đủ | Tác nhân thực hiện “Xem hàng cận hạn và hết hạn” | Các lô cần chú ý được phân nhóm; kết quả Derived expiry indicator và có truy vết nguồn. |
| AS-UC-01-05-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-UC-01-05-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-UC-01-05-04 | Không đủ bằng chứng về kết quả cuối | Client timeout hoặc xử lý bị gián đoạn | Không có finality mutation. Nếu nguồn đọc chưa sẵn sàng hoặc stale, phải trả as_of/stale hoặc lỗi rõ ràng; không suy diễn số liệu. |

## 10. Truy vết

- **Nguồn quyết định:** [Nhóm G13 — Bổ sung hàng và vòng đời master data](../../../01.knowledge/decisions/decision-register.md#313-g13-d%E1%BB%AF-li%E1%BB%87u-ch%E1%BB%A7-combo-b%E1%BB%95-sung-h%C3%A0ng-v%C3%A0-nghi%E1%BB%87p-v%E1%BB%A5-%C4%91%E1%BA%B7c-bi%E1%BB%87t); [Nhóm G12 — Cảnh báo, phục hồi, hiệu năng và POS offline](../../../01.knowledge/decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i)
- **Bài tri thức liên quan:** [Tồn dự kiến và đề xuất bổ sung hàng](../../../01.knowledge/know-how/KB-KGV-036-ton-du-kien-va-de-xuat-bo-sung-hang.md); [Cảnh báo tồn kho và vòng đời xử lý](../../../01.knowledge/know-how/KB-KGV-038-canh-bao-ton-kho-va-vong-doi-xu-ly.md); [Hàng cận hạn, hết hạn, hư hỏng và tiêu hủy](../../../01.knowledge/know-how/KB-KGV-014-hang-can-han-het-han-hu-hong-va-tieu-huy.md); [Tồn vật lý và tồn khả dụng](../../../01.knowledge/know-how/KB-KGV-005-ton-vat-ly-va-ton-kha-dung.md)

| Phạm vi | Cách dùng |
|---|---|
| BA | [BJ-01 — Theo dõi tồn, khả dụng và chỉ báo vận hành](../journeys/BJ-01-theo-doi-ton-kha-dung-va-chi-bao-van-hanh.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy nhóm màn hình cũ làm phạm vi backend. |
| FE | Giao theo work package của BJ; trong package đó, UC này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-UC-01-05-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định UC-01-05, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của UC-01-05. Business Journey chỉ giữ flow đầu-cuối; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.

### Nguồn v3.10.1 — UC-01-05 — Xem hàng cận hạn và hết hạn

> **Phiên bản:** 4.1.0  
> **Loại:** Trường hợp sử dụng  
> **Hành trình nghiệp vụ:** [BJ-01 — Theo dõi tồn, khả dụng và chỉ báo vận hành](../journeys/BJ-01-theo-doi-ton-kha-dung-va-chi-bao-van-hanh.md)  
> **Trạng thái:** SPECIFIED_FOR_REVIEW
