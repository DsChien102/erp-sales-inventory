// APP-04 chọn tổ chức — chép từ Flutter:
//   apps/erp/lib/features/iam/presentation/organizations/widgets/{select_organization_bottom_sheet.dart, confirm_switch_organization_bottom_sheet.dart, organization_empty_view.dart}
//   packages/c45_design_system/lib/src/components/{v_adaptive_sheet.dart, v_bottom_sheet.dart}
// Màn ≥ 1024: hộp thoại 480 (VSheetDialog, nút Đóng góc phải); hẹp hơn: sheet dưới có tay kéo.
import { icon } from '../shared/icons.js';
import { DESKTOP, noticeCard } from '../shared/shell.js';

const esc = (s) => String(s ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

// IamRoleLabelMapper.toDisplayLabel
export const ROLE = { store_owner: 'Chủ cửa hàng', staff: 'Nhân viên bán hàng', warehouse: 'Thủ kho', accountant: 'Kế toán' };

export const ORGS = [
  { id: 'o1', name: 'Mosaic Retail Demo', code: 'MRD', role: 'store_owner', current: true },
  { id: 'o2', name: 'Đại lý Vật tư Nông nghiệp Minh Tâm', code: 'MINHTAM', role: 'staff' },
  { id: 'o3', name: 'Cửa hàng Phân bón Hưng Phát — Chi nhánh Quốc lộ 1A, Long An', code: 'HUNGPHAT-LA', role: 'warehouse' },
];

/** Lọc như _filteredOrganizations: chứa (không phân biệt hoa thường) ở tên hoặc mã. */
export function filterOrgs(orgs, query) {
  const q = String(query ?? '').trim().toLowerCase();
  if (!q) return orgs;
  return orgs.filter((o) => o.name.toLowerCase().includes(q) || o.code.toLowerCase().includes(q));
}

function orgCard(o) {
  return `<button type="button" class="sh-orgcard${o.current ? ' is-current' : ''}" data-org-pick="${o.id}" role="radio" aria-checked="${!!o.current}"${o.current ? ' aria-disabled="true"' : ''}>
    <span class="sh-orgcard__icon">${icon(o.current ? 'store' : 'user')}</span>
    <span class="sh-orgcard__text"><b>${esc(o.name)}</b><small>${esc(o.code)} · ${esc(ROLE[o.role] || '')}</small></span>
    <span class="sh-radio${o.current ? ' is-on' : ''}" aria-hidden="true"></span>
  </button>`;
}

/** Nội dung sheet "Chọn tổ chức". mode: 'list' | 'load-error' | 'retrying'. */
export function orgListBody({ orgs = ORGS, query = '', mode = 'list' } = {}) {
  const items = filterOrgs(orgs, query);
  let list;
  if (mode === 'retrying') list = '<div class="sh-retrying"><span class="sh-spinner" role="progressbar" aria-label="Đang tải"></span></div>';
  else if (mode === 'load-error') list = noticeCard({ compact: true, tone: 'danger', ic: 'error', title: 'Không thể tải danh sách', description: 'Đã xảy ra lỗi khi tải danh sách tổ chức. Vui lòng thử lại.', actions: [{ label: 'Thử lại', attrs: 'data-org-retry' }] });
  else if (!items.length && query) list = noticeCard({ compact: true, ic: 'search', title: 'Không tìm thấy tổ chức', description: 'Thử từ khóa khác hoặc xóa bộ lọc đang áp dụng.', actions: [{ label: 'Xóa bộ lọc', attrs: 'data-org-clear' }] });
  else if (!items.length) list = noticeCard({ compact: true, ic: 'info', title: 'Chưa có tổ chức được cấp quyền', description: 'Bạn chưa được cấp quyền truy cập tổ chức nào. Hãy kiểm tra lời mời hoặc liên hệ Chủ cửa hàng.', actions: [{ label: 'Kiểm tra lại', attrs: 'data-org-retry' }] });
  else list = `<div class="sh-org__list" role="radiogroup" aria-label="Tổ chức">${items.map(orgCard).join('')}</div>`;
  return `<div class="sh-org">
    <h2 class="sh-org__title">Chọn tổ chức</h2>
    <label class="sh-search">${icon('search')}<input type="search" placeholder="Tìm theo tên hoặc mã tổ chức" value="${esc(query)}" data-org-search aria-label="Tìm theo tên hoặc mã tổ chức"></label>
    <div data-region="org-list">${list}</div>
  </div>`;
}

/** confirm_switch_organization_bottom_sheet */
export function confirmBody(org) {
  return `<div class="sh-org">
    <h2 class="sh-org__title">Chuyển sang ${esc(org.name)}?</h2>
    <p class="sh-org__desc">Dữ liệu và quyền truy cập sẽ được tải lại theo tổ chức đã chọn.</p>
    <div class="sh-actions">
      <button type="button" class="button button--secondary" data-org-back>Quay lại</button>
      <button type="button" class="button button--primary" data-org-confirm="${org.id}">Chuyển tổ chức</button>
    </div>
  </div>`;
}

/** Bọc nội dung: sheet (hẹp) hoặc hộp thoại 480 (≥ 1024). */
export function adaptiveSheet(width, body, label) {
  if (width >= DESKTOP) {
    return `<div class="sh-scrim sh-scrim--dialog" data-org-scrim><section class="sh-dialog" role="dialog" aria-modal="true" aria-label="${esc(label)}">${body}<button type="button" class="sh-dialog__close" aria-label="Đóng" data-org-close>${icon('close')}</button></section></div>`;
  }
  return `<div class="sh-scrim sh-scrim--sheet" data-org-scrim><section class="sh-sheet" role="dialog" aria-modal="true" aria-label="${esc(label)}"><div class="sh-sheet__handle" aria-hidden="true"></div>${body}</section></div>`;
}

/** VLoading.show khi đang chuyển */
export function switching(org) {
  return `<div class="sh-scrim sh-scrim--dialog"><div class="sh-loading-dialog" role="status"><span class="sh-spinner"></span><b>Đang chuyển tổ chức</b><p>Đang tải dữ liệu và quyền truy cập của ${esc(org.name)}.</p></div></div>`;
}

/** VToast */
export function toast({ type = 'success', title, message }) {
  return `<div class="sh-toast sh-toast--${type}" role="status">${icon(type === 'success' ? 'checkCircle' : 'error')}<span><b>${esc(title)}</b><small>${esc(message)}</small></span></div>`;
}
