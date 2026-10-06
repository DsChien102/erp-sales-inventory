/* VET45 Theme 7 v3.1.0 — Inventory Audit & Control cluster
 * Scope: BJ08, BJ09, BJ10, BJ11, BJ12, BJ15, BJ16, BJ17.
 * Figma DS is UI authority. Existing app.js remains business/state authority.
 * This patch only replaces presentation renderers and preserves existing handlers/data.
 */

const AC310_SCREEN_IDS = [
  "SCR-036","SCR-037","SCR-038","SCR-040","SCR-041","SCR-042","SCR-043","SCR-044","SCR-045","SCR-046","SCR-047",
  "SCR-048","SCR-049","SCR-050","SCR-051","SCR-052","SCR-053",
  "SCR-054","SCR-055","SCR-056","SCR-057","SCR-058","SCR-059",
  "SCR-066","SCR-067","SCR-068","SCR-069","SCR-070","SCR-071",
  "SCR-078","SCR-079","SCR-080","SCR-081","SCR-082","SCR-083"
];
const ac310BaseRenderers = Object.fromEntries(AC310_SCREEN_IDS.map((id)=>[id, renderers[id]]));

function ac310Tone(tone="Neutral") {
  const map={success:"Success",warning:"Warning",danger:"Danger",error:"Danger",info:"Info",neutral:"Neutral",brand:"Brand"};
  return map[String(tone).toLowerCase()] || tone;
}
function ac310CleanText(text) {
  let out=String(text??"");
  const replacements=[
    [/\bauthoritative\b/gi,"chính thức"],
    [/\bDOM\b/g,"giao diện"],
    [/\bguard\b/gi,"điều kiện kiểm soát"],
    [/\bledger\b/gi,"sổ kho"],
    [/\brecovery\b/gi,"khôi phục"],
    [/\bcommit\b/gi,"ghi nhận"],
    [/\bUNKNOWN\b/g,"chưa xác định"],
    [/\bCut[- ]?off\b/gi,"Thời điểm chốt"],
    [/\bLOT\b/g,"Lô"],
    [/\bUOM\b/g,"Đơn vị"],
    [/\bblocker\b/gi,"điều kiện chưa đạt"],
    [/\bdependency\b/gi,"nghiệp vụ phụ thuộc"],
    [/\bprojection\b/gi,"số liệu hiển thị"],
    [/\bfinality\b/gi,"kết quả chính thức"]
  ];
  replacements.forEach(([re,val])=>{out=out.replace(re,val);});
  return out;
}
function ac310SanitizeMarkup(html) {
  const template=document.createElement("template");
  template.innerHTML=String(html||"");
  const walker=document.createTreeWalker(template.content,NodeFilter.SHOW_TEXT);
  const nodes=[]; while(walker.nextNode()) nodes.push(walker.currentNode);
  nodes.forEach((node)=>{node.nodeValue=ac310CleanText(node.nodeValue);});
  return template.innerHTML;
}
function ac310Base(id,state){
  const fn=ac310BaseRenderers[id];
  return ac310SanitizeMarkup(fn?fn(state):renderGeneric(screens.find((s)=>s.id===id),state));
}
function ac310Return(html){return ac310SanitizeMarkup(html);}
function ac310SectionTitle(title,meta=""){
  return `<div class="ac310-section-title" data-ds-component="VText"><h2>${esc(title)}</h2>${meta?`<span>${esc(meta)}</span>`:""}</div>`;
}
function ac310InfoSurface(title,rows,{extraClass="",badge="",badgeTone="Neutral"}={}){
  const head=title?`<div class="ac310-surface__head"><h2>${esc(title)}</h2>${badge?ds24Badge(badge,ac310Tone(badgeTone)):""}</div>`:"";
  const body=(rows||[]).map((r)=>ds24InfoRow(r[0],r[1],r[2]?"ac310-info-row--emphasis":"")).join("");
  return `<section class="ac310-surface ${extraClass}" data-layout-pattern="Grouped surface" data-composed-from="DS v2 / Info Row${badge?',VBadge':''}">${head}<div class="ac310-info-rows">${body}</div></section>`;
}
function ac310KeyValueSurface(title,rows,{extraClass=""}={}){
  const head=title?`<div class="ac310-surface__head"><h2>${esc(title)}</h2></div>`:"";
  return `<section class="ac310-surface ${extraClass}" data-layout-pattern="Grouped surface" data-composed-from="DS v2 / Key-value Row">${head}<div class="ac310-key-value-stack">${(rows||[]).map((r)=>ds24KeyValueRow(r[0],r[1],!!r[2])).join("")}</div></section>`;
}
function ac310RecordRow({title,subtitle="",badge="",tone="Neutral",attrs="",leading=null,status=false,disabled=false,extraClass=""}){
  return ds24ListRow({title,subtitle,trailing:badge?ds24Badge(badge,ac310Tone(tone)):"",leading,attrs,type:status?"Status":"Navigation",density:status?"Compact":"Default",interactive:!status,disabled,extraClass:`ac310-record-row ${extraClass}`.trim()});
}
function ac310ProductRow({name,code,meta="",badge="",tone="Neutral",attrs="",status=false}){
  const subtitle=[code,meta].filter(Boolean).join(" · ");
  return ds24ListRow({title:name,subtitle,trailing:badge?ds24Badge(badge,ac310Tone(tone)):"",leading:"package",attrs,type:status?"Status":"Navigation",density:status?"Compact":"Default",interactive:!status,extraClass:"ac310-product-row"});
}
function ac310ListSurface(rows,extra=""){
  return ds24GroupedCollection(`<div class="ac310-list-stack">${rows}</div>`,`ac310-list-surface ${extra}`,"DS v2 / List Row,VBadge");
}
function ac310RadioChoice({value,label,detail="",checked=false,attrs="",disabled=false}){
  return `<label class="ac310-radio-row${disabled?' is-disabled':''}" data-ds-component="VRadio" data-figma-node="522:7410"><input type="radio" value="${escapeAttribute(value)}" ${attrs} ${checked?'checked':''} ${disabled?'disabled':''}><span class="ac310-radio-control" aria-hidden="true"></span><span class="ac310-radio-copy"><strong>${esc(label)}</strong>${detail?`<small>${esc(detail)}</small>`:""}</span></label>`;
}
function ac310RadioSurface(title,choices){
  return `<section class="ac310-surface ac310-radio-surface" data-composed-from="VText,VRadio">${title?`<div class="ac310-surface__head"><h2>${esc(title)}</h2></div>`:""}<div class="ac310-radio-list">${choices.join("")}</div></section>`;
}
function ac310AuditItem(type,title,meta){
  const t=String(type||"System");
  const iconName=t==="Create"?"checkCircle":t==="Update"?"edit":t==="Delete"?"alert":"info";
  return `<div class="ac310-audit-item ac310-audit-item--${t.toLowerCase()}" data-ds-component="DS v2 / Audit Item" data-figma-node="525:621" data-ds-prop-type="${t}">${icon(iconName,"ac310-audit-item__icon")}<span class="ac310-audit-item__copy"><strong>${esc(title)}</strong><small>${esc(meta)}</small></span></div>`;
}
function ac310AuditSurface(title,items){
  return `<section class="ac310-audit-surface" data-composed-from="DS v2 / Audit Item">${title?ac310SectionTitle(title):""}<div class="ac310-audit-list">${items.join("")}</div></section>`;
}
function ac310Field(label,value,attrs="",helper="",type="text"){
  const component=type==="number"?"VNumberField":type==="date"?"VDateField":"VTextField";
  return `<label class="ac310-field" data-ds-component="${component}"><span>${esc(label)}</span><input type="${type}" value="${escapeAttribute(value)}" ${attrs}>${helper?`<small>${esc(helper)}</small>`:""}</label>`;
}
function ac310Textarea(label,value,attrs="",helper=""){
  return `<label class="ac310-field" data-ds-component="VTextarea" data-figma-node="522:7212"><span>${esc(label)}</span><textarea ${attrs}>${esc(value)}</textarea>${helper?`<small>${esc(helper)}</small>`:""}</label>`;
}
function ac310FileDrop(title,fileName,attrs=""){
  return `<section class="ac310-file-drop" data-ds-component="VFileDropZone"><div class="ac310-file-drop__icon">${icon("fileText")}</div><div class="ac310-file-drop__copy"><strong>${esc(title)}</strong><small>${esc(fileName||"Chưa chọn tệp")}</small></div><button type="button" class="button button--secondary" ${attrs} data-ds-component="VButton">Chọn tệp</button></section>`;
}
function ac310ApprovalFooter(rejectAttr,approveAttr,approveLabel="Duyệt"){
  return `<footer class="app-actions figma-sticky-footer ac310-two-actions" data-ds-pattern="Sticky Footer"><button class="button button--secondary" type="button" ${rejectAttr} data-ds-component="VButton">Từ chối</button><button class="button button--primary" type="button" ${approveAttr} data-ds-component="VButton">${esc(approveLabel)}</button></footer>`;
}
function ac310SummaryMetrics(items){
  return `<section class="ac310-metrics" data-composed-from="DS v2 / Metric Card">${items.map(([label,value])=>`<div class="ac310-metric" data-ds-component="DS v2 / Metric Card" data-figma-node="525:382"><span>${esc(label)}</span><strong>${esc(String(value))}</strong></div>`).join("")}</section>`;
}
function ac310Result(title,desc,rows,tone="success"){
  return ioResult(title,desc,rows,tone);
}

