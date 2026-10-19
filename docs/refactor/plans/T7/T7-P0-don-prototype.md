# T7-P0 — Dọn prototype Theme 7: bỏ lớp vá, sửa trực tiếp vào mã nguồn

> Theme: Theme 7 Inventory · Trạng thái: Plan 📝 | Làm 🔄 (cấu trúc + golden; tách finer BJ còn lại) | Review ⬜
> Thuộc [PLAN.md](../../PLAN.md) mục "Theme 7", làm **trước khi tiếp tục** [T7-P](T7-P-thiet-ke-lai-luong.md). Ước lượng: **~5–6 ngày, 4 PR**. Người làm: bạn; review: phiên plan/review.

Đường dẫn tính từ `specs/themes/theme-07/03.design/prototype/html/` nếu không ghi khác.

## 1. Mục tiêu

1. Prototype chỉ còn **mã nguồn sạch**: mỗi màn có **một** hàm dựng, mỗi thành phần có **một** bộ CSS, token nằm **một** chỗ. Không còn lớp vá `vNNN-*`.
2. **Hình ảnh và hành vi không đổi** so với trước khi dọn, kiểm bằng bộ ảnh chụp chuẩn (golden). Ngoại lệ duy nhất: Hub Kho cũ v3.8 bị xoá (mục 4.3).
3. Từ sau T7-P0, mọi chỉnh sửa (kể cả các bước T7-P còn lại) **sửa thẳng vào file sở hữu**, không tạo file vá mới.

## 2. Hiện trạng (đo 2026-10-16)

| | Số file | Dung lượng |
|---|---|---|
| CSS được `index.html` nạp | 68 | 641 KB |
| JS được `index.html` nạp | 45 | 1,5 MB (`app.js` 531 KB, `workbench-data.js` 211 KB) |
| CSS / JS **không** được nạp | 18 | 220 KB |
| CHANGELOG cũ (v0.2.4 → v4.6.8) | ~75 | |
| Báo cáo `qa/` cũ (v4.6.5 → v4.6.8) | 15 | |

- **Cách vá hiện tại:** file sau ghi đè hàm dựng của file trước (`renderers['SCR-xxx']=…`), có khi bọc hàm cũ rồi `.replace()` chuỗi HTML. File ghi đè nhiều nhất là `v350-flow-logic-correction.js` (47 lần), `v310-audit-control-cluster.js` (36), `v392-bj02-semantic-hardening.js` (13). Một số hàm toàn cục cũng bị gán lại (`bj02ReviewProductBlocks`, `renderActiveLotEditor`, `lineEditorValid`…).
- **CSS:** cùng một thành phần bị khai báo lại ở nhiều lớp, lớp sau thắng nhờ `!important` hoặc selector dài hơn. Ví dụ dòng key-value emphasis bị ghim ở `bj01-ds-fidelity`, `v251`, `v271`, `v431`, `v440` rồi `v470`.
- **Lớp T7-P vừa thêm:** `v470-color-semantics.*`, `v471-review-distill.*`, `v472-hub-default.js`, `v472-home-candidate.*`. Ba lớp này cũng phải được gộp vào nguồn như các lớp khác.
- File không được nạp: `canonical-finalizer.js`, `canonical-renderer.js`, `ds16-init.js`, `ds16-runtime.js`, `html-ds-alignment.css/.js`, `theme-07-composition.css`, `theme-07-ds-adapter.js`, `v462-warehouse-hub-candidate.css/.js`, `v463-warehouse-hub-candidate.css/.js`, `v464-navigation-contract-alignment.js`, `v465-role-navigation-profiles.css/.js`, `v466-bj-role-simulation.css/.js`, `workbench.css`.

## 3. Cấu trúc đích

```text
html/
  index.html                 harness: chỉ nạp các file dưới đây
  harness/
    workbench.css            sidebar, inspector, state switcher, inspect overlay
    workbench.js             chọn UIF/màn/trạng thái, inspect, traceability
  styles/
    tokens.css               MỘT bộ token, giá trị theo DESIGN.md
    components.css           ds24-*, v-banner, button, badge, list row, sheet, bottom nav…
    screens.css              phần riêng của từng màn, nhóm theo BJ (comment tiêu đề BJ)
  app/
    core.js                  state, routing theo URL, appShell, icon, esc, ds24*/v* helper
    hub.js                   Home Kho (candidate) + 5 workspace + Thiết lập kho
    bj01.js … bj17.js        fixture + hàm dựng + xử lý sự kiện của từng BJ
    cap01.js                 Chính sách tồn & cận hạn
  data/
    workbench-data.js        giữ nguyên nội dung (đổi đường dẫn)
    workbench-data.json
  tools/
    golden.mjs               chụp / so sánh bộ ảnh chuẩn (mục 4.1)
  CHANGELOG.md               một file, bắt đầu v5.0.0
  README.md, DS-CONFORMANCE.md, manifest.json, prototype.manifest.json
```

Quy ước:

