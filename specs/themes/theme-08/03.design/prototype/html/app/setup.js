// Đợt 1 · Thiết lập HĐĐT: HD-01 tổng quan, HD-02 kết nối MISA, HD-03 sheet ngắt kết nối, HD-04 cấu hình phát hành, HD-05 tự động hóa.
// Nguồn Dart (apps/erp/lib/features/einvoice/):
//   HD-01 presentation/pages/einvoice_configuration_overview_page.dart, widgets/{einvoice_configuration_overview_view, readiness_summary,
//         settings_navigation_item}.dart, support/einvoice_configuration_overview_copy.dart, logic/einvoice_configuration_overview_state.dart
//   HD-02 presentation/pages/provider_connection_page.dart, widgets/provider_connection_view.dart, logic/provider_connection_{copy,state}.dart
//   HD-03 presentation/widgets/disconnect_provider_sheet.dart (showVAdaptiveSheet)
//   HD-04 presentation/pages/default_issuance_configuration_page.dart, widgets/default_issuance_configuration_view.dart,
//         logic/default_issuance_configuration_{copy,state}.dart
//   HD-05 presentation/pages/automation_policy_page.dart, widgets/{automation_policy_view, switch_setting_row}.dart, support/automation_policy_copy.dart
//   Route: core/router/app_router.dart GoRoute '/more/einvoice' (+ /connection, /issuance, /automation) cấp gốc, ngoài StoreShell.
import {
  adaptiveSheet, banner, button, card, esc, field, fieldWithDesc, icon, iconBox, input, loadingDot, passwordInput, selectField, vswitch,
} from './ds.js';
import { commonState, editorBar, infoRow, page, pageToast, plainBar, syncedAt, updatedAt } from './common.js';
import { CONNECTION, LAST_SYNCED_AT, LEGAL, TEMPLATES } from './data.js';

// ---------------------------------------------------------------- hàm thuần (đối chiếu Dart)

export const PROVIDER_NAME = 'MISA meInvoice';
export const AUTHORITY_WITH_TAX_CODE = 'Có mã của cơ quan thuế';

/** EInvoiceConfigurationOverviewCopy.connectionSubtitle. */
export const connectionSubtitle = (status) => ({
  disconnected: 'Chưa kết nối MISA meInvoice',
  connected: 'MISA meInvoice · Đã kết nối',
  checkRequired: 'Cần kiểm tra lại',
  reconnectRequired: 'Cần kết nối lại',
}[status]);

/** EInvoiceConfigurationOverviewCopy.issuanceSubtitle: không có mẫu → câu thiếu; mẫu không có trong danh sách / không ký hiệu → in templateId thô. */
export function issuanceSubtitle(templateId, templates) {
  if (!templateId) return 'Chưa chọn mẫu hóa đơn mặc định';
  const match = templates.find((t) => t.templateId === templateId);
  const symbol = match ? match.symbol : null;
  if (!symbol) return templateId;
  return `${symbol} · ${AUTHORITY_WITH_TAX_CODE}`;
}

/** EInvoiceConfigurationOverviewCopy.automationSubtitle: chưa sẵn sàng → câu cố định, không theo chính sách. */
export function automationSubtitle(isReady, policy) {
  if (!isReady) return 'Phát hành hóa đơn và gửi email tự động.';
  return `${policy.autoIssue ? 'Phát hành tự động' : 'Phát hành thủ công'} · ${policy.autoSend ? 'Gửi email tự động' : 'Gửi email thủ công'}`;
}

/** _EInvoiceConfigurationOverviewBody._completeTap: kết nối chưa xong → HD-02; chưa mẫu → HD-04; còn lại → HD-05. */
export function completeTarget(s) {
  if (s.isReady) return null;
  if (s.connection !== 'connected') return 'connection';
  if (!s.templateId) return 'issuance';
  return 'automation';
}

/** EInvoiceConfigurationOverviewCopy.notReadyDescription. */
export const notReadyDescription = (n) => `Còn ${n} điều kiện cần hoàn tất trước khi có thể phát hành hóa đơn điện tử.`;

/** ProviderConnectionCopy.statusValue. */
export const statusValue = (status) => ({ connected: 'Đã kết nối', checkRequired: 'Chờ kết nối', reconnectRequired: 'Lỗi kết nối', disconnected: 'Chưa kết nối' }[status]);

/** ProviderConnectionCopy.maskAccount. */
export function maskAccount(account) {
  const value = account.trim();
  const at = value.indexOf('@');
  if (at > 1) return `${value.slice(0, 2)}***${value.slice(at)}`;
  if (value.length > 2) return `${value.slice(0, 2)}***`;
  return '***';
}

