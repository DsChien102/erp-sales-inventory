/* VET45 Theme 7 prototype — khung runtime (T7-P A11–A12, BJ-12, v5.5.0).
 *
 * Chỉ còn khung sản phẩm:
 *   - Trạng thái + routing lối vào (`entryTargets` / `applyEntry` / `onEntry` / `currentActor`)
 *   - `renderers` / `flowRenderers` / `flowScreen` / `renderAppScreen` / `render` / `navigate` / `previousScreen`
 *   - Helper DS (`appShell`, `ds24*`, `vBanner`, `primaryFooter`, `icon`, `io*` / `ic*` còn dùng…)
 *   - Toast, lối ra dự phòng, bước dựng chung `applyGroupedSurfaceRule`
 *   - API QA `window.__VET45_QA__` (BJ chỉ `Object.assign`)
 *
 * Harness (sidebar / inspector / Inspect / device frame) → `harness/workbench.js` + `harness/workbench.css` + `harness/figma-ds-map.js`.
 * Mỗi BJ → `app/bjNN.js` / `cap01.js`; Hub → `app/hub.js`. Không còn lớp vá `vNNN` / bọc `render`/`navigate`.
 */
const HARNESS = window.VET45_HARNESS_DATA || { flows: [], screens: [], runOrder: [] };
const FIGMA_DS_MAP = window.VET45_FIGMA_DS_MAP || { componentMappings:{}, profileMappings:{}, themeComponentMappings:{}, internalMappings:{} };
// Fixture review (tiền tệ, tỷ giá, thuế, chính sách giá vốn) — đầu vào runtime, không phải quyết định nghiệp vụ.
window.__VET45_MONEY_CURRENCY_CATALOG__ = window.__VET45_MONEY_CURRENCY_CATALOG__ || [{id:"VND",label:"VND"},{id:"USD",label:"USD"}];
window.__VET45_FX_SOURCE_FIXTURE__ = window.__VET45_FX_SOURCE_FIXTURE__ || {VND:{rate:1,version:"LOCAL-VND"},USD:{rate:24450,version:"FX-DEMO-USD-202609"}};
window.__VET45_TAX_TREATMENT_POLICY__ = window.__VET45_TAX_TREATMENT_POLICY__ || {version:"TAX-HKD-DEMO-v1",recoverableRate:0};
window.__VET45_TENANT_COST_POLICY__ = window.__VET45_TENANT_COST_POLICY__ || {version:"COST-POLICY-DEMO-v1",method:"PERIODIC",label:"Bình quân cuối kỳ",periodCloseScopes:[{id:"ALL_PRODUCTS",label:"Toàn bộ sản phẩm"},{id:"DIRTY_PRODUCTS_ONLY",label:"Sản phẩm cần tính lại"}],fixture:true};
// Figma DS v2.0.3 is UI authority; business authority remains in BJ/UC/decision/contracts.
const FIGMA_MIGRATED_FLOWS = new Set([
  "UIF-01","UIF-02","UIF-03","UIF-04","UIF-05","UIF-06","UIF-07","UIF-08","UIF-09",
  "UIF-10","UIF-11","UIF-12","UIF-13","UIF-14","UIF-15","UIF-16","UIF-17","CAP-01"
]);
const FIGMA_TEMPLATE_NODES = {
  "Mobile / Root List":"551:549", "Mobile / Nested List":"551:1277", "Mobile / Detail":"551:1396",
  "Mobile / Form":"551:1452", "Mobile / Wizard":"551:1530", "Mobile / Search & Select":"551:1621", "Mobile / State":"551:1746"
};
const FIGMA_TEMPLATE_BY_FLOW_SCREEN = {
  "UIF-01":{"SCR-001":"Mobile / Root List","SCR-003":"Mobile / Detail"},
  "UIF-02":{"SCR-007":"Mobile / Nested List","SCR-008":"Mobile / Form","SCR-009":"Mobile / Nested List","SCR-084":"Mobile / Form","SCR-010":"Mobile / Detail","SCR-011":"Mobile / Detail","SCR-012":"Mobile / Detail","SCR-013":"Mobile / Detail"},
  "UIF-03":{"SCR-014":"Mobile / Root List","SCR-015":"Mobile / Form","SCR-017":"Mobile / Detail","SCR-019":"Mobile / Detail"},
  "UIF-04":{"SCR-021":"Mobile / Detail"},
  "UIF-05":{"SCR-025":"Mobile / Root List","SCR-026":"Mobile / Detail","SCR-028":"Mobile / Detail","SCR-029":"Mobile / Detail"},
  "UIF-06":{"SCR-030":"Mobile / Root List","SCR-031":"Mobile / Detail","SCR-032":"Mobile / Form","SCR-034":"Mobile / Detail","SCR-033":"Mobile / Form","SCR-035":"Mobile / Detail"},
  "UIF-07":{"SCR-036":"Mobile / Root List","SCR-037":"Mobile / Detail","SCR-039":"Mobile / Detail","SCR-041":"Mobile / Detail"},
  "UIF-08":{"SCR-042":"Mobile / Nested List","SCR-043":"Mobile / Form","SCR-044":"Mobile / Form","SCR-045":"Mobile / Form","SCR-046":"Mobile / Detail","SCR-047":"Mobile / Detail"},
  "UIF-09":{"SCR-036":"Mobile / Root List","SCR-037":"Mobile / Detail","SCR-038":"Mobile / Form","SCR-041":"Mobile / Detail","SCR-056":"Mobile / Detail"},
  "UIF-10":{"SCR-036":"Mobile / Root List","SCR-037":"Mobile / Detail","SCR-040":"Mobile / Form","SCR-041":"Mobile / Detail"},
  "UIF-11":{"SCR-048":"Mobile / Root List","SCR-049":"Mobile / Detail","SCR-050":"Mobile / Form","SCR-053":"Mobile / Detail","SCR-051":"Mobile / Detail"},
  "UIF-12":{"SCR-066":"Mobile / Detail","SCR-067":"Mobile / Form","SCR-068":"Mobile / Detail","SCR-069":"Mobile / Detail","SCR-070":"Mobile / Detail","SCR-071":"Mobile / Detail"},
  "UIF-13":{"SCR-085":"Mobile / Root List","SCR-086":"Mobile / Form","SCR-087":"Mobile / Form","SCR-088":"Mobile / Detail","SCR-089":"Mobile / Detail"},
  "UIF-14":{"SCR-072":"Mobile / Root List","SCR-074":"Mobile / Detail","SCR-077":"Mobile / Detail"},
  "UIF-15":{"SCR-055":"Mobile / Root List","SCR-056":"Mobile / Detail","SCR-059":"Mobile / Detail"},
  "UIF-16":{"SCR-078":"Mobile / Root List","SCR-079":"Mobile / Detail","SCR-081":"Mobile / Detail","SCR-082":"Mobile / Detail","SCR-083":"Mobile / Detail"},
  "UIF-17":{"SCR-078":"Mobile / Root List","SCR-079":"Mobile / Detail","SCR-083":"Mobile / Detail"},
  "CAP-01":{"SCR-062":"Mobile / Form","SCR-063":"Mobile / Form","SCR-065":"Mobile / Detail"}
};
function figmaScreenTemplate(){ return FIGMA_TEMPLATE_BY_FLOW_SCREEN[activeFlowId]?.[activeScreenId] || null; }
const screens = HARNESS.screens;
const flowCatalog = HARNESS.flows;
let activeFlowId = new URLSearchParams(window.location.search).get("uif") || "UIF-02";
if (!flowCatalog.some((f) => f.id === activeFlowId)) activeFlowId = "UIF-02";
const groups = ["Screens"];

const stateByScreen = Object.fromEntries(screens.map((screen) => [screen.id, screen.defaultState]));

const initialParams = new URLSearchParams(window.location.search);
const initialFlow = flowCatalog.find((f) => f.id === activeFlowId);
const entryMode = initialParams.get("entry") || "module";
// Giữ màn retired (vd. SCR-018/088) dù không còn trong flow.screens — bj*.js screenAliases đổi trước hub render().
const requestedScreen = initialParams.get("screen");
let activeScreenId = (() => {
  if (!requestedScreen) return initialFlow?.screens[0] || "SCR-007";
  if (initialFlow?.screens.includes(requestedScreen)) return requestedScreen;
  if (screens.some((s) => s.id === requestedScreen)) return requestedScreen;
  return initialFlow?.screens[0] || "SCR-007";
})();
let viewport = initialParams.get("viewport") === "web" ? "web" : "mobile";
let flowMode = initialParams.get("flow") === "quick" ? "quick" : "document";

