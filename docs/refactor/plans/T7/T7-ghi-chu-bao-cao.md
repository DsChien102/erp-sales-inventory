# Theme 7 (Kho & Giá vốn): ghi chú chuẩn bị viết báo cáo

> Ghi chú nháp, gom từ các buổi kiểm tay và thảo luận. Chưa phải văn bản báo cáo. Mục nào đánh dấu **(cần kiểm)** là suy luận chưa kiểm chứng trên app/DB.

## 1. Giá vốn: tạm tính và chính thức

- **Giá vốn tạm** (bình quân di động): cập nhật ngay sau mỗi phiếu nhận, dùng để ghi giá vốn hàng bán trong tháng.
- **Giá vốn chính thức** (bình quân kỳ): cuối kỳ tính lại = (tồn đầu + nhập trong kỳ) / số lượng. Công bố giá vốn ghi các bút toán chênh lệch (COGS_TRUE_UP, LOSS_TRUE_UP, làm tròn) và tạo phiên bản chính thức.
- Lý do cần công bố dù đã tự tính sau mỗi lần nhập: giá vốn tạm của các đơn bán trước khi hàng sau về chưa phản ánh giá bình quân cả kỳ; công bố chốt một con số thống nhất để báo cáo lãi gộp.
- Với phương pháp MOVING, các điều chỉnh khi công bố xấp xỉ 0.

### 1.1 Khoản chênh khi công bố là gì

**Nguyên tắc:** tiền mua hàng = giá vốn (hàng đã bán) + giá trị kho (hàng chưa bán). Mỗi đồng tiền mua chỉ nằm ở một trong hai chỗ. Bán hết hàng thì toàn bộ tiền mua đã thành giá vốn.

Hai phương pháp đều là bình quân (tiền chia cho số lượng). Khác ở chỗ **lấy những lần nhập nào để chia**:
- **Liên hoàn:** chỉ các lần nhập **đã có trước lúc bán**. Tính được ngay lúc bán.
- **Cuối kỳ:** **tất cả** lần nhập trong kỳ, kể cả lần nhập **sau** khi đã bán. Phải đợi hết kỳ.

Vì vậy khi dùng cuối kỳ, app ghi giá vốn **tạm** theo liên hoàn lúc bán. Khi công bố, app tính lại theo giá chung của kỳ và chỉ ghi **phần chênh**. Chứng từ bán cũ không bị sửa.

**Khoản chênh không phải tiền thật.** Nó chỉ dời một phần tiền mua từ "kho" sang "giá vốn đã bán". Tổng không đổi.

### 1.2 Ví dụ minh hoạ (dùng được trong báo cáo)

Sữa hộp, giá bán 20.000/hộp.
- **Tháng 11:** ngày 1 nhập 10 × 10.000; ngày 5 bán 5; ngày 10 nhập 10 × 16.000; ngày 20 bán 5. Tổng mua 260.000, còn 10 hộp.
- **Tháng 12:** không nhập, bán nốt 10 hộp.

**Tháng 11 theo liên hoàn**

| Thời điểm | Kho | Bình quân | Giá vốn ghi |
|---|---|---|---|
| Ngày 1 nhập | 10 · 100.000 | 10.000 | |
| Ngày 5 bán 5 | 5 · 50.000 | 10.000 | 50.000 |
| Ngày 10 nhập | 15 · 210.000 | 14.000 | |
| Ngày 20 bán 5 | 10 · 140.000 | 14.000 | 70.000 |

Giá vốn 120.000, kho 140.000.

**Tháng 11 theo cuối kỳ:** giá chung = 260.000 / 20 = 13.000. Giá vốn đúng = 10 × 13.000 = 130.000, kho đúng = 130.000. So với số tạm ghi (120.000 / 140.000), công bố ghi **+10.000 vào giá vốn** và **−10.000 vào kho**.

Phân tách khoản chênh theo lần bán:
- Ngày 5: ghi 10.000, đúng là 13.000. Ghi thiếu 3.000/hộp → **+15.000**.
- Ngày 20: ghi 14.000, đúng là 13.000. Ghi dư 1.000/hộp → **−5.000**.
- Cộng: **+10.000**.

**Lãi qua hai tháng**

