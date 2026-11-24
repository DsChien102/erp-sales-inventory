// Trang chủ APP-01 — ĐỀ XUẤT "Bảng giá chợ" (người dùng chốt 2026-11-23, chưa có trong Flutter). Web (≥ 1024) và iPhone.
// Giữ màu, font Mosaic; chỉ đổi cách trình bày: doanh thu số rất lớn + cột 7 ngày đúng tỉ lệ (biểu đồ duy nhất);
// ba hộp số: Đơn hôm nay (số đơn ▲ | chưa xuất hoá đơn, dòng cách trả), Tiền đã thu hôm nay, Công nợ phải thu.
// Số lật lên một lần khi mở (tắt khi giảm chuyển động). Không có nút thao tác, không ô tìm, không chuông.
// Không có banner hồ sơ pháp lý theo yêu cầu người dùng — lệch TH-01 BR-14 / FR-01 (banner ở trang chủ), cần sửa tài liệu.
// Lối vào trợ lý AI (AI-01): nút nổi góc dưới phải (không còn ở đầu trang, người dùng chốt 2026-11-23) mở khung chat nổi
// ngay trên Trang chủ; chữ trong khung lấy nguyên văn từ prototype /ask. Nút ⤢ trong khung mở màn /ask đầy đủ.
// Dữ liệu là DỮ LIỆU MẪU (quầy thuốc thú y), chưa có RPC.
import { icon } from '../shared/icons.js';
import { GREETING, SUGGESTIONS, HINT, FOOTER } from '../../../assistant/html/app/ask.js';

