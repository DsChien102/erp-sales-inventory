# T7 — Thiết kế giá vốn hàng tồn kho (spec)

> Theme 7 · spec dùng chung cho G5-0b (Task 2b), G5-3, G5-4, G5-5, G5-6, G5-7 của [PLAN.md](../../PLAN.md) mục "Theme 7"
> Trạng thái: Spec 📝 chờ người dùng review | Thiết kế duyệt trong chat 2026-11-09 (3 phần)
> Nguồn nghiệp vụ: spec Theme 7 v5.27.0 — [BJ-14](../../../../specs/themes/theme-07/02.specification/behavior/journeys/BJ-14-tinh-va-cong-bo-gia-von.md), KB-KGV-015 (đơn giá chính thức, tổng giá trị từ sổ), KB-KGV-016 (hai phương pháp bình quân), KB-KGV-017 (công bố + điều chỉnh liên kết), KB-KGV-018 (mốc chốt, điều kiện chặn, cập nhật giữa kỳ). Chuẩn mực: VAS 02 Hàng tồn kho; Thông tư 200 / 133 (chọn một phương pháp, áp dụng nhất quán).

## 1. Mục tiêu

Giá vốn là phần trọng tâm của Kho trong báo cáo đồ án. Hội đồng phải thấy **nghiệp vụ kế toán đúng chuẩn**: giá gốc hàng nhập theo VAS 02, hai phương pháp bình quân gia quyền tính song song trên cùng một sổ, cửa hàng chọn một phương pháp làm chính thức, chốt kỳ ghi **điều chỉnh liên kết** mà không sửa giao dịch gốc; mọi con số chứng minh được bằng công thức, ví dụ số và test.

**Đã chốt (người dùng, 2026-11-09):**

| # | Quyết định |
|---|---|
| GV-1 | Trọng tâm: nghiệp vụ kế toán đúng chuẩn (không ưu tiên kỹ thuật hiệu năng, không ưu tiên nhiều màn) |
| GV-2 | **Cửa hàng chọn phương pháp** (bình quân liên hoàn `MOVING` / bình quân cuối kỳ `PERIODIC`); lần tính luôn tính cả hai để đối chiếu; có chốt kỳ theo tháng + true-up |
| GV-3 | **Giá gốc trên phiếu nhận:** chi phí thu mua + chiết khấu thương mại cấp phiếu, phân bổ vào dòng; không điều chỉnh sau khi đã ghi (BJ-13 vẫn bỏ) |
| GV-4 | **Cách A:** tính lại từ sổ lúc tạo lần tính (kết quả bất biến), rà soát, công bố nguyên tử |

**Ngoài phạm vi:** điều chỉnh giá trị hàng nhập sau khi ghi (BJ-13), đổi phương pháp sau lần công bố đầu, giá vốn theo kho / lô, FIFO / đích danh, giá vốn tham chiếu cho định giá bán, bút toán kế toán (TK 156 / 632) — chỉ ghi tên loại để báo cáo đối chiếu.

## 2. Khái niệm

| Khái niệm | Nghĩa trong app |
|---|---|
| Giá gốc (giá nhập) | Giá mua trước thuế GTGT + chi phí thu mua phân bổ − chiết khấu thương mại phân bổ (VAS 02). Thuế GTGT được khấu trừ, không vào giá gốc |
| Sổ số lượng | `inventory.stock_movements` (G5-0b): mỗi dòng một biến động số lượng theo lô |
| Sổ giá trị | `inventory.value_movements`: mỗi dòng một biến động giá trị; dòng điều chỉnh chỉ có giá trị, không có số lượng |
| Giá trị sổ | Σ `amount_vnd` của sổ giá trị cho sản phẩm (có thẩm quyền, KB-KGV-015) |
| Bình quân liên hoàn | Tính lại sau mỗi lần nhập: `(giá trị còn + giá trị nhập) / (SL còn + SL nhập)` |
| Bình quân cuối kỳ | Tính một lần cho đoạn: `(giá trị đầu đoạn + giá trị nhập) / (SL đầu đoạn + SL nhập)` |
| Giá chính thức | Phiên bản giá (`cost_versions`) được công bố, có hiệu lực từ một mốc |
| Giá tạm | Sản phẩm chưa có giá chính thức, phương pháp `PERIODIC` ⇒ xuất tạm theo bình quân liên hoàn |
| Mốc chốt (cut-off) | Số `ledger_sequence` lớn nhất lúc tạo lần tính |
| Đoạn | Các dòng sổ có `ledger_sequence` trong `(mốc của lần công bố trước, mốc mới]` |
| Lần tính (cost run) | Kết quả tính một đoạn cho mọi sản phẩm có biến động; bất biến sau khi tạo |
| Điều chỉnh (true-up) | Dòng sổ giá trị ghi phần chênh giữa giá đã ghi lúc xuất và giá theo phương pháp chính thức |

