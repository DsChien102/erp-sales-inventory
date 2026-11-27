// PT-05 Tạo / chỉnh sửa hồ sơ, PT-04 Sheet trùng hồ sơ, PT-06 Chọn khu vực hành chính, sheet "Rời khỏi màn hình?".
// Nguồn Flutter (apps/erp/lib/features/partner/):
//   presentation/pages/partner_create_page.dart (tiêu đề, leading VIconBox ←, PopScope + sheet rời màn)
//   widgets/{partner_create_form, partner_form_section, partner_section_shell, partner_role_section, partner_person_section,
//     partner_organization_section, partner_primary_contact_section, partner_invoice_section, partner_delivery_section,
//     partner_note_section, partner_outlined_field, partner_compact_field, partner_duplicate_sheet,
//     partner_administrative_unit_picker_sheet, partner_leave_form_dialog}.dart
//   logic/{partner_create_state, partner_create_cubit, partner_create_form_validator}.dart
// Route /partner/new và /partner/:id/edit khai báo ngoài ShellRoute → toàn màn, không thanh bên / thanh dưới (cả web).
// Không được dùng: partner_form_field_row.dart, partner_compact_field.dart (PartnerCompactTextField / Dropdown), partner_ward_search_dropdown.dart.
import { icon } from '../shared/icons.js';
import {
  adaptiveSheet, appBar, banner, button, card, centerLoading, checkbox, chip, esc, field, gap, iconBox, input,
  scaffold, searchBar, select, textArea,
} from './ds.js';
import { CAN_THO_WARDS, UNITS, dartCompare, foldVietnamese } from './data.js';
import { DESKTOP } from '../shared/shell.js';
import { formPageWeb } from './form-web.js';

// ---------------------------------------------------------------- hàm thuần (đối chiếu Dart)

/** PartnerCreateState.sections */
export function sections(type, edit) {
  if (type === 'person' || edit) return ['role', 'main', 'invoice', 'delivery', 'note'];
  return ['role', 'main', 'primaryContact', 'invoice', 'delivery', 'note'];
}

/** Tiêu đề mục (partner_create_form.dart _sections): số thứ tự 4 / 5 / 6 (cá nhân hoặc sửa) hay 5 / 6 / 7 (tạo tổ chức). */
export function sectionTitle(sec, type, edit) {
  const short = type === 'person' || edit;
  return {
    role: '2. Vai trò giao dịch',
    main: type === 'person' ? '3. Thông tin cá nhân' : '3. Thông tin tổ chức',
    primaryContact: '4. Người liên hệ chính',
    invoice: `${short ? 4 : 5}. Hóa đơn / thuế`,
    delivery: `${short ? 5 : 6}. Địa chỉ giao hàng`,
    note: `${short ? 6 : 7}. Ghi chú`,
  }[sec];
}

/** _PartnerFormViewState.build: tiêu đề. Lúc đang tải bản sửa, loại = fallbackPartnerType (luôn person ở PartnerCreatePage.edit). */
export function formTitle({ edit, type, loading }) {
  const t = loading ? 'person' : type;
  if (edit) return t === 'person' ? 'Chỉnh sửa cá nhân' : 'Chỉnh sửa tổ chức';
  return t === 'person' ? 'Tạo cá nhân' : 'Tạo tổ chức';
}

/** PartnerCreateState.canSubmit */
export function canSubmit(s) {
  if (s.blocked || s.loading || !s.roles.length) return false;
  if (s.edit && !s.dirty) return false;
  return s.type === 'person' ? !!(s.fullName.trim() && s.phone.trim()) : !!(s.organizationName.trim() && s.phone.trim());
}

/** VPhoneValidator.validate */
export function phoneError(value, required = false) {
  if (/[^0-9 ]/.test(value)) return 'Số điện thoại không hợp lệ';
  const digits = value.replace(/ /g, '');
  if (!digits) return required ? 'Vui lòng nhập số điện thoại' : null;
  return digits.length >= 9 && digits.length <= 11 ? null : 'Số điện thoại không hợp lệ';
}

