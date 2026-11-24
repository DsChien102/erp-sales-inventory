// Đợt 3 — màn con của sản phẩm (ngoài khung: web không có thanh bên, thân cột 720):
//   SP-05 Hồ sơ (pages/product_profile_maintenance_page.dart), SP-06 Ảnh (pages/product_images_maintenance_page.dart,
//   widgets/image_picker/{product_image_delete_dialog, product_image_gallery_viewer}.dart), SP-07 Ghi chú (pages/product_note_edit_page.dart),
//   SP-08 Nhập nhóm thông tin bổ sung (pages/product_custom_field_group_edit_page.dart), SP-09 Đơn vị (pages/product_measurement_units_page.dart,
//   widgets/{product_conversion_unit_item, product_conversion_unit_*_dialog, product_measurement_units_bottom_bar}.dart),
//   SP-11 Giá cơ sở (pages/product_manual_base_price_page.dart, widgets/dashed_border_container.dart),
//   SP-12 Khung giá (pages/product_price_bands_page.dart), SP-13 Sửa khung giá một đơn vị (pages/edit_product_unit_price_band_page.dart,
//   widgets/{price_band_calculation_type_selector, price_band_store_rule_section, price_band_custom_config_section, price_band_manual_section,
//   price_band_overwrite_dialog}.dart). Chân chung: widgets/product_form_bottom_bar.dart.
import { icon } from '../shared/icons.js';
import { appBar, badge, button, card, esc, field, gap, input, scaffold, select, suffixText, textAreaCounter, toast, vswitch } from './ds.js';
import { money, photo } from './data.js';

const PRODUCT = 'Amoxicillin 500mg';
const back = () => `<button type="button" class="t2-appbar__back" aria-label="Quay lại">${icon('arrowLeft')}</button>`;

// ---------------------------------------------------------------- hàm thuần (đối chiếu Dart)

/** ProductConversionUnitItem._formatRate: số nguyên → không phần thập phân. */
export const formatRate = (r) => (Number.isInteger(r) ? String(r) : String(r));

/** Store rule section _ratioRow: (giá − giá cơ sở) / giá cơ sở × 100, toStringAsFixed(0) + "%". */
export const ratioText = (price, base) => (base === 0 || price == null ? '—' : `${((price - base) / base * 100).toFixed(0)}%`);

/** ProductMeasurementUnitsBottomBar: "Lưu thay đổi" chỉ đóng màn (đơn vị đã lưu ngay từng thao tác); bật khi phiên đã lưu gì đó hoặc đang sửa ĐVT cơ sở khác giá trị cũ. */
export const unitsSaveEnabled = ({ persisted, editingBase, input = '', base = '' }) => persisted || (editingBase && input.trim().toLowerCase() !== base.trim().toLowerCase());

// ---------------------------------------------------------------- chung

/**
 * ProductFormBottomBar: nền surface, gạch trên borderDefault, đệm 16, SafeArea; "Huỷ" (secondary) | khe 16 | nút lưu (primary).
 * Đặt trong VPageScaffold.bottomBar (đã có gạch + SafeArea riêng) → web thấy hai gạch: gạch của bottomBar hết bề ngang + gạch của thanh trong cột 720.
 */
export const formBar = ({ save = 'Lưu thay đổi', enabled = true, loading = false, cancelDisabled = false, safe = false } = {}) => `<div class="t2-formbar${safe ? ' t2-formbar--safe' : ''}"><div class="t2-btnrow16">${button('Huỷ', { variant: 'secondary', full: true, disabled: cancelDisabled })}${button(save, { full: true, loading, disabled: !enabled })}</div></div>`;

const page = (v, { title, subtitle = '', body, bottomBar = '', leading = back(), plainBack = false }) => scaffold({
  appbar: appBar(title, { subtitle, leading: plainBack ? '' : leading, back: plainBack }), body, bottomBar, placeWidth: v.width, windowWidth: v.width,
});
const withToast = (html, v, t) => (t ? `<div class="t2-area">${html}${toast(t[0], '', t[1], { bottom: 14 + (v.device === 'iphone' ? 34 : 0) + (t[2] || 0) })}</div>` : html);
const vtext = (label, { value = '', hint = '', required = false, error = null } = {}) => field({ label, required, error, control: input({ value, hint, invalid: !!error }) });

// ---------------------------------------------------------------- SP-05 hồ sơ