## 3. Dữ liệu

Schema `inventory`, mọi bảng có `tenant_id`, RLS bật, `revoke all` (chỉ qua RPC `security definer`), như quy ước G5-0b. Phạm vi giá: **tổ chức + sản phẩm** (không theo kho / lô, KB-KGV-015). Tiền: `bigint` (đồng). Đơn giá: `numeric(18,4)`.

### 3.1 `value_movements` (giữ lại, đổi dạng so với Task 2 đã commit)

| Cột | Ghi chú |
|---|---|
| `id`, `ledger_sequence` | dùng chung bộ đếm `ledger_counters` với sổ số lượng |
| `product_id` | |
| `movement_id uuid null` | dòng sổ số lượng tương ứng; `null` với dòng điều chỉnh |
| `kind text` | `OPENING`, `RECEIPT`, `SALE`, `SALE_REVERSAL`, `RETURN_IN`, `COUNT_GAIN`, `COUNT_LOSS`, `WRITE_OFF`, `COGS_TRUE_UP`, `LOSS_TRUE_UP`, `REVALUE_ROUNDING` |
| `quantity_basis numeric` | số lượng (ĐVT cơ sở) làm căn cứ, có dấu; `0` với dòng điều chỉnh |
| `unit_cost numeric(18,4) null` | đơn giá đã dùng; `null` với dòng điều chỉnh |
| `amount_vnd bigint not null` | có dấu (+ vào, − ra) |
| `cost_version_id uuid null` | phiên bản giá đã dùng khi xuất theo giá chính thức |
| `is_provisional boolean not null default false` | xuất theo giá tạm |
| `cost_run_id uuid null` | bắt buộc với 3 loại điều chỉnh |
| `source_movement_id uuid null` | `SALE_REVERSAL` trỏ dòng `SALE` gốc |
| `business_date`, `created_at`, `created_by` | |

Chỉ thêm (trigger `_forbid_ledger_mutation`). Check: loại điều chỉnh ⇒ `movement_id is null and cost_run_id is not null`; loại khác ⇒ `movement_id is not null`.

### 3.2 Bảng mới / đổi

