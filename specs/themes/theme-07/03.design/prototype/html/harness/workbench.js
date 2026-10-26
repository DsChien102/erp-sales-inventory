/* Harness — sidebar, inspector, Inspect overlay, device frame (T7-P A11). */

const FLOW_GROUPS = [
  { id: "inventory-operations", label: "Inventory operations", bjs: ["BJ-01", "BJ-02", "BJ-04", "BJ-05", "BJ-06", "BJ-07"] },
  { id: "inventory-valuation", label: "Inventory valuation", bjs: ["BJ-03", "BJ-13", "BJ-14"] },
  { id: "inventory-audit-control", label: "Inventory audit & control", bjs: ["BJ-08", "BJ-09", "BJ-10", "BJ-11", "BJ-12", "BJ-15", "BJ-16", "BJ-17"] },
  { id: "supporting", label: "Supporting capability", bjs: ["CAP-01"] },
];


function renderFlowSelector() {
  if (typeof ThemeApp !== "undefined") ThemeApp.updateModeTabs();
  if (typeof ThemeApp !== "undefined" && ThemeApp.inTheme()) return ThemeApp.renderFlowSelector();
  document.body.dataset.workbenchMode = "bj";
  const sel=document.getElementById("flow-selector"); if(!sel) return;
  const grouped = FLOW_GROUPS.map((group) => ({
    label: group.label,
    flows: flowCatalog.filter((flow) => group.bjs.includes(flow.bj)),
  })).filter((group) => group.flows.length > 0);
  const ungrouped = flowCatalog.filter((flow) => !FLOW_GROUPS.some((group) => group.bjs.includes(flow.bj)));
  if (ungrouped.length) grouped.push({ label: "Other", flows: ungrouped });
  sel.innerHTML = grouped.map((group) => `
    <optgroup label="${group.label}">
      ${group.flows.map((f) => `<option value="${f.id}" ${f.id===activeFlowId?"selected":""}>${f.id} · ${f.bj} · ${f.name}</option>`).join("")}
    </optgroup>
  `).join("");
  const f=activeFlow();
  document.body.dataset.activeUif = f.id;
  document.getElementById("sidebar-flow-title").textContent=`${f.id} · ${f.name}`;
  document.getElementById("sidebar-flow-intent").textContent=f.intent || "";
  document.getElementById("workbench-title").textContent=`${f.bj} · ${f.name}`;
  document.getElementById("workbench-count").textContent=`${f.screens.length} màn · ${f.id}`;
}
function renderNavigation() {
  if (typeof ThemeApp !== "undefined" && ThemeApp.inTheme()) return ThemeApp.renderNavigation();
  const navigation=document.getElementById("screen-navigation");
  navigation.innerHTML=`<div class="nav-group"><span class="nav-group-label">Screens</span>${flowScreens().map((screen)=>`<button class="screen-nav-item ${screen.id===activeScreenId?"is-active":""}" data-screen="${screen.id}" type="button"><span class="screen-nav-number">${screen.short}</span><span class="screen-nav-copy"><strong>${screen.name}</strong><span>${screen.surface}</span></span><span class="nav-chevron">›</span></button>`).join("")}</div>`;
}
function renderInspector() {
  if (typeof ThemeApp !== "undefined" && ThemeApp.isRoot()) return ThemeApp.renderRootInspector();
  renderFlowInspector();
  if (typeof ThemeApp !== "undefined") ThemeApp.afterFlowInspector();
}
function renderFlowInspector() {
  const screen=currentScreen(); const state=stateByScreen[screen.id]; const f=activeFlow();
  document.getElementById("current-screen-id").textContent=`${screen.id} · ${screen.surface}`;
  document.getElementById("current-screen-name").textContent=screen.name;
  document.getElementById("state-switcher").innerHTML=screen.states.map((item)=>`<button class="state-chip ${item===state?"is-active":""}" data-state="${item}" type="button">${item}</button>`).join("");
  const actions=(screen.actions||[]).map((a)=>a.id).join(" · ") || (screen.traceActions?.length ? `System: ${screen.traceActions.join(" · ")}` : "Navigation / query");
  const figmaMigrationLabel = ({
    "UIF-01":"v3.0.1 · BJ01 migrated + DS hard-gated",
    "UIF-02":"v5.8.0 · BJ-02 thiết kế lại",
    "UIF-03":"v5.9.0 · BJ-03 thiết kế lại",
    "UIF-13":"v5.10.0 · BJ-13 thiết kế lại",
    "UIF-14":"v5.19.0 · BJ-14 thiết kế lại",
    "UIF-04":"v5.11.0 · BJ-04 thiết kế lại",
    "UIF-05":"v5.11.0 · BJ-05 thiết kế lại",
    "UIF-06":"v5.12.0 · BJ-06 thiết kế lại",
    "UIF-07":"v5.14.0 · BJ-07 thiết kế lại",
    "UIF-08":"v5.16.0 · BJ-08 thiết kế lại",
    "UIF-09":"v5.13.0 · BJ-09 thiết kế lại · K5",
    "UIF-10":"v5.15.0 · BJ-10 thiết kế lại",
    "UIF-11":"v5.17.0 · BJ-11 thiết kế lại",
    "UIF-12":"v3.2.0 · BJ12 số dư đầu kỳ + control foundation",
    "UIF-15":"v5.20.0 · BJ-15 thiết kế lại",
    "UIF-16":"v5.18.0 · BJ-16 thiết kế lại",
    "UIF-17":"v5.18.0 · BJ-17 thiết kế lại",
    "CAP-01":"v5.7.0 · CAP-01 thiết kế lại"
  })[activeFlowId] || "Calibrated shell · structural migration pending";
  document.getElementById("traceability").innerHTML=`<div class="trace-row"><span>BJ / UIF</span><strong>${f.bj} · ${f.id}</strong></div><div class="trace-row"><span>UC</span><strong>${(screen.uc||[]).join(" · ")||"—"}</strong></div><div class="trace-row"><span>Purpose</span><strong>${screen.purpose||"—"}</strong></div><div class="trace-row"><span>Action</span><strong>${actions}</strong></div><div class="trace-row"><span>Figma DS</span><strong>${figmaMigrationLabel}</strong></div><div class="trace-row"><span>DS annotations</span><strong>VPageScaffold → VAppBar · ${(screen.components||[]).join(" · ")}</strong></div><div class="trace-row"><span>Composition</span><strong>${screen.themeComposition||"—"}</strong></div>`;
  document.getElementById("design-rationale").textContent=f.intent || screen.purpose;
}




