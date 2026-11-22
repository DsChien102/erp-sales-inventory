// SG-14 Kết quả đổi/trả (…/returns/:rid/result), SG-15 Chi tiết phiếu đổi/trả (…/returns/:rid/detail) + sheet "Phiếu đổi/trả",
// SG-16 xem trước phiếu đổi/trả (…/returns/:rid/preview). Mọi route NGOÀI khung.
// Nguồn Dart (apps/erp/lib/features/sales/presentation/):
//   pages/{sales_return_exchange_result_page, sales_return_exchange_detail_page, sales_return_exchange_slip_preview_page, sales_slip_preview_page}.dart,
//   widgets/{sales_return_exchange_result_body, sales_return_result_action_bar, sales_return_exchange_detail_body, sales_return_exchange_detail_header_card,
//   sales_return_exchange_source_order_card, sales_return_exchange_detail_lines_section, sales_return_exchange_detail_summary_card,
//   sales_order_return_slip_sheet}.dart, support/sales_slip_pdf_generator.dart; logic/sales_return_exchange_detail_cubit.dart.
// Key Dart: "sg13" cho cả ba màn (đánh số cũ); TH-05 / CHECKLIST: SG-14, SG-15, SG-16.
import { appBar, badge, button, buttonLg, esc, gap, icon, iconBox, scaffold, toast } from './ds.js';
import { money } from './data.js';
import { EXCHANGE_PRODUCT } from './returns.js';

// ---------------------------------------------------------------- dữ liệu phiếu

/** Hai phiếu khớp SG-09b / 09d đợt 3: DT-000014 khách trả thêm 23.000; DT-000012 hoàn 95.000. Thêm DT-000015 hoàn có cấn trừ. */
export const SLIPS = {
  collect: {
    number: 'DT-000014', status: 'completed', at: '26/11/2026 14:02', atDot: '26/11/2026 · 14:02',
    returns: [{ name: 'Amoxicillin 500mg', unit: 'Hộp', qty: 1, price: 125000, total: 125000 }],
    exchanges: [{ ...EXCHANGE_PRODUCT, qty: 1, total: 148000 }],
    plan: { net: 23000, collect: 23000, processedCollect: 23000, refund: 0, offset: 0, receivableCreate: 0, receivableReverse: 0, offsets: [] },
  },
  refund: {
    number: 'DT-000012', status: 'completed', at: '24/11/2026 09:15', atDot: '24/11/2026 · 09:15',
    returns: [{ name: 'Dầu tắm trị ve rận cho chó mèo 250ml', unit: 'Chai', qty: 1, price: 95000, total: 95000 }], exchanges: [],
    plan: { net: -95000, collect: 0, refund: 95000, processedRefund: 95000, offset: 0, receivableCreate: 0, receivableReverse: 0, offsets: [] },
  },
  offset: {
    number: 'DT-000015', status: 'completed', at: '26/11/2026 16:20', atDot: '26/11/2026 · 16:20',
    returns: [{ name: 'Dầu tắm trị ve rận cho chó mèo 250ml', unit: 'Chai', qty: 1, price: 95000, total: 95000 }], exchanges: [],
    plan: { net: -95000, collect: 0, refund: 35000, processedRefund: 35000, offset: 60000, receivableCreate: 0, receivableReverse: 0, offsets: [{ code: 'DH-000118', amount: 60000 }] },
  },
  processing: {
    number: 'DT-000014', status: 'processing', at: '26/11/2026 14:02', atDot: '26/11/2026 · 14:02',
    returns: [{ name: 'Amoxicillin 500mg', unit: 'Hộp', qty: 1, price: 125000, total: 125000 }], exchanges: [{ ...EXCHANGE_PRODUCT, qty: 1, total: 148000 }],
    plan: { net: 23000, collect: 23000, processedCollect: 0, refund: 0, offset: 0, receivableCreate: 0, receivableReverse: 0, offsets: [] },
  },
};
const valueOf = (s) => ({ ret: s.returns.reduce((a, l) => a + l.total, 0), exc: s.exchanges.reduce((a, l) => a + l.total, 0) });

