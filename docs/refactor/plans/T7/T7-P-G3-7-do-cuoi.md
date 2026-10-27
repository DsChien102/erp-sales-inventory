# T7-P · G3-7 — Đo cuối, sửa cho đạt, ghi lại (đóng T7-P)

> Theme: Theme 7 Inventory · Trạng thái: Plan ✅ (2026-10-26) | Làm ✅ (2026-10-27, v5.26.1 — critique 31/40 hai khung) | Review: để sau (chuyển [PLAN.md](../../PLAN.md) T7-G5)
> Thuộc [plan Giai đoạn 3](T7-P-G3-hoan-thien.md), gói cuối. Plan tổng: [T7-P](T7-P-thiet-ke-lai-luong.md). **Xong gói này là đóng Giai đoạn 3 và đóng T7-P** (chốt của người dùng 2026-10-26).
> Người làm: **Phần 1 — Antigravity** (không có ngữ cảnh trước); **Phần 2 — phiên Claude Code** (người dùng mở sau khi Antigravity báo xong). Plan viết để đọc một mình là làm được; chỗ nào cần quyết định ngoài plan thì **dừng, hỏi người dùng**.
> Ước lượng: Phần 1 ~0,5–1 ngày · Phần 2 ~0,5–1 ngày.

## Phân việc (đọc trước tiên)

| Phần | Ai | Bước | Kết thúc bằng |
|---|---|---|---|
| **1** | **Antigravity** | 0 (đọc, chuẩn bị) → A1…A6 (đo) → **A8** (sửa lỗi audit / bàn phím / ngõ cụt) → **A9** (bàn giao) | Điền mục D, **không commit**, **không đổi phiên bản**, báo người dùng "Phần 1 xong" |
| **2** | Claude Code | A7 (critique — cần skill `/impeccable` chỉ có trong Claude Code, và điểm phải do cùng model chấm để so được với 24 / 29) → B (sửa theo critique) → C (ghi lại, commit) | Commit G3-7, gửi ảnh cho người dùng |

**Antigravity: không làm A7, B, C.** Không chấm critique, không tự cho điểm, không sửa theo heuristic. Gặp các mục đó thì bỏ qua.

---

## 0. Đọc trước (bắt buộc, ~20 phút)

| Tệp | Đọc gì | Vì sao |
|---|---|---|
| `CLAUDE.md` (gốc repo) | Toàn bộ | Quy tắc GitNexus: `impact` trước khi sửa hàm, `detect-changes` trước commit |
| [T7-P-G3-hoan-thien.md](T7-P-G3-hoan-thien.md) | Mục 0.1, 0.4 (Q1–Q5), 1 (quy tắc chung), G3-7, 9 (ghi chú G3-1…G3-6), 13 | Bối cảnh Giai đoạn 3, việc đã làm, chữ mới đã có |
| [T7-P-thiet-ke-lai-luong.md](T7-P-thiet-ke-lai-luong.md) | Mục 1, 2, 3, 5, 11, 13 (cấu trúc bảng), 14 (bảng Giai đoạn 2) | Nơi phải ghi lại ở bước C |
| `.impeccable/critique/2026-10-26T07-12-45Z__me-07-03-design-prototype-html-index-html-050831a4.md` | Toàn bộ | Critique G3-6: **29/40** ở cả hai khung, vấn đề còn lại |
| `.impeccable/critique/2026-10-15T17-12-32Z__me-07-03-design-prototype-html-index-html-050831a4.md` | Bảng heuristic | Bản gốc 24/40, cùng 10 heuristic |
| `specs/themes/theme-07/03.design/prototype/html/CHANGELOG.md` | `[5.24.0]` … `[5.26.0]` | G3-6 đã sửa gì, còn gì "kiểm lại ở G3-7" |
| `specs/themes/theme-07/03.design/prototype/html/README.md` | Phần lệnh golden | Cách chạy công cụ |

Đường dẫn trong plan tính từ `specs/themes/theme-07/03.design/prototype/html/` (gọi tắt **`html/`**) nếu không ghi khác.

### 0.1 Bối cảnh tóm tắt (cho người chưa đọc gì)

- Prototype HTML của Theme 7 (Kho) là nguồn thiết kế cho app Flutter sau này. Có **hai khung**: iPhone (mặc định) và web 1280×800 (`DEVICE=web`). **Cả hai là thiết bị chính**, mọi kiểm phải chạy cả hai.
- Phiên bản hiện tại **v5.26.0** (commit `b202607ae`). G3-0…G3-6 đã làm và commit.
- Công cụ `tools/golden.mjs` mở prototype trong Chrome headless, chụp ảnh + chữ (`.png` + `.txt`) cho mọi ca "màn × trạng thái" (`UIF-xx_SCR-yyy_STATE`) và mọi kịch bản bấm (`SC_*`, mỗi bước một ảnh). Lỗi JS trên trang, bước kiểm tự động sai (tiền thiếu NBSP, sổ kho lệch, đi lạc màn) đều đếm vào **"lỗi JS"**.
- Mốc golden mới nhất: `tools/.golden-g3-6` (iPhone, 2241 ca) và `tools/.golden-g3-6-web` (web, 1350 ca). Dò ngõ cụt: 0 / 498 mỗi khung.
- Mục tiêu còn thiếu của T7-P: **critique ≥ 32/40 ở cả hai khung, 0 P0 / P1** (hiện 29 / 29) và **audit toàn theme 0 lỗi** (chưa chạy toàn theme lần nào; mới chạy theo từng BJ).

### 0.2 Quy tắc không được phá

1. **Chữ của spec giữ nguyên.** Muốn đổi chữ hiển thị → không sửa thẳng, ghi đề xuất vào T7-P mục 13 (cột "Đã duyệt" = `⬜ đề xuất`). Chữ **mới** (chưa có trong spec) được thêm, nhưng phải ghi vào T7-P mục 13.
2. **Không đổi luồng / bố cục đã duyệt** ở brief các BJ. Nếu critique đòi đổi luồng → ghi đề xuất, **dừng, hỏi người dùng**.
3. **Tiền chỉ chủ cửa hàng thấy** (vai nhân viên không có số tiền trong DOM; golden đã tự kiểm).
4. **Golden chụp tuần tự**: xong iPhone rồi mới chạy web; không chạy hai lệnh `capture` / `deadends` cùng lúc (cổng Chrome cố định 9400+).
5. Không chạy reset DB, không push, không đụng Supabase — gói này chỉ sửa prototype và tài liệu.
6. `AGENTS.md` / `CLAUDE.md` bị `gitnexus analyze` đổi số thống kê → **không** đưa vào commit.
7. Các việc đã chuyển sang [PLAN.md](../../PLAN.md) **T7-G5** (gom CSS / `!important`, vùng ảnh BJ-02 / 06 sang `k5Evidence`, lô Amox, giữ hàng Nobivac, fixture BJ-07, review các gói G3) **không làm** ở đây, kể cả khi critique / audit nêu — ghi "chuyển T7-G5".

### 0.3 Chuẩn bị máy

```bash
cd "specs/themes/theme-07/03.design/prototype/html"
python3 -m http.server 8765 --bind 127.0.0.1   # chạy NỀN suốt gói (terminal riêng / tiến trình nền); mọi lệnh golden cần máy chủ này
node --check app/*.js harness/*.js tools/golden.mjs
```

Lưu ý cho tác tử: mỗi lệnh `capture` toàn bộ mất ~1–3 phút (iPhone ~2.240 ca, web ~1.350 ca), chế độ có `AUDIT_JS` lâu hơn — đặt thời gian chờ lệnh ≥ 10 phút, **đợi lệnh trước xong rồi mới chạy lệnh sau** (cổng Chrome cố định). Không cần trình duyệt của IDE cho các lệnh này: `golden.mjs` tự mở Chrome headless.

Ở gốc repo (`/Users/macbook/Documents/Đồ án`): `node .gitnexus/run.cjs analyze` (làm mới chỉ mục; chỉ mục cũ cho kết quả `impact` sai).

Thêm vào `html/tools/.gitignore` (hiện chỉ có `.golden*/`, `.full*/`, `.usage*/`) ba dòng: `.audit*/`, `.keys*/`, `.deadends*/` — để thư mục kết quả của gói không lọt vào commit.

