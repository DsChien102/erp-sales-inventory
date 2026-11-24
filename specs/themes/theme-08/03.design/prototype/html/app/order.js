// Đợt 2 · Phát hành & gửi HĐĐT trên đơn: HD-06 dòng "Hóa đơn điện tử" trong hai màn Sales chủ, HD-07…HD-13.
// Nguồn Dart (apps/erp/lib/features/einvoice/presentation/):
//   HD-06 widgets/{order_einvoice_section, order_einvoice_row}.dart, support/{order_einvoice_copy, einvoice_status_interaction}.dart
//   HD-07 widgets/{pre_issue_einvoice_action_sheet, einvoice_action_item, issuance_failure_banner}.dart
//   HD-08 widgets/issue_invoice_confirmation_sheet.dart (+ logic/order_einvoice_cubit.dart _loadTemplateDisplay / _authorityModeLabel)
//   HD-09 widgets/post_issue_einvoice_action_sheet.dart, support/order_einvoice_post_issue_copy.dart
//   HD-10 widgets/invoice_documents_action_sheet.dart
//   HD-11 / HD-12 widgets/{send_invoice_sheet, resend_invoice_sheet, invoice_delivery_recipient_form}.dart, support/order_invoice_delivery_copy.dart
//   HD-13 pages/invoice_delivery_history_page.dart, widgets/invoice_delivery_history_view.dart, logic/invoice_delivery_history_vm.dart
// Màn Sales chủ (apps/erp/lib/features/sales/presentation/), vẽ theo Flutter ở mức bố cục để thấy HD-06 nằm ở đâu:
//   SG-06 pages/sales_transaction_result_page.dart, widgets/{sales_transaction_result_body, sales_result_header_card, sales_result_customer_card,
//         sales_result_payment_summary_card, sales_result_documents_section, sales_receipt_entry_card, sales_entry_row,
//         sales_transaction_result_action_bar}.dart
//   SG-08 pages/sales_order_detail_page.dart, widgets/{sales_order_detail_body, sales_detail_header_card, sales_order_detail_payment_summary_card,
//         sales_order_detail_products_section, sales_order_detail_documents_section, sales_order_detail_history_entry, sales_detail_action_bar}.dart
//   Route /sales/result/:orderId và /sales/orders/:orderId là GoRoute cấp gốc (ngoài StoreShell).
import {
  adaptiveSheet, appBar, badge, banner, button, emptyDesc, emptyState, emptyTitle, esc, field, fieldWithDesc, gap, icon, iconBox, input, scaffold,
  centerLoading,
} from './ds.js';
import { pageToast } from './common.js';
import { ORDER, DELIVERIES } from './data.js';

// ---------------------------------------------------------------- hàm thuần (đối chiếu Dart)

/** MoneyFormatter.formatMinor: "4.445.238đ" (không dấu cách). */
export const money = (n) => `${n < 0 ? '-' : ''}${Math.abs(n).toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.')}đ`;

/** OrderEInvoiceRow._badgeForState: nhãn + tone. */
export const issuanceBadge = (s) => ({
  notIssued: ['Chưa phát hành', 'neutral'],
  processing: ['Đang xử lý', 'primary'],
  issued: ['Đã phát hành', 'success'],
  failed: ['Phát hành lỗi', 'danger'],
}[s]);

/** EInvoiceStatusInteraction.allowsTapForIssuance: chỉ "Đang xử lý" không bấm được. */
export const allowsTapForIssuance = (s) => s !== 'processing';

/** PostIssueEInvoiceActionSheet._deliveryBadge. */
export const deliveryBadge = (s) => ({
  notSent: ['Chưa gửi', 'neutral'],
  sending: ['Đang gửi', 'primary'],
  sent: ['Đã gửi', 'success'],
  failed: ['Gửi lỗi', 'danger'],
  unknown: ['Không xác định kết quả', 'warning'],
}[s]);

