---
id: UC-02-04
type: use-case
theme: theme-07
title: "Ghi nhận hàng vào tồn vật lý"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-02
---

# UC-02-04 — Ghi nhận hàng vào tồn vật lý

## 1. Mục tiêu và kết quả nghiệp vụ

Ghi hàng thực nhận vào tồn vật lý bằng một commit nguyên tử cho operation đã đủ điều kiện.

**Kết quả cần đạt:** Operation kết thúc `COMMITTED`, `REJECTED` hoặc `UNKNOWN`; nếu commit thì movement/balance/lot/value-entry cần thiết được ghi đúng một lần.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Hồ sơ hợp lệ và đủ thẩm quyền

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

COMMITTED, REJECTED hoặc UNKNOWN; Movement/balance/lot và result.

### 2.3 Không bao gồm

Không sửa chứng từ mua, không tự xác lập giá trị nhập và không dùng execution để che lỗi dữ liệu. UC chỉ commit lượng thực nhận, trạng thái vật lý và movement tương ứng một lần.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Thủ kho; người duyệt khi có ngoại lệ.
- **Thẩm quyền:** Chỉ tác nhân hoặc system process có quyền thực thi đúng scope mới được commit; mọi guard về source/version, policy và lifecycle phải được server kiểm lại trước effect.
- **Sự kiện khởi phát:** Hồ sơ hợp lệ và đủ thẩm quyền.
- **Điều kiện trước:** Đối tượng đúng version đã đạt trạng thái sẵn sàng thực thi; quyền, policy, lock và các invariant nguồn còn hợp lệ tại thời điểm commit.

## 4. Đối tượng và dữ liệu nghiệp vụ

| Đối tượng / Dữ liệu | Ý nghĩa và yêu cầu | Nguồn |
|---|---|---|
| Nguồn nghiệp vụ và phiên bản | Định danh nguồn/đối tượng nghiệp vụ và phiên bản hiện hành cần dùng để tránh xử lý trên dữ liệu cũ. | DOM-IO / BC liên quan |
| Dữ liệu nghiệp vụ | Các dữ kiện người dùng/nguồn cung cấp cho mục tiêu của Use Case; phải tuân theo rule ở mục 6. | DOM-IO / BC liên quan |
| Phạm vi thực hiện | Tác nhân và phạm vi tenant/cửa hàng/kho mà yêu cầu được phép xử lý. | DOM-IO / BC liên quan |

## 5. Các luồng của Use Case

### 5.1 Luồng chính (Basic Flow)

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| BF-01 | Thủ kho / Hệ thống | Yêu cầu thực thi receipt ở trạng thái `READY` với operation identity hiện hành. |  |
| BF-02 | Hệ thống | Recheck source/approval/version, quantity classification, LOT/HSD và current balance trong transaction. | EF-A — Stale hoặc vi phạm bất biến |
| BF-03 | Hệ thống | Tạo quantity movement cho phần thực nhận; hàng Từ chối không tạo movement, hàng Cách ly/Hỏng vào đúng physical state. |  |
| BF-04 | Hệ thống | Cập nhật balance/lot và outbox/result trong cùng atomic boundary; receipt owned goods chưa có giá chuyển `VALUATION_PENDING` theo contract. | EF-B — Kết quả commit chưa xác định |
| BF-05 | Hệ thống | Trả authoritative receipt result cùng effect refs và discrepancy. |  |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

Không có luồng thay thế riêng ngoài các nhánh kết quả đã thể hiện trong Luồng chính.

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Stale hoặc vi phạm bất biến
**Phát sinh tại:** BF-02. **Điều kiện:** Source/version/approval thay đổi hoặc dữ liệu LOT/quantity không còn hợp lệ .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Reject trước commit; không tạo partial movement/balance effect. | |
| EF-A-02 | — | [Kết thúc UC với `REJECTED`.] | |