/* ------------------------------ BJ08 ----------------------------------- */
function ac310Render042(state){
  if(!["READY","PENDING_APPROVAL"].includes(state)) return ac310Base("SCR-042",state);
  if(state==="PENDING_APPROVAL"){
    return ac310Return(appShell({title:"Kiểm kê kho",body:`${vBanner("info","Đã gửi chờ duyệt","Kết quả đếm lại đã được gửi sang công việc duyệt độc lập. Tồn kho chưa thay đổi.")}${ac310InfoSurface("Phiên kiểm kê",[["Mã phiên","KK-0709-03",true],["Kho","Kho trung tâm"],["Trạng thái","Chờ duyệt"]])}`,back:false}));
  }
  const chips=`<div class="ds24-chip-scroll">${ds24Chip("ALL","Tất cả",true,"data-ic08-filter")}${ds24Chip("COUNTING","Đang đếm",false,"data-ic08-filter")}${ds24Chip("APPROVAL","Chờ duyệt",false,"data-ic08-filter")}</div>`;
  const row=ac310RecordRow({title:"KK-0709-03",subtitle:"Kho trung tâm · Toàn kho · 12/38 đã đếm",badge:"Đang đếm",tone:"Info",attrs:'data-ic08-action="resume"',leading:null});
  const session=`${ac310ListSurface(row,"ac310-count-session-list")}<button class="button button--secondary ac310-danger-text" type="button" data-ic08-action="cancel-open" data-ds-component="VButton">Hủy phiên</button>`;
  return ac310Return(appShell({title:"Kiểm kê kho",body:`${ds24Search("","","Tìm phiên kiểm kê")}${chips}${ac310SectionTitle("Phiên đang thực hiện","1 phiên")}${session}${ic08Overlays()}`,actions:primaryFooter("Tạo phiên kiểm kê",'data-ic08-action="create"'),back:false}));
}
function ac310Render043(state){
  if(!["READY","VALIDATION_ERROR"].includes(state)) return ac310Base("SCR-043",state);
  const validation=state==="VALIDATION_ERROR"?vBanner("error","Chưa đủ thông tin","Chọn phạm vi và nhập lý do kiểm kê trước khi mở phiên."):"";
  const scopeOptions=[["ALL","Toàn kho"],["PRODUCT","Sản phẩm"],["GROUP","Nhóm sản phẩm"],["LOT","Lô"]];
  const target=ic08Scope!=="ALL"?`<div class="ds24-field"><span class="vet45-text-style-8">${ic08Scope==="PRODUCT"?"Sản phẩm":ic08Scope==="GROUP"?"Nhóm sản phẩm":"Lô"}</span><button type="button" class="ds24-field__control ds24-select-trigger" data-ic08-action="scope-select-open"><span>${esc(ic08ScopeTarget||"Chọn phạm vi")}</span>${icon("chevronRight","icon--sm")}</button></div>`:"";
  const body=`${validation}${ac310InfoSurface("Thông tin phiên",[["Kho","Kho trung tâm"],["Thời điểm chốt","09/09/2026 · 08:00"],["Người đếm",ic08AssignedCounter]])}<div class="ac310-form-stack">${ds24SelectField("Phạm vi",ic08Scope,scopeOptions,"data-ic08-scope")}${target}${ds24TextField("Lý do kiểm kê",ic08Reason,"data-ic08-reason","")}</div>${vBanner("info","Phạm vi sẽ được khóa","Sau khi mở phiên, phạm vi và thời điểm chốt được giữ nguyên cho lần kiểm kê này.")}${ic08Overlays()}`;
  return ac310Return(appShell({title:"Tạo phiên kiểm kê",body,actions:primaryFooter("Mở phiên kiểm kê",'data-ic08-action="open-session"',ic08Scope!=="ALL"&&!ic08ScopeTarget)}));
}
function ac310CountGroup({id,name,code,lot,uom,value,unexpected=false,disabled=false}){
  const parent=ac310ProductRow({name,code,meta:`${lot?`Lô ${lot} · `:""}${uom}`,badge:unexpected?"Bổ sung thực tế":"Cần đếm",tone:unexpected?"Info":"Neutral",status:true});
  return `<section class="ac310-product-control-group" data-composed-from="DS v2 / List Row,VNumericKeypadSheet">${parent}<div class="ac310-control-indent">${ic08QuantityTrigger("Số lượng thực tế",value,`count:${id}`,uom,disabled)}</div></section>`;
}
function ac310RecountGroup({id,name,code,lot,uom,book,first,variance,value,disabled=false}){
  const parent=ac310ProductRow({name,code,meta:`Lô ${lot} · ${uom}`,badge:variance,tone:"Warning",status:true});
  return `<section class="ac310-product-control-group" data-composed-from="DS v2 / List Row,DS v2 / Key-value Row,VNumericKeypadSheet">${parent}<div class="ac310-control-indent">${ac310KeyValueSurface("",[["Theo sổ",`${book} ${uom}`],["Lần đếm đầu",`${first} ${uom}`],["Chênh lệch",variance,true]],{extraClass:"ac310-inline-surface"})}${ic08QuantityTrigger("Số lượng đếm lại",value,`recount:${id}`,uom,disabled)}</div></section>`;
}
function ac310Render044(state){
  if(!["BLIND_COUNT","READY","VALIDATION_ERROR","LOCK_LOST"].includes(state)) return ac310Base("SCR-044",state);
  const lost=state==="LOCK_LOST";
  const error=state==="VALIDATION_ERROR"?vBanner("error","Chưa nhập đủ kết quả","Nhập số đếm thực tế cho tất cả dòng trước khi nộp."):"";
  const notice=lost?vBanner("warning","Phiên không còn giữ khóa","Số đã nhập được giữ trên thiết bị. Quay về phiên kiểm kê để tải lại trạng thái hiện hành trước khi tiếp tục."):vBanner("info","Đang đếm mù","Chỉ nhập số thực tế. Số theo sổ và chênh lệch chỉ hiển thị sau lần nộp đầu.");
  const groups=[ac310CountGroup({id:"amox",name:"Amox 500",code:"SP-00128",lot:"L2407-A",uom:"hộp",value:ic08Counts.amox,disabled:lost}),ac310CountGroup({id:"glove",name:"Găng tay M",code:"SP-00410",lot:"L2405-M",uom:"hộp",value:ic08Counts.glove,disabled:lost})];
  if(ic08UnexpectedLine) groups.push(ac310CountGroup({id:"unexpected",name:ic08UnexpectedLine.name,code:"Hàng thực tế bổ sung",lot:ic08UnexpectedLine.lot,uom:ic08UnexpectedLine.uom,value:ic08UnexpectedLine.value,unexpected:true,disabled:lost}));
  const body=`${error}${notice}${ac310InfoSurface("Phiên kiểm kê",[["Mã phiên","KK-0709-03"],["Kho","Kho trung tâm"],["Thời điểm chốt","09/09/2026 · 08:00"]])}${ac310SectionTitle("Hàng cần đếm",`${groups.length} dòng`)}<div class="ac310-product-control-list">${groups.join("")}</div>${!lost?`<button class="button button--secondary ac310-inline-button" type="button" data-ic08-action="add-actual-open" data-ds-component="VButton">Thêm hàng thực tế</button>`:""}${ic08Overlays()}`;
  return ac310Return(appShell({title:"Đếm mù",body,actions:lost?primaryFooter("Về phiên kiểm kê",'data-ic08-action="to-list"'):primaryFooter("Nộp kết quả đếm",'data-ic08-action="submit-first"')}));
}
function ac310Render045(state){
  if(!["RECOUNT_REQUIRED","READY","LOCKED","PRICE_BASIS_REQUIRED","EVIDENCE_REQUIRED","VALIDATION_ERROR"].includes(state)) return ac310Base("SCR-045",state);
  const locked=state==="LOCKED",price=state==="PRICE_BASIS_REQUIRED",evidence=state==="EVIDENCE_REQUIRED";
  const notice=locked?vBanner("warning","Phiên đang chỉ đọc","Không thể sửa kết quả đếm trong trạng thái hiện hành."):price?vBanner("error","Chưa đủ căn cứ giá","Dòng thừa chưa có căn cứ giá hợp lệ. Phiên vẫn được giữ khóa."):evidence?vBanner("warning","Chưa đủ bằng chứng","Bổ sung bằng chứng cần thiết trước khi gửi duyệt."):state==="VALIDATION_ERROR"?vBanner("error","Kết quả đếm lại chưa hợp lệ","Kiểm tra số lượng đếm lại trước khi gửi."):vBanner("info","Chỉ đếm lại dòng có chênh lệch","Số theo sổ đã được hiển thị sau lần đếm đầu.");
  const groups=[ac310RecountGroup({id:"amox",name:"Amox 500",code:"SP-00128",lot:"L2407-A",uom:"hộp",book:20,first:18,variance:"−2 hộp",value:ic08Recounts.amox,disabled:locked}),ac310RecountGroup({id:"glove",name:"Găng tay M",code:"SP-00410",lot:"L2405-M",uom:"hộp",book:6,first:7,variance:"+1 hộp",value:ic08Recounts.glove,disabled:locked})];
  const evidenceRows=[["Amox 500","Đã có bằng chứng"],["Găng tay M",price?"Thiếu căn cứ giá":evidence?"Thiếu bằng chứng":"Đã có căn cứ"]];
  const body=`${notice}<div class="ac310-product-control-list">${groups.join("")}</div>${ac310InfoSurface("Căn cứ và bằng chứng",evidenceRows)}${(price||evidence)?vBanner("warning","Chưa thể gửi duyệt","Chỉ có thể gửi khi tất cả căn cứ bắt buộc đã hợp lệ."):""}${ic08Overlays()}`;
  let actions=""; if(!locked) actions=`<footer class="app-actions figma-sticky-footer ac310-footer-stack"><button class="button button--primary" type="button" data-ic08-action="submit-recount" data-ds-component="VButton" ${price||evidence?'disabled':''}>Gửi chờ duyệt</button>${price||evidence?`<button class="button button--secondary ac310-danger-text" type="button" data-ic08-action="cancel-open" data-ds-component="VButton">Hủy phiên</button>`:""}</footer>`;
  return ac310Return(appShell({title:"Chênh lệch và đếm lại",body,actions}));
}
function ac310Render046(state){
  if(!["READY","APPROVAL_REVIEW"].includes(state)) return ac310Base("SCR-046",state);
  const body=`${vBanner("info","Cần quyết định độc lập","Người duyệt chỉ rà soát bằng chứng và quyết định; không sửa số đếm.")}${ac310InfoSurface("Phiên kiểm kê",[["Mã phiên","KK-0709-03",true],["Người thực hiện","Nguyễn An"],["Kho","Kho trung tâm"],["Dòng chênh lệch","2 dòng"]])}${ac310ProductRow({name:"Amox 500",code:"SP-00128",meta:"Lô L2407-A · hộp",badge:"−2 hộp",tone:"Warning",status:true})}${ac310KeyValueSurface("",[["Đếm lại","18 hộp"],["Bằng chứng","Đã đủ"]],{extraClass:"ac310-approval-detail"})}${ac310ProductRow({name:"Găng tay M",code:"SP-00410",meta:"Lô L2405-M · hộp",badge:"+1 hộp",tone:"Warning",status:true})}${ac310KeyValueSurface("",[["Đếm lại","7 hộp"],["Căn cứ giá","Đã đủ"],["Bằng chứng","Đã đủ"]],{extraClass:"ac310-approval-detail"})}${ic08Overlays()}`;
  const actions=`<footer class="app-actions figma-sticky-footer ac310-two-actions"><button class="button button--secondary" type="button" data-ic08-action="request-review" data-ds-component="VButton">Yêu cầu xem lại</button><button class="button button--primary" type="button" data-ic08-action="approve" data-ds-component="VButton">Duyệt và điều chỉnh</button></footer>`;
  return ac310Return(appShell({title:"Duyệt kết quả kiểm kê",body,actions,back:false}));
}

