// Prototype Theme 2 (TH-02) — 10-8. Không có ?screen= → trang xem (viewer.js); có → vẽ đúng một ca (URL chụp ảnh).
// Vẽ y nguyên Flutter hiện tại (không thiết kế lại) để người dùng rà bằng impeccable. Nguồn Dart ghi ở đầu từng file màn.
// Khung: /products/items và /products/items/:id nằm trong ShellRoute(StoreShell) → thanh bên (web ≥ 1024) / thanh dưới;
// /products/items/new và các màn con /products/items/:id/<x> ngoài khung (shared/shell.js insideShell).
import { DEVICE, DESKTOP, SIDE_WIDTH, renderShell } from '../shared/shell.js';
import { SCREENS } from './cases.js';
import { adaptiveSheet } from './ds.js';
import { FILTER_OPTIONS, detailPlaceholder, filterSheet, listPage, listState } from './list.js';
import { createPage, createState, imageAddSheet } from './create.js';

/** VListDetailLayout: listWidth 360, minSplitWidth 840 (tính trên bề ngang vùng nội dung của khung). */
export const LIST_WIDTH = 360;
export const contentWidth = (width) => (width >= DESKTOP ? width - SIDE_WIDTH : width);
export const isSplit = (width) => contentWidth(width) >= 840;

/** Trạng thái ban đầu của một ca. */
export function caseView(screen, state, device) {
  const scr = SCREENS.find((s) => s.id === screen) || SCREENS[0];
  const st = scr.states.some(([id]) => id === state) ? state : scr.states[0][0];
  const d = DEVICE[device] ? device : 'iphone';
  return { screen: scr.id, state: st, device: d, width: DEVICE[d].w, height: DEVICE[d].h, location: scr.route };
}

/**
 * Khu Sản phẩm (ProductAreaShell → VListDetailLayout). Sheet mở từ danh sách:
 *   web (≥ 1024) → showVAdaptiveSheet → hộp thoại ở root navigator → phủ cả cửa sổ, kể cả thanh bên → overlay của khung;
 *   hẹp → bottom sheet trong navigator lồng của ShellRoute → chỉ phủ vùng tab, thanh dưới vẫn hiện.
 * PCC (/products/items/:id) là route con: web → cột phải; hẹp → thay danh sách (đợt 2).
 */
function productArea(v, lv, { sheet = '', detail = null } = {}) {
  const desktop = v.width >= DESKTOP;
  const local = !desktop && sheet ? sheet : '';
  let content;
  if (isSplit(v.width)) {
    const detailWidth = contentWidth(v.width) - LIST_WIDTH - 1;
    const right = detail ? detail(detailWidth, true) : detailPlaceholder();
    content = `<div class="t2-split"><div class="t2-split__list" style="width:${LIST_WIDTH}px">${listPage({ ...lv, width: v.width }, LIST_WIDTH)}</div><i class="t2-vdivider"></i><div class="t2-split__detail">${right}</div></div>`;
  } else content = detail ? detail(v.width, false) : listPage({ ...lv, width: v.width }, v.width);
  return { page: `<div class="t2-area">${content}${local}</div>`, overlay: desktop && sheet ? sheet : '' };
}

export function renderView(v) {
  let page = '';
  let overlay = '';
  const sheet = (body, opts) => adaptiveSheet(v.width, body, opts);
  if (v.screen === 'list') {
    ({ page, overlay } = productArea(v, listState(v.state)));
  } else if (v.screen === 'filter') {
    const body = filterSheet(v.state === 'empty' ? [] : FILTER_OPTIONS);
    ({ page, overlay } = productArea(v, listState('loaded'), { sheet: sheet(body, { title: 'Lọc sản phẩm' }) }));
  } else if (v.screen === 'create') {
    page = createPage(createState(v.state), v);
  } else if (v.screen === 'image-add') {
    page = createPage(createState('images'), v);
    overlay = sheet(imageAddSheet(), { title: 'Thêm ảnh sản phẩm' });
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
    // Ca "cuối danh sách" / "ghi chú": cuộn tới cuối như người dùng đã kéo xuống.
    root.querySelectorAll('[data-scroll-end], [data-scroll-to="end"]').forEach((el) => { el.scrollTop = el.scrollHeight; });
    // Màn tạo: bước đang mở (trừ bước 1) cuộn lên đầu vùng cuộn như người dùng vừa chạm tiêu đề bước.
    const step = root.querySelector('.t2-scrollhere');
    if (step) { const sc = step.closest('.t2-create__scroll'); sc.scrollTop = step.offsetTop - sc.offsetTop - 16; }
  }
}