/** OrderEInvoiceCopy.safeFailureMessage. */
export function safeFailureMessage(failureCode, lastFailureMessage) {
  if (failureCode === 'COMMAND_INTEGRITY') return 'Dữ liệu đơn hàng hoặc cấu hình không khớp. Vui lòng kiểm tra lại.';
  const provider = (lastFailureMessage ?? '').trim();
  if (provider) return provider;
  if (failureCode === 'PROVIDER_REJECTED') return 'Nhà cung cấp từ chối phát hành hóa đơn điện tử.';
  return 'Đã xảy ra lỗi khi phát hành hóa đơn điện tử. Vui lòng kiểm tra và thử lại.';
}

/** OrderEInvoiceCubit: "Mẫu" = serial (không phải số mẫu), "Ký hiệu" = symbol ?? serial ?? "—"; cấp mã theo hình thức ký. */
export function templateDisplay(t, signingMethod) {
  const serial = (t?.serial ?? '').trim();
  const symbol = (t?.symbol ?? '').trim();
  return {
    number: serial || '—',
    symbol: symbol || serial || '—',
    authority: { hsm: 'Có mã CQT', mtt: 'Máy tính tiền', noSign: 'Không ký' }[signingMethod] ?? '—',
  };
}
export const confirmLine1 = (ref, total) => `Đơn hàng ${ref} · Tổng tiền ${total}`;
export const confirmLine2 = (d) => `Mẫu ${d.number} · Ký hiệu ${d.symbol} · ${d.authority}`;

/** OrderInvoiceDeliveryCopy.isValidEmail. */
export const isValidEmail = (v) => /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(String(v).trim());

/** OrderInvoiceDeliveryCopy.suggestionSource. */
export const suggestionSource = (src) => ({
  currentPartnerProfile: 'Hồ sơ khách hàng',
  lastSuccessfulPartnerDelivery: 'Email đã dùng gần nhất cho khách hàng này',
  buyerInvoiceSnapshot: 'Thông tin người mua trên hóa đơn',
  lastInvoiceDelivery: 'Lần gửi gần nhất của hóa đơn này',
}[src] ?? null);

const two = (n) => String(n).padStart(2, '0');
/** resend_invoice_sheet _latestSummary: lần gửi THÀNH CÔNG gần nhất (duyệt từ cuối danh sách), "dd/MM/yyyy, HH:mm". */
export function latestSummary(history) {
  for (let i = history.length - 1; i >= 0; i--) {
    const d = history[i];
    if (d.status === 'succeeded') {
      const t = d.completedAt ?? d.startedAt;
      return `Đã gửi gần nhất đến ${d.email} · ${two(t.getDate())}/${two(t.getMonth() + 1)}/${t.getFullYear()}, ${two(t.getHours())}:${two(t.getMinutes())}`;
    }
  }
  return null;
}

/** invoice_delivery_history_vm: nhãn / tone trạng thái, người thực hiện; cubit sắp deliveryNo giảm dần. */
export const deliveryStatusLabel = (s) => ({ processing: 'Đang gửi', succeeded: 'Đã gửi', failed: 'Gửi lỗi', unknown: 'Không xác định kết quả' }[s]);
export const deliveryStatusTone = (s) => ({ processing: 'primary', succeeded: 'success', failed: 'danger', unknown: 'warning' }[s]);
export function historyRows(deliveries) {
  return [...deliveries].sort((a, b) => b.no - a.no).map((d) => {
    const t = d.completedAt ?? d.startedAt;
    return {
      title: `${deliveryStatusLabel(d.status)} · ${d.email}`,
      meta: `${two(t.getDate())}/${two(t.getMonth() + 1)}/${t.getFullYear()} · ${two(t.getHours())}:${two(t.getMinutes())} · ${d.actor === 'system' ? 'Tự động' : 'Người dùng'}`,
      label: deliveryStatusLabel(d.status),
      tone: deliveryStatusTone(d.status),
    };
  });
}

// ---------------------------------------------------------------- widget dùng chung đợt 2

/**
 * OrderEInvoiceRow (HD-06): VCard đệm 16; Row[VIcon fileCheck 24 textPrimary, khe 16, Expanded(Column[tiêu đề headingH4 ép w700, khe 4,
 * phụ đề bodySmall: "Quản lý HĐĐT" textSecondary | "Chưa đủ thông tin" warning]), khe 8, badge, khe 8, chevronRight 20 textMuted].
 * Không bấm được (đang xử lý / chưa tải xong) vẫn trông y như bấm được (VCard không mờ khi chỉ bỏ onTap).
 */
