// SG-09 Chi tiết đơn hàng (/sales/orders/:orderId — GoRoute cấp gốc, NGOÀI khung) + sheet "Thao tác" + SG-10 Hủy đơn (sheet).
// Nguồn Dart (apps/erp/lib/features/sales/presentation/):
//   pages/sales_order_detail_page.dart, widgets/{sales_order_detail_body, sales_detail_header_card, sales_detail_action_bar,
//   sales_order_detail_cancel_reason_card, sales_order_detail_payment_summary_card, sales_order_detail_products_section,
//   sales_order_detail_grouped_surface, sales_order_detail_documents_section, sales_order_detail_returns_section,
//   sales_order_detail_history_entry, sales_order_detail_error_state, sales_receipt_entry_card, sales_entry_row,
//   sales_amount_highlight_row, sales_order_actions_sheet, sales_order_cancel_sheet}.dart,
//   support/sales_order_detail_mapper.dart (ngày giờ, nhãn), models/sales_order_settlement/sales_order_payment_vm.dart (DisplayData),
//   logic/{sales_order_detail_post_sale_actions, sales_post_sale_error_messages}.dart (câu lỗi).
//   HD-06: OrderEInvoiceSection → features/einvoice/presentation/widgets/order_einvoice_row.dart — trạng thái + sheet HĐĐT vẽ ở prototype Theme 8 đợt 2.
// Key Dart dùng "sg08" cho màn này (đánh số cũ); TH-05 / CHECKLIST gọi là SG-09.
import {
  appBar, badge, button, buttonLg, emptyDesc, emptyMedia, emptyState, emptyTitle, esc, field, fieldDesc, gap, icon, iconBox, input, scaffold, tabs, toast,
} from './ds.js';
import { money } from './data.js';

const LINES = [
  { name: 'Amoxicillin 500mg', unit: 'Hộp', qty: 2, price: 125000, total: 250000 },
  { name: 'Pate cho mèo vị cá ngừ 85g', unit: 'Lon', qty: 6, price: 16000, original: 18000, total: 96000 },
  { name: 'Dầu tắm trị ve rận cho chó mèo 250ml', unit: 'Chai', qty: 1, price: 95000, total: 95000 },
];

/** Đơn mẫu: o1 = đơn SG-07 / SG-16 (DH-000130, trả đủ tiền mặt); o2 = bán nợ toàn bộ (huỷ được); o5 = đơn đã huỷ. */
export const DETAIL_ORDERS = {
  o1: { number: 'DH-000130', at: '22/11/2026 10:32', customer: 'Nguyễn Văn Hùng', phone: '0912345678', customerId: 'c2', total: 441000, paid: 441000, outstanding: 0, lines: LINES },
  o2: { number: 'DH-000129', at: '22/11/2026 09:48', customer: 'Trần Thị Mai', phone: '0987654321', customerId: 'c4', total: 441000, paid: 0, outstanding: 441000, lines: LINES },
  walkIn: { number: 'DH-000127', at: '21/11/2026 16:05', customer: 'Khách lẻ', phone: '', customerId: null, total: 125000, paid: 125000, outstanding: 0, lines: [{ name: 'Amoxicillin 500mg', unit: 'Hộp', qty: 1, price: 125000, total: 125000 }] },
  o5: {
    number: 'DH-000126', at: '21/11/2026 11:20', customer: 'Đại lý Thuốc thú y Minh Tâm', phone: '0905112233', customerId: 'c3', total: 441000, paid: 0, outstanding: 441000, lines: LINES,
    cancelled: true, cancel: { reason: 'Khách đặt nhầm, sẽ lên đơn mới', by: 'Phạm Thu Hà', at: '21/11/2026 15:40' },
  },
};

/** Sau đổi/trả (o1 trả 1 chai dầu tắm 95.000): dòng hiện giữ = đơn giá áp × số còn giữ; phiếu DT-000012. */
const CURRENT_LINES = LINES.slice(0, 2).map((l) => ({ ...l }));
export const RETURN_SLIPS = [{ id: 'r1', number: 'DT-000012', type: 'Đổi/trả', at: '24/11/2026 09:15', status: 'Hoàn tất', diff: -95000 }];

