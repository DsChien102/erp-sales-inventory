// PT-07 Hồ sơ KH & NCC — bố cục iPhone "Mở sẵn, kiểu danh bạ" (người dùng chọn qua /impeccable live, 2026-11-27).
// Đầu trang: avatar 56 + tên + "Loại · Vai trò" + chấm trạng thái; dòng nhanh SĐT / email / MST có icon. Thẻ Công nợ nổi ngay sau đầu
// (icon ví vàng, số tiền 16/700, "N đơn · Quá hạn N ngày"). Mọi mục mở sẵn: tiêu đề nhóm + thẻ trắng các dòng nhãn | giá trị kẻ mảnh
// (bỏ đóng / mở từng thẻ — lệch PartnerDetailExpandableCard). Khối NCC (Chương trình ưu đãi, Lịch sử nhập hàng) cùng kiểu thẻ;
// "Lịch sử thao tác" là dòng chevron cuối. Hàng nút đáy "Chỉnh sửa" (icon bút) | "Thao tác ˄"; đối tác hệ thống không có hàng nút.
// Chữ, nhãn, điều kiện hiện khối theo detail.js. CSS: styles/detail-mobile.css (tiền tố mdd-).
import { icon } from '../shared/icons.js';
import { banner, button, centerLoading, esc, initials, skeleton, textArea } from './ds.js';
import { DETAILS, ERRORS, errorBody, invoiceBadge, missingDescription, sheetActions } from './detail.js';

const roleText = (r) => (r.includes('customer') && r.includes('supplier') ? 'KH & NCC' : r.includes('customer') ? 'Khách hàng' : r.includes('supplier') ? 'Nhà cung cấp' : 'Chưa có vai trò');
const tag = (text, tone) => `<span class="mdd-tag mdd-tag--${tone}">${esc(text)}</span>`;
const kv = (label, value, mono = false) => `<div class="mdd-kv"><dt>${esc(label)}</dt><dd${mono ? ' class="is-mono"' : ''}>${value ? esc(value) : '<span class="mdd-dash">—</span>'}</dd></div>`;
// Ẩn ô trống (chọn qua /impeccable live 2026-11-27): chỉ vẽ dòng có giá trị; mục trống hẳn gom vào khối "Chưa có thông tin".
const kvs = (rows) => `<dl>${rows.filter(([, v]) => v).map(([l, v, m]) => kv(l, v, m)).join('')}</dl>`;
const allEmpty = (rows) => rows.every(([, v]) => !v);
const section = (title, body, extra = '') => `<section class="mdd-sec"><div class="mdd-sh"><h3>${esc(title)}</h3>${extra}</div><div class="mdd-card">${body}</div></section>`;
const seeAll = '<button type="button" class="mdd-link">Xem tất cả</button>';

function hero(d) {
  const st = d.status === 'active' ? '<span class="mdd-status"><i></i>Đang hoạt động</span>' : '<span class="mdd-status is-off"><i></i>Ngừng hoạt động</span>';
  return `<section class="mdd-hero"><span class="mdd-av" aria-hidden="true">${esc(initials(d.name))}</span><div class="mdd-hero__t"><h2>${esc(d.name)}</h2><p>${d.type === 'person' ? 'Cá nhân' : 'Tổ chức'} · ${esc(roleText(d.roles))}</p>${st}</div></section>`;
}

function quick(d) {
  const x = d.type === 'person' ? d.person : d.org;
  const items = [[x.phone, 'phone'], [x.email, 'mail'], [d.taxCode && `MST ${d.taxCode}`, 'receipt']].filter(([v]) => v);
  return items.length ? `<div class="mdd-quick">${items.map(([v, ic]) => `<span>${icon(ic)}${esc(v)}</span>`).join('')}</div>` : '';
}

