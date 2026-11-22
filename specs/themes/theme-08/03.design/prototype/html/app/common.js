// Widget riêng của feature einvoice dùng ở nhiều màn Theme 8.
// Nguồn: apps/erp/lib/features/einvoice/presentation/
//   widgets/{settings_info_row, configuration_editor_bottom_bar, configuration_load_error_state,
//            configuration_permission_denied_state, configuration_query_failure_view}.dart
//   support/{einvoice_datetime_copy, configuration_state_copy}.dart
import { appBar, button, emptyDesc, emptyState, emptyTitle, esc, iconBox, scaffold, toast, centerLoading } from './ds.js';

/** VEmptyMedia(tone:) — tone chỉ đặt ở media nên tiêu đề vẫn textPrimary (khác VEmptyState tone danger của Theme 4). */
const toneMedia = (ic, tone) => iconBox({ ic, size: 64, iconSize: 28.16, radius: 16, cls: `t8-empty__media t8-empty__media--${tone}` });

// ---------------------------------------------------------------- hàm thuần (đối chiếu Dart)

const two = (n) => String(n).padStart(2, '0');
const hm = (d) => `${two(d.getHours())}:${two(d.getMinutes())}`;
const dmy = (d) => `${two(d.getDate())}/${two(d.getMonth() + 1)}/${d.getFullYear()}`;
/** EInvoiceDateTimeCopy.checkedAt / syncedAt / updatedAt: "<nhãn>: HH:mm, dd/MM/yyyy" (giờ máy). */
export const checkedAt = (d) => `Kiểm tra gần nhất: ${hm(d)}, ${dmy(d)}`;
export const syncedAt = (d) => `Đồng bộ gần nhất: ${hm(d)}, ${dmy(d)}`;
export const updatedAt = (d) => `Cập nhật gần nhất: ${hm(d)}, ${dmy(d)}`;

/** ConfigurationStateCopy. */
export const STATE_COPY = {
  permissionTitle: 'Không có quyền truy cập',
  permissionDescription: 'Bạn không có quyền xem hoặc thay đổi thiết lập hóa đơn điện tử của Tổ chức này.',
  permissionAction: 'Quay lại',
  loadErrorTitle: 'Không thể tải dữ liệu',
  loadErrorDescription: 'Không thể tải thiết lập hóa đơn điện tử. Hãy thử lại để kiểm tra mức sẵn sàng.',
  loadErrorAction: 'Thử lại',
};

// ---------------------------------------------------------------- widget

/**
 * SettingsInfoRow: đệm dọc 8; Row[nhãn bodySmall textSecondary, khe 16, Expanded(Row end[Flexible(giá trị bodyDefault w600 canh phải), khe 8 + trailing])].
 * valueTone: success | info | danger (valueColor), mặc định textPrimary. Giá trị không giới hạn dòng (maxLines null) → xuống dòng, canh phải.
 */
export function infoRow(label, value, { tone = '', trailing = '' } = {}) {
  return `<div class="t8-info"><span class="t8-info__label">${esc(label)}</span><span class="t8-info__val"><b class="${tone ? `t8-tone-${tone}` : ''}">${esc(value)}</b>${trailing}</span></div>`;
}

/**
 * ConfigurationEditorBottomBar: Container đệm 16, nền surface, gạch trên borderDefault; SafeArea(top: false) → iPhone thêm 34 đáy.
 * Row[Expanded(VButton secondary "Hủy"), khe 16, Expanded(VButton primary)]. Đang gửi: "Hủy" tắt, nút chính vòng xoay (tắt).
 * Nằm TRONG thân (Column[Expanded(ListView), bar]), không phải VPageScaffold.bottomBar → web: bar rộng bằng cột 720, không hết cửa sổ.
 */
export function editorBar({ cancel = 'Hủy', submit = 'Lưu', loading = false } = {}) {
  return `<div class="t8-editbar"><div class="t8-row2">${button(cancel, { variant: 'secondary', disabled: loading })}${button(submit, { loading })}</div></div>`;
}

/** Thanh dưới tự dựng của HD-02 (trạng thái thông tin): cùng khuôn với editorBar, nội dung tuỳ ý. */
export const plainBar = (inner) => `<div class="t8-editbar">${inner}</div>`;

/**
 * ConfigurationLoadErrorState / ConfigurationPermissionDeniedState: Center(VEmptyState(Column(min)[VEmptyHeader, VEmptyContent(VButton link)])).
 * Không có khe giữa mô tả và nút link (VEmptyContent chỉ giới hạn rộng 360); nút link cao tối thiểu 44 nên vẫn thấy cách.
 */
export function loadErrorState() {
  return emptyState({
    header: [toneMedia('circleX', 'danger'), emptyTitle(STATE_COPY.loadErrorTitle), emptyDesc(STATE_COPY.loadErrorDescription)],
    content: button(STATE_COPY.loadErrorAction, { variant: 'link' }),
  });
}
export function permissionDeniedState() {
  return emptyState({
    header: [toneMedia('lock', 'warning'), emptyTitle(STATE_COPY.permissionTitle), emptyDesc(STATE_COPY.permissionDescription)],
    content: button(STATE_COPY.permissionAction, { variant: 'link' }),
  });
}

/**
 * VPageScaffold(title, showBackButton: true, body) của các màn /more/einvoice/*: route cấp gốc, ngoài StoreShell.
 * body: HTML thân; khi có bar → Column[Expanded(ListView đệm 16 / 16), bar].
 */
export function page(v, { title, content = '', list = '', bar = '', toastHtml = '' }) {
  const body = list
    ? `<div class="t8-list">${list}</div>${bar}`
    : content;
  return scaffold({ appbar: appBar(title, { back: true }), body, placeWidth: v.width, windowWidth: v.width }).replace(/<\/div>\s*$/, `${toastHtml}</div>`);
}

/** Trạng thái chung: đang tải (VLoading 40 giữa), lỗi tải, không quyền. */
export function commonState(kind) {
  if (kind === 'loading') return centerLoading();
  if (kind === 'error') return loadErrorState();
  if (kind === 'no-permission') return permissionDeniedState();
  return '';
}

/**
 * VToast.show trong Scaffold của VPageScaffold (không bottomNavigationBar): SnackBar floating cách đáy 14 + vùng an toàn (iPhone 34).
 * Thanh dưới nằm trong thân nên toast đè lên thanh "Hủy / Lưu". Chỉ hiện message (title không vẽ).
 */
export const pageToast = (v, type, message) => toast(type, '', message, { bottom: 14 + (v.device === 'iphone' ? 34 : 0) });
