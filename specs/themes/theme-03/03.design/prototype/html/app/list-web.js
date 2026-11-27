// PT-01 Danh sách KH & NCC — bố cục web ≥ 1024 "Bảng toàn trang" (người dùng chọn qua /impeccable live, 2026-11-27).
// Thay danh sách 360 + cột trống của PartnerAreaShell khi chưa mở hồ sơ. iPhone / cửa sổ hẹp giữ list.js.
// Đầu trang: tiêu đề + tổng + nút chính "Thêm KH & NCC" (thay nút + nổi). Một hàng công cụ: ô tìm, lọc nhanh dạng nút chia đoạn,
// "Bộ lọc" (mở hộp thoại PT-02), sắp xếp. Hàng "N kết quả phù hợp" + chip lọc đang áp + "Xóa lọc" (FR-03, PT01-E04).
// Bảng 6 cột; bấm dòng → hồ sơ. Màu / chữ / token Mosaic (DESIGN.md). CSS: styles/list-web.css (tiền tố wp-).
import { icon } from '../shared/icons.js';
import { button, emptyDesc, emptyMedia, emptyState, emptyTitle, esc, gap, initials } from './ds.js';
import { PARTNERS } from './data.js';
import { SORT_CHOICES, emptyKind, filterCount, roleLabel } from './list.js';

// Dòng mẫu thêm cho ca có dữ liệu (không phải dữ liệu thật) để bảng đủ dài ở khổ 1280 × 800.
const EXTRA = [
  { id: 'x1', name: 'Phòng khám Thú y Bình An', type: 'organization', status: 'active', roles: ['customer'], phone: '0292 381 2299', taxCode: '1801998877', updated: '26/10/2026' },
  { id: 'x2', name: 'Võ Minh Khoa', type: 'person', status: 'active', roles: ['customer'], phone: '0939 456 120', taxCode: '', updated: '24/10/2026' },
  { id: 'x3', name: 'Công ty TNHH Thức ăn chăn nuôi Mekong', type: 'organization', status: 'active', roles: ['supplier'], phone: '0270 382 5566', taxCode: '1500556677', updated: '22/10/2026' },
  { id: 'x4', name: 'Huỳnh Ngọc Ánh', type: 'person', status: 'inactive', roles: ['customer'], phone: '0976 221 004', taxCode: '', updated: '19/10/2026' },
  { id: 'x5', name: 'Cửa hàng Pet Shop Ninh Kiều', type: 'organization', status: 'active', roles: ['customer'], phone: '0292 373 6600', taxCode: '1801445566', updated: '17/10/2026' },
];
const typeLabel = (p) => (p.type === 'person' ? 'Cá nhân' : 'Tổ chức');
const ROLE_SEG = [[null, 'Tất cả'], ['customer', 'Khách hàng'], ['supplier', 'Nhà cung cấp'], ['both', 'KH & NCC']];
const LABELS = {
  role: { customer: 'Khách hàng', supplier: 'Nhà cung cấp', both: 'KH & NCC' },
  type: { person: 'Cá nhân', organization: 'Tổ chức' },
  status: { active: 'Đang hoạt động', inactive: 'Ngừng hoạt động' },
  updated: { 7: '7 ngày gần đây', 30: '30 ngày gần đây' },
};
const HEAD = '<tr><th>Tên đối tác</th><th>Vai trò</th><th>Số điện thoại</th><th>Mã số thuế</th><th>Cập nhật</th><th>Trạng thái</th></tr>';

// ---------------------------------------------------------------- mảnh

const av = (name) => `<span class="wp-av" aria-hidden="true">${esc(initials(name))}</span>`;
const status = (p) => (p.status === 'active'
  ? '<span class="wp-status wp-status--on"><i></i>Đang hoạt động</span>'
  : '<span class="wp-status wp-status--off"><i></i>Ngừng hoạt động</span>');
const btn = (label, { variant = 'secondary', ic = '', trail = '', cls = '', extra = '' } = {}) => `<button type="button" class="wp-btn wp-btn--${variant} ${cls}">${ic ? icon(ic) : ''}<span>${esc(label)}</span>${extra}${trail ? icon(trail) : ''}</button>`;

