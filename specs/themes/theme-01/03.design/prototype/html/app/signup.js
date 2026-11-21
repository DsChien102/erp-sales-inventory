// ID-02 Đăng ký cửa hàng (3 bước). Chép từ:
//   apps/erp/lib/features/auth/presentation/pages/signup_page.dart (_SignupViewState: _accountStep, _storeStep, _emailExists, _field)
//   apps/erp/lib/features/auth/logic/signup_cubit.dart (_accountErrors, _storeErrors)
//   apps/erp/lib/core/widgets/address/{administrative_units_form_section.dart, vn_administrative_unit_picker_sheet.dart}
//   bước 3 = VerifyEmailView (verify.js)
// Scaffold nền surface + VAppBar('Đăng ký cửa hàng', nút ←) hết bề ngang; ListView đệm 16 trong cột 480.
import { icon } from '../shared/icons.js';
import { adaptiveSheet, appBar, banner, button, esc, field, fieldError, input, plainScaffold, steps } from './ds.js';
import { verifyView } from './verify.js';

export const STEP_TITLES = ['Tài khoản', 'Cửa hàng', 'Xác minh email'];
export const PASSWORD_RULE = 'Tối thiểu 8 ký tự, gồm 1 số và 1 ký tự đặc biệt.'; // PasswordPolicy.requirementText

/** _accountErrors (signup_cubit.dart). */
export function accountErrors(a) {
  const e = {};
  if (!a.familyName.trim()) e.familyName = 'Vui lòng nhập họ và tên đệm';
  if (!a.givenName.trim()) e.givenName = 'Vui lòng nhập tên';
  const email = a.email.trim();
  if (!email || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) e.email = 'Email không hợp lệ';
  const phone = (a.phone || '').trim();
  if (phone && !validPhone(phone)) e.phone = 'Số điện thoại phải có 9–11 chữ số';
  if (policyError(a.password)) e.password = a.password.length < 8 ? 'Mật khẩu phải có ít nhất 8 ký tự' : policyError(a.password);
  if (a.password !== a.confirmPassword) e.confirmPassword = 'Mật khẩu xác nhận không khớp';
  return e;
}
/** _storeErrors (signup_cubit.dart). Email liên hệ không kiểm. */
export function storeErrors(s) {
  const e = {};
  if (!s.name.trim()) e.storeName = 'Vui lòng nhập tên cửa hàng';
  if (!validPhone(s.contactPhone)) e.storePhone = 'Số điện thoại phải có 9–11 chữ số';
  if (!s.provinceCode.trim()) e.province = 'Vui lòng chọn tỉnh / thành phố';
  if (!s.communeCode.trim()) e.commune = 'Vui lòng chọn xã / phường';
  if (!s.addressText.trim()) e.address = 'Vui lòng nhập địa chỉ cửa hàng';
  return e;
}
const validPhone = (p) => /^\d{9,11}$/.test(String(p).replace(/[\s.-]/g, ''));
/** PasswordPolicy.validate: rỗng / < 8 / thiếu số / thiếu ký tự đặc biệt → violationMessage. */
export function policyError(pw) {
  if (!pw) return 'Vui lòng nhập mật khẩu';
  if (pw.length < 8 || !/\d/.test(pw) || !/[^A-Za-z0-9]/.test(pw)) return 'Mật khẩu phải có ít nhất 8 ký tự, gồm 1 số và 1 ký tự đặc biệt';
  return null;
}

const EMPTY_ACCOUNT = { familyName: '', givenName: '', email: '', phone: '', password: '', confirmPassword: '' };
const ACCOUNT = { familyName: 'Nguyễn Thị', givenName: 'Lan', email: 'lan@anphat.vn', phone: '0912 345 678', password: 'AnPhat@2026', confirmPassword: 'AnPhat@2026' };
const STORE = { name: 'Thú y An Phát', contactPhone: '0283 456 789', province: 'Thành phố Hồ Chí Minh', commune: 'Phường An Lạc', addressText: '125 Kinh Dương Vương', contactEmail: 'lan@anphat.vn' };
const EMPTY_STORE = { name: '', contactPhone: '', province: '', commune: '', addressText: '', contactEmail: 'lan@anphat.vn' };