/**
 * VPageScaffold("Hồ sơ sản phẩm", leading arrowBack, không subtitle). Thân cuộn đệm 16: 4 VTextField (khe 16; SKU | Barcode chia đôi khe 16),
 * khe 16, hàng "Quản lý theo lô" + VSwitch, khe 12, hàng "Bắt buộc hạn dùng" + VSwitch; [khóa: khe 8 + "Đã có biến động kho, không đổi được." bodySmall warning].
 * bottomBar: ProductFormBottomBar ("Lưu thay đổi" bật khi có đổi).
 */
export function profilePage(s, v) {
  const lot = s.lot;
  const body = `<div class="t2-subscroll">
    ${vtext('Tên nội bộ', { value: s.name, hint: 'Tên nội bộ', required: true, error: s.nameError })}${gap(16)}
    ${vtext('Tên thương mại', { value: s.trade, hint: 'Tên hiển thị cho khách' })}${gap(16)}
    <div class="t2-row2 t2-row2--16 t2-row2--start">${vtext('SKU', { value: s.sku, hint: 'Mã SKU', error: s.skuError })}${vtext('Barcode', { value: s.barcode, hint: 'Mã vạch' })}</div>${gap(16)}
    <div class="t2-swrow"><span>Quản lý theo lô</span>${vswitch(lot, { disabled: s.locked })}</div>${gap(12)}
    <div class="t2-swrow${!s.locked && lot ? '' : ' is-muted'}"><span>Bắt buộc hạn dùng</span>${vswitch(s.expiry, { disabled: s.locked || !lot })}</div>
    ${s.locked ? `${gap(8)}<p class="t2-small t2-small--warn">Đã có biến động kho, không đổi được.</p>` : ''}
  </div>`;
  return withToast(page(v, { title: 'Hồ sơ sản phẩm', body, bottomBar: formBar({ enabled: s.dirty, loading: s.saving }) }), v, s.toast);
}
export function profileState(k) {
  const base = { name: PRODUCT, trade: 'Amoxi-Vet 500', sku: 'AMX500', barcode: '8936012345678', lot: false, expiry: false, locked: false, dirty: false };
  return {
    default: base, 'lot-on': { ...base, lot: true, expiry: true, dirty: true }, locked: { ...base, lot: true, locked: true },
    'sku-error': { ...base, sku: 'PATE85', skuError: 'SKU "PATE85" đã được sử dụng', dirty: true, toast: ['danger', 'SKU "PATE85" đã được sử dụng'] },
    'name-error': { ...base, name: '', nameError: 'Tên nội bộ không được bỏ trống', dirty: true },
    saving: { ...base, trade: 'Amoxi-Vet 500 (hộp 10 vỉ)', dirty: true, saving: true },
  }[k];
}

// ---------------------------------------------------------------- SP-06 ảnh

/** Lưới 3 cột như bước ảnh của màn tạo; ô "Thêm" lúc đang tải lên → vòng Material giữa ô. "Xem trước ảnh" (màn tạo ghi "Xem gallery"). */
export function imagesPage(s, v) {
  const tile = (im) => `<span class="t2-imgtile${im.cover ? ' is-cover' : ''}"><img src="${photo(im.hue)}" alt="">${im.cover ? '<b class="t2-imgtile__tag">Mặc định</b>' : ''}<span class="t2-imgtile__x">${icon('close')}</span></span>`;
  const can = s.images.length < 8;
  const add = can ? `<span class="t2-imgtile t2-imgtile--add">${s.uploading ? '<span class="t2-spin t2-spin--material"></span>' : `${icon('plus')}${gap(4)}<b>Thêm</b>`}</span>` : '';
  const hint = can ? '<p class="t2-small">Chạm vào ảnh để đặt làm ảnh mặc định. Tối đa 8 ảnh.</p>' : '<p class="t2-small"><b class="t2-warn-b">Đã đạt tối đa 8 ảnh. </b>Xóa bớt ảnh nếu muốn thêm ảnh mới.</p>';
  const body = `<div class="t2-subscroll"><div class="t2-imggrid">${s.images.map(tile).join('')}${add}</div>${s.images.length ? `${gap(16)}<button type="button" class="t2-linkbold">Xem trước ảnh</button>` : ''}${gap(16)}${hint}</div>`;
  return withToast(page(v, { title: 'Ảnh sản phẩm', body, bottomBar: formBar({ enabled: s.dirty }) }), v, s.toast);
}
const IMGS = [{ hue: 32, cover: true }, { hue: 160 }, { hue: 280 }];
export function imagesState(k) {
  return {
    default: { images: IMGS }, empty: { images: [] }, uploading: { images: IMGS, uploading: true, dirty: true },
    max: { images: [32, 160, 280, 200, 12, 50, 120, 300].map((hue, i) => ({ hue, cover: i === 0 })) },
    'delete-dialog': { images: IMGS }, gallery: { images: IMGS },
  }[k];
}

