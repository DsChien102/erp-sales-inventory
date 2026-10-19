/* BJ-08 — Kiểm kê và điều chỉnh chênh lệch (UIF-08). Màn: SCR-042…047.
 *
 * Đã viết lại sạch (T7-P gói A7, 2026-10-17). Màn đăng ký qua flowRenderers / renderers.
 * Helper chung ac310SanitizeMarkup / ac310Return / ac310InfoSurface / ac310RecordRow → app/shared-control.js.
 * Khôi phục listener keypad/scope (bị mất từ A5 khi tách listener Audit).
 */

{ const sc = screens.find((x) => x.id === "SCR-046"); if (sc) sc.states = [...new Set([...(sc.states || []), "APPROVAL_REVIEW"])]; }

let ic08ConfirmKind=null;
let ic08Scope="ALL";
let ic08ScopeTarget="";
let ic08ScopeSheetOpen=false;
let ic08ProductSheetOpen=false;
let ic08CutoffDate="2026-09-09";
let ic08CutoffTime="08:00";
let ic08Reason="Kiểm kê định kỳ";
let ic08AssignedCounter="Nguyễn An";
let ic08CancelReason="";
let ic08ReviewReason="";
let ic08KeypadTarget=null;
let ic08KeypadDraft="";
let ic08Counts={amox:"18",glove:"7"};
let ic08Recounts={amox:"18",glove:"7"};
let ic08Evidence={amox:"Kiểm lại kệ, thiếu 2 hộp",glove:"Phát hiện 1 hộp chưa ghi nhận"};
let ic08UnexpectedLine=null;
/* v350 seed: đếm bắt đầu trống */
ic08Counts={amox:"",glove:""};
ic08Recounts={amox:"",glove:""};
let bj08ListQuery="", bj08ListFilter="ALL";

const bj08NonBlank = (v) => String(v ?? "").trim().length > 0;
function ic08Section(title,body,extra="") { return `<section class="ds24-section ${extra}" data-theme-component="Theme7StockCountSection">${ds24SectionTitle(title)}${body}</section>`; }
function ic08QuantityTrigger(label,value,target,unit,disabled=false) {
  const display=bj08NonBlank(value)?String(value):"—";
  return `<div class="ds24-field" data-theme-component="Theme7QuantityEntry" data-composed-from="VText,VNumericKeypadSheet"><span class="vet45-text-style-8">${esc(label)}</span><button type="button" class="ds24-field__control ds24-quantity-trigger" data-ic08-keypad-open="${target}" data-unit="${escapeAttribute(unit)}" ${disabled?'disabled':''}><span class="vet45-text-style-6">${esc(display)}</span><small class="vet45-text-style-11">${esc(unit)}</small></button></div>`;
}
function ic08ContextRows(rows) { return ds24InfoGroup('',rows.map(([k,v])=>ds24InfoRow(k,v)).join(''),'ds24-info-group--untitled ic08-info-group'); }
function ic08NumericSheet() {
  if(!ic08KeypadTarget)return ""; const [mode,id]=ic08KeypadTarget.split(':'); const unit=id==='unexpected'?(ic08UnexpectedLine?.uom||'hộp'):'hộp'; const title=mode==='recount'?'Nhập số lượng đếm lại':'Nhập số lượng'; const keys=['1','2','3','4','5','6','7','8','9','.','0','⌫'];
  return `<div class="sheet-backdrop ds24-overlay" data-ic08-action="keypad-cancel"><section class="ds24-keypad" data-ds-component="VNumericKeypadSheet" data-figma-node="1829:6657" data-ds-prop-mode="Quantity" role="dialog" aria-modal="true" onclick="event.stopPropagation()"><div class="ds24-keypad__handle"></div><header><h3 class="vet45-text-style-4">${title}</h3><p class="vet45-text-style-7">Đơn vị: ${esc(unit)}</p></header><div class="ds24-keypad__value vet45-text-style-2">${esc(ic08KeypadDraft||'0')}</div><div class="ds24-keypad__grid">${keys.map(k=>`<button type="button" data-ic08-key="${escapeAttribute(k)}" aria-label="${k==='⌫'?'Xóa một số':k}" class="vet45-text-style-3">${k}</button>`).join('')}</div><div class="ds24-keypad__actions"><button class="ds24-button ds24-button--secondary" type="button" data-ic08-action="keypad-cancel" data-ds-component="VButton" data-figma-node="521:529">Hủy</button><button class="ds24-button ds24-button--primary" type="button" data-ic08-action="keypad-save" data-ds-component="VButton" data-figma-node="521:529">Lưu</button></div></section></div>`;
}
function ic08SelectSheet() {
  if(!ic08ScopeSheetOpen&&!ic08ProductSheetOpen)return ""; const productMode=ic08ProductSheetOpen;
  const rows=productMode?[["vitc","Vitamin C","SP-00231 · Lô L2501-C · hộp"],["amox-new","Amox 500","SP-00128 · Lô L2501-A · hộp"]]:ic08Scope==='PRODUCT'?[["amox","Amox 500","SP-00128"],["glove","Găng tay M","SP-00410"]]:ic08Scope==='GROUP'?[["group-vaccine","Nhóm vaccine","Nhóm sản phẩm"],["group-medicine","Nhóm thuốc","Nhóm sản phẩm"]]:[["lot-l2407","Lô L2407-A","Amox 500"],["lot-l2405","Lô L2405-M","Găng tay M"]];
  return `<div class="sheet-backdrop ds24-overlay" data-ic08-action="select-close"><section class="ds24-select-sheet" data-ds-pattern="Select Sheet" data-theme-component="Theme7SearchSelectSheet" role="dialog" aria-modal="true" onclick="event.stopPropagation()"><div class="ds24-sheet__handle"></div><h3 class="vet45-text-style-4">${productMode?'Thêm hàng thực tế':'Chọn phạm vi'}</h3>${ds24Search('','','Tìm kiếm')}<div class="ds24-list-stack">${rows.map(([id,name,meta])=>ds24ListRow({title:name,subtitle:meta,attrs:`data-ic08-${productMode?'product':'scope-target'}="${id}" data-name="${escapeAttribute(name)}" data-meta="${escapeAttribute(meta)}"`,theme:productMode?'Theme7UnexpectedItemResult':'Theme7ScopeResult'})).join('')}</div></section></div>`;
}
function ic08Overlays(){return `${ic08NumericSheet()}${ic08SelectSheet()}`;}
function ic08SessionRow() {
  return `<section class="ds24-session-block" data-theme-component="Theme7StockCountSession"><div class="ds24-session-main">${ds24ListRow({title:'KK-0709-03',subtitle:'Kho trung tâm · Toàn kho',trailing:`${ds24Badge('Đang đếm','Info')}<small class="vet45-text-style-11">12/38</small>`,attrs:'data-ic08-action="resume"',leading:'listCheck',theme:'Theme7StockCountSessionRow'})}</div><button class="ds24-button ds24-button--danger ds24-session-cancel" type="button" data-ic08-action="cancel-open" data-action-contract="ACT-09-CANCEL" data-ds-component="VButton" data-figma-node="521:529">Hủy phiên</button></section>`;
}

