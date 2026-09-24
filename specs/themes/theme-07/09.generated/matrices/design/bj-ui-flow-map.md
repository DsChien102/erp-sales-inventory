# Bản đồ BJ → UC → Screen

> Baseline legacy được giữ để trace. **v1.4.3 overlay Product Entry Architecture** tại [`entry-architecture.md`](../../../06.evidence/design/legacy-contracts/entry-architecture.md): flow arrows không được hiểu là một user session xuyên actor; contextual/recovery/result surfaces không phải global entry.

| BJ | Tên | UC | Screen | Entry | Terminal |
|---|---|---:|---:|---|---|
| `BJ-01` | Theo dõi tồn, khả dụng và chỉ báo vận hành | 5 | 2 full-screen | `SCR-001` | `SCR-003` |
| `BJ-02` | Nhận hàng mua | 5 | 9 | `SCR-006` + contextual `SCR-009` + approver task `SCR-011` | `SCR-012`; `SCR-013` recovery only |
| `BJ-03` | Xác nhận giá trị ban đầu của hàng nhận | 3 | 5 | `SCR-014` + receipt-task `SCR-015` | `SCR-019` |
| `BJ-04` | Quản lý vòng đời giữ hàng | 4 | **1 active Product surface** | contextual `SCR-021` | `SCR-021` |
| `BJ-05` | Lấy hàng và bàn giao đơn | 5 | 5 | `SCR-025` | `SCR-029` |
| `BJ-06` | Tiếp nhận và phân loại hàng khách trả | 4 | 6 | maker `SCR-030`; approver task `SCR-034` | `SCR-035` |
| `BJ-07` | Thực hiện trả hàng cho nhà cung cấp | 4 | 4 | `SCR-036` + supplier-return task `SCR-037` | `SCR-041` |
| `BJ-08` | Kiểm kê và điều chỉnh chênh lệch | 5 | 6 | `SCR-042` | `SCR-047` |
| `BJ-09` | Quản lý trạng thái hàng | 4 | 5 | `SCR-036` | `SCR-041`, `SCR-056` |
| `BJ-10` | Tiêu hủy hàng | 4 | 4 | `SCR-036` | `SCR-041` |
| `BJ-11` | Hủy và sửa sai nghiệp vụ kho | 5 | 6 | maker `SCR-048` / contextual `SCR-049` / approver task `SCR-051` | `SCR-053` |
| `BJ-12` | Khởi tạo số dư tồn kho đầu kỳ | 3 | 6 | `SCR-066` | `SCR-071` |
| `BJ-13` | Ghi nhận chi phí mua đến muộn | 3 | 5 | `SCR-014` | `SCR-019` |
| `BJ-14` | Tính và công bố giá vốn | 4 | 5 active | `SCR-072` | `SCR-077` |
| `BJ-15` | Tra cứu báo cáo tồn và thẻ kho | 4 | 6 | `SCR-054` | `SCR-055`, `SCR-057`, `SCR-059` |
| `BJ-16` | Điều tra và đối soát sai lệch | 4 | 6 | `SCR-078` + contextual `SCR-079` | `SCR-083` |
| `BJ-17` | Phục hồi nghiệp vụ có kết quả chưa xác định | 4 | 5 | `SCR-078` + UNKNOWN context `SCR-079` | `SCR-083` |

## BJ-01 — Theo dõi tồn, khả dụng và chỉ báo vận hành

[`SCR-001`](../../../03.design/screens/SCR-001.md) → [`SCR-003`](../../../03.design/screens/SCR-003.md); LOT detail (`SCR-004`) và provenance (`SCR-005`) là contextual Bottom Sheets trong `SCR-003`; deep trace handoff BJ-15.

## BJ-02 — Nhận hàng mua

**Maker session:** [`SCR-006`](../../../03.design/screens/SCR-006.md) → **Document:** [`SCR-007`](../../../03.design/screens/SCR-007.md) → [`SCR-009`](../../../03.design/screens/SCR-009.md); **Quick:** [`SCR-008`](../../../03.design/screens/SCR-008.md) → [`SCR-009`](../../../03.design/screens/SCR-009.md); tại `SCR-009`, mỗi dòng hàng mở [`SCR-084`](../../../03.design/screens/SCR-084.md) rồi quay lại overview → [`SCR-010`](../../../03.design/screens/SCR-010.md).

- Nếu không cần duyệt: `SCR-010 → SCR-012`.
- Nếu cần duyệt: maker `Gửi phê duyệt` và **dừng tại trạng thái chờ**; không tự chuyển session sang approver.
- **Approver entry riêng:** assigned task/deep link → [`SCR-011`](../../../03.design/screens/SCR-011.md) → decision → system auto-execution → [`SCR-012`](../../../03.design/screens/SCR-012.md).
- `SCR-013` chỉ mở từ `SCR-012` khi UNKNOWN; không phải menu/terminal bình thường.
- Khi Purchase document đã biết từ parent context, có thể deep-link trực tiếp vào `SCR-009` ở document mode, bỏ bước chọn cách/chọn document.

