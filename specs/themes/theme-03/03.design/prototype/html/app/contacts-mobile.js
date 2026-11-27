// PT-08 Người liên hệ — bố cục iPhone "Danh bạ gọn" (người dùng chọn qua /impeccable live, 2026-11-27), cùng kiểu danh sách KH & NCC.
// Đầu trang: nút ‹ 44 + "Người liên hệ" + tên tổ chức (bỏ khối tên tổ chức riêng và nút "⋯" không làm gì). Ô tìm; "N người liên hệ";
// một khối trắng chung, kẻ mảnh lùi sau avatar; dòng: avatar 36 | tên + "Chính" / "Ngừng hoạt động" | "vai trò · SĐT" | email | chevron.
// Nút + nổi khi đã tải. Chữ lấy đúng contacts.js. CSS: styles/contacts-mobile.css (tiền tố mct-).
import { icon } from '../shared/icons.js';
import { button, centerLoading, esc, field, gap, initials, input, select, textArea } from './ds.js';
import { CONTACTS, ORG, PEOPLE, emptyArt, filterContacts } from './contacts.js';

const tag = (c) => (c.primary ? '<span class="mct-tag mct-tag--ok">Chính</span>' : '') + (c.inactive ? '<span class="mct-tag mct-tag--warn">Ngừng hoạt động</span>' : '');
const row = (c) => `<li><button type="button" class="mct-row"${c.inactive ? ' data-off' : ''}><span class="mct-av" aria-hidden="true">${esc(initials(c.name))}</span><span class="mct-t"><span class="mct-n"><b>${esc(c.name)}</b>${tag(c)}</span><small>${esc([c.role, c.phone].filter(Boolean).join(' · '))}</small>${c.email ? `<small>${esc(c.email)}</small>` : ''}</span>${icon('chevronRight')}</button></li>`;

export function contactsPageMobile(kind, { query = '' } = {}) {
  const head = `<header class="mct-bar"><button type="button" class="mct-back" aria-label="Quay lại">${icon('chevronLeft')}</button><div class="mct-titles"><h1>Người liên hệ</h1><p>${esc(ORG.name)}</p></div></header>`;
  let body;
  if (kind === 'loading') body = centerLoading({ material: true });
  else if (kind === 'error' || kind === 'no-permission') {
    const np = kind === 'no-permission';
    body = `<div class="t3-cerr"><i class="t3-cerr__icon">${icon('error')}</i>${gap(12)}<h2>${np ? 'Không có quyền quản lý người liên hệ' : 'Đã xảy ra lỗi'}</h2>${gap(8)}<p>${np ? 'Bạn không có quyền xem hoặc thay đổi người liên hệ của tổ chức này.' : 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.'}</p>${gap(16)}${button('Quay lại', { variant: 'secondary', fg: 'success' })}</div>`;
  } else if (kind === 'empty') {
    body = `<div class="t3-cempty">${emptyArt()}${gap(24)}<h2>Chưa có người liên hệ</h2>${gap(8)}<p>Thêm người liên hệ để liên kết làm việc<br>với tổ chức này.</p>${gap(16)}${button('Gợi ý thêm người liên hệ', { variant: 'secondary', fg: 'success' })}</div>`;
  } else {
    const list = filterContacts(CONTACTS, query);
    const clear = query ? `<button type="button" class="mct-clear" aria-label="Xóa tìm kiếm">${icon('close')}</button>` : '';
    body = `<div class="mct-scroll"><label class="mct-search">${icon('search')}<input type="search" value="${esc(query)}" placeholder="Tìm kiếm người liên hệ" aria-label="Tìm kiếm người liên hệ">${clear}</label>
      <p class="mct-count">${list.length} người liên hệ</p><ul class="mct-group">${list.map(row).join('')}</ul></div>`;
  }
  const showFab = !(kind === 'loading' || kind === 'error' || kind === 'no-permission');
  return `<div class="t3-page mct">${head}${body}${showFab ? `<button type="button" class="mct-fab" aria-label="Thêm người liên hệ">${icon('plus')}</button>` : ''}</div>`;
}

/**
 * PT-09 Thêm / sửa người liên hệ khổ iPhone (chọn qua /impeccable live 2026-11-27): cùng mẫu form hồ sơ (form-mobile.js, lớp mfm-).
 * Đầu trang ‹ + tiêu đề + tên tổ chức; thẻ "Thông tin liên hệ" (Bắt buộc), "Trong tổ chức" (công tắc liên hệ chính), "Ghi chú" (Tùy chọn);
 * chân dính: "Cần có để lưu: …" (chỉ mục còn thiếu) + "Hủy" | "Lưu". "Lưu" luôn bấm được như đặc tả (bấm khi thiếu → hiện lỗi ở ô).
 */