/* ------------------------------ BJ09 ----------------------------------- */
function ac310Render036(state){
  if(activeFlowId==="UIF-09"){
    if(!["READY","FILTER_EMPTY"].includes(state)) return ac310Base("SCR-036",state);
    const labels=[["ALL","Tất cả"],["SELLABLE","Bán được"],["QUARANTINE","Cách ly"],["DAMAGED","Hỏng"],["DEMO","Dùng thử"],["EXPIRED","Hết hạn"]];
    const q=ic09Query.trim().toLowerCase();
    const items=ic09Items.filter((x)=>(ic09Filter==="ALL"||x.state===ic09Filter)&&(!q||`${x.name} ${x.code} ${x.lot}`.toLowerCase().includes(q)));
    const rows=items.map((x)=>ac310ProductRow({name:x.name,code:x.code,meta:`Lô ${x.lot} · ${x.qty} ${x.uom}`,badge:x.label,tone:ic09StatusTone(x.state),attrs:`data-ic09-item="${x.id}"`})).join("");
    const body=`${ds24Search(ic09Query,"data-ic09-search","Tìm sản phẩm hoặc lô")}<div class="ds24-chip-scroll">${labels.map(([k,l])=>ds24Chip(k,l,ic09Filter===k,"data-ic09-filter")).join("")}</div>${rows?ac310ListSurface(rows):ioEmpty("Không có hàng phù hợp","Thử đổi bộ lọc hoặc từ khóa tìm kiếm.")}`;
    return ac310Return(appShell({title:"Tình trạng hàng",body,back:false}));
  }
  if(activeFlowId==="UIF-10"){
    if(state!=="READY") return ac310Base("SCR-036",state);
    const rows=`${ac310ProductRow({name:"Amox 500",code:"SP-00128",meta:"Lô L2407-A · 6 hộp",badge:"Cách ly",tone:"Warning",attrs:'data-ic10-item="amox-l2407"'})}${ac310ProductRow({name:"Vitamin C",code:"SP-00231",meta:"Lô L2310-C · 4 hộp",badge:"Hết hạn",tone:"Danger",attrs:'data-ic10-item="vitc-l2310"'})}`;
    return ac310Return(appShell({title:"Hàng có thể xử lý",body:`${vBanner("info","Chỉ hiển thị hàng đủ điều kiện","Hàng đang bán được cần đổi tình trạng trước khi có thể đề nghị tiêu hủy.")}${ac310ListSurface(rows)}`,back:false}));
  }
  return ac310Base("SCR-036",state);
}
function ac310Render037(state){
  if(activeFlowId==="UIF-09"){
    if(!["READY","EXPIRED","LOCKED"].includes(state)) return ac310Base("SCR-037",state);
    const x=ic09Current(),expired=state==="EXPIRED"||x.state==="EXPIRED",locked=state==="LOCKED";
    const notice=expired?vBanner("warning","Lô đã hết hạn","Lượng hàng này tự động không còn khả dụng bán theo hạn dùng."):locked?vBanner("info","Đang thuộc phạm vi kiểm kê","Thông tin chỉ đọc cho đến khi phiên kiểm kê kết thúc."):"";
    const body=`${notice}${ac310ProductRow({name:x.name,code:x.code,meta:`Lô ${x.lot} · ${x.qty} ${x.uom}`,badge:expired?"Hết hạn":x.label,tone:ic09StatusTone(expired?"EXPIRED":x.state),status:true})}${ac310KeyValueSurface("Thông tin",[["Hạn dùng",x.expiry],["Tồn vật lý",`${x.qty} ${x.uom}`],["Khả dụng bán",expired||x.state!=="SELLABLE"?`0 ${x.uom}`:`${x.qty} ${x.uom}`]])}<p class="ac310-note">Thay đổi tình trạng chỉ phân loại lại cùng lượng hàng; tổng tồn vật lý và giá trị không đổi.</p><button class="button button--secondary ac310-inline-button" type="button" data-ic09-action="history" data-ds-component="VButton">Xem lịch sử</button>`;
    return ac310Return(appShell({title:"Chi tiết tình trạng hàng",body,actions:locked||expired?"":primaryFooter("Thay đổi tình trạng",'data-ic09-action="change"')}));
  }
  if(activeFlowId==="UIF-10"){
    if(!["READY","LOCKED"].includes(state)) return ac310Base("SCR-037",state);
    const locked=state==="LOCKED";
    const body=`${locked?vBanner("info","Đang thuộc phạm vi kiểm kê","Thông tin chỉ đọc cho đến khi phiên kiểm kê kết thúc."):""}${ac310ProductRow({name:"Amox 500",code:"SP-00128",meta:"Lô L2407-A · 6 hộp",badge:"Cách ly",tone:"Warning",status:true})}${ac310KeyValueSurface("Thông tin",[["Tồn vật lý","6 hộp"],["Quyền sở hữu","Hàng của tổ chức"],["Có thể xử lý","6 hộp"]])}<p class="ac310-note">Duyệt yêu cầu chưa làm giảm tồn. Tồn chỉ giảm sau khi xác nhận lượng đã tiêu hủy thực tế.</p>`;
    return ac310Return(appShell({title:"Chi tiết hàng",body,actions:locked?"":primaryFooter("Đề nghị tiêu hủy",'data-ic10-action="request"')}));
  }
  return ac310Base("SCR-037",state);
}
function ac310StateLabel(value){return value==="QUARANTINE"?"Cách ly":value==="DAMAGED"?"Hỏng":value==="DEMO"?"Dùng thử":"Bán được";}
function ac310Render038(state){
  if(activeFlowId!=="UIF-09") return ac310Base("SCR-038",state);
  if(state==="APPROVAL_REVIEW"){
    const x=ic09Current();
    const body=`${vBanner("info","Yêu cầu thay đổi tình trạng","Kiểm tra lý do và phạm vi trước khi quyết định.")}${ac310ProductRow({name:x.name,code:x.code,meta:`Lô ${x.lot} · ${x.qty} ${x.uom}`,badge:`${x.label} → ${ac310StateLabel(ic09Destination)}`,tone:"Info",status:true})}${ac310InfoSurface("Nội dung yêu cầu",[["Tình trạng hiện tại",x.label],["Tình trạng mới",ac310StateLabel(ic09Destination)],["Lý do","Bao bì có dấu hiệu bất thường"]])}`;
    return ac310Return(appShell({title:"Duyệt thay đổi tình trạng",body,actions:ac310ApprovalFooter('data-ic09-action="reject"','data-ic09-action="approve"'),back:false}));
  }
  if(!["READY","VALIDATION_ERROR"].includes(state)) return ac310Base("SCR-038",state);
  const x=ic09Current();
  const choices=[ac310RadioChoice({value:"QUARANTINE",label:"Cách ly",detail:"Tạm thời không bán",checked:ic09Destination==="QUARANTINE",attrs:'name="ic-state" data-ic09-destination'}),ac310RadioChoice({value:"DAMAGED",label:"Hỏng",detail:"Không còn đủ điều kiện bán",checked:ic09Destination==="DAMAGED",attrs:'name="ic-state" data-ic09-destination'}),ac310RadioChoice({value:"DEMO",label:"Dùng thử",detail:"Chuyển sang mục đích dùng thử",checked:ic09Destination==="DEMO",attrs:'name="ic-state" data-ic09-destination'})];
  if(x.state!=="SELLABLE") choices.push(ac310RadioChoice({value:"SELLABLE",label:"Bán được",detail:"Chỉ khi hàng đủ điều kiện trở lại bán",checked:ic09Destination==="SELLABLE",attrs:'name="ic-state" data-ic09-destination'}));
  const body=`${state==="VALIDATION_ERROR"?vBanner("error","Chưa đủ thông tin","Chọn tình trạng mới và nhập lý do phù hợp."):""}${ac310ProductRow({name:x.name,code:x.code,meta:`Lô ${x.lot} · ${x.qty} ${x.uom}`,badge:x.label,tone:ic09StatusTone(x.state),status:true})}${ac310RadioSurface("Tình trạng mới",choices)}${ac310Textarea("Lý do","Bao bì có dấu hiệu bất thường",'data-ic09-reason',"")}`;
  return ac310Return(appShell({title:"Chuyển tình trạng hàng",body,actions:primaryFooter("Gửi xử lý",'data-ic09-action="submit"')}));
}
function ac310Render041(state){
  if(activeFlowId==="UIF-09"||activeFlowId==="UIF-10") return ac310Base("SCR-041",state);
  return ac310Base("SCR-041",state);
}
function ac310Render056(state){
  if(activeFlowId==="UIF-09"){
    if(!["READY","LOADING","PERMISSION_DENIED"].includes(state)) return ac310Base("SCR-056",state);
    if(state!=="READY") return ac310Base("SCR-056",state);
    const x=ic09Current();
    const body=`${ac310ProductRow({name:x.name,code:x.code,meta:`Lô ${x.lot}`,badge:x.label,tone:ic09StatusTone(x.state),status:true})}${ac310AuditSurface("Lịch sử",[ac310AuditItem("Update","Bán được → Cách ly","07/09/2026 · 09:14 · Nguyễn An · Bao bì có dấu hiệu bất thường"),ac310AuditItem("Create","Nhận vào kho","01/09/2026 · 08:00 · Tình trạng ban đầu: Bán được")])}`;
    return ac310Return(appShell({title:"Lịch sử tình trạng",body}));
  }
  if(activeFlowId==="UIF-15") return ac310Render056CF15(state);
  return ac310Base("SCR-056",state);
}

