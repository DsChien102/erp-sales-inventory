// Bố cục WEB (khung ≥ 840), chọn qua impeccable live 2026-11-24. iPhone ở ../signup.js; trạng thái mẫu, hàm kiểm, sheet dùng chung lấy từ đó.
import { adaptiveSheet, appBar, banner, button, esc, field, input, progressBar } from '../ds.js';
import { EMPTY_ACCOUNT, emailExists, PASSWORD_RULE, pickerBody, STATES, STEP_TITLES, storeStep } from '../signup.js';
import { verifyView } from './verify.js';

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
  ${button('Tiếp tục', { full: true })}`;
}

export function signupPage(v) {
  const s = STATES[v.state];
  let content;
  if (s.emailExists) content = emailExists();
  else if (s.step === 0) content = accountStep(s);
  else if (s.step === 1) content = storeStep(s);
  else content = verifyView(v, { state: s.verify, email: 'lan@anphat.vn', cooldown: 59 });
  const cur = s.emailExists ? 1 : s.step;
  // Thanh tiến độ 3 đoạn + thẻ trắng trên nền canvas; tiêu đề thẻ = tên bước. Chọn qua impeccable live (2026-11-24).
  const body = `<div class="t1-stepcol">
    ${progressBar(STEP_TITLES, cur)}
    <div class="t1-stepcard">
      <h2 class="t1-stepcard__title">${esc(STEP_TITLES[cur])}</h2>
      ${s.failure ? `${banner('error', s.failure)}<div class="t1-gap-md"></div>` : ''}
      ${content}
    </div>
    ${cur === 0 && !s.emailExists ? `<div class="t1-center-row t1-stepcol__after">${button('Đã có tài khoản? Đăng nhập', { variant: 'link' })}</div>` : ''}
  </div>`;
  const overlay = s.picker ? adaptiveSheet(v.width, pickerBody(s.picker, Math.round(v.height * 0.75)), 'Khu vực hành chính') : '';
  return { page: `<div class="t1-page t1-page--canvas">${appBar('Đăng ký cửa hàng', { back: true })}<div class="t1-scroll">${body}</div></div>`, overlay };
}
