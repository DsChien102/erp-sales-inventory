# T7-P · Gói A1 — viết lại code sạch BJ-04 Giữ hàng và BJ-05 Lấy hàng & bàn giao

> Theme: Theme 7 Inventory · Trạng thái: Plan ✅ | Làm ✅ | Review ✅
> Thuộc [T7-P](T7-P-thiet-ke-lai-luong.md) Giai đoạn 1, gói A1 (mục 8.1). Ước lượng: **~1 ngày, 1 commit**.
> Người làm: bạn. Review: phiên plan / review. Mẫu tham khảo: `app/bj01.js` (gói A0, đã làm).

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/` nếu không ghi khác. Số dòng đo ngày 2026-10-17 trên `app/core.js` — sẽ lệch khi bạn xoá dần; tìm theo chuỗi trong ngoặc.

## 1. Mục tiêu

1. Toàn bộ BJ-04 (UIF-04: SCR-021) vào `app/bj04.js`, BJ-05 (UIF-05: SCR-025…029) vào `app/bj05.js`: fixture, trạng thái, helper, hàm dựng cuối cùng, xử lý sự kiện.
2. Gỡ phần BJ-04 / 05 khỏi các lớp cũ: `v396` (xoá cả khối), `v393` (xoá cả khối), các đoạn trong `v350`, `v360` và trong các listener chung của `app.js`.
3. `UIF-04`, `UIF-05` vào `ownedFlows`: màn dựng thẳng, không qua bước sửa sau dựng.
4. **Giao diện không đổi:** golden khớp hoàn toàn; bấm thử 0 lỗi JS.

Không làm: đổi thiết kế; dọn CSS của BJ-04 / 05 (gói A11); gỡ cơ chế chuyển sang BJ-17 khi kết quả chưa rõ (`data-v350-action="handoff-unknown"`, dùng chung nhiều BJ — gói A10).

## 2. Bản đồ hiện trạng

### 2.1 BJ-04

| Phần | Ở đâu | Xử lý |
|---|---|---|
| Hàm dựng **đang chạy** của SCR-021 | Khối `v396-bj04-semantic-hardening.js`: `lines`, `model`, các hàm `remaining`, `shortage`, `activeHold`, `terminal`, `lifecycleLabel`, `row`, `banner`, `renderV396`; gán lại `render021IO04` và `renderers['SCR-021']` | **Chuyển** sang `bj04.js` (là bản thắng) |
| `io04Fixture`, `bj04ReservationRow`, `render021IO04` gốc | `app.js` (dòng ~1692, ~2078, ~2085) | **Xoá** — bị `v396` đè, không còn chạy |
| Mục `"SCR-021":render021IO04` | literal `const renderers = {…}` | Xoá |
| Toast "Quay về đơn bán …" | listener `data-action` chung (`if (action === "exit-reservation-context") …`, dòng ~3954), đọc `io04Fixture.order` | Chuyển vào `bj04.js`, đọc `model.order` (cùng giá trị `SO-260827-18`) |
| `window.io04V396 = model` | `v396` | Bỏ (không nơi nào đọc; kiểm bằng `grep -rn io04V396`) |

### 2.2 BJ-05

| Phần | Ở đâu | Xử lý |
|---|---|---|
| Fixture + trạng thái: `IO05_ACTOR`, `io05Orders`, `let io05SelectedOrderId… io05QueueFilter… io05Query`, `let io05ActiveLineId… io05OverrideReason`, `let io05PickEditorOpen, io05PickDraft`, `let io05HandoverByAllocation, io05LastResult, io05StaleAppliedForOrder` | `app.js` dòng ~1696–1726 | Chuyển |
| Helper `io05*` (`io05CurrentOrder` … `io05ApplyHandover`, ~37 hàm) | `app.js` dòng ~1727–1796 | Chuyển |
| `updateIO05AllocationValidation`, `updateIO05HandoverValidation` | `app.js` dòng ~2047, ~2054 | Chuyển |
| `bj05DsTone`, `bj05ReadOnlyListRow`, `bj05TextArea`, `bj05Link`, `bj05SelectionRow`, `bj05OverrideSheet`, `bj05ResultDetails`, `bj05PickEditorSheet`, `render025IO05` … `render029IO05` | `app.js` dòng ~2111–2214 | Chuyển |
| Khởi tạo phiên bản nguồn: `io05Orders.forEach(o=>{o.sourceVersion ??= 1; …})` | `v350` | Chuyển vào `bj05.js`, ngay sau fixture |
| `io05VisibleOrders` bị gán lại **hai lần**: `v350` (lọc `!closed && !unknownLocked`) rồi `v393` (lọc `!closed`) | `v350`, `v393` | Giữ **một** định nghĩa = bản thắng của `v393`: `io05Orders.filter(o => !o.closed)` |
| `io05ApplyHandover` bị bọc: kiểm `reviewSourceVersion === sourceVersion`, sai thì `SCR-028 = SOURCE_CHANGED` | `v350` (`const v350BaseIO05Apply = io05ApplyHandover; io05ApplyHandover = function(){…}`) | Gộp phần kiểm vào đầu hàm gốc trong `bj05.js`; xoá wrapper |
| Wrapper `navigate`: vào SCR-028 thì ghi `reviewSourceVersion` | `v350` (`if(activeFlowId==="UIF-05" && screenId==="SCR-028") …`) | Dùng móc `onScreenEnter` mới (mục 4.1); xoá dòng trong wrapper |
| SCR-029 khi `UNKNOWN` / `COMMIT_UNKNOWN`: hai lớp — `v350` (danh sách `unknowns` của `wrapUnknown`) rồi `v393` (bản thắng, dựng `ioResult` "Kết quả chưa xác định" + nút "Chuyển sang xác minh") | `v350`, `v393` | Gộp nhánh của `v393` vào `render029IO05`; xoá mục `["SCR-029","UIF-05",…]` trong `unknowns`; xoá khối `v393` |
| Toast "Đã cập nhật lô lấy hàng" | bảng toast `v360` (`['[data-io05-action="confirm-lot-override"]', …]`) | Gọi `showToast` trong handler, ngay sau `renderAppScreen()` |
| Ô tìm, nhập số lượng, lý do đổi lô, bản nháp số lượng | listener `input` chung (`// Inventory Operations interactions`): 5 dòng `if(activeFlowId==="UIF-05" && …)` | Chuyển sang listener `input` của `bj05.js` |
| Click: lọc, chọn đơn, chọn dòng, mở editor số lượng, đóng editor, mở / đóng sheet đổi lô, chọn lô | listener click chung (`if(!["UIF-04","UIF-05","UIF-06","UIF-07"].includes(activeFlowId)) return;`): 8 dòng `f5`, `o5`, `l5`, `pickAllocation`, `[data-io05-pick-editor-backdrop]`, `openOverride`, `[data-io05-override-backdrop]`, `selectLot` | Chuyển sang listener click của `bj05.js` |
| Hành động `data-io05-action` | **cùng** listener click chung, đoạn `const a=event.target.closest("[data-io05-action],[data-io06-action],[data-io07-action]")` | Xem bẫy 7.1 |

