---
id: UC-01-04
type: use-case
theme: theme-07
title: "Xem tồn thấp và lượng gợi ý"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-01
---

# UC-01-04 — Xem tồn thấp và lượng gợi ý

## 1. Mục tiêu và kết quả nghiệp vụ

Nhận diện sản phẩm hết hàng/tồn thấp và lượng bổ sung gợi ý từ khả dụng hiện hành cùng threshold/target đã cấu hình.

**Kết quả cần đạt:** Chỉ báo `OUT`/`LOW`/`NORMAL` hoặc `NOT_CONFIGURED` và lượng gợi ý được trả cùng `as_of`; không tạo đơn mua hay mutation tồn.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Có availability và threshold/target

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Trạng thái OUT/LOW và lượng gợi ý được hiển thị; Derived replenishment indicator.

### 2.3 Không bao gồm

Không tự tạo đơn mua, không tự đặt ngưỡng và không thay đổi tồn. UC này chỉ tính/chỉ ra tình trạng tồn thấp và lượng gợi ý từ policy hiện hành.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Chủ cửa hàng, người mua hàng hoặc thủ kho.
- **Thẩm quyền:** Chỉ được đọc đúng tenant/cửa hàng/kho/sản phẩm thuộc phạm vi được cấp; quyền xem số lượng, giá trị và dữ liệu tài chính được kiểm soát độc lập theo policy.
- **Sự kiện khởi phát:** Có availability và threshold/target.
- **Điều kiện trước:** Ngữ cảnh tenant/cửa hàng/kho và quyền đọc hợp lệ; nguồn/read model cần cho truy vấn có thể xác định được `as_of`/version hoặc trả trạng thái stale rõ ràng.

## 4. Đối tượng và dữ liệu nghiệp vụ

| Đối tượng / Dữ liệu | Ý nghĩa và yêu cầu | Nguồn |
|---|---|---|
| Đối tượng nghiệp vụ | Đối tượng/phạm vi được nêu tại điều kiện bắt đầu và các rule bên dưới | DOM-IO |

## 5. Các luồng của Use Case

