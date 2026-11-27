// PT-12 Lịch sử thao tác. Route /partner/:id/history khai báo ngoài ShellRoute → toàn màn (web không thanh bên).
// Nguồn Flutter (apps/erp/lib/features/partner/):
//   presentation/pages/partner_change_history_page.dart (VPageScaffold + subtitle tên đối tác + leading IconButton arrowBack)
//   presentation/widgets/{partner_change_history_body, partner_change_history_card}.dart
//   logic/{partner_change_history_cubit, partner_action_log_diff}.dart (tiêu đề dòng, người làm = 8 ký tự đầu user id, chỉ trang 1 / 20 dòng)
import { icon } from '../shared/icons.js';
import { appBar, button, card, centerLoading, emptyDesc, emptyMedia, emptyState, emptyTitle, esc, gap, scaffold } from './ds.js';
import { DESKTOP } from '../shared/shell.js';
import { historyPageWeb } from './history-web.js';

// ---------------------------------------------------------------- hàm thuần (đối chiếu Dart)

/** _titleLabel: hạ chữ đầu, trừ khi 2 ký tự đầu là chữ hoa (SĐT, MST…). */
export function titleLabel(label) {
  if (label.length < 2) return label.toLowerCase();
  const two = label.slice(0, 2);
  if (two === two.toUpperCase()) return label;
  return label[0].toLowerCase() + label.slice(1);
}

const TYPE_SUMMARY = { create: 'Tạo đối tác', update: 'Cập nhật', addContact: 'Thêm người liên hệ', removeContact: 'Xóa người liên hệ', transform: 'Chuyển sang tổ chức', deactivate: 'Ngừng hoạt động', reactivate: 'Kích hoạt lại', delete: 'Xóa đối tác' };

/** _summaryFor: cập nhật ≤ 2 trường → nêu tên; > 2 → 2 tên + "và N thông tin khác". Thay đổi đã sắp theo nhãn (compareTo). */
export function summaryFor(type, changes) {
  if (type === 'update' && changes.length) {
    const labels = changes.map((c) => titleLabel(c.label));
    if (labels.length <= 2) return `Cập nhật ${labels.join(', ')}`;
    return `Cập nhật ${labels.slice(0, 2).join(', ')} và ${labels.length - 2} thông tin khác`;
  }
  return TYPE_SUMMARY[type];
}

/** _changeDescription: nhiều thay đổi → có tiền tố "Nhãn: ". */
export function changeText(c, showLabel) {
  const p = showLabel ? `${c.label}: ` : '';
  if (c.kind === 'added') return `${p}Thêm mới: ${c.after}`;
  if (c.kind === 'removed') return `${p}Đã xóa: ${c.before}`;
  return `${p}${c.before} → ${c.after}`;
}

/** _toEntry: actorDisplayName = 8 ký tự đầu actor_user_id (không phải tên người dùng). */
export const actorDisplay = (id) => (id.length <= 8 ? id : id.slice(0, 8));

// ---------------------------------------------------------------- dữ liệu mẫu

const byLabel = (a, b) => (a.label < b.label ? -1 : a.label > b.label ? 1 : 0);
export const ENTRIES = [
  { type: 'deactivate', at: '2026-11-21 16:40', actor: '3f9a2c1b-7d4e-4f0a-9b1c-2e8d5a6f7c90', reason: 'Tạm ngưng hợp tác cuối năm', changes: [{ label: 'Trạng thái', kind: 'modified', before: 'Đang hoạt động', after: 'Ngừng hoạt động' }] },
  {
    type: 'update', at: '2026-11-18 09:05', actor: '3f9a2c1b-7d4e-4f0a-9b1c-2e8d5a6f7c90',
    changes: [
      { label: 'SĐT chính', kind: 'modified', before: '0283 812 4567', after: '0283 812 9999' },
      { label: 'Email', kind: 'added', before: '(trống)', after: 'lienhe@anphat.vn' },
      { label: 'Tên xuất hóa đơn', kind: 'modified', before: 'CTY AN PHÁT', after: 'CÔNG TY TNHH THÚ Y AN PHÁT' },
    ].sort(byLabel),
  },
  { type: 'addContact', at: '2026-10-12 14:22', actor: 'a71c09e4-1b2f-4c3d-8e9f-0a1b2c3d4e5f', changes: [] },
  { type: 'create', at: '2026-10-02 08:15', actor: '3f9a2c1b-7d4e-4f0a-9b1c-2e8d5a6f7c90', changes: [] },
];

// ---------------------------------------------------------------- màn

/** PartnerChangeHistoryCard: VCard đệm 16; hàng (tiêu đề bodyDefault w700 | khe 8 | ngày caption "yyyy-MM-dd HH:mm"); thay đổi bodySmall cách 4; "Lý do: …" nghiêng; "bởi …" caption. */
export function historyCard(e) {
  const show = e.changes.length > 1;
  const changes = e.changes.length ? `${gap(8)}${e.changes.map((c) => `<p class="t3-small">${esc(changeText(c, show))}</p>`).join(gap(4))}` : '';
  return card(`<div class="t3-hrow"><b>${esc(summaryFor(e.type, e.changes))}</b><span>${esc(e.at)}</span></div>${changes}${e.reason ? `${gap(4)}<p class="t3-small t3-italic">Lý do: ${esc(e.reason)}</p>` : ''}${gap(4)}<p class="t3-caption">bởi ${esc(actorDisplay(e.actor))}</p>`);
}

export function historyPage(kind, v) {
  if (v.width >= DESKTOP) return historyPageWeb(kind); // Web: dòng thời gian (history-web.js)
  let body;
  if (kind === 'loading') body = centerLoading({ material: true });
  else if (kind === 'error') {
    body = emptyState({ tone: 'danger', header: [emptyMedia('alert'), emptyTitle('Không thể tải lịch sử thao tác'), emptyDesc('Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.')], content: `${gap(32)}${button('Thử lại')}` });
  } else if (kind === 'empty') {
    body = emptyState({ header: [emptyMedia('history'), emptyTitle('Chưa có lịch sử thao tác nào'), emptyDesc('Các thay đổi của KH & NCC sẽ xuất hiện tại đây.')] });
  } else body = `<div class="t3-hlist">${ENTRIES.map(historyCard).join(gap(8))}</div>`;
  const leading = `<button type="button" class="t3-appbar__back" aria-label="Quay lại">${icon('arrowLeft')}</button>`;
  return scaffold({ appbar: appBar('Lịch sử thao tác', { subtitle: 'Công ty TNHH Thú y An Phát', leading }), body, placeWidth: v.width, windowWidth: v.width });
}
