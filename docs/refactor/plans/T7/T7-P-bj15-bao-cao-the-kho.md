# T7-P · BJ-15 Báo cáo tồn và thẻ kho — thiết kế lại (bước B–E) + `SC_journey_6` + `SC_demo`

> Theme: Theme 7 Inventory · Trạng thái: Brief ✅ (duyệt 2026-10-26 — mục 0.10, mọi điểm theo đề xuất) | Plan C–E ✅ | Làm ✅ 2026-10-26 (v5.20.0, chưa commit) | Review ⬜
> Thuộc [T7-P](T7-P-thiet-ke-lai-luong.md) mục 8.2 **chặng 6 "Chốt kỳ"**, BJ thứ hai và cuối. Làm **sau** [BJ-14](T7-P-bj14-gia-von.md) (077 "Xem báo cáo tồn" mở màn của plan này). **Hết plan này = hết chặng 6 và hết Giai đoạn 2**: `SC_journey_6` (mục 6.4) và `SC_demo` (luồng demo T7-P mục 10, mục 6.5).
> Dùng lại K1, K4, K6, K7 (+ `dsSegmented`, `cf12Strip`, `k7Table`, `t7ShowMoney` / `t7FmtMoney`). **Không K2** (báo cáo chỉ đọc). Không khuôn mới.
> Thiết bị: **cả iPhone và web đều là thiết bị chính** (T7-P mục 2). Chủ cửa hàng xem báo cáo nhập – xuất – tồn cuối tháng ở máy tính; nhân viên / chủ tra thẻ kho một sản phẩm ngay tại kệ bằng iPhone khi số trên app khác số đếm.
> Ước lượng: **~3 ngày, 4 commit** (C0 + C1 fixture, 055 báo cáo + thẻ kho; C2 056, xuất, lối chéo; C3 `SC_journey_6` + `SC_demo` + D; E). Người làm: bạn. Review: phiên plan / review.

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/` nếu không ghi khác. Câu trong ngoặc kép là chữ hiển thị, chép nguyên văn; **(mới)** = chữ mới, vào T7-P mục 13 ở bước E.

## 0. Brief (bước B, đã duyệt 2026-10-26)

### 0.1 Việc thật

- **Ai, lúc nào:** (1) **chủ cửa hàng cuối tháng** (sau khi công bố giá vốn ở BJ-14) xem **báo cáo nhập – xuất – tồn** của tháng: mỗi sản phẩm đầu kỳ, nhập, xuất, cuối kỳ, giá trị; đôi khi xuất tệp gửi kế toán. (2) **Bất kỳ ai, bất kỳ lúc nào** số trên app khác số ngoài kệ: mở **thẻ kho một sản phẩm** (từ Tồn kho BJ-01) để xem từng lần nhập / xuất, chứng từ nào, ai làm, còn bao nhiêu sau mỗi lần — rồi đi tiếp sang phiếu gốc hoặc sửa sai (BJ-11).
- **Cần biết / làm gì:** số liệu **đến thời điểm nào** (as-of); đang đọc theo **ngày nghiệp vụ hay ngày ghi nhận**; với một dòng biến động: chứng từ, người, lô, trước → sau; tiền chỉ chủ thấy.
- **Quy tắc** (BJ-15, UC-15-01…04 BR-01…06): chỉ đọc, dựa trên nhật ký biến động bất biến, **không sửa số dư từ báo cáo** (BR-01); báo cáo phải ghi rõ cut-off, thời điểm tạo, độ mới (BR-02); đọc theo ngày ghi nhận **hoặc** ngày nghiệp vụ, gắn nhãn rõ, không trộn ngầm (BR-03); quyền xem số lượng tách khỏi quyền xem giá trị (BR-04 — `FINANCIAL_MASKED`: không số tiền trong DOM); lô chỉ cho sản phẩm theo lô, **không tạo lô giả** cho sản phẩm không theo lô (BR-05); giá trị phân bổ theo lô / tình trạng (nếu có) phải gắn nhãn dẫn xuất (BR-06); xuất tệp giữ đúng phạm vi, quyền và mốc dữ liệu đang xem (UC-15-04).
- **Ranh giới:** BJ-15 không sửa gì; thấy sai thì **chuyển**: phiếu nghiệp vụ sai → BJ-11 (lối "Sửa sai" ở 056 — chốt ở plan BJ-11 0.10 d); số trên app lệch sổ → BJ-16 (ngoài plan — mục 11).

### 0.2 Luồng hiện tại

Ảnh: `tools/.golden-chang5/UIF-15_*`, `SC_bj15_*`, `SC_ws_history_0_*`, `SC_bj01_detail_*` (bước "handoff"); web `tools/.golden-chang5-web/UIF-15_*@web`.

```text
Hub Báo cáo & lịch sử → "Báo cáo tồn & thẻ kho" → 054 "Tra cứu kho" (biểu mẫu: Loại tra cứu · Kho · Sản phẩm · Cách hiểu thời gian · Từ ngày / Đến ngày) → "Xem báo cáo"
  → 055 "Báo cáo tồn kho" (Sản phẩm 3 · Kho · Tổng giá trị; 3 dòng sản phẩm) → dòng → sheet sản phẩm → "Xem thẻ kho" → 055 "Thẻ kho" (danh sách biến động)
       → dòng → 056 "Chi tiết biến động" → "Xem nguồn" → 057 "Nguồn nghiệp vụ" (dòng thời gian 3 bước) → "Xuất bằng chứng"
  "Xuất báo cáo" / "Xuất thẻ kho" → 058 (bảng "Phạm vi xuất") → "Xuất báo cáo" → 059 (PROCESSING 320 ms) → "Xong"
BJ-01 chi tiết sản phẩm → "Xem thẻ kho và lịch sử" → 054 (biểu mẫu trống — mất sản phẩm đang xem)
```

### 0.3 Vấn đề

| # | Màn | Vấn đề |
|---|---|---|
| 1 | 054 | Một biểu mẫu năm ô **trước khi thấy số nào** (Hub và BJ-01 đều vào đây); ô "Kho" chỉ một lựa chọn "Kho trung tâm" (app một kho); hai bộ radio lớn cho hai lựa chọn nhỏ; ô ngày `type=date` hai ô; `VALIDATION_ERROR` banner chung |
| 2 | 055 báo cáo | Không phải báo cáo nhập – xuất – tồn (chỉ tồn và khả dụng, không đầu kỳ / nhập / xuất); thẻ tổng "Sản phẩm 3 · Kho: Kho trung tâm"; "16.060.000 ₫" (ký hiệu ₫ khác "đ" của mọi màn); web cột 402px; không tìm / không bảng |
| 3 | 055 thẻ kho | Danh sách badge "+20 hộp" không có **tồn sau mỗi dòng** ở dạng thẻ kho quen thuộc (Ngày · Chứng từ · Nhập · Xuất · Tồn); không có đầu kỳ / cuối kỳ; sản phẩm theo lô không lọc được theo lô; vào thẻ kho phải qua sheet sản phẩm |
| 4 | 056 / 057 | Hai màn cho một dòng biến động; 057 "Dòng thời gian nguồn" chỉ in lại ba dòng của 056; "Xuất bằng chứng" là đường xuất thứ hai; không có lối sang **phiếu gốc** hay **sửa sai** (BJ-11) |
| 5 | 058 / 059 | Màn riêng chỉ để xác nhận phạm vi đã thấy ở 055; 059 hẹn giờ 320 ms; "Xong" về 055 / 057 tuỳ nguồn |
| 6 | Fixture | Nobivac "SP-00418" 118 hộp lô N2407-01 / N2408-02, Amox "SP-00128" lô L2407-A, "Găng tay M" SP-00602, người "Nguyễn An", chứng từ không có ở chặng nào — lệch hẳn BJ-01 (SP-000184, DH2507 70 / DH2509 50…) và chặng 2–5 (bài học R2 chặng 5) |
| 7 | Tiền | `FINANCIAL_RESTRICTED` là trạng thái đặt tay, không theo vai; vai nhân viên vẫn thấy "Tổng giá trị" ở `READY` |
| 8 | BJ-01 → BJ-15 | "Xem thẻ kho và lịch sử" mở 054 trống thay vì thẻ kho của đúng sản phẩm (`bj01.js` đặt `activeScreenId` thẳng, không qua `applyEntry`) |
| 9 | Mã | `bj15LegacyInventoryBody` / `bj15LegacyStockCardBody` / `bj15LegacyProductSheet` (nhánh trùng), `bj15Segmented` (`.cf-segmented`, thay bằng `dsSegmented`), `bj15ModeChoice`, `ac310SanitizeMarkup` mọi màn, `deniedBody` / `loadingBody` / `ioEmpty` / `ioResult`, nhãn `data-v360-action="fallback-exit"`, `data-action="v351-cf15-*"`, `setTimeout` 320 ms |

### 0.4 Đề xuất

**Luồng mới**

```text
Hub Báo cáo & lịch sử → "Báo cáo tồn & thẻ kho" → 055 "Báo cáo nhập – xuất – tồn" (kỳ mặc định: tháng hiện tại; bảng / danh sách sản phẩm)
  thanh lọc: kỳ ("Tháng 09/2026" → sheet chọn kỳ) · "Ngày nghiệp vụ | Ngày ghi nhận" · ô tìm · "Xuất tệp" (nút phụ → sheet)
  dòng sản phẩm → 055 thẻ kho "{sản phẩm}" (cùng thanh lọc; chip lô nếu theo lô) → dòng biến động → 056 "{loại} {chứng từ}" (gộp nguồn của 057)
       056 → "Sửa sai" (BJ-11 050 của đúng phiếu, nếu phiếu sửa được) · "Mở phiếu gốc" (BJ nguồn, nếu có màn)