| Bảng | Cột chính | Ràng buộc |
|---|---|---|
| `product_costs` | PK `(tenant_id, product_id)`; `quantity_on_hand numeric`, `ledger_value_vnd bigint` (= Σ sổ giá trị), `moving_avg_cost numeric(18,4)`, `official_version_id uuid null`, `official_unit_cost numeric(18,4) null`, `last_ledger_sequence`, `updated_at` | `quantity_on_hand >= 0`; thay `product_costs` theo `(kho, sản phẩm)` của bản G5-0b rút gọn |
| `cost_policies` | PK `tenant_id`; `method text` (`MOVING` / `PERIODIC`), `changed_at`, `changed_by` | Không có dòng = `MOVING`. Đổi chỉ khi chưa có `cost_runs` `PUBLISHED` (`COST_POLICY_LOCKED`) |
| `cost_periods` | `id`, `period_month date` (ngày 1), `status` (`OPEN` / `CLOSED`), `closed_at`, `closed_by`, `closing_run_id` | `unique (tenant_id, period_month)`; kỳ mở đầu tiên tạo khi có biến động đầu tiên |
| `cost_versions` | `id`, `product_id`, `unit_cost numeric(18,4)`, `method`, `effective_from_sequence bigint`, `cost_run_id`, `created_at` | Chỉ thêm |
| `cost_runs` | `id`, `kind` (`PERIOD_CLOSE` / `MID_PERIOD`), `period_id`, `from_sequence`, `cut_off_sequence`, `method` (chụp chính sách), `status` (`READY_FOR_REVIEW` / `BLOCKED` / `STALE` / `PUBLISHED` / `SUPERSEDED`), `blockers jsonb`, `supersedes_run_id`, `based_on_run_id` (lần công bố trước), `created_by/at`, `published_by/at` | Tối đa một lần `READY_FOR_REVIEW` mỗi tenant (unique một phần) |
| `cost_run_lines` | `run_id`, `product_id`; `opening_qty`, `opening_value`; `inbound_qty`, `inbound_value`; `sale_qty`, `sale_value_recorded`; `loss_qty`, `loss_value_recorded`; `closing_qty`; `moving_avg_end`; `periodic_avg`; `selected_unit_cost`; `cogs_true_up`, `loss_true_up`, `rounding_adjust`; `closing_value_after` | Chỉ thêm; PK `(run_id, product_id)` |

Phiếu nhận (G5-3) lưu thêm cấp phiếu `freight_cost_vnd`, `trade_discount_vnd`; cấp dòng `purchase_amount_vnd`, `allocated_freight_vnd`, `allocated_discount_vnd`, `landed_amount_vnd`, `landed_unit_cost`.

Dòng đơn bán (G5-4) lưu `cogs_amount_vnd`, `cogs_unit_cost`, `cost_version_id`, `cogs_is_provisional` (đọc từ kết quả `_post_movements`).

## 4. Luật trong kỳ (lúc ghi sổ, trong `_post_movements`)

Chạy sau khoá sản phẩm, cùng giao dịch ghi sổ số lượng. Với mỗi dòng (`d` = số lượng có dấu), đọc `product_costs` (`q`, `V`, `m` = bình quân liên hoàn, `o` = giá chính thức) và chính sách `method`:

| Biến động | Đơn giá `c` | `amount_vnd` | Cập nhật |
|---|---|---|---|
| `OPENING`, `RECEIPT` (vào) | giá gốc người gọi truyền (bắt buộc, thiếu → `UNIT_COST_REQUIRED`) | `round(d × c)` | `m = (q × m + amount) / (q + d)`; `q += d`; `V += amount` |
| `COUNT_GAIN` (vào) | `o` nếu `PERIODIC` và có `o`; ngược lại `m`; `q = 0` và không có `m` → `UNIT_COST_REQUIRED` | `round(d × c)` | như trên |
| `RETURN_IN` (trả hàng của dòng `SALE` thuộc đoạn đã công bố) | đơn giá dòng `SALE` gốc | `round(d × c)` | như trên |
| `SALE`, `COUNT_LOSS`, `WRITE_OFF` (ra) | `MOVING`: `m`. `PERIODIC`: `o`; chưa có `o` → `m` và `is_provisional = true` | `round(d × c)` (âm) | `q += d`; `V += amount`; `m` không đổi |
| `SALE_REVERSAL` (huỷ / trả dòng `SALE` còn trong đoạn chưa công bố) | đơn giá dòng `SALE` gốc | `−amount` của phần đảo | `q += d`; `V += amount`; `m = V / q` khi `q > 0` |

Thêm:

- `business_date` thuộc kỳ `CLOSED` → `PERIOD_CLOSED` (khoá sổ). Kỳ của ngày chưa có dòng → tạo `OPEN`.
- `q` về 0: giữ `m` cũ; lần vào sau công thức tự ra `c`.
- `_post_movements` trả thêm, mỗi dòng: `{line_id, movement_id, value_movement_id, unit_cost, amount_vnd, cost_version_id, is_provisional}`.
- Che tiền: RPC đọc trả `null` + `financial_masked: true` cho người không `is_owner`.

