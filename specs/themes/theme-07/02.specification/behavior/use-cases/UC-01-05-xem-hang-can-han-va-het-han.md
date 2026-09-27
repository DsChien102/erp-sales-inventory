---
id: UC-01-05
type: use-case
theme: theme-07
title: "Xem hàng cận hạn và hết hạn"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-01
---

# UC-01-05 — Xem hàng cận hạn và hết hạn

## 1. Mục tiêu và kết quả nghiệp vụ

Nhận diện các lô cận hạn và hết hạn từ HSD thực tế cùng policy cận hạn hiện hành.

**Kết quả cần đạt:** Các lô cần chú ý được phân nhóm theo cận hạn/hết hạn với `as_of`; không tự đổi trạng thái hay tiêu hủy hàng.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Có lot expiry và policy cận hạn

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Các lô cần chú ý được phân nhóm; Derived expiry indicator.

### 2.3 Không bao gồm

Không tự chuyển trạng thái hoặc tiêu hủy hàng. UC này chỉ xác định và hiển thị lượng cận hạn/hết hạn từ hạn dùng và ngày nghiệp vụ hiện hành.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Chủ cửa hàng, người mua hàng hoặc thủ kho.
- **Thẩm quyền:** Chỉ được đọc đúng tenant/cửa hàng/kho/sản phẩm thuộc phạm vi được cấp; quyền xem số lượng, giá trị và dữ liệu tài chính được kiểm soát độc lập theo policy.
- **Sự kiện khởi phát:** Có lot expiry và policy cận hạn.
- **Điều kiện trước:** Ngữ cảnh tenant/cửa hàng/kho và quyền đọc hợp lệ; nguồn/read model cần cho truy vấn có thể xác định được `as_of`/version hoặc trả trạng thái stale rõ ràng.

## 4. Đối tượng và dữ liệu nghiệp vụ

| Đối tượng / Dữ liệu | Ý nghĩa và yêu cầu | Nguồn |
|---|---|---|
| Đối tượng nghiệp vụ | Đối tượng/phạm vi được nêu tại điều kiện bắt đầu và các rule bên dưới | DOM-IO |

## 5. Các luồng của Use Case

