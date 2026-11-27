// PT-07 Hồ sơ KH & NCC — bố cục web ≥ 1024 "Hai cột" (người dùng chọn qua /impeccable live, 2026-11-27).
// Toàn trang (không chia cột với danh sách — khớp bảng PT-01 web). Đầu trang: đường dẫn "‹ KH & NCC / Hồ sơ KH & NCC", avatar, tên,
// "Loại · Vai trò" + trạng thái, dòng SĐT · email · MST; nút "Lịch sử thao tác", "Thao tác ▾", "Chỉnh sửa" (nút chính).
// Thân: trái = Thông tin, Hóa đơn / thuế, Địa chỉ giao hàng, Ghi chú (luôn mở); phải = Công nợ, Người liên hệ, Chương trình ưu đãi,
// Lịch sử nhập hàng. Lệch so với Flutter: bỏ thẻ đóng / mở, bỏ hàng nút đáy, "Chỉnh sửa" thành nút chính, "Lịch sử thao tác" lên đầu trang.
// Chữ lấy đúng detail.js. iPhone giữ detailPage (detail.js). CSS: styles/detail-web.css (tiền tố wd-).
import { icon } from '../shared/icons.js';
import { banner, button, esc, initials, skeleton } from './ds.js';
import { addMethodMenu } from './contacts-web.js';
import { DETAILS, ERRORS, errorBody, invoiceBadge, missingDescription, sheetActions } from './detail.js';

const roleText = (r) => (r.includes('customer') && r.includes('supplier') ? 'KH & NCC' : r.includes('customer') ? 'Khách hàng' : r.includes('supplier') ? 'Nhà cung cấp' : 'Chưa có vai trò');
const kv = (rows) => `<dl class="wd-kv">${rows.map(([k, v, mono]) => `<div><dt>${esc(k)}</dt><dd${mono && v ? ' class="wd-mono"' : ''}>${v ? esc(v) : '<span class="wd-dash">—</span>'}</dd></div>`).join('')}</dl>`;
const tag = (text, tone) => `<span class="wd-tag wd-tag--${tone}">${esc(text)}</span>`;
const link = (t, ic = 'chevronRight') => `<button type="button" class="wd-link">${t}${icon(ic)}</button>`;
const card = (title, ic, body, extra = '') => `<section class="wd-card"><header><h2>${icon(ic)}${esc(title)}</h2>${extra}</header>${body}</section>`;
const crumb = `<nav class="wd-crumb" aria-label="Đường dẫn"><button type="button">${icon('chevronLeft')}KH &amp; NCC</button><span>/</span><b>Hồ sơ KH &amp; NCC</b></nav>`;

/** "Thao tác ▾" mở menu thả xuống ngay dưới nút (chọn qua /impeccable live, 2026-11-27) — thay sheet "Thao tác hồ sơ" + "Hủy" trên web. */
function actionMenu(d) {
  const a = sheetActions(d);
  const inactive = d.status === 'inactive';
  const item = (ic, tone, t, sub) => `<button type="button" role="menuitem" class="wd-mi wd-mi--${tone}"><span class="wd-mi__ic">${icon(ic)}</span><span class="wd-mi__t"><b>${esc(t)}</b><small>${esc(sub)}</small></span></button>`;
  const top = [
    a.transform && item('building', 'neutral', 'Chuyển thành tổ chức', 'Chuyển hồ sơ cá nhân hiện tại sang hồ sơ tổ chức.'),
    a.toggle && (inactive ? item('power', 'neutral', 'Kích hoạt lại', 'Cho phép sử dụng lại trong hệ thống.') : item('pause', 'neutral', 'Ngừng hoạt động', 'Tạm ngừng sử dụng trong hệ thống.')),
  ].filter(Boolean).join('');
  const del = a.del ? item('trash', 'danger', 'Xóa hồ sơ', 'Xóa mềm, không hiển thị trong danh sách.') : '';
  return `<div class="wd-menu" role="menu" aria-label="Thao tác hồ sơ">${top}${top && del ? '<hr>' : ''}${del}</div>`;
}

