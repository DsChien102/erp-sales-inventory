# T6-2a — Prototype công nợ phải thu (CN-01…03, SG-13) Implementation Plan

> **Trạng thái 2026-11-18: đã chốt.** Kế hoạch này là bản gốc; kết quả cuối khác ở chỗ: redesign CN-01 (Quá hạn dẫn đầu), CN-03 (một danh sách đơn có tick), SG-13 (Dòng tiền), 45 ca / 90 ảnh, và `tokens.css`/`components.css` đã chuyển sang `specs/prototype/shared/` (symlink `html/shared`). Xem `html/README.md`.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dựng prototype HTML (iPhone 390 + web 1280) cho CN-01, CN-02, CN-03, SG-13 bản cấn trừ và một màn gom `patches`, kèm bộ ảnh đích, để bạn duyệt trước khi viết plan Flutter T6-2.

**Architecture:** Thư mục riêng `specs/themes/theme-06/03.design/prototype/html/` (hướng B, bạn chọn): chép `tokens.css` của Theme 7, rút `components.css` chỉ còn rule 4 màn dùng, thêm `receivable.css`. JS thuần không build: dữ liệu giả theo ví dụ 2.3, các hàm thuần (`allocateOldestFirst`, `planReturnSettlement`, định dạng, nhãn hạn đơn / khách) có test `node --test`, mỗi màn một file render. Ảnh chụp bằng Chrome headless CLI.

**Tech Stack:** HTML/CSS/JS thuần (ES module), Node 24 `node --test`, Google Chrome headless (`/Applications/Google Chrome.app`), `python3 -m http.server`.

**Spec:** [TH-06](../../../02-yeu-cau/TH-06-cong-no.md) mục 2.2, 2.3, 4.2–4.5, 5.2–5.6, 6.3; thiết kế đã duyệt trong chat 2026-11-18 (hướng B, `patches` gom sửa màn cũ). Review plan 2026-11-18: chốt **ẩn khối cấn trừ khi `còn_lại = 0`** (AC-03 US-03.1).

## Global Constraints

- Tiền: VND, số nguyên (đơn vị `minor` = đồng), hiển thị `18.000.000 ₫`; canh phải, chữ số đều (`font-variant-numeric: tabular-nums`) (5.6).
- Nhãn hạn đúng BR-30: `⚠ Quá hạn N ngày` (đỏ, có biểu tượng, không chỉ màu), `Hẹn dd/MM`, `Đến hạn hôm nay`, `Không có hẹn`. Hôm nay cố định trong dữ liệu giả = **2026-11-18**. Ở Flutter số ngày lấy từ server (BR-31); prototype tự tính chỉ để có dữ liệu.
- Vùng chạm ≥ 44 px (ô chọn cấn trừ, dòng danh sách) (5.6).
- Chữ trên màn **đúng nguyên văn spec**: "Công nợ phải thu", "Tổng còn phải thu", "Tất cả", "Quá hạn (n)", "Tìm tên, SĐT", "Không tìm thấy khách phù hợp.", "Xoá tìm kiếm", "Không có khách nào đang nợ", "Đơn bán nợ sẽ hiện ở đây.", "Không tải được công nợ", "Thử lại", "Ngừng hoạt động", "Chọn một khách để xem công nợ", "Công nợ khách hàng", "Còn nợ", "Không còn nợ", "Không còn đơn nào nợ", "Chưa có lần thu nào", "Xem thêm", "Thu tiền", "Số tiền", "Trả hết", "Phương thức", "Tiền mặt", "Chuyển khoản", "Mã giao dịch (Không bắt buộc)", "Số tiền vượt quá tổng còn nợ của khách.", "Quay lại", "Xác nhận thu", "Xác nhận thu tiền?", "Xác nhận", "Sẽ trừ vào", "Khách còn nợ sau khi thu", "Đang ghi nhận...", "Không ghi nhận được. Thử lại?", "Công nợ của khách vừa thay đổi. Hãy tải lại rồi thử lại.", "Tải lại", "Bỏ khoản thu đang nhập?", "Đã thu <số> từ <khách>", "Quyết toán đổi/trả", "Khách được hưởng", "Cấn trừ vào đơn khác", "Trừ vào nợ đơn khác của khách thay vì hoàn tiền.", "Hoàn cho khách", "Phương thức hoàn", "Giảm nợ đơn này", "Phần khách được hưởng được trừ vào nợ của chính đơn này.", "Xác nhận đổi/trả", "Xác nhận đổi/trả?", "Cấn trừ <số> vào đơn <mã>", "Công nợ của khách vừa thay đổi. Hãy tải lại quyết toán.".
- Chữ spec **không** quy định (nút của hộp "Bỏ khoản thu đang nhập?", tiêu đề phụ SG-13 có sẵn…): lấy từ màn Flutter đang có nếu có; không thì đặt tạm và liệt kê trong README mục "Chữ tạm" để bạn chốt lúc duyệt ảnh.
- Chỉ dùng token `--c45-v2-*` từ `tokens.css`; không màu / cỡ chữ gõ cứng trong CSS mới (`receivable.css`). Rule chép từ Theme 7 giữ nguyên giá trị gốc.
- Không sửa gì ngoài `specs/themes/theme-06/` và `docs/refactor/plans/T6/`. Không đụng harness Theme 7.
- Khổ chụp: iPhone **390×844**, web **1280×800**, scale 1. Font: Theme 7 không nạp Inter (chỉ khai báo `font-family`), nên ảnh dùng font hệ thống; giữ như Theme 7, ghi trong README để lúc so với Flutter không bắt nhầm lệch font.
- Commit chỉ `git add specs/themes/theme-06` (nhánh đang có nhiều thay đổi khác chưa commit). Prototype không phải code app nên không cần `detect_changes` của GitNexus.

## Review Focus