/** Công nợ (Theme 6): đang tải → không vẽ; không nợ → "Không còn nợ"; quá hạn → nhãn vàng. */
function receivable(r) {
  if (!r || r.loading) return '';
  const has = !!r.owed;
  const due = has && r.overdue > 0 ? ` · <em>${icon('alert')}Quá hạn ${r.overdue} ngày</em>` : '';
  return `<button type="button" class="mdd-recv"><span class="mdd-recv__ic${has ? '' : ' is-ok'}">${icon('wallet')}</span><span class="mdd-recv__t"><small>Công nợ</small><b>${has ? `Còn nợ ${esc(r.owed)}` : 'Không còn nợ'}</b>${has ? `<span>${r.orders} đơn${due}</span>` : ''}</span>${icon('chevronRight')}</button>`;
}

function mainInfo(d) {
  const p = d.person; const o = d.org;
  const rows = d.type === 'person'
    ? [['Danh xưng', p.title], ['Họ và tên', p.fullName], ['Tên thường gọi', p.nickname], ['SĐT chính', p.phone], ['SĐT phụ', p.phone2], ['Email', p.email]]
    : [['Loại tổ chức', o.type], ['Tên tổ chức', o.name], ['Tên viết tắt', o.shortName], ['Tên quốc tế', o.intlName], ['SĐT chính', o.phone], ['Email', o.email]];
  return section(d.type === 'person' ? 'Thông tin cá nhân' : 'Thông tin tổ chức', kvs(rows));
}

function contacts(d) {
  const n = d.contacts.length;
  const list = n
    ? `<ul class="mdd-list">${[...d.contacts].sort((a, b) => (b.primary ? 1 : 0) - (a.primary ? 1 : 0)).slice(0, 2).map((c) => `<li><span class="mdd-cav" aria-hidden="true">${esc(initials(c.name))}</span><div><b>${esc(c.name)}${c.primary ? '<span class="mdd-chip">Chính</span>' : ''}</b><small>${esc([c.role, c.phone, c.email].filter(Boolean).join(' · '))}</small></div></li>`).join('')}</ul>`
    : '<p class="mdd-empty">Chưa có người liên hệ.</p>';
  const acts = `<div class="mdd-acts"><button type="button">${icon('plusCircle')}<span>Thêm người liên hệ</span></button><button type="button"><span>${n ? `Xem tất cả (${n})` : 'Tất cả'}</span>${icon('chevronRight')}</button></div>`;
  return section('Người liên hệ', list + acts, n ? `<span class="mdd-count">${n}</span>` : tag('Chưa có', 'warning'));
}

const invoiceRows = (d) => [['MST', d.taxCode, true], ['Tên xuất hóa đơn', d.invoice.name], ['Email nhận hóa đơn', d.invoice.email], ['Địa chỉ xuất hóa đơn', d.invoice.address]];
const deliveryRows = (d) => [['Tỉnh / Thành phố', d.delivery.province], ['Xã / Phường', d.delivery.commune], ['Địa chỉ chi tiết', d.delivery.address]];

/** Ba mục có thể trống hẳn: [tiêu đề, trống?, html khi có, chữ phụ đỏ khi trống]. */
function optionalSections(d) {
  const b = invoiceBadge(d);
  return [
    ['Hóa đơn / thuế', allEmpty(invoiceRows(d)), () => section('Hóa đơn / thuế', kvs(invoiceRows(d)), b ? tag(b, 'danger') : ''), b],
    ['Địa chỉ giao hàng', allEmpty(deliveryRows(d)), () => section('Địa chỉ giao hàng', kvs(deliveryRows(d)))],
    ['Ghi chú', !d.note, () => section('Ghi chú', `<p class="mdd-note">${esc(d.note)}</p>`)],
  ];
}

/** Khối "Chưa có thông tin": mỗi mục trống một dòng; được sửa → "+ Thêm" (mở màn sửa), không (đối tác hệ thống) → "Chưa có". */
function emptyGroup(items, canEdit) {
  if (!items.length) return '';
  const trail = canEdit ? `<em>${icon('plus')}Thêm</em>` : '<em class="is-off">Chưa có</em>';
  return section('Chưa có thông tin', items.map(([t, , , sub]) => `<button type="button" class="mdd-erow"${canEdit ? '' : ' disabled'}><span><b>${esc(t)}</b>${sub ? `<small>${esc(sub)}</small>` : ''}</span>${trail}</button>`).join(''));
}

