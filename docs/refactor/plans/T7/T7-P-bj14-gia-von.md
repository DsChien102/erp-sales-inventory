# T7-P · BJ-14 Tính và công bố giá vốn — thiết kế lại (bước B–E)

> Theme: Theme 7 Inventory · Trạng thái: Brief ✅ (duyệt 2026-10-26 — mục 0.10, mọi điểm theo đề xuất) | Plan C–E ✅ | Làm ✅ 2026-10-26 (v5.19.0, chưa commit) | Review ⬜
> Thuộc [T7-P](T7-P-thiet-ke-lai-luong.md) mục 8.2 **chặng 6 "Chốt kỳ"**, BJ thứ nhất. Làm **sau** chặng 5 (commit `5c2a1b0bf`, v5.18.1). BJ sau: [BJ-15](T7-P-bj15-bao-cao-the-kho.md) (cuối chặng, có `SC_journey_6` và `SC_demo` — hết Giai đoạn 2).
> Dùng lại K1, K3, K4, K6, K7 (+ `k2Attention`, `k4ReasonFooter`, `dsChoiceRow`, `t7ShowMoney` / `t7FmtMoney`). **Không K2** (công bố giá vốn không có bước duyệt trong spec — chủ cửa hàng tính và tự công bố). Không khuôn mới.
> Thiết bị: **cả iPhone và web đều là thiết bị chính** (T7-P mục 2). Chủ cửa hàng chốt kỳ thường ở máy tính đầu tháng, đôi khi trên iPhone.
> Ước lượng: **~2 ngày, 3 commit** (C0 + C1 fixture, 072, 074; C2 077, lối chéo + D; E). Người làm: bạn. Review: phiên plan / review.

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/` nếu không ghi khác. Câu trong ngoặc kép là chữ hiển thị, chép nguyên văn; **(mới)** = chữ mới, vào T7-P mục 13 ở bước E.

## 0. Brief (bước B, đã duyệt 2026-10-26)

### 0.1 Việc thật

- **Ai, lúc nào:** **chủ cửa hàng** (người duy nhất xem tiền — T7-P mục 2). **Mỗi tháng một lần** chốt giá vốn tháng trước (thường tuần đầu tháng sau, khi đã nhận đủ hoá đơn); **thỉnh thoảng giữa kỳ** cập nhật giá vốn cho vài sản phẩm vừa đổi giá trị (xác lập giá nhập BJ-03, điều chỉnh giá trị BJ-13, sửa phiếu nhận BJ-11) — nút "Cập nhật giá vốn" ở kết quả BJ-03 / BJ-13 dẫn vào đây.
- **Cần biết / làm gì:** kỳ nào; **còn việc gì chặn** và đi đâu để xử lý; tính xong thì giá trị tồn cuối, giá vốn xuất là bao nhiêu; **phần chênh lệch sẽ ghi** khi công bố; sản phẩm nào đổi giá vốn, từ bao nhiêu thành bao nhiêu; phương pháp là gì (một câu, không thuật ngữ trần) → công bố.
- **Quy tắc** (BJ-14, UC-14-01 BR-01…04, UC-14-04 BR-01…04): phương pháp lấy từ chính sách cửa hàng, **không chọn lại theo lần tính** (BR-01); tính song song hai phương pháp trên cùng dữ liệu, phương pháp không dùng chỉ để đối chiếu (BR-02); **lần tính bất biến** — dữ liệu đổi thì tạo lần tính kế tiếp, không sửa / hủy (BR-03); phạm vi "cập nhật trong kỳ" do hệ thống xác định (sản phẩm + kỳ + nguyên nhân), không phải người dùng chọn (BR-04); công bố chỉ ghi **phần chênh lệch**, không sửa chứng từ gốc (UC-14-04 BR-02, 03); giá vốn chính thức chỉ sinh ở BJ-14 (BR-04); có việc chặn hoặc đầu vào đổi thì không công bố được (JA-02); chốt kỳ chỉ hiện phạm vi chính sách cho phép, một lựa chọn thì chỉ đọc (JA-05); `UNKNOWN` không gửi lại, chuyển BJ-17.

### 0.2 Luồng hiện tại

Ảnh: `tools/.golden-chang5/UIF-14_*`, `SC_bj14_*`, `SC_ws_valuation_2_*`; web `tools/.golden-chang5-web/UIF-14_*@web`.

```text
Hub Giá trị kho → "Giá vốn" → 072 "Công việc giá vốn" (3 dòng cố định: "Chốt giá vốn 08/2026 · Sẵn sàng", "Cập nhật giá vốn · Cần tính lại", "Chốt giá vốn 09/2026 · Bị chặn") + chân "Chốt kỳ"
  dòng Sẵn sàng → 074 "Tính và rà soát giá vốn" (Phương pháp · Kết quả sau tính · Thay đổi sẽ ghi · "Xem đối chiếu…" · "Xem kết quả theo sản phẩm") → "Công bố giá vốn" → sheet → 077 (ioResult canh giữa) → "Về công việc giá vốn"
  dòng Cần tính lại → 074 dạng biểu mẫu "Cập nhật giá vốn" → "Tính lại giá vốn" → 074 kết quả (hẹn giờ 120 ms)
  dòng Bị chặn → 074 banner "Chưa thể chốt giá vốn" + 2 dòng "Đang chờ: Định giá tồn kho / Kiểm soát tồn kho" (không bấm được)
  "Chốt kỳ" → 074 biểu mẫu (ô chọn Kỳ, ô chọn Phạm vi) → "Tính giá vốn"
