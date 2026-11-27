// PT-01 Danh sách KH & NCC — bố cục iPhone / cửa sổ hẹp (< 840 vùng nội dung) "Danh bạ gọn" (người dùng chọn qua /impeccable live, 2026-11-27).
// Thay danh sách thẻ rời của PartnerListPage khi không chia cột. Web (list-web.js) và cột 360 khi chia cột (list.js) giữ nguyên.
// Đầu trang trắng liền: tiêu đề + tổng, ô tìm + nút lọc, chip vai trò; một khối danh sách trắng chung, dòng phân cách mảnh lùi sau avatar.
// Mỗi dòng: avatar 36 | tên (1 dòng) + ngày cập nhật dd/mm bên phải | "Loại · Vai trò" (+ nhãn "Ngừng hoạt động" khi ngừng) | "SĐT · MST".
// Không gắn nhãn "Đang hoạt động" từng dòng (lệch PartnerListItemTile — ghi chú ca trong cases.js). CSS: styles/list-mobile.css (tiền tố mp-).
import { icon } from '../shared/icons.js';
import { button, emptyDesc, emptyMedia, emptyState, emptyTitle, esc, gap, initials } from './ds.js';
import { emptyKind, filterCount, headerLabel, itemSubtitle } from './list.js';

const ROLE_CHIPS = [[null, 'Tất cả'], ['customer', 'Khách hàng'], ['supplier', 'Nhà cung cấp'], ['both', 'KH & NCC']];

function head(v) {
  const total = v.kind === 'loading' ? 0 : v.total; // _lastTotal ?? 0 ở lần tải đầu
  const f = v.f;
  const n = filterCount(f);
  const clear = f.query ? `<button type="button" class="mp-search__clear" aria-label="Xóa tìm kiếm">${icon('close')}</button>` : '';
  const filter = `<button type="button" class="mp-filter${n ? ' is-active' : ''}" aria-label="Bộ lọc${n ? ` (${n} đang áp)` : ''}">${icon('tune')}${n ? `<b>${n}</b>` : ''}</button>`;
  const chips = ROLE_CHIPS.map(([val, l]) => `<button type="button" role="radio" aria-checked="${f.role === val}">${esc(l)}</button>`).join('');
  // Lỗi tải: ô tìm, nút lọc và chip mờ 40%, không bấm được (chưa có dữ liệu để lọc).
  return `<header class="mp-head${v.kind === 'error' ? ' is-disabled' : ''}">
    <div class="mp-title"><h1>KH &amp; NCC</h1><p>${total} đối tác</p></div>
    <div class="mp-tools"><label class="mp-search">${icon('search')}<input type="search" value="${esc(f.query || '')}" placeholder="Tìm tên, SĐT, email, MST..." aria-label="Tìm KH &amp; NCC">${clear}</label>${filter}</div>
    <div class="mp-chips" role="radiogroup" aria-label="Lọc nhanh vai trò">${chips}</div>
  </header>`;
}

/** Một dòng đối tác. Ngày cập nhật dd/mm (năm hiện tại); MST giữ nguyên chuỗi. */
function row(p) {
  const off = p.status !== 'active';
  const meta = [p.phone ? esc(p.phone) : '', p.taxCode ? `MST ${esc(p.taxCode)}` : ''].filter(Boolean).join(' · ');
  return `<li><button type="button" class="mp-row"${off ? ' data-off' : ''}>
    <span class="mp-av" aria-hidden="true">${esc(initials(p.name))}</span>
    <span class="mp-txt">
      <span class="mp-top"><b>${esc(p.name)}</b>${p.updated ? `<time aria-label="Cập nhật ${esc(p.updated)}">${esc(p.updated.slice(0, 5))}</time>` : ''}</span>
      <span class="mp-sub">${esc(itemSubtitle(p))}${off ? '<span class="mp-off">Ngừng hoạt động</span>' : ''}</span>
      ${meta ? `<span class="mp-meta">${meta}</span>` : ''}
    </span>
  </button></li>`;
}

