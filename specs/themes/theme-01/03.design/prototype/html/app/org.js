// ID-11 Hồ sơ tổ chức · ID-12 Chỉnh thông tin tổ chức · ID-13 Hồ sơ pháp lý. Chép từ:
//   apps/erp/lib/features/iam/presentation/organization_profile/views/{organization_profile_page, organization_edit_profile_page,
//     organization_legal_profile_form_page}.dart
//   …/organization_profile/widgets/{organization_profile_actions_bottom_sheet, tax_code_duplicate_warning_bottom_sheet}.dart
//   …/organizations/widgets/organization_empty_view.dart (unauthorized), apps/erp/lib/core/widgets/address/administrative_units_form_section.dart
// Ba route nằm ngoài ShellRoute → toàn màn, không thanh bên / thanh dưới (cả web). VPageScaffold mặc định: cột 720 trên web.
import { icon } from '../shared/icons.js';
import { LEGAL, LEGAL_NOTICE, ORG } from './admin-data.js';
import { adaptiveSheet, banner, button, centerLoading, confirmDialog, esc, field, input, kv, select, toast, vScaffold } from './ds.js';
import { unitSection } from './signup.js';

/** Bottom bar "Thao tác" (primary success, trailing chevronUp) / hai nút chia đôi khe 8: đệm 16 → cao 77 kể cả gạch. */
export const BAR_H = 77;
const actionBar = (label = 'Thao tác', o = {}) => `<div class="t1-bar-pad">${button(label, { full: true, trailing: 'chevronUp', ...o })}</div>`;
const twoBar = (ok, busy, okLabel = ok) => `<div class="t1-bar-pad t1-row2 t1-row2--8">${button('Hủy', { variant: 'secondary', full: true, disabled: busy })}${button(okLabel, { full: true, loading: busy })}</div>`;

/** Lỗi tải (chung nhiều màn IAM): giữa màn, đệm 16; H4 (w600) → khe 8 → bodySmall giữa → khe 24 → VButton "Thử lại". */
export const loadFailed = (title, message) => `<div class="t1-failed2"><h2 class="t1-h4 t1-h4--600">${esc(title)}</h2><div class="t1-gap-sm"></div><p class="t1-small t1-text-center">${esc(message)}</p><div class="t1-gap-lg"></div>${button('Thử lại')}</div>`;

/** OrganizationEmptyView(unauthorized): canh trên, đệm trên 12 / ngang 16; VCard đệm 24; vòng 64 warningBg + khiên 28; H3 w700; khe 4; mô tả; khe 16; link "Quay lại". */
export const orgUnauthorized = () => `<div class="t1-oempty"><div class="t1-card t1-oempty__card">
  <span class="t1-ring t1-ring--warning">${icon('shield')}</span><div class="t1-gap-md"></div>
  <h2 class="t1-h3 t1-text-center">Không có quyền xem tổ chức</h2><div class="t1-gap-xs"></div>
  <p class="t1-body2 t1-text-center">Liên hệ chủ cửa hàng để được cấp quyền quản lý tổ chức nền tảng.</p><div class="t1-gap-md"></div>
  ${button('Quay lại', { variant: 'link' })}</div></div>`;

/** _InfoRow: nhãn bodyDefault textMuted ↔ giá trị bodyDefault w600 phải ("—" khi rỗng). */
const info = (l, val) => kv(l, val || '—', 't1-kv--profile');
const section = (title, inner) => `<div class="t1-card t1-card--pad"><h2 class="t1-h4">${esc(title)}</h2><div class="t1-gap-md"></div><div class="t1-stack16">${inner}</div></div>`;

/** _LegalNotice: nền warningBg bo 12 đệm 16; icon cảnh báo 20 + khe 8; tiêu đề bodyDefault w700 warning, khe 4, bodySmall. */
export const warnBox = (title, message) => `<div class="t1-warnbox">${icon('alert')}<div><b>${esc(title)}</b><p class="t1-small">${esc(message)}</p></div></div>`;

function profileBody(hasLegal) {
  const legal = hasLegal
    ? [info('Loại chủ thể', LEGAL.entityType), info('Tên pháp lý', LEGAL.legalName), info('Mã số thuế', LEGAL.taxCode), info('Địa chỉ đăng ký', LEGAL.registeredAddress)].join('')
    : warnBox(LEGAL_NOTICE.title, LEGAL_NOTICE.message);
  return `<div class="t1-list">
    ${hasLegal ? '' : `${banner('info', 'Bổ sung hồ sơ pháp lý để xuất hoá đơn điện tử.', '', button('Bổ sung', { variant: 'link' }))}<div class="t1-gap-md"></div>`}
    <div class="t1-card t1-card--pad t1-orghead">${icon('building')}<h2 class="t1-h4">${esc(ORG.name)}</h2></div>
    <div class="t1-gap-sm"></div>
    ${section('Thông tin tổ chức', [info('Tên hiển thị', ORG.name), info('Điện thoại', ORG.phone), info('Email', ORG.email), info('Địa chỉ', ORG.address)].join(''))}
    <div class="t1-gap-sm"></div>
    ${section('Hồ sơ pháp lý', legal)}
  </div>`;
}

