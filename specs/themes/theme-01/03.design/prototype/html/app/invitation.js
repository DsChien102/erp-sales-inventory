// ID-06 Nhập mã lời mời + ID-07 Kích hoạt tài khoản theo lời mời (/invitation). Chép từ:
//   apps/erp/lib/features/auth/presentation/pages/{invitation_token_page.dart, invitation_registration_page.dart}
//   apps/erp/lib/features/auth/presentation/widgets/{invitation_token_entry_form.dart, invitation_confirm_bottom_sheet.dart,
//     invitation_registration_form.dart, invitation_outcome_view.dart}
// Luồng: nhập mã → inspect → sheet xác nhận (cả tài khoản đã có lẫn chưa có) → đã có: chấp nhận → /login (banner);
//        chưa có: form đăng ký → /login (banner). Từ chối → màn kết quả "Đã từ chối lời mời".
import { adaptiveSheet, banner, button, codeField, esc, field, input, pageScaffold, plainScaffold, toast } from './ds.js';
import { PASSWORD_RULE } from './signup.js';

/** _entryFailureMessage: mã lỗi inspect → câu hiện dưới ô mã. */
export function entryFailureMessage(code) {
  return {
    INVITATION_TOKEN_INVALID: 'Mã lời mời không hợp lệ. Kiểm tra và nhập lại.',
    INVITATION_EXPIRED: 'Mã lời mời đã hết hạn. Liên hệ người gửi để nhận mã mới.',
    INVITATION_REVOKED: 'Lời mời đã bị thu hồi và không thể tiếp nhận.',
    INVITATION_ALREADY_USED: 'Lời mời đã được sử dụng và không thể tiếp nhận.',
  }[code] || 'Không thể xác thực mã. Kiểm tra kết nối và thử lại.';
}
/** _submit của form nhập mã: kiểm tại chỗ trước khi gọi inspect. */
export function tokenFormatError(token) {
  const t = String(token ?? '').trim();
  if (/^[0-9A-Z]{8}$/.test(t)) return null;
  return t ? 'Mã lời mời phải gồm 8 ký tự chữ hoặc số' : 'Vui lòng nhập mã lời mời';
}

export const INSPECTION = { tenantName: 'Thú y An Phát', role: 'Nhân viên bán hàng', email: 'minh@anphat.vn' };

export const STATES = {
  entry: { view: 'entry' },
  'entry-partial': { view: 'entry', token: 'K7M2' },
  'entry-format': { view: 'entry', token: 'K7M2', error: tokenFormatError('K7M2') },
  'entry-empty': { view: 'entry', error: tokenFormatError('') },
  'entry-invalid': { view: 'entry', token: 'K7M2QX9A', error: entryFailureMessage('INVITATION_TOKEN_INVALID') },
  'entry-expired': { view: 'entry', token: 'K7M2QX9A', error: entryFailureMessage('INVITATION_EXPIRED') },
  'entry-network': { view: 'entry', token: 'K7M2QX9A', error: entryFailureMessage('SYSTEM_ERROR') },
  inspecting: { view: 'entry', token: 'K7M2QX9A', busy: true },
  confirm: { view: 'entry', token: 'K7M2QX9A', sheet: true },
  accepting: { view: 'entry', token: 'K7M2QX9A', busy: true },
  register: { view: 'register' },
  'register-errors': { view: 'register', values: { pw: 'abc' }, errors: { familyName: 'Vui lòng nhập họ và tên đệm', givenName: 'Vui lòng nhập tên', password: 'Mật khẩu phải có ít nhất 8 ký tự, gồm 1 số và 1 ký tự đặc biệt', confirm: 'Vui lòng nhập lại mật khẩu' } },
  'register-filled': { view: 'register', values: { family: 'Trần Văn', given: 'Minh', phone: '0987 654 321', pw: 'Minh@2026', confirm: 'Minh@2026' } },
  'register-submitting': { view: 'register', values: { family: 'Trần Văn', given: 'Minh', phone: '0987 654 321', pw: 'Minh@2026', confirm: 'Minh@2026' }, busy: true },
  'register-failed': { view: 'register', values: { family: 'Trần Văn', given: 'Minh', phone: '0987 654 321' }, toast: ['danger', 'Không hoàn tất', 'Email không khớp với lời mời.'] },
  declined: { view: 'outcome', step: 'declined' },
  blocked: { view: 'outcome', step: 'blocked', message: 'Lời mời đã bị thu hồi.' },
};