- **Một màn = một hàm dựng** trong file BJ sở hữu nó. Màn dùng chung (036 / 037 / 041 của BJ-07 / 09 / 10; 078–083 của BJ-16 / 17) nằm ở file BJ dựng đầu tiên (`bj07.js`, `bj16.js`), file còn lại gọi lại hàm đó.
- **Token giữ tên `--vet45-v2-*`** để không phải đổi hàng nghìn chỗ dùng. **Giá trị theo DESIGN.md** (bảng token ở đầu `v470-color-semantics.css`). Bỏ bộ `--v-*`, `--figma-*`, `--primary-*`, `--yellow-*`… sau khi thay chỗ dùng bằng `--vet45-v2-*`. `figma-ds.exact.css` không còn là bản chép Figma; ghi lệch này vào `DS-CONFORMANCE.md`.
- Không `!important` trừ khi có lý do ghi ngay cạnh. Không `MutationObserver` để sửa DOM sau khi dựng: logic của `v470` / `v471` / `v472` chuyển thẳng vào hàm dựng.
- Giữ nguyên mọi tham số URL đang dùng: `uif`, `screen`, `state`, `flow`, `mode`, `app`, `hubView`. Bỏ `hub`.
- Giữ thuộc tính `data-ds-component`, `data-figma-node`, `data-ds-prop-*` (inspector cần).

## 4. PR 1 — Công cụ golden, xoá phần không dùng, xoá Hub cũ (~0,5–1 ngày)

### 4.1 `tools/golden.mjs` (tạo)

Script chụp `#device-preview` và lấy `innerText` của `#app-screen` cho mọi tổ hợp **UIF × màn × trạng thái** (555 ca ở v4.7.0; UIF-02 chụp cả `flow=document` và `flow=quick`; thêm Home Kho), rồi so hai bộ chụp với nhau. Chỉ dùng Node ≥ 22 và Chrome có sẵn, không cài thêm gì.

**Đã chạy thử 2026-10-16** trên prototype hiện tại:

- Một lần chụp mất khoảng **13 giây** (bản đầu tiên của plan tải lại trang cho từng ca, mất khoảng 15–20 phút). Nhanh vì: mỗi UIF chỉ tải trang **một lần**, sau đó đổi màn / trạng thái **ngay trong trang** (gán `activeScreenId`, `stateByScreen[...]` rồi gọi `render()`), không chờ cố định, và chạy 4 tab Chrome song song.
- **Ổn định:** ba lần chụp liên tiếp không sửa gì so với nhau đều "Khớp hoàn toàn".
- **Nhạy:** cố ý làm badge rộng thêm 1px → báo 94 ca khác; nút chính về màu xanh cũ → 301 ca; chữ đậm đổi màu rất nhẹ → 398 ca.

**Vì sao không so ảnh tuyệt đối:** hai lần vẽ cùng một màn vẫn lệch khử răng cưa ở mép chữ: dưới khoảng 200 điểm ảnh, mỗi điểm lệch dưới 24 (so tuyệt đối báo nhầm 56 / 555 ca). Script báo khác khi **có điểm lệch > 32** (cạnh bị xê dịch) **hoặc hơn 500 điểm lệch > 4** (một vùng đổi màu). Ba ngưỡng chỉnh được bằng biến môi trường `BIG`, `SMALL`, `AREA`.

**Ràng buộc với PR 3:** script gọi `activeScreenId`, `stateByScreen`, `render()` ở phạm vi toàn cục. Khi tách `app.js` thành `app/core.js`, **giữ ba tên này toàn cục** (khai báo cấp cao nhất trong script thường, không bọc trong module / IIFE), nếu không script không chạy được.