// Entry architecture: one table (screen + optional state/flowMode). v350 targets win where both existed.
const entryTargets = {
  "UIF-01": { "product-context": { screen: "SCR-003" } },
  "UIF-02": {
    "document-context": { screen: "SCR-009", flowMode: "document" },
    "approver": { screen: "SCR-011" },
    "owner": { screen: "SCR-007" },
  },
  "UIF-03": { "receipt-task": { screen: "SCR-015" }, "staff": { screen: "SCR-014" } },
  "UIF-04": { "order-context": { screen: "SCR-021" } },
  "UIF-05": { "order-task": { screen: "SCR-026" } },
  "UIF-06": { "return-task": { screen: "SCR-031" }, "approver": { screen: "SCR-034" } },
  "UIF-07": { "return-task": { screen: "SCR-037" } },
  "UIF-08": {
    "assigned-counter": { screen: "SCR-044", state: "BLIND_COUNT" },
    "approver": { screen: "SCR-046", state: "APPROVAL_REVIEW" },
  },
  "UIF-09": {
    "product-context": { screen: "SCR-037", state: "READY" },
    "approver": { screen: "SCR-038", state: "APPROVAL_REVIEW" },
    "request-view": { screen: "SCR-038", state: "PENDING_APPROVAL" },
  },
  "UIF-10": {
    "product-context": { screen: "SCR-037", state: "READY" },
    "request": { screen: "SCR-040", state: "READY" },
    "approver": { screen: "SCR-040", state: "APPROVAL_REVIEW" },
    "completion-operator": { screen: "SCR-040", state: "APPROVED_PENDING_DISPOSAL" },
    "request-view": { screen: "SCR-040" },
  },
  "UIF-11": {
    "approver": { screen: "SCR-051", state: "READY" },
    "operation-context": { screen: "SCR-049", state: "CORRECTABLE" },
    "correction-from-case": { screen: "SCR-050", state: "READY" },
    "correction-from-movement": { screen: "SCR-050", state: "READY" },
  },
  "UIF-12": { "approver": { screen: "SCR-070", state: "READY" }, "owner": { screen: "SCR-066", state: "READY" } },
  "UIF-13": { "source-task": { screen: "SCR-086" }, "staff": { screen: "SCR-085" } },
  "UIF-14": { "dirty-scope": { screen: "SCR-074" } },
  "UIF-15": { "stock-card": { screen: "SCR-055", state: "READY" }, "report": { screen: "SCR-055", state: "READY" } },
  "UIF-16": { "case-context": { screen: "SCR-079" } },
  "UIF-17": { "unknown-context": { screen: "SCR-079" } },
  "CAP-01": { "staff": { screen: "SCR-062", state: "READY" } },
};
const onEntry = {};
let actorMode = entryMode;
function currentActor() { return actorMode; }
function applyEntry(flowId, mode, shouldRender = false) {
  const target = entryTargets[flowId]?.[mode];
  if (!target) return false;
  activeFlowId = flowId;
  activeScreenId = target.screen;
  if (target.flowMode) flowMode = target.flowMode;
  if (target.state !== undefined && stateByScreen[activeScreenId] !== undefined) {
    stateByScreen[activeScreenId] = target.state;
  }
  onEntry[`${flowId}:${mode}`]?.();
  if (shouldRender) { syncReviewUrl(); render(); }
  return true;
}
let entryApplied = null;
if (!requestedScreen) {
  if (applyEntry(activeFlowId, entryMode, false)) entryApplied = entryTargets[activeFlowId]?.[entryMode] || null;
}
const initialState = initialParams.get("state");
if (initialState && !(entryApplied && entryApplied.state) && screens.find((s) => s.id === activeScreenId)?.states.includes(initialState)) {
  stateByScreen[activeScreenId] = initialState;
}
let toastTimer = null;

// QA surface — BJ files only Object.assign into this object (never reassign).
window.__VET45_QA__ = {
  setActor(mode) { actorMode = String(mode || "module"); return actorMode; },
  getActor() { return actorMode; },
  applyEntry(flowId, mode) {
    actorMode = String(mode || "module");
    const applied = applyEntry(String(flowId || activeFlowId), actorMode, true);
    return { applied, flow: activeFlowId, screen: activeScreenId, state: stateByScreen[activeScreenId], actor: actorMode };
  },
  getState() { return { flow: activeFlowId, screen: activeScreenId, state: stateByScreen[activeScreenId] }; },
};


// ============================================================================
const icons = {
  arrowLeft: '<path d="m15 18-6-6 6-6"/><path d="M9 12h10"/>',
  chevronLeft: '<path d="m15 18-6-6 6-6"/>',
  close: '<path d="m18 6-12 12"/><path d="m6 6 12 12"/>',
  arrowRight: '<path d="M5 12h14"/><path d="m13 6 6 6-6 6"/>',
  chevronRight: '<path d="m9 18 6-6-6-6"/>',
  chevronDown: '<path d="m6 9 6 6 6-6"/>',
  fileText: '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6"/><path d="M8 13h8"/><path d="M8 17h6"/>',
  cloudUpload: '<path d="M12 13v8"/><path d="m16 16-4-4-4 4"/><path d="M4.393 15.269A5 5 0 0 1 6.5 5.5a7 7 0 0 1 13.33 3.4A4.5 4.5 0 0 1 18.5 17H17"/>',
  zap: '<path d="M13 2 3 14h9l-1 8 10-12h-9z"/>',
  info: '<circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/>',
  alert: '<path d="M10.3 2.9 1.8 17a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 2.9a2 2 0 0 0-3.4 0z"/><path d="M12 9v4"/><path d="M12 17h.01"/>',
  search: '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>',
  filter: '<path d="M4 5h16"/><path d="M7 12h10"/><path d="M10 19h4"/>',
  warehouse: '<path d="M3 21V8l9-5 9 5v13"/><path d="M7 21v-8h10v8"/><path d="M7 17h10"/>',
  calendar: '<rect width="18" height="18" x="3" y="4" rx="2"/><path d="M16 2v4"/><path d="M8 2v4"/><path d="M3 10h18"/>',
  save: '<path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><path d="M17 21v-8H7v8"/><path d="M7 3v5h8"/>',
  package: '<path d="m7.5 4.27 9 5.15"/><path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z"/><path d="m3.3 7 8.7 5 8.7-5"/><path d="M12 22V12"/>',
  layers: '<path d="m12.83 2.18 8 4a2 2 0 0 1 0 3.58l-8 4a2 2 0 0 1-1.66 0l-8-4a2 2 0 0 1 0-3.58l8-4a2 2 0 0 1 1.66 0Z"/><path d="m22 12.5-9.17 4.59a2 2 0 0 1-1.66 0L2 12.5"/><path d="m22 17.5-9.17 4.59a2 2 0 0 1-1.66 0L2 17.5"/>',
  check: '<path d="M20 6 9 17l-5-5"/>',
  checkCircle: '<circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/>',
  xCircle: '<circle cx="12" cy="12" r="10"/><path d="M12 8v4"/><path d="M12 16h.01"/>',
  shield: '<path d="M20 13c0 5-3.5 7.5-8 9-4.5-1.5-8-4-8-9V5l8-3 8 3z"/><path d="m9 12 2 2 4-4"/>',
  user: '<path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>',
  clock: '<circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/>',
  history: '<path d="M3 12a9 9 0 1 0 3-6.7"/><path d="M3 3v6h6"/><path d="M12 7v5l3 2"/>',
  edit: '<path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L8 18l-4 1 1-4Z"/>',
  rotate: '<path d="M3 12a9 9 0 0 1 15-6.7L21 8"/><path d="M21 3v5h-5"/><path d="M21 12a9 9 0 0 1-15 6.7L3 16"/><path d="M8 16H3v5"/>',
  lock: '<rect width="18" height="11" x="3" y="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>',
  inbox: '<path d="M4 4h16v16H4z"/><path d="M4 14h4l2 3h4l2-3h4"/>',
  listCheck: '<path d="m3 17 2 2 4-4"/><path d="m3 7 2 2 4-4"/><path d="M13 6h8"/><path d="M13 12h8"/><path d="M13 18h8"/>',
  more: '<circle cx="12" cy="12" r="1"/><circle cx="19" cy="12" r="1"/><circle cx="5" cy="12" r="1"/>',
  scan: '<path d="M3 7V5a2 2 0 0 1 2-2h2"/><path d="M17 3h2a2 2 0 0 1 2 2v2"/><path d="M21 17v2a2 2 0 0 1-2 2h-2"/><path d="M7 21H5a2 2 0 0 1-2-2v-2"/><path d="M8 7v10"/><path d="M12 7v10"/><path d="M16 7v10"/>',
};

