---
id: UC-14-01
type: use-case
theme: theme-07
title: "Tính và rà soát giá vốn"
owner: BA
status: FROZEN
frozen_at: v5.27.0
aligned_to: UC.template.md
source_baseline: v4.6.1
ui_flow: UIF-14
---

# UC-14-01 — Tính và rà soát giá vốn

## 1. Mục tiêu và kết quả nghiệp vụ

Kế toán tạo một lần tính cho đúng kỳ/phạm vi, để hệ thống tính hai phương pháp bình quân trên cùng valuation timeline, phát hiện blocker và đưa ra kết quả theo từng Product đủ rõ để quyết định có thể công bố hay chưa.

Người dùng **không chọn phương pháp giá vốn cho từng lần tính**. Phương pháp được phép công bố đã được cấu hình ở cấp tenant; phương pháp còn lại chỉ là số đối chiếu.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

- cần cập nhật trong kỳ vì BJ03/BJ13/correction làm một Product + posting period trở thành dirty; hoặc
- đến thời điểm chốt kỳ theo policy.

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Kết thúc khi run có trạng thái `READY_FOR_REVIEW` với ProductCostResult bất biến, hoặc `BLOCKED` với blocker cụ thể. UC này không ghi COGS/value adjustment và không tạo Official Cost mới.

### 2.3 Không bao gồm

- Chọn/đổi costing method của tenant.
- Sửa nguồn valuation hoặc blocker ở journey khác.
- Công bố run; thuộc UC-14-04.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Kế toán kho/người có quyền tính giá vốn.
- **Thẩm quyền:** Chọn loại xử lý/kỳ trong phạm vi policy; không được loại tùy ý Product khỏi dirty scope do hệ thống sở hữu và không đổi tenant costing method.
- **Sự kiện khởi phát:** dirty scope hoặc nhu cầu period close.
- **Điều kiện trước:** valuation timeline có thể khóa cutoff; posting/calculation period hợp lệ; tenant costing policy có version hiệu lực.

## 4. Đối tượng và dữ liệu nghiệp vụ

| Đối tượng / Dữ liệu | Ý nghĩa và yêu cầu | Nguồn |
|---|---|---|
| Run type | `AD_HOC` cập nhật trong kỳ hoặc `PERIOD_CLOSE` | `DOM-IV` |
| Calculation / posting period | Kỳ dùng tính và kỳ ghi nhận; không đồng nhất máy móc với original period | `T7-DR-168` |
| Scope | Dirty: exact Product + posting period do hệ thống sở hữu; close: phạm vi được policy cho phép rồi khóa snapshot | `T7-DR-169`, `T7-DR-195` |
| Costing policy | Phương pháp tenant đang có hiệu lực; read-only tại BJ14 | `T7-DR-194` |
| Valuation timeline | Ordered quantity/value facts đến cutoff | `T7-DR-164` |
| ProductCostResult | Kết quả bất biến theo Product, gồm hai phương pháp, baseline, delta, blocker | `ENT-IV-09` |

## 5. Các luồng của Use Case

### 5.1 Luồng chính (Basic Flow)

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| BF-01 | Kế toán | Mở công việc cập nhật/chốt giá vốn và xác định loại xử lý, kỳ cần thực hiện. | AF-A — Cập nhật trong kỳ từ dirty scope<br>AF-B — Chốt kỳ |
| BF-02 | Hệ thống | Dựng và khóa scope/cutoff, đọc tenant costing policy có hiệu lực và snapshot valuation facts. | BR-01 — Phương pháp cấp tenant<br>EF-A — Scope/policy stale |
| BF-03 | Hệ thống | Kiểm tra blocker theo từng Product trước và trong tính toán. | EF-B — Có blocker |
| BF-04 | Hệ thống | Tính bình quân gia quyền liên hoàn và bình quân gia quyền cuối kỳ trên cùng fact set; đánh dấu phương pháp tenant là kết quả nguồn để công bố, phương pháp còn lại là đối chiếu. | BR-02 — Tính song song |
| BF-05 | Hệ thống | Materialize `ProductCostResult[]`, baseline và incremental delta; run chuyển `READY_FOR_REVIEW`. | BC-IV-02 — Tính giá vốn |
| BF-06 | Kế toán | Rà soát kết quả, blocker đã xử lý, chênh lệch và phương pháp áp dụng theo policy. | |
| BF-07 | — | [Tiếp tục tại UC-14-04]. | UC-14-04 — Công bố giá vốn |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Cập nhật trong kỳ từ dirty scope
**Phát sinh tại:** BF-01. **Điều kiện:** có Product + posting period dirty do BJ03/BJ13/correction.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Nạp exact dirty scope cùng cause/version/hash; không cho người dùng bỏ tùy ý Product. | T7-DR-195 — Dirty scope authoritative |
| AF-A-02 | — | [Trở lại BF-02]. | BF-02 — Khóa scope/cutoff |

