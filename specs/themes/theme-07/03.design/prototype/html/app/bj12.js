/* BJ-12 — Khởi tạo tồn đầu kỳ (UIF-12). Màn: SCR-066…071.
 *
 * Đã viết lại sạch (T7-P gói A8, 2026-10-17). Màn dựng thẳng (ownedFlows).
 * Helper chung ac310* / cfMoney / cfField / … → app/shared-control.js.
 * Sửa nút Từ chối (data-v350-action="cf12-confirm-reject").
 */

let cf12FileName = "ton-kho-dau-ky-2026.xlsx";
let cf12Cutoff = "2026-08-31";
let cf12ControlQty = "4820";
let cf12ControlValue = "386240000";
let cf12RejectOpen = false;
let cf12RejectReason = "";
const cf12Summary = { rows: 82, products: 36, parsedQty: 4820, parsedValue: 386240000, sellableRows: 74, nonSellableRows: 8 };

function cf12ReviewCard(){
  return `${crFactCard("Phạm vi khởi tạo",[["Kho","Kho trung tâm",true],["Ngày chốt số dư",cfDateVN(cf12Cutoff)],["Sản phẩm",`${cfNumber(cf12Summary.products)} sản phẩm`],["Dòng dữ liệu",`${cfNumber(cf12Summary.rows)} dòng`]])}${crFactCard("Số kiểm soát",[["Tổng số lượng",cfNumber(cf12ControlQty),true],["Tổng giá trị",cfMoney(cf12ControlValue),true],["Đối chiếu tệp","Khớp số kiểm soát"]])}`;
}
function cf12RejectSheet(){
  if(!cf12RejectOpen)return "";
  return `<div class="sheet-backdrop" data-cf12-action="close-reject"><section class="bottom-sheet cf12-reject-sheet" role="dialog" aria-modal="true" aria-label="Từ chối số dư đầu kỳ" onclick="event.stopPropagation()" data-ds-component="VBottomSheet" data-figma-node="4695:6353"><div class="sheet-handle"></div><div class="sheet-title"><h3>Từ chối số dư đầu kỳ</h3></div><div class="sheet-divider"></div><div class="sheet-content">${icTextarea("Lý do từ chối",cf12RejectReason,'data-cf12-reject-reason','Nhập nội dung người lập cần sửa')}<div class="sheet-actions">${cfSecondary("Hủy",'data-cf12-action="close-reject"')}<button class="button button--primary" type="button" data-v350-action="cf12-confirm-reject" data-ds-component="VButton" ${cf12RejectReason.trim()?"":"disabled"}>Xác nhận từ chối</button></div></div></section></div>`;
}
function bj12FileDrop(title,fileName,attrs=""){
  return `<section class="ac310-file-drop" data-ds-component="VFileDropZone"><div class="ac310-file-drop__icon">${icon("fileText")}</div><div class="ac310-file-drop__copy"><strong>${esc(title)}</strong><small>${esc(fileName||"Chưa chọn tệp")}</small></div><button type="button" class="button button--secondary" ${attrs} data-ds-component="VButton">Chọn tệp</button></section>`;
}
function bj12Result(title,desc,rows,tone="success"){
  return ioResult(title,desc,rows,tone);
}
function bj12IssueRow(title,detail){return ac310RecordRow({title,subtitle:detail,badge:"Cần sửa",tone:"Warning",status:true,leading:null});}
function bj12Cf12Review(){
  return ac310InfoSurface("Số dư đầu kỳ",[["Kho","Kho trung tâm"],["Ngày chốt",cfDateVN(cf12Cutoff),true],["Dòng dữ liệu",cfNumber(cf12Summary.rows)],["Sản phẩm",cfNumber(cf12Summary.products)],["Tổng số lượng",cfNumber(cf12Summary.parsedQty)],["Tổng giá trị",cfMoney(cf12Summary.parsedValue),true]]);
}

