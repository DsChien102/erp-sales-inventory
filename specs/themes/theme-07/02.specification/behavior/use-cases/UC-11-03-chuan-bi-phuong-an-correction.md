---
id: UC-11-03
type: use-case
theme: theme-07
title: "Chuẩn bị phương án correction"
owner: BA
status: FROZEN
frozen_at: v5.27.0
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-11
---

# UC-11-03 — Chuẩn bị phương án correction

## 1. Mục tiêu và kết quả nghiệp vụ

Lập phương án correction cho transaction đã commit bằng các effect đảo/điều chỉnh có liên kết, không sửa dữ liệu lịch sử tại chỗ.

**Kết quả cần đạt:** Correction proposal có target, lý do, effect dự kiến và evidence đầy đủ để duyệt/thực thi.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Operation đã hoàn tất và có correction intent

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Phương án khả thi đủ căn cứ hoặc bị chặn; Correction proposal.

### 2.3 Không bao gồm

Không ghi reversal/correction movement ở bước chuẩn bị và không sửa transaction gốc. UC chỉ xác định phần sai, phương án đối ứng và bằng chứng để xin duyệt/thực thi.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Người vận hành kho và người duyệt sửa sai.
- **Thẩm quyền:** Được lập/cập nhật hồ sơ nháp trong phạm vi được cấp; chưa có quyền tạo tác động cuối nếu Journey còn bước phê duyệt hoặc thực thi riêng.
- **Sự kiện khởi phát:** Operation đã hoàn tất và có correction intent.
- **Điều kiện trước:** Nguồn/version cần dùng còn hiện hành; tác nhân có quyền lập hồ sơ trong đúng tenant/cửa hàng/kho; các master/policy bắt buộc cho việc chuẩn bị đã resolve được.

## 4. Đối tượng và dữ liệu nghiệp vụ

| Đối tượng / Dữ liệu | Ý nghĩa và yêu cầu | Nguồn |
|---|---|---|
| Nguồn nghiệp vụ và phiên bản | Định danh nguồn/đối tượng nghiệp vụ và phiên bản hiện hành cần dùng để tránh xử lý trên dữ liệu cũ. | DOM-IO / DOM-IC / BC liên quan |
| Dữ liệu nghiệp vụ | Các dữ kiện người dùng/nguồn cung cấp cho mục tiêu của Use Case; phải tuân theo rule ở mục 6. | DOM-IO / DOM-IC / BC liên quan |
| Phạm vi thực hiện | Tác nhân và phạm vi tenant/cửa hàng/kho mà yêu cầu được phép xử lý. | DOM-IO / DOM-IC / BC liên quan |

## 5. Các luồng của Use Case

