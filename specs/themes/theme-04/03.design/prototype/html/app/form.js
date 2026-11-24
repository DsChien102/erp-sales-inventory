// PR-04 Tạo / sửa giá riêng (+ sheet "Đến ngày", "Tự động ghi đè giá trùng?", "Rời khỏi màn hình?", "Lưu thay đổi?"),
// PR-05 Chọn khách hàng, PR-06 Chọn sản phẩm, PR-07 Chọn đơn vị bán.
// Nguồn Flutter (apps/erp/lib/features/pricing/):
//   presentation/pages/{pricing_form_page, pricing_pick_customer_page, pricing_pick_product_page, pricing_pick_unit_page}.dart
//   presentation/widgets/{price_rule_form_body, price_rule_form_edit_header, price_rule_form_readiness_summary, price_rule_price_field,
//     price_rule_warning_banner, price_rule_form_blocking_states, price_rule_overwrite_confirm_dialog, price_rule_leave_form_dialog,
//     price_rule_save_confirm_sheet, pricing_selectable_entity_card}.dart
//   logic/{price_rule_form_cubit, price_rule_form_state}.dart
// Mọi route /pricing/* nằm ngoài khung: web không thanh bên, app bar hết ngang, thân cột 720.
import {
  appBar, avatar, banner, icon, button, card, datePicker, esc, field, iconBox, moneyField, pickerField, radio,
  scaffold, searchBar, section, skeleton, textAreaCounter, textAreaPlain, toast,
} from './ds.js';
import { legacyEmpty } from './list.js';
import { CUSTOMERS, PRODUCTS, UNITS, dong, money } from './data.js';

// ---------------------------------------------------------------- hàm thuần (đối chiếu Dart)

/**
 * PriceRuleFormReadinessSummary._formatDiffWithPercent: dấu "+" chỉ khi dương; số tiền lấy trị tuyệt đối → chênh âm MẤT dấu trừ ở phần tiền,
 * chỉ phần % còn "-" (toStringAsFixed(1), "." → ","). base 0 → chỉ tiền.
 */
export function diffWithPercent(diff, base) {
  const label = `${diff > 0 ? '+' : ''}${money(Math.abs(diff))}`;
  if (base === 0) return label;
  const pct = (diff / base) * 100;
  return `${label} (${pct > 0 ? '+' : ''}${pct.toFixed(1).replace('.', ',')}%)`;
}

/** PriceRuleFormEditing.showReadinessSummary: có giá > 0 và (có giá hiện tại hoặc có giá sàn không ẩn). */
export const showSummary = (f) => f.price != null && f.price > 0 && (f.list != null || (!f.floorHidden && f.floor != null));
/** isBelowFloor. */
export const isBelowFloor = (f) => !f.floorHidden && f.floor != null && f.price != null && f.price < f.floor;
/** isValid: đủ khách, sản phẩm, đơn vị, giá > 0, từ ngày. */
export const isValid = (f) => !!(f.customer && f.product && f.unit && f.price > 0 && f.from);

/** _ComparisonRow: giá trị dài hơn 20 ký tự → nhãn và giá trị xếp 2 dòng (giá trị canh phải). */
export const isLongValue = (v) => v.length > 20;

// ---------------------------------------------------------------- trạng thái

const EMPTY = { mode: 'create', customer: '', product: '', unit: '', price: null, list: null, floor: null, floorHidden: true, from: '', to: '', note: '', conflict: false, conflictId: null, submitting: false };
const FILLED = { ...EMPTY, customer: 'Công ty TNHH Thú y An Phát', product: 'Amoxicillin 500mg', unit: 'Hộp', price: 105000, list: 115741, floor: 90741, floorHidden: false, from: '22/11/2026', note: 'Theo hợp đồng đại lý Q4' };
const EDIT = {
  ...FILLED, mode: 'edit', customerId: '7c9e6679-7425-40de-944b-e07fc1f90ae7', price: 105000, list: 115741, floor: 90741, from: '01/07/2026', note: 'Theo hợp đồng đại lý Q4',
  updatedBy: 'Nguyễn Thị Lan', updatedAt: '05/10/2026 · 10:21',
};

