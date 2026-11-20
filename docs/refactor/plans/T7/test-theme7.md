# Luồng kiểm tay Theme 7 (Kho & Giá vốn) — bản tạm

> Số liệu do Claude tính tay từ spec giá vốn (`docs/refactor/plans/T7/T7-G5-gia-von-thiet-ke.md` mục 4, 5, 12). Chưa chạy app.
> Lệch số: kiểm lại spec trước khi kết luận là lỗi code. Lệch 1–2 đồng có thể do làm tròn.
> Cách ghi: tick `[x]` khi đúng. Ghi `✗` + số thực tế bên cạnh khi sai.
>
> **Đã rà tên nút / trường theo code:** tạo sản phẩm, tạo đối tác, chính sách tồn, chương trình NCC, phiếu nhận, bán hàng (tạo đơn, thanh toán, đổi/trả, huỷ), kiểm kê, ghi nhận chiết khấu, giá vốn, báo cáo.
> **Chưa chắc (đọc code nhưng chưa chạy app, ghi lại nếu app khác):** vị trí chính xác nút "Tạo sản phẩm" / "Tạo đơn bán hàng" trên màn; giá vốn / doanh thu của đơn S1 ở tab "Theo đơn" (có thể đã trừ phần trả hàng); cách app chặn bán vượt tồn (báo ngay khi nhập số hay khi thanh toán).
> **Ngày:** các mốc HSD tính theo hôm nay = 16/11/2026 (xem đầu Phần 2).

---

## PHẦN 0 — Chuẩn bị

### 0.1 Môi trường

- [x] DB Dev đã dựng từ migration mới nhất (plan G5-7 ghi "Dev cần reset `--linked`"; bạn tự chạy).
- [x] Đăng nhập bằng **chủ cửa hàng** (is_owner). Nhân viên không thấy giá vốn.
- [x] Cửa hàng đã có **cặp cửa hàng–kho mặc định**.
- [x] Kho **chưa có hàng nào** (không seed).

### 0.2 Dữ liệu tạo trước

Tạo tay trong app, **6 bản ghi**: 2 sản phẩm, 3 nhà cung cấp, 1 khách hàng. **Không** tạo tồn, phiếu hay đơn.
Làm đúng thứ tự: 0.2.1 sản phẩm → 0.2.2 nhà cung cấp → 0.2.3 khách hàng.

Cách đọc các bảng:
- **BẮT BUỘC** = bỏ trống thì app không cho đi tiếp / không lưu được (theo luật kiểm tra trong code).
- **Tuỳ chọn** = để trống được. Cột "Điền" ghi giá trị tôi muốn bạn nhập. Tuỳ chọn mà ghi "để trống" thì đừng nhập gì.
- Nhập số tiền **không có dấu chấm** (gõ `150000`, app tự định dạng).

---

#### 0.2.1 Sản phẩm

**Vào:** tab **Sản phẩm** → nút **Tạo sản phẩm** (nút dấu cộng ở góc, nhãn "Tạo sản phẩm"). Hiện form tạo theo từng bước, mỗi bước là một mục có thể mở ra. Bước nào cũng có nút **Tiếp** và **Bỏ qua**.

##### Sản phẩm 1: Nobivac

| Bước | Trường | Bắt buộc? | Điền |
|---|---|---|---|
| **1. Nhận diện** | Tên nội bộ | **BẮT BUỘC** (duy nhất trường này bắt buộc để lưu) | `Nobivac` |
| | Tên thương mại | Tuỳ chọn | để trống |
| | SKU | Tuỳ chọn | `T7-N` |
| | Barcode | Tuỳ chọn | để trống |
| | Công tắc **Quản lý theo lô** | Tuỳ chọn, nhưng **luồng test cần BẬT** | **BẬT** |
| | Công tắc **Bắt buộc hạn dùng** | Tuỳ chọn, nhưng **luồng test cần BẬT** (chỉ bật được sau khi bật "Quản lý theo lô") | **BẬT** |
| **2. Ảnh** | | Tuỳ chọn | bấm **Bỏ qua** |
| **3. Đơn vị cơ sở** | Đơn vị cơ sở | Tuỳ chọn ở bước này, nhưng **bắt buộc nếu muốn nhập giá bán** ở bước 5 | gõ `hộp` (nếu có gợi ý "hộp" thì chọn, không thì giữ chữ vừa gõ) |
| **4. Giá cơ sở** | Giá cơ sở | Tuỳ chọn (nếu nhập phải là số ≥ 0) | `100000` |
| **5. Khung giá bán** | Chọn cách tính (3 ô: Giá cửa hàng / Tự động riêng / Thủ công) | **BẮT BUỘC chọn một** | chọn **Thủ công** |
| | Giá niêm yết | **BẮT BUỘC** khi chọn Thủ công (thiếu → "Nhập giá niêm yết") | `150000` |
| | Giá bán sàn | Tuỳ chọn (nếu nhập phải hợp lệ, nên ≤ giá niêm yết) | `100000` |
| | Nút xác nhận bước | | bấm **Tiếp** |
| **6, 7… Nhóm trường tuỳ chỉnh** (nếu có) | | Tuỳ chọn, trừ khi cửa hàng đã đặt trường nào là bắt buộc | bấm **Bỏ qua**. Nếu app báo "Vui lòng điền đầy đủ các trường bắt buộc" thì điền trường được tô đỏ bằng giá trị bất kỳ |
| **Ghi chú** (bước cuối) | | Tuỳ chọn | bấm **Bỏ qua** |
| Cuối | | | bấm **Lưu sản phẩm** |

##### Sản phẩm 2: Thuốc tẩy giun

Làm y hệt, chỉ đổi các giá trị này:

| Trường | Điền |
|---|---|
| Tên nội bộ (**BẮT BUỘC**) | `Thuốc tẩy giun` |
| SKU | `T7-W` |
| Quản lý theo lô | **BẬT** |
| Bắt buộc hạn dùng | **BẬT** |
| Đơn vị cơ sở | `hộp` |
| Giá cơ sở | `50000` |
| Cách tính giá | **Thủ công** |
| Giá niêm yết (**BẮT BUỘC**) | `80000` |
| Giá bán sàn | `50000` |

##### Lưu ý sản phẩm
- Giá bán **Nobivac = 150.000** là số duy nhất tôi dùng để tính doanh thu / lãi gộp. Phải đúng.
- Nếu form có ô **VAT / thuế**: để **0% hoặc không thuế**.
- Nếu SKU báo "đã được sử dụng" thì đổi thành `T7-N2` / `T7-W2`.
- Nếu lưu xong app báo sản phẩm **"chưa sẵn sàng bán"**, mở checklist sẵn sàng của sản phẩm và làm theo (thường là thiếu giá hoặc đơn vị).
- Giá cơ sở không ảnh hưởng giá vốn (giá vốn chỉ lấy từ phiếu nhận ở bước 2.1, 2.2, 2.4, 2.6).

---

#### 0.2.2 Nhà cung cấp (làm 3 lần: NCC-A, NCC-B, NCC-C)

**Vào:** tab **Thêm** → **Khách hàng & NCC** → nút thêm → hộp **"Thêm KH & NCC mới"** → chọn **Tạo tổ chức**.

Form có các mục đánh số. Mục 2 và 3 phải điền; mục 4–7 bỏ qua.

| Mục | Trường | Bắt buộc? | NCC-A | NCC-B | NCC-C |
|---|---|---|---|---|---|
| **2. Vai trò giao dịch** | Chip **Khách hàng** | — | **không chọn** | **không chọn** | **không chọn** |
| | Chip **Nhà cung cấp** | **BẮT BUỘC chọn ít nhất 1 vai trò** | **chọn** (chip tô màu) | **chọn** | **chọn** |
| | Nút | | **Tiếp** | **Tiếp** | **Tiếp** |
| **3. Thông tin tổ chức** | Loại tổ chức (danh sách chọn) | Tuỳ chọn (code không kiểm) | `Công ty` | `Công ty` | `Công ty` |
| | **Tên tổ chức** | **BẮT BUỘC** (dấu `*`) | `NCC-A` | `NCC-B` | `NCC-C` |
| | Tên viết tắt | Tuỳ chọn | để trống | để trống | để trống |
| | Tên quốc tế | Tuỳ chọn | để trống | để trống | để trống |
| | **SĐT chính** | **BẮT BUỘC**: chỉ chữ số và dấu cách, **9 đến 11 chữ số** | `0281000001` | `0281000002` | `0281000003` |
| | Email | Tuỳ chọn (nếu nhập phải đúng định dạng) | để trống | để trống | để trống |
| | Nút | | **Tiếp** | **Tiếp** | **Tiếp** |
| **4. Người liên hệ chính** | | Tuỳ chọn (không bật thì không kiểm) | **Bỏ qua** | **Bỏ qua** | **Bỏ qua** |
| **5. Hóa đơn / thuế** | MST | Tuỳ chọn, để trống hợp lệ. Nếu nhập phải 10 số, 12 số hoặc dạng 10-3 số | **Bỏ qua** | **Bỏ qua** | **Bỏ qua** |
| **6. Địa chỉ giao hàng** | | Tuỳ chọn | **Bỏ qua** | **Bỏ qua** | **Bỏ qua** |
| **7. Ghi chú** | | Tuỳ chọn | để trống | để trống | để trống |
| Cuối | | | **Lưu & Xem** | **Lưu & Xem** | **Lưu & Xem** |

