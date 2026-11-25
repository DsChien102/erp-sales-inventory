// ID-19 Vai trò (danh mục + chi tiết). Chép từ apps/erp/lib/features/iam/presentation/roles/{roles_area_shell.dart,
//   views/organization_roles_page.dart, views/organization_role_detail_page.dart}, logic/roles_cubit.dart, core/router/app_router.dart.
// /more/roles(/:code): ShellRoute riêng (RolesAreaShell → VListDetailLayout), trong ShellRoute(StoreShell), web ≥ 1024 có thanh bên 84; chỉ Chủ sở hữu.
import { icon } from '../shared/icons.js';
import { ROLES } from './admin-data.js';
import { badge, button, card, detailWidth, esc, isSplit, LIST_WIDTH, listDetail, splitPlaceholder, vScaffold } from './ds.js';

export const ROLE_STATES = { list: {}, loading: { loading: true }, failed: { failed: true }, detail: { code: 'staff' }, 'detail-empty': { code: 'warehouse' } };

/** Mô tả hiển thị: bỏ ghi chú kỹ thuật trong ngoặc ở cuối (như bản web). */
const shortDesc = (d) => String(d).replace(/\s*\([^)]*\)\s*$/, '');

/**
 * Thẻ vai trò (iPhone, impeccable live 2026-11-25): tên + nhãn "Đang dùng" + mô tả + mũi tên (cả thẻ bấm được);
 * chân thẻ: người đang giữ (tối đa 3 ô tròn 28 + tên một dòng, dư cắt "…") hoặc câu chưa có ai.
 */
const holderAvatar = (n) => `<span class="t1-rolecard__av" aria-hidden="true">${esc(n.trim().split(/\s+/).pop()[0])}</span>`;
const roleCard = (r, selected) => `<button type="button" class="t1-rolecard"${selected ? ' aria-current="true"' : ''}>
  <span class="t1-rolecard__main"><span class="t1-rolecard__text"><span class="t1-rolecard__name"><b>${esc(r.title)}</b>${r.members.length ? badge('Đang dùng', 'success') : ''}</span><small>${esc(shortDesc(r.description))}</small></span>${icon('chevronRight', 't1-rolecard__go')}</span>
  <span class="t1-rolecard__foot">${r.members.length ? `${r.members.slice(0, 3).map(holderAvatar).join('')}<span class="t1-rolecard__who">${r.members.map(esc).join(', ')}</span>` : '<span class="t1-rolecard__who">Chưa có thành viên đang giữ vai trò này.</span>'}</span></button>`;

/** Không có nhánh "đang tải": khi chưa có dữ liệu vẫn vẽ phần đầu + "0 vai trò hệ thống" và danh sách rỗng. */
function rolesList(s, w, selected) {
  const roles = s.loading ? [] : ROLES;
  const body = s.failed
    ? `<div class="t1-center t1-pad-h"><div class="t1-card t1-rfail">
        <span class="t1-ring t1-ring--danger t1-ring--56">${icon('close')}</span><div class="t1-gap-md"></div>
        <h2 class="t1-h3 t1-danger t1-text-center">Không thể tải danh sách vai trò</h2><div class="t1-gap-xs"></div>
        <p class="t1-body2 t1-text-center">Dịch vụ phân quyền đang tạm thời không khả dụng. Vui lòng thử lại sau.</p><div class="t1-gap-md"></div>
        ${button('Thử lại', { variant: 'link' })}</div></div>`
    : `<div class="t1-list"><h2 class="t1-selrole__title">Vai trò hệ thống</h2><p class="t1-small t1-selrole__sub">Vai trò vận hành không thay đổi tư cách Chủ sở hữu.</p>
      <div class="t1-rolecards">${roles.map((r) => roleCard(r, r.id === selected)).join('')}</div></div>`;
  return vScaffold({ title: 'Vai trò', subtitle: s.failed ? 'Không tải được' : `${roles.length} vai trò hệ thống`, body, placeWidth: w, fixed: !!s.failed });
}

function roleDetail(code, w, split) {
  const r = ROLES.find((x) => x.id === code);
  // Bố cục iPhone thiết kế lại qua impeccable live (2026-11-25): ô khiên + tên + mô tả + "Vai trò hệ thống · Chỉ đọc" → thẻ thành viên (ô tròn 36 + tên, không bấm được).
  const holders = r.members.map((n) => `<div class="t1-roledet__row"><span class="t1-rolecard__av t1-roledet__av" aria-hidden="true">${esc(n.trim().split(/\s+/).pop()[0])}</span><b>${esc(n)}</b></div>`).join('');
  const body = `<div class="t1-list t1-roledet">
    <div class="t1-orgm__head"><div class="t1-orgm__icon" aria-hidden="true">${icon('shield')}</div><div><h2>${esc(r.title)}</h2><p>${esc(shortDesc(r.description))}</p><p class="t1-roledet__sys">${icon('lock')}Vai trò hệ thống · Chỉ đọc</p></div></div>
    <h3 class="t1-acc__title">Thành viên đang giữ vai trò</h3>
    ${card(holders || '<p class="t1-small t1-roledet__none">Chưa có thành viên đang giữ vai trò này.</p>', 't1-roledet__list')}</div>`;
  return vScaffold({ title: 'Chi tiết vai trò', back: !split, body, placeWidth: w });
}

export function rolesPage(v) {
  const s = ROLE_STATES[v.state];
  if (!isSplit(v.width)) return { page: s.code ? roleDetail(s.code, v.width, false) : rolesList(s, v.width) };
  const right = s.code ? roleDetail(s.code, detailWidth(v.width), true) : splitPlaceholder('Chọn một vai trò để xem chi tiết.');
  return { page: listDetail(v.width, rolesList(s, LIST_WIDTH, s.code), right) };
}
