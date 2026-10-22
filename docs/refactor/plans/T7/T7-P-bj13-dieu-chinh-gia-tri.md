# T7-P · BJ-13 Điều chỉnh giá trị hàng nhập — thiết kế lại (bước B–E) + `SC_journey_2`

> Theme: Theme 7 Inventory · Trạng thái: Brief ✅ (duyệt 2026-10-21 — mục 0.10) | Plan C–E ✅ (viết cùng brief; **rà lại theo code sau khi BJ-03 xong**) | Làm ⬜ | Review ⬜
> Thuộc [T7-P](T7-P-thiet-ke-lai-luong.md) mục 8.2 **chặng 2 "Nhập hàng"**, BJ thứ ba (cuối chặng). Làm **sau** [BJ-02](T7-P-bj02-nhan-hang.md) và [BJ-03](T7-P-bj03-gia-nhap.md).
> Dùng lại K1, K3, K4, K7 (không cần cột chọn của `k7Table` — phạm vi do nguồn cố định). **Không dùng K2:** UC-13-01 không có bước duyệt, chỉ Owner ghi (sửa T7-P mục 9, trước ghi "K2, K3, K4").
> Thiết bị: **cả iPhone và web đều là thiết bị chính** (sửa 2026-10-22, T7-P mục 2). Bố cục iPhone thiết kế và kiểm như web, không chỉ "dùng được".
> Hết plan này = **hết chặng 2**: kịch bản `SC_journey_2` (mục 3.6) đi một mạch Home Kho → nhận hàng → duyệt → xác lập giá → điều chỉnh giá trị → về Home.
> Ước lượng: **~1,25 ngày, 2 commit** (C + D + `SC_journey_2`; E). Người làm: bạn. Review: phiên plan / review.

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/` nếu không ghi khác. Câu trong ngoặc kép là chữ hiển thị, chép nguyên văn; **(mới)** = chữ mới, vào T7-P mục 13 ở bước E.

## 0. Brief (bước B, đã duyệt 2026-10-21)

### 0.1 Việc thật

- **Ai, lúc nào:** Owner, vài lần / tháng, khi một khoản liên quan tới hàng **đã xác lập giá** về sau: hoá đơn vận chuyển, phí bảo hiểm, phí kiểm định, chiết khấu NCC gửi sau. Ngồi máy tính.
- **Cần biết / làm gì:** khoản này bao nhiêu (tăng hay giảm), áp vào những hàng nào, mỗi sản phẩm nhận bao nhiêu, ghi vào kỳ nào; ghi một lần để giá vốn tính lại (BJ-14).
- **Khoản đến từ nguồn** (Mua hàng / nguồn có thẩm quyền), không do Owner gõ tay: Owner chỉ xem phạm vi + cách phân bổ đã có và xác nhận. (Hướng sơ bộ ở T7-P mục 9 "nhập một khoản điều chỉnh" không đúng spec — bỏ.)
- **Quy tắc giữ** (BJ-13, UC-13-01, UIF-13 mục 5): chỉ cho fact phát sinh sau BJ-03, có nguồn ổn định; giữ nguồn / phiên bản, dấu `+/−`, phạm vi, phương pháp; **phạm vi cố định, không bỏ bớt sản phẩm**; `phân bổ_i = số tiền × chỉ số_i / Σ chỉ số`, chỉ số phải hợp lệ trên toàn phạm vi, tổng = 0 thì chặn, **không chia đều thay thế**; một phương pháp thì chỉ đọc, nhiều thì chọn có mô tả; chỉ hiện VND đã chuẩn hoá, không hiện / nhập tỷ giá; kỳ gốc đã khoá → ghi ở kỳ mở, giữ liên kết kỳ gốc; không sửa giá trị gốc; quyền lợi dự kiến không ghi; nhập sai đi BJ-11; ghi xong đánh dấu sản phẩm + kỳ cần BJ-14, không tự công bố giá vốn.

### 0.2 Luồng hiện tại

Ảnh: `tools/.golden-chang1/UIF-13_SCR-085_READY`, `…SCR-086_READY`, `SC_bj13_flow_4_open-confirm`, `…SCR-089_COMPLETED`; web `tools/.golden-chang1-web/UIF-13_*@web`.

```text
Hub → Giá trị kho → "Chi phí mua bổ sung" → 085 danh sách nguồn ─dòng→ 086 Phân bổ (nguồn, phạm vi, cách phân bổ,
  kết quả phân bổ, kỳ) ─"Ghi điều chỉnh"→ sheet "Ghi điều chỉnh giá trị?" ─"Xác nhận"→ 089 Kết quả ─"Về công việc điều chỉnh"→ 085
