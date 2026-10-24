# Changelog — Theme 7 HTML Prototype

## [5.12.2] — Góp ý nhỏ của review chặng 3

Golden mobile so `tools/.golden-chang3` (v5.12.1, 1708 ca → 1708), web so `tools/.golden-chang3-web` (844 → 844). 0 lỗi JS. Khác có chủ đích: mobile chỉ ca 028 (`UIF-05_SCR-028_*`, bước 028 của `SC_bj05_*`, `SC_bj04_after_handover_1`, `SC_journey_3_6`); web chỉ ca có khối "Tóm tắt" hoặc 031 / 032 của UIF-04 / 05 / 06 (`UIF-04_SCR-021_READY`, `UIF-05_SCR-026_*`, `UIF-05_SCR-028_*`, `UIF-06_SCR-031_READY`, `UIF-06_SCR-032_*`, các bước tương ứng của `SC_bj0[456]_*`, `SC_journey_3`). Mốc `tools/.golden-chang3*` chụp lại.

- **Web 031 / 032:** thanh "Xong" / "Lưu ngoại lệ" của cột phải dính đáy vùng cuộn (`position: sticky`), thấy ngay ở 1280 × 800.
- **Khối "Tóm tắt" web:** giá trị chữ ("Đại lý An Phú", "Kho chính") dùng Inter thay mono — luật khung Figma của UIF-01/02/04/05/08 ép mono bằng `!important`, luật K7 đè cùng loại.
- **`k4ReasonFooter`:** lớp / nhãn dùng chung đổi tên `bj02-footer-stack` → `k4-reason-footer`, `bj02-footer-reason` → `k4-reason-footer__reason`, `data-bj02-reason` → `data-k4-reason` (BJ-02 / BJ-05 / BJ-06; HTML khác tên lớp, ảnh không đổi).
- **`k6TaskList`:** ghi chú vì sao dòng iPhone truyền `rowAttr` (không `attrOf`) — `ds24ListRow({ disabled })` đã tự gắn `aria-disabled`; không đổi mã.
- **Audit dọc `SC_journey_3`** (Chrome không giao diện, 29 bước gồm 021 ↔ 026 quay lại, sheet từ chối, về Home bằng thanh bên / nút quay lại; cả hai khung): tương phản chữ, vùng chạm iPhone ≥ 44 × 44, tên nút, `alt` ảnh, tràn ngang. Lỗi tìm được và đã sửa: **028 iPhone** — dòng sản phẩm trong thẻ bị luật khung Figma ép 370px + đệm 16px nên tràn 17px, dòng "Giao lần này" thụt 12px khác dòng dưới. Sau sửa: 0 lỗi ở cả hai khung, 0 lỗi JS.
- Badge harness `v5.12.2 · góp ý review chặng 3`.

## [5.12.1] — Review chặng 3 (R1–R3)

Golden mobile so `tools/.golden-chang3` (1708 ca → 1708), web so `tools/.golden-chang3-web` (844 → 844). 0 lỗi JS. Khác có chủ đích: ca có 026 iPhone (`UIF-05_SCR-026_*`, `SC_bj05_*`, `SC_bj04_from_pick`, `SC_entry_UIF-05_order-task`, `SC_journey_3`), ca có 031 iPhone (`UIF-06_SCR-031_*`, `SC_bj06_*`, `SC_entry_UIF-06_return-task`, `SC_journey_3`), 029 / 035 `UNKNOWN` (cả hai khung, kèm `SC_bj05_unknown`, `SC_bj06_unknown`, `SC_bj17_from_bj05_0`). Mốc `tools/.golden-chang3*` chụp lại.

- **R1 — 026 iPhone:** dòng lô lấy một phần (badge "Đã lấy một phần" + "Lấy đủ") không còn tràn thẻ: luật khung Figma ép hàng Default 76px (`!important`) được đè trong `.bj05-lot` (cao theo nội dung, đệm dọc 8px).
- **R2 — 031 iPhone:** "được nhận {n} {ĐVT}" nối số và ĐVT bằng khoảng trắng không ngắt (hết gãy "3 / hộp").
- **R3 — K3 ở 029 / 035:** bỏ câu `safe` riêng của BJ-05 / BJ-06 (lặp "Không gửi lại thao tác." của khuôn K3).
- Badge harness `v5.12.1 · review chặng 3`.

## [5.12.0] — BJ-06 thiết kế lại; hết chặng 3 (SC_journey_3)

Golden mobile so mốc chụp lại ở HEAD trước BJ-06 (1708 ca → 1708; `tools/.golden-bj05-after` đã cũ: nhãn inspector đổi sau khi chụp), web so mốc web cùng cách (844 → 844). 0 lỗi JS ở cả hai khung. Khác có chủ đích: `UIF-06_*`, `SC_bj06_*`, `SC_entry_UIF-06_*`, `SC_journey_3` (mới), `SC_ws_movement_2_2_item` (mở 030 từ Hub) và **chỉ dòng "Chờ duyệt" của Home Kho** ở mọi ca có Home đã kích hoạt: "3 nhận hàng" → "3 nhận hàng · 1 ngoại lệ lô hàng trả", số 3 → 4 (`diff` thân `.txt` khác đúng dòng đó; danh sách "Chờ duyệt" thêm một dòng "Nobivac DHPPi · Lô DH2509"). Kho chưa kích hoạt không hiện dòng này (nguồn `needsActivation`). `SC_bj17_from_*`, ca BJ-04 / 05 khớp. Mốc mới cho chặng 4: `tools/.golden-chang3`, `tools/.golden-chang3-web`.

