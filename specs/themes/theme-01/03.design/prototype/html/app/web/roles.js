// Bố cục WEB (khung ≥ 840), chọn qua impeccable live 2026-11-24. iPhone ở ../roles.js; trạng thái mẫu, hàm kiểm, sheet dùng chung lấy từ đó.
import { icon } from '../../shared/icons.js';
import { ROLES } from '../admin-data.js';
import { appBar, button, esc, skeleton, vcard, vScaffold } from '../ds.js';
import { ROLE_STATES } from '../roles.js';

/** Mô tả hiển thị: bỏ ghi chú kỹ thuật trong ngoặc ở cuối (vd. "(gán mặc định cho Owner…, BR-36)"). */
const shortDesc = (d) => String(d).replace(/\s*\([^)]*\)\s*$/, '');

function roleDetail(code, w) {
  const r = ROLES.find((x) => x.id === code);
  const body = `<div class="t1-list">${vcard(`<h2 class="t1-h4">${esc(r.title)}</h2><div class="t1-gap-xs"></div><p class="t1-small">${esc(shortDesc(r.description))}</p><div class="t1-gap-md"></div><p class="t1-small">Vai trò hệ thống · Chỉ đọc</p>`)}
    <div class="t1-gap-md"></div><h2 class="t1-h4">Thành viên đang giữ vai trò</h2><div class="t1-gap-sm"></div>
    ${r.members.length ? r.members.map((n) => `<p class="t1-bodyp t1-mb8">${esc(n)}</p>`).join('') : '<p class="t1-small">Chưa có thành viên đang giữ vai trò này.</p>'}</div>`;
  return vScaffold({ title: 'Chi tiết vai trò', body, placeWidth: w });
}

/**
 * Web (≥ 840) — bảng toàn màn, chọn qua impeccable live (2026-11-24): app bar "Vai trò · n vai trò hệ thống"; cột 1120: câu dẫn → bảng
 * (Vai trò hệ thống: tên + mô tả | Thành viên đang giữ vai trò: chữ viết tắt + tên). Bấm dòng mở chi tiết toàn màn (←). Đang tải: skeleton.
 */
function rolesTable(s) {
  const avatar = (n) => `<span class="t1-avatar" aria-hidden="true">${esc(n.trim().split(/\s+/).pop()[0])}</span>`;
  const holders = (r) => (r.members.length ? `<span class="t1-rholders">${r.members.map(avatar).join('')}<span>${r.members.map(esc).join(', ')}</span></span>` : '<span class="t1-rnone">Chưa có thành viên đang giữ vai trò này.</span>');
  const th = `<div class="t1-utable__tr t1-utable__th t1-rtable__tr" role="row"><span role="columnheader">Vai trò hệ thống</span><span role="columnheader">Thành viên đang giữ vai trò</span><span></span></div>`;
  let content;
  if (s.failed) {
    content = `<div class="t1-utable t1-utable--state"><div class="t1-uempty"><div class="t1-rfail">
      <span class="t1-ring t1-ring--danger t1-ring--56">${icon('close')}</span><div class="t1-gap-md"></div>
      <h2 class="t1-h3 t1-danger t1-text-center">Không thể tải danh sách vai trò</h2><div class="t1-gap-xs"></div>
      <p class="t1-body2 t1-text-center">Dịch vụ phân quyền đang tạm thời không khả dụng. Vui lòng thử lại sau.</p><div class="t1-gap-md"></div>
      ${button('Thử lại', { variant: 'link' })}</div></div></div>`;
  } else if (s.loading) {
    content = `<div class="t1-utable" role="table" aria-busy="true" aria-label="Đang tải">${th}${[0, 1, 2, 3].map(() => `<div class="t1-utable__tr t1-utable__tr--skel t1-rtable__tr"><span class="t1-skelcol">${skeleton({ w: 140, h: 16 })}${skeleton({ w: 220, h: 12 })}</span><span class="t1-rholders">${skeleton({ w: 28, h: 28, circle: true })}${skeleton({ w: 120 })}</span><span></span></div>`).join('')}</div>`;
  } else {
    content = `<div class="t1-utable" role="table" aria-label="Vai trò hệ thống">${th}
      ${ROLES.map((r) => `<button type="button" class="t1-utable__tr t1-rtable__tr" role="row"><span class="t1-rtable__role"><b>${esc(r.title)}</b><small>${esc(shortDesc(r.description))}</small></span><span>${holders(r)}</span>${icon('chevronRight', 't1-utable__chev')}</button>`).join('')}</div>`;
  }
  const sub = s.failed ? 'Không tải được' : s.loading ? '0 vai trò hệ thống' : `${ROLES.length} vai trò hệ thống`;
  return `<div class="t1-page t1-page--canvas">${appBar('Vai trò', { back: true, subtitle: sub })}
    <div class="t1-scroll"><div class="t1-uwrap"><p class="t1-small t1-rlead">Vai trò vận hành không thay đổi tư cách Chủ sở hữu.</p>${content}</div></div></div>`;
}

export function rolesPage(v) {
  const s = ROLE_STATES[v.state];
  if (s.code) return { page: roleDetail(s.code, v.width) };
  return { page: rolesTable(s) };
}
