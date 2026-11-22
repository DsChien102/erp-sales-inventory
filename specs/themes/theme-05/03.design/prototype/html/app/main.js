// Prototype Theme 5 (TH-05) — 10-8. Không có ?screen= → trang xem (viewer.js); có → vẽ đúng một ca (URL chụp ảnh).
// Vẽ y nguyên Flutter hiện tại (không thiết kế lại) để người dùng rà bằng impeccable. Nguồn Dart ghi ở đầu từng file màn.
// Khung: /sales/drafts + /sales/compose nằm trong TypedShellRoute riêng của Sales (SalesDraftListScope), mọi /sales/* khác là GoRoute cấp gốc
// → đều NGOÀI StoreShell (không thanh bên / thanh dưới); chỉ /orders (SG-08, đợt 3) nằm trong khung. Sheet là showVBottomSheet / showModalBottomSheet
// (root navigator) → phủ cả màn; web: sheet đáy rộng ≤ 640 canh giữa.
import { DEVICE, renderShell } from '../shared/shell.js';
import { SCREENS } from './cases.js';
import { bottomSheet } from './ds.js';
import { DRAFTS } from './data.js';
import { discardSheet, draftListPage, draftToast } from './drafts.js';
import { composePage, composeToast, leaveSheet, qtyKeypad } from './compose.js';
import {
  customerSheet, customerSheetHeight, duplicateSheet, priceAdjustSheet, priceConfirmSheet, priceKeypad, quickCreateSheet, quickDiscardSheet,
  unitSheet, unitSheetHeight,
} from './sheets.js';
import { cashKeypad, checkoutInvalidPage, checkoutPage, finalizeSheet } from './checkout.js';
import { receiptActionSheet, receiptPreviewPage, resultPage, resultToast } from './result.js';

/** Trạng thái ban đầu của một ca. */
export function caseView(screen, state, device) {
  const scr = SCREENS.find((s) => s.id === screen) || SCREENS[0];
  const st = scr.states.some(([id]) => id === state) ? state : scr.states[0][0];
  const d = DEVICE[device] ? device : 'iphone';
  return { screen: scr.id, state: st, device: d, width: DEVICE[d].w, height: DEVICE[d].h, location: scr.route };
}

const DRAFT_TOASTS = {
  'toast-deleted': ['success', 'Đã xóa đơn nháp', 'Đơn nháp của Trần Thị Mai đã được xóa.'],
  'toast-delete-failed': ['danger', 'Không xóa được đơn nháp', 'Đơn nháp đã thay đổi. Vui lòng tải lại danh sách.'],
};
const COMPOSE_TOASTS = {
  'toast-saved': ['new', 'success', 'Đã lưu đơn nháp.', ''],
  'toast-stock': ['filled', 'warning', 'Số lượng vượt quá tồn khả dụng', ''],
  'toast-blocked': ['filled', 'warning', 'Chưa thể thanh toán', 'Sản phẩm đã ngừng bán. Vui lòng quay lại đơn.'],
  'toast-scan': ['filled', 'info', 'Quét mã', 'Nhập barcode vào ô tìm kiếm rồi nhấn tìm.'],
  'toast-price': ['filled', 'success', 'Đã lưu và áp dụng giá riêng', ''],
  'toast-draft-gone': ['new', 'warning', 'Đơn nháp không còn', 'Đơn nháp này đã bị xoá hoặc thay đổi ở nơi khác. Đã chuyển sang đơn mới.'],
};

const CHECKOUT_TOASTS = {
  'toast-blocked': ['danger', 'Chưa đủ điều kiện thanh toán', 'Sản phẩm đã ngừng bán. Vui lòng quay lại đơn.'],
  'toast-failure': ['danger', 'Chưa hoàn tất được đơn', 'Không thể hoàn tất đơn.'],
  'toast-conflict': ['danger', 'Yêu cầu bị xung đột', 'Vui lòng tải lại đơn.'],
};

