// ID-06 Nhập mã lời mời + ID-07 Kích hoạt tài khoản theo lời mời (/invitation). Chép từ:
//   apps/erp/lib/features/auth/presentation/pages/{invitation_token_page.dart, invitation_registration_page.dart}
//   apps/erp/lib/features/auth/presentation/widgets/{invitation_token_entry_form.dart, invitation_confirm_bottom_sheet.dart,
//     invitation_registration_form.dart, invitation_outcome_view.dart}
// Luồng: nhập mã → inspect → sheet xác nhận (cả tài khoản đã có lẫn chưa có) → đã có: chấp nhận → /login (banner);
//        chưa có: form đăng ký → /login (banner). Từ chối → màn kết quả "Đã từ chối lời mời".
import { icon } from '../shared/icons.js';
import { adaptiveSheet, appBar, button, codeField, esc, field, input, plainScaffold, toast } from './ds.js';
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

/**
 * InvitationTokenEntryForm: nền surface, VAppBar "Kích hoạt tài khoản" + nút ← (về /login); tiêu đề → hướng dẫn → khe 24 → ô mã 8 ký tự (nhóm 4 + 4, + lỗi | mô tả)
 * → khe 24 → "Tiếp tục" ngay dưới (không còn thanh dưới). Bố cục iPhone thiết kế lại qua impeccable live (2026-11-25); chữ giữ nguyên Flutter.
 */
function entryView(v, s) {
  const token = s.token || '';
  const body = `<div class="t1-invite">
    <h2 class="t1-invite__title">Nhập mã lời mời</h2>
    <p class="t1-body2 t1-invite__text">Sao chép mã được gửi tới email của bạn rồi dán vào trường bên dưới.</p>
    ${field({ label: 'Mã lời mời', required: true, control: codeField({ split: true, length: 8, value: token, columnWidth: v.width - 32, invalid: !!s.error, disabled: !!s.busy, focus: !s.busy && !s.sheet && token.length < 8 }), error: s.error, desc: 'Mã không phân biệt chữ hoa và chữ thường.' })}
    <div class="t1-gap-lg"></div>
    ${button('Tiếp tục', { full: true, loading: !!s.busy, attrs: 'data-primary' })}
  </div>`;
  return plainScaffold({ appbar: appBar('Kích hoạt tài khoản', { back: true, backDisabled: !!s.busy }), body, width: v.width });
}

/**
 * _InvitationConfirmSheetContent (iPhone, impeccable live 2026-11-25; web giữ bản cũ ở web/invitation.js): đệm 16; tiêu đề 20/28 w700 → dấu tích + "Mã lời mời hợp lệ."
 * → khối nền canvas 3 dòng (nhãn ↔ giá trị w600 phải) → khe 20 → Xác nhận / khe 8 / Từ chối.
 */
function confirmSheet() {
  const row = (l, val) => `<div class="t1-invconf__row"><span>${esc(l)}</span><b>${esc(val)}</b></div>`;
  return `<div class="t1-confirm t1-invconf">
    <h2 class="t1-invconf__title">Xác nhận lời mời tham gia tổ chức?</h2>
    <p class="t1-invconf__ok">${icon('checkCircle')}Mã lời mời hợp lệ.</p>
    <div class="t1-invconf__box">${row('Tổ chức', INSPECTION.tenantName)}${row('Vai trò', INSPECTION.role)}${row('Email', INSPECTION.email)}</div>
    <div class="t1-invconf__acts">${button('Xác nhận', { full: true, attrs: 'data-primary' })}${button('Từ chối', { variant: 'secondary', full: true })}</div>
  </div>`;
}

/**
 * InvitationRegistrationForm: nền surface, VAppBar "Kích hoạt tài khoản" + ← (về nhập mã); dấu tích + "Mã lời mời hợp lệ" → lời nhắc → khe 20
 * → form (họ + tên cùng hàng 3 : 2; email khoá là một dòng đọc rõ + biểu tượng khoá) → khe 24 → "Kích hoạt tài khoản" ngay dưới (không còn thanh dưới).
 * Bố cục iPhone thiết kế lại qua impeccable live (2026-11-25); chữ, trạng thái giữ nguyên Flutter.
 */
