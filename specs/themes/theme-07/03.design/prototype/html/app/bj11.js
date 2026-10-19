/* BJ-11 — Hủy và sửa sai nghiệp vụ kho (UIF-11). Màn: SCR-048…053.
 *
 * Đã viết lại sạch (T7-P gói A8, 2026-10-17). Màn đăng ký qua flowRenderers / renderers.
 * Helper chung ac310* (Section/KeyValue/List/Radio/Audit/Summary/Field/ApprovalFooter) → app/shared-control.js.
 * Khôi phục listener Correction & Recovery (bị mất từ A5); sửa nút Từ chối (data-v350-action).
 */

let cr11Filter="ALL";
let cr11Query="";
let cr11SelectedId="IO-260901-014";
let cr11Strategy="DELTA";
let cr11CorrectQty=118;
let cr11CorrectionReason="Ghi nhận thừa 2 hộp khi nhận hàng";
let cr11CancelReason="";
let cr11ApprovalRejectOpen=false;
let cr11ApprovalRejectReason="";const cr11Operations=[
  {id:"IO-260906-022",type:"Thay đổi tình trạng hàng",source:"ST-260906-04",status:"READY",statusLabel:"Có thể hủy",route:"CANCEL",warehouse:"Kho trung tâm",product:"Amox 500 · Lô L2407-A",qty:12,uom:"hộp",impact:"Chưa phát sinh thay đổi tồn kho"},
  {id:"IO-260901-014",type:"Nhận hàng",source:"PN-260901-07",status:"COMPLETED",statusLabel:"Có thể sửa",route:"CORRECT",warehouse:"Kho trung tâm",product:"Nobivac DHPPi · Lô DH2507",qty:120,uom:"hộp",correctQty:118,impact:"Đã tăng tồn 120 hộp"},
  {id:"IO-260904-021",type:"Nhận hàng",source:"PN-260904-08",status:"COMPLETED",statusLabel:"Có thể sửa",route:"CORRECT",warehouse:"Kho trung tâm",product:"Amox 500 · Lô L2407-A",qty:20,uom:"hộp",correctQty:18,impact:"Đã tăng tồn 20 hộp"},
  {id:"IO-260906-031",type:"Tiêu hủy",source:"DSP-260906-02",status:"UNKNOWN",statusLabel:"Đang xác minh",route:"UNKNOWN",warehouse:"Kho trung tâm",product:"Vitamin C · Lô L2310-C",qty:5,uom:"hộp",impact:"Chưa thể kết luận tác động tồn kho"},
  {id:"IO-260902-005",type:"Xuất bán",source:"SO-260902-19",status:"COMPLETED",statusLabel:"Cần xử lý đúng luồng",route:"PHYSICAL_RETURN_BLOCKED",warehouse:"Kho trung tâm",product:"Oxytetracycline LA",qty:3,uom:"chai",impact:"Hàng đã bàn giao thực tế cho khách"}
];

function cr11Current(){return cr11Operations.find(x=>x.id===cr11SelectedId)||cr11Operations[1];}
function cr11StateFor(op){if(op.route==="CANCEL")return "CANCELABLE";if(op.route==="UNKNOWN")return "UNKNOWN";if(op.route==="PHYSICAL_RETURN_BLOCKED")return "BLOCKED_PHYSICAL_HANDOVER";return "CORRECTABLE";}
function bj11Textarea(label,value,attrs="",helper=""){
  return `<label class="ac310-field" data-ds-component="VTextarea" data-figma-node="522:7212"><span>${esc(label)}</span><textarea ${attrs}>${esc(value)}</textarea>${helper?`<small>${esc(helper)}</small>`:""}</label>`;
}
function bj11RadioChoice({value,label,detail="",checked=false,attrs="",disabled=false}){
  return `<label class="ac310-radio-row${disabled?' is-disabled':''}" data-ds-component="VRadio" data-figma-node="522:7410"><input type="radio" value="${escapeAttribute(value)}" ${attrs} ${checked?'checked':''} ${disabled?'disabled':''}><span class="ac310-radio-control" aria-hidden="true"></span><span class="ac310-radio-copy"><strong>${esc(label)}</strong>${detail?`<small>${esc(detail)}</small>`:""}</span></label>`;
}