function composeCase(v) {
  const t = COMPOSE_TOASTS[v.state];
  if (t) return composePage(t[0], v, { toastHtml: composeToast(v, t[1], t[2], t[3]) });
  return composePage(v.state, v);
}

export function renderView(v) {
  let page = '';
  let overlay = '';
  const filled = () => composePage('filled', v);
  switch (v.screen) {
    case 'drafts': {
      const t = DRAFT_TOASTS[v.state];
      page = t ? draftListPage('loaded', v, { toastHtml: draftToast(v, t[0], t[1], t[2]) }) : draftListPage(v.state, v);
      break;
    }
    case 'draft-sheet':
      page = draftListPage('loaded', v);
      overlay = bottomSheet(discardSheet(DRAFTS[3]), { label: 'Xóa đơn nháp' });
      break;
    case 'compose': page = composeCase(v); break;
    case 'compose-sheet':
      page = filled();
      overlay = v.state === 'leave' ? bottomSheet(leaveSheet(), { label: 'Đơn có thay đổi chưa lưu' }) : qtyKeypad();
      break;
    case 'unit':
      page = filled();
      overlay = bottomSheet(unitSheet(v.state === 'other' ? 1 : 0), { label: 'Chọn đơn vị bán', height: unitSheetHeight(v) });
      break;
    case 'customer':
      page = filled();
      overlay = bottomSheet(customerSheet(v.state), { label: 'Chọn khách hàng', height: customerSheetHeight(v) });
      break;
    case 'quick-create':
      page = filled();
      if (v.state === 'discard') overlay = bottomSheet(quickCreateSheet('filled'), { label: 'Tạo nhanh khách hàng' }) + bottomSheet(quickDiscardSheet(), { label: 'Bỏ thay đổi chưa lưu', tone: 'danger' });
      else if (v.state === 'duplicate') overlay = bottomSheet(quickCreateSheet('submitting'), { label: 'Tạo nhanh khách hàng' }) + bottomSheet(duplicateSheet(), { label: 'Có thể khách hàng đã tồn tại' });
      else overlay = bottomSheet(quickCreateSheet(v.state), { label: 'Tạo nhanh khách hàng' });
      break;
    case 'price':
      page = filled();
      if (v.state === 'keypad') overlay = bottomSheet(priceAdjustSheet('default')) + priceKeypad('money');
      else if (v.state === 'keypad-percent') overlay = bottomSheet(priceAdjustSheet('percent')) + priceKeypad('percent');
      else if (v.state === 'confirm-below') overlay = bottomSheet(priceConfirmSheet('below'), { label: 'Xác nhận giá dưới sàn' });
      else if (v.state === 'confirm-overwrite') overlay = bottomSheet(priceConfirmSheet('overwrite'), { label: 'Xác nhận ghi đè giá riêng' });
      else overlay = bottomSheet(priceAdjustSheet(v.state), { label: 'Điều chỉnh giá' });
      break;
    case 'checkout': {
      const t = CHECKOUT_TOASTS[v.state];
      if (v.state === 'invalid') page = checkoutInvalidPage(v);
      else page = t ? checkoutPage('cash', v, { toastHtml: composeToast(v, t[0], t[1], t[2]) }) : checkoutPage(v.state, v);
      break;
    }
    case 'checkout-sheet':
      page = checkoutPage(v.state === 'finalize-debt' ? 'debt-dated' : 'cash', v);
      overlay = v.state === 'keypad' ? cashKeypad() : bottomSheet(finalizeSheet(), { label: 'Xác nhận hoàn tất đơn' });
      break;
    case 'result':
      page = v.state === 'toast-pdf-error'
        ? resultPage('paid', v, { toastHtml: resultToast(v, 'danger', 'Thao tác PDF thất bại', 'Exception: Không thể tạo phiếu bán hàng.') })
        : resultPage(v.state, v);
      break;
    case 'result-sheet':
      page = resultPage('paid', v);
      overlay = bottomSheet(receiptActionSheet(), { title: 'Phiếu bán hàng' });
      break;
    case 'receipt': page = receiptPreviewPage(v.state, v); break;
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