export function formState(state) {
  switch (state) {
    case 'new': return EMPTY;
    case 'customer-picked': return { ...EMPTY, customer: 'Công ty TNHH Thú y An Phát', product: 'Amoxicillin 500mg', list: 115741, from: '22/11/2026' };
    case 'filled': return FILLED;
    case 'price-only-list': return { ...FILLED, unit: '', floor: null, floorHidden: true, price: 105000 };
    case 'below-floor': return { ...FILLED, price: 85000 };
    case 'above-list': return { ...FILLED, price: 135000 };
    case 'conflict': return { ...FILLED, conflictId: 'r1' };
    case 'submitting': return { ...FILLED, submitting: true };
    case 'save-error': return FILLED;
    case 'note-long': return { ...FILLED, to: '31/12/2026', note: 'Áp dụng theo hợp đồng đại lý quý 4/2026, số HĐ 12/2026/AP-VET, giao hàng tại kho Thủ Đức.' };
    case 'edit': return EDIT;
    case 'edit-dates': return { ...EDIT, price: 99000, to: '31/12/2026', conflict: true };
    case 'edit-below': return { ...EDIT, price: 88000 };
    default: return EMPTY;
  }
}

// ---------------------------------------------------------------- PR-04

/** Nút ← của form: VIconBox(arrowBack) 40 nền trong suốt trong ô leading 56 (màn chọn dùng ‹ chevronLeft của VAppBar). */
const backArrow = () => iconBox({ ic: 'arrowLeft', size: 40, iconSize: 20, cls: 't4-ibox--clear t4-backbox' });

/** PriceRuleFormReadinessSummary: VCard nền successBg viền success, đệm 16; hàng: nhãn bodySmall textPrimary | giá trị monoNumeric; mỗi hàng đệm dưới 8. */
function summaryCard(f) {
  const floor = f.floorHidden ? null : f.floor;
  const rows = [];
  if (f.list != null) rows.push(['Giá hiện tại', money(f.list), '']);
  if (floor != null) rows.push(['Giá sàn', money(floor), '']);
  if (f.price != null && f.list != null) rows.push(['So với giá hiện tại', diffWithPercent(f.price - f.list, f.list), f.price < f.list ? 'danger' : 'success']);
  if (f.price != null && floor != null) rows.push(['So với giá sàn', diffWithPercent(f.price - floor, floor), f.price < floor ? 'danger' : 'success']);
  return `<div class="t4-summary">${rows.map(([l, v, tone]) => `<div class="t4-cmp${isLongValue(v) ? ' is-long' : ''}"><span>${esc(l)}</span><b class="${tone ? `is-${tone}` : ''}">${esc(v)}</b></div>`).join('')}</div>`;
}

/** PriceRuleFormIdentityCard (sửa): VCard đệm 12; avatar 40 (chữ 16) + tên w600 + **customerId (UUID)** bodySmall; khe 16; "Sản phẩm" | giá trị, khe 8 (+4), "Đơn vị bán" | giá trị. */
function identityCard(f) {
  return card(`<div class="t4-idcard">
    <div class="t4-idcard__head">${avatar(f.customer).replace('font-size:14px', 'font-size:16px')}<div><b>${esc(f.customer)}</b><span>${esc(f.customerId)}</span></div></div>
    <div class="t4-kv"><span>Sản phẩm</span><b>${esc(f.product)}</b></div>
    <div class="t4-kv"><span>Đơn vị bán</span><b>${esc(f.unit)}</b></div>
  </div>`, { pad: false, cls: 't4-idcard-wrap' });
}

/** PriceRuleFormLastUpdatedCard: VCard nền surfaceAlt đệm 12; VIconBox info 36 (nền surface) + "Cập nhật gần nhất" w700 / "Cập nhật bởi: …" / thời gian bodySmallMono. */
function lastUpdatedCard(f) {
  return card(`<div class="t4-lastupd">${iconBox({ ic: 'info', size: 36, iconSize: 18, cls: 't4-ibox--muted' })}<div><b>Cập nhật gần nhất</b><span>Cập nhật bởi: ${esc(f.updatedBy)}</span><span class="t4-mono">${esc(f.updatedAt)}</span></div></div>`, { pad: false, cls: 't4-lastupd-wrap' });
}

