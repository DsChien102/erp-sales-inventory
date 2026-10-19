/* CAP-01 — Chính sách tồn & cận hạn (CAP-01). Màn: SCR-062, SCR-063, SCR-064, SCR-065.
 *
 * Đã viết lại sạch (T7-P gói A3, 2026-10-17): mọi trạng thái, helper, hàm dựng và xử lý sự kiện của CAP-01
 * nằm ở đây; Sửa CAP-01: sửa thẳng file này.
 * Dùng chung từ app/core.js: appShell, ds24InfoRow, ds24Result, vBanner, deniedBody, primaryFooter, esc,
 * escapeAttribute, navigate, render, renderAppScreen, syncReviewUrl, screens, stateByScreen.
 * Helper cục bộ: cap01InfoGroup (gộp v440), cap01KeyValueRow (gộp marker v470), cap01Num.
 * Lối ra dự phòng `data-v360-action="fallback-exit"` do khung (core.js) xử lý.
 * Lối vào / lối ra là fallback prototype (BG-006 chưa chốt) — không phải hợp đồng điều hướng production.
 */

const cap01Num = (v) => Number(v ?? 0);

/** Info group đã gộp class v440 (trước do bước sửa sau dựng). */
function cap01InfoGroup(title, rows, extraClass = "") {
  return `<section class="ds24-info-group ${extraClass}" data-composed-from="DS v2 / Info Row">${title ? `<h2 class="ds24-info-group__title">${esc(title)}</h2>` : ""}<div class="ds24-info-group__rows v440-grouped-surface" data-layout-pattern="Grouped surface" data-v440-grouped-surface="auto">${rows}</div></section>`;
}
/** Key-value row đã gộp marker v470. */
function cap01KeyValueRow(label, value, emphasis = false) {
  return `<div class="ds24-key-value-row${emphasis ? " ds24-key-value-row--emphasis" : ""}" data-ds-component="DS v2 / Key-value Row" data-figma-node="525:358" data-ds-prop-state="${emphasis ? "Emphasis" : "Default"}" data-v470="1"><span>${esc(label)}</span><strong>${esc(value)}</strong></div>`;
}

let capPolicyKind = "STOCK";
let capThreshold = "50";
let capTarget = "80";
let capStockSource = "PRODUCT_OVERRIDE";
let capNearExpiryDays = "90";
let capNearExpiryAction = "WARN";
let capNearExpirySource = "TENANT_DEFAULT";
let capPolicyRevision = 5;
let capLastResult = null;
let capReturnFlow = "UIF-01";
let capReturnScreen = "SCR-001";

function capNumberField(label, value, attr, hint = "", disabled = false) {
  return `<div class="form-field" data-ds-component="VNumberField" data-ds-prop-label="${escapeAttribute(label)}"><label>${esc(label)}</label><div class="input-shell"><input inputmode="numeric" type="number" min="0" value="${escapeAttribute(value)}" ${attr} ${disabled ? "disabled" : ""}></div>${hint ? `<small class="helper-text">${esc(hint)}</small>` : ""}</div>`;
}
function capSelect(label, value, attr, options, disabled = false) {
  return `<label class="form-field v360-select-field" data-ds-component="VSelect"><span>${esc(label)}</span><div class="select-shell"><select ${attr} ${disabled ? "disabled" : ""}>${options.map(([v, l]) => `<option value="${escapeAttribute(v)}" ${v === value ? "selected" : ""}>${esc(l)}</option>`).join("")}</select></div></label>`;
}
function capExit() {
  activeFlowId = capReturnFlow;
  activeScreenId = capReturnScreen;
  if (stateByScreen[activeScreenId] == null) {
    const s = screens.find((x) => x.id === activeScreenId);
    stateByScreen[activeScreenId] = s?.defaultState || s?.states?.[0] || "READY";
  }
  syncReviewUrl();
  render();
}
function capFormNotice(state) {
  if (state === "VALIDATION_ERROR") return vBanner("error", "Chưa thể tiếp tục", "Kiểm tra lại các giá trị được nhập trước khi rà soát.");
  if (state === "CONFLICT") return vBanner("warning", "Chính sách vừa được cập nhật", "Tải lại giá trị hiện hành trước khi lưu thay đổi.");
  if (state === "LOCKED") return vBanner("warning", "Đang ở chế độ chỉ xem", "Chính sách đang được cập nhật ở nơi khác. Bạn có thể xem nhưng chưa thể lưu.");
  return "";
}