function search(query) {
  const clear = query ? `<button type="button" class="wp-search__clear" aria-label="Xóa từ khóa">${icon('close')}</button>` : '<kbd>/</kbd>';
  return `<label class="wp-search">${icon('search')}<input type="search" value="${esc(query || '')}" placeholder="Tìm tên, SĐT, email, MST..." aria-label="Tìm KH & NCC">${clear}</label>`;
}
const seg = (role) => `<div class="wp-seg" role="radiogroup" aria-label="Lọc nhanh vai trò">${ROLE_SEG.map(([v, l]) => `<button type="button" role="radio" aria-checked="${v === role}">${esc(l)}</button>`).join('')}</div>`;

function filterBtn(f) {
  const n = filterCount(f);
  return btn('Bộ lọc', { ic: 'tune', cls: n ? 'is-active' : '', extra: n ? `<b class="wp-btn__count" aria-label="${n} bộ lọc đang áp">${n}</b>` : '' });
}

/** Hàng kết quả: có từ khoá / lọc → "N kết quả phù hợp"; có lọc → chip đang áp (×) + "Xóa lọc". */
function activeRow(f, total) {
  const chips = ['role', 'type', 'status', 'updated'].filter((k) => f[k]).map((k) => LABELS[k][f[k]]);
  if (!chips.length && f.query == null) return '';
  const chip = (l) => `<span class="wp-achip">${esc(l)}<button type="button" aria-label="Bỏ lọc ${esc(l)}">${icon('close')}</button></span>`;
  return `<div class="wp-active"><b>${total} kết quả phù hợp</b>${chips.map(chip).join('')}${chips.length ? '<button type="button" class="wp-clear">Xóa lọc</button>' : ''}</div>`;
}

function row(p) {
  const dash = '<span class="wp-dash">—</span>';
  return `<tr tabindex="0"${p.status !== 'active' ? ' data-off' : ''}>
    <td><span class="wp-name">${av(p.name)}<span><b>${esc(p.name)}</b><small>${esc(typeLabel(p))}</small></span></span></td>
    <td>${esc(roleLabel(p.roles))}</td>
    <td class="wp-mono">${p.phone ? esc(p.phone) : dash}</td>
    <td class="wp-mono">${p.taxCode ? esc(p.taxCode) : dash}</td>
    <td class="wp-mono wp-muted">${esc(p.updated)}</td>
    <td>${status(p)}</td></tr>`;
}
const skelRow = () => `<tr class="wp-skelrow" aria-hidden="true">${[46, 24, 30, 32, 26, 40].map((w, i) => `<td>${i === 0 ? '<span class="wp-skel wp-skel--av"></span>' : ''}<span class="wp-skel" style="width:${w}%"></span></td>`).join('')}</tr>`;

const tableCard = (rows, foot, { scrollEnd = false } = {}) => `<section class="wp-card wp-card--table" aria-label="Danh sách đối tác">
  <table class="wp-table"${scrollEnd ? ' data-scroll-end' : ''}><thead>${HEAD}</thead><tbody>${rows}</tbody></table>
  <div class="wp-tfoot">${foot}</div></section>`;
const stateCard = (inner) => `<section class="wp-card wp-card--state">${inner}</section>`;