const dsIconMap = {
  arrowLeft: "VIcons.arrowLeft", arrowRight: "VIcons.arrowRight", chevronLeft: "VIcons.chevronLeft", chevronRight: "VIcons.chevronRight", chevronDown: "VIcons.arrowDropDown",
  fileText: "VIcons.description", cloudUpload: "li:cloud-upload", zap: "VIcons.bolt", info: "VIcons.info", alert: "VIcons.warning", search: "VIcons.search",
  filter: "VIcons.tune", warehouse: "VIcons.warehouse", calendar: "VIcons.calendar", save: "VIcons.save", package: "VIcons.inventory",
  layers: "VIcons.inventory", check: "VIcons.check", checkCircle: "VIcons.success", xCircle: "VIcons.error", close: "VIcons.close",
  shield: "VIcons.shield", user: "VIcons.person", clock: "VIcons.clock", rotate: "VIcons.refresh", lock: "VIcons.lock", inbox: "VIcons.inbox",
  listCheck: "VIcons.checkList", more: "VIcons.moreHoriz", history: "VIcons.history", edit: "VIcons.edit", scan: "VIcons.barcodeScanner"
};
function icon(name, className = "") {
  const semantic = dsIconMap[name] || "VIcons.info";
  return `<svg class="icon ${className}" data-ds-component="VIcon" data-ds-icon="${semantic}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${icons[name] || icons.info}</svg>`;
}
function navChevron() {
  return icon("chevronRight", "icon--sm nav-action-chevron");
}


function currentScreen() {
  return screens.find((screen) => screen.id === activeScreenId);
}

function activeFlow() { return flowCatalog.find((f) => f.id === activeFlowId) || flowCatalog[0]; }
function flowScreens() { const f=activeFlow(); return (f?.screens || []).map((id)=>screens.find((s)=>s.id===id)).filter(Boolean); }
function statusBar() {
  if (FIGMA_MIGRATED_FLOWS.has(activeFlowId)) {
    return `<div class="app-statusbar" data-figma-slot="Status Bar"><span>9:41</span><span>LTE&nbsp;&nbsp;100%</span></div>`;
  }
  return `
    <div class="app-statusbar">
      <span>09:45</span>
      <span class="app-status-icons">
        <span class="signal-bars"><i></i><i></i><i></i><i></i></span>
        <span>5G</span>
        <span class="battery"></span>
      </span>
    </div>`;
}