- **SCR-030 (K6):** chip có số "Tất cả" · "Cần xử lý" · "Đang chờ"; dòng "{khách} · {đơn bán}" + badge bước đang dở; web bảng Yêu cầu · Khách hàng · Đơn bán · Mặt hàng · Tình trạng. Mở đúng bước ("Cần phân loại" → 033, còn lại → 031). **Dòng "Chờ duyệt lô" mở được** (031 chỉ đọc). `EMPTY` / `FILTER_EMPTY` / `LOADING` / `PERMISSION_DENIED` dựng thật (K1).
- **SCR-031 + SCR-032:** "Bước 1/2 · Nhận hàng" + thanh tiến độ "Đã kiểm {a}/{b} dòng"; dòng "Lô giao {lô} · được nhận {n} {ĐVT}". **Web là một trang hai cột** (`k7Split`: bảng Sản phẩm · Lô giao · Được nhận · Thực nhận · Lô thực nhận · Tình trạng | chi tiết dòng đang chọn); "Xong" lưu rồi chọn dòng chưa kiểm kế tiếp, không đổi trang; `render032BJ06` ở khung web dựng như 031. Chi tiết dòng: nút "Nhận đủ {n} {ĐVT}", lô thực nhận **không chọn sẵn** (`dsChoiceRow`), "Lô khác" → mã lô, lý do, ảnh nhãn lô ("Chụp ảnh" | "Chọn tệp" iPhone, "Kéo tệp vào đây hoặc Chọn tệp" web, xem trước có `alt`). Chân `k4ReasonFooter` có dòng lý do khi tắt. Trạng thái `WAITING_APPROVAL` (`k2Pending`), `RETURN_CAP_CHANGED` / `SOURCE_CHANGED` / `CONFLICT` (`k1Stale`), `LOCKED` (`k1Locked`) khác nhau.
- **SCR-034 (K2):** lối vào chính là Home **"Chờ duyệt"** (nguồn `UIF-06` "ngoại lệ lô hàng trả" trong `__T7_PENDING_SOURCES__`, mở thẳng đúng ca qua `__T7_DIRECT_CONTEXTS__["bj06-approval"]`); `TASK_LIST` (K6) chỉ còn cho `?entry=approver`. Quyết định `k2Decision` + `k2RejectSheet`; duyệt / từ chối xong là K4 "Đã duyệt ngoại lệ" / "Đã từ chối ngoại lệ"; "Về danh sách phê duyệt" về Home "Chờ duyệt" (chế độ Toàn Theme 7) hoặc `TASK_LIST` (chế độ BJ). Người duyệt = `approver` / `owner`; vai khác → "Không thể tự duyệt".
- **SCR-033:** "Bước 2/2 · Phân loại"; iPhone mỗi dòng mở sheet bốn lựa chọn "Bán được" / "Cách ly" / "Hỏng" (= cả dòng, lưu ngay) + "Chia nhiều loại" (ba ô số, "Xong"); web bảng với `dsSegmented` + `k7EditCell` (chỉ sửa được khi "Chia"). Lô hết hạn: dòng chỉ đọc "Hết hạn · hệ thống xác định" (sheet "Lô đã hết hạn" ở iPhone). Lượng chưa nhập (`null`) không còn tính là đã phân loại.
- **SCR-035 (K4 / K3):** "Đã nhận hàng khách trả" (Yêu cầu trả · Đơn bán · "Ghi nhận lúc" điền thật · "Người nhận"), "Đã phân loại hàng trả" (mỗi loại > 0 một dòng; "Hàng cách ly / hỏng chờ xử lý ở Hàng cần xử lý."; "Xem tồn kho" → BJ-01); sheet "Xem {n} dòng hàng"; `UNKNOWN` = `k3Unknown`.
- **Fixture:** HSD lô DH2507 "2026-11-30" (khớp BJ-02 / BJ-05); thời điểm hiển thị cố định `bj06IsoNow()` ("16/09/2026 15:00"); người nhận "Nguyễn Văn An" (như BJ-05); `RET-260827-05` mở thẳng 033 / 035 là yêu cầu đã nhận; `EXPIRED_GUARD` dựng bằng lô DH2408 hết hạn (không còn ép dòng đang mở thành hết hạn theo trạng thái). `io06Seed`: trạng thái đặt từ bộ kiểm dựng lại fixture từ bản gốc rồi chuẩn bị đúng yêu cầu (hết trùng ảnh 031 `CONFLICT` = `LOCKED`, 032 / 033 `VALIDATION_ERROR` = `READY`, 034 `TASK_LIST` = `READY` …).
- **Hub:** `openDirect` đọc móc `window.__T7_DIRECT_CONTEXTS__` (tiền tố trước dấu `:` của `data-t380-context`; không có móc thì nhánh BJ-02 như cũ); nút gắn `data-theme-exit-to-pending` về danh sách "Chờ duyệt"; nguồn "Chờ duyệt" có thể gắn `needsActivation`.
- **QA:** `window.__VET45_QA__.setIO06Evidence(lineId)` đặt ảnh nhãn lô mẫu.
- **Dọn mã:** bỏ `deniedBody` / `loadingBody` / `ioResult` / `io06SelectionRow` / `io06TextField` / `io06Textarea` riêng, nhãn `data-v394-*` → `data-bj06-*`, ~87 luật CSS `body[data-active-uif="UIF-06"]` (ép cột 370px, hàng 76px) thay bằng khối `bj06-*` cuối `screens.css`; listener `click` vẫn ở pha capture (k2RejectSheet chặn nổi bọt nên bubble không thấy nút trong sheet).
- **Golden:** sửa `SC_bj06_line`, `SC_bj06_other_lot`, `SC_bj06_receipt`, `SC_bj06_classify`, `SC_bj06_approve`, `SC_bj06_reject` (vào bằng `entry=approver`); thêm `SC_bj06_full`, `SC_bj06_split`, `SC_bj06_exception_submit`, `SC_bj06_owner_approve`, `SC_bj06_after_approval`, `SC_bj06_waiting_open`, `SC_bj06_self_approval`, **`SC_journey_3`**; `WEB_SCENARIOS` thêm `SC_bj06_full`, `SC_bj06_exception_submit`, `SC_bj06_split`, `SC_bj06_owner_approve`, `SC_journey_3`.
- **Audit (`/impeccable audit`, Chrome headless CDP, 55 ca = 030…035 × trạng thái × 2 khung, gồm sheet chia / kết quả / từ chối và lô khác + ảnh):** chữ ≥ 4,5:1 (0 lỗi); vùng chạm iPhone ≥ 44 × 44 (0 lỗi, gồm "Nhận đủ", "Chụp ảnh", `dsChoiceRow`); ảnh nhãn lô có `alt`; 0 nút thiếu tên; 0 tràn ngang; web: Tab bảng trái → cột phải, hộp thoại giữ Tab trong hộp thoại, Esc đóng và trả focus về nút / dòng đã mở (sửa: dòng 033 trùng thuộc tính với nút bảng ẩn nên focus không về — thêm `data-bj06-row`); nút `dsSegmented` ở web nâng 38 → 40px. Detector `impeccable detect` chỉ báo chữ của bộ kiểm ngoài khung app.
- Badge harness `v5.12.0 · BJ-06 thiết kế lại · hết chặng 3`.

## [5.11.0] — BJ-04 / BJ-05 thiết kế lại; K6

Golden mobile so `tools/.golden-chang2` (1607 ca → 1640), web so `tools/.golden-chang2-web` (762 → 789). 0 lỗi JS ở cả hai khung. Khác có chủ đích: `UIF-04_*`, `UIF-05_*` (mọi trạng thái dựng khác nhau, kể cả các cặp trước đây trùng ảnh: `028 READY` / `PARTIAL_ALLOWED`, `025 FILTER_EMPTY` / `READY`, `026 STALE_RECOVERED`), `SC_bj04*`, `SC_bj05_*`, `SC_quick_UIF-05_*`, `SC_ws_movement_1_2_item` (cùng màn 025 mở từ Hub), `SC_entry_UIF-04_*` / `SC_entry_UIF-05_*`, `SC_bj17_from_bj05_0` (bước 0 là 029 `UNKNOWN` theo K3; các bước BJ-17 phía sau khớp mốc). Ca BJ-02 khớp (`bj02Footer` chỉ gọi lại `k4ReasonFooter`). SCR-027 không còn ca.

