---
id: UC-13-01
type: use-case
theme: theme-07
title: "Ghi nhận điều chỉnh giá trị hàng nhập"
owner: BA
status: IN_REVIEW
aligned_to: UC.template.md
source_baseline: v4.6.0
ui_flow: UIF-13
---

# UC-13-01 — Ghi nhận điều chỉnh giá trị hàng nhập

## 1. Mục tiêu và kết quả nghiệp vụ

Kế toán ghi nhận một **business fact mới hoặc thay đổi hợp lệ xuất hiện sau initial valuation** làm tăng hoặc giảm giá trị hàng nhập, phân bổ nó về đúng phạm vi kinh tế và đúng kỳ mà không sửa ReceiptValuation/value movement gốc.

Kết quả thành công là một điều chỉnh có nguồn, có dấu, có cách phân bổ và period mapping rõ ràng; các Product + posting period bị ảnh hưởng được đánh dấu cần cập nhật giá vốn.

## 2. Bối cảnh và ranh giới

### 2.1 Bắt đầu khi

Có thành phần giá trị mới hoặc phiên bản nghiệp vụ mới đã đủ căn cứ sau khi các target liên quan đã hoàn tất BJ03, ví dụ chi phí vận chuyển, bảo hiểm, thuế/phí không thu hồi, chênh lệch giá hóa đơn, giảm giá, chiết khấu hoặc credit note.

### 2.2 Kết thúc và thời điểm ghi nhận kết quả

Kết thúc khi adjustment được commit đúng một lần; hoặc yêu cầu bị giữ/chặn vì nguồn, target, allocation hay posting period chưa hợp lệ; hoặc mutation ở `UNKNOWN` và được bàn giao BJ17.

### 2.3 Không bao gồm

- Thành phần đã đủ căn cứ trước initial valuation: thuộc BJ03.
- Quyền lợi thương mại chỉ mới dự kiến: chỉ dùng mô phỏng, không ghi value ledger.
- Sửa lỗi người dùng nhập sai business fact đã biết: thuộc BJ11/correction.
- Công bố giá vốn: thuộc BJ14.

## 3. Tác nhân, thẩm quyền và điều kiện trước

- **Tác nhân chính:** Kế toán mua hàng hoặc kế toán kho có quyền tài chính.
- **Thẩm quyền:** Xác nhận nguồn và cách phân bổ trong policy; không sửa nguồn do Theme 10/Theme khác sở hữu.
- **Sự kiện khởi phát:** Một nguồn hợp lệ tạo chênh lệch so với giá trị nhập đã ghi.
- **Điều kiện trước:** Target đã initial-valued; source có stable economic identity; amount/tax/FX đủ xác định; posting route tồn tại; không trùng adjustment đã ghi.

## 4. Đối tượng và dữ liệu nghiệp vụ

| Đối tượng / Dữ liệu | Ý nghĩa và yêu cầu | Nguồn |
|---|---|---|
| Nguồn điều chỉnh | Business fact có thể dương hoặc âm, có source identity/version và bằng chứng | Theme 10, kế toán hoặc nguồn có thẩm quyền |
| Phạm vi mục tiêu | Phiếu nhận hàng valuation exposure mà nguồn thực sự liên quan | `DOM-IV`, `ENT-IV-01` |
| Cách phân bổ | Theo policy cho phép, ví dụ quantity, value hoặc số tiền trực tiếp; metric phải có snapshot ổn định | `BC-IV-06` |
| Giá trị điều chỉnh | Signed amount sau tax/FX normalization; tổng allocation phải khớp nguồn | `ENT-IV-07/08` |
| Kỳ gốc / kỳ ghi nhận | Giữ lineage về kỳ hàng nhập; nếu kỳ gốc khóa thì ghi ở kỳ mở theo policy | `T7-DR-163`, `T7-DR-192` |
| Dirty scope | Exact Product + posting period chịu ảnh hưởng | `T7-DR-195` |

## 5. Các luồng của Use Case