- Số tiền rất lớn (≥ 1.000.000.000 ₫) trên iPhone: không tràn hàng, không che chữ "đơn" (ca `cn01__long`).
- Tên khách dài / SĐT thiếu: cắt `…`, không đẩy số tiền xuống hàng (ca `cn01__long`).
- Bỏ chọn **mọi** đơn cấn trừ ở SG-13: "Hoàn cho khách" = toàn bộ `còn_lại`, hiện phương thức hoàn.
- Bỏ chọn DH-002 (đơn đang nhận tiền) ở SG-13: DH-003 nhận phần đó (`Trừ 500.000`), hoàn vẫn 0 (FR-04 US-03.1).
- SG-13 có đủ ba dòng (giảm nợ → cấn trừ → hoàn) đúng thứ tự (ca `sg13__mixed`).
- Nhập số có dấu chấm ngăn cách / ký tự lạ ở ô tiền CN-03: chỉ giữ chữ số, không NaN.
- Khách có 0 đơn quá hạn nhưng `Đến hạn hôm nay` (không tính quá hạn, AC-03 US-01.2).
- Dữ liệu từng state đúng **một** thời điểm của ví dụ 2.3 (không trộn lịch sử sau bước 2 với công nợ trước bước 1).

---

## File Structure

```text
specs/themes/theme-06/03.design/prototype/html/
  index.html            khung: tải CSS + app/main.js
  package.json          {"type":"module"} (node --test import app/*.js không cảnh báo)
  .gitignore            tools/proto-final/
  README.md             cách chạy, cách chụp, danh sách ca, nguồn token, font, chữ tạm
  styles/tokens.css     chép NGUYÊN từ theme-07
  styles/components.css rút từ theme-07 (chỉ rule dùng) + dòng đầu ghi nguồn
  styles/receivable.css rule mới của 4 màn + patches (gồm spinner)
  app/icon.js           icon() + k7CheckMark() chép từ theme-07, + SVG dùng
  app/format.js         formatVnd, parseMoneyInput, dueLabel, customerDueLabel, overdueAmountMinor
  app/allocate.js       allocateOldestFirst, planReturnSettlement
  app/data.js           TODAY, customers, edgeCustomers, tuanAt, summaryOf, dữ liệu SG-13
  app/cn01.js cn02.js cn03.js sg13.js patches.js   renderCn01(state, device) … → chuỗi HTML
  app/main.js           render(screen, state, device), gắn HTML, tương tác (lọc, tìm, chọn cấn trừ, nhập tiền)
  tests/format.test.mjs allocate.test.mjs data.test.mjs
  tools/check-classes.sh  class dùng trong app/*.js mà không có rule CSS
  tools/capture.mjs     chụp mọi ca → tools/proto-final/{iphone,web}/
  tools/proto-final/    ảnh đích (không vào git)
```

## Danh sách ca (khoá tên ảnh `<screen>__<state>.png`)

| screen | state | Dữ liệu |
|---|---|---|
| `cn01` | `loading`, `all`, `overdue`, `search-empty`, `empty`, `error`, `loading-more`, `long` | `customers` (trước bước 1 của 2.3); `long` = `customers` + `edgeCustomers` |
| `cn02` | `full`, `after-offset`, `block-error`, `paid-off`, `inactive`, `no-history` | Tuấn theo `tuanAt(…)`; `inactive` = Cô Hoa; `no-history` = Chị Lan |
| `cn03` | `empty`, `valid`, `over`, `transfer`, `confirm`, `submitting`, `submit-error`, `changed`, `leave-confirm`, `success` | Tuấn `before`; `success` = CN-02 Tuấn `afterCollect` + toast |
| `sg13` | `all-selected`, `one-unchecked`, `none-selected`, `mixed`, `source-has-debt`, `no-other-debt`, `confirm`, `stale` | bước 2 của 2.3, trừ `mixed` / `source-has-debt` / `no-other-debt` (dữ liệu riêng, Task 6) |
| `patches` | `sg09`, `sg09b`, `sg09c`, `sg14`, `pt07`, `more-menu` | — |

Tổng **38 ca × 2 khổ = 76 ảnh**.

Web: `cn01`/`cn02` hiển thị hai cột (trái CN-01, phải CN-02 hoặc "Chọn một khách để xem công nợ"); `cn03` là hộp thoại trên hai cột; `cn01__all` ở web = chưa chọn khách, `cn02__full` ở web = đã chọn Anh Tuấn.

Mỗi state tự mang đủ dữ liệu của nó (số đã nhập, đơn đang chọn, phương thức…): `capture.mjs` chỉ truyền `screen`, `state`, `device`. Tham số `?amount=` chỉ để thử tay.

---

### Task 1: Khung, token, component rút gọn

**Files:**
- Create: `specs/themes/theme-06/03.design/prototype/html/{index.html,package.json,.gitignore,styles/tokens.css,styles/components.css,styles/receivable.css,app/icon.js,app/main.js,tools/check-classes.sh}`

**Interfaces:**
- Produces: URL `index.html?screen=<id>&state=<id>&device=iphone|web`; `main.js` export `render(screen, state, device): string` (điền ở các task sau); `icon(name, className): string`, `k7CheckMark(checked, disabled): string`; CSS class gốc `.rc-app` (khung 390 / 1280), `.rc-twocol` (web hai cột).

- [ ] **Step 1: Chép `tokens.css` nguyên văn, tạo `package.json`, `.gitignore`**

```bash
cd /Users/macbook/Documents/graduation_project
P=specs/themes/theme-06/03.design/prototype/html
T=specs/themes/theme-07/03.design/prototype/html
mkdir -p $P/{styles,app,tests,tools}
cp $T/styles/tokens.css $P/styles/tokens.css
printf '{ "type": "module", "private": true }\n' > $P/package.json
printf 'tools/proto-final/\n' > $P/.gitignore
```