### 5.1 Luồng chính (Basic Flow)

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| BF-01 | Người vận hành | Chọn transaction/effect đã commit cần sửa và nhập lý do. |  |
| BF-02 | Hệ thống | Nạp original operation, movement/value/state effects và correction chain hiện hữu. | EF-A — Target không còn hợp lệ |
| BF-03 | Người vận hành | Chọn phương án correction phù hợp và bổ sung evidence bắt buộc. |  |
| BF-04 | Hệ thống | Tính effect đảo/điều chỉnh dự kiến và kiểm tra không vượt original exposure/không tạo correction vòng lặp. | AF-A — Cần nhiều bước correction |
| BF-05 | Hệ thống | Lưu proposal/version và chuyển phê duyệt nếu policy yêu cầu; chưa ghi ledger. | EF-B — Kết quả lưu chưa xác định |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Cần nhiều bước correction
**Phát sinh tại:** BF-04. **Điều kiện:** Một correction đơn không thể đưa trạng thái về đúng đích mà vẫn giữ invariant .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Dựng correction plan có thứ tự và liên kết chain; hiển thị toàn bộ effect dự kiến để duyệt. | |
| AF-A-02 | — | [Tiếp tục BF-05.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Target không còn hợp lệ
**Phát sinh tại:** BF-02. **Điều kiện:** Original/correction chain đã thay đổi hoặc đã được sửa bởi operation khác .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Không tạo proposal trên snapshot cũ; yêu cầu refresh. | |
| EF-A-02 | — | [Kết thúc UC.] | |

#### EF-B — Kết quả lưu chưa xác định
**Phát sinh tại:** BF-05. **Điều kiện:** Không rõ proposal đã commit .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Verify proposal identity/version trước retry. | |
| EF-B-02 | — | [Kết thúc/hand-off recovery.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Hủy trước thực thi | Chỉ DRAFT, PENDING_APPROVAL hoặc READY được hủy; cancellation không tạo movement/value| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-02 | UNKNOWN | Không đảo hoặc thay thế khi chưa xác lập finality; phải đối soát bằng cùng operation ID| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-03 | Operation hoàn tất | Không sửa payload/result; tạo operation mới trong correction chain| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-04 | Dependency | Chặn reversal nếu làm âm tồn hoặc dependency chưa được trung hòa; không giả lập trung hòa bằng sửa số dư| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-05 | Delta hay full reversal | Dùng delta khi chỉ phần sai có thể sửa độc lập và giữ đúng nguồn; dùng reversal + replacement khi toàn operation mất hiệu lực hoặc payload đúng phải được xác lập lại nguyên khối| Decision / DOM-IO / DOM-IC / BC nguồn |
| BR-06 | Hàng thực quay về | Sale Issue đã bàn giao chỉ tăng tồn qua BJ-06; cancellation/correction không thay thế việc nhận hàng thực tế| Decision / DOM-IO / DOM-IC / BC nguồn |

- `SBC-COM-01` — Bao yêu cầu và định danh.
- `BC-COMMON-EXTENSIONS` — Shared behavioral contract extensions.
- `SBC-COM-02` — Quyền, phạm vi và điều kiện cần.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `SBC-COM-04` — Finality và tính nguyên tử.
- `BC-IO-16` — Maintain operation draft.
- `BC-IC-07` — Submit inventory operation.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Correction proposal có target, lý do, effect dự kiến và evidence đầy đủ để duyệt/thực thi. | Hồ sơ chỉ được bàn giao sang bước duyệt/thực thi khi các điều kiện của UC đã đạt; chưa ghi ledger trước commit point. |
| Không đủ điều kiện / Bị từ chối | Nếu dữ liệu, nguồn hoặc version chưa đủ điều kiện, hồ sơ không được đưa qua commit point; dữ liệu hợp lệ đã nhập được giữ theo contract để sửa/refresh khi an toàn. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** Correction proposal có target, lý do, effect dự kiến và evidence đầy đủ để duyệt/thực thi.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-11 — Hủy và sửa sai nghiệp vụ kho](../../../03.design/flows/UIF-11-BJ-11.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-049` | Thu thập và rà soát dữ liệu cần để “Chuẩn bị phương án correction”; việc ghi effect chỉ xảy ra tại commit point do UC/BC quy định. |
| `SCR-050` | Thu thập và rà soát dữ liệu cần để “Chuẩn bị phương án correction” (chọn cách sửa và số đúng); việc ghi effect chỉ xảy ra tại commit point do UC/BC quy định. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-11-03-01 — Chuẩn bị phương án correction — luồng chính
- **Given:** Operation đã hoàn tất và có correction intent
- **When:** Chọn transaction/effect đã commit cần sửa và nhập lý do.
- **Then:** Correction proposal có target, lý do, effect dự kiến và evidence đầy đủ để duyệt/thực thi.

### AS-UC-11-03-02 — Chuẩn bị phương án correction — Cần nhiều bước correction
- **Given:** Một correction đơn không thể đưa trạng thái về đúng đích mà vẫn giữ invariant.
- **When:** Hệ thống phát hiện điều kiện “Cần nhiều bước correction” tại BF-04.
- **Then:** Dựng correction plan có thứ tự và liên kết chain; hiển thị toàn bộ effect dự kiến để duyệt. Luồng chính tiếp tục tại BF-05: Lưu proposal/version và chuyển phê duyệt nếu policy yêu cầu; chưa ghi ledger.

### AS-UC-11-03-03 — Chuẩn bị phương án correction — Target không còn hợp lệ
- **Given:** Original/correction chain đã thay đổi hoặc đã được sửa bởi operation khác.
- **When:** Hệ thống phát hiện điều kiện “Target không còn hợp lệ” tại BF-02.
- **Then:** Không tạo proposal trên snapshot cũ; yêu cầu refresh. UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-11-03-04 — Chuẩn bị phương án correction — Kết quả lưu chưa xác định
- **Given:** Không rõ proposal đã commit.
- **When:** Hệ thống phát hiện điều kiện “Kết quả lưu chưa xác định” tại BF-05.
- **Then:** Verify proposal identity/version trước retry. Giữ nguyên identity/evidence hiện có và bàn giao recovery/finality; không tạo effect trùng hoặc thử lại mù.

## 10. Truy vết

- **Journey:** `BJ-11` — Hủy và sửa sai nghiệp vụ kho.
- **Domain:** `DOM-IO`, `DOM-IC`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-16`, `BC-IC-07`.

- **Nguồn quyết định:** [Nhóm G08 — Sửa sai, reversal và kỳ khóa](../../../01.knowledge/decisions/decision-register.md#38-g08-s%E1%BB%ADa-sai-v%C3%A0-ho%C3%A0n-nguy%C3%AAn); [Nhóm G10 — Inventory Operation, idempotency và sự kiện](../../../01.knowledge/decisions/decision-register.md#310-g10-inventory-operation-t%C3%ADch-h%E1%BB%A3p-ch%E1%BB%91ng-tr%C3%B9ng-v%C3%A0-k%E1%BA%BFt-qu%E1%BA%A3-ch%C6%B0a-x%C3%A1c-%C4%91%E1%BB%8Bnh)
- **Bài tri thức liên quan:** [Sửa sai tồn kho mà không sửa lịch sử](../../../01.knowledge/know-how/KB-KGV-021-sua-sai-ton-kho-khong-sua-lich-su.md); [Vòng đời của một Inventory Operation](../../../01.knowledge/know-how/KB-KGV-027-vong-doi-cua-mot-inventory-operation.md); [Idempotency, phiên bản nguồn và xử lý kết quả chưa xác định](../../../01.knowledge/know-how/KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md)
