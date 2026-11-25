// ID-04 Quên mật khẩu (/login/reset-password) và ID-23 Đặt lại mật khẩu khi đã đăng nhập (/more/my-account/reset-password):
// cùng một ResetPasswordPage(authRepository) → cùng giao diện; khác nhau chỉ ở email nhận mã và nơi quay về.
// Chép từ apps/erp/lib/features/iam/presentation/users/views/reset_password_page.dart (_ResetPasswordBodyState, _PasswordBottomBar)
//   + widgets/{reset_password_verify_code_step.dart, reset_password_create_password_step.dart}
// Bố cục iPhone thiết kế lại qua impeccable live (2026-11-25): nền surface, thanh 2 bước, tiêu đề canh trái; chữ, trạng thái giữ nguyên Flutter. Web ở web/reset.js.
import { appBar, authColumn, busyOverlay, button, card, centerLoading, codeField, field, input, progressBar, toast } from './ds.js';
import { PASSWORD_RULE } from './signup.js';
import { maskEmail } from './verify.js';

/** Nhãn nút gửi lại ở bước 1: luôn "00:" + giây (khác ResendCountdown của đăng ký, dùng mm:ss). */
export function resetResendLabel(seconds) {
  return seconds > 0 ? `Gửi lại mã sau 00:${String(seconds).padStart(2, '0')}` : 'Gửi lại mã';
}

