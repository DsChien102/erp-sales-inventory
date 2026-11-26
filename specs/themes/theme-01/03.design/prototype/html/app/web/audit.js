// Bố cục WEB (khung ≥ 840), chọn qua impeccable live 2026-11-24. iPhone ở ../audit.js; trạng thái mẫu, hàm kiểm, sheet dùng chung lấy từ đó.
import { icon } from '../../shared/icons.js';
import { AUDIT, AUDIT_BLOCKED_ITEM, AUDIT_TOTAL, TRACE_ID } from '../admin-data.js';
import { arow, AUDIT_DETAIL_STATES, AUDIT_STATES, auditEmpty, auditFilter, materialBar } from '../audit.js';
import { adaptiveSheet, appBar, badge, button, centerLoading, chipRow, esc, iconButton, searchBar, skeleton, toast } from '../ds.js';

/**
 * Web (≥ 840) — bảng toàn màn, chọn qua impeccable live (2026-11-24): app bar + phụ đề; thanh công cụ (chip trái, ô tìm + bộ lọc phải);
 * cột 1120: dòng thời gian lọc → bảng (Hoạt động | Người thực hiện | Đối tượng: loại + tên | Thời điểm) → "Tải thêm". Chi tiết mở toàn màn (←).
 */
function auditTable(s) {
  const days = s.days || 30;
  const sub = s.forbidden ? 'Chưa được cấp quyền' : s.error ? 'Không tải được dữ liệu' : `${s.empty || s.noResults ? 0 : AUDIT_TOTAL} hoạt động trong ${days} ngày`;
  const items = s.blocked
    ? [AUDIT_BLOCKED_ITEM, ...AUDIT]
    : s.category === 'Thành viên'
    ? AUDIT.filter((a) => ['a3', 'a5'].includes(a.id))
    : AUDIT;
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
      ${items.map((a) => `<button type="button" class="t1-utable__tr t1-atable__tr" role="row"><span class="t1-atable__act">${ic(a)}<span><b>${esc(a.title)}</b>${a.result ? badge(a.result[0], a.result[1]) : ''}${a.legacy ? badge('Thông tin hiện tại', 'neutral') : ''}</span></span><span class="t1-atable__sub">${esc(who(a))}</span><span class="t1-atable__sub"><small>${esc(a.subjectType)}</small>${esc(a.subject)}</span><span class="t1-utable__num">${esc(a.at)}</span>${icon('chevronRight', 't1-utable__chev')}</button>`).join('')}</div>
      <div class="t1-amore">${button('Tải thêm', { variant: 'secondary' })}</div>`;
  }
  const tools = `<div class="t1-utools"><div class="t1-atools__chips">${chipRow(['Tất cả', 'Thành viên', 'Vai trò', 'Tổ chức'], s.category || 'Tất cả')}</div>
    <div class="t1-utools__find">${searchBar('Tìm người thực hiện hoặc hoạt động', s.query || '')}${iconButton('tune', days !== 30 ? 'Bộ lọc (đang áp dụng)' : 'Bộ lọc', { size: 20, dot: days !== 30 })}</div></div>`;
  return `<div class="t1-page t1-page--canvas">${appBar('Lịch sử quản trị', { back: true, subtitle: sub })}${tools}
    <div class="t1-scroll"><div class="t1-uwrap"><p class="t1-small t1-atime2">Thời gian: ${days} ngày gần đây · Mới nhất trước</p>${content}</div></div></div>`;
}

export function auditPage(v) {
  const s = AUDIT_STATES[v.state];
  const overlay = s.sheet ? adaptiveSheet(v.width, auditFilter(), '', { title: 'Bộ lọc lịch sử quản trị' }) : '';
  return { page: auditTable(s), overlay };
}

function auditDetail(s, device) {
  const wrap = (body, t = '') => `<div class="t1-page t1-page--canvas">${materialBar(false)}<div class="t1-scroll">${body}</div>${t}</div>`;
  if (s.loading) return wrap(centerLoading());
  if (s.notFound) return wrap(`<div class="t1-center"><div class="t1-failed2"><h2 class="t1-h4 t1-h4--600">Không tìm thấy hoạt động</h2><div class="t1-gap-sm"></div><p class="t1-small t1-text-center">Nhật ký không tồn tại hoặc không thuộc tổ chức hiện tại.</p><div class="t1-gap-lg"></div>${button('Thử lại')}</div></div>`);
  const a = AUDIT.find((x) => x.id === s.id);
  // Thiết kế lại qua impeccable live (2026-11-24): cột 720; đầu trang (ô biểu tượng + tên hoạt động + "người · thời điểm" + "Thành công")
  // → (hộp vàng khi không còn thông tin người thực hiện) → một thẻ, 4 phần ngăn gạch: Thay đổi (Trước gạch ngang → Sau nổi) · Ngữ cảnh ·
  // Đối tượng · Thông tin truy vết (+ mã sự kiện thô, chữ nhỏ).
  const gone = badge('Không còn dữ liệu', 'warning');
  const part = (t, inner, b = '') => `<div class="t1-adpart"><div class="t1-adpart__head"><h3>${esc(t)}</h3>${b}</div>${inner}</div>`;
  const change = a.changes ? part('Dữ liệu thay đổi', a.changes.map(([f, b4, af]) => `<div class="t1-adchange"><span class="t1-adchange__f">${esc(f)}</span><span class="t1-adchange__v"><span class="t1-adchange__before">Trước: ${esc(b4)}</span>${icon('chevronRight', 't1-adchange__arrow')}<b>Sau: ${esc(af)}</b></span></div>`).join('')) : '';
  const body = `<div class="t1-orgp">
    <div class="t1-orgp__head"><span class="t1-aic t1-aic--48" aria-hidden="true">${icon(a.icon)}</span><div><h1>${esc(a.title)}</h1><p>${esc(a.actor)} · ${esc(a.at)}</p></div><span class="t1-adok"><span class="t1-pill">Thành công</span></span></div>
    ${a.actorUnavailable ? `<div class="t1-warnbox">${icon('alert')}<div><b>Không còn thông tin người thực hiện</b><p class="t1-small">Thông tin người thực hiện không còn khả dụng tại thời điểm xem.</p></div></div>` : ''}
    <section class="t1-orgsec">
      ${change}
      ${part('Ngữ cảnh', `<div class="t1-stack8">${arow('Người thực hiện', a.actor)}${arow('Vai trò', a.actorRole)}</div>`, a.actorUnavailable ? gone : '')}
      ${part('Đối tượng', `<div class="t1-stack8">${arow(a.subjectType, a.subject)}${a.subjectId ? arow('ID đối tượng', a.subjectId) : ''}</div>`, a.legacy ? badge('Thông tin hiện tại', 'neutral') : '')}
      ${part('Thông tin truy vết', `<div class="t1-stack8">${arow('Thời điểm', a.at.replace(' ', ' · '))}${arow('Nguồn', 'Ứng dụng')}${arow('Mã theo dõi', TRACE_ID, true)}</div><p class="t1-small t1-adcode">${esc(a.code)}</p>`)}
    </section>
  </div>`;
  return wrap(`<div class="t1-col" style="max-width:720px">${body}</div>`, s.toast ? toast('success', 'Đã sao chép', 'Đã sao chép mã theo dõi.', { device }) : '');
}

export function auditDetailPage(v) {
  return { page: auditDetail(AUDIT_DETAIL_STATES[v.state], v.device) };
}