```js
// node golden.mjs capture <dir> [filter]  |  node golden.mjs compare <dirA> <dirB>
import { spawn } from 'node:child_process';
import { mkdirSync, writeFileSync, readFileSync, readdirSync, existsSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { inflateSync } from 'node:zlib';
import path from 'node:path';

const [, , mode, a, b] = process.argv;
const HTML = process.env.PROTO_HTML || path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');
const BASE = process.env.PROTO_URL || 'http://127.0.0.1:8765/index.html';
const WORKERS = Number(process.env.WORKERS || 4);
const sha = (buf) => createHash('sha256').update(buf).digest('hex');

// Minimal PNG decoder (8-bit RGB/RGBA, non-interlaced: what Chrome writes).
function decodePng(buf) {
  let pos = 8, w = 0, h = 0, ct = 0; const idat = [];
  while (pos < buf.length) {
    const len = buf.readUInt32BE(pos), type = buf.toString('ascii', pos + 4, pos + 8), data = buf.subarray(pos + 8, pos + 8 + len);
    if (type === 'IHDR') { w = data.readUInt32BE(0); h = data.readUInt32BE(4); ct = data[9]; }
    if (type === 'IDAT') idat.push(data);
    pos += 12 + len;
  }
  const bpp = ct === 6 ? 4 : 3, stride = w * bpp, raw = inflateSync(Buffer.concat(idat)), out = Buffer.alloc(h * stride);
  for (let y = 0; y < h; y++) {
    const f = raw[y * (stride + 1)], src = y * (stride + 1) + 1, row = y * stride;
    for (let x = 0; x < stride; x++) {
      const left = x >= bpp ? out[row + x - bpp] : 0, up = y ? out[row - stride + x] : 0, ul = y && x >= bpp ? out[row - stride + x - bpp] : 0;
      let v = raw[src + x];
      if (f === 1) v += left; else if (f === 2) v += up; else if (f === 3) v += (left + up) >> 1;
      else if (f === 4) { const p = left + up - ul, pa = Math.abs(p - left), pb = Math.abs(p - up), pc = Math.abs(p - ul); v += pa <= pb && pa <= pc ? left : pb <= pc ? up : ul; }
      out[row + x] = v & 255;
    }
  }
  return { w, h, bpp, px: out };
}
// Anti-aliasing noise between two identical renders: <~200 pixels, each channel off by <24.
// A real change either moves an edge (some pixel off by >BIG) or recolors an area (>AREA pixels off by >SMALL).
const BIG = Number(process.env.BIG || 32), SMALL = Number(process.env.SMALL || 4), AREA = Number(process.env.AREA || 500);
function pixelDiff(fa, fb) {
  const A = decodePng(readFileSync(fa)), B = decodePng(readFileSync(fb));
  if (A.w !== B.w || A.h !== B.h) return { n: Infinity };
  let big = 0, small = 0, x0 = 1e9, y0 = 1e9, x1 = -1, y1 = -1;
  for (let i = 0, p = 0; i < A.px.length; i += A.bpp, p++) {
    const d = Math.max(Math.abs(A.px[i] - B.px[i]), Math.abs(A.px[i + 1] - B.px[i + 1]), Math.abs(A.px[i + 2] - B.px[i + 2]));
    if (d > SMALL) { small++; const x = p % A.w, y = (p / A.w) | 0; x0 = Math.min(x0, x); y0 = Math.min(y0, y); x1 = Math.max(x1, x); y1 = Math.max(y1, y); }
    if (d > BIG) big++;
  }
  const n = big > 0 || small > AREA ? small : 0;
  return { n, box: n ? `${x0},${y0}–${x1},${y1}` : '' };
}

if (mode === 'compare') {
  const diff = [];
  const names = new Set([...readdirSync(a), ...readdirSync(b)].filter((f) => f.endsWith('.png')));
  for (const f of [...names].sort()) {
    const pa = path.join(a, f), pb = path.join(b, f);
    if (!existsSync(pa) || !existsSync(pb)) { diff.push(`${f}: chỉ có ở ${existsSync(pa) ? a : b}`); continue; }
    if (sha(readFileSync(pa)) !== sha(readFileSync(pb))) { const d = pixelDiff(pa, pb); if (d.n) diff.push(`${f}: ảnh khác ${d.n === Infinity ? '(kích thước)' : d.n + ' điểm ảnh ở ' + d.box}`); }
    if (readFileSync(pa.replace(/\.png$/, '.txt'), 'utf8') !== readFileSync(pb.replace(/\.png$/, '.txt'), 'utf8')) diff.push(`${f}: chữ khác`);
  }
  console.log(diff.length ? diff.join('\n') + `\n${diff.length} khác biệt` : `Khớp hoàn toàn (${names.size} ca)`);
  process.exit(diff.length ? 1 : 0);
}

const filter = b || '';
const dataFile = ['data/workbench-data.json', 'workbench-data.json'].map((f) => path.join(HTML, f)).find(existsSync);
const wb = JSON.parse(readFileSync(dataFile, 'utf8'));
const states = new Map(wb.screens.map((s) => [s.id, s.states || []]));
// One page load per group (UIF + flow); screens/states switch in-page.
const groups = [];
for (const f of wb.flows) for (const fl of f.id === 'UIF-02' ? ['document', 'quick'] : [null]) {
  const cases = [];
  for (const id of f.screens) for (const st of states.get(id) || []) cases.push({ name: `${f.id}_${id}_${st}${fl ? '_' + fl : ''}`, screen: id, state: st });
  groups.push({ url: `?uif=${f.id}&screen=${f.screens[0]}${fl ? '&flow=' + fl : ''}`, cases: cases.filter((c) => c.name.includes(filter)) });
}
groups.push({ url: '?mode=theme&app=inventory', cases: [{ name: 'HUB_home' }].filter((c) => c.name.includes(filter)) });
const todo = groups.filter((g) => g.cases.length);
mkdirSync(a, { recursive: true });

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
async function worker(n, queue, errors) {
  const port = 9400 + n;
  const chrome = spawn('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', ['--headless=new', `--remote-debugging-port=${port}`, `--user-data-dir=${path.join(a, '.chrome' + n)}`, '--hide-scrollbars', '--force-device-scale-factor=1', 'about:blank'], { stdio: 'ignore' });
  let list; for (let i = 0; i < 100 && !list; i++) { try { list = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json(); } catch { await sleep(100); } }
  const ws = new WebSocket(list.find((t) => t.type === 'page').webSocketDebuggerUrl); await new Promise((r) => (ws.onopen = r));
  let id = 0; const pend = new Map(); let loaded = null;
  ws.onmessage = (e) => { const m = JSON.parse(e.data); if (m.id && pend.has(m.id)) { pend.get(m.id)(m); pend.delete(m.id); } if (m.method === 'Page.loadEventFired' && loaded) loaded(); if (m.method === 'Runtime.exceptionThrown') errors.push(m.params.exceptionDetails.exception?.description?.slice(0, 200)); };
  const send = (method, params = {}) => new Promise((r) => { const i = ++id; pend.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
  const evalv = async (expression) => (await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true })).result.result?.value;
  await send('Page.enable'); await send('Runtime.enable');
  await send('Emulation.setDeviceMetricsOverride', { width: 1600, height: 1100, deviceScaleFactor: 1, mobile: false });
  await send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] });
  const frames = 'new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r)))';
  let g;
  while ((g = queue.shift())) {
    const p = new Promise((r) => (loaded = r));
    await send('Page.navigate', { url: BASE + g.url }); await p;
    await evalv(`(()=>{const st=document.createElement('style');st.textContent='*,*::before,*::after{animation:none!important;transition:none!important;caret-color:transparent!important}'+${JSON.stringify(process.env.EXTRA_CSS || '')};document.head.append(st)})()`);
    await evalv(`document.fonts.ready.then(()=>${frames})`);
    for (const c of g.cases) {
      if (c.screen) await evalv(`(activeScreenId=${JSON.stringify(c.screen)}, stateByScreen[activeScreenId]=${JSON.stringify(c.state)}, render(), ${frames})`);
      const v = await evalv(`(()=>{const d=document.querySelector('#device-preview').getBoundingClientRect();return {x:d.x,y:d.y,w:d.width,h:d.height,t:document.querySelector('#app-screen').innerText}})()`);
      const shot = await send('Page.captureScreenshot', { format: 'png', clip: { x: v.x, y: v.y, width: v.w, height: v.h, scale: 1 } });
      writeFileSync(path.join(a, c.name + '.png'), Buffer.from(shot.result.data, 'base64'));
      writeFileSync(path.join(a, c.name + '.txt'), v.t);
    }
  }
  ws.close(); chrome.kill();
}
const t0 = Date.now(); const errors = []; const queue = [...todo];
await Promise.all(Array.from({ length: Math.min(WORKERS, todo.length) }, (_, n) => worker(n, queue, errors)));
writeFileSync(path.join(a, '_errors.json'), JSON.stringify(errors, null, 1));
console.log(`Đã chụp ${todo.reduce((s, g) => s + g.cases.length, 0)} ca trong ${((Date.now() - t0) / 1000).toFixed(1)} giây, lỗi JS: ${errors.length}`);
```

