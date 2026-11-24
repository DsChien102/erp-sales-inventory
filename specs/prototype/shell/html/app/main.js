// Prototype khung chung (10-8). Không có ?screen= → trang xem (viewer.js); có → vẽ đúng một ca (URL chụp ảnh).
// Tương tác ở URL màn trần: bấm tab / mục con để chuyển; bấm tên tổ chức → APP-04 (tìm, chọn, xác nhận, đang chuyển, toast).
import { icon } from '../shared/icons.js';
import { renderShell, DEVICE, DESKTOP, MORE_ENTRIES, TABS, insideShell } from '../shared/shell.js';
import { ORGS, orgListBody, confirmBody, adaptiveSheet, switching, toast } from './org.js';

const esc = (s) => String(s ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

// Tên màn theo đường dẫn (ô giữ chỗ). Mã màn theo docs/refactor/CHECKLIST.md.
const PAGES = {
  '/': ['Trang chủ', 'APP-01 · HomeTabPage'],
  '/orders': ['Đơn hàng', 'SalesOrderListPage'],
  '/products/items': ['Sản phẩm', 'Danh sách sản phẩm'],
  '/partner': ['Đối tác', 'Danh sách đối tác'],
  '/warehouse': ['Kho', 'Theme 7 · Hub kho'],
  '/more/receivables': ['Công nợ phải thu', 'Theme 6 · CN-01'],
  '/pricing': ['Giá riêng', 'Theme 4'],
  '/more/users-and-roles': ['Người dùng & vai trò', 'Theme 1'],
  '/more/my-account': ['Tài khoản của tôi', 'Theme 1'],
  '/more/settings': ['Thiết lập', 'APP-02 · SystemSettingsPage'],
};

/** Màn "Thêm" (MorePage): đủ 10 mục theo thứ tự; mục tắt mờ; khi bị chặn, mục cần tổ chức mờ. Bố cục thật rà ở mục "Menu Thêm". */
function morePage({ isOwner, isBlocked }) {
  const rows = MORE_ENTRIES.filter((e) => !(e.ownerOnly && !isOwner && !isBlocked)).map((e) => {
    const off = e.enabled === false || (e.needsActiveTenant && isBlocked);
    return `<button type="button" class="sh-more__row${e.destructive ? ' is-danger' : ''}"${e.route ? ` data-shell-route="${e.route}"` : ''}${off ? ' disabled' : ''}>${icon(e.icon)}<span><b>${esc(e.title)}</b><small>${esc(e.subtitle)}</small></span>${e.destructive ? '' : icon('chevronRight')}</button>`;
  }).join('');
  return `<div class="sh-page"><header class="sh-appbar"><h1>Thêm</h1></header><div class="sh-more">${rows}</div></div>`;
}

function page(location, ctx) {
  if (location === '/more') return morePage(ctx);
  const [title, note] = PAGES[location] || ['Màn', ''];
  const isTabRoot = TABS.some((t) => t.route === location);
  // Web (≥ 1024): màn con mở thẳng từ menu Quản lý ở thanh bên, không có trang "Thêm" để quay về → không có nút back.
  const wide = (ctx.width ?? DEVICE[ctx.device].w) >= DESKTOP;
  const back = !isTabRoot && !wide ? `<button type="button" class="sh-appbar__back" aria-label="Quay lại" data-shell-route="/more">${icon('chevronLeft')}</button>` : '';
  return `<div class="sh-page"><header class="sh-appbar">${back}<h1>${esc(title)}</h1></header>
    <div class="sh-placeholder"><b>Nội dung màn</b><span>${esc(note)}</span><code>${esc(location)}${insideShell(location) ? '' : ' · ngoài StoreShell'}</code></div></div>`;
}

const TAB_LOC = { home: '/', orders: '/orders', products: '/products/items', partners: '/partner', more: '/more' };
const SUB_LOC = { warehouse: '/warehouse', receivables: '/more/receivables', pricing: '/pricing', users: '/more/users-and-roles', account: '/more/my-account', settings: '/more/settings' };

/** Trạng thái ban đầu của một ca. */
export function caseView(screen, state, device) {
  const v = { device, width: DEVICE[device].w, location: '/', isOwner: true, isBlocked: false, orgName: ORGS[0].name, gate: 'ready', org: null };
  if (screen === 'tab') v.location = TAB_LOC[state] || '/';
  if (screen === 'sub') v.location = SUB_LOC[state] || '/more';
  if (screen === 'session') {
    if (state === 'staff') v.isOwner = false;
    if (state === 'blocked') { v.isBlocked = true; v.orgName = 'Chưa chọn tổ chức'; }
    if (state === 'narrow' && device === 'web') v.width = 900;
    if (state === 'long-org') v.orgName = ORGS[2].name;
  }
  if (screen === 'gate') v.gate = state;
  if (screen === 'app04') {
    v.org = { step: 'list', query: '', mode: 'list' };
    if (state === 'search-empty') v.org.query = 'xyz';
    if (state === 'load-error') v.org.mode = 'load-error';
    if (state === 'confirm') v.org = { step: 'confirm', target: 'o2' };
    if (state === 'switching') v.org = { step: 'switching', target: 'o2' };
    if (state === 'success') { v.org = { step: 'done', target: 'o2' }; v.orgName = ORGS[1].name; }
  }
  return v;
}

function overlay(v) {
  if (!v.org) return '';
  const target = ORGS.find((o) => o.id === v.org.target);
  if (v.org.step === 'list') return adaptiveSheet(v.width, orgListBody(v.org), 'Chọn tổ chức');
  if (v.org.step === 'confirm') return adaptiveSheet(v.width, confirmBody(target), `Chuyển sang ${target.name}?`);
  if (v.org.step === 'switching') return switching(target);
  if (v.org.step === 'done') return toast({ title: 'Thành công', message: `Đã chuyển sang ${target.name}.` });
  return '';
}

export function renderView(v) {
  return renderShell({ ...v, overlay: overlay(v) }, page(v.location, v));
}

export function render(screen, state, device) {
  return renderView(caseView(screen, state, device));
}

// ---------------------------------------------------------------- chạy trong trình duyệt
if (typeof document !== 'undefined') {
  const q = new URLSearchParams(location.search);
  if (!q.get('screen')) {
    import('./viewer.js').then((m) => m.mountViewer(document.getElementById('root')));
  } else {
    const device = q.get('device') === 'web' ? 'web' : 'iphone';
    const root = document.getElementById('root');
    const v = caseView(q.get('screen'), q.get('state'), device);
    const paint = () => {
      root.innerHTML = `<div class="sh-stage" data-device="${device}">${renderView(v)}</div>`;
      const s = root.querySelector('[data-org-search]');
      if (s && document.activeElement !== s && v.org?.typing) { s.focus(); s.setSelectionRange(s.value.length, s.value.length); }
    };
    paint();
    root.addEventListener('click', (e) => {
      const t = e.target.closest('[data-shell-route],[data-shell-org],[data-shell-retry],[data-org-close],[data-org-scrim],[data-org-pick],[data-org-back],[data-org-confirm],[data-org-clear],[data-org-retry]');
      if (!t) return;
      const d = t.dataset;
      if (d.shellRoute) { v.location = d.shellRoute; v.org = null; }
      else if ('shellOrg' in d) v.org = { step: 'list', query: '', mode: 'list' };
      else if ('shellRetry' in d) { v.gate = 'loading'; paint(); setTimeout(() => { v.gate = 'ready'; paint(); }, 900); return; }
      else if ('orgClose' in d) v.org = null;
      else if ('orgScrim' in d) { if (e.target !== t) return; v.org = null; }
      else if (d.orgPick) { const o = ORGS.find((x) => x.id === d.orgPick); if (o.current) return; v.org = { step: 'confirm', target: o.id }; }
      else if ('orgBack' in d) v.org = { step: 'list', query: '', mode: 'list' };
      else if (d.orgConfirm) {
        v.org = { step: 'switching', target: d.orgConfirm }; paint();
        setTimeout(() => { v.orgName = ORGS.find((o) => o.id === d.orgConfirm).name; v.org = { step: 'done', target: d.orgConfirm }; paint(); setTimeout(() => { v.org = null; paint(); }, 2500); }, 1200);
        return;
      }
      else if ('orgClear' in d) v.org = { ...v.org, query: '' };
      else if ('orgRetry' in d) { v.org = { ...v.org, mode: 'retrying' }; paint(); setTimeout(() => { v.org = { ...v.org, mode: 'list' }; paint(); }, 900); return; }
      paint();
    });
    root.addEventListener('input', (e) => {
      if (!e.target.matches('[data-org-search]') || !v.org) return;
      v.org = { ...v.org, query: e.target.value, typing: true };
      const reg = root.querySelector('[data-region="org-list"]');
      // Chỉ vẽ lại danh sách, giữ con trỏ trong ô tìm.
      const tmp = document.createElement('div');
      tmp.innerHTML = orgListBody(v.org);
      reg.innerHTML = tmp.querySelector('[data-region="org-list"]').innerHTML;
    });
    document.addEventListener('keydown', (e) => { if (e.key === 'Escape' && v.org && v.org.step !== 'switching') { v.org = null; paint(); } });
  }
}
