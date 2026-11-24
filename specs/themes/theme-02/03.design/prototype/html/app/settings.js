// Đợt 4 — Cài đặt sản phẩm (/more/product-settings/…, route gốc ngoài khung: web không có thanh bên, thân cột 720).
// Nguồn Flutter (apps/erp/lib/features/catalog/presentation/):
//   pages/settings/product_settings_page.dart (SP-14), custom_field_groups_page.dart (SP-15), custom_field_group_detail_page.dart +
//   upsert_custom_field_group_page.dart (SP-16), upsert_custom_field_page.dart (SP-17), store_price_rule_settings_page.dart (SP-18),
//   edit_store_price_rule_page.dart (SP-19), store_price_rule_change_history_page.dart (SP-20);
//   widgets/{custom_field_group_deactivate_confirm_sheet, custom_field_deactivate_confirm_sheet, unsaved_changes_confirm_sheet,
//   store_price_rule_save_confirm_sheet, store_price_rule_change_history_entry_card, product_form_bottom_bar}.dart;
//   packages/c45_design_system/lib/src/components/v_modal.dart (showVConfirmDialog).
import { icon } from '../shared/icons.js';
import { appBar, badge, button, card, esc, field, gap, iconBox, input, scaffold, select, suffixText, textArea } from './ds.js';
import { money } from './data.js';
import { formBar } from './sub.js';

const back = () => `<button type="button" class="t2-appbar__back" aria-label="Quay lại">${icon('arrowLeft')}</button>`;
const page = (v, { title, body, bottomBar = '', arrow = false, actions = '' }) => scaffold({
  appbar: appBar(title, { leading: arrow ? back() : '', back: !arrow, actions }), body, bottomBar, placeWidth: v.width, windowWidth: v.width,
});
const center = (html) => `<div class="t2-center">${html}</div>`;
const spinner = () => center('<span class="t2-spin t2-spin--material"></span>');

// ---------------------------------------------------------------- hàm thuần (đối chiếu Dart)

/** Store rule: tỉ lệ × 100 toStringAsFixed(1); giá niêm yết có "+", giá sàn không. */
export const pct1 = (r) => (r * 100).toFixed(1);
export const ruleValues = (rule) => (rule ? [`+${pct1(rule.list)}%`, `${pct1(rule.floor)}%`] : ['—', '—']);
/** _formatDelta: "(+25.0% → +28.0%)"; không có giá trị trước → null. */
export const deltaText = (before, after, prefix = '') => (before == null ? null : `(${prefix}${pct1(before)}% → ${prefix}${pct1(after)}%)`);
/** Nhãn kiểu trường ở thẻ trường (_buildFieldCard) — khác nhãn ở ô chọn kiểu dữ liệu (labelVi). */
export const TYPE_CARD = { text: 'Text', number: 'Số', date: 'Ngày tháng', boolean: 'Bật/Tắt', singleSelect: 'Single select' };
export const TYPE_SELECT = { text: 'Văn bản', number: 'Số', singleSelect: 'Tùy chọn', date: 'Ngày', boolean: 'Bật/Tắt' };
/** Dòng phụ thẻ trường: kiểu • Bắt buộc • Tìm kiếm • Lọc • Hiển thị. */
export const fieldMeta = (f) => [TYPE_CARD[f.type], ...(f.required ? ['Bắt buộc'] : []), ...[f.search && 'Tìm kiếm', f.filter && 'Lọc', f.list && 'Hiển thị'].filter(Boolean)].join(' • ');

// ---------------------------------------------------------------- SP-14

