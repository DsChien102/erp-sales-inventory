// CN-01 Công nợ phải thu — bố cục "Quá hạn dẫn đầu" (phương án B đã chọn 2026-11-18).
// Hero = tiền quá hạn; tổng còn phải thu thu nhỏ; danh sách phẳng xếp theo MỨC KHẨN (quá hạn lâu nhất → đến hạn hôm nay → hẹn gần nhất → không hẹn),
// cùng mức thì nợ nhiều trước. Chữ chỉ dùng bậc DESIGN.md: 13 / 14 / 22 / 28.
import { TODAY, customers, edgeCustomers, richCustomers, totalOf } from './data.js';
import { formatVnd, customerDueLabel, overdueAmountMinor } from './format.js';
import { icon } from './icon.js';
import { esc, page, dueBadge, inactiveBadge, empty, skeletonRows } from './ui.js';

export const fold = (s) => String(s).normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/đ/g, 'd').replace(/Đ/g, 'D').toLowerCase();

const RANK = { overdue: 0, today: 1, upcoming: 2, none: 3 };
const nextDue = (c) => c.orders.filter((o) => o.outstandingMinor > 0 && o.dueDate).map((o) => o.dueDate).sort()[0] || '9999';
const byDebt = (a, b) => totalOf(b) - totalOf(a) || a.displayName.localeCompare(b.displayName, 'vi');

/** Mức khẩn: quá hạn lâu nhất trước, rồi đến hạn hôm nay, rồi hẹn gần nhất, rồi không hẹn; cùng mức thì nợ nhiều trước. */
export function sortedByUrgency(list) {
  return [...list].sort((a, b) => {
    const la = customerDueLabel(a.orders, TODAY); const lb = customerDueLabel(b.orders, TODAY);
    return RANK[la.kind] - RANK[lb.kind] || (lb.days || 0) - (la.days || 0) || nextDue(a).localeCompare(nextDue(b)) || byDebt(a, b);
  });
}

/** Ô tổng: tổng còn phải thu, số khách, và phần quá hạn (tiền, số khách, ngày lâu nhất). */
export function summaryV(list) {
  const over = list.filter((c) => customerDueLabel(c.orders, TODAY).kind === 'overdue');
  return {
    totalMinor: list.reduce((s, c) => s + totalOf(c), 0),
    customerCount: list.length,
    overdueMinor: over.reduce((s, c) => s + overdueAmountMinor(c.orders, TODAY), 0),
    overdueCustomerCount: over.length,
    oldestOverdueDays: Math.max(0, ...over.map((c) => customerDueLabel(c.orders, TODAY).days)),
  };
}

export function filterCustomers(list, { filter = 'all', query = '' } = {}) {
  let r = list;
  if (filter === 'overdue') r = r.filter((c) => customerDueLabel(c.orders, TODAY).kind === 'overdue');
  const q = fold(query.trim());
  if (q) r = r.filter((c) => fold(c.displayName).includes(q) || (c.phone || '').replace(/\s/g, '').includes(q.replace(/\s/g, '')));
  return sortedByUrgency(r);
}

/** Dòng khách: trái = tên + SĐT·đơn, phải = tiền + nhãn hạn. */
function row(c, { selectedId, overdueOnly }) {
  const l = customerDueLabel(c.orders, TODAY);
  const n = c.orders.filter((o) => o.outstandingMinor > 0).length;
  const sub = `${c.phone ? `${esc(c.phone)} · ` : ''}${n} đơn`;
  const extra = overdueOnly && l.kind === 'overdue' ? `<span class="rc-due__amount">· ${formatVnd(overdueAmountMinor(c.orders, TODAY))}</span>` : '';
  const sel = selectedId === c.id;
  return `<button class="rv-row${sel ? ' is-selected' : ''}" type="button" data-nav="cn02:${c.id}"${sel ? ' aria-current="true"' : ''}>
    <span class="rv-row__main"><span class="rv-row__name"><span class="rc-ellipsis" title="${esc(c.displayName)}">${esc(c.displayName)}</span>${c.isActive ? '' : inactiveBadge()}</span><span class="rv-row__sub">${sub}</span></span>
    <span class="rv-row__side"><span class="rv-money">${formatVnd(totalOf(c))}</span><span class="rv-row__due">${dueBadge(l)}${extra}</span></span>
  </button>`;
}

