# T7-P · Gói A5 — viết lại code sạch cụm giá trị: BJ-03, BJ-13, BJ-14

> Theme: Theme 7 Inventory · Trạng thái: Plan ✅ | Làm ✅ | Review ⬜
> Thuộc [T7-P](T7-P-thiet-ke-lai-luong.md) Giai đoạn 1, gói A5 (mục 8.1). Ước lượng: **~3 ngày, 1 commit**, làm theo 5 chặng (mỗi chặng kết thúc bằng golden khớp hoàn toàn).
> Người làm: bạn. Review: phiên plan / review. Mẫu: `app/bj02.js` (A4), `app/bj06.js` (A2); đoạn đo, `typeIn`, `pick`: [A1](T7-P-A1-bj04-bj05.md), [A3](T7-P-A3-cap01.md).
> Làm **sau A4** (A4 sửa khối SCR-008 trong `v460` / `v461` và danh sách `ensureRepresentativeFixture` của `v360` — cùng khối với A5).

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/`. Plan đo ngày 2026-10-17 **trong lúc A4 đang làm** — chỉ neo theo chuỗi; chạy lại lệnh ở mục 2.7 trước khi bắt đầu.

## 1. Mục tiêu

1. BJ-03 (UIF-03: SCR-014, 015, 017, 019) → `app/bj03.js`; BJ-13 (UIF-13: SCR-085, 086, 089) → `app/bj13.js`; BJ-14 (UIF-14: SCR-072, 074, 077) → `app/bj14.js`; helper dùng chung cả cụm → `app/shared-valuation.js` (nạp trước ba file BJ).
2. Đường cũ đã nghỉ (SCR-016, 018, 087, 088, 073, 075, 076 — trạng thái `RETIRED_ACTIVE_ROUTE`, không nằm trong danh sách màn của luồng) vẫn chuyển hướng như hiện tại.
3. Xoá hết lớp của cụm: `v313`, `v397`, `v398`, `v399`, `v430`, `v431`, phần BJ-03/13/14 của `v460`, `v461` (sau A4 hai khối này chỉ còn phần giá trị → xoá cả khối), phần giá trị trong `v350`, `v360`, các section UIF-03 / 13 / 14 của `app.js`.
4. `UIF-03`, `UIF-13`, `UIF-14` vào `ownedFlows`.
5. **Giao diện và hành vi không đổi:** golden khớp hoàn toàn; bấm thử 0 lỗi JS.

Không làm: đổi thiết kế; CSS `.val03-*`, `.v313-*`, `.v430-*`, `.v460-*`, `.v461-*` (A11 — kể cả đổi tên thuộc tính `data-v430-*` / `data-v461-*`); cơ chế `handoff-unknown` (A10).

## 2. Bản đồ hiện trạng

### 2.1 Thứ tự nạp và bản thắng

Thứ tự trong `core.js` **không** theo số phiên bản: `app.js` → … → `v350` → `v360` → … → `v397` → `v398` → `v399` → … → `v313` → `v430` → `v431` → `v440` → `v460` → `v461`.

| Lớp | Đặt `renderers` cho cụm | Còn thắng? |
|---|---|---|
| `app.js` | 16 màn qua literal (`render014IV03` …) | Không |
| `v350` | `renderers["SCR-073"]` (UIF-14); `wrapUnknown` cho SCR-019 / 089 / 077 | Không — bị `v313` trở đi đè |
| `v397` / `v398` / `v399` | Gán lại `render0xxIV03/13/14` rồi đặt `renderers` | Không (hàm dựng); **có** (helper, chuẩn hoá fixture — 2.3) |
| `v313` | `Object.assign(renderers, {…16 màn… V313})` | Không (hàm dựng, listener); **có** (một dòng chuẩn hoá fixture — 2.3) |
| `v430` | `Object.assign(renderers, {…17 khoá… V430})` | **SCR-014, SCR-085** (`render014V430`, `render085V430`) và **SCR-016, SCR-018** (đường cũ, xem 2.2) |
| `v460` | `Object.assign(renderers, {…13 khoá…})` | Không — `v461` đặt lại đúng 13 khoá đó |
| `v461` | `Object.assign(renderers, {'SCR-015','017','019','086','087','088','089','072','073','074','075','076','077'})` | **Mọi màn còn lại** |

Bản thắng cho từng màn trong luồng:

| Luồng | Màn | Hàm thắng |
|---|---|---|
| UIF-03 | SCR-014 | `render014V430` (`v430`) |
| UIF-03 | SCR-015, 017, 019 | `render015`, `render017`, `render019` cục bộ của `v461` |
| UIF-13 | SCR-085 | `render085V430` (`v430`) |
| UIF-13 | SCR-086, 089 | `render086`, `render089` của `v461` |
| UIF-14 | SCR-072, 074, 077 | `render072`, `render074`, `render077` của `v461` |

### 2.2 Đường cũ (retired) — giữ hành vi

| Đường | Hiện làm gì | Ở đâu |
|---|---|---|
| UIF-03 SCR-016 | `navigate` đổi thành SCR-015 (`SCREEN_ALIAS`); nếu đặt thẳng `activeScreenId` → dựng `render015V430` (bản `v430`, **không** phải `v461`) | `v430` |
| UIF-03 SCR-018 | `navigate` chuyển sang **UIF-13 SCR-085**; mở thẳng lúc nạp cũng chuyển | `v430` (`if(activeFlowId==='UIF-03'&&screenId==='SCR-018')…`, và đoạn sửa `activeScreenId` lúc nạp) |
| UIF-13 SCR-087 | alias → SCR-086 | `v430` |
| UIF-13 SCR-088 | alias → SCR-086 (`v430`); **thêm** wrapper `navigate` của `v460` và `v461` (trùng nhau); hàm dựng `'SCR-088':function(state){activeScreenId='SCR-086';return render086(state);}`; sửa `activeScreenId` lúc nạp | `v430`, `v460`, `v461` |
| UIF-14 SCR-073, 075, 076 | alias → SCR-074 | `v430` |
| Xoá mục template của các đường cũ khỏi `FIGMA_TEMPLATE_BY_FLOW_SCREEN` | `try{…delete…}` | `v430` |

Ba đoạn này **chạy được** (golden không chụp màn retired vì không nằm trong `screens` của luồng, nhưng `navigate` và deep link đi qua). Giữ bằng móc khung mới (4.1), không bằng wrapper `navigate`.

### 2.3 Phần "sống" trong các lớp có hàm dựng chết

| Lớp | Phần sống | Vì sao |
|---|---|---|
| `v397` | Chuẩn hoá `val03Receipts` lúc nạp (`for(const [ri,r] of val03Receipts.entries())…`, `g1.sources=[basisCandidate(…)]`, …) và helper cục bộ nó dùng (`basisCandidate`, `stableHash`…); 15 helper `val03*` gán lại (`val03SourceDetail`, `val03ScopeReady`, `val03HasSelectedConflict`, `val03TotalValue`, `val03ReceiptState`, `val03ActionablePairs`, `val03WaitingPairs`, `val03SourcePriceText`, `val03ApplySourceUpdate`, `val03Commit`, `val03ScopeGroupsHtml`, `val03CalculationGroupsHtml`, `val03EvidenceSheet`, `val03ReviewGroupsHtml`, `val03ResultGroupsHtml`) | `v430` / `v461` gọi `val03Commit`, `val03Source`, `val03SourceDetail`, `val03Calc`, `val03EvidenceState`… theo tên toàn cục |
| `v398` | Chuẩn hoá `val13Tasks`; 11 helper `val13*` gán lại (`val13AllocationWeight`, `val13StatusMeta`, `val13ResetTaskDraft`, `val13SourceCard`, `val13TargetHtml`, `val13AllocationRows`, `val13PeriodCard`, `val13ReviewBody`, `val13Commit`, `val13Result`, `val13ApplySourceUpdate`); **`window.val13V398 = {…}`** | `v460` / `v461` gọi `window.val13V398.methodEligible` |
| `v399` | Chuẩn hoá `val14Runs`; 5 helper `val14*` gán lại (`val14RunSummary`, `val14AdjustmentCard`, `val14CreateRun`, `val14ApplyInputChange`, `val14Commit`); **`window.__VET45_V399__ = {…, enrichRun: enrich}`** | `v430` / `v461` gọi `window.__VET45_V399__?.enrichRun` |
| `v313` | `val03Receipts.forEach(r=>{r.v313EntryType=types[r.id]||'DOCUMENT';})` (trong `if(typeof val03Receipts!=='undefined'){…}`) | `v430` / `v461` đọc `r.v313EntryType` |
| `v461` (và `v460`) | `val14CreateRun` gán lại — `v461` thắng | |
| `v360` | `ensureVal03ReviewFixture` (SCR-017 `READY`), `ensureVal03ResultFixture` (SCR-019 `COMPLETED`) — gieo dữ liệu trước khi dựng | Golden chụp hai trạng thái này |
| `v360` | `ensureVal13ReviewFixture` (SCR-088), `ensureVal14ReviewFixture` (SCR-076) | **Chết**: chỉ chạy khi `activeScreenId` là màn retired; mọi lối vào đều đổi sang 086 / 074 trước khi dựng |
| `v360` | `SCR-014`, `SCR-072`, `SCR-085` trong `v360RootScreens`; `SCR-019`, `SCR-077`, `SCR-089` trong `v360ExitTargets` | Giữ (A11); đo ở chặng 5 |

**Cách liệt kê chắc chắn** các câu lệnh chạy lúc nạp (không phải khai báo hàm / hằng helper) của một khối — dùng khi làm chặng 2:

```bash
python3 - <<'EOF'
import re
L=open('app/core.js',encoding='utf-8').read().split('\n')
s=next(i for i,l in enumerate(L) if '===== v397' in l); e=next(i for i,l in enumerate(L) if i>s and '/* =====' in l)
for i in range(s,e):
    l=L[i]
    if re.match(r'^  (?!function |const \w+\s*=\s*(\(|\w+\s*=>)|let |//|\}|\)|if\(typeof renderers)\S',l): print(i+1, l.strip()[:160])
