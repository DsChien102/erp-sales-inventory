// SG-07 Kết quả bán hàng (/sales/result/:orderId) + sheet "Phiếu bán hàng"; SG-16 Xem trước phiếu bán hàng (/sales/orders/:id/preview).
// Nguồn Dart (apps/erp/lib/features/sales/presentation/):
//   pages/{sales_transaction_result_page, sales_result_invalid_entry_page}.dart, widgets/{sales_transaction_result_body, sales_result_header_card,
//   sales_result_customer_card, sales_result_partial_banner, sales_result_payment_summary_card, sales_result_documents_section,
//   sales_receipt_entry_card, sales_einvoice_entry_card, sales_entry_row, sales_result_loading_view, sales_result_failure_view,
//   sales_transaction_result_action_bar, sales_result_receipt_sheet, sales_document_action_sheet}.dart;
//   pages/{sales_order_slip_preview_page, sales_receipt_preview_page}.dart, support/sales_receipt_pdf_generator.dart.
//   HD-06: features/einvoice/presentation/widgets/order_einvoice_row.dart — các trạng thái + sheet HĐĐT vẽ ở prototype Theme 8 (đợt 2).
// Key Dart dùng "sg06" cho màn này (đánh số cũ); TH-05 / CHECKLIST gọi là SG-07.
import {
  appBar, badge, banner, button, emptyDesc, emptyMedia, emptyState, emptyTitle, esc, gap, icon, iconBox, scaffold, toast,
} from './ds.js';
import { money } from './data.js';

/** SalesResultHeaderCard._metaText: phương thức theo đơn gốc: cả hai → "Tiền mặt + chuyển khoản"; chỉ CK / chỉ mặt; không gì → "Chưa thanh toán". */
export function methodText({ cash = 0, bank = 0 }) {
  if (cash > 0 && bank > 0) return 'Tiền mặt + chuyển khoản';
  if (bank > 0) return 'Chuyển khoản';
  if (cash > 0) return 'Tiền mặt';
  return 'Chưa thanh toán';
}

const BASE = { number: 'DH-000130', at: '22/11/2026 · 10:32', customer: { name: 'Nguyễn Văn Hùng', phone: '0912345678' }, total: 441000, cash: 441000, bank: 0, due: null, hd: 'notIssued', receipt: 'idle' };
const RESULT = {
  paid: {},
  debt: { cash: 220500, due: '30/11/2026' },
  change: { cash: 500000 },
  unpaid: { cash: 0, due: '05/12/2026' },
  mixed: { total: 4850000, cash: 2000000, bank: 2850000 },
  'walk-in': { customer: null },
  syncing: { number: null, at: null },
  partial: { partial: true },
  'receipt-generating': { receipt: 'generating' },
  'receipt-error': { receipt: 'error' },
  'hd-fallback': { hd: 'fallback' },
  'hd-buyer': { hd: 'notIssued', buyerNotReady: true, customer: { name: 'Công ty CP Dược Thú y Sài Gòn', phone: null } },
};
export const resultState = (state) => ({ ...BASE, ...(RESULT[state] || {}) });

const RECEIPT_SUB = {
  idle: 'Xem, in hoặc gửi phiếu cho khách', generating: 'Đang tạo phiếu bán hàng', error: 'Không thể tạo phiếu, hãy thử lại',
};

/** SalesEntryRow: VCard đệm 16; icon 24 + khe 12 + (tiêu đề bodyDefault w600, khe 4, phụ bodySmall) + [khe 12 + badge] + khe 12 + › 20 textMuted. */
const entryRow = (ic, title, sub, badgeHtml = '') => `<div class="t5-card t5-card--pad t5-entry"><i class="t5-entry__ic">${icon(ic)}</i><span class="t5-entry__t"><b>${esc(title)}</b>${gap(4)}<span>${esc(sub)}</span></span>${badgeHtml ? `<i class="t5-gap-h12"></i>${badgeHtml}` : ''}<i class="t5-gap-h12"></i><i class="t5-entry__chev">${icon('chevronRight')}</i></div>`;