**Giữ nguyên (dùng chung, gỡ ở gói khác):** nhánh `UIF-05` trong `v350LockSourceForUnknown` và listener `handoff-unknown` của `v350` (gói A10); `bumpIO05Source` trong công cụ dev `window.__VET45_PROTOTYPE__` của `v350` (gói A11); các mục `SCR-025` / `SCR-029` trong `v360RootScreens` / `v360ExitTargets` (đo ở 4.5); `figma-ds-runtime-map` (inspector, gói A11). Các hàm này gọi `io05CurrentOrder()` theo tên toàn cục nên vẫn chạy sau khi chuyển.

## 3. Chuẩn bị

1. `python3 -m http.server 8765 --bind 127.0.0.1 &` trong thư mục `html/`.
2. Thêm kịch bản golden (mục 6) vào `tools/golden.mjs`, rồi:
   ```bash
   node tools/golden.mjs capture tools/.golden-base
   node tools/golden.mjs capture tools/.golden-check
   node tools/golden.mjs compare tools/.golden-base tools/.golden-check   # phải "Khớp hoàn toàn"
   ```
3. Mở từng ảnh `SC_bj04_*`, `SC_bj05_*` trong `.golden-base`: **mỗi bước phải làm màn đổi** (chữ trong `.txt` khác bước trước). Bước nào không đổi → sửa selector rồi chụp lại. Golden chỉ bảo vệ được thao tác thật sự chạy.