EOF
```

(Đổi `v397` thành `v398`, `v399`, `v313`, `v430`, `v461`.) Dòng in ra là câu lệnh lúc nạp **hoặc** dòng tiếp của câu nhiều dòng — đọc từng dòng, phân loại: chuẩn hoá fixture (giữ), gán `window.*` (giữ nếu có nơi đọc), `renderers` / listener / `navigate` (theo bảng ở đây).

### 2.4 Listener — sống hay chết

Một listener chỉ sống nếu thuộc tính nó bắt **được hàm dựng thắng phát ra**. Hàm thắng (2.1) chỉ phát `data-v430-*` (SCR-014, 085), `data-v461-*` (còn lại) và `data-v350-action="handoff-unknown"`.

| Listener | Bắt | Kết luận |
|---|---|---|
| `app.js`: 3 listener UIF-03 (`data-val03-*`), 3 listener UIF-13 (`data-val13-*`), 2 listener UIF-14 (`data-val14-*`) | `data-val03/13/14-*` | **Chết** — hàm thắng không phát `data-val*` |
| `v313` `window` click capture | `data-v313-*` | **Chết** |
| `v430` `window` input / change / click | `data-v430-*` | **Sống một phần**: nhánh mà SCR-014 / 085 phát (vd. `data-v430-val03-filter`, `-receipt`, `-search`, `data-v430-val13-filter`, `-task`, `-search`); các nhánh khác chết |
| `v460` `window` change / click | `data-v460-*` | **Chết** — `v461` phát `data-v461-*` |
| `v461` `window` change / input / click | `data-v461-*` | **Sống** (đối chiếu từng nhánh như `v430`) |
| `v350` `data-v350-action` | `handoff-unknown` | Giữ (A10) |

Đối chiếu từng nhánh `v430`: với mỗi selector `data-v430-…` trong listener, `grep` xem `render014V430` / `render085V430` (và helper chúng gọi) có phát không. Không phát → nhánh chết.

### 2.5 Helper cục bộ của `v430` / `v461`

Mỗi IIFE có bộ helper riêng (`money`, `signed`, `qty`, `pendingGroups`, `entryType`, `row`, `heading`, `button`, `linkButton`, `formSheet`, `confirmSheet`, `applyPolicy`, `workMeta14`…). Các hàm thắng của `v430` dùng bộ của `v430`, của `v461` dùng bộ của `v461`.

- Helper **trùng thân** giữa hai bộ và dùng ở ≥ 2 BJ → `shared-valuation.js`, tên `valuation*` (vd. `valuationMoney`, `valuationSigned`, `valuationRow`).
- Helper **khác thân** (dù cùng tên) → giữ cả hai, tên có hậu tố nguồn (`valuationButton430`, `valuationButton461`) — gộp ở Giai đoạn 2. Ghi danh sách ở mục 9.
- Helper chỉ một BJ dùng → file BJ đó.

### 2.6 `app.js`

Ba section (`// UIF-03 / BJ-03 v1.4.4 …`, `// UIF-13 / BJ-13 v1.4.5 …`, `// UIF-14 / BJ-14 v1.5.0 …`) gồm fixture, trạng thái, helper `val03/13/14*`, `valuationDsTone`, `valuationProductHeader`, `valuationReadOnlyChild` và các `render0xxIV03/13/14` (chết). Fixture / trạng thái / helper còn được gọi → chuyển; hàm dựng → xoá.

