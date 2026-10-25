/* shared-patterns.js — Khuôn dùng chung K1–K4, K7 (T7-P mục 5), dựng ở BJ-12.
 *
 * Chỉ dựng chuỗi HTML từ helper có sẵn (appShell, vBanner, ioResult, ac310InfoSurface, ds24Chip, icon, esc, escapeAttribute…);
 * không đọc biến của BJ nào. Hàm trả về phần thân (body) khi không có chữ "Shell"; k3Unknown / k4Result trả cả màn
 * (appShell) vì chân màn là một phần của khuôn.
 *
 *   K1 trạng thái chung      k1Loading, k1Denied, k1Stale, k1Locked, k1Empty, k1ExitAttr
 *   K2 lập → duyệt → kết quả k2Pending, k2Attention, k2Decision, k2RejectSheet
 *   K3 kết quả chưa rõ       k3Unknown
 *   K4 kết quả xong          k4Result, k4ReasonFooter (chân có dòng lý do khi nút tắt)
 *   K6 danh sách công việc   k6TaskList (tìm + chip có số + bảng / danh sách; BJ quyết bước mở tiếp qua rowAttr)
 *   K7 bố cục web            k7Split, k7Table (cột chọn `select`), k7Check, k7FilterChips, k7EditCell (lớp k7-wide gắn qua appShell({ extraClass }))
 *   Thành phần dùng chung    dsSegmented (VSegmentedControl), dsChoiceRow (thẻ lựa chọn lớn có nút tròn) — dựng ở CAP-01
 */

/* ---------- Tiền: ai xem được ---------- */

// Chủ cửa hàng và người duyệt thấy tiền; nhân viên không (chuỗi tiền không được nằm trong DOM). BJ-08 / BJ-11 dùng.
function t7ShowMoney() { return ["approver", "owner"].includes(currentActor()); }
// signed: kèm dấu "+" / "−" (dấu trừ Unicode, không phải gạch nối).
function t7FmtMoney(n, signed = false) {
  const abs = `${Math.round(Math.abs(n)).toLocaleString("vi-VN")} đ`;
  return signed ? `${n < 0 ? "−" : n > 0 ? "+" : ""}${abs}` : abs;
}

/* ---------- K1 — trạng thái chung ---------- */

// Lối "Về Kho": trong chế độ Toàn Theme 7 về Hub Kho; chế độ BJ về màn đầu của luồng.
function k1ExitAttr(firstScreen) {
  const inTheme = typeof ThemeApp !== "undefined" && ThemeApp.inTheme();
  return inTheme ? 'data-theme-sidebar-route="inventory"' : `data-v360-action="fallback-exit" data-v360-target="${escapeAttribute(firstScreen)}"`;
}

// Khung xương theo bố cục màn. Kiểu khối: "heading" | "card" | "row" | "search" | "text".
function k1Loading({ blocks = ["heading", "card", "card"] } = {}) {
  return `<div class="skeleton-stack" data-ds-component="VSkeleton" aria-busy="true" aria-label="Đang tải">${blocks.map((b) => `<div class="skeleton skeleton--${escapeAttribute(b)}"></div>`).join("")}</div>`;
}

function k1Denied({ what, next, exitAttr }) {
  return `<div class="empty-state permission-denied-state k1-denied" data-ds-component="VEmptyState" data-theme-component="PermissionDeniedState" data-composed-from="VEmptyState,VEmptyMedia,VText"><div class="icon-box icon-box--danger" data-ds-component="VEmptyMedia" data-ds-prop-tone="VComponentTone.danger">${icon("lock", "icon--empty-media")}</div><h3 data-ds-component="VEmptyTitle">Bạn chưa có quyền ${esc(what)}</h3><p data-ds-component="VEmptyDescription">${esc(next)}</p><button class="button button--secondary" type="button" ${exitAttr} data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.secondary" data-ds-prop-size="VButtonSize.medium">Về Kho</button></div>`;
}

// Dữ liệu cũ: banner cảnh báo + nút phụ ngay dưới.
function k1Stale({ title, description, actionLabel = "Tải lại", actionAttr }) {
  return `${vBanner("warning", esc(title), esc(description))}<button class="button button--secondary k1-stale-action" type="button" ${actionAttr} data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.secondary" data-ds-prop-size="VButtonSize.medium">${esc(actionLabel)}</button>`;
}

// Khoá: chỉ đọc, nói vì sao; không nút.
function k1Locked({ title, description }) {
  return vBanner("info", esc(title), esc(description));
}

