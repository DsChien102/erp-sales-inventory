// PT-08 Người liên hệ — bố cục web ≥ 1024 "Bảng" (người dùng chọn qua /impeccable live, 2026-11-27).
// Đầu trang: "‹ Hồ sơ KH & NCC" + "Người liên hệ" + tên tổ chức · "Tổ chức • KH & NCC" + nút chính "Thêm người liên hệ" (thay nút + nổi;
// bỏ "⋯" bấm không làm gì). Thân: ô tìm + "N người liên hệ"; bảng Họ và tên (+ Chính / Ngừng hoạt động) | Vai trò | SĐT | Email | nút
// Chỉnh sửa liên hệ / Đặt làm chính / Gỡ khỏi tổ chức trên từng dòng (thay sheet "Thao tác"). iPhone giữ contactsPage. CSS: styles/detail-web.css (wcn-).
import { icon } from '../shared/icons.js';
import { banner, button, centerLoading, esc, field, initials, input, select, textArea } from './ds.js';
import { alertDialogWeb, confirmDialogWeb } from './detail-web.js';
import { CONTACTS, ORG, PEOPLE, canSetPrimary, emptyArt, filterContacts } from './contacts.js';

const dash = '<span class="wcn-dash">—</span>';
const tags = (c) => `${c.primary ? '<span class="wcn-tag wcn-tag--ok">Chính</span>' : ''}${c.inactive ? '<span class="wcn-tag wcn-tag--warn">Ngừng hoạt động</span>' : ''}`;
const ib = (ic, label, cls = '') => `<button type="button" class="wcn-ib ${cls}" aria-label="${label}" title="${label}">${icon(ic)}</button>`;

/** "Thao tác" của một người liên hệ — menu thả xuống ở cuối dòng (thay sheet "Thao tác" + "Hủy"; chọn 2026-11-27). */
function rowMenu(c) {
  const mi = (ic, t, cls = '') => `<button type="button" role="menuitem" class="wd-mi ${cls}"><span class="wd-mi__ic">${icon(ic)}</span><span class="wd-mi__t"><b>${esc(t)}</b></span></button>`;
  return `<div class="wd-menu wcn-rowmenu" role="menu" aria-label="Thao tác">${mi('edit', 'Chỉnh sửa liên hệ')}${canSetPrimary(c) ? mi('star', 'Đặt làm chính') : ''}<hr>${mi('trash', 'Gỡ khỏi tổ chức', 'wd-mi--danger')}</div>`;
}

function row(c, menu = false) {
  const acts = `${ib('edit', 'Chỉnh sửa liên hệ')}${canSetPrimary(c) ? ib('star', 'Đặt làm chính') : '<span class="wcn-ib-gap"></span>'}${ib('trash', 'Gỡ khỏi tổ chức', 'is-danger')}${menu ? rowMenu(c) : ''}`;
  return `<tr${c.inactive ? ' data-off' : ''}${menu ? ' class="is-menu"' : ''}><td><span class="wcn-name"><span class="wcn-av">${esc(initials(c.name))}</span><b>${esc(c.name)}</b>${tags(c)}</span></td>
    <td>${c.role ? esc(c.role) : dash}</td><td class="wcn-mono">${c.phone ? esc(c.phone) : dash}</td><td>${c.email ? esc(c.email) : dash}</td><td class="wcn-acts"><span class="wd-menuwrap">${acts}</span></td></tr>`;
}

/** "Thêm người liên hệ" — menu thả xuống (chọn qua /impeccable live, 2026-11-27), thay sheet 2 thẻ + "Hủy". cls: căn trái/phải theo nút mở. */
export function addMethodMenu(cls = '') {
  const mi = (ic, t, d) => `<button type="button" role="menuitem" class="wd-mi"><span class="wd-mi__ic">${icon(ic)}</span><span class="wd-mi__t"><b>${esc(t)}</b><small>${esc(d)}</small></span></button>`;
  return `<div class="wd-menu ${cls}" role="menu" aria-label="Thêm người liên hệ">${mi('userPlus', 'Tạo người liên hệ mới', 'Nhập thông tin để tạo người liên hệ mới')}${mi('search', 'Chọn từ cá nhân có sẵn', 'Tìm kiếm và liên kết cá nhân đã có trong hệ thống')}</div>`;
}