// Review-only Inspect state. Kept outside product UI.
let inspectEnabled = false;
let inspectPinned = false;
let inspectTarget = null;

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function inspectableFrom(target) {
  if (!(target instanceof Element)) return null;
  const hit = target.closest('[data-ds-component], [data-theme-component], [data-ds-internal]');
  return hit && hit.closest('#app-screen') ? hit : null;
}

function numberPx(style, property) {
  const value = Number.parseFloat(style.getPropertyValue(property));
  return Number.isFinite(value) ? value : 0;
}

function boxRect(rect, top, right, bottom, left, mode = "expand") {
  if (mode === "expand") {
    return { left: rect.left - left, top: rect.top - top, width: rect.width + left + right, height: rect.height + top + bottom };
  }
  return { left: rect.left + left, top: rect.top + top, width: Math.max(0, rect.width - left - right), height: Math.max(0, rect.height - top - bottom) };
}

function setInspectBox(node, box) {
  Object.assign(node.style, {
    left: `${box.left}px`, top: `${box.top}px`, width: `${box.width}px`, height: `${box.height}px`,
  });
}

function figmaAssetTarget(name, layer = "COMPONENT", status = "EXACT", note = "") {
  const asset = FIGMA_DS_MAP.assetIndex?.[name] || {};
  return { name, nodeId: asset.nodeId || null, assetType: asset.assetType || null, section: asset.section || null, layer, status, note };
}