// Rỗng (bảng đã lọc không còn dòng…): lấy emptyBody làm nền.
function k1Empty({ title, description, actionLabel = "", actionAttr = "" }) {
  const base = emptyBody(true)
    .replace("Không có kết quả phù hợp", esc(title))
    .replace("Xóa bớt điều kiện tìm kiếm để xem thêm kết quả.", esc(description));
  const action = actionLabel ? `<button class="button button--secondary" type="button" ${actionAttr} data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.secondary" data-ds-prop-size="VButtonSize.medium">${esc(actionLabel)}</button>` : "";
  return base.replace(/<\/div>$/, `${action}</div>`);
}

/* ---------- K2 — lập → duyệt → kết quả ---------- */

// Người lập, sau khi gửi: banner + ai duyệt, gửi lúc nào + số liệu đã khoá.
// subject: danh từ sau "duyệt" (vd. "sửa sai" → "Chờ chủ cửa hàng duyệt sửa sai · gửi …"); mặc định rỗng.
function k2Pending({ approver, sentAt, facts = [], subject = "" }) {
  return `${vBanner("info", "Đang chờ duyệt", `Chờ ${esc(approver)} duyệt${subject ? ` ${esc(subject)}` : ""} · gửi ${esc(sentAt)}`)}${facts.length ? ac310InfoSurface("Yêu cầu", facts) : ""}<p class="ac310-note k2-lock-note">Dữ liệu đã khoá. Tồn kho chưa thay đổi.</p>`;
}

// Khối "Cần chú ý" (người duyệt và người lập ở rà soát dùng chung).
// attention: [[nhãn, giá trị, tone]] — tone "warning" (mặc định) hoặc "info" cho dòng chỉ để biết (vd. "Sau khi duyệt").
// title "" = khối thông tin không tiêu đề, nền thường (vd. "Sau khi đổi" của BJ-09 — không báo động khi chỉ có dòng info).
function k2Attention(attention = [], { title = "Cần chú ý" } = {}) {
  return attention.length
    ? `<section class="ac310-surface k2-attention${title ? "" : " k2-attention--plain"}" data-layout-pattern="Grouped surface" >${title ? `<div class="ac310-surface__head"><h2>${esc(title)}</h2></div>` : ""}<div class="ac310-key-value-stack">${attention.map(([label, value, tone = "warning"]) => `<div class="k2-attention__row">${icon(tone === "info" ? "info" : "alert", `icon--sm k2-attention__icon k2-attention__icon--${tone}`)}<span>${esc(label)}</span><strong>${esc(value)}</strong></div>`).join("")}</div></section>`
    : "";
}

// Người duyệt. Thứ tự cố định: câu hỏi → dòng người gửi → "Cần chú ý" → số liệu → chi tiết (bảng).
function k2Decision({ question, maker, sentAt, attention = [], facts = [], detail = "" }) {
  return `<div class="ac310-section-title" data-ds-component="VText"><h2>Cần quyết</h2></div><h3 class="k2-question">${esc(question)}</h3><p class="k2-maker">${esc(maker)} gửi ${esc(sentAt)}</p>${k2Attention(attention)}${facts.length ? ac310InfoSurface("", facts) : ""}${detail}`;
}

// Sheet từ chối bắt buộc lý do (giữ chữ của sheet từ chối BJ-12 cũ).
// Tuỳ chọn cho sheet xác nhận khác (BJ-08): description (câu mô tả dưới tiêu đề), reasonLabel / placeholder / closeLabel / confirmLabel,
// withReason: false = sheet không có ô lý do (nút xác nhận luôn bấm được), tone "danger" = nút xác nhận nguy hiểm.
function k2RejectSheet({ open, title, reason, reasonAttr, confirmAttr, closeAttr, description = "", reasonLabel = "Lý do từ chối", placeholder = "Nhập nội dung người lập cần sửa", closeLabel = "Hủy", confirmLabel = "Xác nhận từ chối", withReason = true, tone = "primary" }) {
  if (!open) return "";
  const desc = description ? `<p class="k2-reject-sheet__desc">${esc(description)}</p>` : "";
  const field = withReason ? icTextarea(reasonLabel, reason, reasonAttr, placeholder) : "";
  const disabled = withReason && !String(reason || "").trim() ? "disabled" : "";
  return `<div class="sheet-backdrop" ${closeAttr}><section class="bottom-sheet k2-reject-sheet" role="dialog" aria-modal="true" aria-label="${escapeAttribute(title)}" onclick="event.stopPropagation()" data-ds-component="VBottomSheet" data-figma-node="4695:6353"><div class="sheet-handle"></div><div class="sheet-title"><h3>${esc(title)}</h3></div><div class="sheet-divider"></div><div class="sheet-content">${desc}${field}<div class="sheet-actions">${cfSecondary(closeLabel, closeAttr)}<button class="button button--${tone === "danger" ? "danger" : "primary"}" type="button" ${confirmAttr} data-ds-component="VButton" ${disabled}>${esc(confirmLabel)}</button></div></div></section></div>`;
}

