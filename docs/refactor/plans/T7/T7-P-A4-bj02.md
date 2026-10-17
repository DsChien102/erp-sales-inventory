# T7-P · Gói A4 — viết lại code sạch BJ-02 Nhận hàng mua

> Theme: Theme 7 Inventory · Trạng thái: Plan ✅ | Làm ✅ | Review ⬜
> Thuộc [T7-P](T7-P-thiet-ke-lai-luong.md) Giai đoạn 1, gói A4 (mục 8.1). Ước lượng: **~2 ngày, 1 commit** (làm theo 4 chặng, mỗi chặng golden khớp rồi mới sang chặng sau).
> Người làm: bạn. Review: phiên plan / review. Mẫu: `app/bj05.js`, `app/bj06.js`; cách làm, đoạn đo, `typeIn`: [A1](T7-P-A1-bj04-bj05.md), [A2](T7-P-A2-bj06.md).
> Làm **sau A2** (A2 đã sửa listener `data-v350-action` và `previousScreen` mà A4 cũng sửa) và sau A3 nếu được (cùng sửa `v360`).

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/`. Plan được đo ngày 2026-10-17 **trong lúc A2 đang làm** — số dòng trôi liên tục, nên plan **chỉ neo theo chuỗi** (tên hàm, tiêu đề khối, đoạn code trong ngoặc). Trước khi bắt đầu, chạy lại các lệnh `grep` ở mục 2.6 để chắc bản đồ vẫn đúng.

## 1. Mục tiêu

1. Toàn bộ BJ-02 (UIF-02: SCR-006, 007, 008, 009, 084, 010, 011, 012, 013) vào `app/bj02.js`: fixture, trạng thái, helper, hàm dựng cuối cùng, xử lý sự kiện.
2. Gỡ BJ-02 khỏi các lớp cũ: `v392` (xoá cả khối), `v466` / `v467` / `v468` (xoá cả khối), `v471` (xoá cả khối), phần BJ-02 trong `v350`, `v360`, `v460`, `v461`, `legacy-sheet-cleanup`, `legacy-cross-theme-copy`, `previousScreen`, listener chung của `app.js`.
3. Xoá cụm "nhập nhanh đời đầu" đang chết (mục 2.4).
4. `UIF-02` vào `ownedFlows`.
5. **Giao diện và hành vi không đổi:** golden khớp hoàn toàn; bấm thử 0 lỗi JS.

Không làm: đổi thiết kế (BJ-02 là BJ đầu tiên của Giai đoạn 2, câu hỏi 15.1 chốt ở đó); CSS `.bj02-*` / `.v392-*` (A11); cơ chế chuyển sang BJ-17 (`bj02-verify-unknown`, `bj02-handoff-unknown` trong listener `v350` — A10); `addPendingReviewExit` và các lối "Về Kho" trong `hub.js` (mục 2.5); `simplifyNormalBanners` (`v360`) và `applyGroupedSurfaceRule` (`v440`) bọc `render()` cho mọi luồng (A11).

## 2. Bản đồ hiện trạng

### 2.1 Màn — bản thắng

Thứ tự nạp: `app.js` → `v350` → `v360` → `v392` → `v460` → `v461` → `v466`–`v468` → `v470` → `v471`.

| Màn | Bản đang chạy | Bị đè (chết) |
|---|---|---|
| SCR-006 Nhận hàng | `v392` (`renderers['SCR-006']`); với `PERMISSION_DENIED` / `LOADING` gọi `r006` = `render006` của `app.js` | Phần còn lại của `render006` |
| SCR-007 Chứng từ chờ nhận | `render007` (`app.js`) + `v392` `.replaceAll('2 sản phẩm đang chờ nhận','2 mặt hàng đang chờ nhận').replaceAll('1 sản phẩm','1 mặt hàng')` | — |
| SCR-008 Nhập hàng nhanh | `v392` (`renderers['SCR-008']`), rồi `v460` **và** `v461` bọc cùng hai `replace` (ô "Kho nhận" `readonly` → `disabled aria-disabled="true"`; bỏ `<small>Ngày nghiệp vụ của tenant do hệ thống xác lập.</small>`). Bọc lần hai không đổi gì thêm | `render008` (`app.js`) |
| SCR-009 Hàng thực nhận | `render009` (`app.js`) + `v392` `.replaceAll('sản phẩm','mặt hàng')` trên **cả HTML** | — |
| SCR-084 Chi tiết hàng thực nhận | `render084` (`app.js`) + `v392` `.replaceAll('Tổng thực nhận','Tổng kiểm nhận')` | — |
| SCR-010 Rà soát | `v392` | `render010` (`app.js`) |
| SCR-011 Phê duyệt | `v392` — **không gọi bản trước**, nên lớp bọc `v350Render011Base` (đổi `approve` / `confirm-reject` sang `data-v350-action`) không có tác dụng | `render011` (`app.js`), `v350Render011Base` |
| SCR-012 Kết quả | `v392`, tự xử lý `UNKNOWN` / `COMMIT_UNKNOWN` (nút `data-v350-action="bj02-verify-unknown"`) | `render012` (`app.js`), lớp bọc `v350Render012Base` |
| SCR-013 Đối soát | `v392`, tự phát `data-v350-action="bj02-handoff-unknown"` | `render013` (`app.js`), lớp bọc `v350Render013Base` |

### 2.2 Hàm toàn cục bị gán lại / bọc (giữ **một** định nghĩa)

| Hàm | Bản thắng | Cách gộp |
|---|---|---|
| `documentLineVariance`, `documentVarianceFeedback`, `lineAcceptedBase`, `documentLineAllowanceBase`, `bj02RequiresApproval`, `receiptRiskValue`, `bj02ReviewIssue`, `bj02SupplierSelectSheet`, `bj02ReceiptContext`, `bj02SourceRows`, `renderActiveLotEditor` (11) | `v392` gán lại | Một `function` với thân `v392` |
| `selectSupplier` | `v392` bọc (`v392SelectSupplierBase`): nếu đổi NCC thì xoá chứng từ, xác nhận sở hữu, `priceBasisVerified`; gọi bản gốc; toast "Đã đổi nhà cung cấp; …" | Gộp vào bản gốc: phần trước ở đầu, toast ở cuối |
| `lineEditorValid` | `v392` bọc: thêm kiểm hạn dùng / NSX theo độ chính xác (`v392ValidPrecisionValue`) | Gộp vào cuối bản gốc |
| `bj02ReviewProductBlocks` | `v471` bọc: dựng HTML gốc rồi sửa qua một `div` tạm — dòng phụ thành `sku · tổng đơn vị`, thêm danh sách lô `v471-lot-list` | Gộp vào bản gốc (mục 4.3.4) |

### 2.3 Bước sửa sau dựng / theo thời điểm phải gộp vào hàm dựng

| Bước | Ở đâu | Làm gì với BJ-02 | Xử lý |
|---|---|---|---|
| `ensureBj02ReviewFixture` | `v360`, gọi trong `ensureRepresentativeFixture()` **trước** khi dựng (bọc `renderFlowScreen`) | Gieo dữ liệu đại diện cho SCR-084 / 010 / 011 / 012 khi mở thẳng | Chuyển sang `bj02.js` (cùng `v360SeedBj02DocumentLines` → `bj02SeedDocumentLines`, `v360Bj02HasExplicitDraftData` → `bj02HasExplicitDraftData`); gọi ở **đầu** `render084BJ02`, `render010BJ02`, `render011BJ02`, `render012BJ02`; bỏ khỏi danh sách trong `ensureRepresentativeFixture` |
| Toast "Đã cập nhật hàng thực nhận" | bảng toast `v360` (`[data-bj02-action="save-line"]`) | Hẹn giờ 30 ms | Gọi `showToast` trong handler `save-line`, ngay sau `saveEditorLine()` |
| `cleanupDismissibleSheets` | `legacy-sheet-cleanup` | Xoá `.bj02-review-detail-sheet .bj02-review-close-button` | Không dựng nút đó trong `bj02ReviewDetailSheet`; xoá dòng |
| `polishCrossThemeCopy` | `legacy-cross-theme-copy` | SCR-012 (trừ `PROCESSING`, `UNKNOWN`, `COMMIT_UNKNOWN`, `REJECTED_EXECUTION`): badge "Vượt chứng từ" → "Đã duyệt vượt", tone success | Tham số cho `bj02ReviewProductBlocks` (vd. `{ resultMode: true }`) để SCR-012 dựng thẳng badge "Đã duyệt vượt" success; xoá khối |
| `decorateKeyValues` | `v470` (MutationObserver, **bỏ qua luồng trong `ownedFlows`**) | Dòng key-value có nhãn chứa "rủi ro" (SCR-011 "Tổng giá trị rủi ro") → class `v470-kv--warning`; số âm `-` → `−` | Gộp vào `bj02KeyValueRow` (mục 4.3.5) |
| `ensureStableExitAffordance` | `v360` | SCR-011 / 012 / 013 nằm trong `v360ExitTargets`; chỉ chèn "Về danh sách" khi màn **không có** nút nào bấm được | Đo ở 4.4 |
| `normalizeDualFooters` (`v361`), `applyGroupedSurfaceRule` (`v440` — bọc `renderFlowScreen`) | | | Đo ở 4.4 |
| `render()` cuối `v392`, `renderAppScreen()` cuối `v471` | | Dựng lại sau khi lớp nạp | Xoá (`hub.js` gọi `render()` sau cùng) |

### 2.4 Mã chết (xoá, không chuyển)

| Mã | Vì sao chết | Kiểm trước khi xoá |
|---|---|---|
| `render008`, `render010`, `render011`, `render012`, `render013` (`app.js`) và phần của `render006` ngoài `PERMISSION_DENIED` / `LOADING` | `v392` đè, không gọi lại | — |
| `v350`: `v350Render011Base` + `renderers["SCR-011"]=…`; `v350Render012Base`, `v350Render013Base` + hai `renderers[…]=…`; khoá `bj02-approve`, `bj02-confirm-reject` trong mảng khoá và 2 nhánh của listener `data-v350-action`; vế `activeFlowId==="UIF-02"?"SCR-011":` | 2.1 — SCR-011 / 012 / 013 của `v392` không gọi bản trước. Nút duyệt là `data-action="approve"`; nút xác nhận từ chối nằm trong sheet do `openRejectSheet` chèn thẳng vào DOM (`data-action="confirm-reject"`), không qua hàm dựng | Mục 3.4 |
| **Cụm "nhập nhanh đời đầu"**: `selectedQuickProductId`, `quickProductMenuOpen`, `receiptDraft`, `lotSequence`, `quickProductById`, `renderQuickProductDiscovery`, `selectedProductSummary`, `balanceStatusHtml`, `renderReceiptBalance`, `quantitySelector`, `lotEntry`, `documentReceivingProduct`, `activeReceivingProduct`, `collectReceiptDraft`, `receiptTotals`, `receiptSummary`, `quantityTotal`, `updateReceiptBalance`, `addLotEntry`, `removeLotEntry`, `hasReceiptLineInput`, `selectQuickProduct`, `resetQuickProduct`, `openChangeProductDialog`, `closeChangeProductDialog`, `filterQuickProductOptions`; trong listener chung: `[data-product-option]`, `data-action` `change-product` / `close-product-change` / `confirm-product-change` / `add-lot` / `remove-lot`, nhánh `[data-product-search]` của `focusin` / `pointerdown` / `input`, `[data-qty], .lot-meta-grid input`; dòng `updateReceiptBalance()` trong `renderFlowScreen` | `renderQuickProductDiscovery`, `selectedProductSummary`, `renderReceiptBalance` không ai gọi (đếm: 1 lần = chỉ định nghĩa). Các phần tử `data-product-option`, `data-product-search`, `data-qty`, `data-action="add-lot|remove-lot|change-product"` chỉ do các hàm chết này (và `lotEntry`, chỉ được `addLotEntry` gọi) phát ra | Bước 4.1.2: mỗi tên `grep -c` → chỉ còn trong cụm; mỗi selector `grep -n 'data-product-option\|data-product-search\|data-qty\|"add-lot"\|"remove-lot"\|"change-product"'` → chỉ ra hàm trong cụm. Tên nào còn nơi dùng sống (vd. `quickProductCatalog` dùng trong `productById`) → **giữ**, ghi mục 9 |
| `showToastBj02` | Một nơi gọi (đo: 2 lần = định nghĩa + 1 gọi) | Đổi nơi gọi sang `showToast`, xoá hàm. `showToastLegacy` không ai gọi → để A11 (khung) |
| `v466`, `v467`, `v468` | Chỉ ghi `window.__VET45_PROTOTYPE__.version` (bị `v470` ghi đè), nhãn `.review-badge` (bị `v470` ghi đè), `scenarios`, `bj02QuickReceipt` | Chuyển **chỉ** `scenarios` (3 mục) và `bj02QuickReceipt` (object sau cùng của `v468`) vào `bj02.js`; xoá 3 khối |

Ghi vào mục 9 (cho brief BJ-02 ở Giai đoạn 2): **chặn tự duyệt** (`SELF_APPROVAL_NOT_ALLOWED`) của BJ-02 hiện không chạy khi bấm, chỉ xem được bằng bộ chọn trạng thái.

### 2.5 Giữ ở chỗ cũ

| Mã | Lý do |
|---|---|
| `escapeAttribute`, `esc` (nằm giữa vùng BJ-02 trong `app.js`), `stateBanner` (`renderGeneric` dùng), `progress` (không ai gọi — A11), `toastTimer` (`showToastCanonical` dùng), `showToast*` | Khung, nhiều BJ dùng |
| `flowMode` (`let flowMode = initialParams.get("flow")…`), khối chọn màn đầu theo `entryMode` (nhánh `UIF-02`), `syncReviewUrl` ghi `flow` | Tham số URL của khung; golden dùng `&flow=quick` |
| `[data-flow]` trong listener click chung (đổi `flowMode`, `resetBj02Receipt`, sang SCR-007 / 008) | Chung một listener với `data-screen`, `data-state`, `data-next`, `data-back` của khung. **Chuyển** sang `bj02.js` được (chỉ BJ-02 phát `data-flow=`), nhưng phải đặt ở listener capture của `bj02.js` và `stopPropagation` — xem 4.3.7 |
| `bj02-verify-unknown`, `bj02-handoff-unknown` trong listener `data-v350-action` | A10 (dùng `v350HandoffUnknown` cục bộ của `v350`) |
| `hub.js`: `addPendingReviewExit`, `openDirect` (`bj02-pending-approval` gán `bj02Lines`, `bj02Header`, `approvalRejectReason`, gọi `resetBj02Receipt`), nhánh `exit-approval` | `hub.js` đã sạch; các biến trên là `let` cấp file trong script thường nên `hub.js` vẫn gán được sau khi chuyển. Plan tổng mục 8.1 định chuyển `addPendingReviewExit` vào hàm dựng SCR-010 — **không làm ở A4**: `afterFlowRender` của Hub xoá nút quay lại ở màn đã gửi duyệt rồi `addPendingReviewExit` thêm lại, dời sang hàm dựng sẽ làm đổi thứ tự đó ở chế độ theme. Để Giai đoạn 2 (bước B BJ-02, câu hỏi lối ra) |
| `window.VET45_BJ02_V392` | Không nơi nào ngoài `v392` đọc; chuyển `V392` thành `const BJ02_CONTEXT = {…}` trong `bj02.js` và **bỏ** gán `window.*` (ghi mục 9) |

### 2.6 Lệnh đo lại trước khi làm

```bash
grep -n "===== v392\|===== v46[678]\|===== v471\|===== legacy-sheet\|===== legacy-cross" app/core.js
grep -n "renderers\[.SCR-0\(0[6-9]\|1[0-3]\|84\).\]\s*=" app/core.js          # chỉ v350 (011/012/013), v392, v460, v461
grep -n "^\s*\(documentLineVariance\|documentVarianceFeedback\|lineAcceptedBase\|documentLineAllowanceBase\|bj02RequiresApproval\|receiptRiskValue\|bj02ReviewIssue\|bj02SupplierSelectSheet\|selectSupplier\|bj02ReceiptContext\|bj02SourceRows\|renderActiveLotEditor\|lineEditorValid\|bj02ReviewProductBlocks\)\s*=" app/core.js   # 14 dòng
grep -n "UIF-02\|bj02\|flowMode" app/hub.js
```

Khác với bảng → dừng, báo phiên review.

## 3. Chuẩn bị

1. `python3 -m http.server 8765 --bind 127.0.0.1 &` trong `html/`.
2. Thêm kịch bản golden (mục 6); chụp `.golden-base`, `.golden-check`, so — "Khớp hoàn toàn".
3. Mở ảnh `SC_bj02_*`: mỗi bước bấm phải làm màn đổi (bước gõ / chọn có thể không đổi — A1 mục 9).
4. **Kiểm mã chết trên trình duyệt** trước khi xoá, trang `?uif=UIF-02&screen=SCR-011`:
   - Nút "Duyệt" có `data-action="approve"` (không phải `data-v350-action`); bấm → SCR-012 `PROCESSING` (không phải `SELF_APPROVAL_NOT_ALLOWED`).
   - `?uif=UIF-02&screen=SCR-012&state=UNKNOWN`: màn là bản `v392` (vòng quay `VLoading`, nút `bj02-verify-unknown`), không phải `ioResult` "Đang xác minh kết quả" của `v350`.
   - Sai → dừng, báo phiên review.

## 4. Các bước

Làm theo 4 chặng; **cuối mỗi chặng chạy golden, phải khớp hoàn toàn** rồi mới sang chặng sau. `ownedFlows.add("UIF-02")` chỉ thêm ở chặng 4.

### 4.1 Chặng 1 — xoá mã chết (trong `core.js`, chưa đụng `bj02.js`)

1. Xoá các mục ở 2.4 hàng 1–2 (hàm dựng bị đè; lớp bọc / khoá chết của `v350`). `render006`: giữ hàm, rút thân còn hai nhánh `PERMISSION_DENIED` / `LOADING` (chỉ những nhánh `v392` còn gọi).
2. Cụm "nhập nhanh đời đầu": chạy các `grep` ở cột "Kiểm" 2.4 hàng 3; xoá những tên chỉ còn trong cụm; xoá các nhánh listener tương ứng và `updateReceiptBalance()` trong `renderFlowScreen`.
3. `showToastBj02` → `showToast` ở nơi gọi; xoá hàm.
4. Golden. Bấm thử nhanh SCR-009 / 084 (thêm dòng, nhập lô, lưu) để chắc không gọi phải tên đã xoá — `_errors.json` rỗng.

### 4.2 Chặng 2 — gộp lớp vào bản gốc (vẫn trong `core.js`)

Làm trên chỗ định nghĩa gốc trong `app.js` (chưa chuyển file — chuyển ở chặng 3, để mỗi chặng chỉ đổi một kiểu).

1. **11 hàm gán lại** (2.2): thay thân bản gốc bằng thân `v392`. Helper cục bộ của `v392` mà các thân này dùng → lên cấp file, đổi tiền tố `v392` → `bj02`. Riêng `v392Esc(` → `esc(` và `v392DateText(` → `formatIsoDate(` (hai hàm này chỉ bọc `typeof`). Còn lại: `bj02AcceptedPhysical`, `bj02AcceptedPhysicalTotal`, `bj02InspectedTotal`, `bj02RejectedTotal`, `bj02SourceRemaining`, `bj02FormatDateWithPrecision`, `bj02ValidPrecisionValue`, `bj02EvidenceRefs`, `bj02EvidenceLabel`, `bj02OwnershipReady`, `bj02MakeOwnershipAssertion`, `bj02EvidencePreviewSheet`, `bj02ChangeSourceSheet`). `V392` → `const BJ02_CONTEXT` (bỏ `window.VET45_BJ02_V392`). Tên nào không ai gọi sau khi gộp (vd. `bj02InspectedTotal`, `bj02RejectedTotal`, `bj02FormatDateWithPrecision`) → xoá, ghi mục 9.
2. **Chuẩn hoá fixture của `v392`** (`Object.values(documentReceiptCatalog).forEach(…)`, `bj02Header.businessDate=…`, `evidenceRefs ||= []`, `delete bj02Header.note`): đặt ngay sau fixture BJ-02 trong `app.js` (sau `let lineEditorDirty`), **sau** khi `productById`, `cloneBj02` đã khai báo — chúng là `function` nên được hoist, chỉ cần `BJ02_CONTEXT` đứng trước.
   - `resetBj02Receipt` dựng lại `bj02Header`: kiểm bản gốc có giữ `businessDate` / `evidenceRefs` không. Nếu không → **giữ đúng hành vi hiện tại** (chuẩn hoá chỉ chạy lúc nạp), không "sửa" thêm.
3. **`selectSupplier`, `lineEditorValid`**: gộp phần bọc vào bản gốc (2.2).
4. **Hàm dựng `v392`** (006, 008, 010, 011, 012, 013): thay `render006` … `render013` gốc bằng thân `v392` (006: hai nhánh gốc đặt đầu hàm). **007, 009, 084**: gộp `.replaceAll` vào chuỗi gốc:
   - 007: hai chuỗi "sản phẩm" → "mặt hàng" ngay trong `render007`.
   - 084: "Tổng thực nhận" → "Tổng kiểm nhận" — tìm mọi nơi sinh chuỗi này trong HTML của SCR-084 (`render084`, `lineTotalSummaryHtml`, `renderNonLotLineEditor`, `renderLotLineEditor`…). Nếu chuỗi đến từ helper mà màn khác (010 / 011 / 012) cũng dùng **và** màn đó đang hiện "Tổng thực nhận" → không sửa helper; thêm tham số nhãn.
   - 009: `replaceAll('sản phẩm','mặt hàng')` áp lên **cả HTML** (kể cả `aria-label`, `placeholder`). Cách an toàn: liệt kê mọi "sản phẩm" trong HTML SCR-009 ở mọi trạng thái (console: dựng `renderers['SCR-009'](st)` **trước** khi gộp, tìm chuỗi), sửa đúng từng nguồn như 084. Nếu nguồn quá rải rác → giữ `.replaceAll` **trong** `render009` (một dòng, chú thích "chữ của v392, gộp ở Giai đoạn 2"), ghi mục 9.
   - 008: hai `replace` của `v460` / `v461` gộp vào chuỗi: ô "Kho nhận" dùng `disabled aria-disabled="true"` thay `readonly aria-readonly="true"`; bỏ `<small>Ngày nghiệp vụ của tenant do hệ thống xác lập.</small>`. Xoá hai khối `parent008` trong `v460`, `v461` (giữ phần BJ-03 / 13 / 14 của hai lớp đó) và sửa dòng `Scope:` đầu hai lớp (bỏ "SCR-008").
5. **`bj02ReviewProductBlocks`** (gộp `v471`): trong vòng `bj02Lines.map`, dòng phụ dựng thẳng `[line.sku||line.productId, \`${lineTotals(line).totalReceived} ${line.uom}\`].filter(Boolean).join(' · ')` (escape như `v471`), rồi nối `bj02LotLines(line)` (= `lotLines` của `v471`) vào cuối `.bj02-review-summary-copy`. Thêm tham số `resultMode` cho badge "Đã duyệt vượt" (2.3). Đo bằng đoạn 4.4 trên SCR-010 / 011 / 012 — HTML phải giống hệt bản qua `div` tạm (thứ tự thuộc tính, khoảng trắng).
6. **`bj02KeyValueRow`** (gộp `v470`): nếu nhãn khớp `/rủi ro/i` → thêm class `v470-kv--warning`; giá trị bắt đầu `-` + số → `−`. Xem dòng `Chênh lệch` của `v470` có áp được cho BJ-02 không (đoạn đo cho biết); thuộc tính `data-v470="1"` **không** thêm (chỉ là dấu "đã xử lý" của observer).
7. Bước sửa sau dựng (2.3): `ensureBj02ReviewFixture` gọi ở đầu 4 hàm dựng + bỏ khỏi `ensureRepresentativeFixture`; nút đóng của `bj02ReviewDetailSheet`; badge SCR-012.
8. Listener của `v392` (`change` capture: `data-bj02-evidence-file`, `data-v392-lot-precision`; `click` capture: `data-v392-*`): gộp vào listener `app.js` cùng loại — `data-bj02-evidence-file`: phần `v392` (đặt `evidenceRefs`, `evidence`, xoá `ownershipAssertion`) **trước** phần gốc (`renderAppScreen`). Bỏ `stopImmediatePropagation` (không còn đối thủ).
9. Xoá cả khối `v392`, `v466`, `v467`, `v468`, `v471`; dòng toast `save-line` của `v360` (gọi `showToast` trong handler); dòng `.bj02-review-close-button` của `legacy-sheet-cleanup`; khối UIF-02 / SCR-012 của `legacy-cross-theme-copy`.
10. Golden. Ca nào khác → so HTML với bản trước chặng (đoạn đo 4.4 dùng được trên `core.js` cũ nếu bạn giữ một bản sao `core.before-a4-2.js` để tải tạm).

### 4.3 Chặng 3 — chuyển sang `app/bj02.js`

1. Chú thích đầu file theo mẫu `bj05.js` / `bj06.js`: BJ-02, UIF-02, 9 màn; "Đã viết lại sạch (T7-P gói A4, ngày …)"; dùng chung từ `core.js`; còn ở `core.js` / `hub.js` (bảng 2.5).
2. Chuyển, theo thứ tự trong `app.js`:
   - Fixture + trạng thái: từ `const supplierCatalog` (hoặc tên đầu tiên còn lại sau chặng 1) đến `let lineEditorDirty`, **trừ** `toastTimer` (khung). `localDateIso`, `formatIsoDate`, `BJ02_TENANT_BUSINESS_DATE`, `quickReceiptDateValid` đi theo (chỉ BJ-02 dùng — kiểm `grep`).
   - `BJ02_CONTEXT`, chuẩn hoá fixture.
   - `cloneBj02` … `resetBj02Receipt` (dừng trước `const icons`).
   - `bj02ListRow` … hết `render013`, **trừ** `escapeAttribute` (giữ ở `core.js`, đặt lại cạnh `esc`).
   - Hàm thao tác: `syncEditorDraftFromDom` … `selectSupplier` (vùng sau literal `renderers`).
   - `executionTimer`, `startAutoExecution`, `openRejectSheet`, `closeRejectSheet`, `confirmReject`.
   - `ensureBj02ReviewFixture` + 2 helper từ `v360`.
3. Đổi tên hàm dựng `render006` … `render013` → `render006BJ02` … `render013BJ02`. Helper giữ tên (`hub.js` gọi `resetBj02Receipt`). Sau chặng 1, `v350` không còn gọi `startAutoExecution` / `confirmReject` — kiểm bằng `grep`.
4. Đăng ký: `Object.assign(renderers, {…9 màn…})`; xoá 9 mục trong literal `const renderers = {…}` của `core.js`. `ownedFlows.add("UIF-02")` **chưa** thêm.
5. `window.__VET45_PROTOTYPE__`: thêm 3 mục `scenarios` + `bj02QuickReceipt` (2.4 hàng cuối).
6. Móc quay lại: `onPrevious["UIF-02"]` (móc do A2 thêm) = nguyên văn khối `if (activeFlowId === "UIF-02") {…}` trong `previousScreen`; xoá khối đó.
7. **Listener.** Gom thành một bộ listener trong `bj02.js`, giữ pha như gốc:
   - `click` capture (`…, true`): toàn bộ listener click đầu tiên của `app.js` (`[data-bj02-document-id]` … `open-existing-overview-line`), các nhánh `data-v392-*` (4.2 bước 8), và **`[data-flow]`** (chuyển từ listener click chung của khung; thêm `event.stopPropagation()` để listener chung bubble không xử lý lần nữa — sau khi xoá nhánh `[data-flow]` khỏi listener chung thì không cần, nhưng để chắc chắn). Đầu listener: `if (activeFlowId !== "UIF-02") return;` — gốc **không** kiểm luồng; kiểm `grep -n 'data-bj02-\|data-flow=\|data-v392-' app/*.js` chỉ ra `bj02.js` trước khi thêm điều kiện.
   - `click` bubble: các khoá `data-action` của BJ-02 trong listener chung (`close-reject`, `exit-flow`, `exit-approval`, `exit-receipt-document-context`, `submit`, `approve`, `open-reject`, `confirm-reject`, `refresh`, `handoff`) → listener riêng trong `bj02.js`, có kiểm `activeFlowId === "UIF-02"`. Đo 2026-10-17: các khoá này chỉ BJ-02 phát (`hub.js` có bắt `exit-approval` ở capture trước, giữ nguyên).
   - `focusin`, `focusout`, `pointerdown`, `change`, `input`: phần BJ-02 còn lại sau chặng 1 (`data-bj02-*`, `data-reject-reason`).
   - Xoá các phần đó khỏi listener chung; listener nào rỗng thì xoá cả listener.
8. Golden.

### 4.4 Chặng 4 — đo bước sửa sau dựng, rồi sở hữu luồng

1. Đoạn đo của [A1 mục 4.5](T7-P-A1-bj04-bj05.md), luồng `["UIF-02"]`, chạy **hai lần**: trang `?uif=UIF-02&screen=SCR-006&flow=document` và `…&flow=quick` (golden cũng chụp cả hai `flow`). Đặt `flowMode` theo trang trước vòng lặp.
   - Bỏ qua khác biệt chỉ gồm thuộc tính `data-v470="1"`.
   - Các khác biệt khác (thường: `v361` footer hai nút SCR-010 / 011, `v440` grouped surface, `v360` "Về danh sách" ở 011 / 012 / 013 khi không có nút) → gộp vào hàm dựng; chạy lại tới "không khác".
   - **Tải lại trang giữa các lần đo:** `ensureBj02ReviewFixture` và SCR-084 ghi vào `bj02Lines`, `lineEditorDraft`.
2. `ownedFlows.add("UIF-02")`.
3. Golden — khớp hoàn toàn.

## 5. Kiểm

| Kiểm | Cách | Đạt khi |
|---|---|---|
| Cú pháp | `node --check app/core.js app/bj02.js app/hub.js` | Không lỗi |
| Không còn mã cũ | `grep -n "bj02\|Bj02\|BJ02\|v392\|render0\(0[6-9]\|1[0-3]\|84\)\b\|lineEditor\|quickOverview" app/core.js` | Chỉ còn: `bj02-verify-unknown`, `bj02-handoff-unknown` (listener `v350`); `SCR-011/012/013` trong `v360ExitTargets`; `.bj02-key-value-row` trong selector của `v470` (A11); `FIGMA_TEMPLATE_BY_FLOW_SCREEN`, nhãn inspector, `entryMode` UIF-02 |
| Một định nghĩa | `grep -n "^\s*[A-Za-z0-9_]*\s*=\s*function" app/bj02.js` | Rỗng |
| Golden | `capture` + `compare` | **Khớp hoàn toàn** (`UIF-02_*_document`, `UIF-02_*_quick`, `SC_pending*`, `SC_quick_UIF-02`, kịch bản mới) |
| Lỗi JS | `_errors.json` | Rỗng |
| Hub | Bấm tay: Hub → "Nhận hàng chờ phê duyệt" → mở phiếu → Duyệt / Từ chối → quay về; Hub → nút nhanh "Nhận hàng" | Như trước |
| Bấm thử | Phiên review | 0 lỗi |

## 6. Kịch bản golden thêm (`tools/golden.mjs`)

Khối `// BJ-02 Nhận hàng mua (UIF-02) — T7-P A4`, `R = '?uif=UIF-02&screen='`. Dùng `click(sel, i)`, `back`, `typeIn`, `pick` (A3 thêm; nếu A3 chưa làm thì thêm `pick` ở đây). Bước đặt dữ liệu không có thao tác UI (chọn tệp) dùng biểu thức JS gán thẳng biến toàn cục rồi `renderAppScreen()` — biến vẫn toàn cục sau khi chuyển file.

```js
const setEvidence = `(()=>{bj02Header.evidenceRefs=[{id:'EV-T1',name:'phieu-giao.jpg',type:'DELIVERY_DOCUMENT'}];bj02Header.evidence='phieu-giao.jpg';bj02Header.ownershipAssertion=null;renderAppScreen();return true})()`;
```

| Tên | Bắt đầu | Bước |
|---|---|---|
| `SC_bj02_choose` | `R+'SCR-006'` | `[data-flow="document"]` → `back` → `[data-flow="quick"]` → `back` |
| `SC_bj02_documents` | `R+'SCR-007&flow=document'` | `typeIn('[data-bj02-document-search]','zzz')` → `typeIn('[data-bj02-document-search]','')` → `[data-bj02-document-id]` (thẻ đầu → SCR-009) → `back` |
| `SC_bj02_line` | `R+'SCR-007&flow=document'` | `[data-bj02-document-id]` → `[data-bj02-line-id]` (dòng đầu → SCR-084) → `[data-bj02-quantity-target]` (ô đầu, mở bàn phím số) → `[data-bj02-numeric-key="1"]` → `[data-bj02-numeric-key="2"]` → `[data-bj02-action="numeric-save"]` → `[data-bj02-action="save-line"]` (về SCR-009, toast) → `[data-bj02-line-id]` (dòng 2, `click(sel,1)`) → `[data-bj02-action="not-received"]` → `[data-bj02-action="confirm-not-received"]` |
| `SC_bj02_lot` | như trên | `[data-bj02-document-id]` → dòng có lô (`[data-bj02-line-id]`, chọn chỉ số theo fixture) → `[data-bj02-action="add-editor-lot"]` → `typeIn('[data-bj02-lot-field="code"]','DH2601')` → `pick('[data-v392-lot-precision="expiryPrecision"]','MONTH')` → `[data-bj02-action="show-manufacture-date"]` → `[data-bj02-action="toggle-lot"]` → `back` (lưu nháp, về SCR-009) |
| `SC_bj02_quick` | `R+'SCR-008&flow=quick'` | `[data-bj02-open-supplier-sheet]` → `[data-bj02-supplier-backdrop]` → `[data-bj02-open-supplier-sheet]` → `[data-bj02-supplier-option]` (đầu) → `setEvidence` → `[data-v392-quick-continue]` (SCR-009) → `back` (SCR-008) → `[data-bj02-open-supplier-sheet]` → `[data-bj02-supplier-option]` (thứ hai, `click(sel,1)` — đổi NCC xoá chứng từ, toast) |
| `SC_bj02_review` | `R+'SCR-010'` | `[data-bj02-review-line]` (đầu) → `[data-bj02-review-close]` → `[data-v392-change-source]` → `[data-v392-cancel-source-change]` → `[data-v392-change-source]` → `[data-v392-confirm-source-change]` |
| `SC_bj02_submit` | `R+'SCR-010'` | `[data-action="submit"]` (fixture không vượt → SCR-012 `PROCESSING`; chụp ngay, hẹn giờ 1,4 s chưa chạy) |
| `SC_bj02_approve` | `R+'SCR-011'` | `[data-v392-open-evidence]` → `[data-v392-preview-file]` (toast) → `[data-v392-close-evidence]` → `[data-action="open-reject"]` → `[data-action="close-reject"]` → `[data-action="open-reject"]` → `typeIn('[data-reject-reason]','Sai số lượng')` → `[data-action="confirm-reject"]` |
| `SC_bj02_approve_ok` | `R+'SCR-011'` | `[data-action="approve"]` (SCR-012 `PROCESSING`; không bước sau) |
| `SC_bj02_result` | `R+'SCR-012&state=COMPLETED'` | `[data-action="exit-flow"]` (về SCR-006) |
| `SC_bj02_unknown` | `R+'SCR-012&state=UNKNOWN'` | `[data-v350-action="bj02-verify-unknown"]` (SCR-013) → `[data-v350-action="bj02-handoff-unknown"]` (sang BJ-17) |
| `SC_bj02_recon_back` | `R+'SCR-013&state=TERMINAL'` | `back` (về SCR-012) |
| `SC_bj02_pending` | `R+'SCR-010&state=PENDING_APPROVAL'` | (chỉ chụp) |

Selector nào không khớp fixture (vd. chỉ số dòng có lô, `data-v392-lot-precision` tên thuộc tính) → chỉnh, ghi mục 9. Không thêm bước sau khi màn ở `PROCESSING` (hẹn giờ có thể chạy giữa hai lần chụp).

## 7. Bẫy

1. **Listener khung không kiểm luồng.** Listener click đầu tiên của `app.js` (`data-bj02-*`) và các khoá `data-action` của BJ-02 trong listener chung chạy cho **mọi** luồng. Khi thêm `if (activeFlowId !== "UIF-02") return;` phải chắc không BJ / Hub nào khác phát các thuộc tính đó (lệnh `grep` ở 4.3.7). Riêng `exit-approval`: `hub.js` bắt ở capture khi ở chế độ theme — giữ nguyên.
2. **`flowMode` ở khung, nhưng BJ-02 ghi vào** (`[data-flow]`, `exit-flow`, `bj02SeedDocumentLines`, `documentCard`). `let` cấp file trong `core.js`, script thường → `bj02.js` ghi được. Đừng khai báo lại trong `bj02.js`.
3. **`hub.js` gán `bj02Lines = …`, `bj02Header = …`** → hai biến phải là `let` (không `const`) trong `bj02.js`.
4. **Chuẩn hoá fixture `v392` là câu lệnh chạy ngay** — phải đứng sau `const`/`let` nó dùng (`documentReceiptCatalog`, `bj02Header`, `BJ02_CONTEXT`): lỗi TDZ nếu đặt trước.
5. **Gộp `.replaceAll` của 009 / 084** có thể đổi chữ ở màn khác dùng chung helper (4.2 bước 4). Golden chụp chữ (`.txt`) của mọi màn — khác ở 010 / 011 / 012 là dấu hiệu sửa nhầm helper.
6. **`bj02ReviewProductBlocks` gộp `v471`:** bản qua `div` tạm được trình duyệt chuẩn hoá HTML (dấu nháy, thẻ tự đóng). Dựng chuỗi thẳng có thể khác ở mức ký tự nhưng giống DOM; đoạn đo so `innerHTML` (đã chuẩn hoá) nên vẫn bắt được khác thật.
7. **`ensureBj02ReviewFixture` đọc `activeScreenId` / `stateByScreen`**, không đọc tham số `state` của hàm dựng — gọi ở đầu hàm dựng vẫn đúng vì `renderAppScreen` truyền `stateByScreen[activeScreenId]`. Đoạn đo đặt cả hai trước khi gọi.
8. **Hai bọc `render()` (`v360` banner, `v440` grouped surface)** vẫn chạy cho luồng đã sở hữu khi đi qua `render()` — đoạn đo không thấy chúng (so `renderFlowScreen` vs hàm dựng). Không gộp ở A4; golden bảo vệ.
9. **Cụm nhập nhanh đời đầu:** `quickProductCatalog` vẫn được `productById` dùng nên **không** thuộc cụm; với mọi tên khác cũng xoá theo `grep`, không theo danh sách.

## 8. Ghi lại và commit

1. `CHANGELOG.md`: mục `[5.1.x] — T7-P Giai đoạn 1, gói A4: BJ-02 viết lại sạch` (số kế tiếp sau bản mới nhất). Nội dung: mã chết đã xoá (2.4), 14 hàm gộp, lớp đã xoá (`v392`, `v466`–`v468`, `v471`, phần BJ-02 của `v350` / `v360` / `v460` / `v461` / legacy), kịch bản golden mới. `manifest.json` → cùng số.
2. Plan tổng mục 14: A4 Làm ✅. Mục 8.1 hàng A4: ghi "`addPendingReviewExit` để lại `hub.js` (A4 mục 2.5)".
3. `python3 tools/sync-registry.py`.
4. `detect_changes()`, commit: `refactor(prototype): T7-P A4 — BJ-02 clean code in app/bj02.js`.

## 9. Ghi chú khi làm

- Cho Giai đoạn 2 (brief BJ-02): chặn tự duyệt BJ-02 không chạy khi bấm (2.4); chữ "sản phẩm" / "mặt hàng" của SCR-009 nếu còn `.replaceAll`; lối "Về Kho" của màn chờ duyệt nằm ở `hub.js`.
- Đo 4.4 (pipe vs bare, tạm bỏ `ownedFlows`, bỏ qua `data-v470="1"`): khác `v440` trên `.v392-quantity-summary` (SCR-010) → gộp class/attrs; khác khoảng trắng class `is-emphasis` + `v470-kv--warning` → `bj02KeyValueRow` join class; khác `v361` dual footer nguy hiểm (SCR-011) → class + `data-ds-prop-tone` trên footer/nút Từ chối. Sau khi gộp: **không khác**.
- `updateBj02EditorLiveFeedback`: bản cũ đọc `saveButton` chưa khai báo (lỗi khi gõ ô lô — `SC_bj02_lot`); sửa thành `document.querySelector('[data-bj02-action="save-line"]')`.
- `addPendingReviewExit` để lại `hub.js` (mục 2.5).
- SCR-009 vẫn có `.replaceAll('sản phẩm','mặt hàng')` trong hàm dựng (chữ của v392) — brief Giai đoạn 2.

## 10. Review

(Phiên review điền sau khi bạn báo xong.)