/** _statusTitle / _statusIcon (SG-14); _statusLabel / _badgeTone (SG-15). */
export const STATUS = {
  completed: { title: 'Đã hoàn tất đổi/trả', icon: 'checkCircle', ok: true, label: 'Hoàn tất', tone: 'success' },
  processing: { title: 'Đang xử lý đổi/trả', icon: 'history', label: 'Đang xử lý', tone: 'primary' },
  confirmed: { title: 'Đã ghi nhận đổi/trả', icon: 'checkCircle', ok: true, label: 'Đã xác nhận', tone: 'info' },
  draft: { title: 'Phiếu nháp đổi/trả', icon: 'info', label: 'Nháp', tone: 'neutral' },
  cancelled: { title: 'Phiếu đổi/trả đã hủy', icon: 'alert', label: 'Đã hủy', tone: 'neutral' },
  blocked: { title: 'Phiếu đổi/trả bị chặn', icon: 'alert', label: 'Bị chặn', tone: 'danger' },
  failed: { title: 'Phiếu đổi/trả thất bại', icon: 'alert', label: 'Thất bại', tone: 'danger' },
};

/** _settlementCard: dòng cấn trừ (chữ đen) + dòng thu / hoàn (VÀNG) + dòng công nợ (VÀNG, kể cả "Không phát sinh công nợ"). */
export function resultSettlementLines(p) {
  const pay = p.refund > 0 ? `Hoàn cho khách: ${money(p.refund)}`
    : p.collect > 0 ? `Thu thêm từ khách: ${money(p.collect)}`
      : p.offset > 0 ? `Hoàn cho khách: ${money(0)}` : 'Không phát sinh thu hoặc hoàn tiền';
  const debt = p.receivableCreate > 0 ? `Ghi nợ khách: ${money(p.receivableCreate)}`
    : p.receivableReverse > 0 ? `Giảm nợ khách: ${money(p.receivableReverse)}` : 'Không phát sinh công nợ';
  return { offsets: p.offsets.filter((o) => o.amount > 0).map((o) => `Cấn trừ vào ${o.code}: ${money(o.amount)}`), pay, debt };
}

/** Header SG-15: thu thêm → "Khách trả thêm"; hoàn → "Hoàn trả khách" (số hoàn, không phải |chênh lệch|); 0 → "Không chênh lệch". */
export function detailBanner(p) {
  if (p.collect > 0 || p.net > 0) return ['Khách trả thêm', p.collect > 0 ? p.collect : p.net];
  if (p.refund > 0 || p.net < 0) return ['Hoàn trả khách', p.refund > 0 ? p.refund : Math.abs(p.net)];
  return ['Không chênh lệch', 0];
}

/** SalesSlipPdfGenerator.settlementRows: dòng đầu là tiêu điểm (đậm, xanh). */
export function settlementRows(p) {
  if (p.net > 0) {
    const pending = p.receivableCreate > 0 ? p.receivableCreate : (p.pendingReceivableCreate || 0);
    const debt = pending > 0 ? pending : (p.processedCollect < p.net ? p.net - p.processedCollect : 0);
    return [['Phải thu thêm', money(p.net)], ['Đã thu', money(p.processedCollect)], ['Công nợ phát sinh', money(debt)]];
  }
  if (p.net < 0) {
    const debtReduction = p.receivableReverse > 0 ? p.receivableReverse : (p.pendingReceivableReverse || 0);
    const refunded = p.processedRefund > 0 ? p.processedRefund : p.refund;
    return [
      ['Cần hoàn tiền', money(p.refund)],
      ...(debtReduction > 0 ? [['Giảm nợ đơn', money(debtReduction)]] : []),
      ...(p.offset > 0 ? [['Cấn trừ sang đơn khác', money(p.offset)]] : []),
      ['Đã hoàn', money(refunded)],
    ];
  }
  return [['Không chênh lệch', money(0)]];
}

