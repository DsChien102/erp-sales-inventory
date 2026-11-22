// SG-03 Chọn đơn vị bán, SG-04 Chọn / tạo nhanh khách, SG-05 Điều chỉnh giá — đều là sheet đáy mở trên SG-02.
// Nguồn Dart (apps/erp/lib/features/sales/presentation/widgets/):
//   sales_product_unit_sheet.dart (SG-03);
//   sales_customer_select_sheet.dart, sales_customer_picker_{body, card, loading_state, search_bar, body_empty_state, body_no_result_state,
//   body_error_state}.dart, sales_customer_quick_create_sheet.dart (SG-04); bloc/shared/sales_customer_picker_cubit.dart (câu lỗi);
//   sales_compose_price_adjust_sheet.dart (SG-05).
import {
  banner, button, checkbox, emptyDesc, emptyMedia, emptyState, emptyTitle, esc, field, fieldDesc, fieldLabel, gap, icon, iconBox, input,
  keypadSheet, radio, radioLabel, searchBar, segmented, skeleton, suffixText, textArea,
} from './ds.js';
import { CUSTOMERS, PRODUCTS, customerSubtitle, money, moneyComma } from './data.js';

// ---------------------------------------------------------------- SG-03

/** Dòng phụ đơn vị: "<giá> · Tồn <N>" (thiếu tồn → chỉ giá). */
export const unitSubtitle = (u) => (u.stock == null ? money(u.price) : `${money(u.price)} · Tồn ${u.stock}`);

/**
 * SalesProductUnitSheet: showVBottomSheet, nội dung SizedBox cao = 1/3 chiều cao màn (844 → 281; 800 → 267), không theo số đơn vị.
 * VPagePadding: "Chọn đơn vị bán" H4 w700; khe 16; danh sách thẻ (khe 8) cuộn trong phần còn lại; khe 16; "Hủy" | "Xác nhận"; khe 8.
 * Thẻ: VCard đệm 16 (chọn → tone primary: nền surfaceBrand, viền borderBrand); ô icon 36 (hộp 20, bo 12; chọn → nền successBgPressed + textBrand,
 * chưa → surfaceAlt + textSecondary); khe 8; tên bodyDefault w700, khe 4, "giá · Tồn N" bodySmall; khe 8; radio bên phải. Không có tên sản phẩm trên sheet.
 */
export function unitSheet(selectedIdx = 0, product = PRODUCTS[3]) {
  const cards = product.units.map((u, i) => {
    const on = i === selectedIdx;
    return `<div class="t5-card t5-card--pad t5-ucard${on ? ' is-tone-primary' : ''}">${iconBox({ ic: 'inventory', size: 36, iconSize: 20, radius: 12, cls: on ? 't5-ibox--selbrand' : 't5-ibox--alt' })}
      <span class="t5-ucard__t"><b>${esc(u.name)}</b>${gap(4)}<span>${esc(unitSubtitle(u))}</span></span>${radio(on)}</div>`;
  }).join(gap(8));
  return `<div class="t5-fixsheet"><h2 class="t5-h4b">Chọn đơn vị bán</h2>${gap(16)}<div class="t5-fixsheet__list">${cards}</div>${gap(16)}
    <div class="t5-row2 t5-row2--8">${button('Hủy', { variant: 'secondary', full: true })}${button('Xác nhận', { full: true })}</div>${gap(8)}</div>`;
}
export const unitSheetHeight = (v) => v.height / 3;

// ---------------------------------------------------------------- SG-04

/**
 * SalesCustomerPickerCard: VCard đệm 12 (chọn → tone primary; ngừng hoạt động → enabled false, chữ + icon textMuted);
 * khe 4 + icon người 22 (không nền) + khe 12 + tên bodyDefault w700 (1 dòng) / khe 4 / phụ bodySmall (2 dòng) + khe 8 + radio.
 */
