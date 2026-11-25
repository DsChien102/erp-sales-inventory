// ID-01 Đăng nhập (+ ID-x1 lỗi mạng, ID-x2 banner tham gia tổ chức, ID-x4 chưa xác minh → /verify-email).
// Chép từ apps/erp/lib/features/auth/presentation/pages/login_page.dart (_LoginViewState.build).
// Scaffold nền surface, SafeArea, VContentWidth(authMaxWidth) canh trên, cuộn; cột cao tối thiểu = màn → Spacer đẩy dòng bản quyền xuống đáy.
import { banner, button, field, input, plainScaffold, toast } from './ds.js';

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
  const body = `<div class="t1-login">
    <div class="t1-login__logo" aria-hidden="true">V45</div>
    <h1 class="t1-login__brand">Mosaic Retail</h1>
    <p class="t1-login__tagline">Quản trị bán hàng thuốc thú y</p>
    ${s.resetSuccess ? `<div class="t1-login__banner">${banner('success', 'Cập nhật mật khẩu thành công', 'Mật khẩu đã được đặt lại. Vui lòng đăng nhập lại.')}</div>` : ''}
    ${s.joined ? `<div class="t1-login__banner">${banner('success', 'Tham gia tổ chức thành công', joinedMessage(s.joined))}</div>` : ''}
    <div class="t1-form t1-login__form">
      ${field({ label: 'Email', control: input({ value: s.email, hint: 'Nhập email', invalid: !!s.emailError }), error: s.emailError })}
      ${field({ label: 'Mật khẩu', control: input({ value: s.password, hint: 'Nhập mật khẩu', password: true, invalid: !!s.passwordError }), error: s.passwordError })}
      ${s.formError ? banner('error', 'Đăng nhập thất bại', s.formError) : ''}
    </div>
    <div class="t1-login__forgot">${button('Quên mật khẩu?', { variant: 'link', disabled: busy })}</div>
    ${button('Đăng nhập', { full: true, loading: busy, attrs: 'data-primary' })}
    ${button('Đăng ký cửa hàng mới', { variant: 'secondary', full: true, disabled: busy })}
    <p class="t1-login__ask">Bạn đã nhận được lời mời?</p>
    ${button('Kích hoạt tài khoản', { variant: 'link', disabled: busy })}
    <span class="t1-spacer"></span>
    <p class="t1-login__foot">© Mosaic Retail · Phiên bản Mobile</p>
  </div>`;
  return {
    page: plainScaffold({ body, width: v.width, cls: 't1-page--login' }),
    overlay: s.toast ? toast('success', 'Cập nhật mật khẩu thành công', 'Mật khẩu đã được đặt lại. Vui lòng đăng nhập lại.', { device: v.device }) : '',
  };
}