Chrome phải có ở `/Applications/Google Chrome.app` (golden gọi thẳng đường dẫn này).

---

## A. Đo (không sửa gì)

### A1. Mốc nền

```bash
node tools/golden.mjs capture tools/.golden-g3-7-base
DEVICE=web node tools/golden.mjs capture tools/.golden-g3-7-web-base
node tools/golden.mjs compare tools/.golden-g3-6 tools/.golden-g3-7-base
node tools/golden.mjs compare tools/.golden-g3-6-web tools/.golden-g3-7-web-base
```

Đạt: hai lệnh `capture` in `lỗi JS: 0`; hai lệnh `compare` in "Khớp hoàn toàn". Không khớp → HEAD đã đổi sau G3-6: đọc `.txt` của ca khác, ghi mục D, rồi dùng `-base` mới làm mốc.

### A2. Công cụ audit — đưa vào repo

Các BJ trước dùng một biểu thức kiểm dọc nằm ở thư mục tạm, chưa có trong repo. Tạo **`html/tools/audit.js`** với nội dung ở **Phụ lục 1** (chép nguyên). Biểu thức chạy sau mỗi ca qua biến `AUDIT_JS`, ghi `_audit.json` trong thư mục chụp. Nó kiểm:

- tương phản chữ ≥ 4,5:1 (chữ lớn ≥ 24px hoặc ≥ 18,66px đậm: ≥ 3:1);
- vùng chạm: iPhone ≥ 44 × 44, web ≥ 40 × 40 (nút, liên kết, ô nhập, ô tick, radio);
- nút / ô nhập không có tên (`aria-label`, chữ, `value`, hoặc `<label>`);
- tràn ngang khỏi khung app (trừ bảng cuộn ngang, sheet, toast, dải chip cuộn);
- `noname` / `rowRole` của `tr[tabindex]` (sau G3-2 không còn, nếu xuất hiện là lỗi hồi quy).

Thêm một dòng vào `html/README.md` ngay dưới dòng `AUDIT_JS=…` hiện có: `AUDIT_JS=tools/audit.js node tools/golden.mjs capture tools/.audit-now   # audit toàn theme (tools/audit.js)`.

### A3. Audit toàn theme (hai khung)

```bash
AUDIT_JS=tools/audit.js node tools/golden.mjs capture tools/.audit-g3-7
AUDIT_JS=tools/audit.js DEVICE=web node tools/golden.mjs capture tools/.audit-g3-7-web
```

Gom kết quả: viết một đoạn `node -e` (hoặc tệp nhỏ trong thư mục tạm của phiên, **không** đưa vào repo) đọc `_audit.json`, gom theo **(loại lỗi, phần tử, chữ)** — cùng một phần tử lặp ở nhiều ca chỉ là **một** lỗi — và in: số lỗi duy nhất mỗi loại, ví dụ 3 ca mỗi lỗi.

Lưu ý khi đọc kết quả:

- Phạm vi là **màn app** `#app-screen`; vỏ harness (thanh công cụ, inspector) không tính.
- Ca `SC_*` có sheet đang mở → các ca đó chính là "mọi sheet" (G3-plan G3-7 bước 2).
- Thanh trạng thái iPhone (giờ, pin) không phải nội dung app: nếu bị báo, loại ra và ghi lý do.
- Mỗi lỗi còn lại phải được: **sửa** (bước B), hoặc **ghi lý do không phải lỗi** (mục D, kèm ca và số đo).

### A4. Bàn phím (web)

`audit.js` không kiểm được bàn phím. Kiểm riêng bằng **Phụ lục 2** (`tools/keys.js`, chỉ dùng trong gói, có thể để lại trong repo):

```bash
AUDIT_JS=tools/keys.js DEVICE=web node tools/golden.mjs capture tools/.keys-g3-7-web UIF-
```

Biểu thức chạy trên mọi ca mở thẳng có `[role="dialog"]`: đặt focus vào phần tử cuối → gửi Tab → focus phải về phần tử đầu; gửi Shift+Tab ở phần tử đầu → về phần tử cuối; gửi Esc → hộp thoại phải đóng (hoặc ca đó không có hàm đóng: ghi). Kết quả ở `_audit.json`, trường `keys`.

**Trả focus về nút đã mở** không kiểm được trên ca mở thẳng (không có nút đã mở). Kiểm tay bằng trình duyệt ở 5 sheet: BJ-01 sheet lô (từ 001 web, bấm một dòng → mở 003 → sheet), BJ-08 sheet nộp, BJ-11 sheet từ chối, BJ-15 sheet kỳ, BJ-17 sheet xác nhận. Mở bằng bàn phím (Tab + Enter), Esc đóng, focus phải về đúng nút đã mở. Ghi kết quả mục D. Không có trình duyệt điều khiển được → ghi "chưa kiểm tay" ở mục D và báo người dùng ở bước C6.

### A5. Audit dọc `SC_demo` và `SC_home_all`

Đã nằm trong A3 (mọi bước của mọi kịch bản đều được kiểm). Đọc riêng hai nhóm này trong `_audit.json` và kiểm thêm bằng mắt từng ảnh của hai kịch bản ở cả hai khung (`tools/.audit-g3-7/SC_demo*.png`, `SC_home_all*.png`, và bản `-web`):

- nút quay lại về đúng màn trước (so ảnh bước sau `back`);
- toast không che nút chân;
- số tồn giống nhau giữa các BJ cùng thời điểm (bước `9-check-ledger` của `SC_demo` đã tự kiểm; nếu "lỗi JS" = 0 là đạt).

### A6. Dò ngõ cụt

```bash
node tools/golden.mjs deadends tools/.deadends-g3-7
DEVICE=web node tools/golden.mjs deadends tools/.deadends-g3-7-web
```

Đạt: `0 ngõ cụt, lỗi JS: 0` ở cả hai.

### A7. Critique lần 1 (Q5 của plan G3) — **Phần 2, Claude Code** (Antigravity bỏ qua, sang A8)

Chạy skill **`/impeccable critique`** (qua công cụ Skill, tên `impeccable:impeccable`, đối số `critique specs/themes/theme-07/03.design/prototype/html/index.html`). Theo đúng cách của G3-6 để điểm so được:

- **Một ngữ cảnh**, không dùng sub-agent. Phần A (đánh giá thiết kế): xem ảnh golden đã chụp ở A1 thay vì mở trình duyệt. Phần B: `impeccable detect` sau phần A.
- **Bộ ảnh cố định** (ghi danh sách vào mục D để lần sau dùng lại), mỗi ảnh lấy cả bản iPhone (`tools/.golden-g3-7-fix/…png`) và web (`tools/.golden-g3-7-web-fix/…@web.png` — tên ca web có hậu tố `@web`; dùng `ls` để lấy đúng tên):
  1. `HUB_home`
  2. BJ-01: `UIF-01_SCR-001_READY`, `UIF-01_SCR-003_READY`
  3. BJ-02: ảnh màn duyệt (SCR-011) và màn kết quả (SCR-012) trong `SC_journey_2`; phiếu đã ghi: ảnh cuối của kịch bản `SC_g3_receipt_recorded_*` (trạng thái `RECORDED` không phải ca mở thẳng, chỉ có trong kịch bản)
  4. BJ-03: `UIF-03_SCR-015_READY`
  5. BJ-05: `UIF-05_SCR-026_READY`
  6. BJ-08: `UIF-08_SCR-044_BLIND_COUNT`, `UIF-08_SCR-046_READY`
  7. BJ-11: `UIF-11_SCR-048_READY`
  8. BJ-14: `UIF-14_SCR-074_READY_FOR_REVIEW`
  9. BJ-15: `UIF-15_SCR-056_READY`
  10. BJ-17: `UIF-17_SCR-083_COMPLETED`
  11. Một K3 (`*_UNKNOWN`) và một K4 ở chế độ Toàn Theme 7 iPhone (ảnh trong `SC_home_all` hoặc `SC_journey_*` có thanh 5 tab)
  12. CAP-01: `CAP-01_SCR-062_READY`
  13. Ảnh bước cuối của `SC_demo` (thẻ kho)

  Tên trạng thái nào không có → chọn trạng thái mặc định gần nhất của màn đó và ghi tên thật vào mục D.