## BJ-03 — Xác nhận giá trị ban đầu của hàng nhận

`Inventory Valuation` vào **Hàng chờ xác nhận giá nhập** tại [`SCR-014`](../../../03.design/screens/SCR-014.md) → [`SCR-015`](../../../03.design/screens/SCR-015.md) → [`SCR-017`](../../../03.design/screens/SCR-017.md) → [`SCR-019`](../../../03.design/screens/SCR-019.md) · provenance/conflict mở contextual sheet. Assigned valuation task/receipt context có thể deep-link vào `SCR-015`.

BJ02 chỉ tạo `VALUATION_PENDING`; warehouse user **không tự bị điều hướng sang BJ03**. Ownership chuyển sang Inventory Valuation.

## BJ-04 — Quản lý vòng đời giữ hàng

**Active Product UI:** `Order detail → Tình trạng giữ hàng →` [`SCR-021`](../../../03.design/screens/SCR-021.md) `→ back to Order detail`.

`SCR-020/022/023/024` là historical/migration contracts, đã retired khỏi active UIF04 từ v1.3.4; không được dùng làm flow steps hoặc navigation entry.

## BJ-05 — Lấy hàng và bàn giao đơn

[`SCR-025`](../../../03.design/screens/SCR-025.md) → [`SCR-026`](../../../03.design/screens/SCR-026.md) → [`SCR-027`](../../../03.design/screens/SCR-027.md) → [`SCR-028`](../../../03.design/screens/SCR-028.md) → [`SCR-029`](../../../03.design/screens/SCR-029.md)

## BJ-06 — Tiếp nhận và phân loại hàng khách trả

**Maker session:** [`SCR-030`](../../../03.design/screens/SCR-030.md) → [`SCR-031`](../../../03.design/screens/SCR-031.md) ⇄ [`SCR-032`](../../../03.design/screens/SCR-032.md). Wrong-LOT case được gửi duyệt làm maker task chuyển `Đang chờ`; maker không đi sang SCR-034.

**Approver session:** assigned wrong-LOT task → [`SCR-034`](../../../03.design/screens/SCR-034.md) → decision → maker task tự cập nhật.

Sau receipt commit: [`SCR-035`](../../../03.design/screens/SCR-035.md) mode **Đã nhận hàng trả / còn bước phân loại** → [`SCR-033`](../../../03.design/screens/SCR-033.md) → [`SCR-035`](../../../03.design/screens/SCR-035.md) mode **Kết quả phân loại cuối**.

## BJ-07 — Thực hiện trả hàng cho nhà cung cấp

[`SCR-036`](../../../03.design/screens/SCR-036.md) → [`SCR-037`](../../../03.design/screens/SCR-037.md) → [`SCR-039`](../../../03.design/screens/SCR-039.md) → [`SCR-041`](../../../03.design/screens/SCR-041.md).

Queue/task context phải nói rõ request do **Mua hàng/source** chuyển sang Kho. Purchase-authorized deep link có thể mở thẳng `SCR-037`. Nếu mismatch/source change, warehouse chờ source amendment; source version mới re-entry cùng `SCR-037`, không tạo flow sửa commercial data trong Kho.

## BJ-08 — Kiểm kê và điều chỉnh chênh lệch

[`SCR-042`](../../../03.design/screens/SCR-042.md) → [`SCR-043`](../../../03.design/screens/SCR-043.md) → [`SCR-044`](../../../03.design/screens/SCR-044.md) → [`SCR-045`](../../../03.design/screens/SCR-045.md) → [`SCR-046`](../../../03.design/screens/SCR-046.md) → [`SCR-047`](../../../03.design/screens/SCR-047.md)

## BJ-09 — Quản lý trạng thái hàng

[`SCR-036`](../../../03.design/screens/SCR-036.md) → [`SCR-037`](../../../03.design/screens/SCR-037.md) → [`SCR-038`](../../../03.design/screens/SCR-038.md) → [`SCR-041`](../../../03.design/screens/SCR-041.md) → [`SCR-056`](../../../03.design/screens/SCR-056.md)

## BJ-10 — Tiêu hủy hàng

[`SCR-036`](../../../03.design/screens/SCR-036.md) → [`SCR-037`](../../../03.design/screens/SCR-037.md) → [`SCR-040`](../../../03.design/screens/SCR-040.md) → [`SCR-041`](../../../03.design/screens/SCR-041.md)

