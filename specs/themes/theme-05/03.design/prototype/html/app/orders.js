// SG-08 Đơn hàng (/orders, tab "Đơn hàng" — TRONG StoreShell) + sheet bộ lọc.
// Nguồn Dart (apps/erp/lib/features/sales/presentation/):
//   pages/sales_order_list_page.dart, widgets/{sales_order_list_body, sales_order_list_card, sales_order_list_search_bar, sales_order_saved_search_chips,
//   sales_order_list_empty_state, sales_order_list_no_result_state, sales_order_list_error_state, sales_order_list_blocked_state,
//   sales_order_filter_bottom_sheet}.dart, models/sales_order/{sales_order_list_item_vm, sales_order_saved_search_preset}.dart,
//   support/sales_order_list_mapper.dart, logic/{sales_order_list_cubit, sales_order_list_state}.dart (câu lỗi, đếm bộ lọc).
// Key Dart dùng "sg07" / "e03_u01" cho màn này (đánh số cũ); TH-05 / CHECKLIST gọi là SG-08.
import { DESKTOP, SIDE_WIDTH } from '../shared/shell.js';
import {
  appBar, badge, button, chip, emptyDesc, emptyMedia, emptyState, emptyTitle, esc, fab, gap, icon, scaffold, searchBar, skeleton,
} from './ds.js';
import { ORDERS, money, orderMetaLine } from './data.js';

/** Bề ngang vùng nội dung của khung: web ≥ 1024 trừ thanh bên 240. */
export const contentWidth = (width) => (width >= DESKTOP ? width - SIDE_WIDTH : width);

/** SalesOrderSavedSearchPreset.label — chip không kèm số đếm. */
export const PRESETS = ['Tất cả', 'Còn phải thu', 'Chưa phát hành HĐĐT'];

/** SalesOrderListState.activeFilterCount: preset ≠ Tất cả cũng tính 1 (dù sheet lọc không có mục preset). */
export function activeFilterCount({ preset = 0, time = 0, lifecycle = 0, settlement = 0, postSale = 0, eInvoice = 0 } = {}) {
  return [preset, time, lifecycle, settlement, postSale, eInvoice].filter((x) => x !== 0).length;
}

/** SalesOrderListNoResultState: có từ khoá → “…” + xuống dòng; nút luôn "Xóa tìm kiếm" (kể cả khi chỉ đang lọc). */
export function noResultDescription(query) {
  const q = (query || '').trim();
  return q ? `Không có đơn phù hợp với “${q}”\ntrong phạm vi hiện tại.` : 'Không có đơn phù hợp trong phạm vi hiện tại.';
}

/** Mapper: không có khách → "Khách Lẻ" (L hoa). */
export const listCustomerLabel = (o) => o.customer || 'Khách Lẻ';

const LIST = {
  loaded: { total: 128 },
  outstanding: { total: 7, preset: 1, items: ['o2', 'o3'] },
  filtered: { total: 4, filters: { time: 1, lifecycle: 1 }, items: ['o1', 'o2', 'o4', 'o7'] },
  search: { total: 2, query: 'mai', items: ['o2', 'o7'] },
  loading: { total: 0 },
  empty: { total: 0, items: [] },
  'no-result': { total: 0, query: 'xyz', items: [] },
  'no-result-filter': { total: 0, filters: { lifecycle: 2, time: 1 }, items: [] },
  error: { total: 0 },
  'load-more': { total: 128, more: 'loading' },
  'load-more-error': { total: 128, more: 'error' },
};
export const listState = (state) => {
  const s = LIST[state] || LIST.loaded;
  const items = s.items ? ORDERS.filter((o) => s.items.includes(o.id)) : ORDERS;
  return { preset: 0, filters: {}, query: '', ...s, items };
};

/**
 * SalesOrderListCard (VCard đệm 16, viền borderStrong): hàng 1 = [tên H4 w600 1 dòng / khe 4 / "SĐT · cửa hàng" bodySmall / khe 8 / tổng bodyDefaultMono w600]
 * + khe 8 + badge "Hoàn tất" (success) | "Đã hủy" (danger); khe 8; hàng 2 = số đơn bodySmall | giờ HH:mm bodySmall. Không có nhãn thanh toán / HĐĐT.
 */
