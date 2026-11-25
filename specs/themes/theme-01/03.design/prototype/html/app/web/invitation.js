// Bố cục WEB (khung ≥ 840), chọn qua impeccable live 2026-11-24. iPhone ở ../invitation.js; trạng thái mẫu, hàm kiểm, sheet dùng chung lấy từ đó.
import { icon } from '../../shared/icons.js';
import { adaptiveSheet, appBar, banner, button, codeField, esc, field, input, plainScaffold, toast } from '../ds.js';
import { INSPECTION, STATES } from '../invitation.js';
import { PASSWORD_RULE } from '../signup.js';

/**
 * Nhập mã lời mời: nền canvas, VAppBar "Kích hoạt tài khoản" + ← (về /login); cột 520 canh trên; thẻ trắng: ô thư 48 → "Nhập mã lời mời"
 * → hướng dẫn → ô mã 8 ký tự (+ lỗi | mô tả) → "Tiếp tục" trong thẻ (không còn thanh dưới). Chọn qua impeccable live (2026-11-24).
 */
function entryView(v, s) {
  const col = Math.min(v.width, 520) - 32 - 40 - 2; // cột − đệm trang − đệm thẻ − viền
  const token = s.token || '';
  return `<div class="t1-page t1-page--canvas">${appBar('Kích hoạt tài khoản', { back: true, backDisabled: !!s.busy })}
    <div class="t1-scroll"><div class="t1-stepcol">
      <div class="t1-stepcard t1-stepcard--first">
        <div class="t1-mailbox" aria-hidden="true">${icon('mail')}</div>
        <h2 class="t1-stepcard__title t1-stepcard__title--icon">Nhập mã lời mời</h2>
        <p class="t1-body2">Sao chép mã được gửi tới email của bạn rồi dán vào trường bên dưới.</p>
        <div class="t1-gap-lg"></div>
        ${field({ label: 'Mã lời mời', required: true, control: codeField({ fill: true, length: 8, value: token, columnWidth: col, invalid: !!s.error, disabled: !!s.busy, focus: !s.busy && !s.sheet && token.length < 8 }), error: s.error, desc: 'Mã không phân biệt chữ hoa và chữ thường.' })}
        <div class="t1-gap-lg"></div>
        ${button('Tiếp tục', { full: true, loading: !!s.busy })}
      </div>
    </div></div>
  </div>`;
}

/**
 * Đăng ký theo lời mời: nền canvas, VAppBar "Kích hoạt tài khoản" + ← (về nhập mã); cột 520: banner success → thẻ trắng 6 ô (email khoá)
 * → thanh dưới "Kích hoạt tài khoản" (cùng cột 520). Chọn qua impeccable live (2026-11-24).
 */
function registerView(v, s) {
  const x = { family: '', given: '', phone: '', pw: '', confirm: '', ...s.values };
  const e = s.errors || {};
  const busy = !!s.busy;
  const col = v.width >= 600 ? 'max-width:520px' : '';
  return `<div class="t1-page t1-page--canvas">${appBar('Kích hoạt tài khoản', { back: true, backDisabled: busy })}
    <div class="t1-scroll"><div class="t1-stepcol">
      ${banner('success', 'Mã lời mời hợp lệ', `Kích hoạt tài khoản để tiếp nhận lời mời và vào ${INSPECTION.tenantName}.`)}
      <div class="t1-stepcard t1-stepcard--near">
        <div class="t1-form">
          ${field({ label: 'Họ và tên đệm', required: true, control: input({ value: x.family, hint: 'Nhập họ và tên đệm', invalid: !!e.familyName, disabled: busy }), error: e.familyName })}
          ${field({ label: 'Tên', required: true, control: input({ value: x.given, hint: 'Nhập tên', invalid: !!e.givenName, disabled: busy }), error: e.givenName })}
          ${field({ label: 'Email', control: input({ value: INSPECTION.email, disabled: true }) })}
          ${field({ label: 'Số điện thoại', control: input({ value: x.phone, hint: 'Nhập số điện thoại', disabled: busy }) })}
          ${field({ label: 'Mật khẩu', required: true, control: input({ value: x.pw, hint: 'Nhập mật khẩu', password: true, invalid: !!e.password, disabled: busy }), error: e.password, desc: PASSWORD_RULE })}
          ${field({ label: 'Xác nhận mật khẩu', required: true, control: input({ value: x.confirm, hint: 'Nhập lại mật khẩu', password: true, invalid: !!e.confirm, disabled: busy }), error: e.confirm })}
        </div>
      </div>
    </div></div>
    <footer class="t1-bottombar"><div class="t1-col" style="${col}"><div class="t1-bar-pad">${button('Kích hoạt tài khoản', { full: true, loading: busy })}</div></div></footer>
  </div>`;
}

/** _InvitationConfirmSheetContent: đệm 16 / 16; tiêu đề H3 w700 → khe 8 → "Mã lời mời hợp lệ." → khe 16 → 3 dòng (nhãn 72 bodySmall + giá trị labelDefault) → khe 32 → Xác nhận / khe 16 / Từ chối → khe 8. */
function confirmSheet() {
  const row = (l, val) => `<div class="t1-inforow"><span>${esc(l)}</span><b>${esc(val)}</b></div>`;
  return `<div class="t1-confirm">
    <h2 class="t1-h3">Xác nhận lời mời tham gia tổ chức?</h2>
    <div class="t1-gap-sm"></div>
    <p class="t1-body2">Mã lời mời hợp lệ.</p>
    <div class="t1-gap-md"></div>
    ${row('Tổ chức', INSPECTION.tenantName)}${row('Vai trò', INSPECTION.role)}${row('Email', INSPECTION.email)}
    <div class="t1-gap-xl"></div>
    ${button('Xác nhận', { full: true })}
    <div class="t1-gap-md"></div>
    ${button('Từ chối', { variant: 'secondary', full: true })}
    <div class="t1-gap-sm"></div>
  </div>`;
}

/** InvitationOutcomeView trong Scaffold nền surface, cột 480 đệm 16 (canh trên). onRetryLater không được truyền → không có "Thử lại sau". */
function outcomeView(v, s) {
  const declined = s.step === 'declined';
  const title = declined ? 'Đã từ chối lời mời' : 'Không thể tiếp tục';
  const body = s.message || (declined ? 'Lời mời đã được từ chối.' : 'Mã lời mời không dùng được. Bạn có thể nhập mã khác.');
  return plainScaffold({
    width: v.width,
    body: `<div class="t1-list"><h2 class="t1-h3">${esc(title)}</h2><div class="t1-gap-sm"></div><p class="t1-body2">${esc(body)}</p><div class="t1-gap-lg"></div>${button('Nhập mã khác', { full: true })}</div>`,
  });
}

export function invitationPage(v) {
  const s = STATES[v.state];
  const page = s.view === 'register' ? registerView(v, s) : s.view === 'outcome' ? outcomeView(v, s) : entryView(v, s);
  const overlay = (s.sheet ? adaptiveSheet(v.width, confirmSheet(), 'Xác nhận lời mời') : '') + (s.toast ? toast(...s.toast, { device: v.device, above: s.view === 'register' ? 77 : 0 }) : '');
  return { page, overlay };
}
