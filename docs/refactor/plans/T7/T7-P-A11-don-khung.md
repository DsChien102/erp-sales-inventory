# T7-P · Gói A11 — dọn khung `core.js`, tách harness, dọn CSS không dùng

> Theme: Theme 7 Inventory · Trạng thái: Plan ✅ | Làm ✅ | Review ✅
> Thuộc [T7-P](T7-P-thiet-ke-lai-luong.md) Giai đoạn 1, gói A11 (mục 4.2, 8.1). Ước lượng: **~3 ngày, 1 commit**, 8 chặng (0 → 7), golden kiểm sau mỗi chặng.
> Người làm: bạn. Review: phiên plan / review. Làm **sau A10** (mọi luồng đã ở `ownedFlows`). Xong A11 = **hết Giai đoạn 1**.
> **Phạm vi đã chốt (2026-10-19):** CSS chỉ làm phần an toàn (xoá luật không dùng, tách CSS harness, xoá `.cr-*` / `.ac310-*` chết) — **gom CSS theo BJ và bỏ `!important` dời sang bước C của từng BJ ở Giai đoạn 2**. Giữ tên thuộc tính `data-v350-action` / `data-v360-action` (đổi theo BJ ở Giai đoạn 2); gộp mọi API QA `window.__VET45_V350__` / `__V360__` / `__V3101__` / `__BJ10__` / `__V440__`… thành **một** `window.__VET45_QA__`, sửa `tools/golden.mjs` theo.

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/`. Đo ngày 2026-10-19 trên working tree sau A10 (`core.js` 1629 dòng, `manifest.json` 5.2.0) — chỉ neo theo chuỗi; chạy lại mục 2.8 trước khi bắt đầu.

## 1. Mục tiêu

1. `core.js` chỉ còn **khung sản phẩm**: trạng thái + routing lối vào, `renderers` / `flowRenderers` / `flowScreen`, `renderAppScreen` / `render` / `navigate` / `previousScreen` / `syncReviewUrl`, các móc (`onScreenEnter`, `onPrevious`, `onUnknownHandoff`, `screenAliases`), helper DS (`appShell`, `ds24*`, `vBanner`, `primaryFooter`, `icon`, `io*` / `ic*` còn dùng…), toast, lối ra dự phòng, actor, API QA. **Không còn khối `vNNN-…` / IIFE lớp vá, không còn bọc `render` / `renderFlowScreen` / `navigate`.**
2. `renderAppScreen()` chỉ còn: màn gốc theme → `ThemeApp.renderRoot()`; còn lại → `rendererFor(activeFlowId, activeScreenId)(state)` + `ThemeApp.afterFlowRender()`. Xoá `renderFlowScreen`, `ownedFlows`.
3. Bước sau dựng còn sống (`simplifyNormalBanners`, `v440` grouped surface) được gộp vào hàm dựng hoặc thành **một** bước dựng chung có tên trong khung (mục 2.2).
4. Harness (sidebar, chọn luồng / màn / trạng thái, inspector, Inspect overlay, khung thiết bị, `__VET45_PROTOTYPE__`, bản đồ Figma DS) → `harness/workbench.js` (+ `harness/figma-ds-map.js` mới); CSS harness → `harness/workbench.css`. Hai file `harness/workbench.*` **đã có** (mỗi file 2 dòng chú thích "chưa tách"; `<link>` ở `index.html` dòng 11, `<script>` ở dòng 133 sau `hub.js`) — điền vào file có sẵn, không tạo mới.
5. Helper dùng chéo đúng chỗ: `bj01Empty` → `core.js` tên `ds24EmptyState`; bản trùng `icCard…icApprovalButtons` (`core.js` + `bj09.js`) → một bản ở `shared-control.js`.
6. CSS: xoá luật không dùng (đo bằng chế độ `usage` mới của `tools/golden.mjs`), gồm `.cr-*` / `.ac310-*` chết. **Không** đổi thứ tự luật còn lại, **không** bỏ `!important`.
7. Xoá mã chết JS còn lại (độ phủ + `grep`), file tạm của các gói trước.
8. **Giao diện và hành vi không đổi**: golden khớp hoàn toàn, trừ khác biệt có chủ đích ở mục 2.2 (nếu có, ghi CHANGELOG).

Không làm: gom CSS theo BJ / bỏ `!important` / bỏ luật `[data-active-uif=…]` (Giai đoạn 2, bước C của từng BJ); đổi tên thuộc tính `data-v3xx-*` (Giai đoạn 2); sửa chữ inspector lỗi thời (golden đọc); bỏ nhánh `FIGMA_MIGRATED_FLOWS.has(...) === false` (mục 2.7); lỗi ở mục 2.7.

## 2. Bản đồ hiện trạng

### 2.1 `core.js` sau A10 — khối nào sống, khối nào chết

| Khối (dòng ≈) | Nội dung | Sống? | Xử lý |
|---|---|---|---|
| `figma-ds-runtime-map.js` (16) | `window.VET45_FIGMA_DS_MAP` (một dòng ~20 KB) | Sống — chỉ Inspect (`resolveFigmaMapping`, `figmaAssetTarget`) | → `harness/figma-ds-map.js` |
| `app.js` đầu (18–110) | `HARNESS`, fixture `__VET45_MONEY_*` / `FX` / `TAX` / `COST_POLICY`, `FIGMA_MIGRATED_FLOWS`, `FIGMA_TEMPLATE_*`, `screens`, `flowCatalog`, `FLOW_GROUPS`, routing `entry` | Sống | Giữ (khung); `FLOW_GROUPS` / `flowGroupLabel` → harness; routing gộp với `v350EntryTargets` (chặng 3) |
| Icon, helper DS, `io*` / `ic*` / `ds24*` (113–530) | | Phần lớn sống | Xoá hàm không ai gọi (chặng 1, 7); bản trùng `ic*` (chặng 4) |
| Dòng chú thích `/* … → app/bjNN.js (T7-P Ax) */` (88 dòng theo `grep -c` mục 2.8, rải khắp file) | Dấu vết chuyển file | — | Xoá hết (git giữ lịch sử) |
| `renderers` / `flowRenderers` / `flowScreen` / `renderAppScreen` / `renderFlowScreen` (592–623) | | `renderFlowScreen` **chết** (mọi luồng ở `ownedFlows`) | Rút gọn (chặng 1) |
| `render`, `syncReviewUrl`, móc, `navigate`, `previousScreen`, toast (625–701) | | Sống | Giữ; `showToastLegacy` chết → xoá |
| Inspect (703–1017) | overlay, `resolveFigmaMapping`, `toggleInspect`, listener capture | Sống — harness | → `harness/workbench.js` |
| Listener click chung (1019–1048) | `[data-screen]`, `[data-state]`, `[data-viewport]` (harness); `[data-next]`, `[data-back]`, `close-toast` (sản phẩm) | Sống | Tách đôi: harness / khung |
| Listener `flow-selector`, `data-generic-*` (1062–1068) | `data-generic-*` chỉ cho `renderGeneric` | Sống (fallback) | `flow-selector` → harness; `data-generic-*` giữ nếu độ phủ còn chạm (chặng 7) |
| `fitReviewDeviceToViewport`, `__VET45_PROTOTYPE__`, `?inspect=1` (1071–1106) | | Sống — harness | → harness |
| `v350` (1112–1234) | `v350DeclaredStates` (thêm trạng thái cho SCR-040 / SCR-046 lúc nạp); `v350EntryTargets` / `v350ApplyEntry` (gọi lúc nạp khi không có `screen`); `v350ActorMode`; wrapper `navigate` rỗng; `__VET45_V350__` | Sống trừ wrapper | Chặng 3 |
| `v360` (1238–1335) | `ensureRepresentativeFixture` (rỗng), `ensureStableExitAffordance` + `v360RootScreens` / `v360ExitTargets` (bọc `renderFlowScreen` → **chết**); listener `fallback-exit` (**sống**: `bj08/09/10/11/12/15/16/17` phát `data-v360-action="fallback-exit"`); `simplifyNormalBanners` (bọc `render` → **sống**, mục 2.2); metadata `__VET45_PROTOTYPE__`; `__VET45_V360__` (cap01 `Object.assign` thêm hàm) | Một phần | Chặng 1–3 |
| `v361` (1337–1412) | `normalizeDualFooters` bọc `renderFlowScreen` | **Chết** (bj02 / bj08 / cap01 đã viết sẵn lớp `v361-dual-footer`) | Xoá JS, **giữ CSS** |
| `v362`, `v363`, `v364`, `v450` | Chỉ ghi `version` / `scenarios` | Chết (metadata) | Xoá |
| `v440` (1460–1540) | `applyGroupedSurfaceRule`: bọc `renderFlowScreen` (chết) **và** bọc `render` + `MutationObserver` trên `#app-screen` (**sống**, chạy cả trên luồng đã sở hữu) | Sống | Chặng 2 (mục 2.2) |
| `v470` (1552–1626) | `decorate()` thoát sớm khi `ownedFlows.has(activeFlowId)` → **chết**; đổi chữ `.review-badge` ở header harness (không nằm trong golden) | Chết | Xoá JS, **giữ CSS** `v470-kv--*` (bj02 / bj08 / bj11 / bj12 viết sẵn lớp) |

