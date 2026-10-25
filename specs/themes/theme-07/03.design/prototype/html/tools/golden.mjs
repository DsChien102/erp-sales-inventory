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
// DEVICE=web: khung Web 1280×800 (cửa sổ 2400×1300 để khung không bị thu); mặc định mobile, tên ca không đổi.
const WEB = process.env.DEVICE === 'web';
const WINDOW = WEB ? { width: 2400, height: 1300 } : { width: 1600, height: 1100 };
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

if (mode !== 'capture' && mode !== 'usage') {
  console.error('Dùng: node tools/golden.mjs capture <dir> [filter] | compare <dirA> <dirB> | usage <dir>');
  process.exit(2);
}
const FULL = process.env.FULL === '1';

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
groups.push({ url: '?mode=theme&app=inventory&activation=pending', cases: [{ name: 'HUB_home_not_activated' }].filter((c) => c.name.includes(filter)) });
// SCR-046 READY là màn của người duyệt: mở bằng vai approver (nhân viên mở cùng màn thấy "Không thể tự duyệt").
{ const g8 = groups.find((g) => g.url.startsWith('?uif=UIF-08')); const i = g8 ? g8.cases.findIndex((c) => c.name === 'UIF-08_SCR-046_READY') : -1; if (i >= 0) groups.push({ url: '?uif=UIF-08&screen=SCR-046&entry=approver', cases: g8.cases.splice(i, 1) }); }

// SCR-051 READY / VALIDATION_ERROR là màn của người duyệt: mở bằng vai approver (nhân viên mở cùng màn thấy "Bạn không thể tự duyệt").
{ const g11 = groups.find((g) => g.url.startsWith('?uif=UIF-11')); const mv = g11 ? g11.cases.filter((c) => /^UIF-11_SCR-051_(READY|VALIDATION_ERROR)$/.test(c.name)) : []; if (mv.length) { g11.cases = g11.cases.filter((c) => !mv.includes(c)); groups.push({ url: '?uif=UIF-11&screen=SCR-051&entry=approver', cases: mv }); } }