#### AF-B — Chốt kỳ
**Phát sinh tại:** BF-01. **Điều kiện:** đến kỳ cần chốt giá vốn.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-B-01 | Kế toán | Chọn phạm vi chốt trong đúng tập lựa chọn tenant policy trả về; nếu có nhiều lựa chọn thì phải chọn rõ, không dùng default do UI tự đặt. | T7-DR-195 — Period-close scope |
| AF-B-02 | Hệ thống | Khóa immutable scope snapshot và cutoff cho run. | |
| AF-B-03 | — | [Trở lại BF-03]. | BF-03 — Kiểm tra blocker |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Scope hoặc policy stale
**Phát sinh tại:** BF-02. **Điều kiện:** dirty cause/scope hoặc policy version đã đổi khi tạo run.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Không dùng snapshot cũ; yêu cầu dựng run mới từ dữ liệu hiện hành. | T7-DR-169 — Dirty scope versioned |
| EF-A-02 | — | [Kết thúc UC]. | |

#### EF-B — Có blocker
**Phát sinh tại:** BF-03. **Điều kiện:** còn `VALUATION_PENDING`, `UNKNOWN`, correction/reconciliation chưa hoàn tất hoặc fact bất hợp lệ làm sai kết quả Product/kỳ.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Materialize run `BLOCKED`, nêu blocker theo Product + owner xử lý; không ghi adjustment/Official Cost. | T7-DR-065 — Close blocker |
| EF-B-02 | — | [Kết thúc UC]. | |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Costing method là policy tenant | BJ14 chỉ đọc method/version có hiệu lực; không radio/dropdown để đổi theo run.| T7-DR-194 |
| BR-02 | Tính song song trên cùng dữ liệu | Cả hai phương pháp dùng cùng ordered fact set/cutoff; phương pháp không được chọn chỉ để đối chiếu.| T7-DR-049, T7-DR-164, T7-DR-194 |
| BR-03 | Run bất biến | Started run không sửa/cancel/reuse; dữ liệu đổi thì tạo successor run.| T7-DR-193 (legacy run finality), T7-DR-169 |
| BR-04 | Dirty scope không phải lựa chọn người dùng | Exact Product + posting period và causes được hệ thống sở hữu.| T7-DR-195 |

- `BC-IV-02` — Tính giá vốn.
- `SBC-COM-02/03/04` — quyền, finality và phục hồi.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| `READY_FOR_REVIEW` | Có immutable ProductCostResult, method áp dụng theo tenant và số đối chiếu; chưa ledger mutation | UC-14-04 |
| `BLOCKED` | Không publication/adjustment; blocker có Product/owner rõ | Xử lý ở journey nguồn rồi tạo successor run |
| Stale trước tạo run | Không dùng dữ liệu cũ | Dựng lại scope/run |

### 7.1 Làm rõ v4.6.0 — policy và phạm vi