// ---------------------------------------------------------------- SG-14

/** SalesReturnResultActionBar (trong THÂN, không phải bottomBar; SafeArea + đệm 16, gạch trên): [“Xem công nợ của khách” secondary large] + "Về trang chủ" | "Xem chi tiết đơn" large. */
const resultBar = (receivable) => `<div class="t5-rbar">${receivable ? `${buttonLg('Xem công nợ của khách', { variant: 'secondary', full: true })}${gap(8)}` : ''}<div class="t5-row">${buttonLg('Về trang chủ', { variant: 'secondary', full: true })}${buttonLg('Xem chi tiết đơn', { full: true })}</div></div>`;

const RESULT = { collect: 'collect', refund: 'refund', offset: 'offset', processing: 'processing' };
export const RESULT_STATES = [...Object.keys(RESULT), 'loading', 'failure', 'not-found', 'pending'];

/**
 * VPageScaffold "Kết quả đổi/trả" (← về đầu ngăn xếp). Thân = Column[cuộn đệm 16: thẻ trạng thái (giữa: icon 40, tiêu đề H4 bold, "Phiếu #…" w600,
 * "dd/MM/yyyy · HH:mm", "Xem phiếu đổi/trả" link) · khe 16 · thẻ khách · khe 16 · "Tóm tắt đổi/trả" · khe 16 · "Quyết toán phiếu"; thanh nút].
 */
export function resultPage(state, v) {
  const page = (body) => scaffold({ appbar: appBar('Kết quả đổi/trả', { back: true }), body, placeWidth: v.width, windowWidth: v.width });
  if (state === 'loading') return page('<div class="t5-center"><span class="t5-spin t5-spin--material"></span></div>');
  const MSG = {
    failure: ['Không tải được kết quả đổi/trả', 'Không tải được chi tiết phiếu.'],
    'not-found': ['Không tìm thấy phiếu đổi/trả', 'Phiếu không tồn tại.'],
    pending: ['Đang đồng bộ dữ liệu', 'Phiếu đang được cập nhật.'],
  };
  if (MSG[state]) {
    const [t, m] = MSG[state];
    return page(`<div class="t5-rcol"><div class="t5-rscroll"><div class="t5-pad16"><b class="t5-msgpanel__t">${esc(t)}</b>${gap(8)}<p class="t5-body2">${esc(m)}</p>${gap(16)}${button('Thử lại', { variant: 'secondary', full: true })}</div></div>${resultBar(false)}</div>`);
  }
  const s = SLIPS[RESULT[state] || 'collect'];
  const st = STATUS[s.status];
  const { ret, exc } = valueOf(s);
  const lines = resultSettlementLines(s.plan);
  const body = `<div class="t5-rcol"><div class="t5-rscroll"><div class="t5-pad16">
    <div class="t5-card t5-card--light t5-card--pad t5-rstat"><i class="t5-rstat__ic${st.ok ? '' : ' is-warn'}">${icon(st.icon)}</i>${gap(8)}<b class="t5-rstat__t">${esc(st.title)}</b>${gap(4)}
      <p class="t5-w600 t5-tc">Phiếu #${esc(s.number)}</p>${gap(4)}<p class="t5-small t5-tc">${esc(s.atDot)}</p>${gap(8)}<button type="button" class="t5-btn t5-btn--link"><span>Xem phiếu đổi/trả</span></button></div>${gap(16)}
    <div class="t5-card t5-card--light t5-card--pad"><p class="t5-bold">Nguyễn Văn Hùng</p>${gap(4)}<p class="t5-small">0912345678</p></div>${gap(16)}
    <div class="t5-card t5-card--light t5-card--pad"><p class="t5-bold">Tóm tắt đổi/trả</p>${gap(8)}
      <div class="t5-arow t5-arow--ink"><span>Giá trị hàng trả</span><b>${esc(money(ret))}</b></div>${gap(4)}<div class="t5-arow t5-arow--ink"><span>Giá trị hàng đổi</span><b>${esc(money(exc))}</b></div>${gap(8)}
      <div class="t5-card--p12 t5-hlbox t5-hlbox--plain"><b>Chênh lệch</b><em>${esc(money(s.plan.net))}</em></div></div>${gap(16)}
    <div class="t5-card t5-card--light t5-card--pad"><p class="t5-bold">Quyết toán phiếu</p>${gap(8)}<div class="t5-row t5-row--top"><i class="t5-settle__ic">${icon('wallet')}</i>
      <span class="t5-grow">${lines.offsets.map((l) => `<p class="t5-bodyp">${esc(l)}</p>${gap(4)}`).join('')}<p class="t5-bodyp t5-text-warning">${esc(lines.pay)}</p>${gap(4)}<p class="t5-bodyp t5-text-warning">${esc(lines.debt)}</p></span></div></div>
  </div></div>${resultBar(s.plan.offset > 0)}</div>`;
  return page(body);
}