function resolveFigmaMapping(element) {
  const ds = element.dataset.dsComponent || "";
  const theme = element.dataset.themeComponent || "";
  const internal = element.dataset.dsInternal || "";
  const profile = element.dataset.dsProfile || "";
  let source = "";
  let mapping = null;
  if (theme && FIGMA_DS_MAP.themeComponentMappings?.[theme]) { source = `theme:${theme}`; mapping = FIGMA_DS_MAP.themeComponentMappings[theme]; }
  else if (internal && FIGMA_DS_MAP.internalMappings?.[internal]) { source = `internal:${internal}`; mapping = FIGMA_DS_MAP.internalMappings[internal]; }
  else if (ds) {
    const base = FIGMA_DS_MAP.componentMappings?.[ds] || null;
    const contextual = profile ? (FIGMA_DS_MAP.profileMappings?.[`${ds}|${profile}`] || null) : null;
    if (base && contextual && ["PATTERN","TEMPLATE","FOUNDATION"].includes(contextual.layer) && ["EXACT","LEGACY_ALIAS","EXACT_FOUNDATION"].includes(base.status)) {
      source = `component:${ds}`; mapping = { ...base, contextMapping: contextual };
    } else if (contextual) { source = `profile:${ds}|${profile}`; mapping = contextual; }
    else if (base) { source = `component:${ds}`; mapping = base; }
    else if (FIGMA_DS_MAP.assetIndex?.[ds]) {
      const asset=FIGMA_DS_MAP.assetIndex[ds];
      const section=String(asset.section||"");
      const layer=section.includes("Patterns")||section.includes("Form Patterns")?"PATTERN":section.includes("Page Templates")?"TEMPLATE":"COMPONENT";
      source=`asset:${ds}`; mapping=figmaAssetTarget(ds,layer,"EXACT","Direct live Figma DS asset used by Phase 4 rollout.");
    }
  }

  // Dynamic legacy aliases that depend on actual rendered anatomy.
  if (ds === "VButton" && String(element.dataset.dsPropVariant || "").toLowerCase().includes("link")) {
    source = "dynamic:VButton.link"; mapping = figmaAssetTarget("DS v2 / Link", "COMPONENT", "LEGACY_ALIAS", "Legacy link-style button resolves to canonical Link component.");
  }
  if (ds === "VTextFormField" && element.querySelector("textarea")) {
    source = "dynamic:VTextFormField.multiline"; mapping = FIGMA_DS_MAP.componentMappings?.VTextarea || mapping;
  }
  if (ds === "VPageScaffold") {
    const explicitTemplate = element.dataset.figmaTemplate || "";
    if (explicitTemplate) {
      source = `phase5:template:${activeFlowId}:${activeScreenId}`;
      mapping = figmaAssetTarget(explicitTemplate, "TEMPLATE", "EXACT", "Phase 5 Theme 7 screen uses the explicit task-appropriate Figma page template.");
      return { ...mapping, source, legacy: { ds, theme, internal, profile } };
    }
    const surface = currentScreen()?.surface || "";
    let name = null;
    if (["result", "status / entry", "validation result"].includes(surface)) name = "Mobile / Detail";
    else if (surface === "form" || surface === "choice" || surface === "approval review") name = "Mobile / Form";
    else if (surface === "list") name = element.dataset.dsPropShowBackButton === "false" ? "Mobile / Root List" : "Mobile / Nested List";
    else if (["detail", "review", "timeline", "dashboard"].includes(surface)) name = "Mobile / Detail";
    if (name) { source = `dynamic:template:${surface}`; mapping = figmaAssetTarget(name, "TEMPLATE", "MIGRATION_TARGET", "Fallback template candidate derived from current task/surface; explicit Phase 5 mappings are authoritative."); }
  }
  if (!mapping) mapping = { name: ds || theme || internal || element.tagName.toLowerCase(), nodeId: null, assetType: null, section: null, layer: "UNMAPPED", status: "UNMAPPED", note: "No Phase 2 mapping rule." };
  return { ...mapping, source, legacy: { ds, theme, internal, profile } };
}

function figmaTextStyleFor(element) {
  const v = String(element.dataset.dsPropVariant || "");
  if (v.includes("headingH1")) return "VET45 v2 / Heading / H1";
  if (v.includes("headingH2")) return "VET45 v2 / Heading / H2";
  if (v.includes("headingH3")) return "VET45 v2 / Heading / H3";
  if (v.includes("headingH4")) return "VET45 v2 / Heading / H4";
  if (v.includes("bodySmall")) return "VET45 v2/Body/Small";
  if (v.includes("bodyDefault") || v.includes("bodyMedium")) return "VET45 v2 / Body / Default";
  if (element.matches("h1")) return "VET45 v2 / Heading / H1";
  if (element.matches("h2")) return "VET45 v2 / Heading / H3";
  if (element.matches("h3")) return "VET45 v2 / Heading / H4";
  if (element.matches("small")) return "VET45 v2/Body/Small";
  if (element.matches("strong")) return "VET45 v2 / Label / Default";
  return "VET45 v2 / Body / Default";
}