/** ProductSettingsPage: VPageScaffold("Sản phẩm", ‹). ListView đệm 16; 2 VCard (đệm 16 / 14): VIconBox 44 (nền surface, icon primary 20, bo 12), khe 12, tiêu đề H4 w700 + mô tả 2 dòng, chevron 20. */
export function settingsPage(v) {
  const item = (ic, t, d) => card(`<div class="t2-setitem">${iconBox({ ic, size: 44, cls: 't2-ibox--plainbrand' })}<span><b>${esc(t)}</b>${gap(4)}<span>${esc(d)}</span></span>${icon('chevronRight')}</div>`, { cls: 't2-card--tap t2-card--p1614' });
  const body = `<div class="t2-subscroll">${item('tag', 'Giá sàn & Giá niêm yết', 'Cấu hình khung giá cửa hàng dùng làm mặc định khi định giá sản phẩm')}${gap(12)}${item('list', 'Nhóm & trường thông tin', 'Cấu hình các nhóm và trường thông tin bổ sung cho sản phẩm')}</div>`;
  return page(v, { title: 'Sản phẩm', body });
}

// ---------------------------------------------------------------- SP-15 nhóm

const GROUPS = [
  { name: 'Thông tin dược', emoji: '💊', fields: 4, required: 1, active: true },
  { name: 'Dinh dưỡng', emoji: '🥛', fields: 3, required: 0, active: true },
  { name: 'Quy cách cũ', emoji: '📦', fields: 2, required: 1, active: false },
];
const grip = () => `<span class="t2-grip">${icon('grip')}</span>`;

/**
 * CustomFieldGroupsPage: VPageScaffold("Nhóm & trường thông tin", ‹, action IconButton + primary). Banner vàng tự vẽ (bo 8, đệm 12) "Thứ tự … Kéo ⠿ để sắp xếp.";
 * thẻ nhóm VCard(16): tay kéo textMuted + khe 12, tên H4 w600, VBadge "Đang dùng" / "Tạm tắt" (cỡ thường), "n trường • m bắt buộc", chevron textMuted. Nhóm tắt xuống cuối.
 * Rỗng: icon inbox 64 textMuted + "Chưa có nhóm thông tin nào" + "Tạo mẫu mặc định". Lỗi: chỉ toast.
 */
export function groupsPage(kind, v) {
  const add = `<button type="button" class="t2-icon-btn t2-icon-btn--brand" aria-label="Thêm nhóm">${icon('plus')}</button>`;
  let body;
  if (kind === 'loading') body = spinner();
  else if (kind === 'empty') body = center(`<div class="t2-histstate is-muted64">${icon('inbox')}${gap(16)}<p>Chưa có nhóm thông tin nào</p>${gap(16)}${button('Tạo mẫu mặc định')}</div>`);
  else {
    const cardOf = (g) => card(`<div class="t2-grprow">${grip()}<span class="t2-grprow__text"><span class="t2-grprow__head"><b>${esc(g.name)}</b>${badge(g.active ? 'Đang dùng' : 'Tạm tắt', { tone: g.active ? 'success' : 'neutral' })}</span>${gap(4)}<small>${g.fields} trường • ${g.required} bắt buộc</small></span><span class="t2-chev-muted">${icon('chevronRight')}</span></div>`, { cls: 't2-card--tap' });
    body = `<div class="t2-setlist"><div class="t2-warnhint">${icon('info')}<span>Thứ tự nhóm và trường sẽ hiển thị tương ứng trong màn hình sản phẩm. Kéo <i class="t2-gripinline">${icon('grip')}</i> để sắp xếp.</span></div>${gap(12)}${GROUPS.map(cardOf).join(gap(12))}</div>`;
  }
  return page(v, { title: 'Nhóm & trường thông tin', body, actions: add });
}

// ---------------------------------------------------------------- SP-16 chi tiết nhóm

const FIELDS = [
  { name: 'Dạng bào chế', type: 'singleSelect', required: true, search: true, filter: true, list: true, active: true },
  { name: 'Hàm lượng (mg)', type: 'number', search: true, active: true },
  { name: 'Kê đơn', type: 'boolean', filter: true, active: true },
  { name: 'Ghi chú cũ', type: 'text', active: false },
];