/** OrderEInvoiceRow (HD-06, trạng thái mặc định): VCard đệm 16; icon 24 + khe 16 + "Hóa đơn điện tử" H4 w700 / khe 4 / "Quản lý HĐĐT" (hoặc "Chưa đủ thông tin" vàng) + khe 8 + badge + khe 8 + ›. */
const HD_BADGE = { notIssued: ['Chưa phát hành', 'neutral'] };
function hdRow(r) {
  if (r.hd === 'fallback') return entryRow('fileCheck', 'Hóa đơn điện tử', 'Quản lý hóa đơn', badge('Chưa tải được', { tone: 'warning' }));
  const [label, tone] = HD_BADGE[r.hd];
  return `<div class="t5-card t5-card--pad t5-entry t5-entry--hd"><i class="t5-entry__ic">${icon('fileCheck')}</i><span class="t5-entry__t"><b>Hóa đơn điện tử</b>${gap(4)}<span${r.buyerNotReady ? ' class="t5-text-warning"' : ''}>${r.buyerNotReady ? 'Chưa đủ thông tin' : 'Quản lý HĐĐT'}</span></span><i class="t5-gap-h8"></i>${badge(label, { tone })}<i class="t5-gap-h8"></i><i class="t5-entry__chev">${icon('chevronRight')}</i></div>`;
}

/**
 * SalesAmountHighlightRow trong thẻ tóm tắt: "Tổng đơn" tone primary (nền xanh nhạt, nhãn labelDefault + số headingH4Mono xanh);
 * "Đã thanh toán" / "Tiền thừa" tone neutral (nền trắng → trông như dòng thường; nhãn bodySmall đen); "Còn phải thu" tone warning nền trong (chữ vàng).
 * Các hàng không có khe giữa (mỗi hàng tự đệm 12). "Hẹn thanh toán": đệm 12 / 12 / 12 / 8, nhãn bodySmall w600 | ngày bodyDefault w600.
 */
function paymentCard(r) {
  const paid = r.cash + r.bank;
  const out = r.total > paid ? r.total - paid : 0;
  const change = paid > r.total ? paid - r.total : 0;
  const row = (label, value, tone, small = true) => `<div class="t5-hlr t5-hlr--${tone}"><span${small ? ' class="is-small"' : ''}>${esc(label)}</span><b>${esc(money(value))}</b></div>`;
  return `<div class="t5-card t5-card--pad"><p class="t5-bold">Tóm tắt thanh toán</p>${gap(8)}
    ${row('Tổng đơn', r.total, 'primary', false)}${row('Đã thanh toán', paid, 'neutral')}${out > 0 ? row('Còn phải thu', out, 'warning') : ''}${change > 0 ? row('Tiền thừa', change, 'neutral') : ''}
    ${r.due ? `<div class="t5-dueline"><span>Hẹn thanh toán</span><b>${esc(r.due)}</b></div>` : ''}</div>`;
}

/**
 * Thân (cuộn, lề 16): khe 8; thẻ đầu (đệm 16): icon ✓ 22 xanh (không nền), khe 8, "Đã hoàn tất đơn" H3 bold, khe 4, "Đơn <số>" H4 w600, khe 4,
 * "<ngày giờ> · <phương thức>" bodySmall, khe 8, "Xem chi tiết đơn" tertiary small xanh; khe 16; thẻ khách (đệm 12, ô người 40); khe 16;
 * [banner đồng bộ một phần]; [banner lỗi phiếu]; thẻ tóm tắt; khe 16; "Chứng từ & hóa đơn" bodyDefault w700; khe 8; phiếu bán hàng; khe 8; HĐĐT; khe 32.
 */