### 5.1 Luồng chính (Basic Flow)

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| BF-01 | Người dùng | Mở danh sách tồn thấp/cần bổ sung trong phạm vi kho được phép. |  |
| BF-02 | Hệ thống | Đọc `available_quantity`, threshold và target theo policy/version hiện hành. | AF-A — Chưa cấu hình threshold/target |
| BF-03 | Hệ thống | Phân loại `OUT` khi available = 0, `LOW` khi 0 < available ≤ threshold; còn lại `NORMAL`. | BR-02 — Hết/tồn thấp |
| BF-04 | Hệ thống | Tính `max(0, target_stock_level - available_quantity)` theo base UOM và gắn `as_of`. | BR-03 — Lượng gợi ý |
| BF-05 | Người dùng | Đọc chỉ báo/gợi ý; quyết định mua hàng thuộc Theme/owner tương ứng, không phải UC này. |  |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Chưa cấu hình threshold/target
**Phát sinh tại:** BF-02. **Điều kiện:** Sản phẩm hoặc tenant chưa có threshold/target hợp lệ .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Trả `NOT_CONFIGURED`, không tự suy ra threshold/target hay lượng gợi ý. | |
| AF-A-02 | — | [Kết thúc UC.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Projection stale hoặc sai phạm vi
**Phát sinh tại:** BF-02. **Điều kiện:** Nguồn tồn stale hoặc query vượt phạm vi được cấp .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Trả stale/permission rõ ràng; không tính gợi ý từ dữ liệu không đủ tin cậy. | |
| EF-A-02 | — | [Kết thúc UC.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Căn cứ tồn | Chỉ dùng available quantity hiện hành; không cộng hàng sắp về hoặc trừ nhu cầu dự kiến| Decision / DOM-IO / BC nguồn |
| BR-02 | Hết/tồn thấp | OUT khi available bằng 0; LOW khi 0 < available ≤ threshold| Decision / DOM-IO / BC nguồn |
| BR-03 | Lượng gợi ý | max(0, target_stock_level − available_quantity) theo đơn vị cơ sở| Decision / DOM-IO / BC nguồn |
| BR-04 | Thiếu cấu hình | Gắn NOT_CONFIGURED; không tự suy ra threshold/target| Decision / DOM-IO / BC nguồn |
| BR-05 | Cận/hết hạn | Product override ưu tiên tenant default; hết hạn bị loại khỏi khả dụng theo ngày nghiệp vụ dù chỉ báo chưa được mở| Decision / DOM-IO / BC nguồn |
| BR-06 | LOT/NONE | Chỉ sản phẩm/lượng có expiry mới xuất hiện trong danh sách cận/hết hạn| Decision / DOM-IO / BC nguồn |

- `SBC-COM-02` — Quyền, phạm vi và điều kiện cần.
- `BC-COMMON-EXTENSIONS` — Shared behavioral contract extensions.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `BC-IO-14` — Query low stock suggestions.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Chỉ báo `OUT`/`LOW`/`NORMAL` hoặc `NOT_CONFIGURED` và lượng gợi ý được trả cùng `as_of`; không tạo đơn mua hay mutation tồn. | Kết thúc tra cứu hoặc chuyển sang UC/BJ khác theo nhu cầu nghiệp vụ; UC này không ghi thay đổi authoritative. |
| Không đủ điều kiện / Bị từ chối | Nếu thiếu quyền, dữ liệu không tồn tại hoặc nguồn stale, hệ thống trả đúng trạng thái đọc/cảnh báo; không tạo mutation. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |

**Ảnh hưởng nghiệp vụ chính:** Chỉ báo `OUT`/`LOW`/`NORMAL` hoặc `NOT_CONFIGURED` và lượng gợi ý được trả cùng `as_of`; không tạo đơn mua hay mutation tồn.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-01 — Theo dõi tồn, khả dụng và chỉ báo vận hành](../../../03.design/flows/UIF-01-BJ-01.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-001` | Trình bày dữ liệu, thời điểm và trạng thái đọc cần để “Xem tồn thấp và lượng gợi ý”; không tạo mutation. |
| `SCR-003` | Trình bày dữ liệu, thời điểm và trạng thái đọc cần để “Xem tồn thấp và lượng gợi ý”; không tạo mutation. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-01-04-01 — Xem tồn thấp và lượng gợi ý — luồng chính
- **Given:** Có availability và threshold/target
- **When:** Mở danh sách tồn thấp/cần bổ sung trong phạm vi kho được phép.
- **Then:** Chỉ báo `OUT`/`LOW`/`NORMAL` hoặc `NOT_CONFIGURED` và lượng gợi ý được trả cùng `as_of`; không tạo đơn mua hay mutation tồn.

### AS-UC-01-04-02 — Xem tồn thấp và lượng gợi ý — Chưa cấu hình threshold/target
- **Given:** Sản phẩm hoặc tenant chưa có threshold/target hợp lệ.
- **When:** Hệ thống phát hiện điều kiện “Chưa cấu hình threshold/target” tại BF-02.
- **Then:** Trả `NOT_CONFIGURED`, không tự suy ra threshold/target hay lượng gợi ý. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-01-04-03 — Xem tồn thấp và lượng gợi ý — Projection stale hoặc sai phạm vi
- **Given:** Nguồn tồn stale hoặc query vượt phạm vi được cấp.
- **When:** Hệ thống phát hiện điều kiện “Projection stale hoặc sai phạm vi” tại BF-02.
- **Then:** Trả stale/permission rõ ràng; không tính gợi ý từ dữ liệu không đủ tin cậy. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

## 10. Truy vết

- **Journey:** `BJ-01` — Theo dõi tồn, khả dụng và chỉ báo vận hành.
- **Domain:** `DOM-IO`.
- **Behavioral Contract:** `SBC-COM-02`, `BC-COMMON-EXTENSIONS`, `SBC-COM-03`, `BC-IO-14`.

- **Nguồn quyết định:** [Nhóm G13 — Bổ sung hàng và vòng đời master data](../../../01.knowledge/decisions/decision-register.md#313-g13-d%E1%BB%AF-li%E1%BB%87u-ch%E1%BB%A7-combo-b%E1%BB%95-sung-h%C3%A0ng-v%C3%A0-nghi%E1%BB%87p-v%E1%BB%A5-%C4%91%E1%BA%B7c-bi%E1%BB%87t); [Nhóm G12 — Cảnh báo, phục hồi, hiệu năng và POS offline](../../../01.knowledge/decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i)
- **Bài tri thức liên quan:** [Tồn dự kiến và đề xuất bổ sung hàng](../../../01.knowledge/know-how/KB-KGV-036-ton-du-kien-va-de-xuat-bo-sung-hang.md); [Cảnh báo tồn kho và vòng đời xử lý](../../../01.knowledge/know-how/KB-KGV-038-canh-bao-ton-kho-va-vong-doi-xu-ly.md); [Hàng cận hạn, hết hạn, hư hỏng và tiêu hủy](../../../01.knowledge/know-how/KB-KGV-014-hang-can-han-het-han-hu-hong-va-tieu-huy.md); [Tồn vật lý và tồn khả dụng](../../../01.knowledge/know-how/KB-KGV-005-ton-vat-ly-va-ton-kha-dung.md)
