// SG-06 Thanh toán (/sales/checkout) + sheet "Hoàn tất đơn?", bàn phím tiền, trang "không hợp lệ", toast.
// Nguồn Dart (apps/erp/lib/features/sales/presentation/):
//   pages/{sales_checkout_page, sales_checkout_invalid_entry_page}.dart, widgets/{sales_checkout_summary_card,
//   sales_checkout_payment_method_selector, sales_checkout_percent_row, sales_checkout_receivable_card, sales_checkout_finalize_sheets,
//   sales_amount_highlight_row}.dart, models/sales_order/sales_checkout_vm.dart, logic/sales_checkout_cubit.dart (selectPaymentMode / selectPercent).
// Key trong Dart dùng tiền tố "sg05" (đánh số cũ); TH-05 / CHECKLIST gọi màn này là SG-06.
import {
  appBar, button, datePicker, esc, gap, icon, keypadSheet, scaffold, segmented, suffixText,
} from './ds.js';
import { money } from './data.js';

/** _toDigitsText: nhóm nghìn bằng dấu CHẤM, không "đ" (ô tiền của màn này; ô SG-05 dùng dấu phẩy). */
export const digitsDot = (n) => String(n).replace(/\B(?=(\d{3})+(?!\d))/g, '.');

/**
 * SalesCheckoutVm: đã trả = mặt + chuyển; tiền thừa = đã trả − tổng (≥ 0); công nợ = tổng − đã trả (≥ 0);
 * Khách lẻ chỉ hoàn tất khi trả đúng bằng tổng; có công nợ thì phải có ngày hẹn.
 */
export function checkoutVm({ total, cash = 0, bank = 0, walkIn = false, mode = 'cash', due = null }) {
  const paid = cash + bank;
  return {
    total, cash, bank, walkIn, mode, due, paid,
    change: paid > total ? paid - total : 0,
    receivable: total > paid ? total - paid : 0,
    canEditCash: !(walkIn && mode === 'cash'),
    canEditBank: !(walkIn && mode === 'bank'),
    canFinalize: (!walkIn || paid === total) && (total <= paid || due != null),
  };
}

/** selectPaymentMode('mixed') khi cả hai ô đang 0: tiền mặt = min(tổng, 2.000.000), chuyển khoản = phần còn lại. Đổi từ tiền mặt / CK sang kết hợp giữ số cũ. */
export function mixedDefault(total) {
  const cash = total >= 2000000 ? 2000000 : total;
  return { cash, bank: total - cash };
}

/** SalesCheckoutPercentRow: chọn ô theo % đã trả: ≥ 75 → 100%, ≥ 25 → 50%, còn lại 0%. */
export const percentIndex = (p) => (p >= 75 ? 2 : p >= 25 ? 1 : 0);

const TOTAL = 441000;
const STATES = {
  cash: { mode: 'cash', cash: TOTAL },
  'walk-in': { mode: 'cash', cash: TOTAL, walkIn: true },
  bank: { mode: 'bank', bank: TOTAL, code: '' },
  'bank-code': { mode: 'bank', bank: TOTAL, code: 'FT26326123456' },
  mixed: { mode: 'mixed', cash: TOTAL, bank: 0 },
  'mixed-big': { mode: 'mixed', total: 4850000, ...mixedDefault(4850000) },
  'walk-in-bank': { mode: 'bank', bank: TOTAL, walkIn: true },
  debt: { mode: 'cash', cash: 220500 },
  'debt-dated': { mode: 'cash', cash: 220500, due: '30/11/2026' },
  'debt-zero': { mode: 'cash', cash: 0, due: '05/12/2026' },
  change: { mode: 'cash', cash: 500000 },
  prechecking: { mode: 'cash', cash: TOTAL, busy: true },
};

export function checkoutState(state) {
  const s = STATES[state] || STATES.cash;
  const vm = checkoutVm({ total: s.total || TOTAL, cash: s.cash || 0, bank: s.bank || 0, walkIn: !!s.walkIn, mode: s.mode, due: s.due || null });
  return { ...vm, code: s.code || '', busy: !!s.busy, customer: s.walkIn ? null : { name: 'Nguyễn Văn Hùng', phone: '0912345678' } };
}