BJ-01 chi tiết sản phẩm → "Xem thẻ kho và lịch sử" → thẻ kho của đúng sản phẩm (và lô đang xem)
BJ-14 077 → "Xem báo cáo tồn" → 055 báo cáo kỳ vừa công bố
"Xuất tệp" → sheet "Xuất báo cáo" → 059 kết quả (K4)
SCR-054, SCR-057, SCR-058 → RETIRED (gộp — 0.10 a, b, c)
```

*SCR-055 Báo cáo nhập – xuất – tồn / Thẻ kho* (vấn đề 1–3, 7)

1. **Bỏ 054 làm bước bắt buộc** (054 → RETIRED, "Bỏ từ v5.20.0"): mọi lối vào mở thẳng 055 với lọc mặc định (kỳ = tháng của ngày nghiệp vụ "17/09/2026" → **"01/09 – 17/09/2026"**, ngày nghiệp vụ). Bỏ ô "Kho".
2. **Thanh lọc** (chung hai chế độ, đầu màn): nút kỳ **"Tháng 09/2026" (mới)** mở sheet **"Chọn kỳ" (mới)**: chip "Tháng này" · "Tháng trước" · **"Tùy chọn" (mới)** (hai ô "Từ ngày" / "Đến ngày" (giữ) — lỗi tại ô **"Ngày bắt đầu phải trước ngày kết thúc" (mới)**, thay banner `VALIDATION_ERROR`); `dsSegmented` "Ngày nghiệp vụ | Ngày ghi nhận" (giữ chữ; thay `.cf-segmented`); dòng mốc **"Số liệu đến {as-of}" (mới — thay khối "Đến 07/09/2026 · 11:00")** (BR-02); `STALE` → `k1Stale` "Dữ liệu đang cập nhật" (giữ) + câu (giữ) + "Tải lại".
3. **Báo cáo** (mặc định): tiêu đề **"Báo cáo nhập – xuất – tồn" (mới — thay "Báo cáo tồn kho")**; ô tìm **"Tìm sản phẩm" (mới)**; web (K7) bảng **"Sản phẩm"** · **"Đầu kỳ"** · **"Nhập"** · **"Xuất"** · **"Cuối kỳ"** (mới) · "Khả dụng" (giữ) · **"Giá trị cuối kỳ"** (mới, chỉ chủ) — số mono căn phải, ĐVT ở cột sản phẩm (không cộng khác ĐVT — giữ ý "Không cộng các số lượng khác đơn vị thành một tổng giả."); iPhone dòng: tên + phụ **"Đầu {a} · Nhập {b} · Xuất {c}" (mới)** + phải **"{d} {ĐVT}"** (cuối kỳ); dòng tổng (chủ) **"Tổng giá trị cuối kỳ {x} đ" (mới — thay thẻ "Tổng giá trị", ký hiệu "đ")**. Bỏ thẻ "Sản phẩm 3 · Kho". Dòng → thẻ kho (bỏ sheet sản phẩm trung gian).
4. **Thẻ kho**: tiêu đề **"Thẻ kho" (giữ)**; phụ **"{sản phẩm} · {mã} · {ĐVT}" (mới)**; nút quay lại về báo cáo (hoặc về BJ-01 khi vào từ đó). Dải số `cf12Strip` **"Đầu kỳ {a} · Nhập {b} · Xuất {c} · Cuối kỳ {d}" (mới)**. Sản phẩm theo lô: chip **"Tất cả lô"** (mới) · "Lô {mã}" (một chip mỗi lô, có số); không theo lô: không chip, dòng **"Sản phẩm không quản lý theo lô." (giữ)** (BR-05). Web bảng **"Ngày"** · **"Chứng từ"** · **"Diễn giải"** · "Lô" · **"Nhập"** · **"Xuất"** · **"Tồn"** (mới) — dòng đầu **"Tồn đầu kỳ" (mới)**, dòng cuối **"Tồn cuối kỳ" (mới)**; iPhone dòng: **"{diễn giải} {chứng từ}"** + phụ "{ngày} · Lô {lô} · {người}" + phải "+{n}" / "−{n}" và **"Tồn {t}" (mới)**. Chủ: dòng **"Giá trị cuối kỳ {x} đ"** dưới dải số. Dòng biến động → 056. `EMPTY` / `FILTER_EMPTY` → `k1Empty` "Không có biến động trong kỳ" (giữ) / "Đổi khoảng ngày hoặc sản phẩm để xem dữ liệu khác." (giữ) + **"Xem tháng trước" (mới)**.
5. **Hai loại ngày (BR-03):** đổi công tắc thì cột / phụ đề đổi tên ("Ngày nghiệp vụ" ↔ "Ngày ghi nhận") và thứ tự dòng đổi theo ngày đó; dòng có hai ngày khác nhau hiện chấm **"Ghi nhận {ngày}" (mới)** ở phụ đề khi đang xem ngày nghiệp vụ (và ngược lại). Trạng thái `RECORDED_DATE_VIEW` / `BUSINESS_DATE_VIEW` giữ (đặt công tắc).
6. **Tiền theo vai (BR-04):** `t7ShowMoney()` thay `FINANCIAL_RESTRICTED` đặt tay — nhân viên không có cột / dòng giá trị, không "đ" trong DOM, **không banner** "Giá trị tài chính đã được ẩn" (bỏ — người không có quyền không cần biết có cột bị ẩn; ghi mục 13). `FINANCIAL_RESTRICTED` giữ trong bộ chọn = mở bằng vai nhân viên.
7. `ARCHIVED_DATA` → `vBanner` info **"Kỳ đã lưu trữ" (mới)** + **"Số liệu chỉ đọc, đến lúc lưu trữ {ngày}." (mới)**. `LOADING` / `PERMISSION_DENIED` → K1 (`what:` **"Bạn chưa có quyền xem báo cáo kho" (mới)**).
8. Web: `k7-wide`; thanh lọc một hàng; bảng chiếm hết bề rộng (không `k7Split` — một bảng).

*SCR-056 Chi tiết biến động* (gộp 057 — vấn đề 4)

9. Tiêu đề **"{loại} {chứng từ}" (mới — thay "Chi tiết biến động")** ("Nhận hàng PN-260904-08"); phụ "{sản phẩm} · Lô {lô}". Khối **"Số lượng" (giữ)**: "Trước" · "Biến động" · "Sau" (giữ) + "Lô" · "Tình trạng" (giữ); khối **"Thời gian và người thực hiện" (giữ)**: "Ngày nghiệp vụ" · "Ngày ghi nhận" · "Người thực hiện" (giữ); chủ: **"Giá trị" (giữ)** "Tác động" (giữ); khối **"Nguồn" (mới — gộp 057)**: dòng thời gian ba bước (giữ chữ 057: "{chứng từ}" / "Giao dịch nguồn được hoàn tất", "Đã ghi nhận kho" / {ngày ghi nhận}, "Tồn tăng / giảm {n} {ĐVT}" / "Số dư sau biến động: {n} {ĐVT}"). 057 → RETIRED; "Xuất bằng chứng" bỏ (xuất ở báo cáo).
10. Chân (chỉ khi có): **"Sửa sai" (giữ chữ BJ-11)** → BJ-11 050 của đúng phiếu (`applyEntry("UIF-11", "correction-from-movement")` mới, như `correction-from-case`; quay lại / "Về …" về 056) — chỉ khi chứng từ có trong `cr11Operations` và sửa được; **"Mở phiếu gốc" (mới)** (nút phụ) → màn của BJ nguồn nếu có (bảng mục 3 điểm 3; không có thì không hiện). `CONFLICT` → `k1Stale` "Nguồn nghiệp vụ vừa thay đổi" (giữ) + câu (giữ) + "Tải lại"; `LOCKED` → dòng chữ phụ "Dữ liệu đang ở chế độ chỉ đọc" (giữ) — ẩn "Sửa sai". SCR-056 của BJ-09 ("Lịch sử tình trạng") **không đổi** (dựng riêng ở `bj09.js`).

*Xuất báo cáo — sheet ở 055 + SCR-059* (vấn đề 5)

11. "Xuất tệp" (**mới** — nút phụ trên thanh lọc / cuối danh sách iPhone) → sheet **"Xuất báo cáo" (giữ)**: "Nội dung" ("Báo cáo nhập – xuất – tồn" / "Thẻ kho {sản phẩm}") · "Kỳ" · "Cách hiểu thời gian" · "Số liệu đến" · chủ: công tắc **"Kèm giá trị" (mới)** (nhân viên: không có dòng) · "Tệp: CSV" (giữ) + "Tệp xuất giữ đúng bộ lọc, khoảng ngày, quyền và mốc dữ liệu của kết quả đang xem." (giữ); "Quay lại" | "Xuất báo cáo" (giữ). 058 → RETIRED.
12. 059 → `k4Result({ screenTitle:"Kết quả xuất báo cáo" (giữ), title:"Đã tạo tệp báo cáo" (giữ), description: câu (giữ), facts: "Tệp" · "Số liệu đến" · "Giá trị tài chính" (giữ) })`; bước tiếp một nút **"Về báo cáo" (giữ chữ)**. `REJECTED_EXECUTION` / `SOURCE_STALE` → K4 warning (giữ chữ) + "Về báo cáo". `PROCESSING` → `k1Loading` (QA `__VET45_QA__.finishBJ15Export()` + hẹn giờ có kiểm màn, như `finishCR16Recovery`).

*Lối vào* (vấn đề 8)

13. BJ-01 "Xem thẻ kho và lịch sử" → `applyEntry("UIF-15", "stock-card", …)` với sản phẩm (và lô nếu đang xem lô) → 055 thẻ kho; quay lại về BJ-01 chi tiết sản phẩm. BJ-14 077 "Xem báo cáo tồn" → `applyEntry("UIF-15", "report", …)` với kỳ đã công bố. Hub → 055 báo cáo (tháng này).

### 0.5 Trạng thái (sau thiết kế lại)

| Màn | Trạng thái | Hiện gì | Làm được gì | Lối ra |
|---|---|---|---|---|
| 055 báo cáo | READY / BUSINESS_DATE_VIEW / RECORDED_DATE_VIEW | thanh lọc, bảng nhập – xuất – tồn, tổng giá trị (chủ) | đổi kỳ / loại ngày, tìm, mở thẻ kho, "Xuất tệp" | Về Kho |
| 055 thẻ kho | READY (+ hai loại ngày) | dải số, chip lô, bảng / dòng biến động | đổi kỳ / ngày / lô, mở dòng, "Xuất tệp" | Quay lại (báo cáo hoặc BJ-01) |
| 055 | FINANCIAL_RESTRICTED | như READY, không tiền (vai nhân viên) | như READY | như trên |
| 055 | EMPTY / FILTER_EMPTY | `k1Empty` | "Xem tháng trước" / "Xem tất cả" | như trên |
| 055 | STALE / ARCHIVED_DATA | `k1Stale` / banner info | "Tải lại" / — | như trên |
| 055…059 | LOADING / PERMISSION_DENIED | K1 | — | "Về Kho" |
| sheet kỳ | VALIDATION_ERROR (từ 054) | lỗi tại ô ngày | sửa ngày | "Quay lại" |
| 056 | READY / FINANCIAL_RESTRICTED | số lượng, thời gian – người, giá trị (chủ), nguồn | "Sửa sai" / "Mở phiếu gốc" (khi có) | Quay lại (thẻ kho) |
| 056 | CONFLICT / LOCKED | `k1Stale` / dòng chỉ đọc | "Tải lại" / — | Quay lại |
| sheet xuất | READY / STALE | phạm vi xuất | "Xuất báo cáo" | "Quay lại" |
| 059 | PROCESSING / COMPLETED / REJECTED_EXECUTION / SOURCE_STALE | `k1Loading` / K4 | — | "Về báo cáo" |

### 0.6 Khuôn dùng lại

- K1, K4 (`k4Result`, `k4Footer`), K6 (`k6TaskList` cho báo cáo — ô tìm + bảng; không chip), K7 (`k7Table`, lớp `k7-wide`), `dsSegmented` (**BJ-15 chuyển sang** — T7-P mục 5 ghi "BJ-15 còn"), `cf12Strip`, `t7ShowMoney` / `t7FmtMoney`, sheet modal theo cách `bj11` (Esc, Tab vòng, focus về nút mở).
- Không thành phần DS mới. Bảng thẻ kho dùng `k7Table` với dòng đầu / cuối kỳ (nếu `k7Table` chưa có dòng tổng: thêm tham số tùy chọn `footRows`, mặc định không đổi HTML — ghi mục 9).

### 0.7 Không đổi

Quy tắc ở 0.1; mọi màn chỉ đọc; `cf15Movements` là nguồn duy nhất cho số đầu / nhập / xuất / cuối (tính, không gõ tay); 056 của BJ-09. Chữ giữ: "Thẻ kho", "Ngày nghiệp vụ", "Ngày ghi nhận", "Từ ngày", "Đến ngày", "Khả dụng", "Sản phẩm không quản lý theo lô.", "Không có biến động trong kỳ" + câu, "Dữ liệu đang cập nhật" + câu, "Số lượng", "Trước", "Biến động", "Sau", "Lô", "Tình trạng", "Thời gian và người thực hiện", "Người thực hiện", "Giá trị", "Tác động", "Giao dịch nguồn được hoàn tất", "Đã ghi nhận kho", "Số dư sau biến động: {n} {ĐVT}", "Nguồn nghiệp vụ vừa thay đổi" + câu, "Dữ liệu đang ở chế độ chỉ đọc", "Xuất báo cáo", "Tệp xuất giữ đúng…", "Kết quả xuất báo cáo", "Đã tạo tệp báo cáo" + câu, "Giá trị tài chính", "Về báo cáo", "Sửa sai".

### 0.8 Kiểm (bước D)

- Golden **mobile** được khác: `UIF-15_*` (054 / 057 / 058 bỏ — ca `UIF-15_SCR-054_*`, `_057_*`, `_058_*` xoá, ghi CHANGELOG), `SC_bj15_*`, `SC_entry_UIF-15_*`, `SC_ws_history_*`, `SC_bj01_detail_*` / `SC_bj01_theme` **chỉ từ bước "Xem thẻ kho"**, `SC_bj14_flow` (bước "Xem báo cáo tồn"), `SC_journey_6`, `SC_demo`. Ca khác khớp `tools/.golden-bj14-after`.
- Golden **web**: như trên với `@web`; ca khác khớp `tools/.golden-bj14-web-after`.
- Kịch bản (mục 6): sửa / thay `SC_bj15_inventory`, `_stock_card`, `_sheet` (bỏ — sheet sản phẩm không còn), `_validation`, `_date_invalid`, `_export`, `_export_source` (bỏ — không còn xuất bằng chứng), `_export_denied`, `_restricted`, `_result_denied`, `_result_stale`; thêm `SC_bj15_report`, `SC_bj15_lot`, `SC_bj15_dates`, `SC_bj15_from_bj01`, `SC_bj15_correct`, `SC_bj15_staff`, `SC_journey_6`, `SC_demo`.

### 0.9 Ước lượng C–E

~3 ngày: C0 fixture + đối chiếu số tồn ~0,5; C1 055 (báo cáo + thẻ kho + thanh lọc + sheet kỳ) ~1; C2 056 (gộp nguồn, lối Sửa sai / phiếu gốc) + sheet xuất + 059 + lối vào BJ-01 / BJ-14 ~0,5; C3 `SC_journey_6` + `SC_demo` + D ~0,75; E ~0,25. (T7-P mục 8.2 ghi 1,5 cho BJ-15 khi chưa có `SC_demo` và hai thiết bị chính.)

### 0.10 Đã chốt khi duyệt brief (2026-10-26): **mọi điểm theo cột "Đề xuất"**

| # | Điểm | Đề xuất | Phương án khác |
|---|---|---|---|
| a | SCR-054 Tra cứu (biểu mẫu trước khi xem) | **Bỏ** (054 → RETIRED); lọc ở đầu 055, mặc định tháng này | Giữ 054, rút gọn còn loại + kỳ |
| b | SCR-057 Nguồn | **Gộp vào 056** (khối "Nguồn"); bỏ "Xuất bằng chứng" | Giữ 057 riêng |
| c | SCR-058 Xuất | **Sheet ở 055**; giữ 059 kết quả | Giữ 058 màn riêng |
| d | Báo cáo | **Nhập – xuất – tồn** (đầu kỳ, nhập, xuất, cuối kỳ, giá trị) | Giữ tồn + khả dụng như hiện tại |
| e | Lối từ 056 | **"Sửa sai" → BJ-11 050** (khi phiếu sửa được) + **"Mở phiếu gốc"** (khi BJ nguồn có màn) | Chỉ xem, không lối |
| f | Banner "Giá trị tài chính đã được ẩn" | **Bỏ** với vai nhân viên (không cột / dòng tiền, không báo) | Giữ banner |
| g | Số tồn lệch giữa BJ-01 và chặng 5 (mục 3 điểm 2) | **Sửa BJ-01 theo chặng 5** (Oxytetracycline LA 12 chai, Tylosin TY2511 3 lọ — câu chuyện kiểm kê cần số đó) | Sửa BJ-08 theo BJ-01 (đổi câu chuyện `SC_journey_5`) |
| h | `SC_demo` | **Một kịch bản** đi đúng tám bước T7-P mục 10, ghép các đoạn bước đã có của `SC_journey_1…6` (tách thành hằng trong `golden.mjs`) | Tám kịch bản `SC_demo_1…8` |

---

## 1. Mục tiêu

1. Thấy số ngay khi vào (không biểu mẫu trước); báo cáo là nhập – xuất – tồn chủ cửa hàng quen.
2. Thẻ kho một sản phẩm đọc như thẻ kho giấy (đầu kỳ → từng dòng có tồn sau → cuối kỳ), lọc theo lô, rõ loại ngày và mốc dữ liệu.
3. Mỗi dòng biến động truy được tới chứng từ và đi tiếp được sang sửa sai.
4. **Số khớp toàn prototype**: thẻ kho kể lại đúng các chứng từ của chặng 1–5, cuối kỳ = tồn ở BJ-01.
5. Hết Giai đoạn 2: `SC_journey_6` và `SC_demo` 0 lỗi ở cả hai khung.

## 2. Chuẩn bị

1. BJ-14 đã làm (plan BJ-14 mục 14, hoặc ít nhất D xong). Rà lại plan theo code BJ-14: `applyEntry` của "Xem báo cáo tồn", `bj14Runs` (kỳ công bố) — lệch ghi mục 9.
2. Mốc = `tools/.golden-bj14-after` / `-web-after`; lệch HEAD → chụp `tools/.golden-bj15-base` / `-web-base`. Chụp tuần tự.
3. GitNexus (CLI): `impact` upstream cho `render054BJ15`…`render059BJ15`, `bj15Movements`, `cf15ProductById`, `cf15Movement`, `render056BJ09` (không sửa — chỉ kiểm không ai gọi chéo), listener `data-bj01-handoff` (`bj01.js`); báo rủi ro vào mục 9.
4. Máy chủ `python3 -m http.server 8765 --bind 127.0.0.1 &` trong `html/`.

## 3. Fixture (`app/bj15.js`, bước C0)

1. **Sản phẩm** = danh mục BJ-01 (đọc từ `bj01` — tên, mã, ĐVT, theo lô, lô): Nobivac DHPPi SP-000184 (lô DH2507 70, DH2509 50), Amox 500 SP-000066, Enrofloxacin 10% SP-000091, Tylosin 20% SP-000122 (TY2408, TY2511), Oxytetracycline LA SP-000147. Không danh mục riêng trong `bj15.js` (bỏ `cf15Products`).
2. **Đối chiếu số tồn (0.10 g) — làm ở C0 của BJ-14** (BJ-14 tính tiền từ số BJ-01; plan BJ-14 mục 3 điểm 1); ở đây chỉ kiểm lại đã khớp. Hiện BJ-01 và chặng 5 lệch: Oxytetracycline LA BJ-01 31 chai / BJ-08 sổ 12; Tylosin TY2511 BJ-01 7 / BJ-08 3; Amox BJ-01 `tracking:"NONE"` 48 trong khi chặng 4 có lô AM2505 (2 hộp cách ly). Đề xuất: sửa BJ-01 (`physical` / `eligible` / `available`, lô) cho khớp số sổ chặng 5 trước khi điều chỉnh (Oxy 12, TY2511 3, Amox 46 + AM2505 2 = 48 — Amox chuyển `tracking:"LOT"` nếu BJ-01 / BJ-09 chịu được, không thì giữ NONE và ghi mục 9). Liệt kê ca golden BJ-01 / Home đổi ở mục 9.
3. **Biến động tháng 09/2026** (`cf15Movements`, mỗi dòng: `id`, `productId`, `lot`, `kind`, `doc`, `business`, `recorded`, `actor`, `delta`, `state`, `value`, `sourceFlow`, `sourceScreen?`, `opId?`) — **lấy chứng từ thật của các chặng**, số dư tính dồn từ tồn đầu kỳ, **cuối kỳ phải bằng số BJ-01 sau bước 2** (`bj15Seed` kiểm, sai thì `console.error` để golden bắt lỗi JS). Tối thiểu:

   | Sản phẩm | Chứng từ (chặng) | Ghi chú |
   |---|---|---|
   | Amox 500 | PN-260904-08 Nhận hàng +20 (BJ-02 / BJ-11 `IO-260904-021`) · ST-260906-04 Đổi tình trạng 2 hộp → cách ly AM2505 (BJ-09, Δ 0) · đơn bán BJ-05 (mã đơn thật) | dòng PN-260904-08 có "Sửa sai" (BJ-11 sửa được) |
   | Nobivac DHPPi | phiếu nhận BJ-02 (mã thật, lô DH2509) · bàn giao BJ-05 `SO-260827-21` −2 (DH2507) | dòng nhận hàng có "Mở phiếu gốc" → BJ-02 |
   | Oxytetracycline LA | SO-260902-19 Xuất bán −3 (BJ-11 `IO-260902-005`, "Đã giao khách" — **không** "Sửa sai") | |
   | Tylosin 20% | PN-260903-05 Nhận hàng TY2511 +5 (BJ-11 `IO-260903-017` — có nghiệp vụ phụ thuộc: **không** "Sửa sai") · bán 3 lọ TY2511 | |
   | Enrofloxacin 10% | xuất hết → cuối kỳ 0 (BJ-01 hết hàng) | |

   Chứng từ chặng 5 trong `SC_journey_5` (KK-260917-01, IO-260917-001) **không** thêm vào fixture tĩnh (xảy ra trong kịch bản) — mục 11.
4. **Người:** "Nguyễn Văn An", "Trần Thị Bình", "Chủ cửa hàng" (bỏ "Nguyễn An", "Trần Minh", "Lê Hoa"). **Mốc dữ liệu:** "17/09/2026 · 21:30" (sau chặng 5 và BJ-14). Giá trị: `unitCost` theo `BJ08_CATALOG` / BJ-14.
5. **Kỳ:** "Tháng 09/2026" (01/09 – 17/09) và **"Tháng 08/2026"** — tháng 8 cần đủ dữ liệu cho báo cáo (077 BJ-14 "Xem báo cáo tồn" mở kỳ vừa công bố là 08/2026): mỗi sản phẩm tồn đầu 01/08 + 1–2 dòng biến động, **cuối 31/08 = đầu 01/09**. `ARCHIVED_DATA` chỉ dựng bằng trạng thái; "Tùy chọn" theo hai ô ngày.
6. `bj15Seed(screen, state)`: 055 `READY` = báo cáo tháng này; thẻ kho đặt bằng `cf15Mode = "CARD"` + `cf15SelectedProduct`; 056 `READY` = dòng PN-260904-08 của Amox. Đi bằng nút thì không seed.

## 4. Bước C1 — 055 báo cáo + thẻ kho (commit 1)

### 4.1 Dữ liệu và sự kiện

1. Trạng thái: `cf15Mode` `"REPORT" | "CARD"`, `cf15Period` (`{ kind, from, to }`), `cf15DateMode`, `cf15Query`, `cf15Lot`, `cf15SelectedProduct`, `cf15Entry` (`hub | bj01 | bj14` — đích của nút quay lại). Bỏ `cf15ReportType`, `cf15Warehouse`, `cf15ProductSheetOpen`.
2. `bj15Ledger(productId, { from, to, dateMode, lot })` → `{ opening, inQty, outQty, closing, rows:[{ …, balance }] }` — một hàm tính cho báo cáo, thẻ kho, xuất tệp và kiểm cuối kỳ.
3. Sự kiện: `data-bj15-period-open`, `data-bj15-period="THIS|LAST|CUSTOM"`, `data-bj15-from` / `-to`, `data-bj15-date-mode` (dsSegmented), `data-bj15-search`, `data-bj15-product`, `data-bj15-lot`, `data-bj15-movement`, `data-bj15-action="export-open" | "export" | "dialog-close" | "apply-period" | "to-report" | "reload" | "correct" | "open-source" | "prev-month"`. Sheet modal theo cách `bj11` (Esc, Tab vòng, focus về nút mở).
4. Lối vào: `entryTargets["UIF-15"]` thêm `stock-card` (055 CARD) và `report` (055 REPORT, kỳ tham số); `bj01.js` listener `data-bj01-handoff` → `applyEntry("UIF-15", "stock-card", true)` sau khi đặt `cf15SelectedProduct` / `cf15Lot` (map `INV-*` → mã sản phẩm) — sửa một dòng ở `bj01.js`. `onPrevious["UIF-15"]`: 056 → thẻ kho; thẻ kho → báo cáo, hoặc `crSwitchFlow("UIF-01", "SCR-003", …)` khi `cf15Entry === "bj01"`.
5. Xoá mã chết (vấn đề 9): `render054BJ15` (đăng ký `screenAliases["UIF-15"]["SCR-054"] → "SCR-055"`), `bj15Legacy*`, `bj15Segmented`, `bj15ModeChoice`, `bj15ProductSheet`, `bj15ContextBanner`, `ac310SanitizeMarkup` ở BJ-15, nhãn `data-cf15-*` / `data-v360-action="fallback-exit"` / `data-action="v351-cf15-*"` → `data-bj15-*`. `.cf-segmented` còn ai dùng (`golden.mjs usage`) — không còn thì xoá CSS. Sửa `tools/golden.mjs`.

### 4.2 Màn

| Màn | Việc |
|---|---|
| 055 | 0.4 điểm 1–8; `appShell({ extraClass:"k7-wide" })`; bộ chọn trạng thái 055 giữ đủ mười trạng thái (054 `VALIDATION_ERROR` chuyển thành sheet kỳ mở sẵn có lỗi — ca golden riêng) |
| 054 | xoá khỏi `screens` của UIF-15 (bộ chọn, inspector `core.js` dòng 44); `screenAliases` → 055 |

## 5. Bước C2 — 056, xuất, lối chéo (commit 2)

1. 056 (0.4 điểm 9–10); 057 → `screenAliases` → 056, xoá `render057BJ15`. Lối "Sửa sai": `entryTargets["UIF-11"]["correction-from-movement"]` = 050, `onEntry` như `correction-from-case` nhưng ghi `cr11ReturnMovement = {id}` (thay `cr11ReturnCase`); BJ-11 050 quay lại / 053 nút phụ **"Về thẻ kho" (mới)** → `crSwitchFlow("UIF-15", "SCR-056", "READY")`. Sửa nhỏ ở `bj11.js` (một biến + hai nhánh) — `impact` trước.
2. "Mở phiếu gốc": bảng `BJ15_SOURCE_SCREENS` (`sourceFlow` → màn chỉ đọc có sẵn: BJ-02 SCR-013 kết quả nhận hàng, BJ-05 SCR-029, BJ-11 SCR-049…) — chỉ những màn mở được đúng chứng từ bằng `__T7_DIRECT_CONTEXTS__` / `onEntry` có sẵn; không có thì không hiện nút (ghi mục 9 các BJ thiếu).
3. Sheet xuất + 059 (0.4 điểm 11–12); 058 → `screenAliases` → 055 (mở sheet), xoá `render058BJ15`.
4. BJ-14 077 "Xem báo cáo tồn" → `applyEntry("UIF-15", "report", true)` với kỳ của lần tính (sửa đích ở `bj14.js`).

CSS (C1 + C2): gom luật BJ-15 (`[data-active-uif="UIF-15"]`, `.cf-*` chỉ BJ-15 dùng, `.ac310-*` của BJ-15) về khối BJ-15 trong `styles/screens.css`, bỏ `!important` không còn đối thủ, bỏ luật cột 402px cho UIF-15.

## 6. Golden (`tools/golden.mjs`, `S15 = '?uif=UIF-15&screen='`)

### 6.1 Mở thẳng

Bộ chọn: 054 / 057 / 058 bỏ; 055 mười trạng thái; 056 sáu; 059 năm. `FINANCIAL_RESTRICTED` = vai nhân viên; `READY` mở bằng vai chủ (nhóm golden `entry=owner` cho UIF-15, như UIF-14).

### 6.2 Kịch bản BJ-15

Thay `SC_bj15_*` cũ (mục 0.8) bằng:

| Kịch bản | Bắt đầu | Bước |
|---|---|---|
| `SC_bj15_report` | `S15 + 'SCR-055'` | tìm "amox" → xoá → "Ngày ghi nhận" → "Ngày nghiệp vụ" → dòng Nobivac (thẻ kho) → quay lại |
| `SC_bj15_lot` | thẻ kho Nobivac | chip "Lô DH2507" → "Lô DH2509" → "Tất cả lô" → dòng nhận hàng → 056 → "Mở phiếu gốc" |
| `SC_bj15_dates` | `S15 + 'SCR-055'` | "Tháng 09/2026" → "Tùy chọn" → từ 17/09 đến 01/09 → lỗi tại ô → sửa → áp dụng → "Tháng trước" → `EMPTY` → "Xem tháng trước" |
| `SC_bj15_from_bj01` | `?uif=UIF-01&screen=SCR-001` | sản phẩm Amox → "Xem thẻ kho và lịch sử" → thẻ kho Amox → quay lại → BJ-01 chi tiết Amox |
| `SC_bj15_correct` | thẻ kho Amox | dòng PN-260904-08 → 056 → "Sửa sai" → BJ-11 050 (số đúng trống) → quay lại → 056 |
| `SC_bj15_export` | `S15 + 'SCR-055'` | "Xuất tệp" → sheet → "Xuất báo cáo" → `finishBJ15Export()` → 059 → "Về báo cáo" |
| `SC_bj15_staff` | `S15 + 'SCR-055&entry=module'` | không "đ" (golden kiểm `__VET45_QA__`), thẻ kho, xuất (không dòng "Kèm giá trị") |
| `SC_bj15_result_stale`, `SC_bj15_result_denied` | như cũ | đổi nhãn |

### 6.3 Web

`WEB_SCENARIOS` thêm `SC_bj15_report`, `SC_bj15_lot`, `SC_bj15_from_bj01`, `SC_bj15_export`, `SC_journey_6`, `SC_demo`.

### 6.4 `SC_journey_6` — hết chặng 6

Chế độ Toàn Theme 7, **vai chủ cửa hàng** (`T + 'inventory&entry=owner'`), cả hai khung; helper `home(…)`, `chain(…)` như `SC_journey_5`.

| # | Bước | Thao tác | Thấy |
|---|---|---|---|
| 0 | (mở) | — | Home Kho |
| 1 | `valuation` → `cost` | Quản lý kho "Giá trị kho" → "Giá vốn" | 072, "Chốt kỳ 08/2026 · Sẵn sàng công bố" |
| 2 | `run` → `products` → `close-products` | dòng `COST-2608` → "Xem {n} sản phẩm" → đóng | 074 kết quả |
| 3 | `open-publish` → `publish` | "Công bố giá vốn" → "Công bố giá vốn" | 077 "Đã công bố giá vốn 08/2026" |
| 4 | `to-report` | "Xem báo cáo tồn" | 055 báo cáo kỳ 08/2026 |
| 5 | `this-month` → `nob` | kỳ "Tháng này" → dòng Nobivac | thẻ kho Nobivac |
| 6 | `lot` → `mv` | chip "Lô DH2507" → dòng bàn giao `SO-260827-21` | 056 "Bàn giao hàng …" |
| 7 | `back-card` → `back-report` → `export` → `confirm-export` → `finish` → `done` | quay lại ×2 → "Xuất tệp" → "Xuất báo cáo" → (QA xong) → "Về báo cáo" | 059 → 055 |
| 8 | `home-end` | về Home | Home Kho |

Kiểm: 0 lỗi JS, mỗi bước đổi màn đúng, quay lại / thanh bên không về nhầm màn con Hub; đổi luồng UIF-14 → UIF-15 giữ kỳ.

### 6.5 `SC_demo` — hết Giai đoạn 2 (T7-P mục 10)

Một kịch bản, cả hai khung, ghép đoạn bước đã có (0.10 h): tách các mảng bước của `SC_journey_1…6` thành hằng (`J1_OPEN`, `J2_RECEIVE`…), `SC_demo` = nối các đoạn đúng tám bước mục 10 với `home(…)` giữa các đoạn và đổi vai theo bảng (Owner / nhân viên → Owner): 1 khởi tạo tồn (BJ-12) → 2 tồn kho, mở sản phẩm tồn thấp (BJ-01) → 3 nhận hàng vượt 1 hộp, Owner duyệt từ "Cần chú ý" (BJ-02) → 4 xác lập giá (BJ-03) → 5 lấy hàng & bàn giao (BJ-05) → 6 kiểm kê, chênh lệch, duyệt (BJ-08) → 7 chốt kỳ, công bố (BJ-14) → 8 thẻ kho của sản phẩm ở bước 2 (BJ-15). Không thêm nhãn mới; nếu một đoạn không ghép được vì trạng thái fixture (vd. bước 1 cần kho chưa kích hoạt — `activation=pending`) thì mở đoạn đó bằng URL riêng trong cùng kịch bản và ghi mục 9. `SC_journey_1…5` **phải khớp mốc** sau khi tách hằng.

## 7. Bước D — kiểm

1. Golden mobile / web so mốc mục 2: chỉ ca ở 0.8 khác; ghi mục 9. Mọi trạng thái 0.5 cho ảnh khác nhau, cả hai khung.
2. Bấm thử UIF-15 hai khung + Hub "Báo cáo tồn & thẻ kho" + BJ-01 "Xem thẻ kho và lịch sử" + BJ-14 "Xem báo cáo tồn" + 056 "Sửa sai": 0 lỗi JS; `node --check app/*.js harness/*.js tools/golden.mjs`.
3. **Số:** với mọi sản phẩm, cuối kỳ thẻ kho = cuối kỳ báo cáo = tồn BJ-01 (kiểm tự động trong `bj15Seed` + một ca golden đọc `__VET45_QA__.getBJ15Ledger()`); đầu kỳ + nhập − xuất = cuối kỳ. **Tiền:** vai nhân viên không "đ" trong HTML 055 / 056 / sheet xuất / 059.
4. **`/impeccable audit` phạm vi UIF-15 — chặn commit E.** 055 (báo cáo, thẻ kho có lô / không lô, hai loại ngày, EMPTY, FILTER_EMPTY, STALE, ARCHIVED_DATA, vai nhân viên), sheet kỳ (+ lỗi), sheet xuất, 056 (READY chủ / nhân viên, CONFLICT, LOCKED, có / không "Sửa sai"), 059 bốn trạng thái, hai khung. Đạt khi: chữ ≥ 4,5:1 (phụ đề dòng, cột số, chip lô, dòng "Số liệu đến"); vùng chạm ≥ 44 × 44 ở iPhone (chip lô cuộn ngang, nút kỳ, dòng biến động); nhập / xuất không chỉ bằng màu (dấu "+" / "−" và cột riêng); số mono căn phải, số – ĐVT không gãy dòng; web: Tab ô tìm / nút kỳ / công tắc / bảng (dòng `<tr>` Enter mở) / nút chân, sheet modal; web không cột 402px; iPhone không bảng ép nhỏ (bảy cột thẻ kho → danh sách dòng). Lỗi trong phạm vi: sửa ngay; ngoài phạm vi: ghi mục 9.
5. **Audit dọc `SC_journey_6` và `SC_demo`** (bài học chặng 3): mọi bước, hai khung — tương phản, vùng chạm, tên nút, tràn ngang, nút quay lại, toast không che nút chân.
6. Gửi ảnh: 055 báo cáo web + iPhone, thẻ kho Nobivac web + iPhone (chip lô), 056 Amox PN-260904-08 iPhone (có "Sửa sai"), sheet kỳ iPhone (lỗi), sheet xuất web, 059 iPhone, `SC_journey_6` bước 3 + 5, `SC_demo` bước cuối.
7. Mốc hết chặng 6 / Giai đoạn 2: `tools/.golden-chang6` / `-web`.

## 8. Bước E — ghi lại (commit 4)

1. `CHANGELOG.md` `[5.20.0] — BJ-15 thiết kế lại; hết chặng 6 (SC_journey_6); SC_demo — hết Giai đoạn 2`; phiên bản 5.20.0 (`manifest.json`, `harness/workbench.js`, badge `index.html`, nhãn inspector UIF-15). Ghi màn / trạng thái bỏ (054, 057, 058) và số BJ-01 đổi (C0 điểm 2).
2. Viết lại theo `_TEMPLATE.md`: SCR-055 (báo cáo + thẻ kho + thanh lọc), SCR-056 (UIF-15: gộp nguồn, lối Sửa sai / phiếu gốc — phần BJ-09 giữ), SCR-059; SCR-054 / 057 / 058 → `RETIRED.md` ("Bỏ từ v5.20.0"); UIF-15 (sơ đồ: vào thẳng 055, BJ-01 / BJ-14 → 055, 056 → BJ-11); sửa liên kết UC-15-0x / use-case map / PAT-NAV tới tệp đã xoá (như chặng 5).
3. T7-P: mục 5 (dòng `dsSegmented`: "BJ-15 đã chuyển sang"); mục 9 BJ-15 ("Đã dựng"); mục 10 (`SC_demo` ✅); mục 13 (chữ mới; ba màn bỏ; bỏ banner ẩn giá trị; BJ-01 sửa số); mục 14 BJ-15 ✅, **chặng 6 `SC_journey_6` ✅, Giai đoạn 2 ✅**; mục 11 "Sau Giai đoạn 2" — ghi các góp ý còn mở của chặng 1–6 (toast 20 × 20, `onUnknownResolved`, `handoff-unknown`, bẫy focus chung, `<tr>` role) làm danh sách đầu vào cho Giai đoạn 3.
4. `INDEX.md` 054…059; `python3 tools/sync-registry.py` — **và xoá tay dòng registry của tệp đã xoá** (SCR-052 / 080 của chặng 5 — góp ý 6 — và 054 / 057 / 058), hoặc sửa `sync-registry.py` bỏ mọi đường dẫn không tồn tại (ghi mục 9).

## 9. Ghi chú khi làm

**Mốc và kiểm.** Mốc nền = `tools/.golden-bj14-after` (2038 ca) / `-web-after` (1153 ca) — khớp HEAD + BJ-14 chưa commit, không chụp `-bj15-base`. Sau làm: `tools/.golden-chang6` (**2164 ca**) / `-web` (**1280 ca**), 0 lỗi JS ở cả hai khung (hết chặng 6 / Giai đoạn 2). Chụp tuần tự. Ca khác mốc đều có chủ đích: `UIF-15_*` (054 / 057 / 058 bỏ), `SC_bj15_*`, `SC_entry_UIF-15_*`, `SC_ws_history_*` (Hub → UIF-15), `SC_bj01_detail` chỉ từ bước "Xem thẻ kho và lịch sử", `SC_journey_6`, `SC_demo`; `SC_journey_1…5` khớp hoàn toàn. Hai lần sửa giữa chừng nhờ so mốc: luật `.sheet-actions:has(> :only-child)` ban đầu để toàn cục làm nút "Đóng" của sheet CAP-01 / BJ-12 đổi bề rộng → giới hạn trong `body[data-active-uif="UIF-15"]`; sửa chữ `purpose` của SCR-056 trong `workbench-data` làm đổi inspector của ca BJ-09 → trả nguyên văn.

**GitNexus.** Chỉ mục cũ (commit `f7add97`, không thấy `k6TaskList` / `bj11*`); `gitnexus analyze` lỗi "Invalid UTF-8" (môi trường, không do thay đổi này). `impact` (upstream) với chỉ mục cũ: `render055BJ15` / `render056BJ15` / `render059BJ15` / `render056BJ09` LOW, 0 người gọi; `cf15ProductById` MEDIUM (5 người gọi, **tất cả trong `bj15.js`** vừa viết lại); `cf15Movement`, `bj15Movements` LOW (người gọi chỉ trong `bj15.js`). `detect_changes` (scope all): 40 tệp, 0 tiến trình, mức thấp. Người gọi chéo kiểm bằng `grep`: chỉ `bj01.js` (listener `data-bj01-handoff`) và `bj14.js` (`to-report`) — đã đổi sang `bj15OpenCard` / `bj15OpenReport`; không ai gọi chéo `render056BJ09`.

**Kết quả D.** Số: `bj15Check` (lúc nạp) + ca `SC_bj15_report` bước `check` — cuối kỳ thẻ kho = cuối kỳ báo cáo = tồn BJ-01 cho cả năm sản phẩm, đầu + nhập − xuất = cuối, tháng 08 khớp `BJ14_T_0826` (122 / 28 / 0 / 12 / 15, xuất 38 / 22 / 6 / 9 / 8). Tiền: `SC_bj15_staff` kiểm 055 / thẻ kho / 056 / sheet xuất không có "đ", "₫", "giá trị" trong DOM (059 vẫn có nhãn "Giá trị tài chính: Không"). Bấm thử bằng script CDP hai khung: Hub / BJ-01 / BJ-14 → 055; Esc đóng sheet và trả focus về nút đã mở; Tab vòng trong sheet; Enter / Space trên `<tr>`; "Sửa sai" → 050 (số đúng trống) → gửi → 053 "Về thẻ kho" → 056; "Mở phiếu gốc" → BJ-11 049 / BJ-05 026. `node --check` mọi `app/*.js`, `harness/*.js`, `tools/golden.mjs` đạt. **Audit dọc** (script tương phản / vùng chạm / tràn ngang / tên nút chạy trên `UIF-15_*`, `SC_bj15_*`, `SC_journey_6`, `SC_demo` bước 7–8, hai khung): 0 lỗi tương phản (≥ 4,5:1), 0 tràn ngang, mọi nút có tên; vùng chạm iPhone ≥ 44 ở mọi phần tử của BJ-15 (chip kỳ / lô, nút kỳ / xuất, dòng); khung web `ds-segment` nâng lên 40. Còn ghi nhận ngoài phạm vi: chip lọc của BJ-01 cao 34 (ca `SC_bj15_from_bj01`), nút "Sửa ngưỡng" 18 px (CAP-01), nút đóng toast 20 × 20, dòng bảng `<tr tabindex>` chưa có `role` — đã ghi ở "Đầu vào cho Giai đoạn 3" (T7-P mục 11).

**Lệch so với plan (và lý do):**
1. **Mở phiếu gốc** hiện cho phiếu BJ-11 (→ 049: PN-260904-08, ST-260906-04, SO-260902-19, PN-260903-05) và đơn BJ-05 (SO-260827-21 → SCR-026). **BJ-02 chưa có màn xem chứng từ đã nhận** (SCR-009 là màn nhận hàng, không chỉ đọc) nên dòng Nhận hàng của BJ-02 không có nút. Vì vậy `SC_bj15_lot` kết thúc ở "Mở phiếu gốc" của **dòng bàn giao SO-260827-21** (không phải dòng nhận hàng); thêm `SC_bj15_tylosin_lot` (lô theo lô + ngày ghi nhận) và `SC_bj15_correct` (Amox PN-260904-08).
2. **Fixture:** tháng 08 dựng từ số của BJ-14 (`BJ14_T_0807` / `T_0826`: tồn đầu 01/08 = cuối tháng 07; nhập = cuối − đầu + xuất) nên **không sửa BJ-14**; mã chứng từ chỉ thật khi có ở BJ khác (PN-260816-04 của BJ-02 gồm cả Nobivac và Oxytetracycline LA, PN-260825-02 / SO-260826-11 theo BJ-01, bốn phiếu BJ-11, SO-260827-21 của BJ-05); còn lại (SO-2608…, SO-260905-07 / 11, PN-260903-02 / 04…) là mã đặt cho đủ sổ. Amox giữ `tracking: "NONE"` như BJ-14 (2 hộp cách ly AM2505 chỉ là ghi chú "2 hộp chuyển sang Cách ly", không lô giả — BR-05). Hai dòng có ngày ghi nhận khác ngày nghiệp vụ (SO-260827-21: 08/09 → 09/09; PN-260903-05: 03/09 → 04/09) để thấy hai loại ngày; không dòng nào vắt qua ranh giới tháng.
3. **BJ-01 không sửa số** (đã khớp từ BJ-14 plan mục 9 điểm 5) và **không sửa "Nguồn và thời điểm cập nhật"**: sheet này còn fixture mốc 27/08 ("Nhận hàng gần nhất" PN-260816-04 +118…) khác sổ kho BJ-15 (PN-260816-04 +42…). Đề xuất đồng bộ ở Giai đoạn 3.
4. **Khả dụng** chỉ hiện khi kỳ gồm hôm nay (là số hiện tại, không có "khả dụng cuối tháng 08"); báo cáo kỳ 08/2026 không cột này.
5. **`cr11ReturnMovement` riêng** (không gộp `cr11Return = { kind, id }` như bảng rủi ro): ít đổi hơn, không động `bj16.js`; hai biến loại trừ nhau (`correction-from-case` xoá biến kia, `bj11BackToCase` ưu tiên hồ sơ). Yêu cầu sửa sai nhớ thêm `movementId`.
6. **Không cần `footRows` cho `k7Table`:** dòng "Tồn đầu kỳ" / "Tồn cuối kỳ" là hai dòng thường có lớp `bj15-edge` (không bấm được). `k6TaskList` thêm `filters: null` (không chip).
7. **Kỳ:** BJ-14 mở báo cáo theo kỳ "MM/YYYY" của lần tính (08/2026 → "Tháng trước"); kỳ ngoài 08 – 09/2026 (vd. 07/2026 đã công bố) hiện `EMPTY` "Không có biến động trong kỳ" + "Xem tháng trước" vì sổ kho bắt đầu từ 01/08/2026.
8. **`SC_demo`:** ghép bằng tham chiếu các bước đã dựng (`SCENARIOS.find`) thay vì tách hằng `J1_OPEN…` — `SC_journey_1…5` không bị đụng. `SC_journey_1` kết thúc ở danh sách "Chờ duyệt" nên thêm bước `1-2-home-kho`; bước 3–4 = `SC_journey_2` tới `home`; 5 = `SC_journey_3` tới `home-1`; 6 = `SC_journey_5` tới `home-2`; 7–8 = đoạn BJ-14 → BJ-15 (thẻ kho Oxytetracycline LA, sản phẩm đặt ngưỡng ở bước 2). Vai đổi qua lối vào Hub (`data-theme-entry-actor`). Sổ kho tĩnh nên sau bước 3–6 tồn BJ-01 lệch cuối kỳ thẻ kho (plan mục 11).
9. **Thêm chữ mới** ngoài mục 13: "Áp dụng" (sheet kỳ), "Nhập ngày theo dạng dd/mm/yyyy" (ngày không đọc được), "Nghiệp vụ {dd/mm}" (đối xứng "Ghi nhận {dd/mm}" khi đọc theo ngày ghi nhận), "Tồn không đổi" (biến động Δ 0), "Kết quả đang cập nhật" (sheet xuất khi `STALE`), tên tệp `bao-cao-nhap-xuat-ton-{kỳ}.csv` / `the-kho-{mã}-{kỳ}.csv`; đã vào T7-P mục 13.
10. **Sửa BJ khác (nhỏ):** `bj01.js` một dòng (handoff), `bj14.js` một dòng (`to-report`), `bj11.js` (`cr11ReturnMovement`, entry `correction-from-movement`, nút "Về thẻ kho"), `core.js` (entryTargets UIF-15 / UIF-11, khung Figma UIF-15), `shared-patterns.js` (`k6TaskList` `filters: null`), `tools/sync-registry.py` (bỏ dòng registry của màn đã xoá).
11. **Công cụ:** `tools/golden.mjs` thêm bước kiểm `assertAt` / `check` ném lỗi trong `setTimeout` để golden đếm đi sai màn hoặc sai số vào "lỗi JS". `gitnexus analyze` không chạy được (mục GitNexus).

## 10. Thứ tự commit

1. C0 + C1 (fixture, đối chiếu số BJ-01, 055, bỏ 054). 2. C2 (056 + bỏ 057, sheet xuất + bỏ 058, 059, lối BJ-01 / BJ-14 / BJ-11). 3. C3 + D (`SC_journey_6`, `SC_demo`, golden, sửa sau audit). 4. E. Làm một lượt thì để chưa commit cho phiên review xem trước. `detect-changes` trước mỗi commit.

## 11. Không làm

- Thêm biến động sinh ra trong kịch bản (kiểm kê, sửa sai của `SC_journey_5`) vào thẻ kho lúc chạy — fixture tĩnh; nối sống để Giai đoạn 3 nếu cần.
- Lối từ thẻ kho sang BJ-16 ("Số trên app lệch") — BJ-16 vào từ cảnh báo (T7-P mục 2).
- Nhiều kho, chọn kho (app một kho).
- Tệp xuất thật (CSV tải về) — prototype chỉ dựng kết quả.
- SCR-056 của BJ-09 ("Lịch sử tình trạng").

## 12. Rủi ro

| Rủi ro | Cách xử lý |
|---|---|
| Sửa số BJ-01 (C0 điểm 2) làm đổi nhiều ca chặng 1 / Home | Liệt kê ca đổi ở mục 9, đối chiếu từng dòng chữ khác chỉ là số sản phẩm đã sửa; nếu đổi quá rộng (vd. Home "Tồn thấp") dừng và hỏi người dùng (0.10 g) |
| Cuối kỳ thẻ kho không khớp BJ-01 | Một hàm `bj15Ledger` cho mọi nơi + kiểm trong `bj15Seed` (lỗi JS → golden báo) |
| Tách `SC_journey_1…5` thành hằng làm đổi ca cũ | Tách thuần (không đổi bước); so mốc: `SC_journey_1…5` phải "khớp hoàn toàn" |
| `SC_demo` dài, đổi vai nhiều lần dễ gãy | Mỗi đoạn kiểm màn đích; đổi vai qua lối vào có `data-theme-entry-actor` (Home "Chờ duyệt"), không đặt vai tay giữa chừng |
| Lối "Sửa sai" từ 056 làm BJ-11 thêm biến thứ hai bên cạnh `cr11ReturnCase` | Một biến `cr11Return = { kind:"case"|"movement", id }` thay hai biến (sửa `bj11.js` + `bj16.js`), `impact` trước |

## 13. Chữ trên màn

| Vị trí | Chữ |
|---|---|
| 055 thanh lọc | "Tháng 09/2026" · "Chọn kỳ" · "Tháng này" · "Tháng trước" · "Tùy chọn" · "Ngày bắt đầu phải trước ngày kết thúc" · "Số liệu đến {as-of}" · "Xuất tệp" |
| 055 báo cáo | "Báo cáo nhập – xuất – tồn" · "Tìm sản phẩm" · cột "Đầu kỳ", "Nhập", "Xuất", "Cuối kỳ", "Giá trị cuối kỳ" · "Đầu {a} · Nhập {b} · Xuất {c}" · "Tổng giá trị cuối kỳ {x} đ" · "Kỳ đã lưu trữ" / "Số liệu chỉ đọc, đến lúc lưu trữ {ngày}." · "Bạn chưa có quyền xem báo cáo kho" |
| 055 thẻ kho | "{sản phẩm} · {mã} · {ĐVT}" · "Đầu kỳ {a} · Nhập {b} · Xuất {c} · Cuối kỳ {d}" · "Tất cả lô" · cột "Ngày", "Chứng từ", "Diễn giải", "Tồn" · "Tồn đầu kỳ" · "Tồn cuối kỳ" · "Tồn {t}" · "Ghi nhận {ngày}" · "Giá trị cuối kỳ {x} đ" · "Xem tháng trước" |
| 056 | "{loại} {chứng từ}" · "Nguồn" · "Mở phiếu gốc" |
| Sheet xuất | "Kèm giá trị" · "Nội dung" "Báo cáo nhập – xuất – tồn" / "Thẻ kho {sản phẩm}" |
| BJ-11 | "Về thẻ kho" |

## 14. Review

**Review chặng 6 (BJ-14 + BJ-15, v5.19.0 → v5.20.0):** (2026-10-26, phiên review) — **đạt có điều kiện**: một điểm nên sửa trước commit (R1, số liệu chéo BJ-14 ↔ BJ-15), còn lại là góp ý nhỏ. Review của BJ-14 trỏ về đây.

| Kiểm (chạy lại) | Kết quả |
|---|---|
| `node --check app/*.js harness/*.js tools/golden.mjs` | Sạch |
| Golden mobile / web chụp lại (tuần tự, máy chủ `:8765`) | 2164 / 1280 ca, 0 lỗi JS; **"Khớp hoàn toàn"** với `tools/.golden-chang6` / `-web` (mốc tái lập được) |
| `.golden-chang5` → hiện tại | mobile 544 / web 273 ca khác. **Không ca nào ngoài các nhóm đã khai ở CHANGELOG `[5.19.0]` / `[5.20.0]`** (lọc bằng danh sách tiền tố: `UIF-14_` / `UIF-15_`, `SC_bj14_` / `SC_bj15_`, `SC_entry_UIF-14/15_`, `SC_journey_1` / `6`, `SC_demo`, `SC_bj01_`, `SC_cap_`, `SC_bj09_` / `SC_bj12_` (ca có số tồn), bước "Cập nhật giá vốn" của `SC_bj03_*` / `SC_bj13_result`…). **`SC_journey_2…5` khớp hoàn toàn** — đúng cam kết "không tách hằng làm đổi ca cũ" |
| Tiền / quyền | Golden `SC_bj15_staff` và `SC_bj14_staff` ném lỗi nếu có "đ" / "₫" / "giá trị" trong DOM của nhân viên — chạy lại 0 lỗi. Có ` ` trước "đ" ở `bj14Money` / `bj15Money` (nhìn bằng mắt dễ tưởng là dấu cách thường) |
| Số trong BJ-15 | `bj15Check` (lúc nạp, 0 `console.error`): cuối kỳ thẻ kho = tồn BJ-01 cho cả 5 sản phẩm; tháng 08 khớp `BJ14_T_0826` (cuối kỳ + xuất). **Tháng 09 xuất chưa được kiểm** — xem R1 |
| Tài liệu bước E | `SCR-055 / 056 / 059 / 072 / 074 / 077`, `UIF-14`, `UIF-15`: `IN_REVIEW`, không còn đoạn `### vX.Y`; `SCR-054 / 057 / 058` xoá (đã `git rm`) + `RETIRED.md` + `INDEX.md`; liên kết UC-15-01 / 03 / 04, `use-case-map`, PAT-NAV, SCR-095 đã sửa; không còn liên kết tới tệp đã xoá (chỉ còn các câu giải thích "đã gộp" và alias `screenAliases`) |
| Registry | Không còn dòng trỏ tới tệp đã xoá trong `03.design/` (góp ý 6 chặng 5 đã xử lý); `package-checksums.sha256` đổi theo |
| Phiên bản | `manifest.json`, `harness/workbench.js`, badge `index.html`, nhãn inspector UIF-14 (5.19.0) / UIF-15 (5.20.0) đồng nhất |
| GitNexus | Không chạy lại: người làm ghi `gitnexus analyze` lỗi "Invalid UTF-8" (môi trường); dùng `grep` cho người gọi chéo (`bj01.js`, `bj14.js` → `bj15OpenCard` / `bj15OpenReport`; BJ-03 / 13 → `applyEntry("UIF-14", "dirty-scope")`). Chấp nhận, nhưng **chạy `detect-changes` trước commit** (CLAUDE.md) nếu chỉ mục dựng lại được |

Lệch plan ở ghi chú (BJ-14 mục 9, plan này mục 9): **chấp nhận** cả hai bộ. Đáng ghi: `SC_demo` ghép bằng tham chiếu `SCENARIOS.find` thay vì tách hằng (an toàn hơn — `SC_journey_1…5` không bị đụng); `cr11ReturnMovement` riêng thay `cr11Return = {kind, id}` (ít đổi hơn, nhưng hai biến loại trừ nhau — xem góp ý 3).

**Nên sửa trước commit:**

- **R1. Số "xuất trong tháng 09" của BJ-14 không khớp sổ kho BJ-15.** `BJ14_T_U1` (lần tính `COST-2609-U1`) cho xuất tháng 09: Nobivac **2**, Amox 500 **4**, Oxytetracycline LA 3. Sổ kho `BJ15_RAW` tháng 09: Nobivac **12** (SO-260905-07 −10 và bàn giao SO-260827-21 −2), Amox **0** (chỉ nhập PN-260904-08 +20 và đổi tình trạng ST-260906-04 Δ 0), Oxytetracycline LA 3 ✓. "Giá vốn xuất" và "Điều chỉnh giá vốn xuất" ở 074 của `COST-2609-U1` đọc từ `qtyOut` này nên là số dựng trên lượng xuất khác với thẻ kho của chính sản phẩm đó — cùng loại với R2 chặng 5 (hai số cho một sự việc). *(Đính chính khi sửa: số này chỉ hiện sau khi xử lý hết việc chặn và "Tính lại" `COST-2609-U1` — golden và `SC_demo` không đi tới đó, nên chưa lộ trong demo; vẫn sửa để fixture nhất quán.)* Tồn cuối (120 / 48 / 12) và cả tháng 08 đã khớp, riêng xuất tháng 09 sót vì `bj15Check` chỉ kiểm tháng 08. Sửa: đổi `qtyOut` của `BJ14_T_U1` thành 12 / 0 / 3 (hoặc tính từ `bj15Ledger` ở bước dựng 074 — `bj14.js` nạp trước `bj15.js` nên cần hàm gọi lúc dựng, không phải lúc nạp) và **mở rộng `bj15Check`** kiểm xuất tháng 09 với `BJ14_T_U1`. Ca golden khác: `UIF-14_SCR-074_*` và `SC_bj14_*` mọi ca có số của `COST-2609-U1` (ghi CHANGELOG `[5.20.1]`).

**Góp ý nhỏ (không chặn):**

1. **T7-P (tài liệu) lỗi thời:** dòng 3 (trạng thái đầu) vẫn ghi chặng 5 "chờ duyệt … BJ-08 / BJ-11 chưa review" và không có chặng 6; mục 8.2 chặng 6 ghi `SC_demo_*` (tên thật `SC_demo`); mục 14 BJ-14 / BJ-15 ghi "chưa review" — cập nhật sau review này (Giai đoạn 2 ✅, review chặng 6 ✅).
2. **056 "Trước / Sau" theo loại ngày:** `bj15Balances(p.id, cf15DateMode)` sắp theo ngày đang đọc, nên nếu một chứng từ có ngày ghi nhận vắt qua chứng từ khác thì tồn trước / sau đổi theo công tắc (số dư kho thật chỉ theo thứ tự ghi nhận). Fixture hiện không có cặp nào đảo thứ tự nên chưa lộ; đề xuất luôn dùng thứ tự ghi nhận cho "Trước / Sau" (và cột "Tồn" của bảng), hoặc ghi vào mục 11 là hạn chế đã biết.
3. **Hai biến quay lại của BJ-11** (`cr11ReturnCase`, `cr11ReturnMovement`): `bj15OpenSource` gán `""` cho cả hai, `bj15Correct` gán một xoá một — đúng, nhưng mọi lối vào BJ-11 mới phải nhớ xoá cả hai. Gom `cr11Return = {kind, id}` ở Giai đoạn 3 (bảng rủi ro mục 12 đã nêu).
4. **Mã thừa nhỏ ở `bj15.js`:** `bj15Report(state)` không dùng `state`; `bj15ExportStart` trả `p` mà không ai dùng; `bj15Money` / `bj14Money` là hai bản trùng (cùng `t7FmtMoney(...).replace(" đ", " đ")`) — đưa NBSP vào `t7FmtMoney` (`shared-patterns.js`) rồi xoá hai bản. Làm ở đợt dọn Giai đoạn 3 vì đổi `t7FmtMoney` đụng mọi BJ có tiền.
5. **"Mở phiếu gốc" không có cho dòng Nhận hàng của BJ-02** — là loại dòng nhiều nhất trong thẻ kho (PN-260816-04, PN-260825-02, PN-260903-02…): người xem bấm vào dòng nhận hàng thấy 056 chỉ có "Sửa sai" nếu là phiếu BJ-11, còn lại không có hành động. Đã ghi ở "Đầu vào cho Giai đoạn 3" (T7-P mục 11); ưu tiên cao vì ảnh hưởng demo bước 8.
6. **Phạm vi commit:** cây làm việc chỉ có chặng 6 (v5.19.0 + v5.20.0) và chưa tách được theo plan (cùng sửa `core.js`, `golden.mjs`, `screens.css`, `components.css`, CHANGELOG, registry) → **một commit chặng 6** (hoặc hai nếu tách được CHANGELOG `[5.19.0]` / `[5.20.0]` bằng `git add -p`). Ba tệp `SCR-054/057/058.md` đã ở trạng thái `D` trong chỉ mục (staged), còn lại chưa — `git add -A` toàn bộ để thống nhất. Hai tệp plan mới (`T7-P-bj14-gia-von.md`, `T7-P-bj15-bao-cao-the-kho.md`) chưa theo dõi — nhớ thêm.
7. **Mốc:** sau R1, chụp lại `tools/.golden-chang6*` (hiện khớp mã nguồn nhưng sẽ khác ở các ca `COST-2609-U1`). Các mốc `tools/.golden-*` bị `.gitignore` — không vào commit.

**Đã sửa (2026-10-26, phiên review theo yêu cầu người dùng, v5.20.1) — review đạt:** R1 (`BJ14_T_U1` xuất tháng 09 Nobivac 12, Amox 500 0, Oxytetracycline LA 3; `bj15Check` kiểm thêm tồn + xuất tháng 09 với `BJ14_T_U1`); góp ý 1 (T7-P dòng 3, mục 8.2, mục 14); góp ý 7 (mốc `tools/.golden-chang6*` chụp lại). Kiểm: `node --check` sạch; golden 2164 / 1280 ca, 0 lỗi JS, **khớp hoàn toàn** mốc trước sửa (số đổi chỉ hiện sau khi tính lại `COST-2609-U1`). GitNexus `impact bj15Check` báo **CRITICAL** nhưng là kết quả sai của chỉ mục cũ (`f7add97`, người gọi là mã Dart einvoice); `grep`: gọi một lần lúc nạp `bj15.js`, `BJ14_T_U1` chỉ dùng trong `bj14InitialRuns`. Góp ý 2–5 để Giai đoạn 3.

**Chưa kiểm được trong phiên này (không có công cụ / không đổi):** audit tương phản / vùng chạm bằng script của người làm (mục 9) không chạy lại — tin ghi chú; chưa xem ảnh các màn mục 7.6. Nếu cần, mở `SC_journey_6` bước 3, 5 và `SC_demo` bước cuối ở cả hai khung.
