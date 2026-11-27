// Prototype Theme 3 (TH-03) — 10-8. Không có ?screen= → trang xem (viewer.js); có → vẽ đúng một ca (URL chụp ảnh).
// Vẽ y nguyên Flutter hiện tại (không thiết kế lại) để người dùng rà bằng impeccable. Nguồn Dart ghi ở đầu từng file màn.
// Khung: /partner và /partner/:id nằm trong ShellRoute(StoreShell) → thanh bên (web ≥ 1024) / thanh dưới; /partner/new, /partner/:id/edit ngoài khung.
import { DEVICE, DESKTOP, SIDE_WIDTH, renderShell } from '../shared/shell.js';
import { SCREENS } from './cases.js';
import { adaptiveSheet } from './ds.js';
import { createTypeSheet, detailPlaceholder, filterSheet, listPage, listState, noPermissionPage, sortSheet, SORT_CHOICES } from './list.js';
import { DUP_EXACT, DUP_POSSIBLE, duplicateSheet, formPage, formState, leaveSheet, pickerSheet } from './form.js';
import { duplicateDialogWeb, leaveDialogWeb, pickerDialogWeb } from './form-web.js';
import {
  DETAILS, actionSheet, deactivateSheet, deleteBlockedSheet, deletePrimaryBlockedSheet, detailPage, detailState, reactivateSheet,
  softDeleteSheet, transformToast, vtoast,
} from './detail.js';
import { historyPage } from './history.js';
import {
  CONTACTS, addMethodSheet, changePrimarySheet, contactActionSheet, contactFormPage, contactFormState, contactToast, contactsPage, removeSheet, selectPage,
} from './contacts.js';
import { confirmDialog, transformPage, transformPrimaryBlockedSheet } from './transform.js';
import { createTypeDialogWeb, filterDialogWeb, listPageWeb, noPermissionPageWeb } from './list-web.js';
import { pickerSheetMobile } from './form-mobile.js';
import { actionSheetMobile, deactivateSheetMobile, reactivateSheetMobile } from './detail-mobile.js';
import { createTypeSheetMobile, filterSheetMobile, listPageMobile, noPermissionPageMobile } from './list-mobile.js';
import {
  deactivateDialogWeb, deleteBlockedDialogWeb, deletePrimaryBlockedDialogWeb, reactivateDialogWeb, softDeleteDialogWeb, transformPrimaryBlockedDialogWeb,
} from './detail-web.js';
import { changePrimaryDialogWeb, contactsPageWeb, removeContactDialogWeb, selectDialogWeb } from './contacts-web.js';

/** VListDetailLayout: listWidth 360, minSplitWidth 840 (tính trên bề ngang vùng nội dung của khung). */
export const LIST_WIDTH = 360;
export const contentWidth = (width) => (width >= DESKTOP ? width - SIDE_WIDTH : width);
export const isSplit = (width) => contentWidth(width) >= 840;

/** Trạng thái ban đầu của một ca. */
export function caseView(screen, state, device) {
  const scr = SCREENS.find((s) => s.id === screen) || SCREENS[0];
  const st = scr.states.some(([id]) => id === state) ? state : scr.states[0][0];
  const d = DEVICE[device] ? device : 'iphone';
  let location = scr.route;
  if (scr.id === 'form' && st.startsWith('edit')) location = '/partner/p1/edit';
  return { screen: scr.id, state: st, device: d, width: DEVICE[d].w, height: DEVICE[d].h, location };
}

/**
 * Khu KH & NCC (PartnerAreaShell). Sheet mở từ danh sách:
 *   web (≥ 1024) → showDialog (root navigator) → phủ cả cửa sổ, kể cả thanh bên → overlay của khung;
 *   hẹp → showModalBottomSheet (useRootNavigator false) → route nằm trong navigator lồng của ShellRoute → sheet chỉ phủ vùng tab, thanh dưới vẫn hiện.
 */
