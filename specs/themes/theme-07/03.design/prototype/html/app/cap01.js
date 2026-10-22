/* CAP-01 — Chính sách tồn & cận hạn (CAP-01). Màn: SCR-062 Ngưỡng tồn, SCR-063 Cận hạn, SCR-065 Kết quả (chỉ khi chưa rõ / bị từ chối).
 *
 * Thiết kế lại (T7-P CAP-01, 2026-10-21, v5.7.0): 062 là bảng sản phẩm sửa tại dòng (web) hoặc một sản phẩm (iPhone)
 * (vào từ BJ-01); 063 là mặc định + sản phẩm có chính sách riêng; SCR-064 Rà soát thành sheet tác động trong 062;
 * lưu thành công ở lại màn + toast. Sửa CAP-01: sửa thẳng file này.
 * Dùng chung từ app/core.js: appShell, ds24ListRow, ds24Badge, ds24DotBadge, ds24InfoRow, vBanner, primaryFooter, esc,
 * escapeAttribute, navigate, render, renderAppScreen, syncReviewUrl, showToast, currentActor, screenAliases, stateByScreen.
 * Từ khuôn: k1Locked, k1Stale, k1Denied, k1ExitAttr, k1Empty (K1); k3Unknown (K3); k4Result, k4Footer (K4);
 * k7Table, k7FilterChips, k7EditCell (K7); dsSegmented, dsChoiceRow. Từ BJ-01: bj01Products, bj01Indicators, BJ01_STOCK_TONE.
 * Ngưỡng tồn ghi thẳng vào bj01Products (BJ-01 chỉ đọc giá trị mới); không làm đổi số tồn.
 * Lối ra dự phòng `data-v360-action="fallback-exit"` do khung (core.js) xử lý.
 */

const CAP_TITLE = "Chính sách tồn & cận hạn";
const CAP_NOTE = "Thay đổi chính sách không làm đổi số tồn.";
const CAP_ROW_ERROR = "Mục tiêu phải lớn hơn hoặc bằng ngưỡng.";
const CAP_DAYS_ERROR = "Số ngày cận hạn phải lớn hơn 0.";
const CAP_ACTIONS = [["WARN", "Cảnh báo", "Vẫn bán, hiện cảnh báo trên lô."], ["BLOCK_SALE", "Chặn bán", "Không bán lô cận hạn."]];

// ---- Trạng thái
let capMode = "table";            // "table" (bảng nhiều sản phẩm) | "single" (một sản phẩm, vào từ BJ-01)
let capProductId = null;          // sản phẩm của chế độ "single"
let capFilter = "ALL";            // "ALL" | "UNSET"
let capDraft = {};                // { [productId]: { threshold, target } } — chữ như đang gõ
let capSingle = { threshold: "", target: "" };   // nháp của chế độ "single" và của sheet sửa trên iPhone
let capSheetProductId = null;     // iPhone: sheet sửa hai ô của một sản phẩm
let capSaveOpen = false;          // web: sheet tác động trước khi lưu bảng
let capAddOpen = false;           // 063: sheet chọn sản phẩm có chính sách riêng
let capPolicyRevision = 5;
let capExpiry = { days: "90", action: "WARN", overrides: [{ productId: "INV-TYLO", days: "60", action: "BLOCK_SALE" }] };
let capExpiryDraft = capCloneExpiry(capExpiry);
let capReturnFlow = null;         // null = vào từ Hub / lối vào chung
let capReturnScreen = null;

function capCloneExpiry(e) { return { days: e.days, action: e.action, overrides: e.overrides.map((o) => ({ ...o })) }; }
const capCanEdit = () => currentActor() !== "staff";
const capStr = (v) => (v == null ? "" : String(v));
const capProduct = (id) => bj01Products.find((p) => p.id === id) || bj01Products[0];

