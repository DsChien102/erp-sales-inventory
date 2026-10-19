/* BJ-10 — Tiêu hủy hàng (UIF-10). Màn: SCR-036, SCR-037, SCR-040, SCR-041.
 *
 * Đã viết lại sạch (T7-P gói A6, 2026-10-17). Màn dùng chung đăng ký qua flowRenderers.
 * ac310SanitizeMarkup lấy từ core.js (A7 → shared-control.js).
 */

let ic10Selected="amox-l2407";

function render036BJ10(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Hàng có thể xử lý",body:deniedBody(),centered:true,back:false});
  if(state==="LOADING")return appShell({title:"Hàng có thể xử lý",body:loadingBody(),back:false});
  if(state==="EMPTY")return appShell({title:"Hàng có thể xử lý",body:ioEmpty("Chưa có hàng cần xử lý","Chỉ hàng không bán được và thuộc quyền sở hữu của tổ chức mới xuất hiện tại đây."),back:false});
  const body=`${vBanner("info","Chỉ hiển thị hàng đủ điều kiện","Hàng đang bán được cần đổi tình trạng trước khi có thể lập yêu cầu tiêu hủy.")}<div class="io-list-card" data-ds-component="VSection" data-composed-from="DS v2 / List Row"><div class="io-product-list">${ioProductRow({name:"Amox 500",code:"SP-00128",primary:"6 hộp",secondary:"Lô L2407-A",badge:"Cách ly",badgeStatus:"warning",attr:'data-ic10-item="amox-l2407"'})}${ioProductRow({name:"Vitamin C",code:"SP-00231",primary:"4 hộp",secondary:"Lô L2310-C",badge:"Hết hạn",badgeStatus:"danger",attr:'data-ic10-item="vitc-l2310"'})}</div></div>`;
  return appShell({title:"Hàng có thể xử lý",body,back:false});
}
function render037BJ10(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Chi tiết hàng",body:deniedBody(),centered:true});
  if(state==="LOCKED")return appShell({title:"Chi tiết hàng",body:`${vBanner("info","Đang thuộc phạm vi kiểm kê","Thông tin chỉ đọc cho đến khi phiên kiểm kê kết thúc.")}${icHeaderRows([["Sản phẩm","Amox 500",true],["Lô","L2407-A"],["Tình trạng","Cách ly"],["Tồn vật lý","6 hộp"]])}`});
  const body=`${icHeaderRows([["Sản phẩm","Amox 500",true],["Mã","SP-00128"],["Lô","L2407-A"],["Tình trạng","Cách ly"],["Tồn vật lý","6 hộp"],["Quyền sở hữu","Hàng của tổ chức"]])}${ioSectionTitle("Xử lý")}<p class="io-footnote">Phê duyệt yêu cầu không làm giảm tồn. Chỉ xác nhận đã tiêu hủy thực tế mới cho phép ghi giảm.</p>`;
  return appShell({title:"Chi tiết hàng",body,actions:primaryFooter("Đề nghị tiêu hủy",'data-ic10-action="request"')});
}
function render040IC10(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Yêu cầu tiêu hủy",body:deniedBody(),centered:true,back:false});
  const base=icHeaderRows([["Sản phẩm","Amox 500",true],["Lô","L2407-A"],["Tình trạng","Cách ly"],["Có thể xử lý","6 hộp"]]);
  if(state==="PRICE_BASIS_REQUIRED")return appShell({title:"Yêu cầu tiêu hủy",body:`${vBanner("error","Chưa có căn cứ giá hợp lệ","Không thể gửi yêu cầu vì chưa xác định được căn cứ giá chính thức cho lượng hàng này. Không nhập giá thủ công để bỏ qua kiểm soát.")}${base}${icField("Số lượng đề nghị","6",'data-ic10-qty','number')}${icTextarea("Lý do","Hàng không còn đủ điều kiện sử dụng",'data-ic10-reason')}`,actions:primaryFooter("Gửi yêu cầu tiêu hủy",'data-ic10-action="submit"',true)});
  if(state==="PENDING_APPROVAL")return appShell({title:"Yêu cầu tiêu hủy",body:`${vBanner("info","Đã gửi chờ duyệt","Bạn đã hoàn tất phần việc lập yêu cầu. Tồn kho chưa thay đổi; người duyệt nhận công việc riêng.")}${base}${icHeaderRows([["Số lượng đề nghị","6 hộp",true],["Tác động tồn kho","Chưa có"]])}`,back:false});
  if(state==="APPROVAL_REVIEW")return appShell({title:"Duyệt tiêu hủy",body:`${vBanner("info","Phê duyệt chưa phải tiêu hủy","Duyệt chỉ cho phép chuyển yêu cầu sang chờ xử lý thực tế. Tồn vật lý chưa giảm ở bước này.","v360-context-banner")}${base}${icHeaderRows([["Số lượng đề nghị","6 hộp",true],["Căn cứ giá","Giá vốn hiện hành"],["Lý do","Hàng không còn đủ điều kiện sử dụng"]])}`,actions:icApprovalButtons("ic10"),back:false});
  if(state==="APPROVED_PENDING_DISPOSAL")return appShell({title:"Yêu cầu tiêu hủy",body:`${vBanner("success","Đã duyệt — chờ xử lý thực tế","Yêu cầu đã được duyệt nhưng tồn kho vẫn giữ nguyên. Công việc xác nhận tiêu hủy sẽ được giao cho người thực hiện phù hợp.")}${base}${icHeaderRows([["Đã duyệt","6 hộp",true],["Tồn vật lý hiện tại","6 hộp · chưa giảm"]])}`,back:false});
  if(state==="COMPLETION_QTY_BLOCKED")return appShell({title:"Xác nhận đã tiêu hủy",body:`${vBanner("error","Số lượng thực tế vượt phạm vi được duyệt","Không thể ghi giảm. Cần lập yêu cầu và phê duyệt mới cho phần vượt chính sách.")}${base}${icField("Đã tiêu hủy thực tế","7",'data-ic10-actual','number')}${icTextarea("Bằng chứng","Biên bản tiêu hủy #TH-0709",'data-ic10-proof')}`,actions:primaryFooter("Xác nhận đã tiêu hủy",'data-ic10-action="complete"',true,"danger"),back:false});
  if(state==="COMPLETION")return appShell({title:"Xác nhận đã tiêu hủy",body:`${vBanner("warning","Chỉ xác nhận sau khi đã xử lý thực tế","Số lượng ở đây là lượng thực tế đã tiêu hủy và sẽ là căn cứ ghi giảm tồn.")}${base}${icField("Đã tiêu hủy thực tế","6",'data-ic10-actual','number')}${icTextarea("Bằng chứng","Biên bản tiêu hủy #TH-0709",'data-ic10-proof')}`,actions:primaryFooter("Xác nhận đã tiêu hủy",'data-ic10-action="complete"',false,"danger"),back:false});
  const body=`${base}${icField("Số lượng đề nghị","6",'data-ic10-qty','number')}${icTextarea("Lý do","Hàng không còn đủ điều kiện sử dụng",'data-ic10-reason')}${icTextarea("Bằng chứng","Ảnh hiện trạng và biên bản kiểm tra",'data-ic10-evidence')}${icHeaderRows([["Căn cứ giá","Giá vốn hiện hành"]])}`;
  return appShell({title:"Yêu cầu tiêu hủy",body,actions:primaryFooter("Gửi yêu cầu tiêu hủy",'data-ic10-action="submit"')});
}
function render041IC10(state){
  if(state==="PROCESSING")return appShell({title:"Kết quả tiêu hủy",body:loadingBody(),centered:true,back:false});
  if(state==="UNKNOWN")return appShell({title:"Kết quả tiêu hủy",body:ioResult("Đang xác minh kết quả","Không tạo lần tiêu hủy mới. Hệ thống đang kiểm tra chính lần xác nhận này.",[["Yêu cầu","TH-0709-04"],["Tồn vật lý","Chưa kết luận"]],"warning"),actions:primaryFooter("Kiểm tra kết quả",'data-ic10-action="verify"'),centered:true,back:false});
  if(state==="REJECTED_EXECUTION")return appShell({title:"Kết quả tiêu hủy",body:ioResult("Chưa ghi giảm","Không có tác động tồn kho mới. Xem lại yêu cầu hiện hành trước khi tiếp tục.",[["Yêu cầu","TH-0709-04"],["Tồn vật lý","Không thay đổi"]],"warning"),actions:primaryFooter("Về hàng có thể xử lý",'data-ic10-action="to-list"'),centered:true,back:false});
  return appShell({title:"Kết quả tiêu hủy",body:ioResult("Đã ghi nhận tiêu hủy","Tồn vật lý và giá trị đã giảm theo đúng số lượng thực tế được xác nhận.",[["Yêu cầu","TH-0709-04"],["Đã tiêu hủy","6 hộp"],["Tồn vật lý còn lại","0 hộp"]]),actions:primaryFooter("Về hàng có thể xử lý",'data-ic10-action="to-list"'),centered:true,back:false});
}