/** Banner thiếu thông tin có nút "Bổ sung" (mở màn sửa). */
const missingBanner = (desc) => `<div class="mdd-warn" role="status"><span class="mdd-warn__ic">${icon('alert')}</span><div><b>Hồ sơ còn thiếu thông tin</b><p>${esc(desc.trim())}</p></div><button type="button" class="mdd-warn__btn">Bổ sung</button></div>`;

/** Chương trình ưu đãi (Theme 7): đang tải → khối xám; lỗi → câu + "Thử lại"; rỗng → câu + "Tạo chương trình"; có → dòng tên · loại · tóm tắt + nhãn. */
function programs(list, { loading = false, error = false } = {}) {
  let body;
  if (loading) body = `<div class="mdd-pad">${skeleton(44, { radius: 4 })}</div>`;
  else if (error) body = `<div class="mdd-pad mdd-row2"><p>Không tải được chương trình ưu đãi.</p>${button('Thử lại', { variant: 'tertiary' })}</div>`;
  else if (!list.length) body = `<div class="mdd-pad"><p class="mdd-muted">Chưa có chương trình đang chạy.</p>${button('Tạo chương trình', { variant: 'tertiary', cls: 't3-btn--lead mdd-create' }).replace('<span>', `${icon('plus')}<span>`)}</div>`;
  else {
    body = `<ul class="mdd-list">${list.map((p) => {
      const below = p.progress
        ? `<span class="mdd-prog"><span class="mdd-prog__bar"><i style="width:${Math.min(1, p.progress[0]) * 100}%"></i></span><span class="is-mono">${esc(p.progress[1])}</span></span>`
        : `<small>${esc(p.summary)}</small>`;
      return `<li><div><b>${esc(p.name)}</b><small>${esc(p.kind)}</small>${below}</div><span class="t3-badge t3-badge--${p.status[1]} t3-badge--sm">${esc(p.status[0])}</span></li>`;
    }).join('')}</ul>`;
  }
  return section('Chương trình ưu đãi', body, seeAll);
}

/** Lịch sử nhập hàng (Theme 7): đang tải → vòng xoay; rỗng / lỗi → một dòng chữ; có → dòng số phiếu · ngày · dòng (lô) | tổng tiền. */
function receipts(list, { loading = false } = {}) {
  if (loading) return section('Lịch sử nhập hàng', `<div class="mdd-pad">${centerLoading({ material: true })}</div>`);
  if (!list.length) return `<p class="mdd-plain">Chưa có lịch sử nhập hàng từ nhà cung cấp này.</p>`;
  return section('Lịch sử nhập hàng', `<ul class="mdd-list">${list.map((r) => `<li class="is-tap"><div><b class="is-mono">${esc(r.no)}</b><small>${esc(r.date)} · ${r.lines} dòng (${r.lots} lô)</small></div><strong class="is-mono">${esc(r.total)}</strong>${icon('chevronRight')}</li>`).join('')}</ul>`, seeAll);
}