BJ-03 / BJ-13 kết quả → "Cập nhật giá vốn" → entry dirty-scope → 074 biểu mẫu
```

### 0.3 Vấn đề

| # | Màn | Vấn đề |
|---|---|---|
| 1 | 072 | Không theo K6 (không chip, không tìm, web là cột 402px); không có lịch sử kỳ đã công bố; phụ đề "Đã tính · 184 · chờ công bố" (thiếu danh từ); dòng "Cập nhật giá vốn" không nói **vì sao** cần tính lại; "Chốt kỳ" là nút chính dù kỳ cần chốt đã có lần tính |
| 2 | 074 | Một màn dựng năm kiểu khác nhau (biểu mẫu / đang tính / bị chặn / kết quả / dữ liệu đổi) không theo một câu chuyện; **"Phương pháp" đứng đầu** (thứ người dùng không quyết được) trong khi việc chặn, kết quả, chênh lệch mới là thứ cần đọc; "Bình quân cuối kỳ / liên hoàn" không giải thích; "Chính sách: Theo chính sách của tổ chức" lặp |
| 3 | 074 bị chặn | "Đang chờ: Định giá tồn kho / Kiểm soát tồn kho" (tên bộ phận kỹ thuật, cửa hàng 1–4 người không có); không có nút sang nơi xử lý (BJ-03, BJ-11, BJ-16); việc chặn là chữ cố định, không đọc từ dữ liệu các chặng trước |
| 4 | 074 kết quả | "Kết quả theo sản phẩm" bị gập sau `<details>`, iPhone chỉ thấy nửa dòng tiêu đề trên chân (ảnh `UIF-14_SCR-074_READY_FOR_REVIEW`); không có giá vốn cũ → mới theo sản phẩm (chỉ "Giá đề xuất" và "Chênh lệch ròng"); số tiền dạng "− 1.820.000 đ" có khoảng trắng sau dấu |
| 5 | 074 biểu mẫu | Ô chọn hệ thống cho Kỳ / Phạm vi; "Cập nhật giá vốn" không liệt kê sản phẩm và nguyên nhân (BR-04: hệ thống sở hữu nguyên nhân — nên **hiện** ra); hẹn giờ 120 ms mù |
| 6 | 077 | `ioResult` / `resultHero` canh giữa, không K4; `UNKNOWN` không theo K3; chỉ "Về công việc giá vốn" — không có bước tiếp sang báo cáo tồn (BJ-15) |
| 7 | Fixture | 184 sản phẩm, tiền tỷ đồng, ĐVT "lọ / viên / đôi", "Amoxicillin 500mg", "Găng tay khám" — lệch hẳn cửa hàng của chặng 1–5 (Nobivac DHPPi hộp 118.000 đ, Amox 500 hộp 42.000 đ…); bài học R2 chặng 5 |
| 8 | Quyền | Không có nhánh vai: nhân viên vào được (Hub "Giá trị kho" chỉ ẩn ở Home); tiền hiện với mọi vai |
| 9 | Mã | Hai khối IIFE (`v399` chuẩn hoá, `v461` dựng) + `VAL_UI_461`; helper gán muộn (`let val14RunSummary…`); `deniedBody` / `loadingBody` / `ioEmpty` / `ioResult`; nhãn `data-v461-val14-*`, `data-v350-action`; `renderers["SCR-073/075/076"]` trỏ 074; `Date.now()` trong mã lần tính (golden không ổn định nếu chụp ảnh lần tính mới) |

### 0.4 Đề xuất

**Luồng mới**

```text
Hub Giá trị kho → "Giá vốn" → 072 "Giá vốn" (K6: chip có số "Cần làm · Đã công bố")
  dòng "Chốt kỳ 08/2026 · Sẵn sàng công bố" → 074 (kết quả) → "Công bố giá vốn" → sheet → 077 (K4) → "Xem báo cáo tồn" (BJ-15) | "Về giá vốn"
  dòng "Cập nhật giá vốn 09/2026 · 3 sản phẩm" → 074 (chưa tính: sản phẩm + nguyên nhân) → "Tính giá vốn"
        → còn việc chặn → 074 bị chặn: mỗi việc một dòng có nút sang nơi xử lý (BJ-03 / BJ-11 / BJ-16)
        → không chặn → đang tính → 074 kết quả → công bố
  dòng "Đã công bố" → 077 chỉ đọc
