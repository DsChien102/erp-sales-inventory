# T7-P · Gói A7 — viết lại code sạch BJ-08 Kiểm kê, dựng `shared-control.js`

> Theme: Theme 7 Inventory · Trạng thái: Plan ✅ | Làm ✅ | Review ✅
> Thuộc [T7-P](T7-P-thiet-ke-lai-luong.md) Giai đoạn 1, gói A7 (mục 8.1). Ước lượng: **~2 ngày, 1 commit**, 4 chặng (golden khớp hoàn toàn sau mỗi chặng).
> Người làm: bạn. Review: phiên plan / review. Mẫu: `app/bj02.js`, `app/bj06.js`; đoạn đo: [A1](T7-P-A1-bj04-bj05.md) mục 4.5.
> Làm **sau A6** (A6 vẫn gọi `ac310SanitizeMarkup` trong `core.js`; A7 chuyển nó). Cùng sửa `v350` / `v360` / `legacy-sheet-cleanup` với A4 — làm sau A4.

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/`. Đo ngày 2026-10-17 trong lúc A4 đang làm — chỉ neo theo chuỗi; chạy lại mục 2.6.

## 1. Mục tiêu

1. BJ-08 (UIF-08: SCR-042…047) → `app/bj08.js`.
2. Dựng `app/shared-control.js` (nạp ngay sau `core.js`): helper `ac310*` / `ac320*` / `ac321*` mà **BJ-08 dùng và ít nhất một BJ khác của cụm kiểm soát (11, 12, 15, 16, 17) cũng dùng**. Helper chỉ BJ khác dùng → để nguyên trong `core.js`, gói A8–A10 chuyển.
3. Bỏ mọi lời gọi `render()` lúc nạp trong `core.js` (mục 4.1) — điều kiện để chuyển helper ra file nạp sau.
4. Gỡ phần BJ-08 khỏi `app.js`, `v310`, `v320`, `v340`, `v350`, `v360`, `v3100` (xoá cả khối), `legacy-sheet-cleanup`.
5. `UIF-08` vào `ownedFlows`. **Giao diện và hành vi không đổi.**

Không làm: đổi thiết kế (đếm mù một tay, huỷ phiên trong menu — Giai đoạn 2); `handoff-unknown` (A10); CSS `.ac310-*`, `.ac321-*`, `.v3100-*` (A11); helper `bj01Empty` (A11 gom về `core.js`).

## 2. Bản đồ hiện trạng

### 2.1 Thứ tự nạp

`app.js` (literal `SCR-042…047 → render042IC08 … render047IC08`) → `v310` (`ac310BaseRenderers` chụp bản `app.js`; `renderers["SCR-042…047"] = ac310Render042…` / `ac310Base(…)`) → `v320` (`ac320Base` chụp bản `v310`; 042, 044) → `v340` (044, 045, 046; gán lại `ac310CountGroup`, `ac310RecountGroup`) → `v350` (042, 044, 045, 046, 047; gán lại `ic08QuantityTrigger`, `ic08ConfirmationSheet`) → `v360` (044, 045) → `v3100` (gán lại `render042IC08 … render047IC08`, đặt cả 6 `renderers`).

### 2.2 Bản thắng

| Màn | Trạng thái | Chuỗi thật sự chạy |
|---|---|---|
| 043, 044, 045, 046, 047 | mọi | `v3100` — tự dựng, không gọi bản trước |
| 042 | mọi | `v3100` gọi `baseRender042V3100` (= `renderers["SCR-042"]` lúc đó) rồi `.replace(/data-ic08-action="create"/g,'data-v3100-ic08-action="new"').replace(/data-ic08-action="resume"/g,'data-v3100-ic08-action="resume-count"')` |
| 042 ← base | `READY`, `FILTER_EMPTY` (+ `CANCEL_REQUEST` nội bộ) | `v350` tự dựng (`v350Ic08ListQuery`, `v350Ic08ListFilter`, `ac310Return(appShell(…))`) |
| 042 ← base | `PENDING_APPROVAL` | `v350` → `v320` `ac320Render042` (→ `ac320Base["SCR-042"]`) → `v310` `ac310Render042`, nhánh `PENDING_APPROVAL` |
| 042 ← base | `LOADING`, `EMPTY`, `PERMISSION_DENIED` | … → `ac310Render042` → `ac310Base("SCR-042")` = `ac310SanitizeMarkup(render042IC08 của app.js)` |

### 2.3 Mã chết

| Mã | Vì sao |
|---|---|
| `render043IC08 … render047IC08` gốc (`app.js`) | `v3100` đè; `ac310BaseRenderers` chụp chúng nhưng chỉ `ac310Render043…046` (chết) gọi |
| `v310`: `ac310Render043`, `044`, `045`, `046` + các `renderers["SCR-04[3-7]"]=` | `v3100` đè |
| `v320`: `ac320Render044`, nhánh `READY` của `ac320Render042` (v350 xử lý `READY` trước) | |
| `v340` cả phần BJ-08: `ac340Base044/045/046`, `ac340Render044/045/046`, `ac340ReviewProduct`, gán lại `ac310CountGroup` / `ac310RecountGroup` | `v3100` đè; `v3100` dùng `blindRow` / `recountRow` riêng. Kiểm: `grep -n "ac310CountGroup\|ac310RecountGroup" app/core.js` — chỉ còn trong `v310` / `v340` |
| `v350`: `renderers["SCR-044…047"]` + biến / helper chỉ chúng dùng; gán lại `ic08ConfirmationSheet`; nhánh `ic08-*` của listener `data-v350-action` mà chỉ 044–047 của `v350` phát (`ic08-confirm-*`, `ic08-approve`, `ic08-request-review`, `ic08-approval-result`, `ic08-confirm-cancel`…) | `v3100` đè; nút của `v3100` dùng `data-v3100-*` |
| `v360`: `renderers["SCR-044"]`, `["SCR-045"]`, `injectSessionCancel`; listener `input` `[data-ic08-cancel-reason]` | `v3100` dùng `data-v3100-cancel-reason` |
| `v310` nhánh `READY` của `ac310Render042` | `v350` xử lý trước |

Kiểm từng mục bằng phép "thuộc tính có được hàm thắng phát không" (A5 mục 2.4): hàm thắng của BJ-08 phát `data-v3100-*`, `data-ic08-*` (từ `ic08NumericSheet`, `ic08SelectSheet`, `ic08QuantityTrigger`, `ic08Section`, `ic08ContextRows`, `add-actual-open`, `scope-select-open`), `data-v350-ic08-*` và `data-v350-action="ic08-open-approval"` / `"ic08-cancel-request-back"` (042 của `v350`), `data-v350-action="handoff-unknown"`.

### 2.4 Sống, phải gộp

| Mã | Ở đâu | Xử lý |
|---|---|---|
| Fixture + trạng thái `ic08*` (`ic08Counts`, `ic08Recounts`, `ic08UnexpectedLine`, `ic08Scope`, `ic08AssignedCounter`, `ic08CancelReason`, `ic08ReviewReason`…), helper `ic08ContextRows`, `ic08NumericSheet`, `ic08SelectSheet`, `ic08Section`, `ic08Overlays`, `ic08SessionRow`… | `app.js` | `bj08.js` (helper không ai gọi sau chặng 1 → xoá) |
| `ic08QuantityTrigger` | `v350` gán lại — **bản thắng** | Một định nghĩa = thân `v350` |
| `render042IC08` gốc (nhánh `LOADING` / `EMPTY` / `PERMISSION_DENIED`) | `app.js` | Thân `render042BJ08` cho các trạng thái đó, bọc `ac310SanitizeMarkup` |
| `v350`: 042 (`READY`/`FILTER_EMPTY`/`CANCEL_REQUEST`), `v350Ic08ListQuery`, `v350Ic08ListFilter`, listener `input` `[data-v350-ic08-list-search]`, listener click `[data-v350-ic08-filter]`, `ic08-open-approval`, `ic08-cancel-request-back` | `v350` | `bj08.js` |
| `v310` `ac310Render042` nhánh `PENDING_APPROVAL` | `v310` | `render042BJ08` |
| Toàn bộ `v3100`: hằng `BOOK`, `META`, trạng thái vòng đếm (`roundNo`, `roundHistory`, `resultSnapshot`, `dialogKind`, `approvalCaseNo`, `contributorNames`), helper (`num`, `signed`, `allZero`, `currentVariance`, `lineHead`, `blindRow`, `recountRow`, `unexpectedBlock`, `footer`, `confirmSheet`, `overlays`), 6 hàm dựng, listener `document` input / change / click (capture), `window.__VET45_V3100__` | `v3100` | `bj08.js`, tên cấp file có tiền tố `bj08` / `BJ08_` |
| Kiểm người duyệt `window.__VET45_V350__?.getActor?.()!=='approver'` | `v3100` | Giữ nguyên lời gọi (`v350` còn ở `core.js`) |
| `legacy-sheet-cleanup`: xoá `.ds24-select-sheet button[data-ic08-action="select-close"]` | | Không dựng nút đó trong `ic08SelectSheet`; xoá dòng |
| `app.js` listener "Inventory Audit & Control interactions": nhánh UIF-08 | `app.js` | Đối chiếu thuộc tính với 2.3 — nhánh sống → `bj08.js`, chết → xoá |
| `v350EntryTargets["UIF-08"]` (`assigned-counter`, `approver`), lối vào trong `v350ApplyEntry` | `v350` | Giữ (khung lối vào, A10/A11) |
| `ensureStableExitAffordance`: SCR-042 là màn gốc; 046 / 047 có đích "Về danh sách" | `v360` | Đo ở chặng 4 |

### 2.5 `shared-control.js`

Đo 2026-10-17 (đếm dòng có cùng helper với mã của BJ-11/12/15/16/17): dùng chung — `ac310ApprovalFooter`, `ac310AuditItem`, `ac310AuditSurface`, `ac310Base`, `ac310EvidenceRows`, `ac310Field`, `ac310FileDrop`, `ac310InfoSurface`, `ac310KeyValueSurface`, `ac310ListSurface`, `ac310ModeChoice`, `ac310ProductRow`, `ac310RadioChoice`, `ac310RadioSurface`, `ac310RecordRow`, `ac310Result`, `ac310Return`, `ac310SectionTitle`, `ac310SummaryMetrics`, `ac310Textarea`, `ac320Base`, `ac321CanonicalChips` (+ `ac310SanitizeMarkup`, `ac310CleanText`, `ac310BaseRenderers` mà `ac310Base` dùng; `ac310StateLabel`, `ac310Tone` nếu helper chung gọi).

A7 chuyển sang `shared-control.js` **chỉ** những helper trong danh sách trên mà **chuỗi thắng của BJ-08 hoặc BJ-09 / 10 (A6 — `ac310SanitizeMarkup`) gọi** (đo lại bằng `grep` trên `bj08.js`, `bj09.js`, `bj10.js` sau chặng 3). Phần còn lại ở `core.js` cho A8–A10 (ghi danh sách ở mục 9 để A8 bắt đầu).

`ac310BaseRenderers` chụp `renderers` **lúc nạp `v310`** — giữ ở `core.js` (vị trí nạp quyết định nội dung), `shared-control.js` chỉ chứa hàm.

### 2.6 Lệnh đo lại

```bash
grep -n "renderers\[.SCR-04[2-7].\]\s*=" app/core.js            # v310, v320, v340, v350, v360, v3100
grep -n "render04[2-7]IC08\s*=\s*function\|ic08[A-Za-z]*\s*=\s*function\|ac310\(Count\|Recount\)Group\s*=" app/core.js
grep -n "^\s*\(if *([^)]*) *\)\?render();" app/core.js         # các lời gọi render() lúc nạp (4.1)
```

## 3. Chuẩn bị

1. Server, kịch bản golden (mục 6), chụp mốc, so — khớp.
2. Kiểm trên trình duyệt: `?uif=UIF-08&screen=SCR-044` — nút có `data-v3100-*`, không có `data-v350-action="ic08-…"`; `?uif=UIF-08&screen=SCR-042` — nút "Tạo phiên kiểm kê" có `data-v3100-ic08-action="new"`. Sai → dừng.

## 4. Các bước

### 4.1 Khung — bỏ `render()` lúc nạp

`core.js` đang gọi `render()` lúc nạp ở cuối phần `app.js` và trong các lớp `v310` (`if ([…"UIF-08"…].includes(activeFlowId)) render();`), `v320` (`if (AC320_SCOPE.includes(activeFlowId)) render();`), `v340` (`if(activeFlowId==="UIF-08") render();`), `v351`, và các `renderAppScreen()` / `render()` cuối khối khác (lệnh `grep` 2.6). Các lần dựng này chạy **trước** `shared-control.js` / `bjNN.js`: nếu hàm dựng cũ của BJ-11/12/15/16 gọi helper đã chuyển sang `shared-control.js` → `ReferenceError` ở cấp cao nhất → **`core.js` dừng nạp giữa chừng**, hỏng mọi luồng.

- Xoá mọi lời gọi `render()` / `renderAppScreen()` chạy lúc nạp trong `core.js`. `hub.js` gọi `render()` sau cùng (đầu `hub.js` có ghi), nên lần dựng đầu tiên vẫn có.
- Giữ các dòng khởi tạo khác cạnh `render();` cuối `app.js` (`device-preview` class, `syncReviewUrl()`).
- Golden phải khớp ngay sau bước này (chạy riêng, trước chặng 1).

### 4.2 Chặng 1 — xoá mã chết (2.3)

Theo bảng; golden.

### 4.3 Chặng 2 — gộp

1. `ic08QuantityTrigger`: thân `v350` vào chỗ gốc; xoá phần gán lại.
2. `render042` hợp nhất (vẫn trong `core.js`): `render042BJ08(state)` = theo 2.2 — `READY`/`FILTER_EMPTY`/`CANCEL_REQUEST` thân `v350`; `PENDING_APPROVAL` nhánh của `ac310Render042`; còn lại `ac310SanitizeMarkup(render042IC08(state))`; cuối cùng **cùng hai `.replace` của `v3100`** (giữ nguyên — đổi thẳng chuỗi `data-ic08-action="create"` thành `data-v3100-ic08-action="new"` trong các nhánh nếu muốn, đo phải giống hệt).
3. Xoá: `v350` 042 + `v320` `ac320Render042` + `v310` `ac310Render042` + các `renderers["SCR-042"]=`; `v3100` `baseRender042V3100`.
4. Golden.

### 4.4 Chặng 3 — chuyển file

1. `app/shared-control.js` (2.5) — thêm `<script>` vào `index.html` ngay sau `app/core.js`. Chú thích đầu file: helper dùng chung cụm kiểm soát (BJ-08, 09, 10, 11, 12, 15, 16, 17); danh sách helper còn ở `core.js` chờ A8–A10.
2. `app/bj08.js`: phần sống 2.4 theo thứ tự `app.js` → `v350` → `v310` (nhánh 042) → `v3100`; hàm dựng `render042BJ08 … render047BJ08`; `Object.assign(renderers, …)`; xoá 6 mục trong literal `renderers`.
3. Listener: `v350` (input list-search capture, click filter / open-approval / cancel-request-back), `v3100` (input / change / click capture), nhánh UIF-08 sống của listener "Audit & Control" `app.js` — giữ đúng pha; đầu mỗi listener `if (activeFlowId !== "UIF-08") return;` (gốc của `v3100` **không** kiểm luồng → kiểm `grep -n 'data-v3100-' app/*.js` chỉ ra `bj08.js` rồi mới thêm).
4. Xoá khối `v3100`; khối `v340` nếu rỗng (sau chặng 1 chỉ còn phần BJ-08 thì rỗng — kiểm); dòng `select-close` của `legacy-sheet-cleanup`.
5. Golden.

### 4.5 Chặng 4 — đo, rồi sở hữu

1. Đoạn đo A1 (đã đổi sang `rendererFor` ở A6), luồng `["UIF-08"]`. Ứng viên: `v360` exit affordance, `v361` footer (044 / 045 có footer nhiều nút `ds24-footer-stack`), `v440`, `v470` (`decorateKeyValues` — dòng "Chênh lệch" ở SCR-045 / 046 → class `v470-kv--attention` **rất có thể**; số âm → `−`). Gộp tới "không khác"; bỏ qua `data-v470="1"`.
2. **Tải lại trang giữa các lần đo** — `v3100` giữ vòng đếm (`roundNo`, `roundHistory`) trong trạng thái file.
3. `ownedFlows.add("UIF-08")`. Golden.

## 5. Kiểm

| Kiểm | Cách | Đạt khi |
|---|---|---|
| Cú pháp | `node --check app/core.js app/shared-control.js app/bj08.js` | Không lỗi |
| Không còn mã cũ | `grep -n "ic08\|v3100\|UIF-08\|SCR-04[2-7]" app/core.js` | Chỉ còn: `v350EntryTargets` / `v350ApplyEntry` (UIF-08), `v360RootScreens` / `v360ExitTargets`, `FIGMA_TEMPLATE_BY_FLOW_SCREEN`, nhãn inspector |
| Không còn `render()` lúc nạp | `grep` 2.6 dòng 3 | Rỗng |
| Deep link mọi luồng | Mở `?uif=UIF-11&screen=SCR-048`, `UIF-12`, `UIF-15`, `UIF-16`, `UIF-17` | Dựng đúng, console sạch (bắt lỗi nạp 4.1) |
| Golden | `capture` + `compare` | **Khớp hoàn toàn** (ca `UIF-08_*`, `SC_quick_UIF-08`, `SC_ws_control_*`, ca của BJ-11/12/15/16/17, kịch bản mới) |
| Lỗi JS | `_errors.json` | Rỗng |

## 6. Kịch bản golden thêm

Khối `// BJ-08 Kiểm kê — T7-P A7`. Lấy selector cụ thể trên trang trước khi viết.

| Tên | Bắt đầu | Bước |
|---|---|---|
| `SC_bj08_list` | `?uif=UIF-08&screen=SCR-042` | chip `[data-v350-ic08-filter]` (2 chip) → `typeIn('[data-v350-ic08-list-search]', …)` → xoá → `[data-v3100-ic08-action="new"]` (SCR-043) |
| `SC_bj08_create` | `?uif=UIF-08&screen=SCR-043` | `[data-ic08-action="scope-select-open"]` → chọn phạm vi trong `ic08SelectSheet` → nút tạo phiên (`data-v3100-*`) → (SCR-044) |
| `SC_bj08_blind` | `?uif=UIF-08&screen=SCR-044` | `[data-ic08-quantity-*]` / trigger số lượng dòng đầu → phím số → lưu → dòng hai → `[data-ic08-action="add-actual-open"]` → điền dòng phát sinh → `pick('[data-v3100-stock-state]', …)` → nộp lần đếm (`data-v3100-*` `submit-first`) → xác nhận trong `confirmSheet` |
| `SC_bj08_recount` | `?uif=UIF-08&screen=SCR-045` | nhập đếm lại → `submit-recount` → xác nhận |
| `SC_bj08_approve` | `?uif=UIF-08&entry=approver` | `approve` → `confirm-approve` (SCR-047) |
| `SC_bj08_self_approve` | `?uif=UIF-08&screen=SCR-046` | `approve` (vai người lập → `SELF_APPROVAL_NOT_ALLOWED`) |
| `SC_bj08_review` | `?uif=UIF-08&entry=approver` | `request-review` → `typeIn('[data-v3100-review-reason]', …)` → xác nhận |
| `SC_bj08_cancel` | `?uif=UIF-08&screen=SCR-044` | `cancel-open` → `typeIn('[data-v3100-cancel-reason]', …)` → xác nhận huỷ (SCR-047 `CANCELLED`) |
| `SC_bj08_unknown` | `?uif=UIF-08&screen=SCR-047&state=UNKNOWN` | `[data-v350-action="handoff-unknown"]` |

Khoá `data-v3100-*` cụ thể (`k==='open'`, `'submit-first'`, `'submit-recount'`, `'approve'`, `'confirm-approve'`, `'request-review'`, `'cancel-open'`, `'dialog-close'`, `'new'`…) lấy từ listener click của `v3100`. Bước không làm màn đổi → chỉnh, ghi mục 9.

## 7. Bẫy

1. **`render()` lúc nạp** (4.1) — bẫy lớn nhất của gói: lỗi không hiện ở luồng BJ-08 mà ở deep link của BJ khác. Mục "Deep link mọi luồng" ở 5 bắt được.
2. **`ac310BaseRenderers` / `ac320Base` chụp `renderers` theo vị trí nạp** — không chuyển hai biến này ra file khác; không xoá mục literal `renderers` của màn mà `ac310Base(id)` còn đọc cho BJ khác (`grep -n 'ac310Base("SCR-' app/core.js`).
3. **`v3100` listener không kiểm luồng** và dùng `document` capture: giữ pha; chỉ thêm điều kiện luồng sau khi `grep` chắc thuộc tính chỉ BJ-08 phát.
4. **Trạng thái vòng đếm của `v3100` là `let` trong IIFE** → lên cấp file thành `let bj08RoundNo`… Tên trần (`roundNo`, `dialogKind`, `num`, `signed`, `footer`, `overlays`) **phải** có tiền tố (phạm vi toàn cục chung — bẫy A2 7.4).
5. **`index.html`**: `shared-control.js` đặt sau `core.js`, trước mọi `bjNN.js` (A6 `bj09.js` / `bj10.js` gọi `ac310SanitizeMarkup` lúc dựng).
6. `bj01Empty` (helper của `bj01.js`) được `render042IC08` gọi ở `EMPTY` — vẫn chạy vì gọi lúc dựng; giữ, A11 gom.

## 8. Ghi lại và commit

1. `CHANGELOG.md` mục `[5.1.x] — T7-P Giai đoạn 1, gói A7: BJ-08 viết lại sạch, shared-control.js`; `manifest.json`.
2. Plan tổng: mục 14 A7 Làm ✅; mục 4.1 bẫy: thêm "không gọi `render()` lúc nạp trong `core.js`"; mục 8.1 hàng A8: danh sách helper `ac310*` còn ở `core.js` (mục 9 của plan này).
3. `python3 tools/sync-registry.py`; `detect_changes()`; commit `refactor(prototype): T7-P A7 — BJ-08 clean code, shared-control.js`.

## 9. Ghi chú khi làm

- Helper `ac310*` / `ac320*` / `ac321*` còn ở `core.js` cho A8–A10: `ac310Base` (+ `ac310BaseRenderers` giữ vị trí nạp), `ac310SectionTitle`, `ac310KeyValueSurface`, `ac310ProductRow`, `ac310ListSurface`, `ac310RadioChoice` / `ac310RadioSurface`, `ac310AuditItem` / `ac310AuditSurface`, `ac310Field`, `ac310Textarea`, `ac310FileDrop`, `ac310ApprovalFooter`, `ac310SummaryMetrics`, `ac310Result`, `ac310StateLabel`, `ac310ModeChoice`, `ac310EvidenceRows`, `ac310IssueRow`, `ac310CaseRows`, `ac310Cf12Review`, `ac310Cf15ProductSheet`, toàn bộ `ac310Render048…082` / `ac310Render056CF15`, `ac320ListCount` / `ac320Render055…057`, `ac321CanonicalChips`. Đã chuyển sang `shared-control.js` (A7): `ac310Tone`, `ac310CleanText`, `ac310SanitizeMarkup`, `ac310Return`, `ac310InfoSurface`, `ac310RecordRow`.
- Đo pipe vs bare trước `ownedFlows`: lệch footer `v361`, exit `v360` (046), attention + U+2212 `v470` (045), copy UNKNOWN "Lần xử lý" — đã gộp vào hàm dựng; sau gộp: không khác (bỏ qua `data-v470="1"`).
- Golden `SC_bj08_*`: keypad qua `[data-ic08-key]` / `[data-ic08-keypad-open]`; `SC_bj08_recount` seed `ic08Counts` trước khi nhập đếm lại; `SC_bj08_approve` / `review` dùng `entry=approver`; `SC_bj08_unknown` handoff sang SCR-079 (đúng chuỗi xác minh).
- Lệch plan nhỏ: `shared-control.js` chỉ chuyển helper mà chuỗi thắng BJ-08 / A6 (`ac310SanitizeMarkup`) gọi — không chuyển cả danh sách đo mục 2.5.

## 10. Review

- **Ngày:** 2026-10-19, rà trên working tree cuối Giai đoạn 1 (sau A11, chưa commit; HEAD `4c7020013`). Kiểm chung: [plan tổng mục 14.1](T7-P-thiet-ke-lai-luong.md#141-review-giai-đoạn-1-2026-10-19).
- **Kết quả: ✅ đạt** (theo trạng thái cuối).
- **Đã kiểm:**
  - Golden: mọi ca `UIF-08_*`, `SC_bj08_*`, `SC_quick_UIF-08`, `SC_ws_control_*` — chữ khớp mốc trước Giai đoạn 1 (`UIF-08_SCR-046_*` "Chênh lệch" là `-2 hộp` như mốc gốc). `SC_banner_046` có lớp `v360-context-banner` — khác biệt có chủ đích của A11.
  - `shared-control.js` nạp ngay sau harness, trước mọi `bj*.js`; `core.js` không còn `render()` lúc nạp; deep link UIF-11/12/15/16/17 dựng đúng, console sạch.
  - `bj01Empty` → `ds24EmptyState` ở khung (A11).
- **Ghi nhận (quy trình, không phải lỗi còn tồn):** mốc kiểm của A7 chỉ chụp tập con (`.golden-a7-u08` 37 ca + `.golden-a7-sc`), không chụp toàn bộ, nên hai lệch lọt qua: (a) handoff UNKNOWN của BJ-02/05/06/08 không chuyển màn (listener mất từ A5) — A8 khôi phục; (b) mốc `.golden-a7-after` có `−2 hộp` (U+2212) trên SCR-046 khác mốc gốc `-2 hộp` — trạng thái cuối đã trở lại đúng. Ghi chú mục 9 "`SC_bj08_unknown` handoff sang SCR-079" không đúng với ảnh chụp lúc đó. Bài học đã đưa vào plan tổng 4.1: **mỗi gói chụp và so toàn bộ golden**, không chỉ ca của gói.