## 4. Các bước

### 4.1 `app/core.js` — móc "khi vào màn" (khung)

Thêm ngay trước `function navigate(screenId)`:

```js
// Móc chạy khi điều hướng vào một màn (khoá "UIF-NN:SCR-NNN"), thay cho việc bọc navigate.
const onScreenEnter = {};
```

Sửa thân `navigate` gốc (giữ phần còn lại):

```js
function navigate(screenId) {
  if (!renderers[screenId]) return;
  onScreenEnter[`${activeFlowId}:${screenId}`]?.();
  activeScreenId = screenId;
  syncReviewUrl();
  render();
}
```

Các wrapper `navigate` cũ (`v350`, `v430`, `v460`, `v461`) vẫn bọc ngoài và gọi xuống hàm này, nên thứ tự cũ giữ nguyên: nhánh trong wrapper chạy trước, rồi tới móc.

### 4.2 `app/bj04.js`

1. Thay chú thích đầu file bằng: BJ-04, UIF-04, SCR-021; "Đã viết lại sạch (T7-P gói A1, ngày …)"; dùng chung từ `core.js` (`appShell`, `ds24ListRow`, `ds24Badge`, `ds24InfoGroup`, `ds24InfoRow`, `ds24SectionTitle`, `vBanner`, `deniedBody`, `loadingBody`, `escapeAttribute`, `showToast`).
2. Chép từ khối `v396`: `lines`, `model`, `remaining`, `shortage`, `activeHold`, `terminal`, `lifecycleLabel`, `row`, `banner`, `renderV396`. Đặt tên rõ ở cấp file (không còn IIFE): `const bj04Lines`, `const bj04Model`, `function bj04Remaining(l)`, …, `function render021BJ04(state)`.
3. `render021BJ04(state)` = thân `renderV396` với chuẩn hoá trạng thái của `v396`: `['READY','LOADING','PERMISSION_DENIED'].includes(state) ? state : 'READY'`. Bỏ nhánh `if(activeFlowId!=='UIF-04') return renderGeneric(…)` (SCR-021 chỉ thuộc UIF-04, luồng đã sở hữu).
4. Đăng ký:
   ```js
   Object.assign(renderers, { "SCR-021": render021BJ04 });
   ownedFlows.add("UIF-04");
   ```
5. Listener:
   ```js
   document.addEventListener("click", (event) => {
     if (activeFlowId !== "UIF-04") return;
     if (event.target.closest('[data-action="exit-reservation-context"]')) return showToast(`Quay về đơn bán ${bj04Model.order}`, "info");
   });
   ```
6. Xoá trong `core.js`: `io04Fixture`, `bj04ReservationRow`, `render021IO04` (app.js); mục `"SCR-021":render021IO04` trong literal `renderers`; dòng `if (action === "exit-reservation-context") …` trong listener `data-action` chung; **cả khối** `===== v396-bj04-semantic-hardening.js =====`.

### 4.3 `app/bj05.js`

1. Chú thích đầu file như 4.2 (BJ-05, UIF-05, SCR-025…029). Ghi rõ phần **còn ở `core.js`**: helper chung `io*` (`ioSearchBar`, `ioMatchesSearch`, `ioFilterRows`, `ioMetaRow`, `ioReadCard`, `ioEmpty`, `ioResult`, `resultHero`, `ioFilterChips`… — BJ-06 / 07 cũng dùng), cơ chế `handoff-unknown` của `v350`.
2. **Chép** theo đúng thứ tự trong `app.js`: fixture + trạng thái → helper `io05*` → `updateIO05AllocationValidation`, `updateIO05HandoverValidation` → `bj05*` → `render025IO05` … `render029IO05`. Đổi tên hàm dựng thành `render025BJ05` … `render029BJ05` (cho thống nhất với `bj01.js`); helper giữ tên cũ (các lớp chung như `v350LockSourceForUnknown` còn gọi `io05CurrentOrder`).
3. Ngay sau fixture, chép dòng khởi tạo của `v350`:
   ```js
   io05Orders.forEach((o) => { o.sourceVersion ??= 1; o.reviewSourceVersion ??= null; o.unknownLocked ??= false; });
   ```