### 4.1 Phân bổ giá gốc trên phiếu nhận (G5-3)

Với `n` dòng, giá mua dòng `a_i` (trước thuế, = SL × đơn giá mua), tổng `A = Σ a_i`, chi phí thu mua `F`, chiết khấu `D` (cấp phiếu, ≥ 0, `D ≤ A + F`):

- `f_i = floor(F × a_i / A)`, `k_i = floor(D × a_i / A)`; phần dư `F − Σ f_i`, `D − Σ k_i` cộng vào dòng có `a_i` lớn nhất (bằng nhau → dòng đầu).
- Giá gốc dòng `g_i = a_i + f_i − k_i`; đơn giá gốc `g_i / SL_i` (4 chữ số) truyền vào `_post_movements` kèm `amount_vnd = g_i` (không làm tròn lại từ đơn giá — dùng đúng `g_i`).
- `A = 0` (hàng tặng) mà `F > 0` → phân bổ theo số lượng. Thiếu giá mua dòng → chặn ở màn rà soát.

Ví dụ: 2 dòng `a = 600.000`, `400.000`; `F = 50.000`, `D = 20.000` ⇒ `f = 30.000 / 20.000`, `k = 12.000 / 8.000`, `g = 618.000 / 412.000`; tổng 1.030.000 = 1.000.000 + 50.000 − 20.000.

## 5. Luật lúc tính (tạo lần tính)

Đoạn: `from_sequence` = `cut_off_sequence` của lần `PUBLISHED` gần nhất (0 nếu chưa có); `cut_off_sequence` = `max(ledger_sequence)` lúc tạo. Dòng điều chỉnh của lần công bố trước có `ledger_sequence > from_sequence` nhưng **không** tính là nhập / xuất của đoạn (lọc theo `kind`); tồn đầu đoạn = `closing_qty` / `closing_value_after` của dòng run trước (sản phẩm mới: 0).

Với mỗi sản phẩm có dòng sổ giá trị trong đoạn:

| Đại lượng | Từ sổ giá trị của đoạn |
|---|---|
| `inbound_qty / value` | Σ `OPENING`, `RECEIPT`, `COUNT_GAIN`, `RETURN_IN` |
| `sale_qty / sale_value_recorded` | Σ `SALE` + `SALE_REVERSAL` (đổi dấu thành số dương) |
| `loss_qty / loss_value_recorded` | Σ `COUNT_LOSS`, `WRITE_OFF` (dương) |
| `closing_qty` | `opening_qty + inbound_qty − sale_qty − loss_qty` (phải bằng Σ `stock_movements.quantity_delta` của sản phẩm có `ledger_sequence <= cut_off_sequence`; lệch → điều kiện chặn `LEDGER_MISMATCH`, dấu hiệu sổ số lượng và sổ giá trị không khớp) |
| `moving_avg_end` | phát lại liên hoàn theo thứ tự `ledger_sequence` từ tồn đầu đoạn (luật mục 4 với `MOVING`) |
| `periodic_avg` `P` | `(opening_value + inbound_value) / (opening_qty + inbound_qty)`; mẫu 0 → `null` (không có hàng sẵn có) |
| `selected_unit_cost` `S` | `MOVING`: `moving_avg_end`; `PERIODIC`: `P` |

Điều chỉnh (chỉ khác 0 khi `PERIODIC`; `MOVING` ghi 0 vì giá ghi lúc xuất đã đúng phương pháp):

- `cogs_true_up = round(sale_qty × S) − sale_value_recorded`
- `loss_true_up = round(loss_qty × S) − loss_value_recorded`
- `closing_value_before = opening_value + inbound_value − sale_value_recorded − loss_value_recorded`
- `rounding_adjust = round(closing_qty × S) − (closing_value_before − cogs_true_up − loss_true_up)` (thường vài đồng; `MOVING` cũng có thể khác 0 do làm tròn từng dòng)
- `closing_value_after = round(closing_qty × S)`