- Costing method lấy từ tenant policy snapshot; UI chỉ hiển thị method hiện hành, không hard-code hoặc cho chọn lại theo run.
- Dirty/ad-hoc run luôn dùng exact dirty scope do hệ thống sở hữu.
- Period-close chỉ hiển thị scope option tenant policy cho phép. Nếu policy trả nhiều option thì user phải chọn rõ; nếu chỉ một option thì UI hiển thị read-only. Tên/ID scope trong prototype chỉ là fixture, không phải catalog nghiệp vụ canonical.
- Khi run được tạo, method + scope + policy version được khóa trong input snapshot.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-14 — Tính và công bố giá vốn](../../../03.design/flows/UIF-14-BJ-14.md)

| Screen | Vai trò trong UC |
|---|---|
| `SCR-072` | Danh sách công việc cần xử lý: cập nhật trong kỳ, chốt kỳ hoặc việc đang bị chặn. |
| `SCR-074` | Thiết lập cần thiết, quá trình tính, vấn đề chặn và kết quả rà soát là các trạng thái của cùng một bề mặt. |

`SCR-073` và `SCR-075` đã retire. Phương pháp tính giá vốn luôn lấy từ chính sách tenant; phạm vi cần tính lại là chỉ đọc và người dùng không thể tùy ý bỏ sản phẩm khỏi phạm vi.

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-14-01-01 — Dirty update lấy scope từ hệ thống
- **Bao phủ:** AF-A; BF-02 → BF-06; BR-01/04.
- **Given:** BJ13 tạo dirty scope gồm Product A và B trong kỳ 09/2026.
- **When:** kế toán tạo cập nhật trong kỳ.
- **Then:** A và B đều thuộc immutable scope; UI không cho bỏ B tùy ý và method lấy từ tenant policy.

### AS-UC-14-01-02 — Tenant dùng bình quân cuối kỳ
- **Bao phủ:** BF-04; BR-01/02.
- **Given:** policy tenant chọn bình quân gia quyền cuối kỳ.
- **When:** hệ thống tính run.
- **Then:** cả hai phương pháp được tính; bình quân cuối kỳ là nguồn để công bố, bình quân liên hoàn chỉ là đối chiếu và không có control đổi method.

### AS-UC-14-01-03 — Run bị chặn bởi hàng chưa xác lập giá trị
- **Bao phủ:** EF-B.
- **Given:** Product A còn quantity `VALUATION_PENDING` trong phạm vi có thể làm sai kết quả kỳ.
- **When:** run kiểm tra blocker.
- **Then:** run ở `BLOCKED`, nêu BJ03 là owner xử lý và không ghi ledger/Official Cost.

### AS-UC-14-01-04 — Period close scope được khóa
- **Bao phủ:** AF-B.
- **Given:** kế toán có quyền chốt kỳ và chọn phạm vi hợp lệ theo policy.
- **When:** run được tạo.
- **Then:** scope snapshot/cutoff bất biến; dữ liệu đổi sau đó không được silently nhập vào run cũ.

## 10. Truy vết

- **Journey:** `BJ-14` — Tính và công bố giá vốn.
- **Domain / Entity:** `DOM-IV`, `ENT-IV-03`, `ENT-IV-09`.
- **Behavioral Contract:** `BC-IV-02`.
- **Decision:** `T7-DR-049`, `T7-DR-164…170`, `T7-DR-194/195`, `T7-DR-202`.
- **Bài tri thức liên quan:** [KB-KGV-015 — Đơn giá tồn kho chính thức và tổng giá trị ghi sổ](../../../01.knowledge/know-how/KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md); [KB-KGV-016 — Vì sao sử dụng song song hai phương pháp tính giá vốn?](../../../01.knowledge/know-how/KB-KGV-016-vi-sao-tinh-song-song-hai-phuong-phap-gia-von.md); [KB-KGV-018 — Đối soát giá vốn cuối kỳ và cập nhật đột xuất giữa kỳ](../../../01.knowledge/know-how/KB-KGV-018-doi-soat-gia-von-cuoi-ky-va-cap-nhat-dot-xuat-giua-ky.md); [KB-KGV-045 — Rà soát giá vốn tham chiếu định giá sau chốt kỳ](../../../01.knowledge/know-how/KB-KGV-045-ra-soat-gia-von-tham-chieu-sau-chot-ky.md)