/* ------------------------------ BJ10 ----------------------------------- */
function ac310Render040(state){
  if(activeFlowId!=="UIF-10") return ac310Base("SCR-040",state);
  if(["PERMISSION_DENIED"].includes(state)) return ac310Base("SCR-040",state);
  const product=ac310ProductRow({name:"Amox 500",code:"SP-00128",meta:"Lô L2407-A · 6 hộp",badge:"Cách ly",tone:"Warning",status:true});
  if(state==="PENDING_APPROVAL") return ac310Return(appShell({title:"Yêu cầu tiêu hủy",body:`${vBanner("info","Đã gửi chờ duyệt","Tồn kho chưa thay đổi. Người duyệt nhận một công việc riêng.")}${product}${ac310InfoSurface("Yêu cầu",[["Số lượng đề nghị","6 hộp",true],["Tác động tồn kho","Chưa có"]])}`,back:false}));
  if(state==="APPROVAL_REVIEW") return ac310Return(appShell({title:"Duyệt tiêu hủy",body:`${vBanner("info","Duyệt chưa phải tiêu hủy","Duyệt chỉ cho phép chuyển sang chờ xử lý thực tế. Tồn vật lý chưa giảm.")}${product}${ac310InfoSurface("Nội dung yêu cầu",[["Số lượng đề nghị","6 hộp",true],["Căn cứ giá","Giá vốn hiện hành"],["Lý do","Hàng không còn đủ điều kiện sử dụng"]])}`,actions:ac310ApprovalFooter('data-ic10-action="reject"','data-ic10-action="approve"'),back:false}));
  if(state==="APPROVED_PENDING_DISPOSAL") return ac310Return(appShell({title:"Yêu cầu tiêu hủy",body:`${vBanner("success","Đã duyệt — chờ xử lý thực tế","Tồn kho vẫn giữ nguyên cho tới khi có xác nhận đã tiêu hủy.")}${product}${ac310InfoSurface("Trạng thái",[["Đã duyệt","6 hộp",true],["Tồn vật lý hiện tại","6 hộp · chưa giảm"]])}`,back:false}));
  const completion=state==="COMPLETION"||state==="COMPLETION_QTY_BLOCKED";
  const priceBlocked=state==="PRICE_BASIS_REQUIRED";
  const banner=completion?(state==="COMPLETION_QTY_BLOCKED"?vBanner("error","Số lượng thực tế vượt phạm vi được duyệt","Không thể ghi giảm phần vượt."):vBanner("warning","Chỉ xác nhận sau khi đã xử lý thực tế","Số lượng xác nhận sẽ là căn cứ ghi giảm tồn.")):priceBlocked?vBanner("error","Chưa có căn cứ giá hợp lệ","Không thể gửi yêu cầu cho tới khi có căn cứ giá chính thức."):"";
  const fields=completion?`${ac310Field("Đã tiêu hủy thực tế",state==="COMPLETION_QTY_BLOCKED"?"7":"6",'data-ic10-actual','',"number")}${ac310Textarea("Bằng chứng","Biên bản tiêu hủy #TH-0709",'data-ic10-proof')}`:`${ac310Field("Số lượng đề nghị","6",'data-ic10-qty','',"number")}${ac310Textarea("Lý do","Hàng không còn đủ điều kiện sử dụng",'data-ic10-reason')}${!priceBlocked?ac310Textarea("Bằng chứng","Ảnh hiện trạng và biên bản kiểm tra",'data-ic10-evidence'):""}`;
  const body=`${banner}${product}${ac310InfoSurface("Thông tin xử lý",[["Có thể xử lý","6 hộp"],["Căn cứ giá",priceBlocked?"Chưa đủ":"Giá vốn hiện hành"]])}<div class="ac310-form-stack">${fields}</div>`;
  return ac310Return(appShell({title:completion?"Xác nhận đã tiêu hủy":"Yêu cầu tiêu hủy",body,actions:primaryFooter(completion?"Xác nhận đã tiêu hủy":"Gửi yêu cầu tiêu hủy",completion?'data-ic10-action="complete"':'data-ic10-action="submit"',priceBlocked||state==="COMPLETION_QTY_BLOCKED",completion?"danger":undefined),back:false}));
}

/* ------------------------------ BJ11 ----------------------------------- */
function ac310Render048(state){
  if(activeFlowId!=="UIF-11") return ac310Base("SCR-048",state);
  if(state!=="READY") return ac310Base("SCR-048",state);
  const labels={ALL:"Tất cả",CANCEL:"Có thể hủy",CORRECT:"Có thể sửa",UNKNOWN:"Đang xác minh"};
  const rows=cr11Operations.filter((op)=>cr11Filter==="ALL"||op.route===cr11Filter).filter((op)=>ioMatchesSearch(cr11Query,`${op.id} ${op.type} ${op.source} ${op.product}`)).map((op)=>ac310RecordRow({title:op.type,subtitle:`${op.id} · ${op.source} · ${op.product}`,badge:op.route==="PHYSICAL_RETURN_BLOCKED"?"Luồng trả hàng":op.statusLabel,tone:op.route==="UNKNOWN"||op.route==="PHYSICAL_RETURN_BLOCKED"?"Warning":"Info",attrs:`data-cr11-operation="${op.id}"`,leading:null})).join("");
  const chips=`<div class="ds24-chip-scroll">${Object.entries(labels).map(([k,l])=>ds24Chip(k,l,cr11Filter===k,"data-cr11-filter")).join("")}</div>`;
  return ac310Return(appShell({title:"Kiểm soát nghiệp vụ kho",body:`${ds24Search(cr11Query,"data-cr11-search","Tìm mã nghiệp vụ hoặc chứng từ")}${chips}${rows?ac310ListSurface(rows):ioEmpty("Không có nghiệp vụ phù hợp","Thử đổi bộ lọc hoặc từ khóa tìm kiếm.")}`,back:false}));
}
function ac310Render049(state){
  if(activeFlowId!=="UIF-11") return ac310Base("SCR-049",state);
  if(!["READY","CORRECTABLE","CANCELABLE","UNKNOWN","BLOCKED_PHYSICAL_HANDOVER","TERMINAL"].includes(state)) return ac310Base("SCR-049",state);
  const op=cr11Current(),routeState=state==="READY"?cr11StateFor(op):state;
  const context=`${ac310RecordRow({title:op.id,subtitle:`${op.type} · ${op.source}`,badge:op.statusLabel,tone:routeState==="UNKNOWN"?"Warning":"Info",status:true,leading:null})}${ac310InfoSurface("Thông tin nghiệp vụ",[["Kho",op.warehouse],["Hàng",op.product],["Số lượng",`${op.qty} ${op.uom}`],["Tác động",op.impact]])}`;
  if(routeState==="UNKNOWN") return ac310Return(appShell({title:"Chi tiết nghiệp vụ kho",body:`${vBanner("warning","Kết quả chưa xác định","Chưa hủy hoặc tạo sửa sai cho tới khi xác lập kết quả của đúng lần xử lý này.")}${context}`,actions:primaryFooter("Xác minh kết quả",'data-cr11-action="handoff-unknown"')}));
  if(routeState==="BLOCKED_PHYSICAL_HANDOVER") return ac310Return(appShell({title:"Chi tiết nghiệp vụ kho",body:`${vBanner("warning","Hàng đã được bàn giao thực tế","Khách trả hàng phải qua nghiệp vụ Hàng khách trả; không xử lý bằng sửa sai.")}${context}`,actions:primaryFooter("Về danh sách",'data-cr11-action="to-list"')}));
  if(routeState==="TERMINAL") return ac310Return(appShell({title:"Chi tiết nghiệp vụ kho",body:`${vBanner("info","Không còn tác động cần sửa","Nghiệp vụ đã dừng trước khi thực thi.")}${context}`,actions:primaryFooter("Về danh sách",'data-cr11-action="to-list"')}));
  if(routeState==="CANCELABLE") return ac310Return(appShell({title:"Chi tiết nghiệp vụ kho",body:`${context}<p class="ac310-note">Nghiệp vụ chưa thực thi nên có thể hủy mà không tạo biến động tồn kho.</p>`,actions:primaryFooter("Hủy yêu cầu",'data-cr11-action="open-cancel"',false,"danger")}));
  return ac310Return(appShell({title:"Chi tiết nghiệp vụ kho",body:`${context}${ac310AuditSurface("Dấu vết",[ac310AuditItem("Create","Nghiệp vụ gốc đã hoàn tất","01/09/2026 · Chưa có sửa sai trước đó")])}`,actions:primaryFooter("Sửa sai",'data-cr11-action="open-correction"')}));
}
function ac310Render052(state){
  if(activeFlowId!=="UIF-11") return ac310Base("SCR-052",state);
  if(["DEPENDENCY_BLOCKED","PERIOD_POLICY_VIOLATION","PERMISSION_DENIED"].includes(state)) return ac310Base("SCR-052",state);
  const op=cr11Current(); const cancelMode=state==="CANCEL_UNEXECUTED"||op.route==="CANCEL";
  if(cancelMode){
    const body=`${state==="VALIDATION_ERROR"&&!cr11CancelReason.trim()?vBanner("error","Cần nhập lý do hủy","Lý do được lưu trong lịch sử kiểm soát."):""}${vBanner("info","Hủy trước khi thực thi","Tồn kho và giá trị không thay đổi.")}${ac310InfoSurface("Yêu cầu",[["Nghiệp vụ",op.id,true],["Loại",op.type],["Chứng từ nguồn",op.source]])}${ac310Textarea("Lý do hủy",cr11CancelReason,'data-cr11-cancel-reason')}`;
    return ac310Return(appShell({title:"Hủy yêu cầu kho",body,actions:primaryFooter("Hủy yêu cầu",'data-cr11-action="confirm-cancel"',!cr11CancelReason.trim(),"danger")}));
  }
  const choices=[ac310RadioChoice({value:"DELTA",label:"Sửa phần sai",detail:"Điều chỉnh riêng phần sai và giữ nguyên phần đúng.",checked:cr11Strategy==="DELTA",attrs:'name="cr11-strategy" data-cr11-strategy'}),ac310RadioChoice({value:"FULL",label:"Hoàn nguyên và ghi lại đúng",detail:"Dùng khi toàn bộ nghiệp vụ phải được xác lập lại.",checked:cr11Strategy==="FULL",attrs:'name="cr11-strategy" data-cr11-strategy'})];
  const body=`${vBanner("info","Nghiệp vụ gốc luôn được giữ nguyên","Hệ thống tạo bản ghi sửa sai có liên kết; không xóa lịch sử đã hoàn tất.")}${ac310InfoSurface("Nghiệp vụ gốc",[["Mã",op.id,true],["Đã ghi nhận",`${op.qty} ${op.uom}`],["Kỳ gốc","Đã khóa"]])}${ac310RadioSurface("Cách sửa",choices)}`;
  return ac310Return(appShell({title:"Chọn cách sửa",body,actions:primaryFooter("Tiếp tục",'data-cr11-action="edit-correction"')}));
}
function ac310Render050(state){
  if(activeFlowId!=="UIF-11") return ac310Base("SCR-050",state);
  if(["PERMISSION_DENIED","SOURCE_VERSION_STALE","CONFLICT"].includes(state)) return ac310Base("SCR-050",state);
  const op=cr11Current(),delta=Number(cr11CorrectQty)-Number(op.qty);
  const body=`${state==="VALIDATION_ERROR"?vBanner("error","Kiểm tra nội dung sửa sai","Số đúng phải lớn hơn hoặc bằng 0 và cần có lý do."):""}${ac310InfoSurface("Trước khi sửa",[["Nghiệp vụ gốc",op.id,true],["Số đã ghi nhận",`${op.qty} ${op.uom}`],["Cách sửa",cr11Strategy==="DELTA"?"Sửa phần sai":"Hoàn nguyên và ghi lại đúng"]])}<div class="ac310-form-stack">${ac310Field("Số đúng",cr11CorrectQty,'data-cr11-correct-qty min="0" inputmode="decimal"','',"number")}${ac310Textarea("Lý do sửa sai",cr11CorrectionReason,'data-cr11-correction-reason')}</div>${ac310KeyValueSurface("Hệ thống tự tính",[["Điều chỉnh",`${delta>0?"+":""}${delta} ${op.uom}`,true]])}`;
  return ac310Return(appShell({title:"Nội dung sửa sai",body,actions:primaryFooter("Gửi phê duyệt",'data-cr11-action="submit-correction"',Number(cr11CorrectQty)<0||!cr11CorrectionReason.trim())}));
}
function ac310Render051(state){
  if(activeFlowId!=="UIF-11") return ac310Base("SCR-051",state);
  if(!["READY","VALIDATION_ERROR"].includes(state)) return ac310Base("SCR-051",state);
  const op=cr11Operations[1],delta=Number(cr11CorrectQty)-Number(op.qty);
  const sheet=cr11ApprovalRejectOpen?`<div class="sheet-backdrop"><section class="bottom-sheet ac310-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true"><div class="sheet-handle"></div><div class="sheet-title"><h3>Từ chối sửa sai</h3></div><div class="sheet-content">${state==="VALIDATION_ERROR"&&!cr11ApprovalRejectReason.trim()?vBanner("error","Cần nhập lý do từ chối","Lý do được lưu cùng quyết định."):""}${ac310Textarea("Lý do từ chối",cr11ApprovalRejectReason,'data-cr11-approval-reason')}<div class="sheet-actions"><button class="button button--secondary" type="button" data-cr11-action="reject-close">Đóng</button><button class="button button--danger" type="button" data-cr11-action="reject-confirm" ${cr11ApprovalRejectReason.trim()?"":"disabled"}>Từ chối</button></div></div></section></div>`:"";
  const body=`${vBanner("info","Công việc phê duyệt độc lập","Quyết định chỉ duyệt phương án; hệ thống tự ghi nhận sửa sai sau khi kiểm tra lại điều kiện.")}${ac310InfoSurface("Yêu cầu sửa sai",[["Nghiệp vụ gốc",op.id,true],["Người lập","Nguyễn An"],["Lý do",cr11CorrectionReason]])}${ac310KeyValueSurface("Trước và sau",[["Trước",`${op.qty} ${op.uom}`],["Sau",`${cr11CorrectQty} ${op.uom}`],["Điều chỉnh",`${delta>0?"+":""}${delta} ${op.uom}`,true]])}${sheet}`;
  return ac310Return(appShell({title:"Duyệt sửa sai",body,actions:ac310ApprovalFooter('data-cr11-action="reject-open"','data-cr11-action="approve"'),back:false}));
}