function bj12KeyValueSurface(title,rows,{extraClass=""}={}){
  const head=title?`<div class="ac310-surface__head"><h2>${esc(title)}</h2></div>`:"";
  const body=(rows||[]).map((r)=>{
    let v=String(r[1]??"");
    if(/^-\s?\d/.test(v)) v=v.replace(/^-\s?/,"−");
    const attention=r[2] && /^(Điều chỉnh|Chênh lệch)$/.test(String(r[0]||""));
    const cls=attention?" ds24-key-value-row v470-kv--attention":" ds24-key-value-row";
    return `<div class="${cls.trim()}" data-ds-component="DS v2 / Key-value Row"><span>${esc(r[0])}</span><strong>${esc(v)}</strong></div>`;
  }).join("");
  return `<section class="ac310-surface ${extraClass}" data-layout-pattern="Grouped surface" data-composed-from="DS v2 / Key-value Row">${head}<div class="ac310-key-value-stack">${body}</div></section>`;
}
function bj12ApprovalHash(){return [cf12FileName,cf12Cutoff,cf12ControlQty,cf12ControlValue,cf12Summary.rows,cf12Summary.parsedQty,cf12Summary.parsedValue].join("|");}
function bj12Hash(){return bj12ApprovalHash();}
function bj12ControlMatches(){return Number(cf12ControlQty)===Number(cf12Summary.parsedQty)&&Number(cf12ControlValue)===Number(cf12Summary.parsedValue);}
let bj12Cf12ApprovalHash=null;
function bj12UnknownResult({title="Kết quả chưa xác định",description="Không gửi lại thao tác. Chuyển đúng lần xử lý này sang xác minh kết quả.",operation,scope,sourceFlow}){
  const body=ioResult(title,description,[["Nghiệp vụ",operation],["Phạm vi",scope],["Trạng thái","Chưa kết luận"]],"warning");
  const attrs=`data-v350-action="handoff-unknown" data-source-flow="${escapeAttribute(sourceFlow)}" data-operation="${escapeAttribute(operation)}" data-scope="${escapeAttribute(scope)}"`;
  return appShell({title:"Xác minh kết quả",body,actions:primaryFooter("Chuyển sang xác minh",attrs),centered:true,back:false});
}
function bj12ExitList(){return primaryFooter("Về danh sách",'data-v360-action="fallback-exit" data-v360-target="SCR-066"');}


function render066BJ12(state){
  if(["READY","PENDING_APPROVAL","REJECTED","ACTIVE_RECONCILED"].includes(state)){
    if(state==="ACTIVE_RECONCILED") return ac310Return(appShell({title:"Khởi tạo tồn kho",body:bj12Result("Tồn kho đầu kỳ đã sẵn sàng","Số dư đầu kỳ đã được ghi nhận và đối chiếu.",[["Ngày chốt",cfDateVN(cf12Cutoff)],["Sản phẩm",`${cfNumber(cf12Summary.products)} sản phẩm`],["Đối soát","Đã khớp"]]),actions:primaryFooter("Xem tồn kho",'data-cf12-action="see-inventory"'),centered:true,back:false}));
    if(state==="PENDING_APPROVAL") return ac310Return(appShell({title:"Khởi tạo tồn kho",body:`${vBanner("info","Đang chờ duyệt","Bạn đã hoàn tất phần chuẩn bị. Tồn kho chưa thay đổi.")}${ac310InfoSurface("Yêu cầu",[["Kho","Kho trung tâm"],["Ngày chốt",cfDateVN(cf12Cutoff)],["Trạng thái","Chờ duyệt"]])}`,back:false}));
    if(state==="REJECTED") return ac310Return(appShell({title:"Khởi tạo tồn kho",body:`${vBanner("warning","Yêu cầu cần chỉnh sửa","Người duyệt đã trả lại dữ liệu. Tồn kho chưa thay đổi.")}${ac310InfoSurface("Yêu cầu",[["Kho","Kho trung tâm"],["Ngày chốt",cfDateVN(cf12Cutoff)],["Trạng thái","Cần chỉnh sửa"]])}`,actions:primaryFooter("Chỉnh dữ liệu",'data-cf12-action="fix-rejected"'),back:false}));
    return ac310Return(appShell({title:"Khởi tạo tồn kho",body:`${ac310InfoSurface("Khởi tạo lần đầu",[["Kho","Kho trung tâm",true],["Trạng thái","Chưa thiết lập"],["Nguyên tắc","Chỉ có một số dư đầu kỳ chính thức"]])}<p class="ac310-note">Sau khi hoàn tất, mọi sửa sai được thực hiện bằng nghiệp vụ điều chỉnh có kiểm soát.</p>`,actions:primaryFooter("Bắt đầu",'data-cf12-action="start"'),back:false}));
  }
  if(state==="UNKNOWN") return bj12UnknownResult({sourceFlow:"UIF-12",operation:"Khởi tạo tồn kho đầu kỳ",scope:`Kho trung tâm · ${cfDateVN(cf12Cutoff)}`});
  if(state==="PERMISSION_DENIED") return ac310SanitizeMarkup(appShell({title:"Khởi tạo tồn kho",body:deniedBody(),centered:true,back:false}));
  if(state==="LOADING") return ac310SanitizeMarkup(appShell({title:"Khởi tạo tồn kho",body:loadingBody(),back:false}));
  if(state==="PREPARING") return ac310SanitizeMarkup(appShell({title:"Khởi tạo tồn kho",body:`${vBanner("info","Đang chuẩn bị số dư đầu kỳ","Tệp và số kiểm soát đã được giữ lại. Tiếp tục rà soát dữ liệu trước khi gửi phê duyệt.")}${cf12ReviewCard()}`,actions:primaryFooter("Tiếp tục chuẩn bị",'data-cf12-action="continue-prepare"'),back:false}));
  return ac310SanitizeMarkup(appShell({title:"Khởi tạo tồn kho",body:loadingBody(),back:false}));
}


