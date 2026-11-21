// Prototype Menu Thêm + Thiết lập hệ thống APP-02 (10-8). Không có ?screen= → trang xem (viewer.js); có → vẽ đúng một ca (URL chụp ảnh).
// Chép y nguyên Flutter hiện tại:
//   apps/erp/lib/features/more/presentation/{more_entries.dart, pages/more_page.dart, pages/system_settings_page.dart, pages/users_and_roles_page.dart}
//   apps/erp/lib/core/router/app_router.dart ('/more' = Scaffold + VAppBar('Thêm', showBackButton: false) + MorePage)
//   DS: VCard (emphasis subtle: không bóng), VIconBox, VAppBar, VPageScaffold (thân tối đa 720 khi cửa sổ ≥ 1024)
// Danh sách mục + luật hiện / bấm được dùng lại shared/shell.js (MORE_ENTRIES), không chép lại.
// Màn trần không có tương tác (mọi thẻ trong Flutter push sang route khác).
import { icon } from '../shared/icons.js';
import { renderShell, DEVICE, MORE_ENTRIES } from '../shared/shell.js';

const esc = (s) => String(s ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

export const ORG_NAME = 'Mosaic Retail Demo';

// ---------------------------------------------------------------- hàm thuần (đối chiếu Dart)

/** MoreEntry.isVisible */
export function isVisible(entry, { isOwner, isBlocked }) {
  return !(entry.ownerOnly && !isOwner && !isBlocked);
}

/**
 * _MoreView: mỗi mục hiện → trạng thái thẻ.
 * enabled = entry.enabled && (!needsActiveTenant || !blocked); onTap = đăng xuất | push(route) nếu isInteractive | null.
 * _MoreMenuItem: isEnabled = enabled && onTap != null → mờ 0.45 + bỏ mũi tên khi tắt.
 * isOwner = IamFeatureAccessState.canOpenIamHub. readSession() đồng bộ nên load() xong ngay khi tạo cubit; chỉ tổ chức bị chặn (không gọi load()) mới để isOwner = false.
 */
export function moreItems({ isOwner, isBlocked }) {
  return MORE_ENTRIES.filter((e) => isVisible(e, { isOwner, isBlocked })).map((e) => {
    const enabled = e.enabled !== false && (!e.needsActiveTenant || !isBlocked);
    const interactive = e.enabled !== false && !!e.route && !(e.needsActiveTenant && isBlocked);
    const hasTap = e.destructive ? true : interactive;
    return { ...e, isEnabled: enabled && hasTap };
  });
}

/** _UsersAndRolesView: thẻ theo quyền của phiên. */
export const HUB_ITEMS = [
  { id: 'org', perm: 'tenant.view', icon: 'building', title: 'Hồ sơ tổ chức', subtitle: 'Thông tin liên hệ và địa chỉ tổ chức' }, // VIcons.apartment
  { id: 'users', perm: 'tenant.member.view', icon: 'users', title: 'Người dùng', subtitle: 'Thành viên, lời mời và quyền truy cập' }, // VIcons.people
  { id: 'roles', perm: 'tenant.member.view', icon: 'shield', title: 'Vai trò', subtitle: 'Phạm vi thao tác theo từng vai trò' }, // VIcons.shield
  { id: 'audit', perm: 'tenant.audit.view', icon: 'list', title: 'Lịch sử quản trị', subtitle: 'Theo dõi thay đổi người dùng và quyền' }, // VIcons.listView
];
export function hubItems(perms) {
  return HUB_ITEMS.filter((i) => perms.includes(i.perm));
}

/** SystemSettingsPage: 2 thẻ ghi cứng. */
export const SETTINGS_ITEMS = [
  { id: 'einvoice', icon: 'fileText', title: 'Thiết lập hóa đơn điện tử', subtitle: 'Kết nối, chọn mẫu hóa đơn, cấu hình tự động phát hành và gửi HĐĐT' }, // VIcons.description
  { id: 'product', icon: 'inventory', title: 'Sản phẩm', subtitle: 'Giá bán, nhóm thông tin và trường tuỳ biến cho sản phẩm' }, // VIcons.inventory
];

// ---------------------------------------------------------------- widgets

/** VAppBar: cao 56, nền surface, gạch dưới 1 borderDefault, tiêu đề headingH3 w700; nút ← chỉ khi route pop được. */
function appBar(title, { back = false } = {}) {
  return `<header class="mr-appbar">
    ${back ? `<button type="button" class="mr-appbar__back" aria-label="Quay lại">${icon('chevronLeft')}</button>` : ''}
    <h1 class="mr-appbar__title">${esc(title)}</h1>
  </header>`;
}

/** _MoreMenuItem: VCard (đệm 16 / 14) + VIconBox 44 bo 12 (nền surfaceBrand / dangerBg) + tiêu đề H4 w700 + phụ đề bodySmall + mũi tên 20. */
function moreCard(e) {
  const cls = ['mr-card', 'mr-row', e.destructive ? 'is-danger' : '', e.isEnabled ? '' : 'is-off'].filter(Boolean).join(' ');
  return `<button type="button" class="${cls}"${e.isEnabled ? '' : ' disabled'}>
    <span class="mr-iconbox mr-iconbox--${e.destructive ? 'danger' : 'brand'}">${icon(e.icon)}</span>
    <span class="mr-row__text"><b>${esc(e.title)}</b><small>${esc(e.subtitle)}</small></span>
    ${e.isEnabled ? `<span class="mr-row__chevron">${icon('chevronRight')}</span>` : ''}
  </button>`;
}

/** SystemSettingsPage: như _MoreMenuItem nhưng VIconBox không truyền nền → surface (trắng trên thẻ trắng); phụ đề tối đa 2 dòng. */
function settingsCard(i) {
  return `<button type="button" class="mr-card mr-row mr-row--two">
    <span class="mr-iconbox mr-iconbox--plain">${icon(i.icon)}</span>
    <span class="mr-row__text"><b>${esc(i.title)}</b><small>${esc(i.subtitle)}</small></span>
    <span class="mr-row__chevron">${icon('chevronRight')}</span>
  </button>`;
}

/** _HubMenuCard: VCard đệm 16 / 16; VIcon 20 textPrimary + khe 8; tiêu đề bodyDefault w700; phụ đề bodySmall, không giới hạn dòng. */
function hubCard(i) {
  return `<button type="button" class="mr-card mr-row mr-row--hub">
    <span class="mr-row__icon">${icon(i.icon)}</span>
    <span class="mr-row__text"><b>${esc(i.title)}</b><small>${esc(i.subtitle)}</small></span>
    <span class="mr-row__chevron">${icon('chevronRight')}</span>
  </button>`;
}

/** '/more': Scaffold(appBar: VAppBar('Thêm'), body: ListView đệm 16 / 16, khe 12). Không giới hạn bề rộng. */
export function morePage(v) {
  return `<div class="mr-page">
    ${appBar('Thêm')}
    <div class="mr-body"><div class="mr-list mr-list--more">${moreItems(v).map(moreCard).join('')}</div></div>
  </div>`;
}

/** VPageScaffold: thân trong cột tối đa 720 (≥ 1024) / 640 (tablet), đệm hai bên = (rộng − 720) / 2. */
function pageScaffold(title, list, v) {
  return `<div class="mr-page mr-page--scaffold">
    ${appBar(title, { back: true })}
    <div class="mr-body"><div class="mr-column" style="--mr-col:${columnMax(v.width)}">${list}</div></div>
  </div>`;
}
/** VPageScaffold.defaultContentMaxWidth theo VBreakpoints (tablet 600, desktop 1024). */
export function columnMax(width) {
  if (width >= 1024) return '720px';
  if (width >= 600) return '640px';
  return '100%';
}

export function settingsPage(v) {
  return pageScaffold('Thiết lập', `<div class="mr-list mr-list--more">${SETTINGS_ITEMS.map(settingsCard).join('')}</div>`, v);
}

export function usersPage(v) {
  const items = hubItems(v.perms);
  return pageScaffold('Người dùng & vai trò', `<div class="mr-list mr-list--hub">${items.map(hubCard).join('')}</div>`, v);
}

// ---------------------------------------------------------------- ca

const ALL_PERMS = ['tenant.view', 'tenant.member.view', 'tenant.audit.view'];
const LOCATION = { more: '/more', settings: '/more/settings', users: '/more/users-and-roles' };

/** Trạng thái ban đầu của một ca. */
export function caseView(screen, state, device) {
  const v = {
    screen, device, width: DEVICE[device].w, location: LOCATION[screen] || '/more',
    isOwner: true, isBlocked: false, orgName: ORG_NAME,
    perms: ALL_PERMS,
  };
  if (screen === 'more' && state === 'staff') v.isOwner = false;
  if (screen === 'more' && state === 'blocked') { v.isBlocked = true; v.isOwner = false; }
  if (screen === 'users' && state === 'partial') v.perms = ['tenant.view'];
  if (screen === 'users' && state === 'empty') v.perms = [];
  return v;
}

export function renderView(v) {
  const page = v.screen === 'settings' ? settingsPage(v) : v.screen === 'users' ? usersPage(v) : morePage(v);
  return renderShell(v, page);
}

export function render(screen, state, device) {
  return renderView(caseView(screen, state, device));
}

// ---------------------------------------------------------------- chạy trong trình duyệt
if (typeof document !== 'undefined') {
  const q = new URLSearchParams(location.search);
  if (!q.get('screen')) {
    import('./viewer.js').then((m) => m.mountViewer(document.getElementById('root')));
  } else {
    const device = q.get('device') === 'web' ? 'web' : 'iphone';
    const v = caseView(q.get('screen'), q.get('state'), device);
    document.getElementById('root').innerHTML = `<div class="sh-stage" data-device="${device}">${renderView(v)}</div>`;
  }
}