/**
 * CustomFieldGroupDetailPage: VPageScaffold(tên nhóm, ‹, action ⋮ → mở sửa nhóm). Hàng: nhãn tự vẽ "Đang dùng" (pill, đệm 8 / 2) + "n trường • m bắt buộc";
 * hàng "TRƯỜNG THÔNG TIN" | "+ Thêm trường" (chữ success 13, không vùng chạm 44); thẻ trường: tay kéo, tên H4 w600 + "*" đỏ + [nhãn "Tạm tắt"], dòng phụ, chevron.
 * Rỗng: khung trắng bo 12 đệm 40 / 16: hộp successBg + icon 32, "Chưa có trường nào" H4, câu, khe 24, "+ Thêm trường thông tin" — hai lối thêm.
 */
export function groupDetailPage(kind, v) {
  const active = kind !== 'inactive';
  const more = `<button type="button" class="t2-icon-btn" aria-label="Sửa nhóm">${icon('moreVert')}</button>`;
  const status = `<div class="t2-grpstatus"><span class="t2-pill${active ? ' is-on' : ''}">${active ? 'Đang dùng' : 'Tạm tắt'}</span><small>${kind === 'empty' ? 0 : 4} trường • ${kind === 'empty' ? 0 : 1} bắt buộc</small></div>`;
  const head = `<div class="t2-grphead"><span>TRƯỜNG THÔNG TIN</span><button type="button" class="t2-addtext">${icon('plus')}<span>Thêm trường</span></button></div>`;
  let list;
  if (kind === 'empty') {
    list = `<div class="t2-pad16x"><div class="t2-fieldempty"><span class="t2-fieldempty__ic">${icon('listCheck')}</span>${gap(16)}<b>Chưa có trường nào</b>${gap(8)}<p>Thêm trường đầu tiên cho nhóm này.</p>${gap(24)}${button('Thêm trường thông tin', { cls: 't2-btn--lead' })}</div></div>`;
  } else {
    list = FIELDS.map((f) => `<div class="t2-pad16x t2-mb12">${card(`<div class="t2-grprow">${grip()}<span class="t2-grprow__text"><span class="t2-grprow__head t2-grprow__head--start"><b class="${f.active ? '' : 'is-off'}">${esc(f.name)}</b>${f.required ? '<i class="t2-req">*</i>' : ''}${f.active ? '' : '<em class="t2-pill t2-pill--xs">Tạm tắt</em>'}</span>${gap(4)}<small>${esc(fieldMeta(f))}</small></span><span class="t2-chev-muted">${icon('chevronRight')}</span></div>`, { cls: 't2-card--tap' })}</div>`).join('');
  }
  const body = `<div class="t2-setscroll">${status}${head}${list}</div>`;
  return page(v, { title: 'Thông tin dược', body, actions: more });
}

// ---------------------------------------------------------------- SP-16 tạo / sửa nhóm

const EMOJIS = ['💊', '🧪', '💉', '🩺', '🧬', '🧫', '🏥', '🌡️', '📦', '🏷️', '📋', '📝', '🗂️', '🧾', '🔒', '⚠️', '🐄', '🐖', '🐔', '🐟', '🐶', '🐱', '🌾', '🏭', '🥛', '🍖', '🌿', '🔬', '🧴', '🧰'];

/** Switch Material tự cấu hình: bật nền success, **tắt nền borderStrong** (VSwitch dùng borderInput đậm hơn). */
const mswitch = (on) => `<span class="t2-switch-hit"><span class="t2-switch t2-switch--light${on ? ' is-on' : ''}"><i></i></span></span>`;

/**
 * UpsertCustomFieldGroupPage: VPageScaffold("Tạo nhóm thông tin" / "Sửa nhóm thông tin", arrowBack). ListView đệm 16: "Icon" bodyDefault w600;
 * ô 56 (emoji 28) + câu nhỏ; lưới **8 cột** emoji (ô bo 8, chọn → surfaceBrand + viền primary); "Tên nhóm *" (dấu * nằm trong chữ nhãn, cùng màu);
 * "Mô tả (tuỳ chọn)" 3 dòng; [sửa: "Trạng thái hoạt động" + Switch]. bottomBar ProductFormBottomBar.
 */