Lưu ý: nếu app cảnh báo trùng số điện thoại / trùng tên thì xác nhận "vẫn tạo", hoặc đổi số cuối cho khác nhau.

---

#### 0.2.3 Khách hàng: KH-Test

**Vào:** như trên → **Thêm KH & NCC mới** → chọn **Tạo cá nhân**.

| Mục | Trường | Bắt buộc? | Điền |
|---|---|---|---|
| **2. Vai trò giao dịch** | Chip **Khách hàng** | **BẮT BUỘC chọn ít nhất 1 vai trò** | **chọn** |
| | Chip **Nhà cung cấp** | — | **không chọn** |
| | Nút | | **Tiếp** |
| **3. Thông tin cá nhân** | Danh xưng | Tuỳ chọn | để trống |
| | **Họ và tên** | **BẮT BUỘC** | `KH-Test` |
| | Tên thường gọi | Tuỳ chọn | để trống |
| | **SĐT chính** | **BẮT BUỘC**, 9–11 chữ số | `0900000007` |
| | SĐT phụ | Tuỳ chọn | để trống |
| | Email | Tuỳ chọn | để trống |
| | Nút | | **Tiếp** |
| **4. Hóa đơn / thuế** | MST | Tuỳ chọn | **Bỏ qua** |
| **5. Địa chỉ giao hàng** | | Tuỳ chọn | **Bỏ qua** |
| **6. Ghi chú** | | Tuỳ chọn | để trống |
| Cuối | | | **Lưu & Xem** |

---

#### 0.2.4 Kiểm lại trước khi đi tiếp

- [ ] Danh sách sản phẩm có **Nobivac** (giá niêm yết **150.000**, đơn vị **hộp**) và **Thuốc tẩy giun** (giá niêm yết **80.000**, đơn vị **hộp**).
- [ ] Mở Nobivac: công tắc **Quản lý theo lô** đang **BẬT**. Mở Thuốc tẩy giun: cũng **BẬT**.
- [ ] Danh sách Khách hàng & NCC có **NCC-A, NCC-B, NCC-C** (nhãn Nhà cung cấp) và **KH-Test** (nhãn Khách hàng).
- [ ] Thẻ Tồn kho của Nobivac hiện **0** hoặc "chưa có hàng". Kho phải trống.

**Quy ước mọi đơn bán trong luồng:** không giảm giá, không VAT, để doanh thu khớp số bên dưới.

### 0.3 Kiểm tra ban đầu

- [ ] Mở **Kho** (`/warehouse`): hiện "Kho chưa có hàng" + nút "Lập phiếu nhận".
- [ ] Mở chi tiết sản phẩm N: thẻ **Tồn kho chỉ xem**, bấm vào mở `/warehouse/stock/<id>`.
- [ ] Không còn màn "điều chỉnh tồn" cũ trong chi tiết sản phẩm, không có bước nhập tồn khi tạo sản phẩm.
- [ ] Hub có đủ lối vào: Tồn kho & khả dụng · Nhận hàng · Kiểm kê kho · Chương trình nhà cung cấp · Giá vốn · Báo cáo tồn & thẻ kho · Lãi gộp · Nhập hàng theo NCC · Chính sách tồn & cận hạn. Bấm từng cái đều mở màn thật.

---

## PHẦN 1 — Thiết lập

### Bước 1.1. Chính sách tồn & cận hạn

**Vào:** Hub Kho → **Chính sách tồn & cận hạn**. Trên cùng có 2 tab: **Ngưỡng tồn** và **Cận hạn**. Sửa xong ở mỗi tab phải bấm **Lưu thay đổi** (tab nào lưu tab đó).

#### 1A. Tab "Ngưỡng tồn": 2 sản phẩm, mỗi sản phẩm 2 ô

Mỗi sản phẩm có 2 ô số nguyên: **Ngưỡng cảnh báo** và **Mức tồn mục tiêu**.
Luật trong code (`stock_policy_rules.dart`, `save_stock_thresholds`):
- Hai ô **phải điền cả hai** (điền một ô, bỏ trống ô kia là lỗi). Để trống cả hai = sản phẩm "Chưa có ngưỡng", không bị lỗi.
- Phải là số nguyên ≥ 0, và **Mức tồn mục tiêu ≥ Ngưỡng cảnh báo**. Vi phạm thì hiện "Mục tiêu phải lớn hơn hoặc bằng ngưỡng."
- Tồn thấp = khả dụng > 0 và **khả dụng ≤ ngưỡng** (bằng ngưỡng vẫn là thấp).

| Sản phẩm | Ngưỡng cảnh báo | Mức tồn mục tiêu |
|---|---|---|
| **Nobivac** | `80` | `200` |
| **Thuốc tẩy giun** | `5` | `30` |

Thao tác: điền 2 sản phẩm → **Lưu thay đổi (2)** → hộp "Lưu 2 thay đổi?" cho xem tác động ("Tồn thấp: x → y sản phẩm") → **Lưu chính sách** → banner "Đã lưu chính sách · Lần 1".

- [ ] Lưu được, mở lại tab Ngưỡng tồn thấy Nobivac = 80 / 200, Thuốc tẩy giun = 5 / 30.
- [ ] Thử sai: nhập ngưỡng Nobivac `80`, mục tiêu `50` → báo lỗi "Mục tiêu phải lớn hơn hoặc bằng ngưỡng." (rồi sửa lại 200).
- [ ] Thử sai: để trống một ô của Thuốc tẩy giun → báo lỗi (rồi điền lại 30).

#### 1B. Tab "Cận hạn": số ngày mặc định

Ô **Số ngày cận hạn** (mục "Mặc định cho mọi sản phẩm"), trống = hợp lệ nhưng **không đánh dấu lô cận hạn nào** ("Chưa đặt: không đánh dấu lô cận hạn."). Nếu nhập phải là số nguyên > 0, không thì "Số ngày cận hạn phải lớn hơn 0."

| Trường | Điền |
|---|---|
| Số ngày cận hạn (mặc định) | `30` |
| "Sản phẩm có chính sách riêng" | **không thêm gì** (để Nobivac và Thuốc tẩy giun dùng mặc định) |

Bấm **Lưu thay đổi**.

Luật cận hạn (`_product_stock_rows`): một lô là cận hạn khi còn tồn > 0, chưa hết hạn, và **(ngày hết hạn − hôm nay) ≤ số ngày cận hạn**. Lô hết hạn (qua hôm nay) là "Có lô hết hạn" và bị trừ khỏi khả dụng.

- [ ] Lưu được, mở lại thấy `30`.
- [ ] Chưa nhập hàng nên chưa có gì bị đánh dấu. Dấu hiệu cận hạn kiểm ở bước 2.2 (Thuốc tẩy giun).

#### 1C. Hệ quả sẽ gặp ở các bước sau (đã đối chiếu code)

| Khi | Hiện gì |
|---|---|
| Bây giờ, kho trống | Cả Nobivac và Thuốc tẩy giun đều **"Hết hàng"** (khả dụng = 0). Bình thường. |
| Bước 2.1 và 2.3: Nobivac tồn 60, 35 | Nobivac **"Tồn thấp"** (60 ≤ 80). Chi tiết Nobivac: "Ngưỡng 80 · Mục tiêu 200" và dòng "Gợi ý nhập thêm 140 (mục tiêu 200)" (= 200 − 60). Bước 5 tồn 35 thì gợi ý 165. |
| Từ bước 2.4: Nobivac tồn 135, 133, 173 | Hết "Tồn thấp" (> 80) |
| Bước 2.7: Nobivac tồn 73 | Lại **"Tồn thấp"** (73 ≤ 80). Gợi ý nhập thêm **127** (= 200 − 73) |
| Bước 2.2: Thuốc tẩy giun tồn 11 | KHÔNG tồn thấp (11 > 5). Lô HSD +20 ngày ≤ 30 ⇒ **"Có lô cận hạn"** |

"Mức tồn mục tiêu" chỉ dùng cho dòng **"Gợi ý nhập thêm"** ở chi tiết tồn kho (hiện khi sản phẩm đang bị cảnh báo và mục tiêu > khả dụng). Code không dùng nó ở chỗ nào khác (không tự đặt hàng, không ảnh hưởng giá vốn).

