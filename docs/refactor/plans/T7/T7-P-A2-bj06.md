# T7-P · Gói A2 — viết lại code sạch BJ-06 Hàng khách trả

> Theme: Theme 7 Inventory · Trạng thái: Plan ✅ | Làm ✅ | Review ⬜
> Thuộc [T7-P](T7-P-thiet-ke-lai-luong.md) Giai đoạn 1, gói A2 (mục 8.1). Ước lượng: **~1 ngày, 1 commit**.
> Người làm: bạn. Review: phiên plan / review. Mẫu tham khảo: `app/bj05.js` (gói A1), [T7-P-A1-bj04-bj05.md](T7-P-A1-bj04-bj05.md) (cách làm, đoạn đo 4.5, helper `typeIn`).

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/` nếu không ghi khác. Số dòng đo ngày 2026-10-17 trên `app/core.js` **sau gói A1** — sẽ lệch khi bạn xoá dần; tìm theo chuỗi trong ngoặc.

## 1. Mục tiêu

1. Toàn bộ BJ-06 (UIF-06: SCR-030…035) vào `app/bj06.js`: fixture, chuẩn hoá fixture, trạng thái, helper `io06*`, hàm dựng cuối cùng, xử lý sự kiện.
2. Gỡ phần BJ-06 khỏi các lớp cũ: `v394` (xoá cả khối), các đoạn trong `v350`, `v360`, `legacy-cross-theme-copy`, `previousScreen` và các listener chung của `app.js`.
3. `UIF-06` vào `ownedFlows`.
4. **Giao diện và hành vi không đổi:** golden khớp hoàn toàn; bấm thử 0 lỗi JS. Mã cũ đang chết (mục 2.3) thì **xoá, không làm sống lại**.

Không làm: đổi thiết kế; dọn CSS `.io06-*` (gói A11); cơ chế `handoff-unknown` và nhánh `UIF-06` trong `v350LockSourceForUnknown` (gói A10); `bumpIO06Source` trong công cụ dev (gói A11); `FIGMA_TEMPLATE_BY_FLOW_SCREEN`, nhãn phiên bản inspector, `v350EntryTargets` / `entryMode` (khung, gói A11).

## 2. Bản đồ hiện trạng

**Điểm khác A1:** lớp `v394` không chỉ đè hàm dựng mà còn **gán lại 18 hàm toàn cục `io06*`** và chặn sự kiện bằng listener trên `window` pha capture có `stopImmediatePropagation()`. Listener `window` capture chạy **trước mọi** listener trên `document`, nên các nhánh cũ cùng việc ở `app.js`, `v350`, `v360` không bao giờ chạy. Bản thắng của mọi thứ dưới đây đã được đo theo thứ tự nạp; mục 3.4 kiểm lại trên trình duyệt trước khi xoá.

### 2.1 Màn — bản thắng

| Màn | Bản đang chạy | Bị đè (xoá) |
|---|---|---|
| SCR-030 Hàng khách trả | `render030IO06` (`app.js`, dòng ~1977), gọi `io06RequestRow` **của `v394`** | `io06RequestRow` gốc (`app.js` ~1971) |
| SCR-031 Kiểm hàng khách trả | `render031IO06` (`app.js` ~2007), gọi `io06ReturnLineRow` **của `v394`**; tiêu đề bị đổi sau dựng thành "Kiểm hàng khách trả" (mục 2.2) | `io06ReturnLineRow` gốc (`app.js` ~1990) |
| SCR-032 Chi tiết hàng trả | `renderers['SCR-032']` của `v394` (~6593) | `render032IO06` (`app.js`) |
| SCR-033 Phân loại hàng trả | `renderers['SCR-033']` của `v394` (~6616) | `render033IO06` (`app.js`) |
| SCR-034 Ngoại lệ lô cần duyệt / Duyệt ngoại lệ lô | `renderers['SCR-034']` của `v394` (~6607). Với UIF-06 **không gọi** `base034`, nên lớp bọc `v350` của SCR-034 (đổi `approve-exception` → `data-v350-action`) không có tác dụng | `render034IO06` (`app.js`), lớp bọc `v350Render034Base` |
| SCR-035 Kết quả hàng trả | `renderers['SCR-035']` của `v394` (~6624), tự xử lý `UNKNOWN` | `render035IO06` (`app.js`), mục `["SCR-035","UIF-06",…]` trong `unknowns` của `v350` |

### 2.2 Bản đồ chi tiết

| Phần | Ở đâu | Xử lý |
|---|---|---|
| `io06EvidenceSvg`, `io06Requests`, `io06LinesByRequest`, `io06ApprovalSeq`, `io06ApprovalCases`, câu `let io06SelectedRequestId=…, io06ApproverListMode=true;` | `app.js` ~1690–1712 | Chuyển |
| Helper `io06*` gốc (`io06CurrentRequest` … `io06ClassificationSummary`, ~35 hàm) | `app.js` ~1713–1757 | Chuyển; 18 hàm bị `v394` gán lại → lấy **thân của `v394`** (bảng 2.4) |
| `updateIO06LineValidation`, `updateIO06ClassificationLive` | `app.js` ~1941, ~1947 | Chuyển; `updateIO06ClassificationLive` lấy thân `v394` |
| `io06DsTone`, `io06TextField`, `io06Textarea`, `io06SelectionRow`, `io06RequestRow`, `render030IO06`, `io06ReturnLineRow`, `io06QtyDisplay`, `io06ResultGroupsHtml`, `render031IO06` | `app.js` ~1956–2026 | Chuyển (`io06RequestRow`, `io06ReturnLineRow`: thân `v394`) |
| `render032IO06`, `render034IO06`, `render033IO06`, `render035IO06` | `app.js` ~2027–2088 | **Xoá** (bị `v394` đè) |
| Hằng / helper cục bộ của `v394`: `BUSINESS_DATE`, `MAKER`, `LOTS`, `CONDITIONS`, `AUTH`, `attr`, `upper`, `stableHash`, `isoNow`, `displayTime`, `v394LineMax`, `v394LotMeta`, `v394ResolveLot`, `v394LotDataReady`, `v394Expiry`, `v394IsExpired`, `v394EvidenceIdentity`, `v394SnapshotCore`, `v394SubjectHash`, `fileSha256`, `lotDetailsHtml`, `evidenceHtml` | IIFE `v394` ~6499–6581 | Chuyển, **đổi tên có tiền tố** (bước 4.3.3) |
| Chuẩn hoá fixture khi nạp: `operationId`, `tracking`, `authorizedQuantity`, `declaredCondition`, bằng chứng fixture, lô hết hạn `RET-L4` = `DH2408`, ca `EX-06-001` | `v394` ~6545–6556 | Chuyển, chạy ngay sau fixture |
| Khởi tạo `r.reviewSourceVersion ??= null; r.unknownLocked ??= false` | `v350` (`io06Requests.forEach(r=>{r.reviewSourceVersion ??= null;…`) | Chuyển **chỉ** `unknownLocked ??= false` (nhánh UIF-06 của `v350LockSourceForUnknown` còn ghi vào); bỏ `reviewSourceVersion` (mục 2.3) |
| Đổi tiêu đề SCR-031 thành "Kiểm hàng khách trả" (mọi trạng thái) | **hai** chỗ: `legacy-cross-theme-copy` (`if(activeFlowId==='UIF-06'&&activeScreenId==='SCR-031')`) và wrapper `renderFlowScreen` cuối `v394` | Đưa vào `render031BJ06`: `title:"Kiểm hàng khách trả"` cho cả `PERMISSION_DENIED`, `LOADING`, `READY`… (`appShell` chỉ dùng `title` trong `<h3>`) |
| Nút quay lại (`[data-back]`) ở SCR-031 / 032 / 033 | `previousScreen()` (`if (activeFlowId === "UIF-06") {…}`, ~3226) | Móc `onPrevious` mới (mục 4.1) |
| `exit-io06-approval` (nút quay lại của màn duyệt, `backAction`) | listener `data-action` chung (~3699) | Chuyển vào listener click của `bj06.js` |
| Input: `data-io06-search`, `data-io06-reason-detail`, `data-io06-reject-reason`, `data-io06-class` | listener `input` chung (`// Inventory Operations interactions`, ~4038) | Chuyển |
| Input: `data-io06-qty`, `data-io06-actual-lot`, `data-v394-new-lot-expiry`, `data-v394-new-lot-manufacture` | listener `window` `input` của `v394` (~6631) | Chuyển (bản `v394`). **Xoá** 2 dòng `data-io06-qty`, `data-io06-actual-lot` trong listener `input` chung (chết) |
| Change: `data-io06-actual-lot` | listener `change` chung (~4049) | Chuyển |
| Change: `data-io06-evidence-file` | listener `window` `change` của `v394` (~6638) | Chuyển (bản `v394`); **xoá** dòng cùng selector trong listener `change` chung (chết) |
| Click: `f6`, `r6`, `line6`, `classLine`, `reason6`, `expectedLot6`, `otherLot6`, `approvalCase6`, `[data-io06-reject-backdrop]` | listener click chung (`if(!["UIF-06","UIF-07"].includes(activeFlowId)) return;`, ~4052, **pha capture**) | Chuyển. `expectedLot6`, `otherLot6`: **gộp** phần chạy trước của `v394` (bảng 2.5) |
| Hành động `data-io06-action` | cùng listener (~4070–4097) và listener `window` click của `v394` (~6641) | Bảng 2.5 |
| Toast "Đã cập nhật hàng khách trả", "Đã lưu phân loại hàng trả" | bảng `toastRules` của `v360` | **Xoá** hai dòng — chết (mục 2.3) |
| `SCR-030` trong `v360RootScreens`; `SCR-034`, `SCR-035` trong `v360ExitTargets` | `v360` | Giữ (bảng dùng chung; gói A11). Phần HTML mà các bước này thêm vào màn — nếu có — đo ở 4.5 |

### 2.3 Mã đang chết (xoá, không chuyển)

| Mã | Vì sao chết |
|---|---|
| `v350`: lớp bọc `io06ReceiptReady` (kiểm `reviewSourceVersion === sourceVersion`) | `v394` gán lại `io06ReceiptReady` sau đó, không gọi bản cũ |
| `v350`: listener click `[data-io06-action="commit-receipt"]` báo `SOURCE_CHANGED` | Listener `document`; `v394` chặn `commit-receipt` ở `window` bằng `stopImmediatePropagation` |
| `v350`: dòng `UIF-06` / `SCR-031` trong wrapper `navigate` (ghi `reviewSourceVersion`) | Chạy được, nhưng chỉ hai mã chết ở trên đọc `reviewSourceVersion` của `io06` |
| `v350`: `v350Render034Base` + hai nhánh `io06-approve-exception`, `io06-confirm-reject` trong listener `data-v350-action`, và vế `activeFlowId==="UIF-06"?"SCR-034":` | `v394` dựng SCR-034 không qua `base034` → nút vẫn là `data-io06-action="approve-exception"` / `"confirm-reject"`, do listener chung xử lý (không kiểm người duyệt) |
| `v350`: mục `SCR-035` trong `unknowns` | `v394` tự trả màn `UNKNOWN` trước khi gọi `base035`; SCR-035 không có trạng thái `COMMIT_UNKNOWN` |
| `v360`: hai dòng toast `io06` | Listener `document` capture; `v394` chặn `save-return-line`, `confirm-classification` ở `window` |
| Listener chung: input `data-io06-qty`, `data-io06-actual-lot`; change `data-io06-evidence-file`; nhánh hành động `save-return-line`, `save-return-exception`, `commit-receipt`, `close-classification-item`, `confirm-classification` | Như trên — `v394` chặn trước |

Ghi vào mục 9 (để brief BJ-06 ở Giai đoạn 2 xét lại): **chặn tự duyệt** (SELF_APPROVAL) và **chặn ghi nhận khi yêu cầu nguồn đổi** của BJ-06 hiện không chạy trong prototype.

### 2.4 18 hàm `v394` gán lại (lấy thân `v394`, giữ một định nghĩa)

`io06CaseSnapshot`, `io06SnapshotMatches`, `io06InvalidateCaseIfChanged`, `io06LinePhysicalValid`, `io06LineEvidenceReady`, `io06LineApprovalState`, `io06RequestAllVerified`, `io06RequestCanSubmitExceptions`, `io06ReceiptReady`, `io06CreateCase`, `io06SetLineDirty`, `io06ClassTotal`, `io06ClassValid`, `io06AllClassValid`, `io06ClassificationDraftFor`, `updateIO06ClassificationLive`, `io06RequestRow`, `io06ReturnLineRow`.

(Mục 8.1 plan tổng trước đây ghi "8 hàm" — đã sửa.) `io06Mismatch`, `io06LineCase`, `io06RefreshRequestState`, `updateIO06LineValidation`… **không** bị gán lại: giữ thân gốc.

### 2.5 Hành động `data-io06-action` — bản thắng

| Khoá | Bản thắng | Ghi chú |
|---|---|---|
| `save-return-line`, `save-return-exception`, `commit-receipt`, `close-classification-item`, `confirm-classification` | `v394` (listener `window` click) | Chép thân `v394`; bỏ nhánh cùng khoá ở listener chung |
| `submit-return-exceptions`, `approve-exception`, `open-reject`, `close-reject`, `confirm-reject`, `exit-approval-detail`, `refresh-return-request`, `open-classification`, `cancel-classification-item`, `result-to-return-queue`, `back-to-return-request` | Listener chung | Chép nguyên văn |
| Click `[data-io06-select-other-lot]` | `v394` chạy trước (đặt `reasonCode` nếu rỗng, xoá `newLotExpiry` / `newLotManufacture`), rồi `otherLot6` của listener chung | Gộp: phần `v394` đặt **đầu** nhánh `otherLot6` |
| Click `[data-io06-select-actual-lot]` | `v394` chạy trước (xoá `newLot*`, `evidenceId`, `evidenceVersion`, `evidenceHash`), rồi `expectedLot6` | Gộp: phần `v394` đặt **đầu** nhánh `expectedLot6` |

## 3. Chuẩn bị

1. `python3 -m http.server 8765 --bind 127.0.0.1 &` trong thư mục `html/`.
2. Thêm kịch bản golden (mục 6) vào `tools/golden.mjs`, rồi chụp `.golden-base`, chụp `.golden-check`, so — phải "Khớp hoàn toàn".
3. Mở từng ảnh `SC_bj06_*` trong `.golden-base`: mỗi bước phải làm màn đổi (`.txt` khác bước trước), trừ các bước chỉ gõ chữ không dựng lại (ghi ở mục 9). Bước nào không đổi → sửa selector rồi chụp lại.
4. **Kiểm "mã chết" trên trình duyệt** (trước khi xoá), trang `?uif=UIF-06&screen=SCR-030`:
   - Mở `RET-260827-03` → dòng đầu → chọn "Lô DH2507" → "Xong": **không có toast** "Đã cập nhật hàng khách trả".
   - `?uif=UIF-06&screen=SCR-034&state=TASK_LIST` → mở ca `EX-06-001` → nút chính có `data-io06-action="approve-exception"` (không phải `data-v350-action`); bấm → banner "Đã duyệt ngoại lệ" (không phải `SELF_APPROVAL_NOT_ALLOWED`).
   - Nếu một trong hai sai → dừng, báo phiên review (bản đồ 2.3 sai).

## 4. Các bước

### 4.1 `app/core.js` — móc "quay lại" (khung)

Thêm cạnh `const onScreenEnter = {};`:

```js
// Móc nút quay lại (data-back) theo luồng, thay cho nhánh của từng BJ trong previousScreen.
const onPrevious = {};
```

Trong `previousScreen()`, ngay sau dòng `ThemeApp.handlePrevious()`:

```js
if (onPrevious[activeFlowId]) return onPrevious[activeFlowId]();
```

Xoá khối `if (activeFlowId === "UIF-06") {…}` trong `previousScreen` (chuyển sang bước 4.3.9). Giữ đúng ngữ nghĩa cũ: màn khác 031 / 032 / 033 → không làm gì.

### 4.2 Thứ tự chép trong `app/bj06.js`

1. Chú thích đầu file: BJ-06, UIF-06, SCR-030…035; "Đã viết lại sạch (T7-P gói A2, ngày …)"; dùng chung từ `core.js` (`appShell`, `ds24*`, `io*` chung: `ioMatchesSearch`, `ioNormalizeSearch`, `ioFilterRows`, `ioEmpty`, `ioResult`, `resultHero`, `ioSecondary`, `ioMetaRow`, `ioReadCard`; `vBanner`, `deniedBody`, `loadingBody`, `esc`, `escapeAttribute`, `icon`, `primaryFooter`, `navigate`, `renderAppScreen`, `onPrevious`); còn ở `core.js`: `handoff-unknown` + nhánh UIF-06 của `v350LockSourceForUnknown` (A10), `bumpIO06Source` (A11), `SCR-030/034/035` trong bảng `v360` (A11).
2. Fixture + trạng thái (`app.js`) → `io06Requests.forEach((r) => { r.unknownLocked ??= false; });` → hằng của `v394` (`BJ06_BUSINESS_DATE`…) → helper `bj06*` của `v394` → helper `io06*` (thân `v394` cho 18 hàm ở 2.4) → **chuẩn hoá fixture của `v394`** (nó gọi `bj06ResolveLot`, `bj06StableHash`, `io06FindLine` — phải đứng sau các hàm đó vì là câu lệnh chạy ngay, không phải khai báo hàm) → `updateIO06LineValidation`, `updateIO06ClassificationLive` → `io06DsTone` … `io06ResultGroupsHtml` → `bj06LotDetailsHtml`, `bj06EvidenceHtml` → hàm dựng → đăng ký → listener.

### 4.3 `app/bj06.js` — chi tiết

1. Chép theo thứ tự 4.2. Hàm khai báo bằng `function` giữ tên `io06*` (lớp chung `v350LockSourceForUnknown`, `bumpIO06Source` gọi `io06CurrentRequest`, `io06RefreshRequestState` theo tên toàn cục).
2. Với 18 hàm ở 2.4: viết **một** `function io06X(…) {…}` với thân của `v394`; không còn câu `io06X = function…` nào. `grep -n "io06[A-Za-z]*\s*=\s*function\|updateIO06ClassificationLive\s*=" app/*.js` phải rỗng.
3. Tên cục bộ của `v394` lên cấp file — **bắt buộc có tiền tố**, vì mọi `app/*.js` là script thường, chung một phạm vi toàn cục (`const attr` / `upper` / `MAKER` trần sẽ đụng hoặc che tên khác): `BJ06_BUSINESS_DATE`, `BJ06_MAKER`, `BJ06_LOTS`, `BJ06_CONDITIONS`, `BJ06_AUTH`, `bj06Attr`, `bj06Upper`, `bj06StableHash`, `bj06IsoNow`, `bj06DisplayTime`, `bj06LineMax`, `bj06LotMeta`, `bj06ResolveLot`, `bj06LotDataReady`, `bj06Expiry`, `bj06IsExpired`, `bj06EvidenceIdentity`, `bj06SnapshotCore`, `bj06SubjectHash`, `bj06FileSha256`, `bj06LotDetailsHtml`, `bj06EvidenceHtml`. Đổi tên trong **toàn bộ** phần chép từ `v394` (kể cả thân 18 hàm và hàm dựng). Thuộc tính `data-v394-*` (`data-v394-lot-details`, `data-v394-new-lot-expiry`, `data-v394-new-lot-manufacture`) **giữ nguyên** — là HTML, golden so được, đổi ở Giai đoạn 2.
4. Hàm dựng (đổi tên cho thống nhất với `bj05.js`):

   | Hàm | Thân lấy từ | Sửa |
   |---|---|---|
   | `render030BJ06` | `render030IO06` | Bỏ dòng `if(activeFlowId!=="UIF-06") return renderGeneric(…)` |
   | `render031BJ06` | `render031IO06` | Như trên; **mọi** `title:"Hàng khách trả"` → `title:"Kiểm hàng khách trả"` |
   | `render032BJ06` … `render035BJ06` | `renderers['SCR-032' … '035']=function` của `v394` | Bỏ `if(activeFlowId!=='UIF-06')return baseNNN(state);` |

   Hàm `displayTime` / `bj06DisplayTime`, `io06DsTone`, `io06Textarea`, `io06ResultLineLabel`, `io06ClassificationSummary`, `bj06EvidenceIdentity`: sau khi chép, `grep` nơi gọi trong `bj06.js`; hàm nào không ai gọi → xoá, ghi ở mục 9.
5. Đăng ký:
   ```js
   Object.assign(renderers, { "SCR-030": render030BJ06, "SCR-031": render031BJ06, "SCR-032": render032BJ06, "SCR-033": render033BJ06, "SCR-034": render034BJ06, "SCR-035": render035BJ06 });
   ownedFlows.add("UIF-06");
   ```
6. **Listener `input`** (`document`, pha bubble):
   - 4 dòng `data-io06-search`, `data-io06-reason-detail`, `data-io06-reject-reason`, `data-io06-class` từ listener chung (nguyên văn, giữ `return`).
   - 4 dòng `data-io06-qty`, `data-io06-actual-lot`, `data-v394-new-lot-expiry`, `data-v394-new-lot-manufacture` từ `v394`: bỏ `event.stopImmediatePropagation()`; `lotDetailsHtml` → `bj06LotDetailsHtml`, `v394LineMax` → `bj06LineMax`.
   - Đầu listener: `if (activeFlowId !== "UIF-06") return; const t = event.target;`.
7. **Listener `change`** (`document`): dòng `data-io06-actual-lot` của listener chung + thân `data-io06-evidence-file` của `v394` (bỏ `stopImmediatePropagation`, `fileSha256` → `bj06FileSha256`).
8. **Listener `click`** (`document`, **pha capture** — `addEventListener("click", …, true)`, như listener chung đang làm, để chạy trước listener `data-action` / `data-back` pha bubble):
   ```js
   document.addEventListener("click", (event) => {
     if (activeFlowId !== "UIF-06") return;
     if (event.target.closest('[data-action="exit-io06-approval"]')) { io06ApproverListMode = true; io06RejectOpen = false; event.stopPropagation(); return renderAppScreen(); }
     // 9 dòng f6, r6, line6, classLine, reason6, expectedLot6 (+ phần v394 ở đầu), otherLot6 (+ phần v394 ở đầu), approvalCase6, reject-backdrop — chép nguyên văn
     const a = event.target.closest("[data-io06-action]"); if (!a) return;
     event.preventDefault(); event.stopPropagation();
     const k = a.dataset.io06Action;
     // 16 khoá ở bảng 2.5: 5 khoá thân v394, 11 khoá thân listener chung
   }, true);
   ```
   `exit-io06-approval`: listener `data-action` chung không cần `stopPropagation` của mình vì đã xoá dòng đó (bước 4.4); `stopPropagation` ở đây chỉ để chắc chắn — bỏ đi cũng được, golden quyết định.
9. Móc quay lại:
   ```js
   onPrevious["UIF-06"] = () => {
     if (activeScreenId === "SCR-031") return navigate("SCR-030");
     if (activeScreenId === "SCR-032") return navigate("SCR-031");
     if (activeScreenId === "SCR-033") { io06ClassificationOpen = false; io06ClassificationDraft = null; return navigate("SCR-030"); }
   };
   ```

### 4.4 Xoá trong `app/core.js`

1. `app.js`: mọi thứ đã chép ở 4.2 / 4.3 và `render032IO06` … `render035IO06`; mục `"SCR-030"…"SCR-035"` trong literal `const renderers = {…}`; khối UIF-06 trong `previousScreen`; dòng `exit-io06-approval` trong listener `data-action`.
2. Listener chung `// Inventory Operations interactions`:
   - `input`: 6 dòng `UIF-06` (giữ 2 dòng `UIF-07`).
   - `change`: 2 dòng `UIF-06` → listener rỗng → **xoá cả listener**.
   - `click`: đổi `if(!["UIF-06","UIF-07"].includes(activeFlowId)) return;` thành `if(activeFlowId!=="UIF-07") return;`; xoá 9 dòng `io06`; selector `"[data-io06-action],[data-io07-action]"` → `"[data-io07-action]"`; `const k=a.dataset.io06Action||a.dataset.io07Action` → `a.dataset.io07Action`; xoá mọi nhánh khoá ở bảng 2.5. Trước khi xoá một khoá: `grep -n 'data-io07-action="<khoá>"' app/core.js` — khoá nào BJ-07 cũng dùng thì giữ (đo 2026-10-17: không khoá nào trùng).
   - Sửa chú thích đầu khối: "UIF-07 (BJ-06 ở app/bj06.js)". Sửa chú thích ~1689 "Inventory Operations shared helpers (BJ-06 / BJ-07)" → "(BJ-07)".
3. `v350`: khởi tạo `io06Requests.forEach(…)`; dòng `UIF-06` trong wrapper `navigate`; lớp bọc `io06ReceiptReady`; listener `commit-receipt`; mục `SCR-035` trong `unknowns`; `v350Render034Base` + `renderers["SCR-034"]=…`; 2 khoá `io06-*` trong mảng khoá và 2 nhánh của listener `data-v350-action`; vế `activeFlowId==="UIF-06"?"SCR-034":`. **Giữ**: nhánh UIF-06 trong `v350LockSourceForUnknown`, `bumpIO06Source`.
4. `v360`: 2 dòng toast `io06`.
5. `legacy-cross-theme-copy`: khối `if(activeFlowId==='UIF-06'&&activeScreenId==='SCR-031'){…}` (3 dòng, kèm chú thích phía trên).
6. **Cả khối** `===== v394-bj06-semantic-hardening.js =====`.

### 4.5 Đo bước sửa sau dựng (trước khi tin golden)

Dùng nguyên đoạn đo của [A1 mục 4.5](T7-P-A1-bj04-bj05.md), đổi danh sách luồng thành `["UIF-06"]`, trên trang `?uif=UIF-06&screen=SCR-030` với `ownedFlows.add("UIF-06")` **tạm comment**.

- Lưu ý: bước 4.4.5 và 4.4.6 (đổi tiêu đề) đã xoá thì bản "piped" không còn đổi tiêu đề → so sẽ báo khác ở `<h3>` SCR-031. Vì vậy **chạy đoạn đo trước khi xoá 4.4.5 / 4.4.6** (hai bước đó xoá cuối cùng), hoặc chấp nhận đúng một khác biệt: `<h3>` SCR-031 "Kiểm hàng khách trả" (bare) vs … (piped) — mọi khác biệt khác phải gộp.
- Các bước sửa sau dựng hay chạm BJ-06: `v360` (`ensureStableExitAffordance` cho SCR-030 / 034 / 035), `v361` (footer), `v440` (grouped surface), `v470` / `v471` (tone badge). Khác ở đâu → gộp vào hàm dựng `bj06.js`, chạy lại đến khi "không khác". Ghi các chỗ đã gộp ở mục 9.
- `render033` của `v394` ghi đè `classification` của dòng hết hạn khi dựng; `render035` `UNKNOWN` không đổi fixture nhưng các trạng thái khác có thể — **tải lại trang** trước mỗi lần chạy đoạn đo.

## 5. Kiểm

| Kiểm | Cách | Đạt khi |
|---|---|---|
| Cú pháp | `node --check app/core.js app/bj06.js` | Không lỗi |
| Không còn mã cũ | `grep -n "io06\|IO06\|v394" app/core.js` | Chỉ còn: nhánh UIF-06 của `v350LockSourceForUnknown`, `bumpIO06Source`, `SCR-030/034/035` trong bảng `v360` (khớp số, không khớp chuỗi `io06`), `FIGMA_TEMPLATE_BY_FLOW_SCREEN`, nhãn phiên bản inspector, `entryMode` dòng ~87–88. Không còn khối `v394` |
| Một định nghĩa | `grep -n "io06[A-Za-z]*\s*=\s*function" app/*.js` | Rỗng |
| Không đụng tên | `grep -n "^\(const\|let\|function\) \(attr\|upper\|MAKER\|LOTS\|AUTH\|isoNow\)\b" app/*.js` | Rỗng (mọi tên từ `v394` đã có tiền tố `bj06` / `BJ06_`) |
| Golden | `capture tools/.golden-check` rồi `compare tools/.golden-base tools/.golden-check` | **Khớp hoàn toàn** (ca cũ + kịch bản mới) |
| Lỗi JS | `tools/.golden-check/_errors.json` | Rỗng |
| Luồng khác | `SC_ws_movement_*` (Hub → Hàng khách trả), mọi `SC_bj05_*`, các ca `UIF-07_*` | Khớp |
| Bấm thử | Phiên review chạy khi review | 0 lỗi |

## 6. Kịch bản golden thêm (`tools/golden.mjs`)

Đặt sau khối `// BJ-04 … BJ-05 — T7-P A1`, tiêu đề `// BJ-06 Hàng khách trả (UIF-06) — T7-P A2`. Dùng `click(sel, i)`, `back`, `typeIn` đã có. `U = '?uif=UIF-06&screen='`.

| Tên | Bắt đầu | Bước |
|---|---|---|
| `SC_bj06_list` | `U+'SCR-030'` | `[data-io06-filter="ACTIONABLE"]` → `[data-io06-filter="WAITING"]` → `[data-io06-filter="ALL"]` → `typeIn('[data-io06-search]','Nam Việt')` → `typeIn('[data-io06-search]','')` |
| `SC_bj06_line` | như trên | `[data-io06-request="RET-260827-03"]` → `[data-io06-line="RET-L1A"]` → `typeIn('[data-io06-qty]','5')` (vượt 3 → lỗi trần) → `typeIn('[data-io06-qty]','2')` → `[data-io06-select-actual-lot]` → `[data-io06-action="save-return-line"]` → `back` (SCR-031 → SCR-030) |
| `SC_bj06_other_lot` | như trên | `[data-io06-request="RET-260827-03"]` → `[data-io06-line="RET-L1A"]` → `[data-io06-select-other-lot]` → `typeIn('[data-io06-actual-lot]','DH2509')` → `[data-io06-reason="OTHER"]` → `[data-io06-reason="RETURNED_DIFFERENT_LOT"]` → `[data-io06-select-actual-lot]` (về đúng lô — xoá bằng chứng) → `back` |
| `SC_bj06_receipt` | như trên | `[data-io06-request="RET-260827-03"]`, rồi với từng dòng `RET-L1A`, `RET-L1B`, `RET-L2` (có lô): `[data-io06-line="…"]` → `typeIn('[data-io06-qty]','1')` → `[data-io06-select-actual-lot]` → `save-return-line`; dòng `RET-L3` (không lô): `[data-io06-line="RET-L3"]` → `typeIn('[data-io06-qty]','1')` → `save-return-line`; rồi `[data-io06-action="commit-receipt"]` → `[data-io06-action="open-classification"]` |
| `SC_bj06_classify` | như trên | `[data-io06-request="RET-260827-05"]` (đi thẳng SCR-033) → `[data-io06-class-line]` (dòng 0) → `[data-io06-action="cancel-classification-item"]` → `[data-io06-class-line]` (dòng 1, `click(sel,1)`) → `typeIn('[data-io06-class="sellable"]','5')` → `[data-io06-action="close-classification-item"]` → `[data-io06-action="confirm-classification"]` → `[data-io06-action="result-to-return-queue"]` |
| `SC_bj06_approve` | `U+'SCR-034&state=TASK_LIST'` | `[data-io06-approval-case="EX-06-001"]` → `[data-io06-action="approve-exception"]` → `[data-io06-action="exit-approval-detail"]` |
| `SC_bj06_reject` | như trên | `[data-io06-approval-case="EX-06-001"]` → `[data-io06-action="open-reject"]` → `[data-io06-reject-backdrop]` → `[data-io06-action="open-reject"]` → `typeIn('[data-io06-reject-reason]','Ảnh không rõ lô')` → `[data-io06-action="confirm-reject"]` → `#app-screen .app-back-button` (`exit-io06-approval`) |
| `SC_bj06_cap_changed` | `U+'SCR-031&state=RETURN_CAP_CHANGED'` | `[data-io06-action="refresh-return-request"]` |
| `SC_bj06_unknown` | `U+'SCR-035&state=UNKNOWN'` | `[data-v350-action="handoff-unknown"]` (sang BJ-17) |
| `SC_bj06_approver_entry` | `'?uif=UIF-06&entry=approver'` | `[data-io06-approval-case]` (ca đầu) |

`SC_bj06_classify`: dòng `RET-L4` là lô hết hạn (`DH2408`) — tự vào nhóm Hết hạn; nếu "Hoàn tất phân loại" vẫn tắt sau bước `close-classification-item` thì mở thêm dòng 0 và lưu, ghi lại ở mục 9. `SC_bj06_receipt`: dòng nào nút "Xong" tắt (số lượng / lô không hợp lệ) thì chỉnh số theo `BJ06_AUTH`, ghi ở mục 9.

## 7. Bẫy

1. **Thứ tự `window` capture → `document`:** sau khi gộp, mọi listener BJ-06 nằm trên `document`. Listener `document` capture đăng ký **trước** `bj06.js` (vd. bảng toast `v360`) giờ sẽ thấy được các cú bấm mà trước đây `v394` chặn. Vì vậy phải xoá 2 dòng toast `io06` (4.4.4), nếu không sẽ **hiện thêm** toast. Sau khi xong: `grep -n "data-io06" app/core.js` phải rỗng.
2. **Listener chung còn sót nhánh `io06`** mà quên đổi selector → nút BJ-06 chạy hai lần (một ở `bj06.js`, một ở `core.js`) → vd. `submit-return-exceptions` tạo hai ca duyệt. Golden `SC_bj06_receipt` / `SC_bj06_approve` bắt được.
3. **Chuẩn hoá fixture là câu lệnh chạy ngay** (4.2): đặt trước các hàm nó gọi được (hàm khai báo `function` được hoist), nhưng **không** trước các `const` nó dùng (`BJ06_LOTS`, `BJ06_AUTH`, `BJ06_CONDITIONS`) — lỗi TDZ.
4. **Tên toàn cục trần** từ IIFE `v394` (4.3.3). Quên đổi một chỗ `upper(` / `attr(` → `ReferenceError` chỉ khi dựng đúng trạng thái đó; đoạn đo 4.5 dựng mọi trạng thái nên bắt được.
5. **`async` trong `FileReader.onload`** (evidence file): giữ `async` và `await bj06FileSha256(file)`.
6. **Hàm có tham số mặc định dạng object** (`io06ResultGroupsHtml(lines,{classified=false}={})`): khi cắt bằng công cụ, tìm thân hàm sau dấu `)` đóng tham số.
7. **Biến khai báo gộp** (`let io06SelectedRequestId=…, …, io06ApproverListMode=true;`): chuyển nguyên câu.
8. **Lần cắt khối của A1 từng nuốt fixture `io07`** (A1 mục 9): fixture `io07Requests` nằm ngay sau `io06ClassificationSummary` (~1759) — cắt đến hết `io06ClassificationSummary`, không hơn. `grep -n "^const io07Requests" app/core.js` phải còn.

## 8. Ghi lại và commit

1. `CHANGELOG.md`: mục `[5.1.2] — T7-P Giai đoạn 1, gói A2: BJ-06 viết lại sạch` (chuyển gì, gỡ lớp nào, móc `onPrevious`, mã chết đã xoá ở 2.3, kịch bản golden mới). `manifest.json` → `5.1.2`.
2. `docs/refactor/plans/T7/T7-P-thiet-ke-lai-luong.md`: mục 14 A2 Làm ✅ (mục 8.1 hàng A2 đã được phiên plan sửa: 18 hàm, móc `onPrevious` — các gói sau dùng lại móc này thay cho nhánh trong `previousScreen`).
3. `python3 tools/sync-registry.py`.
4. `detect_changes()` theo CLAUDE.md (chỉ đổi prototype), rồi commit: `refactor(prototype): T7-P A2 — BJ-06 clean code in app/bj06.js`.

## 9. Ghi chú khi làm

- Cho Giai đoạn 2 (brief BJ-06): chặn tự duyệt ngoại lệ lô và chặn ghi nhận khi yêu cầu nguồn đổi (`sourceVersion`) hiện không chạy (mục 2.3); `data-v394-*` cần đổi tên.
- Đo 4.5 (pipe vs bare, tạm bỏ `ownedFlows`): **không khác** trước khi gộp; sau ownedFlows, SCR-034 `PERMISSION_DENIED` thiếu nút "Về danh sách" của `v360` → gộp `primaryFooter(… fallback-exit … SCR-030)` vào `render034BJ06`.
- `bj06IsoNow` cố định `2026-09-16T08:00:00.000Z` (trước: `new Date().toISOString()` của `v394`) để golden `SC_bj06_receipt` / classify không lệch giờ giữa hai lần chụp.
- Hàm không ai gọi đã xoá: `io06DsTone`, `io06ResultLineLabel`, `io06ClassificationSummary`.
- Golden selector: giữ nguyên plan mục 6; 816 ca khớp; 0 lỗi JS.

## 10. Review

(Phiên review điền sau khi bạn báo xong.)
