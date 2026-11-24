// ID-20 Lịch sử quản trị (danh sách + chi tiết). Chép từ apps/erp/lib/features/iam/presentation/audit_logs/{audit_area_shell.dart,
//   views/organization_audit_logs_page.dart, views/audit_log_detail_page.dart, widgets/*.dart, mappers/tenant_audit_ui_mapper.dart}.
// /more/audit-logs(/:id): ngoài StoreShell. Web (thiết kế lại qua impeccable live 2026-11-24): bảng toàn màn, chi tiết toàn màn có ←.
// Khác các màn IAM khác: danh sách là Scaffold thường (nền surfaceAlt, không cột tối đa); chi tiết dùng AppBar Material (không VAppBar).
import { icon } from '../shared/icons.js';
import { AUDIT, AUDIT_TOTAL, TRACE_ID } from './admin-data.js';
import { adaptiveSheet, appBar, badge, button, centerLoading, chip, chipRow, esc, iconButton, isSplit, searchBar, skeleton, toast, vcard } from './ds.js';

export const AUDIT_STATES = {
  list: {}, 'chip-member': { category: 'Thành viên' }, loading: { loading: true }, empty: { empty: true }, 'no-results': { query: 'xoá dữ liệu', noResults: true },
  error: { error: true }, forbidden: { forbidden: true }, filter: { sheet: true }, 'filter-applied': { days: 7 },
};
export const AUDIT_DETAIL_STATES = { detail: { id: 'a1' }, 'actor-unavailable': { id: 'a6' }, loading: { id: 'a1', loading: true }, 'not-found': { id: 'a1', notFound: true }, 'toast-copied': { id: 'a1', toast: true } };

/** AuditLogItemCard: VCard nền surface (chọn → chỉ đổi viền) đệm 16; icon 20 + khe 16; tiêu đề w700 (+ badge "Thông tin hiện tại"); "người (vai trò) · thời điểm"; "Loại đối tượng: <tên>". */
const auditCard = (a, selected) => vcard(`<div class="t1-arow">${icon(a.icon, 't1-arow__ic')}<div class="t1-arow__text">
  <div class="t1-arow__title"><b>${esc(a.title)}</b>${a.legacy ? badge('Thông tin hiện tại', 'neutral') : ''}</div>
  <span>${esc(a.actorRole && a.actorRole !== '—' ? `${a.actor} (${a.actorRole}) · ${a.at}` : `${a.actor} · ${a.at}`)}</span>
  <span>${esc(`${a.subjectType}: ${a.subject}`)}</span></div></div>`, { selected, keepBg: true });

/** AuditLogEmptyView: Align(0, −0.75); đệm ngang 16; VCard đệm 24; vòng 64 + icon 28; khe 16; H3 w700; khe 8; bodyDefault; khe 16; link. */
const EMPTY = {
  empty: ['info', '', 'Chưa có hoạt động quản trị', 'Các thay đổi người dùng, vai trò và thiết lập sẽ được ghi lại tại đây.', 'Tải lại'],
  noResults: ['search', '', 'Không có hoạt động phù hợp', 'Thử thay đổi từ khóa hoặc bộ lọc đang áp dụng.', 'Xóa bộ lọc'],
  error: ['error', 'danger', 'Không thể tải lịch sử quản trị', 'Đã xảy ra lỗi khi tải dữ liệu. Vui lòng thử lại.', 'Thử lại'],
  forbidden: ['shield', 'warning', 'Bạn không có quyền xem lịch sử quản trị', 'Liên hệ Chủ sở hữu hoặc người có quyền quản trị để được cấp quyền.', 'Quay lại'],
};
const auditEmpty = (k) => {
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
  else list = `<div class="t1-alist">${items.map((a) => auditCard(a, a.id === selected)).join('')}<div class="t1-more">${button('Tải thêm', { variant: 'secondary' })}</div></div>`;
  return `<div class="t1-page t1-page--canvas">${appBar('Lịch sử quản trị', { back: true, subtitle: sub })}
    <div class="t1-fixed"><div class="t1-ubar t1-ubar--canvas">${searchBar('Tìm người thực hiện hoặc hoạt động', s.query || '')}${iconButton('tune', days !== 30 ? 'Bộ lọc (đang áp dụng)' : 'Bộ lọc', { size: 20, dot: days !== 30 })}</div>
    <div class="t1-achips">${chipRow(['Tất cả', 'Thành viên', 'Vai trò', 'Tổ chức'], s.category || 'Tất cả')}</div>
    <p class="t1-small t1-atime">Thời gian: ${days} ngày gần đây · Mới nhất trước</p>
    <div class="t1-ulistwrap">${list}</div></div></div>`;
}

