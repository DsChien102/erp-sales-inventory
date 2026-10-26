# T7-P · Giai đoạn 3 — Hoàn thiện prototype Theme 7

> Theme: Theme 7 Inventory · Trạng thái: Plan ✅ (duyệt 2026-10-26 — mục 0.4, mọi điểm theo đề xuất) | Làm ⬜ | Review ⬜
> Thuộc [T7-P](T7-P-thiet-ke-lai-luong.md) mục 11, Giai đoạn 3. Làm **sau** Giai đoạn 2 (✅ commit `534156bef`, prototype v5.20.1). Xong plan này mới sang Giai đoạn 4 (chốt đặc tả, mục 7.3) và Giai đoạn 5 (Flutter).
> Thiết bị: **cả iPhone và web đều là thiết bị chính** ở mọi màn (T7-P mục 2). Mọi bước kiểm chạy cả hai khung.
> Ước lượng: **~8–9 ngày, 8 gói, mỗi gói một commit** (T7-P mục 11 ghi 2–3 ngày là ước lượng trước khi biết khối góp ý dồn lại từ chặng 1–6; xem mục 0.2). Người làm: bạn. Review: phiên plan / review, sau mỗi gói.

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/` nếu không ghi khác. Câu trong ngoặc kép là chữ hiển thị, chép nguyên văn; **(mới)** = chữ mới, vào T7-P mục 13 khi ghi lại. Chuỗi chữ của spec giữ nguyên; đổi chữ = đề xuất ở mục 13 (T7-P mục 2).

## 0. Brief

### 0.1 Mục tiêu (lấy từ T7-P mục 1, các tiêu chí Giai đoạn 2 chưa đạt)

| # | Tiêu chí T7-P mục 1 | Sau Giai đoạn 2 | Plan này phải đạt |
|---|---|---|---|
| 3 | Critique toàn theme ≥ 32/40, 0 vấn đề P0 / P1; `audit` không còn lỗi tương phản / vùng chạm | Chưa đo lại (gốc 24/40, 2026-10-15); audit chỉ chạy theo từng BJ | Critique ≥ **32/40** ở cả hai khung, 0 P0 / P1; audit **toàn theme** 0 lỗi tương phản / vùng chạm / tên nút |
| 4 | Không ngõ cụt | Còn ngõ cụt đã biết: K4 trên iPhone ở chế độ Toàn Theme 7, BJ-17 xác lập xong không trả về BJ nguồn, thẻ kho không mở được phiếu nhận BJ-02, BJ-14 không có lối quay lại sau khi xử lý việc chặn | Mọi màn / trạng thái có lối ra; **công cụ dò ngõ cụt** (G3-5) 0 lỗi |
| 6 | Demo đi một mạch | `SC_demo` chạy 0 lỗi nhưng sổ kho **tĩnh** — sau bước 3–6 tồn BJ-01 lệch cuối kỳ thẻ kho | Sổ kho sống tối thiểu (Q1): cuối kỳ thẻ kho = tồn BJ-01 sau mọi bước của `SC_demo` |
| 2 | Prototype là nguồn duy nhất, không lớp vá | `core.js` đã sạch; **CSS chưa**: `screens.css` 5.583 dòng, ~50 khối `vNNN-*.css` cũ (dòng 1–5.097), **1.655 `!important`**, ~920 dòng chọn theo `[data-active-uif=…]`; còn `data-v350-action` / `data-v360-action` | CSS gom theo BJ, `!important` ≤ mục tiêu ở 0.4 Q4, không còn tên `v3xx` trong thuộc tính |

Không thuộc plan này: chốt đặc tả (Giai đoạn 4 — áp mục 13, đổi `IN_REVIEW` → chốt, các dòng ⬜ "chốt đặc tả 7.3"); thành phần DS vào `vet45_design_system` (Giai đoạn 5); quét mã vạch thật (hoãn, HF1 mục 8); nhiều kho.

### 0.2 Đầu vào: việc còn mở từ chặng 1–6

Gom từ mục Review của các plan chặng và T7-P mục 11 "Đầu vào cho Giai đoạn 3". Cột "Gói" là nơi xử lý trong plan này. **Kiểm lại từng dòng trước khi làm** (một số có thể đã được sửa ngang ở chặng sau): còn thì sửa, hết thì ghi "đã hết" ở mục 9.

| # | Nguồn | Việc | Gói |
|---|---|---|---|
| 1 | T7-P 14 (chặng 2) | **BJ-13 và `SC_journey_2` chưa từng được review** (plan BJ-13 mục 10 còn "(Phiên review điền.)") | G3-0 |
| 2 | Chặng 1 góp ý 7 | Chip có số hai cách (`ds24Chip(…, count)` vs `k7FilterChips` nhét số vào chữ + `k7-chip--zero`) | G3-2 |
| 3 | Chặng 1 góp ý 8 | 068 lệch số kiểm soát: "Sửa số kiểm soát" phải mở 067 và focus ô "Tổng số lượng kiểm soát" | G3-6 |
| 4 | Chặng 1 góp ý 11 | Enrofloxacin 3 chai "Hư hỏng" trong tệp đầu kỳ nhưng BJ-01 ghi tồn vật lý 0; "Nguồn và thời điểm cập nhật" không phải số dư đầu kỳ | G3-4 |
| 5 | HF1 mục 8 điểm 4–8 | Esc đóng sheet BJ-01 web focus rơi về `BODY`; `aria-selected` (001) vs `aria-current` (009); 015 web cột "Tình trạng" 240px làm cột "Sản phẩm" gãy dòng; 008 web thứ tự Tab ngược thứ tự nhìn; K2 iPhone nhãn "{tên}:" còn dấu hai chấm | G3-2 (4, 5), G3-6 (6, 7, 8) |
| 6 | BJ-03 review | Mã chết khối `v397` (`val03ScopeGroupsHtml`, `val03EvidenceSheet`…); `tokenStale` không được gán | G3-1 |
| 7 | BJ-02 review, BJ-04/05 ghi chú 9 | CSS chết `.bj02-*`, `v392`, `v470`, `.bj05-radio`, `.bj05-selection-row`, `.bj05-pick-lot-*` | G3-1 |
| 8 | BJ-04/05 ghi chú 8 | BJ-01 SCR-003 vẫn ghi giữ hàng 12 hộp của SO-260817-08 (lệch BJ-04) | G3-4 |
| 9 | Chặng 4 bảng rủi ro, BJ-09 ghi chú | Tylosin TY2408 ở BJ-01 vẫn 11 lọ sau tiêu hủy; Amox ở BJ-01 không theo lô nhưng BJ-06 theo lô AM2505 | G3-4 |
| 10 | Chặng 4 góp ý 1–3 | 041 `REJECTED` icon đồng hồ + thiếu "Lô" / "Số lượng"; 037 nút "Đúng hàng" xám → **"Chọn phần hàng"**; 037 tiêu đề "Việc tiếp theo" khi chỉ có ghi chú, badge lặp chữ | G3-6 |
| 11 | Chặng 4 góp ý 4 | `PRICE_BASIS_REQUIRED` không với tới được bằng luồng thật | G3-4 |
| 12 | BJ-09 ghi chú | BJ-02 / BJ-06 còn vùng ảnh cũ `bj06EvidenceZone`, chưa đổi sang `k5Evidence` | G3-2 |
| 13 | Chặng 5 góp ý 1–3 | 079 web nội dung chính ở cột hẹp (dùng `k7Split({ wideMain: true })`); tiêu đề "Kết luận" luôn màu cảnh báo; 044 iPhone "Bán / được" gãy dòng | G3-6 |
| 14 | Chặng 5 góp ý 4 + T7-P 11 | BJ-17 xác lập xong không trả kết quả về BJ nguồn (`onUnknownResolved` chưa có); nhãn `data-v350-action="handoff-unknown"` | G3-3 |
| 15 | Chặng 5 góp ý 5 | `bj17ConfirmSheet` so bản ghi với chính nó (phép kiểm luôn đúng) | G3-3 |
| 16 | Chặng 5 góp ý 7 | "Kho trung tâm" còn ở phạm vi `REC-UNKNOWN-03` và K3 của BJ-08 (app một kho) | G3-4 |
| 17 | Chặng 5 góp ý 8 | 044 dòng đã đếm vẫn dưới chip "Chưa đếm" tới lần dựng sau | G3-6 (chỉ khi critique nêu) |
| 18 | Chặng 6 góp ý 2 | 056 "Trước / Sau" và cột "Tồn" sắp theo loại ngày đang đọc — phải theo thứ tự ghi nhận | G3-4 |
| 19 | Chặng 6 góp ý 3 | Hai biến quay lại BJ-11 (`cr11ReturnCase`, `cr11ReturnMovement`) → một `cr11Return = { kind, id }` | G3-3 |
| 20 | Chặng 6 góp ý 4 | `bj14Money` / `bj15Money` trùng; NBSP chưa nằm trong `t7FmtMoney`; mã thừa `bj15Report(state)`, `bj15ExportStart` trả `p` | G3-2 |
| 21 | Chặng 6 góp ý 5 + T7-P 11 | BJ-02 chưa có màn xem phiếu đã nhận → thẻ kho không có "Mở phiếu gốc" cho dòng Nhận hàng | G3-5 |
| 22 | BJ-14 mục 11 | Không có lối "Về giá vốn" sau khi xử lý việc chặn ở BJ-03 / BJ-11 / BJ-16 | G3-5 |
| 23 | T7-P 13 (⬜ đề xuất) | iPhone Toàn Theme 7: màn kết quả K4 không có lối về Home ngoài đi vòng | G3-5 |
| 24 | T7-P 11 | Toast: nút đóng 20 × 20; toast không được che nút chân | G3-2 |
| 25 | T7-P 11, chặng 5 góp ý 9 | Dòng bảng web `<tr tabindex>` chưa có vai trò / tên (BJ-11 / 14 / 15 / 16) | G3-2 |
| 26 | T7-P 11 | Bẫy focus của sheet viết riêng ở **11 tệp** (`bj05`, `bj06`, `bj07`, `bj08`, `bj09`, `bj10`, `bj11`, `bj13`, `bj14`, `bj15`, `bj16`); Esc riêng ở 16 tệp | G3-2 |
| 27 | T7-P 11 | Sổ kho tĩnh; BJ-01 "Nguồn và thời điểm cập nhật" còn fixture mốc 27/08 | G3-4 (theo Q1) |
| 28 | Chặng 6 ghi chú | Chip lọc BJ-01 cao 34 (vùng chạm mở rộng bằng `::after`, cần đo lại); nút "Sửa ngưỡng" CAP-01 cao 18 px | G3-7 |
| 29 | A11 / Giai đoạn 2 | Gom CSS theo BJ, bỏ `!important`, xoá luật chết | G3-1 |
| 30 | BJ-13 review (G3-0) 1 | `UIF-13_SCR-089_UNKNOWN`: K3 lặp câu "Chuyển đúng … sang xác minh" (chữ `safe` của spec + câu mặc định của `k3Unknown`) | Giai đoạn 4 (sửa chữ spec) |
| 31 | BJ-13 review 2 | Mã `SP-00421` (5 chữ số) của "Vaccine Canine X" ở `bj03.js` / `bj13.js`; sản phẩm không có trong BJ-01 | G3-4 |
| 32 | BJ-13 review 3, 4 | iPhone 085 tên nguồn gãy ở dấu gạch nối; 089 nút "Về công việc điều chỉnh" gãy hai dòng | G3-6 |
| 33 | BJ-13 review 5 | Home sau `SC_journey_2` vẫn "3 nhận hàng" sau khi duyệt (hàng chờ tĩnh) | G3-4 (Q1) |

### 0.3 Thứ tự gói và lý do

| Gói | Việc | Đổi giao diện? | Ước lượng |
|---|---|---|---|
| **G3-0** | Review bù BJ-13 + `SC_journey_2`; chụp mốc nền Giai đoạn 3 | Không | ✅ 2026-10-26 (đạt, 4 góp ý nhỏ → bảng 0.2 #30–33) |
| **G3-1** | Dọn CSS và mã chết | **Không** — golden phải khớp hoàn toàn | 2 ngày |
| **G3-2** | Khung dùng chung: sheet / focus, toast, dòng bảng, chip có số, tiền, vùng ảnh | Có, nhỏ, có liệt kê | 1,5 ngày |
| **G3-3** | Kết quả chưa rõ (K3 → BJ-17 → BJ nguồn) và các đường quay lại | Có (BJ nguồn sau xác lập) | 0,75 ngày |
| **G3-4** | Dữ liệu một nguồn: sổ kho, fixture lệch | Có (số) | 1,5 ngày (theo Q1) |
| **G3-5** | Luồng và Home Kho: không ngõ cụt; công cụ dò ngõ cụt | Có | 1 ngày |
| **G3-6** | Critique gốc mới → sửa P0 / P1 / P2 + góp ý nhỏ còn lại → `/impeccable polish` | Có | 1,5 ngày |
| **G3-7** | Critique lại + `/impeccable audit` toàn theme + audit dọc `SC_demo` → ghi lại | Không (trừ lỗi audit) | 0,75 ngày |

Lý do thứ tự: **G3-1 trước** vì là gói duy nhất được golden bảo vệ trọn vẹn (giao diện không đổi) — làm sau khi đã đổi giao diện thì mất lưới an toàn. G3-2 / 3 / 4 là nền mà critique sẽ chấm lại (sửa trước để critique G3-6 không nêu lại chính các lỗi đã biết). Critique chạy ở **đầu G3-6** (không phải đầu plan) để điểm phản ánh bản đã dọn, và việc sửa theo critique đi thẳng sau đó. G3-7 đo kết quả cuối.

### 0.4 Đã chốt khi duyệt plan (2026-10-26): **mọi điểm theo cột "Đề xuất"**

| # | Câu hỏi | Đề xuất | Lý do / cách khác |
|---|---|---|---|
| Q1 | Sổ kho có "sống" không (thao tác chạy trong prototype sinh biến động vào thẻ kho và tồn BJ-01)? | **Nối sống tối thiểu**: một sổ chung `t7Ledger` (G3-4); chỉ các thao tác đã ghi kho có trong `SC_journey_*` / `SC_demo` — BJ-02 duyệt nhận hàng, BJ-05 bàn giao, BJ-06 nhận hàng trả, BJ-08 duyệt kiểm kê, BJ-09 đổi tình trạng, BJ-10 xác nhận tiêu hủy, BJ-11 duyệt sửa sai, BJ-07 bàn giao trả NCC | Không nối: demo bước 8 (thẻ kho) mâu thuẫn bước 3–6 trước mặt người xem — trái tiêu chí 6. Nối đầy đủ (mọi trạng thái, đảo ngược khi từ chối…): ~3 ngày, không cần cho prototype |
| Q2 | Xem phiếu nhận hàng đã ghi (BJ-02) bằng màn nào? | **SCR-011 thêm trạng thái chỉ đọc `RECORDED`** (mới): cùng bảng "Theo chứng từ · Thực nhận · Chênh lệch", không chân duyệt, tiêu đề "Phiếu nhận {chứng từ}" **(mới)**, phụ "{NCC} · Đã ghi {ngày}" **(mới)**. Mở từ BJ-15 056 "Mở phiếu gốc" và BJ-01 "Nguồn và thời điểm cập nhật" | Thêm màn mới SCR-0xx: thêm Screen Contract mới cho một việc chỉ đọc; 011 đã có đúng bảng cần xem |
| Q3 | Lối về Kho từ màn kết quả K4 trên iPhone (chế độ Toàn Theme 7) | **K4 hiện thanh 5 tab của app** (giống màn gốc theme; luồng đã xong nên không cần ẩn) — không thêm chữ | Thêm nút "Về Kho" vào chân K4: chân đã có hai nút (phụ \| chính), thêm nút thứ ba trái quy tắc "một hành động chính" |
| Q4 | Mục tiêu `!important` sau dọn CSS | **≤ 60** (chỉ còn chỗ đè luật khung Figma / DS không sửa được nguồn), mỗi chỗ còn lại có chú thích lý do | Về 0: phải viết lại luật khung Figma (`.figma-calibrated-shell …`) — để Giai đoạn 5 khi CSS không còn dùng làm nguồn |
| Q5 | Critique dùng công cụ nào để so với gốc 24/40? | **`/impeccable critique`** phạm vi `index.html` cả theme, cùng 10 heuristics như bản 2026-10-15, chạy **hai lần** (iPhone, web), điểm Giai đoạn 3 = điểm thấp hơn | Chấm một khung: web dễ được điểm cao hơn, che lỗi iPhone |

---

## 1. Quy tắc chung cho mọi gói

1. **Mốc golden:** mỗi gói so với mốc chụp **trước** gói đó (`tools/.golden-g3-<n>-base` / `-web-base`) và chụp mốc sau (`tools/.golden-g3-<n>` / `-web`). Không chụp lại mốc giữa gói (bài học T7-P 14.1). **Chụp tuần tự** — iPhone xong rồi mới web; không chạy hai lệnh `capture` song song (cổng Chrome cố định).
2. Máy chủ: `python3 -m http.server 8765 --bind 127.0.0.1` trong thư mục `html/`.
3. Mỗi gói: `node --check app/*.js harness/*.js tools/golden.mjs`; golden 0 lỗi JS ở cả hai khung; chỉ các ca liệt kê ở mục "Golden" của gói được khác — **lọc bằng danh sách tiền tố** như review chặng 6, ca ngoài danh sách phải đọc `.txt` để chứng minh khác có chủ đích, không thì sửa.
4. **GitNexus trước khi sửa** (CLAUDE.md): `node .gitnexus/run.cjs impact <hàm> --direction upstream --repo erp-sales-inventory` cho mọi hàm dùng chung bị đổi (liệt kê ở từng gói). Chỉ mục cũ cho kết quả sai (review chặng 6: `bj15Check` "CRITICAL" với người gọi là mã Dart) → **chạy `node .gitnexus/run.cjs analyze` đầu mỗi gói**. HIGH / CRITICAL thật → dừng, báo người dùng. Trước commit: `node .gitnexus/run.cjs detect-changes --scope all --repo erp-sales-inventory`; `AGENTS.md` / `CLAUDE.md` bị `analyze` sửa số thống kê → **không** đưa vào commit của gói.
5. Phiên bản: G3-1 → **5.21.0**, G3-2 → 5.22.0, G3-3 → 5.23.0, G3-4 → 5.24.0, G3-5 → 5.25.0, G3-6 → 5.26.0, G3-7 → 5.26.x. Mỗi gói: `manifest.json`, `harness/workbench.js` (`version`), badge `index.html`, CHANGELOG `[5.2x.0] — Giai đoạn 3 · G3-n …`, `python3 tools/sync-registry.py`.
6. Chữ: chỉ dùng chữ của spec / T7-P mục 13; chữ **(mới)** của plan này ghi mục 13 ở bước ghi lại của gói.
7. Hai khung: mọi sửa giao diện xem ảnh iPhone **và** `@web` của ca liên quan; trên web không cột 402 px / bản iPhone kéo giãn; trên iPhone không bảng ép nhỏ, số – ĐVT không gãy dòng.

---

## G3-0 — Review bù BJ-13 + mốc nền (phiên review)

1. Phiên review điền plan BJ-13 mục 10 theo khuôn review chặng 4–6: `node --check`, golden `UIF-13_*` / `SC_bj13_*` / `SC_journey_2` hai khung, tiền chỉ chủ cửa hàng, tài liệu bước E (SCR-085…089 / UIF-13 `IN_REVIEW`, không `### vX.Y`), ảnh. Lỗi chặn → thành mục **G3-0 R1…** sửa trước G3-1 (CHANGELOG `[5.20.2]`); góp ý nhỏ → thêm dòng vào bảng 0.2.
2. Chụp mốc nền Giai đoạn 3 ở HEAD sạch: `tools/.golden-g3-1-base` / `-web-base`; phải khớp hoàn toàn `tools/.golden-chang6*` (nếu G3-0 có sửa thì khớp trừ ca của sửa đó).
3. Ghi T7-P mục 14: BJ-13 review ✅, `SC_journey_2` review ✅.

## G3-1 — Dọn CSS và mã chết (giao diện không đổi)

**Mục tiêu:** `screens.css` / `components.css` không còn khối `vNNN-*.css`; CSS của mỗi BJ nằm trong **một** khối có tiêu đề BJ; `!important` ≤ mục tiêu Q4; không đổi một điểm ảnh nào.

**Bước:**

1. **Đo:** `node tools/golden.mjs usage <dir>` (1 worker) trên toàn bộ ca, hai khung → danh sách luật không dùng. Ghi số đầu: số dòng, số luật, `!important`, luật `[data-active-uif=…]` của từng tệp (mục 9).
2. **Xoá luật không dùng** ở cả hai khung (luật chỉ dùng ở web vẫn là luật dùng). Gồm: `.bj02-*`, `v392`, `v470`, `.bj05-radio`, `.bj05-selection-row`, `.bj05-pick-lot-*` (0.2 #7) nếu `usage` xác nhận không dùng. **Dùng bộ tách luật CSS** (đã có từ BJ-14 / 15), không regex (bài học BJ-14 mục 9 điểm 10).
3. **Gom theo BJ:** với từng BJ theo thứ tự chặng (12, 01, CAP-01, 02, 03, 13, 04/05, 06, 09, 07, 10, 08, 11, 16/17, 14, 15) và Hub: chuyển mọi luật chỉ áp cho BJ đó (`[data-active-uif="UIF-NN"]`, tiền tố lớp của BJ) từ các khối `vNNN-…` về khối của BJ ở cuối `screens.css`. Luật dùng cho nhiều BJ → khối "Khuôn dùng chung" trong `components.css` (theo K1…K7). **Giữ thứ tự hiệu lực**: khi chuyển một luật xuống dưới, kiểm không có luật nào giữa vị trí cũ và mới cùng độ ưu tiên đè lên nó; nếu có, gộp luôn luật đó.
4. **Bỏ `!important`** từng khối BJ sau khi gom: bỏ khi không còn đối thủ; còn đối thủ là luật khung Figma (`.figma-calibrated-shell …`, `[data-ds-prop-density]`) thì giữ + chú thích một dòng `/* đè: <luật> */`.
5. **Mã chết JS:** khối `v397` ở `bj03.js` (`val03ScopeGroupsHtml`, `val03EvidenceSheet`…), `tokenStale` (gán hoặc bỏ), hàm không ai gọi (`grep` + chỉ mục GitNexus mới); `bj15Report(state)` bỏ tham số, `bj15ExportStart` bỏ `return p`.
6. Kiểm sau **mỗi BJ** (không đợi hết gói): golden **khớp hoàn toàn** — lệch là lỗi gom, sửa ngay (thường do thứ tự / độ ưu tiên).

**Golden:** không ca nào được khác.
**Commit:** `refactor(prototype): T7-P G3-1 — gom CSS theo BJ, bỏ luật chết (v5.21.0)`.

## G3-2 — Khung dùng chung

**`impact` trước khi sửa:** `ds24Sheet`, `syncDialogFocus`, `showToastCanonical`, `k7Table`, `k7FilterChips`, `ds24Chip`, `t7FmtMoney`, `k5Evidence`, `bj06EvidenceZone`.

1. **Sheet / hộp thoại một chỗ** (0.2 #26, #5 điểm 4): thêm `t7DialogKeys` trong `core.js` — một listener `keydown` pha capture: khi có `#app-screen [role="dialog"]`: Esc → gọi `onDialogClose[activeFlowId]?.()` (BJ đăng ký hàm đóng sheet của mình), không có thì bấm phần tử `[data-dialog-close]` đầu tiên trong hộp thoại; Tab / Shift+Tab đi vòng trong hộp thoại (chép từ listener "Sheet là modal" ở `bj15.js` — bản đầy đủ nhất). Focus khi mở / trả về nút đã mở: `syncDialogFocus` đã có, giữ. **Xoá** 11 bẫy Tab và 16 listener Esc riêng; mỗi BJ chỉ còn `onDialogClose["UIF-NN"] = …`. Kiểm: mọi sheet của mọi BJ, web — Tab vòng, Esc đóng, focus về nút đã mở (BJ-01 sheet lô / nguồn — lỗi HF1 điểm 4).
2. **Toast** (0.2 #24): nút đóng vùng chạm ≥ 44 × 44 ở iPhone (icon giữ 20, vùng mở rộng bằng `::after` như chip); toast đặt **trên** chân màn khi màn có chân (đo chiều cao `.app-footer` lúc hiện), không che nút. Kiểm bằng ca có toast sau bấm nút chân (vd. `SC_bj15_*` "Đã tải lại số liệu", `SC_cap_*` "Đã lưu chính sách").
3. **Dòng bảng web** (0.2 #25, #5 điểm 5): `k7Table` thống nhất một cách — **ô đầu chứa nút `.k7-row-link`** (đã có ở K6) là phần tử nhận Tab / Enter, có tên = tên dòng; `<tr>` bấm chuột được nhưng **bỏ `tabindex`**; dòng đang chọn (K7 hai cột) dùng `aria-current="true"` (bỏ `aria-selected` ở `bj01.js`, `bj02.js`, `bj06.js`, `hub.js`). Xoá các listener "Enter trên `<tr>`" riêng (BJ-11 / 14 / 15 / 16).
4. **Chip có số một cách** (0.2 #2): `k7FilterChips` gọi `ds24Chip(key, label, selected, attrName, count)`; bỏ `k7-chip--zero`. Ảnh chip BJ-12 / CAP-01 / BJ-15 / K6 đổi (số tách `<span>`, số 0 nhạt).
5. **Tiền** (0.2 #20): NBSP trước "đ" đưa vào `t7FmtMoney`; xoá `bj14Money` / `bj15Money` (thay bằng `t7FmtMoney`). Kiểm: không còn `" đ"` (dấu cách thường) trước "đ" trong DOM của bất kỳ ca nào (thêm bước kiểm vào golden, lỗi → "lỗi JS").
6. **Vùng ảnh** (0.2 #12): BJ-02 (008) và BJ-06 đổi sang `k5Evidence` / `k5RegisterEvidence`; xoá `bj06EvidenceZone`. Chữ giữ đúng chữ hiện tại của từng màn (dùng `label` / `emptyTitle` / `hint`).

**Golden được khác:** ca có sheet (chỉ khi focus / vòng focus hiện trong ảnh), ca có toast, ca bảng web của BJ-01 / 11 / 14 / 15 / 16 / K6 (ô đầu thành nút), ca có chip có số (BJ-01, BJ-12, CAP-01, K6, BJ-15), ca vùng ảnh BJ-02 / 06. Không ca nào đổi chữ ngoài số trên chip.
**Commit:** `refactor(prototype): T7-P G3-2 — khung dùng chung: hộp thoại, toast, dòng bảng, chip, tiền, vùng ảnh (v5.22.0)`.

## G3-3 — Kết quả chưa rõ và đường quay lại

**`impact`:** `k3Unknown`, `onUnknownHandoff` (và các BJ đăng ký), `bj17RecoveryCase`, `bj17ConfirmSheet`, `bj11BackToCase`.

1. **Đổi nhãn:** `data-v350-action="handoff-unknown"` → `data-k3-action="handoff"` (`k3Unknown`, `bj06.js`, listener ở `bj17.js`, `golden.mjs`); `data-v350-action="cf12-*"` / `data-v360-action="fallback-exit"` (`bj12.js`) → `data-bj12-action="…"`. Sau gói: `grep -c "data-v3[0-9][0-9]" app/*.js` = 0.
2. **`onUnknownResolved[sourceFlow]`** (0.2 #14): đối xứng `onUnknownHandoff`; BJ-17 gọi khi hồ sơ "Đã xác lập" với `{ operationId, outcome: "RECORDED" | "NOT_RECORDED" }`. Mỗi BJ có K3 (02, 05, 06, 07, 08, 10, 11, 12, 13, 14) đăng ký: đổi trạng thái thao tác nguồn (vd. BJ-11 048 "Tiêu hủy TH-260906-02" hết "Đang xác minh" → "Đã ghi"; `NOT_RECORDED` → mở khoá để làm lại). Màn kết quả của BJ-17 thêm bước tiếp **"Mở {nghiệp vụ} {mã}" (mới)** về đúng màn của thao tác nguồn.
3. `bj17ConfirmSheet` (0.2 #15): chụp bản ghi lúc mở sheet, so lúc bấm; khác → `CONFLICT` như `crConfirmSheet`.
4. `cr11Return = { kind: "case" | "movement", id }` thay `cr11ReturnCase` / `cr11ReturnMovement` (0.2 #19; sửa `bj11.js`, `bj15.js`, `bj16.js`).

**Golden được khác:** `SC_bj17_*`, `SC_journey_5` từ bước xác lập, ca BJ nguồn sau xác lập (thêm kịch bản `SC_g3_unknown_back` mỗi nhóm: BJ-11 → BJ-17 xác lập → BJ-11 048; BJ-05 → … → 026).
**Commit:** `… G3-3 — K3 → BJ-17 → BJ nguồn (v5.23.0)`.

## G3-4 — Dữ liệu một nguồn

**`impact`:** `bj01Products` (mọi người đọc), `bj15Ledger`, `bj15Check`, `BJ15_MOVES`, hàm ghi nhận của các BJ ghi kho ở Q1.

1. **Sổ chung `t7Ledger`** (theo Q1) trong `app/shared-ledger.js` (nạp sau `bj01.js`, trước các `bjNN.js` ghi kho): giữ `BJ15_MOVES` làm dữ liệu gốc; `t7Ledger.post({ productId, lot, kind, doc, delta, state, sourceFlow, opId, actor })` thêm biến động (ngày nghiệp vụ = ngày ghi nhận = `BJ15_TODAY` + giờ hiện tại của fixture) và cập nhật `bj01Products` (`physical`, lô, tình trạng). `t7Ledger.reset()` gọi từ mọi `…Restore()` / `…Seed()` để ca golden mở thẳng luôn bắt đầu từ sổ gốc. Các thao tác ở Q1 gọi `post` đúng lúc **ghi nhận** (sau duyệt / xác nhận), không lúc gửi duyệt.
2. `bj15Check` chạy **sau mỗi `post`** (không chỉ lúc nạp): cuối kỳ thẻ kho = tồn BJ-01 sau từng bước của `SC_demo`. Thêm bước kiểm vào cuối `SC_demo` (lỗi → "lỗi JS").
3. **Fixture lệch** (0.2 #4, #8, #9, #11, #16): Enrofloxacin "Hư hỏng" 3 chai — tồn BJ-01 theo tệp đầu kỳ (chọn số theo một nguồn, ghi mục 9); BJ-01 giữ hàng SO-260817-08 theo BJ-04; Tylosin TY2408 trừ tiêu hủy khi `SC_journey_4` chạy (do sổ sống) và số mặc định khớp BJ-10; Amox: chọn **một** cách (theo lô hoặc không) cho BJ-01 / 06 / 09 / 14 / 15 — đề xuất giữ không theo lô (BJ-14 / 15 đã theo), BJ-06 bỏ lô AM2505 ở hàng trả; thêm một lô "Hỏng" không giá vốn, không việc đang chạy để `PRICE_BASIS_REQUIRED` với tới được (BJ-09 036 / Home đổi một dòng); "Kho trung tâm" → bỏ khỏi phạm vi `REC-UNKNOWN-03` và K3 BJ-08.
4. **BJ-01 "Nguồn và thời điểm cập nhật"** (0.2 #27) đọc từ sổ chung: "Nhận hàng gần nhất" / "Bán gần nhất"… là biến động mới nhất cùng loại của sản phẩm; mốc = giờ biến động mới nhất.
5. **056 "Trước / Sau"** (0.2 #18): luôn theo thứ tự ghi nhận, kể cả khi công tắc đang "Ngày nghiệp vụ"; cột "Tồn" của thẻ kho ở chế độ "Ngày nghiệp vụ" hiện **tồn theo sổ** (ghi nhận) — nếu hai thứ tự khác nhau ở một dòng, dòng đó thêm phụ "Ghi nhận {dd/mm}" (đã có). Thêm một dòng fixture có ngày ghi nhận vắt qua chứng từ khác để ca golden thấy được.

**Golden được khác:** mọi ca có số tồn đổi do fixture (liệt kê theo nhóm ở mục 9, đối chiếu `.txt` chỉ khác số), `SC_journey_2…6` và `SC_demo` từ bước có ghi kho, `UIF-15_*` / `SC_bj15_*`, BJ-01 sheet nguồn.
**Commit:** `… G3-4 — sổ kho chung, fixture một nguồn (v5.24.0)`.

## G3-5 — Luồng, Home Kho, không ngõ cụt

1. **Công cụ dò ngõ cụt** (chạy trước để có danh sách, chạy lại cuối gói): thêm chế độ `node tools/golden.mjs deadends` — với mọi ca mở thẳng (`uif` × `screen` × `state`) ở chế độ Toàn Theme 7, cả hai khung: màn phải có **ít nhất một** trong: nút quay lại, nút chân bật, liên kết / nút sang màn khác bật, thanh tab / thanh bên; trạng thái lỗi / `PERMISSION_DENIED` / K3 phải có lối ra đặt tên. In danh sách ca vi phạm; 0 là đạt.
2. **K4 trên iPhone** (Q3): màn kết quả K4 ở chế độ Toàn Theme 7 hiện thanh 5 tab; chế độ BJ giữ như cũ. Áp ở `k4Result` (một chỗ).
3. **Phiếu nhận đã ghi** (Q2): SCR-011 `RECORDED` chỉ đọc; `bj15SourceOf` thêm nguồn `UIF-02` (dòng "Nhận hàng" có phiếu BJ-02) → "Mở phiếu gốc"; BJ-01 nguồn "Nhận hàng {mã}" là liên kết. Quay lại về đúng màn đã mở.
4. **"Về giá vốn"** (0.2 #22): khi vào BJ-03 / BJ-11 / BJ-16 từ việc chặn của BJ-14 074, màn kết quả của BJ đó có bước tiếp **"Về giá vốn" (chữ đã có ở 077)** mở lại 074 của lần tính (lần kế tiếp nếu đã sinh); nhớ nguồn như `cr11Return`.
5. **Home Kho rà toàn bộ** (T7-P mục 2 bảng "Vị trí trên Home Kho"): mỗi dòng của bảng mở đúng BJ / màn / vai; "Cần chú ý" chỉ hiện khi có việc và số đọc từ nguồn (không gõ cứng); "Quản lý kho" đủ 5 khu, mỗi mục có lối vào. Thêm kịch bản `SC_home_all` đi qua mọi lối vào của Home và về lại Home (hai khung).
6. Kịch bản `SC_journey_*` / `SC_demo` không được gãy.

**Golden được khác:** ca K4 ở chế độ Toàn Theme 7 iPhone (thanh tab), `UIF-02_SCR-011_RECORDED` (mới), `SC_bj15_*` có "Mở phiếu gốc" dòng nhận hàng, ca BJ-03 / 11 / 16 vào từ BJ-14, `SC_home_all` (mới), ca do công cụ dò ngõ cụt chỉ ra.
**Commit:** `… G3-5 — không ngõ cụt, Home Kho đủ lối vào (v5.25.0)`.

## G3-6 — Critique gốc mới, sửa, polish

1. **Critique** (Q5): `/impeccable critique` phạm vi toàn theme, khung iPhone rồi khung web, cùng 10 heuristics với bản 2026-10-15 (`.impeccable/critique/2026-10-15T17-12-32Z__…md`); lưu vào `.impeccable/critique/`. Ghi điểm từng heuristic hai khung vào mục 9, so với 24/40. Kiểm riêng: P0 / P1 / P2 của bản gốc (màu tiền / tồn, màn duyệt chôn quyết định, IA hai Home, ngõ cụt, chữ chuyên môn) đã hết chưa.
2. **Sửa** theo thứ tự P0 → P1 → P2 của critique mới, rồi các góp ý nhỏ còn lại ở 0.2 (#3, #5 điểm 6–8, #10, #13, #17 nếu critique nêu). Mỗi sửa: ca golden khác ghi mục 9. Sửa đổi chữ → đề xuất mục 13, không sửa thẳng chữ spec.
3. **`/impeccable polish`** theo chặng (1 → 6), mỗi chặng một lượt, hai khung — chỉ chỉnh chi tiết (khoảng cách, căn hàng, nhịp, trạng thái hover / focus), không đổi bố cục đã duyệt ở brief các BJ.

**Golden được khác:** ca của các sửa, liệt kê theo P / góp ý ở mục 9.
**Commit:** `… G3-6 — sửa theo critique, polish (v5.26.0)`.

## G3-7 — Đo cuối và ghi lại

1. **Critique lại** (như G3-6 bước 1): đạt khi **cả hai khung ≥ 32/40, 0 P0 / P1**. Chưa đạt → sửa và chạy lại (tối đa hai vòng, rồi báo người dùng).
2. **`/impeccable audit` toàn theme**, hai khung, mọi màn / trạng thái mở thẳng + mọi sheet: chữ ≥ 4,5:1 (chữ lớn / icon ≥ 3:1); vùng chạm ≥ 44 × 44 ở iPhone (đo cả chip BJ-01, nút "Sửa ngưỡng" CAP-01 — 0.2 #28); mọi nút icon / ô nhập có tên; web: Tab đi hết, Enter mở, Esc đóng, focus về nút đã mở; không tràn ngang; không cột 402 px trên web. 0 lỗi là đạt.
3. **Audit dọc `SC_demo`** và `SC_home_all`, mọi bước, hai khung (bài học chặng 3): như trên + nút quay lại về đúng màn, toast không che nút chân, số tồn giống nhau giữa các BJ ở cùng thời điểm (theo Q1).
4. Công cụ dò ngõ cụt 0 lỗi; golden 0 lỗi JS hai khung; mốc cuối Giai đoạn 3: `tools/.golden-g3` / `-web`.
5. **Ghi lại:** CHANGELOG; T7-P mục 1 (tiêu chí 2, 3, 4, 6 ✅ hoặc ghi còn thiếu), mục 3 "Hiện trạng" (điểm critique mới), mục 11 (Giai đoạn 3 ✅, liên kết plan này), mục 13 (chữ mới của plan này, dòng "13 / 03 / mọi K4" ✅ theo Q3), mục 14 (bảng gói G3); Screen Contract của màn đổi hành vi ở plan này (SCR-011 `RECORDED`, K4 thanh tab, BJ-17 bước tiếp, SCR-056 "Trước / Sau") — sửa thẳng nội dung chính, giữ `IN_REVIEW`; `INDEX.md`; `sync-registry.py`.
6. Gửi người dùng ảnh: Home Kho hai khung, một K4 iPhone có thanh tab, 011 `RECORDED` web, `SC_demo` bước cuối hai khung, bảng điểm critique trước / sau.

## 9. Ghi chú khi làm

(Người làm điền theo từng gói: số đo đầu / cuối, ca golden khác, lệch plan và lý do.)

### G3-1 (5.21.0, 2026-10-26) — làm một phần, chưa commit

- **Mốc nền** khớp hoàn toàn `.golden-chang6*` (2164 / 1280). G3-0 phần review bù BJ-13 + `SC_journey_2` **chưa làm** (việc của phiên review).
- **Số đo:** `screens.css` 5.583 → 4.264 dòng, `components.css` 3.905 → 3.239; luật không dùng đã xoá 469; `!important` 1.632 → **84 khai báo / 55 luật** (mục tiêu Q4 ≤ 60 **chưa đạt**; mỗi luật còn lại có chú thích lý do). Golden **khớp hoàn toàn** hai khung.
- **Mã chết:** đã bỏ khối `val03*Html` / `val03EvidenceSheet` / `tokenStale` ở `bj03.js`; `bj15Report`, `bj15ExportStart` gọn lại.
- **Chưa làm — gom luật theo từng BJ (bước 3):** thử gom tự động làm lệch 39 ca iPhone / 68 ca web (BJ-02 SCR-084, BJ-12 web) vì có khai báo "chết" thắng lại khi đổi chỗ (vd. `.lot-extra-action { min-height: 36px }` của BJ-02 vốn thua luật khung Figma). Muốn gom phải xoá các khai báo chết trước (thử bằng `MODE=delete golden.mjs important`, ~2.600 / 6.568 khai báo xoá được, chạy mỗi lượt 3–10 phút mỗi khung) rồi mới đổi chỗ. Đã hoàn tác; **hoãn sang Giai đoạn 5**, khi CSS không còn là nguồn.
- **Công cụ mới:** `tools/golden.mjs important` + `tools/css-important.mjs` (đo / bỏ `!important`, có chế độ `MODE=delete`).

### G3-2 (5.22.0, 2026-10-26) — làm gần đủ, chưa commit

- **Đã làm:** hộp thoại một chỗ (`onDialogClose` + listener Esc / Tab ở `core.js`, xoá 11 bẫy Tab và 16 listener Esc riêng); trả focus về nút dòng bảng (sửa lỗi HF1 điểm 4: Esc đóng sheet BJ-01 web không còn rơi về `BODY`); `k7Table` có `rowOpen` (nút `.k7-row-open` ở ô đầu, bỏ `tabindex` của `<tr>` và các listener Enter trên `<tr>`, `aria-current` thay `aria-selected` ở BJ-01); `k7FilterChips` dùng `ds24Chip(…, count)`; NBSP trong `t7FmtMoney`, bỏ `bj14Money` / `bj15Money`, thêm kiểm "tiền dùng dấu cách thường" vào `golden.mjs`; vùng chạm nút đóng toast 44 × 44.
- **Chưa làm:** vùng ảnh BJ-02 (008) / BJ-06 sang `k5Evidence` (bước 6): BJ-06 tự tạo mã / băm / phiên bản ảnh và có chế độ chỉ đọc, `k5Evidence` chưa có hai thứ đó. Làm kèm G3-3 hoặc tách thành gói nhỏ riêng.
- **Toast:** không cần đo chiều cao chân: toast vốn đã nằm trên chân ở màn có `.figma-sticky-footer` (đo ở `UIF-05 SCR-026`, toast cách chân 10 px). Không đổi.
- **Golden:** 0 lỗi JS; ảnh khác chỉ ở dải chip có số (khoảng cách số – chữ) và chữ tiền NBSP (ảnh giống hệt). Mốc sau gói `tools/.golden-g3-2` / `-web`.
- **Cách làm:** một lần chụp so golden cho cả gói (không chụp sau mỗi bước) — mất khoảng 2 phút cho hai khung.

### G3-3 (5.23.0, 2026-10-26) — làm xong, chưa commit

- **Đã làm:** đổi nhãn `data-v3xx` (còn 0 trong `app/`); `onUnknownResolved` + hook cho BJ-05 / 06 / 07 / 09 / 10 / 11; nút "Mở {nghiệp vụ} {mã}" ở 083; `bj17ConfirmSheet` so với bản chụp lúc mở sheet; `cr11Return`. Chi tiết ở CHANGELOG `[5.23.0]`.
- **Kịch bản mới:** `SC_g3_unknown_back_bj05` (BJ-05 → BJ-17 → 026) và `SC_g3_unknown_back_bj11` (BJ-11 → BJ-17 → 048 "Đã ghi" → 049 "Đã ghi vào kho"), cả hai khung. Chỉ hai luồng này có đường xác lập tới được; các BJ khác mặc định chỉ "Gửi bộ phận hỗ trợ".
- **Chữ mới (mục 13):** BJ-11 049 `RECORDED`: "Đã ghi vào kho" · "Kết quả đã được xác minh; không cần sửa." · badge "Đã ghi".
- **GitNexus:** `impact k3Unknown` = HIGH (17 người gọi trực tiếp, đều là màn K3); chỉ đổi tên thuộc tính nút, hành vi giữ nguyên, golden mọi ca `*_UNKNOWN` khớp. Chưa chạy `impact` cho `bj17ConfirmSheet`, `crOpenSheet`.

### G3-4 (5.24.0, 2026-10-26) — làm gần đủ, chưa commit

- **Đã làm:** sổ chung `t7Ledger` (`app/shared-ledger.js`): `post` cộng vào tồn BJ-01 và thêm dòng thẻ kho BJ-15, kiểm cuối kỳ thẻ kho = tồn BJ-01 ngay sau mỗi `post`; tám thao tác ghi sổ (BJ-02 / 05 / 06 / 07 / 08 / 09 / 10 / 11); bước `9-check-ledger` cuối `SC_demo`; 056 "Trước / Sau" và cột "Tồn" theo thứ tự ghi nhận + dòng Amox nhập muộn; BJ-01 "Dữ liệu đến" 17/09 và sheet nguồn đọc từ sổ kho; bỏ dòng Enrofloxacin hư hỏng khỏi tệp BJ-12; lô Vitamin ADE hỏng không giá vốn (`SC_g3_price_basis` tới "Cần xác lập giá trị" bằng luồng thật); bỏ "Kho trung tâm" ở REC-UNKNOWN-03. Chi tiết ở CHANGELOG `[5.24.0]`.
- **Lệch plan:** không gắn `t7Ledger.reset()` vào từng `…Restore()` — BJ-01 trước đây không reset (nhận hàng cộng dồn cả trang) và mỗi kịch bản golden nạp lại trang nên bắt đầu từ sổ gốc; mọi `post` có `key` nên không ghi hai lần. Ghi nhận ở tên **phiếu nhận** (`REC-…`) thay vì chứng từ (`PN-260816-04` đã nhận một lần ở tháng 08 trong sổ gốc).
- **Chưa làm (0.2 #9, một phần #8):** Amox ở BJ-01 vẫn không theo lô còn BJ-06 (RET-L2) / BJ-08 / BJ-09 giữ lô `AM2505` (đổi BJ-06 làm gãy các bước của `SC_journey_3`); số giữ hàng Nobivac 12 chưa khớp tổng đơn BJ-04 (20) — chỉ đổi nguồn thành SO-260827-21. Sổ ghi theo sản phẩm nên số cuối kỳ không lệch.
- **Fixture BJ-07 dựng riêng:** mọi dòng trả nhà cung cấp có "3 bán được + 2 hỏng" bất kể sản phẩm; sổ lấy phần hỏng thiếu từ khả dụng. Nên dựng lại theo tồn BJ-01 ở đợt sau.
- **Golden:** 0 lỗi JS hai khung (2183 / 1292 ca); mọi dòng chữ khác đã gom nhóm (mốc dữ liệu BJ-01, Home / K5 có Vitamin ADE, BJ-17 scope, BJ-12 dòng mẫu, BJ-15 Amox, demo thẻ kho); mốc `tools/.golden-g3-4` / `-web`.
- **GitNexus:** `impact` chạy sau khi sửa: `bj15Ledger` MEDIUM (9, người gọi đều trong BJ-15 và ledger), `bj01ApplyReceipt` LOW (3).

## 10. Không làm

- Chốt đặc tả (Giai đoạn 4): áp các dòng ⬜ "chốt đặc tả 7.3" của T7-P mục 13 vào UC / BJ / PROC; đổi trạng thái tệp khỏi `IN_REVIEW`.
- Đổi bố cục / luồng đã duyệt ở brief các BJ (trừ khi critique nêu P0 / P1 — khi đó viết đề xuất, hỏi người dùng trước khi làm).
- Sổ kho đầy đủ (đảo biến động khi từ chối / hủy, nhiều kho) — chỉ phần ở Q1.
- Quét mã vạch thật; tệp xuất thật (CSV tải về).
- Thành phần DS vào `vet45_design_system`, Flutter (Giai đoạn 5).
- Hộp thoại "Bỏ thay đổi?" khi rời 062 còn nháp (đã ghi SCR-062 cho Flutter, chặng 1 góp ý 3).

## 11. Rủi ro

| Rủi ro | Cách xử lý |
|---|---|
| Gom CSS đổi thứ tự hiệu lực → lệch ảnh khó tìm | Gom từng BJ rồi golden ngay; lệch thì so luật trước / sau bằng `usage`; không gom nhiều BJ một lượt |
| Bỏ `!important` làm luật khung Figma thắng lại | Chỉ bỏ khi không còn đối thủ (bước 4 G3-1); golden khớp hoàn toàn là điều kiện qua |
| Hộp thoại một chỗ làm hỏng sheet có hành vi riêng (BJ-08 ô đếm, BJ-15 sheet kỳ có ô nhập) | `onDialogClose` do BJ đăng ký; kiểm bàn phím mọi sheet trước khi xoá bản riêng |
| Sổ sống làm ca golden phụ thuộc thứ tự chạy | Mỗi trang golden là một trang mới; `t7Ledger.reset()` trong mọi `Seed` / `Restore`; ca mở thẳng không đi qua `post` |
| Fixture đổi số lan ra nhiều ca (như BJ-14) | Liệt kê ca theo nhóm, đối chiếu `.txt` chỉ khác số; nếu Home "Tồn thấp" / "Hàng cần xử lý" đổi nghĩa → dừng, hỏi người dùng |
| Critique không đạt 32/40 vì vấn đề cần đổi luồng đã duyệt | Ghi đề xuất, hỏi người dùng; không tự đổi luồng (mục 10) |
| GitNexus chỉ mục cũ cho kết quả sai | `analyze` đầu mỗi gói; nghi kết quả thì đối chiếu `grep`, ghi mục 9 |

## 12. Thứ tự commit

G3-0 (nếu có sửa: `[5.20.2]`) → G3-1 → G3-2 → G3-3 → G3-4 → G3-5 → G3-6 → G3-7 (ghi lại cùng commit G3-7). Mỗi gói review xong mới commit; `detect-changes` trước mỗi commit; không đưa `AGENTS.md` / `CLAUDE.md` (số thống kê của `analyze`) vào commit gói.

## 13. Chữ mới

| Vị trí | Chữ |
|---|---|
| SCR-011 `RECORDED` | "Phiếu nhận {chứng từ}" · "{NCC} · Đã ghi {ngày}" |
| BJ-17 kết quả xác lập | "Mở {nghiệp vụ} {mã}" |
| BJ-03 / 11 / 16 kết quả (vào từ BJ-14) | "Về giá vốn" (chữ đã có ở SCR-077) |
| BJ-11 049 `RECORDED` (thao tác chưa rõ đã được xác lập) | "Đã ghi vào kho" · "Kết quả đã được xác minh; không cần sửa." · badge "Đã ghi" |

## 14. Review

(Phiên review điền sau mỗi gói.)