export function customerCard({ title, sub, selected = false, disabled = false }) {
  return `<div class="t5-card t5-ccard${selected ? ' is-tone-primary' : ''}${disabled ? ' is-disabled' : ''}"><i class="t5-gap-h4"></i><i class="t5-ccard__ic">${icon('user')}</i>
    <span class="t5-ccard__t"><b>${esc(title)}</b>${gap(4)}<span>${esc(sub)}</span></span>${radio(selected && !disabled)}</div>`;
}

function pickerBody(state) {
  if (state === 'loading') {
    return `<div class="t5-pad">${skeleton(20, { w: '120px', radius: 12 })}</div>${gap(8)}<div class="t5-cplist">${Array.from({ length: 5 }, () => skeleton(72, { radius: 12 })).join('')}</div>`;
  }
  if (state === 'empty') return emptyState({ header: [emptyMedia('users'), emptyTitle('Chưa có khách hàng'), emptyDesc('Tiếp tục với Khách lẻ hoặc tạo nhanh.')] });
  if (state === 'no-result') return emptyState({ header: [emptyMedia('search'), emptyTitle('Không tìm thấy khách hàng'), emptyDesc('Không có kết quả cho “xyz”.')] });
  if (state === 'error') return emptyState({ header: [emptyMedia('alert'), emptyTitle('Không thể tải khách hàng'), emptyDesc('Kiểm tra kết nối và thử lại.')], tone: 'danger' });
  const items = state === 'search' ? CUSTOMERS.filter((c) => /an|hùng/i.test(c.name)).slice(0, 2) : CUSTOMERS;
  const count = state === 'search' ? `${items.length} kết quả · “an”` : `${items.length} khách hàng`;
  const sel = state === 'selected' ? 'c2' : null;
  return `<p class="t5-pad t5-small">${esc(count)}</p>${gap(8)}<div class="t5-cplist">${items.map((c) => customerCard({ title: c.name, sub: customerSubtitle(c), selected: sel === c.id, disabled: !!c.inactive })).join('')}</div>`;
}

/**
 * showSalesCustomerSelectSheet: showVBottomSheet, nội dung cao 72% màn (844 → 608; 800 → 576). "Chọn khách hàng" H4 w700 (đệm 16); khe 16;
 * ô tìm "Tìm tên, SĐT hoặc mã KH"; khe 16; thẻ "Khách lẻ" / "Không phát sinh công nợ" (chọn khi đơn đang là Khách lẻ); khe 8;
 * thân (số đếm bodySmall + khe 8 + danh sách đệm 16 / 0 / 16 / 32, khe 8); "Tạo nhanh khách hàng" secondary đầy ngang (đệm dọc 12).
 * Chạm thẻ là chọn và đóng ngay (không có nút "Chọn").
 */
export function customerSheet(state = 'loaded') {
  const walkInSelected = state !== 'selected';
  const q = { search: 'an', 'no-result': 'xyz' }[state] || '';
  return `<div class="t5-fixsheet t5-fixsheet--nopad"><h2 class="t5-pad t5-h4b">Chọn khách hàng</h2>${gap(16)}
    <div class="t5-pad">${searchBar({ value: q, hint: 'Tìm tên, SĐT hoặc mã KH', clear: !!q })}</div>${gap(16)}
    <div class="t5-pad">${customerCard({ title: 'Khách lẻ', sub: 'Không phát sinh công nợ', selected: walkInSelected })}</div>${gap(8)}
    <div class="t5-fixsheet__list t5-fixsheet__list--col">${pickerBody(state)}</div>
    <div class="t5-pad t5-padv12">${button('Tạo nhanh khách hàng', { variant: 'secondary', full: true })}</div></div>`;
}
export const customerSheetHeight = (v) => v.height * 0.72;