- [ ] **Step 2: Rút `components.css`** từ `$T/styles/components.css` (3.274 dòng; một class có thể được định nghĩa nhiều chỗ, ví dụ `.app-appbar` ở dòng 312 và 905, `.bottom-sheet` ở 875 và 1033).
  - Lấy **mọi** định nghĩa, theo thứ tự gốc (giữ thứ tự đè), của: reset / `:root` / `body`, `.button*`, `.ds24-button*`, `.ds24-chip*`, `.ds24-badge*`, `.ds24-field*`, `.ds24-empty*`, `.ds-segmented`, `.ds-segment*`, `.bottom-sheet*`, `.confirm-dialog*`, `.confirm-backdrop`, `.app-appbar*`, `.app-icon-button`, `.app-statusbar`, `.k7-check*` (ô chọn), `.skeleton*`, `.toast*`, `.icon*`, `@media (prefers-reduced-motion)`.
  - **Bỏ** rule có selector chứa `body[data-active-uif`, `.device-preview`, `.is-web`, `.k7-` (trừ `.k7-check`), `.bj0`, `.bj1`, `.workbench`.
  - Dòng đầu: `/* Rút từ specs/themes/theme-07/03.design/prototype/html/styles/components.css (T6-2a); cập nhật cùng nguồn khi Theme 7 đổi token. */`.

- [ ] **Step 3: Chép icon và ô chọn** sang `app/icon.js` (đổi thành `export function`): `icon()` từ `$T/app/core.js:256` cùng các path SVG nó tham chiếu; `k7CheckMark()` từ `$T/app/shared-patterns.js` (ô chọn dùng `<button role="checkbox" aria-checked>` như `shared-patterns.js:164`). Biểu tượng dùng: cảnh báo (⚠), chevron phải (›), đóng (✕), tìm (🔍), quay lại (←), dấu chọn. Icon nào nguồn không có thì thêm SVG vào cùng file, ghi chú `mới T6-2a`.

- [ ] **Step 4: Viết `index.html`, `styles/receivable.css`, `app/main.js`** (ES module). `main.js` đọc `URLSearchParams`, gọi `render()`, gắn vào `#root`; khung `.rc-app[data-device]` rộng 390 hoặc 1280, `body` margin 0 (ảnh chụp đúng khổ cửa sổ); web: `.rc-twocol`, cột trái 380. Chưa có màn: `render` trả `<p>chưa có màn</p>`. `receivable.css` có `.rc-spinner` (cho `loading-more`), chỉ dùng token.

- [ ] **Step 5: Viết `tools/check-classes.sh`** (chạy từ Task 3 trở đi):

```bash
#!/usr/bin/env bash
# In class có trong HTML do app/*.js sinh ra mà không có rule nào trong styles/*.css
cd "$(dirname "$0")/.."
grep -oh 'class="[^"]*"' app/*.js | sed 's/class="//; s/"$//' | tr ' ' '\n' | grep -v '\$' | grep -v '^$' | sort -u |
while read c; do grep -q "\.$c\b" styles/*.css || echo "KHÔNG CÓ RULE $c"; done
```

- [ ] **Step 6: Verify**

```bash
cd $P && python3 -m http.server 8766 --bind 127.0.0.1 &
curl -s -o /dev/null -w "%{http_code}\n" "http://127.0.0.1:8766/index.html?screen=cn01&state=all&device=iphone"
# biến thiếu:
grep -oh "var(--c45-v2-[a-z0-9-]*" styles/components.css styles/receivable.css | sed 's/var(//' | sort -u | while read v; do grep -q "^ *$v:" styles/tokens.css || echo "THIẾU $v"; done
# selector cấm còn sót:
grep -nE 'data-active-uif|\.device-preview|\.is-web|\.bj[01][0-9]|\.workbench' styles/components.css
```
Expected: `200`; không dòng `THIẾU`; lệnh grep cuối không in gì.

- [ ] **Step 7: Commit** `git add specs/themes/theme-06 && git commit -m "feat(prototype): T6-2a khung prototype công nợ"`

---

### Task 2: Hàm thuần có test (format, nhãn hạn, chia cũ trước, kế hoạch đổi/trả)

**Files:**
- Create: `app/format.js`, `app/allocate.js`, `tests/format.test.mjs`, `tests/allocate.test.mjs`

**Interfaces:**
- Produces (ES module, chạy được cả trình duyệt và node):
  - `formatVnd(minor: number): string` → `"18.000.000 ₫"`
  - `parseMoneyInput(text: string): number` → chỉ giữ chữ số; rỗng → `0`
  - `dueLabel(dueDate: string|null, today: string): {kind:'overdue'|'today'|'upcoming'|'none', days?: number, text: string}` — nhãn **một đơn còn nợ** (chỉ gọi cho đơn `outstanding > 0`).
  - `customerDueLabel(orders: {outstandingMinor:number, dueDate:string|null}[], today: string): {kind, days?, text}` — nhãn **khách** (FR-02 US-01.1): bỏ đơn `outstanding = 0`; có đơn quá hạn → `overdue`, `days` = lớn nhất; không thì có đơn hẹn hôm nay → `today`; không thì hẹn gần nhất → `upcoming`; không đơn nào có hẹn → `none`.
  - `overdueAmountMinor(orders, today): number` — Σ outstanding các đơn quá hạn (FR-04 US-01.2).
  - `allocateOldestFirst(orders: {id:string, outstandingMinor:number}[], amountMinor: number): {id:string, allocatedMinor:number, outstandingAfterMinor:number}[]` — chỉ trả đơn có phân bổ > 0; `orders` đã xếp cũ trước.
  - `planReturnSettlement({entitled:number, sourceOutstanding:number, candidates:{id:string,outstandingMinor:number}[], selectedIds:string[]}): {reduceOwnDebt:number, remaining:number, offsets:{id:string,amountMinor:number}[], refund:number, showOffsetBlock:boolean}` — công thức 2.2:
    - `reduceOwnDebt = min(entitled, sourceOutstanding)`, `remaining = entitled − reduceOwnDebt`;
    - cấn trừ = **gọi lại `allocateOldestFirst`** trên các đơn trong `selectedIds` (giữ thứ tự `candidates`) với `remaining`;
    - `offsets` liệt kê **mọi** đơn trong `candidates` (đơn bỏ chọn / không dùng tới → `amountMinor: 0`, để màn hiện "Trừ 0" mờ, FR-04);
    - `refund = remaining − Σ offsets`;
    - `showOffsetBlock = candidates.length > 0 && remaining > 0` (chốt review: ẩn khối khi `còn_lại = 0`).