export const STATES = {
  requesting: { phase: 'requesting' },
  'request-failed': { phase: 'request-failed', toast: ['danger', 'Không gửi được mã', 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.'] },
  verify: { phase: 'verify', seconds: 59 },
  'verify-filled': { phase: 'verify', seconds: 42, code: '482915' },
  verifying: { phase: 'verify', seconds: 40, code: '482915', busy: true },
  'verify-wrong': { phase: 'verify', seconds: 31, code: '482915', toast: ['danger', 'Không thể tiếp tục', 'Mã xác minh không đúng hoặc đã hết hạn.'] },
  'resend-ready': { phase: 'verify', seconds: 0 },
  'resent-toast': { phase: 'verify', seconds: 60, toast: ['info', 'Thông báo', 'Đã gửi lại mã xác nhận.'] },
  create: { phase: 'create' },
  'create-filled': { phase: 'create', pw: 'AnPhat@2026', confirm: 'AnPhat@2026' },
  'create-errors': { phase: 'create', pw: 'abc', confirm: 'abcd', pwError: 'Mật khẩu phải có ít nhất 8 ký tự, gồm 1 số và 1 ký tự đặc biệt', confirmError: 'Mật khẩu nhập lại không trùng khớp', toast: ['danger', 'Không thể đặt lại mật khẩu', 'Vui lòng kiểm tra lại thông tin mật khẩu bên dưới.'] },
  'create-submitting': { phase: 'create', pw: 'AnPhat@2026', confirm: 'AnPhat@2026', busy: true },
  'from-account': { phase: 'verify', seconds: 59, account: true },
};

const RESET_STEPS = ['Xác minh email', 'Tạo mật khẩu mới']; // TH-01 FR-01

/**
 * Bước 1: thanh 2 bước → khe 24 → tiêu đề → lời nhắc → khe 24 → ô mã (sáu ô cao 56 trải hết bề ngang) → ghi chú 10 phút
 * → khe 24 → "Xác nhận mã" → khe 8 → gửi lại (giữa): còn đếm ngược là chữ textSecondary, hết là nút link.
 */
function verifyStep(s, v, email) {
  const col = Math.min(v.width, v.width >= 600 ? 480 : v.width) - 32;
  const code = s.code || '';
  const label = resetResendLabel(s.seconds);
  return `<div class="t1-list t1-reset">
    ${progressBar(RESET_STEPS, 0)}
    <h2 class="t1-reset__title">Xác minh email</h2>
    <p class="t1-body2 t1-reset__prompt">Mã 6 chữ số đã được gửi tới <b>${maskEmail(email)}</b>. Xác nhận mã để tạo mật khẩu mới.</p>
    ${field({ label: 'Mã xác nhận', required: true, control: codeField({ fill: true, length: 6, value: code, columnWidth: col, disabled: !!s.busy, focus: !s.busy && code.length < 6 }) })}
    <div class="t1-gap-sm"></div>
    <p class="t1-small">Mã chỉ sử dụng một lần và hết hạn sau 10 phút.</p>
    <div class="t1-gap-lg"></div>
    ${button('Xác nhận mã', { full: true, disabled: code.length !== 6 || !!s.busy, attrs: 'data-primary' })}
    <div class="t1-reset__resend">${s.seconds > 0 ? `<p class="t1-body2 t1-reset__wait">${label}</p>` : button(label, { variant: 'link' })}</div>
  </div>`;
}

/** Bước 2: thanh 2 bước → tiêu đề → 2 ô mật khẩu (gợi ý ••••) → khe 24 → VCard "Quy tắc mật khẩu"; thanh dưới giữ nguyên. */
function createStep(s) {
  return `<div class="t1-list t1-reset">
    ${progressBar(RESET_STEPS, 1)}
    <h2 class="t1-reset__title">Tạo mật khẩu mới</h2>
    <div class="t1-gap-md"></div>
    <div class="t1-form">
      ${field({ label: 'Mật khẩu mới', required: true, control: input({ value: s.pw || '', hint: '••••••••••••', password: true, invalid: !!s.pwError }), error: s.pwError })}
      ${field({ label: 'Nhập lại mật khẩu mới', required: true, control: input({ value: s.confirm || '', hint: '••••••••••••', password: true, invalid: !!s.confirmError }), error: s.confirmError })}
    </div>
    <div class="t1-gap-lg"></div>
    ${card(`<h3 class="t1-h4">Quy tắc mật khẩu</h3><p class="t1-small t1-mt-xs">${PASSWORD_RULE}</p>`, 't1-card--pad')}
  </div>`;
}

/** _PasswordBottomBar: đệm 16, nền surface, gạch trên; "Quay lại" (secondary) | khe 8 | "Đặt lại mật khẩu" (tắt khi chưa nhập đủ hai ô). */
export function bottomBar(s) {
  const filled = !!(s.pw && s.confirm);
  return `<div class="t1-pwbar">${button('Quay lại', { variant: 'secondary', full: true, disabled: !!s.busy })}${button('Đặt lại mật khẩu', { full: true, disabled: !filled || !!s.busy })}</div>`;
}

export function resetPage(v) {
  const s = STATES[v.state];
  const email = s.account ? 'chien@anphat.vn' : 'lan@anphat.vn';
  let body; let bar = '';
  if (s.phase === 'requesting') body = centerLoading();
  else if (s.phase === 'request-failed') {
    body = `<div class="t1-center"><div class="t1-failed">
      <h2 class="t1-h4 t1-h4--600">Không gửi được mã</h2>
      <p class="t1-small t1-text-center">${s.toast[2]}</p>
      <div class="t1-gap-lg"></div>
      ${button('Thử lại')}
    </div></div>`;
  } else if (s.phase === 'verify') body = verifyStep(s, v, email);
  else { body = createStep(s); bar = bottomBar(s); }
  const col = `max-width:${authColumn(v.width)}`;
  const page = `<div class="t1-page t1-page--surface">${appBar('Đặt lại mật khẩu', { back: true })}
    <div class="t1-scroll"><div class="t1-col" style="${col}">${body}</div></div>
    ${bar ? `<footer class="t1-bottombar"><div class="t1-col" style="${col}">${bar}</div></footer>` : ''}
  </div>`;
  const overlay = (s.busy ? busyOverlay() : '') + (s.toast ? toast(...s.toast, { device: v.device, above: bar ? 78 : 0 }) : '');
  return { page, overlay };
}