/** _resolveProductIcon: đơn vị chứa "chai" / "lọ" / "lo" / "ống" / "ong" / "tuýp" / "tuyp" → tag; còn lại → inventory (Lucide box). "Lon" chứa "lo" → tag. */
export function productIcon(unitName) {
  const u = unitName.trim().toLowerCase();
  return ['chai', 'lọ', 'lo', 'ống', 'ong', 'tuýp', 'tuyp'].some((k) => u.includes(k)) ? 'tag' : 'box';
}

/** _diffText: > 0 "Khách trả thêm …"; < 0 "Hoàn lại …"; 0 "Không chênh lệch". */
export function diffText(amount) {
  if (amount > 0) return `Khách trả thêm ${money(amount)}`;
  if (amount < 0) return `Hoàn lại ${money(-amount)}`;
  return 'Không chênh lệch';
}

/** SalesOrderCancelSheet: "Hoàn lại <tổng SỐ LƯỢNG> mặt hàng" (0 → số dòng); "Giảm <tổng đơn>" (không phải còn phải thu). */
export function cancelImpact(order) {
  const qty = order.lines.reduce((s, l) => s + l.qty, 0);
  return { stock: `Hoàn lại ${qty > 0 ? qty : order.lines.length} mặt hàng`, debt: `Giảm ${money(order.total)}` };
}

/** Thẻ "Lý do hủy": "<người> · <thời gian>" bỏ phần rỗng. */
export const cancelSubtitle = (c) => [c.by.trim(), c.at].filter(Boolean).join(' · ');

// ---------------------------------------------------------------- khối

/** VCard đệm 16: [#số H3 mono w400 / khe 4 / "dd/MM/yyyy HH:mm" bodySmall / khe 8] | badge; tên khách bodyDefault bold; khe 4; SĐT; khe 16; "Tổng đơn" (SalesAmountHighlightRow primary). */
function headerCard(o, total) {
  return `<div class="t5-card t5-card--pad"><div class="t5-dhead"><div><p class="t5-dhead__no">#${esc(o.number)}</p>${gap(4)}<p class="t5-small">${esc(o.at)}</p>${gap(8)}</div>
    ${o.cancelled ? badge('Đã hủy', { tone: 'danger' }) : badge('Hoàn tất', { tone: 'success' })}</div>
    <p class="t5-bold">${esc(o.customer)}</p>${gap(4)}<p class="t5-small">${esc(o.phone || 'Không có số điện thoại')}</p>${gap(16)}
    <div class="t5-hlr t5-hlr--primary"><span>Tổng đơn</span><b>${esc(money(total))}</b></div></div>`;
}

/** Vòng Material 20 nét 2 + khe 12 (hoặc 16) + chữ bodySmall đen — trạng thái đang tải của các khối. */
const loadingCard = (text, { gapW = 12, light = false } = {}) => `<div class="t5-card t5-card--p12 t5-row t5-row--0${light ? ' t5-card--light' : ''}"><span class="t5-spin t5-spin--m20"></span><i class="t5-gap-h${gapW}"></i><span class="t5-small t5-small--ink">${esc(text)}</span></div>`;

/** Thẻ thông báo của khối: tiêu đề w600, khe 4, câu bodySmall xám, [khe 4|8 + "Thử lại" secondary small canh trái]. */
const messageCard = (title, message, { retry = false, retryGap = 4, light = false } = {}) => `<div class="t5-card t5-card--p12${light ? ' t5-card--light' : ''}"><p class="t5-w600">${esc(title)}</p>${gap(4)}<p class="t5-small">${esc(message)}</p>${retry ? `${gap(retryGap)}${button('Thử lại', { variant: 'secondary', size: 'small' })}` : ''}</div>`;

/**
 * SalesOrderDetailPaymentSummaryCard (VCard đệm 12, chạm → SG-09b): icon banknoteArrowDown 22 + khe 12 + ["Thanh toán & công nợ" w600 / khe 4 /
 * "Đã thanh toán …" bodySmall w600 VÀNG / khe 4 / "Còn phải thu …" bodySmall w600 VÀNG] + khe 8 + › 20. Cả hai dòng luôn vàng, kể cả khi đã trả đủ.
 * Đơn đã huỷ: VCard enabled false → cả thẻ mờ 0.4, viền borderDefault, chữ xám.
 */