- [ ] **Step 1: Viết test fail** (`node --test tests/`), với giá trị spec:
  - `formatVnd(18000000) === "18.000.000 ₫"`, `formatVnd(0) === "0 ₫"`, `formatVnd(1234567890) === "1.234.567.890 ₫"`.
  - `parseMoneyInput("10.000.000đ") === 10000000`; `parseMoneyInput("abc") === 0`; `parseMoneyInput("") === 0`.
  - `dueLabel("2026-11-10","2026-11-18")` → `{kind:'overdue', days:8, text:'Quá hạn 8 ngày'}`; `"2026-11-25"` → `{kind:'upcoming', text:'Hẹn 25/11'}`; `"2026-11-18"` → `{kind:'today', text:'Đến hạn hôm nay'}`; `null` → `{kind:'none', text:'Không có hẹn'}`.
  - `customerDueLabel`: Tuấn (DH-001 4e6 hẹn 10/11, DH-002 8e6 hẹn 15/11, DH-003 6e6 hẹn 30/11) → `Quá hạn 8 ngày`; Trại Hưng Phát (hẹn 18/11 và 30/11) → `Đến hạn hôm nay`; Chị Lan (hẹn 25/11) → `Hẹn 25/11`; mọi đơn `dueDate:null` → `Không có hẹn`; đơn quá hạn có `outstanding 0` bị bỏ qua.
  - `overdueAmountMinor` của Tuấn = `12000000` (AC-01 US-01.2).
  - `allocateOldestFirst([{id:'DH-001',outstandingMinor:4e6},{id:'DH-002',outstandingMinor:8e6}], 10e6)` → `[{DH-001,4e6,0},{DH-002,6e6,2e6}]`; amount `0` → `[]`; amount = tổng → mọi `outstandingAfterMinor = 0`.
  - `planReturnSettlement`:
    - AC-01 US-03.1: `entitled=500000, sourceOutstanding=0, candidates=[DH-002 2e6, DH-003 6e6], selected=both` → offsets `[{DH-002,500000},{DH-003,0}]`, refund `0`, reduceOwnDebt `0`, `showOffsetBlock` true.
    - FR-04 US-03.1: như trên, `selected=[DH-003]` → offsets `[{DH-002,0},{DH-003,500000}]`, refund `0`.
    - AC-02 US-03.1: `selected=[]` → mọi offset `0`, refund `500000`.
    - AC-03 US-03.1 / SC-03: `entitled=600000, sourceOutstanding=600000, candidates=[DH-002 2e6], selected=[DH-002]` → reduceOwnDebt `600000`, remaining `0`, refund `0`, `showOffsetBlock` **false**.
    - AC-02 US-03.2: `entitled=3e6, sourceOutstanding=0, candidates=[DH-002 2e6], selected=[DH-002]` → offset `2e6`, refund `1e6`.
    - Giảm nợ một phần (ca `sg13__mixed`): `entitled=3e6, sourceOutstanding=400000, candidates=[DH-002 2e6], selected=[DH-002]` → reduceOwnDebt `400000`, remaining `2600000`, offset `2e6`, refund `600000`.
    - Không đơn khác: `entitled=500000, sourceOutstanding=0, candidates=[]` → `showOffsetBlock` false, refund `500000`.

- [ ] **Step 2: Chạy, thấy fail** — `cd $P && node --test tests/` → FAIL (module không tồn tại).
- [ ] **Step 3: Cài đặt** hai file theo chữ ký trên (thuần, không DOM).
- [ ] **Step 4: Chạy lại** — Expected: toàn bộ PASS.
- [ ] **Step 5: Commit** `feat(prototype): hàm thuần chia cũ trước + kế hoạch cấn trừ T6-2a`

---

### Task 3: Dữ liệu giả + CN-01

**Files:**
- Create: `app/data.js`, `app/cn01.js`, `tests/data.test.mjs`; Modify: `app/main.js`, `styles/receivable.css`

**Interfaces:**
- Consumes: Task 2 (`formatVnd`, `customerDueLabel`, `overdueAmountMinor`), `icon`.
- Produces `data.js` export:
  - `TODAY = '2026-11-18'`.
  - `customers[]` — 3 khách chuẩn, trạng thái **trước bước 1** ví dụ 2.3, dạng `{id, displayName, phone, isActive, orders:[{id, code, completedAt, payableMinor, outstandingMinor, dueDate}], history:[…]}`:
    - **Anh Tuấn** `0901 234 567`: DH-001/002/003 đúng bảng 2.3; `history` = `tuanAt('before').history`.
    - **Chị Lan** `0912 345 678`: 1 đơn DH-020 6.000.000, hẹn 25/11; `history: []`.
    - **Trại Hưng Phát** `0987 654 321`: 2 đơn, DH-021 1.000.000 hẹn 18/11, DH-022 1.500.000 hẹn 30/11; `history: []`.
  - `edgeCustomers[]`:
    - **Công ty TNHH Thuốc Thú Y và Vật Tư Chăn Nuôi Đồng Bằng Sông Cửu Long**, `phone: null`, 1 đơn DH-040 1.234.567.890, hẹn 30/11.
    - **Cô Hoa** `0933 111 222`, `isActive: false`, 1 đơn DH-030 tổng 2.000.000, thu lúc bán 500.000 → còn nợ 1.500.000, hẹn 30/11. `history` (mới nhất trước): `{kind:'order_payment', amount:500000, orderCode:'DH-030', at:'2026-11-12T09:10'}` ("Thu 500.000 · đơn DH-030"); `{kind:'refund', amount:200000, orderCode:'DH-029', at:'2026-11-03T16:00'}` ("Hoàn 200.000 · đơn DH-029": trả hàng của DH-029 đã trả đủ, lúc đó khách không còn đơn nợ nào khác nên hoàn tiền mặt, đúng BR-26).
  - `tuanAt(moment)` → `{orders, history}` của Tuấn; history mới nhất trước:
    - `'before'`: đơn đúng bảng 2.3; history = `[C2]` với `C2 = {kind:'collection', amount:2e6, method:'cash', at:'2026-11-06T14:20', by:'Nguyễn An', allocations:[{code:'DH-002', amount:2e6}]}` (khung 5.3).
    - `'afterCollect'` (sau bước 1): DH-002 còn 2.000.000, DH-003 còn 6.000.000; history = `[C10, C2]`, `C10 = {kind:'collection', amount:10e6, method:'cash', at:'2026-11-18T09:30', by:'Nguyễn An', allocations:[{DH-001,4e6},{DH-002,6e6}]}`.
    - `'afterOffset'` (sau bước 1 + 2): DH-002 còn 1.500.000, DH-003 còn 6.000.000 (DH-001 không còn trong đơn nợ, AC-03 US-01.3); history = `[O500, C10, C2]`, `O500 = {kind:'offset', amount:500000, fromOrder:'DH-001', returnCode:'#DT-0001', toOrder:'DH-002', at:'2026-11-18T10:15', by:'Nguyễn An'}`.
    - `'paidOff'` (thu "Trả hết" 18.000.000 từ `before`): `orders: []`; history = `[C18, C2]`, `C18` vào DH-001 4.000.000, DH-002 8.000.000, DH-003 6.000.000.
  - `summaryOf(list)` → `{totalOutstandingMinor, customerCount, overdueCustomerCount}`.
  - `renderCn01(state, device): string`.

