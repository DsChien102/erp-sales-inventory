// Prototype Trang chủ APP-01 (10-8). Không có ?screen= → trang xem (viewer.js); có → vẽ đúng một ca (URL chụp ảnh).
// Trang chủ là ĐỀ XUẤT "Bảng giá chợ" (app/board.js), người dùng chốt 2026-11-23 — thay bố cục Flutter hiện tại
// (home_tab_page.dart), chưa có trong Flutter. Khung (thanh biểu tượng web, thanh dưới iPhone) do shared/shell.js vẽ.
import { renderShell, DEVICE } from '../shared/shell.js';
import { boardPage } from './board.js';

export const ORG_NAME = 'Mosaic Retail Demo';
export const LONG_ORG_NAME = 'Cửa hàng Phân bón Hưng Phát — Chi nhánh Quốc lộ 1A, Long An';

/** HomeHeader._greetingForHour (giữ quy tắc lời chào theo giờ máy). */
export function greetingForHour(hour) {
  if (hour >= 5 && hour < 12) return 'Chào buổi sáng';
  if (hour >= 12 && hour < 18) return 'Chào buổi chiều';
  return 'Chào buổi tối';
}

/** Trạng thái ban đầu của một ca. */
export function caseView(screen, state, device) {
  const v = {
    device, width: DEVICE[device].w, location: '/', isOwner: true, isBlocked: false,
    orgName: ORG_NAME, branchName: ORG_NAME, greeting: greetingForHour(9),
  };
  if (state === 'staff') v.isOwner = false;
  if (state === 'loading-name') v.branchName = 'Đang tải…';
  if (state === 'long-name') { v.orgName = LONG_ORG_NAME; v.branchName = LONG_ORG_NAME; }
  if (state === 'evening') v.greeting = greetingForHour(20);
  if (state === 'ask-open') v.askOpen = true;
  return v;
}

export function renderView(v) {
  return renderShell(v, boardPage(v, (v.width ?? DEVICE[v.device].w) >= 1024));
}

export function render(screen, state, device) {
  return renderView(caseView(screen, state, device));
}

// ---------------------------------------------------------------- chạy trong trình duyệt
if (typeof document !== 'undefined') {
  const q = new URLSearchParams(location.search);
  const root = document.getElementById('root');
  if (!q.get('screen')) {
    import('./viewer.js').then((m) => m.mountViewer(root));
  } else {
    const device = q.get('device') === 'web' ? 'web' : 'iphone';
    root.innerHTML = `<div class="sh-stage" data-device="${device}">${render(q.get('screen'), q.get('state'), device)}</div>`;
    // Nút nổi / nút đóng: bật tắt khung chat; ⤢ mở màn /ask đầy đủ (prototype AI-01).
    root.addEventListener('click', (e) => {
      if (e.target.closest('[data-ask-full]')) { location.href = '../../assistant/html/index.html'; return; }
      if (!e.target.closest('[data-ask-toggle]')) return;
      const page = root.querySelector('.bz');
      const open = page.classList.toggle('is-asking');
      const fab = root.querySelector('.bz-fab');
      fab.setAttribute('aria-expanded', String(open));
      fab.setAttribute('aria-label', open ? 'Đóng Hỏi Mosaic Retail' : 'Hỏi Mosaic Retail');
      (open ? root.querySelector('.bz-chat input') : fab).focus();
    });
    root.addEventListener('keydown', (e) => {
      const page = root.querySelector('.bz.is-asking');
      if (e.key === 'Escape' && page) root.querySelector('.bz-fab').click();
    });
  }
}