function bj11KeyValueSurface(title,rows,{extraClass=""}={}){
  const head=title?`<div class="ac310-surface__head"><h2>${esc(title)}</h2></div>`:"";
  const body=(rows||[]).map((r)=>{
    let v=String(r[1]??"");
    if(/^-\s?\d/.test(v)) v=v.replace(/^-\s?/,"−");
    return ds24KeyValueRow(r[0],v,!!r[2]);
  }).join("");
  return `<section class="ac310-surface ${extraClass}" data-layout-pattern="Grouped surface" data-composed-from="DS v2 / Key-value Row">${head}<div class="ac310-key-value-stack">${body}</div></section>`;
}

function cr11ListRows(){
  const labels={ALL:"Tất cả",CANCEL:"Có thể hủy",CORRECT:"Có thể sửa",UNKNOWN:"Đang xác minh"};
  const rows=cr11Operations.filter(op=>cr11Filter==="ALL"||op.route===cr11Filter).filter(op=>ioMatchesSearch(cr11Query,`${op.id} ${op.type} ${op.source} ${op.product}`));
  const list=rows.map(op=>ioProductRow({name:op.type,code:`${op.id} · ${op.source}`,primary:`${op.qty} ${op.uom}`,secondary:op.product,badge:op.statusLabel,badgeStatus:op.route==="UNKNOWN"?"warning":op.route==="PHYSICAL_RETURN_BLOCKED"?"warning":"info",attr:`data-cr11-operation="${op.id}"`})).join("");
  return `${ioSearchBar("Tìm mã nghiệp vụ, chứng từ hoặc hàng",'data-cr11-search',cr11Query)}${ac321CanonicalChips(cr11Filter,Object.entries(labels),'data-cr11-filter')}${list?`<div class="io-list-card" data-ds-component="VSection" data-composed-from="DS v2 / List Row,VBadge"><div class="io-product-list">${list}</div></div>`:ioEmpty("Không có nghiệp vụ phù hợp","Thử đổi bộ lọc hoặc từ khóa tìm kiếm.")}`;
}

function render048BJ11(state){
  if(state==="READY"){
    const labels={ALL:"Tất cả",CANCEL:"Có thể hủy",CORRECT:"Có thể sửa",UNKNOWN:"Đang xác minh"};
    const rows=cr11Operations.filter((op)=>cr11Filter==="ALL"||op.route===cr11Filter).filter((op)=>ioMatchesSearch(cr11Query,`${op.id} ${op.type} ${op.source} ${op.product}`)).map((op)=>ac310RecordRow({title:op.type,subtitle:`${op.id} · ${op.source} · ${op.product}`,badge:op.route==="PHYSICAL_RETURN_BLOCKED"?"Luồng trả hàng":op.statusLabel,tone:op.route==="UNKNOWN"||op.route==="PHYSICAL_RETURN_BLOCKED"?"Warning":"Info",attrs:`data-cr11-operation="${op.id}"`,leading:null})).join("");
    const chips=`<div class="ds24-chip-scroll">${Object.entries(labels).map(([k,l])=>ds24Chip(k,l,cr11Filter===k,"data-cr11-filter")).join("")}</div>`;
    return ac310Return(appShell({title:"Kiểm soát nghiệp vụ kho",body:`${ds24Search(cr11Query,"data-cr11-search","Tìm mã nghiệp vụ hoặc chứng từ")}${chips}${rows?ac310ListSurface(rows):ioEmpty("Không có nghiệp vụ phù hợp","Thử đổi bộ lọc hoặc từ khóa tìm kiếm.")}`,back:false}));
  }
  // LOADING / EMPTY / PERMISSION_DENIED / FILTER_EMPTY (+ other) — sanitized base
  if(state==="PERMISSION_DENIED") return ac310SanitizeMarkup(appShell({title:"Kiểm soát nghiệp vụ kho",body:deniedBody(),centered:true,back:false}));
  if(state==="LOADING") return ac310SanitizeMarkup(appShell({title:"Kiểm soát nghiệp vụ kho",body:loadingBody(),back:false}));
  if(state==="EMPTY") return ac310SanitizeMarkup(appShell({title:"Kiểm soát nghiệp vụ kho",body:ioEmpty("Chưa có nghiệp vụ cần kiểm soát","Các nghiệp vụ đủ điều kiện sẽ xuất hiện tại đây."),back:false}));
  return ac310SanitizeMarkup(appShell({title:"Kiểm soát nghiệp vụ kho",body:cr11ListRows(),back:false}));
}


