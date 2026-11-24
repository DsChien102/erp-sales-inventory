// ID-14 Người dùng · ID-15 Mời thành viên · ID-16 Chi tiết lời mời · ID-17 Chi tiết thành viên · ID-18 Chọn vai trò. Chép từ:
//   apps/erp/lib/features/iam/presentation/users/{users_area_shell.dart, views/*.dart, widgets/*.dart}, core/router/app_router.dart
// /more/users(/…): ShellRoute riêng (UsersAreaShell → VListDetailLayout) nằm NGOÀI StoreShell → không thanh bên / thanh dưới.
//   Web ≥ 840 (thiết kế lại qua impeccable live 2026-11-24): danh sách là bảng toàn màn, chi tiết mở toàn màn có nút ←. Hẹp: một màn.
// /more/users/invite: GoRoute gốc → toàn màn cả web. Chọn vai trò: Navigator.push từ chi tiết → web mở trong cột phải.
// /more/users/preview-role-change và /select-role đều redirect về hub → màn "Xem trước thay đổi" (ID-18) không mở được.
import { icon } from '../shared/icons.js';
import { INVITATION_BADGE, INVITATIONS, MEMBER_BADGE, MEMBERS, invitationById, memberById, statusDetail } from './admin-data.js';
import {
  actionTile, adaptiveSheet, appBar, badge, skeleton, banner, button, centerLoading, chipRow, esc, field, fieldDesc, fieldError, filterChip, iconButton, input, isSplit, kv,
  radio, searchBar, select, tabs, textArea, toast, vcard, vScaffold,
} from './ds.js';
import { BAR_H, loadFailed } from './org.js';

// ---------------------------------------------------------------- ID-14 danh sách
/** Chữ viết tắt: ký tự đầu của tên (từ cuối họ tên). */
const initial = (name) => esc(String(name).trim().split(/\s+/).pop()[0] || '');
const avatar = (name) => `<span class="t1-avatar" aria-hidden="true">${initial(name)}</span>`;

const memberCard = (m, selected) => {
  const [label, tone] = MEMBER_BADGE[m.status];
  return vcard(`<div class="t1-urow">${avatar(m.name)}<div class="t1-urow__text"><div class="t1-urow__name"><b>${esc(m.name)}</b>${m.isOwner ? badge('Chủ sở hữu', 'primary') : ''}</div><span>${esc(`${m.email} · ${m.role}`)}</span></div>${badge(label, tone)}</div>`, { selected });
};
const invitationCard = (i, selected) => {
  const [label, tone] = INVITATION_BADGE[i.status];
  return vcard(`<div class="t1-urow">${avatar(i.email.split('@')[0])}<div class="t1-urow__text"><b>${esc(i.email)}</b><span>${esc(statusDetail(i))}</span></div>${badge(label, tone)}</div>`, { selected });
};

/** Đang tải (VSkeletonScope): hẹp — 3 thẻ giả (tròn 36 + 2 dòng + nhãn); web — 4 dòng bảng giả dưới hàng tiêu đề thật. */
const listSkeleton = () => `<div class="t1-ulist" aria-busy="true" aria-label="Đang tải">${[0, 1, 2].map(() => vcard(`<div class="t1-urow">${skeleton({ w: 36, h: 36, circle: true })}<div class="t1-urow__text t1-skelcol">${skeleton({ w: '55%', h: 16 })}${skeleton({ w: '80%', h: 12 })}</div>${skeleton({ w: 64, h: 22 })}</div>`)).join('')}</div>`;
const tableSkeleton = (cols) => `<div class="t1-utable" role="table" aria-busy="true" aria-label="Đang tải"><div class="t1-utable__tr t1-utable__th" role="row">${cols.map((c) => `<span role="columnheader">${esc(c)}</span>`).join('')}<span></span></div>
  ${[0, 1, 2, 3].map(() => `<div class="t1-utable__tr t1-utable__tr--skel"><span class="t1-utable__who">${skeleton({ w: 36, h: 36, circle: true })}<span class="t1-skelcol">${skeleton({ w: 160, h: 16 })}${skeleton({ w: 120, h: 12 })}</span></span><span>${skeleton({ w: 120 })}</span><span>${skeleton({ w: 72, h: 22 })}</span><span>${cols[3] ? skeleton({ w: 110 }) : ''}</span><span></span></div>`).join('')}</div>`;