function orderCard(o) {
  const meta = orderMetaLine(o.phone);
  const cancelled = o.status === 'cancelled';
  return `<div class="t5-card t5-card--pad t5-ocard" role="button" aria-label="${esc(o.number)}">
    <div class="t5-ocard__top"><div class="t5-ocard__main"><b class="t5-ocard__name">${esc(listCustomerLabel(o))}</b>${meta ? `${gap(4)}<span class="t5-ocard__meta">${esc(meta)}</span>` : ''}${gap(8)}<em class="t5-ocard__total">${esc(money(o.total))}</em></div>
      <i class="t5-gap-h8"></i>${badge(cancelled ? 'Đã hủy' : 'Hoàn tất', { tone: cancelled ? 'danger' : 'success' })}</div>${gap(8)}
    <div class="t5-ocard__foot"><span>${esc(o.number)}</span><span>${esc(o.time)}</span></div></div>`;
}

/** _OrderCardSkeleton: Container đệm 16 viền borderDefault; Expanded(VSkeleton 140) bị kéo đầy hàng → vạch 1 rộng gần hết thẻ. */
const cardSkeleton = () => `<div class="t5-oskel"><div class="t5-row">${skeleton(24, { radius: 4, w: 'auto' }).replace('class="t5-skel"', 'class="t5-skel t5-skel--grow"')}${skeleton(24, { radius: 4, w: '72px' })}</div>${gap(4)}
  ${skeleton(20, { radius: 4, w: '180px' })}${gap(8)}${skeleton(22, { radius: 4, w: '110px' })}${gap(8)}<div class="t5-row t5-row--0">${skeleton(20, { radius: 4, w: 'auto' }).replace('class="t5-skel"', 'class="t5-skel t5-skel--grow"')}${skeleton(20, { radius: 4, w: '44px' })}</div></div>`;

/** VEmptyState bordered nền surface, cao theo nội dung (Column min), trong VPagePadding; khe 8 giữa header và nút. */
const boxed = ({ media, title, desc, action, tone = '' }) => `<div class="t5-pad">${emptyState({ header: [emptyMedia(media), emptyTitle(title), emptyDesc(desc)], content: `${gap(8)}${action}`, tone, fill: false, cls: 't5-empty--boxed' })}</div>`;

function listBody(state, st) {
  if (state === 'loading') return `<div class="t5-olist t5-olist--skel">${Array.from({ length: 4 }, cardSkeleton).join('')}</div>`;
  if (state === 'error') {
    return boxed({ media: 'circleX', title: 'Không thể tải danh sách', desc: 'Không thể tải danh sách đơn hàng.', tone: 'danger', action: button('Thử lại', { variant: 'tertiary', cls: 't5-btn--fg-danger' }) });
  }
  if (state === 'empty') {
    return boxed({ media: 'info', title: 'Chưa có đơn hàng', desc: 'Đơn hàng hoàn tất sẽ xuất hiện tại đây.', action: button('Tạo đơn bán hàng', { variant: 'tertiary' }) });
  }
  if (state.startsWith('no-result')) {
    return boxed({ media: 'search', title: 'Không tìm thấy đơn hàng', desc: noResultDescription(st.query), action: button('Xóa tìm kiếm', { variant: 'tertiary' }) });
  }
  let footer = '';
  if (st.more === 'loading') footer = `<div class="t5-loadmore t5-loadmore--8"><span class="t5-spin t5-spin--40"></span></div>`;
  if (st.more === 'error') {
    footer = `<div class="t5-card t5-card--p12 t5-row"><span class="t5-omore">Không thể tải thêm đơn hàng. Vui lòng thử lại.</span>${button('Thu lai', { size: 'small' })}</div>`;
  }
  return `<div class="t5-olist"${st.more ? ' data-scroll-end' : ''}>${st.items.map(orderCard).join('')}${footer}</div>`;
}

/** _FilterButton: VIconBox 44 (icon tune 20) bo nút; đang lọc → nền successBg, viền + icon success, badge strong success nhỏ ở (phải −8, trên −6). Viền thường borderDefault (ô tìm borderInput). */
function filterButton(count) {
  const on = count > 0;
  return `<span class="t5-ofilter"><span class="t5-ibox t5-ofilter__box${on ? ' is-on' : ''}" role="button" aria-label="Lọc đơn hàng">${icon('tune')}</span>${on ? `<b class="t5-ofilter__badge">${count}</b>` : ''}</span>`;
}

