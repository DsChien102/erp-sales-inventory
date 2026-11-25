// ID-21 Tài khoản của tôi · ID-22 Chỉnh sửa thông tin. Chép từ:
//   apps/erp/lib/features/iam/presentation/users/views/{my_account_page, edit_my_account_page}.dart
//   apps/erp/lib/features/iam/presentation/users/widgets/{my_account_actions_bottom_sheet, logout_confirmation_bottom_sheet}.dart
//   core/router/app_router.dart (/more/my-account: GoRoute gốc, ngoài StoreShell; onLogout → toast lỗi)
// Sửa thông tin mở bằng Navigator.push (không có route riêng); ID-23 (đặt lại mật khẩu) đã vẽ ở đợt 1 (reset/from-account).
import { icon } from '../shared/icons.js';
import { loadFailed } from './org.js';
import { button, centerLoading, confirmDialog, esc, field, input, toast, vcard, vScaffold, adaptiveSheet } from './ds.js';

export const ME = { lastName: 'Nguyễn Thị', firstName: 'Lan', email: 'lan@anphat.vn', emailStatus: 'Đã xác minh', phone: '0912 345 678' };
/** VAvatar._initialsFrom: nhiều từ → chữ đầu từ đầu + chữ đầu từ cuối, viết hoa. */
export const initials = (name) => {
  const w = String(name).trim().split(/\s+/).filter(Boolean);
  if (!w.length) return '?';
  return (w.length === 1 ? w[0][0] : w[0][0] + w[w.length - 1][0]).toUpperCase();
};

/**
 * bottomBar tự vẽ: Container đệm 16 + nền surface + gạch trên 1 (chồng gạch của VPageScaffold) + SafeArea → cao 78.
 * "Thao tác" primary tone primary; mũi tên ⌃ đổi thành ⌄ khi sheet đang mở.
 */
export const BAR2 = 78;
const actionBar = (open) => `<div class="t1-bar-pad t1-bar-line">${button('Thao tác', { full: true, trailing: open ? 'chevronDown' : 'chevronUp' })}</div>`;

/** _buildInfoRow: đệm dọc 8; nhãn bodyDefault textSecondary, khe 8, giá trị bodyDefault w700 phải; rỗng → "(chưa có)" textMuted w thường. */
export const infoRow = (l, val) => `<div class="t1-acrow"><span>${esc(l)}</span><b${val ? '' : ' class="is-empty"'}>${esc(val || '(chưa có)')}</b></div>`;

export const ACCOUNT_STATES = {
  owner: {}, staff: { staff: true }, 'no-phone': { me: { phone: '' } }, loading: { loading: true }, error: { error: true },
  actions: { sheet: 'actions' }, logout: { sheet: 'logout' },
  'toast-updated': { toast: ['success', 'Thành công', 'Đã cập nhật thông tin cá nhân'] },
  'toast-logout-failed': { toast: ['danger', 'Đăng xuất thất bại', 'Không thể đóng phiên trên máy.'] },
};

/** Sheet "Thao tác tài khoản" (không tiêu đề sheet): đệm 16 / 16; H3 w700; khe 16; 2 VCard (icon 20 + khe 12) + hộp Đăng xuất đỏ, cách 8; khe 24. */
function actionsSheet() {
  const opt = (ic, t, sub, danger = false) => `<div class="t1-card t1-card--pad t1-optcard t1-optcard--12${danger ? ' t1-optcard--danger' : ''}">${icon(ic)}<div><b>${esc(t)}</b><span>${esc(sub)}</span></div>${icon('chevronRight', 't1-optcard__chev')}</div>`;
  return `<div class="t1-list"><h2 class="t1-h3">Thao tác tài khoản</h2><div class="t1-gap-md"></div>
    ${opt('edit', 'Chỉnh sửa thông tin cá nhân', 'Cập nhật hồ sơ cá nhân')}<div class="t1-gap-sm"></div>
    ${opt('lock', 'Đặt lại mật khẩu', 'Xác minh email và tạo mật khẩu mới')}<div class="t1-gap-sm"></div>
    ${opt('logout', 'Đăng xuất', 'Kết thúc phiên sử dụng hiện tại', true)}<div class="t1-gap-lg"></div></div>`;
}
/** Sheet đăng xuất: đệm 16 / 16; H3 w700 danger; khe 4; bodySmall; khe 32; hai nút large (52) chia đôi khe 8; khe 16. */
export const logoutSheet = () => `<div class="t1-list"><h2 class="t1-h3 t1-danger">Đăng xuất khỏi Mosaic Retail?</h2><div class="t1-gap-xs"></div>
  <p class="t1-small">Bạn sẽ cần đăng nhập lại để tiếp tục sử dụng ứng dụng.</p><div class="t1-gap-xl"></div>
  <div class="t1-row2 t1-row2--8">${button('Quay lại', { variant: 'secondary', full: true, cls: 't1-btn--lg' })}${button('Đăng xuất', { full: true, cls: 't1-btn--danger t1-btn--lg' })}</div><div class="t1-gap-md"></div></div>`;