function render049BJ11(state){
  if(["READY","CORRECTABLE","CANCELABLE","UNKNOWN","BLOCKED_PHYSICAL_HANDOVER","TERMINAL"].includes(state)){
    const op=cr11Current(),routeState=state==="READY"?cr11StateFor(op):state;
    const context=`${ac310RecordRow({title:op.id,subtitle:`${op.type} · ${op.source}`,badge:op.statusLabel,tone:routeState==="UNKNOWN"?"Warning":"Info",status:true,leading:null})}${ac310InfoSurface("Thông tin nghiệp vụ",[["Kho",op.warehouse],["Hàng",op.product],["Số lượng",`${op.qty} ${op.uom}`],["Tác động",op.impact]])}`;
    if(routeState==="UNKNOWN") return ac310Return(appShell({title:"Chi tiết nghiệp vụ kho",body:`${vBanner("warning","Kết quả chưa xác định","Chưa hủy hoặc tạo sửa sai cho tới khi xác lập kết quả của đúng lần xử lý này.")}${context}`,actions:primaryFooter("Xác minh kết quả",'data-cr11-action="handoff-unknown"')}));
    if(routeState==="BLOCKED_PHYSICAL_HANDOVER") return ac310Return(appShell({title:"Chi tiết nghiệp vụ kho",body:`${vBanner("warning","Hàng đã được bàn giao thực tế","Khách trả hàng phải qua nghiệp vụ Hàng khách trả; không xử lý bằng sửa sai.")}${context}`,actions:primaryFooter("Về danh sách",'data-cr11-action="to-list"')}));
    if(routeState==="TERMINAL") return ac310Return(appShell({title:"Chi tiết nghiệp vụ kho",body:`${vBanner("info","Không còn tác động cần sửa","Nghiệp vụ đã dừng trước khi thực thi.")}${context}`,actions:primaryFooter("Về danh sách",'data-cr11-action="to-list"')}));
    if(routeState==="CANCELABLE") return ac310Return(appShell({title:"Chi tiết nghiệp vụ kho",body:`${context}<p class="ac310-note">Nghiệp vụ chưa thực thi nên có thể hủy mà không tạo biến động tồn kho.</p>`,actions:primaryFooter("Hủy yêu cầu",'data-cr11-action="open-cancel"',false,"danger")}));
    return ac310Return(appShell({title:"Chi tiết nghiệp vụ kho",body:`${context}${ac310AuditSurface("Dấu vết",[ac310AuditItem("Create","Nghiệp vụ gốc đã hoàn tất","01/09/2026 · Chưa có sửa sai trước đó")])}`,actions:primaryFooter("Sửa sai",'data-cr11-action="open-correction"')}));
  }
  if(state==="PERMISSION_DENIED") return ac310SanitizeMarkup(appShell({title:"Chi tiết nghiệp vụ kho",body:deniedBody(),centered:true}));
  if(state==="LOADING") return ac310SanitizeMarkup(appShell({title:"Chi tiết nghiệp vụ kho",body:loadingBody()}));
  return ac310SanitizeMarkup(appShell({title:"Chi tiết nghiệp vụ kho",body:loadingBody()}));
}