### 2.7 Lệnh đo lại trước khi làm

```bash
grep -n "Object.assign(renderers" app/core.js                    # 4 dòng: v313, v430, v460, v461
grep -n "renderers\[.SCR-0\(1[4-9]\|7[2-7]\|8[5-9]\).\]\s*=" app/core.js   # v350 (073), v397–v399
grep -n "navigate\s*=\s*function" app/core.js                    # có v430, v460, v461 (cùng các lớp khác)
grep -n "window.val13V398\|window.__VET45_V399__\|v313EntryType" app/core.js
```

## 3. Chuẩn bị

1. Server, kịch bản golden (mục 6), chụp `.golden-base` / `.golden-check`, so — khớp hoàn toàn.
2. **Kiểm mã chết trên trình duyệt** trước chặng 1:
   - `?uif=UIF-03&screen=SCR-014`: nút / chip trên màn có `data-v430-*`, **không** có `data-val03-*` / `data-v313-*`.
   - `?uif=UIF-03&screen=SCR-015`: có `data-v461-*`, không có `data-v430-*` / `data-v460-*`.
   - `?uif=UIF-14&screen=SCR-074`: như trên.
   - Sai → dừng, báo phiên review.

## 4. Các bước

### 4.1 Khung — móc chuyển hướng màn

