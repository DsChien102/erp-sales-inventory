#!/usr/bin/env node
// node golden.mjs capture <dir> [filter]  |  node golden.mjs compare <dirA> <dirB>
import { spawn } from 'node:child_process';
import { mkdirSync, writeFileSync, readFileSync, readdirSync, existsSync, rmSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { inflateSync } from 'node:zlib';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const [, , mode, a, b] = process.argv;
const HTML = process.env.PROTO_HTML || path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
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
// A real change either moves an edge (>=MINBIG pixels off by >BIG; a lone noisy pixel does not count) or recolors an area (>AREA pixels off by >SMALL).
const BIG = Number(process.env.BIG || 32), SMALL = Number(process.env.SMALL || 4), AREA = Number(process.env.AREA || 500), MINBIG = Number(process.env.MINBIG || 4);
function pixelDiff(fa, fb) {
  const A = decodePng(readFileSync(fa)), B = decodePng(readFileSync(fb));
  if (A.w !== B.w || A.h !== B.h) return { n: Infinity };
  let big = 0, small = 0, x0 = 1e9, y0 = 1e9, x1 = -1, y1 = -1;
  for (let i = 0, p = 0; i < A.px.length; i += A.bpp, p++) {
    const d = Math.max(Math.abs(A.px[i] - B.px[i]), Math.abs(A.px[i + 1] - B.px[i + 1]), Math.abs(A.px[i + 2] - B.px[i + 2]));
    if (d > SMALL) { small++; const x = p % A.w, y = (p / A.w) | 0; x0 = Math.min(x0, x); y0 = Math.min(y0, y); x1 = Math.max(x1, x); y1 = Math.max(y1, y); }
    if (d > BIG) big++;
  }
  const n = big >= MINBIG || small > AREA ? small : 0;
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

if (mode !== 'capture') {
  console.error('Dùng: node tools/golden.mjs capture <dir> [filter] | compare <dirA> <dirB>');
  process.exit(2);
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

// Interaction scenarios (theme mode / Hub Kho): one fresh page per scenario, capture after every step.
const click = (sel, i = 0) => `(()=>{const el=document.querySelectorAll(${JSON.stringify(sel)})[${i}];if(el)el.click();return !!el})()`;
const back = click('#app-screen .app-back-button');
const search = (q) => `(()=>{const i=document.querySelector('[data-t462-inventory-search]');if(!i)return false;i.value=${JSON.stringify(q)};i.dispatchEvent(new KeyboardEvent('keydown',{key:'Enter',bubbles:true}));return true})()`;
const typeIn = (sel, value) => `(()=>{const i=document.querySelector(${JSON.stringify(sel)});if(!i)return false;i.value=${JSON.stringify(value)};i.dispatchEvent(new Event('input',{bubbles:true}));return true})()`;
const pick = (sel, value) => `(()=>{const i=document.querySelector(${JSON.stringify(sel)});if(!i)return false;i.value=${JSON.stringify(value)};i.dispatchEvent(new Event('change',{bubbles:true}));return true})()`;
const wait = (ms) => `new Promise((r)=>setTimeout(()=>r(true),${ms}))`;
const T = '?mode=theme&app=';
const SCENARIOS = [
  { name: 'SC_more', url: T + 'more', steps: [['kho', click('[data-theme-app-route="inventory"]')], ['back', back]] },
  { name: 'SC_hub_back', url: T + 'inventory', steps: [['back', back], ['nav-more', click('#app-screen [data-theme-sidebar-route="more"]')]] },
  { name: 'SC_mode', url: T + 'inventory', steps: [['bj', click('button[data-workbench-mode="bj"]')], ['theme', click('button[data-workbench-mode="theme"]')]] },
  { name: 'SC_sidebar', url: T + 'inventory', steps: [['more', click('#screen-navigation [data-theme-sidebar-route="more"]')], ['kho', click('#screen-navigation [data-theme-sidebar-route="inventory"]')]] },
  { name: 'SC_search', url: T + 'inventory', steps: [['enter', search('Amox')], ['back', back]] },
  ...['UIF-02', 'UIF-05', 'UIF-08', 'UIF-01'].map((q) => ({ name: `SC_quick_${q}`, url: T + 'inventory', steps: [['enter', click(`[data-t462-quick="${q}"]`)], ['back', back]] })),
  { name: 'SC_pending', url: T + 'inventory', steps: [['list', click('[data-v464-pending-approvals]')], ['receipt', click('[data-v464-pending-receipt]', 1)], ['exit', click('#app-screen .app-back-button')], ['home', back]] },
  ...['UIF-09', 'UIF-16', 'UIF-17'].map((f) => ({ name: `SC_attention_${f}`, url: T + 'inventory', steps: [['open', click(`[data-t462-attention="${f}"]`)], ['back', back]] })),
  ...Object.entries({ inventory: 3, movement: 4, control: 4, valuation: 3, history: 1, setup: 2 }).flatMap(([ws, n]) => Array.from({ length: n }, (_, i) => ({ name: `SC_ws_${ws}_${i}`, url: T + 'inventory', steps: [['ws', click(`[data-t462-workspace="${ws}"]`)], ['item', click('#app-screen [data-theme-entry-flow]', i)], ['back', back], ['home', back]] }))),
  // BJ-01 Tồn kho (UIF-01)
  { name: 'SC_bj01_list', url: '?uif=UIF-01&screen=SCR-001', steps: [['filter-low', click('[data-bj01-filter="LOW"]')], ['filter-near', click('[data-bj01-filter="NEAR"]')], ['filter-all', click('[data-bj01-filter="ALL"]')], ['search', `(()=>{const i=document.querySelector('[data-bj01-search]');i.value='amox';i.dispatchEvent(new Event('input',{bubbles:true}));return true})()`], ['product', click('[data-bj01-product="INV-AMX"]')]] },
  { name: 'SC_bj01_filter_empty', url: '?uif=UIF-01&screen=SCR-001', steps: [['search', `(()=>{const i=document.querySelector('[data-bj01-search]');i.value='zzz';i.dispatchEvent(new Event('input',{bubbles:true}));return true})()`], ['filter', click('[data-bj01-filter="OUT"]')], ['clear', click('[data-bj01-clear]')]] },
  { name: 'SC_bj01_detail', url: '?uif=UIF-01&screen=SCR-001', steps: [['product', click('[data-bj01-product="INV-NOB"]')], ['lot', click('[data-bj01-lot="DH2509"]')], ['close-lot', click('[data-bj01-close-lot]')], ['provenance', click('[data-bj01-provenance]')], ['handoff', click('[data-bj01-handoff]')]] },
  { name: 'SC_bj01_tylo', url: '?uif=UIF-01&screen=SCR-001', steps: [['product', click('[data-bj01-product="INV-TYLO"]')], ['lot', click('[data-bj01-lot="TY2408"]')], ['close-lot', click('.ds24-overlay[data-bj01-close-lot]')], ['back', click('#app-screen .app-back-button')]] },
  { name: 'SC_bj01_stale', url: '?uif=UIF-01&screen=SCR-001&state=STALE', steps: [['refresh', click('[data-bj01-refresh]')], ['product', click('[data-bj01-product="INV-ENRO"]')]] },
  { name: 'SC_bj01_context', url: '?uif=UIF-01&screen=SCR-003&entry=product-context', steps: [['back', click('#app-screen .app-back-button')]] },
  { name: 'SC_bj01_theme', url: '?mode=theme&app=inventory', steps: [['quick', click('[data-t462-quick="UIF-01"]')], ['product', click('[data-bj01-product="INV-OXY"]')], ['back', click('#app-screen .app-back-button')], ['back-hub', click('#app-screen .app-back-button')]] },
  { name: 'SC_pending_review_to_hub', url: '?mode=theme&app=flow&uif=UIF-02&screen=SCR-010&state=PENDING_APPROVAL', steps: [['to-hub', click('[data-v464-action="to-warehouse"]')]] },
  // BJ-04 Giữ hàng (UIF-04) · BJ-05 Lấy hàng & bàn giao (UIF-05) — T7-P A1
  { name: 'SC_bj04', url: '?uif=UIF-04&screen=SCR-021', steps: [['back', click('#app-screen .app-back-button')]] },
  { name: 'SC_bj05_list', url: '?uif=UIF-05&screen=SCR-025', steps: [['filter-waiting', click('[data-io05-filter="WAITING"]')], ['filter-all', click('[data-io05-filter="ALL"]')], ['search', typeIn('[data-io05-search]', 'Minh')], ['clear-search', typeIn('[data-io05-search]', '')], ['order', click('[data-io05-order="SO-260827-21"]')]] },
  { name: 'SC_bj05_waiting', url: '?uif=UIF-05&screen=SCR-025', steps: [['filter-waiting', click('[data-io05-filter="WAITING"]')], ['waiting-order', click('[data-io05-order="SO-260827-24"]')]] },
  { name: 'SC_bj05_pick', url: '?uif=UIF-05&screen=SCR-025', steps: [['order', click('[data-io05-order="SO-260827-21"]')], ['line', click('[data-io05-line]')], ['allocation', click('[data-io05-pick-allocation="AL-21-02"]')], ['draft', typeIn('[data-io05-pick-draft]', '10')], ['update', click('[data-io05-action="update-pick-allocation"]')], ['save', click('[data-io05-action="save-pick"]')]] },
  { name: 'SC_bj05_override', url: '?uif=UIF-05&screen=SCR-025', steps: [['order', click('[data-io05-order="SO-260827-21"]')], ['line', click('[data-io05-line]')], ['allocation', click('[data-io05-pick-allocation="AL-21-01"]')], ['open-override', click('[data-io05-open-override]')], ['select-lot', click('[data-io05-select-lot="DH2509"]')], ['reason', typeIn('[data-io05-override-reason]', 'Lô gần hạn hơn')], ['confirm', click('[data-io05-action="confirm-lot-override"]')]] },
  { name: 'SC_bj05_handover', url: '?uif=UIF-05&screen=SCR-025', steps: [['order', click('[data-io05-order="SO-260827-21"]')], ['review', click('[data-io05-action="review-handover"]')], ['confirm', click('[data-io05-action="confirm-handover"]')], ['continue', click('[data-io05-action="continue-remaining"]')]] },
  { name: 'SC_bj05_unknown', url: '?uif=UIF-05&screen=SCR-029&state=UNKNOWN', steps: [['handoff', click('[data-v350-action="handoff-unknown"]')]] },
  // BJ-06 Hàng khách trả (UIF-06) — T7-P A2
  ...(() => {
    const U = '?uif=UIF-06&screen=';
    return [
      { name: 'SC_bj06_list', url: U + 'SCR-030', steps: [['filter-actionable', click('[data-io06-filter="ACTIONABLE"]')], ['filter-waiting', click('[data-io06-filter="WAITING"]')], ['filter-all', click('[data-io06-filter="ALL"]')], ['search', typeIn('[data-io06-search]', 'Nam Việt')], ['clear-search', typeIn('[data-io06-search]', '')]] },
      { name: 'SC_bj06_line', url: U + 'SCR-030', steps: [['request', click('[data-io06-request="RET-260827-03"]')], ['line', click('[data-io06-line="RET-L1A"]')], ['qty-over', typeIn('[data-io06-qty]', '5')], ['qty-ok', typeIn('[data-io06-qty]', '2')], ['expected-lot', click('[data-io06-select-actual-lot]')], ['save', click('[data-io06-action="save-return-line"]')], ['back', back]] },
      { name: 'SC_bj06_other_lot', url: U + 'SCR-030', steps: [['request', click('[data-io06-request="RET-260827-03"]')], ['line', click('[data-io06-line="RET-L1A"]')], ['other-lot', click('[data-io06-select-other-lot]')], ['lot-code', typeIn('[data-io06-actual-lot]', 'DH2509')], ['reason-other', click('[data-io06-reason="OTHER"]')], ['reason-diff', click('[data-io06-reason="RETURNED_DIFFERENT_LOT"]')], ['back-expected', click('[data-io06-select-actual-lot]')], ['back', back]] },
      { name: 'SC_bj06_receipt', url: U + 'SCR-030', steps: [['request', click('[data-io06-request="RET-260827-03"]')], ['line-a', click('[data-io06-line="RET-L1A"]')], ['qty-a', typeIn('[data-io06-qty]', '1')], ['lot-a', click('[data-io06-select-actual-lot]')], ['save-a', click('[data-io06-action="save-return-line"]')], ['line-b', click('[data-io06-line="RET-L1B"]')], ['qty-b', typeIn('[data-io06-qty]', '1')], ['lot-b', click('[data-io06-select-actual-lot]')], ['save-b', click('[data-io06-action="save-return-line"]')], ['line-2', click('[data-io06-line="RET-L2"]')], ['qty-2', typeIn('[data-io06-qty]', '1')], ['lot-2', click('[data-io06-select-actual-lot]')], ['save-2', click('[data-io06-action="save-return-line"]')], ['line-3', click('[data-io06-line="RET-L3"]')], ['qty-3', typeIn('[data-io06-qty]', '1')], ['save-3', click('[data-io06-action="save-return-line"]')], ['commit', click('[data-io06-action="commit-receipt"]')], ['classify', click('[data-io06-action="open-classification"]')]] },
      { name: 'SC_bj06_classify', url: U + 'SCR-030', steps: [['request', click('[data-io06-request="RET-260827-05"]')], ['line-0', click('[data-io06-class-line]')], ['cancel', click('[data-io06-action="cancel-classification-item"]')], ['line-1', click('[data-io06-class-line]', 1)], ['sellable', typeIn('[data-io06-class="sellable"]', '5')], ['close', click('[data-io06-action="close-classification-item"]')], ['confirm', click('[data-io06-action="confirm-classification"]')], ['to-queue', click('[data-io06-action="result-to-return-queue"]')]] },
      { name: 'SC_bj06_approve', url: U + 'SCR-034&state=TASK_LIST', steps: [['case', click('[data-io06-approval-case="EX-06-001"]')], ['approve', click('[data-io06-action="approve-exception"]')], ['exit', click('[data-io06-action="exit-approval-detail"]')]] },
      { name: 'SC_bj06_reject', url: U + 'SCR-034&state=TASK_LIST', steps: [['case', click('[data-io06-approval-case="EX-06-001"]')], ['open-reject', click('[data-io06-action="open-reject"]')], ['backdrop', click('[data-io06-reject-backdrop]')], ['open-again', click('[data-io06-action="open-reject"]')], ['reason', typeIn('[data-io06-reject-reason]', 'Ảnh không rõ lô')], ['confirm', click('[data-io06-action="confirm-reject"]')], ['exit-list', click('#app-screen .app-back-button')]] },
      { name: 'SC_bj06_cap_changed', url: U + 'SCR-031&state=RETURN_CAP_CHANGED', steps: [['refresh', click('[data-io06-action="refresh-return-request"]')]] },
      { name: 'SC_bj06_unknown', url: U + 'SCR-035&state=UNKNOWN', steps: [['handoff', click('[data-v350-action="handoff-unknown"]')]] },
      { name: 'SC_bj06_approver_entry', url: '?uif=UIF-06&entry=approver', steps: [['case', click('[data-io06-approval-case]')]] },
    ];
  })(),
  // CAP-01 Chính sách tồn & cận hạn — T7-P A3
  ...(() => {
    const C = '?uif=CAP-01&screen=';
    return [
      { name: 'SC_cap01_stock', url: C + 'SCR-062', steps: [['threshold-high', typeIn('[data-v360-cap-threshold]', '100')], ['review-invalid', click('[data-v360-action="cap-review-stock"]')], ['threshold-ok', typeIn('[data-v360-cap-threshold]', '40')], ['source', pick('[data-v360-cap-stock-source]', 'TENANT_DEFAULT')], ['review', click('[data-v360-action="cap-review-stock"]')], ['edit', click('[data-v360-action="cap-edit"]')], ['review-again', click('[data-v360-action="cap-review-stock"]')], ['save', click('[data-v360-action="cap-save"]')], ['exit', click('[data-v360-action="cap-exit"]')]] },
      { name: 'SC_cap01_expiry', url: C + 'SCR-063', steps: [['days-zero', typeIn('[data-v360-cap-expiry-days]', '0')], ['review-invalid', click('[data-v360-action="cap-review-expiry"]')], ['days-ok', typeIn('[data-v360-cap-expiry-days]', '60')], ['action', pick('[data-v360-cap-expiry-action]', 'BLOCK_SALE')], ['review', click('[data-v360-action="cap-review-expiry"]')], ['back', back], ['review-again', click('[data-v360-action="cap-review-expiry"]')], ['save', click('[data-v360-action="cap-save"]')]] },
      { name: 'SC_cap01_back', url: C + 'SCR-062', steps: [['back', back]] },
      { name: 'SC_cap01_locked', url: C + 'SCR-062&state=LOCKED', steps: [['exit', click('[data-v360-action="cap-exit"]')]] },
      { name: 'SC_cap01_review_invalid', url: C + 'SCR-064&state=VALIDATION_ERROR', steps: [['edit', click('[data-v360-action="cap-edit"]')]] },
      { name: 'SC_cap01_unknown', url: C + 'SCR-065&state=UNKNOWN', steps: [['close', click('.app-actions [data-v360-action]')]] },
    ];
  })(),
  // BJ-02 Nhận hàng mua (UIF-02) — T7-P A4
  ...(() => {
    const R = '?uif=UIF-02&screen=';
    const setEvidence = `(()=>{bj02Header.evidenceRefs=[{id:'EV-T1',name:'phieu-giao.jpg',type:'DELIVERY_DOCUMENT'}];bj02Header.evidence='phieu-giao.jpg';bj02Header.ownershipAssertion=null;renderAppScreen();return true})()`;
    return [
      { name: 'SC_bj02_choose', url: R + 'SCR-006', steps: [['document', click('[data-flow="document"]')], ['back', back], ['quick', click('[data-flow="quick"]')], ['back', back]] },
      { name: 'SC_bj02_documents', url: R + 'SCR-007&flow=document', steps: [['search-empty', typeIn('[data-bj02-document-search]', 'zzz')], ['clear-search', typeIn('[data-bj02-document-search]', '')], ['open', click('[data-bj02-document-id]')], ['back', back]] },
      { name: 'SC_bj02_line', url: R + 'SCR-007&flow=document', steps: [['doc', click('[data-bj02-document-id]')], ['line', click('[data-bj02-line-id]')], ['qty', click('[data-bj02-quantity-target]')], ['key1', click('[data-bj02-numeric-key="1"]')], ['key2', click('[data-bj02-numeric-key="2"]')], ['numeric-save', click('[data-bj02-action="numeric-save"]')], ['save-line', click('[data-bj02-action="save-line"]')], ['line2', click('[data-bj02-line-id]', 1)], ['not-received', click('[data-bj02-action="not-received"]')], ['confirm-not', click('[data-bj02-action="confirm-not-received"]')]] },
      { name: 'SC_bj02_lot', url: R + 'SCR-007&flow=document', steps: [['doc', click('[data-bj02-document-id]')], ['line', click('[data-bj02-line-id]')], ['add-lot', click('[data-bj02-action="add-editor-lot"]')], ['lot-code', typeIn('[data-bj02-lot-field="code"]', 'DH2601')], ['precision', pick('[data-v392-lot-precision="expiryPrecision"]', 'MONTH')], ['show-mfg', click('[data-bj02-action="show-manufacture-date"]')], ['toggle-lot', click('[data-bj02-action="toggle-lot"]')], ['back', back]] },
      { name: 'SC_bj02_quick', url: R + 'SCR-008&flow=quick', steps: [['open-supplier', click('[data-bj02-open-supplier-sheet]')], ['backdrop', click('[data-bj02-supplier-backdrop]')], ['open-again', click('[data-bj02-open-supplier-sheet]')], ['pick-supplier', click('[data-bj02-supplier-option]')], ['evidence', setEvidence], ['continue', click('[data-v392-quick-continue]')], ['back', back], ['open-supplier2', click('[data-bj02-open-supplier-sheet]')], ['pick-other', click('[data-bj02-supplier-option]', 1)]] },
      { name: 'SC_bj02_review', url: R + 'SCR-010', steps: [['detail', click('[data-bj02-review-line]')], ['close', click('[data-bj02-review-close]')], ['change-src', click('[data-v392-change-source]')], ['cancel-src', click('[data-v392-cancel-source-change]')], ['change-again', click('[data-v392-change-source]')], ['confirm-src', click('[data-v392-confirm-source-change]')]] },
      { name: 'SC_bj02_submit', url: R + 'SCR-010', steps: [['submit', click('[data-action="submit"]')]] },
      { name: 'SC_bj02_approve', url: R + 'SCR-011', steps: [['open-ev', click('[data-v392-open-evidence]')], ['preview', click('[data-v392-preview-file]')], ['close-ev', click('[data-v392-close-evidence]')], ['open-reject', click('[data-action="open-reject"]')], ['close-reject', click('[data-action="close-reject"]')], ['open-reject2', click('[data-action="open-reject"]')], ['reason', typeIn('[data-reject-reason]', 'Sai số lượng')], ['confirm-reject', click('[data-action="confirm-reject"]')]] },
      { name: 'SC_bj02_approve_ok', url: R + 'SCR-011', steps: [['approve', click('[data-action="approve"]')]] },
      { name: 'SC_bj02_result', url: R + 'SCR-012&state=COMPLETED', steps: [['exit', click('[data-action="exit-flow"]')]] },
      { name: 'SC_bj02_unknown', url: R + 'SCR-012&state=UNKNOWN', steps: [['verify', click('[data-v350-action="bj02-verify-unknown"]')], ['handoff', click('[data-v350-action="bj02-handoff-unknown"]')]] },
      { name: 'SC_bj02_recon_back', url: R + 'SCR-013&state=TERMINAL', steps: [['back', back]] },
      { name: 'SC_bj02_pending', url: R + 'SCR-010&state=PENDING_APPROVAL', steps: [] },
    ];
  })(),
  // Cụm giá trị BJ-03 / 13 / 14 — T7-P A5
  ...(() => {
    const V3 = '?uif=UIF-03&screen=';
    const V13 = '?uif=UIF-13&screen=';
    const V14 = '?uif=UIF-14&screen=';
    return [
      { name: 'SC_bj03_list', url: V3 + 'SCR-014', steps: [['filter-ready', click('[data-v430-val03-filter="READY"]')], ['filter-issue', click('[data-v430-val03-filter="ISSUE"]')], ['filter-all', click('[data-v430-val03-filter="ALL"]')], ['search', typeIn('[data-v430-val03-search]', 'Minh')], ['clear-search', typeIn('[data-v430-val03-search]', '')], ['receipt', click('[data-v430-val03-receipt="VAL03-R1"]')]] },
      { name: 'SC_bj03_basis', url: V3 + 'SCR-014', steps: [['receipt', click('[data-v430-val03-receipt="VAL03-R2"]')], ['add-basis', click('[data-v461-val03-add-basis="VAL03-G3"]')], ['currency', pick('[data-v461-basis-currency]', 'VND')], ['price', typeIn('[data-v461-basis-price]', '120000')], ['tax-mode', click('[data-v461-tax-mode="INCLUDED"]')], ['source', typeIn('[data-v461-basis-source]', 'Báo giá NCC')], ['date', typeIn('[data-v461-basis-date]', '01/09/2026')], ['ref', typeIn('[data-v461-basis-ref]', 'HD-TEST-01')], ['reason', typeIn('[data-v461-basis-reason]', 'Nhập nhanh thiếu căn cứ')], ['save-sheet', click('[data-v461-val03-sheet="save"]')], ['select', click('[data-v461-val03-select="VAL03-G3"]')], ['review', click('[data-v461-val03-review]')], ['back', click('[data-v461-val03-back]')]] },
      { name: 'SC_bj03_confirm', url: V3 + 'SCR-017', steps: [['confirm', click('[data-v461-val03-confirm]')], ['to-list', click('[data-v461-val03-result-list]')]] },
      { name: 'SC_bj13_flow', url: V13 + 'SCR-085', steps: [['filter-actionable', click('[data-v430-val13-filter="ACTIONABLE"]')], ['filter-all', click('[data-v430-val13-filter="ALL"]')], ['task', click('[data-v430-val13-task="LC13-001"]')], ['open-confirm', click('[data-v461-val13-open-confirm]')], ['confirm-close', click('[data-v461-val13-confirm-close]')], ['open-again', click('[data-v461-val13-open-confirm]')], ['confirm', click('[data-v461-val13-confirm]')], ['to-list', click('[data-v461-val13-list]')]] },
      { name: 'SC_bj14_flow', url: V14 + 'SCR-072', steps: [['run', click('[data-v461-val14-run="COST-0826"]')], ['compare', click('[data-v461-compare] summary')], ['open-publish', click('[data-v461-val14-open-publish]')], ['publish-close', click('[data-v461-val14-publish-close]')], ['open-again', click('[data-v461-val14-open-publish]')], ['publish', click('[data-v461-val14-publish]')], ['to-list', click('[data-v461-val14-list]')]] },
      { name: 'SC_bj14_period', url: V14 + 'SCR-072', steps: [['close-period', click('[data-v461-val14-close-period]')], ['period', pick('[data-v461-val14-period]', '09/2026')], ['calculate', click('[data-v461-val14-calculate]')]] },
      { name: 'SC_bj14_dirty', url: '?uif=UIF-14&entry=dirty-scope', steps: [['calculate', click('[data-v461-val14-calculate]')]] },
      { name: 'SC_bj03_retired', url: '?uif=UIF-03&screen=SCR-018', steps: [] },
      { name: 'SC_bj13_retired', url: '?uif=UIF-13&screen=SCR-088', steps: [] },
    ];
  })(),
  // BJ-07 / 09 / 10 — T7-P A6
  ...(() => {
    const seed09Approver = `(()=>{window.__VET45_V3101__?.buildBasis?.();stateByScreen['SCR-038']='APPROVAL_REVIEW';renderAppScreen();return true})()`;
    return [
      { name: 'SC_bj07_list', url: '?uif=UIF-07&screen=SCR-036', steps: [['filter-actionable', click('[data-io07-filter="ACTIONABLE"]')], ['filter-waiting', click('[data-io07-filter="WAITING"]')], ['filter-all', click('[data-io07-filter="ALL"]')], ['search', typeIn('[data-io07-search]', 'Minh')], ['clear-search', typeIn('[data-io07-search]', '')], ['request', click('[data-io07-request="RTV-260827-02"]')]] },
      { name: 'SC_bj07_verify', url: '?uif=UIF-07&screen=SCR-036', steps: [['request', click('[data-io07-request="RTV-260827-02"]')], ['alloc1', click('[data-io07-allocation="RTV-A1"]')], ['scan', typeIn('[data-io07-scan-lot]', 'DH2507')], ['confirm1', click('[data-io07-action="confirm-allocation"]')], ['alloc2', click('[data-io07-allocation="RTV-A2"]')], ['mismatch', click('[data-io07-action="mark-mismatch"]')], ['select-mismatch', click('[data-io07-action="select-mismatch"]')], ['close-mismatch', click('[data-io07-action="close-mismatch"]')]] },
      { name: 'SC_bj07_handover', url: '?uif=UIF-07&screen=SCR-037', steps: [['review', click('[data-io07-action="review-handover"]')], ['back-prep', click('[data-io07-action="back-to-preparation"]')], ['review2', click('[data-io07-action="review-handover"]')], ['confirm', click('[data-io07-action="confirm-handover"]')], ['to-queue', click('[data-io07-action="result-to-rtv-queue"]')]] },
      { name: 'SC_bj07_source_changed', url: '?uif=UIF-07&screen=SCR-039&state=SOURCE_CHANGED', steps: [['back-prep', click('[data-io07-action="back-to-preparation"]')]] },
      { name: 'SC_bj09_flow', url: '?uif=UIF-09&screen=SCR-036', steps: [['filter-sellable', click('[data-ic09-filter="SELLABLE"]')], ['filter-all', click('[data-ic09-filter="ALL"]')], ['search', typeIn('[data-ic09-search]', 'Amox')], ['clear-search', typeIn('[data-ic09-search]', '')], ['item', click('[data-ic09-item="amox"]')], ['change', click('[data-ic09-action="change"]')], ['dest', click('[data-v3101-destination][value="QUARANTINE"]')], ['qty', typeIn('[data-v3101-qty]', '1')], ['reason', typeIn('[data-v3101-reason]', 'Bao bì móp')], ['submit', click('[data-v3101-action="submit"]')]] },
      { name: 'SC_bj09_approve', url: '?uif=UIF-09&entry=approver', steps: [['seed', seed09Approver], ['open-reject', click('[data-v3101-action="reject-open"]')], ['reason', typeIn('[data-v3101-reject-reason]', 'Thiếu bằng chứng')], ['close-reject', click('[data-v3101-action="reject-close"]')], ['approve', click('[data-v3101-action="approve"]')]] },
      { name: 'SC_bj09_movement', url: '?uif=UIF-09&screen=SCR-056', steps: [] },
      { name: 'SC_bj10_flow', url: '?uif=UIF-10&screen=SCR-036', steps: [['item', click('[data-ic10-item="amox-l2407"]')], ['request', click('[data-ic10-action="request"]')], ['qty', typeIn('[data-v350-ic10-qty]', '6')], ['reason', typeIn('[data-v350-ic10-reason]', 'Hàng không còn đủ điều kiện')], ['evidence', typeIn('[data-v350-ic10-evidence]', 'Ảnh hiện trạng')], ['submit', click('[data-v350-action="ic10-submit"]')]] },
      { name: 'SC_bj10_approve', url: '?uif=UIF-10&entry=approver', steps: [['approve', click('[data-v350-action="ic10-approve"]')]] },
      { name: 'SC_bj10_complete', url: '?uif=UIF-10&entry=completion-operator', steps: [['actual', typeIn('[data-v350-ic10-actual]', '6')], ['proof', typeIn('[data-v350-ic10-proof]', 'bien-ban.jpg')], ['complete', click('[data-v350-action="ic10-complete"]')]] },
    ];
  })(),
  // BJ-08 Kiểm kê — T7-P A7
  ...(() => {
    const key = (k) => click(`[data-ic08-key=${JSON.stringify(k)}]`);
    return [
      { name: 'SC_bj08_list', url: '?uif=UIF-08&screen=SCR-042', steps: [['filter-counting', click('[data-v350-ic08-filter="COUNTING"]')], ['filter-approval', click('[data-v350-ic08-filter="APPROVAL"]')], ['search', typeIn('[data-v350-ic08-list-search]', 'KK-0708')], ['clear-search', typeIn('[data-v350-ic08-list-search]', '')], ['new', click('[data-v3100-ic08-action="new"]')]] },
      { name: 'SC_bj08_create', url: '?uif=UIF-08&screen=SCR-043', steps: [['scope-product', pick('[data-ic08-scope]', 'PRODUCT')], ['scope-open', click('[data-ic08-action="scope-select-open"]')], ['scope-pick', click('[data-ic08-scope-target]')], ['open', click('[data-v3100-ic08-action="open"]')], ['confirm', click('[data-v3100-ic08-action="confirm-open"]')]] },
      { name: 'SC_bj08_blind', url: '?uif=UIF-08&screen=SCR-044', steps: [['qty-amox', click('[data-ic08-keypad-open="count:amox"]')], ['a1', key('1')], ['a8', key('8')], ['save-amox', click('[data-ic08-action="keypad-save"]')], ['qty-glove', click('[data-ic08-keypad-open="count:glove"]')], ['g7', key('7')], ['save-glove', click('[data-ic08-action="keypad-save"]')], ['add-actual', click('[data-ic08-action="add-actual-open"]')], ['pick-product', click('[data-ic08-product="vitc"]')], ['stock-state', pick('[data-v3100-stock-state]', 'SELLABLE')], ['qty-unexp', click('[data-ic08-keypad-open="count:unexpected"]')], ['u1', key('1')], ['save-unexp', click('[data-ic08-action="keypad-save"]')], ['submit', click('[data-v3100-ic08-action="submit-first"]')], ['confirm', click('[data-v3100-ic08-action="confirm-first"]')]] },
      { name: 'SC_bj08_recount', url: '?uif=UIF-08&screen=SCR-045', steps: [['seed', `(()=>{ic08Counts={amox:'18',glove:'7'};ic08Recounts={amox:'',glove:''};stateByScreen['SCR-045']='RECOUNT_REQUIRED';renderAppScreen();return true})()`], ['qty-amox', click('[data-ic08-keypad-open="recount:amox"]')], ['a1', key('1')], ['a8', key('8')], ['save-amox', click('[data-ic08-action="keypad-save"]')], ['qty-glove', click('[data-ic08-keypad-open="recount:glove"]')], ['g7', key('7')], ['save-glove', click('[data-ic08-action="keypad-save"]')], ['submit', click('[data-v3100-ic08-action="submit-recount"]')], ['confirm', click('[data-v3100-ic08-action="confirm-recount"]')]] },
      { name: 'SC_bj08_approve', url: '?uif=UIF-08&entry=approver', steps: [['approve', click('[data-v3100-ic08-action="approve"]')], ['confirm', click('[data-v3100-ic08-action="confirm-approve"]')]] },
      { name: 'SC_bj08_self_approve', url: '?uif=UIF-08&screen=SCR-046', steps: [['approve', click('[data-v3100-ic08-action="approve"]')]] },
      { name: 'SC_bj08_review', url: '?uif=UIF-08&entry=approver', steps: [['request', click('[data-v3100-ic08-action="request-review"]')], ['reason', typeIn('[data-v3100-review-reason]', 'Cần đếm lại kệ A')], ['confirm', click('[data-v3100-ic08-action="confirm-review"]')]] },
      { name: 'SC_bj08_cancel', url: '?uif=UIF-08&screen=SCR-044', steps: [['cancel', click('[data-v3100-ic08-action="cancel-open"]')], ['reason', typeIn('[data-v3100-cancel-reason]', 'Sai phạm vi phiên')], ['confirm', click('[data-v3100-ic08-action="confirm-cancel"]')]] },
      { name: 'SC_bj08_unknown', url: '?uif=UIF-08&screen=SCR-047&state=UNKNOWN', steps: [['handoff', click('[data-v350-action="handoff-unknown"]')]] },
    ];
  })(),
  // BJ-11 / BJ-12 — T7-P A8
  { name: 'SC_bj11_list', url: '?uif=UIF-11&screen=SCR-048', steps: [['filter-cancel', click('[data-cr11-filter="CANCEL"]')], ['filter-unknown', click('[data-cr11-filter="UNKNOWN"]')], ['filter-all', click('[data-cr11-filter="ALL"]')], ['search', typeIn('[data-cr11-search]', 'Nobivac')], ['clear-search', typeIn('[data-cr11-search]', '')], ['open', click('[data-cr11-operation="IO-260901-014"]')]] },
  { name: 'SC_bj11_correct', url: '?uif=UIF-11&screen=SCR-048', steps: [['open', click('[data-cr11-operation="IO-260901-014"]')], ['correction', click('[data-cr11-action="open-correction"]')], ['full', click('[data-cr11-strategy][value="FULL"]')], ['edit', click('[data-cr11-action="edit-correction"]')], ['qty', typeIn('[data-cr11-correct-qty]', '117')], ['reason', typeIn('[data-cr11-correction-reason]', 'Đếm lại thùng')], ['submit', click('[data-cr11-action="submit-correction"]')], ['to-list', click('[data-cr11-action="to-list"]')]] },
  { name: 'SC_bj11_cancel', url: '?uif=UIF-11&screen=SCR-048', steps: [['open', click('[data-cr11-operation="IO-260906-022"]')], ['cancel', click('[data-cr11-action="open-cancel"]')], ['reason', typeIn('[data-cr11-cancel-reason]', 'Lập nhầm phiếu')], ['confirm', click('[data-cr11-action="confirm-cancel"]')], ['to-list', click('[data-cr11-action="to-list"]')]] },
  { name: 'SC_bj11_blocked', url: '?uif=UIF-11&screen=SCR-048', steps: [['open', click('[data-cr11-operation="IO-260902-005"]')], ['to-list', click('[data-cr11-action="to-list"]')]] },
  { name: 'SC_bj11_unknown', url: '?uif=UIF-11&screen=SCR-048', steps: [['open', click('[data-cr11-operation="IO-260906-031"]')], ['handoff', click('[data-cr11-action="handoff-unknown"]')]] },
  { name: 'SC_bj11_back', url: '?uif=UIF-11&screen=SCR-050', steps: [['b1', back], ['b2', back], ['b3', back]] },
  { name: 'SC_bj11_approve', url: '?uif=UIF-11&entry=approver', steps: [['approve', click('[data-v350-action="cr11-approve"]')], ['wait', wait(400)], ['to-list', click('[data-cr11-action="to-list"]')]] },
  { name: 'SC_bj11_reject', url: '?uif=UIF-11&entry=approver', steps: [['open', click('[data-cr11-action="reject-open"]')], ['close', click('[data-cr11-action="reject-close"]')], ['open2', click('[data-cr11-action="reject-open"]')], ['reason', typeIn('[data-cr11-approval-reason]', 'Thiếu chứng từ')], ['confirm', click('[data-v350-action="cr11-reject-confirm"]')]] },
  { name: 'SC_bj11_self_approve', url: '?uif=UIF-11&screen=SCR-051', steps: [['approve', click('[data-v350-action="cr11-approve"]')], ['exit', click('[data-v360-action="fallback-exit"]')]] },
  { name: 'SC_bj11_decided', url: '?uif=UIF-11&screen=SCR-051&state=APPROVAL_ALREADY_DECIDED', steps: [['result', click('[data-v350-action="cr11-approval-result"]')]] },
  { name: 'SC_bj11_context', url: '?uif=UIF-11&entry=operation-context', steps: [['back', back]] },
  { name: 'SC_bj12_prepare', url: '?uif=UIF-12&screen=SCR-066', steps: [['start', click('[data-cf12-action="start"]')], ['file', click('[data-cf12-action="choose-file"]')], ['clear-qty', typeIn('[data-cf12-control-qty]', '')], ['check-err', click('[data-v350-action="cf12-check"]')], ['qty', typeIn('[data-cf12-control-qty]', '4820')], ['check', click('[data-v350-action="cf12-check"]')], ['review', click('[data-cf12-action="review"]')], ['send', click('[data-v350-action="cf12-send-approval"]')]] },
  { name: 'SC_bj12_mismatch', url: '?uif=UIF-12&screen=SCR-067', steps: [['qty', typeIn('[data-cf12-control-qty]', '4800')], ['check', click('[data-v350-action="cf12-check"]')], ['back', click('[data-cf12-action="back-file"]')]] },
  { name: 'SC_bj12_failed', url: '?uif=UIF-12&screen=SCR-068&state=VALIDATION_FAILED', steps: [['back', click('[data-cf12-action="back-file"]')]] },
  { name: 'SC_bj12_approve', url: '?uif=UIF-12&screen=SCR-067', steps: [['check', click('[data-v350-action="cf12-check"]')], ['review', click('[data-cf12-action="review"]')], ['send', click('[data-v350-action="cf12-send-approval"]')], ['approver', `window.__VET45_V350__.applyEntry('UIF-12','approver')`], ['approve', click('[data-v350-action="cf12-approve"]')], ['wait', wait(500)], ['inventory', click('[data-cf12-action="see-inventory"]')]] },
  { name: 'SC_bj12_stale', url: '?uif=UIF-12&entry=approver', steps: [['approve', click('[data-v350-action="cf12-approve"]')]] },
  { name: 'SC_bj12_self', url: '?uif=UIF-12&screen=SCR-070', steps: [['approve', click('[data-v350-action="cf12-approve"]')], ['exit', click('[data-v360-action="fallback-exit"]')]] },
  { name: 'SC_bj12_reject', url: '?uif=UIF-12&entry=approver', steps: [['open', click('[data-cf12-action="open-reject"]')], ['close', click('[data-cf12-action="close-reject"]')], ['open2', click('[data-cf12-action="open-reject"]')], ['reason', typeIn('[data-cf12-reject-reason]', 'Sai nhóm vaccine')], ['confirm', click('[data-v350-action="cf12-confirm-reject"]')], ['exit', click('[data-v360-action="fallback-exit"]')], ['fix', click('[data-cf12-action="fix-rejected"]')]] },
  { name: 'SC_bj12_unknown', url: '?uif=UIF-12&screen=SCR-071&state=UNKNOWN', steps: [['handoff', click('[data-v350-action="handoff-unknown"]')]] },
  // BJ-15 — T7-P A9
  { name: 'SC_bj15_inventory', url: '?uif=UIF-15&screen=SCR-054', steps: [['query', click('[data-cf15-action="query"]')], ['sheet', click('[data-cf15-product-row="P-AMX"]')], ['stock', click('[data-cf15-action="product-stock-card"]')], ['mv', click('[data-cf15-movement="MV-AMX-01"]')], ['source', click('[data-cf15-action="source"]')], ['b1', back], ['b2', back]] },
  { name: 'SC_bj15_stock_card', url: '?uif=UIF-15&screen=SCR-054', steps: [['type', click('[data-cf15-report-type="STOCK_CARD"]')], ['mode', click('[data-cf15-date-mode="RECORDED"]')], ['query', click('[data-cf15-action="query"]')], ['sale', click('[data-cf15-movement="M-SALE"]')], ['back', back]] },
  { name: 'SC_bj15_validation', url: '?uif=UIF-15&screen=SCR-054', steps: [['stock', click('[data-cf15-report-type="STOCK_CARD"]')], ['all', pick('[data-cf15-product]','ALL')], ['query-err', click('[data-cf15-action="query"]')], ['inv', click('[data-cf15-report-type="INVENTORY"]')], ['query', click('[data-cf15-action="query"]')]] },
  { name: 'SC_bj15_date_invalid', url: '?uif=UIF-15&screen=SCR-054', steps: [['from', typeIn('[data-cf15-from]','08/09/2026')], ['query', click('[data-cf15-action="query"]')]] },
  { name: 'SC_bj15_sheet', url: '?uif=UIF-15&screen=SCR-054', steps: [['query', click('[data-cf15-action="query"]')], ['nob', click('[data-cf15-product-row="P-NOB"]')], ['close', click('.sheet-backdrop[data-cf15-action="close-product-sheet"]')], ['glv', click('[data-cf15-product-row="P-GLV"]')], ['stock', click('[data-cf15-action="product-stock-card"]')]] },
  { name: 'SC_bj15_export', url: '?uif=UIF-15&screen=SCR-054', steps: [['query', click('[data-cf15-action="query"]')], ['export', click('[data-cf15-action="export"]')], ['back', back], ['export2', click('[data-cf15-action="export"]')], ['confirm', click('[data-cf15-action="confirm-export"]')], ['wait', wait(400)], ['done', click('[data-cf15-action="done-export"]')]] },
  { name: 'SC_bj15_export_source', url: '?uif=UIF-15&screen=SCR-054', steps: [['stock', click('[data-cf15-report-type="STOCK_CARD"]')], ['query', click('[data-cf15-action="query"]')], ['mv', click('[data-cf15-movement="M-RECEIPT"]')], ['source', click('[data-cf15-action="source"]')], ['export', click('[data-cf15-action="export-source"]')], ['confirm', click('[data-cf15-action="confirm-export"]')], ['wait', wait(400)], ['done', click('[data-cf15-action="done-export"]')]] },
  { name: 'SC_bj15_restricted', url: '?uif=UIF-15&screen=SCR-055&state=FINANCIAL_RESTRICTED', steps: [['export', click('[data-cf15-action="export"]')], ['confirm', click('[data-cf15-action="confirm-export"]')], ['wait', wait(400)], ['done', click('[data-cf15-action="done-export"]')]] },
  { name: 'SC_bj15_export_denied', url: '?uif=UIF-15&screen=SCR-058&state=PERMISSION_DENIED', steps: [['exit', click('[data-v360-action="fallback-exit"]')]] },
  { name: 'SC_bj15_result_denied', url: '?uif=UIF-15&screen=SCR-059&state=PERMISSION_DENIED', steps: [['exit', click('[data-v360-action="fallback-exit"]')]] },
  { name: 'SC_bj15_result_stale', url: '?uif=UIF-15&screen=SCR-059&state=SOURCE_STALE', steps: [['done', click('[data-cf15-action="done-export"]')]] },
  { name: 'SC_bj09_history_back', url: '?uif=UIF-09&screen=SCR-056', steps: [['back', back]] },
  // BJ-16 / BJ-17 — T7-P A10
  ...(() => {
    const D = '?uif=UIF-16&screen=';
    const U = '?uif=UIF-17&screen=';
    const bump16 = `(()=>{window.__VET45_V350__.bumpCR16Evidence();return true})()`;
    const bump17 = `(()=>{window.__VET45_V350__.bumpCR17Evidence();return true})()`;
    return [
      { name: 'SC_bj16_list', url: D + 'SCR-078', steps: [['filter-action', click('[data-cr16-filter="ACTION"]')], ['filter-waiting', click('[data-cr16-filter="WAITING"]')], ['filter-high', click('[data-cr16-filter="HIGH"]')], ['filter-all', click('[data-cr16-filter="ALL"]')], ['search', typeIn('[data-cr-control-search]', 'Amox')], ['clear-search', typeIn('[data-cr-control-search]', '')], ['case', click('[data-cr-case="REC-260907-03"]')]] },
      { name: 'SC_bj16_recovery', url: D + 'SCR-078', steps: [['case', click('[data-cr-case="REC-260907-03"]')], ['open-plan', click('[data-v350-action="cr16-open-plan"]')], ['start', click('[data-v350-action="cr16-start-recovery"]')], ['wait', wait(400)], ['review', click('[data-v350-action="cr16-review-result"]')], ['close', click('[data-v350-action="cr16-close-case"]')], ['to-list', click('[data-cr16-action="to-list"]')]] },
      { name: 'SC_bj16_conflict', url: D + 'SCR-078', steps: [['case', click('[data-cr-case="REC-260907-03"]')], ['open-plan', click('[data-v350-action="cr16-open-plan"]')], ['bump', bump16], ['start', click('[data-v350-action="cr16-start-recovery"]')], ['back', back]] },
      { name: 'SC_bj16_mismatch', url: D + 'SCR-078', steps: [['case', click('[data-cr-case="REC-260907-03"]')], ['open-plan', click('[data-v350-action="cr16-open-plan"]')], ['start', click('[data-v350-action="cr16-start-recovery"]')], ['wait', wait(400)], ['review', click('[data-v350-action="cr16-review-result"]')], ['bump', bump16], ['close', click('[data-v350-action="cr16-close-case"]')], ['back-ev', click('[data-v350-action="cr16-back-evidence"]')]] },
      { name: 'SC_bj16_correction', url: D + 'SCR-078', steps: [['case', click('[data-cr-case="REC-260907-04"]')], ['handoff', click('[data-v350-action="cr16-correction-handoff"]')]] },
      { name: 'SC_bj16_no_real', url: D + 'SCR-078', steps: [['case', click('[data-cr-case="REC-260907-05"]')], ['review-close', click('[data-v350-action="cr16-review-close"]')], ['close', click('[data-v350-action="cr16-close-case"]')], ['to-list', click('[data-cr16-action="to-list"]')]] },
      { name: 'SC_bj16_ledger', url: D + 'SCR-078', steps: [['case', click('[data-cr-case="REC-260907-06"]')], ['escalated', click('[data-cr16-action="show-escalated"]')], ['to-list', click('[data-cr16-action="to-list"]')]] },
      { name: 'SC_bj16_source', url: D + 'SCR-078', steps: [['case', click('[data-cr-case="REC-260907-07"]')], ['source', click('[data-v350-action="cr16-source-handoff"]')]] },
      { name: 'SC_bj16_back', url: D + 'SCR-078', steps: [['case', click('[data-cr-case="REC-260907-03"]')], ['open-plan', click('[data-v350-action="cr16-open-plan"]')], ['b1', back], ['b2', back]] },
      { name: 'SC_bj16_context', url: '?uif=UIF-16&entry=case-context', steps: [['back', back]] },
      { name: 'SC_bj16_denied', url: D + 'SCR-083&state=PERMISSION_DENIED', steps: [['exit', click('[data-v360-action="fallback-exit"]')]] },
      { name: 'SC_bj17_list', url: U + 'SCR-078', steps: [['filter-committed', click('[data-cr17-filter="COMMITTED"]')], ['filter-no', click('[data-cr17-filter="NO_COMMIT"]')], ['filter-ins', click('[data-cr17-filter="INSUFFICIENT"]')], ['filter-all', click('[data-cr17-filter="ALL"]')], ['search', typeIn('[data-cr-control-search]', 'IO-260906-044')], ['clear-search', typeIn('[data-cr-control-search]', '')], ['case', click('[data-cr-case="REC-UNKNOWN-01"]')]] },
      { name: 'SC_bj17_committed', url: U + 'SCR-078', steps: [['case', click('[data-cr-case="REC-UNKNOWN-01"]')], ['open-plan', click('[data-cr17-action="open-plan"]')], ['execute', click('[data-v350-action="cr17-execute-plan"]')], ['finish', click('[data-v350-action="cr17-finish-review"]')], ['to-list', click('[data-cr17-action="to-list"]')]] },
      { name: 'SC_bj17_continue', url: U + 'SCR-078', steps: [['case', click('[data-cr-case="REC-UNKNOWN-02"]')], ['open-plan', click('[data-cr17-action="open-plan"]')], ['execute', click('[data-v350-action="cr17-execute-plan"]')], ['finish', click('[data-v350-action="cr17-finish-review"]')]] },
      { name: 'SC_bj17_insufficient', url: U + 'SCR-078', steps: [['case', click('[data-cr-case="REC-UNKNOWN-03"]')], ['escalated', click('[data-cr17-action="show-escalated"]')], ['to-list', click('[data-cr17-action="to-list"]')]] },
      { name: 'SC_bj17_plan_conflict', url: U + 'SCR-078', steps: [['case', click('[data-cr-case="REC-UNKNOWN-01"]')], ['open-plan', click('[data-cr17-action="open-plan"]')], ['bump', bump17], ['execute', click('[data-v350-action="cr17-execute-plan"]')]] },
      { name: 'SC_bj17_finish_conflict', url: U + 'SCR-078', steps: [['case', click('[data-cr-case="REC-UNKNOWN-01"]')], ['open-plan', click('[data-cr17-action="open-plan"]')], ['execute', click('[data-v350-action="cr17-execute-plan"]')], ['bump', bump17], ['finish', click('[data-v350-action="cr17-finish-review"]')]] },
      { name: 'SC_bj17_context', url: '?uif=UIF-17&entry=unknown-context', steps: [['back', back]] },
      { name: 'SC_bj17_denied', url: U + 'SCR-083&state=PERMISSION_DENIED', steps: [['exit', click('[data-v360-action="fallback-exit"]')]] },
      { name: 'SC_bj17_from_bj05', url: '?uif=UIF-05&screen=SCR-029&state=UNKNOWN', steps: [['handoff', click('[data-v350-action="handoff-unknown"]')], ['escalated', click('[data-cr17-action="show-escalated"]')], ['to-list', click('[data-cr17-action="to-list"]')]] },
      { name: 'SC_bj17_from_bj07', url: '?uif=UIF-07&screen=SCR-041&state=UNKNOWN', steps: [['handoff', click('[data-v350-action="handoff-unknown"]')]] },
      { name: 'SC_bj17_from_bj10', url: '?uif=UIF-10&screen=SCR-041&state=UNKNOWN', steps: [['handoff', click('[data-v350-action="handoff-unknown"]')]] },
    ];
  })(),
];
for (const sc of SCENARIOS) groups.push({ url: sc.url, cases: [{ name: `${sc.name}_0` }, ...sc.steps.map(([n, act], i) => ({ name: `${sc.name}_${i + 1}_${n}`, act }))].filter((c) => c.name.includes(filter)) });
const todo = groups.filter((g) => g.cases.length);
mkdirSync(a, { recursive: true });

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
async function worker(n, queue, errors) {
  const port = 9400 + n;
  const chrome = spawn('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', ['--headless=new', `--remote-debugging-port=${port}`, `--user-data-dir=${path.join(a, '.chrome' + n)}`, '--hide-scrollbars', '--force-device-scale-factor=1', 'about:blank'], { stdio: 'ignore' });
  let list; for (let i = 0; i < 100 && !list; i++) { try { list = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json(); } catch { await sleep(100); } }
  if (!list?.length) { chrome.kill(); throw new Error(`Chrome CDP không sẵn sàng ở cổng ${port}`); }
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
    await evalv(`(async()=>{for(let i=0;i<100&&!document.querySelector('#device-preview');i++)await new Promise(r=>setTimeout(r,50));})()`);
    // Native <select> arrows are drawn by the OS and shift with system appearance; hide them so goldens compare only prototype CSS.
    await evalv(`(()=>{const st=document.createElement('style');st.textContent='*,*::before,*::after{animation:none!important;transition:none!important;caret-color:transparent!important}select{appearance:none!important;-webkit-appearance:none!important}'+${JSON.stringify(process.env.EXTRA_CSS || '')};document.head.append(st)})()`);
    await evalv(`document.fonts.ready.then(()=>${frames})`);
    for (const c of g.cases) {
      if (c.screen) await evalv(`(activeScreenId=${JSON.stringify(c.screen)}, stateByScreen[activeScreenId]=${JSON.stringify(c.state)}, render(), ${frames})`);
      // Await act Promise (e.g. wait(ms) for timers) before rAF settle — T7-P A8 §6.1
      if (c.act) await evalv(`Promise.resolve(${c.act}).then(()=>${frames})`);
      const v = await evalv(`(()=>{const d=document.querySelector('#device-preview')?.getBoundingClientRect();const s=document.querySelector('#app-screen');if(!d||!s)return null;return {x:d.x,y:d.y,w:d.width,h:d.height,t:s.innerText+'\\n@inspector '+['current-screen-id','current-screen-name','workbench-title','traceability'].map(i=>document.getElementById(i)?.innerText||'').join(' | ')+'\\n@url '+location.search}})()`);
      if (!v) { errors.push(`no preview for ${c.name}`); continue; }
      const shot = await send('Page.captureScreenshot', { format: 'png', clip: { x: v.x, y: v.y, width: Math.max(1, v.w), height: Math.max(1, v.h), scale: 1 } });
      writeFileSync(path.join(a, c.name + '.png'), Buffer.from(shot.result.data, 'base64'));
      writeFileSync(path.join(a, c.name + '.txt'), v.t);
    }
  }
  ws.close(); chrome.kill();
}
const t0 = Date.now(); const errors = []; const queue = [...todo];
await Promise.all(Array.from({ length: Math.min(WORKERS, todo.length) }, (_, n) => worker(n, queue, errors)));
writeFileSync(path.join(a, '_errors.json'), JSON.stringify(errors, null, 1));
await sleep(300);
for (const d of readdirSync(a)) if (d.startsWith('.chrome')) rmSync(path.join(a, d), { recursive: true, force: true });
console.log(`Đã chụp ${todo.reduce((s, g) => s + g.cases.length, 0)} ca trong ${((Date.now() - t0) / 1000).toFixed(1)} giây, lỗi JS: ${errors.length}`);