function render067BJ12(state){
  if(["READY","VALIDATION_ERROR"].includes(state)){
    const invalid=state==="VALIDATION_ERROR";
    const body=`${invalid?vBanner("error","Chưa đủ dữ liệu kiểm soát","Chọn tệp, ngày chốt và nhập đủ hai số kiểm soát trước khi kiểm tra."):""}${bj12FileDrop("Tệp số dư đầu kỳ",cf12FileName,'data-cf12-action="choose-file"')}<div class="ac310-form-stack">${ac310Field("Ngày chốt số dư",cf12Cutoff,'data-cf12-cutoff','Ngày nghiệp vụ mà số dư đầu kỳ có hiệu lực.',"date")}${ac310Field("Tổng số lượng kiểm soát",cf12ControlQty,'data-cf12-control-qty','Nhập từ nguồn kiểm soát độc lập.',"number")}${ac310Field("Tổng giá trị kiểm soát",cf12ControlValue,'data-cf12-control-value','Giá trị tồn kho đầu kỳ theo nguồn kiểm soát.',"text")}</div>`;
    const disabled=!cf12FileName||!cf12Cutoff||!(Number(cf12ControlQty)>=0)||!(Number(cf12ControlValue)>=0);
    return ac310Return(appShell({title:"Dữ liệu tồn kho đầu kỳ",body,actions:primaryFooter("Kiểm tra dữ liệu",'data-v350-action="cf12-check"',disabled)}));
  }
  if(state==="PERMISSION_DENIED") return ac310SanitizeMarkup(appShell({title:"Dữ liệu tồn kho đầu kỳ",body:deniedBody(),centered:true}));
  if(state==="LOCKED") return ac310SanitizeMarkup(appShell({title:"Dữ liệu tồn kho đầu kỳ",body:`${vBanner("info","Dữ liệu đang được xử lý","Tệp nguồn và số kiểm soát hiện chỉ đọc.")}${cf12ReviewCard()}`}));
  if(state==="CONFLICT") return ac310SanitizeMarkup(appShell({title:"Dữ liệu tồn kho đầu kỳ",body:`${vBanner("warning","Phạm vi vừa thay đổi","Không tiếp tục trên dữ liệu cũ. Tải lại thông tin hiện hành trước khi kiểm tra tệp.")}${cf12ReviewCard()}`}));
  return ac310SanitizeMarkup(appShell({title:"Dữ liệu tồn kho đầu kỳ",body:deniedBody(),centered:true}));
}