// ---- Ngưỡng tồn: nháp, kiểm tra, chỉ báo
function capShown(p) { return capDraft[p.id] || { threshold: capStr(p.threshold), target: capStr(p.target) }; }
function capIsConfigured(p) { return p.monitoringConfigStatus !== "NOT_CONFIGURED"; }
// mục tiêu ≥ ngưỡng ≥ 0; chưa có ngưỡng thì để trống được, đã có ngưỡng thì không xoá về trống.
function capRowError(v, configured) {
  if (v.threshold === "" && v.target === "") return configured ? CAP_ROW_ERROR : "";
  const t = Number(v.threshold), g = Number(v.target);
  return v.threshold === "" || v.target === "" || !(t >= 0) || !(g >= t) ? CAP_ROW_ERROR : "";
}
// Một sản phẩm / sheet: hai ô trống = chưa nhập, chưa lưu được (khác bảng: dòng trống ở bảng không phải "đã sửa").
const capSingleEmpty = (v) => v.threshold === "" && v.target === "";
const capSingleBlocked = (p, v) => Boolean(capRowError(v, capIsConfigured(p))) || capSingleEmpty(v);
function capIsDirty(p) { const d = capDraft[p.id]; return Boolean(d) && (d.threshold !== capStr(p.threshold) || d.target !== capStr(p.target)); }
const capDirtyProducts = () => bj01Products.filter(capIsDirty);
const capHasError = () => capDirtyProducts().some((p) => capRowError(capShown(p), capIsConfigured(p)));
// Sản phẩm sau khi áp giá trị đang gõ (chỉ khi hợp lệ) — để tính chỉ báo trước khi lưu.
function capApplied(p, v) {
  if (capRowError(v, capIsConfigured(p)) || (v.threshold === "" && v.target === "")) return p;
  return { ...p, threshold: Number(v.threshold), target: Number(v.target), monitoringConfigStatus: "CONFIGURED" };
}
const CAP_BADGE_ORDER = ["OUT", "EXPIRED", "LOW", "NEAR", "NOT_CONFIGURED"];
function capIndicatorBadge(p) {
  const inds = bj01Indicators(p);
  const key = CAP_BADGE_ORDER.find((k) => inds.some((i) => i.key === k));
  if (!key) return ds24Badge("Bình thường", "Success");
  const label = inds.find((i) => i.key === key).label;
  return BJ01_STOCK_TONE[key] ? ds24DotBadge(label, BJ01_STOCK_TONE[key]) : ds24Badge(label, "Neutral");
}
function capPreviewLabel(p, v) {
  const inds = bj01Indicators(capApplied(p, v));
  const key = ["OUT", "EXPIRED", "LOW", "NEAR"].find((k) => inds.some((i) => i.key === k));
  return key ? inds.find((i) => i.key === key).label : "Không có cảnh báo";
}
const capLowCount = (list) => list.filter((p) => bj01Indicators(p).some((i) => i.key === "LOW")).length;
const capUnsetCount = () => bj01Products.filter((p) => !capIsConfigured(p)).length;

function capApplyValues(p, v) { p.threshold = Number(v.threshold); p.target = Number(v.target); p.monitoringConfigStatus = "CONFIGURED"; }
function capToastSaved() { capPolicyRevision += 1; showToast(`Đã lưu chính sách · Lần ${capPolicyRevision}`); }