/** OrganizationProfileActionsBottomSheet: đệm 16 / 8 / 16 / 24; H3 w700; khe 16; hai VCard (icon 20 + khe 8 + chữ + mũi tên 20) cách 8. */
function actionsSheet(hasLegal) {
  const opt = (ic, t, sub) => `<div class="t1-card t1-card--pad t1-optcard">${icon(ic)}<div><b>${esc(t)}</b><span>${esc(sub)}</span></div>${icon('chevronRight', 't1-optcard__chev')}</div>`;
  return `<div class="t1-sheetpad"><h2 class="t1-h3">Thao tác hồ sơ</h2><div class="t1-gap-md"></div>
    ${opt('edit', 'Chỉnh sửa thông tin tổ chức', 'Cập nhật thông tin liên hệ và địa chỉ')}<div class="t1-gap-sm"></div>
    ${opt('fileText', hasLegal ? 'Chỉnh sửa hồ sơ pháp lý' : 'Thêm hồ sơ pháp lý', hasLegal ? 'Cập nhật thông tin pháp lý' : 'Bổ sung thông tin pháp lý')}</div>`;
}

export const PROFILE_STATES = {
  'no-legal': {}, 'with-legal': { legal: true }, loading: { loading: true }, error: { error: true }, forbidden: { forbidden: true },
  actions: { sheet: 'actions' }, 'actions-legal': { legal: true, sheet: 'actions' },
  'toast-saved': { toast: ['success', 'Đã lưu thay đổi', 'Thông tin tổ chức đã được cập nhật thành công.'] },
  'toast-legal-saved': { legal: true, toast: ['success', 'Đã lưu hồ sơ pháp lý.', ''] },
};

