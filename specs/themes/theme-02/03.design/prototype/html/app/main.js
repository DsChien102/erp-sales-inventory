// Prototype Theme 2 (TH-02) — 10-8. Không có ?screen= → trang xem (viewer.js); có → vẽ đúng một ca (URL chụp ảnh).
// Vẽ y nguyên Flutter hiện tại (không thiết kế lại) để người dùng rà bằng impeccable. Nguồn Dart ghi ở đầu từng file màn.
// Khung: /products/items và /products/items/:id nằm trong ShellRoute(StoreShell) → thanh bên (web ≥ 1024) / thanh dưới;
// /products/items/new và các màn con /products/items/:id/<x> ngoài khung (shared/shell.js insideShell).
import { DEVICE, DESKTOP, SIDE_WIDTH, renderShell } from '../shared/shell.js';
import { SCREENS } from './cases.js';
import { adaptiveSheet } from './ds.js';
import { FILTER_OPTIONS, detailPlaceholder, filterSheet, listPage, listState } from './list.js';
import { createPage, createState, imageAddSheet } from './create.js';
import {
  PCC, checklistPage, deactivateSheet, deleteBlockedSheet, deleteSheet, evaluate, historyPage, loadingRow, pccPage, reactivateSheet, restoreSheet, BLOCKER_MSG,
} from './pcc.js';
import { toast } from './ds.js';

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
function productArea(v, lv, { sheet = '', detail = null, toastHtml = '' } = {}) {
  const desktop = v.width >= DESKTOP;
  const local = !desktop && sheet ? sheet : '';
  let content;
  if (isSplit(v.width)) {
    const detailWidth = contentWidth(v.width) - LIST_WIDTH - 1;
    const right = `${detail ? detail(detailWidth, true) : detailPlaceholder()}${toastHtml}`;
    content = `<div class="t2-split"><div class="t2-split__list" style="width:${LIST_WIDTH}px">${listPage({ ...lv, width: v.width }, LIST_WIDTH)}</div><i class="t2-vdivider"></i><div class="t2-split__detail">${right}</div></div>`;
  } else content = `${detail ? detail(v.width, false) : listPage({ ...lv, width: v.width }, v.width)}${toastHtml}`;
  return { page: `<div class="t2-area">${content}${local}</div>`, overlay: desktop && sheet ? sheet : '' };
}

/** Ca PCC → (sản phẩm, tuỳ chọn, sheet, toast). Toast VToast: iPhone trên thanh dưới (đáy vùng tab), web trong cột phải. */
const PCC_STATES = {
  ready: ['sp1'], 'ready-no-image': ['sp8'], incomplete: ['sp3'], 'no-unit': ['sp5'], inactive: ['sp6'], deleted: ['sp9'],
  loading: ['sp1', { loading: true }], 'loading-deeplink': ['sp1', { loading: true, noTitle: true }],
  error: ['sp1', { error: 'Sản phẩm không tồn tại hoặc đã bị xoá.' }],
  'danger-open': ['sp1', { dangerOpen: true, scrollEnd: true }], 'danger-open-inactive': ['sp6', { dangerOpen: true, scrollEnd: true }],
  'danger-open-deleted': ['sp9', { dangerOpen: true, scrollEnd: true }],
  'toast-status': ['sp6', {}, ['success', 'Đã cập nhật trạng thái kinh doanh của sản phẩm.']],
  'toast-created': ['sp1', {}, ['success', 'Sản phẩm đã được khởi tạo!']],
};
const STOCK_WARN = ['Sản phẩm vẫn còn tồn kho hiện hành.'];
const PCC_SHEETS = {
  deactivate: ['sp1', 'Ngừng kinh doanh sản phẩm này?', () => deactivateSheet()],
  'deactivate-warning': ['sp1', 'Ngừng kinh doanh sản phẩm này?', () => deactivateSheet(STOCK_WARN)],
  reactivate: ['sp6', 'Kinh doanh lại sản phẩm này?', () => reactivateSheet()],
  'delete-checking': ['sp1', 'Xoá sản phẩm này?', () => loadingRow('Đang kiểm tra điều kiện...')],
  delete: ['sp3', 'Xoá sản phẩm này?', () => deleteSheet()],
  'delete-warning': ['sp1', 'Xoá sản phẩm này?', () => deleteSheet(STOCK_WARN)],
  'delete-blocked': ['sp1', 'Xoá sản phẩm này?', () => deleteBlockedSheet(PCC.sp1.name, ['Sản phẩm đang có trong đơn hàng chưa hoàn tất.'])],
  deleting: ['sp1', 'Xoá sản phẩm này?', () => loadingRow('Đang xóa...')],
  restore: ['sp9', 'Khôi phục sản phẩm này?', (p) => restoreSheet(p.name, evaluate({ ...p, cfMissing: true }).blockers.map((c) => BLOCKER_MSG[c]))],
  'restore-error': ['sp9', 'Khôi phục sản phẩm này?', (p) => restoreSheet(p.name, evaluate({ ...p, cfMissing: true }).blockers.map((c) => BLOCKER_MSG[c]), 'Không thể khôi phục sản phẩm.')],
};

function pccArea(v, sheet) {
  const lv = listState('loaded');
  if (v.screen === 'pcc-sheet' && v.state === 'toast-deleted') {
    return productArea(v, lv, { toastHtml: toast('success', 'Xóa sản phẩm', 'Sản phẩm đã được xóa thành công.') });
  }
  let id; let opts = {}; let t = null; let sh = '';
  if (v.screen === 'pcc') [id, opts = {}, t = null] = PCC_STATES[v.state];
  else {
    const [sid, title, make] = PCC_SHEETS[v.state];
    id = sid;
    sh = sheet(make(PCC[sid]), { title });
    if (v.state === 'restore-error') t = ['danger', 'Không thể khôi phục sản phẩm.'];
  }
  const o = { p: PCC[id], ...opts };
  return productArea(v, { ...lv, selectedId: id }, {
    sheet: sh,
    toastHtml: t ? toast(t[0], t[0] === 'danger' ? 'Không thể khôi phục' : 'Thành công', t[1]) : '',
    detail: (w, split) => pccPage(o, v, w, split),
  });
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
  } else if (v.screen === 'pcc' || v.screen === 'pcc-sheet') {
    ({ page, overlay } = pccArea(v, sheet));
  } else if (v.screen === 'checklist') {
    const b = v.state === 'empty' ? [] : evaluate(v.state === 'no-unit-toast' ? PCC.sp5 : { ...PCC.sp3, images: 0 }).blockers;
    page = checklistPage(b, v, v.state === 'no-unit-toast' ? 'Vui lòng thiết lập đơn vị cơ sở trước.' : '');
  } else if (v.screen === 'history') {
    page = historyPage(v.state, v);
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
