# Changelog — Theme 7 HTML Prototype

## [5.1.9] — T7-P Giai đoạn 1, gói A9: BJ-15 viết lại sạch

- BJ-15 (UIF-15: SCR-054…059) → `app/bj15.js`; helper `cfMoney`…`cfSecondary` và `ac310ProductRow` → `app/shared-control.js`.
- `ownedFlows` thêm `UIF-15`. SCR-056 đăng ký qua `flowRenderers` (UIF-15 + UIF-09).
- SCR-056 của BJ-09 khi không có `movement` tự dựng trong `bj09.js` (`render056BJ09History` / `bj09HistoryBase`); listener `v351-ic09-history-back`.
- Gỡ khỏi `core.js`: phần BJ-15 của `app.js` / `v310` / `v350`; **cả khối `v320`**, **`v351`**, **`legacy-sheet-cleanup`**; `render056IC09`; `ac310StateLabel`. Giữ: `v360RootScreens` / `v360ExitTargets`, `getCf15Rows` → `bj15Movements`, `AC310_SCREEN_IDS`, listener `fallback-exit`.
- Gộp sau dựng vào hàm dựng: sheet không nút "Đóng" + `t381-single-business-action`; 058/059 `PERMISSION_DENIED` footer "Về báo cáo"; 056/057 `backAction` v351; dấu trừ U+2212 trên key-value 056 (`bj15Minus`).
- Golden thêm kịch bản `SC_bj15_*` / `SC_bj09_history_back`.

## [5.1.8] — T7-P Giai đoạn 1, gói A8: BJ-11, BJ-12 viết lại sạch

- BJ-11 (UIF-11: SCR-048…053) → `app/bj11.js`; BJ-12 (UIF-12: SCR-066…071) → `app/bj12.js`; helper chung thêm vào `app/shared-control.js` (SectionTitle / KeyValue / List / Radio / Audit* / SummaryMetrics / Field / ApprovalFooter).
- `ownedFlows` thêm `UIF-11`, `UIF-12`. Fixture `IO-260904-021` nằm trong `cr11Operations` (bỏ splice lúc nạp của `v350`).
- **Sửa lỗi (chặng 0):** khôi phục listener Correction & Recovery (UIF-11/16/17, mất từ A5); trả `render()` runtime trong `crSwitchFlow` và hẹn giờ duyệt sửa sai (A7 xoá nhầm).
- **Sửa lỗi (chặng 5):** nút "Từ chối" trong sheet SCR-051 / SCR-070 — listener input chọn `data-v350-action` cuối; xử lý `cf12-confirm-reject` trước backdrop `close-reject`.
- Gỡ khỏi `core.js`: mã chết / `.replace` thuộc tính / toast `cr11`/`cf12` chết; listener UIF-12 (giữ UIF-15); phần UIF-11 của Correction & Recovery (giữ UIF-16/17 cho A10). Giữ: routing `entry`, `v360RootScreens` / `v360ExitTargets`, `cr16-correction-handoff`, `cfMoney`…`cfSecondary`, `v350EntryTargets` UIF-11/12.
- Golden: sửa `wait(ms)` trong `tools/golden.mjs` (§6.1); thêm kịch bản `SC_bj11_*` / `SC_bj12_*`.

## [5.1.7] — T7-P Giai đoạn 1, gói A7: BJ-08 viết lại sạch, shared-control.js

- BJ-08 (UIF-08: SCR-042…047) chuyển sang `app/bj08.js`; helper dùng chung cụm kiểm soát → `app/shared-control.js` (`ac310Tone` / `ac310CleanText` / `ac310SanitizeMarkup` / `ac310Return` / `ac310InfoSurface` / `ac310RecordRow`).
- `ownedFlows` thêm `UIF-08`. Bỏ mọi lời gọi `render()` lúc nạp trong `core.js` (hub.js dựng lần đầu).
- Gỡ khỏi `core.js`: mã chết BJ-08 (`render043…047` gốc, `v310`/`v320`/`v340`/`v350`/`v360` phần 042–047, cả khối `v3100`, `legacy-sheet-cleanup` nút `select-close`). Giữ: `v350EntryTargets` / `v350ApplyEntry` UIF-08, `v360RootScreens` / `v360ExitTargets`, `FIGMA_TEMPLATE_*`, `ac310BaseRenderers`.
- Gộp sau dựng vào hàm dựng: `v361` dual footer (044/045 hủy + duyệt), `v360` "Về danh sách" (046 không nút), `v470` attention + dấu trừ U+2212 trên "Chênh lệch", copy legacy UNKNOWN "Lần xử lý".
- Golden thêm 9 kịch bản `SC_bj08_*` (37 ca UIF-08 khớp hoàn toàn với mốc trước A7; SC mới + deep link cụm kiểm soát 0 lỗi JS).