/** _organizationInvoiceWarning (partner_invoice_section.dart) — chỉ tổ chức, chỉ cảnh báo (không chặn lưu). */
export function invoiceWarning({ type, taxCode = '', invoiceName = '', invoiceAddress = '' }) {
  if (type !== 'organization') return null;
  const missing = [];
  if (!taxCode.trim()) missing.push('MST');
  if (!invoiceName.trim()) missing.push('tên xuất hóa đơn');
  if (!invoiceAddress.trim()) missing.push('địa chỉ hóa đơn');
  if (!missing.length) return null;
  const join = missing.length === 1 ? missing[0] : missing.length === 2 ? `${missing[0]} và ${missing[1]}` : `${missing.slice(0, -1).join(', ')} và ${missing[missing.length - 1]}`;
  return `Thiếu ${join}. Vui lòng kiểm tra lại trước khi lưu.`;
}

/** _sections: chữ phụ bên phải khi mục đóng. */
export function sectionSummary(sec, s) {
  const nz = (x) => (x && x.trim() ? x.trim() : null);
  switch (sec) {
    case 'role': return s.roles.length === 2 ? 'KH & NCC' : s.roles.includes('customer') ? 'Khách hàng' : s.roles.includes('supplier') ? 'Nhà cung cấp' : null;
    case 'main': return s.type === 'person' ? nz(s.fullName) : nz(s.organizationName);
    case 'primaryContact': return s.primaryContactEnabled ? nz(s.primaryContactName) ?? 'Đã bật' : 'Tùy chọn';
    case 'invoice': return nz(s.taxCode);
    case 'delivery': return nz(s.deliveryProvince) ?? 'Tùy chọn';
    case 'note': return s.note.trim() ? 'Đã nhập' : 'Tùy chọn';
    default: return null;
  }
}

/** Sheet khu vực: danh sách tỉnh sắp theo String.compareTo (đơn vị mã UTF-16) rồi lọc theo chữ đã bỏ dấu. */
export function filterProvinces(query = '') {
  const sorted = [...UNITS].sort((a, b) => dartCompare(a[0], b[0]));
  if (!query) return sorted;
  const q = foldVietnamese(query);
  return sorted.filter(([n]) => foldVietnamese(n).includes(q));
}

// ---------------------------------------------------------------- mục form

/** PartnerSectionHeader: đệm 16; tiêu đề bodyDefault w700 (1 dòng); chữ phụ bodyDefault textSecondary ≤ 45% bề ngang; ô icon 24. */
function sectionHeader(title, trailingText, trailingIcon) {
  return `<div class="t3-sechead"><b>${esc(title)}</b>${trailingText ? `<span class="t3-sechead__sum">${esc(trailingText)}</span>` : ''}${trailingIcon ? `<i class="t3-sechead__icon">${trailingIcon}</i>` : ''}</div>`;
}

/** PartnerFormSection: viền borderDefault bo 12; mở → nội dung + (showActions) hàng "Bỏ qua" (tertiary, chữ primary) | "Tiếp" (small, rộng 112). */
function formSection({ title, open, done, summary, openTrailing = null, body = '', actions = true }) {
  const ic = open ? `<span class="is-sec">${icon('chevronUp')}</span>` : done ? `<span class="is-done">${icon('checkCircle')}</span>` : `<span class="is-sec">${icon('chevronDown')}</span>`;
  const acts = open && actions ? `<div class="t3-secacts">${button('Bỏ qua', { variant: 'tertiary', fg: 'primary' })}<span class="t3-secacts__next">${button('Tiếp', { size: 'small', full: true })}</span></div>` : '';
  return `<section class="t3-sec">${sectionHeader(title, open ? openTrailing : summary, ic)}${open ? body + acts : ''}</section>`;
}

const tf = (label, value, hint, { req = false, err = null } = {}) => field({ label, required: req, error: err, control: input({ value, hint, invalid: !!err }) });
const stack = (items) => items.map((x) => (typeof x === 'number' ? gap(x) : x)).join('');

