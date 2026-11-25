// ID-01 Đăng nhập (+ ID-x1 lỗi mạng, ID-x2 banner tham gia tổ chức, ID-x4 chưa xác minh → /verify-email).
// Chữ, trạng thái, câu lỗi chép từ apps/erp/lib/features/auth/presentation/pages/login_page.dart (_LoginViewState.build).
// Bố cục iPhone thiết kế lại qua impeccable live (2026-11-25): nền canvas, thương hiệu căn giữa, thẻ form (Quên mật khẩu? dưới nút chính),
// danh sách hai dòng Đăng ký cửa hàng mới / Kích hoạt tài khoản. Web ở web/login.js.
// Cột cao tối thiểu = màn → Spacer đẩy dòng bản quyền xuống đáy.
import { icon } from '../shared/icons.js';
import { authColumn, banner, button, card, field, input, toast } from './ds.js';

export const MSG = {
  emailRequired: 'Vui lòng nhập email', // VEmailValidator(requiredEmailMessage)
  passwordRequired: 'Vui lòng nhập mật khẩu', // VPasswordValidator.defaultRequiredPasswordMessage
  invalidCredentials: 'Email hoặc mật khẩu không chính xác.', // IamUiFailureMapper: hiện dưới ô Email, không toast
  network: 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.', // IamUiFailureMapper (AppErrorCode.network)
  resetNeedsEmail: 'Vui lòng nhập email trước khi đặt lại mật khẩu',
};

/** Câu banner sau khi kích hoạt lời mời (joinedMessage). */
export function joinedMessage(orgName) {
  const name = String(orgName ?? '').trim();
  return name
    ? `Đã tham gia tổ chức "${name}" thành công. Đăng nhập để vào Mosaic Retail.`
    : 'Đã tham gia tổ chức thành công. Đăng nhập để vào Mosaic Retail.';
}

export const STATES = {
  default: {},
  'empty-submit': { emailError: MSG.emailRequired, passwordError: MSG.passwordRequired },
  'wrong-credentials': { email: 'lan@anphat.vn', password: 'matkhau12', emailError: MSG.invalidCredentials },
  network: { email: 'lan@anphat.vn', password: 'matkhau12', formError: MSG.network },
  submitting: { email: 'lan@anphat.vn', password: 'matkhau12', submitting: true },
  'forgot-no-email': { emailError: MSG.resetNeedsEmail },
  joined: { email: 'minh@anphat.vn', joined: 'Thú y An Phát' },
  'reset-success': { email: 'lan@anphat.vn', resetSuccess: true },
  'reset-toast': { email: 'lan@anphat.vn', toast: true },
};

/** Dòng lối vào: icon 20 + (câu hỏi nhỏ) + tên việc + mũi tên; cao tối thiểu 60. */
const entryRow = (ic, title, { ask = '', disabled = false } = {}) => `<button type="button" class="t1-login__row"${disabled ? ' disabled' : ''}>${icon(ic, 't1-login__rowic')}<span class="t1-login__rowtext">${ask ? `<small>${ask}</small>` : ''}<b>${title}</b></span>${icon('chevronRight', 't1-login__rowgo')}</button>`;

export function loginPage(v) {
  const s = { email: '', password: '', ...STATES[v.state] };
  const busy = !!s.submitting;
  const form = `<div class="t1-form">
      ${field({ label: 'Email', control: input({ value: s.email, hint: 'Nhập email', invalid: !!s.emailError }), error: s.emailError })}
      ${field({ label: 'Mật khẩu', control: input({ value: s.password, hint: 'Nhập mật khẩu', password: true, invalid: !!s.passwordError }), error: s.passwordError })}
      ${s.formError ? banner('error', 'Đăng nhập thất bại', s.formError) : ''}
      ${button('Đăng nhập', { full: true, loading: busy, attrs: 'data-primary', cls: 't1-login__cta' })}
      <div class="t1-login__forgot">${button('Quên mật khẩu?', { variant: 'link', disabled: busy })}</div>
    </div>`;
  const body = `<div class="t1-login">
    <div class="t1-login__brand">
      <img class="t1-login__logo" src="assets/app-icon.png" alt="" width="64" height="64">
      <div><h1 class="t1-login__name">Mosaic Retail</h1><p class="t1-login__tagline">Quản trị bán hàng thuốc thú y</p></div>
    </div>
    ${s.resetSuccess ? `<div class="t1-login__banner">${banner('success', 'Cập nhật mật khẩu thành công', 'Mật khẩu đã được đặt lại. Vui lòng đăng nhập lại.')}</div>` : ''}
    ${s.joined ? `<div class="t1-login__banner">${banner('success', 'Tham gia tổ chức thành công', joinedMessage(s.joined))}</div>` : ''}
    ${card(form, 't1-login__card')}
    ${card(entryRow('store', 'Đăng ký cửa hàng mới', { disabled: busy }) + entryRow('mail', 'Kích hoạt tài khoản', { ask: 'Bạn đã nhận được lời mời?', disabled: busy }), 't1-login__list')}
    <span class="t1-spacer"></span>
    <p class="t1-login__foot">© Mosaic Retail · Phiên bản Mobile</p>
  </div>`;
  return {
    page: `<div class="t1-page t1-page--canvas t1-page--login"><div class="t1-scroll"><div class="t1-col" style="max-width:${authColumn(v.width)}">${body}</div></div></div>`,
    overlay: s.toast ? toast('success', 'Cập nhật mật khẩu thành công', 'Mật khẩu đã được đặt lại. Vui lòng đăng nhập lại.', { device: v.device }) : '',
  };
}