/** ProductImageDeleteDialog: Dialog Material (cả iPhone), bo 16, đệm 24; vòng dangerBg đệm 12 + delete_outline 32; tiêu đề H4 bold giữa; câu giữa; "Hủy" | "Xóa ảnh" đỏ. */
export const imageDeleteDialog = () => `<div class="sh-scrim sh-scrim--dialog"><section class="t2-mdialog" role="dialog" aria-modal="true" aria-label="Xóa ảnh sản phẩm?">
  <span class="t2-mdialog__ic">${icon('trash')}</span>${gap(16)}<h2 class="t2-mdialog__title">Xóa ảnh sản phẩm?</h2>${gap(8)}
  <p class="t2-mdialog__text">Ảnh này sẽ bị xóa vĩnh viễn. Nếu đây là ảnh mặc định, hệ thống sẽ chọn ảnh còn lại đầu tiên làm ảnh mặc định.</p>${gap(24)}
  <div class="t2-btnrow16">${button('Hủy', { variant: 'secondary', full: true })}${button('Xóa ảnh', { full: true, tone: 'danger' })}</div></section></div>`;

/** ProductImageGalleryViewer: Scaffold nền textPrimary, AppBar Material (← trắng, "Gallery ảnh" H4, "1/3"); ảnh contain; đáy chuyển màu: "Mặc định" pill, "Vuốt để xem ảnh khác", "Đóng" viền đầy ngang. */
export const galleryPage = (v) => `<div class="t2-gallery"><header class="t2-gallery__bar"><span class="t2-gallery__back">${icon('arrowLeft')}</span><b>Gallery ảnh</b><span>1/3</span></header>
  <div class="t2-gallery__img"><img src="${photo(32)}" alt=""></div>
  <div class="t2-gallery__foot${v.device === 'iphone' ? ' is-safe' : ''}"><b class="t2-gallery__pill">Mặc định</b><span>Vuốt để xem ảnh khác</span>${gap(16)}${button('Đóng', { variant: 'secondary', full: true })}</div></div>`;

// ---------------------------------------------------------------- SP-07 ghi chú

/**
 * Scaffold thường (không VPageScaffold) + VAppBar(‹, "Ghi chú", subtitle tên) → web **không giới hạn cột 720**: ô ghi chú và chân kéo hết 1280.
 * Thân ListView đệm 16: câu bodyDefault textSecondary, khe 16, ô 6 dòng + bộ đếm /500. bottomNavigationBar = ProductFormBottomBar (SafeArea).
 */
export function notePage(s, v) {
  const body = `<div class="t2-subscroll"><p class="t2-body2">Ghi chú riêng cho chính bạn. Không hiển thị cho khách hàng.</p>${gap(16)}${textAreaCounter({ value: s.note, hint: 'Ví dụ: Hàng nhập từ NCC A, khách hay hỏi tên cũ ABC...', lines: 6, max: 500 })}</div>`;
  const html = `<div class="t2-page">${appBar('Ghi chú', { subtitle: PRODUCT, back: true })}<div class="t2-body">${body}</div>${formBar({ enabled: s.dirty, safe: true })}</div>`;
  return withToast(html, v, s.toast);
}
export const noteState = (k) => ({ default: { note: 'Hàng nhập từ NCC Thú y Sài Gòn.' }, empty: { note: '' }, dirty: { note: 'Hàng nhập từ NCC Thú y Sài Gòn. Khách hay hỏi tên cũ "Amoxi 500".', dirty: true } }[k]);

// ---------------------------------------------------------------- SP-08 nhập nhóm thông tin bổ sung

/**
 * VPageScaffold(tiêu đề = tên nhóm, subtitle tên sản phẩm, leading arrowBack). ListView đệm 16: một khung (surface, bo 12, viền borderDefault,
 * đệm trên/trái/phải 16, **không đệm dưới** — ô cuối có đệm dưới 24 của ProductCustomFieldInputWidget). Đang tải: tiêu đề "Trường thông tin", nút ‹, vòng Material.
 * Mọi trường đã tắt → không có chân lưu (và ô mờ). Không hỏi khi rời dù đã sửa.
 */
