// SP-03 Tạo nhanh sản phẩm (/products/items/new, ngoài khung: web không có thanh bên) + sheet "Thêm ảnh sản phẩm".
// Nguồn Flutter (apps/erp/lib/features/catalog/):
//   presentation/pages/product_guided_create_page.dart, widgets/{product_guided_create_body, product_guided_fields,
//     product_guided_step_identification, product_guided_step_images, product_guided_step_base_unit, product_guided_step_base_cost,
//     product_guided_step_price_bands, product_guided_step_custom_fields, product_guided_step_note, product_image_picker_panel,
//     image_picker/{product_image_grid_item, product_image_add_sheet}, tenant_measurement_unit_search_field,
//     custom_fields/product_custom_field_input_widget}.dart
//   logic/{product_guided_create_state, product_guided_create_cubit}.dart, presentation/mappers/guided_price_band_submission_resolver.dart
import { icon } from '../shared/icons.js';
import { appBar, button, card, esc, field, gap, input, scaffold, select, suffixText, textAreaCounter, toast, vswitch } from './ds.js';
import { CF_GROUPS, TENANT_UNITS, money, photo } from './data.js';

// ---------------------------------------------------------------- hàm thuần (đối chiếu Dart)

/** Dart double.toString(): số nguyên vẫn có ".0"; còn lại như JS (giữ cả sai số dấu phẩy động). */
export const dartDouble = (n) => (Number.isInteger(n) ? `${n}.0` : String(n));

/** _buildCalculatedPriceDisplay: phần trăm = tỉ lệ × 100 (double), in thẳng vào nhãn "(+…%)". */
export const pricePercentLabel = (title, percent) => `${title} (+${dartDouble(percent)}%)`;

/** ProductGuidedCreateState.stepCount = 6 + số nhóm thông tin bổ sung; tiêu đề bước nhóm i = "${6 + i}. tên", Ghi chú = "${6 + n}. Ghi chú". */
export function stepTitles(groups) {
  return [
    '1. Nhận diện', '2. Ảnh', '3. Đơn vị cơ sở', '4. Giá cơ sở', '5. Khung giá bán',
    ...groups.map((g, i) => `${6 + i}. ${g.name}`),
    `${6 + groups.length}. Ghi chú`,
  ];
}

/** hasAnyData: tên, tên TM, SKU, barcode, ảnh, ĐVT, giá cơ sở, ghi chú (không xét khung giá, trường bổ sung, ô gạt lô). */
export function hasAnyData(s) {
  return ['name', 'tradeName', 'sku', 'barcode', 'baseUnit', 'baseCost', 'note'].some((k) => (s[k] || '').trim() !== '') || (s.images || []).length > 0;
}

/** _normalize của TenantMeasurementUnitSearchField: bỏ dấu, chữ thường; khớp khi tên chứa từ khoá. */
export function foldUnit(s) {
  return String(s).toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/đ/g, 'd');
}
export const matchUnits = (units, q) => (q.trim() ? units.filter((u) => foldUnit(u).includes(foldUnit(q.trim()))) : units);

// ---------------------------------------------------------------- phần nhỏ

/** ProductGuidedFields.buildLabel: đệm dưới 4 trái 4, bodySmall **w700 textSecondary** (khác VFieldLabel 14 w600 textPrimary). */
const guidedLabel = (t) => `<span class="t2-glabel">${esc(t)}</span>`;

/** ProductGuidedFields.buildInputDecoration → TextField Material: nền background, viền borderDefault bo 8, đệm 12 / 8 (≈ 40 cao). */
const materialField = ({ value = '', hint = '', focus = false }) => `<span class="t2-mfield${focus ? ' is-focus' : ''}"><input type="text" value="${esc(value)}" placeholder="${esc(hint)}"></span>`;

/** buildNavigationButtons: Row(spaceBetween)[TextButton "Bỏ qua" (bodyDefault textSecondary) | VButton "Tiếp"]; bước cuối không có cả hai. */
const navButtons = ({ skip = true, next = true } = {}) => `<div class="t2-stepnav">${skip ? '<button type="button" class="t2-skipbtn">Bỏ qua</button>' : '<span></span>'}${next ? button('Tiếp') : ''}</div>`;