### Bước 1.2. Chương trình nhà cung cấp (tạo 3 chương trình)

**Vào:** Hub Kho → **Chương trình nhà cung cấp** → nút **Tạo chương trình**. Làm **3 lần**, mỗi lần một form "Tạo chương trình". Các trường chung của form:

| Trường | Bắt buộc? | Ghi chú |
|---|---|---|
| Nhà cung cấp | **Có** | bấm ô "Chọn nhà cung cấp" rồi chọn trong danh sách |
| Loại ưu đãi | **Có** | chọn 1 trong 3: "Giảm giá theo bậc số lượng", "Mua X tặng Y", "Chiết khấu đạt mốc số lượng tích luỹ" |
| Tên chương trình | **Có** (tối đa 120 ký tự) | tên bạn tự đặt, tôi đề nghị như bảng dưới |
| Sản phẩm | **Có** | bấm **Chọn sản phẩm**. "Mua X tặng Y" chỉ chọn được **một** sản phẩm |
| Tham số | tuỳ loại | xem từng chương trình |
| Ngày bắt đầu | Có (mặc định hôm nay) | **giữ nguyên hôm nay**, không đổi. Phải trong vòng 1 năm quanh hôm nay |
| Ghi chú | Không | để trống |

Bấm **Lưu** ở cuối. Hiện thông báo "Đã lưu chương trình".

#### 1.2.1 Chương trình 1: NCC-A, Nobivac, chiết khấu đạt mốc

| Trường | Điền |
|---|---|
| Nhà cung cấp | `NCC-A` |
| Loại ưu đãi | **Chiết khấu đạt mốc số lượng tích luỹ** |
| Tên chương trình | `A - Nobivac mốc 100` |
| Sản phẩm | **Nobivac** |
| Tham số: **Mốc** | `100` (đơn vị hộp) |
| Tham số: **Chiết khấu** | `5` (%) |
| Ngày bắt đầu | hôm nay (giữ mặc định) |

#### 1.2.2 Chương trình 2: NCC-B, Thuốc tẩy giun, mua 10 tặng 1

| Trường | Điền |
|---|---|
| Nhà cung cấp | `NCC-B` |
| Loại ưu đãi | **Mua X tặng Y** |
| Tên chương trình | `B - Tẩy giun mua 10 tặng 1` |
| Sản phẩm | **Thuốc tẩy giun** (chỉ chọn 1 sản phẩm) |
| Tham số: **Mua** | `10` |
| Tham số: **tặng** | `1` |
| Ngày bắt đầu | hôm nay |

#### 1.2.3 Chương trình 3: NCC-C, Nobivac, giảm giá theo bậc

| Trường | Điền |
|---|---|
| Nhà cung cấp | `NCC-C` |
| Loại ưu đãi | **Giảm giá theo bậc số lượng** |
| Tên chương trình | `C - Nobivac bậc 50 và 100` |
| Sản phẩm | **Nobivac** |
| Tham số: bấm **Thêm bậc** để có 2 hàng | Hàng 1: số lượng `50`, mức giảm `3` (%). Hàng 2: số lượng `100`, mức giảm `5` (%) |
| Ngày bắt đầu | hôm nay |

Luật bậc (code): số lượng bậc sau phải **lớn hơn** bậc trước, mức giảm bậc sau cũng phải **lớn hơn** bậc trước; mức giảm từ 0,01 đến 100%.

#### 1.2.4 Kiểm sau khi tạo

- [ ] Danh sách chương trình có 3 dòng, chip **Đang chạy**: "A - Nobivac mốc 100", "B - Tẩy giun mua 10 tặng 1", "C - Nobivac bậc 50 và 100". Dòng tóm tắt đúng kiểu "Đạt 100 hộp giảm 5% tổng tiền mua" / "Mua 10 tặng 1 hộp" / "Từ 50 hộp giảm 3% · từ 100 giảm 5%".
- [ ] **Thử chặn:** tạo chương trình thứ hai cho **NCC-A** (loại bất kỳ, sản phẩm bất kỳ). Form phải hiện cảnh báo "NCC này đang có chương trình "A - Nobivac mốc 100". Kết thúc chương trình đó trước khi tạo chương trình mới." Bấm **Huỷ**, không lưu.
- [ ] Mở chi tiết "A - Nobivac mốc 100": tiến độ **0/100 hộp**.

---

## PHẦN 2 — Nhập hàng, bán, kiểm kê

> **Hai sản phẩm trong cả kịch bản** (từ đây tôi luôn viết đủ tên, không dùng chữ N / W nữa; chỗ nào còn "N" hay "W" ở Phần 3–4 thì N = **Nobivac**, W = **Thuốc tẩy giun**):
> - **Nobivac** (ĐVT hộp): phiếu R1, R3, R4, bán, kiểm kê, giá vốn, lãi gộp. Là sản phẩm chính.
> - **Thuốc tẩy giun** (ĐVT hộp): chỉ phiếu R2 (hàng tặng) và cảnh báo cận hạn.
>
> **Ngày dùng cho HSD** (tôi tính theo hôm nay = **16/11/2026**; chạy ngày khác thì tính lại theo "hôm nay + …"). Gõ dạng `ngày/tháng/năm`:
>
> | Lô | Hôm nay + | HSD gõ vào |
> |---|---|---|
> | L1 (Nobivac, R1) | 6 tháng | `16/05/2027` |
> | LW (Thuốc tẩy giun, R2) | 20 ngày | `06/12/2026` |
> | L3 (Nobivac, R3) | 12 tháng | `16/11/2027` |
> | L4 (Nobivac, R4) | 18 tháng | `16/05/2028` |
>
> Theo dõi bảng **số dư Nobivac** ở cuối phần này sau mỗi bước.

### Tóm tắt 4 phiếu nhận hàng (mỗi phiếu có bước chi tiết ở mục riêng bên dưới)

| Phiếu | Mục | Nhà cung cấp | Sản phẩm | Mã lô | Hạn dùng | Số lượng nhận | Giá mua / hộp |
|---|---|---|---|---|---|---|---|
| R1 | 2.1 | **NCC-A** | **Nobivac** | `L1` | `16/05/2027` | `60` | `100000` |
| R2 | 2.2 | **NCC-B** | **Thuốc tẩy giun** | `LW` | `06/12/2026` | `11` (gồm 1 tặng) | `50000` |
| R3 | 2.4 | **NCC-C** | **Nobivac** | `L3` | `16/11/2027` | `100` | `110000` (+ chi phí thu mua `90000`) |
| R4 | 2.6 | **NCC-A** | **Nobivac** | `L4` | `16/05/2028` | `40` | `104000` |

Mỗi mục phiếu bên dưới tự ghi đủ từng thao tác từ Hub đến "Ghi nhận". Không có mục chung nào khác phải đọc.

### Bước 2.1. Phiếu R1: NCC-A, Nobivac, 60 hộp

1. Hub Kho → **Nhận hàng** → bấm **Nhận hàng** (tạo phiếu).
2. Màn **Thông tin nhận hàng**: ô **Nhà cung cấp** → chọn **NCC-A**. Ô **Số chứng từ** → gõ `R1`. Bấm **Tiếp tục**.
3. Màn **Hàng thực nhận**: ô tìm → gõ `Nobivac` → chạm **Nobivac**. Nếu hỏi **Chọn đơn vị nhập** → chạm **hộp**.
4. Chạm dòng **Nobivac** để mở form. Chạm vào **Lô 1 · Chưa hoàn tất** để mở ô nhập:
   - **Mã lô** → `L1`
   - **Hạn dùng** → `16/05/2027`
   - **Số lượng nhận** → `60`
5. Kéo xuống, ô **Giá mua / hộp** → `100000`.
6. Mục **Ưu đãi nhà cung cấp**: **không có** ô "% giảm theo bậc" (NCC-A là chương trình đạt mốc). **SL tặng** để `0`. Banner chương trình hiện kiểu "…: 0 + 60 / 100 hộp".
7. Bấm **Xong**, rồi **Tiếp tục**.
8. Màn **Rà soát nhận hàng**: để **Chi phí thu mua** = 0 và **Chiết khấu thương mại** = 0. Bấm **Ghi nhận**.

Kết quả cần thấy:
- [ ] Rà soát: Giá gốc = **6.000.000**, Đơn giá gốc = **100.000**.
- [ ] Màn kết quả: "Ghi nhận hàng thành công", Số dòng hàng 1, Tổng giá gốc **6.000.000**.
- [ ] Hub → **Tồn kho & khả dụng** → **Nobivac**: tồn **60**, giá trị **6.000.000**, bq **100.000**.
- [ ] Chương trình "A - Nobivac mốc 100": tiến độ **60/100**.
- [ ] Nobivac hiện **"Tồn thấp"** (60 ≤ 80), "Gợi ý nhập thêm 140 (mục tiêu 200)".