/** InvitationTokenEntryForm: VPageScaffold "Kích hoạt tài khoản" + nút ← (về /login); khe 24 → banner info → khe 32 → ô mã 8 ký tự; bottomBar "Tiếp tục". */
function entryView(v, s) {
  const col = Math.min(v.width, v.width >= 600 ? 480 : v.width) - 32;
  const token = s.token || '';
  const body = `<div class="t1-pad-h">
    <div class="t1-gap-lg"></div>
    ${banner('info', 'Nhập mã lời mời', 'Sao chép mã được gửi tới email của bạn rồi dán vào trường bên dưới.')}
    <div class="t1-gap-xl"></div>
    ${field({ label: 'Mã lời mời', required: true, control: codeField({ length: 8, value: token, columnWidth: col, invalid: !!s.error, disabled: !!s.busy, focus: !s.busy && !s.sheet && token.length < 8 }), error: s.error, desc: 'Mã không phân biệt chữ hoa và chữ thường.' })}
  </div>`;
  const bar = `<div class="t1-bar-pad">${button('Tiếp tục', { full: true, loading: !!s.busy })}</div>`;
  return pageScaffold({ title: 'Kích hoạt tài khoản', backDisabled: !!s.busy, body, bottomBar: bar, width: v.width });
}

/** _InvitationConfirmSheetContent: đệm 16 / 16; tiêu đề H3 w700 → khe 8 → "Mã lời mời hợp lệ." → khe 16 → 3 dòng (nhãn 72 bodySmall + giá trị labelDefault) → khe 32 → Xác nhận / khe 16 / Từ chối → khe 8. */
export function confirmSheet() {
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

/** InvitationRegistrationForm: VPageScaffold "Kích hoạt tài khoản" + ← (về nhập mã); banner success → 6 ô (email khoá) → bottomBar "Kích hoạt tài khoản". */
function registerView(v, s) {
  const x = { family: '', given: '', phone: '', pw: '', confirm: '', ...s.values };
  const e = s.errors || {};
  const busy = !!s.busy;
  const body = `<div class="t1-pad-h">
    <div class="t1-gap-lg"></div>
    ${banner('success', 'Mã lời mời hợp lệ', `Kích hoạt tài khoản để tiếp nhận lời mời và vào ${INSPECTION.tenantName}.`)}
    <div class="t1-gap-xl"></div>
    <div class="t1-form">
      ${field({ label: 'Họ và tên đệm', required: true, control: input({ value: x.family, hint: 'Nhập họ và tên đệm', invalid: !!e.familyName, disabled: busy }), error: e.familyName })}
      ${field({ label: 'Tên', required: true, control: input({ value: x.given, hint: 'Nhập tên', invalid: !!e.givenName, disabled: busy }), error: e.givenName })}
      ${field({ label: 'Email', control: input({ value: INSPECTION.email, disabled: true }) })}
      ${field({ label: 'Số điện thoại', control: input({ value: x.phone, hint: 'Nhập số điện thoại', disabled: busy }) })}
      ${field({ label: 'Mật khẩu', required: true, control: input({ value: x.pw, hint: 'Nhập mật khẩu', password: true, invalid: !!e.password, disabled: busy }), error: e.password, desc: PASSWORD_RULE })}
      ${field({ label: 'Xác nhận mật khẩu', required: true, control: input({ value: x.confirm, hint: 'Nhập lại mật khẩu', password: true, invalid: !!e.confirm, disabled: busy }), error: e.confirm })}
    </div>
    <div class="t1-gap-xl"></div>
  </div>`;
  const bar = `<div class="t1-bar-pad">${button('Kích hoạt tài khoản', { full: true, loading: busy })}</div>`;
  return pageScaffold({ title: 'Kích hoạt tài khoản', backDisabled: busy, body, bottomBar: bar, width: v.width });
}

/** InvitationOutcomeView trong Scaffold nền surface, cột 480 đệm 16 (canh trên). onRetryLater không được truyền → không có "Thử lại sau". */
export function outcomeView(v, s) {
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
  const overlay = (s.sheet ? adaptiveSheet(v.width, confirmSheet(), 'Xác nhận lời mời') : '') + (s.toast ? toast(...s.toast, { device: v.device, above: s.view === 'outcome' ? 0 : 77 }) : '');
  return { page, overlay };
}