const esc = (s) => String(s ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

export const SAMPLE = {
  date: 'Thứ Hai · 23/11',
  rows: [
    { key: 'rev', label: 'Doanh thu', value: '8.420.000', unit: '₫', delta: '18%', dir: 'up', note: 'so với hôm qua' },
  ],
  orders: {
    yesterday: 9,
    list: [ // giờ, giá trị (nghìn ₫), cách trả — tổng 8.420.000 ₫ (giờ chỉ để làm mẫu)
      ['07:20', 320, 'cash'], ['08:05', 95, 'cash'], ['08:40', 1250, 'bank'], ['09:32', 410, 'cash'],
      ['10:15', 180, 'cash'], ['10:50', 1480, 'bank'], ['11:30', 260, 'cash'], ['13:10', 125, 'cash'],
      ['13:45', 860, 'debt'], ['14:05', 540, 'bank'], ['14:40', 760, 'cash'], ['15:05', 2140, 'bank'],
    ],
  },
  pay: [ { key: 'cash', label: 'Tiền mặt' }, { key: 'bank', label: 'Chuyển khoản' }, { key: 'debt', label: 'Ghi nợ' } ],
  invoices: { pending: [1, 2] }, // 2 đơn hôm nay chưa xuất hoá đơn
  // Tiền đã thu hôm nay = thu lúc bán (7.560.000 = doanh thu − đơn ghi nợ 860.000) + khách trả nợ 2.000.000 (TH-06)
  cashIn: { total: '9.560.000', cash: '4.150.000', bank: '5.410.000', debtPaid: '2.000.000' },
  receivable: { total: '24.600.000', overdue: 3 },
  week: [
    { d: 'T2', v: 6.1 }, { d: 'T3', v: 7.4 }, { d: 'T4', v: 5.2 }, { d: 'T5', v: 8.9 },
    { d: 'T6', v: 7.1 }, { d: 'T7', v: 9.6 }, { d: 'Nay', v: 8.42 },
  ],
  weekTotal: '52,7 triệu',
};

const deltaHtml = (r) => {
  if (r.dir === 'alert') return `<span class="bz-delta is-alert">●&nbsp;${esc(r.delta)}</span>`;
  // rise: tăng nhưng không phải tin tốt (nợ tăng) → màu trung tính
  return `<span class="bz-delta is-${r.dir}">${r.dir === 'down' ? '▼' : '▲'}&nbsp;${esc(r.delta)}</span>`;
};

/** Một dòng bảng: nhãn hẹp in hoa | số lớn | ▲/▼. i = thứ tự để số lật lên lần lượt. */
const boardRow = (r, i) => `<div class="bz-row bz-row--${r.key}${r.changed ? ' is-changed' : ''}" style="--i:${i}">
    <span class="bz-row__label">${esc(r.label)}</span>
    <span class="bz-row__value"><span class="bz-flip">${esc(r.value)}</span><small>${esc(r.unit)}</small></span>
    <span class="bz-row__meta">${deltaHtml(r)}<small>${esc(r.note)}</small></span>
  </div>`;

function weekChart() {
  const max = Math.max(...SAMPLE.week.map((w) => w.v));
  return `<figure class="bz-week" aria-label="Doanh thu 7 ngày, tổng ${SAMPLE.weekTotal}">
    <figcaption><span>Doanh thu 7 ngày gần nhất (triệu ₫)</span><b>${SAMPLE.weekTotal}</b></figcaption>
    <div class="bz-week__bars">${SAMPLE.week.map((w, i) => {
      const today = i === SAMPLE.week.length - 1;
      return `<div class="bz-week__col${today ? ' is-today' : ''}" title="${w.d}: ${String(w.v).replace('.', ',')} triệu"><span class="bz-week__num">${String(w.v).replace('.', ',')}</span><span class="bz-week__bar" style="--h:${(w.v / max).toFixed(3)}"></span><span class="bz-week__day">${w.d}</span></div>`;
    }).join('')}</div>
  </figure>`;
}

/** Một hộp "Đơn hôm nay": số đơn (▲ so với hôm qua) | số đơn chưa xuất hoá đơn; dòng cách trả bên dưới. */
function ordersBox() {
  const { list, yesterday } = SAMPLE.orders;
  const pending = SAMPLE.invoices.pending.length;
  const counts = SAMPLE.pay.map((p) => `<span>${p.label} <b>${list.filter((o) => o[2] === p.key).length}</b></span>`).join('');
  return `<section class="bz-box" aria-label="Đơn hôm nay">
      <div class="bz-box__figs">
        <div class="bz-fig"><span class="bz-tile__label">Đơn hôm nay</span><span class="bz-tile__num"><span class="bz-flip" style="--i:1">${list.length}</span><span class="bz-delta is-up">▲ ${list.length - yesterday}</span></span></div>
        <div class="bz-fig bz-fig--warn"><span class="bz-tile__label">Chưa xuất hoá đơn</span><span class="bz-tile__num"><span class="bz-flip" style="--i:2">${pending}</span></span></div>
      </div>
      <div class="bz-legend">${counts}</div>
    </section>`;
}

/** Hộp một con số: nhãn, số lớn (+ đơn vị), một dòng ngắn bên dưới. */
const figBox = ({ label, value, unit, line, warn, i }) => `<section class="bz-box" aria-label="${esc(label)}">
      <div class="bz-fig${warn ? ' bz-fig--warn' : ''}"><span class="bz-tile__label">${esc(label)}</span><span class="bz-tile__num"><span class="bz-flip" style="--i:${i}">${value}</span>${unit ? `<small>${unit}</small>` : ''}</span></div>
      <div class="bz-legend">${line}</div>
    </section>`;

function cashBox() {
  const c = SAMPLE.cashIn;
  return figBox({ label: 'Tiền đã thu hôm nay', value: c.total, unit: '₫', i: 3, line: `<span>Tiền mặt <b>${c.cash}</b></span><span>Chuyển khoản <b>${c.bank}</b></span>` });
}
function debtBox() {
  const r = SAMPLE.receivable;
  return figBox({ label: 'Công nợ phải thu', value: r.total, unit: '₫', i: 4, line: `<span class="is-warn"><b>${r.overdue}</b> khoản quá hạn</span>` });
}

const svg = (d, cls = '') => `<svg class="${cls}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${d}</svg>`;
const CHAT = '<path d="M7.9 20A9 9 0 1 0 4 16.1L2 22Z"/>';
const EXPAND = '<path d="M15 3h6v6"/><path d="M9 21H3v-6"/><path d="m21 3-7 7"/><path d="m3 21 7-7"/>';

/** Khung chat nổi: đầu khung (tên + mở toàn màn + đóng), lời chào + 4 câu gợi ý, ô hỏi, câu nhắc. */
function chatPanel() {
  return `<section class="bz-chat" id="bz-chat" role="dialog" aria-label="Hỏi Mosaic Retail">
      <header class="bz-chat__head">
        <span class="bz-chat__badge">${svg(CHAT)}</span>
        <h2>Hỏi Mosaic Retail</h2>
        <button type="button" class="bz-chat__tool" data-ask-full aria-label="Mở toàn màn hình" title="Mở toàn màn hình">${svg(EXPAND)}</button>
        <button type="button" class="bz-chat__tool" data-ask-toggle aria-label="Đóng">${icon('close')}</button>
      </header>
      <div class="bz-chat__body">
        <p class="bz-chat__greet">${esc(GREETING)}</p>
        <div class="bz-chat__chips">${SUGGESTIONS.map((q) => `<button type="button" class="bz-chat__chip">${esc(q)}</button>`).join('')}</div>
      </div>
      <form class="bz-chat__composer" onsubmit="return false">
        <label class="bz-chat__input"><input type="text" placeholder="${esc(HINT)}" aria-label="Câu hỏi" /></label>
        <button type="submit" class="bz-chat__send" aria-label="Gửi">${icon('send')}</button>
      </form>
      <p class="bz-chat__foot">${esc(FOOTER)}</p>
    </section>`;
}

/** Nút nổi góc dưới phải; khi khung mở thì thành nút đóng (web) / ẩn dưới khung (iPhone). */
const askFab = (open) => `<button type="button" class="bz-fab" data-ask-toggle aria-controls="bz-chat" aria-expanded="${open}" aria-label="${open ? 'Đóng Hỏi Mosaic Retail' : 'Hỏi Mosaic Retail'}" title="Hỏi Mosaic Retail">${svg(CHAT, 'bz-fab__chat')}${icon('close', 'bz-fab__close')}</button>`;

export function boardPage(v, web) {
  const [rev] = SAMPLE.rows;
  const head = `<header class="bz-head">
      <div class="bz-head__left">
        <p class="bz-date">${esc(v.greeting)} · ${SAMPLE.date}</p>
        <button type="button" class="bz-org" data-home-branch aria-label="Đổi tổ chức, ${esc(v.branchName)}"><span>${esc(v.branchName)}</span>${icon('chevronDown')}</button>
      </div>
    </header>`;
  const hero = `<section class="bz-hero" aria-label="Doanh thu hôm nay">${boardRow(rev, 0)}${weekChart()}</section>`;
  // iPhone: Công nợ phải thu đứng ngay sau Đơn hôm nay (trong màn đầu), Tiền đã thu xuống cuối; web giữ thứ tự 3 cột.
  const secs = `<div class="bz-boxes">${ordersBox()}${web ? cashBox() + debtBox() : debtBox() + cashBox()}</div>`;
  return `<div class="hm-page bz${web ? ' is-web' : ''}${v.askOpen ? ' is-asking' : ''}">
    <div class="bz-scroll" data-home-body>
      ${web ? '' : head /* web: bỏ lời chào + tên tổ chức; đổi tổ chức ở nút đầu thanh bên */}
      ${hero}
      ${secs}
    </div>
    ${chatPanel()}
    ${askFab(!!v.askOpen)}
  </div>`;
}