// ---- Điều hướng
function capOpenForTable(returnFlow = null, returnScreen = null) {
  capMode = "table"; capProductId = null; capDraft = {}; capSaveOpen = false; capSheetProductId = null; capFilter = "ALL";
  capReturnFlow = returnFlow; capReturnScreen = returnScreen;
  activeFlowId = "CAP-01"; activeScreenId = "SCR-062"; stateByScreen["SCR-062"] = "READY";
  syncReviewUrl(); render();
}
// Lối vào từ BJ-01 SCR-003: một sản phẩm; lưu xong về lại SCR-003.
function capOpenForProduct(id) {
  const p = capProduct(id);
  capMode = "single"; capProductId = p.id; capSingle = { threshold: capStr(p.threshold), target: capStr(p.target) };
  capSaveOpen = false; capSheetProductId = null;
  capReturnFlow = "UIF-01"; capReturnScreen = "SCR-003";
  activeFlowId = "CAP-01"; activeScreenId = "SCR-062"; stateByScreen["SCR-062"] = "READY";
  syncReviewUrl(); render();
}
function capExit() {
  const flow = capReturnFlow || "UIF-01", screen = capReturnScreen || "SCR-001";
  capReturnFlow = null; capReturnScreen = null; capMode = "table"; capProductId = null;
  activeFlowId = flow; activeScreenId = screen;
  if (stateByScreen[activeScreenId] == null) {
    const s = screens.find((x) => x.id === activeScreenId);
    stateByScreen[activeScreenId] = s?.defaultState || s?.states?.[0] || "READY";
  }
  syncReviewUrl(); render();
}
// Nút quay lại: có nơi gọi (BJ-01 / BJ-12) thì về đó; vào từ Hub thì về Hub Kho; chế độ BJ thì về Tồn kho.
function capBack() {
  if (capReturnFlow) return capExit();
  if (typeof ThemeApp !== "undefined" && ThemeApp.inTheme()) { activeScreenId = "SCR-062"; return previousScreen(); }
  return capExit();
}
// Dựng lại giữ ô đang gõ: sau render đặt con trỏ về cuối ô cùng thuộc tính data-cap-*.
function capRender() {
  const a = document.activeElement;
  let key = null;
  if (a && a.matches && a.matches("input[data-cap-input]")) {
    for (const at of a.attributes) if (at.name.startsWith("data-cap-") && at.name !== "data-cap-input") { key = `input[${at.name}="${CSS.escape(at.value)}"]`; break; }
  }
  renderAppScreen();
  if (!key) return;
  const n = [...document.querySelectorAll(key)].find((e) => e.offsetParent !== null) || document.querySelector(key);
  if (n) { n.focus(); const v = n.value; n.value = ""; n.value = v; }
}

// ---- Thành phần dùng chung 062 / 063
function capShell({ title = CAP_TITLE, subtitle = null, body, actions = "", centered = false, back = true }) {
  return appShell({ title, subtitle, body, actions, centered, back, backAction: back ? "cap-back" : "", extraClass: "k7-wide" });
}
function capTabs() {
  return dsSegmented({ items: [["SCR-062", "Ngưỡng tồn"], ["SCR-063", "Cận hạn"]], value: activeScreenId, attr: "data-cap-tab", label: "Loại chính sách" });
}
// Banner theo trạng thái / vai; trả { notice, readOnly }.
function capNotice(state, hasInlineError = false) {
  const staff = !capCanEdit();
  if (staff) return { notice: k1Locked({ title: "Chỉ chủ cửa hàng thay đổi được chính sách.", description: "Bạn có thể xem các mức hiện tại." }), readOnly: true };
  if (state === "LOCKED") return { notice: k1Locked({ title: "Đang ở chế độ chỉ xem", description: "Chính sách đang được cập nhật ở nơi khác. Bạn có thể xem nhưng chưa thể lưu." }), readOnly: true };
  if (state === "CONFLICT") return { notice: k1Stale({ title: "Chính sách vừa được cập nhật", description: "Tải lại giá trị hiện hành trước khi lưu thay đổi.", actionLabel: "Tải lại", actionAttr: "data-cap-reload" }), readOnly: true };
  if (state === "VALIDATION_ERROR" && !hasInlineError) return { notice: vBanner("error", "Chưa thể tiếp tục", "Kiểm tra lại các giá trị được nhập trước khi lưu."), readOnly: false };
  return { notice: "", readOnly: false };
}
function capDenied(screenId) {
  return capShell({ body: k1Denied({ what: "xem hoặc thay đổi chính sách tồn", next: "Liên hệ chủ cửa hàng nếu cần.", exitAttr: k1ExitAttr(screenId) }), centered: true, back: false });
}
function capField(label, inner, hint = "") {
  return `<div class="cap-field"><label>${esc(label)}</label>${inner}${hint ? `<small class="cap-note">${esc(hint)}</small>` : ""}</div>`;
}
// Sheet theo khuôn bottom-sheet của BJ-12 (web: hộp thoại giữa màn). backdrop đóng khi bấm ra ngoài; Huỷ dùng data-cap-sheet-close.
function capSheet({ title, body, actions }) {
  return `<div class="sheet-backdrop" data-cap-sheet-backdrop><section class="bottom-sheet cap-sheet" role="dialog" aria-modal="true" aria-label="${escapeAttribute(title)}" onclick="event.stopPropagation()" data-ds-component="VBottomSheet" data-figma-node="4695:6353"><div class="sheet-handle"></div><div class="sheet-title"><h3>${esc(title)}</h3></div><div class="sheet-divider"></div><div class="sheet-content">${body}${actions ? `<div class="sheet-actions">${actions}</div>` : ""}</div></section></div>`;
}
const capCloseBtn = (label = "Huỷ") => cfSecondary(label, "data-cap-sheet-close");
const capPrimaryBtn = (label, attr, disabled = false) => `<button class="button button--primary" type="button" ${attr} data-ds-component="VButton"${disabled ? " disabled" : ""}>${esc(label)}</button>`;