/** _FormWarnings: dưới sàn (VBanner warning) rồi ghi đè (VBanner info + "Xem giá riêng hiện có >" labelSmall primary); khe 16 giữa và sau. */
function warnings(f) {
  const out = [];
  if (isBelowFloor(f)) out.push(banner('warning', 'Giá riêng thấp hơn giá sàn', 'Bạn vẫn có thể lưu nếu có quyền ghi đè giá sàn.'));
  if (f.conflict || f.conflictId) {
    const link = f.conflictId ? '<button type="button" class="t4-bannerlink">Xem giá riêng hiện có &gt;</button>' : '';
    out.push(banner('info', 'Lưu ý tự động ghi đè giá trùng', 'Khoảng thời gian hiệu lực mới bị trùng với giá riêng đang áp dụng khác. Khi lưu, hệ thống sẽ tự động ghi đè giá riêng cũ.', { footer: link }));
  }
  return out.length ? `<div class="t4-warnings">${out.join('')}</div>` : '';
}

function formBody(f) {
  const edit = f.mode === 'edit';
  const unitEnabled = !!f.product && !edit;
  const apply = edit
    ? section('Thông tin áp dụng', identityCard(f))
    : section('Thông tin áp dụng', `<div class="t4-stack16">
        ${pickerField({ label: 'Khách hàng', required: true, value: f.customer, hint: 'Tìm và chọn khách hàng...' })}
        ${pickerField({ label: 'Sản phẩm', required: true, value: f.product, hint: 'Tìm và chọn sản phẩm...' })}
        ${pickerField({ label: 'Đơn vị bán', required: true, value: f.unit, hint: f.product ? 'Chọn đơn vị bán...' : 'Chọn sản phẩm trước', disabled: !unitEnabled })}
      </div>`);
  const priceText = f.price != null ? String(f.price).replace(/\B(?=(\d{3})+(?!\d))/g, ',') : '';
  return `<div class="t4-formscroll">
    ${warnings(f)}
    ${apply}
    <i class="t4-gap" style="height:24px"></i>
    ${section('Mức giá áp dụng', moneyField({ label: 'Giá riêng cho khách', required: true, value: priceText }))}
    ${showSummary(f) ? `<i class="t4-gap" style="height:24px"></i>${summaryCard(f)}` : ''}
    <i class="t4-gap" style="height:24px"></i>
    ${section('Thời gian hiệu lực', `<div class="t4-stack16">${datePicker({ label: 'Từ ngày', required: true, value: f.from, hint: 'Chọn ngày' })}${datePicker({ label: 'Đến ngày', value: f.to, hint: 'Không giới hạn' })}</div>`)}
    <i class="t4-gap" style="height:16px"></i>
    ${field({ label: 'Ghi chú', control: textAreaCounter({ value: f.note, lines: 2, max: 500 }) })}
    ${edit ? `<i class="t4-gap" style="height:24px"></i>${lastUpdatedCard(f)}` : ''}
    <i class="t4-gap" style="height:32px"></i>
  </div>`;
}

/** _BottomBar: SafeArea + đệm 16: "Hủy" (secondary) | khe 16 | "Lưu" / "Đang lưu..." (tắt khi chưa hợp lệ hoặc đang lưu). */
function formBottomBar(f) {
  return `<div class="t4-row2">${button('Hủy', { variant: 'secondary', full: true, disabled: f.submitting })}${button(f.submitting ? 'Đang lưu...' : 'Lưu', { full: true, disabled: f.submitting || !isValid(f) })}</div>`;
}

export function formPage(f, v, { toastHtml = '' } = {}) {
  const edit = f.mode === 'edit';
  const page = scaffold({
    appbar: appBar(edit ? 'Sửa giá riêng' : 'Tạo giá riêng', { subtitle: edit ? f.customer : '', leading: backArrow() }),
    body: formBody(f),
    bottomBar: formBottomBar(f),
    placeWidth: v.width, windowWidth: v.width, cls: 't4-formpage',
  });
  return toastHtml ? page.replace(/<\/div>\s*$/, `${toastHtml}</div>`) : page;
}

