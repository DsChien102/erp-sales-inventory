---
id: UC-06-02
type: use-case
theme: theme-07
title: "Xử lý ngoại lệ truy vết"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v4.0.0
ui_flow: UIF-06
---

# UC-06-02 — Xử lý ngoại lệ truy vết

## 1. Mục tiêu và kết quả nghiệp vụ

Xử lý trường hợp hàng trả không truy vết thẳng được về dòng xuất/lô gốc bằng bằng chứng và quyết định ngoại lệ có thẩm quyền.

**Kết quả cần đạt:** Ngoại lệ được chấp thuận với evidence/reason rõ hoặc bị từ chối; chỉ khi được chấp thuận mới tiếp tục ghi nhận hàng trả.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Lô thực nhận không khớp lô đã xuất

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Ngoại lệ được chấp thuận hoặc từ chối có bằng chứng; Trace exception decision.

### 2.3 Không bao gồm

Không tự hợp thức hóa hàng không truy được nguồn và chưa ghi tăng tồn. UC chỉ lập/hoàn thiện hồ sơ ngoại lệ với bằng chứng đủ để bước tiếp nhận quyết định có được phép tiếp tục hay không.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Thủ kho; bộ phận trả hàng cung cấp ý định thương mại.
- **Thẩm quyền:** Được lập/cập nhật hồ sơ nháp trong phạm vi được cấp; chưa có quyền tạo tác động cuối nếu Journey còn bước phê duyệt hoặc thực thi riêng.
- **Sự kiện khởi phát:** Lô thực nhận không khớp lô đã xuất.
- **Điều kiện trước:** Nguồn/version cần dùng còn hiện hành; tác nhân có quyền lập hồ sơ trong đúng tenant/cửa hàng/kho; các master/policy bắt buộc cho việc chuẩn bị đã resolve được.

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
| BF-01 | Thủ kho | Mở dòng hàng trả cần ngoại lệ và cung cấp bằng chứng nhận diện hiện có. |  |
| BF-02 | Hệ thống | Hiển thị giao dịch/lô ứng viên và phần dữ liệu không khớp. |  |
| BF-03 | Người có quyền | Đánh giá evidence và quyết định chấp thuận ngoại lệ hoặc từ chối. | AF-A — Từ chối |
| BF-04 | Hệ thống | Nếu chấp thuận, lưu reason/evidence và liên kết truy vết ngoại lệ; không tự thay đổi source sale. | EF-A — Quyết định stale/chưa xác định |
| BF-05 | Hệ thống | Đưa dòng đủ điều kiện sang UC-06-03. |  |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Từ chối ngoại lệ
**Phát sinh tại:** BF-03. **Điều kiện:** Bằng chứng không đủ hoặc hàng không thuộc phạm vi được phép nhận .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Người có quyền | Ghi lý do từ chối. | |
| AF-A-02 | — | [Kết thúc UC; không tăng tồn.] | |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Quyết định stale hoặc chưa xác định
**Phát sinh tại:** BF-04. **Điều kiện:** Nguồn/return cap thay đổi hoặc không rõ quyết định đã commit .

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Không tiếp tục nhận hàng cho đến khi refresh/verify cùng identity. | |
| EF-A-02 | — | [Kết thúc/hand-off recovery.] | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Trần trả | Actual quantity phải nằm trong authorized quantity hiện hành của đúng ReturnExchangeLine và cumulative cap vẫn current; approval không override hard guard| Decision / DOM-IO / BC nguồn |
| BR-02 | Combo | Chỉ thành phần thực nhận tăng tồn; không tạo tồn combo; các dòng trong cùng yêu cầu nhận trả commit hoặc rollback cùng nhau| Decision / DOM-IO / BC nguồn |
| BR-03 | Lô | Sai LOT luôn maker–checker theo từng line. Reason Phase 1 là `RETURNED_DIFFERENT_LOT` (default khi mismatch) hoặc `OTHER` + mô tả. Source LOT missing/history conflict/source stale là blocker/reconciliation, không tạo approval. Actual LOT phải resolve/complete attributes trước submit. ApprovalCase `LINE_EXCEPTION` bind request/source, line, Product/UOM, quantity, source/actual LOT + LOT attributes, reason và evidence ID/version/content hash qua immutable subject snapshot/hash; field thuộc subject đổi làm case cũ `SUPERSEDED`| Decision / DOM-IO / BC nguồn |
| BR-04 | Mốc ghi giá trị | Ghi value movement cùng lúc nhận vật lý vào RETURN_PENDING; phân loại không ghi giá trị lần hai| Decision / DOM-IO / BC nguồn |
| BR-05 | Căn cứ giá | Dùng giá đã đối soát của sản phẩm và kỳ xuất gốc; nếu kỳ gốc chưa đối soát thì dùng snapshot tại lần xuất và giữ liên kết để điều chỉnh theo policy| Decision / DOM-IO / BC nguồn |
| BR-06 | Approval | reject chỉ từ chối line exception hiện tại, không terminal toàn operation; một operation có thể có nhiều line cases song song| Decision / DOM-IO / BC nguồn |

