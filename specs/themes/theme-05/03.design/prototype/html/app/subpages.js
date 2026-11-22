// Màn con của SG-09 (Navigator.push MaterialPageRoute — URL không đổi, vẫn NGOÀI khung):
//   SG-09b Thanh toán & công nợ, SG-09c Lịch sử, SG-09d Phiếu đổi/trả của đơn.
// Nguồn Dart (apps/erp/lib/features/sales/presentation/):
//   widgets/{sales_order_payment_debt_page, sales_order_history_page, sales_order_return_list_page, sales_label_highlight_row, sales_amount_highlight_row}.dart,
//   support/sales_order_detail_mapper.dart (nhãn giao dịch, tiêu đề mốc lịch sử, chênh lệch phiếu), models/sales_order_settlement/sales_order_payment_vm.dart (settlementLabel).
import { appBar, esc, gap, icon, iconBox, scaffold } from './ds.js';
import { money } from './data.js';
import { RETURN_SLIPS, diffText } from './detail.js';

/** SalesOrderPaymentVm.settlementLabel. */
export const SETTLEMENT_LABEL = { unpaid: 'Chưa thu', partiallyPaid: 'Còn phải thu', fullyPaid: 'Đã thanh toán', partiallyRefunded: 'Hoàn một phần', refunded: 'Đã hoàn', noBalance: 'Đã tất toán' };

/** _paidMethodRows: TM / CK > 0 → từng dòng neutral; cả hai = 0 → một dòng "Đã thanh toán" tone PRIMARY (nền xanh như "Tổng đơn"). */
export function paidMethodRows({ cash = 0, bank = 0, paid = 0 }) {
  const rows = [];
  if (cash > 0) rows.push(['Đã thanh toán (TM)', cash, 'neutral']);
  if (bank > 0) rows.push(['Đã thanh toán (CK)', bank, 'neutral']);
  if (cash <= 0 && bank <= 0) rows.push(['Đã thanh toán', paid, 'primary']);
  return rows;
}

/** _transactionRow: "<loại> · <phương thức>"; cấn trừ → "Cấn trừ · từ|sang <mã đơn>" (không có loại) + › sang đơn đối ứng. Không có thời gian. */
export function transactionLabel(tx) {
  if (tx.method === 'offset') return `Cấn trừ · ${tx.kind === 'refund' ? 'sang' : 'từ'} ${tx.counterpart}`;
  const kind = { collection: 'Thu tiền', refund: 'Hoàn tiền' }[tx.kind] || null;
  const method = { cash: 'Tiền mặt', bank: 'Chuyển khoản' }[tx.method];
  return kind ? `${kind} · ${method}` : method;
}

/** SalesAmountHighlightRow (đệm 12, bo 8, không viền): nhãn labelDefault 14/20 w600 + số labelDefaultMono theo tone. SalesLabelHighlightRow (Trạng thái / Hẹn): bodyDefault + bodyDefaultMono. */
const amountRow = (label, value, tone = 'primary', { body = false } = {}) => `<div class="t5-hlr t5-hlr--${tone}${body ? ' t5-hlr--body' : ''}"><span>${esc(label)}</span><b>${esc(typeof value === 'number' ? money(value) : value)}</b></div>`;

const PAY = {
  paid: { order: 'DH-000130', customer: 'Nguyễn Văn Hùng', status: 'fullyPaid', total: 441000, cash: 441000, bank: 0, paid: 441000, outstanding: 0, tx: [{ kind: 'collection', method: 'cash', amount: 441000 }] },
  debt: { order: 'DH-000129', customer: 'Trần Thị Mai', status: 'unpaid', total: 441000, cash: 0, bank: 0, paid: 0, outstanding: 441000, due: '05/12/2026', tx: [] },
  partial: {
    order: 'DH-000128', customer: 'Công ty TNHH Thú y An Phát', status: 'partiallyPaid', total: 2350000, cash: 1000000, bank: 500000, paid: 1500000, outstanding: 850000, due: '30/11/2026',
    tx: [{ kind: 'collection', method: 'cash', amount: 1000000 }, { kind: 'collection', method: 'bank', amount: 500000 }],
  },
  returned: {
    order: 'DH-000130', customer: 'Nguyễn Văn Hùng', status: 'partiallyRefunded', total: 346000, cash: 346000, bank: 0, paid: 346000, outstanding: 0,
    original: { total: 441000, cash: 441000, bank: 0, outstanding: 0 }, slips: [{ number: 'DT-000012', extra: 0 }],
    tx: [{ kind: 'collection', method: 'cash', amount: 441000 }, { kind: 'refund', method: 'cash', amount: 95000 }],
  },
  offset: {
    order: 'DH-000129', customer: 'Trần Thị Mai', status: 'partiallyPaid', total: 441000, cash: 0, bank: 0, paid: 0, offset: 120000, outstanding: 321000, due: '05/12/2026',
    tx: [{ kind: 'collection', method: 'offset', counterpart: 'DH-000118', amount: 120000 }],
  },
};
export const PAYMENT_STATES = Object.keys(PAY);

