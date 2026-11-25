// Bố cục WEB (khung ≥ 840), chọn qua impeccable live 2026-11-24. iPhone ở ../reset.js; trạng thái mẫu, hàm kiểm, sheet dùng chung lấy từ đó.
import { icon } from '../../shared/icons.js';
import { appBar, busyOverlay, button, centerLoading, codeField, field, input, pageScaffold, progressBar, toast } from '../ds.js';
import { bottomBar, resetResendLabel, STATES } from '../reset.js';
import { PASSWORD_RULE } from '../signup.js';
import { maskEmail } from '../verify.js';

const RESET_STEPS = ['Xác minh email', 'Tạo mật khẩu mới'];

/** Bước 1 (thẻ): ô thư 48 → "Xác minh email" → lời nhắc → ô mã → "Xác nhận mã" → "Gửi lại mã…" (link); ghi chú 10 phút dưới thẻ. */
function verifyStep(s, v, email) {
  const col = Math.min(v.width, 520) - 32 - 40 - 2; // cột − đệm trang − đệm thẻ − viền
  const code = s.code || '';
  return `<div class="t1-stepcard">
      <div class="t1-mailbox" aria-hidden="true">${icon('mail')}</div>
      <h2 class="t1-stepcard__title t1-stepcard__title--icon">Xác minh email</h2>
      <p class="t1-body2">Mã 6 chữ số đã được gửi tới ${maskEmail(email)}. Xác nhận mã để tạo mật khẩu mới.</p>
      <div class="t1-gap-lg"></div>
      ${field({ label: 'Mã xác nhận', required: true, control: codeField({ fill: true, length: 6, value: code, columnWidth: col, disabled: !!s.busy, focus: !s.busy && code.length < 6 }) })}
      <div class="t1-gap-lg"></div>
      ${button('Xác nhận mã', { full: true, disabled: code.length !== 6 || !!s.busy })}
      <div class="t1-reset__resend">${s.seconds > 0 ? `<p class="t1-body2 t1-reset__wait">${resetResendLabel(s.seconds)}</p>` : button(resetResendLabel(s.seconds), { variant: 'link' })}</div>
    </div>
    <p class="t1-small t1-text-center t1-stepcol__after">Mã chỉ sử dụng một lần và hết hạn sau 10 phút.</p>`;
}

/** Bước 2 (thẻ): "Tạo mật khẩu mới" → 2 ô mật khẩu (gợi ý ••••) → quy tắc mật khẩu (ô nền canvas trong thẻ). */
function createStep(s) {
  return `<div class="t1-stepcard">
      <h2 class="t1-stepcard__title">Tạo mật khẩu mới</h2>
      <div class="t1-form">
        ${field({ label: 'Mật khẩu mới', required: true, control: input({ value: s.pw || '', hint: '••••••••••••', password: true, invalid: !!s.pwError }), error: s.pwError })}
        ${field({ label: 'Nhập lại mật khẩu mới', required: true, control: input({ value: s.confirm || '', hint: '••••••••••••', password: true, invalid: !!s.confirmError }), error: s.confirmError })}
      </div>
      <div class="t1-stepcard__rule"><h3 class="t1-h4">Quy tắc mật khẩu</h3><p class="t1-small t1-mt-xs">${PASSWORD_RULE}</p></div>
    </div>`;
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
  let page;
  if (s.phase === 'verify' || s.phase === 'create') {
    // Thanh 2 bước + thẻ trên nền canvas (cột 520), cùng mẫu với Đăng ký. Chọn qua impeccable live (2026-11-24).
    const col = v.width >= 600 ? 'max-width:520px' : '';
    page = `<div class="t1-page t1-page--canvas">${appBar('Đặt lại mật khẩu', { back: true })}
    <div class="t1-scroll"><div class="t1-stepcol">${progressBar(RESET_STEPS, s.phase === 'verify' ? 0 : 1)}${body}</div></div>
    ${bar ? `<footer class="t1-bottombar"><div class="t1-col" style="${col}">${bar}</div></footer>` : ''}
  </div>`;
  } else {
    page = pageScaffold({ title: 'Đặt lại mật khẩu', body, width: v.width });
  }
  const overlay = (s.busy ? busyOverlay() : '') + (s.toast ? toast(...s.toast, { device: v.device, above: bar ? 78 : 0 }) : '');
  return { page, overlay };
}
