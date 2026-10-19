/* BJ-17 — Phục hồi nghiệp vụ có kết quả chưa xác định (UIF-17). Màn: SCR-078, 079, 080, 082, 083.
 *
 * Đã viết lại sạch (T7-P gói A10, 2026-10-19). Màn dựng thẳng (ownedFlows); gọi lại helper bj16* lúc chạy.
 * Cơ chế K3 handoff-unknown + bj17RecoveryCase ở đây; khoá nguồn qua móc onUnknownHandoff (bj05/06/07 đăng ký).
 * Chữ "Lần xử lý" viết thẳng (trước đây legacy-cross-theme-copy).
 */

let cr17Filter="ALL";
let cr17SelectedId="REC-UNKNOWN-01";
let cr17ResolutionMode="";
const cr17Cases=[
  {id:"REC-UNKNOWN-01",operation:"IO-260906-031",title:"Có bằng chứng đã phát sinh tác động",scope:"Vitamin C · Lô L2310-C · 5 hộp",evidence:"COMMITTED",severity:"Ưu tiên cao",tone:"warning",owner:"Kiểm soát kho",evidenceVersion:1,planEvidenceVersion:null,resolutionRecord:null,sourceFlow:"UIF-17"},
  {id:"REC-UNKNOWN-02",operation:"IO-260906-044",title:"Chưa phát hiện tác động tồn kho",scope:"Amox 500 · Lô L2407-A · 2 hộp",evidence:"NO_COMMIT",severity:"Cần xử lý",tone:"info",owner:"Kiểm soát kho",evidenceVersion:1,planEvidenceVersion:null,resolutionRecord:null,sourceFlow:"UIF-17"},
  {id:"REC-UNKNOWN-03",operation:"IO-260906-052",title:"Chưa đủ bằng chứng kết luận",scope:"Kho trung tâm · 1 lần xử lý",evidence:"INSUFFICIENT",severity:"Cần chuyên sâu",tone:"warning",owner:"Vận hành nền tảng",evidenceVersion:1,planEvidenceVersion:null,resolutionRecord:null,sourceFlow:"UIF-17"}
];
function cr17Current(){return cr17Cases.find(x=>x.id===cr17SelectedId)||cr17Cases[0];}
function cr079StateFor17(c){return c.evidence==="COMMITTED"?"UNKNOWN_EVIDENCE":c.evidence==="NO_COMMIT"?"UNKNOWN_EVIDENCE":"INSUFFICIENT_EVIDENCE";}

const bj17Num=(v)=>Number(v??0);
const bj17Same=(a,b)=>String(a??"")===String(b??"");

function bj17EvidenceRows(c){
  if(c.evidence==="COMMITTED")return [["Yêu cầu","Đã được tiếp nhận"],["Tác động tồn kho","Đã tìm thấy đúng phạm vi"],["Nghiệp vụ nguồn","Vẫn đang chờ kết quả"]];
  if(c.evidence==="NO_COMMIT")return [["Yêu cầu","Đã được tiếp nhận"],["Tác động tồn kho","Chưa phát hiện"],["Tác động dở dang","Không phát hiện"]];
  return [["Yêu cầu","Đã được tiếp nhận"],["Tác động tồn kho","Chưa đủ bằng chứng"],["Bằng chứng còn thiếu","Kết quả ghi nhận cuối cùng"]];
}