| | Liên hoàn | Cuối kỳ |
|---|---|---|
| Lãi T11 (doanh thu 200.000) | 80.000 | 70.000 (−10.000) |
| Kho mang sang T12 | 140.000 | 130.000 |
| Lãi T12 (doanh thu 200.000) | 60.000 | 70.000 (+10.000) |
| **Tổng lãi** | **140.000** | **140.000** |

Kiểm: tổng bán 400.000 − tổng mua 260.000 = 140.000.

**Kết luận:** phương pháp không làm tổng lãi khác đi. Nó chỉ quyết định phần chênh được tính vào lãi **tháng nào**. Cuối kỳ dồn vào tháng công bố; liên hoàn để trong kho, tính khi bán ở tháng sau.

### 1.3 Đối chiếu với lần tính thật (Nobivac, 11/2026)

Bình quân cuối kỳ = 20.700.000 / 200 = **103.500** (không gồm chiết khấu NCC; chiết khấu được để riêng cho hàng còn tồn).

| Lần xuất | SL | Giá tạm đã ghi | Giá chung | Chênh |
|---|---|---|---|---|
| S1 (bán 30, trả 5) | 25 | 100.000 | 103.500 | +87.500 |
| S3 | 100 | 101.052,02 | 103.500 | +244.797 |
| Hao hụt kiểm kê | 2 | 104.000 | 103.500 | −1.000 |
| **Cộng** | | | | **+331.297** |

| | "Đã bán" (xuất bán + hao hụt) | "Trong kho" (73 hộp) | Tổng |
|---|---|---|---|
| Trước công bố | 12.813.203 | 7.376.797 | 20.190.000 |
| Sau công bố | 13.144.500 | 7.045.500 | 20.190.000 |
| Thay đổi | +331.297 | −331.297 | 0 |

- Tồn cuối = 73 × 103.500 − 510.000 (chiết khấu) = 7.045.500. Giá chính thức mới = 7.045.500 / 73 = **96.514 đ/hộp**.
- Kiểm cân bằng: 0 + 20.700.000 − 510.000 = 12.937.500 + 207.000 + 7.045.500 = 20.190.000.
- Lãi T11 trên báo cáo giảm 331.297 so với liên hoàn. Khi bán 73 hộp còn lại, lãi các tháng sau cao hơn đúng chừng đó.

### 1.4 Chiết khấu NCC được chia thế nào (phần trọng tâm)

Sau khi công bố, giá vốn của **hàng đã bán tăng** trong khi giá vốn của **hàng còn tồn giảm**. Người xem dễ thấy mâu thuẫn ở đây. Nguyên nhân nằm ở cách mỗi phương pháp chia khoản chiết khấu đạt mốc.

**Bước 1: giá chung chưa tính chiết khấu.** 20.700.000 / 200 = 103.500/hộp, áp cho mọi hộp.

**Bước 2: chia chiết khấu 510.000.**

| | Liên hoàn | Cuối kỳ |
|---|---|---|
| Chia cho ai | Mọi hộp **đang có trong kho lúc ghi nhận** (173 hộp) | Chỉ hàng **còn tồn lúc chốt** (73 hộp) |
| Mỗi hộp được giảm | 510.000 / 173 = 2.948 | 510.000 / 73 = 6.986 |
| Giá sau giảm | 104.000 − 2.948 = **101.052** | 103.500 − 6.986 = **96.514** |
| Hàng bán sau đó (S3) | được hưởng một phần chiết khấu (bán với giá 101.052) | không được hưởng (tính lại 103.500) |

Theo spec giá vốn mục 5 và 12.4: với cuối kỳ, giá chung `P` **không** gồm chiết khấu `B`; toàn bộ `B` cộng vào giá trị tồn cuối (`closing_value_after = closing_qty × P + B`). Phần chiết khấu dành cho hàng đã bán được tính riêng **lúc ghi nhận chiết khấu** (`cogs_part`, chia theo `R × min(tồn, Q) / Q`) và báo ở lãi gộp, không đi qua lần tính giá vốn.

**Kết quả hai chiều, bù nhau:**

