// ID-21 Tài khoản của tôi · ID-22 Chỉnh sửa thông tin. Chép từ:
//   apps/erp/lib/features/iam/presentation/users/views/{my_account_page, edit_my_account_page}.dart
//   apps/erp/lib/features/iam/presentation/users/widgets/{my_account_actions_bottom_sheet, logout_confirmation_bottom_sheet}.dart
//   core/router/app_router.dart (/more/my-account: GoRoute gốc, ngoài StoreShell; onLogout → toast lỗi)
// Sửa thông tin mở bằng Navigator.push (không có route riêng); ID-23 (đặt lại mật khẩu) đã vẽ ở đợt 1 (reset/from-account).
import { icon } from '../shared/icons.js';
import { BAR_H, loadFailed } from './org.js';
import { badge, button, card, centerLoading, confirmDialog, esc, field, input, toast, vScaffold, adaptiveSheet } from './ds.js';

export const ME = { lastName: 'Nguyễn Thị', firstName: 'Lan', email: 'lan@anphat.vn', emailStatus: 'Đã xác minh', phone: '0912 345 678' };
/** VAvatar._initialsFrom: nhiều từ → chữ đầu từ đầu + chữ đầu từ cuối, viết hoa. */
export const initials = (name) => {
  const w = String(name).trim().split(/\s+/).filter(Boolean);
  if (!w.length) return '?';
  return (w.length === 1 ? w[0][0] : w[0][0] + w[w.length - 1][0]).toUpperCase();
};

/** Thanh dưới tự vẽ (màn sửa): đệm 16 + nền surface + gạch trên 1 (chồng gạch của VPageScaffold) + SafeArea → cao 78. */
export const BAR2 = 78;

/** _buildInfoRow: đệm dọc 8; nhãn bodyDefault textSecondary, khe 8, giá trị bodyDefault w700 phải; rỗng → "(chưa có)" textMuted w thường. */
export const infoRow = (l, val) => `<div class="t1-acrow"><span>${esc(l)}</span><b${val ? '' : ' class="is-empty"'}>${esc(val || '(chưa có)')}</b></div>`;

export const ACCOUNT_STATES = {
  owner: {}, staff: { staff: true }, 'no-phone': { me: { phone: '' } }, loading: { loading: true }, error: { error: true },
  logout: { sheet: 'logout' },
  'toast-updated': { toast: ['success', 'Thành công', 'Đã cập nhật thông tin cá nhân'] },
  'toast-logout-failed': { toast: ['danger', 'Đăng xuất thất bại', 'Không thể đóng phiên trên máy.'] },
};

/** Dòng thao tác (iPhone, impeccable live 2026-11-25; thay nút + sheet "Thao tác"): icon 20 + tên + mô tả + mũi tên; Đăng xuất màu danger. */
const actRow = (ic, title, sub, danger = false) => `<button type="button" class="t1-actlist__row${danger ? ' is-danger' : ''}">${icon(ic, 't1-actlist__ic')}<span class="t1-actlist__text"><b>${esc(title)}</b><small>${esc(sub)}</small></span>${icon('chevronRight', 't1-actlist__go')}</button>`;
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
  // Ô tròn chữ viết tắt + tên + nhãn → "Thông tin cá nhân" → "Thao tác tài khoản" (sửa, đặt lại mật khẩu, đăng xuất).
  const name = `${me.lastName} ${me.firstName}`;
  const row = (l, val) => `<div class="t1-rows__row"><span>${esc(l)}</span><b${val ? '' : ' class="is-empty"'}>${esc(val || '(chưa có)')}</b></div>`;
  const body = `<div class="t1-list t1-acc">
    <div class="t1-orgm__head"><span class="t1-orgm__avatar" aria-hidden="true">${esc(initials(name))}</span><div><div class="t1-selrole__name"><h2>${esc(name)}</h2>${s.staff ? '' : badge('Chủ sở hữu', 'success')}</div><p>Tài khoản cá nhân</p></div></div>
    <h3 class="t1-acc__title">Thông tin cá nhân</h3>
    ${card(`${row('Họ và tên đệm', me.lastName)}${row('Tên', me.firstName)}${row('Email đăng nhập', me.email)}${row('Trạng thái email', me.emailStatus)}${row('Số điện thoại', me.phone)}`, 't1-rows')}
    <h3 class="t1-acc__title t1-acc__title--next">Thao tác tài khoản</h3>
    ${card(`${actRow('edit', 'Chỉnh sửa thông tin cá nhân', 'Cập nhật hồ sơ cá nhân')}${actRow('lock', 'Đặt lại mật khẩu', 'Xác minh email và tạo mật khẩu mới')}${actRow('logout', 'Đăng xuất', 'Kết thúc phiên sử dụng hiện tại', true)}`, 't1-actlist')}
  </div>`;
  const page = vScaffold({ ...base, body, toastHtml: s.toast ? toast(...s.toast, { device: v.device }) : '' });
  return { page, overlay: s.sheet === 'logout' ? adaptiveSheet(v.width, logoutSheet(), 'Đăng xuất') : '' };
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
  // Bố cục iPhone thiết kế lại qua impeccable live (2026-11-25): thẻ "Ảnh đại diện" (Flutter chưa nối onTap) → thẻ form (họ + tên cùng hàng 3 : 2, số điện thoại, email khoá một dòng).
  const body = `<div class="t1-list t1-accedit">
    ${card(`<button type="button" class="t1-accedit__pic"><span class="t1-orgm__avatar" aria-hidden="true">${esc(initials(`${ME.lastName} ${ME.firstName}`))}</span><span class="t1-accedit__text"><b>Ảnh đại diện</b><small>Chạm để thay hoặc xóa ảnh</small></span>${icon('chevronRight', 't1-actlist__go')}</button>`)}
    ${card(`<div class="t1-form">
      <div class="t1-signup__names">
        ${field({ label: 'Họ và tên đệm', required: true, control: input({ value: x.last, hint: 'Nhập họ và tên đệm', invalid: !!e.last }), error: e.last })}
        ${field({ label: 'Tên', required: true, control: input({ value: x.first, hint: 'Nhập tên', invalid: !!e.first }), error: e.first })}
      </div>
      ${/* VField ngoài không invalid → ô số điện thoại không đổi viền đỏ dù có lỗi */ ''}${field({ label: 'Số điện thoại', control: input({ value: x.phone, hint: 'Nhập số điện thoại' }), error: e.phone })}
      <div class="t1-invreg__mail"><span>Email đăng nhập</span><b>${esc(ME.email)}</b>${icon('lock')}</div>
    </div>`, 't1-card--pad')}
  </div>`;
  // Lưu: tắt khi chưa đổi gì; đang lưu → chữ "Đang lưu..." + tắt (không vòng xoay).
  const bar = `<div class="t1-bar-pad t1-row2 t1-row2--8">${button('Hủy', { variant: 'secondary', full: true, disabled: !!s.busy })}${button(s.busy ? 'Đang lưu...' : 'Lưu thay đổi', { full: true, disabled: !s.dirty || !!s.busy, attrs: 'data-primary' })}</div>`;
  const page = vScaffold({ ...base, body, bottomBar: bar, toastHtml: s.toast ? toast(...s.toast, { device: v.device, above: BAR_H }) : '' });
  return { page, overlay: s.dialog ? confirmDialog(DISCARD) : '' };
}