function render042BJ08(state) {
  if (activeFlowId !== "UIF-08") return renderGeneric(screens.find(s => s.id === "SCR-042"), state);
  let html;
  if (state === "CANCEL_REQUEST") {
    html = ac310Return(appShell({title:"Kiểm kê kho",body:`${vBanner("warning","Yêu cầu hủy cần được xử lý trong phiên","Không đặt thao tác hủy trên màn danh sách. Mở đúng phiên kiểm kê để tiếp tục xử lý theo trạng thái hiện hành.")}${ac310InfoSurface("Phiên kiểm kê",[["Mã phiên","KK-0709-03",true],["Kho","Kho trung tâm"],["Trạng thái","Cần mở phiên để xử lý"]])}`,actions:primaryFooter("Về danh sách",'data-v350-action="ic08-cancel-request-back"'),back:false}));
  } else if (state === "READY" || state === "FILTER_EMPTY") {
    const records=[
      {id:"KK-0709-03",status:"COUNTING",title:"KK-0709-03",subtitle:"Kho trung tâm · Toàn kho · 12/38 đã đếm",badge:"Đang đếm",tone:"Info",action:'data-ic08-action="resume"'},
      {id:"KK-0708-02",status:"APPROVAL",title:"KK-0708-02",subtitle:"Kho trung tâm · Nhóm vaccine · Đã đếm xong",badge:"Chờ duyệt",tone:"Warning",action:'data-v350-action="ic08-open-approval"'}
    ];
    const q=bj08ListQuery.trim().toLocaleLowerCase("vi");
    const rows=(state==="FILTER_EMPTY"?[]:records.filter(r=>(bj08ListFilter==="ALL"||r.status===bj08ListFilter)&&(!q||`${r.title} ${r.subtitle}`.toLocaleLowerCase("vi").includes(q))));
    const chips=`<div class="ds24-chip-scroll ac320-chip-row" aria-label="Lọc phiên kiểm kê">${ds24Chip("ALL","Tất cả",bj08ListFilter==="ALL","data-v350-ic08-filter")}${ds24Chip("COUNTING","Đang đếm",bj08ListFilter==="COUNTING","data-v350-ic08-filter")}${ds24Chip("APPROVAL","Chờ duyệt",bj08ListFilter==="APPROVAL","data-v350-ic08-filter")}</div>`;
    const list=rows.length?`<div class="ac320-session-list">${rows.map(r=>ac310RecordRow({title:r.title,subtitle:r.subtitle,badge:r.badge,tone:r.tone,attrs:r.action,leading:null})).join("")}</div>`:ioEmpty("Không tìm thấy phiên kiểm kê","Thử từ khóa hoặc bộ lọc khác.");
    const body=`${ds24Search(bj08ListQuery,'data-v350-ic08-list-search','Tìm phiên kiểm kê')}${chips}${list}`;
    html = ac310Return(appShell({title:"Kiểm kê kho",body,actions:primaryFooter("Tạo phiên kiểm kê",'data-ic08-action="create"'),back:false}));
  } else if (state === "PENDING_APPROVAL") {
    html = ac310Return(appShell({title:"Kiểm kê kho",body:`${vBanner("info","Đã gửi chờ duyệt","Kết quả đếm lại đã được gửi sang công việc duyệt độc lập. Tồn kho chưa thay đổi.")}${ac310InfoSurface("Phiên kiểm kê",[["Mã phiên","KK-0709-03",true],["Kho","Kho trung tâm"],["Trạng thái","Chờ duyệt"]])}`,back:false}));
  } else {
    // LOADING / EMPTY / PERMISSION_DENIED (+ other) from original app.js, sanitized
    if(state==="PERMISSION_DENIED") html = appShell({title:"Kiểm kê kho",body:deniedBody(),centered:true,back:false});
    else if(state==="LOADING") html = appShell({title:"Kiểm kê kho",body:loadingBody(),back:false});
    else if(state==="EMPTY") html = appShell({title:"Kiểm kê kho",body:`${ds24EmptyState(false)}${ic08Overlays()}`,actions:primaryFooter("Tạo phiên kiểm kê",'data-ic08-action="create"'),back:false});
    else html = appShell({title:"Kiểm kê kho",body:`${ds24Search('','','Tìm phiên kiểm kê')}${ac321CanonicalChips('ALL',[["ALL","Tất cả"],["COUNTING","Đang đếm"],["APPROVAL","Chờ duyệt"]],'data-ic08-filter')}${ic08SessionRow()}${ic08Overlays()}`,actions:primaryFooter("Tạo phiên kiểm kê",'data-ic08-action="create"'),back:false});
    html = ac310SanitizeMarkup(html);
  }
  return String(html).replace(/data-ic08-action="create"/g,'data-v3100-ic08-action="new"').replace(/data-ic08-action="resume"/g,'data-v3100-ic08-action="resume-count"');
}