/** UsersEmptyState trong UsersEmptyScroll (khung cao 480 canh giữa): VIconBox 56 bo 12 (icon 28) → 16 → H4 w700 → 8 → bodySmall → 24 → VButton. */
const usersEmpty = ({ ic, tone = '', title, sub, action, danger = false }) => `<div class="t1-uempty"><div class="t1-uempty__in">
  <span class="t1-ibox56${tone ? ` t1-ibox56--${tone}` : ''}">${icon(ic)}</span><div class="t1-gap-md"></div>
  <h2 class="t1-h4 t1-text-center${tone === 'danger' ? ' t1-danger' : ''}">${esc(title)}</h2><div class="t1-gap-sm"></div>
  <p class="t1-small t1-text-center">${esc(sub)}</p>${action ? `<div class="t1-gap-lg"></div>${button(action, { cls: danger ? 't1-btn--danger' : '' })}` : ''}</div></div>`;

export const LIST_STATES = {
  members: { tab: 0 }, invitations: { tab: 1 }, loading: { tab: 0, loading: true }, 'invitations-loading': { tab: 1, loading: true },
  'invitations-empty': { tab: 1, empty: true }, 'no-results': { tab: 0, query: 'hoàng', empty: true }, 'chip-suspended': { tab: 0, chip: 'Tạm ngừng' },
  forbidden: { tab: 0, failure: 'forbidden' }, error: { tab: 0, failure: 'error' },
  'filter-members': { tab: 0, sheet: 'members' }, 'filter-invitations': { tab: 1, sheet: 'invitations' }, 'filter-applied': { tab: 0, filterOn: true, roleFilter: 'Kế toán' },
  'toast-revoked': { tab: 1, revoked: true, toast: ['success', 'Đã thu hồi lời mời.', ''] },
};

function subtitle(s, items) {
  if (s.failure) return s.failure === 'forbidden' ? 'Chưa cấp quyền' : 'Không tải được';
  if (s.loading) return s.tab === 0 ? 'Đang tải thành viên' : 'Đang tải lời mời';
  if ((s.query || s.chip) && !items.length) return '0 kết quả';
  return s.tab === 0 ? `${items.length} thành viên` : `${items.length} lời mời`;
}

