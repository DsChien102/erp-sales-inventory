# T7-P · CAP-01 Chính sách tồn & cận hạn — thiết kế lại (bước B–E) + `SC_journey_1`

> Theme: Theme 7 Inventory · Trạng thái: Brief ✅ (duyệt 2026-10-21) | Plan C–E ✅ | Làm ⬜ | Review ⬜
> Thuộc [T7-P](T7-P-thiet-ke-lai-luong.md) mục 8.2 **chặng 1 "Mở kho"**, BJ thứ ba (cuối chặng). Làm **sau** [BJ-12](T7-P-bj12-ton-dau-ky.md) (dựng K1–K4, K7) và [BJ-01](T7-P-bj01-ton-kho.md). Dùng lại khuôn, không dựng khuôn mới.
> Thiết bị chính: **web** (Owner đặt ngưỡng cho nhiều sản phẩm một lượt); sửa lẻ một sản phẩm từ chi tiết tồn chạy tốt trên iPhone.
> Hết plan này = **hết chặng 1**: kịch bản `SC_journey_1` (mục 4.5) đi một mạch Home Kho chưa kích hoạt → khởi tạo → xem tồn → đặt ngưỡng → thấy chỉ báo đổi.
> Ước lượng: **~1,25 ngày, 2 commit** (C+D; E). Người làm: bạn. Review: phiên plan / review.

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/` nếu không ghi khác. Câu trong ngoặc kép là chữ hiển thị; **(mới)** = chữ mới, vào T7-P mục 13 ở bước E.

## 0. Brief (bước B, đã duyệt 2026-10-21)

### 0.1 Việc thật

- **Ai, lúc nào:** Owner, ngay sau khi khởi tạo kho (BJ-12 → "Đặt ngưỡng tồn"): đặt **một lượt** ngưỡng tồn thấp và mức tồn mục tiêu cho các sản phẩm, đặt số ngày cận hạn mặc định — trên máy tính. Về sau: thấy "Chưa có ngưỡng tồn" ở chi tiết một sản phẩm (BJ-01) thì đặt luôn tại chỗ, thường trên iPhone.
- **Để làm gì:** BJ-01 báo đúng "Tồn thấp" / gợi ý nhập thêm; BJ-09 cảnh báo hoặc chặn bán lô cận hạn.
- **Quy tắc giữ (CAP-01, OP-01…03):** mục tiêu ≥ ngưỡng ≥ 0; số ngày cận hạn > 0; hành động chỉ "Cảnh báo" / "Chặn bán"; ghi đè theo sản phẩm ưu tiên hơn mặc định, bỏ ghi đè thì quay về mặc định; mỗi lần lưu là một lần cập nhật ("Lần N"); **không làm đổi số tồn**.

### 0.2 Luồng hiện tại

Ảnh: `tools/.golden-phase1/CAP-01_SCR-062_READY.png`, `…063_READY`, `…064_READY`, `…065_COMPLETED`.

Home Kho → Thiết lập kho → "Chính sách tồn & cận hạn" → SCR-062 Chính sách tồn (Ngưỡng cảnh báo · Mức tồn mục tiêu · Nguồn áp dụng) → "Rà soát thay đổi" → SCR-064 Rà soát → "Lưu chính sách" → SCR-065 Kết quả → "Đóng". SCR-063 Hàng cận hạn tương tự, nhưng **không có lối vào** từ Hub (chỉ mở được bằng URL).

### 0.3 Vấn đề

| # | Màn | Vấn đề |
|---|---|---|
| 1 | 062 | **Không nói đang đặt cho sản phẩm nào**; số "50" không đơn vị; ngưỡng tồn thấp là theo từng sản phẩm (OP-01 "người dùng chọn sản phẩm") nhưng màn không có sản phẩm |
| 2 | 062 | Sau khởi tạo có 36 sản phẩm: đặt từng cái một qua 3 màn (062 → 064 → 065) cho mỗi sản phẩm là quá lâu; không thấy sản phẩm nào **chưa có ngưỡng** |
| 3 | 062, 063 | Khối "Phạm vi · Áp dụng … · Tác động sổ kho: Không" đứng đầu màn — thông tin kỹ thuật, chiếm chỗ của việc chính |
| 4 | 062, 063 | Ô chọn "Nguồn áp dụng: Ghi đè theo sản phẩm / Mặc định tổ chức" khó hiểu; ở 063 chọn "Ghi đè theo sản phẩm" nhưng không có chỗ chọn sản phẩm nào (OP-03) |
| 5 | 064 | Bố cục vỡ: "Ngưỡng cảnh báo50", "Mức tồn mục tiêu80" dính liền; tác động nói chung chung "Được tính lại theo chính sách mới" thay vì con số cụ thể |
| 6 | 064 `APPROVAL_REQUIRED` | "Cần người có quyền xác nhận. Bạn không thể tự lưu" nhưng CAP-01 không có luồng duyệt → ngõ cụt |
| 7 | 065 | Một màn kết quả riêng cho việc lưu cấu hình, chỉ có "Đóng"; quy tắc chung (T7-P mục 5): thành công cùng màn dùng toast |
| 8 | Lối vào | Hub chỉ mở 062; 063 không có lối vào; chi tiết sản phẩm (BJ-01 SCR-003) "Chưa có ngưỡng tồn" không dẫn tới đâu |
| 9 | Web | Cột điện thoại giữa màn rộng; không có bảng |

### 0.4 Đề xuất

**Luồng mới**

```text
Đường chính (web, sau BJ-12):  071 "Đặt ngưỡng tồn" / Hub "Chính sách tồn & cận hạn"
   → 062 Ngưỡng tồn: bảng sản phẩm, sửa tại dòng ─"Lưu thay đổi (n)"→ sheet tác động → toast, ở lại màn
     ⇄ (thanh chọn trên đầu) 063 Cận hạn: mặc định + sản phẩm có chính sách riêng ─"Lưu thay đổi"→ toast
