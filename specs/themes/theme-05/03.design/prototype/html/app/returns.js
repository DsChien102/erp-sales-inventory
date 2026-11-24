// SG-12 Lập phiếu đổi/trả (/sales/orders/:id/returns/new) + sheet chọn hàng đổi, sheet "Bỏ thay đổi?";
// SG-13 Quyết toán đổi/trả (/sales/orders/:id/returns/:rid/settle) + sheet "Xác nhận đổi/trả?", hộp "Công nợ của khách vừa thay đổi".
// Mọi route là GoRoute cấp gốc → NGOÀI khung. Sheet showVBottomSheet (web sheet đáy 640).
// Nguồn Dart (apps/erp/lib/features/sales/presentation/):
//   pages/{sales_return_exchange_create_page, sales_return_exchange_settlement_page}.dart,
//   widgets/{sales_return_exchange_session_body, sales_return_exchange_session_line_rows, sales_order_line_quantity, sales_exchange_product_picker_sheet,
//   sales_return_discard_dialog, sales_return_exchange_settlement_body, sales_return_entitled_settlement, sales_return_confirm_settlement_sheet,
//   sales_receivable_changed_dialog}.dart, support/sales_return_exchange_pricing_copy.dart;
//   logic/{sales_return_exchange_session_cubit, sales_return_exchange_settlement_cubit, sales_return_exchange_settlement_state, return_settlement_preview}.dart;
//   features/receivable/{logic/receivable_format, presentation/widgets/receivable_parts}.dart (khối cấn trừ).
// Nhánh "khách được hưởng" dựng theo prototype Theme 6 `app/sg13.js` (thiết kế TH-06); ở đây vẽ theo Flutter.
// Key Dart: "sg11" = lập phiếu, "sg12" = quyết toán (đánh số cũ); TH-05 / CHECKLIST: SG-12, SG-13.
import {
  appBar, banner, bottomSheet, button, buttonLg, emptyDesc, emptyMedia, emptyState, emptyTitle, esc, gap, icon, input, scaffold, searchBar, segmented, skeleton, suffixText,
} from './ds.js';
import { money } from './data.js';
import { qtyControls } from './compose.js';

// ---------------------------------------------------------------- dữ liệu

/** Dòng trả được của DH-000130 (RPC: originalUnitPrice = giá SAU giảm / đơn vị → pate 16.000). */
export const RETURNABLE = [
  { id: 'l1', name: 'Amoxicillin 500mg', unit: 'Hộp', price: 125000, max: 2 },
  { id: 'l2', name: 'Pate cho mèo vị cá ngừ 85g', unit: 'Lon', price: 16000, max: 6 },
  { id: 'l3', name: 'Dầu tắm trị ve rận cho chó mèo 250ml', unit: 'Chai', price: 95000, max: 1 },
];
export const EXCHANGE_PRODUCT = { name: 'Frontline Plus cho chó 10–20kg', unit: 'Tuýp', price: 148000 };

/** _ExpectedSummaryCard: hàng trả = giá × SL; đổi; chênh lệch = đổi − trả. > 0 vàng (nền vàng 10%), < 0 xanh (nền xanh 10%), 0 đen (nền surfaceAlt). */
export function expectedSummary(returns, exchanges = []) {
  const ret = returns.reduce((s, r) => s + r.price * r.qty, 0);
  const exc = exchanges.reduce((s, e) => s + e.price * e.qty, 0);
  const diff = exc - ret;
  return { ret, exc, diff, tone: diff > 0 ? 'warning' : diff < 0 ? 'success' : 'neutral' };
}

/** Picker: tồn 1…5 → "Còn N" (vàng đậm); khác → số trần; không có → rỗng. */
export function pickerStockLabel(stock) {
  if (stock == null) return { text: '', low: false };
  if (stock > 0 && stock <= 5) return { text: `Còn ${stock}`, low: true };
  return { text: String(stock), low: false };
}

/** _signedMoney (khối "Tóm tắt đổi/trả" SG-13): "+23.000đ" / "-95.000đ" (gạch nối, không phải dấu trừ). */
export const signedMoney = (n) => `${n > 0 ? '+' : n < 0 ? '-' : ''}${money(Math.abs(n))}`;