/**
 * Hồ sơ (/partner/:id) là route con của khu: web → cột phải (rộng 1040 − 360 − 1 = 679 → cột VPageScaffold 640), danh sách đánh dấu dòng chọn;
 * hẹp → hồ sơ thay danh sách (đẩy trong navigator của khu, thanh dưới vẫn hiện).
 * Toast (VToast trong SnackBar): ScaffoldMessenger gốc hiện SnackBar ở Scaffold gốc. Web: khung không có Scaffold (StoreShell chỉ là Material + Row)
 * → Scaffold gốc là VPageScaffold của hồ sơ → toast nằm trong cột phải. Hẹp: ErpTabScaffold (có thanh dưới) → toast nổi ngay trên thanh dưới.
 * Cả hai: toast đè lên hàng nút "Chỉnh sửa | Thao tác".
 */
function partnerArea(v, lv, { sheet = '', detail = null, toastHtml = '' } = {}) {
  const desktop = v.width >= DESKTOP;
  const local = !desktop && sheet ? sheet : '';
  let content;
  if (v.screen === 'list' && v.state === 'no-permission') content = desktop ? noPermissionPageWeb() : isSplit(v.width) ? noPermissionPage(v, contentWidth(v.width)) : noPermissionPageMobile(); // iPhone: list-mobile.js
  else if (desktop && !detail) content = listPageWeb(lv); // Web chưa mở hồ sơ: bảng toàn trang (list-web.js), không chia 2 cột.
  else if (desktop) content = `${detail(contentWidth(v.width), false)}${toastHtml}`; // Web mở hồ sơ: toàn trang (detail-web.js).
  else if (isSplit(v.width)) {
    const detailWidth = contentWidth(v.width) - LIST_WIDTH - 1;
    const right = detail ? `${detail(detailWidth, true)}${toastHtml}` : detailPlaceholder();
    content = `<div class="t3-split"><div class="t3-split__list" style="width:${LIST_WIDTH}px">${listPage({ ...lv, width: v.width }, LIST_WIDTH)}</div><i class="t3-vdivider"></i><div class="t3-split__detail">${right}</div></div>`;
  } else content = detail ? `${detail(v.width, false)}${toastHtml}` : listPageMobile({ ...lv, width: v.width }); // iPhone: "Danh bạ gọn" (list-mobile.js)
  return { page: `<div class="t3-area">${content}${local}</div>`, overlay: desktop && sheet ? sheet : '' };
}

/** Ca PT-07 → (hồ sơ, sheet, toast). */
const DETAIL_SHEETS = {
  'actions-person': ['p2', (d) => actionSheet(d)], 'actions-org': ['p1', (d) => actionSheet(d)], 'actions-inactive': ['p5', (d) => actionSheet(d)],
  deactivate: ['p2', () => deactivateSheet()], 'deactivate-primary': ['p7', (d) => deactivateSheet(d.primaryOf)], reactivate: ['p5', () => reactivateSheet()],
  'delete-confirm': ['p2', () => softDeleteSheet()], 'delete-blocked': ['p1', () => deleteBlockedSheet(true)], 'delete-blocked-inactive': ['p5', () => deleteBlockedSheet(false)],
  'delete-primary-blocked': ['p7', (d) => deletePrimaryBlockedSheet(d.primaryOf)],
  'transform-primary-blocked': ['p7', (d) => transformPrimaryBlockedSheet(d.primaryOf)],
  'add-contact-method': ['p1', () => addMethodSheet()],
};
const DETAIL_TOASTS = { 'toast-created': ['p2', 'created'], 'toast-updated': ['p1', 'updated'], 'toast-deactivated': ['p5', 'deactivated'], 'toast-failed': ['p1', 'failed'], 'toast-transformed': ['p1', 'transformed'] };

