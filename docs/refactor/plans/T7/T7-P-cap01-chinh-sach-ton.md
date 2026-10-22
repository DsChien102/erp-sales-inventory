# T7-P · CAP-01 Chính sách tồn & cận hạn — thiết kế lại (bước B–E) + `SC_journey_1`

> Theme: Theme 7 Inventory · Trạng thái: Brief ✅ (duyệt 2026-10-21) | Plan C–E ✅ | Làm ✅ 2026-10-21 (v5.7.0, chưa commit) | Review ✅ 2026-10-22 (đạt; R1–R5 xong, v5.7.2)
> Thuộc [T7-P](T7-P-thiet-ke-lai-luong.md) mục 8.2 **chặng 1 "Mở kho"**, BJ thứ ba (cuối chặng). Làm **sau** [BJ-12](T7-P-bj12-ton-dau-ky.md) (dựng K1–K4, K7) và [BJ-01](T7-P-bj01-ton-kho.md). Dùng lại khuôn, không dựng khuôn mới.
> Thiết bị: **cả iPhone và web đều là thiết bị chính** (sửa 2026-10-22, T7-P mục 2) — đặt ngưỡng nhiều sản phẩm một lượt và sửa lẻ một sản phẩm đều phải làm trọn trên cả hai. Plan viết khi còn "web chính"; rà lại 2026-10-22: **đạt cả hai khung**; lỗi nhỏ còn lại sửa ở [plan hotfix T7-HF1](T7-HF1-hai-thiet-bi.md).
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

*SCR-062 Ngưỡng tồn* (K7)

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

(2026-10-21, phiên làm.) Mốc `tools/.golden-chang1` (1440 ca) / `.golden-chang1-web` (603 ca) chụp lại sau chỉnh CSS cuối; so với `.golden-bj01-after` / `.golden-bj01-web-after`: 0 lỗi JS ở cả hai khung.

**Ca golden khác (so mốc sau BJ-01):**
- Dự kiến (brief 0.8): `CAP-01_SCR-062/063/065_*` (SCR-064 mất 4 ca), `SC_cap01_*` → `SC_cap_*`, `SC_journey_1`.
- **Ngoài dự kiến 0.8:** BJ-01 SCR-003 của **Amox 500 / Enrofloxacin 10% / Tylosin 20%** cũng khác (liên kết "Sửa ngưỡng" trong khối cảnh báo, theo 3.4 "ở chỗ hiện ngưỡng"; Nobivac — sản phẩm mặc định — không đổi nên `UIF-01_SCR-003_*` khớp): `SC_bj01_list_5`, `SC_bj01_out_1`, `SC_bj01_receive_1`, `SC_bj01_scan_2`, `SC_bj01_stale_2`, `SC_bj01_theme_2` (Oxy), `SC_bj01_tylo_*`, `SC_bj01_expired_*`.
- Đi qua CAP-01: `SC_bj12_owner_10_policy`, `SC_ws_inventory_2_2_item`, `SC_ws_setup_1_2_item`.
- Web: chỉ `CAP-01_*`, `SC_cap_*`, `SC_journey_1@web` khác.