- [ ] **Step 1: Test dữ liệu** trong `tests/data.test.mjs`:
  - `summaryOf(customers)` → `{totalOutstandingMinor: 26500000, customerCount: 3, overdueCustomerCount: 1}`.
  - Tuấn: Σ outstanding = 18.000.000, `customerDueLabel` = `Quá hạn 8 ngày`, 3 đơn (AC-01 US-01.1).
  - `tuanAt('afterCollect')` Σ = 8.000.000; `tuanAt('afterOffset')` Σ = 7.500.000; `tuanAt('paidOff')` Σ = 0 (khớp ví dụ 2.3).
  - Mọi `collection` trong history: Σ `allocations` = `amount`.
  - Cô Hoa: Σ outstanding = 1.500.000.
- [ ] **Step 2: Chạy fail**, **Step 3: viết `data.js`**, **Step 4: pass**.
- [ ] **Step 5: Viết `renderCn01`** cho 8 trạng thái theo khung ASCII mục 5.2: appbar "Công nợ phải thu"; ô tổng ("Tổng còn phải thu", số, "<n> khách", tính theo `summaryOf` của toàn bộ danh sách state, không theo ô tìm — BR-11); 2 chip `Tất cả` / `Quá hạn (n)`; ô tìm "Tìm tên, SĐT"; dòng khách: tên (cắt `…`) + số tiền phải (không xuống hàng), `SĐT · n đơn` (SĐT thiếu → chỉ `n đơn`), nhãn hạn (`customerDueLabel`, quá hạn có icon cảnh báo) + chevron; khách `isActive:false` có badge `Ngừng hoạt động` cạnh tên (EC-02 US-01.1). Xếp công nợ giảm dần, bằng nhau thì tên tăng dần (BR-10).
  - `loading`: skeleton 6 dòng + ô tổng skeleton. `overdue`: chip Quá hạn chọn, chỉ Tuấn, dòng `Quá hạn 8 ngày · 12.000.000` (AC-01 US-01.2). `search-empty`: ô tìm có chữ "xyz", "Không tìm thấy khách phù hợp." + nút `Xoá tìm kiếm`. `empty`: "Không có khách nào đang nợ" / "Đơn bán nợ sẽ hiện ở đây." (không nút). `error`: "Không tải được công nợ" + `Thử lại`. `loading-more`: danh sách + `.rc-spinner` cuối. `long`: `customers` + `edgeCustomers`.
  - Tương tác (`main.js`): chip đổi lọc; ô tìm lọc bỏ dấu sau 300 ms ("tuan" thấy "Anh Tuấn", AC-02 US-01.2); chạm dòng → `screen=cn02&state=full` (Tuấn).
  - Web: `.rc-twocol`, cột phải "Chọn một khách để xem công nợ".
- [ ] **Step 6: Verify bằng ảnh** (Task 8 chụp hàng loạt; ở đây chụp tay):

```bash
CH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
"$CH" --headless=new --hide-scrollbars --force-device-scale-factor=1 --virtual-time-budget=1500 --window-size=390,844 --screenshot=/tmp/cn01.png "http://127.0.0.1:8766/index.html?screen=cn01&state=all&device=iphone"
"$CH" --headless=new --hide-scrollbars --force-device-scale-factor=1 --virtual-time-budget=1500 --window-size=390,844 --screenshot=/tmp/cn01-long.png "http://127.0.0.1:8766/index.html?screen=cn01&state=long&device=iphone"
bash tools/check-classes.sh
```
Mở ảnh bằng Read, đối chiếu 5.2: 3 dòng, "Quá hạn 8 ngày" / "Hẹn 25/11" / "Đến hạn hôm nay"; ca `long`: tên cắt `…`, tiền không xuống hàng, badge "Ngừng hoạt động" (Review Focus 1–2). `check-classes.sh` không in gì.
- [ ] **Step 7: Commit** `feat(prototype): CN-01 danh sách khách còn nợ`

---

### Task 4: CN-02

**Files:** Create `app/cn02.js`; Modify `app/main.js`, `styles/receivable.css`, `tests/data.test.mjs`

**Interfaces:** Consumes `data.js` (`tuanAt`, `customers`, `edgeCustomers`), `formatVnd`, `dueLabel`. Produces `renderCn02(state: 'full'|'after-offset'|'block-error'|'paid-off'|'inactive'|'no-history', device, opts?: {toast?: string}): string` (`opts.toast` dùng cho `cn03__success`).