function roleBody(s) {
  return `<div class="t3-secbody t3-secbody--b16"><p class="t3-small">Chọn vai trò giao dịch của hồ sơ này.</p>${gap(16)}
    <div class="t3-wrap">${chip('Khách hàng', { tone: s.roles.includes('customer') ? 'primary' : 'neutral' })}${chip('Nhà cung cấp', { tone: s.roles.includes('supplier') ? 'primary' : 'neutral' })}</div>
    ${s.errors.roles ? `${gap(8)}<p class="t3-small t3-small--danger">${esc(s.errors.roles)}</p>` : ''}</div>`;
}

function personBody(s) {
  const e = s.errors;
  return `<div class="t3-pad">${stack([
    tf('Danh xưng', s.personTitle, 'Nhập danh xưng'), 8,
    tf('Họ và tên', s.fullName, 'Nhập họ và tên', { req: true, err: e.fullName }), 16,
    tf('Tên thường gọi', s.nickname, 'Nhập tên thường gọi'), 16,
    tf('SĐT chính', s.phone, 'Nhập SĐT chính', { req: true, err: e.phone }), 16,
    tf('SĐT phụ', s.secondaryPhone, 'Nhập SĐT phụ', { err: e.secondaryPhone }), 16,
    tf('Email', s.email, 'Nhập email', { err: e.email }),
  ])}</div>`;
}

function orgBody(s) {
  const e = s.errors;
  return `<div class="t3-secbody t3-secbody--b4">${stack([
    field({ label: 'Loại tổ chức', control: select({ value: s.organizationTypeLabel, hint: 'Chọn loại tổ chức' }) }), 8,
    tf('Tên tổ chức', s.organizationName, 'Nhập tên tổ chức', { req: true, err: e.organizationName }), 8,
    tf('Tên viết tắt', s.shortName, 'Nhập tên viết tắt'), 8,
    tf('Tên quốc tế', s.internationalName, 'Nhập tên quốc tế'), 8,
    tf('SĐT chính', s.phone, 'Nhập SĐT chính', { req: true, err: e.phone }), 8,
    tf('Email', s.email, 'Nhập email', { err: e.email }),
  ])}</div>`;
}

function primaryContactBody(s) {
  const e = s.errors;
  const fields = s.primaryContactEnabled ? stack([16,
    tf('Danh xưng', s.primaryContactTitle, 'Nhập danh xưng'), 16,
    tf('Họ và tên', s.primaryContactName, 'Nhập họ và tên', { req: true, err: e.primaryContactName }), 16,
    tf('SĐT chính', s.primaryContactPhone, 'Nhập SĐT chính', { req: true, err: e.primaryContactPhone }), 16,
    tf('SĐT phụ', '', 'Nhập SĐT phụ'), 16,
    tf('Email', s.primaryContactEmail, 'Nhập email', { err: e.primaryContactEmail }),
  ]) : '';
  return `<div class="t3-pad">${checkbox('Thêm người liên hệ chính', s.primaryContactEnabled)}${fields}</div>`;
}

function invoiceBody(s) {
  const org = s.type === 'organization';
  const warn = invoiceWarning(s);
  return `<div class="t3-pad">${stack([
    tf('Mã số thuế', s.taxCode, 'Nhập MST (10 số, 12 số hoặc 10-3 số)', { req: org, err: s.errors.taxCode }), 8,
    tf('Tên xuất hóa đơn', s.invoiceName, 'Nhập tên xuất hóa đơn', { req: org }), 16,
    tf('Email nhận hóa đơn', s.invoiceEmail, 'Nhập email nhận hóa đơn', { err: s.errors.invoiceEmail }), 8,
    field({ label: 'Địa chỉ xuất hóa đơn', required: org, control: textArea({ value: s.invoiceAddress, hint: 'Nhập địa chỉ xuất hóa đơn', minLines: 3 }) }),
  ])}${warn ? `${gap(16)}${banner('warning', warn)}` : ''}</div>`;
}