**Lệch plan / chọn thêm:**
1. `WEB_SCENARIOS` ở `golden.mjs` không chỉ `SC_journey_1` mà thêm `SC_cap_table`, `SC_cap_expiry`, `SC_cap_single`, `SC_cap_staff`, `SC_cap_hub` — bảng sửa tại dòng là web chính nên cần ảnh web.
2. Chữ ngoài brief (đã ghi mục 13): "Bình thường", "Số ngày cận hạn phải lớn hơn 0.", "Không còn sản phẩm nào chưa có ngưỡng" / "Mọi sản phẩm đã có ngưỡng cảnh báo." / "Xem tất cả", "Chưa có sản phẩm nào có chính sách riêng.", "Mọi sản phẩm theo lô đều đã có chính sách riêng."; lỗi dòng dùng một câu "Mục tiêu phải lớn hơn hoặc bằng ngưỡng." cho cả thiếu một ô / ngưỡng âm / xoá hết ô của sản phẩm đã có ngưỡng.
3. Sheet dùng khuôn `bottom-sheet` của BJ-12 (web: hộp thoại giữa màn), không dùng `ds24Sheet` (CSS của `ds24Sheet` khoá theo UIF-01).
4. Nút quay lại: vào từ BJ-01 / BJ-12 → về đó (`capReturnFlow`); vào từ Hub → về Hub Kho (`previousScreen`); chế độ BJ → về Tồn kho như cũ. Vào CAP-01 từ Hub luôn mở bảng, bỏ nháp cũ.
5. 063: ô ngày và hành động của dòng riêng sửa tại dòng (brief chỉ nói bảng / danh sách); "Thêm sản phẩm" lấy số ngày và hành động của mặc định hiện tại. "Lưu thay đổi" chỉ tắt khi có lỗi (không tắt khi chưa sửa).
6. Chưa chạy `/impeccable audit`: kiểm bằng ảnh + DOM — ô số có `aria-label="… — {tên}"`, thẻ lựa chọn là `button` (`role="radio"`, `aria-checked`), hộp thoại `role="dialog"`, ô ≥ 44 trên iPhone (40 ở web). Con trỏ giữ khi gõ (kiểm bằng thử `focus` + `input`). Cần bạn / phiên review xem thêm bằng mắt.
7. Đã chạy `python3 tools/sync-registry.py`. Chưa chạy `detect_changes` của GitNexus (công cụ MCP không có trong phiên này); chưa commit.

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

**Review chặng 1 (BJ-12 + BJ-01 + CAP-01):** (2026-10-21, phiên review) — **đạt có điều kiện**, **đạt hẳn 2026-10-22 sau R5** (xem "R5 xong" cuối mục); R1–R4 và góp ý 1, 2, 4, 5, 6, 9, 10, 12 (+ ghi chú 3) **đã sửa ở phiên review theo yêu cầu người dùng** → prototype **v5.7.1** (xem "Đã sửa" cuối mục). Còn lại trước commit: **R5** (`/impeccable audit`). Chưa commit. Review của BJ-12 và BJ-01 trỏ về đây.

| Kiểm (chạy lại) | Kết quả |
|---|---|
| `node --check app/*.js harness/*.js` | Sạch |
| Golden mobile | 1440 ca, 0 lỗi JS; "Khớp hoàn toàn" với `tools/.golden-chang1` |
| Golden web | 603 ca, 0 lỗi JS; "Khớp hoàn toàn" với `tools/.golden-chang1-web` |
| Bấm thử ngoài golden (Chrome không giao diện) | Tìm ra R1–R4 và góp ý 5–7 dưới đây; 0 lỗi JS |
| Đặc tả | UC-12-02 / BJ-12 / 00-use-case-map: ngoại lệ `is_owner` tự duyệt ghi đúng quyết định 2026-10-20 |
| Ảnh | 068 / 070 / 062 web, 068 iPhone, 063 iPhone, `SC_journey_1_0`: bố cục K7 đúng brief, bảng / danh sách đổi đúng khung |

Lệch plan đã ghi trong ghi chú (BJ-12 mục 10: 1–9; BJ-01 mục 10: 1–9; CAP-01 mục 8: 1–7): **chấp nhận**. BJ-01 lệch 5 (CSS BJ-01 chưa gom về một khối): chấp nhận, để gói dọn CSS riêng ở Giai đoạn 3. `/impeccable audit` chưa chạy ở cả ba BJ → thành bước **R5** dưới đây (chạy trước commit). `detect_changes()` không chạy: chấp nhận như H1 (prototype HTML tĩnh, không phải code được lập chỉ mục).

**Cần sửa (chặn commit):**

