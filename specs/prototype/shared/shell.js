// Khung chung của app cửa hàng (10-8 "Layout tổng thể"): thanh bên web, thanh dưới iPhone, màn chờ / lỗi trước khung.
// Vẽ đúng Flutter hiện tại — nguồn:
//   apps/erp/lib/features/dashboard/presentation/{store_shell.dart, erp_tab_scaffold.dart}
//   apps/erp/lib/features/dashboard/presentation/widgets/{erp_side_navigation.dart, erp_bottom_navigation.dart, tenant_ready_gate.dart, default_pair_gate_error_view.dart}
//   apps/erp/lib/features/more/presentation/more_entries.dart
//   packages/c45_design_system/lib/src/components/{v_side_navigation.dart, v_bottom_navigation_bar.dart}
// Theme khác dùng: import { renderShell } from '../shared/shell.js' + nạp shared/shell.css; HTML màn đưa vào tham số thứ hai.
import { icon } from './icons.js';

export const DESKTOP = 1024; // VBreakpoints.desktop: ≥ 1024 thanh bên, < 1024 thanh dưới
export const SIDE_WIDTH = 240; // VSideNavigation.width
export const CONTENT_MAX = 1120; // VContentWidth.defaultMaxWidth.desktop
export const DEVICE = { iphone: { w: 390, h: 844, inset: 34 }, web: { w: 1280, h: 800, inset: 0 } };

// ErpTab (erp_bottom_navigation.dart). icon = tên trong icons.js thay cho Icons.* của Material.
export const TABS = [
  { id: 'home', label: 'Trang chủ', icon: 'home', route: '/' }, // Icons.home_outlined
  { id: 'orders', label: 'Đơn hàng', icon: 'receipt', route: '/orders' }, // Icons.receipt_long_outlined
  { id: 'products', label: 'Sản phẩm', icon: 'inventory', route: '/products/items' }, // Icons.inventory_2_outlined
  { id: 'partners', label: 'Đối tác', icon: 'users', route: '/partner' }, // Icons.people_outline_rounded
  { id: 'more', label: 'Thêm', icon: 'more', route: '/more' }, // Icons.more_horiz_rounded
];

// kMoreEntries (more_entries.dart), giữ thứ tự.
export const MORE_ENTRIES = [
  { id: 'customers', icon: 'users', title: 'Khách hàng & NCC', subtitle: 'Quản lý khách hàng & nhà cung cấp', enabled: false },
  { id: 'receivables', icon: 'wallet', title: 'Công nợ phải thu', subtitle: 'Khách đang nợ, quá hạn, thu tiền', route: '/more/receivables', needsActiveTenant: true, matchPrefixes: ['/more/receivables'] },
  { id: 'purchase_orders', icon: 'download', title: 'Đơn nhập', subtitle: 'Nhập kho từ nhà cung cấp', enabled: false },
  { id: 'inventory', icon: 'warehouse', title: 'Kho', subtitle: 'Tồn kho, phiếu nhập, điều chỉnh', route: '/warehouse', needsActiveTenant: true, matchPrefixes: ['/inventory', '/warehouse'] },
  { id: 'reports', icon: 'chart', title: 'Báo cáo', subtitle: 'Doanh thu, tồn kho, công nợ', enabled: false },
  { id: 'pricing', icon: 'tag', title: 'Giá riêng', subtitle: 'Giá riêng theo khách hàng', route: '/pricing', needsActiveTenant: true, matchPrefixes: ['/pricing'] },
  { id: 'users_and_roles', icon: 'users', title: 'Người dùng & vai trò', subtitle: 'Quản lý thành viên và quyền truy cập', route: '/more/users-and-roles', ownerOnly: true, needsActiveTenant: true, matchPrefixes: ['/more/users-and-roles', '/more/organization-profile', '/more/users', '/more/roles', '/more/audit-logs'] },
  { id: 'my_account', icon: 'user', title: 'Tài khoản của tôi', subtitle: 'Xem và chỉnh sửa thông tin cá nhân', route: '/more/my-account', matchPrefixes: ['/more/my-account'] },
  { id: 'settings', icon: 'settings', title: 'Thiết lập', subtitle: 'Cấu hình hệ thống & hóa đơn điện tử', route: '/more/settings', needsActiveTenant: true, matchPrefixes: ['/more/settings', '/more/einvoice', '/more/product-settings'] },
  { id: 'logout', icon: 'logout', title: 'Đăng xuất', subtitle: 'Thoát khỏi tài khoản hiện tại', destructive: true },
];

