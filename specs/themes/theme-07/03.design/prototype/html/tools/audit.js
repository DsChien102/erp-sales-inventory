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