/** OrganizationUsersPage (VPageScaffold "Người dùng" + phụ đề + nút + 48) — placeWidth: 360 (cột trái web) hoặc bề ngang màn. */
export function usersListPage(s, placeWidth, { selectedId = null, toastHtml = '' } = {}) {
  let items = s.tab === 0 ? MEMBERS : INVITATIONS.filter((i) => !(s.revoked && i.id === 'i1'));
  if (s.chip === 'Tạm ngừng') items = items.filter((m) => m.status === 'suspended');
  if (s.roleFilter) items = items.filter((m) => m.role === s.roleFilter);
  if (s.empty) items = [];
  let list;
  if (s.loading) list = isSplit(placeWidth) ? 'SKELETON' : listSkeleton();
  else if (s.failure === 'forbidden') list = usersEmpty({ ic: 'shield', tone: 'warning', title: 'Bạn không có quyền quản lý', sub: 'Liên hệ Chủ tổ chức hoặc Quản trị viên để được cấp quyền phù hợp.', action: 'Quay lại' });
  else if (s.failure) list = usersEmpty({ ic: 'close', tone: 'danger', title: 'Không thể tải danh sách', sub: 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.', action: 'Thử lại', danger: true });
  else if (!items.length && (s.query || s.chip)) list = usersEmpty({ ic: 'search', title: 'Không tìm thấy kết quả', sub: 'Thử từ khóa khác hoặc xóa bộ lọc đang áp dụng.', action: 'Xóa bộ lọc' });
  else if (!items.length) list = usersEmpty({ ic: 'info', title: s.tab === 0 ? 'Chưa có thành viên khác' : 'Chưa có lời mời', sub: s.tab === 0 ? 'Mời thêm người dùng để cùng vận hành tổ chức.' : 'Mời thành viên mới để họ nhận email tham gia.', action: 'Mời thành viên' });
  else list = `<div class="t1-ulist">${items.map((x) => (s.tab === 0 ? memberCard(x, x.id === selectedId) : invitationCard(x, x.id === selectedId))).join('')}</div>`;
  const chips = s.tab === 0 ? ['Tất cả', 'Hoạt động', 'Tạm ngừng'] : ['Tất cả', 'Đang chờ', 'Hết hạn'];
  if (isSplit(placeWidth)) return usersTablePage(s, items, list, chips, toastHtml);
  const body = `<div class="t1-ubar">${searchBar('Tìm tên hoặc email', s.query || '')}${iconButton('tune', s.filterOn ? 'Bộ lọc (đang áp dụng)' : 'Bộ lọc', { size: 20, dot: !!s.filterOn })}</div>
    ${tabs(['Thành viên', 'Lời mời'], s.tab)}<hr class="t1-divider">
    <div class="t1-chippad">${chipRow(chips, s.chip || 'Tất cả')}</div>
    <div class="t1-ulistwrap">${list}</div>`;
  return vScaffold({ title: 'Người dùng', subtitle: subtitle(s, items), actions: iconButton('plus', 'Mời thành viên'), body, placeWidth, fixed: true, toastHtml });
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

function usersTablePage(s, items, list, chips, toastHtml) {
  const cols = s.tab === 0 ? ['Tên', 'Vai trò hiện hành', 'Trạng thái truy cập', 'Hoạt động gần nhất'] : ['Email', 'Vai trò ban đầu', 'Trạng thái', ''];
  const content = list === 'SKELETON' ? tableSkeleton(cols)
    : list.startsWith('<div class="t1-ulist">') ? usersTable(s, items) : `<div class="t1-utable t1-utable--state">${list}</div>`;
  const bar = `<div class="t1-utools"><div class="t1-utools__tabs">${tabs(['Thành viên', 'Lời mời'], s.tab)}</div>
    <div class="t1-utools__find">${searchBar('Tìm tên hoặc email', s.query || '')}${iconButton('tune', s.filterOn ? 'Bộ lọc (đang áp dụng)' : 'Bộ lọc', { size: 20, dot: !!s.filterOn })}</div></div>`;
  return `<div class="t1-page t1-page--canvas">${appBar('Người dùng', { back: true, subtitle: subtitle(s, items), actions: `<div class="t1-uinvite">${button('Mời thành viên')}</div>` })}
    ${bar}<div class="t1-scroll"><div class="t1-uwrap"><div class="t1-uwrap__chips">${chipRow(chips, s.chip || 'Tất cả')}</div>${content}</div></div>${toastHtml}</div>`;
}

/** MemberFilterBottomSheet / InvitationFilterBottomSheet: đệm 16 / 16 / 16 / 24; tiêu đề nhóm bodyDefault w700, khe 4, Wrap chip khe 8; nhóm cách 16; khe 24; Đặt lại | khe 16 | Áp dụng. */
function filterSheet(kind) {
  const groups = kind === 'members'
    ? [['Trạng thái', ['Tất cả', 'Hoạt động', 'Tạm ngừng']], ['Vai trò', ['Tất cả', 'Chủ cửa hàng', 'Nhân viên bán hàng', 'Kế toán', 'Thủ kho']], ['Sắp xếp', ['Tất cả', 'Tên A–Z', 'Tên Z–A']]]
    : [['Trạng thái', ['Tất cả', 'Đang chờ', 'Hết hạn']], ['Kết quả gửi', ['Tất cả', 'Đã gửi', 'Gửi lỗi', 'Thu hồi']], ['Thời gian', ['Tất cả', '7 ngày', '30 ngày', 'Tùy chọn']]];
  return `<div class="t1-fsheet">${groups.map(([t, opts]) => `<div class="t1-fgroup"><b>${esc(t)}</b><div class="t1-fwrap">${opts.map((o, i) => filterChip(o, i === 0)).join('')}</div></div>`).join('')}
    <div class="t1-row2 t1-fsheet__acts">${button('Đặt lại', { variant: 'secondary', full: true })}${button('Áp dụng', { full: true })}</div></div>`;
}

/**
 * Khu Người dùng. Web: danh sách là bảng toàn màn, chi tiết mở toàn màn (nút ←) — không còn chia 2 cột. Hẹp: một màn như cũ.
 * listToast: toast của danh sách (cả hai khổ).
 */
export function usersArea(v, ls, { detail = null, listToast = '' } = {}) {
  return detail ? detail(v.width) : usersListPage(ls, v.width, { toastHtml: listToast });
}

export function usersPage(v) {
  const s = LIST_STATES[v.state];
  const t = s.toast ? toast(...s.toast, { device: v.device }) : '';
  // Thu hồi xong quay về danh sách → toast đáy màn (cả web lẫn hẹp).
  const page = usersArea(v, s, { listToast: t });
  const overlay = s.sheet ? adaptiveSheet(v.width, filterSheet(s.sheet), '', { title: s.sheet === 'members' ? 'Bộ lọc thành viên' : 'Bộ lọc lời mời' }) : '';
  return { page, overlay };
}

// ---------------------------------------------------------------- ID-15 mời thành viên
export const INVITE_STATES = {
  empty: {}, filled: { email: 'tuan@anphat.vn', role: 'Nhân viên bán hàng' }, 'empty-submit': { errors: { email: 'Vui lòng nhập email và chọn vai trò.' } },
  'no-role': { email: 'tuan@anphat.vn', errors: { role: 'Vui lòng nhập email và chọn vai trò.' } }, 'bad-email': { email: 'tuan@anphat', role: 'Nhân viên bán hàng', errors: { email: 'Email không hợp lệ' } },
  submitting: { email: 'tuan@anphat.vn', role: 'Nhân viên bán hàng', busy: true },
  'toast-failed': { email: 'tuan@anphat.vn', role: 'Nhân viên bán hàng', toast: ['danger', 'Không gửi được lời mời', 'Đã có lời mời đang chờ xử lý.'] },
  loading: { loading: true }, 'roles-failed': { rolesFailed: true },
};

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
      ${field({ label: 'Email', required: true, control: input({ value: s.email || '', hint: 'nhanvien@minhphat.vn', invalid: !!e.email, disabled: !!s.busy }), error: e.email })}
      <fieldset class="t1-rolepick${e.role ? ' is-invalid' : ''}"><legend class="t1-label">Vai trò ban đầu<i aria-hidden="true"> *</i></legend>
        <div class="t1-rolepick__grid">${SELECT_ROLES.map(roleCard).join('')}</div>
        ${e.role ? fieldError(e.role) : fieldDesc('Vai trò có thể thay đổi sau khi tham gia.')}</fieldset>
    </div></div></div>`;
  // Nút gửi: khi đang gửi đổi chữ "Đang gửi..." + tắt (không có vòng xoay).
  const bar = `<div class="t1-bar-pad t1-row2 t1-row2--8">${button('Hủy', { variant: 'secondary', full: true, disabled: !!s.busy })}${button(s.busy ? 'Đang gửi...' : 'Gửi lời mời', { full: true, disabled: !!s.busy })}</div>`;
  return { page: vScaffold({ ...base, body, bottomBar: bar, toastHtml: s.toast ? toast(...s.toast, { device: v.device, above: BAR_H }) : '' }) };
}

// ---------------------------------------------------------------- ID-16 chi tiết lời mời
export const INVITATION_STATES = {
  pending: { id: 'i1' }, 'delivery-failed': { id: 'i3' }, expired: { id: 'i4' }, loading: { id: 'i1', loading: true }, error: { id: 'i1', error: true },
  revoke: { id: 'i1', sheet: 'revoke' }, 'revoke-empty': { id: 'i1', sheet: 'revoke', revokeError: 'Vui lòng nhập lý do thu hồi.' },
  'revoke-submitting': { id: 'i1', sheet: 'revoke', revokeBusy: true, reason: 'Sai email người nhận' },
  'toast-created': { id: 'i1', toast: ['success', 'Đã gửi lời mời thành công.', ''] },
  'toast-created-warning': { id: 'i3', toast: ['warning', 'Đã tạo lời mời', 'Email chưa gửi được. Bạn có thể gửi lại từ chi tiết lời mời.'] },
  'toast-resent': { id: 'i1', toast: ['success', 'Thành công', 'Đã gửi lại lời mời.'] },
  'toast-resend-failed': { id: 'i3', toast: ['warning', 'Cảnh báo gửi email', 'Lời mời vẫn còn hiệu lực nhưng gửi email thất bại.'] },
  'toast-state-changed': { id: 'i1', toast: ['warning', 'Dữ liệu đã thay đổi', 'Dữ liệu đã thay đổi. Vui lòng tải lại rồi xác nhận lại.'] },
};


function invitationDetail(s, w, split, device) {
  const back = !split;
  const base = { title: 'Chi tiết lời mời', back, placeWidth: w };
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

/** _RevokeInvitationSheetBody: đệm 16; H3 w700 danger; khe 4; bodyDefault; (không khe) VField "Lý do thu hồi" + ô 3 dòng; khe 24; Quay lại / khe 8 / Thu hồi (secondary danger) / khe 8. */
const revokeSheet = (s) => `<div class="t1-list"><h2 class="t1-h3 t1-danger">Thu hồi lời mời?</h2><div class="t1-gap-xs"></div>
  <p class="t1-body2">Người nhận sẽ không thể dùng liên kết hiện tại để tham gia tổ chức.</p>
  ${field({ label: 'Lý do thu hồi', control: textArea({ value: s.reason || '', hint: 'Ví dụ: Sai email người nhận', invalid: !!s.revokeError, disabled: !!s.revokeBusy }), error: s.revokeError })}
  <div class="t1-gap-lg"></div>${button('Quay lại', { variant: 'secondary', full: true, disabled: !!s.revokeBusy })}<div class="t1-gap-sm"></div>
  ${button('Thu hồi lời mời', { variant: 'secondary', full: true, loading: !!s.revokeBusy, cls: 't1-btn--danger-outline' })}<div class="t1-gap-sm"></div></div>`;

export function invitationDetailPage(v) {
  const s = INVITATION_STATES[v.state];
  const page = usersArea(v, { tab: 1 }, { detail: (w) => invitationDetail(s, w, false, v.device) });
  let overlay = '';
  if (s.sheet === 'revoke') overlay = adaptiveSheet(v.width, revokeSheet(s), 'Thu hồi lời mời?');
  return { page, overlay };
}

// ---------------------------------------------------------------- ID-17 chi tiết thành viên
export const MEMBER_STATES = {
  active: { id: 'm2' }, suspended: { id: 'm3' }, removed: { id: 'm4' }, owner: { id: 'm1' }, loading: { id: 'm2', loading: true }, error: { id: 'm2', error: true },
  deactivate: { id: 'm2', sheet: 'deactivate' }, reactivate: { id: 'm3', sheet: 'reactivate' }, remove: { id: 'm2', sheet: 'remove' },
  'remove-submitting': { id: 'm2', sheet: 'remove', busy: true },
  'toast-deactivated': { id: 'm3', toast: ['success', 'Đã tạm ngừng thành viên.', ''] },
  'toast-role-changed': { id: 'm2', toast: ['success', 'Đã thay đổi vai trò thành công.', ''] },
  'toast-last-owner': { id: 'm2', toast: ['warning', 'Không thể thực hiện', 'Không thể thực hiện vì đây là chủ sở hữu cuối cùng.'] },
};

/** _DetailRow: nhãn bodySmall textSecondary ↔ giá trị bodySmall w700 phải. */
const drow = (l, val) => kv(l, val, 't1-kv--small');

function memberDetail(s, w, split, device) {
  const base = { title: 'Chi tiết thành viên', back: !split, placeWidth: w };
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
    <div${m.status === 'removed' ? ' class="t1-o60"' : ''}>${sec('Thông tin thành viên', badge(label, tone), `<div class="t1-stack12">${row('Tên', m.name)}${row('Email', m.email)}${row('Vai trò hiện hành', m.role)}${row(m.isOwner ? 'Quyền sở hữu' : 'Danh tính', m.isOwner ? 'Chủ sở hữu' : 'Chỉ đọc')}</div>`)}</div>
    ${note}
    ${sec('Trạng thái truy cập', '', `<div class="t1-stack12">${access}</div>${acts}`)}
  </div>`;
  return vScaffold({ ...base, body, toastHtml: s.toast ? toast(...s.toast, { device, above: 0 }) : '' });
}

/** MembershipLifecycleConfirmSheet: đệm 16 / 8 / 16 / 24; H3 w700 (danger tuỳ); khe 4; bodyDefault; khe 32; Quay lại / khe 8 / nút xác nhận. */
const LIFECYCLE = {
  deactivate: { title: 'Tạm ngừng thành viên?', danger: true, desc: 'Thành viên mất quyền truy cập tới khi được kích hoạt lại.', ok: 'Tạm ngừng' },
  reactivate: { title: 'Kích hoạt lại thành viên?', danger: false, desc: 'Quyền truy cập sẽ được khôi phục theo vai trò hiện hành.', ok: 'Kích hoạt lại' },
  remove: { title: 'Loại thành viên khỏi tổ chức?', danger: true, desc: 'Thành viên sẽ kết thúc vĩnh viễn. Người này cần lời mời mới nếu quay lại.', ok: 'Loại thành viên' },
};
const lifecycleSheet = (k, busy) => {
  const c = LIFECYCLE[k];
  return `<div class="t1-sheetpad"><h2 class="t1-h3${c.danger ? ' t1-danger' : ''}">${esc(c.title)}</h2><div class="t1-gap-xs"></div><p class="t1-body2">${esc(c.desc)}</p><div class="t1-gap-xl"></div>
    ${button('Quay lại', { variant: 'secondary', full: true, disabled: busy })}<div class="t1-gap-sm"></div>
    ${button(c.ok, { variant: c.danger ? 'secondary' : 'primary', full: true, loading: busy, cls: c.danger ? 't1-btn--danger-outline' : '' })}</div>`;
};

export function memberDetailPage(v) {
  const s = MEMBER_STATES[v.state];
  const page = usersArea(v, { tab: 0 }, { detail: (w) => memberDetail(s, w, false, v.device) });
  let overlay = '';
  if (s.sheet) overlay = adaptiveSheet(v.width, lifecycleSheet(s.sheet, !!s.busy), LIFECYCLE[s.sheet].title);
  return { page, overlay };
}

// ---------------------------------------------------------------- ID-18 chọn vai trò
/** _availableRoles (mô tả riêng của màn này, ngắn hơn TH-01 3.4); vai trò hiện tại đưa lên đầu. */
const SELECT_ROLES = [['Nhân viên bán hàng', 'Bán hàng và chăm sóc khách hàng'], ['Kế toán', 'Công nợ, hóa đơn và báo cáo'], ['Thủ kho', 'Nhập xuất, tồn kho và kiểm kê'], ['Chủ cửa hàng', 'Quản lý toàn bộ cửa hàng']];
export const SELECT_STATES = { default: { id: 'm2' }, selected: { id: 'm2', pick: 'Thủ kho' }, suspended: { id: 'm3' } };

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
      <p class="t1-small">${esc(`${m.email} · ${m.role}`)}</p><div class="t1-gap-md"></div><p class="t1-strong">${m.isOwner ? 'Quyền sở hữu: Chủ sở hữu' : 'Danh tính: Chỉ đọc'}</p>`)}
    <div class="t1-gap-md"></div><h2 class="t1-h4">Chọn vai trò mới</h2><div class="t1-gap-xs"></div><p class="t1-small">Mỗi thành viên có đúng một vai trò hiện hành.</p><div class="t1-gap-md"></div>
    ${roles.map(item).join('')}</div>`;
  const bar = `<div class="t1-bar-pad t1-row2 t1-row2--8">${button('Hủy', { variant: 'secondary', full: true })}${button('Tiếp tục', { full: true, disabled: !s.pick })}</div>`;
  return vScaffold({ title: 'Chọn vai trò', body, bottomBar: bar, placeWidth: w });
}

export function selectRolePage(v) {
  const s = SELECT_STATES[v.state];
  return { page: usersArea(v, { tab: 0 }, { detail: (w) => selectRole(s, w) }) };
}