/** _AdministrativeUnitTouchField: 44, đệm ngang 12, viền borderStrong (tắt: borderDefault 50% + nền surfaceAlt 50%), icon trước 18, chữ 14 (có giá trị w600). */
function unitField({ value, hint, ic, enabled = true }) {
  const trail = value ? `<span class="t3-unit__clear" aria-label="Xóa lựa chọn">${icon('close')}</span>` : `<i class="t3-unit__chev">${icon('chevronDown')}</i>`;
  return `<button type="button" class="t3-unit${value ? ' has-value' : ''}${enabled ? '' : ' is-disabled'}"${enabled ? '' : ' disabled'}><i class="t3-unit__lead">${icon(ic)}</i><span class="t3-unit__text">${esc(value || hint)}</span>${trail}</button>`;
}

function deliveryBody(s) {
  const label = (t) => `<span class="t3-label t3-label--small">${esc(t)}</span>`;
  const can = !!s.deliveryProvince;
  return `<div class="t3-pad">${stack([
    label('Tỉnh / Thành phố'), unitField({ value: s.deliveryProvince, hint: 'Chọn tỉnh / thành phố', ic: 'mapPin' }), 16,
    label('Xã / Phường'), unitField({ value: s.deliveryCommune, hint: can ? 'Chọn xã / phường' : 'Chọn tỉnh / thành phố trước', ic: 'building', enabled: can }), 16,
    field({ label: 'Địa chỉ chi tiết', control: textArea({ value: s.deliveryAddress, hint: 'Số nhà, tên đường...', minLines: 3 }) }),
  ])}</div>`;
}

function noteBody(s) {
  return `<div class="t3-secbody t3-secbody--b16"><p class="t3-small">Ghi chú nội bộ</p>${gap(8)}
    <div class="t3-note">${textArea({ value: s.note, minLines: 4, dense: true })}<span class="t3-note__count">${s.note.length}/500</span></div></div>`;
}

const BODIES = { role: roleBody, primaryContact: primaryContactBody, invoice: invoiceBody, delivery: deliveryBody, note: noteBody };

/** PartnerCreateForm: ListView đệm 16 (thẻ "1. Loại hồ sơ" khoá, banner lỗi chung, các mục cách 12) + _StickyActions. */
function formBody(s) {
  if (s.loading) return `<div class="t3-form">${centerLoading({ material: true })}</div>`;
  const locked = `<section class="t3-sec">${sectionHeader('1. Loại hồ sơ', s.type === 'person' ? 'Cá nhân' : 'Tổ chức', `<span class="is-muted">${icon('lock')}</span>`)}</section>`;
  const secs = sections(s.type, s.edit).map((sec) => {
    const body = sec === 'main' ? (s.type === 'person' ? personBody(s) : orgBody(s)) : BODIES[sec](s);
    return formSection({
      title: sectionTitle(sec, s.type, s.edit),
      open: s.active === sec,
      done: s.completed.includes(sec),
      summary: sectionSummary(sec, s),
      openTrailing: sec === 'primaryContact' ? 'Tùy chọn' : null,
      body,
      actions: sec !== 'note',
    });
  }).join('');
  const canPress = canSubmit(s) && !s.blocked && !s.submitting;
  const actions = `<div class="t3-sticky">${button('Hủy', { variant: 'secondary', full: true, disabled: s.submitting })}${button(s.edit ? 'Lưu thay đổi' : 'Lưu & Xem', { full: true, loading: s.submitting, disabled: !canPress })}</div>`;
  return `<div class="t3-form"><div class="t3-form__scroll"${s.scrollTo ? ` data-scroll-to="${s.scrollTo}"` : ''}>${locked}${s.generalError ? `${gap(12)}${banner('error', s.generalError)}` : ''}${gap(12)}${secs}${gap(4)}</div>${actions}</div>`;
}