/** formatVnd (receivable_format.dart): "95.000 ₫" có dấu cách — khác MoneyFormatter "95.000đ". */
export const formatVnd = (n) => `${money(n).replace('đ', '')} ₫`;
export const formatVndBare = (n) => money(n).replace('đ', '');

/** planReturnSettlement: chia cho đơn đang tick theo thứ tự server (cũ trước), mỗi đơn ≤ còn nợ; dư = hoàn. */
export function planReturnSettlement({ reduceOwnDebt = 0, distributable, candidates = [], selected = [] }) {
  let remaining = distributable;
  const offsets = candidates.map((c) => {
    let amount = 0;
    if (selected.includes(c.id) && remaining > 0) {
      amount = Math.min(remaining, c.outstanding);
      remaining -= amount;
    }
    return { id: c.id, code: c.code, amount };
  });
  return { reduceOwnDebt, offsets, offsetTotal: distributable - remaining, refund: remaining, showOffsetBlock: candidates.length > 0 && distributable > 0 };
}

/** orderDueLabel: quá hạn → "Quá hạn N ngày" (đỏ + ⚠); không hẹn → "Không có hẹn"; ≤ hôm nay → "Đến hạn hôm nay" (vàng); còn lại "Hẹn dd/MM" (xám). */
export function orderDueLabel({ overdueDays = 0, due = null, today = '2026-11-26' }) {
  if (overdueDays > 0) return { kind: 'overdue', text: `Quá hạn ${overdueDays} ngày` };
  if (!due) return { kind: 'none', text: 'Không có hẹn' };
  if (due <= today) return { kind: 'today', text: 'Đến hạn hôm nay' };
  const [, m, d] = due.split('-');
  return { kind: 'upcoming', text: `Hẹn ${d}/${m}` };
}

/** buildReturnConfirmationMessage: từ KẾ HOẠCH server (không theo số khách trả ngay vừa nhập). Nối "a, b và c." */
export function confirmationMessage({ refund = 0, collect = 0, receivableCreate = 0, receivableReverse = 0 }) {
  if (refund <= 0 && collect <= 0 && receivableCreate <= 0 && receivableReverse <= 0) return 'Xác nhận đổi/trả hàng không phát sinh chênh lệch.';
  const parts = [];
  if (collect > 0) parts.push(`Thu thêm ${money(collect)} từ khách`);
  if (refund > 0) parts.push(`Hoàn ${money(refund)} cho khách`);
  if (receivableCreate > 0) parts.push(`ghi nhận công nợ ${money(receivableCreate)}`);
  if (receivableReverse > 0) parts.push(`ghi giảm công nợ ${money(receivableReverse)}`);
  if (parts.length === 1) return `${parts[0]}.`;
  return `${parts.slice(0, -1).join(', ')} và ${parts[parts.length - 1]}.`;
}

/** buildEntitledSettlementLines (nhánh khách được hưởng): gạch đầu dòng, tiền formatVnd. */
export function entitledLines(plan) {
  return [
    ...(plan.reduceOwnDebt > 0 ? [`Giảm nợ đơn này ${formatVnd(plan.reduceOwnDebt)}`] : []),
    ...plan.offsets.filter((o) => o.amount > 0).map((o) => `Cấn trừ ${formatVnd(o.amount)} vào đơn ${o.code}`),
    ...(plan.refund > 0 ? [`Hoàn ${formatVnd(plan.refund)} cho khách`] : []),
  ];
}

// ---------------------------------------------------------------- SG-12

/** Ô sản phẩm 40 nền surfaceAlt bo 8, icon Material (inventory_2 / local_pharmacy / image) textMuted 24. */
const matBox = (ic, size = 40) => `<span class="t5-matbox" style="width:${size}px;height:${size}px">${icon(ic)}</span>`;