function appShell({ title, subtitle = null, body, actions = "", centered = false, back = true, backAction = "", extraClass = "" }) {
  const hasSubtitle = Boolean(subtitle);
  const baseFigmaTemplate = FIGMA_MIGRATED_FLOWS.has(activeFlowId) ? figmaScreenTemplate() : null;
  // Mobile / State is reserved for actual full-content empty/error/permission/blocked/no-result surfaces.
  // Result screens keep their business-detail archetype instead of mechanically becoming State pages.
  const isFullContentState = centered && /data-ds-component=["']VEmptyState["']/.test(String(body || ""));
  const figmaTemplate = isFullContentState ? "Mobile / State" : baseFigmaTemplate;
  const shellAttrs = `data-ds-component="VPageScaffold" data-ds-profile="screen.shell.standard" data-ds-prop-title="${escapeAttribute(title)}" data-ds-prop-subtitle="${subtitle == null ? 'null' : escapeAttribute(subtitle)}" data-ds-prop-show-back-button="${back}" data-ds-prop-center-title="false" data-ds-prop-actions="null"${figmaTemplate ? ` data-figma-template="${figmaTemplate}" data-figma-template-node="${FIGMA_TEMPLATE_NODES[figmaTemplate]}" data-figma-migrated="true"` : ''}`;
  return `
    <div class="v-page-scaffold ${figmaTemplate ? 'figma-calibrated-shell' : ''} ${extraClass}" data-mobile-product data-product-app data-inspectable="true" ${shellAttrs}>
      ${statusBar()}
      <header class="app-header">
        <div class="app-appbar ${back ? 'has-back' : 'no-back'} ${hasSubtitle ? 'has-subtitle' : ''}" data-ds-component="VAppBar" data-ds-prop-center-title="false" data-ds-prop-actions="null" data-ds-prop-show-back-button="${back}">
          ${back ? `<button class="app-icon-button app-back-button" ${backAction ? `data-action="${backAction}"` : "data-back"} type="button" aria-label="Quay lại" data-ds-internal="VAppBar.leading">${icon("chevronLeft", "icon--24")}</button>` : ``}
          <div class="app-appbar-copy" data-ds-component="VAppBarTitle"><h3>${title}</h3>${hasSubtitle ? `<span data-ds-component="VAppBarSubtitle">${subtitle}</span>` : ""}</div>
        </div>
      </header>
      <div class="app-content ${centered ? "app-content--centered" : ""}" data-ds-component="VPagePadding" data-ds-profile="screen.body.standard" data-ds-prop-horizontal="null" data-ds-prop-vertical="null" data-ds-prop-apply-bottom-safe-area="false"><div class="body-stack">${body}</div></div>
      ${actions}
    </div>`;
}

function vBanner(status, title, description, extraClass = "", density = "Default") {
  const tone = status === "error" ? "Danger" : status === "success" ? "Success" : status === "warning" ? "Warning" : "Info";
  const iconName = status === "error" ? "xCircle" : status === "success" ? "checkCircle" : status === "warning" ? "alert" : "info";
  const semanticIcon = status === "error" ? "VIcons.error" : status === "success" ? "VIcons.success" : status === "warning" ? "VIcons.warning" : "VIcons.info";
  return `<div class="v-banner v-banner--${status} ${extraClass}" data-ds-component="VBanner" data-figma-node="526:4215" data-ds-prop-tone="${tone}" data-ds-prop-density="${density}" data-ds-default-icon="${semanticIcon}">
    <span class="v-banner-icon" data-ds-internal="VBanner.icon">${icon(iconName)}</span>
    <div class="v-banner-copy" data-ds-internal="VBanner.copy"><strong>${title}</strong>${description ? `<span>${description}</span>` : ""}</div>
  </div>`;
}

function vBadge(label, status = "info", extraClass = "") {
  return `<span class="status-badge status-badge--${status} ${extraClass}" data-ds-component="VBadge" data-ds-prop-status="VBadgeStatus.${status}">${label}</span>`;
}

function stateBanner(state) {
  const mapping = {
    CONFLICT: ["warning", "Dữ liệu vừa thay đổi", "Tải phiên bản hiện hành trước khi tiếp tục; hệ thống không ghi đè im lặng."],
    LOCKED: ["warning", "Kho đang được khóa", "Chỉ có thể xem dữ liệu. Mở công việc đang giữ khóa để biết thêm chi tiết."],
    VALIDATION_ERROR: ["error", "Cần kiểm tra dữ liệu", "Dữ liệu đã nhập được giữ lại. Sửa trường được đánh dấu trước khi tiếp tục."],
    VALIDATION_FAILED: ["error", "Kiểm tra dữ liệu chưa đạt", "Không có dữ liệu nào được ghi nhận; sửa lỗi theo từng dòng hàng."],
    LOT_CONFLICT: ["error", "Thông tin lô không khớp", "Mã lô ND2408 đã tồn tại với hạn dùng khác. Hãy đối chiếu nhãn nhà sản xuất."],
    SOURCE_VERSION_STALE: ["warning", "Chứng từ nguồn đã đổi", "Lượng còn được phép nhận vừa thay đổi. Mở phiên bản hiện hành để đối chiếu."],
    PARTIAL_RECEIPT: ["info", "Có chứng từ đã nhận một phần", "Số còn lại vẫn bám theo chứng từ nguồn và được kiểm tra lũy kế."],
    APPROVAL_REQUIRED: ["warning", "Cần phê duyệt", "Yêu cầu chưa tạo tác động tồn vật lý cho đến khi có quyết định hợp lệ."],
    PENDING_APPROVAL: ["info", "Đã gửi cho người duyệt", "Bạn có thể rời màn hình này. Tồn kho chưa thay đổi; yêu cầu sẽ tự cập nhật khi có quyết định."],
    SELF_APPROVAL_NOT_ALLOWED: ["error", "Không được tự phê duyệt", "Người lập không thể đồng thời là người quyết định yêu cầu này."],
    APPROVAL_ALREADY_DECIDED: ["info", "Yêu cầu đã có quyết định", "Quyết định hợp lệ đầu tiên có hiệu lực; các thao tác quyết định đã được khóa."],
    STALE: ["warning", "Dữ liệu có thể đã cũ", "Làm mới lịch sử trước khi dựa vào trạng thái hiện tại."],
    PROCESSING_OR_UNKNOWN: ["warning", "Kết quả chưa xác định", "Không cần tạo lần nhận mới. Hệ thống tiếp tục xác minh cùng lần nhận hiện tại."],
    TERMINAL: ["success", "Đã xác lập kết quả", "Kết quả đã rõ; hệ thống sẽ đưa bạn về màn kết quả."],
    READ_ONLY: ["info", "Chế độ chỉ xem", "Dữ liệu vẫn hiển thị nhưng mọi thao tác thay đổi đã bị khóa."],
  };
  if (!mapping[state]) return "";
  const [status, title, message] = mapping[state];
  return vBanner(status, title, message);
}

function loadingBody() {
  return `<div class="skeleton-stack" data-ds-component="VSkeleton"><div class="skeleton skeleton--heading"></div><div class="skeleton skeleton--text"></div><div class="skeleton skeleton--card"></div><div class="skeleton skeleton--card"></div><div class="skeleton skeleton--text"></div></div>`;
}

function deniedBody() {
  return `<div class="empty-state permission-denied-state" data-ds-component="VEmptyState" data-theme-component="PermissionDeniedState" data-composed-from="VEmptyState,VEmptyMedia,VText"><div class="icon-box icon-box--danger" data-ds-component="VEmptyMedia" data-ds-prop-tone="VComponentTone.danger">${icon("lock", "icon--empty-media")}</div><h3 data-ds-component="VEmptyTitle">Không có quyền truy cập</h3><p data-ds-component="VEmptyDescription">Dữ liệu nghiệp vụ không được tải vào màn hình này. Liên hệ quản trị viên nếu cần cấp quyền.</p></div>`;
}

function emptyBody(filtered = false) {
  return `<div class="empty-state" data-ds-component="VEmptyState"><div class="icon-box" data-ds-component="VEmptyMedia">${icon("inbox")}</div><h3 data-ds-component="VEmptyTitle">${filtered ? "Không có kết quả phù hợp" : "Không có chứng từ đang chờ nhận"}</h3><p data-ds-component="VEmptyDescription">${filtered ? "Xóa bớt điều kiện tìm kiếm để xem thêm kết quả." : "Quay lại để chọn cách nhận hàng khác nếu phù hợp."}</p></div>`;
}

function primaryFooter(label, actionAttr, disabled = false, tone = "primary") {
  const calibrated = FIGMA_MIGRATED_FLOWS.has(activeFlowId);
  return `<footer class="app-actions${calibrated ? ' figma-sticky-footer' : ''}" data-ds-component="${calibrated ? 'DS v2 / Sticky Footer' : 'VPagePadding'}" ${calibrated ? 'data-ds-prop-layout="Single" data-ds-prop-tone="Default" data-figma-node="549:927"' : 'data-ds-slot="VPageScaffold.bottomBar"'}><button class="button button--primary" ${actionAttr} data-ds-component="VButton" data-ds-profile="button.primaryFooter" data-ds-prop-variant="VButtonVariant.primary" data-ds-prop-size="VButtonSize.medium" data-ds-prop-full-width="true" data-ds-prop-tone="VComponentTone.${tone}" type="button" ${disabled ? "disabled" : ""}>${label}</button></footer>`;
}


function escapeAttribute(value) {
  return String(value).replaceAll("&", "&amp;").replaceAll('"', "&quot;").replaceAll("<", "&lt;").replaceAll(">", "&gt;");
}


function esc(v){return String(v??"").replace(/[&<>\"]/g,(m)=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;"}[m]));}
function dsIconForSurface(surface){return {list:"listCheck",form:"edit",detail:"fileText",review:"shield",result:"checkCircle",timeline:"history",dashboard:"layers",choice:"listCheck"}[surface]||"info";}
function genericFieldRows(screen){
  const rows=(screen.dataRows?.length?screen.dataRows:(screen.fields||[]).map((x)=>({label:x[0],example:x[1],ownership:"DERIVED"})));
  if(!rows.length) return "";
  if(screen.surface==="form") return `<section class="generic-form-section v-section" data-ds-component="VSection">${rows.map((r,i)=>{const comp=(r.component||(/(ngày|hạn|cut-off|kỳ)/i.test(r.label)?"VDatePicker":/(số tiền|giá trị|giá trước)/i.test(r.label)?"VMoneyField":/(số lượng|lượng |ngưỡng|mức tồn|số ngày)/i.test(r.label)?"VNumberField":/(trạng thái|loại|hành động|lý do|nguồn|phạm vi|định dạng|kho)/i.test(r.label)?"VSelect":"VTextFormField")); return `<label class="generic-field" data-ds-component="${comp}" data-ds-prop-label="${esc(r.label)}"><span>${esc(r.label)}</span><div class="generic-input">${esc(r.example||"Nhập dữ liệu")}</div></label>`}).join("")}</section>`;
  return `<div class="generic-kv-card" data-ds-component="VSection" data-composed-from="DS v2 / Info Row">${rows.map((r)=>`<div class="generic-kv-row" data-ds-component="DS v2 / Info Row" data-figma-node="525:351"><span data-ds-component="VText">${esc(r.label)}</span><strong data-ds-component="VText">${esc(r.example||"—")}</strong></div>`).join("")}</div>`;
}
function genericCards(screen){
  const cards=screen.cards||[]; if(!cards.length) return "";
  if(screen.surface==="timeline") return `<div class="generic-timeline" data-theme-component="Theme7EvidenceTimeline" data-composed-from="VCard,VIconBox,VText,VBadge">${cards.map((c,i)=>`<div class="timeline-event"><span class="timeline-dot" data-ds-component="VIconBox">${icon(i===cards.length-1?"checkCircle":"fileText","icon--sm")}</span><div class="timeline-copy"><strong data-ds-component="VText">${esc(c[0])}</strong><span data-ds-component="VText">${esc(c[1]||"")}</span>${c[2]?vBadge(esc(c[2]),i===cards.length-1?"success":"info"):""}</div></div>`).join("")}</div>`;
  return `<div class="generic-card-list">${cards.map((c)=>`<article class="generic-data-card" data-ds-component="${screen.surface==="list"?"DS v2 / List Row":"VSection"}" ${screen.surface==="list"?'data-figma-node="525:519" data-ds-prop-type="Navigation"':'data-composed-from="DS v2 / Info Row,VBadge"'}><div class="generic-card-icon" data-ds-component="VCardIcon">${icon(dsIconForSurface(screen.surface),"icon--sm")}</div><div class="generic-card-copy"><strong data-ds-component="VCardTitle">${esc(c[0])}</strong><span data-ds-component="VText">${esc(c[1]||"")}</span></div>${c[2]?vBadge(esc(c[2]),/lỗi|block|thiếu|unknown|hết/i.test(c[2])?"warning":"info"):""}${screen.surface==="list"?icon("chevronRight","icon--sm"):""}</article>`).join("")}</div>`;
}
function genericPrimaryActions(screen,state){
  if(state==="PERMISSION_DENIED") return "";
  const acts=screen.actions||[]; if(!acts.length){
    if(screen.surface==="result") return primaryFooter("Xong",'data-generic-next',false);
    return "";
  }
  const primary=acts[0]; return primaryFooter(esc(primary.label),'data-generic-action="'+esc(primary.id)+'"',false,primary.tone==="danger"?"danger":"primary");
}
function genericStateContent(screen,state){
  if(state==="PERMISSION_DENIED") return deniedBody();
  if(state==="LOADING"||state==="CALCULATING"||state==="REBUILDING"||state==="PREPARING"||state==="PROCESSING"){
    if(screen.surface==="result") return `<div class="generic-result-center" data-theme-component="Theme7OperationResult"><div class="generic-spinner" data-ds-component="VLoading"></div><h3 data-ds-component="VText">Đang xử lý</h3><p data-ds-component="VText">Giữ nguyên ngữ cảnh. Bạn không cần gửi lại thao tác.</p></div>`;
    return loadingBody();
  }
  if(state.includes("EMPTY")) return `<div class="empty-state" data-ds-component="VEmptyState"><div class="icon-box" data-ds-component="VEmptyMedia">${icon("inbox")}</div><h3 data-ds-component="VEmptyTitle">Chưa có dữ liệu</h3><p data-ds-component="VEmptyDescription">Không có mục phù hợp trong phạm vi hiện tại.</p></div>`;
  if(screen.surface==="result" && /(COMPLETED|PUBLISHED|RESOLVED|ACTIVE_RECONCILED)/.test(state)) return `<div class="generic-result-center" data-theme-component="Theme7OperationResult" data-ds-component="VSection" data-composed-from="VIcon,VText,DS v2 / Info Row,VBanner">${resultHero("Đã xác lập kết quả","Kết quả chính thức đã sẵn sàng.")}${genericFieldRows(screen)}${genericCards(screen)}</div>`;
  if(screen.surface==="result" && /(UNKNOWN|COMMIT_UNKNOWN)/.test(state)) return `<div class="generic-result-center" data-theme-component="Theme7OperationResult">${vBanner("warning","Kết quả chưa xác định","Hệ thống tiếp tục xác minh chính lần xử lý này; không tạo thao tác mới.")}${genericFieldRows(screen)}</div>`;
  let notice=screen.notice? vBanner("info","Lưu ý",esc(screen.notice)):"";
  let stateNote="";
  if(/ERROR|FAILED|CONFLICT|BLOCK|LOCKED|STALE|MISSING|EXPIRED/.test(state)) stateNote=stateBanner(state)||vBanner("warning","Cần kiểm tra",`Cần xử lý điều kiện hiện tại trước khi tiếp tục.`);
  if(/APPROVAL/.test(state)) stateNote=stateBanner(state)||vBanner("info","Đang chờ phê duyệt","Chưa có tác động cuối cho đến khi có quyết định hợp lệ.");
  const intro=`<section class="v-section generic-intro" data-ds-component="VSection"><span class="eyebrow">${esc(activeFlowId)} · ${esc(screen.surface)}</span><h2 data-ds-component="VText">${esc(screen.name)}</h2><p data-ds-component="VText">${esc(screen.purpose)}</p></section>`;
  return intro+stateNote+notice+genericCards(screen)+genericFieldRows(screen);
}
function renderGeneric(screen,state){
  let body=genericStateContent(screen,state);
  if(screen.id==="SCR-044") body=`${vBanner("info","Đếm mù đang bật","Số lượng sổ sách không được tải vào DOM trước khi bạn gửi lần đếm đầu tiên.")}${body}`;
  return appShell({title:screen.name,body,actions:genericPrimaryActions(screen,state),back:!activeFlow()?.entry.includes(screen.id),centered:state==="PERMISSION_DENIED"});
}

