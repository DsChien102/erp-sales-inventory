// ID-04 Quên mật khẩu (/login/reset-password) và ID-23 Đặt lại mật khẩu khi đã đăng nhập (/more/my-account/reset-password):
// cùng một ResetPasswordPage(authRepository) → cùng giao diện; khác nhau chỉ ở email nhận mã và nơi quay về.
// Chép từ apps/erp/lib/features/iam/presentation/users/views/reset_password_page.dart (_ResetPasswordBodyState, _PasswordBottomBar)
//   + widgets/{reset_password_verify_code_step.dart, reset_password_create_password_step.dart}
// VPageScaffold(contentMaxWidth: authMaxWidth, title 'Đặt lại mật khẩu'): nền xám canvas, nút ← tự có (route pop được).
import { busyOverlay, button, card, centerLoading, codeField, field, input, pageScaffold, toast } from './ds.js';
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

/** ResetPasswordVerifyCodeStep: ListView đệm 16 / 16; VCard (đệm 16) → [không khe] VField → khe 24 → "Xác nhận mã" → khe 8 → "Gửi lại mã…" (secondary) → khe 16 → ghi chú. */
function verifyStep(s, v, email) {
  const col = Math.min(v.width, v.width >= 600 ? 480 : v.width) - 32;
  const code = s.code || '';
  return `<div class="t1-list">
    ${card(`<h2 class="t1-h4">Xác minh email</h2><p class="t1-small t1-mt-xs">Mã 6 chữ số đã được gửi tới ${maskEmail(email)}. Xác nhận mã để tạo mật khẩu mới.</p>`, 't1-card--pad')}
    ${field({ label: 'Mã xác nhận', required: true, control: codeField({ length: 6, value: code, columnWidth: col, disabled: !!s.busy, focus: !s.busy && code.length < 6 }) })}
    <div class="t1-gap-lg"></div>
    ${button('Xác nhận mã', { full: true, disabled: code.length !== 6 || !!s.busy })}
    <div class="t1-gap-sm"></div>
    ${button(resetResendLabel(s.seconds), { variant: 'secondary', full: true, disabled: s.seconds > 0 })}
    <div class="t1-gap-md"></div>
    <p class="t1-small">Mã chỉ sử dụng một lần và hết hạn sau 10 phút.</p>
  </div>`;
}

/** ResetPasswordCreatePasswordStep: tiêu đề H3 → khe 16 → 2 ô mật khẩu (gợi ý ••••) → khe 24 → VCard "Quy tắc mật khẩu". */
function createStep(s) {
  return `<div class="t1-list">
    <h2 class="t1-h3">Tạo mật khẩu mới</h2>
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
  // Bản bottomBar của trang tự vẽ nền + viền + đệm 16; VPageScaffold bọc thêm một lớp nền + gạch trên.
  const page = pageScaffold({ title: 'Đặt lại mật khẩu', body, bottomBar: bar, width: v.width });
  const overlay = (s.busy ? busyOverlay() : '') + (s.toast ? toast(...s.toast, { device: v.device, above: bar ? 78 : 0 }) : '');
  return { page, overlay };
}