/** Hộp cảnh báo tự vẽ: đệm 12, nền warningBg, bo 8, viền warning 30%, chữ warning. */
const warnBox = (text, small = false) => `<div class="t2-warnbox${small ? ' t2-warnbox--small' : ''}">${esc(text)}</div>`;

/** VTextField(label: …) legacy = vFieldShell(VFieldLabel + VInput + VFieldError). */
const vtext = (label, { value = '', hint = '', required = false, error = null, suffix = '' } = {}) => field({ label, required, error, control: input({ value, hint, invalid: !!error, suffix }) });

/** ListTile (M3): cao tối thiểu 72 (2 dòng), đệm trái 16 phải 24, khe 16 tới chevron 24 textSecondary; tiêu đề bodyDefault **bold**, phụ bodySmall textSecondary. */
function stepCard(title, subtitle, open, content, scrollTo = false) {
  return card(`<button type="button" class="t2-steptile" aria-expanded="${open}"><span class="t2-steptile__text"><b>${esc(title)}</b><span>${esc(subtitle)}</span></span><i class="t2-steptile__chev">${icon(open ? 'chevronUp' : 'chevronDown')}</i></button>${open ? `<div class="t2-stepbody">${content}</div>` : ''}`, { pad: false, cls: scrollTo ? 't2-scrollhere' : '' });
}

// ---------------------------------------------------------------- các bước

function stepIdentification(s) {
  const qr = `<button type="button" class="t2-suffixbtn" aria-label="Quét mã">${icon('qrScan')}</button>`;
  const dup = s.dupName ? `${gap(8)}<button type="button" class="t2-textbtn-icon">${icon('externalLink')}<span>Mở sản phẩm "${esc(s.dupName)}"</span></button>` : '';
  const lot = s.lot;
  return `${vtext('Tên nội bộ', { value: s.name, hint: 'Ví dụ: Amoxicillin 500mg', required: true, error: s.nameError ? 'Tên nội bộ không được bỏ trống' : null })}
    ${gap(12)}${vtext('Tên thương mại', { value: s.tradeName, hint: 'Tên hiển thị cho khách' })}
    ${gap(12)}<div class="t2-row2 t2-row2--start">
      ${vtext('SKU', { value: s.sku, hint: 'Nhập mã SKU', error: s.skuError })}
      ${vtext('Barcode', { value: s.barcode, hint: 'Quét hoặc nhập', error: s.barcodeError, suffix: qr })}
    </div>${dup}
    ${gap(12)}<div class="t2-row2 t2-row2--16">
      <span class="t2-switchpair"><span>Quản lý theo lô</span>${vswitch(lot)}</span>
      <span class="t2-switchpair${lot ? '' : ' is-muted'}"><span>Bắt buộc hạn dùng</span>${vswitch(s.expiry, { disabled: !lot })}</span>
    </div>
    ${gap(16)}${navButtons()}`;
}

/**
 * ProductImageGridItem: viền (lỗi danger · ảnh bìa success 2 · còn lại borderDefault 1), bo 12; nhãn "Mặc định" (nền success, chữ 10 w700 trắng,
 * đệm 6 / 3, bo dưới phải 12) góc trên trái; nút × tròn 24 (nền surface, icon 14 textSecondary) cách góc 4.
 * Đang tải: phủ surface 80% + vòng 24 nét 2.5 + "Đang tải" 10 w500 primary. Lỗi: phủ + error_outline 24 + câu lỗi 10 danger.
 */
function imageTile(img) {
  const cls = img.failed ? ' is-failed' : img.cover ? ' is-cover' : '';
  const over = img.uploading ? `<span class="t2-imgtile__over"><span class="t2-spin24"></span><b class="is-primary">Đang tải</b></span>`
    : img.failed ? `<span class="t2-imgtile__over">${icon('error')}<b class="is-danger">${esc(img.failed)}</b></span>` : '';
  const tag = img.cover && !img.failed && !img.uploading ? '<b class="t2-imgtile__tag">Mặc định</b>' : '';
  return `<span class="t2-imgtile${cls}"><img src="${photo(img.hue)}" alt="">${over}${tag}<span class="t2-imgtile__x">${icon('close')}</span></span>`;
}