/**
 * SalesCustomerQuickCreateSheet: showModalBottomSheet + VBottomSheet (tay kéo xám, cao ≤ 100% trừ vùng an toàn trên), co theo nội dung.
 * Hàng tiêu đề tự vẽ: "Tạo nhanh khách hàng" H3 w700 + nút × (VIconBox 40); câu "Chỉ nhập thông tin cần thiết để tiếp tục bán hàng." bodySmall;
 * khe 16; VDivider trong lề 16; khe 16; "Loại khách hàng *" (H4 + * đỏ) + khe 8 + radio "Cá nhân" (khe 24) "Tổ chức"; khe 8;
 * "Tên khách hàng *"; khe 8; "Số điện thoại *"; khe 8; "Mã số thuế" + "Không bắt buộc"; khe 8; "Địa chỉ" (3 dòng) + "Không bắt buộc";
 * đệm đáy 12; [banner lỗi]; "Tạo & chọn khách hàng" primary đầy ngang (đệm dọc 12). Ô MST hiện cả khi chọn "Cá nhân".
 */
export function quickCreateSheet(state = 'empty') {
  const org = state === 'org';
  const filled = state === 'filled' || state === 'submitting' || state === 'error';
  const invalid = state === 'invalid';
  const name = org ? 'Công ty TNHH Thú y Hoà Bình' : filled ? 'Phạm Minh Tuấn' : '';
  const phone = filled ? '0978123456' : org ? '0283 999 1234' : '';
  const tax = org ? '0315678901' : '';
  const nameCtl = field({ label: 'Tên khách hàng', required: true, control: input({ value: name, hint: org ? 'Ví dụ: Công ty Minh Phát' : 'Ví dụ: Nguyễn Văn Bình', invalid }), error: invalid ? 'Vui lòng nhập tên khách hàng' : null });
  const phoneCtl = field({ label: 'Số điện thoại', required: true, control: input({ value: phone, hint: 'Ví dụ: 0988123456', invalid }), error: invalid ? 'Vui lòng nhập số điện thoại' : null });
  const taxCtl = `<div class="t5-field">${fieldLabel('Mã số thuế')}${input({ value: tax, hint: 'Ví dụ: 0101234567' })}${fieldDesc('Không bắt buộc')}</div>`;
  const addrCtl = `<div class="t5-field">${fieldLabel('Địa chỉ')}${textArea({ value: org ? '25 Nguyễn Thị Minh Khai, Quận 1, TP. HCM' : '', hint: 'Ví dụ: 123 Đường ABC, Quận XYZ, TP. HCM', minLines: 3 })}${fieldDesc('Không bắt buộc')}</div>`;
  return `<div class="t5-qc">
    <div class="t5-pad t5-qc__head"><h2 class="t5-h3b">Tạo nhanh khách hàng</h2><span class="t5-iconbtn40">${iconBox({ ic: 'close', size: 40, iconSize: 20, cls: 't5-ibox--clear' })}</span></div>
    <p class="t5-pad t5-qc__lead">Chỉ nhập thông tin cần thiết để tiếp tục bán hàng.</p>${gap(16)}<div class="t5-pad"><hr class="t5-divider"></div>${gap(16)}
    <div class="t5-qc__scroll">
      <div class="t5-pad"><span class="t5-label">Loại khách hàng<i> *</i></span><div class="t5-radiorow">${radioLabel('Cá nhân', !org)}<i class="t5-gap-h24"></i>${radioLabel('Tổ chức', org)}</div></div>${gap(8)}
      <div class="t5-pad">${nameCtl}</div>${gap(8)}<div class="t5-pad">${phoneCtl}</div>${gap(8)}<div class="t5-pad">${taxCtl}</div>${gap(8)}<div class="t5-pad">${addrCtl}</div>${gap(12)}
    </div>
    ${state === 'error' ? `<div class="t5-pad t5-padv8">${banner('error', 'Không thể tạo khách hàng', 'Không thể kết nối để tạo khách hàng. Vui lòng thử lại.')}</div>` : ''}
    <div class="t5-pad t5-padv12">${button('Tạo & chọn khách hàng', { full: true, loading: state === 'submitting' })}</div></div>`;
}