- **K6 (`shared-patterns.js`, mới):** `k6TaskList({ search, filters, columns, rows, total, mobileRow, rowAttr, empty, filterEmpty, filterEmptyAttr })` — ô tìm → chip có số (`k7FilterChips`) → bảng web / danh sách iPhone (`k7Table`) → khối "không tìm thấy" luôn dựng sẵn (ẩn) để ô tìm lọc tại chỗ. BJ quyết bước mở tiếp của từng dòng qua `rowAttr`; dòng chỉ xem có `aria-disabled`. Cột đầu của bảng là nút `.k7-row-link` nên đi bàn phím được.
- **`k4ReasonFooter({ label, attr, disabled, reason })`:** chân một nút có dòng lý do khi tắt (chuyển từ `bj02Footer`, HTML BJ-02 không đổi). `k3Unknown` thêm tham số tùy chọn `handoff: { operation, scope }` — giá trị gửi sang BJ-17 khi khác chữ hiển thị (BJ-05 gửi mã nghiệp vụ như cũ).
- **SCR-025 (K6):** chip "Tất cả" · "Cần lấy" · **"Chờ bàn giao"** · "Đang chờ" có số; dòng "{khách} · {n} mặt hàng"; web bảng Đơn · Khách hàng · "Đã lấy" ("{a}/{b} mặt hàng") · Tình trạng. Đơn "Chờ bàn giao" mở thẳng 028; đơn chờ / đang xác minh là dòng tắt.
- **SCR-026 (gộp SCR-027):** thanh tiến độ "Đã lấy đủ {a}/{b} mặt hàng"; mỗi mặt hàng một đầu nhóm, mỗi lô một dòng "Lô · HSD · Lấy {n}"; nút **"Lấy đủ"** một chạm (không toast), sheet "Đã lấy" chỉ khi lấy thiếu / đổi lô, **lưu ngay** (bỏ "Lưu lượng đã lấy"); lô thiếu hiện "Đã lấy {p}/{n}" + badge "Đã lấy một phần"; điều chỉnh lô hiện banner + "Xác nhận đã điều chỉnh hàng" ngay trên dòng. Web: bảng Sản phẩm · Lô · HSD · Cần lấy · Đã lấy (`k7EditCell`, lưu ngay khi hợp lệ) · nút, "Đổi lô" mở hộp thoại "Chọn lô thay thế" (`dsChoiceRow`); khối "Tóm tắt" có "Giao một phần" "Được" / "Không" và "Xem giữ hàng". Chân "Rà soát bàn giao" có dòng lý do khi tắt ("Lấy ít nhất một mặt hàng", "Đơn này yêu cầu giao đủ · còn {n} mặt hàng chưa lấy đủ", "Xác nhận điều chỉnh lô trước khi bàn giao").
- **SCR-027:** RETIRED, alias → SCR-026; ra khỏi `flow.screens` của UIF-05 (`data/workbench-data.js` / `.json`) và bảng mẫu Figma của `core.js`.
- **SCR-028:** **"Giao cho"** (`dsSegmented`: "Khách nhận tại quầy" | "Đơn vị vận chuyển", ghi vào `evidence.recipient`), "Giao lần này" / "Còn lại sau lần này" "{n} mặt hàng" (thay "dòng hàng"); `READY` (đơn không cho giao một phần) cột "Lượng thực giao" chỉ đọc; `PARTIAL_ALLOWED` có ô sửa; `PARTIAL_BLOCKED` chân tắt kèm lý do; `SOURCE_CHANGED` = `k1Stale`. DOM theo thứ tự đọc: "Giao cho" → tóm tắt → bảng; web đặt lại cột bằng CSS.
- **SCR-029 (K4 / K3):** `k4Result` — Đơn · Khách hàng · "Giao cho" · "Bàn giao lúc" (điền thật) · "Người bàn giao"; sheet "Xem {n} dòng hàng"; chân "Lấy đơn tiếp theo" (đơn "Cần lấy" kế tiếp) hoặc "Tiếp tục phần còn lại" | "Về danh sách đơn cần lấy". `UNKNOWN` = `k3Unknown` (mã tham chiếu, thời điểm gửi, "Về Kho"); `PERMISSION_DENIED` = `k1Denied` ở mọi màn 025…029.
- **SCR-021 (BJ-04):** phụ "Đơn {mã} · {khách}"; dải "{a} đang giữ · {b} thiếu · {c} đã xong" (`cf12Strip`); iPhone "{mã} · Đang giữ {h}/{r} {ĐVT}" + badge "Giữ đủ" / "Thiếu {n} {ĐVT}" / "Đã bàn giao"; web bảng Sản phẩm · Cần giữ · Đang giữ · Đã bàn giao · Thiếu · Tình trạng + "Tóm tắt". **Hết ngõ cụt:** chân "Lấy hàng" → 026 của đúng đơn; từ 026 "Xem giữ hàng" → 021, quay lại về 026 (kể cả chế độ Toàn Theme 7: `hub.js` `afterFlowRender` tôn trọng nút quay lại gắn `data-keep-back`).
- **Fixture chung chặng 3 (C0):** HSD lô DH2507 "30/11/2026" (khớp BJ-02); thêm SO-260827-22 "Trang trại Phú Lợi" (đơn không cho giao một phần, đã lấy đủ → chip "Chờ bàn giao"); `bj04OrderModel(orderId)` dựng 021 từ `io05Orders` (đơn tĩnh SO-260827-18 giữ cho `?uif=UIF-04`); `window.__VET45_QA__.openBJ04(orderId)`.
- **Rò trạng thái:** `io05Seed` — trạng thái màn đặt từ ngoài (bộ kiểm, URL) dựng lại đơn từ bản gốc rồi chuẩn bị đúng đơn cho trạng thái đó; đi bằng nút / `navigate` (kể cả quay lại) không dựng lại. Hết "Lô DH2511 · Đã đổi" lọt sang ca `READY`; 029 mở thẳng có kết quả mẫu (hết "Bàn giao lúc —").
- **Dọn mã:** bỏ `render027BJ05`, `bj05ReadOnlyListRow`, `bj05SelectionRow`, `deniedBody` / `loadingBody` / `ds24Result` riêng; `data-v396-reservation-line` → `data-bj04-line`; bỏ `.v396-reservation-*` trong `screens.css`.
- **Golden:** sửa `SC_bj05_list`, `SC_bj05_pick`, `SC_bj05_override`, `SC_bj05_handover`; thêm `SC_bj05_quick_pick`, `SC_bj05_ready_handover`, `SC_bj05_blocked`, `SC_bj05_stale`, `SC_bj05_next_order`, `SC_bj05_theme`, `SC_bj04_from_pick`, `SC_bj04_after_handover`; `WEB_SCENARIOS` thêm `SC_bj05_quick_pick`, `SC_bj05_ready_handover`, `SC_bj05_override`, `SC_bj04_from_pick`, `SC_bj05_theme`.
- **Audit (`/impeccable audit`, Chrome headless CDP, 025 / 026 / 028 / 029 / 021 × trạng thái × 2 khung):** detector 0 phát hiện; chữ ≥ 4,5:1 (0 lỗi); vùng chạm iPhone ≥ 44 × 44 (0 lỗi, gồm "Lấy đủ", ô sửa lượng); web nút 40px theo quy ước K7 chung; 0 tràn ngang; trạng thái "đã lấy đủ / một phần" có chữ; web: Tab qua chip → dòng bảng → ô "Đã lấy" → "Lấy đủ" → "Đổi lô", Enter mở hộp thoại, **Tab đi vòng trong hộp thoại**, Esc đóng và trả focus về nút mở; "Lấy đủ" bằng bàn phím giữ focus ở dòng; dựng lại giữ vị trí cuộn.
- Badge harness `v5.11.0 · BJ-04 / BJ-05 thiết kế lại · dựng K6`.