function stepImages(s) {
  const imgs = s.images;
  const max = 8;
  const add = imgs.length < max ? `<span class="t2-imgtile t2-imgtile--add">${icon('plus')}${gap(4)}<b>Thêm</b></span>` : '';
  const hint = imgs.length < max
    ? `<p class="t2-small">Chạm vào ảnh để đặt làm ảnh mặc định. Tối đa ${max} ảnh.</p>`
    : `<p class="t2-small"><b class="t2-warn-b">Đã đạt tối đa ${max} ảnh. </b>Xóa bớt ảnh nếu muốn thêm ảnh mới.</p>`;
  return `<div class="t2-imggrid">${imgs.map(imageTile).join('')}${add}</div>
    ${imgs.length ? `${gap(16)}<button type="button" class="t2-linkbold">Xem gallery</button>` : ''}
    ${gap(16)}${hint}
    ${!imgs.length ? `${gap(8)}<p class="t2-caption">Chưa có ảnh</p>` : ''}
    ${imgs.some((i) => i.failed) ? `${gap(8)}<p class="t2-caption">Một số ảnh tải lên thất bại — bạn vẫn có thể lưu sản phẩm với ảnh đã tải thành công.</p>` : ''}
    ${gap(16)}${navButtons()}`;
}

/**
 * TenantMeasurementUnitSearchField: overlay ở root (Material elevation 8, bo 8, viền borderDefault), rộng bằng ô, cách 4 phía dưới;
 * đệm 12, cao ≤ 250; dòng: icon sell_outlined 18 + khe 8 + tên bodyDefault, đệm dọc 8. Chỉ hiện khi ô đang focus và có kết quả.
 */
function stepBaseUnit(s) {
  const matches = s.unitFocus ? matchUnits(TENANT_UNITS, s.baseUnit) : [];
  const drop = matches.length ? `<div class="t2-unitdrop">${matches.map((u) => `<span class="t2-unitdrop__row">${icon('tag')}<span>${esc(u)}</span></span>`).join('')}</div>` : '';
  return `<p class="t2-small">Đơn vị gốc để tính tồn/giá. Có thể bổ sung sau.</p>${gap(12)}
    ${guidedLabel('Đơn vị cơ sở')}<span class="t2-unitwrap">${materialField({ value: s.baseUnit, hint: 'Ví dụ: hộp, thùng...', focus: s.unitFocus })}${drop}</span>
    ${gap(8)}${gap(16)}${navButtons()}`;
}

function stepBaseCost(s) {
  if (!s.baseUnit.trim()) return `${warnBox('Cần thiết lập đơn vị cơ sở ở bước trước rồi mới nhập được giá cơ sở.')}${gap(16)}${navButtons()}`;
  return `<p class="t2-small">Nhập giá cơ sở của sản phẩm. Giá này dùng để tính gợi ý giá bán.</p>${gap(12)}
    ${guidedLabel(`Giá cơ sở (${s.baseUnit})`)}${input({ value: s.baseCost, hint: 'Nhập giá cơ sở', suffix: suffixText('đ') })}
    ${gap(16)}${navButtons()}`;
}

/** _buildPricingMethodCard: đệm dọc 8, bo 12; chọn → nền primary 8% + viền primary 1.5 + chữ bodySmall primary bold; không → surface + borderDefault + textSecondary. */
const methodCards = (m) => `<div class="t2-methods">${[['storeRule', 'Giá cửa hàng'], ['customAuto', 'Tự động riêng'], ['manual', 'Thủ công']].map(([k, l]) => `<button type="button" class="t2-method${m === k ? ' is-on' : ''}">${esc(l)}</button>`).join('')}</div>`;

/** _buildPricePreviewRow: đệm 12, surface, viền borderDefault, bo 12; [tiêu đề bodySmall w700 textSecondary, khe 4, phụ bodySmall textMuted] | giá headingH3 bold primary. */
const previewRow = (title, value, sub) => `<div class="t2-preview"><span><b>${esc(title)}</b>${gap(4)}<span>${esc(sub)}</span></span><strong>${esc(value)}</strong></div>`;
function calculated(base, markup, floor) {
  return `${previewRow(pricePercentLabel('Giá niêm yết gợi ý', markup), money(base * (1 + markup / 100)), 'Giá bán chuẩn chưa chiết khấu')}${gap(8)}${previewRow(pricePercentLabel('Giá bán sàn gợi ý', floor), money(base * (1 + floor / 100)), 'Giá tối thiểu nhân viên được phép bán')}`;
}

