/* BJ-16 — Điều tra và đối soát sai lệch (UIF-16). Màn: SCR-078…083.
 *
 * Đã viết lại sạch (T7-P gói A10, 2026-10-19). Màn dựng thẳng (ownedFlows).
 * Phần chung danh sách/helper bj16* dùng chung với BJ-17; crFactCard / ac321CanonicalChips → shared-control.js.
 * cr16-correction-handoff → UIF-11; listener data-v350-action cr16-* viết thẳng.
 */

let crControlQuery="";
let cr16Filter="ALL";
let cr16SelectedId="REC-260907-03";
const cr16Cases=[
  {id:"REC-260907-03",title:"Số liệu hiển thị lệch sổ kho",scope:"Nobivac DHPPi · Lô DH2507",severity:"Cần xử lý",tone:"warning",route:"PROJECTION",owner:"Kiểm soát kho",evidenceVersion:1,planEvidenceVersion:null,recoveryEvidenceVersion:null,closed:false},
  {id:"REC-260907-04",title:"Cần sửa nghiệp vụ nguồn",scope:"Amox 500 · Lô L2407-A",severity:"Đang chờ",tone:"info",route:"CORRECTION",owner:"Kiểm soát kho",evidenceVersion:1,planEvidenceVersion:null,recoveryEvidenceVersion:null,closed:false,correctionOperationId:"IO-260904-021"},
  {id:"REC-260907-05",title:"Chênh lệch do thời điểm ghi nhận",scope:"Găng tay M",severity:"Có thể đóng",tone:"info",route:"NO_REAL",owner:"Kiểm soát kho",evidenceVersion:1,planEvidenceVersion:null,recoveryEvidenceVersion:null,closed:false},
  {id:"REC-260907-06",title:"Cần kiểm tra toàn vẹn sổ kho",scope:"Kho trung tâm · SP-00606",severity:"Ưu tiên cao",tone:"warning",route:"LEDGER",owner:"Vận hành nền tảng",evidenceVersion:1,planEvidenceVersion:null,recoveryEvidenceVersion:null,closed:false},
  {id:"REC-260907-07",title:"Thông tin chứng từ nguồn chưa khớp",scope:"PN-260906-12",severity:"Đang chờ",tone:"info",route:"SOURCE",owner:"Nghiệp vụ nguồn",evidenceVersion:1,planEvidenceVersion:null,recoveryEvidenceVersion:null,closed:false}
];
function cr16Current(){return cr16Cases.find(x=>x.id===cr16SelectedId)||cr16Cases[0];}
function cr079StateFor16(c){return c.route==="PROJECTION"?"PROJECTION_MISMATCH":c.route==="CORRECTION"?"CORRECTION_REQUIRED":c.route==="NO_REAL"?"NO_REAL_DIFFERENCE":c.route==="LEDGER"?"LEDGER_INTEGRITY_RISK":"SOURCE_MISMATCH";}

const bj16Num=(v)=>Number(v??0);

function bj16Denied(title,{centered=true,back=true}={}){return ac310SanitizeMarkup(appShell({title,body:deniedBody(),centered,back}));}
function bj16Loading(title,{back=true}={}){return ac310SanitizeMarkup(appShell({title,body:loadingBody(),back}));}