export function einvoiceRow(state, { buyerNotReady = false } = {}) {
  const [label, tone] = issuanceBadge(state);
  return `<div class="t8-hdrow">${icon('fileCheck', 't8-hdrow__ic')}
    <span class="t8-hdrow__text"><b>Hóa đơn điện tử</b><span class="${buyerNotReady ? 't8-tone-warning' : ''}">${buyerNotReady ? 'Chưa đủ thông tin' : 'Quản lý HĐĐT'}</span></span>
    <i class="t8-gap-h8"></i>${badge(label, { tone })}<i class="t8-gap-h8"></i>${icon('chevronRight', 't8-hdrow__chev')}</div>`;
}

/**
 * SalesEntryRow (phiếu bán hàng / lịch sử / thẻ dự phòng HĐĐT): VCard đệm 16 mặc định; Row[VIcon 24, khe 12, Expanded(tiêu đề bodyDefault w600, khe 4,
 * phụ đề bodySmall textSecondary), (khe 12 + badge), khe 12, chevronRight 20 textMuted].
 */
function entryRow(ic, title, subtitle, { badgeHtml = '' } = {}) {
  return `<div class="t8-entry">${icon(ic, 't8-entry__ic')}<span class="t8-entry__text"><b>${esc(title)}</b><span>${esc(subtitle)}</span></span>${badgeHtml ? `<i class="t8-gap-h12"></i>${badgeHtml}` : ''}<i class="t8-gap-h12"></i>${icon('chevronRight', 't8-entry__chev')}</div>`;
}

/**
 * EInvoiceActionItem: Padding 16 ngang / 8 dọc quanh VCard (đệm 16); Row[VIcon 22 textPrimary, khe 16, Expanded(tiêu đề bodyDefault ép w700, khe 4,
 * phụ bodySmall textSecondary), (khe 8 + badge), khe 8, vòng tải 20 (nét 2) | chevronRight 24 textMuted]. Tắt / đang tải → VCard mờ 0.4, viền borderDefault.
 */
function actionItem(ic, title, supporting, { badgeHtml = '', enabled = true, loading = false } = {}) {
  const on = enabled && !loading;
  return `<div class="t8-act"><div class="t8-act__card${on ? '' : ' is-disabled'}">${icon(ic, 't8-act__ic')}
    <span class="t8-act__text"><b>${esc(title)}</b><span>${esc(supporting)}</span></span>${badgeHtml ? `<i class="t8-gap-h8"></i>${badgeHtml}` : ''}<i class="t8-gap-h8"></i>
    ${loading ? '<span class="t8-spin t8-spin--20" aria-hidden="true"></span>' : icon('chevronRight', 't8-act__chev')}</div></div>`;
}

/**
 * SnackBar Material mặc định (không phải VToast): lỗi tải ngữ cảnh gửi / lỗi gửi dùng ScaffoldMessenger.showSnackBar(SnackBar(Text)).
 * App không đặt snackBarTheme → M3 fixed: dải tối hết bề ngang đáy Scaffold của màn chủ, chữ 14 sáng. Gọi khi sheet đang mở → nằm DƯỚI lớp phủ.
 */
const materialSnack = (v, text) => `<div class="t8-msnack" style="bottom:${(v.bottomBar ?? 0)}px">${esc(text)}</div>`;

// ---------------------------------------------------------------- màn Sales chủ

const ORDER_REF = `#${ORDER.number}`;

/** _ProductLineRow._resolveProductIcon: đơn vị chai / lọ / ống / tuýp → tag; còn lại → inventory. */
export function productIcon(unitName) {
  const u = unitName.trim().toLowerCase();
  return ['chai', 'lọ', 'lo', 'ống', 'ong', 'tuýp', 'tuyp'].some((k) => u.includes(k)) ? 'tag' : 'inventory';
}