export function profilePage(v) {
  const s = PROFILE_STATES[v.state];
  const base = { title: 'Hồ sơ tổ chức', placeWidth: v.width };
  let page;
  if (s.loading) page = vScaffold({ ...base, body: centerLoading(), fixed: true });
  else if (s.forbidden) page = vScaffold({ ...base, body: orgUnauthorized() });
  else if (s.error) page = vScaffold({ ...base, body: loadFailed('Không tải được hồ sơ', 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.'), fixed: true });
  else {
    page = vScaffold({
      ...base, body: profileBody(!!s.legal), bottomBar: actionBar(),
      toastHtml: s.toast ? toast(...s.toast, { device: v.device, above: BAR_H }) : '',
    });
  }
  return { page, overlay: s.sheet ? adaptiveSheet(v.width, actionsSheet(!!s.legal), 'Thao tác hồ sơ') : '' };
}

// ---------------------------------------------------------------- ID-12
const DISCARD = { title: 'Bỏ thay đổi?', message: 'Các thay đổi chưa lưu sẽ bị mất.', cancel: 'Tiếp tục sửa', action: 'Bỏ thay đổi', destructive: true };

export const EDIT_STATES = {
  filled: {}, loading: { loading: true },
  errors: { values: { name: '', phone: '', email: 'lan@anphat', address: '' }, errors: { name: 'Vui lòng nhập tên tổ chức', phone: 'Vui lòng nhập số điện thoại', email: 'Email không hợp lệ', address: 'Vui lòng nhập địa chỉ liên hệ' } },
  submitting: { busy: true, values: { name: 'Thú y An Phát Quận 3' } },
  discard: { values: { name: 'Thú y An Phát Quận 3' }, dialog: true },
  'toast-state-changed': { values: { name: 'Thú y An Phát Quận 3' }, toast: ['warning', 'Dữ liệu đã thay đổi', 'Dữ liệu đã thay đổi. Vui lòng tải lại rồi xác nhận lại.'] },
  'toast-failed': { values: { name: 'Thú y An Phát Quận 3' }, toast: ['danger', 'Không lưu được', 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.'] },
};

export function editPage(v) {
  const s = EDIT_STATES[v.state];
  const base = { title: 'Chỉnh thông tin tổ chức', placeWidth: v.width };
  if (s.loading) return { page: vScaffold({ ...base, body: centerLoading(), fixed: true }) };
  const x = { name: ORG.name, phone: ORG.phone, email: ORG.email, address: ORG.address, ...s.values };
  const e = s.errors || {};
  const body = `<div class="t1-list">
    <p class="t1-small">Thông tin liên hệ này độc lập với hồ sơ pháp lý và chứng từ đã phát hành.</p><div class="t1-gap-md"></div>
    <div class="t1-form">
      ${field({ label: 'Tên tổ chức', required: true, control: input({ value: x.name, invalid: !!e.name }), error: e.name, desc: 'Tên hiển thị.' })}
      ${field({ label: 'Số điện thoại', required: true, control: input({ value: x.phone, invalid: !!e.phone }), error: e.phone })}
      ${field({ label: 'Email liên hệ', required: true, control: input({ value: x.email, invalid: !!e.email }), error: e.email })}
      ${field({ label: 'Địa chỉ liên hệ', required: true, control: input({ value: x.address, invalid: !!e.address }), error: e.address })}
      ${unitSection({ province: ORG.province, commune: ORG.commune, required: false })}
    </div></div>`;
  const page = vScaffold({ ...base, body, bottomBar: twoBar('Lưu thay đổi', !!s.busy), toastHtml: s.toast ? toast(...s.toast, { device: v.device, above: BAR_H }) : '' });
  return { page, overlay: s.dialog ? confirmDialog(DISCARD) : '' };
}

// ---------------------------------------------------------------- ID-13
const TAX_FORMAT = 'Mã số thuế phải gồm 10 hoặc 12 chữ số, hoặc dạng chi nhánh 10 số-3 số (VD: 0123456789-001).';
export const LEGAL_STATES = {
  'add-empty': {}, 'add-errors': { errors: { type: 'Vui lòng chọn loại chủ thể', name: 'Vui lòng nhập tên pháp lý', tax: 'Vui lòng nhập mã số thuế' }, toast: ['danger', 'Thiếu thông tin', 'Vui lòng điền đầy đủ các thông tin bắt buộc'] },
  'add-tax-format': { values: { type: 'Hộ kinh doanh', name: 'Hộ kinh doanh Thú y An Phát', tax: '031234567' }, errors: { tax: TAX_FORMAT }, toast: ['danger', 'Thiếu thông tin', 'Vui lòng điền đầy đủ các thông tin bắt buộc'] },
  'edit-filled': { edit: true }, submitting: { edit: true, busy: true },
  duplicate: { edit: true, sheet: true }, discard: { edit: true, values: { name: 'Công ty TNHH Thú y An Phát Sài Gòn' }, dialog: true },
  loading: { loading: true },
};

/** TaxCodeDuplicateWarningBottomSheet: đệm 16 / 8 / 16 / 24; H3 w700; khe 4; bodySmall; khe 16; hộp vàng; khe 24; "Vẫn lưu" / khe 8 / "Kiểm tra lại". */
const duplicateSheet = () => `<div class="t1-sheetpad"><h2 class="t1-h3">Mã số thuế đã được ghi nhận</h2><div class="t1-gap-xs"></div>
  <p class="t1-small">Mã số thuế này đã xuất hiện ở hồ sơ khác. Hệ thống không tiết lộ tổ chức liên quan.</p><div class="t1-gap-md"></div>
  ${warnBox('Có thể tiếp tục lưu', 'Mã số thuế không bắt buộc duy nhất. Hãy kiểm tra lại trước khi tiếp tục.')}<div class="t1-gap-lg"></div>
  ${button('Vẫn lưu', { full: true })}<div class="t1-gap-sm"></div>${button('Kiểm tra lại', { variant: 'secondary', full: true })}</div>`;

export function legalPage(v) {
  const s = LEGAL_STATES[v.state];
  const title = s.edit ? 'Chỉnh hồ sơ pháp lý' : 'Thêm hồ sơ pháp lý';
  const base = { title, placeWidth: v.width };
  if (s.loading) return { page: vScaffold({ ...base, body: centerLoading(), fixed: true }) };
  const x = s.edit ? { type: LEGAL.entityType, name: LEGAL.legalName, tax: LEGAL.taxCode, address: LEGAL.registeredAddress, ...s.values } : { type: '', name: '', tax: '', address: '', ...s.values };
  const e = s.errors || {};
  const body = `<div class="t1-list">
    <p class="t1-small">Thay đổi hiện tại không làm thay đổi chứng từ lịch sử.</p><div class="t1-gap-md"></div>
    <div class="t1-form">
      ${field({ label: 'Loại chủ thể', control: select({ value: x.type, hint: 'Chọn loại chủ thể', invalid: !!e.type }), error: e.type })}
      ${field({ label: 'Tên pháp lý', required: true, control: input({ value: x.name, hint: 'Nhập tên pháp lý', invalid: !!e.name }), error: e.name })}
      ${field({ label: 'Mã số thuế', required: true, control: input({ value: x.tax, hint: 'Nhập mã số thuế', invalid: !!e.tax }), error: e.tax, desc: '10 hoặc 12 chữ số; chi nhánh nhập đủ 13 số, dấu gạch tự thêm.' })}
      ${field({ label: 'Địa chỉ đăng ký', control: input({ value: x.address, hint: 'Nhập địa chỉ đăng ký' }) })}
      ${unitSection(s.edit ? { province: ORG.province, commune: ORG.commune, required: false } : { required: false })}
    </div><div class="t1-gap-md"></div></div>`;
  const page = vScaffold({ ...base, body, bottomBar: twoBar('Lưu hồ sơ', !!s.busy), toastHtml: s.toast ? toast(...s.toast, { device: v.device, above: BAR_H }) : '' });
  const overlay = s.sheet ? adaptiveSheet(v.width, duplicateSheet(), 'Mã số thuế đã được ghi nhận') : s.dialog ? confirmDialog(DISCARD) : '';
  return { page, overlay };
}