/** F-08: PriceRuleFormNoPermissionState (VEmptyState tone primary, khoá) — nút ‹ mặc định của VAppBar. */
export function formNoPermission(v, edit) {
  return scaffold({
    appbar: appBar(edit ? 'Sửa giá riêng' : 'Tạo giá riêng', { back: true }),
    body: legacyEmpty({ ic: 'lock', tone: 'primary', title: edit ? 'Bạn không có quyền sửa giá riêng' : 'Bạn không có quyền tạo giá riêng', desc: edit ? 'Liên hệ quản trị viên nếu bạn cần quyền chỉnh sửa giá riêng.' : 'Liên hệ quản trị viên nếu bạn cần quyền tạo giá riêng.', action: 'Đóng' }),
    placeWidth: v.width, windowWidth: v.width,
  });
}

/** F-07: PriceRuleFormStateChangedState thay cả màn (không phải banner): VEmptyState tone warning, refresh, "Tải lại". */
export function formStateChanged(v) {
  return scaffold({
    appbar: appBar('Sửa giá riêng', { leading: backArrow() }),
    body: legacyEmpty({ ic: 'refresh', tone: 'warning', title: 'Giá riêng đã được cập nhật', desc: 'Giá riêng này vừa được cập nhật bởi người khác. Vui lòng tải lại trước khi sửa.', action: 'Tải lại' }),
    placeWidth: v.width, windowWidth: v.width,
  });
}

// ---------------------------------------------------------------- sheet của form (showVBottomSheet)

/** _pickEffectiveTo: không tiêu đề sheet; đệm 16/8/16/16: "Đến ngày" H4 canh giữa, khe 16, "Chọn ngày cụ thể" (secondary), khe 8, "Không giới hạn" (primary). */
export const effectiveToSheet = () => `<div class="t4-sheetpad t4-sheetpad--top8">
  <p class="t4-h4 t4-center">Đến ngày</p><i class="t4-gap" style="height:16px"></i>
  ${button('Chọn ngày cụ thể', { variant: 'secondary', full: true })}<i class="t4-gap" style="height:8px"></i>${button('Không giới hạn', { full: true })}
</div>`;

/** Hàng tiêu đề tự vẽ trong sheet: H3 w700 + nút × 20 textSecondary (InkWell đệm 4 → vùng chạm 28). */
const sheetTitleRow = (title) => `<div class="t4-sheethead"><h2>${esc(title)}</h2><button type="button" class="t4-xbtn" aria-label="Đóng">${icon('close')}</button></div>`;

/** showPriceRuleOverwriteConfirmDialog: tên "Dialog" nhưng là bottom sheet, không tiêu đề sheet; tự vẽ hàng tiêu đề + ×. */
export const overwriteSheet = () => `<div class="t4-sheetpad t4-sheetpad--top8">
  ${sheetTitleRow('Tự động ghi đè giá trùng?')}<i class="t4-gap" style="height:4px"></i>
  <p class="t4-body2">Bạn có chắc muốn tự động ghi đè giá riêng này?</p><i class="t4-gap" style="height:16px"></i>
  ${banner('info', 'Lưu ý tự động ghi đè', 'Tạo giá riêng này sẽ tự động ghi đè giá riêng đang áp dụng trùng khoảng thời gian (nếu có).')}
  <i class="t4-gap" style="height:24px"></i>
  <div class="t4-row2">${button('Hủy', { variant: 'secondary', full: true })}${button('Ghi đè & Lưu', { full: true })}</div>
</div>`;

/** showPriceRuleLeaveFormDialog: sheet có tiêu đề "Rời khỏi màn hình?" + gạch; đệm 16/12/16/16; câu xám; khe 24; "Ở lại chỉnh sửa" | khe 12 | "Rời khỏi" (đỏ). */
export const leaveSheet = () => `<div class="t4-sheetpad t4-sheetpad--top12">
  <p class="t4-body2">Những thay đổi chưa lưu sẽ bị mất.</p><i class="t4-gap" style="height:24px"></i>
  <div class="t4-row2 t4-row2--12">${button('Ở lại chỉnh sửa', { variant: 'secondary', full: true })}${button('Rời khỏi', { tone: 'danger', full: true })}</div>
</div>`;

/**
 * PriceRuleSaveConfirmSheet: không tiêu đề sheet; hàng tiêu đề tự vẽ + câu xám; VCard đệm 16 các hàng "Nhãn:" | cũ → mới (mũi tên + giá trị mới xanh w600);
 * hàng "Từ ngày:" chỉ khi đổi; "Đến ngày:" luôn có (kể cả không đổi: "Không giới hạn → Không giới hạn"). Đổi ngày → VBanner info.
 * Ô lý do (VTextArea 3 dòng) + bộ đếm tự vẽ "n/200" caption muted; "Hủy" | "Lưu thay đổi".
 */