### 2.2 Bước sau dựng còn sống — phải đo trước khi gỡ

| Bước | Khi nào chạy | Tác động hiện biết | Cách gỡ |
|---|---|---|---|
| `simplifyNormalBanners` (`v360`) | Sau `render()` (rAF), chỉ UIF-08/09/10/16/17; **không** chạy khi BJ gọi thẳng `renderAppScreen()` | Thêm `.v360-context-banner` (ẩn icon, đổi màu chữ) cho banner info có tiêu đề: "Cần quyết định độc lập" (`bj08.js` SCR-046), "Phê duyệt chưa phải tiêu hủy" (`bj10.js` SCR-040 `APPROVAL_REVIEW`, 2 chỗ); "Yêu cầu thay đổi tình trạng", "Chỉ xử lý dòng có chênh lệch" không còn ai dựng | Truyền `extraClass` `"v360-context-banner"` vào `vBanner(...)` ở 3 chỗ trên; xoá bước. **Khác biệt có chủ đích:** ca đi tới màn qua `renderAppScreen()` (bấm trong BJ) trước đây không có lớp → nay có. Liệt kê các ca golden khác trong CHANGELOG; ngoài các ca đó phải khớp |
| `applyGroupedSurfaceRule` (`v440`) | Sau `render()` và mỗi lần DOM `#app-screen` đổi (`MutationObserver`, microtask) — mọi luồng, cả Hub | Thêm `.v440-grouped-surface` + `data-layout-pattern="Grouped surface"` + `data-v440-grouped-surface="auto"` cho phần tử có ≥ 2 Info / Key-value Row con trực tiếp mà chưa có nền / viền / bóng (đo `getComputedStyle`) | **Đo ở chặng 0.** 0 phần tử trên mọi ca golden → xoá cả khối (giữ CSS — bj02 / cap01 viết sẵn lớp). Có phần tử → **giữ làm bước dựng chung** trong khung: hàm `applyGroupedSurfaceRule()` ở mục "Bước dựng chung (DS)" của `core.js`, gọi ở cuối thân `render()` (không bọc) + giữ `MutationObserver`; bỏ phần bọc `renderFlowScreen`; xoá `__VET45_V440__` (đưa hàm vào `__VET45_QA__`). Gộp hẳn vào từng hàm dựng để Giai đoạn 2 |

### 2.3 Routing lối vào và actor (`v350`)

Hai bảng chồng nhau, `v350` chạy sau và thắng:

- Khối routing đầu `core.js` (khi không có `?screen=`): `entry` → màn (UIF-01/02/03/04/05/06/07/11/12/13/16/17).
- `v350ApplyEntry(activeFlowId, entryMode)` lúc nạp: `entry` → **màn + trạng thái** cho UIF-08 (`assigned-counter`, `approver`), 09 (`product-context`, `approver`), 10 (`product-context`, `approver`, `completion-operator`), 11 (`approver` → SCR-051 `READY`, `operation-context` → SCR-049 `CORRECTABLE`), 12 (`approver`), 14 (`dirty-scope` → SCR-073 `READY`).
- Nhánh UIF-14 `dirty-scope` còn chọn kỳ "DIRTY" trong `val14Runs` — **lúc nạp không chạy** (`typeof val14Runs === "undefined"` vì `bj14.js` nạp sau), chỉ chạy khi gọi qua API QA `applyEntry`. Giữ đúng hành vi đó (bẫy 7.3).
- Actor: `v350ActorMode = entryMode`; `bj08/09/10/11/12.js` đọc qua `window.__VET45_V350__?.getActor?.()`; golden đổi actor qua `__VET45_V350__.applyEntry(...)` (`SC_bj12_approve`).

- Khối đầu còn **tác dụng phụ ngoài màn**: `UIF-02` `document-context` đặt `flowMode = "document"` (thắng `?flow=quick`).
- **Thứ tự với `?state=`** (đo 2026-10-19): khối đầu → dòng áp `initialState` (kiểm theo màn **sau** khối đầu) → `v350ApplyEntry` đè trạng thái. Hệ quả hiện tại: mục chỉ có màn (khối đầu) — `?state=` áp lên màn entry; mục có trạng thái (`v350`) — `?state=` bị bỏ.