/** AuditLogFilterBottomSheet (title "Bộ lọc nhật ký nền tảng"): đệm 16 / 16 / 16 / 24; nhóm w700 + khe 8 + VChip; khe 16; khe 24; Đặt lại | 12 | Áp dụng. */
const auditFilter = () => {
  const g = (t, opts, sel) => `<div class="t1-fgroup t1-fgroup--8"><b>${esc(t)}</b><div class="t1-fwrap">${opts.map((o) => chip(o, { tone: o === sel ? 'primary' : 'neutral' })).join('')}</div></div>`;
  return `<div class="t1-fsheet">${g('Thời gian', ['24 giờ', '7 ngày', '30 ngày'], '30 ngày')}${g('Kết quả', ['Tất cả', 'Thành công', 'Bị chặn', 'Lỗi'], 'Tất cả')}${g('Loại chủ thể', ['Tất cả', 'Người dùng', 'Hệ thống'], 'Tất cả')}
    <div class="t1-row2 t1-row2--12 t1-fsheet__acts">${button('Đặt lại', { variant: 'secondary', full: true })}${button('Áp dụng', { full: true })}</div></div>`;
};

/** AppBar Material: cao 56, nền surface, không gạch dưới; leading ← 56 (hẹp) + titleSpacing 0 / web không leading + titleSpacing 16; tiêu đề headingH4 w700. */
const materialBar = (split) => `<header class="t1-mbar${split ? ' t1-mbar--split' : ''}">${split ? '' : `<button type="button" class="t1-mbar__back" aria-label="Quay lại">${icon('chevronLeft')}</button>`}<h1 class="t1-h4">Chi tiết hoạt động</h1></header>`;

/**
 * AuditDetailRow: giá trị ≤ 24 ký tự, một dòng → nhãn bodyDefault textSecondary ↔ giá trị bodyDefault w700 phải (+ nút sao chép 44, icon 18).
 * Dài hơn 24 ký tự (hoặc nhiều dòng) → xếp dọc: hàng nhãn (+ nút sao chép), khe 4, giá trị w700 canh trái, cao dòng 1.4 (monospace nếu sao chép được).
 */
const arow = (l, val, copy = false) => {
  const btn = copy ? `<button type="button" class="t1-copy" aria-label="Sao chép mã theo dõi">${icon('copy')}</button>` : '';
  if (val.length > 24 || val.includes('\n')) return `<div class="t1-drow t1-drow--block"><div class="t1-drow__head"><span>${esc(l)}</span>${btn}</div><b${copy ? ' class="is-mono"' : ''}>${esc(val)}</b></div>`;
  return `<div class="t1-drow"><span>${esc(l)}</span><b>${esc(val)}${btn}</b></div>`;
};
const secHead = (t, b = '') => `<div class="t1-dhead"><b class="t1-bodyb">${esc(t)}</b>${b}</div><div class="t1-gap-md"></div>`;