**Bất biến cân bằng** (kiểm cho mọi dòng run, hiện trên màn rà soát):
`opening_value + inbound_value = (sale_value_recorded + cogs_true_up) + (loss_value_recorded + loss_true_up) + closing_value_after − rounding_adjust`.

### 5.1 Ví dụ (đưa vào báo cáo)

Nobivac, kho trống, kỳ đầu (chưa có giá chính thức ⇒ `PERIODIC` xuất theo giá tạm = liên hoàn):

| # | Biến động | SL còn | Giá trị sổ | Bình quân liên hoàn |
|---|---|---|---|---|
| 1 | Nhập 100 × 10.000 | 100 | 1.000.000 | 10.000 |
| 2 | Bán 30 → 300.000 | 70 | 700.000 | 10.000 |
| 3 | Nhập 50 × 13.000 = 650.000 | 120 | 1.350.000 | 11.250 |
| 4 | Bán 40 → 450.000 | 80 | 900.000 | 11.250 |

Lần tính: `inbound = 150 / 1.650.000`, `sale = 70 / 750.000`, `closing_qty = 80`, `moving_avg_end = 11.250`, `P = 11.000`.

| | `MOVING` | `PERIODIC` |
|---|---|---|
| `S` | 11.250 | 11.000 |
| `cogs_true_up` | 0 | 70 × 11.000 − 750.000 = **+20.000** |
| `rounding_adjust` | 0 | 880.000 − (900.000 − 20.000) = 0 |
| Giá vốn hàng bán sau điều chỉnh | 750.000 | 770.000 |
| `closing_value_after` | 900.000 | 880.000 |
| Kiểm cân bằng | 0 + 1.650.000 = 750.000 + 900.000 ✓ | 0 + 1.650.000 = 770.000 + 880.000 ✓ |

Dòng bán ở bước 2, 4 không đổi; `PERIODIC` có thêm một dòng `COGS_TRUE_UP +20.000` mang `cost_run_id`, và phiên bản giá 11.000 hiệu lực cho lần xuất sau mốc.

## 6. Luồng tính → rà soát → công bố

### 6.1 Hai loại lần tính

| `kind` | Điều kiện | Khi công bố |
|---|---|---|
| `PERIOD_CLOSE` | Tháng của kỳ `OPEN` sớm nhất đã kết thúc (`period_month + 1 tháng <= current_date`) | Ghi điều chỉnh, tạo phiên bản giá, kỳ → `CLOSED`, kỳ sau `OPEN` |
| `MID_PERIOD` | Bất kỳ lúc nào | Ghi điều chỉnh tới mốc, tạo phiên bản giá; kỳ vẫn `OPEN`. Dùng cho demo |

### 6.2 RPC (chỉ `is_owner`; khác → `PERMISSION_DENIED`)

| RPC | Làm gì |
|---|---|
| `inventory.get_cost_overview(p_tenant_id)` | Phương pháp + có đổi được không; danh sách sản phẩm (giá chính thức + phiên bản + hiệu lực, hoặc "giá tạm"; bình quân liên hoàn; tồn; giá trị sổ); lần tính đang chờ rà soát (nếu có); kỳ đang mở |
| `inventory.set_cost_policy(p_tenant_id, p_method, p_idempotency_key)` | `COST_POLICY_LOCKED` nếu đã có lần `PUBLISHED` |
| `inventory.create_cost_run(p_tenant_id, p_kind, p_idempotency_key)` | Kiểm điều kiện chặn (6.3) → `BLOCKED` + `blockers` (vẫn lưu run để tra), hoặc tính (mục 5) → `READY_FOR_REVIEW`. Khoá `pg_advisory_xact_lock` mức tenant cho giá vốn |
| `inventory.get_cost_run(p_tenant_id, p_run_id)` | Đầu run + dòng + tổng + kết quả kiểm cân bằng |
| `inventory.publish_cost_run(p_tenant_id, p_run_id, p_idempotency_key)` | Mục 6.4 |
| `inventory.discard_cost_run(p_tenant_id, p_run_id, p_idempotency_key)` | `READY_FOR_REVIEW` / `BLOCKED` → `SUPERSEDED` |
| `inventory.list_cost_versions(p_tenant_id, p_product_id)` | Lịch sử phiên bản giá của sản phẩm |