/** ProviderConnectionLoaded.showsForm / infoKind. */
export const showsForm = (status, reconnectMode = false) => reconnectMode || status === 'disconnected';
export function infoKind(status, reconnectMode = false) {
  if (showsForm(status, reconnectMode)) return null;
  return { connected: 'connected', checkRequired: 'pending', reconnectRequired: 'error' }[status];
}

/** _DefaultIssuanceBody._templateOptionLabel: ký hiệu, không có thì tên. Thẻ "Ký hiệu": symbol ?? serial ?? templateId. */
export const templateOptionLabel = (t) => (t.symbol && t.symbol.trim() ? t.symbol.trim() : t.name);
export const templateSymbolValue = (t) => t.symbol ?? t.serial ?? t.templateId;

// ---------------------------------------------------------------- HD-01

const OV = {
  'not-ready': { connection: 'disconnected', templateId: null, policy: { autoIssue: false, autoSend: false } },
  'not-ready-template': { connection: 'connected', templateId: null, policy: { autoIssue: false, autoSend: false } },
  'check-required': { connection: 'checkRequired', templateId: TEMPLATES[0].templateId, policy: { autoIssue: false, autoSend: false } },
  'reconnect-required': { connection: 'reconnectRequired', templateId: TEMPLATES[0].templateId, policy: { autoIssue: true, autoSend: true } },
  'ready-manual': { connection: 'connected', templateId: TEMPLATES[0].templateId, policy: { autoIssue: false, autoSend: false } },
  'ready-auto': { connection: 'connected', templateId: TEMPLATES[0].templateId, policy: { autoIssue: true, autoSend: true } },
  'ready-mixed': { connection: 'connected', templateId: TEMPLATES[1].templateId, policy: { autoIssue: true, autoSend: false } },
  'template-unknown': { connection: 'connected', templateId: 'e5b27c90-6d14-4a3f-b8e2-91c0f4a7d356', policy: { autoIssue: false, autoSend: false } },
};

/**
 * Trạng thái tổng quan đã tải. Mức sẵn sàng = kết nối connected + có mẫu (server trả 1 blocker đầu tiên → N luôn 1, KI-03).
 * Cubit chỉ gọi list_provider_templates khi kết nối connected → kết nối khác mà đã có mẫu thì phụ đề "Cấu hình phát hành" in GUID.
 */
export function overviewState(kind) {
  const base = OV[kind];
  if (!base) return null;
  const isReady = base.connection === 'connected' && !!base.templateId;
  return { ...base, isReady, blockerCount: isReady ? 0 : 1, templates: base.connection === 'connected' ? TEMPLATES : [] };
}

/**
 * ReadinessSummary: VCard nền warningBg / successBg, viền warning / success, đệm 16.
 * Chưa sẵn sàng: "Cần hoàn tất" bodySmall w600 warning + khe 4; tiêu đề headingH3 (18/26 w600) textPrimary; khe 4; mô tả bodySmall textSecondary;
 * khe 8 + Align phải: InkWell bo 8 đệm 4 [chữ bodySmall w600 primary + khe 4 + chevronRight 16 primary].
 */
function readinessSummary(s) {
  if (s.isReady) {
    return `<div class="t8-ready t8-ready--ok"><h2 class="t8-ready__title">Sẵn sàng phát hành</h2><p class="t8-ready__desc">Đã đủ điều kiện phát hành hóa đơn điện tử từ đơn hàng Hoàn tất.</p></div>`;
  }
  return `<div class="t8-ready t8-ready--warn"><span class="t8-ready__eyebrow">Cần hoàn tất</span>
    <h2 class="t8-ready__title">Chưa sẵn sàng phát hành</h2><p class="t8-ready__desc">${esc(notReadyDescription(s.blockerCount))}</p>
    <div class="t8-ready__act"><button type="button" class="t8-ready__link"><span>Xem và hoàn tất</span>${icon('chevronRight')}</button></div></div>`;
}

/**
 * SettingsNavigationItem: VCard (subtle: viền borderStrong, bo 12) đệm 16; Row[VIconBox 40 (icon 20, nền surfaceAlt, icon textSecondary, bo 12), khe 16,
 * Expanded(Column[tiêu đề headingH4 ép w700, khe 4, phụ đề bodySmall textSecondary]), khe 8, chevronRight 20 textSecondary].
 * enabled false → viền borderDefault + cả thẻ mờ 0.4 (vDisabledOpacity), không bấm được.
 */