export function contactFormPageMobile(s) {
  const e = s.errors || {};
  const dis = s.submitting;
  const head = `<header class="mfm-bar"><button type="button" class="mfm-back" aria-label="Quay lại">${icon('chevronLeft')}</button><div class="mfm-titles"><h1>${s.edit ? 'Chỉnh sửa liên hệ' : 'Thêm người liên hệ'}</h1><p>${esc(ORG.name)}</p></div></header>`;
  if (s.loading) return `<div class="t3-page mfm">${head}<div class="t3-body">${centerLoading({ material: true })}</div></div>`;
  const grp = (t, tag, body) => `<section class="mfm-grp"><div class="mfm-gh"><h2>${t}</h2>${tag}</div><div class="mfm-card">${body}</div></section>`;
  const info = [
    field({ label: 'Họ và tên', required: true, error: e.name, control: input({ value: s.name, hint: 'Nhập họ và tên người liên hệ', invalid: !!e.name, disabled: dis }) }),
    field({ label: 'Vai trò liên hệ', required: true, error: e.role, control: select({ value: s.role, hint: 'Chọn vai trò' }).replace('class="t3-select', `class="t3-select${e.role ? ' is-invalid' : ''}${dis ? ' is-disabled' : ''}`) }),
    field({ label: 'SĐT chính', required: true, error: e.phone, control: input({ value: s.phone, hint: 'Nhập số điện thoại', invalid: !!e.phone, disabled: dis }) }),
    field({ label: 'Email', control: input({ value: s.email, hint: 'Nhập địa chỉ email', disabled: dis }) }),
  ].join('');
  const sw = `<div class="mcf-sw"><div><b>Người liên hệ chính</b><span>Là người liên hệ chính cho tổ chức</span></div><span class="t3-switch${s.primary ? ' is-on' : ''}${dis ? ' is-disabled' : ''}" role="switch" aria-checked="${!!s.primary}"><i></i></span></div>`;
  const note = field({ control: textArea({ value: s.note, hint: 'Nhập ghi chú liên quan', minLines: 2 }) });
  const miss = [!s.name.trim() && 'họ và tên', !s.role && 'vai trò', !s.phone.trim() && 'SĐT chính'].filter(Boolean);
  const need = miss.length ? `<p class="mfm-need">${icon('info')}<span>Cần có để lưu: ${esc(miss.join(', '))}</span></p>` : '';
  const err = s.serverError ? `<div class="t3-cformerr">${esc(s.serverError)}</div>` : '';
  return `<div class="t3-page mfm">${head}
    <div class="mfm-scroll">${err}${grp('Thông tin liên hệ', '<span class="mfm-tag is-req">Bắt buộc</span>', info)}${grp('Trong tổ chức', '', sw)}${grp('Ghi chú', '<span class="mfm-tag">Tùy chọn</span>', note)}</div>
    <footer class="mfm-foot">${need}<div class="mfm-btns">${button('Hủy', { variant: 'secondary', full: true })}${button('Lưu', { full: true })}</div></footer>
  </div>`;
}

/**
 * PT-10 Chọn từ cá nhân khổ iPhone (chọn qua /impeccable live 2026-11-27): đầu trang ‹ + tiêu đề + "Thêm vào <tổ chức>"; ô tìm;
 * "N cá nhân · đã chọn M"; một khối trắng kẻ mảnh, dòng: avatar | tên + "SĐT · email" | ô tick vuông (chọn nhiều — bản cũ ô tròn như radio);
 * dòng đã chọn nền brand. Chân dính "Hủy" | "Chọn (M)" (tắt khi chưa chọn), chừa vùng an toàn 34.
 */
export function selectPageMobile(kind) {
  const selected = kind === 'selected' ? [0, 3] : [];
  const head = `<header class="mct-bar"><button type="button" class="mct-back" aria-label="Quay lại">${icon('chevronLeft')}</button><div class="mct-titles"><h1>Chọn từ cá nhân</h1><p>Thêm vào ${esc(ORG.name)}</p></div></header>`;
  const q = kind === 'empty' ? 'Hoàng Yến' : '';
  const clear = q ? `<button type="button" class="mct-clear" aria-label="Xóa tìm kiếm">${icon('close')}</button>` : '';
  const search = `<label class="mct-search">${icon('search')}<input type="search" value="${esc(q)}" placeholder="Tìm kiếm tên, SĐT, email" aria-label="Tìm kiếm tên, SĐT, email">${clear}</label>`;
  let list;
  if (kind === 'loading') list = `<div class="mcs-center">${centerLoading({ material: true })}</div>`;
  // Lỗi (chọn qua /impeccable live 2026-11-27, cùng kiểu lỗi danh sách KH & NCC): ô tìm mờ, giữa màn vòng đỏ nhạt + câu lỗi + "Thử lại"; chân chỉ "Hủy".
  else if (kind === 'error') list = `<div class="mcs-err" role="alert"><span class="mcs-err__ic" aria-hidden="true">${icon('cloudOff')}</span><p>Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.</p>${button('Thử lại').replace('<span>', `${icon('rotate')}<span>`)}</div>`;
  else if (kind === 'empty') list = '<p class="mcs-msg">Không tìm thấy cá nhân nào.</p>';
  else {
    list = `<p class="mct-count">${PEOPLE.length} cá nhân · đã chọn ${selected.length}</p><ul class="mct-group mcs-group">${PEOPLE.map((p, i) => {
      const on = selected.includes(i);
      return `<li><button type="button" class="mcs-row${on ? ' is-on' : ''}" role="checkbox" aria-checked="${on}"><span class="mct-av" aria-hidden="true">${esc(initials(p.name))}</span><span class="mct-t"><b>${esc(p.name)}</b><small>${esc([p.phone, p.email].filter(Boolean).join(' · '))}</small></span><span class="mcs-box${on ? ' is-on' : ''}" aria-hidden="true">${on ? icon('check') : ''}</span></button></li>`;
    }).join('')}</ul>`;
  }
  const err = kind === 'error';
  return `<div class="t3-page mct">${head}<div class="mct-scroll mcs-scroll">${err ? `<div class="mcs-dim">${search}</div>` : search}${list}</div>
    <footer class="mcs-foot${err ? ' is-one' : ''}">${button('Hủy', { variant: 'secondary', full: true })}${err ? '' : button(`Chọn (${selected.length})`, { full: true, disabled: !selected.length })}</footer></div>`;
}