Đường lẻ (iPhone / web):         BJ-01 SCR-003 "Chưa có ngưỡng tồn" ─"Đặt ngưỡng tồn"→ 062 một sản phẩm ─"Lưu"→ toast, về SCR-003
```

*Chung cho 062 / 063*

1. **Thanh chọn** "Ngưỡng tồn | Cận hạn" **(mới)** (`VSegmentedControl`) ngay dưới app bar, chuyển qua lại giữa 062 và 063; tiêu đề app bar chung "Chính sách tồn & cận hạn" (chữ đang dùng ở Hub).
2. Bỏ khối "Phạm vi / Tác động sổ kho" ở đầu; thay bằng một dòng chú thích cuối màn "Thay đổi chính sách không làm đổi số tồn." **(mới)**.
3. Bỏ ô chọn "Nguồn áp dụng": ngưỡng tồn **luôn theo sản phẩm** (062); cận hạn có **mặc định** + **danh sách sản phẩm có chính sách riêng** (063).

*SCR-062 Ngưỡng tồn* (web chính, K7)

4. **Bảng sản phẩm** (dữ liệu = sản phẩm của BJ-01): cột Sản phẩm (tên + mã) · ĐVT · Khả dụng · "Ngưỡng cảnh báo" · "Mức tồn mục tiêu" · "Chỉ báo" (badge sau khi áp giá trị đang gõ). Hai cột ngưỡng là ô số **sửa tại dòng**. Lọc "Tất cả 5 · Chưa có ngưỡng 1" **(mới)**. Dòng đã sửa có chấm đánh dấu; dòng sai hiện lỗi dưới ô "Mục tiêu phải lớn hơn hoặc bằng ngưỡng." **(mới)**.
5. Chân: phụ "Huỷ thay đổi" **(mới)** | chính **"Lưu thay đổi ({n})" (mới)** — tắt khi chưa sửa gì hoặc còn dòng sai.
6. Bấm lưu → **sheet tác động** (thay màn 064): "Lưu {n} thay đổi?" **(mới)**; danh sách ngắn "Oxytetracycline LA: chưa có → 30 / 60 chai"; dòng tác động cụ thể "Tồn thấp: 1 → 2 sản phẩm" **(mới)**; "Thay đổi chính sách không làm đổi số tồn."; "Huỷ" | "Lưu chính sách" (giữ). Lưu xong: đóng sheet, **toast "Đã lưu chính sách · Lần {N}" (mới)**, ở lại bảng (chỉ báo cập nhật).
7. **iPhone:** bảng thành danh sách (tên · "Ngưỡng 30 · Mục tiêu 80 chai" hoặc "Chưa có ngưỡng"); chạm dòng → sheet sửa 2 ô của sản phẩm đó → "Lưu" (lưu thẳng, toast).
8. **Một sản phẩm** (vào từ BJ-01 SCR-003): app bar tiêu đề = tên sản phẩm, phụ đề "Ngưỡng tồn" ; thân = khả dụng hiện tại + 2 ô (đơn vị ở hậu tố ô) + dòng xem trước chỉ báo "Sau khi lưu: Tồn thấp" **(mới)**; chân "Lưu"; lưu → toast → về SCR-003 (lối ra cũ `capExit`). Không có sheet (một sản phẩm, đổi lại được).

*SCR-063 Cận hạn*

9. Khối "Mặc định cho mọi sản phẩm" **(mới)**: "Số ngày cận hạn" (hậu tố "ngày") + "Hành động" là **hai thẻ lựa chọn lớn**: "Cảnh báo" — "Vẫn bán, hiện cảnh báo trên lô." **(mới)** / "Chặn bán" — "Không bán lô cận hạn." **(mới)**.
10. Khối "Sản phẩm có chính sách riêng" **(mới)**: bảng (web) / danh sách (iPhone) Sản phẩm · Số ngày · Hành động · "Dùng mặc định" **(mới)** (bỏ ghi đè, quay về mặc định — OP-03); nút "Thêm sản phẩm" **(mới)** mở sheet chọn sản phẩm có hạn dùng (chỉ sản phẩm theo lô — CAP-01 §6 "LOT/NONE").
11. Chân "Lưu thay đổi" → toast như 6 (một chính sách, không cần sheet).

*SCR-064 Rà soát* → bỏ màn, thành **sheet tác động** ở 062 (mục 6). Trạng thái cũ: `READY` → sheet; `VALIDATION_ERROR` → lỗi tại dòng; `APPROVAL_REQUIRED` → chế độ chỉ xem (mục 12); `PERMISSION_DENIED` → 062 PERMISSION_DENIED.

12. **Ai sửa được:** `is_owner` hoặc role `store_owner` (như quy tắc duyệt T7-P mục 2); nhân viên mở được, **chỉ xem**: ô khoá, banner K1 "Chỉ chủ cửa hàng thay đổi được chính sách." **(mới)**, không có nút lưu. Không có luồng duyệt cho CAP-01.

*SCR-065 Kết quả cập nhật* — chỉ còn cho trường hợp không thành công ngay: `UNKNOWN` → K3 (giữ "Không lưu lại thay đổi"); `REJECTED_EXECUTION` → K4 cảnh báo "Chưa cập nhật chính sách" + "Quay lại chính sách" **(mới)**; `PERMISSION_DENIED` → K1. `COMPLETED` không còn là màn (toast).

*Nối với BJ-01* (sửa nhỏ `bj01.js`)

13. SCR-003, sản phẩm "Chưa có ngưỡng tồn": dòng chú thích hiện có kèm nút phụ **"Đặt ngưỡng tồn"** (cùng chữ với BJ-12 071) → 062 một sản phẩm. Sản phẩm đã có ngưỡng: trong thẻ số / dòng ngưỡng, liên kết "Sửa ngưỡng" **(mới)** → cùng màn.

### 0.5 Trạng thái (sau thiết kế lại)

| Màn | Trạng thái | Hiện gì | Làm được gì | Lối ra |
|---|---|---|---|---|
| 062 bảng | READY | bảng / danh sách, lọc | sửa tại dòng, "Lưu thay đổi (n)" | Quay lại / thanh chọn |
| 062 bảng | VALIDATION_ERROR | lỗi tại dòng sai | sửa | — |
| 062, 063 | LOCKED | K1 khoá: chỉ xem, vì sao | — | Quay lại |
| 062, 063 | CONFLICT | K1 dữ liệu cũ + "Tải lại" | "Tải lại" | Quay lại |
| 062, 063 | chỉ xem (nhân viên) | K1 "Chỉ chủ cửa hàng…", ô khoá | — | Quay lại |
| 062, 063, 065 | PERMISSION_DENIED | K1 | — | "Về Kho" |
| 062 một SP | READY / VALIDATION_ERROR | 2 ô + xem trước chỉ báo | "Lưu" | Quay lại (về SCR-003) |
| 063 | READY / VALIDATION_ERROR | mặc định + danh sách riêng | "Lưu thay đổi", "Thêm sản phẩm", "Dùng mặc định" | Quay lại |
| 065 | UNKNOWN | K3 | "Chuyển sang xác minh" | Về Kho |
| 065 | REJECTED_EXECUTION | K4 cảnh báo | "Quay lại chính sách" | Về Kho |

### 0.6 Khuôn dùng lại (không dựng mới)

K1 (`k1Locked`, `k1Stale`, `k1Denied`), K3 (`k3Unknown`), K4 (`k4Result`), K7 (`k7Table`, `k7FilterChips`, lớp `k7-wide`). Thêm vào `shared-patterns.js` ba hàm dùng chung mới (BJ sau cũng cần):

- `k7EditCell({ value, attr, unit, error, label })` — ô số trong bảng có hậu tố đơn vị, lỗi dưới ô, `aria-label` (BJ-08 đếm, BJ-13 cũng cần).
- `dsSegmented({ items, value, attr })` — thanh chọn hai / ba mục (`VSegmentedControl`). Hiện chỉ có bản cục bộ `.cf-segmented` của BJ-15 với CSS khoá theo `body[data-active-uif="UIF-15"]` (`components.css:2578–2582`): chép giá trị sang lớp chung `.ds-segmented` / `.ds-segment`, **không** sửa BJ-15 (BJ-15 chuyển sang khi tới lượt, chặng 6).
- `dsChoiceRow({ title, subtitle, selected, attrs })` — dòng chọn có nút tròn (thẻ lựa chọn lớn). Hiện là `io06SelectionRow` của BJ-06 (`bj06.js:196`) với CSS khoá theo `UIF-06` (`screens.css:3236–3248`): chép sang lớp chung `.ds-choice-row` / `.ds-radio`, không sửa BJ-06 (chặng 3).

### 0.7 Không đổi

Quy tắc CAP-01 ở 0.1; chữ: "Ngưỡng cảnh báo", "Mức tồn mục tiêu", "Số ngày cận hạn", "Hành động", "Cảnh báo", "Chặn bán", "Lưu chính sách", "Lần {N}", "Chưa có ngưỡng tồn", "Chính sách tồn & cận hạn"; chỉ báo của BJ-01 tính như cũ (chỉ đọc giá trị ngưỡng mới).

### 0.8 Kiểm (bước D)

- Golden mobile / web được khác: `CAP-01_*`, `SC_cap*`, ca BJ-01 có Oxytetracycline LA ở SCR-003 (nút "Đặt ngưỡng tồn"), `SCR-064` mất; ca khác khớp mốc sau BJ-01.
- Kịch bản mới: `SC_cap_table` (sửa Oxy → lưu → sheet → toast → lọc "Chưa có ngưỡng 0"), `SC_cap_single` (BJ-01 Oxy → "Đặt ngưỡng tồn" → lưu → về SCR-003 thấy "Tồn thấp"), `SC_cap_expiry` (đổi mặc định, thêm sản phẩm riêng, "Dùng mặc định"), `SC_cap_staff` (`entry=staff` chỉ xem), **`SC_journey_1`** (mục 4.5).

### 0.9 Ước lượng C–E

~1,25 ngày (C ~0,75; D ~0,25; E ~0,25).

### 0.10 Đã chốt khi duyệt brief (2026-10-21)

| # | Điểm | Chốt |
|---|---|---|
| a | Ngưỡng tồn chỉ đặt theo từng sản phẩm; bỏ ô "Nguồn áp dụng" ở màn tồn (OP-01) | Theo từng sản phẩm |
| b | Bỏ màn Rà soát 064 → sheet tác động khi lưu bảng; lưu một sản phẩm thì lưu thẳng | Thành sheet tác động |
| c | Lưu thành công ở lại màn + toast; SCR-065 chỉ còn cho chưa rõ / bị từ chối | Ở lại màn + toast |
| d | Nhân viên chỉ xem chính sách; bỏ trạng thái "Cần người có quyền xác nhận" (không có luồng duyệt cho CAP-01) | Chủ cửa hàng sửa, nhân viên chỉ xem |

---

## 1. Mục tiêu

1. Owner đặt ngưỡng cho nhiều sản phẩm một lượt trên web, thấy ngay tác động lên chỉ báo, lưu một lần.
2. Đặt / sửa ngưỡng một sản phẩm ngay từ chi tiết tồn (BJ-01), quay lại thấy chỉ báo đổi.
3. Cận hạn: mặc định + sản phẩm riêng, có lối vào.
4. Chặng 1 chạy một mạch: `SC_journey_1`.

## 2. Chuẩn bị

1. Máy chủ `python3 -m http.server 8765 --bind 127.0.0.1 &`.
2. Mốc = mốc **sau BJ-01**: `tools/.golden-bj01-after` (mobile) và `tools/.golden-bj01-web-after` (web) — chụp ở bước D của BJ-01; nếu chưa có, chụp ngay bây giờ trước khi sửa và so khớp với HEAD.

## 3. Bước C — dựng

### 3.1 Dữ liệu (`app/cap01.js`)

1. Sản phẩm = `bj01Products` (khai báo ở `bj01.js`, nạp trước `cap01.js`). Không chép fixture.
2. Bản nháp sửa: `capDraft = {}` (`{ [productId]: { threshold, target } }`); "Huỷ thay đổi" xoá nháp. Lưu: ghi `threshold`, `target` vào phần tử `bj01Products` và đặt `monitoringConfigStatus = "CONFIGURED"`; `capPolicyRevision += 1`.
3. Cận hạn: giữ `capNearExpiryDays`, `capNearExpiryAction` làm mặc định; thêm `capExpiryOverrides = [{ productId:"INV-TYLO", days:60, action:"BLOCK_SALE" }]` (một dòng mẫu); "Thêm sản phẩm" chỉ liệt kê sản phẩm `tracking === "LOT"`.
4. Chế độ: `capMode` = `"table"` | `"single"`; `capProductId` khi `single`. Vai: **`currentActor()==="staff"`** (vai mới cho nhân viên, `?entry=staff`) → chỉ xem; mọi vai khác (`module` mặc định, `owner`, `approver`) → sửa được, nên golden cũ không đổi chế độ. Thêm `entryTargets["CAP-01"].staff = { screen:"SCR-062", state:"READY" }`.
5. Bỏ: `capStockSource`, `capNearExpirySource`, `capSelect` cho nguồn, `cap01InfoGroup("Phạm vi"…)`, `render064CAP01` (thay bằng sheet) — `grep` chỗ dùng trước khi xoá.

### 3.2 Màn

| Màn | Việc |
|---|---|
| Chung | `appShell({ title:"Chính sách tồn & cận hạn", extraClass:"k7-wide", … })` (chế độ một sản phẩm: title = tên SP, subtitle "Ngưỡng tồn"); thanh chọn `dsSegmented({ items:[["SCR-062","Ngưỡng tồn"],["SCR-063","Cận hạn"]], value:activeScreenId, attr:"data-cap-tab" })` → `navigate` (ẩn ở chế độ một SP); chú thích cuối "Thay đổi chính sách không làm đổi số tồn." |
| 062 bảng | `k7FilterChips` ("Tất cả" / "Chưa có ngưỡng" + số); `k7Table` cột ở brief 0.4 mục 4, hai ô `k7EditCell` (`data-cap-threshold="{id}"`, `data-cap-target="{id}"`, đơn vị = `stockUom`), cột Chỉ báo dùng `bj01Indicators` trên bản đã áp nháp; mobile `mobileRow` = dòng + `data-cap-edit-row="{id}"` mở sheet sửa. Chân: "Huỷ thay đổi" \| "Lưu thay đổi ({n})" (`data-cap-open-save`, tắt khi n=0 hoặc có lỗi) |
| Sheet tác động | `ds24Sheet` "Lưu {n} thay đổi?": danh sách đổi ("{tên}: {cũ} → {ngưỡng} / {mục tiêu} {ĐVT}", "chưa có" khi trước đó chưa có), dòng "Tồn thấp: {a} → {b} sản phẩm" (đếm `LOW` trước / sau), chú thích không đổi số tồn; "Huỷ" \| "Lưu chính sách" (`data-cap-save`) |
| 062 một SP | thân: dòng "Khả dụng {n} {ĐVT}"; 2 ô (`cfField` / `capNumberField` có hậu tố ĐVT, lỗi tại ô); dòng "Sau khi lưu: {chỉ báo hoặc 'Không có cảnh báo'}"; chân "Lưu" (`data-cap-save-single`) |
| 063 | khối mặc định (ô ngày + hai `dsChoiceRow` `data-cap-expiry-action="WARN"\|"BLOCK_SALE"`); khối riêng: `k7Table` (web) / danh sách (mobile) + "Dùng mặc định" (`data-cap-override-remove="{id}"`) + "Thêm sản phẩm" (`data-cap-override-add` → sheet chọn) ; chân "Lưu thay đổi" (`data-cap-save-expiry`) |
| Chỉ xem | `currentActor()==="staff"`: `k1Locked({ title:"Chỉ chủ cửa hàng thay đổi được chính sách.", description:"Bạn có thể xem các mức hiện tại." })` ở đầu, mọi ô `disabled`, không chân |
| LOCKED / CONFLICT / PERMISSION_DENIED | `k1Locked` / `k1Stale({ actionLabel:"Tải lại" })` / `k1Denied` |
| 065 | `UNKNOWN` → `k3Unknown({ operation:"Cập nhật chính sách tồn", … })`; `REJECTED_EXECUTION` → `k4Result({ kind:"warning", title:"Chưa cập nhật chính sách", next:[{ label:"Quay lại chính sách", attr:'data-cap-tab="SCR-062"', primary:true }] })`; `PERMISSION_DENIED` → K1; `COMPLETED` (mở bằng URL cũ) → chuyển sang 062 + toast (alias) |

### 3.3 Sự kiện

1. `input` trên `data-cap-threshold` / `data-cap-target` → cập nhật `capDraft`, render lại **chỉ ô lỗi và cột chỉ báo của dòng** hoặc `renderAppScreen()` (giữ con trỏ: lưu `selectionStart` rồi trả lại sau render, như các BJ có ô số khác).
2. `data-cap-save` → áp nháp, `capPolicyRevision++`, đóng sheet, `showToast(\`Đã lưu chính sách · Lần ${capPolicyRevision}\`)`, `renderAppScreen()`.
3. `data-cap-save-single` → áp cho một SP, toast, `capExit()` (về `capReturnFlow` / `capReturnScreen` = UIF-01 / SCR-003).
4. `data-cap-tab` → `navigate(…)` giữ `capMode="table"`.
5. Lối vào từ BJ-01: hàm `capOpenForProduct(id)` (export qua `window.__VET45_QA__` và gọi thẳng từ `bj01.js`): `capMode="single"; capProductId=id; capReturnFlow="UIF-01"; capReturnScreen="SCR-003"; activeFlowId="CAP-01"; activeScreenId="SCR-062"; stateByScreen["SCR-062"]="READY"; syncReviewUrl(); render();`.
6. Từ BJ-12 071 "Đặt ngưỡng tồn" (`go-policy`, plan BJ-12 4.3): `capMode="table"`, `capReturnFlow="UIF-12"`, `capReturnScreen="SCR-071"`.

### 3.4 `app/bj01.js` (sửa nhỏ)

SCR-003: sản phẩm `NOT_CONFIGURED` → cạnh dòng "Chưa có ngưỡng tồn" thêm nút phụ "Đặt ngưỡng tồn" `data-bj01-set-threshold`; sản phẩm đã có ngưỡng → liên kết "Sửa ngưỡng" cùng thuộc tính ở chỗ hiện ngưỡng. Click → `capOpenForProduct(bj01SelectedProductId)`.

### 3.5 Kịch bản golden (`tools/golden.mjs`)

Các kịch bản ở brief 0.8, viết như `SC_bj01_*`. **`SC_journey_1`** (hết chặng 1), bắt đầu `?mode=theme&app=inventory&activation=pending&entry=owner`:

| Bước | Thao tác | Thấy |
|---|---|---|
| 0 | — | Home Kho, khối "Kho chưa kích hoạt", 4 nút nhanh tắt |
| 1 | "Khởi tạo tồn kho" | 066 READY "Cần chuẩn bị" |
| 2 | "Bắt đầu" | 067 |
| 3 | "Kiểm tra dữ liệu" | 068 READY, nút "Ghi nhận số dư đầu kỳ" |
| 4 | "Ghi nhận số dư đầu kỳ" | sheet xác nhận |
| 5 | "Ghi nhận" → chờ hết `PROCESSING` | 071 COMPLETED, "Chủ cửa hàng (tự duyệt)" |
| 6 | "Xem tồn kho" | BJ-01 SCR-001, Oxytetracycline LA "Chưa có ngưỡng tồn" |
| 7 | dòng Oxytetracycline LA | SCR-003, nút "Đặt ngưỡng tồn" |
| 8 | "Đặt ngưỡng tồn" → gõ 30 / 60 → "Lưu" | toast, về SCR-003, badge "Tồn thấp" (26 ≤ 30) |
| 9 | Quay lại → Home Kho (thanh bên "Kho" trên web / nút quay lại trên mobile) | Home Kho **không còn** khối chưa kích hoạt; 4 nút nhanh bật |

Chạy ở cả hai khung (`DEVICE=web` thêm `SC_journey_1@web`: bật cho riêng kịch bản này trong `golden.mjs` — `SC_*` đang bị bỏ khi `WEB`, thêm danh sách cho phép `WEB_SCENARIOS = ["SC_journey_1"]`).

## 4. Bước D — kiểm

1. Golden mobile / web so mốc mục 2: chỉ ca ở brief 0.8 khác; ghi vào mục 8.
2. Bấm thử CAP-01 + UIF-01 SCR-003 ở hai khung: 0 lỗi JS.
3. `/impeccable audit` CAP-01: ô số trong bảng có nhãn (`aria-label="Ngưỡng cảnh báo — {tên}"`), thẻ lựa chọn đi được bằng bàn phím, vùng chạm ≥ 44 trên mobile.
4. **Hết chặng 1:** `SC_journey_1` 0 lỗi, ở cả hai khung; Home Kho đã nối lối vào của BJ-12 (khối chưa kích hoạt), BJ-01 ("Tra cứu tồn"), CAP-01 (Thiết lập kho) — T7-P mục 4.2b.
5. Gửi ảnh: 062 bảng web + sheet tác động, 062 một SP trên iPhone, 063 web, chỉ xem (nhân viên), `SC_journey_1` bước 0 / 5 / 8 / 9.
6. Mốc mới (cho chặng 2): `tools/.golden-chang1`, `tools/.golden-chang1-web`.

## 5. Bước E — ghi lại

1. `CHANGELOG.md` `[5.7.0] — CAP-01 thiết kế lại; hết chặng 1 (SC_journey_1)`; phiên bản 5.7.0.
2. Viết lại theo `_TEMPLATE.md`: SCR-062 (bảng + một SP), SCR-063, SCR-065 (còn UNKNOWN / REJECTED_EXECUTION / PERMISSION_DENIED); SCR-064 → `RETIRED.md` ("Thay bằng sheet tác động trong SCR-062", v5.7.0), xoá file, sửa link. Không có UIF riêng cho CAP-01 (capability) — thêm mục "Lối vào" vào SCR-062.
3. `INDEX.md`: 062–065; T7-P mục 5 (K7 thêm `k7EditCell`), mục 6 (thanh chọn, bảng sửa tại dòng), mục 13 (chữ mới), mục 14: CAP-01 ✅ và **`SC_journey_1` ✅**.
4. Sửa đặc tả: CAP-01 §6 không đổi; SCR-062/063 bỏ "nguồn default/override" ở màn tồn (ngưỡng tồn theo sản phẩm, OP-01).
5. `python3 tools/sync-registry.py`.

## 6. Không làm

- Tính lại chỉ báo cận hạn của lô khi đổi số ngày (fixture lô của BJ-01 giữ nguyên; ghi chú trong CHANGELOG).
- Nhập ngưỡng hàng loạt bằng tệp; ngưỡng theo nhiều kho (Phase 1 một kho).
- Luồng duyệt cho chính sách.

## 7. Rủi ro

| Rủi ro | Cách xử lý |
|---|---|
| Ô số trong bảng mất con trỏ khi render lại mỗi lần gõ | Giữ `selectionStart` / focus theo `data-*` sau render (cách các ô số BJ khác đang làm) hoặc chỉ cập nhật ô / cột liên quan |
| CAP-01 ghi vào `bj01Products` làm golden BJ-01 khác khi chạy chung | Mỗi ca golden tải trang mới (trạng thái reset); chỉ `SC_cap_single`, `SC_journey_1` thấy giá trị mới |
| Bỏ `capStockSource` lệch Screen Contract cũ | Ghi ở E mục 4 |

## 8. Ghi chú khi làm

(Bạn ghi lệch plan, ca golden khác ngoài dự kiến.)

## 9. Chữ trên màn

| Vị trí | Chữ |
|---|---|
| Thanh chọn | "Ngưỡng tồn" · "Cận hạn" |
| Chú thích | "Thay đổi chính sách không làm đổi số tồn." |
| 062 bảng | cột "Sản phẩm", "ĐVT", "Khả dụng", "Ngưỡng cảnh báo", "Mức tồn mục tiêu", "Chỉ báo" · lọc "Tất cả", "Chưa có ngưỡng" · lỗi "Mục tiêu phải lớn hơn hoặc bằng ngưỡng." · "Huỷ thay đổi" · "Lưu thay đổi ({n})" |
| Sheet | "Lưu {n} thay đổi?" · "{tên}: {cũ} → {ngưỡng} / {mục tiêu} {ĐVT}" · "chưa có" · "Tồn thấp: {a} → {b} sản phẩm" · "Huỷ" · "Lưu chính sách" |
| Toast | "Đã lưu chính sách · Lần {N}" |
| 062 một SP | phụ đề "Ngưỡng tồn" · "Khả dụng {n} {ĐVT}" · "Sau khi lưu: {chỉ báo}" / "Sau khi lưu: Không có cảnh báo" · "Lưu" |
| 063 | "Mặc định cho mọi sản phẩm" · "Cảnh báo" / "Vẫn bán, hiện cảnh báo trên lô." · "Chặn bán" / "Không bán lô cận hạn." · "Sản phẩm có chính sách riêng" · "Dùng mặc định" · "Thêm sản phẩm" · "Lưu thay đổi" |
| Chỉ xem | "Chỉ chủ cửa hàng thay đổi được chính sách." · "Bạn có thể xem các mức hiện tại." |
| 065 | "Chưa cập nhật chính sách" · "Quay lại chính sách" |
| BJ-01 SCR-003 | "Đặt ngưỡng tồn" · "Sửa ngưỡng" |

## 10. Review

(Phiên review điền sau khi bạn báo xong.)