/* --- semantic hardening thắng (từ v3100), tiền tố bj08 --- */

const BJ08_BOOK={amox:20,glove:6};
const BJ08_META={
    amox:{name:'Amox 500',code:'SP-00128',lot:'L2407-A',uom:'hộp',state:'Bán được'},
    glove:{name:'Găng tay M',code:'SP-00410',lot:'L2405-M',uom:'hộp',state:'Cách ly'}
};
let bj08RoundNo=1;
let bj08RoundHistory=[];
let bj08ResultSnapshot=null;
let bj08DialogKind=null;
let bj08ApprovalCaseNo=1;
let bj08ContributorNames=['Nguyễn An'];

const bj08Num=(v)=>Number(String(v||'0').replace(',','.'))||0;
// ASCII "-" cho info row (v470 không đụng); U+2212 chỉ ở key-value (bj08KeyValueRow / SCR-045).
const bj08Signed=(n)=>`${n>0?'+':''}${n}`;
const bj08SignedKv=(n)=>n>0?`+${n}`:n<0?`−${Math.abs(n)}`:`${n}`;
const bj08AllZero=(vals)=>Object.keys(BJ08_BOOK).every(k=>bj08Num(vals[k])===BJ08_BOOK[k]) && (!ic08UnexpectedLine || bj08Num(ic08UnexpectedLine.value)===0);
const bj08CurrentVariance=(vals)=>Object.keys(BJ08_BOOK).map(k=>({id:k,...BJ08_META[k],book:BJ08_BOOK[k],count:bj08Num(vals[k]),variance:bj08Num(vals[k])-BJ08_BOOK[k]})).filter(x=>x.variance!==0);
const bj08Info=(rows)=>ic08ContextRows(rows);
const bj08LineHead=(m,badge='')=>ds24ListRow({title:m.name,subtitle:`${m.code} · Lô ${m.lot} · ${m.state} · ${m.uom}`,trailing:badge?ds24Badge(badge,'Info'):'',leading:'package',type:'Status',density:'Compact',interactive:false});
function bj08BlindRow(id){ const m=BJ08_META[id]; return `<section class="ac321-product-input-group" data-theme-component="Theme7StockCountLine" data-physical-count-key="${id}">${bj08LineHead(m)}<div class="ac321-product-field">${ic08QuantityTrigger('Số lượng thực tế',ic08Counts[id],`count:${id}`,m.uom,false)}</div></section>`; }
  function bj08KeyValueRow(label,value,attention=false){
    const cls=attention?' ds24-key-value-row v470-kv--attention':' ds24-key-value-row';
    // Match ds24KeyValueRow anatomy + v470 attention for "Chênh lệch" ≠ 0
    return `<div class="${cls.trim()}" data-ds-component="DS v2 / Key-value Row" data-figma-node="525:358" data-ds-prop-state="Default"><span>${esc(label)}</span><strong>${esc(value)}</strong></div>`;
  }
  function bj08RecountRow(id){ const m=BJ08_META[id], book=BJ08_BOOK[id], first=bj08Num(ic08Counts[id]), value=ic08Recounts[id], variance=first-book; return `<section class="ac321-product-input-group" data-theme-component="Theme7StockRecountLine" data-physical-count-key="${id}">${bj08LineHead(m)}<div class="ac321-product-facts">${ds24KeyValueRow('Theo sổ',`${book} ${m.uom}`)}${ds24KeyValueRow('Lần đếm đầu',`${first} ${m.uom}`)}${bj08KeyValueRow('Chênh lệch',`${bj08SignedKv(variance)} ${m.uom}`,variance!==0)}</div><div class="ac321-product-field">${ic08QuantityTrigger('Số lượng đếm lại',value,`recount:${id}`,m.uom,false)}</div></section>`; }