/** SG-08 Chi tiết đơn hàng: thân cuộn tới khối "Chứng từ & hóa đơn" (ca được chụp như người dùng đã kéo xuống). */
function detailHost(v, { hd = 'notIssued', buyerNotReady = false, toastHtml = '', snack = '' } = {}) {
  const items = ORDER.items.map((it) => `<div class="t8-pline">${iconBox({ ic: productIcon(it.unit), size: 40, iconSize: 20, radius: 12, cls: 't8-pline__ibox' })}
    <span class="t8-pline__text"><b>${esc(it.name)}</b><span>${esc(`${it.qty} ${it.unit} × `)}${esc(money(it.price))}</span></span><i class="t8-gap-h8"></i><em class="t8-mono t8-pline__sum">${esc(money(it.qty * it.price))}</em></div>`).join('<hr class="t8-divider">');
  const body = `<div class="t8-hostscroll" data-scroll-end><div class="t8-hostcol">
    ${gap(16)}
    <div class="t8-card t8-card--pad"><div class="t8-dhead"><div><p class="t8-dhead__no t8-mono">${esc(ORDER_REF)}</p><p class="t8-small t8-mt4">${esc(ORDER.committedAt)}</p>${gap(8)}</div>${badge('Hoàn tất', { tone: 'success' })}</div>
      <b class="t8-dhead__cust">${esc(ORDER.customer)}</b><p class="t8-small t8-mt4">${esc(ORDER.phone)}</p>${gap(16)}
      <div class="t8-amt t8-amt--primary"><span>Tổng đơn</span><em class="t8-mono">${esc(money(ORDER.total))}</em></div></div>
    ${gap(8)}
    <div class="t8-card t8-card--p12 t8-paysum">${icon('banknoteArrowDown', 't8-paysum__ic')}<i class="t8-gap-h12"></i><span class="t8-paysum__text"><b>Thanh toán &amp; công nợ</b><span>Đã thanh toán ${esc(money(ORDER.total))}</span><span>Còn phải thu ${esc(money(0))}</span></span><i class="t8-gap-h8"></i>${icon('chevronRight', 't8-entry__chev')}</div>
    ${gap(8)}
    <div class="t8-recv"><b>Xem công nợ của khách</b>${icon('chevronRight', 't8-entry__chev')}</div>
    ${gap(8)}
    <b class="t8-sectitle">Sản phẩm</b>${gap(8)}<div class="t8-card">${items}</div>
    ${gap(12)}
    <b class="t8-sectitle">Chứng từ &amp; hóa đơn</b>${gap(8)}
    ${entryRow('receipt', 'Phiếu bán hàng', 'Xem, in hoặc gửi phiếu cho khách')}${gap(8)}
    ${einvoiceRow(hd, { buyerNotReady })}${gap(8)}
    ${entryRow('history', 'Lịch sử', 'Thanh toán, chứng từ và nghiệp vụ sau bán')}
    ${gap(12)}</div></div>`;
  const bar = `<div class="t8-hostbar">${button('Thao tác', { full: true, cls: 't8-btn--lg' }).replace('</span></button>', `</span>${icon('chevronUp', 't8-btn__trail')}</button>`)}</div>`;
  return scaffold({ appbar: appBar('Chi tiết đơn hàng', { back: true }), body, bottomBar: bar, placeWidth: v.width, windowWidth: v.width })
    .replace(/<\/div>\s*$/, `${snack}${toastHtml}</div>`);
}