function head(d, menuOpen = false) {
  const st = d.status === 'active' ? '<span class="wd-status wd-status--on"><i></i>Đang hoạt động</span>' : '<span class="wd-status wd-status--off"><i></i>Ngừng hoạt động</span>';
  const phone = d.type === 'person' ? d.person.phone : d.org.phone;
  const email = d.type === 'person' ? d.person.email : d.org.email;
  const quick = [phone && `${icon('phone')}<span class="wd-mono">${esc(phone)}</span>`, email && `${icon('mail')}<span>${esc(email)}</span>`, d.taxCode && `<span>MST <span class="wd-mono">${esc(d.taxCode)}</span></span>`].filter(Boolean);
  const acts = d.system
    ? `<div class="wd-acts">${button('Lịch sử thao tác', { variant: 'secondary', cls: 'wd-b' })}</div>`
    : `<div class="wd-acts">${button('Lịch sử thao tác', { variant: 'secondary', cls: 'wd-b' })}<span class="wd-menuwrap">${button('Thao tác', { variant: 'secondary', cls: `wd-b${menuOpen ? ' is-open' : ''}`, attrs: `aria-haspopup="menu" aria-expanded="${menuOpen}"` }).replace('</span></button>', `</span>${icon(menuOpen ? 'chevronUp' : 'chevronDown')}</button>`)}${menuOpen ? actionMenu(d) : ''}</span>${button('Chỉnh sửa', { cls: 'wd-b', disabled: !d.actions.includes('update') })}</div>`;
  return `<header class="wd-head">${crumb}<div class="wd-head__row"><span class="wd-av">${esc(initials(d.name))}</span>
    <div class="wd-head__t"><h1>${esc(d.name)}</h1><p>${d.type === 'person' ? 'Cá nhân' : 'Tổ chức'} · ${esc(roleText(d.roles))} ${st}</p>
    ${quick.length ? `<p class="wd-quick">${quick.join('<span class="wd-sep"></span>')}</p>` : ''}</div>${acts}</div></header>`;
}

// ---------------------------------------------------------------- khối

function mainInfo(d) {
  const p = d.person; const o = d.org;
  return d.type === 'person'
    ? card('Thông tin cá nhân', 'user', kv([['Danh xưng', p.title], ['Họ và tên', p.fullName], ['Tên thường gọi', p.nickname], ['SĐT chính', p.phone, true], ['SĐT phụ', p.phone2, true], ['Email', p.email]]))
    : card('Thông tin tổ chức', 'building', kv([['Loại tổ chức', o.type], ['Tên tổ chức', o.name], ['Tên viết tắt', o.shortName], ['Tên quốc tế', o.intlName], ['SĐT chính', o.phone, true], ['Email', o.email]]));
}
function invoiceCard(d) {
  const b = invoiceBadge(d);
  return card('Hóa đơn / thuế', 'receipt', kv([['MST', d.taxCode, true], ['Tên xuất hóa đơn', d.invoice.name], ['Email nhận hóa đơn', d.invoice.email], ['Địa chỉ xuất hóa đơn', d.invoice.address]]), b ? tag(b, 'danger') : '');
}
function deliveryCard(d) {
  const x = d.delivery;
  const empty = !x.province && !x.commune && !x.address;
  return card('Địa chỉ giao hàng', 'mapPin', kv([['Tỉnh / Thành phố', x.province], ['Xã / Phường', x.commune], ['Địa chỉ chi tiết', x.address]]), empty ? tag('Chưa có', 'warning') : '');
}
const noteCard = (d) => card('Ghi chú', 'stickyNote', d.note ? `<p class="wd-note">${esc(d.note)}</p>` : '<p class="wd-note wd-dash">—</p>', d.note ? '' : tag('Chưa có', 'warning'));