// ---- SCR-062 — bảng nhiều sản phẩm
function capTableRow(p) {
  const v = capShown(p), err = capRowError(v, capIsConfigured(p)), dirty = capIsDirty(p), ro = !capCanEdit() || ["LOCKED", "CONFLICT"].includes(stateByScreen["SCR-062"]);
  const after = capApplied(p, v);
  return {
    id: p.id, uom: p.stockUom, available: String(p.available),
    product: `<strong>${dirty ? '<span class="cap-dirty-dot" role="img" aria-label="Đã sửa"></span>' : ""}${esc(p.name)}</strong><small>${esc(p.code)}</small>`,
    threshold: k7EditCell({ value: v.threshold, attr: `data-cap-input data-cap-threshold="${escapeAttribute(p.id)}"`, unit: p.stockUom, label: `Ngưỡng cảnh báo — ${p.name}`, disabled: ro }),
    target: k7EditCell({ value: v.target, attr: `data-cap-input data-cap-target="${escapeAttribute(p.id)}"`, unit: p.stockUom, error: err, label: `Mức tồn mục tiêu — ${p.name}`, disabled: ro }),
    badge: capIndicatorBadge(after),
  };
}
function capMobileRow(r) {
  const p = capProduct(r.id);
  const sub = capIsConfigured(p) ? `Ngưỡng ${p.threshold} · Mục tiêu ${p.target} ${p.stockUom}` : "Chưa có ngưỡng";
  // Chỉ xem (nhân viên / khoá / dữ liệu cũ): dòng trạng thái, không mũi tên, không mở sheet.
  const ro = !capCanEdit() || ["LOCKED", "CONFLICT"].includes(stateByScreen["SCR-062"]);
  return ds24ListRow({ title: p.name, subtitle: sub, trailing: capIndicatorBadge(p), leading: null, attrs: ro ? "" : `data-cap-edit-row="${escapeAttribute(p.id)}"`, type: ro ? "Status" : "Navigation" });
}
function capImpactSheet() {
  if (!capSaveOpen) return "";
  const list = capDirtyProducts();
  const items = list.map((p) => {
    const v = capShown(p), old = capIsConfigured(p) ? `${p.threshold} / ${p.target}` : "chưa có";
    return `<li><strong>${esc(p.name)}</strong>: ${esc(old)} → ${esc(v.threshold)} / ${esc(v.target)} ${esc(p.stockUom)}</li>`;
  }).join("");
  const before = capLowCount(bj01Products), after = capLowCount(bj01Products.map((p) => (capIsDirty(p) ? capApplied(p, capShown(p)) : p)));
  const body = `<ul class="cap-sheet-list">${items}</ul><p class="cap-preview">Tồn thấp: ${before} → ${after} sản phẩm</p><p class="cap-note">${CAP_NOTE}</p>`;
  return capSheet({ title: `Lưu ${list.length} thay đổi?`, body, actions: `${capCloseBtn()}${capPrimaryBtn("Lưu chính sách", "data-cap-save")}` });
}
// Hai ô của một sản phẩm: dùng ở chế độ "single" và ở sheet sửa trên iPhone.
function capSingleFields(p, readOnly) {
  const v = capSingle, err = capRowError(v, capIsConfigured(p));
  const cell = (label, attr, value, error = "") => capField(label, k7EditCell({ value, attr: `data-cap-input ${attr}`, unit: p.stockUom, error, label: `${label} — ${p.name}`, disabled: readOnly }));
  const preview = err || capSingleEmpty(v) ? "" : `<p class="cap-preview" data-cap-preview>Sau khi lưu: ${esc(capPreviewLabel(p, v))}</p>`;
  return `<p class="cap-preview">Khả dụng ${esc(p.available)} ${esc(p.stockUom)}</p>${cell("Ngưỡng cảnh báo", 'data-cap-s-threshold=""', v.threshold)}${cell("Mức tồn mục tiêu", 'data-cap-s-target=""', v.target, err)}${preview}`;
}
function capSheetEdit() {
  if (!capSheetProductId) return "";
  const p = capProduct(capSheetProductId);
  return capSheet({ title: p.name, body: capSingleFields(p, false), actions: `${capCloseBtn()}${capPrimaryBtn("Lưu", "data-cap-save-single", capSingleBlocked(p, capSingle))}` });
}