Đích: **một** bảng `entryTargets = { "UIF-NN": { mode: { screen, state?, flowMode? } } }` trong khung (gộp hai nguồn; mục nào có ở cả hai lấy bản `v350`; `UIF-02 document-context` mang `flowMode: "document"`), **một** hàm `applyEntry(flowId, mode, shouldRender)`, móc `onEntry["UIF-14:dirty-scope"]` do `bj14.js` đăng ký (chọn kỳ DIRTY); `let actorMode = entryMode; function currentActor(){ return actorMode; }`.

Vị trí gọi lúc nạp: **đúng chỗ khối routing đầu** (trước dòng áp `initialState`), và dòng áp `initialState` thêm điều kiện bỏ qua khi mục entry đã áp có `state` — giữ nguyên cả hai hệ quả trên. Gọi ở chỗ `v350` cũ thì `initialState` kiểm theo màn mặc định → sai cho UIF-01…07/13/16/17; gọi ở chỗ khối đầu mà không thêm điều kiện thì `?state=` thắng mục `v350` → sai. Ca golden mục 6 (`SC_entry_state_*`) bắt hai lỗi này.

### 2.4 API QA — gộp thành `window.__VET45_QA__`

| Hiện tại | Định nghĩa ở | Người dùng | Đích |
|---|---|---|---|
| `__VET45_V350__.setActor / getActor / applyEntry / getState` | `core.js` `v350` | golden `SC_bj12_approve` | `__VET45_QA__` trong `core.js` |
| `__VET45_V350__.bumpIO05Source` / `bumpIO06Source` | `core.js` (gọi `io05CurrentOrder` / `io06CurrentRequest` / `io06RefreshRequestState`) | golden không dùng | `bj05.js` / `bj06.js` tự `Object.assign(window.__VET45_QA__, {…})` |
| `bumpCR16Evidence` / `bumpCR17Evidence` / `getBJ17` | `core.js` | golden `SC_bj16_*` / `SC_bj17_*` | `bj16.js` / `bj17.js` |
| `setCf12Control` (bản `core.js` bị `bj12.js` ghi đè) | `core.js` + `bj12.js` | | Một bản ở `bj12.js` |
| `getCf15Rows` | `core.js` | | `bj15.js` |
| `getIC10` (→ `__VET45_BJ10__`), `__VET45_BJ10__` | `core.js`, `bj10.js` | | `bj10.js`: `getIC10` vào `__VET45_QA__`; xoá `__VET45_BJ10__` |
| `getIC09` (→ `__VET45_V3101__`), `__VET45_V3101__` | `core.js`, `bj09.js` | golden `seed09Approver` (`buildBasis`) | `bj09.js`: các hàm của `__VET45_V3101__` + `getIC09` vào `__VET45_QA__` (đặt tên không trùng, vd. `ic09BuildBasis`) |
| `__VET45_V360__` (`ensureRepresentativeFixture` rỗng + hàm cap01 thêm vào) | `core.js`, `cap01.js` | | `cap01.js` gán vào `__VET45_QA__` |
| `__VET45_V361__`, `__VET45_V440__`, `__VET45_V450__` | `core.js` | | Xoá (hoặc `applyGroupedSurfaceRule` vào `__VET45_QA__` nếu giữ, mục 2.2) |
| `__VET45_V3100__` (`getRoundHistory`, `getResult`) | `bj08.js` (~191) | | `bj08.js` gán vào `__VET45_QA__` (vd. `bj08RoundHistory`, `bj08Result`) |
| `__VET45_V399__` (`enrichRun`) | `bj14.js` (~107) | **`bj14.js` tự gọi** (`applyPolicy`, ~252: `window.__VET45_V399__?.enrichRun?.(r,0)`) | `applyPolicy` gọi thẳng `val14EnrichRun(r,0)` (giữ `try`); xoá object |
| `__VET45_TENANT_COST_POLICY_V461__` | `bj14.js` (~251) | Không ai đọc (bí danh của fixture) | Xoá |

Quy tắc gộp: **bỏ** các khoá metadata `version` / `decisions` / `policy` / `scope` / `parent` / `fixtureHashNote` (trùng tên giữa các object cũ); hàm của BJ đặt tên có tiền tố BJ, không trùng `getState` / `applyEntry` / `setActor` / `getActor` của khung.

Giữ nguyên: fixture `window.__VET45_MONEY_CURRENCY_CATALOG__`, `__VET45_FX_SOURCE_FIXTURE__`, `__VET45_TAX_TREATMENT_POLICY__`, `__VET45_TENANT_COST_POLICY__` (dữ liệu, không phải API); `window.__VET45_PROTOTYPE__` (metadata, chuyển sang harness — `bj02.js` dòng ~1203 có ghi vào, giữ). Xoá các khối `v36x` / `v4xx` thì `__VET45_PROTOTYPE__.version` rơi về chữ cố định `"3.6.0"` và mất vài mục `scenarios` — không ai đọc (golden không), nhưng đặt `version: "5.3.0"` khớp `manifest.json`, ghi CHANGELOG.

`__VET45_QA__` khai báo trong `core.js` **trước** mọi file BJ (`window.__VET45_QA__ = {…}`); BJ chỉ `Object.assign`, không gán lại cả object.

### 2.5 Helper dùng chéo, bản trùng

| Mã | Hiện tại | Đích |
|---|---|---|
| `bj01Empty(filtered)` | `bj01.js`, `bj08.js` gọi (SCR-042 `EMPTY`) | `core.js` tên `ds24EmptyState(filtered)` (cạnh `ds24*`); sửa lời gọi ở `bj01.js`, `bj08.js`; chú thích đầu `bj01.js` |
| `icCard`, `icField`, `icTextarea`, `icHeaderRows`, `icSecondary`, `icApprovalButtons` | **Định nghĩa hai lần**: `core.js` và `bj09.js` (bản `bj09.js` nạp sau, thắng); `bj10/11/12.js` gọi | So nguyên thân hai bản (phải giống hệt); giữ một bản ở `shared-control.js`; xoá cả hai bản cũ |
| `io05CurrentOrder`, `io06CurrentRequest`, `io06RefreshRequestState`, `cr16Current`, `cr17Current`, `val14Runs`, `cf12Control*`, `bj12ControlMatches`, `cf15DateMode`, `bj15Movements`, `ic09Current` | `core.js` (`__VET45_V350__`) gọi vào BJ | Hết sau khi chuyển API QA (2.4) |
| `bj01Query`, biến BJ-02 (`selectedDocumentId`, `approvalRejectReason`, `bj02Header`, `bj02Lines`, `resetBj02Receipt`) | `hub.js` đọc | Giữ (Hub là khung theme; tách ở Giai đoạn 2), ghi mục 9 |

### 2.6 Harness — tách khỏi `core.js` / `components.css`