function receivableCard(d, loading) {
  if (loading) return card('Công nợ', 'wallet', `${skeleton(32, { w: '60%', radius: 4 })}<i class="t3-gap" style="height:8px"></i>${skeleton(14, { w: '40%', radius: 4 })}`);
  const r = d.receivable || {};
  const body = r.owed
    ? `<p class="wd-amt-lg wd-mono">${esc(r.owed)}</p><p class="wd-sub">Còn nợ · ${r.orders} đơn</p>${r.overdue > 0 ? `<p class="wd-due">${icon('alert')}Quá hạn ${r.overdue} ngày</p>` : ''}`
    : '<p class="wd-sub">Không còn nợ</p>';
  return card('Công nợ', 'wallet', body, link('Xem'));
}
function contactsCard(d, addMenu = false) {
  const n = d.contacts.length;
  const list = n ? `<ul class="wd-contacts">${[...d.contacts].sort((a, b) => (b.primary ? 1 : 0) - (a.primary ? 1 : 0)).slice(0, 2).map((c) => `<li><span class="wd-av wd-av--sm">${esc(initials(c.name))}</span><div><b>${esc(c.name)}${c.primary ? ' <em>Chính</em>' : ''}</b><small>${[c.role && esc(c.role), c.phone && `<span class="wd-mono">${esc(c.phone)}</span>`, c.email && esc(c.email)].filter(Boolean).join(' · ')}</small></div></li>`).join('')}</ul>`
    : '<p class="wd-sub">Chưa có người liên hệ.</p>';
  return card('Người liên hệ', 'users', `${list}<div class="wd-cardfoot"><span class="wd-menuwrap">${link('Thêm người liên hệ', 'plusCircle')}${addMenu ? addMethodMenu('wd-menu--left') : ''}</span>${link(n ? `Xem tất cả (${n})` : 'Tất cả')}</div>`, n ? `<span class="wd-count">${n}</span>` : tag('Chưa có', 'warning'));
}
function programsCard(list, { loading, error }) {
  let body;
  if (loading) body = skeleton(44, { radius: 4 });
  else if (error) body = `<div class="wd-inline"><p class="wd-sub">Không tải được chương trình ưu đãi.</p>${button('Thử lại', { variant: 'tertiary', size: 'small' })}</div>`;
  else if (!list.length) body = `<p class="wd-sub">Chưa có chương trình đang chạy.</p><div class="wd-cardfoot">${link('Tạo chương trình', 'plus')}</div>`;
  else {
    body = `<ul class="wd-rows">${list.map((p) => `<li><div><b>${esc(p.name)}</b><small>${esc(p.kind)}</small>${p.progress
      ? `<span class="wd-prog"><span class="wd-prog__bar"><i style="width:${Math.min(1, p.progress[0]) * 100}%"></i></span><span class="wd-mono">${esc(p.progress[1])}</span></span>`
      : `<small>${esc(p.summary)}</small>`}</div><span class="wd-tag wd-tag--${p.status[1]}">${esc(p.status[0])}</span></li>`).join('')}</ul>`;
  }
  return card('Chương trình ưu đãi', 'tag', body, link('Xem tất cả'));
}
function receiptsCard(list, { loading }) {
  let body;
  if (loading) body = `${skeleton(40, { radius: 4 })}<i class="t3-gap" style="height:8px"></i>${skeleton(40, { radius: 4 })}`;
  else if (!list.length) body = '<p class="wd-sub">Chưa có lịch sử nhập hàng từ nhà cung cấp này.</p>';
  else body = `<ul class="wd-rows">${list.map((r) => `<li><div><b class="wd-mono">${esc(r.no)}</b><small>${esc(r.date)} · ${r.lines} dòng (${r.lots} lô)</small></div><span class="wd-mono wd-amt">${esc(r.total)}</span></li>`).join('')}</ul>`;
  return card('Lịch sử nhập hàng', 'download', body, list.length && !loading ? link('Xem tất cả') : '');
}

// ---------------------------------------------------------------- trang