function returnRow(l, qty, disabled) {
  return `<div class="t5-rrow"><div class="t5-row t5-row--top">${matBox('mInventory')}<span class="t5-rrow__t"><b>${esc(l.name)}</b>${gap(4)}<span>${esc(`${money(l.price)}/${l.unit}`)}</span></span>${qtyControls(qty, { disabled })}</div></div>`;
}
function exchangeRow(e, disabled) {
  return `<div class="t5-rrow"><div class="t5-row">${matBox('mPharmacy')}<span class="t5-rrow__t"><b>${esc(e.name)}</b>${gap(4)}<span>${esc(`${money(e.price)}/${e.unit}`)}</span></span>${qtyControls(e.qty, { disabled })}</div></div>`;
}

const CREATE = {
  empty: { qty: {} },
  'return-only': { qty: { l3: 1 } },
  max: { qty: { l3: 1, l2: 6 } },
  exchange: { qty: { l1: 1 }, exchange: 1 },
  saving: { qty: { l1: 1 }, exchange: 1, saving: true },
  'stale-price': { qty: { l1: 1 }, exchange: 1, banner: 'Giá món đổi đã thay đổi. Đã cập nhật giá mới, vui lòng kiểm tra lại.' },
};
export const CREATE_STATES = ['loading', ...Object.keys(CREATE), 'blocked', 'error'];

/** _MessagePanel: ⚠ đỏ + khe 4 + tiêu đề H4 bold; khe 8; câu bodyDefault xám (+ khe 4); [khe 16 + "Tải lại" secondary đầy ngang]. Không có thanh dưới. */
const messagePanel = (title, messages, { retry = 'Tải lại', warn = true } = {}) => `<div class="t5-rscroll"><div class="t5-msgpanel">
  <div class="t5-row t5-row--4">${warn ? `<i class="t5-msgpanel__ic">${icon('alert')}</i>` : ''}<b class="t5-msgpanel__t">${esc(title)}</b></div>${gap(8)}
  ${messages.map((m) => `<p class="t5-body2">${esc(m)}</p>${gap(4)}`).join('')}${retry ? `${gap(16)}${button(retry, { variant: 'secondary', full: true })}` : ''}</div></div>`;

/**
 * VPageScaffold "Đổi/trả hàng" (← IconButton 48). Thân cuộn đệm 16: "DH-000130 · Nguyễn Văn Hùng" bodySmall xám; khe 4; "Chọn hàng trả và số lượng."; [banner];
 * khe 16; "Hàng trả" bold; khe 4; thẻ (viền nhạt, đệm 8) các dòng trả (đệm 8; Divider); khe 16; "Hàng đổi" bold; khe 4; [thẻ dòng đổi + khe 8];
 * "Chọn hàng đổi" secondary đầy ngang (mờ khi chưa chọn dòng trả); khe 16; "Tóm tắt dự kiến"; khe 32.
 * Thanh dưới (Container đệm 16 + gạch trên): "Tiếp tục" / "Đang lưu..." xanh large đầy ngang.
 */