## [5.10.0] — BJ-13 thiết kế lại; hết chặng 2 (SC_journey_2)

Golden mobile so `tools/.golden-bj13-base` (chụp ở HEAD sau T7-HF1, thay mốc `.golden-bj03-after` đã cũ: 1560 ca → 1607), web so `tools/.golden-bj13-web-base` (721 → 762). 0 lỗi JS ở cả hai khung. Khác có chủ đích: `UIF-13_*` (mọi trạng thái 085 / 086 / 089 dựng khác nhau — trừ `SCR-085_PERMISSION_DENIED` = `FINANCIAL_MASKED`, cùng `k1Denied` theo brief), `SC_bj13_*`, `SC_entry_UIF-13_source-task`, `SC_bj03_retired` (SCR-018 mở SCR-085 mới), `SC_ws_valuation_*` (chữ dòng Hub), `SC_journey_2` (mới). `UIF-14_*` khớp (BJ-14 không đọc fixture BJ-13). Mọi ca khác khớp mốc. Mốc mới cho chặng 3: `tools/.golden-chang2`, `tools/.golden-chang2-web`.

- **SCR-085 (`bj13.js`, viết lại):** chip có số ("Tất cả" · "Có thể xử lý" · "Đang chờ"); web `k7Table` Nguồn · Loại · Đối tác · Số tiền · Sản phẩm · Tình trạng; iPhone dòng = tên nguồn (được xuống 2 dòng, không cắt mã) + "{loại} · {đối tác}" + số tiền có dấu + badge. Số tiền mono, luôn có "+" / "−", xanh tăng / đỏ giảm; chưa quy đổi VND → "Chờ quy đổi" (thay "0 đ"). `EMPTY` / `FILTER_EMPTY` / `LOADING` / không có quyền dựng thật (K1).
- **SCR-086:** web hai cột (`k7Split` 4 : 8) — trái thẻ nguồn ("Xem chứng từ", "Giá trị điều chỉnh" số lớn) + "Cách phân bổ" (một phương pháp: dòng chỉ đọc; nhiều: `dsChoiceRow` có mô tả) + "Kỳ ghi nhận" một dòng ("Ghi vào kỳ 09/2026 · kỳ gốc 08/2026 đã khoá"); phải **một bảng** "Kết quả phân bổ" Sản phẩm · Phiếu nhận · Lô · Số lượng · Giá trị nhập · Tỷ trọng · Phân bổ + dòng "Tổng phân bổ" + "Phạm vi do nguồn xác định, không bỏ bớt sản phẩm được." (bỏ khối "Phạm vi áp dụng" và banner kỳ khoá). iPhone xếp dọc: nguồn → bảng (thẻ) → cách phân bổ → kỳ. Nguồn đang chờ mở chỉ đọc ("Chưa thể xử lý" + lý do, không bảng, không nút). `VALIDATION_ERROR`: banner mới không có "metric", bảng không cột tỷ trọng / phân bổ, nút tắt kèm lý do. `SOURCE_CHANGED`: đóng sheet, banner, số mới.
- **Sheet "Ghi điều chỉnh giá trị?"** (thay SCR-088 cũ): Nguồn · "{n} sản phẩm" · Cách phân bổ · Kỳ ghi nhận · Giá trị điều chỉnh; "Quay lại" | "Xác nhận"; web hộp thoại giữa màn; Esc / nền đóng, focus về nút mở, **Tab đi vòng trong sheet** (bẫy focus — mới, chỉ sheet BJ-13).
- **SCR-089:** K4 (Nguồn · Tổng điều chỉnh · Sản phẩm bị ảnh hưởng · Kỳ ghi nhận · Giá vốn "Cần cập nhật"); "Xem chi tiết phân bổ ({n})" mở sheet "Kết quả phân bổ"; chân "Cập nhật giá vốn" (→ BJ-14 `dirty-scope`) | "Về công việc điều chỉnh"; `UNKNOWN` = K3 (mã tham chiếu, thời điểm, "Về Kho"; bỏ chữ "adjustment"); `REJECTED_EXECUTION` = K4 cảnh báo + "Xem lại phân bổ".
- **Fixture:** LC13-001 (VC-8842) phân bổ cho Nobivac DHPPi SP-000184 PN-260816-04 lô DH2507 121 hộp · 9.885.700 đ + Vaccine Canine X (bỏ "Amoxicillin LA" chưa xác lập giá); LC13-004 đối tác "VietVet" (khớp phiếu PN-260902-07). `val13SyncFromValuation()` lấy số lượng / giá trị nhập từ `val03LastResult` khi vào 085 / 086.
- **Hub:** dòng Giá trị kho "Điều chỉnh giá trị hàng nhập" + "Chi phí, chiết khấu phát sinh sau khi đã xác lập giá"; `FLOW_LABELS["UIF-13"]` cùng tên. Thanh bên "Kho" và nút "Về Kho" (`data-theme-sidebar-route`) **mở Home Kho** thay vì màn con Hub đã xem trước (vd. "Chờ duyệt") — sửa từ audit `SC_journey_2`.
- **BJ-03:** "Tiếp tục xử lý" ở SCR-019 xoá lối quay lại SCR-012 (`val03ReturnTo`): quay lại từ SCR-015 về SCR-014 thay vì kết quả nhận hàng (ngõ cụt trên iPhone) — sửa từ audit `SC_journey_2`; golden BJ-02 / BJ-03 không đổi.
- **Quyền:** chỉ chủ cửa hàng; `entry=staff` (`entryTargets["UIF-13"].staff` → SCR-085) và `FINANCIAL_MASKED` → "Bạn chưa có quyền điều chỉnh giá trị".
- **Dọn mã:** bỏ khối dựng v430 (085) và v461 (086 / 089), listener SCR-087 / 088 (`data-v430-val13-*`, `data-v461-val13-*` → `data-bj13-*`), nhánh `SCR-088` trong `val13ApplySourceUpdate`, helper dựng cũ (`val13SourceCard`, `val13TargetHtml`, `val13AllocationRows`, `val13PeriodCard`, `val13ReviewBody`, `val13StatusMeta`…); bỏ `VAL_UI_430` khỏi `shared-valuation.js` (không còn chỗ dùng). Giữ `val13Engine` (BJ-14 dùng), `val13Preview`, `val13PreviewHashOf`, `val13Commit`.
- **CSS (`components.css`, khối BJ-13 cuối file):** `!important` mới, ghi theo cách T7-HF1 — dòng Compact 370 × 52 của UIF-03/13/14 và banner Default 96px của khung Figma ép bằng `!important`; BJ-13 đè cùng loại, chỉ trong `.bj13-list`, `.bj13-choices` và banner UIF-13 (mô tả 3 dòng trên iPhone bị cắt).
- **Golden:** sửa `SC_bj13_flow`; thêm `SC_bj13_waiting`, `SC_bj13_decrease`, `SC_bj13_stale`, `SC_bj13_staff`, `SC_bj13_unknown`, `SC_bj13_result`, **`SC_journey_2`**; `WEB_SCENARIOS` thêm `SC_bj13_flow`, `SC_bj13_decrease`, `SC_journey_2`.
- **Audit (`/impeccable audit`, Chrome headless CDP, 9 màn / trạng thái × 2 khung):** chữ ≥ 4,5:1 (0 lỗi, kể cả số tiền xanh / đỏ và badge); vùng chạm iPhone ≥ 44 × 44 (0 lỗi); 0 nút thiếu tên; web: Tab qua chip, dòng bảng, "Xem chứng từ", "Ghi điều chỉnh"; Enter mở sheet; Esc đóng, focus về nút mở — sửa: focus thoát khỏi sheet khi Tab. Detector chỉ báo chữ của bộ kiểm (danh sách màn 10px, chữ thanh bên mờ), ngoài khung app.
- Badge harness `v5.10.0 · BJ-13 thiết kế lại · hết chặng 2`.

