// ID-20 Lịch sử quản trị (danh sách + chi tiết). Chép từ apps/erp/lib/features/iam/presentation/audit_logs/{audit_area_shell.dart,
//   views/organization_audit_logs_page.dart, views/audit_log_detail_page.dart, widgets/*.dart, mappers/tenant_audit_ui_mapper.dart}.
// /more/audit-logs(/:id): ShellRoute riêng (AuditAreaShell → VListDetailLayout), ngoài StoreShell.
// Khác các màn IAM khác: danh sách là Scaffold thường (nền surfaceAlt, không cột tối đa); chi tiết Flutter dùng AppBar Material; prototype iPhone dùng VAppBar chung (2026-11-25).
import { icon } from '../shared/icons.js';
import { AUDIT, AUDIT_TOTAL, TRACE_ID } from './admin-data.js';
import { adaptiveSheet, appBar, badge, button, card, centerLoading, chip, chipRow, esc, iconButton, isSplit, listDetail, searchBar, splitPlaceholder, toast } from './ds.js';
import { warnBox } from './org.js';

export const AUDIT_STATES = {
  list: {}, 'chip-member': { category: 'Thành viên' }, loading: { loading: true }, empty: { empty: true }, 'no-results': { query: 'xoá dữ liệu', noResults: true },
  error: { error: true }, forbidden: { forbidden: true }, filter: { sheet: true }, 'filter-applied': { days: 7 },
};
export const AUDIT_DETAIL_STATES = { detail: { id: 'a1' }, 'actor-unavailable': { id: 'a6' }, loading: { id: 'a1', loading: true }, 'not-found': { id: 'a1', notFound: true }, 'toast-copied': { id: 'a1', toast: true } };

/**
 * Dòng lịch sử (iPhone, impeccable live 2026-11-25): giờ 40 | tiêu đề w600 (+ nhãn "Thông tin hiện tại"), "người (vai trò)", "<loại đối tượng>: <tên>" | mũi tên.
 * Gộp theo ngày: tiêu đề ngày + một thẻ chứa các dòng trong ngày (giữ thứ tự mới nhất trước).
 */
const auditRow = (a, selected) => `<button type="button" class="t1-aday__row"${selected ? ' aria-current="true"' : ''}><span class="t1-aday__time">${esc(a.at.split(' ')[1])}</span><span class="t1-aday__text">
  <span class="t1-aday__name"><b>${esc(a.title)}</b>${a.legacy ? badge('Thông tin hiện tại', 'neutral') : ''}</span>
  <span>${esc(a.actorRole && a.actorRole !== '—' ? `${a.actor} (${a.actorRole})` : a.actor)}</span>
  <span>${esc(`${a.subjectType}: ${a.subject}`)}</span></span>${icon('chevronRight', 't1-aday__go')}</button>`;
const auditDays = (items, selected) => [...new Set(items.map((a) => a.at.split(' ')[0]))].map((d) => `<section class="t1-aday"><h2 class="t1-aday__title">${esc(d)}</h2>
  <div class="t1-aday__box">${items.filter((a) => a.at.startsWith(d)).map((a) => auditRow(a, a.id === selected)).join('')}</div></section>`).join('');

/** AuditLogEmptyView: Align(0, −0.75); đệm ngang 16; VCard đệm 24; vòng 64 + icon 28; khe 16; H3 w700; khe 8; bodyDefault; khe 16; link. */
const EMPTY = {
  empty: ['info', '', 'Chưa có hoạt động quản trị', 'Các thay đổi người dùng, vai trò và thiết lập sẽ được ghi lại tại đây.', 'Tải lại'],
  noResults: ['search', '', 'Không có hoạt động phù hợp', 'Thử thay đổi từ khóa hoặc bộ lọc đang áp dụng.', 'Xóa bộ lọc'],
  error: ['error', 'danger', 'Không thể tải lịch sử quản trị', 'Đã xảy ra lỗi khi tải dữ liệu. Vui lòng thử lại.', 'Thử lại'],
  forbidden: ['shield', 'warning', 'Bạn không có quyền xem lịch sử quản trị', 'Liên hệ Chủ sở hữu hoặc người có quyền quản trị để được cấp quyền.', 'Quay lại'],
};
export const auditEmpty = (k) => {
  const [ic, tone, title, desc, act] = EMPTY[k];
  return `<div class="t1-aempty"><div class="t1-card t1-oempty__card"><span class="t1-ring${tone ? ` t1-ring--${tone}` : ''}">${icon(ic)}</span><div class="t1-gap-md"></div>
    <h2 class="t1-h3 t1-text-center${tone === 'danger' ? ' t1-danger' : ''}">${esc(title)}</h2><div class="t1-gap-sm"></div><p class="t1-body2 t1-text-center">${esc(desc)}</p><div class="t1-gap-md"></div>${button(act, { variant: 'link' })}</div></div>`;
};