export function upsertGroupPage(kind, v) {
  const edit = kind !== 'create';
  const sel = edit ? '💊' : '📋';
  const grid = `<div class="t2-emojigrid">${EMOJIS.map((e) => `<span class="t2-emoji${e === sel ? ' is-on' : ''}">${e}</span>`).join('')}</div>`;
  const body = `<div class="t2-subscroll"><b class="t2-bodyb">Icon</b>${gap(8)}<div class="t2-iconpick"><span class="t2-iconpick__big">${sel}</span><p class="t2-small">Icon sẽ hiển thị trên card nhóm ở màn hình chi tiết sản phẩm và tạo sản phẩm.</p></div>${gap(16)}${grid}${gap(16)}
    ${field({ label: 'Tên nhóm *', control: input({ value: edit ? 'Thông tin dược' : '', hint: 'Nhập tên nhóm' }) })}${gap(16)}
    ${field({ label: 'Mô tả (tuỳ chọn)', control: textArea({ value: edit ? 'Thông tin bắt buộc với thuốc thú y' : '', hint: 'Nhập mô tả nhóm', minLines: 3 }) })}
    ${edit ? `${gap(16)}<div class="t2-swrow"><b class="t2-bodyb">Trạng thái hoạt động</b>${mswitch(true)}</div>` : ''}</div>`;
  return page(v, { title: edit ? 'Sửa nhóm thông tin' : 'Tạo nhóm thông tin', body, arrow: true, bottomBar: formBar({ enabled: kind === 'create-dirty' }) });
}

// ---------------------------------------------------------------- SP-17 tạo / sửa trường

/**
 * UpsertCustomFieldPage: VPageScaffold("Tạo trường thông tin" / "Cấu hình trường", arrowBack). Tên, Mô tả, VSelect "Kiểu dữ liệu" (+ câu cảnh báo), "Nhóm" (ô tắt mờ),
 * [Tùy chọn: nhãn bodySmall w600 | TextButton.icon "+ Thêm"; mỗi dòng: tay kéo 16 + ô + IconButton thùng rác đỏ], "THUỘC TÍNH" + khung bo 12 các hàng Switch (đệm 16 / 12, gạch ngăn),
 * [sửa: "TRẠNG THÁI" + khung "Đang dùng"]; khe 40. bottomBar ProductFormBottomBar.
 */