export function cn01List(list, opts = {}) {
  const shown = filterCustomers(list, opts);
  if (!shown.length) return empty({ title: 'Không tìm thấy khách phù hợp.', action: 'Xoá tìm kiếm', actionAttrs: 'data-clear-search', iconName: 'search' });
  const count = shown.length < list.length ? `<p class="rv-showing" role="status">Đang hiển thị ${shown.length} / ${list.length} khách</p>` : '';
  return `${count}<div class="rv-list">${shown.map((c) => row(c, { ...opts, overdueOnly: opts.filter === 'overdue' })).join('')}${opts.loadingMore ? '<div class="rc-loadmore"><span class="rc-spinner" role="status" aria-label="Đang tải thêm"></span></div>' : ''}</div>`;
}

export function hero(s, filter = 'all') {
  if (!s.overdueCustomerCount) return `<div class="rv-hero rv-hero--ok" role="status">${icon('checkCircle')}<span class="rv-hero__text"><b>Không có khoản nào quá hạn</b><span>Tất cả khách đang nợ còn trong hạn hẹn.</span></span></div>`;
  const on = filter === 'overdue';
  return `<button class="rv-hero${on ? ' is-active' : ''}" type="button" data-filter="${on ? 'all' : 'overdue'}" aria-pressed="${on}" aria-label="Quá hạn ${formatVnd(s.overdueMinor)}, ${s.overdueCustomerCount} khách. ${on ? 'Đang lọc quá hạn, bấm để xem tất cả' : 'Bấm để chỉ xem khách quá hạn'}"><span class="rv-hero__label">${icon('alert', 'icon--sm')}Quá hạn</span><span class="rv-hero__amount rv-money">${formatVnd(s.overdueMinor)}</span><span class="rv-hero__sub">${s.overdueCustomerCount} khách · lâu nhất ${s.oldestOverdueDays} ngày</span><span class="rv-hero__chev">${on ? 'Xem tất cả' : icon('chevronRight', 'icon--sm')}</span></button>`;
}

function head(list, { filter, query }) {
  const s = summaryV(list);
  return `<div data-region="cn01-hero">${hero(s, filter)}</div>
  <div class="rv-total"><span class="rv-total__label">Tổng còn phải thu</span><span class="rv-total__row"><span class="rv-total__quiet rv-money">${formatVnd(s.totalMinor)}</span><span class="rv-total__count">${s.customerCount} khách</span></span></div>
  <label class="rc-search">${icon('search')}<input type="text" data-search value="${esc(query)}" placeholder="Tìm tên, SĐT" aria-label="Tìm tên, SĐT"><button class="rc-search__clear" type="button" aria-label="Xoá tìm kiếm" data-clear-search>${icon('close', 'icon--sm')}</button></label>`;
}

const DATASETS = {
  long: () => [...customers, ...edgeCustomers],
  many: () => richCustomers,
  'no-overdue': () => customers.filter((c) => customerDueLabel(c.orders, TODAY).kind !== 'overdue'),
};

/** Cột / màn CN-01 (không gồm khung hai cột web). */
export function cn01Column(state, device, { selectedId = null } = {}) {
  const list = DATASETS[state]?.() ?? customers;
  const filter = state === 'overdue' ? 'overdue' : 'all';
  const query = state === 'search-empty' ? 'xyz' : '';
  const back = device === 'iphone';
  const title = 'Công nợ phải thu';
  if (state === 'loading') return page({ title, back, device, body: `<div class="rv-skel-hero skeleton"></div><div class="rc-skel-controls"><div class="skeleton skeleton--search"></div></div>${skeletonRows(6)}` });
  if (state === 'empty') return page({ title, back, device, body: empty({ title: 'Không có khách nào đang nợ', description: 'Đơn bán nợ sẽ hiện ở đây.' }) });
  if (state === 'error') return page({ title, back, device, body: empty({ title: 'Không tải được công nợ', action: 'Thử lại', actionAttrs: 'data-retry', iconName: 'alert' }) });
  return page({ title, back, device, body: `${head(list, { filter, query })}<div data-region="cn01-list">${cn01List(list, { filter, query, selectedId, loadingMore: state === 'loading-more' })}</div>` });
}

export function renderCn01(state, device) {
  if (device === 'web') return `<div class="rc-twocol"><div class="rc-col">${cn01Column(state, device)}</div><div class="rc-col rc-col--right"><div class="rc-pick">Chọn một khách để xem công nợ</div></div></div>`;
  return cn01Column(state, device);
}