function bj16CaseRows(is17){
  const cases=is17?cr17Cases:cr16Cases,filter=is17?cr17Filter:cr16Filter;
  const filtered=cases.filter((c)=>{if(filter==="ALL")return true;if(is17)return c.evidence===filter;if(filter==="ACTION")return ["PROJECTION","CORRECTION"].includes(c.route);if(filter==="WAITING")return c.route==="SOURCE";if(filter==="HIGH")return c.route==="LEDGER";return true;}).filter((c)=>ioMatchesSearch(crControlQuery,`${c.id} ${c.title} ${c.scope} ${c.operation||""}`));
  return filtered.map((c)=>ac310RecordRow({title:is17?(c.operation||c.id):c.id,subtitle:`${c.title} · ${c.scope}`,badge:c.severity,tone:c.tone,attrs:`data-cr-case="${c.id}"`,leading:null})).join("");
}
function bj16CaseListLegacy(is17){
  const cases=is17?cr17Cases:cr16Cases;const filter=is17?cr17Filter:cr16Filter;
  const chipItems=is17?[["ALL","Tất cả"],["COMMITTED","Đã có tác động"],["NO_COMMIT","Chưa có tác động"],["INSUFFICIENT","Cần chuyên sâu"]]:[["ALL","Tất cả"],["ACTION","Cần xử lý"],["WAITING","Đang chờ"],["HIGH","Ưu tiên cao"]];
  const filtered=cases.filter(c=>{if(filter==="ALL")return true;if(is17)return c.evidence===filter;if(filter==="ACTION")return ["PROJECTION","CORRECTION"].includes(c.route);if(filter==="WAITING")return ["SOURCE"].includes(c.route);if(filter==="HIGH")return c.route==="LEDGER";return true;}).filter(c=>ioMatchesSearch(crControlQuery,`${c.id} ${c.title} ${c.scope} ${c.operation||""}`));
  const rows=filtered.map(c=>ioProductRow({name:c.title,code:is17?(c.operation||""):c.id,primary:is17?"":"",secondary:c.scope,badge:c.severity,badgeStatus:c.tone,attr:`data-cr-case="${c.id}"`})).join("");
  return `${ioSearchBar(is17?"Tìm mã nghiệp vụ hoặc hàng":"Tìm hồ sơ, sản phẩm hoặc chứng từ",'data-cr-control-search',crControlQuery)}${ac321CanonicalChips(filter,chipItems,is17?'data-cr17-filter':'data-cr16-filter')}${rows?`<div class="io-list-card" data-ds-component="VSection" data-composed-from="DS v2 / List Row,VBadge"><div class="io-product-list cr-case-list">${rows}</div></div>`:ioEmpty("Không có hồ sơ phù hợp","Thử đổi bộ lọc hoặc từ khóa tìm kiếm.")}`;
}
function bj16EvidenceCard(rows){const calibrated=FIGMA_MIGRATED_FLOWS.has(activeFlowId);return `<section class="review-card cr-evidence" data-ds-component="${calibrated?'VSection':'VCard'}" ${calibrated?'data-composed-from="DS v2 / Info Row"':'data-ds-profile="card.readOnly"'}><div class="review-card-body">${rows.map(r=>`<div class="cr-evidence-row" ${calibrated?'data-ds-component="DS v2 / Info Row" data-figma-node="525:351"':''}><span data-ds-component="VText">${r[0]}</span><strong data-ds-component="VText">${r[1]}</strong></div>`).join("")}</div></section>`;}
function bj16EvidenceRows(c){
  if(c.route==="PROJECTION")return [["Nguồn nghiệp vụ","118 hộp · đã xác nhận"],["Sổ kho","118 hộp · khớp nguồn"],["Số liệu hiển thị","116 hộp · lệch −2"]];
  if(c.route==="CORRECTION")return [["Nguồn nghiệp vụ","120 hộp"],["Sổ kho","120 hộp"],["Kiểm tra thực tế","118 hộp · cần sửa nghiệp vụ"]];
  if(c.route==="NO_REAL")return [["Nguồn nghiệp vụ","118 hộp"],["Sổ kho","118 hộp"],["Báo cáo tại thời điểm cũ","116 hộp · khác do mốc thời gian"]];
  if(c.route==="LEDGER")return [["Nguồn nghiệp vụ","Có chứng từ"],["Sổ kho","Có dấu hiệu không nhất quán"],["Số liệu hiển thị","Không dùng để dựng lại sổ kho"]];
  return [["Chứng từ nguồn","Chưa khớp dữ liệu kho"],["Sổ kho","Chưa kết luận"],["Trạng thái","Đang chờ nghiệp vụ nguồn xác minh"]];
}
function bj16EvidenceSurface(rows){return ac310InfoSurface("Bằng chứng",rows.map((r)=>[r[0],r[1],String(r[1]).includes("lệch")||String(r[1]).includes("không nhất quán")]));}

