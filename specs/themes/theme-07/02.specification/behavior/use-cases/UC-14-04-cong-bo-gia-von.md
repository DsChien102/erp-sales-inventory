---
id: UC-14-04
type: use-case
theme: theme-07
title: "Công bố giá vốn"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v4.1.0
ui_flow: UIF-14
---

# UC-14-04 — Công bố giá vốn

## 1. Mục tiêu và kết quả nghiệp vụ

Kế toán công bố một run đã sẵn sàng, để hệ thống ghi **chỉ phần chênh lệch cần thiết** cho giá vốn hàng đã xuất và giá trị tồn cuối, đồng thời tạo/cập nhật `OfficialCostVersion` theo phương pháp đã cấu hình ở tenant.

Công bố không sửa receipt, issue, sale order, value movement gốc hoặc giả lập rằng cost version mới đã tồn tại trong quá khứ.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

`CostCalculationRun` ở `READY_FOR_REVIEW`, ProductCostResult và input snapshot còn current, không còn blocker.

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Kết thúc khi publication batch commit nguyên tử và run chuyển `PUBLISHED`; hoặc bị từ chối/stale trước mutation; hoặc kết quả mutation `UNKNOWN` được bàn giao BJ17.

### 2.3 Không bao gồm

- Tính lại run trong chính UC này; nếu input thay đổi phải tạo successor run qua UC-14-01.
- Chọn costing method khác tenant policy.
- Thay đổi giá bán hoặc chứng từ bán/mua nguồn.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Kế toán/người có quyền công bố giá vốn.
- **Thẩm quyền:** Được công bố kết quả đã tính; không cần lớp phê duyệt thứ hai theo Phase 1.
- **Sự kiện khởi phát:** Kế toán hoàn tất rà soát run ready.
- **Điều kiện trước:** run/result hashes, scope/cause versions, policy version và baseline còn current; posting period cho phép ghi; effective time không backdate trái policy.

## 4. Đối tượng và dữ liệu nghiệp vụ

| Đối tượng / Dữ liệu | Ý nghĩa và yêu cầu | Nguồn |
|---|---|---|
| Ready run | Immutable run cần công bố | `ENT-IV-03` |
| ProductCostResult | Target cumulative COGS/carrying value và proposed Official Cost theo từng Product | `ENT-IV-09` |
| Authoritative baseline | Giá trị/COGS đã ghi tới cùng cutoff | `DOM-IV` |
| Incremental delta | Chỉ phần còn thiếu/thừa cần reconcile | `T7-DR-166` |
| Official Cost policy | Method tenant + effective-time policy | `T7-DR-194/167` |
| Dirty causes | Causes đã được run reconcile và chỉ được clear khi publication thành công | `T7-DR-195` |

## 5. Các luồng của Use Case

### 5.1 Luồng chính (Basic Flow)

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| BF-01 | Kế toán | Mở run `READY_FOR_REVIEW`, xem method áp dụng theo tenant, delta và ProductCostResult cần công bố. | |
| BF-02 | Hệ thống | Recheck blocker, run/result hash, baseline, scope/cause version, policy và posting period. | EF-A — Run stale hoặc blocker mới |
| BF-03 | Kế toán | Xác nhận công bố kết quả đã rà soát. | BR-01 — Không chọn lại method |
| BF-04 | Hệ thống | Tính lại incremental delta trên authoritative baseline, tạo các adjustment cần thiết và `OfficialCostVersion` hợp lệ; clear đúng dirty causes; mark run `PUBLISHED` trong một transaction. | BC-IV-03 — Công bố giá vốn<br>EF-B — Effective time/policy không hợp lệ<br>EF-C — Kết quả mutation chưa xác định |
| BF-05 | Hệ thống | Trả kết quả publication theo Product và các phiên bản giá vốn thực sự được tạo. | |
| BF-06 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Product không có basis mới để tạo Official Cost
**Phát sinh tại:** BF-04. **Điều kiện:** ProductCostResult hợp lệ nhưng policy/edge case trả `NO_NEW_COST_BASIS`.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Không tạo cost version mới cho Product đó; vẫn chỉ ghi delta nào thực sự hợp lệ và đã được run tính. | T7-DR-170 — Weighted-average edge case |
| AF-A-02 | — | [Trở lại BF-05]. | BF-05 — Trả kết quả publication |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Run stale hoặc blocker mới
**Phát sinh tại:** BF-02. **Điều kiện:** source/cause/baseline đã đổi hoặc xuất hiện blocker sau calculation.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Từ chối publication, không ghi partial adjustment và yêu cầu tạo successor run. | T7-DR-169 — Dirty scope / successor |
| EF-A-02 | — | [Tiếp tục tại UC-14-01]. | UC-14-01 — Tính và rà soát giá vốn |

#### EF-B — Effective time/policy không hợp lệ
**Phát sinh tại:** BF-04. **Điều kiện:** requested effective time backdate trước publication commit hoặc tạo interval overlap.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Từ chối trước mutation; không sửa cost version lịch sử. | T7-DR-167 — Official Cost không backdate |
| EF-B-02 | — | [Kết thúc UC]. | |