function render068BJ12(state){
  if(state==="CONTROL_TOTAL_MISMATCH"){
    // v350 body — no sanitize (plan 2.3 / 7.3)
    const dq=Number(cf12ControlQty)-Number(cf12Summary.parsedQty),dv=Number(cf12ControlValue)-Number(cf12Summary.parsedValue);
    const body=`${vBanner("warning","Số kiểm soát không khớp","Không gửi phê duyệt cho đến khi tệp chi tiết khớp nguồn kiểm soát độc lập.")}${crFactCard("Đối chiếu số lượng",[["Theo tệp",cfNumber(cf12Summary.parsedQty),true],["Số kiểm soát",cfNumber(cf12ControlQty),true],["Chênh lệch",`${dq>0?"+":""}${cfNumber(dq)}`]])}${crFactCard("Đối chiếu giá trị",[["Theo tệp",cfMoney(cf12Summary.parsedValue),true],["Số kiểm soát",cfMoney(cf12ControlValue),true],["Chênh lệch",cfMoney(dv)]])}`;
    return appShell({title:"Kiểm tra dữ liệu",body,actions:primaryFooter("Sửa số kiểm soát",'data-cf12-action="back-file"')});
  }
  if(["READY","VALIDATION_FAILED"].includes(state)){
    if(state==="VALIDATION_FAILED"){
      const issues=ac310ListSurface(`${bj12IssueRow("Dòng 18 · Vaccine Newcastle","Chưa xác định sản phẩm")}${bj12IssueRow("Dòng 44 · Amox 500","Trùng cùng sản phẩm + kho + tình trạng + lô")}${bj12IssueRow("Dòng 61 · Nobivac DHPPi","Thiếu hạn dùng bắt buộc")}`,"ac310-validation-list");
      return ac310Return(appShell({title:"Kết quả kiểm tra dữ liệu",body:`${vBanner("error","Còn dòng chưa hợp lệ","Không có dữ liệu nào được ghi nhận. Sửa dữ liệu nguồn rồi kiểm tra lại.")}${ac310SummaryMetrics([["Dòng đọc được",cfNumber(cf12Summary.rows)],["Sản phẩm",cfNumber(cf12Summary.products)],["Lỗi cần sửa","3"]])}${ac310SectionTitle("Dòng cần sửa")}${issues}`,actions:primaryFooter("Chọn lại tệp",'data-cf12-action="back-file"')}));
    }
    return ac310Return(appShell({title:"Kết quả kiểm tra dữ liệu",body:`${vBanner("success","Dữ liệu đã qua kiểm tra","Tệp chi tiết khớp số kiểm soát và không còn lỗi bắt buộc.")}${ac310SummaryMetrics([["Dòng dữ liệu",cfNumber(cf12Summary.rows)],["Sản phẩm",cfNumber(cf12Summary.products)],["Tổng số lượng",cfNumber(cf12Summary.parsedQty)]])}${ac310InfoSurface("Kiểm tra chính",[["Số âm","Không có"],["Dòng trùng","Không có"],["Lô / hạn dùng","Hợp lệ"],["Số kiểm soát","Đã khớp",true]])}`,actions:primaryFooter("Rà soát số dư",'data-cf12-action="review"')}));
  }
  if(state==="PERMISSION_DENIED") return ac310SanitizeMarkup(appShell({title:"Kết quả kiểm tra dữ liệu",body:deniedBody(),centered:true}));
  if(state==="LOADING") return ac310SanitizeMarkup(appShell({title:"Kết quả kiểm tra dữ liệu",body:loadingBody()}));
  if(state==="CONFLICT") return ac310SanitizeMarkup(appShell({title:"Kết quả kiểm tra dữ liệu",body:`${vBanner("warning","Nguồn dữ liệu đã thay đổi","Kết quả kiểm tra cũ không còn hiệu lực. Chọn lại tệp hoặc tải lại phạm vi.")}${cf12ReviewCard()}`,actions:primaryFooter("Quay lại dữ liệu",'data-cf12-action="back-file"')}));
  return ac310SanitizeMarkup(appShell({title:"Kết quả kiểm tra dữ liệu",body:loadingBody()}));
}