function render052BJ11(state){
  if(["DEPENDENCY_BLOCKED","PERIOD_POLICY_VIOLATION","PERMISSION_DENIED"].includes(state)){
    const op=cr11Current();
    if(state==="PERMISSION_DENIED") return ac310SanitizeMarkup(appShell({title:"Kiểm soát nghiệp vụ",body:deniedBody(),centered:true}));
    if(state==="DEPENDENCY_BLOCKED") return ac310SanitizeMarkup(appShell({title:"Chọn cách sửa",body:`${vBanner("warning","Chưa thể sửa sai","Có nghiệp vụ phía sau đang phụ thuộc. Hãy xử lý nghiệp vụ đó trước.")}${crFactCard(op.id,[["Nghiệp vụ",op.type,true],["Hàng",op.product],["Tác động hiện tại",op.impact]])}`,actions:primaryFooter("Về chi tiết",'data-cr11-action="back-detail"')}));
    return ac310SanitizeMarkup(appShell({title:"Chọn cách sửa",body:`${vBanner("warning","Chưa có kỳ mở để ghi nhận sửa sai","Cần có kỳ ghi nhận hiện hành hợp lệ trước khi tiếp tục.")}${crFactCard(op.id,[["Ngày nghiệp vụ gốc","01/09/2026"],["Kỳ gốc","Đã khóa"]])}`,actions:primaryFooter("Về chi tiết",'data-cr11-action="back-detail"')}));
  }
  const op=cr11Current(); const cancelMode=state==="CANCEL_UNEXECUTED"||op.route==="CANCEL";
  if(cancelMode){
    const body=`${state==="VALIDATION_ERROR"&&!cr11CancelReason.trim()?vBanner("error","Cần nhập lý do hủy","Lý do được lưu trong lịch sử kiểm soát."):""}${vBanner("info","Hủy trước khi thực thi","Tồn kho và giá trị không thay đổi.")}${ac310InfoSurface("Yêu cầu",[["Nghiệp vụ",op.id,true],["Loại",op.type],["Chứng từ nguồn",op.source]])}${bj11Textarea("Lý do hủy",cr11CancelReason,'data-cr11-cancel-reason')}`;
    return ac310Return(appShell({title:"Hủy yêu cầu kho",body,actions:primaryFooter("Hủy yêu cầu",'data-cr11-action="confirm-cancel"',!cr11CancelReason.trim(),"danger")}));
  }
  const choices=[bj11RadioChoice({value:"DELTA",label:"Sửa phần sai",detail:"Điều chỉnh riêng phần sai và giữ nguyên phần đúng.",checked:cr11Strategy==="DELTA",attrs:'name="cr11-strategy" data-cr11-strategy'}),bj11RadioChoice({value:"FULL",label:"Hoàn nguyên và ghi lại đúng",detail:"Dùng khi toàn bộ nghiệp vụ phải được xác lập lại.",checked:cr11Strategy==="FULL",attrs:'name="cr11-strategy" data-cr11-strategy'})];
  const body=`${vBanner("info","Nghiệp vụ gốc luôn được giữ nguyên","Hệ thống tạo bản ghi sửa sai có liên kết; không xóa lịch sử đã hoàn tất.")}${ac310InfoSurface("Nghiệp vụ gốc",[["Mã",op.id,true],["Đã ghi nhận",`${op.qty} ${op.uom}`],["Kỳ gốc","Đã khóa"]])}${ac310RadioSurface("Cách sửa",choices)}`;
  return ac310Return(appShell({title:"Chọn cách sửa",body,actions:primaryFooter("Tiếp tục",'data-cr11-action="edit-correction"')}));
}


