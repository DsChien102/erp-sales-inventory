/* BJ-09 — Quản lý trạng thái hàng (UIF-09). Màn: SCR-036, SCR-037, SCR-038, SCR-041, SCR-056.
 *
 * Đã viết lại sạch (T7-P gói A6, 2026-10-17). Màn dùng chung đăng ký qua flowRenderers.
 * SCR-056 không có movement → rơi về chuỗi BJ-15 trong renderers["SCR-056"] (A9 thay).
 * ac310SanitizeMarkup lấy từ core.js (A7 → shared-control.js).
 */

let ic09Filter="ALL";
let ic09Query="";
let ic09Selected="amox";
let ic09Destination="QUARANTINE";
const ic09Items=[
  {id:"amox",name:"Amox 500",code:"SP-00128",lot:"L2407-A",qty:18,uom:"hộp",state:"SELLABLE",label:"Bán được",expiry:"30/11/2026"},
  {id:"găng",name:"Găng tay M",code:"SP-00410",lot:"L2405-M",qty:6,uom:"hộp",state:"QUARANTINE",label:"Cách ly",expiry:"—"},
  {id:"vitc",name:"Vitamin C",code:"SP-00231",lot:"L2310-C",qty:4,uom:"hộp",state:"EXPIRED",label:"Hết hạn",expiry:"31/08/2026"},
  {id:"dungthu",name:"Dầu sát khuẩn",code:"SP-00606",lot:"L2406-T",qty:2,uom:"chai",state:"DEMO",label:"Dùng thử",expiry:"31/12/2027"}
];
function icCard(title,body){const calibrated=FIGMA_MIGRATED_FLOWS.has(activeFlowId);return `<section class="review-card" data-ds-component="${calibrated?'VSection':'VCard'}" ${calibrated?'data-composed-from="VText,DS v2 / Info Row,VTextField"':'data-ds-profile="card.readOnly"'}><div class="review-card-header"><strong>${title}</strong></div><div class="review-card-body">${body}</div></section>`;}
function icField(label,value,attr="",type="text",hint=""){return `<div class="form-field" data-ds-component="${type==='number'?'VNumberField':'VTextField'}"><label>${label}</label><div class="input-shell"><input type="${type}" value="${escapeAttribute(value)}" ${attr}></div>${hint?`<small class="helper-text">${hint}</small>`:""}</div>`;}
function icTextarea(label,value,attr="",placeholder=""){return `<div class="form-field ic-textarea-field" data-ds-component="VTextarea" data-figma-node="522:7212"><label>${label}</label><textarea class="textarea" ${attr} placeholder="${escapeAttribute(placeholder)}">${esc(value)}</textarea></div>`;}
function icChoice(value,label,detail,checked=false){return `<label class="v364-radio-option" data-ds-component="VRadio" data-figma-node="522:7410" data-ds-prop-state="${checked?'On':'Off'}"><input type="radio" name="ic-state" value="${escapeAttribute(value)}" data-ic09-destination ${checked?'checked':''}><span class="v364-radio-control" aria-hidden="true"></span><span class="v364-radio-copy"><strong>${esc(label)}</strong>${detail?`<small>${esc(detail)}</small>`:''}</span></label>`;}
function icHeaderRows(rows){return ioReadCard(rows.map(([a,b,strong])=>ioMetaRow(a,b,!!strong)).join(''));}
function icSecondary(label,action,tone="secondary"){const c=tone==='danger'?'button button--danger button--full':'button button--secondary button--full';return `<button class="${c}" type="button" ${action}>${label}</button>`;}
function icApprovalButtons(prefix){return `<div class="ic-action-stack">${icSecondary("Từ chối",`data-${prefix}-action="reject"`,'danger')}${primaryFooter("Duyệt",`data-${prefix}-action="approve"`)}</div>`;}