/* ---------- Chân màn dùng chung K3 / K4 ---------- */

// buttons: [{ label, attr, primary, disabled }] — phụ đứng trước, chính đứng sau; một nút thì full.
function k4Footer(buttons) {
  const calibrated = FIGMA_MIGRATED_FLOWS.has(activeFlowId);
  const btn = (b) => `<button class="button button--${b.primary ? "primary" : "secondary"}" type="button" ${b.attr}${b.disabled ? " disabled" : ""} data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.${b.primary ? "primary" : "secondary"}" data-ds-prop-size="VButtonSize.medium">${esc(b.label)}</button>`;
  const dual = buttons.length > 1;
  return `<footer class="app-actions${calibrated ? " figma-sticky-footer" : ""}${dual ? " is-split ac310-two-actions" : ""}" data-ds-component="DS v2 / Sticky Footer" data-ds-prop-layout="${dual ? "Dual" : "Single"}" data-ds-prop-tone="Default">${buttons.map(btn).join("")}</footer>`;
}

// Chân một nút có dòng lý do ngay trên nút (hiện khi nút tắt). BJ-02 / BJ-05 / BJ-06 dùng; BJ đổi chữ lý do qua [data-k4-reason].
// note: dòng mô tả luôn hiện trên nút khi nút bật (vd. BJ-16 "Đóng xong, … mở khoá."); nút tắt thì dòng lý do thay thế.
function k4ReasonFooter({ label, attr, disabled = false, reason = "", tone = "primary", note = "" }) {
  const line = disabled ? reason : note;
  return primaryFooter(label, attr, disabled, tone).replace("<button", `<div class="k4-reason-footer"><p class="k4-reason-footer__reason" data-k4-reason${line ? "" : " hidden"}>${esc(line)}</p><button`).replace("</button></footer>", "</button></div></footer>");
}

/* ---------- K3 — kết quả chưa rõ ---------- */

// title: tiêu đề màn (BJ-02 giữ "Đối soát nhận hàng"); detail: HTML chèn sau bảng số liệu (dòng thời gian bằng chứng…).
// Kết quả và detail cùng một cột (.k3-column): iPhone như cũ, web tối đa 720px giữa khung.
// handoff: { operation, scope } — giá trị gửi sang BJ-17 khi khác chữ hiển thị (vd. mã nghiệp vụ thay cho nhãn); bỏ trống = dùng operation / scope.
function k3Unknown({ operation, scope, ref, sentAt, safe, sourceFlow, exitAttr, facts = [], title = "Xác minh kết quả", detail = "", handoff = {} }) {
  const rows = [["Nghiệp vụ", operation], ["Phạm vi", scope], ["Mã tham chiếu", ref], ["Thời điểm gửi", sentAt], ...facts, ["Trạng thái", "Chưa kết luận"]];
  const body = `<div class="k3-column">${ioResult("Kết quả chưa xác định", `Không gửi lại thao tác. Chuyển đúng lần xử lý này sang xác minh kết quả.${safe ? ` ${safe}` : ""}`, rows, "warning")}${detail}</div>`;
  const handoffAttr = `data-v350-action="handoff-unknown" data-source-flow="${escapeAttribute(sourceFlow)}" data-operation="${escapeAttribute(handoff.operation ?? operation)}" data-scope="${escapeAttribute(handoff.scope ?? scope)}"`;
  return appShell({ title, body, actions: k4Footer([{ label: "Về Kho", attr: exitAttr }, { label: "Chuyển sang xác minh", attr: handoffAttr, primary: true }]), centered: true, back: false, extraClass: "k7-wide" });
}

/* ---------- K4 — kết quả xong ---------- */