function bj17RecoveryCase({sourceFlow,operation,scope,title,evidence="INSUFFICIENT",owner="Kiểm soát kho"}={}){
  const op=operation||`${sourceFlow}-UNKNOWN`;
  let c=cr17Cases.find(x=>x.operation===op&&x.sourceFlow===sourceFlow);
  if(!c){
    c={
      id:`REC-${String(sourceFlow||"").replace("UIF-","")}-${String(op).replace(/[^A-Za-z0-9]/g,"").slice(-12)}`,
      operation:op,
      title:title||"Cần xác minh kết quả nghiệp vụ",
      scope:scope||"Phạm vi của lần xử lý hiện tại",
      evidence,
      severity:evidence==="INSUFFICIENT"?"Cần chuyên sâu":"Cần xử lý",
      tone:evidence==="INSUFFICIENT"?"warning":"info",
      owner,
      sourceFlow,
      evidenceVersion:1,
      protected:true,
      planEvidenceVersion:null,
      resolutionRecord:null
    };
    cr17Cases.unshift(c);
  }
  return c;
}
function bj17HandoffUnknown(meta){
  onUnknownHandoff[meta.sourceFlow]?.();
  const c=bj17RecoveryCase(meta);
  cr17SelectedId=c.id;
  cr17ResolutionMode="";
  stateByScreen["SCR-079"]=c.evidence==="INSUFFICIENT"?"INSUFFICIENT_EVIDENCE":"UNKNOWN_EVIDENCE";
  return crSwitchFlow("UIF-17","SCR-079",stateByScreen["SCR-079"]);
}

function render078BJ17(state){return render078Shared(true,state);}

function render079BJ17(state){
  if(state==="PERMISSION_DENIED")return bj16Denied("Bằng chứng & kết luận",{centered:true});
  if(state==="LOADING")return bj16Loading("Bằng chứng & kết luận");
  const c=cr17Current(),actual=state==="READY"?cr079StateFor17(c):state;
  if(actual==="INSUFFICIENT_EVIDENCE")return ac310Return(appShell({title:"Bằng chứng kết quả",body:`${vBanner("warning","Chưa đủ bằng chứng để kết luận","Nghiệp vụ vẫn chưa xác định và phạm vi tiếp tục được bảo vệ.")}${ac310RecordRow({title:c.operation,subtitle:c.scope,badge:c.severity,tone:c.tone,status:true,leading:null})}${ac310InfoSurface("Hồ sơ",[["Người xử lý",c.owner],["Định danh nghiệp vụ","Giữ nguyên"]])}${bj16EvidenceSurface(bj17EvidenceRows(c))}`,actions:primaryFooter("Xem trạng thái xử lý",'data-cr17-action="show-escalated"')}));
  const committed=c.evidence==="COMMITTED";
  const banner=committed?vBanner("info","Đã tìm thấy tác động của nghiệp vụ","Bước tiếp theo chỉ xác lập kết quả; không ghi lại tác động lần hai."):vBanner("info","Chưa phát hiện tác động tồn kho","Có thể tiếp tục đúng lần xử lý này, giữ nguyên định danh và nội dung đã xác nhận.");
  return ac310Return(appShell({title:"Bằng chứng kết quả",body:`${banner}${ac310RecordRow({title:c.operation,subtitle:c.scope,badge:c.severity,tone:c.tone,status:true,leading:null})}${ac310InfoSurface("Hồ sơ",[["Người xử lý",c.owner],["Định danh nghiệp vụ","Giữ nguyên"]])}${bj16EvidenceSurface(bj17EvidenceRows(c))}`,actions:primaryFooter(committed?"Xem phương án xác lập":"Xem phương án tiếp tục",'data-cr17-action="open-plan"')}));
}