function ic09StatusTone(s){return s==="EXPIRED"||s==="DAMAGED"?"danger":s==="QUARANTINE"?"warning":s==="DEMO"?"info":"success";}
function ic09Current(){return ic09Items.find(x=>x.id===ic09Selected)||ic09Items[0];}
function render036IC09(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Tình trạng hàng",body:deniedBody(),centered:true,back:false});
  if(state==="LOADING")return appShell({title:"Tình trạng hàng",body:loadingBody(),back:false});
  const labels=[["ALL","Tất cả"],["SELLABLE","Bán được"],["QUARANTINE","Cách ly"],["DAMAGED","Hỏng"],["DEMO","Dùng thử"],["EXPIRED","Hết hạn"]];
  const q=ic09Query.trim().toLowerCase();
  const items=ic09Items.filter(x=>(ic09Filter==="ALL"||x.state===ic09Filter)&&(!q||`${x.name} ${x.code} ${x.lot}`.toLowerCase().includes(q)));
  if(state==="EMPTY")return appShell({title:"Tình trạng hàng",body:ioEmpty("Chưa có hàng trong kho","Khi có tồn kho, tình trạng hàng sẽ xuất hiện tại đây."),back:false});
  const rows=items.map(x=>ioProductRow({name:x.name,code:x.code,primary:`${x.qty} ${x.uom}`,secondary:`Lô ${x.lot}`,badge:x.label,badgeStatus:ic09StatusTone(x.state),attr:`data-ic09-item="${x.id}"`})).join('');
  const statusChips=`<div class="ac321-chip-wrap" data-composed-from="VChip">${labels.map(([k,l])=>ds24Chip(k,l,ic09Filter===k,'data-ic09-filter')).join('')}</div>`;
  const body=`${ds24Search(ic09Query,'data-ic09-search','Tìm sản phẩm hoặc lô')}${statusChips}${rows?`<div class="io-list-card" data-ds-component="VSection" data-composed-from="DS v2 / List Row,VBadge"><div class="io-product-list">${rows}</div></div>`:ioEmpty("Không có hàng phù hợp","Thử đổi bộ lọc hoặc từ khóa tìm kiếm.")}`;
  return appShell({title:"Tình trạng hàng",body,back:false});
}
function render037IC09(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Chi tiết tình trạng hàng",body:deniedBody(),centered:true});
  if(state==="LOADING")return appShell({title:"Chi tiết tình trạng hàng",body:loadingBody()});
  const x=ic09Current(); const expired=state==="EXPIRED"||x.state==="EXPIRED";
  const locked=state==="LOCKED";
  const notice=expired?vBanner("warning","Lô đã hết hạn","Hạn dùng đã qua theo ngày nghiệp vụ. Hệ thống tự loại phần này khỏi khả dụng bán; không cần thao tác đánh dấu."):locked?vBanner("info","Đang thuộc phạm vi kiểm kê","Thông tin chỉ đọc cho đến khi phiên kiểm kê kết thúc."):"";
  const body=`${notice}${icHeaderRows([["Sản phẩm",x.name,true],["Mã",x.code],["Lô",x.lot],["Hạn dùng",x.expiry],["Tình trạng",expired?"Hết hạn":x.label],["Tồn vật lý",`${x.qty} ${x.uom}`],["Khả dụng bán",expired?`0 ${x.uom}`:(x.state==="SELLABLE"?`${x.qty} ${x.uom}`:`0 ${x.uom}`)]])}${ioSectionTitle("Tác động")}<p class="io-footnote">Thay đổi tình trạng chỉ phân loại lại cùng lượng hàng; tổng tồn vật lý và giá trị không đổi.</p>${icSecondary("Xem lịch sử",'data-ic09-action="history"')}`;
  return appShell({title:"Chi tiết tình trạng hàng",body,actions:locked||expired?"":primaryFooter("Thay đổi tình trạng",'data-ic09-action="change"')});
}
function render041IC09(state){
  if(state==="PROCESSING")return appShell({title:"Kết quả thay đổi",body:loadingBody(),centered:true,back:false});
  if(state==="UNKNOWN")return appShell({title:"Kết quả thay đổi",body:ioResult("Đang xác minh kết quả","Không gửi một yêu cầu mới. Hệ thống đang kiểm tra cùng lần xử lý này.",[["Sản phẩm",ic09Current().name],["Tình trạng","Chưa kết luận"]],"warning"),actions:primaryFooter("Kiểm tra kết quả",'data-ic09-action="verify"'),centered:true,back:false});
  if(state==="REJECTED_EXECUTION")return appShell({title:"Kết quả thay đổi",body:ioResult("Yêu cầu không được thực hiện","Tình trạng và tồn kho không thay đổi.",[["Sản phẩm",ic09Current().name],["Tồn vật lý","Không đổi"]],"warning"),actions:primaryFooter("Về tình trạng hàng",'data-ic09-action="to-list"'),centered:true,back:false});
  if(state==="EXPIRED")return appShell({title:"Tình trạng hàng",body:ioResult("Lô đã hết hạn","Hệ thống đã loại lượng hàng này khỏi khả dụng bán theo hạn dùng; tồn vật lý vẫn được giữ để tiếp tục xử lý.",[["Tồn vật lý","4 hộp"],["Khả dụng bán","0 hộp"]],"warning"),actions:primaryFooter("Về tình trạng hàng",'data-ic09-action="to-list"'),centered:true,back:false});
  return appShell({title:"Kết quả thay đổi",body:ioResult("Đã cập nhật tình trạng","Cùng lượng hàng đã được phân loại lại; tổng tồn vật lý và giá trị không thay đổi.",[["Sản phẩm",ic09Current().name],["Tình trạng mới",ic09Destination==="QUARANTINE"?"Cách ly":ic09Destination==="DAMAGED"?"Hỏng":ic09Destination==="DEMO"?"Dùng thử":"Bán được"],["Tồn vật lý",`${ic09Current().qty} ${ic09Current().uom} · không đổi`]]),actions:primaryFooter("Về tình trạng hàng",'data-ic09-action="to-list"'),centered:true,back:false});
}