function canonicalFigmaProps(element, mapping) {
  const ds = element.dataset.dsComponent || "";
  const out = [];
  if (ds === "VButton") {
    const variant = String(element.dataset.dsPropVariant || "").toLowerCase();
    const tone = String(element.dataset.dsPropTone || "").toLowerCase();
    if (mapping.name === "DS v2 / Link") {
      out.push(["Tone", tone.includes("danger") ? "Danger" : "Default"]);
      out.push(["State", element.disabled ? "Disabled" : "Default"]);
    } else {
      let hierarchy = tone.includes("danger") ? "Danger" : variant.includes("secondary") ? "Secondary" : variant.includes("tertiary") ? "Tertiary" : "Primary";
      const size = String(element.dataset.dsPropSize || "").toLowerCase();
      out.push(["Hierarchy", hierarchy]);
      out.push(["State", element.disabled ? "Disabled" : element.classList.contains("is-loading") ? "Loading" : "Default"]);
      out.push(["Size", size.includes("small") ? "Small" : size.includes("large") ? "Large" : "Default"]);
    }
  } else if (ds === "VBadge") {
    const status = String(element.dataset.dsPropStatus || element.className || "").toLowerCase();
    const tone = status.includes("success") ? "Success" : status.includes("warning") ? "Warning" : status.includes("danger") || status.includes("error") ? "Danger" : status.includes("info") ? "Info" : "Neutral";
    out.push(["Tone", tone], ["Style", "Soft"]);
  } else if (ds === "VBanner") {
    const status = String(element.dataset.dsPropStatus || element.className || "").toLowerCase();
    const tone = status.includes("success") ? "Success" : status.includes("warning") ? "Warning" : status.includes("danger") || status.includes("error") ? "Danger" : "Info";
    out.push(["Tone", tone], ["Density", "Default"]);
  } else if (ds === "VChip") {
    const selected = element.dataset.dsPropSelected === "true" || element.classList.contains("is-active");
    out.push(["Tone", selected ? "Brand" : "Neutral"], ["State", element.disabled ? "Disabled" : "Default"]);
  } else if (ds === "VAppBar") {
    const back = element.querySelector('[data-ds-internal="VAppBar.leading"]') !== null;
    const subtitle = element.querySelector('[data-ds-component="VAppBarSubtitle"]') !== null;
    out.push(["Type", back && subtitle ? "Context" : back ? "Back" : subtitle ? "Root context" : "Root"]);
  } else if (ds === "VEmptyState") {
    const text = element.textContent || "";
    let type = element.dataset.themeComponent === "PermissionDeniedState" ? "No Permission" : /không có kết quả/i.test(text) ? "No Result" : /bị chặn|không thể tiếp tục/i.test(text) ? "Blocked" : /lỗi|không tải/i.test(text) ? "Error" : "Empty";
    out.push(["Type", type]);
  } else if (ds === "VSearchBar") {
    const input = element.querySelector("input");
    out.push(["State", element.matches(":focus-within") ? "Focused" : input?.disabled ? "Disabled" : input?.value ? "Filled" : "Default"]);
  } else if (["VTextField","VTextFormField","VNumberField","VDatePicker","VDatePickerField","VSelect"].includes(ds)) {
    const input = element.querySelector("input,textarea,select") || (element.matches("input,textarea,select") ? element : null);
    out.push(["State", element.matches(":focus-within") ? "Focused" : input?.disabled ? "Disabled" : input?.value ? "Filled" : "Default"]);
  } else if (ds === "VRadio") {
    const input = element.querySelector('input[type="radio"]');
    out.push(["State", input?.disabled ? (input.checked ? "Disabled On" : "Disabled Off") : input?.checked || element.classList.contains("is-selected") ? "On" : "Off"]);
  } else if (ds === "VSegmentedControl") {
    const items = [...element.querySelectorAll("button")];
    const selected = items.findIndex((x)=>x.classList.contains("is-selected") || x.getAttribute("aria-pressed") === "true");
    if (selected >= 0) out.push(["Selected", String(selected + 1)]);
  } else if (ds === "VText") {
    out.push(["Text style", figmaTextStyleFor(element)]);
  } else if (ds === "VIcon") {
    out.push(["Registry", "VET45 approved Icon Library"]);
    if (element.dataset.dsPropIcon) out.push(["Icon", element.dataset.dsPropIcon.replace(/^VIcons\./, "")]);
  }
  return out;
}

