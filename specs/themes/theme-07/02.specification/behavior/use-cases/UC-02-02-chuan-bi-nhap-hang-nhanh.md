---
id: UC-02-02
type: use-case
theme: theme-07
title: "Chuẩn bị nhập hàng nhanh"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v4.6.7
ui_flow: UIF-02
---

# UC-02-02 — Chuẩn bị nhập hàng nhanh

## 1. Mục tiêu và kết quả nghiệp vụ

Chuẩn bị dữ liệu nhận hàng nhanh khi hàng đã đến nhưng chưa có chứng từ mua phù hợp, sau đó gửi một lệnh duy nhất để tạo receipt và chuyển sang phê duyệt. Không tạo PO giả và không tạo bản nháp trước khi gửi.

**Kết quả cần đạt:** nếu lệnh gửi hợp lệ, hệ thống tạo Quick Receipt, cấp `receiptId` và trạng thái đầu tiên được persist là `PENDING_APPROVAL`; chưa tăng tồn vật lý. Nếu lệnh bị từ chối, không tạo receipt.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Hàng đã đến, chưa có chứng từ mua phù hợp và chính sách cho phép nhập hàng nhanh.

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

UC kết thúc theo một trong hai kết quả:

- **Thành công:** command create-and-submit hợp lệ tạo `GoodsReceipt` + `ApprovalCase` trong cùng transaction, trả `receiptId`, trạng thái receipt = `PENDING_APPROVAL`.
- **Bị từ chối:** command không tạo `GoodsReceipt`; không có `receiptId` và không có trạng thái `DRAFT` để giữ lại.

### 2.3 Không bao gồm

- Không tạo PO giả.
- Không tạo `GoodsReceipt DRAFT`, không gọi `createDraft` / `addOrUpdateLine` trước submit.
- Không persist dữ liệu form lên server hoặc local storage. Dữ liệu `SCR-008 → SCR-009 → SCR-084 → SCR-010` chỉ tồn tại trong phiên màn hình; rời luồng, refresh hoặc đóng app thì mất.
- Chưa ghi tăng tồn ở UC này; ghi nhận vật lý vẫn thuộc UC-02-04 sau phê duyệt.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Thủ kho hoặc người có quyền lập hồ sơ nhận hàng nhanh.
- **Thẩm quyền:** Được chuẩn bị dữ liệu trong phiên UI và gửi Quick Receipt trong đúng tenant/cửa hàng/kho; chưa có quyền tự phê duyệt hoặc tự ghi tồn.
- **Sự kiện khởi phát:** Hàng đã đến, chưa có chứng từ mua phù hợp và chính sách cho phép nhập hàng nhanh.
- **Điều kiện trước:** tác nhân có quyền; Supplier/Product/UOM tồn tại; warehouse scope hợp lệ; ApprovalPolicy active; có eligible approver; các policy bắt buộc có thể resolve.

## 4. Đối tượng và dữ liệu nghiệp vụ

| Đối tượng / Dữ liệu | Ý nghĩa và yêu cầu | Nguồn |
|---|---|---|
| Supplier | Một Supplier hiện hữu cho toàn bộ Quick Receipt. | Theme 3 / reference contract |
| Các mục hàng | Mỗi mục = Product + transaction UOM; lượng/phân loại/LOT theo policy sản phẩm. | Product/UOM master + user input |
| Evidence giao nhận | 1+ evidence refs theo Shared Attachment Policy. | User input / attachment contract |
| Ownership assertion | Xác nhận quyền sở hữu gắn với actor và evidence. | User action + system context |
| `idempotencyKey` | Identity chống lặp của **lệnh gửi**; phải giữ nguyên khi retry/recovery. | Client command envelope |
| `receiptId` | Chỉ được cấp sau khi create-and-submit thành công. | Server-generated |

## 5. Các luồng của Use Case