function auditList(s, selected) {
  const days = s.days || 30;
  const sub = s.forbidden ? 'Chưa được cấp quyền' : s.error ? 'Không tải được dữ liệu' : `${s.empty || s.noResults ? 0 : AUDIT_TOTAL} hoạt động trong ${days} ngày`;
  let items = AUDIT;
  if (s.category === 'Thành viên') items = AUDIT.filter((a) => ['a3', 'a5'].includes(a.id));
  let list;
  if (s.forbidden) list = auditEmpty('forbidden');
  else if (s.loading) list = centerLoading();
  else if (s.error) list = auditEmpty('error');
  else if (s.empty) list = auditEmpty('empty');
  else if (s.noResults) list = auditEmpty('noResults');
  else list = `<div class="t1-alist t1-alist--days">${auditDays(items, selected)}<div class="t1-more">${button('Tải thêm', { variant: 'secondary' })}</div></div>`;
  return `<div class="t1-page t1-page--canvas">${appBar('Lịch sử quản trị', { back: true, subtitle: sub })}
    <div class="t1-fixed"><div class="t1-utop"><div class="t1-utop__find">${searchBar('Tìm người thực hiện hoặc hoạt động', s.query || '')}${iconButton('tune', days !== 30 ? 'Bộ lọc (đang áp dụng)' : 'Bộ lọc', { size: 20, dot: days !== 30 })}</div>
    <div class="t1-utop__chips">${chipRow(['Tất cả', 'Thành viên', 'Vai trò', 'Tổ chức'], s.category || 'Tất cả')}</div></div>
    <div class="t1-ulistwrap"><p class="t1-small t1-atimem">Thời gian: ${days} ngày gần đây · Mới nhất trước</p>${list}</div></div></div>`;
}

/** AuditLogFilterBottomSheet (title "Bộ lọc nhật ký nền tảng"): đệm 16 / 16 / 16 / 24; nhóm w700 + khe 8 + VChip; khe 16; khe 24; Đặt lại | 12 | Áp dụng. */
export const auditFilter = () => {
  const g = (t, opts, sel) => `<div class="t1-fgroup t1-fgroup--8"><b>${esc(t)}</b><div class="t1-fwrap">${opts.map((o) => chip(o, { tone: o === sel ? 'primary' : 'neutral' })).join('')}</div></div>`;
  return `<div class="t1-fsheet">${g('Thời gian', ['24 giờ', '7 ngày', '30 ngày'], '30 ngày')}${g('Kết quả', ['Tất cả', 'Thành công', 'Bị chặn', 'Lỗi'], 'Tất cả')}${g('Loại chủ thể', ['Tất cả', 'Người dùng', 'Hệ thống'], 'Tất cả')}
    <div class="t1-row2 t1-row2--12 t1-fsheet__acts">${button('Đặt lại', { variant: 'secondary', full: true })}${button('Áp dụng', { full: true })}</div></div>`;
};

/** AppBar Material: cao 56, nền surface, không gạch dưới; leading ← 56 (hẹp) + titleSpacing 0 / web không leading + titleSpacing 16; tiêu đề headingH4 w700. */
export const materialBar = (split) => `<header class="t1-mbar${split ? ' t1-mbar--split' : ''}">${split ? '' : `<button type="button" class="t1-mbar__back" aria-label="Quay lại">${icon('chevronLeft')}</button>`}<h1 class="t1-h4">Chi tiết hoạt động</h1></header>`;

/**
 * AuditDetailRow: giá trị ≤ 24 ký tự, một dòng → nhãn bodyDefault textSecondary ↔ giá trị bodyDefault w700 phải (+ nút sao chép 44, icon 18).
 * Dài hơn 24 ký tự (hoặc nhiều dòng) → xếp dọc: hàng nhãn (+ nút sao chép), khe 4, giá trị w700 canh trái, cao dòng 1.4 (monospace nếu sao chép được).
 */
export const arow = (l, val, copy = false) => {
  const btn = copy ? `<button type="button" class="t1-copy" aria-label="Sao chép mã theo dõi">${icon('copy')}</button>` : '';
  if (val.length > 24 || val.includes('\n')) return `<div class="t1-drow t1-drow--block"><div class="t1-drow__head"><span>${esc(l)}</span>${btn}</div><b${copy ? ' class="is-mono"' : ''}>${esc(val)}</b></div>`;
  return `<div class="t1-drow"><span>${esc(l)}</span><b>${esc(val)}${btn}</b></div>`;
};
/**
 * Một phần của thẻ chi tiết (iPhone, impeccable live 2026-11-25): tiêu đề w600 (+ nhãn), các dòng nhãn bodyDefault textSecondary ↔ giá trị w600 phải.
 * Mã theo dõi: nhãn trên, mã monospace dưới, nút sao chép 44 bên phải; mã sự kiện thô ở cuối phần truy vết.
 */