export function createPage(state, v) {
  const bar = (label, enabled) => `<button type="button" class="t5-btn t5-btn--primary t5-btn--full t5-btn--lg"${enabled ? '' : ' disabled'}><span>${esc(label)}</span></button>`;
  const page = (body, bottomBar = '') => scaffold({ appbar: appBar('Đổi/trả hàng', { back: true }), body, bottomBar, placeWidth: v.width, windowWidth: v.width });
  if (state === 'loading') return page('<div class="t5-center"><span class="t5-spin t5-spin--material"></span></div>');
  if (state === 'blocked') return page(messagePanel('Không thể đổi/trả đơn DH-000130', ['Đơn đang có phiếu đổi/trả chưa hoàn tất.']));
  if (state === 'error') return page(messagePanel('Không thể tải phiên đổi/trả', ['Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.']));
  const c = CREATE[state] || CREATE.empty;
  const dis = !!c.saving;
  const returns = RETURNABLE.map((l) => ({ ...l, qty: c.qty[l.id] || 0 }));
  const exchanges = c.exchange ? [{ ...EXCHANGE_PRODUCT, qty: c.exchange }] : [];
  const sum = expectedSummary(returns, exchanges);
  const hasReturn = returns.some((r) => r.qty > 0);
  const summaryRow = (l, val, cls = '') => `<div class="t5-esrow ${cls}"><span>${esc(l)}</span><b>${esc(val)}</b></div>`;
  const body = `<div class="t5-rscroll"><div class="t5-pad16">
    <p class="t5-small">DH-000130 · Nguyễn Văn Hùng</p>${gap(4)}<p class="t5-small">Chọn hàng trả và số lượng.</p>
    ${c.banner ? `${gap(16)}${banner('error', c.banner, '', { trailing: button('Thử lại', { variant: 'secondary', size: 'small' }) })}` : ''}
    ${gap(16)}<p class="t5-bold">Hàng trả</p>${gap(4)}<div class="t5-card t5-card--light t5-card--p8">${returns.map((r) => returnRow(r, r.qty, dis)).join('<hr class="t5-divider">')}</div>
    ${gap(16)}<p class="t5-bold">Hàng đổi</p>${gap(4)}
    ${exchanges.length ? `<div class="t5-card t5-card--light t5-card--p8">${exchanges.map((e) => exchangeRow(e, dis)).join('')}</div>${gap(8)}` : ''}
    ${button('Chọn hàng đổi', { variant: 'secondary', full: true, disabled: !hasReturn || dis })}${gap(16)}
    <div class="t5-card t5-card--light t5-card--pad"><p class="t5-bold">Tóm tắt dự kiến</p>${gap(16)}
      ${summaryRow('Giá trị hàng trả', money(sum.ret))}${gap(8)}${summaryRow('Giá trị hàng đổi', money(sum.exc))}${gap(16)}
      <div class="t5-esdiff t5-esdiff--${sum.tone}">${summaryRow('Chênh lệch', money(sum.diff), 't5-esrow--diff')}</div></div>${gap(32)}</div></div>`;
  return page(body, bar(dis ? 'Đang lưu...' : 'Tiếp tục', hasReturn && !dis));
}

// ---------------------------------------------------------------- sheet SG-12

export const PICKER_ITEMS = [
  { name: 'Frontline Plus cho chó 10–20kg', unit: 'Tuýp', price: 148000, stock: 3 },
  { name: 'Thức ăn hạt cho chó con 1,5kg', unit: 'Túi', price: 289000, stock: 15 },
  { name: 'Pate cho mèo vị cá ngừ 85g', unit: 'Lon', price: 18000, stock: 120 },
  { name: 'Pate cho mèo vị cá ngừ 85g', unit: 'Lốc 6 lon', price: 102000, stock: 20 },
];

/**
 * showSalesExchangeProductPickerSheet: CÓ tiêu đề "Chọn hàng đổi" + gạch; SizedBox cao CỐ ĐỊNH 480, đệm 16: "Chạm sản phẩm để thêm vào phiếu." bodySmall;
 * khe 8; VSearchBar "Tìm tên, SKU hoặc barcode"; khe 16; khung viền nhạt đệm 8 chứa thẻ (đệm 12, ô ảnh Material 48, khe 16,
 * [tên bold / khe 4 / "<tên> · <đơn vị>" (lặp tên) / khe 8 / giá bold (3) | đơn vị (2, giữa) | tồn (2, phải)]).
 */