Trong `core.js`, cạnh `onScreenEnter` / `onPrevious`:

```js
// Đường cũ của luồng: navigate(màn cũ) → màn mới (cùng luồng), hoặc → [luồng khác, màn].
const screenAliases = {};
```

Đầu `navigate` gốc: `const alias = screenAliases[activeFlowId]?.[screenId]; if (Array.isArray(alias)) { activeFlowId = alias[0]; screenId = alias[1]; } else if (alias) screenId = alias;` — đặt **trước** `if (!renderers[screenId]) return;` và trước móc `onScreenEnter`.

Lúc nạp (deep link `?screen=SCR-088`…): `screenAliases` chưa có khi `core.js` chọn màn đầu. Mỗi `bjNN.js` tự sửa `activeFlowId` / `activeScreenId` ở cuối file, như `v430` / `v461` đang làm:

```js
{ const a = screenAliases[activeFlowId]?.[activeScreenId]; if (Array.isArray(a)) { activeFlowId = a[0]; activeScreenId = a[1]; } else if (a) activeScreenId = a; }
```

### 4.2 Chặng 1 — xoá mã chết

1. Hàm dựng chết: `render0xxIV03/13/14` (`app.js`), `render0xxIV03/13/14 = function…` + phần đặt `renderers` của `v397` / `v398` / `v399`, toàn bộ `render0xxV313` + `Object.assign` + listener của `v313` (**giữ** dòng `v313EntryType`), hàm dựng của `v430` trừ `render014V430`, `render085V430`, `render015V430` (đường cũ SCR-016) và helper chúng gọi, toàn bộ hàm dựng + `Object.assign` + listener + wrapper `navigate` của `v460` (giữ `val14CreateRun` nếu `v461` không gán lại — đo: `v461` có gán lại → xoá bản `v460`).
2. `v350`: `v350Render073Base` + `renderers["SCR-073"]=…`; 3 mục `SCR-019`, `SCR-089`, `SCR-077` trong `unknowns`. **Giữ** nhánh `UIF-14` / `dirty-scope` trong `v350EntryTargets` / `v350ApplyEntry` (khung lối vào).
3. `v360`: `ensureVal13ReviewFixture`, `ensureVal14ReviewFixture` + bỏ khỏi `ensureRepresentativeFixture`.
4. Listener chết (2.4): `app.js` 8 listener; nhánh chết của `v430`.
5. Golden.