### 5.1 Luồng chính (Basic Flow)

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| BF-01 | Người dùng | Mở danh sách hàng cận hạn/hết hạn. |  |
| BF-02 | Hệ thống | Đọc các lô có expiry trong phạm vi và policy cận hạn: Product override trước tenant default. | AF-A — Chưa cấu hình policy cận hạn |
| BF-03 | Hệ thống | Xác định lô đã hết hạn theo ngày nghiệp vụ; xác định cận hạn theo số ngày policy còn lại. |  |
| BF-04 | Hệ thống | Loại sản phẩm `NONE`/không có expiry khỏi danh sách và gắn `as_of`. | BR-06 — LOT/NONE |
| BF-05 | Người dùng | Đọc danh sách; thay đổi state/tiêu hủy nếu cần đi BJ09/BJ10, không thực hiện trong UC này. |  |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Chưa cấu hình policy cận hạn
**Phát sinh tại:** BF-02. **Điều kiện:** Không có Product override hoặc tenant default cho cảnh báo cận hạn .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Không tự đặt ngưỡng; vẫn xác định hàng đã hết hạn trực tiếp từ expiry date, còn cận hạn trả `NOT_CONFIGURED`. | |
| AF-A-02 | — | [Kết thúc UC.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Dữ liệu HSD không hợp lệ
**Phát sinh tại:** BF-02. **Điều kiện:** Lô thiếu/mâu thuẫn HSD trong khi tracking yêu cầu expiry .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Không tự suy HSD; trả lỗi dữ liệu nguồn để xử lý ở owner thích hợp. | |
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
| Thành công | Các lô cần chú ý được phân nhóm theo cận hạn/hết hạn với `as_of`; không tự đổi trạng thái hay tiêu hủy hàng. | Kết thúc tra cứu hoặc chuyển sang UC/BJ khác theo nhu cầu nghiệp vụ; UC này không ghi thay đổi authoritative. |
| Không đủ điều kiện / Bị từ chối | Nếu thiếu quyền, dữ liệu không tồn tại hoặc nguồn stale, hệ thống trả đúng trạng thái đọc/cảnh báo; không tạo mutation. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |

**Ảnh hưởng nghiệp vụ chính:** Các lô cần chú ý được phân nhóm theo cận hạn/hết hạn với `as_of`; không tự đổi trạng thái hay tiêu hủy hàng.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-01 — Theo dõi tồn, khả dụng và chỉ báo vận hành](../../../03.design/flows/UIF-01-BJ-01.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-001` | Trình bày dữ liệu, thời điểm và trạng thái đọc cần để “Xem hàng cận hạn và hết hạn”; không tạo mutation. |
| `SCR-003` | Trình bày dữ liệu, thời điểm và trạng thái đọc cần để “Xem hàng cận hạn và hết hạn”; không tạo mutation. |
| `SCR-004` | Trình bày dữ liệu, thời điểm và trạng thái đọc cần để “Xem hàng cận hạn và hết hạn”; không tạo mutation. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-01-05-01 — Xem hàng cận hạn và hết hạn — luồng chính
- **Given:** Có lot expiry và policy cận hạn
- **When:** Mở danh sách hàng cận hạn/hết hạn.
- **Then:** Các lô cần chú ý được phân nhóm theo cận hạn/hết hạn với `as_of`; không tự đổi trạng thái hay tiêu hủy hàng.

### AS-UC-01-05-02 — Xem hàng cận hạn và hết hạn — Chưa cấu hình policy cận hạn
- **Given:** Không có Product override hoặc tenant default cho cảnh báo cận hạn.
- **When:** Hệ thống phát hiện điều kiện “Chưa cấu hình policy cận hạn” tại BF-02.
- **Then:** Không tự đặt ngưỡng; vẫn xác định hàng đã hết hạn trực tiếp từ expiry date, còn cận hạn trả `NOT_CONFIGURED`. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-01-05-03 — Xem hàng cận hạn và hết hạn — Dữ liệu HSD không hợp lệ
- **Given:** Lô thiếu/mâu thuẫn HSD trong khi tracking yêu cầu expiry.
- **When:** Hệ thống phát hiện điều kiện “Dữ liệu HSD không hợp lệ” tại BF-02.
- **Then:** Không tự suy HSD; trả lỗi dữ liệu nguồn để xử lý ở owner thích hợp. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

## 10. Truy vết

- **Journey:** `BJ-01` — Theo dõi tồn, khả dụng và chỉ báo vận hành.
- **Domain:** `DOM-IO`.
- **Behavioral Contract:** `SBC-COM-02`, `BC-COMMON-EXTENSIONS`, `SBC-COM-03`, `BC-IO-14`.

- **Nguồn quyết định:** [Nhóm G13 — Bổ sung hàng và vòng đời master data](../../../01.knowledge/decisions/decision-register.md#313-g13-d%E1%BB%AF-li%E1%BB%87u-ch%E1%BB%A7-combo-b%E1%BB%95-sung-h%C3%A0ng-v%C3%A0-nghi%E1%BB%87p-v%E1%BB%A5-%C4%91%E1%BA%B7c-bi%E1%BB%87t); [Nhóm G12 — Cảnh báo, phục hồi, hiệu năng và POS offline](../../../01.knowledge/decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i)
- **Bài tri thức liên quan:** [Tồn dự kiến và đề xuất bổ sung hàng](../../../01.knowledge/know-how/KB-KGV-036-ton-du-kien-va-de-xuat-bo-sung-hang.md); [Cảnh báo tồn kho và vòng đời xử lý](../../../01.knowledge/know-how/KB-KGV-038-canh-bao-ton-kho-va-vong-doi-xu-ly.md); [Hàng cận hạn, hết hạn, hư hỏng và tiêu hủy](../../../01.knowledge/know-how/KB-KGV-014-hang-can-han-het-han-hu-hong-va-tieu-huy.md); [Tồn vật lý và tồn khả dụng](../../../01.knowledge/know-how/KB-KGV-005-ton-vat-ly-va-ton-kha-dung.md)