/* ------------------------------ BJ12 ----------------------------------- */
function ac310Cf12Review(){
  return ac310InfoSurface("Số dư đầu kỳ",[["Kho","Kho trung tâm"],["Ngày chốt",cfDateVN(cf12Cutoff),true],["Dòng dữ liệu",cfNumber(cf12Summary.rows)],["Sản phẩm",cfNumber(cf12Summary.products)],["Tổng số lượng",cfNumber(cf12Summary.parsedQty)],["Tổng giá trị",cfMoney(cf12Summary.parsedValue),true]]);
}
function ac310Render066(state){
  if(activeFlowId!=="UIF-12") return ac310Base("SCR-066",state);
  if(!["READY","PENDING_APPROVAL","REJECTED","ACTIVE_RECONCILED"].includes(state)) return ac310Base("SCR-066",state);
  if(state==="ACTIVE_RECONCILED") return ac310Return(appShell({title:"Khởi tạo tồn kho",body:ac310Result("Tồn kho đầu kỳ đã sẵn sàng","Số dư đầu kỳ đã được ghi nhận và đối chiếu.",[["Ngày chốt",cfDateVN(cf12Cutoff)],["Sản phẩm",`${cfNumber(cf12Summary.products)} sản phẩm`],["Đối soát","Đã khớp"]]),actions:primaryFooter("Xem tồn kho",'data-cf12-action="see-inventory"'),centered:true,back:false}));
  if(state==="PENDING_APPROVAL") return ac310Return(appShell({title:"Khởi tạo tồn kho",body:`${vBanner("info","Đang chờ duyệt","Bạn đã hoàn tất phần chuẩn bị. Tồn kho chưa thay đổi.")}${ac310InfoSurface("Yêu cầu",[["Kho","Kho trung tâm"],["Ngày chốt",cfDateVN(cf12Cutoff)],["Trạng thái","Chờ duyệt"]])}`,back:false}));
  if(state==="REJECTED") return ac310Return(appShell({title:"Khởi tạo tồn kho",body:`${vBanner("warning","Yêu cầu cần chỉnh sửa","Người duyệt đã trả lại dữ liệu. Tồn kho chưa thay đổi.")}${ac310InfoSurface("Yêu cầu",[["Kho","Kho trung tâm"],["Ngày chốt",cfDateVN(cf12Cutoff)],["Trạng thái","Cần chỉnh sửa"]])}`,actions:primaryFooter("Chỉnh dữ liệu",'data-cf12-action="fix-rejected"'),back:false}));
  return ac310Return(appShell({title:"Khởi tạo tồn kho",body:`${ac310InfoSurface("Khởi tạo lần đầu",[["Kho","Kho trung tâm",true],["Trạng thái","Chưa thiết lập"],["Nguyên tắc","Chỉ có một số dư đầu kỳ chính thức"]])}<p class="ac310-note">Sau khi hoàn tất, mọi sửa sai được thực hiện bằng nghiệp vụ điều chỉnh có kiểm soát.</p>`,actions:primaryFooter("Bắt đầu",'data-cf12-action="start"'),back:false}));
}
function ac310Render067(state){
  if(activeFlowId!=="UIF-12") return ac310Base("SCR-067",state);
  if(!["READY","VALIDATION_ERROR"].includes(state)) return ac310Base("SCR-067",state);
  const invalid=state==="VALIDATION_ERROR";
  const body=`${invalid?vBanner("error","Chưa đủ dữ liệu kiểm soát","Chọn tệp, ngày chốt và nhập đủ hai số kiểm soát trước khi kiểm tra."):""}${ac310FileDrop("Tệp số dư đầu kỳ",cf12FileName,'data-cf12-action="choose-file"')}<div class="ac310-form-stack">${ac310Field("Ngày chốt số dư",cf12Cutoff,'data-cf12-cutoff','Ngày nghiệp vụ mà số dư đầu kỳ có hiệu lực.',"date")}${ac310Field("Tổng số lượng kiểm soát",cf12ControlQty,'data-cf12-control-qty','Nhập từ nguồn kiểm soát độc lập.',"number")}${ac310Field("Tổng giá trị kiểm soát",cf12ControlValue,'data-cf12-control-value','Giá trị tồn kho đầu kỳ theo nguồn kiểm soát.',"text")}</div>`;
  const disabled=!cf12FileName||!cf12Cutoff||!(Number(cf12ControlQty)>=0)||!(Number(cf12ControlValue)>=0);
  return ac310Return(appShell({title:"Dữ liệu tồn kho đầu kỳ",body,actions:primaryFooter("Kiểm tra dữ liệu",'data-cf12-action="check"',disabled)}));
}
function ac310IssueRow(title,detail){return ac310RecordRow({title,subtitle:detail,badge:"Cần sửa",tone:"Warning",status:true,leading:null});}
function ac310Render068(state){
  if(activeFlowId!=="UIF-12") return ac310Base("SCR-068",state);
  if(!["READY","VALIDATION_FAILED","CONTROL_TOTAL_MISMATCH"].includes(state)) return ac310Base("SCR-068",state);
  if(state==="VALIDATION_FAILED"){
    const issues=ac310ListSurface(`${ac310IssueRow("Dòng 18 · Vaccine Newcastle","Chưa xác định sản phẩm")}${ac310IssueRow("Dòng 44 · Amox 500","Trùng cùng sản phẩm + kho + tình trạng + lô")}${ac310IssueRow("Dòng 61 · Nobivac DHPPi","Thiếu hạn dùng bắt buộc")}`,"ac310-validation-list");
    return ac310Return(appShell({title:"Kết quả kiểm tra dữ liệu",body:`${vBanner("error","Còn dòng chưa hợp lệ","Không có dữ liệu nào được ghi nhận. Sửa dữ liệu nguồn rồi kiểm tra lại.")}${ac310SummaryMetrics([["Dòng đọc được",cfNumber(cf12Summary.rows)],["Sản phẩm",cfNumber(cf12Summary.products)],["Lỗi cần sửa","3"]])}${ac310SectionTitle("Dòng cần sửa")}${issues}`,actions:primaryFooter("Chọn lại tệp",'data-cf12-action="back-file"')}));
  }
  if(state==="CONTROL_TOTAL_MISMATCH") return ac310Return(appShell({title:"Kết quả kiểm tra dữ liệu",body:`${vBanner("warning","Số kiểm soát không khớp","Chưa thể gửi phê duyệt.")}${ac310KeyValueSurface("Đối chiếu",[["Theo tệp",cfNumber(cf12Summary.parsedQty)],["Số kiểm soát",cfNumber(Number(cf12ControlQty)+12)],["Chênh lệch","−12",true],["Giá trị theo tệp",cfMoney(cf12Summary.parsedValue)],["Giá trị kiểm soát",cfMoney(cf12ControlValue)]])}`,actions:primaryFooter("Quay lại dữ liệu",'data-cf12-action="back-file"')}));
  return ac310Return(appShell({title:"Kết quả kiểm tra dữ liệu",body:`${vBanner("success","Dữ liệu đã qua kiểm tra","Tệp chi tiết khớp số kiểm soát và không còn lỗi bắt buộc.")}${ac310SummaryMetrics([["Dòng dữ liệu",cfNumber(cf12Summary.rows)],["Sản phẩm",cfNumber(cf12Summary.products)],["Tổng số lượng",cfNumber(cf12Summary.parsedQty)]])}${ac310InfoSurface("Kiểm tra chính",[["Số âm","Không có"],["Dòng trùng","Không có"],["Lô / hạn dùng","Hợp lệ"],["Số kiểm soát","Đã khớp",true]])}`,actions:primaryFooter("Rà soát số dư",'data-cf12-action="review"')}));
}
function ac310Render069(state){
  if(activeFlowId!=="UIF-12") return ac310Base("SCR-069",state);
  if(!["READY","PENDING_APPROVAL"].includes(state)) return ac310Base("SCR-069",state);
  const pending=state==="PENDING_APPROVAL"?vBanner("info","Đã gửi chờ duyệt","Bạn đã hoàn tất phần chuẩn bị. Tồn kho chưa thay đổi."):"";
  const body=`${pending}${ac310Cf12Review()}${ac310InfoSurface("Phân bố dữ liệu",[["Bán được",`${cfNumber(cf12Summary.sellableRows)} dòng`,true],["Không bán được",`${cfNumber(cf12Summary.nonSellableRows)} dòng`],["Lô / hạn dùng","Giữ theo cấu hình sản phẩm"]])}`;
  return ac310Return(appShell({title:"Rà soát số dư đầu kỳ",body,actions:state==="READY"?primaryFooter("Gửi phê duyệt",'data-cf12-action="send-approval"'):""}));
}
function ac310Render070(state){
  if(activeFlowId!=="UIF-12") return ac310Base("SCR-070",state);
  if(state!=="READY") return ac310Base("SCR-070",state);
  const reject=cf12RejectSheet();
  const body=`${vBanner("info","Kiểm tra trước khi duyệt","Đối chiếu ngày chốt, số kiểm soát và phạm vi trước khi quyết định.")}${ac310InfoSurface("Người chuẩn bị",[["Người lập","Nguyễn An",true],["Ngày gửi","07/09/2026 · 10:32"]])}${ac310Cf12Review()}${reject}`;
  return ac310Return(appShell({title:"Duyệt số dư đầu kỳ",body,actions:ac310ApprovalFooter('data-cf12-action="open-reject"','data-cf12-action="approve"'),back:false}));
}