function paymentCard(kind, d) {
  if (kind === 'loading') return loadingCard('Đang tải thanh toán & công nợ…');
  if (kind === 'blocked') return messageCard('Thanh toán & công nợ', 'Bạn không có quyền xem thanh toán của đơn này.');
  if (kind === 'pending') return messageCard('Thanh toán & công nợ', 'Thanh toán đang đồng bộ. Thử lại sau.', { retry: true });
  if (kind === 'error') return messageCard('Thanh toán & công nợ', 'Không tải được thanh toán & công nợ.', { retry: true });
  const off = d.disabled;
  return `<div class="t5-card t5-card--p12 t5-entry t5-paycard${off ? ' is-off' : ''}" role="button"><i class="t5-entry__ic t5-entry__ic--22">${icon('banknoteArrowDown')}</i>
    <span class="t5-entry__t"><b>Thanh toán &amp; công nợ</b>${gap(4)}<span class="t5-paycard__v">Đã thanh toán ${esc(money(d.paid))}</span>${gap(4)}<span class="t5-paycard__v t5-paycard__v--last">Còn phải thu ${esc(money(d.outstanding))}</span></span>
    <i class="t5-gap-h8"></i><i class="t5-entry__chev">${icon('chevronRight')}</i></div>`;
}

/** _ViewCustomerReceivableRow: VCard viền borderDefault, đệm ngang 16, cao tối thiểu 44: "Xem công nợ của khách" w600 + › 20. Hiện khi đơn CÓ KHÁCH (không xét còn nợ). */
const receivableRow = () => '<div class="t5-card t5-recvrow" role="button"><span>Xem công nợ của khách</span><i class="t5-entry__chev">' + icon('chevronRight') + '</i></div>';

/** _ProductLineRow (cao 64, đệm 12 / 8): VIconBox 40 (nền surfaceAlt, bo 12) + khe 8 + [tên w600 1 dòng / khe 4 / "2 Hộp × " + giá (có giảm: giá gốc gạch textMuted + khe 4 + giá sau)] + khe 8 + thành tiền mono bold. */
function productRow(l) {
  const price = l.original
    ? `<s>${esc(money(l.original))}</s><i class="t5-gap-h4"></i>${esc(money(l.price))}`
    : esc(money(l.price));
  return `<div class="t5-prow">${iconBox({ ic: productIcon(l.unit), size: 40, iconSize: 20, radius: 12, cls: 't5-ibox--altdark' })}<i class="t5-gap-h8"></i>
    <span class="t5-prow__t"><b>${esc(l.name)}</b>${gap(4)}<span>${esc(`${l.qty} ${l.unit} ×`)}&nbsp;${price}</span></span><i class="t5-gap-h8"></i><em class="t5-prow__sum">${esc(money(l.total))}</em></div>`;
}
const productsSection = (lines) => `<p class="t5-bold">Sản phẩm</p>${gap(8)}<div class="t5-card t5-pgroup">${lines.map(productRow).join('<hr class="t5-divider">')}</div>`;

/** SalesEntryRow (VCard đệm 16): icon 24 + khe 12 + (tiêu đề w600 / khe 4 / phụ bodySmall) + khe 12 + › 20. */
const entryRow = (ic, title, sub) => `<div class="t5-card t5-card--pad t5-entry" role="button"><i class="t5-entry__ic">${icon(ic)}</i><span class="t5-entry__t"><b>${esc(title)}</b>${gap(4)}<span>${esc(sub)}</span></span><i class="t5-gap-h12"></i><i class="t5-entry__chev">${icon('chevronRight')}</i></div>`;

/** OrderEInvoiceRow (HD-06) trạng thái mặc định "Chưa phát hành": icon 24 + khe 16, tiêu đề H4 w700, badge neutral + khe 8 + ›. */
const hdRow = () => `<div class="t5-card t5-card--pad t5-entry t5-entry--hd" role="button"><i class="t5-entry__ic">${icon('fileCheck')}</i><span class="t5-entry__t"><b>Hóa đơn điện tử</b>${gap(4)}<span>Quản lý HĐĐT</span></span><i class="t5-gap-h8"></i>${badge('Chưa phát hành')}<i class="t5-gap-h8"></i><i class="t5-entry__chev">${icon('chevronRight')}</i></div>`;