```

### 0.3 Vấn đề

| # | Màn | Vấn đề |
|---|---|---|
| 1 | Tên gọi | Hub và inspector gọi "Chi phí mua bổ sung" / "Ghi nhận chi phí phát sinh đến muộn" nhưng danh sách có cả khoản **giảm** (chiết khấu CK-2609-06 − 350.000 đ); spec gọi "Điều chỉnh giá trị hàng nhập" |
| 2 | 085 | Số tiền nhồi vào dòng phụ "Chi phí vận chuyển · Vận tải An Phát · + 1.200.000 đ"; nguồn chờ quy đổi hiện "**0 đ**" (sai nghĩa); dòng xử lý được không có badge; web là cột điện thoại |
| 3 | 086 | Sản phẩm liệt kê **hai lần** ("Phạm vi áp dụng" rồi "Kết quả phân bổ"); một phương pháp vẫn chiếm một khối; banner "Kỳ của hàng gốc đã khóa" và khối "Kỳ ghi nhận" nói cùng một việc; tổng phân bổ ở tận cuối |
| 4 | 086 | Câu lỗi có từ kỹ thuật: "Cần metric hợp lệ và so sánh được trên toàn phạm vi; hệ thống không tự chia đều." |
| 5 | 089 | "Giá vốn: Cần cập nhật" không có lối sang BJ-14; `UNKNOWN` không theo K3 (thiếu mã tham chiếu, thời điểm, "Về Kho") và có chữ tiếng Anh "Không ghi lại adjustment." |
| 6 | Trạng thái | Golden giống hệt `READY`: 086 `VALIDATION_ERROR`; 085 `EMPTY` / `FILTER_EMPTY` / `FINANCIAL_MASKED` |
| 7 | Fixture | Đích phân bổ của VC-8842 là Nobivac **50 hộp · 4.085.000 đ** + "Amoxicillin LA" — không khớp chặng 2 (sau BJ-03: Nobivac 121 hộp · 9.885.700 đ; Oxytetracycline LA chưa xác lập giá nên **không thể** là đích); CK-2609-06 đối tác Minh Dũng nhưng phạm vi là phiếu VietVet |
| 8 | Mã | Hai khối dựng (v430, v461); listener cũ của SCR-087 / 088 (`data-v430-val13-review` / `-confirm` / `-back`) và `val13ApplySourceUpdate` còn nhắc SCR-088 |

### 0.4 Đề xuất

**Luồng mới**

```text
Hub → Giá trị kho → "Điều chỉnh giá trị hàng nhập" → 085 (bảng nguồn: loại, đối tác, số tiền, số sản phẩm, tình trạng)
  ─nguồn có thể xử lý→ 086 (web hai cột: trái nguồn + cách phân bổ + kỳ; phải bảng phân bổ có dòng tổng)
      ─"Ghi điều chỉnh"→ sheet "Ghi điều chỉnh giá trị?" ─"Xác nhận"→ 089 Kết quả (K4) → "Cập nhật giá vốn" (BJ-14) / "Về công việc điều chỉnh"
  ─nguồn đang chờ→ 086 chỉ đọc: lý do chờ, không có nút ghi