### 6.3 Điều kiện chặn

| Mã trong `blockers` | Khi | Câu "việc cần làm" (Screen Contract quyết chữ cuối) |
|---|---|---|
| `PREVIOUS_PERIOD_OPEN` | `PERIOD_CLOSE` mà còn kỳ `OPEN` cũ hơn kỳ định chốt | Chốt kỳ trước |
| `PERIOD_NOT_ENDED` | `PERIOD_CLOSE` khi tháng chưa hết | Dùng "Cập nhật giữa kỳ" |
| `STOCKTAKE_OPEN` | Có phiên kiểm kê chưa ghi nhận / huỷ (G5-5) | Ghi nhận hoặc huỷ phiên kiểm kê |
| `RUN_PENDING_REVIEW` | Đã có lần `READY_FOR_REVIEW` | Công bố hoặc bỏ lần tính đó |
| `LEDGER_MISMATCH` | `closing_qty` lệch sổ số lượng tại mốc (mục 5) | Báo lỗi dữ liệu (không tự sửa) |
| `NOTHING_TO_COST` | Đoạn không có dòng nào | — |

### 6.4 Công bố (một giao dịch)

1. Khoá tenant (giá vốn), rồi khoá sản phẩm của run theo `product_id` tăng dần (cùng thứ tự `_post_movements` ⇒ không khoá chéo với bán hàng).
2. Kiểm `status = READY_FOR_REVIEW` (khác → `COST_RUN_NOT_READY`); kiểm **cũ**: lần `PUBLISHED` mới nhất vẫn là `based_on_run_id` và `cost_policies.method` = `run.method` — sai → run `STALE`, trả `COST_RUN_STALE`.
3. Mỗi dòng run: ghi `COGS_TRUE_UP`, `LOSS_TRUE_UP`, `REVALUE_ROUNDING` khác 0 (số lượng 0, `cost_run_id`); tạo `cost_versions` (`unit_cost = S`, `effective_from_sequence` = sequence của dòng điều chỉnh cuối + 1); cập nhật `product_costs`: `ledger_value_vnd += Σ điều chỉnh`, `official_version_id`, `official_unit_cost = S`; nếu `PERIODIC` đặt `moving_avg_cost = ledger_value / quantity` (khi `q > 0`).
4. Biến động ghi **sau** mốc nhưng **trước** công bố: giữ nguyên (thuộc đoạn sau, được điều chỉnh ở lần tính sau) — vì vậy bán hàng trong lúc rà soát **không** làm run cũ.
5. `PERIOD_CLOSE`: kỳ → `CLOSED` (`closing_run_id`), kỳ tháng sau `OPEN`.
6. Run → `PUBLISHED`; idempotency: gửi lại cùng khoá trả kết quả lần đầu.

### 6.5 Mã lỗi mới

`PERIOD_CLOSED`, `COST_RUN_BLOCKED`, `COST_RUN_STALE`, `COST_RUN_NOT_READY`, `COST_POLICY_LOCKED`. (`UNIT_COST_REQUIRED` đã có ở G5-0b.)

## 7. Màn hình