4. `io05VisibleOrders`: sửa định nghĩa trong `bj05.js` thành `function io05VisibleOrders() { return io05Orders.filter((o) => !o.closed); }`.
5. `io05ApplyHandover`: thêm phần kiểm của `v350` vào **đầu** hàm (nguyên văn):
   ```js
   const o = io05CurrentOrder();
   if (!o || num(o.reviewSourceVersion) !== num(o.sourceVersion)) {
     stateByScreen["SCR-028"] = "SOURCE_CHANGED";
     if (activeScreenId === "SCR-028") renderAppScreen();
     return null;
   }
   ```
   `num` là hàm cục bộ trong IIFE của `v350` (`const num = (v) => Number(v ?? 0);`), không có bản toàn cục: trong `bj05.js` viết `Number(o.reviewSourceVersion ?? 0) !== Number(o.sourceVersion ?? 0)` (cùng kết quả).
6. `render029BJ05`: thêm vào **đầu** hàm nhánh của `v393` (nguyên văn, đổi `v393Attr` → `escapeAttribute`):
   ```js
   if (["UNKNOWN", "COMMIT_UNKNOWN"].includes(state)) {
     const o = io05CurrentOrder(); io05MarkUnknown(o); o.unknownLocked = true;
     const operation = o.operationId || o.id;
     const scope = `${o.customer} · ${o.warehouse}`;
     const body = ioResult("Kết quả chưa xác định", "Không gửi lại bàn giao. Giữ nguyên đúng lần xử lý này và chuyển sang xác minh trước khi cho phép lấy/bàn giao lại.", [["Nghiệp vụ", operation], ["Phạm vi", scope], ["Trạng thái", "Đang xác minh bàn giao"]], "warning");
     const attrs = `data-v350-action="handoff-unknown" data-source-flow="UIF-05" data-operation="${escapeAttribute(operation)}" data-scope="${escapeAttribute(scope)}"`;
     return appShell({ title: "Xác minh kết quả", body, actions: primaryFooter("Chuyển sang xác minh", attrs), centered: true, back: false });
   }
   ```
   So chữ với khối `v393` trước khi xoá (chữ phải giống hệt).
7. Móc vào SCR-028:
   ```js
   onScreenEnter["UIF-05:SCR-028"] = () => { const o = io05CurrentOrder(); o.reviewSourceVersion = o.sourceVersion; };
   ```
8. Đăng ký:
   ```js
   Object.assign(renderers, { "SCR-025": render025BJ05, "SCR-026": render026BJ05, "SCR-027": render027BJ05, "SCR-028": render028BJ05, "SCR-029": render029BJ05 });
   ownedFlows.add("UIF-05");
   ```
9. **Listener `input`** của `bj05.js`: chép 5 dòng `if(activeFlowId==="UIF-05" && event.target.matches("[data-io05-…]"))` từ listener `input` chung (giữ `return` của từng dòng). Xoá 5 dòng đó khỏi listener chung.
10. **Listener `click`** của `bj05.js`:
    ```js
    document.addEventListener("click", (event) => {
      if (activeFlowId !== "UIF-05") return;
      // 8 dòng f5, o5, l5, pickAllocation, pick-editor-backdrop, openOverride, override-backdrop, selectLot — chép nguyên văn
      const a = event.target.closest("[data-io05-action]"); if (!a) return;
      event.preventDefault(); event.stopPropagation();
      const k = a.dataset.io05Action;
      // các nhánh io05 — xem 4.4
    });
    ```
    Xoá 8 dòng đó khỏi listener click chung.
11. Xoá trong `core.js`: mọi thứ đã chép ở bước 2 (app.js); mục `"SCR-025"…"SCR-029"` trong literal `renderers`; dòng khởi tạo + gán lại `io05VisibleOrders` + wrapper `io05ApplyHandover` + dòng `UIF-05` trong wrapper `navigate` + mục `SCR-029` trong `unknowns` (tất cả trong `v350`); **cả khối** `===== v393-bj05-semantic-hardening.js =====`; dòng toast `confirm-lot-override` trong `v360`.

### 4.4 Tách hành động `data-io05-action` khỏi listener chung