function render080BJ17(state){
  if(state==="PERMISSION_DENIED")return bj16Denied("Phương án xử lý",{centered:true});
  if(state==="LOCKED")return ac310SanitizeMarkup(appShell({title:"Phương án xử lý",body:vBanner("warning","Phạm vi đang do hồ sơ khác bảo vệ","Không xử lý song song cùng phạm vi. Mở hồ sơ đang bảo vệ để tiếp tục.")}));
  if(state==="CONFLICT")return ac310SanitizeMarkup(appShell({title:"Phương án xử lý",body:vBanner("warning","Kết luận đã thay đổi","Bằng chứng mới làm thay đổi phương án. Quay lại bước bằng chứng để rà soát.")}));
  const c=cr17Current();
  if(c.evidence==="INSUFFICIENT"||state==="INSUFFICIENT_EVIDENCE")return ac310Return(appShell({title:"Phương án xử lý",body:`${vBanner("warning","Chưa có phương án xử lý an toàn","Giữ trạng thái chưa xác định và bảo vệ phạm vi cho tới khi có thêm bằng chứng.")}${ac310InfoSurface("Phạm vi xử lý",[["Nghiệp vụ",c.operation,true],["Người xử lý",c.owner],["Lần xử lý","Giữ nguyên"]])}`,actions:primaryFooter("Xem trạng thái xử lý",'data-v350-action="cr17-show-escalated"')}));
  const committed=c.evidence==="COMMITTED",title=committed?"Xác lập đã hoàn tất":"Tiếp tục lần xử lý này";
  return ac310Return(appShell({title:"Phương án xử lý",body:`${vBanner("info",title,committed?"Dùng tác động đã tồn tại để xác lập kết quả; không ghi lại biến động lần hai.":"Tiếp tục cùng định danh sau khi đã xác nhận chưa có tác động bán phần.")}${ac310InfoSurface("Phạm vi",[["Nghiệp vụ",c.operation,true],["Phạm vi",c.scope],["Lần xử lý","Giữ nguyên"]])}${ac310InfoSurface("Không thực hiện",[["Tạo nghiệp vụ mới","Không"],["Tự hoàn nguyên","Không"],["Đổi nội dung đã xác nhận","Không"]])}`,actions:primaryFooter(title,'data-v350-action="cr17-execute-plan"')}));
}

function render082BJ17(state){
  if(state==="PERMISSION_DENIED")return bj16Denied("Rà soát kết quả",{centered:true});
  const c=cr17Current(),committed=(cr17ResolutionMode||c.evidence)==="COMMITTED",continued=(cr17ResolutionMode||"")==="CONTINUED";
  const rows=committed?[["Nghiệp vụ",c.operation,true],["Kết quả","Đã hoàn tất"],["Tác động tồn kho","Giữ tác động đã có"],["Lần xử lý","Không thay đổi"]]:[["Nghiệp vụ",c.operation,true],["Kết quả",continued?"Đã hoàn tất":"Đã có kết quả mới"],["Lần xử lý","Không thay đổi"],["Nghiệp vụ mới","Không tạo"]];
  return ac310Return(appShell({title:"Rà soát kết quả",body:`${vBanner("info","Kết quả đã được xác lập","Hệ thống giữ đúng nghiệp vụ ban đầu và không tạo tác động trùng.")}${ac310InfoSurface("Kết quả cuối",rows)}`,actions:primaryFooter("Hoàn tất xác minh",'data-v350-action="cr17-finish-review"')}));
}

function render083BJ17(state){
  if(state==="PERMISSION_DENIED")return ac310SanitizeMarkup(appShell({title:"Kết quả xử lý",body:deniedBody(),centered:true,back:false,actions:primaryFooter("Về danh sách",'data-v360-action="fallback-exit" data-v360-target="SCR-078"')}));
  if(state==="PROCESSING")return ac310SanitizeMarkup(appShell({title:"Kết quả xử lý",body:loadingBody(),centered:true,back:false}));
  const c=cr17Current();
  if(state==="UNKNOWN"||state==="ESCALATED")return ac310SanitizeMarkup(appShell({title:"Kết quả xác minh",body:ioResult("Chưa xác định — đã chuyển xử lý","Hệ thống chưa đoán kết quả. Phạm vi tiếp tục được bảo vệ và người có trách nhiệm đã nhận hồ sơ.",[["Nghiệp vụ",c.operation],["Người xử lý",c.owner],["Phạm vi","Tiếp tục được bảo vệ"]],"warning"),actions:primaryFooter("Về danh sách xác minh",'data-cr17-action="to-list"'),centered:true,back:false}));
  return ac310SanitizeMarkup(appShell({title:"Kết quả xác minh",body:ioResult("Đã xác lập kết quả nghiệp vụ","Kết quả chính thức đã được ghi cho đúng nghiệp vụ; không tạo nghiệp vụ mới hoặc ghi tác động trùng.",[["Nghiệp vụ",c.operation],["Lần xử lý","Giữ nguyên"],["Trạng thái","Đã hoàn tất"]]),actions:primaryFooter("Về danh sách xác minh",'data-cr17-action="to-list"'),centered:true,back:false}));
}