function render069BJ12(state){
  if(["READY","PENDING_APPROVAL"].includes(state)){
    const pending=state==="PENDING_APPROVAL"?vBanner("info","Đã gửi chờ duyệt","Bạn đã hoàn tất phần chuẩn bị. Tồn kho chưa thay đổi."):"";
    const body=`${pending}${bj12Cf12Review()}${ac310InfoSurface("Phân bố dữ liệu",[["Bán được",`${cfNumber(cf12Summary.sellableRows)} dòng`,true],["Không bán được",`${cfNumber(cf12Summary.nonSellableRows)} dòng`],["Lô / hạn dùng","Giữ theo cấu hình sản phẩm"]])}`;
    return ac310Return(appShell({title:"Rà soát số dư đầu kỳ",body,actions:state==="READY"?primaryFooter("Gửi phê duyệt",'data-v350-action="cf12-send-approval"'):""}));
  }
  if(state==="PERMISSION_DENIED") return ac310SanitizeMarkup(appShell({title:"Rà soát số dư đầu kỳ",body:deniedBody(),centered:true}));
  if(state==="CONFLICT") return ac310SanitizeMarkup(appShell({title:"Rà soát số dư đầu kỳ",body:`${vBanner("warning","Dữ liệu vừa thay đổi","Quay lại kiểm tra nguồn hiện hành trước khi gửi phê duyệt.")}${cf12ReviewCard()}`,actions:primaryFooter("Quay lại dữ liệu",'data-cf12-action="back-file"')}));
  if(state==="VALIDATION_ERROR") return ac310SanitizeMarkup(appShell({title:"Rà soát số dư đầu kỳ",body:`${vBanner("error","Chưa thể gửi phê duyệt","Dữ liệu không còn thỏa điều kiện đã kiểm tra. Quay lại bước kiểm tra.")}${cf12ReviewCard()}`,actions:primaryFooter("Kiểm tra lại",'data-cf12-action="back-check"')}));
  return ac310SanitizeMarkup(appShell({title:"Rà soát số dư đầu kỳ",body:deniedBody(),centered:true}));
}


function render070BJ12(state){
  if(state==="READY"){
    const reject=cf12RejectSheet();
    const body=`${vBanner("info","Kiểm tra trước khi duyệt","Đối chiếu ngày chốt, số kiểm soát và phạm vi trước khi quyết định.")}${ac310InfoSurface("Người chuẩn bị",[["Người lập","Nguyễn An",true],["Ngày gửi","07/09/2026 · 10:32"]])}${bj12Cf12Review()}${reject}`;
    return ac310Return(appShell({title:"Duyệt số dư đầu kỳ",body,actions:ac310ApprovalFooter('data-cf12-action="open-reject"','data-v350-action="cf12-approve"'),back:false}));
  }
  if(state==="PERMISSION_DENIED") return ac310SanitizeMarkup(appShell({title:"Duyệt số dư đầu kỳ",body:deniedBody(),centered:true,actions:bj12ExitList(),back:false}));
  if(state==="SELF_APPROVAL_NOT_ALLOWED") return ac310SanitizeMarkup(appShell({title:"Duyệt số dư đầu kỳ",body:`${vBanner("warning","Không thể tự duyệt","Người chuẩn bị số dư đầu kỳ không được đồng thời là người quyết định.")}${cf12ReviewCard()}`,actions:bj12ExitList(),back:false}));
  if(state==="APPROVAL_ALREADY_DECIDED") return ac310SanitizeMarkup(appShell({title:"Duyệt số dư đầu kỳ",body:`${vBanner("info","Công việc đã có quyết định","Quyết định hợp lệ đầu tiên có hiệu lực. Màn này chỉ còn để xem bằng chứng đã dùng.")}${cf12ReviewCard()}`,actions:bj12ExitList(),back:false}));
  if(state==="VALIDATION_ERROR") return ac310SanitizeMarkup(appShell({title:"Duyệt số dư đầu kỳ",body:`${vBanner("error","Không thể quyết định","Dữ liệu nền không còn hợp lệ. Không ghi nhận số dư từ bằng chứng đã thay đổi.")}${cf12ReviewCard()}`,actions:bj12ExitList(),back:false}));
  return ac310SanitizeMarkup(appShell({title:"Duyệt số dư đầu kỳ",body:deniedBody(),centered:true,actions:bj12ExitList(),back:false}));
}