function body(v) {
  const { kind, f } = v;
  if (kind === 'loading') return tableCard(Array.from({ length: 10 }, skelRow).join(''), '<span class="wp-muted">Đang tải…</span>');
  if (kind === 'error') {
    return stateCard(emptyState({
      tone: 'danger',
      header: [emptyMedia('cloudOff'), emptyTitle('Không tải được danh sách'), emptyDesc('Vui lòng kiểm tra kết nối internet\nhoặc thử lại sau.')],
      content: `${gap(24)}${button('Thử lại', { variant: 'secondary' })}`,
    }));
  }
  if (kind === 'empty' || kind === 'no-result') {
    const ek = kind === 'empty' ? emptyKind(f) : 'no-result';
    const head = ek === 'no-result'
      ? [emptyMedia('search'), emptyTitle('Không tìm thấy kết quả'), gap(8), emptyDesc(`Thử kiểm tra lại từ khóa "${f.query}"\nhoặc bộ lọc.`)]
      : [emptyMedia('users'), emptyTitle('Chưa có KH & NCC'), gap(8), emptyDesc('Thêm đối tác để bắt đầu bán hàng,\nnhập hàng và quản lý công nợ.')];
    const act = ek === 'no-result' ? `${gap(8)}${button('Xóa từ khóa', { variant: 'tertiary' })}`
      : v.canCreate ? `${gap(8)}${button('Thêm KH & NCC', { variant: 'tertiary' })}` : '';
    return stateCard(emptyState({ bg: 'surface', header: head, content: act }));
  }
  const items = v.items === PARTNERS ? [...PARTNERS, ...EXTRA] : v.items;
  const rows = items.map(row).join('') + (kind === 'more' ? Array.from({ length: 2 }, skelRow).join('') : '');
  const foot = v.reachedMax ? '<span class="wp-muted wp-tfoot__end">Đã ở cuối danh sách</span>'
    : `<span>Đang hiện ${items.length} / ${v.total} đối tác</span><span class="wp-muted">${kind === 'more' ? 'Đang tải thêm…' : 'Cuộn xuống để tải thêm'}</span>`;
  return tableCard(rows, foot, { scrollEnd: v.scrollEnd });
}

/** Trang danh sách web: v = listState(…) (list.js). */
/** "Sắp xếp" — menu thả xuống dưới nút sắp xếp (thay hộp "Sắp xếp danh sách" + "Áp dụng"; chọn là áp). */
function sortMenu(selected) {
  return `<div class="wd-menu wp-sortmenu" role="menu" aria-label="Sắp xếp danh sách">${SORT_CHOICES.map((c) => `<button type="button" role="menuitemradio" aria-checked="${c === selected}" class="wd-mi wp-sortmi"><span class="wd-mi__ic">${c === selected ? icon('check') : ''}</span><span class="wd-mi__t"><b>${esc(c)}</b></span></button>`).join('')}</div>`;
}

export function listPageWeb(v, { sortOpen = false } = {}) {
  const total = v.kind === 'loading' ? 0 : v.total;
  const add = v.canCreate ? btn('Thêm KH & NCC', { variant: 'primary', ic: 'plus' }) : '';
  return `<div class="wp t3-page">
    <header class="wp-head"><div><h1>KH &amp; NCC</h1><p>${total} đối tác</p></div>${add}</header>
    <div class="wp-wrap">
      <div class="wp-toolbar">${search(v.f.query)}${seg(v.f.role)}<span class="wp-grow"></span>${filterBtn(v.f)}<span class="wd-menuwrap">${btn(SORT_CHOICES[0], { ic: 'swapVert', trail: sortOpen ? 'chevronUp' : 'chevronDown', cls: `wp-btn--sort${sortOpen ? ' is-open' : ''}` })}${sortOpen ? sortMenu(SORT_CHOICES[0]) : ''}</span></div>
      ${activeRow(v.f, v.total)}
      ${body(v)}
    </div>
  </div>`;
}

// ---------------------------------------------------------------- PT-02 Bộ lọc (hộp thoại web) — chip có dấu ✓ (chọn qua /impeccable live, 2026-11-27)
// Hộp 520 (thay 480); mỗi nhóm có "Tất cả" (FR-02; "Vai trò giao dịch" thêm "Tất cả" cho đồng bộ); chip chọn có ✓;
// "Tùy chọn" mở ô Từ ngày – Đến ngày ngay trong hộp; đầu hộp "N đang chọn"; chân cố định "Đặt lại" | "Áp dụng". iPhone giữ filterSheet (list.js).
const FILTER_GROUPS = [
  ['role', 'Vai trò giao dịch', [[null, 'Tất cả'], ['customer', 'Khách hàng'], ['supplier', 'Nhà cung cấp'], ['both', 'KH & NCC']]],
  ['type', 'Loại hồ sơ', [[null, 'Tất cả'], ['person', 'Cá nhân'], ['organization', 'Tổ chức']]],
  ['status', 'Trạng thái', [[null, 'Tất cả'], ['active', 'Đang hoạt động'], ['inactive', 'Ngừng hoạt động']]],
  ['updated', 'Thời gian cập nhật', [[null, 'Tất cả'], [7, '7 ngày gần đây'], [30, '30 ngày gần đây'], ['custom', 'Tùy chọn']]],
];