// Interaction scenarios (theme mode / Hub Kho): one fresh page per scenario, capture after every step.
const click = (sel, i = 0) => `(()=>{const el=document.querySelectorAll(${JSON.stringify(sel)})[${i}];if(el)el.click();return !!el})()`;
const back = click('#app-screen .app-back-button');
const search = (q) => `(()=>{const i=document.querySelector('[data-t462-inventory-search]');if(!i)return false;i.value=${JSON.stringify(q)};i.dispatchEvent(new KeyboardEvent('keydown',{key:'Enter',bubbles:true}));return true})()`;
const typeIn = (sel, value) => `(()=>{const i=document.querySelector(${JSON.stringify(sel)});if(!i)return false;i.value=${JSON.stringify(value)};i.dispatchEvent(new Event('input',{bubbles:true}));return true})()`;
const pick = (sel, value) => `(()=>{const i=document.querySelector(${JSON.stringify(sel)});if(!i)return false;i.value=${JSON.stringify(value)};i.dispatchEvent(new Event('change',{bubbles:true}));return true})()`;
const wait = (ms) => `new Promise((r)=>setTimeout(()=>r(true),${ms}))`;
const T = '?mode=theme&app=';
// DEVICE=web chỉ chạy các kịch bản có ý nghĩa ở khung web (còn lại cố định theo iPhone).
const WEB_SCENARIOS = ['SC_k5_list', 'SC_bj09_quarantine_to_damaged', 'SC_bj09_approve', 'SC_bj09_from_bj01', 'SC_k5_hub_rtv', 'SC_journey_1', 'SC_cap_table', 'SC_cap_expiry', 'SC_cap_single', 'SC_cap_staff', 'SC_cap_hub', 'SC_bj02_documents', 'SC_bj02_quick', 'SC_bj02_approve', 'SC_bj02_reject', 'SC_bj02_owner_flow', 'SC_bj03_from_receipt', 'SC_bj03_direct', 'SC_bj03_list', 'SC_bj01_list', 'SC_bj01_detail', 'SC_bj01_theme', 'SC_bj13_flow', 'SC_bj13_decrease', 'SC_journey_2', 'SC_bj05_quick_pick', 'SC_bj05_ready_handover', 'SC_bj05_override', 'SC_bj04_from_pick', 'SC_bj05_theme', 'SC_bj06_full', 'SC_bj06_exception_submit', 'SC_bj06_split', 'SC_bj06_owner_approve', 'SC_journey_3', 'SC_bj07_verify', 'SC_bj07_quick_verify', 'SC_bj07_split_source', 'SC_bj07_mismatch_wait', 'SC_bj07_handover', 'SC_bj07_next_request', 'SC_bj10_flow', 'SC_bj10_price_missing', 'SC_bj10_approve', 'SC_bj10_reject', 'SC_bj10_complete', 'SC_bj10_from_list', 'SC_bj10_qty_over', 'SC_bj10_owner_self', 'SC_journey_4', 'SC_bj08_list', 'SC_bj08_create', 'SC_bj08_blind', 'SC_bj08_recount', 'SC_bj08_approve', 'SC_bj08_from_home', 'SC_bj11_list', 'SC_bj11_correct', 'SC_bj11_approve', 'SC_bj11_from_home', 'SC_bj11_from_case', 'SC_recon_list', 'SC_bj16_recovery', 'SC_bj16_correction_return', 'SC_bj17_committed', 'SC_journey_5'];
const SCENARIOS = [
  { name: 'SC_more', url: T + 'more', steps: [['kho', click('[data-theme-app-route="inventory"]')], ['back', back]] },
  { name: 'SC_hub_back', url: T + 'inventory', steps: [['back', back], ['nav-more', click('#app-screen [data-theme-sidebar-route="more"]')]] },
  { name: 'SC_mode', url: T + 'inventory', steps: [['bj', click('button[data-workbench-mode="bj"]')], ['theme', click('button[data-workbench-mode="theme"]')]] },
  { name: 'SC_sidebar', url: T + 'inventory', steps: [['more', click('#screen-navigation [data-theme-sidebar-route="more"]')], ['kho', click('#screen-navigation [data-theme-sidebar-route="inventory"]')]] },
  { name: 'SC_search', url: T + 'inventory', steps: [['enter', search('Amox')], ['back', back]] },
  ...['UIF-02', 'UIF-05', 'UIF-08', 'UIF-01'].map((q) => ({ name: `SC_quick_${q}`, url: T + 'inventory', steps: [['enter', click(`[data-t462-quick="${q}"]`)], ['back', back]] })),
  { name: 'SC_pending', url: T + 'inventory', steps: [['list', click('[data-v464-pending-approvals]')], ['receipt', click('[data-v464-pending-receipt]', 1)], ['exit', click('#app-screen .app-back-button')], ['home', back]] },
  ...['UIF-09', 'UIF-16'].map((f) => ({ name: `SC_attention_${f}`, url: T + 'inventory', steps: [['open', click(`[data-t462-attention="${f}"]`)], ['back', back]] })),
  // Home chỉ còn một dòng "Hồ sơ cần kiểm tra"; ca cũ của UIF-17 = mở dòng đó rồi chọn chip "Chưa rõ kết quả".
  { name: 'SC_attention_UIF-17', url: T + 'inventory', steps: [['open', click('[data-t462-attention="UIF-16"]')], ['unknown-chip', click('[data-recon-filter="UNKNOWN"]')], ['back', back]] },
  ...Object.entries({ inventory: 2, movement: 4, control: 4, valuation: 3, history: 1, setup: 2 }).flatMap(([ws, n]) => Array.from({ length: n }, (_, i) => ({ name: `SC_ws_${ws}_${i}`, url: T + 'inventory', steps: [['ws', click(`[data-t462-workspace="${ws}"]`)], ['item', click('#app-screen [data-theme-entry-flow]', i)], ['back', back], ['home', back]] }))),
  // BJ-01 Tồn kho (UIF-01)
  { name: 'SC_bj01_list', url: '?uif=UIF-01&screen=SCR-001', steps: [['filter-low', click('[data-bj01-filter="LOW"]')], ['filter-near', click('[data-bj01-filter="NEAR"]')], ['filter-all', click('[data-bj01-filter="ALL"]')], ['search', `(()=>{const i=document.querySelector('[data-bj01-search]');i.value='amox';i.dispatchEvent(new Event('input',{bubbles:true}));return true})()`], ['product', click('[data-bj01-product="INV-AMX"]')]] },
  { name: 'SC_bj01_filter_empty', url: '?uif=UIF-01&screen=SCR-001', steps: [['search', `(()=>{const i=document.querySelector('[data-bj01-search]');i.value='zzz';i.dispatchEvent(new Event('input',{bubbles:true}));return true})()`], ['filter', click('[data-bj01-filter="OUT"]')], ['clear', click('[data-bj01-clear]')]] },
  { name: 'SC_bj01_detail', url: '?uif=UIF-01&screen=SCR-001', steps: [['product', click('[data-bj01-product="INV-NOB"]')], ['lot', click('[data-bj01-lot="DH2509"]')], ['close-lot', click('[data-bj01-close-lot]')], ['provenance', click('[data-bj01-provenance]')], ['handoff', click('[data-bj01-handoff]')]] },
  { name: 'SC_bj01_tylo', url: '?uif=UIF-01&screen=SCR-001', steps: [['product', click('[data-bj01-product="INV-TYLO"]')], ['lot', click('[data-bj01-lot="TY2408"]')], ['close-lot', click('.ds24-overlay[data-bj01-close-lot]')], ['back', click('#app-screen .app-back-button')]] },
  { name: 'SC_bj01_stale', url: '?uif=UIF-01&screen=SCR-001&state=STALE', steps: [['refresh', click('[data-bj01-refresh]')], ['product', click('[data-bj01-product="INV-ENRO"]')]] },
  { name: 'SC_bj01_context', url: '?uif=UIF-01&screen=SCR-003&entry=product-context', steps: [['back', click('#app-screen .app-back-button')]] },
  { name: 'SC_bj01_theme', url: '?mode=theme&app=inventory', steps: [['quick', click('[data-t462-quick="UIF-01"]')], ['product', click('[data-bj01-product="INV-OXY"]')], ['back', click('#app-screen .app-back-button')], ['back-hub', click('#app-screen .app-back-button')]] },
  { name: 'SC_bj01_scan', url: '?uif=UIF-01&screen=SCR-001', steps: [['scan', click('[data-bj01-scan]')], ['sample', click('[data-bj01-scan-sample]')]] },
  { name: 'SC_bj01_scan_close', url: '?uif=UIF-01&screen=SCR-001', steps: [['scan', click('[data-bj01-scan]')], ['close', click('.ds24-overlay[data-bj01-scan-close]')]] },
  { name: 'SC_bj01_receive', url: '?uif=UIF-01&screen=SCR-001', steps: [['product', click('[data-bj01-product="INV-AMX"]')], ['receive', click('[data-bj01-receive]')]] },
  { name: 'SC_bj01_out', url: '?uif=UIF-01&screen=SCR-001', steps: [['product', click('[data-bj01-product="INV-ENRO"]')], ['receive', click('[data-bj01-receive]')]] },
  { name: 'SC_bj01_expired', url: '?uif=UIF-01&screen=SCR-001', steps: [['product', click('[data-bj01-product="INV-TYLO"]')], ['dispose', click('[data-bj01-dispose-lot]')]] },
  { name: 'SC_bj01_expired_sheet', url: '?uif=UIF-01&screen=SCR-001', steps: [['product', click('[data-bj01-product="INV-TYLO"]')], ['lot', click('[data-bj01-lot="TY2408"]')], ['dispose', click('.ds24-sheet [data-bj01-dispose-lot]')]] },
  { name: 'SC_bj01_denied', url: '?mode=theme&app=flow&uif=UIF-01&screen=SCR-001&state=PERMISSION_DENIED', steps: [['exit', click('#app-screen [data-theme-sidebar-route="inventory"]')]] },
  { name: 'SC_bj01_barcode_type', url: '?uif=UIF-01&screen=SCR-001', steps: [['type', typeIn('[data-bj01-search]', '8938500004068')]] },
  { name: 'SC_pending_review_to_hub', url: '?mode=theme&app=flow&uif=UIF-02&screen=SCR-010&state=PENDING_APPROVAL', steps: [['to-hub', click('#app-screen [data-theme-sidebar-route="inventory"]')]] },
  // BJ-04 Giữ hàng (UIF-04) · BJ-05 Lấy hàng & bàn giao (UIF-05) — T7-P A1
  { name: 'SC_bj04', url: '?uif=UIF-04&screen=SCR-021', steps: [['back', click('#app-screen .app-back-button')]] },
  ...(() => {
    const V5 = '?uif=UIF-05&screen=';
    const order = (id) => ['order', click(`[data-io05-order="${id}"]`)];
    const act = (name, key) => [name, click(`[data-io05-action="${key}"]`)];
    return [
      { name: 'SC_bj05_list', url: V5 + 'SCR-025', steps: [['filter-handover', click('[data-io05-filter="HANDOVER"]')], ['filter-waiting', click('[data-io05-filter="WAITING"]')], ['filter-all', click('[data-io05-filter="ALL"]')], ['search', typeIn('[data-io05-search]', 'Minh')], ['clear-search', typeIn('[data-io05-search]', '')], order('SO-260827-21')] },
      { name: 'SC_bj05_waiting', url: V5 + 'SCR-025', steps: [['filter-waiting', click('[data-io05-filter="WAITING"]')], ['waiting-order', click('[data-io05-order="SO-260827-24"]')]] },
      { name: 'SC_bj05_pick', url: V5 + 'SCR-025', steps: [order('SO-260827-21'), ['allocation', click('[data-io05-pick-allocation="AL-21-02"]')], ['draft', typeIn('[data-io05-pick-draft]', '10')], act('update', 'update-pick-allocation')] },
      { name: 'SC_bj05_override', url: V5 + 'SCR-025', steps: [order('SO-260827-21'), ['allocation', click('[data-io05-pick-allocation="AL-21-01"]')], ['open-override', click('[data-io05-open-override]')], ['select-lot', click('[data-io05-select-lot="DH2509"]')], ['reason', typeIn('[data-io05-override-reason]', 'Lô gần hạn hơn')], act('confirm', 'confirm-lot-override')] },
      { name: 'SC_bj05_handover', url: V5 + 'SCR-025', steps: [order('SO-260827-21'), act('review', 'review-handover'), act('confirm', 'confirm-handover'), act('continue', 'continue-remaining')] },
      { name: 'SC_bj05_quick_pick', url: V5 + 'SCR-025', steps: [order('SO-260827-21'), ['pick-lot', click('[data-io05-pick-full="AL-21-02"]')], ['pick-gloves', click('[data-io05-pick-full="AL-21-03"]')], act('review', 'review-handover')] },
      { name: 'SC_bj05_ready_handover', url: V5 + 'SCR-025', steps: [['filter-handover', click('[data-io05-filter="HANDOVER"]')], order('SO-260827-22'), ['carrier', click('[data-io05-recipient="CARRIER"]')], act('confirm', 'confirm-handover')] },
      { name: 'SC_bj05_blocked', url: V5 + 'SCR-028&state=PARTIAL_BLOCKED', steps: [] },
      { name: 'SC_bj05_stale', url: V5 + 'SCR-026&state=STALE_RECOVERED', steps: [['allocation', click('[data-io05-pick-allocation="AL-21-01"]')], ['draft', typeIn('[data-io05-pick-draft]', '4')], act('update', 'update-pick-allocation'), act('confirm', 'confirm-physical-correction')] },
      { name: 'SC_bj05_next_order', url: V5 + 'SCR-025', steps: [order('SO-260827-22'), act('confirm', 'confirm-handover'), ['next', click('[data-io05-next-order]')]] },
      { name: 'SC_bj04_from_pick', url: V5 + 'SCR-025', steps: [order('SO-260827-21'), ['reservation', click('[data-io05-go-reservation]')], ['pick', click('[data-bj04-go-pick]')]] },
      { name: 'SC_bj05_theme', url: T + 'inventory', steps: [['quick', click('[data-t462-quick="UIF-05"]')], order('SO-260827-21'), ['reservation', click('[data-io05-go-reservation]')], ['back-to-pick', back], ['reservation-again', click('[data-io05-go-reservation]')], ['pick', click('[data-bj04-go-pick]')], ['back-queue', back], ['back-hub', back]] },
      { name: 'SC_bj04_after_handover', url: V5 + 'SCR-025', steps: [order('SO-260827-22'), act('confirm', 'confirm-handover'), act('to-queue', 'result-to-queue'), ['reservation', `window.__VET45_QA__.openBJ04('SO-260827-22')`]] },
    ];
  })(),
  { name: 'SC_bj05_unknown', url: '?uif=UIF-05&screen=SCR-029&state=UNKNOWN', steps: [['handoff', click('[data-v350-action="handoff-unknown"]')]] },
  // BJ-06 Hàng khách trả (UIF-06) — T7-P BJ-06 (v5.12.0); SC_journey_3 = hết chặng 3
  ...(() => {
    const U = '?uif=UIF-06&screen=';
    const A = '&entry=approver';
    const io = (key) => click(`[data-io06-action="${key}"]`);
    // Nhiều thao tác trong một bước (dựng lại đồng bộ sau mỗi lần bấm nên bấm liên tiếp được).
    const chain = (...sels) => `(()=>{const c=(s)=>document.querySelector(s)?.click();${sels.map((s) => `c(${JSON.stringify(s)});`).join('')}return true})()`;
    const lineDone = (id, lot = true) => chain(`[data-io06-line="${id}"]`, '[data-io06-fill-max]', ...(lot ? ['[data-io06-select-actual-lot]'] : []), '[data-io06-action="save-return-line"]');
    // iPhone: dòng → sheet → lựa chọn; web: nút trong bảng.
    const classify = (id, mode) => WEB ? chain(`[data-io06-class-line="${id}"][data-io06-class-mode="${mode}"]`) : chain(`[data-io06-class-line="${id}"]:not([data-io06-class-mode])`, `[role="dialog"] [data-io06-class-mode="${mode}"]`);
    const home = (...exits) => `(()=>{const sb=document.querySelector('#web-sidebar:not([hidden]) [data-theme-sidebar-route="inventory"]');if(sb){sb.click();return true}${exits.map((s) => `document.querySelector(${JSON.stringify(s)})?.click();`).join('')}for(let i=0;i<3&&!document.querySelector('[data-t462-workspace]');i++)document.querySelector('#app-screen .app-back-button')?.click();return !!document.querySelector('[data-t462-workspace]')})()`;
    return [
      { name: 'SC_bj06_list', url: U + 'SCR-030', steps: [['filter-actionable', click('[data-io06-filter="ACTIONABLE"]')], ['filter-waiting', click('[data-io06-filter="WAITING"]')], ['filter-all', click('[data-io06-filter="ALL"]')], ['search', typeIn('[data-io06-search]', 'Nam Việt')], ['clear-search', typeIn('[data-io06-search]', '')]] },
      { name: 'SC_bj06_line', url: U + 'SCR-030', steps: [['request', click('[data-io06-request="RET-260827-03"]')], ['line', click('[data-io06-line="RET-L1A"]')], ['qty-over', typeIn('[data-io06-qty]', '5')], ['qty-ok', typeIn('[data-io06-qty]', '2')], ['fill', click('[data-io06-fill-max]')], ['expected-lot', click('[data-io06-select-actual-lot]')], ['save', io('save-return-line')], ['back', back]] },
      { name: 'SC_bj06_full', url: U + 'SCR-030', steps: [['request', click('[data-io06-request="RET-260827-03"]')], ['line', click('[data-io06-line="RET-L1A"]')], ['fill', click('[data-io06-fill-max]')], ['lot', click('[data-io06-select-actual-lot]')], ['save', io('save-return-line')]] },
      { name: 'SC_bj06_other_lot', url: U + 'SCR-030', steps: [['request', click('[data-io06-request="RET-260827-03"]')], ['line', click('[data-io06-line="RET-L1A"]')], ['other-lot', click('[data-io06-select-other-lot]')], ['lot-code', typeIn('[data-io06-actual-lot]', 'DH2509')], ['reason-other', click('[data-io06-reason="OTHER"]')], ['reason-diff', click('[data-io06-reason="RETURNED_DIFFERENT_LOT"]')], ['evidence', `window.__VET45_QA__.setIO06Evidence('RET-L1A')`], ['back-expected', click('[data-io06-select-actual-lot]')], ['back', back]] },
      { name: 'SC_bj06_exception_submit', url: U + 'SCR-030', steps: [['request', click('[data-io06-request="RET-260827-03"]')], ['line', click('[data-io06-line="RET-L1A"]')], ['other-lot', click('[data-io06-select-other-lot]')], ['lot-code', typeIn('[data-io06-actual-lot]', 'DH2509')], ['evidence', `window.__VET45_QA__.setIO06Evidence('RET-L1A')`], ['fill', click('[data-io06-fill-max]')], ['save-exception', io('save-return-exception')], ['line-b', lineDone('RET-L1B')], ['line-2', lineDone('RET-L2')], ['line-3', lineDone('RET-L3', false)], ['submit', io('submit-return-exceptions')]] },
      { name: 'SC_bj06_receipt', url: U + 'SCR-030', steps: [['request', click('[data-io06-request="RET-260827-03"]')], ['line-a', lineDone('RET-L1A')], ['line-b', lineDone('RET-L1B')], ['line-2', lineDone('RET-L2')], ['line-3', lineDone('RET-L3', false)], ['commit', io('commit-receipt')], ['detail', click('[data-io06-result-detail]')], ['close', click('[data-io06-sheet-close]')], ['classify', io('open-classification')]] },
      { name: 'SC_bj06_classify', url: U + 'SCR-030', steps: [['request', click('[data-io06-request="RET-260827-05"]')], ['line-0', click('[data-io06-class-line="RET-L4"]:not([data-io06-class-mode])')], ['cancel', io('cancel-classification-item')], ['line-1', click('[data-io06-class-line="RET-L5"]:not([data-io06-class-mode])')], ['quarantine', click('[role="dialog"] [data-io06-class-mode="QUARANTINE"]')], ['line-0b', click('[data-io06-class-line="RET-L4"]:not([data-io06-class-mode])')], ['split', click('[role="dialog"] [data-io06-class-mode="SPLIT"]')], ['sellable', typeIn(WEB ? '[data-io06-class="sellable"]' : '[role="dialog"] [data-io06-class="sellable"]', '3')], ['quarantine-qty', typeIn(WEB ? '[data-io06-class="quarantine"]' : '[role="dialog"] [data-io06-class="quarantine"]', '1')], ['done', io('close-classification-item')], ['confirm', io('confirm-classification')], ['detail', click('[data-io06-result-detail]')], ['close', click('[data-io06-sheet-close]')], ['to-queue', io('result-to-return-queue')]] },
      { name: 'SC_bj06_split', url: U + 'SCR-030', steps: [['request', click('[data-io06-request="RET-260827-05"]')], ...(WEB
        ? [['nobivac-split', click('[data-io06-class-line="RET-L4"][data-io06-class-mode="SPLIT"]')], ['sellable', typeIn(WEB ? '[data-io06-class="sellable"]' : '[role="dialog"] [data-io06-class="sellable"]', '3')], ['quarantine', typeIn(WEB ? '[data-io06-class="quarantine"]' : '[role="dialog"] [data-io06-class="quarantine"]', '1')], ['gloves', classify('RET-L5', 'SELLABLE')]]
        : [['nobivac', click('[data-io06-class-line="RET-L4"]:not([data-io06-class-mode])')], ['split', click('[role="dialog"] [data-io06-class-mode="SPLIT"]')], ['sellable', typeIn(WEB ? '[data-io06-class="sellable"]' : '[role="dialog"] [data-io06-class="sellable"]', '3')], ['quarantine', typeIn(WEB ? '[data-io06-class="quarantine"]' : '[role="dialog"] [data-io06-class="quarantine"]', '1')], ['done', io('close-classification-item')], ['gloves', classify('RET-L5', 'SELLABLE')]]), ['confirm', io('confirm-classification')]] },
      { name: 'SC_bj06_approve', url: U + 'SCR-034&state=TASK_LIST' + A, steps: [['case', click('[data-io06-approval-case="EX-06-001"]')], ['approve', io('approve-exception')], ['exit', io('exit-approval-detail')]] },
      { name: 'SC_bj06_reject', url: U + 'SCR-034&state=TASK_LIST' + A, steps: [['case', click('[data-io06-approval-case="EX-06-001"]')], ['open-reject', io('open-reject')], ['backdrop', click('.sheet-backdrop[data-io06-action="close-reject"]')], ['open-again', io('open-reject')], ['reason', typeIn('[data-io06-reject-reason]', 'Ảnh không rõ lô')], ['confirm', io('confirm-reject')], ['exit', io('exit-approval-detail')]] },
      { name: 'SC_bj06_self_approval', url: U + 'SCR-034&state=READY', steps: [['approve', io('approve-exception')]] },
      { name: 'SC_bj06_cap_changed', url: U + 'SCR-031&state=RETURN_CAP_CHANGED', steps: [['refresh', io('refresh-return-request')]] },
      { name: 'SC_bj06_unknown', url: U + 'SCR-035&state=UNKNOWN', steps: [['handoff', click('[data-v350-action="handoff-unknown"]')]] },
      { name: 'SC_bj06_approver_entry', url: '?uif=UIF-06&entry=approver', steps: [['case', click('[data-io06-approval-case]')]] },
      { name: 'SC_bj06_owner_approve', url: T + 'inventory', steps: [['pending', click('[data-v464-pending-approvals]')], ['case', click('[data-theme-entry-flow="UIF-06"][data-t380-target-screen="SCR-034"]')], ['approve', io('approve-exception')], ['back-list', io('exit-approval-detail')]] },
      // Duyệt xong, thủ kho vào lại yêu cầu: duyệt chưa tự ghi nhận (UIF-06-T08).
      { name: 'SC_bj06_after_approval', url: U + 'SCR-034&state=TASK_LIST' + A, steps: [['case', click('[data-io06-approval-case="EX-06-001"]')], ['approve', io('approve-exception')], ['exit', io('exit-approval-detail')], ['to-queue', `navigate('SCR-030')`], ['request', click('[data-io06-request="RET-260827-07"]')], ['commit', io('commit-receipt')]] },
      { name: 'SC_bj06_waiting_open', url: U + 'SCR-030', steps: [['filter-waiting', click('[data-io06-filter="WAITING"]')], ['request', click('[data-io06-request="RET-260827-07"]')]] },
      // Hết chặng 3 "Bán và giao" (plan BJ-06 mục 5.4): Home Kho → lấy hàng → giữ hàng → bàn giao → khách trả → phân loại → duyệt ngoại lệ lô → Home.
      { name: 'SC_journey_3', url: T + 'inventory', steps: [
        ['pick', click('[data-t462-quick="UIF-05"]')], ['order', click('[data-io05-order="SO-260827-21"]')], ['reservation', click('[data-io05-go-reservation]')], ['to-pick', click('[data-bj04-go-pick]')],
        ['pick-full', chain('[data-io05-pick-full="AL-21-02"]', '[data-io05-pick-full="AL-21-03"]')], ['review', click('[data-io05-action="review-handover"]')], ['handover', click('[data-io05-action="confirm-handover"]')],
        ['home-1', home('[data-io05-action="result-to-queue"]')], ['movement', click('[data-t462-workspace="movement"]')], ['returns', click('#app-screen [data-theme-entry-flow="UIF-06"]')], ['request', click('[data-io06-request="RET-260827-03"]')],
        ['line-a', lineDone('RET-L1A')], ['line-b', lineDone('RET-L1B')], ['line-2', lineDone('RET-L2')], ['line-3', lineDone('RET-L3', false)], ['commit', io('commit-receipt')], ['classify', io('open-classification')],
        ['classify-all', chain(...[['RET-L1A', 'SELLABLE'], ['RET-L1B', 'SELLABLE'], ['RET-L2', 'QUARANTINE'], ['RET-L3', 'SELLABLE']].flatMap(([id, mode]) => WEB ? [`[data-io06-class-line="${id}"][data-io06-class-mode="${mode}"]`] : [`[data-io06-class-line="${id}"]:not([data-io06-class-mode])`, `[role="dialog"] [data-io06-class-mode="${mode}"]`]))], ['finish', io('confirm-classification')],
        ['home-2', home('[data-io06-action="result-to-return-queue"]')], ['pending', click('[data-v464-pending-approvals]')], ['case', click('[data-theme-entry-flow="UIF-06"][data-t380-target-screen="SCR-034"]')], ['approve', io('approve-exception')],
        ['home-end', home('[data-io06-action="exit-approval-detail"]')]] },
    ];
  })(),
  // BJ-07 Trả nhà cung cấp (UIF-07) + BJ-10 Tiêu hủy (UIF-10) — T7-P chặng 4 (v5.14.0 / v5.15.0); SC_journey_4 = hết chặng 4
  ...(() => {
    const S7 = '?uif=UIF-07&screen=', S10 = '?uif=UIF-10&screen=', S9 = '?uif=UIF-09&screen=';
    const k5chip = (k) => click(`[data-k5-filter="${k}"]`);
    const k5row = (key) => click(`[data-k5-row="${key}"]`);
    const k5act = (k) => click(`[data-k5-action="${k}"]`);
    const io7 = (k) => click(`[data-io07-action="${k}"]`);
    const quick = (id) => click(`[data-io07-verify-quick="${id}"]`);
    const b10 = (k) => click(`[data-bj10-action="${k}"]`);
    const ev09 = `(()=>window.__VET45_QA__.setK5Evidence('bj09'))()`;
    const ev10 = `(()=>window.__VET45_QA__.setK5Evidence('bj10'))()`;
    const ev10c = `(()=>window.__VET45_QA__.setK5Evidence('bj10c'))()`;
    const home = (...exits) => `(()=>{const sb=document.querySelector('#web-sidebar:not([hidden]) [data-theme-sidebar-route="inventory"]');if(sb){sb.click();return true}${exits.map((e) => `document.querySelector(${JSON.stringify(e)})?.click();`).join('')}for(let i=0;i<3&&!document.querySelector('[data-t462-workspace]');i++)document.querySelector('#app-screen .app-back-button')?.click();return !!document.querySelector('[data-t462-workspace]')})()`;
    const toList = '[data-k5-action="to-list"]';
    const sendDisposal = [['qty', click('[data-bj10-qty-fill]')], ['method', click('[data-bj10-method="SELF"]')], ['evidence', ev10], ['submit', b10('submit')]];
    return [
      { name: 'SC_bj07_verify', url: S7 + 'SCR-036', steps: [['request', k5row('req:RTV-260827-02')], ['alloc', click('[data-io07-allocation="RTV-A2"]')], ['wrong-lot', typeIn('[data-io07-scan-lot]', 'DH2509')], ['mismatch', io7('mark-mismatch')], ['select-lot', click('[data-io07-action="select-mismatch"][data-io07-mismatch-type="LOT"]')], ['close', io7('close-mismatch')]] },
      { name: 'SC_bj07_quick_verify', url: S7 + 'SCR-036', steps: [['request', k5row('req:RTV-260827-02')], ['dh2511', quick('RTV-A2')], ['ty2511', quick('RTV-A3')], ['gloves', quick('RTV-A4')]] },
      { name: 'SC_bj07_split_source', url: S7 + 'SCR-036', steps: [['request', k5row('req:RTV-260827-02')], ['alloc', click('[data-io07-allocation="RTV-A1"]')], ['sellable', typeIn('[data-io07-source-slice="SELLABLE"]', '2')], ['damaged', typeIn('[data-io07-source-slice="DAMAGED"]', '2')], ['verify', io7('confirm-allocation')]] },
      { name: 'SC_bj07_mismatch_wait', url: S7 + 'SCR-036', steps: [['request', k5row('req:RTV-260827-02')], ['alloc', click('[data-io07-allocation="RTV-A2"]')], ['mismatch', io7('mark-mismatch')], ['type', click('[data-io07-action="select-mismatch"][data-io07-mismatch-type="QUANTITY"]')], ['qty', typeIn('[data-io07-mismatch-qty]', '1')], ['send', io7('record-mismatch-observation')], ['back', back], ['waiting', k5chip('WAITING')]] },
      { name: 'SC_bj07_handover', url: S7 + 'SCR-036', steps: [['request', k5row('req:RTV-260903-03')], ['verify', quick('RTV-A7')], ['review', io7('review-handover')], ['back', back], ['review2', io7('review-handover')], ['confirm', io7('confirm-handover')], ['to-list', k5act('to-list')]] },
      { name: 'SC_bj07_next_request', url: S7 + 'SCR-036', steps: [['request', k5row('req:RTV-260903-03')], ['verify', quick('RTV-A7')], ['review', io7('review-handover')], ['carrier', click('[data-io07-recipient="CARRIER"]')], ['confirm', io7('confirm-handover')], ['detail', click('[data-io07-result-detail]')], ['close', click('[data-io07-sheet-close]')], ['next', click('[data-io07-next-request]')]] },
      { name: 'SC_bj07_source_changed', url: S7 + 'SCR-039&state=SOURCE_CHANGED', steps: [['back-prep', io7('back-to-preparation')]] },
      { name: 'SC_bj10_flow', url: S10 + 'SCR-036', steps: [['item', k5row('lot:tylo-ty2408')], ['request', k5act('request-disposal')], ...sendDisposal] },
      // Dầu sát khuẩn (không có giá vốn) đang có yêu cầu đổi tình trạng chờ duyệt nên 037 không có nút "Đề nghị tiêu hủy": đi thẳng bằng lối vào "request" như nút đó.
      { name: 'SC_bj10_price_missing', url: S10 + 'SCR-036', steps: [['select', `(()=>{k5SelectedLotId='oil-demo';return true})()`], ['request', `(()=>{bj10StartDraft();applyEntry('UIF-10','request',true);return true})()`], ['back', back]] },
      { name: 'SC_bj10_approve', url: '?uif=UIF-10&entry=approver', steps: [['seed', `(()=>{window.__VET45_QA__.seedBJ10Pending();return true})()`], ['approve', b10('approve')]] },
      { name: 'SC_bj10_reject', url: '?uif=UIF-10&entry=approver', steps: [['seed', `(()=>{window.__VET45_QA__.seedBJ10Pending();return true})()`], ['open', b10('reject-open')], ['reason', typeIn('[data-bj10-reject-reason]', 'Thiếu ảnh hiện trạng')], ['confirm', b10('reject-confirm')]] },
      { name: 'SC_bj10_complete', url: '?uif=UIF-10&entry=completion-operator', steps: [['to-completion', b10('to-completion')], ['fill', click('[data-bj10-actual-fill]')], ['proof', ev10c], ['complete', b10('complete')]] },
      { name: 'SC_bj10_from_list', url: S10 + 'SCR-036', steps: [['disposal', k5chip('DISPOSAL')], ['row', k5row('lot:glove-nitrile')], ['to-completion', b10('to-completion')]] },
      { name: 'SC_bj10_qty_over', url: S10 + 'SCR-040&state=COMPLETION', steps: [['over', typeIn('[data-bj10-actual]', '5')], ['fix', typeIn('[data-bj10-actual]', '3')], ['proof', ev10c], ['complete', b10('complete')]] },
      { name: 'SC_bj10_owner_self', url: T + 'inventory&entry=owner', steps: [['ws', click('[data-t462-workspace="control"]')], ['list', click('#app-screen [data-theme-entry-flow="UIF-09"]')], ['actor', `(()=>{window.__VET45_QA__.setActor('owner');return true})()`], ['item', k5row('lot:tylo-ty2408')], ['request', k5act('request-disposal')], ...sendDisposal, ['to-list', k5act('to-list')], ['home', home()], ['pending', click('[data-v464-pending-approvals]')], ['case', click('[data-theme-entry-flow="UIF-10"][data-t380-target-screen="SCR-040"]')], ['approve', b10('approve')], ['to-completion', b10('to-completion')], ['fill', click('[data-bj10-actual-fill]')], ['proof', ev10c], ['complete', b10('complete')]] },
      // Hết chặng 4 "Hàng có vấn đề" (plan BJ-07 + BJ-10 mục 6.4): Home → cách ly → hỏng (duyệt) → tiêu hủy (duyệt) → xác nhận → trả nhà cung cấp → Home.
      { name: 'SC_journey_4', url: T + 'inventory', steps: [
        ['attention', click('[data-t462-attention="UIF-09"]')], ['amox', k5row('lot:amox-am2505')],
        ['change', k5act('change-state')], ['damaged', click('[data-bj09-destination="DAMAGED"]')], ['fill', click('[data-bj09-qty-fill]')], ['reason', typeIn('[data-bj09-reason]', 'Bao bì rách, không còn dùng được')], ['photo', ev09], ['send', click('[data-bj09-action="submit"]')],
        ['home-1', home(toList)], ['pending', click('[data-v464-pending-approvals]')], ['case-1', click('[data-theme-entry-flow="UIF-09"][data-t380-target-screen="SCR-038"]', 1)], ['approve-1', click('[data-bj09-action="approve"]')],
        ['dispose', k5act('request-disposal')],
        ['qty', click('[data-bj10-qty-fill]')], ['method', click('[data-bj10-method="HIRE"]')], ['photo-2', ev10], ['send-2', b10('submit')],
        ['home-2', home(toList)], ['pending-2', click('[data-v464-pending-approvals]')], ['case-2', click('[data-theme-entry-flow="UIF-10"][data-t380-target-screen="SCR-040"]')], ['approve-2', b10('approve')],
        ['complete', b10('to-completion')], ['actual', click('[data-bj10-actual-fill]')], ['proof', ev10c], ['confirm', b10('complete')],
        ['to-list', k5act('to-list')], ['rtv-chip', k5chip('RTV')], ['rtv', k5row('req:RTV-260903-03')],
        ['verify', quick('RTV-A7')], ['review', io7('review-handover')], ['carrier', click('[data-io07-recipient="CARRIER"]')], ['handover', io7('confirm-handover')],
        ['home-end', home(toList)]] },
    ];
  })(),
  // CAP-01 Chính sách tồn & cận hạn — thiết kế lại (v5.7.0)
  ...(() => {
    const C = '?uif=CAP-01&screen=';
    const thr = (id) => `[data-cap-threshold="${id}"]`, tgt = (id) => `[data-cap-target="${id}"]`;
    return [
      { name: 'SC_cap_table', url: C + 'SCR-062', steps: [['threshold', typeIn(thr('INV-OXY'), '30')], ['target-low', typeIn(tgt('INV-OXY'), '20')], ['target-ok', typeIn(tgt('INV-OXY'), '60')], ['amox', typeIn(thr('INV-AMX'), '60')], ['open-save', click('[data-cap-open-save]')], ['cancel', click('[data-cap-sheet-close]')], ['discard', click('[data-cap-discard]')], ['redo', typeIn(thr('INV-OXY'), '30')], ['redo-target', typeIn(tgt('INV-OXY'), '60')], ['open-save2', click('[data-cap-open-save]')], ['save', click('[data-cap-save]')], ['filter-unset', click('[data-cap-filter="UNSET"]')], ['filter-all', click('[data-cap-filter="ALL"]')]] },
      { name: 'SC_cap_mobile_sheet', url: C + 'SCR-062', steps: [['row', click('[data-cap-edit-row="INV-OXY"]')], ['threshold', typeIn('[data-cap-s-threshold]', '30')], ['target-low', typeIn('[data-cap-s-target]', '20')], ['target-ok', typeIn('[data-cap-s-target]', '60')], ['save', click('[data-cap-save-single]')], ['row2', click('[data-cap-edit-row="INV-NOB"]')], ['close', click('[data-cap-sheet-backdrop]')]] },
      { name: 'SC_cap_single', url: '?uif=UIF-01&screen=SCR-001', steps: [['product', click('[data-bj01-product="INV-OXY"]')], ['set', click('[data-bj01-set-threshold]')], ['threshold', typeIn('[data-cap-s-threshold]', '30')], ['target-low', typeIn('[data-cap-s-target]', '20')], ['target-ok', typeIn('[data-cap-s-target]', '60')], ['save', click('[data-cap-save-single]')], ['edit', click('[data-bj01-set-threshold]')], ['back', back]] },
      { name: 'SC_cap_expiry', url: C + 'SCR-063', steps: [['days-zero', typeIn('[data-cap-expiry-days]', '0')], ['days-ok', typeIn('[data-cap-expiry-days]', '60')], ['block', click('[data-cap-expiry-action="BLOCK_SALE"]')], ['add', click('[data-cap-override-add]')], ['pick', click('[data-cap-override-pick="INV-NOB"]')], ['ovr-days', typeIn('[data-cap-ovr-days="INV-NOB"]', '45')], ['ovr-action', pick('[data-cap-ovr-action="INV-NOB"]', 'WARN')], ['remove', click('[data-cap-override-remove="INV-TYLO"]')], ['save', click('[data-cap-save-expiry]')], ['tab', click('[data-cap-tab="SCR-062"]')]] },
      { name: 'SC_cap_staff', url: '?uif=CAP-01&entry=staff', steps: [['tab', click('[data-cap-tab="SCR-063"]')], ['back', back]] },
      { name: 'SC_cap_locked', url: C + 'SCR-062&state=LOCKED', steps: [['tab', click('[data-cap-tab="SCR-063"]')]] },
      { name: 'SC_cap_conflict', url: C + 'SCR-062&state=CONFLICT', steps: [['reload', click('[data-cap-reload]')]] },
      { name: 'SC_cap_unknown', url: C + 'SCR-065&state=UNKNOWN', steps: [['handoff', click('[data-v350-action="handoff-unknown"]')]] },
      { name: 'SC_cap_rejected', url: C + 'SCR-065&state=REJECTED_EXECUTION', steps: [['back-to-policy', click('[data-cap-tab="SCR-062"]')]] },
      { name: 'SC_cap_hub', url: T + 'inventory', steps: [['setup', click('[data-t462-workspace="setup"]')], ['entry', click('[data-theme-entry-flow="CAP-01"]')], ['tab', click('[data-cap-tab="SCR-063"]')], ['back', back]] },
    ];
  })(),
  // Chặng 1 "Mở kho": khởi tạo → xem tồn → đặt ngưỡng → thấy chỉ báo đổi (bước 0–9 ở plan CAP-01 mục 3.5)
  { name: 'SC_journey_1', url: T + 'inventory&activation=pending&entry=owner', steps: [['init', click('[data-theme-entry-flow="UIF-12"][data-theme-entry-actor="owner"]')], ['start', click('[data-cf12-action="start"]')], ['check', click('[data-v350-action="cf12-check"]')], ['send', click('[data-v350-action="cf12-send-approval"]')], ['to-hub', click('[data-theme-sidebar-route="inventory"]')], ['list', click('[data-v464-pending-approvals]')], ['row', click('[data-t380-target-screen="SCR-070"]')], ['approve', click('[data-v350-action="cf12-approve"]')], ['wait', wait(500)], ['inventory', click('[data-cf12-action="see-inventory"]')], ['product', click('[data-bj01-product="INV-OXY"]')], ['set', click('[data-bj01-set-threshold]')], ['threshold', typeIn('[data-cap-s-threshold]', '30')], ['target', typeIn('[data-cap-s-target]', '60')], ['save', click('[data-cap-save-single]')], ['home', `(()=>{const sb=document.querySelector('#app-screen [data-theme-sidebar-route="inventory"]');if(sb){sb.click();return true}for(let i=0;i<2;i++)document.querySelector('#app-screen .app-back-button')?.click();return true})()`]] },
  // BJ-02 Nhận hàng mua (UIF-02) — thiết kế lại (v5.8.0)
  ...(() => {
    const R = '?uif=UIF-02&screen=';
    const line = (id) => click(`[data-bj02-line-id="${id}"]`), act = (a) => click(`[data-bj02-action="${a}"]`);
    // Nhận hết chứng từ PN-260816-04: Nobivac (mã lô + HSD + đạt) rồi Oxytetracycline LA, tới "Rà soát"; nobQty = số Đạt của Nobivac ("fill" = Nhận đủ).
    const toReview = (nobQty) => [
      ['open', click('[data-bj02-document-id="PN-260816-04"]')], ['nob', line('DOC-04-01')], ['lot-code', typeIn('[data-bj02-lot-field="code"]', 'DH2507')], ['lot-expiry', typeIn('[data-bj02-lot-field="expiry"]', '30/11/2026')],
      nobQty === 'fill' ? ['fill', act('fill-remaining')] : ['qty', typeIn('[data-bj02-qty="accepted"]', nobQty)], ['save-nob', act('save-line')],
      ['oxy', line('DOC-04-02')], ['fill-oxy', act('fill-remaining')], ['save-oxy', act('save-line')], ['review', click('[data-next="SCR-010"]')],
    ];
    const setThreshold = `(()=>{const p=bj01Products.find((x)=>x.id==='INV-OXY');p.threshold=30;p.target=60;p.monitoringConfigStatus='CONFIGURED';return true})()`;
    return [
      { name: 'SC_bj02_documents', url: R + 'SCR-007&flow=document', steps: [['search-empty', typeIn('[data-bj02-document-search]', 'zzz')], ['search-product', typeIn('[data-bj02-document-search]', 'oxytetra')], ['clear-search', typeIn('[data-bj02-document-search]', '')], ['open', click('[data-bj02-document-id]')], ['back', back]] },
      { name: 'SC_bj02_line', url: R + 'SCR-007&flow=document', steps: [['doc', click('[data-bj02-document-id]')], ['line', line('DOC-04-01')], ['lot-code', typeIn('[data-bj02-lot-field="code"]', 'DH2601')], ['expiry-bad', typeIn('[data-bj02-lot-field="expiry"]', '13/2026')], ['expiry', typeIn('[data-bj02-lot-field="expiry"]', '11/2026')], ['qty', typeIn('[data-bj02-qty="accepted"]', '110')], ['bad', typeIn('[data-bj02-qty="quarantine"]', '2')], ['save-line', act('save-line')], ['line2', line('DOC-04-02')], ['not-received', act('not-received')]] },
      { name: 'SC_bj02_not_received', url: R + 'SCR-007&flow=document', steps: [['doc', click('[data-bj02-document-id]')], ['line2', line('DOC-04-02')], ['qty', typeIn('[data-bj02-qty="accepted"]', '5')], ['not-received', act('not-received')], ['confirm-keep', act('confirm-close')], ['not-received2', act('not-received')], ['confirm', act('confirm-ok')]] },
      { name: 'SC_bj02_lot', url: R + 'SCR-007&flow=document', steps: [['doc', click('[data-bj02-document-id]')], ['line', line('DOC-04-01')], ['add-lot', act('add-editor-lot')], ['lot-code', typeIn('[data-bj02-lot-field="code"]', 'DH2601')], ['show-mfg', act('show-manufacture-date')], ['toggle-lot', act('toggle-lot')], ['back', back]] },
      { name: 'SC_bj02_doc_full', url: R + 'SCR-007', steps: [['set-threshold', setThreshold], ...toReview('fill'), ['submit', click('[data-action="submit"]')], ['wait', wait(1800)], ['inventory', act('see-inventory')]] },
      { name: 'SC_bj02_over_staff', url: R + 'SCR-007', steps: [...toReview('121'), ['submit', click('[data-action="submit"]')], ['to-kho', click('[data-v360-action="fallback-exit"]')]] },
      { name: 'SC_bj02_owner_flow', url: T + 'inventory', steps: [['receive', click('[data-t462-quick="UIF-02"]')], ...toReview('121'), ['submit', click('[data-action="submit"]')], ['to-kho', click('#app-screen [data-theme-sidebar-route="inventory"]')], ['pending', click('[data-v464-pending-approvals]')], ['mine', click('[data-v464-pending-receipt]')], ['approve', act('approve')], ['wait', wait(1800)], ['valuation', act('go-valuation')]] },
      // BJ-03 từ kết quả nhận hàng: Nobivac tick sẵn, Oxytetracycline LA "Cần đối chiếu" → Cách tính → ghi → Cập nhật giá vốn
      { name: 'SC_bj03_from_receipt', url: T + 'inventory', steps: [['receive', click('[data-t462-quick="UIF-02"]')], ...toReview('121'), ['submit', click('[data-action="submit"]')], ['to-kho', click('#app-screen [data-theme-sidebar-route="inventory"]')], ['pending', click('[data-v464-pending-approvals]')], ['mine', click('[data-v464-pending-receipt]')], ['approve', act('approve')], ['wait', wait(1800)], ['valuation', act('go-valuation')], ['breakdown', click('[data-bj03-breakdown]')], ['close', click('[data-bj03-sheet-close]')], ['open-confirm', click('[data-bj03-open-confirm]')], ['confirm', click('[data-bj03-confirm]')], ['cost', click('[data-bj03-go-cost]')]] },
      // Chặng 2 "Nhập hàng" một mạch (plan BJ-13 mục 3.6): Home Kho → nhận hàng (vượt +1) → duyệt → xác lập giá → điều chỉnh giá trị VC-8842 → Home.
      // Về Home: web bấm "Kho" ở thanh bên; iPhone "Tiếp tục xử lý" rồi quay lại tới Home (019 / 089 không có nút quay lại).
      ...(() => {
        const home = (fromBj03) => `(()=>{const sb=document.querySelector('#web-sidebar:not([hidden]) [data-theme-sidebar-route="inventory"]');if(sb){sb.click();return true}${fromBj03 ? `document.querySelector('[data-bj03-result-back]')?.click();` : `document.querySelector('[data-bj13-list]')?.click();`}for(let i=0;i<3&&!document.querySelector('[data-t462-workspace]');i++)document.querySelector('#app-screen .app-back-button')?.click();return !!document.querySelector('[data-t462-workspace]')})()`;
        return [{ name: 'SC_journey_2', url: T + 'inventory', steps: [['receive', click('[data-t462-quick="UIF-02"]')], ...toReview('121'), ['submit', click('[data-action="submit"]')], ['to-kho', click('#app-screen [data-theme-sidebar-route="inventory"]')], ['pending', click('[data-v464-pending-approvals]')], ['mine', click('[data-v464-pending-receipt]')], ['approve', act('approve')], ['wait', wait(1800)], ['valuation', act('go-valuation')], ['open-value', click('[data-bj03-open-confirm]')], ['confirm-value', click('[data-bj03-confirm]')], ['home', home(true)], ['valuation-ws', click('[data-t462-workspace="valuation"]')], ['adjustments', click('#app-screen [data-theme-entry-flow="UIF-13"]')], ['vc8842', click('[data-bj13-task="LC13-001"]')], ['open-adjust', click('[data-bj13-open-confirm]')], ['confirm-adjust', click('[data-bj13-confirm]')], ['home-end', home(false)]] }];
      })(),
      { name: 'SC_bj02_approve', url: T + 'inventory', steps: [['pending', click('[data-v464-pending-approvals]')], ['receipt', click('[data-v464-pending-receipt]')], ['approve', act('approve')], ['wait', wait(1800)]] },
      { name: 'SC_bj02_evidence', url: R + 'SCR-011', steps: [['open-ev', act('open-evidence')], ['preview', act('preview-file')], ['close-ev', act('close-evidence')]] },
      { name: 'SC_bj02_reject', url: R + 'SCR-011', steps: [['open-reject', act('open-reject')], ['close-reject', act('close-reject')], ['open-reject2', act('open-reject')], ['reason', typeIn('[data-bj02-reject-reason]', 'Sai số lượng')], ['confirm-reject', act('confirm-reject')]] },
      { name: 'SC_bj02_rejected_maker', url: R + 'SCR-010&state=REJECTED', steps: [['redo', act('redo')]] },
      { name: 'SC_bj02_quick', url: R + 'SCR-007', steps: [['quick', click('[data-flow="quick"]')], ['open-supplier', click('[data-bj02-open-supplier-sheet]')], ['pick-supplier', click('[data-bj02-supplier-option]')], ['camera', click('[data-bj02-evidence-camera]')], ['tick', click('[data-bj02-ownership]')], ['continue', click('[data-bj02-quick-continue]')], ['search', typeIn('[data-bj02-overview-product-search]', 'găng')], ['add', click('[data-bj02-overview-product-option="P-GLOVE-N"]')], ['qty', typeIn('[data-bj02-qty="accepted"]', '10')], ['save', act('save-line')], ['review', click('[data-next="SCR-010"]')], ['submit', click('[data-action="submit"]')]] },
      { name: 'SC_bj02_quick_form', url: R + 'SCR-008&flow=quick', steps: [['open-supplier', click('[data-bj02-open-supplier-sheet]')], ['backdrop', click('[data-bj02-supplier-backdrop]')], ['open-again', click('[data-bj02-open-supplier-sheet]')], ['pick-supplier', click('[data-bj02-supplier-option]')], ['camera', click('[data-bj02-evidence-camera]')], ['camera2', click('[data-bj02-evidence-camera]')], ['remove', click('[data-bj02-evidence-remove]')], ['tick', click('[data-bj02-ownership]')], ['untick', click('[data-bj02-ownership]')], ['back', back], ['quick-again', click('[data-flow="quick"]')], ['open-supplier2', click('[data-bj02-open-supplier-sheet]')], ['pick-other', click('[data-bj02-supplier-option]', 1)]] },
      { name: 'SC_bj02_scan', url: R + 'SCR-009&flow=document', steps: [['scan', act('scan-open')], ['sample', click('[data-bj02-scan-sample]')]] },
      { name: 'SC_bj02_scan_type', url: R + 'SCR-009&flow=document', steps: [['type-sku', typeIn('[data-bj02-line-search]', 'SP-000147')]] },
      { name: 'SC_bj02_review', url: R + 'SCR-010', steps: [['detail', click('[data-bj02-review-line]')], ['close', click('[data-bj02-review-close]')], ['change-src', act('change-source')], ['cancel-src', act('confirm-close')], ['change-again', act('change-source')], ['confirm-src', act('confirm-ok')]] },
      { name: 'SC_bj02_submit', url: R + 'SCR-010', steps: [['submit', click('[data-action="submit"]')]] },
      { name: 'SC_bj02_result', url: R + 'SCR-012&state=COMPLETED', steps: [['lines', act('open-lines')], ['close-lines', act('close-lines')], ['more', act('receive-more')]] },
      { name: 'SC_bj02_result_owner', url: R + 'SCR-012&state=COMPLETED&entry=owner', steps: [['valuation', act('go-valuation')]] },
      { name: 'SC_bj02_unknown', url: R + 'SCR-012&state=UNKNOWN', steps: [['refresh', click('[data-action="refresh"]')], ['handoff', click('[data-v350-action="handoff-unknown"]')]] },
      { name: 'SC_bj02_recon_back', url: R + 'SCR-013&state=TERMINAL', steps: [['back', back]] },
      { name: 'SC_bj02_pending', url: R + 'SCR-010&state=PENDING_APPROVAL', steps: [] },
      // T7-HF1 (chỉ khung web): 009 + 084 một màn hai cột — nhận hai dòng liên tiếp, "Xong" chuyển sang dòng chưa xử lý kế tiếp, rồi "Rà soát".
      { name: 'SC_hf1_receive_lines', webOnly: true, url: R + 'SCR-007&flow=document', steps: [['open', click('[data-bj02-document-id="PN-260816-04"]')], ['lot-code', typeIn('[data-bj02-lot-field="code"]', 'DH2507')], ['lot-expiry', typeIn('[data-bj02-lot-field="expiry"]', '30/11/2026')], ['fill', act('fill-remaining')], ['save-nob', act('save-line')], ['fill-oxy', act('fill-remaining')], ['save-oxy', act('save-line')], ['reselect-nob', line('DOC-04-01')], ['review', click('[data-next="SCR-010"]')]] },
      { name: 'SC_bj02_from_bj01', url: '?uif=UIF-01&screen=SCR-001', steps: [['set-threshold', setThreshold], ['product', click('[data-bj01-product="INV-OXY"]')], ['receive', click('[data-bj01-receive]')]] },
    ];
  })(),
  // T7-HF1 (chỉ khung web): SCR-001 danh sách – chi tiết, bấm dòng thứ 3 thì chi tiết bên phải đổi, vẫn ở SCR-001.
  { name: 'SC_hf1_bj01_select', webOnly: true, url: '?uif=UIF-01&screen=SCR-001', steps: [['select-3', click('tr[data-bj01-product]', 2)], ['select-nob', click('tr[data-bj01-product="INV-NOB"]')], ['lot', click('[data-bj01-lot]')], ['close-lot', click('.ds24-overlay[data-bj01-close-lot]')], ['provenance', click('[data-bj01-provenance]')], ['close-provenance', click('.ds24-overlay[data-bj01-close-provenance]')], ['filter-low', click('[data-bj01-filter="LOW"]')]] },
  // Cụm giá trị BJ-03 / 13 / 14 — T7-P A5
  ...(() => {
    const V3 = '?uif=UIF-03&screen=';
    const V13 = '?uif=UIF-13&screen=';
    const V14 = '?uif=UIF-14&screen=';
    return [
      { name: 'SC_bj03_list', url: V3 + 'SCR-014', steps: [['filter-ready', click('[data-bj03-filter="READY"]')], ['filter-issue', click('[data-bj03-filter="ISSUE"]')], ['filter-all', click('[data-bj03-filter="ALL"]')], ['search', typeIn('[data-bj03-search]', 'Minh')], ['search-empty', typeIn('[data-bj03-search]', 'zzz')], ['show-all', click('[data-bj03-show-all]')], ['receipt', click('[data-bj03-receipt="VAL03-R1"]')]] },
      { name: 'SC_bj03_direct', url: V3 + 'SCR-014', steps: [['receipt', click('[data-bj03-receipt="VAL03-R2"]')], ['add-basis', click('[data-bj03-add-basis="VAL03-G3"]')], ['save-empty', click('[data-bj03-save-basis]')], ['price', typeIn('[data-bj03-basis="price"]', '120000')], ['tax-excluded', click('[data-bj03-tax-mode="EXCLUDED"]')], ['tax-included', click('[data-bj03-tax-mode="INCLUDED"]')], ['source', typeIn('[data-bj03-basis="source"]', 'Báo giá NCC')], ['ref', typeIn('[data-bj03-basis="ref"]', 'HD-TEST-01')], ['reason', typeIn('[data-bj03-basis="reason"]', 'Nhập nhanh thiếu căn cứ')], ['save', click('[data-bj03-save-basis]')], ['open-confirm', click('[data-bj03-open-confirm]')], ['confirm', click('[data-bj03-confirm]')], ['to-list', click('[data-bj03-result-list]')]] },
      { name: 'SC_bj03_confirm', url: V3 + 'SCR-015', steps: [['breakdown', click('[data-bj03-breakdown]')], ['close', click('[data-bj03-sheet-close]')], ['untick', click('[data-bj03-select="VAL03-G1"]')], ['tick', click('[data-bj03-select="VAL03-G1"]')], ['open-confirm', click('[data-bj03-open-confirm]')], ['back', click('[data-bj03-sheet-close]')], ['open-again', click('[data-bj03-open-confirm]')], ['confirm', click('[data-bj03-confirm]')], ['continue', click('[data-bj03-result-back]')]] },
      { name: 'SC_bj03_untick', url: V3 + 'SCR-015', steps: [['untick', click('[data-bj03-select="VAL03-G1"]')]] },
      { name: 'SC_bj03_stale', url: V3 + 'SCR-015', steps: [['open-confirm', click('[data-bj03-open-confirm]')], ['source-change', `(()=>{val03ApplySourceUpdate('VAL03-G1',84000);return true})()`], ['confirm', click('[data-bj03-confirm]')], ['recheck', click('[data-bj03-recheck]')]] },
      { name: 'SC_bj03_result', url: V3 + 'SCR-019&state=COMPLETED', steps: [['detail', click('[data-bj03-result-detail]')], ['close', click('[data-bj03-sheet-close]')], ['cost', click('[data-bj03-go-cost]')]] },
      { name: 'SC_bj03_staff', url: V3 + 'SCR-014&entry=staff', steps: [] },
      { name: 'SC_bj03_unknown', url: V3 + 'SCR-019&state=UNKNOWN', steps: [['handoff', click('[data-v350-action="handoff-unknown"]')]] },
      { name: 'SC_bj13_flow', url: V13 + 'SCR-085', steps: [['filter-actionable', click('[data-bj13-filter="ACTIONABLE"]')], ['filter-all', click('[data-bj13-filter="ALL"]')], ['task', click('[data-bj13-task="LC13-001"]')], ['open-confirm', click('[data-bj13-open-confirm]')], ['confirm-close', click('[data-bj13-confirm-close]')], ['open-again', click('[data-bj13-open-confirm]')], ['confirm', click('[data-bj13-confirm]')], ['to-list', click('[data-bj13-list]')]] },
      { name: 'SC_bj13_waiting', url: V13 + 'SCR-085', steps: [['filter-waiting', click('[data-bj13-filter="WAITING"]')], ['task', click('[data-bj13-task="LC13-003"]')], ['back', back]] },
      { name: 'SC_bj13_decrease', url: V13 + 'SCR-085', steps: [['task', click('[data-bj13-task="LC13-004"]')], ['open-confirm', click('[data-bj13-open-confirm]')], ['confirm', click('[data-bj13-confirm]')]] },
      { name: 'SC_bj13_stale', url: V13 + 'SCR-086', steps: [['open-confirm', click('[data-bj13-open-confirm]')], ['source-change', `(()=>{val13ApplySourceUpdate();return true})()`], ['confirm', click('[data-bj13-confirm]')]] },
      { name: 'SC_bj13_staff', url: V13 + 'SCR-085&entry=staff', steps: [] },
      { name: 'SC_bj13_unknown', url: V13 + 'SCR-089&state=UNKNOWN', steps: [['handoff', click('[data-v350-action="handoff-unknown"]')]] },
      { name: 'SC_bj13_result', url: V13 + 'SCR-089&state=COMPLETED', steps: [['detail', click('[data-bj13-result-detail]')], ['close', click('[data-bj13-sheet-close]')], ['cost', click('[data-bj13-go-cost]')]] },
      { name: 'SC_bj14_flow', url: V14 + 'SCR-072', steps: [['run', click('[data-v461-val14-run="COST-0826"]')], ['compare', click('[data-v461-compare] summary')], ['open-publish', click('[data-v461-val14-open-publish]')], ['publish-close', click('[data-v461-val14-publish-close]')], ['open-again', click('[data-v461-val14-open-publish]')], ['publish', click('[data-v461-val14-publish]')], ['to-list', click('[data-v461-val14-list]')]] },
      { name: 'SC_bj14_period', url: V14 + 'SCR-072', steps: [['close-period', click('[data-v461-val14-close-period]')], ['period', pick('[data-v461-val14-period]', '09/2026')], ['calculate', click('[data-v461-val14-calculate]')]] },
      { name: 'SC_bj14_dirty', url: '?uif=UIF-14&entry=dirty-scope', steps: [['calculate', click('[data-v461-val14-calculate]')]] },
      { name: 'SC_bj03_retired', url: '?uif=UIF-03&screen=SCR-018', steps: [] },
      { name: 'SC_bj13_retired', url: '?uif=UIF-13&screen=SCR-088', steps: [] },
    ];
  })(),
  // BJ-07 / 09 / 10 — T7-P A6
  ...(() => {
    const S9 = '?uif=UIF-09&screen=';
    const k5chip = (k) => click(`[data-k5-filter="${k}"]`);
    const k5row = (key) => click(`[data-k5-row="${key}"]`);
    const k5act = (k) => click(`[data-k5-action="${k}"]`);
    const evidence09 = `(()=>window.__VET45_QA__.setK5Evidence('bj09'))()`;
    const home9 = (...exits) => `(()=>{const sb=document.querySelector('#web-sidebar:not([hidden]) [data-theme-sidebar-route="inventory"]');if(sb){sb.click();return true}${exits.map((e) => `document.querySelector(${JSON.stringify(e)})?.click();`).join('')}for(let i=0;i<3&&!document.querySelector('[data-t462-workspace]');i++)document.querySelector('#app-screen .app-back-button')?.click();return !!document.querySelector('[data-t462-workspace]')})()`;
    const toDamaged = [['change', k5act('change-state')], ['dest', click('[data-bj09-destination="DAMAGED"]')], ['qty', click('[data-bj09-qty-fill]')], ['reason', typeIn('[data-bj09-reason]', 'Bao bì rách, không còn dùng được')], ['evidence', evidence09], ['submit', click('[data-bj09-action="submit"]')]];
    const approveFromHome = [['to-list', k5act('to-list')], ['home', home9()], ['pending', click('[data-v464-pending-approvals]')], ['case', click('[data-theme-entry-flow="UIF-09"][data-t380-target-screen="SCR-038"]', 1)], ['approve', click('[data-bj09-action="approve"]')], ['disposal', k5act('request-disposal')]];
    return [
      { name: 'SC_bj07_list', url: '?uif=UIF-07&screen=SCR-036', steps: [['filter-rtv', k5chip('RTV')], ['filter-waiting', k5chip('WAITING')], ['filter-all', k5chip('ALL')], ['search', typeIn('[data-k5-search]', 'Minh')], ['clear-search', typeIn('[data-k5-search]', '')], ['request', k5row('req:RTV-260827-02')]] },
      { name: 'SC_bj09_flow', url: S9 + 'SCR-036', steps: [['filter-open', k5chip('OPEN')], ['filter-all', k5chip('ALL')], ['search', typeIn('[data-k5-search]', 'Amox')], ['clear-search', typeIn('[data-k5-search]', '')], ['item', k5row('lot:amox-am2505')], ...toDamaged] },
      { name: 'SC_bj09_approve', url: '?uif=UIF-09&entry=approver', steps: [['open-reject', click('[data-bj09-action="reject-open"]')], ['reason', typeIn('[data-bj09-reject-reason]', 'Thiếu bằng chứng')], ['close-reject', click('[data-bj09-action="reject-close"]')], ['approve', click('[data-bj09-action="approve"]')]] },
      { name: 'SC_bj09_reject', url: '?uif=UIF-09&entry=approver', steps: [['open-reject', click('[data-bj09-action="reject-open"]')], ['reason', typeIn('[data-bj09-reject-reason]', 'Thiếu ảnh bằng chứng')], ['confirm', click('[data-bj09-action="reject-confirm"]')]] },
      { name: 'SC_k5_list', url: S9 + 'SCR-036', steps: [['open', k5chip('OPEN')], ['rtv', k5chip('RTV')], ['disposal', k5chip('DISPOSAL')], ['waiting', k5chip('WAITING')], ['all', k5chip('ALL')], ['search', typeIn('[data-k5-search]', 'TY2408')], ['clear', typeIn('[data-k5-search]', '')], ['lot', k5row('lot:tylo-ty2408')]] },
      { name: 'SC_k5_filter_empty', url: S9 + 'SCR-036', steps: [['search', typeIn('[data-k5-search]', 'zzz')], ['clear', k5act('clear-filter')]] },
      { name: 'SC_bj09_quarantine_to_damaged', url: T + 'inventory', steps: [['ws', click('[data-t462-workspace="control"]')], ['list', click('#app-screen [data-theme-entry-flow="UIF-09"]')], ['item', k5row('lot:amox-am2505')], ...toDamaged, ...approveFromHome] },
      { name: 'SC_bj09_owner_self', url: T + 'inventory&entry=owner', steps: [['ws', click('[data-t462-workspace="control"]')], ['list', click('#app-screen [data-theme-entry-flow="UIF-09"]')], ['actor', `(()=>{window.__VET45_QA__.setActor('owner');return true})()`], ['item', k5row('lot:amox-am2505')], ...toDamaged, ...approveFromHome] },
      { name: 'SC_bj09_no_approval', url: S9 + 'SCR-036', steps: [['item', k5row('lot:amox-am2505')], ['change', k5act('change-state')], ['dest', click('[data-bj09-destination="DEMO"]')], ['qty', typeIn('[data-bj09-qty]', '1')], ['reason', typeIn('[data-bj09-reason]', 'Dùng làm hàng trưng bày')], ['submit', click('[data-bj09-action="submit"]')], ['to-list', k5act('to-list')]] },
      { name: 'SC_bj09_from_bj01', url: '?uif=UIF-01&screen=SCR-001', steps: [['product', click('[data-bj01-product="INV-NOB"]')], ['lot', click('[data-bj01-lot="DH2507"]')], ['change', click('.ds24-sheet [data-bj01-change-state]')], ['dest', click('[data-bj09-destination="QUARANTINE"]')], ['qty', click('[data-bj09-qty-fill]')], ['back', click('#app-screen .app-back-button')]] },
      { name: 'SC_bj09_expired_to_disposal', url: '?uif=UIF-01&screen=SCR-001', steps: [['product', click('[data-bj01-product="INV-TYLO"]')], ['dispose', click('[data-bj01-dispose-lot]')], ['disposal', k5act('request-disposal')]] },
      { name: 'SC_k5_hub_rtv', url: T + 'inventory', steps: [['ws-movement', click('[data-t462-workspace="movement"]')], ['rtv', click('#app-screen [data-theme-entry-flow="UIF-07"]')], ['home', home9()], ['ws-control', click('[data-t462-workspace="control"]')], ['list', click('#app-screen [data-theme-entry-flow="UIF-09"]')]] },
      { name: 'SC_bj09_movement', url: '?uif=UIF-09&screen=SCR-056', steps: [] },
    ];
  })(),
  // BJ-08 Kiểm kê — T7-P chặng 5
  ...(() => {
    const S8 = '?uif=UIF-08&screen=';
    const a8 = (k) => click(`[data-bj08-action="${k}"]`);
    const enter = (sel) => `(()=>{const i=document.querySelector(${JSON.stringify(sel)});if(!i)return false;i.focus();i.dispatchEvent(new KeyboardEvent('keydown',{key:'Enter',bubbles:true}));return true})()`;
    const count = (key, v) => typeIn(`[data-bj08-count="${key}"]`, v);
    const recount = (key, v) => typeIn(`[data-bj08-recount="${key}"]`, v);
    const home = (...exits) => `(()=>{const sb=document.querySelector('#web-sidebar:not([hidden]) [data-theme-sidebar-route="inventory"]');if(sb){sb.click();return true}${exits.map((e) => `document.querySelector(${JSON.stringify(e)})?.click();`).join('')}for(let i=0;i<3&&!document.querySelector('[data-t462-workspace]');i++)document.querySelector('#app-screen .app-back-button')?.click();return !!document.querySelector('[data-t462-workspace]')})()`;
    // Đếm Oxy 10 → Enter → TY2511 4 → Enter → TY2408 11 (gõ liên tục bằng Enter), rồi nộp lần đầu.
    const typeFirst = [['oxy', count('oxy', '10')], ['enter-1', enter('[data-bj08-count="oxy"]')], ['ty2511', count('ty2511', '4')], ['enter-2', enter('[data-bj08-count="ty2511"]')], ['ty2408', count('ty2408', '11')]];
    const submitFirst = [['submit', a8('submit-first')], ['confirm', a8('confirm-first')]];
    const recountSteps = [['same-oxy', click('[data-bj08-same="oxy"]')], ['ty2511', recount('ty2511', '3')], ['submit', a8('submit-recount')], ['confirm', a8('confirm-recount')]];
    const create = [['scope', click('[data-bj08-scope="GROUP"]')], ['scope-open', a8('scope-open')], ['scope-pick', click('[data-bj08-scope-pick="antibiotic"]')], ['open', a8('open')], ['confirm-open', a8('confirm-open')]];
    return [
      { name: 'SC_bj08_list', url: S8 + 'SCR-042', steps: [['filter-done', click('[data-bj08-filter="DONE"]')], ['filter-pending', click('[data-bj08-filter="PENDING"]')], ['filter-all', click('[data-bj08-filter="ALL"]')], ['search', typeIn('[data-bj08-search]', 'KK-260915')], ['clear-search', typeIn('[data-bj08-search]', '')], ['open', click('[data-bj08-row="KK-260916-01"]')]] },
      { name: 'SC_bj08_create', url: S8 + 'SCR-043', steps: create },
      { name: 'SC_bj08_blind', url: S8 + 'SCR-044', steps: [...typeFirst, ...submitFirst] },
      { name: 'SC_bj08_recount', url: S8 + 'SCR-045', steps: recountSteps },
      { name: 'SC_bj08_matched', url: S8 + 'SCR-045', steps: [['open', a8('matched-open')], ['close', a8('dialog-close')]] },
      { name: 'SC_bj08_approve', url: '?uif=UIF-08&entry=approver', steps: [['approve', a8('approve')]] },
      { name: 'SC_bj08_self_approve', url: S8 + 'SCR-046&state=SELF_APPROVAL_NOT_ALLOWED', steps: [['to-list', a8('to-list')]] },
      { name: 'SC_bj08_review', url: '?uif=UIF-08&entry=approver', steps: [['request', a8('review-open')], ['reason', typeIn('[data-bj08-review-reason]', 'Cần đếm lại kệ A')], ['confirm', a8('confirm-review')]] },
      { name: 'SC_bj08_cancel', url: S8 + 'SCR-044', steps: [['cancel', a8('cancel-open')], ['reason', typeIn('[data-bj08-cancel-reason]', 'Sai phạm vi phiên')], ['confirm', a8('confirm-cancel')]] },
      { name: 'SC_bj08_unknown', url: S8 + 'SCR-047&state=UNKNOWN', steps: [['handoff', click('[data-v350-action="handoff-unknown"]')]] },
      { name: 'SC_bj08_zero', url: S8 + 'SCR-044', steps: [['fill', `(()=>window.__VET45_QA__.fillBJ08Book())()`], ...submitFirst] },
      { name: 'SC_bj08_scan', url: S8 + 'SCR-044', steps: [['scan', `(()=>window.__VET45_QA__.scanBJ08('SP-000122'))()`], ['ty2511', count('ty2511', '4')], ['chip-done', click('[data-bj08-count-filter="DONE"]')]] },
      { name: 'SC_bj08_unexpected', url: S8 + 'SCR-044', steps: [['add', a8('add-open')], ['pick', click('[data-bj08-add-pick="SP-00606"]')], ['state', click('[data-bj08-for="x-SP-00606"][data-bj08-unexpected-state="SELLABLE"]')], ['qty', count('x-SP-00606', '1')], ...typeFirst, ...submitFirst] },
      { name: 'SC_bj08_price_basis', url: S8 + 'SCR-045&state=PRICE_BASIS_REQUIRED', steps: [['cancel', a8('cancel-open')], ['reason', typeIn('[data-bj08-cancel-reason]', 'Chưa có giá vốn hàng thừa')], ['confirm', a8('confirm-cancel')]] },
      { name: 'SC_bj08_owner_self', url: T + 'inventory&entry=owner', steps: [['quick', click('[data-t462-quick="UIF-08"]')], ['actor', `(()=>{window.__VET45_QA__.setActor('owner');return true})()`], ['create', a8('create')], ...create, ...typeFirst, ...submitFirst, ...recountSteps, ['to-list', a8('to-list')], ['home', home()], ['pending', click('[data-v464-pending-approvals]')], ['case', click('[data-theme-entry-flow="UIF-08"][data-t380-target-screen="SCR-046"]')], ['approve', a8('approve')]] },
      { name: 'SC_bj08_from_home', url: T + 'inventory', steps: [['pending', click('[data-v464-pending-approvals]')], ['case', click('[data-theme-entry-flow="UIF-08"][data-t380-target-screen="SCR-046"]')], ['back', back]] },
      { name: 'SC_bj08_pending_view', url: S8 + 'SCR-042', steps: [['filter', click('[data-bj08-filter="PENDING"]')], ['row', click('[data-bj08-row="KK-260915-02"]')]] },
    ];
  })(),
  // BJ-11 Hủy & sửa sai — T7-P chặng 5
  ...(() => {
    const S11 = '?uif=UIF-11&screen=';
    const a11 = (k) => click(`[data-bj11-action="${k}"]`);
    const row = (id) => click(`[data-bj11-row="${id}"]`);
    const home = (...exits) => `(()=>{const sb=document.querySelector('#web-sidebar:not([hidden]) [data-theme-sidebar-route="inventory"]');if(sb){sb.click();return true}${exits.map((e) => `document.querySelector(${JSON.stringify(e)})?.click();`).join('')}for(let i=0;i<3&&!document.querySelector('[data-t462-workspace]');i++)document.querySelector('#app-screen .app-back-button')?.click();return !!document.querySelector('[data-t462-workspace]')})()`;
    const why = 'Hóa đơn nhà cung cấp ghi 18 hộp';
    const fill = [['qty', typeIn('[data-bj11-qty]', '18')], ['reason', typeIn('[data-bj11-reason]', why)]];
    const correct = [['open', row('IO-260904-021')], ['correct', a11('correct')], ...fill, ['submit', a11('submit')]];
    return [
      { name: 'SC_bj11_list', url: S11 + 'SCR-048', steps: [['filter-cancel', click('[data-bj11-filter="CANCEL"]')], ['filter-correct', click('[data-bj11-filter="CORRECT"]')], ['filter-waiting', click('[data-bj11-filter="WAITING"]')], ['filter-all', click('[data-bj11-filter="ALL"]')], ['search', typeIn('[data-bj11-search]', 'PN-260904')], ['clear-search', typeIn('[data-bj11-search]', '')], ['open', row('IO-260904-021')]] },
      { name: 'SC_bj11_correct', url: S11 + 'SCR-048', steps: correct },
      { name: 'SC_bj11_full', url: S11 + 'SCR-048', steps: [['open', row('IO-260904-021')], ['correct', a11('correct')], ['full', click('[data-bj11-strategy="FULL"]')], ...fill, ['submit', a11('submit')]] },
      { name: 'SC_bj11_cancel', url: S11 + 'SCR-048', steps: [['open', row('IO-260906-022')], ['cancel', a11('cancel-open')], ['reason', typeIn('[data-bj11-cancel-reason]', 'Gửi nhầm yêu cầu')], ['confirm', a11('cancel-confirm')], ['to-list', a11('to-list')]] },
      { name: 'SC_bj11_blocked', url: S11 + 'SCR-048', steps: [['open', row('IO-260902-005')], ['to-return', a11('to-return')]] },
      { name: 'SC_bj11_unknown', url: S11 + 'SCR-048', steps: [['open', row('IO-260906-031')], ['handoff', click('[data-v350-action="handoff-unknown"]')]] },
      { name: 'SC_bj11_back', url: S11 + 'SCR-050', steps: [['b1', back], ['b2', back], ['b3', back]] },
      { name: 'SC_bj11_approve', url: '?uif=UIF-11&entry=approver', steps: [['approve', a11('approve')], ['to-list', a11('to-list')]] },
      { name: 'SC_bj11_reject', url: '?uif=UIF-11&entry=approver', steps: [['open', a11('reject-open')], ['close', a11('dialog-close')], ['open2', a11('reject-open')], ['reason', typeIn('[data-bj11-reject-reason]', 'Thiếu chứng từ')], ['confirm', a11('confirm-reject')]] },
      { name: 'SC_bj11_self_approve', url: S11 + 'SCR-051', steps: [['to-list', a11('to-list')]] },
      { name: 'SC_bj11_decided', url: S11 + 'SCR-051&state=APPROVAL_ALREADY_DECIDED', steps: [['result', a11('view-result')]] },
      { name: 'SC_bj11_context', url: '?uif=UIF-11&entry=operation-context', steps: [['back', back]] },
      { name: 'SC_bj11_owner_self', url: T + 'inventory&entry=owner', steps: [['ws', click('[data-t462-workspace="control"]')], ['list', click('#app-screen [data-theme-entry-flow="UIF-11"]')], ['actor', `(()=>{window.__VET45_QA__.setActor('owner');return true})()`], ...correct, ['to-list', a11('to-list')], ['home', home()], ['pending', click('[data-v464-pending-approvals]')], ['case', click('[data-theme-entry-flow="UIF-11"][data-t380-target-screen="SCR-051"]')], ['approve', a11('approve')]] },
      { name: 'SC_bj11_from_home', url: T + 'inventory', steps: [['pending', click('[data-v464-pending-approvals]')], ['case', click('[data-theme-entry-flow="UIF-11"][data-t380-target-screen="SCR-051"]')], ['back', back]] },
      { name: 'SC_bj11_rejected_redo', url: S11 + 'SCR-053&state=REJECTED', steps: [['redo', a11('redo')]] },
      { name: 'SC_bj11_dependency', url: S11 + 'SCR-048', steps: [['open', row('IO-260903-017')], ['correct', a11('correct')], ['to-detail', a11('to-detail')]] },
      { name: 'SC_bj11_from_case', url: '?uif=UIF-11&entry=correction-from-case', steps: [['reason', typeIn('[data-bj11-reason]', why)], ['submit', a11('submit')], ['to-case', a11('to-case')]] },
      { name: 'SC_bj11_case_back', url: '?uif=UIF-16&screen=SCR-078', steps: [['case', click('[data-recon-row="DIFF:REC-260907-04"]')], ['fix', click('[data-bj16-action="fix-source"]')], ['back', back]] },
    ];
  })(),
  { name: 'SC_bj12_prepare', url: '?uif=UIF-12&screen=SCR-066', steps: [['start', click('[data-cf12-action="start"]')], ['file', click('[data-cf12-action="choose-file"]')], ['clear-qty', typeIn('[data-cf12-control-qty]', '')], ['check-err', click('[data-v350-action="cf12-check"]')], ['qty', typeIn('[data-cf12-control-qty]', '4820')], ['check', click('[data-v350-action="cf12-check"]')], ['send', click('[data-v350-action="cf12-send-approval"]')]] },
  { name: 'SC_bj12_mismatch', url: '?uif=UIF-12&screen=SCR-067', steps: [['qty', typeIn('[data-cf12-control-qty]', '4800')], ['check', click('[data-v350-action="cf12-check"]')], ['back', click('[data-cf12-action="back-file"]')]] },
  { name: 'SC_bj12_failed', url: '?uif=UIF-12&screen=SCR-068&state=VALIDATION_FAILED', steps: [['back', click('[data-cf12-action="back-file"]')]] },
  { name: 'SC_bj12_approve', url: '?uif=UIF-12&screen=SCR-067', steps: [['check', click('[data-v350-action="cf12-check"]')], ['send', click('[data-v350-action="cf12-send-approval"]')], ['approver', `window.__VET45_QA__.applyEntry('UIF-12','approver')`], ['approve', click('[data-v350-action="cf12-approve"]')], ['wait', wait(500)], ['inventory', click('[data-cf12-action="see-inventory"]')]] },
  { name: 'SC_bj12_stale', url: '?uif=UIF-12&entry=approver', steps: [['approve', click('[data-v350-action="cf12-approve"]')]] },
  { name: 'SC_bj12_self', url: '?uif=UIF-12&screen=SCR-070', steps: [['approve', click('[data-v350-action="cf12-approve"]')], ['exit', click('[data-v360-action="fallback-exit"]')]] },
  { name: 'SC_bj12_reject', url: '?uif=UIF-12&entry=approver', steps: [['open', click('[data-cf12-action="open-reject"]')], ['close', click('[data-cf12-action="close-reject"]')], ['open2', click('[data-cf12-action="open-reject"]')], ['reason', typeIn('[data-cf12-reject-reason]', 'Sai nhóm vaccine')], ['confirm', click('[data-v350-action="cf12-confirm-reject"]')], ['exit', click('[data-v360-action="fallback-exit"]')], ['fix', click('[data-cf12-action="fix-rejected"]')]] },
  { name: 'SC_bj12_owner', url: T + 'inventory&activation=pending', steps: [['entry', click('[data-theme-entry-flow="UIF-12"][data-theme-entry-actor="owner"]')], ['start', click('[data-cf12-action="start"]')], ['check', click('[data-v350-action="cf12-check"]')], ['filter', click('[data-cf12-filter="nonSellable"]')], ['send', click('[data-v350-action="cf12-send-approval"]')], ['to-hub', click('[data-theme-sidebar-route="inventory"]')], ['list', click('[data-v464-pending-approvals]')], ['row', click('[data-t380-target-screen="SCR-070"]')], ['approve', click('[data-v350-action="cf12-approve"]')], ['wait', wait(500)], ['policy', click('[data-cf12-action="go-policy"]')]] },
  { name: 'SC_bj12_template', url: '?uif=UIF-12&screen=SCR-066', steps: [['template', click('[data-cf12-action="template"]')], ['start', click('[data-cf12-action="start"]')], ['template2', click('[data-cf12-action="template"]')], ['columns', click('[data-cf12-action="open-columns"]')], ['close-columns', click('[data-cf12-action="close-columns"]')]] },
  { name: 'SC_hub_not_activated', url: T + 'inventory&activation=pending', steps: [['quick-disabled', click('[data-t462-quick="UIF-02"]')], ['entry', click('[data-theme-entry-flow="UIF-12"][data-theme-entry-actor="owner"]')], ['back', back]] },
  { name: 'SC_bj12_pending_list', url: T + 'inventory&activation=pending', steps: [['entry', click('[data-theme-entry-flow="UIF-12"][data-theme-entry-actor="owner"]')], ['start', click('[data-cf12-action="start"]')], ['check', click('[data-v350-action="cf12-check"]')], ['send', click('[data-v350-action="cf12-send-approval"]')], ['to-hub', click('[data-theme-sidebar-route="inventory"]')], ['list', click('[data-v464-pending-approvals]')], ['row', click('[data-t380-target-screen="SCR-070"]')], ['approve', click('[data-v350-action="cf12-approve"]')], ['wait', wait(500)], ['result-hub', click('[data-cf12-action="see-inventory"]')]] },
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
  // BJ-16 / BJ-17 — T7-P chặng 5 (v5.18.0): một danh sách "Hồ sơ cần kiểm tra"; SC_journey_5 = hết chặng 5
  ...(() => {
    const D = '?uif=UIF-16&screen=';
    const U = '?uif=UIF-17&screen=';
    const bump16 = `(()=>{window.__VET45_QA__.bumpCR16Evidence();return true})()`;
    const bump17 = `(()=>{window.__VET45_QA__.bumpCR17Evidence();return true})()`;
    const finish16 = `(()=>window.__VET45_QA__.finishCR16Recovery())()`;
    const row = (key) => click(`[data-recon-row="${key}"]`);
    const chip = (key) => click(`[data-recon-filter="${key}"]`);
    const a16 = (k) => click(`[data-bj16-action="${k}"]`);
    const a17 = (k) => click(`[data-bj17-action="${k}"]`);
    const a8 = (k) => click(`[data-bj08-action="${k}"]`);
    const a11 = (k) => click(`[data-bj11-action="${k}"]`);
    const sheet = (k) => click(`[data-recon-sheet="${k}"]`);
    const actor = (who) => `(()=>{window.__VET45_QA__.setActor('${who}');return true})()`;
    const why = 'Hóa đơn nhà cung cấp ghi 18 hộp';
    const REC = (n) => `DIFF:REC-260907-0${n}`, UNK = (n) => `UNKNOWN:REC-UNKNOWN-0${n}`;
    const enter = (sel) => `(()=>{const i=document.querySelector(${JSON.stringify(sel)});if(!i)return false;i.focus();i.dispatchEvent(new KeyboardEvent('keydown',{key:'Enter',bubbles:true}));return true})()`;
    const typeEnter = (key, v) => `(()=>{const i=document.querySelector('[data-bj08-count="${key}"]');if(!i)return false;i.value=${JSON.stringify(v)};i.dispatchEvent(new Event('input',{bubbles:true}));i.focus();i.dispatchEvent(new KeyboardEvent('keydown',{key:'Enter',bubbles:true}));return true})()`;
    const home = (...exits) => `(()=>{const sb=document.querySelector('#web-sidebar:not([hidden]) [data-theme-sidebar-route="inventory"]');if(sb){sb.click();return true}${exits.map((e) => `document.querySelector(${JSON.stringify(e)})?.click();`).join('')}for(let i=0;i<3&&!document.querySelector('[data-t462-workspace]');i++)document.querySelector('#app-screen .app-back-button')?.click();return !!document.querySelector('[data-t462-workspace]')})()`;
    const toKho = '#app-screen [data-theme-sidebar-route="inventory"]';
    return [
      { name: 'SC_bj16_list', url: D + 'SCR-078', steps: [['filter-diff', chip('DIFF')], ['filter-unknown', chip('UNKNOWN')], ['filter-waiting', chip('WAITING')], ['filter-all', chip('ALL')], ['search', typeIn('[data-recon-search]', 'DH2507')], ['clear-search', typeIn('[data-recon-search]', '')], ['case', row(REC(3))]] },
      { name: 'SC_bj16_recovery', url: D + 'SCR-078', steps: [['case', row(REC(3))], ['recover', a16('recover')], ['confirm', sheet('confirm')], ['finish', finish16], ['close', a16('close-case')], ['to-list', a16('to-list')]] },
      { name: 'SC_bj16_conflict', url: D + 'SCR-078', steps: [['case', row(REC(3))], ['recover', a16('recover')], ['bump', bump16], ['confirm', sheet('confirm')], ['reload', a16('reload')]] },
      { name: 'SC_bj16_mismatch', url: D + 'SCR-078', steps: [['case', row(REC(3))], ['recover', a16('recover')], ['confirm', sheet('confirm')], ['finish', finish16], ['bump', bump16], ['close', a16('close-case')], ['back-ev', a16('back-evidence')]] },
      { name: 'SC_bj16_correction', url: D + 'SCR-078', steps: [['case', row(REC(4))], ['fix', a16('fix-source')]] },
      { name: 'SC_bj16_no_real', url: D + 'SCR-078', steps: [['case', row(REC(5))], ['close', a16('close')], ['confirm', sheet('confirm')], ['to-list', a16('to-list')]] },
      { name: 'SC_bj16_ledger', url: D + 'SCR-078', steps: [['case', row(REC(6))], ['escalate', a16('escalate')], ['to-list', a16('to-list')], ['waiting', chip('WAITING')], ['reopen', row(REC(6))]] },
      { name: 'SC_bj16_source', url: D + 'SCR-078', steps: [['case', row(REC(7))], ['to-purchase', a16('to-purchase')]] },
      { name: 'SC_bj16_back', url: D + 'SCR-078', steps: [['case', row(REC(3))], ['recover', a16('recover')], ['cancel', sheet('cancel')], ['b1', back], ['b2', back]] },
      { name: 'SC_bj16_context', url: '?uif=UIF-16&entry=case-context', steps: [['back', back]] },
      { name: 'SC_bj16_denied', url: D + 'SCR-083&state=PERMISSION_DENIED', steps: [['exit', click('[data-v360-action="fallback-exit"]')]] },
      { name: 'SC_bj16_locked', url: D + 'SCR-079&state=LOCKED', steps: [['holder', a16('open-locking-case')]] },
      { name: 'SC_bj16_correction_return', url: D + 'SCR-078', steps: [['case', row(REC(4))], ['fix', a16('fix-source')], ['reason', typeIn('[data-bj11-reason]', why)], ['send', a11('submit')], ['to-case', a11('to-case')], ['actor', actor('approver')], ['view', a16('view-correction')], ['approve', a11('approve')], ['back-case', a11('to-case')], ['recheck', a16('recheck')], ['close', a16('close-case')]] },
      { name: 'SC_recon_list', url: D + 'SCR-078', steps: [['chip-unknown', chip('UNKNOWN')], ['unknown-01', row(UNK(1))], ['back', back], ['chip-diff', chip('DIFF')], ['rec-03', row(REC(3))]] },
      { name: 'SC_recon_home', url: T + 'inventory', steps: [['home-row', click('[data-t462-attention="UIF-16"]')], ['back', back], ['ws', click('[data-t462-workspace="control"]')], ['item', click('#app-screen [data-theme-entry-flow="UIF-16"]')]] },
      { name: 'SC_bj17_list', url: U + 'SCR-078', steps: [['filter-unknown', chip('UNKNOWN')], ['filter-waiting', chip('WAITING')], ['filter-all', chip('ALL')], ['search', typeIn('[data-recon-search]', 'IO-260906-044')], ['clear-search', typeIn('[data-recon-search]', '')], ['case', row(UNK(1))]] },
      { name: 'SC_bj17_committed', url: U + 'SCR-078', steps: [['case', row(UNK(1))], ['confirm-done', a17('confirm-done')], ['confirm', sheet('confirm')], ['to-list', a17('to-list')]] },
      { name: 'SC_bj17_continue', url: U + 'SCR-078', steps: [['case', row(UNK(2))], ['continue', a17('continue')], ['confirm', sheet('confirm')]] },
      { name: 'SC_bj17_insufficient', url: U + 'SCR-078', steps: [['case', row(UNK(3))], ['escalate', a17('escalate')], ['to-list', a17('to-list')]] },
      { name: 'SC_bj17_plan_conflict', url: U + 'SCR-078', steps: [['case', row(UNK(1))], ['confirm-done', a17('confirm-done')], ['bump', bump17], ['confirm', sheet('confirm')], ['reload', a17('reload')]] },
      { name: 'SC_bj17_sheet_conflict', url: U + 'SCR-078', steps: [['case', row(UNK(2))], ['continue', a17('continue')], ['bump', bump17], ['confirm', sheet('confirm')]] },
      { name: 'SC_bj17_context', url: '?uif=UIF-17&entry=unknown-context', steps: [['back', back]] },
      { name: 'SC_bj17_denied', url: U + 'SCR-083&state=PERMISSION_DENIED', steps: [['exit', click('[data-v360-action="fallback-exit"]')]] },
      { name: 'SC_bj17_from_bj05', url: '?uif=UIF-05&screen=SCR-029&state=UNKNOWN', steps: [['handoff', click('[data-v350-action="handoff-unknown"]')], ['continue', a17('continue')], ['confirm', sheet('confirm')]] },
      { name: 'SC_bj17_from_bj07', url: '?uif=UIF-07&screen=SCR-041&state=UNKNOWN', steps: [['handoff', click('[data-v350-action="handoff-unknown"]')]] },
      { name: 'SC_bj17_from_bj10', url: '?uif=UIF-10&screen=SCR-041&state=UNKNOWN', steps: [['handoff', click('[data-v350-action="handoff-unknown"]')]] },
      { name: 'SC_bj17_from_bj11', url: '?uif=UIF-11&screen=SCR-049&state=UNKNOWN', steps: [['handoff', click('[data-v350-action="handoff-unknown"]')]] },
      // Hết chặng 5 "Kiểm kê và sửa sai" (plan BJ-16 + BJ-17 mục 6.4): kiểm kê → chênh lệch → chủ duyệt → hồ sơ chỉ ra phiếu sai → sửa sai → chủ duyệt → đóng hồ sơ → cập nhật số trên app → xác minh kết quả chưa rõ → Home.
      { name: 'SC_journey_5', url: T + 'inventory', steps: [
        ['count', click('[data-t462-quick="UIF-08"]')],
        ['new', a8('create')], ['group', click('[data-bj08-scope="GROUP"]')], ['scope', a8('scope-open')], ['pick', click('[data-bj08-scope-pick="antibiotic"]')], ['open', a8('open')], ['confirm-open', a8('confirm-open')],
        ['oxy', typeEnter('oxy', '10')], ['ty2511', typeEnter('ty2511', '4')], ['ty2408', typeIn('[data-bj08-count="ty2408"]', '11')], ['submit', a8('submit-first')], ['confirm-first', a8('confirm-first')],
        ['same-oxy', click('[data-bj08-same="oxy"]')], ['recount-ty', typeIn('[data-bj08-recount="ty2511"]', '3')], ['send', a8('submit-recount')], ['confirm-recount', a8('confirm-recount')],
        ['home-1', home('[data-bj08-action="to-list"]')], ['pending-1', click('[data-v464-pending-approvals]')], ['case-1', click('[data-t380-context="bj08-approval:KK-260917-01"]')], ['approve-1', a8('approve')],
        ['home-2', home('[data-theme-sidebar-route="inventory"]', '[data-bj08-action="to-list"]')], ['recon', click('[data-t462-attention="UIF-16"]')], ['diff-chip', chip('DIFF')], ['rec-04', row(REC(4))],
        ['fix', a16('fix-source')], ['reason', typeIn('[data-bj11-reason]', why)], ['send-fix', a11('submit')],
        ['home-3', home('[data-bj11-action="to-case"]')], ['pending-2', click('[data-v464-pending-approvals]')], ['case-2', click('[data-t380-context="bj11-approval:SS-260917-01"]')], ['approve-2', a11('approve')],
        ['back-case', a11('to-case')], ['recheck', a16('recheck')], ['close-1', a16('close-case')],
        ['to-list', a16('to-list')], ['rec-03', row(REC(3))], ['recover', a16('recover')], ['confirm-recover', sheet('confirm')], ['finish', finish16], ['close-2', a16('close-case')],
        ['to-list-2', a16('to-list')], ['unknown-chip', chip('UNKNOWN')], ['unknown-01', row(UNK(1))], ['confirm-done', a17('confirm-done')], ['confirm-sheet', sheet('confirm')],
        ['home-end', home(toKho)]] },
    ];
  })(),
  // Khung — T7-P A11
  ...(() => {
    const entries = {
      'UIF-01': ['product-context'],
      'UIF-02': ['document-context', 'approver'],
      'UIF-03': ['receipt-task'],
      'UIF-04': ['order-context'],
      'UIF-05': ['order-task'],
      'UIF-06': ['return-task', 'approver'],
      'UIF-07': ['return-task'],
      'UIF-08': ['assigned-counter', 'approver'],
      'UIF-09': ['product-context', 'approver'],
      'UIF-10': ['product-context', 'approver', 'completion-operator'],
      'UIF-11': ['approver', 'operation-context', 'correction-from-case'],
      'UIF-12': ['approver', 'owner'],
      'UIF-13': ['source-task'],
      'UIF-14': ['dirty-scope'],
      'UIF-16': ['case-context'],
      'UIF-17': ['unknown-context'],
    };
    return [
      ...Object.entries(entries).flatMap(([uif, modes]) => modes.map((mode) => ({ name: `SC_entry_${uif}_${mode}`, url: `?uif=${uif}&entry=${mode}`, steps: [] }))),
      { name: 'SC_entry_state_12', url: '?uif=UIF-12&entry=approver&state=SELF_APPROVAL_NOT_ALLOWED', steps: [] },
      { name: 'SC_entry_state_01', url: '?uif=UIF-01&entry=product-context&state=STALE', steps: [] },
      { name: 'SC_entry_flow_02', url: '?uif=UIF-02&entry=document-context&flow=quick', steps: [] },
      { name: 'SC_qa_entry14', url: '?uif=UIF-14&screen=SCR-072', steps: [['apply', `window.__VET45_QA__.applyEntry('UIF-14','dirty-scope')`]] },
      { name: 'SC_banner_046', url: '?uif=UIF-08&screen=SCR-042', steps: [['to-046', `(()=>{activeScreenId='SCR-046';stateByScreen['SCR-046']='APPROVAL_REVIEW';renderAppScreen();return true})()`]] },
      { name: 'SC_banner_040', url: '?uif=UIF-10&entry=approver', steps: [['rerender', `(()=>{renderAppScreen();return true})()`]] },
    ];
  })(),
];
for (const sc of SCENARIOS) if (sc.webOnly ? WEB : (!WEB || WEB_SCENARIOS.includes(sc.name))) groups.push({ url: sc.url, cases: [{ name: `${sc.name}_0` }, ...sc.steps.map(([n, act], i) => ({ name: `${sc.name}_${i + 1}_${n}`, act }))].filter((c) => c.name.includes(filter)) });
if (WEB) for (const g of groups) { g.url += '&viewport=web'; g.cases = g.cases.map((c) => ({ ...c, name: c.name + '@web' })); }
const todo = groups.filter((g) => g.cases.length);
mkdirSync(a, { recursive: true });

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