/* --- semantic hardening thắng (từ v3101) --- */
(()=>{

  'use strict';
  const VERSION='3.10.1';
  const BUSINESS_DATE='17/09/2026';
  const POLICY={
    id:'STPOL-INVENTORY-STATE',versionId:'STPOL-V7-20260917-01',version:'7',fixtureHash:'fixture-sha256-policy-v7',
    transitions:{
      SELLABLE:{
        QUARANTINE:{label:'Cách ly',reason:true,evidence:false,approval:true,eligibility:'DECREASE'},
        DAMAGED:{label:'Hỏng',reason:true,evidence:true,approval:true,eligibility:'DECREASE'},
        DEMO:{label:'Dùng thử',reason:true,evidence:false,approval:false,eligibility:'DECREASE'}
      },
      QUARANTINE:{
        SELLABLE:{label:'Bán được',reason:true,evidence:true,approval:true,eligibility:'INCREASE'},
        DAMAGED:{label:'Hỏng',reason:true,evidence:false,approval:true,eligibility:'UNCHANGED'},
        DEMO:{label:'Dùng thử',reason:true,evidence:false,approval:false,eligibility:'UNCHANGED'}
      },
      DAMAGED:{QUARANTINE:{label:'Cách ly',reason:true,evidence:true,approval:true,eligibility:'UNCHANGED'}},
      DEMO:{
        SELLABLE:{label:'Bán được',reason:true,evidence:true,approval:true,eligibility:'INCREASE'},
        QUARANTINE:{label:'Cách ly',reason:true,evidence:false,approval:false,eligibility:'UNCHANGED'},
        DAMAGED:{label:'Hỏng',reason:true,evidence:true,approval:true,eligibility:'UNCHANGED'}
      },
      EXPIRED:{}
    }
  };
  const SOURCE={
    amox:{slices:[{balanceId:'BAL-AMOX-C',version:7,valuationState:'VALUATION_CONFIRMED',qty:12},{balanceId:'BAL-AMOX-P',version:4,valuationState:'VALUATION_PENDING',qty:6}],reservationBefore:10},
    'găng':{slices:[{balanceId:'BAL-GLOVE-C',version:3,valuationState:'VALUATION_CONFIRMED',qty:6}],reservationBefore:0},
    vitc:{slices:[{balanceId:'BAL-VITC-C',version:2,valuationState:'VALUATION_CONFIRMED',qty:4}],reservationBefore:0},
    dungthu:{slices:[{balanceId:'BAL-DEMO-C',version:5,valuationState:'VALUATION_CONFIRMED',qty:2}],reservationBefore:0}
  };
  let draft={destination:'QUARANTINE',quantity:'5',reason:'Bao bì có dấu hiệu bất thường',evidence:''};
  let basis=null, decision=null, rejectOpen=false, rejectReason='', movement=null, seq=1;
  let staleOnExecute=false;

  const escText=(v)=>typeof esc==='function'?esc(String(v??'')):String(v??'');
  const num=(v)=>Number(String(v??'').replace(',','.'))||0;
  const current=()=>ic09Current();
  const actor=()=>window.__VET45_V350__?.getActor?.()||'module';
  const stateLabel=(v)=>({SELLABLE:'Bán được',QUARANTINE:'Cách ly',DAMAGED:'Hỏng',DEMO:'Dùng thử',EXPIRED:'Hết hạn'}[v]||v);
  const transition=()=>POLICY.transitions[current().state]?.[draft.destination]||null;
  function fixtureHash(payload){
    // Deterministic harness fixture only. Production contract requires canonical SHA-256.
    const s=JSON.stringify(payload);let h=2166136261;
    for(let i=0;i<s.length;i++){h^=s.charCodeAt(i);h=Math.imul(h,16777619);}return `fixture-${(h>>>0).toString(16).padStart(8,'0')}`;
  }
  function resolveSlices(item,qty){
    const src=SOURCE[item.id]?.slices||[]; let remaining=qty,out=[];
    // Fixture resolver uses stable source-lineage order. Production resolver is server-owned.
    for(const slice of src){if(remaining<=0)break;const take=Math.min(remaining,slice.qty);if(take>0){out.push({...slice,quantity:take});remaining-=take;}}
    if(remaining>0)return null;
    return out;
  }
  function eligibleQty(item,slices){
    if(item.state!=='SELLABLE')return 0;
    return (slices||SOURCE[item.id]?.slices||[]).filter(x=>x.valuationState==='VALUATION_CONFIRMED').reduce((a,x)=>a+(x.qty??x.quantity??0),0);
  }
  function basisValid(){
    const x=current(),t=transition(),q=num(draft.quantity);
    if(!t||q<=0||q>x.qty||!draft.reason.trim())return false;
    if(t.evidence && !draft.evidence.trim())return false;
    return Boolean(resolveSlices(x,q));
  }
  function buildBasis(){
    const x=current(),t=transition(),q=num(draft.quantity),slices=resolveSlices(x,q);
    if(!t||!slices)return null;
    const src=SOURCE[x.id]||{reservationBefore:0};
    const beforeEligible=eligibleQty(x);
    const confirmedMoved=slices.filter(z=>z.valuationState==='VALUATION_CONFIRMED').reduce((a,z)=>a+z.quantity,0);
    const destinationEligible=draft.destination==='SELLABLE';
    const afterEligible=Math.max(0,beforeEligible-(x.state==='SELLABLE'?confirmedMoved:0)+(destinationEligible?confirmedMoved:0));
    const reservationAfter=Math.min(src.reservationBefore||0,afterEligible);
    const payload={
      basisId:`SCB-1709-${String(seq++).padStart(3,'0')}`,itemId:x.id,product:x.name,lot:x.lot,from:x.state,to:draft.destination,
      quantity:q,uom:x.uom,sourceSlices:slices,policyVersionId:POLICY.versionId,policyHash:POLICY.fixtureHash,
      reason:draft.reason.trim(),evidence:draft.evidence.trim(),businessDate:BUSINESS_DATE,expiry:x.expiry,
      reservationImpact:{before:src.reservationBefore||0,after:reservationAfter,shortfall:Math.max(0,(src.reservationBefore||0)-reservationAfter),allocationReviewRequired:(src.reservationBefore||0)>reservationAfter}
    };
    payload.basisHash=fixtureHash(payload);
    return Object.freeze(payload);
  }
  function resetDraft(){
    draft={destination:current().state==='SELLABLE'?'QUARANTINE':'SELLABLE',quantity:String(Math.min(current().qty,5)),reason:'',evidence:''};
    basis=null;decision=null;rejectOpen=false;rejectReason='';movement=null;staleOnExecute=false;
  }
  function approvalRows(b){
    return icHeaderRows([
      ['Sản phẩm',b.product,true],['Lô',b.lot],['Từ',stateLabel(b.from)],['Sang',stateLabel(b.to)],['Số lượng',`${b.quantity} ${b.uom}`],['Lý do',b.reason||'—'],
      ...(b.evidence?[['Bằng chứng',b.evidence]]:[]),
      ['Tác động khả dụng',b.reservationImpact.shortfall>0?`Giảm; ${b.reservationImpact.shortfall} ${b.uom} cần phân bổ lại`:'Đã kiểm tra']
    ]);
  }
  function rejectSheet(){
    if(!rejectOpen)return '';
    return `<div class="sheet-backdrop ds24-overlay"><section class="ds24-confirmation" data-ds-component="VBottomSheet" role="dialog" aria-modal="true"><div class="ds24-confirmation__handle"></div><h3>Từ chối yêu cầu?</h3><p>Lý do được lưu cùng quyết định và không làm thay đổi tồn kho.</p>${icTextarea('Lý do từ chối',rejectReason,'data-v3101-reject-reason','Bắt buộc')}<div class="ds24-confirmation__actions"><button class="ds24-button ds24-button--secondary" data-v3101-action="reject-close">Quay lại</button><button class="ds24-button ds24-button--danger" data-v3101-action="reject-confirm" ${rejectReason.trim()?'':'disabled'}>Xác nhận từ chối</button></div></section></div>`;
  }
  function destinationChoices(){
    const x=current();return Object.entries(POLICY.transitions[x.state]||{}).map(([code,cfg])=>`<label class="v364-radio-option" data-ds-component="VRadio" data-ds-prop-state="${draft.destination===code?'On':'Off'}"><input type="radio" name="v3101-destination" value="${code}" data-v3101-destination ${draft.destination===code?'checked':''}><span class="v364-radio-control" aria-hidden="true"></span><span class="v364-radio-copy"><strong>${cfg.label}</strong><small>${cfg.approval?'Cần người duyệt độc lập':'Có thể xử lý ngay theo quy tắc hiện hành'}</small></span></label>`).join('');
  }
  function infoCurrent(x){
    const src=SOURCE[x.id];const available=x.state==='SELLABLE'?eligibleQty(x):0;
    return icHeaderRows([['Sản phẩm',x.name,true],['Mã',x.code],['Lô',x.lot],['Hạn dùng',x.expiry],['Tình trạng',stateLabel(x.state)],['Tồn vật lý',`${x.qty} ${x.uom}`],['Khả dụng bán',`${available} ${x.uom}`]]);
  }

    function render036BJ09(state){
    if(['PERMISSION_DENIED','LOADING','EMPTY'].includes(state))return render036IC09(state);
    const labels=[['ALL','Tất cả'],['SELLABLE','Bán được'],['QUARANTINE','Cách ly'],['DAMAGED','Hỏng'],['DEMO','Dùng thử'],['EXPIRED','Hết hạn']];
    const q=ic09Query.trim().toLowerCase();
    const items=ic09Items.filter(x=>(ic09Filter==='ALL'||x.state===ic09Filter)&&(!q||`${x.name} ${x.code} ${x.lot}`.toLowerCase().includes(q)));
    const rows=items.map(x=>ioProductRow({name:x.name,code:x.code,primary:`${x.qty} ${x.uom}`,secondary:`Lô ${x.lot}`,badge:stateLabel(x.state),badgeStatus:ic09StatusTone(x.state),attr:`data-ic09-item="${x.id}"`})).join('');
    return appShell({title:'Tình trạng hàng',body:`${ds24Search(ic09Query,'data-ic09-search','Tìm sản phẩm hoặc lô')}<div class="ac321-chip-wrap" data-composed-from="VChip">${labels.map(([k,l])=>ds24Chip(k,l,ic09Filter===k,'data-ic09-filter')).join('')}</div>${rows?`<div class="io-list-card" data-ds-component="VSection"><div class="io-product-list">${rows}</div></div>`:ioEmpty('Không có hàng phù hợp','Thử đổi bộ lọc hoặc từ khóa tìm kiếm.')}`,back:false});
  }
  function render037BJ09(state){
    if(['PERMISSION_DENIED','LOADING'].includes(state))return render037IC09(state);
    const x=current(),expired=x.state==='EXPIRED'||state==='EXPIRED';
    const notice=expired?vBanner('warning','Lô đã hết hạn',`Hết hạn theo ngày nghiệp vụ ${BUSINESS_DATE}; hệ thống tự loại khỏi khả dụng.`):state==='LOCKED'?vBanner('info','Đang thuộc phạm vi kiểm kê','Thông tin chỉ đọc cho đến khi phạm vi được mở khóa.'):'';
    const body=`${notice}${infoCurrent(x)}${ioSectionTitle('Tác động')}<p class="io-footnote">Đổi tình trạng chỉ phân loại lại cùng lượng hàng. Tổng tồn vật lý và giá trị ghi sổ không đổi.</p>${icSecondary('Xem lịch sử','data-ic09-action="history"')}`;
    return appShell({title:'Chi tiết tình trạng hàng',body,actions:expired||state==='LOCKED'?'':primaryFooter('Thay đổi tình trạng','data-ic09-action="change"')});
  }
  function render038BJ09(state){
    const x=current();
    // v360 ensureStableExitAffordance: màn 038 không có nút → "Về danh sách" (ownedFlows bỏ qua lớp đó).
    const exitList=primaryFooter('Về danh sách','data-v360-action="fallback-exit" data-v360-target="SCR-036"');
    if(state==='PERMISSION_DENIED')return appShell({title:'Chuyển tình trạng hàng',body:deniedBody(),centered:true,back:false,actions:exitList});
    if(state==='LOCKED')return appShell({title:'Chuyển tình trạng hàng',body:`${vBanner('info','Đang thuộc phạm vi kiểm kê','Không thể đổi tình trạng khi phạm vi đang khóa.')}${icHeaderRows([['Sản phẩm',x.name,true],['Lô',x.lot],['Tình trạng hiện tại',stateLabel(x.state)]])}`,back:false,actions:exitList});
    if(state==='SELF_APPROVAL_NOT_ALLOWED')return appShell({title:'Duyệt thay đổi tình trạng',body:vBanner('warning','Không thể tự duyệt','Người lập yêu cầu không được tự duyệt yêu cầu này.'),back:false,actions:exitList});
    if(state==='STATE_CHANGE_BASIS_STALE'||state==='CONFLICT')return appShell({title:'Yêu cầu đã thay đổi',body:`${vBanner('warning','Cần lập lại yêu cầu','Dữ liệu đã thay đổi; quyết định cũ không còn hiệu lực.')}${basis?approvalRows(basis):infoCurrent(x)}`,actions:primaryFooter('Lập lại yêu cầu','data-v3101-action="rebuild"'),back:false});
    if(state==='PENDING_APPROVAL'){
      const b=basis;return appShell({title:'Chuyển tình trạng hàng',body:`${vBanner('info','Đã gửi chờ duyệt','Tồn kho chưa thay đổi; người duyệt nhận công việc riêng.')}${b?approvalRows(b):infoCurrent(x)}`,back:false,actions:exitList});
    }
    if(state==='APPROVAL_REVIEW'){
      if(!basis)return appShell({title:'Duyệt thay đổi tình trạng',body:vBanner('warning','Không còn căn cứ hiện hành','Mở lại công việc từ danh sách được giao để lấy đúng phiên bản yêu cầu.'),back:false,actions:exitList});
      const body=`${vBanner('info','Phê duyệt không ghi tồn','Quyết định chỉ áp dụng cho đúng yêu cầu này. Hệ thống sẽ kiểm tra lại trước khi thực thi.')}${approvalRows(basis)}${rejectSheet()}`;
      return appShell({title:'Duyệt thay đổi tình trạng',body,actions:`<div class="ic-action-stack">${icSecondary('Từ chối','data-v3101-action="reject-open"','danger')}${primaryFooter('Duyệt','data-v3101-action="approve"')}</div>`,back:false});
    }
    const t=transition();
    const error=state==='VALIDATION_ERROR'?vBanner('error','Chưa đủ thông tin','Kiểm tra tình trạng đích, số lượng và thông tin bắt buộc theo quy tắc hiện hành.'):'';
    const policyNote=t?`<small class="helper-text">${t.approval?'Yêu cầu này sẽ được gửi người duyệt độc lập.':'Quy tắc hiện hành cho phép hệ thống xử lý sau khi gửi.'}</small>`:'';
    const evidence=t?.evidence?icTextarea('Bằng chứng',draft.evidence,'data-v3101-evidence','Nhập hoặc tham chiếu bằng chứng'):'';
    const body=`${error}${icHeaderRows([['Sản phẩm',x.name,true],['Lô',x.lot],['Từ',stateLabel(x.state)],['Tồn vật lý',`${x.qty} ${x.uom}`]])}${ioSectionTitle('Tình trạng mới')}<div class="choice-list">${destinationChoices()}</div>${policyNote}${icField('Số lượng chuyển',draft.quantity,'data-v3101-qty','number',`Tối đa ${x.qty} ${x.uom}. Hệ thống tự xác định đúng phần tồn được chuyển.`)}${icTextarea('Lý do',draft.reason,'data-v3101-reason','Nhập lý do')}${evidence}`;
    return appShell({title:'Chuyển tình trạng hàng',body,actions:primaryFooter('Gửi xử lý','data-v3101-action="submit"')});
  }
  function render041BJ09(state){
    const x=current();
    if(state==='PROCESSING')return appShell({title:'Kết quả thay đổi',body:`${vBanner('info','Đang kiểm tra và ghi nhận','Hệ thống đang kiểm tra lại đúng căn cứ đã gửi trước khi cập nhật tồn.')}${basis?approvalRows(basis):''}`,centered:false,back:false});
    if(state==='UNKNOWN')return appShell({title:'Kết quả thay đổi',body:ioResult('Đang xác minh kết quả','Không gửi yêu cầu mới. Hệ thống đang kiểm tra cùng lần xử lý này.',[['Sản phẩm',basis?.product||x.name],['Tình trạng','Chưa kết luận']],'warning'),actions:primaryFooter('Chuyển sang xác minh','data-v350-action="handoff-unknown" data-source-flow="UIF-09"'),centered:true,back:false});
    if(state==='STATE_CHANGE_BASIS_STALE'||state==='REJECTED_EXECUTION')return appShell({title:'Kết quả thay đổi',body:ioResult('Yêu cầu chưa được thực hiện','Tình trạng và tồn kho không thay đổi. Nếu căn cứ đã thay đổi, cần lập yêu cầu mới.',[['Sản phẩm',basis?.product||x.name],['Tác động tồn kho','Không có']],'warning'),actions:primaryFooter('Về tình trạng hàng','data-ic09-action="to-list"'),centered:true,back:false});
    if(state==='EXPIRED')return appShell({title:'Tình trạng hàng',body:ioResult('Lô đã hết hạn',`Theo ngày nghiệp vụ ${BUSINESS_DATE}, hệ thống đã loại lượng hàng này khỏi khả dụng bán.`,[['Tồn vật lý',`${x.qty} ${x.uom}`],['Khả dụng bán',`0 ${x.uom}`],['Tác động giá trị','Không đổi']],'warning'),actions:primaryFooter('Về tình trạng hàng','data-ic09-action="to-list"'),centered:true,back:false});
    if(state==='COMPLETED'&&movement){
      const r=movement.reservationImpact;const rows=[['Sản phẩm',movement.product],['Đã chuyển',`${movement.quantity} ${movement.uom} · ${stateLabel(movement.from)} → ${stateLabel(movement.to)}`],['Còn ở trạng thái nguồn',`${movement.remainingSource} ${movement.uom}`],['Tồn vật lý','Không đổi'],['Giá trị ghi sổ','Không đổi']];
      if(r.shortfall>0)rows.push(['Cần phân bổ lại',`${r.shortfall} ${movement.uom}`]);
      return appShell({title:'Kết quả thay đổi',body:ioResult('Đã cập nhật tình trạng','Hệ thống đã ghi chuyển trạng thái trên đúng phạm vi và kiểm tra lại khả dụng.',rows),actions:`<div class="ic-action-stack">${movement.id?icSecondary('Xem biến động','data-ic09-action="history"'):''}${primaryFooter('Về tình trạng hàng','data-ic09-action="to-list"')}</div>`,centered:true,back:false});
    }
    return ac310SanitizeMarkup(render041IC09(state));
  }
  function render056BJ09(state){
    if(!movement)return renderers['SCR-056'](state);
    const body=`${icHeaderRows([['Sản phẩm',movement.product,true],['Lô',movement.lot],['Biến động',`${stateLabel(movement.from)} → ${stateLabel(movement.to)}`],['Số lượng',`${movement.quantity} ${movement.uom}`],['Ghi nhận lúc',movement.recordedAt]])}<p class="io-footnote">Việc đổi tình trạng không làm thay đổi giá trị ghi sổ của lượng hàng này.</p>`;
    const html=appShell({title:'Chi tiết biến động',body});
    // v351: back restores SCR-037 without mutating status (auxiliary drill-down).
    const t=document.createElement('template');t.innerHTML=html;const back=t.content.querySelector('.app-back-button');
    if(back){back.removeAttribute('data-back');back.setAttribute('data-action','v351-ic09-history-back');}
    return t.innerHTML;
  }

  function systemCommit(){
    if(!basis)return false;
    stateByScreen['SCR-041']='PROCESSING';
    if(staleOnExecute){stateByScreen['SCR-041']='STATE_CHANGE_BASIS_STALE';renderAppScreen();return false;}
    const x=ic09Items.find(z=>z.id===basis.itemId);
    if(!x||x.state!==basis.from||x.qty<basis.quantity||POLICY.versionId!==basis.policyVersionId){stateByScreen['SCR-041']='STATE_CHANGE_BASIS_STALE';renderAppScreen();return false;}
    const slices=resolveSlices(x,basis.quantity);
    const currentHash=fixtureHash({...basis,basisHash:undefined,sourceSlices:slices});
    // Basis hash is frozen in this harness; runtime rechecks semantic facts rather than reproducing canonical production serialization.
    if(!slices){stateByScreen['SCR-041']='STATE_CHANGE_BASIS_STALE';renderAppScreen();return false;}
    const originalQty=x.qty;
    if(basis.quantity===x.qty){x.state=basis.to;x.label=stateLabel(basis.to);}
    else{
      x.qty=Number((x.qty-basis.quantity).toFixed(6));
      const splitId=`${x.id}-state-${Date.now()}`;
      ic09Items.push({id:splitId,name:x.name,code:x.code,lot:x.lot,qty:basis.quantity,uom:x.uom,state:basis.to,label:stateLabel(basis.to),expiry:x.expiry});
      SOURCE[splitId]={slices:basis.sourceSlices.map(z=>({balanceId:`${z.balanceId}-to`,version:1,valuationState:z.valuationState,qty:z.quantity})),reservationBefore:0};
    }
    const src=SOURCE[basis.itemId];
    // Reduce source fixture slices in the same deterministic slice order; preserve valuation state.
    let rem=basis.quantity; for(const sl of src.slices){if(rem<=0)break;const take=Math.min(rem,sl.qty);sl.qty-=take;rem-=take;}
    src.reservationBefore=basis.reservationImpact.after;
    movement={id:`MOV-STATE-${String(seq++).padStart(3,'0')}`,product:basis.product,lot:basis.lot,from:basis.from,to:basis.to,quantity:basis.quantity,uom:basis.uom,remainingSource:originalQty-basis.quantity,sourceSlices:basis.sourceSlices.map(z=>({...z,valuationStateSnapshot:z.valuationState})),valuationPreserved:true,valueMovementCreated:false,reservationImpact:basis.reservationImpact,recordedAt:'17/09/2026 · 15:04'};
    stateByScreen['SCR-041']='COMPLETED';renderAppScreen();return true;
  }
  function queueSystemCommit(){setTimeout(()=>{if(activeFlowId==='UIF-09'&&activeScreenId==='SCR-041'&&stateByScreen['SCR-041']==='PROCESSING')systemCommit();},180);}

  document.addEventListener('input',function(e){
    if(activeFlowId!=='UIF-09')return;
    if(e.target.matches('[data-v3101-qty]')){draft.quantity=e.target.value;}
    if(e.target.matches('[data-v3101-reason]')){draft.reason=e.target.value;}
    if(e.target.matches('[data-v3101-evidence]')){draft.evidence=e.target.value;}
    if(e.target.matches('[data-v3101-reject-reason]')){rejectReason=e.target.value;renderAppScreen();}
  },true);
  document.addEventListener('change',function(e){
    if(activeFlowId!=='UIF-09')return;
    if(e.target.matches('[data-v3101-destination]')){draft.destination=e.target.value;renderAppScreen();}
  },true);
  document.addEventListener('click',function(e){
    if(activeFlowId!=='UIF-09')return;
    if(e.target.closest('[data-ic09-item]')||e.target.closest('[data-ic09-action="change"]')){queueMicrotask(resetDraft);}
    const a=e.target.closest('[data-v3101-action]');if(!a||a.disabled)return;
    e.preventDefault();e.stopImmediatePropagation();const k=a.dataset.v3101Action;
    if(k==='submit'){
      if(!basisValid()){stateByScreen['SCR-038']='VALIDATION_ERROR';return renderAppScreen();}
      basis=buildBasis();decision=null;const t=transition();
      if(t?.approval){stateByScreen['SCR-038']='PENDING_APPROVAL';return renderAppScreen();}
      stateByScreen['SCR-041']='PROCESSING';navigate('SCR-041');queueSystemCommit();return;
    }
    if(k==='approve'){
      if(actor()!=='approver'){stateByScreen['SCR-038']='SELF_APPROVAL_NOT_ALLOWED';return renderAppScreen();}
      if(!basis){stateByScreen['SCR-038']='STATE_CHANGE_BASIS_STALE';return renderAppScreen();}
      decision={decision:'APPROVE',basisHash:basis.basisHash,actor:'approver',decidedAt:'17/09/2026 15:04'};
      stateByScreen['SCR-041']='PROCESSING';navigate('SCR-041');queueSystemCommit();return;
    }
    if(k==='reject-open'){if(actor()!=='approver'){stateByScreen['SCR-038']='SELF_APPROVAL_NOT_ALLOWED';return renderAppScreen();}rejectReason='';rejectOpen=true;return renderAppScreen();}
    if(k==='reject-close'){rejectOpen=false;rejectReason='';return renderAppScreen();}
    if(k==='reject-confirm'){
      if(actor()!=='approver'||!rejectReason.trim())return;
      decision={decision:'REJECT',basisHash:basis?.basisHash||null,reason:rejectReason.trim(),actor:'approver',decidedAt:'17/09/2026 15:04'};rejectOpen=false;
      stateByScreen['SCR-041']='REJECTED_EXECUTION';navigate('SCR-041');return;
    }
    if(k==='rebuild'){resetDraft();stateByScreen['SCR-038']='READY';return renderAppScreen();}
  },true);

  window.__VET45_V3101__={
    version:VERSION,decisions:[178,179,180,181,182,183,184],policy:POLICY,
    getDraft:()=>({...draft}),getBasis:()=>basis,getDecision:()=>decision,getMovement:()=>movement,
    getSource:(id)=>JSON.parse(JSON.stringify(SOURCE[id||current().id]||null)),
    setDraft(v={}){draft={...draft,...v};return {...draft};},
    setStaleOnExecute(v=true){staleOnExecute=Boolean(v);return staleOnExecute;},
    buildBasis(){basis=buildBasis();return basis;},systemCommit,
    fixtureHashNote:'Deterministic harness fixture hash only; production contract requires canonical SHA-256.'
  };

  flowRenderers["UIF-09"] = Object.assign(flowRenderers["UIF-09"] || {}, {
    "SCR-036": render036BJ09,
    "SCR-037": render037BJ09,
    "SCR-038": render038BJ09,
    "SCR-041": render041BJ09,
    "SCR-056": render056BJ09,
  });
})();