export function pickerSheet(kind = 'ready') {
  let results;
  if (kind === 'loading') {
    const sk = () => `<div class="t5-card t5-card--light t5-card--p12 t5-row t5-row--top t5-row--16">${skeleton(48, { radius: 8, w: '48px' })}<span class="t5-grow t5-stack0">${skeleton(16, { radius: 4, w: '140px' })}${gap(4)}${skeleton(12, { radius: 4, w: '180px' })}${gap(8)}<span class="t5-pk__cols"><span>${skeleton(16, { radius: 4, w: '80px' })}</span><span class="t5-tc">${skeleton(12, { radius: 4, w: '40px' }).replace('display:block', '')}</span><span class="t5-pk__right">${skeleton(12, { radius: 4, w: '30px' })}</span></span></span></div>`;
    results = `<div class="t5-pkbox">${sk()}${gap(8)}${sk()}${gap(8)}${sk()}</div>`;
  } else if (kind === 'empty') {
    results = `<div class="t5-center">${emptyState({ header: [emptyMedia('mSearchOff'), emptyTitle('Không tìm thấy sản phẩm'), emptyDesc('Thử tìm kiếm với từ khóa khác')], fill: false })}</div>`;
  } else if (kind === 'error') {
    results = `<div class="t5-center">${emptyState({ header: [emptyMedia('mError'), emptyTitle('Không thể tải sản phẩm'), emptyDesc('Exception: Failed host lookup: \'pzlsjedtsntkarkivhve.supabase.co\'')], content: button('Thử lại'), fill: false })}</div>`;
  } else {
    results = `<div class="t5-pkbox">${PICKER_ITEMS.map((it) => {
      const st = pickerStockLabel(it.stock);
      return `<div class="t5-card t5-card--light t5-card--p12 t5-row t5-row--top t5-row--16" role="button">${matBox('mImage', 48)}<span class="t5-pk__t"><b>${esc(it.name)}</b>${gap(4)}<span>${esc(`${it.name} · ${it.unit}`)}</span>${gap(8)}
        <span class="t5-pk__cols"><b>${esc(money(it.price))}</b><span class="t5-tc">${esc(it.unit)}</span><span class="t5-pk__right${st.low ? ' is-low' : ''}">${esc(st.text)}</span></span></span></div>`;
    }).join(gap(8))}</div>`;
  }
  return `<div class="t5-pk"><p class="t5-small">Chạm sản phẩm để thêm vào phiếu.</p>${gap(8)}${searchBar({ hint: 'Tìm tên, SKU hoặc barcode' })}${gap(16)}<div class="t5-pk__res">${results}</div></div>`;
}

/** showSalesReturnDiscardDialog: sheet không tiêu đề, VPagePadding (không đệm dọc): "Bỏ thay đổi?" H3 đỏ; khe 4; câu; khe 24; "Tiếp tục đổi/trả" (secondary) TRÊN "Bỏ thay đổi" (viền đỏ). */
export const discardSheet = () => `<div class="t5-pad"><h2 class="t5-h3b t5-text-danger">Bỏ thay đổi?</h2>${gap(4)}<p class="t5-body2">Hàng trả và hàng đổi vừa chọn chưa được lưu.</p>${gap(24)}
  ${buttonLg('Tiếp tục đổi/trả', { variant: 'secondary', full: true })}${gap(8)}${buttonLg('Bỏ thay đổi', { variant: 'secondary', tone: 'danger', full: true, cls: 't5-btn--sec-danger' })}</div>`;

// ---------------------------------------------------------------- SG-13

const CANDIDATES = [
  { id: 'o18', code: 'DH-000118', outstanding: 60000, overdueDays: 5 },
  { id: 'o22', code: 'DH-000122', outstanding: 120000, due: '2026-11-30' },
];

const SETTLE = {
  collect: { kind: 'collect', collect: 23000, settled: 23000, ret: 125000, exc: 148000 },
  'collect-partial': { kind: 'collect', collect: 23000, settled: 10000, ret: 125000, exc: 148000 },
  'collect-dated': { kind: 'collect', collect: 23000, settled: 10000, due: '30/11/2026', ret: 125000, exc: 148000, expanded: true },
  'walk-in': { kind: 'collect', collect: 23000, settled: 23000, ret: 125000, exc: 148000, walkIn: true },
  zero: { kind: 'zero', ret: 125000, exc: 125000, expanded: true },
  refund: { kind: 'entitled', entitled: 95000, ret: 95000, exc: 0, reduceOwnDebt: 0, candidates: [] },
  'refund-debt': { kind: 'entitled', entitled: 95000, ret: 95000, exc: 0, reduceOwnDebt: 95000, distributable: 0, candidates: [], order: 'DH-000129 · Trần Thị Mai' },
  'refund-offset': { kind: 'entitled', entitled: 95000, ret: 95000, exc: 0, reduceOwnDebt: 0, candidates: CANDIDATES, selected: ['o18'] },
  'confirm-price': { kind: 'collect', collect: 23000, settled: 23000, ret: 125000, exc: 148000, banner: 'Giá món đổi đã thay đổi. Vui lòng quay lại màn đổi/trả để cập nhật giá.' },
  confirming: { kind: 'collect', collect: 23000, settled: 23000, ret: 125000, exc: 148000, confirming: true },
};
export const SETTLE_STATES = [...Object.keys(SETTLE), 'loading', 'blocked', 'error'];