export function upsertFieldPage(kind, v) {
  const edit = kind === 'edit' || kind === 'locked';
  const type = kind === 'select' || edit ? 'singleSelect' : 'text';
  const req = edit || kind === 'select';
  const warn = kind === 'locked' ? '<p class="t2-small t2-small--warn">Không đổi được kiểu dữ liệu do đã có dữ liệu.</p>' : kind === 'edit' ? '<p class="t2-small t2-small--warn">Thay đổi kiểu dữ liệu có thể ảnh hưởng đến tương thích dữ liệu cũ.</p>' : '';
  const opts = type === 'singleSelect'
    ? `${gap(24)}<div class="t2-optshead"><b>Tùy chọn</b><button type="button" class="t2-textbtn-icon t2-textbtn-icon--fg">${icon('plus')}<span>Thêm</span></button></div>${gap(12)}${['Viên nén', 'Dung dịch', 'Bột'].map((o) => `<div class="t2-optrow"><span class="t2-grip t2-grip--16">${icon('grip')}</span>${input({ value: o, hint: 'Nhập tên tùy chọn' })}<button type="button" class="t2-icon-btn t2-icon-btn--danger" aria-label="Xoá">${icon('trash')}</button></div>`).join('')}`
    : '';
  const prow = (l, on, sub = '') => `<div class="t2-proprow"><span><b>${esc(l)}</b>${sub ? `${gap(4)}<small>${esc(sub)}</small>` : ''}</span>${mswitch(on)}</div>`;
  const props = [
    prow('Bắt buộc', req, req ? 'Tham gia tính readiness của sản phẩm' : ''),
    prow('Cho phép tìm kiếm', edit),
    ...(type === 'singleSelect' || type === 'boolean' ? [prow('Cho phép lọc', edit)] : []),
    prow('Hiển thị trên danh sách sản phẩm', edit, edit ? 'Danh sách sản phẩm chỉ hiển thị giới hạn field.' : ''),
  ].join('<hr class="t2-divider">');
  const body = `<div class="t2-subscroll">
    ${field({ label: 'Tên trường', control: input({ value: edit || kind === 'select' ? 'Dạng bào chế' : '', hint: 'Nhập tên trường' }) })}${gap(16)}
    ${field({ label: 'Mô tả (tuỳ chọn)', control: textArea({ value: '', hint: 'Nhập mô tả', minLines: 2 }) })}${gap(16)}
    ${field({ label: 'Kiểu dữ liệu', control: select({ value: TYPE_SELECT[type] }) })}${warn ? `${gap(8)}${warn}` : ''}${gap(16)}
    ${field({ label: 'Nhóm', control: input({ value: 'Thông tin dược', disabled: true }) })}${opts}
    ${gap(24)}<p class="t2-caps">THUỘC TÍNH</p>${gap(12)}<div class="t2-propbox">${props}</div>
    ${edit ? `${gap(24)}<p class="t2-caps">TRẠNG THÁI</p>${gap(12)}<div class="t2-propbox">${prow('Đang dùng', true)}</div>` : ''}${gap(40)}</div>`;
  return page(v, { title: edit ? 'Cấu hình trường' : 'Tạo trường thông tin', body, arrow: true, bottomBar: formBar({ enabled: kind === 'select' }) });
}

/** showVConfirmDialog → VConfirmDialog: Dialog bo 16, đệm 20, tiêu đề H3 w700 trái, câu, khe 24, Wrap phải "Hủy" | "Xác nhận" (cỡ nội dung, không đầy ngang). */
export const confirmDialog = () => `<div class="sh-scrim sh-scrim--dialog"><section class="t2-vconfirm" role="dialog" aria-modal="true" aria-label="Bật bắt buộc cho trường"><h2>Bật bắt buộc cho trường</h2>${gap(8)}<p>Sản phẩm hiện tại chưa điền trường này có thể phát sinh blocker readiness. Dữ liệu hiện có không bị xóa.</p>${gap(24)}<div class="t2-vconfirm__btns">${button('Hủy', { variant: 'secondary' })}${button('Xác nhận')}</div></section></div>`;

/** Sheet "Tạm tắt …" (không tiêu đề sheet; tiêu đề tự vẽ H3 trong nội dung), "Huỷ" | "Tạm tắt" đỏ. */
const selfTitled = (title, text, primary) => `<div class="t2-lc t2-lc--top16"><h3 class="t2-h3">${esc(title)}</h3>${gap(12)}<p class="t2-sheettext">${esc(text)}</p>${gap(24)}<div class="t2-btnrow16">${button('Huỷ', { variant: 'secondary', full: true })}${button(primary, { full: true, tone: 'danger' })}</div></div>`;
export const groupDeactivateSheet = () => selfTitled('Tạm tắt nhóm này?', 'Nhóm đang có 4 trường (1 bắt buộc). Dữ liệu đã nhập trên sản phẩm sẽ được giữ lại. Nhóm sẽ không hiển thị khi tạo/sửa sản phẩm mới.', 'Tạm tắt');
export const fieldDeactivateSheet = () => selfTitled('Tạm tắt trường này?', 'Dữ liệu đã nhập trên sản phẩm sẽ được giữ lại. Trường sẽ không hiển thị khi tạo/sửa sản phẩm mới.', 'Tạm tắt');
/** UnsavedChangesConfirmSheet (sheet có tiêu đề "Thoát mà không lưu?"): câu + "Ở lại" | "Thoát" đỏ. */
export const unsavedSheet = () => `<div class="t2-lc"><p class="t2-sheettext">Thay đổi chưa lưu sẽ bị mất.</p>${gap(24)}<div class="t2-btnrow16">${button('Ở lại', { variant: 'secondary', full: true })}${button('Thoát', { full: true, tone: 'danger' })}</div></div>`;