/** PartnerCreatePage: VPageScaffold(title, showBackButton false, leading VIconBox(arrowBack, 40, nền trong)). */
export function formPage(s, v) {
  if (v.width >= DESKTOP) return formPageWeb(s); // Web: form + cột tóm tắt (form-web.js)
  const leading = `<span class="t3-iconbtn40">${iconBox({ ic: 'arrowLeft', size: 40, iconSize: 20, cls: 't3-ibox--clear' })}</span>`;
  return scaffold({ appbar: appBar(formTitle(s), { leading }), body: formBody(s), placeWidth: v.width, windowWidth: v.width });
}

// ---------------------------------------------------------------- sheet

/** PartnerDuplicateSheet (showVAdaptiveSheet không tiêu đề): đệm 16, cột canh giữa. */
export function duplicateSheet(level, matches) {
  const exact = level === 'exact';
  const matchCard = (m) => card(`<div class="t3-dupmatch">${iconBox({ ic: m.type === 'person' ? 'user' : 'building', size: 40, cls: 't3-ibox--brand' })}<div><b>${esc(m.name)}</b>${m.value ? `${gap(4)}<span>${esc(m.value)}</span>` : ''}</div></div>`, { pad: false, cls: 't3-card--p12' });
  const btns = exact
    ? `${button('Đi đến hồ sơ', { full: true })}${gap(8)}${button('Quay lại', { variant: 'secondary', full: true })}`
    : `${button('Tiếp tục tạo mới', { full: true })}${gap(8)}${button('Xem chi tiết', { variant: 'secondary', full: true })}`;
  return `<div class="t3-dup">
    ${iconBox({ ic: 'alert', size: 48, iconSize: 24, circle: true, cls: exact ? 't3-ibox--danger' : 't3-ibox--warning' })}${gap(12)}
    <h2 class="t3-dup__title">${exact ? 'Trùng khớp hoàn toàn' : 'Có thể là hồ sơ trùng'}</h2>${gap(8)}
    <p class="t3-dup__desc">${exact ? 'Đã tồn tại hồ sơ trùng khớp hoàn toàn. Không thể tạo mới.' : 'Tìm thấy các hồ sơ có thông tin tương tự. Vui lòng kiểm tra trước khi tạo mới.'}</p>${gap(16)}
    <div class="t3-dup__list">${matches.map((m) => `${matchCard(m)}${gap(8)}`).join('')}</div>${gap(8)}
    ${btns}
  </div>`;
}

/** _PartnerLeaveFormSheet (title "Rời khỏi màn hình?"): đệm 16 / 12 / 16 / 16; câu bodyDefault textSecondary; khe 24; hai nút. */
export const leaveSheet = () => `<div class="t3-leave"><p class="t3-body2">Những thay đổi chưa lưu sẽ bị mất.</p>${gap(24)}<div class="t3-grid2">${button('Ở lại chỉnh sửa', { variant: 'secondary', full: true })}${button('Rời khỏi', { tone: 'danger', full: true })}</div></div>`;

/**
 * PartnerAdministrativeUnitPickerSheet: cao 75% màn; hàng tiêu đề (đệm 16 / 4 / 8 / 8) + VSearchBar + khe 8 + hai bước + VDivider + danh sách.
 * p: { tab, province, ward, query }.
 */