let bj10RequestQty="", bj10Reason="", bj10Evidence="", bj10ApprovedQty=0, bj10ActualQty="", bj10Proof="", bj10CompletedQty=0;
const bj10Num=(v)=>Number(v??0);
const bj10NonBlank=(v)=>String(v??"").trim().length>0;
function bj10RequestValid(){const q=bj10Num(bj10RequestQty);return q>0&&q<=6&&bj10NonBlank(bj10Reason)&&bj10NonBlank(bj10Evidence);}
function bj10CompletionValid(){const q=bj10Num(bj10ActualQty);return q>0&&q<=bj10Num(bj10ApprovedQty)&&bj10NonBlank(bj10Proof);}
function bj10IsApprover(){return currentActor()==="approver";}
function bj10IsCompletion(){return currentActor()==="completion-operator";}


function render040BJ10(state){
  // v360 ensureStableExitAffordance: màn 040 không có nút → "Về danh sách" (A11: dựng thẳng, không lớp v360).
  const exitList=primaryFooter("Về danh sách",'data-v360-action="fallback-exit" data-v360-target="SCR-036"');
  if(state==="PERMISSION_DENIED")return appShell({title:"Yêu cầu tiêu hủy",body:deniedBody(),centered:true,back:false,actions:exitList});
  const base=icHeaderRows([["Sản phẩm","Amox 500",true],["Lô","L2407-A"],["Tình trạng","Cách ly"],["Có thể xử lý","6 hộp"]]);
  if(state==="SELF_APPROVAL_NOT_ALLOWED")return appShell({title:"Duyệt tiêu hủy",body:vBanner("warning","Không thể tự duyệt","Người lập yêu cầu không được tự duyệt yêu cầu tiêu hủy."),back:false,actions:exitList});
  if(state==="PENDING_APPROVAL")return appShell({title:"Yêu cầu tiêu hủy",body:`${vBanner("info","Đã gửi chờ duyệt","Tồn kho chưa thay đổi; người duyệt nhận công việc riêng.")}${base}${icHeaderRows([["Số lượng đề nghị",`${bj10RequestQty} hộp`,true],["Lý do",bj10Reason],["Bằng chứng",bj10Evidence],["Tác động tồn kho","Chưa có"]])}`,back:false,actions:exitList});
  if(state==="APPROVAL_REVIEW")return appShell({title:"Duyệt tiêu hủy",body:`${vBanner("info","Phê duyệt chưa phải tiêu hủy","Duyệt chỉ cho phép chuyển yêu cầu sang chờ xử lý thực tế; tồn vật lý chưa giảm.","v360-context-banner")}${base}${icHeaderRows([["Số lượng đề nghị",`${bj10RequestQty} hộp`,true],["Lý do",bj10Reason||"—"],["Bằng chứng",bj10Evidence||"—"],["Căn cứ giá","Giá vốn hiện hành"]])}`,actions:`<div class="ic-action-stack">${icSecondary("Từ chối",'data-v350-action="ic10-reject"','danger')}${primaryFooter("Duyệt",'data-v350-action="ic10-approve"')}</div>`,back:false});
  if(state==="APPROVED_PENDING_DISPOSAL")return appShell({title:"Yêu cầu tiêu hủy",body:`${vBanner("success","Đã duyệt — chờ xử lý thực tế","Tồn kho vẫn giữ nguyên cho đến khi người thực hiện xác nhận xử lý thực tế.")}${base}${icHeaderRows([["Đã duyệt",`${bj10ApprovedQty} hộp`,true],["Tồn vật lý hiện tại","6 hộp · chưa giảm"]])}`,back:false,actions:exitList});
  if(state==="COMPLETION"||state==="COMPLETION_QTY_BLOCKED"){
    const blocked=state==="COMPLETION_QTY_BLOCKED";
    const body=`${blocked?vBanner("error","Số lượng thực tế vượt phạm vi được duyệt",`Tối đa ${bj10ApprovedQty} hộp. Không thể ghi giảm phần vượt.`):vBanner("warning","Chỉ xác nhận sau khi đã xử lý thực tế","Số lượng thực tế sẽ là căn cứ ghi giảm tồn.")}${base}${icField("Đã tiêu hủy thực tế",bj10ActualQty,'data-v350-ic10-actual','number')}${icTextarea("Bằng chứng",bj10Proof,'data-v350-ic10-proof','Nhập số biên bản hoặc bằng chứng')}`;
    return appShell({title:"Xác nhận đã tiêu hủy",body,actions:primaryFooter("Xác nhận đã tiêu hủy",'data-v350-action="ic10-complete"',false,"danger"),back:false});
  }
  const invalid=state==="VALIDATION_ERROR";const price=state==="PRICE_BASIS_REQUIRED";
  const body=`${invalid?vBanner("error","Chưa đủ thông tin","Số lượng phải từ 1 đến 6 hộp; lý do và bằng chứng là bắt buộc."):""}${price?vBanner("error","Chưa có căn cứ giá hợp lệ","Không thể gửi yêu cầu cho đến khi có căn cứ giá chính thức."):""}${base}${icField("Số lượng đề nghị",bj10RequestQty,'data-v350-ic10-qty','number')}${icTextarea("Lý do",bj10Reason,'data-v350-ic10-reason')}${icTextarea("Bằng chứng",bj10Evidence,'data-v350-ic10-evidence')}${icHeaderRows([["Căn cứ giá","Giá vốn hiện hành"]])}`;
  return appShell({title:"Yêu cầu tiêu hủy",body,actions:primaryFooter("Gửi yêu cầu tiêu hủy",'data-v350-action="ic10-submit"',price)});
}

