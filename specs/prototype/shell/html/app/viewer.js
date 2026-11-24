// Trang xem prototype (index.html không có ?screen=): chọn màn / trạng thái ở cột trái,
// xem trong khung iPhone / Web / cả hai, hoặc lưới mọi trạng thái của một màn.
// Mỗi khung là iframe tới đúng URL chụp ảnh (?screen=&state=&device=), nên ảnh và trang xem luôn giống nhau.
import { SCREENS } from './cases.js';
import { render } from './main.js';

const DEV = { iphone: { w: 390, h: 844, label: 'iPhone 390' }, web: { w: 1280, h: 800, label: 'Web 1280' } };
const FLAT = SCREENS.flatMap((s) => s.states.map(([id]) => [s.id, id]));
const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const url = (screen, state, device) => `index.html?screen=${screen}&state=${state}&device=${device}`;

function readHash() {
  const [sc, st, dv, md] = location.hash.slice(1).split('/');
  const scr = SCREENS.find((s) => s.id === sc) || SCREENS[0];
  const state = scr.states.some(([id]) => id === st) ? st : scr.states[0][0];
  return { screen: scr.id, state, device: ['iphone', 'web', 'both'].includes(dv) ? dv : 'both', mode: ['grid', 'edit'].includes(md) ? md : 'single' };
}
const hashOf = (v) => `#${v.screen}/${v.state}/${v.device}/${v.mode}`;
const go = (patch) => { location.hash = hashOf({ ...readHash(), ...patch }); };
const devicesOf = (d) => (d === 'both' ? ['iphone', 'web'] : [d]);

function seg(name, value, options) {
  return `<div class="vw-seg" role="group" aria-label="${name}">${options.map(([v, label]) => `<button type="button" data-${name}="${v}" aria-pressed="${v === value}">${label}</button>`).join('')}</div>`;
}

const active = (v, screen, state) => (v.mode !== 'grid' && v.screen === screen && v.state === state ? ' is-active' : '');

function sidebar(v) {
  return SCREENS.map((s) => `
    <section class="vw-group">
      <button type="button" class="vw-group__head${v.mode === 'grid' && v.screen === s.id ? ' is-active' : ''}" data-grid="${s.id}" title="Xem mọi trạng thái của màn này">
        <span class="vw-code">${esc(s.code)}</span><span class="vw-group__title">${esc(s.title)}</span><span class="vw-count">${s.states.length}</span>
      </button>
      <ul>${s.states.map(([id, label]) => `
        <li><a class="vw-item${active(v, s.id, id)}" href="${hashOf({ ...v, screen: s.id, state: id, mode: v.mode === 'grid' ? 'single' : v.mode })}">
          <span>${esc(label)}</span><code>${id}</code></a></li>`).join('')}
      </ul>
    </section>`).join('');
}

function frame(screen, state, device, scale) {
  const d = DEV[device];
  return `<figure class="vw-frame" data-device="${device}" style="width:${Math.round(d.w * scale)}px">
    <div class="vw-frame__box" style="width:${Math.round(d.w * scale)}px;height:${Math.round(d.h * scale)}px">
      <iframe src="${url(screen, state, device)}" width="${d.w}" height="${d.h}" style="transform:scale(${scale})" title="${screen} ${state} ${device}" loading="lazy"></iframe>
    </div>
    <figcaption>${d.label}${scale < 1 ? ` · ${Math.round(scale * 100)}%` : ''} <a href="${url(screen, state, device)}" target="_blank" rel="noopener" title="Mở riêng khổ thật">↗</a></figcaption>
  </figure>`;
}

function head(v, extra = '') {
  const scr = SCREENS.find((s) => s.id === v.screen);
  const [, label, note] = scr.states.find(([id]) => id === v.state);
  const i = FLAT.findIndex(([a, b]) => a === v.screen && b === v.state);
  return `
    <header class="vw-head">
      <div>
        <p class="vw-crumb">${esc(scr.code)} · ${esc(scr.title)}</p>
        <h1>${esc(label)} <code>${v.state}</code></h1>
        <p class="vw-note">${esc(note)}</p>${extra}
      </div>
      <div class="vw-pager">
        <button type="button" data-step="-1" ${i === 0 ? 'disabled' : ''} aria-label="Ca trước">‹</button>
        <span>${i + 1} / ${FLAT.length}</span>
        <button type="button" data-step="1" ${i === FLAT.length - 1 ? 'disabled' : ''} aria-label="Ca sau">›</button>
      </div>
    </header>`;
}

function single(v, box) {
  const devs = devicesOf(v.device);
  // Một tỉ lệ chung cho mọi khung đang hiện: vừa chiều ngang và chiều cao vùng xem.
  const gap = 32;
  const W = box.width - 48; const H = box.height - 150;
  const sumW = devs.reduce((x, d) => x + DEV[d].w, 0) + gap * (devs.length - 1);
  const maxH = Math.max(...devs.map((d) => DEV[d].h));
  const scale = Math.max(0.25, Math.min(1, W / sumW, H / maxH));
  return `${head(v)}
    <div class="vw-stage">${devs.map((d) => frame(v.screen, v.state, d, scale)).join('')}</div>`;
}