/**
 * "Chứng từ & hóa đơn" (bodyDefault w700, khe 8, các thẻ cách 8): [phiếu bán hàng, HĐĐT — chỉ khi chưa huỷ], [phiếu đổi/trả — khi có phiếu
 * (hoặc đơn huỷ chưa tải xong)], lịch sử. Phiếu đổi/trả và Lịch sử dùng CÙNG icon history.
 */
function documentsSection(o, { history = 'loaded', returns = [] } = {}) {
  const rows = [];
  if (!o.cancelled) rows.push(entryRow('receiptText', 'Phiếu bán hàng', 'Xem, in hoặc gửi phiếu cho khách'), hdRow());
  const showReturns = (returns.length > 0 || o.cancelled) && (history !== 'loaded' || returns.length > 0);
  if (showReturns) {
    if (history === 'loading') rows.push(loadingCard('Đang tải phiếu đổi/trả…', { gapW: 16, light: true }));
    else if (history === 'error') rows.push(messageCard('Phiếu đổi/trả', 'Không tải được phiếu đổi/trả.', { retry: true, retryGap: 8, light: true }));
    else rows.push(entryRow('history', 'Phiếu đổi/trả', `${returns.length} phiếu · Mới nhất ${returns[0].at}`));
  }
  if (history === 'loading') rows.push(loadingCard('Đang tải lịch sử…', { gapW: 16, light: true }));
  else if (history === 'error') rows.push(messageCard('Lịch sử', 'Không tải được lịch sử.', { retry: true, retryGap: 8, light: true }));
  else rows.push(entryRow('history', 'Lịch sử', 'Thanh toán, chứng từ và nghiệp vụ sau bán'));
  return `<p class="t5-bold">Chứng từ &amp; hóa đơn</p>${gap(8)}<div class="t5-stack8">${rows.join('')}</div>`;
}

/** SalesOrderDetailCancelReasonCard (VCard đệm 12): "Lý do hủy" w700, khe 8, lý do w600 / khe 4 / "<người> · <thời gian>". Lý do rỗng → không hiện thẻ. */
function cancelReasonCard(kind, c) {
  let content;
  if (kind === 'loading') content = '<div class="t5-loadmore t5-loadmore--8"><span class="t5-spin t5-spin--material"></span></div>';
  else if (kind === 'pending') content = '<p class="t5-small">Đang cập nhật kết quả hủy đơn...</p>';
  else if (kind === 'error') content = `<div class="t5-row"><span class="t5-small t5-small--danger t5-grow">Không tải được kết quả hủy đơn.</span>${button('Thử lại', { variant: 'secondary', size: 'small' })}</div>`;
  else content = `<p class="t5-w600">${esc(c.reason)}</p>${gap(4)}<p class="t5-small">${esc(cancelSubtitle(c))}</p>`;
  return `<div class="t5-card t5-card--p12"><p class="t5-bold">Lý do hủy</p>${gap(8)}${content}</div>`;
}

// ---------------------------------------------------------------- ca

const CASES = {
  paid: {},
  'paid-end': { scrollEnd: true },
  unpaid: { order: 'o2' },
  'walk-in': { order: 'walkIn' },
  'returned-after': { tab: 1, returned: true },
  'returned-original': { tab: 0, returned: true },
  'returned-end': { tab: 1, returned: true, scrollEnd: true },
  cancelled: { order: 'o5', scrollEnd: false },
  'cancelled-end': { order: 'o5', scrollEnd: true },
  'cancelled-no-reason': { order: 'o5', noReason: true },
  'cancel-reason-pending': { order: 'o5', cancelKind: 'pending' },
  'sections-loading': { payment: 'loading', history: 'loading', actions: false, scrollEnd: true },
  'sections-error': { payment: 'error', history: 'error', scrollEnd: true },
  'payment-pending': { payment: 'pending' },
  'payment-blocked': { payment: 'blocked' },
};
export const DETAIL_STATES = Object.keys(CASES);

