// PT-08 Người liên hệ, PT-09 Thêm / sửa người liên hệ, PT-10 Chọn từ cá nhân + sheet của người liên hệ.
// Route /partner/:id/contacts, …/contacts/new, …/:contactId/edit, …/contacts/select khai báo ngoài ShellRoute → toàn màn (web không thanh bên).
// Nguồn Flutter (apps/erp/lib/features/partner/presentation/):
//   pages/{partner_contacts_page, partner_contact_form_page, partner_contact_select_page}.dart
//   widgets/{partner_contacts_loaded_body, partner_contacts_error_body, partner_contact_tile, partner_contact_empty_illustration,
//     partner_contact_action_sheet, partner_contact_add_method_sheet, partner_contact_change_primary_dialog, partner_contact_remove_dialog,
//     partner_contact_form, partner_contact_select_list, partner_detail_add_contact_flow}.dart
import { icon } from '../shared/icons.js';
import {
  appBar, avatar, button, card, centerLoading, esc, field, gap, iconBox, input, scaffold, searchBar, select, textArea, toast, fab,
} from './ds.js';
import { DESKTOP } from '../shared/shell.js';
import { contactFormPageWeb, contactsPageWeb } from './contacts-web.js';
import { contactFormPageMobile, contactsPageMobile, selectPageMobile } from './contacts-mobile.js';

export const ORG = { name: 'Công ty TNHH Thú y An Phát', roles: 'KH & NCC' };
export const CONTACTS = [
  { name: 'Phạm Thu Hà', primary: true, role: 'Quản lý kinh doanh', phone: '0905 667 788', email: 'ha.pt@anphat.vn' },
  { name: 'Lê Văn Tâm', role: 'Kế toán', phone: '0918 223 344' },
  { name: 'Võ Minh Khoa', inactive: true, role: 'Giao nhận', phone: '0937 445 566' },
];
export const PEOPLE = [
  { name: 'Nguyễn Văn Hùng', phone: '0912 345 678', email: 'hung.nv@gmail.com' },
  { name: 'Lê Hoàng Phúc', phone: '0903 112 233', email: 'phuc.lh@gmail.com' },
  { name: 'Trần Thị Mai', phone: '0987 654 321' },
  { name: 'Đặng Quốc Bảo', phone: '0976 554 433', email: 'bao.dq@outlook.com' },
];
/** _roleOptions (partner_contact_form.dart) — thứ tự khác TH-03 US-04.2 (Kế toán trước Nhân viên mua hàng, Giao nhận trước Phụ trách công nợ). */
export const ROLE_OPTIONS = ['Chủ đại lý', 'Quản lý kinh doanh', 'Kế toán', 'Nhân viên mua hàng', 'Giao nhận', 'Phụ trách công nợ', 'Khác'];

/** PartnerContactsLoadedBody / PartnerContactsCubit.searchContacts: lọc trên máy theo tên / SĐT / email (không phân biệt hoa thường). */
export function filterContacts(list, q) {
  const k = (q || '').trim().toLowerCase();
  if (!k) return list;
  return list.filter((c) => [c.name, c.phone, c.email].some((x) => x && x.toLowerCase().includes(k)));
}

/** PartnerContactActionSheet: "Đặt làm chính" chỉ khi chưa chính và đang hoạt động. */
export const canSetPrimary = (c) => !c.primary && !c.inactive;

/** _StatusChip: đệm 8 / 2, bo 4, caption 12 w600, nền màu 10%. */
const chipTag = (text, tone) => `<span class="t3-ctag t3-ctag--${tone}">${esc(text)}</span>`;

/** PartnerContactTile: InkWell đệm dọc 12; VAvatar 40 | khe 8 | tên w600 (+ "Chính" / "Ngừng hoạt động") + vai trò / SĐT / email | khe 8 | chevron_right_rounded 24 textMuted. */
function contactTile(c) {
  const lines = [c.role, c.phone, c.email].filter(Boolean).map((x) => `${gap(4)}<span>${esc(x)}</span>`).join('');
  return `<li class="t3-ctile">${avatar(c.name)}<div><div class="t3-ctile__name"><b>${esc(c.name)}</b>${c.primary ? chipTag('Chính', 'success') : ''}${c.inactive ? chipTag('Ngừng hoạt động', 'warning') : ''}</div>${lines}</div><i>${icon('chevronRight')}</i></li>`;
}