function loaded(d, o) {
  const desc = missingDescription(d);
  const parts = [hero(d), quick(d)];
  if (d.status === 'inactive') parts.push(banner('warning', 'KH & NCC này sẽ không được chọn cho giao dịch mới.'));
  if (d.system) parts.push(banner('info', 'Đối tác hệ thống, dùng cho phiếu nhận mua lẻ. Không sửa hoặc xoá được.'));
  else if (desc && d.status === 'active') parts.push(missingBanner(desc));
  if (!d.system && d.roles.includes('customer')) parts.push(receivable(o.blocksLoading ? { loading: true } : d.receivable));
  parts.push(mainInfo(d));
  if (d.type === 'organization') parts.push(contacts(d));
  const opt = optionalSections(d);
  parts.push(...opt.filter(([, empty]) => !empty).map(([, , html]) => html()));
  parts.push(emptyGroup(opt.filter(([, empty]) => empty), !d.system && d.actions.includes('update')));
  if (!d.system && d.roles.includes('supplier')) parts.push(programs(d.programs || [], { loading: o.blocksLoading, error: o.programsError }), receipts(d.receipts || [], { loading: o.blocksLoading }));
  parts.push(`<button type="button" class="mdd-rowlink">${icon('settings')}<span>Lịch sử thao tác</span>${icon('chevronRight')}</button>`);
  const bar = d.system ? '' : `<footer class="mdd-foot">${button('Chỉnh sửa', { variant: 'secondary', full: true, disabled: !d.actions.includes('update') }).replace('<span>', `${icon('edit')}<span>`)}${button('Thao tác', { full: true, cls: 't3-btn--trail' }).replace('</span></button>', `</span>${icon('chevronUp')}</button>`)}</footer>`;
  return `<div class="mdd-scroll"${o.scrollEnd ? ' data-scroll-end' : ''}>${parts.filter(Boolean).join('')}</div>${bar}`;
}

function skeletonBody() {
  const sec = (rows) => `<div class="mdd-sec">${skeleton(16, { w: '120px', radius: 4 })}<div class="mdd-card mdd-skcard">${Array.from({ length: rows }, () => `<div class="mdd-skrow">${skeleton(12, { w: '96px', radius: 4 })}${skeleton(14, { w: '55%', radius: 4 })}</div>`).join('')}</div></div>`;
  return `<div class="mdd-scroll" aria-hidden="true"><div class="mdd-hero">${skeleton(56, { w: '56px', radius: 28 })}<div class="mdd-hero__t">${skeleton(18, { w: '180px', radius: 4 })}${skeleton(14, { w: '120px', radius: 4 })}${skeleton(12, { w: '90px', radius: 4 })}</div></div>${skeleton(68, { radius: 12 })}${sec(4)}${sec(3)}</div>`;
}

/** PartnerDetailPage khổ iPhone (không chia cột). Lỗi / không tìm thấy / không có quyền giữ errorBody của detail.js. */
export function detailPageMobile(o) {
  const head = `<header class="mdd-bar"><button type="button" class="mdd-back" aria-label="Quay lại">${icon('chevronLeft')}</button><h1>Hồ sơ KH &amp; NCC</h1></header>`;
  let body;
  if (o.kind === 'loading') body = skeletonBody();
  else if (ERRORS[o.kind]) body = `<div class="t3-form t3-form--center">${errorBody(o.kind)}</div>`;
  else body = loaded(DETAILS[o.id], o);
  return `<div class="t3-page mdd">${head}${body}</div>`;
}

/**
 * Sheet "Thao tác hồ sơ" khổ iPhone (chọn qua /impeccable live 2026-11-27): tiêu đề 18/700 + nút Đóng (X) 44 thay nút "Hủy";
 * các thao tác thường (Chuyển thành tổ chức, Ngừng hoạt động / Kích hoạt lại) chung một khối trắng kẻ mảnh;
 * "Xóa hồ sơ" chữ đỏ tách khối riêng bên dưới. Điều kiện hiện từng thao tác: sheetActions (detail.js).
 */