function inspectLabel(element) {
  const mapping = resolveFigmaMapping(element);
  return mapping.name || element.dataset.dsComponent || element.dataset.themeComponent || element.dataset.dsInternal || element.tagName.toLowerCase();
}

function collectInspectProps(element) {
  const props = [];
  for (const attr of element.attributes) {
    if (attr.name.startsWith('data-ds-prop-')) props.push([attr.name.slice('data-ds-prop-'.length), attr.value]);
  }
  if (element.dataset.dsProfile) props.unshift(['profile', element.dataset.dsProfile]);
  if (element.dataset.dsSlot) props.push(['slot', element.dataset.dsSlot]);
  if (element.dataset.dsDefaultIcon) props.push(['defaultIcon', element.dataset.dsDefaultIcon]);
  if (element.dataset.dsIcon) props.push(['icon', element.dataset.dsIcon]);
  if (element.dataset.composedFrom) props.push(['composedFrom', element.dataset.composedFrom]);
  if (element.dataset.dsGap) props.push(['DS gap', element.dataset.dsGap]);
  return props;
}

function inspectBoxValues(element) {
  const style = getComputedStyle(element);
  const rect = element.getBoundingClientRect();
  const margin = [numberPx(style,'margin-top'), numberPx(style,'margin-right'), numberPx(style,'margin-bottom'), numberPx(style,'margin-left')];
  const border = [numberPx(style,'border-top-width'), numberPx(style,'border-right-width'), numberPx(style,'border-bottom-width'), numberPx(style,'border-left-width')];
  const padding = [numberPx(style,'padding-top'), numberPx(style,'padding-right'), numberPx(style,'padding-bottom'), numberPx(style,'padding-left')];
  const marginRect = boxRect(rect, ...margin, 'expand');
  const paddingRect = boxRect(rect, ...border, 'shrink');
  const contentRect = boxRect(paddingRect, ...padding, 'shrink');
  return { style, rect, margin, border, padding, marginRect, borderRect: rect, paddingRect, contentRect };
}

function fourSides(values) {
  return `${Math.round(values[0] * 10) / 10} · ${Math.round(values[1] * 10) / 10} · ${Math.round(values[2] * 10) / 10} · ${Math.round(values[3] * 10) / 10}`;
}

function renderInspectDetails(element, boxes) {
  const panel = document.getElementById('inspect-details');
  const mapping = resolveFigmaMapping(element);
  const legacyProps = collectInspectProps(element);
  const figmaProps = canonicalFigmaProps(element, mapping);
  const figmaPropsHtml = figmaProps.length
    ? figmaProps.map(([k,v]) => `<div class="inspect-prop"><span>${escapeHtml(k)}</span><code>${escapeHtml(v)}</code></div>`).join('')
    : '<div class="inspect-muted">Không có variant/state canonical bổ sung cho node này.</div>';
  const legacyPropsHtml = legacyProps.length
    ? legacyProps.map(([k,v]) => `<div class="inspect-prop"><span>${escapeHtml(k)}</span><code>${escapeHtml(v)}</code></div>`).join('')
    : '<div class="inspect-muted">Không có legacy prop override.</div>';
  const legacyLabel = [mapping.legacy?.theme && `Theme7.${mapping.legacy.theme}`, mapping.legacy?.ds, mapping.legacy?.internal].filter(Boolean).join(' · ') || '—';
  panel.innerHTML = `
    <div class="inspect-component-name">${escapeHtml(mapping.name)}</div>
    <div class="inspect-meta-grid">
      <span>Figma node</span><strong>${escapeHtml(mapping.nodeId || '—')}</strong>
      <span>Layer</span><strong>${escapeHtml(mapping.layer || '—')}</strong>
      <span>Mapping</span><strong>${escapeHtml(mapping.status || '—')}</strong>
      <span>Section</span><strong>${escapeHtml(mapping.section || '—')}</strong>
      <span>Authority</span><strong>Figma DS v2.0.3</strong>
      <span>Legacy</span><strong>${escapeHtml(legacyLabel)}</strong>
      <span>Element</span><strong>${escapeHtml(element.tagName.toLowerCase())}</strong>
      ${mapping.contextMapping ? `<span>Context</span><strong>${escapeHtml(mapping.contextMapping.name)}${mapping.contextMapping.nodeId ? ` · ${escapeHtml(mapping.contextMapping.nodeId)}` : ''}</strong>` : ''}
    </div>
    ${mapping.note ? `<div class="inspect-mapping-note">${escapeHtml(mapping.note)}</div>` : ''}
    <div class="inspect-subtitle">Figma props / variant</div>
    <div class="inspect-props">${figmaPropsHtml}</div>
    <div class="inspect-subtitle">Legacy annotation / trace</div>
    <div class="inspect-props">${legacyPropsHtml}</div>
    <div class="inspect-subtitle">Box model · T/R/B/L (px)</div>
    <div class="box-model-readout">
      <div class="box-line box-line--margin"><span>margin</span><code>${fourSides(boxes.margin)}</code></div>
      <div class="box-line box-line--border"><span>border</span><code>${fourSides(boxes.border)}</code></div>
      <div class="box-line box-line--padding"><span>padding</span><code>${fourSides(boxes.padding)}</code></div>
      <div class="box-line box-line--content"><span>content</span><code>${Math.round(boxes.contentRect.width * 10) / 10} × ${Math.round(boxes.contentRect.height * 10) / 10}</code></div>
    </div>`;
}