- **R1. CAP-01 lưu hai ô trống thành ngưỡng 0 / 0.** Mở Oxytetracycline LA (chưa có ngưỡng) → "Đặt ngưỡng tồn" → để trống cả hai ô → "Lưu" vẫn bật; bấm thì sản phẩm thành `threshold:0, target:0, CONFIGURED`, toast "Đã lưu chính sách", dòng xem trước còn ghi "Sau khi lưu: Không có cảnh báo". Cùng lỗi ở sheet sửa trên iPhone (062 bảng). Nguyên nhân: `capRowError` (`app/cap01.js:44`) trả rỗng khi cả hai ô trống và sản phẩm chưa cấu hình (đúng cho **bảng**, vì dòng đó không "đã sửa"), nhưng `data-cap-save-single` dùng cùng hàm rồi `capApplyValues` đổi `""` thành `0`. Sửa: ở chế độ một sản phẩm / sheet, hai ô trống = chưa nhập → nút "Lưu" tắt và không hiện dòng "Sau khi lưu"; không đổi luật của bảng.
- **R2. Home Kho "chưa kích hoạt" vẫn có việc của kho đang chạy.** Ảnh `SC_journey_1_0` (bước đầu của demo): dưới khối "Kho chưa kích hoạt" vẫn có "Chờ duyệt · 3 nhận hàng", "Lô sắp hết hạn · 3 lô", "Sai lệch cần đối soát", "Nghiệp vụ chưa xác định kết quả" — mâu thuẫn với câu "Nhập số tồn hiện có một lần để bắt đầu nhận…". Sửa trong `app/hub.js`: khi `!inventoryActivated`, nguồn nhận hàng trả `[]` và bỏ ba dòng cố định; "Cần chú ý" chỉ còn hiện khi có nguồn có dòng (vd. số dư đầu kỳ chờ duyệt), không có thì bỏ cả mục. Golden được khác: `HUB_home_not_activated*`, `SC_hub_not_activated_*`, `SC_bj12_owner_0/1`, `SC_bj12_pending_list_0…`, `SC_journey_1_0`.
- **R3. Sản phẩm đã có ngưỡng nhưng bình thường không xem / sửa được ngưỡng ở SCR-003.** Brief 0.4 mục 13: "Sản phẩm đã có ngưỡng: trong thẻ số / dòng ngưỡng, liên kết 'Sửa ngưỡng'". Bản làm chỉ đặt "Sửa ngưỡng" trong khối cảnh báo Hết hàng / Tồn thấp, nên Nobivac DHPPi (ngưỡng 30, mục tiêu 80) không hiện ngưỡng ở đâu và không có lối sửa. Sửa trong `bj01StockHero` (`app/bj01.js`): sản phẩm `CONFIGURED` có thêm một dòng cuối thẻ số "Ngưỡng {n} · Mục tiêu {m} {ĐVT}" + liên kết "Sửa ngưỡng" (`data-bj01-set-threshold`); bỏ liên kết trong khối cảnh báo để mỗi màn chỉ một chỗ. Chữ "Ngưỡng {n} · Mục tiêu {m} {ĐVT}" là chữ của danh sách 062 trên iPhone, không mới. Golden được khác: mọi ca SCR-003 của sản phẩm đã có ngưỡng (`UIF-01_SCR-003_*`, `SC_bj01_*` qua chi tiết). Ghi vào T7-P mục 13 dòng "01 · SCR-003 · Đặt / Sửa ngưỡng".
- **R4. Alias màn đã bỏ không mang trạng thái — lệch Screen Contract.** `SCR-068.md` dòng 46 ghi map trạng thái của SCR-069 cũ (`PENDING_APPROVAL` → SCR-066 `PENDING_APPROVAL`; `CONFLICT`, `VALIDATION_ERROR` → 068 `CONFLICT`…), brief CAP-01 0.4 ghi `APPROVAL_REQUIRED` của 064 → chế độ chỉ xem; prototype mở **068 / 062 `READY`** cho mọi trạng thái (`?uif=UIF-12&screen=SCR-069&state=PENDING_APPROVAL` → 068 READY). Chọn một: (a) làm map trong hai khối alias (`bj12.js:312`, `cap01.js:284`) — đổi cả màn và trạng thái; hoặc (b) sửa `SCR-068.md` / `SCR-062.md` thành "link cũ mở màn mới ở trạng thái mặc định". Đề xuất (b): link cũ chỉ có trong harness, không đáng thêm mã.

**Góp ý nhỏ (không chặn, sửa khi tiện):**