Cách dùng (trong thư mục `html/`):

```bash
python3 -m http.server 8765 --bind 127.0.0.1 &      # để chạy suốt khi làm
node tools/golden.mjs capture tools/.golden-base     # ~13 giây
node tools/golden.mjs capture tools/.golden-base2
node tools/golden.mjs compare tools/.golden-base tools/.golden-base2   # phải "Khớp hoàn toàn"
# sau mỗi bước sửa:
node tools/golden.mjs capture tools/.golden-now && node tools/golden.mjs compare tools/.golden-base tools/.golden-now
# chỉ chụp một phần khi đang sửa một BJ (lọc theo tên ca):
node tools/golden.mjs capture tools/.golden-now UIF-02
```

- Thư mục golden **không commit**: thêm `tools/.golden*/` vào `.gitignore` gần nhất.
- Báo "ảnh khác N điểm ảnh ở x0,y0–x1,y1" cho biết vùng bị đổi; mở hai ảnh cùng tên trong hai thư mục để xem.
- `EXTRA_CSS='…'` chèn CSS khi chụp. Chỉ dùng để tự thử xem so sánh có bắt được thay đổi không, không dùng khi chụp golden thật.
- **Màn chỉ tới được bằng thao tác** (mở sheet, mở editor lô, nhập số…) không nằm trong golden. Với các màn này, kiểm tay theo danh sách ở mục 7.3.

### 4.2 Xoá phần không dùng

1. Xoá 18 file không được nạp (danh sách ở mục 2). Trước khi xoá, `grep` tên từng file trong toàn repo. Nếu nơi khác có nhắc tới, sửa chỗ nhắc đó ở PR 4.
2. Xoá thư mục `figma-ds-runtime/` nếu `grep` cho thấy `index.html` và các file JS được nạp không dùng tới nó. `figma-ds-runtime-map.js` ở thư mục gốc thì vẫn đang được nạp, nên giữ đến PR 3.
3. Xoá ~75 file `CHANGELOG-*.md` và toàn bộ `qa/`. Lịch sử vẫn nằm trong git. Tạo `CHANGELOG.md` có mục v5.0.0, ghi: T7-P0 dọn prototype, kèm tóm tắt nội dung của `CHANGELOG-v4.7.0.md` (bước colorize, distill, Home candidate).

### 4.3 Xoá Hub Kho cũ v3.8

- Home Kho chỉ còn bản candidate (đã chốt 2026-10-16, xem [T7-P](T7-P-thiet-ke-lai-luong.md)).
- Trong mã Hub (`v464-warehouse-hub-bj02-continuity.js`, cùng phần Hub của `v380`…`v383`, `v370`, `v371`), xoá:
  - nhánh `hubMode === 'current'`;
  - nút chuyển "So sánh Hub Kho" trong inspector;
  - tham số `hub`.
- Xoá `v472-hub-default.js`.
- **Golden sau PR 1:** phải "Khớp hoàn toàn". Script không chụp Hub cũ (`hub=current`), nên việc xoá nó không làm golden khác; kiểm tay rằng mở Kho vẫn ra Home candidate và inspector không còn nút "So sánh Hub Kho".