- [ ] **Step 1: Cài `renderCn02`** theo 5.3:
  - Appbar "Công nợ khách hàng". Header: `tên · SĐT`, badge `Ngừng hoạt động` khi `isActive:false`, `Còn nợ <số>`, `n đơn · m quá hạn`.
  - Khối `ĐƠN CÒN NỢ (cũ trước)`: mỗi đơn `mã · ngày bán`, `Tổng <số>`, `Còn nợ <số>`, nhãn hạn (`dueLabel`). Rỗng → "Không còn đơn nào nợ".
  - Khối `LỊCH SỬ THU & CẤN TRỪ` (mới nhất trước), một mẫu dòng cho mỗi `kind`:
    - `collection`: `Thu 2.000.000 · Tiền mặt` / `Chuyển khoản <mã>`; `06/11 14:20 · Nguyễn An`; `Vào: DH-002 2.000.000` (nhiều đơn ngăn bằng `, `).
    - `order_payment`: `Thu 500.000 · đơn DH-030` + thời gian.
    - `offset`: `Cấn trừ 500.000 · từ trả hàng đơn DH-001 (phiếu #DT-0001) sang đơn DH-002` + thời gian · người.
    - `refund`: `Hoàn 200.000 · đơn DH-029` + thời gian.
    - Cuối khối: `Xem thêm` (chỉ vẽ, không tải).
  - Thanh dưới: nút `Thu tiền` khi công nợ > 0; hết nợ → header "Không còn nợ", ẩn nút (FR-05).
  - State: `full` = Tuấn `before`; `after-offset` = Tuấn `afterOffset` (`Còn nợ 7.500.000 ₫`, `2 đơn · 1 quá hạn`); `block-error` = Tuấn `before`, khối đơn có dữ liệu, khối lịch sử "Không tải được" + `Thử lại` riêng (FR-06); `paid-off` = Tuấn `paidOff`; `inactive` = Cô Hoa; `no-history` = Chị Lan ("Chưa có lần thu nào").
  - Bấm `Thu tiền` → `main.js` chuyển `screen=cn03&state=empty`.
  - Web: hai cột, cột trái CN-01 có dòng khách đang chọn được tô.
- [ ] **Step 2: Test dữ liệu**: thêm vào `tests/data.test.mjs`: với mỗi state CN-02, Σ `outstandingMinor` các đơn hiện = số `Còn nợ` đầu trang (AC-01 US-01.3) — kiểm qua hàm `cn02Model(state)` (export từ `cn02.js`, thuần, `renderCn02` dùng lại).
- [ ] **Step 3: Verify ảnh** iPhone + web ca `full`, `after-offset`, `paid-off`; đối chiếu 5.3; `after-offset` có dòng cấn trừ 500.000 từ DH-001 sang DH-002 (AC-02 US-01.3) và không còn DH-001 trong đơn nợ (AC-03). `bash tools/check-classes.sh` không in gì.
- [ ] **Step 4: Commit** `feat(prototype): CN-02 công nợ của khách`

---

### Task 5: CN-03

**Files:** Create `app/cn03.js`; Modify `app/main.js`, `styles/receivable.css`

**Interfaces:** Consumes `allocateOldestFirst`, `parseMoneyInput`, `formatVnd`, `tuanAt`, `renderCn02`. Produces `renderCn03(state, device): string` (iPhone: bottom sheet toàn cao trên CN-02; web: `.confirm-dialog` trên hai cột).

- [ ] **Step 1: Cài `renderCn03`** theo 5.4 (khách Tuấn `before`, công nợ 18.000.000):
  - Tiêu đề `Thu tiền` + nút đóng; `Anh Tuấn · Còn nợ 18.000.000 ₫`.
  - Ô `Số tiền` (`inputmode="numeric"`, định dạng nghìn, hậu tố `đ`) + nút `Trả hết` (điền = công nợ).
  - `Phương thức`: segment `Tiền mặt` (mặc định) / `Chuyển khoản`; chuyển khoản hiện ô `Mã giao dịch (Không bắt buộc)`.
  - Khối `SẼ TRỪ VÀO` từ `allocateOldestFirst`: `DH-001   4.000.000  → hết nợ`, `DH-002   6.000.000  → còn 2.000.000`; dòng `Khách còn nợ sau khi thu` + `8.000.000 ₫`.
  - Nút `Quay lại` / `Xác nhận thu`.
  - State:
    - `empty`: ô trống, ẩn khối Sẽ trừ vào, nút `Xác nhận thu` khoá.
    - `valid`: 10.000.000, Tiền mặt.
    - `over`: 18.000.001, lỗi "Số tiền vượt quá tổng còn nợ của khách." dưới ô, ẩn khối Sẽ trừ vào, nút khoá (AC-03).
    - `transfer`: 10.000.000, Chuyển khoản, ô mã giao dịch có `FT2611180001`.
    - `confirm`: sheet "Xác nhận thu tiền?" + "Thu 10.000.000 ₫ Tiền mặt từ Anh Tuấn" + danh sách Sẽ trừ vào + `Quay lại` / `Xác nhận`.
    - `submitting`: như `valid`, nút "Đang ghi nhận...", mọi ô khoá.
    - `submit-error`: như `valid` + "Không ghi nhận được. Thử lại?" + `Thử lại`.
    - `changed`: hộp "Công nợ của khách vừa thay đổi. Hãy tải lại rồi thử lại." + `Tải lại`.
    - `leave-confirm`: như `valid` + hộp "Bỏ khoản thu đang nhập?" (hai nút: chữ tạm, ghi README).
    - `success`: CN-03 đã đóng; vẽ `renderCn02` với Tuấn `afterCollect` + toast "Đã thu 10.000.000 ₫ từ Anh Tuấn" (FR-06).
  - Ô tiền tương tác thật: gõ → `parseMoneyInput` → định dạng nghìn → cập nhật khối Sẽ trừ vào / lỗi / trạng thái nút (Review Focus 6). `?amount=` (thử tay) điền sẵn số và ghi đè số của state.