**JS → `harness/workbench.js`** (nạp **ngay sau** `core.js`, trước `shared-*.js` — bẫy 7.5): `FLOW_GROUPS`, `flowGroupLabel`, `renderFlowSelector`, `renderNavigation`, `renderInspector`, `renderFlowInspector` (**giữ nguyên chữ** — golden đọc `current-screen-id`, `current-screen-name`, `workbench-title`, `traceability`), toàn bộ Inspect (`inspectEnabled` … `toggleInspect`, listener `pointermove` / capture `click` / `keydown` / `resize` / `scroll`), phần harness của listener click chung (`[data-screen]`, `[data-state]`, `[data-viewport]`), listener `flow-selector`, đặt lớp `device-preview` / nút viewport lúc nạp, `fitReviewDeviceToViewport` + `resize`, `__VET45_PROTOTYPE__`, `?inspect=1`. `VET45_FIGMA_DS_MAP` → `harness/figma-ds-map.js` (nạp trước `workbench.js`).

`render()` ở `core.js` vẫn gọi `renderFlowSelector()` / `renderNavigation()` / `renderInspector()` / `resetInspectSelection()` / `fitReviewDeviceToViewport()` và đọc `inspectEnabled` — định nghĩa ở harness, có trước lần `render()` đầu (do `hub.js` gọi cuối cùng). Listener `data-generic-*` ở khung cũng đọc `inspectEnabled` (thẻ `.generic-data-card`) — giữ, chỉ đọc lúc chạy.

**Listener chặn của Inspect → `window` capture.** Hiện là `document.addEventListener('click', …, true)` + `stopImmediatePropagation` (`core.js` ~1002). Nó chặn mọi listener bubble bất kể thứ tự; thứ tự đăng ký chỉ quyết định với **listener capture khác trên `document`** (hơn 40 cái ở `bj*.js`, `hub.js`, và `fallback-exit` ~1298 — hiện đăng ký sau Inspect nên bị chặn). Khi chuyển sang harness, đổi thành `window.addEventListener('click', …, true)`: chạy trước mọi listener trên `document`, không còn phụ thuộc thứ tự nạp, `fallback-exit` vẫn bị chặn như hiện tại. Giữ nguyên thân hàm.

**CSS → `harness/workbench.css`:** luật chỉ chọn phần tử harness (ngoài `#app-screen`): `.review-*`, `.sidebar-*`, `.inspector-*`, `.inspect-*`, `.state-chip` / `.state-switcher`, `.screen-nav*`, `.nav-group*`, `.workbench-*`, `.stage-*`, `.viewport-*`, `#flow-selector`, `body.inspect-mode …`, khung thiết bị (`.device-preview`, `--vet45-review-scale`) — ~115 luật trong `components.css` (đếm theo tiền tố) và khối `v281-device-frame-correction.css` trong `screens.css` (dòng ~4071). **Không** chuyển luật trộn (vd. `.device-preview .app-…` chọn phần tử sản phẩm) và mọi luật `[data-theme-*]` của Hub (nằm trong `#app-screen`). Giữ thứ tự tương đối khi chuyển (phần từ `components.css` trước, phần từ `screens.css` sau).

### 2.7 Lỗi / nợ phát hiện — **không sửa ở A11**, ghi cho Giai đoạn 2

| Mục | Hiện tượng |
|---|---|
| Nhãn inspector lỗi thời | `renderFlowInspector` → "Figma DS: v3.0.1 · BJ01 migrated…"; golden đọc `traceability` nên giữ |
| `FIGMA_MIGRATED_FLOWS` chứa cả 18 luồng | Mọi nhánh `calibrated === false` (`statusBar`, `primaryFooter`, `ioMetaRow`, `ioReadCard`, `icCard`, `ioFilterChips`) có thể chết, nhưng chế độ theme có thể đặt `activeFlowId` ngoài tập — không gỡ khi chưa chứng minh |
| Banner ngữ cảnh lúc có lúc không | Mục 2.2: trước A11 chỉ áp khi đi qua `render()` |
| UIF-14 `entry=dirty-scope` lúc nạp không chọn kỳ DIRTY | Mục 2.3 |
| `hub.js` đọc biến của BJ-01 / BJ-02 | Mục 2.5 |
| ~3400 `!important`, ~2400 luật `[data-active-uif=…]`, `screens.css` xếp theo lớp phát hành | Dời bước C Giai đoạn 2 (đã chốt) |

### 2.8 Lệnh đo lại (chạy trước chặng 0)

```bash
grep -n '^/\* ===== \|^(() *=> *{\|^(()=>{' app/core.js                                  # khối còn lại
grep -nE '^\s*(navigate|render|renderAppScreen|renderFlowScreen|previousScreen)\s*=' app/*.js   # bọc hàm khung
grep -ho 'ownedFlows.add("[^"]*")' app/*.js | sort -u | wc -l                            # phải 18
grep -no '__VET45_[A-Z0-9_]*__' app/*.js tools/golden.mjs | sort -u
grep -c '^/\* .*→ \|moved\|(T7-P A' app/core.js                                          # dòng dấu vết
grep -nE '^function (icCard|icField|icTextarea|icHeaderRows|icSecondary|icApprovalButtons)\b' app/*.js
grep -n 'v360-context-banner\|Cần quyết định độc lập\|Phê duyệt chưa phải tiêu hủy' app/*.js | cut -c1-140
```

## 3. Chuẩn bị

1. Server 8765; chụp mốc `.golden-a11-base`, chụp lần hai, so — khớp. Ghi số ca (`Đã chụp N ca`).
2. Thêm kịch bản golden mục 6 **trước** khi sửa code, chụp lại mốc.
3. Trên trình duyệt, ghi lại để so sau khi xong:
   - `?mode=theme&app=inventory` → Hub; bật **Inspect**, rê / ghim một nút trong màn: không kích hoạt hành động; Esc bỏ ghim.
   - `?uif=UIF-08&entry=approver` → SCR-046 `APPROVAL_REVIEW`: banner "Cần quyết định độc lập" **không** có icon (đi qua `render()`).
   - `?uif=UIF-14&entry=dirty-scope` → SCR-073 `READY`.
   - Đổi `viewport` mobile / wide; chọn luồng ở sidebar; bấm chip trạng thái.
   Kết quả khác mô tả → dừng, báo phiên review.

## 4. Các bước

### 4.0 Chặng 0 — công cụ đo (`tools/golden.mjs usage`)

Thêm chế độ `usage <dir>` chạy **đúng danh sách ca của `capture`** (cùng `groups`), không chụp ảnh, thay vào đó:

- **CSS:** `DOM.enable`, `CSS.enable` (ghi `styleSheetId → sourceURL` từ sự kiện `CSS.styleSheetAdded`), `CSS.startRuleUsageTracking` trước mỗi `Page.navigate` (golden mở trang **một lần mỗi nhóm**, nên một cửa sổ đo = một nhóm); hết nhóm gọi `CSS.stopRuleUsageTracking` → `ruleUsage[]` (`styleSheetId`, `startOffset`, `endOffset`, `used`). Bỏ qua stylesheet không có `sourceURL` (thẻ `<style>` golden tự chèn để tắt animation). Gộp mọi nhóm, mọi worker theo khoá `file:startOffset`; luật "dùng" nếu `used` ở **bất kỳ** nhóm nào.
- **Tự kiểm công cụ:** chọn một luật chỉ khớp ở **một** ca giữa nhóm (không phải ca đầu) — `_css-unused.txt` không được chứa nó. Sai → sửa công cụ trước khi dùng kết quả.
- **JS:** `Profiler.enable` + `Profiler.startPreciseCoverage({callCount:true, detailed:false})` trước mỗi nhóm; hết nhóm `Profiler.takePreciseCoverage` → với mỗi script `app/*.js` / `harness/*.js`, mỗi hàm có tên: cộng `count` của range đầu. Gộp theo `file:functionName:startOffset`.
- **Bước sau dựng:** sau mỗi ca ghi `document.querySelectorAll('[data-v440-grouped-surface="auto"]').length` và `document.querySelectorAll('.v360-context-banner').length` (kèm tên ca).
- Ghi `<dir>/_css-unused.txt` (file · dòng · selector, lấy chữ theo offset từ file CSS), `<dir>/_js-uncovered.txt` (file · dòng · tên hàm, `count === 0`), `<dir>/_postrender.txt` (ca có số > 0).

Chạy `node tools/golden.mjs usage tools/.usage-a11-0`. Ghi vào mục 9: số ca có `v440` > 0 (quyết định nhánh của mục 2.2), danh sách ca có `.v360-context-banner`.

### 4.1 Chặng 1 — xoá mã chết JS trong khung

1. Các dòng chú thích dấu vết `/* … → app/… (T7-P Ax) */`, `/* … moved … */` trong `core.js`.
2. `renderFlowScreen` và mọi chỗ bọc nó (`v360` `baseRenderAppScreen` / `ensureRepresentativeFixture` / `ensureStableExitAffordance` / `v360TransientStates` / `v360RootScreens` / `v360ExitTargets`; cả khối `v361`; phần bọc `renderFlowScreen` của `v440`).
3. `renderAppScreen` theo mục 1.2; xoá `ownedFlows` và 18 dòng `ownedFlows.add(...)` ở `bj*.js` / `cap01.js` (sửa chú thích đầu file nếu nhắc).
4. Cả khối `v362`, `v363`, `v364`, `v450`, `v470` (JS). Wrapper `navigate` rỗng của `v350`.
5. `showToastLegacy`, `progress`, `ioFilterChips` (0 lời gọi, đã đo 2026-10-19 — `grep` lại trước khi xoá); bỏ `ioFilterChips` khỏi chú thích đầu `bj05.js` (dòng 6).
6. Chú thích đầu `bj02/05/06/07.js`, `cap01.js` nhắc `v360RootScreens` / `v360ExitTargets` / `v470 (A11)` → sửa.
7. `node --check app/*.js`; golden.

### 4.2 Chặng 2 — gộp bước sau dựng còn sống (mục 2.2)

1. `simplifyNormalBanners`: thêm `"v360-context-banner"` (tham số `extraClass` của `vBanner`) ở `bj08.js` (SCR-046) và `bj10.js` (2 chỗ `APPROVAL_REVIEW`); xoá hàm, phần bọc `render`, `normalInfoBannerTitles`. Golden: liệt kê ca khác (chỉ được là ca vào màn qua `renderAppScreen()`), đối chiếu `_postrender.txt` của chặng 0.
2. `v440`: theo kết quả chặng 0 (xoá cả khối, hoặc giữ thành bước dựng chung — mục 2.2). Golden khớp hoàn toàn.

### 4.3 Chặng 3 — `v350` / `v360` còn lại → khung

1. `v350DeclaredStates`: SCR-040 **bỏ** (`workbench-data.json` đã khai `VALIDATION_ERROR`, `SELF_APPROVAL_NOT_ALLOWED`); SCR-046 `APPROVAL_REVIEW` → đầu `bj08.js` (cùng câu lệnh thêm vào `screens.find(...).states`, chạy lúc nạp — trước `render()` đầu).
2. Routing: gộp thành `entryTargets` + `applyEntry` + `onEntry` (mục 2.3, gồm `flowMode` của `UIF-02 document-context`); gọi `applyEntry(activeFlowId, entryMode, false)` lúc nạp **ở chỗ khối routing đầu** với điều kiện cũ (`!requestedScreen`), dòng áp `initialState` bỏ qua khi mục entry có `state` (mục 2.3). `bj14.js` đăng ký `onEntry["UIF-14:dirty-scope"]`.
3. Actor: `actorMode` / `currentActor()` trong khung; thay `window.__VET45_V350__?.getActor?.()` ở `bj08.js` (3), `bj09.js`, `bj10.js` (3), `bj11.js`, `bj12.js` (2) bằng `currentActor()`.
4. API QA theo mục 2.4 (gồm `V3100`, `V399`, `V461`): `window.__VET45_QA__` trong `core.js`; BJ tự thêm; sửa `tools/golden.mjs` (`__VET45_V350__` → `__VET45_QA__` ở dòng ~231, 253, 254; `__VET45_V3101__.buildBasis` → tên mới ở dòng ~187). Xoá hack ghi đè `setCf12Control` ở `bj12.js` (~210–213).
5. Listener `fallback-exit` → mục "Lối ra dự phòng" trong khung (giữ capture, `stopPropagation`, tên thuộc tính). Nó đăng ký trước listener Inspect, nhưng Inspect chuyển sang `window` capture ở chặng 5 (mục 2.6) nên vẫn bị chặn khi Inspect bật — giữa chặng 3 và 5 thì tạm không bị chặn, chấp nhận (chỉ harness).
6. Xoá IIFE `v350`, `v360`, các lời gọi `syncReviewUrl()` thừa lúc nạp (giữ **một** ở cuối khung).
7. `node --check`; deep link mọi luồng + mọi `entry` (mục 6); golden.

### 4.4 Chặng 4 — helper dùng chéo (mục 2.5)

`ds24EmptyState`; một bản `ic*` ở `shared-control.js`. Golden.

### 4.5 Chặng 5 — tách harness (mục 2.6)

