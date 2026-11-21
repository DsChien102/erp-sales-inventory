// Prototype Trang chủ APP-01 (10-8). Không có ?screen= → trang xem (viewer.js); có → vẽ đúng một ca (URL chụp ảnh).
// Chép y nguyên Flutter hiện tại (features/dashboard/presentation/home_tab_page.dart + widgets/), kể cả số liệu ghi cứng và chữ mẫu.
// Tương tác ở URL màn trần: bấm × trên banner để ẩn banner. Các nút khác trong Flutter là onTap: () {} hoặc mở route ngoài khung nên không làm gì.
import { icon } from '../shared/icons.js';
import { renderShell, DEVICE } from '../shared/shell.js';

const esc = (s) => String(s ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

export const ORG_NAME = 'Mosaic Retail Demo';
export const LONG_ORG_NAME = 'Cửa hàng Phân bón Hưng Phát — Chi nhánh Quốc lộ 1A, Long An';

/** HomeHeader._greetingForHour */
export function greetingForHour(hour) {
  if (hour >= 5 && hour < 12) return 'Chào buổi sáng';
  if (hour >= 12 && hour < 18) return 'Chào buổi chiều';
  return 'Chào buổi tối';
}

/** HomeTabPage: banner chỉ khi chủ + chưa ẩn; LegalProfileHomeBanner còn đòi tenant đã tải và chưa có legalProfile. */
export function showLegalBanner({ isOwner, bannerDismissed, hasLegalProfile }) {
  return isOwner && !bannerDismissed && !hasLegalProfile;
}

// ---------------------------------------------------------------- widgets

/** DashboardHeader → HomeHeader (nền primary, đệm 16) + VSearchBar.header readOnly. */
function header({ greeting, branchName }) {
  return `<header class="hm-header">
    <div class="hm-header__row">
      <div class="hm-header__titles">
        <p class="hm-header__greeting">${esc(greeting)} 👋</p>
        <button type="button" class="hm-header__branch" data-home-branch>
          <span class="hm-header__store">${icon('store')}</span>
          <span class="hm-header__name">${esc(branchName)}</span>
          <span class="hm-header__caret">${icon('chevronDown')}</span>
        </button>
      </div>
      <div class="hm-bell">
        <button type="button" class="hm-bell__button" aria-label="Thông báo">${icon('bell')}</button>
        <span class="hm-bell__dot" aria-hidden="true"></span>
      </div>
    </div>
    <label class="hm-search">
      <span class="hm-search__icon">${icon('search')}</span>
      <input type="text" readonly placeholder="Tìm đơn hàng, sản phẩm, khách hàng..." aria-label="Tìm đơn hàng, sản phẩm, khách hàng..." />
    </label>
  </header>`;
}

/** LegalProfileHomeBanner → VBanner(status: info) + IconButton(close) + VButton.link "Bổ sung". */
function legalBanner() {
  return `<div class="hm-banner-wrap">
    <section class="hm-banner" aria-label="Bổ sung hồ sơ pháp lý để xuất hoá đơn điện tử.">
      <div class="hm-banner__row">
        <span class="hm-banner__icon">${icon('info')}</span>
        <div class="hm-banner__head">
          <p class="hm-banner__title">Bổ sung hồ sơ pháp lý để xuất hoá đơn điện tử.</p>
          <button type="button" class="hm-banner__close" aria-label="Đóng" data-home-dismiss>${icon('close')}</button>
        </div>
      </div>
      <div class="hm-banner__footer"><button type="button" class="hm-link">Bổ sung</button></div>
    </section>
  </div>`;
}

/** _SectionHeader */
const sectionHeader = (title) => `<h2 class="hm-section">${esc(title)}</h2>`;

/** RevenueSummaryCard → RevenueCard (giá trị ghi cứng trong Flutter). */
function revenueCard() {
  return `<button type="button" class="hm-revenue" aria-label="Doanh thu hôm nay">
    <span class="hm-revenue__top">
      <span class="hm-revenue__title">${icon('trendingUp')}<span>Doanh thu hôm nay</span></span>
      ${icon('chevronRight')}
    </span>
    <span class="hm-revenue__amount">8.420.000 ₫</span>
    <span class="hm-revenue__sub">Từ 12 đơn · +18% so với hôm qua</span>
  </button>`;
}

/** MetricTile → MetricCard (VCard emphasis medium, value mặc định "-"). */
function metric({ ic, tone, label, value = '-' }) {
  return `<div class="hm-card hm-metric">
    <span class="hm-metric__icon hm-tone--${tone}">${icon(ic)}</span>
    <span class="hm-metric__value">${esc(value)}</span>
    <span class="hm-metric__label">${esc(label)}</span>
  </div>`;
}

/** TaskItem → TodoItem (chữ mẫu mặc định của TaskItem, VBadge soft). */
function task({ ic, tone, title = 'Công việc cần xử lý', subtitle = 'Mô tả công việc chi tiết', badge = 'Chờ xử lý' }) {
  return `<button type="button" class="hm-card hm-task" aria-label="${esc(title)}">
    <span class="hm-task__icon hm-tone--${tone}">${icon(ic)}</span>
    <span class="hm-task__text"><b>${esc(title)}</b><small>${esc(subtitle)}</small></span>
    <span class="hm-badge hm-tone--${tone}">${esc(badge)}</span>
    <span class="hm-task__chevron">${icon('chevronRight')}</span>
  </button>`;
}

/** HomeTabPage: Column(DashboardHeader, Expanded(CustomScrollView)). */
export function homePage(v) {
  const banner = showLegalBanner(v) ? legalBanner() : '';
  return `<div class="hm-page">
    ${header(v)}
    <div class="hm-body" data-home-body>
      <div class="hm-list">
        ${banner}
        <button type="button" class="hm-ask">Hỏi Mosaic Retail</button>
        ${sectionHeader('Tổng quan hôm nay')}
        ${revenueCard()}
        <div class="hm-metrics">
          ${metric({ ic: 'receipt', tone: 'info', label: 'Đơn hôm nay' })}
          ${metric({ ic: 'wallet', tone: 'warning', label: 'Phải thu' })}
          ${metric({ ic: 'inventory', tone: 'danger', label: 'Sắp hết' })}
        </div>
        ${sectionHeader('Việc cần xử lý')}
        <div class="hm-tasks">
          ${task({ ic: 'handshake', tone: 'danger' })}
          ${task({ ic: 'inventory', tone: 'warning' })}
        </div>
      </div>
    </div>
  </div>`;
}

// ---------------------------------------------------------------- ca

/** Trạng thái ban đầu của một ca. */
export function caseView(screen, state, device) {
  const v = {
    device, width: DEVICE[device].w, location: '/', isOwner: true, isBlocked: false,
    orgName: ORG_NAME, branchName: ORG_NAME, greeting: greetingForHour(9),
    bannerDismissed: false, hasLegalProfile: false, scrollToEnd: false,
  };
  if (state === 'owner') v.hasLegalProfile = true;
  if (state === 'staff') v.isOwner = false;
  if (state === 'scrolled') v.scrollToEnd = true;
  if (state === 'loading-name') { v.branchName = 'Đang tải…'; }
  if (state === 'long-name') { v.orgName = LONG_ORG_NAME; v.branchName = LONG_ORG_NAME; }
  if (state === 'evening') v.greeting = greetingForHour(20);
  return v;
}

export function renderView(v) {
  return renderShell(v, homePage(v));
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
    const root = document.getElementById('root');
    const v = caseView(q.get('screen'), q.get('state'), device);
    const paint = () => {
      root.innerHTML = `<div class="sh-stage" data-device="${device}">${renderView(v)}</div>`;
      if (v.scrollToEnd) {
        const body = root.querySelector('[data-home-body]');
        body.scrollTop = body.scrollHeight;
      }
    };
    paint();
    root.addEventListener('click', (e) => {
      if (e.target.closest('[data-home-dismiss]')) { v.bannerDismissed = true; v.scrollToEnd = false; paint(); }
    });
  }
}