function bj08UnexpectedBlock(blind=true){
    if(!ic08UnexpectedLine) return '';
    const st=ic08UnexpectedLine.stockState||'';
    const select=`<label class="ds24-field" data-ds-component="VSelect"><span class="vet45-text-style-8">Trạng thái hàng</span><select class="ds24-field__control" data-v3100-stock-state><option value="">Chọn trạng thái</option><option value="SELLABLE" ${st==='SELLABLE'?'selected':''}>Bán được</option><option value="QUARANTINE" ${st==='QUARANTINE'?'selected':''}>Cách ly</option><option value="DAMAGED" ${st==='DAMAGED'?'selected':''}>Hỏng</option></select></label>`;
    const m={name:ic08UnexpectedLine.name,code:'Sản phẩm hiện có',lot:ic08UnexpectedLine.lot,uom:ic08UnexpectedLine.uom,state:st?({SELLABLE:'Bán được',QUARANTINE:'Cách ly',DAMAGED:'Hỏng'}[st]||st):'Chưa xác định trạng thái'};
    return `<section class="ac321-product-input-group" data-theme-component="Theme7UnexpectedPhysicalKey">${bj08LineHead(m,'Hàng thực tế')}${select}<div class="ac321-product-field">${ic08QuantityTrigger('Số lượng thực tế',ic08UnexpectedLine.value,'count:unexpected',m.uom,false)}</div><small class="vet45-text-style-11">Giá trị hàng thừa do nguồn có thẩm quyền cung cấp; người đếm không nhập giá.</small></section>`;
}
  // v361 dual footer: Secondary | Primary; cancel → danger secondary
  function bj08Footer(primaryLabel,primaryAction,secondary=true){
    if(!secondary) return `<footer class="app-actions figma-sticky-footer ds24-footer-stack" data-ds-pattern="Sticky Footer"><button class="ds24-button ds24-button--primary" type="button" data-v3100-ic08-action="${primaryAction}" data-ds-component="VButton">${primaryLabel}</button></footer>`;
    return `<footer class="app-actions figma-sticky-footer ds24-footer-stack v361-dual-footer v361-dual-footer--danger" data-ds-pattern="Sticky Footer" data-ds-prop-layout="Dual" data-ds-prop-tone="Danger"><button class="ds24-button ds24-button--secondary" type="button" data-v3100-ic08-action="cancel-open" data-action-contract="ACT-09-CANCEL" data-ds-component="VButton" data-ds-prop-tone="VComponentTone.danger" data-ds-profile="button.destructiveSecondary">Hủy phiên</button><button class="ds24-button ds24-button--primary" type="button" data-v3100-ic08-action="${primaryAction}" data-ds-component="VButton">${primaryLabel}</button></footer>`;
  }
  function bj08ApprovalFooter(){
    return `<footer class="app-actions figma-sticky-footer ds24-footer-stack v361-dual-footer" data-ds-prop-layout="Dual" data-ds-prop-tone="Default"><button class="ds24-button ds24-button--secondary" data-v3100-ic08-action="request-review">Yêu cầu xem lại</button><button class="ds24-button ds24-button--primary" data-v3100-ic08-action="approve">Duyệt và điều chỉnh</button></footer>`;
  }
  const bj08ExitList = () => primaryFooter('Về danh sách','data-v360-action="fallback-exit" data-v360-target="SCR-042"');
function bj08ConfirmSheet(){
    if(!bj08DialogKind)return '';
    const cfg={open:['Mở phiên kiểm kê?','Hệ thống khóa phạm vi trước khi chốt số sổ và mở phiên.','Mở phiên',false],first:['Nộp lần đếm đầu?','Sau khi nộp, số sổ và chênh lệch mới được hiển thị.','Nộp kết quả',false],recount:['Gửi kết quả đếm lại?','Kết quả được lưu thành một vòng đếm lại bất biến.','Gửi kết quả',false],approve:['Duyệt và điều chỉnh?','Hệ thống kiểm tra lại căn cứ giá, quyền và khóa trước khi ghi điều chỉnh.','Duyệt và điều chỉnh',false],review:['Yêu cầu đếm lại?','Vòng đếm hiện tại được giữ nguyên. Một vòng đếm lại mới sẽ được mở.','Yêu cầu đếm lại',true],cancel:['Hủy phiên kiểm kê?','Không tạo điều chỉnh; toàn bộ lịch sử đếm được giữ và phạm vi được mở khóa.','Hủy phiên',true]}[bj08DialogKind];
    if(!cfg)return '';
    const [title,desc,label,reason]=cfg; const val=bj08DialogKind==='cancel'?ic08CancelReason:ic08ReviewReason;
    const reasonHtml=reason?ds24TextField('Lý do',val,bj08DialogKind==='cancel'?'data-v3100-cancel-reason':'data-v3100-review-reason','Bắt buộc để lưu lịch sử quyết định.'):'';
    return `<div class="sheet-backdrop ds24-overlay"><section class="ds24-confirmation" data-ds-component="DS v2 / Confirmation Sheet" role="dialog" aria-modal="true"><div class="ds24-confirmation__handle"></div><h3 class="vet45-text-style-4">${title}</h3><p class="vet45-text-style-6">${desc}</p>${reasonHtml}<div class="ds24-confirmation__actions"><button class="ds24-button ds24-button--secondary" data-v3100-ic08-action="dialog-close">Quay lại</button><button class="ds24-button ${bj08DialogKind==='cancel'?'ds24-button--danger':'ds24-button--primary'}" data-v3100-ic08-action="confirm-${bj08DialogKind}" ${reason&&!val.trim()?'disabled':''}>${label}</button></div></section></div>`;
}
function bj08Overlays(){ return `${ic08NumericSheet()}${ic08SelectSheet()}${bj08ConfirmSheet()}`; }