## [5.9.1] — T7-HF1: đủ bố cục iPhone và web cho màn đã làm

Golden mobile so `tools/.golden-hf1-base` (1560 ca → 1560), web so `tools/.golden-hf1-web-base` (686 → 718: thêm `SC_bj01_list`, `SC_bj01_detail`, `SC_bj01_theme`, `SC_hf1_receive_lines`, `SC_hf1_bj01_select`). 0 lỗi JS. Chỉ bố cục đổi, không đổi chữ, nghiệp vụ hay luồng.

- **Web, BJ-01:** SCR-001 là danh sách – chi tiết (`k7-wide`; bảng Sản phẩm · Khả dụng · Tồn vật lý · Đã giữ · Chỉ báo bên trái, chi tiết sản phẩm đang chọn bên phải; mặc định dòng đầu; bấm / Enter đổi chi tiết, không đổi trang; `bj01WebSelectedId`). SCR-003 hai cột (thẻ số + ngưỡng | bảng lô Lô · HSD · Tồn · Tình trạng + nguồn). `bj01DetailBody(p)` dùng chung hai màn; iPhone giữ danh sách thẻ.
- **Web, BJ-02:** SCR-009 + SCR-084 là một màn hai cột (`bj02WebLineId`, `bj02LineEditorBody`, `bj02LoadLineEditor`): "Xong" lưu dòng rồi chọn dòng chưa xử lý kế tiếp; đổi dòng giữ nháp như nút quay lại của 084; `render084BJ02` trên web = 009 với dòng được chọn. SCR-010 hai cột (bảng "Hàng thực nhận" | "Tóm tắt" + nút xác nhận). SCR-008 hai cột (`.bj02-quick-grid`). Chân màn có dòng lý do: lý do trái, nút phải rộng theo chữ.
- **Web, Home Kho:** ô tìm ≤ 720px, bốn nút nhanh một hàng, dưới chia hai cột (`.t462-columns`), không nút quay lại. CAP-01 SCR-063: ô số ngày ~200px, "Thêm sản phẩm" rộng theo chữ. BJ-03 SCR-015: cột "Tình trạng" ≥ 240px (khối "Tóm tắt" 288px để bảng không tràn).
- **Khuôn K3:** `k3Unknown` bọc kết quả + detail trong `.k3-column` (web ≤ 720px giữa khung; iPhone `display:contents`) — áp cho BJ-02 013, BJ-03 019, BJ-12 066 / 071, CAP-01 065 khi chưa xác định.
- **iPhone:** K2 "Cần chú ý" xếp nhãn (chữ phụ) trên giá trị, icon bên trái cả khối (`.k2-attention__row` gộp hai khai báo làm một); dòng thu gọn SCR-011 (`bj02ReadOnlyLine`): số "121 / 120" không gãy, mã · ĐVT · lô được xuống 2 dòng.
- **Đổi khung (`harness/workbench.js`, `core.js`):** nút đổi khung giờ gọi `onViewportChange` (BJ đăng ký: SCR-084 → SCR-009 khi sang web; giữ nháp khi về iPhone) rồi `renderAppScreen()`. Màn có bố cục riêng theo khung (SCR-001, 003, 009, 010, Home Kho) dựng theo `viewport`, nên DOM iPhone giữ nguyên (golden iPhone khớp).
- **`!important` mới (ghi theo plan mục 7):** luật dùng chung của UIF-01/02/04/05/08 (`screens.css` ~1807–2260, thẻ số liệu Figma) ép List Row 370px / Key-value Row 338px / thẻ kết quả bằng `!important`; các luật web trong khối `T7-HF1` cuối `components.css` đè cùng loại và chỉ trong màn BJ-01, 009, 010, K3 và dòng thu gọn 011.
- **Ca golden khác (so mốc):** iPhone — `UIF-02_SCR-011_*` (dòng thu gọn + K2), `UIF-12_SCR-070_READY` (K2) và các kịch bản đi qua hai màn đó (`SC_bj02_*`, `SC_bj03_from_receipt`, `SC_bj12_*`, `SC_pending`, `SC_journey_1`, `SC_entry_*`). Web — `UIF-01_*`, `UIF-02_SCR-008 / 009 / 084 / 010 / 012(UNKNOWN) / 013`, `UIF-03_SCR-015`, `UIF-12_SCR-066 / 071` và `CAP-01_SCR-065` (K3), `CAP-01_SCR-063`, `HUB_home*`, các `SC_*` đi qua chúng. Ngoài danh sách: `SC_bj15_sheet_2_nob` / `_4_glv` iPhone (80–94 điểm ảnh rải trong một sheet, chữ giống hệt, không đổi mã BJ-15; ca web tương ứng lúc có lúc không → nhiễu hiển thị chữ mono, không quy được cho đợt này).
- **Audit (`/impeccable audit`, Chrome headless CDP, 11 màn × 2 khung):** chữ ≥ 4,5:1 (kể cả dòng chọn của bảng), nút icon đều có `aria-label`, dòng chọn có `aria-selected` / `aria-current`, bàn phím (Tab · Enter · Space · Esc) đạt; detector không có phát hiện mới trong khối T7-HF1. Vùng chạm iPhone: chỉ còn chip lọc BJ-01 34px nhìn thấy (vùng chạm 44px qua `::after`, có từ trước).
- **Sửa sau review (2026-10-22):** sheet `ds24Sheet` (lô, nguồn, quét của BJ-01; danh sách dòng 012, chứng từ giao nhận 011, quét 009 của BJ-02) trên web là hộp thoại 480px giữa khung như `.bottom-sheet` — trước đó dính góc dưới cột trái vì `.ds24-sheet` cố định `position:absolute; bottom:0` và UIF-01 đặt rộng 402px. Khối con bỏ bề rộng iPhone (`!important` cho Key-value / Info Row và chữ banner, vì luật iPhone của chúng có `!important`). `SC_hf1_bj01_select` chọn Nobivac DHPPi trước khi mở sheet lô, thêm bước sheet nguồn (web 718 → 721 ca). Golden iPhone khớp hoàn toàn; web chỉ khác ca mở sheet BJ-01.
- Badge harness `v5.9.1 · T7-HF1 · đủ hai khung`.