0. **Trước khi chuyển**, chụp toàn trang (không cắt theo `#device-preview`) 4 ca: `HUB_home`, một màn mobile, cùng màn `viewport=wide`, cùng màn bật Inspect + ghim một nút. Golden chỉ chụp `#device-preview` và chữ của `#app-screen` / vài ô inspector — sidebar, inspector, `#flow-selector` **không** được golden kiểm hình. Thêm chế độ chụp này vào `golden.mjs` (vd. biến `FULL=1`) hoặc chụp tay; so lại sau bước 2.
1. `harness/figma-ds-map.js` (mới), điền `harness/workbench.js` (file có sẵn); `index.html`: `<script src="harness/figma-ds-map.js">` + `<script src="harness/workbench.js">` ngay sau `app/core.js`; bỏ dòng `harness/workbench.js` cũ (dòng 133, sau `hub.js`). Listener chặn của Inspect đổi sang `window` capture (mục 2.6).
2. CSS harness → `harness/workbench.css` (file có sẵn; giữ `<link>` ở vị trí hiện tại, cuối các stylesheet). Sau khi chuyển: golden + so 4 ảnh toàn trang của bước 0; lệch ở viền / thu phóng thiết bị / sidebar → luật trộn bị chuyển nhầm hoặc thứ tự đổi, đặt lại.
3. Ô `review-badge` trong `index.html`: ghi thẳng bản hiện hành (thay việc `v470` đổi chữ lúc nạp).
4. Kiểm tay mục 3.3 (Inspect, viewport, sidebar, chip trạng thái).

### 4.6 Chặng 6 — CSS không dùng

1. Chạy lại `usage` (`.usage-a11-6`). Từ `_css-unused.txt`, **giữ** (không xoá) luật có: `:hover`, `:focus`, `:focus-visible`, `:focus-within`, `:active`, `:disabled`, `:checked`, `::placeholder`, `::selection`; nằm trong `@media` / `@supports` / `@keyframes` / `@font-face`; chọn `.is-wide`, `.inspect-*`, `body.inspect-mode`, `.toast*`, `[hidden]`; trong `harness/workbench.css`; trong `tokens.css`.
2. **Điều kiện xoá thêm (bắt buộc):** luật trong `_css-unused.txt` chỉ được xoá khi selector có **ít nhất một** tên lớp / thuộc tính `data-*` / id **không xuất hiện** ở đâu trong `app/*.js`, `harness/*.js`, `index.html`, `data/*` (`grep -F`; lớp sinh động như `ds24-badge--${t}`, `v-banner--${status}` thì grep tiền tố `ds24-badge--`, `v-banner--`). Luật không dùng mà mọi tên còn trong mã → **giữ** (có thể chỉ bật khi tương tác: sheet mở, `is-selected`, `v361-dual-footer--danger`, trạng thái lỗi… — golden không bấm tới), ghi số lượng vào mục 9. Viết điều kiện này thành script (đọc `_css-unused.txt`, ra `_css-deletable.txt`), không lọc tay.
3. Xoá phần trong `_css-deletable.txt` theo **từng khối tiêu đề** của `screens.css` / `components.css` (vd. cả nhóm trong `v252-…`), golden sau mỗi 3–4 khối. Khối chỉ còn tiêu đề → xoá tiêu đề.
4. `.cr-*` (43 luật) và `.ac310-*` (43 lớp CSS, JS còn dùng 35) đi theo cùng quy tắc — chỉ xoá luật nằm trong `_css-deletable.txt`.
5. **Không** sắp xếp lại, không gộp luật trùng, không bỏ `!important`.
6. Ghi mục 9: số dòng `screens.css` / `components.css` trước–sau, số luật đã xoá.

### 4.7 Chặng 7 — mã chết còn lại, dọn file tạm

1. Từ `_js-uncovered.txt` của `core.js` / `shared-*.js` / `harness/*.js`: hàm `count === 0` **và** `grep -w` không còn lời gọi (hoặc chỉ được gọi từ hàm cũng chết) → xoá. Độ phủ chỉ là gợi ý; golden không bấm hết mọi nút (bẫy 7.6). Không xoá trong `bj*.js` (Giai đoạn 2 viết lại).
2. Xoá file tạm không theo dõi: `app/core.js.before-a5…a9`, `tools/_a5_extract.py`, `_a6_recovered_audit_listeners.js.txt`, `_a7_extract.py`, `_a8_extract.py`, `_a9_apply.py`, thư mục `tools/.golden-*` cũ (giữ `.golden-a11-base` và bản chụp cuối).
3. Chú thích đầu `core.js` viết lại theo mục 1.1 (bỏ đoạn "Legacy …"). `harness/workbench.js` / `.css` bỏ chú thích "chưa tách".

## 5. Kiểm

| Kiểm | Cách | Đạt khi |
|---|---|---|
| Cú pháp | `node --check app/*.js harness/*.js` | Không lỗi |
| Không còn lớp vá | `grep -n '^/\* ===== \|v3[0-9][0-9]-\|v4[0-9][0-9]-\|legacy-' app/core.js` | Rỗng, trừ: 1 dòng tên lớp `v3xx`/`v4xx` có sẵn ở phần khung (đo 2026-10-19, ghi mục 9) và `v440-grouped-surface` nếu chặng 0 chọn nhánh giữ |
| Không còn bọc hàm khung | `grep -nE '^\s*(navigate\|render\|renderAppScreen\|renderFlowScreen\|previousScreen\|showToast)\s*=' app/*.js harness/*.js` | Rỗng |
| Không còn `ownedFlows` / `renderFlowScreen` | `grep -n 'ownedFlows\|renderFlowScreen' app/*.js harness/*.js` | Rỗng |
| Một API QA | Console: `Object.keys(window).filter(k=>/^__VET45_/.test(k))` | Chỉ `__VET45_QA__`, `__VET45_PROTOTYPE__` và 4 fixture |
| Không bản trùng | Đoạn đếm `^function X` theo tên trên `app/*.js` + `harness/*.js` | Mỗi tên một file |
| Harness tách | `grep -n 'inspect\|renderFlowInspector\|fitReviewDevice\|VET45_FIGMA_DS_MAP' app/*.js` | Chỉ còn lời gọi / đọc `inspectEnabled` trong `render()` và listener `data-generic-*` |
| Harness không lệch | 4 ảnh toàn trang chặng 5 bước 0 | Khớp |
| Deep link | Mọi luồng `?uif=UIF-01…17`, `CAP-01`, `?mode=theme&app=inventory`, mọi `entry` ở mục 2.3 | Dựng đúng, console sạch |
| Golden | `capture` + `compare` với `.golden-a11-base` | **Khớp hoàn toàn**, trừ ca banner chặng 2 đã liệt kê |
| Lỗi JS | `_errors.json` | Rỗng |
| Tay | Mục 3.3 | Như trước |

## 6. Kịch bản golden thêm

Khối `// Khung — T7-P A11`, sinh từ bảng (không viết tay từng dòng):