/** Xác nhận bỏ nhập: showVBottomSheet tone danger (tay kéo đỏ); "Bỏ thay đổi chưa lưu?" H4 w700 đỏ; khe 8; câu bodySmall; khe 16; "Bỏ thay đổi" secondary đỏ; khe 8; "Tiếp tục nhập"; khe 8. */
export function quickDiscardSheet() {
  return `<div class="t5-sheetbody16"><h2 class="t5-h4b t5-text-danger">Bỏ thay đổi chưa lưu?</h2>${gap(8)}<p class="t5-small">Thông tin khách hàng đang nhập sẽ không được lưu.</p>${gap(16)}
    ${button('Bỏ thay đổi', { variant: 'secondary', full: true, cls: 't5-btn--sec-danger' })}${gap(8)}${button('Tiếp tục nhập', { variant: 'secondary', full: true })}${gap(8)}</div>`;
}

/** Trùng SĐT: "Có thể khách hàng đã tồn tại" H4 w700; khe 8; banner vàng "Trùng số điện thoại" + "<SĐT> trùng với <tên>."; khe 16; "Chọn khách hàng này" (primary); khe 8; "Vẫn tạo mới" (secondary). Không có khe cuối. */
export function duplicateSheet() {
  return `<div class="t5-sheetbody16"><h2 class="t5-h4b">Có thể khách hàng đã tồn tại</h2>${gap(8)}${banner('warning', 'Trùng số điện thoại', '0912345678 trùng với Nguyễn Văn Hùng.')}${gap(16)}
    ${button('Chọn khách hàng này', { full: true })}${gap(8)}${button('Vẫn tạo mới', { variant: 'secondary', full: true })}</div>`;
}

// ---------------------------------------------------------------- SG-05

/** _previewApplied: Đơn giá → nhập; Giảm tiền → niêm yết − nhập (≥ 0); Giảm % → làm tròn niêm yết × (100 − %) / 100 (0…100, ngoài → null). Giảm tính trên giá NIÊM YẾT, không trên giá đang áp. */
export function previewApplied(mode, input, catalog) {
  if (input == null) return null;
  if (mode === 'unit') return input;
  if (mode === 'amount') return Math.max(0, catalog - input);
  if (input < 0 || input > 100) return null;
  return Math.max(0, Math.round(catalog * (100 - input) / 100));
}

const ADJ = {
  default: { mode: 0, value: moneyComma(16000), applied: 16000 },
  amount: { mode: 1, value: '3,000', applied: 15000 },
  percent: { mode: 2, value: '10', applied: 16200 },
  below: { mode: 0, value: moneyComma(14000), applied: 14000, below: true },
  'save-private': { mode: 0, value: moneyComma(15500), applied: 15500, save: true },
  'walk-in': { mode: 0, value: moneyComma(16000), applied: 16000, walkIn: true },
};

/**
 * SalesComposePriceAdjustSheet: showVBottomSheet không tiêu đề, VPagePadding + cuộn. "Điều chỉnh giá" H3 w700; khe 8;
 * VCard (đệm 16): ảnh 48 (hộp 24 textMuted) + tên w700 + khe 4 + "Giá riêng áp dụng: <giá đang áp>/<đv>" + "Giá niêm yết: …/<đv>" (bodySmall) —
 * dòng đầu LUÔN ghi "Giá riêng áp dụng" kể cả khi đang là giá niêm yết; không có dòng giá sàn. Khe 8; "Cách điều chỉnh" bodyDefault w600; khe 8;
 * VSegmentedControl "Đơn giá | Giảm tiền | Giảm %"; khe 8; "Nhập điều chỉnh" + ô (chạm mở bàn phím số; tiền dấu phẩy + "đ", % + "%") + "Áp dụng cho 1 <đv>";
 * [khe 16 + banner vàng "Dưới giá sàn" "Giá sàn hiện tại: …/<đv>"]; VCheckbox "Lưu làm giá riêng" (Khách lẻ → mờ) + câu mô tả
 * (+ "Chọn khách hàng để lưu giá riêng."); khe 16; "Hủy" | "Áp dụng". Không xem trước giá sau giảm.
 */