if (mode === 'usage') {
  // Chrome CDP chỉ trả luật đã khớp (used:true); luật không dùng = có trong file nhưng không có trong tập offset đã dùng.
  const cssUsedRanges = new Map(); // file -> [{start,end}]
  const jsCoverage = new Map(); // file:fn:start -> {file,fn,start,count}
  const postrender = [];
  const sheetUrls = new Map(); // styleSheetId -> url
  function listCssRules(src) {
    const rules = [];
    const len = src.length;
    let i = 0;
    const skipWsComment = () => {
      while (i < len) {
        if (src[i] === '/' && src[i + 1] === '*') { const e = src.indexOf('*/', i + 2); i = e < 0 ? len : e + 2; continue; }
        if (/\s/.test(src[i])) { i++; continue; }
        break;
      }
    };
    const readBlock = () => {
      if (src[i] !== '{') return -1;
      let depth = 0, start = i;
      for (; i < len; i++) {
        if (src[i] === '/' && src[i + 1] === '*') { const e = src.indexOf('*/', i + 2); i = e < 0 ? len : e + 1; continue; }
        if (src[i] === '"' || src[i] === "'") { const q = src[i++]; while (i < len && src[i] !== q) { if (src[i] === '\\') i++; i++; } continue; }
        if (src[i] === '{') depth++;
        else if (src[i] === '}') { depth--; if (depth === 0) { i++; return start; } }
      }
      return -1;
    };
    while (i < len) {
      skipWsComment();
      if (i >= len) break;
      if (src[i] === '@') {
        const atStart = i;
        while (i < len && src[i] !== '{' && src[i] !== ';') i++;
        if (src[i] === ';') { i++; continue; }
        const prelude = src.slice(atStart, i).replace(/\s+/g, ' ').trim();
        const blockStart = readBlock();
        if (blockStart < 0) break;
        // Ghi nhận khối @media/@supports để lọc giữ ở chặng 6; không tách luật con (Chrome offset là luật phẳng).
        rules.push({ start: atStart, end: i, selector: prelude, atRule: true });
        continue;
      }
      const start = i;
      while (i < len && src[i] !== '{') {
        if (src[i] === '/' && src[i + 1] === '*') { const e = src.indexOf('*/', i + 2); i = e < 0 ? len : e + 2; continue; }
        i++;
      }
      if (i >= len) break;
      const selector = src.slice(start, i).replace(/\s+/g, ' ').trim();
      const blockStart = readBlock();
      if (blockStart < 0) break;
      if (selector) rules.push({ start, end: i, selector, atRule: false });
    }
    return rules;
  }
  async function usageWorker(n, queue, errors) {
    const port = 9500 + n;
    const chrome = spawn('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', ['--headless=new', `--remote-debugging-port=${port}`, `--user-data-dir=${path.join(a, '.chrome' + n)}`, '--hide-scrollbars', '--force-device-scale-factor=1', 'about:blank'], { stdio: 'ignore' });
    let list; for (let i = 0; i < 100 && !list; i++) { try { list = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json(); } catch { await sleep(100); } }
    if (!list?.length) { chrome.kill(); throw new Error(`Chrome CDP không sẵn sàng ở cổng ${port}`); }
    const ws = new WebSocket(list.find((t) => t.type === 'page').webSocketDebuggerUrl); await new Promise((r) => (ws.onopen = r));
    let id = 0; const pend = new Map(); let loaded = null;
    ws.onmessage = (e) => {
      const m = JSON.parse(e.data);
      if (m.id && pend.has(m.id)) { pend.get(m.id)(m); pend.delete(m.id); }
      if (m.method === 'Page.loadEventFired' && loaded) loaded();
      if (m.method === 'CSS.styleSheetAdded') {
        const h = m.params.header;
        if (h?.styleSheetId && h.sourceURL) sheetUrls.set(h.styleSheetId, h.sourceURL);
      }
      if (m.method === 'Runtime.exceptionThrown') errors.push(m.params.exceptionDetails.exception?.description?.slice(0, 200));
    };
    const send = (method, params = {}) => new Promise((r, j) => {
      const i = ++id;
      const t = setTimeout(() => { pend.delete(i); j(new Error(`CDP timeout ${method}`)); }, 30000);
      pend.set(i, (m) => { clearTimeout(t); r(m); });
      ws.send(JSON.stringify({ id: i, method, params }));
    });
    const evalv = async (expression) => {
      for (let attempt = 0; attempt < 3; attempt++) {
        const m = await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
        if (m?.result?.result) return m.result.result.value;
        await sleep(100);
      }
      return undefined;
    };
    await send('Page.enable'); await send('Runtime.enable'); await send('DOM.enable'); await send('CSS.enable'); await send('Profiler.enable');
    await send('Emulation.setDeviceMetricsOverride', { ...WINDOW, deviceScaleFactor: 1, mobile: false });
    await send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] });
    const frames = 'new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r)))';
    let g;
    while ((g = queue.shift())) {
      const p = new Promise((r) => (loaded = r));
      await send('CSS.startRuleUsageTracking');
      await send('Profiler.startPreciseCoverage', { callCount: true, detailed: false });
      await send('Page.navigate', { url: BASE + g.url }); await p;
      await evalv(`(async()=>{for(let i=0;i<100&&!document.querySelector('#device-preview');i++)await new Promise(r=>setTimeout(r,50));})()`);
      await evalv(`(()=>{const st=document.createElement('style');st.textContent='*,*::before,*::after{animation:none!important;transition:none!important;caret-color:transparent!important}select{appearance:none!important;-webkit-appearance:none!important}';document.head.append(st)})()`);
      await evalv(`document.fonts.ready.then(()=>${frames})`);
      for (const c of g.cases) {
        if (c.screen) await evalv(`(activeScreenId=${JSON.stringify(c.screen)}, stateByScreen[activeScreenId]=${JSON.stringify(c.state)}, render(), ${frames})`);
        if (c.act) await evalv(`Promise.resolve(${c.act}).then(()=>${frames})`);
        const pr = await evalv(`(()=>({v440:document.querySelectorAll('[data-v440-grouped-surface="auto"]').length,v360:document.querySelectorAll('.v360-context-banner').length}))()`);
        if (pr && (pr.v440 > 0 || pr.v360 > 0)) postrender.push(`${c.name}\tv440=${pr.v440}\tv360=${pr.v360}`);
      }
      const cssStop = await send('CSS.stopRuleUsageTracking');
      for (const u of cssStop.result?.ruleUsage || []) {
        if (!u.used) continue;
        const url = sheetUrls.get(u.styleSheetId);
        if (!url) continue;
        const fm = url.match(/\/((?:styles|harness)\/[^/?#]+\.css)/);
        const file = fm ? fm[1] : null;
        if (!file) continue;
        if (!cssUsedRanges.has(file)) cssUsedRanges.set(file, []);
        cssUsedRanges.get(file).push({ start: u.startOffset, end: u.endOffset });
      }
      const cov = await send('Profiler.takePreciseCoverage');
      await send('Profiler.stopPreciseCoverage');
      for (const s of cov.result?.result || []) {
        const url = s.url || '';
        if (!/\/(app|harness)\/[^/]+\.js/.test(url)) continue;
        const file = url.replace(/^.*\/((?:app|harness)\/[^/?#]+\.js).*$/, '$1');
        for (const fn of s.functions || []) {
          if (!fn.functionName || fn.functionName === '') continue;
          const start = fn.ranges?.[0]?.startOffset ?? 0;
          const count = (fn.ranges || []).reduce((n, r) => n + (r.count || 0), 0);
          const key = `${file}:${fn.functionName}:${start}`;
          const prev = jsCoverage.get(key);
          if (!prev) jsCoverage.set(key, { file, fn: fn.functionName, start, count });
          else prev.count += count;
        }
      }
    }
    ws.close(); chrome.kill();
  }
  const t0 = Date.now(); const errors = []; const queue = [...todo];
  // usage: 1 worker — stylesheet IDs must stay consistent for offset→selector mapping
  await usageWorker(0, queue, errors);
  const cssFiles = {};
  for (const f of ['styles/tokens.css', 'styles/components.css', 'styles/screens.css', 'harness/workbench.css']) {
    const p = path.join(HTML, f);
    if (existsSync(p)) cssFiles[f] = readFileSync(p, 'utf8');
  }
  const overlaps = (ranges, start, end) => (ranges || []).some((r) => r.start < end && r.end > start);
  const unusedLines = [];
  for (const [file, src] of Object.entries(cssFiles)) {
    const used = cssUsedRanges.get(file) || [];
    for (const rule of listCssRules(src)) {
      if (overlaps(used, rule.start, rule.end)) continue;
      const line = src.slice(0, rule.start).split('\n').length;
      unusedLines.push(`${file}:${line}\t${rule.selector.slice(0, 160)}`);
    }
  }
  writeFileSync(path.join(a, '_css-unused.txt'), unusedLines.join('\n') + (unusedLines.length ? '\n' : ''));
  const uncovered = [];
  for (const { file, fn, start, count } of [...jsCoverage.values()].sort((a, b) => a.file.localeCompare(b.file) || a.start - b.start)) {
    if (count > 0) continue;
    const srcPath = path.join(HTML, file);
    if (!existsSync(srcPath)) continue;
    const src = readFileSync(srcPath, 'utf8');
    const line = src.slice(0, start).split('\n').length;
    uncovered.push(`${file}:${line}\t${fn}`);
  }
  writeFileSync(path.join(a, '_js-uncovered.txt'), uncovered.join('\n') + (uncovered.length ? '\n' : ''));
  writeFileSync(path.join(a, '_postrender.txt'), postrender.join('\n') + (postrender.length ? '\n' : ''));
  writeFileSync(path.join(a, '_errors.json'), JSON.stringify(errors, null, 1));
  await sleep(300);
  for (const d of readdirSync(a)) if (d.startsWith('.chrome')) rmSync(path.join(a, d), { recursive: true, force: true });
  console.log(`usage: ${todo.reduce((s, g) => s + g.cases.length, 0)} ca · CSS unused ${unusedLines.length} · JS uncovered ${uncovered.length} · postrender hits ${postrender.length} · ${((Date.now() - t0) / 1000).toFixed(1)}s · lỗi ${errors.length}`);
  process.exit(0);
}

async function worker(n, queue, errors, auditLog) {
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
  await send('Emulation.setDeviceMetricsOverride', { ...WINDOW, deviceScaleFactor: 1, mobile: false });
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
      // AUDIT_JS=<tệp biểu thức JS>: chạy kiểm dọc sau mỗi bước (tương phản, vùng chạm, tràn ngang…), ghi vào _audit.json.
      if (process.env.AUDIT_JS) auditLog.push({ name: c.name, ...(await evalv(readFileSync(process.env.AUDIT_JS, 'utf8'))) });
      const shot = FULL
        ? await send('Page.captureScreenshot', { format: 'png' })
        : await send('Page.captureScreenshot', { format: 'png', clip: { x: v.x, y: v.y, width: Math.max(1, v.w), height: Math.max(1, v.h), scale: 1 } });
      writeFileSync(path.join(a, c.name + '.png'), Buffer.from(shot.result.data, 'base64'));
      writeFileSync(path.join(a, c.name + '.txt'), v.t);
    }
  }
  ws.close(); chrome.kill();
}
const t0 = Date.now(); const errors = []; const auditLog = []; const queue = [...todo];
await Promise.all(Array.from({ length: Math.min(WORKERS, todo.length) }, (_, n) => worker(n, queue, errors, auditLog)));
if (process.env.AUDIT_JS) writeFileSync(path.join(a, '_audit.json'), JSON.stringify(auditLog, null, 1));
writeFileSync(path.join(a, '_errors.json'), JSON.stringify(errors, null, 1));
await sleep(300);
for (const d of readdirSync(a)) if (d.startsWith('.chrome')) rmSync(path.join(a, d), { recursive: true, force: true });
console.log(`Đã chụp ${todo.reduce((s, g) => s + g.cases.length, 0)} ca trong ${((Date.now() - t0) / 1000).toFixed(1)} giây, lỗi JS: ${errors.length}`);