function render041BJ10(state){
  if(state==="COMPLETED"){
    if(!(Number(bj10CompletedQty)>0||Number(bj10ApprovedQty)>0)) return appShell({title:"Kết quả tiêu hủy",body:ioResult("Đã ghi nhận tiêu hủy","Tồn vật lý và giá trị đã giảm theo đúng số lượng thực tế được xác nhận.",[["Yêu cầu","TH-0709-04"],["Đã tiêu hủy","6 hộp"],["Tồn vật lý còn lại","0 hộp"]]),actions:primaryFooter("Về hàng có thể xử lý",'data-ic10-action="to-list"'),centered:true,back:false});
    return appShell({title:"Kết quả tiêu hủy",body:ioResult("Đã ghi nhận tiêu hủy","Tồn vật lý và giá trị đã giảm theo đúng số lượng thực tế được xác nhận.",[["Yêu cầu","TH-0709-04"],["Đã tiêu hủy",`${bj10CompletedQty||bj10ApprovedQty} hộp`],["Tồn vật lý còn lại",`${Math.max(0,6-(bj10CompletedQty||bj10ApprovedQty))} hộp`]]),actions:primaryFooter("Về hàng có thể xử lý",'data-ic10-action="to-list"'),centered:true,back:false});
  }
  if(state==="UNKNOWN"||state==="COMMIT_UNKNOWN"){
    const body=ioResult("Kết quả chưa xác định","Không gửi lại thao tác. Chuyển đúng lần xử lý này sang xác minh kết quả.",[["Nghiệp vụ","TH-0709-04"],["Phạm vi","Amox 500 · Lô L2407-A"],["Trạng thái","Chưa kết luận"]],"warning");
    return appShell({title:"Xác minh kết quả",body,actions:primaryFooter("Chuyển sang xác minh",'data-v350-action="handoff-unknown" data-source-flow="UIF-10" data-operation="TH-0709-04" data-scope="Amox 500 · Lô L2407-A"'),centered:true,back:false});
  }
  return ac310SanitizeMarkup(render041IC10(state));
}