export function customFieldsPage(s, v) {
  if (s.loading) return page(v, { title: 'Trường thông tin', body: '<div class="t2-center"><span class="t2-spin t2-spin--material"></span></div>', plainBack: true });
  const err = s.errors || {};
  const one = (f) => {
    const val = s.values[f.name];
    let ctl;
    if (f.type === 'singleSelect') ctl = field({ label: f.name, required: f.required, error: err[f.name], control: select({ value: val, hint: '— Chọn —' }) });
    else if (f.type === 'boolean') ctl = vswitch(!!val, { label: f.name + (f.required ? ' *' : ''), disabled: s.inactive });
    else if (f.type === 'date') ctl = field({ label: f.name, required: f.required, control: `<span class="t2-date">${icon('calendar')}<span>${esc(val || 'Chọn ngày')}</span></span>` });
    else ctl = vtext(f.name, { value: val || '', required: f.required, error: err[f.name] });
    return `<div class="t2-cfinput${s.inactive ? ' is-disabled' : ''}">${ctl}</div>`;
  };
  const body = `<div class="t2-subscroll"><div class="t2-cfbox">${s.fields.map(one).join('')}</div></div>`;
  return withToast(page(v, { title: s.group, subtitle: PRODUCT, body, bottomBar: s.inactive ? '' : formBar({ enabled: s.dirty }) }), v, s.toast);
}
const CF = [
  { name: 'Dạng bào chế', type: 'singleSelect', required: true }, { name: 'Hàm lượng (mg)', type: 'number' },
  { name: 'Kê đơn', type: 'boolean' }, { name: 'Ngày được cấp phép', type: 'date' },
];
export function customFieldsState(k) {
  const base = { group: 'Thông tin dược', fields: CF, values: { 'Dạng bào chế': 'Viên nén', 'Hàm lượng (mg)': '500', 'Kê đơn': true, 'Ngày được cấp phép': '12/03/2025' } };
  return {
    default: base, dirty: { ...base, values: { ...base.values, 'Hàm lượng (mg)': '250' }, dirty: true },
    error: { ...base, values: { 'Hàm lượng (mg)': '500' }, errors: { 'Dạng bào chế': 'Trường này là bắt buộc' }, dirty: true, toast: ['danger', 'Vui lòng điền đầy đủ các trường bắt buộc.'] },
    loading: { loading: true }, inactive: { ...base, inactive: true },
  }[k];
}

// ---------------------------------------------------------------- SP-09 đơn vị

/**
 * ProductConversionUnitItem: đệm đáy 8; Material (surface | tắt: surfaceAlt) bo 8, viền borderDefault, đệm 12; Row[hộp icon inventory 24 (đệm 8, nền surfaceAlt / borderDefault, bo 8),
 * khe 12, cột (tên bold + [thẻ "Đã tắt"], khe 4, **tên lặp lại** bodySmall), "n x <ĐVT cơ sở>" w600]; dưới: "giữ để mở" caption textMuted phải (chỉ nhấn giữ mới mở);
 * mở → [Tắt đơn vị / Bật đơn vị (viền nhỏ) | khe 8 | Xoá (đỏ nhỏ) | khe 8 | Đóng (chữ xám)].
 */
function convItem(u, base, open = false) {
  const off = !u.active;
  const actions = open
    ? `${gap(12)}<div class="t2-convact">${button(off ? 'Bật đơn vị' : 'Tắt đơn vị', { variant: 'secondary', size: 'small', full: true })}${button('Xoá', { size: 'small', full: true, tone: 'danger' })}${button('Đóng', { variant: 'tertiary', size: 'small', cls: 't2-btn--muted' })}</div>`
    : `${gap(4)}<span class="t2-conv__hint">giữ để mở</span>`;
  return `<div class="t2-conv${off ? ' is-off' : ''}"><div class="t2-conv__row"><span class="t2-conv__ic">${icon('inventory')}</span><span class="t2-conv__text"><span class="t2-conv__name"><b>${esc(u.name)}</b>${off ? '<i>Đã tắt</i>' : ''}</span>${gap(4)}<small>${esc(u.name)}</small></span><b class="t2-conv__rate">${formatRate(u.rate)} x ${esc(base)}</b></div>${actions}</div>`;
}

/** Nút viền tự vẽ (InkWell, viền primary 50%, bo 8, đệm dọc 12) + icon 18 + chữ bodyDefault primary — không phải VButton. */
const outlineAdd = (label) => `<button type="button" class="t2-addline">${icon('plus')}<span>${esc(label)}</span></button>`;