## [5.9.0] — T7-P BJ-03: thiết kế lại Xác lập giá trị nhập ban đầu

Golden mobile so `tools/.golden-bj02-after` (1510 ca → 1560), web so `tools/.golden-bj02-web-after` (636 → 686). Khác có chủ đích: `UIF-03_*` (ca `UIF-03_SCR-017_*` mất; mọi trạng thái 014 / 015 / 019 dựng khác nhau — trừ `SCR-014_PERMISSION_DENIED` = `FINANCIAL_MASKED`, cùng `k1Denied` theo brief), `SC_bj03_*` (kịch bản mới, xem dưới; `SC_bj03_basis` mất), `SC_entry_UIF-03_*`, `SC_ws_valuation_*` (chữ dòng Hub), `SC_bj02_owner_flow` / `SC_bj02_result_owner` (bước cuối "Xác lập giá trị" mở SCR-015 mới). Mọi ca khác khớp mốc.

- **SCR-014 (`bj03.js`, viết lại):** chip lọc có số ("Tất cả" · "Có thể xác lập" · "Cần xử lý"); dòng "{NCC} · {Theo chứng từ | Nhập nhanh}" + "{n} sản phẩm chờ" + badge (phiếu sẵn sàng cũng có badge); web `k7Table` có cột "Chờ" ("{n} ngày"); phiếu vừa nhận ở BJ-02 đứng đầu; `EMPTY` / `FILTER_EMPTY` / `LOADING` / `PERMISSION_DENIED` / `FINANCIAL_MASKED` dựng thật (K1). Hub: dòng "Hàng chờ xác lập giá trị" + "Ghi giá nhập cho hàng đã nhận"; `FLOW_LABELS["UIF-03"]` = "Xác lập giá trị nhập ban đầu".
- **SCR-015:** bảng sản phẩm có ô tick (Sản phẩm + lô · Số lượng · Đơn giá · Thành tiền · Tình trạng); dòng đủ căn cứ tick sẵn một lần khi mở phiếu (`r.ticked`, cũng khi vào thẳng); dòng mâu thuẫn nói rõ hai giá lệch và "Thống nhất giá ở Mua hàng rồi quay lại."; "Cách tính" mở sheet bảng thành phần (ngoại tệ: "Quy đổi từ USD theo tỷ giá kế toán", không hiện tỷ giá); web `k7Split` (`wideMain`): bảng + khối "Tóm tắt" có nút "Ghi giá trị ({n})", iPhone: thẻ có ô tick đầu thẻ + dải "Đã chọn {n} sản phẩm · {tổng}" + chân (lý do "Chọn ít nhất một sản phẩm đủ căn cứ" khi tắt).
- **Sheet "Thêm căn cứ giá":** bỏ ô tiền tệ (chỉ VND — JA-05); "Đơn giá mua" có hậu tố "đ/{ĐVT}" + gợi ý "Giá vốn hiện tại: {giá} đ/{ĐVT}" (`officialCostVnd`, chỉ gợi ý); "Cách hiểu giá" là `dsSegmented` (mặc định "Đã gồm thuế"); "Ngày căn cứ" điền sẵn ngày nhận; lỗi tại ô, dữ liệu giữ; bỏ câu "Kế toán có thể lập căn cứ…". Hộp thoại giữa màn trên web, sheet dưới trên iPhone; nút ở chân sheet cố định khi nội dung cuộn.
- **SCR-017 → RETIRED** (`screenAliases["UIF-03"]["SCR-017"] = "SCR-015"`, bỏ khỏi `flows[UIF-03].screens`): rà soát thành sheet "Ghi giá trị nhập ban đầu?" trong SCR-015; căn cứ đổi lúc xác nhận → đóng sheet, `SOURCE_CHANGED` + "Kiểm tra lại" (`val03ApplySourceUpdate` bỏ điều kiện `SCR-017`, nay: dòng đang chọn thì tăng `sourceVersion`).
- **SCR-019:** K4 — Phiếu nhận · Sản phẩm đã xác lập · Tổng giá trị đã ghi · Giá vốn "Cần cập nhật" · Người ghi · Lúc · "Còn chờ giá trị"; "Xem chi tiết {n} sản phẩm" mở sheet; chân "Cập nhật giá vốn" (mở BJ-14 `dirty-scope`) | "Tiếp tục xử lý" / "Về danh sách"; `UNKNOWN` = K3; `REJECTED_EXECUTION` = K4 cảnh báo; `PROCESSING` = K1. Ca vào thẳng `COMPLETED` dùng kết quả mẫu tĩnh `VAL03_SAMPLE_RESULT` (không ghi khi dựng màn).
- **Quyền:** chỉ chủ cửa hàng; `entry=staff` (`entryTargets["UIF-03"].staff` → SCR-014) và `FINANCIAL_MASKED` → K1 "Bạn chưa có quyền xác lập giá trị" ở cả 014 / 015 / 019.
- **Khuôn dùng chung (`shared-patterns.js`, `components.css`):** `k7Table` có tham số `select` (cột ô tick; bỏ trống thì HTML như cũ — BJ-12 / BJ-02 / CAP-01 không đổi), `k7Check` / `k7CheckMark`, `k7Split` có `wideMain` / `asideWebOnly`.
- **Nối BJ-02:** `val03OpenForReceipt` đặt `ticked`, đặt lại giao diện, nhóm mới tạo có `officialCostVnd` theo giá vốn trong danh mục BJ-02; phiếu có `entryType: "QUICK" | "DOCUMENT"` (thay `v313EntryType` / so `id`).
- **Fixture:** nhãn căn cứ ngắn ("Đơn mua PO-2608-041 (v3)", "Xác nhận NCC 02/09"…) để "Căn cứ: {nhãn}" đọc tự nhiên; R2 G3 Găng tay `officialCostVnd: 135000`.
- **Dọn mã:** bỏ khối dựng v430 (015 / 016) và v461 (015 / 017 / 019) và toàn bộ `data-v430-val03-*` / `data-v461-val03-*` (nay `data-bj03-*`), `ensureVal03ReviewFixture` / `ensureVal03ResultFixture`, `v313EntryType`. Giữ `VAL_UI_430` / `VAL_UI_461` (BJ-13 / BJ-14 còn dùng) và các hàm tính khối v397.
- **Chữ mới ngoài brief (cần vào T7-P mục 13):** "Chi tiết {n} sản phẩm" (tiêu đề sheet chi tiết SCR-019), "Chọn sản phẩm" (tên cột ô tick, chỉ đọc màn hình), "Đóng" (nút sheet "Cách tính" / chi tiết), "Quay lại" ở sheet căn cứ, "Người ghi: Chủ cửa hàng", "Lúc: {giờ}".
- **Audit (`/impeccable audit` bằng Chrome headless qua CDP, 18 màn / trạng thái × 2 khung):** tương phản chữ ≥ 4,5:1 — sửa chữ mục đang chọn của `ds-segment` trong UIF-03 (4,31 → `--vet45-v2-text-brand`) và số tiền trong sheet chi tiết (4,13); vùng chạm iPhone ≥ 44 × 44 (0 lỗi; ô tick, "Nhập giá", "Cách tính"); 0 nút / ô thiếu tên truy cập; web: Tab / Space bật tắt ô tick, Enter mở hộp thoại, Esc đóng, focus về nút đã mở — sửa hai lỗi: dựng lại màn làm mất focus sau khi tick (`renderRefocus`) và handler nghe ở `window` chặn `core.js` ghi nút mở hộp thoại (nay nghe ở `document`). Ghi chú: `ds-segment` đo 43,99 px ở một số ca do thu khung — không phải lỗi.
- **Golden:** thay `SC_bj03_list` / `SC_bj03_confirm`, bỏ `SC_bj03_basis`; thêm `SC_bj03_direct`, `SC_bj03_from_receipt`, `SC_bj03_untick`, `SC_bj03_stale`, `SC_bj03_result`, `SC_bj03_staff`, `SC_bj03_unknown`; `WEB_SCENARIOS` thêm `SC_bj03_from_receipt`, `SC_bj03_direct`, `SC_bj03_list`.
- Badge harness `v5.9.0 · BJ-03 thiết kế lại · chặng 2`.

