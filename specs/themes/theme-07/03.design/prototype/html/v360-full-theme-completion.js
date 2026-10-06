/* VET45 Theme 7 v3.6.0 — full-theme completion & UX QA correction
 * Parent: v3.5.1
 * Scope: supporting capability CAP-01, active-session cancellation, representative-state coherence,
 * feedback/toast semantics, dead-end exits, and final UX simplification.
 * Figma is Design System + mature cross-theme reference only; Theme 7 design authority is this HTML harness.
 */
(() => {
  const VERSION = "3.6.0";
  const e = (v) => (typeof esc === "function" ? esc(v) : String(v ?? ""));
  const ea = (v) => (typeof escapeAttribute === "function" ? escapeAttribute(v) : String(v ?? "").replace(/"/g,"&quot;"));
  const nb = (v) => String(v ?? "").trim().length > 0;
  const n = (v) => Number(v ?? 0);

  // -----------------------------------------------------------------------
  // Full-theme scope: supporting capability is a first-class prototype flow.
  // -----------------------------------------------------------------------
  if (typeof FIGMA_MIGRATED_FLOWS !== "undefined") FIGMA_MIGRATED_FLOWS.add("CAP-01");
  if (typeof FIGMA_TEMPLATE_BY_FLOW_SCREEN !== "undefined") {
    FIGMA_TEMPLATE_BY_FLOW_SCREEN["CAP-01"] = {
      "SCR-062":"Mobile / Form",
      "SCR-063":"Mobile / Form",
      "SCR-064":"Mobile / Detail",
      "SCR-065":"Mobile / Detail"
    };
  }
  if (typeof FLOW_GROUPS !== "undefined" && !FLOW_GROUPS.some(g=>g.id==="supporting")) {
    FLOW_GROUPS.push({id:"supporting",label:"Supporting capability",bjs:["CAP-01"]});
  }

  // Inspector labels are review metadata only, never Product UI.
  const oldRenderInspector = typeof renderInspector === "function" ? renderInspector : null;
  if (oldRenderInspector) {
    renderInspector = function(){
      oldRenderInspector();
      const trace=document.getElementById("traceability");
      if(activeFlowId==="CAP-01" && trace){
        const rows=[...trace.querySelectorAll(".trace-row")];
        const figma=rows.find(r=>r.firstElementChild?.textContent?.trim()==="Figma DS");
        if(figma?.lastElementChild) figma.lastElementChild.textContent="v3.6.0 · Figma DS primitives · HTML Theme 7 design";
      }
    };
  }

  // -----------------------------------------------------------------------
  // CAP-01 — Inventory / near-expiry policy supporting capability.
  // Entry and return location are prototype integration fallbacks, not a
  // production navigation contract while BG-006 remains unresolved.
  // -----------------------------------------------------------------------
  let capPolicyKind="STOCK";
  let capThreshold="50";
  let capTarget="80";
  let capStockSource="PRODUCT_OVERRIDE";
  let capNearExpiryDays="90";
  let capNearExpiryAction="WARN";
  let capNearExpirySource="TENANT_DEFAULT";
  let capPolicyRevision=5;
  let capLastResult=null;
  let capReturnFlow="UIF-01";
  let capReturnScreen="SCR-001";

  function capNumberField(label,value,attr,hint="",disabled=false){
    return `<div class="form-field" data-ds-component="VNumberField" data-ds-prop-label="${ea(label)}"><label>${e(label)}</label><div class="input-shell"><input inputmode="numeric" type="number" min="0" value="${ea(value)}" ${attr} ${disabled?"disabled":""}></div>${hint?`<small class="helper-text">${e(hint)}</small>`:""}</div>`;
  }
  function capSelect(label,value,attr,options,disabled=false){
    return `<label class="form-field v360-select-field" data-ds-component="VSelect"><span>${e(label)}</span><div class="select-shell"><select ${attr} ${disabled?"disabled":""}>${options.map(([v,l])=>`<option value="${ea(v)}" ${v===value?"selected":""}>${e(l)}</option>`).join("")}</select></div></label>`;
  }
  function capExit(){
    activeFlowId=capReturnFlow;
    activeScreenId=capReturnScreen;
    if(stateByScreen[activeScreenId]==null){ const s=screens.find(x=>x.id===activeScreenId); stateByScreen[activeScreenId]=s?.defaultState||s?.states?.[0]||"READY"; }
    syncReviewUrl(); render();
  }
  function capFormNotice(state){
    if(state==="VALIDATION_ERROR") return vBanner("error","Chưa thể tiếp tục","Kiểm tra lại các giá trị được nhập trước khi rà soát.");
    if(state==="CONFLICT") return vBanner("warning","Chính sách vừa được cập nhật","Tải lại giá trị hiện hành trước khi lưu thay đổi.");
    if(state==="LOCKED") return vBanner("warning","Đang ở chế độ chỉ xem","Chính sách đang được cập nhật ở nơi khác. Bạn có thể xem nhưng chưa thể lưu.");
    return "";
  }
  function capRender062(state){
    if(state==="PERMISSION_DENIED") return appShell({title:"Chính sách tồn",body:deniedBody(),centered:true,backAction:"v360-cap-exit"});
    const locked=state==="LOCKED";
    const invalid=n(capThreshold)<0||n(capTarget)<n(capThreshold);
    const body=`${capFormNotice(state)}${ds24InfoGroup("Phạm vi",`${ds24InfoRow("Áp dụng","Tồn kho và cảnh báo tồn thấp")}${ds24InfoRow("Tác động sổ kho","Không")}`,"v360-policy-context")}
      <section class="v360-form-section" data-composed-from="VNumberField,VSelect">
        ${capNumberField("Ngưỡng cảnh báo",capThreshold,'data-v360-cap-threshold','Cảnh báo khi tồn khả dụng xuống dưới mức này.',locked)}
        ${capNumberField("Mức tồn mục tiêu",capTarget,'data-v360-cap-target','Phải lớn hơn hoặc bằng ngưỡng cảnh báo.',locked)}
        ${capSelect("Nguồn áp dụng",capStockSource,'data-v360-cap-stock-source',[["PRODUCT_OVERRIDE","Ghi đè theo sản phẩm"],["TENANT_DEFAULT","Mặc định tổ chức"]],locked)}
      </section>`;
    const actions=locked?primaryFooter("Đóng",'data-v360-action="cap-exit"'):`<footer class="app-actions figma-sticky-footer"><button class="button button--primary" type="button" data-v360-action="cap-review-stock" data-ds-component="VButton" ${invalid?'disabled':''}>Rà soát thay đổi</button></footer>`;
    return appShell({title:"Chính sách tồn",body,actions,backAction:"v360-cap-exit"});
  }
  function capRender063(state){
    if(state==="PERMISSION_DENIED") return appShell({title:"Hàng cận hạn",body:deniedBody(),centered:true,backAction:"v360-cap-exit"});
    const locked=state==="LOCKED";
    const invalid=n(capNearExpiryDays)<=0;
    const body=`${capFormNotice(state)}${ds24InfoGroup("Phạm vi",`${ds24InfoRow("Áp dụng","Cảnh báo hàng cận hạn")}${ds24InfoRow("Tác động sổ kho","Không")}`,"v360-policy-context")}
      <section class="v360-form-section" data-composed-from="VNumberField,VSelect">
        ${capNumberField("Số ngày cận hạn",capNearExpiryDays,'data-v360-cap-expiry-days','Tính từ ngày hiện tại đến hạn dùng.',locked)}
        ${capSelect("Hành động",capNearExpiryAction,'data-v360-cap-expiry-action',[["WARN","Cảnh báo"],["BLOCK_SALE","Chặn bán"]],locked)}
        ${capSelect("Nguồn áp dụng",capNearExpirySource,'data-v360-cap-expiry-source',[["TENANT_DEFAULT","Mặc định tổ chức"],["PRODUCT_OVERRIDE","Ghi đè theo sản phẩm"]],locked)}
      </section>`;
    const actions=locked?primaryFooter("Đóng",'data-v360-action="cap-exit"'):`<footer class="app-actions figma-sticky-footer"><button class="button button--primary" type="button" data-v360-action="cap-review-expiry" data-ds-component="VButton" ${invalid?'disabled':''}>Rà soát thay đổi</button></footer>`;
    return appShell({title:"Hàng cận hạn",body,actions,backAction:"v360-cap-exit"});
  }
  function capRender064(state){
    if(state==="PERMISSION_DENIED") return appShell({title:"Rà soát chính sách",body:deniedBody(),centered:true,backAction:"v360-cap-edit"});
    if(state==="VALIDATION_ERROR") return appShell({title:"Rà soát chính sách",body:vBanner("error","Chính sách chưa hợp lệ","Quay lại cấu hình và kiểm tra các giá trị."),actions:primaryFooter("Quay lại chỉnh sửa",'data-v360-action="cap-edit"'),backAction:"v360-cap-edit"});
    const sourceLabel=(capPolicyKind==="STOCK"?capStockSource:capNearExpirySource)==="PRODUCT_OVERRIDE"?"Ghi đè theo sản phẩm":"Mặc định tổ chức";
    const policyRows=capPolicyKind==="STOCK"
      ? `${ds24KeyValueRow("Ngưỡng cảnh báo",capThreshold,true)}${ds24KeyValueRow("Mức tồn mục tiêu",capTarget,true)}${ds24InfoRow("Nguồn áp dụng",sourceLabel)}`
      : `${ds24KeyValueRow("Cận hạn",`${capNearExpiryDays} ngày`,true)}${ds24InfoRow("Hành động",capNearExpiryAction==="WARN"?"Cảnh báo":"Chặn bán")}${ds24InfoRow("Nguồn áp dụng",sourceLabel)}`;
    const pending=state==="APPROVAL_REQUIRED";
    const body=`${pending?vBanner("warning","Cần người có quyền xác nhận","Bạn không thể tự lưu thay đổi chính sách này."):""}${ds24InfoGroup(capPolicyKind==="STOCK"?"Chính sách tồn":"Chính sách cận hạn",policyRows,"v360-policy-review")}${ds24InfoGroup("Tác động",`${ds24InfoRow("Sổ kho","Không thay đổi")}${ds24InfoRow("Chỉ báo và khả dụng","Được tính lại theo chính sách mới")}`,"v360-policy-impact")}`;
    const actions=pending?primaryFooter("Về cấu hình",'data-v360-action="cap-edit"'):`<footer class="app-actions figma-sticky-footer v360-dual-actions"><button class="button button--secondary" type="button" data-v360-action="cap-edit" data-ds-component="VButton">Chỉnh sửa</button><button class="button button--primary" type="button" data-v360-action="cap-save" data-ds-component="VButton">Lưu chính sách</button></footer>`;
    return appShell({title:"Rà soát chính sách",body,actions,backAction:"v360-cap-edit"});
  }
  function capRender065(state){
    if(state==="PERMISSION_DENIED") return appShell({title:"Kết quả cập nhật",body:deniedBody(),centered:true,back:false,actions:primaryFooter("Đóng",'data-v360-action="cap-exit"')});
    if(state==="UNKNOWN") return appShell({title:"Kết quả cập nhật",body:ds24Result("Đang xác minh kết quả","Không lưu lại thay đổi. Hệ thống đang xác minh đúng lần cập nhật này.",[["Chính sách",capPolicyKind==="STOCK"?"Tồn kho":"Cận hạn"],["Tác động sổ kho","Chưa kết luận"]],"warning"),centered:true,back:false,actions:primaryFooter("Đóng",'data-v360-action="cap-exit"')});
    if(state==="REJECTED_EXECUTION") return appShell({title:"Kết quả cập nhật",body:ds24Result("Chưa cập nhật chính sách","Không có chính sách mới được áp dụng.",[["Tác động sổ kho","Không"],["Trạng thái","Giữ chính sách hiện hành"]],"warning"),centered:true,back:false,actions:primaryFooter("Về cấu hình",'data-v360-action="cap-edit"')});
    const r=capLastResult||{revision:capPolicyRevision+1,kind:capPolicyKind,lowStock:12};
    return appShell({title:"Kết quả cập nhật",body:ds24Result("Đã cập nhật chính sách","Chỉ báo liên quan sẽ dùng chính sách mới; không tạo biến động tồn kho.",[["Chính sách",r.kind==="STOCK"?"Tồn kho":"Cận hạn"],["Lần cập nhật",`Lần ${r.revision}`],["Tác động sổ kho","Không"],["Chỉ báo tồn thấp",`${r.lowStock} sản phẩm`]]),centered:true,back:false,actions:primaryFooter("Đóng",'data-v360-action="cap-exit"')});
  }
  renderers["SCR-062"]=capRender062;
  renderers["SCR-063"]=capRender063;
  renderers["SCR-064"]=capRender064;
  renderers["SCR-065"]=capRender065;

  // -----------------------------------------------------------------------
  // BJ08 cancellation: destructive action belongs inside an opened session,
  // never on the browse list.
  // -----------------------------------------------------------------------
  function injectSessionCancel(html){
    if(!html || html.includes('data-ic08-action="cancel-open"')) return html;
    const button=`<button class="button button--secondary v360-session-cancel" type="button" data-ic08-action="cancel-open" data-action-contract="ACT-09-CANCEL" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.secondary" data-ds-prop-tone="VComponentTone.danger">Hủy phiên</button>`;
    if(html.includes('</footer>')) return html.replace('</footer>',`${button}</footer>`);
    return html;
  }
  const base044=renderers["SCR-044"];
  renderers["SCR-044"]=function(state){
    const html=base044(state);
    if(activeFlowId!=="UIF-08" || !["BLIND_COUNT","READY","VALIDATION_ERROR"].includes(state)) return html;
    return injectSessionCancel(html);
  };
  const base045=renderers["SCR-045"];
  renderers["SCR-045"]=function(state){
    const html=base045(state);
    if(activeFlowId!=="UIF-08" || !["RECOUNT_REQUIRED","READY","VALIDATION_ERROR","EVIDENCE_REQUIRED","PRICE_BASIS_REQUIRED"].includes(state)) return html;
    return injectSessionCancel(html);
  };

  // -----------------------------------------------------------------------
  // Representative-state coherence. These seeds are only for direct Inspector
  // entry to READY review screens; normal user transitions already populate
  // the same prerequisites and are never overwritten.
  // -----------------------------------------------------------------------
  function v360SeedBj02DocumentLines(forceApproval=false){
    flowMode="document"; selectedDocumentId="PN-260816-04";
    if(!bj02Lines.length) bj02Lines=createDocumentReceiptLines(selectedDocumentId);
    bj02Lines.forEach((line,idx)=>{
      const expected=Math.max(1,Number(line.remainingReceivableQty)||1);
      const received=expected+((forceApproval&&idx===0)?1:0);
      line.status="COMPLETED";
      line.accepted=received; line.quarantine=0; line.damaged=0; line.rejected=0; line.totalReceived=received;
      if(line.trackingPolicy==="LOT"){
        line.lots=[{id:`V360-L${idx+1}`,code:idx===0?"DH2507":"AM2507",expiry:line.expiryRequired?(idx===0?"30/11/2026":"31/12/2027"):"",manufactureDate:"",accepted:received,totalReceived:received,quarantine:0,damaged:0,rejected:0}];
      }
    });
  }
  function v360Bj02HasExplicitDraftData(){
    return Array.isArray(bj02Lines) && bj02Lines.some(line=>{
      if(!line) return false;
      if(["COMPLETED","NOT_RECEIVED"].includes(line.status)) return true;
      const direct=[line.accepted,line.quarantine,line.damaged,line.rejected,line.totalReceived].some(v=>Number(v||0)>0);
      const lots=Array.isArray(line.lots) && line.lots.some(l=>[l.accepted,l.quarantine,l.damaged,l.rejected,l.totalReceived].some(v=>Number(v||0)>0) || String(l.code||"").trim());
      return direct || lots;
    });
  }
  function ensureBj02ReviewFixture(){
    if(activeFlowId!=="UIF-02") return;
    const st=stateByScreen[activeScreenId];
    if(activeScreenId==="SCR-084" && st==="READY" && !lineEditorDraft){
      if(!bj02Lines.length) v360SeedBj02DocumentLines(false);
      const line=bj02Lines[0];
      activeReceiptLineId=line?.id||null;
      lineEditorDraft=line?cloneBj02(line):null;
      activeLotDraftId=lineEditorDraft?.lots?.[0]?.id||null;
      lineEditorDirty=false; lineEditorReadOnly=false; lineProductMenuOpen=false;
      lineClassificationExpanded=false; lotClassificationExpanded=false; lotManufactureExpanded=Boolean(lineEditorDraft?.lots?.[0]?.manufactureDate);
      return;
    }
    if(activeScreenId==="SCR-010" && st==="READY"){
      // Direct Inspector entry needs a representative fixture, but an explicit
      // in-progress/user-prepared receipt must never be overwritten by review seeding.
      if(!bj02Lines.length || (!allReceiptLinesHandled() && !v360Bj02HasExplicitDraftData())) v360SeedBj02DocumentLines(false);
      return;
    }
    if(activeScreenId==="SCR-011" && ["READY","APPROVAL_REQUIRED","APPROVAL_REVIEW"].includes(st)){
      if(!bj02Lines.length || !allReceiptLinesHandled() || !bj02RequiresApproval()) v360SeedBj02DocumentLines(true);
      return;
    }
    if(activeScreenId==="SCR-012" && ["COMPLETED","VALUATION_PENDING_RESULT"].includes(st)){
      if(!bj02Lines.length || !allReceiptLinesHandled()) v360SeedBj02DocumentLines(false);
    }
  }
  function ensureVal03ReviewFixture(){
    if(activeFlowId!=="UIF-03"||activeScreenId!=="SCR-017"||stateByScreen[activeScreenId]!=="READY") return;
    if(val03SelectedSlices().length>0 && val03ScopeReady()) { if(val03ReviewSourceVersion==null) val03ReviewSourceVersion=val03Current().sourceVersion; return; }
    const r=val03Current();
    r.groups.forEach(g=>g.slices.forEach(s=>{s.selected=false;}));
    const g=r.groups.find(x=>x.id==="VAL03-G1")||r.groups.find(x=>val03EvidenceState(x)==="READY");
    const s=g?.slices.find(x=>x.pendingQty>0);
    if(g&&s){s.selected=true;s.selectedQty=s.pendingQty;if(!g.selectedSource)g.selectedSource=g.sources[0]?.id||"";val03ReviewSourceVersion=r.sourceVersion;}
  }
  function ensureVal03ResultFixture(){
    if(activeFlowId!=="UIF-03"||activeScreenId!=="SCR-019"||stateByScreen[activeScreenId]!=="COMPLETED"||val03LastResult) return;
    const r=val03Current();
    r.groups.forEach(g=>g.slices.forEach(sl=>{sl.selected=false;}));
    const g=r.groups.find(x=>x.id==="VAL03-G1")||r.groups.find(x=>val03EvidenceState(x)==="READY");
    const sl=g?.slices.find(x=>x.pendingQty>0);
    if(g&&sl){sl.selected=true;sl.selectedQty=sl.pendingQty;if(!g.selectedSource)g.selectedSource=g.sources[0]?.id||"";val03ReviewSourceVersion=r.sourceVersion;val03Commit();}
  }
  // Direct Inspector entry to the shared SCR-041 result must show a coherent
  // completed disposal rather than a zero-value artifact. Normal flow results
  // delegate to v3.5.0 and preserve the actual completed quantity.
  const v360Render041Base=renderers["SCR-041"];
  renderers["SCR-041"]=function(state){
    if(activeFlowId==="UIF-10"&&state==="COMPLETED"){
      const q=window.__VET45_V350__?.getIC10?.()||{};
      if(!(Number(q.completedQty)>0||Number(q.approvedQty)>0)) return appShell({title:"Kết quả tiêu hủy",body:ioResult("Đã ghi nhận tiêu hủy","Tồn vật lý và giá trị đã giảm theo đúng số lượng thực tế được xác nhận.",[["Yêu cầu","TH-0709-04"],["Đã tiêu hủy","6 hộp"],["Tồn vật lý còn lại","0 hộp"]]),actions:primaryFooter("Về hàng có thể xử lý",'data-ic10-action="to-list"'),centered:true,back:false});
    }
    return v360Render041Base(state);
  };
  function ensureIo07ReviewFixture(){
    if(activeFlowId!=="UIF-07"||activeScreenId!=="SCR-039"||stateByScreen[activeScreenId]!=="READY") return;
    const req=io07Current();
    if(!io07AllVerified(req)){io07Allocations(req).forEach(({allocation})=>{allocation.verified=true;allocation.physicalMismatch=false;allocation.affectedByChange=false;});}
    req.reviewSourceVersion=req.sourceVersion;
  }
  function ensureVal13ReviewFixture(){
    if(activeFlowId!=="UIF-13"||activeScreenId!=="SCR-088"||stateByScreen[activeScreenId]!=="READY") return;
    const t=val13Current();
    t.targets.forEach(x=>x.selected=true);
    if(!t.selectedMethod) t.selectedMethod=t.allowedMethods?.[0]?.id||"";
    val13ReviewSourceVersion=t.sourceVersion;
    val13PreviewHash=val13PreviewHashOf(t);
  }
  function ensureVal14ReviewFixture(){
    if(activeFlowId!=="UIF-14"||activeScreenId!=="SCR-076"||stateByScreen[activeScreenId]!=="READY") return;
    let r=val14Current();
    if(r.status!=="READY_FOR_REVIEW"){
      const ready=val14Runs.find(x=>x.status==="READY_FOR_REVIEW");
      if(ready){val14SelectedRunId=ready.id;r=ready;}
    }
    if(val14PublishReviewVersion==null) val14PublishReviewVersion=r.runInputHash||String(r.inputVersion);
  }
  function ensureRepresentativeFixture(){
    try{ensureBj02ReviewFixture();ensureVal03ReviewFixture();ensureVal03ResultFixture();ensureIo07ReviewFixture();ensureVal13ReviewFixture();ensureVal14ReviewFixture();}catch(err){console.error("v360 fixture",err);}
  }
  const baseRenderAppScreen=renderAppScreen;
  const v360TransientStates=new Set(["LOADING","PROCESSING","CALCULATING","REBUILDING","PREPARING","EXPORT_RUNNING"]);
  const v360RootScreens=new Set(["SCR-001","SCR-006","SCR-014","SCR-025","SCR-030","SCR-036","SCR-042","SCR-048","SCR-054","SCR-066","SCR-072","SCR-078","SCR-085","SCR-062","SCR-063"]);
  const v360ExitTargets={
    "SCR-011":"SCR-006","SCR-012":"SCR-006","SCR-013":"SCR-006",
    "SCR-019":"SCR-014","SCR-029":"SCR-025","SCR-034":"SCR-030","SCR-035":"SCR-030",
    "SCR-038":"SCR-036","SCR-040":"SCR-036","SCR-051":"SCR-048",
    "SCR-041":"SCR-036","SCR-046":"SCR-042","SCR-047":"SCR-042",
    "SCR-052":"SCR-048","SCR-053":"SCR-048","SCR-058":"SCR-055","SCR-059":"SCR-055",
    "SCR-070":"SCR-066","SCR-071":"SCR-066","SCR-077":"SCR-072","SCR-083":"SCR-078","SCR-089":"SCR-085"
  };
  function ensureStableExitAffordance(){
    const state=stateByScreen[activeScreenId];
    if(v360TransientStates.has(state)||v360RootScreens.has(activeScreenId))return;
    const root=document.getElementById("app-screen");if(!root)return;
    const interactive=root.querySelector('button:not([disabled]),a[href],[data-back],[data-action]:not([data-action=""]),[data-generic-next],[data-generic-action]');
    if(interactive)return;
    const target=v360ExitTargets[activeScreenId];if(!target)return;
    const label=activeScreenId==="SCR-058"||activeScreenId==="SCR-059"?"Về báo cáo":"Về danh sách";
    root.querySelector('.v-page-scaffold')?.insertAdjacentHTML('beforeend',primaryFooter(label,`data-v360-action="fallback-exit" data-v360-target="${target}"`));
  }
  renderAppScreen=function(){ensureRepresentativeFixture();const out=baseRenderAppScreen();ensureStableExitAffordance();return out;};

  // -----------------------------------------------------------------------
  // Product feedback: mutation success is acknowledged when the user remains
  // in the same work context or returns to a work list. Dedicated result
  // screens keep sole ownership of operation-level success feedback.
  // -----------------------------------------------------------------------
  const toastRules=[
    ['[data-bj01-refresh]',"Đã cập nhật tồn kho","success"],
    ['[data-bj02-action="save-line"]',"Đã cập nhật hàng thực nhận","success"],
    ['[data-io05-action="confirm-lot-override"]',"Đã cập nhật lô lấy hàng","success"],
    ['[data-io06-action="save-return-line"]',"Đã cập nhật hàng khách trả","success"],
    ['[data-io06-action="confirm-classification"]',"Đã lưu phân loại hàng trả","success"],
    ['[data-io07-action="confirm-allocation"]',"Đã xác nhận phần hàng","success"],
    ['[data-v350-action="ic09-submit"]',"Đã gửi yêu cầu thay đổi tình trạng","success"],
    ['[data-v350-action="ic10-submit"]',"Đã gửi yêu cầu tiêu hủy","success"],
    ['[data-cr11-action="submit-correction"]',"Đã gửi yêu cầu sửa sai","success"],
    ['[data-cf12-action="send-approval"]',"Đã gửi số dư đầu kỳ chờ duyệt","success"]
  ];
  document.addEventListener("click",(event)=>{
    for(const [selector,msg,tone] of toastRules){
      const hit=event.target.closest(selector);if(!hit||hit.disabled)continue;
      window.setTimeout(()=>{if(document.getElementById("app-screen"))showToast(msg,tone);},30);
      break;
    }
  },true);

  // -----------------------------------------------------------------------
  // CAP-01 interaction and stable exit paths.
  // -----------------------------------------------------------------------
  document.addEventListener("input",(event)=>{
    if(activeFlowId==="UIF-08" && event.target.matches("[data-ic08-cancel-reason]")){
      queueMicrotask(()=>{const b=document.querySelector('[data-v350-action="ic08-confirm-cancel"]');if(b)b.disabled=!String(event.target.value||"").trim();});
    }
  },true);
  document.addEventListener("input",(event)=>{
    if(activeFlowId!=="CAP-01")return;
    if(event.target.matches("[data-v360-cap-threshold]")){capThreshold=event.target.value;return;}
    if(event.target.matches("[data-v360-cap-target]")){capTarget=event.target.value;return;}
    if(event.target.matches("[data-v360-cap-expiry-days]")){capNearExpiryDays=event.target.value;return;}
  },true);
  document.addEventListener("change",(event)=>{
    if(activeFlowId!=="CAP-01")return;
    if(event.target.matches("[data-v360-cap-stock-source]")){capStockSource=event.target.value;return;}
    if(event.target.matches("[data-v360-cap-expiry-action]")){capNearExpiryAction=event.target.value;return;}
    if(event.target.matches("[data-v360-cap-expiry-source]")){capNearExpirySource=event.target.value;return;}
  },true);
  document.addEventListener("click",(event)=>{
    const action=event.target.closest("[data-v360-action]");
    if(!action||action.disabled)return;
    const k=action.dataset.v360Action;
    if(k==="cap-exit"){event.preventDefault();event.stopPropagation();return capExit();}
    if(k==="fallback-exit"){event.preventDefault();event.stopPropagation();const target=action.dataset.v360Target;if(target)return navigate(target);}
    if(activeFlowId!=="CAP-01")return;
    event.preventDefault();event.stopPropagation();
    if(k==="cap-review-stock"){
      if(n(capThreshold)<0||n(capTarget)<n(capThreshold)){stateByScreen["SCR-062"]="VALIDATION_ERROR";return renderAppScreen();}
      capPolicyKind="STOCK";stateByScreen["SCR-064"]="READY";return navigate("SCR-064");
    }
    if(k==="cap-review-expiry"){
      if(n(capNearExpiryDays)<=0){stateByScreen["SCR-063"]="VALIDATION_ERROR";return renderAppScreen();}
      capPolicyKind="EXPIRY";stateByScreen["SCR-064"]="READY";return navigate("SCR-064");
    }
    if(k==="cap-edit"){return navigate(capPolicyKind==="STOCK"?"SCR-062":"SCR-063");}
    if(k==="cap-save"){
      capPolicyRevision+=1;capLastResult={revision:capPolicyRevision,kind:capPolicyKind,lowStock:12};stateByScreen["SCR-065"]="COMPLETED";return navigate("SCR-065");
    }
  },true);
  document.addEventListener("click",(event)=>{
    const x=event.target.closest('[data-action="v360-cap-exit"]');
    if(x){event.preventDefault();event.stopPropagation();return capExit();}
    const edit=event.target.closest('[data-action="v360-cap-edit"]');
    if(edit&&activeFlowId==="CAP-01"){event.preventDefault();event.stopPropagation();return navigate(capPolicyKind==="STOCK"?"SCR-062":"SCR-063");}
  },true);

  // -----------------------------------------------------------------------
  // UX simplification: normal progress/context should not consume banner
  // semantics. Only exact informational banners which merely restate the
  // screen are demoted; exception/warning/error/success banners remain.
  // -----------------------------------------------------------------------
  const normalInfoBannerTitles=new Set([
    "Yêu cầu thay đổi tình trạng",
    "Phê duyệt chưa phải tiêu hủy",
    "Cần quyết định độc lập",
    "Chỉ xử lý dòng có chênh lệch"
  ]);
  function simplifyNormalBanners(){
    if(!["UIF-08","UIF-09","UIF-10","UIF-16","UIF-17"].includes(activeFlowId))return;
    document.querySelectorAll("#app-screen .v-banner--info").forEach(b=>{
      const title=b.querySelector("strong")?.textContent?.trim()||"";
      if(normalInfoBannerTitles.has(title)) b.classList.add("v360-context-banner");
    });
  }
  const prevRender=render;
  render=function(){const out=prevRender();requestAnimationFrame(simplifyNormalBanners);return out;};

  // Version metadata exposed to QA/runtime.
  if(window.__VET45_PROTOTYPE__){
    window.__VET45_PROTOTYPE__.version=VERSION;
    window.__VET45_PROTOTYPE__.uiFlows=flowCatalog.map(f=>f.id);
    window.__VET45_PROTOTYPE__.screens=screens.map(s=>s.id);
    window.__VET45_PROTOTYPE__.scenarios=[...(window.__VET45_PROTOTYPE__.scenarios||[]),"supporting-policy","active-session-cancellation","feedback-semantic"];
  }
  window.__VET45_V360__={
    version:VERSION,
    capState:()=>({capPolicyKind,capThreshold,capTarget,capStockSource,capNearExpiryDays,capNearExpiryAction,capNearExpirySource,capPolicyRevision,capLastResult}),
    setCapReturn(flow="UIF-01",screen="SCR-001"){capReturnFlow=flow;capReturnScreen=screen;},
    ensureRepresentativeFixture,
    capExit
  };

  // Final render after all effective renderers and global QA corrections exist.
  syncReviewUrl();render();
})();
