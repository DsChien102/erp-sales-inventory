// Đo khai báo `!important` nào còn cần (T7-P G3-1).
//   node tools/golden.mjs important <dir>        — chạy dò trong trình duyệt trên mọi ca golden, ghi <dir>/_important.json
//   node tools/css-important.mjs apply <dir>     — bỏ `!important` ở khai báo đã được dò thấy không đổi gì
// Cách dò: với mỗi khai báo `!important` của luật có phần tử khớp, bỏ cờ đó qua CSSOM, so computed style của
// các phần tử khớp trước/sau; khác = còn cần. Luật không có phần tử khớp (hover, focus, media không bật…) = chưa kiểm → giữ.
import { spawn } from 'node:child_process';
import { readFileSync, writeFileSync, readdirSync, rmSync, existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const FILES = ['styles/components.css', 'styles/screens.css'];
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// ---- Tách luật + khai báo (bỏ qua chú thích, chuỗi, ngoặc) ----
function skipComment(src, i) { const e = src.indexOf('*/', i + 2); return e < 0 ? src.length : e + 2; }
function skipString(src, i) { const q = src[i++]; while (i < src.length && src[i] !== q) { if (src[i] === '\\') i++; i++; } return i + 1; }
export function normSel(s) {
  return s.replace(/\/\*[\s\S]*?\*\//g, '').replace(/\s+/g, '').replace(/["']/g, '').replace(/(?<!:):(before|after|first-line|first-letter)/g, '::$1');
}
// Trả về danh sách luật phẳng (cả luật lồng trong @media/@supports): { selector, bodyStart, bodyEnd, depth }
export function flatRules(src) {
  const out = [];
  const walk = (from, to, depth) => {
    let i = from;
    while (i < to) {
      if (src[i] === '/' && src[i + 1] === '*') { i = skipComment(src, i); continue; }
      if (/\s/.test(src[i])) { i++; continue; }
      const start = i;
      while (i < to && src[i] !== '{' && src[i] !== ';') {
        if (src[i] === '/' && src[i + 1] === '*') { i = skipComment(src, i); continue; }
        if (src[i] === '"' || src[i] === "'") { i = skipString(src, i); continue; }
        i++;
      }
      if (src[i] === ';') { i++; continue; }
      if (i >= to) break;
      const prelude = src.slice(start, i);
      const bodyStart = i + 1; let d = 0;
      for (; i < to; i++) {
        if (src[i] === '/' && src[i + 1] === '*') { i = skipComment(src, i) - 1; continue; }
        if (src[i] === '"' || src[i] === "'") { i = skipString(src, i) - 1; continue; }
        if (src[i] === '{') d++;
        else if (src[i] === '}') { d--; if (d === 0) break; }
      }
      const bodyEnd = i; i++;
      if (prelude.trim().startsWith('@')) {
        if (/^@(media|supports|layer|container)/i.test(prelude.trim())) walk(bodyStart, bodyEnd, depth + 1);
      } else out.push({ selector: prelude.trim(), bodyStart, bodyEnd, depth });
    }
  };
  walk(0, src.length, 0);
  return out;
}
// Tách thân luật thành khai báo: [{ start, end }] (đoạn văn bản, không gồm dấu ;)
export function splitDecls(src, bodyStart, bodyEnd) {
  const decls = []; let i = bodyStart, s = bodyStart, paren = 0;
  for (; i < bodyEnd; i++) {
    const c = src[i];
    if (c === '/' && src[i + 1] === '*') { i = skipComment(src, i) - 1; continue; }
    if (c === '"' || c === "'") { i = skipString(src, i) - 1; continue; }
    if (c === '(') paren++; else if (c === ')') paren--;
    else if (c === ';' && paren === 0) { decls.push({ start: s, end: i }); s = i + 1; }
  }
  if (src.slice(s, bodyEnd).replace(/\/\*[\s\S]*?\*\//g, '').trim()) decls.push({ start: s, end: bodyEnd });
  return decls;
}
const IMP = /!\s*important/i;
const stripComments = (t) => t.replace(/\/\*[\s\S]*?\*\//g, '').trim();

// Bảng luật có !important: key -> { file, decls:[{ text, imp }] }
const DELETE = process.env.MODE === 'delete';
export function importantTable(HTML) {
  const table = {};
  for (const file of FILES) {
    const src = readFileSync(path.join(HTML, file), 'utf8');
    const occ = {};
    for (const r of flatRules(src)) {
      const k0 = file + '|' + normSel(r.selector);
      occ[k0] = (occ[k0] || 0) + 1;
      const decls = splitDecls(src, r.bodyStart, r.bodyEnd).map((d) => ({ text: stripComments(src.slice(d.start, d.end)), start: d.start, end: d.end }));
      const cand = (d) => DELETE ? d.text.length > 0 && !d.text.startsWith('--') : IMP.test(d.text);
      if (!decls.some(cand)) continue;
      table[k0 + '#' + occ[k0]] = { file, selector: r.selector.replace(/\s+/g, ' ').slice(0, 120), depth: r.depth, decls: decls.map((d) => ({ text: d.text, imp: cand(d) })) };
    }
  }
  return table;
}

const PROBE = `(() => {
  const T = window.__impTable;
  const IMPRE = /!\\s*important/i;
  const norm = (s) => s.replace(/\\s+/g, '').replace(/["']/g, '');
  if (!window.__imp) {
    const idx = [], occ = {};
    for (const sh of document.styleSheets) {
      const m = (sh.href || '').match(/styles\\/([^/?#]+\\.css)/); if (!m) continue;
      const file = 'styles/' + m[1];
      const walk = (rules, cond) => { for (const r of rules) {
        if (r.type === 1) { const k0 = file + '|' + norm(r.selectorText); occ[k0] = (occ[k0] || 0) + 1; const key = k0 + '#' + occ[k0]; if (T[key]) idx.push({ key, rule: r, cond, orig: r.style.cssText }); }
        else if (r.cssRules) { let on = true; try { on = r.media ? matchMedia(r.media.mediaText).matches : (r.conditionText ? CSS.supports(r.conditionText) : true); } catch (e) {} walk(r.cssRules, cond && on); } } };
      walk(sh.cssRules, true);
    }
    const I = window.__imp = { idx, byKey: {}, st: {}, needed: Object.assign({}, window.__impInit.needed), restored: 0, added: 0 };
    for (const e of idx) I.byKey[e.key] = e;
    for (const k of Object.keys(window.__impInit.stripped)) { const cut = k.lastIndexOf('|'); const key = k.slice(0, cut), j = k.slice(cut + 1); if (!I.byKey[key]) continue; (I.st[key] = I.st[key] || new Set()).add(+j); }
    for (const e of idx) if (I.st[e.key]) setRule(e);
  }
  const I = window.__imp;
  function setRule(e) { const set = window.__imp.st[e.key]; e.rule.style.cssText = T[e.key].decls.map((d, k) => set && set.has(k) ? (window.__impDelete ? '' : d.text.replace(IMPRE, '')) : d.text).filter(Boolean).join(';'); }
  const resetAll = () => { for (const e of I.idx) if (I.st[e.key] && I.st[e.key].size) e.rule.style.cssText = e.orig; };
  const applyAll = () => { for (const e of I.idx) if (I.st[e.key] && I.st[e.key].size) setRule(e); };
  const sigOf = (el, pseudo) => { const cs = getComputedStyle(el, pseudo || null); if (pseudo) { const c = cs.content; if (c === 'none' || c === 'normal') return 'c:' + c; } let s = ''; for (let i = 0; i < cs.length; i++) { const p = cs[i]; s += p + ':' + cs.getPropertyValue(p) + ';'; } return s; };
  const root = document.querySelector('#device-preview');
  const allEls = () => { const anc = []; for (let n = root.parentElement; n; n = n.parentElement) anc.push(n); return [...anc, root, ...root.querySelectorAll('*')]; };
  const sigAll = () => { const m = new Map(); for (const el of allEls()) m.set(el, [sigOf(el), sigOf(el, '::before'), sigOf(el, '::after')]); return m; };
  const PS = ['', '::before', '::after'];
  const diffEls = (A, B) => { const out = []; for (const [el, a] of A) { const b = B.get(el); if (!b) continue; for (let i = 0; i < 3; i++) if (a[i] !== b[i]) { out.push([el, i]); } } return out; };
  const splitList = (sel) => { const out = []; let d = 0, s = 0; for (let i = 0; i < sel.length; i++) { const c = sel[i]; if (c === '(' || c === '[') d++; else if (c === ')' || c === ']') d--; else if (c === ',' && d === 0) { out.push(sel.slice(s, i)); s = i + 1; } } out.push(sel.slice(s)); return out; };
  const PSEUDO = /(::?(?:before|after|first-line|first-letter|placeholder|marker|selection|-webkit-[a-z-]+))$/;
  const targetsOf = (e, cap) => { const t = []; for (const part of splitList(e.rule.selectorText)) { let b = part.trim(), ps = null; const pm = b.match(PSEUDO); if (pm) { ps = pm[1]; b = b.slice(0, -ps.length).trim() || '*'; } let els; try { els = document.querySelectorAll(b); } catch (x) { continue; } for (let i = 0; i < els.length && t.length < cap; i++) t.push([els[i], ps === '::before' || ps === ':before' ? 1 : ps === '::after' || ps === ':after' ? 2 : 0, ps]); } return t; };
  const matchesEl = (e, el) => { for (const part of splitList(e.rule.selectorText)) { let b = part.trim(); const pm = b.match(PSEUDO); if (pm) b = b.slice(0, -pm[1].length).trim() || '*'; try { if (el.matches(b)) return true; } catch (x) {} } return false; };
  // 1. trạng thái gốc
  resetAll(); const SIG0 = sigAll(); applyAll();
  // 2. tập đã bỏ phải khớp trạng thái gốc; lệch → trả lại (chưa đánh dấu "cần") mọi khai báo của luật khớp phần tử lệch; bước 3 thử bỏ lại từng cái
  for (let round = 0; round < 8; round++) {
    const D = diffEls(SIG0, sigAll()); if (!D.length) break;
    const els = new Set(D.map((d) => d[0]));
    const cand = I.idx.filter((e) => I.st[e.key] && I.st[e.key].size && [...els].some((el) => matchesEl(e, el)));
    if (!cand.length) { I.stuck = (I.stuck || 0) + 1; (I.stuckInfo = I.stuckInfo || []).push(location.search + ' ' + D.slice(0, 3).map(([el, i]) => el.tagName + '.' + String(el.className).slice(0, 60) + '/' + i).join(' ; ')); break; }
    for (const e of cand) { I.restored += I.st[e.key].size; I.st[e.key].clear(); setRule(e); }
  }
  // 3. thử bỏ thêm
  for (const e of I.idx) {
    if (!e.cond) continue;
    const info = T[e.key]; const set = I.st[e.key] || (I.st[e.key] = new Set());
    const todo = []; info.decls.forEach((d, j) => { if (d.imp && !set.has(j) && !I.needed[e.key + '|' + j]) todo.push(j); });
    if (!todo.length) continue;
    const targets = targetsOf(e, 120); if (!targets.length) continue;
    for (const j of todo) {
      set.add(j); setRule(e);
      let changed = false;
      for (const [el, pi, ps] of targets) { if (sigOf(el, ps) !== SIG0.get(el)?.[pi]) { changed = true; break; } }
      if (changed) { set.delete(j); I.needed[e.key + '|' + j] = 1; setRule(e); } else I.added++;
    }
  }
  return 1;
})()`;

export async function runImportant({ a, todo, BASE, WINDOW, HTML, WORKERS }) {
  const table = importantTable(HTML);
  const total = Object.values(table).reduce((n, r) => n + r.decls.filter((d) => d.imp).length, 0);
  console.log(`important: ${Object.keys(table).length} luật · ${total} khai báo !important`);
  const prev = existsSync(path.join(a, '_important.json')) ? JSON.parse(readFileSync(path.join(a, '_important.json'), 'utf8')) : null;
  let needed = { ...(prev?.needed || {}) }, stripped = { ...(prev?.stripped || {}) }; const errors = [];
  const PASSES = Number(process.env.PASSES || 4);
  for (let pass = 1; pass <= PASSES; pass++) {
    if (process.env.RETRY && pass > 1) needed = {}; // thử lại khai báo từng bị coi là cần: đối thủ có thể đã được bỏ cờ ở lượt trước
    const before = Object.keys(needed).length, beforeS = Object.keys(stripped).length;
    const newNeeded = {}, newStripped = {}; let restored = 0, stuck = 0;
    const queue = [...todo]; const t0 = Date.now();
    async function worker(n) {
      const port = 9600 + n;
      const chrome = spawn('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', ['--headless=new', `--remote-debugging-port=${port}`, `--user-data-dir=${path.join(a, '.chrome' + n)}`, '--hide-scrollbars', '--force-device-scale-factor=1', 'about:blank'], { stdio: 'ignore' });
      let list; for (let i = 0; i < 100 && !list; i++) { try { list = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json(); } catch { await sleep(100); } }
      const ws = new WebSocket(list.find((t) => t.type === 'page').webSocketDebuggerUrl); await new Promise((r) => (ws.onopen = r));
      let id = 0; const pend = new Map(); let loaded = null;
      ws.onmessage = (e) => { const m = JSON.parse(e.data); if (m.id && pend.has(m.id)) { pend.get(m.id)(m); pend.delete(m.id); } if (m.method === 'Page.loadEventFired' && loaded) loaded(); if (m.method === 'Runtime.exceptionThrown') errors.push(m.params.exceptionDetails.exception?.description?.slice(0, 200)); };
      const send = (method, params = {}) => new Promise((r) => { const i = ++id; pend.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
      const evalv = async (expression) => { const m = await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true }); if (m.result?.exceptionDetails) errors.push(m.result.exceptionDetails.exception?.description?.slice(0, 300)); return m.result?.result?.value; };
      await send('Page.enable'); await send('Runtime.enable');
      await send('Emulation.setDeviceMetricsOverride', { ...WINDOW, deviceScaleFactor: 1, mobile: false });
      await send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] });
      const frames = 'new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r)))';
      let g;
      while ((g = queue.shift())) {
        const p = new Promise((r) => (loaded = r));
        await send('Page.navigate', { url: BASE + g.url }); await p;
        await evalv(`(async()=>{for(let i=0;i<100&&!document.querySelector('#device-preview');i++)await new Promise(r=>setTimeout(r,50));})()`);
        await evalv(`(()=>{const st=document.createElement('style');st.textContent='*,*::before,*::after{animation:none!important;transition:none!important;caret-color:transparent!important}select{appearance:none!important;-webkit-appearance:none!important}';document.head.append(st)})()`);
        await evalv(`document.fonts.ready.then(()=>${frames})`);
        await evalv(`(window.__impDelete=${DELETE}, window.__impTable=${JSON.stringify(table)}, window.__impInit=${JSON.stringify({ needed, stripped: Object.fromEntries(Object.keys(stripped).filter((k) => !needed[k]).map((k) => [k, 1])) })}, 0)`);
        for (const c of g.cases) {
          if (c.screen) await evalv(`(activeScreenId=${JSON.stringify(c.screen)}, stateByScreen[activeScreenId]=${JSON.stringify(c.state)}, render(), ${frames})`);
          if (c.act) await evalv(`Promise.resolve(${c.act}).then(()=>${frames})`);
          await evalv(PROBE);
        }
        const res = await evalv(`JSON.stringify({ n: window.__imp ? window.__imp.needed : {}, s: window.__imp ? Object.entries(window.__imp.st).flatMap(([k, v]) => [...v].map((j) => k + '|' + j)) : [], r: window.__imp ? window.__imp.restored : 0, u: window.__imp ? (window.__imp.stuck || 0) : 0, i: window.__imp ? (window.__imp.stuckInfo || []) : [] })`);
        if (res) { const r = JSON.parse(res); Object.assign(newNeeded, r.n); Object.assign(needed, r.n); for (const k of r.s) newStripped[k] = 1; restored += r.r; stuck += r.u; for (const x of r.i || []) console.log('kẹt:', x); }
      }
      ws.close(); chrome.kill();
    }
    await Promise.all(Array.from({ length: Math.min(WORKERS, todo.length) }, (_, n) => worker(n)));
    await sleep(300);
    for (const d of readdirSync(a)) if (d.startsWith('.chrome')) rmSync(path.join(a, d), { recursive: true, force: true });
    needed = { ...needed, ...newNeeded };
    // tập bỏ = hợp các tập của trang, trừ khai báo bất kỳ trang nào thấy cần
    stripped = {}; for (const k of Object.keys(newStripped)) if (!needed[k]) stripped[k] = 1;
    const changed = Object.keys(needed).length !== before || Object.keys(stripped).length !== beforeS;
    writeFileSync(path.join(a, '_important.json'), JSON.stringify({ needed, stripped, errors }, null, 1));
    console.log(`lượt ${pass}: cần ${Object.keys(needed).length} · bỏ ${Object.keys(stripped).length} · trả lại ${restored} · kẹt ${stuck} · lỗi ${errors.length} · ${((Date.now() - t0) / 1000).toFixed(1)}s`);
    if (!changed && restored === 0) { console.log('hội tụ'); break; }
  }
}

// ---- apply ----
function applyMain() {
  const [, , , dir, ...more] = process.argv;
  const HTML = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
  const dirs = [dir, ...more];
  const needed = {}, strip = {};
  for (const d of dirs) { const j = JSON.parse(readFileSync(path.join(d, '_important.json'), 'utf8')); Object.assign(needed, j.needed); for (const k of Object.keys(j.stripped)) strip[k] = 1; }
  for (const k of Object.keys(needed)) delete strip[k];
  let stripped = 0, kept = 0, unverified = 0;
  for (const file of FILES) {
    const src = readFileSync(path.join(HTML, file), 'utf8');
    const occ = {}; const edits = [];
    for (const r of flatRules(src)) {
      const k0 = file + '|' + normSel(r.selector); occ[k0] = (occ[k0] || 0) + 1; const key = k0 + '#' + occ[k0];
      const decls = splitDecls(src, r.bodyStart, r.bodyEnd);
      const stripable = decls.map((d) => stripComments(src.slice(d.start, d.end)));
      decls.forEach((d, j) => {
        if (!(DELETE ? stripable[j].length > 0 && !stripable[j].startsWith('--') : IMP.test(stripable[j]))) return;
        const kj = key + '|' + j;
        if (strip[kj]) {
          const text = src.slice(d.start, d.end);
          if (DELETE) { let e = d.end; if (src[e] === ';') e++; edits.push({ at: d.start, len: e - d.start }); stripped++; }
          else { const m = [...text.matchAll(/\s*!\s*important/gi)].pop(); if (m) { edits.push({ at: d.start + m.index, len: m[0].length }); stripped++; } }
        } else if (needed[kj]) kept++; else unverified++;
      });
    }
    let out = src; for (const e of edits.sort((x, y) => y.at - x.at)) out = out.slice(0, e.at) + out.slice(e.at + e.len);
    writeFileSync(path.join(HTML, file), out);
  }
  console.log(`apply: bỏ ${stripped} · giữ (cần) ${kept} · giữ (chưa kiểm) ${unverified}`);
}
if (process.argv[2] === 'apply') applyMain();