function render062CAP01(state) {
  if (state === "PERMISSION_DENIED") return appShell({ title: "Chính sách tồn", body: deniedBody(), centered: true, backAction: "v360-cap-exit" });
  const locked = state === "LOCKED";
  const invalid = cap01Num(capThreshold) < 0 || cap01Num(capTarget) < cap01Num(capThreshold);
  const body = `${capFormNotice(state)}${cap01InfoGroup("Phạm vi", `${ds24InfoRow("Áp dụng", "Tồn kho và cảnh báo tồn thấp")}${ds24InfoRow("Tác động sổ kho", "Không")}`, "v360-policy-context")}
      <section class="v360-form-section" data-composed-from="VNumberField,VSelect">
        ${capNumberField("Ngưỡng cảnh báo", capThreshold, "data-v360-cap-threshold", "Cảnh báo khi tồn khả dụng xuống dưới mức này.", locked)}
        ${capNumberField("Mức tồn mục tiêu", capTarget, "data-v360-cap-target", "Phải lớn hơn hoặc bằng ngưỡng cảnh báo.", locked)}
        ${capSelect("Nguồn áp dụng", capStockSource, "data-v360-cap-stock-source", [["PRODUCT_OVERRIDE", "Ghi đè theo sản phẩm"], ["TENANT_DEFAULT", "Mặc định tổ chức"]], locked)}
      </section>`;
  const actions = locked
    ? primaryFooter("Đóng", 'data-v360-action="cap-exit"')
    : `<footer class="app-actions figma-sticky-footer"><button class="button button--primary" type="button" data-v360-action="cap-review-stock" data-ds-component="VButton" ${invalid ? "disabled" : ""}>Rà soát thay đổi</button></footer>`;
  return appShell({ title: "Chính sách tồn", body, actions, backAction: "v360-cap-exit" });
}

function render063CAP01(state) {
  if (state === "PERMISSION_DENIED") return appShell({ title: "Hàng cận hạn", body: deniedBody(), centered: true, backAction: "v360-cap-exit" });
  const locked = state === "LOCKED";
  const invalid = cap01Num(capNearExpiryDays) <= 0;
  const body = `${capFormNotice(state)}${cap01InfoGroup("Phạm vi", `${ds24InfoRow("Áp dụng", "Cảnh báo hàng cận hạn")}${ds24InfoRow("Tác động sổ kho", "Không")}`, "v360-policy-context")}
      <section class="v360-form-section" data-composed-from="VNumberField,VSelect">
        ${capNumberField("Số ngày cận hạn", capNearExpiryDays, "data-v360-cap-expiry-days", "Tính từ ngày hiện tại đến hạn dùng.", locked)}
        ${capSelect("Hành động", capNearExpiryAction, "data-v360-cap-expiry-action", [["WARN", "Cảnh báo"], ["BLOCK_SALE", "Chặn bán"]], locked)}
        ${capSelect("Nguồn áp dụng", capNearExpirySource, "data-v360-cap-expiry-source", [["TENANT_DEFAULT", "Mặc định tổ chức"], ["PRODUCT_OVERRIDE", "Ghi đè theo sản phẩm"]], locked)}
      </section>`;
  const actions = locked
    ? primaryFooter("Đóng", 'data-v360-action="cap-exit"')
    : `<footer class="app-actions figma-sticky-footer"><button class="button button--primary" type="button" data-v360-action="cap-review-expiry" data-ds-component="VButton" ${invalid ? "disabled" : ""}>Rà soát thay đổi</button></footer>`;
  return appShell({ title: "Hàng cận hạn", body, actions, backAction: "v360-cap-exit" });
}