### Bước 2.2. Phiếu R2: NCC-B, Thuốc tẩy giun, mua 10 tặng 1

1. Hub Kho → **Nhận hàng** → bấm **Nhận hàng**.
2. **Thông tin nhận hàng**: **Nhà cung cấp** → **NCC-B**. **Số chứng từ** → `R2`. **Tiếp tục**.
3. **Hàng thực nhận**: ô tìm → gõ `Thuốc tẩy giun` → chạm **Thuốc tẩy giun** → (nếu hỏi) **hộp**.
4. Chạm dòng **Thuốc tẩy giun** → chạm **Lô 1 · Chưa hoàn tất**:
   - **Mã lô** → `LW`
   - **Hạn dùng** → `06/12/2026`
   - **Số lượng nhận** → **`11`** (không phải 10: 10 hộp mua + 1 hộp tặng)
5. Ô **Giá mua / hộp** → `50000`.
6. Mục **Ưu đãi nhà cung cấp**: banner hiện tên chương trình "B - Tẩy giun mua 10 tặng 1". Ô **SL tặng** tự hiện **`1`**. Nếu đang là `0` thì gõ `1`.
7. **Xong** → **Tiếp tục**.
8. **Rà soát nhận hàng**: chi phí 0, chiết khấu 0. Bấm **Ghi nhận**.

Vì sao nhập 11: app tính SL thanh toán = Số lượng nhận − SL tặng. Nhập 11, tặng 1 → trả tiền 10 hộp × 50.000 = 500.000. Nhập 10 thì app tự gợi ý tặng 1 và chỉ còn 9 hộp trả tiền (sai ý).

Kết quả cần thấy:
- [ ] Rà soát: nhập **11 hộp**, Giá mua **500.000**, Giá gốc **500.000**, Đơn giá gốc ≈ **45.454,55**.
- [ ] **Tồn kho** → **Thuốc tẩy giun**: tồn **11**, giá trị **500.000**.
- [ ] Thuốc tẩy giun có nhãn **"Có lô cận hạn"** (còn 20 ngày ≤ 30). **Không** có "Tồn thấp" (11 > 5).

### Bước 2.3. Bán Nobivac, trả hàng, huỷ đơn

**Khác với phiếu nhận: khi bán bạn KHÔNG nhập mã lô và KHÔNG nhập số chứng từ.**
- **Mã lô:** màn bán hàng không có ô chọn lô. App tự xuất theo hạn dùng gần nhất trước (FEFO). Nobivac lúc này chỉ có lô `L1` nên chắc chắn xuất từ `L1`. Muốn xem lô nào bị trừ: Hub → **Tồn kho & khả dụng** → **Nobivac** → mục **Lô và hạn dùng** (sau mỗi đơn), hoặc **Thẻ kho** ở bước 4.1 (cột **Lô**).
- **Số chứng từ:** đơn bán tự có **số đơn** do app cấp. Sau khi hoàn tất, đầu màn **Kết quả bán hàng** và đầu màn chi tiết đơn hiện dạng `#<số đơn>`. Bạn **ghi lại số đơn** của S1, S2, S3 vào bảng cuối tệp để dò lại ở Thẻ kho (cột **Chứng từ**) và báo cáo Lãi gộp tab **Theo đơn**.

#### 2.3.1 Đơn S1: bán 30 hộp Nobivac cho KH-Test

1. Vào tab **Đơn hàng** → bấm **Tạo đơn bán hàng** (nếu chưa có đơn nào) hoặc nút tạo đơn ở danh sách. Mở màn **Tạo đơn hàng**.
2. Thẻ khách đang ghi "Khách lẻ" → bấm **Chọn KH** → chọn **KH-Test**.
3. Ô tìm **"Tìm tên, SKU hoặc barcode"** → gõ `Nobivac` → chọn kết quả **Nobivac**. Nếu hiện sheet **Chọn đơn vị bán** → chọn `hộp` → **Xác nhận**.
4. Trên dòng Nobivac vừa thêm, **chạm vào số lượng** → hộp **Nhập số lượng** (đơn vị: hộp) → gõ `30` → xác nhận.
5. Kiểm tóm tắt: **Tổng tiền hàng (1 sản phẩm)** = **4.500.000**, Giảm giá = 0, **Thành tiền / Khách phải trả = 4.500.000**.
6. Bấm **Thanh toán** → màn **Thanh toán**: Phương thức để mặc định **Tiền mặt** (thu đủ 4.500.000) → bấm **Tiếp tục** → sheet **Hoàn tất đơn?** → bấm **Hoàn tất đơn** → màn **Kết quả bán hàng**.

- [ ] Ghi lại **số đơn S1**: `#________`.
- [ ] Sau S1: Tồn kho → Nobivac: tồn **30**, giá trị **3.000.000** (xuất 30 × 100.000). **Lô L1 còn 30** (app tự lấy từ L1).

#### 2.3.2 Trả 5 hộp của đơn S1

1. Tab **Đơn hàng** → mở đơn **S1** (đơn Nobivac 30 hộp, trạng thái Hoàn tất).
2. Bấm **Thao tác** (sheet hiện: Thu tiền / Đổi/trả hàng / Hủy đơn) → chọn **Đổi/trả hàng**.
3. Màn đổi/trả, mục **Hàng trả** (có dòng Nobivac): bấm nút **+** đúng **5 lần** để số lượng trả = `5`. Mục **Hàng đổi**: **không chọn gì**.
4. Tóm tắt dự kiến: Giá trị hàng trả = **750.000**. Bấm **Tiếp tục**.
5. Màn **Quyết toán đổi/trả**: tiêu đề "Cần hoàn tiền". **Phương thức hoàn** = **Tiền mặt**. Bấm **Xác nhận đổi/trả**.

- [ ] Sau trả: tồn Nobivac = **35**, giá trị **3.500.000**, bq **100.000**.

#### 2.3.3 Đơn S2: bán 10 hộp Nobivac, rồi huỷ đơn

**Phần A. Tạo và hoàn tất đơn S2 (bán 10 hộp)**

1. Vào tab **Đơn hàng** → bấm nút tạo đơn (**Tạo đơn bán hàng** / **Tạo đơn hàng**). Mở màn **Tạo đơn hàng**.
2. Thẻ khách đang ghi "Khách lẻ" → bấm **Chọn KH** → chọn **KH-Test**.
3. Ô tìm **"Tìm tên, SKU hoặc barcode"** → gõ `Nobivac` → chạm kết quả **Nobivac**. Nếu hiện sheet **Chọn đơn vị bán** → chọn `hộp` → **Xác nhận**.
4. Trên dòng Nobivac vừa thêm, **chạm vào số lượng** → hộp **Nhập số lượng** → gõ `10` → xác nhận.
5. Kiểm tóm tắt: **Tổng tiền hàng (1 sản phẩm)** = **1.500.000**, Giảm giá = 0, **Khách phải trả = 1.500.000**.
6. Bấm **Thanh toán** → màn **Thanh toán**. **Lần này KHÔNG thu tiền** (vì đơn đã thu tiền thì app không cho huỷ, chỉ cho đổi/trả; app báo "Đơn đã có thanh toán, vui lòng đổi/trả"):
   - Phương thức giữ **Tiền mặt**. Ô **Số tiền mặt**: xoá `1.500.000` và gõ `0`.
   - Mục **Công nợ phát sinh** hiện **1.500.000**. Ô **Ngày hẹn thanh toán** (bắt buộc khi có công nợ): bấm **Chọn ngày hẹn** → chọn một ngày sau hôm nay (ví dụ 7 ngày nữa).
   - Bấm **Tiếp tục** → sheet **Hoàn tất đơn?** → bấm **Hoàn tất đơn** → màn **Kết quả bán hàng**. Ghi lại số đơn ở đầu màn.
   - (Khách lẻ không ghi nợ được; ở đây khách là **KH-Test** nên được.)
   - Nếu app không cho nhập số tiền mặt = 0, ghi lại câu báo lỗi và cho tôi biết; ta đổi cách tạo đơn chưa thu tiền.

- [ ] Ghi lại **số đơn S2**: `#________`.
- [ ] Đơn S2 hiện còn nợ **1.500.000**, đã thanh toán **0**.
- [ ] Trước khi huỷ, Tồn kho → Nobivac: tồn **25**, giá trị **2.500.000** (35 − 10). Kho trừ ngay khi hoàn tất đơn, dù chưa thu tiền.

**Phần B. Huỷ đơn S2**