// ---------------------------------------------------------------- SP-18 khung giá cửa hàng

const RULE = { list: 0.28, floor: 0.14 };

/**
 * StorePriceRuleSettingsPage: VPageScaffold("Giá sàn & Giá niêm yết", ‹). ListView đệm 16 / 16: [banner lỗi đỏ + "Thử lại"], thẻ giới thiệu (icon cửa hàng 44 surfaceBrand),
 * khe 20, thẻ "CẤU HÌNH HIỆN TẠI" | "✎ Sửa" (2 hàng: icon xu hướng lên xanh "+28.0%" / **xu hướng xuống đỏ "14.0%"**), khe 20, thẻ "Lưu ý" vàng, khe 16, thẻ "Lịch sử thay đổi" ›.
 */
export function storeRulePage(kind, v) {
  if (kind === 'loading') return page(v, { title: 'Giá sàn & Giá niêm yết', body: spinner() });
  const rule = kind === 'empty' ? null : RULE;
  const [lv, fv] = ruleValues(rule);
  const errBanner = kind === 'error' ? `<div class="t2-errbanner">${icon('error')}<span>Đã xảy ra lỗi. Vui lòng thử lại.</span><button type="button" class="t2-ctabtn t2-ctabtn--plain">Thử lại</button></div>${gap(16)}` : '';
  const info = `<div class="t2-box12 t2-ruleinfo">${iconBox({ ic: 'store', size: 44, iconSize: 22, cls: 't2-ibox--brand' })}<span><b>Khung giá cửa hàng</b>${gap(4)}<span>Các đơn vị chọn <strong>"Theo khung giá cửa hàng"</strong> sẽ tự động áp dụng tỷ lệ dưới đây để tính Giá niêm yết và Giá sàn từ Giá cơ sở.</span></span></div>`;
  const vrow = (ic, tone, l, sub, val) => `<div class="t2-rulerow"><span class="t2-rulerow__ic is-${tone}">${icon(ic)}</span><span><b>${esc(l)}</b>${gap(2)}<small>${esc(sub)}</small></span><strong class="is-${tone}">${esc(val)}</strong></div>`;
  const cfg = `<div class="t2-box12"><div class="t2-rulehead"><span>CẤU HÌNH HIỆN TẠI</span><button type="button" class="t2-editlink">${icon('edit')}<span>Sửa</span></button></div>${gap(16)}${rule ? '' : `<p class="t2-small">Chưa cấu hình khung giá cửa hàng. Nhấn Sửa để thiết lập tỷ lệ lãi và giá sàn.</p>${gap(12)}`}${vrow('trendingUp', 'up', 'Giá niêm yết', 'Tỷ lệ lãi so với Giá cơ sở', lv)}<div class="t2-pad12y"><hr class="t2-divider"></div>${vrow('trendingDown', 'down', 'Giá sàn', 'Tỷ lệ sàn so với Giá cơ sở', fv)}</div>`;
  const note = `<div class="t2-box12 t2-notewarn"><span class="t2-notewarn__head">${icon('info')}<b>Lưu ý</b></span>${gap(8)}<span class="t2-dotrow"><i></i><span>Giá sẽ tự cập nhật cho các đơn vị chọn <strong>"Theo khung giá cửa hàng"</strong>.</span></span>${gap(8)}<span class="t2-dotrow"><i></i><span>Không áp dụng cho đơn vị chọn <strong>"Tự động riêng theo cấu hình"</strong> hoặc <strong>"Nhập thủ công"</strong>.</span></span></div>`;
  const hist = card(`<div class="t2-setitem">${iconBox({ ic: 'history', size: 40, cls: 't2-ibox--brand' })}<span><b>Lịch sử thay đổi</b>${gap(4)}<span>Xem các thay đổi khung giá cửa hàng</span></span>${icon('chevronRight')}</div>`, { cls: 't2-card--tap t2-card--p1614' });
  const body = `<div class="t2-subscroll">${errBanner}${info}${gap(20)}${cfg}${gap(20)}${note}${gap(16)}${hist}</div>`;
  return page(v, { title: 'Giá sàn & Giá niêm yết', body });
}