## 5. PR 2 — Gộp CSS (~1,5–2 ngày)

Làm theo thứ tự. Sau **mỗi** bước, chạy `golden.mjs capture` và `compare` với golden của PR 1; phải ra "Khớp hoàn toàn".

1. **Nối máy móc:** ghép 68 file CSS **đúng thứ tự nạp** thành một file tạm `styles/_all.css`, sửa `index.html` chỉ nạp file này. Golden phải khớp, vì thứ tự cascade không đổi.
2. **Xoá luật không bao giờ áp dụng:**
   - Chạy toàn bộ ca golden với CDP `CSS.startRuleUsageTracking` → `CSS.stopRuleUsageTracking` (mở rộng `golden.mjs` thêm chế độ `coverage`, gom `ruleUsage` của mọi ca).
   - Luật nào `used: false` ở **mọi** ca thì là ứng viên xoá. Trước khi xoá, kiểm xem luật đó có thuộc trạng thái chỉ tới được bằng thao tác không (`:hover`, `:focus`, `.is-open`, sheet, editor). Có thì giữ.
3. **Gộp khai báo trùng của cùng thành phần:**
   - Với mỗi thành phần (`.ds24-key-value-row`, `.ds24-list-row`, `.v-banner`, `.button`, `.status-badge`, `.ds24-badge`, `.bj02-*`, `.t462-*`…), gom mọi khai báo về **một** khối.
   - Giữ giá trị đang thắng (xem Computed trong DevTools hoặc giá trị ở lớp cuối), bỏ `!important` và selector kiểu `body[data-active-uif=…]` khi không còn đối thủ.
   - Làm từng thành phần, chụp golden sau mỗi thành phần.
4. **Token:**
   - Tạo `styles/tokens.css` từ `figma-ds.exact.css`, `tokens.generated.css`, `:root` của `styles.css` và khối token ở đầu `v470-color-semantics.css`. Giá trị theo DESIGN.md.
   - Thay chỗ dùng `--v-*`, `--figma-*`, `--primary-*`, `--blue-*`, `--yellow-*`, `--red-*`, `--neutral-*` bằng `--vet45-v2-*` tương ứng, rồi xoá các bí danh này.
   - Bỏ giá trị dự phòng trong `var(--x, #hex)`.
5. **Tách file** `_all.css` thành `tokens.css`, `components.css`, `screens.css` (theo cấu trúc mục 3) và `harness/workbench.css` (phần `.review-*`, `.sidebar-*`, `.inspector-*`, `.inspect-*`, `.state-*`, `.screen-nav*`).

Xong PR 2 thì không còn file `vNNN-*.css`, `bj01-ds-fidelity.css`, `bj02-ds-fidelity.css`, `figma-ds.exact.css`, `figma-ds.styles.exact.css`, `tokens.generated.css`, `styles.css`.

## 6. PR 3 — Gộp JS theo BJ (~2–2,5 ngày)

Golden phải khớp sau mỗi BJ.

1. **Lập bảng "màn → hàm dựng cuối cùng":**
   - Mở prototype, chạy trong console: `Object.entries(renderers).map(([k,f])=>[k,f.toString().slice(0,80)])`. Tìm từng hàm trong mã để biết hàm thắng nằm ở file nào.
   - Với hàm bọc kiểu `const base=renderers[X]; renderers[X]=s=>base(s).replace(…)`, ghi rõ chuỗi bị thay. Khi gộp, sửa thẳng chuỗi đó trong hàm gốc.
2. **`app/core.js`:** chuyển từ `app.js` các phần dùng chung: biến trạng thái, đọc URL, `renderAppScreen`, `appShell`, `icon`, `esc`, `escapeAttribute`, `ds24*`, `vBanner`, `vBadge`, `primaryFooter`… Hàm toàn cục nào bị gán lại ở lớp sau (`bj02ReviewProductBlocks`, `renderActiveLotEditor`, `lineEditorValid`, …) thì lấy **bản cuối**.
3. **Mỗi BJ một file** `app/bjNN.js`: gồm fixture, hàm dựng **cuối cùng** của từng màn, và xử lý sự kiện của BJ đó. Làm theo thứ tự 02 → 01 → 03 → 04/05 → 06 → 07/09/10 → 08 → 11 → 12 → 13/14 → 15 → 16/17 → CAP-01 → hub, mỗi BJ một commit.
4. **Gộp lớp T7-P vào hàm dựng:**
   - `v470-color-semantics.js`:
     - tách badge tình trạng tồn → đưa vào nơi dựng list row của BJ-01 (SCR-001, lô ở SCR-003), truyền `trailing: ds24Badge(...)`;
     - tone "rủi ro" và "Chênh lệch" → thêm class lúc dựng key-value row (SCR-011, SCR-045);
     - dấu `−` → định dạng số lúc dựng.
   - `v471-review-distill.js`: danh sách lô → đưa thẳng vào `bj02ReviewProductBlocks` và `bj02ReviewSubtitle`.
   - `v472-home-candidate.js`: chevron "Cần chú ý" → đưa vào `attentionRow`; thanh dưới "Sản phẩm" → sửa mảng tab trong `hub.js`.
   - Sau bước này không còn `MutationObserver` sửa DOM.