function showInspectOverlay(element) {
  if (!inspectEnabled || !element || !element.isConnected) return;
  inspectTarget = element;
  const overlay = document.getElementById('inspect-overlay');
  const boxes = inspectBoxValues(element);
  overlay.hidden = false;
  setInspectBox(overlay.querySelector('.inspect-box--margin'), boxes.marginRect);
  setInspectBox(overlay.querySelector('.inspect-box--border'), boxes.borderRect);
  setInspectBox(overlay.querySelector('.inspect-box--padding'), boxes.paddingRect);
  setInspectBox(overlay.querySelector('.inspect-box--content'), boxes.contentRect);
  const tag = overlay.querySelector('.inspect-tag');
  tag.textContent = inspectLabel(element);
  const tagTop = Math.max(4, boxes.borderRect.top - 25);
  const tagLeft = Math.max(4, Math.min(boxes.borderRect.left, window.innerWidth - 280));
  tag.style.top = `${tagTop}px`;
  tag.style.left = `${tagLeft}px`;
  renderInspectDetails(element, boxes);
}

function hideInspectOverlay() {
  const overlay = document.getElementById('inspect-overlay');
  if (overlay) overlay.hidden = true;
}

function resetInspectSelection() {
  inspectPinned = false;
  inspectTarget = null;
  hideInspectOverlay();
  const status = document.getElementById('inspect-pin-status');
  if (status) status.textContent = inspectEnabled ? 'Hover component' : 'Inspect off';
  const details = document.getElementById('inspect-details');
  if (details && inspectEnabled) details.textContent = 'Rê chuột lên component; click để ghim. Esc để bỏ ghim.';
}

function toggleInspect(force) {
  inspectEnabled = typeof force === 'boolean' ? force : !inspectEnabled;
  document.body.classList.toggle('inspect-mode', inspectEnabled);
  const toggle = document.getElementById('inspect-toggle');
  toggle.classList.toggle('is-active', inspectEnabled);
  toggle.setAttribute('aria-pressed', String(inspectEnabled));
  toggle.textContent = inspectEnabled ? 'Inspect · On' : 'Inspect';
  document.getElementById('inspect-section').hidden = !inspectEnabled;
  const url = new URL(window.location.href);
  if (inspectEnabled) url.searchParams.set('inspect', '1'); else url.searchParams.delete('inspect');
  history.replaceState(null, '', url);
  resetInspectSelection();
}

document.getElementById('inspect-toggle')?.addEventListener('click', () => toggleInspect());
document.getElementById('app-screen')?.addEventListener('pointermove', (event) => {
  if (!inspectEnabled || inspectPinned) return;
  const target = inspectableFrom(event.target);
  if (target) showInspectOverlay(target); else hideInspectOverlay();
});
document.getElementById('app-screen')?.addEventListener('pointerleave', () => {
  if (inspectEnabled && !inspectPinned) hideInspectOverlay();
});

// Capture click inside product viewport while Inspect is on so prototype actions
// never fire accidentally. A click pins the selected component instead.
window.addEventListener('click', (event) => {
  if (!inspectEnabled || !event.target.closest?.('#app-screen')) return;
  const target = inspectableFrom(event.target);
  if (!target) return;
  event.preventDefault();
  event.stopImmediatePropagation();
  inspectPinned = true;
  showInspectOverlay(target);
  document.getElementById('inspect-pin-status').textContent = 'Pinned · Esc để bỏ ghim';
}, true);