// ---------------------------------------------------------------- SP-19 sửa khung giá cửa hàng

/**
 * EditStorePriceRulePage: VPageScaffold("Chỉnh sửa khung giá", ‹). Banner vàng; mỗi tỉ lệ: nhãn bodyDefault w600, khe 8, Row[VTextFormField (**ô nhiều dòng**, minLines 2, chữ H4 w600,
 * hậu tố %, helperText) | khe 8 | cột 2 nút 36 ▲ ▼ (bước 0,1)], khe 4, **helperText lặp lại** bodySmall. "XEM TRƯỚC VỚI VÍ DỤ": ô giá cơ sở ví dụ 100.000 đ + giá dự kiến (sàn chữ đỏ).
 * Lưu → sheet "Áp dụng quy tắc lên sản phẩm đã có giá?".
 */
export function storeRuleEditPage(kind, v) {
  const err = kind === 'error';
  const list = '28.0';
  const floor = err ? '35.0' : '14.0';
  const banner = `<div class="t2-warnhint">${icon('info')}<span>Tỷ lệ dưới đây sẽ được áp dụng cho mọi đơn vị chọn <strong>"Theo khung giá cửa hàng"</strong>.</span></div>`;
  const pctField = (l, val, e) => `<b class="t2-bodyb">${esc(l)}</b>${gap(8)}<div class="t2-steprow"><span class="t2-steprow__field">${field({ control: `<span class="t2-textarea t2-textarea--num${e ? ' is-invalid' : ''}" style="min-height:${2 * 22 + 24}px"><textarea rows="2">${esc(val)}</textarea>${suffixText('%')}</span>`, error: e })}${e ? '' : '<span class="t2-helper">Tính theo % trên Giá cơ sở</span>'}</span><span class="t2-stepbtns"><span>${icon('chevronUp')}</span>${gap(4)}<span>${icon('chevronDown')}</span></span></div>${gap(4)}<p class="t2-small">Tính theo % trên Giá cơ sở</p>`;
  const base = 100000;
  const prev = `<div class="t2-box12"><span class="t2-caps2">XEM TRƯỚC VỚI VÍ DỤ</span>${gap(12)}<p class="t2-small">Giá cơ sở (ví dụ)</p>${gap(8)}${input({ value: '100.000', suffix: suffixText('đ') })}${gap(12)}<div class="t2-pricerow"><span>Giá niêm yết (dự kiến)</span><b class="is-up">${esc(money(base * (1 + Number(list) / 100)))}</b></div>${gap(8)}<div class="t2-pricerow"><span>Giá sàn (dự kiến)</span><b class="is-down">${esc(money(base * (1 + Number(floor) / 100)))}</b></div></div>`;
  const body = `<div class="t2-subscroll">${banner}${gap(20)}${pctField('Giá niêm yết (tỷ lệ lãi)', list, null)}${gap(20)}${pctField('Giá sàn (tỷ lệ sàn)', floor, err ? 'Giá sàn không được lớn hơn giá niêm yết.' : null)}${gap(20)}${prev}</div>`;
  return page(v, { title: 'Chỉnh sửa khung giá', body, bottomBar: formBar({ enabled: !err && kind !== 'default' }) });
}
/** StorePriceRuleSaveConfirmSheet (không tiêu đề sheet): tiêu đề tự vẽ + câu + "Hủy" | "Áp dụng". */
export const ruleSaveSheet = () => `<div class="t2-lc t2-lc--top16"><h3 class="t2-h3">Áp dụng quy tắc lên sản phẩm đã có giá?</h3>${gap(12)}<p class="t2-sheettext">Thay đổi tỷ lệ lãi/sàn sẽ tự động áp dụng và cập nhật lại giá bán cho toàn bộ sản phẩm đang sử dụng "Khung giá cửa hàng".</p>${gap(24)}<div class="t2-btnrow16">${button('Hủy', { variant: 'secondary', full: true })}${button('Áp dụng', { full: true })}</div></div>`;