### 5.1 Luồng chính (Basic Flow)

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| BF-01 | Thủ kho | Mở Nhập hàng nhanh và chọn Supplier đã tồn tại. | Dữ liệu chỉ nằm trong phiên UI. |
| BF-02 | Thủ kho | Thêm các sản phẩm thực nhận; chọn transaction UOM và ghi lượng/LOT/phân loại theo cấu hình sản phẩm. | EF-A — Supplier/Product không resolve được |
| BF-03 | Thủ kho | Bổ sung chứng từ giao nhận/evidence và xác nhận quyền sở hữu. | Không persist receipt; không thu thập price/FX basis trong BJ02. |
| BF-04 | Hệ thống/UI | Kiểm tra thiếu dòng, UOM, LOT/HSD, evidence và duplicate Product+UOM trước khi cho gửi. | AF-A — Có dữ liệu cần sửa |
| BF-05 | Thủ kho | Chọn **Gửi phê duyệt**. Client gửi toàn bộ Supplier + items + evidence + ownership context + `idempotencyKey` trong một command. | `BC-IC-07`; không gọi `BC-IO-16`. |
| BF-06 | Hệ thống | Kiểm tra lại toàn bộ payload, quyền, scope và approver theo policy dành cho Quick Receipt. Nếu hợp lệ, tạo `GoodsReceipt` + `ApprovalCase` nguyên tử, cấp `receiptId`, receipt bắt đầu ở `PENDING_APPROVAL`. | EF-B — Command bị từ chối; EF-C — Kết quả chưa xác định |
| BF-07 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Có dữ liệu cần sửa
**Phát sinh tại:** BF-04. **Điều kiện:** thiếu dòng/UOM/LOT/HSD/evidence hoặc trùng Product+UOM.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống/UI | Chỉ rõ lỗi để thủ kho sửa trong phiên hiện tại; không gửi command và không tạo receipt. | Không dùng mã `DRAFT_*`. |
| AF-A-02 | — | [Trở lại BF-02/BF-03.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Supplier/Product không resolve được
**Phát sinh tại:** BF-02. **Điều kiện:** người dùng nhập/chọn dữ liệu chưa resolve tới master record hợp lệ.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Không cho gửi và không tạo master data trong BJ02; hướng sang Theme 2/3 nếu cần. | Không tạo receipt. |
| EF-A-02 | — | [Kết thúc hoặc sửa lựa chọn trong cùng phiên.] | |

#### EF-B — Command bị từ chối trước khi tạo receipt
**Phát sinh tại:** BF-06. **Điều kiện:** server phát hiện dữ kiện bắt buộc không hợp lệ hoặc thiếu approver phù hợp.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Từ chối toàn bộ command; không tạo `GoodsReceipt` và không cấp `receiptId`. | Thiếu approver → `APPROVER_CONFIGURATION_MISSING`; lỗi dữ liệu còn lại không dùng `DRAFT_*`. `APPROVAL_PRICE_BASIS_REQUIRED` không áp dụng cho Quick Receipt. |
| EF-B-02 | Thủ kho | Có thể sửa dữ liệu khi vẫn còn trong phiên; nếu rời luồng/refresh/đóng app thì dữ liệu mất. | |

#### EF-C — Kết quả submit chưa xác định
**Phát sinh tại:** BF-06. **Điều kiện:** client không nhận được kết quả cuối của command.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-C-01 | Hệ thống/Client | Retry hoặc query command result bằng **cùng `idempotencyKey`**; không tạo command identity mới. | Nếu lần đầu đã thành công, trả lại cùng `receiptId`/`PENDING_APPROVAL`; nếu đã bị từ chối, trả lại cùng rejection. |
| EF-C-02 | — | [Kết thúc/hand-off recovery.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Quick Receipt luôn cần duyệt | Quick Receipt chỉ được tạo thành công ở `PENDING_APPROVAL`; không có nhánh đi thẳng `READY`. | Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-02 | Một Supplier | Một Quick Receipt có đúng một Supplier đã tồn tại; Product cũng phải tồn tại. BJ-02 không tạo Supplier, Product hoặc PO/source giả. | Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-03 | Nhiều mục hàng | Quick Receipt hỗ trợ nhiều mục; mỗi mục nghiệp vụ/UI = một Product + một transaction UOM. | Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-04 | UOM và duplicate | Nếu Product có một UOM nhập hợp lệ thì dùng trực tiếp; nếu có nhiều thì user chọn. Cùng Product + UOM khác được tạo mục khác; cùng Product + cùng UOM bị chặn. | Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-05 | Materialization kỹ thuật | Một mục có thể materialize thành nhiều technical lines theo lot/state nhưng phải giữ cùng receipt-item reference. | Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-06 | Phân loại số lượng | Đạt/Cách ly/Hỏng/Từ chối là authoritative inputs; `Tổng kiểm nhận` derive; `Vào tồn vật lý = Đạt + Cách ly + Hỏng`; không có input total riêng. | Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-07 | LOT/expiry | LOT/expiry theo Product policy; `LOT` bắt buộc lot code, expiry theo `expiry_required`, manufacture date optional. | Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-08 | Không có `DRAFT` | Quick Receipt **không có trạng thái `DRAFT`**. Thiếu approver hoặc dữ kiện BJ02 bắt buộc thì command bị từ chối và **không tạo receipt**. Price/FX basis không phải điều kiện submit của UC-02-02. | T7-DR-027 / BC-IC-07 |
| BR-09 | Kho nhận | Kho nhận Phase 1 là system-owned fact; UI hiển thị read-only, không dropdown affordance. | Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-10 | Ngày nhận | `receipt_business_date` do server/tenant business clock xác lập và read-only; không dùng browser clock/date picker. | Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-11 | Evidence | `Chứng từ giao nhận` là 1+ evidence refs bắt buộc; loại file/kích thước/số lượng theo Shared Attachment Policy. | Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-12 | Chọn UOM | Product nhiều UOM hiển thị toàn bộ UOM nhập hợp lệ để user chọn trực tiếp; chọn Product+UOM xong mở one-item editor. | Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-13 | Phiên UI không persist | Dữ liệu `SCR-008 → SCR-009 → SCR-084 → SCR-010` chỉ tồn tại trong memory của phiên màn hình. Rời Quick flow, refresh hoặc đóng app thì mất; không server draft, không local draft. | T7-DR-027 / UIF-02 |
| BR-14 | Create-and-submit nguyên tử | Chỉ một command gửi tạo receipt. `receiptId` chỉ có sau success; validation/approval-routing rejection không để lại receipt. | T7-DR-027 / BC-IC-07 / API-C-26 |
| BR-15 | Không chặn theo giá/tỷ giá tại BJ02 | Quick Receipt approval là bắt buộc nhưng không dùng price/FX basis hoặc `risk_value_vnd` làm guard tạo receipt. Căn cứ giá/tỷ giá được xác lập/resolve ở BJ03/BJ13 theo authority tương ứng. | T7-DR-027 / T7-DR-080 |

- `SBC-COM-01` — Bao yêu cầu và định danh.
- `BC-COMMON-EXTENSIONS` — Shared behavioral contract extensions.
- `SBC-COM-02` — Quyền, phạm vi và điều kiện cần.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `SBC-COM-04` — Finality và tính nguyên tử.
- `BC-IC-07` — Submit inventory operation / Quick Receipt create-and-submit.

> `BC-IO-16` / `API-C-25` **không áp dụng cho UC-02-02**.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | `GoodsReceipt` được tạo, có `receiptId`, trạng thái đầu = `PENDING_APPROVAL`; chưa tăng tồn vật lý. | Bàn giao UC-02-03; người lập có thể Về Kho. |
| Không đủ điều kiện / Bị từ chối | Không tạo receipt, không có `receiptId`, không có server/local draft. | Nếu còn trong phiên thì sửa và gửi lại; nếu đã rời/refresh/đóng app thì nhập lại từ đầu. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại; outcome gắn với cùng `idempotencyKey`. | Retry/query bằng cùng `idempotencyKey`; không tạo Quick Receipt thứ hai. |

**Ảnh hưởng nghiệp vụ chính:** Quick Receipt chỉ tồn tại trong domain sau khi command create-and-submit thành công và bắt đầu ở `PENDING_APPROVAL`.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-02 — Nhận hàng mua](../../../03.design/flows/UIF-02-BJ-02.md)

| Screen | Vai trò trong UC |
|---|---|
| `SCR-006` | Chọn Nhập hàng nhanh; chưa tạo receipt. |
| `SCR-008` | Nhập header/evidence trong phiên UI; không persist draft. |
| `SCR-009` | Quản lý danh sách Product+UOM trong phiên UI; không persist draft. |
| `SCR-084` | Chỉnh một Product+UOM/LOT trong phiên UI; không persist draft. |
| `SCR-010` | Rà soát và gửi **một command create-and-submit**; success mới có `receiptId`. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-02-02-01 — Gửi Quick Receipt hợp lệ
- **Given:** phiên Nhập hàng nhanh có Supplier, ít nhất một Product+UOM hợp lệ, LOT/evidence/ownership đầy đủ và có approver phù hợp.
- **When:** thủ kho chọn **Gửi phê duyệt** với một `idempotencyKey` mới.
- **Then:** hệ thống tạo một `GoodsReceipt`, cấp `receiptId`, tạo ApprovalCase, trả trạng thái `PENDING_APPROVAL`; chưa tăng tồn vật lý.

### AS-UC-02-02-02 — Dữ liệu bắt buộc không hợp lệ
- **Given:** phiên Quick thiếu dòng/UOM/LOT/evidence hoặc có duplicate Product+UOM.
- **When:** người dùng cố gửi.
- **Then:** command bị từ chối toàn bộ, không tạo receipt và không trả mã `DRAFT_*`; dữ liệu chỉ còn trong phiên hiện tại.

### AS-UC-02-02-03 — Thiếu approver
- **Given:** payload BJ02 đã hợp lệ nhưng không resolve được eligible approver theo policy Quick Receipt.
- **When:** người dùng gửi Quick Receipt.
- **Then:** hệ thống trả `APPROVER_CONFIGURATION_MISSING`; không tạo receipt. Việc chưa có price/FX basis không làm command bị từ chối ở UC này.

### AS-UC-02-02-04 — Rời phiên trước khi gửi
- **Given:** người dùng đã nhập một phần dữ liệu Quick Receipt nhưng chưa gửi thành công.
- **When:** người dùng rời Quick flow, refresh hoặc đóng app.
- **Then:** dữ liệu Quick Receipt chưa gửi không còn; server và thiết bị không có bản nháp để khôi phục.

### AS-UC-02-02-05 — Mất phản hồi sau khi gửi
- **Given:** client đã gửi command với `idempotencyKey=K` nhưng không nhận được phản hồi cuối.
- **When:** client retry/query kết quả bằng cùng `K`.
- **Then:** hệ thống trả lại đúng outcome của lần đầu; nếu đã success thì cùng `receiptId`, nếu đã reject thì cùng rejection; không tạo receipt thứ hai.

## 10. Truy vết

- **Journey:** `BJ-02` — Nhận hàng mua.
- **Domain:** `DOM-IO`, `DOM-IC`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-07`.
- **Loại trừ:** `BC-IO-16`, `API-C-25` không dùng cho Quick Receipt.
- **Nguồn quyết định:** `T7-DR-027`, `T7-DR-103`, `T7-DR-118`, `T7-DR-119`.