function navItem(ic, title, subtitle, { enabled = true } = {}) {
  return `<button type="button" class="t8-nav${enabled ? '' : ' is-disabled'}"${enabled ? '' : ' disabled'}>
    ${iconBox({ ic, size: 40, iconSize: 20, cls: 't8-nav__ibox', radius: 12 })}
    <span class="t8-nav__text"><b>${esc(title)}</b><span>${esc(subtitle)}</span></span>${icon('chevronRight', 't8-nav__chev')}</button>`;
}

export function overviewPage(v, kind) {
  const title = 'Hóa đơn điện tử';
  const st = commonState(kind);
  if (st) return page(v, { title, content: st });
  const s = overviewState(kind);
  const list = `${readinessSummary(s)}
    ${navItem('key', 'Kết nối MISA', connectionSubtitle(s.connection))}
    ${navItem('fileCheck', 'Cấu hình phát hành', issuanceSubtitle(s.templateId, s.templates), { enabled: s.connection === 'connected' })}
    ${navItem('tune', 'Tự động hóa', automationSubtitle(s.isReady, s.policy))}`;
  return page(v, { title, list: `<div class="t8-stack16">${list}</div>` });
}

// ---------------------------------------------------------------- HD-02

/** Ca HD-02 → trạng thái. */
export function connectionState(kind) {
  const base = { status: 'disconnected', reconnectMode: false, submitting: false, accountError: null, passwordError: null, account: '', password: '', masked: CONNECTION.maskedAccount, lastChecked: CONNECTION.lastCheckedAt, toast: null };
  const m = {
    form: {},
    'form-filled': { account: 'ketoan@anphat.vn', password: 'matkhau123' },
    'form-invalid': { accountError: 'Vui lòng nhập tài khoản MISA', passwordError: 'Vui lòng nhập mật khẩu MISA' },
    'form-submitting': { account: 'ketoan@anphat.vn', password: 'matkhau123', submitting: true },
    'form-reconnect': { status: 'reconnectRequired', reconnectMode: true },
    'toast-auth-failed': { account: 'ketoan@anphat.vn', password: 'matkhau12', toast: ['danger', 'Tài khoản hoặc mật khẩu không đúng. Hãy kiểm tra lại.'] },
    'toast-generic': { account: 'ketoan@anphat.vn', password: 'matkhau123', toast: ['danger', 'Có lỗi xảy ra, vui lòng thử lại.'] },
    connected: { status: 'connected' },
    'connected-no-time': { status: 'connected', masked: null, lastChecked: null },
    'toast-connected': { status: 'connected', toast: ['success', 'Kết nối MISA meInvoice thành công.'] },
    pending: { status: 'checkRequired' },
    error: { status: 'reconnectRequired' },
    'toast-reconnected': { status: 'connected', toast: ['success', 'Tài khoản kết nối MISA đã được cập nhật.'] },
    disconnecting: { status: 'connected', submitting: true },
  }[kind];
  return m ? { ...base, ...m } : null;
}

function connectionForm(v, s) {
  const list = `<h2 class="t8-h4b">Thông tin kết nối</h2>
    ${card(`${infoRow('Nhà cung cấp', PROVIDER_NAME)}<hr class="t8-divider">${infoRow('Mã số thuế đơn vị phát hành', LEGAL.taxCode)}`)}
    <p class="t8-small t8-mt8">Mã số thuế được lấy từ Hồ sơ pháp lý của Tổ chức.</p>
    <div class="t8-mt16">${field({ label: 'Tài khoản MISA', required: true, control: input({ value: s.account, hint: 'Nhập tài khoản MISA', invalid: !!s.accountError, disabled: s.submitting }), error: s.accountError })}</div>
    <div class="t8-mt16">${fieldWithDesc({ label: 'Mật khẩu MISA', required: true, control: passwordInput({ value: s.password, hint: 'Nhập mật khẩu MISA', invalid: !!s.passwordError, disabled: s.submitting }), error: s.passwordError })}</div>
    <p class="t8-small t8-mt8">Mật khẩu được bảo mật và không hiển thị lại sau khi kết nối.</p>`;
  const bar = editorBar({ submit: s.reconnectMode ? 'Kết nối lại' : 'Kết nối', loading: s.submitting });
  return page(v, { title: 'Kết nối MISA', list, bar, toastHtml: s.toast ? pageToast(v, ...s.toast) : '' });
}