- `SBC-COM-01` — Bao yêu cầu và định danh.
- `BC-COMMON-EXTENSIONS` — Shared behavioral contract extensions.
- `SBC-COM-02` — Quyền, phạm vi và điều kiện cần.
- `SBC-COM-03` — Kết quả và hướng phục hồi.
- `SBC-COM-04` — Finality và tính nguyên tử.
- `BC-IO-07` — Receive customer return.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Ngoại lệ được chấp thuận với evidence/reason rõ hoặc bị từ chối; chỉ khi được chấp thuận mới tiếp tục ghi nhận hàng trả. | Hồ sơ chỉ được bàn giao sang bước duyệt/thực thi khi các điều kiện của UC đã đạt; chưa ghi ledger trước commit point. |
| Không đủ điều kiện / Bị từ chối | Nếu dữ liệu, nguồn hoặc version chưa đủ điều kiện, hồ sơ không được đưa qua commit point; dữ liệu hợp lệ đã nhập được giữ theo contract để sửa/refresh khi an toàn. | Sửa dữ liệu, refresh nguồn hoặc bàn giao owner/recovery theo đúng AF/EF tương ứng; không sửa trực tiếp dữ liệu có thẩm quyền. |
| Chưa xác định (`UNKNOWN`) | Không coi mất phản hồi là thất bại. Giữ cùng command/operation identity và không tạo effect thứ hai. | Đối soát/recovery theo cùng identity trước mọi lần tiếp tục. |

**Ảnh hưởng nghiệp vụ chính:** Ngoại lệ được chấp thuận với evidence/reason rõ hoặc bị từ chối; chỉ khi được chấp thuận mới tiếp tục ghi nhận hàng trả.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-06 — Tiếp nhận và phân loại hàng khách trả](../../../03.design/flows/UIF-06-BJ-06.md)


| Screen | Vai trò trong UC |
|---|---|
| `SCR-031` | Thu thập và rà soát dữ liệu cần để “Xử lý ngoại lệ truy vết”; việc ghi effect chỉ xảy ra tại commit point do UC/BC quy định. |
| `SCR-032` | Thu thập và rà soát dữ liệu cần để “Xử lý ngoại lệ truy vết”; việc ghi effect chỉ xảy ra tại commit point do UC/BC quy định. |
| `SCR-034` | Thu thập và rà soát dữ liệu cần để “Xử lý ngoại lệ truy vết”; việc ghi effect chỉ xảy ra tại commit point do UC/BC quy định. |

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-06-02-01 — Xử lý ngoại lệ truy vết — luồng chính
- **Given:** Lô thực nhận không khớp lô đã xuất
- **When:** Mở dòng hàng trả cần ngoại lệ và cung cấp bằng chứng nhận diện hiện có.
- **Then:** Ngoại lệ được chấp thuận với evidence/reason rõ hoặc bị từ chối; chỉ khi được chấp thuận mới tiếp tục ghi nhận hàng trả.

### AS-UC-06-02-02 — Xử lý ngoại lệ truy vết — Từ chối ngoại lệ
- **Given:** Bằng chứng không đủ hoặc hàng không thuộc phạm vi được phép nhận.
- **When:** Ghi lý do từ chối.
- **Then:** UC kết thúc với kết quả của nhánh này; không tiếp tục luồng chính và không tạo thêm effect ngoài kết quả đã nêu.

### AS-UC-06-02-03 — Xử lý ngoại lệ truy vết — Quyết định stale hoặc chưa xác định
- **Given:** Nguồn/return cap thay đổi hoặc không rõ quyết định đã commit.
- **When:** Hệ thống phát hiện điều kiện “Quyết định stale hoặc chưa xác định” tại BF-04.
- **Then:** Không tiếp tục nhận hàng cho đến khi refresh/verify cùng identity. Giữ nguyên identity/evidence hiện có và bàn giao recovery/finality; không tạo effect trùng hoặc thử lại mù.

## 10. Truy vết

- **Journey:** `BJ-06` — Tiếp nhận và phân loại hàng khách trả.
- **Domain:** `DOM-IO`.
- **Behavioral Contract:** `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-07`.

- **Nguồn quyết định:** [Nhóm G06 — Trả hàng, hết hạn và loại bỏ](../../../01.knowledge/decisions/decision-register.md#36-g06-tr%E1%BA%A3-h%C3%A0ng-tr%E1%BA%A1ng-th%C3%A1i-h%E1%BA%BFt-h%E1%BA%A1n-v%C3%A0-ti%C3%AAu-h%E1%BB%A7y)
- **Bài tri thức liên quan:** [Hàng khách trả: từ tiếp nhận đến phân loại](../../../01.knowledge/know-how/KB-KGV-012-hang-khach-tra-tu-tiep-nhan-den-phan-loai.md); [Danh tính và vòng đời của một lô hàng](../../../01.knowledge/know-how/KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md); [Combo bán hàng và tồn kho theo thành phần](../../../01.knowledge/know-how/KB-KGV-035-combo-ban-hang-va-ton-kho-theo-thanh-phan.md); [Định giá hàng trả, tiêu hủy và chênh lệch thừa thiếu](../../../01.knowledge/know-how/KB-KGV-020-dinh-gia-hang-tra-tieu-huy-va-chenh-lech-thua-thieu.md)