export function pickerSheet(p, screenHeight) {
  const height = Math.round(screenHeight * 0.75);
  const step = (n, title, sub, { active, done, enabled = true }) => `<button type="button" class="t3-pstep${active ? ' is-active' : ''}${enabled ? '' : ' is-disabled'}"${enabled ? '' : ' disabled'}>
      <span class="t3-pstep__num${active ? ' is-active' : done ? ' is-done' : ''}">${done && !active ? icon('check') : n}</span>
      <span class="t3-pstep__text"><b>${esc(title)}</b>${sub ? `<small>${esc(sub)}</small>` : ''}</span></button>`;
  let list;
  if (p.tab === 0) {
    const items = filterProvinces(p.query);
    list = items.length
      ? `<ul class="t3-plist">${items.map(([n, c]) => `<li><button type="button" class="t3-pitem${n === p.province ? ' is-selected' : ''}">${icon('mapPin')}<span>${esc(n)}</span><small>${c} xã/phường</small>${n === p.province ? `<i class="t3-pitem__ok">${icon('checkCircle')}</i>` : ''}</button></li>`).join('')}</ul>`
      : `<div class="t3-pempty">${icon('searchOff')}${gap(8)}<b>Không tìm thấy tỉnh / thành phố</b>${p.query ? `${gap(4)}<span>Không có kết quả nào khớp với "${esc(p.query)}"</span>` : ''}</div>`;
  } else {
    list = `<ul class="t3-plist">${CAN_THO_WARDS.map((n) => `<li><button type="button" class="t3-pitem${n === p.ward ? ' is-selected' : ''}">${icon('building')}<span>${esc(n)}</span>${n === p.ward ? `<i class="t3-pitem__ok">${icon('checkCircle')}</i>` : ''}</button></li>`).join('')}</ul>`;
  }
  return `<div class="t3-picker" style="height:${height}px">
    <div class="t3-picker__head"><b>Khu vực hành chính</b><button type="button" class="t3-icon-btn t3-icon-btn--muted" aria-label="Đóng">${icon('close')}</button></div>
    <div class="t3-pad">${searchBar({ value: p.query || '', hint: p.tab === 0 ? 'Tìm kiếm tỉnh, thành phố...' : `Tìm kiếm xã, phường tại ${p.province || ''}...` })}</div>${gap(8)}
    <div class="t3-psteps">${step(1, 'Tỉnh / thành phố', p.province, { active: p.tab === 0, done: !!p.province })}<i class="t3-psteps__sep">${icon('chevronRight')}</i>${step(2, 'Xã / phường', p.ward, { active: p.tab === 1, done: !!p.ward, enabled: !!p.province })}</div>
    <hr class="t3-divider">
    ${list}
  </div>`;
}

// ---------------------------------------------------------------- ca → trạng thái

const EMPTY = {
  type: 'person', edit: false, loading: false, blocked: false, submitting: false, dirty: false, active: 'role', completed: [], roles: [], errors: {}, generalError: null,
  personTitle: '', fullName: '', nickname: '', phone: '', secondaryPhone: '', email: '',
  organizationTypeLabel: '', organizationName: '', shortName: '', internationalName: '',
  primaryContactEnabled: false, primaryContactTitle: '', primaryContactName: '', primaryContactPhone: '', primaryContactEmail: '',
  taxCode: '', invoiceName: '', invoiceAddress: '', invoiceEmail: '', deliveryProvince: '', deliveryCommune: '', deliveryAddress: '', note: '', scrollTo: null,
};
const PERSON = { ...EMPTY, roles: ['customer'], fullName: 'Nguyễn Văn Hùng', phone: '0912 345 678', dirty: true, completed: ['role'] };
const ORG = {
  ...EMPTY, type: 'organization', roles: ['customer', 'supplier'], dirty: true, completed: ['role', 'main'],
  organizationTypeLabel: 'Công ty', organizationName: 'Công ty TNHH Thú y An Phát', shortName: 'An Phát', phone: '0283 812 4567', email: 'lienhe@anphat.vn',
};
const ORG_SAVED = {
  ...ORG, edit: true, dirty: false, completed: [], active: 'role', taxCode: '0312345678', invoiceName: 'CÔNG TY TNHH THÚ Y AN PHÁT',
  invoiceAddress: '12 Nguyễn Văn Cừ, Phường An Bình, Thành phố Cần Thơ', invoiceEmail: 'ketoan@anphat.vn',
  deliveryProvince: 'Thành phố Cần Thơ', deliveryCommune: 'Phường An Bình', deliveryAddress: '12 Nguyễn Văn Cừ', note: 'Giao hàng buổi sáng.',
};