## BJ-11 — Hủy và sửa sai nghiệp vụ kho

**Maker:** [`SCR-048`](../../../03.design/screens/SCR-048.md) → [`SCR-049`](../../../03.design/screens/SCR-049.md) → [`SCR-052`](../../../03.design/screens/SCR-052.md). Nếu cancelable: `SCR-052 → SCR-053`. Nếu operation đã hoàn tất và correction khả thi: `SCR-052 →` [`SCR-050`](../../../03.design/screens/SCR-050.md) `→ SCR-053:PENDING_APPROVAL`; maker task kết thúc ở trạng thái chờ.

**Approver entry riêng:** assigned task/deep link → [`SCR-051`](../../../03.design/screens/SCR-051.md) → decision → system recheck + correction execution → [`SCR-053`](../../../03.design/screens/SCR-053.md). Maker không bị điều hướng sang approver. `UNKNOWN` từ detail/result handoff BJ-17 với cùng operation identity.

## BJ-12 — Khởi tạo số dư tồn kho đầu kỳ

[`SCR-066`](../../../03.design/screens/SCR-066.md) → [`SCR-067`](../../../03.design/screens/SCR-067.md) → [`SCR-068`](../../../03.design/screens/SCR-068.md) → [`SCR-069`](../../../03.design/screens/SCR-069.md) → [`SCR-070`](../../../03.design/screens/SCR-070.md) → [`SCR-071`](../../../03.design/screens/SCR-071.md)

## BJ-13 — Ghi nhận chi phí mua đến muộn

[`SCR-085`](../../../03.design/screens/SCR-085.md) → [`SCR-086`](../../../03.design/screens/SCR-086.md) → [`SCR-087`](../../../03.design/screens/SCR-087.md) → [`SCR-088`](../../../03.design/screens/SCR-088.md) → [`SCR-089`](../../../03.design/screens/SCR-089.md)

## BJ-14 — Tính và công bố giá vốn

[`SCR-072`](../../../03.design/screens/SCR-072.md) → [`SCR-073`](../../../03.design/screens/SCR-073.md) → [`SCR-074`](../../../03.design/screens/SCR-074.md) → [`SCR-076`](../../../03.design/screens/SCR-076.md) → [`SCR-077`](../../../03.design/screens/SCR-077.md) · SCR-075 retired; blocker là state của SCR-074

## BJ-15 — Tra cứu báo cáo tồn và thẻ kho

[`SCR-054`](../../../03.design/screens/SCR-054.md) → [`SCR-055`](../../../03.design/screens/SCR-055.md) → [`SCR-056`](../../../03.design/screens/SCR-056.md) → [`SCR-057`](../../../03.design/screens/SCR-057.md) → [`SCR-058`](../../../03.design/screens/SCR-058.md) → [`SCR-059`](../../../03.design/screens/SCR-059.md)

## BJ-16 — Điều tra và đối soát sai lệch

[`SCR-078`](../../../03.design/screens/SCR-078.md) → [`SCR-079`](../../../03.design/screens/SCR-079.md). Từ evidence, route theo nguyên nhân: source owner / BJ-11 / BJ-17 / ledger-integrity escalation; **chỉ khi sổ kho đã được chứng minh đúng và dữ liệu dẫn xuất sai** mới đi [`SCR-080`](../../../03.design/screens/SCR-080.md) → [`SCR-081`](../../../03.design/screens/SCR-081.md) → [`SCR-082`](../../../03.design/screens/SCR-082.md) → [`SCR-083`](../../../03.design/screens/SCR-083.md). Không có sai lệch thực có thể đi `SCR-079 → SCR-082 → SCR-083`.

## BJ-17 — Phục hồi nghiệp vụ có kết quả chưa xác định

[`SCR-078`](../../../03.design/screens/SCR-078.md) → [`SCR-079`](../../../03.design/screens/SCR-079.md) → [`SCR-080`](../../../03.design/screens/SCR-080.md) → [`SCR-082`](../../../03.design/screens/SCR-082.md) → [`SCR-083`](../../../03.design/screens/SCR-083.md). Evidence đã commit chỉ xác lập finality từ tác động đã có; evidence no-commit chỉ được tiếp tục **cùng operation/request identity và cùng content**; thiếu evidence đi thẳng result escalated và giữ scope protection. Không blind retry/new operation.

## Supporting capability CAP-01

[`SCR-062`](../../../03.design/screens/SCR-062.md) → [`SCR-063`](../../../03.design/screens/SCR-063.md) → [`SCR-064`](../../../03.design/screens/SCR-064.md) → [`SCR-065`](../../../03.design/screens/SCR-065.md). Entry/branching còn chờ duyệt tại `BG-006`; xem `../design-readiness/supporting-flow-CAP-01.md`.