function render043BJ08(state){
    if(activeFlowId!=='UIF-08') return renderGeneric(screens.find(s=>s.id==='SCR-043'),state);
    if(state==='COUNT_SCOPE_HAS_UNRESOLVED_VALUATION') return appShell({title:'Tạo phiên kiểm kê',body:`${vBanner('warning','Chưa thể mở phiên','Phạm vi còn hàng chờ xác nhận giá trị. Hoàn tất phần giá trị hàng nhận trước khi kiểm kê.')}${bj08Info([['Kho','Kho trung tâm'],['Người đếm',ic08AssignedCounter]])}`,actions:primaryFooter('Về kiểm kê','data-v3100-ic08-action="to-list"')});
    const scopeOptions=[['ALL','Toàn kho'],['PRODUCT','Sản phẩm'],['GROUP','Nhóm sản phẩm'],['LOT','Lô']];
    const target=ic08Scope==='ALL'?'':`<button class="ds24-button ds24-button--secondary" type="button" data-ic08-action="scope-select-open">${ic08ScopeTarget||'Chọn phạm vi cụ thể'}</button>`;
    const body=`${bj08Info([['Kho','Kho trung tâm'],['Thời điểm chốt','Khi mở phiên'],['Người đếm',ic08AssignedCounter]])}${ds24SelectField('Phạm vi',ic08Scope,scopeOptions,'data-ic08-scope')}${target}${ds24TextField('Lý do kiểm kê',ic08Reason,'data-ic08-reason')}${vBanner('info','Phạm vi được khóa khi mở phiên','Hệ thống chốt số sổ và thành viên nhóm tại thời điểm khóa phạm vi.')}${bj08Overlays()}`;
    return appShell({title:'Tạo phiên kiểm kê',body,actions:primaryFooter('Mở phiên kiểm kê','data-v3100-ic08-action="open"')});
};

function render044BJ08(state){
    if(activeFlowId!=='UIF-08') return renderGeneric(screens.find(s=>s.id==='SCR-044'),state);
    const validation=state==='VALIDATION_ERROR'?vBanner('error','Chưa đủ kết quả đếm','Nhập số lượng thực tế cho tất cả dòng trước khi nộp.'):'';
    const body=`${validation}${vBanner('info','Đếm mù','Số lượng theo sổ chỉ xuất hiện sau khi nộp lần đếm đầu.')}${bj08Info([['Phiên','KK-1709-01'],['Kho','Kho trung tâm'],['Người đếm',ic08AssignedCounter]])}${ic08Section('Hàng trong phạm vi',bj08BlindRow('amox')+bj08BlindRow('glove'))}${bj08UnexpectedBlock(true)}<button class="ds24-button ds24-button--secondary" type="button" data-ic08-action="add-actual-open">Thêm hàng thực tế</button>${bj08Overlays()}`;
    return appShell({title:'Đếm mù',body,actions:bj08Footer('Nộp kết quả đếm','submit-first',true)});
};

function render045BJ08(state){
    if(activeFlowId!=='UIF-08') return renderGeneric(screens.find(s=>s.id==='SCR-045'),state);
    const diffs=bj08CurrentVariance(ic08Counts);
    const ids=diffs.map(x=>x.id);
    const rows=ids.map(bj08RecountRow).join('');
    const basisBlocked=state==='PRICE_BASIS_REQUIRED';
    const basis=basisBlocked?vBanner('warning','Thiếu căn cứ giá hàng thừa','Phiên vẫn khóa; căn cứ giá phải đến từ nguồn có thẩm quyền.'):bj08Info([['Căn cứ giá hàng thừa',ids.includes('glove')?'Đã xác nhận':'Không phát sinh'],['Khóa phạm vi','Đang giữ']]);
    const validation=state==='VALIDATION_ERROR'?vBanner('error','Kết quả đếm lại chưa hợp lệ','Nhập số lượng đếm lại cho tất cả dòng chênh lệch.'):'';
    const body=`${validation}${vBanner('warning',`Đếm lại lần ${bj08RoundNo}`,`${ids.length} dòng còn chênh lệch. Kết quả vòng trước được giữ nguyên trong lịch sử.`)}${ic08Section('Dòng cần đếm lại',rows||'<p class="vet45-text-style-7">Không còn dòng chênh lệch.</p>')}${basis}${bj08Overlays()}`;
    return appShell({title:'Chênh lệch và đếm lại',body,actions:bj08Footer('Gửi kết quả đếm lại','submit-recount',true)});
};

  function render046BJ08(state){
    if(activeFlowId!=='UIF-08') return renderGeneric(screens.find(s=>s.id==='SCR-046'),state);
    // v360 ensureStableExitAffordance: màn không nút → "Về danh sách"
    if(state==='PERMISSION_DENIED')return appShell({title:'Duyệt kết quả kiểm kê',body:deniedBody(),centered:true,actions:bj08ExitList(),back:false});
    if(state==='COUNT_APPROVAL_SNAPSHOT_STALE')return appShell({title:'Duyệt kết quả kiểm kê',body:`${vBanner('warning','Kết quả cần được lập lại','Căn cứ giá hoặc dữ liệu kiểm kê đã thay đổi. Không thể điều chỉnh theo lần duyệt cũ.')}${bj08Info([['Phiên','KK-1709-01'],['Tác động','Chưa ghi điều chỉnh']])}`,actions:bj08ExitList(),back:false});
    if(state==='SELF_APPROVAL_NOT_ALLOWED')return appShell({title:'Duyệt kết quả kiểm kê',body:vBanner('warning','Không thể tự duyệt','Bạn đã tham gia kiểm đếm của kết quả này. Công việc cần người duyệt độc lập.'),actions:bj08ExitList(),back:false});
    if(state==='APPROVAL_ALREADY_DECIDED')return appShell({title:'Duyệt kết quả kiểm kê',body:vBanner('info','Công việc đã có quyết định','Mở kết quả phiên để xem trạng thái hiện hành.'),actions:primaryFooter('Xem kết quả','data-v3100-ic08-action="approval-result"'),back:false});
    const vals={amox:String(ic08Recounts.amox??'').trim()!==''?ic08Recounts.amox:(String(ic08Counts.amox??'').trim()!==''?ic08Counts.amox:'18'),glove:String(ic08Recounts.glove??'').trim()!==''?ic08Recounts.glove:(String(ic08Counts.glove??'').trim()!==''?ic08Counts.glove:'7')};
    const diffs=Object.keys(BJ08_BOOK).map(k=>({id:k,...BJ08_META[k],book:BJ08_BOOK[k],count:bj08Num(vals[k]),variance:bj08Num(vals[k])-BJ08_BOOK[k]})).filter(x=>x.variance!==0);
    const lines=diffs.map(x=>ic08Section(`${x.name} · ${x.lot}`,bj08Info([['Trạng thái',x.state],['Theo sổ',`${x.book} ${x.uom}`],['Đếm lại',`${x.count} ${x.uom}`],['Chênh lệch',`${bj08Signed(x.variance)} ${x.uom}`],...(x.variance>0?[['Căn cứ giá hàng thừa','Đã xác nhận']]:[['Căn cứ giá thiếu','Giá vốn đã khóa']])]))).join('');
    const body=`${vBanner('info','Cần quyết định độc lập','Bạn chỉ rà soát kết quả và quyết định; không sửa số đếm.','v360-context-banner')}${bj08Info([['Phiên','KK-1709-01'],['Lần đếm lại',String(bj08RoundNo)],['Người đã tham gia đếm',bj08ContributorNames.join(', ')],['Mức duyệt','Đã xác định theo rủi ro hiện hành']])}${lines}${bj08Overlays()}`;
    return appShell({title:'Duyệt kết quả kiểm kê',body,actions:bj08ApprovalFooter(),back:false});
  };