1. **Nhân viên trên iPhone (062):** dòng danh sách vẫn có mũi tên nhưng chạm không làm gì (`cap01.js:346` thoát im lặng). Khi chỉ xem dùng `type:"Status"` (không mũi tên). BJ-01 SCR-003 cũng hiện "Đặt ngưỡng tồn" / "Sửa ngưỡng" cho `staff` — ẩn khi `currentActor()==="staff"`.
2. **Esc không đóng sheet CAP-01** (BJ-12 đóng được). Thêm `keydown` Escape như `bj12.js:253`, đóng `capSaveOpen` / `capSheetProductId` / `capAddOpen`.
3. **Rời 062 khi còn nháp:** nút quay lại đi luôn, không hỏi; nháp nằm ngầm và mất khi vào lại từ Hub. Prototype để vậy được; ghi vào SCR-062 mục trạng thái cho Flutter: có nháp mà rời màn → hộp thoại "Bỏ thay đổi?" (chữ chờ duyệt ở mục 13).
4. **062 web:** ô chữ (Sản phẩm, ĐVT, Khả dụng) căn trên còn ô nhập căn giữa → hàng lệch; `.k7-table td { vertical-align: middle }`.
5. **Sheet trên web** (hộp thoại giữa màn) vẫn có thanh kéo và đáy trống ~40px: ẩn `.sheet-handle` và bỏ đệm đáy trong `.device-preview.is-web`.
6. **070 "Cần chú ý":** "Sau khi duyệt — Kho bắt đầu hoạt động" mang icon cảnh báo; đây là thông tin → icon `info`, chỉ "Không bán được" giữ cảnh báo.
7. **Chip có số hai cách:** BJ-01 dùng `ds24Chip(…, count)` (số tách `<span>`, số 0 → `is-empty`), `k7FilterChips` nhét số vào chữ và tự thêm `k7-chip--zero`. Gộp: `k7FilterChips` gọi `ds24Chip(key, label, selected, attrName, count)`; bỏ `k7-chip--zero`.
8. **068 lệch số kiểm soát:** "Chọn lại tệp" và "Sửa số kiểm soát" cùng `back-file`. Nút chính nên mở 067 và đặt focus vào ô "Tổng số lượng kiểm soát".
9. **063 iPhone:** ô chọn hành động của dòng riêng không có mũi tên, trông như ô chữ — dùng `cfSelect` (có `chevronDown`).
10. **Đường nhân viên lập BJ-12 không đi được trong chế độ Toàn Theme 7** (mọi lối vào Hub đặt vai `owner`; `SC_bj12_pending_list` phải gọi `setActor('module')`). Chấp nhận cho prototype; ghi một dòng trong UIF-12 mục lối vào.
11. **Fixture hành trình:** tệp đầu kỳ có Enrofloxacin 3 chai "Hư hỏng" nhưng BJ-01 ngay sau khởi tạo ghi tồn vật lý 0; nguồn "Nguồn và thời điểm cập nhật" vẫn là "Nhận hàng PN-…" thay vì số dư đầu kỳ. Không chặn; gộp fixture khi làm chặng 2 (BJ-02 đọc cùng sản phẩm).
12. **Registry:** `09.generated/registries/design/screen-registry.md` dòng 70 còn `SCR-064 … RENDERED_v3.6.0` (SCR-069 đã `RETIRED_v5.5.0`); `data/workbench-data.js` hành động `ACT-12-CONFIGURE` còn `SCR-064` trong `screen_ids`. Sửa nguồn rồi chạy lại `sync-registry.py`.

- **R5. `/impeccable audit` cho cả chặng 1 (chặn commit).** Máy chủ `python3 -m http.server 8765 --bind 127.0.0.1` trong `html/`; chạy `/impeccable audit` phạm vi Hub Kho (cả `activation=pending`), UIF-12 (066–071), UIF-01 (001, 003 + sheet lô / quét / nguồn), CAP-01 (062 bảng + một sản phẩm, 063, 065), ở **cả hai khung** (`viewport=web`). Đạt khi: chữ ≥ 4,5:1 (chữ lớn / icon ≥ 3:1), vùng chạm ≥ 44 × 44 ở khung iPhone, mọi nút icon và ô số có `aria-label`, đi được bằng bàn phím trên web (Tab qua chip lọc và ô bảng, Enter mở sheet, Esc đóng sheet ở cả BJ-12 và CAP-01, focus về nút đã mở sheet). Lỗi tìm được: sửa ngay nếu nằm trong `shared-patterns.js` / màn của chặng 1; còn lại ghi thành dòng trong mục này. Xong: golden so `tools/.golden-chang1*`, chụp lại mốc nếu có sửa, CHANGELOG `[5.7.2]` nếu có sửa.

