// ID-01 Đăng nhập (+ ID-x1 lỗi mạng, ID-x2 banner tham gia tổ chức, ID-x4 chưa xác minh → /verify-email).
// Chép từ apps/erp/lib/features/auth/presentation/pages/login_page.dart (_LoginViewState.build).
// Bố cục chọn qua impeccable live (2026-11-24): khối thương hiệu riêng — dải đầu màn trên iPhone, cột trái trên web; form bên phải.
import { banner, button, field, fieldError, fieldLabel, input, toast } from './ds.js';

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

export function loginPage(v) {
  const s = { email: '', password: '', ...STATES[v.state] };
  const busy = !!s.submitting;
  const banners = [
    s.resetSuccess ? banner('success', 'Cập nhật mật khẩu thành công', 'Mật khẩu đã được đặt lại. Vui lòng đăng nhập lại.') : '',
    s.joined ? banner('success', 'Tham gia tổ chức thành công', joinedMessage(s.joined)) : '',
  ].join('');
  // "Quên mật khẩu?" nằm cùng dòng nhãn Mật khẩu.
  const password = `<div class="t1-field${s.passwordError ? ' is-invalid' : ''}">
        <div class="t1-login__labelrow">${fieldLabel('Mật khẩu')}${button('Quên mật khẩu?', { variant: 'link', disabled: busy })}</div>
        ${input({ value: s.password, hint: 'Nhập mật khẩu', password: true, invalid: !!s.passwordError })}${s.passwordError ? fieldError(s.passwordError) : ''}
      </div>`;
  const foot = '<p class="t1-login__foot">© Mosaic Retail · Phiên bản Mobile</p>';
  // Khối thương hiệu: dải nền surfaceBrand trên đầu (hẹp); cột trái 42% (≥ 900px), dòng bản quyền đáy cột.
  const page = `<div class="t1-page t1-page--surface t1-page--login"><div class="t1-scroll"><div class="t1-login">
    <div class="t1-login__panel">
      <div class="t1-login__brand"><div class="t1-login__logo" aria-hidden="true">V45</div><div><h1 class="t1-login__name">Mosaic Retail</h1><p class="t1-login__tagline">Quản trị bán hàng thuốc thú y</p></div></div>
      ${foot}
    </div>
    <div class="t1-login__main">
      <div class="t1-login__form">
        ${banners ? `<div class="t1-login__banners">${banners}</div>` : ''}
        ${field({ label: 'Email', control: input({ value: s.email, hint: 'Nhập email', invalid: !!s.emailError }), error: s.emailError })}
        ${password}
        ${s.formError ? banner('error', 'Đăng nhập thất bại', s.formError) : ''}
        ${button('Đăng nhập', { full: true, loading: busy, attrs: 'data-primary' })}
      </div>
      <div class="t1-login__signup">${button('Đăng ký cửa hàng mới', { variant: 'secondary', full: true, disabled: busy })}</div>
      <div class="t1-login__invite"><p>Bạn đã nhận được lời mời?</p>${button('Kích hoạt tài khoản', { variant: 'link', disabled: busy })}</div>
      <span class="t1-spacer"></span>
      ${foot}
    </div>
  </div></div></div>`;
  return {
    page,
    overlay: s.toast ? toast('success', 'Cập nhật mật khẩu thành công', 'Mật khẩu đã được đặt lại. Vui lòng đăng nhập lại.', { device: v.device }) : '',
  };
}