function render071BJ12(state){
  if(state==="UNKNOWN"||state==="COMMIT_UNKNOWN"){
    return bj12UnknownResult({sourceFlow:"UIF-12",operation:"Khởi tạo tồn kho đầu kỳ",scope:`Kho trung tâm · ${cfDateVN(cf12Cutoff)}`});
  }
  let html;
  if(state==="PERMISSION_DENIED") html=appShell({title:"Kết quả khởi tạo tồn kho",body:deniedBody(),centered:true,actions:bj12ExitList(),back:false});
  else if(state==="PROCESSING") html=appShell({title:"Kết quả khởi tạo tồn kho",body:`${loadingBody()}${vBanner("info","Đang ghi nhận và đối soát","Hệ thống đang xử lý số dư được duyệt. Không cần thực hiện thêm thao tác.")}`,centered:true,back:false});
  else if(state==="REJECTED_EXECUTION") html=appShell({title:"Kết quả khởi tạo tồn kho",body:ioResult("Chưa khởi tạo tồn kho","Yêu cầu không được thực hiện. Không có số dư đầu kỳ nào được ghi nhận.",[["Ngày chốt số dư",cfDateVN(cf12Cutoff)],["Tác động tồn kho","Không có"]],"warning"),actions:primaryFooter("Về trạng thái khởi tạo",'data-cf12-action="result-home"'),centered:true,back:false});
  else html=appShell({title:"Kết quả khởi tạo tồn kho",body:ioResult("Đã khởi tạo tồn kho đầu kỳ","Số dư đã được ghi nhận nguyên khối và đối soát thành công. Mọi sửa sai tiếp theo đi qua nghiệp vụ điều chỉnh có kiểm soát.",[["Ngày chốt số dư",cfDateVN(cf12Cutoff)],["Sản phẩm",`${cfNumber(cf12Summary.products)} sản phẩm`],["Tổng giá trị",cfMoney(cf12Summary.parsedValue)],["Đối soát","Đã khớp"]]),actions:primaryFooter("Xem tồn kho",'data-cf12-action="see-inventory"'),centered:true,back:false});
  return ac310SanitizeMarkup(html);
}


