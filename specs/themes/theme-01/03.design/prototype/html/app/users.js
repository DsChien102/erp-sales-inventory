// ID-14 Người dùng · ID-15 Mời thành viên · ID-16 Chi tiết lời mời · ID-17 Chi tiết thành viên · ID-18 Chọn vai trò. Chép từ:
//   apps/erp/lib/features/iam/presentation/users/{users_area_shell.dart, views/*.dart, widgets/*.dart}, core/router/app_router.dart
// /more/users(/…): ShellRoute riêng (UsersAreaShell → VListDetailLayout) nằm NGOÀI StoreShell → không thanh bên / thanh dưới.
//   web ≥ 840: danh sách 360 (bọc ScaffoldMessenger riêng) | gạch | chi tiết (cột VPageScaffold 640). Hẹp: một màn.
// /more/users/invite: GoRoute gốc → toàn màn cả web. Chọn vai trò: Navigator.push từ chi tiết → web mở trong cột phải.
// /more/users/preview-role-change và /select-role đều redirect về hub → màn "Xem trước thay đổi" (ID-18) không mở được.
import { icon } from '../shared/icons.js';
import { INVITATION_BADGE, INVITATIONS, MEMBER_BADGE, MEMBERS, invitationById, memberById, statusDetail } from './admin-data.js';
import {
  actionTile, adaptiveSheet, badge, banner, button, card, centerLoading, chipRow, detailWidth, esc, field, fieldError, filterChip, iconButton, input, isSplit, kv,
  LIST_WIDTH, listDetail, radio, searchBar, splitPlaceholder, textArea, toast, vScaffold,
} from './ds.js';
import { BAR_H, loadFailed } from './org.js';

// ---------------------------------------------------------------- ID-14 danh sách
// Bố cục iPhone thiết kế lại qua impeccable live (2026-11-25); chữ giữ nguyên Flutter: tab hai nút liền → ô tìm + bộ lọc (nền trắng) → chip → thẻ; "Mời thành viên" ở thanh dưới (thay nút +).
const userLine = (ic, text) => `<span class="t1-ucard__line">${icon(ic)}${esc(text)}</span>`;
const userCard = (name, badges, lines, selected) => `<button type="button" class="t1-ucard"${selected ? ' aria-current="true"' : ''}><span class="t1-ucard__name"><b>${esc(name)}</b>${badges}</span>${lines.join('')}</button>`;
const memberCard = (m, selected) => userCard(m.name, `${m.isOwner ? badge('Chủ sở hữu', 'primary') : ''}<i></i>${badge(...MEMBER_BADGE[m.status])}`, [userLine('mail', m.email), userLine('shield', m.role)], selected);
/** Dòng phụ lời mời: vai trò; hạn · kết quả gửi (cùng chữ statusDetail). */
const invitationCard = (i, selected) => userCard(i.email, `<i></i>${badge(...INVITATION_BADGE[i.status])}`, [userLine('shield', i.role), userLine('clock', statusDetail(i).slice(i.role.length + 3))], selected);

/** UsersEmptyState trong UsersEmptyScroll (khung cao 480 canh giữa): VIconBox 56 bo 12 (icon 28) → 16 → H4 w700 → 8 → bodySmall → 24 → VButton. */
export const usersEmpty = ({ ic, tone = '', title, sub, action, danger = false, variant = 'primary' }) => `<div class="t1-uempty"><div class="t1-uempty__in">
  <span class="t1-ibox56${tone ? ` t1-ibox56--${tone}` : ''}">${icon(ic)}</span><div class="t1-gap-md"></div>
  <h2 class="t1-h4 t1-text-center${tone === 'danger' ? ' t1-danger' : ''}">${esc(title)}</h2><div class="t1-gap-sm"></div>
  <p class="t1-small t1-text-center">${esc(sub)}</p>${action ? `<div class="t1-gap-lg"></div>${button(action, { variant, cls: danger ? 't1-btn--danger' : '' })}` : ''}</div></div>`;