- [ ] **Step 2: Verify**: ảnh `over` có lỗi, nút khoá; `?amount=18000000` (thử tay) → mọi đơn "→ hết nợ", `Khách còn nợ sau khi thu 0 ₫`; gõ tay `10.000.000đ` → khối Sẽ trừ vào đúng như `valid`. `bash tools/check-classes.sh` không in gì.
- [ ] **Step 3: Commit** `feat(prototype): CN-03 thu tiền theo khách`

---

### Task 6: SG-13 cấn trừ

**Files:** Create `app/sg13.js`; Modify `app/main.js`, `app/data.js`, `styles/receivable.css`

**Interfaces:** Consumes `planReturnSettlement`, `formatVnd`, `dueLabel`, `k7CheckMark`. Produces `renderSg13(state, device): string`.

- [ ] **Step 1: Đọc SG-13 Flutter đang có** (không có prototype TH-05): `apps/erp/lib/features/sales/presentation/pages/sales_return_exchange_settlement_page.dart`, `.../widgets/sales_return_exchange_settlement_body.dart`, `.../widgets/sales_return_confirm_settlement_sheet.dart`. Ghi vào README mục "SG-13 nền" thứ tự khối, tiêu đề, nút, phần web của màn hiện có. Prototype **giữ nguyên** bố cục đó và chỉ chèn các dòng mới của TH-06 (giảm nợ, khối cấn trừ, hoàn có điều kiện), để T6-2 chỉ thêm khối chứ không vẽ lại màn.
- [ ] **Step 2: Dữ liệu SG-13** trong `data.js`, `sg13Cases`:
  - Ví dụ 2.3 bước 2 (dùng cho `all-selected`, `one-unchecked`, `none-selected`, `confirm`, `stale`): đơn nguồn DH-001 (đã trả đủ, `sourceOutstanding 0`), trả hàng 500.000, đổi 0 → `entitled 500000`; candidates `DH-002 còn 2.000.000 hẹn 15/11`, `DH-003 còn 6.000.000 hẹn 30/11`.
  - `mixed` (dữ liệu riêng, không thuộc 2.3): Tuấn, đơn nguồn DH-010 tổng 4.000.000 đã thu 3.600.000 (còn 400.000), trả hàng 3.000.000; candidates `[DH-002 2.000.000]` → giảm nợ 400.000, cấn trừ 2.000.000, hoàn 600.000 (`còn_lại` 2.600.000 ≤ đã thu 3.600.000, BR-27).
  - `source-has-debt` (SC-03): đơn nguồn DH-010 tổng 1.000.000 đã thu 400.000, trả hàng 600.000; khách vẫn có DH-002 còn nợ → giảm nợ 600.000, khối cấn trừ **ẩn** (`showOffsetBlock` false).
  - `no-other-debt`: khách chỉ có đơn nguồn đã trả đủ, trả hàng 500.000, `candidates []` → như TH-05: Hoàn 500.000 + phương thức.
- [ ] **Step 3: Cài `renderSg13`** theo 5.5 trên nền Step 1, dùng `planReturnSettlement`:
  - Tiêu đề `Quyết toán đổi/trả`; `Khách được hưởng`; `Chênh lệch −<số> ₫`; `Hàng trả <số> · Hàng đổi <số>`.
  - Thứ tự (FR-01 US-03.1): `Giảm nợ đơn này <số> ₫` + "Phần khách được hưởng được trừ vào nợ của chính đơn này." (khi > 0) → khối `CẤN TRỪ VÀO ĐƠN KHÁC` (khi `showOffsetBlock`) → `Hoàn cho khách <số> ₫` → `Phương thức hoàn` (`Tiền mặt` / `CK`) **chỉ khi hoàn > 0**.
  - Khối cấn trừ: chữ "Trừ vào nợ đơn khác của khách thay vì hoàn tiền."; mỗi đơn trong `offsets` một dòng, cả dòng là `<button role="checkbox">` cao ≥ 44 px: ô chọn, `DH-002 · còn nợ 2.000.000`, nhãn hạn, `Trừ 500.000` canh phải; `amountMinor 0` → `Trừ 0` chữ mờ.
  - Nút dưới `Xác nhận đổi/trả`.
  - State: `all-selected` (mọi đơn chọn); `one-unchecked` (**bỏ DH-002** → DH-003 `Trừ 500.000`, hoàn 0); `none-selected` (hoàn 500.000 + phương thức); `mixed`; `source-has-debt`; `no-other-debt`; `confirm` (`all-selected` + sheet "Xác nhận đổi/trả?" có dòng "Cấn trừ 500.000 vào đơn DH-002", US-03.2 FR-01); `stale` (hộp "Công nợ của khách vừa thay đổi. Hãy tải lại quyết toán." + `Tải lại`, US-03.2 FR-04).
  - Tương tác: bấm dòng → đổi `selectedIds` → gọi lại `planReturnSettlement` → vẽ lại.
- [ ] **Step 4: Verify** ảnh 8 ca iPhone + web: `none-selected` có `Hoàn cho khách 500.000 ₫` và phương thức hoàn; `all-selected` có `Hoàn cho khách 0 ₫`, không phương thức hoàn (AC-01/02 US-03.1); `one-unchecked` DH-003 `Trừ 500.000`; `mixed` đủ ba dòng đúng thứ tự; `source-has-debt` không có khối cấn trừ (AC-03). `bash tools/check-classes.sh` không in gì.
- [ ] **Step 5: Commit** `feat(prototype): SG-13 khối cấn trừ`

---

### Task 7: Màn gom `patches`

**Files:** Create `app/patches.js`; Modify `app/main.js`, `styles/receivable.css`

**Interfaces:** Produces `renderPatches(state: 'sg09'|'sg09b'|'sg09c'|'sg14'|'pt07'|'more-menu', device): string` — mỗi state hai nửa "Trước" / "Sau" (iPhone: trên / dưới; web: trái / phải), phần mới viền `--c45-v2-primary-500` và nhãn `MỚI`.