### 4.3 Chặng 2 — gộp phần sống của các lớp về chỗ gốc

1. 15 + 11 + 5 helper gán lại (2.3) + `val14CreateRun` (`v461`): thay thân bản gốc trong `app.js` bằng thân thắng; helper cục bộ chúng cần → cấp file, tiền tố `val03` / `val13` / `val14` / `valuation`.
2. Chuẩn hoá fixture của `v397` / `v398` / `v399` / `v313` → ngay sau fixture tương ứng trong `app.js`, đúng thứ tự nạp cũ (`v397` → `v398` → `v399` → `v313`).
3. `window.val13V398` → `const val13Engine = {…}` (cấp file); `window.__VET45_V399__.enrichRun` → `function val14EnrichRun(…)`. Sửa nơi gọi (`window.val13V398?.methodEligible?…` → `val13Engine.methodEligible(…)`, `window.__VET45_V399__?.enrichRun?.(r,0)` → `val14EnrichRun(r,0)`) — giữ đúng nhánh khi không có (không còn "không có"). Nếu còn nơi khác đọc `window.__VET45_V399__` / `window.val13V398` (`grep app/*.js tools/*.mjs`) → giữ gán `window` một dòng, ghi mục 9.
4. Xoá khối `v397`, `v398`, `v399`, `v313`. Golden.

### 4.4 Chặng 3 — tách hàm dựng thắng ra khỏi IIFE `v430` / `v461`

1. Hàm thắng + helper (2.5) lên cấp file **trong `core.js`** (tạm), tên: `render014BJ03`, `render015BJ03`, `render016BJ03` (= `render015V430`, chỉ cho đường cũ — xem 4.6.3), `render017BJ03`, `render019BJ03`, `render085BJ13`, `render086BJ13`, `render089BJ13`, `render072BJ14`, `render074BJ14`, `render077BJ14`.
2. Listener sống của `v430` / `v461`: gộp thành một listener mỗi loại (`input`, `change`, `click`) **trên `window`, pha capture**, giữ `stopImmediatePropagation` — giữ nguyên thời điểm so với các listener khác (bỏ ở Giai đoạn 2). Mỗi listener: `if (!["UIF-03","UIF-13","UIF-14"].includes(activeFlowId)) return;` nếu gốc có, giữ nguyên điều kiện gốc.
3. Đường cũ (2.2) → `screenAliases` (4.1); xoá các wrapper `navigate` của `v430`, `v460`, `v461`.
4. Xoá khối `v430`, `v460`, `v461` (sau A4 không còn phần SCR-008), `v431` (chỉ ghi `window.__VET45_V431__` — không nơi nào đọc, kiểm bằng `grep`). Golden.