function connectionInfo(v, s) {
  const kind = infoKind(s.status);
  const tone = { connected: 'success', pending: 'info', error: 'danger' }[kind];
  const rows = [
    infoRow('Trạng thái', statusValue(s.status), { tone, trailing: kind === 'pending' ? `<i class="t8-gap-h8"></i>${loadingDot(14, 2, 'info')}` : '' }),
    infoRow('Nhà cung cấp', PROVIDER_NAME),
    s.masked ? infoRow('Tài khoản', s.masked) : '',
    infoRow('MST đơn vị phát hành', LEGAL.taxCode),
  ].filter(Boolean).join('<hr class="t8-divider">');
  const list = `<h2 class="t8-h4b">Thông tin kết nối</h2>${card(rows)}
    ${kind === 'pending' ? `<div class="t8-mt16">${banner('info', 'Đang chờ kết nối', 'Hệ thống đang tự động hoàn tất kết nối với MISA meInvoice.')}</div>` : ''}
    ${kind === 'error' ? `<div class="t8-mt16">${banner('error', 'Không thể kết nối với MISA meInvoice', 'Hãy kết nối lại để hệ thống thử lại bằng thông tin hiện có.')}</div>` : ''}
    ${s.lastChecked ? `<p class="t8-small t8-mt16">${esc(updatedAt(s.lastChecked))}</p>` : ''}`;
  const dis = (full) => button('Ngắt kết nối', { variant: 'secondary', tone: 'danger', full, disabled: s.submitting });
  const bar = plainBar(kind === 'error'
    ? `<div class="t8-row2">${dis(false)}${button('Kết nối lại', { disabled: s.submitting })}</div>`
    : dis(true));
  return page(v, { title: 'Kết nối MISA', list, bar, toastHtml: s.toast ? pageToast(v, ...s.toast) : '' });
}

export function connectionPage(v, kind) {
  const st = commonState(kind === 'load-error' ? 'error' : kind);
  if (st) return page(v, { title: 'Kết nối MISA', content: st });
  const s = connectionState(kind);
  return showsForm(s.status, s.reconnectMode) ? connectionForm(v, s) : connectionInfo(v, s);
}

// ---------------------------------------------------------------- HD-03

/**
 * DisconnectProviderSheet trong showVAdaptiveSheet(title "Ngắt kết nối MISA?"): đệm 16 / 12 / 16 / 16; nội dung bodyDefault textSecondary;
 * khe 24; VButton primary danger đầy ngang "Ngắt kết nối"; khe 8; VButton secondary đầy ngang "Giữ kết nối".
 * < 1024: sheet đáy (tay kéo, tiêu đề + gạch); ≥ 1024: hộp thoại 480 (tiêu đề + nút Đóng + gạch).
 */
export function disconnectSheet(v) {
  const body = `<div class="t8-dsheet"><p class="t8-body2">Sau khi ngắt kết nối, không thể phát hành hóa đơn điện tử mới. Hóa đơn và lịch sử đã phát sinh vẫn được giữ nguyên.</p>
    <i class="t8-gap" style="height:24px"></i>${button('Ngắt kết nối', { tone: 'danger', full: true })}<i class="t8-gap" style="height:8px"></i>${button('Giữ kết nối', { variant: 'secondary', full: true })}</div>`;
  return adaptiveSheet(v.width, body, { title: 'Ngắt kết nối MISA?' });
}

// ---------------------------------------------------------------- HD-04

export function issuanceState(kind) {
  const base = { selectedId: TEMPLATES[0].templateId, submitting: false, error: null, synced: LAST_SYNCED_AT, menu: false, toast: null };
  const m = {
    empty: { selectedId: null },
    'empty-no-sync': { selectedId: null, synced: null },
    selected: {},
    menu: { menu: true },
    'selected-other': { selectedId: TEMPLATES[2].templateId },
    invalid: { selectedId: null, error: 'Vui lòng chọn mẫu hóa đơn' },
    submitting: { submitting: true },
    'toast-saved': { toast: ['success', 'Mẫu hóa đơn mặc định đã được cập nhật.'] },
    'toast-incompatible': { toast: ['danger', 'Mẫu hóa đơn không tương thích với cấu hình ký hiện tại.'] },
    'toast-not-connected': { toast: ['danger', 'Cần kết nối MISA trước khi lưu mẫu hóa đơn mặc định.'] },
    'toast-error': { toast: ['danger', 'Có lỗi xảy ra, vui lòng thử lại.'] },
  }[kind];
  return m ? { ...base, ...m } : null;
}

/** Menu xổ của VSelect (MenuAnchor): khung viền borderInput bo 8, đệm 8, bóng e1, rộng bằng ô; mỗi dòng 44 đệm ngang 8, bodyDefault textPrimary; dòng đang chọn KHÔNG tô / không dấu. */
const selectMenu = (items) => `<div class="t8-menu" role="listbox">${items.map((t) => `<button type="button" class="t8-menu__item" role="option">${esc(t)}</button>`).join('')}</div>`;