### 5.1 Luồng chính (Basic Flow)

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| BF-01 | Kế toán | Mở nguồn điều chỉnh đã đủ căn cứ và cần ghi vào giá trị hàng nhập. | |
| BF-02 | Hệ thống | Xác minh source identity/version, route, target scope, các valuation exposure và period mapping; chuẩn hóa amount/tax/FX. | AF-A — Một nguồn áp dụng nhiều target<br>EF-A — Target chưa initial-valued<br>EF-B — Nguồn chỉ là dự kiến |
| BF-03 | Kế toán | Chọn hoặc rà soát cách phân bổ trong tập policy cho phép; không tự mở rộng target ngoài nguồn. | AF-B — Source/policy yêu cầu judgment về subset |
| BF-04 | Hệ thống | Tính allocation theo metric snapshot và làm tròn xác định; trả signed delta theo từng exposure/posting period để rà soát. | BR-01 — Dấu của adjustment<br>BR-02 — Phân bổ bất biến |
| BF-05 | Kế toán | Rà soát tổng nguồn, target, allocation và period rồi xác nhận ghi nhận. | EF-C — Nguồn hoặc allocation stale |
| BF-06 | Hệ thống | Commit source adjustment, allocations, valuation adjustment batch/lines và value movements; đánh dấu exact Product + posting period dirty trong cùng transaction. | BC-IV-04 — Ghi điều chỉnh giá trị<br>EF-D — Kết quả mutation chưa xác định |
| BF-07 | — | [Kết thúc UC]. | |

### 5.2 Luồng thay thế (Alternate Flow)

#### AF-A — Một nguồn áp dụng nhiều target

**Phát sinh tại:** BF-02. **Điều kiện:** một hóa đơn/chi phí/credit note liên quan nhiều phiếu nhận hàng valuation exposure.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-A-01 | Hệ thống | Dựng authoritative target set và metric snapshot cho toàn bộ exposure liên quan. | T7-DR-158…160 |
| AF-A-02 | — | [Trở lại BF-03]. | BF-03 — Rà soát cách phân bổ |

#### AF-B — Source/policy cho phép judgment về subset

**Phát sinh tại:** BF-03. **Điều kiện:** nguồn hoặc policy nêu rõ target cần quyết định bằng judgment, không phải fixed scope.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| AF-B-01 | Kế toán | Chọn target trong candidate set được nguồn cho phép và ghi bằng chứng/lý do nếu policy yêu cầu. | T7-DR-158 — Authoritative target scope |
| AF-B-02 | Hệ thống | Hash/audit selected scope; không nhận target ngoài source lineage. | |
| AF-B-03 | — | [Trở lại BF-04]. | BF-04 — Tính allocation |

### 5.3 Luồng ngoại lệ (Exception Flow)

#### EF-A — Target chưa initial-valued
**Phát sinh tại:** BF-02. **Điều kiện:** có target thuộc source scope vẫn `VALUATION_PENDING`.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-A-01 | Hệ thống | Chưa ghi adjustment; nêu rõ target phải hoàn tất BJ03 trước. | T7-DR-191 — Ranh giới BJ03/BJ13 |
| EF-A-02 | — | [Kết thúc UC]. | |

#### EF-B — Nguồn chỉ là dự kiến
**Phát sinh tại:** BF-02. **Điều kiện:** chiết khấu/quyền lợi thương mại chưa phát sinh hoặc chưa đủ bằng chứng.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-B-01 | Hệ thống | Loại nguồn khỏi đường ghi value ledger; chỉ cho phép consumer mô phỏng nếu contract hỗ trợ. | T7-DR-193 — Quyền lợi dự kiến |
| EF-B-02 | — | [Kết thúc UC]. | |

#### EF-C — Nguồn hoặc allocation stale
**Phát sinh tại:** BF-05. **Điều kiện:** revision, target, metric, period mapping hoặc allocation hash đã đổi.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-C-01 | Hệ thống | Từ chối toàn command trước mutation và yêu cầu dựng lại preview. | T7-DR-161 — Freshness |
| EF-C-02 | — | [Trở lại BF-02]. | BF-02 — Xác minh nguồn hiện hành |

#### EF-D — Kết quả mutation chưa xác định
**Phát sinh tại:** BF-06. **Điều kiện:** không chứng minh được commit/no-commit.