/** Thanh dưới (VPagePadding dọc 12): "Thao tác" xanh large 52 đầy ngang + chevronUp trắng 16; mờ khi thao tác chưa tải. Đơn đã huỷ: không có thanh. */
const actionBar = (ready) => `<button type="button" class="t5-btn t5-btn--primary t5-btn--full t5-btn--lg"${ready ? '' : ' disabled'}><span>Thao tác</span><i class="t5-btn__trail">${icon('chevronUp')}</i></button>`;

/** Nội dung trang đã tải (có thể kèm toast). */
export function detailPage(state, v, { toastHtml = '' } = {}) {
  const c = CASES[state] || {};
  const o = DETAIL_ORDERS[c.order || 'o1'];
  const returns = c.returned ? RETURN_SLIPS : [];
  const showAfter = c.returned && c.tab === 1;
  const lines = showAfter ? CURRENT_LINES : o.lines;
  const total = showAfter ? lines.reduce((s, l) => s + l.total, 0) : o.total;
  const paid = c.returned ? o.paid - 95000 : o.paid;
  const outstanding = showAfter ? Math.max(0, total - paid) : o.outstanding;
  const cancel = o.cancelled && !c.noReason ? cancelReasonCard(c.cancelKind || 'loaded', o.cancel) : '';
  const scroll = `<div class="t5-rscroll"${c.scrollEnd ? ' data-scroll-end' : ''}><div class="t5-pad">${gap(16)}${headerCard(o, total)}${gap(8)}
    ${cancel ? `${cancel}${gap(8)}` : ''}${paymentCard(c.payment || 'loaded', { paid: c.returned && !showAfter ? o.paid : paid, outstanding, disabled: o.cancelled })}
    ${o.customerId ? `${gap(8)}${receivableRow()}` : ''}${gap(8)}${productsSection(lines)}${gap(12)}
    ${documentsSection(o, { history: c.history || 'loaded', returns })}${gap(12)}</div></div>`;
  const body = `${c.returned ? `${gap(8)}<div class="t5-pad">${tabs(['Đơn gốc', 'Sau đổi/trả'], c.tab)}</div>` : ''}${scroll}${toastHtml}`;
  return scaffold({
    appbar: appBar('Chi tiết đơn hàng', { back: true }), body, bottomBar: o.cancelled ? '' : actionBar(c.actions !== false),
    placeWidth: v.width, windowWidth: v.width, cls: 't5-page--compose',
  });
}

/** Trạng thái cả trang: đang tải (CircularProgressIndicator 36 giữa màn) / 4 kiểu lỗi (VEmptyState giữa màn, nút primary theo tone). Không có thanh dưới. */
const ERRORS = {
  blocked: ['alert', 'warning', 'Không có quyền xem đơn hàng', 'Tài khoản của bạn không có quyền xem đơn hàng này.', 'Quay lại'],
  'not-found': ['info', '', 'Không tìm thấy đơn hàng', 'Đơn hàng không tồn tại hoặc đã bị xóa.', 'Quay lại'],
  pending: ['info', 'warning', 'Đơn hàng đang cập nhật', 'Dữ liệu đơn hàng chưa sẵn sàng. Vui lòng thử lại.', 'Thử lại'],
  error: ['alert', 'danger', 'Không thể tải chi tiết đơn hàng', 'Kiểm tra kết nối và thử lại.', 'Thử lại'],
};
export function detailStatusPage(kind, v) {
  let body;
  if (kind === 'loading') body = '<div class="t5-center"><span class="t5-spin t5-spin--material"></span></div>';
  else {
    const [media, tone, title, desc, action] = ERRORS[kind];
    body = emptyState({ header: [emptyMedia(media), emptyTitle(title), emptyDesc(desc)], tone, content: `${gap(8)}${button(action, { tone: tone === 'warning' ? 'warning' : tone })}`, cls: tone === 'warning' ? 't5-empty--twarning' : '' });
  }
  return scaffold({ appbar: appBar('Chi tiết đơn hàng', { back: true }), body, placeWidth: v.width, windowWidth: v.width });
}

/** VToast trên thanh "Thao tác": 14 + (1 + 12 + 52 + 12) + vùng an toàn iPhone 34. */
export const detailToast = (v, type, title, message) => toast(type, title, message, { bottom: 14 + 77 + (v.device === 'iphone' ? 34 : 0) });