| Màn | Plan | Nội dung |
|---|---|---|
| SCR-072 Giá vốn | G5-6 | Đầu màn "Phương pháp: …" + "Đổi" (chỉ khi chưa công bố lần nào; sheet chọn kèm một câu giải thích từng phương pháp). Danh sách sản phẩm (web bảng, iPhone thẻ): giá chính thức + phiên bản + hiệu lực / nhãn "Giá tạm", bình quân liên hoàn, tồn, giá trị sổ. Nút "Tính giá vốn". Dòng "Lần tính chờ rà soát". Mở sản phẩm → lịch sử phiên bản |
| SCR-074 Chốt kỳ / Cập nhật giá vốn | G5-6 | Chọn "Chốt kỳ tháng {MM/YYYY}" / "Cập nhật giữa kỳ". `BLOCKED`: danh sách điều kiện chặn + việc cần làm. `READY_FOR_REVIEW`: bảng so sánh theo sản phẩm (tồn đầu, nhập, xuất, liên hoàn, cuối kỳ, phương pháp dùng, điều chỉnh), dòng tổng, dòng kiểm cân bằng; "Công bố" / "Bỏ lần tính". `STALE`: banner + "Tính lại" |
| SCR-077 Kết quả công bố | G5-6 | K4: số sản phẩm, tổng điều chỉnh giá vốn hàng bán / hao hụt, phiên bản hiệu lực; "Xem giá vốn", "Xem báo cáo lãi gộp" |
| SCR-009 / 010 Phiếu nhận | G5-3 | Ô "Chi phí thu mua", "Chiết khấu thương mại" cấp phiếu; màn rà soát có bảng phân bổ (giá mua, chi phí, chiết khấu, giá gốc, đơn giá gốc) |
| SCR-003 Chi tiết tồn | G5-2 | Giá chính thức / giá tạm + bình quân liên hoàn (che với nhân viên) |
| Báo cáo lãi gộp | G5-7 | Theo sản phẩm theo kỳ: doanh thu, giá vốn lúc bán, điều chỉnh, giá vốn sau điều chỉnh, lãi gộp, tỷ lệ; dòng riêng "Hao hụt / huỷ". Theo đơn: chỉ giá vốn lúc bán (điều chỉnh không chia xuống đơn, KB-KGV-017) |

Chữ trên màn: theo Screen Contract 072 / 074 / 077 (FROZEN) phần còn đúng; chỗ thuộc phần bỏ (duyệt, xác minh, nhiều phạm vi chốt) bỏ; chữ mới (giá tạm, cập nhật giữa kỳ, kiểm cân bằng) plan G5-6 đề xuất, người dùng duyệt.

## 8. Chia plan

| Plan | Phần giá vốn |
|---|---|
| G5-0b (Task 2b, 4) | `value_movements` dạng 3.1; `product_costs` dạng 3.2 (theo tổ chức + sản phẩm); `cost_policies`, `cost_periods`, `cost_versions`; luật mục 4 trong `_post_movements`; `PERIOD_CLOSED` |
| G5-1 | `OPENING` truyền giá gốc từng dòng |
| G5-2 | SCR-003 hiện giá vốn |
| G5-3 | Phân bổ mục 4.1, `RECEIPT` |
| G5-4 | `SALE`, `SALE_REVERSAL`, `RETURN_IN`; dòng đơn lưu giá vốn |
| G5-5 | `COUNT_GAIN`, `COUNT_LOSS`, `WRITE_OFF`; phiên kiểm kê mở là điều kiện chặn |
| **G5-6 Giá vốn & chốt kỳ (mới)** | `cost_runs`, `cost_run_lines`, RPC mục 6.2, SCR-072 / 074 / 077 |
| G5-7 Báo cáo (G5-6 cũ) | SCR-055 / 056 + báo cáo lãi gộp |
| G5-8 Rà cuối (G5-7 cũ) | — |

## 9. Test chứng minh số

`supabase/tests/inventory_costing.sql` (người dùng chạy; mỗi ca so **đúng từng đồng**, sai → `raise exception 'FAIL: <ca>'`):