export function accountPage(v) {
  const s = ACCOUNT_STATES[v.state];
  const base = { title: 'Tài khoản của tôi', placeWidth: v.width };
  if (s.loading) return { page: vScaffold({ ...base, body: centerLoading(), fixed: true }) };
  if (s.error) return { page: vScaffold({ ...base, body: loadFailed('Không tải được hồ sơ', 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.'), fixed: true }) };
  const me = { ...ME, ...s.me };
  const body = `<div class="t1-list">
    ${vcard(`<div class="t1-mehead"><span class="t1-mehead__ic">${icon('user')}</span><div><h2 class="t1-h4">${esc(`${me.lastName} ${me.firstName}`)}</h2><p class="t1-small t1-mt-xs">Tài khoản cá nhân</p></div>${s.staff ? '' : '<span class="t1-badge t1-badge--success t1-badge--md">Chủ sở hữu</span>'}</div>`)}
    <div class="t1-gap-md"></div>
    ${vcard(`<h2 class="t1-h4">Thông tin cá nhân</h2><div class="t1-gap-md"></div>${infoRow('Họ và tên đệm', me.lastName)}${infoRow('Tên', me.firstName)}${infoRow('Email đăng nhập', me.email)}${infoRow('Trạng thái email', me.emailStatus)}${infoRow('Số điện thoại', me.phone)}`)}
    <div class="t1-gap-xl"></div></div>`;
  const page = vScaffold({ ...base, body, bottomBar: actionBar(!!s.sheet), toastHtml: s.toast ? toast(...s.toast, { device: v.device, above: BAR2 }) : '' });
  const overlay = s.sheet === 'actions' ? adaptiveSheet(v.width, actionsSheet(), 'Thao tác tài khoản') : s.sheet === 'logout' ? adaptiveSheet(v.width, logoutSheet(), 'Đăng xuất') : '';
  return { page, overlay };
}

// ---------------------------------------------------------------- ID-22
export const DISCARD = { title: 'Bỏ thay đổi?', message: 'Các thay đổi chưa lưu sẽ bị mất.', cancel: 'Tiếp tục sửa', action: 'Bỏ thay đổi', destructive: true };
export const EDIT_ACCOUNT_STATES = {
  default: {}, changed: { values: { phone: '0987 111 222' }, dirty: true },
  errors: { values: { last: '', first: '', phone: '0912 34' }, dirty: true, errors: { last: 'Vui lòng nhập họ và tên đệm', first: 'Vui lòng nhập tên', phone: 'Số điện thoại không hợp lệ' } },
  submitting: { values: { phone: '0987 111 222' }, dirty: true, busy: true },
  discard: { values: { phone: '0987 111 222' }, dirty: true, dialog: true },
  'toast-failed': { values: { phone: '0987 111 222' }, dirty: true, toast: ['danger', 'Không lưu được', 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.'] },
  loading: { loading: true }, error: { error: true },
};

export function editAccountPage(v) {
  const s = EDIT_ACCOUNT_STATES[v.state];
  const base = { title: 'Chỉnh sửa thông tin', placeWidth: v.width };
  if (s.loading) return { page: vScaffold({ ...base, body: centerLoading(), fixed: true }) };
  if (s.error) return { page: vScaffold({ ...base, body: loadFailed('Không tải được hồ sơ', 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.'), fixed: true }) };
  const x = { last: ME.lastName, first: ME.firstName, phone: ME.phone, ...s.values };
  const e = s.errors || {};
  // VAvatar 48 (nền successBg, chữ success, cỡ 16.8) — thẻ có mũi tên nhưng không có onTap.
  const body = `<div class="t1-list">
    ${vcard(`<div class="t1-mehead"><span class="t1-avatar48">${esc(initials(`${ME.lastName} ${ME.firstName}`))}</span><div><h2 class="t1-h4">Ảnh đại diện</h2><p class="t1-small t1-mt-xs">Chạm để thay hoặc xóa ảnh</p></div>${icon('chevronRight', 't1-chev20')}</div>`)}
    <div class="t1-gap-lg"></div>
    <div class="t1-form">
      ${field({ label: 'Họ và tên đệm', required: true, control: input({ value: x.last, hint: 'Nhập họ và tên đệm', invalid: !!e.last }), error: e.last })}
      ${field({ label: 'Tên', required: true, control: input({ value: x.first, hint: 'Nhập tên', invalid: !!e.first }), error: e.first })}
      ${/* VField ngoài không invalid → ô số điện thoại không đổi viền đỏ dù có lỗi */ ''}${field({ label: 'Số điện thoại', control: input({ value: x.phone, hint: 'Nhập số điện thoại' }), error: e.phone })}
      ${field({ label: 'Email đăng nhập', control: input({ value: ME.email, disabled: true }) })}
    </div><div class="t1-gap-xl"></div></div>`;
  // Lưu: tắt khi chưa đổi gì; đang lưu → chữ "Đang lưu..." + tắt (không vòng xoay).
  const bar = `<div class="t1-bar-pad t1-bar-line t1-row2 t1-row2--8">${button('Hủy', { variant: 'secondary', full: true, disabled: !!s.busy })}${button(s.busy ? 'Đang lưu...' : 'Lưu thay đổi', { full: true, disabled: !s.dirty || !!s.busy })}</div>`;
  const page = vScaffold({ ...base, body, bottomBar: bar, toastHtml: s.toast ? toast(...s.toast, { device: v.device, above: BAR2 }) : '' });
  return { page, overlay: s.dialog ? confirmDialog(DISCARD) : '' };
}