Listener chung bắt `[data-io05-action],[data-io06-action],[data-io07-action]` rồi rẽ theo khoá `k`. Chuyển sang `bj05.js` các nhánh sau (lấy đúng phần chạy khi `activeFlowId === "UIF-05"`):

| Khoá | Trong listener chung | Đưa sang `bj05.js` |
|---|---|---|
| `review-handover` | `if(activeFlowId==="UIF-05"){…; return navigate("SCR-028");}` rồi code BJ-07 | Chỉ phần trong `if(activeFlowId==="UIF-05")`; **bỏ** cặp `if` đó khỏi listener chung, giữ code BJ-07 |
| `confirm-handover` | `if(activeFlowId==="UIF-05"){…}` rồi code BJ-07 | Như trên |
| `update-pick-allocation`, `close-lot-override`, `confirm-lot-override`, `confirm-physical-correction`, `save-pick`, `back-to-pick`, `result-to-queue`, `continue-remaining` | Nhánh riêng của BJ-05 | Cả nhánh |

Sau đó **đổi selector** của listener chung thành `"[data-io06-action],[data-io07-action]"` và dòng `const k=…` thành `a.dataset.io06Action || a.dataset.io07Action`. Trước khi xoá một khoá khỏi listener chung, chạy `grep -n 'data-io0[67]-action="<khoá>"' app/core.js` — khoá nào BJ-06 / 07 cũng dùng thì **giữ** nhánh đó ở listener chung.

`confirm-lot-override`: sau `return renderAppScreen()` hiện có, đổi thành `renderAppScreen(); return showToast("Đã cập nhật lô lấy hàng", "success");` (thay toast hẹn giờ của `v360`).

### 4.5 Đo bước sửa sau dựng (trước khi tin golden)

Trên trang `?uif=UIF-05&screen=SCR-025` (đã có `bj05.js`, **chưa** có dòng `ownedFlows.add("UIF-05")` — tạm comment dòng đó), dán vào console:

```js
(async () => {
  const app = document.getElementById("app-screen");
  const tick = () => new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(r)));
  const out = [];
  for (const flow of ["UIF-04", "UIF-05"]) {
    activeFlowId = flow;
    for (const id of flowCatalog.find((f) => f.id === flow).screens) {
      for (const st of screens.find((s) => s.id === id).states) {
        activeScreenId = id; stateByScreen[id] = st;
        renderFlowScreen(); await tick(); const piped = app.innerHTML;
        app.innerHTML = renderers[id](st); const bare = app.innerHTML;
        if (piped !== bare) { let i = 0; while (piped[i] === bare[i]) i++; out.push({ id, st, piped: piped.slice(i - 80, i + 160), bare: bare.slice(i - 80, i + 160) }); }
      }
    }
  }
  console.log(out.length ? out : "không khác");
})();
```

- `"không khác"` → bỏ comment `ownedFlows.add` và đi tiếp.
- Có khác → xem chỗ khác (thường là class `v440-grouped-surface` thêm vào danh sách, thứ tự nút footer của `v361`, nút "Về danh sách" của `v360`) và **gộp vào hàm dựng** của `bj05.js` để HTML trần ra giống hệt; chạy lại đến khi "không khác". Ghi lại các chỗ đã gộp ở mục 9.
- Lưu ý `render029` ở `UNKNOWN` làm đổi trạng thái fixture (`unknownLocked`) — tải lại trang trước khi chạy lại đoạn đo.

## 5. Kiểm

| Kiểm | Cách | Đạt khi |
|---|---|---|
| Cú pháp | `node --check app/core.js app/bj04.js app/bj05.js` | Không lỗi |
| Không còn mã cũ | `grep -n "io05\|io04\|bj05\|bj04\|render02[1-9]IO0" app/core.js` | Chỉ còn: `v350LockSourceForUnknown` (nhánh UIF-05), `bumpIO05Source`, mục `SCR-025` / `SCR-029` trong `v360RootScreens` / `v360ExitTargets`, `figma-ds-runtime-map`. Không còn khối `v393`, `v396` |
| Golden | `capture tools/.golden-check` rồi `compare tools/.golden-base tools/.golden-check` | **Khớp hoàn toàn** (714 ca cũ + kịch bản mới) |
| Lỗi JS | `tools/.golden-check/_errors.json` | Rỗng |
| Bấm thử | Phiên review chạy bộ bấm thử khi review | 0 lỗi |
| Luồng khác | Kịch bản `SC_quick_UIF-05_*`, `SC_ws_movement_1_*` (Hub → Lấy & bàn giao) | Khớp |

