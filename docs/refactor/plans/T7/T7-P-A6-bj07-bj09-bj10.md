# T7-P · Gói A6 — viết lại code sạch BJ-07 Trả NCC, BJ-09 Tình trạng hàng, BJ-10 Tiêu hủy

> Theme: Theme 7 Inventory · Trạng thái: Plan ✅ | Làm ✅ | Review ✅
> Thuộc [T7-P](T7-P-thiet-ke-lai-luong.md) Giai đoạn 1, gói A6 (mục 8.1). Ước lượng: **~3 ngày, 1 commit**, 5 chặng (mỗi chặng golden khớp hoàn toàn).
> Người làm: bạn. Review: phiên plan / review. Mẫu: `app/bj02.js`, `app/bj06.js`; đoạn đo: [A1](T7-P-A1-bj04-bj05.md) mục 4.5.
> Làm sau A2 (đã xong — listener chung `io07`) và sau A4 (cùng sửa listener `data-v350-action`, `legacy-cross-theme-copy`). Độc lập với A5. **Trước A7** (A7 dựng `shared-control.js`; A6 vẫn gọi `ac310SanitizeMarkup` trong `core.js`).

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/`. Đo ngày 2026-10-17 trong lúc A4 đang làm — chỉ neo theo chuỗi; chạy lại mục 2.7 trước khi bắt đầu.

## 1. Mục tiêu

1. BJ-07 (UIF-07: SCR-036, 037, 039, 041) → `app/bj07.js`; BJ-09 (UIF-09: SCR-036, 037, 038, 041, 056) → `app/bj09.js`; BJ-10 (UIF-10: SCR-036, 037, 040, 041) → `app/bj10.js`.
2. Màn dùng chung (036, 037, 041 — ba luồng; 056 — BJ-09 và BJ-15) dựng **theo luồng**: mỗi BJ đăng ký hàm dựng của mình cho màn đó qua móc khung `flowRenderers` (4.1). Không còn hàm dựng nào rẽ nhánh theo `activeFlowId`.
3. Gỡ: `v395`, `v3101` (cả khối); phần BJ-07 / 09 / 10 trong `app.js`, `v310`, `v350`, `v360`, `legacy-cross-theme-copy`. **Giữ** phần SCR-056 của `v310` / `v320` / `v351` cho BJ-15 (A9).
4. `UIF-07`, `UIF-09`, `UIF-10` vào `ownedFlows`.
5. **Giao diện và hành vi không đổi.**

Không làm: đổi thiết kế (khuôn K5 ở Giai đoạn 2); helper `ac310*` (A7 chuyển sang `shared-control.js`); `handoff-unknown`, nhánh UIF-07 của `v350LockSourceForUnknown` (A10); CSS (A11).

**Khác plan tổng mục 8.1:** plan tổng định "036 / 037 / 041 dựng ở `bj07.js`, BJ-09 / 10 gọi lại". Đo cho thấy ba luồng dựng ba nội dung **khác hẳn** nhau trên cùng mã màn (`render036IO07` hiện chỉ là `if (UIF-09) … if (UIF-10) …`), nên A6 dùng móc `flowRenderers`: mỗi BJ sở hữu phiên bản màn của mình. Phiên review chấp nhận đổi hướng này khi duyệt plan; nếu không, quay về cách của plan tổng.

## 2. Bản đồ hiện trạng

### 2.1 Thứ tự nạp

`app.js` (literal: `SCR-036→render036IO07`, `037→render037IO07`, `039→render039IO07`, `041→render041IO07`, `038→render038IC09`, `040→render040IC10`, `056→render056CF15`; ba hàm `render036/037/041IO07` gốc rẽ nhánh sang `…IC09` / `…IC10`) → `v310` (chụp `ac310BaseRenderers` = bản `app.js`; đặt `ac310Render036/037/038/040/041/056`) → `v320` (056) → `v350` (038, 040, 041) → `v351` (056) → `v360` (041) → `v395` (gán lại `render036/037/039/041IO07`, đặt `renderers`) → `v3101` (036, 037, 038, 041, 056 cho UIF-09).

### 2.2 Bản thắng theo luồng × màn × trạng thái

| Luồng | Màn | Trạng thái | Chuỗi thật sự chạy |
|---|---|---|---|
| UIF-07 | 036, 037, 039, 041 | mọi | `v395` (`render036IO07` … mới), nhánh UIF-07 — tự dựng hết |
| UIF-09 | 036 | `READY`, `FILTER_EMPTY`, `EXPIRED` | `v3101` |
| UIF-09 | 036 | `PERMISSION_DENIED`, `LOADING`, `EMPTY` | `v3101` → `v395` → **`render036IC09` (`app.js`)** — bỏ qua `v310` |
| UIF-09 | 037 | trừ `PERMISSION_DENIED`, `LOADING` | `v3101` |
| UIF-09 | 037 | `PERMISSION_DENIED`, `LOADING` | `v3101` → `v395` → **`render037IC09` (`app.js`)** |
| UIF-09 | 038 | mọi | `v3101` (không gọi bản trước) |
| UIF-09 | 041 | một số trạng thái (xem nhánh trong `v3101`) | `v3101` |
| UIF-09 | 041 | còn lại | `v3101` → `v395` → `v360` → `v350` → `ac310Render041` → `ac310Base("SCR-041")` = `ac310SanitizeMarkup(render041IO07 gốc → render041IC09)` |
| UIF-09 | 056 | có `movement` | `v3101` |
| UIF-09 | 056 | không có `movement` | `v3101` → `v351` → `v320` → `v310` → … (chuỗi của BJ-15) |
| UIF-10 | 036, 037 | mọi | `v395` → **`render036IC10` / `render037IC10` (`app.js`)** |
| UIF-10 | 040 | trừ `PERMISSION_DENIED` | `v350` (`renderers["SCR-040"]` của `v350`) |
| UIF-10 | 040 | `PERMISSION_DENIED` | `v350` → `ac310Render040` → `ac310Base` = `ac310SanitizeMarkup(render040IC10)` |
| UIF-10 | 041 | `COMPLETED` | `v395` → `v360` (nhánh `COMPLETED`, đọc `__VET45_V350__.getIC10()`; nếu chưa có số lượng → tự dựng, nếu có → gọi `v350`) → `v350` (nhánh `COMPLETED`) |
| UIF-10 | 041 | còn lại | … → `ac310Render041` → `ac310Base` = `ac310SanitizeMarkup(render041IC10)` |

Bảng này là đích của đoạn đo (chặng 5): với mỗi ô, hàm dựng mới phải ra HTML giống hệt chuỗi trên.

### 2.3 Mã chết

| Mã | Vì sao |
|---|---|
| `render036IO07`, `render037IO07`, `render039IO07`, `render041IO07` gốc — **phần UIF-07** | `v395` gán lại; bản gốc chỉ còn được gọi qua `ac310BaseRenderers` cho nhánh UIF-09 / 10 → giữ thân thành `render041IC09` / `IC10` trực tiếp (4.4) |
| `ac310Render036`, `ac310Render037`, `ac310Render038` (`v310`) | 036 / 037: `v395` đè cho mọi luồng; 038: chỉ UIF-09, `v3101` đè hết |
| `render038IC09` (`app.js`), `v350` `renderers["SCR-038"]` + `v350Ic09Reason`, `v350Ic09Request` + nhánh `ic09-submit` / `ic09-approve` / `ic09-reject` của listener `data-v350-action` + dòng reset UIF-09 trong listener "Reset per-request drafts" | 038 của `v3101` không gọi bản trước; các khoá `ic09-*` chỉ `v350` 038 phát |
| `v395`: 4 hàm dựng mới — **phần UIF-09 / 10** (`if(activeFlowId==='UIF-09')return render036IC09(state);…`) | Thay bằng `flowRenderers` |
| Toast `v360`: `[data-io07-action="confirm-allocation"]`, `[data-v350-action="ic09-submit"]` | `confirm-allocation`: `v395` chặn ở `window` (`stopImmediatePropagation`); `ic09-submit`: không ai phát. Kiểm ở 3.2 |
| `legacy-cross-theme-copy`: khối UIF-09 SCR-038 (đổi chữ nút `[data-ic09-action="submit"],[data-v350-action="ic09-submit"]`) | Nút 038 của `v3101` là `data-v3101-action="submit"` — không khớp |
| `app.js` listener click chung: nhánh `io07` bị `v395` chặn trước (`mark-mismatch`, `confirm-allocation`, `confirm-handover`…) | `v395` `window` capture `stopImmediatePropagation` cho 6 khoá: `mark-mismatch`, `select-mismatch`, `close-mismatch`, `record-mismatch-observation`, `confirm-allocation`, `confirm-handover` |

### 2.4 Hàm gán lại / bọc

| Hàm | Bản thắng |
|---|---|
| `io07AllVerified`, `io07ReviewGroups`, `io07SourceDelta`, `io07VerificationSheet`, `io07ApplySourceUpdate`, `io07CreateResult`, `io07ResultSnapshot` | `v395` |
| `io07ActiveRequests` | `v350` bọc: lọc `!r.unknownLocked` → gộp vào bản gốc |
| `render036/037/039/041IO07` | `v395` (phần UIF-07) |

### 2.5 Sống, phải giữ / gộp

| Mã | Ở đâu | Xử lý |
|---|---|---|
| Khởi tạo `io07Requests.forEach(r=>{r.unknownLocked ??= false;})` | `v350` | Chuyển vào `bj07.js` |
| `ensureIo07ReviewFixture` | `v360` | `bj07.js`, gọi đầu hàm dựng tương ứng (đọc điều kiện trong hàm); bỏ khỏi `ensureRepresentativeFixture` |
| `v350` `renderers["SCR-040"]` (UIF-10) + trạng thái `v350Ic10*` + helper `v350Ic10CompletionValid` + nhánh `ic10-*` của listener `data-v350-action` + dòng reset UIF-10 | `v350` | `bj10.js`. Kiểm người duyệt dùng `isApproverEntry()` / `isCompletionEntry()` cục bộ của `v350` → đọc qua `window.__VET45_V350__.getActor()` (đã có, `v3100` cũng dùng) |
| `v350` / `v360` nhánh UIF-10 `COMPLETED` của SCR-041; `window.__VET45_V350__.getIC10` | `v350`, `v360` | `bj10.js` (đọc thẳng biến `bj10*`, bỏ `getIC10` nếu không còn ai đọc — `grep`) |
| Toast `v360` `[data-v350-action="ic10-submit"]` | sống (listener `v350` không chặn cùng nút) | Gọi `showToast` trong handler `ic10-submit` của `bj10.js` |
| `v395`: chuẩn hoá fixture `io07*`, helper cục bộ (`activeFound`, `verifyButtonDisabled`, `recordObservation`, `displayTime`…), trạng thái sheet lệch (`mismatchSheetOpen`, `mismatchType`…), listener `window` input / click | `v395` | `bj07.js`, tiền tố `bj07` cho helper cục bộ |
| `v3101`: `POLICY`, `BUSINESS_DATE`, chuẩn hoá `ic09*`, helper, 5 hàm dựng UIF-09, listener `document` input / change / click (capture), `window.__VET45_V3101__` | `v3101` | `bj09.js`, tiền tố `bj09` / `BJ09_` |
| `app.js` listener "Inventory Audit & Control interactions": nhánh `UIF-09` (`data-ic09-search`, `data-ic09-destination`, `data-ic09-filter`, `data-ic09-item`, `data-ic09-action`) và `UIF-10` (`data-ic10-item`, `data-ic10-action`) | `app.js` | Đối chiếu với listener `v3101` (cùng bắt `data-ic09-action`, `data-ic09-item` ở capture **trước**) — nhánh nào `v3101` xử lý trước và `return` / chặn thì nhánh `app.js` chết; còn lại chuyển |
| `render036IC09`, `render037IC09`, `render041IC09`, `render036IC10`, `render037IC10`, `render040IC10`, `render041IC10` (`app.js`) | `app.js` | Sống ở các ô "→ app.js" của 2.2 → chuyển sang `bj09.js` / `bj10.js` |
| `v310`: `ac310Render040`, `ac310Render041` (chỉ còn bọc `ac310Base` + sanitize) | `v310` | Không chuyển — trong hàm dựng mới gọi `ac310SanitizeMarkup(render041IC09(state))` cho đúng trạng thái (giữ kết quả giống hệt) |
| `previousScreen`: không có nhánh UIF-07 / 09 / 10 (dùng mặc định theo danh sách màn) | | Không cần `onPrevious` |

### 2.6 SCR-056

UIF-15 (BJ-15) chưa sở hữu đến A9 → `renderers["SCR-056"]` (chuỗi `v310` → `v320` → `v351`) **giữ nguyên**, chỉ bỏ lớp `v3101` khỏi chuỗi. BJ-09 đăng ký `flowRenderers["UIF-09"]["SCR-056"] = render056BJ09`; nhánh "không có `movement`" gọi `renderers["SCR-056"](state)` (chuỗi cũ — đúng như hiện tại). Ghi chú cho A9: thay lời gọi đó bằng hàm của `bj15.js`.

### 2.7 Lệnh đo lại

```bash
grep -n "renderers\[.SCR-0\(3[6-9]\|4[01]\|56\).\]\s*=" app/core.js     # v310, v320, v350, v351, v360, v395, v3101
grep -n "render0\(3[6-9]\|4[01]\)IO07\s*=\s*function\|io07[A-Za-z]*\s*=\s*function" app/core.js   # v350 (io07ActiveRequests), v395
grep -n "k===\"ic09-\|k===\"ic10-" app/core.js
grep -n "UIF-07\|UIF-09\|UIF-10\|io07\|ic09\|ic10" app/hub.js
```

## 3. Chuẩn bị

1. Server, kịch bản golden (mục 6), chụp mốc, so — khớp.
2. **Kiểm mã chết trên trình duyệt**:
   - `?uif=UIF-07&screen=SCR-037`: mở một phần hàng, xác nhận → **không** toast "Đã xác nhận phần hàng".
   - `?uif=UIF-09&screen=SCR-038`: nút chính có `data-v3101-action="submit"`, chữ "Gửi xử lý".
   - `?uif=UIF-10&screen=SCR-040`: gửi yêu cầu → **có** toast "Đã gửi yêu cầu tiêu hủy".
   - Sai → dừng, báo phiên review.

## 4. Các bước

### 4.1 Khung — `flowRenderers`

Trong `core.js`, cạnh `ownedFlows`:

```js
// Màn dùng chung nhiều luồng: mỗi luồng đăng ký hàm dựng riêng, flowRenderers["UIF-NN"]["SCR-NNN"] = fn.
const flowRenderers = {};
function rendererFor(flowId, screenId) { return flowRenderers[flowId]?.[screenId] || renderers[screenId]; }
```

`renderAppScreen`: nhánh `ownedFlows` dùng `rendererFor(activeFlowId, activeScreenId)(stateByScreen[activeScreenId])`. Đoạn đo (A1 4.5) đổi `renderers[id](st)` → `rendererFor(flow, id)(st)`. Tìm mọi nơi khác gọi `renderers[activeScreenId]` trực tiếp (`grep -n "renderers\[activeScreenId\]\|renderers\[screen" app/*.js`) — nơi nào dựng màn của luồng đã sở hữu thì đổi sang `rendererFor`.

Màn chỉ do luồng đã sở hữu dùng (036, 037, 038, 039, 040, 041) vẫn cần một mục trong `renderers` (`navigate` kiểm `if (!renderers[screenId]) return;`; luồng khác mở màn đó qua bộ chọn thì ra `renderGeneric`). Thêm helper khung:

```js
// Mục renderers cho màn chỉ dựng theo luồng: rẽ sang flowRenderers, không có thì renderGeneric.
function flowScreen(screenId) {
  return (state) => (flowRenderers[activeFlowId]?.[screenId] || ((st) => renderGeneric(screens.find((s) => s.id === screenId), st)))(state);
}
```

và đặt `renderers["SCR-0xx"] = flowScreen("SCR-0xx")`. **Không** viết bộ rẽ bằng `rendererFor` — `rendererFor` rơi về `renderers[...]` tức chính bộ rẽ → đệ quy vô hạn khi `flowRenderers` chưa có (lần dựng lúc nạp `core.js`, trước khi `bjNN.js` nạp).

### 4.2 Chặng 1 — xoá mã chết (2.3)

Xoá theo bảng 2.3; với nhánh listener `app.js` của `io07` bị `v395` chặn: xoá đúng 6 khoá đó. Golden.

### 4.3 Chặng 2 — gộp hàm gán lại / bọc (2.4) và phần sống của `v350` / `v360`

1. 7 hàm `io07*` của `v395` → thay thân bản gốc trong `app.js`; `io07ActiveRequests` gộp lọc `unknownLocked`.
2. Khởi tạo `unknownLocked` (`v350`) → sau fixture `io07Requests`.
3. Golden.

### 4.4 Chặng 3 — hàm dựng mới theo luồng (vẫn trong `core.js`)

Viết ở cấp file (tạm trong `core.js`), mỗi hàm ra **đúng** chuỗi ở 2.2:

| Hàm | Thân |
|---|---|
| `render036BJ07`, `render037BJ07`, `render039BJ07`, `render041BJ07` | Nhánh UIF-07 của 4 hàm `v395` (bỏ dòng rẽ sang UIF-09 / 10 / `base0xx`) |
| `render036BJ09` | Thân `v3101` cho `READY`/`FILTER_EMPTY`/`EXPIRED`; `PERMISSION_DENIED`/`LOADING`/`EMPTY` → `render036IC09(state)` |
| `render037BJ09` | Thân `v3101`; `PERMISSION_DENIED`/`LOADING` → `render037IC09(state)` |
| `render038BJ09` | Thân `v3101` |
| `render041BJ09` | Thân `v3101`; nhánh rơi → `ac310SanitizeMarkup(render041IC09(state))` |
| `render056BJ09` | Thân `v3101`; không `movement` → `renderers["SCR-056"](state)` |
| `render036BJ10`, `render037BJ10` | `render036IC10` / `render037IC10` (`app.js`) — đổi tên |
| `render040BJ10` | Thân `v350`; `PERMISSION_DENIED` → `ac310SanitizeMarkup(render040IC10(state))` |
| `render041BJ10` | `COMPLETED`: gộp nhánh `v360` + `v350` (cùng thứ tự kiểm); còn lại → `ac310SanitizeMarkup(render041IC10(state))` |

Kiểm `ac310Base(id, state)` có làm gì thêm ngoài `ac310SanitizeMarkup(fn(state))` không (đo 2026-10-17: không) — nếu có, theo nó.

Đăng ký `flowRenderers` cho 3 luồng; **chưa** thêm `ownedFlows`. Đặt `renderers["SCR-0xx"] = flowScreen("SCR-0xx")` (4.1) cho 036 / 037 / 038 / 039 / 040 / 041. Xoá: `v395` hàm dựng + dòng `renderers[…]=`; `v3101` hàm dựng + dòng `renderers[…]=` (giữ phần còn lại của hai khối tới chặng 4); `v310` `ac310Render036/037/038/040/041` + 5 dòng `renderers["SCR-03x/040/041"]=`; `v350` `renderers["SCR-040"]`, `["SCR-041"]`; `v360` `renderers["SCR-041"]`; `render036/037/039/041IO07` gốc trong `app.js` (giữ `…IC09`, `…IC10`); 7 mục trong literal `renderers` (`036`, `037`, `038`, `039`, `040`, `041` — giữ `056`). Golden.

### 4.5 Chặng 4 — chuyển file

1. `bj07.js`: fixture + trạng thái `io07*` (`app.js`), helper `io07*`, phần sống của `v395` (2.5), `ensureIo07ReviewFixture`, 4 hàm dựng, listener: `app.js` (nhánh `io07` còn lại của listener click / input chung — sau đó listener chung rỗng → xoá) + `v395` (`window`, capture, giữ `stopImmediatePropagation` tới Giai đoạn 2).
2. `bj09.js`: fixture `ic09*` (`app.js`), `render036/037/041IC09`, toàn bộ phần sống `v3101`, 5 hàm dựng, listener (`v3101` + nhánh UIF-09 còn sống của listener "Audit & Control" `app.js`).
3. `bj10.js`: fixture `ic10*`, `render036/037/040/041IC10`, phần UIF-10 của `v350`, toast `ic10-submit`, 4 hàm dựng, listener (nhánh `ic10-*` của `v350` + nhánh UIF-10 của listener "Audit & Control").
4. Xoá khối `v395`, `v3101`; dòng toast `ic10-submit` của `v360`.
5. Chú thích đầu ba file: ghi màn dùng chung đăng ký qua `flowRenderers`; `bj09.js` ghi "SCR-056 rơi về chuỗi BJ-15 (A9 thay)"; `ac310SanitizeMarkup` lấy từ `core.js` (A7 chuyển sang `shared-control.js`).
6. Golden.

### 4.6 Chặng 5 — đo, rồi sở hữu

1. Đoạn đo (A1 4.5, đã đổi sang `rendererFor`), luồng `["UIF-07","UIF-09","UIF-10"]`. Ứng viên khác: `v360` (`ensureStableExitAffordance` — 036 là màn gốc; 038 / 040 / 041 có đích "Về danh sách"), `v361`, `v362` / `v363` (nhịp danh sách, chip — đọc phạm vi trong khối), `v440`, `v470` (`decorateCaptions` — chuỗi "… · Cận hạn / Hết hạn" ở danh sách BJ-09 / 10 **rất có thể** bị đổi thành badge; `decorateKeyValues`). Gộp tới "không khác"; bỏ qua `data-v470="1"`.
2. `ownedFlows.add` ba luồng. Golden.

## 5. Kiểm

| Kiểm | Cách | Đạt khi |
|---|---|---|
| Cú pháp | `node --check app/core.js app/bj07.js app/bj09.js app/bj10.js` | Không lỗi |
| Không còn mã cũ | `grep -n "io07\|ic09\|ic10\|v395\|v3101\|UIF-07\|UIF-09\|UIF-10" app/core.js` | Chỉ còn: `v350LockSourceForUnknown` (UIF-07), `v350EntryTargets` (UIF-09 / 10 `product-context`, `approver`, `completion-operator`), `v360RootScreens` / `v360ExitTargets`, `FIGMA_TEMPLATE_BY_FLOW_SCREEN`, nhãn inspector, `entryMode` UIF-07 |
| Không rẽ nhánh theo luồng | `grep -n "activeFlowId\s*[!=]==\s*['\"]UIF-0[79]\|UIF-10" app/bj07.js app/bj09.js app/bj10.js` | Chỉ ở đầu listener |
| Một định nghĩa | `grep -n "^\s*[A-Za-z0-9_]*\s*=\s*function" app/bj07.js app/bj09.js app/bj10.js` | Rỗng |
| Golden | `capture` + `compare` | **Khớp hoàn toàn** (ca `UIF-07/09/10_*`, `UIF-15_SCR-056_*`, `SC_attention_UIF-09`, `SC_ws_*`, kịch bản mới) |
| Lối vào vai trò | `?uif=UIF-10&entry=approver`, `…&entry=completion-operator`, `?uif=UIF-09&entry=approver` | Như trước |

## 6. Kịch bản golden thêm

Khối `// BJ-07 / 09 / 10 — T7-P A6`. Lấy giá trị selector cụ thể trên trang trước khi viết (`document.querySelectorAll('[data-io07-request]')` …).

| Tên | Bắt đầu | Bước |
|---|---|---|
| `SC_bj07_list` | `?uif=UIF-07&screen=SCR-036` | 2 chip `[data-io07-filter]` → `typeIn('[data-io07-search]','Minh')` → xoá → `[data-io07-request]` (yêu cầu chờ bàn giao → SCR-037) |
| `SC_bj07_verify` | như trên | `[data-io07-request]` → `[data-io07-allocation]` (đầu) → `typeIn('[data-io07-scan-lot]', <lô đúng>)` → `[data-io07-action="confirm-allocation"]` → `[data-io07-allocation]` (thứ hai) → `[data-io07-action="mark-mismatch"]` → `[data-io07-action="select-mismatch"]` → `[data-io07-action="close-mismatch"]` |
| `SC_bj07_handover` | `?uif=UIF-07&screen=SCR-037` (fixture đã đủ — `ensureIo07ReviewFixture`; nếu không, đi từ 036 xác nhận đủ phần) | `[data-io07-action="review-handover"]` (SCR-039) → `[data-io07-action="back-to-preparation"]` → `review-handover` → `[data-io07-action="confirm-handover"]` (SCR-041) → `[data-io07-action="result-to-rtv-queue"]` |
| `SC_bj07_source_changed` | `?uif=UIF-07&screen=SCR-039&state=SOURCE_CHANGED` | nút chính |
| `SC_bj09_flow` | `?uif=UIF-09&screen=SCR-036` | chip `[data-ic09-filter]` → `typeIn('[data-ic09-search]', …)` → xoá → `[data-ic09-item]` (SCR-037) → `[data-ic09-action="change"]` (SCR-038) → `pick('[data-v3101-destination]', …)` → `typeIn('[data-v3101-qty]','1')` → `typeIn('[data-v3101-reason]','Bao bì móp')` → `[data-v3101-action="submit"]` |
| `SC_bj09_approve` | `?uif=UIF-09&entry=approver` | nút duyệt / từ chối của `v3101` (`data-v3101-action`), `typeIn('[data-v3101-reject-reason]', …)` |
| `SC_bj09_movement` | `?uif=UIF-09&screen=SCR-056` | (chỉ chụp) |
| `SC_bj10_flow` | `?uif=UIF-10&screen=SCR-036` | `[data-ic10-item]` (SCR-037) → `[data-ic10-action="request"]` (SCR-040) → điền các ô `data-v350-ic10-*` (`qty`, `reason`, `evidence`) → `[data-v350-action="ic10-submit"]` (toast) |
| `SC_bj10_approve` | `?uif=UIF-10&entry=approver` | `[data-v350-action="ic10-approve"]` |
| `SC_bj10_complete` | `?uif=UIF-10&entry=completion-operator` | `typeIn('[data-v350-ic10-actual]','6')` → `typeIn('[data-v350-ic10-proof]','bien-ban.jpg')` → `[data-v350-action="ic10-complete"]` (SCR-041 `COMPLETED`) |

Bước không làm màn đổi → chỉnh, ghi mục 9.

## 7. Bẫy

1. **Ba chuỗi khác nhau trên cùng một màn**: đoạn đo phải chạy với `activeFlowId` của từng luồng (đã có vòng `for (const flow of …)`).
2. **`ac310BaseRenderers` chụp bản `app.js` lúc nạp `v310`.** Xoá `render041IO07` gốc trước khi viết `render041BJ09` / `BJ10` gọi thẳng `render041IC09` / `IC10` → `ac310Base("SCR-041")` (nếu BJ khác còn gọi) gặp `undefined` → `renderGeneric`. Kiểm `grep -n 'ac310Base("SCR-04[01]"\|ac310Base(.SCR-03' app/core.js` sau chặng 3: phải rỗng.
3. **`v395` và `v3101` dùng listener khác pha** (`window` capture vs `document` capture). Chuyển nguyên pha; chỉ hợp nhất ở Giai đoạn 2.
4. **Nhánh trùng giữa `v3101` và `app.js`** (`data-ic09-action`, `data-ic09-item`): `v3101` chạy trước. Nếu `v3101` xử lý mà không chặn, `app.js` chạy tiếp → hành vi là **cả hai**; giữ đúng như vậy (hai bước liên tiếp trong cùng handler), ghi mục 9.
5. **`isApproverEntry` cục bộ `v350`** — trong `bj10.js` thay bằng `window.__VET45_V350__.getActor() === "approver"` / `=== "completion-operator"`; kiểm `getActor` trả đúng chuỗi (`v350ActorMode`).
6. **Lần dựng lúc nạp `core.js`** (`render();` cuối `app.js`, và `render()` lúc nạp của `v310` / `v320` / `v340` / `v351`) chạy trước `bj07/09/10.js`: deep link `?uif=UIF-09…` lúc đó ra `renderGeneric` (qua `flowScreen`), rồi `hub.js` dựng lại đúng. Không được ném lỗi — hàm dựng mới chỉ đăng ký trong `bjNN.js`, không gọi từ `core.js`.
7. **SCR-056 của BJ-09 gọi chuỗi BJ-15** — khi A9 xoá chuỗi đó, nhánh này phải đổi theo (ghi trong `bj09.js` và mục 9).

## 8. Ghi lại và commit

1. `CHANGELOG.md` mục `[5.1.x] — T7-P Giai đoạn 1, gói A6: BJ-07, BJ-09, BJ-10 viết lại sạch` (móc `flowRenderers`, mã chết, kịch bản golden); `manifest.json`.
2. Plan tổng: mục 14 A6 Làm ✅; mục 8.1 hàng A6 + A9: ghi "màn dùng chung qua `flowRenderers`"; hàng A9: "thay nhánh SCR-056 không có `movement` trong `bj09.js`".
3. `python3 tools/sync-registry.py`; `detect_changes()`; commit `refactor(prototype): T7-P A6 — BJ-07, BJ-09, BJ-10 clean code`.

## 9. Ghi chú khi làm

- Cho Giai đoạn 2: SCR-036 / 037 / 041 của ba luồng là ba màn khác nhau dùng chung mã — brief K5 quyết định tách mã màn hay giữ; toast "Đã xác nhận phần hàng" (BJ-07) và chữ nút 038 (BJ-09) hiện không như lớp `v360` / `v390` định.
- Extract sơ bộ từng kéo nhầm khối IC08 vào `bj09.js` — đã gỡ; BJ-08 vẫn ở `core.js`.
- `SC_bj09_approve`: `entry=approver` không có `basis` → seed `window.__VET45_V3101__.buildBasis()` trước khi bấm duyệt/từ chối.
- `render056IC09` / nhánh UIF-09 của `ac310Render056` giữ trong `core.js` (chuỗi SCR-056 khi BJ-09 không có `movement`); guard `typeof ic09Current` vì lần `render()` sớm trước khi nạp `bj09.js`.
- Gộp `v350UnknownResult` vào `render041BJ10` (UNKNOWN); gộp `v360` "Về danh sách" vào 038/040 không nút. Đo pipe vs bare (bỏ `data-v470`): 0 khác.
- Một hairline PNG `UIF-10_SCR-040_PERMISSION_DENIED` (chữ khớp) so với mốc A5 — chấp nhận và cập nhật mốc local.

## 10. Review

- **Ngày:** 2026-10-19, rà trên working tree cuối Giai đoạn 1 (sau A11, chưa commit; HEAD `4c7020013`). Kiểm chung: [plan tổng mục 14.1](T7-P-thiet-ke-lai-luong.md#141-review-giai-đoạn-1-2026-10-19).
- **Kết quả: ⚠️ → ✅ sau A12 bước R3 (2026-10-19):** giao diện đạt; `bj07.js` đã còn một định nghĩa cho mọi hàm.
- **Đã kiểm:**
  - Golden: mọi ca `UIF-07/09/10_*`, `UIF-15_SCR-056_*`, `SC_bj07_*`, `SC_bj09_*`, `SC_bj10_*`, `SC_attention_UIF-09` — chữ khớp mốc trước Giai đoạn 1. `SC_bj09_movement_0` (SCR-056 BJ-09 không có `movement`) nay khớp `UIF-09_SCR-056_READY` của mốc gốc — phần A6 tạm rơi về chuỗi BJ-15 đã được A9 trả đúng.
  - Móc `flowRenderers` / `rendererFor` / `flowScreen` còn nguyên sau A11; `renderers["SCR-036…041"] = flowScreen(id)`. Rẽ nhánh `activeFlowId` trong `bj07/09/10.js` chỉ ở đầu listener và hẹn giờ `queueSystemCommit` của BJ-09 (chấp nhận được).
  - Đổi hướng `flowRenderers` (thay "dựng ở `bj07.js`") — chấp nhận; A9 / A10 dùng lại đúng cách.
- **Chưa đạt:**
  1. `bj07.js` còn 7 hàm định nghĩa hai lần (bản `app.js` chết ở đầu file, bản `v395` gán đè trong khối cuối): `io07AllVerified`, `io07ReviewGroups`, `io07SourceDelta`, `io07VerificationSheet`, `io07ApplySourceUpdate`, `io07CreateResult`, `io07ResultSnapshot`. Kiểm "Một định nghĩa" mục 5 (`grep "^\s*[A-Za-z0-9_]*\s*=\s*function" app/bj07.js`) phải rỗng.
- **Góp ý (không chặn):** `bj10.js` có `render036BJ10` … `render041BJ10` chỉ gọi thẳng `render0xxIC10` — bỏ lớp chuyển tiếp, đăng ký thẳng `render0xxIC10` (hoặc đổi tên hàm gốc) khi làm R3.