5. **Sự kiện:** lớp vá đang gắn nhiều `document.addEventListener('click', …)` có `stopImmediatePropagation()` để chặn handler của lớp trước. Gom về **một** handler mỗi BJ theo `data-*`, rồi xoá handler bị chặn.
6. **Xoá mã chết:**
   - Chạy golden với CDP `Profiler.startPreciseCoverage({callCount:true, detailed:true})` → `Profiler.takePreciseCoverage`.
   - Hàm có `count: 0` ở mọi ca là ứng viên xoá.
   - Trước khi xoá, kiểm xem hàm có phải handler sự kiện hoặc nhánh chỉ tới được bằng thao tác không (mục 7.3). Có thì giữ.
7. `harness/workbench.js`: phần sidebar, chọn trạng thái, traceability, inspect và cập nhật `.review-badge`, tách từ `app.js` và các lớp `v3xx` / `v4xx`.

Xong PR 3 thì `index.html` chỉ nạp `data/workbench-data.js`, `app/core.js`, `app/bj*.js`, `app/cap01.js`, `app/hub.js`, `harness/workbench.js`, và không còn file `vNNN-*.js`.

## 7. PR 4 — Tài liệu và tham chiếu (~0,5 ngày)

1. Cập nhật `README.md`, `DS-CONFORMANCE.md`, `manifest.json`, `prototype.manifest.json` theo cấu trúc mới. `manifest.json`: `version` → `5.0.0`, bỏ các mục trỏ tới file đã xoá.
2. `grep -rn` tên các file đã xoá trong `specs/themes/theme-07` và `docs/`, gồm:
   - `03.design/prototype/README.md`;
   - `09.generated/registries/artifact-registry.*`;
   - `09.generated/indexes/artifact-index.md`, `package-checksums.sha256`;
   - `runtime-state-registry-v4.6.8.json`;
   - `README.md` của theme.

   Sửa đường dẫn. Riêng `package-checksums.sha256` thì tạo lại bằng `shasum -a 256`.
3. Plan Flutter có trích "fixture trong `app.js` của prototype" ([PLAN.md](../../PLAN.md) mục Theme 7, các plan T7-0…T7-1): đổi thành `app/bjNN.js`.
4. Trong [T7-P](T7-P-thiet-ke-lai-luong.md), sửa câu "lớp `v47x-*`" thành "sửa trực tiếp file BJ / `components.css`".

### 7.3 Kiểm tay (màn chỉ tới được bằng thao tác)

Mở prototype đã dọn và bản trước khi dọn (`git stash` hoặc worktree) cạnh nhau, đi từng luồng sau và so:

- **BJ-02 nhập nhanh trọn luồng:** SCR-006 → 008 (chọn NCC trong sheet, chọn tệp) → 009 → 084 (thêm lô, bàn phím số, HSD theo tháng / năm) → 010 (mở chi tiết dòng, "Sửa") → gửi duyệt → Home "Nhận hàng chờ phê duyệt" → SCR-011 (xem chứng từ, Từ chối có lý do, Duyệt) → 012.
- **BJ-02 nhận theo chứng từ:** "Đổi chứng từ" (sheet xác nhận).
- **Các luồng khác:**
  - BJ-08: đếm mù → đếm lại → duyệt.
  - BJ-14: chọn phương pháp → tính → công bố (sheet).
  - BJ-07: chọn hàng → bàn giao.
  - Hub: tìm kiếm Enter; 4 nút nhanh; 4 dòng "Cần chú ý"; 5 workspace; Thiết lập kho.
- **Inspector:**
  - đổi UIF trong sidebar;
  - đổi trạng thái;
  - bật Inspect rồi rê lên một thành phần;
  - mục "Design Contract" hiện đúng.

## 8. Kiểm tra (mỗi PR)

| Kiểm | Cách | Đạt khi |
|---|---|---|
| Golden | `node tools/golden.mjs capture tools/.golden-prN` rồi `compare` với golden PR trước (~13 giây mỗi lần chụp) | "Khớp hoàn toàn" |
| Lỗi JS | `_errors.json` trong thư mục golden | rỗng |
| Không còn lớp vá | `ls | grep -E '^v[0-9]+-'` | PR 2: không còn `.css`; PR 3: không còn file nào |
| Thao tác | mục 7.3 | không khác bản trước |
| Ca golden không ổn định | ghi tại đây khi chạy lần đầu | |

## 9. Rủi ro / lưu ý

- **Cascade CSS:** gộp sai thứ tự sẽ đổi giao diện ở chỗ không ngờ. Vì vậy bước 5.1 nối máy móc trước, và chụp golden sau từng thành phần, không gộp nhiều thành phần rồi mới chụp.
- **Hàm bị gán lại:** một số lớp gán lại hàm toàn cục mà file trước vẫn gọi theo tên. Khi chuyển sang `core.js`, chỉ giữ **một** định nghĩa: bản cuối.
- **Thứ tự nạp `v472-hub-default.js` trước `v464`:** file này bị xoá ở PR 1 cùng với tham số `hub`, nên không còn phụ thuộc thứ tự.
- **Golden không phủ thao tác:** đó là lý do có mục 7.3. Đừng bỏ qua.
- Không đổi thiết kế trong T7-P0. Thấy lỗi giao diện thì ghi vào mục 10 để làm ở T7-P, **không sửa lẫn vào PR dọn**, vì golden sẽ khác và không còn phân biệt được lỗi dọn với sửa có chủ đích.