function resultBody(r) {
  const meta = `${r.at || 'Đang đồng bộ'} · ${methodText(r)}`;
  const cust = r.customer;
  return `<div class="t5-rscroll"><div class="t5-pad">${gap(8)}
    <div class="t5-card t5-card--pad t5-rhead"><i class="t5-rhead__ic">${icon('checkCircle')}</i>${gap(8)}<h2 class="t5-rhead__t">Đã hoàn tất đơn</h2>${gap(4)}
      <p class="t5-rhead__no">Đơn ${esc(r.number || '5b1f0c2e-8a4d-4c71-9f3e-2d6a7b8c9e01')}</p>${gap(4)}<p class="t5-small t5-tc">${esc(meta)}</p>${gap(8)}
      ${button('Xem chi tiết đơn', { variant: 'tertiary', size: 'small', full: true, cls: 't5-btn--fg-primary' })}</div>${gap(16)}
    <div class="t5-card t5-card--p12 t5-rcust">${iconBox({ ic: 'user', size: 40, iconSize: 20, radius: 12, cls: 't5-ibox--altdark' })}<i class="t5-gap-h8"></i><span class="t5-entry__t"><b>${esc(cust ? cust.name : 'Khách lẻ')}</b>${gap(4)}<span>${esc(cust && cust.phone ? cust.phone : 'Không có số điện thoại')}</span></span></div>${gap(16)}
    ${r.partial ? `${banner('warning', 'Một số dữ liệu liên quan đang chờ đồng bộ. Đơn hàng vẫn đã hoàn tất.')}${gap(16)}` : ''}
    ${r.receipt === 'error' ? `${banner('warning', 'Đơn văn đã hoàn tất. Chưa thể tạo phiếu bán hàng. Không thanh toán hoặc tạo lại đơn.')}${gap(16)}` : ''}
    ${paymentCard(r)}${gap(16)}
    <p class="t5-bold">Chứng từ &amp; hóa đơn</p>${gap(8)}
    ${entryRow('receiptText', r.receipt === 'error' ? 'Tạo lại phiếu bán hàng' : 'Phiếu bán hàng', RECEIPT_SUB[r.receipt])}${gap(8)}${hdRow(r)}${gap(32)}</div></div>`;
}

/** SalesTransactionResultActionBar (đệm dọc 12): "Về trang chủ" (secondary viền xanh) | "Tạo đơn mới" (xanh); lỗi tải → "Thử tải lại" nền ĐỎ. */
const actionBar = (failure) => `<div class="t5-row2 t5-row2--8">${button('Về trang chủ', { variant: 'secondary', full: true, cls: 't5-btn--sec-success' })}${button(failure ? 'Thử tải lại' : 'Tạo đơn mới', { full: true, tone: failure ? 'danger' : '' })}</div>`;

/** VPageScaffold "Kết quả bán hàng" — không nút ← (showBackButton: false), không thanh bên / thanh dưới. */
export function resultPage(state, v, { toastHtml = '' } = {}) {
  let body;
  const failure = state === 'failure';
  if (state === 'loading') body = `<div class="t5-center t5-center--col"><span class="t5-spin t5-spin--40"></span>${gap(16)}<p class="t5-bodyp">Đang tải kết quả bán hàng...</p></div>`;
  else if (failure) {
    body = emptyState({ header: [emptyMedia('close'), emptyTitle('Không tải được chi tiết kết quả'), emptyDesc('Đơn đã được tạo. Thử tải lại và không thanh toán lại.')], tone: 'danger', content: `${gap(8)}${button('Thử tải lại', { variant: 'tertiary' })}`, cls: 't5-empty--media56' });
  } else body = resultBody(resultState(state));
  return scaffold({ appbar: appBar('Kết quả bán hàng'), body: body + toastHtml, bottomBar: actionBar(failure), placeWidth: v.width, windowWidth: v.width, cls: 't5-page--compose' });
}

/** Thanh dưới = 1 + 12 + 44 + 12 = 69 (+ 34 iPhone). */
export const resultToast = (v, type, title, message) => toast(type, title, message, { bottom: 14 + 69 + (v.device === 'iphone' ? 34 : 0) });

/**
 * showSalesDocumentActionSheet: showVBottomSheet CÓ tiêu đề ("Phiếu bán hàng" H3 w700 + VDivider); đệm 16 / 12; 3 thẻ VCard đệm 16:
 * icon 22 + khe 12 + (tiêu đề w600 / khe 4 / phụ bodySmall) + khe 8 + › 20; khe 8 giữa + 8 cuối.
 */