// Sửa trực tiếp: vẽ màn thẳng vào trang (không iframe, cỡ thật) để /impeccable live chọn được phần tử.
// Chỉ để xem / chọn; tương tác của màn (gõ tiền, lọc…) chạy ở chế độ Từng ca hoặc URL màn trần.
function edit(v) {
  const devs = devicesOf(v.device);
  const tip = '<p class="vw-tip">Cỡ thật: dùng ⊕ của Impeccable để chọn phần tử; Shift+↑ để chọn khung lớn hơn (tới cả màn), Enter để chốt. Chuyển ca bằng cột trái hoặc phím j / k. Màn ở đây không bấm được; thử tương tác ở nút ↗ (mở màn trần).</p>';
  return `${head(v, tip)}
    <div class="vw-live-stage">${devs.map((d) => `
      <figure class="vw-live" data-device="${d}">
        ${render(v.screen, v.state, d)}
        <figcaption>${DEV[d].label} · 100%</figcaption>
      </figure>`).join('')}
    </div>`;
}

function grid(v) {
  const scr = SCREENS.find((s) => s.id === v.screen);
  const devs = devicesOf(v.device);
  const scale = { iphone: 0.42, web: 0.3 };
  return `
    <header class="vw-head">
      <div>
        <p class="vw-crumb">${esc(scr.code)} · ${esc(scr.title)}</p>
        <h1>Mọi trạng thái <span class="vw-count">${scr.states.length}</span></h1>
        <p class="vw-note">Bấm tên một ca để xem lớn.</p>
      </div>
    </header>
    <div class="vw-grid" style="--vw-card:${{ iphone: 230, web: 430, both: 640 }[v.device]}px">${scr.states.map(([id, label, note]) => `
      <article class="vw-card">
        <a class="vw-card__title" href="${hashOf({ ...v, state: id, mode: 'single' })}"><b>${esc(label)}</b><code>${id}</code></a>
        <p class="vw-note">${esc(note)}</p>
        <div class="vw-card__frames">${devs.map((d) => frame(v.screen, id, d, scale[d])).join('')}</div>
      </article>`).join('')}
    </div>`;
}

export function mountViewer(root) {
  document.body.classList.add('vw-body');
  document.title = 'Khung chung · Prototype';
  root.innerHTML = `
    <div class="vw">
      <header class="vw-top">
        <div class="vw-brand"><a class="vw-home" href="../../../index.html" title="Mục lục mọi prototype (cần chạy python3 specs/prototype/serve.py)">← Mục lục</a><b>Khung chung</b><span>Prototype 10-8 · ${FLAT.length} ca</span></div>
        <div class="vw-tools" data-tools></div>
      </header>
      <nav class="vw-side" data-side aria-label="Màn và trạng thái"></nav>
      <main class="vw-main" data-main></main>
    </div>`;
  const side = root.querySelector('[data-side]');
  const main = root.querySelector('[data-main]');
  const tools = root.querySelector('[data-tools]');
  let last = '';
  const paint = (force) => {
    const v = readHash();
    const box = main.getBoundingClientRect();
    const key = hashOf(v) + (v.mode === 'single' ? `|${Math.round(box.width)}x${Math.round(box.height)}` : '');
    if (key === last && !force) return;
    last = key;
    tools.innerHTML = seg('device', v.device, [['iphone', 'iPhone'], ['web', 'Web'], ['both', 'Cả hai']])
      + seg('mode', v.mode, [['single', 'Từng ca'], ['grid', 'Cả màn'], ['edit', 'Sửa trực tiếp']]);
    side.innerHTML = sidebar(v);
    main.innerHTML = v.mode === 'grid' ? grid(v) : v.mode === 'edit' ? edit(v) : single(v, box);
    main.scrollTop = 0;
    side.querySelector('.is-active')?.scrollIntoView({ block: 'nearest' });
  };
  root.addEventListener('click', (e) => {
    const b = e.target.closest('[data-device],[data-mode],[data-grid],[data-step]');
    if (!b) return;
    if (b.dataset.device) go({ device: b.dataset.device });
    else if (b.dataset.mode) go({ mode: b.dataset.mode });
    else if (b.dataset.grid) go({ screen: b.dataset.grid, mode: 'grid' });
    else step(Number(b.dataset.step));
  });
  const step = (n) => {
    const v = readHash();
    const i = FLAT.findIndex(([a, b]) => a === v.screen && b === v.state);
    const next = FLAT[Math.min(FLAT.length - 1, Math.max(0, i + n))];
    go({ screen: next[0], state: next[1], mode: v.mode === 'grid' ? 'single' : v.mode });
  };
  document.addEventListener('keydown', (e) => {
    if (e.defaultPrevented || e.shiftKey || e.metaKey || e.ctrlKey || e.altKey) return;
    if (e.target.closest?.('input, textarea, [contenteditable]')) return;
    // Sửa trực tiếp: ↑ ↓ / Shift+↑ thuộc công cụ chọn của /impeccable live → chỉ dùng j / k.
    const arrows = readHash().mode !== 'edit';
    if ((arrows && e.key === 'ArrowDown') || e.key === 'j') { e.preventDefault(); step(1); }
    else if ((arrows && e.key === 'ArrowUp') || e.key === 'k') { e.preventDefault(); step(-1); }
    else if (e.key === '1') go({ device: 'iphone' });
    else if (e.key === '2') go({ device: 'web' });
    else if (e.key === '3') go({ device: 'both' });
    else if (e.key === 'g') go({ mode: readHash().mode === 'grid' ? 'single' : 'grid' });
    else if (e.key === 'e') go({ mode: readHash().mode === 'edit' ? 'single' : 'edit' });
  });
  window.addEventListener('hashchange', () => paint());
  let t;
  window.addEventListener('resize', () => { clearTimeout(t); t = setTimeout(() => paint(), 150); });
  paint(true);
}
