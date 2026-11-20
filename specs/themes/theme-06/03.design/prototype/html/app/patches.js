import { formatVnd } from './format.js';
import { icon } from './icon.js';
import { esc, dueBadge, btn, statusBar } from './ui.js';

// Hàng trong khung minh hoạ: { t, sub, v, nav, isNew }
const row = (r) => `<div class="rc-prow${r.isNew ? ' is-new' : ''}"><span class="rc-prow__main"><span class="rc-prow__t">${esc(r.t)}</span>${r.sub ? `<span class="rc-prow__sub">${r.html ? r.sub : esc(r.sub)}</span>` : ''}</span>${r.v ? `<span class="rc-money rc-prow__v">${esc(r.v)}</span>` : ''}${r.nav ? `<span class="rc-prow__nav">${icon('chevronRight', 'icon--sm')}</span>` : ''}${r.isNew ? '<span class="rc-newtag">MỚI</span>' : ''}</div>`;
const card = (title, rows) => `<div class="rc-pcard">${title ? `<h4 class="rc-section rc-section--tight">${esc(title)}</h4>` : ''}${rows.map(row).join('')}</div>`;
const half = (label, inner, isNew = false) => `<section class="rc-half${isNew ? ' rc-half--new' : ''}"><div class="rc-half__label">${label}</div><div class="rc-half__frame">${inner}</div></section>`;
const m = (n) => formatVnd(n);

const SCREENS = {
  sg09: {
    title: 'Chi tiết đơn · DH-002',
    before: () => card('THANH TOÁN & CÔNG NỢ', [{ t: 'Tổng phải trả', v: m(10e6) }, { t: 'Đã thanh toán', v: m(2e6) }, { t: 'Còn nợ', v: m(8e6) }]),
    after: () => card('THANH TOÁN & CÔNG NỢ', [{ t: 'Tổng phải trả', v: m(10e6) }, { t: 'Đã thanh toán', v: m(2e6) }, { t: 'Còn nợ', v: m(8e6) }, { t: 'Xem công nợ của khách', nav: true, isNew: true }]),
  },
  sg09b: {
    title: 'Giao dịch của đơn',
    before: () => card('ĐƠN NGUỒN · DH-001', [{ t: 'Từ đơn hàng gốc', v: m(4e6) }, { t: 'Đã thanh toán (TM)', v: m(4e6) }]),
    after: () => `${card('ĐƠN NGUỒN · DH-001', [{ t: 'Từ đơn hàng gốc', v: m(4e6) }, { t: 'Đã thanh toán (TM)', v: m(4e6) }, { t: 'Đã cấn trừ', v: m(500000), isNew: true }, { t: 'Cấn trừ · sang DH-002', v: m(500000), nav: true, isNew: true }])}${card('ĐƠN NHẬN · DH-002', [{ t: 'Cấn trừ · từ DH-001', v: m(500000), nav: true, isNew: true }])}`,
  },
  sg09c: {
    title: 'Lịch sử đơn',
    before: () => card('', [{ t: 'Hoàn tất đơn', sub: '05/11 10:00' }, { t: 'Ghi nhận thanh toán', sub: '06/11 14:20' }]),
    after: () => card('', [{ t: 'Hoàn tất đơn', sub: '05/11 10:00' }, { t: 'Ghi nhận thanh toán', sub: '06/11 14:20' }, { t: 'Ghi nhận thu nợ theo khách', sub: '18/11 09:30', isNew: true }, { t: 'Cấn trừ công nợ', sub: '18/11 10:15', isNew: true }]),
  },
  sg14: {
    title: 'Kết quả đổi/trả',
    before: () => `${card('', [{ t: 'Đã ghi nhận đổi/trả', sub: 'Phiếu #DT-0001' }, { t: 'Hoàn cho khách', v: m(0) }])}<div class="rc-pbtn">${btn('Xong', { full: true })}</div>`,
    after: () => `${card('', [{ t: 'Đã ghi nhận đổi/trả', sub: 'Phiếu #DT-0001' }, { t: 'Cấn trừ vào DH-002', v: m(500000), isNew: true }, { t: 'Hoàn cho khách', v: m(0) }])}<div class="rc-pbtn rc-prow is-new">${btn('Xem công nợ của khách', { kind: 'secondary', full: true })}<span class="rc-newtag">MỚI</span></div><div class="rc-pbtn">${btn('Xong', { full: true })}</div>`,
  },
  pt07: {
    title: 'Hồ sơ đối tác · Anh Tuấn',
    before: () => card('', [{ t: 'Anh Tuấn', sub: '0901 234 567' }, { t: 'Vai trò', v: 'Khách hàng' }]),
    after: () => `${card('', [{ t: 'Anh Tuấn', sub: '0901 234 567' }, { t: 'Vai trò', v: 'Khách hàng' }])}${card('', [{ t: 'Công nợ', isNew: true, nav: true, sub: `<span class="rc-pt-owed">Còn nợ ${m(18e6)} · 3 đơn</span>${dueBadge({ kind: 'overdue', text: 'Quá hạn 8 ngày' })}`, html: true }])}${card('', [{ t: 'Công nợ', isNew: true, nav: true, sub: 'Không còn nợ' }])}`,
  },
  'more-menu': {
    title: 'Thêm',
    before: () => card('', [{ t: 'Khách hàng & NCC', nav: true }, { t: 'Báo cáo', sub: 'Doanh thu, tồn kho, công nợ', nav: true }]),
    after: () => card('', [{ t: 'Khách hàng & NCC', nav: true }, { t: 'Công nợ phải thu', sub: 'Khách đang nợ, quá hạn, thu tiền', nav: true, isNew: true }, { t: 'Báo cáo', sub: 'Doanh thu, tồn kho, công nợ', nav: true }]),
  },
};

export function renderPatches(state, device) {
  const s = SCREENS[state];
  const bar = (t) => `<div class="rc-pbar">${esc(t)}</div>`;
  const before = half('TRƯỚC · khung minh hoạ, nền Flutter hiện có', bar(s.title) + s.before());
  const after = half('SAU', bar(s.title) + s.after(), true);
  return `${device === 'iphone' ? statusBar() : ''}<div class="rc-patches rc-patches--${device}">${before}${after}</div>`;
}