function render047BJ08(state){
    if(activeFlowId!=='UIF-08') return renderGeneric(screens.find(s=>s.id==='SCR-047'),state);
    const snap=bj08ResultSnapshot;
    // legacy-cross-theme-copy: "Định danh xử lý" → "Lần xử lý"
    if(state==='UNKNOWN')return appShell({title:'Kết quả kiểm kê',body:ds24Result('Đang xác minh kết quả','Không gửi lại thao tác. Hệ thống cần xác minh đúng lần xử lý này.',[['Phiên','KK-1709-01'],['Lần xử lý','Giữ nguyên'],['Tồn kho','Chưa kết luận']],'warning'),actions:primaryFooter('Chuyển sang xác minh','data-v350-action="handoff-unknown" data-source-flow="UIF-08" data-operation="KK-1709-01" data-scope="Kho trung tâm · Kiểm kê"'),centered:true,back:false});
    if(state==='CANCELLED'||snap?.type==='CANCELLED')return appShell({title:'Kết quả kiểm kê',body:ds24Result('Đã hủy phiên','Không tạo điều chỉnh. Lịch sử đếm được giữ và phạm vi đã mở khóa.',[['Phiên','KK-1709-01'],['Điều chỉnh','Không tạo'],['Khóa phạm vi','Đã mở'],['Thời điểm','17/09/2026 09:52']],'warning'),actions:primaryFooter('Về kiểm kê','data-v3100-ic08-action="to-list"'),centered:true,back:false});
    if(state==='REJECTED_EXECUTION')return appShell({title:'Kết quả kiểm kê',body:ds24Result('Chưa thực hiện điều chỉnh','Điều kiện nghiệp vụ không đạt; không có tác động tồn kho.',[['Phiên','KK-1709-01'],['Tác động','Không ghi nhận']],'warning'),actions:primaryFooter('Về kiểm kê','data-v3100-ic08-action="to-list"'),centered:true,back:false});
    if(snap?.type==='ZERO')return appShell({title:'Kết quả kiểm kê',body:ds24Result('Đã hoàn tất kiểm kê','Kết quả thực tế khớp số sổ. Không cần tạo điều chỉnh và phạm vi đã mở khóa.',[['Phiên','KK-1709-01'],['Điều chỉnh','Không tạo'],['Khóa phạm vi','Đã mở'],['Hoàn tất lúc',snap.committedAt]]),actions:primaryFooter('Về kiểm kê','data-v3100-ic08-action="to-list"'),centered:true,back:false});
    return appShell({title:'Kết quả kiểm kê',body:ds24Result('Đã hoàn tất kiểm kê','Điều chỉnh chênh lệch đã được ghi và phạm vi đã mở khóa.',[['Phiên','KK-1709-01'],['Điều chỉnh',snap?.adjustmentId||'ADJ-1709-08'],['Đã điều chỉnh',`${snap?.lines||2} dòng`],['Khóa phạm vi','Đã mở'],['Ghi nhận lúc',snap?.committedAt||'17/09/2026 09:52']]),actions:primaryFooter('Về kiểm kê','data-v3100-ic08-action="to-list"'),centered:true,back:false});
};