## [5.1.6] — T7-P Giai đoạn 1, gói A6: BJ-07, BJ-09, BJ-10 viết lại sạch

- BJ-07 (UIF-07: SCR-036/037/039/041), BJ-09 (UIF-09: SCR-036/037/038/041/056), BJ-10 (UIF-10: SCR-036/037/040/041) chuyển sang `app/bj07.js`, `bj09.js`, `bj10.js`.
- Móc khung `flowRenderers` / `rendererFor` / `flowScreen`: màn dùng chung (036/037/041; 056) dựng theo luồng. `ownedFlows` thêm `UIF-07`, `UIF-09`, `UIF-10`.
- Gỡ khỏi `core.js`: khối `v395` / `v3101`; phần BJ-07/09/10 của `app.js` / `v350` / `v360` / `legacy-cross-theme-copy`; listener `io07` / `ic09` / `ic10` chết. Giữ: chuỗi SCR-056 BJ-15 (`v310`/`v320`/`v351`), `v350LockSourceForUnknown` UIF-07, `v350EntryTargets` / `v360RootScreens` / `v360ExitTargets`, `FIGMA_TEMPLATE_*`, `entryMode` return-task.
- Gộp sau dựng vào hàm dựng: `v360` fallback "Về danh sách" (038/040 không nút); `v350UnknownResult` cho SCR-041 UNKNOWN của BJ-10. SCR-056 BJ-09 không có `movement` tạm gọi chuỗi BJ-15 (A9 thay).
- Golden thêm 10 kịch bản `SC_bj07_*` / `SC_bj09_*` / `SC_bj10_*` (ca UIF-07/09/10 + UIF-15_SCR-056 + attention khớp hoàn toàn; 0 lỗi JS). Selector chỉnh: `SC_bj09_approve` seed `buildBasis()` vì `entry=approver` không có căn cứ sẵn.

## [5.1.5] — T7-P Giai đoạn 1, gói A5: cụm giá trị BJ-03 / 13 / 14 viết lại sạch

- BJ-03 (UIF-03: SCR-014/015/017/019), BJ-13 (UIF-13: SCR-085/086/089), BJ-14 (UIF-14: SCR-072/074/077) chuyển sang `app/bj03.js`, `bj13.js`, `bj14.js`; helper chung → `app/shared-valuation.js`.
- `ownedFlows` thêm `UIF-03`, `UIF-13`, `UIF-14`. Móc khung `screenAliases` trong `navigate` (đường cũ SCR-016/018/087/088/073/075/076); deep link giữ màn retired để alias chạy trước `hub.js` render.
- Hàm thắng: SCR-014/085 từ `v430`; còn lại từ `v461`. Giữ chuẩn hoá fixture / helper sống của `v397`–`v399` + `v313EntryType`. Expose `window.val13V398` / `__VET45_V399__` cho chỗ gọi còn lại.
- Gỡ khỏi `core.js`: khối `v313` / `v397`–`v399` / `v430` / `v431` / `v460` / `v461` (phần giá trị); listener `data-val*` chết. Giữ: `v350EntryTargets` UIF-14 dirty-scope, `v360RootScreens` / `v360ExitTargets`, `FIGMA_TEMPLATE_*`, `entryMode` receipt-task / source-task.
- Đo pipe vs bare trước `ownedFlows`: không khác (không cần gộp thêm `v440`/`v360`/`v470`). Dirty-scope: set `mode14=DIRTY_SETUP` lúc nạp trong `bj14.js`; `v350ApplyEntry` guard `typeof val14Runs`.
- Golden thêm 9 kịch bản `SC_bj03_*` / `SC_bj13_*` / `SC_bj14_*` (960 ca khớp hoàn toàn; 0 lỗi JS). Selector chỉnh: basis đủ currency/source/reason + ngày `dd/mm/yyyy`; BJ-13 bỏ pick method thứ hai (fixture chỉ 1 cách); retired SCR-018→UIF-13 SCR-085, SCR-088→SCR-086.

## [5.1.4] — T7-P Giai đoạn 1, gói A4: BJ-02 viết lại sạch