// ---------------------------------------------------------------- SP-20 lịch sử khung giá cửa hàng

const RULE_HIST = [
  { at: '2026-11-20 15:30', current: true, actor: '3f9a2c1b', list: [0.25, 0.28], floor: [0.12, 0.14] },
  { at: '2026-11-02 09:10', actor: 'a71d09e4', list: [0.2, 0.25], floor: [0.1, 0.12] },
  { at: '2026-10-15 08:00', actor: '3f9a2c1b', list: [null, 0.2], floor: [null, 0.1] },
];

/**
 * StorePriceRuleChangeHistoryPage: VPageScaffold("Lịch sử thay đổi", ‹ — cùng tiêu đề với SP-22, không ghi của gì). Banner vàng "Lịch sử chỉ ghi nhận …";
 * thẻ (bo 12, đệm 16): ngày bold | nhãn "Hiện tại"; "Bởi: 3f9a2c1b"; "Giá niêm yết  +28.0%" + "(+25.0% → +28.0%)" nhỏ phải; "Giá sàn  14.0%" + "(12.0% → 14.0%)".
 * Rỗng: icon lịch sử + "Chưa có lịch sử thay đổi". Lỗi: một dòng chữ xám.
 */
export function ruleHistoryPage(kind, v) {
  let body;
  if (kind === 'loading') body = spinner();
  else if (kind === 'error') body = center('<p class="t2-centertext">Đã xảy ra lỗi. Vui lòng thử lại.</p>');
  else {
    const banner = `<div class="t2-warnhint">${icon('info')}<span>Lịch sử chỉ ghi nhận các thay đổi khung giá cửa hàng.</span></div>`;
    const entry = (e) => {
      const ld = deltaText(e.list[0], e.list[1], '+');
      const fd = deltaText(e.floor[0], e.floor[1]);
      return `<div class="t2-hist t2-hist--rule"><div class="t2-hist__head"><b>${esc(e.at)}</b>${e.current ? '<span class="t2-curchip">Hiện tại</span>' : ''}</div>${gap(4)}<small>Bởi: ${esc(e.actor)}</small>${gap(8)}
        <div class="t2-pricerow t2-pricerow--plain"><span>Giá niêm yết</span><b>+${pct1(e.list[1])}%</b></div>${ld ? `${gap(4)}<small class="t2-right">${esc(ld)}</small>` : ''}${gap(8)}
        <div class="t2-pricerow t2-pricerow--plain"><span>Giá sàn</span><b>${pct1(e.floor[1])}%</b></div>${fd ? `${gap(4)}<small class="t2-right">${esc(fd)}</small>` : ''}</div>`;
    };
    const list = kind === 'empty' ? `<div class="t2-pad32y">${center(`<div class="t2-histstate is-empty">${icon('history')}${gap(16)}<p>Chưa có lịch sử thay đổi</p></div>`)}</div>` : RULE_HIST.map(entry).join('');
    body = `<div class="t2-histlist">${banner}${gap(12)}${list}</div>`;
  }
  return page(v, { title: 'Lịch sử thay đổi', body });
}