```

*Tên gọi* (vấn đề 1)

1. Hub Giá trị kho: "Điều chỉnh giá trị hàng nhập" (tên màn 085, chữ spec) + phụ "Chi phí, chiết khấu phát sinh sau khi đã xác lập giá" **(mới)**; `FLOW_LABELS['UIF-13']` cùng tên.

*SCR-085 Điều chỉnh giá trị hàng nhập*

2. Chip có số: "Tất cả" · "Có thể xử lý" · "Đang chờ" (giữ chữ).
3. Dòng (iPhone): tiêu đề = mã nguồn ("Hóa đơn vận chuyển VC-8842"); phụ "{loại} · {đối tác}"; bên phải **số tiền có dấu** (mono, xanh / đỏ theo token tăng / giảm) + badge "Có thể xử lý" / "Đang chờ" (giữ chữ). Nguồn chưa có giá trị VND: thay "0 đ" bằng **"Chờ quy đổi" (mới)**.
4. Web: `k7Table` — Nguồn · Loại · Đối tác · Số tiền · Sản phẩm ("{n}") · Tình trạng.
5. `EMPTY` → `k1Empty({ title:"Không có khoản điều chỉnh nào" (mới), description:"Khoản phát sinh sau khi đã xác lập giá sẽ hiện ở đây." (mới) })`; `FILTER_EMPTY` → `k1Empty` + "Xem tất cả"; `LOADING` → `k1Loading`; `PERMISSION_DENIED` / `FINANCIAL_MASKED` / vai `staff` → `k1Denied({ what:"Bạn chưa có quyền điều chỉnh giá trị" (mới), next:"Chỉ chủ cửa hàng xem và ghi điều chỉnh giá trị." (mới) })`.

*SCR-086 Phân bổ điều chỉnh giá trị* (K7)

6. `k7Split`. **Trái:** thẻ nguồn (tên nguồn, loại · đối tác, liên kết "Xem chứng từ" **(mới)** mở tên tệp bằng chứng `evidence`); "Giá trị điều chỉnh" số lớn có dấu (giữ); "Cách phân bổ" (giữ): một phương pháp → **một dòng chỉ đọc** "Theo giá trị nhập ban đầu" + câu mô tả (giữ); nhiều phương pháp → `dsChoiceRow` từng phương pháp kèm mô tả; "Kỳ ghi nhận" (giữ) **gộp banner + khối thành một dòng**: kỳ gốc khoá → "Ghi vào kỳ {kỳ mở} · kỳ gốc {kỳ gốc} đã khoá" **(mới)**; kỳ gốc mở → "Ghi vào kỳ {kỳ}" **(mới)**.
7. **Phải:** một bảng duy nhất "Kết quả phân bổ" (giữ) — Sản phẩm · Phiếu nhận · Lô · Số lượng · "Giá trị nhập" **(mới, thay "Căn cứ phân bổ")** · "Tỷ trọng" **(mới)** · "Phân bổ" **(mới)**; dòng cuối "Tổng phân bổ" (giữ) = giá trị điều chỉnh. Bỏ khối "Phạm vi áp dụng"; chú thích dưới bảng "Phạm vi do nguồn xác định, không bỏ bớt sản phẩm được." **(mới)** (thay nhãn "Theo nguồn xác định").
8. iPhone: xếp dọc nguồn → giá trị → bảng (thành thẻ) → cách phân bổ → kỳ.
9. Chân "Ghi điều chỉnh" (giữ) → sheet "Ghi điều chỉnh giá trị?" (giữ) + câu giữ "Kiểm tra lại tổng tiền, phạm vi, cách phân bổ và kỳ ghi nhận trước khi ghi." + số liệu Nguồn · Giá trị điều chỉnh · Kỳ ghi nhận · "{n} sản phẩm" **(mới)**; "Quay lại" | "Xác nhận" (giữ); web là hộp thoại giữa màn (khuôn BJ-12).
10. `VALIDATION_ERROR` (UC-13-01: không có phương pháp hợp lệ / tổng chỉ số = 0): banner lỗi "Chưa có phương pháp phân bổ hợp lệ" (giữ) + mô tả **"Hàng trong phạm vi chưa đủ dữ liệu để chia theo cùng một cách. Hệ thống không tự chia đều." (mới, thay câu có "metric")**; bảng không có cột "Phân bổ"; nút ghi tắt kèm lý do.
11. `SOURCE_CHANGED`: banner "Nguồn điều chỉnh đã thay đổi" + "Kiểm tra lại dữ liệu hiện hành trước khi ghi." (giữ), số mới.
12. **Nguồn đang chờ** (UIF-13-T03: mở chỉ đọc): banner thông tin "Chưa thể xử lý" (giữ) + lý do `waitingOwner` (giữ chữ fixture, vd. "Chờ nguồn hoàn tất quy đổi giá trị"); không có bảng phân bổ, không có nút ghi.

*SCR-089 Kết quả điều chỉnh giá trị* (K4)

13. `COMPLETED`: `k4Result({ title:"Đã ghi điều chỉnh giá trị hàng nhập" (giữ; khoản giảm: "Đã ghi giảm giá trị hàng nhập" — giữ), description:"Điều chỉnh đã được ghi; sản phẩm liên quan cần cập nhật giá vốn." (giữ) })`; `facts`: Nguồn · Tổng điều chỉnh · Sản phẩm bị ảnh hưởng · Kỳ ghi nhận · Giá vốn "Cần cập nhật" (giữ); "Xem chi tiết phân bổ ({n})" (giữ).
14. Bước tiếp: phụ **"Cập nhật giá vốn"** (chữ của BJ-03) → BJ-14 `dirty-scope`; chính "Về công việc điều chỉnh" (giữ).
15. `UNKNOWN` → `k3Unknown({ operation:"Điều chỉnh giá trị hàng nhập", scope:"{nguồn} · {n} sản phẩm", ref, sentAt, sourceFlow:"UIF-13" })`; câu "Không ghi lại điều chỉnh. Chuyển đúng thao tác này sang xác minh." **(mới, thay "adjustment")** vào `safe`. `REJECTED_EXECUTION` → K4 cảnh báo "Chưa ghi điều chỉnh" + "Không có thay đổi giá trị." + "Xem lại phân bổ" (giữ) → 086 (UIF-13-T08). `PROCESSING` → `k1Loading`.

### 0.5 Trạng thái (sau thiết kế lại)

| Màn | Trạng thái | Hiện gì | Làm được gì | Lối ra |
|---|---|---|---|---|
| 085 | READY | bảng / danh sách nguồn, chip có số | mở nguồn, lọc, tìm | Về Kho |
| 085 | EMPTY / FILTER_EMPTY | `k1Empty` | "Xem tất cả" | Về Kho |
| 085, 086 | LOADING | `k1Loading` | — | — |
| 085, 086, 089 | PERMISSION_DENIED / FINANCIAL_MASKED | `k1Denied` | — | "Về Kho" |
| 086 | READY | nguồn + cách phân bổ + kỳ; bảng phân bổ | chọn phương pháp (nếu nhiều), "Ghi điều chỉnh" | Quay lại |
| 086 | nguồn đang chờ | "Chưa thể xử lý" + lý do | — | Quay lại |
| 086 | VALIDATION_ERROR | banner + bảng không có cột phân bổ | — | Quay lại |
| 086 | SOURCE_CHANGED | banner + số mới | "Ghi điều chỉnh" lại | Quay lại |
| 089 | PROCESSING | `k1Loading` | — | — |
| 089 | COMPLETED | K4 | "Cập nhật giá vốn", "Về công việc điều chỉnh" | Về Kho |
| 089 | REJECTED_EXECUTION | K4 cảnh báo | "Xem lại phân bổ" | Về Kho |
| 089 | UNKNOWN | K3 | "Chuyển sang xác minh" | "Về Kho" |

Alias giữ: 087 → 086, 088 → 086 (link cũ mở màn mới ở trạng thái mặc định).

### 0.6 Khuôn dùng lại (không dựng mới)

K1 (`k1Loading`, `k1Denied`, `k1Empty`, `k1ExitAttr`), K3 (`k3Unknown`), K4 (`k4Result`, `k4Footer`), K7 (`k7Split`, `k7Table`, lớp `k7-wide`), `dsChoiceRow` (nhiều phương pháp), sheet / hộp thoại của BJ-12. Không thành phần mới.

### 0.7 Không đổi

Quy tắc ở 0.1; `val13Engine` (dùng chung BJ-14), `val13Preview`, `val13PreviewHashOf`, `val13Commit`, `val13ApplySourceUpdate` (bỏ nhánh SCR-088); dấu và làm tròn phân bổ. Chữ giữ: tiêu đề 085 / 086 / 089, "Giá trị điều chỉnh", "Cách phân bổ", "Theo giá trị nhập ban đầu", "Kết quả phân bổ", "Tổng phân bổ", "Kỳ ghi nhận", "Ghi điều chỉnh", "Ghi điều chỉnh giá trị?", "Xác nhận", "Nguồn điều chỉnh đã thay đổi", "Chưa có phương pháp phân bổ hợp lệ", "Chưa thể xử lý", "Đã ghi điều chỉnh giá trị hàng nhập", "Đã ghi giảm giá trị hàng nhập", "Sản phẩm bị ảnh hưởng", "Tổng điều chỉnh", "Về công việc điều chỉnh", "Chưa ghi điều chỉnh", "Xem lại phân bổ".

### 0.8 Kiểm (bước D)

- Golden **mobile** được khác: `UIF-13_*`, `SC_bj13_*`, `SC_entry_UIF-13_*`, `SC_ws_valuation_*` (chữ dòng Hub), ca BJ-14 có đọc fixture BJ-13 qua `val13Engine` (kiểm `UIF-14_*`: **phải khớp** — nếu khác, ghi mục 8 và giải thích). Ca khác khớp mốc `tools/.golden-bj03-after`.
- Golden **web** được khác: `UIF-13_*@web` + kịch bản web; ca khác khớp `tools/.golden-bj03-web-after`.
- Kịch bản mới (mục 3.5): `SC_bj13_flow` (sửa), `SC_bj13_waiting`, `SC_bj13_decrease`, `SC_bj13_stale`, `SC_bj13_staff`, `SC_bj13_unknown`, **`SC_journey_2`** (mục 3.6).

### 0.9 Ước lượng C–E

~1,25 ngày: C ~0,6; `SC_journey_2` + Hub ~0,25; D ~0,2; E ~0,2.

### 0.10 Đã chốt khi duyệt brief (2026-10-21): **mọi điểm theo cột "Đề xuất"**

| # | Điểm | Đề xuất | Phương án khác |
|---|---|---|---|
| a | Tên trên Hub | **"Điều chỉnh giá trị hàng nhập"** (chữ spec, gồm cả tăng và giảm) | Giữ "Chi phí mua bổ sung" |
| b | Khoản điều chỉnh do ai tạo | **Chỉ từ nguồn** (theo spec); bỏ hướng "Owner nhập một khoản" ở T7-P mục 9 | Thêm "Ghi khoản mới" cho Owner (cần sửa UC-13-01 và nguồn có thẩm quyền) |
| c | Khối "Phạm vi áp dụng" | **Bỏ**, gộp vào bảng "Kết quả phân bổ" + chú thích phạm vi cố định | Giữ hai danh sách |
| d | Duyệt cho BJ-13 | **Không có** (UC-13-01 không có bước duyệt; chỉ Owner ghi) | Thêm K2 khi khoản lớn (cần quyết định nghiệp vụ mới) |

---

## 1. Mục tiêu

1. Owner thấy ngay khoản nào tăng / giảm bao nhiêu, mở một khoản là thấy mỗi sản phẩm nhận bao nhiêu và ghi vào kỳ nào, ghi một lần.
2. Mọi trạng thái ở 0.5 dựng khác nhau và có lối ra.
3. Chặng 2 chạy một mạch: `SC_journey_2` ở cả hai khung.

## 2. Chuẩn bị

1. BJ-03 đã xong (fixture R1 khớp BJ-02, `val03LastResult` có sau khi ghi). Rà lại mục 3.1 với code BJ-03 thật.
2. Mốc = `tools/.golden-bj03-after` / `tools/.golden-bj03-web-after`; nếu chưa có, chụp và so khớp HEAD.
3. Máy chủ `python3 -m http.server 8765 --bind 127.0.0.1 &` trong `html/`.

## 3. Bước C — dựng (commit 1)

### 3.1 Fixture (`app/bj13.js`)

1. LC13-001 (VC-8842, + 1.200.000 đ): đích = **Nobivac DHPPi** (`SP-000184`, PN-260816-04, lô DH2507, 121 hộp, giá trị nhập 9.885.700 đ) + **Vaccine Canine X** (PN-260821-03, 40 lọ, 4.010.000 đ, giữ). Bỏ đích "Amoxicillin LA".
2. Đồng bộ với phiên: hàm `val13SyncFromValuation()` (gọi khi vào 085 / 086) — nếu `val03LastResult` có nhóm cùng `code` + `receipt` với một đích, thay `qty` và `receivedValue` bằng số đã ghi ở BJ-03. Không có thì dùng số tĩnh ở mục 1 (đã khớp).
3. LC13-004 (CK-2609-06, − 350.000 đ): đổi đối tác thành "VietVet" cho khớp phạm vi PN-260902-07 (vấn đề 7).
4. LC13-003 (VC-8890, đang chờ): `normalizedAmount:null` giữ; hiện "Chờ quy đổi".
5. `grep -n "Amoxicillin\|SP-00142\|SP-00088" app/bj13.js app/bj14.js` — BJ-14 có đọc đích của BJ-13 qua `val13Engine` không; nếu có, chỉ đổi khi golden `UIF-14_*` vẫn khớp, không thì để BJ-14 giữ fixture riêng và ghi mục 8.

### 3.2 Màn

| Màn | Việc |
|---|---|
| Chung | Một khối dựng duy nhất; xoá listener SCR-087 / 088 (`data-v430-val13-review`, `-confirm`, `-back`) và nhánh `SCR-088` trong `val13ApplySourceUpdate`; đổi `data-v430-val13-*` / `data-v461-val13-*` → `data-bj13-*` (sửa `tools/golden.mjs`). `appShell({ …, extraClass:"k7-wide" })`; vai `staff` / `FINANCIAL_MASKED` / `PERMISSION_DENIED` → `k1Denied` |
| 085 | chip có số; `k7Table` cột 0.4 mục 4; `mobileRow` = `ds24ListRow` (tiêu đề nguồn, phụ "{loại} · {đối tác}", trailing số tiền có dấu + badge); `data-bj13-task="{id}"`; số tiền: `VAL_UI_461.signed`, `null` → "Chờ quy đổi" |
| 086 | `k7Split({ main: thẻ nguồn + giá trị + cách phân bổ + kỳ, aside: k7Table phân bổ + dòng tổng + chú thích })`; phương pháp: một → dòng chỉ đọc, nhiều → `dsChoiceRow` (`data-bj13-method="{id}"`); nguồn đang chờ / `VALIDATION_ERROR` / `SOURCE_CHANGED` theo 0.4 mục 10–12; chân `k4Footer([{ label:"Ghi điều chỉnh", attr:'data-bj13-open-confirm', primary:true, disabled }])` + dòng lý do khi tắt |
| Sheet xác nhận | khuôn sheet BJ-12; `data-bj13-confirm` / `data-bj13-confirm-close`; Escape đóng |
| 089 | `k4Result` / `k3Unknown` / K4 cảnh báo như 0.4 mục 13–15; "Cập nhật giá vốn" `data-bj13-go-cost` (cùng cách BJ-03 `data-bj03-go-cost`); "Về công việc điều chỉnh" `data-bj13-list`; "Xem lại phân bổ" `data-bj13-back` |

### 3.3 Sự kiện

1. `data-bj13-task` → `val13SelectedTaskId`, `val13ResetTaskDraft`, `val13SyncFromValuation()`, `navigate("SCR-086")` (nguồn đang chờ vẫn mở, chỉ đọc).
2. `data-bj13-open-confirm` → `val13ReviewSourceVersion = t.sourceVersion; val13PreviewHash = val13PreviewHashOf(t)`; mở sheet. `data-bj13-confirm` → kiểm phiên bản / hash như hiện có (`bj13.js:271`): lệch → đóng sheet, `SOURCE_CHANGED`; khớp → `val13Commit()`, `navigate("SCR-089")`.
3. `data-bj13-method` → đổi `selectedMethod` (chỉ phương pháp trong `allowedMethods`), xoá hash xem trước, render.

### 3.4 Hub và dọn dùng chung

1. `hub.js`: `valuation.items` UIF-13 → `title:'Điều chỉnh giá trị hàng nhập', subtitle:'Chi phí, chiết khấu phát sinh sau khi đã xác lập giá'`; `FLOW_LABELS['UIF-13']` cùng tên.
2. Sau BJ-03 và BJ-13: `grep -n "VAL_UI_430" app/*.js` — không còn chỗ dùng thì xoá `VAL_UI_430` khỏi `shared-valuation.js` (giữ `VAL_UI_461`, BJ-14 dùng). Còn thì để nguyên và ghi mục 8.

### 3.5 Golden (`tools/golden.mjs`)

Sửa `SC_bj13_flow` theo selector mới. Thêm (`V13` = gốc UIF-13 hiện có):

| Kịch bản | Bắt đầu | Bước |
|---|---|---|
| `SC_bj13_waiting` | `V13 + 'SCR-085'` | chip "Đang chờ" → VC-8890 → 086 "Chưa thể xử lý" → quay lại |
| `SC_bj13_decrease` | `V13 + 'SCR-085'` | CK-2609-06 → 086 (số âm) → "Ghi điều chỉnh" → "Xác nhận" → 089 "Đã ghi giảm giá trị hàng nhập" |
| `SC_bj13_stale` | `V13 + 'SCR-086'` | "Ghi điều chỉnh" → gọi `val13ApplySourceUpdate()` → "Xác nhận" → banner "Nguồn điều chỉnh đã thay đổi" |
| `SC_bj13_staff` | `V13 + 'SCR-085&entry=staff'` | — (thấy `k1Denied`) — thêm `entryTargets["UIF-13"].staff = { screen:"SCR-085" }` |
| `SC_bj13_unknown` | `V13 + 'SCR-089&state=UNKNOWN'` | "Chuyển sang xác minh" |

`WEB_SCENARIOS` thêm `SC_bj13_flow`, `SC_bj13_decrease`, `SC_journey_2`.

### 3.6 `SC_journey_2` — hết chặng 2

Bắt đầu `?mode=theme&app=inventory` (`T + 'inventory'`, kho đã kích hoạt). Vai: lối "Nhận hàng" đặt `module` (nhân viên lập); dòng "Chờ duyệt" đặt `approver` (BJ-02 mục 5.4); lối Giá trị kho đặt lại `module` (BJ-03 / BJ-13 chỉ chặn `staff`).

| Bước | Thao tác | Thấy |
|---|---|---|
| 0 | — | Home Kho đã kích hoạt; "Cần chú ý · Chờ duyệt" |
| 1 | "Nhận hàng" (nút nhanh) | 007 Nhận hàng: PN-260816-04, dòng "Hàng đến chưa có chứng từ" |
| 2 | PN-260816-04 | 009 "Đã xử lý 0/2 mặt hàng" |
| 3 | Nobivac DHPPi → mã lô "DH2507", HSD "30/11/2026", Đạt 121 → "Xong" | 009, Nobivac "121 / 120" + "Vượt chứng từ" |
| 4 | Oxytetracycline LA → "Nhận đủ 24 chai" → "Xong" | 009 "Đã xử lý 2/2 mặt hàng" |
| 5 | "Rà soát" | 010 "Cần chú ý · Vượt chứng từ: Nobivac DHPPi 121 / 120 hộp (+1)", nút "Gửi phê duyệt" |
| 6 | "Gửi phê duyệt" | 010 chờ duyệt (K2) |
| 7 | "Về Kho" → "Chờ duyệt" → dòng Minh Dũng | 011 "Duyệt nhận hàng PN-260816-04 của Minh Dũng?", chứng từ 120 · thực nhận 121 |
| 8 | "Duyệt" → chờ hết `PROCESSING` | 012 "Đã ghi nhận hàng", nút "Xác lập giá trị" |
| 9 | "Xác lập giá trị" | 015 PN-260816-04: Nobivac tick sẵn 9.885.700 đ; Oxytetracycline LA "Cần đối chiếu" |
| 10 | "Ghi giá trị (1)" → "Xác nhận giá trị" | 019 "Đã ghi giá trị nhập ban đầu", "Còn chờ giá trị · 1 sản phẩm" |
| 11 | Về Home (thanh bên "Kho" trên web / quay lại trên mobile, như `SC_journey_1` bước 9) → Quản lý kho → Giá trị kho → "Điều chỉnh giá trị hàng nhập" | 085, VC-8842 "+ 1.200.000 đ" |
| 12 | VC-8842 | 086: Nobivac "Giá trị nhập 9.885.700 đ", tổng phân bổ "+ 1.200.000 đ" |
| 13 | "Ghi điều chỉnh" → "Xác nhận" | 089 "Đã ghi điều chỉnh giá trị hàng nhập" |
| 14 | Về Home | Home Kho |

Chạy ở cả hai khung (`SC_journey_2@web` qua `WEB_SCENARIOS`). Nếu bước 7 cần đổi vai giữa chừng mà Hub chưa đặt được, gọi `window.__VET45_QA__.setActor('approver')` ngay trước bước 7 và ghi mục 8.

## 4. Bước D — kiểm

1. Golden mobile / web so mốc mục 2: chỉ ca ở 0.8 khác; ghi mục 8. Mọi trạng thái 0.5 cho ảnh khác nhau (`diff` thân `.txt`).
2. Bấm thử UIF-13 hai khung + Hub Giá trị kho: 0 lỗi JS; `node --check app/*.js harness/*.js`.
3. **`/impeccable audit` phạm vi UIF-13 — chặn commit E.** Chạy trên 085, 086 (một phương pháp, nguồn đang chờ, `VALIDATION_ERROR`, sheet xác nhận), 089 (`COMPLETED`, `UNKNOWN`), ở cả hai khung. Đạt khi: chữ ≥ 4,5:1 (số tiền xanh / đỏ trên nền trắng, badge); vùng chạm ≥ 44 × 44 ở iPhone; số tiền có dấu không chỉ phân biệt bằng màu (có "+" / "−"); web đi được bằng bàn phím (Tab qua bảng và nút, Esc đóng sheet, focus về nút đã mở). Lỗi trong phạm vi: sửa ngay; ngoài phạm vi: ghi mục 8.
4. **Hết chặng 2:** `SC_journey_2` 0 lỗi ở cả hai khung; Home Kho đã nối lối vào của BJ-02 (nút nhanh, "Chờ duyệt"), BJ-03 và BJ-13 (Giá trị kho) — T7-P mục 4.2b. **`/impeccable audit` chạy lại một lượt cho cả đường `SC_journey_2`** (chuyển màn giữa ba BJ, nút quay lại, thanh bên web).
5. Gửi ảnh: 085 web, 086 web + iPhone, sheet xác nhận, 089; `SC_journey_2` bước 0 / 5 / 7 / 9 / 12 / 13.
6. Mốc mới cho chặng 3: `tools/.golden-chang2`, `tools/.golden-chang2-web`.

## 5. Bước E — ghi lại (commit 2)

1. `CHANGELOG.md` `[5.10.0] — BJ-13 thiết kế lại; hết chặng 2 (SC_journey_2)`; phiên bản 5.10.0.
2. Viết lại theo `_TEMPLATE.md`: SCR-085, SCR-086 (gồm sheet xác nhận và trạng thái nguồn đang chờ), SCR-089; UIF-13 (sơ đồ mới; lối vào Hub; lối ra BJ-14 / BJ-17).
3. Sửa T7-P mục 9 BJ-13: khuôn "K1, K3, K4, K7" (bỏ K2), bỏ hướng "nhập một khoản".
4. `INDEX.md` 085–089; T7-P mục 13 (chữ mới), mục 14: BJ-13 ✅ và **`SC_journey_2` ✅**.
5. `python3 tools/sync-registry.py`.

## 6. Không làm

- Tạo khoản điều chỉnh bằng tay (0.10 b); mô phỏng quyền lợi dự kiến.
- Thiết kế lại BJ-14 (chặng 6).
- Ghi chú hoá đơn / tệp bằng chứng thật (prototype chỉ hiện tên tệp).

## 7. Rủi ro

| Rủi ro | Cách xử lý |
|---|---|
| Đổi đích LC13-001 làm golden BJ-14 khác | Mục 3.1 điểm 5: kiểm `UIF-14_*`; khác thì BJ-14 giữ fixture riêng |
| `val13SyncFromValuation` đổi số giữa lúc đã xem trước | Chỉ gọi khi vào 085 / 086, trước khi tạo hash xem trước |
| `SC_journey_2` dài, dễ vỡ khi một BJ đổi selector | Chỉ dùng `data-bj02-*` / `data-bj03-*` / `data-bj13-*` và `data-theme-*`, không dùng chữ |

## 8. Ghi chú khi làm

(Điền khi làm.)

## 9. Chữ trên màn

| Vị trí | Chữ |
|---|---|
| Hub | "Điều chỉnh giá trị hàng nhập" · "Chi phí, chiết khấu phát sinh sau khi đã xác lập giá" |
| 085 | chip "Tất cả" · "Có thể xử lý" · "Đang chờ" · cột "Nguồn", "Loại", "Đối tác", "Số tiền", "Sản phẩm", "Tình trạng" · "Chờ quy đổi" · "Không có khoản điều chỉnh nào" · "Khoản phát sinh sau khi đã xác lập giá sẽ hiện ở đây." |
| 086 | "Xem chứng từ" · "Ghi vào kỳ {kỳ mở} · kỳ gốc {kỳ gốc} đã khoá" · "Ghi vào kỳ {kỳ}" · cột "Sản phẩm", "Phiếu nhận", "Lô", "Số lượng", "Giá trị nhập", "Tỷ trọng", "Phân bổ" · "Phạm vi do nguồn xác định, không bỏ bớt sản phẩm được." · "Hàng trong phạm vi chưa đủ dữ liệu để chia theo cùng một cách. Hệ thống không tự chia đều." · "{n} sản phẩm" |
| 089 | "Cập nhật giá vốn" · "Không ghi lại điều chỉnh. Chuyển đúng thao tác này sang xác minh." |
| Không có quyền | "Bạn chưa có quyền điều chỉnh giá trị" · "Chỉ chủ cửa hàng xem và ghi điều chỉnh giá trị." |

## 10. Review

(Phiên review điền.)