function render050BJ11(state){
  if(["PERMISSION_DENIED","SOURCE_VERSION_STALE","CONFLICT"].includes(state)){
    const op=cr11Current();const delta=Number(cr11CorrectQty)-Number(op.qty);
    if(state==="PERMISSION_DENIED") return ac310SanitizeMarkup(appShell({title:"Nội dung sửa sai",body:deniedBody(),centered:true}));
    const validation=state==="SOURCE_VERSION_STALE"?vBanner("warning","Nghiệp vụ nguồn đã thay đổi","Hãy quay lại chi tiết để đối chiếu dữ liệu hiện hành trước khi gửi."):vBanner("warning","Đã có yêu cầu sửa sai khác","Không tạo yêu cầu sửa sai song song. Mở yêu cầu đang hoạt động để tiếp tục.");
    const body=`${validation}${crFactCard("Trước và sau",[["Nghiệp vụ gốc",op.id,true],["Số đã ghi nhận",`${op.qty} ${op.uom}`],["Cách sửa",cr11Strategy==="DELTA"?"Sửa phần sai":"Hoàn nguyên và ghi lại đúng"]])}<div class="form-field" data-ds-component="VNumberField"><label>Số đúng <span class="required">*</span></label><div class="input-shell"><input type="number" min="0" inputmode="decimal" value="${cr11CorrectQty}" data-cr11-correct-qty></div></div>${crFactCard("Hệ thống tự tính",[["Điều chỉnh",`${delta>0?"+":""}${delta} ${op.uom}`,true]])}${icTextarea("Lý do sửa sai",cr11CorrectionReason,'data-cr11-correction-reason','Mô tả ngắn điều đã sai và căn cứ sửa')}`;
    const disabled=Number(cr11CorrectQty)<0||!cr11CorrectionReason.trim()||state==="SOURCE_VERSION_STALE"||state==="CONFLICT";
    return ac310SanitizeMarkup(appShell({title:"Nội dung sửa sai",body,actions:primaryFooter("Gửi phê duyệt",'data-cr11-action="submit-correction"',disabled)}));
  }
  const op=cr11Current(),delta=Number(cr11CorrectQty)-Number(op.qty);
  const body=`${state==="VALIDATION_ERROR"?vBanner("error","Kiểm tra nội dung sửa sai","Số đúng phải lớn hơn hoặc bằng 0 và cần có lý do."):""}${ac310InfoSurface("Trước khi sửa",[["Nghiệp vụ gốc",op.id,true],["Số đã ghi nhận",`${op.qty} ${op.uom}`],["Cách sửa",cr11Strategy==="DELTA"?"Sửa phần sai":"Hoàn nguyên và ghi lại đúng"]])}<div class="ac310-form-stack">${ac310Field("Số đúng",cr11CorrectQty,'data-cr11-correct-qty min="0" inputmode="decimal"','',"number")}${bj11Textarea("Lý do sửa sai",cr11CorrectionReason,'data-cr11-correction-reason')}</div>${bj11KeyValueSurface("Hệ thống tự tính",[["Điều chỉnh",`${delta>0?"+":""}${delta} ${op.uom}`,true]])}`;
  return ac310Return(appShell({title:"Nội dung sửa sai",body,actions:primaryFooter("Gửi phê duyệt",'data-cr11-action="submit-correction"',Number(cr11CorrectQty)<0||!cr11CorrectionReason.trim())}));
}