| Tên | Bắt đầu | Bước |
|---|---|---|
| `SC_entry_<UIF>_<mode>` | `?uif=<UIF>&entry=<mode>` cho **mọi** cặp ở mục 2.3 (cả hai nguồn: UIF-01 `product-context`; 02 `document-context` / `approver`; 03 `receipt-task`; 04 `order-context`; 05 `order-task`; 06 `return-task` / `approver`; 07 `return-task`; 08 `assigned-counter` / `approver`; 09 `product-context` / `approver`; 10 `product-context` / `approver` / `completion-operator`; 11 `approver` / `operation-context`; 12 `approver`; 13 `source-task`; 14 `dirty-scope`; 16 `case-context`; 17 `unknown-context`) | — (chỉ ca `_0`) |
| `SC_entry_state_12` | `?uif=UIF-12&entry=approver&state=SELF_APPROVAL_NOT_ALLOWED` | — (mong đợi: SCR-070 `READY`, `?state=` bị bỏ) |
| `SC_entry_state_01` | `?uif=UIF-01&entry=product-context&state=STALE` | — (mong đợi: SCR-003 `STALE`) |
| `SC_entry_flow_02` | `?uif=UIF-02&entry=document-context&flow=quick` | — (mong đợi: SCR-009, `flowMode` = `document`) |
| `SC_qa_entry14` | `?uif=UIF-14&screen=SCR-072` | `__VET45_QA__.applyEntry('UIF-14','dirty-scope')` (trước khi sửa: `__VET45_V350__`) |
| `SC_banner_046` | `?uif=UIF-08&screen=SCR-042` | Đi tới SCR-046 bằng nút trong BJ (lấy selector trên trang) — ca mong đợi **khác** ở chặng 2 |
| `SC_banner_040` | `?uif=UIF-10&entry=approver` | Một bước bấm trong màn rồi quay lại `APPROVAL_REVIEW` (nếu có) |

Kịch bản dùng `__VET45_V350__` / `__VET45_V3101__` phải chạy được với cả tên cũ (trước chặng 3) và mới: viết `(window.__VET45_QA__||window.__VET45_V350__)`, bỏ nhánh cũ ở chặng 7.

Đã có, phải khớp: toàn bộ `SC_hub_*`, `SC_ws_*`, `SC_pending`, `SC_bj*_*`, `SC_cap01_*`, `SC_attention_*`.

## 7. Bẫy

1. **`v440` không chết dù mọi luồng đã sở hữu** — nó bọc `render` và có `MutationObserver`, không chỉ bọc `renderFlowScreen`. Xoá mà không đo (chặng 0) → lệch golden khắp nơi.
2. **`simplifyNormalBanners` chạy trong rAF sau `render()`**, không chạy khi BJ gọi thẳng `renderAppScreen()` (mọi `bj*.js` đều có chỗ gọi như vậy). Đây là nguồn duy nhất của khác biệt có chủ đích ở A11.
3. **Thứ tự routing lúc nạp**: khối routing đầu chạy trước, `v350ApplyEntry` sau và thắng (UIF-11 có ở cả hai). Nhánh UIF-14 `dirty-scope` lúc nạp **không** chọn kỳ vì `bj14.js` chưa nạp — móc `onEntry` đăng ký ở `bj14.js` cũng chưa có lúc nạp, nên hành vi giữ nguyên; đừng "sửa" bằng cách gọi lại sau khi nạp.
4. **`__VET45_QA__` phải tồn tại trước mọi `bj*.js`**; BJ `Object.assign` vào, không `window.__VET45_QA__ = {…}` (ghi đè hàm của file nạp trước). `cap01.js` hiện dùng `??=` — đổi theo.
5. **Thứ tự nạp harness / listener Inspect**: listener capture trên `document` chặn mọi listener bubble bất kể thứ tự, nhưng với listener capture khác trên `document` (hơn 40 cái ở `bj*.js` / `hub.js`, `fallback-exit` ở khung) chỉ chặn được cái đăng ký **sau** nó. Vì vậy chuyển listener chặn sang **`window` capture** (mục 2.6) — chạy trước mọi listener trên `document`, hết phụ thuộc thứ tự. Vẫn nạp `harness/workbench.js` ngay sau `core.js` (để `render()` đầu thấy hàm harness, và phòng hờ). Kiểm tay: Inspect bật, bấm nút có `data-v360-action="fallback-exit"` → **không** điều hướng (như trước A11).
6. **Độ phủ không phải bằng chứng chết**: golden không bấm mọi nút / gõ mọi ô. Chỉ xoá hàm khi `grep` xác nhận không còn lời gọi sống. Luật CSS "không dùng" chỉ đúng với trạng thái golden đã mở — quy tắc giữ ở 4.6.1 bắt buộc.
7. **Xoá luật CSS không đổi cascade, chuyển luật thì có**: chặng 6 chỉ xoá; chặng 5 chuyển luật harness — chỉ luật thuần harness, giữ thứ tự tương đối.
8. **`renderFlowInspector` không được "dọn chữ"**: golden ghi `traceability` / `workbench-title` vào `.txt`.
9. **`ownedFlows` còn được nhắc trong chú thích / plan của BJ** — xoá `Set` thì `grep` cả chú thích; `bj*.js` không được còn `ownedFlows.add` (sẽ `ReferenceError` lúc nạp, hỏng luồng sau — bài học A7).
10. **Không "sửa tiện tay"** mục 2.7.

## 8. Ghi lại và commit

1. `CHANGELOG.md` mục `[5.3.0] — T7-P Giai đoạn 1, gói A11: dọn khung; hết Giai đoạn 1` (khối đã xoá; routing / actor / `__VET45_QA__`; harness tách; CSS: số luật xoá; ca golden khác có chủ đích — banner ngữ cảnh); `manifest.json` 5.3.0.
2. Plan tổng: mục 14 A11 Làm ✅; mục 3 hiện trạng (khung sạch, harness tách); mục 4.1 bẫy thêm "bước sau dựng bọc `render` / `MutationObserver` vẫn chạy trên luồng đã sở hữu — đo trước khi xoá"; mục 8.1 mốc hết Giai đoạn 1.
3. `README.md` của prototype (cấu trúc thư mục: `harness/`, `__VET45_QA__`, `golden.mjs usage`).
4. `python3 tools/sync-registry.py`; `detect_changes()` (GitNexus) nếu có; commit `refactor(prototype): T7-P A11 — clean framework, split harness`.

## 9. Ghi chú khi làm