function loadedBody(d, o) {
  const notes = [];
  if (d.status === 'inactive') notes.push(banner('warning', 'KH & NCC này sẽ không được chọn cho giao dịch mới.'));
  const desc = missingDescription(d);
  if (d.system) notes.push(banner('info', 'Đối tác hệ thống, dùng cho phiếu nhận mua lẻ. Không sửa hoặc xoá được.'));
  else if (desc && d.status === 'active') notes.push(banner('warning', 'Hồ sơ còn thiếu thông tin', desc));
  const left = [mainInfo(d), invoiceCard(d), deliveryCard(d), noteCard(d)];
  const right = [];
  if (!d.system && d.roles.includes('customer')) right.push(receivableCard(d, o.blocksLoading));
  if (d.type === 'organization') right.push(contactsCard(d, o.addMenu));
  if (!d.system && d.roles.includes('supplier')) {
    right.push(programsCard(d.programs || [], { loading: o.blocksLoading, error: o.programsError }), receiptsCard(d.receipts || [], { loading: o.blocksLoading }));
  }
  const cols = right.length
    ? `<div class="wd-cols"><div class="wd-stack">${left.join('')}</div><div class="wd-stack">${right.join('')}</div></div>`
    : `<div class="wd-cols wd-cols--one"><div class="wd-stack">${left.join('')}</div></div>`;
  return `${head(d, o.menu)}<div class="wd-scroll"${o.scrollEnd ? ' data-scroll-end' : ''}><div class="wd-wrap">${notes.length ? `<div class="wd-notes">${notes.join('')}</div>` : ''}${cols}</div></div>`;
}

function loadingBody() {
  const sk = (h, w = '100%', r = 4) => skeleton(h, { w, radius: r });
  const box = (n) => `<section class="wd-card">${sk(18, '40%')}<i class="t3-gap" style="height:16px"></i>${Array.from({ length: n }, () => sk(14, '80%')).join('<i class="t3-gap" style="height:12px"></i>')}</section>`;
  return `<header class="wd-head">${crumb}<div class="wd-head__row">${sk(56, '56px', 28)}<div class="wd-head__t">${sk(22, '280px')}<i class="t3-gap" style="height:8px"></i>${sk(14, '180px')}</div></div></header>
    <div class="wd-scroll"><div class="wd-wrap"><div class="wd-cols"><div class="wd-stack">${box(4)}${box(3)}</div><div class="wd-stack">${box(2)}${box(2)}</div></div></div></div>`;
}

export function detailPageWeb(o) {
  let body;
  if (o.kind === 'loading') body = loadingBody();
  else if (ERRORS[o.kind]) body = `<header class="wd-head wd-head--bare">${crumb}</header><div class="t3-form t3-form--center">${errorBody(o.kind)}</div>`;
  else body = loadedBody(DETAILS[o.id], o);
  return `<div class="t3-page wd">${body}</div>`;
}

// ---------------------------------------------------------------- Hộp xác nhận web — liệt kê hệ quả (chọn qua /impeccable live, 2026-11-27)
// Mẫu chung: tiêu đề + nút Đóng; các dòng hệ quả (icon theo tone); [banner]; "+ Thêm lý do (không bắt buộc)" thu gọn (mở ô lý do 0/200);
// nút canh phải "Hủy" | nút xác nhận theo tone (cảnh báo / nguy hiểm — không dùng nút xanh cho thao tác phá).
export function confirmDialogWeb({ title, items, warn = '', confirm, tone, reason = true }) {
  const li = ([cls, ic, text]) => `<li class="is-${cls}">${icon(ic)}${esc(text)}</li>`;
  return `<div class="sh-scrim sh-scrim--dialog"><section class="t3-dialog wdc" role="alertdialog" aria-modal="true" aria-label="${esc(title)}">
    <header class="wdc-top"><h2>${esc(title)}</h2><button type="button" class="wpc-x" aria-label="Đóng">${icon('close')}</button></header>
    <div class="wdc-body"><ul class="wdc-list">${items.map(li).join('')}</ul>
      ${warn ? `<div class="wdc-warn">${warn}</div>` : ''}${reason ? `<button type="button" class="wdc-add" aria-expanded="false">${icon('plus')}Thêm lý do (không bắt buộc)</button>` : ''}</div>
    <footer class="wdc-foot">${button('Hủy', { variant: 'secondary' })}${button(confirm, { tone })}</footer>
  </section></div>`;
}

/** "Ngừng hoạt động KH & NCC?" — primaryOf → banner liên hệ chính. */
export const deactivateDialogWeb = (primaryOf = null) => confirmDialogWeb({
  title: 'Ngừng hoạt động KH & NCC?',
  items: [['off', 'ban', 'KH & NCC này sẽ không còn được chọn cho giao dịch mới.'], ['keep', 'check', 'Hồ sơ và lịch sử vẫn được giữ lại.']],
  warn: primaryOf ? banner('warning', '', `Người này đang là liên hệ chính của “${primaryOf}”. Sau khi ngừng hoạt động, tổ chức sẽ không còn người liên hệ chính.`) : '',
  confirm: 'Ngừng hoạt động',
  tone: 'warning',
});