function render062CAP01(state) {
  if (state === "PERMISSION_DENIED") return capDenied("SCR-062");
  if (capMode === "single") {
    const p = capProduct(capProductId), err = capRowError(capSingle, capIsConfigured(p));
    const { notice, readOnly } = capNotice(state, Boolean(err));
    const body = `<div class="cap-narrow">${notice}${capSingleFields(p, readOnly)}<p class="cap-note">${CAP_NOTE}</p></div>`;
    const actions = readOnly ? "" : primaryFooter("Lưu", "data-cap-save-single", capSingleBlocked(p, capSingle));
    return capShell({ title: esc(p.name), subtitle: "Ngưỡng tồn", body, actions });
  }
  const dirty = capDirtyProducts(), hasErr = capHasError();
  const { notice, readOnly } = capNotice(state, hasErr);
  const unset = capUnsetCount();
  const products = bj01Products.filter((p) => capFilter === "ALL" || !capIsConfigured(p));
  const rows = products.map(capTableRow);
  const columns = [
    { key: "product", label: "Sản phẩm", html: true },
    { key: "uom", label: "ĐVT" },
    { key: "available", label: "Khả dụng", align: "end", mono: true },
    { key: "threshold", label: "Ngưỡng cảnh báo", align: "end", html: true },
    { key: "target", label: "Mức tồn mục tiêu", align: "end", html: true },
    { key: "badge", label: "Chỉ báo", html: true },
  ];
  const table = k7Table({ columns, rows, mobileRow: capMobileRow, caption: "Ngưỡng tồn theo sản phẩm", empty: { title: "Không còn sản phẩm nào chưa có ngưỡng", description: "Mọi sản phẩm đã có ngưỡng cảnh báo.", actionLabel: "Xem tất cả", actionAttr: 'data-cap-filter="ALL"' } });
  const chips = k7FilterChips({ items: [["ALL", "Tất cả", bj01Products.length], ["UNSET", "Chưa có ngưỡng", unset]], selected: capFilter, attrName: "data-cap-filter" });
  const body = `${notice}${capTabs()}${chips}${table}<p class="cap-note">${CAP_NOTE}</p>${capImpactSheet()}${capSheetEdit()}`;
  const actions = readOnly ? "" : k4Footer([
    { label: "Huỷ thay đổi", attr: "data-cap-discard", disabled: dirty.length === 0 },
    { label: `Lưu thay đổi (${dirty.length})`, attr: "data-cap-open-save", primary: true, disabled: dirty.length === 0 || hasErr },
  ]).replace('class="app-actions', 'class="app-actions k7-web-only');
  return capShell({ body, actions });
}