/**
 * VPageScaffold("Đơn vị đo lường", subtitle tên, leading arrowBack). Thẻ "ĐƠN VỊ CƠ SỞ" (nhãn hoa bodySmall bold) và thẻ "ĐƠN VỊ QUY ĐỔI (n)", khe 16.
 * Sửa ĐVT cơ sở / thêm quy đổi: ô VTextField, câu "Sẽ lưu ở dạng chữ thường: …", TextButton "Huỷ" xám + VButton "Lưu" / "Thêm" canh phải.
 * Chân "Lưu thay đổi" chỉ đóng màn — mọi thay đổi đã lưu ngay khi bấm "Lưu" / "Thêm".
 */
export function unitsPage(s, v) {
  const has = !!s.base;
  let baseCard;
  if (s.editBase) {
    baseCard = `<p class="t2-small">Tên đơn vị cơ sở</p>${gap(8)}${input({ value: s.baseInput, hint: 'hộp, chai, gói, lọ, kg...' })}${gap(8)}<p class="t2-small">Sẽ lưu ở dạng chữ thường: ${esc(s.baseInput.toLowerCase())}</p>${gap(16)}<div class="t2-inlinesave"><button type="button" class="t2-skipbtn">Huỷ</button>${button('Lưu')}</div>`;
  } else if (!has) baseCard = `<p class="t2-body1">Chưa thiết lập (không bắt buộc).</p>${gap(16)}${outlineAdd('Thiết lập đơn vị cơ sở')}`;
  else baseCard = `<b class="t2-unitbase">${esc(s.base)}</b>${gap(4)}<p class="t2-small">Đơn vị cơ sở không đổi được sau khi đã đặt.</p>`;
  let conv;
  if (!has) conv = '<p class="t2-body1">Cần đặt đơn vị cơ sở trước khi thêm đơn vị quy đổi.</p>';
  else {
    const list = s.units.length ? s.units.map((u, i) => convItem(u, s.base, s.openIndex === i)).join('') : (!s.adding ? '<p class="t2-body1">Chưa có đơn vị quy đổi.</p>' : '');
    const form = s.adding
      ? `<div class="t2-row2 t2-row2--16 t2-row2--start"><span class="t2-colfield"><p class="t2-small">Tên đơn vị</p>${gap(8)}${input({ value: s.convName, hint: 'hộp, thùng...' })}</span><span class="t2-colfield"><p class="t2-small">Tỉ lệ (x ${esc(s.base)})</p>${gap(8)}${input({ value: s.convRate, hint: '10' })}</span></div>${gap(8)}<p class="t2-small">Sẽ lưu ở dạng chữ thường: ${s.convName.trim() ? esc(s.convName.trim().toLowerCase()) : '—'}</p>${gap(16)}<div class="t2-inlinesave"><button type="button" class="t2-skipbtn">Huỷ</button>${button('Thêm')}</div>`
      : outlineAdd('Thêm đơn vị quy đổi');
    conv = `${list}${gap(16)}${form}`;
  }
  const body = `<div class="t2-subscroll">${card(`<p class="t2-caps">ĐƠN VỊ CƠ SỞ</p>${gap(12)}${baseCard}`)}${gap(16)}${card(`<p class="t2-caps">ĐƠN VỊ QUY ĐỔI (${s.units.length})</p>${gap(12)}${conv}`)}</div>`;
  const en = unitsSaveEnabled({ persisted: s.persisted, editingBase: s.editBase, input: s.baseInput || '', base: s.base || '' });
  return withToast(page(v, { title: 'Đơn vị đo lường', subtitle: PRODUCT, body, bottomBar: formBar({ enabled: en }) }), v, s.toast);
}
const UNITS = [{ name: 'thùng', rate: 20, active: true }, { name: 'lốc', rate: 5, active: true }, { name: 'két', rate: 24, active: false }];
export function unitsState(k) {
  const b = { base: 'hộp', units: UNITS, openIndex: -1 };
  return {
    default: b, 'no-base': { base: null, units: [] }, 'edit-base': { base: null, units: [], editBase: true, baseInput: 'Hộp' },
    'no-conv': { base: 'hộp', units: [] }, adding: { ...b, adding: true, convName: 'Thùng', convRate: '20', units: UNITS.slice(1) },
    expanded: { ...b, openIndex: 0 }, 'expanded-off': { ...b, openIndex: 2 },
    'toast-added': { ...b, persisted: true, toast: ['success', 'Đã cập nhật đơn vị quy đổi'] },
    'toast-error': { ...b, adding: true, convName: 'hộp', convRate: '1', units: UNITS, toast: ['danger', 'Không thể dùng đơn vị cơ sở làm đơn vị quy đổi'] },
    deactivate: b, reactivate: b, delete: b, 'delete-blocked': b,
  }[k];
}
/** Sheet đơn vị: khuôn _VLifecycleBottomSheetContent (đệm 20, câu xám, khe 24, hai nút). */
const lcSheet = (text, cancel, primary, danger) => `<div class="t2-lc"><p class="t2-sheettext">${esc(text)}</p>${gap(24)}<div class="t2-btnrow16">${button(cancel, { variant: 'secondary', full: true })}${button(primary, { full: true, tone: danger ? 'danger' : '' })}</div></div>`;
export const UNIT_SHEETS = {
  deactivate: ['Tắt đơn vị này?', () => lcSheet('Đơn vị "thùng" sẽ ẩn khỏi lựa chọn khi nhập/bán, dữ liệu cũ vẫn giữ nguyên.', 'Huỷ', 'Tắt', true)],
  reactivate: ['Bật lại đơn vị?', () => lcSheet('Đơn vị "két" sẽ được dùng lại trong nhập/bán hàng.', 'Huỷ', 'Bật', true)],
  delete: ['Xoá đơn vị quy đổi?', () => lcSheet('Đơn vị "thùng" sẽ bị xóa vĩnh viễn khỏi sản phẩm. Chỉ dùng khi đơn vị chưa có giao dịch hoặc khung giá. Nếu đã phát sinh dữ liệu, hệ thống sẽ gợi ý "Tắt đơn vị" thay vì xóa.', 'Huỷ', 'Xoá', true)],
  'delete-blocked': ['Không thể xóa đơn vị', () => lcSheet('Không thể xóa đơn vị này vì đã có dữ liệu phụ thuộc. Hãy dùng "Tắt đơn vị" để bảo toàn lịch sử.', 'Đóng', 'Tắt đơn vị', false)],
};