export function renderView(v) {
  let page = '';
  let overlay = '';
  const sheet = (body, opts) => adaptiveSheet(v.width, body, opts);
  if (v.screen === 'list') {
    ({ page, overlay } = partnerArea(v, listState(v.state)));
  } else if (v.screen === 'filter' && v.state === 'sort' && v.width >= DESKTOP) {
    // Web: "Sắp xếp" là menu thả xuống dưới nút sắp xếp của bảng (list-web.js), không phải hộp thoại.
    page = `<div class="t3-area">${listPageWeb(listState('loaded'), { sortOpen: true })}</div>`;
  } else if (v.screen === 'filter') {
    const sel = v.state === 'filter-selected' ? { role: 'customer', type: 'organization', status: 'active', updated: 7 } : {};
    // Web: hộp thoại bộ lọc thiết kế lại (list-web.js); iPhone: sheet như Flutter hiện tại.
    const body = v.state === 'sort' ? sortSheet(SORT_CHOICES[0]) : v.width >= DESKTOP ? filterDialogWeb(sel) : isSplit(v.width) ? filterSheet(sel) : filterSheetMobile(sel); // iPhone: list-mobile.js
    ({ page, overlay } = partnerArea(v, listState('loaded'), { sheet: sheet(body, { label: v.state === 'sort' ? 'Sắp xếp' : 'Bộ lọc KH & NCC' }) }));
  } else if (v.screen === 'create-type') {
    // Web: hộp thoại chọn loại + "Tiếp tục" (list-web.js); iPhone: sheet như Flutter hiện tại.
    const dlg = v.width >= DESKTOP ? createTypeDialogWeb() : isSplit(v.width) ? sheet(createTypeSheet(), { title: 'Thêm KH & NCC mới' }) : sheet(createTypeSheetMobile(), { label: 'Thêm KH & NCC mới' }); // iPhone: list-mobile.js
    ({ page, overlay } = partnerArea(v, listState('loaded'), { sheet: dlg }));
  } else if (v.screen === 'detail' || v.screen === 'detail-sheet') {
    let o = detailState(v.state);
    let sh = '';
    let th = '';
    if (v.screen === 'detail-sheet') {
      const [id, make] = DETAIL_SHEETS[v.state];
      o = detailState(id === 'p1' ? 'org-both' : id === 'p5' ? 'inactive' : id === 'p7' ? 'person-both' : 'person-missing');
      o.scrollEnd = false;
      // Web: "Thao tác hồ sơ" là menu thả xuống dưới nút "Thao tác ▾" (detail-web.js), không phải hộp thoại.
      if (v.width >= DESKTOP && v.state.startsWith('actions-')) o.menu = true;
      else if (v.width >= DESKTOP && v.state === 'add-contact-method') o.addMenu = true; // Web: menu dưới "Thêm người liên hệ" trong thẻ
      else if (v.width >= DESKTOP && v.state.startsWith('delete-blocked')) sh = deleteBlockedDialogWeb(v.state === 'delete-blocked'); // Web: cảnh báo canh trái
      else if (v.width >= DESKTOP && v.state === 'delete-primary-blocked') sh = deletePrimaryBlockedDialogWeb(DETAILS[id].primaryOf);
      else if (v.width >= DESKTOP && v.state === 'transform-primary-blocked') sh = transformPrimaryBlockedDialogWeb(DETAILS[id].primaryOf);
      else if (v.width >= DESKTOP && v.state === 'reactivate') sh = reactivateDialogWeb(); // Web: cảnh báo canh trái (detail-web.js)
      else if (v.width >= DESKTOP && v.state === 'delete-confirm') sh = softDeleteDialogWeb(); // Web: liệt kê hệ quả (detail-web.js)
      else if (v.width >= DESKTOP && v.state.startsWith('deactivate')) sh = deactivateDialogWeb(v.state === 'deactivate-primary' ? DETAILS[id].primaryOf : null); // Web: liệt kê hệ quả (detail-web.js)
      else sh = sheet(v.width >= 840 ? make(DETAILS[id])
        : v.state.startsWith('actions-') ? actionSheetMobile(DETAILS[id])
          : v.state.startsWith('deactivate') ? deactivateSheetMobile(v.state === 'deactivate-primary' ? DETAILS[id].primaryOf : null)
            : v.state === 'reactivate' ? reactivateSheetMobile()
            : make(DETAILS[id]), { label: 'Thao tác hồ sơ' }); // iPhone: detail-mobile.js
    } else if (DETAIL_TOASTS[v.state]) {
      const [id, key] = DETAIL_TOASTS[v.state];
      o = detailState(id === 'p2' ? 'person-missing' : id === 'p5' ? 'inactive' : 'org-both');
      th = key === 'transformed' ? transformToast() : vtoast(key);
    }
    const lv = { ...listState('loaded'), selectedId: o.id };
    ({ page, overlay } = partnerArea(v, lv, { sheet: sh, toastHtml: th, detail: (w, split) => detailPage(o, v, w, split) }));
  } else if (v.screen === 'history') {
    page = historyPage(v.state, v);
  } else if (v.screen === 'contacts') {
    const kind = v.state === 'search' || v.state === 'toast-added' ? 'loaded' : v.state;
    page = `<div class="t3-area">${contactsPage(kind, v, { query: v.state === 'search' ? 'hà' : '' })}${v.state === 'toast-added' ? contactToast('Thêm người liên hệ thành công', v.device) : ''}</div>`;
  } else if (v.screen === 'contact-sheet' && v.state === 'add-method' && v.width >= DESKTOP) {
    page = contactsPageWeb('loaded', { addMenu: true }); // Web: menu thả xuống dưới nút "Thêm người liên hệ" (contacts-web.js)
  } else if (v.screen === 'contact-sheet' && v.width >= DESKTOP) {
    // Web: "Thao tác" = menu ở cuối dòng; đổi chính = cảnh báo canh trái; gỡ = liệt kê hệ quả (contacts-web.js).
    const menuRow = v.state === 'actions' ? 1 : v.state === 'actions-primary' ? 0 : -1;
    page = contactsPageWeb('loaded', { menuRow });
    if (v.state === 'change-primary') overlay = changePrimaryDialogWeb(CONTACTS[0].name, CONTACTS[1].name);
    else if (v.state === 'remove') overlay = removeContactDialogWeb();
  } else if (v.screen === 'contact-sheet') {
    page = contactsPage('loaded', v);
    const body = {
      'add-method': () => addMethodSheet(), actions: () => contactActionSheet(CONTACTS[1]), 'actions-primary': () => contactActionSheet(CONTACTS[0]),
      'change-primary': () => changePrimarySheet(CONTACTS[0].name, CONTACTS[1].name), remove: () => removeSheet(),
    }[v.state]();
    overlay = sheet(body, { label: 'Người liên hệ' });
  } else if (v.screen === 'contact-form') {
    page = contactFormPage(contactFormState(v.state), v);
  } else if (v.screen === 'contact-select' && v.width >= DESKTOP) {
    // Web: hộp thoại chọn nhiều đè trên bảng Người liên hệ (contacts-web.js).
    page = contactsPageWeb('loaded');
    overlay = selectDialogWeb(v.state);
  } else if (v.screen === 'contact-select') {
    page = selectPage(v.state, v);
  } else if (v.screen === 'transform') {
    page = transformPage(v.state === 'confirm' ? 'step2' : v.state, v);
    if (v.state === 'confirm') overlay = confirmDialog();
  } else if (v.screen === 'form') {
    const s = formState(v.state === 'leave' ? 'person-main-filled' : v.state);
    page = formPage(s, v);
    if (v.state === 'leave') overlay = v.width >= DESKTOP ? leaveDialogWeb() : sheet(leaveSheet(), { title: 'Rời khỏi màn hình?' });
  } else if (v.screen === 'duplicate') {
    const exact = v.state === 'exact';
    const fs = { ...formState(exact ? 'person-main-filled' : 'org-main'), active: null, submitting: false };
    page = formPage(fs, v);
    const level = exact ? 'exact' : 'possible';
    const matches = exact ? DUP_EXACT : DUP_POSSIBLE;
    // Web: hộp so sánh "Bạn đang nhập" | "Hồ sơ đã có" (form-web.js); iPhone: sheet như Flutter hiện tại.
    overlay = v.width >= DESKTOP ? duplicateDialogWeb(level, matches, fs)
      : sheet(duplicateSheet(level, matches), { label: exact ? 'Trùng khớp hoàn toàn' : 'Có thể là hồ sơ trùng' });
  } else if (v.screen === 'picker') {
    const p = {
      province: { tab: 0 }, 'province-selected': { tab: 0, province: 'Thành phố Cần Thơ' }, 'province-empty': { tab: 0, query: 'Sài Gòn' },
      ward: { tab: 1, province: 'Thành phố Cần Thơ' },
    }[v.state];
    page = formPage(formState(v.state === 'province' || v.state === 'province-empty' ? 'delivery-empty' : 'delivery'), v);
    // Web: hộp lưới 2 cột (form-web.js); iPhone: sheet như Flutter hiện tại.
    overlay = v.width >= DESKTOP ? pickerDialogWeb(p) : sheet(v.width < 840 ? pickerSheetMobile(p, v.height) : pickerSheet(p, v.height), { label: 'Khu vực hành chính' }); // iPhone: form-mobile.js
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
  }
}