export function contactsPageWeb(kind, { query = '', addMenu = false, menuRow = -1 } = {}) {
  const loaded = !['loading', 'error', 'no-permission'].includes(kind);
  const head = `<header class="wcn-head"><nav class="wcn-crumb"><button type="button">${icon('chevronLeft')}Hồ sơ KH &amp; NCC</button></nav>
    <div class="wcn-head__row"><div><h1>Người liên hệ</h1>${loaded ? `<p><b>${esc(ORG.name)}</b> · Tổ chức • ${esc(ORG.roles)}</p>` : ''}</div>
    ${loaded ? `<span class="wd-menuwrap">${button('Thêm người liên hệ', { cls: 'wcn-add', attrs: `aria-haspopup="menu" aria-expanded="${addMenu}"` }).replace('<span>', `${icon('plus')}<span>`)}${addMenu ? addMethodMenu() : ''}</span>` : ''}</div></header>`;
  let body;
  if (kind === 'loading') body = centerLoading({ material: true });
  else if (kind === 'error' || kind === 'no-permission') {
    const np = kind === 'no-permission';
    body = `<div class="t3-cerr"><i class="t3-cerr__icon">${icon('error')}</i><i class="t3-gap" style="height:12px"></i><h2>${np ? 'Không có quyền quản lý người liên hệ' : 'Đã xảy ra lỗi'}</h2><i class="t3-gap" style="height:8px"></i><p>${np ? 'Bạn không có quyền xem hoặc thay đổi người liên hệ của tổ chức này.' : 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.'}</p><i class="t3-gap" style="height:16px"></i>${button('Quay lại', { variant: 'secondary', fg: 'success' })}</div>`;
  } else if (kind === 'empty') {
    body = `<div class="wcn-scroll"><div class="wcn-wrap"><section class="wcn-card wcn-empty">${emptyArt()}<h2>Chưa có người liên hệ</h2><p>Thêm người liên hệ để liên kết làm việc<br>với tổ chức này.</p>${button('Gợi ý thêm người liên hệ', { variant: 'secondary', fg: 'success' })}</section></div></div>`;
  } else {
    const list = filterContacts(CONTACTS, query);
    const clear = query ? `<button type="button" class="wcn-clear" aria-label="Xóa từ khóa">${icon('close')}</button>` : '';
    body = `<div class="wcn-scroll"><div class="wcn-wrap">
      <div class="wcn-tool"><label class="wcn-search">${icon('search')}<input type="search" value="${esc(query)}" placeholder="Tìm kiếm người liên hệ" aria-label="Tìm kiếm người liên hệ">${clear}</label><span class="wcn-count">${list.length} người liên hệ</span></div>
      <section class="wcn-card"><table class="wcn-table"><thead><tr><th>Họ và tên</th><th>Vai trò</th><th>Số điện thoại</th><th>Email</th><th><span class="wcn-sr">Thao tác</span></th></tr></thead><tbody>${list.map((c) => row(c, CONTACTS.indexOf(c) === menuRow)).join('')}</tbody></table></section>
    </div></div>`;
  }
  return `<div class="t3-page wcn">${head}${body}</div>`;
}