export function actionSheetMobile(d) {
  const a = sheetActions(d);
  const inactive = d.status === 'inactive';
  const row = (ic, tone, title, sub, cls = '') => `<button type="button" class="mda-row ${cls}"><span class="mda-ic mda-ic--${tone}">${icon(ic)}</span><span class="mda-t"><b>${esc(title)}</b><small>${esc(sub)}</small></span>${icon('chevronRight')}</button>`;
  const main = [
    a.transform ? row('building', 'success', 'Chuyển thành tổ chức', 'Chuyển hồ sơ cá nhân hiện tại sang hồ sơ tổ chức.') : '',
    a.toggle ? (inactive ? row('power', 'success', 'Kích hoạt lại', 'Cho phép sử dụng lại trong hệ thống.') : row('pause', 'warning', 'Ngừng hoạt động', 'Tạm ngừng sử dụng trong hệ thống.')) : '',
  ].join('');
  return `<div class="t3-actsheet mda">
    <header class="mda-head"><h2>Thao tác hồ sơ</h2><button type="button" class="mda-x" aria-label="Đóng">${icon('close')}</button></header>
    ${main ? `<div class="mda-group">${main}</div>` : ''}
    ${a.del ? `<div class="mda-group">${row('trash', 'danger', 'Xóa hồ sơ', 'Xóa mềm, không hiển thị trong danh sách.', 'is-danger')}</div>` : ''}
  </div>`;
}

/**
 * Sheet "Ngừng hoạt động KH & NCC?" khổ iPhone (chọn qua /impeccable live 2026-11-27): căn trái; đầu sheet ô icon tròn vàng 40 + tiêu đề 18/700
 * + nút Đóng (X); hai dòng hậu quả (⊘ không còn được chọn cho giao dịch mới / ✓ hồ sơ và lịch sử vẫn giữ); [banner liên hệ chính];
 * "Lý do (không bắt buộc)" + ô 3 dòng + "0/200"; "Hủy" | "Ngừng hoạt động" (nút chính xanh, như đặc tả).
 */
export function deactivateSheetMobile(primaryOf = null) {
  // Câu nằm cùng hàng icon (bản Flutter để tiêu đề rỗng → hàng icon trơ, câu thụt xuống dòng dưới).
  const warn = primaryOf ? `<div class="mdc-warn" role="status">${icon('alert')}<p>Người này đang là liên hệ chính của “${esc(primaryOf)}”. Sau khi ngừng hoạt động, tổ chức sẽ không còn người liên hệ chính.</p></div>` : '';
  return `<div class="t3-confirm mdc">
    <header class="mdc-head"><span class="mdc-ic">${icon('pause')}</span><h2>Ngừng hoạt động KH &amp; NCC?</h2><button type="button" class="mdc-x" aria-label="Đóng">${icon('close')}</button></header>
    <ul class="mdc-cons"><li>${icon('ban')}<span>KH &amp; NCC này sẽ không còn được chọn cho giao dịch mới.</span></li><li class="is-ok">${icon('checkCircle')}<span>Hồ sơ và lịch sử vẫn được giữ lại.</span></li></ul>
    ${warn}
    <div class="mdc-reason"><span class="mdc-label">Lý do (không bắt buộc)</span>${textArea({ hint: 'Nhập lý do (nếu có)', minLines: 3 })}<span class="mdc-count">0/200</span></div>
    <div class="mdc-btns">${button('Hủy', { variant: 'secondary', full: true })}${button('Ngừng hoạt động', { full: true })}</div>
  </div>`;
}

/** Sheet "Kích hoạt lại KH & NCC?" khổ iPhone (chọn qua /impeccable live 2026-11-27): cùng mẫu sheet ngừng — ô icon nguồn tròn xanh + tiêu đề + X; một dòng ✓; "Hủy" | "Kích hoạt lại". */
export const reactivateSheetMobile = () => `<div class="t3-confirm mdc">
  <header class="mdc-head"><span class="mdc-ic mdc-ic--ok">${icon('power')}</span><h2>Kích hoạt lại KH &amp; NCC?</h2><button type="button" class="mdc-x" aria-label="Đóng">${icon('close')}</button></header>
  <ul class="mdc-cons"><li class="is-ok">${icon('checkCircle')}<span>KH &amp; NCC này sẽ có thể được chọn lại cho giao dịch mới.</span></li></ul>
  <div class="mdc-btns">${button('Hủy', { variant: 'secondary', full: true })}${button('Kích hoạt lại', { full: true })}</div>
</div>`;