function render064CAP01(state) {
  if (state === "PERMISSION_DENIED") return appShell({ title: "Rà soát chính sách", body: deniedBody(), centered: true, backAction: "v360-cap-edit" });
  if (state === "VALIDATION_ERROR") return appShell({ title: "Rà soát chính sách", body: vBanner("error", "Chính sách chưa hợp lệ", "Quay lại cấu hình và kiểm tra các giá trị."), actions: primaryFooter("Quay lại chỉnh sửa", 'data-v360-action="cap-edit"'), backAction: "v360-cap-edit" });
  const sourceLabel = (capPolicyKind === "STOCK" ? capStockSource : capNearExpirySource) === "PRODUCT_OVERRIDE" ? "Ghi đè theo sản phẩm" : "Mặc định tổ chức";
  const policyRows = capPolicyKind === "STOCK"
    ? `${cap01KeyValueRow("Ngưỡng cảnh báo", capThreshold, true)}${cap01KeyValueRow("Mức tồn mục tiêu", capTarget, true)}${ds24InfoRow("Nguồn áp dụng", sourceLabel)}`
    : `${cap01KeyValueRow("Cận hạn", `${capNearExpiryDays} ngày`, true)}${ds24InfoRow("Hành động", capNearExpiryAction === "WARN" ? "Cảnh báo" : "Chặn bán")}${ds24InfoRow("Nguồn áp dụng", sourceLabel)}`;
  const pending = state === "APPROVAL_REQUIRED";
  const body = `${pending ? vBanner("warning", "Cần người có quyền xác nhận", "Bạn không thể tự lưu thay đổi chính sách này.") : ""}${cap01InfoGroup(capPolicyKind === "STOCK" ? "Chính sách tồn" : "Chính sách cận hạn", policyRows, "v360-policy-review")}${cap01InfoGroup("Tác động", `${ds24InfoRow("Sổ kho", "Không thay đổi")}${ds24InfoRow("Chỉ báo và khả dụng", "Được tính lại theo chính sách mới")}`, "v360-policy-impact")}`;
  const actions = pending
    ? primaryFooter("Về cấu hình", 'data-v360-action="cap-edit"')
    : `<footer class="app-actions figma-sticky-footer v360-dual-actions v361-dual-footer" data-ds-prop-layout="Dual" data-ds-prop-tone="Default"><button class="button button--secondary" type="button" data-v360-action="cap-edit" data-ds-component="VButton">Chỉnh sửa</button><button class="button button--primary" type="button" data-v360-action="cap-save" data-ds-component="VButton">Lưu chính sách</button></footer>`;
  return appShell({ title: "Rà soát chính sách", body, actions, backAction: "v360-cap-edit" });
}

function render065CAP01(state) {
  if (state === "PERMISSION_DENIED") return appShell({ title: "Kết quả cập nhật", body: deniedBody(), centered: true, back: false, actions: primaryFooter("Đóng", 'data-v360-action="cap-exit"') });
  if (state === "UNKNOWN") return appShell({ title: "Kết quả cập nhật", body: ds24Result("Đang xác minh kết quả", "Không lưu lại thay đổi. Hệ thống đang xác minh đúng lần cập nhật này.", [["Chính sách", capPolicyKind === "STOCK" ? "Tồn kho" : "Cận hạn"], ["Tác động sổ kho", "Chưa kết luận"]], "warning"), centered: true, back: false, actions: primaryFooter("Đóng", 'data-v360-action="cap-exit"') });
  if (state === "REJECTED_EXECUTION") return appShell({ title: "Kết quả cập nhật", body: ds24Result("Chưa cập nhật chính sách", "Không có chính sách mới được áp dụng.", [["Tác động sổ kho", "Không"], ["Trạng thái", "Giữ chính sách hiện hành"]], "warning"), centered: true, back: false, actions: primaryFooter("Về cấu hình", 'data-v360-action="cap-edit"') });
  const r = capLastResult || { revision: capPolicyRevision + 1, kind: capPolicyKind, lowStock: 12 };
  return appShell({ title: "Kết quả cập nhật", body: ds24Result("Đã cập nhật chính sách", "Chỉ báo liên quan sẽ dùng chính sách mới; không tạo biến động tồn kho.", [["Chính sách", r.kind === "STOCK" ? "Tồn kho" : "Cận hạn"], ["Lần cập nhật", `Lần ${r.revision}`], ["Tác động sổ kho", "Không"], ["Chỉ báo tồn thấp", `${r.lowStock} sản phẩm`]]), centered: true, back: false, actions: primaryFooter("Đóng", 'data-v360-action="cap-exit"') });
}