// ---- SCR-063 — cận hạn
function capOverrideRow(o, ro) {
  const p = capProduct(o.productId), err = Number(o.days) > 0 ? "" : CAP_DAYS_ERROR;
  const days = k7EditCell({ value: o.days, attr: `data-cap-input data-cap-ovr-days="${escapeAttribute(o.productId)}"`, unit: "ngày", error: err, label: `Số ngày cận hạn — ${p.name}`, disabled: ro });
  const select = `<select class="cap-select" data-cap-ovr-action="${escapeAttribute(o.productId)}" aria-label="Hành động — ${escapeAttribute(p.name)}"${ro ? " disabled" : ""}>${CAP_ACTIONS.map(([k, l]) => `<option value="${k}"${o.action === k ? " selected" : ""}>${esc(l)}</option>`).join("")}</select>`;
  const remove = ro ? "" : `<button type="button" class="cap-link-button" data-cap-override-remove="${escapeAttribute(o.productId)}">Dùng mặc định</button>`;
  return { id: o.productId, product: `<strong>${esc(p.name)}</strong><small>${esc(p.code)}</small>`, days, select, remove, p };
}
function capOverrideMobile(r) {
  return `<div class="cap-row-card"><div class="cap-row-card__head"><span><strong>${esc(r.p.name)}</strong><small>${esc(r.p.code)}</small></span>${r.remove}</div>${r.days}${r.select}</div>`;
}
function capAddSheet() {
  if (!capAddOpen) return "";
  const taken = new Set(capExpiryDraft.overrides.map((o) => o.productId));
  const options = bj01Products.filter((p) => p.tracking === "LOT" && !taken.has(p.id));
  const body = options.length
    ? `<div class="ds24-list-stack">${options.map((p) => ds24ListRow({ title: p.name, subtitle: p.code, leading: null, attrs: `data-cap-override-pick="${escapeAttribute(p.id)}"`, type: "Navigation" })).join("")}</div>`
    : `<p class="cap-note">Mọi sản phẩm theo lô đều đã có chính sách riêng.</p>`;
  return capSheet({ title: "Thêm sản phẩm", body, actions: capCloseBtn("Đóng") });
}
function render063CAP01(state) {
  if (state === "PERMISSION_DENIED") return capDenied("SCR-063");
  const d = capExpiryDraft, daysErr = Number(d.days) > 0 ? "" : CAP_DAYS_ERROR;
  const hasErr = Boolean(daysErr) || d.overrides.some((o) => !(Number(o.days) > 0));
  const { notice, readOnly: ro } = capNotice(state, hasErr);
  const rowsView = d.overrides.map((o) => capOverrideRow(o, ro));
  const choice = `<div class="ds-choice-list" role="radiogroup" aria-label="Hành động">${CAP_ACTIONS.map(([k, l, sub]) => dsChoiceRow({ title: l, subtitle: sub, selected: d.action === k, attrs: `data-cap-expiry-action="${k}"`, disabled: ro })).join("")}</div>`;
  const defaults = `<div class="cap-narrow cap-narrow--start">${ac310SectionTitle("Mặc định cho mọi sản phẩm")}${capField("Số ngày cận hạn", k7EditCell({ value: d.days, attr: "data-cap-input data-cap-expiry-days", unit: "ngày", error: daysErr, label: "Số ngày cận hạn", disabled: ro }), "Tính từ ngày hiện tại đến hạn dùng.")}${capField("Hành động", choice)}</div>`;
  const columns = [
    { key: "product", label: "Sản phẩm", html: true },
    { key: "days", label: "Số ngày", align: "end", html: true },
    { key: "select", label: "Hành động", html: true },
    { key: "remove", label: "", align: "end", html: true },
  ];
  const list = rowsView.length
    ? k7Table({ columns, rows: rowsView, mobileRow: capOverrideMobile, caption: "Sản phẩm có chính sách riêng" })
    : `<p class="cap-note">Chưa có sản phẩm nào có chính sách riêng.</p>`;
  const add = ro ? "" : cfSecondary("Thêm sản phẩm", "data-cap-override-add");
  const body = `${notice}${capTabs()}${defaults}${ac310SectionTitle("Sản phẩm có chính sách riêng")}${list}${add}<p class="cap-note">${CAP_NOTE}</p>${capAddSheet()}`;
  const actions = ro ? "" : primaryFooter("Lưu thay đổi", "data-cap-save-expiry", hasErr);
  return capShell({ body, actions });
}

// ---- SCR-065 — chỉ còn khi chưa rõ / bị từ chối (lưu thành công = toast ở màn)
function render065CAP01(state) {
  if (state === "PERMISSION_DENIED") return capDenied("SCR-065");
  if (state === "UNKNOWN") return k3Unknown({ operation: "Cập nhật chính sách tồn", scope: "Kho trung tâm", ref: "CAP-260827-01", sentAt: "09:42 · 27/08/2026", safe: "Không lưu lại thay đổi.", sourceFlow: "CAP-01", exitAttr: k1ExitAttr("SCR-062") });
  if (state === "REJECTED_EXECUTION") return k4Result({ screenTitle: CAP_TITLE, kind: "warning", title: "Chưa cập nhật chính sách", description: "Không có chính sách mới được áp dụng.", facts: [["Tác động sổ kho", "Không"], ["Trạng thái", "Giữ chính sách hiện hành"]], next: [{ label: "Về Kho", attr: k1ExitAttr("SCR-062") }, { label: "Quay lại chính sách", attr: 'data-cap-tab="SCR-062"', primary: true }] });
  // COMPLETED (đường cũ): không còn màn kết quả — về 062 và báo bằng toast.
  activeScreenId = "SCR-062"; stateByScreen["SCR-062"] = stateByScreen["SCR-062"] || "READY"; syncReviewUrl();
  queueMicrotask(() => showToast(`Đã lưu chính sách · Lần ${capPolicyRevision}`));
  return render062CAP01(stateByScreen["SCR-062"]);
}

