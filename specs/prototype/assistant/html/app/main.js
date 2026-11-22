// Prototype Tích hợp AI — 10-8. Không có ?screen= → trang xem (viewer.js); có → vẽ đúng một ca (URL chụp ảnh).
// Vẽ y nguyên Flutter hiện tại (không thiết kế lại) để người dùng rà bằng impeccable. Nguồn Dart ghi ở đầu app/ask.js.
// Khung: /ask là GoRoute cấp gốc (app_router.dart), NGOÀI ShellRoute(StoreShell) → không thanh bên / thanh dưới; shared/shell.js insideShell('/ask') = false.
import { DEVICE, renderShell } from '../shared/shell.js';
import { SCREENS } from './cases.js';
import { askPage } from './ask.js';
import { Q, R } from './data.js';

const user = (text) => ({ kind: 'user', text });
const ai = (reply) => ({ kind: 'assistant', reply });
const err = (offline = false) => ({ kind: 'error', offline });

const LONG_Q = 'Cho mình xem doanh thu từng ngày trong tuần này so với tuần trước, ngày nào giảm mạnh nhất và mặt hàng nào kéo doanh thu xuống nhiều nhất?';

/** Ca → { messages, waiting, slow, draft, focused }. */
function caseState(screen, state) {
  const s = { messages: [], waiting: false, slow: false, draft: '', focused: false };
  const set = (messages, extra = {}) => Object.assign(s, { messages }, extra);
  switch (`${screen}/${state}`) {
    case 'start/typing': return Object.assign(s, { draft: 'Tuần này bán được bao nhiêu đơn', focused: true });
    case 'start/waiting': return set([user(Q.forecast)], { waiting: true });
    case 'start/waiting-slow': return set([user(Q.forecast)], { waiting: true, slow: true });
    case 'start/long-question': return set([user(LONG_Q)], { waiting: true });
    case 'answer/revenue': return set([user(Q.revenue), ai(R.revenue)]);
    case 'answer/forecast': return set([user(Q.forecast), ai(R.forecast)]);
    case 'answer/top5': return set([user(Q.top5), ai(R.top5)]);
    case 'answer/orders': return set([user('Mấy đơn gần nhất là đơn nào?'), ai(R.orders)]);
    case 'answer/stock-mixed': return set([user('Còn bao nhiêu sữa?'), ai(R.stock)]);
    case 'answer/two-tables': return set([user('Hàng bán chạy tháng này còn đủ bán không?'), ai(R.twoTables)]);
    case 'answer/empty-table': return set([user(Q.forecast), ai(R.emptyTable)]);
    case 'answer/chat': return set([user(Q.revenue), ai(R.revenue), user('Cảm ơn nhé'), ai(R.chat)]);
    case 'answer/too-complex': return set([user('So sánh doanh thu, lãi gộp, tồn kho và công nợ của từng nhóm hàng theo từng tuần trong quý này'), ai(R.tooComplex)]);
    case 'answer/remaining-low': return set([user(Q.revenue), ai(R.revenueLow)]);
    case 'problem/out-of-scope': return set([user('Mai trời mưa không?'), ai(R.outOfScope)]);
    case 'problem/unsupported': return set([user(Q.debt), ai(R.unsupported)]);
    case 'problem/refuse': return set([user('Xoá đơn DH-000129 giúp tôi'), ai(R.refuse)]);
    case 'problem/no-permission': return set([user('Lãi gộp tháng này?'), ai(R.noPermission)]);
    case 'problem/busy': return set([user(Q.revenue), ai(R.busy)]);
    case 'problem/slow': return set([user(Q.forecast), ai(R.slow)]);
    case 'problem/error': return set([user(Q.revenue), err(false)]);
    case 'problem/offline': return set([user(Q.revenue), err(true)]);
    case 'problem/error-earlier': return set([user(Q.revenue), err(false), user(Q.top5), ai(R.top5)]);
    case 'problem/limit': return set([user(Q.revenue), ai(R.revenueLow), user(Q.top5), ai(R.limit)]);
    case 'problem/conversation': return set([
      user(Q.revenue), ai(R.revenue),
      user(Q.forecast), ai(R.forecast),
      user('Mai trời mưa không?'), ai(R.outOfScope),
      user('Còn bao nhiêu sữa?'), ai(R.stock),
    ]);
    default: return s;
  }
}

/** Trạng thái ban đầu của một ca. */
export function caseView(screen, state, device) {
  const scr = SCREENS.find((x) => x.id === screen) || SCREENS[0];
  const st = scr.states.some(([id]) => id === state) ? state : scr.states[0][0];
  const d = DEVICE[device] ? device : 'iphone';
  return { screen: scr.id, state: st, device: d, width: DEVICE[d].w, height: DEVICE[d].h, location: scr.route, ...caseState(scr.id, st) };
}

export function renderView(v) {
  return renderShell({ device: v.device, width: v.width, height: v.height, location: v.location, orgName: 'Mosaic Retail Demo' }, askPage(v));
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
    // ask_assistant_page: jumpTo(maxScrollExtent) sau mỗi tin / khi bắt đầu chờ.
    root.querySelectorAll('[data-scroll-end]').forEach((el) => { el.scrollTop = el.scrollHeight; });
    if (v.focused) root.querySelector('.ai-input input')?.focus();
  }
}