function render078Shared(is17,state){
  const title=is17?"Nghiệp vụ cần xác minh":"Đối soát sai lệch";
  if(state==="PERMISSION_DENIED")return bj16Denied(title,{centered:true,back:false});
  if(state==="LOADING")return bj16Loading(title,{back:false});
  if(state==="EMPTY")return ac310SanitizeMarkup(appShell({title,body:ioEmpty(is17?"Không có nghiệp vụ cần xác minh":"Không có hồ sơ đối soát","Danh sách sẽ cập nhật khi có tín hiệu cần kiểm tra."),back:false}));
  if(state==="READY"){
    const filter=is17?cr17Filter:cr16Filter;
    const chipItems=is17?[["ALL","Tất cả"],["COMMITTED","Đã có tác động"],["NO_COMMIT","Chưa có tác động"],["INSUFFICIENT","Cần chuyên sâu"]]:[["ALL","Tất cả"],["ACTION","Cần xử lý"],["WAITING","Đang chờ"],["HIGH","Ưu tiên cao"]];
    const rows=bj16CaseRows(is17);
    const body=`${ds24Search(crControlQuery,"data-cr-control-search",is17?"Tìm mã nghiệp vụ hoặc hàng":"Tìm hồ sơ, sản phẩm hoặc chứng từ")}<div class="ds24-chip-scroll">${chipItems.map(([k,l])=>ds24Chip(k,l,filter===k,is17?"data-cr17-filter":"data-cr16-filter")).join("")}</div>${rows?ac310ListSurface(rows):ioEmpty("Không có hồ sơ phù hợp","Thử đổi bộ lọc hoặc từ khóa tìm kiếm.")}`;
    return ac310Return(appShell({title,body,back:false}));
  }
  return ac310SanitizeMarkup(appShell({title,body:bj16CaseListLegacy(is17),back:false}));
}
function render078BJ16(state){return render078Shared(false,state);}

function render079BJ16(state){
  if(state==="PERMISSION_DENIED")return bj16Denied("Bằng chứng & kết luận",{centered:true});
  if(state==="LOADING")return bj16Loading("Bằng chứng & kết luận");
  const c=cr16Current();const actual=state==="READY"?cr079StateFor16(c):state;
  if(actual==="SOURCE_MISMATCH")return appShell({title:"Bằng chứng & kết luận",body:`${vBanner("info","Đang chờ nghiệp vụ nguồn xác minh","Kho không tự sửa dữ liệu nguồn. Chuyển đúng hồ sơ và phạm vi cho phân hệ sở hữu nguồn.")}${crFactCard(c.id,[["Phạm vi",c.scope,true],["Người xử lý hiện tại",c.owner],["Bảo vệ phạm vi","Đang áp dụng"]])}${bj16EvidenceCard(bj16EvidenceRows(c))}`,actions:primaryFooter("Chuyển cho nghiệp vụ nguồn",'data-v350-action="cr16-source-handoff"')});
  if(actual==="CORRECTION_REQUIRED")return appShell({title:"Bằng chứng & kết luận",body:`${vBanner("warning","Cần sửa nghiệp vụ đã hoàn tất","Sai lệch nằm ở nghiệp vụ nguồn. Không chỉnh số dư trực tiếp.")}${crFactCard(c.id,[["Phạm vi",c.scope,true],["Người xử lý",c.owner]])}${bj16EvidenceCard(bj16EvidenceRows(c))}`,actions:primaryFooter("Mở yêu cầu sửa sai",'data-v350-action="cr16-correction-handoff"')});
  let banner="",actions="";
  if(actual==="PROJECTION_MISMATCH"){banner=vBanner("info","Sổ kho đúng, số liệu hiển thị sai","Chỉ số liệu hiển thị cần được khôi phục.");actions=primaryFooter("Khôi phục số liệu hiển thị",'data-v350-action="cr16-open-plan"');}
  else if(actual==="NO_REAL_DIFFERENCE"){banner=vBanner("info","Không có sai lệch tồn kho thực","Khác biệt đến từ thời điểm lấy số liệu.");actions=primaryFooter("Rà soát đóng hồ sơ",'data-v350-action="cr16-review-close"');}
  else if(actual==="LEDGER_INTEGRITY_RISK"){banner=vBanner("warning","Cần kiểm tra toàn vẹn sổ kho","Tạm dừng khôi phục tự động và sửa sai.");actions=primaryFooter("Xem trạng thái chuyển xử lý",'data-cr16-action="show-escalated"');}
  else banner=vBanner("warning","Chưa đủ bằng chứng kết luận","Giữ hồ sơ mở cho tới khi xác định được nguyên nhân.");
  return ac310Return(appShell({title:"Bằng chứng & kết luận",body:`${banner}${ac310RecordRow({title:c.id,subtitle:c.scope,badge:c.severity,tone:c.tone,status:true,leading:null})}${ac310InfoSurface("Hồ sơ",[["Người xử lý",c.owner],["Bảo vệ phạm vi",c.route==="NO_REAL"?"Không cần":"Đang áp dụng"]])}${bj16EvidenceSurface(bj16EvidenceRows(c))}`,actions}));
}