/** VTextField có hậu tố chữ "đ" (không phải VMoneyField: chữ thường, không mono); chạm mở bàn phím số. */
const amountField = (value) => `<span class="t5-input"><input type="text" readonly value="${esc(value)}">${suffixText('đ')}</span>`;

/** Khách lẻ: 3 VButton — "0%" | "50%" (secondary, tắt) | "100%" (primary xanh), khe 4. Khách có hồ sơ: VSegmentedControl "0% | 50% | 100%". */
function percentRow(vm) {
  const pay = vm.mode === 'cash' ? vm.cash : vm.bank;
  const p = vm.total === 0 ? 100 : Math.round(pay * 100 / vm.total);
  if (!vm.walkIn) return segmented(['0%', '50%', '100%'], percentIndex(p));
  return `<div class="t5-row3">${button('0%', { variant: 'secondary', full: true, disabled: true })}${button('50%', { variant: 'secondary', full: true, disabled: true })}${button('100%', { full: true })}</div>`;
}

/**
 * Thẻ nhập tiền (VCard đệm 12): [Tiền mặt] nhãn w600, khe 4, ô, khe 4, gợi ý bodySmall, khe 8; [Chuyển khoản] tương tự;
 * hàng % (trừ Kết hợp); [Mã giao dịch (trừ Tiền mặt) + "Không bắt buộc."]; khe 8; "Tiền thừa" bodySmall | số mono w600 (luôn hiện, kể cả 0đ).
 */
function payCard(vm) {
  const mixed = vm.mode === 'mixed';
  let html = '';
  if (vm.mode === 'cash' || mixed) {
    const hint = mixed ? 'Nhập phần khách trả bằng tiền mặt.' : (vm.canEditCash ? 'Có thể nhập số tiền khác.' : 'Tự động bằng tổng đơn.');
    html += `<p class="t5-flabel">${mixed ? 'Tiền mặt' : 'Số tiền mặt'}</p>${gap(4)}${amountField(digitsDot(vm.cash))}${gap(4)}<p class="t5-small">${esc(hint)}</p>${gap(8)}`;
  }
  if (vm.mode === 'bank' || mixed) {
    const hint = mixed ? 'Nhập phần khách trả bằng chuyển khoản.' : (vm.canEditBank ? 'Có thể nhập số tiền khác.' : 'Tự động bằng tổng đơn.');
    html += `<p class="t5-flabel">${mixed ? 'Chuyển khoản' : 'Số tiền chuyển khoản'}</p>${gap(4)}${amountField(digitsDot(vm.bank))}${gap(4)}<p class="t5-small">${esc(hint)}</p>${gap(8)}`;
  }
  if (!mixed) html += percentRow(vm);
  if (vm.mode !== 'cash') {
    html += `${mixed ? '' : gap(8)}<p class="t5-flabel">Mã giao dịch</p>${gap(4)}<span class="t5-input"><input type="text" value="${esc(vm.code || '')}" placeholder="Nhập mã giao dịch"></span>${gap(4)}<p class="t5-small">Không bắt buộc.</p>${gap(8)}`;
  }
  html += `${gap(8)}<div class="t5-chrow"><span>Tiền thừa</span><b>${esc(money(vm.change))}</b></div>`;
  return `<div class="t5-card t5-card--p12">${html}</div>`;
}

/**
 * SalesCheckoutReceivableCard (VCard đệm 12): SalesAmountHighlightRow "Công nợ phát sinh" — tone primary (nền xanh nhạt, chữ xanh) kể cả khi > 0;
 * > 0 → khe 16 + VDatePicker "Ngày hẹn thanh toán *" ("Chọn ngày hẹn") + khe 4 + "Bắt buộc khi phát sinh công nợ."; = 0 → khe 4 + "Không phát sinh công nợ."
 */
function receivableCard(vm) {
  const tail = vm.receivable > 0
    ? `${gap(16)}${datePicker({ label: 'Ngày hẹn thanh toán', required: true, hint: 'Chọn ngày hẹn', value: vm.due || '' })}${gap(4)}<p class="t5-small">Bắt buộc khi phát sinh công nợ.</p>`
    : `${gap(4)}<p class="t5-small">Không phát sinh công nợ.</p>`;
  return `<div class="t5-card t5-card--p12"><div class="t5-hl t5-hl--label"><span>Công nợ phát sinh</span><b>${esc(money(vm.receivable))}</b></div>${tail}</div>`;
}

