// Bố cục WEB (khung ≥ 840), chọn qua impeccable live 2026-11-24. iPhone ở ../users.js; trạng thái mẫu, hàm kiểm, sheet dùng chung lấy từ đó.
import { icon } from '../../shared/icons.js';
import { INVITATION_BADGE, INVITATIONS, MEMBER_BADGE, MEMBERS, invitationById, memberById, statusDetail } from '../admin-data.js';
import {
  adaptiveSheet, appBar, badge, banner, button, centerLoading, chipRow, esc, field, fieldDesc, fieldError, iconButton, input, kv,
  radio, searchBar, skeleton, tabs, toast, vcard, vScaffold,
} from '../ds.js';
import { BAR_H, loadFailed } from '../org.js';
import {
  changeRoleSheet, changeRoleTitle, filterSheet, INVITATION_STATES, INVITE_STATES, LIFECYCLE, lifecycleSheet, LIST_STATES, MEMBER_STATES, revokeSheet, SELECT_ROLES, SELECT_STATES,
  subtitle, usersEmpty,
} from '../users.js';

/** Chữ viết tắt: ký tự đầu của tên (từ cuối họ tên). */
const initial = (name) => esc(String(name).trim().split(/\s+/).pop()[0] || '');

const avatar = (name) => `<span class="t1-avatar" aria-hidden="true">${initial(name)}</span>`;

/** Đang tải (VSkeletonScope): 4 dòng bảng giả dưới hàng tiêu đề thật. */
const tableSkeleton = (cols) => `<div class="t1-utable" role="table" aria-busy="true" aria-label="Đang tải"><div class="t1-utable__tr t1-utable__th" role="row">${cols.map((c) => `<span role="columnheader">${esc(c)}</span>`).join('')}<span></span></div>
  ${[0, 1, 2, 3].map(() => `<div class="t1-utable__tr t1-utable__tr--skel"><span class="t1-utable__who">${skeleton({ w: 36, h: 36, circle: true })}<span class="t1-skelcol">${skeleton({ w: 160, h: 16 })}${skeleton({ w: 120, h: 12 })}</span></span><span>${skeleton({ w: 120 })}</span><span>${skeleton({ w: 72, h: 22 })}</span><span>${cols[3] ? skeleton({ w: 110 }) : ''}</span><span></span></div>`).join('')}</div>`;