## 10. Ghi chú khi làm

- **2026-10-16 — PR1:** `tools/golden.mjs` theo plan (~13–16s, 4 worker, so pixel có ngưỡng). Baseline 555 ca khớp hai lần chụp. Xoá 18 file không nạp, `figma-ds-runtime/`, `CHANGELOG-*`, `qa/`, `v472-hub-default.js`; Hub chỉ còn candidate (bỏ `hub`). Golden sau PR1 khớp base.
- **PR2:** Nối 68 CSS → tách `styles/{tokens,components,screens}.css` + stub `harness/workbench.css`. Chưa làm coverage unused-rules / gộp trùng từng thành phần / thay hết alias token (để sau, golden đã khớp sau split).
- **PR3:** Nối toàn bộ JS đúng thứ tự nạp vào `app/core.js`; `app/bj*.js` / `hub.js` / `cap01.js` / `harness/workbench.js` là stub sở hữu. Chưa tách finer từng BJ hay gộp MutationObserver `v470`–`v472` vào hàm dựng. Capture đầu sau PR3 khớp base (1 ca AA lẻ); một số lần captcha sau lệch 12 ca toggle CAP-01/UIF-08 (~38–76 điểm) — ghi là **không ổn định**, không sửa UI.
- **PR4:** README / manifest 5.0.0 / DS-CONFORMANCE / PLAN + plan T7 trỏ `app/core.js` / `bjNN.js`; checksum theme-07 tạo lại.

## 11. Review

### 2026-10-16 — review PR 1–4 (chưa commit)

**Kết luận:** PR 1 đạt. PR 4 đạt phần lớn. **PR 2 và PR 3 mới làm bước nối máy móc** (5.1 và bản tương tự cho JS), chưa làm phần gộp thật (5.2–5.5, 6.1–6.7). Ngoài ra PR 3 gây **12 ca golden lệch thật**. T7-P0 chưa xong: Làm 🔄.

**Đã kiểm, đạt:**

- Golden PR 1 và PR 2 (`.golden-pr1`, `.golden-pr2-concat`, `.golden-pr2-split`) khớp hoàn toàn `.golden-base`. `.golden-base` cũng khớp bộ ảnh phiên review chụp độc lập trước khi dọn.
- 0 lỗi JS trên 555 ca.
- Hub: mở Kho ra Home candidate; không còn nút "So sánh Hub Kho"; 4 dòng "Cần chú ý" có chevron; thanh dưới Trang chủ · Đơn hàng · Sản phẩm · Đối tác · Thêm; bấm "Nhận hàng chờ phê duyệt" mở đúng danh sách.
- SCR-010: lô hiện ngay trên dòng; bấm dòng mở sheet chi tiết. Inspector: đổi UIF sang UIF-14 thì màn và danh sách trạng thái đổi theo.
- 18 file không nạp, `figma-ds-runtime/`, `qa/`, CHANGELOG cũ đã xoá; `CHANGELOG.md` v5.0.0, `manifest.json` 5.0.0; `tools/.golden*/` được git bỏ qua.

**Cần sửa:**