function bj08Rerender(){ if(typeof renderAppScreen==='function')renderAppScreen(); }

Object.assign(window.__VET45_QA__, { bj08RoundHistory: () => bj08RoundHistory.slice(), bj08Result: () => bj08ResultSnapshot });


/* --- listeners (app.js Audit UIF-08 sống + v350 list + v3100) --- */
document.addEventListener("input",(event)=>{
  if(activeFlowId!=="UIF-08") return;
  if(event.target.matches("[data-ic08-reason]")){ic08Reason=event.target.value;return;}
  if(event.target.matches("[data-v350-ic08-list-search]")){bj08ListQuery=event.target.value;return renderAppScreen();}
  if(event.target.matches("[data-v3100-cancel-reason]")){ic08CancelReason=event.target.value;return bj08Rerender();}
  if(event.target.matches("[data-v3100-review-reason]")){ic08ReviewReason=event.target.value;return bj08Rerender();}
},true);
document.addEventListener("change",(event)=>{
  if(activeFlowId!=="UIF-08") return;
  if(event.target.matches("[data-ic08-scope]")){ic08Scope=event.target.value;ic08ScopeTarget="";ic08ScopeSheetOpen=false;return renderAppScreen();}
  if(event.target.matches("[data-v3100-stock-state]")&&ic08UnexpectedLine){ic08UnexpectedLine.stockState=event.target.value;return bj08Rerender();}
},true);
document.addEventListener("click",(event)=>{
  if(activeFlowId!=="UIF-08") return;
  const f=event.target.closest("[data-v350-ic08-filter]");
  if(f){event.preventDefault();event.stopPropagation();bj08ListFilter=f.dataset.v350Ic08Filter;return renderAppScreen();}
  const openAppr=event.target.closest('[data-v350-action="ic08-open-approval"]');
  if(openAppr){event.preventDefault();event.stopPropagation();stateByScreen["SCR-046"]="APPROVAL_REVIEW";return navigate("SCR-046");}
  const backCancel=event.target.closest('[data-v350-action="ic08-cancel-request-back"]');
  if(backCancel){event.preventDefault();event.stopPropagation();stateByScreen["SCR-042"]="READY";return renderAppScreen();}

  const key=event.target.closest("[data-ic08-key]");
  if(key){event.preventDefault();const k=key.dataset.ic08Key;if(k==="⌫")ic08KeypadDraft=ic08KeypadDraft.slice(0,-1);else if(k==="."){if(!ic08KeypadDraft.includes("."))ic08KeypadDraft=(ic08KeypadDraft||"0")+".";}else{ic08KeypadDraft=(ic08KeypadDraft==="0"?"":ic08KeypadDraft)+k;}return renderAppScreen();}
  const qty=event.target.closest("[data-ic08-keypad-open]");
  if(qty&&!qty.disabled){event.preventDefault();ic08KeypadTarget=qty.dataset.ic08KeypadOpen;const [mode,id]=ic08KeypadTarget.split(":");ic08KeypadDraft=mode==="recount"?(ic08Recounts[id]||"0"):(id==="unexpected"?(ic08UnexpectedLine?.value||"0"):(ic08Counts[id]||"0"));return renderAppScreen();}
  const scopeTarget=event.target.closest("[data-ic08-scope-target]");
  if(scopeTarget){event.preventDefault();ic08ScopeTarget=scopeTarget.dataset.name||scopeTarget.textContent.trim();ic08ScopeSheetOpen=false;return renderAppScreen();}
  const product=event.target.closest("[data-ic08-product]");
  if(product){event.preventDefault();const id=product.dataset.ic08Product;ic08UnexpectedLine=id==="vitc"?{id:"unexpected",name:"Vitamin C",lot:"L2501-C",uom:"hộp",value:"0"}:{id:"unexpected",name:"Amox 500",lot:"L2501-A",uom:"hộp",value:"0"};ic08ProductSheetOpen=false;return renderAppScreen();}
  const aIc=event.target.closest("[data-ic08-action]");
  if(aIc&&!aIc.disabled){event.preventDefault();const k=aIc.dataset.ic08Action;
    if(k==="scope-select-open"){ic08ScopeSheetOpen=true;ic08ProductSheetOpen=false;return renderAppScreen();}
    if(k==="add-actual-open"){ic08ProductSheetOpen=true;ic08ScopeSheetOpen=false;return renderAppScreen();}
    if(k==="select-close"){ic08ProductSheetOpen=false;ic08ScopeSheetOpen=false;return renderAppScreen();}
    if(k==="keypad-cancel"){ic08KeypadTarget=null;ic08KeypadDraft="";return renderAppScreen();}
    if(k==="keypad-save"){
      const [mode,id]=(ic08KeypadTarget||":").split(":");const v=ic08KeypadDraft||"0";
      if(mode==="recount"&&id)ic08Recounts[id]=v;else if(mode==="count"&&id==="unexpected"&&ic08UnexpectedLine)ic08UnexpectedLine.value=v;else if(mode==="count"&&id)ic08Counts[id]=v;
      ic08KeypadTarget=null;ic08KeypadDraft="";return renderAppScreen();
    }
  }

  const a=event.target.closest("[data-v3100-ic08-action]"); if(!a||a.disabled)return;
  event.preventDefault();event.stopImmediatePropagation(); const k=a.dataset.v3100Ic08Action;
  if(k==='new'){bj08RoundNo=1;bj08RoundHistory=[];bj08ResultSnapshot=null;bj08DialogKind=null;bj08ApprovalCaseNo=1;bj08ContributorNames=[ic08AssignedCounter];ic08Counts={amox:'',glove:''};ic08Recounts={amox:'',glove:''};ic08UnexpectedLine=null;ic08CancelReason='';ic08ReviewReason='';stateByScreen['SCR-043']='READY';return navigate('SCR-043');}
  if(k==='resume-count'){return navigate('SCR-044');}
  if(k==='to-list'){bj08ResultSnapshot=null;return navigate('SCR-042');}
  if(k==='open'){bj08DialogKind='open';return bj08Rerender();}
  if(k==='confirm-open'){bj08DialogKind=null;stateByScreen['SCR-044']='BLIND_COUNT';return navigate('SCR-044');}
  if(k==='submit-first'){bj08DialogKind='first';return bj08Rerender();}
  if(k==='confirm-first'){
    bj08DialogKind=null;
    const missing=Object.keys(BJ08_BOOK).some(id=>String(ic08Counts[id]??'').trim()===''||!Number.isFinite(Number(ic08Counts[id]))||Number(ic08Counts[id])<0);
    if(missing||(ic08UnexpectedLine&&bj08Num(ic08UnexpectedLine.value)>0&&!ic08UnexpectedLine.stockState)){stateByScreen['SCR-044']='VALIDATION_ERROR';return bj08Rerender();}
    bj08RoundHistory.push({round:1,type:'FIRST',actor:ic08AssignedCounter,values:{...ic08Counts},hash:'cnt-first-v3100'});
    if(bj08AllZero(ic08Counts)){bj08ResultSnapshot={type:'ZERO',committedAt:'17/09/2026 09:50'};stateByScreen['SCR-047']='COMPLETED';return navigate('SCR-047');}
    bj08RoundNo=1;stateByScreen['SCR-045']='RECOUNT_REQUIRED';return navigate('SCR-045');
  }
  if(k==='submit-recount'){bj08DialogKind='recount';return bj08Rerender();}
  if(k==='confirm-recount'){
    bj08DialogKind=null;
    const ids=bj08CurrentVariance(ic08Counts).map(x=>x.id);
    const missing=ids.some(id=>String(ic08Recounts[id]??'').trim()===''||!Number.isFinite(Number(ic08Recounts[id]))||Number(ic08Recounts[id])<0);
    if(missing){stateByScreen['SCR-045']='VALIDATION_ERROR';return bj08Rerender();}
    if(stateByScreen['SCR-045']==='PRICE_BASIS_REQUIRED'){return bj08Rerender();}
    bj08RoundHistory.push({round:bj08RoundNo+1,type:'RECOUNT',actor:ic08AssignedCounter,values:{...ic08Recounts},hash:`cnt-recount-${bj08RoundNo+1}-v3100`});
    if(bj08AllZero(ic08Recounts)){bj08ResultSnapshot={type:'ZERO',committedAt:'17/09/2026 09:51'};stateByScreen['SCR-047']='COMPLETED';return navigate('SCR-047');}
    stateByScreen['SCR-042']='PENDING_APPROVAL';bj08ApprovalCaseNo+=1;return navigate('SCR-042');
  }
  if(k==='cancel-open'){ic08CancelReason='';bj08DialogKind='cancel';return bj08Rerender();}
  if(k==='confirm-cancel'){if(!ic08CancelReason.trim())return;bj08DialogKind=null;bj08ResultSnapshot={type:'CANCELLED',reason:ic08CancelReason};stateByScreen['SCR-047']='CANCELLED';return navigate('SCR-047');}
  if(k==='approve'){if(currentActor()!=='approver'){stateByScreen['SCR-046']='SELF_APPROVAL_NOT_ALLOWED';return bj08Rerender();}bj08DialogKind='approve';return bj08Rerender();}
  if(k==='confirm-approve'){if(currentActor()!=='approver'){bj08DialogKind=null;stateByScreen['SCR-046']='SELF_APPROVAL_NOT_ALLOWED';return bj08Rerender();}bj08DialogKind=null;bj08ResultSnapshot={type:'ADJUSTED',adjustmentId:'ADJ-1709-08',lines:bj08CurrentVariance(ic08Recounts).length,committedAt:'17/09/2026 09:52'};stateByScreen['SCR-047']='COMPLETED';return navigate('SCR-047');}
  if(k==='request-review'){if(currentActor()!=='approver'){stateByScreen['SCR-046']='SELF_APPROVAL_NOT_ALLOWED';return bj08Rerender();}ic08ReviewReason='';bj08DialogKind='review';return bj08Rerender();}
  if(k==='confirm-review'){if(!ic08ReviewReason.trim())return;bj08DialogKind=null;bj08RoundNo+=1;stateByScreen['SCR-045']='RECOUNT_REQUIRED';return navigate('SCR-045');}
  if(k==='dialog-close'){bj08DialogKind=null;return bj08Rerender();}
  if(k==='approval-result'){stateByScreen['SCR-047']='COMPLETED';return navigate('SCR-047');}
},true);


Object.assign(renderers, {
  "SCR-042": render042BJ08,
  "SCR-043": render043BJ08,
  "SCR-044": render044BJ08,
  "SCR-045": render045BJ08,
  "SCR-046": render046BJ08,
  "SCR-047": render047BJ08
});