7. Vào tab **Đơn hàng** → mở đơn **S2** (đúng số đơn vừa ghi, trạng thái Hoàn tất).
8. Bấm **Thao tác** → trong sheet chọn **Hủy đơn** (mục này **không bị mờ** vì S2 chưa thu đồng nào).
9. Sheet **Hủy đơn hàng?**: mục "Điều chỉnh dự kiến" hiện Tồn kho "Hoàn lại 10 …". Ô **Lý do hủy** (không bắt buộc): gõ `Test huỷ`. Bấm **Hủy đơn hàng**.

- [ ] Đơn S2 chuyển sang **Đã hủy**.
- [ ] Tồn Nobivac vẫn **35**, giá trị **3.500.000** (huỷ hoàn nguyên đúng: từ 25 trở lại 35).
- [ ] Nobivac vẫn **"Tồn thấp"** (35 ≤ 80), "Gợi ý nhập thêm **165** (mục tiêu 200)".

#### 2.3.4 Nếu bạn đã lỡ thu tiền cho S2 (không huỷ được): làm từng bước này

Dùng khi đơn S2 của bạn đã thu tiền nên nút **Hủy đơn** bị mờ ("Đơn đã có thanh toán, vui lòng đổi/trả"). Tình trạng lúc này: tồn Nobivac = **25**, giá trị **2.500.000**. Không cần xoá hay làm lại gì từ đầu.

**Phần A. Trả hết 10 hộp của S2 cũ (đưa tồn về 35)**

1. Vào tab **Đơn hàng** → mở đơn **S2 cũ** (đơn bán 10 hộp Nobivac đã thu tiền).
2. Bấm **Thao tác** → trong sheet chọn **Đổi/trả hàng**.
3. Màn đổi/trả, mục **Hàng trả** (dòng Nobivac): bấm nút **+** đúng **10 lần** để số lượng trả = `10`. Mục **Hàng đổi**: không chọn gì.
4. Tóm tắt dự kiến: Giá trị hàng trả = **1.500.000**. Bấm **Tiếp tục**.
5. Màn **Quyết toán đổi/trả** ("Cần hoàn tiền"): **Phương thức hoàn** = **Tiền mặt**. Bấm **Xác nhận đổi/trả**.

- [ ] Ghi lại **số đơn S2 cũ**: `#________`.
- [ ] Tồn Nobivac = **35**, giá trị **3.500.000**.

**Phần B. Tạo đơn mới chưa thu tiền rồi huỷ (để test chức năng huỷ)**

6. Làm đúng các bước 1 đến 9 của mục **2.3.3** ở trên (tạo đơn bán 10 hộp Nobivac cho KH-Test, **Số tiền mặt = 0**, chọn **Ngày hẹn thanh toán**, hoàn tất, rồi **Thao tác → Hủy đơn**).

- [ ] Ghi lại **số đơn huỷ**: `#________`.
- [ ] Đơn chuyển **Đã hủy**. Tồn Nobivac về **35**, giá trị **3.500.000**.

**Số kỳ vọng khác đi nếu bạn làm theo mục này** (khác với các số ghi ở bước 4.1):
- Bước 4.1, Báo cáo tồn, dòng Nobivac: **Nhập 225** (200 mua + 5 trả S1 + 10 trả S2 cũ + 10 huỷ đơn mới), **Xuất 152** (30 + 10 + 10 + 2 kiểm kê + 100). Đầu kỳ 0, Cuối kỳ 73 không đổi.
- Giá trị tồn, giá vốn, doanh thu thuần, lãi gộp (bước 3.2, 4.2) **không đổi**, vì S2 cũ bán rồi trả hết nên doanh thu và giá vốn triệt tiêu nhau.
- Bước 4.2, tab **Theo đơn**: có thêm S2 cũ.

### Bước 2.4. Phiếu R3: NCC-C, Nobivac, 100 hộp (giảm giá theo bậc)

Làm theo "Cách lập một phiếu nhận", với **hai lượt** trên cùng một phiếu: nhập thử 80 để xem gợi ý, rồi sửa thành 100.

1. Hub Kho → **Nhận hàng** → bấm **Nhận hàng**.
2. **Thông tin nhận hàng**: **Nhà cung cấp** → **NCC-C**. **Số chứng từ** → `R3`. **Tiếp tục**.
3. **Hàng thực nhận**: ô tìm → `Nobivac` → chạm **Nobivac** → (nếu hỏi) **hộp**.
4. Chạm dòng **Nobivac** → chạm **Lô 1 · Chưa hoàn tất**:
   - **Mã lô** → `L3`
   - **Hạn dùng** → `16/11/2027`
   - **Số lượng nhận** → **`80`** (lượt thử)
5. Ô **Giá mua / hộp** → `110000`.
6. Mục **Ưu đãi nhà cung cấp** (lượt thử, 80 hộp):
   - [ ] **% giảm theo bậc** tự hiện **`3`**.
   - [ ] Banner có dòng kiểu "Nhập thêm **20** hộp để được giảm **5%**".
7. Quay lên sửa **Số lượng nhận** thành **`100`** (lượt thật).
   - [ ] **% giảm theo bậc** tự đổi thành **`5`**. **SL tặng** để `0`.
8. **Xong** → **Tiếp tục**.
9. **Rà soát nhận hàng**: ô **Chi phí thu mua** → `90000`. **Chiết khấu thương mại** → `0`. Bấm **Ghi nhận**.

Kết quả cần thấy:
- [ ] Bảng Phân bổ giá gốc: Giá mua **11.000.000**, Giảm bậc **550.000**, Chi phí **90.000**, Giá gốc **10.540.000**, Đơn giá gốc **105.400**.
- [ ] **Tồn kho** → **Nobivac**: tồn **135**, giá trị **14.040.000**, bq **104.000**. Hết "Tồn thấp" (135 > 80).
- [ ] Mục **Lô và hạn dùng**: L1 = 35 (HSD 16/05/2027), L3 = 100 (HSD 16/11/2027).

### Bước 2.5. Kiểm kê Nobivac: mở phiên, thử chặn giá vốn, rồi hoàn tất

#### 2.5.1 Mở phiên kiểm kê (chưa đếm)

1. Hub Kho → **Kiểm kê kho** → bấm **Tạo phiên kiểm kê**. Màn "Tạo phiên kiểm kê":
   - **Phạm vi**: chọn **Sản phẩm** (không chọn Toàn kho). Bấm **Chọn phạm vi cụ thể** → chọn **Nobivac**. (Hiện "2 mặt hàng": L1 và L3.)
   - **Người đếm**: chọn tên tài khoản của bạn trong danh sách.
   - **Lý do kiểm kê** (bắt buộc): gõ `Kiểm kê test T7`.
2. Bấm **Mở phiên kiểm kê** → sheet **Mở phiên kiểm kê?** → **Mở phiên**.

- [ ] Hub Kho mục **Cần chú ý** có "Kiểm kê đang dở: 1 phiên chưa ghi nhận".

#### 2.5.2 Thử chặn giá vốn (trong lúc phiên còn mở)

1. Hub → **Giá vốn** → bấm **Cập nhật giữa kỳ** → màn tính → bấm **Tính giá vốn**.

- [ ] Bị **chặn**: có danh sách việc cần làm, trong đó có việc "ghi nhận hoặc huỷ phiên kiểm kê" (mã `STOCKTAKE_OPEN`). Không công bố được. Rời màn, quay lại phiên kiểm kê.

#### 2.5.3 Đếm và ghi nhận

1. Hub → **Kiểm kê kho** → mở phiên vừa tạo → màn **Đếm mù** (chưa thấy số sổ; app ghi "Số lượng theo sổ chỉ xuất hiện sau khi nộp lần đếm đầu").
2. Cột **Đếm được**, mỗi dòng một ô:
   - Dòng **Nobivac · Lô L1** → gõ `33`
   - Dòng **Nobivac · Lô L3** → gõ `100`
3. Bấm **Nộp kết quả đếm** → sheet **Nộp lần đếm đầu?** → **Nộp kết quả**.
4. Màn **Chênh lệch và đếm lại** (mục "Mặt hàng lệch"): dòng **Nobivac · Lô L1**: Theo sổ **35**, Đếm đầu **33**, Chênh lệch **−2**.
   - Cột **Lý do** (3 lựa chọn Thất thoát / Hỏng / Hết hạn): chọn **Hỏng**.
   - Cột **Đếm lại**: bấm nút **Vẫn 33**.
   - Lô L3 khớp (Theo sổ 100 = Đếm 100) nằm ở mục khớp; có thể bấm "Xem 1 mặt hàng khớp".
5. Bấm **Ghi nhận điều chỉnh** → sheet **Ghi nhận điều chỉnh?** → **Ghi nhận** → màn **Kết quả kiểm kê**.

- [ ] Kết quả: "Đã hoàn tất kiểm kê", **Thiếu / thừa = −2** hộp.
- [ ] Tồn Nobivac = **133**, giá trị **13.832.000** (trừ 2 × 104.000 = 208.000). Lô L1 còn 33.
- [ ] Hub: mục "Kiểm kê đang dở" biến mất.