// ---------------------------------------------------------------- SP-11 giá cơ sở

/**
 * VPageScaffold("Giá cơ sở", subtitle, arrowBack). Chân nằm **trong thân** (Column[Expanded(cuộn), ProductFormBottomBar]) → không có gạch đôi như màn khác.
 * Có ĐVT: VCard(16)[ô "Giá cơ sở hiện tại" (viền textSecondary 20%, bo 8, đệm 16 / 12) | giá bold; khe 16; nhãn bodySmall "Giá cơ sở mới (đ / 1 hộp)";
 * khe 8; VMoneyField gợi ý "Ví dụ: 45,000", hậu tố "đ / hộp"; khe 8; câu nhỏ]. Chưa có ĐVT: khung viền đứt (borderDefault, 6 / 4, bo 8) + câu có chữ đậm.
 */
export function basePricePage(s, v) {
  const inner = s.unit
    ? card(`<div class="t2-curprice"><span>Giá cơ sở hiện tại</span><b>${s.current != null ? esc(money(s.current)) : '—'}</b></div>${gap(16)}<p class="t2-small">Giá cơ sở mới (đ / 1 ${esc(s.unit)})</p>${gap(8)}${input({ value: s.value, hint: 'Ví dụ: 45,000', suffix: suffixText(`đ / ${s.unit}`) })}${gap(8)}<p class="t2-small">Giá cơ sở luôn gắn với đơn vị cơ sở của sản phẩm (${esc(s.unit)}).</p>`)
    : `<div class="t2-dashed"><p class="t2-body1">Cần thiết lập <b>đơn vị cơ sở</b> cho sản phẩm trước khi nhập giá cơ sở.</p>${gap(8)}<p class="t2-small">Giá cơ sở luôn gắn với đơn vị cơ sở của sản phẩm.</p></div>`;
  const body = `<div class="t2-create"><div class="t2-subscroll">${inner}</div>${formBar({ enabled: !!s.unit && s.dirty, loading: s.saving, safe: true })}</div>`;
  return withToast(page(v, { title: 'Giá cơ sở', subtitle: PRODUCT, body }), v, s.toast);
}
export const basePriceState = (k) => ({
  default: { unit: 'hộp', current: 80000, value: '80.000' }, dirty: { unit: 'hộp', current: 80000, value: '85.000', dirty: true },
  empty: { unit: 'hộp', current: null, value: '' }, 'no-unit': { unit: null }, saving: { unit: 'hộp', current: 80000, value: '85.000', dirty: true, saving: true },
}[k]);

