// PT-12 Lịch sử thao tác — bố cục web ≥ 1024 "Dòng thời gian" (người dùng chọn qua /impeccable live, 2026-11-27).
// Đầu trang: "‹ Hồ sơ KH & NCC" + "Lịch sử thao tác" + tên đối tác. Thân cột 760: nhóm theo tháng ("Tháng 11/2026"), mỗi mục một chấm
// biểu tượng theo loại (ngừng hoạt động tô vàng) + thẻ: tiêu đề | ngày giờ; thay đổi "Nhãn  cũ (gạch) → mới (đậm)", "Thêm mới" / "Đã xóa"
// là nhãn nhỏ; "Lý do: …"; "bởi 3f9a2c1b". Chữ lấy đúng history.js. iPhone giữ historyPage. CSS: styles/detail-web.css (tiền tố wh-).
import { icon } from '../shared/icons.js';
import { button, centerLoading, emptyDesc, emptyMedia, emptyState, emptyTitle, esc, gap } from './ds.js';
import { ENTRIES, actorDisplay, summaryFor } from './history.js';

const TYPE_IC = { create: 'plusCircle', update: 'edit', addContact: 'userPlus', removeContact: 'userX', transform: 'building', deactivate: 'pause', reactivate: 'power', delete: 'trash' };
const month = (at) => { const [y, m] = at.split('-'); return `Tháng ${Number(m)}/${y}`; };

function change(c) {
  const v = c.kind === 'added' ? `<span class="wh-after">${esc(c.after)}</span><em>Thêm mới</em>`
    : c.kind === 'removed' ? `<span class="wh-before">${esc(c.before)}</span><em>Đã xóa</em>`
      : `<span class="wh-before">${esc(c.before)}</span>${icon('arrowRight')}<span class="wh-after">${esc(c.after)}</span>`;
  return `<li><span class="wh-lbl">${esc(c.label)}</span>${v}</li>`;
}

const entry = (e) => `<li class="wh-ev wh-ev--${e.type}"><span class="wh-dot">${icon(TYPE_IC[e.type])}</span><div class="wh-ev__b">
  <div class="wh-ev__h"><b>${esc(summaryFor(e.type, e.changes))}</b><time class="wh-mono">${esc(e.at)}</time></div>
  ${e.changes.length ? `<ul class="wh-ch">${e.changes.map(change).join('')}</ul>` : ''}
  ${e.reason ? `<p class="wh-reason">Lý do: ${esc(e.reason)}</p>` : ''}
  <span class="wh-by">${icon('user')}bởi <span class="wh-mono">${esc(actorDisplay(e.actor))}</span></span></div></li>`;

function timeline(list) {
  const groups = [];
  for (const e of list) {
    const m = month(e.at);
    if (!groups.length || groups[groups.length - 1][0] !== m) groups.push([m, []]);
    groups[groups.length - 1][1].push(e);
  }
  return groups.map(([m, es]) => `<h2 class="wh-month">${esc(m)}</h2><ol class="wh-tl">${es.map(entry).join('')}</ol>`).join('');
}

export function historyPageWeb(kind) {
  let body;
  if (kind === 'loading') body = centerLoading({ material: true });
  else if (kind === 'error') {
    body = emptyState({ tone: 'danger', header: [emptyMedia('alert'), emptyTitle('Không thể tải lịch sử thao tác'), emptyDesc('Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.')], content: `${gap(32)}${button('Thử lại')}` });
  } else if (kind === 'empty') {
    body = emptyState({ header: [emptyMedia('history'), emptyTitle('Chưa có lịch sử thao tác nào'), emptyDesc('Các thay đổi của KH & NCC sẽ xuất hiện tại đây.')] });
  } else body = `<div class="wh-scroll"><div class="wh-col">${timeline(ENTRIES)}</div></div>`;
  return `<div class="t3-page wh"><header class="wh-head"><nav class="wh-crumb"><button type="button">${icon('chevronLeft')}Hồ sơ KH &amp; NCC</button></nav><h1>Lịch sử thao tác</h1><p>Công ty TNHH Thú y An Phát</p></header>${body}</div>`;
}
