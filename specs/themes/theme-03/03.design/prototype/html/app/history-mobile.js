// PT-12 Lịch sử thao tác — bố cục iPhone "Dòng thời gian" (người dùng chọn qua /impeccable live, 2026-11-27), cùng hướng bản web.
// Đầu trang: nút ‹ 44 + "Lịch sử thao tác" + tên đối tác. Nhóm theo tháng (tiêu đề dính); đường kẻ dọc + chấm icon theo loại
// (ngừng hoạt động / xoá tô vàng, cập nhật xám); mỗi mục một thẻ: tiêu đề | "dd/MM · HH:mm"; thay đổi: nhãn nhỏ, cũ (gạch) → mới (đậm),
// "Thêm mới" / "Đã xóa" là nhãn nhỏ; "Lý do: …" nghiêng; "bởi 3f9a2c1b". Chữ lấy đúng history.js. CSS: styles/history-mobile.css (tiền tố mh-).
import { icon } from '../shared/icons.js';
import { button, centerLoading, emptyDesc, emptyMedia, emptyState, emptyTitle, esc, gap } from './ds.js';
import { ENTRIES, actorDisplay, summaryFor } from './history.js';

const TYPE_IC = { create: 'plusCircle', update: 'edit', addContact: 'userPlus', removeContact: 'userX', transform: 'building', deactivate: 'pause', reactivate: 'power', delete: 'trash' };
const month = (at) => { const [y, m] = at.split('-'); return `Tháng ${Number(m)}/${y}`; };
/** "2026-11-21 16:40" → "21/11 · 16:40" (năm đã có ở tiêu đề tháng). */
const shortAt = (at) => { const [d, t] = at.split(' '); const [, m, dd] = d.split('-'); return `${dd}/${m} · ${t}`; };

function change(c) {
  const v = c.kind === 'added' ? `<span class="mh-after">${esc(c.after)}</span><em>Thêm mới</em>`
    : c.kind === 'removed' ? `<span class="mh-before">${esc(c.before)}</span><em>Đã xóa</em>`
      : `<span class="mh-before">${esc(c.before)}</span>${icon('arrowRight')}<span class="mh-after">${esc(c.after)}</span>`;
  return `<li><span class="mh-lbl">${esc(c.label)}</span><span class="mh-v">${v}</span></li>`;
}

const entry = (e) => `<li class="mh-ev mh-ev--${e.type}"><span class="mh-dot" aria-hidden="true">${icon(TYPE_IC[e.type])}</span><div class="mh-card">
  <div class="mh-h"><b>${esc(summaryFor(e.type, e.changes))}</b><time class="mh-mono" datetime="${esc(e.at)}">${esc(shortAt(e.at))}</time></div>
  ${e.changes.length ? `<ul class="mh-ch">${e.changes.map(change).join('')}</ul>` : ''}
  ${e.reason ? `<p class="mh-reason">Lý do: ${esc(e.reason)}</p>` : ''}
  <span class="mh-by">${icon('user')}bởi <span class="mh-mono">${esc(actorDisplay(e.actor))}</span></span></div></li>`;

function timeline(list) {
  const groups = [];
  for (const e of list) {
    const m = month(e.at);
    if (!groups.length || groups[groups.length - 1][0] !== m) groups.push([m, []]);
    groups[groups.length - 1][1].push(e);
  }
  return `<div class="mh-scroll">${groups.map(([m, items]) => `<h2 class="mh-month">${esc(m)}</h2><ol class="mh-tl">${items.map(entry).join('')}</ol>`).join('')}</div>`;
}

export function historyPageMobile(kind) {
  const head = `<header class="mh-bar"><button type="button" class="mh-back" aria-label="Quay lại">${icon('chevronLeft')}</button><div><h1>Lịch sử thao tác</h1><p>Công ty TNHH Thú y An Phát</p></div></header>`;
  let body;
  if (kind === 'loading') body = centerLoading({ material: true });
  else if (kind === 'error') body = emptyState({ tone: 'danger', header: [emptyMedia('alert'), emptyTitle('Không thể tải lịch sử thao tác'), emptyDesc('Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.')], content: `${gap(32)}${button('Thử lại')}` });
  else if (kind === 'empty') body = emptyState({ header: [emptyMedia('history'), emptyTitle('Chưa có lịch sử thao tác nào'), emptyDesc('Các thay đổi của KH & NCC sẽ xuất hiện tại đây.')] });
  else body = timeline(ENTRIES);
  return `<div class="t3-page mh">${head}${body}</div>`;
}