Object.assign(renderers, {
  "SCR-062": render062CAP01,
  "SCR-063": render063CAP01,
  "SCR-065": render065CAP01,
});

// SCR-064 Rà soát đã thành sheet tác động trong SCR-062; link cũ vẫn mở.
screenAliases["CAP-01"] = Object.assign(screenAliases["CAP-01"] || {}, { "SCR-064": "SCR-062" });
{ const a = screenAliases[activeFlowId]?.[activeScreenId]; if (Array.isArray(a)) { activeFlowId = a[0]; activeScreenId = a[1]; } else if (a) activeScreenId = a; }

// ---- Sự kiện
// Vào CAP-01 từ Hub / lối vào chung: về bảng, bỏ nháp cũ. Đăng ký trước hub.js để chạy trước lúc Hub dựng màn.
window.addEventListener("click", (event) => {
  if (event.target.closest?.('[data-theme-entry-flow="CAP-01"]')) {
    capMode = "table"; capProductId = null; capDraft = {}; capSaveOpen = false; capSheetProductId = null; capAddOpen = false; capFilter = "ALL";
    capReturnFlow = null; capReturnScreen = null; capExpiryDraft = capCloneExpiry(capExpiry);
  }
}, true);

document.addEventListener("input", (event) => {
  if (activeFlowId !== "CAP-01" || !event.target.matches?.("[data-cap-input]")) return;
  const t = event.target, value = t.value;
  const ds = t.dataset;
  if (ds.capThreshold != null || ds.capTarget != null) {
    const id = ds.capThreshold ?? ds.capTarget, p = capProduct(id);
    capDraft[id] = { ...capShown(p), [ds.capThreshold != null ? "threshold" : "target"]: value };
    if (!capIsDirty(p)) delete capDraft[id];
    if (["READY", "VALIDATION_ERROR"].includes(stateByScreen["SCR-062"])) stateByScreen["SCR-062"] = capHasError() ? "VALIDATION_ERROR" : "READY";
    return capRender();
  }
  if (ds.capSThreshold != null || ds.capSTarget != null) { capSingle[ds.capSThreshold != null ? "threshold" : "target"] = value; return capRender(); }
  if (ds.capExpiryDays != null) { capExpiryDraft.days = value; return capRender(); }
  if (ds.capOvrDays != null) { const o = capExpiryDraft.overrides.find((x) => x.productId === ds.capOvrDays); if (o) o.days = value; return capRender(); }
}, true);

document.addEventListener("change", (event) => {
  if (activeFlowId !== "CAP-01") return;
  const sel = event.target.closest?.("[data-cap-ovr-action]");
  if (sel) { const o = capExpiryDraft.overrides.find((x) => x.productId === sel.dataset.capOvrAction); if (o) o.action = sel.value; return renderAppScreen(); }
}, true);

// Esc đóng sheet đang mở (như BJ-12).
document.addEventListener("keydown", (event) => {
  if (activeFlowId !== "CAP-01" || event.key !== "Escape" || !(capSaveOpen || capSheetProductId || capAddOpen)) return;
  event.preventDefault(); capSaveOpen = false; capSheetProductId = null; capAddOpen = false; renderAppScreen();
}, true);