function stepPriceBands(s) {
  if (!s.baseUnit.trim()) return `${warnBox('Cần thiết lập đơn vị cơ sở ở bước trước rồi mới nhập được khung giá bán.')}${gap(16)}${navButtons()}`;
  const base = Number(String(s.baseCost).replace(/\./g, '')) || 0;
  let body = '';
  if (s.method === 'storeRule') {
    if (s.ruleLoading) body = '<div class="t2-ruleload"><span class="t2-spin t2-spin--material"></span></div>';
    else if (s.ruleUnavailable) body = warnBox(s.ruleUnavailable, true);
    else body = `<p class="t2-small">Quy tắc: ${esc(s.ruleName)}</p>${gap(12)}${calculated(base, s.ruleList * 100, s.ruleFloor * 100)}`;
  } else if (s.method === 'customAuto') {
    const pct = (label, val) => `<span class="t2-colfield">${guidedLabel(label)}${input({ value: val, suffix: suffixText('%') })}</span>`;
    const ok = s.markup !== '' && s.floorMarkup !== '';
    body = `<div class="t2-row2">${pct('Lãi cơ sở', s.markup)}${pct('Giá sàn', s.floorMarkup)}</div>${gap(16)}
      ${ok ? calculated(base, Number(s.markup), Number(s.floorMarkup)) : '<p class="t2-small t2-small--muted">Nhập tỷ lệ % để xem gợi ý giá.</p>'}`;
  } else {
    const moneyField = (label, val, err) => `<span class="t2-colfield">${guidedLabel(label)}${field({ control: input({ value: val, hint: '0', suffix: suffixText('đ'), invalid: !!err }), error: err })}</span>`;
    body = `<div class="t2-row2 t2-row2--start">${moneyField('Giá niêm yết', s.listPrice, null)}${moneyField('Giá bán sàn', s.floorPrice, s.manualError)}</div>${gap(12)}
      <div class="t2-warnrow">${icon('info')}<span>Giá nhập thủ công sẽ không tự động cập nhật khi giá cơ sở thay đổi.</span></div>`;
  }
  return `<p class="t2-small">Thiết lập giá bán của sản phẩm. Bạn có thể chọn cách định giá tự động hoặc nhập thủ công.</p>${gap(12)}
    ${methodCards(s.method)}${gap(16)}${body}${gap(16)}${navButtons()}`;
}

/** ProductCustomFieldInputWidget: mỗi trường đệm dưới 24. text / number → VTextField(label); chọn một → VSelect(label, "— Chọn —"); có / không → VSwitch(label + " *"); ngày → VDatePicker(label). */
function stepCustomFields(s, group, last) {
  const err = s.cfErrors || {};
  const one = (f) => {
    const v = (s.cf || {})[f.name];
    let ctl;
    if (f.type === 'singleSelect') ctl = field({ label: f.name, required: f.required, error: err[f.name], control: select({ value: v, hint: '— Chọn —' }) });
    else if (f.type === 'boolean') ctl = vswitch(!!v, { label: f.name + (f.required ? ' *' : '') });
    else if (f.type === 'date') ctl = field({ label: f.name, required: f.required, control: `<span class="t2-date">${icon('calendar')}<span>${esc(v || 'Chọn ngày')}</span></span>` });
    else ctl = vtext(f.name, { value: v || '', required: f.required, error: err[f.name] });
    return `<div class="t2-cfinput">${ctl}</div>`;
  };
  return `${group.fields.map(one).join('')}${gap(16)}${navButtons({ next: !last })}`;
}

function stepNote(s) {
  return `${guidedLabel('Nội dung ghi chú')}${textAreaCounter({ value: s.note, hint: 'Ví dụ: Hàng nhập từ NCC A, khách hay hỏi tên cũ ABC...', lines: 4, max: 500 })}
    ${gap(8)}<p class="t2-small">Ghi chú riêng cho bạn. Không hiển thị cho khách hàng.</p>`;
}

// ---------------------------------------------------------------- trang