document.addEventListener("input",(event)=>{
  if(activeFlowId==="UIF-09"&&event.target.matches("[data-ic09-search]")){ic09Query=event.target.value;return renderAppScreen();}
},true);
document.addEventListener("change",(event)=>{
  if(activeFlowId==="UIF-09"&&event.target.matches("[data-ic09-destination]")){ic09Destination=event.target.value;return renderAppScreen();}
},true);
document.addEventListener("click",(event)=>{
  if(activeFlowId!=="UIF-09") return;

    const f=event.target.closest("[data-ic09-filter]"); if(f){event.preventDefault();ic09Filter=f.dataset.ic09Filter;return renderAppScreen();}
    const item=event.target.closest("[data-ic09-item]"); if(item){event.preventDefault();ic09Selected=item.dataset.ic09Item;stateByScreen["SCR-037"]=ic09Current().state==="EXPIRED"?"EXPIRED":"READY";return navigate("SCR-037");}
    const a=event.target.closest("[data-ic09-action]"); if(a&&!a.disabled){event.preventDefault();const k=a.dataset.ic09Action;
      if(k==="change"){stateByScreen["SCR-038"]="READY";return navigate("SCR-038");} if(k==="history")return navigate("SCR-056");
      if(k==="submit"){stateByScreen["SCR-038"]="PENDING_APPROVAL";return render();} if(k==="approve"){stateByScreen["SCR-041"]="COMPLETED";return navigate("SCR-041");}
      if(k==="reject"){stateByScreen["SCR-041"]="REJECTED_EXECUTION";return navigate("SCR-041");} if(k==="verify")return renderAppScreen();
      if(k==="to-list"){stateByScreen["SCR-036"]="READY";return navigate("SCR-036");}
    }
  
},true);

ownedFlows.add("UIF-09");