export function priceAdjustSheet(state = 'default') {
  const a = ADJ[state] || ADJ.default;
  const suffix = a.mode === 2 ? '%' : 'đ';
  const ctl = `<span class="t5-input t5-input--num"><input type="text" readonly value="${esc(a.value)}">${suffixText(suffix)}</span>`;
  return `<div class="t5-sheetbody16"><h2 class="t5-h3b">Điều chỉnh giá</h2>${gap(8)}
    <div class="t5-card t5-card--pad t5-adj__prod">${iconBox({ ic: 'inventory', size: 48, iconSize: 24, radius: 8, cls: 't5-ibox--altmuted' })}<span class="t5-adj__t"><b>Pate cho mèo vị cá ngừ 85g</b>${gap(4)}<span>Giá riêng áp dụng: 16.000đ/Lon</span><span>Giá niêm yết: 18.000đ/Lon</span></span></div>${gap(8)}
    <p class="t5-adj__lbl">Cách điều chỉnh</p>${gap(8)}${segmented(['Đơn giá', 'Giảm tiền', 'Giảm %'], a.mode)}${gap(8)}
    <div class="t5-field">${fieldLabel('Nhập điều chỉnh')}${ctl}${fieldDesc('Áp dụng cho 1 Lon')}</div>
    ${a.below ? `${gap(16)}${banner('warning', 'Dưới giá sàn', 'Giá sàn hiện tại: 15.000đ/Lon')}` : ''}
    <div class="${a.walkIn ? 't5-dim' : ''}">${checkbox('Lưu làm giá riêng', !!a.save)}</div>
    <p class="t5-small">Lưu ngay làm giá riêng cho khách hàng này.</p>${a.walkIn ? '<p class="t5-small">Chọn khách hàng để lưu giá riêng.</p>' : ''}${gap(16)}
    <div class="t5-row2 t5-row2--8">${button('Hủy', { variant: 'secondary', full: true })}${button('Áp dụng', { full: true })}</div></div>`;
}

/** confirmBelowFloor (tone warning — tay kéo vẫn xám) / confirmOverwrite: tiêu đề H4 w700; khe 8; câu bodySmall; khe 16; nút xanh đầy ngang; khe 8; "Quay lại". */
export function priceConfirmSheet(kind) {
  const c = kind === 'overwrite'
    ? ['Ghi đè giá riêng hiện có?', 'Giá riêng đang áp dụng sẽ được cập nhật ngay.', 'Ghi đè và áp dụng']
    : ['Xác nhận giá dưới sàn?', 'Giá này cần quyền ghi đè và sẽ được lưu kèm cảnh báo.', 'Xác nhận áp dụng'];
  return `<div class="t5-sheetbody16"><h2 class="t5-h4b">${esc(c[0])}</h2>${gap(8)}<p class="t5-small">${esc(c[1])}</p>${gap(16)}
    ${button(c[2], { full: true })}${gap(8)}${button('Quay lại', { variant: 'secondary', full: true })}</div>`;
}

/** Chạm ô điều chỉnh → showVNumericKeypadSheet(money, "Nhập số tiền" / "Nhập số tiền giảm", "Đơn vị: VND"); % → quantity có thập phân "Nhập phần trăm", "Đơn vị: %". */
export function priceKeypad(kind = 'money') {
  if (kind === 'percent') return keypadSheet({ title: 'Nhập phần trăm', unit: 'Đơn vị: %', value: '10', decimal: true });
  return keypadSheet({ title: 'Nhập số tiền', unit: 'Đơn vị: VND', value: '16,000', money: true });
}