#### EF-B — Kết quả commit chưa xác định
**Phát sinh tại:** BF-04. **Điều kiện:** Không đủ bằng chứng client-side về transaction đã commit hay rollback .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Trả `UNKNOWN`, giữ operation identity và chuyển sang UC-02-05/BJ17 để verify; không blind retry. | |
| EF-B-02 | — | [Kết thúc UC.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Nhận vượt nguồn | Đánh giá theo từng source line trên lượng đạt lũy kế ở base UOM; ngưỡng % và số lượng tuyệt đối do ApprovalPolicy quy định| Decision / DOM-IO / BC nguồn |
| BR-02 | Hàng từ chối | Không tạo movement; vẫn lưu discrepancy/evidence| Decision / DOM-IO / BC nguồn |
| BR-03 | Tình trạng ngay khi nhận | Hàng cách ly/hỏng vẫn tăng tồn vật lý vào đúng trạng thái; không được mặc định chuyển thành sellable| Decision / DOM-IO / BC nguồn |
| BR-04 | LOT/expiry | NONE không hỏi hạn dùng; LOT mới mở yêu cầu hạn dùng theo product policy| Decision / DOM-IO / BC nguồn |
| BR-05 | Nhận từng phần | Cho phép nhiều receipt cùng tham chiếu source line nhưng tổng lượng được kiểm bằng concurrency guard| Decision / DOM-IO / BC nguồn |
| BR-06 | Nguyên tử | Movement, balance, lot, result và outbox cùng commit hoặc không có gì commit| Decision / DOM-IO / BC nguồn |

- `SBC-COM-01` — Bao yêu cầu và định danh.
- `BC-COMMON-EXTENSIONS` — Shared behavioral contract extensions.
- `SBC-COM-02` — Quyền, phạm vi và điều kiện cần.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `SBC-COM-04` — Finality và tính nguyên tử.
- `BC-IO-02` — Receive purchased goods.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Operation kết thúc `COMMITTED`, `REJECTED` hoặc `UNKNOWN`; nếu commit thì movement/balance/lot/value-entry cần thiết được ghi đúng một lần. | Hành trình tiếp tục từ kết quả authoritative vừa ghi theo Business Journey sở hữu; không suy bước tiếp theo chỉ từ thứ tự UC. |
| Không đủ điều kiện / Bị từ chối | Nếu precondition, version, quyền hoặc invariant không còn hợp lệ, hệ thống từ chối trước effect; nếu finality chưa rõ thì giữ cùng operation identity để recovery. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** Operation kết thúc `COMMITTED`, `REJECTED` hoặc `UNKNOWN`; nếu commit thì movement/balance/lot/value-entry cần thiết được ghi đúng một lần.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-02 — Nhận hàng mua](../../../03.design/flows/UIF-02-BJ-02.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-012` | Trình bày dữ liệu, trạng thái thực thi và kết quả của “Ghi nhận hàng vào tồn vật lý”; feedback phải phân biệt rõ thành công, từ chối và `UNKNOWN` khi có. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-02-04-01 — Ghi nhận hàng vào tồn vật lý — luồng chính
- **Given:** Hồ sơ hợp lệ và đủ thẩm quyền
- **When:** Yêu cầu thực thi receipt ở trạng thái `READY` với operation identity hiện hành.
- **Then:** Operation kết thúc `COMMITTED`, `REJECTED` hoặc `UNKNOWN`; nếu commit thì movement/balance/lot/value-entry cần thiết được ghi đúng một lần.

### AS-UC-02-04-02 — Ghi nhận hàng vào tồn vật lý — Stale hoặc vi phạm bất biến
- **Given:** Source/version/approval thay đổi hoặc dữ liệu LOT/quantity không còn hợp lệ.
- **When:** Hệ thống phát hiện điều kiện “Stale hoặc vi phạm bất biến” tại BF-02.
- **Then:** Reject trước commit; không tạo partial movement/balance effect. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-02-04-03 — Ghi nhận hàng vào tồn vật lý — Kết quả commit chưa xác định
- **Given:** Không đủ bằng chứng client-side về transaction đã commit hay rollback.
- **When:** Hệ thống phát hiện điều kiện “Kết quả commit chưa xác định” tại BF-04.
- **Then:** Trả `UNKNOWN`, giữ operation identity và chuyển sang UC-02-05/BJ17 để verify; không blind retry. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

## 10. Truy vết

- **Journey:** `BJ-02` — Nhận hàng mua.
- **Domain:** `DOM-IO`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-02`.

- **Nguồn quyết định:** [Nhóm G03 — Nhận hàng mua và giải phóng khả dụng](../../../01.knowledge/decisions/decision-register.md#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B); [Nhóm G02 — Lô, hạn dùng và chính sách theo dõi sản phẩm](../../../01.knowledge/decisions/decision-register.md#32-g02-%C4%91%E1%BB%8Bnh-danh-s%E1%BB%91-d%C6%B0-%C4%91%C6%A1n-v%E1%BB%8B-t%C3%ADnh-v%C3%A0-ch%C3%ADnh-s%C3%A1ch-theo-d%C3%B5i); [Nhóm G11 — Quyền và phê duyệt](../../../01.knowledge/decisions/decision-register.md#311-g11-quy%E1%BB%81n-ph%C3%AA-duy%E1%BB%87t-v%C3%A0-b%E1%BA%A3o-v%E1%BB%87-d%E1%BB%AF-li%E1%BB%87u)
- **Bài tri thức liên quan:** [Nhận hàng mua và xử lý chênh lệch giao nhận](../../../01.knowledge/know-how/KB-KGV-007-nhan-hang-mua-va-xu-ly-chenh-lech-giao-nhan.md); [Hàng đã nhận nhưng chưa chốt giá](../../../01.knowledge/know-how/KB-KGV-008-hang-da-nhan-nhung-chua-chot-gia.md); [Chính sách NONE, LOT hoặc SERIAL](../../../01.knowledge/know-how/KB-KGV-024-chinh-sach-quan-ly-hang-thong-thuong-theo-lo-hoac-theo-serial.md); [Danh tính và vòng đời của một lô hàng](../../../01.knowledge/know-how/KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md); [Phê duyệt inventory operation theo mức rủi ro](../../../01.knowledge/know-how/KB-KGV-031-phe-duyet-inventory-operation-theo-muc-rui-ro.md)