/** SG-06 Kết quả bán hàng: không nút ←; thanh dưới "Về trang chủ" | "Tạo đơn mới". */
function resultHost(v, { hd = 'notIssued', buyerNotReady = false, fallback = false } = {}) {
  const hdHtml = fallback
    ? entryRow('fileCheck', 'Hóa đơn điện tử', 'Quản lý hóa đơn', { badgeHtml: badge('Chưa tải được', { tone: 'warning' }) })
    : einvoiceRow(hd, { buyerNotReady });
  const body = `<div class="t8-hostscroll" data-scroll-end><div class="t8-hostcol">
    ${gap(8)}
    <div class="t8-card t8-card--pad t8-rhead">${icon('checkCircle', 't8-rhead__ic')}${gap(8)}<h2 class="t8-rhead__title">Đã hoàn tất đơn</h2>${gap(4)}
      <p class="t8-rhead__no">Đơn ${esc(ORDER.number)}</p>${gap(4)}<p class="t8-small t8-center">${esc(ORDER.soldAt)} · Tiền mặt</p>${gap(8)}
      ${button('Xem chi tiết đơn', { variant: 'tertiary', size: 'small', cls: 't8-rhead__btn' })}</div>
    ${gap(16)}
    <div class="t8-card t8-card--p12 t8-rcust">${iconBox({ ic: 'user', size: 40, iconSize: 20, radius: 12, cls: 't8-pline__ibox' })}<i class="t8-gap-h8"></i><span class="t8-entry__text"><b>${esc(ORDER.customer)}</b><span>${esc(ORDER.phone)}</span></span></div>
    ${gap(16)}
    <div class="t8-card t8-card--pad"><b class="t8-sectitle">Tóm tắt thanh toán</b>${gap(8)}
      <div class="t8-amt t8-amt--primary"><span>Tổng đơn</span><em class="t8-mono">${esc(money(ORDER.total))}</em></div>
      <div class="t8-amt t8-amt--plain"><span>Đã thanh toán</span><em class="t8-mono">${esc(money(ORDER.total))}</em></div></div>
    ${gap(16)}
    <b class="t8-sectitle">Chứng từ &amp; hóa đơn</b>${gap(8)}
    ${entryRow('receipt', 'Phiếu bán hàng', 'Xem, in hoặc gửi phiếu cho khách')}${gap(8)}
    ${hdHtml}
    ${gap(32)}</div></div>`;
  const bar = `<div class="t8-hostbar t8-row2 t8-row2--8">${button('Về trang chủ', { variant: 'secondary', cls: 't8-btn--success-outline', full: true })}${button('Tạo đơn mới', { full: true })}</div>`;
  return scaffold({ appbar: appBar('Kết quả bán hàng'), body, bottomBar: bar, placeWidth: v.width, windowWidth: v.width });
}

// ---------------------------------------------------------------- HD-06

const HD_STATES = { 'not-issued': 'notIssued', processing: 'processing', issued: 'issued', failed: 'failed' };

export function resultPage(v, kind) {
  if (kind === 'unavailable') return resultHost(v, { fallback: true });
  if (kind === 'buyer-not-ready') return resultHost(v, { buyerNotReady: true });
  return resultHost(v, { hd: HD_STATES[kind] });
}

export function detailPage(v, kind) {
  if (kind === 'buyer-not-ready') return detailHost(v, { buyerNotReady: true });
  if (kind === 'toast-preview-error') return detailHost(v, { toastHtml: hostToast(v, 'Xem trước hóa đơn chưa sẵn sàng. Vui lòng thử lại sau ít giây.') });
  if (kind === 'toast-no-template') return detailHost(v, { toastHtml: hostToast(v, 'Chưa chọn mẫu hóa đơn. Vui lòng cập nhật cấu hình phát hành.') });
  if (kind === 'toast-document') return detailHost(v, { hd: 'issued', toastHtml: hostToast(v, 'Không thể lưu tài liệu hóa đơn trên thiết bị. Vui lòng thử lại.') });
  return detailHost(v, { hd: HD_STATES[kind] });
}

/** VToast của OrderEInvoiceSection trên SG-08: SnackBar floating trên thanh "Thao tác" (bottomNavigationBar 44 + đệm 12 × 2 = 68 + gạch 1). */
const hostToast = (v, message) => pageToast({ ...v, device: v.device }, 'danger', message).replace(/bottom:(\d+)px/, (_, b) => `bottom:${Number(b) + 69}px`);

// ---------------------------------------------------------------- HD-07

const PRE = {
  default: {},
  'preview-loading': { previewLoading: true },
  'buyer-not-ready': { buyerNotReady: true, showCorrection: true },
  'buyer-no-partner': { buyerNotReady: true, showCorrection: false },
  'not-connected': { providerConnected: false },
  'preview-unsupported': { previewEnabled: false },
  'failed-provider': { failed: true, failureCode: 'PROVIDER_REJECTED', lastFailureMessage: 'Ký hiệu hóa đơn 1C26TAA chưa được đăng ký sử dụng với cơ quan thuế.' },
  'failed-integrity': { failed: true, failureCode: 'COMMAND_INTEGRITY' },
  'failed-generic': { failed: true, failureCode: null },
};