function bj11ExitList(){return primaryFooter("Về danh sách",'data-v360-action="fallback-exit" data-v360-target="SCR-048"');}
function render051BJ11(state){
  if(["READY","VALIDATION_ERROR"].includes(state)){
    const op=cr11Operations[1],delta=Number(cr11CorrectQty)-Number(op.qty);
    const sheet=cr11ApprovalRejectOpen?`<div class="sheet-backdrop"><section class="bottom-sheet ac310-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true"><div class="sheet-handle"></div><div class="sheet-title"><h3>Từ chối sửa sai</h3></div><div class="sheet-content">${state==="VALIDATION_ERROR"&&!cr11ApprovalRejectReason.trim()?vBanner("error","Cần nhập lý do từ chối","Lý do được lưu cùng quyết định."):""}${bj11Textarea("Lý do từ chối",cr11ApprovalRejectReason,'data-cr11-approval-reason')}<div class="sheet-actions"><button class="button button--secondary" type="button" data-cr11-action="reject-close">Đóng</button><button class="button button--danger" type="button" data-v350-action="cr11-reject-confirm" ${cr11ApprovalRejectReason.trim()?"":"disabled"}>Từ chối</button></div></div></section></div>`:"";
    const body=`${vBanner("info","Công việc phê duyệt độc lập","Quyết định chỉ duyệt phương án; hệ thống tự ghi nhận sửa sai sau khi kiểm tra lại điều kiện.")}${ac310InfoSurface("Yêu cầu sửa sai",[["Nghiệp vụ gốc",op.id,true],["Người lập","Nguyễn An"],["Lý do",cr11CorrectionReason]])}${bj11KeyValueSurface("Trước và sau",[["Trước",`${op.qty} ${op.uom}`],["Sau",`${cr11CorrectQty} ${op.uom}`],["Điều chỉnh",`${delta>0?"+":""}${delta} ${op.uom}`,true]])}${sheet}`;
    return ac310Return(appShell({title:"Duyệt sửa sai",body,actions:ac310ApprovalFooter('data-cr11-action="reject-open"','data-v350-action="cr11-approve"'),back:false}));
  }
  if(state==="PERMISSION_DENIED") return ac310SanitizeMarkup(appShell({title:"Duyệt sửa sai",body:deniedBody(),centered:true,actions:bj11ExitList(),back:false}));
  if(state==="SELF_APPROVAL_NOT_ALLOWED") return ac310SanitizeMarkup(appShell({title:"Duyệt sửa sai",body:`${vBanner("warning","Bạn không thể tự duyệt yêu cầu này","Người lập và người duyệt phải độc lập theo chính sách kiểm soát.")}`,actions:bj11ExitList(),back:false}));
  if(state==="APPROVAL_ALREADY_DECIDED") return ac310SanitizeMarkup(appShell({title:"Duyệt sửa sai",body:vBanner("info","Yêu cầu đã có quyết định","Mở kết quả sửa sai để xem trạng thái hiện hành."),actions:primaryFooter("Xem kết quả",'data-v350-action="cr11-approval-result"'),back:false}));
  return ac310SanitizeMarkup(appShell({title:"Duyệt sửa sai",body:deniedBody(),centered:true,actions:bj11ExitList(),back:false}));
}