const RECEIPT_COPY = [['Xem phiếu', 'Kiểm tra phiếu trước khi in hoặc gửi'], ['In phiếu', 'Chọn máy in và số bản cần in'], ['Chia sẻ phiếu', 'Gửi qua ứng dụng khác']];
/** SalesDocumentActionSheetCopy của phiếu đổi/trả (showSalesReturnExchangeSlipSheet). */
export const RETURN_SLIP_COPY = [['Xem trước phiếu', 'Kiểm tra nội dung trước khi in hoặc chia sẻ'], ['In phiếu', 'In phiếu đổi/trả cho khách'], ['Chia sẻ phiếu', 'Gửi qua ứng dụng khác']];
export function receiptActionSheet(copy = RECEIPT_COPY) {
  const tile = (ic, t, s) => `<div class="t5-card t5-card--pad t5-entry t5-entry--22"><i class="t5-entry__ic">${icon(ic)}</i><span class="t5-entry__t"><b>${esc(t)}</b>${gap(4)}<span>${esc(s)}</span></span><i class="t5-gap-h8"></i><i class="t5-entry__chev">${icon('chevronRight')}</i></div>`;
  const [v, p, sh] = copy;
  return `<div class="t5-docsheet">${tile('eye', v[0], v[1])}${gap(8)}${tile('printer', p[0], p[1])}${gap(8)}${tile('share', sh[0], sh[1])}${gap(8)}</div>`;
}

// ---------------------------------------------------------------- SG-16 phiếu bán hàng (PDF A5)

const RECEIPT_LINES = [
  { name: 'Amoxicillin 500mg', qty: 2, unit: 'Hộp', price: 125000, total: 250000 },
  { name: 'Pate cho mèo vị cá ngừ 85g', qty: 6, unit: 'Lon', price: 18000, total: 96000, discounted: 16000 },
  { name: 'Dầu tắm trị ve rận cho chó mèo 250ml', qty: 1, unit: 'Chai', price: 95000, total: 95000 },
];

/** Các dòng tổng của phiếu (SalesReceiptPdfGenerator): Tiền hàng, Giảm giá, [Tổng đơn nền xanh], dòng thanh toán theo phương thức, Còn phải thu (đậm), [Hạn thu], [Công nợ phát sinh từ đơn]. */
export function receiptDoc(kind = 'paid') {
  const debt = kind === 'debt';
  const walkIn = kind === 'walk-in';
  return {
    store: 'MOSAIC RETAIL DEMO', storeCode: 'CH-01', no: 'PBH-000130', order: 'DH-000130', soldAt: '22/11/2026 · 10:32',
    customer: walkIn ? null : { name: 'Nguyễn Văn Hùng', phone: '0912345678' },
    lines: RECEIPT_LINES, subtotal: 453000, discount: 12000, total: 441000,
    payments: debt ? [['Tiền mặt', 220500]] : [['Tiền mặt', 441000]],
    outstanding: debt ? 220500 : 0, due: debt ? '30/11/2026' : null,
  };
}

/**
 * Trang A5 (419,5 × 595,3 pt), lề 10, khung trắng đệm 14 bo 16 (trắng trên trắng, không thấy). Đầu: ô "V45" 44 nền #1F7A36 (logo cố định, không phải tên app),
 * tên cửa hàng IN HOA 12 đậm + mã 10 xám canh phải; gạch. "PHIẾU BÁN HÀNG" 16 đậm giữa; "PBH-…  ·  Đơn DH-…" mono 10 xám.
 * Hàng nhãn 10,5 xám | giá trị (có chữ số → mono). Dòng hàng: tên 10,5 đậm; "2 Hộp × 125.000đ" mono 9,5 (có giảm: giá gốc gạch + giá sau giảm đậm); thành tiền mono đậm.
 * "Tổng đơn" nền #E8F6EC bo 6. "Còn phải thu" đậm; có khách → thêm "Công nợ phát sinh từ đơn" (lặp số còn phải thu). Cuối: "Cám ơn quý khách!" + "Phiếu bán hàng nội bộ — không phải hóa đơn điện tử".
 */
