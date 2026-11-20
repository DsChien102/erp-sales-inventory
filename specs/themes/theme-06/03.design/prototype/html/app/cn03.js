import { tuanAt, TODAY } from './data.js';
import { allocateOldestFirst } from './allocate.js';
import { formatVnd, dueLabel } from './format.js';
import { icon, k7CheckMark } from './icon.js';
import { esc, btn, sheet, dialog, dueBadge } from './ui.js';
import { renderCn02 } from './cn02.js';

const NAME = 'Anh Tuấn';
export const grp = (n) => String(n).replace(/\B(?=(\d{3})+(?!\d))/g, '.');
const bare = (n) => formatVnd(n).replace(' ₫', '');

export const CN03_STATES = {
  empty: { amount: 0, selectedIds: [] },
  valid: { amount: 10e6, selectedIds: ['DH-001', 'DH-002', 'DH-003'] },
  over: { amount: 18000001, selectedIds: ['DH-001', 'DH-002', 'DH-003'] },
  transfer: { amount: 10e6, method: 'transfer', ref: 'FT2611180001', selectedIds: ['DH-001', 'DH-002', 'DH-003'] },
  confirm: { amount: 10e6, overlay: 'confirm', selectedIds: ['DH-001', 'DH-002', 'DH-003'] },
  submitting: { amount: 10e6, phase: 'submitting', selectedIds: ['DH-001', 'DH-002', 'DH-003'] },
  'submit-error': { amount: 10e6, phase: 'error', selectedIds: ['DH-001', 'DH-002', 'DH-003'] },
  changed: { amount: 10e6, overlay: 'changed', selectedIds: ['DH-001', 'DH-002', 'DH-003'] },
  'leave-confirm': { amount: 10e6, overlay: 'leave', selectedIds: ['DH-001', 'DH-002', 'DH-003'] },
  all: { amount: 18e6, selectedIds: ['DH-001', 'DH-002', 'DH-003'] },
  one: { amount: 8e6, selectedIds: ['DH-002'] },
  multi: { amount: 5e6, selectedIds: ['DH-001', 'DH-003'] },
  'one-over': { amount: 8000001, selectedIds: ['DH-002'] },
  'one-confirm': { amount: 8e6, overlay: 'confirm', selectedIds: ['DH-002'] },
};

/** Thuần: phạm vi áp dụng = các đơn đã tick (giữ thứ tự cũ trước). Số tiền mặc định = Σ còn nợ các đơn đã tick (scopeTotal). */
export function cn03Scope(orders, selectedIds = []) {
  const applicable = orders.filter((o) => selectedIds.includes(o.id));
  return { applicable, scopeTotal: applicable.reduce((s, o) => s + o.outstandingMinor, 0), customerTotal: orders.reduce((s, o) => s + o.outstandingMinor, 0) };
}

/** Thuần: kết quả tính cho một số tiền (dùng cả khi gõ tay). */
export function cn03Calc(amount, orders, total, customerTotal = total) {
  const over = amount > total;
  const alloc = amount > 0 && !over ? allocateOldestFirst(orders, amount) : [];
  return { over, alloc, after: customerTotal - (over ? 0 : amount), canSubmit: amount > 0 && !over };
}

export function allocHtml(calc, orders) {
  if (!calc.alloc.length) return '';
  const code = (id) => orders.find((o) => o.id === id).code;
  return `<h4 class="rc-section rc-section--tight">SẼ TRỪ VÀO</h4>${calc.alloc.map((a) => `<div class="rc-alloc"><span>${esc(code(a.id))}</span><span class="rc-alloc__amt">${bare(a.allocatedMinor)}</span><span class="rc-alloc__res">${a.outstandingAfterMinor === 0 ? '→ hết nợ' : `→ còn ${bare(a.outstandingAfterMinor)}`}</span></div>`).join('')}<div class="rc-alloc-total"><span>Khách còn nợ sau khi thu</span><span class="rc-money">${formatVnd(calc.after)}</span></div>`;
}

/** Danh sách đơn có ô tick; kết quả chia nằm ngay trong từng dòng. Ô tick đầu danh sách = tất cả đơn (= trả hết). */
export function ordersHtml(allOrders, selectedIds, calc, lock = '') {
  const by = Object.fromEntries(calc.alloc.map((x) => [x.id, x]));
  const allOn = allOrders.length > 0 && allOrders.every((o) => selectedIds.includes(o.id));
  const someOn = selectedIds.length > 0 && !allOn;
  const total = allOrders.reduce((s, o) => s + o.outstandingMinor, 0);
  const master = `<button class="rw-master" type="button" role="checkbox" aria-checked="${allOn ? 'true' : someOn ? 'mixed' : 'false'}" data-pick-all${lock}>${k7CheckMark(allOn)}<span class="rw-master__label">Tất cả đơn · trả hết</span><span class="rw-money">${bare(total)}</span></button>`;
  const rows = allOrders.map((o) => {
    const on = selectedIds.includes(o.id);
    const a = by[o.id];
    const res = !on ? '<span class="rw-res rw-res--off">Không thu</span>'
      : a ? `<span class="rw-res">Trừ ${bare(a.allocatedMinor)} → ${a.outstandingAfterMinor === 0 ? 'hết nợ' : `còn ${bare(a.outstandingAfterMinor)}`}</span>`
      : calc.alloc.length ? '<span class="rw-res rw-res--off">Chưa nhận</span>' : '';
    return `<button class="rw-order${on ? ' is-on' : ''}" type="button" role="checkbox" aria-checked="${on}" data-pick="${esc(o.id)}"${lock}>${k7CheckMark(on)}<span class="rw-order__main"><span class="rw-order__code">${esc(o.code)}</span>${dueBadge(dueLabel(o.dueDate, TODAY))}</span><span class="rw-order__side"><span class="rw-money">Còn nợ ${bare(o.outstandingMinor)}</span>${res}</span></button>`;
  }).join('');
  return `<div class="rw-orders" role="group" aria-label="Chọn đơn nhận tiền">${master}${rows}</div>`;
}