- BJ-02 (UIF-02: SCR-006…013, SCR-084) chuyển hết sang `app/bj02.js`: fixture, `BJ02_CONTEXT`, helper, hàm dựng, listener click/focus/change/input (pha capture + `data-action` bubble), `onPrevious["UIF-02"]`.
- `ownedFlows` thêm `UIF-02`. Gộp bước sửa sau dựng vào hàm dựng: `v440` grouped surface (SCR-010), `v361` dual footer nguy hiểm (SCR-011), `v470` tone "rủi ro" / dấu trừ (`bj02KeyValueRow`), badge SCR-012 `resultMode`, `ensureBj02ReviewFixture` ở đầu 084/010/011/012.
- Gỡ khỏi `core.js`: mã chết nhập nhanh đời đầu; cả khối `v392`, `v466`–`v468`, `v471`; phần BJ-02 của `v350` / `v360` / `v460` / `v461` / `legacy-sheet-cleanup` / `legacy-cross-theme-copy`; listener `data-bj02-*` / `data-flow` / `data-v392-*`. Giữ: `bj02-verify-unknown` / `bj02-handoff-unknown` (A10), `addPendingReviewExit` (hub), `flowMode` / `entryMode` UIF-02, `SCR-011/012/013` trong `v360ExitTargets`.
- Sửa lỗi sẵn: `updateBj02EditorLiveFeedback` dùng biến `saveButton` chưa khai báo → lấy nút `[data-bj02-action="save-line"]` từ DOM (kịch bản nhập lô).
- Golden thêm 13 kịch bản BJ-02 (`SC_bj02_*`): khớp hoàn toàn với bộ UIF-02; 0 lỗi JS.

## [5.1.3] — T7-P Giai đoạn 1, gói A3: CAP-01 viết lại sạch

- CAP-01 (SCR-062…065) chuyển hết sang `app/cap01.js`: trạng thái, helper, hàm dựng, listener input/change/click (pha capture), `capExit`, công cụ dev `__VET45_V360__.{capState,setCapReturn,capExit}`.
- `ownedFlows` thêm `CAP-01`. Dữ liệu khung vào literal `core.js`: `FIGMA_MIGRATED_FLOWS`, `FIGMA_TEMPLATE_BY_FLOW_SCREEN`, `FLOW_GROUPS` (Supporting capability), `figmaMigrationLabel`; xoá lớp bọc `renderFlowInspector` của `v360`.
- Gộp bước sửa sau dựng vào hàm dựng: `v440` grouped surface (`cap01InfoGroup`), `v361` dual footer (SCR-064), marker `data-v470` trên key-value (`cap01KeyValueRow`). Giữ: `fallback-exit`, `SCR-062/063` trong `v360RootScreens` (A11).
- Golden thêm 6 kịch bản CAP-01 (`SC_cap01_*`, helper `pick`): 843 ca khớp hoàn toàn; 0 lỗi JS.

## [5.1.2] — T7-P Giai đoạn 1, gói A2: BJ-06 viết lại sạch

- BJ-06 (UIF-06: SCR-030…035) chuyển hết sang `app/bj06.js`: fixture, chuẩn hoá semantic của `v394`, helper `io06*` (18 hàm lấy thân `v394`), hàm dựng, listener input/change/click (pha capture).
- `ownedFlows` thêm `UIF-06`. Móc khung mới `onPrevious` trong `previousScreen` — BJ-06 dùng cho SCR-031/032/033; các gói sau dùng lại thay nhánh trong `previousScreen`.
- Tiêu đề SCR-031 "Kiểm hàng khách trả" nằm thẳng trong `render031BJ06` (trước: `legacy-cross-theme-copy` + wrapper `v394`). Nút "Về danh sách" của SCR-034 `PERMISSION_DENIED` (trước do `v360` `ensureStableExitAffordance`) gộp vào hàm dựng. Timestamp ghi nhận / phân loại cố định theo ngày nghiệp vụ (golden ổn định).
- Gỡ khỏi `core.js`: cả khối `v394`; fixture / helper / hàm dựng / listener BJ-06 trong app.js; khởi tạo / wrapper `io06ReceiptReady` / navigate SCR-031 / listener `commit-receipt` / `v350Render034Base` / nhánh `io06-*` actor / mục SCR-035 trong `unknowns` của `v350`; 2 toast `io06` của `v360` (đang chết); khối đổi tiêu đề SCR-031 trong `legacy-cross-theme-copy`. Giữ: nhánh UIF-06 của `v350LockSourceForUnknown`, `bumpIO06Source`, `SCR-030/034/035` trong bảng `v360`.
- Mã chết đã xoá (không làm sống lại): chặn tự duyệt ngoại lệ lô và chặn ghi nhận khi `sourceVersion` đổi — ghi lại cho brief Giai đoạn 2.
- Golden thêm 10 kịch bản BJ-06 (`SC_bj06_*`): 816 ca khớp hoàn toàn; 0 lỗi JS.