## 6. Kịch bản golden thêm (`tools/golden.mjs`)

Thêm helper cạnh `click` / `search`:

```js
const typeIn = (sel, value) => `(()=>{const i=document.querySelector(${JSON.stringify(sel)});if(!i)return false;i.value=${JSON.stringify(value)};i.dispatchEvent(new Event('input',{bubbles:true}));return true})()`;
```

| Tên | Bắt đầu | Bước |
|---|---|---|
| `SC_bj04` | `?uif=UIF-04&screen=SCR-021` | `#app-screen .app-back-button` (toast "Quay về đơn bán SO-260827-18") |
| `SC_bj05_list` | `?uif=UIF-05&screen=SCR-025` | `[data-io05-filter="WAITING"]` → `[data-io05-filter="ALL"]` → `typeIn('[data-io05-search]','Minh')` → `typeIn('[data-io05-search]','')` → `[data-io05-order="SO-260827-21"]` |
| `SC_bj05_waiting` | như trên | `[data-io05-order="SO-260827-24"]` (đơn đang chờ — không mở) |
| `SC_bj05_pick` | như trên | `[data-io05-order="SO-260827-21"]` → `[data-io05-line]` (dòng đầu) → `[data-io05-pick-allocation]` → `typeIn('[data-io05-pick-draft]','6')` → `[data-io05-action="update-pick-allocation"]` → `[data-io05-action="save-pick"]` |
| `SC_bj05_override` | như trên | `[data-io05-order="SO-260827-21"]` → `[data-io05-line]` → `[data-io05-open-override]` → `[data-io05-select-lot]` (lô đầu) → `typeIn('[data-io05-override-reason]','Lô gần hạn hơn')` → `[data-io05-action="confirm-lot-override"]` |
| `SC_bj05_handover` | như trên | `[data-io05-order="SO-260827-21"]` → `[data-io05-action="review-handover"]` → `[data-io05-action="confirm-handover"]` → `[data-io05-action="result-to-queue"]` |
| `SC_bj05_unknown` | `?uif=UIF-05&screen=SCR-029&state=UNKNOWN` | `[data-v350-action="handoff-unknown"]` (sang BJ-17) |

Bước nào không làm đổi màn ở lần chụp đầu → chỉnh selector (mục 3.3). Ghi selector đã chỉnh ở mục 9.

## 7. Bẫy

1. **Listener hành động chung** (4.4): bỏ nhánh BJ-05 mà quên đổi selector thì nút BJ-05 (`review-handover`, `confirm-handover`) chạy nhầm code BJ-07 → lỗi `io07Current()` / dữ liệu sai. Golden `SC_bj05_handover` bắt được.
2. **Thứ tự listener:** listener của `bj05.js` đăng ký sau listener chung. Listener chung có `stopPropagation()` — chỉ chặn lan sang phần tử khác, không chặn listener khác trên `document`, nên không ảnh hưởng. Đừng đổi sang `stopImmediatePropagation()`.
3. **Hàm toàn cục bị gán lại:** `io05VisibleOrders`, `io05ApplyHandover` — sau khi xoá phần gán lại trong `v350` / `v393`, chỉ còn định nghĩa trong `bj05.js`. `grep -n "io05VisibleOrders\s*=\|io05ApplyHandover\s*=" app/*.js` phải rỗng.
4. **Hàm có tham số mặc định dạng object** (bẫy của A0): khi cắt hàm bằng công cụ, tìm thân hàm sau dấu `)` đóng tham số.
5. **Biến khai báo gộp** (`let a=…, b=…, c=…;`): chuyển nguyên câu, đừng tách sót biến.
6. **`num`** không phải hàm toàn cục (bước 4.3.5).

## 8. Ghi lại và commit