#### EF-C — Kết quả mutation chưa xác định
**Phát sinh tại:** BF-04. **Điều kiện:** không chứng minh được publication transaction đã commit hay rollback.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-C-01 | Hệ thống | Trả `UNKNOWN`, giữ nguyên publication identity; không công bố lại bằng command mới. | SBC-COM-03 — Kết quả và phục hồi |
| EF-C-02 | — | [Tiếp tục tại BJ-17]. | BJ-17 — Phục hồi nghiệp vụ có kết quả chưa xác định |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Method không phải quyết định của run | Publication bắt buộc dùng method/version tenant đã khóa trong run.| T7-DR-194 |
| BR-02 | Chỉ ghi incremental delta | Không re-post toàn lịch sử; rerun cùng fact/baseline phải delta 0.| T7-DR-166 |
| BR-03 | Không rewrite giao dịch gốc | Receipt, issue, sale và movement gốc bất biến; chênh lệch đi adjustment liên kết.| T7-DR-052/059 |
| BR-04 | Official Cost chỉ sinh tại BJ14 | Không nhận bootstrap từ BJ03.| T7-DR-185/195 |

- `BC-IV-03` — Công bố valuation và Official Cost.
- `SBC-COM-03/04` — Finality, UNKNOWN và atomicity.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Run `PUBLISHED`; adjustment/value movements và Official Cost versions hợp lệ được commit; exact dirty causes được clear | Giao dịch sau dùng cost version có hiệu lực |
| Stale/blocker | Không publication mutation | UC-14-01 tạo successor run sau khi nguồn được xử lý |
| Effective-time invalid | Không sửa lịch sử cost version | Sửa yêu cầu/policy hợp lệ |
| `UNKNOWN` | Chưa thể kết luận publication đã commit | BJ17 |

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-14 — Tính và công bố giá vốn](../../../03.design/flows/UIF-14-BJ-14.md)

| Screen | Vai trò trong UC |
|---|---|
| `SCR-074` | Rà soát và xác nhận công bố ngay trên kết quả đã kiểm tra; có thể dùng Bottom Sheet xác nhận, không cần màn riêng. |
| `SCR-077` | Kết quả công bố có hiệu lực. |

`SCR-076` đã retire từ v3.13.0. UI không cho chọn lại phương pháp tính giá vốn và không coi kết quả xem trước là kết quả đã công bố.

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-14-04-01 — Công bố theo method tenant
- **Bao phủ:** BF-01 → BF-06; BR-01/04.
- **Given:** run ready và tenant policy chọn bình quân cuối kỳ.
- **When:** kế toán công bố.
- **Then:** Official Cost được tạo từ kết quả bình quân cuối kỳ; số bình quân liên hoàn không được dùng làm nguồn publication.

### AS-UC-14-04-02 — Rerun chỉ ghi phần chênh lệch
- **Bao phủ:** BF-04; BR-02/03.
- **Given:** authoritative baseline đã có một phần COGS/value adjustment từ publication trước.
- **When:** successor run được công bố.
- **Then:** chỉ incremental delta còn lại được ghi; giao dịch gốc và adjustment cũ không bị sửa/re-post.

### AS-UC-14-04-03 — Cause mới xuất hiện trước publication
- **Bao phủ:** EF-A.
- **Given:** run đã ready nhưng BJ13 tạo thêm adjustment cùng Product/kỳ trước lúc publish.
- **When:** kế toán công bố run cũ.
- **Then:** publication bị từ chối là stale; dirty cause mới không bị clear và phải tạo successor run.

### AS-UC-14-04-04 — Publication timeout
- **Bao phủ:** EF-C.
- **Given:** publication command đã gửi nhưng client mất kết nối trước khi nhận kết quả.
- **When:** người dùng mở lại.
- **Then:** hệ thống không giả định FAILED và không cho tạo publication mới; dùng cùng identity để đối soát qua BJ17.

## 10. Truy vết

- **Journey:** `BJ-14` — Tính và công bố giá vốn.
- **Domain / Entity:** `DOM-IV`, `ENT-IV-02/03/04/05/06/09`.
- **Behavioral Contract:** `BC-IV-03`.
- **Decision:** `T7-DR-052`, `T7-DR-164…170`, `T7-DR-194/195`.
- **Bài tri thức liên quan:** [KB-KGV-015 — Đơn giá tồn kho chính thức và tổng giá trị ghi sổ](../../../01.knowledge/know-how/KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md); [KB-KGV-017 — Công bố giá vốn chính thức và ghi nhận giá vốn hàng bán](../../../01.knowledge/know-how/KB-KGV-017-cong-bo-don-gia-ton-kho-va-ghi-nhan-gia-von-xuat-ban.md); [KB-KGV-018 — Đối soát giá vốn cuối kỳ và cập nhật đột xuất giữa kỳ](../../../01.knowledge/know-how/KB-KGV-018-doi-soat-gia-von-cuoi-ky-va-cap-nhat-dot-xuat-giua-ky.md); [KB-KGV-044 — Từ giá vốn tham chiếu định giá đến giá bán giao dịch](../../../01.knowledge/know-how/KB-KGV-044-tu-gia-von-tham-chieu-den-gia-ban-giao-dich.md); [KB-KGV-045 — Rà soát giá vốn tham chiếu định giá sau chốt kỳ](../../../01.knowledge/know-how/KB-KGV-045-ra-soat-gia-von-tham-chieu-sau-chot-ky.md)