function auditDetail(s, split, device) {
  const wrap = (body, t = '') => `<div class="t1-page t1-page--canvas">${materialBar(split)}<div class="t1-scroll">${body}</div>${t}</div>`;
  if (s.loading) return wrap(centerLoading());
  if (s.notFound) return wrap(`<div class="t1-center"><div class="t1-failed2"><h2 class="t1-h4 t1-h4--600">Không tìm thấy hoạt động</h2><div class="t1-gap-sm"></div><p class="t1-small t1-text-center">Nhật ký không tồn tại hoặc không thuộc tổ chức hiện tại.</p><div class="t1-gap-lg"></div>${button('Thử lại')}</div></div>`);
  const a = AUDIT.find((x) => x.id === s.id);
  // Thiết kế lại qua impeccable live (2026-11-24): cột 720; đầu trang (ô biểu tượng + tên hoạt động + "người · thời điểm" + "Thành công")
  // → (hộp vàng khi không còn thông tin người thực hiện) → một thẻ, 4 phần ngăn gạch: Thay đổi (Trước gạch ngang → Sau nổi) · Ngữ cảnh ·
  // Đối tượng · Thông tin truy vết (+ mã sự kiện thô, chữ nhỏ).
  const gone = badge('Không còn dữ liệu', 'warning');
  const part = (t, inner, b = '') => `<div class="t1-adpart"><div class="t1-adpart__head"><h3>${esc(t)}</h3>${b}</div>${inner}</div>`;
  const change = a.changes ? part('Thay đổi', a.changes.map(([f, b4, af]) => `<div class="t1-adchange"><span class="t1-adchange__f">${esc(f)}</span><span class="t1-adchange__v"><span class="t1-adchange__before">Trước: ${esc(b4)}</span>${icon('chevronRight', 't1-adchange__arrow')}<b>Sau: ${esc(af)}</b></span></div>`).join('')) : '';
  const body = `<div class="t1-orgp">
    <div class="t1-orgp__head"><span class="t1-aic t1-aic--48" aria-hidden="true">${icon(a.icon)}</span><div><h1>${esc(a.title)}</h1><p>${esc(a.actor)} · ${esc(a.at)}</p></div><span class="t1-adok"><span class="t1-pill">Thành công</span></span></div>
    ${a.actorUnavailable ? `<div class="t1-warnbox">${icon('alert')}<div><b>Không còn thông tin người thực hiện</b><p class="t1-small">Thông tin người thực hiện không còn khả dụng tại thời điểm xem.</p></div></div>` : ''}
    <section class="t1-orgsec">
      ${change}
      ${part('Ngữ cảnh', `<div class="t1-stack8">${arow('Người thực hiện', a.actor)}${arow('Loại chủ thể', a.actorRole)}</div>`, a.actorUnavailable ? gone : '')}
      ${part('Đối tượng', `<div class="t1-stack8">${arow(a.subjectType, a.subject)}${a.subjectId ? arow('ID đối tượng', a.subjectId) : ''}</div>`, a.legacy ? badge('Thông tin hiện tại', 'neutral') : '')}
      ${part('Thông tin truy vết', `<div class="t1-stack8">${arow('Thời điểm', a.at.replace(' ', ' · '))}${arow('Nguồn', 'Tenant App')}${arow('Mã theo dõi', TRACE_ID, true)}</div><p class="t1-small t1-adcode">${esc(a.code)}</p>`)}
    </section>
  </div>`;
  return wrap(`<div class="t1-col" style="max-width:720px">${body}</div>`, s.toast ? toast('success', 'Đã sao chép', 'req_7f3a9c21e0b4d6a8b1e5f3c8d19f02', { device }) : '');
}

/**
 * Web (≥ 840) — bảng toàn màn, chọn qua impeccable live (2026-11-24): app bar + phụ đề; thanh công cụ (chip trái, ô tìm + bộ lọc phải);
 * cột 1120: dòng thời gian lọc → bảng (Hoạt động | Người thực hiện | Đối tượng: loại + tên | Thời điểm) → "Tải thêm". Chi tiết mở toàn màn (←).
 */