/**
 * SalesOrderPaymentDebtPage: VPageScaffold "Thanh toán & công nợ" (←). Thân cuộn, lề 16: khe 16; "#<mã> · <khách>" bodyDefaultMono xám; khe 16;
 * thẻ (viền borderDefault, đệm 16) "Tình trạng hiện tại" (w700, khe 12, các hàng sát nhau); [khe 8 "Từ đơn hàng gốc" — KHÔNG khe sau tiêu đề];
 * [khe 8 "Từ phiếu đổi/trả #…" — khe 16 sau tiêu đề và giữa hàng]; [khe 8 "Giao dịch"]; khe 16.
 */
export function paymentDebtPage(state, v) {
  const p = PAY[state] || PAY.paid;
  const current = [
    amountRow('Trạng thái', SETTLEMENT_LABEL[p.status], 'neutral', { body: true }),
    amountRow('Tổng đơn', p.total),
    ...paidMethodRows(p).map(([l, a, t]) => amountRow(l, a, t)),
    p.offset ? amountRow('Đã cấn trừ', p.offset, 'neutral') : '',
    amountRow('Còn phải thu', p.outstanding, 'warning'),
    p.due ? amountRow('Hẹn thanh toán', p.due, 'neutral', { body: true }) : '',
  ].join('');
  const card = (title, inner, titleGap = 0) => `${gap(8)}<div class="t5-card t5-card--pad t5-card--light"><p class="t5-bold">${esc(title)}</p>${titleGap ? gap(titleGap) : ''}${inner}</div>`;
  const original = p.original ? card('Từ đơn hàng gốc', [
    amountRow('Tổng đơn', p.original.total),
    p.original.cash > 0 ? amountRow('Đã thanh toán (TM)', p.original.cash, 'neutral') : '',
    p.original.bank > 0 ? amountRow('Đã thanh toán (CK)', p.original.bank, 'neutral') : '',
    amountRow('Còn phải thu', p.original.outstanding, 'neutral'),
  ].join('')) : '';
  const slips = (p.slips || []).map((s) => card(`Từ phiếu đổi/trả #${s.number}`, amountRow('Khách trả thêm', s.extra, 'neutral'), 16)).join('');
  const tx = p.tx.length ? card('Giao dịch', p.tx.map((t) => {
    const row = amountRow(transactionLabel(t), t.amount, 'neutral');
    return t.method === 'offset' ? `<div class="t5-txlink" role="link"><div class="t5-grow">${row}</div><i class="t5-entry__chev">${icon('chevronRight')}</i></div>` : row;
  }).join('')) : '';
  const body = `<div class="t5-rscroll"><div class="t5-pad">${gap(16)}<p class="t5-ctxmono">#${esc(p.order)} · ${esc(p.customer)}</p>${gap(16)}
    <div class="t5-card t5-card--pad t5-card--light"><p class="t5-bold">Tình trạng hiện tại</p>${gap(12)}${current}</div>${original}${slips}${tx}${gap(16)}</div></div>`;
  return scaffold({ appbar: appBar('Thanh toán & công nợ', { back: true }), body, placeWidth: v.width, windowWidth: v.width });
}

// ---------------------------------------------------------------- SG-09c

const HISTORY = {
  default: [
    ['In phiếu bán hàng', null, 'Phạm Thu Hà', '22/11/2026 10:34'],
    ['Tạo phiếu bán hàng', null, 'Phạm Thu Hà', '22/11/2026 10:32'],
    ['Ghi nhận thanh toán tiền mặt', 441000, 'Phạm Thu Hà', '22/11/2026 10:32'],
    ['Hoàn tất đơn hàng', null, 'Phạm Thu Hà', '22/11/2026 10:32'],
  ],
  returned: [
    ['Ghi nhận hoàn tiền', 95000, 'Lê Quốc Bảo', '24/11/2026 09:15'],
    ['Hoàn tất đổi/trả #DT-000012', null, 'Lê Quốc Bảo', '24/11/2026 09:15'],
    ['Tính lại quyết toán', null, 'Phạm Thu Hà', '24/11/2026 09:15'],
    ['Ghi nhận thanh toán tiền mặt', 441000, 'Phạm Thu Hà', '22/11/2026 10:32'],
    ['Hoàn tất đơn hàng', null, 'Phạm Thu Hà', '22/11/2026 10:32'],
  ],
  cancelled: [
    ['Ghi nhận báo cáo hủy đơn', null, 'Phạm Thu Hà', '21/11/2026 15:40'],
    ['Yêu cầu hoàn tác giá bán', null, 'Phạm Thu Hà', '21/11/2026 15:40'],
    ['Hủy đơn hàng', null, 'Phạm Thu Hà', '21/11/2026 15:40'],
    ['Hoàn tất đơn hàng', null, 'Phạm Thu Hà', '21/11/2026 11:20'],
  ],
};
export const HISTORY_STATES = Object.keys(HISTORY);
const HISTORY_CTX = { default: 'DH-000130 · Nguyễn Văn Hùng', returned: 'DH-000130 · Nguyễn Văn Hùng', cancelled: 'DH-000126 · Đại lý Thuốc thú y Minh Tâm' };