export function settlePlan(c) {
  if (c.kind !== 'entitled') return null;
  return planReturnSettlement({ reduceOwnDebt: c.reduceOwnDebt, distributable: c.distributable ?? c.entitled - c.reduceOwnDebt, candidates: c.candidates, selected: c.selected || [] });
}

/** Thẻ số nổi bật (_highlightAmount): VCard nền successBg đệm 12, nhãn bodyDefault bold | số bold xanh (MoneyFormatter "23.000đ"). */
const highlight = (label, amount) => `<div class="t5-card t5-card--p12 t5-hlbox"><b>${esc(label)}</b><em>${esc(money(amount))}</em></div>`;

/** _amountRow secondary: nhãn bodySmall xám | số bodyDefault w600. */
const amountRow = (label, value) => `<div class="t5-arow"><span>${esc(label)}</span><b>${esc(value)}</b></div>`;

function collectCard(c) {
  const outstanding = Math.max(0, c.collect - c.settled);
  const due = outstanding > 0 ? `${gap(16)}<p class="t5-bold t5-row t5-row--4">Ngày hẹn thanh toán<span class="t5-text-danger">*</span></p>${gap(8)}
    <button type="button" class="t5-due48${c.due ? ' has-value' : ''}">${icon('calendar')}<span>${esc(c.due || 'Chọn ngày hẹn')}</span></button>` : '';
  return `${highlight('Phải thu thêm', c.collect)}${gap(16)}<p class="t5-bold">Khách thanh toán ngay</p>${gap(8)}
    ${input({ value: money(c.settled).replace('đ', ''), suffix: suffixText('đ'), disabled: !!c.walkIn })}
    ${c.walkIn ? `${gap(4)}<p class="t5-small">Thu đủ, không phát sinh công nợ.</p>` : ''}${gap(16)}
    <p class="t5-bold">Phương thức thu</p>${gap(8)}${segmented(['Tiền mặt', 'Chuyển khoản'], 0)}${gap(24)}
    ${amountRow('Công nợ phát sinh', money(outstanding))}${due}`;
}

/** Khối "Tóm tắt đổi/trả" thu gọn (chạm mở): tiêu đề bold + "Chênh lệch +23.000đ" bodySmall + chevron 24; mở → 3 hàng. */
function planCard(c) {
  const diff = c.exc - c.ret;
  return `<div class="t5-card t5-card--light t5-card--pad"><div class="t5-row" role="button"><span class="t5-grow"><b class="t5-bold">Tóm tắt đổi/trả</b>${gap(4)}<span class="t5-small">Chênh lệch ${esc(signedMoney(diff))}</span></span><i class="t5-planchev">${icon(c.expanded ? 'chevronUp' : 'chevronDown')}</i></div>
    ${c.expanded ? `${gap(16)}${amountRow('Giá trị hàng trả', money(c.ret))}${gap(8)}${amountRow('Giá trị hàng đổi', money(c.exc))}${gap(8)}${amountRow('Chênh lệch', signedMoney(diff))}` : ''}</div>`;
}