function ds24Badge(label,tone="Neutral") {
  const t=String(tone).toLowerCase();
  return `<span class="ds24-badge ds24-badge--${t}" data-ds-component="VBadge" data-figma-node="525:309" data-ds-prop-style="Soft" data-ds-prop-tone="${tone}">${esc(label)}</span>`;
}
// VBadge có chấm 8px: chấm đặc = cảnh báo, chấm rỗng = nguy hiểm (CSS .ds24-badge--dot), để màu không là tín hiệu duy nhất.
function ds24DotBadge(label,tone="Neutral") {
  const t=String(tone).toLowerCase();
  return `<span class="ds24-badge ds24-badge--${t} ds24-badge--dot" data-ds-component="VBadge" data-ds-prop-style="Soft" data-ds-prop-tone="${tone}">${esc(label)}</span>`;
}
function ds24Chip(key,label,selected,attrName,count=null) {
  const countHtml=count==null?"":` <span class="ds24-chip__count">${esc(count)}</span>`;
  return `<button class="ds24-chip${selected?' is-selected':''}${count===0?' is-empty':''}" type="button" aria-pressed="${selected?'true':'false'}" ${attrName}="${escapeAttribute(key)}" data-ds-component="VChip" data-figma-node="522:7449" data-ds-prop-state="Default" data-ds-prop-tone="${selected?'Brand':'Neutral'}">${esc(label)}${countHtml}</button>`;
}
// trailingAction: nút cuối ô tìm (vd. quét mã vạch), chuỗi HTML đã dựng sẵn.
function ds24Search(value,attrs,placeholder="Tìm kiếm",trailingAction="") {
  return `<div class="ds24-search-header" data-ds-component="DS v2 / Search & Filter Header" data-figma-node="547:2306" data-ds-prop-layout="Search"><label class="ds24-search" data-ds-component="VSearchBar" data-figma-node="522:7245" data-ds-prop-state="Default">${icon("search")}<input ${attrs} value="${escapeAttribute(value)}" placeholder="${escapeAttribute(placeholder)}" aria-label="${escapeAttribute(placeholder)}">${trailingAction}</label></div>`;
}
function ds24ListRow({title,subtitle="",trailing="",leading="package",attrs="",type="Navigation",theme="",state="Default",density="Default",interactive=null,disabled=false,extraClass=""}) {
  const isInteractive=interactive==null ? type!=="Status" : Boolean(interactive);
  const tag=isInteractive?"button":"div";
  const effectiveState=disabled||state==="Disabled"?"Disabled":state;
  const disabledAttrs=effectiveState==="Disabled" ? (isInteractive?' disabled aria-disabled="true"':' aria-disabled="true"') : "";
  const buttonType=isInteractive?' type="button"':'';
  const hasLeading=Boolean(leading);
  const leadingHtml=hasLeading?icon(leading,"ds24-list-row__leading"):"";
  return `<${tag} class="ds24-list-row${hasLeading?'':' ds24-list-row--no-leading'}${extraClass?` ${extraClass}`:''}"${buttonType} ${attrs}${disabledAttrs} data-ds-component="DS v2 / List Row" data-figma-node="525:519" data-ds-prop-type="${type}" data-ds-prop-state="${effectiveState}" data-ds-prop-density="${density}" data-ds-prop-leading="${hasLeading?'Visible':'Hidden'}" ${theme?`data-theme-component="${theme}"`:''}>${leadingHtml}<span class="ds24-list-row__copy"><strong>${esc(title)}</strong><small>${esc(subtitle)}</small></span><span class="ds24-list-row__trailing">${trailing}${type==="Navigation"?icon("chevronRight","icon--sm"):''}</span></${tag}>`;
}
// VStockRow: List Row không icon đầu, cột phải hai tầng (số lượng mono + badge tình trạng), chevron.
function ds24StockRow({title,subtitle="",quantity,badge="",attrs=""}) {
  return `<button class="ds24-list-row ds24-list-row--no-leading ds24-stock-row" type="button" ${attrs} data-ds-component="VStockRow" data-ds-prop-type="Navigation"><span class="ds24-list-row__copy"><strong>${esc(title)}</strong><small>${esc(subtitle)}</small></span><span class="ds24-stock-row__value"><strong class="ds24-stock-row__qty">${esc(quantity)}</strong>${badge}</span>${icon("chevronRight","icon--sm")}</button>`;
}
function ds24ContextStatusRow({title,subtitle="",label,tone="Neutral",leading="package",attrs=""}) {
  return ds24ListRow({title,subtitle,trailing:ds24Badge(label,tone),leading,attrs,type:"Status",density:"Compact",state:"Default",interactive:false});
}
function ds24InfoRow(label,value,extra="") {
  return `<div class="ds24-info-row ${extra}" data-ds-component="DS v2 / Info Row" data-figma-node="525:351"><span>${esc(label)}</span><strong>${esc(value)}</strong></div>`;
}
function ds24KeyValueRow(label,value,emphasis=false,valueAttrs="") {
  return `<div class="ds24-key-value-row${emphasis?' ds24-key-value-row--emphasis':''}" data-ds-component="DS v2 / Key-value Row" data-figma-node="525:358" data-ds-prop-state="${emphasis?'Emphasis':'Default'}"><span>${esc(label)}</span><strong ${valueAttrs}>${esc(value)}</strong></div>`;
}
function ds24InfoGroup(title,rows,extraClass="") {
  return `<section class="ds24-info-group ${extraClass}" data-composed-from="DS v2 / Info Row">${title?`<h2 class="ds24-info-group__title">${esc(title)}</h2>`:""}<div class="ds24-info-group__rows">${rows}</div></section>`;
}
function ds24GroupedCollection(content,extraClass="",composedFrom="") {
  const from=composedFrom||"DS v2 / List Row";
  return `<section class="ds24-grouped-collection ${extraClass}" data-layout-pattern="Grouped surface" data-figma-reference="4518:1545" data-composed-from="${escapeAttribute(from)}">${content}</section>`;
}
function ds24SummaryCard(title,body,extra="") {
  return `<section class="ds24-summary-card" data-ds-component="DS v2 / Summary Card" data-figma-node="525:552" data-ds-prop-tone="Neutral" ${extra}><h2 class="ds24-summary-card__title">${esc(title)}</h2><p class="ds24-summary-card__body">${esc(body)}</p></section>`;
}
function ds24SectionTitle(title,meta="") { return `<div class="ds24-section-title"><h2 class="vet45-text-style-5">${esc(title)}</h2>${meta?`<span class="vet45-text-style-11">${esc(meta)}</span>`:''}</div>`; }
function ds24EmptyState(filtered=true) {
  return `<div class="ds24-empty" data-ds-component="VEmptyState"><div class="ds24-empty__media" data-ds-component="VEmptyMedia">${icon(filtered?'search':'inbox')}</div><h3 class="vet45-text-style-5" data-ds-component="VEmptyTitle">${filtered?'Không có kết quả phù hợp':'Chưa có dữ liệu tồn kho'}</h3><p class="vet45-text-style-6" data-ds-component="VEmptyDescription">${filtered?'Thử tên, mã sản phẩm hoặc chọn bộ lọc khác.':'Không có dữ liệu trong kho hiện tại.'}</p>${filtered?`<button class="ds24-button ds24-button--secondary" data-bj01-clear type="button" data-ds-component="VButton" data-figma-node="521:529">Xóa tìm kiếm và bộ lọc</button>`:''}</div>`;
}