// next: [{ label, attr, primary }] — phụ | chính.
// button: HTML đặt sau bảng số liệu (vd. liên kết "Xem {n} dòng hàng").
function k4Result({ screenTitle = "Kết quả", kind = "success", title, description, facts = [], next = [], button = "" }) {
  return appShell({ title: screenTitle, body: ioResult(title, description, facts, kind, button), actions: next.length ? k4Footer(next) : "", centered: true, back: false, extraClass: "k7-wide" });
}

/* ---------- K6 — danh sách công việc ---------- */

// Thân màn danh sách việc: ô tìm → chip có số → bảng (web) / danh sách (iPhone) → khối "không tìm thấy".
// search: { value, attr, placeholder }; filters: { items: [[key, label, count]], selected, attrName }.
// rows: mảng đã lọc, mỗi dòng có status { label, tone } và disabled (dòng chỉ xem: aria-disabled, không mở).
// rowAttr(r): thuộc tính mở bước tiếp của dòng — BJ quyết bước đích, K6 không biết màn nào.
// empty: k1Empty khi không có việc nào (total = 0); filterEmpty: k1Empty khi lọc / tìm ra rỗng, luôn dựng sẵn (ẩn) để ô tìm lọc tại chỗ.
// filterEmptyAttr: tên thuộc tính đánh dấu khối rỗng (vd. `data-io05-filter-empty`).
function k6TaskList({ search, filters, columns, rows, total = rows.length, mobileRow, rowAttr, empty, filterEmpty, filterEmptyAttr }) {
  const head = `${ds24Search(search.value, search.attr, search.placeholder)}${k7FilterChips(filters)}`;
  if (!total) return `${head}${k1Empty(empty)}`;
  const attrOf = (r) => `${rowAttr(r)}${r.disabled ? ' aria-disabled="true"' : ""}`;
  // Dòng iPhone: ds24ListRow({ disabled }) tự gắn aria-disabled, nên chỉ truyền rowAttr (attrOf sẽ gắn trùng).
  const defaultRow = (r) => ds24ListRow({ title: r.title, subtitle: r.subtitle, trailing: ds24Badge(r.status.label, r.status.tone), attrs: rowAttr(r), type: "Navigation", state: r.disabled ? "Disabled" : "Default", disabled: r.disabled });
  const table = rows.length ? k7Table({ columns, rows, mobileRow: mobileRow || defaultRow, caption: search.placeholder, rowAttr: attrOf }) : "";
  return `${head}<section class="k6-list" data-composed-from="DS v2 / List Row,VBadge,VTable">${table}</section><div ${filterEmptyAttr} ${rows.length ? "hidden" : ""}>${k1Empty(filterEmpty)}</div>`;
}

/* ---------- K7 — bố cục web ---------- */

// wideMain: bảng rộng bên trái, khối tóm tắt hẹp bên phải (mặc định cột trái hẹp); asideWebOnly: iPhone không hiện khối phải.
function k7Split({ main, aside, wideMain = false, asideWebOnly = false }) {
  return `<div class="k7-split${wideMain ? " k7-split--wide-main" : ""}"><div class="k7-split__main">${main}</div><aside class="k7-split__aside${asideWebOnly ? " k7-split__aside--web" : ""}">${aside}</aside></div>`;
}

// Ô tick (VCheckbox). k7CheckMark: chỉ phần hộp (dùng khi cả thẻ là một nút); k7Check: nút đủ vùng chạm 44 × 44 cho bảng.
function k7CheckMark(checked, disabled = false) {
  return `<span class="k7-check__box${checked ? " is-checked" : ""}${disabled ? " is-disabled" : ""}" aria-hidden="true">${checked ? icon("check", "icon--sm") : ""}</span>`;
}
function k7Check({ attr, checked = false, disabled = false, label }) {
  return `<button type="button" class="k7-check" role="checkbox" aria-checked="${checked}" aria-label="${escapeAttribute(label)}" ${attr}${disabled ? ' disabled aria-disabled="true"' : ""} data-ds-component="VCheckbox">${k7CheckMark(checked, disabled)}</button>`;
}