document.addEventListener('keydown', (event) => {
  if (event.key !== 'Escape' || !inspectEnabled) return;
  resetInspectSelection();
});
window.addEventListener('resize', () => { if (inspectEnabled && inspectTarget) showInspectOverlay(inspectTarget); });
document.getElementById('app-screen')?.addEventListener('scroll', () => { if (inspectEnabled && inspectTarget) showInspectOverlay(inspectTarget); }, true);



document.addEventListener("click", (event) => {
  const screenButton = event.target.closest("[data-screen]");
  if (screenButton) return navigate(screenButton.dataset.screen);

  const stateButton = event.target.closest("[data-state]");
  if (stateButton) {
    stateByScreen[activeScreenId] = stateButton.dataset.state;
    syncReviewUrl();
    return render();
  }

  const viewportButton = event.target.closest("[data-viewport]");
  if (viewportButton) {
    viewport = viewportButton.dataset.viewport;
    syncReviewUrl();
    document.querySelectorAll(".viewport-button").forEach((button) => button.classList.toggle("is-active", button === viewportButton));
    document.getElementById("device-preview").className = `device-preview is-${viewport}`;
    // Màn có bố cục riêng theo khung (T7-HF1) dựng lại sau khi đổi khung; BJ đăng ký móc chuẩn hoá trạng thái trước đó.
    onViewportChange.forEach((hook) => hook(viewport));
    renderAppScreen();
    fitReviewDeviceToViewport();
    return;
  }
});


document.getElementById("device-preview").className = `device-preview is-${viewport}`;
document.querySelectorAll(".viewport-button").forEach((button) => button.classList.toggle("is-active", button.dataset.viewport === viewport));
syncReviewUrl();


const flowSelectorEl=document.getElementById("flow-selector");
flowSelectorEl?.addEventListener("change",(e)=>{activeFlowId=e.target.value; const f=activeFlow(); activeScreenId=f.screens[0]; syncReviewUrl(); render();});


function fitReviewDeviceToViewport() {
  const device = document.getElementById("device-preview");
  const canvas = document.querySelector(".stage-canvas");
  if (!device || !canvas) return;
  if (window.innerWidth <= 840) {
    device.style.setProperty("--vet45-review-scale", "1");
    return;
  }
  const canvasRect = canvas.getBoundingClientRect();
  const canvasStyle = getComputedStyle(canvas);
  const padTop = parseFloat(canvasStyle.paddingTop) || 0;
  const padLeft = parseFloat(canvasStyle.paddingLeft) || 0;
  const padRight = parseFloat(canvasStyle.paddingRight) || 0;
  const deviceTop = canvasRect.top + padTop;
  const availableHeight = Math.max(360, window.innerHeight - deviceTop - 8);
  const availableWidth = Math.max(240, canvas.clientWidth - padLeft - padRight);
  const isWeb = device.classList.contains("is-web");
  const scale = isWeb
    ? Math.min(1, availableHeight / 802, availableWidth / 1282)
    : Math.min(1, availableHeight / 890, availableWidth / 418);
  device.style.setProperty("--vet45-review-scale", String(scale));
}
window.addEventListener("resize", fitReviewDeviceToViewport);
requestAnimationFrame(fitReviewDeviceToViewport);


window.__VET45_PROTOTYPE__ = {
  productKind: "app",
  version: "5.26.0",
  defaultViewport: { width: 402, height: 874 },
  offline: true,
  uiFlows: flowCatalog.map((f) => f.id),
  screens: screens.map((s) => s.id),
  roles: [...new Set(screens.flatMap((s) => s.actors || []))],
  states: [...new Set(screens.flatMap((s) => s.states || []))],
  scenarios: ["canonical", "document-receipt", "quick-receipt", "source-waiting", "stale-recovery", "partial-handover", "permission-denied"],
  devicePresets: [{ id: "iphone-402", kind: "mobile", width: 402, height: 874 }, { id: "web-1280", kind: "web", width: 1280, height: 800 }],
  inspect: { enabled: true, selectable: true }
};
if (initialParams.get("inspect") === "1") toggleInspect(true);