1. `CHANGELOG.md`: mục `[5.1.1] — T7-P Giai đoạn 1, gói A1: BJ-04, BJ-05 viết lại sạch` (chuyển gì, gỡ lớp nào, móc `onScreenEnter`, kịch bản golden mới). `manifest.json` → `5.1.1`.
2. `docs/refactor/plans/T7/T7-P-thiet-ke-lai-luong.md` mục 14: A1 Làm ✅. Mục 8.1: ghi "móc `onScreenEnter`" vào ghi chú gói A1 (các gói sau dùng lại thay cho wrapper `navigate`).
3. `python3 tools/sync-registry.py`.
4. `detect_changes()` theo CLAUDE.md (chỉ đổi prototype), rồi commit: `refactor(prototype): T7-P A1 — BJ-04, BJ-05 clean code in app/bj04.js, app/bj05.js`.

## 9. Ghi chú khi làm

- Đo 4.5 (pipe vs bare, tạm bỏ `ownedFlows`): **không khác** — không cần gộp thêm lớp sau dựng.
- Golden selector chỉnh so với mục 6:
  - `SC_bj05_pick`: allocation `AL-21-02`, draft `10` (AL-21-01 max 4 nên draft `6` làm nút Cập nhật disabled).
  - `SC_bj05_override`: thêm bước mở pick editor (`AL-21-01`) trước `open-override`; chọn lô `DH2509`.
  - `SC_bj05_handover`: bước cuối `continue-remaining` (fixture bàn giao một phần — không có nút `result-to-queue`).
  - `SC_bj05_waiting`: lọc WAITING rồi bấm đơn disabled (bước cuối không đổi màn — chủ đích).
  - `select-lot` / `reason` / `pick-draft`: `innerText` có thể không đổi; bước sau (confirm/update) vẫn đổi màn.
- Lệch plan nhỏ khi cắt khối: lần đầu regex gỡ BJ-04/05 nuốt luôn fixture io06/io07 — đã khôi phục vào `core.js`; `bj05.js` chỉ còn IO05.

## 10. Review

- **Ngày:** 2026-10-19, rà trên working tree cuối Giai đoạn 1 (sau A11, chưa commit; HEAD `4c7020013`). Code A1 đã được A10 / A11 sửa tiếp (móc `onUnknownHandoff`, `__VET45_QA__`) — rà theo trạng thái cuối. Kiểm chung của cả Giai đoạn 1: [plan tổng mục 14.1](T7-P-thiet-ke-lai-luong.md#141-review-giai-đoạn-1-2026-10-19).
- **Kết quả: ✅ đạt.**
- **Đã kiểm:**
  - Golden: mọi ca `UIF-04_*`, `UIF-05_*`, `SC_bj04`, `SC_bj05_*`, `SC_quick_UIF-05`, `SC_ws_movement_*` — chữ khớp mốc trước Giai đoạn 1 (`tools/.golden-base`, `.golden-a5-base`); ảnh chỉ lệch ở góc khung thiết bị (lỗi A11, mục 14.1). `SC_bj05_unknown_1_handoff` sang BJ-17 như mốc gốc.
  - `grep "io05VisibleOrders\s*=\|io05ApplyHandover\s*=" app/*.js` rỗng; `core.js` không còn `io04` / `io05` / `v393` / `v396`; `bumpIO05Source` đã vào `__VET45_QA__` (A11).
  - `bj04.js`: một bản dựng `render021BJ04`, toast "Quay về đơn bán SO-260827-18" trong listener riêng. `bj05.js`: kiểm `sourceVersion` ở đầu `io05ApplyHandover`, nhánh UNKNOWN của `v393` ở đầu `render029BJ05` (chữ giống hệt), móc `onScreenEnter["UIF-05:SCR-028"]`, toast đổi lô gọi ngay sau `renderAppScreen()`.
  - Móc khung `onScreenEnter` nằm trong `navigate` gốc, sau `screenAliases` (A5) — đúng thứ tự plan.
- **Góp ý (không chặn, làm ở gói A12 bước R4):**
  1. Chú thích đầu `bj04.js` dòng 3 cụt câu ("… nằm ở đây; màn dựng") — phần "thẳng qua `ownedFlows`…" bị A11 xoá dở. Cùng lỗi ở `bj01.js` dòng 4.
  2. `bj05.js` dòng 9 thừa thụt đầu dòng `  */` (cũng ở `bj06.js`, `bj07.js`).