## [5.8.0] — T7-P BJ-02: thiết kế lại Nhận hàng mua; fixture chung chặng 2

Golden mobile so `tools/.golden-chang1` (1440 ca → 1510), web so `tools/.golden-chang1-web` (603 → 636). Khác có chủ đích: `UIF-02_*` (ca `UIF-02_SCR-006_*` mất, `SCR-010_REJECTED` mới), `SC_bj02_*` (kịch bản mới, xem dưới), `SC_entry_UIF-02_*`, `SC_quick_UIF-02_*`, `SC_entry_flow_02`, `SC_bj01_receive`, `SC_bj01_out` (Nhận hàng → SCR-007), `SC_pending_*` và `SC_pending_review_to_hub` (Chờ duyệt mở phiếu fixture 011; "Về Kho" dùng khuôn K2), `SC_ws_movement_0_2_item`, `SC_mode_1_bj` (màn đầu UIF-02 là SCR-007); mọi ca còn lại chỉ khác dòng `@url` (màn mặc định của UIF-02 từ SCR-006 sang SCR-007). `UIF-12_*` khớp (k2Attention / k3Unknown / k4Result / k7Table đổi tham số mặc định, HTML BJ-12 không đổi). 0 lỗi JS ở cả hai khung. Mốc mới (chặng 2): `tools/.golden-bj02-after`, `tools/.golden-bj02-web-after`.