/* ------------------------------ BJ15 ----------------------------------- */
function ac310ModeChoice(value,label,detail,current,attr){
  return `<button type="button" class="ac310-mode-row${current===value?' is-selected':''}" ${attr}="${value}" data-ds-component="VRadio" data-figma-node="522:7410"><span class="ac310-radio-control"></span><span class="ac310-radio-copy"><strong>${esc(label)}</strong><small>${esc(detail)}</small></span></button>`;
}
function ac310Render054(state){
  if(activeFlowId!=="UIF-15") return ac310Base("SCR-054",state);
  if(!["READY","VALIDATION_ERROR"].includes(state)) return ac310Base("SCR-054",state);
  const invalid=state==="VALIDATION_ERROR";
  const productOptions=[["ALL","Tất cả sản phẩm"],...cf15Products.map((x)=>[x.id,`${x.name} · ${x.code}`])];
  const modes=`${ac310ModeChoice("INVENTORY","Tồn kho","Xem số lượng và giá trị theo phạm vi",cf15ReportType,"data-cf15-report-type")}${ac310ModeChoice("STOCK_CARD","Thẻ kho","Xem biến động của một sản phẩm",cf15ReportType,"data-cf15-report-type")}`;
  const dates=`${ac310ModeChoice("BUSINESS","Ngày nghiệp vụ","Theo ngày nghiệp vụ phát sinh",cf15DateMode,"data-cf15-date-mode")}${ac310ModeChoice("RECORDED","Ngày ghi nhận","Theo thời điểm hệ thống ghi nhận",cf15DateMode,"data-cf15-date-mode")}`;
  const body=`${invalid?vBanner("error","Chưa đủ điều kiện tra cứu",cf15ReportType==="STOCK_CARD"?"Chọn một sản phẩm cụ thể để xem thẻ kho.":"Kiểm tra lại phạm vi và kỳ báo cáo."):""}${ac310RadioSurface("Loại tra cứu",[modes])}<div class="ac310-form-stack">${cfSelect("Kho",cf15Warehouse,[["MAIN","Kho trung tâm"]],"data-cf15-warehouse","")}${cfSelect("Sản phẩm",cf15Product,productOptions,"data-cf15-product",cf15ReportType==="STOCK_CARD"?"Bắt buộc khi xem thẻ kho.":"")}</div>${ac310RadioSurface("Cách hiểu thời gian",[dates])}<div class="ac310-form-stack ac310-date-grid">${cfField("Từ ngày",cf15From,'data-cf15-from','date')}${cfField("Đến ngày",cf15To,'data-cf15-to','date')}</div>`;
  return ac310Return(appShell({title:"Tra cứu kho",body,actions:primaryFooter("Xem báo cáo",'data-cf15-action="query"'),back:false}));
}
function ac310Cf15ProductSheet(product,financeAllowed){
  if(!cf15ProductSheetOpen||!product) return "";
  const rows=[["Tồn vật lý",`${cfNumber(product.qty)} ${product.uom}`,true],["Khả dụng bán",`${cfNumber(product.available)} ${product.uom}`,true],...(financeAllowed?[["Giá trị tồn",cfMoney(product.value)]]:[])];
  const lots=product.tracking==="LOT"?product.lots.map((l)=>ac310RecordRow({title:`Lô ${l.lot}`,subtitle:`${l.qty} ${product.uom}`,badge:l.state,tone:l.state==="Bán được"?"Success":"Warning",status:true,leading:null})).join(""):"";
  return `<div class="sheet-backdrop" data-cf15-action="close-product-sheet"><section class="bottom-sheet ac310-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true" onclick="event.stopPropagation()"><div class="sheet-handle"></div><div class="sheet-title"><h3>${esc(product.name)}</h3><small>${esc(product.code)}</small></div><div class="sheet-content">${ac310KeyValueSurface("",rows,{extraClass:"ac310-sheet-surface"})}${product.tracking==="LOT"?`${ac310SectionTitle("Theo lô")}${ac310ListSurface(lots,"ac310-sheet-list")}`:`<p class="ac310-note">Sản phẩm không quản lý theo lô.</p>`}<div class="sheet-actions"><button class="button button--secondary" type="button" data-cf15-action="close-product-sheet">Đóng</button><button class="button button--primary" type="button" data-cf15-action="product-stock-card" data-cf15-product-id="${product.id}">Xem thẻ kho</button></div></div></section></div>`;
}
function ac310Render055(state){
  if(activeFlowId!=="UIF-15") return ac310Base("SCR-055",state);
  if(!["READY","RECORDED_DATE_VIEW","BUSINESS_DATE_VIEW","FINANCIAL_RESTRICTED"].includes(state)) return ac310Base("SCR-055",state);
  const mode=state==="RECORDED_DATE_VIEW"?"RECORDED":state==="BUSINESS_DATE_VIEW"?"BUSINESS":cf15DateMode;
  const financeAllowed=state!=="FINANCIAL_RESTRICTED";
  if(cf15ReportType==="INVENTORY"){
    const rows=cf15Products.map((p)=>ac310ProductRow({name:p.name,code:p.code,meta:`${cfNumber(p.qty)} ${p.uom} · Khả dụng ${cfNumber(p.available)} ${p.uom}`,attrs:`data-cf15-product-row="${p.id}"`})).join("");
    const body=`${cf15ContextBanner(state,mode)}${ac310SummaryMetrics([["Sản phẩm",cf15Products.length],["Kho","Kho trung tâm"],...(financeAllowed?[["Tổng giá trị",cfMoney(cf15Products.reduce((a,x)=>a+x.value,0))]]:[])])}${financeAllowed?"":vBanner("info","Giá trị tài chính đã được ẩn","Bạn vẫn có thể xem số lượng trong phạm vi được cấp quyền.")}${ac310SectionTitle("Sản phẩm")}${ac310ListSurface(rows)}<button class="button button--secondary ac310-inline-button" type="button" data-cf15-action="export">Xuất báo cáo</button>${ac310Cf15ProductSheet(cf15ProductById(cf15SelectedProduct),financeAllowed)}`;
    return ac310Return(appShell({title:"Báo cáo tồn kho",subtitle:`Kho trung tâm · ${cf15DateLabel(mode)}`,body}));
  }
  const p=cf15ProductById(cf15Product==="ALL"?cf15SelectedProduct:cf15Product);
  const movements=cf15Movements.map((m)=>ac310RecordRow({title:m.label,subtitle:`${mode==="RECORDED"?m.recorded:m.business} · ${m.source}`,badge:`${m.delta>0?"+":""}${m.delta} ${m.uom}`,tone:"Neutral",attrs:`data-cf15-movement="${m.id}"`,leading:null})).join("");
  const body=`${cf15ContextBanner(state,mode)}${ac310ProductRow({name:p.name,code:p.code,meta:`${cfNumber(p.qty)} ${p.uom}`,badge:`Khả dụng ${cfNumber(p.available)} ${p.uom}`,tone:"Success",status:true})}${financeAllowed?ac310KeyValueSurface("",[["Giá trị tồn",cfMoney(p.value),true]]):vBanner("info","Giá trị tài chính đã được ẩn","Thẻ kho vẫn hiển thị số lượng và nguồn nghiệp vụ.")}${ac310SectionTitle("Biến động")}${ac310ListSurface(movements)}<button class="button button--secondary ac310-inline-button" type="button" data-cf15-action="export">Xuất thẻ kho</button>`;
  return ac310Return(appShell({title:"Thẻ kho",subtitle:`${p.name} · ${cf15DateLabel(mode)}`,body}));
}
function ac310Render056CF15(state){
  if(activeFlowId!=="UIF-15") return ac310Base("SCR-056",state);
  if(!["READY","FINANCIAL_RESTRICTED","LOCKED"].includes(state)) return ac310Base("SCR-056",state);
  const m=cf15Movement(),financeAllowed=state!=="FINANCIAL_RESTRICTED";
  const lockedNotice=state==="LOCKED"?vBanner("info","Dữ liệu đang ở chế độ chỉ đọc","Bạn có thể xem nguồn và truy vết; màn này không thay đổi dữ liệu."):"";
  const body=`${lockedNotice}${ac310RecordRow({title:m.label,subtitle:m.source,badge:`${m.delta>0?"+":""}${m.delta} ${m.uom}`,tone:"Neutral",status:true,leading:null})}${ac310InfoSurface("Thời gian và người thực hiện",[["Ngày nghiệp vụ",m.business],["Ngày ghi nhận",m.recorded],["Người thực hiện",m.actor]])}${ac310KeyValueSurface("Số lượng",[["Trước",`${m.before} ${m.uom}`],["Biến động",`${m.delta>0?"+":""}${m.delta} ${m.uom}`,true],["Sau",`${m.after} ${m.uom}`],["Lô",m.lot],["Tình trạng",m.state]])}${financeAllowed?ac310KeyValueSurface("Giá trị",[["Tác động",cfMoney(m.value),true]]):vBanner("info","Giá trị tài chính đã được ẩn","Bạn vẫn có thể truy vết nguồn và số lượng.")}<button class="button button--secondary ac310-inline-button" type="button" data-cf15-action="source">Xem nguồn</button>`;
  return ac310Return(appShell({title:"Chi tiết biến động",body}));
}
function ac310Render057(state){
  if(activeFlowId!=="UIF-15") return ac310Base("SCR-057",state);
  if(state!=="READY"&&state!=="STALE") return ac310Base("SCR-057",state);
  const m=cf15Movement();
  const items=[ac310AuditItem("Create",m.source,`Nghiệp vụ nguồn hoàn tất · ${m.business}`),ac310AuditItem("System","Đã ghi nhận kho",m.recorded),ac310AuditItem("Update",`${m.delta>=0?"Tồn tăng":"Tồn giảm"} ${Math.abs(m.delta)} ${m.uom}`,`Số dư sau biến động: ${m.after} ${m.uom}`)];
  const body=`${state==="STALE"?vBanner("warning","Dữ liệu nguồn đang cập nhật","Giữ mốc hiển thị hiện tại cho tới khi tải lại dữ liệu."):""}${ac310InfoSurface("Biến động đang xem",[["Nguồn",m.source,true],["Sản phẩm",cf15ProductById(cf15Product==="ALL"?cf15SelectedProduct:cf15Product).name],["Số lượng",`${m.delta>0?"+":""}${m.delta} ${m.uom}`]])}${ac310AuditSurface("Dòng thời gian nghiệp vụ",items)}<button class="button button--secondary ac310-inline-button" type="button" data-cf15-action="export-source">Xuất bằng chứng</button>`;
  return ac310Return(appShell({title:"Nguồn nghiệp vụ",body}));
}
function ac310Render058(state){
  if(activeFlowId!=="UIF-15") return ac310Base("SCR-058",state);
  if(state!=="READY") return ac310Base("SCR-058",state);
  const sourceLabel=cf15ExportFrom==="SOURCE"?"Bằng chứng biến động":cf15ReportType==="STOCK_CARD"?"Thẻ kho":"Báo cáo tồn kho";
  const body=`${ac310InfoSurface("Phạm vi xuất",[["Nội dung",sourceLabel,true],["Kho","Kho trung tâm"],["Kỳ",`${cfDateVN(cf15From)} → ${cfDateVN(cf15To)}`],["Cách hiểu thời gian",cf15DateLabel()],["Dữ liệu đến","07/09/2026 · 11:00"],["Giá trị tài chính",cf15FinanceIncluded?"Có":"Không"]])}${ac310InfoSurface("Định dạng",[["Tệp","CSV",true],["Quyền dữ liệu","Giữ như màn đang xem"]])}`;
  return ac310Return(appShell({title:"Xuất báo cáo",body,actions:primaryFooter("Xuất báo cáo",'data-cf15-action="confirm-export"'),backAction:"cf15-back-export"}));
}