/** Ảnh trống: 3 vòng người + chấm "+" xanh (Stack 120 × 120). */
export const emptyArt = () => `<div class="t3-cart"><span class="a">${icon('user')}</span><span class="b">${icon('user')}</span><span class="c">${icon('idCard')}</span><span class="d">${icon('plus')}</span></div>`;

/** PartnerContactsPage: VPageScaffold("Người liên hệ", centerTitle, ← mặc định, action "⋯" không làm gì), FAB khi đã tải. */
export function contactsPage(kind, v, { query = '' } = {}) {
  if (v.width >= DESKTOP) return contactsPageWeb(kind, { query }); // Web: bảng (contacts-web.js)
  if (v.width < 840) return contactsPageMobile(kind, { query }); // iPhone: danh bạ gọn (contacts-mobile.js)
  let body;
  if (kind === 'loading') body = centerLoading({ material: true });
  else if (kind === 'error' || kind === 'no-permission') {
    const np = kind === 'no-permission';
    body = `<div class="t3-cerr"><i class="t3-cerr__icon">${icon('error')}</i>${gap(12)}<h2>${np ? 'Không có quyền quản lý người liên hệ' : 'Đã xảy ra lỗi'}</h2>${gap(8)}<p>${np ? 'Bạn không có quyền xem hoặc thay đổi người liên hệ của tổ chức này.' : 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.'}</p>${gap(16)}${button('Quay lại', { variant: 'secondary', fg: 'success' })}</div>`;
  } else {
    const head = `<div class="t3-orghead"><h2>${esc(ORG.name)}</h2>${gap(4)}<p>Tổ chức • ${esc(ORG.roles)}</p></div>`;
    if (kind === 'empty') {
      body = `${head}<div class="t3-cempty">${emptyArt()}${gap(24)}<h2>Chưa có người liên hệ</h2>${gap(8)}<p>Thêm người liên hệ để liên kết làm việc<br>với tổ chức này.</p>${gap(16)}${button('Gợi ý thêm người liên hệ', { variant: 'secondary', fg: 'success' })}</div>`;
    } else {
      const list = filterContacts(CONTACTS, query);
      body = `${head}<div class="t3-csearch">${searchBar({ value: query, hint: 'Tìm kiếm người liên hệ' })}</div><p class="t3-ccount">${list.length} người liên hệ</p>${gap(8)}<ul class="t3-clist">${list.map(contactTile).join('')}</ul>`;
    }
  }
  const more = `<button type="button" class="t3-appbar__act" aria-label="Thêm">${icon('more')}</button>`;
  const page = scaffold({ appbar: appBar('Người liên hệ', { back: true, center: true, actions: more }), body, fabHtml: kind === 'loading' || kind === 'error' || kind === 'no-permission' ? '' : fab('plus', 'Thêm người liên hệ'), placeWidth: v.width, windowWidth: v.width });
  return page;
}

/** PartnerContactAddMethodSheet (VPagePadding + applyBottomSafeArea): "Thêm người liên hệ" H3 w700; 2 VCard (khe chữ → › là 8 ở thẻ 1, 16 ở thẻ 2); "Hủy". */
export function addMethodSheet() {
  const row = (ic, tone, t, d, g) => card(`<div class="t3-mcard">${iconBox({ ic, circle: true, cls: `t3-ibox--${tone}` })}<i class="t3-gap-h16"></i><div><b>${esc(t)}</b>${gap(4)}<span>${esc(d)}</span></div><i class="t3-gap-h${g}"></i><i class="t3-mcard__chev">${icon('chevronRight')}</i></div>`, { cls: 't3-card--tap' });
  return `<div class="t3-pad t3-addm">${gap(8)}<h2 class="t3-h3">Thêm người liên hệ</h2>${gap(16)}${row('userPlus', 'success', 'Tạo người liên hệ mới', 'Nhập thông tin để tạo người liên hệ mới', 8)}${gap(8)}${row('search', 'info', 'Chọn từ cá nhân có sẵn', 'Tìm kiếm và liên kết cá nhân đã có trong hệ thống', 16)}${gap(16)}${button('Hủy', { variant: 'secondary', full: true })}</div>`;
}