## [5.1.1] — T7-P Giai đoạn 1, gói A1: BJ-04, BJ-05 viết lại sạch

- BJ-04 (UIF-04: SCR-021) chuyển hết sang `app/bj04.js` từ khối `v396` (fixture semantic, hàm dựng, toast "Quay về đơn bán"). Xoá `io04Fixture` / `render021IO04` gốc và cả khối `v396`.
- BJ-05 (UIF-05: SCR-025…029) chuyển hết sang `app/bj05.js`: fixture, helper `io05*`, hàm dựng, listener input/click, `data-io05-action`. Gộp kiểm `sourceVersion` của `v350` vào `io05ApplyHandover`; gộp nhánh UNKNOWN / COMMIT_UNKNOWN của `v393` vào `render029BJ05`; toast "Đã cập nhật lô lấy hàng" gọi ngay sau xác nhận đổi lô.
- `ownedFlows` thêm `UIF-04`, `UIF-05`. Móc khung mới `onScreenEnter` trong `navigate` (khoá `UIF-NN:SCR-NNN`) — BJ-05 dùng cho SCR-028 ghi `reviewSourceVersion`; các gói sau dùng lại thay wrapper `navigate`.
- Gỡ khỏi `core.js`: khối `v393`, `v396`; init / gán lại `io05VisibleOrders` / wrapper `io05ApplyHandover` / nhánh UIF-05 trong wrapper `navigate` / mục SCR-029 trong `unknowns` của `v350`; toast `confirm-lot-override` của `v360`; nhánh BJ-05 trong listener Inventory Operations chung (selector còn `[data-io06-action],[data-io07-action]`).
- Golden thêm kịch bản BJ-04 / BJ-05 (`SC_bj04`, `SC_bj05_*`, helper `typeIn`): 747 ca khớp hoàn toàn; 0 lỗi JS. Selector chỉnh so với plan: pick dùng `AL-21-02` + draft `10`; override mở editor trước rồi `DH2509`; handover kết thúc bằng `continue-remaining` (bàn giao một phần); waiting lọc WAITING rồi bấm đơn disabled (không đổi màn — chủ đích).

## [5.1.0] — T7-P bước A: BJ-01 viết lại sạch

- BJ-01 (UIF-01: SCR-001, SCR-003, SCR-004) chuyển hết sang `app/bj01.js`: fixture, trạng thái, hàm dựng, xử lý click / ô tìm / thoát ngữ cảnh sản phẩm. Không còn mã BJ-01 trong `app/core.js` (trừ `bj01Empty` mà BJ-08 legacy còn gọi).
- Cơ chế `ownedFlows` trong `core.js`: luồng đã viết lại dựng thẳng bằng `renderers[...]`, bỏ qua bước sửa sau dựng legacy. `UIF-01` là luồng đầu tiên.
- Badge tình trạng tồn (trước do `v470` tách sau khi dựng) nằm thẳng trong hàm dựng qua helper mới `ds24DotBadge` (class `ds24-badge--dot`, trước là `v470-stock-badge`); `v470` bỏ qua luồng đã viết lại. Bỏ `bj01LotBadge` không dùng.
- Toast "Đã cập nhật tồn kho" chuyển từ bảng toast của `v360` vào nút làm mới của BJ-01, hiện ngay sau khi vẽ lại (trước: hẹn giờ 30 ms).
- Golden thêm 7 kịch bản BJ-01 (31 bước): lọc, tìm, rỗng sau lọc, chi tiết, sheet lô, sheet nguồn → thẻ kho, làm mới khi dữ liệu cũ, vào từ ngữ cảnh sản phẩm, vào từ Hub. Kết quả: 714 ca khớp hoàn toàn; bộ bấm thử 0 lỗi JS.
- `tools/sync-registry.py`: đồng bộ registry `09.generated` sau mỗi lần sửa prototype.

## [5.0.0] — T7-P0 dọn prototype

Dọn mã nguồn: bỏ lớp vá không dùng, Hub Kho chỉ còn bản candidate, công cụ golden. Hình ảnh/hành vi giữ nguyên so với v4.7.0 (ngoại lệ: Hub cũ `hub=current` bị xoá).

### Changed
- Cấu trúc T7-P0: `styles/{tokens,components,screens}.css`, `harness/`, `app/core.js`, `app/hub.js`, `app/bj*.js` / `cap01.js` (đích viết lại từng BJ), `data/workbench-data.*`, `tools/golden.mjs`, một `CHANGELOG.md`.
- Home Kho chỉ còn candidate (SCR-090); bỏ tham số URL `hub` và nút "So sánh Hub Kho".
- `manifest.json` / `prototype.manifest.json` → `5.0.0`.