- Chấm **riêng hai khung**, 10 heuristic giống bản 2026-10-15 / 2026-10-26. **Điểm Giai đoạn 3 = điểm thấp hơn** của hai khung.
- Lưu `.impeccable/critique/<timestamp>__me-07-03-design-prototype-html-index-html-050831a4.md`, cùng khuôn với bản 2026-10-26 (front-matter `total_score`, `p0_count`, `p1_count`; bảng iPhone | Web).
- Kiểm lại riêng bốn mục G3-6 ghi "kiểm lại ở G3-7": 037 tiêu đề "Việc tiếp theo" khi chỉ có ghi chú / badge lặp chữ; 041 `REJECTED` thiếu "Lô" / "Số lượng"; 044 dòng đã đếm vẫn nằm dưới chip "Chưa đếm"; 008 web thứ tự Tab ngược thứ tự nhìn. Mỗi mục: còn / hết, ghi mục D.

**Đạt** khi: cả hai khung ≥ 32/40 **và** 0 P0 / P1 **và** A3 + A4 + A6 0 lỗi (hoặc mỗi lỗi có lý do ghi ở D). Đạt → bỏ qua B, sang C.

Phần 2 bắt đầu bằng: đọc mục D (Antigravity đã điền), `git diff` + `git status` để xem Phần 1 đã sửa gì, chạy lại `node --check` và một lần golden hai khung so với `-fix` của A8 (phải khớp). Ảnh cho critique lấy từ mốc **sau A8** (`tools/.golden-g3-7-fix` / `tools/.golden-g3-7-web-fix`), không phải `-base`.

### A8. Sửa lỗi audit, bàn phím, ngõ cụt — **Phần 1, Antigravity**

Chỉ sửa lỗi **đo được** ở A3 / A4 / A6 (tương phản, vùng chạm, thiếu tên, tràn ngang, Tab / Esc, ngõ cụt). Không sửa gì khác.

1. Với mỗi lỗi đã gom nhóm ở A3 / A4 / A6: tìm phần tử trong mã (`grep` lớp CSS / thuộc tính trong `app/*.js`, `styles/*.css`), xác định **tệp sở hữu** (BJ nào dựng phần tử đó).
2. **Trước khi sửa một hàm JS dùng chung** (`k*` trong `app/shared-patterns.js`, `ds24*`, hàm trong `app/core.js` / `app/hub.js`): ở gốc repo chạy `node .gitnexus/run.cjs impact <tên hàm> --direction upstream --repo erp-sales-inventory`; ghi mức rủi ro vào D. HIGH / CRITICAL → **dừng, hỏi người dùng** trước khi sửa. Sửa CSS không cần `impact`.
3. Cách sửa cho phép:
   - Tương phản: đổi sang token màu đã có trong `styles/tokens.css` (vd. biến `--…-text` đậm hơn), **không** đặt mã màu mới rời rạc.
   - Vùng chạm: tăng `min-height` / `min-width` hoặc mở rộng vùng bằng `::after` (cách đã dùng cho chip và nút đóng toast) — không đổi cỡ chữ / bố cục.
   - Thiếu tên: thêm `aria-label` bằng chữ đang hiện trên màn hoặc chữ của spec; không bịa chữ hiển thị mới.
   - Tràn ngang: `min-width: 0` / `overflow-wrap` / `white-space` — không ẩn nội dung.
   - Esc không đóng: đăng ký `onDialogClose["UIF-NN"] = () => { …đóng sheet…; render(); return true; }` trong `app/bjNN.js` theo mẫu các BJ khác (`grep -n 'onDialogClose\[' app/*.js`).
   - Ngõ cụt: thêm lối ra theo mẫu `UIF-10 SCR-041` (G3-5, CHANGELOG `[5.25.0]`) — nút về danh sách của BJ, chữ có sẵn trong BJ.
4. **Không** thêm `!important`, **không** tạo tệp CSS / JS mới (trừ `tools/audit.js`, `tools/keys.js`), **không** đổi chữ hiển thị đã có.
5. Lỗi nào phải đổi bố cục / luồng / chữ mới sửa được → không sửa; ghi D với nhãn **"cần Phần 2"** kèm ca và đề xuất.
6. Sau khi sửa xong:

```bash
node --check app/*.js harness/*.js tools/golden.mjs
node tools/golden.mjs capture tools/.golden-g3-7-fix
DEVICE=web node tools/golden.mjs capture tools/.golden-g3-7-web-fix
node tools/golden.mjs compare tools/.golden-g3-7-base tools/.golden-g3-7-fix
DEVICE=web node tools/golden.mjs compare tools/.golden-g3-7-web-base tools/.golden-g3-7-web-fix
```

   - `lỗi JS: 0` cả hai khung.
   - Ca khác: mỗi ca phải thuộc một sửa đã ghi ở D. Ca khác ngoài dự kiến → mở `.txt` hai bên so (`diff`); khác không chủ đích → sửa lại. Chữ (`.txt`) **không được** khác, trừ khi sửa là thêm lối ra ngõ cụt.
   - Chạy lại A3, A4, A6 vào thư mục mới (`tools/.audit-g3-7-fix`, `-fix-web`, `.keys-g3-7-fix-web`, `.deadends-g3-7-fix`, `-fix-web`): số lỗi phải giảm đúng bằng số đã sửa.

### A9. Bàn giao — **Phần 1, Antigravity**

1. Điền **mục D** đủ các dòng của khuôn ở mục D (số đo trước / sau, lỗi đã sửa, lỗi để lại kèm lý do, mục "cần Phần 2", kết quả `impact`).
2. **Không** commit, **không** đổi phiên bản (`manifest.json` / badge / CHANGELOG là việc Phần 2), **không** sửa T7-P / plan G3 / tài liệu `03.design`.
3. Để nguyên các thư mục `tools/.golden-g3-7-*`, `.audit-*`, `.keys-*`, `.deadends-*` (Phần 2 dùng lại).
4. Báo người dùng một đoạn ngắn: "Phần 1 xong" + số lỗi audit trước / sau mỗi khung + số mục "cần Phần 2".

---

## B. Sửa theo critique — **Phần 2, Claude Code** (chỉ khi A7 chưa đạt; tối đa hai vòng)

### B1. Thứ tự sửa

1. Mục "cần Phần 2" Antigravity để lại ở D (lỗi audit cần đổi bố cục / chữ).
2. P0 / P1 của critique mới.
3. Heuristic đang thấp nhất mỗi khung, theo bảng ứng viên B2.
4. Bốn mục "kiểm lại" ở A7 nếu còn.

### B2. Ứng viên cho heuristic thấp (từ critique 2026-10-26)

Critique G3-6: iPhone thấp nhất ở **H7 Linh hoạt (2)**, web ở **H8 Tối giản (2)**; các heuristic còn lại 3. Muốn ≥ 32 thì mỗi khung cần +3 so với 29. Ứng viên, đã chia theo được làm ngay hay phải hỏi:

| # | Heuristic | Ứng viên | Làm ngay? |
|---|---|---|---|
| U1 | H1 / H6 (demo tin được) | Home Kho "Chờ duyệt": `pendingSummary` (`app/hub.js`) còn gồm ba phiếu mẫu cố định → đọc từ trạng thái các BJ như "Cần chú ý" đã làm, để duyệt xong thì số giảm. Không đổi chữ, không đổi bố cục | **Có** |
| U2 | H8 web | Bảng web còn thưa: rà các bảng K7 ở web (BJ-03 015, BJ-08 044, BJ-11 048, BJ-14 074, BJ-15 056) — cột số sát nội dung, không lặp thông tin ngay cạnh cột (vd. BJ-03 "Lô DH2507 · 121 hộp" cạnh cột "121 hộp"), độ rộng tối đa như BJ-08 (820px) khi bảng ít cột | **Có** (chỉ CSS / bỏ dòng phụ lặp) |
| U3 | H4 / H8 | Hàng nhãn — giá trị lệch, chữ 9–10px còn lại sau G3-6 (G3-6 đo lúc chạy: không còn chữ < 11px ngoài thanh trạng thái — nếu critique mới vẫn nêu, đo lại bằng `getComputedStyle` trên ca cụ thể) | **Có** |
| U4 | H7 iPhone | Thao tác hàng loạt trên iPhone (vd. chọn nhiều dòng cùng đổi tình trạng, "Lấy đủ tất cả") | **Không — đổi luồng.** Ghi đề xuất mục 13, hỏi người dùng |
| U5 | H1 / "đỉnh" demo | K4 kết quả nhận hàng / kiểm kê thêm một dòng "Tồn kho đã đổi: {sản phẩm} {trước} → {sau}" **(mới)** | **Không — thêm phần tử vào khuôn K4 đã duyệt.** Hỏi người dùng |
| U6 | H2 | Chữ chuyên môn "Đếm mù", "Căn cứ", mã `REC-UNKNOWN-0x` hiện ở danh sách | Chữ spec → **chỉ ghi đề xuất mục 13**, không sửa. Riêng mã nội bộ hiện ở danh sách: nếu không phải chữ spec thì được ẩn / thay bằng tên thao tác |
| U7 | H10 | Trợ giúp tìm kiếm được | **Không** — ngoài phạm vi prototype; ghi "chuyển T7-G5" |

Nếu U1–U3 + U6 làm xong mà vẫn < 32 → **dừng, báo người dùng** với: điểm từng heuristic hai khung, ứng viên U4 / U5 (kèm ước lượng), và câu hỏi có làm không. Không tự làm U4 / U5.

### B3. Cách sửa mỗi mục

- **GitNexus trước khi sửa** mỗi hàm dùng chung (`k7Table`, `k4Result`, `k2…`, `k3Unknown`, hàm trong `hub.js`…): `node .gitnexus/run.cjs impact <hàm> --direction upstream --repo erp-sales-inventory` (chạy từ gốc repo). HIGH / CRITICAL → báo người dùng trước khi sửa (đã biết: `k3Unknown` HIGH, 17 người gọi; nếu chỉ đổi CSS thì vẫn báo nhưng không cần dừng).
- Sửa thẳng vào tệp sở hữu (`app/bjNN.js`, `app/hub.js`, `app/shared-*.js`, `styles/screens.css` / `components.css`). **Không** tạo tệp CSS / JS vá mới.
- Thêm `!important` mới là **không được** (đang chuyển T7-G5 để bỏ).
- Mỗi sửa: chạy lại golden hai khung (`tools/.golden-g3-7-b` / `tools/.golden-g3-7-web-b` — không ghi đè mốc `-fix` của Phần 1), `compare` với `-fix`; ca khác phải nằm trong nhóm của sửa đó — đọc `.txt` ca ngoài nhóm, khác không chủ đích thì sửa.
- Sau cả vòng: chạy lại A3, A4, A6, A7 (critique lần 2 lưu tệp mới). Vòng 2 chưa đạt → dừng, báo người dùng.

---

## C. Ghi lại và commit — **Phần 2, Claude Code**

### C1. Mốc cuối

```bash
node tools/golden.mjs capture tools/.golden-g3
DEVICE=web node tools/golden.mjs capture tools/.golden-g3-web
```

`lỗi JS: 0` cả hai. Nếu B không sửa gì: `compare` với `tools/.golden-g3-7-fix` / `-web-fix` (mốc sau Phần 1) phải khớp hoàn toàn (trừ đổi badge phiên bản).

### C2. Phiên bản

- Có sửa giao diện ở B → **5.26.1**; chỉ ghi lại → vẫn **5.26.1** (đổi badge).
- Sửa ở: `manifest.json` (`version`), `harness/workbench.js` (`version: "5.26.1"`, gần dòng 458), badge `index.html` (dòng 28): `v5.26.1 · Giai đoạn 3 ✅ · G3-7 đo cuối`.
- `CHANGELOG.md` đầu tệp: `## [5.26.1] — Giai đoạn 3 · G3-7 đo cuối, hết Giai đoạn 3` — gồm: điểm critique hai khung (trước / sau), số lỗi audit trước / sau, dò ngõ cụt, kết quả bàn phím, các sửa (nếu có), mốc `tools/.golden-g3` / `-web`, dòng "Chuyển T7-G5:" liệt kê việc không làm.
- `python3 tools/sync-registry.py`.

### C3. Plan Giai đoạn 3 ([T7-P-G3-hoan-thien.md](T7-P-G3-hoan-thien.md))

- Dòng trạng thái (dòng 3): `Làm ✅ (2026-MM-DD, v5.26.1)`; Review: `chuyển T7-G5`.
- Bảng 0.3: thêm cột / ghi ✅ cho G3-1…G3-7 (G3-1, G3-2, G3-4 "✅ một phần — phần còn lại chuyển T7-G5").
- Mục 9: thêm `### G3-7 (5.26.1, ngày)` — chép tóm tắt mục D của plan này (điểm, audit, sửa, lý do lỗi không sửa) và liên kết tới plan này.
- Mục 13: thêm chữ mới của G3-5 chưa có trong bảng: BJ-01 sheet nguồn "Mở phiếu nhận {mã}"; BJ-10 041 `EXPIRED` "Đề nghị tiêu hủy đã hết hiệu lực" · "Không có tác động tồn kho. Tạo đề nghị mới nếu vẫn cần tiêu hủy."; và chữ mới của B (nếu có).

### C4. Plan tổng ([T7-P-thiet-ke-lai-luong.md](T7-P-thiet-ke-lai-luong.md))

1. **Dòng trạng thái (dòng 3):** đổi `**Giai đoạn 3 🔄** — [plan](T7-P-G3-hoan-thien.md) (G3-0…G3-6 xong, `v5.26.0`; G3-7 ⬜)` → `**Giai đoạn 3 ✅** (ngày, v5.26.1 — [plan](T7-P-G3-hoan-thien.md), [G3-7](T7-P-G3-7-do-cuoi.md)) · **T7-P đóng** — tiếp: PLAN.md T7-G4 (chốt đặc tả), T7-G5 (Flutter)`.
2. **Mục 1:** thêm cột "Kết quả (Giai đoạn 3)" vào bảng: #1 ✅ (brief 17 BJ + CAP-01 đã duyệt — mục 14); #2 "✅ JS; CSS còn `!important` 55 luật, chưa gom theo BJ — chuyển T7-G5"; #3 điểm mới + audit (✅ hoặc ghi thiếu); #4 ✅ dò ngõ cụt 0 / 498 mỗi khung; #5 kiểm bằng `grep -rln "^### v[0-9]" specs/themes/theme-07/03.design/screens specs/themes/theme-07/03.design/flows` = rỗng → ✅, còn tệp → ghi số tệp + "T7-G4"; #6 ✅ `SC_demo` 0 lỗi, sổ kho sống.
3. **Mục 3:** đổi tiêu đề thành `## 3. Hiện trạng (2026-10-16; cập nhật cuối Giai đoạn 3)`, thêm dòng cuối bảng: `| Cuối Giai đoạn 3 (v5.26.1) | Critique iPhone {a}/40, web {b}/40 (tệp …); audit toàn theme {n} lỗi; golden 2241 / 1350 ca (số thật lúc chụp); dò ngõ cụt 0 |`.
4. **Mục 11:** dòng "3. Hoàn thiện": thêm `✅ ngày (v5.26.1)` vào cột "Việc".
5. **Mục 13:** dòng `13 / 03 / mọi K4` (đang `⬜ đề xuất`): cột "Đã duyệt" → `✅ 2026-10-26 (v5.25.0, G3-5 Q3: K4 iPhone Toàn Theme 7 có thanh 5 tab; bẫy focus chung ở core.js từ G3-2)`. Thêm bốn dòng chữ mới từ mục 13 của plan G3 (SCR-011 `RECORDED`; BJ-17 "Mở {nghiệp vụ} {mã}"; BJ-03 / 11 / 16 "Về giá vốn"; BJ-11 049 `RECORDED`) + hai dòng G3-5 ở C3, cột "Đã duyệt" = `✅ 2026-10-26 (plan G3 ✅ duyệt, v5.2x.0)`. Đề xuất mới của B (U4 / U5 / U6) ghi `⬜ đề xuất`.
6. **Mục 14:** thêm sau bảng Giai đoạn 2 một mục `### Giai đoạn 3 — hoàn thiện` với bảng: `Gói | Làm | Phiên bản | Ghi chú`: G3-0 ✅ (review bù BJ-13 đạt), G3-1 ✅ một phần (CSS gom → T7-G5), G3-2 ✅ một phần (vùng ảnh → T7-G5), G3-3 ✅, G3-4 ✅ một phần (Amox / Nobivac / BJ-07 → T7-G5), G3-5 ✅, G3-6 ✅ (29/40), G3-7 ✅ (điểm mới). Cột review: "chuyển T7-G5". **Không** sửa các ô "chưa review" của bảng Giai đoạn 2 (review để sau).

