// Bố cục WEB (khung ≥ 840), chọn qua impeccable live 2026-11-24. iPhone ở ../login.js; trạng thái mẫu, hàm kiểm, sheet dùng chung lấy từ đó.
import { banner, button, field, fieldError, fieldLabel, input, toast } from '../ds.js';
import { joinedMessage, STATES } from '../login.js';

export function loginPage(v) {
  const s = { email: '', password: '', ...STATES[v.state] };
  const busy = !!s.submitting;
  const banners = [
    s.resetSuccess ? banner('success', 'Cập nhật mật khẩu thành công', 'Mật khẩu đã được đặt lại. Vui lòng đăng nhập lại.') : '',
    s.joined ? banner('success', 'Tham gia tổ chức thành công', joinedMessage(s.joined)) : '',
  ].join('');
  // "Quên mật khẩu?" nằm cùng dòng nhãn Mật khẩu.
  const password = `<div class="t1-field${s.passwordError ? ' is-invalid' : ''}">
        <div class="t1-wlogin__labelrow">${fieldLabel('Mật khẩu')}${button('Quên mật khẩu?', { variant: 'link', disabled: busy })}</div>
        ${input({ value: s.password, hint: 'Nhập mật khẩu', password: true, invalid: !!s.passwordError })}${s.passwordError ? fieldError(s.passwordError) : ''}
      </div>`;
  const foot = '<p class="t1-wlogin__foot">© Mosaic Retail</p>';
  // Khối thương hiệu: dải nền surfaceBrand trên đầu (hẹp); cột trái 42% (≥ 900px), dòng bản quyền đáy cột.
  const page = `<div class="t1-page t1-page--surface t1-page--login"><div class="t1-scroll"><div class="t1-wlogin">
    <div class="t1-wlogin__panel">
      <div class="t1-wlogin__brand"><img class="t1-wlogin__logo" src="assets/app-icon.png" alt="" width="72" height="72"><div><h1 class="t1-wlogin__name">Mosaic Retail</h1><p class="t1-wlogin__tagline">Quản trị bán hàng thuốc thú y</p></div></div>
      ${foot}
    </div>
    <div class="t1-wlogin__main">
      <div class="t1-wlogin__form">
        ${banners ? `<div class="t1-wlogin__banners">${banners}</div>` : ''}
        ${field({ label: 'Email', control: input({ value: s.email, hint: 'Nhập email', invalid: !!s.emailError }), error: s.emailError })}
        ${password}
        ${s.formError ? banner('error', 'Đăng nhập thất bại', s.formError) : ''}
        ${button('Đăng nhập', { full: true, loading: busy, attrs: 'data-primary' })}
      </div>
      <div class="t1-wlogin__signup">${button('Đăng ký cửa hàng mới', { variant: 'secondary', full: true, disabled: busy })}</div>
      <div class="t1-wlogin__invite"><p>Bạn đã nhận được lời mời?</p>${button('Kích hoạt tài khoản', { variant: 'link', disabled: busy })}</div>
      <span class="t1-spacer"></span>
      ${foot}
    </div>
  </div></div></div>`;
  return {
    page,
    overlay: s.toast ? toast('success', 'Cập nhật mật khẩu thành công', 'Mật khẩu đã được đặt lại. Vui lòng đăng nhập lại.', { device: v.device }) : '',
  };
}