Object.assign(renderers, {
  "SCR-062": render062CAP01,
  "SCR-063": render063CAP01,
  "SCR-064": render064CAP01,
  "SCR-065": render065CAP01,
});

document.addEventListener("input", (event) => {
  if (activeFlowId !== "CAP-01") return;
  if (event.target.matches("[data-v360-cap-threshold]")) { capThreshold = event.target.value; return; }
  if (event.target.matches("[data-v360-cap-target]")) { capTarget = event.target.value; return; }
  if (event.target.matches("[data-v360-cap-expiry-days]")) { capNearExpiryDays = event.target.value; return; }
}, true);

document.addEventListener("change", (event) => {
  if (activeFlowId !== "CAP-01") return;
  if (event.target.matches("[data-v360-cap-stock-source]")) { capStockSource = event.target.value; return; }
  if (event.target.matches("[data-v360-cap-expiry-action]")) { capNearExpiryAction = event.target.value; return; }
  if (event.target.matches("[data-v360-cap-expiry-source]")) { capNearExpirySource = event.target.value; return; }
}, true);

document.addEventListener("click", (event) => {
  const back = event.target.closest('[data-action="v360-cap-exit"]');
  if (back) { event.preventDefault(); event.stopPropagation(); return capExit(); }
  const edit = event.target.closest('[data-action="v360-cap-edit"]');
  if (edit && activeFlowId === "CAP-01") { event.preventDefault(); event.stopPropagation(); return navigate(capPolicyKind === "STOCK" ? "SCR-062" : "SCR-063"); }
  const action = event.target.closest("[data-v360-action]");
  if (!action || action.disabled) return;
  const k = action.dataset.v360Action;
  if (k === "cap-exit") { event.preventDefault(); event.stopPropagation(); return capExit(); }
  if (activeFlowId !== "CAP-01" || !["cap-review-stock", "cap-review-expiry", "cap-edit", "cap-save"].includes(k)) return;
  event.preventDefault();
  event.stopPropagation();
  if (k === "cap-review-stock") {
    if (cap01Num(capThreshold) < 0 || cap01Num(capTarget) < cap01Num(capThreshold)) { stateByScreen["SCR-062"] = "VALIDATION_ERROR"; return renderAppScreen(); }
    capPolicyKind = "STOCK"; stateByScreen["SCR-064"] = "READY"; return navigate("SCR-064");
  }
  if (k === "cap-review-expiry") {
    if (cap01Num(capNearExpiryDays) <= 0) { stateByScreen["SCR-063"] = "VALIDATION_ERROR"; return renderAppScreen(); }
    capPolicyKind = "EXPIRY"; stateByScreen["SCR-064"] = "READY"; return navigate("SCR-064");
  }
  if (k === "cap-edit") { return navigate(capPolicyKind === "STOCK" ? "SCR-062" : "SCR-063"); }
  if (k === "cap-save") {
    capPolicyRevision += 1; capLastResult = { revision: capPolicyRevision, kind: capPolicyKind, lowStock: 12 }; stateByScreen["SCR-065"] = "COMPLETED"; return navigate("SCR-065");
  }
}, true);

Object.assign(window.__VET45_QA__, {
  capState: () => ({ capPolicyKind, capThreshold, capTarget, capStockSource, capNearExpiryDays, capNearExpiryAction, capNearExpirySource, capPolicyRevision, capLastResult }),
  setCapReturn(flow = "UIF-01", screen = "SCR-001") { capReturnFlow = flow; capReturnScreen = screen; },
  capExit,
});