export function saveConfirmSheet({ oldPrice, newPrice, oldTo, newTo, reason = '' }) {
  const row = (l, a, b) => `<div class="t4-chg"><span>${esc(l)}</span><span class="t4-chg__val"><span>${esc(a)}</span><b>→</b><b>${esc(b)}</b></span></div>`;
  const dateChanged = oldTo !== newTo;
  return `<div class="t4-sheetpad t4-sheetpad--top8">
    ${sheetTitleRow('Lưu thay đổi?')}<i class="t4-gap" style="height:4px"></i>
    <p class="t4-body2">Bạn có chắc muốn cập nhật giá riêng này?</p><i class="t4-gap" style="height:16px"></i>
    ${card(`<div class="t4-stack8">${row('Giá riêng:', oldPrice, newPrice)}${row('Đến ngày:', oldTo, newTo)}</div>`)}
    ${dateChanged ? `<i class="t4-gap" style="height:16px"></i>${banner('info', 'Lưu ý tự động ghi đè', 'Cập nhật thời gian hiệu lực này sẽ tự động ghi đè giá riêng đang áp dụng trùng khoảng thời gian (nếu có).')}` : ''}
    <i class="t4-gap" style="height:16px"></i>
    ${field({ label: 'Lý do thay đổi (không bắt buộc)', control: textAreaPlain({ value: reason, hint: 'Nhập lý do thay đổi...', lines: 3 }) })}
    <i class="t4-gap" style="height:4px"></i><p class="t4-count">${reason.length}/200</p>
    <i class="t4-gap" style="height:24px"></i>
    <div class="t4-row2">${button('Hủy', { variant: 'secondary', full: true })}${button('Lưu thay đổi', { full: true })}</div>
  </div>`;
}

/**
 * VToast lỗi khi lưu (chỉ hiện message). bottomBar của VPageScaffold là bottomNavigationBar → SnackBar nổi NGAY TRÊN hàng "Hủy | Lưu"
 * (thanh cao 1 + 16 + 44 + 16 = 77, iPhone thêm 34 vùng an toàn).
 */
export const saveErrorToast = (v) => toast('danger', 'Lỗi', 'Không thể lưu giá riêng. Vui lòng thử lại.', { bottom: 14 + 77 + (v.device === 'iphone' ? 34 : 0) });

// ---------------------------------------------------------------- PR-05 / 06 / 07

/**
 * PricingSelectableEntityCard: VCard đệm 16; chưa chọn → viền borderStrong + bóng e1; chọn → nền successBg, viền success, bóng e2.
 * avatar: leading + khe 8 + chữ + khe 8 + radio; listRow: radio + khe 8 + chữ. Chữ: tiêu đề w600 1 dòng, phụ bodySmall 2 dòng, chú thích bodySmall 1 dòng.
 */
function entityCard({ leading = '', title, sub = '', caption = '', selected = false, listRow = false }) {
  const text = `<div class="t4-ecard__text"><b>${esc(title)}</b>${sub ? `<span>${sub}</span>` : ''}${caption ? `<span>${esc(caption)}</span>` : ''}</div>`;
  const inner = listRow ? `${radio(selected)}${text}` : `${leading}${text}${radio(selected)}`;
  return `<div class="t4-ecard${selected ? ' is-selected' : ''}${listRow ? ' t4-ecard--row' : ''}">${inner}</div>`;
}

/** PricingPickInitialsLeading: VIconBox 52 bo 16 vuông tròn góc, tone success, chữ tắt 13. */
const initialsBox = (name) => {
  const w = name.trim().split(/\s+/);
  const ini = (w.length === 1 ? w[0][0] : w[0][0] + w[w.length - 1][0]).toUpperCase();
  return iconBox({ label: ini, size: 52, iconSize: 13, radius: 16, cls: 't4-ibox--success' });
};

/** Khung tải chung 3 màn chọn: đệm 16, 3 VSkeleton ∞ × 72 bo 4, khe 8 (không phải khung thẻ). */
const pickSkeleton = () => `<div class="t4-pickskel">${skeleton(72, { radius: 4 }).repeat(3)}</div>`;