function auditTable(s) {
  const days = s.days || 30;
  const sub = s.forbidden ? 'Chưa được cấp quyền' : s.error ? 'Không tải được dữ liệu' : `${s.empty || s.noResults ? 0 : AUDIT_TOTAL} hoạt động trong ${days} ngày`;
  const items = s.category === 'Thành viên' ? AUDIT.filter((a) => ['a3', 'a5'].includes(a.id)) : AUDIT;
  const who = (a) => (a.actorRole && a.actorRole !== '—' ? `${a.actor} (${a.actorRole})` : a.actor);
  const ic = (a) => `<span class="t1-aic" aria-hidden="true">${icon(a.icon)}</span>`;
  const th = `<div class="t1-utable__tr t1-utable__th t1-atable__tr" role="row"><span role="columnheader">Hoạt động</span><span role="columnheader">Người thực hiện</span><span role="columnheader">Đối tượng</span><span role="columnheader">Thời điểm</span><span></span></div>`;
  let content;
  const state = s.forbidden ? 'forbidden' : s.error ? 'error' : s.empty ? 'empty' : s.noResults ? 'noResults' : '';
  if (state) content = `<div class="t1-utable t1-utable--state">${auditEmpty(state)}</div>`;
  else if (s.loading) {
    content = `<div class="t1-utable" role="table" aria-busy="true" aria-label="Đang tải">${th}${[0, 1, 2, 3, 4].map(() => `<div class="t1-utable__tr t1-utable__tr--skel t1-atable__tr"><span class="t1-atable__act">${skeleton({ w: 36, h: 36 })}${skeleton({ w: 180, h: 16 })}</span><span>${skeleton({ w: 140 })}</span><span class="t1-skelcol">${skeleton({ w: 60, h: 10 })}${skeleton({ w: 120 })}</span><span>${skeleton({ w: 110 })}</span><span></span></div>`).join('')}</div>`;
  } else {
    content = `<div class="t1-utable" role="table" aria-label="Lịch sử quản trị">${th}
      ${items.map((a) => `<button type="button" class="t1-utable__tr t1-atable__tr" role="row"><span class="t1-atable__act">${ic(a)}<span><b>${esc(a.title)}</b>${a.legacy ? badge('Thông tin hiện tại', 'neutral') : ''}</span></span><span class="t1-atable__sub">${esc(who(a))}</span><span class="t1-atable__sub"><small>${esc(a.subjectType)}</small>${esc(a.subject)}</span><span class="t1-utable__num">${esc(a.at)}</span>${icon('chevronRight', 't1-utable__chev')}</button>`).join('')}</div>
      <div class="t1-amore">${button('Tải thêm', { variant: 'secondary' })}</div>`;
  }
  const tools = `<div class="t1-utools"><div class="t1-atools__chips">${chipRow(['Tất cả', 'Thành viên', 'Vai trò', 'Tổ chức'], s.category || 'Tất cả')}</div>
    <div class="t1-utools__find">${searchBar('Tìm người thực hiện hoặc hoạt động', s.query || '')}${iconButton('tune', days !== 30 ? 'Bộ lọc (đang áp dụng)' : 'Bộ lọc', { size: 20, dot: days !== 30 })}</div></div>`;
  return `<div class="t1-page t1-page--canvas">${appBar('Lịch sử quản trị', { back: true, subtitle: sub })}${tools}
    <div class="t1-scroll"><div class="t1-uwrap"><p class="t1-small t1-atime2">Thời gian: ${days} ngày gần đây · Mới nhất trước</p>${content}</div></div></div>`;
}

export function auditPage(v) {
  const s = AUDIT_STATES[v.state];
  const overlay = s.sheet ? adaptiveSheet(v.width, auditFilter(), '', { title: 'Bộ lọc nhật ký nền tảng' }) : '';
  return { page: isSplit(v.width) ? auditTable(s) : auditList(s), overlay };
}

export function auditDetailPage(v) {
  return { page: auditDetail(AUDIT_DETAIL_STATES[v.state], false, v.device) };
}