### 4.5 Chặng 4 — chuyển file

1. `app/shared-valuation.js`: helper dùng ≥ 2 BJ (`valuation*`, `valuationDsTone`, `valuationProductHeader`, `valuationReadOnlyChild`, các helper chung của 2.5). Thêm `<script src="app/shared-valuation.js"></script>` trong `index.html` ngay sau `app/core.js` (thứ tự hiện tại: `core.js` → `bj01.js` … `bj17.js` → `cap01.js` → `hub.js`; `bj03.js` nạp **trước** `bj13.js` / `bj14.js`).
2. `app/bj03.js`, `bj13.js`, `bj14.js`: fixture + chuẩn hoá + trạng thái + helper + hàm dựng + listener + `screenAliases[...]` + đoạn sửa màn lúc nạp + `Object.assign(renderers, …)`. Chú thích đầu file theo mẫu `bj02.js`.
   - Chuẩn hoá fixture tách theo BJ được: đo 2026-10-17, `v398` chỉ đụng `val13*`, `v399` chỉ đụng `val14*`. Dòng `v313EntryType` (của `v313`, chạy sau `v399`) đi vào `bj03.js` — chạy sớm hơn trước nhưng chỉ đụng `val03Receipts`, không ảnh hưởng.
3. `ensureVal03ReviewFixture`, `ensureVal03ResultFixture` → `bj03.js`, gọi ở đầu `render017BJ03`, `render019BJ03`; bỏ khỏi `ensureRepresentativeFixture` (A4 mục 2.3 làm giống vậy).
4. Golden.

### 4.6 Chặng 5 — đo, rồi sở hữu luồng

1. Đoạn đo của A1, luồng `["UIF-03","UIF-13","UIF-14"]`, `ownedFlows` tạm chưa thêm. Bỏ qua khác biệt chỉ gồm `data-v470="1"`. Ứng viên: `v360` (`ensureStableExitAffordance` — 014 / 072 / 085 là màn gốc; 019 / 077 / 089 có đích "Về danh sách"), `v361`, `v440` (`applyGroupedSurfaceRule` — lớp này viết cho chính cụm giá trị, khả năng cao có khác), `v470` (`decorateKeyValues`: "Chênh lệch", số âm → `−`; `decorateCaptions`). Gộp vào hàm dựng tới "không khác".
2. `ownedFlows.add("UIF-03")`, `("UIF-13")`, `("UIF-14")`.
3. SCR-016 (đường cũ) khi `activeScreenId` bị đặt thẳng: `renderers['SCR-016'] = render016BJ03` (bản `v430`) — giữ đúng như hiện tại, ghi mục 9 cho Giai đoạn 2 (có thể bỏ hẳn).
4. Golden.

## 5. Kiểm

| Kiểm | Cách | Đạt khi |
|---|---|---|
| Cú pháp | `node --check app/core.js app/shared-valuation.js app/bj03.js app/bj13.js app/bj14.js` | Không lỗi |
| Không còn lớp | `grep -n "===== v313\|===== v39[789]\|===== v43[01]\|===== v46[01]" app/core.js` | Rỗng |
| Không còn mã cũ | `grep -n "val03\|val13\|val14\|valuation\|UIF-03\|UIF-13\|UIF-14" app/core.js` | Chỉ còn: `v350EntryTargets` (UIF-14), `v360RootScreens` / `v360ExitTargets`, `FIGMA_TEMPLATE_BY_FLOW_SCREEN`, nhãn inspector, `entryMode` (UIF-03 `receipt-task`, UIF-13 `source-task`) |
| Một định nghĩa | `grep -n "^\s*[A-Za-z0-9_]*\s*=\s*function" app/bj03.js app/bj13.js app/bj14.js app/shared-valuation.js` | Rỗng |
| Đường cũ | Console: `activeFlowId='UIF-03'; navigate('SCR-018')` → UIF-13 SCR-085; `activeFlowId='UIF-14'; navigate('SCR-076')` → SCR-074; mở `?uif=UIF-13&screen=SCR-088` → SCR-086 | Như trước |
| Golden | `capture` + `compare` | **Khớp hoàn toàn** (ca `UIF-03/13/14_*`, `SC_ws_valuation_*`, kịch bản mới) |
| Lỗi JS | `_errors.json` | Rỗng |