- **Chặng 0:** `v440` còn sống (73 ca có `[data-v440-grouped-surface=auto]`) → giữ bước dựng chung trong khung. `v360` banner đo ~10 ca. CSS unused lúc đầu ~1499.
- **Chặng 2:** truyền `extraClass` `"v360-context-banner"` vào `vBanner` (bj08 SCR-046, bj10 SCR-040 ×2). Ca golden đi qua `renderAppScreen()` nay có lớp (có chủ đích).
- **Chặng 5 CSS:** tách chrome thuần (sidebar/inspector/inspect/stage/workbench-mode) → `harness/workbench.css`; **giữ** `.device-preview` size + luật trộn (`.review-card`, `.device-preview.is-wide .…`, figma `:has`) trong `styles/*`. `index.html` nạp `components` → `workbench` → `screens` (workbench trước screens để không đè v281). Bản CSS gốc trước tách mất → rebaseline golden sau tách (nội dung `#app-screen` pad16 gần khớp mốc s5b trên hầu hết ca; lệch AA viền / vài màn chrome — ghi CHANGELOG).
- **Chặng 6:** usage 1496 unused → deletable 1254 (giữ policy 117 + còn tên trong mã 125). Xoá hết deletable một lần: `components.css` **6092→3243**, `screens.css` **9414→7264**; golden khớp với base sau A11.
- **Chặng 7:** xoá `ioFilterChips`, `flowGroupLabel`; file tạm `core.js.before-a*` / `_a*_extract.py`; giữ `__VET45_QA__.setActor/getActor/getState`. `core.js` ~657 dòng.
- **Không commit** trong phiên (chờ người dùng yêu cầu).

## 10. Review

- **Ngày:** 2026-10-19, rà trên working tree cuối Giai đoạn 1 (sau A11, chưa commit; HEAD `4c7020013`). Kiểm chung: [plan tổng mục 14.1](T7-P-thiet-ke-lai-luong.md#141-review-giai-đoạn-1-2026-10-19).
- **Kết quả: ❌ → ✅ sau A12 (R1, R4–R6, 2026-10-19):** CSS đã trả lại, golden 0 khác biệt với mọi mốc trước Giai đoạn 1; chú thích, công cụ, thư mục mốc và commit đã xử lý. Ghi nhận lúc review: **mất CSS ở chặng 5 làm lệch hình 23 ca trạng thái + các ca `SC_*` đi qua chúng; việc chụp lại mốc (`.golden-a11-base` lúc 10:28, sau chặng 5) đã che lệch.** Sửa ở gói A12 bước R1.
- **Đã kiểm:**
  - `node --check app/*.js harness/*.js` sạch. Golden toàn bộ 1348 ca, 0 lỗi JS; khớp hoàn toàn `tools/.golden-a11-base` và `-final` (nhưng hai mốc này chụp **sau** khi mất CSS — xem dưới).
  - Khung: không còn khối `vNNN` / bọc `render` / `navigate` / `renderAppScreen`; không còn `ownedFlows` / `renderFlowScreen`; `entryTargets` / `applyEntry` / `onEntry` / `currentActor` một bảng; `__VET45_QA__` là API QA duy nhất (29 hàm, BJ `Object.assign`); `window` chỉ còn `__VET45_QA__`, `__VET45_PROTOTYPE__`, 4 fixture, `VET45_HARNESS_DATA`, `VET45_FIGMA_DS_MAP`.
  - Harness ở `harness/workbench.js` / `figma-ds-map.js` / `workbench.css`, nạp ngay sau `core.js`. `applyGroupedSurfaceRule` giữ làm bước dựng chung (đúng nhánh chặng 0). Banner `v360-context-banner` truyền qua `extraClass` ở `bj08.js` / `bj10.js` (khác biệt có chủ đích).
  - `ds24EmptyState` ở khung; `icCard…icApprovalButtons` một bản ở `shared-control.js`.
- **Lệch (so với mốc trước Giai đoạn 1 `tools/.golden-base` / `.golden-a5-base` và mốc ngay sau A10 `.golden-a10`; chữ khớp 100%, chỉ hình):**
  1. **Tiêu đề thẻ `.review-card-header strong` 14px → 11px** và khoảng đệm thẻ đổi: `UIF-11_SCR-050_CONFLICT` / `_SOURCE_VERSION_STALE`, `UIF-11_SCR-052_*` (2), `UIF-12_SCR-066_PREPARING`, `SCR-067/068/069_*`, `SCR-070_APPROVAL_ALREADY_DECIDED` / `_SELF_APPROVAL_NOT_ALLOWED` / `_VALIDATION_ERROR` (10), `UIF-15_SCR-058_READY` / `_STALE`, `UIF-16_SCR-079_*` / `081_*` / `082_MISMATCH_REMAINS` (5), cùng các ca `SC_bj12_*` / `SC_bj16_*` đi qua các màn đó. Nguyên nhân: khối CSS "Review cards composed from VCardHeader/VCardContent-like anatomy" (`.review-card-header {padding:16px 16px 8px; border-bottom:0; background:surface}`, `.review-card-header strong {font-size:14px; line-height:19px; font-weight:600}`, `.review-card-body`, `.review-line…`) **không còn** trong `styles/*` và **không** nằm trong `_css-deletable.txt` — mất khi tách harness ở chặng 5 (mục 9: "Bản CSS gốc trước tách mất → rebaseline golden"). Bản gốc còn ở git: `git show HEAD:specs/themes/theme-07/03.design/prototype/html/styles.css` dòng ~2112–2117 (biến `--v-*` → `--vet45-v2-*`).
  2. `UIF-13_SCR-089_REJECTED_EXECUTION` / `_UNKNOWN` — lệch vài px quanh biểu tượng + tiêu đề kết quả (xuất hiện sau `.golden-a7-after`; nhiều khả năng cùng đợt mất CSS).
  3. **Mọi ca**: góc bo khung thiết bị (4 góc, ~500 điểm ảnh/ca) khác mốc trước A11 — luật `.device-preview` / nền sân khấu đổi khi tách `workbench.css`. Là harness nhưng ảnh golden chụp cả khung; mục 9 có nhắc "lệch AA viền" nhưng CHANGELOG 5.3.0 **không** ghi.
- **Chưa đạt khác (không chặn hình, làm ở A12 bước R4–R6):**
  1. Kiểm "Không còn lớp vá" còn: `/* ===== app.js ===== */` (dòng 13), chú thích `// v1.7.0 …` / `// v1.8.0 …` / `/* flowScreen assigns after framework */` (442, 451, 457, 580).
  2. Chú thích đầu `core.js` dòng 7 và CHANGELOG 5.3.0 còn nói khung có `simplifyNormalBanners` — hàm đã xoá.
  3. `tools/golden.mjs` còn nhánh tên cũ `(window.__VET45_QA__||window.__VET45_V350__)` / `__VET45_V3101__` (bảng 6: "bỏ nhánh cũ ở chặng 7").
  4. 32 thư mục mốc golden (`tools/.golden-*`, `.golden-a9/-a10/-base` ở gốc `html/`) và `tools/.full-a11-*`, `tools/.usage-a11-*` chưa bị git bỏ qua (`tools/.gitignore` chỉ có `.golden*/`).
  5. **Commit:** working tree còn 214 file legacy bị xoá + `styles/`, `harness/`, `data/` chưa track; HEAD hiện nạp `data/workbench-data.js` / `styles/*` không có trong git → clone sạch không chạy được. Commit A11 phải gồm toàn bộ cấu trúc T7-P0 (xoá legacy, thêm `styles/` / `harness/` / `data/`).