flowRenderers["UIF-17"]={
  "SCR-078":render078BJ17,
  "SCR-079":render079BJ17,
  "SCR-080":render080BJ17,
  "SCR-082":render082BJ17,
  "SCR-083":render083BJ17
};

document.addEventListener("input",(event)=>{
  if(activeFlowId!=="UIF-17")return;
  if(event.target.matches("[data-cr-control-search]")){crControlQuery=event.target.value;return renderAppScreen();}
},true);

document.addEventListener("click",(event)=>{
  if(activeFlowId==="UIF-17"){
    const f=event.target.closest("[data-cr17-filter]");if(f){event.preventDefault();cr17Filter=f.dataset.cr17Filter;return renderAppScreen();}
    const row=event.target.closest("[data-cr-case]");if(row){event.preventDefault();cr17SelectedId=row.dataset.crCase;stateByScreen["SCR-079"]=cr079StateFor17(cr17Current());return navigate("SCR-079");}
    const a17=event.target.closest("[data-cr17-action]");if(a17&&!a17.disabled){event.preventDefault();const k=a17.dataset.cr17Action;
      if(k==="open-plan"){const c=cr17Current();c.planEvidenceVersion=c.evidenceVersion;c.resolutionRecord=null;stateByScreen["SCR-080"]=c.evidence==="INSUFFICIENT"?"INSUFFICIENT_EVIDENCE":"READY";return navigate("SCR-080");}
      if(k==="show-escalated"){stateByScreen["SCR-083"]="ESCALATED";return navigate("SCR-083");}
      if(k==="to-list"){crControlQuery="";cr17ResolutionMode="";stateByScreen["SCR-078"]="READY";return navigate("SCR-078");}
    }
    const a=event.target.closest("[data-v350-action]");if(a&&!a.disabled){
      const k=a.dataset.v350Action;
      if(String(k||"").startsWith("cr17-")){
        event.preventDefault();event.stopPropagation();
        if(k==="cr17-execute-plan"){
          const c=cr17Current();if(!c.planEvidenceVersion)c.planEvidenceVersion=c.evidenceVersion;
          if(bj17Num(c.planEvidenceVersion)!==bj17Num(c.evidenceVersion)){stateByScreen["SCR-080"]="CONFLICT";return renderAppScreen();}
          cr17ResolutionMode=c.evidence==="COMMITTED"?"COMMITTED":"CONTINUED";
          c.resolutionRecord={operationId:c.operation,scope:c.scope,evidenceVersion:c.evidenceVersion,newOperationCreated:false,duplicateEffect:false,mode:cr17ResolutionMode};
          stateByScreen["SCR-082"]="READY";return navigate("SCR-082");
        }
        if(k==="cr17-finish-review"){
          const c=cr17Current(),r=c.resolutionRecord;if(!r||!bj17Same(r.operationId,c.operation)||!bj17Same(r.scope,c.scope)||bj17Num(r.evidenceVersion)!==bj17Num(c.evidenceVersion)||r.newOperationCreated||r.duplicateEffect){stateByScreen["SCR-080"]="CONFLICT";return navigate("SCR-080");}
          stateByScreen["SCR-083"]="COMPLETED";return navigate("SCR-083");
        }
        if(k==="cr17-show-escalated"){stateByScreen["SCR-083"]="ESCALATED";return navigate("SCR-083");}
      }
    }
  }
},true);

/* handoff-unknown: mọi luồng (nút nằm ở màn BJ khác) — không kiểm activeFlowId */
document.addEventListener("click",(event)=>{
  const a=event.target.closest('[data-v350-action="handoff-unknown"]');if(!a||a.disabled)return;
  event.preventDefault();event.stopPropagation();
  return bj17HandoffUnknown({sourceFlow:a.dataset.sourceFlow,operation:a.dataset.operation,scope:a.dataset.scope,evidence:"INSUFFICIENT"});
},true);

ownedFlows.add("UIF-17");