**Đã sửa (2026-10-21, phiên review, v5.7.1):** R1 (`capSingleEmpty` / `capSingleBlocked` ở `cap01.js`), R2 (`hub.js`: kho chưa kích hoạt chỉ còn "Chờ duyệt" của nguồn có dòng), R3 (`bj01StockHero` dòng "Ngưỡng {n} · Mục tiêu {m} {ĐVT}" + "Sửa ngưỡng"; bỏ liên kết trong khối cảnh báo; ẩn với `staff`), R4 theo cách (b) — SCR-068 / SCR-062 / UIF-12 ghi "link cũ mở màn mới ở trạng thái mặc định". Góp ý 1, 2, 4, 5 (hộp thoại web: luật `!important` đè luật sheet iPhone — trước đó cả `width: 480px` cũ của K7 cũng không ăn), 6 (`k2Decision` nhận tone thứ ba `"info"`), 9, 10 (UIF-12 mục lối vào), 12; ghi chú 3 vào SCR-062 cho Flutter. **Chưa làm:** 7 (gộp hai cách chip có số — đổi hình chip ở BJ-12 / CAP-01, để làm cùng chip BJ-15 ở chặng 6), 8 (focus ô số kiểm soát), 11 (fixture — gộp ở chặng 2). Kiểm: `node --check` sạch; golden 1440 / 603 ca, 0 lỗi JS, chỉ ca nêu ở CHANGELOG `[5.7.1]` khác mốc cũ; bộ bấm thử của review chạy lại: R1–R4, Esc, nhân viên đều đạt. Mốc `tools/.golden-chang1*` đã chụp lại (v5.7.1); `sync-registry.py` đã chạy.

**R5 xong (2026-10-22, phiên review, v5.7.2):** đo bằng Chrome headless qua CDP (script tạm ở scratchpad, không vào repo) trên 30 màn / trạng thái ở mỗi khung, gồm sheet tự duyệt / từ chối (BJ-12), sheet lưu (CAP-01), sheet lô / nguồn / quét (BJ-01).

| Tiêu chí | Kết quả |
|---|---|
| Tương phản chữ ≥ 4,5:1 (lớn ≥ 3:1) | 0 lỗi ở cả hai khung (bộ đo thử với chữ #bbb → 1,8:1, có bắt) |
| Vùng chạm ≥ 44 × 44 (iPhone) | Đạt. Chip lọc BJ-01 cao 34px nhưng `::after` mở rộng 5px mỗi phía = 44px |
| Nhãn nút icon / ô số / ô nhập | Thiếu: ô "Lý do từ chối" → **đã sửa** (`icTextarea` có `aria-label`); `ds24Sheet` thêm `aria-label` = tiêu đề |
| Esc đóng sheet | BJ-12, CAP-01 đạt; **BJ-01 không đóng → đã sửa** (`bj01.js` keydown) |
| Focus vào sheet khi mở / về nút đã mở khi đóng | **Không có → đã sửa** chung ở khung: `syncDialogFocus()` cuối `renderAppScreen` (`core.js`), hộp thoại `tabindex="-1"` không vòng focus. Đo lại: 5/5 sheet đạt ở web; iPhone 4/5 (CAP-01 062: nút lưu của bảng ẩn trên iPhone — không phải đường dùng thật) |
| Tab trên web | Có vòng focus ở thanh chọn, chip, dòng danh sách; ô số bảng có viền `:focus-within` |

Golden mobile 1440 / web 603 ca **khớp hoàn toàn** `tools/.golden-chang1*` → không chụp lại mốc; 0 lỗi JS; `node --check` sạch; CHANGELOG `[5.7.2]`; `sync-registry.py` đã chạy. Ngoài phạm vi (ghi lại): BJ-02 sheet từ chối chèn DOM ngoài `renderAppScreen` nên chưa có focus tự động — làm ở chặng 2 (plan BJ-02 mục 5.1). **Chặng 1 xong review; còn commit.**

Commit theo thứ tự trong ba plan (BJ-12 3 commit → BJ-01 2 → CAP-01 2) hoặc gộp theo chặng — cây làm việc đang chung; phần sửa v5.7.1 đi cùng commit CAP-01 (C+D).