// ---------------------------------------------------------------- PT-09 Thêm / sửa người liên hệ — "Form + cột tóm tắt" (chọn qua /impeccable live, 2026-11-27)
// Cùng mẫu PT-05 web (form-web.css, wfm-): đầu trang "‹ Người liên hệ" + tiêu đề + tên tổ chức; thẻ form ô 2 cột (công tắc
// "Người liên hệ chính" trong khung riêng, ghi chú cả hàng); cột phải "Cần có để lưu" (✓ khi đủ) + "Lưu" + "Hủy" (thay chữ trên app bar).
export function contactFormPageWeb(s) {
  const e = s.errors || {};
  const dis = !!s.submitting;
  const title = s.edit ? 'Chỉnh sửa liên hệ' : 'Thêm người liên hệ';
  const head = `<header class="wcn-head"><nav class="wcn-crumb"><button type="button">${icon('chevronLeft')}Người liên hệ</button></nav><h1>${title}</h1><p>${esc(ORG.name)}</p></header>`;
  if (s.loading) return `<div class="t3-page wcn">${head}${centerLoading({ material: true })}</div>`;
  const roleSel = select({ value: s.role, hint: 'Chọn vai trò' }).replace('class="t3-select', `class="t3-select${e.role ? ' is-invalid' : ''}${dis ? ' is-disabled' : ''}`);
  const prim = `<label class="wcf-prim"><span><b>Người liên hệ chính</b><small>Là người liên hệ chính cho tổ chức</small></span><span class="t3-switch${s.primary ? ' is-on' : ''}${dis ? ' is-disabled' : ''}" role="switch" aria-checked="${!!s.primary}"><i></i></span></label>`;
  const grid = `<div class="wfm-grid">
    ${field({ label: 'Họ và tên', required: true, error: e.name, control: input({ value: s.name, hint: 'Nhập họ và tên người liên hệ', invalid: !!e.name, disabled: dis }) })}
    ${field({ label: 'Vai trò liên hệ', required: true, error: e.role, control: roleSel })}
    ${field({ label: 'SĐT chính', required: true, error: e.phone, control: input({ value: s.phone, hint: 'Nhập số điện thoại', invalid: !!e.phone, disabled: dis }) })}
    ${field({ label: 'Email', control: input({ value: s.email, hint: 'Nhập địa chỉ email', disabled: dis }) })}
    <div class="wfm-wide">${prim}</div>
    <div class="wfm-wide">${field({ label: 'Ghi chú', control: textArea({ value: s.note, hint: 'Nhập ghi chú liên quan', minLines: 2 }) })}</div></div>`;
  const need = [['Họ và tên', !!s.name.trim()], ['Vai trò liên hệ', !!s.role], ['SĐT chính', !!s.phone.trim()]];
  const name = s.name.trim() || (s.edit ? 'Người liên hệ' : 'Người liên hệ mới');
  const side = `<aside class="wfm-side"><div class="wfm-sum">
    <div class="wfm-sum__who"><span class="wfm-av">${icon('user')}</span><div><b>${esc(name)}</b><small>${esc(s.role || ORG.name)}</small></div></div>
    <h3>Cần có để lưu</h3><ul class="wfm-check">${need.map(([l, ok]) => `<li class="${ok ? 'is-ok' : ''}"><i>${ok ? icon('check') : ''}</i>${esc(l)}</li>`).join('')}</ul>
    <div class="wfm-sum__acts">${button('Lưu', { full: true, loading: dis })}${button('Hủy', { variant: 'tertiary', full: true, disabled: dis })}</div></div></aside>`;
  const err = s.serverError ? banner('error', s.serverError) : '';
  return `<div class="t3-page wcn">${head}<div class="t3-body wfm"><div class="wfm-scroll"><div class="wfm-cols">
    <div class="wfm-stack">${err}<section class="wfm-card">${grid}</section></div>${side}</div></div></div></div>`;
}