function render080BJ16(state){
  if(state==="PERMISSION_DENIED")return bj16Denied("Phương án xử lý",{centered:true});
  if(state==="LOCKED")return ac310SanitizeMarkup(appShell({title:"Phương án xử lý",body:vBanner("warning","Phạm vi đang do hồ sơ khác bảo vệ","Không xử lý song song cùng phạm vi. Mở hồ sơ đang bảo vệ để tiếp tục.")}));
  if(state==="CONFLICT")return ac310SanitizeMarkup(appShell({title:"Phương án xử lý",body:vBanner("warning","Kết luận đã thay đổi","Bằng chứng mới làm thay đổi phương án. Quay lại bước bằng chứng để rà soát.")}));
  const c=cr16Current();
  return ac310Return(appShell({title:"Phương án xử lý",body:`${vBanner("info","Khôi phục số liệu hiển thị","Sổ kho đã đúng; chỉ khôi phục dữ liệu hiển thị trong phạm vi này.")}${ac310InfoSurface("Phạm vi",[["Hồ sơ",c.id,true],["Hàng",c.scope],["Bảo vệ phạm vi","Đang áp dụng"]])}${ac310InfoSurface("Tác động",[["Sổ kho","Không thay đổi"],["Nghiệp vụ nguồn","Không thay đổi"],["Số liệu hiển thị","Khôi phục theo sổ kho"]])}`,actions:primaryFooter("Bắt đầu khôi phục",'data-v350-action="cr16-start-recovery"')}));
}

function render081BJ16(state){
  if(state==="PERMISSION_DENIED")return bj16Denied("Khôi phục số liệu",{centered:true});
  if(state==="VALIDATION_FAILED"||state==="CONFLICT")return ac310SanitizeMarkup(appShell({title:"Khôi phục số liệu",body:`${vBanner("warning","Chưa thể hoàn tất khôi phục","Bằng chứng hoặc phạm vi đã thay đổi. Hồ sơ vẫn được giữ mở và sổ kho không bị sửa.")}${crFactCard(cr16Current().id,[["Phạm vi",cr16Current().scope,true],["Sổ kho","Không thay đổi"]])}`}));
  const c=cr16Current();
  if(state==="READY")return ac310Return(appShell({title:"Khôi phục số liệu",body:`${vBanner("success","Đã khôi phục số liệu hiển thị","Kết quả sẵn sàng để rà soát trước khi đóng hồ sơ.")}${ac310InfoSurface("Hồ sơ",[["Mã",c.id,true],["Phạm vi",c.scope],["Sổ kho","Không thay đổi"],["Số liệu hiển thị","Đã cập nhật"]])}`,actions:primaryFooter("Rà soát kết quả",'data-v350-action="cr16-review-result"')}));
  if(state==="REBUILDING"){
    const progress=`<section class="ac310-progress-block"><div class="ac310-progress" data-ds-component="VProgress"><div class="ac310-progress__bar"><span style="width:68%"></span></div></div><strong>Đang khôi phục số liệu hiển thị</strong><small>Bạn có thể rời màn hình; hồ sơ tự cập nhật khi hoàn tất.</small></section>`;
    return ac310Return(appShell({title:"Đang khôi phục số liệu",body:`${progress}${ac310InfoSurface("Hồ sơ",[["Mã",c.id,true],["Phạm vi",c.scope],["Sổ kho","Không thay đổi"]])}`}));
  }
  return ac310SanitizeMarkup(appShell({title:"Đang khôi phục số liệu",body:`${loadingBody()}${vBanner("info","Hệ thống đang xử lý","Bạn có thể rời màn hình. Hồ sơ sẽ cập nhật khi dữ liệu hiển thị đã được khôi phục.")}${crFactCard(c.id,[["Phạm vi",c.scope,true],["Sổ kho","Không thay đổi"]])}`}));
}

