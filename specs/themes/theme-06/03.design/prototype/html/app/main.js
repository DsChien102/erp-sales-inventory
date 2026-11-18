import { renderCn01, cn01List, hero, summaryV } from './cn01.js';
import { renderCn02 } from './cn02.js';
import { renderCn03 } from './cn03.js';
import { renderSg13, sg13Model } from './sg13.js';
import { renderPatches } from './patches.js';
import { customers, edgeCustomers, richCustomers, tuanAt } from './data.js';
import { cn03Calc, cn03Scope, derivedHtml, ordersHtml, grp } from './cn03.js';
import { parseMoneyInput } from './format.js';
import { CN03_STATES as cn03States } from './cn03.js';
import { filterCustomers } from './cn01.js';

const SCREENS = {
  cn01: (s, d) => renderCn01(s, d),
  cn02: (s, d) => renderCn02(s, d),
  cn03: (s, d, o) => renderCn03(s, d, o),
  sg13: (s, d, o) => renderSg13(s, d, o),
  patches: (s, d) => renderPatches(s, d),
};

export function render(screen, state, device, opts = {}) {
  const fn = SCREENS[screen];
  return fn ? fn(state, device, opts) : '<p>chưa có màn</p>';
}

// Không có ?screen= → trang xem (viewer.js); có → vẽ đúng một màn (URL chụp ảnh).
if (typeof document !== 'undefined' && !new URLSearchParams(location.search).get('screen')) {
  import('./viewer.js').then((m) => m.mountViewer(document.getElementById('root')));
} else if (typeof document !== 'undefined') {
  const q = new URLSearchParams(location.search);
  const device = q.get('device') === 'web' ? 'web' : 'iphone';
  const root = document.getElementById('root');
  const view = { screen: q.get('screen'), state: q.get('state'), amount: q.get('amount') == null ? null : parseMoneyInput(q.get('amount')) };
  const paint = () => {
    root.innerHTML = `<div class="rc-app" data-device="${device}">${render(view.screen, view.state, device, { ...(view.amount == null ? {} : { amount: view.amount }), ...(view.selectedIds ? { selectedIds: view.selectedIds } : {}) })}</div>`;
  };
  const CN02_STATE = { 'c-tuan': 'full', 'c-lan': 'no-history', 'c-hoa': 'inactive' };
  if (root) {
    paint();
    // Tương tác CN-01: lọc, tìm (300 ms), chạm dòng
    let filter = view.state === 'overdue' ? 'overdue' : 'all';
    let query = '';
    let timer;
    const list = () => (view.state === 'long' ? [...customers, ...edgeCustomers] : view.state === 'many' ? richCustomers : customers);
    const repaintList = () => {
      const reg = root.querySelector('[data-region="cn01-list"]');
      if (reg) reg.innerHTML = cn01List(list(), { filter, query });
      const hr = root.querySelector('[data-region="cn01-hero"]');
      if (hr) hr.innerHTML = hero(summaryV(list()), filter);
    };
    root.addEventListener('click', (e) => {
      const pkAll = e.target.closest('[data-pick-all]');
      if (pkAll && view.screen === 'cn03') {
        const cur = view.selectedIds ?? cn03State().selectedIds ?? [];
        view.selectedIds = cur.length === t0.length ? [] : t0.map((o) => o.id);
        view.amount = cn03Scope(t0, view.selectedIds).scopeTotal;
        paint();
        return;
      }
      const pk = e.target.closest('[data-pick]');
      if (pk && view.screen === 'cn03') {
        const cur = view.selectedIds ?? cn03State().selectedIds ?? [];
        const id = pk.dataset.pick;
        view.selectedIds = t0.map((o) => o.id).filter((x) => (x === id ? !cur.includes(x) : cur.includes(x)));
        view.amount = cn03Scope(t0, view.selectedIds).scopeTotal;
        paint();
        return;
      }
      const mt = e.target.closest('[data-method]');
      if (mt) {
        root.querySelectorAll('[data-method]').forEach((b) => { const on = b === mt; b.classList.toggle('is-selected', on); b.setAttribute('aria-pressed', on); });
        const r = root.querySelector('[data-region="cn03-ref"]');
        if (r) r.innerHTML = mt.dataset.method === 'transfer' ? '<label class="ds24-field rc-field"><span>Mã giao dịch (Không bắt buộc)</span><input class="ds24-field__control" data-ref></label>' : '';
        return;
      }
      const t = e.target.closest('[data-filter],[data-clear-search],[data-nav]');
      if (!t) return;
      if (t.dataset.filter) { filter = t.dataset.filter; repaintList(); }
      else if ('clearSearch' in t.dataset) { query = ''; const i = root.querySelector('[data-search]'); if (i) i.value = ''; repaintList(); }
      else if (t.dataset.nav) {
        const [scr, arg] = t.dataset.nav.split(':');
        view.screen = scr; view.amount = null; view.selectedIds = undefined;
        view.state = scr === 'cn02' ? (CN02_STATE[arg] || 'full') : scr === 'cn03' ? arg : 'full';
        paint();
      }
    });
    // CN-03: gõ tiền → định dạng nghìn, tính lại Sẽ trừ vào / lỗi / nút
    const t0 = tuanAt('before').orders;
    const tot0 = t0.reduce((x, o) => x + o.outstandingMinor, 0);
    const cn03State = () => (view.screen === 'cn03' ? cn03States[view.state] || {} : {});
    const scope = () => cn03Scope(t0, view.selectedIds ?? cn03State().selectedIds ?? []);
    const applyAmount = (n) => {
      view.amount = n;
      const sc = scope();
      const calc = cn03Calc(n, sc.applicable, sc.scopeTotal, sc.customerTotal);
      const ord = root.querySelector('[data-region="cn03-orders"]');
      if (ord) ord.innerHTML = ordersHtml(t0, view.selectedIds ?? cn03State().selectedIds ?? [], calc);
      const reg = root.querySelector('[data-region="cn03-derived"]');
      if (reg) reg.innerHTML = derivedHtml(calc, sc.applicable.length);
      const ok = root.querySelector('[data-confirm]');
      if (ok) ok.disabled = !calc.canSubmit;
    };
    root.addEventListener('input', (e) => {
      if (e.target.matches('[data-amount]')) {
        const n = parseMoneyInput(e.target.value);
        e.target.value = n ? grp(n) : '';
        applyAmount(n);
        return;
      }
      if (!e.target.matches('[data-search]')) return;
      clearTimeout(timer);
      timer = setTimeout(() => { query = e.target.value; repaintList(); }, 300);
    });
  }
}