// ---------------------------------------------------------------- PT-10 Chọn từ cá nhân — hộp thoại đè trên bảng Người liên hệ (chọn qua /impeccable live, 2026-11-27)
// Hộp 560: tiêu đề + tên tổ chức + nút Đóng; ô tìm; danh sách ô tick vuông (chọn nhiều — thay vòng tròn giống radio); dòng chọn nền xanh nhạt;
// chân "N đã chọn" + "Hủy" | "Chọn (N)". Đang tải / trống / lỗi nằm trong vùng danh sách. iPhone giữ selectPage (contacts.js).
export function selectDialogWeb(kind) {
  const sel = kind === 'selected' ? [0, 3] : [];
  const cb = (on) => `<span class="wsl-cb${on ? ' is-on' : ''}" aria-hidden="true">${on ? icon('check') : ''}</span>`;
  let list;
  if (kind === 'loading') list = `<div class="wsl-state">${centerLoading({ material: true })}</div>`;
  else if (kind === 'error') list = '<div class="wsl-state"><p class="wsl-msg is-danger">Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.</p></div>';
  else if (kind === 'empty') list = '<div class="wsl-state"><p class="wsl-msg">Không tìm thấy cá nhân nào.</p></div>';
  else {
    list = `<ul class="wsl-list">${PEOPLE.map((p, i) => `<li><button type="button" role="checkbox" aria-checked="${sel.includes(i)}" class="wsl-li${sel.includes(i) ? ' is-sel' : ''}">${cb(sel.includes(i))}<span class="wcn-av">${esc(initials(p.name))}</span><span class="wsl-li__t"><b>${esc(p.name)}</b><small>${[p.phone && `<span class="wcn-mono">${esc(p.phone)}</span>`, p.email && esc(p.email)].filter(Boolean).join(' · ')}</small></span></button></li>`).join('')}</ul>`;
  }
  const q = kind === 'empty' ? 'Hoàng Yến' : '';
  return `<div class="sh-scrim sh-scrim--dialog"><section class="t3-dialog wsl" role="dialog" aria-modal="true" aria-label="Chọn từ cá nhân">
    <header class="wsl-head"><div><h2>Chọn từ cá nhân</h2><p>${esc(ORG.name)}</p></div><button type="button" class="wpc-x" aria-label="Đóng">${icon('close')}</button></header>
    <div class="wsl-search"><label class="wcn-search">${icon('search')}<input type="search" value="${esc(q)}" placeholder="Tìm kiếm tên, SĐT, email" aria-label="Tìm kiếm tên, SĐT, email"></label></div>
    ${list}
    <footer class="wsl-foot"><span class="wsl-n"><b>${sel.length}</b> đã chọn</span>${button('Hủy', { variant: 'secondary' })}${button(`Chọn (${sel.length})`, { disabled: !sel.length })}</footer>
  </section></div>`;
}

// ---------------------------------------------------------------- Hộp xác nhận của người liên hệ (web)
/** "Đổi người liên hệ chính?" — mẫu cảnh báo canh trái + hàng avatar cũ → mới. */
export const changePrimaryDialogWeb = (from, to) => alertDialogWeb({
  ic: 'star', tone: 'success', title: 'Đổi người liên hệ chính?',
  desc: `<p>${esc(from)} hiện đang là người liên hệ chính. Nếu tiếp tục, ${esc(to)} sẽ trở thành người liên hệ chính mới.</p>
    <div class="wcn-swap"><span><span class="wcn-av">${esc(initials(from))}</span>${esc(from)}</span>${icon('arrowRight')}<span><span class="wcn-av">${esc(initials(to))}</span><b>${esc(to)}</b></span></div>`,
  actions: `${button('Quay lại', { variant: 'secondary' })}${button('Xác nhận đổi')}`,
});

/** "Gỡ người liên hệ?" — mẫu liệt kê hệ quả (như Ngừng hoạt động / Xóa hồ sơ), không có ô lý do. */
export const removeContactDialogWeb = () => confirmDialogWeb({
  title: 'Gỡ người liên hệ?',
  items: [['del', 'userX', 'Người này sẽ được gỡ khỏi danh sách liên hệ của tổ chức.'], ['keep', 'check', 'Hồ sơ cá nhân không bị xóa khỏi hệ thống.']],
  confirm: 'Gỡ liên hệ', tone: 'danger', reason: false,
});
