# Changelog — Theme 7 HTML Prototype

## [5.7.2] — R5: `/impeccable audit` chặng 1 (Hub, BJ-12, BJ-01, CAP-01)

Đo bằng Chrome headless ở cả hai khung (Hub cả `activation=pending`; 066 / 067 / 068 / 070 / 071 nhiều trạng thái; 001, 003 + sheet lô / nguồn / quét; 062 bảng + một sản phẩm + sheet lưu + chỉ xem; 063; 065): tương phản chữ ≥ 4,5:1 (chữ lớn ≥ 3:1) — **0 lỗi** (bộ đo đã thử với chữ #bbb → 1,8:1 bị bắt); vùng chạm iPhone — chip lọc BJ-01 cao 34px nhưng `::after` mở rộng 5px mỗi phía (= 44px), **đạt**; ô số / nút icon có nhãn; ô số bảng web có viền focus (`:focus-within`). Golden mobile 1440 ca / web 603 ca **khớp hoàn toàn** `tools/.golden-chang1*` (sửa chỉ đổi hành vi, không đổi hình); 0 lỗi JS. Mốc không cần chụp lại.

- **Focus hộp thoại (`core.js` `syncDialogFocus`, gọi cuối `renderAppScreen`):** sheet / hộp thoại `role="dialog"` mở thì focus vào hộp thoại (`tabindex="-1"`, không vòng focus — `components.css`); đóng (Esc, Huỷ, nền) thì focus về nút đã mở, nhớ bằng thuộc tính `data-*` của nút vì màn dựng lại. Áp cho mọi BJ dùng `renderAppScreen`.
- **Esc đóng sheet BJ-01** (`bj01.js`): sheet lô, nguồn, quét (BJ-12 / CAP-01 đã có).
- **Nhãn:** ô "Lý do từ chối" (`icTextarea`, `shared-control.js`) có `aria-label`; `ds24Sheet` (`core.js`) có `aria-label` = tiêu đề.
- **Không lỗi / ngoài phạm vi:** khung iPhone CAP-01 062 — nút "Lưu thay đổi (n)" của bảng ẩn (iPhone sửa bằng sheet từng dòng) nên không có ca trả focus về nút đó; BJ-02 sheet từ chối chèn DOM ngoài `renderAppScreen` → chưa có focus tự động (thiết kế lại ở chặng 2, plan BJ-02 mục 5.1 dùng `k2RejectSheet`).

## [5.7.1] — Sửa sau review chặng 1 (BJ-12, BJ-01, CAP-01)

Golden mobile / web so `tools/.golden-chang1*` (v5.7.0): khác có chủ đích — `HUB_home_not_activated`, `SC_hub_not_activated_*`, `SC_bj12_owner_0`, `SC_bj12_pending_list_*`, `SC_journey_1_*` (R2); `UIF-01_SCR-003_*`, `SC_bj01_*` qua chi tiết, `SC_entry_UIF-01_product-context_0`, `SC_entry_state_*` (R3); `SC_cap_single_*`, `SC_cap_mobile_sheet_1` (R1); `CAP-01_SCR-062/063_*`, `SC_cap_*` (chỉ xem, ô chọn, bảng căn giữa, hộp thoại web); `UIF-12_SCR-070_READY` và kịch bản qua 070 (`SC_bj12_approve/reject/self/stale`, `SC_entry_UIF-12_approver_0`). `UIF-06_SCR-033_READY@web` 47 điểm = nhiễu đã biết. 0 lỗi JS ở cả hai khung. Mốc `tools/.golden-chang1*` chụp lại.

- **R1 (`cap01.js`):** một sản phẩm / sheet sửa trên iPhone: hai ô trống thì "Lưu" tắt, không có dòng "Sau khi lưu" (trước: lưu thành ngưỡng 0 / 0).
- **R2 (`hub.js`):** Kho chưa kích hoạt: "Cần chú ý" bỏ nhận hàng chờ duyệt, lô sắp hết hạn, sai lệch, nghiệp vụ chưa rõ; chỉ còn "Chờ duyệt" của số dư đầu kỳ khi có, không có thì bỏ cả mục.
- **R3 (`bj01.js`):** SCR-003 sản phẩm đã có ngưỡng: dòng cuối thẻ số "Ngưỡng {n} · Mục tiêu {m} {ĐVT}" + "Sửa ngưỡng" (bỏ liên kết trong khối cảnh báo). Nhân viên (`staff`) không thấy "Đặt ngưỡng tồn" / "Sửa ngưỡng".
- **R4 (tài liệu):** link cũ SCR-069 / SCR-064 mở màn mới ở trạng thái mặc định — ghi rõ ở SCR-068, SCR-062, UIF-12.
- **Góp ý nhỏ:** CAP-01 chỉ xem trên iPhone dùng dòng trạng thái (không mũi tên); Esc đóng sheet CAP-01; bảng có ô sửa căn giữa theo ô nhập; hộp thoại giữa màn trên web (`k7-wide`) rộng 480px, bo bốn góc, không thanh kéo, không đáy thừa; ô chọn hành động 063 có mũi tên; 070 "Sau khi duyệt" dùng icon thông tin (`k2Decision` nhận tone thứ ba của dòng); `workbench-data` bỏ SCR-064 khỏi `screen_ids` của `ACT-12-CONFIGURE`; `screen-registry.md` SCR-064 → `RETIRED_v5.7.0`.

## [5.7.0] — T7-P CAP-01: thiết kế lại Chính sách tồn & cận hạn; hết chặng 1 (`SC_journey_1`)

Golden mobile so `tools/.golden-bj01-after`, web so `tools/.golden-bj01-web-after`. Khác có chủ đích: `CAP-01_*` (SCR-064 mất), `SC_cap_*` (thay `SC_cap01_*`), `SC_journey_1`, `SC_ws_inventory_2_2_item` / `SC_ws_setup_1_2_item` (mở CAP-01), `SC_bj12_owner_10_policy` (nút "Đặt ngưỡng tồn"), và ca BJ-01 SCR-003 của sản phẩm có nút mới — Oxytetracycline LA ("Đặt ngưỡng tồn") và Amox 500 / Enrofloxacin 10% / Tylosin 20% ("Sửa ngưỡng" trong khối cảnh báo): `SC_bj01_list_5`, `SC_bj01_out_1`, `SC_bj01_receive_1`, `SC_bj01_scan_2`, `SC_bj01_stale_2`, `SC_bj01_theme_2`, `SC_bj01_tylo_*`, `SC_bj01_expired_*`. Ca khác khớp mốc; 0 lỗi JS ở cả hai khung. Mốc mới (chặng 2): `tools/.golden-chang1`, `tools/.golden-chang1-web`.

- **SCR-062 (`cap01.js`, viết lại):** bảng sản phẩm sửa tại dòng (web): Sản phẩm · ĐVT · Khả dụng · Ngưỡng cảnh báo · Mức tồn mục tiêu · Chỉ báo (tính lại theo giá trị đang gõ), lọc "Tất cả / Chưa có ngưỡng", chấm dòng đã sửa, lỗi "Mục tiêu phải lớn hơn hoặc bằng ngưỡng." dưới ô, chân "Huỷ thay đổi" | "Lưu thay đổi (n)". Lưu bảng → sheet tác động ("Lưu n thay đổi?", đổi từng sản phẩm, "Tồn thấp: a → b sản phẩm") → toast "Đã lưu chính sách · Lần N", ở lại màn. iPhone: danh sách + sheet sửa hai ô, lưu thẳng. Một sản phẩm (vào từ BJ-01): tiêu đề = tên sản phẩm, phụ đề "Ngưỡng tồn", "Khả dụng …", "Sau khi lưu: …", "Lưu" → về SCR-003.
- **SCR-063:** "Mặc định cho mọi sản phẩm" (số ngày + hai thẻ lựa chọn "Cảnh báo" / "Chặn bán") và "Sản phẩm có chính sách riêng" (bảng web / thẻ iPhone: số ngày, hành động, "Dùng mặc định"; "Thêm sản phẩm" chỉ liệt kê sản phẩm theo lô). Thanh chọn "Ngưỡng tồn | Cận hạn" chung với 062; bỏ ô "Nguồn áp dụng" và khối "Phạm vi".
- **SCR-064 Rà soát:** bỏ — thành sheet tác động trong 062 (`screenAliases["CAP-01"]`, bỏ khỏi `workbench-data`). **SCR-065:** chỉ còn `UNKNOWN` (K3) / `REJECTED_EXECUTION` (K4) / `PERMISSION_DENIED` (K1); `COMPLETED` (đường cũ) mở 062 + toast.
- **Quyền:** `is_owner` / `store_owner` sửa; `entry=staff` (`entryTargets["CAP-01"].staff`) chỉ xem — banner K1 "Chỉ chủ cửa hàng thay đổi được chính sách.", ô khoá, không chân. Không có luồng duyệt.
- **Thành phần dùng chung (`shared-patterns.js`, `components.css`):** `k7EditCell` (ô số có hậu tố đơn vị, lỗi dưới ô, `aria-label`), `dsSegmented` (`.ds-segmented`, chép giá trị `.cf-segmented` của BJ-15 — chưa sửa BJ-15), `dsChoiceRow` (`.ds-choice-row` / `.ds-radio`, chép từ `io06SelectionRow` của BJ-06 — chưa sửa BJ-06); `k4Footer` nhận `disabled` cho từng nút.
- **Nối BJ:** BJ-01 SCR-003 — sản phẩm chưa có ngưỡng: nút "Đặt ngưỡng tồn" (`data-bj01-set-threshold` → `capOpenForProduct`); sản phẩm Tồn thấp / Hết hàng: liên kết "Sửa ngưỡng" trong khối cảnh báo. BJ-12 SCR-071 "Đặt ngưỡng tồn" → `capOpenForTable("UIF-12", "SCR-071")`. Ngưỡng ghi thẳng vào `bj01Products` (BJ-01 chỉ đọc giá trị mới; số tồn không đổi).
- **Chữ mới ngoài plan (cần vào T7-P mục 13):** "Bình thường" (badge chỉ báo khi không có cảnh báo), "Số ngày cận hạn phải lớn hơn 0.", "Không còn sản phẩm nào chưa có ngưỡng" / "Mọi sản phẩm đã có ngưỡng cảnh báo." / "Xem tất cả" (lọc rỗng), "Chưa có sản phẩm nào có chính sách riêng.", "Mọi sản phẩm theo lô đều đã có chính sách riêng.", "Thêm sản phẩm" (sheet).
- **Không làm:** tính lại chỉ báo cận hạn của lô khi đổi số ngày (fixture lô BJ-01 giữ nguyên).
- **Golden:** thay `SC_cap01_*` bằng `SC_cap_table`, `SC_cap_mobile_sheet`, `SC_cap_single`, `SC_cap_expiry`, `SC_cap_staff`, `SC_cap_locked`, `SC_cap_conflict`, `SC_cap_unknown`, `SC_cap_rejected`, `SC_cap_hub`; thêm `SC_journey_1`; `WEB_SCENARIOS` (`SC_journey_1`, `SC_cap_table`, `SC_cap_expiry`, `SC_cap_single`, `SC_cap_staff`, `SC_cap_hub`) chạy được ở `DEVICE=web`.
- Badge harness `v5.7.0 · CAP-01 thiết kế lại · hết chặng 1`.

## [5.6.0] — T7-P BJ-01: thiết kế lại Tồn kho & khả dụng

Golden mobile so `tools/.golden-bj01-base` (khớp hoàn toàn `.golden-bj12-after`), web so `.golden-bj01-web-base` (khớp `.golden-bj12-web-after` trừ 2 ca nhiễu 47 / 33 điểm ảnh ở `UIF-06_SCR-033_READY@web`, `UIF-07_SCR-037_EXPIRED@web`). Khác có chủ đích: `UIF-01_*`, `SC_bj01_*`, `SC_search_*`, `SC_quick_UIF-01_*`, `SC_entry_*` (UIF-01), các ca đi qua SCR-001 (`SC_ws_inventory_0_*`, `SC_cap01_*`, `SC_bj12_*` kết thúc ở Tồn kho) và `UIF-09_SCR-036_*` (+ các kịch bản dừng ở SCR-036: dòng Tylosin thêm vào BJ-09). 0 lỗi JS.

- **SCR-001 (`bj01.js`):** ô tìm có nút quét mã vạch (sheet "Quét mã vạch" mô phỏng); chip lọc kèm số (số 0 mờ); ở "Tất cả" sắp theo mức gấp Hết hàng → hết hạn → Tồn thấp → cận hạn → bình thường → chưa có ngưỡng; dòng sản phẩm = `VStockRow` (tên, mã, số khả dụng mono + badge).
- **SCR-003:** tiêu đề = tên sản phẩm, phụ đề `{mã} · {ĐVT}`; bỏ thẻ sản phẩm riêng; một thẻ số chính (`bj01StockHero`); cảnh báo ngay dưới kèm "Gợi ý nhập thêm … (mục tiêu …)" + "Nhận hàng" (→ BJ-02 nhập nhanh) và banner "Có lô hết hạn" + "Xử lý lô hết hạn" (→ BJ-09 lọc đúng lô; sheet lô cũng có nút); lô sắp theo HSD gần nhất.
- **Trạng thái:** dùng K1 của BJ-12 (`k1Loading` khung xương đúng bố cục, `k1Stale` + "Làm mới", `k1Denied` + "Về Kho"; không có dữ liệu sản phẩm trong DOM khi không có quyền).
- **Thành phần dùng chung (`core.js`):** `VStockRow` (`ds24StockRow`), `ds24Chip(…, count)`, `ds24Search(…, trailingAction)`, icon `scan`.
- **BJ-09 (`bj09.js`):** fixture thêm lô TY2408 Tylosin 20% (hết hạn) để "Xử lý lô hết hạn" có đích.
- **CSS:** khối thành phần mới ở cuối `components.css`, khối "BJ-01 Tồn kho" ở cuối `screens.css`; xoá luật cũ không còn khớp phần tử nào (`.bj01-product-row`, `.bj01-list-empty`, `.bj01-eligibility-reasons`, `.ds24-key-value-row--emphasis` của UIF-01).
- **Golden:** thêm `SC_bj01_scan`, `SC_bj01_scan_close`, `SC_bj01_receive`, `SC_bj01_out`, `SC_bj01_expired`, `SC_bj01_expired_sheet`, `SC_bj01_denied`, `SC_bj01_barcode_type`.
- Badge harness `v5.6.0 · BJ-01 thiết kế lại`.

## [5.5.0] — T7-P BJ-12: thiết kế lại khởi tạo tồn đầu kỳ; dựng khuôn K1–K4, K7

Golden mobile so `tools/.golden-bj12-base` (khớp hoàn toàn `.golden-phase1`), web so `.golden-bj12-web-base` (khớp hoàn toàn `.golden-web-base`): chỉ khác ở `UIF-12_*`, `SC_bj12_*`, `SC_entry_UIF-12_*`, `HUB_home`, các kịch bản đi qua Home Kho (dòng "Chờ duyệt"), `SC_entry_state_12`; 0 lỗi JS. Mốc sau: `tools/.golden-bj12-after` (1376 ca), `tools/.golden-bj12-web-after` (551 ca).

- **K1–K4, K7 (`app/shared-patterns.js`, mới):** `k1Loading` / `k1Denied` / `k1Stale` / `k1Locked` / `k1Empty` / `k1ExitAttr`; `k2Pending` / `k2Decision` / `k2RejectSheet` / `k2SelfCommitSheet`; `k3Unknown`; `k4Result` (+ `k4Footer`); `k7Split` / `k7Table` / `k7FilterChips`. CSS khối "Khuôn K1–K4, K7" cuối `components.css`: lớp `k7-wide` (màn thoát cột iPhone 402px, tối đa 1120px), bảng chỉ hiện ở khung web, danh sách thẻ chỉ ở khung mobile.
- **Khung:** `appShell({ extraClass })`; `entryTargets["UIF-12"].owner`; `cfField(…, error)` (ô lỗi: viền + dòng lỗi dưới ô, mặc định rỗng).
- **Home Kho (`hub.js`):** `?activation=pending` / `ThemeApp.setActivated()` — Kho chưa kích hoạt hiện khối "Kho chưa kích hoạt" + "Khởi tạo tồn kho", 4 nút nhanh tắt. "Nhận hàng chờ phê duyệt" → "Chờ duyệt": nguồn đăng ký qua `window.__T7_PENDING_SOURCES__` (`{ id, label, rows() }`), dòng phụ "3 nhận hàng · 1 số dư đầu kỳ"; lối vào thêm `data-theme-entry-actor` (đặt vai khi vào luồng; mặc định về `module`).
- **BJ-12 (`bj12.js`):** SCR-069 gộp vào SCR-068 (`screenAliases`; bỏ khỏi `workbench-data`). 066: "Cần chuẩn bị" + "Tải tệp mẫu", lý do từ chối, chờ duyệt (K2), kết quả (K4 / K3). 067: hai cột web (vùng kéo thả + cột cần có), sheet "Xem các cột cần có" trên iPhone, ô tiền có phân cách nghìn, lỗi tại ô. 068: dải số, bảng lỗi có "Cách sửa", đối chiếu Theo tệp · Theo sổ · Chênh lệch (fixture lệch thật 4.830 / 4.820), khi đạt có "Số dư sẽ ghi nhận" + bảng dòng lọc được; chủ cửa hàng "Ghi nhận số dư đầu kỳ" → sheet → ghi nhận ngay (tự duyệt), nhân viên "Gửi phê duyệt". 070: "Cần quyết" (câu hỏi, người gửi, cần chú ý, số liệu) + bảng dòng; từ chối bằng sheet có lý do. 071: tóm tắt có "Người duyệt", "Đặt ngưỡng tồn" → CAP-01, `setActivated(true)`. Esc đóng sheet.
- **Golden:** bỏ bước `review`; thêm `SC_bj12_owner`, `SC_bj12_template`, `SC_hub_not_activated`, `SC_bj12_pending_list`, `SC_entry_UIF-12_owner`, nhóm `HUB_home_not_activated`.
- Badge harness `v5.5.0 · BJ-12 thiết kế lại`.

## [5.4.0] — T7-P H1: harness khung web 1280×800

Không đổi màn nào: golden mobile khớp hoàn toàn `tools/.golden-phase1` (1348 ca), 0 lỗi JS.

- **H1 — dọn `is-wide`:** xoá mọi luật `.device-preview.is-wide …` (`components.css`, kể cả trong `@media`); 6 luật `:not(.is-wide)` → `.device-preview.is-mobile`. `viewport=wide` trên URL nay rơi về mobile; giá trị mới là `viewport=web`.
- **H2 — nút và khai báo:** nút "Web · 1280 × 800" cạnh "Mobile · 402 × 874"; `__VET45_PROTOTYPE__.productKind: "app"`, `devicePresets` thêm `web-1280`.
- **H3 — khung web:** `.device-preview.is-web` 1280×800, viền 1px, lưới 240px + nội dung; không thanh trạng thái iOS, không thanh dưới. Màn Hub / Thêm rộng tới 1120px; màn BJ chưa thiết kế lại cho web giữ cột iPhone 402px ở giữa vùng nội dung, cao theo khung. Sân khấu hẹp hơn 1280px thì khung thu quanh giữa.
- **H4 — thanh bên giả:** `#web-sidebar` (`hub.js` `webSidebar()` / `renderWebSidebar()`, gọi từ `render()`): tên tổ chức, 5 mục chính (chỉ "Thêm" bật), mục con "Kho" (đang chọn, về Home Kho) / "Giá riêng / Nhớ giá" / "Người dùng & vai trò" / "Tài khoản của tôi" / "Thiết lập" (tắt), "Đăng xuất" (tắt). Tên tổ chức là fixture `ORG_NAME` ("VET45 Demo") vì Hub chưa có tên tổ chức.
- **H5 — thu khung:** `fitReviewDeviceToViewport()` có công thức cho khung web (`min(1, cao / 802, rộng / 1282)`); đổi khung gọi lại ngay.
- **H6 — golden hai khung:** `DEVICE=web node tools/golden.mjs capture <dir>` — cửa sổ 2400×1300, URL thêm `viewport=web`, tên ca thêm `@web`, chỉ nhóm màn × trạng thái + `HUB_home` (555 ca), bỏ kịch bản `SC_*`. Mốc web: `tools/.golden-web-base`.
- Badge harness `v5.4.0 · H1 khung web`.

## [5.3.1] — T7-P A12: sửa sau review Giai đoạn 1 — hết Giai đoạn 1

- **R1 (lỗi A11):** trả lại CSS mất khi tách harness — khối "Review cards" (`.review-card-header strong` 14px, `.review-card-header` / `-body`, `.review-line`) vào `components.css` đúng vị trí cũ; thứ tự luật `.device-preview` như `styles.css` gốc (bo góc 34px, khung chuẩn 402×874) và xoá bản sao bo 32px trong `screens.css`. Tiêu đề thẻ UIF-11/12/15/16, kết quả SCR-089 và 4 góc khung trở lại như trước Giai đoạn 1.
- **R2 (lỗi A8):** `ac310ApprovalFooter` viết sẵn dual footer nguy hiểm của `v361` (`v361-dual-footer--danger`, nút "Từ chối" tone danger) — SCR-051 / SCR-070 lại có "Từ chối" | "Duyệt" trên một hàng; `bj11KeyValueSurface` dựng dòng nhấn mạnh bằng `ds24KeyValueRow(…, true)` — "Điều chỉnh" trên SCR-050 / 051 lại đậm như trước A8. Khớp mốc trước Giai đoạn 1.
- **R3 (A5, A6):** mỗi hàm một định nghĩa — xoá 37 bản chết bị gán đè trong `bj03.js` (15), `bj07.js` (7), `bj13.js` (10), `bj14.js` (5), khai báo `let` ở cấp file; `val14CreateRun` gộp `bj14ApplyPolicy` (bỏ bọc `baseCreate14`); bỏ export thừa `window.val03ApplySourceUpdate` / `val13ApplySourceUpdate` / `val13V398`. Golden khớp hoàn toàn.
- **R7 (A5):** cụm giá trị tách đúng theo BJ — `bj03.js` dựng SCR-014…019, `bj13.js` SCR-085…089, `bj14.js` SCR-072…077 (trước: `bj03.js` dựng cả SCR-085, `bj14.js` dựng cả SCR-015/017/019/086/089). Helper giao diện `VAL_UI_430` / `VAL_UI_461` → `shared-valuation.js`. Xoá listener chết `data-v430-val14-*`; gộp 10 định nghĩa trùng dạng bí danh (`val03Calc`…, `val13Preview`…) và `val03Commit` bản `v397`. Golden khớp hoàn toàn.
- **R4:** dọn chú thích lỗi thời (`/* ===== app.js ===== */`, `// v1.7.0` / `v1.8.0` / `v2.7.1`, câu cụt đầu `bj01` / `bj04`, `simplifyNormalBanners`); `bj10.js` bỏ lớp chuyển tiếp `render036/037BJ10`.
- **R5:** `tools/golden.mjs` chỉ dùng `__VET45_QA__`; mốc mới `tools/.golden-phase1` (1348 ca, 0 lỗi JS) — **0 khác biệt** với mọi mốc trước Giai đoạn 1 còn lưu (`.golden-a5-base` 960 ca, `.golden-base` 911, `.golden-a10` 186, `.golden-a8-check` 110); xoá 32 thư mục mốc tạm; `tools/.gitignore` thêm `.full*/`, `.usage*/`.
- Badge harness `v5.3.1 · T7-P A12 hết Giai đoạn 1`.

## [5.3.0] — T7-P Giai đoạn 1, gói A11: dọn khung `core.js`, tách harness, dọn CSS không dùng

- `core.js` chỉ còn khung: `entryTargets` / `applyEntry` / `onEntry` / `currentActor`, `renderAppScreen` / `render` / `navigate`, helper DS, toast, lối ra dự phòng, bước dựng chung (`applyGroupedSurfaceRule` + MutationObserver; `simplifyNormalBanners` đã gộp vào `vBanner` ở bj08 / bj10, không còn trong khung). Xoá lớp vá `v35x`/`v36x`/`v4xx`, `ownedFlows` / `renderFlowScreen`.
- API QA gộp thành `window.__VET45_QA__` (BJ/`cap01` chỉ `Object.assign`); `tools/golden.mjs` đọc `__VET45_QA__` (giữ fallback tên cũ đến hết A11).
- Harness → `harness/workbench.js` + `harness/figma-ds-map.js` + `harness/workbench.css` (chrome sidebar/inspector/inspect/stage; khung `.device-preview` size + luật trộn giữ trong `styles/*` để cascade với v281). `index.html`: nạp harness ngay sau `core.js`; stylesheet `components` → `workbench` → `screens`.
- Helper chéo: `ds24EmptyState` trong khung; `icCard`…`icApprovalButtons` một bản ở `shared-control.js`.
- Banner ngữ cảnh: truyền `extraClass` `"v360-context-banner"` vào `vBanner` (bj08/bj10) — ca đi qua `renderAppScreen()` nay có lớp (khác biệt có chủ đích, đã ghi lúc chặng 2).
- CSS: xoá 1254 luật không dùng (gate usage + không còn tên trong mã) — `components.css` 6092→3243 dòng, `screens.css` 9414→7264. Không bỏ `!important`, không gom theo BJ.
- Badge harness `v5.3.0 · T7-P A11 framework`. *(Review 2026-10-19: chặng 5 làm mất CSS và mốc golden bị chụp lại — sửa ở 5.3.1 R1.)*

## [5.2.0] — T7-P Giai đoạn 1, gói A10: BJ-16, BJ-17 viết lại sạch; mọi luồng đã sở hữu

- BJ-16 (UIF-16: SCR-078…083) → `app/bj16.js`; BJ-17 (UIF-17: SCR-078/079/080/082/083) → `app/bj17.js`; helper chung `crFactCard` / `ac321CanonicalChips` → `app/shared-control.js`.
- `ownedFlows` thêm `UIF-16`, `UIF-17` — **mọi luồng đã sở hữu**.
- Cơ chế K3: `bj17HandoffUnknown` / `bj17RecoveryCase` ở `bj17.js`; móc `onUnknownHandoff` (bj05/06/07 đăng ký); `bj02-verify-unknown` / `bj02-handoff-unknown` → `bj02.js`.
- Gỡ khỏi `core.js`: phần BJ-16/17 của Correction Recovery / `v350`; **cả khối `v310`** (`ac310Base` / `AC310_SCREEN_IDS`); **cả khối chữ sau dựng UIF-17**; listener UIF-16/17. Giữ: `crSwitchFlow`, routing `entry`, `v350DeclaredStates` / `v350EntryTargets` / `__VET45_V350__`, `v360` / `v361` / `v440` / `v470` (A11).
- Gộp vào hàm dựng: thuộc tính `data-v350-action` cuối; chữ "Lần xử lý"; footer "Về danh sách" 083 `PERMISSION_DENIED`.
- Golden thêm kịch bản `SC_bj16_*` / `SC_bj17_*`.

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