function render053BJ11(state){
  let html;
  if(state==="PERMISSION_DENIED") html=appShell({title:"Kết quả sửa sai",body:deniedBody(),centered:true,actions:bj11ExitList(),back:false});
  else if(state==="PROCESSING") html=appShell({title:"Kết quả sửa sai",body:`${loadingBody()}${vBanner("info","Đang ghi nhận sửa sai","Hệ thống đang kiểm lại điều kiện và ghi nhận phần sửa sai theo quyết định đã duyệt.")}`,centered:true,back:false});
  else if(state==="PENDING_APPROVAL") html=appShell({title:"Kết quả sửa sai",body:ioResult("Đã gửi chờ duyệt","Bạn đã hoàn tất phần việc của mình. Người có quyền duyệt sẽ nhận một công việc riêng.",[["Nghiệp vụ gốc",cr11Current().id],["Tác động tồn kho","Chưa thay đổi"]],"warning"),actions:primaryFooter("Về danh sách",'data-cr11-action="to-list"'),centered:true,back:false});
  else if(state==="CANCELLED") html=appShell({title:"Kết quả kiểm soát",body:ioResult("Đã hủy yêu cầu","Yêu cầu dừng trước khi thực thi; không phát sinh biến động kho hoặc thay đổi giá trị tồn kho.",[["Nghiệp vụ",cr11Current().id],["Tồn kho","Không thay đổi"]]),actions:primaryFooter("Về danh sách",'data-cr11-action="to-list"'),centered:true,back:false});
  else if(state==="REJECTED") html=appShell({title:"Kết quả sửa sai",body:ioResult("Yêu cầu không được duyệt","Nghiệp vụ gốc được giữ nguyên và không có tác động tồn kho mới.",[["Nghiệp vụ gốc","IO-260901-014"],["Tồn kho","Không thay đổi"]],"warning"),actions:primaryFooter("Về danh sách",'data-cr11-action="to-list"'),centered:true,back:false});
  else if(state==="UNKNOWN") html=appShell({title:"Kết quả sửa sai",body:ioResult("Đang xác minh kết quả","Không tạo hoặc gửi lại yêu cầu sửa sai. Hệ thống đang xác minh đúng lần xử lý này.",[["Nghiệp vụ gốc","IO-260901-014"],["Kết quả","Chưa xác định"]],"warning"),actions:primaryFooter("Xác minh kết quả",'data-cr11-action="handoff-unknown"'),centered:true,back:false});
  else if(state==="BLOCKED") html=appShell({title:"Kết quả sửa sai",body:ioResult("Chưa thể ghi sửa sai","Điều kiện hiện hành không còn phù hợp. Nghiệp vụ gốc chưa bị thay đổi.",[["Nghiệp vụ gốc","IO-260901-014"],["Tác động mới","Không có"]],"warning"),actions:primaryFooter("Về danh sách",'data-cr11-action="to-list"'),centered:true,back:false});
  else html=appShell({title:"Kết quả sửa sai",body:ioResult("Đã hoàn tất sửa sai","Nghiệp vụ gốc được giữ nguyên; bản ghi sửa sai mới đã ghi phần điều chỉnh và liên kết đầy đủ.",[["Nghiệp vụ gốc","IO-260901-014"],["Bản ghi sửa sai","IO-260907-109"],["Điều chỉnh",`${Number(cr11CorrectQty)-120} hộp`]]),actions:primaryFooter("Về danh sách",'data-cr11-action="to-list"'),centered:true,back:false});
  return ac310SanitizeMarkup(html);
}