| | Trước công bố | Sau công bố | Lý do |
|---|---|---|---|
| 125 hộp đã bán | 100.000 / 101.052 | 103.500 (tăng) | Không hưởng chiết khấu, gánh giá chung cả tháng |
| 73 hộp còn tồn | 101.052 | 96.514 (giảm) | Nhận toàn bộ 510.000 chiết khấu |
| Tổng | 20.190.000 | 20.190.000 | Chỉ chia lại, không sinh thêm |

**Thứ tự thao tác quyết định số liệu.** Ghi nhận chiết khấu **trước** khi bán S3 (như lần kiểm này): kho lúc đó 173 ≥ mốc 100, nên toàn bộ 510.000 vào tồn, phần giảm giá vốn bằng 0. Ghi nhận **sau** khi bán S3 (kịch bản gốc, kho còn 73): 508.000 × 73/100 = 370.840 vào tồn, 137.160 giảm giá vốn hàng đã bán. Hai thứ tự cho ra kết quả công bố khác nhau (−331.297 / 96.514 so với −36.500 / 98.420), dù cùng dữ liệu nhập bán.

### 1.5 Những chỗ dễ hiểu nhầm (chuẩn bị câu trả lời khi bảo vệ)

1. **Giá vốn khác giá bán.** Giá vốn là tiền chủ cửa hàng bỏ ra cho một đơn vị hàng, chỉ chủ cửa hàng xem. Giá bán (Nobivac 150.000) do chủ cửa hàng tự đặt, công bố giá vốn không đổi giá bán.
2. **Khoản chênh không phải tiền lỗ hay tiền phát sinh.** Nó dời một phần tiền mua từ "giá trị kho" sang "giá vốn đã bán". Tiền thật (mua, bán) không đổi.
3. **Phương pháp không làm tổng lãi khác đi**, chỉ đổi lãi được tính vào **tháng nào** (ví dụ 1.2: hai tháng cộng lại cùng 140.000).
4. **Vì sao giá giảm mà giá vốn đã bán lại tăng:** chiết khấu dồn hết vào hàng còn tồn (mục 1.4).
5. **Vì sao cần "giá tạm":** lúc bán chưa hết kỳ, chưa biết giá chung, nên phải ghi tạm theo liên hoàn và bù khi công bố. Với liên hoàn thì không có giá tạm.
6. **Sau khi công bố:** giá chính thức (96.514) dùng cho các lần xuất sau, tới lần công bố kế tiếp; bình quân liên hoàn được đặt lại bằng giá trị sổ / tồn; phương pháp bị khoá.
7. **Hợp lệ về kế toán:** VAS 02 và Thông tư 200 / 133 cho chọn một trong hai phương pháp bình quân và yêu cầu áp dụng nhất quán, nên app khoá việc đổi phương pháp sau lần công bố đầu tiên.

## 2. Lãi gộp nằm ở module Kho

- Lãi gộp = doanh thu thuần − giá vốn sau điều chỉnh (`cogs_sale + cogs_adjust − chiết khấu nhà cung cấp`).
- Nằm ở Kho vì giá vốn chỉ Kho có (sổ kho, lô, giá nhập, chiết khấu). Hao hụt báo riêng, không trừ vào lãi gộp.

## 3. Ba loại chương trình nhà cung cấp

| Loại | Bản chất | Khi nào áp |
|---|---|---|
| TIER_DISCOUNT | Giảm giá theo bậc số lượng của **từng phiếu** | Ngay lúc nhận hàng |
| BUY_X_GET_Y | Mua X tặng Y | Ngay lúc nhận hàng |
| VOLUME_REBATE | Chiết khấu đạt mốc **tích luỹ nhiều phiếu** | Sau khi đạt mốc, bước "Ghi nhận chiết khấu" |

- Chương trình không có ngày hết hạn: chỉ kết thúc khi người dùng kết thúc thủ công.

### Vì sao chiết khấu đạt mốc không giảm trực tiếp vào giá nhập
- Lúc nhập lần 1 chưa biết chắc sẽ đạt mốc; khoản giảm chỉ chắc chắn khi đạt. Ghi nhận sau mới biết số tiền thực.
- Khi ghi nhận: phần chiết khấu chia theo tồn còn lại `R × min(tồn, Q) / Q`; phần hàng đã bán thì giảm giá vốn hàng bán (spec 12.4).

## 4. Tính năng G5-5c: gợi ý đạt mốc ở phiếu nhận