// ---------------------------------------------------------------- SG-15

const DETAIL = { collect: 'collect', refund: 'refund' };
export const RETURN_DETAIL_STATES = [...Object.keys(DETAIL), 'loading', 'error', 'toast-pdf'];

/** _buildLineCard: VCard viền nhạt đệm 12: VIconBox 40 (box | store, nền surfaceAlt, bo 8) + khe 16 + [tên w600 / khe 4 / "1 Hộp × 125.000đ"] + khe 8 + thành tiền bold (không mono). */
const lineCard = (l, ic) => `<div class="t5-card t5-card--light t5-card--p12 t5-row t5-row--16">${iconBox({ ic, size: 40, iconSize: 20, radius: 8, cls: 't5-ibox--alt' })}<span class="t5-grow"><p class="t5-w600">${esc(l.name)}</p>${gap(4)}<p class="t5-small">${esc(`${l.qty} ${l.unit} × ${money(l.price)}`)}</p></span><b class="t5-ltotal">${esc(money(l.total))}</b></div>`;

/**
 * VPageScaffold "Chi tiết phiếu đổi/trả" (← về chi tiết đơn). Thân cuộn đệm 16: thẻ đầu (số phiếu H4 bold KHÔNG "#" | badge; "dd/MM/yyyy HH:mm"; tên; SĐT;
 * khối xanh "Khách trả thêm" / "Hoàn trả khách"), khe 16, thẻ đơn nguồn ("Đã trả một phần" cố định), khe 16, Hàng trả / Hàng đổi (thẻ rời, khe 4), khe 16, tóm tắt.
 * Thanh dưới "Thao tác ⌃" như SG-09.
 */