const part = (title, inner, b = '') => `<section class="t1-adm__part"><div class="t1-dhead"><h3 class="t1-h4 t1-h4--600">${esc(title)}</h3>${b}</div>${inner}</section>`;
const prow = (l, val) => `<div class="t1-adm__row"><span>${esc(l)}</span><b>${esc(val)}</b></div>`;
const traceRow = () => `<div class="t1-adm__trace"><div><span>Mã theo dõi</span><b>${esc(TRACE_ID)}</b></div><button type="button" class="t1-adm__copy" aria-label="Sao chép mã theo dõi">${icon('copy')}</button></div>`;

function auditDetail(s, split, device) {
  const wrap = (body, t = '') => `<div class="t1-page t1-page--canvas">${split ? materialBar(split) : appBar('Chi tiết hoạt động', { back: true })}<div class="t1-scroll">${body}</div>${t}</div>`;
  if (s.loading) return wrap(centerLoading());
  if (s.notFound) return wrap(`<div class="t1-center"><div class="t1-failed2"><h2 class="t1-h4 t1-h4--600">Không tìm thấy hoạt động</h2><div class="t1-gap-sm"></div><p class="t1-small t1-text-center">Nhật ký không tồn tại hoặc không thuộc tổ chức hiện tại.</p><div class="t1-gap-lg"></div>${button('Thử lại')}</div></div>`);
  const a = AUDIT.find((x) => x.id === s.id);
  const gone = badge('Không còn dữ liệu', 'warning');
  // Thứ tự: đầu màn (ô biểu tượng + tên hoạt động + "người · thời điểm") → nhãn kết quả → hộp vàng (không còn người thực hiện) → một thẻ: Dữ liệu thay đổi · Ngữ cảnh · Đối tượng · Thông tin truy vết.
  const changes = a.changes ? part('Dữ liệu thay đổi', a.changes.map(([f, before, after]) => `<div class="t1-adm__change"><span>${esc(f)}</span><span>Trước: ${esc(before)}</span><b>Sau: ${esc(after)}</b></div>`).join('')) : '';
  const body = `<div class="t1-list t1-adm">
    <div class="t1-orgm__head"><div class="t1-orgm__icon" aria-hidden="true">${icon(a.icon)}</div><div><h2>${esc(a.title)}</h2><p>${esc(`${a.actor} · ${a.at}`)}</p></div></div>
    <div class="t1-adm__result">${badge('Thành công', 'success')}</div>
    ${a.actorUnavailable ? `<div class="t1-adm__warn">${warnBox('Không còn thông tin người thực hiện', 'Thông tin người thực hiện không còn khả dụng tại thời điểm xem.')}</div>` : ''}
    ${card(`${changes}
      ${part('Ngữ cảnh', prow('Người thực hiện', a.actor) + prow('Loại chủ thể', a.actorRole), a.actorUnavailable ? gone : '')}
      ${part('Đối tượng', prow(a.subjectType, a.subject) + (a.subjectId ? prow('ID đối tượng', a.subjectId) : ''), a.legacy ? badge('Thông tin hiện tại', 'neutral') : '')}
      ${part('Thông tin truy vết', `${prow('Thời điểm', a.at.replace(' ', ' · '))}${prow('Nguồn', 'Tenant App')}${traceRow()}<p class="t1-adm__code">${esc(a.code)}</p>`)}`, 't1-adm__card')}
  </div>`;
  return wrap(body, s.toast ? toast('success', 'Đã sao chép', 'req_7f3a9c21e0b4d6a8b1e5f3c8d19f02', { device }) : '');
}

export function auditPage(v) {
  const s = AUDIT_STATES[v.state];
  const overlay = s.sheet ? adaptiveSheet(v.width, auditFilter(), '', { title: 'Bộ lọc nhật ký nền tảng' }) : '';
  if (!isSplit(v.width)) return { page: auditList(s), overlay };
  return { page: listDetail(v.width, auditList(s), splitPlaceholder('Chọn một mục lịch sử để xem chi tiết.')), overlay };
}

export function auditDetailPage(v) {
  const s = AUDIT_DETAIL_STATES[v.state];
  const split = isSplit(v.width);
  if (!split) return { page: auditDetail(s, false, v.device) };
  return { page: listDetail(v.width, auditList({}, s.id), auditDetail(s, true, v.device)) };
}