function pickPage(v, { title, search = null, body, canConfirm }) {
  const top = search ? `<div class="t4-picksearch">${searchBar(search)}</div>` : '';
  return scaffold({
    appbar: appBar(title, { back: true }),
    body: `<div class="t4-list">${top}${body}</div>`,
    bottomBar: button('Chọn', { full: true, disabled: !canConfirm }),
    placeWidth: v.width, windowWidth: v.width, cls: 't4-pickpage',
  });
}

const pickError = (msg) => legacyEmpty({ ic: 'error', title: 'Đã xảy ra lỗi', desc: msg, action: 'Thử lại' });

export function customerPick(state, v) {
  const sel = state === 'selected' ? 'c1' : null;
  const query = state === 'empty' ? 'hoàng long' : state === 'selected' ? '' : '';
  let body;
  if (state === 'loading') body = pickSkeleton();
  else if (state === 'error') body = pickError('Không tải được danh sách khách hàng.');
  else if (state === 'empty') body = legacyEmpty({ ic: 'user', title: 'Không tìm thấy khách hàng', desc: 'Thử từ khóa khác hoặc kiểm tra chính tả.' });
  else body = `<div class="t4-listscroll">${CUSTOMERS.map((c) => entityCard({ leading: initialsBox(c.name), title: c.name, sub: esc(c.sub), caption: c.role, selected: c.id === sel })).join('')}</div>`;
  return pickPage(v, { title: 'Chọn khách hàng', search: { value: query, hint: 'Tìm tên hoặc số điện thoại khách hàng...', clear: !!query, focused: true }, body, canConfirm: !!sel });
}

export function productPick(state, v) {
  const sel = state === 'selected' ? 'sp1' : null;
  const query = state === 'empty' ? 'xyz' : '';
  let body;
  if (state === 'loading') body = pickSkeleton();
  else if (state === 'error') body = pickError('Không tải được danh sách sản phẩm.');
  else if (state === 'empty') body = legacyEmpty({ ic: 'inventory', title: 'Không tìm thấy sản phẩm', desc: 'Thử từ khóa khác hoặc kiểm tra chính tả.' });
  else {
    body = `<div class="t4-listscroll">${PRODUCTS.map((p) => entityCard({
      leading: iconBox({ ic: 'inventory', size: 52, iconSize: 20, radius: 16 }),
      title: p.name,
      sub: p.listBeforeVat == null ? '' : `Giá hiện tại: <i class="t4-mono">${dong(p.listBeforeVat)}</i>`,
      caption: p.baseUnit ? `Đơn vị cơ bản: ${p.baseUnit}` : '',
      selected: p.id === sel,
    })).join('')}</div>`;
  }
  return pickPage(v, { title: 'Chọn sản phẩm', search: { value: query, hint: 'Tìm tên sản phẩm...', clear: !!query, focused: true }, body, canConfirm: !!sel });
}

/** _priceSubtitle: "Giá hiện tại: X • Giá sàn: Y"; thiếu giá hiện tại → "--"; sàn ẩn / thiếu → bỏ phần sàn; thiếu cả hai → không có dòng. */
export function unitSubtitle(u) {
  const showFloor = !u.floorHidden && u.floor != null;
  if (u.list == null && !showFloor) return '';
  return `Giá hiện tại: <i class="t4-mono">${u.list == null ? '--' : dong(u.list)}</i>${showFloor ? ` • Giá sàn: <i class="t4-mono">${dong(u.floor)}</i>` : ''}`;
}

export function unitPick(state, v) {
  const sel = state === 'selected' ? 'u1' : null;
  let body;
  if (state === 'loading') body = pickSkeleton();
  else if (state === 'error') body = pickError('Không tải được danh sách đơn vị bán.');
  else if (state === 'empty') body = legacyEmpty({ ic: 'ruler', title: 'Chưa có đơn vị bán', desc: 'Sản phẩm này chưa được cấu hình đơn vị bán.' });
  else body = `<div class="t4-listscroll t4-listscroll--top8">${UNITS.map((u) => entityCard({ title: u.name, sub: unitSubtitle(u), caption: u.base ? 'Đơn vị cơ bản' : '', selected: u.id === sel, listRow: true })).join('')}</div>`;
  return pickPage(v, { title: 'Chọn đơn vị bán', body, canConfirm: !!sel });
}

