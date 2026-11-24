// ID-03 Xác minh email (OTP) + VerifyEmailView dùng chung với bước 3 Đăng ký. Chép từ:
//   apps/erp/lib/features/auth/presentation/pages/verify_email_page.dart
//   apps/erp/lib/features/auth/presentation/widgets/{verify_email_view.dart, resend_countdown.dart}
//   apps/erp/lib/features/auth/logic/verify_email_cubit.dart (cooldown 60 s; allowImmediateResend → bấm "Gửi lại mã" được ngay)
// ID-05 Chưa thuộc tổ chức: apps/erp/lib/features/auth/presentation/pages/no_organization_page.dart
import { button, codeField, field } from './ds.js';
import { icon } from '../shared/icons.js';

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
export function verifyView(v, { state = 'default', email, prompt, cooldown = 59, columnWidth }) {
  const col = columnWidth ?? Math.min(v.width, v.width >= 600 ? 480 : v.width) - 32;
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

/**
 * VerifyEmailPage: nền canvas; cột 520 canh giữa dọc; thẻ trắng (viền borderDefault, bo card, đệm 24/20):
 * ô biểu tượng thư 48 (surfaceBrand) → tiêu đề → VerifyEmailView; "Đăng xuất" (link) dưới thẻ. Chọn qua impeccable live (2026-11-24).
 */
export function verifyPage(v) {
  const email = 'lan@anphat.vn';
  const state = v.state === 'countdown' ? 'default' : v.state;
  const inner = Math.min(v.width, 520) - 32 - 40 - 2; // cột − đệm trang − đệm thẻ − viền
  const page = `<div class="t1-page t1-page--canvas"><div class="t1-scroll"><div class="t1-verify-page">
    <div class="t1-verify-page__card">
      <div class="t1-mailbox" aria-hidden="true">${icon('mail')}</div>
      <h2 class="t1-verify-page__title">Xác minh email để tiếp tục</h2>
      ${verifyView(v, { state: v.state === 'default' ? 'can-resend' : state, email, prompt: `Mã 6 chữ số đã được gửi tới ${maskEmail(email)}.`, cooldown: 59, columnWidth: inner })}
    </div>
    <div class="t1-center-row t1-verify-page__after">${button('Đăng xuất', { variant: 'link' })}</div>
  </div></div></div>`;
  return { page };
}

/**
 * NoOrganizationPage: nền canvas, cột 560 canh giữa dọc; thẻ ngang: ô biểu tượng toà nhà 48 (surfaceBrand) | tiêu đề + mô tả + hai nút
 * ("Nhập mã lời mời" chính, "Đăng xuất" viền; web cùng hàng — nút chính bên phải, iPhone xếp dọc). Chọn qua impeccable live (2026-11-24).
 */
export function noOrgPage(v) {
  const page = `<div class="t1-page t1-page--canvas"><div class="t1-scroll"><div class="t1-noorg">
    <div class="t1-noorg__card">
      <div class="t1-mailbox" aria-hidden="true">${icon('building')}</div>
      <div class="t1-noorg__main">
        <h2 class="t1-noorg__title">Bạn chưa thuộc tổ chức nào</h2>
        <p class="t1-body2">Bạn chưa được cấp quyền truy cập tổ chức nào. Hãy kiểm tra lời mời hoặc liên hệ Chủ cửa hàng.</p>
        <div class="t1-noorg__actions">${button('Nhập mã lời mời', { full: true })}${button('Đăng xuất', { variant: 'secondary', full: true })}</div>
      </div>
    </div>
  </div></div></div>`;
  return { page };
}
