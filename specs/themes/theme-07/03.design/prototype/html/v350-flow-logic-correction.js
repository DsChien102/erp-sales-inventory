/* VET45 Theme 7 v3.5.0 — full flow/logic correction
 * Parent: v3.4.0
 * Scope: executable state transitions, stale-source guards, UNKNOWN recovery,
 * actor handoff, reporting scope, costing lineage, and UI behavior regressions.
 * UI remains composed from the existing Figma DS components/patterns.
 */
(() => {
  const VERSION = "3.5.0";
  const num = (v) => Number(v ?? 0);
  const nonBlank = (v) => String(v ?? "").trim().length > 0;
  const same = (a,b) => String(a ?? "") === String(b ?? "");
  const escAttr = (v) => (typeof escapeAttribute === "function" ? escapeAttribute(v) : String(v).replace(/"/g,"&quot;"));

  // Reachable states introduced/activated by v3.5.0 must be declared, not only
  // reachable through imperative handlers. This keeps Inspector/state coverage
  // aligned with the executable state machine.
  const v350DeclaredStates = {
    "SCR-040":["VALIDATION_ERROR","SELF_APPROVAL_NOT_ALLOWED"],
    "SCR-046":["APPROVAL_REVIEW"]
  };
  Object.entries(v350DeclaredStates).forEach(([sid,extra])=>{
    const sc=screens.find(x=>x.id===sid);
    if(sc){ sc.states=[...new Set([...(sc.states||[]),...extra])]; }
  });

  // -------------------------------------------------------------------------
  // Entry architecture / actor boundary
  // -------------------------------------------------------------------------
  const v350EntryTargets = {
    "UIF-08": {"assigned-counter":["SCR-044","BLIND_COUNT"], "approver":["SCR-046","APPROVAL_REVIEW"]},
    "UIF-09": {"product-context":["SCR-037","READY"], "approver":["SCR-038","APPROVAL_REVIEW"]},
    "UIF-10": {"product-context":["SCR-037","READY"], "approver":["SCR-040","APPROVAL_REVIEW"], "completion-operator":["SCR-040","COMPLETION"]},
    "UIF-14": {"dirty-scope":["SCR-073","READY"]}
  };
  function v350ApplyEntry(flowId, mode, shouldRender=false) {
    const target = v350EntryTargets[flowId]?.[mode];
    if (!target) return false;
    activeFlowId = flowId;
    activeScreenId = target[0];
    if (stateByScreen[activeScreenId] !== undefined) stateByScreen[activeScreenId] = target[1];
    if (flowId === "UIF-14" && mode === "dirty-scope") {
      const dirty = val14Runs.find(r => r.status === "DIRTY");
      if (dirty) {
        val14SelectedRunId = dirty.id;
        val14SetupKind = dirty.kind;
        val14SetupPeriod = dirty.period;
        val14SetupScope = "Sản phẩm cần tính lại";
        val14SuccessorOf = dirty.id;
      }
    }
    if (shouldRender) { syncReviewUrl(); render(); }
    return true;
  }
  if (!initialParams.get("screen")) v350ApplyEntry(activeFlowId, entryMode, false);
  let v350ActorMode = entryMode;
  const isApproverEntry = () => v350ActorMode === "approver";
  const isCompletionEntry = () => v350ActorMode === "completion-operator";

  // -------------------------------------------------------------------------
  // Common safety / recovery helpers
  // -------------------------------------------------------------------------
  function v350LockSourceForUnknown(flowId) {
    if (flowId === "UIF-05") { const o=io05CurrentOrder(); if(o)o.unknownLocked=true; }
    if (flowId === "UIF-06") { const r=io06CurrentRequest(); if(r){r.unknownLocked=true;r.queue="WAITING";r.status="Đang xác minh kết quả";} }
    if (flowId === "UIF-07") { const r=io07Current(); if(r){r.unknownLocked=true;r.queue="WAITING";r.lifecycle="Đang xác minh kết quả";} }
  }
  function v350RecoveryCase({sourceFlow,operation,scope,title,evidence="INSUFFICIENT",owner="Kiểm soát kho"}) {
    const op = operation || `${sourceFlow}-UNKNOWN`;
    let c = cr17Cases.find(x => x.operation === op && x.sourceFlow === sourceFlow);
    if (!c) {
      c = {
        id:`REC-${sourceFlow.replace("UIF-","")}-${op.replace(/[^A-Za-z0-9]/g,"").slice(-12)}`,
        operation:op,
        title:title || "Cần xác minh kết quả nghiệp vụ",
        scope:scope || "Phạm vi của lần xử lý hiện tại",
        evidence,
        severity:evidence==="INSUFFICIENT"?"Cần chuyên sâu":"Cần xử lý",
        tone:evidence==="INSUFFICIENT"?"warning":"info",
        owner,
        sourceFlow,
        evidenceVersion:1,
        protected:true
      };
      cr17Cases.unshift(c);
    }
    return c;
  }
  function v350HandoffUnknown(meta) {
    v350LockSourceForUnknown(meta.sourceFlow);
    const c=v350RecoveryCase(meta);
    cr17SelectedId=c.id;
    cr17ResolutionMode="";
    stateByScreen["SCR-079"]=c.evidence==="INSUFFICIENT"?"INSUFFICIENT_EVIDENCE":"UNKNOWN_EVIDENCE";
    return crSwitchFlow("UIF-17","SCR-079",stateByScreen["SCR-079"]);
  }
  function v350UnknownResult({title="Kết quả chưa xác định",description="Không gửi lại thao tác. Chuyển đúng lần xử lý này sang xác minh kết quả.",operation,scope,sourceFlow}) {
    const body=ioResult(title,description,[["Nghiệp vụ",operation],["Phạm vi",scope],["Trạng thái","Chưa kết luận"]],"warning");
    const attrs=`data-v350-action="handoff-unknown" data-source-flow="${escAttr(sourceFlow)}" data-operation="${escAttr(operation)}" data-scope="${escAttr(scope)}"`;
    return appShell({title:"Xác minh kết quả",body,actions:primaryFooter("Chuyển sang xác minh",attrs),centered:true,back:false});
  }

  // Source queues must not expose an operation that is still UNKNOWN.
  io05Orders.forEach(o=>{o.sourceVersion ??= 1;o.reviewSourceVersion ??= null;o.unknownLocked ??= false;});
  io06Requests.forEach(r=>{r.reviewSourceVersion ??= null;r.unknownLocked ??= false;});
  io07Requests.forEach(r=>{r.unknownLocked ??= false;});
  io05VisibleOrders = function(){ return io05Orders.filter(o=>!o.closed&&!o.unknownLocked); };
  const v350BaseIO07Active = io07ActiveRequests;
  io07ActiveRequests = function(){ return v350BaseIO07Active().filter(r=>!r.unknownLocked); };

  // Capture source version when entering a review/receipt context.
  const v350Navigate = navigate;
  navigate = function(screenId){
    if(activeFlowId==="UIF-05" && screenId==="SCR-028") io05CurrentOrder().reviewSourceVersion=io05CurrentOrder().sourceVersion;
    if(activeFlowId==="UIF-06" && screenId==="SCR-031") io06CurrentRequest().reviewSourceVersion=io06CurrentRequest().sourceVersion;
    return v350Navigate(screenId);
  };

  // BJ05: commit must revalidate the source version used for review.
  const v350BaseIO05Apply = io05ApplyHandover;
  io05ApplyHandover = function(){
    const o=io05CurrentOrder();
    if(!o || num(o.reviewSourceVersion)!==num(o.sourceVersion)){
      stateByScreen["SCR-028"]="SOURCE_CHANGED";
      if(activeScreenId==="SCR-028") renderAppScreen();
      return null;
    }
    return v350BaseIO05Apply();
  };

  // BJ06: normal return and exception return share the same source snapshot guard.
  const v350BaseIO06ReceiptReady = io06ReceiptReady;
  io06ReceiptReady = function(req=io06CurrentRequest()){
    return num(req.reviewSourceVersion)===num(req.sourceVersion) && v350BaseIO06ReceiptReady(req);
  };

  // -------------------------------------------------------------------------
  // BJ08 — blind count / recount / approval
  // -------------------------------------------------------------------------
  ic08Counts={amox:"",glove:""};
  ic08Recounts={amox:"",glove:""};
  let v350Ic08DiscrepancyIds=[];
  let v350Ic08AdjustedCount=0;
  const v350Ic08Book={amox:20,glove:6};
  const v350Ic08Meta={
    amox:{name:"Amox 500",code:"SP-00128",lot:"L2407-A",uom:"hộp"},
    glove:{name:"Găng tay M",code:"SP-00410",lot:"L2405-M",uom:"hộp"}
  };
  function v350Ic08FirstValid(){return ["amox","glove"].every(id=>nonBlank(ic08Counts[id])&&Number.isFinite(Number(ic08Counts[id]))&&Number(ic08Counts[id])>=0);}
  function v350Ic08Recompute(){v350Ic08DiscrepancyIds=["amox","glove"].filter(id=>num(ic08Counts[id])!==v350Ic08Book[id]);return v350Ic08DiscrepancyIds;}
  function v350Ic08RecountValid(){return v350Ic08DiscrepancyIds.every(id=>nonBlank(ic08Recounts[id])&&Number.isFinite(Number(ic08Recounts[id]))&&Number(ic08Recounts[id])>=0);}
  function v350Ic08Variance(id,value){const d=num(value)-v350Ic08Book[id];return `${d>0?"+":""}${d} ${v350Ic08Meta[id].uom}`;}
  ic08QuantityTrigger = function(label,value,target,unit,disabled=false) {
    const display=nonBlank(value)?String(value):"—";
    return `<div class="ds24-field" data-theme-component="Theme7QuantityEntry" data-composed-from="VText,VNumericKeypadSheet"><span class="vet45-text-style-8">${esc(label)}</span><button type="button" class="ds24-field__control ds24-quantity-trigger" data-ic08-keypad-open="${target}" data-unit="${escAttr(unit)}" ${disabled?'disabled':''}><span class="vet45-text-style-6">${esc(display)}</span><small class="vet45-text-style-11">${esc(unit)}</small></button></div>`;
  };
  ic08ConfirmationSheet = function(){
    if(!ic08ConfirmKind)return "";
    const cfg={
      'open-session':['Mở phiên kiểm kê?','Phạm vi sẽ được khóa theo thời điểm chốt của phiên.','Mở phiên','default',false],
      'submit-first':['Nộp lần đếm đầu?','Sau khi nộp, hệ thống mới hiển thị số sổ và chênh lệch.','Nộp kết quả','default',false],
      'submit-recount':['Gửi kết quả kiểm kê?','Kết quả đếm lại sẽ được chuyển sang công việc duyệt độc lập.','Gửi chờ duyệt','default',false],
      'approve':['Duyệt và điều chỉnh?','Hệ thống chỉ ghi điều chỉnh sau khi kiểm tra lại điều kiện và phạm vi.','Duyệt và điều chỉnh','default',false],
      'request-review':['Yêu cầu xem lại?','Phiên giữ nguyên khóa và quay lại bước đếm lại.','Yêu cầu xem lại','default',true],
      'cancel':['Hủy phiên kiểm kê?','Không tạo điều chỉnh. Lịch sử kiểm đếm được giữ.','Hủy phiên','danger',true]
    }[ic08ConfirmKind]; if(!cfg)return "";
    const [title,desc,action,tone,needsReason]=cfg;
    const val=ic08ConfirmKind==='cancel'?ic08CancelReason:ic08ReviewReason;
    const attr=ic08ConfirmKind==='cancel'?'data-ic08-cancel-reason':'data-ic08-review-reason';
    const reason=needsReason?ds24TextField('Lý do',val,attr,'Lý do được lưu trong lịch sử quản trị.'):'';
    return `<div class="sheet-backdrop ds24-overlay" data-ic08-action="confirm-close"><section class="ds24-confirmation ds24-confirmation--${tone}" data-ds-component="DS v2 / Confirmation Sheet" role="dialog" aria-modal="true" onclick="event.stopPropagation()"><div class="ds24-confirmation__handle"></div><h3 class="vet45-text-style-4">${esc(title)}</h3><p class="vet45-text-style-6">${esc(desc)}</p>${reason}<div class="ds24-confirmation__actions"><button class="ds24-button ds24-button--secondary" type="button" data-ic08-action="confirm-close">Quay lại</button><button class="ds24-button ${tone==='danger'?'ds24-button--danger':'ds24-button--primary'}" type="button" data-v350-action="ic08-confirm-${ic08ConfirmKind}" ${needsReason&&!nonBlank(val)?'disabled':''}>${esc(action)}</button></div></section></div>`;
  };
  function v350Render044(state){
    if(activeFlowId!=="UIF-08") return ac340Base044(state);
    if(!["BLIND_COUNT","READY","VALIDATION_ERROR","LOCK_LOST"].includes(state)) return ac340Base044(state);
    const lost=state==="LOCK_LOST";
    const error=state==="VALIDATION_ERROR"?vBanner("error","Chưa nhập đủ kết quả","Nhập số đếm thực tế cho tất cả dòng trước khi nộp."):"";
    const notice=lost?vBanner("warning","Phiên không còn giữ khóa","Số đã nhập được giữ trên thiết bị. Tải lại trạng thái hiện hành trước khi tiếp tục."):vBanner("info","Đang đếm mù","Chỉ nhập số thực tế. Số theo sổ và chênh lệch chỉ hiển thị sau lần nộp đầu.");
    const groups=["amox","glove"].map(id=>{const m=v350Ic08Meta[id];return ac310CountGroup({id,name:m.name,code:m.code,lot:m.lot,uom:m.uom,value:ic08Counts[id],disabled:lost});});
    if(ic08UnexpectedLine)groups.push(ac310CountGroup({id:"unexpected",name:ic08UnexpectedLine.name,code:"Hàng thực tế bổ sung",lot:ic08UnexpectedLine.lot,uom:ic08UnexpectedLine.uom,value:ic08UnexpectedLine.value,unexpected:true,disabled:lost}));
    const body=`${error}${notice}${ac310InfoSurface("Phiên kiểm kê",[["Mã phiên","KK-0709-03"],["Kho","Kho trung tâm"],["Thời điểm chốt","09/09/2026 · 08:00"]])}<div class="ac310-product-control-list ac340-product-task-list">${groups.join("")}</div>${!lost?`<button class="button button--secondary ac310-inline-button" type="button" data-ic08-action="add-actual-open" data-ds-component="VButton">Thêm hàng thực tế</button>`:""}${ic08Overlays()}`;
    return ac310Return(appShell({title:"Đếm mù",body,actions:lost?primaryFooter("Về phiên kiểm kê",'data-ic08-action="to-list"'):primaryFooter("Nộp kết quả đếm",'data-ic08-action="submit-first"')}));
  }
  function v350Render045(state){
    if(activeFlowId!=="UIF-08")return ac340Base045(state);
    if(!["RECOUNT_REQUIRED","READY","LOCKED","PRICE_BASIS_REQUIRED","EVIDENCE_REQUIRED","VALIDATION_ERROR"].includes(state))return ac340Base045(state);
    if(!v350Ic08DiscrepancyIds.length)v350Ic08Recompute();
    if(!v350Ic08DiscrepancyIds.length) v350Ic08DiscrepancyIds=["amox","glove"]; // direct Inspector fixture only
    const locked=state==="LOCKED",price=state==="PRICE_BASIS_REQUIRED",evidence=state==="EVIDENCE_REQUIRED";
    const notice=locked?vBanner("warning","Phiên đang chỉ đọc","Không thể sửa kết quả đếm trong trạng thái hiện hành."):price?vBanner("error","Chưa đủ căn cứ giá","Dòng thừa chưa có căn cứ giá hợp lệ."):evidence?vBanner("warning","Chưa đủ bằng chứng","Bổ sung bằng chứng cần thiết trước khi gửi duyệt."):state==="VALIDATION_ERROR"?vBanner("error","Kết quả đếm lại chưa hợp lệ","Nhập số lượng đếm lại cho tất cả dòng chênh lệch."):vBanner("info","Chỉ đếm lại dòng có chênh lệch","Số theo sổ đã được hiển thị sau lần đếm đầu.");
    const groups=v350Ic08DiscrepancyIds.map(id=>{const m=v350Ic08Meta[id],first=nonBlank(ic08Counts[id])?num(ic08Counts[id]):(id==="amox"?18:7);return ac310RecountGroup({id,name:m.name,code:m.code,lot:m.lot,uom:m.uom,book:v350Ic08Book[id],first,variance:v350Ic08Variance(id,first),value:ic08Recounts[id],disabled:locked});});
    const evidenceRows=v350Ic08DiscrepancyIds.map(id=>[v350Ic08Meta[id].name,price?"Thiếu căn cứ giá":evidence?"Thiếu bằng chứng":"Đã đủ căn cứ"]);
    const body=`${notice}<div class="ac310-product-control-list ac340-product-task-list">${groups.join("")}</div>${ac310InfoSurface("Căn cứ và bằng chứng",evidenceRows)}${ic08Overlays()}`;
    let actions="";if(!locked)actions=`<footer class="app-actions figma-sticky-footer ac310-footer-stack"><button class="button button--primary" type="button" data-ic08-action="submit-recount" ${price||evidence?'disabled':''}>Gửi chờ duyệt</button>${price||evidence?`<button class="button button--secondary ac310-danger-text" type="button" data-ic08-action="cancel-open">Hủy phiên</button>`:""}</footer>`;
    return ac310Return(appShell({title:"Chênh lệch và đếm lại",body,actions}));
  }
  function v350Render046(state){
    if(activeFlowId!=="UIF-08")return ac340Base046(state);
    if(state==="SELF_APPROVAL_NOT_ALLOWED")return appShell({title:"Duyệt kết quả kiểm kê",body:vBanner("warning","Không thể tự duyệt","Người thực hiện kiểm kê không được duyệt chính kết quả của mình."),back:false});
    if(state==="APPROVAL_ALREADY_DECIDED")return appShell({title:"Duyệt kết quả kiểm kê",body:vBanner("info","Công việc đã có quyết định","Mở kết quả kiểm kê để xem trạng thái hiện hành."),actions:primaryFooter("Xem kết quả",'data-v350-action="ic08-approval-result"'),back:false});
    if(!["READY","APPROVAL_REVIEW"].includes(state))return ac340Base046(state);
    const ids=v350Ic08DiscrepancyIds.length?v350Ic08DiscrepancyIds:["amox","glove"];
    const groups=ids.map(id=>{const m=v350Ic08Meta[id],first=nonBlank(ic08Counts[id])?num(ic08Counts[id]):(id==="amox"?18:7),final=nonBlank(ic08Recounts[id])?num(ic08Recounts[id]):first;return ac340ReviewProduct({name:m.name,code:m.code,meta:`Lô ${m.lot} · ${m.uom}`,variance:v350Ic08Variance(id,final),rows:[["Kết quả cuối",`${final} ${m.uom}`],["Bằng chứng","Đã đủ"]]});}).join("");
    const noDiff=ids.every(id=>{const v=nonBlank(ic08Recounts[id])?num(ic08Recounts[id]):num(ic08Counts[id]||v350Ic08Book[id]);return v===v350Ic08Book[id];});
    const body=`${vBanner("info","Cần quyết định độc lập",noDiff?"Kết quả cuối không còn chênh lệch. Người duyệt xác nhận để hoàn tất phiên.":"Người duyệt chỉ rà soát bằng chứng và quyết định; không sửa số đếm.")}${ac310InfoSurface("Phiên kiểm kê",[["Mã phiên","KK-0709-03"],["Người thực hiện","Nguyễn An"],["Kho","Kho trung tâm"],["Dòng cần quyết định",`${ids.length} dòng`]])}<div class="ac340-review-list">${groups}</div>${ic08Overlays()}`;
    const actions=`<footer class="app-actions figma-sticky-footer ac310-two-actions"><button class="button button--secondary" type="button" data-v350-action="ic08-request-review">Yêu cầu xem lại</button><button class="button button--primary" type="button" data-v350-action="ic08-approve">Duyệt${noDiff?"":" và điều chỉnh"}</button></footer>`;
    return ac310Return(appShell({title:"Duyệt kiểm kê",body,actions,back:false}));
  }
  renderers["SCR-044"]=v350Render044;
  renderers["SCR-045"]=v350Render045;
  renderers["SCR-046"]=v350Render046;
  const v350Render047Base=renderers["SCR-047"];
  renderers["SCR-047"]=function(state){
    if(activeFlowId!=="UIF-08"||state!=="COMPLETED")return v350Render047Base(state);
    const title=v350Ic08AdjustedCount?"Đã hoàn tất kiểm kê":"Đã hoàn tất kiểm kê — không cần điều chỉnh";
    const desc=v350Ic08AdjustedCount?"Điều chỉnh tồn kho đã được ghi theo quyết định duyệt và phạm vi đã mở khóa.":"Kết quả kiểm đếm khớp số sổ. Phiên hoàn tất mà không tạo bút toán điều chỉnh.";
    const rows=[["Phiên","KK-0709-03"],["Điều chỉnh",v350Ic08AdjustedCount?"ADJ-0709-03":"Không tạo"],["Số dòng điều chỉnh",String(v350Ic08AdjustedCount)],["Khóa phạm vi","Đã mở"]];
    return appShell({title:"Kết quả kiểm kê",body:ds24Result(title,desc,rows),actions:primaryFooter("Về kiểm kê",'data-ic08-action="to-list"'),centered:true,back:false});
  };

  // -------------------------------------------------------------------------
  // BJ09 — state-change reason must be an actual request field.
  // -------------------------------------------------------------------------
  let v350Ic09Reason="";
  let v350Ic09Request=null;
  const v350Render038Base=renderers["SCR-038"];
  renderers["SCR-038"]=function(state){
    if(activeFlowId!=="UIF-09")return v350Render038Base(state);
    const x=ic09Current();const req=v350Ic09Request;const requestDest=req?.destination||ic09Destination;const requestReason=req?.reason||v350Ic09Reason;const dest=requestDest==="QUARANTINE"?"Cách ly":requestDest==="DAMAGED"?"Hỏng":requestDest==="DEMO"?"Dùng thử":"Bán được";
    if(state==="SELF_APPROVAL_NOT_ALLOWED")return appShell({title:"Duyệt thay đổi tình trạng",body:vBanner("warning","Không thể tự duyệt","Người lập yêu cầu không được tự duyệt yêu cầu này."),back:false});
    if(state==="APPROVAL_REVIEW"){
      const body=`${vBanner("info","Yêu cầu thay đổi tình trạng","Kiểm tra lý do và phạm vi trước khi quyết định.")}${icHeaderRows([["Sản phẩm",x.name,true],["Lô",x.lot],["Từ",x.label],["Sang",dest],["Số lượng",`${x.qty} ${x.uom}`],["Lý do",requestReason||"—"]])}`;
      return appShell({title:"Duyệt thay đổi tình trạng",body,actions:`<div class="ic-action-stack">${icSecondary("Từ chối",'data-v350-action="ic09-reject"','danger')}${primaryFooter("Duyệt",'data-v350-action="ic09-approve"')}</div>`,back:false});
    }
    if(state==="PENDING_APPROVAL")return appShell({title:"Chuyển tình trạng hàng",body:`${vBanner("info","Đã gửi chờ duyệt","Người duyệt nhận một công việc riêng; hàng chưa đổi tình trạng.")}${icHeaderRows([["Sản phẩm",x.name,true],["Từ",x.label],["Sang",dest],["Lý do",requestReason||"—"]])}`,back:false});
    if(["PERMISSION_DENIED","LOCKED"].includes(state))return v350Render038Base(state);
    const error=state==="VALIDATION_ERROR"?vBanner("error","Chưa đủ thông tin","Chọn tình trạng đích và nhập lý do."):"";
    const choices=[icChoice("QUARANTINE","Cách ly","Tạm thời không bán",ic09Destination==="QUARANTINE"),icChoice("DAMAGED","Hỏng","Không còn đủ điều kiện bán",ic09Destination==="DAMAGED"),icChoice("DEMO","Dùng thử","Chuyển sang mục đích dùng thử",ic09Destination==="DEMO")];if(x.state!=="SELLABLE")choices.push(icChoice("SELLABLE","Bán được","Chỉ khi hàng đủ điều kiện trở lại bán",ic09Destination==="SELLABLE"));
    const body=`${error}${icHeaderRows([["Sản phẩm",x.name,true],["Lô",x.lot],["Hiện tại",x.label],["Số lượng",`${x.qty} ${x.uom}`]])}${ioSectionTitle("Tình trạng mới")}<div class="choice-list">${choices.join("")}</div>${icTextarea("Lý do",v350Ic09Reason,'data-v350-ic09-reason','Nhập lý do')}`;
    return appShell({title:"Chuyển tình trạng hàng",body,actions:primaryFooter("Gửi xử lý",'data-v350-action="ic09-submit"')});
  };

  // -------------------------------------------------------------------------
  // BJ10 — disposal request/approval/completion use one bound model.
  // -------------------------------------------------------------------------
  let v350Ic10RequestQty="",v350Ic10Reason="",v350Ic10Evidence="",v350Ic10ApprovedQty=0,v350Ic10ActualQty="",v350Ic10Proof="",v350Ic10CompletedQty=0;
  function v350Ic10RequestValid(){const q=num(v350Ic10RequestQty);return q>0&&q<=6&&nonBlank(v350Ic10Reason)&&nonBlank(v350Ic10Evidence);}
  function v350Ic10CompletionValid(){const q=num(v350Ic10ActualQty);return q>0&&q<=num(v350Ic10ApprovedQty)&&nonBlank(v350Ic10Proof);}
  const v350Render040Base=renderers["SCR-040"];
  renderers["SCR-040"]=function(state){
    if(activeFlowId!=="UIF-10")return v350Render040Base(state);
    if(state==="PERMISSION_DENIED")return v350Render040Base(state);
    const base=icHeaderRows([["Sản phẩm","Amox 500",true],["Lô","L2407-A"],["Tình trạng","Cách ly"],["Có thể xử lý","6 hộp"]]);
    if(state==="SELF_APPROVAL_NOT_ALLOWED")return appShell({title:"Duyệt tiêu hủy",body:vBanner("warning","Không thể tự duyệt","Người lập yêu cầu không được tự duyệt yêu cầu tiêu hủy."),back:false});
    if(state==="PENDING_APPROVAL")return appShell({title:"Yêu cầu tiêu hủy",body:`${vBanner("info","Đã gửi chờ duyệt","Tồn kho chưa thay đổi; người duyệt nhận công việc riêng.")}${base}${icHeaderRows([["Số lượng đề nghị",`${v350Ic10RequestQty} hộp`,true],["Lý do",v350Ic10Reason],["Bằng chứng",v350Ic10Evidence],["Tác động tồn kho","Chưa có"]])}`,back:false});
    if(state==="APPROVAL_REVIEW")return appShell({title:"Duyệt tiêu hủy",body:`${vBanner("info","Phê duyệt chưa phải tiêu hủy","Duyệt chỉ cho phép chuyển yêu cầu sang chờ xử lý thực tế; tồn vật lý chưa giảm.")}${base}${icHeaderRows([["Số lượng đề nghị",`${v350Ic10RequestQty} hộp`,true],["Lý do",v350Ic10Reason||"—"],["Bằng chứng",v350Ic10Evidence||"—"],["Căn cứ giá","Giá vốn hiện hành"]])}`,actions:`<div class="ic-action-stack">${icSecondary("Từ chối",'data-v350-action="ic10-reject"','danger')}${primaryFooter("Duyệt",'data-v350-action="ic10-approve"')}</div>`,back:false});
    if(state==="APPROVED_PENDING_DISPOSAL")return appShell({title:"Yêu cầu tiêu hủy",body:`${vBanner("success","Đã duyệt — chờ xử lý thực tế","Tồn kho vẫn giữ nguyên cho đến khi người thực hiện xác nhận xử lý thực tế.")}${base}${icHeaderRows([["Đã duyệt",`${v350Ic10ApprovedQty} hộp`,true],["Tồn vật lý hiện tại","6 hộp · chưa giảm"]])}`,back:false});
    if(state==="COMPLETION"||state==="COMPLETION_QTY_BLOCKED"){
      const blocked=state==="COMPLETION_QTY_BLOCKED";
      const body=`${blocked?vBanner("error","Số lượng thực tế vượt phạm vi được duyệt",`Tối đa ${v350Ic10ApprovedQty} hộp. Không thể ghi giảm phần vượt.`):vBanner("warning","Chỉ xác nhận sau khi đã xử lý thực tế","Số lượng thực tế sẽ là căn cứ ghi giảm tồn.")}${base}${icField("Đã tiêu hủy thực tế",v350Ic10ActualQty,'data-v350-ic10-actual','number')}${icTextarea("Bằng chứng",v350Ic10Proof,'data-v350-ic10-proof','Nhập số biên bản hoặc bằng chứng')}`;
      return appShell({title:"Xác nhận đã tiêu hủy",body,actions:primaryFooter("Xác nhận đã tiêu hủy",'data-v350-action="ic10-complete"',false,"danger"),back:false});
    }
    const invalid=state==="VALIDATION_ERROR";const price=state==="PRICE_BASIS_REQUIRED";
    const body=`${invalid?vBanner("error","Chưa đủ thông tin","Số lượng phải từ 1 đến 6 hộp; lý do và bằng chứng là bắt buộc."):""}${price?vBanner("error","Chưa có căn cứ giá hợp lệ","Không thể gửi yêu cầu cho đến khi có căn cứ giá chính thức."):""}${base}${icField("Số lượng đề nghị",v350Ic10RequestQty,'data-v350-ic10-qty','number')}${icTextarea("Lý do",v350Ic10Reason,'data-v350-ic10-reason')}${icTextarea("Bằng chứng",v350Ic10Evidence,'data-v350-ic10-evidence')}${icHeaderRows([["Căn cứ giá","Giá vốn hiện hành"]])}`;
    return appShell({title:"Yêu cầu tiêu hủy",body,actions:primaryFooter("Gửi yêu cầu tiêu hủy",'data-v350-action="ic10-submit"',price)});
  };
  const v350Render041Base=renderers["SCR-041"];
  renderers["SCR-041"]=function(state){
    if(activeFlowId==="UIF-10" && state==="COMPLETED")return appShell({title:"Kết quả tiêu hủy",body:ioResult("Đã ghi nhận tiêu hủy","Tồn vật lý và giá trị đã giảm theo đúng số lượng thực tế được xác nhận.",[["Yêu cầu","TH-0709-04"],["Đã tiêu hủy",`${v350Ic10CompletedQty||v350Ic10ApprovedQty} hộp`],["Tồn vật lý còn lại",`${Math.max(0,6-(v350Ic10CompletedQty||v350Ic10ApprovedQty))} hộp`]]),actions:primaryFooter("Về hàng có thể xử lý",'data-ic10-action="to-list"'),centered:true,back:false});
    return v350Render041Base(state);
  };

  // -------------------------------------------------------------------------
  // BJ12 — independent control total and approval snapshot.
  // -------------------------------------------------------------------------
  let v350Cf12ApprovalHash=null;
  const v350Cf12Hash=()=>[cf12FileName,cf12Cutoff,cf12ControlQty,cf12ControlValue,cf12Summary.rows,cf12Summary.parsedQty,cf12Summary.parsedValue].join("|");
  const v350Cf12Matches=()=>num(cf12ControlQty)===num(cf12Summary.parsedQty)&&num(cf12ControlValue)===num(cf12Summary.parsedValue);
  const v350Render067Base=renderers["SCR-067"];
  renderers["SCR-067"]=(state)=>activeFlowId==="UIF-12"?v350Render067Base(state).replace(/data-cf12-action="check"/g,'data-v350-action="cf12-check"'):v350Render067Base(state);
  const v350Render069Base=renderers["SCR-069"];
  renderers["SCR-069"]=(state)=>activeFlowId==="UIF-12"?v350Render069Base(state).replace(/data-cf12-action="send-approval"/g,'data-v350-action="cf12-send-approval"'):v350Render069Base(state);
  const v350Render070Base=renderers["SCR-070"];
  renderers["SCR-070"]=(state)=>activeFlowId==="UIF-12"?v350Render070Base(state).replace(/data-cf12-action="approve"/g,'data-v350-action="cf12-approve"'):v350Render070Base(state);
  const v350Render068Base=renderers["SCR-068"];
  renderers["SCR-068"]=function(state){
    if(activeFlowId!=="UIF-12")return v350Render068Base(state);
    if(state!=="CONTROL_TOTAL_MISMATCH")return v350Render068Base(state);
    const dq=num(cf12ControlQty)-num(cf12Summary.parsedQty),dv=num(cf12ControlValue)-num(cf12Summary.parsedValue);
    const body=`${vBanner("warning","Số kiểm soát không khớp","Không gửi phê duyệt cho đến khi tệp chi tiết khớp nguồn kiểm soát độc lập.")}${crFactCard("Đối chiếu số lượng",[["Theo tệp",cfNumber(cf12Summary.parsedQty),true],["Số kiểm soát",cfNumber(cf12ControlQty),true],["Chênh lệch",`${dq>0?"+":""}${cfNumber(dq)}`]])}${crFactCard("Đối chiếu giá trị",[["Theo tệp",cfMoney(cf12Summary.parsedValue),true],["Số kiểm soát",cfMoney(cf12ControlValue),true],["Chênh lệch",cfMoney(dv)]])}`;
    return appShell({title:"Kiểm tra dữ liệu",body,actions:primaryFooter("Sửa số kiểm soát",'data-cf12-action="back-file"')});
  };

  // -------------------------------------------------------------------------
  // BJ14 — successor must preserve immediate predecessor and policy method.
  // -------------------------------------------------------------------------
  const v350Render073Base=renderers["SCR-073"];
  renderers["SCR-073"]=function(state){
    if(activeFlowId!=="UIF-14")return v350Render073Base(state);
    if(state==="PERMISSION_DENIED")return v350Render073Base(state);
    const base=val14SuccessorOf?val14Runs.find(x=>x.id===val14SuccessorOf):null;
    const periodClose=val14SetupKind==="PERIOD_CLOSE";
    const method=base?.policyLabel||"Bình quân cuối kỳ",policy=base?.policyVersion||"Chính sách giá vốn";
    const setupFacts=ds24InfoGroup("Chính sách áp dụng",`${ds24InfoRow("Thời điểm chốt",periodClose?`Cuối kỳ ${val14SetupPeriod}`:"04/09/2026 · 14:30")}${ds24InfoRow("Phương pháp công bố",method)}${ds24InfoRow("Chính sách",policy)}`,"valuation-info-group");
    const body=`${base?vBanner("warning","Dữ liệu đã thay đổi","Lần tính mới kế thừa đúng phương pháp và thay thế trực tiếp lần tính này; lần cũ được giữ để truy vết."):""}${ds24SectionTitle("Loại lần tính")}${val14KindChoices()}<label class="val14-field valuation-field" data-ds-component="VField"><span>Kỳ</span><select data-val14-period data-ds-component="VSelect"><option ${val14SetupPeriod==="08/2026"?'selected':''}>08/2026</option><option ${val14SetupPeriod==="09/2026"?'selected':''}>09/2026</option></select></label><label class="val14-field valuation-field" data-ds-component="VField"><span>Phạm vi</span><select data-val14-scope data-ds-component="VSelect"><option ${val14SetupScope==="Toàn bộ sản phẩm"?'selected':''}>Toàn bộ sản phẩm</option><option ${val14SetupScope==="Sản phẩm cần tính lại"?'selected':''}>Sản phẩm cần tính lại</option></select></label>${setupFacts}`;
    return appShell({title:"Thiết lập lần tính",body,actions:primaryFooter("Tính giá vốn",'data-val14-action="calculate"')});
  };

  // -------------------------------------------------------------------------
  // BJ15 — report filters constrain actual datasets and export scope.
  // -------------------------------------------------------------------------
  cf15Movements.forEach(m=>{m.productId ||= "P-NOB";});
  if(!cf15Movements.some(m=>m.productId==="P-AMX"))cf15Movements.push({id:"MV-AMX-01",productId:"P-AMX",label:"Nhận hàng",source:"PN-260907-11",business:"07/09/2026",recorded:"07/09/2026",actor:"Nguyễn An",before:12,delta:6,after:18,uom:"hộp",lot:"L2407-A",state:"Bán được",value:720000});
  if(!cf15Movements.some(m=>m.productId==="P-GLV"))cf15Movements.push({id:"MV-GLV-01",productId:"P-GLV",label:"Kiểm kê",source:"KK-0709-03",business:"07/09/2026",recorded:"07/09/2026",actor:"Nguyễn An",before:5,delta:1,after:6,uom:"hộp",lot:"L2405-M",state:"Bán được",value:0});
  function v350DateIso(v){const m=String(v||"").match(/^(\d{2})\/(\d{2})\/(\d{4})/);return m?`${m[3]}-${m[2]}-${m[1]}`:String(v||"").slice(0,10);}
  function v350Cf15Products(){return cf15Product==="ALL"?cf15Products:cf15Products.filter(p=>p.id===cf15Product);}
  function v350Cf15Movements(mode=cf15DateMode){const pid=cf15Product==="ALL"?cf15SelectedProduct:cf15Product;return cf15Movements.filter(m=>(!pid||m.productId===pid)).filter(m=>{const d=v350DateIso(mode==="RECORDED"?m.recorded:m.business);return (!cf15From||d>=cf15From)&&(!cf15To||d<=cf15To);});}
  cf15InventoryResult=function(state,mode){
    const financeAllowed=state!=="FINANCIAL_RESTRICTED",products=v350Cf15Products();
    if(!products.length)return `${cf15ContextBanner(state,mode)}${ioEmpty("Không có dữ liệu phù hợp","Đổi phạm vi hoặc kỳ báo cáo để kiểm tra lại.")}`;
    const rows=products.map(p=>ioProductRow({name:p.name,code:p.code,primary:`${cfNumber(p.qty)} ${p.uom}`,secondary:`Khả dụng ${cfNumber(p.available)} ${p.uom}`,attr:`data-cf15-product-row="${p.id}"`})).join("");
    const totalValue=products.reduce((a,x)=>a+x.value,0);
    return `${cf15ContextBanner(state,mode)}${cfSummaryGrid([["Sản phẩm",products.length],["Kho","Kho trung tâm"],...(financeAllowed?[["Tổng giá trị",cfMoney(totalValue)]]:[])])}${financeAllowed?"":vBanner("info","Giá trị tài chính đã được ẩn","Bạn vẫn có thể xem số lượng trong phạm vi được cấp quyền.")}<div class="io-list-card" data-ds-component="VSection" data-composed-from="DS v2 / List Row"><div class="io-product-list">${rows}</div></div><p class="io-footnote">Không cộng các số lượng khác đơn vị thành một tổng giả.</p><div class="cf-inline-actions">${cfSecondary("Xuất báo cáo",'data-cf15-action="export"')}</div>${cf15ProductSheet(cf15ProductById(cf15SelectedProduct),financeAllowed)}`;
  };
  cf15StockCardResult=function(state,mode){
    const financeAllowed=state!=="FINANCIAL_RESTRICTED";const p=cf15ProductById(cf15Product==="ALL"?cf15SelectedProduct:cf15Product);const movements=v350Cf15Movements(mode);
    const movRows=movements.map(m=>`<button class="cf-movement-row" type="button" data-cf15-movement="${m.id}" data-ds-component="DS v2 / List Row"><span><strong>${m.label}</strong><small>${mode==="RECORDED"?m.recorded:m.business} · ${m.source}</small></span><span class="cf-movement-values"><strong>${m.delta>0?"+":""}${m.delta} ${m.uom}</strong><small>Còn ${m.after} ${m.uom}</small></span>${navChevron()}</button>`).join("");
    return `${cf15ContextBanner(state,mode)}${crFactCard(p.name,[["Mã",p.code,true],["Tồn hiện tại",`${cfNumber(p.qty)} ${p.uom}`],["Khả dụng bán",`${cfNumber(p.available)} ${p.uom}`],...(financeAllowed?[["Giá trị tồn",cfMoney(p.value)]]:[])])}${financeAllowed?"":vBanner("info","Giá trị tài chính đã được ẩn","Thẻ kho vẫn hiển thị số lượng và nguồn nghiệp vụ trong phạm vi quyền.")}${movements.length?`<div class="cf-movement-list">${movRows}</div>`:ioEmpty("Không có biến động trong kỳ","Đổi khoảng ngày hoặc sản phẩm để xem dữ liệu khác.")}<div class="cf-inline-actions">${cfSecondary("Xuất thẻ kho",'data-cf15-action="export"')}</div>`;
  };
  const v350Render055Base=renderers["SCR-055"];
  renderers["SCR-055"]=function(state){
    if(activeFlowId!=="UIF-15")return v350Render055Base(state);
    if(!["READY","RECORDED_DATE_VIEW","BUSINESS_DATE_VIEW","FINANCIAL_RESTRICTED","FILTER_EMPTY","EMPTY","LOADING","PERMISSION_DENIED"].includes(state))return v350Render055Base(state);
    if(["FILTER_EMPTY","EMPTY","LOADING","PERMISSION_DENIED"].includes(state))return v350Render055Base(state);
    const mode=state==="RECORDED_DATE_VIEW"?"RECORDED":state==="BUSINESS_DATE_VIEW"?"BUSINESS":cf15DateMode;
    const financeAllowed=state!=="FINANCIAL_RESTRICTED";
    if(cf15ReportType==="INVENTORY"){
      const products=v350Cf15Products();
      if(!products.length)return ac310Return(appShell({title:"Báo cáo tồn kho",body:ioEmpty("Không có dữ liệu phù hợp","Đổi phạm vi hoặc kỳ báo cáo để kiểm tra lại.")}));
      const rows=products.map((p)=>ac310ProductRow({name:p.name,code:p.code,meta:`${cfNumber(p.qty)} ${p.uom} · Khả dụng ${cfNumber(p.available)} ${p.uom}`,attrs:`data-cf15-product-row="${p.id}"`})).join("");
      const totalValue=products.reduce((a,x)=>a+x.value,0);
      const body=`${cf15ContextBanner(state,mode)}${ac310SummaryMetrics([["Sản phẩm",products.length],["Kho","Kho trung tâm"],...(financeAllowed?[["Tổng giá trị",cfMoney(totalValue)]]:[])])}${financeAllowed?"":vBanner("info","Giá trị tài chính đã được ẩn","Bạn vẫn có thể xem số lượng trong phạm vi được cấp quyền.")}${ac310ListSurface(rows)}<button class="button button--secondary ac310-inline-button" type="button" data-cf15-action="export">Xuất báo cáo</button>${ac310Cf15ProductSheet(cf15ProductById(cf15SelectedProduct),financeAllowed)}`;
      return ac310Return(appShell({title:"Báo cáo tồn kho",subtitle:`Kho trung tâm · ${cf15DateLabel(mode)}`,body}));
    }
    const p=cf15ProductById(cf15Product==="ALL"?cf15SelectedProduct:cf15Product);
    const filtered=v350Cf15Movements(mode);
    if(!filtered.length)return ac310Return(appShell({title:"Thẻ kho",subtitle:`${p.name} · ${cf15DateLabel(mode)}`,body:`${cf15ContextBanner(state,mode)}${ioEmpty("Không có biến động trong kỳ","Đổi khoảng ngày hoặc sản phẩm để xem dữ liệu khác.")}`}));
    const movements=filtered.map((m)=>ac310RecordRow({title:m.label,subtitle:`${mode==="RECORDED"?m.recorded:m.business} · ${m.source}`,badge:`${m.delta>0?"+":""}${m.delta} ${m.uom}`,tone:"Neutral",attrs:`data-cf15-movement="${m.id}"`,leading:null})).join("");
    const body=`${cf15ContextBanner(state,mode)}${ac310ProductRow({name:p.name,code:p.code,meta:`${cfNumber(p.qty)} ${p.uom}`,badge:`Khả dụng ${cfNumber(p.available)} ${p.uom}`,tone:"Success",status:true})}${financeAllowed?ac310KeyValueSurface("",[["Giá trị tồn",cfMoney(p.value),true]]):vBanner("info","Giá trị tài chính đã được ẩn","Thẻ kho vẫn hiển thị số lượng và nguồn nghiệp vụ.")}${ac310SectionTitle("Biến động")}${ac310ListSurface(movements)}<button class="button button--secondary ac310-inline-button" type="button" data-cf15-action="export">Xuất thẻ kho</button>`;
    return ac310Return(appShell({title:"Thẻ kho",subtitle:`${p.name} · ${cf15DateLabel(mode)}`,body}));
  };
  const v350Render058Base=renderers["SCR-058"];
  renderers["SCR-058"]=function(state){
    if(activeFlowId!=="UIF-15"||state!=="READY")return v350Render058Base(state);
    const sourceLabel=cf15ExportFrom==="SOURCE"?"Bằng chứng biến động":cf15ReportType==="STOCK_CARD"?"Thẻ kho":"Báo cáo tồn kho";
    const productLabel=cf15Product==="ALL"?"Tất cả sản phẩm":cf15ProductById(cf15Product).name;
    const count=cf15ReportType==="STOCK_CARD"?v350Cf15Movements(cf15DateMode).length:v350Cf15Products().length;
    const body=`${crFactCard("Phạm vi xuất",[["Nội dung",sourceLabel,true],["Kho","Kho trung tâm"],["Sản phẩm",productLabel],["Kỳ",`${cfDateVN(cf15From)} → ${cfDateVN(cf15To)}`],["Cách hiểu thời gian",cf15DateLabel()],["Số dòng trong phạm vi",String(count)],["Giá trị tài chính",cf15FinanceIncluded?"Có":"Không"]])}${crFactCard("Định dạng",[["Tệp","CSV",true],["Quyền dữ liệu","Giữ đúng như màn đang xem"]])}<p class="io-footnote">Tệp xuất giữ đúng bộ lọc, khoảng ngày, quyền và mốc dữ liệu của kết quả đang xem.</p>`;
    return appShell({title:"Xuất báo cáo",body,actions:primaryFooter("Xuất báo cáo",'data-cf15-action="confirm-export"'),backAction:"cf15-back-export"});
  };

  // -------------------------------------------------------------------------
  // BJ16 / BJ17 — context integrity + evidence freshness + safe finality.
  // -------------------------------------------------------------------------
  cr16Cases.forEach((c,i)=>{c.evidenceVersion ??= 1;c.planEvidenceVersion ??= null;c.recoveryEvidenceVersion ??= null;c.closed ??= false;if(c.id==="REC-260907-04")c.correctionOperationId="IO-260904-021";});
  if(!cr11Operations.some(o=>o.id==="IO-260904-021"))cr11Operations.splice(2,0,{id:"IO-260904-021",type:"Nhận hàng",source:"PN-260904-08",status:"COMPLETED",statusLabel:"Có thể sửa",route:"CORRECT",warehouse:"Kho trung tâm",product:"Amox 500 · Lô L2407-A",qty:20,uom:"hộp",correctQty:18,impact:"Đã tăng tồn 20 hộp"});
  cr17Cases.forEach(c=>{c.evidenceVersion ??= 1;c.planEvidenceVersion ??= null;c.resolutionRecord ??= null;c.sourceFlow ??= "UIF-17";});
  const v350Render079Base=renderers["SCR-079"],v350Render080Base=renderers["SCR-080"],v350Render081Base=renderers["SCR-081"],v350Render082Base=renderers["SCR-082"],v350Render083Base=renderers["SCR-083"];
  renderers["SCR-079"]=function(state){
    if(activeFlowId!=="UIF-16")return v350Render079Base(state);
    const c=cr16Current();const actual=state==="READY"?cr079StateFor16(c):state;
    if(actual==="SOURCE_MISMATCH")return appShell({title:"Bằng chứng & kết luận",body:`${vBanner("info","Đang chờ nghiệp vụ nguồn xác minh","Kho không tự sửa dữ liệu nguồn. Chuyển đúng hồ sơ và phạm vi cho phân hệ sở hữu nguồn.")}${crFactCard(c.id,[["Phạm vi",c.scope,true],["Người xử lý hiện tại",c.owner],["Bảo vệ phạm vi","Đang áp dụng"]])}${crEvidenceCard(cr16EvidenceRows(c))}`,actions:primaryFooter("Chuyển cho nghiệp vụ nguồn",'data-v350-action="cr16-source-handoff"')});
    if(actual==="CORRECTION_REQUIRED")return appShell({title:"Bằng chứng & kết luận",body:`${vBanner("warning","Cần sửa nghiệp vụ đã hoàn tất","Sai lệch nằm ở nghiệp vụ nguồn. Không chỉnh số dư trực tiếp.")}${crFactCard(c.id,[["Phạm vi",c.scope,true],["Người xử lý",c.owner]])}${crEvidenceCard(cr16EvidenceRows(c))}`,actions:primaryFooter("Mở yêu cầu sửa sai",'data-v350-action="cr16-correction-handoff"')});
    const html=v350Render079Base(state);return html.replace(/data-cr16-action="open-plan"/g,'data-v350-action="cr16-open-plan"').replace(/data-cr16-action="review-close"/g,'data-v350-action="cr16-review-close"');
  };
  renderers["SCR-080"]=function(state){
    const html=v350Render080Base(state);
    if(activeFlowId==="UIF-16")return html.replace(/data-cr16-action="start-recovery"/g,'data-v350-action="cr16-start-recovery"');
    if(activeFlowId==="UIF-17")return html.replace(/data-cr17-action="execute-plan"/g,'data-v350-action="cr17-execute-plan"').replace(/data-cr17-action="show-escalated"/g,'data-v350-action="cr17-show-escalated"');
    return html;
  };
  renderers["SCR-081"]=function(state){const html=v350Render081Base(state);return activeFlowId==="UIF-16"?html.replace(/data-cr16-action="review-result"/g,'data-v350-action="cr16-review-result"'):html;};
  renderers["SCR-082"]=function(state){
    if(activeFlowId==="UIF-16"&&state==="MISMATCH_REMAINS")return appShell({title:"Rà soát kết quả",body:`${vBanner("warning","Sai lệch vẫn còn","Giữ hồ sơ mở và phạm vi được bảo vệ. Quay lại bằng chứng để tiếp tục điều tra.")}${crFactCard(cr16Current().id,[["Sổ kho","118 hộp"],["Số liệu hiển thị","117 hộp"],["Chênh lệch","−1 hộp",true]])}`,actions:primaryFooter("Quay lại bằng chứng",'data-v350-action="cr16-back-evidence"')});
    const html=v350Render082Base(state);
    if(activeFlowId==="UIF-16")return html.replace(/data-cr16-action="close-case"/g,'data-v350-action="cr16-close-case"');
    if(activeFlowId==="UIF-17")return html.replace(/data-cr17-action="finish-review"/g,'data-v350-action="cr17-finish-review"');
    return html;
  };
  renderers["SCR-083"]=function(state){return v350Render083Base(state);};

  // -------------------------------------------------------------------------
  // UNKNOWN result routing — a result in doubt must not silently return/retry.
  // -------------------------------------------------------------------------
  function wrapUnknown(screenId,flowId,metaFactory){const base=renderers[screenId];renderers[screenId]=function(state){if(activeFlowId===flowId&&["UNKNOWN","COMMIT_UNKNOWN"].includes(state))return v350UnknownResult(metaFactory());return base(state);};}
  const unknowns=[
    ["SCR-019","UIF-03",()=>({sourceFlow:"UIF-03",operation:`Giá trị ban đầu · ${val03Current()?.id||""}`,scope:"Lô/đơn vị vừa xác nhận"})],
    ["SCR-029","UIF-05",()=>({sourceFlow:"UIF-05",operation:io05CurrentOrder().id,scope:`${io05CurrentOrder().customer} · ${io05CurrentOrder().warehouse}`})],
    ["SCR-035","UIF-06",()=>({sourceFlow:"UIF-06",operation:io06CurrentRequest().id,scope:`${io06CurrentRequest().customer} · ${io06CurrentRequest().source}`})],
    ["SCR-041","UIF-07",()=>({sourceFlow:"UIF-07",operation:io07Current().id,scope:`${io07Current().supplier} · ${io07Current().source}`})],
    ["SCR-047","UIF-08",()=>({sourceFlow:"UIF-08",operation:"KK-0709-03",scope:"Kho trung tâm · phiên kiểm kê"})],
    ["SCR-041","UIF-09",()=>({sourceFlow:"UIF-09",operation:`Đổi tình trạng · ${ic09Current().code}`,scope:`${ic09Current().name} · Lô ${ic09Current().lot}`})],
    ["SCR-041","UIF-10",()=>({sourceFlow:"UIF-10",operation:"TH-0709-04",scope:"Amox 500 · Lô L2407-A"})],
    ["SCR-066","UIF-12",()=>({sourceFlow:"UIF-12",operation:"Khởi tạo tồn kho đầu kỳ",scope:`Kho trung tâm · ${cfDateVN(cf12Cutoff)}`})],
    ["SCR-071","UIF-12",()=>({sourceFlow:"UIF-12",operation:"Khởi tạo tồn kho đầu kỳ",scope:`Kho trung tâm · ${cfDateVN(cf12Cutoff)}`})],
    ["SCR-089","UIF-13",()=>({sourceFlow:"UIF-13",operation:`Chi phí đến muộn · ${val13Current()?.id||""}`,scope:"Phạm vi phân bổ đã xác nhận"})],
    ["SCR-077","UIF-14",()=>({sourceFlow:"UIF-14",operation:val14Current()?.id||"Lần tính giá vốn",scope:`${val14Current()?.period||""} · ${val14Current()?.scope||""}`})]
  ];unknowns.forEach(x=>wrapUnknown(...x));
  // BJ02 uses an explicit verification step before escalation to BJ17.
  const v350Render012Base=renderers["SCR-012"],v350Render013Base=renderers["SCR-013"];
  renderers["SCR-012"]=function(state){if(activeFlowId==="UIF-02"&&["UNKNOWN","COMMIT_UNKNOWN"].includes(state))return appShell({title:"Kết quả nhận hàng",body:ioResult("Đang xác minh kết quả","Không gửi lại thao tác. Kiểm tra đúng lần ghi nhận này trước khi quyết định bước tiếp theo.",[["Yêu cầu","Nhận hàng hiện tại"],["Trạng thái","Chưa kết luận"]],"warning"),actions:primaryFooter("Xác minh kết quả",'data-v350-action="bj02-verify-unknown"'),centered:true,back:false});return v350Render012Base(state);};
  renderers["SCR-013"]=function(state){if(activeFlowId==="UIF-02"&&["PROCESSING_OR_UNKNOWN","STALE"].includes(state)){const html=v350Render013Base(state);return html.replace(/data-action="handoff"/g,'data-v350-action="bj02-handoff-unknown"');}return v350Render013Base(state);};

  // BJ11 navigation action must not create finality.
  const v350Render051Base=renderers["SCR-051"];
  renderers["SCR-051"]=(state)=>activeFlowId==="UIF-11"?v350Render051Base(state).replace(/data-cr11-action="approval-result"/g,'data-v350-action="cr11-approval-result"'):v350Render051Base(state);

  // -------------------------------------------------------------------------
  // Event binding for v3.5.0 controls.
  // -------------------------------------------------------------------------
  document.addEventListener("input",(event)=>{
    if(event.target.matches("[data-v350-ic09-reason]")){v350Ic09Reason=event.target.value;return;}
    if(event.target.matches("[data-v350-ic10-qty]")){v350Ic10RequestQty=event.target.value;return;}
    if(event.target.matches("[data-v350-ic10-reason]")){v350Ic10Reason=event.target.value;return;}
    if(event.target.matches("[data-v350-ic10-evidence]")){v350Ic10Evidence=event.target.value;return;}
    if(event.target.matches("[data-v350-ic10-actual]")){v350Ic10ActualQty=event.target.value;return;}
    if(event.target.matches("[data-v350-ic10-proof]")){v350Ic10Proof=event.target.value;return;}
  },true);

  document.addEventListener("click",(event)=>{
    const a=event.target.closest("[data-v350-action]");if(!a||a.disabled)return;
    event.preventDefault();event.stopPropagation();const k=a.dataset.v350Action;
    if(k==="handoff-unknown")return v350HandoffUnknown({sourceFlow:a.dataset.sourceFlow,operation:a.dataset.operation,scope:a.dataset.scope,evidence:"INSUFFICIENT"});
    if(k==="bj02-verify-unknown"){stateByScreen["SCR-013"]="PROCESSING_OR_UNKNOWN";return navigate("SCR-013");}
    if(k==="bj02-handoff-unknown")return v350HandoffUnknown({sourceFlow:"UIF-02",operation:"Nhận hàng",scope:"Yêu cầu nhận hàng hiện tại",evidence:"INSUFFICIENT"});

    if(k==="ic08-confirm-submit-first"){
      ic08ConfirmKind=null;if(!v350Ic08FirstValid()){stateByScreen["SCR-044"]="VALIDATION_ERROR";return renderAppScreen();}
      v350Ic08Recompute();
      if(v350Ic08DiscrepancyIds.length){v350Ic08DiscrepancyIds.forEach(id=>ic08Recounts[id]="");stateByScreen["SCR-045"]="RECOUNT_REQUIRED";return navigate("SCR-045");}
      stateByScreen["SCR-046"]="APPROVAL_REVIEW";return navigate("SCR-046");
    }
    if(k==="ic08-confirm-submit-recount"){
      ic08ConfirmKind=null;if(!v350Ic08RecountValid()){stateByScreen["SCR-045"]="VALIDATION_ERROR";return renderAppScreen();}
      stateByScreen["SCR-042"]="PENDING_APPROVAL";return navigate("SCR-042");
    }
    if(k==="ic08-confirm-open-session"){ic08ConfirmKind=null;stateByScreen["SCR-044"]="BLIND_COUNT";return navigate("SCR-044");}
    if(k==="ic08-confirm-cancel"){if(!nonBlank(ic08CancelReason))return;ic08ConfirmKind=null;stateByScreen["SCR-047"]="CANCELLED";return navigate("SCR-047");}
    if(k==="ic08-approve"){if(!isApproverEntry()){stateByScreen["SCR-046"]="SELF_APPROVAL_NOT_ALLOWED";return renderAppScreen();}ic08ConfirmKind="approve";return renderAppScreen();}
    if(k==="ic08-confirm-approve"){if(!isApproverEntry()){ic08ConfirmKind=null;stateByScreen["SCR-046"]="SELF_APPROVAL_NOT_ALLOWED";return renderAppScreen();}ic08ConfirmKind=null;v350Ic08AdjustedCount=["amox","glove"].filter(id=>num(nonBlank(ic08Recounts[id])?ic08Recounts[id]:ic08Counts[id])!==v350Ic08Book[id]).length;stateByScreen["SCR-047"]="COMPLETED";return navigate("SCR-047");}
    if(k==="ic08-request-review"){ic08ReviewReason="";ic08ConfirmKind="request-review";return renderAppScreen();}
    if(k==="ic08-confirm-request-review"){if(!isApproverEntry()){ic08ConfirmKind=null;stateByScreen["SCR-046"]="SELF_APPROVAL_NOT_ALLOWED";return renderAppScreen();}if(!nonBlank(ic08ReviewReason))return;ic08ConfirmKind=null;stateByScreen["SCR-045"]="RECOUNT_REQUIRED";return navigate("SCR-045");}
    if(k==="ic08-approval-result")return navigate("SCR-047");

    if(k==="ic09-submit"){if(!ic09Destination||!nonBlank(v350Ic09Reason)){stateByScreen["SCR-038"]="VALIDATION_ERROR";return renderAppScreen();}const x=ic09Current();v350Ic09Request={itemId:x.id,from:x.state,destination:ic09Destination,reason:v350Ic09Reason.trim()};stateByScreen["SCR-038"]="PENDING_APPROVAL";return renderAppScreen();}
    if(k==="ic09-approve"){if(!isApproverEntry()){stateByScreen["SCR-038"]="SELF_APPROVAL_NOT_ALLOWED";return renderAppScreen();}const req=v350Ic09Request;if(!req){stateByScreen["SCR-038"]="VALIDATION_ERROR";return renderAppScreen();}const x=ic09Items.find(i=>i.id===req.itemId);if(x){x.state=req.destination;x.label=req.destination==="QUARANTINE"?"Cách ly":req.destination==="DAMAGED"?"Hỏng":req.destination==="DEMO"?"Dùng thử":"Bán được";}stateByScreen["SCR-041"]="COMPLETED";return navigate("SCR-041");}
    if(k==="ic09-reject"){if(!isApproverEntry()){stateByScreen["SCR-038"]="SELF_APPROVAL_NOT_ALLOWED";return renderAppScreen();}stateByScreen["SCR-041"]="REJECTED_EXECUTION";return navigate("SCR-041");}

    if(k==="ic10-submit"){if(!v350Ic10RequestValid()){stateByScreen["SCR-040"]="VALIDATION_ERROR";return renderAppScreen();}stateByScreen["SCR-040"]="PENDING_APPROVAL";return renderAppScreen();}
    if(k==="ic10-approve"){if(!isApproverEntry()){stateByScreen["SCR-040"]="SELF_APPROVAL_NOT_ALLOWED";return renderAppScreen();}v350Ic10ApprovedQty=num(v350Ic10RequestQty);stateByScreen["SCR-040"]="APPROVED_PENDING_DISPOSAL";return renderAppScreen();}
    if(k==="ic10-reject"){if(!isApproverEntry()){stateByScreen["SCR-040"]="SELF_APPROVAL_NOT_ALLOWED";return renderAppScreen();}stateByScreen["SCR-041"]="REJECTED_EXECUTION";return navigate("SCR-041");}
    if(k==="ic10-complete"){
      if(!isCompletionEntry()&&v350ActorMode!=="module"){return;}
      if(num(v350Ic10ActualQty)>num(v350Ic10ApprovedQty)){stateByScreen["SCR-040"]="COMPLETION_QTY_BLOCKED";return renderAppScreen();}
      if(!v350Ic10CompletionValid()){stateByScreen["SCR-040"]="COMPLETION_QTY_BLOCKED";return renderAppScreen();}
      v350Ic10CompletedQty=num(v350Ic10ActualQty);stateByScreen["SCR-041"]="COMPLETED";return navigate("SCR-041");
    }

    if(k==="cf12-check"){
      const valid=Boolean(cf12FileName&&cf12Cutoff&&cf12ControlQty!==""&&cf12ControlValue!==""&&num(cf12ControlQty)>=0&&num(cf12ControlValue)>=0);
      if(!valid){stateByScreen["SCR-067"]="VALIDATION_ERROR";return renderAppScreen();}
      stateByScreen["SCR-068"]=v350Cf12Matches()?"READY":"CONTROL_TOTAL_MISMATCH";return navigate("SCR-068");
    }
    if(k==="cf12-send-approval"){if(!v350Cf12Matches()){stateByScreen["SCR-068"]="CONTROL_TOTAL_MISMATCH";return navigate("SCR-068");}v350Cf12ApprovalHash=v350Cf12Hash();stateByScreen["SCR-069"]="PENDING_APPROVAL";stateByScreen["SCR-066"]="PENDING_APPROVAL";return navigate("SCR-066");}
    if(k==="cf12-approve"){
      if(!isApproverEntry()){stateByScreen["SCR-070"]="SELF_APPROVAL_NOT_ALLOWED";return renderAppScreen();}
      if(!v350Cf12ApprovalHash||v350Cf12ApprovalHash!==v350Cf12Hash()){stateByScreen["SCR-070"]="VALIDATION_ERROR";return renderAppScreen();}
      stateByScreen["SCR-071"]="PROCESSING";navigate("SCR-071");setTimeout(()=>{if(activeFlowId==="UIF-12"&&activeScreenId==="SCR-071"&&stateByScreen["SCR-071"]==="PROCESSING"){stateByScreen["SCR-071"]="COMPLETED";stateByScreen["SCR-066"]="ACTIVE_RECONCILED";render();}},420);return;
    }

    if(k==="cr11-approval-result")return navigate("SCR-053");
    if(k==="cr16-correction-handoff"){const c=cr16Current();const opId=c.correctionOperationId;if(!opId)return;cr11SelectedId=opId;stateByScreen["SCR-049"]="CORRECTABLE";return crSwitchFlow("UIF-11","SCR-049","CORRECTABLE");}
    if(k==="cr16-source-handoff"){stateByScreen["SCR-083"]="ESCALATED";return navigate("SCR-083");}
    if(k==="cr16-open-plan"){const c=cr16Current();c.planEvidenceVersion=c.evidenceVersion;stateByScreen["SCR-080"]="READY";return navigate("SCR-080");}
    if(k==="cr16-start-recovery"){const c=cr16Current();if(num(c.planEvidenceVersion)!==num(c.evidenceVersion)){stateByScreen["SCR-080"]="CONFLICT";return renderAppScreen();}c.recoveryEvidenceVersion=c.evidenceVersion;stateByScreen["SCR-081"]="REBUILDING";navigate("SCR-081");setTimeout(()=>{if(activeFlowId==="UIF-16"&&activeScreenId==="SCR-081"){const cc=cr16Current();stateByScreen["SCR-081"]=num(cc.recoveryEvidenceVersion)===num(cc.evidenceVersion)?"READY":"CONFLICT";render();}},250);return;}
    if(k==="cr16-review-result"){const c=cr16Current();if(num(c.recoveryEvidenceVersion)!==num(c.evidenceVersion)){stateByScreen["SCR-081"]="CONFLICT";return renderAppScreen();}stateByScreen["SCR-082"]="READY";return navigate("SCR-082");}
    if(k==="cr16-review-close"){const c=cr16Current();c.planEvidenceVersion=c.evidenceVersion;stateByScreen["SCR-082"]="READY";return navigate("SCR-082");}
    if(k==="cr16-close-case"){const c=cr16Current();const snap=c.recoveryEvidenceVersion??c.planEvidenceVersion;if(num(snap)!==num(c.evidenceVersion)){stateByScreen["SCR-082"]="MISMATCH_REMAINS";return renderAppScreen();}c.closed=true;stateByScreen["SCR-083"]="COMPLETED";return navigate("SCR-083");}
    if(k==="cr16-back-evidence"){stateByScreen["SCR-079"]=cr079StateFor16(cr16Current());return navigate("SCR-079");}

    if(k==="cr17-execute-plan"){
      const c=cr17Current();if(!c.planEvidenceVersion)c.planEvidenceVersion=c.evidenceVersion;
      if(num(c.planEvidenceVersion)!==num(c.evidenceVersion)){stateByScreen["SCR-080"]="CONFLICT";return renderAppScreen();}
      cr17ResolutionMode=c.evidence==="COMMITTED"?"COMMITTED":"CONTINUED";
      c.resolutionRecord={operationId:c.operation,scope:c.scope,evidenceVersion:c.evidenceVersion,newOperationCreated:false,duplicateEffect:false,mode:cr17ResolutionMode};
      stateByScreen["SCR-082"]="READY";return navigate("SCR-082");
    }
    if(k==="cr17-finish-review"){
      const c=cr17Current(),r=c.resolutionRecord;if(!r||!same(r.operationId,c.operation)||!same(r.scope,c.scope)||num(r.evidenceVersion)!==num(c.evidenceVersion)||r.newOperationCreated||r.duplicateEffect){stateByScreen["SCR-080"]="CONFLICT";return navigate("SCR-080");}
      stateByScreen["SCR-083"]="COMPLETED";return navigate("SCR-083");
    }
    if(k==="cr17-show-escalated"){stateByScreen["SCR-083"]="ESCALATED";return navigate("SCR-083");}
  },true);

  // Snapshot the recovery plan when it is opened with existing BJ17 controls.
  document.addEventListener("click",(event)=>{const a=event.target.closest('[data-cr17-action="open-plan"]');if(!a||activeFlowId!=="UIF-17")return;const c=cr17Current();c.planEvidenceVersion=c.evidenceVersion;c.resolutionRecord=null;},true);
  // Normal-return stale source feedback after legacy commit handler refuses commit.
  document.addEventListener("click",(event)=>{const a=event.target.closest('[data-io06-action="commit-receipt"]');if(!a||activeFlowId!=="UIF-06")return;const req=io06CurrentRequest();if(num(req.reviewSourceVersion)!==num(req.sourceVersion)){stateByScreen["SCR-031"]="SOURCE_CHANGED";queueMicrotask(()=>renderAppScreen());}},true);


  // Reset per-request drafts when the user starts a new business task.
  document.addEventListener("click",(event)=>{
    if(activeFlowId==="UIF-09" && event.target.closest("[data-ic09-action=\"change\"]")){v350Ic09Reason="";v350Ic09Request=null;}
    if(activeFlowId==="UIF-09" && event.target.closest("[data-ic09-item]")){v350Ic09Reason="";v350Ic09Request=null;}
    if(activeFlowId==="UIF-10" && event.target.closest("[data-ic10-action=\"request\"]")){v350Ic10RequestQty="";v350Ic10Reason="";v350Ic10Evidence="";v350Ic10ApprovedQty=0;v350Ic10ActualQty="";v350Ic10Proof="";v350Ic10CompletedQty=0;}
  },true);

  // -------------------------------------------------------------------------
  // Actor ownership — decision actions are executable only in the assigned
  // approver/completion context. Navigation/open-sheet actions remain harmless.
  // -------------------------------------------------------------------------
  const v350Render011Base=renderers["SCR-011"];
  renderers["SCR-011"]=function(state){
    if(activeFlowId!=="UIF-02")return v350Render011Base(state);
    return v350Render011Base(state)
      .replace(/data-action="approve"/g,'data-v350-action="bj02-approve"')
      .replace(/data-action="confirm-reject"/g,'data-v350-action="bj02-confirm-reject"');
  };
  const v350Render034Base=renderers["SCR-034"];
  renderers["SCR-034"]=function(state){
    if(activeFlowId!=="UIF-06")return v350Render034Base(state);
    return v350Render034Base(state)
      .replace(/data-io06-action="approve-exception"/g,'data-v350-action="io06-approve-exception"')
      .replace(/data-io06-action="confirm-reject"/g,'data-v350-action="io06-confirm-reject"');
  };
  const v350Render051ActorBase=renderers["SCR-051"];
  renderers["SCR-051"]=function(state){
    if(activeFlowId!=="UIF-11")return v350Render051ActorBase(state);
    return v350Render051ActorBase(state)
      .replace(/data-cr11-action="approve"/g,'data-v350-action="cr11-approve"')
      .replace(/data-cr11-action="reject-confirm"/g,'data-v350-action="cr11-reject-confirm"');
  };
  const v350Render070ActorBase=renderers["SCR-070"];
  renderers["SCR-070"]=function(state){
    if(activeFlowId!=="UIF-12")return v350Render070ActorBase(state);
    return v350Render070ActorBase(state)
      .replace(/data-cf12-action="confirm-reject"/g,'data-v350-action="cf12-confirm-reject"');
  };

  document.addEventListener("click",(event)=>{
    const a=event.target.closest("[data-v350-action]"); if(!a||a.disabled)return;
    const k=a.dataset.v350Action;
    if(!["bj02-approve","bj02-confirm-reject","io06-approve-exception","io06-confirm-reject","cr11-approve","cr11-reject-confirm","cf12-confirm-reject"].includes(k))return;
    event.preventDefault();event.stopPropagation();
    if(!isApproverEntry()){
      const screen=activeFlowId==="UIF-02"?"SCR-011":activeFlowId==="UIF-06"?"SCR-034":activeFlowId==="UIF-11"?"SCR-051":"SCR-070";
      stateByScreen[screen]="SELF_APPROVAL_NOT_ALLOWED";return renderAppScreen();
    }
    if(k==="bj02-approve")return startAutoExecution();
    if(k==="bj02-confirm-reject")return confirmReject();
    if(k==="io06-approve-exception"){
      const c=io06SelectedApprovalCase();if(!c||c.status!=="PENDING")return;c.status="APPROVED";c.decisionReason="";io06AfterApprovalDecision(c);return renderAppScreen();
    }
    if(k==="io06-confirm-reject"){
      if(!io06RejectReason.trim())return;const c=io06SelectedApprovalCase();if(!c||c.status!=="PENDING")return;c.status="REJECTED";c.decisionReason=io06RejectReason.trim();io06RejectOpen=false;io06AfterApprovalDecision(c);return renderAppScreen();
    }
    if(k==="cr11-approve"){
      stateByScreen["SCR-053"]="PROCESSING";navigate("SCR-053");setTimeout(()=>{if(activeFlowId==="UIF-11"&&activeScreenId==="SCR-053"&&stateByScreen["SCR-053"]==="PROCESSING"){stateByScreen["SCR-053"]="COMPLETED";syncReviewUrl();render();}},300);return;
    }
    if(k==="cr11-reject-confirm"){
      if(!cr11ApprovalRejectReason.trim()){stateByScreen["SCR-051"]="VALIDATION_ERROR";return renderAppScreen();}cr11ApprovalRejectOpen=false;stateByScreen["SCR-053"]="REJECTED";return navigate("SCR-053");
    }
    if(k==="cf12-confirm-reject"){
      if(!cf12RejectReason.trim())return;cf12RejectOpen=false;stateByScreen["SCR-070"]="APPROVAL_ALREADY_DECIDED";stateByScreen["SCR-066"]="REJECTED";return renderAppScreen();
    }
  },true);

  // -------------------------------------------------------------------------
  // BJ08 list controls — search and filter must change the visible collection,
  // not merely render controls that look interactive.
  // -------------------------------------------------------------------------
  let v350Ic08ListQuery="", v350Ic08ListFilter="ALL";
  const v350Render042Base=renderers["SCR-042"];
  renderers["SCR-042"]=function(state){
    if(activeFlowId!=="UIF-08")return v350Render042Base(state);
    if(state==="CANCEL_REQUEST")return ac310Return(appShell({title:"Kiểm kê kho",body:`${vBanner("warning","Yêu cầu hủy cần được xử lý trong phiên","Không đặt thao tác hủy trên màn danh sách. Mở đúng phiên kiểm kê để tiếp tục xử lý theo trạng thái hiện hành.")}${ac310InfoSurface("Phiên kiểm kê",[["Mã phiên","KK-0709-03",true],["Kho","Kho trung tâm"],["Trạng thái","Cần mở phiên để xử lý"]])}`,actions:primaryFooter("Về danh sách",'data-v350-action="ic08-cancel-request-back"'),back:false}));
    if(!["READY","FILTER_EMPTY"].includes(state))return v350Render042Base(state);
    const records=[
      {id:"KK-0709-03",status:"COUNTING",title:"KK-0709-03",subtitle:"Kho trung tâm · Toàn kho · 12/38 đã đếm",badge:"Đang đếm",tone:"Info",action:'data-ic08-action="resume"'},
      {id:"KK-0708-02",status:"APPROVAL",title:"KK-0708-02",subtitle:"Kho trung tâm · Nhóm vaccine · Đã đếm xong",badge:"Chờ duyệt",tone:"Warning",action:'data-v350-action="ic08-open-approval"'}
    ];
    const q=v350Ic08ListQuery.trim().toLocaleLowerCase("vi");
    const rows=(state==="FILTER_EMPTY"?[]:records.filter(r=>(v350Ic08ListFilter==="ALL"||r.status===v350Ic08ListFilter)&&(!q||`${r.title} ${r.subtitle}`.toLocaleLowerCase("vi").includes(q))));
    const chips=`<div class="ds24-chip-scroll ac320-chip-row" aria-label="Lọc phiên kiểm kê">${ds24Chip("ALL","Tất cả",v350Ic08ListFilter==="ALL","data-v350-ic08-filter")}${ds24Chip("COUNTING","Đang đếm",v350Ic08ListFilter==="COUNTING","data-v350-ic08-filter")}${ds24Chip("APPROVAL","Chờ duyệt",v350Ic08ListFilter==="APPROVAL","data-v350-ic08-filter")}</div>`;
    const list=rows.length?`<div class="ac320-session-list">${rows.map(r=>ac310RecordRow({title:r.title,subtitle:r.subtitle,badge:r.badge,tone:r.tone,attrs:r.action,leading:null})).join("")}</div>`:ioEmpty("Không tìm thấy phiên kiểm kê","Thử từ khóa hoặc bộ lọc khác.");
    const body=`${ds24Search(v350Ic08ListQuery,'data-v350-ic08-list-search','Tìm phiên kiểm kê')}${chips}${list}`;
    return ac310Return(appShell({title:"Kiểm kê kho",body,actions:primaryFooter("Tạo phiên kiểm kê",'data-ic08-action="create"'),back:false}));
  };
  document.addEventListener("input",(event)=>{if(activeFlowId==="UIF-08"&&event.target.matches("[data-v350-ic08-list-search]")){v350Ic08ListQuery=event.target.value;return renderAppScreen();}},true);
  document.addEventListener("click",(event)=>{
    const f=event.target.closest("[data-v350-ic08-filter]");if(f&&activeFlowId==="UIF-08"){event.preventDefault();event.stopPropagation();v350Ic08ListFilter=f.dataset.v350Ic08Filter;return renderAppScreen();}
    const a=event.target.closest('[data-v350-action="ic08-open-approval"]');if(a&&activeFlowId==="UIF-08"){event.preventDefault();event.stopPropagation();stateByScreen["SCR-046"]="APPROVAL_REVIEW";return navigate("SCR-046");}
    const back=event.target.closest('[data-v350-action="ic08-cancel-request-back"]');if(back&&activeFlowId==="UIF-08"){event.preventDefault();event.stopPropagation();stateByScreen["SCR-042"]="READY";return renderAppScreen();}
  },true);

  // Fix List Row search hiding after DS migration.
  window.__VET45_V350__={
    version:VERSION,
    setActor(mode){v350ActorMode=String(mode||"module");return v350ActorMode;},
    getActor(){return v350ActorMode;},
    applyEntry(flowId,mode){
      v350ActorMode=String(mode||"module");
      const applied=v350ApplyEntry(String(flowId||activeFlowId),v350ActorMode,true);
      return {applied,flow:activeFlowId,screen:activeScreenId,state:stateByScreen[activeScreenId],actor:v350ActorMode};
    },
    bumpIO05Source(){const o=io05CurrentOrder();o.sourceVersion=num(o.sourceVersion)+1;return o.sourceVersion;},
    bumpIO06Source(){const r=io06CurrentRequest();r.sourceVersion=num(r.sourceVersion)+1;io06RefreshRequestState(r);return r.sourceVersion;},
    bumpCR16Evidence(){const c=cr16Current();c.evidenceVersion=num(c.evidenceVersion)+1;return c.evidenceVersion;},
    bumpCR17Evidence(){const c=cr17Current();c.evidenceVersion=num(c.evidenceVersion)+1;return c.evidenceVersion;},
    setCf12Control(qty,value){cf12ControlQty=String(qty);cf12ControlValue=String(value);return v350Cf12Matches();},
    getCf15Rows(mode=cf15DateMode){return v350Cf15Movements(mode).map(x=>x.id);},
    getState(){return {flow:activeFlowId,screen:activeScreenId,state:stateByScreen[activeScreenId]};},
    getIC10(){return {requestQty:v350Ic10RequestQty,reason:v350Ic10Reason,evidence:v350Ic10Evidence,approvedQty:v350Ic10ApprovedQty,actualQty:v350Ic10ActualQty,proof:v350Ic10Proof,completedQty:v350Ic10CompletedQty};},
    getIC09(){return {reason:v350Ic09Reason,destination:ic09Destination,request:v350Ic09Request,current:ic09Current()};},
    getBJ17(){const c=cr17Current();return {id:c.id,operation:c.operation,evidenceVersion:c.evidenceVersion,record:c.resolutionRecord};}
  };

  // Final render after correcting entry routing and effective renderer table.
  syncReviewUrl();render();
})();