export const LIST_STATES = {
  members: { tab: 0 }, invitations: { tab: 1 }, loading: { tab: 0, loading: true }, 'invitations-loading': { tab: 1, loading: true },
  'invitations-empty': { tab: 1, empty: true }, 'no-results': { tab: 0, query: 'hoàng', empty: true }, 'chip-suspended': { tab: 0, chip: 'Tạm ngừng' },
  forbidden: { tab: 0, failure: 'forbidden' }, error: { tab: 0, failure: 'error' },
  'filter-members': { tab: 0, sheet: 'members' }, 'filter-invitations': { tab: 1, sheet: 'invitations' }, 'filter-applied': { tab: 0, filterOn: true, roleFilter: 'Kế toán' },
  'toast-revoked': { tab: 1, revoked: true, toast: ['success', 'Đã thu hồi lời mời.', ''] },
};

export function subtitle(s, items) {
  if (s.failure) return s.failure === 'forbidden' ? 'Chưa cấp quyền' : 'Không tải được';
  if (s.loading) return s.tab === 0 ? 'Đang tải thành viên' : 'Đang tải lời mời';
  if ((s.query || s.chip) && !items.length) return '0 kết quả';
  return s.tab === 0 ? `${items.length} thành viên` : `${items.length} lời mời`;
}

