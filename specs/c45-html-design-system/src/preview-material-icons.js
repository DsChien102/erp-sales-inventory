/** Preview-only Material glyphs used by the authoritative Flutter example.
 * These are deliberately separate from VIcons/Lucide so preview parity does
 * not corrupt the public Mosaic Retail icon contract.
 */
const PATHS = Object.freeze({
  home:'M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z',
  receipt_long:'M19 3H5c-1.1 0-2 .9-2 2v14l2-1 2 1 2-1 2 1 2-1 2 1 2-1 2 1 2-1V5c0-1.1-.9-2-2-2zm-1 12H6v-2h12v2zm0-4H6V9h12v2zm0-4H6V5h12v2z',
  more_horiz:'M6 10c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm12 0c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm-6 0c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z',
  store:'M20 4H4v2h16V4zm1 10v-2l-1-5H4l-1 5v2h1v6h10v-6h4v6h2v-6h1zm-9 4H6v-4h6v4z',
  search:'M9.5 3A6.5 6.5 0 1 0 13.6 14.55L19.05 20 20.5 18.55l-5.45-5.45A6.5 6.5 0 0 0 9.5 3zm0 2A4.5 4.5 0 1 1 5 9.5 4.5 4.5 0 0 1 9.5 5z',
  visibility:'M12 4.5C7 4.5 2.73 7.61 1 12c1.73 4.39 6 7.5 11 7.5s9.27-3.11 11-7.5C21.27 7.61 17 4.5 12 4.5zm0 12.5a5 5 0 1 1 0-10 5 5 0 0 1 0 10zm0-8a3 3 0 1 0 0 6 3 3 0 0 0 0-6z',
  visibility_off:'M2.1 3.51 3.51 2.1 21.9 20.49l-1.41 1.41-3.27-3.27A11.9 11.9 0 0 1 12 19.5C7 19.5 2.73 16.39 1 12a13.9 13.9 0 0 1 3.18-4.55L2.1 5.37V3.51zm7.59 7.59a2.5 2.5 0 0 0 3.21 3.21L9.69 11.1zM12 4.5c5 0 9.27 3.11 11 7.5a13.75 13.75 0 0 1-2.09 3.35l-3.1-3.1c.02-.08.02-.17.02-.25A5.83 5.83 0 0 0 12 6.17c-.08 0-.17 0-.25.02L10.11 4.55A12.6 12.6 0 0 1 12 4.5z',
  check_rounded:'M9 16.17 4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z'
});

function svg(name, size = 24) {
  const path = PATHS[name];
  if (!path) return null;
  const el = document.createElementNS('http://www.w3.org/2000/svg','svg');
  el.setAttribute('viewBox','0 0 24 24');
  el.setAttribute('width', String(size));
  el.setAttribute('height', String(size));
  el.setAttribute('aria-hidden','true');
  el.setAttribute('focusable','false');
  el.style.display='block';
  el.style.fill='currentColor';
  const p = document.createElementNS('http://www.w3.org/2000/svg','path');
  p.setAttribute('d', path);
  el.append(p);
  return el;
}

export function hydratePreviewMaterialIcons(root = document) {
  root.querySelectorAll('[data-preview-material-icon]').forEach(host => {
    if (host.dataset.previewMaterialHydrated === 'true') return;
    const name = host.dataset.previewMaterialIcon;
    const size = Number(host.dataset.previewMaterialSize || 24);
    const icon = svg(name,size);
    if (!icon) return;
    host.textContent='';
    host.append(icon);
    host.dataset.previewMaterialHydrated='true';
  });
}