function registerView(v, s) {
  const x = { family: '', given: '', phone: '', pw: '', confirm: '', ...s.values };
  const e = s.errors || {};
  const busy = !!s.busy;
  const body = `<div class="t1-invreg">
    <p class="t1-invreg__ok">${icon('checkCircle')}<b>Mã lời mời hợp lệ</b></p>
    <p class="t1-body2 t1-invreg__text">Kích hoạt tài khoản để tiếp nhận lời mời và vào <b>${esc(INSPECTION.tenantName)}</b>.</p>
    <div class="t1-form">
      <div class="t1-signup__names">
        ${field({ label: 'Họ và tên đệm', required: true, control: input({ value: x.family, hint: 'Nhập họ và tên đệm', invalid: !!e.familyName, disabled: busy }), error: e.familyName })}
        ${field({ label: 'Tên', required: true, control: input({ value: x.given, hint: 'Nhập tên', invalid: !!e.givenName, disabled: busy }), error: e.givenName })}
      </div>
      <div class="t1-invreg__mail"><span>Email</span><b>${esc(INSPECTION.email)}</b>${icon('lock')}</div>
      ${field({ label: 'Số điện thoại', control: input({ value: x.phone, hint: 'Nhập số điện thoại', disabled: busy }) })}
      ${field({ label: 'Mật khẩu', required: true, control: input({ value: x.pw, hint: 'Nhập mật khẩu', password: true, invalid: !!e.password, disabled: busy }), error: e.password, desc: PASSWORD_RULE })}
      ${field({ label: 'Xác nhận mật khẩu', required: true, control: input({ value: x.confirm, hint: 'Nhập lại mật khẩu', password: true, invalid: !!e.confirm, disabled: busy }), error: e.confirm })}
    </div>
    <div class="t1-gap-lg"></div>
    ${button('Kích hoạt tài khoản', { full: true, loading: busy, attrs: 'data-primary' })}
  </div>`;
  return plainScaffold({ appbar: appBar('Kích hoạt tài khoản', { back: true, backDisabled: busy }), body, width: v.width });
}

/**
 * InvitationOutcomeView (iPhone, impeccable live 2026-11-25; web giữ bản cũ ở web/invitation.js): Scaffold nền surface; biểu tượng 64 + tiêu đề + câu canh giữa;
 * "Nhập mã khác" ở đáy màn. Đã từ chối → × xám; không thể tiếp tục → cảnh báo vàng. onRetryLater không được truyền → không có "Thử lại sau".
 */
function outcomeView(v, s) {
  const declined = s.step === 'declined';
  const title = declined ? 'Đã từ chối lời mời' : 'Không thể tiếp tục';
  const text = s.message || (declined ? 'Lời mời đã được từ chối.' : 'Mã lời mời không dùng được. Bạn có thể nhập mã khác.');
  const body = `<div class="t1-noorgm">
    <div class="t1-noorgm__mid">
      <div class="t1-vmail__icon ${declined ? 't1-vmail__icon--neutral' : 't1-vmail__icon--warning'}" aria-hidden="true">${icon(declined ? 'close' : 'alert')}</div>
      <h2 class="t1-vmail__title">${esc(title)}</h2>
      <p class="t1-body2 t1-noorgm__text">${esc(text)}</p>
    </div>
    <div class="t1-noorgm__actions">${button('Nhập mã khác', { full: true, attrs: 'data-primary' })}</div>
  </div>`;
  return plainScaffold({ body, width: v.width });
}

export function invitationPage(v) {
  const s = STATES[v.state];
  const page = s.view === 'register' ? registerView(v, s) : s.view === 'outcome' ? outcomeView(v, s) : entryView(v, s);
  const overlay = (s.sheet ? adaptiveSheet(v.width, confirmSheet(), 'Xác nhận lời mời') : '') + (s.toast ? toast(...s.toast, { device: v.device }) : '');
  return { page, overlay };
}