const skelRow = () => `<li class="mp-skrow" aria-hidden="true"><span class="t3-skel" style="width:36px;height:36px;border-radius:999px"></span><span class="mp-sklines"><span class="t3-skel" style="height:14px;width:62%;border-radius:4px"></span><span class="t3-skel" style="height:12px;width:40%;border-radius:4px"></span><span class="t3-skel" style="height:12px;width:54%;border-radius:4px"></span></span></li>`;

const listHead = (v) => `<div class="mp-listhead"><span>${esc(headerLabel(v.f, v.total))}</span><button type="button">${icon('swapVert')}<span>Sắp xếp</span></button></div>`;

function body(v) {
  const { kind, f } = v;
  if (kind === 'loading') return `<div class="mp-scroll"><div class="mp-listhead"><span>${esc(headerLabel(f, 0))}</span></div><ul class="mp-group">${Array.from({ length: 8 }, skelRow).join('')}</ul></div>`;
  if (kind === 'error') {
    // Lỗi giữa màn (chọn qua /impeccable live 2026-11-27): ổ tròn 72 nền đỏ nhạt, tiêu đề chữ thường, nút chính "Thử lại" có icon tải lại.
    return `<div class="mp-error" role="alert"><span class="mp-error__media" aria-hidden="true">${icon('cloudOff')}</span><h2>Không tải được danh sách</h2><p>Vui lòng kiểm tra kết nối internet<br>hoặc thử lại sau.</p><button type="button" class="mp-error__btn">${icon('rotate')}<span>Thử lại</span></button></div>`;
  }
  if (kind === 'empty' || kind === 'no-result') {
    const ek = kind === 'empty' ? emptyKind(f) : 'no-result';
    const h = ek === 'no-result'
      ? [emptyMedia('search'), emptyTitle('Không tìm thấy kết quả'), gap(8), emptyDesc(`Thử kiểm tra lại từ khóa "${f.query}"\nhoặc bộ lọc.`)]
      : [emptyMedia('users'), emptyTitle('Chưa có KH & NCC'), gap(8), emptyDesc('Thêm đối tác để bắt đầu bán hàng,\nnhập hàng và quản lý công nợ.')];
    const act = ek === 'no-result' ? button('Xóa từ khóa', { variant: 'tertiary' }) : v.canCreate ? button('Thêm KH & NCC', { variant: 'tertiary' }) : '';
    return `<div class="mp-scroll">${listHead(v)}${emptyState({ bg: 'surface', fill: false, header: h, content: act ? `${gap(8)}${act}` : '', cls: 'mp-empty' })}</div>`;
  }
  const more = kind === 'more' ? Array.from({ length: 2 }, skelRow).join('') : '';
  const end = v.reachedMax ? '<p class="t3-endnote">Đã ở cuối danh sách</p>' : '';
  return `<div class="mp-scroll"${v.scrollEnd ? ' data-scroll-end' : ''}>${listHead(v)}<ul class="mp-group">${v.items.map(row).join('')}${more}</ul>${end}</div>`;
}

/** PartnerListPage khổ iPhone. FAB "Thêm KH & NCC" khi có quyền tạo. */
export function listPageMobile(v) {
  const fabHtml = v.canCreate ? `<button type="button" class="mp-fab" aria-label="Thêm KH &amp; NCC">${icon('plus')}</button>` : '';
  return `<div class="t3-page mp-page">${head(v)}${body(v)}${fabHtml}</div>`;
}

/**
 * PartnerNoPermissionView khổ iPhone (người dùng chọn qua /impeccable live, 2026-11-27): nền trắng, ổ khoá tròn 72 + tiêu đề + mô tả căn giữa,
 * thêm nút secondary "Về Trang chủ" để không thành ngõ cụt (lệch đặc tả — ghi chú ca trong cases.js).
 */