/**
 * ProductGuidedCreatePage: VPageScaffold("Tạo nhanh sản phẩm", leading IconButton(VIcons.arrowBack 24) — khác ‹ của VAppBar),
 * resizeToAvoidBottomInset false. Thân (ProductGuidedCreateBody): cuộn đệm 16, các thẻ bước cách 8; chân dính: đệm 16, nền surface,
 * gạch trên borderDefault, SafeArea dưới; "Huỷ" (secondary) | khe 16 | "Lưu sản phẩm" (tắt khi !hasAnyData hoặc đang lưu).
 */
export function createPage(s, v) {
  const groups = s.groups;
  const titles = stepTitles(groups);
  const subs = [
    'Tên nội bộ, tên thương mại, SKU, barcode', 'Ảnh bìa và ảnh phụ', 'Chọn đơn vị gốc để tính giá', 'Thiết lập giá cơ sở ban đầu', 'Thiết lập cách tính giá bán',
    ...groups.map((g) => `${g.fields.filter((f) => (s.cf || {})[f.name] != null && (s.cf || {})[f.name] !== '').length}/${g.fields.length} trường đã điền`),
    'Nhắc chính bạn: nguồn hàng, lưu ý riêng...',
  ];
  const content = [
    () => stepIdentification(s), () => stepImages(s), () => stepBaseUnit(s), () => stepBaseCost(s), () => stepPriceBands(s),
    ...groups.map((g, i) => () => stepCustomFields(s, g, 5 + i === titles.length - 1)),
    () => stepNote(s),
  ];
  const steps = titles.map((t, i) => stepCard(t, subs[i], s.active === i, s.active === i ? content[i]() : '', s.active === i && i > 0)).join(gap(8));
  const saving = s.submitting;
  const foot = `<div class="t2-stickyfoot"><div class="t2-btnrow16">${button('Huỷ', { variant: 'secondary', full: true, disabled: saving })}${button('Lưu sản phẩm', { full: true, loading: saving, disabled: !hasAnyData(s) })}</div></div>`;
  const back = '<button type="button" class="t2-appbar__back" aria-label="Quay lại">' + icon('arrowLeft') + '</button>';
  const page = scaffold({
    appbar: appBar('Tạo nhanh sản phẩm', { leading: back }),
    body: `<div class="t2-create"><div class="t2-create__scroll"${s.scrollEnd ? ' data-scroll-end' : ''}>${steps}</div>${foot}</div>`,
    placeWidth: v.width,
    windowWidth: v.width,
    cls: 't2-page--create',
  });
  const t = s.toast ? toast(s.toast[0], s.toast[0] === 'danger' ? 'Lỗi' : 'Thành công', s.toast[1], { bottom: 14 + (v.device === 'iphone' ? 34 : 0) }) : '';
  return `<div class="t2-area">${page}${t}</div>`;
}

/**
 * ProductImageAddSheet (showVAdaptiveSheet title "Thêm ảnh sản phẩm"): SafeArea + đệm 16; 3 ô (đệm 12, viền borderDefault, bo 12, nền background):
 * hộp icon đệm 8 nền màu 10% bo 12 + icon 24 | khe 12 | tiêu đề bodyDefault w600, khe 4, phụ bodySmall textSecondary. Khe 8; khe 24 + "Hủy" secondary đầy ngang.
 */
export function imageAddSheet() {
  const opt = (ic, tone, title, sub) => `<div class="t2-imgopt"><span class="t2-imgopt__ic t2-imgopt__ic--${tone}">${icon(ic)}</span><span><b>${esc(title)}</b>${gap(4)}<span>${esc(sub)}</span></span></div>`;
  return `<div class="t2-imgadd">${opt('camera', 'success', 'Chụp ảnh', 'Dùng camera của thiết bị')}${gap(8)}${opt('images', 'primary', 'Chọn từ thư viện', 'Chọn ảnh đã có trên máy')}${gap(8)}${opt('folder', 'primary', 'Chọn tệp', 'Tải ảnh từ thư mục')}${gap(24)}${button('Hủy', { variant: 'secondary', full: true })}</div>`;
}

// ---------------------------------------------------------------- ca → trạng thái