## 6. Kịch bản golden thêm

Khối `// Cụm giá trị BJ-03 / 13 / 14 — T7-P A5`. Selector lấy từ hàm thắng (`data-v430-*` cho 014 / 085, `data-v461-*` cho phần còn lại) — chạy `document.querySelectorAll('[data-v461-val03-select]')` v.v. trên trang để lấy giá trị cụ thể trước khi viết.

| Tên | Bắt đầu | Bước |
|---|---|---|
| `SC_bj03_list` | `?uif=UIF-03&screen=SCR-014` | 2 chip lọc `[data-v430-val03-filter]` → `typeIn('[data-v430-val03-search]','Minh')` → xoá → `[data-v430-val03-receipt]` (phiếu đầu → SCR-015) |
| `SC_bj03_basis` | `?uif=UIF-03&screen=SCR-015` | `[data-v461-val03-select]` (nhóm đầu) → `[data-v461-val03-add-basis]` → điền `data-v461-basis-*` (giá, ngày, số chứng từ) → `[data-v461-tax-mode]` → `[data-v461-val03-sheet]` (lưu) → `[data-v461-val03-review]` (SCR-017) → `[data-v461-val03-back]` |
| `SC_bj03_confirm` | `?uif=UIF-03&screen=SCR-017` | `[data-v461-val03-confirm]` (SCR-019) → `[data-v461-val03-result-list]` (SCR-014) |
| `SC_bj13_flow` | `?uif=UIF-13&screen=SCR-085` | chip `[data-v430-val13-filter]` → `[data-v430-val13-task]` (SCR-086) → `pick('[data-v461-val13-method]', <cách phân bổ thứ hai>)` → `[data-v461-val13-open-confirm]` → `[data-v461-val13-confirm-close]` → `[data-v461-val13-open-confirm]` → `[data-v461-val13-confirm]` (SCR-089) → `[data-v461-val13-list]` |
| `SC_bj14_flow` | `?uif=UIF-14&screen=SCR-072` | `[data-v461-val14-run]` (lần tính sẵn sàng → SCR-074) → `[data-v461-compare]` → `[data-v461-val14-open-publish]` → `[data-v461-val14-publish-close]` → `[data-v461-val14-open-publish]` → `[data-v461-val14-publish]` (SCR-077) → `[data-v461-val14-list]` |
| `SC_bj14_period` | `?uif=UIF-14&screen=SCR-072` | `[data-v461-val14-close-period]` → `pick('[data-v461-val14-period]', …)` → `[data-v461-val14-calculate]` |
| `SC_bj14_dirty` | `?uif=UIF-14&entry=dirty-scope` | `[data-v461-val14-calculate]` |
| `SC_bj03_retired` | `?uif=UIF-03&screen=SCR-018` | (chỉ chụp — phải ra UIF-13 SCR-085) |
| `SC_bj13_retired` | `?uif=UIF-13&screen=SCR-088` | (chỉ chụp — SCR-086) |

Bước không làm màn đổi → chỉnh selector, ghi mục 9.

## 7. Bẫy