- Mục tiêu: lúc nhập thiếu mốc, người dùng thấy nếu nhập đủ thì được giảm bao nhiêu và giá vốn dự kiến, để chấp nhận lãi thấp ở lần nhập đầu.
- Làm **hoàn toàn trên UI**: dùng % của chương trình và đơn giá người dùng đang gõ; không đổi RPC, không ghi sổ.
- Công thức: ước tính = mốc × đơn giá × % / 100; giá vốn dự kiến = đơn giá × (1 − %/100).
- Ví dụ: mốc 100 hộp, 5%, giá 100.000 → giảm ≈ 500.000 đ, giá vốn dự kiến ≈ 95.000đ/hộp.
- Dòng banner ghi rõ "Dự kiến, chưa ghi sổ; chưa tính hàng đang tồn".

## 5. Số liệu mẫu đã kiểm tay

- Nobivac: ghi nhận chiết khấu 510.000 khi tồn 173 (trước khi bán đơn S3) → giá vốn bình quân 101.052, giá trị tồn 7.376.797.
- Thứ tự thao tác ảnh hưởng số liệu: ghi nhận chiết khấu trước hay sau khi bán quyết định phần đi vào tồn so với phần giảm COGS.
- Lần tính giá vốn 11/2026 theo bình quân cuối kỳ (chi tiết ở mục 1.3): điều chỉnh giá vốn xuất +331.297, giá trị tồn −331.297, giá chính thức Nobivac 96.514. Kịch bản gốc (bán S3 trước, ghi chiết khấu sau, 508.000) cho ra −36.500 và 98.420. Lệch do thứ tự thao tác và số tiền chiết khấu, không phải lỗi app. App đề xuất đúng 508.000 (5% × 10.160.000); người kiểm tự gõ tay 510.000 (có thể ghi số khác đề xuất, app cho phép).

## 6. Hạn chế đã biết (nên nêu khi bảo vệ)

1. Giá vốn bình quân không phân biệt lô hay nhà cung cấp.
2. Chia chiết khấu theo tồn còn lại là xấp xỉ.
3. Chương trình nhà cung cấp không có ngày hết hạn.
4. Bán hàng chưa chọn được lô cụ thể (FEFO tự chọn).
5. App chưa gợi ý giá bán từ giá vốn.
6. Ước tính ở phiếu nhận không tính hàng đang tồn nên giá vốn dự kiến chỉ là mức tham khảo.

## 7. Hướng phát triển

- Gợi ý giá bán từ giá vốn và biên lãi mục tiêu.
- Ngày hiệu lực/hết hạn cho chương trình nhà cung cấp.
- Tính giá vốn dự kiến có tính tồn hiện có.
- Cho chọn lô khi bán.

### Câu hỏi đang mở: có giữ hai phương pháp giá vốn không

- Khi kiểm tay, giá tạm và khoản chênh của bình quân cuối kỳ là phần khó hiểu nhất với người xem.
- Mục đích chính của phần giá vốn: cho chủ cửa hàng biết **một sản phẩm tốn bao nhiêu tiền**.
- Đề xuất: chỉ giữ **bình quân liên hoàn**. Giá gốc có ngay, mỗi sản phẩm một con số, không có giá tạm hay khoản chênh. VAS 02 và Thông tư 200 cho chọn một phương pháp, dùng nhất quán.
- Đánh đổi: phải sửa spec Theme 7 (BJ-14, KB-KGV-016), migration và các màn giá vốn, và phần báo cáo nói về hai phương pháp.
- Trạng thái: **đang hỏi ý kiến nhóm**, chưa quyết.

## 8. Ghi chú kiểm thử

- Test sinh ảnh vào `docs/`: xem mục 3.1 trong `T7-G5-5c-goi-y-dat-moc-o-phieu-nhan.md` (đã thêm cờ `CAPTURE_SCREENSHOTS=1`).
- G5-5c: 13 test mới (6 luật dựng chữ, 5 cubit, 2 banner); nhóm liên quan 60/60 xanh. 3 test golden ở màn khác còn đỏ, chưa rõ nguyên nhân **(cần kiểm)**.
- Kiểm tay G5-5c (mục 4 của plan) chưa làm.
