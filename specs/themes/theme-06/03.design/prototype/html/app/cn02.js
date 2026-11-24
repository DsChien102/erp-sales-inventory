import { TODAY, customers, edgeCustomers, tuanAt, totalOf } from './data.js';
import { formatVnd, dueLabel } from './format.js';
import { esc, page, dueBadge, inactiveBadge, btn, empty, toast } from './ui.js';
import { icon } from './icon.js';
import { cn01Column } from './cn01.js';

const day = (iso) => `${iso.slice(8, 10)}/${iso.slice(5, 7)}`;
const stamp = (iso) => `${day(iso)} ${iso.slice(11, 16)}`;
const find = (id) => [...customers, ...edgeCustomers].find((c) => c.id === id);

/** Mô hình thuần của CN-02 cho từng state; renderCn02 dùng lại. */
export function cn02Model(state) {
  const tuan = find('c-tuan');
  let c; let moment = null;
  if (state === 'after-offset') { c = tuan; moment = 'afterOffset'; }
  else if (state === 'paid-off') { c = tuan; moment = 'paidOff'; }
  else if (state === 'inactive') c = find('c-hoa');
  else if (state === 'no-history') c = find('c-lan');
  else if (state === 'afterCollect') { c = tuan; moment = 'afterCollect'; }
  else { c = tuan; moment = 'before'; } // full, block-error
  const { orders, history } = moment ? tuanAt(moment) : c;
  const open = orders.filter((o) => o.outstandingMinor > 0);
  return {
    customer: c, orders: open, history,
    total: open.reduce((s, o) => s + o.outstandingMinor, 0),
    overdueCount: open.filter((o) => dueLabel(o.dueDate, TODAY).kind === 'overdue').length,
    historyError: state === 'block-error',
  };
}

function historyRow(h) {
  const when = stamp(h.at);
  if (h.kind === 'collection') {
    const m = h.method === 'cash' ? 'Tiền mặt' : `Chuyển khoản${h.ref ? ` ${esc(h.ref)}` : ''}`;
    return `<div class="rc-hist"><div class="rc-hist__title">Thu ${formatVnd(h.amount).replace(' ₫', '')} · ${m}</div><div class="rc-hist__meta">${when} · ${esc(h.by)}</div><div class="rc-hist__meta">Vào: ${h.allocations.map((a) => `${esc(a.code)} ${formatVnd(a.amount).replace(' ₫', '')}`).join(', ')}</div></div>`;
  }
  if (h.kind === 'order_payment') return `<div class="rc-hist"><div class="rc-hist__title">Thu ${formatVnd(h.amount).replace(' ₫', '')} · đơn ${esc(h.orderCode)}</div><div class="rc-hist__meta">${when}</div></div>`;
  if (h.kind === 'offset') return `<div class="rc-hist"><div class="rc-hist__title">Cấn trừ ${formatVnd(h.amount).replace(' ₫', '')} · từ trả hàng đơn ${esc(h.fromOrder)} (phiếu ${esc(h.returnCode)}) sang đơn ${esc(h.toOrder)}</div><div class="rc-hist__meta">${when} · ${esc(h.by)}</div></div>`;
  return `<div class="rc-hist"><div class="rc-hist__title">Hoàn ${formatVnd(h.amount).replace(' ₫', '')} · đơn ${esc(h.orderCode)}</div><div class="rc-hist__meta">${when}</div></div>`;
}

function orderRow(o) {
  const due = dueLabel(o.dueDate, TODAY);
  return `<button class="rc-order${due.kind === 'overdue' ? ' is-overdue' : ''}" type="button" data-nav="sg09:${o.code}"><span class="rc-order__main"><span class="rc-order__code">${esc(o.code)} · ${day(o.completedAt)}</span>${dueBadge(due)}</span><span class="rc-order__money"><span class="rc-order__owed">Còn nợ ${formatVnd(o.outstandingMinor)}</span><span class="rc-order__total">Tổng ${formatVnd(o.payableMinor)}</span></span><span class="rc-order__chev">${icon('chevronRight', 'icon--sm')}</span></button>`;
}

function content(m) {
  const c = m.customer;
  const sub = m.total > 0
    ? `<div class="rc-chead__sub"><span>${m.orders.length} đơn ·</span>${m.overdueCount ? `<span class="rc-chead__warn">${icon('alert', 'icon--sm')}${m.overdueCount} quá hạn</span>` : `<span>${m.overdueCount} quá hạn</span>`}</div>`
    : '';
  const head = `<section class="rc-chead"><div class="rc-chead__who"><span class="rc-chead__name rc-ellipsis">${esc(c.displayName)}</span>${c.phone ? `<span class="rc-chead__phone">${esc(c.phone)}</span>` : ''}${c.isActive ? '' : inactiveBadge()}</div>
    <div class="rc-chead__owed"><span class="rc-chead__label">${m.total > 0 ? 'Còn nợ' : 'Không còn nợ'}</span><span class="rc-money rc-chead__amount">${formatVnd(m.total)}</span></div>${sub}</section>`;
  const orders = `<h4 class="rc-section">ĐƠN CÒN NỢ (cũ trước)</h4>${m.orders.length ? `<div class="rc-group">${m.orders.map(orderRow).join('')}</div>` : '<p class="rc-note">Không còn đơn nào nợ</p>'}`;
  let hist;
  if (m.historyError) hist = `<div class="rc-blockerr"><p>Không tải được</p>${btn('Thử lại', { kind: 'secondary', attrs: 'data-retry-block' })}</div>`;
  else if (!m.history.length) hist = '<p class="rc-note">Chưa có lần thu nào</p>';
  else hist = `<div class="rc-group">${m.history.map(historyRow).join('')}<button class="rc-more" type="button">Xem thêm</button></div>`;
  return `<div class="rc-scroll rc-cn02">${head}${orders}<h4 class="rc-section">LỊCH SỬ THU &amp; CẤN TRỪ</h4>${hist}</div>`;
}

export function cn02Page(state, device, opts = {}) {
  const m = cn02Model(state);
  const footer = m.total > 0 ? btn('Thu tiền', { full: true, attrs: 'data-nav="cn03:empty"' }) : '';
  return page({ title: 'Công nợ khách hàng', back: device === 'iphone', device, body: content(m), footer }) + (opts.toast ? toast(opts.toast) : '');
}

export function renderCn02(state, device, opts = {}) {
  if (device === 'web') {
    const m = cn02Model(state);
    return `<div class="rc-twocol"><div class="rc-col">${cn01Column('all', 'web', { selectedId: m.customer.id })}</div><div class="rc-col rc-col--right">${cn02Page(state, device, opts)}</div></div>`;
  }
  return cn02Page(state, device, opts);
}