// ---------------------------------------------------------------- SP-12 khung giá

/**
 * VPageScaffold("Khung giá bán", subtitle, arrowBack). ListView đệm dọc 24: "ĐƠN VỊ & KHUNG GIÁ BÁN" caption bold (đệm 16 / 8), mỗi thẻ đệm 16 / 6:
 * ô (surface, viền borderDefault, bo 8, đệm 16): tên bold | chữ "Sửa" / "Thiết lập" màu success (InkWell, không vùng chạm 44); [ĐVT cơ sở: "Đơn vị cơ sở"]; khe 16;
 * 3 hàng "Giá cơ sở / Giá niêm yết / Giá sàn" (khe 8). Đơn vị tắt: nền background + "Đơn vị ngừng hoạt động" + VBadge "Không hoạt động".
 * Chưa có ĐVT: khung viền đứt + chân "Huỷ | Lưu thay đổi" (lưu luôn tắt). Lỗi: một dòng chữ giữa màn.
 */
export function priceBandsPage(s, v) {
  let body;
  if (s.loading) body = '<div class="t2-center"><span class="t2-spin t2-spin--material"></span></div>';
  else if (s.error) body = `<div class="t2-center"><p class="t2-centertext t2-centertext--plain">${esc(s.error)}</p></div>`;
  else if (s.noUnit) {
    body = `<div class="t2-create"><div class="t2-subscroll"><div class="t2-dashed"><p class="t2-body1">Cần thiết lập <b>đơn vị cơ sở</b> cho sản phẩm trước khi thiết lập khung giá bán.</p>${gap(8)}<p class="t2-small">Khung giá bán được tính theo đơn vị cơ sở của sản phẩm.</p></div></div>${formBar({ enabled: false, safe: true })}</div>`;
  } else {
    const row = (l, p) => `<div class="t2-pricerow"><span>${esc(l)}</span><b>${p != null ? esc(money(p)) : '—'}</b></div>`;
    const cardOf = (r) => (r.active === false
      ? `<div class="t2-bandcard is-off"><span><b>${esc(r.unit)}</b><small>Đơn vị ngừng hoạt động</small></span>${badge('Không hoạt động', { tone: 'neutral', small: true })}</div>`
      : `<div class="t2-bandcard"><div class="t2-bandcard__head"><b>${esc(r.unit)}</b><span class="t2-bandlink">${r.list != null ? 'Sửa' : 'Thiết lập'}</span></div>${r.isBase ? `${gap(4)}<small>Đơn vị cơ sở</small>` : ''}${gap(16)}${row('Giá cơ sở', r.base)}${gap(8)}${row('Giá niêm yết', r.list)}${gap(8)}${row('Giá sàn', r.floor)}</div>`);
    body = `<div class="t2-bandlist"><p class="t2-caps t2-caps--pad">ĐƠN VỊ &amp; KHUNG GIÁ BÁN</p>${s.rows.map((r) => `<div class="t2-bandwrap">${cardOf(r)}</div>`).join('')}</div>`;
  }
  return page(v, { title: 'Khung giá bán', subtitle: PRODUCT, body });
}
export const priceBandsState = (k) => ({
  default: { rows: [{ unit: 'hộp', isBase: true, base: 80000, list: 125000, floor: 110000 }, { unit: 'thùng', base: 1600000, list: null, floor: null }, { unit: 'két', active: false }] },
  loading: { loading: true }, 'no-unit': { noUnit: true }, error: { error: 'Đã xảy ra lỗi. Vui lòng thử lại.' },
}[k]);

// ---------------------------------------------------------------- SP-13 sửa khung giá một đơn vị

/**
 * VPageScaffold("Khung giá bán", subtitle — cùng tiêu đề với SP-12). Thân đệm 16: ô "Giá cơ sở / 1 hộp" | giá H4 bold; khe 16; ô (bo 8) VChoiceList "Cách tính"
 * 3 lựa chọn có mô tả; khe 16; ô chi tiết theo cách tính. Chữ trong các section dùng Text() không màu (màu chữ mặc định).
 */