export function returnDetailPage(state, v, { toastHtml = '' } = {}) {
  const bar = `<button type="button" class="t5-btn t5-btn--primary t5-btn--full t5-btn--lg"><span>Thao tác</span><i class="t5-btn__trail">${icon('chevronUp')}</i></button>`;
  const page = (body, bottomBar = '') => scaffold({ appbar: appBar('Chi tiết phiếu đổi/trả', { back: true }), body: body + toastHtml, bottomBar, placeWidth: v.width, windowWidth: v.width, cls: 't5-page--compose' });
  if (state === 'loading') return page('<div class="t5-center"><span class="t5-spin t5-spin--material"></span></div>');
  if (state === 'error') return page(`<div class="t5-pad16"><p class="t5-bodyp">Không tải được chi tiết phiếu.</p>${gap(16)}${button('Thử lại', { full: true })}</div>`);
  const s = SLIPS[DETAIL[state] || 'collect'];
  const st = STATUS[s.status];
  const { ret, exc } = valueOf(s);
  const [bl, ba] = detailBanner(s.plan);
  const body = `<div class="t5-rscroll"><div class="t5-pad16">
    <div class="t5-card t5-card--light t5-card--pad"><div class="t5-dhead"><b class="t5-h4b">${esc(s.number)}</b>${badge(st.label, { tone: st.tone })}</div>${gap(4)}<p class="t5-small">${esc(s.at)}</p>${gap(8)}
      <p class="t5-bold">Nguyễn Văn Hùng</p>${gap(4)}<p class="t5-small">0912345678</p>${gap(16)}<div class="t5-card t5-card--p12 t5-hlbox"><b>${esc(bl)}</b><em>${esc(money(ba))}</em></div></div>${gap(16)}
    <div class="t5-card t5-card--light t5-card--p12 t5-row t5-row--16" role="button">${iconBox({ ic: 'history', size: 36, iconSize: 18, radius: 8, cls: 't5-ibox--alt' })}<span class="t5-grow"><p class="t5-w600">Đơn hàng nguồn DH-000130</p>${gap(4)}<p class="t5-small">Đã trả một phần</p></span><i class="t5-entry__chev t5-entry__chev--sec">${icon('chevronRight')}</i></div>${gap(16)}
    <p class="t5-bold">Hàng trả</p>${gap(4)}${s.returns.map((l) => `${lineCard(l, 'box')}${gap(4)}`).join('')}
    ${s.exchanges.length ? `${gap(8)}<p class="t5-bold">Hàng đổi</p>${gap(4)}${s.exchanges.map((l) => `${lineCard(l, 'store')}${gap(4)}`).join('')}` : ''}${gap(16)}
    <div class="t5-card t5-card--light t5-card--pad"><p class="t5-bold">Tóm tắt đổi/trả</p>${gap(16)}
      <div class="t5-arow t5-arow--w500"><span>Giá trị hàng trả</span><b>${esc(money(ret))}</b></div>${gap(8)}<div class="t5-arow t5-arow--w500"><span>Giá trị hàng đổi</span><b>${esc(money(exc))}</b></div>${gap(16)}
      <div class="t5-card t5-card--p12 t5-hlbox"><b>Chênh lệch</b><em>${esc(money(Math.abs(s.plan.net)))}</em></div></div>${gap(16)}</div></div>`;
  return page(body, bar);
}
export const returnDetailToast = (v) => toast('danger', 'Xuất PDF thất bại', 'Exception: Unable to load asset: "packages/c45_design_system/assets/fonts/ttf_Inter/Inter-Regular.ttf".', { bottom: 14 + 77 + (v.device === 'iphone' ? 34 : 0) });

// ---------------------------------------------------------------- SG-16 phiếu đổi/trả

