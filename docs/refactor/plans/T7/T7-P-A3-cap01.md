# T7-P · Gói A3 — viết lại code sạch CAP-01 Chính sách tồn & cận hạn

> Theme: Theme 7 Inventory · Trạng thái: Plan ✅ | Làm ✅ | Review ⬜
> Thuộc [T7-P](T7-P-thiet-ke-lai-luong.md) Giai đoạn 1, gói A3 (mục 8.1). Ước lượng: **~0,5 ngày, 1 commit**.
> Người làm: bạn. Review: phiên plan / review. Mẫu tham khảo: `app/bj05.js` (gói A1); cách làm, đoạn đo, helper golden: [T7-P-A1-bj04-bj05.md](T7-P-A1-bj04-bj05.md).
> Làm được độc lập với A2 (không chung lớp, không chung listener).

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/` nếu không ghi khác. Số dòng đo ngày 2026-10-17 trên `app/core.js` sau gói A1 — sẽ lệch; tìm theo chuỗi trong ngoặc.

## 1. Mục tiêu

1. Toàn bộ CAP-01 (SCR-062…065) vào `app/cap01.js`: trạng thái, helper, hàm dựng, xử lý sự kiện, lối ra `capExit`.
2. Phần "khung" mà `v360` đang vá lúc nạp (`FIGMA_MIGRATED_FLOWS`, `FIGMA_TEMPLATE_BY_FLOW_SCREEN`, `FLOW_GROUPS`, nhãn inspector) → ghi thẳng vào literal của `core.js`; xoá lớp bọc `renderFlowInspector` của `v360`.
3. `CAP-01` vào `ownedFlows`.
4. **Giao diện không đổi:** golden khớp hoàn toàn; bấm thử 0 lỗi JS.

Không làm: đổi thiết kế; CSS `.v360-*` (gói A11); `fallback-exit`, `v360RootScreens` / `v360ExitTargets`, bảng toast, `ensureRepresentativeFixture` của `v360` (dùng chung — gói A11).

## 2. Bản đồ hiện trạng

CAP-01 chỉ có **một** định nghĩa cho mỗi màn, tất cả trong IIFE `===== v360-full-theme-completion.js =====` (bắt đầu ~5582). Không lớp nào sau `v360` đè màn CAP-01 (đo: `grep -n "SCR-06[2-5]\|CAP-01" app/core.js` chỉ ra vùng `v360`). Các khớp `cap…` ở ~1943, ~2031, ~6595 là biến `capInvalid` của BJ-06 — không liên quan.

| Phần | Ở đâu trong `v360` | Xử lý |
|---|---|---|
| `FIGMA_MIGRATED_FLOWS.add("CAP-01")` | ~5599 | Thêm `"CAP-01"` vào literal `const FIGMA_MIGRATED_FLOWS = new Set([…])` (~28); xoá dòng |
| `FIGMA_TEMPLATE_BY_FLOW_SCREEN["CAP-01"] = {…}` | ~5600–5607 | Thêm mục `"CAP-01":{…}` vào literal `FIGMA_TEMPLATE_BY_FLOW_SCREEN`; xoá khối |
| `FLOW_GROUPS.push({id:"supporting",…})` | ~5608–5610 | Thêm phần tử `{ id: "supporting", label: "Supporting capability", bjs: ["CAP-01"] }` vào cuối literal `const FLOW_GROUPS` (~61); xoá khối |
| Lớp bọc `renderFlowInspector` (đổi ô "Figma DS" thành `v3.6.0 · Figma DS primitives · HTML Theme 7 design`) | ~5612–5624 | Thêm `"CAP-01":"v3.6.0 · Figma DS primitives · HTML Theme 7 design"` vào bảng `figmaMigrationLabel` trong `renderFlowInspector` (~749); xoá lớp bọc. Inspector không nằm trong golden — so bằng mắt (mục 5) |
| Trạng thái `let capPolicyKind … capReturnScreen` (11 biến) | ~5631–5641 | Chuyển |
| `capNumberField`, `capSelect`, `capExit`, `capFormNotice` | ~5643–5660 | Chuyển |
| `capRender062` … `capRender065` + 4 dòng `renderers["SCR-06x"]=…` | ~5661–5709 | Chuyển, đổi tên `render062CAP01` … `render065CAP01` |
| Listener `input` (`if(activeFlowId!=="CAP-01")return;` 3 ô số) | ~5896–5901, capture | Chuyển |
| Listener `change` (3 ô chọn) | ~5902–5907, capture | Chuyển |
| Listener click `[data-v360-action]`: `cap-exit`, rồi `fallback-exit` (dùng chung), rồi phần sau `if(activeFlowId!=="CAP-01")return;` (`cap-review-stock`, `cap-review-expiry`, `cap-edit`, `cap-save`) | ~5908–5928, capture | Chuyển `cap-exit` + 4 khoá CAP-01; **giữ** listener với **chỉ** `fallback-exit` |
| Listener click `[data-action="v360-cap-exit"]` / `"v360-cap-edit"` (nút quay lại của appbar) | ~5929–5934, capture | Chuyển |
| `window.__VET45_V360__.capState`, `setCapReturn`, `capExit` | ~5966–5969 | Chuyển ba mục này sang `cap01.js`: `Object.assign(window.__VET45_V360__ ??= {}, { capState, setCapReturn, capExit })`. Không nơi nào trong repo gọi (đo: chỉ có trong `v360`), nhưng là công cụ dev, giữ cho đủ |
| `"SCR-062","SCR-063"` trong `v360RootScreens` | ~5844 | Giữ (A11); phần HTML mà bước sửa sau dựng thêm vào (nếu có) đo ở 4.3 |

**Không có** mã chết, hàm gán lại, toast hay wrapper `navigate` của CAP-01. Helper cục bộ của IIFE `v360` mà CAP-01 dùng: `e` (= `esc`), `ea` (= `escapeAttribute`), `n` (= `Number(v ?? 0)`).

## 3. Chuẩn bị

1. `python3 -m http.server 8765 --bind 127.0.0.1 &` trong `html/`.
2. Thêm kịch bản golden (mục 6), chụp `.golden-base`, chụp `.golden-check`, so — "Khớp hoàn toàn".
3. Mở ảnh `SC_cap01_*`: mỗi bước bấm phải làm màn đổi. Bước gõ chữ (`typeIn`) và chọn (`pick`) **không** dựng lại màn — chữ trong `.txt` có thể không đổi, bước bấm sau đó mới đổi (giống A1 mục 9).
4. Mở `?uif=CAP-01&screen=SCR-062`, chụp ảnh panel inspector (ô "Figma DS", nhóm "Supporting capability" trong bộ chọn luồng) để so ở mục 5.

## 4. Các bước

### 4.1 `app/core.js` — dữ liệu khung

Bốn chỉnh sửa ở bảng 2 (hàng 1–4): thêm vào literal, xoá phần vá trong `v360`. Không đổi gì khác trong `renderFlowInspector`.

### 4.2 `app/cap01.js`

1. Chú thích đầu file: CAP-01, SCR-062…065; "Đã viết lại sạch (T7-P gói A3, ngày …)"; dùng chung từ `core.js`: `appShell`, `ds24InfoGroup`, `ds24InfoRow`, `ds24KeyValueRow`, `ds24Result`, `vBanner`, `deniedBody`, `primaryFooter`, `esc`, `escapeAttribute`, `navigate`, `render`, `renderAppScreen`, `syncReviewUrl`, `screens`, `stateByScreen`; còn ở `core.js`: `fallback-exit`, `v360RootScreens` (A11). Ghi: **lối vào / lối ra là fallback prototype (BG-006 chưa chốt)** — giữ chú thích gốc của `v360`.
2. Chép theo thứ tự: 11 biến trạng thái → `cap01Num` → `capNumberField`, `capSelect`, `capExit`, `capFormNotice` → `render062CAP01` … `render065CAP01`.
   - `e(` → `esc(`, `ea(` → `escapeAttribute(` (bỏ nhánh `typeof … === "function"`: `core.js` nạp trước). `n(` → `cap01Num(` với `const cap01Num = (v) => Number(v ?? 0);`.
   - Đổi cẩn thận: `e(` / `n(` là tên một chữ — chỉ đổi lời gọi hàm, không đổi chữ `e`, `n` trong chuỗi / tên khác. Cách an toàn: đổi bằng regex `\be\(` và `\bn\(` **chỉ trong đoạn đã chép**, rồi đọc lại từng chỗ.
3. Đăng ký:
   ```js
   Object.assign(renderers, { "SCR-062": render062CAP01, "SCR-063": render063CAP01, "SCR-064": render064CAP01, "SCR-065": render065CAP01 });
   ownedFlows.add("CAP-01");
   ```
4. Listener — giữ **pha capture** như gốc (`…, true`), giữ nguyên thứ tự kiểm:
   ```js
   document.addEventListener("input", (event) => { if (activeFlowId !== "CAP-01") return; /* 3 dòng nguyên văn */ }, true);
   document.addEventListener("change", (event) => { if (activeFlowId !== "CAP-01") return; /* 3 dòng nguyên văn */ }, true);
   document.addEventListener("click", (event) => {
     const back = event.target.closest('[data-action="v360-cap-exit"]');
     if (back) { event.preventDefault(); event.stopPropagation(); return capExit(); }
     const edit = event.target.closest('[data-action="v360-cap-edit"]');
     if (edit && activeFlowId === "CAP-01") { event.preventDefault(); event.stopPropagation(); return navigate(capPolicyKind === "STOCK" ? "SCR-062" : "SCR-063"); }
     const action = event.target.closest("[data-v360-action]");
     if (!action || action.disabled) return;
     const k = action.dataset.v360Action;
     if (k === "cap-exit") { event.preventDefault(); event.stopPropagation(); return capExit(); }
     if (activeFlowId !== "CAP-01" || !["cap-review-stock", "cap-review-expiry", "cap-edit", "cap-save"].includes(k)) return;
     event.preventDefault(); event.stopPropagation();
     // 4 nhánh nguyên văn, n( → cap01Num(
   }, true);
   ```
   - `v360-cap-exit` / `cap-exit` gốc **không** kiểm `activeFlowId` — giữ như vậy (chỉ màn CAP-01 có các nút này; `grep -n 'cap-exit' app/*.js` sau khi xong chỉ ra `cap01.js`).
   - Gốc: `if(activeFlowId!=="CAP-01")return; event.preventDefault();event.stopPropagation();` chặn **mọi** `data-v360-action` khác trên màn CAP-01. Sau khi tách, khoá lạ (không có) sẽ không bị chặn nữa — vô hại vì màn CAP-01 chỉ phát 5 khoá trên. Kiểm: `grep -o 'data-v360-action="[a-z-]*"' app/cap01.js | sort -u` = `cap-edit`, `cap-exit`, `cap-review-expiry`, `cap-review-stock`, `cap-save`.
5. Công cụ dev (`window.__VET45_V360__`, bảng 2): `v360` chạy trong `core.js`, nạp trước `cap01.js`, và gán cả object một lần. Vì vậy trong `v360` bỏ 3 mục `capState`, `setCapReturn`, `capExit` khỏi object; trong `cap01.js` thêm `Object.assign(window.__VET45_V360__, { capState: () => ({…}), setCapReturn(flow = "UIF-01", screen = "SCR-001") {…}, capExit });`.
6. Xoá trong `v360`: mọi phần đã chép; listener `input` / `change` CAP-01; listener `v360-cap-exit` / `v360-cap-edit`; trong listener `data-v360-action` chỉ để lại:
   ```js
   document.addEventListener("click",(event)=>{
     const action=event.target.closest("[data-v360-action]");
     if(!action||action.disabled)return;
     if(action.dataset.v360Action==="fallback-exit"){event.preventDefault();event.stopPropagation();const target=action.dataset.v360Target;if(target)return navigate(target);}
   },true);
   ```
   Sửa tiêu đề mục `// CAP-01 interaction and stable exit paths.` → `// Stable exit paths (fallback-exit).`; chú thích `Scope:` đầu `v360` bỏ "supporting capability CAP-01".

### 4.3 Đo bước sửa sau dựng

Đoạn đo của [A1 mục 4.5](T7-P-A1-bj04-bj05.md), danh sách luồng `["CAP-01"]`, trang `?uif=CAP-01&screen=SCR-062`, `ownedFlows.add("CAP-01")` tạm comment.

- Ứng viên khác: `v360` (`ensureStableExitAffordance` — SCR-062 / 063 là màn gốc trong `v360RootScreens`), `v361` (`normalizeDualFooters` — SCR-064 có footer hai nút `v360-dual-actions`), `v440` (grouped surface — `ds24InfoGroup`), `v470` / `v471`.
- Có khác → gộp vào hàm dựng `cap01.js`, chạy lại đến "không khác"; ghi ở mục 9.
- `capLastResult` chỉ đổi khi bấm "Lưu chính sách" — đoạn đo không bấm, không cần tải lại giữa các lần.

## 5. Kiểm

| Kiểm | Cách | Đạt khi |
|---|---|---|
| Cú pháp | `node --check app/core.js app/cap01.js` | Không lỗi |
| Không còn mã cũ | `grep -n "capPolicy\|capThreshold\|capRender\|capExit\|SCR-06[2-5]\|CAP-01" app/core.js` | Chỉ còn: literal `FIGMA_MIGRATED_FLOWS`, `FIGMA_TEMPLATE_BY_FLOW_SCREEN`, `FLOW_GROUPS`, `figmaMigrationLabel`; `"SCR-062","SCR-063"` trong `v360RootScreens` |
| Golden | `capture tools/.golden-check` + `compare` | **Khớp hoàn toàn** (ca `CAP-01_*`, `SC_ws_setup_*`, kịch bản mới) |
| Lỗi JS | `tools/.golden-check/_errors.json` | Rỗng |
| Inspector | So với ảnh chụp ở 3.4 | Ô "Figma DS" = `v3.6.0 · Figma DS primitives · HTML Theme 7 design`; bộ chọn luồng còn nhóm "Supporting capability" |
| Công cụ dev | Console: `__VET45_V360__.capState().capPolicyRevision` | `5` |
| Bấm thử | Phiên review | 0 lỗi |

## 6. Kịch bản golden thêm (`tools/golden.mjs`)

Thêm helper cạnh `typeIn`:

```js
const pick = (sel, value) => `(()=>{const i=document.querySelector(${JSON.stringify(sel)});if(!i)return false;i.value=${JSON.stringify(value)};i.dispatchEvent(new Event('change',{bubbles:true}));return true})()`;
```

Khối `// CAP-01 Chính sách tồn & cận hạn — T7-P A3`, `C = '?uif=CAP-01&screen='`:

| Tên | Bắt đầu | Bước |
|---|---|---|
| `SC_cap01_stock` | `C+'SCR-062'` | `typeIn('[data-v360-cap-threshold]','100')` → `[data-v360-action="cap-review-stock"]` (mục tiêu 80 < 100 → `VALIDATION_ERROR`) → `typeIn('[data-v360-cap-threshold]','40')` → `pick('[data-v360-cap-stock-source]','TENANT_DEFAULT')` → `[data-v360-action="cap-review-stock"]` (SCR-064) → `[data-v360-action="cap-edit"]` (về SCR-062) → `[data-v360-action="cap-review-stock"]` → `[data-v360-action="cap-save"]` (SCR-065) → `[data-v360-action="cap-exit"]` (sang UIF-01 SCR-001) |
| `SC_cap01_expiry` | `C+'SCR-063'` | `typeIn('[data-v360-cap-expiry-days]','0')` → `[data-v360-action="cap-review-expiry"]` (`VALIDATION_ERROR`) → `typeIn('[data-v360-cap-expiry-days]','60')` → `pick('[data-v360-cap-expiry-action]','BLOCK_SALE')` → `[data-v360-action="cap-review-expiry"]` → `back` (appbar `v360-cap-edit` → SCR-063) → `[data-v360-action="cap-review-expiry"]` → `[data-v360-action="cap-save"]` |
| `SC_cap01_back` | `C+'SCR-062'` | `back` (appbar `v360-cap-exit` → UIF-01 SCR-001) |
| `SC_cap01_locked` | `C+'SCR-062&state=LOCKED'` | `[data-v360-action="cap-exit"]` (nút "Đóng") |
| `SC_cap01_review_invalid` | `C+'SCR-064&state=VALIDATION_ERROR'` | `[data-v360-action="cap-edit"]` |
| `SC_cap01_unknown` | `C+'SCR-065&state=UNKNOWN'` | nút chính của footer (`.app-actions [data-v360-action]`) |

`SC_cap01_stock` bước 2: nút "Rà soát thay đổi" chỉ được tính `disabled` lúc dựng (ô nhập không dựng lại) nên vẫn bấm được — đúng hành vi hiện tại, handler mới đặt `VALIDATION_ERROR`. Nếu bước nào không làm màn đổi → chỉnh selector, ghi ở mục 9.

## 7. Bẫy

1. **Tên một chữ `e`, `n`** (4.2.2): đổi sót → `ReferenceError` chỉ ở trạng thái dựng tới lời gọi đó; đoạn đo 4.3 dựng mọi trạng thái nên bắt được.
2. **Thứ tự kiểm trong listener click** (4.2.4): `v360-cap-exit` / `cap-exit` được kiểm **trước** điều kiện luồng — giữ nguyên.
3. **`fallback-exit` dùng chung** (nút "Về danh sách" do `v360` chèn vào nhiều BJ): không chuyển, không xoá.
4. **Biến trạng thái thành toàn cục:** trước là `let` trong IIFE, nay là `let` cấp file. `grep -n "^\(let\|const\|function\) cap" app/*.js` chỉ ra `cap01.js`.
5. **`window.__VET45_V360__`** được `v360` tạo trong `core.js` (nạp trước) — `cap01.js` chỉ `Object.assign` vào, không gán lại cả object (mất `ensureRepresentativeFixture`).

## 8. Ghi lại và commit

1. `CHANGELOG.md`: mục `[5.1.3] — T7-P Giai đoạn 1, gói A3: CAP-01 viết lại sạch` (chuyển gì; dữ liệu khung vào literal; xoá lớp bọc `renderFlowInspector` của `v360`). `manifest.json` → `5.1.3`. (Nếu A2 chưa xong khi làm A3, dùng số kế tiếp sau bản mới nhất trong `CHANGELOG.md`.)
2. Plan tổng mục 14: A3 Làm ✅; mục 4.2 bước 1 bỏ "(gộp phần CAP-01 của `v360`)" vì đã làm ở A3.
3. `python3 tools/sync-registry.py`.
4. `detect_changes()`, commit: `refactor(prototype): T7-P A3 — CAP-01 clean code in app/cap01.js`.

## 9. Ghi chú khi làm

- Đo 4.3 (pipe vs bare, tạm bỏ `ownedFlows`): khác `v440` grouped surface → gộp `cap01InfoGroup`; khác `v361` dual footer SCR-064 → class `v361-dual-footer` + `data-ds-prop-*`; khác marker `data-v470` trên key-value SCR-064 → `cap01KeyValueRow`. Sau khi gộp: **không khác**.
- Golden selector: giữ nguyên plan mục 6; helper `pick` thêm cạnh `typeIn`. 843 ca khớp; 0 lỗi JS.
- Lệch plan nhỏ: `nb` / `e` / `ea` / `n` cục bộ của IIFE `v360` không còn dùng sau khi chuyển CAP-01 — đã xoá cùng khối (không chỉ CAP-01).

## 10. Review

(Phiên review điền sau khi bạn báo xong.)