/* --------------------------- BJ16 / BJ17 ------------------------------- */
function ac310CaseRows(is17){
  const cases=is17?cr17Cases:cr16Cases,filter=is17?cr17Filter:cr16Filter;
  const filtered=cases.filter((c)=>{if(filter==="ALL")return true;if(is17)return c.evidence===filter;if(filter==="ACTION")return ["PROJECTION","CORRECTION"].includes(c.route);if(filter==="WAITING")return c.route==="SOURCE";if(filter==="HIGH")return c.route==="LEDGER";return true;}).filter((c)=>ioMatchesSearch(crControlQuery,`${c.id} ${c.title} ${c.scope} ${c.operation||""}`));
  return filtered.map((c)=>ac310RecordRow({title:is17?(c.operation||c.id):c.id,subtitle:`${c.title} · ${c.scope}`,badge:c.severity,tone:c.tone,attrs:`data-cr-case="${c.id}"`,leading:null})).join("");
}
function ac310Render078(state){
  if(!["UIF-16","UIF-17"].includes(activeFlowId)) return ac310Base("SCR-078",state);
  if(state!=="READY") return ac310Base("SCR-078",state);
  const is17=activeFlowId==="UIF-17",filter=is17?cr17Filter:cr16Filter;
  const chipItems=is17?[["ALL","Tất cả"],["COMMITTED","Đã có tác động"],["NO_COMMIT","Chưa có tác động"],["INSUFFICIENT","Cần chuyên sâu"]]:[["ALL","Tất cả"],["ACTION","Cần xử lý"],["WAITING","Đang chờ"],["HIGH","Ưu tiên cao"]];
  const rows=ac310CaseRows(is17);
  const body=`${ds24Search(crControlQuery,"data-cr-control-search",is17?"Tìm mã nghiệp vụ hoặc hàng":"Tìm hồ sơ, sản phẩm hoặc chứng từ")}<div class="ds24-chip-scroll">${chipItems.map(([k,l])=>ds24Chip(k,l,filter===k,is17?"data-cr17-filter":"data-cr16-filter")).join("")}</div>${rows?ac310ListSurface(rows):ioEmpty("Không có hồ sơ phù hợp","Thử đổi bộ lọc hoặc từ khóa tìm kiếm.")}`;
  return ac310Return(appShell({title:is17?"Nghiệp vụ cần xác minh":"Đối soát sai lệch",body,back:false}));
}
function ac310EvidenceRows(rows){return ac310InfoSurface("Bằng chứng",rows.map((r)=>[r[0],r[1],String(r[1]).includes("lệch")||String(r[1]).includes("không nhất quán")]));}
function ac310Render079(state){
  if(!["UIF-16","UIF-17"].includes(activeFlowId)) return ac310Base("SCR-079",state);
  if(["PERMISSION_DENIED","LOADING"].includes(state)) return ac310Base("SCR-079",state);
  if(activeFlowId==="UIF-17"){
    const c=cr17Current(),actual=state==="READY"?cr079StateFor17(c):state;
    if(actual==="INSUFFICIENT_EVIDENCE") return ac310Return(appShell({title:"Bằng chứng kết quả",body:`${vBanner("warning","Chưa đủ bằng chứng để kết luận","Nghiệp vụ vẫn chưa xác định và phạm vi tiếp tục được bảo vệ.")}${ac310RecordRow({title:c.operation,subtitle:c.scope,badge:c.severity,tone:c.tone,status:true,leading:null})}${ac310InfoSurface("Hồ sơ",[["Người xử lý",c.owner],["Định danh nghiệp vụ","Giữ nguyên"]])}${ac310EvidenceRows(cr17EvidenceRows(c))}`,actions:primaryFooter("Xem trạng thái xử lý",'data-cr17-action="show-escalated"')}));
    const committed=c.evidence==="COMMITTED";
    const banner=committed?vBanner("info","Đã tìm thấy tác động của nghiệp vụ","Bước tiếp theo chỉ xác lập kết quả; không ghi lại tác động lần hai."):vBanner("info","Chưa phát hiện tác động tồn kho","Có thể tiếp tục đúng lần xử lý này, giữ nguyên định danh và nội dung đã xác nhận.");
    return ac310Return(appShell({title:"Bằng chứng kết quả",body:`${banner}${ac310RecordRow({title:c.operation,subtitle:c.scope,badge:c.severity,tone:c.tone,status:true,leading:null})}${ac310InfoSurface("Hồ sơ",[["Người xử lý",c.owner],["Định danh nghiệp vụ","Giữ nguyên"]])}${ac310EvidenceRows(cr17EvidenceRows(c))}`,actions:primaryFooter(committed?"Xem phương án xác lập":"Xem phương án tiếp tục",'data-cr17-action="open-plan"')}));
  }
  const c=cr16Current(),actual=state==="READY"?cr079StateFor16(c):state; let banner="",actions="";
  if(actual==="PROJECTION_MISMATCH"){banner=vBanner("info","Sổ kho đúng, số liệu hiển thị sai","Chỉ số liệu hiển thị cần được khôi phục.");actions=primaryFooter("Khôi phục số liệu hiển thị",'data-cr16-action="open-plan"');}
  else if(actual==="CORRECTION_REQUIRED"){banner=vBanner("warning","Cần sửa nghiệp vụ đã hoàn tất","Sai lệch nằm ở nghiệp vụ nguồn; không chỉnh số dư trực tiếp để làm khớp.");actions=primaryFooter("Mở yêu cầu sửa sai",'data-cr16-action="handoff-correction"');}
  else if(actual==="NO_REAL_DIFFERENCE"){banner=vBanner("info","Không có sai lệch tồn kho thực","Khác biệt đến từ thời điểm lấy số liệu.");actions=primaryFooter("Rà soát đóng hồ sơ",'data-cr16-action="review-close"');}
  else if(actual==="LEDGER_INTEGRITY_RISK"){banner=vBanner("warning","Cần kiểm tra toàn vẹn sổ kho","Tạm dừng khôi phục tự động và sửa sai.");actions=primaryFooter("Xem trạng thái chuyển xử lý",'data-cr16-action="show-escalated"');}
  else if(actual==="SOURCE_MISMATCH") banner=vBanner("info","Đang chờ nghiệp vụ nguồn xác minh","Hồ sơ được giữ mở; kho không tự sửa dữ liệu nguồn hoặc sổ kho.");
  else banner=vBanner("warning","Chưa đủ bằng chứng kết luận","Giữ hồ sơ mở cho tới khi xác định được nguyên nhân.");
  return ac310Return(appShell({title:"Bằng chứng & kết luận",body:`${banner}${ac310RecordRow({title:c.id,subtitle:c.scope,badge:c.severity,tone:c.tone,status:true,leading:null})}${ac310InfoSurface("Hồ sơ",[["Người xử lý",c.owner],["Bảo vệ phạm vi",c.route==="NO_REAL"?"Không cần":"Đang áp dụng"]])}${ac310EvidenceRows(cr16EvidenceRows(c))}`,actions}));
}
function ac310Render080(state){
  if(!["UIF-16","UIF-17"].includes(activeFlowId)) return ac310Base("SCR-080",state);
  if(["PERMISSION_DENIED","LOCKED","CONFLICT"].includes(state)) return ac310Base("SCR-080",state);
  if(activeFlowId==="UIF-17"){
    const c=cr17Current();
    if(c.evidence==="INSUFFICIENT"||state==="INSUFFICIENT_EVIDENCE") return ac310Return(appShell({title:"Phương án xử lý",body:`${vBanner("warning","Chưa có phương án xử lý an toàn","Giữ trạng thái chưa xác định và bảo vệ phạm vi cho tới khi có thêm bằng chứng.")}${ac310InfoSurface("Phạm vi xử lý",[["Nghiệp vụ",c.operation,true],["Người xử lý",c.owner],["Định danh","Giữ nguyên"]])}`,actions:primaryFooter("Xem trạng thái xử lý",'data-cr17-action="show-escalated"')}));
    const committed=c.evidence==="COMMITTED",title=committed?"Xác lập đã hoàn tất":"Tiếp tục lần xử lý này";
    return ac310Return(appShell({title:"Phương án xử lý",body:`${vBanner("info",title,committed?"Dùng tác động đã tồn tại để xác lập kết quả; không ghi lại biến động lần hai.":"Tiếp tục cùng định danh sau khi đã xác nhận chưa có tác động bán phần.")}${ac310InfoSurface("Phạm vi",[["Nghiệp vụ",c.operation,true],["Phạm vi",c.scope],["Định danh","Giữ nguyên"]])}${ac310InfoSurface("Không thực hiện",[["Tạo nghiệp vụ mới","Không"],["Tự hoàn nguyên","Không"],["Đổi nội dung đã xác nhận","Không"]])}`,actions:primaryFooter(title,'data-cr17-action="execute-plan"')}));
  }
  const c=cr16Current();
  return ac310Return(appShell({title:"Phương án xử lý",body:`${vBanner("info","Khôi phục số liệu hiển thị","Sổ kho đã đúng; chỉ khôi phục dữ liệu hiển thị trong phạm vi này.")}${ac310InfoSurface("Phạm vi",[["Hồ sơ",c.id,true],["Hàng",c.scope],["Bảo vệ phạm vi","Đang áp dụng"]])}${ac310InfoSurface("Tác động",[["Sổ kho","Không thay đổi"],["Nghiệp vụ nguồn","Không thay đổi"],["Số liệu hiển thị","Khôi phục theo sổ kho"]])}`,actions:primaryFooter("Bắt đầu khôi phục",'data-cr16-action="start-recovery"')}));
}
function ac310Render081(state){
  if(activeFlowId!=="UIF-16") return ac310Base("SCR-081",state);
  if(!["REBUILDING","READY"].includes(state)) return ac310Base("SCR-081",state);
  const c=cr16Current();
  if(state==="READY") return ac310Return(appShell({title:"Khôi phục số liệu",body:`${vBanner("success","Đã khôi phục số liệu hiển thị","Kết quả sẵn sàng để rà soát trước khi đóng hồ sơ.")}${ac310InfoSurface("Hồ sơ",[["Mã",c.id,true],["Phạm vi",c.scope],["Sổ kho","Không thay đổi"],["Số liệu hiển thị","Đã cập nhật"]])}`,actions:primaryFooter("Rà soát kết quả",'data-cr16-action="review-result"')}));
  const progress=`<section class="ac310-progress-block"><div class="ac310-progress" data-ds-component="VProgress"><div class="ac310-progress__bar"><span style="width:68%"></span></div></div><strong>Đang khôi phục số liệu hiển thị</strong><small>Bạn có thể rời màn hình; hồ sơ tự cập nhật khi hoàn tất.</small></section>`;
  return ac310Return(appShell({title:"Đang khôi phục số liệu",body:`${progress}${ac310InfoSurface("Hồ sơ",[["Mã",c.id,true],["Phạm vi",c.scope],["Sổ kho","Không thay đổi"]])}`}));
}
function ac310Render082(state){
  if(!["UIF-16","UIF-17"].includes(activeFlowId)) return ac310Base("SCR-082",state);
  if(state==="PERMISSION_DENIED") return ac310Base("SCR-082",state);
  if(activeFlowId==="UIF-17"){
    const c=cr17Current(),committed=(cr17ResolutionMode||c.evidence)==="COMMITTED",continued=(cr17ResolutionMode||"")==="CONTINUED";
    const rows=committed?[["Nghiệp vụ",c.operation,true],["Kết quả","Đã hoàn tất"],["Tác động tồn kho","Giữ tác động đã có"],["Định danh","Không thay đổi"]]:[["Nghiệp vụ",c.operation,true],["Kết quả",continued?"Đã hoàn tất":"Đã có kết quả mới"],["Định danh","Không thay đổi"],["Nghiệp vụ mới","Không tạo"]];
    return ac310Return(appShell({title:"Rà soát kết quả",body:`${vBanner("info","Kết quả đã được xác lập","Hệ thống giữ đúng nghiệp vụ ban đầu và không tạo tác động trùng.")}${ac310InfoSurface("Kết quả cuối",rows)}`,actions:primaryFooter("Hoàn tất xác minh",'data-cr17-action="finish-review"')}));
  }
  const c=cr16Current();
  if(state==="MISMATCH_REMAINS") return ac310Return(appShell({title:"Rà soát kết quả",body:`${vBanner("warning","Sai lệch vẫn còn","Giữ hồ sơ mở và phạm vi được bảo vệ.")}${ac310KeyValueSurface(c.id,[["Sổ kho","118 hộp"],["Số liệu hiển thị","117 hộp"],["Chênh lệch","−1 hộp",true]])}`}));
  const noReal=c.route==="NO_REAL";
  return ac310Return(appShell({title:"Rà soát kết quả",body:`${vBanner("info",noReal?"Không có sai lệch thực":"Số liệu đã khớp",noReal?"Khác biệt trước đó được giải thích bằng mốc thời gian.":"Số liệu hiển thị hiện khớp với sổ kho.")}${ac310KeyValueSurface(c.id,[["Sổ kho","118 hộp"],["Số liệu hiển thị","118 hộp"],["Chênh lệch","0 hộp",true],["Phạm vi",noReal?"Không khóa":"Sẵn sàng mở khóa"]])}`,actions:primaryFooter("Đóng hồ sơ & mở khóa",'data-cr16-action="close-case"')}));
}