document.addEventListener("input",(event)=>{
  if(activeFlowId!=="UIF-12") return;
  if(event.target.matches("[data-cf12-cutoff]")){cf12Cutoff=event.target.value;return;}
  if(event.target.matches("[data-cf12-control-qty]")){cf12ControlQty=event.target.value;return;}
  if(event.target.matches("[data-cf12-control-value]")){cf12ControlValue=String(event.target.value||"").replace(/[^0-9-]/g,"");return;}
  if(event.target.matches("[data-cf12-reject-reason]")){
    cf12RejectReason=event.target.value;
    const b=document.querySelector('[data-v350-action="cf12-confirm-reject"]'); if(b)b.disabled=!cf12RejectReason.trim();
    return;
  }
},true);
document.addEventListener("click",(event)=>{
  if(activeFlowId!=="UIF-12") return;
  // data-v350-action trước — nút confirm-reject nằm trong backdrop close-reject
  const v=event.target.closest("[data-v350-action]");
  if(v&&!v.disabled){
    const k=v.dataset.v350Action;
    if(["cf12-check","cf12-send-approval","cf12-approve","cf12-confirm-reject"].includes(k)){
      event.preventDefault();event.stopPropagation();
      if(k==="cf12-check"){
        const valid=Boolean(cf12FileName&&cf12Cutoff&&cf12ControlQty!==""&&cf12ControlValue!==""&&Number(cf12ControlQty)>=0&&Number(cf12ControlValue)>=0);
        if(!valid){stateByScreen["SCR-067"]="VALIDATION_ERROR";syncReviewUrl();return renderAppScreen();}
        stateByScreen["SCR-068"]=bj12ControlMatches()?"READY":"CONTROL_TOTAL_MISMATCH";return navigate("SCR-068");
      }
      if(k==="cf12-send-approval"){if(!bj12ControlMatches()){stateByScreen["SCR-068"]="CONTROL_TOTAL_MISMATCH";return navigate("SCR-068");}bj12Cf12ApprovalHash=bj12Hash();stateByScreen["SCR-069"]="PENDING_APPROVAL";stateByScreen["SCR-066"]="PENDING_APPROVAL";return navigate("SCR-066");}
      if(k==="cf12-approve"){
        if(window.__VET45_V350__?.getActor?.()!=="approver"){stateByScreen["SCR-070"]="SELF_APPROVAL_NOT_ALLOWED";syncReviewUrl();return renderAppScreen();}
        if(!bj12Cf12ApprovalHash||bj12Cf12ApprovalHash!==bj12Hash()){stateByScreen["SCR-070"]="VALIDATION_ERROR";syncReviewUrl();return renderAppScreen();}
        stateByScreen["SCR-071"]="PROCESSING";navigate("SCR-071");setTimeout(()=>{if(activeFlowId==="UIF-12"&&activeScreenId==="SCR-071"&&stateByScreen["SCR-071"]==="PROCESSING"){stateByScreen["SCR-071"]="COMPLETED";stateByScreen["SCR-066"]="ACTIVE_RECONCILED";syncReviewUrl();render();}},420);return;
      }
      if(k==="cf12-confirm-reject"){
        if(window.__VET45_V350__?.getActor?.()!=="approver"){stateByScreen["SCR-070"]="SELF_APPROVAL_NOT_ALLOWED";syncReviewUrl();return renderAppScreen();}
        if(!cf12RejectReason.trim())return;cf12RejectOpen=false;stateByScreen["SCR-070"]="APPROVAL_ALREADY_DECIDED";stateByScreen["SCR-066"]="REJECTED";syncReviewUrl();return renderAppScreen();
      }
    }
  }
  const a=event.target.closest("[data-cf12-action]");
  if(a&&!a.disabled){
    event.preventDefault(); event.stopPropagation(); const k=a.dataset.cf12Action;
    if(k==="start"||k==="continue-prepare"){stateByScreen["SCR-067"]="READY";return navigate("SCR-067");}
    if(k==="choose-file"){cf12FileName="ton-kho-dau-ky-2026.xlsx";stateByScreen["SCR-067"]="READY";return renderAppScreen();}
    if(k==="back-file"){stateByScreen["SCR-067"]="READY";return navigate("SCR-067");}
    if(k==="review"){stateByScreen["SCR-069"]="READY";return navigate("SCR-069");}
    if(k==="back-check"){stateByScreen["SCR-068"]="READY";return navigate("SCR-068");}
    if(k==="fix-rejected"){stateByScreen["SCR-067"]="READY";return navigate("SCR-067");}
    if(k==="open-reject"){cf12RejectOpen=true;cf12RejectReason="";return renderAppScreen();}
    if(k==="close-reject"){cf12RejectOpen=false;cf12RejectReason="";return renderAppScreen();}
    if(k==="result-home"){return navigate("SCR-066");}
    if(k==="see-inventory"){activeFlowId="UIF-01";activeScreenId="SCR-001";stateByScreen["SCR-001"]="READY";syncReviewUrl();return render();}
  }
},true);


Object.assign(renderers, {
  "SCR-066": render066BJ12,
  "SCR-067": render067BJ12,
  "SCR-068": render068BJ12,
  "SCR-069": render069BJ12,
  "SCR-070": render070BJ12,
  "SCR-071": render071BJ12
});
ownedFlows.add("UIF-12");

// Keep setCf12Control working after hash moved here
if(window.__VET45_V350__){
  const prev=window.__VET45_V350__.setCf12Control;
  window.__VET45_V350__.setCf12Control=function(qty,value){cf12ControlQty=String(qty);cf12ControlValue=String(value);return bj12ControlMatches();};
}
