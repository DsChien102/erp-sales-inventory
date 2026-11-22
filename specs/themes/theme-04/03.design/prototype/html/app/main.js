// Prototype Theme 4 (TH-04) — 10-8. Không có ?screen= → trang xem (viewer.js); có → vẽ đúng một ca (URL chụp ảnh).
// Vẽ y nguyên Flutter hiện tại (không thiết kế lại) để người dùng rà bằng impeccable. Nguồn Dart ghi ở đầu từng file màn.
// Khung: mọi route /pricing/* là GoRoute cấp gốc, nằm NGOÀI ShellRoute(StoreShell) → không thanh bên (web) / thanh dưới (iPhone);
// shared/shell.js insideShell('/pricing…') = false. Sheet là showVBottomSheet (root navigator) → phủ cả màn ở cả hai khổ.
import { DEVICE, renderShell } from '../shared/shell.js';
import { SCREENS } from './cases.js';
import { bottomSheet } from './ds.js';
import { filterSheet, filterSheetState, listPage, listState, sortSheet } from './list.js';
import {
  customerPick, effectiveToSheet, formNoPermission, formPage, formState, formStateChanged, leaveSheet, overwriteSheet,
  productPick, saveConfirmSheet, saveErrorToast, unitPick,
} from './form.js';
import { actionSheet, detailPage, detailState, detailToast, disableSheet, reenableError, reenableLoading, reenableSheet } from './detail.js';
import { activitySheet, historyFilterSheet, historyPage } from './history.js';
import { ACTIVITIES } from './data.js';

/** Trạng thái ban đầu của một ca. */
export function caseView(screen, state, device) {
  const scr = SCREENS.find((s) => s.id === screen) || SCREENS[0];
  const st = scr.states.some(([id]) => id === state) ? state : scr.states[0][0];
  const d = DEVICE[device] ? device : 'iphone';
  return { screen: scr.id, state: st, device: d, width: DEVICE[d].w, height: DEVICE[d].h, location: scr.route };
}

function formSheetCase(v) {
  switch (v.state) {
    case 'effective-to': return { page: formPage(formState('filled'), v), overlay: bottomSheet(effectiveToSheet()) };
    case 'overwrite': return { page: formPage(formState('filled'), v), overlay: bottomSheet(overwriteSheet(), { label: 'Xác nhận tự động ghi đè giá riêng' }) };
    case 'leave': return { page: formPage(formState('filled'), v), overlay: bottomSheet(leaveSheet(), { title: 'Rời khỏi màn hình?' }) };
    case 'save-confirm': return { page: formPage({ ...formState('edit'), price: 99000 }, v), overlay: bottomSheet(saveConfirmSheet({ oldPrice: '105.000đ', newPrice: '99.000đ', oldTo: 'Không giới hạn', newTo: 'Không giới hạn' }), { label: 'Xác nhận lưu thay đổi giá riêng' }) };
    case 'save-confirm-dates': return { page: formPage(formState('edit-dates'), v), overlay: bottomSheet(saveConfirmSheet({ oldPrice: '105.000đ', newPrice: '99.000đ', oldTo: 'Không giới hạn', newTo: '31/12/2026', reason: 'Điều chỉnh theo phụ lục HĐ' }), { label: 'Xác nhận lưu thay đổi giá riêng' }) };
    default: return { page: '', overlay: '' };
  }
}

export function renderView(v) {
  let page = '';
  let overlay = '';
  switch (v.screen) {
    case 'list': page = listPage(listState(v.state), v); break;
    case 'filter': page = listPage(listState('loaded'), v); overlay = bottomSheet(filterSheet(filterSheetState(v.state)), { title: 'Bộ lọc giá riêng' }); break;
    case 'sort': page = listPage(listState('loaded'), v); overlay = bottomSheet(sortSheet()); break;
    case 'form':
      if (v.state === 'no-permission') page = formNoPermission(v, false);
      else page = formPage(formState(v.state), v, { toastHtml: v.state === 'save-error' ? saveErrorToast(v) : '' });
      break;
    case 'form-edit':
      if (v.state === 'no-permission') page = formNoPermission(v, true);
      else if (v.state === 'state-changed') page = formStateChanged(v);
      else page = formPage(formState(v.state), v);
      break;
    case 'form-sheet': ({ page, overlay } = formSheetCase(v)); break;
    case 'pick-customer': page = customerPick(v.state, v); break;
    case 'pick-product': page = productPick(v.state, v); break;
    case 'pick-unit': page = unitPick(v.state, v); break;
    case 'detail': {
      const t = { 'toast-created': ['success', 'Đã tạo giá riêng thành công'], 'toast-disabled': ['success', 'Giá riêng sẽ không áp dụng cho đơn hàng mới.'], 'toast-reenable-error': ['danger', 'Vui lòng thử lại sau.'] }[v.state];
      const st = v.state === 'toast-created' ? 'applying' : v.state === 'toast-reenable-error' ? 'disabled' : v.state;
      page = detailPage(st, v, { toastHtml: t ? detailToast(v, t[0], t[1]) : '' });
      break;
    }
    case 'detail-sheet': {
      const off = detailState('disabled');
      const on = detailState('applying');
      const sheets = {
        actions: () => [on, bottomSheet(actionSheet(on.actions), { title: 'Thao tác' })],
        'actions-disabled': () => [off, bottomSheet(actionSheet(off.actions), { title: 'Thao tác' })],
        disable: () => [on, bottomSheet(disableSheet(on), { title: 'Tắt giá riêng' })],
        'disable-submitting': () => [on, bottomSheet(disableSheet(on, { submitting: true, reason: 'Khách tạm ngưng nhập hàng' }), { title: 'Tắt giá riêng' })],
        'reenable-loading': () => [off, bottomSheet(reenableLoading(), { title: 'Bật lại giá riêng' })],
        reenable: () => [off, bottomSheet(reenableSheet(off), { title: 'Bật lại giá riêng' })],
        'reenable-below': () => [off, bottomSheet(reenableSheet(off, { mode: 'below' }), { title: 'Bật lại giá riêng' })],
        'reenable-below-ack': () => [off, bottomSheet(reenableSheet(off, { mode: 'below', ack: true }), { title: 'Bật lại giá riêng' })],
        'reenable-blocked': () => [off, bottomSheet(reenableSheet(off, { mode: 'blocked' }), { title: 'Bật lại giá riêng' })],
        'reenable-error': () => [off, bottomSheet(reenableError(), { title: 'Bật lại giá riêng' })],
      };
      const [rule, sheet] = sheets[v.state]();
      page = detailPage(rule === off ? 'disabled' : 'applying', v);
      overlay = sheet;
      break;
    }
    case 'history': page = historyPage(v.state, v); break;
    case 'history-sheet':
      page = historyPage('loaded', v);
      if (v.state === 'filter') overlay = bottomSheet(historyFilterSheet(), { label: 'Bộ lọc lịch sử giá riêng' });
      else if (v.state === 'filter-selected') overlay = bottomSheet(historyFilterSheet({ type: 'Sửa giá', actor: 'Trần Minh Đức', time: '30 ngày gần đây' }), { label: 'Bộ lọc lịch sử giá riêng' });
      else overlay = bottomSheet(activitySheet(v.state === 'activity' ? ACTIVITIES[0] : ACTIVITIES[4]), { title: 'Chi tiết hoạt động' });
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
    // Ca "cuối danh sách": cuộn tới cuối như người dùng đã kéo xuống.
    root.querySelectorAll('[data-scroll-end]').forEach((el) => { el.scrollTop = el.scrollHeight; });
  }
}