function render082BJ16(state){
  if(state==="PERMISSION_DENIED")return bj16Denied("Rà soát kết quả",{centered:true});
  if(state==="MISMATCH_REMAINS")return appShell({title:"Rà soát kết quả",body:`${vBanner("warning","Sai lệch vẫn còn","Giữ hồ sơ mở và phạm vi được bảo vệ. Quay lại bằng chứng để tiếp tục điều tra.")}${crFactCard(cr16Current().id,[["Sổ kho","118 hộp"],["Số liệu hiển thị","117 hộp"],["Chênh lệch","−1 hộp",true]])}`,actions:primaryFooter("Quay lại bằng chứng",'data-v350-action="cr16-back-evidence"')});
  const c=cr16Current();const noReal=c.route==="NO_REAL";
  return ac310Return(appShell({title:"Rà soát kết quả",body:`${vBanner("info",noReal?"Không có sai lệch thực":"Số liệu đã khớp",noReal?"Khác biệt trước đó được giải thích bằng mốc thời gian.":"Số liệu hiển thị hiện khớp với sổ kho.")}${ac310KeyValueSurface(c.id,[["Sổ kho","118 hộp"],["Số liệu hiển thị","118 hộp"],["Chênh lệch","0 hộp",true],["Phạm vi",noReal?"Không khóa":"Sẵn sàng mở khóa"]])}`,actions:primaryFooter("Đóng hồ sơ & mở khóa",'data-v350-action="cr16-close-case"')}));
}

function render083BJ16(state){
  if(state==="PERMISSION_DENIED")return ac310SanitizeMarkup(appShell({title:"Kết quả xử lý",body:deniedBody(),centered:true,back:false,actions:primaryFooter("Về danh sách",'data-v360-action="fallback-exit" data-v360-target="SCR-078"')}));
  if(state==="PROCESSING")return ac310SanitizeMarkup(appShell({title:"Kết quả xử lý",body:loadingBody(),centered:true,back:false}));
  const c=cr16Current();
  if(state==="UNKNOWN"||state==="ESCALATED")return ac310SanitizeMarkup(appShell({title:"Kết quả đối soát",body:ioResult("Đã chuyển xử lý chuyên sâu","Hồ sơ vẫn mở; phạm vi rủi ro tiếp tục được bảo vệ cho tới khi có bằng chứng mới.",[["Hồ sơ",c.id],["Người xử lý",c.owner],["Phạm vi","Chưa mở khóa"]],"warning"),actions:primaryFooter("Về danh sách đối soát",'data-cr16-action="to-list"'),centered:true,back:false}));
  return ac310SanitizeMarkup(appShell({title:"Kết quả đối soát",body:ioResult("Đã xử lý sai lệch","Hồ sơ được đóng bằng bằng chứng và phạm vi liên quan đã được mở khóa.",[["Hồ sơ",c.id],["Kết luận",c.route==="NO_REAL"?"Không có sai lệch thực":"Số liệu đã khớp"],["Phạm vi","Đã mở khóa"]]),actions:primaryFooter("Về danh sách đối soát",'data-cr16-action="to-list"'),centered:true,back:false}));
}