### Bước 2.6. Phiếu R4: NCC-A, Nobivac, 40 hộp (đạt mốc chiết khấu)

1. Hub Kho → **Nhận hàng** → bấm **Nhận hàng**.
2. **Thông tin nhận hàng**: **Nhà cung cấp** → **NCC-A**. **Số chứng từ** → `R4`. **Tiếp tục**.
3. **Hàng thực nhận**: ô tìm → `Nobivac` → chạm **Nobivac** → (nếu hỏi) **hộp**.
4. Chạm dòng **Nobivac** → chạm **Lô 1 · Chưa hoàn tất**:
   - **Mã lô** → `L4`
   - **Hạn dùng** → `16/05/2028`
   - **Số lượng nhận** → `40`
5. Ô **Giá mua / hộp** → `104000`. **SL tặng** để `0`.
   - [ ] Banner chương trình NCC-A kiểu "…: 60 + 40 / 100 hộp".
6. **Xong** → **Tiếp tục**.
7. **Rà soát nhận hàng**: chi phí 0, chiết khấu 0 → **Ghi nhận**.

Kết quả cần thấy:
- [ ] **Tồn kho** → **Nobivac**: tồn **173**, giá trị **17.992.000**, bq **104.000**.
- [ ] Chương trình "A - Nobivac mốc 100": tiến độ **100/100**, chip **Đạt mốc**.
- [ ] Hub "Cần chú ý": có mục "Chương trình đạt mốc … chờ ghi nhận chiết khấu".

### Bước 2.7. Bán 100 hộp Nobivac + thử bán vượt tồn

#### 2.7.1 Đơn S3

1. Vào tab **Đơn hàng** → bấm nút tạo đơn (**Tạo đơn bán hàng** / **Tạo đơn hàng**).
2. Thẻ khách → **Chọn KH** → chọn **KH-Test**.
3. Ô tìm **"Tìm tên, SKU hoặc barcode"** → gõ `Nobivac` → chạm **Nobivac**. Nếu hiện **Chọn đơn vị bán** → `hộp` → **Xác nhận**.
4. Chạm vào số lượng của dòng Nobivac → **Nhập số lượng** → gõ `100` → xác nhận.
5. Kiểm tóm tắt: Tổng tiền hàng **15.000.000**, **Khách phải trả 15.000.000**.
6. Bấm **Thanh toán** → Phương thức **Tiền mặt** (mặc định) → **Tiếp tục** → sheet **Hoàn tất đơn?** → **Hoàn tất đơn** → màn **Kết quả bán hàng**. Ghi lại số đơn.

- [ ] Ghi lại **số đơn S3**: `#________`.
- [ ] Xuất theo hạn dùng gần nhất trước (FEFO): hết **L1 (33)** rồi **67** từ **L3**. Còn **L3 = 33, L4 = 40** (xem Tồn kho → Nobivac → Lô và hạn dùng). Nếu app chia lô khác thì ghi lại; tổng số lượng và giá trị vẫn phải đúng.
- [ ] Tồn Nobivac = **73**, giá trị **7.592.000** (xuất 100 × 104.000 = 10.400.000).
- [ ] Nobivac lại **"Tồn thấp"** (73 ≤ 80), "Gợi ý nhập thêm **127** (mục tiêu 200)"; Hub "Cần chú ý" có mục này.

#### 2.7.2 Thử bán vượt tồn

1. Tạo đơn mới: khách **KH-Test**, sản phẩm **Nobivac**, số lượng **`80`** (tồn chỉ 73).

- [ ] App **chặn**: báo vượt tồn khi nhập số lượng, hoặc không cho thanh toán. Ghi lại app chặn ở bước nào và câu báo. Rồi **không** hoàn tất đơn này: bấm quay lại, bỏ đơn nháp (nếu hỏi "Lưu nháp?" thì chọn bỏ).

### Bước 2.8. Ghi nhận chiết khấu NCC-A (sản phẩm Nobivac)

1. Hub Kho → **Chương trình nhà cung cấp** → mở **"A - Nobivac mốc 100"** (chip **Đạt mốc**) → bấm **Ghi nhận chiết khấu**.
2. Màn **Ghi nhận chiết khấu**, mục **Căn cứ**: kiểm Nhà cung cấp **NCC-A**, Đã mua **100**, Tổng tiền mua **10.160.000**, Mức chiết khấu **5%**, Đề xuất **508.000**.
3. **Số chứng từ** (bắt buộc): gõ `CK-01`. **Ngày chứng từ**: hôm nay. **Số tiền ghi nhận** (bắt buộc): để nguyên số đề xuất `508000` (không sửa, nên không cần "Lý do khác đề xuất").
4. Bấm **Ghi nhận** → sheet "Ghi nhận chiết khấu 508.000?" (cảnh báo "Giá trị tồn và bình quân của 1 sản phẩm sẽ giảm. Không hoàn tác được.") → bấm **Ghi nhận**.

- [ ] Màn kết quả chia: phần trừ vào **tồn** = **370.840**, phần giảm **giá vốn đã bán** = **137.160** (508.000 × 73/100 = 370.840).
- [ ] Chương trình chuyển **"Đã ghi nhận"**.
- [ ] Tồn Nobivac = 73, giá trị **7.221.160**, bq **98.920**.

### Bảng số dư Nobivac (đối chiếu nhanh)

| Sau bước (mục) | Tồn | Giá trị sổ | bq |
|---|---|---|---|
| 2.1 (R1) | 60 | 6.000.000 | 100.000 |
| 2.3 (bán/trả/huỷ) | 35 | 3.500.000 | 100.000 |
| 2.4 (R3) | 135 | 14.040.000 | 104.000 |
| 2.5 (kiểm kê −2) | 133 | 13.832.000 | 104.000 |
| 2.6 (R4) | 173 | 17.992.000 | 104.000 |
| 2.7 (bán 100) | 73 | 7.592.000 | 104.000 |
| 2.8 (chiết khấu) | 73 | 7.221.160 | 98.920 |

---

## PHẦN 3 — Giá vốn & chốt kỳ (chỉ tài khoản chủ cửa hàng)

> **Đã rà theo code ngày 16/11/2026:** `presentation/costing/*` (màn 072 Giá vốn, 074 lần tính, 077 kết quả), `costing_rules.dart`, migration `20261118001_inventory_costing.sql` (`_cost_run_compute`, `create_cost_run`, `publish_cost_run`, `get_cost_overview`). Số kỳ vọng tính lại theo đúng công thức trong SQL; khớp spec giá vốn mục 5.
>
> Hôm nay còn trong tháng 11/2026 nên **không có nút "Chốt kỳ"** (nút này chỉ hiện khi tháng của kỳ đang mở đã kết thúc). Ta dùng **Cập nhật giữa kỳ**.
>
> **Đừng làm thêm nghiệp vụ kho nào** (nhận hàng, bán, kiểm kê) giữa bước 3.2 và 3.4. Có biến động mới thì lần tính chuyển "Cần tính lại" và không công bố được.

### Bước 3.1. Chọn phương pháp giá vốn

1. Hub Kho → **Giá vốn**. Tiêu đề **Giá vốn**, dưới đó ghi "Chính sách: Bình quân liên hoàn" (mặc định).
2. Ở danh sách (chip **Cần làm**) có thể đã có một dòng **"Cập nhật giá vốn 11/2026"**, nhãn **Cần xử lý**, "1 việc cần xử lý". Đó là lần tính bị chặn ở bước 2.5.2. Cứ để đó: lần tính mới ở bước 3.2 sẽ tự thay nó và dòng này biến mất.
3. Bấm **Đổi** (góc trên, cạnh tiêu đề) → sheet **Chọn phương pháp giá vốn** có 2 lựa chọn, mỗi cái kèm một câu giải thích:
   - **Bình quân liên hoàn**: "Giá vốn tính lại sau mỗi lần nhập."
   - **Bình quân cuối kỳ**: "Giá vốn mỗi sản phẩm là giá trung bình của tồn đầu kỳ và hàng nhập cả kỳ."
4. Chọn **Bình quân cuối kỳ** → **Lưu** (nút Lưu chỉ sáng khi chọn khác phương pháp hiện tại).

- [ ] Sheet có câu "Chỉ đổi được trước lần công bố giá vốn đầu tiên."
- [ ] Sheet đóng, dòng dưới tiêu đề đổi thành **"Chính sách: Bình quân cuối kỳ"**.

### Bước 3.2. Tạo lần tính và rà soát