document.addEventListener("input",(event)=>{
  if(activeFlowId!=="UIF-11") return;
  if(event.target.matches("[data-cr11-search]")){cr11Query=event.target.value;return renderAppScreen();}
  if(event.target.matches("[data-cr11-correct-qty]")){cr11CorrectQty=Math.max(0,Number(event.target.value)||0);return renderAppScreen();}
  if(event.target.matches("[data-cr11-correction-reason]")){cr11CorrectionReason=event.target.value;return;}
  if(event.target.matches("[data-cr11-cancel-reason]")){cr11CancelReason=event.target.value;const btn=document.querySelector('[data-cr11-action="confirm-cancel"]');if(btn)btn.disabled=!cr11CancelReason.trim();return;}
  if(event.target.matches("[data-cr11-approval-reason]")){cr11ApprovalRejectReason=event.target.value;const btn=document.querySelector('[data-v350-action="cr11-reject-confirm"]');if(btn)btn.disabled=!cr11ApprovalRejectReason.trim();return;}
},true);
document.addEventListener("change",(event)=>{
  if(activeFlowId!=="UIF-11") return;
  if(event.target.matches("[data-cr11-strategy]")){cr11Strategy=event.target.value;return renderAppScreen();}
},true);
document.addEventListener("click",(event)=>{
  if(activeFlowId!=="UIF-11") return;
  const filter=event.target.closest("[data-cr11-filter]");if(filter){event.preventDefault();cr11Filter=filter.dataset.cr11Filter;return renderAppScreen();}
  const row=event.target.closest("[data-cr11-operation]");if(row){event.preventDefault();cr11SelectedId=row.dataset.cr11Operation;const op=cr11Current();stateByScreen["SCR-049"]=cr11StateFor(op);return navigate("SCR-049");}
  const a=event.target.closest("[data-cr11-action]");if(a&&!a.disabled){event.preventDefault();const k=a.dataset.cr11Action;
    if(k==="to-list"){cr11Query="";stateByScreen["SCR-048"]="READY";return navigate("SCR-048");}
    if(k==="back-detail")return navigate("SCR-049");
    if(k==="open-cancel"){stateByScreen["SCR-052"]="CANCEL_UNEXECUTED";cr11CancelReason="";return navigate("SCR-052");}
    if(k==="confirm-cancel"){if(!cr11CancelReason.trim()){stateByScreen["SCR-052"]="VALIDATION_ERROR";return renderAppScreen();}stateByScreen["SCR-053"]="CANCELLED";return navigate("SCR-053");}
    if(k==="open-correction"){stateByScreen["SCR-052"]="CORRECTION_ROUTE";return navigate("SCR-052");}
    if(k==="edit-correction"){cr11CorrectQty=cr11Current().correctQty||cr11Current().qty;stateByScreen["SCR-050"]="READY";return navigate("SCR-050");}
    if(k==="submit-correction"){if(Number(cr11CorrectQty)<0||!cr11CorrectionReason.trim()){stateByScreen["SCR-050"]="VALIDATION_ERROR";syncReviewUrl();return renderAppScreen();}stateByScreen["SCR-053"]="PENDING_APPROVAL";navigate("SCR-053");showToast("Đã gửi yêu cầu sửa sai","success");return;}
    if(k==="reject-open"){cr11ApprovalRejectOpen=true;cr11ApprovalRejectReason="";return renderAppScreen();}
    if(k==="reject-close"){cr11ApprovalRejectOpen=false;return renderAppScreen();}
    if(k==="handoff-unknown"){cr17SelectedId="REC-UNKNOWN-01";stateByScreen["SCR-079"]="UNKNOWN_EVIDENCE";return crSwitchFlow("UIF-17","SCR-079","UNKNOWN_EVIDENCE");}
  }
  const v=event.target.closest("[data-v350-action]");if(!v||v.disabled)return;
  const vk=v.dataset.v350Action;
  if(!["cr11-approval-result","cr11-approve","cr11-reject-confirm"].includes(vk))return;
  event.preventDefault();event.stopPropagation();
  if(vk==="cr11-approval-result")return navigate("SCR-053");
  if(currentActor()!=="approver"){stateByScreen["SCR-051"]="SELF_APPROVAL_NOT_ALLOWED";syncReviewUrl();return renderAppScreen();}
  if(vk==="cr11-approve"){
    stateByScreen["SCR-053"]="PROCESSING";navigate("SCR-053");setTimeout(()=>{if(activeFlowId==="UIF-11"&&activeScreenId==="SCR-053"&&stateByScreen["SCR-053"]==="PROCESSING"){stateByScreen["SCR-053"]="COMPLETED";syncReviewUrl();render();}},300);return;
  }
  if(vk==="cr11-reject-confirm"){
    if(!cr11ApprovalRejectReason.trim()){stateByScreen["SCR-051"]="VALIDATION_ERROR";syncReviewUrl();return renderAppScreen();}cr11ApprovalRejectOpen=false;stateByScreen["SCR-053"]="REJECTED";return navigate("SCR-053");
  }
},true);


Object.assign(renderers, {
  "SCR-048": render048BJ11,
  "SCR-049": render049BJ11,
  "SCR-052": render052BJ11,
  "SCR-050": render050BJ11,
  "SCR-051": render051BJ11,
  "SCR-053": render053BJ11
});