/** Lọc danh sách theo trạng thái mẫu, chọn khối rỗng / lỗi, rồi vẽ bảng toàn màn. */
function usersListPage(s, toastHtml) {
  let items = s.tab === 0 ? MEMBERS : INVITATIONS.filter((i) => !(s.revoked && i.id === 'i1'));
  if (s.chip === 'Tạm ngừng') items = items.filter((m) => m.status === 'suspended');
  if (s.roleFilter) items = items.filter((m) => m.role === s.roleFilter);
  if (s.empty) items = [];
  let list = ''; // khối rỗng / lỗi; '' = có dữ liệu, null = đang tải
  if (s.loading) list = null;
  else if (s.failure === 'forbidden') list = usersEmpty({ ic: 'shield', tone: 'warning', title: 'Bạn không có quyền quản lý', sub: 'Liên hệ Chủ tổ chức hoặc Quản trị viên để được cấp quyền phù hợp.', action: 'Quay lại' });
  else if (s.failure) list = usersEmpty({ ic: 'close', tone: 'danger', title: 'Không thể tải danh sách', sub: 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.', action: 'Thử lại', danger: true });
  else if (!items.length && (s.query || s.chip)) list = usersEmpty({ ic: 'search', title: 'Không tìm thấy kết quả', sub: 'Thử từ khóa khác hoặc xóa bộ lọc đang áp dụng.', action: 'Xóa bộ lọc' });
  else if (!items.length) list = usersEmpty({ ic: 'info', title: s.tab === 0 ? 'Chưa có thành viên khác' : 'Chưa có lời mời nào', sub: s.tab === 0 ? 'Mời thêm người dùng để cùng vận hành tổ chức.' : 'Tạo lời mời mới để thêm người dùng vào tổ chức.', action: 'Mời thành viên' });
  const chips = s.tab === 0 ? ['Tất cả', 'Hoạt động', 'Tạm ngừng'] : ['Tất cả', 'Đang chờ', 'Hết hạn'];
  return usersTablePage(s, items, list, chips, toastHtml);
}

/**
 * Web (≥ 840) — bảng toàn màn, chọn qua impeccable live (2026-11-24): app bar "Người dùng" + phụ đề + nút "Mời thành viên";
 * thanh công cụ (tab trái, ô tìm + bộ lọc phải); cột 1120: chip nhanh → bảng. Bấm dòng mở chi tiết toàn màn (nút ←).
 * Trạng thái rỗng / lỗi / đang tải dùng lại khối của danh sách hẹp, đặt vào chỗ bảng.
 */
function usersTable(s, items) {
  const head = (cols) => `<div class="t1-utable__tr t1-utable__th" role="row">${cols.map((c) => `<span role="columnheader">${esc(c)}</span>`).join('')}<span></span></div>`;
  const chev = icon('chevronRight', 't1-utable__chev');
  if (s.tab === 0) {
    return `<div class="t1-utable" role="table" aria-label="Thành viên">${head(['Tên', 'Vai trò hiện hành', 'Trạng thái truy cập', 'Hoạt động gần nhất'])}
      ${items.map((m) => `<button type="button" class="t1-utable__tr" role="row"><span class="t1-utable__who">${avatar(m.name)}<span><b>${esc(m.name)}</b>${m.isOwner ? badge('Chủ sở hữu', 'primary') : ''}<small>${esc(m.email)}</small></span></span><span>${esc(m.role)}</span><span>${badge(...MEMBER_BADGE[m.status])}</span><span class="t1-utable__num">${esc(m.status === 'active' ? m.lastActive : '—')}</span>${chev}</button>`).join('')}</div>`;
  }
  return `<div class="t1-utable" role="table" aria-label="Lời mời">${head(['Email', 'Vai trò ban đầu', 'Trạng thái', ''])}
    ${items.map((i) => `<button type="button" class="t1-utable__tr" role="row"><span class="t1-utable__who">${avatar(i.email.split('@')[0])}<span><b>${esc(i.email)}</b><small>${esc(i.expiry)} · ${esc(statusDetail(i).split(' · ').pop())}</small></span></span><span>${esc(i.role)}</span><span>${badge(...INVITATION_BADGE[i.status])}</span><span></span>${chev}</button>`).join('')}</div>`;
}

function usersTablePage(s, items, state, chips, toastHtml) {
  const cols = s.tab === 0 ? ['Tên', 'Vai trò hiện hành', 'Trạng thái truy cập', 'Hoạt động gần nhất'] : ['Email', 'Vai trò ban đầu', 'Trạng thái', ''];
  const content = s.loading ? tableSkeleton(cols) : state ? `<div class="t1-utable t1-utable--state">${state}</div>` : usersTable(s, items);
  const bar = `<div class="t1-utools"><div class="t1-utools__tabs">${tabs(['Thành viên', 'Lời mời'], s.tab)}</div>
    <div class="t1-utools__find">${searchBar('Tìm tên hoặc email', s.query || '')}${iconButton('tune', s.filterOn ? 'Bộ lọc (đang áp dụng)' : 'Bộ lọc', { size: 20, dot: !!s.filterOn })}</div></div>`;
  return `<div class="t1-page t1-page--canvas">${appBar('Người dùng', { back: true, subtitle: subtitle(s, items), actions: `<div class="t1-uinvite">${button('Mời thành viên')}</div>` })}
    ${bar}<div class="t1-scroll"><div class="t1-uwrap"><div class="t1-uwrap__chips">${chipRow(chips, s.chip || 'Tất cả')}</div>${content}</div></div>${toastHtml}</div>`;
}

export function usersPage(v) {
  const s = LIST_STATES[v.state];
  const t = s.toast ? toast(...s.toast, { device: v.device }) : '';
  // Thu hồi xong quay về danh sách → toast đáy màn (web).
  const page = usersListPage(s, t);
  const overlay = s.sheet ? adaptiveSheet(v.width, filterSheet(s.sheet), '', { title: s.sheet === 'members' ? 'Bộ lọc thành viên' : 'Bộ lọc lời mời' }) : '';
  return { page, overlay };
}

export function invitePage(v) {
  const s = INVITE_STATES[v.state];
  const base = { title: 'Mời thành viên', placeWidth: v.width };
  if (s.loading) return { page: vScaffold({ ...base, body: centerLoading(), fixed: true }) };
  if (s.rolesFailed) return { page: vScaffold({ ...base, body: loadFailed('Không tải được danh sách vai trò', 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.'), fixed: true }) };
  const e = s.errors || {};
  // Câu dẫn → thẻ trắng: Email → "Vai trò ban đầu" chọn bằng 4 thẻ có radio + mô tả (2 cột ≥ 600). Chọn qua impeccable live (2026-11-24).
  const roleCard = ([t, d]) => {
    const on = t === s.role;
    return `<button type="button" class="t1-rolepick__opt${on ? ' is-on' : ''}" aria-pressed="${on}"${s.busy ? ' disabled' : ''}>${radio(on)}<span><b>${esc(t)}</b><small>${esc(d)}</small></span></button>`;
  };
  const body = `<div class="t1-formpage"><p class="t1-small">Người nhận phải đăng nhập đúng email. Lời mời sẽ hết hạn sau 7 ngày.</p>
    <div class="t1-formcard"><div class="t1-form">
      ${field({ label: 'Email', required: true, control: input({ value: s.email || '', hint: 'nhanvien@example.com', invalid: !!e.email, disabled: !!s.busy }), error: e.email })}
      <fieldset class="t1-rolepick${e.role ? ' is-invalid' : ''}"><legend class="t1-label">Vai trò ban đầu<i aria-hidden="true"> *</i></legend>
        <div class="t1-rolepick__grid">${SELECT_ROLES.map(roleCard).join('')}</div>
        ${e.role ? fieldError(e.role) : fieldDesc('Vai trò có thể thay đổi sau khi tham gia.')}</fieldset>
    </div></div></div>`;
  // Nút gửi: khi đang gửi đổi chữ "Đang gửi..." + tắt (không có vòng xoay).
  const bar = `<div class="t1-bar-pad t1-row2 t1-row2--8">${button('Hủy', { variant: 'secondary', full: true, disabled: !!s.busy })}${button(s.busy ? 'Đang gửi...' : 'Gửi lời mời', { full: true, disabled: !!s.busy })}</div>`;
  return { page: vScaffold({ ...base, body, bottomBar: bar, toastHtml: s.toast ? toast(...s.toast, { device: v.device, above: BAR_H }) : '' }) };
}

function invitationDetail(s, w, device) {
  const base = { title: 'Chi tiết lời mời', placeWidth: w };
  if (s.loading) return vScaffold({ ...base, body: centerLoading(), fixed: true });
  if (s.error) return vScaffold({ ...base, body: loadFailed('Không tải được lời mời', 'Không tìm thấy tài nguyên.'), fixed: true });
  const i = invitationById(s.id);
  const [label, tone] = INVITATION_BADGE[i.status];
  // Thiết kế lại qua impeccable live (2026-11-24): đầu trang (chữ viết tắt + email + hạn) → khối "Thông tin lời mời" (nhãn trạng thái,
  // 3 dòng nhãn | giá trị) → còn chờ: "Gửi lại lời mời" + "Thu hồi lời mời" ngay cuối khối (không còn thanh "Thao tác" / sheet).
  const delivery = statusDetail(i).split(' · ').pop();
  const canMutate = i.wire === 'pending';
  const acts = canMutate ? `<div class="t1-invacts">${button('Gửi lại lời mời', { variant: 'secondary' })}${button('Thu hồi lời mời', { variant: 'secondary', cls: 't1-btn--danger-outline', loading: !!s.revokeBusy })}</div>` : '';
  const body = `<div class="t1-orgp">
    <div class="t1-orgp__head">${avatar(i.email.split('@')[0]).replace('t1-avatar"', 't1-avatar t1-avatar--lg"')}<div><h1>${esc(i.email)}</h1><p>${esc(i.expiry)}</p></div></div>
    <section class="t1-orgsec"><div class="t1-orgsec__head"><h2>Thông tin lời mời</h2>${badge(label, tone)}</div>
      <div class="t1-stack12">${kv('Vai trò ban đầu', i.role, 't1-kv--profile')}${kv('Trạng thái', label, 't1-kv--profile')}${kv('Giao nhận', delivery, 't1-kv--profile')}</div>
      ${acts}</section>
  </div>`;
  return vScaffold({ ...base, body, toastHtml: s.toast ? toast(...s.toast, { device, above: 0 }) : '' });
}

export function invitationDetailPage(v) {
  const s = INVITATION_STATES[v.state];
  const page = invitationDetail(s, v.width, v.device);
  let overlay = '';
  if (s.sheet === 'revoke') overlay = adaptiveSheet(v.width, revokeSheet(s), 'Thu hồi lời mời?');
  return { page, overlay };
}

function memberDetail(s, w, device) {
  const base = { title: 'Chi tiết thành viên', placeWidth: w };
  if (s.loading) return vScaffold({ ...base, body: centerLoading(), fixed: true });
  if (s.error) return vScaffold({ ...base, body: loadFailed('Không tải được thành viên', 'Không tìm thấy tài nguyên.'), fixed: true });
  const m = memberById(s.id);
  const [label, tone] = MEMBER_BADGE[m.status];
  // Thiết kế lại qua impeccable live (2026-11-24): đầu trang (chữ viết tắt + tên + email · vai trò) → khối "Thông tin thành viên" (+ nhãn)
  // → ghi chú (tạm ngừng / đã loại) → khối "Trạng thái truy cập" + nút thao tác ngay cuối khối (không còn thanh "Thao tác" / sheet).
  const row = (l, val) => kv(l, val, 't1-kv--profile');
  const access = m.status === 'active' ? row('Ngày tham gia', m.joined) + row('Hoạt động gần nhất', m.lastActive)
    : m.status === 'suspended' ? row('Tạm ngừng lúc', m.suspendedAt) : row('Đã loại lúc', m.removedAt) + row('Vai trò trước đó', m.role);
  const note = m.status === 'suspended' ? banner('warning', 'Quyền truy cập đã tạm ngừng', 'Thành viên không thể truy cập tổ chức cho đến khi được kích hoạt lại.')
    : m.status === 'removed' ? banner('info', 'Thành viên đã được loại', 'Quyền truy cập đã kết thúc. Lịch sử và dữ liệu nghiệp vụ vẫn được giữ lại.') : '';
  const hasActions = !m.soleOwner && m.status !== 'removed';
  const acts = hasActions ? `<div class="t1-invacts">${button('Thay đổi vai trò', { variant: 'secondary' })}${m.status === 'active' ? button('Tạm ngừng thành viên', { variant: 'secondary' }) : button('Kích hoạt lại', { variant: 'secondary' })}${button('Loại khỏi tổ chức', { variant: 'secondary', cls: 't1-btn--danger-outline' })}</div>` : '';
  const sec = (title, action, inner) => `<section class="t1-orgsec"><div class="t1-orgsec__head"><h2>${esc(title)}</h2>${action}</div>${inner}</section>`;
  const body = `<div class="t1-orgp">
    <div class="t1-orgp__head${m.status === 'removed' ? ' t1-o60' : ''}">${avatar(m.name).replace('t1-avatar"', 't1-avatar t1-avatar--lg"')}<div><h1>${esc(m.name)}</h1><p>${esc(`${m.email} · ${m.role}`)}</p></div></div>
    <div${m.status === 'removed' ? ' class="t1-o60"' : ''}>${sec('Thông tin thành viên', badge(label, tone), `<div class="t1-stack12">${row('Tên', m.name)}${row('Email', m.email)}${row('Vai trò hiện hành', m.role)}${row('Quyền sở hữu', m.isOwner ? 'Chủ sở hữu' : 'Thành viên')}</div>`)}</div>
    ${note}
    ${sec('Trạng thái truy cập', '', `<div class="t1-stack12">${access}</div>${acts}`)}
  </div>`;
  return vScaffold({ ...base, body, toastHtml: s.toast ? toast(...s.toast, { device, above: 0 }) : '' });
}

export function memberDetailPage(v) {
  const s = MEMBER_STATES[v.state];
  const page = memberDetail(s, v.width, v.device);
  let overlay = '';
  if (LIFECYCLE[s.sheet]) overlay = adaptiveSheet(v.width, lifecycleSheet(s.sheet, !!s.busy), LIFECYCLE[s.sheet].title);
  return { page, overlay };
}

function selectRole(s, w) {
  const m = memberById(s.id);
  const i = SELECT_ROLES.findIndex(([t]) => t === m.role);
  const roles = i > 0 ? [SELECT_ROLES[i], ...SELECT_ROLES.filter((_, k) => k !== i)] : SELECT_ROLES;
  const active = m.status === 'active';
  const item = ([t, d]) => {
    const cur = t === m.role; const on = t === s.pick;
    return `<div class="t1-roleopt${on ? ' is-on' : ''}">${icon('user', 't1-roleopt__ic')}<div class="t1-roleopt__text"><b>${esc(t)}</b><span>${esc(d)}</span></div>${cur ? badge('Hiện tại', 'success') : radio(on)}</div>`;
  };
  const body = `<div class="t1-list">
    ${vcard(`<div class="t1-dhead"><h2 class="t1-h4">${esc(m.name)}</h2>${badge(active ? 'Hoạt động' : 'Tạm ngừng', active ? 'success' : 'danger')}</div><div class="t1-gap-xs"></div>
      <p class="t1-small">${esc(`${m.email} · ${m.role}`)}</p><div class="t1-gap-md"></div><p class="t1-strong">${m.isOwner ? 'Quyền sở hữu: Chủ sở hữu' : 'Quyền sở hữu: Thành viên'}</p>`)}
    <div class="t1-gap-md"></div><h2 class="t1-h4">Chọn vai trò mới</h2><div class="t1-gap-xs"></div><p class="t1-small">Mỗi thành viên có đúng một vai trò hiện hành.</p><div class="t1-gap-md"></div>
    ${roles.map(item).join('')}</div>`;
  const bar = `<div class="t1-bar-pad t1-row2 t1-row2--8">${button('Hủy', { variant: 'secondary', full: true })}${button('Tiếp tục', { full: true, disabled: !s.pick })}</div>`;
  return vScaffold({ title: 'Chọn vai trò', body, bottomBar: bar, placeWidth: w });
}

export function selectRolePage(v) {
  const s = SELECT_STATES[v.state];
  const m = memberById(s.id);
  const overlay = s.sheet === 'confirm' ? adaptiveSheet(v.width, changeRoleSheet(m, s.pick), changeRoleTitle(m)) : '';
  return { page: selectRole(s, v.width), overlay };
}