### C5. Tài liệu thiết kế (`specs/themes/theme-07/03.design/`)

Sửa thẳng nội dung chính theo khuôn `screens/_TEMPLATE.md` (mục 2 Lối vào / ra, 4 Trạng thái, 5 Hành động, 8 Chữ trên màn); **giữ** `IN_REVIEW`; **không** thêm đoạn `### vX.Y`.

| Tệp | Sửa | Nguồn hành vi (đọc mã để ghi đúng) |
|---|---|---|
| `screens/SCR-011.md` | Thêm trạng thái `RECORDED` (chỉ đọc): tiêu đề "Phiếu nhận {mã}", phụ "{NCC} · Đã ghi {ngày}", bảng "Theo chứng từ · Thực nhận · Chênh lệch · Tình trạng", không chân duyệt; lối vào từ SCR-056 "Mở phiếu gốc" và sheet nguồn SCR-003 "Mở phiếu nhận {mã}"; quay lại về nơi đã mở | `app/bj02.js`: `bj02OpenRecorded`, `render011Recorded` |
| `screens/SCR-056.md` | Dòng 27 + mục 3 / 4: "Mở phiếu gốc" có cho dòng Nhận hàng của BJ-02 (bỏ câu "nhận hàng BJ-02 chưa có màn xem chứng từ đã nhận"); "Trước / Sau" và cột "Tồn" luôn theo thứ tự ghi nhận, kể cả khi đọc theo ngày nghiệp vụ; dòng lệch ngày có phụ "Ghi nhận {dd/mm}" | `app/bj15.js`: `bj15SourceOf`, `bj15Balances` |
| `screens/SCR-003.md` | Sheet "Nguồn và thời điểm cập nhật": đọc biến động gần nhất từ sổ kho; "Mở phiếu nhận {mã}" khi biến động gần nhất là nhận hàng | `app/bj01.js` (tìm "Nguồn và thời điểm") |
| `screens/SCR-083.md` | Kết quả xác lập: bước tiếp "Mở {nghiệp vụ} {mã}" về màn của thao tác nguồn; kết quả được báo về BJ nguồn (`RECORDED` / `NOT_RECORDED`) | `app/bj17.js`, `onUnknownResolved` ở `app/core.js` |
| `screens/SCR-049.md` | Trạng thái `RECORDED`: "Đã ghi vào kho" · "Kết quả đã được xác minh; không cần sửa." · badge "Đã ghi" | `app/bj11.js` |
| `screens/SCR-041.md` | `PENDING_APPROVAL` (dùng K2), `EXPIRED` ("Đề nghị tiêu hủy đã hết hiệu lực" · "Không có tác động tồn kho. Tạo đề nghị mới nếu vẫn cần tiêu hủy."), lối ra "Về hàng cần xử lý" | `app/bj10.js` |
| Màn kết quả của BJ-03 / BJ-11 / BJ-16 có "Về giá vốn" | Lối ra "Về giá vốn" khi vào từ việc chặn của SCR-074 | `grep -n "bj14ReturnAction" app/*.js` → hàm dựng màn kết quả nào gọi → Screen Contract của màn đó |
| `patterns/PAT-NAV.md` | K4 (màn kết quả) ở chế độ Toàn Theme 7 trên iPhone hiện thanh 5 tab của app; chế độ BJ và web giữ như cũ | `app/hub.js` `afterFlowRender` |
| `screens/INDEX.md` | Ghi SCR-011 có thêm trạng thái `RECORDED` (cột ghi chú) | — |

Rồi `python3 tools/sync-registry.py` (từ `html/`) và kiểm `git diff` của registry chỉ đổi đúng các màn trên.

### C6. Gửi người dùng

Ảnh (đường dẫn đầy đủ trong `tools/.golden-g3` / `-web`): `HUB_home` hai khung; một K4 iPhone có thanh 5 tab; ảnh SCR-011 `RECORDED` web (ảnh cuối `SC_g3_receipt_recorded_*@web`); bước cuối `SC_demo` hai khung. Kèm bảng điểm critique: gốc 24 → G3-6 29 → G3-7 (iPhone / web), số lỗi audit, và danh sách "chuyển T7-G5" + đề xuất đang chờ duyệt (U4 / U5 nếu có).

### C7. Commit

1. `node .gitnexus/run.cjs analyze` rồi `node .gitnexus/run.cjs detect-changes --scope all --repo erp-sales-inventory` (gốc repo). Chỉ được chạm các symbol của sửa ở B; ngoài ra → kiểm lại.
2. `git status`: **bỏ** `AGENTS.md`, `CLAUDE.md` khỏi commit. Thư mục `tools/.golden-*`, `.audit-*`, `.keys-*`, `.deadends-*` phải bị `tools/.gitignore` loại (bước 0.3) — kiểm lại không bị thêm. Được commit: `tools/audit.js`, `tools/keys.js`, `tools/.gitignore`, `README.md`.
3. Một commit (đang ở nhánh `refactor/simple-arch`, không tạo nhánh, không push):

```
refactor(prototype): T7-P G3-7 — đo cuối, audit toàn theme, hết Giai đoạn 3 (v5.26.1)
```

Thân commit: điểm critique hai khung, audit, các sửa, "Chuyển T7-G5: …". Kết thúc bằng dòng `Co-Authored-By` theo quy ước của phiên.

---

## D. Ghi chú khi làm

### Phần 1 (Antigravity điền)

- **A1 mốc nền:**
  - iPhone: 2241 ca trong 67.1s, lỗi JS: 0. `compare` với `.golden-g3-6`: Khớp hoàn toàn (2241 ca).
  - Web: 1350 ca trong 42.6s, lỗi JS: 0. `compare` với `.golden-g3-6-web`: Khớp hoàn toàn (1350 ca).
- **A3 audit (trước sửa):**
  - Bảng số lỗi duy nhất (occurrences):
    | Loại | iPhone (duy nhất / lần) | Web (duy nhất / lần) |
    |---|---|---|
    | `contrast` | 10 lỗi duy nhất (40 lần) | 7 lỗi duy nhất (25 lần) |
    | `target` | 11 lỗi duy nhất (288 lần) | 65 lỗi duy nhất (813 lần) |
    | `overflow` | 0 | 0 |
    | `noname` | 0 | 0 |
    | `rowRole` | 0 | 0 |
  - Danh sách lỗi trước sửa:
    - `contrast`:
      - `4.44 p "Hệ thống đang xử lý. Bạn không cần thực "` (UIF-02_SCR-012_PROCESSING_document, UIF-02_SCR-012_PROCESSING_quick, SC_demo_33_3-4-approve...).
      - Tỷ lệ 3.85 trên các nút bị vô hiệu hóa (`disabled` / `.is-disabled`): `button.button--secondary "Chụp ảnh"` (LOCKED), `button.button--primary "Xong"` (VALIDATION_ERROR), `button.button--secondary "Vẫn 10 chai / 4 lọ / 1 chai"` (PRICE_BASIS_REQUIRED), `button.button--primary "Đúng hàng"` (wrong-lot), `button.button--primary "Gửi chênh lệch"` (mismatch), `button.button--danger "Hủy phiên" / "Hủy yêu cầu"`, `button.button--secondary "Huỷ thay đổi"` (CAP-01).
    - `target`:
      - iPhone: `button.button.button--tertiary 43×44 "Xóa lô"` (SC_bj02_lot_3_add-lot, SC_bj02_lot_4_lot-code, SC_bj02_lot_5_show-mfg); `button.ds24-chip` cao 34px (có `::after`); `button.toast-close` 20×20 (có `::after`).
      - Web: `button.ds-segment` cao 38px ở BJ-03, BJ-05, BJ-07, BJ-10, CAP-01; `button.k7-check` 24×44 (bị `min-width: 0` của `data-mobile-product` đè); `button.cap-link-button` (76×18 "Sửa ngưỡng", 95×18 "Dùng mặc định"); `button.k7-row-open` (77×20, 183×20, 122×36...); `button.k7-row-link` (64×24 "Cách tính", 94×24 "Xem chứng từ"...); `button.ds24-chip` cao 34px (có `::after`); `button.toast-close` 20×20 (có `::after`).