/** PreIssueEInvoiceActionSheet: [banner lỗi] [cảnh báo người mua + link] + 3 mục: Phát hành / Kiểm tra & xem trước / Gửi hóa đơn (luôn tắt) + khe 8. */
export function preIssueSheet(kind) {
  const s = { previewLoading: false, buyerNotReady: false, showCorrection: true, previewEnabled: true, providerConnected: true, failed: false, ...PRE[kind] };
  const issueEnabled = s.providerConnected && !s.buyerNotReady && !s.previewLoading;
  const failBanner = s.failed ? `<div class="t8-sheetblock">${banner('error', 'Phát hành hóa đơn điện tử không thành công', safeFailureMessage(s.failureCode, s.lastFailureMessage))}</div>` : '';
  const buyer = s.buyerNotReady ? `<div class="t8-sheetblock">${banner('warning', 'Chưa đủ thông tin để phát hành', 'Khách hàng còn thiếu thông tin bắt buộc để phát hành hóa đơn.')}
    ${s.showCorrection ? `${gap(8)}<div>${button('Cập nhật thông tin khách hàng', { variant: 'link', cls: 't8-btn--brand', disabled: s.previewLoading })}</div>` : ''}</div>` : '';
  return `${failBanner}${buyer}
    ${actionItem('receipt', 'Phát hành hóa đơn điện tử', s.buyerNotReady ? 'Cần bổ sung đủ thông tin' : 'Gửi phát hành qua MISA', { enabled: issueEnabled })}
    ${actionItem('eye', 'Kiểm tra & xem trước', 'Kiểm tra và mở bản xem trước từ MISA', { enabled: s.previewEnabled, loading: s.previewLoading })}
    ${actionItem('send', 'Gửi hóa đơn', 'Gửi qua email', { enabled: false, badgeHtml: badge('Chưa gửi', { tone: 'neutral', small: true }) })}
    ${gap(8)}`;
}

// ---------------------------------------------------------------- HD-08

/** IssueInvoiceConfirmationSheet: đệm 16 / 12 / 16 / 16; 2 dòng bodyDefault textSecondary (khe 4); khe 24; nút chính đầy ngang; khe 8; "Hủy" viền. */
export function confirmSheet(signingMethod = 'hsm') {
  const d = templateDisplay({ serial: 'C26TAA', symbol: '1C26TAA' }, signingMethod);
  return `<div class="t8-dsheet"><p class="t8-body2">${esc(confirmLine1(ORDER_REF, money(ORDER.total)))}</p>${gap(4)}<p class="t8-body2">${esc(confirmLine2(d))}</p>
    ${gap(24)}${button('Phát hành hóa đơn điện tử', { full: true })}${gap(8)}${button('Hủy', { variant: 'secondary', full: true })}</div>`;
}

// ---------------------------------------------------------------- HD-09 / HD-10

const POST = {
  'not-sent': { delivery: 'notSent' },
  sent: { delivery: 'sent' },
  sending: { delivery: 'sending' },
  failed: { delivery: 'failed' },
  unknown: { delivery: 'unknown', attention: true },
  pending: { delivery: 'sent', pending: true },
  'official-loading': { delivery: 'notSent', officialLoading: true },
};

export function postIssueSheet(kind) {
  const s = { delivery: 'notSent', officialLoading: false, pending: false, attention: false, ...POST[kind] };
  const actionsEnabled = !s.officialLoading;
  const sendInteractive = actionsEnabled && !s.pending && s.delivery !== 'sending';
  const [dl, dt] = deliveryBadge(s.delivery);
  return `${actionItem('eye', 'Xem hóa đơn điện tử', 'Mở hóa đơn chính thức từ MISA', { loading: s.officialLoading })}
    ${actionItem('fileCheck', 'Tài liệu XML & PDF', 'Lưu bản PDF hoặc tệp XML', { enabled: actionsEnabled })}
    ${actionItem('send', 'Gửi hóa đơn', s.attention ? 'Lần gửi gần nhất cần được kiểm tra trong lịch sử gửi.' : 'Gửi qua email', { enabled: sendInteractive, badgeHtml: badge(dl, { tone: dt }) })}
    ${gap(8)}`;
}