flowRenderers["UIF-10"] = Object.assign(flowRenderers["UIF-10"] || {}, {
  "SCR-036": render036BJ10,
  "SCR-037": render037BJ10,
  "SCR-040": render040BJ10,
  "SCR-041": render041BJ10,
});

Object.assign(window.__VET45_QA__, {
  getIC10(){return {requestQty:bj10RequestQty,reason:bj10Reason,evidence:bj10Evidence,approvedQty:bj10ApprovedQty,actualQty:bj10ActualQty,proof:bj10Proof,completedQty:bj10CompletedQty};}
});

document.addEventListener("input",(event)=>{
  if(event.target.matches("[data-v350-ic10-qty]")){bj10RequestQty=event.target.value;return;}
  if(event.target.matches("[data-v350-ic10-reason]")){bj10Reason=event.target.value;return;}
  if(event.target.matches("[data-v350-ic10-evidence]")){bj10Evidence=event.target.value;return;}
  if(event.target.matches("[data-v350-ic10-actual]")){bj10ActualQty=event.target.value;return;}
  if(event.target.matches("[data-v350-ic10-proof]")){bj10Proof=event.target.value;return;}
},true);

document.addEventListener("click",(event)=>{
  if(activeFlowId==="UIF-10" && event.target.closest('[data-ic10-action="request"]')){
    bj10RequestQty="";bj10Reason="";bj10Evidence="";bj10ApprovedQty=0;bj10ActualQty="";bj10Proof="";bj10CompletedQty=0;
  }
  const v350A=event.target.closest("[data-v350-action]");
  if(v350A && !v350A.disabled && activeFlowId==="UIF-10"){
    const k=v350A.dataset.v350Action;
    if(k==="ic10-submit"||k==="ic10-approve"||k==="ic10-reject"||k==="ic10-complete"){
      event.preventDefault();event.stopPropagation();
      if(k==="ic10-submit"){
        if(!bj10RequestValid()){stateByScreen["SCR-040"]="VALIDATION_ERROR";return renderAppScreen();}
        stateByScreen["SCR-040"]="PENDING_APPROVAL";renderAppScreen();return showToast("Đã gửi yêu cầu tiêu hủy","success");
      }
      if(k==="ic10-approve"){if(!bj10IsApprover()){stateByScreen["SCR-040"]="SELF_APPROVAL_NOT_ALLOWED";return renderAppScreen();}bj10ApprovedQty=bj10Num(bj10RequestQty);stateByScreen["SCR-040"]="APPROVED_PENDING_DISPOSAL";return renderAppScreen();}
      if(k==="ic10-reject"){if(!bj10IsApprover()){stateByScreen["SCR-040"]="SELF_APPROVAL_NOT_ALLOWED";return renderAppScreen();}stateByScreen["SCR-041"]="REJECTED_EXECUTION";return navigate("SCR-041");}
      if(k==="ic10-complete"){
        const actor=currentActor()||"module";
        if(!bj10IsCompletion()&&actor!=="module"){return;}
        if(bj10Num(bj10ActualQty)>bj10Num(bj10ApprovedQty)){stateByScreen["SCR-040"]="COMPLETION_QTY_BLOCKED";return renderAppScreen();}
        if(!bj10CompletionValid()){stateByScreen["SCR-040"]="COMPLETION_QTY_BLOCKED";return renderAppScreen();}
        bj10CompletedQty=bj10Num(bj10ActualQty);stateByScreen["SCR-041"]="COMPLETED";return navigate("SCR-041");
      }
    }
  }
  if(activeFlowId!=="UIF-10") return;
  const item=event.target.closest("[data-ic10-item]"); if(item){event.preventDefault();ic10Selected=item.dataset.ic10Item;stateByScreen["SCR-037"]="READY";return navigate("SCR-037");}
  const a=event.target.closest("[data-ic10-action]"); if(a&&!a.disabled){event.preventDefault();const k=a.dataset.ic10Action;
    if(k==="request"){stateByScreen["SCR-040"]="READY";return navigate("SCR-040");} if(k==="submit"){stateByScreen["SCR-040"]="PENDING_APPROVAL";return render();}
    if(k==="approve"){stateByScreen["SCR-040"]="APPROVED_PENDING_DISPOSAL";return render();} if(k==="reject"){stateByScreen["SCR-041"]="REJECTED_EXECUTION";return navigate("SCR-041");}
    if(k==="complete"){stateByScreen["SCR-041"]="COMPLETED";return navigate("SCR-041");} if(k==="verify")return renderAppScreen();
    if(k==="to-list"){stateByScreen["SCR-036"]="READY";return navigate("SCR-036");}
  }
},true);