/** _SalesTimelineText.displayActorName: rỗng / UUID / "Không rõ" / "unknown" → tên người bán của đơn, không có → "Nhân viên". */
export function displayActorName(name, fallback = null) {
  const t = String(name || '').trim();
  const unknown = !t || /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(t) || t === 'Không rõ' || t.toLowerCase() === 'unknown';
  if (unknown) return fallback && fallback.trim() ? fallback.trim() : 'Nhân viên';
  return t;
}

/**
 * SalesOrderHistoryPage: "Lịch sử" (←). Lề 16: khe 16; "<mã> · <khách>" bodyDefault xám (không "#", chữ thường — SG-09b dùng "#" + mono); khe 24;
 * "Lịch sử" w700 (lặp tiêu đề app bar); khe 8; thẻ viền borderDefault đệm 16: mỗi mốc = cột 36 [VIconBox tròn 36 history 18 nền successBg + vạch 2 borderDefault cách 4]
 * + khe 8 + [tiêu đề bold (+ " <số tiền>") / khe 4 / "<người> · <thời gian>" bodySmall xám / (khe 4 + mô tả textMuted)], đệm đáy 12 (mốc cuối 0); khe 32.
 */
export function historyPage(state, v) {
  const items = HISTORY[state] || HISTORY.default;
  const rows = items.map(([title, amount, actor, at, desc], i) => {
    const last = i === items.length - 1;
    return `<div class="t5-tl${last ? ' is-last' : ''}"><div class="t5-tl__rail">${iconBox({ ic: 'history', size: 36, iconSize: 18, circle: true, cls: 't5-ibox--success' })}${last ? '' : '<i class="t5-tl__line"></i>'}</div><i class="t5-gap-h8"></i>
      <div class="t5-tl__t"><b>${esc(amount != null ? `${title} ${money(amount)}` : title)}</b>${gap(4)}<span>${esc(`${displayActorName(actor)} · ${at}`)}</span>${desc ? `${gap(4)}<span class="t5-small--muted">${esc(desc)}</span>` : ''}</div></div>`;
  }).join('');
  const body = `<div class="t5-rscroll"><div class="t5-pad">${gap(16)}<p class="t5-body2">${esc(HISTORY_CTX[state] || HISTORY_CTX.default)}</p>${gap(24)}
    <p class="t5-bold">Lịch sử</p>${gap(8)}<div class="t5-card t5-card--pad t5-card--light">${rows}</div>${gap(32)}</div></div>`;
  return scaffold({ appbar: appBar('Lịch sử', { back: true }), body, placeWidth: v.width, windowWidth: v.width });
}

// ---------------------------------------------------------------- SG-09d

const SLIPS_TWO = [
  { id: 'r2', number: 'DT-000014', type: 'Đổi/trả', at: '26/11/2026 14:02', status: 'Hoàn tất', diff: 23000 },
  ...RETURN_SLIPS,
];
export const RETURN_LIST_STATES = ['list', 'single', 'no-identity'];

/**
 * SalesOrderReturnListPage: VPageScaffold "Phiếu đổi/trả" + phụ đề "Đơn <mã> · <khách>" (←). Lề 16: khe 8; "Các lần đổi/trả (N)" w700; khe 8;
 * thẻ viền borderDefault không đệm, Divider 1 giữa hàng; hàng (InkWell đệm 12): icon history 20 + khe 8 + ["<số phiếu> · Đổi/trả" w700 / khe 4 /
 * "<thời gian> · <trạng thái>" bodySmall xám / khe 4 / chênh lệch bodySmall textMuted] + [khe 8 + › nếu có mã phiếu]; khe 32. Loại luôn "Đổi/trả".
 */
export function returnListPage(state, v) {
  let slips = state === 'single' ? RETURN_SLIPS : SLIPS_TWO;
  if (state === 'no-identity') slips = [{ ...SLIPS_TWO[0], id: '' }, SLIPS_TWO[1]];
  const rows = slips.map((s) => `<div class="t5-rlrow" role="${s.id ? 'button' : 'presentation'}"><i class="t5-rlrow__ic">${icon('history')}</i><i class="t5-gap-h8"></i>
    <span class="t5-rlrow__t"><b>${esc(`${s.number} · ${s.type}`)}</b>${gap(4)}<span>${esc(`${s.at} · ${s.status}`)}</span>${gap(4)}<span class="t5-small--muted">${esc(diffText(s.diff))}</span></span>
    ${s.id ? `<i class="t5-gap-h8"></i><i class="t5-entry__chev">${icon('chevronRight')}</i>` : ''}</div>`).join('<hr class="t5-divider">');
  const body = `<div class="t5-rscroll"><div class="t5-pad">${gap(8)}<p class="t5-bold">Các lần đổi/trả (${slips.length})</p>${gap(8)}<div class="t5-card t5-card--light t5-pgroup">${rows}</div>${gap(32)}</div></div>`;
  return scaffold({ appbar: appBar('Phiếu đổi/trả', { back: true, subtitle: 'Đơn DH-000130 · Nguyễn Văn Hùng' }), body, placeWidth: v.width, windowWidth: v.width });
}