// ---------------------------------------------------------------- sheet "Thao tác"

/**
 * showSalesOrderActionsSheet: showVBottomSheet CÓ tiêu đề "Thao tác" (+ gạch); đệm 16 / 12; 2 thẻ VCard đệm 12 cách 8 (+ khe 8 cuối):
 * icon 22 + khe 8 + (tiêu đề w600 / khe 4 / phụ bodySmall xám) + khe 8 + › 20. "Hủy đơn" tone đỏ: nền dangerBg, viền đỏ 30%.
 * Tắt: nền surfaceAlt, viền borderDefault, tiêu đề + icon textMuted, › borderDefault (không mờ 0.4). Không có "Thu tiền".
 */
function actionTile(ic, title, sub, { danger = false, enabled = true } = {}) {
  const c = ['t5-card', 't5-card--p12', 't5-entry', 't5-acttile', danger && enabled ? 'is-danger' : '', enabled ? '' : 'is-off'].filter(Boolean).join(' ');
  return `<div class="${c}" role="button"${enabled ? '' : ' aria-disabled="true"'}><i class="t5-entry__ic t5-acttile__ic">${icon(ic)}</i><span class="t5-entry__t"><b>${esc(title)}</b>${gap(4)}<span>${esc(sub)}</span></span><i class="t5-gap-h8"></i><i class="t5-entry__chev">${icon('chevronRight')}</i></div>`;
}
export function actionsSheet({ canReturn = true, canCancel = false, cancelReason = 'Đơn đã có thanh toán, vui lòng đổi/trả' } = {}) {
  return `<div class="t5-docsheet">${actionTile('history', 'Đổi/trả hàng', 'Chọn hàng khách trả hoặc đổi', { enabled: canReturn })}${gap(8)}
    ${actionTile('fileXCorner', 'Hủy đơn', !canCancel && cancelReason ? cancelReason : 'Kiểm tra điều kiện và tác động trước khi hủy', { danger: true, enabled: canCancel })}${gap(8)}</div>`;
}

// ---------------------------------------------------------------- SG-10 Hủy đơn

/**
 * showSalesOrderCancelSheet: showVBottomSheet KHÔNG tiêu đề; đệm 16 / 8 / 16 / 16: "Hủy đơn hàng?" H3 bold đỏ; khe 4; "Đơn <mã> sẽ chuyển sang Đã hủy và không thể mở lại."
 * bodyDefault xám; khe 16; VField "Lý do hủy" + ô "Nhập lý do nếu cần" + "Không bắt buộc" (không có chip lý do — app gửi chữ trong ô làm lý do);
 * khe 16; thẻ nền surfaceAlt đệm 16 "Điều chỉnh dự kiến" (Tồn kho / Công nợ); khe 24; "Quay lại" secondary large; khe 8; "Hủy đơn hàng" secondary đỏ large.
 */
export function cancelSheet({ reason = '', submitting = false } = {}) {
  const o = DETAIL_ORDERS.o2;
  const impact = cancelImpact(o);
  return `<div class="t5-sheetpad">
    <h2 class="t5-h3b t5-text-danger">Hủy đơn hàng?</h2>${gap(4)}<p class="t5-body2">Đơn ${esc(o.number)} sẽ chuyển sang Đã hủy và không thể mở lại.</p>${gap(16)}
    ${field({ label: 'Lý do hủy', control: `${input({ value: reason, hint: 'Nhập lý do nếu cần' })}${fieldDesc('Không bắt buộc')}` })}${gap(16)}
    <div class="t5-card t5-card--pad t5-card--alt"><p class="t5-bold">Điều chỉnh dự kiến</p>${gap(8)}
      <div class="t5-kv"><span>Tồn kho</span><b>${esc(impact.stock)}</b></div>${gap(8)}<div class="t5-kv"><span>Công nợ</span><b>${esc(impact.debt)}</b></div></div>${gap(24)}
    ${buttonLg('Quay lại', { variant: 'secondary', full: true, disabled: submitting })}${gap(8)}
    ${buttonLg(submitting ? 'Đang hủy...' : 'Hủy đơn hàng', { variant: 'secondary', tone: 'danger', full: true, disabled: submitting, cls: 't5-btn--sec-danger' })}</div>`;
}