export function derivedHtml(calc, picked = 0) {
  if (!picked) return '<small class="rc-hint">Chọn ít nhất một đơn để thu.</small>';
  return `${calc.over ? '<small class="rc-error" role="alert">Số tiền vượt quá tổng còn nợ của các đơn đã chọn.</small>' : ''}${calc.alloc.length ? `<div class="rw-after"><span>Khách còn nợ sau khi thu</span><span class="rw-money">${formatVnd(calc.after)}</span></div>` : ''}`;
}

function form({ amount, method = 'cash', ref = '', phase, selectedIds = [] }, allOrders, customerTotal) {
  const { applicable: orders, scopeTotal: total } = cn03Scope(allOrders, selectedIds);
  const calc = cn03Calc(amount, orders, total, customerTotal);
  const lock = phase === 'submitting' ? ' disabled' : '';
  const seg = [['cash', 'Tiền mặt'], ['transfer', 'Chuyển khoản']].map(([k, t]) => `<button type="button" class="ds-segment${k === method ? ' is-selected' : ''}" data-method="${k}" aria-pressed="${k === method}"${lock}>${t}</button>`).join('');
  return `<button class="rc-close" type="button" aria-label="Đóng" data-close>${icon('close')}</button>
  <p class="rw-who">${NAME} · Còn nợ ${formatVnd(customerTotal)}</p>
  <div data-region="cn03-orders">${ordersHtml(allOrders, selectedIds, calc, lock)}</div>
  <span class="rw-label">Số tiền</span>
  <div class="rw-amount"><input class="ds24-field__control" data-amount inputmode="numeric" autocomplete="off" aria-label="Số tiền" value="${amount ? grp(amount) : ''}"${lock}><span class="rw-amount__unit">đ</span></div>
  <div class="rc-method"><span class="rc-method__label">Phương thức</span><div class="ds-segmented" role="group" aria-label="Phương thức">${seg}</div></div>
  <div data-region="cn03-ref">${method === 'transfer' ? `<label class="ds24-field rc-field"><span>Mã giao dịch (Không bắt buộc)</span><input class="ds24-field__control" data-ref value="${esc(ref)}"${lock}></label>` : ''}</div>
  <div data-region="cn03-derived">${derivedHtml(calc, orders.length)}</div>
  ${phase === 'error' ? `<div class="rc-submit-error" role="alert"><span>Không ghi nhận được. Thử lại?</span>${btn('Thử lại', { kind: 'secondary', attrs: 'data-submit' })}</div>` : ''}`;
}

function actions(phase, canSubmit) {
  return `${btn('Quay lại', { kind: 'secondary', attrs: `data-close${phase === 'submitting' ? ' disabled' : ''}` })}${btn(phase === 'submitting' ? 'Đang ghi nhận...' : 'Xác nhận thu', { attrs: 'data-confirm', disabled: !canSubmit || phase === 'submitting' })}`;
}

export function renderCn03(state, device, opts = {}) {
  if (state === 'success') return renderCn02('afterCollect', device, { toast: `Đã thu ${formatVnd(10e6)} từ ${NAME}` });
  const st = { amount: 0, method: 'cash', ref: '', ...CN03_STATES[state] };
  if (opts.amount != null) st.amount = opts.amount;
  if (opts.selectedIds) st.selectedIds = opts.selectedIds;
  const { orders: allOrders } = tuanAt('before');
  const { applicable: orders, scopeTotal, customerTotal } = cn03Scope(allOrders, st.selectedIds);
  const calc = cn03Calc(st.amount, orders, scopeTotal, customerTotal);
  const base = renderCn02('full', device);
  const main = sheet({ title: 'Thu tiền', body: form(st, allOrders, customerTotal), actions: actions(st.phase, calc.canSubmit), device });
  let over = '';
  if (st.overlay === 'confirm') {
    const m = st.method === 'cash' ? 'Tiền mặt' : 'Chuyển khoản';
    over = sheet({ title: 'Xác nhận thu tiền?', body: `<p class="rc-confirm-line">Thu ${formatVnd(st.amount)} ${m} từ ${NAME}${orders.length === allOrders.length ? ' · tất cả đơn' : orders.length === 1 ? ` · đơn ${esc(orders[0].code)}` : ` · ${orders.length} đơn đã chọn`}</p>${allocHtml(calc, orders)}`, actions: `${btn('Quay lại', { kind: 'secondary' })}${btn('Xác nhận')}`, device }).replace('class="sheet-backdrop"', 'class="sheet-backdrop rc-top"').replace('class="confirm-backdrop"', 'class="confirm-backdrop rc-top"');
  } else if (st.overlay === 'changed') {
    over = dialog({ title: 'Công nợ của khách vừa thay đổi. Hãy tải lại rồi thử lại.', actions: btn('Tải lại') }).replace('class="confirm-backdrop"', 'class="confirm-backdrop rc-top"');
  } else if (st.overlay === 'leave') {
    over = dialog({ title: 'Bỏ khoản thu đang nhập?', actions: `${btn('Ở lại', { kind: 'secondary' })}${btn('Bỏ', { kind: 'danger' })}` }).replace('class="confirm-backdrop"', 'class="confirm-backdrop rc-top"');
  }
  return base + (st.overlay === 'confirm' ? '' : main) + over;
}