| # | Mức | Vấn đề | Việc cần làm |
|---|---|---|---|
| R1 | Chặn | PR 2 / PR 3 chưa đạt mục tiêu 1 của plan: `app/core.js` (1,3 MB) là 43 file JS cũ nối lại, còn nguyên tên lớp (`/* ===== v350-flow-logic-correction.js ===== */`…); vẫn 26 lần gán lại `renderers['SCR-…']`, 143 `stopImmediatePropagation`, 4 `MutationObserver`. `styles/screens.css` là 64 file CSS nối lại, toàn bộ CSS còn 4 120 `!important`; `tokens.css` còn 38 khai báo bí danh `--v-*` / `--figma-*`. `app/bjNN.js`, `hub.js`, `cap01.js`, `harness/*` chỉ là một dòng chú thích. Hệ quả: T7-P **chưa thể "sửa thẳng vào file sở hữu"**, vì một màn vẫn được định nghĩa nhiều lần trong `core.js`. | Làm tiếp 5.2–5.5 và 6.1–6.7. Có thể làm **dần theo BJ**: trước khi T7-P chỉnh BJ nào thì tách BJ đó sang `app/bjNN.js` (chỉ giữ hàm dựng cuối, xoá bản bị đè, gộp `v470`–`v472` của BJ đó), kiểm bằng `golden.mjs capture … UIF-NN` |
| R2 | Lỗi | 12 ca lệch golden từ PR 3, **ổn định, không phải nhiễu**: CAP-01 SCR-062 (4 trạng thái), SCR-063 (4), UIF-08 SCR-043 (4). Vùng lệch 12×6 điểm ảnh ở x 380–391: mũi tên của `<select class="ds24-field__control">` bị xê dịch. Chụp lại 3 lần (cả `WORKERS=1`) lần nào cũng lệch đúng 12 ca này, trong khi `.golden-pr2-split` khớp base. Ghi chú mục 10 ("không ổn định") là sai. | Tìm nguyên nhân giữa `.golden-pr2-split` và `.golden-pr3`: nhiều khả năng một đoạn JS chèn `<style>` hoặc style inline cho ô chọn và việc nối file đã đổi thứ tự. Sửa đến khi `compare tools/.golden-base …` khớp |
| R3 | Nhỏ | Mã dựng Hub cũ v3.8 ("Việc của bạn", phần `v380`–`v383` trong `core.js`) vẫn còn, dù không còn đường vào | Xoá theo 4.3 |
| R4 | Nhỏ | Tham chiếu cũ: `specs/themes/theme-07/README.md:132` và `03.design/prototype/README.md:61` vẫn ghi "lớp cuối là `v460-semantic-ux.css/js`"; `09.generated/registries/artifact-registry.csv/.json` vẫn liệt kê `CHANGELOG-v4.*` và file `v*` đã xoá | Sửa hai README; cập nhật registry (checksum đã tạo lại, registry thì chưa) |
| R5 | Nhỏ | `workbench-data.json` ở thư mục gốc trùng hệt `data/workbench-data.json` | Xoá bản ở gốc, sửa chỗ còn đọc nó |
| R6 | Dọn | `tools/.golden*` chiếm 1,5 GB (`.golden-pr2-concat` 657 MB); `.golden-pr2-test`, `.golden-pr3c` rỗng | Xoá các bộ trung gian, giữ `.golden-base` |
| R7 | Ghi chú | Công cụ golden thỉnh thoảng báo nhầm 1 ca (vd. `UIF-02_SCR-013_STALE_quick`, 28 điểm ảnh rải khắp màn) vì luật "có điểm lệch > 32" quá nhạy với nhiễu lẻ | Nếu gặp lại: đổi điều kiện thành "có từ 4 điểm lệch > 32" |

### 2026-10-16 — xử lý review (phiên review sửa trực tiếp theo yêu cầu)

| # | Kết quả |
|---|---|
| R1 | **Chốt hướng:** khung chung sạch ngay; từng BJ viết lại vào `app/bjNN.js` khi T7-P làm BJ đó (tránh viết hai lần). Đã làm phần khung: `renderAppScreen` / `renderInspector` / `renderFlowSelector` / `renderNavigation` / `syncReviewUrl` / `previousScreen` mỗi hàm một định nghĩa (điều phối trong `core.js`); Hub + chế độ theme viết lại trong `app/hub.js` (`ThemeApp`), xoá v370, v371, v380–v383, v464, v472 và phần Hub của v381 / v390 / v393 / v396 + 77 luật CSS Hub cũ; một bộ token `--vet45-v2-*` (thay 1 365 chỗ dùng, bỏ 344 dự phòng, 5 khối `:root` → 1). `app/bjNN.js` ghi màn của BJ và các lớp legacy đang định nghĩa chúng. Còn lại cho T7-P theo BJ: 46 màn định nghĩa nhiều lần, wrapper `navigate` (v350 / v430 / v460 / v461), bước sửa sau dựng bọc `renderFlowScreen`, `v470` / `v471`, gộp CSS từng thành phần (`!important`). |
| R2 | **Kết luận review sai:** 12 ca lệch không do PR 3 mà do mũi tên `<select>` gốc của trình duyệt (hệ điều hành vẽ, đổi theo trạng thái máy); cùng mã lúc lệch lúc khớp. Ghi chú "không ổn định" ở mục 10 là đúng. Sửa công cụ: ẩn mũi tên `<select>` khi chụp. |
| R3 | Xong cùng R1 (mã + CSS Hub cũ đã xoá). |
| R4 | Hai README đã sửa; `artifact-registry.csv/.json` (bỏ 211 dòng file đã xoá, thêm 30), `artifact-index.md`, `package-checksums.sha256` đã đồng bộ. |
| R5 | Đã xoá `workbench-data.json` ở gốc. |
| R6 | Đã xoá bộ golden trung gian; công cụ tự xoá profile Chrome sau khi chụp. |
| R7 | Thêm `MINBIG` (cần ≥ 4 điểm lệch > 32). |

**Golden sau khi sửa:** 683 ca (thêm 128 bước kịch bản thao tác Hub; chữ gồm inspector + URL). So với mốc trước khi viết lại Hub: chỉ khác ở các ca đã sửa có chủ đích (phiếu chờ duyệt → SCR-011 đúng dữ liệu + URL, "Về Kho" về Hub sạch) và 52 ca chỉ khác dòng URL (không còn `mode=bj` thừa). Sau khi gom token và xoá CSS Hub cũ: khớp hoàn toàn. Bộ bấm thử (mọi nút / ô nhập, 2 lớp, mọi ca): 0 lỗi JS.

**Phát hiện thêm:** PR 2 dồn khối token `v470` vào `tokens.css` (nạp trước) nên `:root` cũ trong `components.css` đè lại `--primary-500` / `--blue-500` / `--yellow-500` / `--red-500` về màu cũ; đã sửa khi gom token. 3 khai báo dùng biến không tồn tại đã trỏ token đúng.