BJ-03 / BJ-13 kết quả → "Cập nhật giá vốn" → 074 của lần cập nhật trong kỳ (như hiện tại, đúng lần tính)
```

*SCR-072 Giá vốn* (K6 — vấn đề 1)

1. Tiêu đề **"Giá vốn" (mới — chữ Hub; thay "Công việc giá vốn")**; phụ **"Chính sách: {phương pháp}" (mới)**. Không ô tìm (vài dòng mỗi năm). Chip có số **"Cần làm"** (mới) · **"Đã công bố"** (mới, 12 tháng gần nhất).
2. Dòng iPhone: tiêu đề **"Chốt kỳ {kỳ}" / "Cập nhật giá vốn {kỳ}" (mới)**; phụ theo tình trạng: **"{n} sản phẩm · đã tính, chờ công bố" / "{n} sản phẩm · {nguyên nhân rút gọn}" / "{k} việc cần xử lý" / "Công bố {ngày}" (mới)**; badge "Sẵn sàng công bố" (giữ) · "Cần tính lại" (giữ) · **"Cần xử lý" (mới — thay "Bị chặn")** · **"Chưa tính" (giữ)** · "Đã công bố" (giữ).
3. Web (K7): bảng **"Lần tính"** · **"Kỳ"** · "Phạm vi" · **"Chênh lệch sẽ ghi"** (tổng hai dòng điều chỉnh, chỉ dòng đã tính) · "Tình trạng".
4. `rowAttr` (K6): mọi dòng → 074 của lần tính (đúng trạng thái); "Đã công bố" → 077 chỉ đọc.
5. Chân: **bỏ "Chốt kỳ" thường trực** — chỉ hiện khi có kỳ đã kết thúc mà chưa có lần tính chốt kỳ (fixture: không có; trạng thái đặt từ ngoài `NEEDS_PERIOD_CLOSE` để dựng) — chữ **"Chốt kỳ {kỳ}" (mới)**. `EMPTY` → `k1Empty` "Không có công việc giá vốn" (giữ) / "Chưa có phạm vi cần cập nhật hoặc chốt kỳ." (giữ). `LOADING` / `PERMISSION_DENIED` → K1 (`what:` **"Bạn chưa có quyền xem giá vốn" (mới)**, `next:` "Chỉ chủ cửa hàng xem và công bố giá vốn." (mới)).

*SCR-074 Giá vốn {kỳ}* (một câu chuyện — vấn đề 2–5)

6. Tiêu đề **"{Chốt kỳ / Cập nhật giá vốn} {kỳ}" (mới — thay "Tính và rà soát giá vốn")**; phụ "{n} sản phẩm · Thời điểm chốt {cutoff}" (mới). Thứ tự khối cố định cho mọi trạng thái: **① Việc chặn → ② Kết quả → ③ Sẽ ghi khi công bố → ④ Theo sản phẩm → ⑤ Phương pháp** (khối chưa có thì bỏ, không dựng khung rỗng).
7. **Chưa tính** (`NOT_CALCULATED` — gộp biểu mẫu "Cập nhật giá vốn" / "Chốt giá vốn kỳ"): cập nhật trong kỳ → khối **"Sản phẩm cần tính lại" (mới)**: mỗi dòng "{sản phẩm}" + phụ nguyên nhân **"Xác lập giá nhập {mã phiếu}" / "Điều chỉnh giá trị {mã}" / "Sửa sai {mã phiếu}" (mới)** (BR-04 — hệ thống sở hữu, chỉ đọc); chốt kỳ → "Kỳ" + "Phạm vi" (`dsChoiceRow` nếu chính sách có nhiều phạm vi, một phạm vi thì dòng chỉ đọc — JA-05; bỏ ô chọn hệ thống). Chân "Tính giá vốn" (giữ).
8. **Việc chặn** (`BLOCKED`): `vBanner` warning **"Chưa công bố được" (mới — thay "Chưa thể chốt giá vốn")** + **"Xử lý {k} việc dưới đây rồi tính lại." (mới)**; mỗi việc một dòng **đọc từ dữ liệu các BJ khác** (mục 3 điểm 4) với nút chữ sang nơi xử lý: **"Mở hàng chờ xác lập giá trị"** (chữ BJ-08 043) → BJ-03 014 · **"Mở yêu cầu sửa sai"** (mới) → BJ-11 051 (chủ duyệt) · **"Mở hồ sơ"** (mới) → BJ-16 079. Bỏ "Đang chờ: {bộ phận}". Chân **"Tính lại" (mới)** (tạo lần tính kế tiếp — BR-03; tắt, lý do **"Còn {k} việc cần xử lý" (mới)** khi việc chặn vẫn còn).
9. **Đang tính** (`CALCULATING`): `k1Loading` + "Có thể rời màn hình. Kết quả được lưu trong cùng lần tính." (giữ). Prototype: xong bằng hẹn giờ có kiểm màn + `__VET45_QA__.finishBJ14Calc()` (như `finishCR16Recovery`), golden chờ có điều kiện.
10. **Kết quả** (`READY_FOR_REVIEW`): ② `cf12Strip` / dải số **"Giá trị tồn cuối {x} đ · Giá vốn xuất {y} đ" (giữ nhãn)**; ③ khối "Thay đổi sẽ ghi khi công bố" (giữ) + "Chỉ phần chênh lệch dưới đây được ghi; chứng từ lịch sử không bị sửa." (giữ) + "Điều chỉnh giá vốn xuất" / "Điều chỉnh giá trị tồn" (giữ) — số có dấu dính (**"−1.820.000 đ"**, `t7FmtMoney(n, true)`); ④ **"Theo sản phẩm" (mới — thay "Kết quả theo sản phẩm" + `<details>`)**: web bảng "Sản phẩm" · **"Giá vốn cũ"** · **"Giá vốn mới"** (mới) · "Chênh lệch" (giữ) — không gập; iPhone 3 dòng đổi nhiều nhất + nút **"Xem {n} sản phẩm" (mới)** mở sheet chỉ đọc; sản phẩm không có căn cứ mới: badge "Không đổi" (giữ); ⑤ **"Phương pháp" (giữ) — một dòng: "{phương pháp} — {giải thích một câu}" (mới)**: "Bình quân cuối kỳ — giá vốn mỗi sản phẩm là giá trung bình của tồn đầu kỳ và hàng nhập cả kỳ." / "Bình quân liên hoàn — giá vốn tính lại sau mỗi lần nhập." + "Theo chính sách của cửa hàng; không đổi theo lần tính." (mới — thay hàng "Chính sách: Theo chính sách của tổ chức"); "Xem đối chiếu theo {phương pháp kia}" (giữ) → sheet chỉ đọc (thay `<details>`). Chân "Công bố giá vốn" (giữ).
11. Sheet "Công bố giá vốn?" (giữ) + câu (giữ) + "Kỳ ghi nhận" · "Phạm vi" · "Phương pháp" · hai dòng điều chỉnh (giữ); "Quay lại" | "Công bố giá vốn" (giữ). Đầu vào đổi giữa lúc mở sheet và lúc bấm → đóng sheet, `INPUT_CHANGED`.
12. **Đầu vào đã đổi** (`INPUT_CHANGED`): `k1Stale({ title:"Dữ liệu đầu vào đã thay đổi" (giữ), description:"Kết quả cũ được giữ để truy vết nhưng không còn đủ điều kiện công bố." (giữ), actionLabel:"Tạo lần tính kế tiếp" (giữ) })`.
13. Web (K7): `k7Split({ wideMain:true })` — trái ①–④; phải khối "Tóm tắt" (chữ BJ-03): Kỳ · Phạm vi · Thời điểm chốt · Phương pháp · hai dòng điều chỉnh. `PERMISSION_DENIED` → K1 như điểm 5.

*SCR-077 Kết quả công bố* (K4 / K3 — vấn đề 6)

14. `COMPLETED` → `k4Result({ screenTitle:"Kết quả công bố giá vốn" (giữ), title:**"Đã công bố giá vốn {kỳ}" (mới — thêm kỳ)**, description:"Phần chênh lệch đã được ghi và giá vốn chính thức mới đã có hiệu lực." (giữ) })`; `facts`: "Kỳ ghi nhận" · "Phương pháp" · "Sản phẩm có giá vốn mới" (giữ) · "Điều chỉnh giá vốn xuất" · "Điều chỉnh giá trị tồn" · **"Công bố lúc" (mới — thay "Hiệu lực")**. Bỏ "Sản phẩm đã đối soát". Bước tiếp: phụ **"Về giá vốn" (mới — thay "Về công việc giá vốn")** | chính **"Xem báo cáo tồn" (mới)** → BJ-15 055 (báo cáo tồn, kỳ vừa công bố).
15. `REJECTED_EXECUTION` → K4 warning "Chưa công bố giá vốn" (giữ) + câu (giữ) + "Kỳ ghi nhận"; một nút "Về giá vốn". `UNKNOWN` → `k3Unknown({ operation:**"Công bố giá vốn" (mới)**, scope:"{Chốt kỳ / Cập nhật giá vốn} {kỳ}", ref:{mã lần tính}, sentAt, sourceFlow:"UIF-14" })` (thêm `BJ17_KIND["UIF-14"] = "Công bố giá vốn"`). `PROCESSING` → `k1Loading`. `PERMISSION_DENIED` → K1.

### 0.5 Trạng thái (sau thiết kế lại)

| Màn | Trạng thái | Hiện gì | Làm được gì | Lối ra |
|---|---|---|---|---|
| 072 | READY | K6 chip có số; danh sách / bảng | lọc, mở lần tính | Về Kho |
| 072 | NEEDS_PERIOD_CLOSE (mới, đặt từ ngoài) | như READY + chân | "Chốt kỳ {kỳ}" | Về Kho |
| 072 | EMPTY | `k1Empty` | — | Về Kho |
| 072…077 | LOADING / PERMISSION_DENIED | K1 | — | "Về Kho" |
| 074 | NOT_CALCULATED (mới — gộp hai biểu mẫu cũ) | sản phẩm + nguyên nhân / kỳ + phạm vi | "Tính giá vốn" | Quay lại |
| 074 | BLOCKED | banner + việc chặn có nút sang BJ khác | mở nơi xử lý; "Tính lại" (tắt khi còn việc) | Quay lại |
| 074 | CALCULATING | `k1Loading` | — | Quay lại |
| 074 | READY_FOR_REVIEW | ②–⑤ | "Công bố giá vốn" → sheet; "Xem đối chiếu", "Xem {n} sản phẩm" | Quay lại |
| 074 | INPUT_CHANGED | `k1Stale` | "Tạo lần tính kế tiếp" | Quay lại |
| 077 | COMPLETED | K4 | "Xem báo cáo tồn" | "Về giá vốn" |
| 077 | REJECTED_EXECUTION | K4 cảnh báo | — | "Về giá vốn" |
| 077 | UNKNOWN | K3 | "Chuyển sang xác minh" | "Về Kho" |
| 077 | PROCESSING | `k1Loading` | — | — |

### 0.6 Khuôn dùng lại

- K1, K3 (`k3Unknown`), K4 (`k4Result`, `k4ReasonFooter`, `k4Footer`), K6 (`k6TaskList`), K7 (`k7Split`, `k7Table`), `dsChoiceRow`, `cf12Strip`, `k2Attention` (khối việc chặn nếu hợp — hoặc danh sách dòng), `t7ShowMoney` / `t7FmtMoney`.
- Không thành phần DS mới.

### 0.7 Không đổi

Quy tắc ở 0.1; chính sách `__VET45_TENANT_COST_POLICY__` (phương pháp, phạm vi chốt kỳ); lần tính bất biến + lần kế tiếp (`supersedes`); kiểm `runInputHash` lúc công bố; `handoff-unknown` của UIF-14; entry `dirty-scope`. Chữ giữ: "Sẵn sàng công bố", "Cần tính lại", "Chưa tính", "Đã công bố", "Không có công việc giá vốn" + câu, "Tính giá vốn", "Có thể rời màn hình. Kết quả được lưu trong cùng lần tính.", "Giá trị tồn cuối", "Giá vốn xuất", "Thay đổi sẽ ghi khi công bố" + câu, "Điều chỉnh giá vốn xuất", "Điều chỉnh giá trị tồn", "Không đổi", "Phương pháp", "Bình quân cuối kỳ", "Bình quân liên hoàn", "Xem đối chiếu theo {phương pháp}", "Công bố giá vốn", "Công bố giá vốn?" + câu, "Kỳ ghi nhận", "Phạm vi", "Dữ liệu đầu vào đã thay đổi" + câu, "Tạo lần tính kế tiếp", "Kết quả công bố giá vốn", "Phần chênh lệch đã được ghi…", "Sản phẩm có giá vốn mới", "Chưa công bố giá vốn" + câu.

### 0.8 Kiểm (bước D)

- Golden **mobile** được khác: `UIF-14_*`, `SC_bj14_*`, `SC_entry_UIF-14_*`, `SC_ws_valuation_2_*` (Hub → "Giá vốn"), `SC_bj03_*` / `SC_bj13_*` **chỉ từ bước "Cập nhật giá vốn" trở đi** (bước trước phải khớp), `SC_journey_2` (nếu có bước sang BJ-14), **ca có số tồn Oxytetracycline LA / Tylosin TY2511 / Amox ở BJ-01 và Home** (đối chiếu số tồn ở mục 3 điểm 1 — đối chiếu từng dòng chữ khác chỉ là các số đó). Ca khác khớp mốc `tools/.golden-chang5` (v5.18.1).
- Golden **web**: như trên với `@web`; ca khác khớp `tools/.golden-chang5-web`.
- Kịch bản (mục 6): sửa `SC_bj14_flow`, `SC_bj14_dirty`, `SC_bj14_period`; thêm `SC_bj14_blocked`, `SC_bj14_published`, `SC_bj14_stale`, `SC_bj14_staff`, `SC_bj14_from_bj03`.

### 0.9 Ước lượng C–E

~2 ngày: C0 fixture ~0,25; C1 072 + 074 (năm trạng thái, việc chặn đọc dữ liệu thật) ~1; C2 077 + lối chéo + D ~0,5; E ~0,25. (T7-P mục 8.2 ghi 1,5 khi còn chia thiết bị chính / phụ.)

### 0.10 Đã chốt khi duyệt brief (2026-10-26): **mọi điểm theo cột "Đề xuất"**

| # | Điểm | Đề xuất | Phương án khác |
|---|---|---|---|
| a | Thứ tự khối 074 | **Việc chặn → Kết quả → Sẽ ghi → Theo sản phẩm → Phương pháp** (phương pháp xuống cuối, một dòng giải thích) | Giữ "Phương pháp" đầu màn như hiện tại |
| b | Việc chặn | **Đọc từ dữ liệu thật của BJ-03 / BJ-11 / BJ-16** (sản phẩm trong phạm vi còn hàng chờ giá, yêu cầu sửa sai chờ duyệt, hồ sơ đối soát chưa đóng), mỗi việc có nút sang nơi xử lý | Giữ chữ cố định, chỉ thêm nút |
| c | Nút "Chốt kỳ" ở 072 | **Chỉ khi có kỳ đã kết thúc chưa có lần tính** (fixture không có — dựng bằng trạng thái đặt từ ngoài) | Giữ nút thường trực |
| d | Lịch sử ở 072 | **Có** chip "Đã công bố" (12 tháng, mở 077 chỉ đọc) | Không — kỳ đã công bố biến khỏi danh sách |
| e | Kết quả theo sản phẩm | **Hiện luôn** (bảng web; iPhone 3 dòng + "Xem {n} sản phẩm"), có giá vốn cũ → mới | Giữ gập sau "Xem kết quả theo sản phẩm" |
| f | Fixture | **Cửa hàng của chặng 1–5**: sản phẩm / ĐVT / giá vốn theo BJ-01 + `BJ08_CATALOG`, tiền tính từ số lượng × giá (vài chục triệu, không tỷ) | Giữ số cũ (184 sản phẩm, tỷ đồng) |
| g | Bước tiếp sau công bố | **"Xem báo cáo tồn"** → BJ-15 (nối chặng 6) | Chỉ "Về giá vốn" |

---

## 1. Mục tiêu

1. Chủ cửa hàng đọc một màn theo đúng thứ tự việc: còn gì chặn → kết quả → sẽ ghi gì → công bố.
2. Việc chặn dẫn thẳng tới nơi xử lý (BJ-03 / BJ-11 / BJ-16), số liệu là của cửa hàng thật trong prototype.
3. Phương pháp giá vốn được giải thích bằng một câu, không đứng chắn đầu màn.
4. Chỉ chủ cửa hàng vào được; mọi trạng thái 0.5 dựng khác nhau và có lối ra, ở cả hai khung.

## 2. Chuẩn bị

> **Ba điểm dễ sai (đọc trước khi làm):**
> 1. **Sửa số tồn BJ-01 trước tiên** (mục 3 điểm 1): `app/bj01.js` khớp số sổ chặng 5 — Oxytetracycline LA 12 chai, Tylosin TY2511 3 lọ, Amox 46 + lô AM2505 2 (đổi Amox sang "theo lô" làm vỡ BJ-01 / BJ-09 thì giữ "không theo lô", ghi mục 9). BJ-14 tính tiền = số lượng × giá từ số này; làm sau thì phải chụp lại golden BJ-14.
> 2. **Golden UIF-14 mở bằng vai chủ cửa hàng** (mục 6): golden mặc định vào bằng vai nhân viên → mọi ca BJ-14 thành K1 "Bạn chưa có quyền xem giá vốn". Trong `tools/golden.mjs` cho nhóm ca UIF-14 dùng `entry=owner` (cách đã làm cho 046 / 051); vai nhân viên chỉ ở `SC_bj14_staff`.
> 3. **Chụp golden tuần tự**: `golden.mjs` dùng cổng Chrome cố định — chụp iPhone xong mới chụp web (`DEVICE=web`), không chạy hai lần chụp cùng lúc (chặng 5 đã lẫn ảnh vì chụp song song).

1. Chặng 5 đã commit (`5c2a1b0bf`). Góp ý chặng 5 còn mở không chặn plan này; nếu làm góp ý 2 (tone "Kết luận") / 1 (`wideMain`) trước thì dùng lại cách đó ở 074.
2. Mốc = `tools/.golden-chang5` / `-web` (v5.18.1, chụp lại sau R1–R3). Chụp lại ở HEAD, so "Khớp hoàn toàn"; lệch → chụp `tools/.golden-bj14-base` / `-web-base` và ghi mục 9. **Chụp tuần tự** (cổng Chrome cố định).
3. GitNexus (CLI `node .gitnexus/run.cjs impact <tên> --repo erp-sales-inventory --direction upstream`): `render072BJ14`, `render074BJ14`, `render077BJ14`, `val14CreateRun`, `val14Commit`, `bj14ApplyPolicy`, `val14EnrichRun`; báo mức rủi ro vào mục 9. `val14*` có thể được `shared-valuation.js` / BJ-03 / BJ-13 gọi — `grep` trước khi đổi tên.
4. Máy chủ `python3 -m http.server 8765 --bind 127.0.0.1 &` trong `html/`.

## 3. Fixture (`app/bj14.js`, bước C0)

1. **Sản phẩm và giá:** đọc danh mục từ BJ-01 (`bj01` sản phẩm: tên, mã, ĐVT) và giá vốn từ `BJ08_CATALOG` (`unitCost`): Nobivac DHPPi 118.000 đ/hộp, Amox 500 42.000 đ/hộp, Tylosin 20% 85.000 đ/lọ, Oxytetracycline LA 55.000 đ/chai, Găng tay khám Nitrile 65.000 đ/hộp; sản phẩm BJ-01 không có trong `BJ08_CATALOG` (vd. Enrofloxacin 10%) đặt giá vốn trong fixture BJ-14, ghi mục 9. **Làm trước:** đối chiếu số tồn BJ-01 với chặng 5 theo [plan BJ-15 mục 3 điểm 2](T7-P-bj15-bao-cao-the-kho.md#3-fixture-appbj15js-bước-c0) (Oxytetracycline LA 31 → 12 chai, Tylosin TY2511 7 → 3 lọ… — 0.10 g của plan BJ-15, duyệt cùng brief này) để BJ-14 tính tiền trên số đã khớp; ca golden BJ-01 / Home đổi do việc này ghi mục 9 và được phép khác (thêm vào 0.8). **Không hằng số tiền gõ tay cho tổng**: giá trị tồn cuối, giá vốn xuất, hai dòng điều chỉnh tính từ dòng sản phẩm (số lượng × giá) trong `bj14Totals(run)`.
2. **Lần tính** (`bj14Runs`, mỗi lần: `id`, `kind` `PERIOD_CLOSE | AD_HOC`, `period`, `cutoff`, `status`, `lines: [{ product, code, uom, qtyEnd, qtyOut, oldCost, newCost, cause? }]`, `supersedes`, `inputVersion`, `publishedAt`):
   - `COST-2608` · Chốt kỳ 08/2026 · `READY_FOR_REVIEW` · mọi sản phẩm BJ-01 · cutoff "31/08/2026 · 23:59" — đi công bố trong `SC_journey_6`.
   - `COST-2609-U1` · Cập nhật giá vốn 09/2026 · `NOT_CALCULATED` · 3 sản phẩm có nguyên nhân từ các chặng: **Nobivac DHPPi** "Xác lập giá nhập {mã phiếu BJ-03}" · **Amox 500** "Sửa sai PN-260904-08" (BJ-11) · sản phẩm có điều chỉnh giá trị ở BJ-13 (lấy sản phẩm BJ-13 có trong BJ-01; không có thì Tylosin 20% với mã điều chỉnh BJ-13 thật, ghi mục 9).
   - `COST-2607` · Chốt kỳ 07/2026 · `PUBLISHED` "05/08/2026 · 09:20" (chip "Đã công bố").
   - Bỏ `COST-0901-B` (Bị chặn cố định) — trạng thái chặn sinh từ dữ liệu (điểm 4).
3. Lần tính mới: mã `{id gốc}-R{n}` tăng dần (bỏ `Date.now()`), thời điểm cố định "17/09/2026 · 21:20" (sau mốc của chặng 5).
4. **Việc chặn** `bj14Blockers(run)` — đọc dữ liệu thật, chỉ sản phẩm trong phạm vi: (a) yêu cầu sửa sai `cr11Requests` `PENDING` có sản phẩm trong phạm vi → "Sửa sai {mã phiếu} đang chờ duyệt" → "Mở yêu cầu sửa sai"; (b) hồ sơ `cr16Cases` `OPEN` chạm sản phẩm → "Hồ sơ {mã} chưa đóng" → "Mở hồ sơ"; (c) dòng hàng chờ xác lập giá của BJ-03 có sản phẩm trong phạm vi → "{n} dòng hàng chưa có giá nhập" → "Mở hàng chờ xác lập giá trị". Fixture mặc định: `COST-2609-U1` có Amox → REC-260907-04 (`OPEN`) chặn → bấm "Tính giá vốn" ra `BLOCKED`; đóng hồ sơ ở BJ-16 rồi quay lại → "Tính lại" bật. Ghi mục 9 các nguồn không đọc được (vd. BJ-03 không có hàm đọc theo sản phẩm → thêm hàm nhỏ ở `bj03.js`).
5. `bj14Seed(screen, state)` như các BJ trước: 074 `READY_FOR_REVIEW` = `COST-2608`; `NOT_CALCULATED` / `BLOCKED` = `COST-2609-U1` (BLOCKED dựng từ việc chặn thật); `INPUT_CHANGED` = `COST-2608` đã tăng `inputVersion`; 077 `COMPLETED` = `COST-2608` sau công bố. Đi bằng nút thì không seed.

## 4. Bước C1 — 072, 074 (commit 1)

### 4.1 Dữ liệu và sự kiện

1. Viết lại `bj14.js` thành một khối (bỏ IIFE `v399` / `v461`, `VAL_UI_461`, helper gán muộn). Giữ tên `val14*` mà file khác gọi (kiểm `grep` ở mục 2.3), còn lại tiền tố `bj14`.
2. Quyền: `bj14CanView()` = `currentActor() === "owner" || "approver"` (dùng `t7ShowMoney()`); vai khác → `PERMISSION_DENIED` ở 072…077. Hub dòng "Giá vốn" gắn `data-theme-entry-actor="owner"` nếu Hub hiện đang vào bằng vai `module` (kiểm `SC_ws_valuation_2`; ghi mục 9).
3. Sự kiện: `data-bj14-filter`, `data-bj14-row`, `data-bj14-action="calculate" | "recalculate" | "open-publish" | "dialog-close" | "publish" | "successor" | "compare-open" | "products-open" | "to-list" | "to-report" | "close-period" | "to-valuation" | "to-correction" | "to-case"`. Sheet modal: Esc đóng, Tab vòng trong hộp thoại, focus về nút đã mở (cách `bj11Visible` — `getClientRects`).
4. Nút sang BJ khác đi qua `applyEntry` / `crSwitchFlow` (không sửa DOM BJ khác): BJ-03 014 (`applyEntry("UIF-03", …)` có sẵn?), BJ-11 051 (`__T7_DIRECT_CONTEXTS__["bj11-approval"](id)` + vai `approver`), BJ-16 079 (`cr16SelectedId` + `applyEntry("UIF-16", "case-context")`). Quay về: nút quay lại của BJ đích về Hub / màn đầu luồng đích là chấp nhận được; **không** thêm "Về giá vốn" ở BJ khác (mục 11).
5. Xoá mã chết (vấn đề 9): `renderers["SCR-073/075/076"]` (giữ `screenAliases` → 074), `deniedBody` / `loadingBody` / `ioEmpty` / `ioResult` / `resultHero` ở BJ-14, `val14MethodCard`, `val14Blockers`, `val14KindChoices`, `productSeed`, hash giả (`runInputHash` giữ một trường so sánh đơn giản), nhãn `data-v461-val14-*` → `data-bj14-*`. Sửa `tools/golden.mjs` theo nhãn mới.

### 4.2 Màn

| Màn | Việc |
|---|---|
| 072 | 0.4 điểm 1–5; `appShell({ extraClass:"k7-wide" })` |
| 074 | 0.4 điểm 6–13; bộ chọn trạng thái thêm `NOT_CALCULATED`; `PROCESSING` cũ (nếu còn trong bộ chọn) → `CALCULATING` |

## 5. Bước C2 — 077, lối chéo (commit 2, cùng D)

077 (0.4 điểm 14–15). Lối vào từ BJ-03 / BJ-13 ("Cập nhật giá vốn") mở 074 của `COST-2609-U1` đúng trạng thái hiện tại (không reset fixture khi đi bằng nút). "Xem báo cáo tồn" → `crSwitchFlow("UIF-15", "SCR-055", "READY")` — BJ-15 chưa thiết kế lại ở plan này thì mở màn cũ (chấp nhận, ghi mục 9; plan BJ-15 sửa đích). `BJ17_KIND["UIF-14"]`, `BJ17_SOURCE["UIF-14"] = "Giá vốn"`.

CSS: gom luật BJ-14 (`[data-active-uif="UIF-14"]`, `.val14-*`, `.v399-*`, `.v460-*` / `.v430-*` chỉ BJ-14 dùng — `golden.mjs usage` trước) về khối BJ-14 trong `styles/screens.css`; bỏ `!important` không còn đối thủ; bỏ luật cột 402px cho UIF-14.

## 6. Kịch bản golden (`tools/golden.mjs`, `S14 = '?uif=UIF-14&screen='`, vai mặc định của golden phải là chủ cho UIF-14 — nhóm `entry=owner` như 046 / 051)

Sửa: `SC_bj14_flow` (072 → `COST-2608` → "Xem 7 sản phẩm" → đóng → "Xem đối chiếu" → đóng → "Công bố giá vốn" → "Quay lại" → mở lại → "Công bố giá vốn" → 077 → "Về giá vốn" → chip "Đã công bố" có `COST-2608`), `SC_bj14_dirty` (`COST-2609-U1` → "Tính giá vốn" → `BLOCKED` có "Mở hồ sơ"), `SC_bj14_period` (072 `NEEDS_PERIOD_CLOSE` → "Chốt kỳ 09/2026"… nếu chính sách có hai phạm vi: chọn `dsChoiceRow` → "Tính giá vốn" → `__VET45_QA__.finishBJ14Calc()` → `READY_FOR_REVIEW`).

| Kịch bản | Bắt đầu | Bước |
|---|---|---|
| `SC_bj14_blocked` | `S14 + 'SCR-074&state=BLOCKED'` | "Mở hồ sơ" → BJ-16 079 REC-260907-04 (ảnh) |
| `SC_bj14_published` | `S14 + 'SCR-072'` | chip "Đã công bố" → `COST-2607` → 077 chỉ đọc |
| `SC_bj14_stale` | `S14 + 'SCR-074'` | mở sheet công bố → QA tăng `inputVersion` → "Công bố giá vốn" → `INPUT_CHANGED` → "Tạo lần tính kế tiếp" |
| `SC_bj14_staff` | `?uif=UIF-14&screen=SCR-072&entry=module` | K1 "Bạn chưa có quyền xem giá vốn" |
| `SC_bj14_from_bj03` | BJ-03 kết quả (ca có sẵn của `SC_bj03_*`) | "Cập nhật giá vốn" → 074 `COST-2609-U1` |

`WEB_SCENARIOS` thêm `SC_bj14_flow`, `SC_bj14_dirty`, `SC_bj14_blocked`. Chỉ dùng `data-bj14-*` / `data-theme-*` / `data-k*`.

## 7. Bước D — kiểm

1. Golden mobile / web so mốc mục 2: chỉ ca ở 0.8 khác; ghi mục 9. Mọi trạng thái 0.5 cho ảnh khác nhau, cả hai khung.
2. Bấm thử UIF-14 hai khung + Hub "Giá vốn" + BJ-03 / BJ-13 "Cập nhật giá vốn": 0 lỗi JS; `node --check app/*.js harness/*.js tools/golden.mjs`.
3. **Tiền / quyền:** vai nhân viên ở 072…077: K1, không "đ" trong HTML. **Tổng khớp dòng:** "Giá trị tồn cuối" = Σ dòng; điều chỉnh = Σ chênh lệch dòng (kiểm bằng `__VET45_QA__.getBJ14()` trong golden).
4. **`/impeccable audit` phạm vi UIF-14 — chặn commit E.** 072 (READY từng chip, EMPTY, NEEDS_PERIOD_CLOSE), 074 (năm trạng thái + sheet công bố, sheet sản phẩm, sheet đối chiếu), 077 (COMPLETED, REJECTED_EXECUTION, UNKNOWN), hai khung. Đạt khi: chữ ≥ 4,5:1 (badge, phụ đề, dòng lý do ở chân, nút chữ sang BJ khác); vùng chạm ≥ 44 × 44 ở iPhone; tăng / giảm không chỉ bằng màu (dấu "+" / "−"); số tiền mono căn phải, **không gãy dòng** (NBSP giữa số và "đ"); web: Tab ô / chip / bảng / nút chân, Enter mở / Esc đóng sheet, focus về nút đã mở; web không cột 402px; iPhone không bảng ép nhỏ. Lỗi trong phạm vi: sửa ngay; ngoài phạm vi: ghi mục 9.
5. Gửi ảnh: 072 web + iPhone, 074 `NOT_CALCULATED` iPhone, `BLOCKED` iPhone + web, `READY_FOR_REVIEW` web + iPhone (cuộn tới "Theo sản phẩm"), sheet công bố iPhone, 077 iPhone.
6. Mốc cho plan sau: `tools/.golden-bj14-after` / `-web-after`.

## 8. Bước E — ghi lại (commit 3)

1. `CHANGELOG.md` `[5.19.0] — BJ-14 thiết kế lại`; phiên bản 5.19.0 (`manifest.json`, `harness/workbench.js`, badge `index.html`, nhãn inspector UIF-14). Ghi trạng thái thêm / bỏ (`NOT_CALCULATED`, `NEEDS_PERIOD_CLOSE`; 074 `PROCESSING` nếu bỏ).
2. Viết lại theo `_TEMPLATE.md`: SCR-072, 074, 077, UIF-14 (sơ đồ: K6, một màn câu chuyện, việc chặn → BJ-03 / 11 / 16, 077 → BJ-15).
3. T7-P mục 9 BJ-14 ("Đã dựng"), mục 13 (chữ mới; việc chặn đọc dữ liệu; bỏ "Đang chờ: {bộ phận}"; Owner-only), mục 14: BJ-14 ✅. `INDEX.md` 072…077.
4. `python3 tools/sync-registry.py`.

## 9. Ghi chú khi làm

**Mốc và kiểm.** Mốc nền chụp ở HEAD (`5c2a1b0bf`) từ bản sao: `tools/.golden-bj14-base` (2016 ca) / `-web-base` (1134 ca) **khớp hoàn toàn** `tools/.golden-chang5` / `-web`. Sau làm: `tools/.golden-bj14-after` (2038 ca) / `-web-after` (1153 ca), 0 lỗi JS ở cả hai khung (mốc cho plan sau). Chụp tuần tự (iPhone rồi web). Chữ ở `.txt` khác mốc chỉ ở ca nêu dưới.

**GitNexus (upstream, `impact`):** `render072BJ14`, `render074BJ14`, `render077BJ14`, `val14CreateRun`, `val14Commit`, `bj14ApplyPolicy`, `val14EnrichRun` — LOW, 0 tiến trình; người gọi chỉ trong `bj14.js` (BJ-03 / BJ-13 chỉ gọi `applyEntry("UIF-14", "dirty-scope")`, giữ nguyên). `k6TaskList` (7 nơi gọi, đều truyền `search`) — chỉ thêm `search: null` + `caption`, tương thích ngược. `detect-changes`: 22 tệp, 0 tiến trình, mức thấp.

**Ca golden khác mốc (đều có chủ đích, 0.8):** `UIF-14_*` (+ `NEEDS_PERIOD_CLOSE`, 074 `NOT_CALCULATED`, 077 `PROCESSING`), `SC_bj14_*` (mới: `blocked`, `published`, `stale`, `staff`, `from_bj03`), `SC_entry_UIF-14_*`, `SC_qa_entry14`, `SC_ws_valuation_2` (Hub → "Giá vốn"), `SC_bj03_result` / `SC_bj03_from_receipt` / `SC_bj13_result` **chỉ bước "Cập nhật giá vốn"**; ca có số tồn BJ-01 / Home: `UIF-01_SCR-001_*`, `SC_bj01_*`, `SC_cap_*` (+ `CAP-01_SCR-062_*` web), `SC_bj02_from_bj01`, `SC_bj02_doc_full`, `SC_bj09_from_bj01` / `_expired_to_disposal`, `SC_bj12_approve` / `_pending_list`, `SC_journey_1`, `SC_quick_UIF-01`, `SC_search`, `SC_ws_inventory`, `SC_hf1_bj01_select`. Ca khác khớp mốc.

**Kiểm hành vi (script CDP riêng, hai khung, đạt hết):** tổng = Σ dòng (`getBJ14()`); DOM hiện đúng tổng; số tiền NBSP trước "đ" ở mọi màn; nhân viên ở 072 / 074 / 077 chỉ có K1, không có "đ"; sheet: focus vào hộp thoại, Esc đóng và trả focus về nút đã mở; Enter trên dòng bảng (web); công bố 2608 đổi giá chính thức, lần tính U1 lấy giá cũ mới; U1 → `BLOCKED` (REC-260907-04) → đóng hồ sơ → "Tính lại" bật → `COST-2609-U1-R1` → READY, danh sách chỉ hiện lần mới nhất; đầu vào đổi giữa lúc mở sheet và lúc bấm → `INPUT_CHANGED` → `COST-2608-R1`; BJ-03 "Cập nhật giá vốn" → 074 (vai chung thành chủ cửa hàng); mở hồ sơ → BJ-16 079; "Xem báo cáo tồn" → UIF-15 055; chốt kỳ (chọn phạm vi → tính → READY); hẹn giờ 1,5 s.

**`/impeccable audit` (phạm vi UIF-14, hai khung, 11 trạng thái + 3 sheet):** chữ ≥ 4,5:1 (0 lỗi), 0 tràn ngang, mọi nút có tên, bảng có `<caption>` + `th scope`, thứ tự Tab đúng (chip → dòng) có vòng focus. Sửa trong phạm vi: thêm vòng focus cho chip / dòng / thẻ chọn / nút sang BJ khác (DS chưa có); 077 các hàng nhãn dài xếp ngang cùng kiểu. Vùng chạm: nút 44 (chip 36 + vùng mở rộng 4 + 4 bằng `::after`). Ghi ngoài phạm vi: nút chân web cao 40 (quy tắc K7 chung, tiêu chí ≥ 44 chỉ iPhone); dòng bảng `<tr tabindex>` chưa có `role` (đã ghi ở "Sau Giai đoạn 2").

**Lệch so với plan (và lý do):**
1. **5 sản phẩm, không 7** ("Xem 5 sản phẩm"): lấy đúng 5 sản phẩm của BJ-01 (Nobivac, Amox, Enrofloxacin, Tylosin, Oxytetracycline LA); Dầu sát khuẩn không có giá vốn. Enrofloxacin giá vốn 96.000 đ đặt ở `BJ14_EXTRA_COST` (không có trong `BJ08_CATALOG`).
2. **`NEEDS_PERIOD_CLOSE` = kỳ 08/2026** (không 09/2026): kỳ 09 chưa kết thúc ngày 17/09; trạng thái dựng bằng cách bỏ `COST-2608`.
3. **Nguyên nhân của `COST-2609-U1`:** Nobivac → "Điều chỉnh giá trị LC13-ADJ-001-1" (sản phẩm BJ-13 có trong BJ-01 là Nobivac); Amox → "Sửa sai PN-260904-08"; **Oxytetracycline LA** → "Xác lập giá nhập PN-260816-04" (không phải Tylosin: hồ sơ REC-260907-07 của Tylosin sẽ chặn thêm).
4. **Việc chặn theo kỳ và theo loại:** chỉ việc thuộc kỳ của lần tính hoặc trước đó mới chặn (để chốt kỳ 08 không bị hồ sơ tháng 09 chặn); hồ sơ BJ-16 chỉ chặn loại ảnh hưởng giá trị (sửa phiếu gốc, sổ kho nghi sai, phiếu mua chưa khớp) — "số trên app lệch" và "báo cáo khác số tồn" không đổi sổ kho nên không chặn. Nhờ vậy mặc định `COST-2609-U1` chỉ có đúng một việc chặn (REC-260907-04, `SC_bj14_blocked`). Nguồn BJ-03: thêm `val03PendingLines(code)` ở `bj03.js`; chỉ chặn khi sản phẩm **chưa có giá vốn chính thức** (cả 5 sản phẩm đều có nên nguồn này chưa hiện ở dữ liệu mẫu).
5. **Amox giữ `tracking: "NONE"`** (48 = 46 + AM2505 2 cách ly): BJ-01 không có sản phẩm vừa theo lô vừa không; chỉ sửa `eligible` 47 → 46, `available` 42 → 41, cách ly 1 → 2. Tylosin: `physical` 18 → 14, TY2511 7 → 3, đặt giữ 3 → 1 (còn khả dụng 2, vẫn "Tồn thấp"). Oxytetracycline LA: 31 → 12 (cách ly 1, giữ 4, khả dụng 7).
6. **"Chênh lệch" theo sản phẩm** = tổng hai điều chỉnh của dòng (tồn cuối × Δgiá + xuất × Δgiá); tổng các dòng = hai dòng điều chỉnh ở ③.
7. **Tồn cuối 31/08 và xuất trong kỳ** là số fixture của BJ-14 (122 / 28 / 0 / 12 / 15); **plan BJ-15 phải dựng biến động tháng 08 cho cuối kỳ khớp các số này** (hoặc sửa `BJ14_T_0826`).
8. **Vai chung vào từ BJ-03 / BJ-13:** hai BJ này mở bằng vai chung (không phải nhân viên); entry `dirty-scope` đổi vai chung thành chủ cửa hàng, vai nhân viên vẫn gặp K1. Hub tile "Giá vốn" thêm `actor: 'owner'`.
9. **Hẹn giờ tính 1,5 s** (không 120 ms) để ca "Đang tính" chụp được; `finishBJ14Calc()` xong ngay.
10. **Dọn mã / CSS:** `bj14.js` viết lại một khối (bỏ IIFE `v399` / `v461`, `VAL_UI_461` bộ dựng, `renderers` 073 / 075 / 076, `Date.now()`, hash giả, `data-v461-val14-*` → `data-bj14-*`); `VAL_UI_461` chỉ còn `money` / `signed` / `pct` (BJ-13 dùng); `k6TaskList` thêm `search: null`; bỏ UIF-14 khỏi các danh sách chọn chung (cột 370 / 402 px) và các luật chết `val14-*`, `v399-*`, `v430-details`, `v460-*`; hàng nhãn — số tiền của UIF-14 tự định kiểu. Lần dọn đầu bằng regex làm hỏng một selector (`.v440-grouped-surface`) — làm lại bằng bộ tách luật CSS; golden các BJ khác (kể cả BJ-03 / 05 / 06 / 07 / 13) khớp mốc.
11. **Công cụ:** `tools/golden.mjs` nhóm UIF-14 mở bằng `entry=owner`; `compare` in dài qua đường ống (pipe) bị cắt — đọc kết quả qua tệp.

## 10. Thứ tự commit

1. C0 + C1 (fixture, 072, 074). 2. C2 + D (077, lối chéo, golden, sửa sau audit). 3. E. Làm một lượt thì để chưa commit cho phiên review xem trước. `detect-changes` trước mỗi commit (CLAUDE.md).

## 11. Không làm

- Đổi phương pháp giá vốn của cửa hàng (ngoài BJ-14 — JA-01).
- Màn chi tiết một sản phẩm trong lần tính (lịch sử giá vốn theo sản phẩm) — xem ở BJ-15 thẻ kho nếu cần.
- Lối "Về giá vốn" ở BJ-03 / BJ-11 / BJ-16 sau khi xử lý việc chặn (người dùng quay lại qua Hub; cân nhắc ở rà soát Giai đoạn 3).
- Thiết kế lại BJ-15 (plan sau) — "Xem báo cáo tồn" mở màn hiện có.

## 12. Rủi ro

| Rủi ro | Cách xử lý |
|---|---|
| Việc chặn đọc dữ liệu BJ khác làm ca golden phụ thuộc thứ tự chạy | `bj14Seed` dựng lại `cr11` / `cr16` gốc khi trạng thái đặt từ ngoài (gọi `bj11Restore` / `crRestore` có sẵn); ca đi bằng nút giữ dữ liệu |
| Đổi fixture làm đổi số tiền ở màn khác (BJ-03 / BJ-13 hiện giá vốn?) | `grep` `val14` / `COST-` ngoài `bj14.js`; số của BJ khác không đổi trong plan này |
| Golden vào UIF-14 bằng vai nhân viên → mọi ca thành K1 | Nhóm golden `entry=owner` cho UIF-14 (như 046 / 051); ca nhân viên riêng `SC_bj14_staff` |
| Hẹn giờ tính làm golden chập chờn | `finishBJ14Calc()` QA + golden chờ có điều kiện |

## 13. Chữ trên màn

| Vị trí | Chữ |
|---|---|
| 072 | "Giá vốn" · "Chính sách: {phương pháp}" · chip "Cần làm", "Đã công bố" · "Chốt kỳ {kỳ}" · "Cập nhật giá vốn {kỳ}" · "{n} sản phẩm · đã tính, chờ công bố" · "{n} sản phẩm · {nguyên nhân}" · "{k} việc cần xử lý" · "Công bố {ngày}" · badge "Cần xử lý" · cột "Lần tính", "Kỳ", "Chênh lệch sẽ ghi" · "Bạn chưa có quyền xem giá vốn" / "Chỉ chủ cửa hàng xem và công bố giá vốn." |
| 074 | "{Chốt kỳ / Cập nhật giá vốn} {kỳ}" · "{n} sản phẩm · Thời điểm chốt {cutoff}" · "Sản phẩm cần tính lại" · "Xác lập giá nhập {mã}" / "Điều chỉnh giá trị {mã}" / "Sửa sai {mã}" · "Chưa công bố được" / "Xử lý {k} việc dưới đây rồi tính lại." · "Mở yêu cầu sửa sai" · "Mở hồ sơ" · "Tính lại" · "Còn {k} việc cần xử lý" · "Theo sản phẩm" · "Giá vốn cũ" · "Giá vốn mới" · "Xem {n} sản phẩm" · câu giải thích hai phương pháp · "Theo chính sách của cửa hàng; không đổi theo lần tính." |
| 077 | "Đã công bố giá vốn {kỳ}" · "Công bố lúc" · "Về giá vốn" · "Xem báo cáo tồn" · K3 "Công bố giá vốn" |

## 14. Review

Review chặng 6 (BJ-14 + BJ-15) viết chung ở [T7-P-bj15-bao-cao-the-kho.md mục 14](T7-P-bj15-bao-cao-the-kho.md) (2026-10-26, **đạt có điều kiện**). Phần của BJ-14: golden `.golden-chang6` khớp hoàn toàn; ca khác `.golden-chang5` đều thuộc nhóm đã khai ở 0.8 / mục 9; nhân viên không có "đ" ở 072…077; `node --check` sạch. **R1 (nên sửa trước commit):** `qtyOut` của `BJ14_T_U1` (Nobivac 2, Amox 4) không khớp sổ kho BJ-15 tháng 09 (12 và 0) — **đã sửa ở v5.20.1** (12 / 0 / 3; `bj15Check` kiểm thêm tháng 09). Review đạt.