/** Trang A5 theo _buildReturnSlipBody: đầu "V45" + tên cửa hàng IN HOA; "PHIẾU ĐỔI/TRẢ"; "DT-…  ·  Đơn DH-…"; Ngày xác nhận / Khách / SĐT; Hàng trả; Hàng đổi; dòng quyết toán; "Cảm ơn quý khách!". */
export function returnSlipPaper(s) {
  const row = (l, val, head = false) => `<div class="t5-pdf__row${head ? ' is-bold is-head' : ''}"><span>${esc(l)}</span><b class="${/[0-9]/.test(val) ? 'is-mono' : ''}">${esc(val)}</b></div>`;
  const item = (l) => `<div class="t5-pdf__line"><div><b>${esc(l.name)}</b><span>${esc(`${l.qty} ${l.unit} × ${money(l.price)}`)}</span></div><em>${esc(money(l.total))}</em></div>`;
  const rows = settlementRows(s.plan);
  return `<div class="t5-pdf__page"><div class="t5-pdf__box">
    <div class="t5-pdf__head"><span class="t5-pdf__logo">V45</span><div><b>MOSAIC RETAIL DEMO</b><span>CH-01</span></div></div><i class="t5-pdf__g6"></i><hr class="t5-pdf__hr">
    <i class="t5-pdf__g6"></i><p class="t5-pdf__title">PHIẾU ĐỔI/TRẢ</p><p class="t5-pdf__no">${esc(s.number)}  ·  Đơn DH-000130</p><i class="t5-pdf__g8"></i>
    ${row('Ngày xác nhận', s.atDot)}${row('Khách hàng', 'Nguyễn Văn Hùng')}${row('Số điện thoại', '0912345678')}
    <i class="t5-pdf__g6"></i><hr class="t5-pdf__hr"><i class="t5-pdf__g6"></i><p class="t5-pdf__sec">Hàng trả</p><i class="t5-pdf__g6"></i>${s.returns.map(item).join('<i class="t5-pdf__g4"></i>')}
    ${s.exchanges.length ? `<i class="t5-pdf__g6"></i><p class="t5-pdf__sec">Hàng đổi</p><i class="t5-pdf__g6"></i>${s.exchanges.map(item).join('<i class="t5-pdf__g4"></i>')}` : ''}
    <i class="t5-pdf__g6"></i><hr class="t5-pdf__hr"><i class="t5-pdf__g6"></i>${rows.map(([l, val], i) => row(l, val, i === 0)).join('')}
    <i class="t5-pdf__g8"></i><hr class="t5-pdf__hr"><i class="t5-pdf__g6"></i><p class="t5-pdf__thanks">Cảm ơn quý khách!</p>
  </div></div>`;
}

const SLIP = { collect: 'collect', refund: 'refund', offset: 'offset' };
export const SLIP_STATES = [...Object.keys(SLIP), 'loading', 'pdf-loading', 'error'];

/**
 * SalesReturnExchangeSlipPreviewPage: đang tải → VPageScaffold + CircularProgressIndicator; thiếu dữ liệu → câu giữa màn + "Thử lại" xanh.
 * SalesSlipPreviewPage: app bar "Phiếu đổi/trả" + MỘT icon ⋮ (chạm = sinh PDF rồi CHIA SẺ; không có in); PdfPreview như SG-16 phiếu bán (lề 20 / 8 / 20 / 12, ≤ 700).
 */
export function slipPreviewPage(state, v) {
  const actions = `<button type="button" class="t5-icon-btn" aria-label="Tuỳ chọn">${icon('moreVert')}</button>`;
  if (state === 'loading') return scaffold({ appbar: appBar('Phiếu đổi/trả', { back: true }), body: '<div class="t5-center"><span class="t5-spin t5-spin--material"></span></div>', placeWidth: v.width, windowWidth: v.width });
  if (state === 'error') {
    return scaffold({ appbar: appBar('Phiếu đổi/trả', { back: true }), body: `<div class="t5-center"><div class="t5-pad16 t5-tc"><p class="t5-bodyp">Không tải được phiếu đổi/trả để xem trước.</p>${gap(16)}${button('Thử lại')}</div></div>`, placeWidth: v.width, windowWidth: v.width });
  }
  let body;
  if (state === 'pdf-loading') body = `<div class="t5-center t5-center--col"><span class="t5-spin t5-spin--40"></span>${gap(8)}<p class="t5-small">Đang tạo bản xem trước PDF...</p></div>`;
  else {
    const col = Math.min(v.width, v.width >= 1024 ? 720 : v.width >= 600 ? 640 : v.width);
    const pageW = Math.min(700, col - 40);
    const scale = pageW / 419.53;
    body = `<div class="t5-pdfview"><div class="t5-pdfview__slot" style="width:${pageW}px;height:${Math.round(595.28 * scale)}px"><div class="t5-pdf" style="transform:scale(${scale.toFixed(4)})">${returnSlipPaper(SLIPS[SLIP[state]])}</div></div></div>`;
  }
  return scaffold({ appbar: appBar('Phiếu đổi/trả', { back: true, actions }), body, placeWidth: v.width, windowWidth: v.width });
}
