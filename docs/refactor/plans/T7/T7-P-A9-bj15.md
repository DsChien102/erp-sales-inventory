# T7-P · Gói A9 — viết lại code sạch BJ-15 Báo cáo tồn và thẻ kho

> Theme: Theme 7 Inventory · Trạng thái: Plan ✅ | Làm ✅ | Review ⬜
> Thuộc [T7-P](T7-P-thiet-ke-lai-luong.md) Giai đoạn 1, gói A9 (mục 8.1). Ước lượng: **~1,5 ngày, 1 commit**, 5 chặng (0 → 4), golden kiểm sau mỗi chặng.
> Người làm: bạn. Review: phiên plan / review. Mẫu: `app/bj12.js` (dùng `cf*`, `crFactCard`), `app/bj09.js` (màn dùng chung qua `flowRenderers`); đoạn đo: [A1](T7-P-A1-bj04-bj05.md) mục 4.5.
> Làm **sau A8**. Không có thay đổi hành vi có chủ đích; lỗi phát hiện được ghi ở mục 2.7 cho brief BJ-15.

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/`. Đo ngày 2026-10-17 trên working tree (A8 đã làm, chưa commit) — chỉ neo theo chuỗi; chạy lại mục 2.8.

## 1. Mục tiêu

1. BJ-15 (UIF-15: SCR-054, 055, 056, 057, 058, 059) → `app/bj15.js`.
2. **SCR-056 của BJ-09 khi không có `movement`** thôi gọi chuỗi BJ-15 (`renderers["SCR-056"]`): `bj09.js` tự dựng (mục 2.6). Đây là phần A6 để lại.
3. Helper dùng chung BJ-12 + BJ-15 (`cfMoney` … `cfSecondary`) và BJ-09 + BJ-15 (`ac310ProductRow`) → `app/shared-control.js`; helper chỉ BJ-15 dùng → `bj15.js`.
4. Gỡ phần BJ-15 khỏi `app.js` (đầu `core.js`), `v310`, `v320` (cả khối), `v350`, `v351` (cả khối), `legacy-sheet-cleanup` (cả khối).
5. `UIF-15` vào `ownedFlows`. **Giao diện và hành vi không đổi.**

Không làm: BJ-16/17 (A10); `crFactCard`, `crSwitchFlow` (A10 / A11); bảng `v360RootScreens` / `v360ExitTargets` và listener `fallback-exit` (A11); CSS `.cf-*`, `.cf15-*`, `.ac310-*`, `.t381-*` (A11); sửa lỗi ở mục 2.7.

## 2. Bản đồ hiện trạng

### 2.1 Thứ tự nạp

`app.js` (state `cf15*`, `cf15Products`, `cf15Movements`; `cf15ProductById`, `cf15Movement`, `cf15DateLabel`, `cf15Segmented`, `cf15ContextBanner`, `cf15ProductSheet`, `cf15InventoryResult`, `cf15StockCardResult`; `render054CF15 … render059CF15`; literal `renderers`; listener input / change / click "v1.8.0" phần UIF-15) → `v310` (`ac310BaseRenderers` chụp bản `app.js`; `ac310ModeChoice`, `ac310Render054`, `ac310Cf15ProductSheet`, `ac310Render055`, `ac310Render056` (rẽ UIF-09 / UIF-15), `ac310Render056CF15`, `ac310Render057`, `ac310Render058`; `renderers["SCR-059"]` = `ac310Base`) → `v320` (`ac320Render055`, `ac320Render056`, `ac320Render057` bọc lại, xoá tiêu đề mục) → `v350` (lúc nạp: gắn `productId` + đẩy `MV-AMX-01`, `MV-GLV-01` vào `cf15Movements`; `v350Cf15Products` / `v350Cf15Movements`; **gán lại** `cf15InventoryResult`, `cf15StockCardResult`; bọc 055 và 058) → `v351` (bọc 056, 057: đổi nút quay lại; listener `v351-*-back`) → `v360` (`ensureStableExitAffordance` cho 058 / 059) → `legacy-sheet-cleanup` (bỏ nút "Đóng" trong sheet sản phẩm).

`v361`, `v440`, `v470` chạy chung trên mọi luồng chưa sở hữu → đo ở chặng 4.

### 2.2 Bản thắng — UIF-15

"base" = hàm `render05xCF15` của `app.js`, luôn qua `ac310SanitizeMarkup` (qua `ac310Base`).

| Màn | Trạng thái | Chuỗi thật sự chạy |
|---|---|---|
| 054 | `READY`, `VALIDATION_ERROR` | `ac310Render054` (sanitize) |
| 054 | `CONFLICT`, `PERMISSION_DENIED` | base (sanitize) |
| 054 | `LOCKED` | base **rơi xuống thân form** (kiểu cũ `cf15Segmented`, không banner) (sanitize) |
| 055 | `READY`, `RECORDED_DATE_VIEW`, `BUSINESS_DATE_VIEW`, `FINANCIAL_RESTRICTED` | `v350` tự dựng (`ac310Return`): INVENTORY lọc theo `v350Cf15Products()`, không có tiêu đề "Sản phẩm", sheet `ac310Cf15ProductSheet`; STOCK_CARD lọc theo `v350Cf15Movements(mode)`, rỗng → `ioEmpty` "Không có biến động trong kỳ" |
| 055 | `LOADING`, `EMPTY`, `FILTER_EMPTY`, `PERMISSION_DENIED` | base (sanitize) → `ac320Render055` (dựng lại qua `template`, không xoá gì) |
| 055 | `STALE`, `ARCHIVED_DATA` | base **thân READY** với `cf15InventoryResult` / `cf15StockCardResult` **bản `v350`** (kiểu `io*` cũ, sheet `cf15ProductSheet`; tiêu đề phụ luôn "Kho trung tâm · …") (sanitize) → `ac320` (không xoá gì) |
| 056 | `READY`, `FINANCIAL_RESTRICTED`, `LOCKED` | `ac310Render056CF15` (sanitize) → `ac320Render056` (không xoá gì với UIF-15) → `v351`: nút quay lại bỏ `data-back`, thêm `data-action="v351-cf15-movement-back"` |
| 056 | `LOADING`, `CONFLICT`, `PERMISSION_DENIED` | base (sanitize) → `v351` như trên |
| 057 | `READY`, `STALE` | `ac310Render057` (sanitize) → `ac320Render057`: xoá `.ac310-section-title` "Dòng thời gian nghiệp vụ" → `v351`: `data-action="v351-cf15-source-back"` |
| 057 | `LOADING`, `EMPTY`, `PERMISSION_DENIED` | base (sanitize) → `v351` như trên |
| 058 | `READY` | `v350` tự dựng (`crFactCard` "Phạm vi xuất" có thêm "Sản phẩm", "Số dòng trong phạm vi") — **không sanitize** |
| 058 | `VALIDATION_ERROR`, `STALE`, `PERMISSION_DENIED`, `EXPORT_RUNNING` | base (sanitize); `PERMISSION_DENIED` (không nút, `back:false`) → `v360` chèn `primaryFooter("Về báo cáo",'data-v360-action="fallback-exit" data-v360-target="SCR-055"')` |
| 059 | mọi | base (sanitize); `PERMISSION_DENIED` → `v360` chèn "Về báo cáo" như 058 |

Sheet sản phẩm (055, cả `ac310Cf15ProductSheet` lẫn `cf15ProductSheet`): `legacy-sheet-cleanup` xoá nút "Đóng" (`data-cf15-action="close-product-sheet"` trong `.sheet-actions`) và thêm class `t381-single-business-action` cho `.sheet-actions` còn một nút.

### 2.3 Bản thắng — SCR-056 của UIF-09 khi không có `movement`

`render056BJ09` gọi `renderers["SCR-056"]` → `v351` → `ac320Render056` → `ac310Render056` (nhánh UIF-09):

| Trạng thái | Chuỗi |
|---|---|
| `READY` | `ac310Render056` nhánh UIF-09 (`ac310ProductRow` + `ac310AuditSurface("Lịch sử", …)`, sanitize) → `ac320` xoá tiêu đề mục "Lịch sử" (vì tiêu đề trang "Lịch sử tình trạng") → `v351`: `data-action="v351-ic09-history-back"` |
| còn lại (`LOADING`, `CONFLICT`, `LOCKED`, `PERMISSION_DENIED`, `FINANCIAL_RESTRICTED`) | `ac310Base` → sanitize(`render056CF15`) → không phải UIF-15 → `render056IC09(state)` (`core.js`) → `v351` như trên |

UIF-09 đã sở hữu nên `v360` / `v361` / `v440` / `v470` không chạy trên kết quả này.

### 2.4 Mã chết

| Mã | Vì sao |
|---|---|
| Nhánh `invalid` (banner `VALIDATION_ERROR`) của base 054 | `ac310Render054` xử lý `VALIDATION_ERROR`; base chỉ còn sống cho `LOCKED` (với `invalid=false`) |
| `ac310Render055` (cả hàm) | `v350` bắt hết các trạng thái nó tự dựng; trạng thái khác nó chỉ gọi `ac310Base` |
| `cf15InventoryResult` / `cf15StockCardResult` bản `app.js` | `v350` gán lại lúc nạp |
| `ac320Render055` | Thân READY base / `v350` đều không còn tiêu đề "Sản phẩm" → không xoá gì (xác nhận bằng đo, chặng 1) |
| Thân READY / FINANCIAL / LOCKED của base 056 | `ac310Render056CF15` xử lý |
| Thân READY / STALE của base 057 | `ac310Render057` xử lý |
| `ac310Render058` (cả hàm); thân READY của base 058 | `v350` bắt `READY`; trạng thái khác `ac310Render058` chỉ gọi `ac310Base` |
| `renderers["SCR-059"]=(s)=>…?ac310Base(…):ac310Base(…)` | Hai nhánh như nhau |
| Nút "Đóng" trong hai sheet sản phẩm | `legacy-sheet-cleanup` xoá sau khi dựng |
| `ac310StateLabel`, `ac320ListCount` | Không ai gọi (`grep` 2.8) |
| Guard `if(activeFlowId!=="UIF-15") return renderGeneric(…)` trong 054, 055, 057, 058 | Các màn này chỉ thuộc UIF-15 |

### 2.5 Sống, phải gộp

| Mã | Ở đâu | Xử lý |
|---|---|---|
| State `cf15*`, `cf15Products`, `cf15Movements`, `cf15ProductById`, `cf15Movement`, `cf15DateLabel`, `cf15ContextBanner` | `app.js` | `bj15.js` (giữ tên: `__VET45_V350__.getCf15Rows`, `bj01.js` không đọc nhưng golden / công cụ dev có thể) |
| Gắn `productId` cho 3 movement gốc (`"P-NOB"`) + đẩy `MV-AMX-01`, `MV-GLV-01` | `v350` — **chạy lúc nạp** | Viết thẳng vào literal `cf15Movements` trong `bj15.js` (đúng thứ tự: 3 gốc rồi AMX, GLV); xoá ở `v350` **cùng lúc** (bẫy 7.1) |
| `v350DateIso`, `v350Cf15Products`, `v350Cf15Movements` | `v350` | `bj15DateIso`, `bj15Products()`, `bj15Movements(mode)`; `__VET45_V350__.getCf15Rows` gọi `bj15Movements` lúc chạy |
| `cf15InventoryResult` / `cf15StockCardResult` bản `v350` | `v350` | `bj15LegacyInventoryBody` / `bj15LegacyStockCardBody` — chỉ cho 055 `STALE` / `ARCHIVED_DATA` |
| `v350` 055 / 058 tự dựng | `v350` | Nhánh trong `render055BJ15` / `render058BJ15` (058 READY **không** sanitize) |
| `ac310Render054`, `ac310ModeChoice`, `cf15Segmented` (054 `LOCKED`) | `v310`, `app.js` | `bj15.js` (`bj15ModeChoice`; `cf15Segmented` → `bj15Segmented`) |
| `ac310Cf15ProductSheet`, `cf15ProductSheet` | `v310`, `app.js` | `bj15ProductSheet` / `bj15LegacyProductSheet`: bỏ nút "Đóng", `.sheet-actions` thêm `t381-single-business-action` |
| `ac310Render056CF15`, `ac310Render057` | `v310` | `render056BJ15`, `render057BJ15`; 057 không còn `ac310SectionTitle` trong `ac310AuditSurface` (gọi `ac310AuditSurface("", items)` hoặc dựng thẳng — đo) |
| `v351` đổi nút quay lại 056 / 057 | `v351` | `appShell({…, backAction:"v351-cf15-movement-back"})` / `"v351-cf15-source-back"` (bẫy 7.5) |
| Listener `v351` (`v351-cf15-movement-back` → 055, `v351-cf15-source-back` → 056) | `v351` | `bj15.js`, giữ pha capture + `stopImmediatePropagation` |
| Listener `v351-ic09-history-back` → 037 | `v351` | `bj09.js` (mục 2.6) |
| `v360` "Về báo cáo" cho 058 / 059 `PERMISSION_DENIED` | `v360` | `actions: primaryFooter("Về báo cáo",'data-v360-action="fallback-exit" data-v360-target="SCR-055"')` (mẫu `bj11.js` / `bj08ExitList`); listener `fallback-exit` ở lại `v360` (A11) |
| Listener input / change / click UIF-15 (khối "v1.8.0 — targeted interactions") + `cf15-back-export` | `app.js` | `bj15.js`; xoá cả khối ở `core.js` (UIF-12 đã đi ở A8) |
| `v470` dấu trừ U+2212 trên `.ds24-key-value-row` | `v470` | 056: "Biến động" của `M-SALE` (`-4 hộp`), "Tác động" (`-340.000 ₫`); helper `bj15Minus(text)` cho giá trị key-value. Đo thêm ở chặng 4 |
| `__VET45_V350__.getCf15Rows` | `v350` | Giữ ở `__VET45_V350__` (A11), gọi `bj15Movements` |

### 2.6 SCR-056 của BJ-09 — làm cùng gói

Hiện `render056BJ09` (khi `movement` rỗng) gọi `renderers["SCR-056"]`. Sau A9, `renderers["SCR-056"] = flowScreen("SCR-056")` (cả hai luồng đăng ký qua `flowRenderers`) → gọi lại sẽ **đệ quy vô hạn** về chính `render056BJ09`. Phải thay trong cùng bước (bẫy 7.2):

1. `bj09.js` thêm `render056BJ09History(state)` theo 2.3: `READY` → `ac310ProductRow` + danh sách audit **không** tiêu đề "Lịch sử" (sanitize); trạng thái khác → sanitize(`render056IC09` chuyển từ `core.js` sang `bj09.js`, tên `bj09HistoryBase`); cả hai dùng `backAction:"v351-ic09-history-back"`.
2. `render056BJ09`: `if(!movement) return render056BJ09History(state);`. Nhánh có `movement` đổi luôn sang `backAction` thay đoạn vá `template` (cùng kết quả DOM).
3. Listener `v351-ic09-history-back` → `navigate("SCR-037")` vào listener click của `bj09.js` (pha capture, `stopImmediatePropagation`).
4. Bỏ dòng chú thích đầu `bj09.js` "SCR-056 không có movement → rơi về chuỗi BJ-15 … (A9 thay)".

### 2.7 Lỗi phát hiện — **không sửa ở A9**, ghi cho brief BJ-15

| Lỗi | Hiện tượng |
|---|---|
| Lọc ngày sau khi gõ | `cfField` kiểu ngày hiện `dd/mm/yyyy`; listener gán thẳng `cf15From` / `cf15To` = chuỗi gõ vào. `bj15Movements` so ISO (`2026-09-07`) với `dd/mm/yyyy` bằng so chuỗi → gõ bất kỳ ngày nào là thẻ kho rỗng |
| Báo cáo tồn không theo kỳ | INVENTORY chỉ lọc theo sản phẩm, bỏ qua khoảng ngày và cách hiểu thời gian |
| 055 `STALE` / `ARCHIVED_DATA` dùng giao diện `io*` cũ | Khác hẳn 055 `READY` (DS v2); thẻ kho ở hai trạng thái này có tiêu đề phụ "Kho trung tâm · …" thay vì tên sản phẩm |
| 054 `LOCKED` không có thông báo | Hiện form tra cứu bình thường, bấm "Xem báo cáo" vẫn chạy |
| Hẹn giờ 320 ms của `confirm-export` gọi `render()` không `syncReviewUrl()` | URL vẫn `state=PROCESSING` sau khi xong — **giữ nguyên** ở A9 (golden `@url` đang chụp như vậy) |

### 2.8 Lệnh đo lại

```bash
grep -n 'renderers\[.SCR-05[4-9].\]\s*=' app/core.js                      # v310, v320, v350, v351
grep -n 'cf15\|UIF-15\|SCR-05[4-9]' app/core.js | cut -c1-160
grep -n 'ac320\|AC320_SCOPE\|v351-' app/*.js | cut -c1-160                  # v320 / v351 còn ai dùng
grep -n 'ac310StateLabel\|ac320ListCount\|cf15Segmented' app/*.js           # mã chết / sống
grep -n 'cfMoney\|cfNumber\|cfDateVN\|cfDateKey\|cfField\|cfSelect\|cfSummaryGrid\|cfSecondary\|cfMoneyInput' app/*.js | grep -v 'app/core.js' | cut -c1-120
```

### 2.9 Helper (đo 2026-10-17)

| Helper | BJ dùng | Về đâu |
|---|---|---|
| `cfMoney`, `cfMoneyInput`, `cfNumber`, `cfDateVN`, `cfDateKey`, `cfField`, `cfSelect`, `cfSummaryGrid`, `cfSecondary` | BJ-12, BJ-15 | `shared-control.js` (`const` → xoá ở `core.js` cùng bước, bẫy 7.6) |
| `ac310ProductRow` | BJ-09 (056), BJ-15 | `shared-control.js` |
| `ac310ModeChoice`, `ac310Cf15ProductSheet`, `cf15Segmented`, `cf15ProductSheet` | BJ-15 | `bj15.js` (tiền tố `bj15`) |
| `render056IC09`, `icHeaderRows` | BJ-09 | `render056IC09` → `bj09.js`; `icHeaderRows` đã có bản trong `bj09.js` (bản `core.js` còn cho `bj10.js` — A11) |
| `ac310StateLabel`, `ac320ListCount` | — | Xoá |
| `crFactCard`, `ioResult`, `ioEmpty`, `ioProductRow`, `navChevron` | nhiều BJ | Ở lại `core.js` (`crFactCard` → A10) |
| `ac310CaseRows`, `ac310EvidenceRows`, `ac321CanonicalChips`, `ac310Base` (+ `ac310BaseRenderers`, `AC310_SCREEN_IDS`) | BJ-08/11/16/17 | Ở lại (A10) |

## 3. Chuẩn bị

1. Server, kịch bản golden (mục 6), chụp mốc `.golden-base`, chụp lần hai, so — khớp.
2. Kiểm trên trình duyệt để biết mốc đang ghi gì:
   - `?uif=UIF-15&screen=SCR-054` → "Thẻ kho" → "Xem báo cáo" → dòng "Bán hàng" (SCR-056): "Biến động" hiện `−4 hộp` (U+2212, do `v470`).
   - `?uif=UIF-15&screen=SCR-055&state=STALE`: giao diện `io*` cũ (thẻ tóm tắt dạng lưới), khác `READY`.
   - `?uif=UIF-09&screen=SCR-056`: không có tiêu đề mục "Lịch sử"; nút quay lại về SCR-037.
   Kết quả khác mô tả → dừng, báo phiên review.

## 4. Các bước

### 4.1 Chặng 1 — xoá mã chết (2.4)

Theo bảng. `ac320Render055`: đo trước–sau HTML cho mọi trạng thái 055 (đoạn đo A1) — giống hệt thì xoá; khác → giữ và báo. Golden.

### 4.2 Chặng 2 — gộp (vẫn trong `core.js`)

1. `render054BJ15 … render059BJ15` theo 2.2: nhánh thắng + nhánh base còn sống, bọc `ac310SanitizeMarkup` đúng như chuỗi hiện tại (gọi thẳng hàm base, **không** qua `ac310Base`); 055 `READY…` và 058 `READY` lấy thân `v350`; 056 / 057 dùng `backAction`; 058 / 059 `PERMISSION_DENIED` có footer "Về báo cáo"; sheet không có nút "Đóng".
2. `render056BJ09History` + `bj09HistoryBase` (2.6) — tạm đặt trong `core.js`, chặng 3 chuyển.
3. Thay mọi `renderers["SCR-054…059"]=` của `v310` / `v320` / `v350` / `v351` bằng hàm hợp nhất (SCR-056: `flowRenderers["UIF-15"]["SCR-056"]` + `renderers["SCR-056"]=flowScreen("SCR-056")`); `render056BJ09` gọi `render056BJ09History` **cùng lúc**.
4. Đo nhanh trước–sau bằng đoạn đo A1 cho mọi trạng thái UIF-15 và UIF-09 SCR-056. Golden.

### 4.3 Chặng 3 — chuyển file

1. `shared-control.js`: thêm nhóm `cf*` và `ac310ProductRow` (2.9); xoá bản ở `core.js` cùng bước; sửa chú thích đầu file (danh sách còn ở `core.js` chờ A10).
2. `app/bj15.js`: state + fixture (`cf15Movements` **đã có** `productId`, `MV-AMX-01`, `MV-GLV-01`) + helper `bj15*` + 6 hàm dựng; listener input / change / click UIF-15 + `cf15-back-export` + `v351-cf15-*-back`; `Object.assign(renderers, {"SCR-054":…,"SCR-055":…,"SCR-057":…,"SCR-058":…,"SCR-059":…})`; `flowRenderers["UIF-15"] = {"SCR-056": render056BJ15}`; xoá 6 mục `SCR-054…059` trong literal `renderers`. Viết lại chú thích đầu file theo mẫu `bj12.js`.
3. `app/bj09.js`: `render056BJ09History`, `bj09HistoryBase`, listener `v351-ic09-history-back` (2.6).
4. Xoá ở `core.js`: phần BJ-15 của `app.js`; `render056IC09`; phần BJ15 của `v310` (`ac310ModeChoice` … `ac310Render058`, `ac310Render056`, dòng gán `renderers`); **cả khối `v320`**; phần "BJ15" của `v350`; **cả khối `v351`**; **cả khối `legacy-sheet-cleanup`**; khối listener "v1.8.0".
5. Trước khi xoá cả khối `v320` / `v351` / `legacy-sheet-cleanup`: `grep` chắc không còn nhánh của BJ khác (đo 2026-10-17: `v320` chỉ còn 055–057 + `AC320_SCOPE` nội bộ; `v351` chỉ UIF-09 / UIF-15; `legacy-sheet-cleanup` chỉ `cf15`).
6. `node --check`; mở deep link mọi luồng cụm kiểm soát (mục 5); golden.

### 4.4 Chặng 4 — đo, rồi sở hữu

1. Đoạn đo A1 (`rendererFor`), luồng `["UIF-15"]`, mọi trạng thái; với 055 đo cả hai `cf15ReportType` và khi sheet mở; với 056 đo cả `M-SALE`. Ứng viên lệch:
   - `v470`: `.ds24-key-value-row` có giá trị bắt đầu `-` (056 `M-SALE`), dòng "Chênh lệch" (không có ở BJ-15 — xác nhận).
   - `v440` grouped surface trên `crFactCard` (058 `READY`), `cfSummaryGrid` / sheet `io*` (055 `STALE`).
   - `v361`: BJ-15 không có footer hai nút — xác nhận không lệch.
   - `legacy-cross-theme-copy` rule chung "Định danh xử lý" — BJ-15 không có (xác nhận).
   Gộp tới "không khác"; bỏ qua `data-v470="1"`.
2. Tải lại trang giữa các lần đo (state `cf15*` nằm trong file).
3. `ownedFlows.add("UIF-15")`. Golden khớp hoàn toàn với mốc.

## 5. Kiểm

| Kiểm | Cách | Đạt khi |
|---|---|---|
| Cú pháp | `node --check app/core.js app/shared-control.js app/bj09.js app/bj15.js` | Không lỗi |
| Không còn mã cũ | `grep -n "cf15\|UIF-15\|SCR-05[4-9]" app/core.js` | Chỉ còn: `FIGMA_TEMPLATE_BY_FLOW_SCREEN`, nhãn inspector (`"UIF-15":"v3.2.0 …"`), `v360RootScreens` (054) / `v360ExitTargets` (058, 059), dòng `renderers["SCR-056"]=flowScreen(…)`, `getCf15Rows`, `AC310_SCREEN_IDS` (A10) |
| Khối đã xoá | `grep -n "v320-audit\|v351-list-chip\|legacy-sheet-cleanup\|ac320" app/core.js` | Rỗng |
| Không còn `render()` lúc nạp | `grep -n "^\s*\(if *([^)]*) *\)\?render();" app/core.js` | Rỗng |
| Deep link | `?uif=UIF-15&screen=SCR-054`, `UIF-09&screen=SCR-056`, `UIF-08`, `UIF-11`, `UIF-12`, `UIF-16`, `UIF-17`, `?mode=theme&app=inventory` | Dựng đúng, console sạch (bẫy 7.1, 7.2) |
| Golden | `capture` + `compare` với mốc | **Khớp hoàn toàn** sau mọi chặng |
| Lỗi JS | `_errors.json` | Rỗng |

## 6. Kịch bản golden thêm

Khối `// BJ-15 — T7-P A9`. Lấy selector cụ thể trên trang trước khi viết; bước không làm màn đổi → chỉnh, ghi mục 9. `S = '?uif=UIF-15&screen='`.

| Tên | Bắt đầu | Bước |
|---|---|---|
| `SC_bj15_inventory` | `S+'SCR-054'` | `[data-cf15-action="query"]` (055 INVENTORY) → `[data-cf15-product-row="P-AMX"]` (sheet) → `[data-cf15-action="product-stock-card"]` (055 STOCK_CARD) → `[data-cf15-movement="MV-AMX-01"]` (056) → `[data-cf15-action="source"]` (057) → `back` (056) → `back` (055) |
| `SC_bj15_stock_card` | `S+'SCR-054'` | `[data-cf15-report-type="STOCK_CARD"]` → `[data-cf15-date-mode="RECORDED"]` → `query` → `[data-cf15-movement="M-SALE"]` (056, dấu trừ) → `back` |
| `SC_bj15_validation` | `S+'SCR-054'` | `[data-cf15-report-type="STOCK_CARD"]` → `pick('[data-cf15-product]','ALL')` → `query` (`VALIDATION_ERROR`) → `[data-cf15-report-type="INVENTORY"]` → `query` (055) |
| `SC_bj15_date_invalid` | `S+'SCR-054'` | `typeIn('[data-cf15-from]','08/09/2026')` → `query` (`VALIDATION_ERROR`) |
| `SC_bj15_sheet` | `S+'SCR-054'` | `query` → `[data-cf15-product-row="P-NOB"]` → `.sheet-backdrop[data-cf15-action="close-product-sheet"]` → `[data-cf15-product-row="P-GLV"]` (không lô) → `product-stock-card` |
| `SC_bj15_export` | `S+'SCR-054'` | `query` → `[data-cf15-action="export"]` (058) → `back` (055) → `export` → `[data-cf15-action="confirm-export"]` (059 `PROCESSING`) → `wait(400)` (`COMPLETED`) → `[data-cf15-action="done-export"]` (055) |
| `SC_bj15_export_source` | `S+'SCR-054'` | `STOCK_CARD` → `query` → `[data-cf15-movement="M-RECEIPT"]` → `source` → `[data-cf15-action="export-source"]` (058 "Bằng chứng biến động") → `confirm-export` → `wait(400)` → `done-export` (057) |
| `SC_bj15_restricted` | `S+'SCR-055&state=FINANCIAL_RESTRICTED'` | `export` (058 "Giá trị tài chính: Không") → `confirm-export` → `wait(400)` → `done-export` |
| `SC_bj15_export_denied` | `S+'SCR-058&state=PERMISSION_DENIED'` | `[data-v360-action="fallback-exit"]` (055) |
| `SC_bj15_result_denied` | `S+'SCR-059&state=PERMISSION_DENIED'` | `fallback-exit` (055) |
| `SC_bj15_result_stale` | `S+'SCR-059&state=SOURCE_STALE'` | `done-export` |
| `SC_bj09_history_back` | `?uif=UIF-09&screen=SCR-056` | `back` (`v351-ic09-history-back` → 037) |

Lối vào từ BJ-01 (`[data-bj01-handoff]` → UIF-15 SCR-054) đã có trong `SC_bj01_detail`.

## 7. Bẫy

1. **Truy cập lúc nạp tới biến đã chuyển ra `bj15.js`** — `v350` gọi `cf15Movements.forEach(…)` / `.push(…)` ngay lúc nạp `core.js`; literal `const renderers = {…,"SCR-054":render054CF15,…}` tham chiếu hàm. Chuyển mà quên một trong hai → `ReferenceError` cấp cao nhất, `core.js` dừng giữa chừng, **hỏng mọi luồng** (A8 bẫy 7.1). Kiểm bằng deep link mọi luồng sau chặng 3.
2. **Đệ quy SCR-056** — sau khi `renderers["SCR-056"]=flowScreen("SCR-056")`, nhánh `!movement` của `render056BJ09` mà còn gọi `renderers["SCR-056"]` sẽ gọi lại chính nó → tràn stack. Đổi hai chỗ trong cùng một lần sửa (2.6).
3. **Sanitize không đồng đều**: 058 `READY` của `v350` **không** bọc; mọi nhánh `ac310` và base bọc. Gộp đúng như chuỗi; đo bằng HTML, không chỉ bằng ảnh.
4. **`v350` gán lại hàm toàn cục** `cf15InventoryResult` / `cf15StockCardResult`: chỉ giữ bản `v350` (đổi tên `bj15Legacy*`); đừng chép nhầm bản `app.js` (còn tiêu đề "Sản phẩm" / "Biến động").
5. **Thứ tự thuộc tính nút quay lại**: `v351` dùng `setAttribute` nên `data-action` nằm cuối thẻ; `appShell({backAction})` đặt `data-action` trước `type`. Golden (ảnh + chữ) không đổi; khi đo HTML so bằng `isEqualNode` (không phụ thuộc thứ tự thuộc tính) hoặc chấp nhận khác biệt đúng chỗ này.
6. **`const` trùng tên**: `cfMoney`, `cfMoneyInput`, `cfNumber` là `const` — để cùng lúc ở `core.js` và `shared-control.js` là `SyntaxError` ở file nạp sau, hỏng mọi luồng.
7. **Không dùng `ac310Base` trong `bj15.js`**: `ac310BaseRenderers` chụp `renderers` lúc nạp; khi literal không còn 054–059, `ac310Base("SCR-05x")` rơi về `renderGeneric`. Gọi thẳng hàm base của BJ.
8. **Listener `v351` có `stopImmediatePropagation`** ở pha capture: giữ nguyên trong `bj15.js` / `bj09.js`, nếu không listener khác (hub, `[data-action]` chung) có thể bắt cùng cú bấm.
9. **Không "sửa tiện tay"** các lỗi mục 2.7 (nhất là thêm `syncReviewUrl()` vào hẹn giờ 320 ms — làm lệch `@url` golden).

## 8. Ghi lại và commit

1. `CHANGELOG.md` mục `[5.1.9] — T7-P Giai đoạn 1, gói A9: BJ-15 viết lại sạch` (chuyển gì, gỡ khối nào, SCR-056 BJ-09 tự dựng, golden thêm); `manifest.json`.
2. Plan tổng: mục 14 A9 Làm ✅; mục 8.1 hàng A10 bỏ phụ thuộc vào `ac310ProductRow` / `cf*` (đã ở `shared-control.js`).
3. Chú thích đầu `bj09.js`, `bj12.js` (bỏ "cfMoney / cfField … giữ ở core.js"), `shared-control.js`.
4. `python3 tools/sync-registry.py`; `detect_changes()`; commit `refactor(prototype): T7-P A9 — BJ-15 clean code`.

## 9. Ghi chú khi làm

- 2026-10-18: Chrome headless CDP (`tools/golden.mjs`) không lên cổng 9400 trên máy làm (kể cả qua `osascript`); kiểm deep link / hành vi bằng browser harness. Cần chạy lại `node tools/golden.mjs capture .golden-a9` rồi `compare` với mốc trước A9 trên máy có Chrome CDP.
- Selector kịch bản lấy theo plan mục 6; `SC_bj15_validation` dùng `pick('[data-cf15-product]','ALL')` sau khi chọn STOCK_CARD (vì chọn STOCK_CARD tự gán sản phẩm cụ thể).

## 10. Review

(Phiên review điền sau khi bạn báo xong.)