export const noPermissionPageMobile = () => `<div class="t3-page mp-page mp-page--white">
  <header class="t3-appbar"><div class="t3-appbar__titles"><h1 class="t3-appbar__title">KH &amp; NCC</h1></div></header>
  <div class="mp-noperm" role="status"><span class="mp-noperm__media" aria-hidden="true">${icon('lock')}</span><h2>Bạn không có quyền xem<br>KH &amp; NCC</h2><p>Liên hệ quản trị viên để được cấp quyền.</p>
    <button type="button" class="mp-noperm__btn">${icon('home')}<span>Về Trang chủ</span></button></div>
</div>`;

/**
 * PT-02 Bộ lọc khổ iPhone (chọn qua /impeccable live 2026-11-27): đầu sheet "Bộ lọc KH & NCC" (18/700) + "Đặt lại" (tertiary) bên phải;
 * 4 nhóm cách bằng đường kẻ mảnh; mỗi nhóm có chip "Tất cả" (lệch đặc tả, giống web); chip chọn có ✓; chip thời gian tự xuống dòng
 * (không cắt chữ), "Tùy chọn" viền nét đứt; chân sheet một nút "Áp dụng". sel: {role, type, status, updated}.
 */
export function filterSheetMobile(sel) {
  const chip = (on, label) => `<button type="button" role="radio" aria-checked="${on}">${on ? icon('check') : ''}<span>${esc(label)}</span></button>`;
  const group = (title, opts, key, extra = '') => `<fieldset class="mf-group"><legend>${esc(title)}</legend><div class="mf-chips" role="radiogroup" aria-label="${esc(title)}">${opts.map(([val, l]) => chip((sel[key] ?? null) === val, l)).join('')}${extra}</div></fieldset>`;
  const custom = `<button type="button" class="mf-custom">${icon('calendar')}<span>Tùy chọn</span></button>`;
  return `<div class="mf">
    <header class="mf-head"><h2>Bộ lọc KH &amp; NCC</h2><button type="button" class="mf-reset">Đặt lại</button></header>
    <div class="mf-body">
      ${group('Vai trò giao dịch', [[null, 'Tất cả'], ['customer', 'Khách hàng'], ['supplier', 'Nhà cung cấp'], ['both', 'KH & NCC']], 'role')}
      ${group('Loại hồ sơ', [[null, 'Tất cả'], ['person', 'Cá nhân'], ['organization', 'Tổ chức']], 'type')}
      ${group('Trạng thái', [[null, 'Tất cả'], ['active', 'Đang hoạt động'], ['inactive', 'Ngừng hoạt động']], 'status')}
      ${group('Thời gian cập nhật', [[null, 'Tất cả'], [7, '7 ngày gần đây'], [30, '30 ngày gần đây']], 'updated', custom)}
    </div>
    <footer class="mf-foot">${button('Áp dụng', { full: true })}</footer>
  </div>`;
}

/**
 * PT-03 "Thêm KH & NCC mới" khổ iPhone (chọn qua /impeccable live 2026-11-27): đầu sheet tiêu đề 18/700 + nút Đóng (X) 44, không đường kẻ;
 * hai lựa chọn chung một khối trắng (viền 12, kẻ mảnh giữa), mỗi dòng: ô icon 40 nền brand | tên + mô tả | chevron.
 * Mở bằng adaptiveSheet không tiêu đề (tiêu đề nằm trong thân), label "Thêm KH & NCC mới".
 */
export function createTypeSheetMobile() {
  const opt = (ic, title, desc) => `<li><button type="button" class="mc-row"><span class="mc-ib" aria-hidden="true">${icon(ic)}</span><span class="mc-txt"><b>${esc(title)}</b><span>${esc(desc)}</span></span><i class="mc-chev" aria-hidden="true">${icon('chevronRight')}</i></button></li>`;
  return `<div class="mc">
    <header class="mc-head"><h2>Thêm KH &amp; NCC mới</h2><button type="button" class="mc-x" aria-label="Đóng">${icon('close')}</button></header>
    <ul class="mc-group">${opt('user', 'Tạo cá nhân', 'Dành cho khách hàng hoặc cá nhân không có pháp nhân')}${opt('building', 'Tạo tổ chức', 'Dành cho công ty, cửa hàng, đại lý, đơn vị kinh doanh')}</ul>
  </div>`;
}