| Step ID | Tác nhân | Hành động | Ghi chú và tham chiếu |
|---|---|---|---|
| EF-D-01 | Hệ thống | Trả `UNKNOWN`, giữ nguyên identity của adjustment command và không ghi lại bằng command mới. | SBC-COM-03 — Kết quả và phục hồi |
| EF-D-02 | — | [Tiếp tục tại BJ-17]. | BJ-17 — Phục hồi nghiệp vụ có kết quả chưa xác định |

## 6. Quy tắc nghiệp vụ và Behavioral Contract

| Mã | Tên quy tắc nội bộ | Nội dung | Căn cứ |
|---|---|---|---|
| BR-01 | Adjustment có thể dương hoặc âm | BJ13 không chỉ là “chi phí đến muộn”; mọi component hợp lệ làm tăng/giảm giá trị sau BJ03 đều dùng cùng contract.| T7-DR-192 |
| BR-02 | Allocation không phụ thuộc thứ tự thao tác | Metric snapshot, stable exposure order và rounding policy phải cho cùng kết quả dù UI/source row được sắp lại.| T7-DR-159/160 |
| BR-03 | Không rewrite lịch sử | Adjustment mới liên kết initial valuation; không sửa ReceiptValuation/value movement gốc.| T7-DR-191/192 |
| BR-04 | Sai nhập liệu không phải adjustment đến sau | Nếu người dùng ghi sai fact đã biết, xử lý correction ở BJ11.| T7-DR-191 |
| BR-05 | Chỉ fact đã xác lập được ghi thật | Forecast/estimated commercial benefit không tạo adjustment.| T7-DR-193 |

- `BC-IV-06` — Dựng preview điều chỉnh giá trị hàng nhập.
- `BC-IV-04` — Ghi điều chỉnh giá trị hàng nhập.
- `SBC-COM-02/03/04` — Quyền, finality và phục hồi.

## 7. Kết quả và điều kiện sau

| Trường hợp | Trạng thái / Ảnh hưởng nghiệp vụ | Hướng tiếp tục |
|---|---|---|
| Thành công | Signed adjustment được ghi đúng một lần; nguồn, target, allocation và kỳ có provenance; dirty scope Product + posting period được tạo | BJ14 cập nhật giá vốn |
| Target chưa valued / nguồn chưa đủ | Không value movement mới | Hoàn tất BJ03 hoặc chờ nguồn trở thành fact thật |
| Stale/conflict | Không partial commit | Refresh preview và rà soát lại |
| Lỗi nhập liệu cũ | Không dùng BJ13 để che lỗi | BJ11/correction |
| `UNKNOWN` | Không kết luận commit/no-commit | BJ17 |

### 7.1 Làm rõ v4.6.0 — công thức phân bổ

Với normalized signed source amount `A`, target `i` có metric `m_i`, `M = Σm_i`:

`allocation_i = A × m_i / M` khi `M > 0`.

- Theo giá trị: `m_i` là giá trị nhập ban đầu của exposure trước mọi adjustment BJ13.
- Theo lượng: chỉ được dùng khi source/policy cung cấp metric quantity có cùng dimension/metric-unit trên toàn scope; không lấy trực tiếp các quantity khác UOM để cộng chung.
- Làm tròn VND theo stable exposure order; exposure cuối nhận residual để tổng phân bổ đúng bằng `A`.
- `M <= 0` hoặc metric không so sánh được => method không hợp lệ, không fallback chia đều.
- Bước rà soát vẫn bắt buộc về hành vi nhưng v4.6.0 dùng Confirmation Sheet ngay trên `SCR-086`; không cần `SCR-088` là screen riêng.

## 8. Liên hệ giao diện

**UI Flow canonical:** [UIF-13 — Điều chỉnh giá trị hàng nhập](../../../03.design/flows/UIF-13-BJ-13.md)

