# T7-P · BJ-01 Tồn kho & khả dụng — dựng thiết kế mới (bước C–E)

> Theme: Theme 7 Inventory · Trạng thái: Plan ✅ (rà lại theo code sau Giai đoạn 1 + H1 + plan BJ-12: 2026-10-21) | Làm ✅ 2026-10-21 (v5.6.0, chưa commit) | Review ✅ 2026-10-22 (đạt; R1–R5 xong, v5.7.2 — [plan CAP-01 mục 10](T7-P-cap01-chinh-sach-ton.md#10-review))
> Thuộc [T7-P](T7-P-thiet-ke-lai-luong.md). Brief đã duyệt 2026-10-16: mục 0 của plan này. Bước A đã xong (`app/bj01.js`).
> Ước lượng: **~1–1,5 ngày, 2 commit** (C+D; E). Làm **sau** [dọn tài liệu 7.1](T7-P-doc-don-tai-lieu.md) (bước E dùng khuôn ở đó) **và sau BJ-12** — 2026-10-20 Giai đoạn 2 sắp theo chặng hành trình, BJ-01 là BJ thứ hai của chặng 1 "Mở kho" ([T7-P mục 8.2](T7-P-thiet-ke-lai-luong.md)); K1 dựng ở BJ-12 (`app/shared-patterns.js`), plan này dùng lại. Thiết bị chính: **iPhone**; web phải dùng được (T7-P mục 2). Phiên bản đích **5.6.0** (BJ-12 = 5.5.0, CAP-01 = 5.7.0).
> Người làm: bạn. Review: phiên plan / review.

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/` nếu không ghi khác. Câu trong ngoặc kép là chữ hiển thị, chép nguyên văn.

## 0. Brief (bước B, đã duyệt 2026-10-16)

**Việc thật**

- Nhân viên, giữa lúc có khách: "Còn bao nhiêu? Bán được bao nhiêu?" → tìm nhanh một sản phẩm, nhìn một con số.
- Owner, đầu ngày hoặc trước khi đặt hàng: "Cái gì hết hoặc sắp hết? Lô nào cận hạn, hết hạn?" → lọc theo vấn đề rồi làm việc tiếp: nhập thêm (BJ-02) hoặc xử lý lô (BJ-09).

**Luồng hiện tại** (ảnh: `tools/.golden-phase1/UIF-01_SCR-001_READY.png`, `SC_bj01_list_5_product.png`, `SC_bj01_detail_4_provenance.png`)

SCR-001 danh sách (dòng ngữ cảnh, ô tìm, 5 chip lọc, dòng sản phẩm) → SCR-003 chi tiết (thẻ sản phẩm, "Khả dụng", 3 số phân rã, lý do không bán được, cảnh báo tồn, lô, nguồn) → sheet lô / sheet nguồn → thẻ kho (BJ-15).

**Vấn đề**

| # | Màn | Vấn đề |
|---|---|---|
| 1 | 001 | Tên bị cắt ("SP-…", "Enrofloxacin 10% · SP-0…") vì mã nằm chung tiêu đề; số khả dụng là chữ phụ xám, nhỏ hơn badge |
| 2 | 001 | 5 chip lọc bị cắt ("Hết h…"), không có số lượng nên không biết lọc có ra gì không |
| 3 | 001 | Danh sách theo thứ tự fixture, không đưa hàng có vấn đề lên đầu |
| 4 | 001 | Ô tìm nói "mã vạch" nhưng không có nút quét |
| 5 | 003 | Tiêu đề chung "Chi tiết tồn kho"; tên sản phẩm nằm trong một thẻ riêng; "Khả dụng" và 3 số phân rã là hai khối lệch lề, chữ "hộp" chạm mép phải |
| 6 | 003 | Cảnh báo "Tồn thấp" nằm dưới cùng; gợi ý nhập thêm chôn trong câu; không có bước tiếp → ngõ cụt |
| 7 | 003 | Lô hết hạn không có lối xử lý |

**Đề xuất**

*SCR-001 Tồn kho*

1. Ô tìm có nút **quét mã vạch** ở cuối (prototype: mở sheet "Đưa mã vạch vào khung", chọn sẵn một sản phẩm mẫu).
2. Chip lọc **kèm số**: Tất cả 5 · Hết hàng 1 · Tồn thấp 1 · Cận hạn 1 · Hết hạn 1; chip có số 0 vẫn hiện nhưng mờ.
3. Ở "Tất cả", sắp theo mức gấp: Hết hàng → Có lô hết hạn → Tồn thấp → Có lô cận hạn → bình thường → chưa có ngưỡng.
4. Dòng sản phẩm: bỏ icon hộp (dòng nào cũng giống nhau); **tiêu đề = tên**, dòng phụ = mã; cột phải = **số khả dụng to, mono** ("106 hộp") với badge tình trạng ngay dưới. Thành phần mới: `VStockRow` (List Row có cột phải hai tầng).

*SCR-003 Chi tiết*

5. App bar: **tiêu đề = tên sản phẩm**, phụ đề = "SP-000184 · hộp". Bỏ thẻ sản phẩm riêng. Dòng "Kho trung tâm · Dữ liệu đến …" giữ, nhỏ, ngay dưới app bar.
6. **Thẻ số chính** một khối: "Khả dụng" lớn (mono) + badge tình trạng; dưới là một hàng 3 số (Tồn vật lý · Đủ điều kiện bán · Đã giữ); nếu có, một dòng "Không đủ điều kiện bán: Cách ly 2 hộp". Sửa lề phải.
7. **Cảnh báo ngay dưới thẻ số**, có việc tiếp: Tồn thấp / Hết hàng → "Gợi ý nhập thêm 38 hộp (mục tiêu 80)" + nút phụ **"Nhận hàng"** (mở BJ-02 nhập nhanh). Có lô hết hạn → nút phụ **"Xử lý lô hết hạn"** (mở BJ-09 với lô đó).
8. Lô sắp theo **HSD gần nhất trước**; sheet lô giữ, thêm nút "Xử lý lô hết hạn" khi lô đã hết hạn.
9. "Nguồn và thời điểm cập nhật" → sheet → "Xem thẻ kho và lịch sử": giữ nguyên.

*Trạng thái* (dùng khuôn K1 đã dựng ở BJ-12 — `k1Loading`, `k1Stale`, `k1Denied`): LOADING = khung xương đúng bố cục; EMPTY / FILTER_EMPTY giữ; STALE = banner + "Làm mới" ngay dưới dòng ngữ cảnh; PERMISSION_DENIED = chuyện gì + làm gì tiếp + nút "Về Kho".

**Không đổi:** quy tắc chỉ báo (Hết hàng / Tồn thấp / cận hạn / hết hạn), ngưỡng (CAP-01), sheet nguồn và chuyển sang thẻ kho.

**Chữ mới cần thêm vào Screen Contract** (T7-P mục 13): "Quét mã vạch", "Gợi ý nhập thêm {n} {ĐVT} (mục tiêu {m})", "Xử lý lô hết hạn", "Về Kho" (ở trạng thái không có quyền), tiêu đề SCR-003 = tên sản phẩm.

**Kiểm (bước D):** golden chỉ khác ở `UIF-01_*`, `SC_bj01_*`, `SC_search_*`, `SC_quick_UIF-01_*`; thêm kịch bản cho chip có số, sắp xếp, nút "Nhận hàng", "Xử lý lô hết hạn", quét mã vạch.

**Ước lượng C–E:** ~1 ngày.

## 1. Mục tiêu

1. **SCR-001 Tồn kho:** tên sản phẩm đọc trọn; số khả dụng là thứ nổi nhất mỗi dòng; chip lọc có số; hàng có vấn đề lên đầu; ô tìm có nút quét mã vạch.
2. **SCR-003 Chi tiết:** tiêu đề là tên sản phẩm; một thẻ số chính; cảnh báo ngay dưới kèm việc tiếp theo ("Nhận hàng" → BJ-02, "Xử lý lô hết hạn" → BJ-09); lô sắp theo HSD gần nhất.
3. Dựng **khuôn K1** (trạng thái chung) cho BJ-01: tải, không có quyền, dữ liệu cũ, rỗng.
4. CSS của BJ-01 về một khối; xoá luật cũ không còn dùng.

## 2. Chuẩn bị

1. Máy chủ: `python3 -m http.server 8765 --bind 127.0.0.1 &` trong thư mục `html/`.
2. Mốc = mốc **sau BJ-12** (`tools/.golden-bj12-after`, `tools/.golden-bj12-web-after`, chụp ở bước D của BJ-12). Chụp lại hiện trạng `tools/.golden-bj01-base` và `DEVICE=web … tools/.golden-bj01-web-base`, so với hai mốc đó → "Khớp hoàn toàn". Không chụp lại mốc giữa gói.
3. Đọc lại brief (mục 0) và bảng chữ mục 9 của plan này.

## 3. Bước C — dựng

### 3.1 `app/core.js` — thành phần dùng chung (thêm, không đổi hành vi cũ)

Đặt cạnh các helper `ds24*` hiện có.

**a. Icon quét mã.** Trong `const icons = {…}` thêm khoá `scan`:

```js
scan: '<path d="M3 7V5a2 2 0 0 1 2-2h2"/><path d="M17 3h2a2 2 0 0 1 2 2v2"/><path d="M21 17v2a2 2 0 0 1-2 2h-2"/><path d="M7 21H5a2 2 0 0 1-2-2v-2"/><path d="M8 7v10"/><path d="M12 7v10"/><path d="M16 7v10"/>',
```

Trong `dsIconMap` thêm `scan: "VIcons.barcodeScanner"`.

**b. `ds24Search` nhận nút cuối ô** (tham số thứ tư, mặc định rỗng — chỗ gọi cũ không đổi):

```js
function ds24Search(value, attrs, placeholder = "Tìm kiếm", trailingAction = "") {
  // … giữ nguyên, chỉ thêm ${trailingAction} ngay sau thẻ <input …> trong <label class="ds24-search">
}
```

**c. `ds24Chip` nhận số đếm** (tham số thứ năm, mặc định `null`):

- `count != null` → thêm `<span class="ds24-chip__count">${count}</span>` sau nhãn; `count === 0` → thêm class `is-empty` (vẫn bấm được).

**d. `ds24StockRow` (mới) — thành phần `VStockRow`:**

```js
// VStockRow: List Row không icon đầu, cột phải hai tầng (số lượng mono + badge tình trạng), chevron.
function ds24StockRow({ title, subtitle = "", quantity, badge = "", attrs = "" }) {
  return `<button class="ds24-list-row ds24-list-row--no-leading ds24-stock-row" type="button" ${attrs} data-ds-component="VStockRow" data-ds-prop-type="Navigation"><span class="ds24-list-row__copy"><strong>${esc(title)}</strong><small>${esc(subtitle)}</small></span><span class="ds24-stock-row__value"><strong class="ds24-stock-row__qty">${esc(quantity)}</strong>${badge}</span>${icon("chevronRight", "icon--sm")}</button>`;
}
```

**e. Trạng thái toàn màn (K1):** không thêm helper — dùng `k1Denied`, `k1Loading`, `k1Stale`, `k1ExitAttr` trong `app/shared-patterns.js` (dựng ở BJ-12). Nếu BJ-12 chưa làm xong thì làm BJ-12 trước.

### 3.2 `styles/components.css` — CSS của các thành phần ở 3.1

Thêm một khối `/* ===== Thành phần: search action, chip count, stock row, state ===== */` ở cuối file, chỉ dùng token `--vet45-v2-*`:

| Selector | Yêu cầu |
|---|---|
| `.ds24-search__action` | Nút 44 × 44, không viền, nền trong suốt, màu `--vet45-v2-icon-secondary`; focus có vòng `--vet45-v2-focus-ring` |
| `.ds24-chip__count` | Cỡ 12, đậm 600, chữ số đều (`font-variant-numeric: tabular-nums`), cách nhãn 6px |
| `.ds24-chip.is-empty` | Chữ `--vet45-v2-text-muted`; vẫn có viền như chip thường |
| `.ds24-stock-row` | Kế thừa `.ds24-list-row`; cao tối thiểu 64 |
| `.ds24-stock-row__value` | Cột phải, căn phải, xếp dọc, khoảng cách 4 |
| `.ds24-stock-row__qty` | JetBrains Mono, 16/22, đậm 700, `--vet45-v2-text-primary`; chữ số đều |
| `.skeleton--row` | Cao 64, bo 12 (bổ sung cho `.skeleton-*` sẵn có) |

### 3.3 `app/bj01.js` — SCR-001 Tồn kho

1. **Biến mới:** `let bj01ScanOpen = false;`
2. **Bộ lọc có số** (`bj01SearchAndFilters`):
   - Số mỗi chip đếm trên toàn bộ `bj01Products` (không phụ thuộc ô tìm): `ALL` = tổng; `OUT`, `LOW`, `NEAR`, `EXPIRED` = số sản phẩm có chỉ báo đó (`bj01Indicators`).
   - Gọi `ds24Chip(k, l, bj01Filter === k, "data-bj01-filter", count)`.
   - Ô tìm: `ds24Search(bj01Query, 'data-bj01-search', 'Tên, mã sản phẩm hoặc mã vạch', '<button type="button" class="ds24-search__action" data-bj01-scan aria-label="Quét mã vạch">' + icon("scan", "icon--sm") + '</button>')`.
3. **Sắp xếp** khi `bj01Filter === "ALL"`: theo chỉ báo chính (`bj01PrimaryAttention`) với thứ tự `OUT` → `EXPIRED` → `LOW` → `NEAR` → không có chỉ báo → `NOT_CONFIGURED`; giữ thứ tự fixture trong cùng nhóm. Lọc theo chip khác: giữ thứ tự fixture.
4. **Dòng sản phẩm** dùng `ds24StockRow`:
   - `title` = `p.name` (không kèm mã).
   - `subtitle` = `p.code`; nếu chỉ báo chính là `NOT_CONFIGURED`: `` `${p.code} · Chưa có ngưỡng tồn` ``.
   - `quantity` = `` `${p.available} ${p.stockUom}` ``.
   - `badge` = `bj01RowBadge(p)` (đã có).
   - `attrs` giữ nguyên `data-bj01-product="…" data-bj01-search-text="…"` (kịch bản golden và ô tìm dựa vào).
   - Bỏ `bj01RowSubtitle` nếu không còn chỗ dùng.
5. **Sheet quét mã** (`bj01ScanSheet()`, nối vào cuối `body` của SCR-001 khi `bj01ScanOpen`):
   - `ds24Sheet({ title: "Quét mã vạch", attrs: "data-bj01-scan-close", body: … })`.
   - Body: khung giả lập `<div class="bj01-scan-frame" aria-hidden="true">${icon("scan")}</div>`, dòng "Đưa mã vạch vào khung", nút phụ `data-bj01-scan-sample="INV-AMX"` chữ "Quét thử: Amox 500" (chỉ có trong prototype, ghi chú ở mục 9).
6. **Sự kiện** (trong listener click của `bj01.js`, nhánh `activeFlowId === "UIF-01"`):
   - `[data-bj01-scan]` → `bj01ScanOpen = true; renderAppScreen()`.
   - Bấm nền sheet (`event.target.matches("[data-bj01-scan-close]")`) → đóng, như cách sheet lô đang làm.
   - `[data-bj01-scan-sample]` → `bj01ScanOpen = false; bj01SelectedProductId = …; bj01LotOpen = false; bj01ProvenanceOpen = false; navigate("SCR-003")`.

### 3.4 `app/bj01.js` — SCR-003 Chi tiết

1. **App bar:**
   - `READY`, `STALE`, `LOADING`: `title: p.name`, `subtitle: `${p.code} · ${p.stockUom}``.
   - `PERMISSION_DENIED`: `title: "Chi tiết tồn kho"`, không phụ đề (không lộ dữ liệu sản phẩm).
   - Bỏ phụ đề "Từ ngữ cảnh sản phẩm · Kho trung tâm"; `backAction` của ngữ cảnh sản phẩm giữ nguyên.
2. **Bỏ** thẻ sản phẩm (`productContext`). Dòng `bj01Context()` giữ, ngay dưới app bar.
3. **Thẻ số chính** — thay `bj01AvailabilityRows(p)` bằng `bj01StockHero(p)`:

```html
<section class="bj01-stock-hero" data-composed-from="VCard,DS v2 / Key-value Row">
  <div class="bj01-stock-hero__main"><span>Khả dụng</span><strong>106 hộp</strong>{badge}</div>
  <dl class="bj01-stock-hero__stats">
    <div><dt>Tồn vật lý</dt><dd>120 hộp</dd></div>
    <div><dt>Đủ điều kiện bán</dt><dd>118 hộp</dd></div>
    <div><dt>Đã giữ</dt><dd>12 hộp</dd></div>
  </dl>
  <p class="bj01-stock-hero__note">Không đủ điều kiện bán: Cách ly 2 hộp</p>   <!-- chỉ khi có; nhiều lý do nối bằng " · " -->
</section>
```

   - `{badge}`: chỉ báo cấp sản phẩm — `OUT` → `ds24DotBadge("Hết hàng","Danger")`, `LOW` → `ds24DotBadge("Tồn thấp","Warning")`; không có thì bỏ. (Chỉ báo cấp lô nằm ở phần lô.)
   - `bj01LotQuantityRows` (sheet lô) giữ như cũ.
4. **Cảnh báo kèm việc tiếp** — thay `bj01AttentionBanner(p)` bằng `bj01Attention(p)`, đặt **ngay sau thẻ số chính**, trước dòng "Chưa cấu hình ngưỡng tồn…":
   - `OUT` / `LOW`: `vBanner(OUT ? "error" : "warning", "Hết hàng" | "Tồn thấp", <mô tả cũ phần khả dụng · ngưỡng>)`, sau đó dòng `<p class="bj01-attention__hint">Gợi ý nhập thêm {target − available} {ĐVT} (mục tiêu {target} {ĐVT})</p>` (chỉ khi có `target` và `target > available`), sau đó nút phụ `<button class="ds24-button ds24-button--secondary" data-bj01-receive type="button">Nhận hàng</button>`. Cả khối bọc `<div class="bj01-attention">`.
   - Có lô `EXPIRED`: thêm khối thứ hai `vBanner("error", "Có lô hết hạn", "Lô {mã} · {tồn lô} {ĐVT} không đủ điều kiện bán.")` + nút phụ `data-bj01-dispose-lot="{mã}"` "Xử lý lô hết hạn". Nhiều lô hết hạn: liệt kê mã nối " · ", nút dùng lô đầu.
   - Thứ tự khi có cả hai (vd. Tylosin): Tồn thấp / Hết hàng trước, lô hết hạn sau.
5. **Lô sắp theo HSD gần nhất trước.** Helper `bj01ExpirySortKey(lot)`: `expiryPrecision` `DAY` "dd/mm/yyyy" → ngày đó; `MONTH` "mm/yyyy" → ngày cuối tháng; `YEAR` "yyyy" → 31/12; không có → cuối danh sách. Dòng lô giữ chữ và badge hiện tại.
6. **Sheet lô:** khi lô `EXPIRED`, thêm nút phụ "Xử lý lô hết hạn" (`data-bj01-dispose-lot="{mã}"`) dưới banner "Hết hạn".
7. **Sự kiện mới:**
   - `[data-bj01-receive]` → sang BJ-02 nhập nhanh:
     ```js
     bj01LotOpen = false; bj01ProvenanceOpen = false;
     activeFlowId = "UIF-02"; flowMode = "quick"; resetBj02Receipt("quick");
     activeScreenId = "SCR-008"; stateByScreen["SCR-008"] = "READY";
     syncReviewUrl(); render();
     ```
     (Chưa điền sẵn sản phẩm vào phiếu: BJ-02 chưa hỗ trợ; ghi ở mục 10.)
   - `[data-bj01-dispose-lot]` → sang BJ-09, danh sách đã lọc đúng lô:
     ```js
     bj01LotOpen = false; bj01ProvenanceOpen = false;
     activeFlowId = "UIF-09"; ic09Filter = "EXPIRED"; ic09Query = el.dataset.bj01DisposeLot;
     activeScreenId = "SCR-036"; stateByScreen["SCR-036"] = "READY";
     syncReviewUrl(); render();
     ```
8. **Fixture BJ-09** (`app/bj09.js`, mảng `ic09Items`): thêm dòng để BJ-09 có đúng lô của BJ-01:
   ```js
   {id:"tylo",name:"Tylosin 20%",code:"SP-000122",lot:"TY2408",qty:11,uom:"lọ",state:"EXPIRED",label:"Hết hạn",expiry:"31/07/2026"},
   ```
   Dòng này làm danh sách BJ-09 dài thêm một dòng (ca golden `UIF-09_SCR-036_*` được phép khác).

### 3.5 Trạng thái (khuôn K1)

| Màn · trạng thái | Hiện gì | Lối ra |
|---|---|---|
| 001 · `LOADING` | Dòng ngữ cảnh + `k1Loading({ blocks:["search","row","row","row","row"] })` (thêm kiểu khối `row` / `search` vào `k1Loading` nếu BJ-12 chưa có) | — |
| 001 · `EMPTY` | `bj01Empty(false)` (giữ) | — |
| 001 · `FILTER_EMPTY` | `bj01Empty(true)` + "Xóa tìm kiếm và bộ lọc" (giữ) | Nút xoá lọc |
| 001 · `STALE` | Dòng ngữ cảnh → `k1Stale({ title:"Dữ liệu có thể đã cũ", actionLabel:"Làm mới", actionAttr:"data-bj01-refresh" })` (giữ chữ) → danh sách | Làm mới |
| 001 / 003 · `PERMISSION_DENIED` | `k1Denied({ what:"Không có quyền xem tồn kho", next:"Bạn chưa được cấp quyền xem tồn kho. Liên hệ chủ cửa hàng nếu cần.", exitAttr:k1ExitAttr("SCR-001") })`; không có dữ liệu sản phẩm trong DOM | "Về Kho" |
| 003 · `LOADING` | Dòng ngữ cảnh + `k1Loading({ blocks:["card","row","row","row"] })` | — |
| 003 · `STALE` | Như READY, banner + "Làm mới" ngay dưới dòng ngữ cảnh | Làm mới |

### 3.6 `styles/screens.css` — CSS BJ-01

1. Tạo khối `/* ===== BJ-01 Tồn kho (app/bj01.js) ===== */` ở **cuối** file cho: `.bj01-stock-hero*` (thẻ trắng bo 12, viền `--vet45-v2-border-default`, đệm 16; số "Khả dụng" JetBrains Mono 22/28 đậm 700; lưới 3 cột cho `dl`, nhãn 12 `--vet45-v2-text-secondary`, số mono 14), `.bj01-attention*` (khoảng cách 8 giữa banner, gợi ý, nút), `.bj01-scan-frame` (khung 4:3, viền gạch `--vet45-v2-border-strong`, icon giữa).
2. **Dọn luật cũ của BJ-01** sau khi markup mới chạy:
   - Luật nhắm `[data-active-uif="UIF-01"]` hoặc `.bj01-` (đo 2026-10-21 sau A11): `styles/components.css` 6 chỗ, `styles/screens.css` 101 chỗ (`grep -c "UIF-01\|bj01-" styles/*.css`).
   - Xoá luật **không còn khớp phần tử nào** trên màn BJ-01 (vd. `.ds24-availability…`, thẻ sản phẩm cũ). Dùng script mục 3.7 để biết luật nào không dùng.
   - Luật còn dùng: chuyển vào khối BJ-01, bỏ tiền tố `body[data-active-uif="UIF-01"]` nếu selector đã đủ riêng (class `bj01-*`), bỏ `!important` khi không còn đối thủ. Chụp golden sau mỗi lần chuyển.

### 3.7 Đo luật CSS không dùng

Dùng chế độ có sẵn của golden (A11), **không viết script mới**: `node tools/golden.mjs usage tools/.usage-bj01 UIF-01` (chạy mọi ca có `UIF-01` trong tên, gồm `SC_bj01_*`) → xem `tools/.usage-bj01/_css-deletable.txt`, lọc dòng có `UIF-01` hoặc `bj01-`. Luật cho thao tác (sheet đang mở, `:hover`, `:focus`, `is-open`) chỉ hiện khi kịch bản mở chúng — trước khi xoá luật loại này, mở bằng tay để chắc.

### 3.8 Kịch bản golden (`tools/golden.mjs`)

Giữ các kịch bản `SC_bj01_*` hiện có (thuộc tính `data-bj01-*` không đổi). Thêm:

| Tên | Bắt đầu | Bước |
|---|---|---|
| `SC_bj01_scan` | `?uif=UIF-01&screen=SCR-001` | `[data-bj01-scan]` → `[data-bj01-scan-sample]` |
| `SC_bj01_scan_close` | như trên | `[data-bj01-scan]` → bấm `.ds24-overlay[data-bj01-scan-close]` |
| `SC_bj01_receive` | như trên | `[data-bj01-product="INV-AMX"]` → `[data-bj01-receive]` |
| `SC_bj01_out` | như trên | `[data-bj01-product="INV-ENRO"]` → `[data-bj01-receive]` |
| `SC_bj01_expired` | như trên | `[data-bj01-product="INV-TYLO"]` → `[data-bj01-dispose-lot]` |
| `SC_bj01_expired_sheet` | như trên | `[data-bj01-product="INV-TYLO"]` → `[data-bj01-lot="TY2408"]` → `.ds24-sheet [data-bj01-dispose-lot]` |
| `SC_bj01_denied` | `?mode=theme&app=flow&uif=UIF-01&screen=SCR-001&state=PERMISSION_DENIED` | nút "Về Kho" (`[data-theme-sidebar-route="inventory"]` do `k1ExitAttr` sinh ở chế độ theme) |
| `SC_bj01_barcode_type` | `?uif=UIF-01&screen=SCR-001` | gõ `8938500004068` vào `[data-bj01-search]` (máy quét USB trên web gõ như bàn phím) → còn đúng dòng Amox 500 |

## 4. Bước D — kiểm

| Kiểm | Đạt khi |
|---|---|
| Golden mobile | So `tools/.golden-bj01-base`: chỉ khác ở `UIF-01_*`, `SC_bj01_*`, `SC_search_*`, `SC_quick_UIF-01_*`, `SC_ws_inventory_0_*`, `UIF-09_SCR-036_*` (dòng Tylosin thêm vào BJ-09) và kịch bản mới. Mọi ca khác "Khớp hoàn toàn" |
| Golden web | So `tools/.golden-bj01-web-base`: chỉ khác `UIF-01_*@web`, `UIF-09_SCR-036_*@web` |
| Web dùng được | Khung web: SCR-001 / 003 không vỡ, không tràn ngang, đủ nút; BJ-01 **không** dùng `k7-wide` (iPhone chính — giữ cột ở giữa); `SC_bj01_barcode_type` đạt |
| Bộ bấm thử | 0 lỗi JS (phiên review chạy lại khi review) |
| Bỏ chạm luồng khác | `SC_bj01_receive` dừng ở SCR-008 nhập nhanh; `SC_bj01_expired` dừng ở SCR-036 BJ-09 có đúng một dòng "Tylosin 20% · TY2408" |
| `PERMISSION_DENIED` | DOM của SCR-001 / 003 không có tên, mã hay số lượng sản phẩm nào (`innerText` của `#app-screen` chỉ gồm chữ trạng thái, thanh trạng thái và nút) |
| Tương phản / vùng chạm | `/impeccable audit` cho UIF-01: chữ ≥ 4,5:1, nút quét mã và chip ≥ 44 × 44, nút icon có `aria-label` |
| Chữ | Đúng bảng mục 9 |
| Bạn xem ảnh | `UIF-01_SCR-001_READY`, `UIF-01_SCR-003_READY` (Nobivac), `SC_bj01_list_5_product` (Amox — tồn thấp), `SC_bj01_tylo_1_product` (Tylosin — tồn thấp + lô hết hạn), `SC_bj01_scan_1_*`, `UIF-01_SCR-001_PERMISSION_DENIED`, `UIF-01_SCR-003_LOADING` |

Xong D: chụp `tools/.golden-bj01-after` và `DEVICE=web … tools/.golden-bj01-web-after` (mốc cho CAP-01).

## 5. Bước E — ghi lại

1. `CHANGELOG.md`: mục `[5.6.0] — T7-P BJ-01 thiết kế lại` (thay đổi theo màn; ca golden khác; thành phần mới `VStockRow`, chip có số, nút quét trong ô tìm; dùng K1 của BJ-12). Phiên bản 5.6.0 ở `manifest.json`, `harness/workbench.js`, badge `index.html`.
2. **Viết lại theo khuôn** `03.design/screens/_TEMPLATE.md`: `03.design/screens/SCR-001.md`, `SCR-003.md` — gộp các đoạn `### vX.Y` hiện có vào nội dung chính; thứ bậc thông tin, bảng trạng thái và bảng chữ theo prototype mới; trạng thái `IN_REVIEW`.
3. Viết lại `03.design/flows/UIF-01-BJ-01.md` theo `03.design/flows/_TEMPLATE.md`: sơ đồ 001 → 003 → (sheet lô / sheet nguồn → BJ-15), nút sang BJ-02 và BJ-09, khuôn K1.
4. `03.design/screens/INDEX.md`: SCR-004, SCR-005 ghi "sheet trong SCR-003"; SCR-002, SCR-060, SCR-061 giữ ghi chú hiện có.
5. Plan tổng thể T7-P: mục 5 thêm BJ-01 vào chỗ dùng K1; mục 6 đánh dấu `VStockRow`, nút quét, chip có số = ✅ prototype; mục 13 đánh dấu 3 dòng BJ-01 đã duyệt + thêm chữ mới ở mục 9 dưới đây; mục 14 BJ-01 C / D / E ✅.
6. `python3 tools/sync-registry.py`.

## 6. Thứ tự commit

1. `feat(prototype): T7-P BJ-01 redesign — stock list, detail, K1 states` — mục 3 + golden mới.
2. `docs(theme-07): BJ-01 screen contracts and UIF on new template` — mục 5.

Trước mỗi commit chạy `detect_changes()` theo CLAUDE.md (thay đổi chỉ ở prototype / tài liệu, không đụng symbol Flutter).

## 7. Không làm trong plan này

- Điền sẵn sản phẩm vào phiếu BJ-02 khi bấm "Nhận hàng" (BJ-02 chưa hỗ trợ; xem lại ở brief BJ-02).
- Đặt ngưỡng tồn ngay trong SCR-003 khi "Chưa có ngưỡng tồn": plan CAP-01 mục 3.4 thêm nút "Đặt ngưỡng tồn" / "Sửa ngưỡng" vào SCR-003.
- Gộp fixture BJ-01 và BJ-09 thành một bộ (chỉ thêm một dòng Tylosin; gộp hẳn ở BJ-09).
- Quét mã vạch thật (prototype chỉ mô phỏng).

## 8. Rủi ro

| Rủi ro | Cách xử lý |
|---|---|
| Dọn CSS cũ làm lệch màn của BJ khác dùng chung class (`.ds24-list-row`, `.ds24-chip`) | Chỉ xoá luật có `UIF-01` hoặc `bj01-` trong selector; golden các BJ khác phải khớp |
| `ds24Search` / `ds24Chip` đổi chữ ký | Tham số mới ở cuối, có mặc định — chỗ gọi cũ không đổi; golden các BJ khác phải khớp |
| Màn BJ-09 thêm một dòng | Đã liệt kê là khác có chủ đích |

## 9. Chữ trên màn (đã duyệt cùng brief; thêm vào mục 13 của T7-P khi làm E)

| Màn | Vị trí | Chữ | Mới? |
|---|---|---|---|
| 001 | Nút trong ô tìm (`aria-label`) | "Quét mã vạch" | mới |
| 001 | Tiêu đề sheet quét | "Quét mã vạch" | mới |
| 001 | Hướng dẫn trong sheet | "Đưa mã vạch vào khung" | mới |
| 001 | Nút mô phỏng trong sheet | "Quét thử: Amox 500" | chỉ prototype, không vào Screen Contract |
| 001 | Chip | "Tất cả", "Hết hàng", "Tồn thấp", "Cận hạn", "Hết hạn" + số | giữ chữ, thêm số |
| 003 | App bar | `{tên sản phẩm}` / `{mã} · {ĐVT}` | đổi (trước: "Chi tiết tồn kho") |
| 003 | Thẻ số chính | "Khả dụng", "Tồn vật lý", "Đủ điều kiện bán", "Đã giữ", "Không đủ điều kiện bán: {lý do} {SL} {ĐVT}" | giữ chữ, gộp dòng lý do |
| 003 | Gợi ý | "Gợi ý nhập thêm {n} {ĐVT} (mục tiêu {m} {ĐVT})" | mới (tách từ mô tả banner cũ) |
| 003 | Nút | "Nhận hàng" | mới ở màn này |
| 003 | Banner lô hết hạn | "Có lô hết hạn" / "Lô {mã} · {SL} {ĐVT} không đủ điều kiện bán." | mới |
| 003 | Nút | "Xử lý lô hết hạn" | mới |
| 001 / 003 | Không có quyền | "Không có quyền xem tồn kho" / "Bạn chưa được cấp quyền xem tồn kho. Liên hệ chủ cửa hàng nếu cần." / "Về Kho" | mới (thay câu chung "Liên hệ quản trị viên…") |

## 10. Ghi chú khi làm

Làm 2026-10-21. Golden: mobile `.golden-bj01-after` (1399 ca), web `.golden-bj01-web-after` (551 ca), 0 lỗi JS. Mốc `.golden-bj01-base` mobile khớp hoàn toàn `.golden-bj12-after`; mốc web lệch mốc BJ-12 ở 2 ca nhiễu (`UIF-06_SCR-033_READY@web` 47 điểm, `UIF-07_SCR-037_EXPIRED@web` 33 điểm), không thuộc BJ-01.

**Lệch plan**

1. **Tiêu đề không có quyền:** plan mục 3.5 / 9 ghi `what:"Không có quyền xem tồn kho"`, nhưng `k1Denied` tự ghép "Bạn chưa có quyền {what}" → "Bạn chưa có quyền Không có quyền…". Dùng `what:"xem tồn kho"` → tiêu đề "Bạn chưa có quyền xem tồn kho" (cùng kiểu BJ-12). Mô tả và nút "Về Kho" đúng plan. Đã ghi chữ này vào SCR-001 / 003 mục 8 và T7-P mục 13.
2. **Chip "Tồn thấp" = 2, không phải 1:** brief tính theo dữ liệu cũ; dữ liệu hiện tại có Amox 500 và Tylosin 20% đều tồn thấp. Số chip đếm đúng theo chỉ báo.
3. **Chip vẫn cuộn ngang:** khung chip bị khoá 370px bởi luật chung (`body[data-active-uif] .figma-calibrated-shell .ds24-chip-scroll`). Thu khoảng cách + đệm chip BJ-01 (6px / 10px) để thấy ~4,5 chip; "Hết hạn" cần cuộn. Chữ không còn bị cắt. Muốn thấy đủ 5 chip không cuộn thì phải đổi chung khung chip (ngoài phạm vi).
4. **Nút quét mô phỏng:** thêm `.ds24-search__action` có margin âm để vùng chạm 44 × 44 nằm trong ô tìm 44 cao.
5. **Dọn CSS (mục 3.6) chưa làm hết:** đã xoá luật chỉ riêng BJ-01 và không khớp phần tử nào (`.bj01-product-row*`, `.bj01-list-empty`, `.bj01-eligibility-reasons`, `.ds24-key-value-row--emphasis` của UIF-01, `[data-bj01-product-row][hidden]`). **Không** chuyển luật còn dùng (≈110 luật `UIF-01` / `bj01-` trong `screens.css`, nhiều luật `!important`, một số dùng chung `:is(UIF-01, UIF-02, …)`) vào khối cuối: đổi thứ tự luật có nguy cơ vỡ BJ khác, làm riêng một gói dọn CSS sau. Còn 8 luật `UIF-01` / `bj01-` đo là không dùng nhưng nằm trong `:is()` chung với BJ khác — giữ.
6. **Tên file đo CSS:** `golden.mjs usage` ghi `_css-unused.txt` (plan ghi `_css-deletable.txt`). Chạy với filter `bj01` mới gồm cả kịch bản `SC_bj01_*` (filter `UIF-01` chỉ chạy 14 ca trạng thái).
7. **Ca golden đổi ngoài danh sách plan (đều đi qua SCR-001 hoặc SCR-036):** `SC_ws_inventory_0_2_item`, `SC_cap01_*`, `SC_bj12_approve_6`, `SC_bj12_pending_list_11`, `SC_entry_state_01_0` (kết thúc ở Tồn kho); `SC_attention_UIF-09`, `SC_bj09_flow_*`, `SC_ws_control_1_2`, `SC_ws_inventory_1_2` (dòng Tylosin thêm vào BJ-09).
8. **`detect_changes()` (CLAUDE.md):** công cụ GitNexus MCP không có trong phiên này nên chưa chạy; thay đổi chỉ ở prototype HTML / tài liệu, không đụng symbol Flutter.
9. **Chưa commit:** theo thứ tự mục 6 plan (2 commit) khi bạn yêu cầu; cây làm việc còn chung với thay đổi BJ-12 chưa commit.

**Ảnh nên xem:** `UIF-01_SCR-001_READY`, `UIF-01_SCR-003_READY`, `SC_bj01_list_5_product`, `SC_bj01_tylo_1_product`, `SC_bj01_scan_1_scan`, `UIF-01_SCR-001_PERMISSION_DENIED`, `UIF-01_SCR-003_LOADING` trong `tools/.golden-bj01-after`.

## 11. Review

(2026-10-21, phiên review) — review chung cả chặng 1 (R1–R4 đã sửa ở v5.7.1; còn R5 `/impeccable audit` trước commit): [plan CAP-01 mục 10](T7-P-cap01-chinh-sach-ton.md#10-review). Lệch 1–9 chấp nhận (lệch 5: dọn CSS để gói riêng ở Giai đoạn 3). Phần của BJ-01: **R3** (ngưỡng của sản phẩm bình thường không xem / sửa được ở SCR-003); góp ý 1, 7, 11.