/** PartnerContactActionSheet: "Thao tác" H3 + khe 8 + gạch + ListTile (56, icon 24) + "Hủy". */
export function contactActionSheet(c) {
  const tile = (ic, label, danger = false) => `<div class="t3-ltile${danger ? ' is-danger' : ''}"><i>${icon(ic)}</i><span>${esc(label)}</span><i class="t3-ltile__chev">${icon('chevronRight')}</i></div>`;
  return `<div class="t3-actsheet"><h2 class="t3-actsheet__title">Thao tác</h2>${gap(8)}<hr class="t3-divider">${tile('edit', 'Chỉnh sửa liên hệ')}${canSetPrimary(c) ? tile('star', 'Đặt làm chính') : ''}${tile('trash', 'Gỡ khỏi tổ chức', true)}${gap(8)}<div class="t3-pad">${button('Hủy', { variant: 'secondary', full: true })}</div>${gap(16)}</div>`;
}

/** PartnerContactChangePrimaryDialog: tự bọc VBottomSheet bên trong showVAdaptiveSheet → thêm một tay kéo + bo trên (cả trong hộp thoại web). */
export function changePrimarySheet(from, to) {
  return `<div class="t3-innersheet"><div class="sh-sheet__handle" aria-hidden="true"></div><div class="t3-confirm">
    <h2 class="t3-ctitle">Đổi người liên hệ chính?</h2>${gap(12)}<p class="t3-cdesc t3-cdesc--n">${esc(from)} hiện đang là người liên hệ chính. Nếu tiếp tục, ${esc(to)} sẽ trở thành người liên hệ chính mới.</p>${gap(16)}
    <div class="t3-swap">${iconBox({ label: avatar(from).match(/<b>(.*?)<\/b>/)[1], size: 48, iconSize: 16, circle: true, cls: 't3-ibox--success' })}<i>${icon('arrowRight')}</i>${iconBox({ label: avatar(to).match(/<b>(.*?)<\/b>/)[1], size: 48, iconSize: 16, circle: true, cls: 't3-ibox--success' })}</div>${gap(20)}
    <div class="t3-grid2">${button('Quay lại', { variant: 'secondary', fg: 'success', full: true })}${button('Xác nhận đổi', { full: true })}</div></div></div>`;
}

/** PartnerContactRemoveDialog: khe giữa hai nút 8 (sheet khác 12). */
export const removeSheet = () => `<div class="t3-confirm"><h2 class="t3-ctitle">Gỡ người liên hệ?</h2>${gap(12)}<p class="t3-cdesc t3-cdesc--n">Người này sẽ được gỡ khỏi danh sách liên hệ của tổ chức. Hồ sơ cá nhân không bị xóa khỏi hệ thống.</p>${gap(16)}<div class="t3-grid2 t3-grid2--8">${button('Quay lại', { variant: 'secondary', fg: 'success', full: true })}${button('Gỡ liên hệ', { tone: 'danger', full: true })}</div></div>`;

// ---------------------------------------------------------------- PT-09

/**
 * PartnerContactFormPage: VPageScaffold(centerTitle) leading TextButton "Hủy", action TextButton "Lưu" (luôn bấm được, kể cả khi đang lưu).
 * Thân: ListView đệm 16, ô cách 16; hàng nút đáy của PartnerContactForm không hiện (trang luôn truyền onFormCreated).
 */
export function contactFormPage(s, v) {
  if (v.width >= DESKTOP) return contactFormPageWeb(s); // Web: form + cột tóm tắt (contacts-web.js)
  if (v.width < 840) return contactFormPageMobile(s); // iPhone: cùng mẫu form hồ sơ (contacts-mobile.js)
  const e = s.errors || {};
  const err = s.serverError ? `<div class="t3-cformerr">${esc(s.serverError)}</div>${gap(16)}` : '';
  const dis = s.submitting;
  const fields = [
    field({ label: 'Họ và tên', required: true, error: e.name, control: input({ value: s.name, hint: 'Nhập họ và tên người liên hệ', invalid: !!e.name, disabled: dis }) }),
    field({ label: 'Vai trò liên hệ', required: true, error: e.role, control: select({ value: s.role, hint: 'Chọn vai trò' }).replace('class="t3-select', `class="t3-select${e.role ? ' is-invalid' : ''}${dis ? ' is-disabled' : ''}`) }),
    field({ label: 'SĐT chính', required: true, error: e.phone, control: input({ value: s.phone, hint: 'Nhập số điện thoại', invalid: !!e.phone, disabled: dis }) }),
    field({ label: 'Email', control: input({ value: s.email, hint: 'Nhập địa chỉ email', disabled: dis }) }),
    `<div class="t3-primrow"><div><b>Người liên hệ chính</b>${gap(4)}<span>Là người liên hệ chính cho tổ chức</span></div><span class="t3-switch${s.primary ? ' is-on' : ''}${dis ? ' is-disabled' : ''}" role="switch" aria-checked="${!!s.primary}"><i></i></span></div>`,
    field({ label: 'Ghi chú', control: textArea({ value: s.note, hint: 'Nhập ghi chú liên quan', minLines: 2 }) }),
  ].join(gap(16));
  const leading = '<button type="button" class="t3-textact">Hủy</button>';
  const save = '<button type="button" class="t3-textact t3-textact--b">Lưu</button>';
  const body = s.loading ? centerLoading({ material: true }) : `<div class="t3-form__scroll">${err}${fields}</div>`;
  return scaffold({ appbar: appBar(s.edit ? 'Chỉnh sửa liên hệ' : 'Thêm người liên hệ', { leading, center: true, actions: save }), body, placeWidth: v.width, windowWidth: v.width });
}