export function receiptPaper(d) {
  const row = (l, val, bold = false) => `<div class="t5-pdf__row${bold ? ' is-bold' : ''}"><span>${esc(l)}</span><b class="${/[0-9]/.test(val) ? 'is-mono' : ''}">${esc(val)}</b></div>`;
  const lines = d.lines.map((l) => `<div class="t5-pdf__line"><div><b>${esc(l.name)}</b><span>${l.discounted
    ? `${l.qty} ${esc(l.unit)} × <s>${esc(money(l.price))}</s> <strong>${esc(money(l.discounted))}</strong>`
    : `${l.qty} ${esc(l.unit)} × ${esc(money(l.price))}`}</span></div><em>${esc(money(l.total))}</em></div>`).join('<i class="t5-pdf__g6"></i>');
  return `<div class="t5-pdf__page"><div class="t5-pdf__box">
    <div class="t5-pdf__head"><span class="t5-pdf__logo">V45</span><div><b>${esc(d.store)}</b><span>${esc(d.storeCode)}</span></div></div><i class="t5-pdf__g6"></i><hr class="t5-pdf__hr">
    <i class="t5-pdf__g6"></i><p class="t5-pdf__title">PHIẾU BÁN HÀNG</p><p class="t5-pdf__no">${esc(d.no)}  ·  Đơn ${esc(d.order)}</p><i class="t5-pdf__g8"></i>
    ${row('Ngày bán', d.soldAt)}${d.customer ? `${row('Khách hàng', d.customer.name)}${d.customer.phone ? row('Số điện thoại', d.customer.phone) : ''}` : ''}
    <i class="t5-pdf__g6"></i><hr class="t5-pdf__hr"><i class="t5-pdf__g6"></i>${lines}<i class="t5-pdf__g6"></i><hr class="t5-pdf__hr"><i class="t5-pdf__g6"></i>
    ${row('Tiền hàng', money(d.subtotal))}${row('Giảm giá', money(d.discount))}<i class="t5-pdf__g2"></i>
    <div class="t5-pdf__total"><span>Tổng đơn</span><b>${esc(money(d.total))}</b></div><i class="t5-pdf__g6"></i>
    ${d.payments.map(([l, a]) => row(l, money(a))).join('')}${row('Còn phải thu', money(d.outstanding), true)}${d.due ? row('Hạn thu', d.due) : ''}
    ${d.customer ? `<i class="t5-pdf__g6"></i><hr class="t5-pdf__hr"><i class="t5-pdf__g6"></i>${row('Công nợ phát sinh từ đơn', money(d.outstanding))}` : ''}
    <i class="t5-pdf__g8"></i><hr class="t5-pdf__hr"><i class="t5-pdf__g6"></i><p class="t5-pdf__thanks">Cám ơn quý khách!</p><p class="t5-pdf__note">Phiếu bán hàng nội bộ — không phải hóa đơn điện tử</p>
  </div></div>`;
}

/**
 * SalesReceiptPreviewPage: VPageScaffold "Phiếu bán hàng" (←) + 2 IconButton 48 (máy in, chia sẻ) — không có chữ. Thân PdfPreview: nền background,
 * trang có bóng (0, 3, mờ 5), lề trang 20 / 8 / 20 / 12, rộng ≤ 700. PdfPreview nằm trong cột 720 của VPageScaffold → web: trang 680;
 * iPhone: trang 350 (chữ 10,5 pt còn ~8,8 px).
 */
export function receiptPreviewPage(state, v) {
  const actions = `<button type="button" class="t5-icon-btn" aria-label="In">${icon('printer')}</button><button type="button" class="t5-icon-btn" aria-label="Chia sẻ">${icon('share')}</button>`;
  if (state === 'invalid') {
    return scaffold({ appbar: appBar('Phiếu bán hàng', { back: true }), body: '<div class="t5-center"><p class="t5-bodyp">Thiếu dữ liệu phiếu bán hàng hợp lệ để xem trước.</p></div>', placeWidth: v.width, windowWidth: v.width });
  }
  let body;
  if (state === 'loading') body = `<div class="t5-center t5-center--col"><span class="t5-spin t5-spin--40"></span>${gap(8)}<p class="t5-small">Đang tạo bản xem trước PDF...</p></div>`;
  else {
    const col = Math.min(v.width, v.width >= 1024 ? 720 : v.width >= 600 ? 640 : v.width);
    const pageW = Math.min(700, col - 40);
    const scale = pageW / 419.53;
    body = `<div class="t5-pdfview"><div class="t5-pdfview__slot" style="width:${pageW}px;height:${Math.round(595.28 * scale)}px"><div class="t5-pdf" style="transform:scale(${scale.toFixed(4)})">${receiptPaper(receiptDoc(state))}</div></div></div>`;
  }
  return scaffold({ appbar: appBar('Phiếu bán hàng', { back: true, actions }), body, placeWidth: v.width, windowWidth: v.width });
}