/** "Xóa hồ sơ KH & NCC?" */
export const softDeleteDialogWeb = () => confirmDialogWeb({
  title: 'Xóa hồ sơ KH & NCC?',
  items: [['del', 'trash', 'Hồ sơ sẽ bị xóa khỏi danh sách làm việc và không còn được chọn cho giao dịch mới.'], ['keep', 'check', 'Thao tác này không xóa giao dịch hoặc chứng từ đã phát sinh.']],
  confirm: 'Xóa hồ sơ',
  tone: 'danger',
});

// ---------------------------------------------------------------- Hộp cảnh báo canh trái (chọn qua /impeccable live, 2026-11-27)
// Biểu tượng tròn theo tone bên trái + tiêu đề + câu mô tả, một nút Đóng, nút canh phải. Dùng cho "Kích hoạt lại KH & NCC?".
export function alertDialogWeb({ ic, tone, title, desc, actions }) {
  return `<div class="sh-scrim sh-scrim--dialog"><section class="t3-dialog wrc" role="alertdialog" aria-modal="true" aria-label="${esc(title)}">
    <div class="wrc-top"><span class="wrc-ic wrc-ic--${tone}">${icon(ic)}</span><div><h2>${esc(title)}</h2>${desc}</div><button type="button" class="wpc-x" aria-label="Đóng">${icon('close')}</button></div>
    <footer class="wdc-foot">${actions}</footer></section></div>`;
}

/** "Kích hoạt lại KH & NCC?" */
export const reactivateDialogWeb = () => alertDialogWeb({
  ic: 'power', tone: 'success', title: 'Kích hoạt lại KH & NCC?',
  desc: '<p>KH &amp; NCC này sẽ có thể được chọn lại cho giao dịch mới.</p>',
  actions: `${button('Hủy', { variant: 'secondary' })}${button('Kích hoạt lại')}`,
});

/** "Không thể xóa hồ sơ" (có giao dịch). canDeactivate → thêm câu gợi ý + nút "Ngừng hoạt động". */
export const deleteBlockedDialogWeb = (canDeactivate) => alertDialogWeb({
  ic: 'alert', tone: 'warning', title: 'Không thể xóa hồ sơ',
  desc: `<p>KH &amp; NCC đã phát sinh giao dịch hoặc chứng từ liên quan nên không thể xóa.</p>${canDeactivate ? '<p>Bạn có thể ngừng hoạt động để tránh sử dụng trong giao dịch mới.</p>' : ''}`,
  actions: canDeactivate ? `${button('Quay lại', { variant: 'secondary' })}${button('Ngừng hoạt động', { tone: 'warning' })}` : button('Quay lại', { variant: 'secondary' }),
});

/** "Không thể xóa hồ sơ" (đang là liên hệ chính của tổ chức khác). */
export const deletePrimaryBlockedDialogWeb = (org) => alertDialogWeb({
  ic: 'trash', tone: 'danger', title: 'Không thể xóa hồ sơ',
  desc: `<p>Hồ sơ này đang là người liên hệ chính của “${esc(org)}”. Hãy đổi hoặc gỡ người liên hệ chính trước khi xóa hồ sơ.</p>`,
  actions: `${button('Đóng', { variant: 'secondary' })}${button('Xem tổ chức')}`,
});

/** "Không thể chuyển thành tổ chức" (đang là liên hệ chính của tổ chức khác). */
export const transformPrimaryBlockedDialogWeb = (org) => alertDialogWeb({
  ic: 'building', tone: 'warning', title: 'Không thể chuyển thành tổ chức',
  desc: `<p>Hồ sơ này đang là người liên hệ chính của “${esc(org)}”. Hãy đổi người liên hệ chính của tổ chức trước khi thực hiện chuyển đổi.</p>`,
  actions: `${button('Đóng', { variant: 'secondary' })}${button('Xem tổ chức')}`,
});
