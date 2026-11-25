// ID-19 Vai trò (danh mục + chi tiết). Chép từ apps/erp/lib/features/iam/presentation/roles/{roles_area_shell.dart,
//   views/organization_roles_page.dart, views/organization_role_detail_page.dart}, logic/roles_cubit.dart, core/router/app_router.dart.
// /more/roles(/:code): ShellRoute riêng (RolesAreaShell → VListDetailLayout), ngoài StoreShell; chỉ Chủ sở hữu.
import { icon } from '../shared/icons.js';
import { ROLES } from './admin-data.js';
import { badge, button, detailWidth, esc, isSplit, LIST_WIDTH, listDetail, splitPlaceholder, vcard, vScaffold } from './ds.js';

export const ROLE_STATES = { list: {}, loading: { loading: true }, failed: { failed: true }, detail: { code: 'staff' }, 'detail-empty': { code: 'warehouse' } };

/** Không có nhánh "đang tải": khi chưa có dữ liệu vẫn vẽ phần đầu + "0 vai trò hệ thống" và danh sách rỗng. */
function rolesList(s, w, selected) {
  const roles = s.loading ? [] : ROLES;
  const body = s.failed
    ? `<div class="t1-center t1-pad-h"><div class="t1-card t1-rfail">
        <span class="t1-ring t1-ring--danger t1-ring--56">${icon('close')}</span><div class="t1-gap-md"></div>
        <h2 class="t1-h3 t1-danger t1-text-center">Không thể tải danh sách vai trò</h2><div class="t1-gap-xs"></div>
        <p class="t1-body2 t1-text-center">Dịch vụ phân quyền đang tạm thời không khả dụng. Vui lòng thử lại sau.</p><div class="t1-gap-md"></div>
        ${button('Thử lại', { variant: 'link' })}</div></div>`
    : `<div class="t1-list"><h2 class="t1-h4">Vai trò hệ thống</h2><div class="t1-gap-xs"></div><p class="t1-small">Vai trò vận hành không thay đổi tư cách Chủ sở hữu.</p><div class="t1-gap-md"></div>
      ${roles.map((r) => `<div class="t1-mb12">${vcard(`<div class="t1-urow">${icon('user', 't1-urow__ic')}<div class="t1-urow__text"><b>${esc(r.title)}</b><span>${esc(r.description)}</span></div>${r.members.length ? badge('Đang dùng', 'success') : icon('chevronRight', 't1-chev20')}</div>`, { selected: r.id === selected })}</div>`).join('')}</div>`;
  return vScaffold({ title: 'Vai trò', subtitle: s.failed ? 'Không tải được' : `${roles.length} vai trò hệ thống`, body, placeWidth: w, fixed: !!s.failed });
}

function roleDetail(code, w, split) {
  const r = ROLES.find((x) => x.id === code);
  const body = `<div class="t1-list">${vcard(`<h2 class="t1-h4">${esc(r.title)}</h2><div class="t1-gap-xs"></div><p class="t1-small">${esc(r.description)}</p><div class="t1-gap-md"></div><p class="t1-small">Vai trò hệ thống · Chỉ đọc</p>`)}
    <div class="t1-gap-md"></div><h2 class="t1-h4">Thành viên đang giữ vai trò</h2><div class="t1-gap-sm"></div>
    ${r.members.length ? r.members.map((n) => `<p class="t1-bodyp t1-mb8">${esc(n)}</p>`).join('') : '<p class="t1-small">Chưa có thành viên đang giữ vai trò này.</p>'}</div>`;
  return vScaffold({ title: 'Chi tiết vai trò', back: !split, body, placeWidth: w });
}

export function rolesPage(v) {
  const s = ROLE_STATES[v.state];
  if (!isSplit(v.width)) return { page: s.code ? roleDetail(s.code, v.width, false) : rolesList(s, v.width) };
  const right = s.code ? roleDetail(s.code, detailWidth(v.width), true) : splitPlaceholder('Chọn một vai trò để xem chi tiết.');
  return { page: listDetail(v.width, rolesList(s, LIST_WIDTH, s.code), right) };
}