/**
 * VPageScaffold "Đơn hàng" (tiêu đề trái, phụ đề "<N> đơn hàng" / "Đang tải…", không ←), FAB xanh "+" (Tạo đơn bán hàng).
 * Thân: khe 8, [ô tìm | khe 8 | nút lọc] (VPagePadding), khe 8, chip nhanh cuộn ngang (chọn → tone success), khe 8, danh sách.
 * Khung: route trong StoreShell → web: chỗ đặt = 1040 (cột 720), nhưng gutter nút nổi tính theo cửa sổ 1280 → FAB lọt vào trong cột.
 * sheet: HTML sheet lọc — showVBottomSheet mở ở navigator lồng của ShellRoute → chỉ phủ vùng nội dung (cả iPhone và web).
 */
export function orderListPage(state, v, { sheet = '' } = {}) {
  const placeWidth = contentWidth(v.width);
  if (state === 'blocked') {
    const body = emptyState({ header: [emptyMedia('alert'), emptyTitle('Không có quyền xem đơn hàng'), emptyDesc('Tài khoản của bạn không có quyền truy cập danh sách đơn hàng trong phạm vi này.')], tone: 'warning', content: `${gap(8)}${button('Quay lại', { variant: 'tertiary', cls: 't5-btn--fg-warning' })}`, cls: 't5-empty--twarning' });
    return `<div class="t5-area">${scaffold({ appbar: appBar('Đơn hàng'), body, placeWidth, windowWidth: v.width })}</div>`;
  }
  const st = listState(state);
  const sub = state === 'loading' ? 'Đang tải…' : `${st.total} đơn hàng`;
  const count = activeFilterCount({ preset: st.preset, ...st.filters });
  const chips = `<div class="t5-hscroll"><div class="t5-chiprow">${PRESETS.map((p, i) => chip(p, { tone: i === st.preset ? 'success' : 'neutral' })).join('')}</div></div>`;
  const body = `${gap(8)}<div class="t5-pad t5-row">${searchBar({ value: st.query, hint: 'Tìm đơn hàng, khách hàng, SĐT', clear: !!st.query })}${filterButton(count)}</div>${gap(8)}
    <div class="t5-pad">${chips}</div>${gap(8)}<div class="t5-tabbody">${listBody(state, st)}</div>`;
  const page = scaffold({ appbar: appBar('Đơn hàng', { subtitle: sub }), body, fabHtml: fab('plus', 'Tạo đơn bán hàng'), placeWidth, windowWidth: v.width });
  return `<div class="t5-area">${page}${sheet}</div>`;
}

// ---------------------------------------------------------------- sheet bộ lọc

export const FILTER_GROUPS = [
  ['Thời gian', ['Tất cả', 'Hôm nay', '7 ngày', '30 ngày']],
  ['Trạng thái đơn', ['Tất cả', 'Hoàn tất', 'Đã hủy']],
  ['Thanh toán', ['Tất cả', 'Đã thanh toán', 'Còn phải thu', 'Chưa thu']],
  ['Sau bán', ['Tất cả', 'Có đổi/trả']],
  ['Hóa đơn điện tử', ['Tất cả', 'Chưa phát hành', 'Đã phát hành']],
];

/**
 * SalesOrderFilterBottomSheet (showVBottomSheet KHÔNG tiêu đề): VPagePadding[khe 16, mỗi nhóm: tiêu đề bodyDefault bold, khe 8, Wrap chip (khe 8; chọn → tone PRIMARY,
 * khác chip nhanh tone success), khe 16] rồi VPagePadding[Row "Đặt lại" (secondary, chữ textPrimary) | khe 8 | "Áp dụng" (xanh)] — KHÔNG có đệm đáy dưới hàng nút.
 * "Đặt lại" đóng sheet ngay (không chỉ xoá lựa chọn). Không có mục chip nhanh (preset) dù nó được đếm vào badge.
 */
export function filterSheet(selected = [0, 0, 0, 0, 0]) {
  const groups = FILTER_GROUPS.map(([title, opts], g) => `${gap(16)}<p class="t5-bold">${esc(title)}</p>${gap(8)}<div class="t5-wrap">${opts.map((o, i) => chip(o, { tone: i === selected[g] ? 'primary' : 'neutral' })).join('')}</div>`).join('');
  return `<div class="t5-pad">${groups}${gap(16)}</div><div class="t5-pad t5-row">${button('Đặt lại', { variant: 'secondary', full: true })}${button('Áp dụng', { full: true })}</div>`;
}