document.addEventListener("click", (event) => {
  if (activeFlowId !== "CAP-01") return;
  const t = event.target;
  const hit = (sel) => t.closest(sel);
  const stop = () => { event.preventDefault(); event.stopPropagation(); };
  const btn = (sel) => { const el = hit(sel); return el && !el.disabled ? el : null; };

  if (hit('[data-action="cap-back"]')) { stop(); return capBack(); }
  const tab = hit("[data-cap-tab]");
  if (tab) { stop(); capSaveOpen = false; capSheetProductId = null; capAddOpen = false; capMode = "table"; stateByScreen[tab.dataset.capTab] = stateByScreen[tab.dataset.capTab] === "PERMISSION_DENIED" ? "READY" : stateByScreen[tab.dataset.capTab]; return navigate(tab.dataset.capTab); }
  const filter = hit("[data-cap-filter]");
  if (filter) { stop(); capFilter = filter.dataset.capFilter; return renderAppScreen(); }
  if (hit("[data-cap-reload]")) { stop(); capDraft = {}; capExpiryDraft = capCloneExpiry(capExpiry); stateByScreen[activeScreenId] = "READY"; syncReviewUrl(); return renderAppScreen(); }

  // 062 bảng (web)
  if (btn("[data-cap-discard]")) { stop(); capDraft = {}; if (stateByScreen["SCR-062"] === "VALIDATION_ERROR") stateByScreen["SCR-062"] = "READY"; return renderAppScreen(); }
  if (btn("[data-cap-open-save]")) { stop(); capSaveOpen = true; return renderAppScreen(); }
  if (t.matches("[data-cap-sheet-backdrop]") || hit("[data-cap-sheet-close]")) { stop(); capSaveOpen = false; capSheetProductId = null; capAddOpen = false; return renderAppScreen(); }
  if (btn("[data-cap-save]")) {
    stop();
    for (const p of capDirtyProducts()) capApplyValues(p, capShown(p));
    capDraft = {}; capSaveOpen = false; stateByScreen["SCR-062"] = "READY";
    renderAppScreen(); return capToastSaved();
  }
  // 062 iPhone: chạm dòng → sheet sửa hai ô, lưu thẳng
  const row = hit("[data-cap-edit-row]");
  if (row) {
    stop();
    if (!capCanEdit() || ["LOCKED", "CONFLICT"].includes(stateByScreen["SCR-062"])) return;
    const p = capProduct(row.dataset.capEditRow);
    capSheetProductId = p.id; capSingle = { threshold: capStr(p.threshold), target: capStr(p.target) };
    return renderAppScreen();
  }
  // 062 một sản phẩm (trang riêng hoặc sheet trên iPhone)
  if (btn("[data-cap-save-single]")) {
    stop();
    const p = capProduct(capMode === "single" ? capProductId : capSheetProductId);
    if (capSingleBlocked(p, capSingle)) return;
    capApplyValues(p, capSingle);
    capSheetProductId = null;
    if (capMode === "single") { capExit(); return capToastSaved(); }
    renderAppScreen(); return capToastSaved();
  }

  // 063
  const act = hit("[data-cap-expiry-action]");
  if (act && !act.disabled) { stop(); capExpiryDraft.action = act.dataset.capExpiryAction; return renderAppScreen(); }
  const rm = hit("[data-cap-override-remove]");
  if (rm) { stop(); capExpiryDraft.overrides = capExpiryDraft.overrides.filter((o) => o.productId !== rm.dataset.capOverrideRemove); return renderAppScreen(); }
  if (btn("[data-cap-override-add]")) { stop(); capAddOpen = true; return renderAppScreen(); }
  const pick = hit("[data-cap-override-pick]");
  if (pick) { stop(); capExpiryDraft.overrides.push({ productId: pick.dataset.capOverridePick, days: capExpiryDraft.days, action: capExpiryDraft.action }); capAddOpen = false; return renderAppScreen(); }
  if (btn("[data-cap-save-expiry]")) {
    stop();
    if (Number(capExpiryDraft.days) > 0 && capExpiryDraft.overrides.every((o) => Number(o.days) > 0)) {
      capExpiry = capCloneExpiry(capExpiryDraft);
      renderAppScreen(); return capToastSaved();
    }
  }
}, true);

Object.assign(window.__VET45_QA__, {
  capState: () => ({ capMode, capProductId, capFilter, capDraft, capSingle, capExpiry, capExpiryDraft, capPolicyRevision, capReturnFlow, capReturnScreen }),
  setCapReturn(flow = null, screen = null) { capReturnFlow = flow; capReturnScreen = screen; },
  capExit, capOpenForProduct, capOpenForTable,
});