/** OrganizationUsersPage (VPageScaffold "Người dùng" + phụ đề) — placeWidth: 360 (cột trái web) hoặc bề ngang màn. */
export function usersListPage(s, placeWidth, { selectedId = null, toastHtml = '' } = {}) {
  let items = s.tab === 0 ? MEMBERS : INVITATIONS.filter((i) => !(s.revoked && i.id === 'i1'));
  if (s.chip === 'Tạm ngừng') items = items.filter((m) => m.status === 'suspended');
  if (s.roleFilter) items = items.filter((m) => m.role === s.roleFilter);
  if (s.empty) items = [];
  let list;
  if (s.loading) list = centerLoading();
  else if (s.failure === 'forbidden') list = usersEmpty({ ic: 'shield', tone: 'warning', title: 'Bạn không có quyền quản lý', sub: 'Liên hệ Chủ tổ chức hoặc Quản trị viên để được cấp quyền phù hợp.', action: 'Quay lại' });
  else if (s.failure) list = usersEmpty({ ic: 'close', tone: 'danger', title: 'Không thể tải danh sách', sub: 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.', action: 'Thử lại', danger: true });
  else if (!items.length && (s.query || s.chip)) list = usersEmpty({ ic: 'search', title: 'Không tìm thấy kết quả', sub: 'Thử từ khóa khác hoặc xóa bộ lọc đang áp dụng.', action: 'Xóa bộ lọc', variant: 'secondary' });
  else if (!items.length) list = usersEmpty({ ic: 'info', title: s.tab === 0 ? 'Chưa có thành viên khác' : 'Chưa có lời mời', sub: s.tab === 0 ? 'Mời thêm người dùng để cùng vận hành tổ chức.' : 'Mời thành viên mới để họ nhận email tham gia.', action: 'Mời thành viên' });
  else list = `<div class="t1-ulist">${items.map((x) => (s.tab === 0 ? memberCard(x, x.id === selectedId) : invitationCard(x, x.id === selectedId))).join('')}</div>`;
  const chips = s.tab === 0 ? ['Tất cả', 'Hoạt động', 'Tạm ngừng'] : ['Tất cả', 'Đang chờ', 'Hết hạn'];
  const body = `<div class="t1-utop"><div class="t1-useg" role="tablist">${['Thành viên', 'Lời mời'].map((l, i) => `<button type="button" role="tab" aria-selected="${i === s.tab}">${l}</button>`).join('')}</div>
      <div class="t1-utop__find">${searchBar('Tìm tên hoặc email', s.query || '')}${iconButton('tune', s.filterOn ? 'Bộ lọc (đang áp dụng)' : 'Bộ lọc', { size: 20, dot: !!s.filterOn })}</div></div>
    <div class="t1-chippad">${chipRow(chips, s.chip || 'Tất cả')}</div>
    <div class="t1-ulistwrap">${list}</div>`;
  // Một nút chính mỗi màn: ẩn thanh dưới khi khối rỗng / lỗi / không có quyền đã có nút riêng (không ra kết quả vẫn hiện, "Xóa bộ lọc" là secondary).
  const hasBar = !s.failure && (s.loading || items.length || s.query || s.chip);
  const bar = hasBar ? `<div class="t1-bar-pad">${button('Mời thành viên', { full: true, attrs: 'data-primary' })}</div>` : '';
  return vScaffold({ title: 'Người dùng', subtitle: subtitle(s, items), body, bottomBar: bar, placeWidth, fixed: true, toastHtml });
}

/** MemberFilterBottomSheet / InvitationFilterBottomSheet: đệm 16 / 16 / 16 / 24; tiêu đề nhóm bodyDefault w700, khe 4, Wrap chip khe 8; nhóm cách 16; khe 24; Đặt lại | khe 16 | Áp dụng. */
export function filterSheet(kind) {
  const groups = kind === 'members'
    ? [['Trạng thái', ['Tất cả', 'Hoạt động', 'Tạm ngừng']], ['Vai trò', ['Tất cả', 'Chủ cửa hàng', 'Nhân viên bán hàng', 'Kế toán', 'Thủ kho']], ['Sắp xếp', ['Tất cả', 'Tên A–Z', 'Tên Z–A']]]
    : [['Trạng thái', ['Tất cả', 'Đang chờ', 'Hết hạn']], ['Kết quả gửi', ['Tất cả', 'Đã gửi', 'Gửi lỗi', 'Thu hồi']], ['Thời gian', ['Tất cả', '7 ngày', '30 ngày', 'Tùy chọn']]];
  return `<div class="t1-fsheet">${groups.map(([t, opts]) => `<div class="t1-fgroup"><b>${esc(t)}</b><div class="t1-fwrap">${opts.map((o, i) => filterChip(o, i === 0)).join('')}</div></div>`).join('')}
    <div class="t1-row2 t1-fsheet__acts">${button('Đặt lại', { variant: 'secondary', full: true })}${button('Áp dụng', { full: true })}</div></div>`;
}

/**
 * Khu Người dùng. detail(w): HTML cột phải / cả màn; null → placeholder (web) hoặc danh sách (hẹp).
 * Toast của chi tiết (ScaffoldMessenger gốc) nằm trong cột phải; toast của danh sách nằm trong cột trái.
 */
export function usersArea(v, ls, { selectedId = null, detail = null, listToast = '', placeholderToast = '' } = {}) {
  if (!isSplit(v.width)) return detail ? detail(v.width) : usersListPage(ls, v.width, { toastHtml: listToast });
  const right = detail ? detail(detailWidth(v.width)) : splitPlaceholder('Chọn một thành viên hoặc lời mời để xem chi tiết.', placeholderToast);
  return listDetail(v.width, usersListPage(ls, LIST_WIDTH, { selectedId, toastHtml: listToast }), right);
}

export function usersPage(v) {
  const s = LIST_STATES[v.state];
  const t = s.toast ? toast(...s.toast, { device: v.device, above: BAR_H }) : '';
  // Web: thu hồi xong context.go('/more/users') → toast gốc hiện ở cột phải (Scaffold placeholder); hẹp: pop về danh sách.
  const page = usersArea(v, s, { listToast: isSplit(v.width) ? '' : t, placeholderToast: isSplit(v.width) ? t : '' });
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
  // Bố cục iPhone thiết kế lại qua impeccable live (2026-11-25): thẻ Email (ghi chú dưới ô, giữ cả khi báo lỗi) → thẻ "Vai trò ban đầu" chọn bằng 4 dòng radio + mô tả → câu "có thể thay đổi sau".
  const roleRow = ([name, d]) => {
    const on = name === s.role;
    return `<button type="button" role="radio" class="t1-rolelist__opt${on ? ' is-on' : ''}" aria-checked="${on}">${radio(on)}<span><b>${esc(name)}</b><small>${esc(d)}</small></span></button>`;
  };
  const body = `<div class="t1-list t1-invitem">
    ${card(`${field({ label: 'Email', required: true, control: input({ value: s.email || '', hint: 'nhanvien@minhphat.vn', invalid: !!e.email }), error: e.email })}
      <p class="t1-small t1-invitem__note">Người nhận phải đăng nhập đúng email. Lời mời sẽ hết hạn sau 7 ngày.</p>`, 't1-card--pad')}
    ${card(`<div class="t1-rolelist__legend"><span class="t1-label">Vai trò ban đầu<i aria-hidden="true"> *</i></span></div>
      <div role="radiogroup" aria-label="Vai trò ban đầu">${SELECT_ROLES.map(roleRow).join('')}</div>`, `t1-rolelist${e.role ? ' is-invalid' : ''}`)}
    ${e.role ? `<div class="t1-invitem__error">${fieldError(e.role)}</div>` : ''}
    <p class="t1-small t1-invitem__later">Vai trò có thể thay đổi sau khi tham gia.</p>
  </div>`;
  // Nút gửi: khi đang gửi đổi chữ "Đang gửi..." + tắt (không có vòng xoay).
  const bar = `<div class="t1-bar-pad t1-row2 t1-row2--8">${button('Hủy', { variant: 'secondary', full: true, disabled: !!s.busy })}${button(s.busy ? 'Đang gửi...' : 'Gửi lời mời', { full: true, disabled: !!s.busy })}</div>`;
  return { page: vScaffold({ ...base, body, bottomBar: bar, toastHtml: s.toast ? toast(...s.toast, { device: v.device, above: BAR_H }) : '' }) };
}

// ---------------------------------------------------------------- ID-16 chi tiết lời mời
export const INVITATION_STATES = {
  pending: { id: 'i1' }, 'delivery-failed': { id: 'i3' }, expired: { id: 'i4' }, loading: { id: 'i1', loading: true }, error: { id: 'i1', error: true },
  actions: { id: 'i1', sheet: 'actions' }, revoke: { id: 'i1', sheet: 'revoke' }, 'revoke-empty': { id: 'i1', sheet: 'revoke', revokeError: 'Vui lòng nhập lý do thu hồi.' },
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
  // Bố cục iPhone thiết kế lại qua impeccable live (2026-11-25): ô thư + email + hạn → thẻ "Thông tin lời mời" (vai trò, trạng thái, giao nhận); nhãn như bản web, không in giá trị wire.
  const delivery = statusDetail(i).split(' · ').pop();
  const body = `<div class="t1-list t1-orgm">
    <div class="t1-orgm__head"><div class="t1-orgm__icon" aria-hidden="true">${icon('mail')}</div><div><h2>${esc(i.email)}</h2><p>${esc(i.expiry)}</p></div></div>
    <section class="t1-card t1-card--pad t1-orgm__sec"><h3 class="t1-h4 t1-h4--600">Thông tin lời mời</h3>
      ${kv('Vai trò ban đầu', i.role, 't1-kv--profile')}<div class="t1-orgm__status"><span>Trạng thái</span>${badge(label, tone)}</div>${kv('Giao nhận', delivery, 't1-kv--profile')}</section>
  </div>`;
  const canMutate = i.wire === 'pending';
  const bar = canMutate ? `<div class="t1-bar-pad">${button('Thao tác', { full: true, trailing: 'chevronUp', loading: !!s.revokeBusy, attrs: 'data-primary' })}</div>` : '';
  return vScaffold({ ...base, body, bottomBar: bar, toastHtml: s.toast ? toast(...s.toast, { device, above: canMutate ? BAR_H : 0 }) : '' });
}

/** Sheet "Thao tác lời mời" (có title): đệm 16; IamActionTile gửi lại / khe 8 / thu hồi (danger) / khe 16. */
const invitationActions = () => `<div class="t1-list">${actionTile('rotate', 'Gửi lại lời mời', 'Gửi lại email đến người nhận')}<div class="t1-gap-sm"></div>${actionTile('trash', 'Thu hồi lời mời', 'Người nhận không thể tiếp tục tham gia', true)}<div class="t1-gap-md"></div></div>`;
/** _RevokeInvitationSheetBody: đệm 16; H3 w700 danger; khe 4; bodyDefault; (không khe) VField "Lý do thu hồi" + ô 3 dòng; khe 24; Quay lại / khe 8 / Thu hồi (secondary danger) / khe 8. */
export const revokeSheet = (s) => `<div class="t1-list"><h2 class="t1-h3 t1-danger">Thu hồi lời mời?</h2><div class="t1-gap-xs"></div>
  <p class="t1-body2">Người nhận sẽ không thể dùng liên kết hiện tại để tham gia tổ chức.</p>
  ${field({ label: 'Lý do thu hồi', control: textArea({ value: s.reason || '', hint: 'Ví dụ: Sai email người nhận', invalid: !!s.revokeError, disabled: !!s.revokeBusy }), error: s.revokeError })}
  <div class="t1-gap-lg"></div>${button('Quay lại', { variant: 'secondary', full: true, disabled: !!s.revokeBusy })}<div class="t1-gap-sm"></div>
  ${button('Thu hồi lời mời', { variant: 'secondary', full: true, loading: !!s.revokeBusy, cls: 't1-btn--danger-outline' })}<div class="t1-gap-sm"></div></div>`;

export function invitationDetailPage(v) {
  const s = INVITATION_STATES[v.state];
  const page = usersArea(v, { tab: 1 }, { selectedId: s.id, detail: (w) => invitationDetail(s, w, isSplit(v.width), v.device) });
  let overlay = '';
  if (s.sheet === 'actions') overlay = adaptiveSheet(v.width, invitationActions(), '', { title: 'Thao tác lời mời' });
  if (s.sheet === 'revoke') overlay = adaptiveSheet(v.width, revokeSheet(s), 'Thu hồi lời mời?');
  return { page, overlay };
}

// ---------------------------------------------------------------- ID-17 chi tiết thành viên
export const MEMBER_STATES = {
  active: { id: 'm2' }, suspended: { id: 'm3' }, removed: { id: 'm4' }, owner: { id: 'm1' }, loading: { id: 'm2', loading: true }, error: { id: 'm2', error: true },
  actions: { id: 'm2', sheet: 'actions' }, 'actions-suspended': { id: 'm3', sheet: 'actions' },
  deactivate: { id: 'm2', sheet: 'deactivate' }, reactivate: { id: 'm3', sheet: 'reactivate' }, remove: { id: 'm2', sheet: 'remove' },
  'remove-submitting': { id: 'm2', sheet: 'remove', busy: true },
  'toast-deactivated': { id: 'm3', toast: ['success', 'Đã tạm ngừng thành viên.', ''] },
  'toast-role-changed': { id: 'm2', toast: ['success', 'Đã thay đổi vai trò thành công.', ''] },
  'toast-last-owner': { id: 'm2', toast: ['warning', 'Không thể thực hiện', 'Không thể thực hiện vì đây là chủ sở hữu cuối cùng.'] },
};

/** _DetailRow (iPhone 2026-11-25): nhãn bodyDefault textSecondary ↔ giá trị bodyDefault w600 phải. */
const drow = (l, val) => kv(l, val, 't1-kv--profile');
/** Ô tròn 52: chữ đầu của tên; xám khi không còn hoạt động. */
const memberAvatar = (m) => `<span class="t1-orgm__avatar${m.status === 'active' ? '' : ' is-off'}" aria-hidden="true">${esc(m.name.trim().split(/\s+/).pop()[0])}</span>`;

function memberDetail(s, w, split, device) {
  const base = { title: 'Chi tiết thành viên', back: !split, placeWidth: w };
  if (s.loading) return vScaffold({ ...base, body: centerLoading(), fixed: true });
  if (s.error) return vScaffold({ ...base, body: loadFailed('Không tải được thành viên', 'Không tìm thấy tài nguyên.'), fixed: true });
  const m = memberById(s.id);
  const [label, tone] = MEMBER_BADGE[m.status];
  const access = m.status === 'active' ? drow('Ngày tham gia', m.joined) + drow('Hoạt động gần nhất', m.lastActive)
    : m.status === 'suspended' ? drow('Tạm ngừng lúc', m.suspendedAt) : drow('Đã loại lúc', m.removedAt) + drow('Vai trò trước đó', m.role);
  const note = m.status === 'suspended' ? banner('warning', 'Quyền truy cập đã tạm ngừng', 'Thành viên không thể truy cập tổ chức cho đến khi được kích hoạt lại.')
    : m.status === 'removed' ? banner('info', 'Thành viên đã được loại', 'Quyền truy cập đã kết thúc. Lịch sử và dữ liệu nghiệp vụ vẫn được giữ lại.') : '';
  // Bố cục iPhone thiết kế lại qua impeccable live (2026-11-25): ô tròn + tên + email → thẻ "Thông tin thành viên" (+ nhãn) → thông báo (tạm ngừng / đã loại) → thẻ "Trạng thái truy cập".
  const off = m.status === 'removed' ? ' t1-o60' : '';
  const body = `<div class="t1-list t1-orgm">
    <div class="t1-orgm__head${off}">${memberAvatar(m)}<div><h2>${esc(m.name)}</h2><p>${esc(m.email)}</p></div></div>
    <section class="t1-card t1-card--pad t1-orgm__sec${off}"><div class="t1-dhead"><h3 class="t1-h4 t1-h4--600">Thông tin thành viên</h3>${badge(label, tone)}</div>
      ${drow('Tên', m.name)}${drow('Email', m.email)}${drow('Vai trò hiện hành', m.role)}${drow(m.isOwner ? 'Quyền sở hữu' : 'Danh tính', m.isOwner ? 'Chủ sở hữu' : 'Chỉ đọc')}</section>
    ${note}
    <section class="t1-card t1-card--pad t1-orgm__sec"><h3 class="t1-h4 t1-h4--600">Trạng thái truy cập</h3>${access}</section>
  </div>`;
  const hasActions = !m.soleOwner && m.status !== 'removed';
  const bar = hasActions ? `<div class="t1-bar-pad">${button('Thao tác', { full: true, trailing: 'chevronUp', loading: !!s.busy, attrs: 'data-primary' })}</div>` : '';
  return vScaffold({ ...base, body, bottomBar: bar, toastHtml: s.toast ? toast(...s.toast, { device, above: hasActions ? BAR_H : 0 }) : '' });
}

/** showMemberLifecycleActionsBottomSheet: đệm 16 / 8 / 16 / 24; H3 w700 "Thao tác thành viên"; khe 16; tile cách 8. */
function memberActions(m) {
  const tiles = [actionTile('shield', 'Thay đổi vai trò', 'Cập nhật vai trò')];
  if (m.status === 'active') tiles.push(actionTile('pause', 'Tạm ngừng thành viên', 'Dừng quyền truy cập tạm thời'));
  if (m.status === 'suspended') tiles.push(actionTile('userCheck', 'Kích hoạt lại', 'Khôi phục quyền truy cập'));
  tiles.push(actionTile('userX', 'Loại khỏi tổ chức', 'Kết thúc tư cách thành viên', true));
  return `<div class="t1-sheetpad"><h2 class="t1-h3">Thao tác thành viên</h2><div class="t1-gap-md"></div>${tiles.join('<div class="t1-gap-sm"></div>')}</div>`;
}
/** MembershipLifecycleConfirmSheet: đệm 16 / 8 / 16 / 24; H3 w700 (danger tuỳ); khe 4; bodyDefault; khe 32; Quay lại / khe 8 / nút xác nhận. */
export const LIFECYCLE = {
  deactivate: { title: 'Tạm ngừng thành viên?', danger: true, desc: 'Thành viên mất quyền truy cập tới khi được kích hoạt lại.', ok: 'Tạm ngừng' },
  reactivate: { title: 'Kích hoạt lại thành viên?', danger: false, desc: 'Quyền truy cập sẽ được khôi phục theo vai trò hiện hành.', ok: 'Kích hoạt lại' },
  remove: { title: 'Loại thành viên khỏi tổ chức?', danger: true, desc: 'Thành viên sẽ kết thúc vĩnh viễn. Người này cần lời mời mới nếu quay lại.', ok: 'Loại thành viên' },
};
export const lifecycleSheet = (k, busy) => {
  const c = LIFECYCLE[k];
  return `<div class="t1-sheetpad"><h2 class="t1-h3${c.danger ? ' t1-danger' : ''}">${esc(c.title)}</h2><div class="t1-gap-xs"></div><p class="t1-body2">${esc(c.desc)}</p><div class="t1-gap-xl"></div>
    ${button('Quay lại', { variant: 'secondary', full: true, disabled: busy })}<div class="t1-gap-sm"></div>
    ${button(c.ok, { variant: c.danger ? 'secondary' : 'primary', full: true, loading: busy, cls: c.danger ? 't1-btn--danger-outline' : '' })}</div>`;
};

export function memberDetailPage(v) {
  const s = MEMBER_STATES[v.state];
  const page = usersArea(v, { tab: 0 }, { selectedId: s.id, detail: (w) => memberDetail(s, w, isSplit(v.width), v.device) });
  let overlay = '';
  if (s.sheet === 'actions') overlay = adaptiveSheet(v.width, memberActions(memberById(s.id)), 'Thao tác thành viên');
  else if (s.sheet) overlay = adaptiveSheet(v.width, lifecycleSheet(s.sheet, !!s.busy), LIFECYCLE[s.sheet].title);
  return { page, overlay };
}

// ---------------------------------------------------------------- ID-18 chọn vai trò
/** _availableRoles (mô tả riêng của màn này, ngắn hơn TH-01 3.4); vai trò hiện tại đưa lên đầu. */
export const SELECT_ROLES = [['Nhân viên bán hàng', 'Bán hàng và chăm sóc khách hàng'], ['Kế toán', 'Công nợ, hóa đơn và báo cáo'], ['Thủ kho', 'Nhập xuất, tồn kho và kiểm kê'], ['Chủ cửa hàng', 'Quản lý toàn bộ cửa hàng']];
export const SELECT_STATES = { default: { id: 'm2' }, selected: { id: 'm2', pick: 'Thủ kho' }, suspended: { id: 'm3' } };

// Bố cục iPhone thiết kế lại qua impeccable live (2026-11-25): ô tròn + tên + nhãn → "Chọn vai trò mới" → thẻ danh sách (vai trò hiện tại dòng đầu nền canvas, không chọn được). Web giữ bản cũ ở web/users.js.
function selectRole(s, w) {
  const m = memberById(s.id);
  const i = SELECT_ROLES.findIndex(([t]) => t === m.role);
  const roles = i > 0 ? [SELECT_ROLES[i], ...SELECT_ROLES.filter((_, k) => k !== i)] : SELECT_ROLES;
  const active = m.status === 'active';
  const item = ([t, d]) => {
    const text = `<span class="t1-rolelist__text"><b>${esc(t)}</b><small>${esc(d)}</small></span>`;
    if (t === m.role) return `<div class="t1-rolelist__opt is-current">${text}${badge('Hiện tại', 'success')}</div>`;
    const on = t === s.pick;
    return `<button type="button" role="radio" class="t1-rolelist__opt${on ? ' is-on' : ''}" aria-checked="${on}">${radio(on)}${text}</button>`;
  };
  const body = `<div class="t1-list t1-selrole">
    <div class="t1-orgm__head">${memberAvatar(m)}<div><div class="t1-selrole__name"><h2>${esc(m.name)}</h2>${badge(active ? 'Hoạt động' : 'Tạm ngừng', active ? 'success' : 'danger')}</div>
      <p>${esc(`${m.email} · ${m.role}`)}</p><p>${m.isOwner ? 'Quyền sở hữu: Chủ sở hữu' : 'Danh tính: Chỉ đọc'}</p></div></div>
    <h3 class="t1-selrole__title">Chọn vai trò mới</h3><p class="t1-small t1-selrole__sub">Mỗi thành viên có đúng một vai trò hiện hành.</p>
    ${card(`<div role="radiogroup" aria-label="Chọn vai trò mới">${roles.map(item).join('')}</div>`, 't1-rolelist')}</div>`;
  const bar = `<div class="t1-bar-pad t1-row2 t1-row2--8">${button('Hủy', { variant: 'secondary', full: true })}${button('Tiếp tục', { full: true, disabled: !s.pick, attrs: 'data-primary' })}</div>`;
  return vScaffold({ title: 'Chọn vai trò', body, bottomBar: bar, placeWidth: w });
}

export function selectRolePage(v) {
  const s = SELECT_STATES[v.state];
  return { page: usersArea(v, { tab: 0 }, { selectedId: s.id, detail: (w) => selectRole(s, w) }) };
}