| # | Ca | Kỳ vọng |
|---|---|---|
| 1 | Ví dụ 5.1, `MOVING` | `cogs_true_up 0`, `closing_value_after 900.000` |
| 2 | Ví dụ 5.1, `PERIODIC` | `+20.000`, `880.000`, phiên bản 11.000; lần bán sau công bố dùng 11.000, `is_provisional = false` |
| 3 | `PERIODIC` có giá chính thức kỳ trước (10.500) | xuất trong kỳ ghi 10.500; điều chỉnh đúng theo `P` của đoạn |
| 4 | Làm tròn (`P` không chẵn, vd. 3 nhập lệch giá) | `rounding_adjust ≠ 0`, `ledger_value = round(SL × S)` |
| 5 | Phân bổ 4.1 (ví dụ 2 dòng + ca dư lẻ) | `Σ g_i = A + F − D` |
| 6 | Huỷ đơn cùng đoạn; trả hàng của đoạn đã công bố | `SALE_REVERSAL` đảo đúng giá gốc; `RETURN_IN` vào theo giá dòng bán gốc |
| 7 | Kiểm kê thiếu + huỷ hàng, `PERIODIC` | điều chỉnh vào `LOSS_TRUE_UP`, không vào `COGS_TRUE_UP` |
| 8 | Ghi vào kỳ `CLOSED` | `PERIOD_CLOSED` |
| 9 | Công bố hai lần cùng khoá; công bố run có lần công bố khác chen vào; đổi chính sách giữa chừng | trả kết quả cũ; `COST_RUN_STALE`; `COST_POLICY_LOCKED` sau lần công bố đầu |
| 10 | `MID_PERIOD` rồi `PERIOD_CLOSE` | hai đoạn nối tiếp, không đếm trùng dòng điều chỉnh của đoạn trước |
| 11 | Bán trong lúc run chờ rà soát | công bố vẫn được; dòng bán thuộc đoạn sau |

Bất biến kiểm sau **mọi** ca: `product_costs.ledger_value_vnd = Σ value_movements.amount_vnd`; cân bằng mục 5 cho mọi dòng run; số dòng sổ cũ không đổi (không update / delete). Flutter: test hợp đồng SQL (có hàm, mã lỗi, `security definer`, khoá trước khi đọc) + widget test màn theo quy ước G5.

## 10. Cho báo cáo đồ án

Mục "Giá vốn hàng tồn kho" (làm ở phần Báo cáo): giá gốc theo VAS 02 + ví dụ phân bổ 4.1; hai công thức bình quân + ví dụ 5.1; nguyên tắc sổ chỉ thêm và điều chỉnh liên kết (KB-KGV-017); vì sao mốc chốt theo số thứ tự sổ (6.4 bước 4); sơ đồ trạng thái lần tính (`READY_FOR_REVIEW` / `BLOCKED` / `STALE` / `PUBLISHED` / `SUPERSEDED`); bảng ca test mục 9; phần spec chưa làm (BJ-13, nhiều phạm vi chốt, giá tham chiếu định giá).

## 11. Rủi ro

| Rủi ro | Xử lý |
|---|---|
| Phát lại liên hoàn lúc tính chậm khi sổ dài | Chỉ đọc đoạn từ mốc trước; dữ liệu đồ án nhỏ. Ghi trong báo cáo là điểm cần chỉ mục `(tenant_id, product_id, ledger_sequence)` |
| `_post_movements` phình vì luật giá | Tách hàm `inventory._value_line(...)` thuần (tính `c`, `amount`, cập nhật `product_costs`), `_post_movements` gọi; test riêng |
| Phương pháp đổi giữa chừng làm số khó giải thích | Chỉ đổi trước lần công bố đầu (`COST_POLICY_LOCKED`); lần tính chụp `method` |
| Kỳ theo tháng làm demo khó chốt kỳ | `MID_PERIOD` demo được ngay; `PERIOD_CLOSE` demo bằng dữ liệu tháng trước (script mô phỏng của AI-3 có thể tạo biến động có `business_date` tháng trước — quyết ở G5-6) |
| Spec làm phiên bản giá theo "đơn vị vận hành"; app một kho | Phạm vi tổ chức + sản phẩm khớp spec khi một tổ chức một đơn vị vận hành; ghi trong báo cáo |