const BLANK = {
  name: '', tradeName: '', sku: '', barcode: '', lot: false, expiry: false, nameError: false, skuError: null, barcodeError: null, dupName: '',
  images: [], baseUnit: '', unitFocus: false, baseCost: '', method: 'storeRule', ruleLoading: false, ruleUnavailable: '',
  ruleName: 'Khung giá mặc định', ruleList: 0.28, ruleFloor: 0.14, markup: '', floorMarkup: '', listPrice: '', floorPrice: '', manualError: null,
  groups: CF_GROUPS, cf: {}, cfErrors: {}, note: '', active: 0, submitting: false, toast: null, scrollEnd: false,
};
const FILLED = { ...BLANK, name: 'Amoxicillin 500mg', tradeName: 'Amoxi-Vet 500', sku: 'AMX500', barcode: '8936012345678', lot: true };
const WITH_UNIT = { ...FILLED, baseUnit: 'hộp', baseCost: '80.000' };
const IMGS = [{ hue: 32, cover: true }, { hue: 160 }, { hue: 280, uploading: true }, { hue: 200, failed: 'Lỗi tải' }];

export function createState(state) {
  switch (state) {
    case 'new': return { ...BLANK };
    case 'filled': return { ...FILLED };
    case 'name-error': return { ...BLANK, tradeName: 'Amoxi-Vet 500', nameError: true, toast: ['danger', 'Vui lòng nhập tên nội bộ sản phẩm.'] };
    case 'duplicate': return { ...FILLED, skuError: 'SKU "AMX500" đã được sử dụng', dupName: 'Amoxicillin 500mg (hộp 10 vỉ)' };
    case 'images-empty': return { ...FILLED, active: 1 };
    case 'images': return { ...FILLED, active: 1, images: IMGS };
    case 'images-max': return { ...FILLED, active: 1, images: [32, 160, 280, 200, 12, 50, 120, 300].map((hue, i) => ({ hue, cover: i === 0 })) };
    case 'unit': return { ...FILLED, active: 2 };
    case 'unit-dropdown': return { ...FILLED, active: 2, baseUnit: 'h', unitFocus: true };
    case 'cost-no-unit': return { ...FILLED, active: 3 };
    case 'cost': return { ...WITH_UNIT, active: 3 };
    case 'price-store': return { ...WITH_UNIT, active: 4 };
    case 'price-store-loading': return { ...WITH_UNIT, active: 4, ruleLoading: true };
    case 'price-store-missing': return { ...WITH_UNIT, active: 4, ruleUnavailable: 'Chưa cấu hình khung giá cửa hàng. Vui lòng thiết lập trong Cài đặt sản phẩm.' };
    case 'price-custom-empty': return { ...WITH_UNIT, active: 4, method: 'customAuto' };
    case 'price-custom': return { ...WITH_UNIT, active: 4, method: 'customAuto', markup: '35', floorMarkup: '12.5' };
    case 'price-manual': return { ...WITH_UNIT, active: 4, method: 'manual', listPrice: '120.000', floorPrice: '100.000' };
    case 'price-manual-error': return { ...WITH_UNIT, active: 4, method: 'manual', listPrice: '120.000', floorPrice: '150.000', manualError: 'Giá sàn phải ≤ giá niêm yết', toast: ['danger', 'Giá sàn không được lớn hơn giá niêm yết.'] };
    case 'price-no-unit': return { ...FILLED, active: 4 };
    case 'custom-fields': return { ...WITH_UNIT, active: 5, cf: { 'Dạng bào chế': 'Viên nén', 'Hàm lượng (mg)': '500' } };
    case 'custom-fields-error': return { ...WITH_UNIT, active: 5, cfErrors: { 'Dạng bào chế': 'Trường này là bắt buộc' }, toast: ['danger', 'Vui lòng điền đầy đủ các trường bắt buộc.'] };
    case 'note': return { ...WITH_UNIT, active: 6, note: 'Hàng nhập từ NCC Thú y Sài Gòn.', scrollEnd: true };
    case 'no-groups': return { ...WITH_UNIT, groups: [], active: 5, note: '', scrollEnd: true };
    case 'collapsed': return { ...WITH_UNIT, active: -1 };
    case 'submitting': return { ...WITH_UNIT, active: -1, submitting: true };
    case 'save-error': return { ...WITH_UNIT, active: -1, toast: ['danger', 'Lỗi hệ thống khi tạo sản phẩm.'] };
    default: return { ...BLANK };
  }
}