1. **Thứ tự nạp không theo số**: `v313` / `v430` nằm **sau** `v397`–`v399`. Khi gộp helper gán lại, "bản cuối" là theo vị trí trong file, không theo tên lớp.
2. **Hàm thắng nằm trong IIFE** dùng helper cục bộ cùng tên khác thân (`button`, `row`… ở `v430` và `v461`). Đưa lên cấp file mà không đổi tên → bản sau đè bản trước, SCR-014 / 085 đổi giao diện. Golden bắt được; đổi tên theo 2.5 trước khi chuyển.
3. **Listener `window` capture + `stopImmediatePropagation`**: gộp nhiều listener thành một thì thứ tự các nhánh phải như thứ tự đăng ký cũ (`v430` trước `v461`).
4. **Chuẩn hoá fixture phụ thuộc thứ tự** (`v397` thêm `sources`, `v313` thêm `v313EntryType`…). Đổi thứ tự → `entryType` hoặc căn cứ giá khác → chữ trên SCR-014 / 015 khác.
5. **`ensureVal03*Fixture`** đọc `activeScreenId` / `stateByScreen` — gọi ở đầu hàm dựng (như A4).
6. **`index.html`**: quên thêm `shared-valuation.js` → `ReferenceError` khi dựng. Thêm đúng vị trí, trước `bj03.js`.
7. Đoạn đo của A1 gọi `renderers[id](st)`; đường cũ SCR-088 trong `renderers` đổi `activeScreenId` khi dựng — đoạn đo chỉ chạy màn trong `flowCatalog` (không gồm màn retired), không sao.

## 8. Ghi lại và commit

1. `CHANGELOG.md` mục `[5.1.x] — T7-P Giai đoạn 1, gói A5: cụm giá trị BJ-03 / 13 / 14 viết lại sạch`; `manifest.json`.
2. Plan tổng mục 14: A5 Làm ✅; mục 4.1 bước 3: thêm "móc `screenAliases`".
3. `python3 tools/sync-registry.py`; `detect_changes()`; commit `refactor(prototype): T7-P A5 — valuation cluster clean code in app/bj03.js, bj13.js, bj14.js, shared-valuation.js`.

## 9. Ghi chú khi làm

- Cho Giai đoạn 2: SCR-016 mở thẳng đang dựng bản `v430` của SCR-015 (khác bản `v461`); thuộc tính `data-v430-*` / `data-v461-*` cần đổi tên; helper trùng tên khác thân (2.5).
- Helper gộp vào `shared-valuation.js`: `valuationDsTone`, `valuationProductHeader`, `valuationReadOnlyChild`, `ensureVal03ReviewFixture`, `ensureVal03ResultFixture`. Helper cục bộ `v430` / `v461` (money, row, formSheet…) giữ trong IIFE từng file — chưa gộp (khác thân).
- Giữ `window.val13V398` / `window.__VET45_V399__` (và `val13Engine` / `val14EnrichRun` toàn cục) vì tách file; `eligibleMethods` / `applyPolicy` dùng optional `window.*` như bản gốc.
- Đo pipe vs bare (A1 4.5, bỏ qua chỉ `data-v470="1"`): **không khác** → không gộp thêm `v440`/`v360`/`v470`.
- Deep link màn retired: `core.js` giữ `requestedScreen` dù không còn trong `flow.screens`; bj* `screenAliases` + `hub.js` render cuối.
- Dirty-scope: `v350ApplyEntry` guard `typeof val14Runs` (chạy trước khi `bj14.js` nạp); `bj14.js` set `mode14='DIRTY_SETUP'` lúc nạp.
- Golden selector lệch plan: `SC_bj03_basis` cần currency/source/reason + ngày `dd/mm/yyyy` (không ISO); `SC_bj13_flow` bỏ pick method thứ hai (fixture chỉ `FIXTURE_VALUE`); phiếu basis dùng `VAL03-R2` / nhóm `VAL03-G3`.
- Gán lại `val03*` / `val13*` / `val14* = function…` trong bj* là phần sống của v397–v399 (đúng plan 2.3), không phải mã chết.

## 10. Review

(Phiên review điền sau khi bạn báo xong.)