/** Trạng thái form của từng ca. */
export function formState(state) {
  switch (state) {
    case 'person-new': return { ...EMPTY };
    case 'person-role-error': return { ...EMPTY, errors: { roles: 'Vui lòng chọn vai trò giao dịch' } };
    case 'person-main': return { ...PERSON, active: 'main', fullName: '', phone: '' };
    case 'person-main-filled': return { ...PERSON, active: 'main', personTitle: 'Anh', nickname: 'Anh Hùng', email: 'hung.nv@gmail.com' };
    case 'person-main-errors': return { ...PERSON, active: 'main', fullName: '', phone: '0912 34', email: 'hung.nv@', errors: { fullName: 'Vui lòng nhập họ và tên', phone: 'Số điện thoại không hợp lệ', email: 'Email không hợp lệ' } };
    case 'person-collapsed': return { ...PERSON, active: null, completed: ['role', 'main', 'invoice'], taxCode: '8012345678' };
    case 'person-invoice': return { ...PERSON, active: 'invoice', completed: ['role', 'main'], taxCode: '8012345678', errors: {} };
    case 'org-new': return { ...EMPTY, type: 'organization' };
    case 'org-main': return { ...ORG, active: 'main', completed: ['role'] };
    case 'org-contact-off': return { ...ORG, active: 'primaryContact' };
    case 'org-contact': return { ...ORG, active: 'primaryContact', primaryContactEnabled: true, primaryContactTitle: 'Chị', primaryContactName: 'Phạm Thu Hà', primaryContactPhone: '0905 667 788' };
    case 'org-invoice': return { ...ORG, active: 'invoice', completed: ['role', 'main', 'primaryContact'], scrollTo: 'end' };
    case 'org-invoice-partial': return { ...ORG, active: 'invoice', completed: ['role', 'main', 'primaryContact'], taxCode: '0312345678', errors: {}, scrollTo: 'end' };
    case 'delivery-empty': return { ...ORG, active: 'delivery', completed: ['role', 'main', 'primaryContact', 'invoice'] };
    case 'delivery': return { ...ORG, active: 'delivery', completed: ['role', 'main', 'primaryContact', 'invoice'], deliveryProvince: 'Thành phố Cần Thơ', deliveryCommune: 'Phường An Bình', deliveryAddress: '12 Nguyễn Văn Cừ' };
    case 'note': return { ...ORG, active: 'note', completed: ['role', 'main', 'primaryContact', 'invoice', 'delivery'], deliveryProvince: 'Thành phố Cần Thơ', note: 'Khách quen, ưu tiên giao trước 10 giờ.', scrollTo: 'end' };
    case 'submitting': return { ...PERSON, active: null, completed: ['role', 'main'], submitting: true };
    case 'general-error': return { ...PERSON, active: null, completed: ['role', 'main'], generalError: 'Không thể lưu dữ liệu. Vui lòng thử lại.' };
    case 'blocked': return { ...PERSON, active: null, completed: ['role', 'main'], blocked: true, generalError: 'Bạn chưa có quyền tạo KH & NCC.' };
    case 'edit-loading': return { ...ORG_SAVED, loading: true };
    case 'edit': return { ...ORG_SAVED };
    case 'edit-dirty': return { ...ORG_SAVED, active: 'main', dirty: true, phone: '0283 812 9999' };
    case 'edit-conflict': return { ...ORG_SAVED, active: null, dirty: true, generalError: 'Hồ sơ đã được cập nhật bởi người khác. Vui lòng tải lại rồi thử lại.' };
    default: return { ...EMPTY };
  }
}

export const DUP_EXACT = [{ type: 'person', name: 'Nguyễn Văn Hùng', value: 'SĐT: 0912345678' }];
export const DUP_POSSIBLE = [
  { type: 'organization', name: 'Công ty TNHH Thú y An Phát', value: 'Tên: Công ty TNHH Thú y An Phát' },
  { type: 'organization', name: 'Thú y An Phát (chi nhánh Cái Răng)', value: 'Email: lienhe@anphat.vn' },
];