export function documentsSheet(kind) {
  const pdfLoading = kind === 'loading-pdf';
  const xmlLoading = kind === 'loading-xml';
  return `${actionItem('file', 'Lưu bản PDF', 'Lưu hóa đơn dạng PDF vào thiết bị', { loading: pdfLoading, enabled: !xmlLoading })}
    ${actionItem('fileText', 'Lưu tệp XML', 'Lưu dữ liệu hóa đơn điện tử dạng XML', { loading: xmlLoading, enabled: !pdfLoading })}
    ${gap(8)}`;
}

// ---------------------------------------------------------------- HD-11 / HD-12

const SEND = {
  suggested: { email: 'ketoan@thuyanphat.vn', source: 'currentPartnerProfile' },
  'last-used': { email: 'mua.hang@thuyanphat.vn', source: 'lastSuccessfulPartnerDelivery' },
  empty: { email: '', source: null },
  invalid: { email: 'ketoan@thuyanphat', source: null, showError: true },
  submitting: { email: 'ketoan@thuyanphat.vn', source: 'currentPartnerProfile', submitting: true },
  locked: { email: 'ketoan@thuyanphat.vn', source: 'currentPartnerProfile', locked: true },
  'snack-error': { email: 'ketoan@thuyanphat.vn', source: 'currentPartnerProfile', snack: 'Không thể gửi hóa đơn lúc này. Vui lòng thử lại.' },
};

/**
 * InvoiceDeliveryRecipientForm trong SingleChildScrollView đệm 16 / 12 / 16 / 16: VTextField "Email người nhận *" + mô tả "Email chỉ áp dụng cho lần gửi này."
 * (lỗi "Email không đúng định dạng." thay mô tả); [khe 4 + nguồn gợi ý bodySmall]; [khe 16 + chân (gửi lại)]; khe 24; "Gửi hóa đơn" đầy ngang; khe 8; "Hủy".
 * Nút chính tắt khi email rỗng / sai / đang khoá; khoá (operationLocked) không có dòng giải thích.
 */
function recipientForm(s, { footer = '' } = {}) {
  const locked = s.submitting || s.locked;
  const canSubmit = !s.submitting && !s.locked && !s.showError && isValidEmail(s.email);
  const src = suggestionSource(s.source);
  return `<div class="t8-dsheet">${fieldWithDesc({
    label: 'Email người nhận', required: true,
    control: input({ value: s.email, hint: 'Nhập email', invalid: !!s.showError, disabled: locked }),
    error: s.showError ? 'Email không đúng định dạng.' : null, desc: s.showError ? null : 'Email chỉ áp dụng cho lần gửi này.',
  })}${src ? `${gap(4)}<p class="t8-small">${esc(src)}</p>` : ''}${footer ? `${gap(16)}${footer}` : ''}
    ${gap(24)}${button('Gửi hóa đơn', { full: true, loading: s.submitting, disabled: !canSubmit })}${gap(8)}${button('Hủy', { variant: 'secondary', full: true, disabled: s.submitting })}</div>`;
}

export const sendState = (kind) => ({ ...SEND[kind] });
export const sendSheet = (kind) => recipientForm(sendState(kind));

const RESEND = {
  default: { email: 'mua.hang@thuyanphat.vn', source: 'lastInvoiceDelivery' },
  'no-success': { email: 'mua.hang@thuyanphat.vn', source: 'lastInvoiceDelivery', history: 'failedOnly' },
  invalid: { email: 'mua.hang@', source: null, showError: true },
  submitting: { email: 'mua.hang@thuyanphat.vn', source: 'lastInvoiceDelivery', submitting: true },
};

export function resendSheet(kind) {
  const s = RESEND[kind];
  const history = s.history === 'failedOnly' ? DELIVERIES.filter((d) => d.status !== 'succeeded') : DELIVERIES;
  const summary = latestSummary(history);
  const footer = `${summary ? `<p class="t8-body2">${esc(summary)}</p>${gap(8)}` : ''}<div class="t8-centerrow">${button('Xem lịch sử gửi', { variant: 'link', disabled: !!s.submitting })}</div>`;
  return recipientForm(s, { footer });
}

// ---------------------------------------------------------------- HD-13