const esc = (s) => String(s ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

/** ErpTab.fromLocation */
export function tabFromLocation(location) {
  if (location === '/') return 'home';
  if (location.startsWith('/orders') || location.startsWith('/sales')) return 'orders';
  if (location.startsWith('/products')) return 'products';
  if (location.startsWith('/partner')) return 'partners';
  if (['/more', '/inventory', '/warehouse', '/pricing'].some((p) => location.startsWith(p))) return 'more';
  return 'home';
}

/**
 * Đường dẫn nằm trong ShellRoute(StoreShell) của app_router.dart: 5 nhánh tab + /warehouse (warehouseHubRoutes trong nhánh "Thêm").
 * Mọi route khác (/more/receivables, /pricing, /more/settings, /more/users-and-roles, /more/my-account, trang chi tiết đối tác…)
 * khai báo ngoài ShellRoute → mở toàn màn, KHÔNG có thanh bên / thanh dưới (kể cả trên web).
 */
export function insideShell(location) {
  if (location === '/' || location === '/more') return true;
  if (location === '/products/items' || location.startsWith('/products/items/')) return !/^\/products\/items\/(new|[^/]+\/(view|checklist|measurement-units|note|manual-base-price|price-bands|custom-fields|profile-maintenance|images-maintenance|change-history))/.test(location);
  if (location === '/partner' || /^\/partner\/[^/]+$/.test(location)) return location !== '/partner/new';
  if (location === '/orders') return true; // nhánh Đơn hàng chỉ có SalesNav.ordersList
  return location === '/warehouse' || location.startsWith('/warehouse/');
}

/** kSideNavSubEntries: mục có route và đang bật. */
export const SIDE_SUB_ENTRIES = MORE_ENTRIES.filter((e) => e.route && e.enabled !== false);

/** MoreEntry.isVisible (lọc trong ErpSideNavigation): mục chỉ chủ cửa hàng ẩn với người khác, trừ khi tổ chức bị chặn. */
export function visibleSubEntries({ isOwner = true, isBlocked = false } = {}) {
  return SIDE_SUB_ENTRIES.filter((e) => !(e.ownerOnly && !isOwner && !isBlocked));
}

/** MoreEntry.isInteractive */
export function isInteractive(entry, { isBlocked = false } = {}) {
  if (entry.enabled === false || !entry.route) return false;
  return !(entry.needsActiveTenant && isBlocked);
}

/** selectedMoreEntry: khớp tiền tố đầu tiên từ trên xuống; '/more' đúng bằng → null. */
export function selectedMoreEntry(location) {
  if (location === '/more') return null;
  return SIDE_SUB_ENTRIES.find((e) => (e.matchPrefixes || []).some((p) => location === p || location.startsWith(`${p}/`))) || null;
}

/** Thanh biểu tượng web (≥ 1024) — ĐỀ XUẤT thay ErpSideNavigation 240 (chưa có trong Flutter).
 *  Rộng 84: ô tổ chức (bấm để đổi), 4 tab (icon + nhãn, không có "Thêm"), "Quản lý" mở menu nổi
 *  (popover) chứa 6 tính năng phụ kèm mô tả, Đăng xuất ở đáy. Đang ở một tính năng phụ → "Quản lý" sáng. */
export function sideNav({ location = '/', isOwner = true, isBlocked = false, orgName = 'Chưa chọn tổ chức' } = {}) {
  const tab = tabFromLocation(location);
  const sel = tab === 'more' ? selectedMoreEntry(location) : null;
  const tabs = TABS.filter((t) => t.id !== 'more').map((t) => {
    const on = t.id === tab;
    return `<button type="button" class="sh-side__tab${on ? ' is-on' : ''}" data-shell-route="${t.route}"${on ? ' aria-current="page"' : ''}>${icon(t.icon)}<span>${esc(t.label)}</span></button>`;
  }).join('');
  const subs = visibleSubEntries({ isOwner, isBlocked }).map((e) => {
    const on = sel?.id === e.id;
    return `<button type="button" class="sh-menu__item${on ? ' is-on' : ''}" data-shell-route="${e.route}"${on ? ' aria-current="page"' : ''}${isInteractive(e, { isBlocked }) ? '' : ' disabled'}><span class="sh-menu__icon">${icon(e.icon)}</span><span class="sh-menu__text"><b>${esc(e.title)}</b><small>${esc(e.subtitle)}</small></span></button>`;
  }).join('');
  const initial = isBlocked ? '' : esc(String(orgName).trim().charAt(0).toUpperCase());
  return `<nav class="sh-side" aria-label="Điều hướng chính">
    <button type="button" class="sh-side__org" data-shell-org aria-label="Đổi tổ chức, ${esc(orgName)}" title="${esc(orgName)}">${initial || icon('store')}</button>
    ${tabs}
    <span class="sh-side__spacer"></span>
    <button type="button" class="sh-side__tab sh-side__manage${tab === 'more' ? ' is-on' : ''}" popovertarget="sh-manage-menu">${icon('layers')}<span>Quản lý</span></button>
    <button type="button" class="sh-side__tab sh-side__logout" data-shell-logout>${icon('logout')}<span>Đăng xuất</span></button>
    <div id="sh-manage-menu" class="sh-menu sh-side__menu" popover><p class="sh-menu__title">Quản lý cửa hàng</p>${subs}</div>
  </nav>`;
}

/** Thanh dưới (ErpBottomNavigation + VBottomNavigationBar). inset = MediaQuery.padding.bottom (iPhone 34, web 0 → đệm 12). */
export function bottomNav({ location = '/', inset = 0 } = {}) {
  const tab = tabFromLocation(location);
  const items = TABS.map((t) => {
    const on = t.id === tab;
    return `<button type="button" class="sh-bottom__item${on ? ' is-selected' : ''}" data-shell-route="${t.route}"${on ? ' aria-current="page"' : ''}>${icon(t.icon, 'sh-bottom__icon')}<span>${esc(t.label)}</span></button>`;
  }).join('');
  return `<nav class="sh-bottom" aria-label="Điều hướng chính" style="padding-bottom:${inset > 0 ? inset : 12}px">${items}</nav>`;
}

/** Thanh trạng thái iPhone (giả lập, cùng class Theme 6 dùng). */
export const statusBar = () => '<div class="app-statusbar"><span>09:41</span><span>LTE&nbsp;&nbsp;100%</span></div>';

/** Vòng tải giữa màn (VLoading). */
export const loading = () => '<div class="sh-center"><span class="sh-spinner" role="progressbar" aria-label="Đang tải"></span></div>';

/** Thẻ báo giữa màn: OrganizationEmptyView / DefaultPairGateErrorView (cùng bố cục: vòng icon 64, tiêu đề H3, mô tả, nút chữ). */
export function noticeCard({ tone = 'neutral', ic = 'info', title, description, actions = [], compact = false }) {
  return `<div class="sh-notice${compact ? ' sh-notice--compact' : ''}">
    <div class="sh-notice__card">
      <span class="sh-notice__badge sh-notice__badge--${tone}">${icon(ic)}</span>
      <h3 class="sh-notice__title${tone === 'danger' ? ' is-danger' : ''}">${esc(title)}</h3>
      <p class="sh-notice__desc">${esc(description)}</p>
      <div class="sh-notice__actions">${actions.map((a) => `<button type="button" class="sh-link" ${a.attrs || ''}>${esc(a.label)}</button>`).join('')}</div>
    </div>
  </div>`;
}

/** DefaultPairGateErrorView */
export const gateError = () => noticeCard({
  tone: 'danger', ic: 'error', title: 'Không thiết lập được kho mặc định',
  description: 'Cửa hàng và kho mặc định chưa sẵn sàng. Thử lại hoặc chọn tổ chức khác.',
  actions: [{ label: 'Thử lại', attrs: 'data-shell-retry' }, { label: 'Chọn tổ chức khác', attrs: 'data-shell-org' }],
});

/** TenantReadyGate khi tổ chức bị chặn (OrganizationEmptyView noAuthorizedOrganizations, bản thường). */
export const blockedNotice = () => noticeCard({
  ic: 'info', title: 'Chưa có tổ chức được cấp quyền',
  description: 'Bạn chưa được cấp quyền truy cập tổ chức nào. Hãy kiểm tra lời mời hoặc liên hệ Chủ cửa hàng.',
  actions: [{ label: 'Kiểm tra lại', attrs: 'data-shell-org' }],
});

/**
 * Vẽ cả khung.
 * opts.device   'iphone' | 'web'                 khổ và có thanh trạng thái hay không
 * opts.width    số px (mặc định theo device)       < 1024 → thanh dưới, ≥ 1024 → thanh bên
 * opts.height   số px (mặc định theo device)
 * opts.location đường dẫn hiện tại (chọn tab / mục con)
 * opts.gate     'ready' | 'loading' | 'error'      cặp cửa hàng–kho mặc định chưa sẵn sàng → cả màn, không có điều hướng
 * opts.isOwner, opts.isBlocked, opts.orgName       phiên làm việc
 * opts.overlay  HTML phủ lên trên (sheet / hộp thoại / toast)
 * content       HTML phần màn bên trong khung
 */
export function renderShell(opts = {}, content = '') {
  const device = opts.device === 'web' ? 'web' : 'iphone';
  const d = DEVICE[device];
  const width = opts.width ?? d.w;
  const height = opts.height ?? d.h;
  const location = opts.location ?? '/';
  const gate = opts.gate ?? 'ready';
  const isBlocked = !!opts.isBlocked;
  const desktop = width >= DESKTOP;
  const top = device === 'iphone' ? statusBar() : '';
  let body;
  if (!insideShell(location)) {
    // Route ngoài ShellRoute: chỉ có màn, không khung.
    body = `<div class="sh-mobile"><main class="sh-main">${content}</main></div>`;
    return `<div class="sh-app" data-device="${device}" data-layout="bare" style="width:${width}px;height:${height}px">${top}${body}${opts.overlay || ''}</div>`;
  }
  if (gate !== 'ready') {
    // StoreShell._buildGateHold: Scaffold nền background, không thanh bên / thanh dưới.
    body = `<div class="sh-hold">${gate === 'loading' ? loading() : gateError()}</div>`;
  } else {
    // ErpTabScaffold: tab khác "Thêm" đi qua TenantReadyGate.
    const tab = tabFromLocation(location);
    const inner = isBlocked && tab !== 'more' ? `<div class="sh-hold sh-hold--center">${blockedNotice()}</div>` : content;
    if (desktop) {
      body = `<div class="sh-desktop">${sideNav({ location, isOwner: opts.isOwner ?? true, isBlocked, orgName: opts.orgName })}<main class="sh-main"><div class="sh-content">${inner}</div></main></div>`;
    } else {
      // ErpTabScaffold luôn vẽ thanh dưới cho mọi route trong nhánh (kể cả /warehouse/...).
      body = `<div class="sh-mobile"><main class="sh-main">${inner}</main>${bottomNav({ location, inset: d.inset })}</div>`;
    }
  }
  return `<div class="sh-app" data-device="${device}" data-layout="${gate !== 'ready' ? 'hold' : desktop ? 'desktop' : 'mobile'}" style="width:${width}px;height:${height}px">${top}${body}${opts.overlay || ''}</div>`;
}