- [ ] **Step 1: Cài** theo US-03.2 FR-03, US-03.3, US-04.1, 7.3:
  - `sg09`: dòng `Xem công nợ của khách ›` trong khối "Thanh toán & công nợ".
  - `sg09b`: dòng giao dịch `Cấn trừ · sang DH-002` (đơn nguồn) và `Cấn trừ · từ DH-001` (đơn nhận); dòng `Đã cấn trừ`.
  - `sg09c`: hoạt động `Cấn trừ công nợ` và `Ghi nhận thu nợ theo khách`.
  - `sg14`: dòng `Cấn trừ vào DH-002 500.000 ₫` + nút `Xem công nợ của khách`.
  - `pt07`: khối `Công nợ`: `Còn nợ 18.000.000 ₫ · 3 đơn` + `⚠ Quá hạn 8 ngày`; bên cạnh biến thể `Không còn nợ`.
  - `more-menu`: mục `Công nợ phải thu` (phụ đề "Khách đang nợ, quá hạn, thu tiền") ngay dưới `Khách hàng & NCC`; mục `Báo cáo` giữ phụ đề "Doanh thu, tồn kho, công nợ" (FR-04 US-04.1).
  - Phần "Trước" vẽ khung đơn giản (không cần giống pixel), ghi chú `khung minh hoạ, nền Flutter hiện có`.
- [ ] **Step 2: Verify ảnh** 6 ca; chữ đúng nguyên văn mục 4.4–4.5. `bash tools/check-classes.sh` không in gì.
- [ ] **Step 3: Commit** `feat(prototype): patches sửa màn cũ T6-2a`

---

### Task 8: Chụp ảnh đích, README, tự kiểm

**Files:** Create `tools/capture.mjs`, `README.md`

**Interfaces:** Consumes URL `?screen&state&device` và bảng "Danh sách ca". Produces `tools/proto-final/{iphone,web}/<screen>__<state>.png` (38 × 2 = 76 ảnh); `node tools/capture.mjs [filter]` (filter khớp tiền tố tên ca).

- [ ] **Step 1: Viết `tools/capture.mjs`**: danh sách ca đặt hằng đầu file (đúng bảng trên); mỗi ca `spawnSync` Chrome `--headless=new --hide-scrollbars --force-device-scale-factor=1 --virtual-time-budget=1500 --window-size=<390,844|1280,800> --screenshot=<file> <url>`; server mặc định `http://127.0.0.1:8766` (đổi bằng `PROTO_URL`); in `ok/lỗi` từng ca, cuối in `N ca, M lỗi`; exit 1 nếu có ca lỗi / ảnh rỗng (tệp < 2 KB).
- [ ] **Step 2: Chạy** `python3 -m http.server 8766 --bind 127.0.0.1 &` rồi `node tools/capture.mjs`. Expected: `76 ca, 0 lỗi`; `ls tools/proto-final/iphone | wc -l` = 38, `web` = 38.
- [ ] **Step 3: Tự kiểm Review Focus**: mở bằng Read các ảnh `cn01__long` (iPhone), `cn01__overdue` (chỉ Tuấn "Quá hạn 8 ngày · 12.000.000", Trại Hưng Phát không có), `cn02__after-offset`, `cn03__over`, `sg13__none-selected`, `sg13__one-unchecked`, `sg13__mixed`; sửa CSS nếu tràn / sai, chụp lại ca đó (`node tools/capture.mjs cn01`).
- [ ] **Step 4: Viết `README.md`**: cách chạy, `node --test tests/`, `bash tools/check-classes.sh`, `node tools/capture.mjs`; bảng ca + thời điểm dữ liệu; nguồn token / component (Theme 7); ghi chú font; mục "SG-13 nền" (Task 6 Step 1); mục "Chữ tạm" (chữ spec không quy định); ghi `patches` là khung minh hoạ. Chạy `node --test tests/` — Expected: tất cả PASS.
- [ ] **Step 5: Commit** `feat(prototype): T6-2a bộ ảnh đích + README`
- [ ] **Step 6: Dừng.** Báo bạn: đường dẫn prototype, lệnh chạy, thư mục ảnh, danh sách "Chữ tạm" cần chốt; **không** viết plan Flutter T6-2 cho tới khi bạn duyệt ảnh.

---

## Self-review

- **Spec coverage:** CN-01 (US-01.1/01.2, 5.2, EC-02 Ngừng hoạt động) → Task 3; CN-02 (US-01.3, 5.3, mọi loại dòng lịch sử, AC-02/03) → Task 4; CN-03 (US-02.1 FR-01…FR-09, 5.4) → Task 5; SG-13 (US-03.1, US-03.2 FR-01/FR-04, 5.5) → Task 6; sửa SG-09/09b/09c/14, PT-07, menu Thêm (US-03.2 FR-03, US-03.3, US-04.1) → Task 7; BR-30 nhãn hạn + công thức 2.2 → Task 2; 5.6 (⚠ + chữ, ≥ 44 px, tabular) → Global Constraints + Task 3–6; ảnh đích 390/1280 → Task 8.
- **Chưa làm có chủ ý:** Flutter, nối RPC, `/impeccable audit` (thuộc T6-2 sau khi duyệt ảnh); phiếu bán hàng dòng "Cấn trừ <số>" (US-03.3 FR-04, không có màn trong app để vẽ).
- **Nhất quán chữ ký:** `allocateOldestFirst`, `planReturnSettlement`, `dueLabel`, `customerDueLabel`, `overdueAmountMinor`, `formatVnd`, `parseMoneyInput`, `tuanAt`, `summaryOf`, `render<Screen>(state, device)` dùng cùng tên ở Task 2–8.
- **Nhất quán dữ liệu:** mỗi state gắn một thời điểm (`before` / `afterCollect` / `afterOffset` / `paidOff`); test Task 3 kiểm tổng từng thời điểm khớp ví dụ 2.3.
