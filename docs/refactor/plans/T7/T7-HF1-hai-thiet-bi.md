# T7-HF1 · Hotfix: đủ bố cục iPhone và web cho các màn Theme 7 đã làm

> Theme: Theme 7 Inventory (prototype HTML) · Trạng thái: Brief ✅ (duyệt 2026-10-22 — mục 0.4) | Làm ✅ (2026-10-22, chưa commit) | Review ✅ 2026-10-22 (mục 8; 2 lỗi đã sửa ngay trong phiên review)
> **Hotfix riêng, không thuộc [T7-P](T7-P-thiet-ke-lai-luong.md)**: không thêm dòng vào tiến độ hay chặng của T7-P. Lý do: 2026-10-22 người dùng chốt **iPhone và web đều là thiết bị chính ở mọi màn** ([LUONG-UNG-DUNG 1.1](../../../02-yeu-cau/LUONG-UNG-DUNG.md)); các màn làm trước đó theo cách hiểu sai "thiết bị chính theo màn" có màn chỉ làm một bên.
> Làm **trước** [BJ-13](T7-P-bj13-dieu-chinh-gia-tri.md), để BJ-13 dựng trên khuôn đã sửa. Review BJ-02 và BJ-03 (đang ⬜) gộp vào review của hotfix này.
> Phiên bản đích **5.9.1** (hiện 5.9.0; BJ-13 = 5.10.0). Ước lượng **~2–2,5 ngày, 2 commit** (C+D; E). Người làm: bạn. Review: phiên plan / review.

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/` nếu không ghi khác. Câu trong ngoặc kép là chữ hiển thị. **Không đổi chữ, nghiệp vụ hay luồng**: chỉ đổi bố cục.

## 0. Brief

### 0.1 Kết quả rà (2026-10-22, golden mới cả hai khung)

Chụp bằng `node tools/golden.mjs capture` và `DEVICE=web …` cho UIF-01, UIF-02, UIF-03, UIF-12, CAP-01, Hub.

| Nhóm | Màn | Hiện trạng |
|---|---|---|
| **A. Web là cột iPhone 402px giữa khung** | BJ-01 SCR-001, 003 | Danh sách thẻ hẹp giữa khung; thanh tiêu đề trắng cũng chỉ phủ cột giữa. Không dùng `k7-wide` (plan BJ-01 cố ý giữ vì "iPhone chính") |
| | BJ-02 SCR-009, 084, 010 | Như trên; chân màn nút full cột 402px |
| **B. Web là bản iPhone kéo giãn** | BJ-02 SCR-008 | Có `k7-wide` nhưng biểu mẫu lệch trái, nút "Tiếp tục" dài ~1000px (`.bj02-footer-stack` bọc nút nên luật căn phải của `k7-wide .app-actions .button` không áp) |
| | Home Kho (`hub.js` `renderHubHome`) | `t7-integrated-shell` thoát cột 402 nhưng không có bố cục web: 4 ô nút nhanh ~500px mỗi ô, dòng "Cần chú ý" / "Quản lý kho" dài hết khung, nút quay lại ở màn gốc |
| | CAP-01 SCR-063 | Ô "Số ngày cận hạn" rộng ~560px cho số 2 chữ số (`.cap-narrow`); "Thêm sản phẩm" dài hết khung |
| **C. Chưa đều / chật** | BJ-02 SCR-013 (và mọi màn `k3Unknown` có `detail`) | Thẻ kết quả 480px giữa, dòng thời gian bằng chứng rộng hết khung |
| | BJ-03 SCR-015 web | Cột "Tình trạng" hẹp, dòng căn cứ gãy 4–5 dòng |
| **D. iPhone — lỗi khuôn dùng chung** | K2 "Cần chú ý" (BJ-12 070, BJ-02 011) | Nhãn \| giá trị hai cột, giá trị xuống dòng xấu ("8 dòng (cách ly / hư / hỏng)") |
| | Dòng thu gọn của bảng 011 (`bj02ReadOnlyLine`) | Số "121 / 120" gãy dòng; mã SP bị cắt "SP-000184 · hộp · DH2507 …" |
| **Đạt** | BJ-12 (066–071), CAP-01 062, BJ-03 014, BJ-02 007 / 011 / 012 | Cả hai khung là thiết kế thật |

### 0.2 Đề xuất (đã duyệt 2026-10-22)

| # | Màn | Web | iPhone |
|---|---|---|---|
| 1 | **SCR-001** Tồn kho | `k7-wide`. **Danh sách – chi tiết:** trái ô tìm + chip lọc + bảng (Sản phẩm (tên + mã) · Khả dụng · Tồn vật lý · Đã giữ · Chỉ báo); phải chi tiết sản phẩm đang chọn (thẻ số `bj01StockHero` + "Lô và hạn dùng" + "Nguồn và thời điểm cập nhật"). Mặc định chọn dòng đầu. Bấm dòng: đổi chi tiết bên phải, **không** đổi trang | Giữ nguyên (bấm dòng → SCR-003) |
| 2 | **SCR-003** Chi tiết tồn (mở thẳng, vd. `entry=product-context`) | `k7-wide`, hai cột: trái thẻ số + ngưỡng; phải bảng lô (Lô · HSD · Tồn · Tình trạng) + dòng nguồn | Giữ nguyên |
| 3 | **SCR-009 + 084** Hàng thực nhận / chi tiết dòng | `k7-wide`. **Danh sách – chi tiết:** trái ngữ cảnh phiếu + tiến độ + ô tìm / quét + danh sách mặt hàng (dòng đang chọn tô nền); phải nội dung SCR-084 của dòng đang chọn ("Nhận đủ …", lô, "Thêm lô khác", tổng kiểm nhận). "Xong" ở cột phải lưu dòng và **chuyển sang dòng chưa xử lý kế tiếp**. Chân màn: "Rà soát" căn phải. Vào thẳng SCR-084 trên web = SCR-009 với dòng đó được chọn | Giữ hai màn như hiện tại |
| 4 | **SCR-010** Rà soát nhận hàng | `k7-wide`, `k7Split({ wideMain:true })`: trái bảng "Hàng thực nhận" (Mặt hàng · Theo chứng từ · Thực nhận · Lô · Tình trạng) + "Thông tin lần nhận"; phải khối tóm tắt (chứng từ, NCC, kho, ngày, số mặt hàng) + nút "Xác nhận nhận hàng" — như SCR-015 (nút hai bản, web ở khối tóm tắt, iPhone ở chân) | Giữ nguyên |
| 5 | **SCR-008** Nhập hàng nhanh | Hai cột: trái "Nhà cung cấp", "Kho và ngày nhận", ô xác nhận sở hữu; phải "Chứng từ giao nhận" (vùng kéo thả). Chân màn: dòng lý do bên trái, nút "Tiếp tục" bên phải rộng theo chữ | Giữ nguyên |
| 6 | **Home Kho** | Ô tìm rộng tối đa 720px; 4 nút nhanh **một hàng**, ô thấp (~88px); dưới chia **hai cột**: trái "Cần chú ý", phải "Quản lý kho" + "Thiết lập kho". Ẩn nút quay lại trên web (thanh bên đã chỉ chỗ) | Giữ nguyên |
| 7 | **K3** (`k3Unknown`, vd. SCR-013) | Thẻ kết quả và `detail` (dòng thời gian) cùng một cột tối đa 720px giữa khung | Giữ nguyên |
| 8 | **CAP-01 SCR-063** | Ô số ngày rộng ~200px; "Thêm sản phẩm" rộng theo chữ, căn trái | Giữ nguyên |
| 9 | **BJ-03 SCR-015** | Cột "Tình trạng" tối thiểu ~240px; dòng căn cứ ≤ 3 dòng ở khung 1280 | Giữ nguyên |
| 10 | **K2 "Cần chú ý"** | Giữ (nhãn \| giá trị một hàng) | Nhãn ở trên (chữ phụ), giá trị ở dưới căn trái, icon bên trái cả khối |
| 11 | **Dòng thu gọn 011** | — | Số "121 / 120" không gãy (`white-space:nowrap`, cột số co theo nội dung); dòng phụ (mã · ĐVT · lô) được xuống 2 dòng thay vì cắt "…" |

Câu hỏi đã chốt (mục 0.4): (a) SCR-001 web dùng danh sách – chi tiết như mục 1, hay chỉ bảng rộng (bấm dòng sang SCR-003 hai cột)? Đề xuất: danh sách – chi tiết (đúng bố cục web chung, Owner tra nhiều sản phẩm liền). (b) SCR-009 + 084 gộp trên web như mục 3? Đề xuất: có (nhận nhiều dòng liên tục bằng bàn phím / máy quét, không đổi trang mỗi dòng).

### 0.3 Không đổi

Chữ hiển thị, quy tắc, trạng thái, luồng giữa các màn (Screen Contract giữ; chỉ thêm đoạn bố cục web / iPhone ở bước E). Bố cục iPhone của mọi màn trừ mục 10, 11.

### 0.4 Đã chốt khi duyệt brief (2026-10-22): **mọi mục theo cột "Đề xuất"**

- **(a)** SCR-001 trên web là danh sách – chi tiết: bảng bên trái, bấm dòng thì chi tiết hiện bên phải, không đổi trang. SCR-003 vẫn còn cho lối vào thẳng (hai cột trên web).
- **(b)** SCR-009 + 084 gộp **bố cục web** thành một màn hai cột; "Xong" lưu dòng rồi chuyển sang dòng chưa xử lý kế tiếp. iPhone giữ hai màn.
- Mục 2–11 làm đúng như bảng 0.2.

## 1. Chuẩn bị

1. `python3 -m http.server 8765 --bind 127.0.0.1` trong `html/`.
2. Chụp **một** mốc trước khi sửa, không chụp lại giữa chừng: `node tools/golden.mjs capture tools/.golden-hf1-base` và `DEVICE=web node tools/golden.mjs capture tools/.golden-hf1-web-base`.
3. Kiểm: `grep -n "viewport" app/core.js` — biến `viewport` (`"web"` | `"mobile"`, `core.js:69`) dùng để rẽ hành vi bấm dòng ở mục 3.2, 3.3; bố cục thì rẽ bằng CSS `.device-preview.is-web` như các BJ đã làm (đổi khung không dựng lại màn — kiểm cả lúc bấm nút đổi khung trên harness, không chỉ lúc tải URL `viewport=web`: nếu đổi khung không dựng lại, sau khi đổi phải gọi `renderAppScreen()`).

## 2. Bước C — dựng (commit 1)

### 2.1 Khuôn dùng chung (`app/shared-patterns.js`, `styles/components.css`)

1. **K2 "Cần chú ý" (mục 10):** `.k2-attention__row` đang khai báo hai lần (`components.css` ~3330 và ~3507) — gộp làm một. iPhone (`.device-preview:not(.is-web)`): lưới `20px 1fr`, nhãn và giá trị cùng cột 2 xếp dọc (nhãn 13/20 chữ phụ, giá trị 14/20 đậm, căn trái). Web giữ một hàng. Không đổi HTML của `k2Attention` nếu làm được bằng CSS; cần thì bọc nhãn + giá trị trong `<div class="k2-attention__text">`.
2. **K3 (mục 7):** trên web, `.k7-wide .io-result` và phần `detail` cùng nằm trong một cột `max-width:720px; margin:0 auto` (bọc trong `k3Unknown`: `<div class="k3-column">…</div>`). Ảnh hưởng mọi màn `k3Unknown`: BJ-12 071 `UNKNOWN` / `COMMIT_UNKNOWN`, BJ-03 019 `UNKNOWN`, BJ-02 013 — liệt kê trong golden mục 3.
3. **Chân màn có dòng lý do (`bj02Footer`, mục 5):** web `k7-wide`: `.bj02-footer-stack` thành hàng ngang (`flex-direction:row; align-items:center; justify-content:flex-end; gap: space-3; width:100%`), nút `width:auto; min-width:160px`. iPhone giữ.

### 2.2 BJ-01 (`app/bj01.js`, khối CSS BJ-01 trong `styles/screens.css`)

1. Thêm `bj01SelectedId` (mặc định: dòng đầu theo thứ tự `bj01UrgencyRank` đang dùng cho danh sách).
2. `render001BJ01` READY / STALE / FILTER_EMPTY: `appShell({ …, extraClass:"k7-wide" })`, thân = `k7Split({ wideMain:true, asideWebOnly:true, main: bj01Context() + bj01SearchAndFilters() + k7Table({ columns, rows, mobileRow: <dòng thẻ hiện tại>, rowAttr: (r)=>\`data-bj01-product="${r.id}"${r.id===bj01SelectedId?' aria-selected="true"':''}\` }), aside: <chi tiết> })`. Chi tiết = phần thân READY của `render003BJ01` tách ra thành `bj01DetailBody(p)` (gọi ở cả 001 web và 003). LOADING / EMPTY / PERMISSION_DENIED: thêm `k7-wide` cho thanh tiêu đề phủ hết khung, giữ nội dung.
3. Bấm `data-bj01-product`: `viewport==="web"` → `bj01SelectedId = id; renderAppScreen()`; ngược lại như cũ (sang SCR-003). Dòng chọn: nền `--vet45-v2-surface-selected` (hoặc token chọn của DS; không gõ màu tay), `aria-selected`.
4. `render003BJ01`: `extraClass:"k7-wide"`; trên web `bj01DetailBody` xếp hai cột (CSS: `.device-preview.is-web .bj01-detail { display:grid; grid-template-columns: 5fr 7fr; }` — trái thẻ số, phải lô + nguồn). Khi là cột phải của 001 thì một cột (`.k7-split__aside .bj01-detail { display:block }`).
5. Sheet lô / nguồn / quét: trên web thành hộp thoại (luật `.k7-wide .bottom-sheet` đã có, kiểm lại).

### 2.3 BJ-02 (`app/bj02.js`, khối CSS UIF-02)

1. **SCR-009 + 084 (mục 3):** thêm `bj02WebLineId` (dòng đang chọn trên web; mặc định dòng chưa xử lý đầu tiên). Tách thân READY của `render084BJ02` thành `bj02LineEditorBody(line)`. `render009BJ02` READY trên web: `k7Split({ main: <danh sách hiện tại>, aside: bj02LineEditorBody(dòng chọn), asideWebOnly:true })`, `extraClass:"k7-wide"`. Bấm dòng: web → `beginLineEditor(id)` + `bj02WebLineId=id` + render 009; iPhone như cũ (sang 084). "Xong" trên web: lưu như cũ rồi chọn dòng chưa xử lý kế tiếp (hết thì giữ dòng vừa lưu) và ở lại 009. `render084BJ02` khi `viewport==="web"`: trả `render009BJ02` với dòng đó được chọn (golden `UIF-02_SCR-084_*@web` sẽ khác — đúng chủ đích). Sheet quét / lô dùng chung.
2. **SCR-010 (mục 4):** `k7Split({ wideMain:true, main: k7Table(hàng thực nhận) + "Thông tin lần nhận", aside: tóm tắt + nút })` theo mẫu `render015` của `bj03.js` (nút hai bản: `.k7-web-only` trong khối tóm tắt, `.k7-mobile-only` ở chân). Sheet xác nhận / sheet chi tiết dòng giữ.
3. **SCR-008 (mục 5):** thân web hai cột (`.bj02-quick-grid`: `grid-template-columns: 1fr 1fr`, chỉ `.device-preview.is-web`); iPhone giữ thứ tự hiện tại.
4. **SCR-011 dòng thu gọn (mục 11):** trong `bj02ReadOnlyLine`, cột số `white-space:nowrap`, dòng phụ bỏ `text-overflow:ellipsis` / `-webkit-line-clamp:1` → cho 2 dòng.
5. Sửa chú thích `/* ---------- SCR-011 … (web chính) ---------- */` (`bj02.js` ~1119) bỏ "(web chính)".

### 2.4 Home Kho (`app/hub.js` `renderHubHome`, CSS `.t462-*`)

1. Bọc phần dưới nút nhanh: `<div class="t462-columns"><div>${attention}</div><div>${workspaces}${setup}</div></div>`. CSS chỉ web: `.t462-quick-grid { grid-template-columns: repeat(4, 1fr) }`, ô nút nhanh `min-height:88px`; `.t462-columns { display:grid; grid-template-columns: 1fr 1fr; gap: space-6; align-items:start }`; `.t462-search-wrap { max-width:720px }`. iPhone: `.t462-columns` là `display:contents` (thứ tự như cũ).
2. Nút quay lại của Hub (`data-theme-app-back`): ẩn trên web.
3. Kho chưa kích hoạt (`HUB_home_not_activated`): banner + nút kích hoạt ở cột trái trên web; kiểm ảnh.

### 2.5 CAP-01, BJ-03

1. `SCR-063` (mục 8): web `.cap-expiry-days .k7-edit` (hoặc ô số ngày mặc định) `max-width:200px`; nút "Thêm sản phẩm" web `width:auto; align-self:flex-start`. Sửa chú thích đầu `cap01.js` bỏ "(web chính)".
2. `SCR-015` (mục 9): cột Tình trạng `min-width:240px` (`k7Table` cột có `cls` → lớp `bj03-col-status`); kiểm ở 1280 dòng căn cứ ≤ 3 dòng. Sửa chú thích đầu `bj03.js` bỏ "(web chính)".

### 2.6 Golden (`tools/golden.mjs`)

1. `WEB_SCENARIOS` thêm `SC_bj01_list`, `SC_bj01_detail`, `SC_bj02_documents`-kiểu nhận nhiều dòng (dùng kịch bản đang có của BJ-02 lập phiếu; nếu chưa có kịch bản đi qua 009 → 084 → "Xong" → dòng kế, thêm `SC_hf1_receive_lines`: SCR-007 → PN-260816-04 → dòng 1 "Nhận đủ" + lô + HSD → "Xong" → dòng 2 tự chọn → … → "Rà soát"), `SC_bj01_theme` (Hub → Tra cứu tồn).
2. Kịch bản web mới `SC_hf1_bj01_select`: SCR-001 web → bấm dòng thứ 3 → chi tiết bên phải đổi, URL vẫn SCR-001.

## 3. Bước D — kiểm

1. **Golden** so mốc mục 1. Được khác: `UIF-01_*` (cả `@web`), `UIF-02_SCR-008/009/084/010/011_*`, `UIF-02_SCR-013_*`, `UIF-12_SCR-070_*` và `UIF-12_SCR-071_*UNKNOWN*` (K2 iPhone, K3 web), `UIF-03_SCR-015_*@web`, `UIF-03_SCR-019_UNKNOWN*@web`, `CAP-01_SCR-063_*@web`, `HUB_*@web`, `SC_journey_1_*`, `SC_bj01_*`, `SC_bj02_*`, `SC_bj03_*`, `SC_cap_hub_*` có bước qua các màn trên, và kịch bản mới. Mọi ca khác **khớp hoàn toàn**. Ghi danh sách ca khác vào mục 6.
2. **Hai khung đều là thiết kế thật** (T7-P mục 4.5 bước 3): xem ảnh iPhone và `@web` của mọi màn trong mục 0.2 — trên web không còn cột 402px giữa khung, không nút / dòng dài hết khung; trên iPhone không bảng ép nhỏ, số không gãy dòng.
3. Bộ bấm thử UIF-01, UIF-02, UIF-03, UIF-12, CAP-01, Hub ở hai khung + **đổi khung giữa chừng** (iPhone → web khi đang ở SCR-009 có dòng đang sửa): 0 lỗi JS; `node --check app/*.js harness/*.js`.
4. Bàn phím trên web: SCR-001 và SCR-009 đi bằng Tab tới dòng, Enter chọn dòng, chi tiết bên phải nhận được focus bằng Tab tiếp; Esc đóng hộp thoại.
5. **`/impeccable audit` phạm vi các màn mục 0.2 — chặn commit E**, cả hai khung. Đạt khi: chữ ≥ 4,5:1 (dòng chọn của bảng), vùng chạm ≥ 44 × 44 trên iPhone, nút icon có `aria-label`, dòng chọn có `aria-selected`.
6. Gửi ảnh: 001 web (chọn dòng khác dòng đầu), 003 web, 009 web (dòng thứ 2 đang sửa), 010 web, 008 web, Home Kho web (đã kích hoạt + chưa kích hoạt), 013 web, 063 web, 015 web, 070 iPhone, 011 iPhone.
7. **Review BJ-02, BJ-03 (gộp):** phiên review chạy lại tiêu chí D của [plan BJ-02](T7-P-bj02-nhan-hang.md) và [plan BJ-03](T7-P-bj03-gia-nhap.md) trên bản 5.9.1.

## 4. Bước E — ghi lại (commit 2)

1. `CHANGELOG.md` `[5.9.1] — T7-HF1: đủ bố cục iPhone và web cho màn đã làm`; manifest / badge harness 5.9.1.
2. Screen Contract SCR-001, 003, 008, 009, 084, 010, 013, 063, 015, 090: thêm / sửa đoạn **Bố cục** ghi rõ bố cục web và bố cục iPhone (không đổi chữ, trạng thái). UIF-01, UIF-02: bỏ câu "(bản web hiện còn cột giữa khung — …)", "(bố cục web của lập phiếu … sửa ở plan hotfix …)" vì đã xong.
3. Plan BJ-01 (mục 4 dòng "Web dùng được") và plan BJ-02 (mục 9 "Không làm"): thêm một dòng "đã sửa ở T7-HF1 (5.9.1)". Không sửa tiến độ của T7-P.
4. `python3 tools/sync-registry.py` nếu Screen Contract đổi (như các BJ trước).
5. Trước mỗi commit: `detect_changes()` của GitNexus nếu có trong phiên (prototype HTML tĩnh không được lập chỉ mục — ghi lại nếu không chạy được).

## 5. Không làm

- BJ chưa thiết kế lại (04–11, 13–17): web vẫn là cột 402px cho tới khi T7-P làm tới — mỗi BJ đó làm đủ hai bố cục ngay trong plan của nó (quy tắc mới, T7-P mục 2).
- Đổi chữ, gộp / tách màn trong Screen Contract (SCR-009 + 084 chỉ gộp **bố cục web**, hai màn vẫn tồn tại).
- Flutter, khung web của app (PLAN mục W).
- `docs/themes/*` (tài liệu v1 cũ còn ghi "mobile-first") — không phải đặc tả chuẩn.

## 6. Ghi chú khi làm

- **Golden:** iPhone 1560 → 1560 ca, 45 ca khác, đều là K2 / dòng thu gọn 011 và kịch bản đi qua `UIF-02_SCR-011`, `UIF-12_SCR-070`, ngoại trừ `SC_bj15_sheet_2_nob`, `_4_glv` (80–94 điểm ảnh rải, chữ giống hệt, BJ-15 không đổi mã; ca web `UIF-15_SCR-055` lúc có lúc không → nhiễu chữ mono, chưa quy được). Web 686 → 718, 253 ca khác — danh sách đầy đủ ở CHANGELOG 5.9.1. Không có `UIF-01_*` iPhone khác (iPhone dựng nguyên mã cũ).
- **Lệch plan:** (1) bố cục dựng theo biến `viewport` (và dựng lại khi đổi khung) thay vì chỉ ẩn / hiện bằng CSS, để DOM iPhone giữ nguyên golden; `k7Split` / `.k7-web-only` vẫn dùng. (2) Biến chọn dòng SCR-001 là `bj01WebSelectedId` (giữ `bj01SelectedProductId` cho nút trong chi tiết). (3) Hàng nút "Xong" của editor web nằm cuối cột phải (`bj02EditorSaveRow`, lý do `data-bj02-editor-reason`) chứ không dùng chân màn; chân web của 009 là "Rà soát". (4) SCR-010 web không có chân màn — nút xác nhận chỉ ở khối "Tóm tắt". (5) Khối "Tóm tắt" SCR-015 thu còn 288px và đệm ô bảng 8px để cột "Tình trạng" 240px không tràn. (6) `golden.mjs` thêm cờ `webOnly` cho kịch bản chỉ chạy ở khung web (`SC_hf1_*`).
- **`!important` mới:** có, cùng loại luật cũ `!important` của UIF-01/02/04/05/08 (List Row 370, Key-value 338, thẻ kết quả Figma): xem CHANGELOG 5.9.1. Một số luật phải tăng độ đặc hiệu vì `screens.css` nạp sau `components.css`.
- **Audit:** mục D5 — đạt (chi tiết ở CHANGELOG). D3 đổi khung giữa chừng: iPhone → web khi sửa dòng ở SCR-084 → SCR-009 giữ dòng và số đã nhập; web → iPhone giữ nháp; 0 lỗi JS; `node --check` đạt. D4 bàn phím SCR-001 / SCR-010 / sheet lô đạt (thử bằng sự kiện bàn phím tổng hợp, chưa thử Tab thật).
- **Chưa làm:** gửi ảnh mục D6 và review BJ-02 / BJ-03 gộp (D7) — việc của phiên review; `detect_changes()` của GitNexus không chạy (prototype HTML tĩnh không được lập chỉ mục, công cụ không có trong phiên). Chưa commit.

## 7. Rủi ro

| Rủi ro | Giảm |
|---|---|
| Gộp 009 + 084 trên web làm sai trạng thái nháp dòng khi chuyển dòng | Dùng đúng `beginLineEditor` / lưu như nút "Xong" hiện tại; đổi dòng khi nháp chưa lưu → hỏi như nút quay lại của 084 đang làm (giữ chữ có sẵn) |
| Đổi khung giữa chừng giữ trạng thái của khung kia (dòng chọn web không có ở iPhone) | iPhone bỏ qua `bj01SelectedId` / `bj02WebLineId`; đổi khung gọi lại render (kiểm D3) |
| K3 / K2 sửa ở khuôn làm khác golden BJ đã duyệt | Liệt kê trước ở D1; chỉ ca đó được khác |
| Sửa CSS chung đè luật cũ theo UIF | Đặt luật mới trong khối của BJ / khuôn, không thêm `!important` mới trừ khi luật cũ có `!important` (ghi vào mục 6) |

## 8. Review (2026-10-22, phiên review — gộp review BJ-02, BJ-03)

**Đã kiểm, đạt**
- Golden chụp lại độc lập: iPhone 1560 ca, web 718 ca, 0 lỗi JS. So ảnh người làm chụp (`.golden-hf1-new`, `-web-new`): web khớp hoàn toàn, iPhone chỉ khác `SC_bj15_sheet_2_nob` (nhiễu đã ghi ở mục 6). `node --check app/*.js harness/*.js` đạt.
- So mốc `.golden-hf1-base`: iPhone 44 ca khác, đều là K2 / dòng 011 (`UIF-12_SCR-070`, `UIF-02_SCR-011`, `SC_bj12_*`, `SC_entry_UIF-0{2,12}_approver`, `SC_entry_state_12`, `SC_pending_2_receipt`) + nhiễu `SC_bj15_*`. Web 253 ca, trong phạm vi; ngoài danh sách D1 chỉ có các ca K3 (`UIF-02_SCR-012_*UNKNOWN*`, alias sang 013; `UIF-12_SCR-066_UNKNOWN`; `CAP-01_SCR-065_UNKNOWN`) — đúng chủ đích vì K3 đổi ở khuôn, D1 liệt kê thiếu.
- Xem ảnh mục D6: 001 (chọn dòng thứ 3), 003, 009 (dòng 2 đang sửa), 010, 008, Home Kho (đã kích hoạt + chưa kích hoạt), 013, 063, 015 trên web; 070, 011 trên iPhone. Bố cục khớp bảng 0.2 mục 1–11.
- D3 đổi khung giữa chừng (bằng trình duyệt thật): iPhone 084 sửa Đạt = 7 → web: ở 009, giữ dòng và số 7; đổi sang dòng khác thì dòng cũ lưu nháp (`PENDING`, Đạt 7); về iPhone không lỗi. 0 lỗi JS.

**Phải sửa trước commit — ✅ đã sửa 2026-10-22** (golden iPhone 1560 ca khớp hoàn toàn; web 721 ca, chỉ khác ca mở sheet BJ-01; 0 lỗi JS; ghi ở CHANGELOG 5.9.1)
1. **Sheet `ds24Sheet` trên web không thành hộp thoại** (mục 2.2 bước 5 chưa đạt). Luật hộp thoại web chỉ có cho `.bottom-sheet` (`components.css` ~3485, ~3617); `ds24Sheet` (`core.js:403`, lớp `.ds24-overlay` / `.ds24-sheet`) không có luật web. Hệ quả: sheet lô và sheet nguồn của BJ-01 ở 001 / 003 web dính góc dưới cột trái (~330px). Sửa: thêm luật `.device-preview.is-web .k7-wide` cho `.ds24-overlay` / `.ds24-sheet` như `.bottom-sheet` (giữa khung, 480px, bỏ tay nắm); `grep -n "ds24Sheet(" app/*.js` để kiểm các màn `k7-wide` khác dùng chung. (Sheet quét cũng là `ds24Sheet` nên tự đổi theo — xem ghi chú quét dưới.) **Đã sửa:** khối luật sau `.k7-wide .bottom-sheet` trong `components.css`; khối con bỏ bề rộng iPhone, `!important` chỉ cho Key-value / Info Row và chữ banner (luật iPhone của chúng có `!important`). Kiểm thêm: sheet danh sách dòng 012 và chứng từ giao nhận 011 cũng thành hộp thoại.
2. **Golden `SC_hf1_bj01_select` không thử sheet lô:** bước `select-3` chọn Amox 500 (không theo lô) nên bước `lot` bấm vào không có gì — vì vậy lỗi 1 lọt. Chọn dòng có lô (Nobivac DHPPi) rồi mới `lot`. **Đã sửa:** thêm bước `select-nob`, và `provenance` / `close-provenance`.

**Quét mã vạch — chưa làm, có thể hoãn (người dùng, 2026-10-22): không chặn, chỉ ghi lại** cho khi làm tính năng quét:
- Web 009: quét đúng mặt hàng của dòng đang chọn thì sheet quét không đóng — `beginLineEditor(id)` với `id` là dòng đang chọn đi nhánh `return` sớm (`bj02.js` ~778), không dựng lại màn. Sửa: `renderAppScreen()` trước `return`.
- Sheet quét ở 009 web hiện cao gần hết khung (hết khi sửa lỗi 1).

**Nên sửa (nhỏ, không chặn)**
4. Esc đóng sheet BJ-01 trên web thì focus rơi về `BODY`, không về dòng / nút đã mở (BJ-02 / BJ-03 đã đặt tiêu chí "focus về nút đã mở").
5. SCR-001 web: `aria-selected` trên `<tr>` của bảng thường (không phải `grid`) không được đọc; 009 web dùng `aria-current="true"` — dùng cùng một cách (`aria-current`) cho cả hai.
6. SCR-015 web: cột "Tình trạng" 240px làm cột "Sản phẩm" hẹp — "Oxytetracycline LA" và "Lô DH2507 · 121 hộp" gãy dòng ở 1280. Cân lại (vd. tình trạng 200–220px, hoặc thu khối "Tóm tắt").
7. SCR-008 web: thứ tự Tab là nhà cung cấp → "Chọn tệp" (cột phải) → ô tick (cột trái); thứ tự nhìn là cột trái trước. Đổi thứ tự DOM hoặc chấp nhận và ghi lại.
8. K2 iPhone xếp dọc: nhãn "{tên}:" của 011 vẫn còn dấu hai chấm (chữ viết cho dạng một hàng) — để lượt chữ sau, không đổi chữ trong hotfix.

**Tài liệu**
- Mục 3 D1 liệt kê thiếu các ca K3 ở trên — CHANGELOG 5.9.1 đã có đủ, không cần sửa thêm.
- `09.generated/registries/design/screen-registry.md` còn `SCR-017` là màn đang dùng (`SCR-006` đã ghi RETIRED) — bảng sinh tự động, sửa nguồn khi sinh lại.
- Trong lúc review, `python3 tools/sync-registry.py --help` đã chạy luôn (script không có `--help`) và ghi lại registry / checksums — cùng lệnh bước E, chạy lại sau khi sửa là được.

**Review BJ-02, BJ-03 (D7):** xem [BJ-02 mục 13](T7-P-bj02-nhan-hang.md#13-review), [BJ-03 mục 10](T7-P-bj03-gia-nhap.md#10-review).

**Commit:** BJ-02 (5.8.0), BJ-03 (5.9.0) và HF1 (5.9.1) đang chung một cây làm việc chưa commit; các file trùng nhau (`bj02.js`, `shared-patterns.js`, `components.css`, `golden.mjs`) nên không tách lại được 3 + 2 + 2 commit như plan. Sau khi sửa lỗi 1–2 và chụp lại golden: người dùng chọn gộp (vd. một commit mã 5.8.0–5.9.1 + một commit tài liệu) — ghi lệch này vào mục 6 của từng plan.