| Screen | Vai trò trong UC |
|---|---|
| `SCR-085` | Danh sách công việc điều chỉnh giá trị hàng nhập, bao gồm cả khoản tăng và giảm. |
| `SCR-086` | Nguồn, phạm vi áp dụng, cách phân bổ và kết quả dự kiến trên cùng một công việc. |
| `SCR-088` | Rà soát chỉ đọc trước khi ghi điều chỉnh tăng/giảm. |
| `SCR-089` | Kết quả có hiệu lực và phạm vi cần BJ14 cập nhật giá vốn. |

`SCR-087` đã retire từ v3.13.0; không tạo màn trung gian chỉ để chuyển từ chọn phạm vi sang xem kết quả phân bổ.

## 9. Kịch bản nghiệm thu (Acceptance Scenarios)

### AS-UC-13-01-01 — Chi phí vận chuyển đến sau
- **Bao phủ:** BF-01 → BF-07; AF-A; BR-01 → BR-03.
- **Given:** phí vận chuyển có nguồn hợp lệ xuất hiện sau khi các phiếu nhận hàng target đã initial-valued.
- **When:** kế toán xác nhận allocation.
- **Then:** adjustment dương được ghi đúng phạm vi và Product + posting period được đánh dấu cần cập nhật giá vốn.

### AS-UC-13-01-02 — Chiết khấu/credit note đến sau
- **Bao phủ:** BF-01 → BF-07; BR-01/03/05.
- **Given:** Theme 10 xác lập quyền lợi thương mại thực tế làm giảm giá trị hàng nhập.
- **When:** kế toán ghi nhận điều chỉnh.
- **Then:** signed adjustment âm được ghi, không sửa initial valuation và không thay đổi quantity.

### AS-UC-13-01-03 — Quyền lợi chỉ mới dự kiến
- **Bao phủ:** EF-B; BR-05.
- **Given:** Theme 10 chỉ cung cấp forecast chiết khấu theo kỳ, chưa phát sinh quyền lợi.
- **When:** nguồn được đưa vào BJ13.
- **Then:** hệ thống không ghi value ledger; dữ liệu chỉ có thể phục vụ mô phỏng.

### AS-UC-13-01-04 — Người dùng phát hiện đã gõ sai initial value
- **Bao phủ:** BR-04.
- **Given:** BJ03 đã commit 1.000.000 nhưng fact đúng lúc đó là 100.000 do nhập nhầm.
- **When:** người dùng yêu cầu sửa.
- **Then:** không tạo “late cost” để bù; hồ sơ được chuyển theo correction/BJ11.

### AS-UC-13-01-05 — Kỳ gốc đã khóa
- **Bao phủ:** BF-02 → BF-06.
- **Given:** adjustment liên quan phiếu nhận hàng thuộc kỳ đã khóa nhưng policy cho phép ghi ở kỳ mở kế tiếp.
- **When:** kế toán xác nhận.
- **Then:** posting period là kỳ mở theo policy, original period vẫn được giữ trong lineage.

## 10. Truy vết

- **Journey:** `BJ-13` — Điều chỉnh giá trị hàng nhập.
- **Domain / Entity:** `DOM-IV`, `ENT-IV-01/02/05/06/07/08`.
- **Behavioral Contract:** `BC-IV-04`, `BC-IV-06`, `SBC-COM-02/03/04`.
- **Decision:** `T7-DR-191…193`, `T7-DR-157…163`.
- **Bài tri thức liên quan:** [KB-KGV-015 — Đơn giá tồn kho chính thức và tổng giá trị ghi sổ](../../../01.knowledge/know-how/KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md); [KB-KGV-018 — Đối soát giá vốn cuối kỳ và cập nhật đột xuất giữa kỳ](../../../01.knowledge/know-how/KB-KGV-018-doi-soat-gia-von-cuoi-ky-va-cap-nhat-dot-xuat-giua-ky.md); [KB-KGV-019 — Các thành phần hình thành giá trị hàng nhập](../../../01.knowledge/know-how/KB-KGV-019-cac-thanh-phan-hinh-thanh-gia-tri-hang-nhap.md); [KB-KGV-043 — Kịch bản chiết khấu mua hàng theo kỳ](../../../01.knowledge/know-how/KB-KGV-043-kich-ban-chiet-khau-mua-hang-theo-ky.md)