/* Bind v3.1.0 renderers. Shared screen IDs preserve non Audit & Control flows. */
renderers["SCR-042"]=ac310Render042;
renderers["SCR-043"]=ac310Render043;
renderers["SCR-044"]=ac310Render044;
renderers["SCR-045"]=ac310Render045;
renderers["SCR-046"]=ac310Render046;
renderers["SCR-047"]=(state)=>activeFlowId==="UIF-08"?ac310Base("SCR-047",state):ac310Base("SCR-047",state);
renderers["SCR-036"]=ac310Render036;
renderers["SCR-037"]=ac310Render037;
renderers["SCR-038"]=ac310Render038;
renderers["SCR-040"]=ac310Render040;
renderers["SCR-041"]=ac310Render041;
renderers["SCR-048"]=ac310Render048;
renderers["SCR-049"]=ac310Render049;
renderers["SCR-052"]=ac310Render052;
renderers["SCR-050"]=ac310Render050;
renderers["SCR-051"]=ac310Render051;
renderers["SCR-053"]=(state)=>activeFlowId==="UIF-11"?ac310Base("SCR-053",state):ac310Base("SCR-053",state);
renderers["SCR-066"]=ac310Render066;
renderers["SCR-067"]=ac310Render067;
renderers["SCR-068"]=ac310Render068;
renderers["SCR-069"]=ac310Render069;
renderers["SCR-070"]=ac310Render070;
renderers["SCR-071"]=(state)=>activeFlowId==="UIF-12"?ac310Base("SCR-071",state):ac310Base("SCR-071",state);
renderers["SCR-054"]=ac310Render054;
renderers["SCR-055"]=ac310Render055;
renderers["SCR-056"]=ac310Render056;
renderers["SCR-057"]=ac310Render057;
renderers["SCR-058"]=ac310Render058;
renderers["SCR-059"]=(state)=>activeFlowId==="UIF-15"?ac310Base("SCR-059",state):ac310Base("SCR-059",state);
renderers["SCR-078"]=ac310Render078;
renderers["SCR-079"]=ac310Render079;
renderers["SCR-080"]=ac310Render080;
renderers["SCR-081"]=ac310Render081;
renderers["SCR-082"]=ac310Render082;
renderers["SCR-083"]=(state)=>["UIF-16","UIF-17"].includes(activeFlowId)?ac310Base("SCR-083",state):ac310Base("SCR-083",state);

// Re-render once so a deep-linked Audit & Control screen immediately uses v3.1.0.
if (["UIF-08","UIF-09","UIF-10","UIF-11","UIF-12","UIF-15","UIF-16","UIF-17"].includes(activeFlowId)) render();
