// ID-03 Xác minh email (OTP) + VerifyEmailView dùng chung với bước 3 Đăng ký. Chép từ:
//   apps/erp/lib/features/auth/presentation/pages/verify_email_page.dart
//   apps/erp/lib/features/auth/presentation/widgets/{verify_email_view.dart, resend_countdown.dart}
//   apps/erp/lib/features/auth/logic/verify_email_cubit.dart (cooldown 60 s; allowImmediateResend → bấm "Gửi lại mã" được ngay)
// Bố cục iPhone ID-03, ID-05 thiết kế lại qua impeccable live (2026-11-25); chữ, trạng thái giữ nguyên Flutter. Web ở web/verify.js.
// ID-05 Chưa thuộc tổ chức: apps/erp/lib/features/auth/presentation/pages/no_organization_page.dart
import { icon } from '../shared/icons.js';
import { authColumn, button, card, codeField, field, plainScaffold, toast } from './ds.js';

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

export const RESEND_FAILED = 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.'; // resend() lỗi → resendFailure, hiện bằng toast đỏ (không phải lỗi mã)
export const OTP_WRONG = 'Mã xác minh không đúng hoặc đã hết hạn.'; // verify_email_cubit (cả khi chưa đủ 6 số)

/**
 * Phần nhập mã dùng chung màn ID-03 và bước 3 Đăng ký: VField(nhãn "Mã xác minh" *, sáu ô cao 56 trải hết bề ngang, lỗi)
 * → khe 24 → "Xác minh" (đầy ngang) → khe 8 → gửi lại (giữa): còn đếm ngược là chữ textSecondary, hết là nút link (như Đặt lại mật khẩu).
 * state: default | error | filled | submitting | can-resend | resend-failed
 */
function codeForm(v, { state = 'default', cooldown = 59 }) {
  // Cỡ ô (cao 56, chữ 18) tính theo cột 358; bề ngang ô do lưới chia đều.
  const col = Math.min(v.width, v.width >= 600 ? 480 : v.width) - 32;
  const code = state === 'error' ? '123456' : state === 'filled' || state === 'submitting' ? '482915' : '';
  const busy = state === 'submitting';
  const invalid = state === 'error';
  const secs = state === 'can-resend' || state === 'resend-failed' ? 0 : cooldown;
  return `${field({ label: 'Mã xác minh', required: true, control: codeField({ fill: true, length: 6, value: code, columnWidth: col, invalid, disabled: busy, focus: !busy && code.length < 6 }), error: invalid ? OTP_WRONG : null })}
    <div class="t1-gap-lg"></div>
    ${button('Xác minh', { full: true, loading: busy, attrs: 'data-primary' })}
    <div class="t1-verify__resend">${secs > 0 ? `<p class="t1-body2 t1-verify__wait">${resendLabel(secs)}</p>` : button(resendLabel(secs), { variant: 'link' })}</div>`;
}

/** Bước 3 Đăng ký: lời nhắc bodyDefault textSecondary → khe 24 → phần nhập mã. */
export function verifyView(v, { state = 'default', email, cooldown = 59 }) {
  return `<div class="t1-verify">
    <p class="t1-body2">Mã xác minh gồm 6 chữ số đã được gửi tới ${maskEmail(email)}.</p>
    <div class="t1-gap-lg"></div>
    ${codeForm(v, { state, cooldown })}
  </div>`;
}

/** VerifyEmailPage: nền canvas; ô biểu tượng thư 64 + tiêu đề + lời nhắc canh giữa; thẻ nhập mã; "Đăng xuất" (link) ở đáy màn. */
export function verifyPage(v) {
  const email = 'lan@anphat.vn';
  const state = v.state === 'default' ? 'can-resend' : v.state === 'countdown' ? 'default' : v.state;
  const body = `<div class="t1-vmail">
    <div class="t1-vmail__icon" aria-hidden="true">${icon('mail')}</div>
    <h2 class="t1-vmail__title">Xác minh email để tiếp tục</h2>
    <p class="t1-body2 t1-vmail__prompt">Mã 6 chữ số đã được gửi tới <b>${maskEmail(email)}</b>.</p>
    ${card(codeForm(v, { state, cooldown: 59 }), 't1-vmail__card')}
    <span class="t1-spacer"></span>
    <div class="t1-vmail__out">${button('Đăng xuất', { variant: 'link' })}</div>
  </div>`;
  const overlay = v.state === 'resend-failed' ? toast('danger', 'Không gửi được mã', RESEND_FAILED, { device: v.device }) : '';
  return { page: `<div class="t1-page t1-page--canvas t1-page--vmail"><div class="t1-scroll"><div class="t1-col" style="max-width:${authColumn(v.width)}">${body}</div></div></div>`, overlay };
}

/** NoOrganizationPage: nền surface, cột 480; biểu tượng tòa nhà 64 + tiêu đề + mô tả canh giữa vùng trên; "Nhập mã lời mời" + "Đăng xuất" (link) ở đáy màn. */
export function noOrgPage(v) {
  const body = `<div class="t1-noorgm">
    <div class="t1-noorgm__mid">
      <div class="t1-vmail__icon" aria-hidden="true">${icon('building')}</div>
      <h2 class="t1-vmail__title">Bạn chưa thuộc tổ chức nào</h2>
      <p class="t1-body2 t1-noorgm__text">Bạn chưa được cấp quyền truy cập tổ chức nào. Hãy kiểm tra lời mời hoặc liên hệ Chủ cửa hàng.</p>
    </div>
    <div class="t1-noorgm__actions">${button('Nhập mã lời mời', { full: true, attrs: 'data-primary' })}${button('Đăng xuất', { variant: 'link' })}</div>
  </div>`;
  return { page: plainScaffold({ body, width: v.width }) };
}