/** SalesReturnEntitledSettlement (TH-06 EP-03): dòng phụ labelDefault w600 (đệm 16/12), "Khách được hưởng" + số 28 xanh + meta; khối chia (thanh 8 + dòng chấm); [CẤN TRỪ VÀO ĐƠN KHÁC]. */
function entitledBody(c, plan) {
  const segs = [['own', plan.reduceOwnDebt], ['offset', plan.offsetTotal], ['refund', plan.refund]].filter(([, val]) => val > 0);
  const flowRow = (k, label, value, note = '') => `<div class="t5-flow__row"><span class="t5-flow__dot t5-flow__dot--${k}"></span><span class="t5-grow"><span class="t5-flow__l">${esc(label)}</span>${note ? `<span class="t5-flow__n">${esc(note)}</span>` : ''}</span><b class="t5-flow__v">${esc(value)}</b></div>`;
  const offsetRow = (cd) => {
    const share = plan.offsets.find((o) => o.id === cd.id).amount;
    const on = (c.selected || []).includes(cd.id);
    const due = orderDueLabel(cd);
    return `<div class="t5-offrow" role="checkbox" aria-checked="${on}"><span class="t5-offrow__chk"><span class="t5-check__box${on ? ' is-on' : ''}">${on ? icon('check') : ''}</span></span><i class="t5-gap-h8"></i>
      <span class="t5-offrow__t"><b>${esc(`${cd.code} · còn nợ ${formatVnd(cd.outstanding)}`)}</b><span class="t5-row"><span class="t5-grow t5-due t5-due--${due.kind}">${due.kind === 'overdue' ? icon('alert') : ''}${esc(due.text)}</span><b class="t5-offrow__amt${share === 0 ? ' is-zero' : ''}">Trừ ${esc(formatVndBare(share))}</b></span></span></div>`;
  };
  return `<p class="t5-entsub">${esc(c.order || 'DH-000130 · Nguyễn Văn Hùng')}</p>
    <div class="t5-enthero"><span class="t5-enthero__l">Khách được hưởng</span><b class="t5-enthero__amt">${esc(formatVnd(c.entitled))}</b><span class="t5-enthero__m">Chênh lệch −${esc(formatVnd(c.entitled))} · Hàng trả ${esc(formatVndBare(c.ret))} · Hàng đổi ${esc(formatVndBare(c.exc))}</span></div>
    <div class="t5-flow">${segs.length ? `<div class="t5-flow__bar">${segs.map(([k, val]) => `<span class="t5-flow__seg t5-flow__seg--${k}" style="flex:${Math.max(1, Math.floor(val / 1000))}"></span>`).join('')}</div>` : ''}
      ${plan.reduceOwnDebt > 0 ? `${gap(8)}${flowRow('own', 'Giảm nợ đơn này', formatVnd(plan.reduceOwnDebt), 'Trừ vào nợ của chính đơn này')}` : ''}
      ${plan.showOffsetBlock ? `${gap(8)}${flowRow('offset', 'Cấn trừ vào đơn khác', formatVnd(plan.offsetTotal))}` : ''}
      ${gap(8)}${flowRow('refund', 'Hoàn cho khách', formatVnd(plan.refund))}
      ${plan.refund > 0 ? `${gap(8)}<p class="t5-flow__method">Phương thức hoàn</p>${gap(8)}${segmented(['Tiền mặt', 'CK'], 0)}` : ''}</div>
    ${plan.showOffsetBlock ? `<h4 class="t5-rcsec">CẤN TRỪ VÀO ĐƠN KHÁC</h4><p class="t5-small t5-pad">Trừ vào nợ đơn khác của khách thay vì hoàn tiền.</p>${gap(8)}${c.candidates.map(offsetRow).join('')}` : ''}${gap(24)}`;
}

/**
 * VPageScaffold "Quyết toán đổi/trả" (←, tắt khi đang xác nhận). Thu thêm / không chênh lệch: đệm 16, dòng phụ bodySmall, [banner vàng + "Tải lại"],
 * khe 16, thẻ chính (viền nhạt đệm 16), khe 16, "Tóm tắt đổi/trả" thu gọn, khe 32. Hoàn (chênh lệch < 0): LUÔN là nhánh "Khách được hưởng"
 * (thẻ "Cần hoàn tiền" cũ không còn tới được). Thanh dưới (đệm 16 + gạch): [nhãn xám | số bold, khe 8 — chỉ khi không phải nhánh hưởng] + "Xác nhận đổi/trả".
 */