export const STATES = {
  account: { step: 0, account: EMPTY_ACCOUNT },
  'account-errors': { step: 0, account: { ...EMPTY_ACCOUNT, email: 'lan@anphat', password: 'abc' }, errors: accountErrors({ ...EMPTY_ACCOUNT, email: 'lan@anphat', password: 'abc' }) },
  store: { step: 1, store: EMPTY_STORE },
  'store-errors': { step: 1, store: EMPTY_STORE, errors: storeErrors({ name: '', contactPhone: '', provinceCode: '', communeCode: '', addressText: '' }) },
  'store-filled': { step: 1, store: STORE },
  'picker-province': { step: 1, store: EMPTY_STORE, picker: { tab: 0 } },
  'picker-ward': { step: 1, store: { ...EMPTY_STORE, province: 'Thành phố Hồ Chí Minh' }, picker: { tab: 1, province: 'Thành phố Hồ Chí Minh' } },
  'store-submitting': { step: 1, store: STORE, submitting: true },
  'server-error': { step: 1, store: STORE, failure: 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.' },
  'email-exists': { step: 1, emailExists: true },
  verify: { step: 2, verify: 'default' },
  'verify-error': { step: 2, verify: 'error' },
};

function accountStep(s) {
  const a = { ...EMPTY_ACCOUNT, ...s.account };
  const e = s.errors || {};
  const f = (label, key, ctl, { required = true, desc } = {}) => field({ label, required, control: ctl({ invalid: !!e[key] }), error: e[key], desc });
  return `<div class="t1-form">
    ${f('Họ và tên đệm', 'familyName', (o) => input({ ...o, value: a.familyName, hint: 'Nguyễn Thị' }))}
    ${f('Tên', 'givenName', (o) => input({ ...o, value: a.givenName, hint: 'Lan' }))}
    ${f('Email', 'email', (o) => input({ ...o, value: a.email, hint: 'lan@example.com' }))}
    ${f('Số điện thoại', 'phone', (o) => input({ ...o, value: a.phone, hint: '0912 345 678' }), { required: false })}
    ${f('Mật khẩu', 'password', (o) => input({ ...o, value: a.password, hint: 'Nhập mật khẩu', password: true }), { desc: PASSWORD_RULE })}
    ${f('Nhập lại mật khẩu', 'confirmPassword', (o) => input({ ...o, value: a.confirmPassword, hint: 'Nhập lại mật khẩu', password: true }))}
  </div>
  <div class="t1-gap-lg"></div>
  ${button('Tiếp tục', { full: true })}
  <div class="t1-gap-md"></div>
  <div class="t1-center-row">${button('Đã có tài khoản? Đăng nhập', { variant: 'link' })}</div>`;
}

/**
 * _AdministrativeUnitTouchField: cao 44, đệm ngang 12, viền 1 borderDefault (không phải borderInput như ô nhập), bo 8;
 * icon trước 18 textSecondary, chữ bodyDefault (gợi ý textSecondary), nút xoá 16 khi có giá trị, mũi tên xuống 20.
 * Tắt (chưa có tỉnh): nền surfaceAlt, viền borderDefault 50%, chữ / icon textMuted.
 */
function unitField({ value, hint, ic, enabled = true, invalid = false }) {
  const cls = ['t1-unit', enabled ? '' : 'is-disabled', invalid ? 'is-invalid' : '', value ? 'has-value' : ''].filter(Boolean).join(' ');
  return `<button type="button" class="${cls}"${enabled ? '' : ' disabled'}>${icon(ic, 't1-unit__lead')}<span class="t1-unit__text">${esc(value || hint)}</span>${value ? `<span class="t1-unit__clear" aria-label="Xoá">${icon('close')}</span>` : ''}${icon('chevronDown', 't1-unit__chev')}</button>`;
}

export function unitSection({ province = '', commune = '', provinceError, communeError, required = true }) {
  return `<div class="t1-form">
    ${field({ label: 'Tỉnh / thành phố', required, control: unitField({ value: province, hint: 'Chọn tỉnh / thành phố', ic: 'mapPin', invalid: !!provinceError }), error: provinceError })}
    ${field({ label: 'Xã / phường', required, control: unitField({ value: commune, hint: province ? 'Chọn xã / phường' : 'Chọn tỉnh / thành phố trước', ic: 'building', enabled: !!province, invalid: !!communeError }), error: communeError })}
  </div>`;
}

function storeStep(s) {
  const st = { ...EMPTY_STORE, ...s.store };
  const e = s.errors || {};
  const busy = !!s.submitting;
  return `<div class="t1-form">
    ${field({ label: 'Tên cửa hàng', required: true, control: input({ value: st.name, hint: 'Thú y An Phát', invalid: !!e.storeName }), error: e.storeName })}
    ${field({ label: 'Số điện thoại cửa hàng', required: true, control: input({ value: st.contactPhone, hint: '0912 345 678', invalid: !!e.storePhone }), error: e.storePhone })}
    ${unitSection({ province: st.province, commune: st.commune, provinceError: e.province, communeError: e.commune })}
    ${field({ label: 'Địa chỉ chi tiết', required: true, control: input({ value: st.addressText, hint: 'Số nhà, tên đường...', invalid: !!e.address }), error: e.address })}
    ${field({ label: 'Email liên hệ', control: input({ value: st.contactEmail, hint: 'lan@example.com' }) })}
    <p class="t1-small">Thông tin pháp lý (mã số thuế) có thể bổ sung sau trong Hồ sơ tổ chức.</p>
  </div>
  <div class="t1-gap-lg"></div>
  <div class="t1-row2">
    ${button('Quay lại', { variant: 'secondary', disabled: busy })}
    ${button(busy ? 'Đang tạo...' : 'Tạo cửa hàng', { loading: busy })}
  </div>`;
}

function emailExists() {
  return `<div class="t1-field is-invalid">${fieldError('Email đã được đăng ký')}</div>
  <div class="t1-gap-lg"></div>
  ${button('Đăng nhập', { full: true })}
  <div class="t1-gap-md"></div>
  ${button('Quên mật khẩu', { variant: 'link' })}`;
}

// ---------------------------------------------------------------- sheet chọn khu vực (vn_administrative_unit_picker_sheet.dart)

// Tên đầy đủ theo assets/data/vn_administrative_units.json, sắp như Dart String.compareTo (theo mã ký tự: "Đ…" xuống cuối).
export const PROVINCES = ['Thành phố Cần Thơ', 'Thành phố Huế', 'Thành phố Hà Nội', 'Thành phố Hải Phòng', 'Thành phố Hồ Chí Minh', 'Thành phố Đà Nẵng', 'Thành phố Đồng Nai', 'Tỉnh An Giang', 'Tỉnh Bắc Ninh', 'Tỉnh Cao Bằng', 'Tỉnh Cà Mau', 'Tỉnh Gia Lai', 'Tỉnh Hà Tĩnh', 'Tỉnh Hưng Yên', 'Tỉnh Khánh Hoà', 'Tỉnh Lai Châu'];
export const HCM_WARDS = ['Phường An Hội Tây', 'Phường An Hội Đông', 'Phường An Khánh', 'Phường An Lạc', 'Phường An Nhơn', 'Phường An Phú', 'Phường An Phú Đông', 'Phường An Đông', 'Phường Bà Rịa', 'Phường Bàn Cờ'];

/**
 * Nội dung sheet: SizedBox cao 75% màn; hàng tiêu đề (đệm 16 / 4 / 8 / 8) "Khu vực hành chính" headingH4 w700 + nút Đóng (Icons.close, textSecondary);
 * VSearchBar (đệm ngang 16); khe 8; hai tab bước (bodySmall, gạch dưới 2.5 primary) ngăn bởi mũi tên 20 borderStrong; VDivider; danh sách (đệm 16 / 8, dòng đệm 12 / 8, ngăn VDivider).
 */
function pickerBody({ tab, province }, height) {
  const tabItem = (i, label, { active, done, enabled = true }) => `<button type="button" class="t1-ptab${active ? ' is-active' : ''}${done ? ' is-done' : ''}"${enabled ? '' : ' disabled'}>${done && !active ? icon('checkCircle') : ''}<span>${esc(label)}</span></button>`;
  const items = tab === 0 ? PROVINCES : HCM_WARDS;
  return `<div class="t1-picker" style="height:${height}px">
    <div class="t1-picker__head"><b>Khu vực hành chính</b><button type="button" class="t1-icon-btn t1-icon-btn--muted" aria-label="Đóng">${icon('close')}</button></div>
    <label class="t1-search">${icon('search')}<input type="search" placeholder="${esc(tab === 0 ? 'Tìm kiếm tỉnh, thành phố...' : `Tìm kiếm xã, phường tại ${province}...`)}"></label>
    <div class="t1-picker__tabs">
      ${tabItem(0, province || 'Tỉnh / thành phố', { active: tab === 0, done: !!province })}
      <span class="t1-picker__sep">${icon('chevronRight')}</span>
      ${tabItem(1, 'Xã / phường', { active: tab === 1, enabled: !!province })}
    </div>
    <ul class="t1-picker__list">${items.map((n) => `<li><button type="button" class="t1-picker__item${n === province ? ' is-selected' : ''}"><span>${esc(n)}</span>${n === province ? icon('checkCircle') : ''}</button></li>`).join('')}</ul>
  </div>`;
}

export function signupPage(v) {
  const s = STATES[v.state];
  let content;
  if (s.emailExists) content = emailExists();
  else if (s.step === 0) content = accountStep(s);
  else if (s.step === 1) content = storeStep(s);
  else content = verifyView(v, { state: s.verify, email: 'lan@anphat.vn', cooldown: 59 });
  const body = `<div class="t1-list">
    ${steps(STEP_TITLES, s.emailExists ? 1 : s.step)}
    <div class="t1-gap-lg"></div>
    ${s.failure ? `${banner('error', s.failure)}<div class="t1-gap-md"></div>` : ''}
    ${content}
  </div>`;
  const overlay = s.picker ? adaptiveSheet(v.width, pickerBody(s.picker, Math.round(v.height * 0.75)), 'Khu vực hành chính') : '';
  return { page: plainScaffold({ appbar: appBar('Đăng ký cửa hàng', { back: true }), body, width: v.width }), overlay };
}