/** sel: {role, type, status, updated} (updated: 7 | 30 | 'custom' | null). */
export function filterDialogWeb(sel = {}) {
  const n = FILTER_GROUPS.filter(([k]) => sel[k] != null).length;
  const chip = (on, l, ic) => `<button type="button" class="wpf-chip" aria-pressed="${on}">${on ? icon('check') : ic ? icon(ic) : ''}<span>${esc(l)}</span></button>`;
  const range = sel.updated === 'custom'
    ? '<div class="wpf-range"><label><span>Từ ngày</span><input type="text" placeholder="dd/mm/yyyy"></label><span class="wpf-range__dash">–</span><label><span>Đến ngày</span><input type="text" placeholder="dd/mm/yyyy"></label></div>' : '';
  return `<div class="wpf">
    <header class="wpf-head"><h2>Bộ lọc KH &amp; NCC</h2>${n ? `<span class="wpf-badge">${n} đang chọn</span>` : ''}</header>
    ${FILTER_GROUPS.map(([k, label, opts]) => `<section class="wpf-s"><h3>${esc(label)}</h3><div class="wpf-chips">${opts.map(([v, l]) => chip((sel[k] ?? null) === v, l, v === 'custom' ? 'calendar' : '')).join('')}</div>${k === 'updated' ? range : ''}</section>`).join('')}
    <footer class="wpf-foot"><button type="button" class="wpf-reset">Đặt lại</button><span class="wpf-grow"></span><button type="button" class="wp-btn wp-btn--primary">Áp dụng</button></footer>
  </div>`;
}

// ---------------------------------------------------------------- PT-03 "Thêm KH & NCC mới" (hộp thoại web) — chọn rồi "Tiếp tục" (chọn qua /impeccable live, 2026-11-27)
// Hộp 520: hai thẻ chọn (radio, mặc định "Tạo cá nhân"), chân "Hủy" | "Tiếp tục" → PT-05 đúng loại.
// Lệch: thêm một lần bấm so với bản bấm thẻ đi luôn. iPhone giữ createTypeSheet (list.js).
const CREATE_TYPES = [
  ['user', 'Tạo cá nhân', 'Dành cho khách hàng hoặc cá nhân không có pháp nhân'],
  ['building', 'Tạo tổ chức', 'Dành cho công ty, cửa hàng, đại lý, đơn vị kinh doanh'],
];
export function createTypeDialogWeb(selected = 0) {
  const opt = ([ic, t, d], i) => `<button type="button" role="radio" aria-checked="${i === selected}" class="wpc-radio"><span class="wpc-dot"></span><span class="wpc-text"><b>${esc(t)}</b><span>${esc(d)}</span></span><span class="wpc-ic">${icon(ic)}</span></button>`;
  return `<div class="sh-scrim sh-scrim--dialog"><section class="t3-dialog wpc" role="dialog" aria-modal="true" aria-label="Thêm KH &amp; NCC mới">
    <header class="wpc-head"><h2>Thêm KH &amp; NCC mới</h2><button type="button" class="wpc-x" aria-label="Đóng">${icon('close')}</button></header>
    <div class="wpc-radios" role="radiogroup" aria-label="Loại hồ sơ">${CREATE_TYPES.map(opt).join('')}</div>
    <footer class="wpc-foot">${btn('Hủy')}${btn('Tiếp tục', { variant: 'primary' })}</footer>
  </section></div>`;
}

/** L-07 Không có quyền xem (web): đầu trang "KH & NCC" kiểu mới (không nút thêm) + ổ khoá giữa vùng còn lại. */
export function noPermissionPageWeb() {
  return `<div class="wp t3-page"><header class="wp-head"><div><h1>KH &amp; NCC</h1></div></header>
    ${emptyState({ header: [emptyMedia('lock'), emptyTitle('Bạn không có quyền xem\nKH & NCC'), emptyDesc('Liên hệ quản trị viên để được cấp quyền.')] })}</div>`;
}
