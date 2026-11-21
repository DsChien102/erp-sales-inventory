// ID-03 Xác minh email (OTP) + VerifyEmailView dùng chung với bước 3 Đăng ký. Chép từ:
//   apps/erp/lib/features/auth/presentation/pages/verify_email_page.dart
//   apps/erp/lib/features/auth/presentation/widgets/{verify_email_view.dart, resend_countdown.dart}
//   apps/erp/lib/features/auth/logic/verify_email_cubit.dart (cooldown 60 s; allowImmediateResend → bấm "Gửi lại mã" được ngay)
// ID-05 Chưa thuộc tổ chức: apps/erp/lib/features/auth/presentation/pages/no_organization_page.dart
import { button, codeField, field, plainScaffold } from './ds.js';

/** maskEmail (features/iam/data/models/password_reset_result.dart): ký tự đầu + *** + @tên miền. */
export function maskEmail(email) {
  const at = email.indexOf('@');
  if (at <= 0) return '***';
  return `${email.slice(0, 1)}***${email.slice(at)}`;
}

/** ResendCountdown: "Gửi lại mã sau mm:ss" khi còn khoá, "Gửi lại mã" khi hết. */
export function resendLabel(seconds) {
  if (seconds <= 0) return 'Gửi lại mã';
  const mm = String(Math.floor(seconds / 60)).padStart(2, '0');
  const ss = String(seconds % 60).padStart(2, '0');
  return `Gửi lại mã sau ${mm}:${ss}`;
}

export const RESEND_FAILED = 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.'; // resend() lỗi → failure, hiện cùng chỗ lỗi mã
export const OTP_WRONG = 'Mã xác minh không đúng hoặc đã hết hạn.'; // verify_email_cubit (cả khi chưa đủ 6 số)

/**
 * VerifyEmailView: lời nhắc bodyDefault textSecondary → khe 24 → VField(nhãn "Mã xác minh" *, ô 6 số, lỗi)
 * → khe 16 → ResendCountdown (nút link) → khe 24 → "Xác minh" (đầy ngang).
 * state: default | error | filled | submitting | can-resend
 */
export function verifyView(v, { state = 'default', email, prompt, cooldown = 59 }) {
  const col = Math.min(v.width, v.width >= 600 ? 480 : v.width) - 32;
  const code = state === 'error' ? '123456' : state === 'filled' || state === 'submitting' ? '482915' : '';
  const busy = state === 'submitting';
  const invalid = state === 'error' || state === 'resend-failed';
  const secs = state === 'can-resend' || state === 'resend-failed' ? 0 : cooldown;
  const text = prompt || `Mã xác minh gồm 6 chữ số đã được gửi tới ${maskEmail(email)}.`;
  return `<div class="t1-verify">
    <p class="t1-body2">${text}</p>
    <div class="t1-gap-lg"></div>
    ${field({ label: 'Mã xác minh', required: true, control: codeField({ length: 6, value: code, columnWidth: col, invalid, disabled: busy, focus: !busy && code.length < 6 }), error: state === 'resend-failed' ? RESEND_FAILED : invalid ? OTP_WRONG : null })}
    <div class="t1-gap-md"></div>
    <div>${button(resendLabel(secs), { variant: 'link', disabled: secs > 0 })}</div>
    <div class="t1-gap-lg"></div>
    ${button('Xác minh', { full: true, loading: busy })}
  </div>`;
}

/** VerifyEmailPage: Scaffold nền surface; ListView đệm 16 trong cột 480: khe 32 → tiêu đề H3 → khe 24 → VerifyEmailView → khe 16 → "Đăng xuất" (link). */
export function verifyPage(v) {
  const email = 'lan@anphat.vn';
  const state = v.state === 'countdown' ? 'default' : v.state;
  const body = `<div class="t1-list">
    <div class="t1-gap-xl"></div>
    <h2 class="t1-h3">Xác minh email để tiếp tục</h2>
    <div class="t1-gap-lg"></div>
    ${verifyView(v, { state: v.state === 'default' ? 'can-resend' : state, email, prompt: `Mã 6 chữ số đã được gửi tới ${maskEmail(email)}.`, cooldown: 59 })}
    <div class="t1-gap-md"></div>
    <div>${button('Đăng xuất', { variant: 'link' })}</div>
  </div>`;
  return { page: plainScaffold({ body, width: v.width }) };
}

/** NoOrganizationPage: nền surface, cột 480, nội dung canh giữa dọc (cao tối thiểu = màn − 32). */
export function noOrgPage(v) {
  const body = `<div class="t1-list t1-list--center">
    <h2 class="t1-h3 t1-text-center">Bạn chưa thuộc tổ chức nào</h2>
    <div class="t1-gap-md"></div>
    <p class="t1-body2 t1-text-center">Bạn chưa được cấp quyền truy cập tổ chức nào. Hãy kiểm tra lời mời hoặc liên hệ Chủ cửa hàng.</p>
    <div class="t1-gap-xl"></div>
    ${button('Nhập mã lời mời', { full: true })}
    <div class="t1-gap-md"></div>
    ${button('Đăng xuất', { variant: 'secondary', full: true })}
  </div>`;
  return { page: plainScaffold({ body, width: v.width, cls: 't1-page--fill' }) };
}