/**
 * InvoiceDeliveryHistoryPage: VPageScaffold "Lịch sử gửi hóa đơn" + ←; đẩy bằng MaterialPageRoute từ sheet (ngoài GoRouter).
 * Có dữ liệu: ListView đệm 16: "Các lần gửi" 14 w700, khe 16, VCard (đệm dọc 8) các hàng [Column(tiêu đề bodyDefault w600 "<trạng thái> · <email>", khe 4,
 * "dd/MM/yyyy · HH:mm · <người>" bodySmall), badge] ngăn bởi Divider 1. Rỗng / lỗi: VEmptyState có viền giữa màn.
 */
export function historyPage(v, kind) {
  let body = '';
  if (kind === 'loading') body = centerLoading();
  else if (kind === 'empty') {
    body = `<div class="t8-center t8-center--pad">${emptyState({ fill: false, bg: 'surface', cls: 't8-empty--bordered', header: [iconBox({ ic: 'inbox', size: 64, iconSize: 28.16, radius: 16, cls: 't8-empty__media' }), emptyTitle('Chưa có lịch sử gửi hóa đơn.')] })}</div>`;
  } else if (kind === 'error') {
    body = `<div class="t8-center t8-center--pad">${emptyState({
      fill: false, bg: 'surface', tone: 'danger', cls: 't8-empty--bordered',
      header: [iconBox({ ic: 'circleX', size: 64, iconSize: 28.16, radius: 16, cls: 't8-empty__media' }), emptyTitle('Không thể tải lịch sử gửi hóa đơn.'), emptyDesc('Không thể tải lịch sử gửi hóa đơn.')],
      content: `${gap(8)}${button('Thử lại', { variant: 'tertiary' })}`,
    })}</div>`;
  } else {
    const rows = historyRows(DELIVERIES).map((r) => `<div class="t8-hrow"><span class="t8-hrow__text"><b>${esc(r.title)}</b><span>${esc(r.meta)}</span></span>${badge(r.label, { tone: r.tone })}</div>`).join('<hr class="t8-divider">');
    body = `<div class="t8-list"><h2 class="t8-h4b">Các lần gửi</h2>${gap(16)}<div class="t8-card t8-card--v8">${rows}</div></div>`;
  }
  return scaffold({ appbar: appBar('Lịch sử gửi hóa đơn', { back: true }), body, placeWidth: v.width, windowWidth: v.width });
}

// ---------------------------------------------------------------- ghép ca có sheet

/** showVAdaptiveSheet trên SG-08: iPhone sheet đáy (tiêu đề + gạch), web ≥ 1024 hộp thoại 480 (tiêu đề + ×). */
export function sheetCase(v, screen, kind) {
  const titles = {
    'pre-issue': 'Hóa đơn điện tử', confirm: 'Phát hành hóa đơn điện tử?', 'post-issue': 'Hóa đơn điện tử',
    documents: 'Tài liệu hóa đơn điện tử', send: 'Gửi hóa đơn điện tử', resend: 'Gửi lại hóa đơn điện tử',
  };
  const hd = { 'pre-issue': PRE[kind]?.failed ? 'failed' : 'notIssued', confirm: 'notIssued' }[screen] ?? 'issued';
  const buyerNotReady = screen === 'pre-issue' && !!PRE[kind]?.buyerNotReady;
  let body = '';
  let snack = '';
  switch (screen) {
    case 'pre-issue': body = preIssueSheet(kind); break;
    case 'confirm': body = confirmSheet(kind === 'mtt' ? 'mtt' : kind === 'no-signing' ? null : 'hsm'); break;
    case 'post-issue': body = postIssueSheet(kind); break;
    case 'documents': body = documentsSheet(kind); break;
    case 'send': {
      body = sendSheet(kind);
      if (SEND[kind].snack) snack = materialSnack({ ...v, bottomBar: 69 + (v.device === 'iphone' ? 34 : 0) }, SEND[kind].snack);
      break;
    }
    case 'resend': body = resendSheet(kind); break;
    default: break;
  }
  return { page: detailHost(v, { hd, buyerNotReady, snack }), overlay: adaptiveSheet(v.width, body, { title: titles[screen] }) };
}