1. Màn Giá vốn → bấm **Cập nhật giữa kỳ** (nút ở chân màn) → mở màn **"Cập nhật giá vốn 11/2026"** (chưa tính): Kỳ **11/2026**, Phạm vi **Toàn bộ sản phẩm**, mục **Phương pháp**.
   - [ ] Mục **Phương pháp** ở màn này ghi gì? **Nghi lỗi:** code đang gán cứng "Bình quân liên hoàn" cho màn chưa tính (`cost_run_page.dart`, `CostMethodBlock(method: CostMethod.moving)`), nên có thể vẫn ghi liên hoàn dù đã chọn cuối kỳ. Ghi lại thực tế. Sau khi tính, màn rà soát lấy đúng phương pháp của lần tính.
2. Bấm **Tính giá vốn** (chân màn). Chờ tính xong → màn rà soát, phụ đề "2 sản phẩm · Thời điểm chốt 16/11/2026 · hh:mm". Chân màn có **Bỏ lần tính** (chữ đỏ) và **Công bố giá vốn**.
3. Kiểm phần đầu màn rà soát:

| Chỗ trên màn | Giá trị kỳ vọng |
|---|---|
| Thẻ **Giá trị tồn cuối** | **7.684.660 đ** (Nobivac 7.184.660 + Thuốc tẩy giun 500.000) |
| Thẻ **Giá vốn xuất** | **12.937.500 đ** |
| Mục **Thay đổi sẽ ghi khi công bố** → Điều chỉnh giá vốn xuất | **+36.500 đ** (= +37.500 giá vốn bán − 1.000 hao hụt) |
| ↳ Điều chỉnh giá trị tồn | **−36.500 đ** |
| Mục **Phương pháp** | "**Bình quân cuối kỳ** — giá vốn mỗi sản phẩm là giá trung bình…" |
| Cột phụ **Tóm tắt** (chỉ web rộng) | Kỳ 11/2026 · Phạm vi Toàn bộ sản phẩm · Thời điểm chốt · Phương pháp Bình quân cuối kỳ |

4. Mục **Theo sản phẩm**:
   - **Web rộng:** bảng cột Sản phẩm / Giá vốn cũ / Giá vốn mới / Chênh lệch.
   - **iPhone:** chỉ hiện sẵn sản phẩm có chênh lệch (Nobivac); bấm **Xem 2 sản phẩm** để thấy đủ.

| Sản phẩm | Giá vốn cũ | Giá vốn mới | Chênh lệch |
|---|---|---|---|
| Nobivac | **Giá tạm** | **98.420 đ/hộp** | **−36.500 đ** |
| Thuốc tẩy giun | **Giá tạm** | **45.455 đ/hộp** | nhãn **Không đổi** |

   Giá vốn mới của Nobivac là **98.420**, không phải 103.500: theo spec mục 5, với bình quân cuối kỳ thì phiên bản giá = giá trị tồn cuối ÷ SL tồn cuối = 7.184.660 ÷ 73. Giá trị này đã gồm chiết khấu NCC phần còn trong kho. **103.500** chỉ là cột "Bình quân cuối kỳ" trong Chi tiết tính.

5. Bấm **Xem chi tiết tính** → sheet **Chi tiết tính** (web: bảng có dòng **Tổng**; iPhone: mỗi sản phẩm một nhóm).

| Cột | Nobivac | Thuốc tẩy giun |
|---|---|---|
| Tồn đầu | 0 · 0 đ | 0 · 0 đ |
| Nhập | **200 · 20.700.000 đ** | **11 · 500.000 đ** |
| Chiết khấu NCC | **−370.840 đ** | 0 đ |
| Xuất bán | **125 · 12.937.500 đ** (sổ 12.900.000 + điều chỉnh 37.500) | 0 · 0 đ |
| Hao hụt | **2 · 207.000 đ** (sổ 208.000 − 1.000) | 0 · 0 đ |
| Tồn cuối | **73 · 7.184.660 đ** | **11 · 500.000 đ** |
| Bình quân liên hoàn | **98.920 đ** | 45.455 đ |
| Bình quân cuối kỳ | **103.500 đ** | 45.455 đ |
| Điều chỉnh | **−36.500 đ** | **0 đ** |

   Xuất bán 125 = 30 (S1) − 5 (trả) + 10 (S2) − 10 (huỷ S2) + 100 (S3). Trả hàng và huỷ đơn trước lần công bố đầu tiên được trừ vào xuất bán, không cộng vào nhập. Nếu bạn đã làm mục 2.3.4, S2 cũ bán 10 rồi trả 10 nên vẫn ra 125.

   - [ ] Dòng **Tổng** (web): Nhập **21.200.000**, Chiết khấu NCC **−370.840**, Xuất bán **12.937.500**, Hao hụt **207.000**, Tồn cuối **7.684.660**, Điều chỉnh **−36.500**.
   - [ ] Cuối sheet có nhãn xanh **"Kiểm cân bằng: Khớp"** và dòng "Tồn đầu + Nhập − Chiết khấu NCC = Giá vốn xuất + Hao hụt + Tồn cuối". Bấm **Đóng**.

6. Ở mục **Phương pháp**, bấm **Xem đối chiếu theo Bình quân liên hoàn** → sheet **"Đối chiếu theo Bình quân liên hoàn"** ("Chỉ để đối chiếu; không dùng để công bố."). Sheet cộng **cả 2 sản phẩm**:
   - [ ] Giá trị tồn cuối **7.721.160 đ** (Nobivac 7.221.160 + Thuốc tẩy giun 500.000).
   - [ ] Giá vốn xuất **12.900.000 đ**.

### Bước 3.3. Không tạo được lần tính thứ hai khi đang chờ công bố

**Chưa công bố.** Bấm mũi tên quay lại → màn **Giá vốn**.

- [ ] Chân màn **không còn nút "Cập nhật giữa kỳ"**: app ẩn nút này khi đã có lần tính chờ công bố. Vì vậy trên app không bấm được để thấy lỗi `RUN_PENDING_REVIEW`.
- [ ] Chip **Cần làm** có dòng **"Cập nhật giá vốn 11/2026"**, nhãn **Sẵn sàng công bố**, "2 sản phẩm · đã tính, chờ công bố". Web có thêm cột **Chênh lệch sẽ ghi −36.500 đ**. Dòng "Cần xử lý" của bước 2.5.2 đã biến mất.
- [ ] (Tuỳ chọn, chỉ web) Gõ thẳng địa chỉ `/warehouse/costing/new?kind=MID_PERIOD` → **Tính giá vốn**. Phải hiện banner "Chưa công bố được", việc **"Đã có lần tính chờ công bố"** kèm nút **Mở lần tính**. Bấm **Mở lần tính** phải về đúng lần tính đang chờ. Lần tính bị chặn này sẽ tự bị thay ở lần tính sau.

Chạm dòng **Sẵn sàng công bố** để mở lại màn rà soát.

### Bước 3.4. Công bố

1. Màn rà soát → **Công bố giá vốn** → sheet **"Công bố giá vốn?"** ("Kết quả đã rà soát sẽ có hiệu lực. Hệ thống chỉ ghi phần chênh lệch, không sửa chứng từ lịch sử.").
   - [ ] Sheet ghi: Kỳ ghi nhận **11/2026** · Phạm vi **Toàn bộ sản phẩm** · Phương pháp **Bình quân cuối kỳ** · Điều chỉnh giá vốn xuất **+36.500 đ** · Điều chỉnh giá trị tồn **−36.500 đ**.
2. Bấm **Công bố giá vốn** → màn **Kết quả công bố giá vốn**.
   - [ ] Tiêu đề **"Đã công bố giá vốn 11/2026"**, "Phần chênh lệch đã được ghi và giá vốn chính thức mới đã có hiệu lực."
   - [ ] Kỳ ghi nhận **11/2026** · Phương pháp **Bình quân cuối kỳ** · Sản phẩm có giá vốn mới **2** · Điều chỉnh giá vốn xuất **+36.500 đ** · Điều chỉnh giá trị tồn **−36.500 đ** · Công bố lúc (giờ hiện tại).
   - [ ] Có 3 nút: **Về giá vốn**, **Xem báo cáo lãi gộp**, **Xem báo cáo tồn**.
3. Bấm **Về giá vốn**:
   - [ ] Chip **Cần làm** trống ("Không còn việc cần làm"). Chip **Đã công bố (1)** có dòng "Cập nhật giá vốn 11/2026", "Công bố 16/11/2026".
   - [ ] **Không còn nút "Đổi"** cạnh tiêu đề (app ẩn hẳn, không báo lỗi). Dòng "Chính sách: Bình quân cuối kỳ" giữ nguyên.
   - [ ] Nút **Cập nhật giữa kỳ** hiện lại. Không có nút "Chốt kỳ".
   - [ ] Chạm dòng đã công bố → mở lại màn kết quả. Màn này **không có** nút công bố lần nữa.
