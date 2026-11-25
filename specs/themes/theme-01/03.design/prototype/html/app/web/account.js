// Bố cục WEB (khung ≥ 840), chọn qua impeccable live 2026-11-24. iPhone giữ bản chép Flutter ở ../account.js; trạng thái mẫu, hàm kiểm, sheet dùng chung lấy từ đó.
import { icon } from '../../shared/icons.js';
import { ACCOUNT_STATES, BAR2, DISCARD, EDIT_ACCOUNT_STATES, infoRow, initials, logoutSheet, ME } from '../account.js';
import { adaptiveSheet, button, centerLoading, confirmDialog, esc, field, iconButton, input, toast, vScaffold } from '../ds.js';
import { loadFailed } from '../org.js';

export function accountPage(v) {
  const s = ACCOUNT_STATES[v.state];
  const base = { title: 'Tài khoản của tôi', placeWidth: v.width };
  if (s.loading) return { page: vScaffold({ ...base, body: centerLoading(), fixed: true }) };
  if (s.error) return { page: vScaffold({ ...base, body: loadFailed('Không tải được hồ sơ', 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.'), fixed: true }) };
  const me = { ...ME, ...s.me };
  // Thiết kế lại qua impeccable live (2026-11-24): web ≥ 900 hai cột — trái thẻ hồ sơ (chữ viết tắt 72, tên, email, nhãn Chủ sở hữu, "Đăng xuất");
  // phải "Thông tin cá nhân" (nút bút chì) + "Bảo mật" (Đặt lại mật khẩu). Hẹp: xếp dọc. Không còn thanh "Thao tác" / sheet.
  const name = `${me.lastName} ${me.firstName}`;
  const sec = (title, action, inner) => `<section class="t1-orgsec"><div class="t1-orgsec__head"><h2>${esc(title)}</h2>${action}</div>${inner}</section>`;
  const body = `<div class="t1-orgp"><div class="t1-acgrid">
    <div class="t1-accard"><span class="t1-avatar t1-avatar--xl" aria-hidden="true">${esc(initials(name))}</span><h1>${esc(name)}</h1><p>${esc(me.email)}</p>
      ${s.staff ? '' : '<span class="t1-badge t1-badge--success">Chủ sở hữu</span>'}
      <div class="t1-accard__out">${button('Đăng xuất', { variant: 'secondary', full: true, cls: 't1-btn--danger-outline' })}</div></div>
    <div class="t1-acright">
      ${sec('Thông tin cá nhân', iconButton('edit', 'Chỉnh sửa thông tin cá nhân', { size: 20 }), `<div class="t1-stack4">${infoRow('Họ và tên đệm', me.lastName)}${infoRow('Tên', me.firstName)}${infoRow('Email đăng nhập', me.email)}${infoRow('Trạng thái email', me.emailStatus)}${infoRow('Số điện thoại', me.phone)}</div>`)}
      ${sec('Bảo mật', '', `<div class="t1-acpw"><div><b>Đặt lại mật khẩu</b><p class="t1-small">Xác minh email và tạo mật khẩu mới</p></div>${button('Đặt lại mật khẩu', { variant: 'secondary' })}</div>`)}
    </div></div></div>`;
  const page = vScaffold({ ...base, body, toastHtml: s.toast ? toast(...s.toast, { device: v.device, above: 0 }) : '' });
  // Web cần cột rộng hơn 720 cho hai cột.
  const wide = v.width >= 900 ? page.replace(/(<div class="t1-col" style=")[^"]*(")/, '$1max-width:1040px$2') : page;
  const overlay = s.sheet === 'logout' ? adaptiveSheet(v.width, logoutSheet(), 'Đăng xuất') : '';
  return { page: wide, overlay };
}

export function editAccountPage(v) {
  const s = EDIT_ACCOUNT_STATES[v.state];
  const base = { title: 'Chỉnh sửa thông tin', placeWidth: v.width };
  if (s.loading) return { page: vScaffold({ ...base, body: centerLoading(), fixed: true }) };
  if (s.error) return { page: vScaffold({ ...base, body: loadFailed('Không tải được hồ sơ', 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.'), fixed: true }) };
  const x = { last: ME.lastName, first: ME.firstName, phone: ME.phone, ...s.values };
  const e = s.errors || {};
  // Thiết kế lại qua impeccable live (2026-11-24): cột 560, một thẻ — dòng "Ảnh đại diện" (chữ viết tắt 48 + mô tả + mũi tên) → gạch → 4 ô xếp dọc.
  const body = `<div class="t1-formpage"><div class="t1-formcard">
    <button type="button" class="t1-avrow"><span class="t1-avatar t1-avatar--lg" aria-hidden="true">${esc(initials(`${ME.lastName} ${ME.firstName}`))}</span><span><b>Ảnh đại diện</b><small>Chạm để thay hoặc xóa ảnh</small></span>${icon('chevronRight', 't1-chev20')}</button>
    <hr class="t1-avsep">
    <div class="t1-form">
      ${field({ label: 'Họ và tên đệm', required: true, control: input({ value: x.last, hint: 'Nhập họ và tên đệm', invalid: !!e.last }), error: e.last })}
      ${field({ label: 'Tên', required: true, control: input({ value: x.first, hint: 'Nhập tên', invalid: !!e.first }), error: e.first })}
      ${/* VField ngoài không invalid → ô số điện thoại không đổi viền đỏ dù có lỗi */ ''}${field({ label: 'Số điện thoại', control: input({ value: x.phone, hint: 'Nhập số điện thoại' }), error: e.phone })}
      ${field({ label: 'Email đăng nhập', control: input({ value: ME.email, disabled: true }) })}
    </div></div></div>`;
  // Lưu: tắt khi chưa đổi gì; đang lưu → chữ "Đang lưu..." + tắt (không vòng xoay).
  const bar = `<div class="t1-bar-pad t1-bar-line t1-row2 t1-row2--8">${button('Hủy', { variant: 'secondary', full: true, disabled: !!s.busy })}${button(s.busy ? 'Đang lưu...' : 'Lưu thay đổi', { full: true, disabled: !s.dirty || !!s.busy })}</div>`;
  const page = vScaffold({ ...base, body, bottomBar: bar, toastHtml: s.toast ? toast(...s.toast, { device: v.device, above: BAR2 }) : '' });
  const narrow = v.width >= 600 ? page.replace(/(<div class="t1-col" style=")[^"]*(")/g, '$1max-width:560px$2') : page;
  return { page: narrow, overlay: s.dialog ? confirmDialog(DISCARD) : '' };
}