flowRenderers["UIF-16"]={
  "SCR-078":render078BJ16,
  "SCR-079":render079BJ16,
  "SCR-080":render080BJ16,
  "SCR-081":render081BJ16,
  "SCR-082":render082BJ16,
  "SCR-083":render083BJ16
};
["SCR-078","SCR-079","SCR-080","SCR-081","SCR-082","SCR-083"].forEach((id)=>{renderers[id]=flowScreen(id);});

document.addEventListener("input",(event)=>{
  if(activeFlowId!=="UIF-16")return;
  if(event.target.matches("[data-cr-control-search]")){crControlQuery=event.target.value;return renderAppScreen();}
},true);

document.addEventListener("click",(event)=>{
  if(activeFlowId!=="UIF-16")return;
  const f=event.target.closest("[data-cr16-filter]");if(f){event.preventDefault();cr16Filter=f.dataset.cr16Filter;return renderAppScreen();}
  const row=event.target.closest("[data-cr-case]");if(row){event.preventDefault();cr16SelectedId=row.dataset.crCase;stateByScreen["SCR-079"]=cr079StateFor16(cr16Current());return navigate("SCR-079");}
  const a16=event.target.closest("[data-cr16-action]");if(a16&&!a16.disabled){event.preventDefault();const k=a16.dataset.cr16Action;
    if(k==="show-escalated"){stateByScreen["SCR-083"]="ESCALATED";return navigate("SCR-083");}
    if(k==="to-list"){crControlQuery="";stateByScreen["SCR-078"]="READY";return navigate("SCR-078");}
  }
  const a=event.target.closest("[data-v350-action]");if(!a||a.disabled)return;
  const k=a.dataset.v350Action;if(!String(k||"").startsWith("cr16-"))return;
  event.preventDefault();event.stopPropagation();
  if(k==="cr16-correction-handoff"){const c=cr16Current();const opId=c.correctionOperationId;if(!opId)return;cr11SelectedId=opId;stateByScreen["SCR-049"]="CORRECTABLE";return crSwitchFlow("UIF-11","SCR-049","CORRECTABLE");}
  if(k==="cr16-source-handoff"){stateByScreen["SCR-083"]="ESCALATED";return navigate("SCR-083");}
  if(k==="cr16-open-plan"){const c=cr16Current();c.planEvidenceVersion=c.evidenceVersion;stateByScreen["SCR-080"]="READY";return navigate("SCR-080");}
  if(k==="cr16-start-recovery"){const c=cr16Current();if(bj16Num(c.planEvidenceVersion)!==bj16Num(c.evidenceVersion)){stateByScreen["SCR-080"]="CONFLICT";return renderAppScreen();}c.recoveryEvidenceVersion=c.evidenceVersion;stateByScreen["SCR-081"]="REBUILDING";navigate("SCR-081");setTimeout(()=>{if(activeFlowId==="UIF-16"&&activeScreenId==="SCR-081"){const cc=cr16Current();stateByScreen["SCR-081"]=bj16Num(cc.recoveryEvidenceVersion)===bj16Num(cc.evidenceVersion)?"READY":"CONFLICT";render();}},250);return;}
  if(k==="cr16-review-result"){const c=cr16Current();if(bj16Num(c.recoveryEvidenceVersion)!==bj16Num(c.evidenceVersion)){stateByScreen["SCR-081"]="CONFLICT";return renderAppScreen();}stateByScreen["SCR-082"]="READY";return navigate("SCR-082");}
  if(k==="cr16-review-close"){const c=cr16Current();c.planEvidenceVersion=c.evidenceVersion;stateByScreen["SCR-082"]="READY";return navigate("SCR-082");}
  if(k==="cr16-close-case"){const c=cr16Current();const snap=c.recoveryEvidenceVersion??c.planEvidenceVersion;if(bj16Num(snap)!==bj16Num(c.evidenceVersion)){stateByScreen["SCR-082"]="MISMATCH_REMAINS";return renderAppScreen();}c.closed=true;stateByScreen["SCR-083"]="COMPLETED";return navigate("SCR-083");}
  if(k==="cr16-back-evidence"){stateByScreen["SCR-079"]=cr079StateFor16(cr16Current());return navigate("SCR-079");}
},true);

ownedFlows.add("UIF-16");