export function contactFormState(state) {
  const base = { name: '', role: '', phone: '', email: '', primary: false, note: '', errors: {}, edit: false };
  return {
    new: base,
    filled: { ...base, name: 'Nguyễn Thị Lan', role: 'Nhân viên mua hàng', phone: '0909 112 233', email: 'lan.nt@anphat.vn', primary: true },
    errors: { ...base, phone: '0909', errors: { name: 'Vui lòng nhập họ tên', role: 'Vui lòng chọn vai trò', phone: 'Số điện thoại không hợp lệ' } },
    submitting: { ...base, name: 'Nguyễn Thị Lan', role: 'Nhân viên mua hàng', phone: '0909 112 233', submitting: true },
    'server-error': { ...base, name: 'Nguyễn Thị Lan', role: 'Nhân viên mua hàng', phone: '0909 112 233', serverError: 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.' },
    edit: { ...base, edit: true, name: 'Lê Văn Tâm', role: 'Kế toán', phone: '0918 223 344', note: 'Liên hệ đối chiếu công nợ cuối tháng.' },
    'edit-loading': { ...base, edit: true, loading: true },
  }[state];
}

// ---------------------------------------------------------------- PT-10

/** PartnerContactSelectList: ô tìm đệm 16; danh sách gạch ngăn; ô chọn tròn 22 (nhiều lựa chọn nhưng trông như radio); hàng nút đáy nằm trong thân. */
export function selectPage(kind, v) {
  if (v.width < 840) return selectPageMobile(kind); // iPhone: danh sách gộp, ô tick vuông (contacts-mobile.js)
  const selected = kind === 'selected' ? [0, 3] : [];
  let list;
  if (kind === 'loading') list = centerLoading({ material: true });
  else if (kind === 'error') list = '<div class="t3-center"><p class="t3-selmsg is-danger">Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.</p></div>';
  else if (kind === 'empty') list = '<div class="t3-center"><p class="t3-selmsg">Không tìm thấy cá nhân nào.</p></div>';
  else {
    list = `<ul class="t3-clist t3-clist--fill">${PEOPLE.map((p, i) => `<li class="t3-ctile t3-ctile--sel">${avatar(p.name)}<div><b>${esc(p.name)}</b>${p.phone ? `${gap(4)}<span>${esc(p.phone)}</span>` : ''}${p.email ? `${gap(4)}<span>${esc(p.email)}</span>` : ''}</div><span class="t3-selmark${selected.includes(i) ? ' is-on' : ''}">${selected.includes(i) ? icon('check') : ''}</span></li>`).join('')}</ul>`;
  }
  const q = kind === 'empty' ? 'Hoàng Yến' : '';
  const body = `<div class="t3-form"><div class="t3-csearch">${searchBar({ value: q, hint: 'Tìm kiếm tên, SĐT, email' })}</div><div class="t3-selbody">${list}</div><div class="t3-dbar">${button('Hủy', { variant: 'secondary', fg: 'success', full: true })}${button(`Chọn (${selected.length})`, { full: true, disabled: !selected.length })}</div></div>`;
  return scaffold({ appbar: appBar('Chọn từ cá nhân', { back: true }), body, placeWidth: v.width, windowWidth: v.width });
}

/**
 * Scaffold có FAB ở đáy: SnackBar nổi lấy đỉnh FAB làm mốc đáy (_ScaffoldLayout) → toast nằm trên nút +.
 * Đỉnh FAB: iPhone (ngoài khung) 34 + 16 + 56 = 106, web 16 + 56 = 72; cộng lề SnackBar 10 + lề VToast 4.
 */
export const contactToast = (msg, device) => toast('success', 'Thành công', msg, { bottom: (device === 'iphone' ? 106 : 72) + 14 });