/** SalesCheckoutSummaryCard: chỉ thẻ khách (khe 4 + icon người 20 textSecondary + khe 12 + tên w700 / khe 4 / SĐT bodySmall). Không có danh sách hàng, không có tổng trong thân. */
function customerCard(c) {
  return `<div class="t5-card t5-card--p12 t5-cocust"><i class="t5-gap-h4"></i><i class="t5-cocust__ic">${icon('user')}</i><span class="t5-cocust__t"><b>${esc(c ? c.name : 'Khách lẻ')}</b>${gap(4)}<span>${esc(c ? c.phone : 'Không bắt buộc thông tin')}</span></span></div>`;
}

/**
 * VPageScaffold "Thanh toán" (← 48). Thân ListView đệm 16 / 12 / 16 / 16: thẻ khách; khe 16; "Phương thức" H4 w700 + khe 8 + segmented
 * "Tiền mặt | Chuyển khoản | Kết hợp"; khe 8; thẻ nhập tiền; khe 16; thẻ công nợ.
 * bottomBar (đệm dọc 12): "Khách phải trả" bodyDefault (chữ ĐEN, SG-02 xám) | tổng mono w700; khe 8; "Tiếp tục" xanh đầy ngang (đang kiểm → vòng xoay).
 */
export function checkoutPage(state, v, { toastHtml = '' } = {}) {
  const vm = checkoutState(state);
  const body = `<div class="t5-coscroll">${customerCard(vm.customer)}${gap(16)}
    <h3 class="t5-h4b">Phương thức</h3>${gap(8)}${segmented(['Tiền mặt', 'Chuyển khoản', 'Kết hợp'], { cash: 0, bank: 1, mixed: 2 }[vm.mode])}${gap(8)}
    ${payCard(vm)}${gap(16)}${receivableCard(vm)}</div>${toastHtml}`;
  const bar = `<div class="t5-sumbar"><div class="t5-sumbar__top t5-sumbar__top--dark"><span>Khách phải trả</span><b>${esc(money(vm.total))}</b></div>${gap(8)}
    ${button('Tiếp tục', { full: true, loading: vm.busy, disabled: !vm.canFinalize })}</div>`;
  return scaffold({ appbar: appBar('Thanh toán', { back: true }), body, bottomBar: bar, placeWidth: v.width, windowWidth: v.width, cls: 't5-page--compose' });
}

/** Mở thẳng /sales/checkout không kèm đơn: câu bodyDefault trong lề 16 (không icon, không hộp) + khe 16 + "Quay lại tạo đơn" xanh đầy ngang. */
export function checkoutInvalidPage(v) {
  const body = `<div class="t5-pad">${gap(0)}<p class="t5-bodyp">Không thể mở thanh toán từ liên kết này. Hãy quay lại tạo đơn và chọn Thanh toán từ đơn đang soạn.</p>${gap(16)}${button('Quay lại tạo đơn', { full: true })}</div>`;
  return scaffold({ appbar: appBar('Thanh toán', { back: true }), body, placeWidth: v.width, windowWidth: v.width });
}

/** showSalesCheckoutFinalizeSheet: showVBottomSheet không tiêu đề; "Hoàn tất đơn?" H4 w700; khe 8; câu bodySmall; khe 16; "Hoàn tất đơn" xanh; khe 8; "Quay lại"; khe 8. Không nhắc lại số tiền / công nợ. */
export function finalizeSheet() {
  return `<div class="t5-sheetbody16"><h2 class="t5-h4b">Hoàn tất đơn?</h2>${gap(8)}
    <p class="t5-small">Hệ thống sẽ ghi nhận các khoản đã thu, công nợ phát sinh nếu có và hoàn tất đơn. Vui lòng kiểm tra lại trước khi xác nhận.</p>${gap(16)}
    ${button('Hoàn tất đơn', { full: true })}${gap(8)}${button('Quay lại', { variant: 'secondary', full: true })}${gap(8)}</div>`;
}

/** Chạm ô tiền → showVNumericKeypadSheet(money, "Nhập số tiền mặt" / "Nhập số tiền chuyển khoản", "Đơn vị: VND", tone success). */
export const cashKeypad = () => keypadSheet({ title: 'Nhập số tiền mặt', unit: 'Đơn vị: VND', value: '441,000', money: true });