export function settlePage(state, v) {
  const page = (body, bottomBar = '', backDisabled = false) => scaffold({
    appbar: appBar('Quyết toán đổi/trả', { leading: `<button type="button" class="t5-appbar__back"${backDisabled ? ' disabled' : ''} aria-label="Quay lại">${icon('chevronLeft')}</button>` }), body, bottomBar, placeWidth: v.width, windowWidth: v.width,
  });
  if (state === 'loading') return page('<div class="t5-center"><span class="t5-spin t5-spin--material"></span></div>');
  if (state === 'blocked') return page(messagePanel('Không thể quyết toán', ['Đơn đang có phiếu đổi/trả chưa hoàn tất.'], { retry: '', warn: false }));
  if (state === 'error') return page(messagePanel('Không tải được quyết toán', ['Không quyết toán được phiếu đổi/trả. Vui lòng thử lại.'], { retry: 'Thử lại', warn: false }));
  const c = SETTLE[state] || SETTLE.collect;
  const plan = settlePlan(c);
  let body;
  if (plan) body = `<div class="t5-rscroll">${entitledBody(c, plan)}</div>`;
  else {
    const card = c.kind === 'zero' ? `${highlight('Không phát sinh chênh lệch', 0)}${gap(16)}<p class="t5-bodyp">Không cần thu thêm, hoàn tiền hoặc ghi nhận công nợ.</p>` : collectCard(c);
    body = `<div class="t5-rscroll"><div class="t5-pad16"><p class="t5-small">${esc(c.walkIn ? 'DH-000127 · Khách lẻ' : 'DH-000130 · Nguyễn Văn Hùng')}</p>
      ${c.banner ? `${gap(16)}${banner('warning', c.banner, '', { trailing: button('Tải lại', { variant: 'secondary', size: 'small' }) })}` : ''}
      ${gap(16)}<div class="t5-card t5-card--light t5-card--pad">${card}</div>${gap(16)}${planCard(c)}${gap(32)}</div></div>`;
  }
  const outstanding = c.kind === 'collect' ? Math.max(0, c.collect - c.settled) : 0;
  const canConfirm = !(outstanding > 0 && !c.due) && !c.confirming;
  const head = plan ? '' : `<div class="t5-sbar"><span>${c.kind === 'collect' ? 'Phải thu thêm' : 'Không chênh lệch'}</span><b>${esc(money(c.kind === 'collect' ? c.collect : 0))}</b></div>${gap(8)}`;
  const bar = `${head}<button type="button" class="t5-btn t5-btn--primary t5-btn--full t5-btn--lg"${canConfirm ? '' : ' disabled'}><span>${c.confirming ? 'Đang xử lý...' : 'Xác nhận đổi/trả'}</span></button>`;
  return page(body, bar, !!c.confirming);
}

/** Thanh dưới SG-13 = 16 + [22 + 8] + 52 + 16 + 1 (+ 34 iPhone); dùng đặt toast nếu cần. */

/**
 * showSalesReturnConfirmSettlementSheet: sheet không tiêu đề, VPagePadding: "Xác nhận đổi/trả?" H3 bold; khe 4; câu tóm tắt xám (hoặc gạch đầu dòng ở nhánh hưởng);
 * khe 24; "Xác nhận đổi/trả" xanh large TRÊN "Quay lại" (ngược thứ tự SG-10 / sheet bỏ thay đổi).
 */
export function confirmSheet(kind = 'collect') {
  let text;
  if (kind === 'offset') {
    const plan = settlePlan(SETTLE['refund-offset']);
    text = `<ul class="t5-bullets">${entitledLines(plan).map((l) => `<li>${esc(l)}</li>`).join('')}</ul>`;
  } else {
    text = `<p class="t5-body2">${esc(confirmationMessage({ collect: 23000 }))}</p>`;
  }
  return `<div class="t5-pad"><h2 class="t5-h3b">Xác nhận đổi/trả?</h2>${gap(4)}${text}${gap(24)}
    ${buttonLg('Xác nhận đổi/trả', { full: true })}${gap(8)}${buttonLg('Quay lại', { variant: 'secondary', full: true })}</div>`;
}

/** SalesReceivableChangedDialog (showDialog root, không đóng bằng chạm ngoài): Dialog M3 (lề 40 / 24, rộng ≤ 480) bo 16, đệm 20: câu làm tiêu đề H3 w700; khe 16; "Tải lại" canh phải. */
export const receivableChangedDialog = () => `<div class="sh-scrim sh-scrim--dialog t5-m3dialog-scrim"><section class="t5-m3dialog" role="alertdialog" aria-modal="true" aria-label="Công nợ thay đổi">
  <h2 class="t5-h3b">Công nợ của khách vừa thay đổi. Hãy tải lại quyết toán.</h2>${gap(16)}<div class="t5-m3dialog__actions">${button('Tải lại')}</div></section></div>`;

export const sheetOf = (body, opts) => bottomSheet(body, opts);