function ds24Sheet({title,body,attrs=""}) {
  return `<div class="sheet-backdrop ds24-overlay" ${attrs}><section class="ds24-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" data-ds-prop-show-title="true" data-ds-prop-title="${escapeAttribute(title)}" role="dialog" aria-modal="true" aria-label="${escapeAttribute(title)}"><div class="ds24-sheet__handle" data-ds-internal="VBottomSheet.handle"></div><h3 class="vet45-text-style-4" data-ds-internal="VBottomSheet.title">${esc(title)}</h3><div class="ds24-sheet__body" data-ds-internal="VBottomSheet.content">${body}</div></section></div>`;
}


// ============================================================================


function ioSearchBar(placeholder,attr,value=""){return `<div class="search-box io-search" data-ds-component="VSearchBar" data-ds-profile="search.standard" data-ds-prop-variant="VSearchBarVariant.outlined" data-ds-prop-tone="VComponentTone.neutral" data-ds-prop-hint-text="${escapeAttribute(placeholder)}"><span class="search-leading">${icon("search","icon--sm")}</span><input ${attr} value="${escapeAttribute(value)}" placeholder="${escapeAttribute(placeholder)}" aria-label="${escapeAttribute(placeholder)}"/><span></span></div>`;}
function ioNormalizeSearch(value){return String(value||"").trim().toLocaleLowerCase("vi");}
function ioMatchesSearch(query,text){const q=ioNormalizeSearch(query);return !q||ioNormalizeSearch(text).includes(q);}
function ioFilterRows(scope,query){
  const q=ioNormalizeSearch(query); let visible=0;
  document.querySelectorAll(`[data-${scope}-search-text]`).forEach((row)=>{const show=!q||String(row.dataset[`${scope}SearchText`]||"").includes(q);row.hidden=!show;if(show)visible+=1;});
  const empty=document.querySelector(`[data-${scope}-filter-empty]`); if(empty)empty.hidden=visible!==0;
}
function ioSectionTitle(title,meta=""){return `<div class="io-section-title" data-ds-component="VSection"><h2 data-ds-component="VText">${title}</h2>${meta?`<span data-ds-component="VText" data-ds-prop-variant="VTextVariant.bodySmall">${meta}</span>`:""}</div>`;}
function ioMetaText(v){return String(v??"").replace(/<[^>]*>/g,"").replace(/&[a-zA-Z0-9#]+;/g," ").trim();}
function ioMetaDetail(label,value,strong=false){return `<div class="io-meta-detail" data-composed-from="VText"><span data-ds-component="VText" data-ds-prop-variant="VTextVariant.bodySmall">${label}</span><${strong?'strong':'p'} data-ds-component="VText" data-ds-prop-variant="VTextVariant.bodyDefault">${value}</${strong?'strong':'p'}></div>`;}
function ioMetaRow(label,value,strong=false){
  const calibrated=FIGMA_MIGRATED_FLOWS.has(activeFlowId);
  const labelText=ioMetaText(label), valueText=ioMetaText(value);
  const needsMultiline=calibrated && (labelText.length>22 || valueText.length>30 || (labelText.length+valueText.length)>44);
  if(needsMultiline) return ioMetaDetail(label,value,strong);
  return `<div class="io-meta-row" ${calibrated?'data-ds-component="DS v2 / Info Row" data-figma-node="525:351" data-ds-prop-state="Default"':'data-ds-component="VSection"'}><span data-ds-component="VText" data-ds-prop-variant="VTextVariant.bodySmall">${label}</span><${strong?'strong':'span'} data-ds-component="VText">${value}</${strong?'strong':'span'}></div>`;
}
function ioProductRow({name,code,primary,secondary="",badge="",badgeStatus="info",attr="",interactive=true}){const tag=interactive?"button":"div";const typeAttr=interactive?' type="button"':"";const composed=interactive?"VText,VBadge,VIcon":"VText,VBadge";return `<${tag} class="io-product-row ${interactive?"":"is-readonly"}" ${attr}${typeAttr} data-theme-component="InventoryOperationItemRow" data-ds-migration-state="LEGACY_COMPOSITE_NOT_LIST_ROW" data-composed-from="${composed}"><span class="io-product-copy"><strong data-ds-component="VText">${name}</strong><small data-ds-component="VText" data-ds-prop-variant="VTextVariant.bodySmall">${code}${secondary?` · ${secondary}`:""}</small>${badge?vBadge(badge,badgeStatus):""}</span><span class="io-product-value"><strong data-ds-component="VText">${primary}</strong>${interactive?icon("chevronRight","icon--sm"):""}</span></${tag}>`;}
function ioReadCard(body,extra=""){const calibrated=FIGMA_MIGRATED_FLOWS.has(activeFlowId);return `<section class="review-card io-read-card ${extra}" data-ds-component="${calibrated?'VSection':'VCard'}" ${calibrated?'data-composed-from="DS v2 / Info Row"':'data-ds-profile="card.readOnly"'}><div class="review-card-body">${body}</div></section>`;}
function ioSecondary(label,attr){return `<button class="button button--secondary button--full" ${attr} data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.secondary" data-ds-prop-size="VButtonSize.medium" type="button">${label}</button>`;}
function ioEmpty(title,desc){return `<div class="empty-state" data-ds-component="VEmptyState"><div class="icon-box" data-ds-component="VEmptyMedia">${icon("inbox")}</div><h3 data-ds-component="VEmptyTitle">${title}</h3><p data-ds-component="VEmptyDescription">${desc}</p></div>`;}
function resultHero(title,desc,kind="success"){const iconName=kind==="success"?"checkCircle":kind==="danger"?"xCircle":"clock";const toneClass=kind==="success"?"icon-box--success":kind==="danger"?"icon-box--danger":"icon-box--warning";return `<div class="result-hero result-hero--${kind}" data-ds-component="VSection" data-composed-from="VIcon,VText"><div class="icon-box ${toneClass}" data-ds-component="VIcon">${icon(iconName,"icon--empty-media")}</div><h2 data-ds-component="VText" data-ds-prop-variant="VTextVariant.headingH3">${title}</h2><p data-ds-component="VText" data-ds-prop-variant="VTextVariant.bodyDefault">${desc}</p></div>`;}
function ioResult(title,desc,rows,kind="success",button=""){return `<div class="io-result">${resultHero(title,desc,kind)}${ioReadCard(rows.map(r=>ioMetaRow(r[0],r[1],true)).join(''))}${button}</div>`;}

function ds24SelectField(label,value,options,attr="") {
  return `<label class="ds24-field" data-ds-component="VSelect" data-figma-node="522:7291"><span class="vet45-text-style-8">${esc(label)}</span><select ${attr} class="ds24-field__control vet45-text-style-6">${options.map(([v,l])=>`<option value="${v}" ${v===value?'selected':''}>${esc(l)}</option>`).join('')}</select></label>`;
}
function ds24TextField(label,value,attrs="",helper="") {
  return `<label class="ds24-field" data-ds-component="VTextField" data-figma-node="522:7186"><span class="vet45-text-style-8">${esc(label)}</span><input class="ds24-field__control vet45-text-style-6" value="${escapeAttribute(value)}" ${attrs}>${helper?`<small class="vet45-text-style-11">${esc(helper)}</small>`:''}</label>`;
}
function ds24Result(title,description,rows,tone='success') {
  const iconName=tone==='success'?'checkCircle':tone==='danger'?'xCircle':'alert';
  return `<section class="ds24-result" data-theme-component="Theme7OperationResult" data-composed-from="VIcon,VText,DS v2 / Info Row,State Pattern"><div class="ds24-result__icon ds24-result__icon--${tone}">${icon(iconName)}</div><h2 class="vet45-text-style-3">${esc(title)}</h2><p class="vet45-text-style-6">${esc(description)}</p><div class="ds24-info-stack">${rows.map(([k,v])=>ds24InfoRow(k,v)).join('')}</div></section>`;
}


// Chuyển luồng khi handoff (BJ-16 → BJ-11, BJ-17 …): đổi luồng + màn + trạng thái rồi dựng lại.


function crSwitchFlow(flowId,screenId,state){activeFlowId=flowId;activeScreenId=screenId;if(state&&stateByScreen[screenId]!==undefined)stateByScreen[screenId]=state;syncReviewUrl();render();}




const renderers = {};
for (const screen of screens) if (!renderers[screen.id]) renderers[screen.id]=(state)=>renderGeneric(screen,state);


// Một điểm vào duy nhất. Màn gốc chế độ theme → ThemeApp.renderRoot(); còn lại → rendererFor + afterFlowRender.
// Màn dùng chung nhiều luồng: mỗi luồng đăng ký hàm dựng riêng, flowRenderers["UIF-NN"]["SCR-NNN"] = fn.
const flowRenderers = {};
function rendererFor(flowId, screenId) { return flowRenderers[flowId]?.[screenId] || renderers[screenId]; }
// Mục renderers cho màn chỉ dựng theo luồng: rẽ sang flowRenderers, không có thì renderGeneric.
function flowScreen(screenId) {
  return (state) => (flowRenderers[activeFlowId]?.[screenId] || ((st) => renderGeneric(screens.find((s) => s.id === screenId), st)))(state);
}
["SCR-036","SCR-037","SCR-038","SCR-039","SCR-040","SCR-041"].forEach((id)=>{ renderers[id]=flowScreen(id); });
function renderAppScreen() {
  if (typeof ThemeApp !== "undefined" && ThemeApp.isRoot()) return ThemeApp.renderRoot();
  document.getElementById("app-screen").innerHTML = rendererFor(activeFlowId, activeScreenId)(stateByScreen[activeScreenId]);
  if (typeof ThemeApp !== "undefined") ThemeApp.afterFlowRender();
  syncDialogFocus();
}

// Sheet / hộp thoại (role="dialog"): mở thì đưa focus vào hộp thoại, đóng thì trả focus về nút đã mở.
// Màn dựng lại sau mỗi lần bấm nên nút mở được nhớ bằng thuộc tính data-* của nó, không bằng phần tử.
let dialogOpenerSelector = null, dialogWasOpen = false, dialogRestorePending = false;
document.addEventListener("click", (event) => {
  dialogRestorePending = false;
  const opener = event.target.closest("#app-screen button, #app-screen [role='button']");
  if (!opener || opener.closest('[role="dialog"]')) return;
  const dataAttrs = (el) => [...el.attributes].filter((a) => a.name.startsWith("data-") && !/^data-(ds|figma|composed|layout)/.test(a.name)).map((a) => `[${a.name}="${CSS.escape(a.value)}"]`).join("");
  // Nút mở ở ô đầu của dòng bảng (k7-row-open) không mang data-*: nhớ theo dòng chứa nó.
  const row = opener.classList.contains("k7-row-open") ? opener.closest("tr") : null;
  dialogOpenerSelector = (row ? dataAttrs(row) && `tr${dataAttrs(row)} .k7-row-open` : dataAttrs(opener)) || null;
}, true);
function syncDialogFocus() {
  const screen = document.getElementById("app-screen");
  const dialog = screen.querySelector('[role="dialog"]');
  if (dialog) {
    if (!dialog.contains(document.activeElement)) { if (!dialog.hasAttribute("tabindex")) dialog.setAttribute("tabindex", "-1"); dialog.focus({ preventScroll: true }); }
    dialogWasOpen = true;
    return;
  }
  // Một thao tác có thể dựng lại màn hai lần (vd. Esc rồi render chung): còn chờ trả focus cho tới lần bấm sau.
  if (dialogWasOpen) dialogRestorePending = true;
  dialogWasOpen = false;
  const lost = document.activeElement === document.body || !screen.contains(document.activeElement);
  if (dialogRestorePending && dialogOpenerSelector && lost) screen.querySelector(dialogOpenerSelector)?.focus({ preventScroll: true });
}

// Esc đóng sheet / hộp thoại: mỗi luồng đăng ký hàm đóng của mình (trả true nếu có gì để đóng và đã tự dựng lại màn).
// Tab / Shift+Tab chỉ đi vòng trong hộp thoại đang mở.
const onDialogClose = {};
window.addEventListener("keydown", (event) => {
  if (event.key === "Escape") { if (onDialogClose[activeFlowId]?.()) event.preventDefault(); return; }
  if (event.key !== "Tab") return;
  const dialog = document.querySelector('#app-screen [role="dialog"]');
  if (!dialog) return;
  const items = [...dialog.querySelectorAll("button:not([disabled]), [href], input, textarea, select, [tabindex]:not([tabindex='-1'])")].filter((el) => el.offsetParent !== null);
  if (!items.length) return;
  const first = items[0], last = items[items.length - 1], at = document.activeElement;
  if (event.shiftKey ? (at === first || !dialog.contains(at) || at === dialog) : (at === last || !dialog.contains(at))) { event.preventDefault(); (event.shiftKey ? last : first).focus(); }
}, true);

function render() {
  renderFlowSelector();
  renderNavigation();
  renderInspector();
  if (typeof ThemeApp !== "undefined") ThemeApp.renderWebSidebar();
  renderAppScreen();
  if (typeof applyGroupedSurfaceRule === "function") applyGroupedSurfaceRule();
  if (inspectEnabled) resetInspectSelection();
  requestAnimationFrame(fitReviewDeviceToViewport);
}

function syncReviewUrl() {
  const url = new URL(window.location.href);
  url.searchParams.set("uif", activeFlowId);
  url.searchParams.set("screen", activeScreenId);
  url.searchParams.set("state", stateByScreen[activeScreenId]);
  url.searchParams.set("flow", flowMode);
  url.searchParams.set("viewport", viewport);
  if (typeof ThemeApp !== "undefined") ThemeApp.decorateUrl(url);
  history.replaceState(null, "", url);
}

// Móc chạy khi điều hướng vào một màn (khoá "UIF-NN:SCR-NNN"), thay cho việc bọc navigate.
const onScreenEnter = {};

// Móc chạy khi người xem đổi khung iPhone / web (harness gọi, rồi dựng lại màn): chuẩn hoá trạng thái màn có bố cục riêng theo khung.
const onViewportChange = [];

// Móc nút quay lại (data-back) theo luồng, thay cho nhánh của từng BJ trong previousScreen.
const onPrevious = {};

// Móc khoá nguồn khi handoff UNKNOWN (UIF-05/06/07 đăng ký; bj17HandoffUnknown gọi).
const onUnknownHandoff = {};
// Móc đối xứng: BJ-17 gọi khi hồ sơ "Đã xác lập" với { operationId, outcome: "RECORDED" | "NOT_RECORDED" } — BJ nguồn mở khoá và đổi trạng thái thao tác.
const onUnknownResolved = {};

// Đường cũ của luồng: navigate(màn cũ) → màn mới (cùng luồng), hoặc → [luồng khác, màn].
const screenAliases = {};

function navigate(screenId) {
  const alias = screenAliases[activeFlowId]?.[screenId];
  if (Array.isArray(alias)) { activeFlowId = alias[0]; screenId = alias[1]; }
  else if (alias) screenId = alias;
  if (!renderers[screenId]) return;
  onScreenEnter[`${activeFlowId}:${screenId}`]?.();
  activeScreenId = screenId;
  syncReviewUrl();
  render();
}

function previousScreen() {
  if (typeof ThemeApp !== "undefined" && ThemeApp.handlePrevious()) return;
  if (onPrevious[activeFlowId]) return onPrevious[activeFlowId]();
  const list = activeFlow()?.screens || [];
  const idx = list.indexOf(activeScreenId);
  if (idx > 0) return navigate(list[idx - 1]);
}

function normalizeToastType(type = "success") {
  const raw=String(type||"success");
  const aliases={xCircle:"danger",error:"danger",danger:"danger",alert:"warning",warning:"warning",info:"info",rotate:"info",arrowLeft:"info",arrowRight:"info",shield:"info",layers:"info",checkCircle:"success",success:"success"};
  return aliases[raw]||"success";
}
function showToastCanonical(message, type = "success") {
  const screen=document.getElementById("app-screen");
  const oldToast=screen.querySelector(".toast");
  if(oldToast)oldToast.remove();
  const toastType=normalizeToastType(type);
  const iconName=toastType==="danger"?"xCircle":toastType==="warning"?"alert":toastType==="info"?"info":"checkCircle";
  const semanticIcon=toastType==="danger"?"VIcons.error":toastType==="warning"?"VIcons.warning":toastType==="info"?"VIcons.info":"VIcons.success";
  const toast=document.createElement("div");
  toast.className="toast";
  toast.dataset.dsComponent="VToast";
  toast.dataset.figmaNode="526:4305";
  toast.dataset.dsPropType=`VToastType.${toastType}`;
  toast.dataset.dsPropMessage=message;
  toast.innerHTML=`<span class="toast-icon-box" data-ds-component="VIconBox" data-ds-prop-is-circular="true" data-ds-prop-size="24" data-ds-prop-icon-size="14" data-ds-prop-icon="${semanticIcon}">${icon(iconName,"icon--sm")}</span><span class="toast-message" data-ds-internal="VToast.message">${esc(message)}</span><button class="toast-close" data-action="close-toast" type="button" aria-label="Đóng thông báo" data-ds-internal="VToast.close" data-ds-icon="VIcons.close">${icon("close","icon--sm")}</button>`;
  screen.appendChild(toast);
  window.clearTimeout(toastTimer);
  toastTimer=window.setTimeout(()=>toast.remove(),2600);
  return toast;
}
function showToast(message,type="success"){return showToastCanonical(message,type);}


document.addEventListener("click", (event) => {
  const nextButton = event.target.closest("[data-next]");
  if (nextButton) return navigate(nextButton.dataset.next);

  if (event.target.closest("[data-back]")) return previousScreen();

  const actionButton = event.target.closest("[data-action]");
  if (!actionButton) return;
  const action = actionButton.dataset.action;
  if (action === "close-toast") { actionButton.closest(".toast")?.remove(); return; }
});

// Lối ra dự phòng — màn gắn data-k1-action="exit".
document.addEventListener("click", (event) => {
  const action = event.target.closest("[data-k1-action]");
  if (!action || action.disabled) return;
  if (action.dataset.k1Action === "exit") {
    event.preventDefault();
    event.stopPropagation();
    const target = action.dataset.k1Target;
    if (target) return navigate(target);
  }
}, true);





document.addEventListener("click",(e)=>{
  const next=e.target.closest("[data-generic-next]"); if(next){ const ids=activeFlow()?.screens||[]; const i=ids.indexOf(activeScreenId); if(i>=0&&i<ids.length-1) navigate(ids[i+1]); else showToast("Đã hoàn thành flow demo", "checkCircle"); }
  const act=e.target.closest("[data-generic-action]"); if(act){ showToast(`${act.textContent.trim()} · prototype không gọi backend`, "checkCircle"); }
  const card=e.target.closest(".generic-data-card[data-ds-profile='card.interactive']"); if(card&&!inspectEnabled){ const ids=activeFlow()?.screens||[]; const i=ids.indexOf(activeScreenId); if(i>=0&&i<ids.length-1) navigate(ids[i+1]); }
});




/* Bước dựng chung (DS) — grouped surface (trước đây v440; giữ MutationObserver vì DOM đổi ngoài render). */
function applyGroupedSurfaceRule() {
  const ROW_SELECTOR = '[data-ds-component="DS v2 / Info Row"],[data-ds-component="DS v2 / Key-value Row"]';
  const ROOT_BOUNDARY_SELECTOR = '#app-screen,.app-content,.app-body,.app-shell,.device-screen';
  const alpha = (value) => {
    const text = String(value || '');
    if (!text || text === 'transparent') return 0;
    const m = text.match(/rgba?\(([^)]+)\)/i);
    if (!m) return 1;
    const parts = m[1].split(',').map((v) => v.trim());
    return parts.length < 4 ? 1 : Number(parts[3]);
  };
  const hasVisualSurface = (el) => {
    if (!el) return false;
    const s = getComputedStyle(el);
    const borderWidths = [s.borderTopWidth, s.borderRightWidth, s.borderBottomWidth, s.borderLeftWidth].map((v) => parseFloat(v) || 0);
    const hasBorder = borderWidths.some((v) => v > 0.1) && [s.borderTopStyle, s.borderRightStyle, s.borderBottomStyle, s.borderLeftStyle].some((v) => v !== 'none');
    const hasShadow = Boolean(s.boxShadow && s.boxShadow !== 'none');
    const hasBackground = alpha(s.backgroundColor) > 0.01;
    return hasBorder || hasShadow || hasBackground;
  };
  const alreadyOwnedBySurface = (stack) => {
    let current = stack;
    for (let depth = 0; current && depth < 3; depth += 1, current = current.parentElement) {
      if (depth > 0 && current.matches?.(ROOT_BOUNDARY_SELECTOR)) break;
      if (hasVisualSurface(current)) return true;
    }
    return false;
  };
  const isMinimalRowStack = (el) => {
    const direct = [...el.children].filter((child) => child.matches?.(ROW_SELECTOR));
    if (direct.length < 2) return false;
    return ![...el.children].some((child) => [...child.children].filter((grand) => grand.matches?.(ROW_SELECTOR)).length >= 2);
  };
  const root = document.querySelector('#app-screen');
  if (!root) return { candidates: 0, added: 0 };
  let candidates = 0, added = 0;
  root.querySelectorAll('*').forEach((el) => {
    if (!isMinimalRowStack(el)) return;
    candidates += 1;
    if (alreadyOwnedBySurface(el)) return;
    el.classList.add('v440-grouped-surface');
    el.setAttribute('data-layout-pattern', 'Grouped surface');
    el.setAttribute('data-v440-grouped-surface', 'auto');
    added += 1;
  });
  return { candidates, added };
}
window.__VET45_QA__.applyGroupedSurfaceRule = applyGroupedSurfaceRule;
(() => {
  const root = document.querySelector('#app-screen');
  if (!root || typeof MutationObserver === 'undefined') return;
  let scheduled = false;
  new MutationObserver(() => {
    if (scheduled) return;
    scheduled = true;
    queueMicrotask(() => { scheduled = false; applyGroupedSurfaceRule(); });
  }).observe(root, { childList: true, subtree: true });
})();

syncReviewUrl();