export function issuancePage(v, kind) {
  const title = 'Cấu hình phát hành';
  const st = commonState(kind === 'load-error' ? 'error' : kind);
  if (st) return page(v, { title, content: st });
  const s = issuanceState(kind);
  const sel = TEMPLATES.find((t) => t.templateId === s.selectedId) || null;
  const select = selectField({
    label: 'Mẫu hóa đơn', required: true, value: sel ? templateOptionLabel(sel) : '', hint: 'Chọn mẫu hóa đơn',
    error: s.error, desc: s.synced ? syncedAt(s.synced) : null, disabled: s.submitting,
  });
  const info = sel ? `<div class="t8-mt16">${card(`<h3 class="t8-h4b">Thông tin mẫu</h3><i class="t8-gap" style="height:8px"></i>
    ${infoRow('Ký hiệu', templateSymbolValue(sel))}<hr class="t8-divider">${infoRow('Cấp mã', AUTHORITY_WITH_TAX_CODE)}<hr class="t8-divider">${infoRow('Loại hóa đơn', sel.name)}`)}</div>` : '';
  const list = `<p class="t8-body2">Chọn mẫu hóa đơn và hình thức ký số mặc định khi phát hành hóa đơn điện tử.</p>
    <div class="t8-mt16 t8-selwrap${s.menu ? ' is-open' : ''}">${select}${s.menu ? selectMenu(TEMPLATES.map(templateOptionLabel)) : ''}</div>${info}`;
  return page(v, { title, list, bar: editorBar({ loading: s.submitting }), toastHtml: s.toast ? pageToast(v, ...s.toast) : '' });
}

// ---------------------------------------------------------------- HD-05

export function automationState(kind) {
  const base = { autoIssue: false, autoSend: false, submitting: false, toast: null };
  const m = {
    off: {},
    'issue-on': { autoIssue: true },
    'both-on': { autoIssue: true, autoSend: true },
    submitting: { autoIssue: true, autoSend: true, submitting: true },
    'toast-saved': { autoIssue: true, autoSend: true, toast: ['success', 'Quy tắc phát hành và gửi email đã được cập nhật.'] },
    'toast-not-ready': { autoIssue: true, toast: ['danger', 'Cần hoàn tất thiết lập hóa đơn điện tử trước khi bật phát hành tự động.'] },
    'toast-state-changed': { autoIssue: true, autoSend: true, toast: ['warning', 'Chính sách tự động đã được cập nhật ở nơi khác. Hãy tải lại rồi lưu lại.'] },
    'toast-error': { autoIssue: true, toast: ['danger', 'Có lỗi xảy ra, vui lòng thử lại.'] },
  }[kind];
  return m ? { ...base, ...m } : null;
}

/**
 * SwitchSettingRow: đệm dọc 8; Row[Expanded(nhãn bodyDefault ép w700 textPrimary), khe 16, VSwitch]; khe 4; mô tả bodySmall textSecondary.
 * enabled false → chỉ công tắc mờ (VSwitch tắt), nhãn / mô tả giữ nguyên màu.
 */
function switchRow(label, supporting, on, enabled) {
  return `<div class="t8-swrow"><div class="t8-swrow__head"><b>${esc(label)}</b><i class="t8-gap-h16"></i>${vswitch(on, { disabled: !enabled })}</div><p class="t8-small t8-mt4">${esc(supporting)}</p></div>`;
}

export function automationPage(v, kind) {
  const title = 'Tự động hóa';
  const st = commonState(kind === 'load-error' ? 'error' : kind);
  if (st) return page(v, { title, content: st });
  const s = automationState(kind);
  const list = card(`<h2 class="t8-h4b">Quy tắc tự động</h2><i class="t8-gap" style="height:16px"></i>
    ${switchRow('Tự động phát hành', 'Khi bật, hệ thống phát hành hóa đơn điện tử khi đơn hàng Hoàn tất và đủ điều kiện.', s.autoIssue, !s.submitting)}
    <hr class="t8-divider t8-divider--16">
    ${switchRow('Tự động gửi email', 'Khi bật, hệ thống gửi hóa đơn điện tử đến email khách hàng sau khi phát hành thành công (chỉ áp dụng với khách hàng có email hợp lệ trong hồ sơ khách hàng).', s.autoSend, !s.submitting)}`);
  return page(v, { title, list, bar: editorBar({ loading: s.submitting }), toastHtml: s.toast ? pageToast(v, ...s.toast) : '' });
}