4. Hub → **Tồn kho & khả dụng** → **Nobivac** → khối **Giá vốn**:
   - [ ] Giá vốn chính thức **98.420 đ/hộp** · Bình quân liên hoàn **98.420 đ/hộp** (lúc công bố, app đặt lại bằng giá trị sổ ÷ tồn) · Giá trị tồn (sổ) **7.184.660 đ** · "Phương pháp: Bình quân cuối kỳ". Không còn dòng "Xuất kho đang dùng giá tạm".
   - [ ] Bấm **Lịch sử giá vốn** → sheet có 1 dòng **98.420 đ/hộp**, "Bình quân cuối kỳ · Công bố 16/11/2026 · GV-2611-02". Mã có thể là -01 hoặc -03 tuỳ số lần tính đã tạo trong tháng. Ghi lại.
   - [ ] Mở **Thuốc tẩy giun**: Giá vốn chính thức **45.455 đ/hộp**, giá trị sổ **500.000 đ**.
5. Lần công bố ghi vào sổ giá trị Nobivac **2 dòng điều chỉnh** (không có dòng làm tròn vì bằng 0): điều chỉnh giá vốn bán làm giá trị tồn **giảm 37.500**, điều chỉnh hao hụt làm giá trị tồn **tăng 1.000**. Thẻ kho ở Phần 4 có thể hiện thành 2 dòng như vậy. Ghi lại cách app hiển thị.

**Số dư Nobivac sau Phần 3:** tồn 73 · giá trị sổ **7.184.660** · giá chính thức **98.420**.

---

## PHẦN 4 — Báo cáo

Mọi báo cáo: bấm **Chọn kỳ** → chọn **Tháng này** → **Áp dụng**.

### Bước 4.1. Báo cáo nhập – xuất – tồn và thẻ kho

1. Hub → **Báo cáo tồn & thẻ kho**.
2. Bảng sản phẩm (cột Đầu kỳ / Nhập / Xuất / Cuối kỳ / Khả dụng / Giá trị cuối kỳ):

| Sản phẩm | Đầu kỳ | Nhập | Xuất | Cuối kỳ | Giá trị cuối kỳ |
|---|---|---|---|---|---|
| Nobivac | 0 | **215** (225 nếu đã làm mục 2.3.4) | **142** (152 nếu đã làm mục 2.3.4) | **73** | **7.184.660** |
| Thuốc tẩy giun | 0 | **11** | 0 | **11** | **500.000** |

   Giải thích: báo cáo cộng mọi biến động tăng vào "Nhập" và mọi biến động giảm vào "Xuất". Nobivac Nhập 215 = 200 (3 phiếu) + 5 (trả hàng) + 10 (huỷ S2). Xuất 142 = 30 (S1) + 10 (S2) + 2 (kiểm kê) + 100 (S3). Hiệu: 0 + 215 − 142 = 73.
   - [ ] **Tổng giá trị cuối kỳ** = **7.684.660** (7.184.660 + 500.000).
3. Chạm dòng **Nobivac** → **Thẻ kho**:
   - [ ] **Tồn đầu kỳ 0**, **Tồn cuối kỳ 73**.
   - [ ] Có đủ các dòng (cột Ngày nghiệp vụ / Chứng từ / Diễn giải / Lô / Nhập / Xuất / Tồn): R1, S1, trả hàng, S2 và huỷ S2, R3, kiểm kê, R4, S3, chiết khấu NCC, **một** dòng điều chỉnh giá vốn từ lần công bố.
   - [ ] Bộ lọc lô: **Tất cả lô**, **Lô L1**, **Lô L3**, **Lô L4**. Chọn Lô L3 → thấy nhập 100, xuất 67.
4. Chạm một dòng (ví dụ phiếu R3) → **Chi tiết biến động** → bấm **Mở phiếu gốc**.
   - [ ] Mở đúng phiếu nhận R3 (số chứng từ R3).

### Bước 4.2. Lãi gộp

Hub → **Lãi gộp** → tab **Theo sản phẩm**.

- [ ] Dòng tổng: **Doanh thu thuần 18.750.000** (30 + 100 hộp bán, trừ 5 hộp trả; × 150.000), **Giá vốn 12.800.340**, **Lãi gộp 5.949.660**, **Hao hụt / huỷ 207.000**, **Lãi sau hao hụt 5.742.660**.
- [ ] Dòng **Nobivac** (bảng web có cột; trên iPhone chạm dòng để xem chi tiết): Doanh thu thuần **18.750.000**; Giá vốn lúc bán **12.900.000**; Điều chỉnh **+37.500**; Chiết khấu NCC **137.160**; Giá vốn sau điều chỉnh **12.800.340** (= 12.900.000 + 37.500 − 137.160); Lãi gộp **5.949.660**; Tỷ lệ **31,7%**.
- [ ] **Thuốc tẩy giun** không có dòng (chưa bán).

Tab **Theo đơn**:
- [ ] Có đơn **S1** và **S3** (S2 đã huỷ nên không có). S3: doanh thu **15.000.000**, giá vốn **10.400.000**. S1: doanh thu **4.500.000** (giá vốn **3.000.000**, có thể đã trừ phần trả hàng: ghi lại số thực tế).
- [ ] Có ghi chú "Điều chỉnh giá vốn không chia xuống từng đơn."

### Bước 4.3. Nhập hàng theo NCC

Hub → **Nhập hàng theo NCC** (chọn kỳ như trên).

| Nhà cung cấp | Số phiếu | Tiền mua | Chi phí thu mua | Chiết khấu thương mại | Giá gốc | Chiết khấu đạt mốc |
|---|---|---|---|---|---|---|
| NCC-A | 2 | 10.160.000 | 0 | 0 | 10.160.000 | **508.000** |
| NCC-B | 1 | 500.000 | 0 | 0 | 500.000 | 0 |
| NCC-C | 1 | 10.450.000 (sau giảm bậc) | 90.000 | 0 | 10.540.000 | 0 |

- [ ] Tổng giá gốc = **21.200.000**.
- [ ] Chạm **NCC-B**: sản phẩm Thuốc tẩy giun, mua **10**, tặng **1**, giá gốc 500.000, đơn giá gốc bình quân ≈ **45.454,55**.

### Bước 4.4. So sánh nhà cung cấp (sản phẩm Nobivac)

1. Hub → **Tồn kho & khả dụng** → mở **Nobivac** → bấm **So sánh nhà cung cấp**.

- [ ] **NCC-A**: 2 lần nhập, bình quân đơn giá gốc **101.600** (10.160.000 ÷ 100), lần gần nhất **104.000**, tổng mua 100 tặng 0.
- [ ] **NCC-C**: 1 lần nhập, bình quân đơn giá gốc **105.400**.
- [ ] NCC-B không xuất hiện ở Nobivac (B chỉ bán Thuốc tẩy giun).

---

## PHẦN 5 — Kiểm cuối

### 5.1 Hiển thị web và điện thoại
- [ ] Mở trang Kho trên **Chrome cửa sổ rộng (~1280)** và trên **iPhone/màn hẹp (~390)**. Lần lượt mở: Hub, Tồn kho, Nhận hàng, Kiểm kê, Giá vốn, Báo cáo tồn & thẻ kho, Lãi gộp. Không vỡ bố cục, chữ không bị cắt.
- [ ] Hub: mọi lối vào bấm vào đều mở màn thật, không có toast giả, không có trang trống.

### 5.2 Quyền nhân viên (cần một tài khoản nhân viên không phải chủ; bỏ qua nếu chưa có)
- [ ] Nhân viên mở **Giá vốn** → hiện "Chỉ chủ cửa hàng xem và công bố giá vốn."
- [ ] Nhân viên mở **Lãi gộp** → hiện "Chỉ chủ cửa hàng xem báo cáo lãi gộp."
- [ ] Nhân viên mở **Nhập hàng theo NCC** → hiện "Chỉ chủ cửa hàng xem báo cáo nhập hàng."
- [ ] Nhân viên mở **Báo cáo tồn**: không thấy cột Giá trị cuối kỳ.

### 5.3 Mất mạng khi ghi phiếu (tuỳ chọn)
1. Lập một phiếu nhận mới tới màn **Rà soát nhận hàng** (ví dụ NCC-B, Thuốc tẩy giun, lô `LW2`, HSD `06/12/2026`, SL nhận 1, giá 50000).
2. Tắt mạng máy → bấm **Ghi nhận**.
- [ ] Hiện "Chưa ghi nhận được do mất kết nối." kèm nút **Thử lại**.
3. Bật mạng → bấm **Thử lại**.
- [ ] Phiếu chỉ được ghi **một lần** (danh sách Nhận hàng có đúng 1 phiếu mới).
(Bước này làm thay đổi tồn Thuốc tẩy giun thêm 1; làm cuối cùng, sau mọi số liệu ở trên.)

---

## Ghi chú / lỗi tìm thấy

| Bước | Số kỳ vọng | Số thực tế | Ghi chú |
|---|---|---|---|
| | | | |