export function editBandPage(s, v) {
  const base = 80000;
  const choices = [['storeRule', 'Theo khung giá cửa hàng', 'Tự động áp dụng khung giá cửa hàng.'], ['customConfig', 'Tự động riêng theo cấu hình', 'Tự động tính giá theo cấu hình của sản phẩm.'], ['manual', 'Nhập thủ công', 'Tự nhập giá cho đơn vị này.']];
  const choiceList = `<span class="t2-label">Cách tính</span>${choices.map(([k, l, h]) => `<div class="t2-choice2"><span class="t2-radio${s.type === k ? ' is-on' : ''}"></span><span><b>${esc(l)}</b><small>${esc(h)}</small></span></div>`).join('')}`;
  const prow = (l, p, bold = true) => `<div class="t2-pricerow t2-pricerow--plain"><span>${esc(l)}</span>${bold ? `<b>${p == null ? '—' : esc(money(p))}</b>` : `<span>${esc(p)}</span>`}</div>`;
  let detail;
  if (s.type === 'storeRule') {
    detail = `<p class="t2-small">Khung của cửa hàng đang áp dụng</p>${gap(16)}${prow('Giá niêm yết', ratioText(102400, base), false)}${gap(12)}${prow('Giá sàn', ratioText(91200, base), false)}${gap(16)}<hr class="t2-divider">${gap(16)}${prow('Giá niêm yết', 102400)}${gap(12)}${prow('Giá sàn', 91200)}`;
  } else if (s.type === 'customConfig') {
    const ratio = (l, val, p) => `<span class="t2-plainlabel">${esc(l)}</span>${gap(8)}<div class="t2-ratiorow"><span class="t2-w120">${input({ value: val, suffix: suffixText('%') })}</span><span>${p == null ? '= —' : `= ${esc(money(p))}`}</span></div>`;
    detail = `<p class="t2-small">Nhập cấu hình tính toán</p>${gap(16)}${ratio('Tỷ lệ giá niêm yết', '35', 108000)}${gap(16)}${ratio('Tỷ lệ giá sàn', '15', 92000)}${gap(16)}<hr class="t2-divider">${gap(16)}${prow('Giá niêm yết (dự kiến)', 108000)}${gap(12)}${prow('Giá sàn (dự kiến)', 92000)}${gap(16)}<div class="t2-notebox">Giá sẽ tự cập nhật khi Giá cơ sở thay đổi.</div>`;
  } else {
    const mrow = (l, val) => `<div class="t2-moneyrow"><span>${esc(l)}</span><span>${input({ value: val, suffix: suffixText('đ') })}</span></div>`;
    detail = `<p class="t2-small">Nhập giá thủ công</p>${gap(16)}${mrow('Giá niêm yết', '125.000')}${gap(16)}${mrow('Giá sàn', '110.000')}${gap(16)}<div class="t2-notebox">Giá sẽ không tự cập nhật khi Giá cơ sở thay đổi.</div>`;
  }
  const body = `<div class="t2-subscroll"><div class="t2-box8 t2-box8--row"><span><b>Giá cơ sở</b>${gap(4)}<small>1 hộp</small></span><strong>${esc(money(base))}</strong></div>${gap(16)}<div class="t2-box8">${choiceList}</div>${gap(16)}<div class="t2-box8">${detail}</div></div>`;
  return withToast(page(v, { title: 'Khung giá bán', subtitle: PRODUCT, body, bottomBar: formBar({ enabled: s.dirty }) }), v, s.toast);
}
export const editBandState = (k) => ({
  store: { type: 'storeRule' }, custom: { type: 'customConfig', dirty: true }, manual: { type: 'manual', dirty: true }, overwrite: { type: 'storeRule', dirty: true },
}[k]);

/** price_band_overwrite_dialog (showVAdaptiveSheet không tiêu đề): tiêu đề tự vẽ trong nội dung, câu, ô surfaceAlt "Niêm yết hiện tại / Sàn hiện tại", "Hủy" | "Ghi đè". */
export const overwriteSheet = () => `<div class="t2-lc"><h3 class="t2-h3">Ghi đè khung giá hiện tại?</h3>${gap(12)}<p class="t2-sheettext">Sản phẩm đã có khung giá bán. Áp dụng quy tắc cửa hàng sẽ thay thế giá hiện tại.</p>${gap(16)}<div class="t2-curbox"><span>Niêm yết hiện tại: ${esc(money(125000))}</span>${gap(4)}<span>Sàn hiện tại: ${esc(money(110000))}</span></div>${gap(24)}<div class="t2-btnrow16">${button('Hủy', { variant: 'secondary', full: true })}${button('Ghi đè', { full: true })}</div></div>`;