- **A4 bàn phím:**
  - Hộp thoại kiểm qua golden: 1 ca mở thẳng có `[role="dialog"]` (`UIF-03_SCR-015_VALIDATION_ERROR@web`, 9 phần tử): `tabWrap: true`, `shiftTabWrap: true`, `escCloses: true`.
  - Kiểm tra trả focus ở 5 sheet (kiểm tự động bằng headless Chrome CDP):
    1. BJ-01 sheet lô: mở từ SCR-001 (chọn sản phẩm -> SCR-003 panel -> bấm dòng lô `tr[data-bj01-lot] .k7-row-open`): Tab+Enter mở sheet, Esc đóng sheet, focus trả về đúng `.k7-row-open` của dòng lô -> **Đạt**.
    2. BJ-08 sheet nộp: mở từ SCR-044 (`COUNTED` -> bấm `[data-bj08-action="submit-first"]`): mở sheet, Esc đóng sheet, focus trả về nút `[data-bj08-action="submit-first"]` -> **Đạt**.
    3. BJ-11 sheet từ chối: mở từ SCR-051 vai chủ cửa hàng (`[data-bj11-action="reject-open"]`): mở sheet, Esc đóng sheet, focus trả về nút `[data-bj11-action="reject-open"]` -> **Đạt**.
    4. BJ-15 sheet kỳ: mở từ SCR-055 (`[data-bj15-action="period-open"]`): mở sheet, Esc đóng sheet, focus trả về nút `[data-bj15-action="period-open"]` -> **Đạt**.
    5. BJ-17 sheet xác nhận: mở từ SCR-079 (`[data-bj17-action="confirm-done"]`): mở sheet, Esc đóng sheet, focus trả về nút `[data-bj17-action="confirm-done"]` -> **Đạt**.
- **A5:** `SC_demo` / `SC_home_all`: quay lại đúng màn trước, toast không che nút chân, sổ kho sống (`9-check-ledger` của `SC_demo` tự kiểm, lỗi JS: 0) -> **Đạt**.
- **A6 ngõ cụt:** 498 ca mỗi khung, **0 ngõ cụt, lỗi JS: 0** cả hai khung iPhone và Web.
- **A8 đã sửa:**
  - 1. Contrast `.loading-state p`: `styles/components.css:1007` đổi màu từ `var(--vet45-v2-text-muted)` sang `var(--vet45-v2-text-secondary)` (tương phản tăng từ 4.44 lên >7:1). Ca golden khác: 9 ca màn SCR-012 (UIF-02_SCR-012_PROCESSING_*, SC_bj02_*, SC_demo_33_3-4-approve, SC_journey_2_16_approve).
  - 2. Target `body[data-active-uif="UIF-02"] .lot-delete-action-inline`: `styles/components.css:1724` thêm `min-width: 44px;` (tăng từ 43px lên 44px đạt chuẩn iPhone). Ca golden khác: 0 ca khác ngoài dự kiến (không đổi chữ, không lệch layout).
  - 3. Target `.device-preview.is-web .ds-segment`: `styles/components.css:2714` đổi `min-height: 38px;` thành `min-height: 40px;` (đạt chuẩn web ≥ 40px cho segmented controls). Ca golden khác: 87 ca web (CAP-01, BJ-03, BJ-05, BJ-07, BJ-10 có chứa ds-segment; toàn bộ khớp chữ .txt).
  - 4. Target `.k7-check` web: `styles/components.css:2873` thêm `.k7-table td.k7-col-check .k7-check { min-width: 44px; }` ngăn `[data-mobile-product] .body-stack * { min-width: 0; }` bóp chiều rộng checkbox trên bảng web.
  - Kết quả `impact`: Toàn bộ 4 sửa đều nằm trong tệp CSS (`styles/components.css`), không sửa hàm JS dùng chung nào nên không cần chạy `impact` (theo quy tắc mục A8.2: "Sửa CSS không cần impact"). Môi trường sandbox IDE không hỗ trợ phần mở rộng FTS của DuckDB trong GitNexus analyze (stale ở commit 534156b).
- **A8 sau sửa:**
  - Bảng audit sau sửa:
    | Loại | iPhone (sau sửa) | Web (sau sửa) |
    |---|---|---|
    | `contrast` | 9 lỗi duy nhất (31 lần) | 6 lỗi duy nhất (18 lần) |
    | `target` | 10 lỗi duy nhất (284 lần) | 42 lỗi duy nhất (615 lần) |
    | `overflow` | 0 | 0 |
    | `noname` | 0 | 0 |
    | `rowRole` | 0 | 0 |
  - Lỗi JS: **0** cả hai khung (`.golden-g3-7-fix` 2241 ca: 0 lỗi; `.golden-g3-7-web-fix` 1350 ca: 0 lỗi; `.audit-g3-7-fix` 2241 ca: 0 lỗi; `.audit-g3-7-fix-web` 1350 ca: 0 lỗi).
  - Bàn phím: 1 dialog UIF-03 tabWrap/shiftTabWrap/escCloses đều true; 5/5 sheet kiểm tra focus return đạt.
  - Dò ngõ cụt: 498 ca mỗi khung, **0 ngõ cụt, lỗi JS: 0**.