// Trả CẢ HAI dạng: bảng (khung web) và danh sách (khung mobile); đổi khung không dựng lại nên CSS ẩn / hiện.
// columns: [{ key, label, align: "start" | "end", mono, html, cls(row) }]; empty: tham số k1Empty khi không còn dòng.
// rowAttr(r): thuộc tính thêm cho <tr> (vd. dòng bấm được); mặc định không có.
// select(r): { attr, checked, disabled, label } → thêm cột ô tick đầu bảng; bỏ trống thì HTML như cũ. Danh sách mobile tự dựng ô tick trong mobileRow.
function k7Table({ columns, rows, mobileRow, caption = "", footer = "", empty = null, rowAttr = null, select = null, selectLabel = "Chọn" }) {
  if (!rows.length && empty) return k1Empty(empty);
  const head = (select ? `<th scope="col" class="k7-col-check"><span class="k7-sr">${esc(selectLabel)}</span></th>` : "") + columns.map((c) => `<th scope="col" class="k7-col-${c.align || "start"}">${esc(c.label)}</th>`).join("");
  const cell = (c, r) => `<td class="k7-col-${c.align || "start"}${c.mono ? " k7-mono" : ""}${c.cls ? ` ${c.cls(r) || ""}` : ""}">${c.html ? r[c.key] : esc(r[c.key] ?? "")}</td>`;
  const body = rows.map((r) => `<tr${rowAttr ? ` ${rowAttr(r)}` : ""}>${select ? `<td class="k7-col-check">${k7Check(select(r))}</td>` : ""}${columns.map((c) => cell(c, r)).join("")}</tr>`).join("");
  const foot = footer ? `<p class="k7-table__footer">${esc(footer)}</p>` : "";
  return `<div class="k7-table-wrap"><table class="k7-table" data-ds-component="VTable">${caption ? `<caption>${esc(caption)}</caption>` : ""}<thead><tr>${head}</tr></thead><tbody>${body}</tbody></table><div class="k7-table-list">${rows.map((r) => mobileRow(r)).join("")}</div>${foot}</div>`;
}

// items: [[key, label, count]] — chip có số: "Tất cả 82"; số 0 thì mờ (đổi sang chữ phụ, vẫn đủ tương phản).
function k7FilterChips({ items, selected, attrName }) {
  return `<div class="ds24-chip-scroll k7-chips" role="group" aria-label="Lọc dòng" data-composed-from="VChip">${items.map(([key, label, count]) => {
    const chip = ds24Chip(key, count == null ? label : `${label} ${count}`, selected === key, attrName);
    return count === 0 ? chip.replace('class="ds24-chip', 'class="ds24-chip k7-chip--zero') : chip;
  }).join("")}</div>`;
}


// Ô số sửa tại dòng (bảng / form): hậu tố đơn vị, lỗi dưới ô, aria-label cho trình đọc màn hình.
// attr: thuộc tính định danh ô (vd. `data-cap-threshold="INV-OXY"`); value rỗng = chưa có giá trị.
function k7EditCell({ value, attr, unit = "", error = "", label, disabled = false }) {
  const invalid = error ? ' aria-invalid="true"' : "";
  return `<span class="k7-edit${error ? " k7-edit--error" : ""}" data-ds-component="VNumberField"><span class="k7-edit__box"><input type="number" inputmode="numeric" min="0" step="1" value="${escapeAttribute(value ?? "")}" ${attr} aria-label="${escapeAttribute(label)}"${invalid}${disabled ? " disabled" : ""}>${unit ? `<em class="k7-edit__unit" aria-hidden="true">${esc(unit)}</em>` : ""}</span>${error ? `<small class="field-error" role="alert">${esc(error)}</small>` : ""}</span>`;
}

/* ---------- Thành phần dùng chung ---------- */

// items: [[key, label]]; thanh chọn hai / ba mục. Mục đang chọn aria-pressed; attr đặt trên từng nút (giá trị = key).
function dsSegmented({ items, value, attr, label = "Chọn mục" }) {
  return `<div class="ds-segmented" role="group" aria-label="${escapeAttribute(label)}" data-ds-component="VSegmentedControl">${items.map(([key, text]) => `<button type="button" class="ds-segment${key === value ? " is-selected" : ""}" ${attr}="${escapeAttribute(key)}" aria-pressed="${key === value}">${esc(text)}</button>`).join("")}</div>`;
}

// Dòng chọn có nút tròn (thẻ lựa chọn lớn); nhóm bọc bằng role="radiogroup" ở nơi gọi.
function dsChoiceRow({ title, subtitle = "", selected = false, attrs = "", disabled = false }) {
  const trailing = `<span class="ds-radio${selected ? " is-selected" : ""}" aria-hidden="true"></span>`;
  return ds24ListRow({ title, subtitle, trailing, leading: null, attrs: `${attrs} role="radio" aria-checked="${selected}"`, type: "Selection", state: disabled ? "Disabled" : selected ? "Selected" : "Default", interactive: true, disabled, extraClass: `ds-choice-row${selected ? " is-selected" : ""}` });
}