### Removed
- 18 file CSS/JS không được `index.html` nạp; thư mục `figma-ds-runtime/`; `qa/`; các `CHANGELOG-*.md` cũ (lịch sử còn trong git).
- Mọi `vNNN-*.css` / `vNNN-*.js` ở thư mục gốc (nội dung đã nối vào `styles/*` và `app/core.js`).
- `v472-hub-default.js` (không còn cần ép `hub=candidate`).

### Internal
- Viết lại từng BJ vào `app/bjNN.js` (một hàm dựng mỗi màn, gộp `v470` / `v471` của BJ đó): làm khi T7-P làm BJ đó (quyết định 2026-10-16).

### Khung chung (sau review T7-P0, 2026-10-16)

- **Một định nghĩa cho mỗi hàm khung.** `renderAppScreen` trước bị bọc 14 lớp, `renderInspector` 9 lớp; giờ là bộ điều phối trong `app/core.js`. Bước sửa sau dựng còn lại của từng BJ bọc `renderFlowScreen` / `renderFlowInspector` (legacy, xoá dần ở T7-P).
- **Hub Kho viết lại trong `app/hub.js` (`ThemeApp`).** Gộp phần còn dùng của v370 (chế độ theme, màn Thêm, vào / ra luồng, sidebar, inspector), v380 (mở thẳng màn kèm ngữ cảnh), v390 (khoá quay lại sau khi gửi duyệt), v464 (Hub candidate, phiếu chờ duyệt, "Về Kho"), v472 (chevron "Cần chú ý", thanh dưới). Xoá hẳn v370, v371, v380–v383, v464, v472 và phần Hub của v381, v390, v393, v396 cùng 77 luật CSS của Hub cũ. Một trình nghe click duy nhất thay cho 6.
- **Sửa hành vi (có chủ đích):** bấm phiếu chờ duyệt nạp dữ liệu phiếu trước khi mở SCR-011 và URL ghi đúng `screen=SCR-011` (trước: hiện dữ liệu cũ, URL `SCR-006`); HSD của phiếu ghi `31/08/2027` thay `2027-08-31`; "Về Kho" ở SCR-010 chờ duyệt về Hub sạch (trước: còn sót footer "Về Kho" che Hub, tiêu đề harness lệch); ở chế độ Theo BJ, quay lại từ SCR-011 không còn bị chặn.
- **Một bộ token.** Gộp 5 khối `:root` thành `styles/tokens.css`; thay 1 365 chỗ dùng `--v-*`, `--figma-*`, `--primary-*`, `--neutral-*`, `--blue-*`, `--yellow-*`, `--red-*`, `--shadow-*`, `--color-*` bằng `--vet45-v2-*`; bỏ 344 giá trị dự phòng; thêm token còn thiếu (`space-18`, `control-*`, `field-padding-*`, `font-sans/mono`, `neutral-150`, `primary-150`, `info-700`, `danger-700`, `shadow-1…3`). Sửa: `--primary-500`, `--blue-500`, `--yellow-500`, `--red-500` đã bị `:root` cũ trong components.css đè lại màu trước DESIGN.md, giờ theo DESIGN.md; 3 khai báo dùng biến không tồn tại (`.button--danger-text`, `.spinner`, focus ô nhập nhiều dòng) giờ trỏ token đúng.
- **Golden:** thêm 128 bước kịch bản thao tác Hub, ghi inspector + URL; ẩn mũi tên `<select>` khi chụp; luật nhiễu `MINBIG` (cần ≥ 4 điểm lệch mạnh); tự xoá profile Chrome sau khi chụp.

### Ghi nhận từ v4.7.0 (T7-P trước khi dọn)

**Colorize (`v470`):** token primary/warning/danger/info/chữ phụ theo DESIGN.md; key-value emphasis bỏ nền xanh; badge tình trạng tồn ở trailing; tone rủi ro / chênh lệch.

**Distill (`v471`):** lưới 2 cột thông tin lần nhận/yêu cầu; bỏ khối lặp ở SCR-010; dòng LOT hiện mã · số lượng · HSD; SCR-074 "Kết quả sau tính" thành tiêu đề khối tổng.

**Home candidate (`v472`):** Home Kho = candidate; chevron ở "Cần chú ý"; thanh dưới theo `LUONG-UNG-DUNG.md` (Trang chủ · Đơn hàng · Sản phẩm · Đối tác · Thêm).