- **Để lại, không phải lỗi:**
  - `contrast` tỷ lệ 3.85 trên 9 nút iPhone / 6 nút Web: Đều là các nút ở trạng thái vô hiệu hóa (`:disabled` / `aria-disabled="true"` / `.is-disabled`). Theo WCAG 2.1 SC 1.4.3 (Contrast Minimum), các thành phần điều khiển không kích hoạt (inactive controls) không áp dụng yêu cầu tương phản tối thiểu. Script `audit.js` quét toàn bộ DOM visible text mà không trừ trạng thái disabled.
  - `target` `button.ds24-chip` cao 34px (iPhone & Web): Vùng chạm đã được mở rộng bằng `::after` (`inset: -5px 0` trên mobile; `inset-block: -4px` trên base) đảm bảo vùng chạm thực tế ≥ 44px (mobile) và ≥ 40px (web). `getBoundingClientRect` của script audit không tính `::after` (đã nêu tại mục 0.2 #28 và ghi chú Phụ lục 1).
  - `target` `button.toast-close` 20×20 (iPhone & Web): Đã có `#app-screen > .toast .toast-close::after { inset: -12px; }` mở rộng vùng chạm lên 44×44px (đã nêu tại mục 0.2 #28).
  - `target` `button.k7-row-open` (chiều cao 20px–36px) trên Web: Nút bấm đặt ở ô đầu của dòng bảng để hỗ trợ bàn phím (Tab/Enter). Về thao tác chạm chuột trên Web, toàn bộ hàng `tr` đều nhận sự kiện click và có chiều cao ≥ 40px (ví dụ BJ-01 `tr` cao 53px). Nâng riêng nút này lên 40px sẽ phá vỡ nhịp dọc và độ co giãn của bảng dữ liệu desktop.
  - `target` `button.k7-row-link` ("Cách tính" 64×24, "Xem chứng từ" 94×24...): Liên kết hành động nội dòng trong ô bảng dữ liệu Web (inline link trong cell), hiển thị 24px theo chuẩn bảng desktop.
- **Cần Phần 2:**
  - 1 mục: `button.cap-link-button` ("Sửa ngưỡng" 76×18 trong SCR-003 / CAP-01, "Dùng mặc định" 95×18 trong SCR-063) — Nếu muốn đạt 40px mà không vỡ dòng liên kết trong bảng/thẻ thông tin thì cần điều chỉnh bố cục/khoảng đệm của ô bảng ở Phần 2 hoặc chuyển T7-G5 theo mục 0.2 #28.
- **Lệch plan:**
  - Lệnh kiểm bàn phím `AUDIT_JS=tools/keys.js DEVICE=web node tools/golden.mjs capture tools/.keys-g3-7-web UIF-` ngoài các ca mở thẳng `UIF-*` còn lọc trúng các bước kịch bản có chứa chuỗi "UIF-" (ví dụ `SC_home_all_*_check-UIF-02`), khiến các bước trước đó trong kịch bản bị bỏ qua sinh lỗi "đi sai luồng" ở 5 ca kịch bản. Trên các ca mở thẳng có dialog thực thụ, script chạy hoàn toàn chính xác.
  - Khởi động lại HTTP server do tiến trình nền cũ gặp lỗi quyền đọc tệp của thư mục `app/` (lỗi 404). Sau khi khởi động lại server, lỗi JS: 0 ở toàn bộ các lệnh chụp.

### Phần 2 (Claude Code điền)

- **Mở đầu (2026-10-27):** `node --check` đạt; golden `tools/.golden-g3-7-p2` / `-web-p2` so với `-fix`: **khớp hoàn toàn** (2241 / 1350 ca, lỗi JS 0). `gitnexus analyze` chạy được ở phiên này (chỉ mục mới tới `b202607`).
- **Ảnh critique thực dùng** (mỗi ảnh cả iPhone `tools/.golden-g3-7-fix/…` và web `…-web-fix/…@web`; lần 2 cùng tên ở `-b` / `-web-b`): `HUB_home`; `UIF-01_SCR-001_READY`, `UIF-01_SCR-003_READY`; BJ-02 duyệt `SC_journey_2_11_review`, kết quả `SC_journey_2_17_wait` (SCR-012 `COMPLETED`), phiếu đã ghi `SC_g3_receipt_recorded_5_check-011` (bước 5 là màn SCR-011 `RECORDED`; bước cuối 7 là SCR-056); `UIF-03_SCR-015_READY`; `UIF-05_SCR-026_READY`; `UIF-08_SCR-044_BLIND_COUNT`, `UIF-08_SCR-046_READY`; `UIF-11_SCR-048_READY`; `UIF-14_SCR-074_READY_FOR_REVIEW`; `UIF-15_SCR-056_READY`; `UIF-17_SCR-083_COMPLETED`; K3 `SC_bj02_unknown_0` (không có K3 `*_UNKNOWN` của BJ nguồn ở chế độ Toàn Theme 7 trong kịch bản; thêm `SC_journey_5_43_unknown-01` = BJ-17 079 có thanh tab), K4 có thanh 5 tab `SC_journey_2_17_wait`; `CAP-01_SCR-062_READY`; thẻ kho `SC_demo_84_8-back-card` (bước cuối 87 `9-check-ledger` là Home, xem thêm). Kiểm lại: `UIF-09/10_SCR-037_READY`, `UIF-10_SCR-041_REJECTED`, `SC_bj08_blind_4_enter-2`, `UIF-02_SCR-008_READY_document@web`.
- **A7 critique lần 1** (`.impeccable/critique/2026-10-27T02-17-04Z__…md`): **iPhone 29 · web 29**, 0 P0, **1 P1** (Home "Chờ duyệt" là số mẫu cố định — cuối `SC_demo` vẫn 7). P1 cũ (HSD DH2509, ngày nhận BJ-02) đã hết. Detector 122 phát hiện, cùng hình G3-6 (vỏ harness / font DS / token advisory).
- **Bốn mục "kiểm lại":** 037 tiêu đề "Việc tiếp theo" chỉ có ghi chú + badge "Cách ly" lặp "2 hộp Cách ly" — **còn** (chữ / khuôn K5 → đề xuất, chưa sửa); 041 `REJECTED` thiếu Lô / Số lượng — **hết** (B); 044 dòng đã đếm dưới "Chưa đếm" — **hết** (B); 008 web Tab — **hết, không phải lỗi**: thứ tự thật Nhà cung cấp → Chọn tệp → ô xác nhận (ô "Kho và ngày nhận" chỉ đọc, không nhận focus) = thứ tự hàng của lưới hai cột và thứ tự lý do khoá nút.
- **Sửa ở B (vòng 1):**
  1. U1 / P1 — `app/hub.js` nguồn "Chờ duyệt" UIF-02 bỏ phiếu đã duyệt / từ chối (`bj02DecidedReceipts`, `bj02ReviewReceiptId` mới ở `app/bj02.js`; Hub đặt id khi mở từ "Chờ duyệt"). `impact`: `pendingSummary`, `applyDirectContext`, `applyDirectContextMine` LOW.
  2. U2 — `app/bj03.js` `lotLines`: một lô bán được chứa đủ dòng → chỉ "Lô {mã}" (bỏ "· 121 hộp" lặp; cả thẻ iPhone). `impact` LOW. CSS 015 web: tên sản phẩm một dòng.
  3. U3 — `styles/screens.css` BJ-14 / BJ-15 hàng nhãn–giá trị: giá trị theo bề rộng nội dung (hết gãy 074 web Tóm tắt, hết tràn ngày 056 iPhone).
  4. 041 `REJECTED` thêm "Lô", "Số lượng" (chữ có sẵn ở `bj10Facts`) — `render041BJ10` LOW.
  5. 044 — `app/bj08.js` thêm `focusout`: rời ô đếm sang ô khác / ra ngoài thì lọc lại; sang nút thì không (giữ cú bấm). Kiểm bằng sự kiện tổng hợp (headless không có focus cửa sổ).
  6. U6 — `app/bj17.js` phụ đề 079 "{nghiệp vụ} {mã} · {phạm vi}" thay mã nội bộ `REC-UNKNOWN-0x` / `REC-xx-…` (không phải chữ spec). `render079BJ17` LOW.
  7. K4 — `styles/components.css` khoảng 12px giữa mô tả và thẻ ở các BJ chưa có `gap`.
  8. "Cần Phần 2" — `cap-link-button` web thêm `::after` (đo: 84×40).
- **Ca golden khác** (`.golden-g3-7-b` / `-web-b` so `-fix`, lỗi JS 0): chữ chỉ đổi đúng các nhóm trên — "Lô DH2507 · 121 hộp" → "Lô DH2507" (30 / 13 ca), phụ đề BJ-17 (≈ 45 / 19 ca), số "Chờ duyệt" sau duyệt BJ-02 trong `SC_demo` / `SC_journey` (7 → 6, 3 → 2 nhận hàng), 041 `REJECTED` (+ Lô / Số lượng). Ảnh khác thêm: K4 các BJ (khoảng 12px), 074 / 056, 015 web.
- **Đo lại sau B:** audit iPhone 9 tương phản / 10 vùng chạm, web 6 / 42 — như sau Phần 1 (đều là nút `disabled`, chip / toast / `cap-link-button` có `::after`, liên kết nội dòng bảng web); bàn phím 1 hộp thoại đạt 3/3 (5 "lỗi" vẫn là ca kịch bản bị bộ lọc `UIF-` cắt); ngõ cụt 0 / 498 mỗi khung, lỗi JS 0.
- **A7 critique lần 2** (`.impeccable/critique/2026-10-27T02-35-15Z__…md`): **iPhone 30 · web 31**, 0 P0 / P1. Lên: H1 3 → 4 (hai khung), H8 web 2 → 3. **Chưa đạt 32** → theo B2 dừng, hỏi người dùng.
- **Người dùng chốt (2026-10-27):** làm **U4**; rồi đóng G3-7 với điểm đạt được (không làm U5, gộp "Tóm tắt" web, tiền một kiểu chữ + badge 048 — ghi `⬜ đề xuất` ở T7-P mục 13).
- **B vòng 2 (U4):** `app/bj05.js` "Lấy đủ tất cả" ở 026 (`io05PickableAllocations`, `io05PickAllFull`; hiện khi còn ≥ 2 lô chưa lấy đủ; bỏ lô chờ điều chỉnh hàng đang cầm; focus sang "Rà soát bàn giao"). `render026BJ05` LOW. Không làm ở 015 (demo chỉ một dòng đủ căn cứ) và 037 (kiểm từng dòng là bản chất bước xác minh). Golden `-b2` so `-b`: chữ chỉ thêm "Lấy đủ tất cả" (34 / 20 ca nhóm BJ-05); audit không đổi; ngõ cụt 0 / 498.
- **A7 critique lần 3** (`.impeccable/critique/2026-10-27T02-42-19Z__…md`): **iPhone 31 · web 31**, 0 P0 / P1 (H7 iPhone 2 → 3). Điểm Giai đoạn 3 = **31/40**.
- **C:** v5.26.1 (`manifest.json`, `harness/workbench.js`, badge `index.html`), CHANGELOG `[5.26.1]`; mốc cuối `tools/.golden-g3` (2241 ca) / `tools/.golden-g3-web` (1350 ca), lỗi JS 0, khớp hoàn toàn `-b2`. Tài liệu `03.design`: SCR-003, 011, 019, 041, 049, 053, 056, 083, PAT-NAV, INDEX; `sync-registry.py` chỉ đổi đúng các tệp đó + prototype.
- **Lệch plan:** ảnh "bước cuối `SC_demo` (thẻ kho)" thực ra là Home (bước 87) — dùng bước 84 cho thẻ kho; K3 Toàn Theme 7 iPhone không có trong kịch bản — dùng K3 chế độ BJ.

---

## Phụ lục 1 — `html/tools/audit.js`

```js
(() => {
  const root = document.querySelector('#app-screen');
  if (!root) return { error: 'no app-screen' };
  const web = document.querySelector('.device-preview')?.classList.contains('is-web');
  const out = { contrast: [], target: [], overflow: [], noname: [], rowRole: [] };
  const parse = (c) => { const m = String(c).match(/rgba?\(([^)]+)\)/); if (!m) return null; const p = m[1].split(',').map((x) => parseFloat(x)); return { r: p[0], g: p[1], b: p[2], a: p.length > 3 ? p[3] : 1 }; };
  const lin = (v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); };
  const lum = (c) => 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
  const bgOf = (el) => {
    const layers = []; let e = el;
    while (e && e.nodeType === 1) { const c = parse(getComputedStyle(e).backgroundColor); if (c && c.a > 0) { layers.push(c); if (c.a >= 1) break; } e = e.parentElement; }
    let base = { r: 255, g: 255, b: 255 };
    for (let i = layers.length - 1; i >= 0; i--) { const l = layers[i]; base = { r: l.r * l.a + base.r * (1 - l.a), g: l.g * l.a + base.g * (1 - l.a), b: l.b * l.a + base.b * (1 - l.a) }; }
    return base;
  };
  const visible = (el) => { const r = el.getBoundingClientRect(); if (r.width < 1 || r.height < 1) return false; for (let e = el; e && e !== document.body; e = e.parentElement) { const s = getComputedStyle(e); if (s.display === 'none' || s.visibility === 'hidden' || e.hidden) return false; } return true; };
  const label = (el) => `${el.tagName.toLowerCase()}${el.className && typeof el.className === 'string' ? '.' + el.className.trim().split(/\s+/).slice(0, 2).join('.') : ''}`;
  const seen = new Set();
  const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
  while (walker.nextNode()) {
    const n = walker.currentNode; const t = n.nodeValue.trim(); if (!t) continue;
    const el = n.parentElement; if (!el || !visible(el) || el.closest('.toast')) continue;
    const s = getComputedStyle(el); const fg = parse(s.color); if (!fg) continue;
    const bg = bgOf(el);
    const fgc = { r: fg.r * fg.a + bg.r * (1 - fg.a), g: fg.g * fg.a + bg.g * (1 - fg.a), b: fg.b * fg.a + bg.b * (1 - fg.a) };
    const L1 = lum(fgc), L2 = lum(bg); const ratio = (Math.max(L1, L2) + 0.05) / (Math.min(L1, L2) + 0.05);
    const size = parseFloat(s.fontSize), bold = parseInt(s.fontWeight, 10) >= 700;
    const large = size >= 24 || (size >= 18.66 && bold);
    const need = large ? 3 : 4.5;
    if (ratio < need) { const k = label(el) + '|' + t.slice(0, 24); if (!seen.has(k)) { seen.add(k); out.contrast.push(`${ratio.toFixed(2)} ${label(el)} "${t.slice(0, 40)}"`); } }
  }
  const min = web ? 40 : 44;
  root.querySelectorAll('button, [role="button"], a[href], input:not([type=hidden]), select, textarea, tr[tabindex], [role="checkbox"], [role="radio"]').forEach((el) => {
    if (!visible(el) || el.closest('.k7-table-list') && web) return;
    const r = el.getBoundingClientRect();
    if (el.matches('tr[tabindex]')) { if (r.height < min) out.target.push(`tr ${Math.round(r.height)}px`); if (!el.getAttribute('role')) out.rowRole.push(label(el)); return; }
    if (r.width < min || r.height < min) out.target.push(`${label(el)} ${Math.round(r.width)}×${Math.round(r.height)} "${(el.innerText || el.getAttribute('aria-label') || '').trim().slice(0, 24)}"`);
    const name = (el.getAttribute('aria-label') || el.innerText || el.value || '').trim();
    if (!name && !el.labels?.length) out.noname.push(label(el));
  });
  const content = root.querySelector('.app-content') || root;
  if (content.scrollWidth > content.clientWidth + 1) out.overflow.push(`.app-content ${content.scrollWidth}>${content.clientWidth}`);
  const frame = root.getBoundingClientRect();
  root.querySelectorAll('*').forEach((el) => { if (!visible(el)) return; const r = el.getBoundingClientRect(); if (r.right > frame.right + 1 && !el.closest('.k7-table-wrap, .sheet-backdrop, .toast, .ds24-chip-scroll')) { const k = 'ov|' + label(el); if (!seen.has(k)) { seen.add(k); out.overflow.push(`${label(el)} right ${Math.round(r.right)}>${Math.round(frame.right)}`); } } });
  return out;
})()
```

Ghi chú: vùng chạm mở rộng bằng `::after` (chip BJ-01, nút đóng toast) **không** được tính bởi `getBoundingClientRect` → các phần tử này có thể bị báo thiếu. Với mỗi phần tử như vậy: đo vùng `::after` bằng `getComputedStyle(el, '::after')` (`inset` / `width` / `height`) và ghi vào mục D; đủ 44 thì không phải lỗi. Đây là mục 0.2 #28 của plan G3 (chip BJ-01 cao 34 với `::after`; nút "Sửa ngưỡng" CAP-01 cao 18px).

## Phụ lục 2 — `html/tools/keys.js`

```js
(() => {
  const dialog = document.querySelector('#app-screen [role="dialog"]');
  if (!dialog) return { keys: null };
  const items = () => [...dialog.querySelectorAll("button:not([disabled]), [href], input, textarea, select, [tabindex]:not([tabindex='-1'])")].filter((el) => el.offsetParent !== null);
  const press = (key, shiftKey = false) => window.dispatchEvent(new KeyboardEvent('keydown', { key, shiftKey, bubbles: true, cancelable: true }));
  const list = items(); const r = { items: list.length, tabWrap: null, shiftTabWrap: null, escCloses: null };
  if (list.length) {
    list[list.length - 1].focus(); press('Tab'); r.tabWrap = document.activeElement === list[0];
    list[0].focus(); press('Tab', true); r.shiftTabWrap = document.activeElement === list[list.length - 1];
  }
  press('Escape'); r.escCloses = !document.querySelector('#app-screen [role="dialog"]');
  return { keys: r };
})()
```

Đọc kết quả: `tabWrap` / `shiftTabWrap` phải `true` (hoặc `items` = 0 → lỗi: hộp thoại không có gì để focus); `escCloses` = `false` → hộp thoại đó chưa đăng ký `onDialogClose` ở BJ của nó (xem `app/core.js` dòng ~510 và các dòng `onDialogClose["UIF-NN"] =` trong `app/bjNN.js`) — trừ hộp thoại cố ý không đóng bằng Esc (vd. đang xử lý), ghi lý do ở D.
