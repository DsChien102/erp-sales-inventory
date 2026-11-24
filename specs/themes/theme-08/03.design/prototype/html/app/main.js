// Prototype Theme 8 (TH-08) — 10-8. Không có ?screen= → trang xem (viewer.js); có → vẽ đúng một ca (URL chụp ảnh).
// Vẽ y nguyên Flutter hiện tại (không thiết kế lại) để người dùng rà bằng impeccable. Nguồn Dart ghi ở đầu từng file màn.
// Khung: route /more/einvoice/* là GoRoute cấp gốc, nằm NGOÀI ShellRoute(StoreShell) → không thanh bên (web) / thanh dưới (iPhone);
// shared/shell.js insideShell('/more/einvoice…') = false. HD-03 là showVAdaptiveSheet (iPhone sheet đáy, web hộp thoại 480).
// Đợt 2: /sales/result/:id và /sales/orders/:id cũng cấp gốc; HD-07…12 đều showVAdaptiveSheet; HD-13 là MaterialPageRoute (route ghi trong cases chỉ để đặt tên).
import { DEVICE, renderShell } from '../shared/shell.js';
import { SCREENS } from './cases.js';
import { automationPage, connectionPage, disconnectSheet, issuancePage, overviewPage } from './setup.js';
import { detailPage, historyPage, resultPage, sheetCase } from './order.js';

/** Trạng thái ban đầu của một ca. */
export function caseView(screen, state, device) {
  const scr = SCREENS.find((s) => s.id === screen) || SCREENS[0];
  const st = scr.states.some(([id]) => id === state) ? state : scr.states[0][0];
  const d = DEVICE[device] ? device : 'iphone';
  return { screen: scr.id, state: st, device: d, width: DEVICE[d].w, height: DEVICE[d].h, location: scr.route };
}

export function renderView(v) {
  let page = '';
  let overlay = '';
  switch (v.screen) {
    case 'overview': page = overviewPage(v, v.state); break;
    case 'connection': page = connectionPage(v, v.state); break;
    case 'disconnect':
      page = connectionPage(v, v.state === 'from-error' ? 'error' : 'connected');
      overlay = disconnectSheet(v);
      break;
    case 'issuance': page = issuancePage(v, v.state); break;
    case 'automation': page = automationPage(v, v.state); break;
    case 'result': page = resultPage(v, v.state); break;
    case 'detail': page = detailPage(v, v.state); break;
    case 'history': page = historyPage(v, v.state); break;
    case 'pre-issue': case 'confirm': case 'post-issue': case 'documents': case 'send': case 'resend':
      ({ page, overlay } = sheetCase(v, v.screen, v.state));
      break;
    default: break;
  }
  return renderShell({ device: v.device, width: v.width, height: v.height, location: v.location, orgName: 'Mosaic Retail Demo', overlay }, page);
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
    const v = caseView(q.get('screen'), q.get('state'), q.get('device') === 'web' ? 'web' : 'iphone');
    const root = document.getElementById('root');
    root.innerHTML = `<div class="sh-stage" data-device="${v.device}">${renderView(v)}</div>`;
    // Màn Sales chủ: cuộn tới cuối như người dùng đã kéo xuống khối "Chứng từ & hóa đơn".
    root.querySelectorAll('[data-scroll-end]').forEach((el) => { el.scrollTop = el.scrollHeight; });
  }
}