- **SCR-006 → SCR-007 (`screenAliases["UIF-02"]`):** bỏ màn chọn cách nhận. 007 "Nhận hàng": ô tìm theo chứng từ / nhà cung cấp / sản phẩm, thẻ liệt kê tối đa hai tên hàng, dòng "Hàng đến chưa có chứng từ" cuối danh sách (cả khi rỗng); web: `k7Table` + nút phụ. BJ-01 "Nhận hàng" mở 007 với ô tìm điền sẵn tên sản phẩm.
- **SCR-008:** "Chụp ảnh" | "Chọn tệp" (web: kéo thả), danh sách tệp có "Xoá", ô tick quyền sở hữu thật, chân "Tiếp tục" kèm dòng lý do.
- **SCR-009:** một dòng ngữ cảnh + thanh tiến độ + ô tìm có nút quét (gõ / quét đúng mã mở thẳng dòng) + dòng `VStockRow` (số "{nhận} / {chứng từ}" + badge); lý do "Rà soát" tắt.
- **SCR-084:** "Nhận đủ {n} {ĐVT}"; "Đạt" ô số lớn nhập thẳng, "Hàng không đạt" ba ô nhỏ; hạn dùng một ô tự hiểu độ chính xác; lô đóng một dòng; hộp xác nhận chuyển từ chèn DOM sang trạng thái (nhận focus, Esc đóng); gõ số không dựng lại màn (giữ con trỏ).
- **SCR-010:** "Cần chú ý" (`k2Attention` tách khỏi `k2Decision`) đứng đầu; chủ cửa hàng lập cũng "Gửi phê duyệt" rồi tự vào SCR-011 duyệt một lần nữa (cửa hàng chỉ có một chủ; không có đường ghi nhận thẳng); `PENDING_APPROVAL` = `k2Pending`; thêm `REJECTED` + "Nhận lại"; bỏ `APPROVER_CONFIGURATION_MISSING`, `FINANCIAL_MASKED`.
- **SCR-011:** `k7Split` (`k2Decision` + `k7Table` có cột "Theo chứng từ", "Chênh lệch"), `k2RejectSheet` thay sheet chèn DOM, kết quả từ chối K4. **SCR-012:** K4 một bố cục theo vai (Owner: "Xác lập giá trị" → BJ-03; nhân viên: "Xem tồn kho"), "Vào tồn", "Giá trị — Chờ xác lập", "Xem {n} dòng hàng". **SCR-013:** một màn phục hồi (`k3Unknown` thêm `title`, `detail`); 012 `UNKNOWN` mở thẳng 013.
- **Hub "Chờ duyệt":** dòng đầu mở đúng phiếu vừa gửi trong phiên (`bj02PendingSubmitted`), không nạp lại fixture; chủ cửa hàng lập → Gửi phê duyệt → Về Kho → Chờ duyệt → Duyệt (kịch bản `SC_bj02_owner_flow`).
- **Ghi nhận xong:** `bj02LastCommitted` (BJ-03 đọc) và `bj01ApplyReceipt` cộng tồn BJ-01 (Đạt vào khả dụng; Đạt + Cách ly + Hỏng vào tồn vật lý; lô mới / lô có sẵn; `latestPhysicalMovement`).
- **BJ-03 nối vào phiếu vừa nhận (`bj03.js`):** `val03OpenForReceipt(ref)` (cũng ở `__VET45_QA__`) mở SCR-015 cho đúng phiếu: đọc `bj02LastCommitted`, dựng lại nhóm / lô / lát (Đạt = Đủ điều kiện bán, Cách ly, Hỏng) theo hàng thực nhận, nhập nhanh thì tạo phiếu mới (không có căn cứ giá), tick sẵn nhóm đã đủ căn cứ; nút quay lại về kết quả nhận hàng. Fixture R1 (PN-260816-04) khớp BJ-02: Nobivac DHPPi `SP-000184` một lô DH2507 121 hộp (9.885.700 đ), Oxytetracycline LA `SP-000147` 24 chai (hai căn cứ mâu thuẫn). Chưa làm phần thiết kế lại 014 / 015 của plan BJ-03; BJ-13 còn fixture riêng (Amoxicillin LA, 4.085.000 đ). Mốc `.golden-bj02-*` chụp lại sau thay đổi này (khác: `UIF-03_*`, `SC_bj03_*`, đầu cuối của `SC_bj02_owner_flow` / `SC_bj02_result_owner`).
- **Quy tắc duyệt cho mọi BJ (người dùng chốt 2026-10-22):** mỗi cửa hàng chỉ có một chủ; chủ lập phiếu cũng gửi duyệt rồi tự vào màn duyệt bấm "Duyệt" một lần nữa. **BJ-12:** bỏ nhánh "Ghi nhận số dư đầu kỳ" + sheet tự duyệt và "(tự duyệt)" (`cf12SelfOpen`, `cf12IsOwner`, `cf12ApprovedBy`, `open-self` / `confirm-self`); `k2SelfCommitSheet` bỏ khỏi `shared-patterns.js` (không còn BJ nào dùng); `SC_bj12_owner`, `SC_journey_1` đi Gửi phê duyệt → Về Kho → Chờ duyệt → Duyệt; `SC_bj12_pending_list` bỏ bước đổi vai. Đặc tả: DOM-IC `INV-IC-02`, UC-08-04, UC-10-01…04, UC-12-02, UC-02-03, BJ-02, BJ-12, overview, KB-KGV-011 / 021, SCR-051 / 068 / 070 / 071 ghi ngoại lệ `is_owner`. Mốc `.golden-bj02-*` chụp lại (khác: `SC_bj12_owner`, `SC_journey_1`, `SC_bj12_pending_list`, `UIF-12_SCR-068_READY`, `UIF-12_SCR-071_*`).
- **Fixture chung chặng 2:** Nobivac DHPPi (`SP-000184`), Oxytetracycline LA (`SP-000147`, không theo lô, 120.000 đ/chai) thay Amoxicillin LA; phiếu PN-260816-04 = Nobivac 120 hộp (theo lô) + Oxytetracycline LA 24 chai; `productRef` nối sản phẩm BJ-02 với BJ-01. Hub: dòng "Chờ duyệt" nhận hàng đầu tiên là phiếu 011 (Minh Dũng, Nguyễn Văn An gửi 09:41), gắn `data-theme-entry-actor="approver"`; bỏ `addPendingReviewExit` (010 chờ duyệt tự có "Về Kho").
- **Dọn mã:** bỏ `render006BJ02`, bàn phím số riêng (`bj02NumericPad…`), cờ chết `lineClassificationExpanded` / `lotClassificationExpanded`, `.replaceAll('sản phẩm','mặt hàng')`, `bj02ReviewProductBlocks` (dựng HTML rồi sửa DOM), thuộc tính `data-v392-*` / `data-v350-action="bj02-*"` → `data-bj02-*`.
- **Chữ ngoài brief (cần vào T7-P mục 13, đã ghi):** "Không có chứng từ đang chờ nhận" + "Hàng đến mà chưa có chứng từ mua thì nhập hàng nhanh." (EMPTY 007); "Chờ nhận" (cột Tình trạng bảng web); "Kho và ngày nhận"; "Thêm ít nhất một mặt hàng"; "Ngày sản xuất chưa đúng dạng"; "Không có {tên} trong chứng từ này" (quét không khớp); "Hàng thực nhận" làm tiêu đề sheet "Xem {n} dòng hàng".
- **Audit (`/impeccable audit` bằng Chrome headless qua CDP, 27 màn / trạng thái ở khung iPhone và 27 ở web):** tương phản chữ ≥ 4,5:1 (chữ lớn ≥ 3:1) 0 lỗi; vùng chạm iPhone ≥ 44 × 44 (sửa liên kết "Sửa" 26 → 44 px); 0 nút / ô thiếu tên truy cập; Esc đóng sheet quét, sheet tự duyệt và hộp xác nhận, focus vào hộp thoại khi mở; Tab tới được từng mã chứng từ trong bảng web. Sửa ngay: chân màn web 402px → 100% (`.k7-wide` + legacy UIF-02), cột bảng duyệt web co theo khung.
- **Golden:** thay `SC_bj02_choose` / `SC_bj02_approve_ok`; thêm `SC_bj02_doc_full`, `SC_bj02_over_staff`, `SC_bj02_owner_flow`, `SC_bj02_approve`, `SC_bj02_reject`, `SC_bj02_quick`, `SC_bj02_scan`, `SC_bj02_unknown`, `SC_bj02_from_bj01` (+ `SC_bj02_documents`, `SC_bj02_line`, `SC_bj02_not_received`, `SC_bj02_lot`, `SC_bj02_evidence`, `SC_bj02_rejected_maker`, `SC_bj02_quick_form`, `SC_bj02_scan_type`, `SC_bj02_result`, `SC_bj02_result_owner`); `WEB_SCENARIOS` thêm `SC_bj02_documents`, `SC_bj02_quick`, `SC_bj02_approve`, `SC_bj02_reject`, `SC_bj02_owner_flow`.
- Badge harness `v5.8.0 · BJ-02 thiết kế lại · chặng 2`.

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
